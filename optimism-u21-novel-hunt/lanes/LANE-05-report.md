# LANE 05 — Proof lifecycle and permissionless deletion

Target: `OptimismPortal2` v6.1.0 (`op-contracts/v9.0.0`, impl `0xb20b23af6071405c37ddda0c0640e8ebb7899645`,
identical impl behind the OP Mainnet, Ink, Soneium and Unichain portal proxies) with `AnchorStateRegistry`
v4.0.0 (impl `0x2b27299c…`, identical behind the four ASR proxies), `DisputeGameFactory` v1.6.1 and the
deployed game implementations. All behavioural claims below were executed against the real deployed
bytecode on the `l1` fork (block 26433900) unless marked "source only".

Verdict: **the notice's claim holds.** `deleteProvenWithdrawal` can only remove a proof that can never
finalize; no candidate. One reusable primitive outside the delete function itself (PRIM-0503, trojan
super-root game) is reported with an honest low score.

## 1. State machine of one proof slot `provenWithdrawals[h][s]`

```
            prove (msg.sender == s, not paused, target safe,
                   game = DGF.gameAtIndex(i): isGameProper ∧ wasRespectedWhenCreated ∧ status != CW,
                   now > game.createdAt, hash(outputRootProof) == game root for this chain,
                   MPT inclusion of h)
  EMPTY ───────────────────────────────────────────────────────────────▶ PROVEN(game, ts = now)
    ▲                                                                        │  │
    │ delete (anyone, any time, also paused, also if h finalized):           │  │ prove again by s: overwrite,
    │   game.status() == CHALLENGER_WINS  ∨  ASR_current.blacklist[game]     │  │ ts reset, array gets a duplicate
    └────────────────────────────────────────────────────────────────────────┘  ▼
                                                                         PROVEN(game', ts')
  finalize(tx, s) by anyone: not paused, !finalized[h], ts != 0, ts > game.createdAt,
      now - ts > 604800, ASR_current.isGameClaimValid(game)   →  finalized[h] = true  (slot is NOT cleared)
```

`proofSubmitters[h]` is a side list: `push(msg.sender)` on every prove, never read on-chain, never pruned.

`isGameClaimValid(g)` = registered in `ASR.disputeGameFactory` ∧ ¬blacklisted ∧ `createdAt > retirementTimestamp`
∧ ¬paused ∧ `wasRespectedGameTypeWhenCreated` ∧ resolved ∧ `now − resolvedAt > 302400` ∧ `status == DEFENDER_WINS`.

Root used at prove time: `rootClaimByChainId(systemConfig.l2ChainId())` for game types {4,5,7,9,10}
(`GameTypes.isSuperGame`, identical in v8 and v9), `rootClaim()` otherwise. `l2ChainId()` = 10 / 57073 / 1868 / 130.

## 2. Invariants and their status

| # | Invariant | Status |
|---|---|---|
| I1 | deletable(slot) ⇒ slot can never pass `checkWithdrawal` under the current registry | holds (REJ-0501) |
| I2 | deletable is monotone: once true it stays true | holds: status write-once, no un-blacklist (ASR has 5 mutators) |
| I3 | a write to `(h, s)` never changes `(h, s')`, `finalizedWithdrawals`, or ETH custody | holds (REJ-0502, REJ-0506) |
| I4 | only `s` can create/overwrite `(h, s)`; anyone can zero it only when dead | holds |
| I5 | a proof stored under v8 (or earlier) has the same meaning under v9 | holds (REJ-0504) |
| I6 | no proof stored before a registry swap is usable after it | holds, double-locked (REJ-0505) |
| I7 | `proofSubmitters[h]` enumerates live proofs | **false** (PRIM-0502; off-chain relevance only) |
| I8 | every permanently dead proof is deletable | **false** (PRIM-0504: retired, post-swap; cleanup gap only) |
| I9 | a proof built from true L2 state is only ever accepted against a true game | **false for super-root types** (PRIM-0503) |

## 3. Work items from the brief

1. **Source read + v8 diff.** Portal diff: new `deleteProvenWithdrawal`, `paused()/guardian()/superchainConfig()`
   through `ethLockbox`, `L1CDMCallFailed` revert, lockbox-state assertion; prove/check logic unchanged.
   ASR diff: `systemConfig` → spacer, `ethLockbox` appended (slot 6, offset 12), pause/guardian through the
   lockbox; predicates unchanged. DGF, SuperFaultDisputeGame, FaultDisputeGame, SuperPermissionedDisputeGame:
   formatting only. ZKDisputeGame 2.0.1→2.1.0: `wasRespectedGameTypeWhenCreated` computed before the parent
   check plus "respected child needs respected parent" (type 10 is not registered on any of the four chains).
2. **Deletion predicate.** Full boundary matrix in PRIM-0501 (`DeletePredicateTest.test_predicate_matrix`).
   Not-registered / not-respected entries cannot exist (prove requires both; same DGF proxies before and
   after U21). Retirement cannot move backwards. Nothing deletable-now can become valid later.
3. **Data-structure integrity.** No removal from the array at all; duplicates on re-prove; stale entries
   after delete; no on-chain loop → no gas griefing; no index → no cross-submitter confusion; delete works
   while paused and on finalized withdrawals with no effect beyond the slot (REJ-0502, REJ-0506, PRIM-0502).
4. **Submitter identity.** Attacker shadow proofs never block, delay, overwrite or get selected instead of
   the victim's proof; respected-ness is one frozen flag at both prove and finalize (REJ-0503).
