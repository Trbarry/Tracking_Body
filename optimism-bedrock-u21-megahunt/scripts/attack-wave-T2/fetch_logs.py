"""Chunked, adaptive eth_getLogs through the local read-only proxy. Usage:
fetch_logs.py <l1|l2> <address> <topic0> <from> <to> <step> <out.json>"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpc
net, addr, topic, a, b, step, out = sys.argv[1:8]
url = rpc.L1 if net=="l1" else rpc.L2
a,b,step=int(a),int(b),int(step)
logs=[]; cur=a; calls=0
while cur<=b:
    s=step
    while True:
        e=min(cur+s-1,b)
        try:
            r=rpc.call(url,"eth_getLogs",[{"fromBlock":hex(cur),"toBlock":hex(e),"address":addr,"topics":[topic]}],retries=2); calls+=1; break
        except Exception as ex:
            s=max(s//4,1000); print("shrink",cur,s,str(ex)[:120],flush=True)
    logs.extend(r); print(cur,e,len(r),len(logs),flush=True); cur=e+1
json.dump({"net":net,"address":addr,"topic0":topic,"from":a,"to":b,"calls":calls,"logs":logs},open(out,"w"))
print("done",len(logs),"calls",calls)
