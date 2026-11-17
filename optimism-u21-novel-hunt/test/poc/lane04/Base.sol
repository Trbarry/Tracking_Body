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
    function version() external view returns (string memory);
    function ethLockbox() external view returns (address);
    function paused() external view returns (bool);
    function l2Sender() external view returns (address);
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function provenWithdrawals(bytes32, address) external view returns (address game, uint64 timestamp);
    function proofSubmitters(bytes32, uint256) external view returns (address);
    function numProofSubmitters(bytes32) external view returns (uint256);
    function proveWithdrawalTransaction(
        WithdrawalTransaction memory _tx,
        uint256 _disputeGameIndex,
        OutputRootProof calldata _outputRootProof,
        bytes[] calldata _withdrawalProof
    ) external;
    function finalizeWithdrawalTransaction(WithdrawalTransaction memory _tx) external;
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction memory _tx, address _proofSubmitter) external;
    function checkWithdrawal(bytes32 _withdrawalHash, address _proofSubmitter) external view;
    function deleteProvenWithdrawal(bytes32 _withdrawalHash, address _proofSubmitter) external;
    function proofMaturityDelaySeconds() external view returns (uint256);
    function donateETH() external payable;
    function depositTransaction(address,uint256,uint64,bool,bytes memory) external payable;
}

interface IGame {
    function status() external view returns (uint8);
    function resolve() external returns (uint8);
    function resolveClaim(uint256, uint256) external;
    function claimDataLen() external view returns (uint256);
    function createdAt() external view returns (uint64);
    function resolvedAt() external view returns (uint64);
    function gameType() external view returns (uint32);
    function rootClaim() external view returns (bytes32);
    function wasRespectedGameTypeWhenCreated() external view returns (bool);
    function l2SequenceNumber() external view returns (uint256);
}

interface IASR {
    function isGameClaimValid(address) external view returns (bool);
    function isGameProper(address) external view returns (bool);
    function isGameFinalized(address) external view returns (bool);
    function isGameBlacklisted(address) external view returns (bool);
    function blacklistDisputeGame(address) external;
    function respectedGameType() external view returns (uint32);
    function setRespectedGameType(uint32) external;
    function updateRetirementTimestamp() external;
    function retirementTimestamp() external view returns (uint64);
}

interface IDGF {
    function gameAtIndex(uint256) external view returns (uint32, uint64, address);
    function gameCount() external view returns (uint256);
}

interface IMessenger {
    function successfulMessages(bytes32) external view returns (bool);
    function failedMessages(bytes32) external view returns (bool);
    function relayMessage(uint256, address, address, uint256, uint256, bytes memory) external payable;
    function xDomainMessageSender() external view returns (address);
    function baseGas(bytes memory, uint32) external view returns (uint64);
}

contract Base is Test {
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    IMessenger constant L1CDM = IMessenger(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);
    IASR constant ASR = IASR(0x23B2C62946350F4246f9f9D027e071f0264FD113);
    IDGF constant DGF = IDGF(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);
    address constant LOCKBOX = 0x322b47Ff1FA8D5611F761e3E275C45B71b294D43;
    address constant GUARDIAN = 0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2;
    address constant L2CDM = 0x4200000000000000000000000000000000000007;
    address constant BRIDGE = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;

    struct Prove {
        WithdrawalTransaction wd;
        uint256 gameIndex;
        OutputRootProof orp;
        bytes[] proof;
        address submitter;
        bytes32 hash;
        uint256 blockNumber;
    }

    string json;

    function _fork() internal {
        vm.createSelectFork("l1");
        json = vm.readFile("proves.json");
    }

    function _load(uint256 i) internal view returns (Prove memory p) {
        string memory k = string.concat(".txs[", vm.toString(i), "]");
        bytes memory input = vm.parseJsonBytes(json, string.concat(k, ".input"));
        p.submitter = vm.parseJsonAddress(json, string.concat(k, ".from"));
        p.blockNumber = vm.parseJsonUint(json, string.concat(k, ".blockNumber"));
        bytes memory args = new bytes(input.length - 4);
        for (uint256 j = 0; j < args.length; j++) args[j] = input[j + 4];
        (p.wd, p.gameIndex, p.orp, p.proof) = abi.decode(args, (WithdrawalTransaction, uint256, OutputRootProof, bytes[]));
        p.hash = hashWd(p.wd);
        require(p.hash == vm.parseJsonBytes32(json, string.concat(k, ".wdHash")), "hash mismatch");
    }

    function hashWd(WithdrawalTransaction memory w) internal pure returns (bytes32) {
        return keccak256(abi.encode(w.nonce, w.sender, w.target, w.value, w.gasLimit, w.data));
    }

    /// Resolve the real game through its public functions (no pranks) and warp past maturity + finality.
    function _mature(bytes32 h, address submitter) internal returns (address game) {
        uint64 ts;
        (game, ts) = PORTAL.provenWithdrawals(h, submitter);
        require(ts != 0, "not proven");
        IGame g = IGame(game);
        if (g.status() == 0) {
            require(g.claimDataLen() == 1, "contested game");
            vm.warp(block.timestamp + 4 days);
            g.resolveClaim(0, 0);
            g.resolve();
        }
        require(g.status() == 2, "not defender wins");
        uint256 t1 = uint256(g.resolvedAt()) + 302400 + 2;
        uint256 t2 = uint256(ts) + 604800 + 2;
        uint256 t = t1 > t2 ? t1 : t2;
        if (t > block.timestamp) vm.warp(t);
    }

    function _msgHash(bytes memory data) internal pure returns (bytes32) {
        // data = relayMessage(nonce,sender,target,value,minGas,message) calldata; v1 hash == keccak(calldata)
        return keccak256(data);
    }
}
