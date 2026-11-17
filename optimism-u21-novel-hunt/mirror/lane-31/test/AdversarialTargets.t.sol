// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { RealWithdrawalBase, WithdrawalTransaction } from "./RealWithdrawalBase.t.sol";

contract ReenteringTargetLane31 {
    address internal constant PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;

    fallback() external payable {
        // Inflows are deliberately callable during finalization.
        (bool donateOk,) = PORTAL.call(abi.encodeWithSignature("donateETH()"));
        require(donateOk, "donate reentry failed");
        (bool depositOk,) = PORTAL.call(
            abi.encodeWithSignature(
                "depositTransaction(address,uint256,uint64,bool,bytes)",
                address(0x3131),
                0,
                uint64(21_000),
                false,
                bytes("")
            )
        );
        require(depositOk, "deposit reentry failed");

        WithdrawalTransaction memory dummy = WithdrawalTransaction({
            nonce: 1,
            sender: address(this),
            target: address(0x3132),
            value: 0,
            gasLimit: 21_000,
            data: bytes("")
        });
        (bool finalizeOk,) = PORTAL.call(
            abi.encodeWithSignature(
                "finalizeWithdrawalTransaction((uint256,address,address,uint256,uint256,bytes))",
                dummy
            )
        );
        require(!finalizeOk, "finalize reentry bypassed l2Sender guard");
        (bool externalFinalizeOk,) = PORTAL.call(
            abi.encodeWithSignature(
                "finalizeWithdrawalTransactionExternalProof((uint256,address,address,uint256,uint256,bytes),address)",
                dummy,
                address(this)
            )
        );
        require(!externalFinalizeOk, "external finalize reentry bypassed l2Sender guard");

        (bool lockOk,) = LOCKBOX.call(abi.encodeWithSignature("lockETH()"));
        require(!lockOk, "unauthorized lockbox lock succeeded");
        (bool unlockOk,) = LOCKBOX.call(abi.encodeWithSignature("unlockETH(uint256)", 0));
        require(!unlockOk, "unauthorized lockbox unlock succeeded");
    }
}

/// @dev All vm.etch cases explicitly replace the real L1CrossDomainMessenger code. They test the
///      deployed portal's cross-contract assumptions, not production reachability of the target.
contract AdversarialTargetsTest is RealWithdrawalBase {
    uint256 internal constant SUCCESSFUL_MESSAGES_SLOT = 203;
    uint256 internal constant FAILED_MESSAGES_SLOT = 206;
    bytes4 internal constant L1_CDM_CALL_FAILED =
        bytes4(keccak256("OptimismPortal_L1CDMCallFailed()"));

    function mappingBool(bytes32 messageHash, uint256 slot) internal view returns (bool) {
        return uint256(vm.load(L1_CDM, keccak256(abi.encode(messageHash, slot)))) != 0;
    }

    function lowLevelFinalize(Fixture memory fixture, uint256 suppliedGas)
        internal
        returns (bool ok, bytes4 selector)
    {
        bytes memory returndata;
        (ok, returndata) = PORTAL.call{ gas: suppliedGas }(
            abi.encodeCall(
                portal.finalizeWithdrawalTransactionExternalProof,
                (fixture.withdrawal, fixture.proofSubmitter)
            )
        );
        if (!ok && returndata.length >= 4) selector = bytes4(returndata);
    }

    function test_v9ReverterAndGasBurner_leaveMessengerWithdrawalReplayable() public {
        vm.createSelectFork("l1");
        Fixture memory fixture = loadFixture("post-messenger-value.json");
        matureAndResolve(fixture);
        uint256 initialSnapshot = vm.snapshotState();
        uint256 lockboxBefore = LOCKBOX.balance;
        uint256 portalBefore = PORTAL.balance;

        vm.etch(L1_CDM, hex"60006000fd"); // immediate revert
        (bool revertOk, bytes4 revertSelector) = lowLevelFinalize(fixture, 5_000_000);
        assertFalse(revertOk);
        assertEq(revertSelector, L1_CDM_CALL_FAILED);
        assertFalse(portal.finalizedWithdrawals(fixture.withdrawalHash));
        assertEq(LOCKBOX.balance, lockboxBefore);
        assertEq(PORTAL.balance, portalBefore);

        assertTrue(vm.revertToState(initialSnapshot));
        vm.etch(L1_CDM, hex"5b600056"); // JUMPDEST; PUSH1 0; JUMP forever
        (bool burnOk, bytes4 burnSelector) = lowLevelFinalize(fixture, 5_000_000);
        assertFalse(burnOk);
        assertEq(burnSelector, L1_CDM_CALL_FAILED);
        assertFalse(portal.finalizedWithdrawals(fixture.withdrawalHash));
        assertEq(LOCKBOX.balance, lockboxBefore);
        assertEq(PORTAL.balance, portalBefore);
    }

    function test_mockedSuccessfulNoopMessenger_canStillProduceFinalizedNeither() public {
        vm.createSelectFork("l1");
        Fixture memory fixture = loadFixture("post-messenger-value.json");
        matureAndResolve(fixture);
        bytes32 messageHash = keccak256(fixture.withdrawal.data);
        assertFalse(mappingBool(messageHash, SUCCESSFUL_MESSAGES_SLOT));
        assertFalse(mappingBool(messageHash, FAILED_MESSAGES_SLOT));

        // Returns 65,535 zero bytes. SafeCall copies no returndata, so this succeeds despite the
        // return bomb. This code is not the production messenger.
        vm.etch(L1_CDM, hex"61ffff6000f3");
        uint256 lockboxBefore = LOCKBOX.balance;
        uint256 messengerBefore = L1_CDM.balance;
        (bool ok,) = lowLevelFinalize(fixture, 5_000_000);

        assertTrue(ok);
        assertTrue(portal.finalizedWithdrawals(fixture.withdrawalHash));
        assertFalse(mappingBool(messageHash, SUCCESSFUL_MESSAGES_SLOT));
        assertFalse(mappingBool(messageHash, FAILED_MESSAGES_SLOT));
        assertEq(lockboxBefore - LOCKBOX.balance, fixture.withdrawal.value);
        assertEq(L1_CDM.balance - messengerBefore, fixture.withdrawal.value);
        assertEq(PORTAL.balance, 0);
    }

    function test_mockedReentrantMessenger_cannotDoubleFinalize() public {
        vm.createSelectFork("l1");
        Fixture memory fixture = loadFixture("post-messenger-zero-1.json");
        matureAndResolve(fixture);
        ReenteringTargetLane31 reenterer = new ReenteringTargetLane31();
        vm.etch(L1_CDM, address(reenterer).code);

        (bool ok,) = lowLevelFinalize(fixture, 5_000_000);
        assertTrue(ok, "outer finalization failed");
        assertTrue(portal.finalizedWithdrawals(fixture.withdrawalHash));
        assertEq(PORTAL.balance, 0);
    }
}
