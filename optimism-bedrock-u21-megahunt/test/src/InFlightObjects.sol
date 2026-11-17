// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// F6 historical harness — piece 3: REAL in-flight objects on a historical fork, created through
// protocol actions only (no vm.store, no mock, no privileged prank):
//
//   deposit                 OptimismPortal.depositTransaction (ABI unchanged since Bedrock)
//   proven withdrawal       replay of a real proveWithdrawalTransaction transaction at the block it
//                           was mined (era fixtures evidence/F6-era-fixtures/<ERA>/p<i>.json), or the
//                           same calldata from another submitter (fault-proof eras: the proof is
//                           keyed by msg.sender, so this creates a NEW object)
//   failed messenger message replay of the real transaction that emitted FailedRelayedMessage
//                           (fixtures <ERA>/m<i>.json) + the relayMessage calldata that replays it
//   dispute game            a real game that is IN_PROGRESS at the fork block, or a new game created
//                           through DisputeGameFactory.create with a real game's extraData
//
// vm.prank is used only to choose the caller of a permissionless function (the recorded sender of
// a real user transaction, or a fresh address). vm.warp is the only other cheat.

import "./UpgradeReplay.sol";
import "./Ifaces.sol";

struct EraProve {
    string era;
    uint256 index;
    bytes32 hash;
    WithdrawalTransaction wd;
    bool messenger; // wd.sender == L2CrossDomainMessenger
    address proofSubmitter; // msg.sender seen by the portal (0 if unknown: wrapped tx before fault proofs)
    bool submitterKnown;
    uint256 proofRefIndex; // l2OutputIndex (L2OutputOracle eras) or disputeGameIndex (fault-proof eras)
    bool faultProofModel; // true: provenWithdrawals(hash, submitter); false: provenWithdrawals(hash)
    address storedGame; // game stored by the real proof (0 in L2OutputOracle eras)
    uint64 storedTimestamp; // proof timestamp stored by the real proof
    bytes32 proveTx;
    address txFrom;
    address txTo;
    uint256 txValue;
    uint256 txGas;
    bytes txInput; // full input of the real prove transaction
    bool direct; // txTo == portal and the input is exactly the prove call
    uint256 proveBlock;
    uint64 proveTimestamp;
    bool finalizedAtHead; // finalizedWithdrawals(hash) at the fixture's head block
}

struct EraFailedMsg {
    string era;
    uint256 index;
    bytes32 msgHash;
    uint256 blockNumber;
    uint64 timestamp;
    bytes32 txHash;
    address txFrom;
    address txTo;
    uint256 txValue;
    uint256 txGas;
    bytes txInput; // full input of the real transaction that emitted FailedRelayedMessage
    bytes relayCalldata; // relayMessage(...) calldata; keccak256 == msgHash for version-1 messages
    bool hashIsV1;
    bool producedByPortalFinalize; // false: the failure came from a direct replay on the messenger
    bool failedAtHead;
    bool successfulAtHead;
}

struct DepositResult {
    bool ok;
    bytes ret;
    bytes opaqueData; // TransactionDeposited.opaqueData (empty if the call failed)
    address l2From; // indexed `from` of the event (aliased if the caller has code)
    uint256 portalBalanceDelta; // ETH that stayed in the portal
    uint256 lockboxBalanceDelta; // ETH that went to the ETHLockbox (0 before U16)
}

