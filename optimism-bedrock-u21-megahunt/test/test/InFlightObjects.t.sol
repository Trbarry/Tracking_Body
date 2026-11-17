// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../src/InFlightObjects.sol";

/// Populates every era with real in-flight objects through protocol actions and records which
/// eras work. One fork per test, re-pinned with vm.rollFork (no fork leak). Outputs:
///   ../evidence/F6-objects-deposits.md, F6-objects-proves.md, F6-objects-failed.md, F6-objects-games.md
contract InFlightObjectsTest is InFlightObjects {
    address constant ALICE = address(uint160(0xA11CE0F6F6));
    address constant FRESH_SUBMITTER = address(uint160(0x5B0F6F6));

    function _eras() internal pure returns (uint256[] memory e) {
        e = new uint256[](17);
        uint256 n;
        for (uint256 i = HFData.BEDROCK; i < HFData.POINTS; i++) {
            // BEDROCK_STEP1 (portal not initialised yet) is the only point without a usable portal.
            e[n++] = i;
        }
        assembly {
            mstore(e, n)
        }
    }

    // ------------------------------------------------------------------------------------------
    // 1. deposits, with and without value, in every era
    // ------------------------------------------------------------------------------------------
    function test_deposit_every_era() public {
        uint256[] memory e = _eras();
        _forkAt(HFData.blockOf(e[0]));
        string memory out =
            "| era | block | portal | deposit 1 ETH | ETH to portal | ETH to lockbox | deposit 0 ETH | opaqueData len |\n|---|---|---|---|---|---|---|---|\n";
        uint256 okBoth;
        for (uint256 k; k < e.length; k++) {
            if (k != 0) _rollAfter(e[k]);
            DepositResult memory a = _deposit(OP_PORTAL, ALICE, address(0xB0B), 1 ether, 1 ether, 100_000, false, hex"");
            DepositResult memory b = _deposit(OP_PORTAL, ALICE, address(0xB0B), 0, 0, 100_000, false, hex"c0ffee");
            if (a.ok && b.ok) okBoth++;
            if (a.ok) {
                assertEq(a.portalBalanceDelta + a.lockboxBalanceDelta, 1 ether, "minted ETH is held by portal or lockbox");
                assertEq(a.l2From, ALICE, "EOA sender is not aliased");
                // opaqueData = abi.encodePacked(uint256 mint, uint256 value, uint64 gasLimit, bool isCreation, bytes data)
                assertEq(a.opaqueData.length, 32 + 32 + 8 + 1, "opaqueData length (no calldata)");
                assertEq(uint256(bytes32(a.opaqueData)), 1 ether, "mint field");
            }
            out = string.concat(
                out, "| ", HFData.label(e[k]), " | ", vm.toString(block.number), " | ", _version(OP_PORTAL), " | ",
                _outcome(a.ok, a.ret), " | "
            );
            out = string.concat(
                out, vm.toString(a.portalBalanceDelta), " | ", vm.toString(a.lockboxBalanceDelta), " | ", _outcome(b.ok, b.ret),
                " | ", vm.toString(b.opaqueData.length), " |\n"
            );
        }
        vm.writeFile("../evidence/F6-objects-deposits.md", out);
        emit log_string(out);
        assertEq(okBoth, e.length, "deposits work in every era from BEDROCK on");
    }

    // ------------------------------------------------------------------------------------------
    // 2. proven withdrawals: replay of a real prove transaction in every era
    // ------------------------------------------------------------------------------------------
    bool internal forked;

    function _pin(uint256 blockNumber) internal {
        if (!forked) {
            _forkAt(blockNumber);
            forked = true;
        } else {
            _rollTo(blockNumber);
        }
    }

    function _proveRow(string memory era) internal returns (string memory row, bool same) {
        EraProve memory p = _loadEraProve(era, 0);
        _pin(p.proveBlock - 1);
        (bool existed,,) = _proofOf(p.hash, p.proofSubmitter);
        (bool ok, bytes memory ret) = _proveReal(p);
        (bool exists, address game, uint64 ts) = _proofOf(p.hash, p.proofSubmitter);
        same = ok && !existed && exists && ts == p.storedTimestamp && game == p.storedGame;
        row = string.concat(
            "| ", era, " | p0 ", vm.toString(p.hash), " | ", vm.toString(p.proveBlock), " | ", _version(OP_PORTAL), " | ",
            p.faultProofModel ? "disputeGame" : "l2OutputOracle"
        );
        row = string.concat(row, " | ", _outcome(ok, ret), " | ", same ? "yes" : "NO", " | ", _freshSubmitterCell(p), " |\n");
    }

    /// @dev A second, synthetic object: the same calldata from a submitter that never proved on mainnet.
    function _freshSubmitterCell(EraProve memory p) internal returns (string memory) {
        if (!p.direct) return "wrapped tx (not attempted) | ";
        (bool ok2, bytes memory ret2) = _proveAs(p, FRESH_SUBMITTER);
        (bool exists2,, uint64 ts2) = _proofOf(p.hash, FRESH_SUBMITTER);
        return string.concat(
            _outcome(ok2, ret2), " | ",
            p.faultProofModel ? (exists2 && ts2 == block.timestamp ? "yes (keyed by submitter)" : "NO") : "n/a (proof keyed by hash only)"
        );
    }

    function test_prove_replay_every_era() public {
        uint256[] memory e = _eras();
        string memory out =
            "| era | fixture | prove block | portal | model | real-tx replay | stored == mainnet | same calldata from fresh submitter | new object stored |\n|---|---|---|---|---|---|---|---|---|\n";
        uint256 replayed;
        uint256 withFixture;
        for (uint256 k; k < e.length; k++) {
            string memory era = HFData.label(e[k]);
            (uint256 n,) = _eraCounts(era);
            if (n == 0) {
                out = string.concat(out, "| ", era, " | none | | | | | | | |\n");
                continue;
            }
            withFixture++;
            (string memory row, bool same) = _proveRow(era);
            if (same) replayed++;
            out = string.concat(out, row);
        }
        vm.writeFile("../evidence/F6-objects-proves.md", out);
        emit log_string(out);
        assertEq(replayed, withFixture, "the real prove tx replays to the mainnet-stored proof in every era that has a fixture");
    }

    // ------------------------------------------------------------------------------------------
    // 3. failed messenger messages: replay of the real failing transaction in every era that has one
    // ------------------------------------------------------------------------------------------
    function _failedRow(string memory era) internal returns (string memory row, bool produced) {
        EraFailedMsg memory m = _loadEraFailed(era, 0);
        _pin(m.blockNumber - 1);
        (bool txOk, bool failedRecorded) = _produceFailedReal(m);
        produced = txOk && failedRecorded;
        (bool rok, bytes memory rret) = _replayFailed(m, ALICE, 0);
        (bool succ,) = _msgStatus(m.msgHash);
        row = string.concat(
            "| ", era, " | m0 ", vm.toString(m.msgHash), " | ", vm.toString(m.blockNumber), " | ", _version(OP_L1CDM), " | ",
            m.producedByPortalFinalize ? "portal finalize" : "messenger replay"
        );
        row = string.concat(
            row, " | ", txOk ? "yes" : "NO", " | ", failedRecorded ? "true" : "false", " | ", _outcome(rok, rret),
            succ ? " (now successful)" : " (still failed)", " |\n"
        );
    }

    function test_failed_message_every_era() public {
        uint256[] memory e = _eras();
        string memory out =
            "| era | fixture | block | L1CDM | produced by | real tx replay ok | failedMessages after | permissionless replay right after |\n|---|---|---|---|---|---|---|---|\n";
        uint256 produced;
        uint256 withFixture;
        for (uint256 k; k < e.length; k++) {
            string memory era = HFData.label(e[k]);
            (, uint256 n) = _eraCounts(era);
            if (n == 0) {
                out = string.concat(out, "| ", era, " | none (no FailedRelayedMessage log in this era) | | | | | | |\n");
                continue;
            }
            withFixture++;
            (string memory row, bool ok) = _failedRow(era);
            if (ok) produced++;
            out = string.concat(out, row);
        }
        vm.writeFile("../evidence/F6-objects-failed.md", out);
        emit log_string(out);
        assertEq(produced, withFixture, "the real failing tx reproduces failedMessages[hash] in every era that has a fixture");
    }

    // ------------------------------------------------------------------------------------------
    // 4. dispute games: a real IN_PROGRESS game and a newly created one, in every fault-proof era
    // ------------------------------------------------------------------------------------------
    function test_game_in_progress_every_fp_era() public {
        _forkAt(HFData.blockOf(HFData.V1_4_0_FP) + 7200);
        string memory out =
            "| era | block | DGF | games | newest IN_PROGRESS (index, type) | create() like it with another root | new game status |\n|---|---|---|---|---|---|---|\n";
        uint256 found;
        uint256 eras;
        for (uint256 i = HFData.V1_4_0_FP; i < HFData.POINTS; i++) {
            // one day after the point, so that games of the new release exist
            uint256 b = HFData.blockOf(i) + 7200;
            if (i == HFData.U21_V9) b = 26433900;
            if (i != HFData.V1_4_0_FP) _rollTo(b);
            eras++;
            (address game, uint256 idx) = _findGameInProgress(OP_DGF, 40);
            out = string.concat(
                out, "| ", HFData.label(i), " | ", vm.toString(b), " | ", _version(OP_DGF), " | ", vm.toString(IDGF(OP_DGF).gameCount()), " | "
            );
            if (game == address(0)) {
                out = string.concat(out, "none in the last 40 | | |\n");
                continue;
            }
            found++;
            (bool ok, address ng, bytes memory ret) = _createGameLike(OP_DGF, game, keccak256("F6 harness root claim"), ALICE);
            out = string.concat(
                out, vm.toString(game), " (", vm.toString(idx), ", type ", vm.toString(uint256(IGame(game).gameType())), ") | ",
                _outcome(ok, ret), " | ", ok ? vm.toString(uint256(IGame(ng).status())) : "-", " |\n"
            );
        }
        vm.writeFile("../evidence/F6-objects-games.md", out);
        emit log_string(out);
        assertEq(found, eras, "a real in-progress game exists one day after every fault-proof fork point");
    }
}
