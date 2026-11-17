# LANE F — UNSAFE TARGETS AND SURVIVING SYSTEM-CONTRACT TRUST

Inputs: BW0-06, A-014; current and historical portals, lockboxes, messengers, registries, factories,
bridges, SystemConfigs, ProxyAdmins. Key fact: any withdrawal ever initiated on L2 (it is permanent in
L2ToL1MessagePasser `sentMessages`) and never finalized can be PROVEN TODAY against a current game and
finalized with `msg.sender == portal`, calling its original L1 target with its original data. The portal
blocks only `_isUnsafeTarget` = {portal, current ethLockbox} at prove and finalize.

Mission:
1. Enumerate unfinalized withdrawals whose L1 target is a current or historical system contract (or a
   contract that ACCEPTS calls from the portal / trusts `msg.sender == portal` / reads `portal.l2Sender()`):
   sources: L1 `WithdrawalProven` events and their prove calldata (`evidence/F4/` has OP withdrawal events
   incl. 3,281 never-finalized legacy-era withdrawals; PASS A fixtures); L2 `MessagePassed` events on OP
   via `http://127.0.0.1:7546` (indexed `nonce`, `sender`, `target` — filter by target in the
   system-contract address set; the target topic filter makes this cheap); Ink/Soneium/Unichain via their
   public RPCs passively if feasible. Write `LIVE-OBJECTS-F.md`.
2. Build the target matrix for ALL generations (addresses from `chains/*/HISTORY.md`,
   `evidence/F2-impl-history-*.json`, `RELEASE-DAG.md`): for each contract — accepts calls from the portal?
   treats the portal as authority (exact check, file:line)? accepts ETH? can change authorization,
   ownership, pause, custody, game state, bridge state or accounting?
3. Attempt (on a fork, from an unprivileged L2 sender's withdrawal — you may build the proven state for
   an attacker-authored withdrawal by proving a real attacker-created L2 withdrawal if one exists, or
   fabricate the proven entry with vm.store as a VEHICLE and say so; then also show an attacker can
   create such a withdrawal on L2 today) withdrawals to: retired lockboxes; sibling portals (other chains);
   old ASRs / DelayedWETHs; current/old messengers and bridges; SystemConfig; ProxyAdmin-adjacent
   contracts; AddressManager; contracts whose address became code only after the L2 withdrawal was
   initiated (a CREATE2/CREATE address an attacker can predict now and deploy later).
4. Look for a call that is benign under the target's original type but privileged under its later code.
5. Prove current permissionless reachability and a direct impact on SHARED protocol state. Reject
   self-donation and moving only the attacker's own assets.
