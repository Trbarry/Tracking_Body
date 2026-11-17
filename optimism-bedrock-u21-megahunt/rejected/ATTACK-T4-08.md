# ATTACK-T4-08 — Output-root / super-root encoding differs between kona and op-node / the posted claims

Lane ATK-T4. Model: Opus 5.5 (`claude-opus-5-5`, user-approved exception; Mythos 5.2 quota exhausted until 2026-11-22). All runs are local pure computation or passive reads through :7545/:7546. Harness: `test/poc/attack-wave/T4/` (kona-client v1.7.0 = old type-9 prestate 0x031ac6f1, kona-client v1.9.0 = new prestate 0x03e5a548, each built with its own tag Cargo.lock — 0 package versions outside the tag lock; op-node = /home/user/ethereum-optimism/op-v9.0.0).

**Sequence tried.** 1,500 random output roots and 1,500 super roots (1-8 distinct chains, chain IDs up to 2^64-1,
timestamps up to 2^64-1) per side; plus 4 real type-9 claims on OP: games 0x675e956b (21377, IN_PROGRESS, old
prestate), 0x2f55f48e, 0x5d62795e (21308), 0x42d0c7b4 — output root from the L2 block (state root, Isthmus
withdrawalsRoot = message-passer storage root, block hash), then SuperRoot v1 [(10, root)].

**Result.** 0 divergences; all 4 recomputed super roots equal `rootClaim()` for kona v1.7.0, v1.9.0 and op-node
(`evidence/attack-wave/T4/real-receipts-and-roots.txt`). Duplicate chain IDs were excluded (closure C12).

**Verdict.** KILL. Score 0.
