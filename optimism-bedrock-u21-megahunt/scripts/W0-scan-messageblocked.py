import json,urllib.request,time,sys
URL='http://127.0.0.1:7545'
T=["0xf52508d5339edf0d7e5060a416df98db067af561bdc60872d29c0439eaa13a02","0x52c8a2680a9f4cc0ad0bf88f32096eadbebf0646ea611d93a0ce6a29a0240405"]
ADDR="0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1"
def q(a,b):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_getLogs","params":[{"address":ADDR,"fromBlock":hex(a),"toBlock":hex(b),"topics":[T]}]}).encode()
    for attempt in range(4):
        try:
            r=json.load(urllib.request.urlopen(urllib.request.Request(URL,body,{'Content-Type':'application/json'}),timeout=60))
            if 'result' in r: return r['result']
            err=r.get('error')
        except Exception as e: err=str(e)
        time.sleep(2+attempt*3)
    return ('ERR',err)
start,end=int(sys.argv[1]),int(sys.argv[2]); step=int(sys.argv[3])
out=[];errs=[]
a=start
while a<=end:
    b=min(a+step-1,end)
    r=q(a,b)
    if isinstance(r,tuple): errs.append((a,b,str(r[1])[:120]))
    else: out+=r
    a=b+1
json.dump({'range':[start,end],'step':step,'logs':out,'errors':errs},open(sys.argv[4],'w'),indent=1)
print('done logs',len(out),'errors',len(errs))
