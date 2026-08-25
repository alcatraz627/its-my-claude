#!/usr/bin/env python3
"""Audit how well a board is actually used, against the rubric in the header.

Written 2026-08-25 BEFORE the trial agent's board was read, so the checks are
not shaped to what it happened to do. Point it at any board:

    python3 test/board-usage-audit.py <board-slug> [--exclude-tag showcase]

It reports facts, not grades. A low number is not automatically a fault: a
project with no real dependencies SHOULD have no `after` chains, and saying so
is the auditor's job rather than the reader's.
"""
import json, sys, urllib.request
from collections import Counter

BASE = "http://localhost:5106"
SCANNABLE = 56          # the char bar a card title is meant to sit under
LANE_ORDER = ["inbox", "backlog", "active", "blocked", "done", "stale"]


def get(path):
    with urllib.request.urlopen(BASE + path) as r:
        return json.load(r)


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: board-usage-audit.py <board-slug> [--exclude-tag <name>]")
    slug = sys.argv[1]
    excl = sys.argv[sys.argv.index("--exclude-tag") + 1] if "--exclude-tag" in sys.argv else None

    d = get(f"/api/board?slug={slug}")
    board = d.get("board") or {}
    cards = d.get("cards") or board.get("cards") or []
    plan = d.get("plan") or {}
    notes = d.get("notes") or {}

    tags = {t["id"]: t for t in plan.get("tags", [])}
    on = plan.get("on", {})
    if excl:
        drop = {tid for tid, t in tags.items() if t.get("name") == excl}
        cards = [c for c in cards if not (set(on.get(c["id"], [])) & drop)]

    ids = {c["id"] for c in cards}
    say = print
    say(f"\n=== board-usage audit · {slug} · {len(cards)} cards"
        + (f" (excluding tag:{excl})" if excl else "") + " ===\n")

    # 1 titles
    longs = [c for c in cards if len(c.get("title", "")) > SCANNABLE]
    briefed = [c for c in cards if c.get("titleBrief")]
    say(f"1. TITLES     {len(longs)}/{len(cards)} over {SCANNABLE} chars · {len(briefed)} carry a brief")
    if longs and not briefed:
        say(f"   -> nothing is briefed, so every long title is read in full on the face")
    for c in longs[:3]:
        say(f"   long ({len(c['title'])}): {c['title'][:70]}")

    # 2 tags
    # count only the cards still in scope: iterating every `on` entry reported
    # 39-card totals under a 25-card heading when --exclude-tag was used
    kinds = Counter(tags[t]["kind"] for c in cards for t in on.get(c["id"], []) if t in tags)
    vocab_in_use = {t for c in cards for t in on.get(c["id"], []) if t in tags}
    per_card = [len(on.get(c["id"], [])) for c in cards]
    tagged = sum(1 for n in per_card if n)
    say(f"\n2. TAGS       {len(vocab_in_use)} in use on these cards ({len(tags)} in the board vocabulary) · {tagged}/{len(cards)} cards tagged"
        f" · busiest card has {max(per_card) if per_card else 0}")
    say(f"   kinds used: {dict(kinds) or 'none'}")
    unused = {"milestone", "tier", "effort", "area", "risk", "priority", "class"} - set(kinds)
    if unused:
        say(f"   kinds never used: {sorted(unused)}")

    # 3 goals
    goals = plan.get("goals", {})
    mine = {k: v for k, v in goals.items() if k in ids}
    say(f"\n3. GOALS      {len(mine)}/{len(cards)} cards carry one")
    for k, v in list(mine.items())[:2]:
        title = next((c["title"] for c in cards if c["id"] == k), "?")
        echo = v.strip().lower() in title.strip().lower()
        say(f"   {'RESTATES THE TITLE' if echo else 'adds a reason'}: {v[:64]}")

    # 4 milestones
    ms = [t["name"] for t in tags.values() if t.get("kind") == "milestone"]
    counts = {m: sum(1 for c in cards
                     if any(tags.get(t, {}).get("name") == m for t in on.get(c["id"], [])))
              for m in ms}
    say(f"\n4. MILESTONES {len(ms)}: {counts or 'none'}")
    if ms:
        covered = sum(counts.values())
        say(f"   {covered}/{len(cards)} cards sit under one"
            + ("" if covered >= len(cards) else " -> the rest are unplaced"))

    # 5 sequencing
    seq = {k: v for k, v in plan.get("seq", {}).items() if k in ids}
    say(f"\n5. AFTER      {len(seq)} card(s) declare a predecessor")

    # 6 verify
    ver = [c for c in cards if c.get("verify")]
    grades = Counter(c["verify"].get("grade") for c in ver if c["verify"].get("grade"))
    human = sum(1 for c in ver if c["verify"].get("needsHuman"))
    say(f"\n6. VERIFY     {len(ver)}/{len(cards)} graded {dict(grades) or ''} · {human} need a human")

    # 7 docs
    linked = [c for c in cards if c.get("docs")]
    say(f"\n7. DOCS       {len(linked)}/{len(cards)} cards link a document")

    # 8 lanes
    lanes = Counter(c.get("lane") for c in cards)
    say(f"\n8. LANES      {{{', '.join(f'{l}:{lanes.get(l,0)}' for l in LANE_ORDER)}}}")
    if lanes and max(lanes.values()) > len(cards) * 0.8:
        say(f"   -> {max(lanes, key=lanes.get)} holds over 80%, so the lanes are not saying much yet")

    # 9 notes
    n_cards = sum(1 for cid in notes if cid in ids)
    say(f"\n9. NOTES      {n_cards} card(s) carry a note")

    # 10 plan churn — a board that shows only the original plan lied
    say(f"\n10. CHURN     done:{lanes.get('done',0)} stale:{lanes.get('stale',0)}"
        f" blocked:{lanes.get('blocked',0)}")
    say("   (compare against plan-changes.md by hand: a cut item should be visible)")

    # 11 decisions / 12 views
    say(f"\n11. DECISIONS {len(plan.get('decisions', []))} recorded")
    say(f"12. VIEWS     {len(plan.get('views', []))} named")
    say("")


if __name__ == "__main__":
    main()
