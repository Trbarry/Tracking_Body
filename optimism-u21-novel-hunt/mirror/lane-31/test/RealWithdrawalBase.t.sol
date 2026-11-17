// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";

struct WithdrawalTransaction {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
}

interface IOptimismPortal2Lane31 {
    function provenWithdrawals(bytes32 withdrawalHash, address proofSubmitter)
        external
        view
        returns (address disputeGameProxy, uint64 timestamp);

    function finalizedWithdrawals(bytes32 withdrawalHash) external view returns (bool);

    function finalizeWithdrawalTransaction(WithdrawalTransaction calldata withdrawal) external;

    function finalizeWithdrawalTransactionExternalProof(
        WithdrawalTransaction calldata withdrawal,
        address proofSubmitter
    ) external;

    function proofMaturityDelaySeconds() external view returns (uint256);

    function anchorStateRegistry() external view returns (address);
}

interface IFaultDisputeGameLane31 {
    function status() external view returns (uint8);

    function createdAt() external view returns (uint64);

    function resolvedAt() external view returns (uint64);

    function maxClockDuration() external view returns (uint64);

    function resolveClaim(uint256 claimIndex, uint256 numToResolve) external;

    function resolve() external returns (uint8);
}

interface IAnchorStateRegistryLane31 {
    function disputeGameFinalityDelaySeconds() external view returns (uint256);

    function isGameClaimValid(address game) external view returns (bool);
}

interface IL1CrossDomainMessengerLane31 {
    function successfulMessages(bytes32 messageHash) external view returns (bool);

    function failedMessages(bytes32 messageHash) external view returns (bool);
}

abstract contract RealWithdrawalBase is Test {
    address internal constant PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    address internal constant L1_CDM = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address internal constant L2_CDM = 0x4200000000000000000000000000000000000007;
    bytes32 internal constant WITHDRAWAL_FINALIZED_TOPIC =
        keccak256("WithdrawalFinalized(bytes32,bool)");
    string internal constant FIXTURE_ROOT =
        "/home/user/Tracking_Body/optimism-u21-novel-hunt/mirror/lane-31/fixtures/";

    IOptimismPortal2Lane31 internal constant portal = IOptimismPortal2Lane31(PORTAL);
    IL1CrossDomainMessengerLane31 internal constant messenger = IL1CrossDomainMessengerLane31(L1_CDM);

    struct Fixture {
        WithdrawalTransaction withdrawal;
        bytes32 withdrawalHash;
        address proofSubmitter;
        address disputeGame;
        uint256 proofTimestamp;
    }

    function loadFixture(string memory filename) internal view returns (Fixture memory fixture) {
        string memory json = vm.readFile(string.concat(FIXTURE_ROOT, filename));

        fixture.withdrawal = WithdrawalTransaction({
            nonce: vm.parseUint(vm.parseJsonString(json, ".withdrawal.nonce")),
            sender: vm.parseJsonAddress(json, ".withdrawal.sender"),
            target: vm.parseJsonAddress(json, ".withdrawal.target"),
            value: vm.parseUint(vm.parseJsonString(json, ".withdrawal.value")),
            gasLimit: vm.parseUint(vm.parseJsonString(json, ".withdrawal.gasLimit")),
            data: vm.parseJsonBytes(json, ".withdrawal.data")
        });
        fixture.withdrawalHash = vm.parseJsonBytes32(json, ".provenance.withdrawalHash");
        fixture.proofSubmitter = vm.parseJsonAddress(json, ".provenance.proofSubmitter");
        fixture.disputeGame = vm.parseJsonAddress(json, ".observedState.disputeGame");
        fixture.proofTimestamp = vm.parseJsonUint(json, ".observedState.storedProofTimestamp");

        assertEq(hashWithdrawal(fixture.withdrawal), fixture.withdrawalHash, "fixture hash mismatch");
    }

    function hashWithdrawal(WithdrawalTransaction memory withdrawal) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                withdrawal.nonce,
                withdrawal.sender,
                withdrawal.target,
                withdrawal.value,
                withdrawal.gasLimit,
                withdrawal.data
            )
        );
    }

    /// @dev No prank is used: resolveClaim and resolve are permissionless after the real root
    ///      claim's clock expires. The time warp models the ordinary passage of time.
    function matureAndResolve(Fixture memory fixture) internal {
        (address storedGame, uint64 storedTimestamp) =
            portal.provenWithdrawals(fixture.withdrawalHash, fixture.proofSubmitter);
        assertEq(storedGame, fixture.disputeGame, "stored game changed");
        assertEq(storedTimestamp, fixture.proofTimestamp, "stored proof timestamp changed");

        IFaultDisputeGameLane31 game = IFaultDisputeGameLane31(storedGame);
        if (game.status() == 0) {
            vm.warp(uint256(game.createdAt()) + game.maxClockDuration() + 1);
            game.resolveClaim(0, 0);
            assertEq(game.resolve(), 2, "real game did not resolve for defender");
        }
        assertEq(game.status(), 2, "fixture game is not defender-wins");

        IAnchorStateRegistryLane31 registry =
            IAnchorStateRegistryLane31(portal.anchorStateRegistry());
        uint256 proofReadyAt = uint256(storedTimestamp) + portal.proofMaturityDelaySeconds() + 1;
        uint256 gameReadyAt =
            uint256(game.resolvedAt()) + registry.disputeGameFinalityDelaySeconds() + 1;
        vm.warp(proofReadyAt > gameReadyAt ? proofReadyAt : gameReadyAt);
        assertTrue(registry.isGameClaimValid(storedGame), "real game claim did not become valid");
    }

    function findPortalFinalizedLog(Vm.Log[] memory logs, bytes32 withdrawalHash)
        internal
        pure
        returns (bool found, bool success)
    {
        for (uint256 i; i < logs.length; ++i) {
            if (
                logs[i].emitter == PORTAL && logs[i].topics.length == 2
                    && logs[i].topics[0] == WITHDRAWAL_FINALIZED_TOPIC
                    && logs[i].topics[1] == withdrawalHash
            ) {
                return (true, abi.decode(logs[i].data, (bool)));
            }
        }
    }
}
