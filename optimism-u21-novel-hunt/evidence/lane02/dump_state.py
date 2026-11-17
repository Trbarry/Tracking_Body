#!/usr/bin/env python3
"""LANE 02 storage dumper. Read-only: eth_getStorageAt / eth_call / eth_getBalance / eth_getCode
against the shared local anvil forks. Usage: dump_state.py pre|n|post OUT.json  (pre=26430858 :8546, n=26430859 :8547, post=26433900 :8545)"""
import json, sys, subprocess, urllib.request
RPC = {"pre": "http://127.0.0.1:8546", "n": "http://127.0.0.1:8547", "post": "http://127.0.0.1:8545"}
TAG = {"pre": "op-v8.0.0", "n": "op-v9.0.0", "post": "op-v9.0.0"}
which, out = sys.argv[1], sys.argv[2]
rpc = RPC[which]
SNAP = f"/home/user/ethereum-optimism/{TAG[which]}/packages/contracts-bedrock/snapshots/storageLayout/"

def batch(calls):
    res = {}
    for i in range(0, len(calls), 150):
        chunk = calls[i:i+150]
        body = json.dumps([{"jsonrpc": "2.0", "id": i+j, "method": m, "params": p} for j, (m, p) in enumerate(chunk)]).encode()
        req = urllib.request.Request(rpc, data=body, headers={"Content-Type": "application/json"})
        for attempt in range(4):
            try:
                r = json.loads(urllib.request.urlopen(req, timeout=180).read()); break
            except Exception as e:
                if attempt == 3: raise
        for x in r:
            res[x["id"]] = x.get("result", {"error": x.get("error")})
    out_ = []
    for i in range(len(calls)):
        v = res[i]
        tries = 0
        while isinstance(v, dict) and tries < 20:
            tries += 1
            import time; time.sleep(min(25, 3 * tries))
            body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": calls[i][0], "params": calls[i][1]}).encode()
            try:
                x = json.loads(urllib.request.urlopen(urllib.request.Request(rpc, data=body, headers={"Content-Type": "application/json"}), timeout=180).read())
                v = x.get("result", {"error": x.get("error")})
            except Exception as e:
                v = {"error": str(e)}
        if isinstance(v, dict): raise RuntimeError("rpc failed for %r: %r" % (calls[i], v))
        out_.append(v)
    return out_

def keccak(hexdata):
    return subprocess.check_output(["cast", "keccak", hexdata]).decode().strip()
def kstr(s):
    return subprocess.check_output(["cast", "keccak", s]).decode().strip()
def pad(x): return x.lower().replace("0x", "").rjust(64, "0")
def mapslot(key_hex, slot): return keccak("0x" + pad(key_hex) + pad(hex(slot)))
def sig(s): return subprocess.check_output(["cast", "sig", s]).decode().strip()
def minus1(h): return hex(int(h, 16) - 1)

IMPL = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
ADMIN = "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"
OZV5 = "0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00"

