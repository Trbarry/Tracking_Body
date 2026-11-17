// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

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

interface IPortal {
    function version() external view returns (string memory);
    function ethLockbox() external view returns (address);
    function systemConfig() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function paused() external view returns (bool);
    function l2Sender() external view returns (address);
    function proofMaturityDelaySeconds() external view returns (uint256);
    function provenWithdrawals(bytes32, address) external view returns (address disputeGameProxy, uint64 timestamp);
    function proofSubmitters(bytes32, uint256) external view returns (address);
    function numProofSubmitters(bytes32) external view returns (uint256);
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function deleteProvenWithdrawal(bytes32, address) external;
    function checkWithdrawal(bytes32, address) external view;
    function finalizeWithdrawalTransaction(WithdrawalTransaction calldata) external;
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction calldata, address) external;
    function proveWithdrawalTransaction(
        WithdrawalTransaction calldata _tx,
        uint256 _disputeGameIndex,
        OutputRootProof calldata _outputRootProof,
        bytes[] calldata _withdrawalProof
    ) external;
}

interface IASR {
    function version() external view returns (string memory);
    function respectedGameType() external view returns (uint32);
    function retirementTimestamp() external view returns (uint64);
    function disputeGameFactory() external view returns (address);
    function ethLockbox() external view returns (address);
    function anchorGame() external view returns (address);
    function getAnchorRoot() external view returns (bytes32, uint256);
    function paused() external view returns (bool);
    function isGameRegistered(address) external view returns (bool);
    function isGameProper(address) external view returns (bool);
    function isGameRespected(address) external view returns (bool);
    function isGameRetired(address) external view returns (bool);
    function isGameBlacklisted(address) external view returns (bool);
    function isGameResolved(address) external view returns (bool);
    function isGameFinalized(address) external view returns (bool);
    function isGameClaimValid(address) external view returns (bool);
    function blacklistDisputeGame(address) external;
    function updateRetirementTimestamp() external;
    function setRespectedGameType(uint32) external;
    function disputeGameFinalityDelaySeconds() external view returns (uint256);
}

interface IDGF {
    function gameCount() external view returns (uint256);
    function gameAtIndex(uint256) external view returns (uint32 gameType, uint64 timestamp, address proxy);
    function games(uint32, bytes32, bytes calldata) external view returns (address proxy, uint64 timestamp);
    function gameImpls(uint32) external view returns (address);
    function initBonds(uint32) external view returns (uint256);
    function create(uint32, bytes32, bytes calldata) external payable returns (address);
}

interface IGame {
    function version() external view returns (string memory);
    function status() external view returns (uint8);
    function createdAt() external view returns (uint64);
    function resolvedAt() external view returns (uint64);
    function gameType() external view returns (uint32);
    function rootClaim() external view returns (bytes32);
    function rootClaimByChainId(uint256) external view returns (bytes32);
    function extraData() external view returns (bytes memory);
    function l2SequenceNumber() external view returns (uint256);
    function wasRespectedGameTypeWhenCreated() external view returns (bool);
    function gameCreator() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function maxClockDuration() external view returns (uint64);
    function claimDataLen() external view returns (uint256);
    function claimData(uint256)
        external
        view
        returns (uint32 parentIndex, address counteredBy, address claimant, uint128 bond, bytes32 claim, uint128 position, uint128 clock);
    function getRequiredBond(uint128) external view returns (uint256);
    function attack(bytes32 _disputed, uint256 _parentIndex, bytes32 _claim) external payable;
    function resolveClaim(uint256, uint256) external;
    function resolve() external returns (uint8);
    function closeGame() external;
    function bondDistributionMode() external view returns (uint8);
    function splitDepth() external view returns (uint256);
    function maxGameDepth() external view returns (uint256);
    function startingSequenceNumber() external view returns (uint256);
}

interface ISuperchainConfig {
    function guardian() external view returns (address);
    function pause(address) external;
    function unpause(address) external;
    function paused(address) external view returns (bool);
}

interface ILockbox {
    function paused() external view returns (bool);
    function guardian() external view returns (address);
    function superchainConfig() external view returns (address);
    function authorizedPortals(address) external view returns (bool);
}
