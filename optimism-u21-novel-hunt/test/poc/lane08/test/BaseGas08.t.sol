// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Base08.sol";

/// L1 -> L2 direction: L1CDM.baseGas (what the L1 messenger charges for the L2 relay) is numerically unchanged by U21
/// and equals the live L2 formula (same constants), so deposits are budgeted exactly as before.
contract BaseGas08Test is Base08 {
    function test_l1_baseGas_unchanged_across_u21() public {
        uint256 post = vm.createFork("l1");
        uint256 pre = vm.createFork("l1pre");
        uint32[6] memory ms = [uint32(0), 1, 200_000, 350_000, 3_000_000, type(uint32).max];
        uint256[8] memory lens = [uint256(0), 1, 164, 228, 10_000, 11_616, 100_000, 120_000];
        for (uint256 i; i < ms.length; i++) {
            for (uint256 j; j < lens.length; j++) {
                bytes memory m = new bytes(lens[j]);
                vm.selectFork(pre);
                uint64 a = l1cdm.baseGas(m, ms[i]);
                vm.selectFork(post);
                uint64 b = l1cdm.baseGas(m, ms[i]);
                assertEq(a, b, "pre == post");
                assertEq(b, l2BaseGasLive(lens[j], ms[i]), "== live L2 formula");
            }
        }
        vm.selectFork(pre);
        assertEq(l1cdm.version(), "2.11.1");
        vm.selectFork(post);
        assertEq(l1cdm.version(), "2.13.0");
    }
}
