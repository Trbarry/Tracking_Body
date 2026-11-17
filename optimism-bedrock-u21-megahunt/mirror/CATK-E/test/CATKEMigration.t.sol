// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

struct WithdrawalTransaction {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
}

struct OutputRootProof {
    bytes32 version;
    bytes32 stateRoot;
    bytes32 messagePasserStorageRoot;
    bytes32 latestBlockhash;
}

struct Proposal {
    bytes32 root;
    uint256 l2SequenceNumber;
}

struct DisputeGameConfig {
    bool enabled;
    uint256 initBond;
    uint32 gameType;
    bytes gameArgs;
}

struct MigrateInput {
    address[] chainSystemConfigs;
    DisputeGameConfig[] disputeGameConfigs;
    Proposal startingAnchorRoot;
    uint32 startingRespectedGameType;
}

interface IOPCM {
    function migrate(MigrateInput calldata input) external;
}

interface ISystemConfig {
    function optimismPortal() external view returns (address);
    function delayedWETH() external view returns (address);
    function isFeatureEnabled(bytes32 feature) external view returns (bool);
}

interface IPortal {
    function anchorStateRegistry() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function ethLockbox() external view returns (address);
    function donateETH() external payable;
    function depositTransaction(address to, uint256 value, uint64 gasLimit, bool isCreation, bytes calldata data)
        external
        payable;
    function proveWithdrawalTransaction(
        WithdrawalTransaction calldata withdrawal,
        uint256 disputeGameIndex,
        OutputRootProof calldata outputRootProof,
        bytes[] calldata withdrawalProof
    ) external;
    function finalizeWithdrawalTransaction(WithdrawalTransaction calldata withdrawal) external;
    function checkWithdrawal(bytes32 withdrawalHash, address proofSubmitter) external view;
    function provenWithdrawals(bytes32 withdrawalHash, address proofSubmitter)
        external
        view
        returns (address disputeGameProxy, uint64 timestamp);
}

interface IAnchorStateRegistry {
    function anchorGame() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function ethLockbox() external view returns (address);
    function getAnchorRoot() external view returns (bytes32 root, uint256 l2SequenceNumber);
    function getStartingAnchorRoot() external view returns (bytes32 root, uint256 l2SequenceNumber);
    function isGameClaimValid(address game) external view returns (bool);
    function isGameRegistered(address game) external view returns (bool);
    function setAnchorState(address game) external;
}

interface IGen1AnchorStateRegistry {
    function anchors(uint32 gameType) external view returns (bytes32 root, uint256 l2BlockNumber);
    function setAnchorState(address game) external;
    function tryUpdateAnchorState() external;
}

interface IDisputeGameFactory {
    function create(uint32 gameType, bytes32 rootClaim, bytes calldata extraData)
        external
        payable
        returns (address game);
    function gameCount() external view returns (uint256);
    function gameImpls(uint32 gameType) external view returns (address);
    function initBonds(uint32 gameType) external view returns (uint256);
    function setImplementation(uint32 gameType, address implementation) external;
    function setInitBond(uint32 gameType, uint256 bond) external;
}

interface IDisputeGame {
    function l2SequenceNumber() external view returns (uint256);
    function resolveClaim(uint256 claimIndex, uint256 numToResolve) external;
    function resolve() external returns (uint8 status);
    function status() external view returns (uint8);
}

