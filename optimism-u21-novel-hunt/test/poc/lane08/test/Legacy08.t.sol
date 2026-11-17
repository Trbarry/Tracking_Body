// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Base08.sol";

/// Version-0 (pre-Bedrock, migrated) messenger withdrawals across U21, using a REAL legacy withdrawal that was
/// proven on mainnet at block 26427304 (prove tx 0x91c310bc…, withdrawal nonce 106600, 3000 GTC to 0x93f3…0746).
contract Legacy08Test is Base08 {
    function _load(uint256 idx) internal returns (WithdrawalTransaction memory w, address submitter, address game) {
        string memory json = vm.readFile("data/proven_slim.json");
        string memory k = string.concat(".items[", vm.toString(idx), "]");
        bytes memory input = vm.parseJsonBytes(json, string.concat(k, ".input"));
        submitter = vm.parseJsonAddress(json, string.concat(k, ".from"));
        bytes memory args = new bytes(input.length - 4);
        for (uint256 j; j < args.length; j++) args[j] = input[j + 4];
        uint256 gi;
        (w, gi,,) = abi.decode(args, (WithdrawalTransaction, uint256, OutputRootProof, bytes[]));
        (,, game) = dgf.gameAtIndex(gi);
    }

    function _mature(address game) internal {
        vm.warp(block.timestamp + 302400 + 600);
        if (IGame(game).status() == 0) {
            IGame(game).resolveClaim(0, 0);
            IGame(game).resolve();
        }
        vm.warp(block.timestamp + 604800 + 600);
    }

    function _decode(bytes memory d) internal pure returns (uint256 nonce, address sender, address target, uint256 value, uint256 minGas, bytes memory message) {
        bytes memory a = new bytes(d.length - 4);
        for (uint256 j; j < a.length; j++) a[j] = d[j + 4];
        (nonce, sender, target, value, minGas, message) = abi.decode(a, (uint256, address, address, uint256, uint256, bytes));
    }

    /// (a) real state: the legacy message was never relayed -> delivered exactly once, legacy-format replay blocked.
    /// (b) same withdrawal if the legacy message HAD been relayed before Bedrock (successfulMessages[oldHash] set,
    ///     which is the production state of every already-relayed legacy message; emulated with vm.store):
    ///     v9: OptimismPortal_L1CDMCallFailed at any gas (proven, never finalizable);  v8: finalized, success=false.
    function test_legacy_v0_inflight() public {
        vm.createSelectFork(vm.envOr("FORK", string("l1")));
        bool v9 = keccak256(bytes(portal.version())) == keccak256("6.1.0");
        (WithdrawalTransaction memory w, address submitter, address game) = _load(5);
        (uint256 nonce, address sender, address target,,, bytes memory message) = _decode(w.data);
        assertEq(nonce >> 240, 0, "version 0");
        bytes32 oldHash = keccak256(abi.encodeWithSignature("relayMessage(address,address,bytes,uint256)", target, sender, message, nonce));
        bytes32 slot = keccak256(abi.encode(oldHash, uint256(203)));
        assertEq(vm.load(address(l1cdm), slot), bytes32(0), "legacy message not relayed pre-Bedrock");
        _mature(game);

        uint256 snap = vm.snapshotState();
        // (a)
        portal.finalizeWithdrawalTransactionExternalProof{ gas: 2_500_000 }(w, submitter);
        assertTrue(l1cdm.successfulMessages(keccak256(w.data)), "delivered under the v1 hash");
        vm.expectRevert();
        portal.finalizeWithdrawalTransactionExternalProof(w, submitter);
        vm.revertToState(snap);

        // (b)
        vm.store(address(l1cdm), slot, bytes32(uint256(1)));
        uint256[3] memory gs = [uint256(2_000_000), 10_000_000, 50_000_000];
        for (uint256 i; i < gs.length; i++) {
            uint256 s2 = vm.snapshotState();
            (bool ok, bytes memory ret) = address(portal).call{ gas: gs[i] }(abi.encodeCall(portal.finalizeWithdrawalTransactionExternalProof, (w, submitter)));
            if (v9) {
                assertFalse(ok);
                assertEq(bytes4(ret), bytes4(keccak256("OptimismPortal_L1CDMCallFailed()")));
            } else {
                assertTrue(ok);
                assertTrue(portal.finalizedWithdrawals(hashWithdrawal(w)));
                assertFalse(l1cdm.successfulMessages(keccak256(w.data)) || l1cdm.failedMessages(keccak256(w.data)));
            }
            vm.revertToState(s2);
        }
    }
}
