// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";

interface ILockbox29 {
    error ETHLockbox_Unauthorized();
    error ETHLockbox_NoWithdrawalTransactions();
    error ProxyAdminOwnedBase_NotProxyAdminOwner();

    function authorizedPortals(address) external view returns (bool);
    function authorizedLockboxes(address) external view returns (bool);
    function superchainConfig() external view returns (address);
    function lockETH() external payable;
    function unlockETH(uint256) external;
    function receiveLiquidity() external payable;
    function migrateLiquidity(address) external;
}

interface IPortal29 {
    error OptimismPortal_BadTarget();
    error OptimismPortal_Unproven();

    event TransactionDeposited(address indexed from, address indexed to, uint256 indexed version, bytes opaqueData);

    struct WithdrawalTransaction {
        uint256 nonce;
        address sender;
        address target;
        uint256 value;
        uint256 gasLimit;
        bytes data;
    }

    function finalizeWithdrawalTransaction(WithdrawalTransaction calldata) external;
    function depositTransaction(address, uint256, uint64, bool, bytes calldata) external payable;
}

contract LockboxLane29Test is Test {
    address internal constant SUPERCHAIN_CONFIG = 0x95703e0982140D16f8ebA6d158FccEde42f04a4C;

    address[4] internal portals = [
        0xbEb5Fc579115071764c7423A4f12eDde41f106Ed,
        0x5d66C1782664115999C47c9fA5cd031f495D3e4F,
        0x88e529A6ccd302c948689Cd5156C83D4614FAE92,
        0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2
    ];

    address[4] internal lockboxes = [
        0x322b47Ff1FA8D5611F761e3E275C45B71b294D43,
        0xbd4AbB321138e8Eddc399cE64E66451294325a14,
        0x67B4de6FfA66EF201Ea6099A89cA397D56622E31,
        0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5
    ];

    function setUp() external {
        vm.createSelectFork("l1n");
    }

    function test_liveAuthorizationMatricesAreDiagonalAndLockboxMatrixEmpty() external view {
        for (uint256 i; i < 4; i++) {
            ILockbox29 lockbox = ILockbox29(lockboxes[i]);
            assertEq(lockbox.superchainConfig(), SUPERCHAIN_CONFIG);
            for (uint256 j; j < 4; j++) {
                assertEq(lockbox.authorizedPortals(portals[j]), i == j);
                assertFalse(lockbox.authorizedLockboxes(lockboxes[j]));
            }
        }
    }

    function test_realLockboxRejectsEOAButAuthorizedPortalCanChooseAmountWhenIdle() external {
        ILockbox29 lockbox = ILockbox29(lockboxes[0]);
        uint256 lockboxBefore = lockboxes[0].balance;
        uint256 portalBefore = portals[0].balance;

        vm.expectRevert(ILockbox29.ETHLockbox_Unauthorized.selector);
        lockbox.unlockETH(1);

        // Primitive only: impersonating the already-authorized production portal demonstrates
        // what the lockbox trusts; it is not an attacker-reachable call by itself.
        vm.prank(portals[0]);
        lockbox.unlockETH(1);
        assertEq(lockboxes[0].balance, lockboxBefore - 1);
        assertEq(portals[0].balance, portalBefore + 1);
    }

    function test_realLockboxRejectsAuthorizedPortalDuringWithdrawalContext() external {
        ILockbox29 lockbox = ILockbox29(lockboxes[0]);

        // Slot 50 is l2Sender in the pinned v9 storage layout. This models the exact transient
        // state used by a live portal while executing a withdrawal target.
        vm.store(portals[0], bytes32(uint256(50)), bytes32(uint256(uint160(address(0xBEEF)))));

        vm.prank(portals[0]);
        vm.expectRevert(ILockbox29.ETHLockbox_NoWithdrawalTransactions.selector);
        lockbox.unlockETH(1);
    }

    function test_realPortalBlocksOnlyItselfAndItsCurrentLockbox() external {
        IPortal29 portal = IPortal29(portals[0]);
        IPortal29.WithdrawalTransaction memory withdrawal = IPortal29.WithdrawalTransaction({
            nonce: 0, sender: address(1), target: portals[0], value: 0, gasLimit: 0, data: hex""
        });

        vm.expectRevert(IPortal29.OptimismPortal_BadTarget.selector);
        portal.finalizeWithdrawalTransaction(withdrawal);

        withdrawal.target = lockboxes[0];
        vm.expectRevert(IPortal29.OptimismPortal_BadTarget.selector);
        portal.finalizeWithdrawalTransaction(withdrawal);

        // Reaching Unproven rather than BadTarget proves the deployed filter accepts sibling
        // portals and sibling lockboxes. No proof state is mocked here.
        withdrawal.target = portals[3];
        vm.expectRevert(IPortal29.OptimismPortal_Unproven.selector);
        portal.finalizeWithdrawalTransaction(withdrawal);

        withdrawal.target = lockboxes[3];
        vm.expectRevert(IPortal29.OptimismPortal_Unproven.selector);
        portal.finalizeWithdrawalTransaction(withdrawal);
    }

    function test_siblingPortalAcceptsSourcePortalAndIndependentL2Value() external {
        IPortal29 sibling = IPortal29(portals[3]);
        address l2Recipient = address(0xCAFE);
        uint256 l2CallValue = 7 ether;
        uint64 gasLimit = 100_000;
        address aliasedSourcePortal = address(uint160(portals[0]) + uint160(0x1111000000000000000000000000000000001111));

        vm.expectEmit(true, true, true, true, portals[3]);
        emit IPortal29.TransactionDeposited(
            aliasedSourcePortal, l2Recipient, 0, abi.encodePacked(uint256(0), l2CallValue, gasLimit, false, bytes(""))
        );

        // Primitive only: a finalized withdrawal supplies this source-portal call context. The
        // zero mint and nonzero L2 call value demonstrate that the two fields are independent.
        vm.prank(portals[0]);
        sibling.depositTransaction(l2Recipient, l2CallValue, gasLimit, false, hex"");
    }

    function test_realOwnerAndAuthorizationGates() external {
        ILockbox29 lockbox = ILockbox29(lockboxes[0]);

        vm.expectRevert(ILockbox29.ETHLockbox_Unauthorized.selector);
        lockbox.lockETH();
        vm.expectRevert(ILockbox29.ETHLockbox_Unauthorized.selector);
        lockbox.receiveLiquidity();
        vm.expectRevert(ILockbox29.ProxyAdminOwnedBase_NotProxyAdminOwner.selector);
        lockbox.migrateLiquidity(lockboxes[3]);
    }
}
