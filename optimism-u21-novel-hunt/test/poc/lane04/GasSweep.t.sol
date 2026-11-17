// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./Base.sol";

contract GasSweepTest is Base {
    function setUp() public { _fork(); }

    // outcome codes: 0 revert-empty(OOG) 1 revert "SafeCall: Not enough gas" 2 revert L1CDMCallFailed 3 revert other
    //                4 ok+successfulMessages 5 ok+failedMessages 6 ok + neither (!!)  (messenger)
    function _try(Prove memory p, address caller, address submitter, uint256 g) internal returns (uint8 code) {
        uint256 snap = vm.snapshotState();
        vm.prank(caller);
        (bool ok, bytes memory ret) = address(PORTAL).call{ gas: g }(
            abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (p.wd, submitter))
        );
        if (!ok) {
            if (ret.length == 0) code = 0;
            else if (bytes4(ret) == bytes4(keccak256("Error(string)"))) code = 1;
            else if (bytes4(ret) == bytes4(keccak256("OptimismPortal_L1CDMCallFailed()"))) code = 2;
            else code = 3;
        } else {
            bytes32 mh = keccak256(p.wd.data);
            bool s = L1CDM.successfulMessages(mh);
            bool f = L1CDM.failedMessages(mh);
            require(PORTAL.finalizedWithdrawals(p.hash), "ok but not finalized");
            code = s ? 4 : (f ? 5 : 6);
            if (s && f) code = 7;
        }
        vm.revertToState(snap);
    }

    function _sweep(uint256 idx, uint256 lo, uint256 hi, uint256 step) internal {
        Prove memory p = _load(idx);
        _mature(p.hash, p.submitter);
        address attacker = address(0xA77ACC);
        console.log("idx/gasLimit/value", idx, p.wd.gasLimit, p.wd.value);
        uint8 last = 255;
        for (uint256 g = lo; g <= hi; g += step) {
            uint8 c = _try(p, attacker, p.submitter, g);
            if (c != last) { console.log("  gas >=", g, "outcome", c); last = c; }
        }
    }

    function test_sweep_messenger_eth_2000() public { _sweep(36, 100_000, 700_000, 1000); }
    function test_sweep_messenger_erc20() public { _sweep(40, 200_000, 1_000_000, 1000); }
    function test_sweep_messenger_big() public { _sweep(10, 3_000_000, 4_000_000, 2000); }
}

contract GasSweep2Test is GasSweepTest {
    function test_big_wide() public { _sweep(10, 3_600_000, 12_000_000, 100_000); }
    function test_big_trace() public {
        Prove memory p = _load(10);
        _mature(p.hash, p.submitter);
        vm.prank(address(0xA77ACC));
        PORTAL.finalizeWithdrawalTransactionExternalProof{gas: 8_000_000}(p.wd, p.submitter);
    }
}
