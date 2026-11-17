#!/usr/bin/env python3
import re,sys,os,difflib,glob
H='/home/user/ethereum-optimism'
ORDER=['v1.0.0','v1.1.0','v1.2.0','v1.3.0','v1.4.0','v1.5.0','v1.6.0','v1.8.0','v2.0.0','v3.0.0','v4.0.0','v4.1.0','v5.0.0','v6.0.0','v7.0.0','v8.0.0','v9.0.0']
MAINT={'v2.1.0':'v2.0.0','v2.2.0':'v2.0.0','v3.0.1':'v3.0.0'}
def base(v):
    if v in('v7.0.0','v8.0.0','v9.0.0'): return f'{H}/op-{v}/packages/contracts-bedrock'
    return f'{H}/hist/{v}/packages/contracts-bedrock'
def find(v,name):
    b=base(v)
    res=[]
    for d in ('src','contracts'):
        for p in glob.glob(f'{b}/{d}/**/{name}.sol',recursive=True):
            if '/test' in p or '/interfaces/' in p or '/vendor/' in p: continue
            res.append(p)
    return res[0] if res else None
def strip_comments(s):
    # keep line structure
    out=[];i=0;n=len(s);
    while i<n:
        if s.startswith('//',i):
            j=s.find('\n',i); j=n if j<0 else j; i=j
        elif s.startswith('/*',i):
            j=s.find('*/',i); j=n if j<0 else j+2
            out.append('\n'*s.count('\n',i,j)); i=j
        elif s[i] in '"\'':
            q=s[i]; j=i+1
            while j<n and s[j]!=q:
                if s[j]=='\\': j+=1
                j+=1
            out.append(s[i:j+1]); i=j+1
        else:
            out.append(s[i]); i+=1
    return ''.join(out)
def extract(path,fn):
    """return list of (startline, endline, text) for function/modifier/constructor named fn"""
    s=open(path).read()
    sc=strip_comments(s)
    res=[]
    if fn=='constructor': pat=r'\bconstructor\s*\('
    elif fn=='receive': pat=r'\breceive\s*\(\s*\)'
    else: pat=r'\b(?:function|modifier)\s+'+re.escape(fn)+r'\b'
    for m in re.finditer(pat,sc):
        i=m.start()
        # find body start { or ; 
        depth=0;j=i
        while j<len(sc) and sc[j] not in '{;': j+=1
        if j>=len(sc): continue
        if sc[j]==';':
            end=j+1
        else:
            depth=0;k=j
            while k<len(sc):
                if sc[k]=='{': depth+=1
                elif sc[k]=='}':
                    depth-=1
                    if depth==0: break
                k+=1
            end=k+1
        sl=sc.count('\n',0,i)+1; el=sc.count('\n',0,end)+1
        res.append((sl,el,sc[i:end]))
    return res
def norm(t):
    t=re.sub(r'\s+',' ',t)
    t=re.sub(r'\s*([(){};,=+\-*/<>!&|:.\[\]])\s*',r'\1',t)
    t=t.replace(',)',')').replace(',}','}')
    parts=re.split(r'(?<=[;{}])',t)
    return [p.strip() for p in parts if p.strip()]
def trace(name,fn,alt=None,show=True,maxdiff=60):
    """alt: dict version->(name,fn) overrides"""
    prev=None;prevv=None
    for v in ORDER+list(MAINT):
        nm,f=name,fn
        if alt and v in alt: nm,f=alt[v]
        if isinstance(nm,str): nms=[nm]
        else: nms=nm
        p=None
        for x in nms:
            p=find(v,x)
            if p: 
                ex=extract(p,f)
                if ex: break
                p2=p; p=None
        if v in MAINT:
            # compare to parent
            par=MAINT[v]
            pp=None
            for x in nms:
                pp=find(par,x)
                if pp and extract(pp,f): break
            a=norm('\n'.join(e[2] for e in extract(pp,f))) if pp else []
            b=norm('\n'.join(e[2] for e in extract(p,f))) if p else []
            print(f'  [{v} vs {par}] {"SAME" if a==b else "DIFF"}')
            if a!=b and show:
                for l in list(difflib.unified_diff(a,b,lineterm='',n=0))[2:maxdiff]: print('      '+l)
            continue
        if not p:
            print(f'{v}: -- absent'); 
            if prev is not None: prev=[];prevv=v
            continue
        ex=extract(p,f)
        cur=norm('\n'.join(e[2] for e in ex))
        rel=p.split('contracts-bedrock/')[1]
        loc=','.join(f'{a}-{b}' for a,b,_ in ex)
        if prev is None:
            print(f'{v}: FIRST {rel}:{loc}')
            if show:
                for l in cur[:maxdiff]: print('      '+l)
        elif cur==prev:
            print(f'{v}: same {rel}:{loc}')
        else:
            print(f'{v}: CHANGED {rel}:{loc}')
            if show:
                d=list(difflib.unified_diff(prev,cur,lineterm='',n=0))[2:]
                for l in d[:maxdiff]: print('      '+l)
                if len(d)>maxdiff: print(f'      ... ({len(d)-maxdiff} more diff lines)')
        prev=cur;prevv=v
if __name__=='__main__':
    name=sys.argv[1]; fn=sys.argv[2]
    md=int(sys.argv[3]) if len(sys.argv)>3 else 60
    names=name.split(',')
    trace(names,fn,maxdiff=md)
