// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

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

interface IPortal {
    function proveWithdrawalTransaction(
        WithdrawalTransaction calldata _tx,
        uint256 _disputeGameIndex,
        OutputRootProof calldata _outputRootProof,
        bytes[] calldata _withdrawalProof
    ) external;
    function finalizeWithdrawalTransaction(WithdrawalTransaction calldata _tx) external;
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction calldata _tx, address _proofSubmitter) external;
    function checkWithdrawal(bytes32 _withdrawalHash, address _proofSubmitter) external view;
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function provenWithdrawals(bytes32, address) external view returns (address game, uint64 timestamp);
    function l2Sender() external view returns (address);
    function paused() external view returns (bool);
    function version() external view returns (string memory);
    function ethLockbox() external view returns (address);
}

interface IDGF {
    function create(uint32 _gameType, bytes32 _rootClaim, bytes calldata _extraData) external payable returns (address);
    function gameCount() external view returns (uint256);
    function initBonds(uint32) external view returns (uint256);
    function gameAtIndex(uint256) external view returns (uint32, uint64, address);
}

interface IGame {
    function resolveClaim(uint256 _claimIndex, uint256 _numToResolve) external;
    function resolve() external returns (uint8);
    function status() external view returns (uint8);
    function createdAt() external view returns (uint64);
    function rootClaimByChainId(uint256) external view returns (bytes32);
}

interface ICDM {
    function relayMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _minGasLimit,
        bytes calldata _message
    ) external payable;
    function sendMessage(address _target, bytes calldata _message, uint32 _minGasLimit) external payable;
    function successfulMessages(bytes32) external view returns (bool);
    function failedMessages(bytes32) external view returns (bool);
    function baseGas(bytes calldata _message, uint32 _minGasLimit) external view returns (uint64);
    function xDomainMessageSender() external view returns (address);
    function messageNonce() external view returns (uint256);
    function version() external view returns (string memory);
    function paused() external view returns (bool);
}

abstract contract Base08 is Test {
    IPortal constant portal = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    IDGF constant dgf = IDGF(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);
    ICDM constant l1cdm = ICDM(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);
    address constant L1_BRIDGE = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
    address constant L2_BRIDGE = 0x4200000000000000000000000000000000000010;
    address constant L2CDM = 0x4200000000000000000000000000000000000007;
    address constant LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    uint256 constant L2_CHAIN_ID = 10;

    uint256 internal seq; // fake super timestamp counter
    uint256 internal t0;
    address[] internal games;

    /// Live L2CrossDomainMessenger v2.2.1 baseGas (constants read on-chain from the l2 fork; see LANE-08 report).
    function l2BaseGasLive(uint256 msgLen, uint256 minGasLimit) internal pure returns (uint64) {
        uint256 executionGas = 200_000 + 40_000 + 40_000 + 5_000 + (minGasLimit * 64) / 63;
        uint256 total = msgLen + 260;
        uint256 a = executionGas + total * 16;
        uint256 b = total * 40;
        return uint64(21_000 + (a > b ? a : b));
    }

    function hashWithdrawal(WithdrawalTransaction memory _tx) internal pure returns (bytes32) {
        return keccak256(abi.encode(_tx.nonce, _tx.sender, _tx.target, _tx.value, _tx.gasLimit, _tx.data));
    }

    function v1Nonce(uint256 n) internal pure returns (uint256) {
        return (uint256(1) << 240) | n;
    }

    function relayCalldata(
        uint256 nonce,
        address sender,
        address target,
        uint256 value,
        uint256 minGasLimit,
        bytes memory message
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(ICDM.relayMessage.selector, nonce, sender, target, value, minGasLimit, message);
    }

    function msgHash(
        uint256 nonce,
        address sender,
        address target,
        uint256 value,
        uint256 minGasLimit,
        bytes memory message
    ) internal pure returns (bytes32) {
        return keccak256(relayCalldata(nonce, sender, target, value, minGasLimit, message));
    }

    /// Builds the withdrawal the live L2CDM would have produced for sendMessage(target, message, minGasLimit){value}.
    function messengerWithdrawal(
        uint256 mpNonce,
        uint256 cdmNonce,
        address sender,
        address target,
        uint256 value,
        uint32 minGasLimit,
        bytes memory message
    ) internal pure returns (WithdrawalTransaction memory w) {
        w.nonce = v1Nonce(mpNonce);
        w.sender = L2CDM;
        w.target = address(l1cdm);
        w.value = value;
        w.gasLimit = l2BaseGasLive(message.length, minGasLimit);
        w.data = relayCalldata(v1Nonce(cdmNonce), sender, target, value, minGasLimit, message);
    }

    /// Creates a dispute game (respected type 9) over a fabricated super root whose only content is
    /// an output root with a single-leaf L2ToL1MessagePasser storage trie containing `_tx`, then proves `_tx`.
    /// NOTE: the fabricated root is only a vehicle to get an arbitrary L2CDM-originated withdrawal into
    /// `provenWithdrawals` through the real prove path; on mainnet the same state is reached by simply
    /// sending the message on L2 and proving against an honest root.
    function proveFresh(WithdrawalTransaction memory _tx) internal {
        bytes32 wh = hashWithdrawal(_tx);
        bytes32 storageKey = keccak256(abi.encode(wh, uint256(0)));
        bytes32 path = keccak256(abi.encode(storageKey));
        bytes memory leaf = abi.encodePacked(hex"e3a120", path, hex"01");
        bytes32 storageRoot = keccak256(leaf);
        OutputRootProof memory orp = OutputRootProof(bytes32(0), keccak256("state"), storageRoot, keccak256("bh"));
        bytes32 outputRoot = keccak256(abi.encode(orp.version, orp.stateRoot, orp.messagePasserStorageRoot, orp.latestBlockhash));
        seq++;
        bytes memory extra = abi.encodePacked(bytes1(0x01), uint64(block.timestamp + seq), L2_CHAIN_ID, outputRoot);
        uint256 idx = dgf.gameCount();
        address game = dgf.create{ value: dgf.initBonds(9) }(9, keccak256(extra), extra);
        games.push(game);
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        bytes[] memory proof = new bytes[](1);
        proof[0] = leaf;
        portal.proveWithdrawalTransaction(_tx, idx, orp, proof);
    }

    /// Lets the (unchallenged) games resolve and the proofs mature.
    function matureAll() internal {
        vm.warp(block.timestamp + 302400 + 2);
        for (uint256 i; i < games.length; i++) {
            IGame(games[i]).resolveClaim(0, 0);
            IGame(games[i]).resolve();
            assertEq(IGame(games[i]).status(), 2, "DEFENDER_WINS");
        }
        vm.warp(block.timestamp + 604800 + 2);
        delete games;
    }
}
