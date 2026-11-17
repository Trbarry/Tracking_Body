// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Reusable REAL-WITHDRAWAL FIXTURE for the Optimism U21 hunt (lane 11).
//
// Loads withdrawals that were really proven on the OP Mainnet OptimismPortal2 (mainnet logs,
// blocks 26363900..26433900) and were NOT finalized at the `l1` pin (26433900), then drives them
// to finalization on a local fork through the public, permissionless path only:
//   warp -> SuperFaultDisputeGame.resolveClaim()/resolve() -> warp past the finality air-gap
//   -> OptimismPortal2.finalizeWithdrawalTransaction[ExternalProof]().
// No vm.prank of any privileged role, no vm.store, no mocks are used by the helpers in this file.
// (vm.warp is the only cheat on the honest path; vm.prank(submitter) is only used to call
// `finalizeWithdrawalTransaction` as the proof submitter, which `...ExternalProof` makes
// equivalent to a permissionless call anyway.)
//
// See test/poc/README.md for the JSON schema and usage.

import "forge-std/Test.sol";

struct WithdrawalTransaction {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
}

interface IPortal {
    function version() external view returns (string memory);
    function ethLockbox() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function systemConfig() external view returns (address);
    function paused() external view returns (bool);
    function l2Sender() external view returns (address);
    function guardian() external view returns (address);
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function provenWithdrawals(bytes32, address) external view returns (address game, uint64 timestamp);
    function proofSubmitters(bytes32, uint256) external view returns (address);
    function numProofSubmitters(bytes32) external view returns (uint256);
    function proofMaturityDelaySeconds() external view returns (uint256);
    function disputeGameFinalityDelaySeconds() external view returns (uint256);
    function respectedGameType() external view returns (uint32);
    function respectedGameTypeUpdatedAt() external view returns (uint64);
    function disputeGameFactory() external view returns (address);
    function disputeGameBlacklist(address) external view returns (bool);
    function superchainConfig() external view returns (address);
    function minimumGasLimit(uint64) external view returns (uint64);
    function checkWithdrawal(bytes32, address) external view;
    function finalizeWithdrawalTransaction(WithdrawalTransaction calldata) external;
    function finalizeWithdrawalTransactionExternalProof(WithdrawalTransaction calldata, address) external;
    function deleteProvenWithdrawal(bytes32, address) external; // v9 only
    function depositTransaction(address, uint256, uint64, bool, bytes calldata) external payable;
    function donateETH() external payable;
    function migrateLiquidity() external;
    function params() external view returns (uint128 prevBaseFee, uint64 prevBoughtGas, uint64 prevBlockNum);
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
    function relayMessage(uint256, address, address, uint256, uint256, bytes calldata) external payable;
    function sendMessage(address, bytes calldata, uint32) external payable;
    function portal() external view returns (address);
}

interface IASR {
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
}

interface IGame {
    function status() external view returns (uint8); // 0 IN_PROGRESS, 1 CHALLENGER_WINS, 2 DEFENDER_WINS
    function createdAt() external view returns (uint64);
    function resolvedAt() external view returns (uint64);
    function gameType() external view returns (uint32);
    function rootClaim() external view returns (bytes32);
    function l2SequenceNumber() external view returns (uint256);
    function claimDataLen() external view returns (uint256);
    function maxClockDuration() external view returns (uint64);
    function resolvedSubgames(uint256) external view returns (bool);
    function resolveClaim(uint256, uint256) external;
    function resolve() external returns (uint8);
}

interface ISuperchainConfig {
    function guardian() external view returns (address);
    function pause(address) external;
    function unpause(address) external;
    function paused(address) external view returns (bool);
}

struct Fixture {
    uint256 index;
    bytes32 hash;
    WithdrawalTransaction wd;
    address proofSubmitter;
    address game;
    uint64 proofTimestamp; // provenWithdrawals[hash][submitter].timestamp at the l1 pin
    uint256 gameIndex;
    bool postU21; // proven after the U21 tx (block 26430859)
    bool messenger; // sender == L2CrossDomainMessenger
    bool hasValue;
    bool multiSubmitter;
    string class_;
    bytes proveCalldata; // exact proveWithdrawalTransaction calldata recorded on mainnet
}

