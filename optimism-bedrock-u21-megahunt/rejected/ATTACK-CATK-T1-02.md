# ATTACK-CATK-T1-02 — stale blacklisted/retired/de-respected anchor

## Hypothesis

Because `getAnchorRoot()` does not revalidate `anchorGame`, an attacker invalidates the live anchor
after finality and makes later games inherit a stale root.

## Original condition and changed precondition

The original safety condition was that invalid games are invalidated before they become anchors.
v9 deliberately returns the anchor without blacklist/retirement/type checks
(`AnchorStateRegistry.sol:203-213`). The relevant transition functions are guardian-only
(`:156-185`). Instead of repeating the known stale-anchor observation, the executed mutation asks
whether a permissionless sibling/post-upgrade entrypoint can create the transition.

## Exact sequence and result

For the live OP, Ink, Soneium and Unichain anchor, the attacker calls
`blacklistDisputeGame(anchor)`, `updateRetirementTimestamp()` and
`setRespectedGameType(current+1)`. All 12 calls revert. Anchor address, retirement timestamp and
respected type remain bit-for-bit unchanged; none of the anchors becomes blacklisted.

## Barrier and evidence

Only the configured guardian can create the state on which the mutation depends. Malicious or
arbitrary guardian behavior is excluded, and a stale anchor after such action is already
acknowledged (known-findings blacklist Part 2 item 5). Test
`test_T02_anchorInvalidationTransitionsAreGuardianOnly` passes at
`mirror/CATK-T1/test/FixRegressionCATKT1.t.sol:262`. Deterministic privileged-only/known kill; no
candidate.

