# ATTACK-T3-06 — ERC721 bridge deltas up to 2.9.1: pause source, deposits mapping, finalize checks

Lane ATK-T3 (bridge token identity / L1ERC721Bridge / OptimismMintableERC20Factory), Opus 5.5 (CLAUDE.md exception, Mythos 5.2 quota until 2026-11-22). Sources: op-contracts v9.0.0 (`/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/src`). PoC: `test/poc/attack-wave/T3/test/T3.t.sol`; run output `evidence/attack-wave/T3/forge-final.txt` (9/9 PASS). Kill type: layout history + census + fork read.

**Hypothesis.** Version deltas of L1ERC721Bridge (superchainConfig -> spacer, `systemConfig` pause source at v4.0.0, 2.9.1) moved
the `deposits` mapping (old escrows unreleasable = permanent freeze) or left the bridge on a pause pointer that diverges from the
portal's.

**Executed.** Storage-layout snapshots v1.2.0..v9.0.0 (`hist/*/snapshots/storageLayout/L1ERC721Bridge.json`): `deposits` at slot 49
in every version; superchainConfig slot 50 became `spacer_50_0_20`, `systemConfig` added at 51. Empirically all 14,263
outstanding escrows (from 2022 onward) read true at slot 49 (ATTACK-T3-05). `test_C3_pauseSource_consistent`:
L1ERC721Bridge.systemConfig() == L1StandardBridge.systemConfig() == portal.systemConfig() == 0x229047fe…B290, both unpaused.
Finalize checks unchanged v8 -> v9 (diff is formatting only; implementation 0x9f164f1d… identical at N-1 and N).

**Barrier.** No slot reuse; pause resolves through the same SystemConfig as the portal (behaviour with the lockbox identifier paused
already executed in PASS A D11 / C8). KILLED.
