// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

// LANE 02 — proven/finalized withdrawal mappings across the v8 -> v9 boundary, real OP Mainnet entries.

interface IPortalB {
    function version() external view returns (string memory);
    function provenWithdrawals(bytes32, address) external view returns (address, uint64);
    function proofSubmitters(bytes32, uint256) external view returns (address);
    function numProofSubmitters(bytes32) external view returns (uint256);
    function finalizedWithdrawals(bytes32) external view returns (bool);
    function checkWithdrawal(bytes32, address) external view;
    function deleteProvenWithdrawal(bytes32, address) external;
    function guardian() external view returns (address);
    function anchorStateRegistry() external view returns (address);
}

interface IASRB {
    function blacklistDisputeGame(address) external;
    function isGameBlacklisted(address) external view returns (bool);
}

contract U21WithdrawalBoundaryTest is Test {
    IPortalB constant PORTAL = IPortalB(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed);

    // proven at L1 block 26429992 (v8, 867 blocks before U21), still unfinalized
    bytes32 constant H1 = 0xcb4d1cae41ae4f41058343d205d1e295eb5e4a55a380f45694e2b88991a1651d;
    address constant S1 = 0x47728c875b7F52a40227d662f83a3C3d0f7E6FBB;
    address constant G1 = 0x86512332B510F40Bb9361dE685cA1e4815dEe5fe;
    uint64 constant T1 = 1794861023;

    // proven 2026-11-09 under v8, finalized under v9 at L1 block 26433013
    bytes32 constant H2 = 0x52f21523f97079446fc97a3b09a636b2f33453378db28e744c53b20b66282e7e;
    address constant S2 = 0xd6BC6261f60feaD499A826bbcaB29513F8Bc8f04;
    address constant G2 = 0x5601a746270ddf8682BFbd1230a2f2bd96e3B7b4;
    uint64 constant T2 = 1794258083;

    struct Entry {
        address game;
        uint64 ts;
        uint256 n;
        address sub0;
        bool fin;
        bytes32 rawPW;
    }

    function _read(bytes32 h, address s) internal view returns (Entry memory e) {
        (e.game, e.ts) = PORTAL.provenWithdrawals(h, s);
        e.n = PORTAL.numProofSubmitters(h);
        e.sub0 = PORTAL.proofSubmitters(h, 0);
        e.fin = PORTAL.finalizedWithdrawals(h);
        e.rawPW = vm.load(address(PORTAL), keccak256(abi.encode(s, keccak256(abi.encode(h, uint256(57))))));
    }

    /// The same storage entry decodes identically through the v8 implementation (block N-1) and the v9 one (block N).
    function test_entriesProvenUnderV8ReadIdenticallyUnderV9() public {
        vm.createSelectFork("l1pre");
        assertEq(PORTAL.version(), "5.8.0");
        Entry memory a1 = _read(H1, S1);
        Entry memory a2 = _read(H2, S2);
        PORTAL.checkWithdrawal(H2, S2); // already finalizable under v8 at N-1

        vm.createSelectFork("l1n");
        assertEq(PORTAL.version(), "6.1.0");
        Entry memory b1 = _read(H1, S1);
        Entry memory b2 = _read(H2, S2);
        PORTAL.checkWithdrawal(H2, S2); // and still finalizable under v9 at N

        assertEq(a1.game, G1);
        assertEq(a1.ts, T1);
        assertEq(a2.game, G2);
        assertEq(a2.ts, T2);
        assertEq(a1.sub0, S1);
        assertFalse(a1.fin);
        assertFalse(a2.fin);
        assertEq(keccak256(abi.encode(a1)), keccak256(abi.encode(b1)));
        assertEq(keccak256(abi.encode(a2)), keccak256(abi.encode(b2)));
        // raw packing: [uint64 timestamp | address disputeGameProxy]
        assertEq(b1.rawPW, bytes32((uint256(T1) << 160) | uint256(uint160(G1))));

        vm.createSelectFork("l1"); // 26433900: H2 was finalized by its owner under v9 at block 26433013
        assertTrue(PORTAL.finalizedWithdrawals(H2));
        vm.expectRevert(abi.encodeWithSignature("OptimismPortal_AlreadyFinalized()"));
        PORTAL.checkWithdrawal(H2, S2);
    }

    /// New v9 permissionless cleanup: the proof entry is deleted but the submitter stays in `proofSubmitters`.
    /// Setup uses the Guardian's documented `blacklistDisputeGame` action (state production can be in).
    function test_deleteProvenWithdrawalLeavesSubmitterResidue() public {
        vm.createSelectFork("l1n");
        IASRB asr = IASRB(PORTAL.anchorStateRegistry());
        // not deletable while the game is neither CHALLENGER_WINS nor blacklisted
        vm.expectRevert(abi.encodeWithSignature("OptimismPortal_DisputeGameNotInvalidated()"));
        PORTAL.deleteProvenWithdrawal(H1, S1);

        address guardian = PORTAL.guardian();
        vm.prank(guardian);
        asr.blacklistDisputeGame(G1);
        assertTrue(asr.isGameBlacklisted(G1));

        vm.prank(address(0xBAD)); // anyone
        PORTAL.deleteProvenWithdrawal(H1, S1);

        (address g, uint64 ts) = PORTAL.provenWithdrawals(H1, S1);
        assertEq(g, address(0));
        assertEq(ts, 0);
        assertEq(PORTAL.numProofSubmitters(H1), 1, "array is not shrunk");
        assertEq(PORTAL.proofSubmitters(H1, 0), S1, "stale submitter remains");
        vm.expectRevert(abi.encodeWithSignature("OptimismPortal_Unproven()"));
        PORTAL.checkWithdrawal(H1, S1);
        // second delete reverts (idempotent, no griefing loop)
        vm.expectRevert(abi.encodeWithSignature("OptimismPortal_Unproven()"));
        PORTAL.deleteProvenWithdrawal(H1, S1);
    }
}
