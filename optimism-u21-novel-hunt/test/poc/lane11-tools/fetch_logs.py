import json, subprocess, sys, time
P="0xbEb5Fc579115071764c7423A4f12eDde41f106Ed"
T=["0x67a6208cfcc0801d50f6cbe764733f4fddf66ac0b04442061a8a8c0cb6b63f62","0x798f9f13695f8f045aa5f80ed8efebb695f3c7fe65da381969f2f28bf3c60b97","0xdb5c7652857aa163daadd670e116628fb42e869d8ac4251ef8971d9e5727df1b","0xc52e609801931c8dcad3132b8a92414d2199941e6e09c85b117df31b6bda682a"]
URLS=["https://rpc.mevblocker.io","https://ethereum-rpc.publicnode.com"]
def q(url,a,b):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_getLogs","params":[{"address":P,"topics":[T],"fromBlock":hex(a),"toBlock":hex(b)}]})
    r=subprocess.run(["curl","-sS","-m","90","-X","POST","-H","content-type: application/json","--data",body,url],capture_output=True,text=True)
    j=json.loads(r.stdout)
    if "result" not in j: raise Exception(str(j)[:200])
    return j["result"]
start,end,step=int(sys.argv[1]),int(sys.argv[2]),int(sys.argv[3])
out=[]; a=start
while a<=end:
    b=min(a+step-1,end); ok=False
    for attempt in range(4):
        for u in URLS:
            try:
                res=q(u,a,b); out+=res; ok=True; break
            except Exception as e:
                err=str(e)
        if ok: break
        time.sleep(2)
    if not ok: print("FAIL",a,b,err,file=sys.stderr)
    a=b+1
json.dump(out,open(sys.argv[4],"w"))
print(len(out))
