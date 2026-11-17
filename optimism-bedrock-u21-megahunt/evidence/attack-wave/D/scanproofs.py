import json, sys, urllib.request
from collections import Counter
RPC=sys.argv[1]; PORTAL=sys.argv[2].lower(); DGF=sys.argv[3].lower(); FROM=int(sys.argv[4]); TO=int(sys.argv[5]); OUT=sys.argv[6]
def rpc(m,p):
    r=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"content-type":"application/json"})
    j=json.load(urllib.request.urlopen(r,timeout=120))
    if 'error' in j: raise Exception(j['error'])
    return j['result']
from hashlib import sha3_256
# keccak via eth_call-free: precomputed topics
T_EXT='0x798f9f13695f8f045aa5f80ed8efebb695f3c7fe65da381969f2f28bf3c60b97' # WithdrawalProvenExtension1(bytes32,address)
def call(to,data,blk):
    return rpc("eth_call",[{"to":to,"data":data},hex(blk)])
def u(x): return int(x,16)
logs=[]
step=5000
b=FROM
while b<=TO:
    e=min(TO,b+step-1)
    logs+=rpc("eth_getLogs",[{"address":PORTAL,"fromBlock":hex(b),"toBlock":hex(e),"topics":[T_EXT]}])
    b=e+1
rows=[]
for lg in logs:
    blk=u(lg['blockNumber']); wh=lg['topics'][1]; sub='0x'+lg['topics'][2][26:]
    # provenWithdrawals(bytes32,address) selector 0xbf8e... compute via cast-free table
    pw=call(PORTAL,'0xbb2c727e'+wh[2:]+sub[2:].rjust(64,'0'),blk)
    game='0x'+pw[2+24:2+64]
    gc=u(call(DGF,'0x4d1975b4',blk-1))  # gameCount() at state before block
    # findLatestGames(9, gc-1, 1)
    data='0x254bd683'+hex(9)[2:].rjust(64,'0')+hex(gc-1)[2:].rjust(64,'0')+hex(1)[2:].rjust(64,'0')
    fl=call(DGF,data,blk-1)
    # decode: offset, len, then tuple offset ... take index and metadata(proxy) roughly
    words=[fl[2+i*64:2+(i+1)*64] for i in range((len(fl)-2)//64)]
    # layout: [0]=0x20 [1]=len [2]=offset tuple [3]=index [4]=metadata [5]=timestamp [6]=rootClaim [7]=extraData offset
    newest_idx=u(words[3]); newest_proxy='0x'+words[4][24:]
    tx=rpc("eth_getTransactionByHash",[lg['transactionHash']])
    rows.append(dict(block=blk,tx=lg['transactionHash'],wh=wh,submitter=sub,tx_from=tx['from'],tx_to=tx['to'],game=game,newest_idx=newest_idx,newest_proxy=newest_proxy,picked_newest=(game.lower()==newest_proxy.lower()),direct=(tx['to'] or '').lower()==PORTAL))
json.dump(rows,open(OUT,'w'),indent=1)
c=Counter((r['picked_newest'],r['direct']) for r in rows)
print("proofs",len(rows),"(picked_newest,direct_to_portal) counts",dict(c))
print("distinct submitters",len(set(r['submitter'] for r in rows)),"non-direct tx_to",Counter(r['tx_to'] for r in rows if not r['direct']).most_common(5))
