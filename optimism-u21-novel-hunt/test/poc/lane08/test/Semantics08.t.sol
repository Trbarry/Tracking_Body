// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Base08.sol";

contract Picky {
    bool public accept;
    function set(bool a) external { accept = a; }
    receive() external payable { require(accept, "no eth"); }
}

/// Target of the attacker's own (previously failed) message. When replayed directly on the L1CDM it
/// finalizes somebody else's proven, matured messenger withdrawal from inside `relayMessage`.
contract Griefer {
    IPortal constant portal = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    bool public armed;
    bytes public victimCall;
    bool public innerOk;
    bytes public innerRet;

    function arm(bytes calldata c) external { armed = true; victimCall = c; }

    fallback() external payable {
        require(armed, "not armed"); // first delivery (through the portal) fails -> message becomes replayable
        (innerOk, innerRet) = address(portal).call(victimCall);
    }
}

contract Counter {
    uint256 public hits;
    address public lastXSender;
    fallback() external payable {
        hits++;
        lastXSender = ICDM(msg.sender).xDomainMessageSender();
    }
}

contract Semantics08Test is Base08 {
    bool internal v9;
    bytes4 constant CDM_FAILED = bytes4(keccak256("OptimismPortal_L1CDMCallFailed()"));

    function setUp() public {
        vm.createSelectFork(vm.envOr("FORK", string("l1")));
        v9 = keccak256(bytes(portal.version())) == keccak256("6.1.0");
        vm.deal(address(this), 100 ether);
    }

    function _fin(WithdrawalTransaction memory w, uint256 gas_) internal returns (bool ok, bytes memory ret) {
        (ok, ret) = address(portal).call{ gas: gas_ }(abi.encodeCall(portal.finalizeWithdrawalTransaction, (w)));
    }

    /// S1 — messenger message to an unsafe target (the portal): permanent revert in L1CDM.
    /// v9: portal reverts at ANY gas, withdrawal never finalizes, ETH never leaves the lockbox.
    /// v8: finalized with success=false, ETH re-locked (unreplayable). Same funds outcome (stuck), different state.
    function test_S1_unsafeTarget_neverFinalizes() public {
        WithdrawalTransaction memory w = messengerWithdrawal(910001, 910001, address(0xA11CE), address(portal), 1 ether, 0, "");
        bytes32 mh = keccak256(w.data);
        proveFresh(w);
        matureAll();
        uint256 lb = LOCKBOX.balance;
        uint256[4] memory gs = [uint256(600_000), 2_000_000, 16_000_000, 50_000_000];
        for (uint256 i; i < gs.length; i++) {
            uint256 snap = vm.snapshotState();
            (bool ok, bytes memory ret) = _fin(w, gs[i]);
            if (v9) {
                assertFalse(ok);
                assertEq(bytes4(ret), CDM_FAILED);
            } else {
                assertTrue(ok);
                assertTrue(portal.finalizedWithdrawals(hashWithdrawal(w)));
                assertFalse(l1cdm.failedMessages(mh) || l1cdm.successfulMessages(mh)); // neither: unreplayable
            }
            assertEq(LOCKBOX.balance, lb, "ETH stays in lockbox either way");
            vm.revertToState(snap);
        }
    }

    /// S3 — failing L1StandardBridge.finalizeBridgeETH is caught inside the messenger: finalized + failed + replayable,
    /// single delivery, value conserved in the L1CDM in between.
    function test_S3_bridgeFinalizeFailure_isFailedReplayable() public {
        Picky to = new Picky();
        bytes memory m = abi.encodeWithSignature("finalizeBridgeETH(address,address,uint256,bytes)", address(this), address(to), 3 ether, bytes(""));
        WithdrawalTransaction memory w = messengerWithdrawal(910002, 910002, L2_BRIDGE, L1_BRIDGE, 3 ether, 0, m);
        bytes32 mh = keccak256(w.data);
        proveFresh(w);
        matureAll();
        uint256 lb = LOCKBOX.balance;
        uint256 cdmBal = address(l1cdm).balance;
        uint256 toBal = address(to).balance; // forge's deterministic CREATE addresses carry mainnet dust
        (bool ok,) = _fin(w, 2_000_000);
        assertTrue(ok, "portal finalizes: relayMessage returned normally");
        assertTrue(portal.finalizedWithdrawals(hashWithdrawal(w)));
        assertTrue(l1cdm.failedMessages(mh) && !l1cdm.successfulMessages(mh));
        assertEq(LOCKBOX.balance, lb - 3 ether);
        assertEq(address(l1cdm).balance, cdmBal + 3 ether, "value parked in L1CDM");
        // portal cannot deliver twice
        (ok,) = _fin(w, 2_000_000);
        assertFalse(ok);
        // replay while still failing: stays failed
        l1cdm.relayMessage(v1Nonce(910002), L2_BRIDGE, L1_BRIDGE, 3 ether, 0, m);
        assertTrue(l1cdm.failedMessages(mh) && !l1cdm.successfulMessages(mh));
        // recipient fixed -> anyone replays
        to.set(true);
        vm.prank(address(0xB0B));
        l1cdm.relayMessage(v1Nonce(910002), L2_BRIDGE, L1_BRIDGE, 3 ether, 0, m);
        assertTrue(l1cdm.successfulMessages(mh));
        assertEq(address(to).balance, toBal + 3 ether);
        assertEq(address(l1cdm).balance, cdmBal);
        vm.expectRevert("CrossDomainMessenger: message has already been relayed");
        l1cdm.relayMessage(v1Nonce(910002), L2_BRIDGE, L1_BRIDGE, 3 ether, 0, m);
    }

    /// S2 — third-party griefing through the xDomainMsgSender reentrancy branch: the attacker replays his own failed
    /// message and, from inside it, finalizes the victim's withdrawal. Victim's message is recorded failed (portal
    /// sees success), value parked in L1CDM, and is delivered exactly once by a later replay. No double delivery,
    /// no loss; identical on v8 and v9.
    function test_S2_reentrantFinalize_marksVictimFailed_noDoubleDelivery() public {
        Griefer g = new Griefer();
        Counter victimTarget = new Counter();
        WithdrawalTransaction memory wa = messengerWithdrawal(910003, 910003, address(0xBAD), address(g), 0, 0, hex"aa");
        WithdrawalTransaction memory wv = messengerWithdrawal(910004, 910004, address(0xA11CE), address(victimTarget), 2 ether, 100_000, hex"bb");
        bytes32 ha = keccak256(wa.data);
        bytes32 hv = keccak256(wv.data);
        proveFresh(wa);
        proveFresh(wv);
        matureAll();
        // 1. attacker's message goes through the portal and fails (target not armed) -> replayable
        (bool ok,) = _fin(wa, 3_000_000);
        assertTrue(ok);
        assertTrue(l1cdm.failedMessages(ha));
        // 2. attacker replays it; its target finalizes the victim's withdrawal while xDomainMsgSender != DEFAULT
        g.arm(abi.encodeCall(portal.finalizeWithdrawalTransactionExternalProof, (wv, address(this))));
        uint256 cdmBal = address(l1cdm).balance;
        uint256 vtBal = address(victimTarget).balance;
        vm.prank(address(0xBAD));
        l1cdm.relayMessage{ gas: 5_000_000 }(v1Nonce(910003), address(0xBAD), address(g), 0, 0, hex"aa");
        assertTrue(g.innerOk(), "victim withdrawal finalized from inside the attacker's replay");
        assertTrue(portal.finalizedWithdrawals(hashWithdrawal(wv)));
        assertTrue(l1cdm.failedMessages(hv) && !l1cdm.successfulMessages(hv), "victim message recorded failed, not executed");
        assertEq(victimTarget.hits(), 0);
        assertEq(address(l1cdm).balance, cdmBal + 2 ether, "victim value parked in L1CDM");
        // 3. anyone replays the victim's message: exactly-once delivery with the right xDomain sender
        l1cdm.relayMessage(v1Nonce(910004), address(0xA11CE), address(victimTarget), 2 ether, 100_000, hex"bb");
        assertTrue(l1cdm.successfulMessages(hv));
        assertEq(victimTarget.hits(), 1);
        assertEq(victimTarget.lastXSender(), address(0xA11CE));
        assertEq(address(victimTarget).balance, vtBal + 2 ether);
        vm.expectRevert("CrossDomainMessenger: message has already been relayed");
        l1cdm.relayMessage(v1Nonce(910004), address(0xA11CE), address(victimTarget), 2 ether, 100_000, hex"bb");
        (ok,) = _fin(wv, 3_000_000);
        assertFalse(ok, "portal: already finalized");
    }

    /// S5/S6 — hash poisoning is impossible: nobody but the portal-with-l2Sender==L2CDM can create a failed/successful
    /// entry. (a) direct relayMessage of an undelivered message reverts; (b) a NON-messenger withdrawal that targets
    /// L1CDM.relayMessage with the victim's exact parameters is treated as a replay and reverts inside the messenger
    /// (portal finalizes that junk withdrawal with success=false), leaving the victim's hash untouched; (c) the
    /// victim's real withdrawal then delivers normally.
    function test_S5_cannotPoisonVictimHash() public {
        Counter victimTarget = new Counter();
        WithdrawalTransaction memory wv = messengerWithdrawal(910005, 910005, address(0xA11CE), address(victimTarget), 0, 0, hex"cc");
        bytes32 hv = keccak256(wv.data);
        // attacker's own direct L2ToL1MessagePasser withdrawal carrying the same relayMessage calldata
        WithdrawalTransaction memory wj = WithdrawalTransaction(v1Nonce(910006), address(0xBAD), address(l1cdm), 0, 1_000_000, wv.data);
        proveFresh(wv);
        proveFresh(wj);
        matureAll();
        vm.expectRevert("CrossDomainMessenger: message cannot be replayed");
        l1cdm.relayMessage(v1Nonce(910005), address(0xA11CE), address(victimTarget), 0, 0, hex"cc");
        (bool ok,) = _fin(wj, 3_000_000);
        assertTrue(ok, "junk withdrawal finalizes (sender != L2CDM), inner call failed");
        assertTrue(portal.finalizedWithdrawals(hashWithdrawal(wj)));
        assertFalse(l1cdm.failedMessages(hv) || l1cdm.successfulMessages(hv), "victim hash untouched");
        (ok,) = _fin(wv, 3_000_000);
        assertTrue(ok);
        assertTrue(l1cdm.successfulMessages(hv));
        assertEq(victimTarget.hits(), 1);
    }

    /// S8 — a messenger-message target cannot re-enter the portal (l2Sender guard) to finalize another withdrawal.
    function test_S8_targetCannotReenterPortal() public {
        Griefer g = new Griefer();
        Counter other = new Counter();
        WithdrawalTransaction memory wa = messengerWithdrawal(910007, 910007, address(0xBAD), address(g), 0, 0, hex"aa");
        WithdrawalTransaction memory wo = messengerWithdrawal(910008, 910008, address(0xA11CE), address(other), 0, 0, hex"dd");
        proveFresh(wa);
        proveFresh(wo);
        matureAll();
        g.arm(abi.encodeCall(portal.finalizeWithdrawalTransactionExternalProof, (wo, address(this))));
        (bool ok,) = _fin(wa, 5_000_000);
        assertTrue(ok);
        assertFalse(g.innerOk(), "inner finalize reverted");
        assertEq(bytes4(g.innerRet()), bytes4(keccak256("OptimismPortal_NoReentrancy()")));
        assertFalse(portal.finalizedWithdrawals(hashWithdrawal(wo)));
        assertTrue(l1cdm.successfulMessages(keccak256(wa.data)));
    }
}
