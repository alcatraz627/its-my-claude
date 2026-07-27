#!/usr/bin/env python3
"""Score prose for the account's language-quality defects: two-split structure,
verdict-first reporting, overclaim futures, contrastive scaffolds, and the
thesaurus word bans. Weighted violations per 100 words; lower is cleaner.

Derived from the 2026-07 language-quality sweep (style/sweep/20260727-simple-lang/,
user-ratified taxonomy). Not ste-lint: the lexicons are thesaurus-aligned, dashes
count only in connective form, style-system meta-traffic is excluded, and the
category set is the sweep's, not ASD-STE100's.

Usage:
  prose-lint.py FILE [FILE...]      one summary line per file
  prose-lint.py --json FILE...      full per-file JSON (score, violations, spans)
  cmd | prose-lint.py [-]           lint stdin
Exit 0 always (a linter reports; gates decide elsewhere). Errors name the fix.
"""
import json, os, re, sys

BE = r"(?:am|is|are|was|were|be|been|being)"
PP_IRREG = r"(?:done|made|sent|read|built|kept|held|set|put|run|written|shown|given|taken|found|seen|known)"

# lexicons are thesaurus-aligned (style/thesaurus.jsonl), not STE's list
JARGON = ["leverage","leverages","leveraging","highest-leverage","high-leverage","utilize","utilizes",
    "facilitate","facilitates","delve","delves","comprehensive","comprehensively","crucial","vital",
    "seamless","seamlessly","robust","robustly","holistic","synergy","paradigm","cutting-edge",
    "effortless","world-class","revolutionary","elegant","delightful","turnkey","state-of-the-art",
    "game-changing","battle-tested","enterprise-grade","supercharge","unleash","production-ready"]
FILLER = ["simply","essentially","basically","in order to","a variety of","worth noting",
    "it's important to note","it is important to note","it should be noted","it's worth noting",
    "keep in mind","needless to say","as you can see","at the end of the day"]
HEDGE_ASSERT = ["typically","generally","usually","in most cases","for the most part"]
UNVERIFIED = ["should now work","should work now","should be fixed","that should do it",
    "this should fix","should be working"]
VERDICT_OPENER = re.compile(
    r"^\W*(?:\*\*)?(?:Done|Perfect|Great|Excellent|Awesome|Fantastic|Beautiful|Complete[d]?|"
    r"All (?:done|set|good)|Everything (?:is |works )|Release is live|Shipped)\b", re.I)
META_ID = re.compile(r"\b(?:thes|mist|aff|pin)-\d{8}")
# connective dashes only; digit ranges (L15-L36, 2024-2026) never count
DASH = re.compile(r"\s[—–]\s|(?<=[A-Za-z])[—–](?=[A-Za-z])")
# two high-precision forms only; bare "not X —" catches plain negation (validated 2026-07-27)
CONTRASTIVE = re.compile(r"\bnot\s+[^.;,]{2,40},?\s+but\s+|[—–]\s*it'?s\b", re.I)

WEIGHTS = {"fused_25_35": 1, "fused_35_50": 3, "fused_over_50": 6, "two_split_dash": 1,
           "contrastive_scaffold": 1.5, "verdict_first_opener": 3, "unverified_claim": 4,
           "filler_hedge": 1.5, "hedged_assertion": 1, "jargon_marketing": 2,
           "passive": 1, "nominalization": 1, "semicolon": 0.5}

def _sentences(text):
    out = []
    for line in text.split("\n"):
        s = line.strip()
        if not s: continue
        out += [p.strip() for p in re.split(r"(?<=[.!?:])\s+(?=[A-Z0-9\"'])", s) if p.strip()]
    return out

def _wc(s): return len(re.findall(r"[A-Za-z0-9][A-Za-z0-9'\-/]*", s))

def _count(text, phrases, spans, label):
    low = text.lower(); n = 0
    for ph in phrases:
        for m in re.finditer(r"(?<![a-z])" + re.escape(ph) + r"(?![a-z])", low):
            n += 1
            if len(spans[label]) < 3:
                spans[label].append(text[max(0, m.start()-30):m.end()+30].strip())
    return n

