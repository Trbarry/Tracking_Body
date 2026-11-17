# REJ-CF5-01 — OP-only legacy slots do not affect v9 behavior

OP alone retains nonzero XDM slots 51/151, L1StandardBridge slot 1, and Portal slot 54; all are zero on Ink, Soneium, and Unichain (`mirror/CF5/evidence/pinned-cast-reads.txt:133-153`). In v9 these locations are private spacers (`CrossDomainMessenger.sol:40,63`, `StandardBridge.sol:38`, `OptimismPortal2.sol:82`). No executable code reads them. Rejected as inert layout residue.
