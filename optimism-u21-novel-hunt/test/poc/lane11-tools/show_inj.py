import json,sys
KIND=["OK","REVERT","BURN","BOMB","REENTER","EMPTY","EOA","DELEG_BURN","DELEG_OK"]; F=["CUR","LEG","V9"]
CL=["REV","RELAYED","FAILEDMSG","NEITHER","PLAIN_OK","PLAIN_FAIL"]
def load(fk,tag=""):
    try: return json.load(open("/home/user/u21-work/lane-11/evidence/injected-gas-%s%s.json"%(fk,tag)))
    except Exception as e: return None
tag=sys.argv[1] if len(sys.argv)>1 else ""
A=load("l1pre",tag); B=load("l1",tag)
for nm,X in (("l1pre",A),("l1",B)):
    if X: print(nm,"violations",X["violations"],X["violationLog"][:300])
rowsA={r["case"]:r for r in (A or {"rows":[]})["rows"]}; rowsB={r["case"]:r for r in (B or {"rows":[]})["rows"]}
print("case kind len minGas val F wdGas | v8: minNoRev minTop top [rev rel fail neither pOk pFail] firstNeither..last firstFailed..last | v9: same | d(minNoRev) d(minTop)")
for c in sorted(set(rowsA)|set(rowsB)):
    a=rowsA.get(c); b=rowsB.get(c); r=a or b
    def fmt(x):
        if not x: return "-"
        p=x["probes"]
        return "%d %d %s [%d %d %d %d %d %d] N%d..%d F%d..%d nm%d %s"%(x["minGasNoRevert"],x["minGasTopClass"],CL[x["classAtMax"]],p["reverted"],p["relayed"],p["failedMsg"],p["neither"],p["plainOk"],p["plainFail"],x["firstNeither"],x["lastNeither"],x["firstFailed"],x["lastFailed"],x["nonMonotone"],x["revertSelBelow"][:10])
    d=""
    if a and b: d="| d %d %d"%(b["minGasNoRevert"]-a["minGasNoRevert"],b["minGasTopClass"]-a["minGasTopClass"])
    print(c,("M" if r["messenger"] else "P"),KIND[r["kind"]],r["len"],r["minGas"],"1eth" if r["value"]!="0" else "0",F[r["formula"]],r["wdGasLimit"],"| v8:",fmt(a),"| v9:",fmt(b),d)
