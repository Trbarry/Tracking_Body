# Lane 30 — pre-U21 in-flight scan

Read-only JSON-RPC batching against `http://127.0.0.1:8546`, block `0x1934d8a`. Selectors:

- DGF `gameAtIndex(uint256)`: `0xbb8aa1fc`
- game `status()`: `0x200d2ed2`
- `anchorStateRegistry()`: `0x5c0cba33`
- `weth()`: `0x3fc8cef3`
- `vm()`: `0x3a768463`
- `absolutePrestate()`: `0x8d450a95`

The scanned tail was indices 20878 through 21377 inclusive. It covers 500/21378 games and about 20.7 days of creation time, much longer than the 302400-second maximum game clock, but it is explicitly a tail sample rather than a claim about every historical unresolved game.

```text
FETCHED 500
TYPE_COUNTS {9: 500}
FIRST type 9: index 20878, createdAt 1793080523
LAST  type 9: index 21377, createdAt 1794870155

STATUS 500
IN_PROGRESS 84
INDEX_RANGE 21294..21377
CREATED_RANGE 1794571403..1794870155

GROUP 84:
  type     9
  VM       0xacc005dcd857b401e4732e6f7837135a22825cfa
  ASR      0x23b2c62946350f4246f9f9d027e071f0264fd113
  WETH     0x1b6dbf05eaf22d4e70dc993e8a19dd9f3dcb3162
  prestate 0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df
```

The N block timestamp is 1794871439, so the final sampled game predates U21 by 1284 seconds. `gameCount()` is 21378 at both N−1 and N. The representative fork PoC uses that final game.
