// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { RealWithdrawalBase } from "./RealWithdrawalBase.t.sol";

contract MessengerGasBoundaryTest is RealWithdrawalBase {
    struct Outcome {
        bool callSucceeded;
        bool finalized;
        bool relayed;
        bool failedMessage;
        bytes4 revertSelector;
    }

    Fixture internal fixture;
    bytes32 internal messageHash;

    function setUp() public {
        vm.createSelectFork("l1");
        fixture = loadFixture("post-messenger-zero-1.json");
        matureAndResolve(fixture);
        messageHash = keccak256(fixture.withdrawal.data);
        assertFalse(portal.finalizedWithdrawals(fixture.withdrawalHash));
        assertFalse(messenger.successfulMessages(messageHash));
        assertFalse(messenger.failedMessages(messageHash));
    }

    function runWithGas(uint256 suppliedGas) internal returns (Outcome memory outcome) {
        uint256 snapshot = vm.snapshotState();
        bytes memory returndata;
        (outcome.callSucceeded, returndata) = PORTAL.call{ gas: suppliedGas }(
            abi.encodeCall(
                portal.finalizeWithdrawalTransactionExternalProof,
                (fixture.withdrawal, fixture.proofSubmitter)
            )
        );
        outcome.finalized = portal.finalizedWithdrawals(fixture.withdrawalHash);
        outcome.relayed = messenger.successfulMessages(messageHash);
        outcome.failedMessage = messenger.failedMessages(messageHash);
        if (!outcome.callSucceeded && returndata.length >= 4) {
            assembly {
                mstore(add(outcome, 0x80), mload(add(returndata, 0x20)))
            }
        }

        assertFalse(
            outcome.finalized && !outcome.relayed && !outcome.failedMessage,
            "SERIOUS: finalized messenger withdrawal recorded neither outcome"
        );
        assertTrue(vm.revertToStateAndDelete(snapshot), "snapshot restore failed");
    }

    function minimumGasForCallSuccess(uint256 low, uint256 high) internal returns (uint256) {
        require(runWithGas(high).callSucceeded, "upper bound does not succeed");
        while (low < high) {
            uint256 mid = low + (high - low) / 2;
            if (runWithGas(mid).callSucceeded) high = mid;
            else low = mid + 1;
        }
        return low;
    }

    function minimumGasForRelay(uint256 low, uint256 high) internal returns (uint256) {
        require(runWithGas(high).relayed, "upper bound does not relay");
        while (low < high) {
            uint256 mid = low + (high - low) / 2;
            if (runWithGas(mid).relayed) high = mid;
            else low = mid + 1;
        }
        return low;
    }

    function test_binarySearchExactBoundaries_noFinalizedNeither() public {
        uint256 minCallSuccess = minimumGasForCallSuccess(100_000, 2_000_000);
        uint256 minRelay = minimumGasForRelay(minCallSuccess, 2_000_000);
        emit log_named_uint("minimum outer gas for non-reverting finalization", minCallSuccess);
        emit log_named_uint("minimum outer gas for successful inner relay", minRelay);

        Outcome memory belowCall = runWithGas(minCallSuccess - 1);
        Outcome memory atCall = runWithGas(minCallSuccess);
        Outcome memory belowRelay = runWithGas(minRelay - 1);
        Outcome memory atRelay = runWithGas(minRelay);

        assertFalse(belowCall.callSucceeded, "call succeeded below exact boundary");
        assertFalse(belowCall.finalized, "reverting call finalized withdrawal");
        assertTrue(atCall.callSucceeded, "call failed at exact boundary");
        assertTrue(atCall.finalized, "successful call did not finalize");
        assertTrue(atCall.relayed || atCall.failedMessage, "no messenger outcome at call boundary");
        assertFalse(belowRelay.relayed, "relay succeeded below exact boundary");
        assertTrue(atRelay.relayed, "relay failed at exact boundary");
    }

    function testFuzz_gasClassificationNeverFinalizedNeither(uint32 suppliedGas) public {
        suppliedGas = uint32(bound(suppliedGas, 100_000, 2_000_000));
        Outcome memory outcome = runWithGas(suppliedGas);
        if (outcome.callSucceeded) {
            assertTrue(outcome.finalized, "non-reverting finalize call did not finalize");
            assertTrue(outcome.relayed || outcome.failedMessage, "missing messenger outcome");
        } else {
            assertFalse(outcome.finalized, "reverting finalize call changed state");
        }
    }

    function test_deterministic128PointSweep_noFinalizedNeither() public {
        uint256 reverted;
        uint256 finalizedRelayed;
        uint256 finalizedFailed;
        uint256 finalizedNeither;
        for (uint256 i; i < 128; ++i) {
            uint256 suppliedGas = 100_000 + uint256(keccak256(abi.encode(i))) % 1_900_001;
            Outcome memory outcome = runWithGas(suppliedGas);
            if (!outcome.callSucceeded) {
                ++reverted;
            } else if (outcome.relayed) {
                ++finalizedRelayed;
            } else if (outcome.failedMessage) {
                ++finalizedFailed;
            } else {
                ++finalizedNeither;
            }
        }

        emit log_named_uint("classification: reverted", reverted);
        emit log_named_uint("classification: finalized + relayed", finalizedRelayed);
        emit log_named_uint("classification: finalized + failedMessages", finalizedFailed);
        emit log_named_uint("classification: finalized + neither", finalizedNeither);
        assertEq(reverted + finalizedRelayed + finalizedFailed + finalizedNeither, 128);
        assertEq(finalizedNeither, 0, "SERIOUS: deterministic sweep found neither outcome");
    }
}
