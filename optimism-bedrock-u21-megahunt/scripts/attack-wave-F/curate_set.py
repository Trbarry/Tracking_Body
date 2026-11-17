# ATK-F: keep only addresses of the raw set that have code on L1 at 26433900 (pinned :8545); add DelayedWETH generations
import json, urllib.request
BASE = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/"
raw = json.load(open(BASE + "evidence/attack-wave/F/system-address-set-raw.json"))
extra = ["0x82511d494B5C942BE57498a70Fdd7184Ee33B975","0x9F9b897e37de5052cD70Db6D08474550DDb07f39","0x323dFC63c9B83CB83f40325AaB74b245937cbdF0",
 "0x21429aF66058BC3e4aE4a8f2EC4531AaC433ecbC","0xe214879aD573693A4C49f7654449Caa455cdE34f","0xc5f54F934075677FBA99b5E43468439cbdE88ca7",
 "0xD061AB95069987868768818cc1248705351e2D0e","0xe03F4d1D0E6B8b18b97198598b3f792E57BA17d4","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"]
for e in extra: raw.setdefault(e.lower(), ["F4 hist / WETH9"])
addrs = sorted(raw)
batch = [{"jsonrpc": "2.0", "id": i, "method": "eth_getCode", "params": [a, hex(26433900)]} for i, a in enumerate(addrs)]
out = []
for i in range(0, len(batch), 50):
    r = urllib.request.Request("http://127.0.0.1:8545", json.dumps(batch[i:i+50]).encode(), {"content-type": "application/json"})
    out += json.load(urllib.request.urlopen(r, timeout=300))
code = {addrs[o["id"]]: (len(o.get("result", "0x")) - 2) // 2 for o in out}
cur = {a: {"src": raw[a], "codesize": code[a]} for a in addrs if code[a] > 0}
json.dump(cur, open(BASE + "evidence/attack-wave/F/system-contract-set.json", "w"), indent=0)
print(len(addrs), "raw ->", len(cur), "with code")
