// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

interface IFactory27 {
    function gameCount() external view returns (uint256);
    function gameAtIndex(uint256 index) external view returns (uint32 gameType, uint64 timestamp, address proxy);
}

interface IGame27 {
    function gameCreator() external pure returns (address);
    function rootClaim() external pure returns (bytes32);
    function extraData() external pure returns (bytes memory);
    function status() external view returns (uint8);
    function l2SequenceNumber() external pure returns (uint256);
    function createdAt() external view returns (uint64);
    function resolvedAt() external view returns (uint64);
    function wasRespectedGameTypeWhenCreated() external view returns (bool);
    function anchorStateRegistry() external pure returns (address);
}

contract GameInventoryTest is Test {
    IFactory27 internal constant FACTORY =
        IFactory27(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);

    function setUp() external {
        vm.createSelectFork("l1");
    }

    function test_inventoryLast30() external view {
        uint256 count = FACTORY.gameCount();
        assertEq(count, 21_389);
        for (uint256 i = count - 30; i < count; ++i) {
            (uint32 gameType, uint64 factoryTimestamp, address proxy) = FACTORY.gameAtIndex(i);
            IGame27 game = IGame27(proxy);
            console2.log("GAME", i);
            console2.log("proxy", proxy);
            console2.log("type", uint256(gameType));
            console2.log("creator", game.gameCreator());
            console2.logBytes32(game.rootClaim());
            console2.logBytes(game.extraData());
            console2.log("status", uint256(game.status()));
            console2.log("sequence", game.l2SequenceNumber());
            console2.log("factoryCreated", uint256(factoryTimestamp));
            console2.log("gameCreated", uint256(game.createdAt()));
            console2.log("resolved", uint256(game.resolvedAt()));
            console2.log("respectedAtCreation", game.wasRespectedGameTypeWhenCreated());
            console2.log("asr", game.anchorStateRegistry());
        }
    }
}
