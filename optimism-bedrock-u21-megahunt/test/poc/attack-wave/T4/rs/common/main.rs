//! ATK-T4 crate-level differential harness. The same source is compiled against kona-client
//! v1.7.0 (old type-9 prestate) and v1.9.0 (new prestate), each with its own Cargo.lock.
//! Reads JSON-lines cases on stdin, writes one JSON result line per case on stdout.
//! Pure computation: no network, no chain access.

use alloy_consensus::{Eip658Value, Header, Receipt};
use alloy_eips::BlockNumHash;
use alloy_primitives::{Address, B256, Bytes, Log, U256, hex, keccak256};
use kona_derive::{
    AttributesBuilder, StatefulAttributesBuilder,
    test_utils::{TestChainProvider, TestSystemConfigL2Fetcher},
};
use kona_genesis::SystemConfig;
use kona_interop::{OutputRootWithChain, SuperRoot};
use kona_protocol::{BlockInfo, L1BlockInfoTx, L2BlockInfo, OutputRoot, decode_deposit};
use kona_registry::{L1_CONFIGS, ROLLUP_CONFIGS};
use serde_json::{Value, json};
use std::{
    future::Future,
    io::{BufRead, Write},
    pin::pin,
    str::FromStr,
    sync::Arc,
    task::{Context, Poll, Waker},
};

fn block_on<F: Future>(f: F) -> F::Output {
    let mut f = pin!(f);
    let mut cx = Context::from_waker(Waker::noop());
    loop {
        if let Poll::Ready(v) = f.as_mut().poll(&mut cx) {
            return v;
        }
    }
}

fn b256(v: &Value) -> B256 {
    B256::from_str(v.as_str().expect("b256 str")).expect("b256")
}
fn addr(v: &Value) -> Address {
    Address::from_str(v.as_str().expect("addr str")).expect("addr")
}
fn bytes(v: &Value) -> Bytes {
    Bytes::from(hex::decode(v.as_str().expect("bytes str")).expect("hex"))
}
fn u64v(v: &Value) -> u64 {
    match v {
        Value::Number(n) => n.as_u64().expect("u64"),
        Value::String(s) => {
            if let Some(h) = s.strip_prefix("0x") {
                u64::from_str_radix(h, 16).expect("u64 hex")
            } else {
                s.parse().expect("u64 dec")
            }
        }
        _ => panic!("u64 {v:?}"),
    }
}
fn u256v(v: &Value) -> U256 {
    U256::from_str(v.as_str().expect("u256 str")).expect("u256")
}
fn opt<T>(v: &Value, f: impl Fn(&Value) -> T) -> Option<T> {
    if v.is_null() { None } else { Some(f(v)) }
}

fn log_of(v: &Value) -> Log {
    let topics = v["topics"].as_array().unwrap().iter().map(b256).collect::<Vec<_>>();
    Log::new_unchecked(addr(&v["address"]), topics, bytes(&v["data"]))
}

fn sys_cfg(v: &Value) -> SystemConfig {
    SystemConfig {
        batcher_address: addr(&v["batcher"]),
        overhead: u256v(&v["overhead"]),
        scalar: u256v(&v["scalar"]),
        gas_limit: u64v(&v["gas_limit"]),
        base_fee_scalar: opt(&v["base_fee_scalar"], u64v),
        blob_base_fee_scalar: opt(&v["blob_base_fee_scalar"], u64v),
        eip1559_denominator: opt(&v["eip1559_denominator"], |x| u64v(x) as u32),
        eip1559_elasticity: opt(&v["eip1559_elasticity"], |x| u64v(x) as u32),
        operator_fee_scalar: opt(&v["operator_fee_scalar"], |x| u64v(x) as u32),
        operator_fee_constant: opt(&v["operator_fee_constant"], u64v),
        min_base_fee: opt(&v["min_base_fee"], u64v),
        da_footprint_gas_scalar: opt(&v["da_footprint_gas_scalar"], |x| u64v(x) as u16),
    }
}

fn hexs(b: &[u8]) -> String {
    format!("0x{}", hex::encode(b))
}

