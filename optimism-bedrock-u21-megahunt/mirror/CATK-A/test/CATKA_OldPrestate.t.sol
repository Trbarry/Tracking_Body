// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

interface IDisputeGameFactoryCATKA {
    function gameArgs(uint32 gameType) external view returns (bytes memory);
}

interface ISuperFaultDisputeGameCATKA {
    function absolutePrestate() external view returns (bytes32);
    function status() external view returns (uint8);
    function wasRespectedGameTypeWhenCreated() external view returns (bool);
    function maxClockDuration() external view returns (uint64);
    function getChallengerDuration(uint256 claimIndex) external view returns (uint64);
}

contract CATKAOldPrestateForkTest is Test {
    bytes32 internal constant OLD_PRESTATE =
        0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df;
    bytes32 internal constant NEW_PRESTATE =
        0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9;

    address[3] internal FACTORIES = [
        0xe5965Ab5962eDc7477C8520243A95517CD252fA9,
        0x10d7B35078d3baabB96Dd45a9143B94be65b12CD,
        0x2F12d621a16e2d3285929C9996f478508951dFe4
    ];

    address[3] internal OLD_GAMES = [
        0x675E956B1912Df79108408CA524fB37810500d10,
        0x40beC00713A38EE5fD697764D50f0055bA4942cc,
        0x3073a5f81798E353033Ba07cF19b49d6390a68d8
    ];

    address[3] internal NEW_GAMES = [
        0xc02e429475DA586b5458b3060fEc97b322dfD1B9,
        0x4393946a3786936fC0435bdBE248fe1748D791b0,
        0x53278636D07d6484Cefe9dF934012f037DC6f92C
    ];

    function _configuredPrestate(address factory) internal view returns (bytes32 prestate) {
        bytes memory args = IDisputeGameFactoryCATKA(factory).gameArgs(9);
        assertGe(args.length, 32);
        assembly ("memory-safe") {
            prestate := mload(add(args, 0x20))
        }
    }

    function test_preUpgradeFactoriesUseOldPrestate() public {
        vm.createSelectFork("l1pre");
        assertEq(block.number, 26_430_858);

        for (uint256 i; i < FACTORIES.length; ++i) {
            assertEq(_configuredPrestate(FACTORIES[i]), OLD_PRESTATE);
        }
    }

    function test_postUpgradeRotationPreservesLiveOldGames() public {
        vm.createSelectFork("l1");
        assertEq(block.number, 26_433_900);

        uint64[3] memory expectedDurations = [uint64(37_920), uint64(50_472), uint64(38_064)];
        for (uint256 i; i < FACTORIES.length; ++i) {
            assertEq(_configuredPrestate(FACTORIES[i]), NEW_PRESTATE);

            ISuperFaultDisputeGameCATKA oldGame = ISuperFaultDisputeGameCATKA(OLD_GAMES[i]);
            assertEq(oldGame.absolutePrestate(), OLD_PRESTATE);
            assertEq(oldGame.status(), 0); // IN_PROGRESS
            assertTrue(oldGame.wasRespectedGameTypeWhenCreated());
            assertEq(oldGame.maxClockDuration(), 302_400);
            assertEq(oldGame.getChallengerDuration(0), expectedDurations[i]);

            ISuperFaultDisputeGameCATKA newGame = ISuperFaultDisputeGameCATKA(NEW_GAMES[i]);
            assertEq(newGame.absolutePrestate(), NEW_PRESTATE);
            assertEq(newGame.status(), 0); // IN_PROGRESS
            assertTrue(newGame.wasRespectedGameTypeWhenCreated());
        }
    }
}
