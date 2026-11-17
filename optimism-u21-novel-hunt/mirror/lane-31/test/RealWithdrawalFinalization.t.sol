// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { RealWithdrawalBase, WithdrawalTransaction } from "./RealWithdrawalBase.t.sol";
import { Vm } from "forge-std/Vm.sol";

contract RealWithdrawalFinalizationTest is RealWithdrawalBase {
    function setUp() public {
        vm.createSelectFork("l1");
    }

    function test_realType9MessengerWithdrawal_finalizesEndToEnd() public {
        Fixture memory fixture = loadFixture("post-messenger-zero-1.json");
        assertEq(fixture.withdrawal.sender, L2_CDM, "not a messenger withdrawal");
        assertEq(fixture.withdrawal.target, L1_CDM, "not routed to L1 messenger");
        assertFalse(portal.finalizedWithdrawals(fixture.withdrawalHash), "already finalized");

        matureAndResolve(fixture);

        uint256 lockboxBefore = LOCKBOX.balance;
        uint256 portalBefore = PORTAL.balance;
        bytes32 messageHash = keccak256(fixture.withdrawal.data);
        assertFalse(messenger.successfulMessages(messageHash), "message already successful");
        assertFalse(messenger.failedMessages(messageHash), "message already failed");

        vm.recordLogs();
        portal.finalizeWithdrawalTransactionExternalProof(
            fixture.withdrawal, fixture.proofSubmitter
        );
        Vm.Log[] memory logs = vm.getRecordedLogs();

        (bool found, bool success) = findPortalFinalizedLog(logs, fixture.withdrawalHash);
        assertTrue(found, "portal did not emit WithdrawalFinalized");
        assertTrue(success, "portal target call failed");
        assertTrue(portal.finalizedWithdrawals(fixture.withdrawalHash), "not finalized");
        assertTrue(
            messenger.successfulMessages(messageHash) || messenger.failedMessages(messageHash),
            "finalized messenger withdrawal recorded neither outcome"
        );
        assertFalse(
            messenger.successfulMessages(messageHash) && messenger.failedMessages(messageHash),
            "first relay recorded both outcomes"
        );
        assertEq(PORTAL.balance, portalBefore, "portal retained ETH");
        assertEq(LOCKBOX.balance, lockboxBefore, "zero-value finalization changed lockbox");
    }
}
