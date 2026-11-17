PRIM-ID: PRIM-F4-03
Title: Hidden A -> B -> A implementation cycle on the OP Mainnet OptimismPortal (L1 block 26309074, 2026-10-31): a one-off
  implementation `0x6d971b07…` installed for one call, `forceDeposit()`, emitted a `TransactionDeposited` with an
  arbitrary UN-ALIASED L2 `from`; invisible in any implementation-pointer history sampled per block
Earliest semantic ancestor: v1.0.0 `OptimismPortal` deposit event as the sole L1->L2 authority (op-node derives deposits
  from `TransactionDeposited` logs emitted by the portal address); ProxyAdmin `upgradeAndCall` power over the portal.
Current consumer: op-node / kona deposit derivation (any log from the portal address is a deposit).
Releases crossed: v8.0.0 portal 5.8.0 (impl 0x1005217a…) -> one-off impl -> 5.8.0, inside one Safe execution.
Chains affected: OP Mainnet only (one tx).
Source contracts + functions: Safe 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A `execTransaction` -> ProxyAdmin
  0x543bA4AA… `upgradeAndCall(portal, 0x6d971b07cea5febaea8aefb827032f6a0538c9bb, forceDeposit() = 0x37604b29)` ->
  `upgrade(portal, 0x1005217ad392dc64cef501fa1777a27d42166748)` (tx 0xd80476b3ec56283723804cf7bc2d96f800c81d3ebd0fea843555396ffe94f28f,
  `evidence/F4/trace/26309074-calls.json`).
Persistent object or state: none on L1 (net storage delta of the portal zero, `trace/26309074-diff.json`); on L2 a
  deposit tx from 0x5227f603c1ee34ce3c06efe6477003bdfccb2f8c (no code on L1 or L2) to 0x4200…0042 (OP token), gas
  1,000,000, calldata `transfer(0x6b1bae59…4e3b, 44,231,858.7e18)`; the recipient is the L2 alias of the Safe.
Trigger: governance (ProxyAdmin owner) only.
Attacker-controlled inputs: none.
Required pre-state: ProxyAdmin ownership.
State mutation: L2 OP-token balances (via the forced deposit).
External calls: none from the one-off implementation.
Identity dependencies: op-node trusts the portal ADDRESS, not its code version.
Broken or weakened assumption: "the implementation-pointer history and `Upgraded` census describe every code that ran
  behind a proxy" — they do not: two `Upgraded` events in one tx; block-granular samplers see A before and A after.
  Also "an L2 deposit `from` is either an L1 EOA or an aliased L1 contract" — the forced deposit used an arbitrary L2 address.
Candidate compositions: none permissionless. The one-off implementation is inert: called directly it reverts
  (custom error 0x4ba8b214, cast call @26433900), `forceDeposit()` on the live portal reverts; no DELEGATECALL /
  SELFDESTRUCT in its bytecode; balance 0. A log it emitted from its OWN address would not be read by op-node.
Current production evidence: receipt logs (Upgraded x2, TransactionDeposited from the portal, ExecutionSuccess);
  `evidence/F4/op-proxyadminowner-safe-exec-classified.json` (all 49 Safe executions).
Reason it may be benign: privileged-only (-6), deliberate governance action, past-only; recorded as a methodology fact
  for other workers (B13/B14 census must use per-tx `Upgraded` events or traces, not samplers).
Exact falsification experiment: n/a (no permissionless path). For completeness: `cast call 0x6d971b07… 'forceDeposit()'`
  from any address reverts; done.
Confidence: high (fact).
Audit coverage:
Nearest known finding:
