"""Build the ATK-T2 fork-test fixtures: full Types.WithdrawalTransaction for chosen real objects + eth_getProof
storage proofs at the L2 block of OP game 21388 (L2 159,653,251, root 0x05bfbbc4...)."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpc
from keccak import keccak
from legacy_census_lib import migrate, dec_word, L2CDM, L1CDM
E = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/T2"
OUTD = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/test/poc/attack-wave/T2/fixtures"
os.makedirs(OUTD, exist_ok=True)
L2BLOCK = 159653251
want_ovm1 = {668: "ovm1_unrelayed_25ETH", 16753: "ovm1_relayed_600ETH"}
want_ovm2 = {110269: "ovm2_relayed_35555ETH", 132971: "ovm2_unrelayed"}
want_bedrock = {"0xafbabc05c9a66929457ea97120469f6bb7e2afe7b795b63314ff77df1db5a526": "bedrock_regolith_messenger",
                "0xa0a06f614cbab329889e7ffd3582335cec98c92a29555eef05181d9af776f1e6": "ecotone_direct_eoa",
                "0xa903f2ec0354c8b37e74b7405222f5f3503c0f60a1d48243407945e418e2dcf9": "isthmus_direct_feevault"}
items = []
def add(label, nonce, sender, target, value, gas, data, era):
    wh = keccak(nonce.to_bytes(32,"big") + b"\x00"*12 + sender + b"\x00"*12 + target + value.to_bytes(32,"big") + gas.to_bytes(32,"big")
                + (192).to_bytes(32,"big") + len(data).to_bytes(32,"big") + data + b"\x00"*((32-len(data)%32)%32))
    items.append(dict(id=label, era=era, nonce=str(nonce), sender="0x"+sender.hex(), target="0x"+target.hex(), value=str(value), gasLimit=str(gas), data="0x"+data.hex(), withdrawalHash="0x"+wh.hex()))
for m in json.load(open("/home/user/ethereum-optimism/ext-codex/sherlock-bedrock-fix-CF3/optimism/packages/migration-data/data/ovm-messages.json")):
    c = bytes.fromhex(m["msg"][2:]); nonce = dec_word(c[4:], 3)
    if nonce in want_ovm1:
        off = dec_word(c[4:], 2); ln = dec_word(c[4:], off//32)
        value, v0, v1, wh, gas, data = migrate(c[16:36], c[48:68], c[4+off+32:4+off+32+ln], nonce)
        add(want_ovm1[nonce], nonce, L2CDM, L1CDM, value, gas, data, "ovm1"); assert items[-1]["withdrawalHash"] == wh
for l in json.load(open(f"{E}/raw/l2-legacy-sentmessage.json"))["logs"]:
    d = bytes.fromhex(l["data"][2:]); nonce = dec_word(d, 2)
    if nonce in want_ovm2:
        off = dec_word(d, 1); ln = dec_word(d, off//32)
        value, v0, v1, wh, gas, data = migrate(bytes.fromhex(l["topics"][1][-40:]), d[12:32], d[off+32:off+32+ln], nonce)
        add(want_ovm2[nonce], nonce, L2CDM, L1CDM, value, gas, data, "ovm2"); assert items[-1]["withdrawalHash"] == wh
for r in json.load(open(f"{E}/bedrock-messagepassed-census.json")):
    if r["withdrawalHash"] in want_bedrock:
        add(want_bedrock[r["withdrawalHash"]], r["nonce"], bytes.fromhex(r["sender"][2:]), bytes.fromhex(r["target"][2:]), r["value"], r["gasLimit"], bytes.fromhex(r["data"][2:]), r["era"])
        assert items[-1]["withdrawalHash"] == r["withdrawalHash"]
assert len(items) == 7, len(items)
b = rpc.call(rpc.L2, "eth_getBlockByNumber", [hex(L2BLOCK), False])
slots = ["0x" + keccak(bytes.fromhex(i["withdrawalHash"][2:]) + b"\x00"*32).hex() for i in items]
p = rpc.call(rpc.L2, "eth_getProof", ["0x4200000000000000000000000000000000000016", slots, hex(L2BLOCK)])
orr = "0x" + keccak(b"\x00"*32 + bytes.fromhex(b["stateRoot"][2:]) + bytes.fromhex(p["storageHash"][2:]) + bytes.fromhex(b["hash"][2:])).hex()
assert orr == "0x05bfbbc4c8ee97467ddca915bf6704eaa7fc1580473cd2ca22ddda355bd64111", orr
for it, sp in zip(items, p["storageProof"]):
    assert int(sp["value"], 16) == 1, (it["id"], sp["value"])
    it["proof"] = sp["proof"]
    json.dump(it, open(f"{OUTD}/{it['id']}.json", "w"), indent=1)
json.dump(dict(gameIndex=21388, game="0x668513Abb2B32A988f9F4AaDa89ca48A974F8b65", l2Block=L2BLOCK, version="0x"+"00"*32, stateRoot=b["stateRoot"],
               messagePasserStorageRoot=p["storageHash"], latestBlockhash=b["hash"], outputRoot=orr, ids=[i["id"] for i in items]), open(f"{OUTD}/output.json", "w"), indent=1)
print("ok", [(i["id"], i["withdrawalHash"][:10], len(i["proof"])) for i in items])
