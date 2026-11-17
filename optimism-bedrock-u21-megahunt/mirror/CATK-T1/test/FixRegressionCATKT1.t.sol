// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./helpers/U21Fixtures.sol";

interface IDGF_T1 {
    function create(uint32 gameType, bytes32 rootClaim, bytes calldata extraData)
        external
        payable
        returns (address proxy);
    function gameCount() external view returns (uint256);
    function gameAtIndex(uint256 index) external view returns (uint32 gameType, uint64 timestamp, address proxy);
    function gameImpls(uint32 gameType) external view returns (address);
    function gameArgs(uint32 gameType) external view returns (bytes memory);
    function initBonds(uint32 gameType) external view returns (uint256);
    function setImplementation(uint32 gameType, address implementation) external;
}

interface IPortal_T1 {
    function initialize(address systemConfig, address anchorStateRegistry, address ethLockbox) external;
    function ethLockbox() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function systemConfig() external view returns (address);
    function paused() external view returns (bool);
    function l2Sender() external view returns (address);
    function params() external view returns (uint128 prevBaseFee, uint64 prevBoughtGas, uint64 prevBlockNum);
    function depositTransaction(address to, uint256 value, uint64 gasLimit, bool isCreation, bytes calldata data)
        external
        payable;
}

interface IASR_T1 {
    function anchorGame() external view returns (address);
    function getAnchorRoot() external view returns (bytes32 root, uint256 l2SequenceNumber);
    function disputeGameFactory() external view returns (address);
    function respectedGameType() external view returns (uint32);
    function retirementTimestamp() external view returns (uint64);
    function blacklistDisputeGame(address game) external;
    function setRespectedGameType(uint32 gameType) external;
    function updateRetirementTimestamp() external;
    function setAnchorState(address game) external;
    function isGameRegistered(address game) external view returns (bool);
    function isGameProper(address game) external view returns (bool);
    function isGameClaimValid(address game) external view returns (bool);
    function isGameBlacklisted(address game) external view returns (bool);
    function paused() external view returns (bool);
    function disputeGameFinalityDelaySeconds() external view returns (uint256);
}

interface IGame_T1 {
    function anchorStateRegistry() external pure returns (address);
    function absolutePrestate() external pure returns (bytes32);
    function rootClaim() external pure returns (bytes32);
    function l2SequenceNumber() external pure returns (uint256);
    function getRequiredBond(uint128 position) external view returns (uint256);
    function attack(bytes32 disputed, uint256 parentIndex, bytes32 claim) external payable;
    function closeGame() external;
    function bondDistributionMode() external view returns (uint8);
    function claimDataLen() external view returns (uint256);
}

interface ISystemConfig_T1 {
    function l2ChainId() external view returns (uint256);
    function optimismPortal() external view returns (address);
    function isFeatureEnabled(bytes32 feature) external view returns (bool);
    function setFeature(bytes32 feature, bool enabled) external;
}

struct ResourceConfig_T1 {
    uint32 maxResourceLimit;
    uint8 elasticityMultiplier;
    uint8 baseFeeMaxChangeDenominator;
    uint32 minimumBaseFee;
    uint32 systemTxMaxGas;
    uint128 maximumBaseFee;
}

struct SystemAddresses_T1 {
    address l1CrossDomainMessenger;
    address l1ERC721Bridge;
    address l1StandardBridge;
    address optimismPortal;
    address optimismMintableERC20Factory;
    address delayedWETH;
    address opcm;
}

interface ISystemConfigInit_T1 {
    function initialize(
        address owner,
        uint32 basefeeScalar,
        uint32 blobbasefeeScalar,
        bytes32 batcherHash,
        uint64 gasLimit,
        address unsafeBlockSigner,
        ResourceConfig_T1 calldata config,
        SystemAddresses_T1 calldata addresses_,
        uint256 l2ChainId,
        address superchainConfig
    ) external;
}

