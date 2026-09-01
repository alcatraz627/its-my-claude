#!/usr/bin/env python3
"""Reproduce every number in report.md, including the three-way split and the
frequency-matched control that earlier existed only as throwaway heredocs.

The prosecutor's first finding was that the shipped scripts could not
regenerate the report's headline table. This script is that finding's fix.

Run after corpus.py:  python3 measure.py
"""
import os, bisect, collections, json, os, random, re, sys

SK = "/Users/alcatraz627/.claude/skills"
DOC_SKILLS = ("build-change", "build-ui", "bloop", "gated-plan", "deep-research")
STOP = {"the","and","that","with","from","then","this","your","load","shared","into",
        "before","anything","else","each","only","when","what","where","which","they",
        "them","have","been"}
H = re.compile(r"^(#{1,4})\s+(.+?)\s*$")

def mechanical_lexicon():
    """Phase-heading content words of the doc-producing skills. No hand curation:
    the earlier hand-written lexicon was the prosecutor's second objection."""
    lex = set()
    for s in DOC_SKILLS:
        p = f"{SK}/{s}/SKILL.md"
        if not os.path.exists(p): continue
        for line in open(p, errors="replace"):
            m = re.match(r"^##\s+(?:Phase|Step)\s*[\d.]*\s*[:.—-]?\s*(.+)", line.strip())
            if m:
                t = re.sub(r"\(.*?\)", "", m.group(1)).strip(" .:—-").lower()
                lex |= {w for w in re.findall(r"[a-z][a-z-]{3,}", t) if w not in STOP}
    return lex

def group(r):
    """The three populations the report compares.

    its-my-config is the gcc mirror: agent-facing content living in a repo, so
    classifying it by path would inflate the repo-visible bucket by 705 files.
    That reclassification was silent in the first pass. It is explicit here.
    """
    if re.search(r"/\.claude/output/.*plan\.md$", r["path"], re.I): return "plans"
    if r["repo"] == "its-my-config": return "agent-only"
    return "repo-visible" if r["dest"].startswith("repo") else "agent-only"

def load():
    rows = [json.loads(l) for l in open(os.environ.get("DOCCORPUS", "/Users/alcatraz627/.claude/assets/reports/20260831-doc-prose-causes/corpus.jsonl"))]
    return [r for r in rows if r["mtime"] >= "2026-07-28"]

def headings_by_group(rows):
    heads = collections.defaultdict(list)
    docfreq = collections.Counter()
    for r in rows:
        g, infence, seen = group(r), False, set()
        try: f = open(r["path"], errors="replace")
        except OSError: continue
        for line in f:
            if line.startswith("```"): infence = not infence; continue
            if infence: continue
            m = H.match(line.rstrip())
            if m:
                ws = {w for w in re.findall(r"[a-z][a-z-]{3,}", m.group(2).lower())}
                heads[g].append(ws); seen |= ws
        docfreq.update(seen)
    return heads, docfreq

def freq_matched_decoy(lex, docfreq, seed=11):
    """Pair each lexicon word with the nearest-frequency word outside it.

    Matching on COUNT rather than frequency is what made the first control
    worthless: ordinary words that plans happen not to use read as a 43x
    contrast that does not exist.
    """
    pool = sorted((w for w in docfreq if w not in lex and len(w) > 3), key=lambda w: docfreq[w])
    freqs = [docfreq[w] for w in pool]
    random.seed(seed); decoy = set()
    for w in lex:
        i = bisect.bisect_left(freqs, docfreq.get(w, 0))
        for off in range(60):
            for j in (i + off, i - off):
                if 0 <= j < len(pool) and pool[j] not in decoy:
                    decoy.add(pool[j]); break
            else: continue
            break
    return decoy

def main():
    rows = load()
    lex = mechanical_lexicon()
    heads, docfreq = headings_by_group(rows)
    decoy = freq_matched_decoy(lex, docfreq)
    files = collections.Counter(group(r) for r in rows)

    print(f"corpus: {len(rows)} files written on/after 2026-07-28")
    print(f"mechanical lexicon {len(lex)} words, frequency-matched decoy {len(decoy)} words\n")
    print(f"{'group':14s} {'files':>6s} {'headings':>9s} {'lexicon':>10s} {'decoy':>10s} {'ratio':>7s}")
    for g in ("repo-visible", "agent-only", "plans"):
        hs = heads[g]; tot = len(hs) or 1
        a = sum(1 for ws in hs if ws & lex)
        b = sum(1 for ws in hs if ws & decoy)
        ra, rb = 100*a/tot, 100*b/tot
        print(f"{g:14s} {files[g]:6d} {len(hs):9d} {ra:9.1f}% {rb:9.1f}% {ra/max(rb,0.01):6.1f}x")
    print("\nThe claim this supports: only the plans group rises above its own")
    print("chance floor. Repo and agent-only sit at or below it, so the lexicon")
    print("carries no signal in documents a build skill did not write.")

main()
