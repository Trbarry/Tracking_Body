// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./Lane09Migrate.t.sol";

interface IASRx {
    function isGameRegistered(address) external view returns (bool);
    function isGameRetired(address) external view returns (bool);
    function isGameClaimValid(address) external view returns (bool);
    function isGameProper(address) external view returns (bool);
}

interface IPortalChk {
    function checkWithdrawal(bytes32, address) external view;
}

/// @notice A proof recorded against a REAL, finalized, valid pre-migration game (OP Mainnet's current
///         anchor game) is accepted by the portal before migrate() and rejected after it.
contract Lane09OldProofsTest is Lane09Base {
    function setUp() public {
        vm.createSelectFork("l1");
    }

    function test_oldGameProof_dies_at_migration() public {
        address game = OP_ASR.anchorGame();
        assertTrue(IASRx(address(OP_ASR)).isGameClaimValid(game), "real anchor game valid pre-migration");

        bytes32 h = keccak256("lane09-withdrawal");
        bytes32 slot = keccak256(abi.encode(address(this), keccak256(abi.encode(h, uint256(57)))));
        (bool okc, bytes memory rc) = game.staticcall(abi.encodeWithSignature("createdAt()"));
        require(okc);
        uint256 ts = uint256(abi.decode(rc, (uint64))) + 1; // proven right after game creation
        if (block.timestamp <= ts + 7 days) vm.warp(ts + 7 days + 1);
        vm.store(address(OP_PORTAL), slot, bytes32((ts << 160) | uint256(uint160(game))));
        IPortalChk(address(OP_PORTAL)).checkWithdrawal(h, address(this)); // passes pre-migration

        _migrate();

        assertFalse(IASRx(address(sharedASR)).isGameRegistered(game), "old game not in shared DGF");
        assertTrue(IASRx(address(sharedASR)).isGameRetired(game), "and retired by shared ASR retirementTimestamp");
        assertFalse(IASRx(address(sharedASR)).isGameClaimValid(game));
        vm.expectRevert(bytes4(keccak256("OptimismPortal_InvalidRootClaim()")));
        IPortalChk(address(OP_PORTAL)).checkWithdrawal(h, address(this));
        // the old ASR still considers it valid (it keeps serving the legacy games only)
        assertTrue(IASRx(address(OP_ASR)).isGameClaimValid(game));
    }
}
