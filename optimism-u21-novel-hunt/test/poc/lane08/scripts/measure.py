#!/usr/bin/env python3
"""Lane 08: real-transaction gas measurements on a PRIVATE anvil (port 18080) forked from the shared `l1`
(or `l1pre`) anvil. Never touches a public network. Usage: measure.py <rpc> <v9|v8> <out.json>"""
import json, sys, urllib.request, subprocess

RPC, VER, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
PORTAL = '0xbeb5fc579115071764c7423a4f12edde41f106ed'
DGF = '0xe5965ab5962edc7477c8520243a95517cd252fa9'
L1CDM = '0x25ace71c97b33cc4729cf772ae268934f7ab5fa1'
ACCT = '0x0808080808080808080808080808080808080808'
SINK, BURNER, REVERTER = ['0x515100000000000000000000000000000000000%d' % i for i in (1, 2, 3)]
PC_CHECK, PC_SUB = (7312, 5594) if VER == 'v9' else (7473, 5854)
RESERVE = 190000 if VER == 'v9' else 85000
_id = 0

def rpc(m, p=[]):
    global _id
    _id += 1
    req = urllib.request.Request(RPC, data=json.dumps({'jsonrpc': '2.0', 'id': _id, 'method': m, 'params': p}).encode(),
                                 headers={'Content-Type': 'application/json'})
    r = json.load(urllib.request.urlopen(req, timeout=600))
    return r

def ok(m, p=[]):
    import time
    for k in range(40):
        r = rpc(m, p)
        if 'error' in r:
            if '429' in str(r['error']) or 'Max retries' in str(r['error']) or 'Fork Error' in str(r['error']):
                time.sleep(3)
                continue
            raise Exception('%s -> %s' % (m, r['error']))
        return r['result']
    raise Exception('%s -> persistent upstream error' % m)

def sel(sig):
    return subprocess.check_output(['cast', 'sig', sig]).decode().strip()

def call(to, data):
    return ok('eth_call', [{'to': to, 'data': data}, 'latest'])

def send(to, data, gas, value=0):
    nonce = ok('eth_getTransactionCount', [ACCT, 'latest'])
    r = rpc('eth_sendTransaction', [{'from': ACCT, 'to': to, 'data': data, 'gas': hex(gas), 'value': hex(value), 'nonce': nonce,
                                    'maxFeePerGas': hex(10**11), 'maxPriorityFeePerGas': hex(10**9)}])
    if 'error' in r:
        return None, r['error']
    h = r['result']
    import time
    for _ in range(300):
        ok('evm_mine')
        b = ok('eth_getBlockByNumber', ['latest', False])
        if h in b['transactions']:
            return ok('eth_getTransactionReceipt', [h]), None
        time.sleep(0.5)
    raise Exception('tx not mined ' + h)

def setup(cases):
    ok('anvil_setCode', [SINK, '0x00'])
    ok('anvil_setCode', [BURNER, '0xfe'])
    ok('anvil_setCode', [REVERTER, '0x5f5ffd'])
    ok('anvil_impersonateAccount', [ACCT])
    ok('anvil_setBalance', [ACCT, hex(10**24)])
    base = int(call(DGF, sel('gameCount()')), 16)
    assert base == 21389 or VER == 'v8', base
    games = []
    for i, c in enumerate(cases):
        rc, e = send(DGF, c['create'], 3_000_000, 8 * 10**16)
        assert rc and rc['status'] == '0x1', (i, 'create', rc, e)
    ok('evm_increaseTime', [5]); ok('evm_mine')
    for i, c in enumerate(cases):
        rc, e = send(PORTAL, c['prove'], 30_000_000)
        assert rc and rc['status'] == '0x1', (i, 'prove', rc, e)
    ok('evm_increaseTime', [302400 + 5]); ok('evm_mine')
    for i, c in enumerate(cases):
        g = '0x' + call(DGF, sel('gameAtIndex(uint256)') + '%064x' % (c['gameIndex']))[2:][-40:]
        rc, e = send(g, sel('resolveClaim(uint256,uint256)') + '%064x%064x' % (0, 0), 3_000_000)
        assert rc and rc['status'] == '0x1', (i, 'resolveClaim', rc, e)
        rc, e = send(g, sel('resolve()'), 3_000_000)
        assert rc and rc['status'] == '0x1', (i, 'resolve', rc, e)
    ok('evm_increaseTime', [604800 + 5]); ok('evm_mine')

