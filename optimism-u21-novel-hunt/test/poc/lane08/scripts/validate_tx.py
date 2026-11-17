#!/usr/bin/env python3
"""Cross-check: REAL transactions (finalizeWithdrawalTransaction, msg.sender = proof submitter) on the private anvil
vs the eth_call/probe numbers. usage: validate_tx.py <rpc> <case> <predicted direct tx gas>"""
import json, sys, subprocess, urllib.request, time
RPC = sys.argv[1]; CASE = int(sys.argv[2]); PRED = int(sys.argv[3])
PORTAL = '0xbeb5fc579115071764c7423a4f12edde41f106ed'; L1CDM = '0x25ace71c97b33cc4729cf772ae268934f7ab5fa1'
ACCT = '0x0808080808080808080808080808080808080808'
def rpc(m, p=[]):
    req = urllib.request.Request(RPC, data=json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': m, 'params': p}).encode(), headers={'Content-Type': 'application/json'})
    return json.load(urllib.request.urlopen(req, timeout=900))
def ok(m, p=[]):
    for k in range(60):
        r = rpc(m, p)
        if 'error' in r:
            if 'Fork Error' in str(r['error']) or '429' in str(r['error']): time.sleep(3); continue
            raise Exception(str(r['error'])[:300])
        return r['result']
def sel(s): return subprocess.check_output(['cast', 'sig', s]).decode().strip()
c = json.load(open('data/case_%d.json' % CASE))
def attempt(gas):
    snap = ok('evm_snapshot')
    try:
        nonce = ok('eth_getTransactionCount', [ACCT, 'latest'])
        h = ok('eth_sendTransaction', [{'from': ACCT, 'to': PORTAL, 'data': c['finalize'], 'gas': hex(gas), 'nonce': nonce, 'maxFeePerGas': hex(10**11), 'maxPriorityFeePerGas': hex(10**9)}])
        for _ in range(600):
            ok('evm_mine')
            b = ok('eth_getBlockByNumber', ['latest', False])
            if h in b['transactions']: break
            time.sleep(0.5)
        rc = ok('eth_getTransactionReceipt', [h])
        st = rc['status'] == '0x1'
        s = int(ok('eth_call', [{'to': L1CDM, 'data': sel('successfulMessages(bytes32)') + c['msgHash'][2:]}, 'latest']), 16)
        f = int(ok('eth_call', [{'to': L1CDM, 'data': sel('failedMessages(bytes32)') + c['msgHash'][2:]}, 'latest']), 16)
        return st, int(rc['gasUsed'], 16), s, f
    finally:
        ok('evm_revert', [snap])
lo, hi = PRED - 3000, PRED + 3000
assert attempt(hi)[0] and not attempt(lo)[0]
while lo < hi:
    mid = (lo + hi) // 2
    if attempt(mid)[0]: hi = mid
    else: lo = mid + 1
print(json.dumps({'case': CASE, 'label': c['label'], 'predicted_direct_tx_gas': PRED, 'real_min_tx_gas': lo, 'at_min(status,gasUsed,successful,failed)': attempt(lo), 'below(status,gasUsed,...)': attempt(lo - 1)}))
