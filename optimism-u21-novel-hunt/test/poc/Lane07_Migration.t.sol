// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import "forge-std/Test.sol";

// LANE 07 — fork test against REAL deployed v9 code at L1 block 26433900.
// Models the PLANNED, documented OP Mainnet (10) + Unichain (130) interop migration
// (OPContractsManagerV2.migrate) executed by the real ProxyAdminOwner Safe via DELEGATECALL.
// The only privileged action simulated is that documented governance action.

struct WithdrawalTransaction { uint256 nonce; address sender; address target; uint256 value; uint256 gasLimit; bytes data; }
struct OutputRootProof { bytes32 version; bytes32 stateRoot; bytes32 messagePasserStorageRoot; bytes32 latestBlockhash; }
struct Proposal { bytes32 root; uint256 l2SequenceNumber; }
struct DisputeGameConfig { bool enabled; uint256 initBond; uint32 gameType; bytes gameArgs; }
struct MigrateInput { address[] chainSystemConfigs; DisputeGameConfig[] disputeGameConfigs; Proposal startingAnchorRoot; uint32 startingRespectedGameType; }

interface IOPCM { function migrate(MigrateInput calldata) external; }
interface ISC {
    function l2ChainId() external view returns (uint256);
    function optimismPortal() external view returns (address);
    function delayedWETH() external view returns (address);
    function isFeatureEnabled(bytes32) external view returns (bool);
}
interface IPortal {
    function anchorStateRegistry() external view returns (address);
    function ethLockbox() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function proveWithdrawalTransaction(WithdrawalTransaction calldata, uint256, OutputRootProof calldata, bytes[] calldata) external;
    function finalizeWithdrawalTransaction(WithdrawalTransaction calldata) external;
    function checkWithdrawal(bytes32, address) external view;
    function provenWithdrawals(bytes32, address) external view returns (address, uint64);
    function paused() external view returns (bool);
}
interface IASR {
    function respectedGameType() external view returns (uint32);
    function retirementTimestamp() external view returns (uint64);
    function anchorGame() external view returns (address);
    function getAnchorRoot() external view returns (bytes32, uint256);
    function disputeGameFactory() external view returns (address);
    function ethLockbox() external view returns (address);
    function isGameRegistered(address) external view returns (bool);
    function isGameProper(address) external view returns (bool);
    function isGameClaimValid(address) external view returns (bool);
    function isGameRespected(address) external view returns (bool);
    function setAnchorState(address) external;
}
interface IDGF {
    function gameImpls(uint32) external view returns (address);
    function gameArgs(uint32) external view returns (bytes memory);
    function initBonds(uint32) external view returns (uint256);
    function gameCount() external view returns (uint256);
    function owner() external view returns (address);
    function create(uint32, bytes32, bytes calldata) external payable returns (address);
    function games(uint32, bytes32, bytes calldata) external view returns (address, uint64);
    function gameAtIndex(uint256) external view returns (uint32, uint64, address);
}
interface IGame {
    function status() external view returns (uint8);
    function resolve() external returns (uint8);
    function resolveClaim(uint256, uint256) external;
    function rootClaim() external view returns (bytes32);
    function rootClaimByChainId(uint256) external view returns (bytes32);
    function extraData() external view returns (bytes memory);
    function l2SequenceNumber() external view returns (uint256);
    function createdAt() external view returns (uint64);
    function wasRespectedGameTypeWhenCreated() external view returns (bool);
    function anchorStateRegistry() external view returns (address);
    function startingProposal() external view returns (bytes32, uint256);
    function gameType() external view returns (uint32);
}

interface IGameCredit { function claimCredit(address) external; }

contract DelegateCaller {
    function exec(address t, bytes calldata d) external returns (bytes memory r) {
        bool ok;
        (ok, r) = t.delegatecall(d);
        if (!ok) assembly { revert(add(r, 32), mload(r)) }
    }
}

