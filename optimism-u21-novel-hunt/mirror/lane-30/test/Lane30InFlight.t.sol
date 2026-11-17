// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";

interface ISuperFaultGame30 {
    function createdAt() external view returns (uint64);
    function resolvedAt() external view returns (uint64);
    function status() external view returns (uint8);
    function claimDataLen() external view returns (uint256);
    function gameCreator() external view returns (address);
    function absolutePrestate() external view returns (bytes32);
    function vm() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function weth() external view returns (address);
    function maxClockDuration() external view returns (uint64);
    function bondDistributionMode() external view returns (uint8);
    function normalModeCredit(address) external view returns (uint256);
    function resolveClaim(uint256, uint256) external;
    function resolve() external returns (uint8);
    function closeGame() external;
    function claimCredit(address) external;
}

interface IDelayedWETH30 {
    function delay() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function withdrawals(address, address) external view returns (uint256 amount, uint256 timestamp);
}

interface IAnchorStateRegistry30 {
    function paused() external view returns (bool);
    function isGameProper(address) external view returns (bool);
    function isGameFinalized(address) external view returns (bool);
    function disputeGameFinalityDelaySeconds() external view returns (uint256);
}

contract Lane30InFlightTest is Test {
    // Last game created before U21 (DGF index 21,377). It had only its root claim at block N.
    ISuperFaultGame30 internal constant GAME =
        ISuperFaultGame30(0x675E956B1912Df79108408CA524fB37810500d10);
    address internal constant ASR = 0x23B2C62946350F4246f9f9D027e071f0264FD113;
    address internal constant WETH = 0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162;
    address internal constant VM = 0xaCc005DCd857B401e4732E6F7837135A22825cfA;
    bytes32 internal constant PRE_U21_PRESTATE =
        0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df;

    function setUp() external {
        vm.createSelectFork("l1n");
    }

    function test_preUpgradeGameStillReferencesPreservedSingletons() external view {
        assertEq(GAME.status(), 0);
        assertEq(GAME.claimDataLen(), 1);
        assertEq(GAME.absolutePrestate(), PRE_U21_PRESTATE);
        assertEq(GAME.vm(), VM);
        assertEq(GAME.anchorStateRegistry(), ASR);
        assertEq(GAME.weth(), WETH);
        assertEq(IDelayedWETH30(WETH).balanceOf(address(GAME)), 0.08 ether);
        assertFalse(IAnchorStateRegistry30(ASR).paused());
    }

    function test_realInFlightGameResolvesClosesAndPaysAfterU21() external {
        address recipient = GAME.gameCreator();
        uint256 recipientBefore = recipient.balance;

        vm.warp(uint256(GAME.createdAt()) + uint256(GAME.maxClockDuration()) + 1);
        GAME.resolveClaim(0, 0);
        assertEq(GAME.resolve(), 2); // DEFENDER_WINS

        uint256 finalityDelay = IAnchorStateRegistry30(ASR).disputeGameFinalityDelaySeconds();
        vm.warp(uint256(GAME.resolvedAt()) + finalityDelay + 1);
        assertTrue(IAnchorStateRegistry30(ASR).isGameFinalized(address(GAME)));

        GAME.closeGame();
        assertEq(GAME.bondDistributionMode(), 1); // NORMAL
        assertTrue(IAnchorStateRegistry30(ASR).isGameProper(address(GAME)));
        assertEq(GAME.normalModeCredit(recipient), 0.08 ether);

        // The first claim call starts the DelayedWETH withdrawal delay.
        GAME.claimCredit(recipient);
        (uint256 unlockedAmount, uint256 unlockTimestamp) =
            IDelayedWETH30(WETH).withdrawals(address(GAME), recipient);
        assertEq(unlockedAmount, 0.08 ether);

        vm.warp(unlockTimestamp + IDelayedWETH30(WETH).delay());
        GAME.claimCredit(recipient);

        assertEq(recipient.balance, recipientBefore + 0.08 ether);
        assertEq(IDelayedWETH30(WETH).balanceOf(address(GAME)), 0);
    }
}
