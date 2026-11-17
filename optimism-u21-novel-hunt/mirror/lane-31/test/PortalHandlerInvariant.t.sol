// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import {
    RealWithdrawalBase,
    WithdrawalTransaction,
    IOptimismPortal2Lane31,
    IL1CrossDomainMessengerLane31
} from "./RealWithdrawalBase.t.sol";

interface IPortalHandlerActionsLane31 {
    function depositTransaction(
        address to,
        uint256 value,
        uint64 gasLimit,
        bool isCreation,
        bytes calldata data
    ) external payable;

    function donateETH() external payable;

    function deleteProvenWithdrawal(bytes32 withdrawalHash, address proofSubmitter) external;

    function l2Sender() external view returns (address);
}

interface ISuperchainHandlerLane31 {
    function pause(address identifier) external;

    function extend(address identifier) external;

    function pausable(address identifier) external view returns (bool);
}

contract PortalHandlerLane31 is Test {
    address internal constant PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    address internal constant L1_CDM = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address internal constant SUPERCHAIN_CONFIG = 0x95703e0982140D16f8ebA6d158FccEde42f04a4C;
    address internal constant GUARDIAN = 0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2;

    IOptimismPortal2Lane31 internal constant portal = IOptimismPortal2Lane31(PORTAL);
    IPortalHandlerActionsLane31 internal constant actions = IPortalHandlerActionsLane31(PORTAL);
    IL1CrossDomainMessengerLane31 internal constant messenger =
        IL1CrossDomainMessengerLane31(L1_CDM);

    WithdrawalTransaction internal withdrawal;
    bytes32 public immutable withdrawalHash;
    address public immutable proofSubmitter;
    bytes32 public immutable messageHash;
    bytes internal rawProveCalldata;

    uint256 public immutable initialCustody;
    uint256 public deposited;
    uint256 public donated;
    uint256 public delivered;
    bool public finalizedByHandler;

    constructor(
        WithdrawalTransaction memory withdrawal_,
        bytes32 withdrawalHash_,
        address proofSubmitter_,
        bytes memory rawProveCalldata_
    ) {
        withdrawal = withdrawal_;
        withdrawalHash = withdrawalHash_;
        proofSubmitter = proofSubmitter_;
        messageHash = keccak256(withdrawal_.data);
        rawProveCalldata = rawProveCalldata_;
        initialCustody = PORTAL.balance + LOCKBOX.balance;
    }

    function actionDeposit(uint96 rawValue, uint16 rawLength, address target) external {
        uint256 value = bound(uint256(rawValue), 0, 1 ether);
        uint256 length = bound(uint256(rawLength), 0, 1024);
        target = address(uint160(0xD000 + (uint160(target) % 64)));
        bytes memory data = new bytes(length);
        vm.deal(address(this), value);
        actions.depositTransaction{ value: value }(
            target, value, uint64(length * 40 + 21_000), false, data
        );
        deposited += value;
    }

    function actionDonate(uint96 rawValue) external {
        uint256 value = bound(uint256(rawValue), 0, 1 ether);
        vm.deal(address(this), value);
        actions.donateETH{ value: value }();
        donated += value;
    }

    function actionProveAsAnotherSubmitter(uint160 rawActor) external {
        address actor = address(uint160(0x31310000 + (rawActor % 16)));
        vm.deal(actor, 0);
        vm.prank(actor);
        PORTAL.call(rawProveCalldata);
    }

    function actionFinalizeOrReplay() external {
        bool wasFinalized = portal.finalizedWithdrawals(withdrawalHash);
        (bool ok,) = PORTAL.call(
            abi.encodeCall(
                portal.finalizeWithdrawalTransactionExternalProof,
                (withdrawal, proofSubmitter)
            )
        );
        bool nowFinalized = portal.finalizedWithdrawals(withdrawalHash);
        if (!wasFinalized && ok && nowFinalized) {
            finalizedByHandler = true;
            delivered += withdrawal.value;
        }
        if (wasFinalized) assertFalse(ok, "finalized withdrawal replay succeeded");
    }

    function actionDeleteValidProof() external {
        (bool ok,) = PORTAL.call(
            abi.encodeCall(actions.deleteProvenWithdrawal, (withdrawalHash, proofSubmitter))
        );
        assertFalse(ok, "valid defender-wins proof was deleted");
    }

    function actionWarp(uint32 rawDelta) external {
        vm.warp(block.timestamp + bound(uint256(rawDelta), 0, 120 days));
    }

    /// @dev Guardian prank models the ordinary production pause transition only.
    function actionPauseOrExtend() external {
        ISuperchainHandlerLane31 config = ISuperchainHandlerLane31(SUPERCHAIN_CONFIG);
        bool canPause = config.pausable(LOCKBOX);
        vm.prank(GUARDIAN);
        if (canPause) config.pause(LOCKBOX);
        else config.extend(LOCKBOX);
    }

    function realMessengerRecordedOutcome() external view returns (bool) {
        return messenger.successfulMessages(messageHash) || messenger.failedMessages(messageHash);
    }

    function currentCustody() external view returns (uint256) {
        return PORTAL.balance + LOCKBOX.balance;
    }

    function portalBalance() external view returns (uint256) {
        return PORTAL.balance;
    }

    function lockboxBalance() external view returns (uint256) {
        return LOCKBOX.balance;
    }

    function portalL2Sender() external view returns (address) {
        return actions.l2Sender();
    }
}

