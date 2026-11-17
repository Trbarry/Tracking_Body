# ATTACK-T1-14 — Proof-program fixes vs prestates already deployed (games created under a pre-fix prestate)

Lane ATK-T1, Opus 5.5. Target 14 (rows 31/33). Kill type: executed census + prior executed kills (Lane A, CATK-A).

**Condition.** Kona 3.1.1/3.1.2 (trace extension, zero-root acceptance) and MIPS64 syscall/eventfd fixes (rows 31/33): games created
under a prestate built before a fix stay judged by that program after the prestate switch.

**Executed** (`T1_Extra.t.sol::test_T1_13_prestateGenerations`, L1 @ 26433900): live type-9 `gameArgs` on OP/Ink/Unichain all carry
prestate 0x03e5a548…37c9 (kona-client v1.9.0) and VM 0xaCc005DC…5cfA (= registry v9 MIPS64 1.10.1); in-progress type-9 games among
the last 120 of each factory still on the OLD prestate (0x031ac6f1…): OP 74, Ink 7, Unichain 75 (new: 11 / 1 / 10). Soneium has no
proof program (type 5, permissioned).

**Barrier.** The old-prestate population exists and is judged by kona-client v1.7.0; Lane A diffed v1.7.0 -> v1.9.0 and the MIPS
deltas and killed every soundness difference with an executed or code barrier (ATTACK-A-01..05, ATTACK-CATK-A-01..06; in
particular CATK-A-04: trace-extension / zero-root fixes were already in v1.7.0, no old->new diff). The 1.10.1 VM is shared by both
prestates, so the MIPS64 fixes apply to old-prestate games too (cast at 26433900: OP games #21330/#21370 old prestate and #21385 new prestate all have `vm()` = 0xaCc005DC…5cfA). No new precondition from this lane. Score <= 0.