abstract contract InFlightObjects is UpgradeReplay {
    bytes32 internal constant TOPIC_TRANSACTION_DEPOSITED = 0xb3813568d9991fc951961fcb4c784893574240a28925604d09fc577c55bb7c32;
    bytes32 internal constant TOPIC_FAILED_RELAYED = 0x99d0e048484baa1b1540b1367cb128acd7ab2946d1ed91ec10e3c85e4bf51b8f;
    bytes32 internal constant TOPIC_RELAYED = 0x4641df4a962071e12719d8c8c8e5ac7fc4d97b927346a3d7a335b1f7517e133c;
    bytes32 internal constant TOPIC_WITHDRAWAL_PROVEN = 0x67a6208cfcc0801d50f6cbe764733f4fddf66ac0b04442061a8a8c0cb6b63f62;
    bytes32 internal constant TOPIC_WITHDRAWAL_FINALIZED = 0xdb5c7652857aa163daadd670e116628fb42e869d8ac4251ef8971d9e5727df1b;

    // ------------------------------------------------------------------------------------------
    // Era fixture loaders
    // ------------------------------------------------------------------------------------------

    function _eraDir() internal view virtual returns (string memory) {
        return vm.envOr("F6_ERA_FIXTURES_DIR", string("../evidence/F6-era-fixtures"));
    }

    function _eraCounts(string memory era) internal view returns (uint256 proves, uint256 failed) {
        string memory j = vm.readFile(string.concat(_eraDir(), "/", era, "/count.json"));
        proves = vm.parseJsonUint(j, ".proves");
        failed = vm.parseJsonUint(j, ".failedMessages");
    }

    function _hashWithdrawal(WithdrawalTransaction memory w) internal pure returns (bytes32) {
        return keccak256(abi.encode(w.nonce, w.sender, w.target, w.value, w.gasLimit, w.data));
    }

    function _loadEraProve(string memory era, uint256 i) internal view returns (EraProve memory p) {
        string memory j = vm.readFile(string.concat(_eraDir(), "/", era, "/p", vm.toString(i), ".json"));
        p.era = era;
        p.index = i;
        p.hash = vm.parseJsonBytes32(j, ".hash");
        p.wd.nonce = vm.parseJsonUint(j, ".nonce");
        p.wd.sender = vm.parseJsonAddress(j, ".sender");
        p.wd.target = vm.parseJsonAddress(j, ".target");
        p.wd.value = vm.parseJsonUint(j, ".value");
        p.wd.gasLimit = vm.parseJsonUint(j, ".gasLimit");
        p.wd.data = vm.parseJsonBytes(j, ".data");
        p.messenger = p.wd.sender == L2_CDM;
        p.proofSubmitter = vm.parseJsonAddress(j, ".proofSubmitter");
        p.submitterKnown = vm.parseJsonBool(j, ".submitterKnown");
        p.proofRefIndex = vm.parseJsonUint(j, ".proofRefIndex");
        p.faultProofModel = keccak256(bytes(vm.parseJsonString(j, ".proofModel"))) == keccak256("disputeGame");
        p.storedGame = vm.parseJsonAddress(j, ".storedGame");
        p.storedTimestamp = uint64(vm.parseJsonUint(j, ".storedTimestamp"));
        p.proveTx = vm.parseJsonBytes32(j, ".proveTx");
        p.txFrom = vm.parseJsonAddress(j, ".proveTxFrom");
        p.txTo = vm.parseJsonAddress(j, ".proveTxTo");
        p.txValue = vm.parseJsonUint(j, ".proveTxValue");
        p.txGas = vm.parseJsonUint(j, ".proveTxGas");
        p.txInput = vm.parseJsonBytes(j, ".proveTxInput");
        p.direct = vm.parseJsonBool(j, ".direct");
        p.proveBlock = vm.parseJsonUint(j, ".proveBlock");
        p.proveTimestamp = uint64(vm.parseJsonUint(j, ".proveTimestamp"));
        p.finalizedAtHead = vm.parseJsonBool(j, ".finalizedAtHead");
        require(_hashWithdrawal(p.wd) == p.hash, "era fixture: struct does not hash to withdrawalHash");
    }

    /// @notice First prove fixture of `era` matching the filters (reverts if none).
    function _findEraProve(string memory era, bool wantUnfinalizedAtHead, bool wantDirect)
        internal
        view
        returns (EraProve memory p)
    {
        (uint256 n,) = _eraCounts(era);
        for (uint256 i; i < n; i++) {
            p = _loadEraProve(era, i);
            if (wantUnfinalizedAtHead && p.finalizedAtHead) continue;
            if (wantDirect && !p.direct) continue;
            return p;
        }
        revert(string.concat("no matching prove fixture in era ", era));
    }

    function _loadEraFailed(string memory era, uint256 i) internal view returns (EraFailedMsg memory m) {
        string memory j = vm.readFile(string.concat(_eraDir(), "/", era, "/m", vm.toString(i), ".json"));
        m.era = era;
        m.index = i;
        m.msgHash = vm.parseJsonBytes32(j, ".msgHash");
        m.blockNumber = vm.parseJsonUint(j, ".block");
        m.timestamp = uint64(vm.parseJsonUint(j, ".timestamp"));
        m.txHash = vm.parseJsonBytes32(j, ".tx");
        m.txFrom = vm.parseJsonAddress(j, ".txFrom");
        m.txTo = vm.parseJsonAddress(j, ".txTo");
        m.txValue = vm.parseJsonUint(j, ".txValue");
        m.txGas = vm.parseJsonUint(j, ".txGas");
        m.txInput = vm.parseJsonBytes(j, ".txInput");
        m.relayCalldata = vm.parseJsonBytes(j, ".relayCalldata");
        m.hashIsV1 = vm.parseJsonBool(j, ".hashIsV1");
        m.producedByPortalFinalize = keccak256(bytes(vm.parseJsonString(j, ".producedBy"))) == keccak256("portalFinalize");
        m.failedAtHead = vm.parseJsonBool(j, ".failedAtHead");
        m.successfulAtHead = vm.parseJsonBool(j, ".successfulAtHead");
        if (m.hashIsV1) require(keccak256(m.relayCalldata) == m.msgHash, "era fixture: relay calldata does not hash to msgHash");
    }

    // ------------------------------------------------------------------------------------------
    // 1. Deposits
    // ------------------------------------------------------------------------------------------

    /// @notice `from` calls portal.depositTransaction{value: mint}(to, l2Value, gasLimit, isCreation, data)
    ///         on the active fork. Works in every era (signature unchanged since Bedrock).
    function _deposit(
        address portal,
        address from,
        address to,
        uint256 mint,
        uint256 l2Value,
        uint64 gasLimit,
        bool isCreation,
        bytes memory data
    ) internal returns (DepositResult memory r) {
        address lockbox = _lockboxOf(portal);
        uint256 pb = portal.balance;
        uint256 lb = lockbox == address(0) ? 0 : lockbox.balance;
        vm.deal(from, from.balance + mint);
        vm.recordLogs();
        vm.prank(from, from);
        (r.ok, r.ret) =
            portal.call{ value: mint }(abi.encodeCall(IPortal.depositTransaction, (to, l2Value, gasLimit, isCreation, data)));
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 k; k < logs.length; k++) {
            if (logs[k].emitter == portal && logs[k].topics.length == 4 && logs[k].topics[0] == TOPIC_TRANSACTION_DEPOSITED) {
                r.l2From = address(uint160(uint256(logs[k].topics[1])));
                r.opaqueData = abi.decode(logs[k].data, (bytes));
            }
        }
        r.portalBalanceDelta = portal.balance - pb;
        r.lockboxBalanceDelta = lockbox == address(0) ? 0 : lockbox.balance - lb;
    }

    /// @notice ETHLockbox of `portal` on the active fork, or address(0) in eras without one.
    function _lockboxOf(address portal) internal view returns (address lb) {
        try IPortal(portal).ethLockbox() returns (address a) {
            lb = a;
        } catch { }
    }

    // ------------------------------------------------------------------------------------------
    // 2. Proven withdrawals
    // ------------------------------------------------------------------------------------------

    /// @notice Fresh fork of the block before the real prove transaction of `p`.
    function _forkForProve(EraProve memory p) internal returns (uint256) {
        return _forkAt(p.proveBlock - 1);
    }

    /// @notice Replays the REAL prove transaction (recorded sender, recorded input) on the active
    ///         fork, which must be the state of block proveBlock-1. Block env is set to the prove block.
    function _proveReal(EraProve memory p) internal returns (bool ok, bytes memory ret) {
        vm.roll(p.proveBlock);
        vm.warp(p.proveTimestamp);
        return _replayRaw(p.txFrom, p.txTo, p.txValue, p.txInput, 0);
    }

    /// @notice Sends the recorded prove calldata to the portal from `submitter` (only for fixtures
    ///         whose transaction called the portal directly). In fault-proof eras this creates a
    ///         proof object that does not exist on mainnet: provenWithdrawals[hash][submitter].
    function _proveAs(EraProve memory p, address submitter) internal returns (bool ok, bytes memory ret) {
        require(p.direct, "InFlightObjects: fixture is a wrapped prove; use _proveReal");
        vm.prank(submitter, submitter);
        (ok, ret) = OP_PORTAL.call(p.txInput);
    }

    /// @notice Era-aware read of the stored proof. `game` is 0 in L2OutputOracle eras.
    ///         Tries the fault-proof ABI first, then the Bedrock ABI.
    function _proofOf(bytes32 hash, address submitter) internal view returns (bool exists, address game, uint64 ts) {
        (bool ok, bytes memory ret) = OP_PORTAL.staticcall(abi.encodeWithSelector(0xbb2c727e, hash, submitter)); // provenWithdrawals(bytes32,address)
        if (ok && ret.length == 64) {
            (game, ts) = abi.decode(ret, (address, uint64));
            return (ts != 0, game, ts);
        }
        (ok, ret) = OP_PORTAL.staticcall(abi.encodeWithSelector(0xe965084c, hash)); // provenWithdrawals(bytes32)
        if (ok && ret.length == 96) {
            (, uint128 t,) = abi.decode(ret, (bytes32, uint128, uint128));
            return (t != 0, address(0), uint64(t));
        }
    }

    function _isFinalized(bytes32 hash) internal view returns (bool) {
        return IPortal(OP_PORTAL).finalizedWithdrawals(hash);
    }

    /// @notice Resolves a fault dispute game through its public functions (both resolveClaim ABIs),
    ///         warping to the end of the clocks when needed. Returns the final status.
    function _resolveGame(address game) internal returns (uint8 status) {
        IGame g = IGame(game);
        status = g.status();
        if (status != 0) return status;
        uint256 dur = _maxClockDuration(game);
        uint256 clockEnd = uint256(g.createdAt()) + dur + 1;
        if (block.timestamp < clockEnd) vm.warp(clockEnd);
        uint256 n = g.claimDataLen();
        for (uint256 pass; pass < 2; pass++) {
            bool allOk = true;
            for (uint256 i = n; i > 0; i--) {
                if (_subgameResolved(game, i - 1)) continue;
                (bool ok,) = game.call(abi.encodeWithSignature("resolveClaim(uint256,uint256)", i - 1, 0));
                if (!ok) (ok,) = game.call(abi.encodeWithSignature("resolveClaim(uint256)", i - 1));
                if (!ok) {
                    allOk = false;
                    break;
                }
            }
            if (allOk) break;
            require(pass == 0, "InFlightObjects: game cannot be resolved by warping");
            vm.warp(uint256(g.createdAt()) + 2 * dur + 1);
        }
        status = g.resolve();
    }

    function _maxClockDuration(address game) internal view returns (uint256 d) {
        (bool ok, bytes memory ret) = game.staticcall(abi.encodeWithSignature("maxClockDuration()"));
        if (ok && ret.length == 32) return abi.decode(ret, (uint256));
        (ok, ret) = game.staticcall(abi.encodeWithSignature("gameDuration()")); // FaultDisputeGame < 1.0: total duration
        if (ok && ret.length == 32) return abi.decode(ret, (uint256)) / 2;
        return 302400;
    }

    function _subgameResolved(address game, uint256 i) internal view returns (bool r) {
        (bool ok, bytes memory ret) = game.staticcall(abi.encodeWithSignature("resolvedSubgames(uint256)", i));
        if (ok && ret.length == 32) r = abi.decode(ret, (bool));
    }

    /// @notice Warps (and resolves the game, in fault-proof eras) so that the proof of `hash` by
    ///         `submitter` is old enough to finalize under the code that is live on the active fork.
    ///         Returns the game status (2 = DEFENDER_WINS; 255 = L2OutputOracle era, no game).
    function _matureProof(bytes32 hash, address submitter) internal returns (uint8 gameStatus) {
        (bool exists, address game, uint64 ts) = _proofOf(hash, submitter);
        require(exists, "InFlightObjects: no proof stored on this fork");
        if (game == address(0)) {
            // L2OutputOracle model: proof and output must both be older than the finalization period.
            vm.warp(block.timestamp + 7 days + 1);
            if (block.timestamp <= uint256(ts) + 7 days) vm.warp(uint256(ts) + 7 days + 1);
            return 255;
        }
        if (game.code.length == 0) return 254; // stored "game" is not a contract on this fork
        gameStatus = _resolveGame(game);
        uint256 matDelay = 7 days;
        try IPortal(OP_PORTAL).proofMaturityDelaySeconds() returns (uint256 d) {
            matDelay = d;
        } catch { }
        uint256 finDelay = 3.5 days;
        try IPortal(OP_PORTAL).disputeGameFinalityDelaySeconds() returns (uint256 d) {
            finDelay = d;
        } catch { }
        uint256 t1 = uint256(ts) + matDelay + 1;
        uint256 t2 = uint256(IGame(game).resolvedAt()) + finDelay + 1;
        uint256 t = t1 > t2 ? t1 : t2;
        if (block.timestamp < t) vm.warp(t);
    }

    /// @notice Attempts finalization on the active fork: `finalizeWithdrawalTransaction` pranked as
    ///         `submitter` (valid in every era: before fault proofs the caller is irrelevant, after
    ///         them the caller's own proof is used). Returns success and revert data.
    function _tryFinalize(WithdrawalTransaction memory wd, address submitter) internal returns (bool ok, bytes memory ret) {
        vm.prank(submitter, submitter);
        (ok, ret) = OP_PORTAL.call(abi.encodeCall(IPortal.finalizeWithdrawalTransaction, (wd)));
    }

    /// @notice Same through the permissionless external-proof entry point (portal >= 3.x).
    function _tryFinalizeExternal(WithdrawalTransaction memory wd, address submitter, address caller)
        internal
        returns (bool ok, bytes memory ret)
    {
        vm.prank(caller, caller);
        (ok, ret) = OP_PORTAL.call(abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (wd, submitter)));
    }

    // ------------------------------------------------------------------------------------------
    // 3. Failed messenger messages
    // ------------------------------------------------------------------------------------------

    function _forkForFailed(EraFailedMsg memory m) internal returns (uint256) {
        return _forkAt(m.blockNumber - 1);
    }

    /// @notice Replays the REAL transaction that emitted FailedRelayedMessage on the active fork
    ///         (state of block m.blockNumber-1). Returns whether the transaction succeeded and
    ///         whether the messenger now records the message as failed.
    function _produceFailedReal(EraFailedMsg memory m) internal returns (bool txOk, bool failedRecorded) {
        vm.roll(m.blockNumber);
        vm.warp(m.timestamp);
        uint256 intrinsic = _intrinsicGas(m.txInput);
        (txOk,) = _replayRaw(m.txFrom, m.txTo, m.txValue, m.txInput, m.txGas > intrinsic ? m.txGas - intrinsic : m.txGas);
        failedRecorded = IMessenger(OP_L1CDM).failedMessages(m.msgHash);
    }

    /// @notice Permissionless replay of a failed message: `caller` sends the recorded relayMessage
    ///         calldata to the L1CrossDomainMessenger with `gas_` (0 = all) and no value.
    function _replayFailed(EraFailedMsg memory m, address caller, uint256 gas_) internal returns (bool ok, bytes memory ret) {
        vm.prank(caller, caller);
        if (gas_ == 0) (ok, ret) = OP_L1CDM.call(m.relayCalldata);
        else (ok, ret) = OP_L1CDM.call{ gas: gas_ }(m.relayCalldata);
    }

    function _msgStatus(bytes32 msgHash) internal view returns (bool successful, bool failed) {
        successful = IMessenger(OP_L1CDM).successfulMessages(msgHash);
        failed = IMessenger(OP_L1CDM).failedMessages(msgHash);
    }

    // ------------------------------------------------------------------------------------------
    // 4. Dispute games
    // ------------------------------------------------------------------------------------------

    /// @notice Newest game of `dgf` that is IN_PROGRESS on the active fork, looking at the last
    ///         `maxScan` games (address(0) if none / no factory in this era).
    function _findGameInProgress(address dgf, uint256 maxScan) internal view returns (address game, uint256 index) {
        if (dgf.code.length == 0) return (address(0), 0);
        uint256 n;
        try IDGF(dgf).gameCount() returns (uint256 c) {
            n = c;
        } catch {
            return (address(0), 0);
        }
        for (uint256 k; k < maxScan && k < n; k++) {
            (,, address proxy) = IDGF(dgf).gameAtIndex(n - 1 - k);
            if (IGame(proxy).status() == 0) return (proxy, n - 1 - k);
        }
    }

    /// @notice Creates a new game through the permissionless factory entry point, reusing the game
    ///         type and extraData of `template` (a real game) with a different root claim. The bond
    ///         is dealt to `creator`. Reverts with the factory/game revert data when the type is
    ///         permissioned (tx.origin must be the proposer) or the claim already exists.
    function _createGameLike(address dgf, address template, bytes32 rootClaim, address creator)
        internal
        returns (bool ok, address game, bytes memory ret)
    {
        uint32 gt = IGame(template).gameType();
        bytes memory extra = IGame(template).extraData();
        uint256 bond = IDGF(dgf).initBonds(gt);
        vm.deal(creator, creator.balance + bond);
        vm.prank(creator, creator);
        (ok, ret) = dgf.call{ value: bond }(abi.encodeCall(IDGF.create, (gt, rootClaim, extra)));
        if (ok) game = abi.decode(ret, (address));
    }

    // ------------------------------------------------------------------------------------------
    // Small utilities
    // ------------------------------------------------------------------------------------------

    function _sel(bytes memory ret) internal pure returns (bytes4 s) {
        if (ret.length >= 4) {
            assembly {
                s := mload(add(ret, 32))
            }
        }
    }

    /// @notice Human-readable outcome: "ok", "revert <selector>", "revert Error(<string>)" or "revert (empty)".
    function _outcome(bool ok, bytes memory ret) internal pure returns (string memory) {
        if (ok) return "ok";
        if (ret.length == 0) return "revert (empty)";
        if (_sel(ret) == 0x08c379a0 && ret.length >= 68) {
            bytes memory body = new bytes(ret.length - 4);
            for (uint256 k = 4; k < ret.length; k++) body[k - 4] = ret[k];
            return string.concat("revert Error(", abi.decode(body, (string)), ")");
        }
        return string.concat("revert ", vm.toString(abi.encodePacked(_sel(ret))));
    }
}
