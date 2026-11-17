import json,sys
for fk in sys.argv[1:]:
    print("==",fk)
    for r in json.load(open("/home/user/u21-work/lane-11/evidence/gas-boundary-%s.json"%fk)):
        print(r["i"],r["class"][:22],"M" if r["messenger"] else "P",r["gasLimit"],r["dataLen"],"top",r["classAt12M"],"used",r["usedAt12M"],"minNoRev",r["minGasNoRevert"],"minTop",r["minGasTopClass"],r["revertSelBelow"][:10],"nonmono",r["nonMonotone"],r["probes"],r["firstNeither"],r["lastNeither"])
