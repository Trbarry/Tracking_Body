# ATTACK-CATK-CMP1-10 — Third-party contract creates a gas-undeliverable stranger withdrawal

Families: gas budget + target authorization + bridge custody. Score: **3.0/10**.

An independent genesis-to-pin census decoded all 35,544 canonical OP relay payloads: 46 inner
senders, 38 contracts, 47 targets, zero parse failures. Maximum minimum gas was 8M and maximum data
was 416 bytes. The five 8M objects came from canonical L2StandardBridge and target only the fixed
L1StandardBridge.

Kill barrier: historical deployed objects never enter the capped band. In the largest sender-
controlled bridge cases, the gas choice is attached to the caller-funded bridge action and cannot
name an unrelated target. A latent arbitrary-payload contract surface was not demonstrated.

Evidence: `mirror/CATK-CMP1/evidence/gas-sender-census.json` and
`StandardBridge.sol:305-383`.
