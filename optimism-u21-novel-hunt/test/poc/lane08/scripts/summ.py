import json,sys
f=sys.argv[1]
for line in open(f):
    line=line.strip()
    if not line.startswith('{'): print(line[:300]); continue
    r=json.loads(line)
    a=r.get('at_min',{}); t=a.get('trace',{})
    print(r['i'],r['label'])
    print('   wd.gasLimit',r['wd_gasLimit'],'| minTxGas passing portal check',r['min_tx_gas_passing_portal_check'],'->',a.get('out'),'gasUsed',a.get('gasUsed'),'| minFinalize',r.get('min_tx_gas_finalizing'),r.get('at_min_finalizing',{}).get('out'),'| minDeliver',r.get('min_tx_gas_delivering'),'| +2M:',r.get('at_plus_2M',{}).get('out'),'| -1:',r.get('below_min',{}).get('out'))
    print('   trace@min:',{k:v for k,v in t.items() if k not in('steps',)})
    t2=r.get('at_min_finalizing',{}).get('trace')
    if t2: print('   trace@minFinalize:',{k:v for k,v in t2.items() if k not in('steps',)})
