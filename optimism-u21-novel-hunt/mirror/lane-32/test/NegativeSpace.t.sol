// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";

interface ILockbox32 {
    function paused() external view returns (bool);
    function superchainConfig() external view returns (address);
    function guardian() external view returns (address);
    function authorizedPortals(address) external view returns (bool);
    function lockETH() external payable;
    function receiveLiquidity() external payable;
    function unlockETH(uint256) external;
    function authorizePortal(address) external;
    function authorizeLockbox(address) external;
}

interface IPortal32 {
    function paused() external view returns (bool);
    function systemConfig() external view returns (address);
    function ethLockbox() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function donateETH() external payable;
    function migrateLiquidity() external;
    function migrateToSharedDisputeGame(address, address) external;
    function deleteProvenWithdrawal(bytes32, address) external;
    function provenWithdrawals(bytes32, address) external view returns (address disputeGameProxy, uint64 timestamp);
}

interface ISystemConfig32 {
    function superchainConfig() external view returns (address);
    function delayedWETH() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function isFeatureEnabled(bytes32) external view returns (bool);
    function setFeature(bytes32, bool) external;
}

interface IAnchorStateRegistry32 {
    function ethLockbox() external view returns (address);
    function respectedGameType() external view returns (uint32);
    function isGameBlacklisted(address) external view returns (bool);
    function setRespectedGameType(uint32) external;
}

interface IDelayedWETH32 {
    function ethLockbox() external view returns (address);
}

interface IDisputeGameFactory32 {
    function owner() external view returns (address);
    function gameImpls(uint32) external view returns (address);
    function initBonds(uint32) external view returns (uint256);
    function setInitBond(uint32, uint256) external;
}

interface IProxyAdminOwned32 {
    function proxyAdminOwner() external view returns (address);
}

interface IGame32 {
    function status() external view returns (uint8);
}

interface IMessenger32 {
    function version() external view returns (string memory);
    function RELAY_CONSTANT_OVERHEAD() external view returns (uint64);
    function RELAY_CALL_OVERHEAD() external view returns (uint64);
    function RELAY_RESERVED_GAS() external view returns (uint64);
    function RELAY_GAS_CHECK_BUFFER() external view returns (uint64);
    function baseGas(bytes memory, uint32) external view returns (uint64);
}

contract ForceSend32 {
    constructor(address payable target) payable {
        selfdestruct(target);
    }
}

