# ATTACK MATRIX — attack wave (2026-11-17)

Every executed hypothesis of the six lanes (Opus 5.5, ATK-X) and their independent Codex Daybreak mirrors (CATK-X).
One row per kill file. Candidates: **0**. Full experiment tables: `workers/ATK-X-report.md`, `workers/CATK-X-report.md`.
Kill files: **73** (Opus lanes + Codex mirrors). Experiments executed (from the lane reports): A 8, B 9, C ~40, D 8, E 4 fork tests / 9 hypotheses, F 12; mirrors A 9, B 16, C 9, D 12, E 11, F 19.

## Lane A — Old-prestate soundness to arbitrary withdrawal

| Kill file | Hypothesis | Barrier (first line of the file's barrier/result field) |
|---|---|---|
| `rejected/ATTACK-A-01.md` | ATTACK-A-01 — Holocene singular-batch parent-hash check missing in the OLD prestate (kona-client v1.7.0) | Privileged-only input: derivation accepts frames only from `SystemConfig.batcherHash` (OP `0x6887…2985`, Ink |
| `rejected/ATTACK-A-02.md` | ATTACK-A-02 — OLD prestate replaces a block by a deposit-only block on ANY executor error | or TrieDB bug that rejected a valid state would be a separate root cause, present unchanged in BOTH programs |
| `rejected/ATTACK-A-03.md` | ATTACK-A-03 — EVM-stack delta (revm 41 -> 43, op-revm handler rewrite, deposit EIP-7825 exemption moved, FpvmOpTx) | no access-list or authorization-list txs |
| `rejected/ATTACK-A-04.md` | ATTACK-A-04 — Interop consolidation / message-graph deltas in the super-root program | `parse_log_to_executing_message` requires `log.address == Predeploys::CROSS_L2_INBOX && topics.len()==2` |
| `rejected/ATTACK-A-05.md` | ATTACK-A-05 — Remaining v1.7.0 -> v1.9.0 deltas: SDM/post-exec (Lagoon), Bedrock deposit "decoding", std-fpvm I/O |  |
| `rejected/ATTACK-CATK-A-01.md` | ATTACK-CATK-A-01 — singular-batch parent-hash overwrite | The differing field is in batch data accepted only from the configured batcher. An ordinary user |
| `rejected/ATTACK-CATK-A-02.md` | ATTACK-CATK-A-02 — broad execution-error deposit-only fallback | Canonical trie/provider reads succeed with an honest complete oracle. Preimages are hash-bound, so |
| `rejected/ATTACK-CATK-A-03.md` | ATTACK-CATK-A-03 — interop, Lagoon PostExec, and SDM fixes | Interop is disabled and there is no deployed dependency set. OP, Ink, and Unichain set Lagoon to |
| `rejected/ATTACK-CATK-A-04.md` | ATTACK-CATK-A-04 — previously critical trace-extension / zero-root findings | There is no old→new diff. v1.7 already calls `prepare_derivation`, rejects claims before the safe |
| `rejected/ATTACK-CATK-A-05.md` | ATTACK-CATK-A-05 — deposit EIP-7825 gas-cap divergence | The premise is false: v1.7 already lifts the cap for deposits in |
| `rejected/ATTACK-CATK-A-06.md` | ATTACK-CATK-A-06 — non-consensus client changes | `f07f3e0` changes host/RPC serde handling of `isSystemTx` for historical pre-Regolith system |

## Lane B — Historical messenger failure / third-party forced failure

| Kill file | Hypothesis | Barrier (first line of the file's barrier/result field) |
|---|---|---|
| `rejected/ATTACK-B-01.md` | ATTACK-B-01 — Historical value-bearing failed messages left unbacked / unreplayable (L1CDM pool) | pending failures have value 0, matching L1CDM balance 0 on every chain. The 12 replays that still fail fail in |
| `rejected/ATTACK-B-02.md` | ATTACK-B-02 — Historical "finalized in portal, unknown to messenger" objects carrying value (A-068 historical half) | hash is already `successfulMessages=true` (paid pre-Bedrock); L1CDM reverted at |
| `rejected/ATTACK-B-03.md` | ATTACK-B-03 — Forced failure + reordering breaks L1StandardBridge ERC20 accounting / release | 292) — order-independent while |
| `rejected/ATTACK-B-04.md` | ATTACK-B-04 — Third party makes the forced-failed victim message permanently unreplayable | 265-282, :292-295) — no path writes successfulMessages without the call succeeding; the target receives |
| `rejected/ATTACK-B-05.md` | ATTACK-B-05 — Capture of ETH parked in the L1CDM by a forced failure | 245) and failedMessages[v1hash] (:247), where the |
| `rejected/ATTACK-B-06.md` | ATTACK-B-06 — Upgrade/migration between forced failure and replay strands the parked value | after migrate; both replays deliver exactly; L1CDM ends at 0. Pause in between only reverts the replay at :222 |
| `rejected/ATTACK-CATK-B-01.md` | ATTACK-CATK-B-01 — false portal finalization strands an unmapped message | Only four of 32,007 finalizations are false, all OP. Every relay has nonce version 0 and reverts `CrossDomainMessenger: legacy withdrawal already relayed`; its v0 hash was already `successful=true` before the attempted duplicate. The appare… |
| `rejected/ATTACK-CATK-B-02.md` | ATTACK-CATK-B-02 — historical value-bearing failures are stranded or caller-capturable | Exactly four failed hashes carry ETH, totaling 328.236399668390660000 ETH. All four later succeeded through direct zero-value messenger calls, with delays of 7, 90, 5,502 and 10,229 blocks. They are now `failed=true, successful=true`, and e… |
| `rejected/ATTACK-CATK-B-03.md` | ATTACK-CATK-B-03 — forced failure changes StandardBridge ETH/ERC20 settlement | The primitive works: the victim portal hash finalizes and value (if any) moves to L1CDM while the message becomes failed. But arbitrary direct replay then pays the committed ETH recipient or exact ERC20 recipient, drains messenger custody, … |
| `rejected/ATTACK-CATK-B-04.md` | ATTACK-CATK-B-04 — application replay changes identity, deadline, or beneficiary | `test_realApplicationVictimForcedFailedThenSettlesExactly` passes: replay succeeds, L1CDM returns to its pre-state, and the caller gains zero. v9 reinstalls the committed `_sender` before the target call (`CrossDomainMessenger.sol:284-286`)… |
| `rejected/ATTACK-CATK-B-05.md` | ATTACK-CATK-B-05 — ERC721 ordering lets another caller consume the escrow | The deployed bridge requires `msg.sender == L1CDM` and `xDomainMessageSender == 0x420…0014`; direct attacker finalization reverts. `L1ERC721Bridge.sol:102-114` requires the exact `(local,remote,tokenId)` escrow bit, clears it, and performs … |
| `rejected/ATTACK-CATK-B-06.md` | ATTACK-CATK-B-06 — active failed-message ordering exposes a forced-failure freeze | Both orders recover the same three bridge messages and leave the same twelve failed. The remaining barriers are target-local and pre-existing: bare token revert, already-confirmed root, `TransfersBlocked()`, arithmetic underflow, invalid L1… |

