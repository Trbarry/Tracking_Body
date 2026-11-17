// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";

interface IPortal30 {
    function depositTransaction(address, uint256, uint64, bool, bytes calldata) external payable;
    function params() external view returns (uint128 prevBaseFee, uint64 prevBoughtGas, uint64 prevBlockNum);
}

interface ILockbox30 {
    function lockETH() external payable;
}

contract Lane30ResourceMeteringTest is Test {
    IPortal30 internal constant PORTAL = IPortal30(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    address internal constant LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;

    function setUp() external {
        vm.createSelectFork("l1n");
        vm.deal(address(this), 2 ether);
    }

    function test_directAttackerCannotEnterLockboxCallPath() external {
        vm.expectRevert();
        ILockbox30(LOCKBOX).lockETH{value: 1 wei}();
    }

    function test_invalidDepositRollsBackPreMeteringLockboxCall() external {
        uint256 lockboxBefore = LOCKBOX.balance;
        (uint128 feeBefore, uint64 boughtBefore, uint64 blockBefore) = PORTAL.params();

        // lockETH executes before this bad-target check, while metering executes after the body.
        vm.expectRevert();
        PORTAL.depositTransaction{value: 1 ether}(address(1), 1 ether, 100_000, true, hex"");

        assertEq(LOCKBOX.balance, lockboxBefore);
        (uint128 feeAfter, uint64 boughtAfter, uint64 blockAfter) = PORTAL.params();
        assertEq(feeAfter, feeBefore);
        assertEq(boughtAfter, boughtBefore);
        assertEq(blockAfter, blockBefore);
    }

    function test_validDepositLocksValueAndMetersAtomically() external {
        uint256 lockboxBefore = LOCKBOX.balance;
        (, uint64 boughtBefore,) = PORTAL.params();

        PORTAL.depositTransaction{value: 1 ether}(address(1), 1 ether, 100_000, false, hex"");

        assertEq(LOCKBOX.balance, lockboxBefore + 1 ether);
        (, uint64 boughtAfter,) = PORTAL.params();
        assertEq(boughtAfter, boughtBefore + 100_000);
    }
}