5. **Cross-version.** 41 real v8-era proofs (blocks 26425493–26429992) and 3 v9-era proofs surveyed; one
   (tx `0x1214545b…`, 119.59 ETH messenger withdrawal) driven to finalization under v9 by an unrelated caller.
   U21 changed no game type, respected type, retirement timestamp, ASR/DGF proxy on any of the four chains
   (PRIM-0505, table below). Types 0/1 were already unset before U21; Soneium already respected type 5.
6. **Future migration.** `OPContractsManagerMigrator.migrate` deploys fresh lockbox/DGF/ASR and repoints the
   portal atomically. Simulated the portal-side swap with the real implementations: old proofs die by
   registration (factory-dependent clone address) and by the fresh `retirementTimestamp`; twin games in the
   new factory do not resurrect them (REJ-0505, PRIM-0504).

## 4. Chain facts read (pre = `l1pre` 26430858, post = `l1` 26433900)

| Chain | ASR proxy | DGF proxy | respected pre/post | retirementTimestamp pre/post | gameImpls pre == post | ASR.ethLockbox == portal.ethLockbox (post) |
|---|---|---|---|---|---|---|
| OP | 0x23B2C629… | 0xe5965Ab5… | 9 / 9 | 1753379243 / same | yes (5, 9 set; 0,1,8,10 unset) | yes 0x322b47Ff… |
| Ink | 0xEe018bAf… | 0x10d7B350… | 9 / 9 | 1753379243 / same | yes | yes 0xbd4AbB32… |
| Soneium | 0x48909289… | 0x512A3d2c… | 5 / 5 | 1753380095 / same | yes (5 only) | yes 0x67B4de6F… |
| Unichain | 0x27Cf508E… | 0x2F12d621… | 9 / 9 | 1753380731 / same | yes | yes 0x08bA0023… |

OP ASR slot 6: pre `0x…00688271ab00000009`, post `0x322b47ff1fa8d5611f761e3e275c45b71b294d4300000000688271ab00000009`.
OP DGF census of non-retired games (idx 9828..21388, 11,561 games): type 0 → 8029 DEFENDER_WINS / 48 CHALLENGER_WINS;
type 8 → 2168 / 22; type 9 → 1199 / 10 / 85 IN_PROGRESS (oldest 3.48 d). All `wasRespectedGameTypeWhenCreated`.
No blacklist event and no `WithdrawalProofDeleted` event on any of the four portals up to block 26434070.

## 5. Primitives

- PRIM-0501 exact delete semantics and boundary matrix.
- PRIM-0502 append-only, unauthenticated, never-pruned `proofSubmitters`.
- PRIM-0503 trojan super-root game (invalid game, correct per-chain output root) accepts honest proofs.
- PRIM-0504 dead-but-undeletable proofs; blacklist check relative to the current registry.
- PRIM-0505 all games since 2025-07-24 remain proving targets; U21 changed nothing in the game landscape.

## 6. Why PRIM-0503 is not a candidate

On-chain facts are reproduced (`TrojanGameTest`): anyone can create a respected type-9 game whose super root is
non-canonical (extra chain entry, or a duplicated chain-10 entry) but whose chain-10 output root is the true
one; the portal accepts an unmodified honest proof against it; after CHALLENGER_WINS the proof is dead and
anyone deletes it. Under the legacy output-root types this could not happen. The monorepo's own selector
(`op-node/withdrawals/utils.go:211-246`, used by `op-chain-ops/cmd/withdrawal/prove.go`) would pick such a game.
But: the prover picks `_disputeGameIndex`; nothing is stolen or frozen; the effect is a restart of the 7-day
wait plus wasted gas — "temporary inconvenience" under LANE_CONTEXT §6. Score ≈ 3
(+2 permissionless, +2 fork repro, +2 cross-contract, +1 deterministic, +1 multi-chain, −3 no eligible impact,
−2 victim-side game selection). Not verified: which production front-ends auto-select the newest game; whether
the attacker's bond is recoverable in practice (needs his own honest counter-claim to stay uncountered).

## 7. Not done / open questions

- `eth_getLogs` older than ~10k blocks was unavailable, so proofs older than 2026-11-16 00:53 UTC and any
  historical proof pointing at one of the 80 CHALLENGER_WINS games were not enumerated.
- The prebuilt v9 `out/` was not present, so deployed-vs-source bytecode equality was not checked; all tests
  hit the deployed bytecode directly, source line references are to the pinned v9 tree.
- The migration was simulated at the portal level (same-lockbox variant, fresh proxies via `vm.etch` of the
  existing proxy code + real implementations), not by executing `OPContractsManagerV2.migrate`.
- Ink / Unichain / Soneium were checked by configuration reads and shared implementation addresses, not by
  re-running the fork tests against their proxies.
- Whether the fault-proof program / op-challenger really rejects every non-canonical super-root encoding
  (extra chain, duplicate chain id, far-future timestamp) was taken from the solver's hash-equality design
  (source only), not executed.

## 8. Files

- Primitives: `primitives/PRIM-0501.md` … `PRIM-0505.md`
- Rejected: `rejected/REJ-0501.md` … `REJ-0507.md`
- PoCs: `test/poc/lane05/{Ifaces.sol,Lifecycle.t.sol,CrossVersion.t.sol,Migration.t.sol,Trojan.t.sol,Survey.t.sol,proofs.json,provetxs.json,README.md}`
  (working harness `/home/user/u21-work/lane05`, 9 tests passing)
- Evidence: `evidence/lane05-forge-test-output.txt`, `lane05-trojan-trace.txt`, `lane05-proven_pre-logs.json`,
  `lane05-proven_post-logs.json`, `lane05-finalized-logs.json`, `lane05-op-games-12000-21388.json`,
  `lane05-op-games-8500-11999.json`
