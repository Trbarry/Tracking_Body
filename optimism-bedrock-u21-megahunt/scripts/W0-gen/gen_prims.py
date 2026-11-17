import json,re,sys
sys.path.insert(0,'/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/scripts/W0-gen')
import prim_records as p, prim_data as d
OUT='/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/'
src2id={}
for i,r in enumerate(p.RECS,1):
    r['id']=f'A-{i:03d}'
    for s in r['srcs']: src2id[s]=r['id']
byid={r['id']:r for r in p.RECS}
def resolve(txt):
    return re.sub(r'PRIM-(\d{4})',lambda m: f'PRIM-{m.group(1)} ({src2id[m.group(1)]})' if m.group(1) in src2id else m.group(0),txt)
out=[]
for r in p.RECS:
    a=d.ANC[r['anc']]; c=d.CON[r['con']]
    nxt=r['nxt']
    m=re.match(r'see (?:NEXT_EXPERIMENT of the )?record for PRIM-(\d{4})',nxt)
    if m:
        can=byid[src2id[m.group(1)]]
        nxt=f"same experiment as {can['id']}: {can['nxt']}"
    rec={
     'id':r['id'],
     'source_files':[f'optimism-u21-novel-hunt/primitives/PRIM-{s}.md' for s in r['srcs']],
     'title':r['title'],
     'family':r['fam'],
     'EARLIEST_SEMANTIC_ANCESTOR':{'first_release':a[0],'location_at_that_tag':a[1],'current_form_since':a[2],'note':a[3]},
     'CURRENT_U21_CONSUMER':{'contract_function':c[0],'location_v9':c[1]},
     'PERSISTENT_STATE_OR_OBJECT':resolve(r['pers']),
     'HISTORICAL_BRANCHES':d.BR[r['br']],
     'AUDIT_COVERAGE_ALREADY_DONE':'TRACK-B',
     'UNREVIEWED_CROSS-UPGRADE_EDGE':resolve(r['edge']),
     'NEXT_EXPERIMENT':resolve(nxt),
     'priority':r['prio'],
     'pass_a_status':r['status'],
     'same_mechanism_as':sorted({src2id[s] for s in r['same']}-{r['id']}),
    }
    out.append(rec)
meta={'worker':'W0','generated':'2026-11-17','track':'A (blind)',
 'source':'/home/user/Tracking_Body/optimism-u21-novel-hunt/primitives (115 files: 112 primitives + 3 scope routes PRIM-3301..3303, dropped)',
 'records':len(out),'merged_lane_mirror_pairs':sum(1 for r in p.RECS if len(r['srcs'])>1),
 'path_conventions':'location_at_that_tag is relative to packages/contracts-bedrock at hist/<tag> (v1.0.0..v6.0.0) or op-v{7,8,9}.0.0; location_v9 is relative to op-v9.0.0/packages/contracts-bedrock',
 'priority_rule':'P0 = the historical backtrace could change a PASS A closure (C3,C4,C5,C6,C9,C13) or feeds open lead L1/L3; P1 = a lineage with a concrete unexercised create-at-N/consume-at-M pair; P2 = context, or a duplicate mechanism whose canonical record carries the experiment (see same_mechanism_as)',
 'dedupe_rule':'only exact lane-vs-Codex-mirror duplicates are merged into one record (two source_files); the same mechanism found by unrelated lanes is kept as separate records linked by same_mechanism_as',
 'family_vocabulary':['custody','proof-lifecycle','messenger-replay','pause','storage-init','upgrade-engine','identity-binding','dispute-game','bond-credit','gas-budget','migration','tooling']}
json.dump({'meta':meta,'primitives':out},open(OUT+'PRIMITIVES.json','w'),indent=1)
json.dump({'src2id':src2id},open('/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/W0/src2id.json','w'))
print(len(out)); 
for r in out:
    if r['priority']!='P2': print(r['id'],r['priority'],r['family'],'|',','.join(x[-12:-3] for x in r['source_files']),'|',r['title'][:70])
