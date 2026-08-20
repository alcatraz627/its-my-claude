#!/usr/bin/env python3
"""The deck's lightweight prose gate: enough to catch offending slides, never a review.

Owner, 2026-08-18: "I don't want a heavy review, just enough to catch offending
issues." So this is a fixed list of mechanical checks over DECK.md, each one a
thing all three source decks or the account's prose taxonomy named as a defect,
and nothing else. It prints one line per finding with the slide number, and a
count. The SKILL codifies the loop around it: if the first run finds more than two
issues, the agent fixes, re-runs, and fixes again until clean or justified.

Checks (slide-scoped):
  em-dash        an em-dash anywhere (house rule; also conventions/language-quality.md)
  claims         more than one top-level claim on a claim slide: a paragraph AND a
                 list, or two paragraphs, on a slide with no table/diagram/cards
  bullets        more than 6 bullets on one slide, or a bullet over 140 characters
  words          more than 90 words of body prose on one slide (a notes line wearing
                 a slide costume, per automation)
  adjectives     a number-shaped claim without a number: many / significant / huge /
                 dramatically / massive / robust / seamless (numbers, not adjectives)
  hedge-triad    a rule-of-three adjective list ("fast, simple, and reliable")
  notes-voice    presenter notes that are fragments (no verb-ish word) or bullet lists;
                 notes are full sentences the speaker reads
  ste            sentences over 25 words on a slide (STE-writing's one hard limit)
  unsourced      a slide with a % or a large number and no source word (per, from,
                 measured, source, n=, of N) anywhere on the slide or in its notes

Exit 0 when clean, 1 when findings; --json for machines.
"""
import json, re, sys

WEASEL = re.compile(r"\b(many|significant(ly)?|huge|dramatic(ally)?|massive(ly)?|robust|seamless(ly)?|numerous|substantial(ly)?|countless)\b", re.I)
TRIAD = re.compile(r"\b\w+, \w+,? and \w+\b")
NUMBER = re.compile(r"(\d+(\.\d+)?%|\b\d{3,}\b|\b\d+\s*(ms|s|x|k|kb|mb|gb|days?|hours?|min))", re.I)
SOURCE = re.compile(r"\b(per|from|measured|source|sources|n\s*=|of \d+|according to|ledger|transcript|test(s)?|suite|log)\b", re.I)

def slides_of(src):
    out, cur = [], None
    for ln in src.splitlines():
        if ln.startswith("# ") or ln.startswith("## "):
            cur = {"title": ln.lstrip("# ").strip(), "lines": [], "notes": []}; out.append(cur); continue
        if cur is None: cur = {"title": "(preamble)", "lines": [], "notes": []}; out.append(cur)
        if ln.startswith("> notes:"): cur["notes"].append(ln[8:].strip()); continue
        if ln.startswith(">") and cur["notes"]: cur["notes"][-1] += " " + ln[1:].strip(); continue
        cur["lines"].append(ln)
    return out

def body_text(lines):
    """Prose only: drop directives, fences, tables, and the insides of ::: blocks."""
    out, fence, block = [], False, False
    for ln in lines:
        if ln.startswith("```"): fence = not fence; continue
        if fence: continue
        if ln.startswith(":::"):
            if ln.strip() == ":::": block = False
            elif re.match(r":::(cards|cols|callout)\b", ln) and not (ln.startswith(":::callout") and len(ln.split(None, 2)) > 2): block = True
            continue
        if block or ln.startswith("|") or ln.startswith(("kicker:", "sub:", "leave:")): continue
        out.append(re.sub(r"^\s*([-*]|\d+\.) ", "", ln))
    return out

def lint(src):
    findings = []
    for n, s in enumerate(slides_of(src), 1):
        L = s["lines"]; prose = [x for x in body_text(L) if x.strip()]
        text = re.sub(r"`[^`]*`", " ", " ".join(prose)); notes = " ".join(s["notes"])   # a word in backticks is a specimen, not a use
        def f(kind, msg): findings.append({"slide": n, "title": s["title"], "kind": kind, "msg": msg})
        if "—" in "\n".join(L) or "—" in notes: f("em-dash", "em-dash present; use a comma, a period, or 'and'")
        bullets = [x for x in L if re.match(r"^\s*([-*]|\d+\.) ", x)]
        if len(bullets) > 6: f("bullets", f"{len(bullets)} bullets; six is the ceiling, split the slide")
        for b in bullets:
            if len(b) > 140: f("bullets", f"bullet over 140 chars: '{b[:50]}…'")
        words = len(text.split())
        if words > 90: f("words", f"{words} words of prose; a slide carries one claim, the rest is notes")
        has_struct = any(x.startswith(("|", "```", ":::cards", ":::cols")) for x in L)
        paras = [x for x in prose if x not in [re.sub(r"^\s*([-*]|\d+\.) ", "", b) for b in bullets]]
        if not has_struct and n > 1 and ((len(paras) >= 2 and len(bullets) == 0) or (len(paras) >= 1 and len(bullets) > 0 and words > 60)):
            f("claims", "reads as more than one claim (paragraphs plus a list, or two paragraphs); one claim per slide")
        for m in WEASEL.finditer(text): f("adjectives", f"'{m.group(0)}' is an adjective where a number belongs")
        for m in TRIAD.finditer(text):
            if len(m.group(0).split()) <= 5: f("hedge-triad", f"rule-of-three list '{m.group(0)}'; say the one that matters")
        for sent in re.split(r"(?<=[.!?])\s+", text):
            if len(sent.split()) > 25: f("ste", f"sentence over 25 words: '{sent[:60]}…'")
        for note in s["notes"]:
            if note.startswith(("-", "*")) or (len(note.split()) < 4 and note): f("notes-voice", f"notes should be full sentences the speaker reads: '{note[:50]}'")
        allt = "\n".join(L) + " " + notes
        # dates, clock times, paths, urls and code spans are not numeric claims
        nums = "\n".join(x for x in L if not x.startswith(("```", ":::open")))
        nums = re.sub(r"`[^`]*`|\S*/\S+|\b\d{4}-\d{2}-\d{2}\b|\b\d{1,2}:\d{2}\b|#\d+", "", nums)
        if NUMBER.search(nums) and not SOURCE.search(allt): f("unsourced", "a number with no source word on the slide or in its notes (per / from / measured / n= / test)")
    return findings

def main(argv):
    if len(argv) < 2: print(__doc__); return 2
    as_json = "--json" in argv; path = [a for a in argv[1:] if not a.startswith("--")][0]
    src = open(path, encoding="utf-8").read(); fs = lint(src)
    if as_json: print(json.dumps({"file": path, "count": len(fs), "findings": fs}, indent=2))
    else:
        for x in fs: print(f"  slide {x['slide']:>2} [{x['kind']}] {x['title'][:30]}: {x['msg']}")
        print(f"deck-lint: {len(fs)} finding(s) in {path}" + ("" if fs else "  (clean)"))
    return 1 if fs else 0

if __name__ == "__main__": sys.exit(main(sys.argv))