contract NegativeSpaceTest is Test {
    address internal constant PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    address internal constant SYSCFG = 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290;
    address internal constant ASR = 0x23B2C62946350F4246f9f9D027e071f0264FD113;
    address internal constant DGF = 0xe5965Ab5962eDc7477C8520243A95517CD252fA9;
    address internal constant DWETH = 0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162;
    address internal constant SUPERCHAIN_CONFIG = 0x95703e0982140D16f8ebA6d158FccEde42f04a4C;
    address internal constant L1_MESSENGER = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address internal constant L2_MESSENGER = 0x4200000000000000000000000000000000000007;
    bytes32 internal constant ETH_LOCKBOX = bytes32("ETH_LOCKBOX");
    bytes32 internal constant INTEROP = bytes32("INTEROP");

    function setUp() external {
        vm.createSelectFork("l1");
    }

    function test_allFourChains_bindPauseAndGamesToExactLiveLockbox() external view {
        address[4] memory sys = [
            SYSCFG,
            0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364,
            0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3,
            0xc407398d063f942feBbcC6F80a156b47F3f1BDA6
        ];
        address[4] memory portals = [
            PORTAL,
            0x5d66C1782664115999C47c9fA5cd031f495D3e4F,
            0x88e529A6ccd302c948689Cd5156C83D4614FAE92,
            0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2
        ];
        address[4] memory lockboxes = [
            LOCKBOX,
            0xbd4AbB321138e8Eddc399cE64E66451294325a14,
            0x67B4de6FfA66EF201Ea6099A89cA397D56622E31,
            0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5
        ];
        address[4] memory registries = [
            ASR,
            0xEe018bAf058227872540AC60eFbd38b023d9dAe2,
            0x4890928941e62e273dA359374b105F803329F473,
            0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9
        ];

        for (uint256 i; i < 4; i++) {
            ISystemConfig32 cfg = ISystemConfig32(sys[i]);
            IPortal32 portal = IPortal32(portals[i]);
            ILockbox32 lockbox = ILockbox32(lockboxes[i]);
            IAnchorStateRegistry32 registry = IAnchorStateRegistry32(registries[i]);
            IDelayedWETH32 weth = IDelayedWETH32(cfg.delayedWETH());
            IDisputeGameFactory32 factory = IDisputeGameFactory32(cfg.disputeGameFactory());

            assertTrue(cfg.isFeatureEnabled(ETH_LOCKBOX));
            assertFalse(cfg.isFeatureEnabled(INTEROP));
            assertEq(portal.ethLockbox(), lockboxes[i]);
            assertEq(portal.anchorStateRegistry(), registries[i]);
            assertEq(lockbox.superchainConfig(), cfg.superchainConfig());
            assertEq(cfg.superchainConfig(), SUPERCHAIN_CONFIG);
            assertEq(registry.ethLockbox(), lockboxes[i]);
            assertEq(weth.ethLockbox(), lockboxes[i]);
            assertTrue(lockbox.authorizedPortals(portals[i]));
            assertFalse(portal.paused());
            assertFalse(lockbox.paused());
            assertEq(IProxyAdminOwned32(portals[i]).proxyAdminOwner(), IProxyAdminOwned32(lockboxes[i]).proxyAdminOwner());
            assertEq(IProxyAdminOwned32(registries[i]).proxyAdminOwner(), IProxyAdminOwned32(lockboxes[i]).proxyAdminOwner());

            uint32 respected = registry.respectedGameType();
            assertTrue(factory.gameImpls(respected) != address(0));
            if (respected != 5) assertGt(factory.initBonds(respected), 0);
        }
    }

    function test_siblingValuePaths_unauthorizedLockAndReceiveRevert_butDonateSucceeds() external {
        vm.deal(address(this), 3 wei);
        vm.expectRevert(bytes4(keccak256("ETHLockbox_Unauthorized()")));
        ILockbox32(LOCKBOX).lockETH{ value: 1 wei }();
        vm.expectRevert(bytes4(keccak256("ETHLockbox_Unauthorized()")));
        ILockbox32(LOCKBOX).receiveLiquidity{ value: 1 wei }();

        uint256 portalBefore = PORTAL.balance;
        uint256 lockboxBefore = LOCKBOX.balance;
        IPortal32(PORTAL).donateETH{ value: 1 wei }();
        assertEq(PORTAL.balance, portalBefore + 1 wei);
        assertEq(LOCKBOX.balance, lockboxBefore);
    }

    function test_validatorZeroBalanceCanBeInvalidatedAfterValidationByForceSend() external {
        vm.deal(address(this), 1 wei);
        uint256 beforeBalance = PORTAL.balance;
        new ForceSend32{ value: 1 wei }(payable(PORTAL));
        // The CREATE address may itself carry fork-state dust, all of which is transferred.
        assertGt(PORTAL.balance, beforeBalance);
    }

    function test_lockboxAdministrativeSiblingsRemainProxyAdminOwnerOnly() external {
        bytes4 denied = bytes4(keccak256("ProxyAdminOwnedBase_NotProxyAdminOwner()"));
        vm.expectRevert(denied);
        ILockbox32(LOCKBOX).authorizePortal(address(this));
        vm.expectRevert(denied);
        ILockbox32(LOCKBOX).authorizeLockbox(address(this));
        vm.expectRevert(bytes4(keccak256("ETHLockbox_Unauthorized()")));
        ILockbox32(LOCKBOX).unlockETH(1);
        vm.expectRevert(denied);
        IPortal32(PORTAL).migrateLiquidity();
    }

    function test_migrateToSharedDisputeGame_featureGateRunsBeforeAuthorization() external {
        vm.expectRevert(bytes4(keccak256("OptimismPortal_NotUsingInterop()")));
        IPortal32(PORTAL).migrateToSharedDisputeGame(LOCKBOX, ASR);
    }

    function test_configurationValidatorsCannotBeViolatedPermissionlessly() external {
        vm.expectRevert(bytes4(keccak256("ProxyAdminOwnedBase_NotProxyAdminOrProxyAdminOwner()")));
        ISystemConfig32(SYSCFG).setFeature(INTEROP, true);
        vm.expectRevert(bytes4(keccak256("AnchorStateRegistry_Unauthorized()")));
        IAnchorStateRegistry32(ASR).setRespectedGameType(5);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        IDisputeGameFactory32(DGF).setInitBond(9, 0);
    }

    function test_deleteProvenWithdrawal_rejectsLiveNonInvalidatedHistoricalObject() external {
        bytes32 withdrawalHash = 0x76313a38c7aca313f8a180125773dff4981c9f4f9bf81e134a894444412e6b59;
        address submitter = 0x5f7f3E256AB61566dB3A8047B4405A52aa3517b2;
        (address game, uint64 timestamp) = IPortal32(PORTAL).provenWithdrawals(withdrawalHash, submitter);
        assertTrue(game != address(0));
        assertGt(timestamp, 0);
        assertEq(IGame32(game).status(), 0); // IN_PROGRESS
        assertFalse(IAnchorStateRegistry32(ASR).isGameBlacklisted(game));
        vm.expectRevert(bytes4(keccak256("OptimismPortal_DisputeGameNotInvalidated()")));
        IPortal32(PORTAL).deleteProvenWithdrawal(withdrawalHash, submitter);
    }

    function test_liveL1AndL2MessengerGasBudgetsExposeAsymmetricUpgrade() external {
        IMessenger32 l1Messenger = IMessenger32(L1_MESSENGER);
        assertEq(l1Messenger.RELAY_CONSTANT_OVERHEAD(), 200_000);
        assertEq(l1Messenger.RELAY_CALL_OVERHEAD(), 40_000);
        assertEq(l1Messenger.RELAY_RESERVED_GAS(), 40_000); // remote L2 budget
        assertEq(l1Messenger.RELAY_GAS_CHECK_BUFFER(), 5_000); // remote L2 budget
        assertGt(l1Messenger.baseGas(bytes(""), 0), 0);

        vm.createSelectFork("l2");
        IMessenger32 l2Messenger = IMessenger32(L2_MESSENGER);
        assertEq(l2Messenger.RELAY_CONSTANT_OVERHEAD(), 200_000);
        assertEq(l2Messenger.RELAY_CALL_OVERHEAD(), 40_000);
        assertEq(l2Messenger.RELAY_RESERVED_GAS(), 40_000);
        assertEq(l2Messenger.RELAY_GAS_CHECK_BUFFER(), 5_000);
        assertGt(l2Messenger.baseGas(bytes(""), 0), 0);
        assertTrue(keccak256(bytes(l2Messenger.version())) != keccak256(bytes("2.4.0")));
    }
}
