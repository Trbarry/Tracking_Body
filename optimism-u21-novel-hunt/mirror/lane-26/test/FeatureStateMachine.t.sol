// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";

interface ISystemConfigFeatures26 {
    function owner() external view returns (address);
    function proxyAdmin() external view returns (address);
    function proxyAdminOwner() external view returns (address);
    function initVersion() external view returns (uint8);
    function l2ChainId() external view returns (uint256);
    function minimumGasLimit() external view returns (uint64);
    function maximumGasLimit() external view returns (uint64);
    function gasLimit() external view returns (uint64);
    function setGasLimit(uint64 value) external;
    function setFeature(bytes32 feature, bool enabled) external;
    function isFeatureEnabled(bytes32 feature) external view returns (bool);
    function isCustomGasToken() external view returns (bool);
}

interface IPortalCGT26 {
    function depositTransaction(address to, uint256 value, uint64 gasLimit, bool isCreation, bytes calldata data)
        external
        payable;
}

contract FeatureStateMachineTest is Test {
    address internal constant SYSTEM_CONFIG = 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290;
    address internal constant PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    address internal constant SYSTEM_CONFIG_OWNER = 0x847B5c174615B1B7fDF770882256e2D3E95b9D92;
    address internal constant PROXY_ADMIN_OWNER = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;

    bytes32 internal constant ETH_LOCKBOX = bytes32("ETH_LOCKBOX");
    bytes32 internal constant INTEROP = bytes32("INTEROP");
    bytes32 internal constant CUSTOM_GAS_TOKEN = bytes32("CUSTOM_GAS_TOKEN");
    bytes32 internal constant UNKNOWN = bytes32("LANE_26_UNKNOWN");

    ISystemConfigFeatures26 internal cfg = ISystemConfigFeatures26(SYSTEM_CONFIG);

    function setUp() public {
        vm.createSelectFork("l1n");
        vm.deal(address(this), 1 ether);
        assertEq(cfg.owner(), SYSTEM_CONFIG_OWNER);
        assertEq(cfg.proxyAdminOwner(), PROXY_ADMIN_OWNER);
        assertEq(cfg.initVersion(), 3);
        assertEq(cfg.l2ChainId(), 10);
    }

    function test_unprivilegedAndSystemConfigOwnerCannotSetFeatures() public {
        vm.expectRevert(abi.encodeWithSignature("ProxyAdminOwnedBase_NotProxyAdminOrProxyAdminOwner()"));
        cfg.setFeature(INTEROP, true);

        vm.prank(SYSTEM_CONFIG_OWNER);
        vm.expectRevert(abi.encodeWithSignature("ProxyAdminOwnedBase_NotProxyAdminOrProxyAdminOwner()"));
        cfg.setFeature(INTEROP, true);
    }

    function test_ethLockboxAndInteropAreOneWay() public {
        assertTrue(cfg.isFeatureEnabled(ETH_LOCKBOX));
        assertFalse(cfg.isFeatureEnabled(INTEROP));

        vm.prank(PROXY_ADMIN_OWNER);
        vm.expectRevert(abi.encodeWithSignature("SystemConfig_InvalidFeatureState()"));
        cfg.setFeature(ETH_LOCKBOX, false);

        vm.prank(PROXY_ADMIN_OWNER);
        cfg.setFeature(INTEROP, true);
        assertTrue(cfg.isFeatureEnabled(INTEROP));

        vm.prank(PROXY_ADMIN_OWNER);
        vm.expectRevert(abi.encodeWithSignature("SystemConfig_InvalidFeatureState()"));
        cfg.setFeature(INTEROP, false);
    }

    function test_cgtAndUnknownFeaturesRemainTwoWayToggles() public {
        assertGt(LOCKBOX.balance, 180_000 ether);
        assertFalse(cfg.isCustomGasToken());

        vm.prank(PROXY_ADMIN_OWNER);
        cfg.setFeature(CUSTOM_GAS_TOKEN, true);
        assertTrue(cfg.isCustomGasToken());

        // The real Portal immediately applies the new execution-time rule even though the
        // lockbox already holds production liquidity.
        vm.expectRevert(abi.encodeWithSignature("OptimismPortal_NotAllowedOnCGTMode()"));
        IPortalCGT26(PORTAL).depositTransaction{ value: 1 wei }(address(this), 1 wei, 21_000, false, hex"");

        vm.prank(PROXY_ADMIN_OWNER);
        cfg.setFeature(CUSTOM_GAS_TOKEN, false);
        assertFalse(cfg.isCustomGasToken());

        vm.startPrank(PROXY_ADMIN_OWNER);
        cfg.setFeature(UNKNOWN, true);
        assertTrue(cfg.isFeatureEnabled(UNKNOWN));
        cfg.setFeature(UNKNOWN, false);
        assertFalse(cfg.isFeatureEnabled(UNKNOWN));
        vm.stopPrank();
    }

    function test_gasLimitBoundsAreEnforcedOnSystemConfigOwner() public {
        uint64 minimum = cfg.minimumGasLimit();
        uint64 maximum = cfg.maximumGasLimit();
        assertEq(minimum, 21_000_000);
        assertEq(maximum, 500_000_000);

        vm.prank(SYSTEM_CONFIG_OWNER);
        vm.expectRevert(bytes("SystemConfig: gas limit too low"));
        cfg.setGasLimit(minimum - 1);

        vm.prank(SYSTEM_CONFIG_OWNER);
        vm.expectRevert(bytes("SystemConfig: gas limit too high"));
        cfg.setGasLimit(maximum + 1);

        vm.prank(SYSTEM_CONFIG_OWNER);
        cfg.setGasLimit(minimum);
        assertEq(cfg.gasLimit(), minimum);
    }
}
