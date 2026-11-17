// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { RealWithdrawalBase, WithdrawalTransaction } from "./RealWithdrawalBase.t.sol";

/// @dev This suite isolates deployed implementation behavior with a vm.store-injected proof.
///      The proof state is intentionally mocked and is not evidence that the crafted withdrawal
///      exists on L2. Real fixtures are used only to supply a production-valid, matured game.
contract NewAccountGasDifferentialTest is RealWithdrawalBase {
    address internal constant EMPTY_TARGET = 0x00000000000000000000000000000000BeEf0031;
    uint256 internal constant PROVEN_WITHDRAWALS_SLOT = 57;

    struct DirectFixture {
        WithdrawalTransaction withdrawal;
        bytes32 withdrawalHash;
        address proofSubmitter;
    }

    function injectProof(
        bytes32 withdrawalHash,
        address proofSubmitter,
        address game,
        uint64 timestamp
    ) internal {
        bytes32 firstMappingSlot = keccak256(
            abi.encode(withdrawalHash, PROVEN_WITHDRAWALS_SLOT)
        );
        bytes32 valueSlot = keccak256(abi.encode(proofSubmitter, firstMappingSlot));
        uint256 packed = uint256(uint160(game)) | (uint256(timestamp) << 160);
        vm.store(PORTAL, valueSlot, bytes32(packed));
    }

    function makeDirectFixture(Fixture memory realFixture)
        internal
        returns (DirectFixture memory direct)
    {
        direct.withdrawal = WithdrawalTransaction({
            nonce: realFixture.withdrawal.nonce + 31,
            sender: address(0x3131),
            target: EMPTY_TARGET,
            value: 1 wei,
            gasLimit: 100_000,
            data: bytes("")
        });
        direct.withdrawalHash = hashWithdrawal(direct.withdrawal);
        direct.proofSubmitter = address(0x313131);
        injectProof(
            direct.withdrawalHash,
            direct.proofSubmitter,
            realFixture.disputeGame,
            uint64(block.timestamp - portal.proofMaturityDelaySeconds() - 1)
        );
        (address storedGame, uint64 storedTimestamp) = portal.provenWithdrawals(
            direct.withdrawalHash, direct.proofSubmitter
        );
        assertEq(storedGame, realFixture.disputeGame);
        assertGt(storedTimestamp, 0);
    }

    function classify(
        DirectFixture memory direct,
        uint256 suppliedGas,
        bool installCode
    ) internal returns (bool callSucceeded, bool finalized, uint256 targetDelta) {
        uint256 snapshot = vm.snapshotState();
        if (installCode) vm.etch(EMPTY_TARGET, hex"00");
        uint256 targetBefore = EMPTY_TARGET.balance;
        (callSucceeded,) = PORTAL.call{ gas: suppliedGas }(
            abi.encodeCall(
                portal.finalizeWithdrawalTransactionExternalProof,
                (direct.withdrawal, direct.proofSubmitter)
            )
        );
        finalized = portal.finalizedWithdrawals(direct.withdrawalHash);
        targetDelta = EMPTY_TARGET.balance - targetBefore;
        assertTrue(vm.revertToStateAndDelete(snapshot));
    }

    function binarySearchMin(
        DirectFixture memory direct,
        bool installCode
    ) internal returns (uint256 low) {
        low = 100_000;
        uint256 high = 1_500_000;
        (bool highOk,,) = classify(direct, high, installCode);
        require(highOk, "upper bound failed");
        while (low < high) {
            uint256 mid = low + (high - low) / 2;
            (bool ok,,) = classify(direct, mid, installCode);
            if (ok) high = mid;
            else low = mid + 1;
        }
    }

    function test_v9EmptyAccountReservationIncludes183600Gas_mockedProofOnly() public {
        // Publicnode no longer serves block 26,433,900 without a token. A near-head fork has the
        // same deployed v9 implementations; this test isolates code, not a changing state claim.
        vm.createSelectFork("l1public");
        Fixture memory realFixture = loadFixture("post-messenger-zero-1.json");
        matureAndResolve(realFixture);
        assertEq(EMPTY_TARGET.codehash, bytes32(0), "chosen target exists");
        DirectFixture memory direct = makeDirectFixture(realFixture);

        uint256 codeTargetMin = binarySearchMin(direct, true);
        uint256 emptyTargetMin = binarySearchMin(direct, false);
        emit log_named_uint("v9 min gas, nonempty-code target", codeTargetMin);
        emit log_named_uint("v9 min gas, empty target", emptyTargetMin);
        emit log_named_uint("v9 empty-account reservation delta", emptyTargetMin - codeTargetMin);

        // SafeCall adds exactly 183,600 to its hasMinGas reserve. The measured outer-call
        // boundary also includes the different cold-account/CALL costs of the two target states.
        assertGe(emptyTargetMin - codeTargetMin, 183_600, "reservation missing");
        assertLe(emptyTargetMin - codeTargetMin, 187_000, "unexpected outer-cost delta");
        (bool belowOk, bool belowFinalized,) = classify(direct, emptyTargetMin - 1, false);
        (bool atOk, bool atFinalized, uint256 delivered) = classify(direct, emptyTargetMin, false);
        assertFalse(belowOk || belowFinalized, "empty-account call succeeded below boundary");
        assertTrue(atOk && atFinalized, "empty-account call failed at boundary");
        assertEq(delivered, 1 wei, "value not delivered at boundary");
    }

    function test_v8ToV9EmptyAccountMinimumGasDiff_mockedProofOnly() public {
        vm.createSelectFork("l1pre");
        Fixture memory preReal = loadFixture("pre-messenger-zero.json");
        matureAndResolve(preReal);
        assertEq(EMPTY_TARGET.codehash, bytes32(0));
        DirectFixture memory v8Direct = makeDirectFixture(preReal);
        uint256 v8Min = binarySearchMin(v8Direct, false);

        vm.createSelectFork("l1public");
        Fixture memory postReal = loadFixture("post-messenger-zero-1.json");
        matureAndResolve(postReal);
        assertEq(EMPTY_TARGET.codehash, bytes32(0));
        DirectFixture memory v9Direct = makeDirectFixture(postReal);
        uint256 v9Min = binarySearchMin(v9Direct, false);

        emit log_named_uint("v8 empty-account minimum outer gas", v8Min);
        emit log_named_uint("v9 empty-account minimum outer gas", v9Min);
        emit log_named_int("v9 minus v8 minimum outer gas", int256(v9Min) - int256(v8Min));
        // The cross-version delta nets the new 183,600 reserve against unrelated portal
        // implementation gas changes; the same-version target-state test isolates the reserve.
        assertGt(v9Min, v8Min + 170_000, "expected large v9 empty-account gas increase");
    }
}