fn run(c: &Value) -> Value {
    let id = c["id"].clone();
    match c["k"].as_str().unwrap() {
        // Single deposit log -> deposit tx (EIP-2718 bytes) via kona_protocol::decode_deposit.
        "dep" => {
            let log = log_of(c);
            match decode_deposit(b256(&c["bh"]), u64v(&c["idx"]) as usize, &log) {
                Ok(b) => json!({"id": id, "ok": hexs(&b), "hash": format!("{}", keccak256(&b))}),
                Err(e) => json!({"id": id, "err": format!("{e:?}")}),
            }
        }
        // Full payload attributes via kona_derive::StatefulAttributesBuilder (deposits, L1 info,
        // upgrade txs, gas limit, eip1559 params, min base fee, beacon root, randao).
        "attr" => {
            let chain = u64v(&c["chain"]);
            let mut rcfg = ROLLUP_CONFIGS.get(&chain).expect("rollup cfg").clone();
            if let Some(o) = c.get("override_hardforks") {
                // Synthetic fork-boundary cases: shift named fork times.
                for (k, v) in o.as_object().unwrap() {
                    let t = opt(v, u64v);
                    match k.as_str() {
                        "ecotone" => rcfg.hardforks.ecotone_time = t,
                        "fjord" => rcfg.hardforks.fjord_time = t,
                        "granite" => rcfg.hardforks.granite_time = t,
                        "holocene" => rcfg.hardforks.holocene_time = t,
                        "isthmus" => rcfg.hardforks.isthmus_time = t,
                        "jovian" => rcfg.hardforks.jovian_time = t,
                        "karst" => rcfg.hardforks.karst_time = t,
                        _ => panic!("fork {k}"),
                    }
                }
            }
            let rcfg = Arc::new(rcfg);
            let l1 = Arc::new(L1_CONFIGS.get(&rcfg.l1_chain_id).expect("l1 cfg").clone());
            let header: Header = serde_json::from_value(c["l1_header"].clone()).expect("header");
            let l1_hash = header.hash_slow();
            let p = &c["parent"];
            let parent = L2BlockInfo {
                block_info: BlockInfo {
                    hash: b256(&p["hash"]),
                    number: u64v(&p["number"]),
                    parent_hash: B256::ZERO,
                    timestamp: u64v(&p["timestamp"]),
                },
                l1_origin: BlockNumHash { hash: b256(&p["l1_hash"]), number: u64v(&p["l1_number"]) },
                seq_num: u64v(&p["seq"]),
            };
            let epoch = BlockNumHash { hash: l1_hash, number: header.number };
            let mut l1p = TestChainProvider::default();
            l1p.insert_header(l1_hash, header.clone());
            let receipts = c["receipts"]
                .as_array()
                .map(|rs| {
                    rs.iter()
                        .map(|r| Receipt {
                            status: Eip658Value::Eip658(u64v(&r["status"]) == 1),
                            cumulative_gas_used: u64v(&r["cgu"]),
                            logs: r["logs"].as_array().unwrap().iter().map(log_of).collect(),
                        })
                        .collect::<Vec<_>>()
                })
                .unwrap_or_default();
            l1p.insert_receipts(l1_hash, receipts);
            let mut l2p = TestSystemConfigL2Fetcher::default();
            l2p.insert(parent.block_info.hash, sys_cfg(&c["sys"]));
            let mut b = StatefulAttributesBuilder::new(rcfg, l1, l2p, l1p, None);
            match block_on(b.prepare_payload_attributes(parent, epoch)) {
                Ok(a) => json!({
                    "id": id,
                    "tx_hashes": a.transactions.as_ref().map(|t| t.iter().map(|x| format!("{}", keccak256(x))).collect::<Vec<_>>()),
                    "l1_hash": format!("{l1_hash}"),
                    "timestamp": a.payload_attributes.timestamp,
                    "prev_randao": format!("{}", a.payload_attributes.prev_randao),
                    "fee_recipient": format!("{}", a.payload_attributes.suggested_fee_recipient),
                    "beacon_root": a.payload_attributes.parent_beacon_block_root.map(|x| format!("{x}")),
                    "withdrawals": a.payload_attributes.withdrawals.as_ref().map(|w| w.len()),
                    "txs": a.transactions.unwrap_or_default().iter().map(|t| hexs(t)).collect::<Vec<_>>(),
                    "no_tx_pool": a.no_tx_pool,
                    "gas_limit": a.gas_limit,
                    "eip1559": a.eip_1559_params.map(|x| format!("{x}")),
                    "min_base_fee": a.min_base_fee,
                }),
                Err(e) => json!({"id": id, "l1_hash": format!("{l1_hash}"), "err": format!("{e:?}")}),
            }
        }
        // L1 info calldata decode + re-encode round trip.
        "l1dec" => {
            let cd = bytes(&c["calldata"]);
            match L1BlockInfoTx::decode_calldata(&cd) {
                Ok(i) => json!({"id": id, "reenc": hexs(&i.encode_calldata()), "fields": format!("{i:?}")}),
                Err(e) => json!({"id": id, "err": format!("{e:?}")}),
            }
        }
        "oroot" => {
            let o = OutputRoot::from_parts(b256(&c["state"]), b256(&c["storage"]), b256(&c["block"]));
            json!({"id": id, "hash": format!("{}", o.hash()), "enc": hexs(&o.encode())})
        }
        "sroot" => {
            let outs = c["outs"]
                .as_array()
                .unwrap()
                .iter()
                .map(|x| OutputRootWithChain::new(u64v(&x[0]), b256(&x[1])))
                .collect();
            let s = SuperRoot::new(u64v(&c["ts"]), outs);
            let mut buf = Vec::new();
            s.encode(&mut buf);
            json!({"id": id, "hash": format!("{}", s.hash()), "enc": hexs(&buf)})
        }
        // Embedded registry config dump (compared across tags and against op-node).
        "cfg" => {
            let chain = u64v(&c["chain"]);
            let r = ROLLUP_CONFIGS.get(&chain).expect("cfg");
            let l1 = L1_CONFIGS.get(&r.l1_chain_id).expect("l1");
            let mut sched = l1
                .blob_schedule
                .iter()
                .map(|(k, v)| format!("{k}:{}/{}/{}", v.target_blob_count, v.max_blob_count, v.update_fraction))
                .collect::<Vec<_>>();
            sched.sort();
            json!({
                "id": id,
                "hardforks": format!("{:?}", r.hardforks),
                "block_time": r.block_time,
                "deposit_contract": format!("{}", r.deposit_contract_address),
                "system_config": format!("{}", r.l1_system_config_address),
                "genesis": format!("{:?}", r.genesis),
                "l1": format!("prague={:?} osaka={:?} bpo1={:?} bpo2={:?} bpo3={:?} bpo4={:?} bpo5={:?} amsterdam={:?}",
                    l1.prague_time, l1.osaka_time, l1.bpo1_time, l1.bpo2_time, l1.bpo3_time, l1.bpo4_time, l1.bpo5_time, l1.amsterdam_time),
                "blob_schedule": sched,
            })
        }
        // Receipts trie root with op-alloy OpReceiptEnvelope + kona-mpt (the executor's encoder).
        "rroot" => {
            let rs = c["receipts"]
                .as_array()
                .unwrap()
                .iter()
                .map(|r| {
                    let logs = r["logs"].as_array().unwrap().iter().map(log_of).collect::<Vec<_>>();
                    let ty = match u64v(&r["type"]) {
                        0 => op_alloy_consensus::OpTxType::Legacy,
                        1 => op_alloy_consensus::OpTxType::Eip2930,
                        2 => op_alloy_consensus::OpTxType::Eip1559,
                        4 => op_alloy_consensus::OpTxType::Eip7702,
                        0x7e => op_alloy_consensus::OpTxType::Deposit,
                        t => panic!("tx type {t}"),
                    };
                    op_alloy_consensus::OpReceiptEnvelope::from_parts(
                        u64v(&r["status"]) == 1,
                        u64v(&r["cgu"]),
                        logs.iter(),
                        ty,
                        opt(&r["deposit_nonce"], u64v),
                        opt(&r["deposit_receipt_version"], u64v),
                    )
                })
                .collect::<Vec<_>>();
            use alloy_eips::eip2718::Encodable2718;
            let root = kona_mpt::ordered_trie_with_encoder(&rs, |r, buf| r.encode_2718(buf)).root();
            json!({"id": id, "root": format!("{root}")})
        }
        // Deposit-only fallback filter (kona_protocol::OpAttributesWithParent::as_deposits_only).
        "donly" => {
            let txs = c["txs"].as_array().unwrap().iter().map(bytes).collect::<Vec<_>>();
            let attrs = op_alloy_rpc_types_engine::OpPayloadAttributes {
                transactions: Some(txs),
                ..Default::default()
            };
            let a = kona_protocol::OpAttributesWithParent::new(attrs, L2BlockInfo::default(), None, false);
            let d = a.as_deposits_only();
            json!({"id": id, "txs": d.attributes().transactions.clone().unwrap_or_default().iter().map(|t| hexs(t)).collect::<Vec<_>>()})
        }
        // Span-batch transaction codec on real user txs (RPC JSON -> EIP-2718 bytes, hash-checked).
        "span" => {
            use alloy_eips::eip2718::Encodable2718;
            let chain_id = u64v(&c["chain_id"]);
            let mut raws = Vec::new();
            let mut hash_ok = true;
            for t in c["rpc_txs"].as_array().unwrap() {
                let env: op_alloy_consensus::OpTxEnvelope =
                    serde_json::from_value(t.clone()).expect("tx json");
                let raw = env.encoded_2718();
                if format!("{}", keccak256(&raw)) != t["hash"].as_str().unwrap().to_lowercase() {
                    hash_ok = false;
                }
                raws.push(Bytes::from(raw));
            }
            let n = raws.len() as u64;
            let mut sb = kona_protocol::SpanBatchTransactions::default();
            if let Err(e) = sb.add_txs(raws.clone(), chain_id) {
                return json!({"id": id, "err": format!("add_txs {e:?}"), "hash_ok": hash_ok});
            }
            let mut enc = Vec::new();
            sb.encode(&mut enc).expect("encode");
            let rt = |bytes_in: &[u8]| -> Result<Vec<String>, String> {
                let mut d = kona_protocol::SpanBatchTransactions { total_block_tx_count: n, ..Default::default() };
                let mut r = bytes_in;
                d.decode(&mut r).map_err(|e| format!("{e:?}"))?;
                Ok(d.full_txs(chain_id).map_err(|e| format!("{e:?}"))?.iter().map(|t| hexs(t)).collect())
            };
            let raw_hex: Vec<String> = raws.iter().map(|t| hexs(t)).collect();
            let kona_rt = rt(&enc);
            let mut out = json!({
                "id": id, "hash_ok": hash_ok, "n": n, "raw": raw_hex, "kona_enc": hexs(&enc),
                "kona_rt_ok": kona_rt.as_ref().map(|v| *v == raw_hex).unwrap_or(false),
            });
            if let Some(g) = c.get("go_enc").and_then(|v| v.as_str()) {
                let gb = hex::decode(g).unwrap();
                let r = rt(&gb);
                out["go_enc_eq_kona_enc"] = json!(gb == enc);
                out["kona_dec_go_ok"] = json!(r.as_ref().map(|v| *v == raw_hex).unwrap_or(false));
            }
            out
        }
        // FPVM system-config reconstruction from the parent L2 block (kona_protocol::to_system_config).
        "sysfrom" => {
            let rcfg = ROLLUP_CONFIGS.get(&u64v(&c["chain"])).expect("cfg");
            let header: Header = serde_json::from_value(c["header"].clone()).expect("l2 header");
            let hash_ok = format!("{}", header.hash_slow()) == c["hash"].as_str().unwrap().to_lowercase();
            let d = &c["tx0"];
            let dep = op_alloy_consensus::TxDeposit {
                source_hash: b256(&d["sourceHash"]),
                from: addr(&d["from"]),
                to: alloy_primitives::TxKind::Call(addr(&d["to"])),
                mint: d["mint"].as_str().map(|m| u128::from_str_radix(m.trim_start_matches("0x"), 16).unwrap()).unwrap_or(0),
                value: u256v(&d["value"]),
                gas_limit: u64v(&d["gas"]),
                is_system_transaction: d["isSystemTx"].as_bool().unwrap_or(false),
                input: bytes(&d["input"]),
            };
            use alloy_eips::eip2718::Encodable2718;
            let sealed = alloy_consensus::Sealable::seal_slow(dep);
            let tx_ok = format!("{}", keccak256(sealed.encoded_2718())) == d["hash"].as_str().unwrap().to_lowercase();
            let block = op_alloy_consensus::OpBlock {
                header,
                body: alloy_consensus::BlockBody {
                    transactions: vec![op_alloy_consensus::OpTxEnvelope::Deposit(sealed)],
                    ommers: vec![],
                    withdrawals: None,
                },
            };
            match kona_protocol::to_system_config(&block, rcfg) {
                Ok(s) => json!({
                    "id": id, "hash_ok": hash_ok, "tx_ok": tx_ok,
                    "batcher": format!("{}", s.batcher_address).to_lowercase(),
                    "overhead": format!("{:#066x}", s.overhead),
                    "scalar": format!("{:#066x}", s.scalar),
                    "gas_limit": s.gas_limit,
                    "eip1559": format!("{:08x}{:08x}", s.eip1559_denominator.unwrap_or(0), s.eip1559_elasticity.unwrap_or(0)),
                    "operator_fee": format!("{}/{}", s.operator_fee_scalar.unwrap_or(0), s.operator_fee_constant.unwrap_or(0)),
                    "min_base_fee": s.min_base_fee.unwrap_or(0),
                    "da_footprint": s.da_footprint_gas_scalar.unwrap_or(0),
                }),
                Err(e) => json!({"id": id, "hash_ok": hash_ok, "tx_ok": tx_ok, "err": format!("{e:?}")}),
            }
        }
        k => json!({"id": id, "err": format!("unknown kind {k}")}),
    }
}

fn main() {
    let stdin = std::io::stdin();
    let mut out = std::io::BufWriter::new(std::io::stdout().lock());
    for line in stdin.lock().lines() {
        let line = line.unwrap();
        if line.trim().is_empty() {
            continue;
        }
        let c: Value = serde_json::from_str(&line).expect("json case");
        let r = std::panic::catch_unwind(|| run(&c))
            .unwrap_or_else(|_| json!({"id": c["id"].clone(), "panic": true}));
        writeln!(out, "{r}").unwrap();
    }
}
