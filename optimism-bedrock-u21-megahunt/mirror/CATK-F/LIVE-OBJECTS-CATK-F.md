# CATK-F live withdrawal objects

## Verdict

No unfinalized OP withdrawal at the pin gives an unprivileged sender authority over shared protocol
state. The live population contains expected bridge messages plus four bridge-targeted messages whose
committed L2 sender is not the canonical bridge; those four fail the bridge identity check.

Pins: OP L2 blocks `105235063..159654093`; Ethereum L1 block `26433900`. Collection used only
read-only JSON-RPC. Full rows and transaction hashes are in
`evidence/withdrawal-object-census.json`.

## Population census

| Population | Count | Result |
|---|---:|---|
| All OP `MessagePassed` events | 35,579 | Complete genesis-to-pin range |
| Outer target = canonical L1 messenger | 35,544 | 35,543 have canonical L2 messenger sender |
| Direct/non-messenger withdrawals | 35, 22 unique targets | 0 match the 379-address curated current/historical system inventory |
| L1 `WithdrawalProven*` events | 31,839 | 30,093 distinct proven withdrawals |
| Distinct finalized withdrawals | 26,000 | Joined by withdrawal hash |
| Distinct proven but never finalized | 4,093 | 4,080 target the canonical messenger |
| Noncanonical L1 proof events | 35, 32 distinct | 0 curated system targets |
| Decoded canonical relay payloads | 35,544 | 0 decode failures |
| Inner targets matching system inventory | 23,145 | Mostly canonical bridges |
| Unfinalized inner system messages | 3,702 | 682 proven; 3,020 not yet proven |

### Unfinalized inner system messages

| L1 target | Committed L2 sender | Proven | Unproven | Security meaning |
|---|---|---:|---:|---|
| OP L1StandardBridge | L2StandardBridge `0x4200…0010` | 676 | 2,998 | Expected bridge path |
| OP L1ERC721Bridge | L2ERC721Bridge `0x4200…0014` | 2 | 22 | Expected bridge path |
| OP L1StandardBridge | `0x2d2f…44cd` | 3 | 0 | Cannot satisfy `otherBridge` |
| OP L1StandardBridge | `0xece2…3504` | 1 | 0 | Cannot satisfy `otherBridge` |

`StandardBridge.onlyOtherBridge` requires both `msg.sender == messenger` and the messenger's committed
`xDomainMessageSender == otherBridge` (`StandardBridge.sol:111-115`). The fork suite proves that an
attacker may choose the L1 bridge as target but cannot choose the inner sender independently.

## Portal/caller-trust objects

- The only v9 runtime consumers found for `portal.l2Sender()` are L1CrossDomainMessenger and
  ETHLockbox. Messenger ingress requires both the exact portal and L2 messenger
  (`L1CrossDomainMessenger.sol:136-138`). Lockbox unlock additionally requires the portal's
  `l2Sender` to be the default sentinel, which is false during a withdrawal
  (`ETHLockbox.sol:157-174`).
- One withdrawal targets the canonical messenger with a noncanonical outer sender
  (`0xc0d3…0007`); it is unproven and cannot enter the first-relay branch.
- All 16 current source-portal/destination-L2 aliases have zero balance, no code, and match no checked
  privileged identity (`evidence/portal-alias-census.json`).
- Across 13 historical/current DelayedWETH objects and four portals: 52 portal balances, every live
  allowance, and every portal-involved Approval/Transfer event are zero/absent
  (`evidence/delayed-weth-portal-census.json`).

## Code-later object

Exactly one of 66 unique effective targets had no code at initiation and code at the L1 pin:
`0x00C7…23bC`. Withdrawal `0x21dee2…902e` is unproven, zero-value, and commits that same account as
both sender and target with selector `0x06684706`. Its current 23-byte EIP-7702 designator rejects the
selector in the pinned fork; L1 messenger marks the message failed. It cannot affect shared state and
is the account's own self-message.

