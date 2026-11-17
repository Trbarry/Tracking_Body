# CATK-F report — unsafe targets and surviving system-contract trust

Model: Codex (GPT-5). Completed 2026-11-17 UTC. Independent mirror of ATK-F.

## Outcome

**No reportable candidate.** Candidate files created: **0**. Six hypotheses were deterministically
rejected because none combines permissionless reachability with impact to shared protocol state.

Experiments executed: **19** — 15 local-fork test cases plus four passive, pinned census passes
(withdrawal objects, DelayedWETH portal objects, portal aliases, and the 4×4 lockbox authorization
matrix). Final Forge result: **15 passed, 0 failed, 0 skipped**.

Pins:

- Ethereum L1: block `26433900`.
- OP L2: block `159654093`; full census begins at genesis block `105235063`.
- Forge used `-j 1`. No transaction was broadcast and no shared fork was mutated. All fabricated proof
  entries are explicitly local `vm.store` vehicles; separate L2 fork tests establish current
  permissionless withdrawal creation and immutable sender binding.

## High-signal results

1. **Complete OP withdrawal census.** 35,579 `MessagePassed` events; 35,544 canonical messenger
   targets and 35 direct withdrawals. No direct withdrawal matches the 379-address current/historical
   system inventory. All relay payloads decoded. There are 3,702 unfinalized inner system targets:
   3,698 expected canonical bridge messages and four StandardBridge messages with a wrong committed
   sender. The latter cannot pass `onlyOtherBridge`.
2. **L1 live proof population.** 31,839 proof events, 30,093 distinct proven withdrawals, 26,000
   finalized, and 4,093 proven-but-unfinalized. Among 32 distinct noncanonical proofs, zero targets are
   curated system contracts.
3. **Portal/lockbox trust.** The portal blocks itself/current lockbox. All three sibling lockboxes
   reject the OP portal. A modeled retired OP lockbox accepts only attacker-funded `lockETH`; its
   `unlockETH` rejects because `l2Sender != 0xdead` during withdrawal execution.
4. **Sibling portal composition.** OP→Ink/Soneium/Unichain portal calls move exactly equal custody:
   source lockbox −1 ETH, destination lockbox +1 ETH. No duplication. All 16 portal aliases have zero
   code/balance and no checked privileged identity.
5. **Messenger/bridge binding.** Direct portal frames fail every current bridge. The legitimate L2
   messenger route fixes inner sender to the attacker, so it reaches L1 messenger but fails bridge
   identity. All sibling messengers reject the OP portal.
6. **Historical objects.** Six ASRs, 13 DelayedWETH objects, four each of SystemConfig, ProxyAdmin,
   AddressManager, and DisputeGameFactory reject the portal's guardian/owner frame. All 52
   portal/DelayedWETH balances and all allowances/events are empty. WETH round trip recovers exactly
   self-funded value.
7. **Code-later search.** Of 66 effective targets, one changed from no code to a 23-byte EIP-7702
   designator. The exact unproven withdrawal is a zero-value self-message; current execution rejects
   its selector and L1 messenger records failure.

## Honest scoring

| Hypothesis | Candidate score | Terminal barrier |
|---|---:|---|
| Existing unfinalized system target | 0/10 | No attacker-controlled direct system object; bridge sender binding |
| Retired/sibling lockbox | 0/10 | Withdrawal-time `l2Sender` guard; self-donation only |
| Messenger/bridge laundering | 0/10 | Conjunctive portal/messenger/otherBridge identity |
| Registry/WETH/admin target | 0/10 | Guardian/owner checks; no portal-owned asset object |
| Sibling portal/alias composition | 0/10 | Equal custody movement; no privileged alias |
| Code-later target | 0/10 | Exact call reverts; zero-value self-message |

## Artifacts and reproduction

- Live objects: `mirror/CATK-F/LIVE-OBJECTS-CATK-F.md`
- All-generation matrix: `mirror/CATK-F/ALL-GENERATION-TARGET-MATRIX.md`
- Fork test: `mirror/CATK-F/test/CATK_F_UnsafeTargets.t.sol`
- Raw evidence/scripts: `mirror/CATK-F/evidence/`, `mirror/CATK-F/scripts/`
- Rejections: `rejected/ATTACK-CATK-F-01.md` through `-06.md`

Reproduce after copying the mirror test into the harness:

```sh
cd /home/user/u21-work/codex-CATK-F/h
forge test -j 1 --match-path test/CATK_F_UnsafeTargets.t.sol -vv
```

## Highest-value next experiment

Run the same genesis-to-pin `MessagePassed` → decoded inner target → L1 proof/finalization → code
chronology census on **Ink, Soneium, and Unichain L2 histories**. OP is complete; sibling chains are the
remaining evidence gap and could contain old messages aimed at another chain's surviving L1 trust
objects.

