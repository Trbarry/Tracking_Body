// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { RealWithdrawalBase } from "./RealWithdrawalBase.t.sol";
import { Vm } from "forge-std/Vm.sol";

interface IPortalDepositLane31 {
    function depositTransaction(
        address to,
        uint256 value,
        uint64 gasLimit,
        bool isCreation,
        bytes calldata data
    ) external payable;

    function minimumGasLimit(uint64 byteCount) external pure returns (uint64);
}

contract DepositDifferentialTest is RealWithdrawalBase {
    bytes32 internal constant DEPOSIT_TOPIC =
        keccak256("TransactionDeposited(address,address,uint256,bytes)");

    struct DepositOutcome {
        bool ok;
        bytes4 revertSelector;
        uint256 gasUsed;
        bytes32 eventDigest;
        uint256 portalDelta;
        uint256 lockboxDelta;
    }

    function runDeposit(bytes memory data, uint64 gasLimit, uint256 value)
        internal
        returns (DepositOutcome memory outcome)
    {
        vm.deal(address(this), value);
        uint256 portalBefore = PORTAL.balance;
        uint256 lockboxBefore = LOCKBOX.balance;
        vm.recordLogs();
        uint256 gasBefore = gasleft();
        bytes memory returndata;
        (outcome.ok, returndata) = PORTAL.call{ value: value }(
            abi.encodeCall(
                IPortalDepositLane31.depositTransaction,
                (address(0xD031), value, gasLimit, false, data)
            )
        );
        outcome.gasUsed = gasBefore - gasleft();
        if (!outcome.ok && returndata.length >= 4) outcome.revertSelector = bytes4(returndata);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i; i < logs.length; ++i) {
            if (logs[i].emitter == PORTAL && logs[i].topics[0] == DEPOSIT_TOPIC) {
                outcome.eventDigest = keccak256(abi.encode(logs[i].topics, logs[i].data));
            }
        }
        outcome.portalDelta = PORTAL.balance - portalBefore;
        outcome.lockboxDelta = LOCKBOX.balance - lockboxBefore;
    }

    function test_exactNMinus1ToN_largeCalldataDeposit_sameOutcome() public {
        bytes memory maxData = new bytes(120_000);
        maxData[0] = 0x31;
        maxData[maxData.length - 1] = 0x99;
        uint64 gasLimit = uint64(maxData.length * 40 + 21_000);

        vm.createSelectFork("l1pre");
        DepositOutcome memory pre = runDeposit(maxData, gasLimit, 0);
        uint64 preMinimum = IPortalDepositLane31(PORTAL).minimumGasLimit(uint64(maxData.length));

        vm.createSelectFork("l1n");
        DepositOutcome memory n = runDeposit(maxData, gasLimit, 0);
        uint64 nMinimum = IPortalDepositLane31(PORTAL).minimumGasLimit(uint64(maxData.length));

        assertTrue(pre.ok && n.ok, "max-size deposit diverged");
        assertEq(preMinimum, gasLimit);
        assertEq(nMinimum, gasLimit);
        assertEq(pre.eventDigest, n.eventDigest, "deposit event changed at N");
        assertEq(pre.portalDelta, 0);
        assertEq(pre.lockboxDelta, 0);
        assertEq(n.portalDelta, 0);
        assertEq(n.lockboxDelta, 0);
        emit log_named_uint("N-1 120k deposit gas", pre.gasUsed);
        emit log_named_uint("N 120k deposit gas", n.gasUsed);
    }

    function test_120001BytesAndUnderpricedGas_revertOnBothVersions() public {
        bytes memory oversized = new bytes(120_001);
        uint64 pricedGas = uint64(oversized.length * 40 + 21_000);

        vm.createSelectFork("l1pre");
        DepositOutcome memory preOversized = runDeposit(oversized, pricedGas, 0);
        DepositOutcome memory preUnderpriced = runDeposit(bytes("1234"), 21_159, 0);

        vm.createSelectFork("l1n");
        DepositOutcome memory nOversized = runDeposit(oversized, pricedGas, 0);
        DepositOutcome memory nUnderpriced = runDeposit(bytes("1234"), 21_159, 0);

        assertFalse(preOversized.ok || nOversized.ok);
        assertFalse(preUnderpriced.ok || nUnderpriced.ok);
        assertEq(preOversized.revertSelector, nOversized.revertSelector);
        assertEq(preUnderpriced.revertSelector, nUnderpriced.revertSelector);
    }

    function test_valueDepositMovesETHDirectlyToLockbox_notPortal() public {
        vm.createSelectFork("l1");
        DepositOutcome memory outcome = runDeposit(new bytes(4096), 184_840, 1 ether);
        assertTrue(outcome.ok);
        assertEq(outcome.portalDelta, 0);
        assertEq(outcome.lockboxDelta, 1 ether);
    }

    function test_exactNMinus1ToN_calldataGasCurve() public {
        uint256[] memory lengths = new uint256[](5);
        lengths[0] = 0;
        lengths[1] = 256;
        lengths[2] = 4096;
        lengths[3] = 32_768;
        lengths[4] = 120_000;
        uint256[] memory preGas = new uint256[](lengths.length);
        uint256[] memory nGas = new uint256[](lengths.length);

        vm.createSelectFork("l1pre");
        for (uint256 i; i < lengths.length; ++i) {
            bytes memory data = new bytes(lengths[i]);
            DepositOutcome memory outcome = runDeposit(
                data, uint64(lengths[i] * 40 + 21_000), 0
            );
            assertTrue(outcome.ok);
            preGas[i] = outcome.gasUsed;
        }

        vm.createSelectFork("l1n");
        for (uint256 i; i < lengths.length; ++i) {
            bytes memory data = new bytes(lengths[i]);
            DepositOutcome memory outcome = runDeposit(
                data, uint64(lengths[i] * 40 + 21_000), 0
            );
            assertTrue(outcome.ok);
            nGas[i] = outcome.gasUsed;
            emit log_named_uint("calldata bytes", lengths[i]);
            emit log_named_uint("N-1 gas", preGas[i]);
            emit log_named_uint("N gas", nGas[i]);
            emit log_named_int("N minus N-1", int256(nGas[i]) - int256(preGas[i]));
        }
    }
}
