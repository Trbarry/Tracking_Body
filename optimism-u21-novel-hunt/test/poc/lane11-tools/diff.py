import sys,glob,os
E="/home/user/u21-work/lane-11/evidence"
def load(p):
    d={}
    for l in open(p):
        l=l.rstrip("\n")
        if " := " in l:
            k,v=l.split(" := ",1); d[k]=v
    return d
for f in sorted(glob.glob(E+"/diff-l1-*.txt")):
    name=os.path.basename(f)[len("diff-l1-"):]
    g=E+"/diff-l1pre-"+name
    if not os.path.exists(g): print("## %s: no l1pre file"%name); continue
    a,b=load(g),load(f)
    keys=sorted(set(a)|set(b))
    diffs=[(k,a.get(k,"<absent>"),b.get(k,"<absent>")) for k in keys if a.get(k)!=b.get(k)]
    print("## %s: %d keys, %d differ"%(name,len(keys),len(diffs)))
    for k,x,y in diffs: print("  %s\n      v8(l1pre): %s\n      v9(l1)   : %s"%(k,x[:150],y[:150]))
