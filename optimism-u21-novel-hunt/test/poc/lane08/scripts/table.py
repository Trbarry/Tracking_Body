import json,sys
rs=json.load(open(sys.argv[1]))
print('| # | case | wd.gasLimit | portal-frame gas min (direct-tx gas) | outcome at min | L1CDM entry gas | gas at hasMinGas | threshold | margin | precheck | target entry gas | left after target | post-call cost | min g deliver | outcome at 58M |')
print('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|')
for r in rs:
    a=r.get('at_min',{}); t=a.get('trace',{})
    f=lambda k: str(t.get(k,'-'))
    print('|',r['i'],'|',r['label'],'|',r['wd_gasLimit'],'|',r.get('g_min_pass'),'(%s)'%r.get('direct_tx_gas_min_pass'),'|',a.get('out'),'|',f('l1cdm_proxy_entry_gas'),'|',f('gas_at_hasMinGas'),'|',f('hasMinGas_threshold'),'|',f('hasMinGas_margin'),'|',f('precheck_cost_from_proxy_entry'),'|',f('target_entry_gas'),'|',f('gas_after_target_call'),'|',f('postcall_cost'),'|',r.get('g_min_deliver'),'|',r.get('at_HI',{}).get('out'),'|')
    for k in ('at_min_finalize','at_min_deliver'):
        if r.get(k,{}).get('trace'):
            print('|  | ^ %s g=%s %s: %s |'%(k,r[k]['g'],r[k]['out'],{x:y for x,y in r[k]['trace'].items() if x!='steps'}))
