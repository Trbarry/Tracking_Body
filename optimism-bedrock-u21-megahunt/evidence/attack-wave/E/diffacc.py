import sys,re,collections
def load(f):
    accts=collections.Counter(); reads={}; writes={}
    for l in open(f):
        if l.startswith('A '):
            p=l.split(); accts[p[2].lower()]+=1
        else:
            p=l.split()
            k=(p[1].lower(),p[2])
            if p[0]=='R': reads.setdefault(k,set()).add(p[3])
            else: writes[k]=(p[3],p[5])
    return accts,reads,writes
a1,r1,w1=load(sys.argv[1]); a2,r2,w2=load(sys.argv[2])
print("accounts clean",len(a1),"poisoned",len(a2))
print("accounts only clean",set(a1)-set(a2)); print("accounts only poisoned",set(a2)-set(a1))
print("read slots clean",len(r1),"poisoned",len(r2))
print("read slots only clean",sorted(set(r1)-set(r2))); print("read slots only poisoned",sorted(set(r2)-set(r1)))
dv=[k for k in set(r1)&set(r2) if r1[k]!=r2[k]]
print("read slots with differing values:",len(dv))
for k in sorted(dv): print("  ",k,"clean",sorted(r1[k]),"poisoned",sorted(r2[k]))
print("write slots clean",len(w1),"poisoned",len(w2), "only clean",set(w1)-set(w2),"only poisoned",set(w2)-set(w1))
dw=[k for k in set(w1)&set(w2) if w1[k][1]!=w2[k][1]]
print("writes with differing final value:",len(dw))
for k in sorted(dw): print("  ",k,"clean",w1[k],"poisoned",w2[k])
