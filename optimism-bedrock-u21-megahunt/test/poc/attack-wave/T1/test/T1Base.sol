// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

// ATK-T1 (attack wave, resume, Opus 5.5): FIX-REGRESSION lane. Shared handles for the four chains.
// Deployed bytecode only. L1 fork = shared read-only anvil :8545 pinned at 26433900 (forge forks it
// in-process; nothing is ever sent to the shared anvil).

struct WT {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
}

struct ORP {
    bytes32 version;
    bytes32 stateRoot;
    bytes32 messagePasserStorageRoot;
    bytes32 latestBlockhash;
}

interface IPortal {
    function proveWithdrawalTransaction(WT memory _tx, uint256 _idx, ORP calldata _orp, bytes[] calldata _proof) external;
    function finalizeWithdrawalTransactionExternalProof(WT memory _tx, address _proofSubmitter) external;
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function provenWithdrawals(bytes32, address) external view returns (address game, uint64 ts);
    function deleteProvenWithdrawal(bytes32, address) external;
    function checkWithdrawal(bytes32, address) external view;
    function numProofSubmitters(bytes32) external view returns (uint256);
    function ethLockbox() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function systemConfig() external view returns (address);
    function paused() external view returns (bool);
    function l2Sender() external view returns (address);
    function version() external view returns (string memory);
    function proofMaturityDelaySeconds() external view returns (uint256);
    function depositTransaction(address, uint256, uint64, bool, bytes memory) external payable;
}

interface IASR {
    function anchorGame() external view returns (address);
    function isGameClaimValid(address) external view returns (bool);
    function isGameProper(address) external view returns (bool);
    function isGameRegistered(address) external view returns (bool);
    function isGameRetired(address) external view returns (bool);
    function isGameBlacklisted(address) external view returns (bool);
    function isGameFinalized(address) external view returns (bool);
    function respectedGameType() external view returns (uint32);
    function retirementTimestamp() external view returns (uint64);
    function disputeGameFactory() external view returns (address);
    function ethLockbox() external view returns (address);
    function getAnchorRoot() external view returns (bytes32, uint256);
    function setAnchorState(address) external;
    function paused() external view returns (bool);
    function disputeGameFinalityDelaySeconds() external view returns (uint256);
}

interface IDGF {
    function gameImpls(uint32) external view returns (address);
    function gameArgs(uint32) external view returns (bytes memory);
    function initBonds(uint32) external view returns (uint256);
    function create(uint32, bytes32, bytes calldata) external payable returns (address);
    function gameCount() external view returns (uint256);
    function gameAtIndex(uint256) external view returns (uint32, uint64, address);
}

interface IGame {
    function createdAt() external view returns (uint64);
    function resolvedAt() external view returns (uint64);
    function status() external view returns (uint8);
    function gameType() external view returns (uint32);
    function rootClaim() external view returns (bytes32);
    function rootClaimByChainId(uint256) external view returns (bytes32);
    function l2SequenceNumber() external view returns (uint256);
    function anchorStateRegistry() external view returns (address);
    function weth() external view returns (address);
    function wasRespectedGameTypeWhenCreated() external view returns (bool);
    function gameCreator() external view returns (address);
    function extraData() external view returns (bytes memory);
    function resolveClaim(uint256, uint256) external;
    function resolve() external returns (uint8);
    function closeGame() external;
    function bondDistributionMode() external view returns (uint8);
    function claimDataLen() external view returns (uint256);
    function maxClockDuration() external view returns (uint64);
    function getChallengerDuration(uint256) external view returns (uint64);
    function proposer() external view returns (address);
    function absolutePrestate() external view returns (bytes32);
}

interface ISysCfg {
    function l2ChainId() external view returns (uint256);
    function optimismPortal() external view returns (address);
    function l1CrossDomainMessenger() external view returns (address);
    function l1StandardBridge() external view returns (address);
    function l1ERC721Bridge() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function delayedWETH() external view returns (address);
    function superchainConfig() external view returns (address);
    function paused() external view returns (bool);
}

interface IHasSysCfg {
    function systemConfig() external view returns (address);
    function paused() external view returns (bool);
    function superchainConfig() external view returns (address);
}

interface ILockbox {
    function superchainConfig() external view returns (address);
    function paused() external view returns (bool);
    function authorizedPortals(address) external view returns (bool);
}

abstract contract T1Base is Test {
    string[4] names = ["OP", "Ink", "Soneium", "Unichain"];
    uint256[4] chainIds = [uint256(10), 57073, 1868, 130];
    address[4] portal;
    address[4] lockbox;
    address[4] asr;
    address[4] sysCfg;
    address[4] dgf;
    address[4] l1cdm;

    address attacker = makeAddr("t1-attacker");

    function _load() internal {
        portal = [0xbEb5Fc579115071764c7423A4f12eDde41f106Ed, 0x5d66C1782664115999C47c9fA5cd031f495D3e4F, 0x88e529A6ccd302c948689Cd5156C83D4614FAE92, 0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2];
        lockbox = [0x322b47Ff1FA8D5611F761e3E275C45B71b294D43, 0xbd4AbB321138e8Eddc399cE64E66451294325a14, 0x67B4de6FfA66EF201Ea6099A89cA397D56622E31, 0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5];
        asr = [0x23B2C62946350F4246f9f9D027e071f0264FD113, 0xEe018bAf058227872540AC60eFbd38b023d9dAe2, 0x4890928941e62e273dA359374b105F803329F473, 0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9];
        sysCfg = [0x229047fed2591dbec1eF1118d64F7aF3dB9EB290, 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364, 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3, 0xc407398d063f942feBbcC6F80a156b47F3f1BDA6];
        dgf = [0xe5965Ab5962eDc7477C8520243A95517CD252fA9, 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD, 0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0, 0x2F12d621a16e2d3285929C9996f478508951dFe4];
        l1cdm = [0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1, 0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f, 0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f, 0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6];
    }

    function _hash(WT memory w) internal pure returns (bytes32) {
        return keccak256(abi.encode(w.nonce, w.sender, w.target, w.value, w.gasLimit, w.data));
    }

    /// Super root proof encoding (v9 Encoding.encodeSuperRootProof): 0x01 | uint64 ts | (chainId, root)*.
    function _superProof(uint64 ts, uint256 chainId, bytes32 root) internal pure returns (bytes memory) {
        return bytes.concat(bytes1(0x01), bytes8(ts), bytes32(chainId), root);
    }

    function _try(address t, bytes memory d) internal view returns (bool ok, bytes memory out) {
        (ok, out) = t.staticcall(d);
    }
}
