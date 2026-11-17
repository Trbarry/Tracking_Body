# ATTACK-CATK-D-03 — Future shared-game migration amplifies the trojan

## Hypothesis

Once OP and other chains share one super-root game/registry, an extra unrelated chain, unsorted entries, and duplicate OP entries could turn one malicious game into a cross-chain withdrawal-delay primitive.

## Exact sequence executed

On the current deployed type-9 implementation, `test_futureSharedShape_unsortedExtraChainAndDuplicateOpStillProves` created a preimage ordered as chain 130 bogus root, chain 10 genuine root, duplicate chain 10 bogus root. The deployed portal found the first OP entry and accepted a real OP withdrawal proof.

## Barrier / kill

- OP Mainnet is not yet using a shared multi-chain registry for this path; cross-chain reach is future-only.
- The current OP proof remains keyed by submitter and immediately replaceable with an honest-game proof.
- A noncanonical chain list loses under the standard Kona fault-proof model; this exact onchain-vs-proof-program validation split is known (CC25 3.1.6/3.1.7; closure C12).
- No irreversible pre-positioning across `migrateToSharedDisputeGame` was found; migration invalidates/requires re-proof by design.

The fork test preserves the future shape as regression evidence, but it adds no current eligible impact. Applying the base score from CATK-D-01 and the `-5 future-only without irreversible pre-positioning` deduction yields `-10`.

Decision: reject; future-only composition with the same impact barrier.
