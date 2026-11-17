// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../src/UpgradeReplay.sol";

/// Pins down the exact semantics of vm.rollFork + vm.makePersistent that `_carry` relies on:
///   (1) rollFork discards local writes to NON-persistent accounts;
///   (2) a persistent account keeps the slots it has loaded or written locally (stale read values
///       included) across rollFork;
///   (3) slots of a persistent account that were never touched locally are served from the chain at
///       the NEW block.
contract PersistProbeTest is UpgradeReplay {
    // OptimismPortal `params` (ResourceMetering, slot 1) changes with every deposit block;
    // the implementation slot changes at every upgrade.
    bytes32 constant SLOT_PARAMS = bytes32(uint256(1));
    uint256 constant B0 = 26048619 - 1; // block before U20
    uint256 constant B1 = 26430859; // U21 block

    function test_roll_discards_local_writes_of_non_persistent_accounts() public {
        _forkAt(B0);
        bytes32 real0 = vm.load(OP_PORTAL, EIP1967_IMPL_SLOT);
        vm.store(OP_PORTAL, EIP1967_IMPL_SLOT, bytes32(uint256(0xdead)));
        vm.store(OP_PORTAL, bytes32(uint256(0xF6F6F6)), bytes32(uint256(1)));
        _rollTo(B1);
        assertEq(address(uint160(uint256(vm.load(OP_PORTAL, EIP1967_IMPL_SLOT)))), HFData.implAfter(HFData.PORTAL, HFData.U21_V9), "real impl at B1");
        assertEq(vm.load(OP_PORTAL, bytes32(uint256(0xF6F6F6))), bytes32(0), "local write gone");
        _rollTo(B0);
        assertEq(vm.load(OP_PORTAL, EIP1967_IMPL_SLOT), real0, "back at B0: real value, not 0xdead");
    }

    function test_persistent_account_keeps_touched_slots_and_refreshes_untouched() public {
        _forkAt(B0);
        vm.makePersistent(OP_PORTAL);
        // touched by READ only:
        bytes32 impl0 = vm.load(OP_PORTAL, EIP1967_IMPL_SLOT);
        // touched by WRITE (a synthetic marker; this test is about cheatcode semantics, not the protocol):
        vm.store(OP_PORTAL, bytes32(uint256(0xF6F6F6)), bytes32(uint256(0xBEEF)));
        // SLOT_PARAMS is NOT touched before the roll.
        _rollTo(B1);
        assertEq(vm.load(OP_PORTAL, bytes32(uint256(0xF6F6F6))), bytes32(uint256(0xBEEF)), "(2) written slot carried");
        bytes32 implCarried = vm.load(OP_PORTAL, EIP1967_IMPL_SLOT);
        bytes32 paramsAtB1 = vm.load(OP_PORTAL, SLOT_PARAMS);
        emit log_named_bytes32("impl slot read at B0", impl0);
        emit log_named_bytes32("impl slot seen after roll to B1 (persistent)", implCarried);
        emit log_named_bytes32("params seen after roll to B1 (never touched before)", paramsAtB1);
        // reference values from a clean view of B1
        vm.revokePersistent(OP_PORTAL);
        _rollTo(B1);
        bytes32 implReal = vm.load(OP_PORTAL, EIP1967_IMPL_SLOT);
        bytes32 paramsReal = vm.load(OP_PORTAL, SLOT_PARAMS);
        emit log_named_bytes32("impl slot real at B1", implReal);
        emit log_named_bytes32("params real at B1", paramsReal);
        assertTrue(implReal != impl0, "sanity: impl changed between B0 and B1");
        assertEq(implCarried, impl0, "(2) slot that was only READ locally stays at its old value");
        assertEq(paramsAtB1, paramsReal, "(3) untouched slot comes from the new block");
    }
}
