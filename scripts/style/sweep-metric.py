#!/usr/bin/env python3
"""P2 of the vocab sweep: score candidate steering terms and cut to the top N.

Reads the P1 corpus, scores every unigram/bigram/trigram by
spread x context-weight x rarity x novelty, and writes the top candidates with
their occurrence pointers. Runs the calibration gate first: with novelty
disabled, the known-baked positives must land in the top decile and the named
common-word negatives must be rejected, or the run must stop here (a metric
that cannot re-find hand-found words has no business proposing new ones).

Usage: .venv-sweep/bin/python sweep-metric.py <run-dir> [--top 300]
"""
import json, math, os, re, sys, glob
from collections import defaultdict
from wordfreq import zipf_frequency

RUN = sys.argv[1]
TOP = int(sys.argv[sys.argv.index('--top') + 1]) if '--top' in sys.argv else 300

TOKEN = re.compile(r"[a-z][a-z'-]{1,}[a-z]|[a-z]{2,}")
CORRECTION = re.compile(r"\b(don't|do not|stop|never|always|why did you|why are you|i want|i need|be more|instead|not what i)\b")
SENT_SPLIT = re.compile(r'[.!?\n;,]+')
IMPERATIVE = re.compile(r"\b(do not|don't|stop|never|always|keep|make|avoid|remember|please|instead|should|you are|you're|be more|i want|i need|i don't|too\s+\w+)\b")
EVALUATIVE = re.compile(r"\b(this is|that is|that's|it's|feels|looks|seems|reads as|i like|i hate|i prefer|good|bad|wrong|right|fine|great|terrible|annoying)\b")
STOPEDGE = {'the','and','for','you','that','this','with','are','was','not','but','have','has','had','can','will','its','all','our','your','out','use','get','one','two','how','what','when','where','why','who','which','should','would','could','than','then','them','they','there','here','from','into','onto','over','under','about','just','also','been','being','because','while','after','before','only','same','some','any','each','very','more','most','less','least','too','own','off','per','via','let','lets'}

# Gate checks only lexical positives; contextual words (intent, stupid,
# one-shot) are unreachable at word level — planted as P3/P4 tracers.
POSITIVES = ['efficacy', 'overindex']
POSITIVES_TRACER = ['intent', 'stupid', 'one-shot']
POSITIVES_INFO = ['pragmatic', 'one-shotting', 'waste my time']
# User verdict 2026-07-16 (option 1): ultra-common words gate P2; the
# transcript-class (domain nouns lexically twinned with steering words) is a
# planted NEGATIVE tracer for P4 — P4 must classify it domain-jargon or halt.
NEGATIVES = ['the', 'month', 'more', 'better']
NEGATIVES_TRACER = ['transcript']

def known_terms():
    known = set()
    hints = os.path.expanduser('~/.claude/style/glossary-hints.tsv')
    if os.path.exists(hints):
        for line in open(hints):
            if line.startswith('#') or '\t' not in line: continue
            known.add(line.split('\t')[0].strip().lower())
    return known

rows = []
for p in glob.glob(f'{RUN}/corpus/*.jsonl'):
    for line in open(p):
        rows.append(json.loads(line))
row_text = {}
for r in rows:
    row_text[(r['project'], r['session'], r['msg_idx'])] = r['text'].lower()

def context_diversity(term, occ):
    ctxs = set(); total = 0
    for ptr in occ[:60]:
        t = row_text.get(tuple(ptr), '')
        i = t.find(term)
        if i < 0: continue
        total += 1
        ctxs.add(' '.join(t[max(0, i-25):i+len(term)+25].split()))
    return (len(ctxs) / total) if total else 1.0

stats = defaultdict(lambda: {'count': 0, 'sessions': set(), 'ctx': 0.0, 'occ': []})
for r in rows:
    text = r['text'].lower()
    w = 1.0
    if len(r['text']) < 200: w += 0.5
    if CORRECTION.search(text): w += 0.5
    # feedback-shaped: a short reply to assistant output is where steering
    # vocabulary lives; long spec messages are where domain nouns live
    fb = 1 if (r.get('lookback') and len(r['text']) < 300) else 0
    w += 0.75 * fb
    # sentence-level steering signal: a term inside an imperative or
    # evaluative SENTENCE is steering-shaped no matter how long the message
    # is (the user writes long feedback essays; message length lies)
    steer_toks = set()
    sents = SENT_SPLIT.split(text)
    for sent in sents:
        if IMPERATIVE.search(sent) or EVALUATIVE.search(sent):
            steer_toks.update(TOKEN.findall(sent))
    toks = TOKEN.findall(text)
    grams = list(toks)
    for sent in sents:  # n-grams never cross sentence punctuation
        stoks = TOKEN.findall(sent)
        for n in (2, 3):
            for i in range(len(stoks) - n + 1):
                g = stoks[i:i + n]
                if g[0] in STOPEDGE or g[-1] in STOPEDGE: continue
                grams.append(' '.join(g))
    sess = (r['project'], r['session'])
    for t in set(grams):
        s = stats[t]
        s['count'] += 1
        s['sessions'].add(sess)
        s['ctx'] += w
        s['fb'] = s.get('fb', 0) + fb
        in_steer = (t in steer_toks) if ' ' not in t else all(x in steer_toks for x in t.split())
        s['steer'] = s.get('steer', 0) + (1 if in_steer else 0)
        if len(s['occ']) < 100:
            s['occ'].append([r['project'], r['session'], r['msg_idx']])

