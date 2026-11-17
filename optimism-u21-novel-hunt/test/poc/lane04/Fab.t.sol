// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./Base.sol";

contract Burner {
    // burns ~need gas, then accepts ETH
    uint256 public immutable need;
    constructor(uint256 n) { need = n; }
    fallback() external payable {
        uint256 start = gasleft();
        uint256 x;
        while (start - gasleft() < need) { x++; }
    }
}
contract Reverter { fallback() external payable { revert("no"); } }
contract Bomb { fallback() external payable { assembly { return(0, 2000000) } } }
contract RevertBomb { fallback() external payable { assembly { revert(0, 2000000) } } }
contract StateDep {
    bool public open;
    function set(bool o) external { open = o; }
    fallback() external payable { require(open, "closed"); }
}
contract GasProbe {
    uint256 public got;
    fallback() external payable { got = gasleft(); }
}

/// FABRICATED proofs: provenWithdrawals slot is written with vm.store (mock-only, to characterise branch
/// conditions of the deployed v6.1.0 implementation). The dispute game used is a REAL game resolved honestly.
contract FabTest is Base {
    address game;
    address constant SUB = address(0x5B);
    address constant ATT = address(0xA77ACC);

    function setUp() public {
        _fork();
        Prove memory p = _load(8); // real proof against game 0xC6dF..., already DEFENDER_WINS
        game = _mature(p.hash, p.submitter);
        assertTrue(ASR.isGameClaimValid(game));
    }

    function _fab(WithdrawalTransaction memory w) internal returns (bytes32 h) {
        h = hashWd(w);
        bytes32 slot = keccak256(abi.encode(SUB, keccak256(abi.encode(h, uint256(57)))));
        uint256 ts = block.timestamp - 604800 - 10;
        vm.store(address(PORTAL), slot, bytes32((ts << 160) | uint256(uint160(game))));
        PORTAL.checkWithdrawal(h, SUB);
    }

    function _w(address sender, address target, uint256 value, uint256 gasLimit, bytes memory data)
        internal pure returns (WithdrawalTransaction memory w)
    {
        w = WithdrawalTransaction({ nonce: (uint256(1) << 240) | 0xffffffffff, sender: sender, target: target, value: value, gasLimit: gasLimit, data: data });
    }

    function _fin(WithdrawalTransaction memory w, uint256 g) internal returns (bool ok, bytes memory ret) {
        vm.prank(ATT);
        (ok, ret) = address(PORTAL).call{ gas: g }(abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (w, SUB)));
    }

    // --- L1CDMCallFailed trigger condition -------------------------------------------------
    function test_cond_senderL2CDM_targetNotL1CDM_reverting() public {
        address t = address(new Reverter());
        WithdrawalTransaction memory w = _w(L2CDM, t, 1 ether, 100_000, "");
        bytes32 h = _fab(w);
        (bool ok, bytes memory ret) = _fin(w, 2_000_000);
        assertFalse(ok);
        assertEq(bytes4(ret), bytes4(keccak256("OptimismPortal_L1CDMCallFailed()")));
        assertFalse(PORTAL.finalizedWithdrawals(h));
    }

    function test_cond_senderNotL2CDM_targetL1CDM_relayReverts() public {
        // relayMessage of a never-failed message from a non-messenger sender -> "message cannot be replayed"
        bytes memory data = abi.encodeCall(IMessenger.relayMessage, ((uint256(1) << 240) | 77, address(0xBEEF), address(0xCAFE), 0, 0, ""));
        WithdrawalTransaction memory w = _w(address(0xBEEF), address(L1CDM), 0, 300_000, data);
        bytes32 h = _fab(w);
        (bool ok,) = _fin(w, 2_000_000);
        assertTrue(ok);
        assertTrue(PORTAL.finalizedWithdrawals(h)); // finalized-with-failure, no replay (sender != L2CDM)
        assertFalse(L1CDM.failedMessages(keccak256(data)));
        assertFalse(L1CDM.successfulMessages(keccak256(data)));
    }

    function test_cond_senderNotL2CDM_withValue_reverting_relocks() public {
        address t = address(new Reverter());
        WithdrawalTransaction memory w = _w(address(0xBEEF), t, 5 ether, 100_000, "");
        bytes32 h = _fab(w);
        uint256 lb = LOCKBOX.balance; uint256 pb = address(PORTAL).balance; uint256 tb = t.balance;
        (bool ok,) = _fin(w, 2_000_000);
        assertTrue(ok);
        assertTrue(PORTAL.finalizedWithdrawals(h));
        assertEq(LOCKBOX.balance, lb); assertEq(address(PORTAL).balance, pb); assertEq(t.balance, tb);
    }

    function test_cond_senderL2CDM_messageToUnsafeTarget_neverFinalizable() public {
        bytes memory data = abi.encodeCall(IMessenger.relayMessage, ((uint256(1) << 240) | 0xfffffffff0, address(0xBEEF), address(PORTAL), 1 ether, 0, ""));
        WithdrawalTransaction memory w = _w(L2CDM, address(L1CDM), 1 ether, 400_000, data);
        bytes32 h = _fab(w);
        (bool ok, bytes memory ret) = _fin(w, 5_000_000);
        assertFalse(ok);
        assertEq(bytes4(ret), bytes4(keccak256("OptimismPortal_L1CDMCallFailed()")));
        assertFalse(PORTAL.finalizedWithdrawals(h));
    }

    // messenger withdrawal whose target reverts: recorded failed, finalized, replayable; second finalize blocked
    function test_messenger_failed_then_replay_and_no_double() public {
        StateDep t = new StateDep();
        bytes memory data = abi.encodeCall(IMessenger.relayMessage, ((uint256(1) << 240) | 0xfffffffff1, address(0xBEEF), address(t), 3 ether, 50_000, hex"01"));
        WithdrawalTransaction memory w = _w(L2CDM, address(L1CDM), 3 ether, 400_000, data);
        bytes32 h = _fab(w);
        uint256 mb = address(L1CDM).balance; uint256 tb0 = address(t).balance;
        (bool ok,) = _fin(w, 5_000_000);
        assertTrue(ok);
        assertTrue(PORTAL.finalizedWithdrawals(h));
        assertTrue(L1CDM.failedMessages(keccak256(data)));
        assertEq(address(L1CDM).balance - mb, 3 ether);
        // portal second time
        (ok,) = _fin(w, 5_000_000);
        assertFalse(ok);
        // replay through the PORTAL as a different (non-messenger) withdrawal carrying the same relayMessage calldata and value 0
        t.set(true);
        WithdrawalTransaction memory w2 = _w(address(0xBEEF), address(L1CDM), 0, 400_000, data);
        bytes32 h2 = _fab(w2);
        (ok,) = _fin(w2, 5_000_000);
        assertTrue(ok);
        assertTrue(PORTAL.finalizedWithdrawals(h2));
        assertTrue(L1CDM.successfulMessages(keccak256(data)));
        assertEq(address(t).balance - tb0, 3 ether);
        assertEq(address(L1CDM).balance, mb);
        // direct replay now fails
        vm.expectRevert();
        L1CDM.relayMessage((uint256(1) << 240) | 0xfffffffff1, address(0xBEEF), address(t), 3 ether, 50_000, hex"01");
    }

    // --- gas: non-messenger, gas-hungry target; can a third party force success=false? -----
    // codes: 0 revert-empty 1 revert NotEnoughGas 3 revert other 4 finalized+delivered 5 finalized+UNDELIVERED
    function _sweepNM(WithdrawalTransaction memory w, uint256 lo, uint256 hi, uint256 step) internal {
        bytes32 h = _fab(w);
        uint8 last = 255;
        for (uint256 g = lo; g <= hi; g += step) {
            uint256 snap = vm.snapshotState();
            uint256 tb = w.target.balance;
            (bool ok, bytes memory ret) = _fin(w, g);
            uint8 c;
            if (!ok) c = ret.length == 0 ? 0 : (bytes4(ret) == bytes4(keccak256("Error(string)")) ? 1 : 3);
            else { require(PORTAL.finalizedWithdrawals(h)); c = (w.target.balance - tb == w.value && (w.value > 0)) ? 4 : 5; }
            vm.revertToState(snap);
            if (c != last) { console.log("  gas >=", g, "outcome", c); last = c; }
        }
    }

    function test_gas_burner_need500k_limit100k_value() public {
        address t = address(new Burner(500_000));
        console.log("burner need 500k, gasLimit 100k, value 1 ETH");
        _sweepNM(_w(address(0xBEEF), t, 1 ether, 100_000, ""), 150_000, 1_000_000, 1_000);
    }
    function test_gas_burner_need2M_limit100k_value() public {
        address t = address(new Burner(2_000_000));
        console.log("burner need 2M, gasLimit 100k, value 1 ETH");
        _sweepNM(_w(address(0xBEEF), t, 1 ether, 100_000, ""), 150_000, 3_000_000, 5_000);
    }
    function test_gas_burner_need60k_limit0_value() public {
        address t = address(new Burner(60_000));
        console.log("burner need 60k, gasLimit 0, value 1 ETH");
        _sweepNM(_w(address(0xBEEF), t, 1 ether, 0, ""), 100_000, 400_000, 500);
    }
    function test_gas_freshEOA_value_today() public {
        address t = address(uint160(uint256(keccak256("fresh-eoa-lane04"))));
        assertEq(t.codehash, bytes32(0));
        console.log("fresh EOA (codehash 0), gasLimit 0, value 1 ETH");
        _sweepNM(_w(address(0xBEEF), t, 1 ether, 0, ""), 100_000, 500_000, 500);
        vm.deal(t, 1);
        assertEq(t.codehash, keccak256(""));
        console.log("same EOA after 1 wei dust (codehash keccak(empty))");
        _sweepNM(_w(address(0xBEEF), t, 1 ether, 0, ""), 100_000, 500_000, 500);
    }
    function test_returnbomb() public {
        address t = address(new Bomb());
        console.log("return bomb 2MB, gasLimit 100k, value 1 ETH");
        _sweepNM(_w(address(0xBEEF), t, 1 ether, 100_000, ""), 150_000, 2_000_000, 5_000);
        t = address(new RevertBomb());
        console.log("revert bomb 2MB, gasLimit 100k, value 1 ETH");
        _sweepNM(_w(address(0xBEEF), t, 1 ether, 100_000, ""), 150_000, 2_000_000, 5_000);
    }
    function test_probe_gas_received_at_minimum() public {
        GasProbe t = new GasProbe();
        WithdrawalTransaction memory w = _w(address(0xBEEF), address(t), 0, 100_000, "");
        _fab(w);
        uint256 lo = 100_000; uint256 hi = 1_000_000;
        while (hi - lo > 1) {
            uint256 mid = (lo + hi) / 2;
            uint256 snap = vm.snapshotState();
            (bool ok,) = _fin(w, mid);
            vm.revertToState(snap);
            if (ok) hi = mid; else lo = mid;
        }
        (bool ok2,) = _fin(w, hi);
        assertTrue(ok2);
        console.log("min portal-call gas", hi, "target gasleft at entry", t.got());
    }
}
