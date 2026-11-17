// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

/// @notice Replays official OP Mainnet upgrade calls on an in-process fork.
/// @dev The fixture is the historical outer transaction (from/to/value/data/gas). The harness
///      impersonates only that historical sender and never broadcasts. It then compares every
///      tracked implementation locator with passive archive state at the real post-upgrade block.
contract UpgradeReplayTest is Test {
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

    function test_replay_v5() external {
        _replay("v5");
    }

    function test_replay_v6() external {
        _replay("v6");
    }

    function test_replay_v7() external {
        _replay("v7");
    }

    function test_replay_v8() external {
        _replay("v8");
    }

    function test_replay_v9() external {
        _replay("v9");
    }

    function _replay(string memory release) internal {
        string memory json = vm.readFile(string.concat("fixtures/upgrade-", release, ".json"));
        uint256 upgradeBlock = vm.parseJsonUint(json, ".block");
        uint256 upgradeTimestamp = vm.parseJsonUint(json, ".blockTimestamp");
        address sender = vm.parseJsonAddress(json, ".from");
        address target = vm.parseJsonAddress(json, ".to");
        uint256 value = vm.parseJsonUint(json, ".value");
        uint256 gasLimit = vm.parseJsonUint(json, ".gas");
        bytes memory input = vm.parseJsonBytes(json, ".input");

        vm.createSelectFork("archive", upgradeBlock - 1);
        // Preserve pre-block state but give the replay the official block environment.
        vm.roll(upgradeBlock);
        vm.warp(upgradeTimestamp);
        if (value != 0) vm.deal(sender, sender.balance + value);
        vm.prank(sender, sender);
        (bool ok, bytes memory returndata) = target.call{ value: value, gas: gasLimit }(input);
        if (!ok) {
            emit log_named_bytes(string.concat(release, " replay revert"), returndata);
            fail();
        }

        _assertImpl(json, ".expected.OptimismPortal", PORTAL, IMPLEMENTATION_SLOT);
        _assertImpl(json, ".expected.SystemConfig", SYSTEM_CONFIG, IMPLEMENTATION_SLOT);
        _assertImpl(
            json,
            ".expected.L1CrossDomainMessenger",
            ADDRESS_MANAGER,
            MESSENGER_ADDRESS_MANAGER_SLOT
        );
        _assertImpl(json, ".expected.L1StandardBridge", L1_STANDARD_BRIDGE, IMPLEMENTATION_SLOT);
        _assertImpl(json, ".expected.DisputeGameFactory", DGF, IMPLEMENTATION_SLOT);
        _assertImpl(json, ".expected.AnchorStateRegistry", ASR, IMPLEMENTATION_SLOT);
        _assertImpl(json, ".expected.ETHLockbox", ETH_LOCKBOX, IMPLEMENTATION_SLOT);
    }

    function _assertImpl(
        string memory json,
        string memory jsonPath,
        address storageAddress,
        bytes32 slot
    ) internal view {
        address expected = vm.parseJsonAddress(json, jsonPath);
        address actual = address(uint160(uint256(vm.load(storageAddress, slot))));
        assertEq(actual, expected, jsonPath);
    }
}
