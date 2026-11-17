#!/usr/bin/env python3
import json
ROOT="/home/user/ethereum-optimism/op-v%d.0.0/packages/contracts-bedrock/snapshots/storageLayout/%s.json"
pre=json.load(open('PRE_UPGRADE_STATE.json')); post=json.load(open('POST_UPGRADE_STATE.json'))
names=["OptimismPortal2","SystemConfig","ETHLockbox","AnchorStateRegistry","DelayedWETH","DisputeGameFactory","SuperchainConfig","L1CrossDomainMessenger","L1StandardBridge","L1ERC721Bridge","OptimismMintableERC20Factory","ProxyAdmin"]
def field(raw, off, n):
    v=int(raw,16); val=(v>>(8*off))&((1<<(8*n))-1); return "0x"+("%x"%val).rjust(2*n,"0")
out=[]
for name in names:
    lay={v:json.load(open(ROOT%(v,name))) for v in (7,8,9)}
    keys=sorted({(int(e['slot']),int(e['offset'])) for v in lay for e in lay[v]})
    out.append(f"\n### {name}\n")
    out.append("| slot | off | bytes | v7.0.0 | v8.0.0 | v9.0.0 | changed | OP Mainnet raw field @N-1 | @N |")
    out.append("|---|---|---|---|---|---|---|---|---|")
    c0=pre['op-mainnet-10'][name]; c1=post['op-mainnet-10'][name]
    for (s,o) in keys:
        ent={v:next((e for e in lay[v] if int(e['slot'])==s and int(e['offset'])==o),None) for v in (7,8,9)}
        e=ent[9] or ent[8] or ent[7]
        n=int(e['bytes'])
        cells=[(f"`{ent[v]['label']}` {ent[v]['type']}" if ent[v] else "—") for v in (7,8,9)]
        changed="**YES**" if len({(ent[v]['label'],ent[v]['type']) if ent[v] else None for v in (7,8,9)})>1 else ""
        if n<=32:
            r0=c0['slots'].get(str(s),{}).get('raw','0x'+'0'*64); r1=c1['slots'].get(str(s),{}).get('raw','0x'+'0'*64)
            f0=field(r0,o,n); f1=field(r1,o,n)
            if int(f0,16)==0: f0="0"
            if int(f1,16)==0: f1="0"
            f1 = f1 if f1!=f0 else "="
        else:
            f0=f1="(multi-slot)"
        out.append(f"| {s} | {o} | {n} | {cells[0]} | {cells[1]} | {cells[2]} | {changed} | `{f0}` | `{f1}` |")
open('evidence/lane02/layout_tables.md','w').write("\n".join(out)+"\n")
print(len(out),"lines")
