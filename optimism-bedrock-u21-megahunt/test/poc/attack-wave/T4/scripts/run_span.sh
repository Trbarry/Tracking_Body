#!/bin/bash
# ATK-T4 span-batch three-way pipeline: kona7/kona9 encode+roundtrip -> op-node encode/decode -> kona decodes op-node encoding.
# usage: run_span.sh <span-cases.jsonl> <prefix>
set -e
T=/home/user/u21-work/T4; C=$1; P=$2
$T/target7/release/t4-diff < $C > $P.k7.jsonl
$T/target9/release/t4-diff < $C > $P.k9.jsonl
python3 -I - "$P" <<'PY'
import json,sys
P=sys.argv[1]
a=[json.loads(l) for l in open(P+'.k7.jsonl')]
with open(P+'.span2.jsonl','w') as f:
    for r in a:
        if 'raw' in r:
            f.write(json.dumps({'k':'span2','id':r['id'],'chain_id':10,'raw':r['raw'],'kona_enc':r['kona_enc']})+'\n')
PY
$T/t4go < $P.span2.jsonl > $P.go.jsonl
python3 -I - "$C" "$P" <<'PY'
import json,sys
C,P=sys.argv[1],sys.argv[2]
cs={json.loads(l)['id']:json.loads(l) for l in open(C)}
g=[json.loads(l) for l in open(P+'.go.jsonl')]
with open(P+'.span3.jsonl','w') as f:
    for r in g:
        if 'go_enc' in r:
            c=cs[r['id']]; c['go_enc']=r['go_enc']; f.write(json.dumps(c)+'\n')
PY
$T/target7/release/t4-diff < $P.span3.jsonl > $P.k7b.jsonl
$T/target9/release/t4-diff < $P.span3.jsonl > $P.k9b.jsonl
python3 -I - "$P" <<'PY'
import json,sys
P=sys.argv[1]
L=lambda f:[json.loads(l) for l in open(P+f)]
a,b,g,a2,b2=L('.k7.jsonl'),L('.k9.jsonl'),L('.go.jsonl'),L('.k7b.jsonl'),L('.k9b.jsonl')
ntx=sum(r.get('n',0) for r in a)
print('cases',len(a),'txs',ntx,'kona7==kona9',sum(x==y for x,y in zip(a,b)),'kona-errors',sum(('err' in r) or ('panic' in r) for r in a),
 'kona_rt_ok',sum(r.get('kona_rt_ok',False) for r in a),'| go cases',len(g),'go-errors',sum('err' in r for r in g),'go_enc==kona_enc',sum(r.get('go_enc_eq_kona_enc',False) for r in g),
 'go_rt_ok',sum(r.get('go_rt_ok',False) for r in g),'go_dec_kona_ok',sum(r.get('go_dec_kona_ok',False) for r in g),
 '| kona7 dec go ok',sum(r.get('kona_dec_go_ok',False) for r in a2),'kona9 dec go ok',sum(r.get('kona_dec_go_ok',False) for r in b2))
for r in a:
    if 'err' in r or 'panic' in r: print('KONA-ERR',json.dumps(r)[:300])
for r in g:
    if 'err' in r or not (r.get('go_rt_ok') and r.get('go_dec_kona_ok') and r.get('go_enc_eq_kona_enc')): print('GO-DIFF',json.dumps(r)[:300])
PY