SEL_FIN = None; SEL_OK = None; SEL_FAIL = None
ERR_CDM = None

def attempt(c, gas, trace=False):
    """Sends the real finalize tx with tx gas limit `gas`, classifies, reverts the chain to the snapshot."""
    snap = ok('evm_snapshot')
    res = {'gas': gas}
    try:
        # revert data (if any) via eth_call with the identical gas limit
        r = rpc('eth_call', [{'from': ACCT, 'to': PORTAL, 'data': c['finalize'], 'gas': hex(gas)}, 'latest'])
        rc, e = send(PORTAL, c['finalize'], gas)
        if rc is None:
            res['out'] = 'INTRINSIC'; res['err'] = str(e)[:80]
            return res
        res['gasUsed'] = int(rc['gasUsed'], 16)
        if rc['status'] != '0x1':
            data = ''
            if 'error' in r:
                data = (r['error'].get('data') or '')
            if data.startswith(ERR_CDM):
                res['out'] = 'REVERT_L1CDMCallFailed'
            elif data.startswith('0x08c379a0'):
                res['out'] = 'REVERT_SafeCallNotEnoughGas'
            else:
                res['out'] = 'REVERT_OOG_or_other'; res['data'] = data[:20]
        else:
            fin = int(call(PORTAL, SEL_FIN + c['withdrawalHash'][2:]), 16)
            s = int(call(L1CDM, SEL_OK + c['msgHash'][2:]), 16)
            f = int(call(L1CDM, SEL_FAIL + c['msgHash'][2:]), 16)
            assert fin == 1
            psucc = None
            for lg in rc['logs']:
                if lg['topics'][0] == TOPIC_FIN:
                    psucc = int(lg['data'], 16)
            res['portalSuccess'] = psucc
            res['out'] = 'FINALIZED_DELIVERED' if s else ('FINALIZED_FAILEDMSG' if f else ('FINALIZED_NORECORD_portalSuccess=%s' % psucc))
        if trace:
            res['trace'] = analyze(rc['transactionHash'], c)
        return res
    finally:
        ok('evm_revert', [snap])

