// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Test.sol";

interface ILockbox {
    function version() external view returns (string memory);
    function authorizedPortals(address) external view returns (bool);
    function authorizedLockboxes(address) external view returns (bool);
    function superchainConfig() external view returns (address);
    function paused() external view returns (bool);
    function proxyAdmin() external view returns (address);
    function proxyAdminOwner() external view returns (address);
    function lockETH() external payable;
    function unlockETH(uint256) external;
    function receiveLiquidity() external payable;
    function migrateLiquidity(address) external;
    function authorizePortal(address) external;
    function authorizeLockbox(address) external;
}

interface IPortal {
    function version() external view returns (string memory);
    function ethLockbox() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function systemConfig() external view returns (address);
    function paused() external view returns (bool);
    function l2Sender() external view returns (address);
    function donateETH() external payable;
    function depositTransaction(address, uint256, uint64, bool, bytes memory) external payable;
    function migrateLiquidity() external;
}

interface ISysCfg {
    function isFeatureEnabled(bytes32) external view returns (bool);
    function paused() external view returns (bool);
    function delayedWETH() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function superchainConfig() external view returns (address);
}

interface IASR {
    function ethLockbox() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function respectedGameType() external view returns (uint32);
    function retirementTimestamp() external view returns (uint64);
    function anchorGame() external view returns (address);
    function paused() external view returns (bool);
}

interface IDGF {
    function gameImpls(uint32) external view returns (address);
    function initBonds(uint32) external view returns (uint256);
    function owner() external view returns (address);
    function gameCount() external view returns (uint256);
}

interface IDWETH {
    function ethLockbox() external view returns (address);
}

struct DisputeGameConfig {
    bool enabled;
    uint256 initBond;
    uint32 gameType;
    bytes gameArgs;
}

struct Proposal {
    bytes32 root;
    uint256 l2SequenceNumber;
}

struct MigrateInput {
    address[] chainSystemConfigs;
    DisputeGameConfig[] disputeGameConfigs;
    Proposal startingAnchorRoot;
    uint32 startingRespectedGameType;
}

interface IOPCM {
    function migrate(MigrateInput calldata) external;
}

abstract contract Lane09Base is Test {
    address constant SAFE = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address constant OPCM = 0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f;

    IPortal constant OP_PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    IPortal constant UNI_PORTAL = IPortal(0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2);
    ILockbox constant OP_LB = ILockbox(0x322b47Ff1FA8D5611F761e3E275C45B71b294D43);
    ILockbox constant UNI_LB = ILockbox(0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5);
    ISysCfg constant OP_SC = ISysCfg(0x229047fed2591dbec1eF1118d64F7aF3dB9EB290);
    ISysCfg constant UNI_SC = ISysCfg(0xc407398d063f942feBbcC6F80a156b47F3f1BDA6);
    IASR constant OP_ASR = IASR(0x23B2C62946350F4246f9f9D027e071f0264FD113);
    IASR constant UNI_ASR = IASR(0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9);
    address constant DEFAULT_L2_SENDER = 0x000000000000000000000000000000000000dEaD;

    ILockbox sharedLB;
    IASR sharedASR;
    IDGF sharedDGF;

    /// @dev Executes the PLANNED, documented governance action OPContractsManagerV2.migrate for
    ///      OP Mainnet (10) + Unichain (130) exactly as the ProxyAdmin-owner Safe would
    ///      (DELEGATECALL into the deployed OPCM). This is setup of a documented future state.
    function _migrate() internal {
        address[] memory scs = new address[](2);
        scs[0] = address(OP_SC);
        scs[1] = address(UNI_SC);
        DisputeGameConfig[] memory gcs = new DisputeGameConfig[](1);
        gcs[0] = DisputeGameConfig({
            enabled: true,
            initBond: 0.08 ether,
            gameType: 9,
            gameArgs: abi.encode(bytes32(0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9))
        });
        MigrateInput memory input = MigrateInput({
            chainSystemConfigs: scs,
            disputeGameConfigs: gcs,
            startingAnchorRoot: Proposal({ root: keccak256("lane09-starting-super-root"), l2SequenceNumber: block.timestamp - 1 }),
            startingRespectedGameType: 9
        });
        vm.prank(SAFE, true);
        (bool ok, bytes memory ret) = OPCM.delegatecall(abi.encodeCall(IOPCM.migrate, (input)));
        if (!ok) {
            assembly {
                revert(add(ret, 0x20), mload(ret))
            }
        }
        sharedLB = ILockbox(OP_PORTAL.ethLockbox());
        sharedASR = IASR(OP_PORTAL.anchorStateRegistry());
        sharedDGF = IDGF(sharedASR.disputeGameFactory());
    }
}

