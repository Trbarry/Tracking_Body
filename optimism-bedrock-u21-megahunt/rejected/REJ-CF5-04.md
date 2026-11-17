# REJ-CF5-04 — pause history does not leave a target chain paused or bypassed

The shared SuperchainConfig emitted one global pause at block 22,482,108 and an unpause 636 seconds later. Its only address pause was `0x758e…` (Swell Portal), not a target lockbox, and expired under the three-month v9 rule. Each target lockbox and the global identifier read false at block 26,433,900 (`mirror/CF5/evidence/pinned-cast-reads.txt:122-132`). No missing-unpause or identifier-collision candidate.