CHAINS = {
 "op-mainnet-10": dict(SystemConfig="0x229047fed2591dbec1eF1118d64F7aF3dB9EB290", OptimismPortal2="0xbEb5Fc579115071764c7423A4f12eDde41f106Ed",
   ETHLockbox="0x322b47Ff1FA8D5611F761e3E275C45B71b294D43", AnchorStateRegistry="0x23B2C62946350F4246f9f9D027e071f0264FD113",
   DisputeGameFactory="0xe5965Ab5962eDc7477C8520243A95517CD252fA9", DelayedWETH="0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162",
   L1CrossDomainMessenger="0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1", L1StandardBridge="0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1",
   L1ERC721Bridge="0x5a7749f83b81B301cAb5f48EB8516B986DAef23D", OptimismMintableERC20Factory="0x75505a97BD334E7BD3C476893285569C4136Fa0F",
   ProxyAdmin="0x543bA4AADBAb8f9025686Bd03993043599c6fB04", SuperchainConfig="0x95703e0982140D16f8ebA6d158FccEde42f04a4C"),
 "ink-57073": dict(SystemConfig="0x62c0a111929fa32cec2f76adba54c16afb6e8364", OptimismPortal2="0x5d66C1782664115999C47c9fA5cd031f495D3e4F",
   ETHLockbox="0xbd4AbB321138e8Eddc399cE64E66451294325a14", AnchorStateRegistry="0xEe018bAf058227872540AC60eFbd38b023d9dAe2",
   DisputeGameFactory="0x10d7B35078d3baabB96Dd45a9143B94be65b12CD", DelayedWETH="0x57b4C29DAee99a28E6E86778b499361294c134eA",
   L1CrossDomainMessenger="0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f", L1StandardBridge="0x88FF1e5b602916615391F55854588EFcBB7663f0",
   L1ERC721Bridge="0x661235a238B11191211fa95D4Dd9E423d521E0Be", OptimismMintableERC20Factory="0xA8B389A82e088b164cD03230e900980CcED34d29",
   ProxyAdmin="0xd56045E68956FCe2576E680c95a4750cf8241f79"),
 "soneium-1868": dict(SystemConfig="0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3", OptimismPortal2="0x88e529A6ccd302c948689Cd5156C83D4614FAE92",
   ETHLockbox="0x67B4de6FfA66EF201Ea6099A89cA397D56622E31", AnchorStateRegistry="0x4890928941e62e273dA359374b105F803329F473",
   DisputeGameFactory="0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0", DelayedWETH="0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47",
   L1CrossDomainMessenger="0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f", L1StandardBridge="0xeb9bf100225c214Efc3E7C651ebbaDcF85177607",
   L1ERC721Bridge="0x5933e323bE8896DfaCd1cD671442F27dAA10a053", OptimismMintableERC20Factory="0xc1047e30EFC9E172cFe7aa0219895B6a43fC415F",
   ProxyAdmin="0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a"),
 "unichain-130": dict(SystemConfig="0xc407398d063f942febbcc6f80a156b47f3f1bda6", OptimismPortal2="0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2",
   ETHLockbox="0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5", AnchorStateRegistry="0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9",
   DisputeGameFactory="0x2F12d621a16e2d3285929C9996f478508951dFe4", DelayedWETH="0x74ad145aC900F1DD5551F0C9E143314DC4022FCf",
   L1CrossDomainMessenger="0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6", L1StandardBridge="0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA",
   L1ERC721Bridge="0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf", OptimismMintableERC20Factory="0xA2B597EaeAcb6F627e088cbEaD319e934ED5edad",
   ProxyAdmin="0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4"),
}
NSLOTS = dict(SystemConfig=112, OptimismPortal2=72, ETHLockbox=70, AnchorStateRegistry=70, DisputeGameFactory=108, DelayedWETH=70,
              L1CrossDomainMessenger=258, L1StandardBridge=70, L1ERC721Bridge=70, OptimismMintableERC20Factory=70, ProxyAdmin=70, SuperchainConfig=70)
