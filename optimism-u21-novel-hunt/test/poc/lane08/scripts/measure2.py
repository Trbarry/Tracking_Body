#!/usr/bin/env python3
"""Lane 08: eth_call/debug_traceCall based gas measurements on the PRIVATE anvil (lane port), state prepared by
measure.py's setup() (fabricated games created, withdrawals proven through the real portal, time advanced).
No state is changed by this script. Usage: measure2.py <rpc> <v9|v8> <out.json> [case,case,...] [--setup]"""
import json, sys, subprocess
sys.argv_backup = list(sys.argv)
import importlib.util, os
RPC, VER, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
DATA = os.environ.get('CASEDIR', 'data')
GAME_BASE = int(os.environ.get('GAME_BASE', '21389'))

import urllib.request
PORTAL = '0xbeb5fc579115071764c7423a4f12edde41f106ed'
DGF = '0xe5965ab5962edc7477c8520243a95517cd252fa9'
L1CDM = '0x25ace71c97b33cc4729cf772ae268934f7ab5fa1'
ACCT = '0x0808080808080808080808080808080808080808'
PROBE = '0x5151000000000000000000000000000000000099'
SINK, BURNER, REVERTER = ['0x515100000000000000000000000000000000000%d' % i for i in (1, 2, 3)]
PC_CHECK, PC_SUB = (7312, 5594) if VER == 'v9' else (7473, 5854)
RESERVE = 190000 if VER == 'v9' else 85000
_id = 0

def rpc(m, p=[]):
    global _id
    _id += 1
    req = urllib.request.Request(RPC, data=json.dumps({'jsonrpc': '2.0', 'id': _id, 'method': m, 'params': p}).encode(),
                                 headers={'Content-Type': 'application/json'})
    return json.load(urllib.request.urlopen(req, timeout=900))

def ok(m, p=[]):
    import time
    for k in range(60):
        r = rpc(m, p)
        if 'error' in r:
            if '429' in str(r['error']) or 'Max retries' in str(r['error']) or 'Fork Error' in str(r['error']):
                time.sleep(3); continue
            raise Exception('%s -> %s' % (m, str(r['error'])[:300]))
        return r['result']
    raise Exception('%s -> persistent upstream error' % m)

def sel(sig):
    return subprocess.check_output(['cast', 'sig', sig]).decode().strip()

def call(to, data):
    return ok('eth_call', [{'to': to, 'data': data}, 'latest'])

def send(to, data, gas, value=0):
    import time
    nonce = ok('eth_getTransactionCount', [ACCT, 'latest'])
    h = ok('eth_sendTransaction', [{'from': ACCT, 'to': to, 'data': data, 'gas': hex(gas), 'value': hex(value), 'nonce': nonce,
                                   'maxFeePerGas': hex(10**11), 'maxPriorityFeePerGas': hex(10**9)}])
    for _ in range(600):
        ok('evm_mine')
        b = ok('eth_getBlockByNumber', ['latest', False])
        if h in b['transactions']:
            return ok('eth_getTransactionReceipt', [h])
        time.sleep(0.5)
    raise Exception('tx not mined ' + h)

def setup(cases, subset=None):
    ok('anvil_setCode', [SINK, '0x00'])
    ok('anvil_setCode', [BURNER, '0xfe'])
    ok('anvil_setCode', [REVERTER, '0x5f5ffd'])
    ok('anvil_impersonateAccount', [ACCT])
    ok('anvil_setBalance', [ACCT, hex(10**24)])
    base = int(call(DGF, sel('gameCount()')), 16)
    idxs = subset if subset is not None else list(range(len(cases)))
    assert base == GAME_BASE + idxs[0], base
    for i in idxs:
        c = cases[i]
        rc = send(DGF, c['create'], 3_000_000, 8 * 10**16)
        assert rc['status'] == '0x1', (i, 'create')
    ok('evm_increaseTime', [5]); ok('evm_mine')
    for i in idxs:
        c = cases[i]
        rc = send(PORTAL, c['prove'], 30_000_000)
        assert rc['status'] == '0x1', (i, 'prove')
    ok('evm_increaseTime', [302400 + 5]); ok('evm_mine')
    for i in idxs:
        c = cases[i]
        g = '0x' + call(DGF, sel('gameAtIndex(uint256)') + '%064x' % (GAME_BASE + i))[2:][-40:]
        rc = send(g, sel('resolveClaim(uint256,uint256)') + '%064x%064x' % (0, 0), 3_000_000)
        assert rc['status'] == '0x1', (i, 'resolveClaim')
        rc = send(g, sel('resolve()'), 3_000_000)
        assert rc['status'] == '0x1', (i, 'resolve')
    ok('evm_increaseTime', [604800 + 5]); ok('evm_mine')

