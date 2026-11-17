// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";

struct ExtraInstruction {
    string key;
    bytes data;
}

struct GameConfig {
    bool enabled;
    uint256 initBond;
    uint32 gameType;
    bytes gameArgs;
}

struct UpgradeInput {
    address systemConfig;
    GameConfig[] disputeGameConfigs;
    ExtraInstruction[] extraInstructions;
}

struct SuperchainUpgradeInput {
    address superchainConfig;
    ExtraInstruction[] extraInstructions;
}

struct ProxyDeployArgs {
    address proxyAdmin;
    address addressManager;
    uint256 l2ChainId;
    string saltMixer;
}

struct Proposal {
    bytes32 root;
    uint256 l2SequenceNumber;
}

struct MigrateInput {
    address[] chainSystemConfigs;
    GameConfig[] disputeGameConfigs;
    Proposal startingAnchorRoot;
    uint32 startingRespectedGameType;
}

interface IOPCM {
    error OPContractsManagerV2_OnlyDelegateCall();

    function upgradeSuperchain(SuperchainUpgradeInput calldata input) external;
    function upgrade(UpgradeInput calldata input) external;
    function migrate(MigrateInput calldata input) external;
}

interface IOPCMMigrator {
    function migrate(MigrateInput calldata input) external;
}

interface IProxyAdmin {
    function getProxyImplementation(address payable proxy) external view returns (address);
    function upgrade(address payable proxy, address implementation) external;
}

interface IOPCMUtils {
    function loadOrDeployProxy(
        address source,
        bytes4 selector,
        ProxyDeployArgs calldata args,
        string calldata contractName,
        ExtraInstruction[] calldata instructions
    ) external returns (address payable);

    function upgrade(
        address proxyAdmin,
        address target,
        address implementation,
        bytes calldata data,
        bytes32 slot,
        uint8 offset
    ) external;
}

interface IStorageSetter {
    function setBytes32(bytes32 slot, bytes32 value) external;
}

