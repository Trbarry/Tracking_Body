# KNOWN-FINDINGS-BLACKLIST — root causes a triager will call "known"

Worker F3 (Track B). Grouped by root-cause family (vocabulary in `AUDIT-FINDINGS.json -> meta.root_cause_vocabulary`).
Each entry: **root cause** — exact condition that made it exploitable — fix or status — source (report id, page).
Part 2 lists what remains LIVE BY DESIGN at v9 (acknowledged / won't fix / documentation-only). A candidate whose
root cause matches any entry in Part 1 with an intact fix, or any entry in Part 2, scores "-6 known issue" unless
it adds a reachability condition the report explicitly excluded.

Abbreviations: S23a = Sherlock Bedrock contest 2023-01, S23b = Sherlock fix review 2023-03, SFP = Sherlock fault-proof
contest 2024-03, CC25 = Cantina interop-portal contest 2025-04, SPI = Spearbit interop-portal/U16 2025-05.

## Part 1 — Known root causes (with the condition and the fix)

### 1. Gas accounting on non-replayable exits
| Root cause | Exploit condition | Fix / status | Source |
|---|---|---|---|
| Min-gas check performed before later SSTORE/call prep | direct withdrawal with gasLimit within ~5k of real need; any third party finalizes with exact gas | check at the call site (`SafeCall.callWithMinGas`) | S23a H-1, M-8 |
| 63/64 rule ignored | withdrawal gasLimit >= 952,192 | 64/63 + 40k in `hasMinGas` | S23a H-2; S23b H-3 |
| Messenger cannot record success/failure after the target call | low user min gas, or long message (memory expansion + hashing) | 40k reserve + `hasMinGas` pre-check; **large messages left open until v9** | S23b M-1, M-4, M-6; Trust M-3 (p11-14, acknowledged 2023-12) |
| Migrated OVM withdrawals carry synthetic gas limits | legacy withdrawal needing > 135,175 gas (inner min gas 0) or over-estimated outer limit | migration computation changed | S23b H-1; S23a M-4 |
| baseGas undercounts wrapper calldata / second 63-64 at proxy / relay buffer 5k short | tight min gas | partly fixed; rest acknowledged | S23b M-2; Trust M-2, L-5; U21 3.1.16 |
| Deposits with no / too little gas | `_gasLimit` 0 or < calldata cost | `minimumGasLimit`, 120 kB cap | S23a M-11; S23b M-5; Trust L-1, L-7 |
| Unsatisfiable withdrawal gasLimit (hash commits to it) | gasLimit above what one L1 tx can supply (now EIP-7825 2^24) | **won't fix since 2022** | Zeppelin 2022-09 M-04; U21 3.1.4, 3.1.10 |
| L2 predeploy computes baseGas with old constants after an L1-only release | any messenger withdrawal after U21 until an L2 hard fork | acknowledged; portal revert is the stop-gap | U21 3.1.3 |
| try/catch starved through EIP-150 | caller supplies gas so the callee fails and the tail succeeds | fuzz test + semgrep + monitoring, no code change | IRI L-01; U13 5.2.6 |
| Precompile call OOG stored as the preimage | caller-controlled gas to `loadPrecompilePreimagePart` | `_requiredGas` | Spearbit No-MIPS 5.1.1 |

### 2. Reentrancy sentinels and initializers
| Root cause | Exploit condition | Fix / status | Source |
|---|---|---|---|
| Nested finalize resets `l2Sender` | withdrawal that finalizes another | non-reentrancy via `l2Sender` | Zeppelin 2022-05 M-04 |
| Messenger `nonReentrant` reverted inside portal finalize | attacker message re-enters portal for a victim withdrawal | reentrant relay recorded as failed instead of revert | S23a H-3 |
| Initializer re-run resets `xDomainMsgSender` | publicly executable upgrade tx run from inside a replayed failed message with value | write only if zero + post-call assert | Trust H-1 (p8-9) |
| Initializer resets metering params | any upgrade | init only when unset | Trust L-2 |
| `upgrade()`/`initialize()` callable by anyone if not atomic with the proxy upgrade | implementation switched without init in the same tx | ProxyAdminOwnedBase | CC25 3.2.11 |
| Uninitialised / real-valued implementations | implementation contracts | `_disableInitializers`, zero values | Zeppelin 2022-05 L-02/L-03; Cantina MCP 3.1.1 |
| StorageSetter upgrade zeroes one byte; OZ v5 initializer layout | v5-layout implementation shipped | documented / not stated | U19 3.1.2; OPCMv2 3.3.15 |

### 3. Proof, game and registry binding
| Root cause | Exploit condition | Fix / status | Source |
|---|---|---|---|
| Inverted finalization-period comparison | any output | corrected | Zeppelin 2022-05 H-01 |
| Re-prove restarts the timer | anyone re-proves a victim's withdrawal | v1.0.0 gate; superseded by per-submitter proofs at v1.4.0 | ToB 2023-01 |
| Re-proposed output strands a proof | challenger deletes and re-proposes at another index | re-prove when the root at the stored index changed | S23a M-13 |
| GameType truncated to uint8 | >= 256 game types | uint32 | SFP M-1 |
| Game of registry B accepted by registry A | shared factory or registry replaced | `asr == address(this)` (v4–v6), **removed at v7**, validator-only from v8 | CC25 3.2.9; OPCMv2 3.3.12; U20 3.1.6; U19 3.2.7 |
| Portal does not chain-bind legacy game roots | wrong-chain legacy type respected, or shared factory | not fixed (validator / operator) | U19 3.3.2; U20 3.2.5; U21 3.1.1, 3.1.18, 3.2.10 |
| Super-root preimage ordering / timestamp not checked by the portal | super roots active | left to the proof program | CC25 3.1.6, 3.1.7 |
| Output-root version unchecked in `hashOutputRootProof` | none found (hash equality binds it) | acknowledged | Interop L2 3.2.15 |
| Prove allowed after finalize; proofs against any old valid game | always | by design | CC25 3.1.5, 3.2.4 |
| Migration invalidates pending proofs | proofs pending at `migrateToSuperRoots` / shared-game migration | by design (re-prove) | CC25 3.2.7; U21 3.2.1 |
| kona accepted an invalid claim (trace extension; zero root) | kona game type | fixed in kona | Kona 3.1.1, 3.1.2 |
| Blob preimage evaluation points not roots of unity | blob batches | fixed (GHSA-r3cr-h2xh-wh4q) | aleph_v 2025-04 |

### 4. Anchor state and game-type lifecycle
| Root cause | Exploit condition | Fix / status | Source |
|---|---|---|---|
| Anchor accepts a far-future block/sequence number | a game with such a claim resolves for the defender | `challengeRootL2Block` on output-root games only | SFP M-2; U21 3.2.11 |
| Blacklisted anchor game bricked game creation | attacker front-runs the guardian with `setAnchorState` | blacklist check removed from `getAnchorRoot` | U13 5.1.2 |
| Anchor may be / stay a blacklisted or legacy game | anchor set before invalidation; registry upgrade keeps it | accepted | CC25 3.2.1, 3.2.15, 3.2.18; U20 3.1.4 |
| Unauthenticated starting anchor / prestate / respected type at deploy or migrate | operator input wrong | off-chain validation only | U20 3.1.1, 3.2.1; U21 3.1.17, 3.1.19; OPCMv2 3.2.3 |
| Respected-type switch and retirement are separate calls | old-type game created between them | not stated (Informational) | U19 3.3.1 |
| Prove rejects / finalize accepts after a type change | guardian changes type without retiring | superseded by creation-time snapshot | U13 5.2.2; SFP families 003-M, 007-M |
| Game created before its type is respected blocks the UUID | new type registered before being respected | acknowledged | U13 5.2.5 |

### 5. Dispute game mechanics (bond-level unless stated)
| Root cause | Exploit condition | Fix / status | Source |
|---|---|---|---|
| Creator credited by `tx.origin` | smart-wallet proposer | factory passes creator (permissionless games) | SFP M-3 |
| Move not bound to the parent claim | L1 re-org | `_disputed` argument | SFP M-4 |
| Richer attacker out-bonds honest defender | economics | by design | Spearbit No-MIPS 5.1.3, 5.4.3 |
| `challengeRootL2Block` bond priority / callable late / unpermissioned on the permissioned game | see ids | acknowledged / open | No-MIPS 5.1.4, 5.2.2; U19 3.2.10 |
| Clock, depth, extension, step-after-resolve edge cases | constructor parameters / timing | later constructor validation | No-MIPS 5.1.2, 5.2.1, 5.2.3, 5.2.6; SFP H-families 002–010 (not in the final report) |
| Pause at closeGame latches REFUND; claimCredit blocked during pause | pause window | fixed | CC25 3.1.1; SPI 5.3.1 |
| DelayedWETH unlock unbounded / sub-accounting by convention | caller misuse | intentional | IRI I-02; SFP family 008-M |
| Stale `gameArgs` after 2-arg `setImplementation`; old-style implementation under new factory; calldata injection into clones; extraData vs args ambiguity | privileged misuse / future game types | all acknowledged | U17 3.1.1; U18 3.1.1–3.1.3, 3.3.1 |

### 6. Pause
| Root cause | Exploit condition | Fix / status | Source |
|---|---|---|---|
| No unpause / pause not symmetric across domains | owner pause; L2 messenger paused while L1 sends | pause removed from messengers at v1.0.0, global pause at v1.2.0 | Zeppelin 2022-05 M-06; S23a M-12 |
| Changing the lockbox pointer or the lockbox feature flag unpauses | privileged change while paused | one function gated (v4.0.0); `setFeature` gated from v5.0.0 | SPI 5.1.3; U16a 5.1.3 |
| Pause recorded against an identifier nobody reads | guardian/tooling uses the portal address after U21 | intended | U21 3.1.2, 3.2.14 |
| Deposits, `migrateLiquidity`, admin paths not paused | pause active | by design / not stated | CC25 3.2.2, 3.2.6 |
| Pre-signed pause signatures not bound to target | module pointer changed | acknowledged | DPM MiloTruck L-3; SPI 5.1.4 |

### 7. Upgrade / migration sequencing and storage
| Root cause | Exploit condition | Fix / status | Source |
|---|---|---|---|
| Legacy messenger storage not visible to new code -> double relay | v0 message relayed before Bedrock | layout aligned | S23b H-2 |
| Upgrade scripts write removed variables / default configs | any scripted upgrade | acknowledged | Trust L-4; Cantina MCP 3.1.7, 3.2.7 |
| Storage gaps inconsistent; one slot skipped in the messenger | future layout change | acknowledged | Zeppelin 2022-09 M-08; Trust L-3 |
| Legacy portal spacers not cleared | chain upgraded from v2/v3 layout | decided: never clear | SPI 5.3.6 |
| Chains that skipped v4.0.0 have no lockbox | U15 -> U16a | expected; v9 deploys one | U16a 5.2.5; U21 3.1.12 |
| Disabling the lockbox feature strands funds | privileged toggle | v9: cannot be disabled | U16a 5.2.1 |
| Interop enabled before liquidity pooled | L2 activation before L1 migration | redesign | Interop Contracts 5.2.1 |
| Delays are implementation immutables: every swap re-prices old proofs, games and bonds | chain with non-uniform delays | acknowledged (U22) | U21 3.1.5, 3.1.9, 3.1.13, 3.1.15 |
| Migration residue: uncleared game types, sticky portal authorizations, re-migration, partial migration, chain-0 governance | shared-lockbox migration | documentation only | CC25 3.2.14, 3.2.17; OPCMv2 3.2.4, 3.2.5, 3.3.5, 3.3.6, 3.3.10; U21 3.1.7, 3.2.3 |
| Chain operator can make OPCM upgrades revert (batcher hash, renounced owner) | SystemConfig owner action | acknowledged | OPCMv2 3.2.1; U19 3.2.4; U21 3.2.12, 3.2.13 |
| CREATE2 collisions / front-run deploy | same salt | fixed | U13 5.2.4; OPCMv2 3.2.6 |
| Validator / VerifyOPCM blind spots | privileged misconfiguration | mixed | VerifyOPCM 5.1.1, 5.2.1; U19 3.2.1–3.2.9; U20 3.1.2, 3.1.3 |

### 8. VM and derivation
| Root cause | Exploit condition | Fix / status | Source |
|---|---|---|---|
| mmap wrap / no GC in 32-bit MIPS | program steered to exhaust address space | superseded by MIPS64 | Cantina MIPS 3.1.1, 3.2.1 |
| Instruction semantics differ from spec or from Go (srav, add overflow, j/jal, bgezal/bltzal, SLL/SLLV, futex, getrandom, syscall error registers) | program executes the instruction | most fixed; several 32-bit ones only acknowledged | Cantina MIPS 3.3.x; Base M-01; Spearbit MT-Cannon; 3DOC 2025-06; Cannon fix review |
| Deposit identified by magic nonce; frame decoding; unsafe casts; p2p panics; signing hash without chain id | malicious sequencer/batcher or peer | fixed / accepted | SigmaPrime OPB-01..11; S23a M-1, M-3, M-6, S-24 |
| kona derivation divergences and panics (34 items) | mostly malformed batcher data or config changes near the proof window | **acknowledged, unfixed at report time** | Kona 3.3.1, 3.3.2, 3.4.1–3.4.32 |

### 9. Bridges and tokens
Unauthenticated refund path (Zeppelin 2022-05 C-01, fixed), flipped token pair on refund (H-02), ERC721 asymmetry and
`safeTransferFrom` (Zeppelin 2022-09 M-01, L-08), mintable-interface detection (M-02; S23a M-5), fee-on-transfer and
rebasing tokens (documented), undeliverable targets (documented), SuperchainERC20 same-address assumption
(Interop Contracts 5.1.2, acknowledged).

## Part 2 — Live by design at v9 (acknowledged / won't fix): do not report on their own

1. A third party can force the FIRST relay of someone else's messenger withdrawal to fail (it is stored as failed and
   must be replayed; value waits in L1CDM) — Trust M-1, acknowledged; reentrant-relay branch unchanged at v9.
