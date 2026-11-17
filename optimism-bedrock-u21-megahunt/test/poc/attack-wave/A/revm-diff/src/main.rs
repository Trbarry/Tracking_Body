//! ATK-A D3 differential: execute the same randomized KARST-spec transaction corpus through
//! op-revm as pinned by kona-client/v1.7.0 (revm 41) and kona-client/v1.9.0 (revm 43).
//! Output: one line per case with every consensus-visible field (status, tx gas used, refund,
//! output, logs, full post-state digest). Diff the two outputs.
use op_revm::{
    revm::{
        context::{BlockEnv, CfgEnv, TxEnv},
        context_interface::result::ExecutionResult,
        database::{CacheDB, EmptyDB},
        primitives::{keccak256, Address, Bytes, TxKind, B256, U256},
        state::{AccountInfo, Bytecode},
        Context, ExecuteCommitEvm,
    },
    DefaultOp, OpBuilder, OpSpecId, OpTransaction, OpHaltReason,
};

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 { self.0 ^= self.0 << 13; self.0 ^= self.0 >> 7; self.0 ^= self.0 << 17; self.0 }
    fn r(&mut self, n: u64) -> u64 { self.next() % n }
    fn pick<T: Copy>(&mut self, v: &[T]) -> T { v[self.r(v.len() as u64) as usize] }
}

fn addr(b: u8) -> Address { Address::with_last_byte(b) }
const SENDER: u8 = 0xA0;
fn pool(rng: &mut Rng) -> Address {
    let p = [0x01u8, 0x02, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0f, 0x11,
             0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xD0, 0xE0, 0xE1, 0xE2, SENDER];
    let b = rng.pick(&p);
    if b == 0x11 && rng.r(2) == 0 { return Address::from_word(B256::from(U256::from(0x100u64))); }
    addr(b)
}
fn push(code: &mut Vec<u8>, v: U256) {
    let bytes = v.to_be_bytes::<32>();
    let first = bytes.iter().position(|b| *b != 0).unwrap_or(31);
    let n = 32 - first;
    code.push(0x5f + n as u8); // PUSHn
    code.extend_from_slice(&bytes[first..]);
}
fn pushu(code: &mut Vec<u8>, v: u64) { if v == 0 { code.push(0x5f) } else { push(code, U256::from(v)) } }
fn pusha(code: &mut Vec<u8>, a: Address) { push(code, U256::from_be_slice(a.as_slice())); }

fn init_code(rng: &mut Rng, depth: u32) -> Vec<u8> {
    let mut c = Vec::new();
    match rng.r(6) {
        0 => { // return runtime of n bytes (random program or 0xef prefix)
            let rt = if rng.r(5) == 0 { vec![0xef, 0x00] } else { program(rng, depth + 1, 6) };
            for (i, b) in rt.iter().enumerate() { pushu(&mut c, *b as u64); pushu(&mut c, i as u64); c.push(0x53); }
            pushu(&mut c, rt.len() as u64); pushu(&mut c, 0); c.push(0xf3);
        }
        1 => { pushu(&mut c, 0); pushu(&mut c, 0); c.push(0xfd); }
        2 => { c.push(0xfe); }
        3 => { pushu(&mut c, 7); pushu(&mut c, 1); c.push(0x55); pushu(&mut c, 0); pushu(&mut c, 0); c.push(0xf3); }
        4 => { pusha(&mut c, pool(rng)); c.push(0xff); }
        _ => { c.extend(program(rng, depth + 1, 5)); }
    }
    c
}

