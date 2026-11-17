# REJ-CF4-02 — Non-zero spacers are reinterpreted or read by v9 tooling

## Hypothesis

Portal, messenger, bridge, ERC721 bridge, or DelayedWETH stale direct slots are occupied by a new
field or consumed by OPCM/StandardValidator/migration raw-slot logic.

## Falsification

`mirror/CF4/evidence/direct-slot-liveness.json` binds every non-zero boundary slot to its v9
meaning. All meaning-changed production values remain explicit spacers. V9 source search found raw
access only for the layout-derived initializer byte, OZ-v5 guard, messenger active slot 204, portal
reserved slot 61, and ResolvedDelegateProxy special mapping. StandardValidator uses typed getters.

## Verdict

Rejected at op-contracts/v9.0.0 and block 26433900. No X-to-Y live-field collision found.
