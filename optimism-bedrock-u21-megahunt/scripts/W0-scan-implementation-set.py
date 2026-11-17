import json,urllib.request,time,sys
URL='http://127.0.0.1:7545'
T=["0xff513d80e2c7fa487608f70a618dfbc0cf415699dc69588c747e8c71566c88de","0xa47fcdf075d680d3817bfca7973b373e1a5f6cfc3b444748299cc2b83d8348f9"]
ADDR=["0xe5965Ab5962eDc7477C8520243A95517CD252fA9","0x10d7B35078d3baabB96Dd45a9143B94be65b12CD","0x2F12d621a16e2d3285929C9996f478508951dFe4","0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0"]
def q(a,b):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_getLogs","params":[{"address":ADDR,"fromBlock":hex(a),"toBlock":hex(b),"topics":[T]}]}).encode()
    err=None
    for attempt in range(5):
        try:
            r=json.load(urllib.request.urlopen(urllib.request.Request(URL,body,{'Content-Type':'application/json'}),timeout=60))
            if 'result' in r: return r['result']
            err=r.get('error')
        except Exception as e: err=str(e)
        time.sleep(2+attempt*3)
    return ('ERR',err)
start,end,step,out=int(sys.argv[1]),int(sys.argv[2]),int(sys.argv[3]),sys.argv[4]
logs=[];errs=[];a=start
while a<=end:
    b=min(a+step-1,end); r=q(a,b)
    if isinstance(r,tuple): errs.append((a,b,str(r[1])[:120]))
    else: logs+=[{'address':x['address'],'block':int(x['blockNumber'],16),'tx':x['transactionHash'],'topics':x['topics'],'data':x['data']} for x in r]
    a=b+1
json.dump({'range':[start,end],'step':step,'factories':ADDR,'logs':logs,'errors':errs},open(out,'w'),indent=1)
print('done',len(logs),len(errs))
