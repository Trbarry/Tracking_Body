"""F5 shared read-only helpers (JSON-RPC against the local L1 archive failover proxy)."""
import json, time, urllib.request, subprocess, functools, os

RPC = os.environ.get("F5_RPC", "http://127.0.0.1:7545")
PIN = 26433900
N = 26430859
IMPL_SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
ADMIN_SLOT = "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"

CHAINS = {
    "OP": dict(chainId=10, SystemConfig="0x229047fed2591dbec1eF1118d64F7aF3dB9EB290", OptimismPortal="0xbEb5Fc579115071764c7423A4f12eDde41f106Ed",
               ETHLockbox="0x322b47Ff1FA8D5611F761e3E275C45B71b294D43", AnchorStateRegistry="0x23B2C62946350F4246f9f9D027e071f0264FD113",
               DisputeGameFactory="0xe5965Ab5962eDc7477C8520243A95517CD252fA9", DelayedWETH="0x1B6DBF05EaF22d4E70dC993e8a19dd9F3dcb3162",
               L1CrossDomainMessenger="0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1", L1StandardBridge="0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1",
               L1ERC721Bridge="0x5a7749f83b81B301cAb5f48EB8516B986DAef23D", OptimismMintableERC20Factory="0x75505a97BD334E7BD3C476893285569C4136Fa0F",
               ProxyAdmin="0x543bA4AADBAb8f9025686Bd03993043599c6fB04"),
    "INK": dict(chainId=57073, SystemConfig="0x62c0a111929fa32cec2f76adba54c16afb6e8364", OptimismPortal="0x5d66C1782664115999C47c9fA5cd031f495D3e4F",
                ETHLockbox="0xbd4AbB321138e8Eddc399cE64E66451294325a14", AnchorStateRegistry="0xEe018bAf058227872540AC60eFbd38b023d9dAe2",
                DisputeGameFactory="0x10d7B35078d3baabB96Dd45a9143B94be65b12CD", DelayedWETH="0x57b4C29DAee99a28E6E86778b499361294c134eA",
                L1CrossDomainMessenger="0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f", L1StandardBridge="0x88FF1e5b602916615391F55854588EFcBB7663f0",
                L1ERC721Bridge="0x661235a238B11191211fa95D4Dd9E423d521E0Be", OptimismMintableERC20Factory="0xA8B389A82e088b164cD03230e900980CcED34d29",
                ProxyAdmin="0xd56045E68956FCe2576E680c95a4750cf8241f79"),
    "SONEIUM": dict(chainId=1868, SystemConfig="0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3", OptimismPortal="0x88e529A6ccd302c948689Cd5156C83D4614FAE92",
                    ETHLockbox="0x67B4de6FfA66EF201Ea6099A89cA397D56622E31", AnchorStateRegistry="0x4890928941e62e273dA359374b105F803329F473",
                    DisputeGameFactory="0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0", DelayedWETH="0x18fBb58C366e21F395DdEc7cBa0510a2D9116B47",
                    L1CrossDomainMessenger="0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f", L1StandardBridge="0xeb9bf100225c214Efc3E7C651ebbaDcF85177607",
                    L1ERC721Bridge="0x5933e323bE8896DfaCd1cD671442F27dAA10a053", OptimismMintableERC20Factory="0xc1047e30EFC9E172cFe7aa0219895B6a43fC415F",
                    ProxyAdmin="0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a"),
    "UNICHAIN": dict(chainId=130, SystemConfig="0xc407398d063f942febbcc6f80a156b47f3f1bda6", OptimismPortal="0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2",
                     ETHLockbox="0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5", AnchorStateRegistry="0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9",
                     DisputeGameFactory="0x2F12d621a16e2d3285929C9996f478508951dFe4", DelayedWETH="0x74ad145aC900F1DD5551F0C9E143314DC4022FCf",
                     L1CrossDomainMessenger="0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6", L1StandardBridge="0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA",
                     L1ERC721Bridge="0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf", OptimismMintableERC20Factory="0xA2B597EaeAcb6F627e088cbEaD319e934ED5edad",
                     ProxyAdmin="0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4"),
}
SUPERCHAIN_CONFIG = "0x95703e0982140D16f8ebA6d158FccEde42f04a4C"

