// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./Base.sol";

/// Cross-version: state created under v8 (fork l1pre = block before the U21 tx), then the REAL U21 transaction is
/// re-executed in-process (same sender EOA, same calldata, same Safe) and the object is consumed under v9.
contract CrossVersionTest is Base {
    address constant U21_SENDER = 0xE10A25d4ec17A94CA455F3cDA84137189843B4f2;
    address constant SAFE = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address constant ATT = address(0xA77ACC);

    function setUp() public {
        vm.createSelectFork("l1pre");
        json = vm.readFile("proves.json");
        assertEq(PORTAL.version(), "5.8.0");
    }

    function _upgrade() internal {
        bytes memory input = vm.parseBytes(vm.readFile("u21input.hex"));
        vm.prank(U21_SENDER, U21_SENDER);
        (bool ok, bytes memory ret) = SAFE.call(input);
        require(ok, string(ret));
        assertEq(PORTAL.version(), "6.1.0");
    }

    function _dec(bytes memory data) internal pure returns (uint256, address, address, uint256, uint256, bytes memory) {
        bytes memory args = new bytes(data.length - 4);
        for (uint256 j = 0; j < args.length; j++) args[j] = data[j + 4];
        return abi.decode(args, (uint256, address, address, uint256, uint256, bytes));
    }

    function _try(Prove memory p, uint256 g) internal returns (uint8 code) {
        uint256 snap = vm.snapshotState();
        vm.prank(ATT);
        (bool ok, bytes memory ret) = address(PORTAL).call{ gas: g }(
            abi.encodeCall(IPortal.finalizeWithdrawalTransactionExternalProof, (p.wd, p.submitter))
        );
        if (!ok) code = ret.length == 0 ? 0 : (bytes4(ret) == bytes4(keccak256("Error(string)")) ? 1 : 3);
        else {
            bytes32 mh = keccak256(p.wd.data);
            bool s = L1CDM.successfulMessages(mh); bool f = L1CDM.failedMessages(mh);
            code = s ? 4 : (f ? 5 : 6);
        }
        vm.revertToState(snap);
    }

    // v8 behaviour for the same withdrawal the v9 sweep used (idx 36, 2000 ETH)
    function test_v8_sweep() public {
        Prove memory p = _load(36);
        _mature(p.hash, p.submitter);
        uint8 last = 255;
        for (uint256 g = 100_000; g <= 700_000; g += 1000) {
            uint8 c = _try(p, g);
            if (c != last) { console.log("  v8 gas >=", g, "outcome", c); last = c; }
        }
    }

    // proven under v8, upgrade executed, finalized under v9
    function test_provenV8_upgrade_finalizeV9() public {
        Prove memory p = _load(36);
        _mature(p.hash, p.submitter);
        _upgrade();
        (address game, uint64 ts) = PORTAL.provenWithdrawals(p.hash, p.submitter);
        assertTrue(ts != 0 && ASR.isGameClaimValid(game));
        uint256 lb = LOCKBOX.balance;
        vm.prank(ATT);
        PORTAL.finalizeWithdrawalTransactionExternalProof(p.wd, p.submitter);
        assertEq(lb - LOCKBOX.balance, 2000 ether);
        assertTrue(L1CDM.successfulMessages(keccak256(p.wd.data)));
    }

    // FAILED under v8 (recipient behaviour substituted with vm.etch -> reverting), upgrade, replay under v9.
    function test_failedV8_upgrade_replayV9() public {
        Prove memory p = _load(0); // 119.59 ETH to EOA 0xb9b3..., minGasLimit 0
        _mature(p.hash, p.submitter);
        (uint256 n, address s, address t, uint256 v, uint256 mg, bytes memory m) = _dec(p.wd.data);
        address recipient = 0xb9B397fb65c9a336A6F117598361cE1efe05F35B;
        vm.etch(recipient, hex"60006000fd"); // SUBSTITUTION: recipient reverts
        uint256 mb = address(L1CDM).balance; uint256 rb = recipient.balance;
        vm.prank(ATT);
        PORTAL.finalizeWithdrawalTransactionExternalProof(p.wd, p.submitter);
        bytes32 mh = keccak256(p.wd.data);
        assertTrue(L1CDM.failedMessages(mh));
        assertTrue(PORTAL.finalizedWithdrawals(p.hash));
        assertEq(address(L1CDM).balance - mb, v);

        _upgrade();
        assertTrue(L1CDM.failedMessages(mh));
        assertTrue(PORTAL.finalizedWithdrawals(p.hash));
        assertEq(address(L1CDM).balance - mb, v);
        vm.etch(recipient, "");

        // portal cannot run it again
        vm.expectRevert(bytes4(keccak256("OptimismPortal_AlreadyFinalized()")));
        PORTAL.finalizeWithdrawalTransactionExternalProof(p.wd, p.submitter);

        // replay gas sweep under v9 constants
        uint8 last = 255;
        for (uint256 g = 20_000; g <= 500_000; g += 500) {
            uint256 snap = vm.snapshotState();
            vm.prank(ATT);
            (bool ok,) = address(L1CDM).call{ gas: g }(abi.encodeCall(IMessenger.relayMessage, (n, s, t, v, mg, m)));
            uint8 c = !ok ? 0 : (L1CDM.successfulMessages(mh) ? 4 : 5);
            vm.revertToState(snap);
            if (c != last) { console.log("  v9 replay gas >=", g, "outcome", c); last = c; }
        }
        vm.prank(ATT);
        L1CDM.relayMessage(n, s, t, v, mg, m);
        assertTrue(L1CDM.successfulMessages(mh));
        assertEq(recipient.balance - rb, v);
        assertEq(address(L1CDM).balance, mb);
        vm.expectRevert();
        L1CDM.relayMessage(n, s, t, v, mg, m);
    }
}
