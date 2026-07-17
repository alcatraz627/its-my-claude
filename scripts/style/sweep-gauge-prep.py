#!/usr/bin/env python3
"""P4 prep: aggregate P3 per-occurrence labels into per-term evidence bundles,
mechanically bucket, and shard the judgment-worthy set for sonnet gauging.

The cheap call is made here so sonnet is only spent where judgment matters: a
term whose occurrences are 0% steering is domain-jargon by arithmetic, not by
opinion. Only terms carrying real steering signal (or a planted tracer) reach a
gauging agent, which decides the hard question a ratio cannot: genuine reusable
shorthand vs a one-off command idiom vs project-scoped jargon.

Usage: sweep-gauge-prep.py <run-dir>
"""
import json, os, sys, glob
from collections import defaultdict

RUN = sys.argv[1]
GAUGE_FLOOR = 0.30   # steering-ratio below this and not a tracer -> mechanical bucket
PER_SHARD = 22       # terms per gauging agent

tracers = {}
for l in open(f'{RUN}/candidates/tracers.jsonl'):
    t = json.loads(l); tracers[t['term']] = t['tracer']

byterm = defaultdict(lambda: {'labels': [], 'meanings': []})
for p in glob.glob(f'{RUN}/contexts/shard-*.jsonl'):
    if '.corrections' in p: continue
    for line in open(p):
        r = json.loads(line)
        if r['ptr'][0] == '__control__': continue
        b = byterm[r['term']]
        b['labels'].append(r['label'])
        if r['label'] in ('steering', 'domain-term') and len(b['meanings']) < 12:
            b['meanings'].append({'label': r['label'], 'meaning': r['meaning'], 'ptr': r['ptr']})

# scored candidates carry spread/zipf; join them in
cand = {json.loads(l)['term']: json.loads(l) for l in open(f'{RUN}/candidates/candidates.jsonl')}

bundles, mech = [], []
for term, b in byterm.items():
    n = len(b['labels'])
    if n == 0: continue
    dist = {k: b['labels'].count(k) for k in ('steering', 'domain-term', 'quoted', 'incidental')}
    steer_ratio = dist['steering'] / n
    meta = cand.get(term, {})
    rec = {'term': term, 'n_labeled': n, 'dist': dist, 'steer_ratio': round(steer_ratio, 2),
           'sessions': meta.get('sessions'), 'zipf': meta.get('zipf'),
           'tracer': tracers.get(term), 'evidence': b['meanings']}
    if tracers.get(term) or steer_ratio >= GAUGE_FLOOR:
        bundles.append(rec)
    else:
        # mechanical verdict: no steering signal to weigh
        dom = dist['domain-term'] / n
        rec['mech_verdict'] = ('domain-jargon' if dom >= 0.5 else
                               'quoted-noise' if dist['quoted'] / n >= 0.5 else 'low-signal-reject')
        mech.append(rec)

bundles.sort(key=lambda r: -r['steer_ratio'])
os.makedirs(f'{RUN}/gauged', exist_ok=True)
os.makedirs(f'{RUN}/gauge-input', exist_ok=True)
json.dump(mech, open(f'{RUN}/gauged/mechanical.json', 'w'), indent=1)

# 10% dual-assignment for the overlap audit: every 10th bundle is duplicated
# into a parallel shard so two independent agents rule on it
overlap = bundles[::10]
shards = [bundles[i:i + PER_SHARD] for i in range(0, len(bundles), PER_SHARD)]
for n, sh in enumerate(shards, 1):
    json.dump({'shard_id': f'gauge-{n:02d}', 'n_terms': len(sh), 'terms': sh},
              open(f'{RUN}/gauge-input/gauge-{n:02d}.json', 'w'))
if overlap:
    json.dump({'shard_id': 'gauge-overlap', 'n_terms': len(overlap), 'terms': overlap},
              open(f'{RUN}/gauge-input/gauge-overlap.json', 'w'))

print(f'gauge-worthy terms: {len(bundles)} in {len(shards)} shards (+{len(overlap)} overlap dups)')
print(f'mechanically bucketed (no sonnet): {len(mech)} '
      f'({sum(1 for m in mech if m["mech_verdict"]=="domain-jargon")} domain-jargon, '
      f'{sum(1 for m in mech if m["mech_verdict"]=="quoted-noise")} quoted-noise, '
      f'{sum(1 for m in mech if m["mech_verdict"]=="low-signal-reject")} low-signal)')
print('tracer buckets:', {t['term']: ('GAUGE' if (tracers.get(t['term']) or t['steer_ratio']>=GAUGE_FLOOR) else t.get('mech_verdict'))
      for t in bundles + mech if t.get('tracer')})
print('\ntop gauge-worthy by steer_ratio:')
for r in bundles[:22]:
    print(f"  {r['steer_ratio']:.2f}  {r['term']:24s} n={r['n_labeled']:2d} sess={r['sessions']} dist={r['dist']}")