def strip_code(text):
    text = re.sub(r"```.*?```", " ", text, flags=re.S)
    return re.sub(r"`[^`]*`", " CODEREF ", text)

def lint(text):
    """Return (score, violations, spans, words). Score is weighted per-100w."""
    prose = strip_code(text)
    if len(META_ID.findall(prose)) >= 2:
        return {"skipped": "style-system meta-traffic (rule-ID density)", "score": 0.0}
    sents = _sentences(prose)
    words = sum(_wc(s) for s in sents) or 1
    v, spans = {}, {k: [] for k in WEIGHTS}
    lens = [(w, s) for s in sents for w in [_wc(s)]]
    for lo, hi, key in ((25, 35, "fused_25_35"), (35, 50, "fused_35_50"), (50, 10**6, "fused_over_50")):
        hit = [(w, s) for w, s in lens if lo < w <= hi]
        v[key] = len(hit)
        spans[key] = [s[:100] for _, s in hit[:3]]
    v["two_split_dash"] = len(DASH.findall(prose))
    v["contrastive_scaffold"] = len(CONTRASTIVE.findall(prose))
    for m in CONTRASTIVE.finditer(prose):
        if len(spans["contrastive_scaffold"]) < 3:
            spans["contrastive_scaffold"].append(prose[max(0, m.start()-20):m.end()+30].strip())
    first = sents[0] if sents else ""
    v["verdict_first_opener"] = 1 if VERDICT_OPENER.match(first) else 0
    if v["verdict_first_opener"]: spans["verdict_first_opener"] = [first[:100]]
    v["unverified_claim"] = _count(prose, UNVERIFIED, spans, "unverified_claim")
    v["filler_hedge"] = _count(prose, FILLER, spans, "filler_hedge")
    v["hedged_assertion"] = _count(prose, HEDGE_ASSERT, spans, "hedged_assertion")
    v["jargon_marketing"] = _count(prose, JARGON, spans, "jargon_marketing")
    v["passive"] = len(re.findall(rf"\b{BE}\s+(?:\w+ed|{PP_IRREG})\b", prose, re.I))
    v["nominalization"] = len(re.findall(r"\b(?:perform(?:s|ed)?|conduct(?:s|ed)?|carry out|carries out|make use of)\b", prose, re.I)) \
                        + len(re.findall(r"\b\w{4,}(?:tion|ment|ance|ence)\s+of\b", prose, re.I))
    v["semicolon"] = prose.count(";")
    weighted = sum(WEIGHTS[k] * n for k, n in v.items())
    score = weighted * 100.0 / words
    if words < 60:
        score *= words / 60.0
    return {"score": round(score, 2), "words": words,
            "violations": {k: n for k, n in v.items() if n},
            "spans": {k: s for k, s in spans.items() if s}}

def main(argv):
    as_json = "--json" in argv
    files = [a for a in argv if a not in ("--json", "-")]
    if not files:
        r = lint(sys.stdin.read())
        print(json.dumps(r, indent=2) if as_json else f"stdin  score={r['score']}  " + " ".join(f"{k}={n}" for k, n in r.get("violations", {}).items()))
        return 0
    for f in files:
        if not os.path.exists(f):
            print(f"{f}: not found — check the path, or pipe content via stdin (cmd | prose-lint.py)")
            continue
        r = lint(open(f, errors="replace").read())
        if as_json:
            print(json.dumps({"file": f, **r}, indent=2))
        elif "skipped" in r:
            print(f"{os.path.basename(f):32} skipped ({r['skipped']})")
        else:
            top = sorted(r["violations"].items(), key=lambda kv: -WEIGHTS[kv[0]] * kv[1])[:3]
            print(f"{os.path.basename(f):32} score={r['score']:6.2f} words={r['words']:5d}  worst: " +
                  (", ".join(f"{k} x{n}" for k, n in top) or "clean"))
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
