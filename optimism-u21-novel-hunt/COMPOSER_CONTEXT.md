# Composition phase — shared brief (orchestrator synthesis after the primitive lanes)

Read `LANE_CONTEXT.md` first (all sections incl. addenda 8-11: safety rules, forks, addresses,
scope facts, RPC proxy). Same hard rules: local forks only, no broadcast, no fabrication,
blind-first (no prior audits / public findings). Then read EVERY file in `primitives/` and skim
`rejected/` (so you do not re-walk killed paths) and the lane reports in `lanes/` that matter to
your compositions. Lanes 01-12 are Mythos lanes, 21-33 are independent Codex mirrors of the same
briefs. Lanes 02, 11 and 22 may still be writing: re-list `primitives/` before you finish.

## State of play (orchestrator's reading — verify, do not trust)

25 lanes, ~110 primitives, ~170 killed ideas, ZERO candidates. Closed by two independent models:
upgrade execution (N-1 -> N replay matches chain on all changed slots), ETH conservation,
`deleteProvenWithdrawal`, finalization/replay uniqueness, feature/pause machine, shared-lockbox
authorization, super-root type confusion, pre-positioning before `migrate` (CREATE2 deployer in
real flows is the Safe because OPCM reaches Utils by DELEGATECALL — `OPContractsManagerUtilsCaller.sol:257`
— so PRIM-2104's direct-call occupation lands on addresses no legitimate flow uses).

## Leads that are still open (strongest first)

L1. OLD-PRESTATE GAMES (PRIM-0102, PRIM-2103). Type-9 games created before U21 keep the old
    immutable prestate `0x031ac6f1…` and stay respected/in flight (OP indices up to ~21377);
    new games use `0x03e5a548…` (kona-client v1.9.0). If the kona delta between the two prestates
    contains a SOUNDNESS fix, every in-flight old-prestate game is still judged by the unfixed
    program. Both kona trees are local (`rust/kona` in the v8 and v9 checkouts, and develop).
    Question: is there a consensus/derivation/interop-validity difference that lets (a) an
    invalid root claim survive a challenge, or (b) an honest root claim be defeated? (a) needs an
    attacker-created game from before U21 that is still in progress — check the scan (below);
    (b) kills honest proofs (delay) and bonds (carved out of Critical/High).
L2. STILL-VALID LEGACY GAMES (PRIM-0101, PRIM-0702, PRIM-0505). ~10k type-0/8 output-root games
    since 2025-07-24 remain claim-valid beside type 9. Full passive scan of indices 9760..21388
    (type, creator, status, rootClaim, l2Seq, blacklisted, retired, claimValid) is being written to
    `evidence/op-mainnet-games-9760-21388.json`. Any DEFENDER_WINS + claimValid + not-blacklisted
    game whose creator is not the usual proposer, or any third-party IN_PROGRESS game, deserves a
    root check. NOTE a real attempt exists: game 21288 (type 9, creator `0x7813CC25…`,
    l2SequenceNumber 2e9, CHALLENGER_WINS) with a 90,000 ETH withdrawal proven against it at L1
    block 26404222 (see `mirror/lane-31/WITHDRAWAL_FIXTURES.md`).
L3. FORCED-FAIL OF MESSENGER WITHDRAWALS (PRIM-0401, 0304, 0803, 1202, 2306): a third party can
    finalize a victim's mature messenger withdrawal from inside a replay of his own failed
    message; the victim's message is recorded failed, its ETH sits in the L1CDM (outside the
    lockbox) until someone replays. Unchanged since v8 and benign alone. Compose with: relay
    targets that read `portal.l2Sender()` or need same-tx finalization; pause semantics; the
    planned shared-lockbox migration; L1StandardBridge / ERC721 / application targets; ordering.
L4. TROJAN SUPER-ROOT GAMES (PRIM-0503, 0701, 0903, 2701, 2702, 0606): L1 accepts non-canonical
    super roots (duplicate/extra/unsorted chain entries, first-match lookup); such a game embeds
    the TRUE chain-10 root, accepts honest proofs, then loses, after which the proof is deletable.
    Cost 0.08 ETH bond per game. Is there an eligible impact (see SCOPE_SNAPSHOT.md impact list)
    — e.g. sustained protocol-wide withdrawal delay for standard tooling — or only tooling grief?
    After the planned OP+Unichain migration (two-chain super roots, shared factory)?
L5. GAS: L1CDM 2.13.0 reserves 150k vs live L2CDM 2.2.1 budget 45k (PRIM-0801/1001/1201/0404):
    margin ~59-114k today, negative for minGasLimit >= ~7.3M (replayable failure). Fusaka tx gas
    cap (EIP-7825, 2^24) x larger v9 reserves x failed-message replay: is there a band of
    messages that can never be delivered again (ETH stuck in L1CDM)? Is it only self-inflicted?
    Also `SafeCall` +183,600 floor for value to codehash==0 targets (removable with 1 wei).
L6. UNEXPLAINED DIFFERENTIAL (PRIM-3105): identical deposits cost calldata-proportional MORE gas
    at block N than N-1 (+26k @4kB, +200k @32kB, +730k @120kB). Root cause unknown. Explain it
    (compiler? memory copy? lockbox path?) and decide whether any deposit that fit in a block /
    under the tx gas cap before no longer does.
L7. PERMISSIONED SUPER GAMES (PRIM-0104, 0705): type 5 authorises by `tx.origin`, needs no bond,
    is DEFENDER_WINS at creation; OP's type-5 proposer is the live type-9 proposer EOA. Anchors are
    cross-type (PRIM-2704). Can ANY contract called in a transaction ORIGINATED by that EOA create
    a type-5 game with an attacker-chosen root — i.e. does the proposer's routine tx ever execute
    attacker-influencable code (DGF.create -> clone init -> DelayedWETH / ASR / bond refunds,
    `claimCredit` to arbitrary recipients, resolve/step paths)? What can a type-5 DEFENDER_WINS
    game do on a chain that respects type 9 (anchor update? proving?) and on Soneium (respects 5)?
L8. MIGRATION RESIDUE (PRIM-0904, 0901, 2903, 3005, 0601/0602): orphaned legacy ASR/DGF/WETH,
    retired lockboxes that still authorize their portal, incomplete `clearedGameTypes()` list,
    four independent pause pointers, calldata frozen at vote time vs permissionless anchor moves.
L9. L2-side solvency before pooling: is each chain's L2 ETH liability <= its lockbox balance
    (OP ~182.5k, Unichain ~18.3k ETH)? L2 archive RPC: `http://127.0.0.1:7546` (OP only).

## Deliverables (per composer X in {A,B,C,D})

- `lanes/COMPOSER-X-report.md`: a numbered table of EVERY composition attempted
  (primitives combined -> hypothesis -> exact killing fact or result). The count matters.
- `rejected/COMP-X-nn.md` for the substantive kills (file:line / cast output / test name).
- `candidates/CAND-X-nn.md` (template + honest score from LANE_CONTEXT §5) ONLY if it survives
  your own falsification with a fork test against deployed bytecode. Score >= 7 to escalate.
- PoC tests under `test/poc/composer-X/`, traces under `evidence/composer-X/`.
- Harness: `cp -r /home/user/u21-work/template /home/user/u21-work/composer-X`.
- Final message <= 450 words: number of compositions attempted, candidates with scores, top 3
  kills with the killing fact, and the single highest-value next experiment.
