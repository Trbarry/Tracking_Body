// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Base08.sol";

/// Real withdrawals proven on mainnet in the ~5k blocks before the U21 tx (in flight across the upgrade).
/// Fork l1 = post-U21 code (portal 6.1.0 / L1CDM 2.13.0); fork l1pre = pre-U21 code (5.8.0 / 2.11.1).
contract InFlight08Test is Base08 {
    enum Out { NotEnoughGas, CDMCallFailed, OtherRevert, FinalizedPortalFailure, FinalizedFailedMsg, FinalizedSuccessMsg, FinalizedNoRecord }

    function _fork() internal returns (string memory f) {
        f = vm.envOr("FORK", string("l1"));
        vm.createSelectFork(f);
    }

    function attempt(WithdrawalTransaction memory w, address submitter, bytes32 mh, uint256 gasLimit) internal returns (Out o) {
        uint256 snap = vm.snapshotState();
        bytes memory cd = abi.encodeCall(portal.finalizeWithdrawalTransactionExternalProof, (w, submitter));
        vm.recordLogs();
        (bool ok, bytes memory ret) = address(portal).call{ gas: gasLimit }(cd);
        if (!ok) {
            bytes4 sel = ret.length >= 4 ? bytes4(ret) : bytes4(0);
            if (sel == bytes4(keccak256("OptimismPortal_L1CDMCallFailed()"))) o = Out.CDMCallFailed;
            else if (sel == 0x08c379a0) o = Out.NotEnoughGas;
            else o = Out.OtherRevert;
        } else {
            Vm.Log[] memory logs = vm.getRecordedLogs();
            bool portalSuccess;
            for (uint256 i; i < logs.length; i++) {
                if (logs[i].topics[0] == keccak256("WithdrawalFinalized(bytes32,bool)")) portalSuccess = abi.decode(logs[i].data, (bool));
            }
            if (!portalSuccess) o = Out.FinalizedPortalFailure;
            else if (l1cdm.successfulMessages(mh)) o = Out.FinalizedSuccessMsg;
            else if (l1cdm.failedMessages(mh)) o = Out.FinalizedFailedMsg;
            else o = Out.FinalizedNoRecord;
        }
        vm.revertToState(snap);
    }

    function searchMin(WithdrawalTransaction memory w, address s, bytes32 mh, uint256 hi) internal returns (uint256 lo) {
        lo = 1;
        while (lo < hi) {
            uint256 mid = (lo + hi) / 2;
            Out o = attempt(w, s, mh, mid);
            if (uint8(o) >= uint8(Out.CDMCallFailed) && o != Out.OtherRevert) hi = mid; else lo = mid + 1;
        }
    }

    function test_inflight_realWithdrawals() public {
        string memory f = _fork();
        string memory json = vm.readFile("data/proven_slim.json");
        uint256 n = vm.parseJsonUint(json, ".n");
        // let every game referenced resolve (unchallenged) and every proof mature
        vm.warp(block.timestamp + 302400 + 600);
        vm.roll(block.number + 1);
        WithdrawalTransaction[] memory ws = new WithdrawalTransaction[](n);
        address[] memory subs = new address[](n);
        for (uint256 i; i < n; i++) {
            string memory k = string.concat(".items[", vm.toString(i), "]");
            bytes memory input = vm.parseJsonBytes(json, string.concat(k, ".input"));
            subs[i] = vm.parseJsonAddress(json, string.concat(k, ".from"));
            bytes memory args = new bytes(input.length - 4);
            for (uint256 j; j < args.length; j++) args[j] = input[j + 4];
            (WithdrawalTransaction memory w, uint256 gi,,) = abi.decode(args, (WithdrawalTransaction, uint256, OutputRootProof, bytes[]));
            ws[i] = w;
            (,, address game) = dgf.gameAtIndex(gi);
            if (IGame(game).status() == 0) {
                try IGame(game).resolveClaim(0, 0) { } catch { }
                try IGame(game).resolve() { } catch { }
            }
        }
        vm.warp(block.timestamp + 604800 + 600);
        vm.roll(block.number + 1);
        emit log_named_string("fork", f);
        emit log_named_string("portal", portal.version());
        emit log_named_string("L1CDM", l1cdm.version());
        emit log("idx | wd.gasLimit | dataLen | value | v0? | minPassGas | outcome@min | outcome@min+3M   (1=L1CDMCallFailed 3=finalized,portal success=false 4=finalized+failedMsg 5=finalized+delivered)");
        for (uint256 i; i < n; i++) {
            WithdrawalTransaction memory w = ws[i];
            bytes32 wh = hashWithdrawal(w);
            if (portal.finalizedWithdrawals(wh)) { emit log_named_uint("already finalized", i); continue; }
            try portal.checkWithdrawal(wh, subs[i]) { } catch (bytes memory err) { emit log_named_uint("checkWithdrawal fails", i); emit log_bytes(err); continue; }
            bytes32 mh;
            bool v0;
            if (w.sender == L2CDM && w.data.length >= 4) {
                bytes memory d = w.data;
                bytes memory a = new bytes(d.length - 4);
                for (uint256 j; j < a.length; j++) a[j] = d[j + 4];
                (uint256 nonce,,,,,) = abi.decode(a, (uint256, address, address, uint256, uint256, bytes));
                v0 = (nonce >> 240) == 0;
                mh = keccak256(d);
            }
            uint256 g = searchMin(w, subs[i], mh, 20_000_000);
            Out o1 = attempt(w, subs[i], mh, g);
            Out o2 = attempt(w, subs[i], mh, g + 3_000_000);
            emit log(string.concat(vm.toString(i), " | ", vm.toString(w.gasLimit), " | ", vm.toString(w.data.length), " | ", vm.toString(w.value), " | ", v0 ? "v0" : (w.sender == L2CDM ? "v1" : "non-CDM"), " | ", vm.toString(g), " | ", vm.toString(uint8(o1)), " | ", vm.toString(uint8(o2))));
        }
    }
}
