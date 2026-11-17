// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../src/HistoricalFork.sol";
import "../src/MultiChain.sol";

/// F6 piece 5 — verifies the four-chain handle table (OP Mainnet, Ink, Soneium, Unichain) against
/// each chain's SystemConfig on chain, before and after U21, and exercises `_forEachChain` with a
/// real permissionless deposit on every chain. One fork per test.
contract MultiChainTest is HistoricalFork, MultiChain {
    address constant ALICE = address(uint160(0xA11CE0F6F6));

    function _checkAll(uint256 blockNumber) internal returns (string memory out) {
        _forkAt(blockNumber);
        out = string.concat("| chain | id | portal | ETHLockbox | L1CDM | bridge | DGF | ASR | resolved == table |\n|---|---|---|---|---|---|---|---|---|\n");
        for (uint256 i; i < Chains.COUNT; i++) {
            OpChain memory t = _chain(i);
            OpChain memory r = _resolveChain(i);
            bool same = _sameHandles(t, r);
            assertTrue(same, string.concat("handles of ", t.name, " == SystemConfig-resolved handles at ", vm.toString(blockNumber)));
            assertEq(r.chainId, t.chainId, "chain id");
            out = string.concat(out, "| ", t.name, " | ", vm.toString(r.chainId), " | ", _version(r.portal), " | ", _version(r.lockbox), " | ");
            out = string.concat(out, _version(r.l1cdm), " | ", _version(r.l1Bridge), " | ", _version(r.dgf), " | ", _version(r.asr), " | ");
            out = string.concat(out, same ? "yes" : "NO", " |\n");
        }
    }

    function test_handles_match_chain_post_U21() public {
        string memory out = _checkAll(26433900);
        vm.writeFile("../evidence/F6-multichain-26433900.md", out);
        emit log_string(out);
    }

    function test_handles_match_chain_pre_U21() public {
        string memory out = _checkAll(HFData.blockOf(HFData.U21_V9) - 1);
        vm.writeFile("../evidence/F6-multichain-26430858.md", out);
        emit log_string(out);
    }

    // ---- _forEachChain with a real permissionless call per chain ----
    uint256 internal depositsOk;

    function depositBody(OpChain memory c) external {
        uint256 snap = vm.snapshotState();
        uint256 lb = c.lockbox.balance;
        uint256 pb = c.portal.balance;
        vm.deal(ALICE, 1 ether);
        vm.prank(ALICE, ALICE);
        IPortal(c.portal).depositTransaction{ value: 0.01 ether }(address(0xB0B), 0.01 ether, 100_000, false, hex"");
        assertEq(c.lockbox.balance - lb, 0.01 ether, string.concat(c.name, ": deposit ETH goes to the chain's ETHLockbox"));
        assertEq(c.portal.balance, pb, string.concat(c.name, ": portal keeps no ETH"));
        vm.revertToStateAndDelete(snap);
        depositsOk++;
    }

    function test_forEachChain_deposit_post_U21() public {
        _forkAt(26433900);
        _forEachChain(this.depositBody);
        assertEq(depositsOk, Chains.COUNT, "deposit works on all four chains");
    }
}
