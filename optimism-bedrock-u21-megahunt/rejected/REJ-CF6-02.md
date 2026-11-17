# REJ-CF6-02 — v8/v9 erase failed-message replay authorization

**Hypothesis.** A `failedMessages[msgHash]` bit written by v7 is cleared, re-keyed, or rejected by
the post-U21 messenger, permanently losing the retry path.

**Killing fact.** `CarryThroughTest::test_v7_failed_message_replays_after_v8_v9` creates the bit by
replaying the real v7 portal finalization transaction that emitted `FailedRelayedMessage`, executes
the official v8 and v9 upgrade calls, and invokes the exact historical `relayMessage` calldata.
The bit remains true after each upgrade. The v9 call returns normally and fails at the historical
target again, leaving the message retryable rather than finalized or erased.

**Evidence.** Message hash
`0x43e0b78554c436637d3a3f6383edce9dd460777a14776a6b035c604c38bd0deb`;
fixture `mirror/CF6/fixtures/failed-message-v7.json`; v7 replay gates/writes at pinned
`op-contracts/v7.0.0/src/universal/CrossDomainMessenger.sol:222-308`; v9 gates/writes at pinned
`op-contracts/v9.0.0/src/universal/CrossDomainMessenger.sol:209-295`; named test above.

**Scope of rejection.** One real zero-value v7 failed message across v8/v9. Value-bearing failures,
pre-Bedrock nonce versions, and migration/pause compositions remain open.
