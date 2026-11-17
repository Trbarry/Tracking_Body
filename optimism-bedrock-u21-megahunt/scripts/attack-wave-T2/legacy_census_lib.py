"""ATK-T2 (a): census of every legacy (version-0) messenger withdrawal emitted on OVM 2.0 L2
(legacy L2CDM SentMessage, L2 blocks 0..105,235,062), migrated exactly as op-chain-ops
MigrateWithdrawal did, then joined with L1 relay status (legacy RelayedMessage(v0hash),
Bedrock RelayedMessage/FailedRelayedMessage(v1hash)) and portal proven/finalized(withdrawalHash)."""
import json, os, sys, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from keccak import keccak
R = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/T2/raw"
OUT = "/home/user/Tracking_Body/optimism-bedrock-u21-megahunt/evidence/attack-wave/T2"
L1CDM = bytes.fromhex("25ace71c97b33cc4729cf772ae268934f7ab5fa1")
L2CDM = bytes.fromhex("4200000000000000000000000000000000000007")
L2SB = bytes.fromhex("4200000000000000000000000000000000000010")
L1SB = bytes.fromhex("99c9fc46f92e8a1c0dec1b1747d010903e884be1")
def w(x): return x.to_bytes(32, "big")
def a(x): return b"\x00"*12 + x
def dyn(b): return w(len(b)) + b + b"\x00"*((32 - len(b) % 32) % 32)
def dec_word(d, i): return int.from_bytes(d[32*i:32*i+32], "big")
def migrate_gas(data):
    g = len(data)*16 + 200_000 + (64*1_000_000)//63 + 40_000 + 40_000 + 5_000
    return min(g, 25_000_000)
def load(name): return json.load(open(os.path.join(R, name)))["logs"]


def l1_status():
    legacy_relayed=set(); bedrock_relayed=set(); failed=set(); rb={}
    for l in load("l1cdm-relayed.json"):
        h=(l["topics"][1] if len(l["topics"])>1 else l["data"]).lower(); blk=int(l["blockNumber"],16)
        (legacy_relayed if blk<17422444 else bedrock_relayed).add(h); rb.setdefault(h,blk)
    for l in load("l1cdm-failed.json"):
        failed.add((l["topics"][1] if len(l["topics"])>1 else l["data"]).lower())
    fin={l["topics"][1].lower():(int(l["data"][2:],16)==1,int(l["blockNumber"],16)) for l in load("op-portal-finalized.json")}
    prov=collections.Counter(l["topics"][1].lower() for l in load("op-portal-proven.json"))
    return legacy_relayed,bedrock_relayed,failed,rb,fin,prov
def migrate(target,sender,msg,nonce):
    value=0
    if sender==L2SB and msg[:4]==bytes.fromhex("1532ec34"): value=int.from_bytes(msg[4+64:4+96],"big")
    v0=keccak(bytes.fromhex("cbd4ece9")+a(target)+a(sender)+w(128)+w(nonce)+dyn(msg))
    data=bytes.fromhex("d764ad0b")+w(nonce)+a(sender)+a(target)+w(value)+w(0)+w(192)+dyn(msg)
    v1=keccak(data); gas=migrate_gas(data)
    wh=keccak(w(nonce)+a(L2CDM)+a(L1CDM)+w(value)+w(gas)+w(192)+dyn(data))
    return value,"0x"+v0.hex(),"0x"+v1.hex(),"0x"+wh.hex(),gas,data
