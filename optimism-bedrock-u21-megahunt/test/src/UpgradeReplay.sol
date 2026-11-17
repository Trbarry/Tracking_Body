// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// F6 historical harness — piece 2: replay of the OFFICIAL historical upgrade transactions.
//
// Every fork point of HistoricalForkData has a fixture test/fixtures/upgrades/<LABEL>.json with the
// real mainnet transaction(s) that performed it (hash, from, to, value, gas, input). Two replay modes:
//
//   Prank    vm.roll/vm.warp to the upgrade block, vm.prank(recorded sender, recorded sender) and
//            `to.call{gas}(input)` with the recorded calldata. Works on ANY state whose Safe nonce
//            and approved hashes equal the real pre-state (a fork of block-1, or a fork carried there
//            with persistent accounts). Compatible with vm.startStateDiffRecording.
//   Transact vm.transact(txHash): forge fetches the transaction and executes it on the current
//            state with its real gas limit and block environment.
//
// The privileged sender is pranked ONLY to reproduce an official, already executed upgrade during
// local setup (allowed by the engagement rules). Never use these helpers in an exploit phase.
//
// Carrying a locally created object through real upgrades: see `_carry`.

import "./HistoricalFork.sol";

struct UpgradeTx {
    bytes32 hash;
    address from;
    address to;
    uint256 value;
    uint256 gas;
    bytes input;
}

struct Upgrade {
    uint256 point; // HFData index
    string label;
    uint256 blockNumber;
    uint64 timestamp;
    UpgradeTx[] txs;
    bytes32[] preTransact; // same-block txs executed (vm.transact) before `txs`, e.g. a proxy CREATE
    UpgradeTx[] postTxs; // same-block txs replayed after `txs`, in the same mode as `txs`
}

struct SlotWrite {
    address account;
    bytes32 slot;
    bytes32 value; // value after the replay finished
}

