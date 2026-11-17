# LANE 30 report — Historical Assumption Archaeology

## Outcome

No permissionless, production-reachable vulnerability survived falsification. Six concrete composition primitives and six exact negative results are recorded. The strongest suspected failure — U21 changing ASR/DelayedWETH behavior under real unresolved games — was killed on the N fork by completing the entire resolution/finality/close/unlock/withdraw sequence against a real pre-upgrade game.

No `CAND-30xx` file was created. The hard-coded migration clearing list deserves follow-up but current OP state lacks its required condition and direct eligible impact is not established.

## Method and safety

- Source baselines: v7 `a7c88c8…`, v8 `f45a5cc…`, v9 `ba6fcadb…`.
- State baselines: N−1 `26430858` (`:8546`), N `26430859` (`:8547`), later `26433900` (`:8545`), OP L2 (`:9545`).
- Public/external material was not searched; blind-first rules were maintained.
- Every chain interaction was `eth_call`, `eth_getStorageAt`, code/balance read, or in-process `forge test`. No public or shared-fork state mutation was sent.
- Harness: `/home/user/u21-work/codex-30/h`, with `l1n` added. Final result: 5/5 tests pass.

## 1. Old code newly surrounded

Nineteen named files are byte-identical v7/v8/v9. The highest-risk ingress is changed Portal inheriting old post-body `ResourceMetering`, followed by changed L1StandardBridge inheriting old StandardBridge, changed DelayedWETH inheriting old WETH98, and changed contracts depending on old storage/trie/encoding helpers. Exact SHA-256 triples and call sites are in `mirror/lane-30/U21_UNCHANGED_OLD_PRIMITIVES.md`.

`SuperchainConfig.sol` is not unchanged. `ProxyAdminOwnedBase.sol` has a formatting-only diff. `libraries/Types.sol` is unchanged; `dispute/lib/Types.sol` is semantically changed. These distinctions prevent false attribution.

## 2. Every named small diff

Only two named changes alter runtime behavior:

1. `SafeCall.callWithMinGas` reserves 183,600 extra gas for value to a nonexistent account (`SafeCall.sol:7-9,119-135`). Its changed overload is used only by changed Portal. Unchanged SafeCall consumers use unaffected entry points.
2. `GameTypes.clearedGameTypes()` adds a seven-type list (`dispute/lib/Types.sol:97-110`), used by changed Migrator and changed Validator.

All other named diffs are formatting, comments, or corrected documentation. Full matrix: `mirror/lane-30/U21_SMALL_DIFF_MATRIX.md`.

## 3. Exact N−1 → N state

Final ProxyAdmin resolution is recorded in `mirror/lane-30/U21_PROXY_IMPLEMENTATION_MAP.md`. Seven OP implementations changed; ERC721Bridge, MintableERC20Factory, DGF and L1StandardBridge returned to their prior implementation after initializer choreography. The receipt’s 132 Upgrade logs are therefore not 132 final implementation changes.

I compared all 97 compiler-declared static storage slots across the 11 touched OP proxies. Only Portal params, Lockbox SC pointer, DelayedWETH Lockbox pointer, packed ASR Lockbox pointer, and L1CDM nonce differed. Separately:

- SystemConfig’s unstructured OPCM slot changed to v9 OPCM.
- DGF `gameArgs[9]` changed only absolute prestate; VM/ASR/WETH/chain word did not.
- Proxy implementation locations changed according to the final map; proxy admin/owner did not.

At N, DGF count remained 21378, WETH supply/balance/delay were preserved, ASR anchor/type/retirement were preserved, ETH_LOCKBOX remained true and INTEROP remained false. N→later changes were ordinary Portal metering, 11 new games, an anchor update and messenger nonce traffic. Details/raw words: `mirror/lane-30/N_MINUS_1_TO_N_STATE.md`.

## 4. In-flight games

DGF snapshots implementation args into clone calldata (`DisputeGameFactory.sol:174-217`), so old games keep their old prestate but call mutable ASR/WETH proxies. The 500-game tail spans 20.7 days. All are type 9; all 84 games still `IN_PROGRESS` at N−1 share the same VM, ASR, WETH and old prestate (`mirror/lane-30/IN_FLIGHT_SCAN.md`).

Representative index 21377 / `0x675E…0d10` was created before U21, had one claim and held 0.08 WETH. On the N fork:

