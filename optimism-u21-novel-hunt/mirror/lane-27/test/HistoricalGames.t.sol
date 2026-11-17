// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

interface IFactoryHistorical27 {
    function gameAtIndex(uint256 index) external view returns (uint32 gameType, uint64 timestamp, address proxy);
    function gameImpls(uint32 gameType) external view returns (address);
}

interface IGameHistorical27 {
    function status() external view returns (uint8);
    function resolvedAt() external view returns (uint64);
    function wasRespectedGameTypeWhenCreated() external view returns (bool);
    function rootClaim() external pure returns (bytes32);
    function l2SequenceNumber() external pure returns (uint256);
}

interface IASRHistorical27 {
    function retirementTimestamp() external view returns (uint64);
    function disputeGameBlacklist(address game) external view returns (bool);
    function isGameClaimValid(address game) external view returns (bool);
}

contract HistoricalGamesTest is Test {
    IFactoryHistorical27 internal constant FACTORY =
        IFactoryHistorical27(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);
    IASRHistorical27 internal constant ASR =
        IASRHistorical27(0x23B2C62946350F4246f9f9D027e071f0264FD113);

    // Binary search over factory metadata found this to be the first game created strictly
    // after the current retirement timestamp.
    uint256 internal constant FIRST_NOT_RETIRED_INDEX = 9_828;
    address internal constant EXPECTED_GAME = 0x5812F56173A63B83664077c5210b55D6195411bd;

    function setUp() external {
        vm.createSelectFork("l1n");
    }

    function test_oldUnsetTypeCanRemainClaimValid() external view {
        (uint32 gameType, uint64 createdAt, address proxy) = FACTORY.gameAtIndex(FIRST_NOT_RETIRED_INDEX);
        IGameHistorical27 game = IGameHistorical27(proxy);

        assertEq(gameType, 0);
        assertEq(proxy, EXPECTED_GAME);
        assertGt(createdAt, ASR.retirementTimestamp());
        assertEq(FACTORY.gameImpls(0), address(0), "new type-0 games are disabled");
        assertEq(game.status(), 2, "DEFENDER_WINS");
        assertTrue(game.wasRespectedGameTypeWhenCreated());
        assertFalse(ASR.disputeGameBlacklist(proxy));
        assertTrue(ASR.isGameClaimValid(proxy), "implementation removal/current type change does not retire old game");
        assertEq(game.l2SequenceNumber(), 138_890_875);
        assertEq(game.rootClaim(), 0xe8ac8315972844981318ce2417cb99da047d0eb9380c61a1d4f67e63bdf6458a);
        assertEq(game.resolvedAt(), 1_753_684_115);
    }

    function test_historicalRootMatchesCanonicalL2Header() external pure {
        bytes32 outputRoot = keccak256(
            abi.encode(
                bytes32(0),
                bytes32(0x5918ce5bd983cf828cb3b15679e5acd763d99cf034b7259f2b324776eca4ec27),
                bytes32(0x2df798742063cfd20a555ac6642bd90b9912b6426390d999cf966aaa3bb0a3c4),
                bytes32(0xbb4b107a43c4bc1ed376293dfb3c990cd3448a5f44ab2e6539d385e986bd9a0f)
            )
        );
        assertEq(outputRoot, 0xe8ac8315972844981318ce2417cb99da047d0eb9380c61a1d4f67e63bdf6458a);
    }

    function test_latestType0AndType8GamesAreValidAndCanonical() external view {
        IGameHistorical27 latestType0 =
            IGameHistorical27(0x066bC6056168a61Cd62800e3895A9A096B16D558);
        assertEq(latestType0.status(), 2);
        assertTrue(latestType0.wasRespectedGameTypeWhenCreated());
        assertTrue(ASR.isGameClaimValid(address(latestType0)));
        assertEq(latestType0.l2SequenceNumber(), 153_413_384);
        assertEq(
            latestType0.rootClaim(),
            _outputRoot(
                0x809ea4a17aa5f53f77003eddebcb1a64815f9a7c7848d185f8dfc3b430893cc7,
                0x0b3a25db88900bfd469d73226697431723575bb315b9c354716899a4c82a99c5,
                0x068359f39cc51c7934105fd5772552fca4675b345175a525ad3e46efb48be519
            )
        );

        IGameHistorical27 latestType8 =
            IGameHistorical27(0x908554DC63b03b16bc0f34dAD3dfeDb6afc1aE86);
        assertEq(latestType8.status(), 2);
        assertTrue(latestType8.wasRespectedGameTypeWhenCreated());
        assertTrue(ASR.isGameClaimValid(address(latestType8)));
        assertEq(latestType8.l2SequenceNumber(), 157_333_888);
        assertEq(
            latestType8.rootClaim(),
            _outputRoot(
                0xcaa2728ecc31c128b35431546cc518bb32ac8d94bac3e7bfce461f745a5b22c4,
                0xb5aea82aee59edd5adfcd972a220e4e931fc6c0e3a86bf928b5c4eb2c92bd971,
                0x2d979f58d5de064fc7a204d02bb8ca05ff52ac2119ff823e8f3f3c58b53d7c16
            )
        );
    }

    function _outputRoot(bytes32 stateRoot, bytes32 messagePasserStorageRoot, bytes32 blockHash)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(bytes32(0), stateRoot, messagePasserStorageRoot, blockHash));
    }
}
