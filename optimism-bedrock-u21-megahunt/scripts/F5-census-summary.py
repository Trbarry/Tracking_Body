#!/usr/bin/env python3
"""Summarise a games census JSON: lineage classes, third-party claim-valid / in-progress games, ASR mismatch check."""
import json, sys, collections, datetime
f, cur_asr, retire = sys.argv[1], sys.argv[2].lower(), int(sys.argv[3])
g = json.load(open(f))
d = lambda t: datetime.datetime.fromtimestamp(t, datetime.UTC).strftime('%Y-%m-%d %H:%M')
print(f"games {len(g)}  index {g[0]['index']}..{g[-1]['index']}  created {d(g[0]['createdAt'])} .. {d(g[-1]['createdAt'])}")
ST = {0: "IN_PROGRESS", 1: "CHALLENGER_WINS", 2: "DEFENDER_WINS", None: "?"}
print("\n-- lineage classes: (type, version, gameASR, weth, prestate) -> n, index range, date range, creators")
cl = collections.OrderedDict()
for x in g:
    k = (x['type'], x['version'], x['gameAsr'], x['weth'], x['prestate'])
    cl.setdefault(k, []).append(x)
for k, v in cl.items():
    cr = collections.Counter(y['creator'] for y in v)
    print(f"type {k[0]} v{k[1]} asr {k[2]} weth {k[3]} prestate {k[4]}\n     n={len(v)} idx {v[0]['index']}..{v[-1]['index']} {d(v[0]['createdAt'])}..{d(v[-1]['createdAt'])} creators {dict(cr.most_common(4))}{' +%d more'%(len(cr)-4) if len(cr)>4 else ''}")
print("\n-- (type, creator, status, claimValid, blacklisted, retired, wasRespected) -> count")
cnt = collections.Counter((x['type'], x['creator'], ST[x['status']], x['claimValid'], x['blacklisted'], x['retired'], x['wasRespected']) for x in g)
for k, n in sorted(cnt.items(), key=lambda z: -z[1]):
    print(" ", k, n)
main = collections.Counter(x['creator'] for x in g).most_common(1)[0][0]
print("\n-- games whose own ASR != current ASR and NOT retired (createdAt > retirementTimestamp %d):" % retire)
bad = [x for x in g if (x['gameAsr'] or '').lower() != cur_asr and not x['retired']]
print("   count", len(bad))
for x in bad[:40]:
    print("  ", x['index'], x['type'], x['game'], x['creator'], ST[x['status']], d(x['createdAt']), 'asr', x['gameAsr'], 'claimValid', x['claimValid'])
print("\n-- blacklisted games:", [(x['index'], x['game']) for x in g if x['blacklisted']])
print("\n-- claimValid or IN_PROGRESS(non-retired) games by creator")
c2 = collections.Counter((x['creator'], x['type'], ST[x['status']], x['claimValid']) for x in g if x['claimValid'] or (x['status'] == 0 and not x['retired']))
for k, n in sorted(c2.items(), key=lambda z: -z[1]):
    print("  ", k, n)
print("\n-- IN_PROGRESS but retired:", collections.Counter((x['creator'], x['type']) for x in g if x['status'] == 0 and x['retired']))
