// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

/// @notice Named, block-selectable OP Mainnet implementation discontinuities.
/// @dev The authoritative addresses/values/transaction hashes live in op-upgrade-blocks.json.
///      Masks cover durable block-end changes only; intra-transaction StorageSetter hops have no
///      selectable fork block and are intentionally not represented as independent points.
abstract contract HistoricalFork is Test {
    string internal constant ARCHIVE_RPC = "http://127.0.0.1:7545";
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant MESSENGER_ADDRESS_MANAGER_SLOT =
        0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e;

    address internal constant PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant SYSTEM_CONFIG = 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290;
    address internal constant ADDRESS_MANAGER = 0xdE1FCfB0851916CA5101820A69b13a4E276bd81F;
    address internal constant L1_STANDARD_BRIDGE = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
    address internal constant DGF = 0xe5965Ab5962eDc7477C8520243A95517CD252fA9;
    address internal constant ASR = 0x23B2C62946350F4246f9f9D027e071f0264FD113;
    address internal constant ETH_LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;

    uint8 internal constant M_PORTAL = 1 << 0;
    uint8 internal constant M_SYSTEM = 1 << 1;
    uint8 internal constant M_MESSENGER = 1 << 2;
    uint8 internal constant M_BRIDGE = 1 << 3;
    uint8 internal constant M_DGF = 1 << 4;
    uint8 internal constant M_ASR = 1 << 5;
    uint8 internal constant M_LOCKBOX = 1 << 6;

    struct ForkPoint {
        string name;
        uint64 afterBlock;
        uint8 changedMask;
    }

    function selectBefore(ForkPoint memory point) internal returns (uint256 forkId) {
        forkId = vm.createSelectFork(ARCHIVE_RPC, uint256(point.afterBlock) - 1);
    }

    function selectAfter(ForkPoint memory point) internal returns (uint256 forkId) {
        forkId = vm.createSelectFork(ARCHIVE_RPC, point.afterBlock);
    }

    function selectV5Before() internal returns (uint256) {
        return vm.createSelectFork(ARCHIVE_RPC, 23_877_376);
    }

    function selectV5After() internal returns (uint256) {
        return vm.createSelectFork(ARCHIVE_RPC, 23_877_377);
    }

    function selectV6Before() internal returns (uint256) {
        return vm.createSelectFork(ARCHIVE_RPC, 24_421_511);
    }

    function selectV6After() internal returns (uint256) {
        return vm.createSelectFork(ARCHIVE_RPC, 24_421_512);
    }

    function selectV7Before() internal returns (uint256) {
        return vm.createSelectFork(ARCHIVE_RPC, 25_397_810);
    }

    function selectV7After() internal returns (uint256) {
        return vm.createSelectFork(ARCHIVE_RPC, 25_397_811);
    }

    function selectV8Before() internal returns (uint256) {
        return vm.createSelectFork(ARCHIVE_RPC, 26_048_618);
    }

    function selectV8After() internal returns (uint256) {
        return vm.createSelectFork(ARCHIVE_RPC, 26_048_619);
    }

    function selectV9Before() internal returns (uint256) {
        return vm.createSelectFork(ARCHIVE_RPC, 26_430_858);
    }

    function selectV9After() internal returns (uint256) {
        return vm.createSelectFork(ARCHIVE_RPC, 26_430_859);
    }

    function historicalForkPoints() internal pure returns (ForkPoint[] memory p) {
        p = new ForkPoint[](22);
        p[0] = ForkPoint("OVM_XDM_GENESIS_ENTRY", 12_686_756, M_MESSENGER);
        p[1] = ForkPoint("OVM_BRIDGE_GENESIS_IMPL", 12_686_787, M_BRIDGE);
        p[2] = ForkPoint("OVM_XDM_PATCH_1", 12_706_528, M_MESSENGER);
        p[3] = ForkPoint("OVM_XDM_BRICK_FOR_UPGRADE", 13_596_294, M_MESSENGER);
        p[4] = ForkPoint("OVM_XDM_UNBRICK", 13_596_781, M_MESSENGER);
        p[5] = ForkPoint("OVM_BRIDGE_PATCH_1", 13_596_915, M_BRIDGE);
        p[6] = ForkPoint("BEDROCK_STAGE_SYSTEM_XDM_OFF", 17_422_444, M_SYSTEM | M_MESSENGER);
        p[7] = ForkPoint("BEDROCK_STAGE_PORTAL_XDM_BRIDGE", 17_423_158, M_PORTAL | M_MESSENGER | M_BRIDGE);
        p[8] = ForkPoint("U4_1", 19_314_493, M_PORTAL | M_SYSTEM | M_MESSENGER | M_BRIDGE);
        p[9] = ForkPoint("U5_1", 19_634_866, M_PORTAL | M_SYSTEM | M_MESSENGER | M_BRIDGE);
        p[10] = ForkPoint("FAULT_PROOFS_FACTORY_DEPLOY", 19_884_570, M_DGF);
        p[11] = ForkPoint("U6_1_MCP", 20_062_696, M_PORTAL | M_SYSTEM);
        p[12] = ForkPoint("SYSTEM_CONFIG_PATCH", 21_695_024, M_SYSTEM);
        p[13] = ForkPoint("U7_FAULT_PROOFS", 22_182_531, M_PORTAL | M_SYSTEM | M_MESSENGER | M_BRIDGE | M_DGF);
        p[14] = ForkPoint("U8", 22_339_996, M_PORTAL | M_SYSTEM | M_MESSENGER | M_BRIDGE);
        p[15] = ForkPoint(
            "U16_ETH_LOCKBOX",
            22_990_599,
            M_PORTAL | M_SYSTEM | M_MESSENGER | M_BRIDGE | M_DGF | M_ASR | M_LOCKBOX
        );
        p[16] = ForkPoint("U17", 23_491_328, M_PORTAL | M_SYSTEM | M_MESSENGER | M_BRIDGE);
        p[17] = ForkPoint("RELEASE_V5", 23_877_377, M_PORTAL | M_SYSTEM | M_MESSENGER | M_BRIDGE | M_DGF);
        p[18] = ForkPoint("RELEASE_V6", 24_421_512, M_PORTAL | M_SYSTEM | M_DGF | M_ASR);
        p[19] = ForkPoint("RELEASE_V7", 25_397_811, 0x7f);
        p[20] = ForkPoint("RELEASE_V8", 26_048_619, M_PORTAL | M_SYSTEM);
        p[21] = ForkPoint("RELEASE_V9_U21", 26_430_859, M_PORTAL | M_SYSTEM | M_MESSENGER | M_ASR | M_LOCKBOX);
    }

    function implementationAt(uint8 bit) internal view returns (address) {
        if (bit == M_MESSENGER) {
            return address(uint160(uint256(vm.load(ADDRESS_MANAGER, MESSENGER_ADDRESS_MANAGER_SLOT))));
        }
        address proxy;
        if (bit == M_PORTAL) proxy = PORTAL;
        else if (bit == M_SYSTEM) proxy = SYSTEM_CONFIG;
        else if (bit == M_BRIDGE) proxy = L1_STANDARD_BRIDGE;
        else if (bit == M_DGF) proxy = DGF;
        else if (bit == M_ASR) proxy = ASR;
        else if (bit == M_LOCKBOX) proxy = ETH_LOCKBOX;
        else revert("unknown implementation bit");
        return address(uint160(uint256(vm.load(proxy, IMPLEMENTATION_SLOT))));
    }
}

contract HistoricalForkTest is HistoricalFork {
    function test_all_named_fork_points_are_durable_slot_discontinuities() external {
        ForkPoint[] memory points = historicalForkPoints();
        uint8[7] memory bits = [M_PORTAL, M_SYSTEM, M_MESSENGER, M_BRIDGE, M_DGF, M_ASR, M_LOCKBOX];
        for (uint256 i; i < points.length; i++) {
            selectBefore(points[i]);
            address[7] memory beforeImpl;
            for (uint256 j; j < bits.length; j++) {
                if ((points[i].changedMask & bits[j]) != 0) beforeImpl[j] = implementationAt(bits[j]);
            }
            selectAfter(points[i]);
            for (uint256 j; j < bits.length; j++) {
                if ((points[i].changedMask & bits[j]) != 0) {
                    assertNotEq(implementationAt(bits[j]), beforeImpl[j], points[i].name);
                }
            }
        }
    }
}