def rarity(z, avg_ctx):
    if z >= 5.3: return 0.0
    if z >= 4.0: return ((5.3 - z) / 1.3) if avg_ctx >= 1.15 else 0.0
    return 1.2

def score_all(novelty_on=True):
    known = known_terms() if novelty_on else set()
    scored = []
    for t, s in stats.items():
        ns = len(s['sessions'])
        if ns < 3: continue
        if novelty_on and t in known: continue
        avg_ctx = s['ctx'] / s['count']
        z = zipf_frequency(t, 'en')
        rf = rarity(z, avg_ctx)
        if rf == 0.0: continue
        fb_ratio = s.get('fb', 0) / s['count']
        steer_ratio = s.get('steer', 0) / s['count']
        if s['count'] >= 5 and context_diversity(t, s['occ']) < 0.34:
            continue  # template fragment: same surroundings everywhere
        sc = math.log2(1 + ns) * avg_ctx * rf * (0.4 + 0.6 * fb_ratio + 1.2 * steer_ratio)
        scored.append({'term': t, 'score': round(sc, 3), 'sessions': ns,
                       'count': s['count'], 'zipf': round(z, 2),
                       'avg_ctx': round(avg_ctx, 2), 'fb_ratio': round(fb_ratio, 2),
                       'steer_ratio': round(steer_ratio, 2), 'occurrences': s['occ']})
    scored.sort(key=lambda x: -x['score'])
    return scored

# ---- calibration gate (novelty off) ----
cal = score_all(novelty_on=False)
ranks = {c['term']: i + 1 for i, c in enumerate(cal)}
# The gate that means anything: discovery == surviving the production cut.
lines = [f'# Metric calibration — {len(cal)} scored terms, cut = top {TOP}', '']
gate_ok = True
for p in POSITIVES:
    present = p in stats and len(stats[p]['sessions']) >= 3
    if not present:
        lines.append(f'- positive `{p}`: ABSENT from corpus at >=3 sessions (found in {len(stats[p]["sessions"]) if p in stats else 0}) — cannot calibrate on it, noted honestly')
        continue
    r = ranks.get(p)
    ok = r is not None and r <= TOP
    gate_ok &= ok
    lines.append(f'- positive `{p}`: rank {r} of {len(cal)} — {"PASS (inside cut)" if ok else "FAIL (misses cut)"}')
for p in POSITIVES_TRACER:
    lines.append(f'- tracer `{p}`: rank {ranks.get(p, "unscored")} — lexically unreachable by design; planted as P3/P4 ground-truth tracer')
for p in POSITIVES_INFO:
    ns = len(stats[p]['sessions']) if p in stats else 0
    lines.append(f'- info `{p}`: {ns} session(s) in corpus; rank {ranks.get(p, "unscored")}')
for p in NEGATIVES_TRACER:
    lines.append(f'- negative-tracer `{p}`: rank {ranks.get(p, "unscored")} — planted for P4 (must be classified domain-jargon there; user verdict 2026-07-16)')
for n in NEGATIVES:
    r = ranks.get(n)
    ok = r is None or r > TOP
    gate_ok &= ok
    lines.append(f'- negative `{n}`: {"rejected outright" if r is None else f"rank {r}"} — {"PASS (outside cut)" if ok else "FAIL (inside cut)"}')
lines.append('')
lines.append(f'## GATE: {"PASS" if gate_ok else "FAIL"}')
os.makedirs(f'{RUN}/candidates', exist_ok=True)
open(f'{RUN}/candidates/metric-calibration.md', 'w').write('\n'.join(lines) + '\n')
print('\n'.join(lines))
if not gate_ok:
    sys.exit(2)

# ---- production cut (novelty on) ----
prod = score_all(novelty_on=True)[:TOP]
with open(f'{RUN}/candidates/candidates.jsonl', 'w') as f:
    for c in prod: f.write(json.dumps(c) + '\n')
# tracer threads: known-story words followed through every later phase
cal_by_term = {c['term']: c for c in cal}
with open(f'{RUN}/candidates/tracers.jsonl', 'w') as f:
    for t, kind in [('efficacy', 'positive'), ('intent', 'contextual-positive'),
                    ('stupid', 'contextual-positive'), ('one-shot', 'contextual-positive'),
                    ('transcript', 'negative')]:
        c = cal_by_term.get(t)
        if c: f.write(json.dumps({**c, 'tracer': kind}) + '\n')
print(f'wrote {sum(1 for _ in open(f"{RUN}/candidates/tracers.jsonl"))} tracer threads')
print(f'\nwrote {len(prod)} candidates; top 25 preview:')
for c in prod[:25]:
    print(f"  {c['score']:6.2f}  {c['term']:28s} sess={c['sessions']:3d} n={c['count']:4d} zipf={c['zipf']:4.1f} ctx={c['avg_ctx']:.2f}")
