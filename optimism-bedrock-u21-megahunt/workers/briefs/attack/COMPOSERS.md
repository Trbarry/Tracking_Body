# COMPOSERS — after the six attack lanes (all killed, 0 candidates, 73 kill files)

**Status 2026-11-17 (resume):** COMPOSER-1 and COMPOSER-2 (Opus) were stopped by a safety classifier; per
`CADRE-LEGAL.md` section 5 they are NOT re-run or re-phrased. R1 targets third-party contracts and is OUT OF
AUTHORIZATION under `CADRE-LEGAL.md` section 4 (programme rule: no testing with third-party smart contracts).

Read `ATTACK_CONTEXT.md` (rules, infra, deliverables, candidate template/score), then `ATTACK-MATRIX.md`
(every kill with its barrier — do NOT re-run a killed hypothesis unless your composition changes its
precondition), `LIVE-OBJECTS.md` (real production objects), `PRIMITIVE-COMPATIBILITY-MATRIX.csv`,
`CLOSURE-MAP.md`, and the lane reports `workers/ATK-*-report.md` / `workers/CATK-*-report.md`.
Reuse lane harnesses: `test/poc/attack-wave/{A..F}/`, `mirror/CATK-*/`, historical harness `test/`.

Residual edges the lanes left open (each is a starting point, not a conclusion):
R1. Forced failure (nested replay; known Trust M-1, acknowledged) x third-party L1 targets whose replay is
    not equivalent to first delivery: deadlines, rounds, one-shot state (Hop `confirmTransferRoot`, the
    Synthetix bridge, router `0x23CA5E53…` with ~638 ETH in flight per lane B), and every inner relay
    target of the ~32,007 finalized + pending messenger withdrawals that reads `portal.l2Sender()` /
    `xDomainMessageSender()` in a time-gated way. Eligibility: impact must be "user funds" per SCOPE.md 1.4
    (a third-party contract that freezes its users' funds because the protocol let a stranger force a
    failure may qualify as freezing of user funds; decide honestly).
R2. Retired lockbox accepts attacker ETH after migration; sibling-portal deposit from the portal alias
    (PRIM-2902); sticky lockbox authorization (PRIM-2903, known Low).
R3. Sender-chosen undeliverable bands (minGasLimit >= ~15.51M; message >= ~264 KB nonzero bytes; L2 accepts
    both): is there ANY L2 contract (bridge, router, batcher, account abstraction entry point, L2 app) that
    builds a withdrawal from data a THIRD PARTY controls, so that a stranger can push someone else's
    message into a band? (`baseGas` and size are fixed by whoever calls `sendMessage`.) Search real OP
    Mainnet L2 contracts that call L2CDM `sendMessage` / L2ToL1MessagePasser `initiateWithdrawal` with
    caller-supplied payloads (MessagePassed `sender` histogram via `http://127.0.0.1:7546`).
R4. Allowances to protocol call-executors: a real 9 USDC allowance to Unichain's L1CDM is spendable by any
    L2 user (lane F, user error). Census: ERC20 `Approval` events on L1 with spender in {every chain's L1CDM,
    portal, L1StandardBridge, lockbox, old portal impls}; total value spendable today.
R5. Trojan games x the automatic prover EOA `0x431f…ddf5` (135 proofs for 74 users, newest-game selection):
    victims do not choose the game. Known root cause (Cantina 2025-04 Interop Portal 3.1.6, Low).
R6. Old-prestate games (148 IN_PROGRESS until <= 2026-11-23 23:02 UTC): a program-level run needs L2
    execution witnesses; no public OP RPC serves `debug_executionWitness` (checked: mainnet.optimism.io,
    tenderly, publicnode, zan). Treat as infeasible here unless you find a witness source.

## COMPOSER-1 — cross-family attack paths

Attempt at least 12 high-value compositions, each connecting at least two of: historical proof/game state;
messenger replay state; custody/lockbox state; pause identity; migration state; target authorization; gas
budget; chain/root identity. Prefer: attacker creates an unusual but valid state -> an upgrade/migration/
replay changes its interpretation -> another contract trusts the changed state -> irreversible value,
proof or authorization impact. Each composition must be EXECUTED on a fork (or killed by an exact
file:line / cast-read barrier before any fork work is meaningful) and recorded.

## COMPOSER-2 — medium-to-high amplifier

For every real but limited primitive in the attack-wave results (R1-R5 and any limited primitive in
`ATTACK-MATRIX.md` that a lane scored > 0): test repeatability, victim multiplicity, shared-relayer impact,
cross-chain / shared-lockbox amplification, permanent rather than temporary effect, targeting of unrelated
users, insolvency or protocol-wide withdrawal failure — with real production objects (`LIVE-OBJECTS.md`)
and fork tests. Kill the amplification as soon as one realistic barrier remains. Do not inflate severity.

Lane ids: COMPOSER-1 = `CMP1`, COMPOSER-2 = `CMP2`. Deliverables exactly as ATTACK_CONTEXT.md with X =
CMP1 / CMP2 (`rejected/ATTACK-CMP1-nn.md`, `candidates/CAND-ATK-CMP1-nn.md`, `test/poc/attack-wave/CMP1/`,
`evidence/attack-wave/CMP1/`, `workers/ATK-CMP1-report.md`).
