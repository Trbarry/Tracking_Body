import json,subprocess,sys
R={'pre':'http://127.0.0.1:8546','n':'http://127.0.0.1:8547','post':'http://127.0.0.1:8545'}
def call(rpc,to,sig,*args):
    try:
        o=subprocess.run(['cast','call','--rpc-url',R[rpc],to,sig,*args],capture_output=True,text=True,timeout=60)
        if o.returncode!=0: return 'ERR:'+o.stderr.strip().split('\n')[-1][:80]
        return o.stdout.strip()
    except Exception as e: return 'EXC'
def storage(rpc,to,slot):
    o=subprocess.run(['cast','storage','--rpc-url',R[rpc],to,slot],capture_output=True,text=True,timeout=60)
    return o.stdout.strip()
def code(rpc,to):
    o=subprocess.run(['cast','code','--rpc-url',R[rpc],to],capture_output=True,text=True,timeout=60)
    return o.stdout.strip()
