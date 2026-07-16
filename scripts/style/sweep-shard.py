#!/usr/bin/env python3
"""P3 shard builder for the vocab sweep.

Turns the candidate list into balanced classification shards: per term, up to
30 session-stratified occurrences, each carrying the message text and its
assistant lookback/lookahead. Every shard gets 3 planted control rows with
known labels (the answer key lives in a file the shard agents never receive);
a shard that misgrades a control gets redone. Balancing is by occurrence
count, not term count, so shard wall-clock stays even.

Usage: sweep-shard.py <run-dir> [--per-shard 180]
"""
import json, os, sys, glob, random
random.seed(20260716)

RUN = sys.argv[1]
PER = int(sys.argv[sys.argv.index('--per-shard') + 1]) if '--per-shard' in sys.argv else 180
MAX_OCC = int(sys.argv[sys.argv.index('--max-occ') + 1]) if '--max-occ' in sys.argv else 30

row_by_ptr = {}
for p in glob.glob(f'{RUN}/corpus/*.jsonl'):
    for line in open(p):
        r = json.loads(line)
        row_by_ptr[(r['project'], r['session'], r['msg_idx'])] = r

def items_for(term_row):
    occ = term_row['occurrences']
    by_sess = {}
    for ptr in occ:
        by_sess.setdefault((ptr[0], ptr[1]), []).append(ptr)
    picked = []
    sessions = list(by_sess)
    random.shuffle(sessions)
    while sessions and len(picked) < MAX_OCC:
        for s in list(sessions):
            if by_sess[s]:
                picked.append(by_sess[s].pop(0))
                if len(picked) >= MAX_OCC: break
            else:
                sessions.remove(s)
        if all(not v for v in by_sess.values()): break
    out = []
    for ptr in picked:
        r = row_by_ptr.get(tuple(ptr))
        if not r: continue
        t = r['text']
        i = t.lower().find(term_row['term'])
        window = t if len(t) <= 700 else t[max(0, i - 300):i + 400]
        out.append({'term': term_row['term'], 'ptr': ptr, 'text': window,
                    'lookback': r['lookback'][-250:], 'lookahead': r['lookahead'][:250]})
    return out

CONTROLS = [
    {'term': 'overindex', 'ptr': ['__control__', 0, 1],
     'text': "Do not overindex on that one failing example, be pragmatic about the class of issue instead.",
     'lookback': 'I found the failing case in row 42 and generalized the fix from it.', 'lookahead': '',
     '_answer': 'steering'},
    {'term': 'redis', 'ptr': ['__control__', 0, 2],
     'text': "Wire the session cache through redis instead of the file store, and don't lose the TTL semantics this time.",
     'lookback': 'The file-store cache dropped TTLs on restart.', 'lookahead': 'Rewired the cache through redis with TTL preserved.', '_answer': 'domain-term'},
    {'term': 'robust', 'ptr': ['__control__', 0, 3],
     'text': 'The doc you wrote says "a seamless, robust developer experience" which is exactly the marketing voice I told you to drop.',
     'lookback': 'Here is the draft README you asked for.', 'lookahead': '', '_answer': 'quoted'},
]

terms = [json.loads(l) for l in open(f'{RUN}/candidates/candidates.jsonl')]
terms += [json.loads(l) for l in open(f'{RUN}/candidates/tracers.jsonl')]
all_items = []
for tr in terms:
    all_items.extend(items_for(tr))

os.makedirs(f'{RUN}/contexts-input', exist_ok=True)
os.makedirs(f'{RUN}/contexts', exist_ok=True)
shards, cur = [], []
count = 0
for it in all_items:
    cur.append(it); count += 1
    if count >= PER:
        shards.append(cur); cur = []; count = 0
if cur: shards.append(cur)

key = {}
for n, shard in enumerate(shards, 1):
    sid = f'shard-{n:02d}'
    controls = []
    for k, c in enumerate(CONTROLS):
        c2 = {kk: vv for kk, vv in c.items() if kk != '_answer'}
        c2['ptr'] = ['__control__', n, k + 1]
        controls.append(c2)
        key[f'{sid}/{k+1}'] = c['_answer']
    items = shard + controls
    random.shuffle(items)
    json.dump({'shard_id': sid, 'n_items': len(items), 'items': items},
              open(f'{RUN}/contexts-input/{sid}.json', 'w'))
json.dump(key, open(f'{RUN}/candidates/control-key.json', 'w'))
print(f'{len(shards)} shards, {len(all_items)} real occurrences + {3*len(shards)} controls; '
      f'terms={len(terms)} (incl. {sum(1 for t in terms if t.get("tracer"))} tracers)')
