// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Base08.sol";

/// SafeCall.callWithMinGas (v9) adds NEW_ACCOUNT_STATE_GAS = 183,600 to the portal's min-gas requirement when
/// `_tx.value != 0 && _tx.target.codehash == 0`, although EIP-8037 is not active on L1. Measured on real bytecode.
/// Run with --isolate for cold-access accounting; FORK=l1 (v9) or FORK=l1pre (v8).
contract NewAccount08Test is Base08 {
    function setUp() public {
        vm.createSelectFork(vm.envOr("FORK", string("l1")));
        vm.deal(address(this), 100 ether);
    }

    function minGas(WithdrawalTransaction memory w) internal returns (uint256 lo) {
        uint256 hi = 5_000_000;
        lo = 1;
        bytes memory cd = abi.encodeCall(portal.finalizeWithdrawalTransaction, (w));
        while (lo < hi) {
            uint256 mid = (lo + hi) / 2;
            uint256 snap = vm.snapshotState();
            (bool ok,) = address(portal).call{ gas: mid }(cd);
            vm.revertToState(snap);
            if (ok) hi = mid; else lo = mid + 1;
        }
    }

    function test_newAccountReserve() public {
        address fresh = address(uint160(uint256(keccak256("lane08-never-touched-account"))));
        address existing = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        assertEq(fresh.codehash, bytes32(0));
        assertTrue(existing.codehash != bytes32(0));
        WithdrawalTransaction memory a = WithdrawalTransaction(v1Nonce(920001), address(0xA11CE), fresh, 1 ether, 0, "");
        WithdrawalTransaction memory b = WithdrawalTransaction(v1Nonce(920002), address(0xA11CE), existing, 1 ether, 0, "");
        WithdrawalTransaction memory c = WithdrawalTransaction(v1Nonce(920003), address(0xA11CE), fresh, 0, 0, "");
        proveFresh(a);
        proveFresh(b);
        proveFresh(c);
        matureAll();
        emit log_named_string("portal", portal.version());
        emit log_named_uint("min gas, 1 ETH -> never-touched account (codehash 0), gasLimit 0", minGas(a));
        emit log_named_uint("min gas, 1 ETH -> existing EOA, gasLimit 0", minGas(b));
        emit log_named_uint("min gas, 0 ETH -> never-touched account, gasLimit 0", minGas(c));
    }
}
