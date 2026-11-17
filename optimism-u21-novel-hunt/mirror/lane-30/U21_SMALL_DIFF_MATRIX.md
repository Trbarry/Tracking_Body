# Lane 30 — every named small v8→v9 diff

Diff is `f45a5ccf…` → `ba6fcadb…`. “Formatting” means token-equivalent line wrapping/reindentation; “comment” changes neither AST nor runtime. Counts are `+/-` from `git diff --numstat`.

| Component | +/- | Classification and reason | Unchanged-caller assumption touched |
|---|---:|---|---|
| `libraries/rlp/RLPReader.sol` | 4/3 | Formatting: `RLPItem` literals reflowed. | None; decode lengths/pointers identical. |
| `libraries/SafeCall.sol` | 38/33 | **Semantic.** Adds `NEW_ACCOUNT_STATE_GAS=183600` and passes it to `hasMinGas` only for value sent to `target.codehash==0` (`SafeCall.sol:7-9,119-135`). This pre-positions EIP-8037/Amsterdam. | Only `OptimismPortal2.callWithMinGas` uses the changed overload (`OptimismPortal2.sol:620-627`), and Portal itself changed. Unchanged DAC/FeeVault/StandardBridge/Faucet use `send`/`call`; unchanged behavior. CrossDomainMessenger uses `hasMinGas`/`call`, not this branch. |
| `libraries/Burn.sol` | 2/0 | Comment only: Amsterdam TODO says SELFDESTRUCT value will become stranded rather than burned (`Burn.sol:29-30`). | None; ResourceMetering still calls `Burn.gas` identically. |
| `libraries/Constants.sol` | 1/1 | Comment only: `PERMIT_ALL_CONTRACTS_INSTRUCTION` is described as initial-deployment-only, not migration. | None; bytes value remains `"ALL"`. |
| `libraries/Predeploys.sol` | 16/7 | Formatting: comments and `_variants` arguments reflowed. | None; record count, addresses, gates and gas limits identical. |
| `libraries/GasPayingToken.sol` | 2/1 | Formatting: one storage-slot expression wrapped. | None. |
| `dispute/lib/LibPosition.sol` | 6/7 | Formatting: Yul `or/byte` expression reindented. | None; same assembly expression. |
| `dispute/lib/LibUDT.sol` | 1/9 | Formatting: `LibGameId.pack` signature collapsed. | None. |
| `dispute/lib/LibGameArgs.sol` | 3/1 | Formatting: one-line length revert expanded to braces. | None. |
| `dispute/lib/Types.sol` | 16/2 | **Semantic addition.** Adds seven-element `GameTypes.clearedGameTypes()` (`Types.sol:97-110`) and redirects the maintenance comment to it. Existing constants and `isSuperGame` are unchanged. | No unchanged caller invokes the new function. Changed Migrator clears the old DGF (`OPContractsManagerMigrator.sol:536-540`); changed MigrationValidator checks exactly that same list (`…MigrationValidator.sol:728-735`). Their shared omission therefore cannot be caught by validation. |
| `libraries/Types.sol` | 0/0 | Byte-identical v7/v8/v9. Included to disambiguate the two `Types.sol` files. | Portal withdrawal structs unchanged. |
| `cannon/MIPS64.sol` | 5/13 | Formatting: function signature and two proof checks reflowed. | None; VM step logic identical. |
| `cannon/libraries/MIPS64Instructions.sol` | 1/6 | Formatting: struct literal collapsed. | None. |
| `cannon/libraries/MIPS64Memory.sol` | 2/2 | Documentation correction: return value is a 64-bit word, not “hashed MIPS state.” | None. |
| `MIPS64Arch.sol`, `MIPS64State.sol`, `MIPS64Syscalls.sol` | 0/0 | Byte-identical. | None. |
| `cannon/PreimageOracle.sol` | 22/33 | Formatting only: assembly calls, chained setters and proof predicates reflowed. | None; the live shared oracle remains v1.1.5 and its address is unchanged through U21. |
| `universal/ProxyAdmin.sol` | 2/3 | Formatting: ChugSplash `setStorage` call reflowed. | None; proxy-type routing identical (`ProxyAdmin.sol:104-130,149-166`). |
| `universal/ProxyAdminOwnedBase.sol` | 2/1 | Formatting: ResolvedDelegateProxy string expression wrapped. | None; slot probing and comparisons identical (`ProxyAdminOwnedBase.sol:41-85`). |
| `safe/LivenessModule.sol` | 1/3 | Formatting: `_removeOwner` literal collapsed. | None. |
| `L2/FeeVault.sol` | 1/3 | Formatting: `initiateWithdrawal` literal collapsed. | None; also no L2 hardfork accompanied U21. |
| `legacy/LegacyMintableERC20.sol` | 1/8 | Formatting: constructor signature collapsed. | None. |

## SafeCall / cross-domain gas boundary

Amsterdam is not active at block N. Therefore the new 183,600 requirement is conservative today: it may demand more transaction gas for a value withdrawal to a nonexistent account, but the user/finalizer can retry with more gas. Portal forwards all remaining gas; `_tx.gasLimit` is only a floor. A failed L2-messenger withdrawal reverts finalization and remains retryable (`OptimismPortal2.sol:639-653`).

U21 also gives the L1 messenger new **local** budgets of 135,000 reserve and 15,000 check buffer (`GasConstants.sol:49-78`; `L1CrossDomainMessenger.sol:43-47,145-153`). Public getters intentionally expose **remote L2** budgets for `baseGas` (`L1CrossDomainMessenger.sol:49-74,116-125`). Read-only state:

| Contract/block | version | constant/call/reserve/buffer | `baseGas(0x,0)` |
|---|---:|---:|---:|
| L1 messenger N−1 | 2.11.1 | 200000 / 40000 / 40000 / 5000 | 310160 |
| L1 messenger N | 2.13.0 | 200000 / 40000 / 40000 / 5000 | 310160 |
| OP L2 messenger pinned :9545 | 2.2.1 | 200000 / 40000 / 40000 / 5000 | 310160 |

The apparent getter mismatch is therefore deliberate ABI compatibility, not an incorrect local reserve. The L2 has old constants, but extra L1 transaction gas and Portal retry semantics prevent a permanent freeze under current rules. Amsterdam behavior is source-reasoned only and was not locally reproducible.