2. Withdrawals with an unsatisfiable gas limit or an oversized payload can never be finalized — Zeppelin 2022-09 M-04;
   U21 3.1.4, 3.1.10. Deployed L2 messengers under-quote gas after U21 — U21 3.1.3.
3. Messages to unsafe targets or already-relayed legacy messages can be proven but never finalized at v9 (source
   comment in the portal); ETH minted to an aliased sender on a failed deposit is stranded — U21 3.1.14; Zeppelin 2022-09 M-07.
4. `prove` works after finalization, for any claim-valid game of any age, any number of times per submitter; deleted
   proofs leave `proofSubmitters` stale — CC25 3.1.5, 3.2.4; U21 3.2.1.
5. The anchor may be a blacklisted, retired or legacy game and `getAnchorRoot` ignores the blacklist — U13 5.1.2;
   CC25 3.2.1, 3.2.18; U21 3.2.11. Starting anchors, prestates and respected types are trusted operator inputs —
   U20 3.1.1, 3.1.4, 3.2.1; U21 3.1.19.
6. No atomic "retire + switch respected type"; games created under a then-respected type stay valid unless retired
   or blacklisted — U19 3.3.1.
7. Registry identity of a game is enforced by deployment discipline and the off-chain validator, not by the
   registry — OPCMv2 3.3.12; U20 3.1.6. Legacy game roots are not chain-bound by the portal — U19 3.3.2; U20 3.2.5.