contract Lane09MigrateTest is Lane09Base {
    function setUp() public {
        vm.createSelectFork("l1");
    }

    function test_migrate_op_unichain_realState() public {
        uint256 opBal = address(OP_LB).balance;
        uint256 uniBal = address(UNI_LB).balance;
        emit log_named_decimal_uint("pre OP lockbox", opBal, 18);
        emit log_named_decimal_uint("pre UNI lockbox", uniBal, 18);

        _migrate();

        emit log_named_address("shared lockbox", address(sharedLB));
        emit log_named_address("shared ASR", address(sharedASR));
        emit log_named_address("shared DGF", address(sharedDGF));
        emit log_named_decimal_uint("shared lockbox balance", address(sharedLB).balance, 18);
        assertEq(address(sharedLB).balance, opBal + uniBal, "conservation");
        assertEq(UNI_PORTAL.ethLockbox(), address(sharedLB));
        assertEq(UNI_PORTAL.anchorStateRegistry(), address(sharedASR));
        assertEq(address(OP_LB).balance, 0);
        assertEq(address(UNI_LB).balance, 0);

        // persisting authorizations
        emit log_named_uint("oldOP.authorizedPortals[opPortal]", OP_LB.authorizedPortals(address(OP_PORTAL)) ? 1 : 0);
        emit log_named_uint("oldUNI.authorizedPortals[uniPortal]", UNI_LB.authorizedPortals(address(UNI_PORTAL)) ? 1 : 0);
        emit log_named_uint("shared.authorizedPortals[op]", sharedLB.authorizedPortals(address(OP_PORTAL)) ? 1 : 0);
        emit log_named_uint("shared.authorizedPortals[uni]", sharedLB.authorizedPortals(address(UNI_PORTAL)) ? 1 : 0);
        emit log_named_uint("shared.authorizedLockboxes[oldOP]", sharedLB.authorizedLockboxes(address(OP_LB)) ? 1 : 0);
        emit log_named_uint("shared.authorizedLockboxes[oldUNI]", sharedLB.authorizedLockboxes(address(UNI_LB)) ? 1 : 0);
        emit log_named_address("shared.proxyAdmin", sharedLB.proxyAdmin());
        emit log_named_address("shared.superchainConfig", sharedLB.superchainConfig());

        // old ASR / DelayedWETH repointing
        emit log_named_address("old OP ASR lockbox", OP_ASR.ethLockbox());
        emit log_named_address("old UNI ASR lockbox", UNI_ASR.ethLockbox());
        emit log_named_address("OP SC delayedWETH", OP_SC.delayedWETH());
        emit log_named_address("UNI SC delayedWETH", UNI_SC.delayedWETH());
        emit log_named_address("OP SC dgf", OP_SC.disputeGameFactory());
        emit log_named_address("UNI SC dgf", UNI_SC.disputeGameFactory());
        emit log_named_address("old UNI DWETH lockbox", IDWETH(0x74ad145aC900F1DD5551F0C9E143314DC4022FCf).ethLockbox());
        emit log_named_uint("old OP DGF impl(9)", uint160(IDGF(0xe5965Ab5962eDc7477C8520243A95517CD252fA9).gameImpls(9)));
        emit log_named_uint("old OP DGF impl(5)", uint160(IDGF(0xe5965Ab5962eDc7477C8520243A95517CD252fA9).gameImpls(5)));
        emit log_named_uint("shared DGF impl(9)", uint160(sharedDGF.gameImpls(9)));
        emit log_named_uint("old OP ASR retirement", OP_ASR.retirementTimestamp());
        emit log_named_address("old OP ASR anchorGame", OP_ASR.anchorGame());
        emit log_named_uint("shared ASR retirement", sharedASR.retirementTimestamp());
        emit log_named_uint("INTEROP op", OP_SC.isFeatureEnabled("INTEROP") ? 1 : 0);
    }
}