fn program(rng: &mut Rng, depth: u32, len: u32) -> Vec<u8> {
    let mut c = Vec::new();
    let n = 1 + rng.r(len as u64);
    for _ in 0..n {
        match rng.r(19) {
            0 | 1 => { pushu(&mut c, rng.pick(&[0, 1, 2, 3])); pushu(&mut c, rng.pick(&[0, 1, 2, 3])); c.push(0x55); } // SSTORE val slot
            2 => { pushu(&mut c, rng.r(4)); c.push(0x54); c.push(0x50); }
            3 => { pushu(&mut c, rng.r(3)); pushu(&mut c, rng.r(3)); c.push(0x5d); pushu(&mut c, rng.r(3)); c.push(0x5c); c.push(0x50); }
            4 | 5 | 6 => { // CALL family
                let op = rng.pick(&[0xf1u8, 0xf1, 0xf4, 0xfa, 0xf2]);
                pushu(&mut c, rng.pick(&[0, 32])); pushu(&mut c, 0); // out size, out off
                pushu(&mut c, rng.pick(&[0, 4, 64, 128, 213])); pushu(&mut c, 0); // in size, in off
                if op == 0xf1 || op == 0xf2 { pushu(&mut c, rng.pick(&[0, 0, 1, 1_000_000])); }
                pusha(&mut c, pool(rng));
                let g = rng.pick(&[0u64, 100, 2300, 3000, 9000, 40000, 200000, u64::MAX]);
                if g == u64::MAX { c.push(0x5a) } else { pushu(&mut c, g) }
                c.push(op); c.push(0x50);
            }
            7 | 8 => { // CREATE / CREATE2 from memory
                let ic = init_code(rng, depth);
                for (i, b) in ic.iter().enumerate() { pushu(&mut c, *b as u64); pushu(&mut c, 0x200 + i as u64); c.push(0x53); }
                if rng.r(2) == 0 {
                    pushu(&mut c, rng.r(3)); // salt
                    pushu(&mut c, ic.len() as u64); pushu(&mut c, 0x200); pushu(&mut c, rng.pick(&[0, 1, u32::MAX as u64])); c.push(0xf5);
                } else {
                    pushu(&mut c, ic.len() as u64); pushu(&mut c, 0x200); pushu(&mut c, rng.pick(&[0, 1, u32::MAX as u64])); c.push(0xf0);
                }
                if rng.r(2) == 0 { c.push(0x3b); } // EXTCODESIZE of created
                c.push(0x50);
            }
            9 => { push(&mut c, U256::from(rng.next())); pushu(&mut c, rng.pick(&[0, 31, 1000, 30000, 2_000_000])); c.push(0x52); }
            10 => { pushu(&mut c, rng.r(2)); pushu(&mut c, rng.pick(&[0, 7, 64])); pushu(&mut c, 0); c.push(0xa1); }
            11 => { pusha(&mut c, pool(rng)); c.push(rng.pick(&[0x31u8, 0x3b, 0x3f])); c.push(0x50); }
            12 => { pushu(&mut c, 33); pushu(&mut c, 0); pushu(&mut c, 0x40); pusha(&mut c, pool(rng)); c.push(0x3c); }
            13 => { pushu(&mut c, 64); pushu(&mut c, 0); pushu(&mut c, 0x80); c.push(0x5e); } // MCOPY
            14 => { c.push(0x47); c.push(0x50); c.push(0x48); c.push(0x50); } // SELFBALANCE BASEFEE
            15 => { for _ in 0..rng.r(6) { push(&mut c, U256::from(rng.next()) << (rng.r(4)*64)); pushu(&mut c, 32*rng.r(8)); c.push(0x52); } }
            16 => { c.push(0x3d); c.push(0x50); pushu(&mut c, 0); pushu(&mut c, 0); pushu(&mut c, 0); c.push(0x3e); } // RETURNDATACOPY 0 bytes
            17 => { pushu(&mut c, rng.pick(&[0, 32, 2000])); pushu(&mut c, 0); c.push(0x20); c.push(0x50); }
            _ => { // terminator
                match rng.r(5) {
                    0 => { pushu(&mut c, rng.pick(&[0, 32])); pushu(&mut c, 0); c.push(0xfd); }
                    1 => { c.push(0xfe); }
                    2 => { pusha(&mut c, pool(rng)); c.push(0xff); }
                    3 => { pushu(&mut c, rng.pick(&[0, 32])); pushu(&mut c, 0); c.push(0xf3); }
                    _ => { c.push(0x00); }
                }
                return c;
            }
        }
    }
    if rng.r(3) == 0 { pushu(&mut c, 32); pushu(&mut c, 0); c.push(0xf3); }
    c
}

fn digest(db: &CacheDB<EmptyDB>) -> B256 {
    let mut v: Vec<(Address, Vec<u8>)> = Vec::new();
    for (a, acc) in db.cache.accounts.iter() {
        let mut s = Vec::new();
        s.extend_from_slice(&acc.info.balance.to_be_bytes::<32>());
        s.extend_from_slice(&acc.info.nonce.to_be_bytes());
        s.extend_from_slice(acc.info.code_hash.as_slice());
        s.push(format!("{:?}", acc.account_state).len() as u8);
        let mut st: Vec<_> = acc.storage.iter().filter(|(_, v)| !v.is_zero()).collect();
        st.sort();
        for (k, v) in st { s.extend_from_slice(&k.to_be_bytes::<32>()); s.extend_from_slice(&v.to_be_bytes::<32>()); }
        let exists = !(acc.info.balance.is_zero() && acc.info.nonce == 0 && acc.info.code_hash == keccak256([]) ) || acc.storage.values().any(|v| !v.is_zero());
        if exists { v.push((*a, s)); }
    }
    v.sort();
    let mut all = Vec::new();
    for (a, s) in v { all.extend_from_slice(a.as_slice()); all.extend(s); }
    keccak256(all)
}

