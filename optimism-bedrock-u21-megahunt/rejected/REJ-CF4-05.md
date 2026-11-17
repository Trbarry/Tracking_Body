# REJ-CF4-05 — Legacy messenger mapping aliases active replay state

## Hypothesis

Legacy hashed entries under base 201 or 202 collide with current `successfulMessages` or
`failedMessages`, altering replay protection.

## Falsification

The namespaces have distinct base slots: legacy spacers 201/202, successful 203, failed 206. A
production 2021 relay hash remains one only under base 203. Fork test
`testLegacyMessengerNamespacesRemainDisjointUnderJunk` sets the exact 201/202 entries to all ones
and observes unchanged successful/failed getters.

## Verdict

Rejected by exact derivation and named block-26433900 fork test.
