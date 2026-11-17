// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Minimal interfaces for the deployed L1 contracts of every era (Bedrock .. U21). Fork tests call
// the real deployed bytecode through these; a getter that does not exist in an era simply reverts
// (use try/catch or the era-aware helpers in InFlightObjects.sol).
// The withdrawal struct and the U21-era interfaces are the PASS A ones (test/poc/U21Fixtures.sol).

struct WithdrawalTransaction {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
}

interface IPortal {
    // ---- all eras ----
    function version() external view returns (string memory);
    function l2Sender() external view returns (address);
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function paused() external view returns (bool);
    function guardian() external view returns (address);
    function depositTransaction(address, uint256, uint64, bool, bytes calldata) external payable;
    function donateETH() external payable;
    function finalizeWithdrawalTransaction(WithdrawalTransaction calldata) external;
    function minimumGasLimit(uint64) external view returns (uint64);
    function params() external view returns (uint128 prevBaseFee, uint64 prevBoughtGas, uint64 prevBlockNum);
    // ---- fault-proof portal (OptimismPortal2, from v1.4.0 / block 20062696) ----
    function provenWithdrawals(bytes32, address) external view returns (address game, uint64 timestamp);
    function proofSubmitters(bytes32, uint256) external view returns (address);
    function numProofSubmitters(bytes32) external view returns (uint256);
    function proofMaturityDelaySeconds() external view returns (uint256);
    function disputeGameFinalityDelaySeconds() external view returns (uint256);
    function respectedGameType() external view returns (uint32);
    function respectedGameTypeUpdatedAt() external view returns (uint64);
    function disputeGameFactory() external view returns (address);
    function disputeGameBlacklist(address) external view returns (bool);
    function checkWithdrawal(bytes32, address) external view;
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction calldata, address) external;
    // ---- later eras ----
    function systemConfig() external view returns (address);
    function superchainConfig() external view returns (address);
    function anchorStateRegistry() external view returns (address); // from U16 (v4.0.0)
    function ethLockbox() external view returns (address); // from U16 (v4.0.0)
    function migrateLiquidity() external; // U16 only path
    function deleteProvenWithdrawal(bytes32, address) external; // v9 only
}

/// @dev Bedrock-era portal (L2OutputOracle model, block 17423158 .. 20062695): the proven mapping
///      is keyed by the withdrawal hash only and the same getter name has a different ABI.
interface IPortalLegacy {
    function provenWithdrawals(bytes32) external view returns (bytes32 outputRoot, uint128 timestamp, uint128 l2OutputIndex);
    function isOutputFinalized(uint256) external view returns (bool);
    function L2_ORACLE() external view returns (address);
    function l2Oracle() external view returns (address);
}

interface IL2OutputOracle {
    function FINALIZATION_PERIOD_SECONDS() external view returns (uint256);
    function finalizationPeriodSeconds() external view returns (uint256);
    function latestOutputIndex() external view returns (uint256);
    function getL2Output(uint256) external view returns (bytes32 outputRoot, uint128 timestamp, uint128 l2BlockNumber);
}

interface ILockbox {
    function version() external view returns (string memory);
    function paused() external view returns (bool);
    function authorizedPortals(address) external view returns (bool);
    function authorizedLockboxes(address) external view returns (bool);
    function lockETH() external payable;
    function unlockETH(uint256) external;
    function systemConfig() external view returns (address);
    function superchainConfig() external view returns (address);
}

interface IMessenger {
    function version() external view returns (string memory);
    function successfulMessages(bytes32) external view returns (bool);
    function failedMessages(bytes32) external view returns (bool);
    function xDomainMessageSender() external view returns (address);
    function paused() external view returns (bool);
    function baseGas(bytes calldata, uint32) external view returns (uint64);
    function messageNonce() external view returns (uint256);
    function relayMessage(uint256, address, address, uint256, uint256, bytes calldata) external payable;
    function sendMessage(address, bytes calldata, uint32) external payable;
    function portal() external view returns (address);
}

interface IBridge {
    function version() external view returns (string memory);
    function depositETH(uint32, bytes calldata) external payable;
    function bridgeETHTo(address, uint32, bytes calldata) external payable;
    function deposits(address, address) external view returns (uint256);
}

interface IASR {
    function version() external view returns (string memory);
    function isGameProper(address) external view returns (bool);
    function isGameRespected(address) external view returns (bool);
    function isGameResolved(address) external view returns (bool);
    function isGameFinalized(address) external view returns (bool);
    function isGameClaimValid(address) external view returns (bool);
    function isGameBlacklisted(address) external view returns (bool);
    function isGameRetired(address) external view returns (bool);
    function paused() external view returns (bool);
    function respectedGameType() external view returns (uint32);
    function retirementTimestamp() external view returns (uint64);
    function disputeGameFinalityDelaySeconds() external view returns (uint256);
    function blacklistDisputeGame(address) external;
    function anchorGame() external view returns (address);
    function disputeGameFactory() external view returns (address);
}

interface IDGF {
    function version() external view returns (string memory);
    function gameCount() external view returns (uint256);
    function gameAtIndex(uint256) external view returns (uint32 gameType, uint64 timestamp, address proxy);
    function gameImpls(uint32) external view returns (address);
    function initBonds(uint32) external view returns (uint256);
    function create(uint32 gameType, bytes32 rootClaim, bytes calldata extraData) external payable returns (address);
    function games(uint32 gameType, bytes32 rootClaim, bytes calldata extraData) external view returns (address proxy, uint64 timestamp);
}

interface IGame {
    function version() external view returns (string memory);
    function status() external view returns (uint8); // 0 IN_PROGRESS, 1 CHALLENGER_WINS, 2 DEFENDER_WINS
    function createdAt() external view returns (uint64);
    function resolvedAt() external view returns (uint64);
    function gameType() external view returns (uint32);
    function rootClaim() external view returns (bytes32);
    function extraData() external view returns (bytes memory);
    function l2BlockNumber() external view returns (uint256);
    function l2SequenceNumber() external view returns (uint256);
    function claimDataLen() external view returns (uint256);
    function maxClockDuration() external view returns (uint64);
    function resolvedSubgames(uint256) external view returns (bool);
    function resolveClaim(uint256, uint256) external; // from v1.6.0-era games
    function resolveClaim(uint256) external; // v1.4.0-era games (FaultDisputeGame 1.2.0)
    function resolve() external returns (uint8);
}

interface ISuperchainConfig {
    function version() external view returns (string memory);
    function guardian() external view returns (address);
    function pause(address) external;
    function unpause(address) external;
    function paused(address) external view returns (bool);
    function paused() external view returns (bool);
}

interface ISystemConfig {
    function version() external view returns (string memory);
    function owner() external view returns (address);
    function l2ChainId() external view returns (uint256);
    function optimismPortal() external view returns (address);
    function l1CrossDomainMessenger() external view returns (address);
    function l1StandardBridge() external view returns (address);
    function l1ERC721Bridge() external view returns (address);
    function optimismMintableERC20Factory() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function superchainConfig() external view returns (address);
    function guardian() external view returns (address);
    function paused() external view returns (bool);
    function isFeatureEnabled(bytes32) external view returns (bool);
    function proxyAdmin() external view returns (address);
    function proxyAdminOwner() external view returns (address);
    function batcherHash() external view returns (bytes32);
    function gasLimit() external view returns (uint64);
}

interface IAddressManager {
    function getAddress(string memory) external view returns (address);
    function owner() external view returns (address);
}
