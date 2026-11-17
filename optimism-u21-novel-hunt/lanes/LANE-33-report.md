# Lane 33 report — Scope Snapshot

**Date:** 2026-11-17 UTC  
**Result:** Scope mapped; no vulnerability candidate asserted.  
**Main deliverable:** `mirror/lane-33/SCOPE_SNAPSHOT.md`

## Objective and independence

Independently determine the live Immunefi Optimism scope and Upgrade 21 governance/deployment scope without reading any other lane output or audit findings. The only shared-hunt file read was `LANE_CONTEXT.md`; the allowed U21 transaction/receipt JSON was read only for execution metadata. All writes are lane-33 paths.

## Safety and method

- Created the required isolated harness at `/home/user/u21-work/codex-33/h` and added `l1n = http://127.0.0.1:8547`.
- Made no transaction, broadcast, impersonation, fork mutation, `anvil_*`, or `evm_*` call.
- Live retrievals were HTTP GETs only.
- Chain verification used only `cast storage` and `cast call` against the read-only block-N local fork.
- Did not open any audit PDF. Only the U21 audit filename/title was recorded.

## Eligibility decision model

1. Exact address in live Assets in Scope → **A (explicit)**.
2. Exact A asset is a proxy and the affected code is its live implementation → **B (proxy clause)**.
3. Address absent, but a listed Smart Contract/Blockchain impact is demonstrated → **C (Primacy of Impact)**; the programme’s named chains are OP, Ink, Soneium and Unichain.
4. U21 code/calldata also receives the official Protocol Upgrade Proposal route because topic 10948 was OP Labs-authored and reached/succeeded in the official vote.
5. No row, no listed impact, and no applicable proposal-code route → **D (out of scope/unknown)**.

The proposal route supplements but does not erase address precision. It cannot safely be stretched to Base, Governor proposals, preview proposals, unrelated legacy code, or privileged-only behavior.

## Live retrieval result

Immunefi root, information and scope pages all returned HTTP 200; the root redirected to information. The embedded live object yielded 36 assets, 30 impacts, nine reward tiers and ten known issues. The programme was last updated 2026-10-13 and carries a $2,000,042 maximum, mandatory impact PoC and KYC.

The Discourse search and topic JSON endpoints both returned HTTP 200. The official vote page was available to the web renderer/search index but direct curl returned HTTP 403; this is explicitly marked partial, not silently treated as a complete archive. Hashes/statuses are in `mirror/lane-33/retrieval-manifest.json`.

## Governance/deployment cross-check

- U21 topic: `Upgrade 21 - Interop Readiness`, topic 10948, created 2026-11-04 21:19:51 UTC.
- Vote: proposal ID `18704058920168992233750266034048958164367667396985967653465644941701644737084`, displayed SUCCEEDED/optimistically approved, ended 2026-11-11 16:55 (page display time zone not independently exposed by direct retrieval).
- Release: `op-contracts/v9.0.0`, pinned commit `ba6fcadbc57eb99918c5b0f14f57c72527f531e3`.
- Task: `eth/084-U21-op-ink-soneium-uni`; OP Mainnet, Ink, Soneium, Unichain; OPCM 9.0.3 at `0x2d91…331f`.
- Execution: tx `0x024770…a99`, successful at block 26430859, 307 logs.
- Local notice agrees on the release and behavior (`upgrade-21.mdx:23-80`) but is explicitly provisional (`:28-31`) and retains a stale Nov 2 publication target (`:208-220`) versus the actual Nov 4 topic.
- `semver-lock.json` was cross-checked. It contains source/init-code hashes, not semantic versions or deployed addresses, so it cannot replace live pointer reads.

## Block-N implementation result

Read-only state confirms all four chain deployments share Portal 6.1.0 (`0xb20b…9645`), SystemConfig 4.3.0 (`0xade2…377`), ETHLockbox 2.0.0 (`0xdf75…afe`) and ASR 4.0.0 (`0x2b27…2D0`). OP’s resolved L1CrossDomainMessenger implementation is `0x7d4E…448`, version 2.13.0. Full addresses and resolution modes are in `mirror/lane-33/chain-implementation-map.json`.

## Primitives

- **PRIM-3301:** live proxy clause covers the current implementation behind an exact listed proxy.
- **PRIM-3302:** unlisted proxies on OP/Ink/Soneium/Unichain can use Primacy of Impact, but named-chain status is not explicit address listing.
- **PRIM-3303:** official U21 proposal code/calldata has an independent programme route.

## Killed scope assumptions

- **REJ-3301:** current OP ASR is not the listed `0x18DA…443`; current U21 proxy is `0x23B2…113`.
- **REJ-3302:** current U21 DelayedWETH proxy `0x1b6d…3162` is not the listed `0xE497…8d14`.
- **REJ-3303:** sibling-chain proxies are not exact asset rows; they rely on impact/proposal coverage.

No candidate file was created: this lane established eligibility facts, not a permissionless exploit or violated protocol invariant.

## Compositions deserving follow-up

1. **Shared implementation, four-chain impact:** reproduce any permissionless Portal/SystemConfig/ETHLockbox/ASR defect against each real sibling proxy. Shared bytecode plus separate state can turn one root cause into multi-chain eligible impact, but proxy eligibility must be stated precisely.
2. **Current ASR/lockbox scope proof:** any direct theft, permanent freeze, or invalid-withdrawal route in current ASR/ETHLockbox should attach both the U21 proposal route and Primacy-of-Impact proof because those exact OP addresses are not listed.
3. **Pre-positioning before documented migration:** a permissionless action available now that becomes harmful when the planned interop migration runs is scope-plausible; prove today’s reachability and the documented governance dependency without calling privileged execution itself an exploit.

## Files

- `mirror/lane-33/SCOPE_SNAPSHOT.md`
- `mirror/lane-33/retrieval-manifest.json`
- `mirror/lane-33/chain-implementation-map.json`
- `primitives/PRIM-3301.md` through `PRIM-3303.md`
- `rejected/REJ-3301.md` through `REJ-3303.md`
- `lanes/LANE-33-report.md`