## Lane C — Gas cap / cross-layer budget undeliverability

| Kill file | Hypothesis | Barrier (first line of the file's barrier/result field) |
|---|---|---|
| `rejected/ATTACK-C-01.md` | ATTACK-C-01 — Third party forces a victim's messenger withdrawal to `failedMessages`, replay then needs more than the 2^24 cap | / case / gasLimit / finalize min (outcome) / replay min after forced fail / replay − finalize / |
| `rejected/ATTACK-C-02.md` | ATTACK-C-02 — Non-empty "never deliverable" band by minGasLimit under EIP-7825 (live L2CDM 2.2.1 budget) | finalize-min(m) = 518,843 + 1.04838·m (three 64/63 factors: |
| `rejected/ATTACK-C-03.md` | ATTACK-C-03 — Real in-flight OP Mainnet withdrawals with minGasLimit 8,000,000 are stranded or third-party-strandable | finalize minimum 8,886,768 -> finalized + failedMessages; |
| `rejected/ATTACK-C-04.md` | ATTACK-C-04 — Large-calldata messenger withdrawals that L2 accepts but no L1 tx <= 2^24 can deliver | / message / gasLimit (L2 floor branch 21000+40(L+260)) / finalize min tx gas / fits 2^24 / |
| `rejected/ATTACK-C-05.md` | ATTACK-C-05 — 183,600 NEW_ACCOUNT_STATE_GAS reserve pushes value withdrawals to fresh accounts over the cap | Messenger, 1 ETH to a never-touched account: m=0 finalize min 537,760 (relayed); m=15.8M 17,102,209 vs |
| `rejected/ATTACK-C-06.md` | ATTACK-C-06 — Gas-burning / gas-hungry L1 target makes a messenger withdrawal permanently undeliverable |  |
| `rejected/ATTACK-C-07.md` | ATTACK-C-07 — Older budget generations (Bedrock-era formula, version-0 migrated legacy withdrawals) cross the 2^24 edge | contracts with the same formulas; not scanned (lower priority: the edge is formula-determined, sender-chosen). |
| `rejected/ATTACK-C-08.md` | ATTACK-C-08 — Band where one-tx delivery is impossible under the cap (finalize-as-failed + replay is the only path) | both steps are permissionless and each fits 2^24; the message is delivered with all value |
| `rejected/ATTACK-C-09.md` | ATTACK-C-09 — A third party moves a victim's withdrawal INTO the undeliverable band | is fixed at L2 creation by the sender. KILLED. |
| `rejected/ATTACK-CATK-C-01.md` | ATTACK-CATK-C-01 — forced L1 relay failure cannot become permanent under the same cap | The portal delivered through `g=15,382,429`, finalized/recorded failure through `g=15,510,449`, and direct replay delivered through `g=15,981,628`. At `g=15,382,430`, the portal transaction finalized with `failedMessages=true`; the next cap… |
| `rejected/ATTACK-CATK-C-02.md` | ATTACK-CATK-C-02 — large-data and specific-gas creation/finalization gap | There is a real sender-selected gap. A 379,200-byte zero payload fits the demonstrated L2 word edge, while the portal's last delivered word edge is 323,168 bytes; 323,200 is already unfinalizable despite a 3,260,880 calldata floor. Likewise… |
| `rejected/ATTACK-CATK-C-03.md` | ATTACK-CATK-C-03 — value, new-account reserve, and StandardBridge target | All messenger replays delivered, including value to the new account and the deployed bridge call. The bridge replay floor was 27,210. For direct portal withdrawals, the maximum existing-recipient gas limit was 16,053,187 and the new-account… |
| `rejected/ATTACK-CATK-C-04.md` | ATTACK-CATK-C-04 — gas-burning target does not lose relay state | Portal finalization completed, `successfulMessages=false`, and `failedMessages=true`. Direct replay returned normally and again retained `failedMessages=true`. There was no neither-mapping state and no messenger bookkeeping loss. |

## Lane D — Trojan super-root game as protocol attack

| Kill file | Hypothesis | Barrier (first line of the file's barrier/result field) |
|---|---|---|
| `rejected/ATTACK-D-01.md` | ATTACK-D-01 — Trojan super-root game as an eligible withdrawal-freeze (lead L4 / A-023 / PRIM-0503) | Opus 5.5 (user-approved exception). Verdict: KILLED — known root cause + impact not eligible. Score 2 (< 7). |
| `rejected/ATTACK-D-02.md` | ATTACK-D-02 — Overwrite / poison a relayer's good proof with a trojan proof | proofs are keyed by `msg.sender`: `provenWithdrawals[withdrawalHash][msg.sender] = …` |
| `rejected/ATTACK-D-03.md` | ATTACK-D-03 — Wrong-root newest game as a tooling DoS (no trojan needed) | nothing is written on-chain; the user loses prove gas and retries with another index. Off-chain third-party |
| `rejected/ATTACK-D-04.md` | ATTACK-D-04 — Keep default-tooling withdrawals unavailable indefinitely (sustained engine, pricing) | the user can prove against an honest game at any time (`OptimismPortal2.sol:390-492` accepts any proper, |
| `rejected/ATTACK-D-05.md` | ATTACK-D-05 — Compose with the planned OP+Unichain shared migration (FUTURE-ONLY) | KILLED (future-only, no new mechanism; −5). |
| `rejected/ATTACK-CATK-D-01.md` | ATTACK-CATK-D-01 — Trojan super-root as a sustained withdrawal-delay engine | The primitive is real, but the claimed impact is not: |
| `rejected/ATTACK-CATK-D-02.md` | ATTACK-CATK-D-02 — Overwrite a victim or shared-relayer withdrawal proof | `OptimismPortal2.sol:483-484` stores `provenWithdrawals[withdrawalHash][msg.sender]`. The attacker cannot choose the second key. `finalizeWithdrawalTransactionExternalProof` lets anyone finalize using a valid submitter slot, but does not le… |
| `rejected/ATTACK-CATK-D-03.md` | ATTACK-CATK-D-03 — Future shared-game migration amplifies the trojan | OP Mainnet is not yet using a shared multi-chain registry for this path; cross-chain reach is future-only. |

## Lane E — Migration poisoning and orphaned state

| Kill file | Hypothesis | Barrier (first line of the file's barrier/result field) |
|---|---|---|
| `rejected/ATTACK-E-01.md` | ATTACK-E-01 — orphaned gen-2 ASR anchor poisoning alters the planned migrate (KILLED) | 0 occurrences of 0x1c68…/0xD5D0…/0x18DA…/0x318A… in |
| `rejected/ATTACK-E-02.md` | ATTACK-E-02 — orphaned gen-0 ASR (v2.0.0) is attacker-writable (KILLED) | 71-82 (`tryUpdateAnchorState` requires `msg.sender` to be the factory-registered game of its own gameData) and :99-100 |
| `rejected/ATTACK-E-03.md` | ATTACK-E-03 — donations / forced ETH / deposits before migrate break pooled solvency or migrate (KILLED) | lockboxes end at 0 (asserted). Migrator sweeps `portal.migrateLiquidity()` and `oldLockbox.migrateLiquidity(new)` |
| `rejected/ATTACK-E-04.md` | ATTACK-E-04 — advancing the live per-chain ASR anchor before migrate changes the re-initialised legacy ASR or the shared anchor (KILLED) | 547-555, arg at :553) so `rootChanged == false` and the anchor check is skipped (/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol:113-121). The shared |
| `rejected/ATTACK-E-05.md` | ATTACK-E-05 — attacker legacy games created before/at migration survive into or bridge to the shared domain (KILLED) | retirementTimestamp = migration time, AnchorStateRegistry.sol:130-132); legacy DGF type 9 cleared -> |
| `rejected/ATTACK-E-06.md` | ATTACK-E-06 — hidden pre-positioning at the CREATE2 addresses of the shared lockbox/ASR/DGF (KILLED) | none of which an EOA can place at a Safe-derived CREATE2 address — C10/C14). The 5 ETH is lockbox surplus |
| `rejected/ATTACK-E-07.md` | ATTACK-E-07 — attacker forces migrate failure / partial migration / unsafe retry or repeat (KILLED) | 129-166, 287-325, ; OptimismPortal2.sol:528-572); the state-diff shows no attacker-written slot is read except portal resource |
| `rejected/ATTACK-E-08.md` | ATTACK-E-08 — post-migration falsification of the migration validator by 1-wei donations (KILLED: known, no impact) | it is a false alarm in an off-chain review step, sweepable by the owner, moving no value. Same root cause as PASS A |
| `rejected/ATTACK-E-09.md` | ATTACK-E-09 — sticky authorization of the retired per-chain lockbox after migrate (KILLED: known, self-harm only) | withdrawal reverts `ETHLockbox_NoWithdrawalTransactions` (ETHLockbox.sol:157-178); only the owner sweeps it back. |
| `rejected/ATTACK-CATK-E-01.md` | ATTACK-CATK-E-01 — poison orphan/live anchors before OP+Unichain migration | The fresh shared ASR is initialized exclusively from `_input.startingAnchorRoot` |
| `rejected/ATTACK-CATK-E-02.md` | ATTACK-CATK-E-02 — mutate gen-1 anchors or extend a retired factory lineage | Every call fails in E07. `DisputeGameFactory.create` reverts on a zero implementation at |
| `rejected/ATTACK-CATK-E-03.md` | ATTACK-CATK-E-03 — poison migration through legacy or live DelayedWETH storage | All eleven legacy proxies have zero reads and zero writes during migration. The migrator deliberately |
| `rejected/ATTACK-CATK-E-04.md` | ATTACK-CATK-E-04 — pre-position games and withdrawal proofs before migration | The proof records remain, but authority is evaluated through the portal's new shared ASR/DGF. Both |
| `rejected/ATTACK-CATK-E-05.md` | ATTACK-CATK-E-05 — balance, sticky-authorization, or future-address poisoning | E06 pools exactly `200810526200523469952700` wei and zeroes both old lockboxes/portals. Sticky old |
| `rejected/ATTACK-CATK-E-06.md` | ATTACK-CATK-E-06 — partial migration, retry corruption, or repeat migration | The late revert rolls back the entire EVM transaction: every pointer, feature bit, balance, and Safe |

## Lane F — Unsafe targets and surviving system-contract trust

| Kill file | Hypothesis | Barrier (first line of the file's barrier/result field) |
|---|---|---|
| `rejected/ATTACK-F-01.md` | ATTACK-F-01 — Withdrawal into a lockbox the portal does not treat as unsafe (sibling, retired, implementation) | failing experiment + code barrier. |
| `rejected/ATTACK-F-02.md` | ATTACK-F-02 — Forged first relay through any L1CrossDomainMessenger / direct bridge finalization from the portal | failing experiment + code barrier. |
| `rejected/ATTACK-F-03.md` | ATTACK-F-03 — Portal as caller of authority/config contracts of every generation | Ownable: caller is not the owner / |
| `rejected/ATTACK-F-04.md` | ATTACK-F-04 — Sender 0x…dEaD keeps l2Sender == DEFAULT during the call (lockbox guard and re-entrancy guard off) | L2 msg.sender 0x…dEaD needs its key or an L1 contract at 0x…dEaD - 0x1111…1111 (160-bit |
| `rejected/ATTACK-F-05.md` | ATTACK-F-05 — Live ERC20 allowances to portals / L1CrossDomainMessengers spendable by any L2 user |  |
| `rejected/ATTACK-F-06.md` | ATTACK-F-06 — Portal-originated permissionless calls (sibling-portal deposit, L1CDM.sendMessage with xDomainMessageSender = portal) | StandardBridge/ERC721Bridge (other bridge only, v9 src/universal/StandardBridge.sol:113, |
| `rejected/ATTACK-F-07.md` | ATTACK-F-07 — Portal-relayed DisputeGameFactory.create of a tx.origin-authorized type-5 game (Soneium) | cast nonce at L1 26,433,900 = 8537 = |
| `rejected/ATTACK-F-08.md` | ATTACK-F-08 — L2 withdrawal to an address that becomes a portal-trusting contract later (past or future CREATE/CREATE2) | full-population scan + code barrier. |
| `rejected/ATTACK-CATK-F-01.md` | ATTACK-CATK-F-01 — live unfinalized system-target withdrawal | cannot satisfy `onlyOtherBridge`. Outer target choice does not let an attacker choose the committed |
| `rejected/ATTACK-CATK-F-02.md` | ATTACK-CATK-F-02 — current or retired lockbox drain | 168-170 explicitly forbids unlocks during withdrawal execution. The only |
| `rejected/ATTACK-CATK-F-03.md` | ATTACK-CATK-F-03 — messenger/bridge authority laundering | otherMessenger`; bridges conjunctively check exact messenger and committed `otherBridge`. |
| `rejected/ATTACK-CATK-F-04.md` | ATTACK-CATK-F-04 — registry, WETH, factory, and admin mutation | portal-owned token object exists; the only reachable WETH object is self-funded. |
| `rejected/ATTACK-CATK-F-05.md` | ATTACK-CATK-F-05 — sibling portal composition / alias privilege | deterministic but confers no listed role. |
| `rejected/ATTACK-CATK-F-06.md` | ATTACK-CATK-F-06 — benign-at-initiation target gains later privileged code | with no shared protocol target or authority. |

