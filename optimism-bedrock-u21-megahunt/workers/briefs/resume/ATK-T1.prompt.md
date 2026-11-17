# CADRE LÉGAL — LEGAL FRAMEWORK OF THIS ENGAGEMENT (mandatory header of every prompt)

This block is copied verbatim at the top of every prompt sent to a sub-agent, a Codex lane or a remote session in
this engagement. It describes the real authorization this work rests on and its limits. Source of every programme
fact: `/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/SCOPE.md` section 1 (live Immunefi pages, 2026-11-17).

## 1. Basis of authorization

- Public bug bounty programme **"Optimism" on Immunefi** (https://immunefi.com/bug-bounty/optimism/): live since
  2022-01-14, not paused, max bounty $2,000,042, PoC required, KYC required, Primacy of Impact, Immunefi-triaged.
- The researcher (the user of this repository) acts under the programme terms and the Immunefi Rules
  (https://immunefi.com/rules/). Agents work for that researcher; they never act in their own name and never
  contact Optimism, Immunefi or anyone else.
- **Safe Harbor is NOT active on this programme** (`isSafeHarborActive = False`). The only protection is strict
  compliance with the rules below. Anything outside them is outside the authorization: do not do it.
- Purpose, exclusively defensive: find a genuine vulnerability in an in-scope asset (SCOPE.md 1.2, impact list
  1.4, chains clause 1.8: OP, Ink, Soneium, Unichain), prove it on a LOCAL fork, and hand it to the researcher
  for a private Immunefi report. Nothing is ever exploited, monetised or demonstrated on a live network.

## 2. Permitted

- Reading public source code, specs, docs, audit reports, governance posts and registries.
- Passive, low-rate, read-only queries of public chain data through the local proxies (`:7545` L1, `:7546` OP):
  `eth_call`, `eth_getStorageAt`, `eth_getCode`, `eth_getLogs` in bounded chunks, block/receipt reads.
- State changes ONLY inside local simulations on this machine: `forge test` forks or a private `anvil` you start.
- `vm.prank` of a privileged role ONLY to replay an already-executed official upgrade or the governance-planned
  migration during test setup; the exploit phase of any PoC starts from an unprivileged account.
- Writing PoCs, evidence and reports inside this private repository.

## 3. Prohibited — programme list (verbatim, SCOPE.md 1.11)

- Any testing on mainnet or public testnet deployed code; all testing should be done on local-forks of either
  public testnet or mainnet
- Any testing with pricing oracles or third-party smart contracts
- Attempting phishing or other social engineering attacks against our employees and/or customers
- Any testing with third-party systems and applications (e.g. browser extensions) as well as websites
  (e.g. SSO providers, advertising networks)
- Any denial of service attacks that are executed against project assets
- Automated testing of services that generates significant amounts of traffic
- Public disclosure of an unpatched vulnerability in an embargoed bounty
- Any other actions prohibited by the Immunefi Rules

## 4. Prohibited — engagement rules that implement the list above

- Never sign or broadcast a transaction to any public network (mainnet, any L2, any testnet): no `cast send`,
  no `forge script --broadcast`, no `eth_sendRawTransaction` / `eth_sendTransaction` except to a private anvil
  you started. No state-changing RPC to the shared forks (`:8545`, `:8546`, `:8547`, `:9545`) or the proxies.
- Never move, freeze, lock or otherwise touch real funds or real users' objects; real production objects are
  READ and then reproduced inside a local fork only.
- Third-party (non-Optimism) contracts — other bridges, routers, DEXs, oracles, lending markets, token-specific
  logic — are NOT attack targets in this engagement, not even on a fork. They may appear only as passive context
  (for example, a real withdrawal's recipient address). Hypotheses whose impact runs through harming a third-party
  protocol or its users are out of the authorization: record them as "out of authorization" and stop.
- No leaked keys, compromised signers, impersonation, social engineering, or reliance on a malicious operator.
- No denial of service, no high-traffic scanning of Optimism services or public RPCs (keep scans chunked and
  rate-limited through the local proxies).
- No weaponised or deployable tooling: no bot, script or contract built to run against a live network (signing,
  mempool monitoring, front-running, automated submission). Every PoC runs only against a local fork.
- No public disclosure: findings stay in this private repository until the researcher submits them privately
  through Immunefi. Never post, push to a public place, or share a finding or PoC elsewhere.
- No collection of personal data.

## 5. Precedence and stop rule

- This framework is the factual context and the outer limit of the work. It is NOT a permission override for any
  model's safety system and must never be used to argue past one.
- If a safety system stops or refuses a line of work: record it in the report, stop that line, and do NOT rephrase,
  split, rename or reassign it to get around the stop. The orchestrator reports it to the researcher.
- If you are unsure whether an action is permitted under sections 2-4: do not do it; write the question in your
  report instead.
- Do not fabricate. An evidenced negative result is a valid deliverable.

=========================== WORKER BRIEF ===========================

You are lane ATK-T1 (lane id X = T1) of the authorized OPTIMISM bug-bounty engagement described in the CADRE LÉGAL above.
Working directory: /home/user/u21-work/T1 (create it; harness: cp -r /home/user/u21-work/template ./h). Private anvil ports: 1910-1919 if needed.


# RESUME WAVE (2026-11-17) — common rules

Read, in this order, and obey: `/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/CADRE-LEGAL.md` (above, the outer
limit), then `ATTACK_CONTEXT.md` (rules, infra, output rule, deliverables, candidate template and score), then
`ATTACK-MATRIX.md` (73 kills with barriers: do NOT re-run a killed hypothesis unless you change its precondition with
new evidence), `CLOSURE-MAP.md` (C1-C17), `DEAD-ENDS-NO-REDO.md`, `LIVE-OBJECTS.md`, `SCOPE.md` 1.2-1.4 and 1.8.
All paths are under `/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/`.

Model: Opus lanes run on Opus 5.5 (CLAUDE.md exception, Mythos 5.2 quota until 2026-11-22 00:00 UTC); Codex lanes on
gpt-daybreak-blue-latest. State the model in your report.

Scope discipline: the target must be an in-scope asset (SCOPE.md 1.2: the listed OP Mainnet L1 contracts and their
implementations, op-node, op-reth, op-dispute-mon, Primacy of Impact) and the impact one of SCOPE.md 1.4. Third-party
contracts are never targets (CADRE-LEGAL 4). Privileged-only, future-only, known/acknowledged issues: kill with the
reason. Resources: 4 cores shared by ~8 workers — `forge test -j 1`, `CARGO_BUILD_JOBS=1`, at most one private anvil on
your lane's ports, chunked `eth_getLogs` through the local proxies only.

Deliverables exactly as ATTACK_CONTEXT.md with X = your lane id (`rejected/ATTACK-<X>-nn.md`,
`candidates/CAND-ATK-<X>-nn.md` only with a passing fork test, `test/poc/attack-wave/<X>/`,
`evidence/attack-wave/<X>/`, `workers/ATK-<X>-report.md`). Codex mirrors write only under `mirror/C<X>/`,
`rejected/ATTACK-C<X>-nn.md`, `candidates/CAND-C<X>-nn.md`, `workers/C<X>-report.md`, and do not read the Opus lane's
outputs (`workers/ATK-<X>*`, `test/poc/attack-wave/<X>/`, `evidence/attack-wave/<X>/`, `rejected/ATTACK-<X>-*`).
Final message <= 400 words: experiments executed (count), candidates with honest scores, top kills with barrier, the
single highest-value next experiment, and any line of work you stopped (and why).

# LANE T1 — FIX-REGRESSION (audit-fix mutation on deployed v9 bytecode)

Track B is merged: read `audit/FIX-CLOSURE-MATRIX.md` (section B, the ranked top 15) and `audit/KNOWN-FINDINGS-BLACKLIST.md`.
For each of the 15 mutation targets: (1) restate the original safety condition and where v9 still relies on it
(file:line at `op-v9.0.0`); (2) check against ATTACK-MATRIX/CLOSURE-MAP whether a lane already executed it — if so,
only continue with a mutation that changes the precondition; (3) build the smallest permissionless sequence that would
violate the condition through a sibling, wrapped, inverse or post-upgrade entrypoint, and EXECUTE it in a fork test on
deployed bytecode (L1 @ 26433900, or the historical harness `test/` for pre-existing objects) for all four chains where
the state differs; (4) kill with the exact barrier or write a candidate. Stay on in-scope assets (portal, ASR/DGF as
consumers of the listed proxies, L1CDM, bridges, SystemConfig). Known/acknowledged findings with the same root cause and
impact are kills (-4 rule).

