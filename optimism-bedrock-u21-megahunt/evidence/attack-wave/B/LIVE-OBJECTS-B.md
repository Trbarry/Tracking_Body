# LIVE-OBJECTS-B — messenger failure census, all four chains (ATK-B)

Scan: `eth_getLogs` via archive proxy :7545, blocks 17,422,444..26,433,900 in 10k windows, addresses =
4 portals + 4 L1CDMs, topics `WithdrawalFinalized(bytes32,bool)` (kept success=false) and
`FailedRelayedMessage(bytes32)`. Every hit decoded from `debug_traceTransaction` (callTracer); mappings
read at 26,433,900. Raw: `scan-failures-all-chains.json`, decoded: `census-decoded.json`, scripts `scan.py`, `decode.py`.

L1CDM addresses / ETH balance @26433900 (also 0 at 18.5M, 20M, 22M): OP 0x25ace71c… 0; Ink 0x69d3Cf86… 0;
Soneium 0x9CF951E3… 0 (no failure ever); Unichain 0x9A3D64E3… 0 (no failure ever).

## A. FailedRelayedMessage — 30 logs, 22 distinct hashes (OP 18, Ink 3)

Value-bearing (all 4 now `successfulMessages = true`, replayed; nothing parked):

| chain | msgHash | first fail block | value (ETH) | target | status @pin |
|---|---|---|---|---|---|
| Ink | 0x940ba5ec…7941 | 22,419,550 | 17.294 | 0x0f703cf7… | delivered |
| Ink | 0xd9204ef4…b8fe | 23,096,290 (+4 failed replays) | 58.326 | 0x0f703cf7… | delivered |
| Ink | 0xfac7aaf7…4445 | 23,175,112 | 15.866 | 0x0f703cf7… | delivered |
| OP | 0x4469d07d…3276 | 26,346,791 (v8) | 236.750 | 0x23CA5E53… | delivered |

Still failed at the pin: 15 OP hashes, ALL value 0 (consistent with L1CDM balance 0). v9 replay by an
unrelated EOA (test_E1): 3 deliver now (0x18b123eb, 0x6c9a36ef, 0x71c9882b: ERC20 via L1StandardBridge,
unclaimed); 12 still fail for target-side reasons:
- `deposits[l1][l2]` underflow in L1StandardBridge (0x1829f5fe token 0xd17d5c95/L2 0x96bBD554, 50,123 units;
  0xe43cf22b token 0xBB9bc244/L2 0x7093f7CC, 5.091): withdrawal of an L2 token pair that was never deposited
  (per-pair accounting working as designed).
- token reverts on transfer (0x2c820221, 0xdc594bf2, 0x09af464a: token 0x48AFbBd3 custom error 0x11bad8f5).
- third-party targets: Hop `TransferRoot already confirmed` (0x33f61390), Synthetix bridge
  `Must be proxy target`/state (0x43e0b785, 0xb53bc394, 0xae100545, 0x9546105b), legacy gateway
  `Invalid l1Token` (0xe208b527), token `SafeMath: subtraction overflow` (0x384bf7ec, L1CDM has no balance).
None is caused by a third party; none carries ETH.

## B. WithdrawalFinalized(success=false) — 4 hits, all OP, all legacy (version-0) migrated withdrawals

| block | withdrawal hash | value | legacy (v0) hash successfulMessages | v1 failed/successful |
|---|---|---|---|---|
| 25,149,695 | 0x50d7b362…6ddd | 0.6087 ETH | true | false/false |
| 25,149,748 | 0x64db0ab9…a7ec | 0.001 ETH | true | false/false |
| 25,163,168 | 0xd3628e07…5977 | 1.5220 ETH | true | false/false |
| 26,139,841 | 0xad0a2811…8ec4 | 0 ETH (legacy WBTC 0.4968 finalizeERC20Withdrawal) | true | false/false |

L1CDM reverted at `legacy withdrawal already relayed` (CrossDomainMessenger.sol:231): these were already
paid by the pre-Bedrock messenger; the v8 portal relocked the ETH into the lockbox (trace: lockbox
0x1ee116bf lockETH after the reverted relay). "Finalized, unknown to messenger" but NO stranded value:
double-withdrawal attempts that failed safely. Under v9 the same input reverts the whole finalize (:652).

## C. Production objects matching the attack precondition (forced-fail victims)

Every proven, mature, unfinalized L2CDM withdrawal on OP/Ink/Unichain (e.g. PASS A fixtures f1..f8,
`withdrawal-fixtures-all.json` class pre_mature_valid: 24 entries incl. 638.18 ETH 0xb16e5fc2…, CRV x9,
LINK 95.4, WBTC-like 0xa693B19d). Targets observed: L1StandardBridge (ETH/ERC20/legacy), 0x23CA5E53 impl
0xc25b0d51 (checks xDomainMessageSender only), Hop, Synthetix, L1ERC721Bridge — bytecode scan: none reads
`portal.l2Sender()` (selector 0x9bf62d82); all read `xDomainMessageSender()`, which a replay sets.
