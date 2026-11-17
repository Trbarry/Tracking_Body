# ATK-T4 — proof-program differential (kona v1.7.0 old prestate vs v1.9.0 new prestate vs op-node v9)

Model: Opus 5.5 (user-approved exception). Result: 0 candidates, kills ATTACK-T4-01..11. Pure local computation plus
passive, rate-limited reads through the local proxies (L1 :7545, OP :7546). Nothing is broadcast.

## Build (work dir /home/user/u21-work/T4, CARGO_BUILD_JOBS=1, one build at a time)
```
W=/home/user/u21-work/T4; cd /home/user/ethereum-optimism/optimism
for t in v1.7.0 v1.9.0; do mkdir -p $W/src-$t && git archive kona-client/$t rust/ op-core/nuts | tar -x -C $W/src-$t; done
# rs/v1.x.0/Cargo.toml point at $W/src-v1.x.0/rust; Cargo.lock = that tag's rust/Cargo.lock (checked: 0 versions outside it)
(cd rs/v1.7.0 && CARGO_BUILD_JOBS=1 CARGO_TARGET_DIR=$W/target7 cargo build --release)
(cd rs/v1.9.0 && CARGO_BUILD_JOBS=1 CARGO_TARGET_DIR=$W/target9 cargo build --release)
# op-node side: go.work uses ./go + /home/user/ethereum-optimism/op-v9.0.0. op-core/superchain needs the gitignored
# superchain-configs.zip: built from superchain-registry 08d6a449 (the v9 submodule pin) with
#   SUPERCHAIN_REGISTRY_DIR=$W/scr SUPERCHAIN_CONFIGS_OUT=$W/superchain-configs.zip bash op-core/superchain/sync-superchain.sh
# (PATH shim yq->tomlq); sha256 a94b0232… equals the committed .sha256, then copied into op-v9.0.0/op-core/superchain/.
# go/derivecopy = verbatim copy of op-v9.0.0/op-node/rollup/derive/*.go (non-test) + zz_t4_export.go (span codec wrappers).
cp /home/user/ethereum-optimism/op-v9.0.0/op-node/rollup/derive/*.go go/derivecopy/ && rm go/derivecopy/*_test.go
(cd go && GOWORK=$PWD/../go.work GOFLAGS=-p=1 go build -o $W/t4go ./cmd/t4go)
```
## Run
```
S=scripts
# real data (cached under real/cache): 1,023 OP blocks = old game 21377 window end, its start, 23 heaviest-deposit epochs
python3 -I $S/fetch_real.py real range:159634384:159634983 range:159331824:159332223 heavy:26380000:26430700:25
for t in 7 9; do $W/target$t/release/t4-diff < real/real-cases.jsonl > real/o$t.jsonl; done; $W/t4go < real/real-cases.jsonl > real/og.jsonl
python3 -I $S/compare.py real/real-cases.jsonl real/o7.jsonl real/o9.jsonl real/og.jsonl      # 1023 match-canonical, 0 divergences
python3 -I $S/fetch_rcpt.py real real/real-cases.jsonl 10 0x675e…0d10,0x2f55…86fd,0x5d62…69ed,0x42d0…cb   # receipts roots + game claims
python3 -I $S/build_sysfrom.py real real/real-cases.jsonl real/sysfrom-cases.jsonl              # FPVM to_system_config cases
python3 -I $S/build_span.py real real/real-cases.jsonl real/span-cases.jsonl && $S/run_span.sh real/span-cases.jsonl real/spanreal
# synthetic, deterministic seeds 1..3
python3 -I $S/gen_synth.py real/real-cases.jsonl synth/s1.jsonl 1   # then the three binaries, compare.py and classify.py
python3 -I $S/gen_span.py synth/spansyn.jsonl 1 && $S/run_span.sh synth/spansyn.jsonl synth/spansyn
```
Case kinds (same JSONL to all three binaries): `dep` (decode_deposit / UnmarshalDepositLogEvent), `attr`
(StatefulAttributesBuilder / FetchingAttributesBuilder), `sysfrom` (to_system_config / PayloadToSystemConfig),
`rroot` (OpReceiptEnvelope + kona-mpt / DeriveSha), `oroot`, `sroot`, `donly`, `span`/`span2`, `cfg`.
Outputs and summaries: `evidence/attack-wave/T4/`.
