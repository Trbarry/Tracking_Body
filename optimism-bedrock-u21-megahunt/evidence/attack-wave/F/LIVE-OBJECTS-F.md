# LIVE-OBJECTS-F — production objects matching ATK-F preconditions

Lane ATK-F, Opus 5.5. Precondition: an unfinalized (or replayable) withdrawal / authority whose L1 target is a system contract or
a contract that trusts the portal or the L1CDM as caller. Sources: L1 archive proxy :7545, OP L2 archive :7546, pinned :8545 (26433900).
Scripts: `scripts/attack-wave-F/{scan_l1_proven.py,curate_set.py,scan_l2_op.py}`.

Address set: 611 addresses from chains/*/{DEPLOYMENT,STATE-U21}.json, chains/*/HISTORY.md, F2 impl/game histories, LANE_CONTEXT,
SCOPE, U21 proxy map, plus 8 DelayedWETH generations and WETH9 (`system-address-set-raw.json`); 477 have code at 26433900
(`system-contract-set.json`).

| Id | Chain | Object | Block | Why it matches | Status / why harmless |
|---|---|---|---|---|---|
| L1-1 | OP / Ink / Soneium / Unichain | 31,804 / 1,054 / 1,925 / 3,692 `WithdrawalProven` with target = own L1CDM, sender = L2CDM | 17.0M..26.43M | target trusts portal | normal messenger path (ATK-B lane); no other sender -> L1CDM |
| L1-2 | OP | hash 0x45fd4bbc…0ebd, sender L2CDM -> 0x394400571c… (16 kB contract, game creator) | 20,873,192 | sender L2CDM with a non-L1CDM target | forged: proven against that creator's own CHALLENGER_WINS game; not finalized |
| L1-3 | OP | hash 0x0cf8309e…7e4a, sender 0x…dEaD -> 0x7813cc25… (EOA) | 26,404,222 | l2Sender == DEFAULT trick | forged (`sentMessages` false on L2), game 0xa5714949… CHALLENGER_WINS; deletable (ATTACK-F-04) |
| L1-4 | OP | hash 0x3e9259dd…73c2, 0x00b700b9… -> WETH9.approve(0x00b700b9…, ~max) | 19,608,765 (L2 118,450,437) | portal-owned allowance | finalized; portal WETH balance 0 |
| L1-5 | OP/Ink/Unichain | 10 proven withdrawals to code-less EOAs (game creators / deployers, mostly from == to) | various | target with no code (could gain code) | no code at 26433900; not system addresses |
| A-1 | Unichain | USDC allowance 0x66ba29ab… -> Unichain L1CDM 0x9a3d64e3…, 9 USDC, balance 2.531863 | 25,084,528 | L1CDM-spendable allowance | live, spendable by any Unichain L2 user (F09 PASS); victim error, rejected (ATTACK-F-05) |
| A-2 | OP | "Nolimit" 0x69eb276b… allowance 2^128 from 0x44afc83b… -> OP portal | 25,867,951 | portal-spendable allowance | spam token, no value |
| P-1 | Soneium | proposer 0x400c164C…E1b8, nonce 8537 == gameCount 8537 (all games by it) | 26,433,900 | tx.origin-authorized type-5 games (respected) | proposer never sent a non-create tx (ATTACK-F-07) |
| L2-1 | OP L2 | `MessagePassed` to any non-L1CDM L1 system contract (477 addresses), L2 105,235,063..159,654,093 | — | unproven object to a system target | 1 hit = L1-4; none to lockboxes, portals, registries, factories, SystemConfig, ProxyAdmin, AddressManager, bridges, WETHs |

Balances held by the 4 portals and 4 L1CDMs (WETH9, USDC, USDT, DAI, wstETH, LINK, DelayedWETH g1 + v2) at 26433900: all 0.
Not scanned: Ink/Soneium/Unichain L2 `MessagePassed` (public RPCs cap eth_getLogs at 1000 blocks; ~30-60M blocks each). Their
proven withdrawals are fully covered by the L1 scan.
