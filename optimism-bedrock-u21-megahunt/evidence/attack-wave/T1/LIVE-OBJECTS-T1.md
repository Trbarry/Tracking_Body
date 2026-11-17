# LIVE-OBJECTS-T1 — production objects matching the fix-regression preconditions (L1 block 26433900)

Lane ATK-T1, Opus 5.5. Passive reads through the pinned fork / proxies only. None of these objects satisfies an attacker precondition;
they are the populations each kill was evaluated against.

| Target | Chain | Object | Why it matches / what was read |
|---|---|---|---|
| 1, 13 | all four | factory game types ever configured {0,1,4,5,8,9,10}; live: type 5 impl 0x5C3eb47c…D691 (args 40 B) on all four, type 9 impl 0x19AF533C…3208 (args 124 B, bond 0.08 ETH) on OP/Ink/Unichain | candidates for a foreign-bound registered implementation; every live args blob names only the portal's ASR (`dgf-config-events.json`, `T1_Registry.out.txt`) |
| 2 | OP / Ink / Soneium / Unichain | anchors 0x55A5CFd4…6f95 (type 9, seq 1794298459) / 0x38925ef2…8945 (9) / 0x5dFB50E0…C454 (5) / 0x944a783a…AfD5 (9) | anchor that later gets invalidated: all claim-valid, none blacklisted/retired; 0 guardian events on the 4 current ASRs since 22,980,000 (`asr-guardian-events.json`) |
| 3, 12 | OP | withdrawal 0x38479d42…9218, 119.592959152653799482 ETH, L2CDM->L1CDM, proven by 0xb9B397fb…F35B on game #21359 (0xdABd4b65…7e70) in tx 0x1214545b…5c0a | real per-submitter record used for third-party re-prove / re-prove-after-finalize / delete (`T1_Games_09_10.out.txt`) |
| 7 | OP | game #21359 (type 9, unchallenged, newer than the anchor) | real game whose `closeGame` was gas-searched |
| 9 | all four | portal legacy slots: 53 = 0x…95703e0982140d16f8eba6d158fccede42f04a4c00, 56 = own DGF, 59 = legacy respected type/timestamp (Soneium low byte 1), 63 = own lockbox | non-default residue in never-cleared spacers; never read by v9 (`T1_Portal_04_05_06.out.txt`) |
| 11 | all four | type-5 proposers 0xc27ba3E0…5bE0 (OP), 0x3832bfbe…D177 (Ink), 0x400c164C…E1b8 (Soneium, respected), 0x86b392cA…75b7 (Unichain) | tx.origin-authorised creators: code-less EOAs (no 7702 delegation) |
| 14 | OP / Ink / Unichain | in-progress old-prestate (0x031ac6f1…) type-9 games among the last 120: 74 / 7 / 75 | games judged by kona-client v1.7.0 (Lane A domain) |
| 15 | all four | 23 DelayedWETH generations, 48.272955 ETH total (current 2.0.0: OP 20.662782, Unichain 21.419797, Ink 5.710376; Soneium 0) | old proxies holding bonds after re-pointing (`T1_Extra_11_12_13.out.txt`) |