def intrinsic(cd_hex):
    b = bytes.fromhex(cd_hex[2:])
    z = b.count(0)
    nz = len(b) - z
    std = 21000 + 4 * z + 16 * nz
    floor = 21000 + 10 * (z + 4 * nz)   # EIP-7623
    return std, floor

def ext_calldata(c):
    # finalizeWithdrawalTransaction(w) -> finalizeWithdrawalTransactionExternalProof(w, ACCT)
    orig = c['finalize'][2:]
    body = orig[8 + 64:]
    return SEL_EXT + '%064x' % 0x40 + ACCT[2:].rjust(64, '0') + body

def probe_data(c, g):
    cd = ext_calldata(c)[2:]
    n = len(cd) // 2
    pad = (64 - (len(cd) % 64)) % 64
    head = PORTAL[2:].rjust(64, '0') + '%064x' % 0xc0 + '%064x' % g + L1CDM[2:].rjust(64, '0') + c['withdrawalHash'][2:] + c['msgHash'][2:]
    return SEL_RUN + head + '%064x' % n + cd + '0' * pad

def attempt(c, g):
    r = ok('eth_call', [{'from': ACCT, 'to': PROBE, 'data': probe_data(c, g), 'gas': hex(59_900_000)}, 'latest'])
    flags = int(r[2:66], 16); s = '0x' + r[66:74]; used = int(r[130:194], 16)
    res = {'g': g, 'used': used}
    if not flags & 1:
        if s == ERR_CDM: res['out'] = 'REVERT_L1CDMCallFailed'
        elif s == '0x08c379a0': res['out'] = 'REVERT_SafeCallNotEnoughGas'
        else: res['out'] = 'REVERT_OOG_or_other'; res['sel'] = s
    else:
        assert flags & 2
        res['out'] = 'FINALIZED_DELIVERED' if flags & 4 else ('FINALIZED_FAILEDMSG' if flags & 8 else 'FINALIZED_NORECORD')
    return res

