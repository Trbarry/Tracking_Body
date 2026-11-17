# Lane 31 real-withdrawal fixture corpus

## Provenance and search

- Portal: `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed`.
- Inclusive L1 range: `26373900..26433900` (60,001 blocks straddling U21 block `26430859`).
- The requested Publicnode archive query was attempted first and returned HTTP 403 / `Archive requests require a personal token`; the raw response is `logs/publicnode-probe.json`. The complete scan therefore used passive `eth_getLogs` reads through `https://eth.drpc.org`, in 100-block chunks with two workers. This was the provider's effective cap, stricter than the requested 10,000-block maximum.
- Complete result: 1,247 logs, 0 failed chunks: 470 `WithdrawalProven`, 470 `WithdrawalProvenExtension1`, and 307 `WithdrawalFinalized`. Raw chunks, aggregate, error ledger, and scan metadata are under `logs/portal-26373900-26433900/`.
- `scripts/build_withdrawal_fixture.sh` fetches the prove transaction and receipt, decodes the actual `proveWithdrawalTransaction` calldata, recomputes the withdrawal tuple, resolves the DGF index, and reads stored proof/finalization state from the correct pinned fork. Each JSON retains the raw calldata and complete Merkle proof.

The portal event signatures used by the scanner come from `OptimismPortal2.sol`; proving writes per-submitter state and emits both proof events at target commit `ba6fcadb`, `/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src/L1/OptimismPortal2.sol:480-491`.

## Fixture index

| File | Era / proof block | Shape | Value (wei) | Game index / type / address | Status at selected fork | Finalized |
|---|---:|---|---:|---|---|---|
| `post-messenger-zero-1.json` | post / 26432559 | L2CDM -> L1CDM | 0 | 21384 / 9 / `0xF565...2cCC` | in progress | false |
| `post-messenger-value.json` | post / 26432798 | L2CDM -> L1CDM | 1,790,000,000,000,000 | 21384 / 9 / `0xF565...2cCC` | in progress | false |
| `post-messenger-zero-2.json` | post / 26433490 | L2CDM -> L1CDM | 0 | 21387 / 9 / `0x0C39...5444` | in progress | false |
| `pre-messenger-zero.json` | pre / 26429987 | L2CDM -> L1CDM | 0 | 21374 / 9 / `0xeD80...cF54` | in progress | false |
| `pre-messenger-value.json` | pre / 26428146 | L2CDM -> L1CDM | 12,091,417,834,329,393 | 21367 / 9 / `0x16A3...87a8` | in progress | false |
| `pre-plain-value-27eth.json` | pre / 26426994 | L2StandardBridge -> non-messenger target | 27,239,430,368,181,064,215 | 21364 / 9 / `0x4527...700f` | in progress | false |
| `pre-plain-value-53eth.json` | pre / 26426996 | L2StandardBridge -> non-messenger target | 53,471,397,708,087,729,191 | 21364 / 9 / `0x4527...700f` | in progress | false |
| `pre-plain-invalid-90000eth.json` | pre / 26404222 | plain | 90,000 ETH | 21288 / 9 / `0xa571...3619` | challenger wins | false |

Full hashes, submitters, transactions, proof arrays, and observations are in the JSON, not abbreviated there. The 60,001-block corpus contained no plain zero-value proof: all non-L2CDM proofs were the three value-bearing rows above. Thus zero/value coverage exists for real messenger withdrawals and value coverage exists for real plain withdrawals; no plain-zero fixture is claimed.

## End-to-end execution

`test/RealWithdrawalBase.t.sol:83-100` loads a JSON fixture and independently checks `keccak256(abi.encode(withdrawal))` against the event hash. For `post-messenger-zero-1.json`, the test:

1. Forks the real deployed state at block 26433900.
2. Warps past the real type-9 game's root clock, calls public `resolveClaim(0,0)` and `resolve()`, then warps past both portal proof maturity and ASR game finality (`test/RealWithdrawalBase.t.sol:115-137`). **No prank is used for game resolution.** Both functions are permissionless at this state.
3. Calls `finalizeWithdrawalTransactionExternalProof` with the real stored proof submitter. No caller prank is used; the external-proof API intentionally accepts the submitter as an argument.
4. Asserts `WithdrawalFinalized(...,true)`, global finalization, exactly one L1 messenger outcome, unchanged portal balance, and unchanged lockbox balance for value zero (`test/RealWithdrawalFinalization.t.sol:12-45`).

The complete `-vvvv` execution trace is `test-results/real-finalization-trace.txt`.

## Reproduction

```sh
cd /home/user/u21-work/codex-31/h
forge test --match-path test/RealWithdrawalFinalization.t.sol -vvvv
```
