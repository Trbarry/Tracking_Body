# Orchestrator check — are non-retired games bound to the portal's CURRENT AnchorStateRegistry?

Why: `AnchorStateRegistry.isGameRegistered` no longer compares the game's own registry with the
registry being asked (PASS A PRIM-0903, blind; the audit track ranks the removed binding as its
first mutation target). Safety then rests on: every game that the current registry does not treat
as retired was created by an implementation bound to that same registry.

Read at L1 block 26433900 through the archive proxy (passive `eth_call`s only).

| Chain | Portal ASR | retirementTimestamp | games | first non-retired index | that game's own `anchorStateRegistry()` |
|---|---|---|---|---|---|
| OP Mainnet | 0x23B2C62946350F4246f9f9D027e071f0264FD113 | 1753379243 (2025-07-24) | 21389 | 9828 | same as portal ASR |
| Ink | 0xEe018bAf058227872540AC60eFbd38b023d9dAe2 | 1753379243 (2025-07-24) | 2640 | 922 | same |
| Soneium | 0x4890928941e62e273dA359374b105F803329F473 | 1753380095 (2025-07-24) | 8537 | 2841 | same |
| Unichain | 0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9 | 1753380731 (2025-07-24) | 17691 | 6186 | same |

Per chain four games were sampled (first two after the cut, the midpoint, the latest): all 16 are
bound to the portal's current registry. So the first game created after each chain's retirement
cut already used an implementation bound to the new registry.

NOT established: that EVERY post-cut game on each chain is bound to the current registry (a later
implementation registration pointing at another registry would break the monotonic argument).
Exhaustive check = one `anchorStateRegistry()` call per post-cut game (OP 11,561; Ink 1,718;
Soneium 5,696; Unichain 11,505) — requested from worker F5 as part of its per-chain census.

## Exhaustive result (from worker F5's saved census `evidence/F5/registry-binding-check.json`, block 26433900)

| Chain | games scanned | non-retired | bound to portal's current ASR | foreign | getter failures | registries of retired games |
|---|---|---|---|---|---|---|
| OP Mainnet | 21389 / 21389 (contiguous) | 11561 (from idx 9828) | 11561 | 0 | 0 | 0x18dac71c… (7110), 0x1c68ecfb… (2718) |
| Ink | 2640 / 2640 | 1718 (from idx 922) | 1718 | 0 | 0 | 0xde744491… (470), 0x2fc99fd1… (452) |
| Soneium | 8537 / 8537 | 5696 (from idx 2841) | 5696 | 0 | 0 | 0x61f89a38… (1486), 0x190b6ece… (1355) |
| Unichain | 17691 / 17691 | 11505 (from idx 6186) | 11505 | 0 | 0 | 0x318a642d… (3731), 0xd5d0e176… (2455) |

Every game created before each chain's retirement cut points at an OLDER registry; every game after it
points at the current one. The missing `isGameRegistered` registry-binding check is therefore not
exploitable with any game that exists today: the retirement timestamp, not the binding, is what
excludes the old-registry games. CLOSED as C15 (failing experiment over the full population).
Reopen if: the retirement timestamp of a current ASR is ever lowered/reset below an old-registry game's
creation time, a new ASR is installed without a retirement bump (planned `migrate` creates fresh
ASR + DGF — check that path), or a factory registers an implementation bound to another registry.