def analyze(c, g):
    t = ok('debug_traceCall', [{'from': ACCT, 'to': PROBE, 'data': probe_data(c, g), 'gas': hex(59_900_000)}, 'latest',
                               {'disableMemory': True, 'disableStorage': True}])
    logs = t['structLogs']
    info = {}
    idx_call = None; idx_ret = None
    for i, l in enumerate(logs):
        op, d = l['op'], l['depth']
        if op == 'CALL':
            st = l['stack']
            addr = '0x' + st[-2][2:].rjust(40, '0')[-40:]
            nxt = logs[i + 1] if i + 1 < len(logs) else None
            if addr == PORTAL and 'portal_frame_entry_gas' not in info and nxt is not None and nxt['depth'] == d + 1:
                info['portal_frame_entry_gas'] = nxt['gas']
            if addr == L1CDM and idx_call is None:
                idx_call = i
                info['portal_gas_before_CALL'] = l['gas']
                if nxt is not None and nxt['depth'] == d + 1:
                    info['l1cdm_proxy_entry_gas'] = nxt['gas']
                for j in range(i + 1, len(logs)):
                    if logs[j]['depth'] == d:
                        idx_ret = j; info['portal_gas_after_CALL'] = logs[j]['gas']; break
                break
    if idx_call is not None and 'l1cdm_proxy_entry_gas' in info:
        impl_depth = logs[idx_call]['depth'] + 2
        end = idx_ret if idx_ret is not None else len(logs)
        target_seen = False
        for i in range(idx_call + 1, end):
            l = logs[i]; op, d, pc, gas = l['op'], l['depth'], l['pc'], l['gas']
            if d != impl_depth: continue
            if 'l1cdm_impl_entry_gas' not in info: info['l1cdm_impl_entry_gas'] = gas
            if op == 'GAS' and pc == PC_CHECK and 'gas_at_hasMinGas' not in info: info['gas_at_hasMinGas'] = gas - 2
            if op == 'GAS' and pc == PC_SUB and 'gas_at_sub' not in info: info['gas_at_sub'] = gas - 2
            if op == 'CALL' and 'gas_at_sub' in info and not target_seen:
                target_seen = True
                info['target_CALL_gas_before'] = gas
                info['target_CALL_requested'] = int(l['stack'][-1], 16)
                nxt = logs[i + 1]
                if nxt['depth'] == d + 1: info['target_entry_gas'] = nxt['gas']
                for j in range(i + 1, end):
                    if logs[j]['depth'] == impl_depth:
                        info['gas_after_target_call'] = logs[j]['gas']; break
            info['impl_last_gas'] = gas; info['impl_last_op'] = op
    if 'gas_at_hasMinGas' in info:
        m = c['minGasLimit']
        need = -(-(m * 64 + 63 * RESERVE) // 63)
        info['hasMinGas_threshold'] = need
        info['hasMinGas_margin'] = info['gas_at_hasMinGas'] - need
        info['precheck_cost_from_proxy_entry'] = info['l1cdm_proxy_entry_gas'] - info['gas_at_hasMinGas']
        info['proxy_entry_minus_wd_gasLimit'] = info['l1cdm_proxy_entry_gas'] - c['gasLimit']
    if 'gas_after_target_call' in info:
        info['postcall_cost'] = info['gas_after_target_call'] - info['impl_last_gas']
    info['steps'] = len(logs)
    return info

def search(c, pred, lo, hi):
    if not pred(attempt(c, hi)): return None
    while lo < hi:
        mid = (lo + hi) // 2
        if pred(attempt(c, mid)): hi = mid
        else: lo = mid + 1
    return lo

NOPASS = ('REVERT_OOG_or_other', 'REVERT_SafeCallNotEnoughGas')

def main():
    global SEL_EXT, SEL_RUN, ERR_CDM
    SEL_EXT = sel('finalizeWithdrawalTransactionExternalProof((uint256,address,address,uint256,uint256,bytes),address)')
    SEL_RUN = sel('run(address,bytes,uint256,address,bytes32,bytes32)')
    ERR_CDM = sel('OptimismPortal_L1CDMCallFailed()')
    n = json.load(open('data/cases.json'))['n']
    args = [a for a in sys.argv[4:] if not a.startswith('--')]
    only = [int(x) for x in args[0].split(',')] if args else list(range(n))
    cases = []
    for i in range(n):
        c = json.load(open('%s/case_%d.json' % (DATA, i))); c['i'] = i
        cases.append(c)
    if '--setup' in sys.argv:
        setup(cases)
    for a in sys.argv:
        if a.startswith('--setup-only='):
            setup(cases, [int(x) for x in a.split('=')[1].split(',')])
    code = json.load(open('out/Probe08.sol/Probe08.json'))['deployedBytecode']['object']
    ok('anvil_setCode', [PROBE, code])
    results = []
    HI = 45_000_000
    for i in only:
        c = cases[i]
        std, floor = intrinsic(c['finalize'])
        r = {'i': i, 'label': c['label'], 'wd_gasLimit': c['gasLimit'], 'minGasLimit': c['minGasLimit'], 'dataLen': c['dataLen'], 'value': c['value'],
             'intrinsic_std': std, 'intrinsic_floor7623': floor}
        g_pass = search(c, lambda o: o['out'] not in NOPASS, 1, HI)
        r['g_min_pass'] = g_pass
        if g_pass is not None:
            r['direct_tx_gas_min_pass'] = g_pass + std
            a = attempt(c, g_pass); a['trace'] = analyze(c, g_pass)
            r['at_min'] = a
            r['below_min'] = attempt(c, g_pass - 1)
            g_fin = search(c, lambda o: o['out'].startswith('FINALIZED'), g_pass, HI)
            r['g_min_finalize'] = g_fin
            if g_fin is not None:
                b = attempt(c, g_fin)
                if g_fin != g_pass: b['trace'] = analyze(c, g_fin)
                r['at_min_finalize'] = b
                g_del = search(c, lambda o: o['out'] == 'FINALIZED_DELIVERED', g_fin, HI)
                r['g_min_deliver'] = g_del
                if g_del is not None and g_del != g_fin:
                    d = attempt(c, g_del); d['trace'] = analyze(c, g_del); r['at_min_deliver'] = d
            r['at_plus_2M'] = attempt(c, min(g_pass + 2_000_000, HI))
            r['at_HI'] = attempt(c, HI)
        results.append(r)
        print(json.dumps(r)); sys.stdout.flush()
        json.dump(results, open(OUT, 'w'), indent=1)

main()