8. `tx.origin` proposer authorisation; super-permissioned games are DEFENDER_WINS at creation — U20 3.2.4.
   `challengeRootL2Block` is permissionless on permissioned games — U19 3.2.10.
9. Shared ETHLockbox: no per-portal accounting, authorizations are permanent, chain 0 governs shared contracts —
   CC25 3.2.14, 3.2.17; OPCMv2 3.3.10; U21 3.1.7.
10. `SuperchainConfig.pause(address)` accepts any identifier; only the lockbox (or zero) matters at v9; deposits and
    admin liquidity moves are not paused — U21 3.1.2; CC25 3.2.2, 3.2.6.
11. `initialize()` can be called where `upgrade()` was intended; OPCMv2 re-runs initializers on every upgrade —
    SPI 5.1.1; OPCMv2 3.3.13.
12. Proof maturity, game finality and WETH delays are implementation immutables — U21 3.1.5, 3.1.9, 3.1.13, 3.1.15.
13. Factory `gameArgs` survive a 2-arg `setImplementation`; factory does not version-check implementations; clones
    do not check calldata length — U18 3.1.1, 3.1.2, 3.1.3, 3.3.1.
14. Well-funded attacker vs honest defender; DelayedWETH unbounded unlock; bond-level game quirks — No-MIPS 5.1.3,
    5.1.4; IRI I-02.
15. Chain operator can block OPCM upgrades of its own chain (and a multi-chain bundle) — U21 3.2.12, 3.2.13.
16. Deposit griefing by filling the resource limit; large-calldata message griefing — S23a M-2 (also Immunefi known issues).
17. kona: 2 Medium + 32 Low acknowledged at commit 86910c91 (whether later kona releases fixed them is not in the corpus).
18. EIP-1559 parameters unset in SystemConfig mean "use chain defaults" — U13 5.1.1.

## Part 3 — Publicly disclosed but never validated (Sherlock FP judging repository)

Eleven "High" and twenty "Medium" submission families were excluded from the final report by the contest rule
(game-internal root causes out of scope unless the air-gap is bypassed). Their root causes are public and several
were later fixed (clock extension, resolution ordering, anchor rules). Sixteen are recorded in
`AUDIT-FINDINGS.json` with `finding_id` prefixed `fam-`. A resubmission of any of them is a duplicate.
