# ATTACK-CATK-A-02 — broad execution-error deposit-only fallback

## Hypothesis

Because v1.7 retries every post-Holocene execution error as a deposit-only block, a user-controlled
execution failure might make the old prestate derive a different root from v1.9.

## Exact sequence tried

1. Direct-diffed `kona-driver` commit `c368ce9` and its exhaustive classifier.
2. Constructed the smallest source-level discriminator: `TrieDBError::Provider("missing witness")`.
   v1.7 flushes/retries deposit-only; v1.9 returns the executor error.
3. Traced error origins through the stateless trie/oracle and executor lifecycle and tested whether
   transaction calldata, value, gas, or a bad preimage can deterministically cause one on canonical
   state.

## Barrier

Canonical trie/provider reads succeed with an honest complete oracle. Preimages are hash-bound, so
an attacker cannot substitute different state; withholding data prevents progress rather than
authenticating a deposit-only output. Database/internal and missing-executor failures are likewise
node/witness conditions, not transaction-selected invalidity. No complete-oracle canonical witness
was found.

## Verdict

Rejected for lack of a permissionless deterministic trigger. Differential confidence: 9/10;
arbitrary-withdrawal exploitability: 0/10.

