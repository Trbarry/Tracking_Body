# REJ-CF5-05 — type-5/type-9 behavioral split is documented policy, not authorization bypass

The same-calldata fork test proves OP type-9 creation succeeds while Soneium reverts. U20 explicitly made OP/Ink/Unichain permissionless type 9 and Soneium proposer-only type 5 (`superchain-ops/src/tasks/eth/071-U20-op-ink-soneium-uni/README.md:16-30`); U21 expressly retained the split (`eth/084-U21-op-ink-soneium-uni/README.md:16-29`). No actor gains a capability forbidden by that chain's configured policy. Rejected as intended configuration.
