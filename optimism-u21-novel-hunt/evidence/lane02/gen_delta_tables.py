#!/usr/bin/env python3
"""Build the attributed N-1 -> N delta tables (per chain / per proxy) from the upgrade-tx prestate diff and the two dumps."""
import json
tx=json.load(open('evidence/lane02/u21-tx-prestate-diff.json'))['result']
pre=json.load(open('PRE_UPGRADE_STATE.json')); post=json.load(open('POST_UPGRADE_STATE.json'))
IMPL="0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
def attribute(name, slot, a, b):
    s=int(slot,16) if slot.startswith('0x') else None
    if slot==IMPL: return "EIP-1967 implementation. Written 4x in the tx (StorageSetter -> impl -> StorageSetter -> impl) by `OPContractsManagerUtils.upgrade` (src/L1/opcm/OPContractsManagerUtils.sol:354,372,379,386); net = new v9 implementation."
    if name=="SystemConfig" and slot=="0x99f45962df4bc30de8d4c3c6d1ffc0f100edce16e80c7a5768b6d55ca463ff42": return "`OPCM_SLOT` (keccak('systemconfig.opcm')-1) = lastUsedOPCM: 8.0.1 OPCM -> OPCMV2 9.0.3. `SystemConfig.initialize` (src/L1/SystemConfig.sol:237) with `addrs.opcm = opcmV2` (OPContractsManagerV2.sol:852)."
    if name=="ETHLockbox" and s==3: return "NEW v9 field `superchainConfig` (slot 3, was unused/zero). `ETHLockbox.initialize` (src/L1/ETHLockbox.sol:105) with `_cts.systemConfig.superchainConfig()` (OPContractsManagerV2.sol:891)."
    if name=="AnchorStateRegistry" and s==6: return "NEW v9 field `ethLockbox` packed into slot 6 bytes 12..31 (zero before). `AnchorStateRegistry.initialize` (src/dispute/AnchorStateRegistry.sol:107). Low 12 bytes (`respectedGameType`, `retirementTimestamp`) rewritten with identical values."
    if name=="DelayedWETH" and s==5: return "NEW v9 field `ethLockbox` (slot 5, was unused/zero). `DelayedWETH.initialize` (src/dispute/DelayedWETH.sol:62)."
    if name=="DisputeGameFactory" and slot=="0x42faa4569684ce9de6c0b2f969e15e6e43a595549e706530ccb0e79bc8aaa794": return "`gameArgs[9]` data word 0 (keccak(keccak(9 . 105))) = absolutePrestate of SUPER_CANNON_KONA: 0x031ac6f1.. -> 0x03e5a548..37c9 (kona-client v1.9.0). `DisputeGameFactory.setImplementation` from `_apply` (OPContractsManagerV2.sol:984)."
    if name=="DisputeGameFactory": return "`gameArgs[5]` (SUPER_PERMISSIONED, 40 bytes = ASR ++ proposer) data words: proposer 0x473300df21D047806A082244b417f96b32f13A33 -> 0xc27BA3e0fc01567a5E57ae0c391aa98cecba5be0 (upgrade INPUT; OP Mainnet only). `setImplementation` (OPContractsManagerV2.sol:984)."
    return "?"
names={}
for ch in pre:
    if ch=='_meta': continue
    for n,c in pre[ch].items(): names[c['proxy'].lower()]=(ch,n)
extra={"0xde1fcfb0851916ca5101820a69b13a4e276bd81f":("op-mainnet-10","AddressManager"),"0x9b7c9bbd6d540a8a4dedd935819fc4408ba71153":("ink-57073","AddressManager"),"0xb24bfeece1b3b7a44559f4cbc21bed312b130b70":("soneium-1868","AddressManager"),"0x8098f676033a377b9defe302e9fe6877cd63d575":("unichain-130","AddressManager"),"0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a":("shared","ProxyAdminOwner Safe")}
out=[]
out.append("| chain | contract (proxy) | slot | value @N-1 | value @N | cause |")
out.append("|---|---|---|---|---|---|")
rows=[]
for a in sorted(set(tx['pre'])|set(tx['post'])):
    ps=tx['pre'].get(a,{}).get('storage',{}); qs=tx['post'].get(a,{}).get('storage',{})
    ch,n=names.get(a,extra.get(a,("-",a)))
    for k in sorted(set(ps)|set(qs)):
        va=ps.get(k,'0x'+'0'*64); vb=qs.get(k,'0x'+'0'*64)
        if n=="AddressManager": cause="`addresses[keccak('OVM_L1CrossDomainMessenger')]`: L1CDM implementation 2.11.1 -> 2.13.0 (ResolvedDelegateProxy path of `ProxyAdmin.upgrade`, src/universal/ProxyAdmin.sol:159-161)."
        elif n=="ProxyAdminOwner Safe": cause="Safe nonce 48 -> 49 (the `execTransaction`)."
        else: cause=attribute(n,k,va,vb)
        ks=k if len(k)<12 else k[:10]+'..'+k[-6:]
        if int(k,16)<1000: ks=str(int(k,16))
        rows.append((ch,n,a,ks,va,vb,cause))
order={"shared":0,"op-mainnet-10":1,"ink-57073":2,"soneium-1868":3,"unichain-130":4,"-":5}
rows.sort(key=lambda r:(order.get(r[0],9),r[1]))
for ch,n,a,ks,va,vb,cause in rows:
    if n=="SuperchainConfig": ch="shared"
    out.append(f"| {ch} | {n} `{a}` | {ks} | `{va}` | `{vb}` | {cause} |")
open('evidence/lane02/delta_tables.md','w').write("\n".join(out)+"\n")
print(len(rows),"changed slots in the upgrade tx")
