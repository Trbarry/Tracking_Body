#!/usr/bin/env python3
"""Compare deployed implementation bytecode (block N and N-1) with the local v9 (and v8 where built) forge artifacts,
masking immutables. Read-only."""
import json, subprocess, sys
ART = "/home/user/ethereum-optimism/op-v9.0.0/packages/contracts-bedrock/forge-artifacts/"
def code(addr, rpc):
    return subprocess.check_output(["cast", "code", addr, "--rpc-url", rpc]).decode().strip()
def call(addr, sig, rpc, *args):
    o = subprocess.run(["cast", "call", addr, sig, *args, "--rpc-url", rpc], capture_output=True, text=True)
    return o.stdout.strip() if o.returncode == 0 else "REVERT"
def cmp(name, addr, rpc):
    a = json.load(open(f"{ART}{name}.sol/{name}.json"))
    exp = a["deployedBytecode"]["object"][2:]
    imm = a["deployedBytecode"].get("immutableReferences", {}) or {}
    on = code(addr, rpc)[2:]
    if len(on) != len(exp):
        return f"LENGTH MISMATCH onchain={len(on)//2} artifact={len(exp)//2}"
    eb = bytearray.fromhex(exp); ob = bytearray.fromhex(on)
    nimm = 0
    for refs in imm.values():
        for r in refs:
            for i in range(r["start"], r["start"] + r["length"]):
                eb[i] = 0; ob[i] = 0
            nimm += 1
    diff = sum(1 for x, y in zip(eb, ob) if x != y)
    return "MATCH (immutable refs masked: %d)" % nimm if diff == 0 else f"DIFF bytes={diff}"
N = "http://127.0.0.1:8547"; PRE = "http://127.0.0.1:8546"
impls = [("OptimismPortal2", "0xb20b23af6071405c37ddda0c0640e8ebb7899645"), ("SystemConfig", "0xade27248542c0f3e89b49e4eb76155e267f14377"),
 ("ETHLockbox", "0xdf75e6b07e98873e36ba5c05508f80c1454e0afe"), ("AnchorStateRegistry", "0x2b27299c577d4720100e2735b652444dcea652d0"),
 ("DisputeGameFactory", "0x72b971717e088b59f26d4236be222adb6acd393b"), ("DelayedWETH", "0xf024e96317907c3b8d8cb346b9fd9034c8640e15"),
 ("SuperchainConfig", "0xa303a644cfbc0c34f6a9dbeafdeba4c967ea01e7"), ("L1CrossDomainMessenger", "0x7d4ec7fb1a1b9e6d61c04d5e21e3d68cff639448"),
 ("L1StandardBridge", "0xb37a11aadf167b2f0b8dd85372de4bc66cd4a891"), ("L1ERC721Bridge", "0x9f164f1d02a81e06d639e55f65a87f0070e3cb2e"),
 ("OptimismMintableERC20Factory", "0xaabea75da509fa518fd8a91eae4be5813b829b12"), ("StorageSetter", "0x2476c911e6d4d9411e677d8faf15a64ac1fdeee8"),
 ("OPContractsManagerV2", "0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f")]
# pre-upgrade impls compared against the v9 artifact as well (expect DIFF where source changed)
pre_impls = [("OptimismPortal2", "0x1005217ad392dc64cef501fa1777a27d42166748"), ("SystemConfig", "0x670b850a235a6fa98cd7a195eb139d0277e471fa"),
 ("ETHLockbox", "0xb3a24db07038b51962026329b62e7a965d56a6ad"), ("AnchorStateRegistry", "0x8f40cc98d694ab986f026c5383a181fcc9b6b281"),
 ("DelayedWETH", "0xe440cc08a71694c8229323803f59024e3144630e"), ("SuperchainConfig", "0x5570b1f2b97b1e35b5c6f9ee76f6cf02c9917504"),
 ("L1CrossDomainMessenger", "0x59D497530b00062f40950ba8EaB88868bf7F86f0")]
print("== post-U21 implementations vs local v9 forge-artifacts (code read at block 26430859)")
for n, a in impls:
    try: print(f"{n:32s} {a} {cmp(n, a, N)}  version={call(a, 'version()(string)', N)}")
    except Exception as e: print(n, a, "ERR", e)
print("== pre-U21 implementations vs local v9 artifacts (sanity: must differ)")
for n, a in pre_impls:
    try: print(f"{n:32s} {a} {cmp(n, a, PRE)}  version={call(a, 'version()(string)', PRE)}")
    except Exception as e: print(n, a, "ERR", e)
# game implementations and VM
dgfs = {"op": "0xe5965Ab5962eDc7477C8520243A95517CD252fA9", "ink": "0x10d7B35078d3baabB96Dd45a9143B94be65b12CD", "soneium": "0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0", "unichain": "0x2F12d621a16e2d3285929C9996f478508951dFe4"}
names = {0: "FaultDisputeGame", 1: "PermissionedDisputeGame", 4: "SuperFaultDisputeGame", 5: "SuperPermissionedDisputeGame", 8: "FaultDisputeGame", 9: "SuperFaultDisputeGame", 10: "ZKDisputeGame"}
print("== game implementations registered at block N vs v9 artifacts; gameArgs pre/post")
seen = {}
for ch, dgf in dgfs.items():
    for gt in range(0, 11):
        impl = call(dgf, "gameImpls(uint32)(address)", N, str(gt)); implp = call(dgf, "gameImpls(uint32)(address)", PRE, str(gt))
        if int(impl, 16) == 0 and int(implp, 16) == 0: continue
        args = call(dgf, "gameArgs(uint32)(bytes)", N, str(gt)); argsp = call(dgf, "gameArgs(uint32)(bytes)", PRE, str(gt))
        bond = call(dgf, "initBonds(uint32)(uint256)", N, str(gt)); bondp = call(dgf, "initBonds(uint32)(uint256)", PRE, str(gt))
        res = seen.get(impl)
        if res is None and int(impl, 16) != 0:
            try: res = cmp(names.get(gt, "FaultDisputeGame"), impl, N)
            except Exception as e: res = "ERR %s" % e
            seen[impl] = res
        print(f"{ch} type {gt}: impl pre={implp} post={impl} [{names.get(gt)}: {res}] bond pre={bondp} post={bond}")
        print(f"     args pre ={argsp}\n     args post={args}")