fn main() {
    let cases: u64 = std::env::args().nth(1).map(|s| s.parse().unwrap()).unwrap_or(2000);
    let seed0: u64 = std::env::args().nth(2).map(|s| s.parse().unwrap()).unwrap_or(1);
    for case in 0..cases {
        let mut rng = Rng(0x9E3779B97F4A7C15 ^ (seed0.wrapping_mul(1_000_003) + case + 1));
        let mut db = CacheDB::new(EmptyDB::default());
        db.insert_account_info(addr(SENDER), AccountInfo { balance: U256::from(10u128.pow(24)), nonce: 0, ..Default::default() });
        for b in [0xC0u8, 0xC1, 0xC2, 0xC3, 0xC4] {
            let code = Bytecode::new_raw(Bytes::from(program(&mut rng, 0, 12)));
            let bal = if rng.r(2) == 0 { U256::ZERO } else { U256::from(5u64) };
            db.insert_account_info(addr(b), AccountInfo { balance: bal, nonce: 1, code_hash: code.hash_slow(), code: Some(code), ..Default::default() });
            for s in 0..3u64 { if rng.r(2) == 0 { db.insert_account_storage(addr(b), U256::from(s), U256::from(rng.r(3))).unwrap(); } }
        }
        // EIP-7702 delegated EOA -> C1
        let mut dc = vec![0xef, 0x01, 0x00]; dc.extend_from_slice(addr(0xC1).as_slice());
        let dcode = Bytecode::new_raw(Bytes::from(dc));
        db.insert_account_info(addr(0xD0), AccountInfo { balance: U256::from(rng.r(2)), nonce: 1, code_hash: dcode.hash_slow(), code: Some(dcode), ..Default::default() });
        if rng.r(2) == 0 { db.insert_account_info(addr(0xE1), AccountInfo { balance: U256::from(1u64), ..Default::default() }); }

        let mut cfg = CfgEnv::new_with_spec(OpSpecId::KARST);
        cfg.chain_id = 10;
        let block = BlockEnv { number: U256::from(100u64), timestamp: U256::from(1_790_000_000u64), gas_limit: 60_000_000, basefee: rng.pick(&[0u64, 7, 1_000_000]), ..Default::default() };
        let mut evm = Context::op().with_db(db).with_cfg(cfg).with_block(block).build_op();
        let mut line = format!("{case}");
        let mut nonce = 0u64;
        for _t in 0..(1 + rng.r(3)) {
            let deposit = rng.r(3) == 0;
            let to = if rng.r(6) == 0 { TxKind::Create } else { TxKind::Call(pool(&mut rng)) };
            let data = if to == TxKind::Create { Bytes::from(init_code(&mut rng, 0)) } else { Bytes::from(vec![0u8; rng.pick(&[0usize, 4, 100])]) };
            let gl = rng.pick(&[21_000u64, 21_100, 23_000, 30_000, 53_000, 60_000, 100_000, 300_000, 1_000_000, 16_777_216, 20_000_000]);
            let value = U256::from(rng.pick(&[0u64, 0, 1, 1_000]));
            let tx = if deposit {
                let base = TxEnv::builder().caller(addr(rng.pick(&[SENDER, 0xB0]))).gas_limit(gl).kind(to).data(data).value(value);
                OpTransaction::builder().base(base).source_hash(B256::with_last_byte(1 + rng.r(200) as u8)).mint(rng.pick(&[0u128, 0, 5_000])).build_fill()
            } else {
                let base = TxEnv::builder().caller(addr(SENDER)).nonce(nonce).gas_limit(gl).kind(to).data(data.clone()).value(value)
                    .gas_price(2_000_000).gas_priority_fee(Some(rng.pick(&[0u128, 1]))).tx_type(Some(2)).chain_id(Some(10));
                OpTransaction::builder().base(base).enveloped_tx(Some(Bytes::from(vec![0x02u8; 40 + data.len()]))).build_fill()
            };
            // Mirror of alloy-op-evm@kona-client/v1.7.0 `OpEvm::transact_raw` (rust/alloy-op-evm/src/lib.rs:344-370):
            // the production FPVM path lifts the EIP-7825 cap for deposits around the call.
            let mirror = deposit && std::env::var("MIRROR_TRANSACT_RAW").is_ok();
            let saved = if mirror { Some(evm.0.ctx.cfg.tx_gas_limit_cap.replace(u64::MAX)) } else { None };
            let res = evm.transact_commit(tx);
            if let Some(c) = saved { evm.0.ctx.cfg.tx_gas_limit_cap = c; }
            match res {
                Ok(r) => {
                    if !deposit { nonce += 1; }
                    let kind = match &r { ExecutionResult::Success { .. } => "S", ExecutionResult::Revert { .. } => "R", ExecutionResult::Halt { reason, .. } => match reason { OpHaltReason::FailedDeposit => "FD", _ => "H" } };
                    let halt = if let ExecutionResult::Halt { reason, .. } = &r { format!("{reason:?}") } else { String::new() };
                    let logs = keccak256(format!("{:?}", r.logs()).as_bytes());
                    let out = r.output().map(|o| keccak256(o)).unwrap_or_default();
                    line += &format!(" |{kind},{},{},{},{:.8},{:.8},{:?}", r.tx_gas_used(), r.gas().final_refunded(), r.gas().floor_gas(), logs, out, r.created_address());
                    eprintln!("{case} halt={halt}");
                }
                Err(e) => { line += &format!(" |E:{}", format!("{e:?}").chars().take(60).collect::<String>()); }
            }
        }
        line += &format!(" #{:.12}", digest(&evm.0.ctx.journaled_state.database));
        println!("{line}");
    }
}
