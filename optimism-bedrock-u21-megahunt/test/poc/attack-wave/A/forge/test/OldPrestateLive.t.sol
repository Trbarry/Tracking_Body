// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";

interface IGame {
    function absolutePrestate() external view returns (bytes32);
    function status() external view returns (uint8);
    function claimDataLen() external view returns (uint256);
    function maxClockDuration() external view returns (uint64);
    function getChallengerDuration(uint256) external view returns (uint64);
    function wasRespectedGameTypeWhenCreated() external view returns (bool);
    function gameType() external view returns (uint32);
    function claimData(uint256) external view returns (uint32, address, address, uint128, bytes32, uint128, uint128);
    function getRequiredBond(uint128) external view returns (uint256);
    function move(bytes32 disputed, uint256 parentIndex, bytes32 claim, bool isAttack) external payable;
}

interface IDGF {
    function gameAtIndex(uint256) external view returns (uint32, uint64, address);
}

interface IASR {
    function isGameProper(address) external view returns (bool);
    function isGameRespected(address) external view returns (bool);
}

/// ATK-A: production facts that bound the old-prestate lane, on a fork of L1 block 26435056.
/// The old (kona-client v1.7.0) program still adjudicates IN_PROGRESS games after U21, and an
/// unprivileged EOA can still open a dispute in one of them. Whether that dispute can be won by
/// the wrong side depends only on the old program's soundness; see rejected/ATTACK-A-01..05.
contract OldPrestateLiveTest is Test {
    bytes32 constant OLD = 0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df;
    bytes32 constant NEW = 0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9;
    uint256 constant PIN = 26435056;

    IDGF constant OP_DGF = IDGF(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);
    IASR constant OP_ASR = IASR(0x23B2C62946350F4246f9f9D027e071f0264FD113);
    IDGF constant INK_DGF = IDGF(0x10d7B35078d3baabB96Dd45a9143B94be65b12CD);
    IASR constant INK_ASR = IASR(0xEe018bAf058227872540AC60eFbd38b023d9dAe2);
    IDGF constant UNI_DGF = IDGF(0x2F12d621a16e2d3285929C9996f478508951dFe4);
    IASR constant UNI_ASR = IASR(0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9);

    function setUp() public {
        vm.createSelectFork("l1archive", PIN);
    }

    function _checkOld(IDGF dgf, IASR asr, uint256 idx) internal view returns (IGame g) {
        (uint32 gt,, address proxy) = dgf.gameAtIndex(idx);
        g = IGame(proxy);
        assertEq(gt, 9, "type 9");
        assertEq(g.absolutePrestate(), OLD, "old kona-client v1.7.0 prestate");
        assertEq(g.status(), 0, "IN_PROGRESS");
        assertTrue(g.wasRespectedGameTypeWhenCreated(), "respected at creation");
        assertTrue(asr.isGameProper(proxy), "proper");
        assertTrue(asr.isGameRespected(proxy), "respected");
    }

    /// Newest pre-U21 games on each chain still run the old program (census: 70/7/71 IN_PROGRESS).
    function test_oldPrestateGamesStillLiveAndRespected() public view {
        _checkOld(OP_DGF, OP_ASR, 21377);
        _checkOld(INK_DGF, INK_ASR, 2638);
        _checkOld(UNI_DGF, UNI_ASR, 17586);
        (,, address newer) = OP_DGF.gameAtIndex(21378);
        assertEq(IGame(newer).absolutePrestate(), NEW, "first post-U21 game uses v1.9.0");
    }

    /// An unprivileged EOA can still attack the root of an unchallenged old-prestate game.
    function test_unprivilegedAttackMoveOnOldGame() public {
        (,, address proxy) = OP_DGF.gameAtIndex(21377);
        IGame g = IGame(proxy);
        assertEq(g.claimDataLen(), 1, "unchallenged");
        (,,,, bytes32 root, uint128 pos,) = g.claimData(0);
        uint256 bond = g.getRequiredBond(pos * 2);
        address attacker = makeAddr("attacker");
        vm.deal(attacker, bond);
        vm.prank(attacker, attacker);
        g.move{value: bond}(root, 0, keccak256("dishonest"), true);
        assertEq(g.claimDataLen(), 2, "attack accepted on old-prestate game");
        assertEq(g.absolutePrestate(), OLD, "leaf steps will run the old program");
    }
}
