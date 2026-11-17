// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";

interface IPortal {
    function version() external view returns (string memory);
    function ethLockbox() external view returns (address);
    function paused() external view returns (bool);
}

contract SanityTest is Test {
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);

    function setUp() public {
        vm.createSelectFork("l1"); // pinned by the local anvil at block 26433900
    }

    function test_sanity() public view {
        assertEq(PORTAL.version(), "6.1.0");
        assertEq(block.number, 26433900);
        assertGt(PORTAL.ethLockbox().balance, 100_000 ether);
    }
}
