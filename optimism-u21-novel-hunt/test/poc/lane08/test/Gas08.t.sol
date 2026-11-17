// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Base08.sol";

contract Sink {
    uint256 public hits;
    fallback() external payable { hits++; }
}

contract GasBurner {
    fallback() external payable { while (true) { } }
}

contract Reverter {
    fallback() external payable { revert("no"); }
}

contract Gas08Test is Base08 {
    enum Out { NotEnoughGas, CDMCallFailed, OtherRevert, FinalizedFailedMsg, FinalizedSuccessMsg, FinalizedNoRecord }

    function setUp() public {
        vm.createSelectFork(vm.envOr("FORK", string("l1")));
        vm.deal(address(this), 100 ether);
    }

    function attempt(WithdrawalTransaction memory w, bytes32 mh, uint256 gasLimit) internal returns (Out o, uint256 used) {
        uint256 snap = vm.snapshotState();
        bytes memory cd = abi.encodeCall(portal.finalizeWithdrawalTransaction, (w));
        uint256 g0 = gasleft();
        (bool ok, bytes memory ret) = address(portal).call{ gas: gasLimit }(cd);
        used = g0 - gasleft();
        if (!ok) {
            bytes4 sel = ret.length >= 4 ? bytes4(ret) : bytes4(0);
            if (sel == bytes4(keccak256("OptimismPortal_L1CDMCallFailed()"))) o = Out.CDMCallFailed;
            else if (sel == 0x08c379a0) o = Out.NotEnoughGas; // Error(string) "SafeCall: Not enough gas"
            else o = Out.OtherRevert; // incl. OOG of the portal frame itself
        } else {
            require(portal.finalizedWithdrawals(hashWithdrawal(w)), "not finalized?");
            if (l1cdm.successfulMessages(mh)) o = Out.FinalizedSuccessMsg;
            else if (l1cdm.failedMessages(mh)) o = Out.FinalizedFailedMsg;
            else o = Out.FinalizedNoRecord;
        }
        vm.revertToState(snap);
    }

    /// smallest gas such that outcome >= target outcome class (outcomes are monotone in gas for our targets)
    function searchMin(WithdrawalTransaction memory w, bytes32 mh, Out want, uint256 lo, uint256 hi) internal returns (uint256) {
        (Out o,) = attempt(w, mh, hi);
        if (uint8(o) < uint8(want)) return type(uint256).max;
        while (lo < hi) {
            uint256 mid = (lo + hi) / 2;
            (o,) = attempt(w, mh, mid);
            if (uint8(o) >= uint8(want)) hi = mid; else lo = mid + 1;
        }
        return lo;
    }

    function report(string memory label, WithdrawalTransaction memory w, bytes32 mh) internal {
        uint256 HI = 30_000_000;
        uint256 gPass = searchMin(w, mh, Out.CDMCallFailed, 1, HI);      // first gas where portal's own min-gas check passes (or anything beyond)
        uint256 gFin = searchMin(w, mh, Out.FinalizedFailedMsg, 1, HI);  // first gas where the withdrawal finalizes
        uint256 gOk = searchMin(w, mh, Out.FinalizedSuccessMsg, 1, HI);  // first gas where the message is delivered
        (Out oPass,) = attempt(w, mh, gPass);
        (Out oFin,) = attempt(w, mh, gFin);
        emit log_named_string("== case", label);
        emit log_named_uint("   tx.gasLimit (live L2 baseGas)", w.gasLimit);
        emit log_named_uint("   data length", w.data.length);
        emit log_named_uint("   min call gas passing portal SafeCall check", gPass);
        emit log_named_uint("   outcome there (1=CDMCallFailed 3=finalized+failedMsg 4=finalized+delivered)", uint8(oPass));
        emit log_named_uint("   min call gas to finalize", gFin);
        emit log_named_uint("   outcome there", uint8(oFin));
        emit log_named_uint("   min call gas to deliver message", gOk);
    }

    function test_ethBridgeWithdrawal_minGas0() public {
        address to = makeAddr("recipient-existing");
        vm.deal(to, 1 wei);
        bytes memory m = abi.encodeWithSignature("finalizeBridgeETH(address,address,uint256,bytes)", to, to, 1 ether, bytes(""));
        WithdrawalTransaction memory w = messengerWithdrawal(900001, 900001, L2_BRIDGE, L1_BRIDGE, 1 ether, 0, m);
        proveFresh(w);
        matureAll();
        report("ETH bridge withdrawal, minGasLimit=0, existing EOA", w, msgHash(v1Nonce(900001), L2_BRIDGE, L1_BRIDGE, 1 ether, 0, m));
    }

    function test_ethBridgeWithdrawal_minGas200k() public {
        address to = makeAddr("recipient-existing");
        vm.deal(to, 1 wei);
        bytes memory m = abi.encodeWithSignature("finalizeBridgeETH(address,address,uint256,bytes)", to, to, 1 ether, bytes(""));
        WithdrawalTransaction memory w = messengerWithdrawal(900002, 900002, L2_BRIDGE, L1_BRIDGE, 1 ether, 200_000, m);
        proveFresh(w);
        matureAll();
        report("ETH bridge withdrawal, minGasLimit=200000, existing EOA", w, msgHash(v1Nonce(900002), L2_BRIDGE, L1_BRIDGE, 1 ether, 200_000, m));
    }
}
