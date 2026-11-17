// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

// ATK-T2 — legacy carry-through. Every object below is a REAL L2 withdrawal (OVM 1.0 migrated, OVM 2.0 migrated,
// Bedrock-era) that is live in OP Mainnet L2ToL1MessagePasser.sentMessages and never finalized on L1. It is proven
// with a REAL storage proof (eth_getProof at L2 159,653,251) against the REAL OP game #21388 (root 0x05bfbbc4…),
// resolved honestly by warping its clock, then finalized by an unprivileged EOA under the deployed v9 bytecode.
// No vm.store, no mock, no privileged prank. Fork: local read-only archive proxy, L1 block 26,433,900.

struct WithdrawalTransaction { uint256 nonce; address sender; address target; uint256 value; uint256 gasLimit; bytes data; }
struct OutputRootProof { bytes32 version; bytes32 stateRoot; bytes32 messagePasserStorageRoot; bytes32 latestBlockhash; }

interface IPortal {
    function proveWithdrawalTransaction(WithdrawalTransaction memory, uint256, OutputRootProof calldata, bytes[] calldata) external;
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction memory, address) external;
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function provenWithdrawals(bytes32, address) external view returns (address, uint64);
    function proofMaturityDelaySeconds() external view returns (uint256);
    function disputeGameFinalityDelaySeconds() external view returns (uint256);
    function ethLockbox() external view returns (address);
    function checkWithdrawal(bytes32, address) external view;
    function version() external view returns (string memory);
}
interface IFactory { function gameAtIndex(uint256) external view returns (uint32, uint64, address); }
interface IGame {
    function status() external view returns (uint8);
    function createdAt() external view returns (uint64);
    function resolvedAt() external view returns (uint64);
    function maxClockDuration() external view returns (uint64);
    function claimDataLen() external view returns (uint256);
    function resolvedSubgames(uint256) external view returns (bool);
    function resolveClaim(uint256, uint256) external;
    function resolve() external returns (uint8);
    function rootClaimByChainId(uint256) external view returns (bytes32);
}
interface IBridge {
    function finalizeBridgeERC20(address, address, address, address, uint256, bytes calldata) external;
    function finalizeERC20Withdrawal(address, address, address, address, uint256, bytes calldata) external;
    function deposits(address, address) external view returns (uint256);
}
interface ILegacyTok {
    function l1Token() external view returns (address);
    function l2Bridge() external view returns (address);
    function supportsInterface(bytes4) external view returns (bool);
    function balanceOf(address) external view returns (uint256);
}
interface IMessenger {
    function successfulMessages(bytes32) external view returns (bool);
    function failedMessages(bytes32) external view returns (bool);
    function relayMessage(uint256, address, address, uint256, uint256, bytes calldata) external payable;
}