interface IMessengerInit_T1 {
    function initialize(address systemConfig, address portal) external;
    function version() external view returns (string memory);
}

interface IDelayedWETH_T1 {
    function deposit() external payable;
    function balanceOf(address owner) external view returns (uint256);
    function delay() external view returns (uint256);
    function unlock(address subAccount, uint256 amount) external;
    function withdraw(address subAccount, uint256 amount) external;
    function recover(uint256 amount) external;
    function hold(address owner, uint256 amount) external;
}

contract Type5OriginWrapper_T1 {
    function create(address factory, uint32 gameType, bytes32 rootClaim, bytes calldata extraData)
        external
        payable
        returns (address)
    {
        return IDGF_T1(factory).create{ value: msg.value }(gameType, rootClaim, extraData);
    }
}

/// @notice Independent CATK-T1 regression mutations against the proxies deployed at L1 block 26,433,900.
///         Every state-changing call starts from an unprivileged address and executes only in the local fork.
contract FixRegressionCATKT1 is U21FixtureBase {
    struct ChainCfg {
        string name;
        uint256 l2ChainId;
        address systemConfig;
        address portal;
        address lockbox;
        address asr;
        address dgf;
        address messenger;
        uint32 respectedType;
    }

    address internal constant ATTACKER = address(0xA11CE);
    bytes32 internal constant ETH_LOCKBOX_FEATURE = bytes32("ETH_LOCKBOX");
    bytes32 internal constant OLD_KONA_PRESTATE =
        0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df;

    function setUp() public {
        vm.createSelectFork("l1");
        vm.deal(ATTACKER, 1_000 ether);
        assertEq(block.number, 26_433_900);
    }

    function _chain(uint256 i) internal pure returns (ChainCfg memory c) {
        if (i == 0) {
            return ChainCfg({
                name: "OP",
                l2ChainId: 10,
                systemConfig: 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290,
                portal: 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed,
                lockbox: 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43,
                asr: 0x23B2C62946350F4246f9f9D027e071f0264FD113,
                dgf: 0xe5965Ab5962eDc7477C8520243A95517CD252fA9,
                messenger: 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1,
                respectedType: 9
            });
        }
        if (i == 1) {
            return ChainCfg({
                name: "Ink",
                l2ChainId: 57_073,
                systemConfig: 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364,
                portal: 0x5d66C1782664115999C47c9fA5cd031f495D3e4F,
                lockbox: 0xbd4AbB321138e8Eddc399cE64E66451294325a14,
                asr: 0xEe018bAf058227872540AC60eFbd38b023d9dAe2,
                dgf: 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD,
                messenger: 0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f,
                respectedType: 9
            });
        }
        if (i == 2) {
            return ChainCfg({
                name: "Soneium",
                l2ChainId: 1_868,
                systemConfig: 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3,
                portal: 0x88e529A6ccd302c948689Cd5156C83D4614FAE92,
                lockbox: 0x67B4de6FfA66EF201Ea6099A89cA397D56622E31,
                asr: 0x4890928941e62e273dA359374b105F803329F473,
                dgf: 0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0,
                messenger: 0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f,
                respectedType: 5
            });
        }
        return ChainCfg({
            name: "Unichain",
            l2ChainId: 130,
            systemConfig: 0xc407398d063f942feBbcC6F80a156b47F3f1BDA6,
            portal: 0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2,
            lockbox: 0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5,
            asr: 0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9,
            dgf: 0x2F12d621a16e2d3285929C9996f478508951dFe4,
            messenger: 0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6,
            respectedType: 9
        });
    }

    function _superRoot(uint256 chainId, uint64 sequence, bytes32 outputRoot)
        internal
        pure
        returns (bytes32 rootClaim, bytes memory extraData)
    {
        extraData = abi.encodePacked(bytes1(0x01), bytes8(sequence), bytes32(chainId), outputRoot);
        rootClaim = keccak256(extraData);
    }

    function _createType9(ChainCfg memory c, uint64 sequence, bytes32 salt) internal returns (address game) {
        (bytes32 root, bytes memory extra) = _superRoot(c.l2ChainId, sequence, keccak256(abi.encode(c.name, salt)));
        uint256 bond = IDGF_T1(c.dgf).initBonds(9);
        vm.prank(ATTACKER, ATTACKER);
        game = IDGF_T1(c.dgf).create{ value: bond }(9, root, extra);
    }

    function _callAsAttacker(address target, bytes memory data) internal returns (bool ok, bytes memory ret) {
        vm.prank(ATTACKER, ATTACKER);
        (ok, ret) = target.call(data);
    }

    /// T01 / row 1: a post-retirement game must be a clone whose immutable ASR is the current ASR.
    function test_T01_registryBinding_postUpgradeCreateCannotNameSiblingRegistry() public {
        for (uint256 i; i < 4; i++) {
            ChainCfg memory c = _chain(i);
            IASR_T1 asr = IASR_T1(c.asr);
            assertEq(asr.disputeGameFactory(), c.dgf, c.name);
            assertEq(asr.respectedGameType(), c.respectedType, c.name);

            uint256 n = IDGF_T1(c.dgf).gameCount();
            (, uint64 createdAt, address latest) = IDGF_T1(c.dgf).gameAtIndex(n - 1);
            assertGt(createdAt, asr.retirementTimestamp(), c.name);
            assertEq(IGame_T1(latest).anchorStateRegistry(), c.asr, c.name);
            assertTrue(asr.isGameRegistered(latest), c.name);

            if (c.respectedType == 9) {
                (, uint256 anchorSeq) = asr.getAnchorRoot();
                address game = _createType9(c, uint64(anchorSeq + 1), bytes32(i + 1));
                assertEq(IGame_T1(game).anchorStateRegistry(), c.asr, c.name);
                assertTrue(asr.isGameRegistered(game), c.name);
                assertFalse(asr.isGameClaimValid(game), c.name);
            } else {
                (, uint256 anchorSeq) = asr.getAnchorRoot();
                (bytes32 root, bytes memory extra) =
                    _superRoot(c.l2ChainId, uint64(anchorSeq + 1), keccak256("CATK-T1-Soneium"));
                (bool ok,) = _callAsAttacker(
                    c.dgf, abi.encodeCall(IDGF_T1.create, (uint32(5), root, extra))
                );
                assertFalse(ok, "Soneium type-5 create must reject non-proposer origin");
            }
        }
    }

    /// T02 / row 2: keeping a bad anchor is known behavior, but no unprivileged call can create
    /// the blacklist, retirement, or de-respecting transition on which the mutation depends.
    function test_T02_anchorInvalidationTransitionsAreGuardianOnly() public {
        for (uint256 i; i < 4; i++) {
            ChainCfg memory c = _chain(i);
            IASR_T1 asr = IASR_T1(c.asr);
            address beforeAnchor = asr.anchorGame();
            uint64 beforeRetirement = asr.retirementTimestamp();
            uint32 beforeType = asr.respectedGameType();

            (bool blacklistOk,) =
                _callAsAttacker(c.asr, abi.encodeCall(IASR_T1.blacklistDisputeGame, (beforeAnchor)));
            (bool retireOk,) = _callAsAttacker(c.asr, abi.encodeCall(IASR_T1.updateRetirementTimestamp, ()));
            (bool typeOk,) =
                _callAsAttacker(c.asr, abi.encodeCall(IASR_T1.setRespectedGameType, (uint32(beforeType + 1))));

            assertFalse(blacklistOk, c.name);
            assertFalse(retireOk, c.name);
            assertFalse(typeOk, c.name);
            assertEq(asr.anchorGame(), beforeAnchor, c.name);
            assertEq(asr.retirementTimestamp(), beforeRetirement, c.name);
            assertEq(asr.respectedGameType(), beforeType, c.name);
            assertFalse(asr.isGameBlacklisted(beforeAnchor), c.name);
        }
    }

    /// T03 / row 3: re-proving after finalization is reachable, but the economic effect is killed
    /// by the hash-global finalizedWithdrawals bit.
    function test_T03_reproveAfterFinalizationCannotExecuteTwice() public {
        Fixture memory f = _loadFixture(1);
        assertTrue(_makeFinalizable(f));
        _finalizeAs(f, ATTACKER);
        assertTrue(PORTAL.finalizedWithdrawals(f.hash));

        address reprover = address(0xBEEF);
        (bool reproved, bytes memory ret) = _reproveAs(f, reprover);
        assertTrue(reproved, string(ret));
        (, uint64 ts) = PORTAL.provenWithdrawals(f.hash, reprover);
        assertGt(ts, 0);

        vm.expectRevert();
        vm.prank(address(0xCA11), address(0xCA11));
        PORTAL.finalizeWithdrawalTransactionExternalProof(f.wd, reprover);
    }

    /// T04 / row 4: an old nonce-version-0 first relay either leaves a replayable mapping or the
    /// whole portal call reverts. It never finalizes with neither messenger mapping.
    function test_T04_versionZeroFirstRelayHasNoFinalizedUnknownOutcome() public {
        Fixture memory f = _loadFixture(1);
        assertLt(f.wd.nonce, 1 << 240, "fixture must be nonce version zero");
        assertTrue(_makeFinalizable(f));
        bytes32 msgHash = messageHash(f.wd);

        uint256[7] memory gasSamples = [uint256(600_000), 800_000, 1_000_000, 1_300_000, 1_700_000, 2_200_000, 3_000_000];
        bool sawRevert;
        bool sawFinalized;
        for (uint256 i; i < gasSamples.length; i++) {
            uint256 snap = vm.snapshotState();
            (bool ok,) = _finalizeWithGas(f, gasSamples[i]);
            bool finalized = PORTAL.finalizedWithdrawals(f.hash);
            bool success = L1CDM.successfulMessages(msgHash);
            bool failed = L1CDM.failedMessages(msgHash);
            if (ok) {
                sawFinalized = true;
                assertTrue(finalized);
                assertTrue(success || failed, "finalized messenger withdrawal must write an outcome");
            } else {
                sawRevert = true;
                assertFalse(finalized);
                assertFalse(success);
                assertFalse(failed);
            }
            assertTrue(vm.revertToState(snap));
        }
        assertTrue(sawRevert, "must exercise atomic low-gas revert");
        assertTrue(sawFinalized, "must exercise a completed first relay");
    }

    /// T05 / row 6: pointer writers and the lockbox feature are not permissionless.
    function test_T05_pausePointerCannotBeMutatedByAttacker() public {
        for (uint256 i; i < 4; i++) {
            ChainCfg memory c = _chain(i);
            IPortal_T1 portal = IPortal_T1(c.portal);
            ISystemConfig_T1 sys = ISystemConfig_T1(c.systemConfig);
            assertEq(portal.ethLockbox(), c.lockbox, c.name);
            assertEq(portal.anchorStateRegistry(), c.asr, c.name);
            assertEq(portal.systemConfig(), c.systemConfig, c.name);
            assertEq(portal.paused(), ILockbox(c.lockbox).paused(), c.name);
            assertTrue(sys.isFeatureEnabled(ETH_LOCKBOX_FEATURE), c.name);

            (bool initOk,) = _callAsAttacker(
                c.portal, abi.encodeCall(IPortal_T1.initialize, (c.systemConfig, c.asr, ATTACKER))
            );
            (bool featureOk,) = _callAsAttacker(
                c.systemConfig, abi.encodeCall(ISystemConfig_T1.setFeature, (ETH_LOCKBOX_FEATURE, false))
            );
            assertFalse(initOk, c.name);
            assertFalse(featureOk, c.name);
            assertEq(portal.ethLockbox(), c.lockbox, c.name);
            assertTrue(sys.isFeatureEnabled(ETH_LOCKBOX_FEATURE), c.name);
        }
    }

    /// T06 / row 12: the missing upper bound is real for type 9, but it only becomes authoritative
    /// after the deliberately invalid game is allowed to resolve unchallenged (known fault-proof model).
    function test_T06_farFutureSuperAnchorRequiresInvalidGameToWin() public {
        for (uint256 i; i < 4; i++) {
            ChainCfg memory c = _chain(i);
            IASR_T1 asr = IASR_T1(c.asr);
            (, uint256 beforeSeq) = asr.getAnchorRoot();
            if (c.respectedType == 5) {
                (bytes32 root, bytes memory extra) =
                    _superRoot(c.l2ChainId, 2_000_000_002, keccak256("CATK-T1-type5-future"));
                (bool ok,) =
                    _callAsAttacker(c.dgf, abi.encodeCall(IDGF_T1.create, (uint32(5), root, extra)));
                assertFalse(ok, "Soneium proposer gate");
                continue;
            }

            uint64 farFuture = uint64(2_000_000_000 + i);
            assertGt(farFuture, beforeSeq);
            address game = _createType9(c, farFuture, keccak256(abi.encode("future", i)));
            assertFalse(asr.isGameClaimValid(game));
            assertEq(_resolveGameHonestly(game), 2, "uncontested game resolves for proposer");
            vm.warp(uint256(IGame(game).resolvedAt()) + asr.disputeGameFinalityDelaySeconds() + 1);
            assertTrue(asr.isGameClaimValid(game));
            vm.prank(ATTACKER, ATTACKER);
            asr.setAnchorState(game);
            assertEq(asr.anchorGame(), game);
            (, uint256 afterSeq) = asr.getAnchorRoot();
            assertEq(afterSeq, farFuture);
        }
    }

    /// T07 / row 16: sample the deployed super-game closeGame gas boundary. Every successful call
    /// must also update the anchor; otherwise the call reverts atomically.
    function test_T07_closeGameGasStarvationCannotSkipAnchorUpdate() public {
        ChainCfg memory c = _chain(0);
        IASR_T1 asr = IASR_T1(c.asr);
        (, uint256 beforeSeq) = asr.getAnchorRoot();
        address game = _createType9(c, uint64(beforeSeq + 1), keccak256("T07"));
        assertEq(_resolveGameHonestly(game), 2);
        vm.warp(uint256(IGame(game).resolvedAt()) + asr.disputeGameFinalityDelaySeconds() + 1);

        bool sawRevert;
        bool sawSuccess;
        for (uint256 gasAmount = 75_000; gasAmount <= 1_000_000; gasAmount += 25_000) {
            uint256 snap = vm.snapshotState();
            vm.prank(ATTACKER, ATTACKER);
            (bool ok,) = game.call{ gas: gasAmount }(abi.encodeCall(IGame_T1.closeGame, ()));
            if (ok) {
                sawSuccess = true;
                assertEq(asr.anchorGame(), game, "successful close must update anchor");
            } else {
                sawRevert = true;
                assertTrue(asr.anchorGame() != game, "revert must roll back anchor");
            }
            assertTrue(vm.revertToState(snap));
        }
        assertTrue(sawRevert);
        assertTrue(sawSuccess);
    }

    /// T08 / row 28: sample the two SafeCall reserve layers on a real v1 messenger withdrawal.
    /// There is no completed portal state in which both messenger outcome mappings are absent.
    function test_T08_safeCallReserveSamplesAreAtomicOrReplayable() public {
        Fixture memory f = _loadFixture(5);
        assertTrue(_makeFinalizable(f));
        bytes32 msgHash = messageHash(f.wd);
        uint256[8] memory gasSamples =
            [uint256(450_000), 600_000, 750_000, 900_000, 1_100_000, 1_400_000, 1_900_000, 2_800_000];
        bool sawCompleted;
        bool sawRevert;

        for (uint256 i; i < gasSamples.length; i++) {
            uint256 snap = vm.snapshotState();
            (bool ok,) = _finalizeWithGas(f, gasSamples[i]);
            bool finalized = PORTAL.finalizedWithdrawals(f.hash);
            bool success = L1CDM.successfulMessages(msgHash);
            bool failed = L1CDM.failedMessages(msgHash);
            if (ok) {
                sawCompleted = true;
                assertTrue(finalized);
                assertTrue(success || failed, "messenger outcome must be replayable or delivered");
            } else {
                sawRevert = true;
                assertFalse(finalized);
                assertFalse(success);
                assertFalse(failed);
            }
            assertTrue(vm.revertToState(snap));
        }
        assertTrue(sawCompleted);
        assertTrue(sawRevert);
    }

    /// T09 / row 17: the permissionless deposit entrypoint on every portal neither reads nor writes
    /// the retired portal slots 52, 58, or 59.
    function test_T09_legacyPortalSpacersAreDeadOnPermissionlessDeposit() public {
        for (uint256 i; i < 4; i++) {
            ChainCfg memory c = _chain(i);
            vm.record();
            vm.prank(ATTACKER, ATTACKER);
            IPortal_T1(c.portal).depositTransaction(ATTACKER, 0, 100_000, false, bytes(""));
            (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(c.portal);
            for (uint256 j; j < reads.length; j++) {
                assertTrue(uint256(reads[j]) != 52 && uint256(reads[j]) != 58 && uint256(reads[j]) != 59, c.name);
            }
            for (uint256 j; j < writes.length; j++) {
                assertTrue(uint256(writes[j]) != 52 && uint256(writes[j]) != 58 && uint256(writes[j]) != 59, c.name);
            }
        }
    }

    /// T10 / rows 15+5: attacker re-initialization cannot reset the messenger sentinel or portal
    /// resource parameters. The deployed proxies reject the same-version initialize calls.
    function test_T10_initializerIdempotenceCannotBeReachedPermissionlessly() public {
        for (uint256 i; i < 4; i++) {
            ChainCfg memory c = _chain(i);
            IPortal_T1 portal = IPortal_T1(c.portal);
            (uint128 feeBefore, uint64 gasBefore, uint64 blockBefore) = portal.params();
            string memory messengerVersion = IMessengerInit_T1(c.messenger).version();

            (bool portalOk,) = _callAsAttacker(
                c.portal, abi.encodeCall(IPortal_T1.initialize, (c.systemConfig, c.asr, c.lockbox))
            );
            (bool messengerOk,) = _callAsAttacker(
                c.messenger, abi.encodeCall(IMessengerInit_T1.initialize, (c.systemConfig, c.portal))
            );
            assertFalse(portalOk, c.name);
            assertFalse(messengerOk, c.name);
            (uint128 feeAfter, uint64 gasAfter, uint64 blockAfter) = portal.params();
            assertEq(feeAfter, feeBefore, c.name);
            assertEq(gasAfter, gasBefore, c.name);
            assertEq(blockAfter, blockBefore, c.name);
            assertEq(IMessengerInit_T1(c.messenger).version(), messengerVersion, c.name);
        }
    }

    /// T11 / row 13: direct and wrapped type-5 creation retain the attacker's tx.origin and fail
    /// the proposer check on every chain.
    function test_T11_type5TxOriginGateRejectsDirectAndWrappedAttacker() public {
        Type5OriginWrapper_T1 wrapper = new Type5OriginWrapper_T1();
        for (uint256 i; i < 4; i++) {
            ChainCfg memory c = _chain(i);
            assertTrue(IDGF_T1(c.dgf).gameImpls(5) != address(0), c.name);
            (, uint256 anchorSeq) = IASR_T1(c.asr).getAnchorRoot();
            (bytes32 root, bytes memory extra) =
                _superRoot(c.l2ChainId, uint64(anchorSeq + 1), keccak256(abi.encode("type5", i)));

            (bool directOk,) =
                _callAsAttacker(c.dgf, abi.encodeCall(IDGF_T1.create, (uint32(5), root, extra)));
            vm.prank(ATTACKER, ATTACKER);
            (bool wrappedOk,) = address(wrapper).call(
                abi.encodeCall(Type5OriginWrapper_T1.create, (c.dgf, uint32(5), root, extra))
            );
            assertFalse(directOk, c.name);
            assertFalse(wrappedOk, c.name);
        }
    }

    /// T12 / row 30: delete is permissionless only for a permanently invalid proof. A valid mature
    /// proof cannot be deleted, while the real CHALLENGER_WINS proof can be removed harmlessly.
    function test_T12_deleteProofPredicateSeparatesValidAndInvalidGames() public {
        Fixture memory valid = _loadFixture(1);
        Fixture memory invalid = _loadFixture(9);
        assertTrue(ASR.isGameClaimValid(valid.game));
        assertEq(IGame(invalid.game).status(), 1);

        vm.expectRevert();
        vm.prank(ATTACKER, ATTACKER);
        PORTAL.deleteProvenWithdrawal(valid.hash, valid.proofSubmitter);
        (address validGame, uint64 validTs) = PORTAL.provenWithdrawals(valid.hash, valid.proofSubmitter);
        assertEq(validGame, valid.game);
        assertGt(validTs, 0);

        vm.prank(ATTACKER, ATTACKER);
        PORTAL.deleteProvenWithdrawal(invalid.hash, invalid.proofSubmitter);
        (address deletedGame, uint64 deletedTs) = PORTAL.provenWithdrawals(invalid.hash, invalid.proofSubmitter);
        assertEq(deletedGame, address(0));
        assertEq(deletedTs, 0);
        assertFalse(PORTAL.finalizedWithdrawals(invalid.hash));
    }

    /// T13 / rows 21+22: both validator-only relationships are correct in deployed state, and the
    /// only relevant on-chain writers are privileged.
    function test_T13_validatorBindingsCannotBeChangedByAttacker() public {
        for (uint256 i; i < 4; i++) {
            ChainCfg memory c = _chain(i);
            ISystemConfig_T1 sys = ISystemConfig_T1(c.systemConfig);
            assertEq(sys.l2ChainId(), c.l2ChainId, c.name);
            assertEq(sys.optimismPortal(), c.portal, c.name);
            address implementationBefore = IDGF_T1(c.dgf).gameImpls(c.respectedType);
            assertTrue(implementationBefore != address(0), c.name);

            (bool setImplOk,) = _callAsAttacker(
                c.dgf,
                abi.encodeCall(IDGF_T1.setImplementation, (c.respectedType, ATTACKER))
            );
            assertFalse(setImplOk, c.name);
            assertEq(IDGF_T1(c.dgf).gameImpls(c.respectedType), implementationBefore, c.name);

            // l2ChainId is only assigned by initialize. Supply a fully ABI-valid same-version call
            // so failure is attributable to the deployed initializer/authorization barrier, not decoding.
            ResourceConfig_T1 memory config = ResourceConfig_T1({
                maxResourceLimit: 20_000_000,
                elasticityMultiplier: 10,
                baseFeeMaxChangeDenominator: 8,
                minimumBaseFee: 1 gwei,
                systemTxMaxGas: 1_000_000,
                maximumBaseFee: type(uint128).max
            });
            SystemAddresses_T1 memory addresses_ = SystemAddresses_T1({
                l1CrossDomainMessenger: c.messenger,
                l1ERC721Bridge: address(1),
                l1StandardBridge: address(2),
                optimismPortal: c.portal,
                optimismMintableERC20Factory: address(3),
                delayedWETH: address(4),
                opcm: address(5)
            });
            bytes memory validInitialize = abi.encodeCall(
                ISystemConfigInit_T1.initialize,
                (
                    ATTACKER,
                    uint32(1),
                    uint32(1),
                    bytes32(uint256(1)),
                    uint64(30_000_000),
                    ATTACKER,
                    config,
                    addresses_,
                    c.l2ChainId + 1,
                    ATTACKER
                )
            );
            (bool initOk,) = _callAsAttacker(c.systemConfig, validInitialize);
            assertFalse(initOk, c.name);
            assertEq(sys.l2ChainId(), c.l2ChainId, c.name);
        }
    }

    /// T14 / rows 31+33: an old-prestate game is permissionlessly disputable, but opening a claim
    /// only enters the adjudication tree; it does not make the root claim valid or authorize a withdrawal.
    function test_T14_oldPrestateWrappedAttackOnlyCreatesAChallenge() public {
        ChainCfg memory c = _chain(0);
        (, , address oldGame) = IDGF_T1(c.dgf).gameAtIndex(21_377);
        assertEq(IGame_T1(oldGame).absolutePrestate(), OLD_KONA_PRESTATE);
        assertEq(IGame_T1(oldGame).anchorStateRegistry(), c.asr);
        assertTrue(IASR_T1(c.asr).isGameProper(oldGame));
        assertFalse(IASR_T1(c.asr).isGameClaimValid(oldGame));
        assertEq(IGame_T1(oldGame).claimDataLen(), 1);

        bytes32 childClaim = keccak256("CATK-T1-old-prestate-child");
        uint256 bond = IGame_T1(oldGame).getRequiredBond(2); // root attack position
        vm.prank(ATTACKER, ATTACKER);
        IGame_T1(oldGame).attack{ value: bond }(IGame_T1(oldGame).rootClaim(), 0, childClaim);
        assertEq(IGame_T1(oldGame).claimDataLen(), 2);
        assertFalse(IASR_T1(c.asr).isGameClaimValid(oldGame));
    }

    /// T15 / rows 18+19: old WETH balances are bond escrows. Permissionless unlock is namespaced
    /// by msg.sender; recover/hold are owner-only. Four representative chain histories are tested.
    function test_T15_legacyDelayedWETHCannotReleaseSomeoneElsesBond() public {
        address[4] memory legacy = [
            address(0xE497B094d6DbB3D5E4CaAc9a14696D7572588d14),
            address(0x3Beaca17eaE5643FB1479AA5f4B1fF75cc4b9B50),
            address(0x9AEA1FD851b63d57Ba4Fc556B0e0c170126C9EAf),
            address(0xc9edb4E340f4E9683B4557bD9db8f9d932177C86)
        ];
        uint256[4] memory expectedBalances = [uint256(0.16 ether), 0.08 ether, 0, 0.08 ether];

        for (uint256 i; i < legacy.length; i++) {
            IDelayedWETH_T1 weth = IDelayedWETH_T1(legacy[i]);
            uint256 escrowBefore = legacy[i].balance;
            assertEq(escrowBefore, expectedBalances[i]);

            (bool recoverOk,) = _callAsAttacker(
                legacy[i], abi.encodeCall(IDelayedWETH_T1.recover, (type(uint256).max))
            );
            (bool holdOk,) =
                _callAsAttacker(legacy[i], abi.encodeCall(IDelayedWETH_T1.hold, (ATTACKER, escrowBefore + 1)));
            assertFalse(recoverOk);
            assertFalse(holdOk);
            assertEq(legacy[i].balance, escrowBefore);

            vm.prank(ATTACKER, ATTACKER);
            weth.deposit{ value: 1 wei }();
            vm.prank(ATTACKER, ATTACKER);
            weth.unlock(ATTACKER, 1 wei);
            vm.warp(block.timestamp + weth.delay() + 1);
            vm.prank(ATTACKER, ATTACKER);
            weth.withdraw(ATTACKER, 1 wei);
            assertEq(weth.balanceOf(ATTACKER), 0);
            assertEq(legacy[i].balance, escrowBefore, "only attacker's own wei was returned");
        }
    }
}
