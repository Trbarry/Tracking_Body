// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { RealWithdrawalBase, IFaultDisputeGameLane31 } from "./RealWithdrawalBase.t.sol";

interface ISuperchainConfigLane31 {
    function pause(address identifier) external;

    function isLocalOrGlobalPaused(address identifier) external view returns (bool);
}

interface IPauseViewLane31 {
    function paused() external view returns (bool);
}

interface IPortalActionsLane31 {
    function depositTransaction(
        address to,
        uint256 value,
        uint64 gasLimit,
        bool isCreation,
        bytes calldata data
    ) external payable;

    function donateETH() external payable;

    function numProofSubmitters(bytes32 withdrawalHash) external view returns (uint256);

    function deleteProvenWithdrawal(bytes32 withdrawalHash, address proofSubmitter) external;
}

interface IMessengerSendLane31 {
    function sendMessage(address target, bytes calldata message, uint32 minGasLimit) external payable;
}

contract PortalStateInvariantsTest is RealWithdrawalBase {
    address internal constant SUPERCHAIN_CONFIG = 0x95703e0982140D16f8ebA6d158FccEde42f04a4C;
    address internal constant SYSTEM_CONFIG = 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290;
    address internal constant GUARDIAN = 0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2;

    IPortalActionsLane31 internal constant portalActions = IPortalActionsLane31(PORTAL);

    function fixtureJson(string memory filename) internal view returns (string memory) {
        return vm.readFile(string.concat(FIXTURE_ROOT, filename));
    }

    /// @dev The Guardian prank is setup-only: it creates the exact production pause state exposed
    ///      by SuperchainConfig.pause(lockbox). No privileged behavior is part of an attack path.
    function test_pauseBlocksProofsFinalizationAndUnlocks_butKeepsInflowsOpen() public {
        vm.createSelectFork("l1");
        Fixture memory fixture = loadFixture("post-messenger-zero-1.json");
        matureAndResolve(fixture);
        bytes memory rawProveCalldata = vm.parseJsonBytes(
            fixtureJson("post-messenger-zero-1.json"), ".provenance.rawCalldata"
        );

        vm.prank(GUARDIAN);
        ISuperchainConfigLane31(SUPERCHAIN_CONFIG).pause(LOCKBOX);
        assertTrue(ISuperchainConfigLane31(SUPERCHAIN_CONFIG).isLocalOrGlobalPaused(LOCKBOX));
        assertTrue(IPauseViewLane31(PORTAL).paused());
        assertTrue(IPauseViewLane31(LOCKBOX).paused());
        assertTrue(IPauseViewLane31(SYSTEM_CONFIG).paused());
        assertTrue(IPauseViewLane31(L1_CDM).paused());

        (bool finalizeOk,) = PORTAL.call(
            abi.encodeCall(
                portal.finalizeWithdrawalTransactionExternalProof,
                (fixture.withdrawal, fixture.proofSubmitter)
            )
        );
        assertFalse(finalizeOk, "paused finalization succeeded");
        assertFalse(portal.finalizedWithdrawals(fixture.withdrawalHash));

        (bool proveOk,) = PORTAL.call(rawProveCalldata);
        assertFalse(proveOk, "paused proof succeeded");

        (bool unlockOk,) = LOCKBOX.call(abi.encodeWithSignature("unlockETH(uint256)", 1));
        assertFalse(unlockOk, "paused unlock succeeded");

        vm.deal(address(this), 10 ether);
        uint256 custodyBefore = PORTAL.balance + LOCKBOX.balance;
        uint256 portalBefore = PORTAL.balance;

        portalActions.depositTransaction{ value: 1 ether }(
            address(0xD031), 1 ether, 21_000, false, bytes("")
        );
        (bool receiveOk,) = PORTAL.call{ value: 1 ether }(bytes(""));
        assertTrue(receiveOk, "receive deposit blocked while paused");
        portalActions.donateETH{ value: 1 ether }();
        IMessengerSendLane31(L1_CDM).sendMessage{ value: 1 ether }(
            address(0xD032), bytes("paused-inflow"), 100_000
        );

        assertEq(LOCKBOX.balance + PORTAL.balance, custodyBefore + 4 ether);
        assertEq(PORTAL.balance, portalBefore + 1 ether, "only donateETH should remain in portal");
        assertEq(LOCKBOX.balance, custodyBefore - portalBefore + 3 ether);
    }

    function test_reproveIsolationAndFinalizationUniqueness_realProof() public {
        vm.createSelectFork("l1");
        Fixture memory fixture = loadFixture("post-messenger-zero-1.json");
        bytes memory rawProveCalldata = vm.parseJsonBytes(
            fixtureJson("post-messenger-zero-1.json"), ".provenance.rawCalldata"
        );
        address secondSubmitter = address(0x31310002);

        {
            (address originalGame, uint64 originalTimestamp) = portal.provenWithdrawals(
                fixture.withdrawalHash, fixture.proofSubmitter
            );
            uint256 countBefore = portalActions.numProofSubmitters(fixture.withdrawalHash);

            vm.prank(secondSubmitter);
            (bool firstProveOk,) = PORTAL.call(rawProveCalldata);
            assertTrue(firstProveOk, "same real proof failed for second submitter");
            (address secondGame, uint64 secondTimestamp) = portal.provenWithdrawals(
                fixture.withdrawalHash, secondSubmitter
            );
            assertEq(secondGame, originalGame);
            assertEq(portalActions.numProofSubmitters(fixture.withdrawalHash), countBefore + 1);
            (address originalGameAfter, uint64 originalTimestampAfter) = portal.provenWithdrawals(
                fixture.withdrawalHash, fixture.proofSubmitter
            );
            assertEq(originalGameAfter, originalGame);
            assertEq(originalTimestampAfter, originalTimestamp, "other submitter reset original timer");

            vm.warp(block.timestamp + 1);
            vm.prank(secondSubmitter);
            (bool reproveOk,) = PORTAL.call(rawProveCalldata);
            assertTrue(reproveOk, "same submitter could not reprove");
            (, uint64 resetTimestamp) = portal.provenWithdrawals(
                fixture.withdrawalHash, secondSubmitter
            );
            assertGt(resetTimestamp, secondTimestamp, "reprove did not reset own timer");
            assertEq(
                portalActions.numProofSubmitters(fixture.withdrawalHash),
                countBefore + 2,
                "reprove did not append documented duplicate"
            );
        }

        matureAndResolve(fixture);
        portal.finalizeWithdrawalTransactionExternalProof(
            fixture.withdrawal, fixture.proofSubmitter
        );
        assertTrue(portal.finalizedWithdrawals(fixture.withdrawalHash));

        vm.prank(secondSubmitter);
        (bool externalReplayOk,) = PORTAL.call(
            abi.encodeCall(
                portal.finalizeWithdrawalTransactionExternalProof,
                (fixture.withdrawal, secondSubmitter)
            )
        );
        assertFalse(externalReplayOk, "external proof bypassed finalized flag");

        vm.prank(fixture.proofSubmitter);
        (bool directReplayOk,) = PORTAL.call(
            abi.encodeCall(portal.finalizeWithdrawalTransaction, (fixture.withdrawal))
        );
        assertFalse(directReplayOk, "direct path bypassed finalized flag");
    }

    function test_deleteProvenWithdrawal_onlyDeletesPermanentlyInvalidProof() public {
        vm.createSelectFork("l1");
        Fixture memory invalidFixture = loadFixture("pre-plain-invalid-90000eth.json");
        (address gameBefore, uint64 timestampBefore) = portal.provenWithdrawals(
            invalidFixture.withdrawalHash, invalidFixture.proofSubmitter
        );
        assertEq(gameBefore, invalidFixture.disputeGame);
        assertGt(timestampBefore, 0);
        assertEq(IFaultDisputeGameLane31(gameBefore).status(), 1, "game not challenger-wins");

        portalActions.deleteProvenWithdrawal(
            invalidFixture.withdrawalHash, invalidFixture.proofSubmitter
        );
        (address gameAfter, uint64 timestampAfter) = portal.provenWithdrawals(
            invalidFixture.withdrawalHash, invalidFixture.proofSubmitter
        );
        assertEq(gameAfter, address(0));
        assertEq(timestampAfter, 0);
        assertFalse(portal.finalizedWithdrawals(invalidFixture.withdrawalHash));

        Fixture memory validFixture = loadFixture("post-messenger-zero-1.json");
        (bool validDeleteOk,) = PORTAL.call(
            abi.encodeCall(
                portalActions.deleteProvenWithdrawal,
                (validFixture.withdrawalHash, validFixture.proofSubmitter)
            )
        );
        assertFalse(validDeleteOk, "live in-progress proof was deletable");
    }
}