def analyze(txh, c):
    t = ok('debug_traceTransaction', [txh, {'disableMemory': True, 'disableStorage': True}])
    logs = t['structLogs']
    info = {}
    cdm_depth = None      # depth of the L1CDM proxy frame
    impl_depth = None
    after_target_call = False
    target_call_idx = None
    for i, l in enumerate(logs):
        op, d, pc, gas = l['op'], l['depth'], l['pc'], l['gas']
        if op in ('CALL', 'STATICCALL', 'DELEGATECALL', 'CALLCODE'):
            st = l['stack']
            addr = '0x' + st[-2][2:].rjust(40, '0')[-40:]
            nxt = logs[i + 1] if i + 1 < len(logs) else None
            if op == 'CALL' and addr == L1CDM and cdm_depth is None:
                info['portal_gas_before_CALL'] = gas
                info['portal_CALL_gasCost'] = l.get('gasCost')
                if nxt and nxt['depth'] == d + 1:
                    cdm_depth = d + 1
                    impl_depth = d + 2
                    info['l1cdm_proxy_entry_gas'] = nxt['gas']
            elif cdm_depth is not None and d == impl_depth and op == 'CALL' and info.get('gas_at_sub') is not None and target_call_idx is None:
                target_call_idx = i
                info['target_CALL_gas_before'] = gas
                info['target_CALL_requested'] = int(st[-1], 16)
                if nxt and nxt['depth'] == d + 1:
                    info['target_entry_gas'] = nxt['gas']
                # find next step back at impl depth
                for j in range(i + 1, len(logs)):
                    if logs[j]['depth'] == impl_depth:
                        info['gas_after_target_call'] = logs[j]['gas']
                        break
        if cdm_depth is not None and d == impl_depth:
            if 'l1cdm_impl_entry_gas' not in info:
                info['l1cdm_impl_entry_gas'] = gas
            if op == 'GAS' and pc == PC_CHECK and 'gas_at_hasMinGas' not in info:
                info['gas_at_hasMinGas'] = gas - 2
            if op == 'GAS' and pc == PC_SUB and 'gas_at_sub' not in info:
                info['gas_at_sub'] = gas - 2
            info['impl_last_gas'] = gas
            info['impl_last_op'] = op
    if 'gas_at_hasMinGas' in info:
        m = c['minGasLimit']
        need = -(-(m * 64 + 63 * RESERVE) // 63)
        info['hasMinGas_threshold'] = need
        info['hasMinGas_margin'] = info['gas_at_hasMinGas'] - need
        info['precheck_cost_from_proxy_entry'] = info['l1cdm_proxy_entry_gas'] - info['gas_at_hasMinGas']
        info['portal_forwarded_minus_txGasLimitField'] = info['l1cdm_proxy_entry_gas'] - c['gasLimit']
    if 'gas_after_target_call' in info:
        info['postcall_cost'] = info['gas_after_target_call'] - info['impl_last_gas']
    info['steps'] = len(logs)
    info['failed'] = t.get('failed')
    return info

RANK = {'INTRINSIC': 0, 'REVERT_OOG_or_other': 0, 'REVERT_SafeCallNotEnoughGas': 0}

def passed(o):
    return RANK.get(o['out'], 1) == 1

def search(c, pred, lo, hi):
    if not pred(attempt(c, hi)):
        return None
    while lo < hi:
        mid = (lo + hi) // 2
        if pred(attempt(c, mid)):
            hi = mid
        else:
            lo = mid + 1
    return lo

def main():
    global SEL_FIN, SEL_OK, SEL_FAIL, ERR_CDM, TOPIC_FIN
    SEL_FIN = sel('finalizedWithdrawals(bytes32)'); SEL_OK = sel('successfulMessages(bytes32)'); SEL_FAIL = sel('failedMessages(bytes32)')
    ERR_CDM = sel('OptimismPortal_L1CDMCallFailed()')
    TOPIC_FIN = subprocess.check_output(['cast', 'keccak', 'WithdrawalFinalized(bytes32,bool)']).decode().strip()
    n = json.load(open('data/cases.json'))['n']
    only = [int(x) for x in sys.argv[4].split(',')] if len(sys.argv) > 4 else list(range(n))
    cases = []
    for i in range(n):
        c = json.load(open('data/case_%d.json' % i)); c['i'] = i; c['gameIndex'] = 21389 + i
        cases.append(c)
    setup(cases)
    results = []
    HI = 59_000_000
    for i in only:
        c = cases[i]
        r = {'i': i, 'label': c['label'], 'wd_gasLimit': c['gasLimit'], 'minGasLimit': c['minGasLimit'], 'dataLen': c['dataLen'], 'value': c['value']}
        g_pass = search(c, passed, 21000, HI)
        r['min_tx_gas_passing_portal_check'] = g_pass
        if g_pass is not None:
            a = attempt(c, g_pass, trace=True)
            r['at_min'] = a
            g_fin = search(c, lambda o: o['out'].startswith('FINALIZED'), g_pass, HI)
            r['min_tx_gas_finalizing'] = g_fin
            if g_fin is not None:
                r['at_min_finalizing'] = attempt(c, g_fin, trace=(g_fin != g_pass))
                g_del = search(c, lambda o: o['out'] == 'FINALIZED_DELIVERED', g_fin, HI)
                r['min_tx_gas_delivering'] = g_del
            r['at_plus_2M'] = attempt(c, g_pass + 2_000_000)
            r['below_min'] = attempt(c, g_pass - 1)
        results.append(r)
        print(json.dumps(r)); sys.stdout.flush()
        json.dump(results, open(OUT, 'w'), indent=1)

main()