contract PortalHandlerInvariantTest is RealWithdrawalBase {
    address internal constant DEFAULT_L2_SENDER = 0x000000000000000000000000000000000000dEaD;
    PortalHandlerLane31 internal handler;

    function setUp() public {
        vm.createSelectFork("l1");
        Fixture memory fixture = loadFixture("post-messenger-value.json");
        matureAndResolve(fixture);
        string memory json = vm.readFile(string.concat(FIXTURE_ROOT, "post-messenger-value.json"));
        bytes memory rawProveCalldata = vm.parseJsonBytes(json, ".provenance.rawCalldata");
        handler = new PortalHandlerLane31(
            fixture.withdrawal,
            fixture.withdrawalHash,
            fixture.proofSubmitter,
            rawProveCalldata
        );
        address invariantCaller = address(0x3131F00D);
        vm.deal(invariantCaller, 100 ether);
        targetSender(invariantCaller);
        targetContract(address(handler));
    }

    function assertEthCustodyConservation() internal view {
        assertEq(
            handler.currentCustody(),
            handler.initialCustody() + handler.deposited() + handler.donated() - handler.delivered(),
            "portal+lockbox custody equation violated"
        );
    }

    function assertPortalHoldsOnlyExplicitDonations() internal view {
        assertEq(handler.portalBalance(), handler.donated(), "unexpected ETH retained in portal");
    }

    function assertFinalizedMessengerHasRecordedOutcome() internal view {
        if (handler.finalizedByHandler()) {
            assertTrue(handler.realMessengerRecordedOutcome(), "finalized messenger has neither outcome");
        }
    }

    function assertL2SenderAlwaysRestored() internal view {
        assertEq(handler.portalL2Sender(), DEFAULT_L2_SENDER, "portal left in reentrant state");
    }

    function assertAllInvariants() internal view {
        assertEthCustodyConservation();
        assertPortalHoldsOnlyExplicitDonations();
        assertFinalizedMessengerHasRecordedOutcome();
        assertL2SenderAlwaysRestored();
    }

    function test_handlerDeterministicStateMachineSweep() public {
        for (uint256 i; i < 36; ++i) {
            uint256 action = i % 6;
            if (action == 0) {
                handler.actionDeposit(
                    uint96((i + 1) * 0.01 ether),
                    uint16((i * 173) % 1025),
                    address(uint160(0xD000 + i))
                );
            } else if (action == 1) {
                handler.actionDonate(uint96((i + 1) * 0.001 ether));
            } else if (action == 2) {
                handler.actionFinalizeOrReplay();
            } else if (action == 3) {
                handler.actionDeleteValidProof();
            } else if (action == 4) {
                handler.actionWarp(uint32(i % 2 == 0 ? 10 days : 100 days));
            } else {
                handler.actionPauseOrExtend();
            }
            assertAllInvariants();
        }
    }

    function invariant_ethCustodyConservation() public view {
        assertEthCustodyConservation();
    }

    function invariant_portalHoldsOnlyExplicitDonations() public view {
        assertPortalHoldsOnlyExplicitDonations();
    }

    function invariant_finalizedMessengerHasRecordedOutcome() public view {
        assertFinalizedMessengerHasRecordedOutcome();
    }

    function invariant_l2SenderAlwaysRestored() public view {
        assertL2SenderAlwaysRestored();
    }
}
