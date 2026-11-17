#!/usr/bin/env python3
"""F4 — print the net storage delta of each traced upgrade tx for the tracked proxies (from evidence/F4/trace/*-diff.json)."""
import json, sys, glob, os
B = '/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/F4/trace/'
names = {'0xbeb5fc579115071764c7423a4f12edde41f106ed': 'Portal', '0x229047fed2591dbec1ef1118d64f7af3db9eb290': 'SystemConfig',
         '0x25ace71c97b33cc4729cf772ae268934f7ab5fa1': 'L1CDM', '0x99c9fc46f92e8a1c0dec1b1747d010903e884be1': 'L1SB',
         '0x5a7749f83b81b301cab5f48eb8516b986daef23d': 'L1ERC721', '0x75505a97bd334e7bd3c476893285569c4136fa0f': 'ERC20Factory',
         '0x95703e0982140d16f8eba6d158fccede42f04a4c': 'SuperchainConfig', '0x8062abc286f5e7d9428a0ccb9abd71e50d93b935': 'ProtocolVersions',
         '0xe5965ab5962edc7477c8520243a95517cd252fa9': 'DGF', '0x18dac71c228d1c32c99489b7323d441e1175e443': 'ASR-old',
         '0x1c68ecfbf9c8b1e6c0677965b3b9ecf9a104305b': 'ASR-u13', '0x23b2c62946350f4246f9f9d027e071f0264fd113': 'ASR',
         '0x322b47ff1fa8d5611f761e3e275c45b71b294d43': 'Lockbox', '0xde1fcfb0851916ca5101820a69b13a4e276bd81f': 'AddressManager',
         '0x543ba4aadbab8f9025686bd03993043599c6fb04': 'ProxyAdmin', '0xdfe97868233d1aa22e815a266982f2cf17685a27': 'L2OO',
         '0x1b6dbf05eaf22d4e70dc993e8a19dd9f3dcb3162': 'DWETH'}
labs = sys.argv[1:] or sorted(os.path.basename(f)[:-10] for f in glob.glob(B + '*-diff.json'))
Z = '0x' + '0' * 64
for lab in labs:
    d = json.load(open(B + lab + '-diff.json'))
    print('=====', lab)
    for a in sorted(set(d['pre']) | set(d['post'])):
        if a.lower() not in names:
            continue
        pre = d['pre'].get(a, {}).get('storage', {}) or {}
        post = d['post'].get(a, {}).get('storage', {}) or {}
        bal = (d['pre'].get(a, {}).get('balance'), d['post'].get(a, {}).get('balance'))
        print('  ', names[a.lower()], '' if bal[1] is None else f'balance {int(bal[0] or "0x0",16)/1e18:.4f} -> {int(bal[1],16)/1e18:.4f}')
        for s in sorted(set(pre) | set(post), key=lambda x: int(x, 16)):
            v0, v1 = pre.get(s, Z), post.get(s, Z)
            if v0 != v1:
                sl = int(s, 16)
                print('       ', (str(sl) if sl < 1000 else s), v0[2:].lstrip('0') or '0', '->', v1[2:].lstrip('0') or '0')