abstract contract U21FixtureBase is Test {
    IPortal internal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    ILockbox internal constant LOCKBOX = ILockbox(0x322b47Ff1FA8D5611F761e3E275C45B71b294D43);
    IMessenger internal constant L1CDM = IMessenger(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);
    IASR internal constant ASR = IASR(0x23B2C62946350F4246f9f9D027e071f0264FD113);
    ISuperchainConfig internal constant SUPERCHAIN_CONFIG = ISuperchainConfig(0x95703e0982140D16f8ebA6d158FccEde42f04a4C);
    address internal constant L1_STANDARD_BRIDGE = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
    address internal constant L2CDM = 0x4200000000000000000000000000000000000007;
    address internal constant DEFAULT_L2_SENDER = 0x000000000000000000000000000000000000dEaD;
    address internal constant GUARDIAN = 0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2;

    string internal indexJson;

    /// @dev Directory (relative to the forge project root, fs_permissions "./") holding
    ///      index.json, f<i>.json and ref<i>.json. Override with env U21_FIXTURES_DIR.
    function _fixturesDir() internal view virtual returns (string memory) {
        return vm.envOr("U21_FIXTURES_DIR", string("evidence/withdrawal-fixtures"));
    }

    function _loadIndex() internal {
        if (bytes(indexJson).length == 0) indexJson = vm.readFile(string.concat(_fixturesDir(), "/index.json"));
    }

    function _fixtureCount() internal returns (uint256) {
        _loadIndex();
        return vm.parseJsonUint(indexJson, ".meta.count");
    }

    function _refCount() internal returns (uint256) {
        _loadIndex();
        return vm.parseJsonUint(indexJson, ".meta.refCount");
    }

    function _load(string memory prefix, uint256 i) private returns (Fixture memory f) {
        string memory j = vm.readFile(string.concat(_fixturesDir(), "/", prefix, vm.toString(i), ".json"));
        f.index = i;
        f.hash = vm.parseJsonBytes32(j, ".hash");
        f.wd.nonce = vm.parseJsonUint(j, ".nonce");
        f.wd.sender = vm.parseJsonAddress(j, ".sender");
        f.wd.target = vm.parseJsonAddress(j, ".target");
        f.wd.value = vm.parseJsonUint(j, ".value");
        f.wd.gasLimit = vm.parseJsonUint(j, ".gasLimit");
        f.wd.data = vm.parseJsonBytes(j, ".data");
        f.proofSubmitter = vm.parseJsonAddress(j, ".proofSubmitter");
        f.game = vm.parseJsonAddress(j, ".game");
        f.proofTimestamp = uint64(vm.parseJsonUint(j, ".proofTimestamp"));
        f.gameIndex = vm.parseJsonUint(j, ".gameIndex");
        f.postU21 = vm.parseJsonBool(j, ".postU21");
        f.hasValue = vm.parseJsonBool(j, ".hasValue");
        f.class_ = vm.parseJsonString(j, ".class");
        f.proveCalldata = vm.parseJsonBytes(j, ".proveCalldata");
        f.messenger = f.wd.sender == L2CDM;
        if (vm.keyExistsJson(j, ".multiSubmitter")) f.multiSubmitter = vm.parseJsonBool(j, ".multiSubmitter");
        // Integrity: the reconstructed struct must hash to the logged withdrawalHash.
        require(hashWithdrawal(f.wd) == f.hash, "fixture: struct does not hash to withdrawalHash");
    }

    /// @notice Loads fixture `i` (proven on mainnet, not finalized at the l1 pin).
    function _loadFixture(uint256 i) internal returns (Fixture memory) {
        return _load("f", i);
    }

    /// @notice Loads reference entry `i`: finalized on mainnet by v9 code between the two pins
    ///         (so: unfinalized and mature on `l1pre`, already finalized on `l1`).
    function _loadRef(uint256 i) internal returns (Fixture memory) {
        return _load("ref", i);
    }

    /// @notice First fixture matching class/kind/value (reverts if none).
    function _findFixture(string memory class_, bool messenger, bool hasValue) internal returns (Fixture memory f) {
        uint256 n = _fixtureCount();
        for (uint256 i; i < n; i++) {
            string memory p = string.concat(".fixtures[", vm.toString(i), "]");
            if (keccak256(bytes(vm.parseJsonString(indexJson, string.concat(p, ".class")))) != keccak256(bytes(class_))) {
                continue;
            }
            bool isMsgr = vm.parseJsonAddress(indexJson, string.concat(p, ".sender")) == L2CDM;
            if (isMsgr != messenger) continue;
            if (vm.parseJsonBool(indexJson, string.concat(p, ".hasValue")) != hasValue) continue;
            return _loadFixture(i);
        }
        revert(string.concat("no fixture for class ", class_));
    }

    function hashWithdrawal(WithdrawalTransaction memory w) internal pure returns (bytes32) {
        return keccak256(abi.encode(w.nonce, w.sender, w.target, w.value, w.gasLimit, w.data));
    }

    /// @notice v1 cross-domain message hash of a messenger withdrawal (data = relayMessage(...)).
    function messageHash(WithdrawalTransaction memory w) internal pure returns (bytes32) {
        // The withdrawal data is exactly abi.encodeWithSignature("relayMessage(uint256,address,address,uint256,uint256,bytes)", ...)
        // which is what Hashing.hashCrossDomainMessageV1 hashes.
        return keccak256(w.data);
    }

    struct Inner {
        uint256 nonce;
        address sender;
        address target;
        uint256 value;
        uint256 minGasLimit;
        bytes message;
    }

    function decodeInner(WithdrawalTransaction memory w) internal pure returns (Inner memory i) {
        bytes memory d = w.data;
        bytes memory body = new bytes(d.length - 4);
        for (uint256 k = 4; k < d.length; k++) body[k - 4] = d[k];
        (i.nonce, i.sender, i.target, i.value, i.minGasLimit, i.message) =
            abi.decode(body, (uint256, address, address, uint256, uint256, bytes));
    }

    // ------------------------------------------------------------------------------------------
    // Honest-path drivers
    // ------------------------------------------------------------------------------------------

    /// @notice Resolves a (Super)FaultDisputeGame through its public functions. Warps to the end
    ///         of the chess clocks if needed. Returns the final status.
    function _resolveGameHonestly(address game) internal returns (uint8 status) {
        IGame g = IGame(game);
        status = g.status();
        if (status != 0) return status;
        // Uncontested games resolve once the root clock (maxClockDuration) has run out; contested
        // ones need up to twice that (clock inheritance + extensions are bounded by it).
        uint256 clockEnd = uint256(g.createdAt()) + uint256(g.maxClockDuration()) + 1;
        if (block.timestamp < clockEnd) vm.warp(clockEnd);
        uint256 n = g.claimDataLen();
        for (uint256 pass; pass < 2; pass++) {
            bool allOk = true;
            for (uint256 i = n; i > 0; i--) {
                if (g.resolvedSubgames(i - 1)) continue;
                try g.resolveClaim(i - 1, 0) { }
                catch {
                    allOk = false;
                    break;
                }
            }
            if (allOk) break;
            require(pass == 0, "fixture: game cannot be resolved honestly");
            vm.warp(uint256(g.createdAt()) + 2 * uint256(g.maxClockDuration()) + 1);
        }
        status = g.resolve();
    }

    /// @notice Makes fixture `f` finalizable by its recorded proof submitter using only warps and
    ///         public game functions. Returns false if the game resolved against the proposer.
    function _makeFinalizable(Fixture memory f) internal returns (bool ok) {
        (address game, uint64 ts) = PORTAL.provenWithdrawals(f.hash, f.proofSubmitter);
        require(ts != 0, "fixture: not proven on this fork");
        uint8 st = _resolveGameHonestly(game);
        if (st != 2) return false;
        uint256 t1 = uint256(ts) + PORTAL.proofMaturityDelaySeconds() + 1;
        uint256 t2 = uint256(IGame(game).resolvedAt()) + PORTAL.disputeGameFinalityDelaySeconds() + 1;
        uint256 t = t1 > t2 ? t1 : t2;
        if (block.timestamp < t) vm.warp(t);
        PORTAL.checkWithdrawal(f.hash, f.proofSubmitter);
        return true;
    }

    /// @notice Finalizes through the permissionless external-proof entry point from `caller`.
    function _finalizeAs(Fixture memory f, address caller) internal {
        vm.prank(caller, caller);
        PORTAL.finalizeWithdrawalTransactionExternalProof(f.wd, f.proofSubmitter);
    }

    /// @notice Low-level finalize with an exact gas stipend; returns success and returndata.
    function _finalizeWithGas(Fixture memory f, uint256 gas_) internal returns (bool ok, bytes memory ret) {
        (ok, ret) = address(PORTAL).call{ gas: gas_ }(
            abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (f.wd, f.proofSubmitter))
        );
    }

    /// @notice Replays the recorded mainnet proof calldata as `submitter`.
    function _reproveAs(Fixture memory f, address submitter) internal returns (bool ok, bytes memory ret) {
        vm.prank(submitter, submitter);
        (ok, ret) = address(PORTAL).call(f.proveCalldata);
    }

    function _sel(bytes memory ret) internal pure returns (bytes4 s) {
        if (ret.length >= 4) {
            assembly {
                s := mload(add(ret, 32))
            }
        }
    }
}
