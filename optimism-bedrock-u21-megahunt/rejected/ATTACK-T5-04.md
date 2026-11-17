# ATTACK-T5-04 — donations / forced ETH / governance moves hide a deficit or create an exploitable gap (KILLED)

**Hypothesis.** Eventless ETH (donateETH, SELFDESTRUCT, governance transfers) inflates custody and masks a deficit, or an
attacker can use it to make custody accounting diverge from L2 claims.

**Sequence executed.** Pre-Bedrock L1SB ledger (balance − (ΣETHDepositInitiated − ΣETHWithdrawalFinalized), 317,436 +
9,294 events, L1 12,686,786..17,423,157) with bisection of every residual jump; post-Bedrock ledger (ATTACK-T5-03);
fork test `test_T5_donations_and_forced_eth_are_surplus_only`.

**Barrier.** Exactly three eventless inflows ever, 3.264939988000841220 ETH: 1.740038988 ETH (L1 12,688,132) and
1.522901 ETH (12,782,215), both Safe `0x9ba6e03d…` `execTransaction` → `migrateEth(L1SB)` (0x175dc507) on the retired
OVM 1.0 ETH gateways `0xe681F809…` and `0xF20C38fC…` (moving already-backed ETH); 0.002 ETH public `donateETH()`
(17,140,200). Zero after Bedrock (residual 0). On deployed bytecode donations emit no `TransactionDeposited`, so they can
only add custody. They cannot hide a deficit because the liability side is built independently from L2/L1 events.

**Evidence.** `legacy-l1sb-residual.json`, `legacy-l1sb-eth-*.json.gz`, `fork-test-output.txt`.
