# CATK-CMP1 — COMPOSER-1 independent mirror report

Model: **OpenAI Codex (GPT-5)**. Verdict: **13 compositions executed; 0 candidates**. Nine
deployed-state fork composition tests plus sanity pass (`forge test -j 1 -vv`). Four further
compositions use complete pinned populations and exact deployed source/state barriers. No public
transaction was broadcast; shared RPCs were passive-read only.

## Results

| Composition | Result | Honest score |
|---|---|---:|
| Forced failed 363.438 ETH app message x ten-year delay | original target settles; attacker gets zero | 4.0 |
| Same x application pause | only privileged, reversible gate | 2.0 |
| Same x lockbox-local pause | pause reaches L1CDM; no gap | 1.5 |
| Same x global pause | replay blocked until unpause | 1.0 |
| Same x game blacklist/proof deletion | replay independent after portal finalization | 3.0 |
| Same x EIP-7825 cap | settles within 16M gas | 2.5 |
| Hop live failure x one-shot state | root already confirmed; zero value | 1.0 |
| Synthetix live failure x target identity | immutable wrong target remains rejected | 1.0 |
| Forced lockbox ETH x sibling/sticky authorization | exact caller gates hold | 2.0 |
| Contract-built withdrawals x gas cap | max 8M/416B; largest fixed to bridge | 3.0 |
| Live executor allowance x failure replay | 2.531863 USDC victim approval; no multiplier | 1.0 |
| Trojan newest game x automatic prover | per-submitter, deletable/reprovable | 2.0 |
| Old-prestate game x root validity/migration | no divergence witness; INTEROP disabled | 4.5 |

Candidate threshold was score >=7 plus a passing genuine fork exploit. None qualifies; therefore no
`CAND-CATK-CMP1-*` file exists. Each killed hypothesis has its own
`rejected/ATTACK-CATK-CMP1-01.md` through `-13.md` record.

## Highest-signal barriers

1. **Immutable replay authority:** sender, target, value, minimum gas, and calldata are committed;
   success is terminal. Permissionless replay does not transfer caller authority.
2. **Proof/replay state separation:** once the portal finalizes and L1CDM records failure,
   blacklisting/deleting the proof cannot reach the parked message. Before finalization, bad proofs
   are per submitter and reprovable.
3. **Pause identity is wired through:** both local lockbox and global pauses reach SystemConfig and
   L1CDM.
4. **Custody authorization is exact:** force-sent surplus and sticky old authorization do not let an
   EOA or sibling portal call lock/unlock; production shared migration currently reverts
   `NotUsingInterop`.
5. **Complete OP gas population:** 35,579 withdrawals / 35,544 decoded canonical relays; max inner
   gas 8M, outer 8.416M, data 416 bytes. No live capped-band object exists.

## Highest-value next experiment

Differentially execute kona v1.7.0 and v1.9.0 over user-constructible deposit, L1-info, block-boundary,
and interop-root inputs. If outputs diverge, minimize to an exact Cannon one-step witness against a
still-live old-prestate game. This is the only residual path with current permissionless reach and
potential protocol-level impact.

Artifacts: `mirror/CATK-CMP1/COMPOSITIONS.md`,
`mirror/CATK-CMP1/evidence/fork-test-output.txt`,
`mirror/CATK-CMP1/evidence/gas-sender-census.json`,
`mirror/CATK-CMP1/evidence/state-barriers.md`, and
`mirror/CATK-CMP1/test/CATK_CMP1.t.sol`.
