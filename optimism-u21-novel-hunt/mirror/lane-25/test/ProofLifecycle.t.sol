// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";

interface IPortal25 {
    function version() external view returns (string memory);
    function paused() external view returns (bool);
    function provenWithdrawals(bytes32, address) external view returns (address disputeGameProxy, uint64 timestamp);
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function proofSubmitters(bytes32, uint256) external view returns (address);
    function numProofSubmitters(bytes32) external view returns (uint256);
    function checkWithdrawal(bytes32, address) external view;
    function deleteProvenWithdrawal(bytes32, address) external;
}

interface IAnchorStateRegistry25 {
    function isGameRegistered(address) external view returns (bool);
    function isGameRespected(address) external view returns (bool);
    function isGameRetired(address) external view returns (bool);
    function isGameBlacklisted(address) external view returns (bool);
    function isGameClaimValid(address) external view returns (bool);
    function blacklistDisputeGame(address) external;
    function updateRetirementTimestamp() external;
}

interface IGame25 {
    function status() external view returns (uint8);
    function createdAt() external view returns (uint64);
    function resolvedAt() external view returns (uint64);
    function wasRespectedGameTypeWhenCreated() external view returns (bool);
}

interface ISuperchainConfig25 {
    function pause(address) external;
}

contract UnregisteredGame25 {
    uint8 public status;
    uint64 public immutable createdAt;
    bool public immutable wasRespectedGameTypeWhenCreated;

    constructor(uint8 _status, bool _respected) {
        status = _status;
        createdAt = uint64(block.timestamp - 100);
        wasRespectedGameTypeWhenCreated = _respected;
    }

    function setStatus(uint8 _status) external {
        status = _status;
    }

    function gameData() external pure returns (uint32 gameType, bytes32 rootClaim, bytes memory extraData) {
        return (9, bytes32(uint256(0x2525)), hex"2525");
    }
}

contract EmptyFactory25 {
    function games(uint32, bytes32, bytes calldata) external pure returns (address game, uint64 createdAt) {
        return (address(0), 0);
    }
}

