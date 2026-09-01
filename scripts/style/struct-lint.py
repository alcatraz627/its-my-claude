#!/usr/bin/env python3
"""Measure the structural defects prose-lint.py cannot see.

prose-lint scores words and sentences. The owner's objection is about the
document's skeleton: section titles that name a process step instead of the
thing a reader is looking for, table headers written as clauses, and metaphors
used as if they were defined terms.

Lexicons are mined, not invented. Sources:
  house terms   GLOSSARY.md Concepts + User Shorthand
  process terms the ## Phase headings of the nine doc-producing skills
  metaphors     terms used as nouns for technical objects across those skills
"""
import os, json, re, sys, collections, os

HOUSE = {"facet","surface","surfaces","harness","runtime note","checkpoint","core dump",
    "proposal","slug","gcc","efficacy","one-shotting","sweep","sprawl","smell","epic",
    "deliberate","overindex","triad","atone","affirm","pin","juror","warden","lane","lanes",
    "seat","seats","band","bands","canon","ledger","ledgers","residue","cadence"}

PROCESS = {"refuse condition","refuse conditions","parity ledger","inheritance ledger",
    "directive","directives","skeleton","embryo","running slice","first running slice",
    "loading law","falsifiably","ruling","rulings","gate","gates","triple","triples",
    "class and refuse","must not touch","speculative appendix","done-condition",
    "scope close","dispositions","standing constraints","refuse","emit the plan"}

METAPHOR = {"altitude","altitudes","embryo","organ","organs","ladder","rung","rungs",
    "costume","blast radius","north star","spine","fabric","plumbing","rails","surface area",
    "front door","organism","bloodstream","muscle","skeleton","anatomy","choreography"}

ALL = {t: k for k, s in (("house",HOUSE),("process",PROCESS),("metaphor",METAPHOR)) for t in s}
TERM_RE = re.compile(r"\b(" + "|".join(sorted((re.escape(t) for t in ALL), key=len, reverse=True)) + r")\b", re.I)

# A table header should name the data in the column. These shapes do not.
CLAUSE_HDR = re.compile(r"\b(that|which|who|when|if)\b|^(must|should|can|will|does|is|are|has)\b", re.I)
VERBY_HDR  = re.compile(r"^(check|adopt|deviate|fix|keep|drop|park|prove|flips?|holds?)\b", re.I)

H = re.compile(r"^(#{1,4})\s+(.+?)\s*$")
FENCE = re.compile(r"^\s*```")

def analyse(path):
    try: txt = open(path, errors="replace").read()
    except OSError: return None
    lines, infence = txt.split("\n"), False
    heads, thdrs = [], []
    for i, line in enumerate(lines):
        if FENCE.match(line): infence = not infence; continue
        if infence: continue
        m = H.match(line)
        if m: heads.append(m.group(2).strip("*_` "))
        if line.lstrip().startswith("|") and i + 1 < len(lines) and re.match(r"^\s*\|[\s:|-]+\|\s*$", lines[i+1]):
            thdrs += [c.strip().strip("*_` ") for c in line.strip().strip("|").split("|") if c.strip()]
    if not heads and not thdrs: return None
    hits = collections.Counter()
    bad_heads, bad_hdrs = [], []
    for h in heads:
        found = {ALL[m.group(1).lower()] for m in TERM_RE.finditer(h)}
        if found:
            hits.update(found); bad_heads.append(h)
    for t in thdrs:
        if CLAUSE_HDR.search(t) or VERBY_HDR.match(t) or len(t.split()) > 4:
            bad_hdrs.append(t)
    return {"headings": len(heads), "table_headers": len(thdrs),
            "jargon_headings": len(bad_heads), "clause_headers": len(bad_hdrs),
            "by_kind": dict(hits), "worst_heads": bad_heads[:6], "worst_hdrs": bad_hdrs[:6]}

def main():
    rows = [json.loads(l) for l in open(os.environ.get("DOCCORPUS", "/Users/alcatraz627/.claude/assets/reports/20260831-doc-prose-causes/corpus.jsonl"))]
    rows = [r for r in rows if r["mtime"] >= "2026-07-28"]
    agg = collections.defaultdict(lambda: collections.Counter())
    out = []
    for r in rows:
        a = analyse(r["path"])
        if not a: continue
        grp = "repo-visible" if r["dest"].startswith("repo") else "agent-only"
        agg[grp]["files"] += 1
        for k in ("headings","table_headers","jargon_headings","clause_headers"):
            agg[grp][k] += a[k]
        for k, v in a["by_kind"].items(): agg[grp]["kind:"+k] += v
        out.append({**r, **a})
    json.dump(out, open("/Users/alcatraz627/.claude/assets/reports/20260831-doc-prose-causes/struct.json","w"))

    print(f"{'group':14s} {'files':>6s} {'heads':>7s} {'jargon':>7s} {'%':>6s} {'thdrs':>7s} {'clause':>7s} {'%':>6s}")
    for g in ("repo-visible","agent-only"):
        c = agg[g]
        jp = 100*c['jargon_headings']/max(c['headings'],1)
        cp = 100*c['clause_headers']/max(c['table_headers'],1)
        print(f"{g:14s} {c['files']:6d} {c['headings']:7d} {c['jargon_headings']:7d} {jp:5.1f}% {c['table_headers']:7d} {c['clause_headers']:7d} {cp:5.1f}%")
        print(f"{'':14s}   by kind: " + ", ".join(f"{k[5:]}={v}" for k,v in sorted(c.items()) if k.startswith("kind:")))
    print()
    worst = sorted(out, key=lambda r: -(r["jargon_headings"]+r["clause_headers"]))[:12]
    print("=== worst files by structural defect count ===")
    for r in worst:
        print(f"  jargon={r['jargon_headings']:3d} clause={r['clause_headers']:3d}  [{r['dest']}] {r['path'].replace('/Users/alcatraz627/','~/')}")
main()
