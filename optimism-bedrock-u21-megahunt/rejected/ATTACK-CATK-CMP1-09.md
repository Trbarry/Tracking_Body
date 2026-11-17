# ATTACK-CATK-CMP1-09 — Forced ETH plus sticky lockbox authorization enables sibling withdrawal

Families: custody/lockbox + migration residue + sibling portal identity. Score: **2.0/10**.

C09 force-sent attacker-funded ETH to the deployed OP lockbox. Direct attacker `unlockETH` failed.
Even a locally modeled Ink portal caller could not call OP `lockETH`; the OP authorization matrix is
`true,false,false,false` across OP/Ink/Soneium/Unichain. Balance remained unchanged.

Kill barrier: sticky authorization preserves only an exact portal address. After migration, portal
code calls its current lockbox pointer; no unprivileged input selects the retired lockbox. Lockbox
authorization and migration are ProxyAdmin-owner gated, and withdrawal-time `l2Sender` is separately
rejected by `unlockETH`.

Evidence: C09; `ETHLockbox.sol:142-215`.