INITLOC = {"L1CrossDomainMessenger": (0, 20), "ProxyAdmin": None}
G = lambda *a: list(a)
GETTERS = dict(
 SystemConfig=G("version()(string)","owner()(address)","initVersion()(uint8)","proxyAdmin()(address)","proxyAdminOwner()(address)","overhead()(uint256)","scalar()(uint256)","batcherHash()(bytes32)","gasLimit()(uint64)","basefeeScalar()(uint32)","blobbasefeeScalar()(uint32)","eip1559Denominator()(uint32)","eip1559Elasticity()(uint32)","operatorFeeScalar()(uint32)","operatorFeeConstant()(uint64)","daFootprintGasScalar()(uint16)","minBaseFee()(uint64)","l2ChainId()(uint256)","superchainConfig()(address)","unsafeBlockSigner()(address)","l1CrossDomainMessenger()(address)","l1ERC721Bridge()(address)","l1StandardBridge()(address)","optimismPortal()(address)","optimismMintableERC20Factory()(address)","delayedWETH()(address)","disputeGameFactory()(address)","lastUsedOPCM()(address)","lastUsedOPCMVersion()(string)","startBlock()(uint256)","paused()(bool)","guardian()(address)","isCustomGasToken()(bool)","resourceConfig()((uint32,uint8,uint8,uint32,uint32,uint128))","minimumGasLimit()(uint64)","batchInbox()(address)",
   "isFeatureEnabled(bytes32)(bool) 0x4554485f4c4f434b424f58000000000000000000000000000000000000000000","isFeatureEnabled(bytes32)(bool) 0x494e5445524f5000000000000000000000000000000000000000000000000000","isFeatureEnabled(bytes32)(bool) 0x435553544f4d5f4741535f544f4b454e00000000000000000000000000000000"),
 OptimismPortal2=G("version()(string)","initVersion()(uint8)","proxyAdmin()(address)","proxyAdminOwner()(address)","l2Sender()(address)","systemConfig()(address)","anchorStateRegistry()(address)","ethLockbox()(address)","disputeGameFactory()(address)","superchainConfig()(address)","guardian()(address)","paused()(bool)","proofMaturityDelaySeconds()(uint256)","disputeGameFinalityDelaySeconds()(uint256)","respectedGameType()(uint32)","respectedGameTypeUpdatedAt()(uint64)","params()(uint128,uint64,uint64)"),
 ETHLockbox=G("version()(string)","initVersion()(uint8)","proxyAdmin()(address)","proxyAdminOwner()(address)","systemConfig()(address)","superchainConfig()(address)","guardian()(address)","paused()(bool)","authorizedPortals(address)(bool) {OptimismPortal2}","authorizedLockboxes(address)(bool) {ETHLockbox}"),
 AnchorStateRegistry=G("version()(string)","initVersion()(uint8)","proxyAdmin()(address)","proxyAdminOwner()(address)","systemConfig()(address)","ethLockbox()(address)","superchainConfig()(address)","paused()(bool)","disputeGameFactory()(address)","anchorGame()(address)","getStartingAnchorRoot()((bytes32,uint256))","getAnchorRoot()(bytes32,uint256)","respectedGameType()(uint32)","retirementTimestamp()(uint64)","disputeGameFinalityDelaySeconds()(uint256)"),
 DisputeGameFactory=G("version()(string)","owner()(address)","initVersion()(uint8)","proxyAdmin()(address)","proxyAdminOwner()(address)","gameCount()(uint256)",
   *[f"gameImpls(uint32)(address) {i}" for i in range(0,11)], *[f"initBonds(uint32)(uint256) {i}" for i in range(0,11)], *[f"gameArgs(uint32)(bytes) {i}" for i in range(0,11)]),
 DelayedWETH=G("version()(string)","initVersion()(uint8)","proxyAdmin()(address)","proxyAdminOwner()(address)","systemConfig()(address)","ethLockbox()(address)","config()(address)","delay()(uint256)","totalSupply()(uint256)"),
 L1CrossDomainMessenger=G("version()(string)","initVersion()(uint8)","proxyAdmin()(address)","proxyAdminOwner()(address)","portal()(address)","PORTAL()(address)","systemConfig()(address)","superchainConfig()(address)","otherMessenger()(address)","OTHER_MESSENGER()(address)","messageNonce()(uint256)","paused()(bool)"),
 L1StandardBridge=G("version()(string)","initVersion()(uint8)","proxyAdmin()(address)","proxyAdminOwner()(address)","messenger()(address)","otherBridge()(address)","systemConfig()(address)","superchainConfig()(address)","paused()(bool)"),
 L1ERC721Bridge=G("version()(string)","initVersion()(uint8)","proxyAdmin()(address)","proxyAdminOwner()(address)","messenger()(address)","otherBridge()(address)","systemConfig()(address)","superchainConfig()(address)","paused()(bool)"),
 OptimismMintableERC20Factory=G("version()(string)","initVersion()(uint8)","bridge()(address)","BRIDGE()(address)"),
 ProxyAdmin=G("owner()(address)","addressManager()(address)","isUpgrading()(bool)",
   *[f"proxyType(address)(uint8) {{{n}}}" for n in ["SystemConfig","OptimismPortal2","ETHLockbox","AnchorStateRegistry","DisputeGameFactory","DelayedWETH","L1CrossDomainMessenger","L1StandardBridge","L1ERC721Bridge","OptimismMintableERC20Factory"]],
   *[f"getProxyImplementation(address)(address) {{{n}}}" for n in ["SystemConfig","OptimismPortal2","ETHLockbox","AnchorStateRegistry","DisputeGameFactory","DelayedWETH","L1CrossDomainMessenger","L1StandardBridge","L1ERC721Bridge","OptimismMintableERC20Factory"]],
   *[f"getProxyAdmin(address)(address) {{{n}}}" for n in ["SystemConfig","OptimismPortal2","ETHLockbox","AnchorStateRegistry","DisputeGameFactory","DelayedWETH","L1StandardBridge","L1ERC721Bridge","OptimismMintableERC20Factory"]],
   "implementationName(address)(string) {L1CrossDomainMessenger}"),
 SuperchainConfig=G("version()(string)","initVersion()(uint8)","proxyAdmin()(address)","proxyAdminOwner()(address)","guardian()(address)","paused()(bool)","paused(address)(bool) 0x0000000000000000000000000000000000000000","pauseExpiry()(uint256)",
   *[f"paused(address)(bool) {a}" for a in ["0xbEb5Fc579115071764c7423A4f12eDde41f106Ed","0x322b47Ff1FA8D5611F761e3E275C45B71b294D43","0x5d66C1782664115999C47c9fA5cd031f495D3e4F","0xbd4AbB321138e8Eddc399cE64E66451294325a14","0x88e529A6ccd302c948689Cd5156C83D4614FAE92","0x67B4de6FfA66EF201Ea6099A89cA397D56622E31","0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2","0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5"]],
   *[f"pauseTimestamps(address)(uint256) {a}" for a in ["0x0000000000000000000000000000000000000000","0xbEb5Fc579115071764c7423A4f12eDde41f106Ed","0x322b47Ff1FA8D5611F761e3E275C45B71b294D43","0x5d66C1782664115999C47c9fA5cd031f495D3e4F","0xbd4AbB321138e8Eddc399cE64E66451294325a14","0x88e529A6ccd302c948689Cd5156C83D4614FAE92","0x67B4de6FfA66EF201Ea6099A89cA397D56622E31","0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2","0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5"]]),
)
SC_NAMED = {"UNSAFE_BLOCK_SIGNER_SLOT": kstr("systemconfig.unsafeblocksigner"),
  "L1_CROSS_DOMAIN_MESSENGER_SLOT": minus1(kstr("systemconfig.l1crossdomainmessenger")), "L1_ERC_721_BRIDGE_SLOT": minus1(kstr("systemconfig.l1erc721bridge")),
  "L1_STANDARD_BRIDGE_SLOT": minus1(kstr("systemconfig.l1standardbridge")), "OPTIMISM_PORTAL_SLOT": minus1(kstr("systemconfig.optimismportal")),
  "OPTIMISM_MINTABLE_ERC20_FACTORY_SLOT": minus1(kstr("systemconfig.optimismmintableerc20factory")), "DELAYED_WETH_SLOT": minus1(kstr("systemconfig.delayedweth")),
  "OPCM_SLOT": minus1(kstr("systemconfig.opcm")), "LEGACY_BATCH_INBOX_SLOT": minus1(kstr("systemconfig.batchinbox")), "START_BLOCK_SLOT": minus1(kstr("systemconfig.startBlock")),
  "LEGACY_L2_OUTPUT_ORACLE_SLOT": minus1(kstr("systemconfig.l2outputoracle")), "LEGACY_DISPUTE_GAME_FACTORY_SLOT": minus1(kstr("systemconfig.disputegamefactory")),
  "LEGACY_GAS_PAYING_TOKEN_SLOT": minus1(kstr("opstack.gaspayingtoken")), "LEGACY_GAS_PAYING_TOKEN_NAME_SLOT": minus1(kstr("opstack.gaspayingtokenname")),
  "LEGACY_GAS_PAYING_TOKEN_SYMBOL_SLOT": minus1(kstr("opstack.gaspayingtokensymbol")),
  "FEATURE[ETH_LOCKBOX]": mapslot("0x4554485f4c4f434b424f58000000000000000000000000000000000000000000".ljust(66,"0"), 109),
  "FEATURE[INTEROP]": mapslot("0x494e5445524f5000000000000000000000000000000000000000000000000000", 109),
  "FEATURE[CUSTOM_GAS_TOKEN]": mapslot("0x435553544f4d5f4741535f544f4b454e00000000000000000000000000000000", 109)}

