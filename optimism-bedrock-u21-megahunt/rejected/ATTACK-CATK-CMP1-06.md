# ATTACK-CATK-CMP1-06 — EIP-7825 makes a real parked application message undeliverable

Families: gas budget + messenger replay + third-party target. Score: **2.5/10**.

C06 replayed the real 363.438 ETH application message inside a 16,000,000-gas call, below the
`2^24` transaction cap, and settled it. The independent OP population census found a maximum
committed minimum gas of 8,000,000, maximum outer gas of 8,415,632, and maximum message length of
416 bytes.

Kill barrier: neither the real fixture nor any historical live OP object reaches the post-cap
undeliverable band. Sender-chosen future self-grief remains possible but does not create an
unrelated victim.

Evidence: C06 and `mirror/CATK-CMP1/evidence/gas-sender-census.json`.
