// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";

interface IDGF {
    function gameCount() external view returns (uint256);
    function gameAtIndex(uint256) external view returns (uint32, uint64, address);
}

interface IGame {
    function status() external view returns (uint8);
    function resolvedAt() external view returns (uint64);
    function createdAt() external view returns (uint64);
    function claimDataLen() external view returns (uint256);
    function claimData(uint256)
        external
        view
        returns (uint32 parentIndex, address counteredBy, address claimant, uint128 bond, bytes32 claim, uint128 position, uint128 clock);
    function resolveClaim(uint256, uint256) external;
    function resolve() external returns (uint8);
    function closeGame() external;
    function claimCredit(address) external;
    function bondDistributionMode() external view returns (uint8);
    function credit(address) external view returns (uint256);
    function normalModeCredit(address) external view returns (uint256);
    function refundModeCredit(address) external view returns (uint256);
    function weth() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function maxClockDuration() external view returns (uint64);
    function wasRespectedGameTypeWhenCreated() external view returns (bool);
    function vm() external view returns (address);
}

interface IWETH {
    function balanceOf(address) external view returns (uint256);
    function withdrawals(address, address) external view returns (uint256, uint256);
    function delay() external view returns (uint256);
    function version() external view returns (string memory);
}

interface IASR {
    function anchorGame() external view returns (address);
    function isGameFinalized(address) external view returns (bool);
    function isGameProper(address) external view returns (bool);
    function paused() external view returns (bool);
    function version() external view returns (string memory);
}

contract InflightGamesTest is Test {
    IDGF constant DGF = IDGF(0xe5965Ab5962eDc7477C8520243A95517CD252fA9);
    uint256 constant U21_TS = 1794871439; // block 26430859 timestamp (pre block 26430858 = 1794871427)

    uint256 tested;
    uint256 okPaid;
    uint256 inProgress;
    uint256 resolvedUnclosed;
    uint256 closedUnclaimed;
    uint256 failures;

    function _one(uint256 i) internal {
        (uint32 gt, uint64 ts, address g) = DGF.gameAtIndex(i);
        if (ts >= U21_TS) return; // only games created before U21
        IGame game = IGame(g);
        IWETH weth = IWETH(game.weth());
        if (weth.balanceOf(g) == 0) return; // fully paid out
        tested++;
        (,, address claimant,,,,) = game.claimData(0);
        if (game.status() == 0) inProgress++;
        else if (game.bondDistributionMode() == 0) resolvedUnclosed++;
        else closedUnclaimed++;
        uint256 snap = vm.snapshotState();
        bool ok = _flow(game, weth, claimant, gt);
        vm.revertToState(snap);
        if (ok) okPaid++;
        else {
            failures++;
            emit log_named_address("FAILED game", g);
            emit log_named_uint("  index", i);
        }
    }

    function _run(string memory fork, uint256 lookback) internal {
        string memory alt = vm.envOr("ALT_RPC", string(""));
        if (bytes(alt).length != 0 && keccak256(bytes(fork)) == keccak256("l1")) {
            // same pinned block as the shared `l1` anvil, read straight from an archive node (passive reads only)
            vm.createSelectFork(alt, 26433900);
        } else {
            vm.createSelectFork(fork);
        }
        uint256 n = DGF.gameCount();
        uint256 start = n > lookback ? n - lookback : 0;
        uint256 step = vm.envOr("STEP", uint256(1));
        for (uint256 i = start; i < n; i += step) {
            _one(i);
        }
        emit log_named_string("fork", fork);
        emit log_named_uint("gameCount", n);
        emit log_named_uint("pre-U21 games with WETH balance tested", tested);
        emit log_named_uint("  in progress at fork block", inProgress);
        emit log_named_uint("  resolved, not closed", resolvedUnclosed);
        emit log_named_uint("  closed, credit unclaimed", closedUnclaimed);
        emit log_named_uint("paid out in full", okPaid);
        emit log_named_uint("failures", failures);
        assertEq(failures, 0, "some in-flight game could not pay out");
        assertGt(tested, 0);
    }

    function _flow(IGame game, IWETH weth, address claimant, uint32) internal returns (bool) {
        address g = address(game);
        uint256 wbalBefore = weth.balanceOf(g);
        uint256 balBefore = claimant.balance;
        if (game.status() == 0) {
            // only single-claim (unchallenged) games are walked generically; challenged ones are resolved depth-first
            vm.warp(block.timestamp + uint256(game.maxClockDuration()) + 1);
            uint256 len = game.claimDataLen();
            for (uint256 j = len; j > 0; j--) {
                try game.resolveClaim(j - 1, 0) { } catch { }
            }
            try game.resolve() { }
            catch {
                emit log("resolve reverted");
                return false;
            }
        }
        if (game.bondDistributionMode() == 0) {
            vm.warp(uint256(game.resolvedAt()) + 302400 + 1 > block.timestamp ? uint256(game.resolvedAt()) + 302400 + 1 : block.timestamp);
            try game.closeGame() { }
            catch (bytes memory err) {
                emit log_named_bytes("closeGame reverted", err);
                return false;
            }
        }
        // credit recipients: walk every claim's claimant and counteredBy
        uint256 len2 = game.claimDataLen();
        address[] memory rec = new address[](2 * len2);
        for (uint256 j; j < len2; j++) {
            (, address cb, address cl,,,,) = game.claimData(j);
            rec[2 * j] = cl;
            rec[2 * j + 1] = cb;
        }
        // phase 1: unlock
        for (uint256 j; j < rec.length; j++) {
            if (rec[j] == address(0)) continue;
            try game.claimCredit(rec[j]) { } catch { }
        }
        vm.warp(block.timestamp + weth.delay() + 1);
        for (uint256 j; j < rec.length; j++) {
            if (rec[j] == address(0)) continue;
            try game.claimCredit(rec[j]) { } catch { }
        }
        uint256 wbalAfter = weth.balanceOf(g);
        if (wbalAfter != 0) {
            emit log_named_uint("weth balance left in game", wbalAfter);
            return false;
        }
        if (len2 == 1 && claimant.balance != balBefore + wbalBefore) {
            emit log("root claimant not paid");
            return false;
        }
        return true;
    }

    function test_inflight_games_payout_postU21() public {
        _run("l1", vm.envOr("LOOKBACK", uint256(260)));
    }

    function test_inflight_games_payout_preU21_control() public {
        _run("l1pre", 60);
    }
}
