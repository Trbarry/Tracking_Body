import json,urllib.request,sys
from collections import Counter
RPC='http://127.0.0.1:7545'; DGF='0xe5965Ab5962eDc7477C8520243A95517CD252fA9'
def rpc(m,p):
    r=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"content-type":"application/json"})
    return json.load(urllib.request.urlopen(r,timeout=120))['result']
rows=json.load(open(sys.argv[1]))
for r in rows:
    tx=rpc("eth_getTransactionByHash",[r['tx']]); inp=tx['input']
    r['selector']=inp[:10]
    if inp[:10]=='0x4870496f':
        w=[inp[10+i*64:10+(i+1)*64] for i in range(12)]
        r['game_index']=int(w[1],16)
        # withdrawal tuple starts at offset w[0]
        off=int(w[0],16)//32
        ww=[inp[10+i*64:10+(i+1)*64] for i in range(off,off+6)]
        r['wd_sender']='0x'+ww[1][24:]; r['wd_target']='0x'+ww[2][24:]; r['wd_value']=int(ww[3],16)
        r['lag_games']=r['newest_idx']-r['game_index']
    rw=rpc("eth_getTransactionReceipt",[r['tx']])
    r['gasUsed']=int(rw['gasUsed'],16)
json.dump(rows,open(sys.argv[1],'w'),indent=1)
print(Counter(r.get('lag_games') for r in rows).most_common(12))
b=[r for r in rows if r['submitter']=='0x431f5015b7c05fe792aea2a05158919af1e8ddf5']
print('bot lag',Counter(r.get('lag_games') for r in b).most_common(8),'bot wd senders',Counter(r.get('wd_sender') for r in b).most_common(3),'bot tx_from',Counter(r['tx_from'] for r in b).most_common(2))
print('selectors',Counter(r['selector'] for r in rows))