def rpc(method, params, tries=8, rpc_url=None):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    err = None
    for attempt in range(tries):
        try:
            req = urllib.request.Request(rpc_url or RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "rpc-client"})
            with urllib.request.urlopen(req, timeout=90) as r:
                j = json.loads(r.read())
            if "result" in j:
                return j["result"]
            err = j.get("error")
            if err and "revert" in str(err).lower():
                raise ValueError(str(err))
        except ValueError:
            raise
        except Exception as e:  # noqa
            err = str(e)
        time.sleep(0.5 + attempt)
    raise RuntimeError(f"rpc failed {method} {str(params)[:200]}: {err}")

def blk(b):
    return hex(b) if isinstance(b, int) else b

def storage(addr, slot, block=PIN):
    if isinstance(slot, int):
        slot = hex(slot)
    return rpc("eth_getStorageAt", [addr, slot, blk(block)])

def balance(addr, block=PIN):
    return int(rpc("eth_getBalance", [addr, blk(block)]), 16)

def code(addr, block=PIN):
    return rpc("eth_getCode", [addr, blk(block)])

def call_raw(addr, data, block=PIN):
    try:
        return rpc("eth_call", [{"to": addr, "data": data}, blk(block)])
    except ValueError:
        return None

@functools.lru_cache(maxsize=None)
def sig(s):
    return subprocess.run(["cast", "sig", s], capture_output=True, text=True).stdout.strip()

@functools.lru_cache(maxsize=None)
def topic(s):
    return subprocess.run(["cast", "sig-event", s], capture_output=True, text=True).stdout.strip()

def w(n):
    return f"{n:064x}"

def call(addr, fn, args=(), block=PIN):
    """fn like 'owner()'; args: ints / hex addresses / bytes32 hex; returns raw hex or None on revert."""
    data = sig(fn)
    for a in args:
        if isinstance(a, int):
            data += w(a)
        else:
            data += w(int(a, 16))
    return call_raw(addr, data, block)

def as_addr(x):
    return None if not x or x == "0x" else "0x" + x[-40:]

def as_int(x):
    return None if not x or x == "0x" else int(x[:66], 16)

def as_str(x):
    if not x or x == "0x":
        return None
    try:
        h = x[2:]
        ln = int(h[64:128], 16)
        return bytes.fromhex(h[128:128 + 2 * ln]).decode()
    except Exception:
        return None

def block_ts(b):
    r = rpc("eth_getBlockByNumber", [blk(b), False])
    return int(r["timestamp"], 16)

def logs(address, topics, frm, to, chunk=None):
    """eth_getLogs with adaptive splitting. address: str or list."""
    out = []
    def go(a, b):
        try:
            r = rpc("eth_getLogs", [{"address": address, "topics": topics, "fromBlock": hex(a), "toBlock": hex(b)}], tries=3)
            if r is None:
                raise RuntimeError("null")
            out.extend(r)
        except Exception:
            if a >= b:
                raise
            m = (a + b) // 2
            go(a, m)
            go(m + 1, b)
    if chunk:
        for a in range(frm, to + 1, chunk):
            go(a, min(a + chunk - 1, to))
    else:
        go(frm, to)
    out.sort(key=lambda l: (int(l["blockNumber"], 16), int(l["logIndex"], 16)))
    return out

def first_code_block(addr, lo=10_000_000, hi=PIN):
    """Smallest block at which addr has code (binary search; assumes monotone)."""
    if code(addr, hi) in ("0x", None):
        return None
    while lo < hi:
        m = (lo + hi) // 2
        if code(addr, m) not in ("0x", None):
            hi = m
        else:
            lo = m + 1
    return lo

def slot_history(addr, slot, lo, hi=PIN):
    """All value changes of a storage slot between lo and hi by recursive bisection
    (misses A->B->A excursions inside an interval). Returns [(block, value)] = first block with new value."""
    res = []
    cache = {}
    def v(b):
        if b not in cache:
            cache[b] = storage(addr, slot, b)
        return cache[b]
    def go(a, b):
        if v(a) == v(b):
            return
        if b == a + 1:
            res.append((b, v(b)))
            return
        m = (a + b) // 2
        go(a, m)
        go(m, b)
    go(lo, hi)
    return [(lo, v(lo))] + sorted(res)
