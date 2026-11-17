# CATK-CMP1 composition ledger

Model: OpenAI Codex (GPT-5), independent COMPOSER-1 mirror. Pins: Ethereum `26433900`, OP
`159654093`. All state mutations occurred inside Foundry-local fork state. Passive RPC endpoints
were used only for reads. Candidate threshold: score at least 7 **and** a passing deployed-state fork
exploit.

| ID | Families composed | Execution / exact barrier | Result | Score | Disposition |
|---|---|---|---|---:|---|
| C01 | proof/game + replay + target time | real 363.438 ETH withdrawal; forced failure; warp 10 years; replay | immutable target settles; caller gets 0 | 4.0 | CATK-CMP1-01 |
| C02 | replay + target auth + pause | real failure; EtherFi ops pause/replay/unpause/replay | only privileged temporary gate | 2.0 | CATK-CMP1-02 |
| C03 | pause identity + lockbox + replay | local lockbox pause after parking | messenger stops; unpause restores | 1.5 | CATK-CMP1-03 |
| C04 | global pause + replay + custody | global pause after parking | direct replay stops; unpause restores | 1.0 | CATK-CMP1-04 |
| C05 | game invalidation + proof deletion + replay | blacklist real game; delete real proof; replay | post-finalization state machines separate | 3.0 | CATK-CMP1-05 |
| C06 | gas cap + replay + app target | real replay inside 16M gas | settles below 2^24 cap | 2.5 | CATK-CMP1-06 |
| C07 | historical replay + one-shot target | live Hop failure + committed root state | economic effect already applied; value 0 | 1.0 | CATK-CMP1-07 |
| C08 | replay + target/implementation auth | live Synthetix failure | immutable wrong target still rejected | 1.0 | CATK-CMP1-08 |
| C09 | lockbox custody + migration residue + sibling identity | force ETH; attacker unlock; sibling portal lock | exact authorization rejects both | 2.0 | CATK-CMP1-09 |
| C10 | gas budget + contract sender + target auth | decode all 35,544 OP relay payloads | max 8M/416B; high gas fixed to bridge | 3.0 | CATK-CMP1-10 |
| C11 | allowance executor + replay + one-shot | pinned Approval, allowance, balance; messenger source | live 2.531863 USDC victim approval; no multiplier | 1.0 | CATK-CMP1-11 |
| C12 | trojan game + auto prover + proof identity | per-submitter mapping + C05 execution | retryable tooling delay, no global poison | 2.0 | CATK-CMP1-12 |
| C13 | old prestate + root validity + migration | live game reads; ASR predicate; inactive migration call | no divergence witness; INTEROP disabled | 4.5 | CATK-CMP1-13 |

## Fork execution

Nine composition tests and one sanity test pass with `forge test -j 1 -vv`. The full output is in
`evidence/fork-test-output.txt`. C01-C06 share a genuine deployed application withdrawal and proof;
C07-C08 use live failed messages; C09 uses the deployed OP lockbox. Privileged pranks are confined to
modeled defensive operations (pause/unpause/blacklist) and negative identity checks. The exploit
caller is always unprivileged.

## Residual edges R1-R6

- R1: covered by C01/C02/C07. No deadline-sensitive value redirection or attacker-controlled
  one-shot reset was found.
- R2: covered by C09. Forced surplus remains self-funded; sticky authorization conveys no caller
  right and sibling portals fail exact-address authorization.
- R3: covered by C06/C10. No live object reaches the capped band; high-gas bridge messages bind the
  caller's own asset action to a fixed target.
- R4: covered by C11. One live generic-executor approval is spendable but is a 2.531863 USDC victim
  approval, and failure/success atomicity prevents replay multiplication.
- R5: covered by C05/C12. Trojan selection is per submitter, retryable, and cannot reach an already
  finalized failed message.
- R6: covered by C13. The surface is time-bounded and real, but no old/new kona divergence witness
  exists; migration is not enabled on production OP.

## Candidate decision

No composition meets the threshold, so no `CAND-CATK-CMP1-*` file was created. C13 is the highest
uncertainty/highest consequence line, but without a concrete differential witness it is not an
exploit and cannot receive a fork-PoC score.

## Single highest-value next experiment

Run differential v1.7.0 versus v1.9.0 kona execution over user-constructible OP/interop inputs
(deposit attributes, L1-info, block boundaries, invalid/duplicate chain-root inputs), then minimize
any output-root divergence into the exact Cannon one-step witness usable against one of the still-
live old-prestate games. This is the only remaining experiment that can turn a current,
permissionless, high-impact surface into a candidate rather than another authorization or
conservation kill.
