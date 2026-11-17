# ATTACK-T5-02 — a deposit mints L2 ETH without the matching L1 lock (unbacked L2 ETH) (KILLED)

**Hypothesis.** Some permissionless deposit path, or the derivation, credits L2 ETH that was never locked on L1.

**Sequence executed.** (i) Fork test `test_T5_every_deposit_path_mints_exactly_what_it_locks` on deployed v9 bytecode:
portal `depositTransaction` (msg.value 3), `depositTransaction` with `_value` 5 / msg.value 0, portal `receive`,
L1SB `depositETH`, L1CDM `sendMessage{value}` from an unprivileged EOA. (ii) Historical: 50 Bedrock-era deposits (25
largest incl. a 10,000 ETH mint, 25 random) re-derived from their L1 logs (sourceHash, RLP 0x7e hash) and read on OP L2.
(iii) OVM 2.0: all 203,074 L2StandardBridge ETH `DepositFinalized` (L2 0..105,235,062) joined to the 317,436 L1SB
`ETHDepositInitiated`. (iv) L2 interop predeploys 0x…24/0x…25/0x…29 at L2 159,654,093.

**Barrier.** `OptimismPortal2.sol:757-758,790-794` (v9): the mint field is `msg.value` and the same `msg.value` is
locked; every path emits exactly one event with mint == lockbox delta; a value>0/mint 0 deposit locks nothing and mints
nothing. Historical: 50/50 L2 deposit txs exist with identical mint/value/from/gas; 203,074/203,074 OVM 2.0 mints match
an L1 lock (0 unbacked); OVM 2.0 supply is conserved exactly (ΔtotalSupply = Σmint − Σwithdrawn, 0 wei); the ETHLiquidity
proxy has no implementation and 0 balance (no interop mint source on OP).

**Evidence.** `fork-test-output.txt`, `op-l2-mint-sample.json`, `legacy-mint-join.json`, `l2-legacy-eth-mints.json.gz`.