contract MigrationTest is Test {
    address constant SAFE = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A; // ProxyAdminOwner
    address constant OPCM = 0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f;
    ISC constant SC_OP = ISC(0x229047fed2591dbec1eF1118d64F7aF3dB9EB290);
    ISC constant SC_UNI = ISC(0xc407398d063f942feBbcC6F80a156b47F3f1BDA6);
    bytes32 constant PRESTATE = 0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9;
    address constant PROPOSER = 0xc27ba3E0Fc01567a5E57Ae0c391AA98cECBA5bE0;
    bytes32 constant INTEROP = "INTEROP";

    IPortal pOP; IPortal pUNI; IASR oldAsrOP; IASR oldAsrUNI; IDGF oldDgfOP; IDGF oldDgfUNI;
    address oldLockOP; address oldLockUNI;
    address attacker = address(0xA77AC4E2);

    function setUp() public {
        // L1_ALIAS lets the suite run against a private anvil (lane port 18070) layered on the shared `l1` fork.
        vm.createSelectFork(vm.envOr("L1_ALIAS", string("l1")));
        pOP = IPortal(SC_OP.optimismPortal()); pUNI = IPortal(SC_UNI.optimismPortal());
        oldAsrOP = IASR(pOP.anchorStateRegistry()); oldAsrUNI = IASR(pUNI.anchorStateRegistry());
        oldDgfOP = IDGF(oldAsrOP.disputeGameFactory()); oldDgfUNI = IDGF(oldAsrUNI.disputeGameFactory());
        oldLockOP = pOP.ethLockbox(); oldLockUNI = pUNI.ethLockbox();
        vm.deal(attacker, 100 ether);
        vm.label(address(pOP), "PortalOP"); vm.label(address(pUNI), "PortalUNI");
    }

    // ---------- helpers ----------
    function _wd(uint256 nonce, uint256 value) internal view returns (WithdrawalTransaction memory) {
        return WithdrawalTransaction({ nonce: nonce, sender: attacker, target: attacker, value: value, gasLimit: 100_000, data: "" });
    }
    function _wdHash(WithdrawalTransaction memory t) internal pure returns (bytes32) {
        return keccak256(abi.encode(t.nonce, t.sender, t.target, t.value, t.gasLimit, t.data));
    }
    /// Builds a fabricated L2 output root whose message-passer storage trie contains exactly `t`.
    function _fakeOutput(WithdrawalTransaction memory t) internal pure returns (bytes32 outputRoot, OutputRootProof memory orp, bytes[] memory proof) {
        bytes32 storageKey = keccak256(abi.encode(_wdHash(t), uint256(0)));
        bytes32 trieKey = keccak256(abi.encode(storageKey));
        bytes memory leaf = abi.encodePacked(hex"e3a120", trieKey, hex"01");
        orp = OutputRootProof({ version: bytes32(0), stateRoot: keccak256("fake state"), messagePasserStorageRoot: keccak256(leaf), latestBlockhash: keccak256("fake block") });
        outputRoot = keccak256(abi.encode(orp.version, orp.stateRoot, orp.messagePasserStorageRoot, orp.latestBlockhash));
        proof = new bytes[](1); proof[0] = leaf;
    }
    function _super1(uint64 ts, uint256 c0, bytes32 r0) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes1(0x01), ts, c0, r0);
    }
    function _super2(uint64 ts, uint256 c0, bytes32 r0, uint256 c1, bytes32 r1) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes1(0x01), ts, c0, r0, c1, r1);
    }
    function _super3(uint64 ts, uint256 c0, bytes32 r0, uint256 c1, bytes32 r1, uint256 c2, bytes32 r2) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes1(0x01), ts, c0, r0, c1, r1, c2, r2);
    }

    function _migrate() internal returns (IASR newAsr, IDGF newDgf) {
        address[] memory scs = new address[](2);
        scs[0] = address(SC_OP); scs[1] = address(SC_UNI); // ascending l2ChainId: 10 < 130
        DisputeGameConfig[] memory cfgs = new DisputeGameConfig[](2);
        cfgs[0] = DisputeGameConfig({ enabled: true, initBond: 0.08 ether, gameType: 9, gameArgs: abi.encode(PRESTATE) });
        cfgs[1] = DisputeGameConfig({ enabled: true, initBond: 0, gameType: 5, gameArgs: abi.encode(PROPOSER) });
        // Governance-chosen starting anchor: a two-chain super root at (now - 600).
        bytes memory startSuper = _super2(uint64(block.timestamp - 600), 10, keccak256("op start root"), 130, keccak256("uni start root"));
        MigrateInput memory inp = MigrateInput({
            chainSystemConfigs: scs,
            disputeGameConfigs: cfgs,
            startingAnchorRoot: Proposal({ root: keccak256(startSuper), l2SequenceNumber: block.timestamp - 600 }),
            startingRespectedGameType: 9
        });
        // The documented governance action: the ProxyAdminOwner Safe DELEGATECALLs OPCM.migrate.
        vm.etch(SAFE, address(new DelegateCaller()).code);
        DelegateCaller(SAFE).exec(OPCM, abi.encodeCall(IOPCM.migrate, (inp)));
        newAsr = IASR(pOP.anchorStateRegistry());
        newDgf = IDGF(newAsr.disputeGameFactory());
    }

    uint64 evilTs; // 0 => anchor+1
    function _createEvilOld(uint256 nonce, uint256 value) internal returns (address game, WithdrawalTransaction memory t, OutputRootProof memory orp, bytes[] memory proof, uint256 idx) {
        t = _wd(nonce, value);
        bytes32 evilRoot;
        (evilRoot, orp, proof) = _fakeOutput(t);
        (, uint256 seq) = oldAsrOP.getAnchorRoot();
        bytes memory extra = _super1(evilTs == 0 ? uint64(seq + 1) : evilTs, 10, evilRoot);
        idx = oldDgfOP.gameCount();
        vm.prank(attacker);
        game = oldDgfOP.create{ value: 0.08 ether }(9, keccak256(extra), extra);
    }

    // ---------- CONTROL: today's state, no migration ----------
    // An unchallenged invalid type-9 game finalizes a fabricated withdrawal. This is NOT a finding
    // (it assumes zero honest challengers for 3.5 days); it calibrates the harness and shows that the
    // registry checks are the only L1 gate between a proven withdrawal and the ETHLockbox.
    function test_control_unchallenged_invalid_game_pays() public {
        (address game, WithdrawalTransaction memory t, OutputRootProof memory orp, bytes[] memory proof, uint256 idx) = _createEvilOld(1, 1000 ether);
        vm.warp(block.timestamp + 1);
        vm.prank(attacker); pOP.proveWithdrawalTransaction(t, idx, orp, proof);
        vm.warp(block.timestamp + 302401);
        IGame(game).resolveClaim(0, 0); IGame(game).resolve();
        assertEq(IGame(game).status(), 2);
        vm.warp(block.timestamp + 604801);
        uint256 b = attacker.balance;
        vm.prank(attacker); pOP.finalizeWithdrawalTransaction(t);
        assertEq(attacker.balance - b, 1000 ether);
    }

    // ---------- pre-positioned proof + game do NOT survive the planned migration ----------
    function test_prepositioned_proof_dies_at_migration() public {
        (address game, WithdrawalTransaction memory t, OutputRootProof memory orp, bytes[] memory proof, uint256 idx) = _createEvilOld(1, 1000 ether);
        vm.warp(block.timestamp + 1);
        vm.prank(attacker); pOP.proveWithdrawalTransaction(t, idx, orp, proof);

        vm.warp(block.timestamp + 1 days);
        uint64 safeNonce = vm.getNonce(SAFE);
        uint256 sumBefore = oldLockOP.balance + oldLockUNI.balance + address(pOP).balance + address(pUNI).balance;
        (IASR newAsr, IDGF newDgf) = _migrate();

        // CREATE2 deployer of the 3 shared proxies is the Safe itself (DELEGATECALL context):
        // its account nonce advances by exactly 3. Nobody else can occupy those addresses.
        assertEq(vm.getNonce(SAFE), safeNonce + 3, "safe is the create2 deployer");
        // wiring
        assertEq(pUNI.anchorStateRegistry(), address(newAsr), "uni asr");
        assertEq(pUNI.disputeGameFactory(), address(newDgf), "uni dgf");
        assertEq(pOP.ethLockbox(), pUNI.ethLockbox(), "shared lockbox");
        assertEq(pOP.ethLockbox().balance, sumBefore, "liquidity pooled");
        assertEq(oldLockOP.balance + oldLockUNI.balance, 0);
        assertTrue(SC_OP.isFeatureEnabled(INTEROP) && SC_UNI.isFeatureEnabled(INTEROP));
        assertEq(newDgf.gameCount(), 0);
        assertEq(newAsr.retirementTimestamp(), block.timestamp);
        assertEq(newAsr.anchorGame(), address(0));
        assertEq(oldAsrOP.ethLockbox(), pOP.ethLockbox(), "old ASR re-pointed at shared lockbox");
        assertEq(SC_UNI.delayedWETH(), SC_OP.delayedWETH(), "shared DelayedWETH = chain[0]'s");
        emit log_named_address("shared ETHLockbox", pOP.ethLockbox());
        emit log_named_address("shared DGF", address(newDgf));
        emit log_named_address("shared ASR", address(newAsr));
        emit log_named_uint("shared lockbox ETH", pOP.ethLockbox().balance / 1 ether);

        // old factory: impls cleared
        assertEq(oldDgfOP.gameImpls(9), address(0)); assertEq(oldDgfOP.gameImpls(5), address(0));
        assertEq(oldDgfUNI.gameImpls(9), address(0)); assertEq(oldDgfUNI.gameImpls(5), address(0));

        // the pre-positioned game still resolves DEFENDER_WINS in its own (old) registry...
        vm.warp(block.timestamp + 302401);
        IGame(game).resolveClaim(0, 0); IGame(game).resolve();
        assertEq(IGame(game).status(), 2);
        vm.warp(block.timestamp + 604801);
        assertTrue(oldAsrOP.isGameClaimValid(game), "old ASR still calls it valid");
        // ...but the portal now asks the shared registry, where it is unregistered.
        assertFalse(newAsr.isGameRegistered(game));
        assertFalse(newAsr.isGameClaimValid(game));
        vm.prank(attacker);
        vm.expectRevert(bytes4(keccak256("OptimismPortal_InvalidRootClaim()")));
        pOP.finalizeWithdrawalTransaction(t);

        // Re-registering the same UUID in the shared factory yields a different clone address:
        // the old game stays unregistered (isGameRegistered compares addresses).
        bytes memory extra = IGame(game).extraData();
        (, uint256 aSeq) = newAsr.getAnchorRoot();
        if (IGame(game).l2SequenceNumber() > aSeq) {
            vm.prank(attacker);
            address twin = newDgf.create{ value: 0.08 ether }(9, IGame(game).rootClaim(), extra);
            assertTrue(twin != game);
            assertFalse(newAsr.isGameRegistered(game));
            assertTrue(newAsr.isGameRegistered(twin));
        }
        // bonds of the pre-migration game are still claimable through the (re-pointed) old DelayedWETH
        IGameCredit(game).claimCredit(attacker);
        vm.warp(block.timestamp + 302401);
        uint256 bal = attacker.balance;
        IGameCredit(game).claimCredit(attacker);
        assertEq(attacker.balance - bal, 0.08 ether, "bond refunded/paid after migration");
        // old-registry proofs cannot be re-proven either: index lookup is in the shared factory
        vm.prank(attacker);
        vm.expectRevert();
        pOP.proveWithdrawalTransaction(t, idx, orp, proof);
    }

    function test_prepositioned_future_game_twin_in_shared_factory() public {
        evilTs = uint64(block.timestamp + 60 days); // L1 puts no upper bound on a super game's timestamp
        test_prepositioned_proof_dies_at_migration();
    }

    // ---------- two-chain super root: output-root selection ----------
    bytes32 rA; bytes32 rB; IDGF sDgf; IASR sAsr;
    function _mk(bytes memory e) internal returns (address g) {
        vm.prank(attacker); g = sDgf.create{ value: 0.08 ether }(9, keccak256(e), e);
    }
    function test_two_chain_super_root_selection() public {
        (sAsr, sDgf) = _migrate();
        vm.warp(block.timestamp + 12); // games created at ts == retirementTimestamp are retired
        uint64 ts = uint64(block.timestamp - 100);
        {
            WithdrawalTransaction memory tA = _wd(11, 5 ether); WithdrawalTransaction memory tB = _wd(22, 7 ether);
            OutputRootProof memory oA; bytes[] memory prA; OutputRootProof memory oB; bytes[] memory prB;
            (rA, oA, prA) = _fakeOutput(tA);
            (rB, oB, prB) = _fakeOutput(tB);
            // (1) canonical order [(10,A),(130,B)]
            address g1 = _mk(_super2(ts, 10, rA, 130, rB));
            assertEq(IGame(g1).rootClaimByChainId(10), rA); assertEq(IGame(g1).rootClaimByChainId(130), rB);
            assertTrue(IGame(g1).wasRespectedGameTypeWhenCreated());
            vm.warp(block.timestamp + 1);
            vm.startPrank(attacker);
            pOP.proveWithdrawalTransaction(tA, 0, oA, prA);        // OP portal selects chain 10
            pUNI.proveWithdrawalTransaction(tB, 0, oB, prB);       // Unichain portal selects chain 130
            vm.expectRevert(bytes4(keccak256("OptimismPortal_InvalidOutputRootProof()")));
            pOP.proveWithdrawalTransaction(tB, 0, oB, prB);        // cross-chain root rejected
            vm.expectRevert(bytes4(keccak256("OptimismPortal_InvalidOutputRootProof()")));
            pUNI.proveWithdrawalTransaction(tA, 0, oA, prA);
            vm.stopPrank();
        }
        // (2) L1 accepts structurally non-canonical super roots: unsorted, duplicate chain id, foreign chain id.
        address g2 = _mk(_super2(ts + 1, 130, rB, 10, rA));              // unsorted
        address g3 = _mk(_super2(ts + 2, 10, rA, 10, rB));               // duplicate chain 10, no 130
        address g4 = _mk(_super3(ts + 3, 10, rA, 130, rB, 10, rB));      // duplicate after canonical prefix
        address g5 = _mk(_super1(ts + 4, 57073, rA));                    // chain not in the set at all
        assertEq(IGame(g2).rootClaimByChainId(10), rA);
        assertEq(IGame(g3).rootClaimByChainId(10), rA);                  // first match wins
        vm.expectRevert(bytes4(keccak256("UnknownChainId()"))); IGame(g3).rootClaimByChainId(130);
        assertEq(IGame(g4).rootClaimByChainId(10), rA);
        vm.expectRevert(bytes4(keccak256("UnknownChainId()"))); IGame(g5).rootClaimByChainId(10);
        assertTrue(sAsr.isGameProper(g2) && sAsr.isGameProper(g3));
        assertTrue(sAsr.isGameProper(g4) && sAsr.isGameProper(g5));
    }

    // ---------- a game created in the migration block is retired ----------
    function test_same_timestamp_game_is_retired() public {
        (IASR newAsr, IDGF newDgf) = _migrate();
        bytes memory e = _super2(uint64(block.timestamp - 100), 10, bytes32(uint256(1)), 130, bytes32(uint256(2)));
        vm.prank(attacker); address g = newDgf.create{ value: 0.08 ether }(9, keccak256(e), e);
        assertFalse(newAsr.isGameProper(g));
    }
}