1. warp past game clock;
2. `resolveClaim(0,0)` and `resolve()`;
3. warp past ASR finality;
4. `closeGame()` selects NORMAL and credits creator;
5. first `claimCredit()` starts WETH delay;
6. warp 302400 and call again;
7. creator gains 0.08 ETH and game WETH becomes zero.

This kills permanent freeze/theft from the U21 singleton upgrade for the observed production shape. Test: `mirror/lane-30/test/Lane30InFlight.t.sol`; source control points `SuperFaultDisputeGame.sol:673-790,945-1037`, ASR `:286-325`, DelayedWETH `:81-108`.

## 5. Old metering plus Lockbox call order

The modifier executes the Portal body before metering (`ResourceMetering.sol:66-75`), and Portal calls Lockbox before validating creation target/gas/calldata (`OptimismPortal2.sol:741-795`). However:

- v8 has the exact same order (`v8 OptimismPortal2.sol:684-738`);
- ETH_LOCKBOX was already true at N−1;
- `lockETH` authenticates Portal and has no callback (`ETHLockbox.sol:142-151`);
- direct attacker call reverts;
- invalid deposit rolls back Lockbox balance and meter fields;
- valid deposit moves value and metering atomically.

Test: `mirror/lane-30/test/Lane30ResourceMetering.t.sol`.

## 6. Proxy-admin sameness

`_assertSharedProxyAdminOwner` trusts the target’s self-reported getter (`ProxyAdminOwnedBase.sol:79-85`), so an attacker contract can syntactically spoof it. Current danger is killed because Lockbox checks its real ProxyAdmin owner/admin before every route that authorizes a target or transfers its full balance (`ETHLockbox.sol:94-130,184-234`). Migrator owner equality is followed by real admin-gated external mutations; validator comparisons grant nothing.

Live standard, Resolved and Chug proxies all resolve the same ProxyAdmin and Safe. Full inventory: `mirror/lane-30/U21_PROXY_ADMIN_SAMENESS.md`.

## 7. Assumption-marker mining

Every `src/L1` grep match is grouped with exact lines and a U21 verdict in `mirror/lane-30/U21_ASSUMPTION_HITS.md`, with L1-executed proxy/dispute/library matches added. Notable kills:

- testing magic address `0xbeefcafe` has no code at N;
- DAC percentage assumption is enforced ≤100;
- initializer v5 TODO has pre- and post-initializer guards;
- Portal timestamp “not strictly necessary” checks remain before acceptance;
- legacy-game no-try/catch is not reached by sampled type-9 games;
- PreimageOracle assumption code and deployed singleton are unchanged;
- ZK `nosemgrep` sites are inactive because type 10 implementation is zero.

## 8. Rejected hypotheses

- REJ-3001: in-flight bond freeze/steal — real payout succeeds.
- REJ-3002: pre-meter Lockbox partial effect/reentry — no callback, atomic rollback.
- REJ-3003: permissionless fake-owner Lockbox drain — preceding real-owner gate.
- REJ-3004: retroactive prestate change — clone args immutable.
- REJ-3005: permanent messenger gas freeze — all-gas forwarding and retry.
- REJ-3006: hidden semantic formatter diff — exhaustive diff leaves only two explicit changes.

## 9. Open compositions for another lane

1. **Finite game clearing + planned interop migration (PRIM-3005).** Migrator and Validator share a list omitting types 2,3,6,7,254,255,1337. OP currently has every omitted entry zero, but another planned-set chain or a future registration could make the validator self-consistently miss stale games. Check Unichain exact DGF registrations and migration calldata.
2. **Same-owner predicate in a future permissionless path (PRIM-3004).** The predicate is demonstrably spoofable; search later/develop call sites for any route where it replaces caller authentication.
3. **Amsterdam plus old L2 gas constants (PRIM-3006).** Exercise value-to-new-account messages under an actual EIP-8037 simulator and exact-floor finalizer. Current rules only show retryable gas friction, not permanent impact.

## Scope/severity note

Game bonds alone are capped below Critical/High by the supplied scope facts; ETHLockbox/ASR/DelayedWETH are not individually listed assets, though U21 code/calldata is in scope. INTEROP is inactive and migration is future-planned, reducing present severity. No claim here elevates a mocked or future-only condition to mainnet exploitability.
