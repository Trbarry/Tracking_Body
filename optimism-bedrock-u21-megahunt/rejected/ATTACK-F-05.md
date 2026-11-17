# ATTACK-F-05 — Live ERC20 allowances to portals / L1CrossDomainMessengers spendable by any L2 user

Lane ATK-F, Opus 5.5. Kill type: scored below threshold (victim-error object, negligible value). PoC passes.

**Hypothesis.** Portal and L1CDM execute arbitrary attacker calls; any allowance granted to them is spendable by anyone.

**Scan.** `Approval`/`ApprovalForAll` logs with spender/operator in {4 portals, 4 L1CDMs}, L1 blocks 12,689,408..head ~26,434,000 (:7545):
2 approvals, 0 ApprovalForAll (`evidence/attack-wave/F/approvals-latest.json`).
1. USDC owner 0x66ba29ab…3d79 -> Unichain L1CDM 0x9a3d64e3…, 9 USDC (block 25,084,528); owner balance 2.531863 USDC.
2. "Nolimit"/nlt 0x69eb276b… owner 0x44afc83b… -> OP portal, 2^128 (block 25,867,951): spam token, owner holds the whole supply.
Plus a pre-existing WETH9 allowance FROM the OP portal (max, to 0x00b700b9…, set by a finalized withdrawal at 19,608,765); portal WETH balance 0.
Token balances of the 4 portals and 4 L1CDMs in WETH/USDC/USDT/DAI/wstETH/LINK/DelayedWETH g1+v2: all 0.

**Sequence executed.** `test_F09_liveAllowanceToMessenger`: on OP L2 any EOA calls `L2CDM.sendMessage` (shape); on L1 the
Unichain portal finalizes (vehicle proof) a sender=L2CDM withdrawal relaying `USDC.transferFrom(victim, attacker, 2,531,863)`. PASS.

**Score.** +2 permissionless, +2 current, +2 PoC (vehicle), +2 "Loss of user funds by direct theft", +1 unrelated victim;
-4 victim voluntarily approved a generic call executor, -4 documented messenger behaviour (arbitrary target, msg.sender = L1CDM).
Total 1 (< 7) and 2.53 USD at risk. Rejected; not a protocol defect.
