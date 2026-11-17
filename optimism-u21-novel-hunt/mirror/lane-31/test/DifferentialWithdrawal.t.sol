// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { RealWithdrawalBase } from "./RealWithdrawalBase.t.sol";
import { Vm } from "forge-std/Vm.sol";

contract DifferentialWithdrawalTest is RealWithdrawalBase {
    bytes4 internal constant L1_CDM_CALL_FAILED =
        bytes4(keccak256("OptimismPortal_L1CDMCallFailed()"));

    struct Outcome {
        bool callSucceeded;
        bool finalized;
        bool relayed;
        bool failedMessage;
        bool finalizedEventFound;
        bool finalizedEventSuccess;
        bytes4 revertSelector;
        uint256 gasUsed;
        uint256 portalBalanceAfter;
        uint256 lockboxBalanceAfter;
    }

    function callFinalize(Fixture memory fixture, uint256 suppliedGas)
        internal
        returns (Outcome memory outcome)
    {
        bytes32 messageHash = keccak256(fixture.withdrawal.data);
        vm.recordLogs();
        uint256 gasBefore = gasleft();
        bytes memory returndata;
        (outcome.callSucceeded, returndata) = PORTAL.call{ gas: suppliedGas }(
            abi.encodeCall(
                portal.finalizeWithdrawalTransactionExternalProof,
                (fixture.withdrawal, fixture.proofSubmitter)
            )
        );
        outcome.gasUsed = gasBefore - gasleft();
        Vm.Log[] memory logs = vm.getRecordedLogs();
        (outcome.finalizedEventFound, outcome.finalizedEventSuccess) =
            findPortalFinalizedLog(logs, fixture.withdrawalHash);
        outcome.finalized = portal.finalizedWithdrawals(fixture.withdrawalHash);
        outcome.relayed = _readMessengerBool(
            abi.encodeCall(messenger.successfulMessages, (messageHash))
        );
        outcome.failedMessage = _readMessengerBool(
            abi.encodeCall(messenger.failedMessages, (messageHash))
        );
        outcome.portalBalanceAfter = PORTAL.balance;
        outcome.lockboxBalanceAfter = LOCKBOX.balance;
        if (!outcome.callSucceeded && returndata.length >= 4) {
            outcome.revertSelector = bytes4(returndata);
        }
    }

    function classifyAndRestore(Fixture memory fixture, uint256 suppliedGas)
        internal
        returns (Outcome memory outcome)
    {
        uint256 snapshot = vm.snapshotState();
        outcome = callFinalize(fixture, suppliedGas);
        assertFalse(
            outcome.finalized && !outcome.relayed && !outcome.failedMessage,
            "finalized messenger withdrawal recorded neither outcome"
        );
        assertTrue(vm.revertToStateAndDelete(snapshot));
    }

    function binarySearchMinSuccess(Fixture memory fixture) internal returns (uint256 low) {
        low = 100_000;
        uint256 high = 2_000_000;
        require(classifyAndRestore(fixture, high).callSucceeded, "2m gas upper bound failed");
        while (low < high) {
            uint256 mid = low + (high - low) / 2;
            if (classifyAndRestore(fixture, mid).callSucceeded) high = mid;
            else low = mid + 1;
        }
    }

    function test_exactNMinus1ToN_sameRealFixture_sameSuccessfulOutcome() public {
        vm.createSelectFork("l1pre");
        Fixture memory preFixture = loadFixture("pre-messenger-zero.json");
        matureAndResolve(preFixture);
        uint256 prePortalBefore = PORTAL.balance;
        uint256 preLockboxBefore = LOCKBOX.balance;
        Outcome memory pre = callFinalize(preFixture, 2_000_000);

        vm.createSelectFork("l1n");
        Fixture memory nFixture = loadFixture("pre-messenger-zero.json");
        matureAndResolve(nFixture);
        uint256 nPortalBefore = PORTAL.balance;
        uint256 nLockboxBefore = LOCKBOX.balance;
        Outcome memory n = callFinalize(nFixture, 2_000_000);

        assertTrue(pre.callSucceeded && n.callSucceeded, "normal finalization diverged");
        assertTrue(pre.finalized && n.finalized, "normal finalization did not finalize");
        assertTrue(pre.finalizedEventFound && n.finalizedEventFound, "missing event");
        assertEq(pre.finalizedEventSuccess, n.finalizedEventSuccess, "event success changed at N");
        assertEq(pre.relayed, n.relayed, "relay success changed at N");
        assertEq(pre.failedMessage, n.failedMessage, "failedMessages changed at N");
        assertEq(pre.portalBalanceAfter, prePortalBefore, "v8 portal balance changed");
        assertEq(n.portalBalanceAfter, nPortalBefore, "v9 portal balance changed");
        assertEq(pre.lockboxBalanceAfter, preLockboxBefore, "v8 lockbox balance changed");
        assertEq(n.lockboxBalanceAfter, nLockboxBefore, "v9 lockbox balance changed");
        emit log_named_uint("N-1 finalize call gas (harness measurement)", pre.gasUsed);
        emit log_named_uint("N finalize call gas (harness measurement)", n.gasUsed);
    }

    function test_documentedDiff_failingMessengerFinalizesOnV8_revertsOnV9() public {
        vm.createSelectFork("l1pre");
        Fixture memory preFixture = loadFixture("pre-messenger-zero.json");
        matureAndResolve(preFixture);
        vm.etch(L1_CDM, hex"60006000fd"); // PUSH0 PUSH0 REVERT
        Outcome memory pre = callFinalize(preFixture, 2_000_000);

        vm.createSelectFork("l1");
        Fixture memory postFixture = loadFixture("post-messenger-zero-1.json");
        matureAndResolve(postFixture);
        vm.etch(L1_CDM, hex"60006000fd");
        Outcome memory post = callFinalize(postFixture, 2_000_000);

        assertTrue(pre.callSucceeded, "v8 unexpectedly reverted");
        assertTrue(pre.finalized, "v8 did not retain finalization");
        assertTrue(pre.finalizedEventFound, "v8 missing finalized event");
        assertFalse(pre.finalizedEventSuccess, "v8 target unexpectedly succeeded");

        assertFalse(post.callSucceeded, "v9 unexpectedly accepted failed messenger call");
        assertFalse(post.finalized, "v9 retained reverted finalization");
        assertFalse(post.finalizedEventFound, "v9 retained reverted event");
        assertEq(post.revertSelector, L1_CDM_CALL_FAILED, "unexpected v9 revert");
    }

    function test_binarySearchMinimumGas_v8AndV9RealMessengerPaths() public {
        vm.createSelectFork("l1pre");
        Fixture memory preFixture = loadFixture("pre-messenger-zero.json");
        matureAndResolve(preFixture);
        uint256 v8Min = binarySearchMinSuccess(preFixture);
        Outcome memory v8AtMin = classifyAndRestore(preFixture, v8Min);
        Outcome memory v8Below = classifyAndRestore(preFixture, v8Min - 1);

        vm.createSelectFork("l1");
        Fixture memory postFixture = loadFixture("post-messenger-zero-1.json");
        matureAndResolve(postFixture);
        uint256 v9Min = binarySearchMinSuccess(postFixture);
        Outcome memory v9AtMin = classifyAndRestore(postFixture, v9Min);
        Outcome memory v9Below = classifyAndRestore(postFixture, v9Min - 1);

        assertFalse(v8Below.callSucceeded);
        assertTrue(v8AtMin.callSucceeded && v8AtMin.finalized);
        assertTrue(v8AtMin.relayed || v8AtMin.failedMessage);
        assertFalse(v9Below.callSucceeded);
        assertTrue(v9AtMin.callSucceeded && v9AtMin.finalized);
        assertTrue(v9AtMin.relayed || v9AtMin.failedMessage);
        emit log_named_uint("v8 minimum outer gas", v8Min);
        emit log_named_uint("v9 minimum outer gas", v9Min);
    }

    function test_viewGetterDiffs_areDocumentedAndWired() public {
        vm.createSelectFork("l1pre");
        (bool okV8Version, bytes memory v8VersionData) = PORTAL.staticcall(
            abi.encodeWithSignature("version()")
        );
        address v8Superchain = abi.decode(
            _staticcall(PORTAL, abi.encodeWithSignature("superchainConfig()")), (address)
        );
        address v8Guardian = abi.decode(
            _staticcall(PORTAL, abi.encodeWithSignature("guardian()")), (address)
        );

        vm.createSelectFork("l1n");
        (bool okV9Version, bytes memory v9VersionData) = PORTAL.staticcall(
            abi.encodeWithSignature("version()")
        );
        address v9Superchain = abi.decode(
            _staticcall(PORTAL, abi.encodeWithSignature("superchainConfig()")), (address)
        );
        address v9Guardian = abi.decode(
            _staticcall(PORTAL, abi.encodeWithSignature("guardian()")), (address)
        );

        assertTrue(okV8Version && okV9Version);
        assertEq(abi.decode(v8VersionData, (string)), "5.8.0");
        assertEq(abi.decode(v9VersionData, (string)), "6.1.0");
        assertEq(v8Superchain, v9Superchain, "superchainConfig wiring changed value");
        assertEq(v8Guardian, v9Guardian, "guardian wiring changed value");
    }

    function _staticcall(address target, bytes memory data) internal view returns (bytes memory result) {
        (bool ok, bytes memory returndata) = target.staticcall(data);
        require(ok, "staticcall failed");
        return returndata;
    }

    function _readMessengerBool(bytes memory data) internal view returns (bool) {
        (bool ok, bytes memory returndata) = L1_CDM.staticcall(data);
        return ok && returndata.length >= 32 && abi.decode(returndata, (bool));
    }
}
