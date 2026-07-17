#!/usr/bin/env python3
"""P5 prep: for each P4 survivor worth synthesizing, gather ALL its corpus
occurrences (not the 15-sample P3/P4 saw) and its recency profile, so the
synthesis agent judges the full evidence and the proposal table can show
staleness. Already-baked terms are dropped (they have glossary rows); the
novel + borderline survivors get bundles.

Usage: .venv-sweep/bin/python sweep-synth-prep.py <run-dir>
"""
import json, os, sys, glob, re
from collections import defaultdict

RUN = sys.argv[1]

# already-baked terms (+ n-gram variants) don't need synthesis
baked = set()
for l in open(os.path.expanduser('~/.claude/style/glossary-hints.tsv')):
    if l.startswith('#') or '\t' not in l: continue
    baked.add(l.split('\t')[0].strip().lower())
baked |= {'overindex on', 'do not overindex', 'one-shot', 'one-shotting'}

# P4 keeps + the overlap-disagreement borderline
home = {}
for sp in glob.glob(f'{RUN}/gauged/gauge-*.jsonl'):
    if 'overlap' in sp: continue
    for l in open(sp):
        r = json.loads(l); home[r['term']] = r
survivors = [t for t, r in home.items() if r['keep'] and t not in baked]
if home.get('spam'): survivors.append('spam')  # P6 adjudicates the overlap split
survivors = sorted(set(survivors))

# full corpus occurrences per survivor
corp = []
for p in glob.glob(f'{RUN}/corpus/*.jsonl'):
    corp += [json.loads(l) for l in open(p)]

def occ_of(term):
    out = []
    for r in corp:
        toks = set(re.findall(r"[a-z][a-z'-]*[a-z]", r['text'].lower()))
        hit = (term in toks) if ' ' not in term else (term in r['text'].lower())
        if hit:
            t = r['text']
            i = t.lower().find(term.split()[0])
            out.append({'ptr': [r['project'], r['session'], r['msg_idx']], 'ts': r['ts'][:10] if r['ts'] else '',
                        'text': t if len(t) <= 500 else t[max(0, i-220):i+280],
                        'lookback': r['lookback'][-200:], 'lookahead': r['lookahead'][:200]})
    return out

def recency(occs):
    ds = sorted(d['ts'] for d in occs if d['ts'])
    if not ds: return {}
    from collections import Counter
    wk = Counter(d[:7] for d in ds)
    return {'first': ds[0], 'last': ds[-1], 'n_dated': len(ds),
            'span_days': (len(set(ds))), 'by_month': dict(sorted(wk.items()))}

os.makedirs(f'{RUN}/synthesis', exist_ok=True)
os.makedirs(f'{RUN}/synth-input', exist_ok=True)
bundles = []
for term in survivors:
    occs = occ_of(term)
    bundles.append({'term': term, 'p4': home[term], 'n_occ': len(occs),
                    'recency': recency(occs), 'occurrences': occs[:40]})

# shard 4 terms per synthesis agent
PER = 4
shards = [bundles[i:i+PER] for i in range(0, len(bundles), PER)]
for n, sh in enumerate(shards, 1):
    json.dump({'shard_id': f'synth-{n:02d}', 'terms': sh},
              open(f'{RUN}/synth-input/synth-{n:02d}.json', 'w'))
print(f'{len(survivors)} survivors to synthesize in {len(shards)} shards: {survivors}')
for b in bundles:
    r = b['recency']
    print(f"  {b['term']:14s} occ={b['n_occ']:3d}  {r.get('first','?')}->{r.get('last','?')}  months={list(r.get('by_month',{}).keys())}")