contract U21ExecutionGuardsTest is Test {
    address internal constant OPCM = 0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f;
    address internal constant OPCM_UTILS = 0xE1EA0F70fDA205fDfeEc770A259e4C34C0f7c4c6;
    address internal constant OPCM_MIGRATOR = 0x5B42AB3d7CB6c6dA53b3d5C148Ff34CD998afAC0;
    address internal constant PROXY_ADMIN = 0x543bA4AADBAb8f9025686Bd03993043599c6fB04;
    address internal constant ADDRESS_MANAGER = 0xdE1FCfB0851916CA5101820A69b13a4E276bd81F;
    address internal constant SUPERCHAIN_CONFIG = 0x95703e0982140D16f8ebA6d158FccEde42f04a4C;
    address internal constant SYSTEM_CONFIG = 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290;
    address internal constant SUPERCHAIN_IMPL = 0xA303a644cfbC0c34f6a9dBEaFdebA4C967EA01e7;
    address internal constant STORAGE_SETTER = 0x2476c911E6D4D9411E677D8Faf15a64ac1fDEEe8;
    address internal constant GUARDIAN = 0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2;
    bytes32 internal constant EIP1967_ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    function setUp() public {
        vm.createSelectFork("l1n");
    }

    function test_directCallsToStateMutatingOPCMEntryPointsRevert() public {
        ExtraInstruction[] memory instructions = new ExtraInstruction[](0);
        GameConfig[] memory games = new GameConfig[](0);

        vm.expectRevert(IOPCM.OPContractsManagerV2_OnlyDelegateCall.selector);
        IOPCM(OPCM).upgradeSuperchain(SuperchainUpgradeInput(SUPERCHAIN_CONFIG, instructions));

        vm.expectRevert(IOPCM.OPContractsManagerV2_OnlyDelegateCall.selector);
        IOPCM(OPCM).upgrade(UpgradeInput(SYSTEM_CONFIG, games, instructions));

        address[] memory systems = new address[](0);
        vm.expectRevert(IOPCM.OPContractsManagerV2_OnlyDelegateCall.selector);
        IOPCM(OPCM).migrate(MigrateInput(systems, games, Proposal(bytes32(0), 0), 0));
    }

    function test_directProxyAdminAndUtilsCallsCannotUpgradeRealProxy() public {
        address beforeImpl = IProxyAdmin(PROXY_ADMIN).getProxyImplementation(payable(SUPERCHAIN_CONFIG));
        assertEq(beforeImpl, SUPERCHAIN_IMPL);

        (bool adminOk,) = PROXY_ADMIN.call(
            abi.encodeCall(IProxyAdmin.upgrade, (payable(SUPERCHAIN_CONFIG), STORAGE_SETTER))
        );
        assertFalse(adminOk, "non-owner unexpectedly upgraded through ProxyAdmin");
        assertEq(IProxyAdmin(PROXY_ADMIN).getProxyImplementation(payable(SUPERCHAIN_CONFIG)), beforeImpl);

        (bool utilsOk,) = OPCM_UTILS.call(
            abi.encodeCall(
                IOPCMUtils.upgrade,
                (
                    PROXY_ADMIN,
                    SUPERCHAIN_CONFIG,
                    SUPERCHAIN_IMPL,
                    abi.encodeWithSignature("initialize(address)", GUARDIAN),
                    bytes32(0),
                    uint8(0)
                )
            )
        );
        assertFalse(utilsOk, "direct Utils call unexpectedly gained ProxyAdmin authority");
        assertEq(IProxyAdmin(PROXY_ADMIN).getProxyImplementation(payable(SUPERCHAIN_CONFIG)), beforeImpl);
    }

    function test_directMigratorCallCannotUseRealProxyAdminAuthority() public {
        address[] memory systems = new address[](1);
        systems[0] = SYSTEM_CONFIG;
        GameConfig[] memory games = new GameConfig[](1);
        games[0] = GameConfig({
            enabled: true,
            initBond: 0,
            gameType: 5,
            gameArgs: abi.encode(address(0xBEEF))
        });
        MigrateInput memory input = MigrateInput({
            chainSystemConfigs: systems,
            disputeGameConfigs: games,
            startingAnchorRoot: Proposal(bytes32(uint256(1)), 0),
            startingRespectedGameType: 5
        });
        address beforeImpl = IProxyAdmin(PROXY_ADMIN).getProxyImplementation(payable(SYSTEM_CONFIG));

        (bool ok,) = OPCM_MIGRATOR.call(abi.encodeCall(IOPCMMigrator.migrate, (input)));

        assertFalse(ok, "direct Migrator call unexpectedly used Safe authority");
        assertEq(IProxyAdmin(PROXY_ADMIN).getProxyImplementation(payable(SYSTEM_CONFIG)), beforeImpl);
    }

    function test_proxyAndImplementationInitializersAreNotReRunnable() public {
        bytes memory initialize = abi.encodeWithSignature("initialize(address)", address(this));

        (bool proxyOk,) = SUPERCHAIN_CONFIG.call(initialize);
        assertFalse(proxyOk, "proxy initializer was re-runnable");

        (bool implementationOk,) = SUPERCHAIN_IMPL.call(initialize);
        assertFalse(implementationOk, "implementation singleton was initializable");
    }

    function test_directStorageSetterCallWritesOnlySingletonStorage() public {
        bytes32 slot = keccak256("lane-21-isolation-check");
        bytes32 beforeProxy = vm.load(SUPERCHAIN_CONFIG, slot);
        IStorageSetter(STORAGE_SETTER).setBytes32(slot, bytes32(uint256(21)));

        assertEq(vm.load(STORAGE_SETTER, slot), bytes32(uint256(21)));
        assertEq(vm.load(SUPERCHAIN_CONFIG, slot), beforeProxy);
    }

    function test_utilsCanPermissionlesslyOccupyPredictedNormalProxySalt() public {
        ExtraInstruction[] memory instructions = new ExtraInstruction[](1);
        instructions[0] = ExtraInstruction({
            key: "PermittedProxyDeployment",
            data: bytes("ETHLockbox")
        });
        ProxyDeployArgs memory args = ProxyDeployArgs({
            proxyAdmin: PROXY_ADMIN,
            addressManager: ADDRESS_MANAGER,
            l2ChainId: block.timestamp,
            saltMixer: "interop salt mixer"
        });

        address proxy = IOPCMUtils(OPCM_UTILS).loadOrDeployProxy(
            address(0), bytes4(0), args, "ETHLockbox", instructions
        );
        assertGt(proxy.code.length, 0);
        assertEq(address(uint160(uint256(vm.load(proxy, EIP1967_ADMIN_SLOT)))), PROXY_ADMIN);

        vm.expectRevert();
        IOPCMUtils(OPCM_UTILS).loadOrDeployProxy(
            address(0), bytes4(0), args, "ETHLockbox", instructions
        );
    }
}
