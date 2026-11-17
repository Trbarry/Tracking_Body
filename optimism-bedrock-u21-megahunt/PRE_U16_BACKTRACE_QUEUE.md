# PRE-U16 BACKTRACE QUEUE (PASS B input)

Each row is a persistent object or state that exists on mainnet today, was (or may have been)
created under an older release, and is consumed by U21-era code. Priority P0 = could change a
PASS A closure; P1 = new lineage; P2 = context. Owner = worker that takes it. Status starts QUEUED.

PASS A reached back only to v7.0.0. "Pre-U16" here therefore means everything from Bedrock
(and targeted OVM residue) through v6.0.0, plus the v7 edges PASS A read only as storage layouts.

| ID | Prio | Persistent object / state | Created under | U21 consumer | Question to answer | Reopens | Owner | Status |
|---|---|---|---|---|---|---|---|---|
| B01 | P0 | `provenWithdrawals` entries from the L2OutputOracle era (legacy mapping slot, `l2OutputIndex` instead of a game) and from each later portal version | Bedrock .. pre-fault-proofs, v1.4 (U7), v3/v4 | `checkWithdrawal`, `finalize*`, `deleteProvenWithdrawal` (calls `status()` on the STORED address) | Do legacy entries exist in live storage; which slot; can any v9 path read them; what does `deleteProvenWithdrawal` do on a stored non-game address | C4, C5 | OPUS-02 | QUEUED |
| B02 | P0 | `finalizedWithdrawals` and withdrawal-hash / nonce-version domain across Bedrock, legacy OVM migrated withdrawals | OVM -> Bedrock migration | portal finalize, L1CDM `successfulMessages`/`failedMessages`, legacy v0 hash slot 203 | Is one economic withdrawal representable under two hashes; is legacy double-relay protection complete | C5 | OPUS-03 | QUEUED |
| B03 | P0 | ETH custody history per chain: portal balance -> ETHLockbox (U16), `migrateLiquidity`, donations, failed-withdrawal ETH left in portals, L1CDM-held ETH of failed messages | Bedrock .. U16 | lockbox accounting, planned shared lockbox | Is every chain's L2 ETH liability backed by its lockbox; any residue outside the lockbox | C3, L9 | OPUS-01 | QUEUED |
| B04 | P0 | Dispute-game lineage: every game type registered/unregistered, respected-type switches, retirement timestamp moves, blacklist entries, ASR replacements per chain | U7 .. U20 | ASR `isGameClaimValid`, portal prove/finalize | Is there any game (any chain) that is claim-valid today but was created under an implementation/prestate later deemed unsound and never retired | C12, C13, L1 | OPUS-10 | QUEUED |
| B05 | P0 | Absolute-prestate history (cannon, MT-cannon, kona, interop) and in-flight games across each switch | U7 .. U21 | old clones' immutable prestate | Which historical prestates had soundness fixes after them; are games from those windows still usable | L1 | OPUS-10 | QUEUED |
| B06 | P1 | Pause state and identifier history: portal-local `paused` slot, SuperchainConfig v1 global pause, per-identifier pause (U13), lockbox identifier (U16/U21), DeputyPauseModule | Bedrock .. U21 | four pause pointers in v9 | Is any historical pause bit/slot still set or readable; does any contract still resolve an old identifier | C8 | OPUS-04 | QUEUED |
| B07 | P1 | Immutables moved to storage at MCP (U6): portal `l2Oracle`, `systemConfig`, `guardian`, messenger `PORTAL`/`OTHER_MESSENGER`, bridge `MESSENGER`/`OTHER_BRIDGE` | U6 | v9 getters and legacy aliases | Any value now resolved from a different source than the one an old object was created under | C2 | OPUS-06 | QUEUED |
| B08 | P1 | Initializer version history per proxy per chain (OZ `_initialized` vs `ReinitializableBase`), StorageSetter cycles | Bedrock .. U21 | `reinitializer(initVersion())` | Different histories reaching the same initialized version with different state | C1, C2 | OPUS-05 | QUEUED |
| B09 | P1 | DelayedWETH generations per chain (legacy proxies still holding bonds; allowance/hold semantics) | U7 .. U21 | legacy games' `claimCredit`, global pause only | Stranded or duplicated credit; legacy approvals; cross-game leakage (bond-only = at best Medium) | — | OPUS-11 | QUEUED |
| B10 | P1 | L1CrossDomainMessenger state behind ResolvedDelegateProxy: `successfulMessages`, `failedMessages`, legacy `relayedMessages`/slot 203, `xDomainMsgSender`, initializer byte at offset 20 | OVM .. U21 | `relayMessage` replay branch | Old-version message hashes replayable/blocked under 2.13.0; ETH held for failed messages per chain | C5, L3 | OPUS-03 | QUEUED |
| B11 | P1 | L1StandardBridge `deposits[l1Token][l2Token]` escrow accounting incl. OVM-era tokens, legacy `finalizeERC20Withdrawal` aliases | OVM .. U21 | bridge finalize via replay | Escrow drift across versions; token-pair identity changes | — | OPUS-16 | QUEUED |
| B12 | P1 | SystemConfig fields and `ConfigUpdate` event history (batcher hash, gas config, EIP-1559 params, operator fee, DA footprint, min base fee, features bitmap) | Bedrock .. U21 | op-node / kona derivation, re-emitted events at U21 | Same event interpreted differently by client generations; re-emission at upgrade | — | OPUS-13 | QUEUED |
| B13 | P1 | Chain-specific upgrade paths: OP vs Ink vs Soneium vs Unichain (genesis generation, skipped upgrades, OPCM vs manual) | per chain | same v9 code | Same-code / different-history behavioural divergence | C1, C8, C9 | F5 | QUEUED |
| B14 | P1 | OPCM generations and `lastUsedOPCM`/sequence state; ProxyAdmin ownership moves (U8 Stage 1, U13) | U13 .. U21 | OPCM v9 upgrade/migrate checks | Skip-path or retry state accepted by the current validator | C1 | OPUS-07 | QUEUED |
| B15 | P2 | L2 predeploy history (L2ToL1MessagePasser, L2CDM 2.2.1, L2StandardBridge, L1Block, ProxyAdmin owner alias) by hardfork | Bedrock .. Isthmus/Jovian/Karst | L1 proof verification, baseGas budgets | L2-side state created under old predeploy code and consumed by v9 L1 contracts | L5 | OPUS-12 | QUEUED |
| B16 | P2 | Custom-gas-token mode history (v1 CGT, removal, CGT v2 at U18) | U? .. U18 | portal/lockbox CGT branches | Mode transitions on any live in-scope chain | — | OPUS-15 | QUEUED |
| B17 | P2 | Prior audit fixes whose safety depends on a relationship later removed | all | all | Fix-closure failures (Track B, after the blind registry freezes) | — | OPUS-18 | HELD (Track B) |

Rules: a row is DONE only with a recorded fact (file:line at a pinned tag, a `cast` read at a
pinned block, or a fork test). A row may be skipped only by proving the release cannot create
persistent state, mutate a surviving object, or change the interpretation of current state.
