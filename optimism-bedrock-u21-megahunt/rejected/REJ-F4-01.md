REJ-ID: REJ-F4-01
Title: "Legacy L2OutputOracle-era `provenWithdrawals` entries (portal v1, slot 52) are read by v9 under the Portal2 meaning"

Idea
- Portal v1 (v1.0.0 .. v1.3.0, OP Mainnet 17423158 .. 20062695) stored `provenWithdrawals[hash] = {bytes32 outputRoot;
  uint128 timestamp; uint128 l2OutputIndex}` at `keccak256(abi.encode(hash, 52))` (+1). Portal2 abandoned slot 52
  (`spacer_52_0_32`, op-v9.0.0 src/L1/OptimismPortal2.sol:67) and moved to a 2-level mapping at slot 57.
- If any v9 path (checkWithdrawal, finalize*, deleteProvenWithdrawal, numProofSubmitters, getters) read slot 52 entries, a
  legacy proof could finalize under a game-based check or a stale proof could be consumed.

Killing fact
- Entries still exist: 12,338 hashes first proven before 20062696, 3,281 never finalized (re-derived in this run from
  `evidence/F4/op-portal-withdrawal-events.jsonl`, 77,340 logs, 0 failed chunks); 72/72 sampled entries non-zero @26433900.
- No v9 reader: `test/poc/F4/F4_LegacyStorage.t.sol::test_legacyProvenEntriesExistButAreUnreachable` (24 real entries,
  each matched to the still-deployed L2OO output at its index, x 3 submitters) records every SLOAD of all portal entry
  points: neither slot 52 nor any entry slot is read; no write. `test_fabricatedLegacyProofGivesNothing`: a mature
  fabricated legacy proof gives `OptimismPortal_Unproven` from both finalizers and `deleteProvenWithdrawal`. 3/3 PASS
  (re-run 2026-11-17, `-j 1`).
- Ink / Soneium / Unichain were born on OptimismPortal2 3.10.0 (impl 0xe2f82632…; first impl blocks 21344310 / 21314185 /
  21116362, cast storage of the EIP-1967 slot): no slot-52 entry can exist there.