interface IDelayedWETH {
    function deposit() external payable;
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function unlock(address subAccount, uint256 amount) external;
    function withdraw(address subAccount, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function withdrawals(address owner, address subAccount) external view returns (uint256 amount, uint256 timestamp);
    function delay() external view returns (uint256);
    function ethLockbox() external view returns (address);
}

interface IETHLockbox {
    function authorizedPortals(address portal) external view returns (bool);
    function authorizedLockboxes(address lockbox) external view returns (bool);
    function lockETH() external payable;
    function unlockETH(uint256 value) external;
    function receiveLiquidity() external payable;
    function migrateLiquidity(address lockbox) external;
    function authorizePortal(address portal) external;
    function authorizeLockbox(address lockbox) external;
}

contract DelegateCallerCATKE {
    function exec(address target, bytes calldata data) external returns (bytes memory result) {
        bool ok;
        (ok, result) = target.delegatecall(data);
        if (!ok) {
            assembly {
                revert(add(result, 0x20), mload(result))
            }
        }
    }
}

contract ForceETHCATKE {
    constructor() payable {}

    function force(address payable target) external {
        selfdestruct(target);
    }
}

/// @notice Independent CATK-E fork experiments against deployed OPCM 9.0.3 at block 26433900.
///         The Safe code replacement is used only to model the documented Safe -> OPCM delegatecall.
contract CATKEMigrationTest is Test {
    address constant SAFE = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address constant OPCM = 0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f;

    ISystemConfig constant OP_SC = ISystemConfig(0x229047fed2591dbec1eF1118d64F7aF3dB9EB290);
    ISystemConfig constant UNI_SC = ISystemConfig(0xc407398d063f942feBbcC6F80a156b47F3f1BDA6);
    IPortal constant OP_PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    IPortal constant UNI_PORTAL = IPortal(0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2);

    IAnchorStateRegistry constant OP_LIVE_ASR = IAnchorStateRegistry(0x23B2C62946350F4246f9f9D027e071f0264FD113);
    IAnchorStateRegistry constant UNI_LIVE_ASR = IAnchorStateRegistry(0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9);
    IAnchorStateRegistry constant OP_GEN2_ASR = IAnchorStateRegistry(0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b);
    IAnchorStateRegistry constant UNI_GEN2_ASR = IAnchorStateRegistry(0xD5D0e176be44E61eaB3Cf1FA8153758dF603376f);
    IGen1AnchorStateRegistry constant OP_GEN1_ASR =
        IGen1AnchorStateRegistry(0x18DAc71c228D1C32c99489B7323d441E1175e443);
    IGen1AnchorStateRegistry constant UNI_GEN1_ASR =
        IGen1AnchorStateRegistry(0x318A642db9e24A85318B8BF18eFd5287BA38643B);

    IDisputeGameFactory constant OP_DGF = IDisputeGameFactory(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);
    IDisputeGameFactory constant UNI_DGF = IDisputeGameFactory(0x2F12d621a16e2d3285929C9996f478508951dFe4);
    IETHLockbox constant OP_LOCKBOX = IETHLockbox(0x322b47Ff1FA8D5611F761e3E275C45B71b294D43);
    IETHLockbox constant UNI_LOCKBOX = IETHLockbox(0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5);

    IDelayedWETH constant OP_CURRENT_WETH = IDelayedWETH(0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162);
    IDelayedWETH constant UNI_CURRENT_WETH = IDelayedWETH(0x74ad145aC900F1DD5551F0C9E143314DC4022FCf);

    address constant ATTACKER = address(0xA77AC4E2);
    address constant SPENDER = address(0x5EED);
    address constant RECEIVER = address(0xBEEF);
    bytes32 constant ABSOLUTE_PRESTATE = 0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9;
    bytes32 constant INTEROP = "INTEROP";

    function setUp() public {
        vm.createSelectFork(vm.envOr("L1_ALIAS", string("l1")));
        assertEq(block.number, 26_433_900, "wrong pinned fork");
        vm.deal(ATTACKER, 1_000 ether);
        vm.label(ATTACKER, "CATK-E attacker");
        vm.label(SAFE, "ProxyAdminOwner Safe");
        vm.label(OPCM, "OPCM 9.0.3");
    }

    function _legacyWETHs() internal pure returns (address[] memory weths) {
        weths = new address[](11);
        weths[0] = 0xE497B094d6DbB3D5E4CaAc9a14696D7572588d14;
        weths[1] = 0x9F9b897e37de5052cD70Db6D08474550DDb07f39;
        weths[2] = 0x82511d494B5C942BE57498a70Fdd7184Ee33B975;
        weths[3] = 0x323dFC63c9B83CB83f40325AaB74b245937cbdF0;
        weths[4] = 0xe214879aD573693A4C49f7654449Caa455cdE34f;
        weths[5] = 0xD061AB95069987868768818cc1248705351e2D0e;
        weths[6] = 0x7d8Ea656D7417229f420b0c87f6428baA8499d70;
        weths[7] = 0x84B268A4101A8c8e3CcB33004F81eD08202bA124;
        weths[8] = 0xc9edb4E340f4E9683B4557bD9db8f9d932177C86;
        weths[9] = 0xa0157F0730Dea8d1a5c358Dc1d340a05D8796C23;
        weths[10] = 0x0bdbEc6bd35571F97f96f3ed21822a4f2e071A3c;
    }

    function _superRoot(uint64 timestamp, uint256 chainId, bytes32 outputRoot) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes1(0x01), timestamp, chainId, outputRoot);
    }

    function _twoChainSuperRoot(uint64 timestamp, bytes32 opRoot, bytes32 uniRoot)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(bytes1(0x01), timestamp, uint256(10), opRoot, uint256(130), uniRoot);
    }

    function _validInput() internal view returns (MigrateInput memory input) {
        address[] memory chains = new address[](2);
        chains[0] = address(OP_SC);
        chains[1] = address(UNI_SC);

        DisputeGameConfig[] memory configs = new DisputeGameConfig[](1);
        configs[0] = DisputeGameConfig({
            enabled: true, initBond: 0.08 ether, gameType: 9, gameArgs: abi.encode(ABSOLUTE_PRESTATE)
        });
        uint64 timestamp = uint64(block.timestamp - 600);
        bytes memory encodedRoot =
            _twoChainSuperRoot(timestamp, keccak256("CATK-E OP start"), keccak256("CATK-E UNI start"));
        input = MigrateInput({
            chainSystemConfigs: chains,
            disputeGameConfigs: configs,
            startingAnchorRoot: Proposal({root: keccak256(encodedRoot), l2SequenceNumber: timestamp}),
            startingRespectedGameType: 9
        });
    }

    function _malformedLateFailureInput() internal view returns (MigrateInput memory input) {
        input = _validInput();
        DisputeGameConfig[] memory configs = new DisputeGameConfig[](2);
        configs[0] = input.disputeGameConfigs[0];
        // Type 5's empty args pass the migrator's preflight validation, then fail abi.decode in
        // _makeGameArgs only after both chains have apparently been migrated.
        configs[1] = DisputeGameConfig({enabled: true, initBond: 0, gameType: 5, gameArgs: hex""});
        input.disputeGameConfigs = configs;
    }

    function _installSafeDelegateHarness() internal {
        vm.etch(SAFE, address(new DelegateCallerCATKE()).code);
    }

    function _callMigrate(MigrateInput memory input) internal returns (bool ok, bytes memory result) {
        _installSafeDelegateHarness();
        bytes memory opcmCall = abi.encodeCall(IOPCM.migrate, (input));
        (ok, result) = SAFE.call(abi.encodeCall(DelegateCallerCATKE.exec, (OPCM, opcmCall)));
    }

    function _migrate(MigrateInput memory input) internal {
        (bool ok, bytes memory result) = _callMigrate(input);
        if (!ok) {
            assembly {
                revert(add(result, 0x20), mload(result))
            }
        }
    }

    function _migrate() internal returns (IAnchorStateRegistry sharedASR, IDisputeGameFactory sharedDGF) {
        _migrate(_validInput());
        sharedASR = IAnchorStateRegistry(OP_PORTAL.anchorStateRegistry());
        sharedDGF = IDisputeGameFactory(sharedASR.disputeGameFactory());
    }

    function _contains(bytes32[] memory values, bytes32 needle) internal pure returns (bool) {
        for (uint256 i; i < values.length; i++) {
            if (values[i] == needle) return true;
        }
        return false;
    }

    function _assertNoRecordedAccess(address target, string memory reason) internal view {
        (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(target);
        assertEq(reads.length + writes.length, 0, reason);
    }

    function _withdrawalHash(WithdrawalTransaction memory withdrawal) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                withdrawal.nonce,
                withdrawal.sender,
                withdrawal.target,
                withdrawal.value,
                withdrawal.gasLimit,
                withdrawal.data
            )
        );
    }

    function _fakeOutput(WithdrawalTransaction memory withdrawal)
        internal
        pure
        returns (bytes32 outputRoot, OutputRootProof memory proof, bytes[] memory withdrawalProof)
    {
        bytes32 storageKey = keccak256(abi.encode(_withdrawalHash(withdrawal), uint256(0)));
        bytes32 trieKey = keccak256(abi.encode(storageKey));
        bytes memory leaf = abi.encodePacked(hex"e3a120", trieKey, hex"01");
        proof = OutputRootProof({
            version: bytes32(0),
            stateRoot: keccak256("CATK-E fake state"),
            messagePasserStorageRoot: keccak256(leaf),
            latestBlockhash: keccak256("CATK-E fake block")
        });
        outputRoot = keccak256(
            abi.encode(proof.version, proof.stateRoot, proof.messagePasserStorageRoot, proof.latestBlockhash)
        );
        withdrawalProof = new bytes[](1);
        withdrawalProof[0] = leaf;
    }

    function _prepositionProof(
        IPortal portal,
        IAnchorStateRegistry asr,
        IDisputeGameFactory dgf,
        uint256 chainId,
        uint256 nonce
    ) internal returns (address game, bytes32 withdrawalHash, uint256 gameIndex) {
        WithdrawalTransaction memory withdrawal = WithdrawalTransaction({
            nonce: nonce, sender: ATTACKER, target: ATTACKER, value: 100 ether, gasLimit: 100_000, data: ""
        });
        (bytes32 outputRoot, OutputRootProof memory outputProof, bytes[] memory withdrawalProof) =
            _fakeOutput(withdrawal);
        (, uint256 anchorSequence) = asr.getAnchorRoot();
        bytes memory extraData = _superRoot(uint64(anchorSequence + 1), chainId, outputRoot);
        gameIndex = dgf.gameCount();
        vm.prank(ATTACKER);
        game = dgf.create{value: 0.08 ether}(9, keccak256(extraData), extraData);
        vm.warp(block.timestamp + 1);
        vm.prank(ATTACKER);
        portal.proveWithdrawalTransaction(withdrawal, gameIndex, outputProof, withdrawalProof);
        withdrawalHash = _withdrawalHash(withdrawal);
    }

    function _forceETH(address target, uint256 amount) internal {
        vm.prank(ATTACKER);
        ForceETHCATKE force = new ForceETHCATKE{value: amount}();
        force.force(payable(target));
    }

    /// E01: The two v2.2.2 orphan registries are genuinely attacker-writable with already-final
    /// production games, but migration performs zero storage accesses to either registry.
    function test_E01_moveBothGen2Anchors_migrationDoesNotReadThem() public {
        (, uint256 opBefore) = OP_GEN2_ASR.getAnchorRoot();
        (, uint256 uniBefore) = UNI_GEN2_ASR.getAnchorRoot();
        address opSuperCandidate = OP_LIVE_ASR.anchorGame();
        address uniSuperCandidate = UNI_LIVE_ASR.anchorGame();
        assertTrue(OP_GEN2_ASR.isGameClaimValid(opSuperCandidate));
        assertTrue(UNI_GEN2_ASR.isGameClaimValid(uniSuperCandidate));
        vm.prank(ATTACKER);
        (bool opSuperCompatible,) =
            address(OP_GEN2_ASR).call(abi.encodeCall(IAnchorStateRegistry.setAnchorState, (opSuperCandidate)));
        vm.prank(ATTACKER);
        (bool uniSuperCompatible,) =
            address(UNI_GEN2_ASR).call(abi.encodeCall(IAnchorStateRegistry.setAnchorState, (uniSuperCandidate)));
        assertFalse(opSuperCompatible, "v2.2.2 unexpectedly accepted l2SequenceNumber-only game");
        assertFalse(uniSuperCompatible, "v2.2.2 unexpectedly accepted l2SequenceNumber-only game");

        // Current type-9 Super games have no legacy l2BlockNumber() selector. Use finalized
        // type-8 games from the live generation, which v2.2.2 accepts and can actually anchor.
        address opCandidate = 0x4ffb1A59A7D81876377A74b59869670d8192abFf; // OP DGF index 19206
        address uniCandidate = 0x6426Ea5B64172568F6544583D4aa65c67FC01d6a; // UNI DGF index 16000
        assertTrue(OP_GEN2_ASR.isGameClaimValid(opCandidate));
        assertTrue(UNI_GEN2_ASR.isGameClaimValid(uniCandidate));

        vm.prank(ATTACKER);
        OP_GEN2_ASR.setAnchorState(opCandidate);
        vm.prank(ATTACKER);
        UNI_GEN2_ASR.setAnchorState(uniCandidate);
        (, uint256 poisonedOP) = OP_GEN2_ASR.getAnchorRoot();
        (, uint256 poisonedUNI) = UNI_GEN2_ASR.getAnchorRoot();
        assertGt(poisonedOP, opBefore);
        assertGt(poisonedUNI, uniBefore);
        emit log_named_uint("OP gen2 sequence before", opBefore);
        emit log_named_uint("OP gen2 sequence after", poisonedOP);
        emit log_named_uint("UNI gen2 sequence before", uniBefore);
        emit log_named_uint("UNI gen2 sequence after", poisonedUNI);

        MigrateInput memory input = _validInput();
        vm.record();
        _migrate(input);
        _assertNoRecordedAccess(address(OP_GEN2_ASR), "OP gen2 consumed");
        _assertNoRecordedAccess(address(UNI_GEN2_ASR), "UNI gen2 consumed");
        _assertNoRecordedAccess(address(OP_GEN1_ASR), "OP gen1 consumed");
        _assertNoRecordedAccess(address(UNI_GEN1_ASR), "UNI gen1 consumed");

        IAnchorStateRegistry shared = IAnchorStateRegistry(OP_PORTAL.anchorStateRegistry());
        emit log_named_address("shared ASR", address(shared));
        (bytes32 installedRoot, uint256 installedSequence) = shared.getStartingAnchorRoot();
        assertEq(installedRoot, input.startingAnchorRoot.root);
        assertEq(installedSequence, input.startingAnchorRoot.l2SequenceNumber);
        (, uint256 opAfter) = OP_GEN2_ASR.getAnchorRoot();
        (, uint256 uniAfter) = UNI_GEN2_ASR.getAnchorRoot();
        assertEq(opAfter, poisonedOP, "orphan poison unexpectedly transformed");
        assertEq(uniAfter, poisonedUNI, "orphan poison unexpectedly transformed");
        assertFalse(shared.isGameRegistered(opCandidate));
        assertFalse(shared.isGameRegistered(uniCandidate));
    }

    /// E02: Even a permissionlessly advanced live anchorGame is not a migration input. This uses
    /// the normal unchallenged-game path only as a reachability control; it is not claimed as an exploit.
    function test_E02_advanceLiveAnchor_anchorSlotNotReadByMigration() public {
        (, uint256 oldSequence) = OP_LIVE_ASR.getAnchorRoot();
        bytes memory extraData = _superRoot(uint64(oldSequence + 1), 10, keccak256("CATK-E attacker-selected output"));
        vm.prank(ATTACKER);
        address game = OP_DGF.create{value: 0.08 ether}(9, keccak256(extraData), extraData);

        vm.warp(block.timestamp + 302_401);
        IDisputeGame(game).resolveClaim(0, 0);
        IDisputeGame(game).resolve();
        assertEq(IDisputeGame(game).status(), 2, "control game did not resolve defender-wins");
        vm.warp(block.timestamp + 604_801);
        assertTrue(OP_LIVE_ASR.isGameClaimValid(game));
        vm.prank(ATTACKER);
        OP_LIVE_ASR.setAnchorState(game);
        assertEq(OP_LIVE_ASR.anchorGame(), game);
        emit log_named_address("attacker-selected live anchor game", game);

        MigrateInput memory input = _validInput();
        vm.record();
        _migrate(input);
        (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(address(OP_LIVE_ASR));
        bytes32 anchorGameSlot = bytes32(uint256(2));
        assertFalse(_contains(reads, anchorGameSlot), "migrator read poisoned anchorGame");
        assertFalse(_contains(writes, anchorGameSlot), "migrator rewrote poisoned anchorGame");

        assertEq(OP_LIVE_ASR.anchorGame(), game, "old orphan anchor should persist");
        IAnchorStateRegistry shared = IAnchorStateRegistry(OP_PORTAL.anchorStateRegistry());
        (bytes32 root, uint256 sequence) = shared.getAnchorRoot();
        assertEq(root, input.startingAnchorRoot.root);
        assertEq(sequence, input.startingAnchorRoot.l2SequenceNumber);
        assertFalse(shared.isGameRegistered(game));
    }

    /// E03: Exercise all three user-writable storage families (balance, allowance, withdrawal)
    /// on every legacy DelayedWETH proxy, then prove all eleven proxies are absent from migration.
    function test_E03_mutateEveryLegacyWETH_allUnreadAndRedeemable() public {
        address[] memory weths = _legacyWETHs();
        uint256 maxDelay;
        for (uint256 i; i < weths.length; i++) {
            IDelayedWETH weth = IDelayedWETH(weths[i]);
            vm.startPrank(ATTACKER);
            weth.deposit{value: 5 wei}();
            assertTrue(weth.approve(SPENDER, 1 wei));
            assertTrue(weth.transfer(RECEIVER, 1 wei));
            weth.unlock(ATTACKER, 1 wei);
            vm.stopPrank();
            vm.prank(SPENDER);
            assertTrue(weth.transferFrom(ATTACKER, RECEIVER, 1 wei));
            (uint256 unlocked,) = weth.withdrawals(ATTACKER, ATTACKER);
            assertEq(unlocked, 1 wei);
            assertEq(weth.balanceOf(ATTACKER), 3 wei);
            if (weth.delay() > maxDelay) maxDelay = weth.delay();
        }

        vm.warp(block.timestamp + maxDelay + 1);
        for (uint256 i; i < weths.length; i++) {
            vm.prank(ATTACKER);
            IDelayedWETH(weths[i]).withdraw(ATTACKER, 1 wei);
            assertEq(IDelayedWETH(weths[i]).balanceOf(ATTACKER), 2 wei);
        }

        vm.record();
        _migrate();
        for (uint256 i; i < weths.length; i++) {
            (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(weths[i]);
            assertEq(reads.length + writes.length, 0, "legacy WETH consumed by migration");
            assertEq(IDelayedWETH(weths[i]).balanceOf(ATTACKER), 2 wei, "legacy balance altered");
        }
    }

    /// E04: The two live WETH proxies are reinitialized, but balances and unlock requests persist;
    /// both remain redeemable even though Unichain's proxy becomes an orphan.
    function test_E04_currentWETHStateSurvivesRewire_andBothWithdraw() public {
        IDelayedWETH[2] memory weths = [OP_CURRENT_WETH, UNI_CURRENT_WETH];
        for (uint256 i; i < weths.length; i++) {
            vm.startPrank(ATTACKER);
            weths[i].deposit{value: 3 wei}();
            weths[i].unlock(ATTACKER, 1 wei);
            vm.stopPrank();
        }

        vm.record();
        _migrate();
        (bytes32[] memory opReads, bytes32[] memory opWrites) = vm.accesses(address(OP_CURRENT_WETH));
        (bytes32[] memory uniReads, bytes32[] memory uniWrites) = vm.accesses(address(UNI_CURRENT_WETH));
        assertGt(opReads.length + opWrites.length, 0, "OP live WETH not touched");
        assertGt(uniReads.length + uniWrites.length, 0, "UNI live WETH not touched");

        address sharedLockbox = OP_PORTAL.ethLockbox();
        assertEq(OP_SC.delayedWETH(), address(OP_CURRENT_WETH));
        assertEq(UNI_SC.delayedWETH(), address(OP_CURRENT_WETH));
        assertEq(OP_CURRENT_WETH.ethLockbox(), sharedLockbox);
        assertEq(UNI_CURRENT_WETH.ethLockbox(), sharedLockbox);
        assertEq(OP_CURRENT_WETH.balanceOf(ATTACKER), 3 wei);
        assertEq(UNI_CURRENT_WETH.balanceOf(ATTACKER), 3 wei);

        uint256 wait = OP_CURRENT_WETH.delay();
        if (UNI_CURRENT_WETH.delay() > wait) wait = UNI_CURRENT_WETH.delay();
        vm.warp(block.timestamp + wait + 1);
        vm.prank(ATTACKER);
        OP_CURRENT_WETH.withdraw(ATTACKER, 1 wei);
        vm.prank(ATTACKER);
        UNI_CURRENT_WETH.withdraw(ATTACKER, 1 wei);
        assertEq(OP_CURRENT_WETH.balanceOf(ATTACKER), 2 wei);
        assertEq(UNI_CURRENT_WETH.balanceOf(ATTACKER), 2 wei);
    }

    /// E05: Create attacker games and validly record fabricated withdrawal proofs on both current
    /// portals. Migration retains the records but removes their authority by swapping registries.
    function test_E05_gamesAndProofsOnBothChains_doNotSurviveAuthoritySwap() public {
        (address opGame, bytes32 opWithdrawalHash,) = _prepositionProof(OP_PORTAL, OP_LIVE_ASR, OP_DGF, 10, 10_001);
        (address uniGame, bytes32 uniWithdrawalHash,) =
            _prepositionProof(UNI_PORTAL, UNI_LIVE_ASR, UNI_DGF, 130, 13_001);
        emit log_named_address("pre-positioned OP game", opGame);
        emit log_named_address("pre-positioned UNI game", uniGame);
        (address opRecorded,) = OP_PORTAL.provenWithdrawals(opWithdrawalHash, ATTACKER);
        (address uniRecorded,) = UNI_PORTAL.provenWithdrawals(uniWithdrawalHash, ATTACKER);
        assertEq(opRecorded, opGame);
        assertEq(uniRecorded, uniGame);

        (IAnchorStateRegistry shared, IDisputeGameFactory newDGF) = _migrate();
        assertFalse(shared.isGameRegistered(opGame));
        assertFalse(shared.isGameRegistered(uniGame));
        assertEq(newDGF.gameCount(), 0);
        assertEq(OP_DGF.gameImpls(9), address(0));
        assertEq(UNI_DGF.gameImpls(9), address(0));
        (opRecorded,) = OP_PORTAL.provenWithdrawals(opWithdrawalHash, ATTACKER);
        (uniRecorded,) = UNI_PORTAL.provenWithdrawals(uniWithdrawalHash, ATTACKER);
        assertEq(opRecorded, opGame, "record itself should persist");
        assertEq(uniRecorded, uniGame, "record itself should persist");
        vm.expectRevert();
        OP_PORTAL.checkWithdrawal(opWithdrawalHash, ATTACKER);
        vm.expectRevert();
        UNI_PORTAL.checkWithdrawal(uniWithdrawalHash, ATTACKER);
    }

    /// E06: Exercise deposits, donations, and forced ETH against both portals and both lockboxes.
    /// Every pre-migration wei is pooled; sticky retired authorization gives an attacker no caller right.
    function test_E06_depositDonateForceETH_conservedAndUnauthorized() public {
        vm.startPrank(ATTACKER);
        OP_PORTAL.depositTransaction{value: 1 ether}(ATTACKER, 1 ether, 100_000, false, "");
        UNI_PORTAL.depositTransaction{value: 2 ether}(ATTACKER, 2 ether, 100_000, false, "");
        OP_PORTAL.donateETH{value: 0.1 ether}();
        UNI_PORTAL.donateETH{value: 0.2 ether}();
        vm.stopPrank();
        _forceETH(address(OP_PORTAL), 11 wei);
        _forceETH(address(UNI_PORTAL), 13 wei);
        _forceETH(address(OP_LOCKBOX), 17 wei);
        _forceETH(address(UNI_LOCKBOX), 19 wei);

        uint256 custody = address(OP_PORTAL).balance + address(UNI_PORTAL).balance + address(OP_LOCKBOX).balance
            + address(UNI_LOCKBOX).balance;
        _migrate();
        address sharedLockbox = OP_PORTAL.ethLockbox();
        emit log_named_address("shared lockbox", sharedLockbox);
        emit log_named_uint("pooled custody", sharedLockbox.balance);
        assertEq(UNI_PORTAL.ethLockbox(), sharedLockbox);
        assertEq(sharedLockbox.balance, custody, "pooled ETH conservation");
        assertEq(address(OP_PORTAL).balance + address(UNI_PORTAL).balance, 0);
        assertEq(address(OP_LOCKBOX).balance + address(UNI_LOCKBOX).balance, 0);
        assertTrue(IETHLockbox(sharedLockbox).authorizedLockboxes(address(OP_LOCKBOX)));
        assertTrue(IETHLockbox(sharedLockbox).authorizedLockboxes(address(UNI_LOCKBOX)));

        vm.startPrank(ATTACKER);
        (bool lockOK,) = address(OP_LOCKBOX).call{value: 1 wei}(abi.encodeCall(IETHLockbox.lockETH, ()));
        (bool receiveOK,) = sharedLockbox.call{value: 1 wei}(abi.encodeCall(IETHLockbox.receiveLiquidity, ()));
        (bool unlockOK,) = address(OP_LOCKBOX).call(abi.encodeCall(IETHLockbox.unlockETH, (1 wei)));
        (bool migrateOK,) = address(OP_LOCKBOX).call(abi.encodeCall(IETHLockbox.migrateLiquidity, (sharedLockbox)));
        (bool authorizePortalOK,) = sharedLockbox.call(abi.encodeCall(IETHLockbox.authorizePortal, (ATTACKER)));
        (bool authorizeLockboxOK,) =
            sharedLockbox.call(abi.encodeCall(IETHLockbox.authorizeLockbox, (address(OP_LOCKBOX))));
        vm.stopPrank();
        assertFalse(lockOK);
        assertFalse(receiveOK);
        assertFalse(unlockOK);
        assertFalse(migrateOK);
        assertFalse(authorizePortalOK);
        assertFalse(authorizeLockboxOK);

        // Post-migration donations can only add attacker-owned ETH. They cannot reduce pooled assets.
        uint256 pooledBefore = sharedLockbox.balance;
        _forceETH(address(OP_LOCKBOX), 23 wei);
        _forceETH(sharedLockbox, 29 wei);
        vm.prank(ATTACKER);
        OP_PORTAL.depositTransaction{value: 31 wei}(ATTACKER, 31 wei, 100_000, false, "");
        assertEq(sharedLockbox.balance, pooledBefore + 29 wei + 31 wei);
        assertEq(address(OP_LOCKBOX).balance, 23 wei);
    }

    /// E07: Gen-1 registries and retired game types expose no ordinary-account path to a chosen
    /// anchor. U21 already removed type 0/1 implementations from both factories.
    function test_E07_gen1AndRetiredGameMutationGates() public {
        assertEq(OP_DGF.gameImpls(0), address(0));
        assertEq(OP_DGF.gameImpls(1), address(0));
        assertEq(UNI_DGF.gameImpls(0), address(0));
        assertEq(UNI_DGF.gameImpls(1), address(0));

        (, uint256 opAnchorSequence) = OP_LIVE_ASR.getAnchorRoot();
        (, uint256 uniAnchorSequence) = UNI_LIVE_ASR.getAnchorRoot();
        bytes memory opPermissionedExtra = _superRoot(uint64(opAnchorSequence + 1), 10, keccak256("CATK-E type-5 OP"));
        bytes memory uniPermissionedExtra =
            _superRoot(uint64(uniAnchorSequence + 1), 130, keccak256("CATK-E type-5 UNI"));

        vm.startPrank(ATTACKER);
        (bool opCreate,) = address(OP_DGF).call(abi.encodeCall(IDisputeGameFactory.create, (0, bytes32(0), "")));
        (bool uniCreate,) = address(UNI_DGF).call(abi.encodeCall(IDisputeGameFactory.create, (0, bytes32(0), "")));
        (bool opPermissionedCreate,) = address(OP_DGF)
            .call(abi.encodeCall(IDisputeGameFactory.create, (5, keccak256(opPermissionedExtra), opPermissionedExtra)));
        (bool uniPermissionedCreate,) = address(UNI_DGF)
            .call(
                abi.encodeCall(IDisputeGameFactory.create, (5, keccak256(uniPermissionedExtra), uniPermissionedExtra))
            );
        (bool opOwnerSetter,) =
            address(OP_DGF).call(abi.encodeCall(IDisputeGameFactory.setImplementation, (uint32(0), address(0xBAD))));
        (bool uniOwnerSetter,) =
            address(UNI_DGF).call(abi.encodeCall(IDisputeGameFactory.setInitBond, (uint32(9), 1 wei)));
        (bool opTryUpdate,) =
            address(OP_GEN1_ASR).call(abi.encodeCall(IGen1AnchorStateRegistry.tryUpdateAnchorState, ()));
        (bool uniTryUpdate,) =
            address(UNI_GEN1_ASR).call(abi.encodeCall(IGen1AnchorStateRegistry.tryUpdateAnchorState, ()));
        (bool opSet,) = address(OP_GEN1_ASR)
            .call(abi.encodeCall(IGen1AnchorStateRegistry.setAnchorState, (OP_LIVE_ASR.anchorGame())));
        (bool uniSet,) = address(UNI_GEN1_ASR)
            .call(abi.encodeCall(IGen1AnchorStateRegistry.setAnchorState, (UNI_LIVE_ASR.anchorGame())));
        vm.stopPrank();
        assertFalse(opCreate);
        assertFalse(uniCreate);
        assertFalse(opPermissionedCreate);
        assertFalse(uniPermissionedCreate);
        assertFalse(opOwnerSetter);
        assertFalse(uniOwnerSetter);
        assertFalse(opTryUpdate);
        assertFalse(uniTryUpdate);
        assertFalse(opSet);
        assertFalse(uniSet);
    }

    /// E08: Even if an attacker knows the future timestamp and prefunds all three deterministic
    /// proxy addresses, CREATE2 succeeds. The only effect is donated surplus/trapped attacker ETH.
    function test_E08_prefundFutureProxyAddresses_noCollisionOrUnsafeRoot() public {
        uint256 snapshot = vm.snapshotState();
        MigrateInput memory input = _validInput();
        _migrate(input);
        address predictedLockbox = OP_PORTAL.ethLockbox();
        address predictedASR = OP_PORTAL.anchorStateRegistry();
        address predictedDGF = OP_PORTAL.disputeGameFactory();
        emit log_named_address("predicted shared lockbox", predictedLockbox);
        emit log_named_address("predicted shared ASR", predictedASR);
        emit log_named_address("predicted shared DGF", predictedDGF);
        assertTrue(vm.revertToState(snapshot));
        assertEq(predictedLockbox.code.length, 0);
        assertEq(predictedASR.code.length, 0);
        assertEq(predictedDGF.code.length, 0);

        uint256 oldCustody = address(OP_LOCKBOX).balance + address(UNI_LOCKBOX).balance;
        vm.startPrank(ATTACKER);
        (bool sentLB,) = payable(predictedLockbox).call{value: 101 wei}("");
        (bool sentASR,) = payable(predictedASR).call{value: 103 wei}("");
        (bool sentDGF,) = payable(predictedDGF).call{value: 107 wei}("");
        vm.stopPrank();
        assertTrue(sentLB && sentASR && sentDGF);

        _migrate(input);
        assertEq(OP_PORTAL.ethLockbox(), predictedLockbox);
        assertEq(OP_PORTAL.anchorStateRegistry(), predictedASR);
        assertEq(OP_PORTAL.disputeGameFactory(), predictedDGF);
        assertEq(predictedLockbox.balance, oldCustody + 101 wei);
        assertEq(predictedASR.balance, 103 wei);
        assertEq(predictedDGF.balance, 107 wei);
        (bytes32 installedRoot, uint256 installedSequence) = IAnchorStateRegistry(predictedASR).getAnchorRoot();
        assertEq(installedRoot, input.startingAnchorRoot.root);
        assertEq(installedSequence, input.startingAnchorRoot.l2SequenceNumber);
    }

    /// E09: A genuine late failure after portal/lockbox mutations is transaction-atomic. Correcting
    /// the privileged malformed type-5 args permits an immediate retry from the untouched state.
    function test_E09_lateFailureRollsBackAllState_thenRetrySucceeds() public {
        _installSafeDelegateHarness();
        uint64 safeNonceBefore = vm.getNonce(SAFE);
        address opASRBefore = OP_PORTAL.anchorStateRegistry();
        address uniASRBefore = UNI_PORTAL.anchorStateRegistry();
        address opLockboxBefore = OP_PORTAL.ethLockbox();
        address uniLockboxBefore = UNI_PORTAL.ethLockbox();
        uint256 opBalanceBefore = opLockboxBefore.balance;
        uint256 uniBalanceBefore = uniLockboxBefore.balance;

        (bool ok,) = _callMigrate(_malformedLateFailureInput());
        assertFalse(ok, "malformed late config unexpectedly succeeded");
        assertEq(OP_PORTAL.anchorStateRegistry(), opASRBefore);
        assertEq(UNI_PORTAL.anchorStateRegistry(), uniASRBefore);
        assertEq(OP_PORTAL.ethLockbox(), opLockboxBefore);
        assertEq(UNI_PORTAL.ethLockbox(), uniLockboxBefore);
        assertEq(opLockboxBefore.balance, opBalanceBefore);
        assertEq(uniLockboxBefore.balance, uniBalanceBefore);
        assertFalse(OP_SC.isFeatureEnabled(INTEROP));
        assertFalse(UNI_SC.isFeatureEnabled(INTEROP));
        assertEq(vm.getNonce(SAFE), safeNonceBefore, "reverted CREATE2 changed Safe nonce");

        _migrate(_validInput());
        assertTrue(OP_SC.isFeatureEnabled(INTEROP));
        assertTrue(UNI_SC.isFeatureEnabled(INTEROP));
        assertEq(OP_PORTAL.anchorStateRegistry(), UNI_PORTAL.anchorStateRegistry());
        assertEq(OP_PORTAL.ethLockbox(), UNI_PORTAL.ethLockbox());
    }

    /// E10: A second migration is rejected by the permanent INTEROP bit before any custody change.
    function test_E10_repeatedMigrationRejected_stateUnchanged() public {
        MigrateInput memory input = _validInput();
        vm.prank(ATTACKER);
        (bool directOK,) = OPCM.call(abi.encodeCall(IOPCM.migrate, (input)));
        DelegateCallerCATKE rogueDelegate = new DelegateCallerCATKE();
        vm.prank(ATTACKER);
        (bool rogueDelegateOK,) = address(rogueDelegate)
            .call(abi.encodeCall(DelegateCallerCATKE.exec, (OPCM, abi.encodeCall(IOPCM.migrate, (input)))));
        assertFalse(directOK, "OPCM accepted a non-delegate migration");
        assertFalse(rogueDelegateOK, "non-owner delegate context migrated chains");

        _migrate();
        address sharedASR = OP_PORTAL.anchorStateRegistry();
        address sharedDGF = OP_PORTAL.disputeGameFactory();
        address sharedLockbox = OP_PORTAL.ethLockbox();
        uint256 balance = sharedLockbox.balance;

        (bool ok, bytes memory reason) = _callMigrate(input);
        assertFalse(ok, "repeat migration succeeded");
        assertGe(reason.length, 4);
        bytes4 selector;
        assembly {
            selector := mload(add(reason, 0x20))
        }
        assertEq(selector, bytes4(keccak256("OPContractsManagerMigrator_ChainAlreadyMigrated()")));
        assertEq(OP_PORTAL.anchorStateRegistry(), sharedASR);
        assertEq(OP_PORTAL.disputeGameFactory(), sharedDGF);
        assertEq(OP_PORTAL.ethLockbox(), sharedLockbox);
        assertEq(UNI_PORTAL.ethLockbox(), sharedLockbox);
        assertEq(sharedLockbox.balance, balance);
    }

    /// E11: Positive control for post-migration withdrawal availability. A fresh shared game can
    /// prove and finalize against OP, paying from the pooled lockbox after normal timing gates.
    function test_E11_postMigrationGameAndWithdrawal_payFromSharedPool() public {
        (IAnchorStateRegistry sharedASR, IDisputeGameFactory sharedDGF) = _migrate();
        vm.warp(block.timestamp + 1); // same-timestamp games are deliberately retired

        WithdrawalTransaction memory withdrawal = WithdrawalTransaction({
            nonce: 88_001, sender: ATTACKER, target: ATTACKER, value: 1 ether, gasLimit: 100_000, data: ""
        });
        (bytes32 outputRoot, OutputRootProof memory outputProof, bytes[] memory withdrawalProof) =
            _fakeOutput(withdrawal);
        (, uint256 anchorSequence) = sharedASR.getAnchorRoot();
        bytes memory extraData = _superRoot(uint64(anchorSequence + 1), 10, outputRoot);
        vm.prank(ATTACKER);
        address game = sharedDGF.create{value: 0.08 ether}(9, keccak256(extraData), extraData);
        assertTrue(sharedASR.isGameRegistered(game));

        vm.warp(block.timestamp + 1);
        vm.prank(ATTACKER);
        OP_PORTAL.proveWithdrawalTransaction(withdrawal, 0, outputProof, withdrawalProof);
        vm.warp(block.timestamp + 302_401);
        IDisputeGame(game).resolveClaim(0, 0);
        IDisputeGame(game).resolve();
        assertEq(IDisputeGame(game).status(), 2);
        vm.warp(block.timestamp + 604_801);
        uint256 balanceBefore = ATTACKER.balance;
        vm.prank(ATTACKER);
        OP_PORTAL.finalizeWithdrawalTransaction(withdrawal);
        assertEq(ATTACKER.balance - balanceBefore, 1 ether);
    }
}
