# ATTACK-CATK-D-01 — Trojan super-root as a sustained withdrawal-delay engine

## Hypothesis

A permissionless attacker creates a type-9 game whose preimage has duplicate/unsorted chain entries. The first OP entry is a genuine output root, so a real withdrawal proof succeeds. Honest fault proving later makes the game lose; deletion/re-proving resets the user's seven-day timer. Repeated games might freeze unrelated users.

## Exact sequence executed

1. Fork Ethereum at block 26,433,900.
2. Create a type-9 game through the deployed factory with 0.08 ETH and duplicate chain-10 entries.
3. Use a real OP withdrawal and MPT proof; confirm the portal stores the new game in the attacker's submitter slot.
4. Repeat with OP block 159,654,093's exact timestamp/output proof, matching what op-node/viem recompute.
5. Model the malformed game's expected challenger-win status with an explicitly labelled harness-only status-byte change; delete permissionlessly and re-prove against a real honest game.
6. Separately delete a real proof against real challenger-wins game 21288; confirm its root counterer received at least the 0.08 ETH root bond.
7. Re-prove from the same submitter against an honest game immediately, without deletion or status change.

Evidence: `mirror/CATK-D/tests/TrojanSuperRoot.t.sol`; all eight fork tests pass. Live objects and measurements are under `mirror/CATK-D/evidence/`.

## Barrier / kill

The primitive is real, but the claimed impact is not:

- storage is keyed by `(withdrawalHash, msg.sender)`; the attacker cannot alter an unrelated user/relayer proof;
- the affected submitter can immediately select an honest game and overwrite its own slot; no upgrade or challenger-win wait is required;
- repetition depends on the victim/tool voluntarily signing another proof using another malicious game;
- portal acceptance of noncanonical super-root preimages is already documented as left to the proof program (known-findings blacklist: CC25 3.1.6, 3.1.7; closure C12);
- the withdrawal itself is genuine, so this is not “Incorrectly proven withdrawal”; bonds are excluded from Critical/High impacts.

The closest scope line is High “Temporary freezing of funds ... (e.g. recoverable via an upgrade)”, but the demonstrated recovery is a permissionless immediate re-proof, not an upgrade. This is retryable inconvenience/tooling griefing.

## Honest score

`+2 permissionless +2 current production reachability +2 deployed-bytecode PoC +1 unrelated tooling user +1 repeatable/multi-victim +1 cross-contract -4 victim/tool selects object -4 known root cause -3 retryable inconvenience -3 no eligible impact = -5`.

Decision: reject; no candidate file.