abstract contract UpgradeReplay is HistoricalFork {
    enum ReplayMode {
        Prank,
        Transact
    }

    event UpgradeReplayed(string label, uint256 blockNumber, uint256 txs, bool transactMode);

    // ------------------------------------------------------------------------------------------
    // Fixtures
    // ------------------------------------------------------------------------------------------

    function _upgradeFixturePath(uint256 i) internal pure virtual returns (string memory) {
        return string.concat("fixtures/upgrades/", HFData.label(i), ".json");
    }

    /// @notice Loads the real transaction(s) of fork point `i`.
    function _loadUpgrade(uint256 i) internal view returns (Upgrade memory u) {
        string memory j = vm.readFile(_upgradeFixturePath(i));
        u.point = i;
        u.label = HFData.label(i);
        u.blockNumber = vm.parseJsonUint(j, ".block");
        u.timestamp = uint64(vm.parseJsonUint(j, ".timestamp"));
        require(u.blockNumber == HFData.blockOf(i), "UpgradeReplay: fixture/table block mismatch");
        uint256 n = vm.parseJsonUint(j, ".txCount");
        u.txs = new UpgradeTx[](n);
        for (uint256 k; k < n; k++) {
            u.txs[k] = _parseTx(j, string.concat(".txs[", vm.toString(k), "]"));
            require(u.txs[k].hash == HFData.txHash(i, k), "UpgradeReplay: fixture/table tx mismatch");
        }
        if (vm.keyExistsJson(j, ".preTransact")) u.preTransact = vm.parseJsonBytes32Array(j, ".preTransact");
        uint256 m = vm.keyExistsJson(j, ".postTxCount") ? vm.parseJsonUint(j, ".postTxCount") : 0;
        u.postTxs = new UpgradeTx[](m);
        for (uint256 k; k < m; k++) {
            u.postTxs[k] = _parseTx(j, string.concat(".postTxs[", vm.toString(k), "]"));
        }
    }

    function _parseTx(string memory j, string memory p) internal pure returns (UpgradeTx memory t) {
        t.hash = vm.parseJsonBytes32(j, string.concat(p, ".hash"));
        t.from = vm.parseJsonAddress(j, string.concat(p, ".from"));
        t.to = vm.parseJsonAddress(j, string.concat(p, ".to"));
        t.value = vm.parseJsonUint(j, string.concat(p, ".value"));
        t.gas = vm.parseJsonUint(j, string.concat(p, ".gas"));
        t.input = vm.parseJsonBytes(j, string.concat(p, ".input"));
    }

    // ------------------------------------------------------------------------------------------
    // Replay primitives
    // ------------------------------------------------------------------------------------------

    /// @notice Block environment of the upgrade block of point `i`.
    function _setBlockEnv(uint256 i) internal {
        vm.roll(HFData.blockOf(i));
        vm.warp(HFData.timestampOf(i));
    }

    /// @dev Intrinsic gas of a transaction with calldata `d` (21000 + 4/16 per byte), so that the
    ///      call receives about what the real transaction's first frame received.
    function _intrinsicGas(bytes memory d) internal pure returns (uint256 g) {
        g = 21000;
        for (uint256 k; k < d.length; k++) {
            g += d[k] == 0 ? 4 : 16;
        }
    }

    /// @notice Raw replay: `from` (also tx.origin) calls `to` with `data`. `gas_` = 0 forwards all.
    ///         Use this for any recorded transaction, not only upgrades.
    function _replayRaw(address from, address to, uint256 value, bytes memory data, uint256 gas_)
        internal
        returns (bool ok, bytes memory ret)
    {
        if (from.balance < value) vm.deal(from, value);
        vm.prank(from, from);
        if (gas_ == 0) (ok, ret) = to.call{ value: value }(data);
        else (ok, ret) = to.call{ value: value, gas: gas_ }(data);
    }

    /// @notice Replays one recorded transaction by pranking its sender (block env must be set).
    function _replayTxPrank(UpgradeTx memory t) internal returns (bool ok, bytes memory ret) {
        uint256 intrinsic = _intrinsicGas(t.input);
        return _replayRaw(t.from, t.to, t.value, t.input, t.gas > intrinsic ? t.gas - intrinsic : t.gas);
    }

    /// @notice Replays the official upgrade of point `i` on the ACTIVE fork state. The caller is
    ///         responsible for the state being "block blockOf(i)-1" (fresh fork or carried).
    ///         Reverts if any transaction fails. Leaves block.number/timestamp at the upgrade block.
    function _replayUpgrade(uint256 i, ReplayMode mode) internal {
        Upgrade memory u = _loadUpgrade(i);
        // Same-block context (only SUPERCHAIN_CONFIG_INIT so far: the proxy and its implementation are
        // created earlier in the upgrade block). Creation txs cannot be pranked, so they always use vm.transact.
        for (uint256 k; k < u.preTransact.length; k++) vm.transact(u.preTransact[k]);
        for (uint256 k; k < u.txs.length; k++) _replayOne(i, u.txs[k], mode, u.label);
        for (uint256 k; k < u.postTxs.length; k++) _replayOne(i, u.postTxs[k], mode, u.label);
        _setBlockEnv(i);
        emit UpgradeReplayed(u.label, u.blockNumber, u.txs.length, mode == ReplayMode.Transact);
    }

    function _replayOne(uint256 i, UpgradeTx memory t, ReplayMode mode, string memory label_) internal {
        if (mode == ReplayMode.Transact) {
            vm.transact(t.hash);
            return;
        }
        _setBlockEnv(i);
        (bool ok, bytes memory ret) = _replayTxPrank(t);
        if (!ok) {
            emit log_named_bytes("upgrade replay revert data", ret);
            revert(string.concat("UpgradeReplay: replay of ", label_, " reverted"));
        }
    }

    /// @notice Fresh fork of the block before point `i`, then the official upgrade replayed on it.
    function _forkAndReplay(uint256 i, ReplayMode mode) internal returns (uint256 forkId) {
        forkId = _forkBefore(i);
        _replayUpgrade(i, mode);
    }

    // ------------------------------------------------------------------------------------------
    // Carrying local objects through the real upgrades
    // ------------------------------------------------------------------------------------------

    /// @notice Carries the ACTIVE fork through the official upgrades (afterPoint, toPoint].
    ///
    /// How it works: for each point k the fork is re-pinned to the real state of block blockOf(k)-1
    /// (vm.rollFork) and the real upgrade transaction is replayed. Accounts that the caller marked
    /// with vm.makePersistent keep, across each re-pin, EVERY SLOT THEY HAVE LOADED OR WRITTEN SO FAR
    /// (plus code, balance, nonce); slots they never touched and all other accounts come from the
    /// real chain at the new block. So an object created locally in a persistent contract (a proof
    /// in the portal, a failed message in the messenger, a game ...) survives, the real upgrade
    /// initializers run on it, and every non-persistent dependency (Safe nonce and approvals, new
    /// implementations, SystemConfig, games, lockbox balance) is exactly the historical one.
    ///
    /// Caveat (measured by `_staleSlots`): slots of a persistent contract that were touched locally
    /// and later changed on mainnet by something OTHER than the replayed upgrades (user traffic,
    /// guardian actions) stay at their local value. Check them when an experiment depends on such a
    /// slot. Typical example: OptimismPortal `params` (resource metering), slot 1.
    function _carry(uint256 afterPoint, uint256 toPoint, ReplayMode mode) internal {
        require(toPoint < HFData.POINTS && afterPoint < toPoint, "UpgradeReplay: bad carry range");
        require(block.number < HFData.blockOf(afterPoint + 1), "UpgradeReplay: active fork is already past the first upgrade");
        for (uint256 k = afterPoint + 1; k <= toPoint; k++) {
            _rollBefore(k);
            _replayUpgrade(k, mode);
        }
    }

    /// @notice Marks the contracts that hold in-flight objects as persistent (portal, messenger
    ///         proxy, bridge proxy). Call BEFORE the first `_carry`.
    function _persistObjectHolders() internal {
        vm.makePersistent(OP_PORTAL, OP_L1CDM, OP_L1_BRIDGE);
    }

    /// @notice Values of `slots` of `account` on the active fork.
    function _readSlots(address account, bytes32[] memory slots) internal view returns (bytes32[] memory v) {
        v = new bytes32[](slots.length);
        for (uint256 k; k < slots.length; k++) v[k] = vm.load(account, slots[k]);
    }

    /// @notice Compares the local (carried) values of `slots` of persistent `account` with the real
    ///         chain at `realBlock`. Revokes the persistence of `account` and re-pins the fork to
    ///         `realBlock` (the carried state is gone afterwards — call it last). Returns the number
    ///         of differing slots and logs each one.
    function _staleSlots(address account, bytes32[] memory slots, uint256 realBlock) internal returns (uint256 n) {
        bytes32[] memory local_ = _readSlots(account, slots);
        vm.revokePersistent(account);
        _rollTo(realBlock);
        for (uint256 k; k < slots.length; k++) {
            bytes32 real = vm.load(account, slots[k]);
            if (real != local_[k]) {
                n++;
                emit log_named_bytes32("stale slot", slots[k]);
                emit log_named_bytes32("  carried", local_[k]);
                emit log_named_bytes32("  real   ", real);
            }
        }
    }

    // ------------------------------------------------------------------------------------------
    // Verification against the real post-state
    // ------------------------------------------------------------------------------------------

    /// @notice Replays point `i` in Prank mode while recording the state diff, and returns every
    ///         distinct (account, slot) the replay wrote, with its value after the replay.
    function _replayUpgradeRecording(uint256 i) internal returns (SlotWrite[] memory writes, uint256 rawWrites) {
        vm.startStateDiffRecording();
        _replayUpgrade(i, ReplayMode.Prank);
        Vm.AccountAccess[] memory acc = vm.stopAndReturnStateDiff();
        uint256 cap;
        for (uint256 a; a < acc.length; a++) cap += acc[a].storageAccesses.length;
        SlotWrite[] memory tmp = new SlotWrite[](cap);
        uint256 n;
        for (uint256 a; a < acc.length; a++) {
            for (uint256 s; s < acc[a].storageAccesses.length; s++) {
                Vm.StorageAccess memory sa = acc[a].storageAccesses[s];
                if (!sa.isWrite || sa.reverted) continue;
                rawWrites++;
                bool seen;
                for (uint256 q; q < n; q++) {
                    if (tmp[q].account == sa.account && tmp[q].slot == sa.slot) {
                        seen = true;
                        break;
                    }
                }
                if (seen) continue;
                tmp[n++] = SlotWrite(sa.account, sa.slot, bytes32(0));
            }
        }
        writes = new SlotWrite[](n);
        for (uint256 q; q < n; q++) {
            writes[q] = SlotWrite(tmp[q].account, tmp[q].slot, vm.load(tmp[q].account, tmp[q].slot));
        }
    }

    /// @notice Re-pins the active fork to the REAL end of the upgrade block of point `i` and
    ///         compares every recorded slot. Returns the number of mismatches (logged). The local
    ///         replay state is discarded.
    function _compareWithRealPostState(uint256 i, SlotWrite[] memory writes)
        internal
        returns (uint256 mismatches, string memory detail)
    {
        _rollAfter(i);
        for (uint256 q; q < writes.length; q++) {
            bytes32 real = vm.load(writes[q].account, writes[q].slot);
            if (real != writes[q].value) {
                mismatches++;
                detail = string.concat(
                    detail, "  ", vm.toString(writes[q].account), " slot ", vm.toString(writes[q].slot), " replay ",
                    vm.toString(writes[q].value), " real ", vm.toString(real), "\n"
                );
            }
        }
    }

    function _distinctAccounts(SlotWrite[] memory w) internal pure returns (uint256 n) {
        address[] memory seen = new address[](w.length);
        for (uint256 q; q < w.length; q++) {
            bool s;
            for (uint256 r; r < n; r++) {
                if (seen[r] == w[q].account) {
                    s = true;
                    break;
                }
            }
            if (!s) seen[n++] = w[q].account;
        }
    }
}
