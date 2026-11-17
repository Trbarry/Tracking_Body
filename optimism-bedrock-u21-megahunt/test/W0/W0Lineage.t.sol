// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import "forge-std/Test.sol";

interface IASR {
    function isGameRegistered(address) external view returns (bool);
    function isGameRetired(address) external view returns (bool);
    function isGameProper(address) external view returns (bool);
    function isGameClaimValid(address) external view returns (bool);
    function setAnchorState(address) external;
    function anchorGame() external view returns (address);
    function getAnchorRoot() external view returns (bytes32, uint256);
    function respectedGameType() external view returns (uint32);
    function retirementTimestamp() external view returns (uint64);
    function version() external view returns (string memory);
    function disputeGameFactory() external view returns (address);
}
interface IGame {
    function anchorStateRegistry() external view returns (address);
    function version() external view returns (string memory);
    function createdAt() external view returns (uint64);
    function status() external view returns (uint8);
    function l2BlockNumber() external view returns (uint256);
}
interface IDGF { function gameAtIndex(uint256) external view returns (uint32, uint64, address); }

/// W0 lineage facts on deployed OP Mainnet bytecode (fork "l1" = L1 block 26433900). No privileged prank.
contract W0LineageTest is Test {
    IASR constant CUR = IASR(0x23B2C62946350F4246f9f9D027e071f0264FD113);   // registry created at U16
    IASR constant OLD = IASR(0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b);   // registry created at U13 (2.2.2)
    IDGF constant DGF = IDGF(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);

    function setUp() public { vm.createSelectFork("l1"); }

    /// PRIM-W0-01: since v7.0.0 the current registry reports a game bound to ANOTHER registry as registered;
    /// only retirementTimestamp keeps it out.
    function test_W0_01_currentRegistryRegistersGameOfOldRegistry() public view {
        (, uint64 ts, address g) = DGF.gameAtIndex(9827);
        assertEq(IGame(g).anchorStateRegistry(), address(OLD), "game 9827 is bound to the old registry");
        assertTrue(CUR.isGameRegistered(g), "current registry: registered (no registry-binding check)");
        assertTrue(CUR.isGameRetired(g), "only the retirement timestamp rejects it");
        assertLe(ts, CUR.retirementTimestamp());
        assertFalse(CUR.isGameProper(g));
        (,, address g2) = DGF.gameAtIndex(9828);
        assertEq(IGame(g2).anchorStateRegistry(), address(CUR), "first game after U16 is bound to the current registry");
    }

    /// PRIM-W0-02: the superseded registry mirrors the live respected type and accepts CURRENT games as its anchor
    /// from any caller.
    function test_W0_02_oldRegistryAnchorMovableWithCurrentGame() public {
        assertEq(OLD.respectedGameType(), CUR.respectedGameType(), "old registry returns the live respected type");
        assertEq(OLD.disputeGameFactory(), address(DGF));
        (,, address g8) = DGF.gameAtIndex(20094); // type 8, FDG 2.4.2, bound to the current registry
        assertEq(IGame(g8).anchorStateRegistry(), address(CUR));
        assertTrue(OLD.isGameClaimValid(g8), "old registry: current game is claim-valid");
        address before = OLD.anchorGame();
        (, uint256 seqBefore) = OLD.getAnchorRoot();
        vm.prank(address(0xBEEF));
        OLD.setAnchorState(g8);
        assertEq(OLD.anchorGame(), g8, "anchor of the superseded registry moved by an arbitrary caller");
        (, uint256 seqAfter) = OLD.getAnchorRoot();
        assertGt(seqAfter, seqBefore);
        emit log_named_address("old anchorGame before", before);
        emit log_named_uint("old anchor l2BlockNumber before", seqBefore);
        emit log_named_uint("old anchor l2BlockNumber after", seqAfter);
        // current registry untouched
        assertTrue(CUR.anchorGame() != g8);
    }
}
