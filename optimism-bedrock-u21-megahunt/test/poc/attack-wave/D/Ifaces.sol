// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

struct WithdrawalTransaction { uint256 nonce; address sender; address target; uint256 value; uint256 gasLimit; bytes data; }
struct OutputRootProof { bytes32 version; bytes32 stateRoot; bytes32 messagePasserStorageRoot; bytes32 latestBlockhash; }
struct GameSearchResult { uint256 index; bytes32 metadata; uint64 timestamp; bytes32 rootClaim; bytes extraData; }

interface IPortal {
    function provenWithdrawals(bytes32, address) external view returns (address disputeGameProxy, uint64 timestamp);
    function numProofSubmitters(bytes32) external view returns (uint256);
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function deleteProvenWithdrawal(bytes32, address) external;
    function checkWithdrawal(bytes32, address) external view;
    function finalizeWithdrawalTransaction(WithdrawalTransaction calldata) external;
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction calldata, address) external;
    function proveWithdrawalTransaction(WithdrawalTransaction calldata, uint256, OutputRootProof calldata, bytes[] calldata) external;
    function respectedGameType() external view returns (uint32);
    function proofMaturityDelaySeconds() external view returns (uint256);
}
interface IASR {
    function isGameProper(address) external view returns (bool);
    function isGameRespected(address) external view returns (bool);
    function isGameFinalized(address) external view returns (bool);
    function isGameClaimValid(address) external view returns (bool);
    function disputeGameFinalityDelaySeconds() external view returns (uint256);
    function getAnchorRoot() external view returns (bytes32, uint256);
}
interface IDGF {
    function gameCount() external view returns (uint256);
    function gameAtIndex(uint256) external view returns (uint32 gameType, uint64 timestamp, address proxy);
    function initBonds(uint32) external view returns (uint256);
    function create(uint32, bytes32, bytes calldata) external payable returns (address);
    function findLatestGames(uint32, uint256, uint256) external view returns (GameSearchResult[] memory);
}
interface IGame {
    function status() external view returns (uint8);
    function createdAt() external view returns (uint64);
    function resolvedAt() external view returns (uint64);
    function rootClaim() external view returns (bytes32);
    function rootClaimByChainId(uint256) external view returns (bytes32);
    function extraData() external view returns (bytes memory);
    function l2SequenceNumber() external view returns (uint256);
    function wasRespectedGameTypeWhenCreated() external view returns (bool);
    function maxClockDuration() external view returns (uint64);
    function claimDataLen() external view returns (uint256);
    function getRequiredBond(uint128) external view returns (uint256);
    function attack(bytes32, uint256, bytes32) external payable;
    function resolveClaim(uint256, uint256) external;
    function resolve() external returns (uint8);
    function claimCredit(address) external;
    function normalModeCredit(address) external view returns (uint256);
    function bondDistributionMode() external view returns (uint8);
    function weth() external view returns (address);
}
interface IDelayedWETH { function delay() external view returns (uint256); }
