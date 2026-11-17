# PRIM-CF6-02 — failed cross-domain message replay bit survives v7 -> v9

- **Earliest semantic ancestor:** v7-era real `FailedRelayedMessage`, tx
  `0x8c899957c12979b99a02e680e8d695386056ec968fea0cc5d07405b809d27622`,
  L1 block 25475826.
- **Current consumer:** v9 `CrossDomainMessenger.relayMessage` replay branch.
- **Releases crossed:** v7 -> v8 -> v9.
- **Chains affected:** OP Mainnet demonstrated.
- **Source contracts + functions:** v7 `src/universal/CrossDomainMessenger.sol:222-308`; v9
  `src/universal/CrossDomainMessenger.sol:209-295`, pinned at commits
  `a7c88c8d636ceb9944ea0edaf7d033da258778ab` and
  `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`.
- **Persistent object or state:** `failedMessages[msgHash] = true` while
  `successfulMessages[msgHash] = false`.
- **Trigger:** replay the real v7 portal finalization calldata that emits the failure, carry the
  messenger proxy account through v8/v9 official replays, then call its real `relayMessage`
  calldata permissionlessly.
- **Attacker-controlled inputs:** replay caller and supplied gas; message tuple is historical.
- **Required pre-state:** failed bit true, successful bit false, version-1 message hash.
- **State mutation:** the initial failed bit is written under v7. The tested v9 replay returns
  normally but the target fails again, so the failed bit remains true and success remains false.
- **External calls:** messenger -> historical message target.
- **Identity dependencies:** `keccak256(relayMessage calldata)` message hash, messenger proxy,
  AddressManager implementation entry.
- **Broken or weakened assumption:** none observed. The replay authorization survives both upgrades.
- **Candidate compositions:** target behavior changes across upgrades; value-bearing failed messages;
  pause/migration around replay.
- **Current production evidence:** real event message hash
  `0x43e0b78554c436637d3a3f6383edce9dd460777a14776a6b035c604c38bd0deb`;
  `CarryThroughTest::test_v7_failed_message_replays_after_v8_v9` passes.
- **Reason it may be benign:** a repeated target failure is expected; crucially the retry bit is not
  cleared or converted into an unreplayable terminal state.
- **Exact falsification experiment:** rerun the named test and inspect the three logged stages; any
  clearing of `failedMessages`, premature `successfulMessages`, or replay revert fails the test.
- **Confidence:** high.
- **Audit coverage:**
- **Nearest known finding:**