def cast_call(to, s):
    parts = s.split(" ")
    try:
        o = subprocess.run(["cast", "call", to, *parts, "--rpc-url", rpc], capture_output=True, text=True, timeout=120)
        return o.stdout.strip() if o.returncode == 0 else "REVERT: " + o.stderr.strip().splitlines()[-1][:200]
    except Exception as e:
        return "ERR: " + str(e)[:100]

def decode(entry, raw):
    v = int(raw, 16); off = int(entry["offset"]); n = int(entry["bytes"])
    if n > 32: return None
    val = (v >> (8*off)) & ((1 << (8*n)) - 1)
    t = entry["type"]
    if t.startswith("mapping") or t.endswith("[]"): return "(mapping/array base: %d)" % val
    if t == "address" or t.startswith("contract "): return "0x%040x" % val
    if t == "bool": return bool(val)
    if t.startswith("bytes"): return "0x" + ("%x" % val).rjust(2*n, "0")
    return val

result = {"_meta": {"rpc": rpc, "which": which, "layoutTag": TAG[which], "block": int(batch([("eth_blockNumber", [])])[0], 16)}}
for chain, cts in CHAINS.items():
    result[chain] = {}
    for name, addr in cts.items():
        try: layout = json.load(open(SNAP + name + ".json"))
        except Exception: layout = []
        n = NSLOTS[name]
        calls = [("eth_getStorageAt", [addr, hex(i), "latest"]) for i in range(n)]
        extra = {"EIP1967_IMPLEMENTATION": IMPL, "EIP1967_ADMIN": ADMIN, "OZ_V5_INITIALIZABLE": OZV5}
        if name == "SystemConfig": extra.update(SC_NAMED)
        if name == "L1CrossDomainMessenger":
            extra["RDP.implementationName[self] (keccak(self,0))"] = mapslot(addr, 0)
            extra["RDP.addressManager[self] (keccak(self,1))"] = mapslot(addr, 1)
        if name == "ETHLockbox":
            extra["authorizedPortals[portal]"] = mapslot(cts["OptimismPortal2"], 1)
            extra["authorizedLockboxes[self]"] = mapslot(addr, 2)
        if name == "ProxyAdmin":
            for k in ["L1CrossDomainMessenger", "L1StandardBridge", "OptimismPortal2", "SystemConfig", "ETHLockbox"]:
                extra[f"proxyType[{k}]"] = mapslot(cts[k], 1)
            extra["implementationName[L1CrossDomainMessenger]"] = mapslot(cts["L1CrossDomainMessenger"], 2)
        if name == "SuperchainConfig":
            for ident in ["0x0", cts["OptimismPortal2"], cts["ETHLockbox"]]:
                extra[f"pauseTimestamps[{ident}]"] = mapslot(ident, 1)
        if name == "DisputeGameFactory":
            for gt in range(0, 11):
                extra[f"gameImpls[{gt}]"] = mapslot(hex(gt), 101); extra[f"initBonds[{gt}]"] = mapslot(hex(gt), 102); extra[f"gameArgs[{gt}]"] = mapslot(hex(gt), 105)
        ekeys = list(extra)
        calls += [("eth_getStorageAt", [addr, extra[k], "latest"]) for k in ekeys]
        calls += [("eth_getBalance", [addr, "latest"]), ("eth_getCode", [addr, "latest"])]
        r = batch(calls)
        slots = {}
        for i in range(n):
            raw = r[i]
            ents = [e for e in layout if int(e["slot"]) == i]
            spanning = [e for e in layout if int(e["slot"]) < i < int(e["slot"]) + (int(e["bytes"]) + 31)//32]
            if int(raw, 16) == 0 and not ents: continue
            if ents:
                slots[str(i)] = {"label": " | ".join(e["label"] for e in ents), "type": " | ".join(e["type"] for e in ents), "raw": raw,
                                 "decoded": {e["label"]: decode(e, raw) for e in ents}}
            else:
                lab = ("(inside %s)" % spanning[0]["label"]) if spanning else "(UNLABELLED - not in %s layout)" % TAG[which]
                slots[str(i)] = {"label": lab, "type": spanning[0]["type"] if spanning else "?", "raw": raw, "decoded": raw}
        named = {k: {"slot": extra[k], "raw": r[n+j]} for j, k in enumerate(ekeys)}
        bal = int(r[n+len(ekeys)], 16); code = r[n+len(ekeys)+1]
        impl = "0x" + named["EIP1967_IMPLEMENTATION"]["raw"][-40:]
        getters = {}
        for g in GETTERS[name]:
            for k, v in cts.items(): g = g.replace("{%s}" % k, v)
            getters[g] = cast_call(addr, g)
        if name == "L1CrossDomainMessenger" or int(impl, 16) == 0:
            pa = cts.get("ProxyAdmin")
            if pa and name != "ProxyAdmin" and name != "SuperchainConfig":
                impl = cast_call(pa, f"getProxyImplementation(address)(address) {addr}")
        iloc = INITLOC.get(name, (0, 0))
        initv = None
        if iloc is not None:
            s0 = int(r[iloc[0]], 16); initv = {"_initialized": (s0 >> (8*iloc[1])) & 0xff, "_initializing": bool((s0 >> (8*(iloc[1]+1))) & 0xff)}
        implinfo = {}
        if isinstance(impl, str) and impl.startswith("0x") and int(impl, 16) != 0:
            ic = batch([("eth_getStorageAt", [impl, "0x0", "latest"]), ("eth_getCode", [impl, "latest"]), ("eth_getBalance", [impl, "latest"])])
            implinfo = {"slot0": ic[0], "codeSize": (len(ic[1]) - 2)//2, "codeHash": keccak(ic[1]) if len(ic[1]) > 2 else None, "ethBalance": int(ic[2], 16)}
        result[chain][name] = {"proxy": addr, "implementation": impl, "implementationInfo": implinfo, "version": getters.get("version()(string)"),
            "initializedVersion": initv, "proxyCodeSize": (len(code)-2)//2, "slots": slots, "namedSlots": named, "getters": getters,
            "ethBalance": str(bal), "ethBalanceEther": bal/1e18}
        print(chain, name, "ok", len(slots), file=sys.stderr)
json.dump(result, open(out, "w"), indent=1)
