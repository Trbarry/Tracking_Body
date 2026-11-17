import json, subprocess, urllib.request, time
RPC="https://ethereum-rpc.publicnode.com"; L1="http://127.0.0.1:8545"; PRE="http://127.0.0.1:8546"
def rpc(url,method,params):
    for a in range(5):
        try:
            req=urllib.request.Request(url,data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),headers={"Content-Type":"application/json","User-Agent":"research-client"})
            out=json.loads(urllib.request.urlopen(req,timeout=60).read())
            if "error" in out: raise Exception(out["error"])
            return out["result"]
        except Exception as e:
            err=e; time.sleep(2)
    raise err
def topic(s): return subprocess.check_output(["cast","sig-event",s]).decode().strip()
T_L=topic("ETHLocked(address,uint256)"); T_U=topic("ETHUnlocked(address,uint256)"); T_LR=topic("LiquidityReceived(address,uint256)"); T_LM=topic("LiquidityMigrated(address,uint256)")
T_DEP=topic("TransactionDeposited(address,address,uint256,bytes)"); T_FIN=topic("WithdrawalFinalized(bytes32,bool)")
chains={"OP":("0x322b47Ff1FA8D5611F761e3E275C45B71b294D43","0xbEb5Fc579115071764c7423A4f12eDde41f106Ed"),"INK":("0xbd4AbB321138e8Eddc399cE64E66451294325a14","0x5d66C1782664115999C47c9fA5cd031f495D3e4F"),"SON":("0x67B4de6FfA66EF201Ea6099A89cA397D56622E31","0x88e529A6ccd302c948689Cd5156C83D4614FAE92"),"UNI":("0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5","0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2")}
A,B=26430859,26433900
res={}
for name,(lb,portal) in chains.items():
    logs=rpc(RPC,"eth_getLogs",[{"fromBlock":hex(A),"toBlock":hex(B),"address":lb}])
    plogs=rpc(RPC,"eth_getLogs",[{"fromBlock":hex(A),"toBlock":hex(B),"address":portal,"topics":[[T_DEP,T_FIN]]}])
    locked=sum(int(l["data"],16) for l in logs if l["topics"][0]==T_L)
    unlocked=sum(int(l["data"],16) for l in logs if l["topics"][0]==T_U)
    other=[l for l in logs if l["topics"][0] in (T_LR,T_LM)]
    nl=sum(1 for l in logs if l["topics"][0]==T_L); nu=sum(1 for l in logs if l["topics"][0]==T_U)
    foreign=[l for l in logs if l["topics"][0] in (T_L,T_U) and int(l["topics"][1],16)!=int(portal,16)]
    # deposits: mint value = first 32 bytes of opaqueData
    mint=0; ndep=0; nfin=0; nfail=0
    for l in plogs:
        if l["topics"][0]==T_DEP:
            d=bytes.fromhex(l["data"][2:]); ln=int.from_bytes(d[32:64],"big"); od=d[64:64+ln]; mint+=int.from_bytes(od[0:32],"big"); ndep+=1
        else:
            nfin+=1; nfail+= (int(l["data"],16)==0)
    b0=int(rpc(PRE,"eth_getBalance",[lb,"latest"]),16); b1=int(rpc(L1,"eth_getBalance",[lb,"latest"]),16)
    res[name]=dict(locked=str(locked),unlocked=str(unlocked),nLocked=nl,nUnlocked=nu,liquidityEvents=len(other),foreignPortalEvents=len(foreign),depositMint=str(mint),nDeposits=ndep,nFinalized=nfin,nFinalizedFailed=nfail,balPre=str(b0),balPost=str(b1),delta=str(b1-b0),lockedMinusUnlocked=str(locked-unlocked),reconciles=(b1-b0==locked-unlocked),mintEqualsLocked=(mint==locked))
    print(name,res[name])
json.dump(res,open("data/reconcile_u21_window.json","w"),indent=1)
