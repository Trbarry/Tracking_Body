# ATTACK-E-06 — hidden pre-positioning at the CREATE2 addresses of the shared lockbox/ASR/DGF (KILLED)

**Hypothesis.** An attacker who predicts the shared proxies' addresses (salt mixes `block.timestamp`, deployer = Safe)
pre-funds them so the honest migrate reverts (address collision) or installs a shared lockbox with unexpected state.

**Sequence executed.** `test/poc/attack-wave/E/test/ATKE_Poison.t.sol::test_E08_prefund_predicted_shared_addresses`: same-block clean migrate to learn the
addresses, revert, attacker SELFDESTRUCT-funds lockbox +5 ETH, ASR +1, DGF +1, then migrate.

**Barrier.** Migrate succeeds with identical addresses; balance does not block CREATE2 (only code/nonce/storage do,
none of which an EOA can place at a Safe-derived CREATE2 address — C10/C14). The 5 ETH is lockbox surplus
(balance clean + 5 ETH). No code, storage or authorization can be pre-placed.

**Evidence.** forge-E04-E08-E09.txt, E08-prefund-create2.txt.