contract ATKT2Test is Test {
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    IFactory constant DGF = IFactory(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);
    IMessenger constant L1CDM = IMessenger(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);
    uint256 constant GAME_INDEX = 21388;
    address constant SUBMITTER = address(0x7102); // unprivileged proof submitter
    address constant ATTACKER = address(0xA77AC4); // unprivileged finalizer / replayer
    string dir;
    OutputRootProof orp;
    address game;

    function setUp() public {
        vm.createSelectFork("http://127.0.0.1:7545", 26433900);
        dir = string.concat(vm.projectRoot(), "/test/fixtures/");
        string memory o = vm.readFile(string.concat(dir, "output.json"));
        orp = OutputRootProof(vm.parseJsonBytes32(o, ".version"), vm.parseJsonBytes32(o, ".stateRoot"),
            vm.parseJsonBytes32(o, ".messagePasserStorageRoot"), vm.parseJsonBytes32(o, ".latestBlockhash"));
        (,, game) = DGF.gameAtIndex(GAME_INDEX);
        assertEq(game, vm.parseJsonAddress(o, ".game"));
        assertEq(IGame(game).rootClaimByChainId(10), keccak256(abi.encode(orp.version, orp.stateRoot, orp.messagePasserStorageRoot, orp.latestBlockhash)), "game root == real L2 output root");
        assertEq(keccak256(bytes(PORTAL.version())), keccak256(bytes("6.1.0")));
    }

    function _load(string memory id) internal view returns (WithdrawalTransaction memory w, bytes[] memory proof, bytes32 h) {
        string memory j = vm.readFile(string.concat(dir, id, ".json"));
        w = WithdrawalTransaction(vm.parseUint(vm.parseJsonString(j, ".nonce")), vm.parseJsonAddress(j, ".sender"), vm.parseJsonAddress(j, ".target"),
            vm.parseUint(vm.parseJsonString(j, ".value")), vm.parseUint(vm.parseJsonString(j, ".gasLimit")), vm.parseJsonBytes(j, ".data"));
        proof = vm.parseJsonBytesArray(j, ".proof");
        h = keccak256(abi.encode(w.nonce, w.sender, w.target, w.value, w.gasLimit, w.data));
        assertEq(h, vm.parseJsonBytes32(j, ".withdrawalHash"));
    }

    function _resolveGame() internal {
        IGame g = IGame(game);
        if (g.status() != 0) return;
        uint256 t = uint256(g.createdAt()) + 2 * uint256(g.maxClockDuration()) + 1;
        if (block.timestamp < t) vm.warp(t);
        for (uint256 i = g.claimDataLen(); i > 0; i--) if (!g.resolvedSubgames(i - 1)) g.resolveClaim(i - 1, 0);
        assertEq(g.resolve(), 2, "game resolves DEFENDER_WINS");
    }

    /// prove (unprivileged SUBMITTER) -> honest resolution -> mature; returns the finalize result from ATTACKER.
    function _proveAndMature(WithdrawalTransaction memory w, bytes[] memory proof, bytes32 h) internal {
        assertFalse(PORTAL.finalizedWithdrawals(h), "never finalized");
        vm.prank(SUBMITTER, SUBMITTER);
        PORTAL.proveWithdrawalTransaction(w, GAME_INDEX, orp, proof);
        _resolveGame();
        uint256 t1 = block.timestamp + PORTAL.proofMaturityDelaySeconds() + 1;
        uint256 t2 = uint256(IGame(game).resolvedAt()) + PORTAL.disputeGameFinalityDelaySeconds() + 1;
        vm.warp(t1 > t2 ? t1 : t2);
        PORTAL.checkWithdrawal(h, SUBMITTER);
    }

    function _finalize(WithdrawalTransaction memory w) internal returns (bool ok, bytes memory ret) {
        vm.prank(ATTACKER, ATTACKER);
        (ok, ret) = address(PORTAL).call{gas: 15_000_000}(abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (w, SUBMITTER)));
    }

    function _inner(WithdrawalTransaction memory w) internal pure returns (uint256 n, address s, address t, uint256 v, uint256 g, bytes memory m) {
        bytes memory d = w.data;
        bytes memory args = new bytes(d.length - 4);
        for (uint256 i; i < args.length; i++) args[i] = d[i + 4];
        (n, s, t, v, g, m) = abi.decode(args, (uint256, address, address, uint256, uint256, bytes));
    }

    function _v0(address t, address s, bytes memory m, uint256 n) internal pure returns (bytes32) {
        return keccak256(abi.encodeWithSignature("relayMessage(address,address,bytes,uint256)", t, s, m, n));
    }

    function _ethRecipient(bytes memory m) internal pure returns (address to, uint256 amt) {
        // finalizeETHWithdrawal(from,to,amount,data) (0x1532ec34) and finalizeBridgeETH(from,to,amount,data) (0x1635f5fd)
        bytes memory args = new bytes(m.length - 4);
        for (uint256 i; i < args.length; i++) args[i] = m[i + 4];
        (, to, amt,) = abi.decode(args, (address, address, uint256, bytes));
    }

    function _deliveredOnce(string memory id) internal {
        (WithdrawalTransaction memory w, bytes[] memory proof, bytes32 h) = _load(id);
        _proveAndMature(w, proof, h);
        address lockbox = PORTAL.ethLockbox();
        address to; uint256 amt; bytes32 v1;
        if (w.sender == 0x4200000000000000000000000000000000000007) {
            (uint256 n, address s, address t, uint256 v, uint256 g, bytes memory m) = _inner(w);
            v1 = keccak256(w.data);
            (to, amt) = _ethRecipient(m);
            assertEq(amt, w.value, "legacy value parsed == committed amount");
            if (n >> 240 == 0) assertFalse(L1CDM.successfulMessages(_v0(t, s, m, n)), "legacy v0 hash not relayed");
            assertEq(v, w.value); g;
        } else {
            to = w.target; amt = w.value;
        }
        uint256 lb0 = lockbox.balance; uint256 to0 = to.balance; uint256 at0 = ATTACKER.balance;
        (bool ok, bytes memory ret) = _finalize(w);
        assertTrue(ok, string(ret));
        assertTrue(PORTAL.finalizedWithdrawals(h));
        assertEq(lb0 - lockbox.balance, w.value, "lockbox pays exactly value");
        assertEq(to.balance - to0, amt, "committed recipient gets exactly value");
        assertEq(ATTACKER.balance, at0, "finalizer gains nothing");
        if (v1 != bytes32(0)) { assertTrue(L1CDM.successfulMessages(v1)); assertFalse(L1CDM.failedMessages(v1)); }
        // second finalize and a direct messenger replay both fail
        (ok,) = _finalize(w);
        assertFalse(ok, "no second finalization");
        if (v1 != bytes32(0)) {
            (uint256 n, address s, address t, uint256 v, uint256 g, bytes memory m) = _inner(w);
            vm.prank(ATTACKER, ATTACKER);
            vm.expectRevert(bytes("CrossDomainMessenger: message cannot be replayed"));
            L1CDM.relayMessage(n, s, t, v, g, m);
        }
        emit log_named_bytes32(string.concat(id, " finalized, value delivered once, hash"), h);
    }

    function _blockedDoubleRelay(string memory id) internal {
        (WithdrawalTransaction memory w, bytes[] memory proof, bytes32 h) = _load(id);
        (uint256 n, address s, address t,,, bytes memory m) = _inner(w);
        assertEq(n >> 240, 0, "version-0 nonce");
        assertTrue(L1CDM.successfulMessages(_v0(t, s, m, n)), "already paid by the pre-Bedrock messenger");
        _proveAndMature(w, proof, h); // proving works: the object is real
        address lockbox = PORTAL.ethLockbox();
        (address to,) = _ethRecipient(m);
        uint256 lb0 = lockbox.balance; uint256 to0 = to.balance;
        (bool ok, bytes memory ret) = _finalize(w);
        assertFalse(ok, "v9 finalize must revert");
        emit log_named_bytes(string.concat(id, " revert data"), ret);
        assertEq(bytes4(ret), bytes4(keccak256("OptimismPortal_L1CDMCallFailed()")));
        assertFalse(PORTAL.finalizedWithdrawals(h));
        assertEq(lockbox.balance, lb0); assertEq(to.balance, to0);
        // the messenger itself refuses a direct attempt too
        vm.prank(ATTACKER, ATTACKER);
        vm.expectRevert(bytes("CrossDomainMessenger: legacy withdrawal already relayed"));
        L1CDM.relayMessage{value: 0}(n, s, t, 1, 0, m);
        emit log_named_uint(string.concat(id, " value that stays in the lockbox (wei)"), w.value);
    }

    function test_T2a_ovm1_unrelayed_v0_deliveredOnce() public { _deliveredOnce("ovm1_unrelayed_25ETH"); }
    function test_T2a_ovm2_unrelayed_v0_deliveredOnce() public { _deliveredOnce("ovm2_unrelayed"); }
    function test_T2a_ovm1_relayed_v0_600ETH_blocked() public { _blockedDoubleRelay("ovm1_relayed_600ETH"); }
    function test_T2a_ovm2_relayed_v0_35555ETH_blocked() public { _blockedDoubleRelay("ovm2_relayed_35555ETH"); }
    function test_T2b_bedrock_regolith_messenger_deliveredOnce() public { _deliveredOnce("bedrock_regolith_messenger"); }
    function test_T2b_ecotone_direct_eoa_deliveredOnce() public { _deliveredOnce("ecotone_direct_eoa"); }
    function test_T2b_isthmus_direct_feevault_deliveredOnce() public { _deliveredOnce("isthmus_direct_feevault"); }

    // ---- T2c: legacy escrowed pair whose L1 token the v9 bridge now classifies as OptimismMintable ----
    // VEHICLE (stated): the cross-domain context is set with vm.store(L1CDM.xDomainMsgSender = L2StandardBridge,
    // slot 204) + vm.prank(L1CDM); everything else (classification, pair check, mint, escrow) is deployed bytecode.
    IBridge constant L1SB = IBridge(0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1);
    address constant EDU = 0x9340857794710bbccf68167222a1DE4F0e269b10;
    address constant L2SB = 0x4200000000000000000000000000000000000010;

    function _asOtherBridge() internal {
        vm.store(address(L1CDM), bytes32(uint256(204)), bytes32(uint256(uint160(L2SB))));
        vm.prank(address(L1CDM));
    }

    function test_T2c_legacyEscrowPair_reclassifiedMintable_frozen() public {
        ILegacyTok t = ILegacyTok(EDU);
        assertTrue(t.supportsInterface(0x1d1d8b63), "L1 token answers ILegacyMintableERC20");
        assertEq(t.l1Token(), EDU, "self-referential l1Token");
        assertEq(t.l2Bridge(), address(0));
        uint256 esc = L1SB.deposits(EDU, EDU);
        assertEq(esc, 90170 ether, "legacy escrow written by the pre-Bedrock bridge");
        assertEq(t.balanceOf(address(L1SB)), esc);
        address to = address(0xB0B);
        _asOtherBridge();
        vm.expectRevert(); // mint() of the L1 token is onlyL2Bridge (== address(0))
        L1SB.finalizeBridgeERC20(EDU, EDU, to, to, 1 ether, "");
        _asOtherBridge();
        vm.expectRevert();
        L1SB.finalizeERC20Withdrawal(EDU, EDU, to, to, 1 ether, "");
        assertEq(L1SB.deposits(EDU, EDU), esc, "escrow untouched: no release path exists in v9");
        assertEq(t.balanceOf(to), 0);
        emit log_named_uint("EDU escrow unreachable (wei)", esc);
    }

    function test_T2c_negativeControl_nonMintableLegacyPair_releases() public {
        address WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599; address L2WBTC = 0x68f180fcCe6836688e9084f035309E29Bf0A2095;
        uint256 esc = L1SB.deposits(WBTC, L2WBTC);
        address to = address(0xB0B);
        _asOtherBridge();
        L1SB.finalizeBridgeERC20(WBTC, L2WBTC, to, to, 1e8, "");
        assertEq(L1SB.deposits(WBTC, L2WBTC), esc - 1e8);
        assertEq(ILegacyTok(WBTC).balanceOf(to), 1e8);
    }
}