contract ProofLifecycleTest is Test {
    IPortal25 internal constant PORTAL = IPortal25(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    IAnchorStateRegistry25 internal constant ASR = IAnchorStateRegistry25(0x23B2C62946350F4246f9f9D027e071f0264FD113);
    ISuperchainConfig25 internal constant SUPERCHAIN = ISuperchainConfig25(0x95703e0982140D16f8ebA6d158FccEde42f04a4C);

    address internal constant LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    address internal constant GUARDIAN = 0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2;

    // Proven before U21 and still IN_PROGRESS at N.
    bytes32 internal constant PRE_N_HASH = 0x8df3d52a499b3881a91e2a38a6eb46d136d7b47d5abb52685965acc39b1df241;
    address internal constant PRE_N_SUBMITTER = 0x6A9C2449c32779F89d0CcAfd746152e237c1BDf2;
    address internal constant PRE_N_GAME = 0xbEc6373FA5B74517350D9CB358a5e7D9F3DaB356;
    uint64 internal constant PRE_N_TIMESTAMP = 1_794_853_991;

    // Proven before U21 and finalized under v6.1.0 at block 0x1935326.
    bytes32 internal constant CROSS_VERSION_HASH = 0x6d7c43da9a7a7c3ce288cf3c41cbc55644ac6c5128696d4e8ecbaf1243e74af4;
    address internal constant CROSS_VERSION_SUBMITTER = 0xBF84721Cc6A0D4895d0f186498C7382c489878E3;
    address internal constant CROSS_VERSION_GAME = 0xFd0C8dD55d270916fb1097C27D217A06162537D6;
    uint64 internal constant CROSS_VERSION_TIMESTAMP = 1_794_231_107;
    uint64 internal constant U21_TIMESTAMP = 1_794_871_439;

    bytes4 internal constant NOT_INVALIDATED = bytes4(keccak256("OptimismPortal_DisputeGameNotInvalidated()"));
    bytes4 internal constant UNPROVEN = bytes4(keccak256("OptimismPortal_Unproven()"));
    bytes4 internal constant INVALID_ROOT = bytes4(keccak256("OptimismPortal_InvalidRootClaim()"));

    function test_exactNPreservesV8ProofAndInProgressCannotBeDeleted() external {
        vm.createSelectFork("l1pre");
        (address preGame, uint64 preTimestamp) = PORTAL.provenWithdrawals(PRE_N_HASH, PRE_N_SUBMITTER);
        assertEq(preGame, PRE_N_GAME);
        assertEq(preTimestamp, PRE_N_TIMESTAMP);

        // v8 has no delete selector.
        (bool preDelete,) =
            address(PORTAL).call(abi.encodeCall(IPortal25.deleteProvenWithdrawal, (PRE_N_HASH, PRE_N_SUBMITTER)));
        assertFalse(preDelete);

        vm.createSelectFork("l1n");
        assertEq(PORTAL.version(), "6.1.0");
        (address postGame, uint64 postTimestamp) = PORTAL.provenWithdrawals(PRE_N_HASH, PRE_N_SUBMITTER);
        assertEq(postGame, preGame);
        assertEq(postTimestamp, preTimestamp);
        assertEq(IGame25(PRE_N_GAME).status(), 0);

        vm.expectRevert(NOT_INVALIDATED);
        PORTAL.deleteProvenWithdrawal(PRE_N_HASH, PRE_N_SUBMITTER);
        (postGame, postTimestamp) = PORTAL.provenWithdrawals(PRE_N_HASH, PRE_N_SUBMITTER);
        assertEq(postGame, PRE_N_GAME);
        assertEq(postTimestamp, PRE_N_TIMESTAMP);
    }

    function test_challengerWinsDeletionIsPermissionlessAndLeavesArrayStale() external {
        vm.createSelectFork("l1n");
        assertEq(PORTAL.numProofSubmitters(PRE_N_HASH), 1);
        assertEq(PORTAL.proofSubmitters(PRE_N_HASH, 0), PRE_N_SUBMITTER);

        // Models the production-reachable terminal result of the real registered game.
        _setGameResolution(PRE_N_GAME, 1, uint64(block.timestamp));
        assertEq(IGame25(PRE_N_GAME).status(), 1);

        vm.prank(address(0xA11CE));
        PORTAL.deleteProvenWithdrawal(PRE_N_HASH, PRE_N_SUBMITTER);

        (address game, uint64 timestamp) = PORTAL.provenWithdrawals(PRE_N_HASH, PRE_N_SUBMITTER);
        assertEq(game, address(0));
        assertEq(timestamp, 0);
        assertEq(PORTAL.numProofSubmitters(PRE_N_HASH), 1);
        assertEq(PORTAL.proofSubmitters(PRE_N_HASH, 0), PRE_N_SUBMITTER);

        vm.expectRevert(UNPROVEN);
        PORTAL.deleteProvenWithdrawal(PRE_N_HASH, PRE_N_SUBMITTER);
    }

    function test_blacklistedProofCanBeDeletedByAnotherUserWhilePaused() external {
        vm.createSelectFork("l1n");

        // Both privileged calls only construct states the deployed Guardian can already create.
        vm.prank(GUARDIAN);
        ASR.blacklistDisputeGame(PRE_N_GAME);
        assertTrue(ASR.isGameBlacklisted(PRE_N_GAME));

        vm.prank(GUARDIAN);
        SUPERCHAIN.pause(LOCKBOX);
        assertTrue(PORTAL.paused());

        vm.prank(address(0xB0B));
        PORTAL.deleteProvenWithdrawal(PRE_N_HASH, PRE_N_SUBMITTER);
        (, uint64 timestamp) = PORTAL.provenWithdrawals(PRE_N_HASH, PRE_N_SUBMITTER);
        assertEq(timestamp, 0);
    }

    function test_defenderWinsCannotBeDeleted() external {
        vm.createSelectFork("l1n");
        // Models the other production-reachable terminal result of the real registered game.
        _setGameResolution(PRE_N_GAME, 2, uint64(block.timestamp));
        assertEq(IGame25(PRE_N_GAME).status(), 2);

        vm.expectRevert(NOT_INVALIDATED);
        PORTAL.deleteProvenWithdrawal(PRE_N_HASH, PRE_N_SUBMITTER);
    }

    function test_retirementAloneDoesNotAuthorizeDeletion() external {
        vm.createSelectFork("l1n");
        vm.prank(GUARDIAN);
        ASR.updateRetirementTimestamp();
        assertTrue(ASR.isGameRetired(PRE_N_GAME));

        vm.expectRevert(NOT_INVALIDATED);
        PORTAL.deleteProvenWithdrawal(PRE_N_HASH, PRE_N_SUBMITTER);
    }

    function test_notRespectedBoundaryCannotDeleteWithoutPermanentInvalidation() external {
        vm.createSelectFork("l1n");
        assertTrue(IGame25(PRE_N_GAME).wasRespectedGameTypeWhenCreated());

        // Synthetic boundary only: this creation-time bit is immutable in production.
        bytes32 raw = vm.load(PRE_N_GAME, bytes32(uint256(9)));
        vm.store(PRE_N_GAME, bytes32(uint256(9)), bytes32(uint256(raw) & ~uint256(0xff)));
        assertFalse(ASR.isGameRespected(PRE_N_GAME));

        vm.expectRevert(NOT_INVALIDATED);
        PORTAL.deleteProvenWithdrawal(PRE_N_HASH, PRE_N_SUBMITTER);
    }

    function test_unregisteredSyntheticEntryOnlyDeletesIfStatusIsChallengerWins() external {
        vm.createSelectFork("l1n");
        UnregisteredGame25 game = new UnregisteredGame25(0, true);
        assertFalse(ASR.isGameRegistered(address(game)));

        bytes32 withdrawalHash = keccak256("lane25-unregistered");
        address submitter = address(0x2525);
        _writeProof(withdrawalHash, submitter, address(game), uint64(block.timestamp - 1));

        vm.expectRevert(NOT_INVALIDATED);
        PORTAL.deleteProvenWithdrawal(withdrawalHash, submitter);

        game.setStatus(1);
        PORTAL.deleteProvenWithdrawal(withdrawalHash, submitter);
        (, uint64 timestamp) = PORTAL.provenWithdrawals(withdrawalHash, submitter);
        assertEq(timestamp, 0);
    }

    function test_noCodeStoredGameRevertsEvenIfBlacklisted() external {
        vm.createSelectFork("l1n");
        address noCode = address(0xBEEF);
        bytes32 withdrawalHash = keccak256("lane25-no-code");
        address submitter = address(0x2526);
        _writeProof(withdrawalHash, submitter, noCode, uint64(block.timestamp - 1));

        vm.prank(GUARDIAN);
        ASR.blacklistDisputeGame(noCode);
        assertTrue(ASR.isGameBlacklisted(noCode));

        (bool ok,) = address(PORTAL).call(abi.encodeCall(IPortal25.deleteProvenWithdrawal, (withdrawalHash, submitter)));
        assertFalse(ok);
        (address storedGame, uint64 timestamp) = PORTAL.provenWithdrawals(withdrawalHash, submitter);
        assertEq(storedGame, noCode);
        assertGt(timestamp, 0);
    }

    function test_crossVersionProofFinalizedUnderV9() external {
        vm.createSelectFork("l1n");
        assertEq(PORTAL.version(), "6.1.0");
        (address gameAtN, uint64 timestampAtN) = PORTAL.provenWithdrawals(CROSS_VERSION_HASH, CROSS_VERSION_SUBMITTER);
        assertEq(gameAtN, CROSS_VERSION_GAME);
        assertEq(timestampAtN, CROSS_VERSION_TIMESTAMP);
        assertLt(timestampAtN, U21_TIMESTAMP);
        assertFalse(PORTAL.finalizedWithdrawals(CROSS_VERSION_HASH));

        vm.createSelectFork("l1");
        (address gameLater, uint64 timestampLater) =
            PORTAL.provenWithdrawals(CROSS_VERSION_HASH, CROSS_VERSION_SUBMITTER);
        assertEq(gameLater, gameAtN);
        assertEq(timestampLater, timestampAtN);
        assertTrue(PORTAL.finalizedWithdrawals(CROSS_VERSION_HASH));
    }

    function test_deletingAlreadyFinalizedProofDoesNotClearReplayProtection() external {
        vm.createSelectFork("l1");
        assertTrue(PORTAL.finalizedWithdrawals(CROSS_VERSION_HASH));
        uint256 submitterCount = PORTAL.numProofSubmitters(CROSS_VERSION_HASH);
        assertGt(submitterCount, 0);

        // The real blacklist path is covered above; direct storage avoids depending on an
        // uncached historical mapping slot for this separate post-finalization assertion.
        _setBlacklisted(CROSS_VERSION_GAME);
        vm.prank(address(0xA11CE));
        PORTAL.deleteProvenWithdrawal(CROSS_VERSION_HASH, CROSS_VERSION_SUBMITTER);

        (, uint64 timestamp) = PORTAL.provenWithdrawals(CROSS_VERSION_HASH, CROSS_VERSION_SUBMITTER);
        assertEq(timestamp, 0);
        assertTrue(PORTAL.finalizedWithdrawals(CROSS_VERSION_HASH));
        assertEq(PORTAL.numProofSubmitters(CROSS_VERSION_HASH), submitterCount);
    }

    function test_deleteFrontRunCannotChangeAnInvalidProofIntoAValidOne() external {
        vm.createSelectFork("l1n");
        vm.warp(block.timestamp + 10 days);
        _setGameResolution(PRE_N_GAME, 1, uint64(block.timestamp - 4 days));
        assertFalse(ASR.isGameClaimValid(PRE_N_GAME));

        vm.expectRevert(INVALID_ROOT);
        PORTAL.checkWithdrawal(PRE_N_HASH, PRE_N_SUBMITTER);

        PORTAL.deleteProvenWithdrawal(PRE_N_HASH, PRE_N_SUBMITTER);
        vm.expectRevert(UNPROVEN);
        PORTAL.checkWithdrawal(PRE_N_HASH, PRE_N_SUBMITTER);
    }

    function test_badSubmitterProofDoesNotBlockGoodSubmitterProof() external {
        vm.createSelectFork("l1n");
        vm.warp(block.timestamp + 10 days);
        _setGameResolution(PRE_N_GAME, 2, uint64(block.timestamp - 4 days));
        assertTrue(ASR.isGameClaimValid(PRE_N_GAME));

        bytes32 withdrawalHash = keccak256("lane25-two-submitters");
        address badSubmitter = address(0xBAD);
        address goodSubmitter = address(0x600D);

        UnregisteredGame25 badGame = new UnregisteredGame25(1, true);
        _writeProof(withdrawalHash, badSubmitter, address(badGame), uint64(block.timestamp - 1));
        _writeProof(withdrawalHash, goodSubmitter, PRE_N_GAME, PRE_N_TIMESTAMP);
        _writeSubmitterArray(withdrawalHash, badSubmitter, goodSubmitter);

        // The array deliberately lists the bad proof first, but selection is explicit by address.
        PORTAL.checkWithdrawal(withdrawalHash, goodSubmitter);
        PORTAL.deleteProvenWithdrawal(withdrawalHash, badSubmitter);
        PORTAL.checkWithdrawal(withdrawalHash, goodSubmitter);
    }

    function test_plannedMigrationMechanismRejectsAllOldFactoryProofsButDoesNotDeleteThem() external {
        vm.createSelectFork("l1n");
        vm.warp(block.timestamp + 10 days);

        // Models the two decisive properties of the newly initialized migration ASR using the
        // deployed ASR code: a fresh (empty) factory and retirement at migration time.
        EmptyFactory25 freshFactory = new EmptyFactory25();
        vm.store(address(ASR), bytes32(uint256(1)), bytes32(uint256(uint160(address(freshFactory)))));
        vm.prank(GUARDIAN);
        ASR.updateRetirementTimestamp();

        assertFalse(ASR.isGameRegistered(PRE_N_GAME));
        assertTrue(ASR.isGameRetired(PRE_N_GAME));
        assertFalse(ASR.isGameClaimValid(PRE_N_GAME));

        vm.expectRevert(INVALID_ROOT);
        PORTAL.checkWithdrawal(PRE_N_HASH, PRE_N_SUBMITTER);
        (address game, uint64 timestamp) = PORTAL.provenWithdrawals(PRE_N_HASH, PRE_N_SUBMITTER);
        assertEq(game, PRE_N_GAME);
        assertEq(timestamp, PRE_N_TIMESTAMP);

        vm.expectRevert(NOT_INVALIDATED);
        PORTAL.deleteProvenWithdrawal(PRE_N_HASH, PRE_N_SUBMITTER);
    }

    function test_realProofPackingMatchesSlot57Layout() external {
        vm.createSelectFork("l1n");
        uint256 packed = uint256(vm.load(address(PORTAL), _proofSlot(PRE_N_HASH, PRE_N_SUBMITTER)));
        assertEq(address(uint160(packed)), PRE_N_GAME);
        assertEq(uint64(packed >> 160), PRE_N_TIMESTAMP);
    }

    function _proofSlot(bytes32 withdrawalHash, address submitter) internal pure returns (bytes32) {
        bytes32 outer = keccak256(abi.encode(withdrawalHash, uint256(57)));
        return keccak256(abi.encode(submitter, outer));
    }

    function _writeProof(bytes32 withdrawalHash, address submitter, address game, uint64 timestamp) internal {
        uint256 packed = uint256(uint160(game)) | (uint256(timestamp) << 160);
        vm.store(address(PORTAL), _proofSlot(withdrawalHash, submitter), bytes32(packed));
    }

    function _writeSubmitterArray(bytes32 withdrawalHash, address first, address second) internal {
        bytes32 lengthSlot = keccak256(abi.encode(withdrawalHash, uint256(60)));
        vm.store(address(PORTAL), lengthSlot, bytes32(uint256(2)));
        uint256 dataSlot = uint256(keccak256(abi.encode(lengthSlot)));
        vm.store(address(PORTAL), bytes32(dataSlot), bytes32(uint256(uint160(first))));
        vm.store(address(PORTAL), bytes32(dataSlot + 1), bytes32(uint256(uint160(second))));
    }

    function _setGameResolution(address game, uint8 status, uint64 resolvedAt) internal {
        uint256 raw = uint256(vm.load(game, bytes32(0)));
        raw &= ~(uint256(type(uint64).max) << 64);
        raw &= ~(uint256(0xff) << 128);
        raw |= uint256(resolvedAt) << 64;
        raw |= uint256(status) << 128;
        vm.store(game, bytes32(0), bytes32(raw));
    }

    function _setBlacklisted(address game) internal {
        bytes32 slot = keccak256(abi.encode(game, uint256(5)));
        vm.store(address(ASR), slot, bytes32(uint256(1)));
    }
}
