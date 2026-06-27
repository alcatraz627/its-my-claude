#!/usr/bin/env python3
"""backlog-consolidate.py — merge the gcc improvement backlog into one ranked, triaged file.

The improvement signals already converge on the proposal store: the /core-dump and
/catchup contribution phases file cross-linked proposals, gcc-signal-capture auto-stubs
on strong friction, atone-consolidate drafts prevention proposals, and the human files
directly. What was missing is a step that READS that store, clusters items by their
shared provenance, ranks them, and decides which are actually worth acting on — so the
backlog stops being a write-only graveyard.

This is that step. It:
  - reads the canonical store (proposals.jsonl; override with PROPOSE_STORE),
  - clusters OPEN items by shared `link:*` provenance (connected components),
  - enriches atone-linked items with severity / recurrence from atone's derived triggers,
  - applies the anti-churn triage gate (below),
  - writes ONE ranked, human-facing file: ~/.claude/topics/backlog-triage-YYYY-MM-DD.md.

It NEVER mutates the store and NEVER auto-applies. The human PROMOTE/DROP decision (via
/backlog-triage -> propose.sh done|reject) is the only thing that changes state.

The anti-churn triage gate — an item is PROMOTE-worthy iff ANY of:
  - corroboration >= 2 (two independent streams point at the same idea), OR
  - a linked atone slug is severity S3, OR
  - a linked atone slug has recurrence >= 3, OR
  - it is a human contribution (src:session-contrib / src:post-catchup) with effort <= medium.
Everything else -> WATCH (visible, still accruing corroboration, not presented as actionable).
Open > STALE_DAYS with corroboration < 2 and no S3 -> DROP-REVIEW (graveyard cleanup).
A single weak signal is, by the user's own right-sized-code / speculative-abstractions
rules, not yet actionable — it waits for a second stream. That bar IS the anti-churn lever.

Scope note: corroboration is computed from the link:* tags already on each proposal
(provenance travels with the item), so this does not re-scan the raw dream/valence/metacog
pools — those enter the backlog via the contribution/auto-stub link tags. Wiring them as
direct feeders is a later enhancement, intentionally deferred to avoid churn.

Usage: backlog-consolidate.py [--force] [--read-only] [--stale-days N] [--help]
  --force       ignore the weekly idempotency guard
  --read-only   compute and print the summary, write nothing
  Idempotency: skips if it ran < 6 days ago (weekly cadence) unless --force.
"""
import json
import os
import sys
import hashlib
import datetime
from collections import defaultdict

HOME = os.path.expanduser("~")
GCC = os.path.join(HOME, ".claude")
STORE = os.environ.get("PROPOSE_STORE", os.path.join(GCC, "proposals.jsonl"))
TRIGGERS = os.path.join(GCC, "atone", "derived", "triggers.json")
TOPICS = os.path.join(GCC, "topics")
MARKER = os.path.join(GCC, ".backlog-consolidate-last-run")
SIDECAR = os.path.join(GCC, ".backlog-triage-latest.json")
WEEKLY_SECONDS = 6 * 24 * 3600
DEFAULT_STALE_DAYS = 45

HUMAN_SRCS = {"src:session-contrib", "src:post-catchup"}


def now_utc():
    # new datetime() is fine in a standalone script (this is not a workflow).
    return datetime.datetime.now(datetime.timezone.utc)


def parse_cli(argv):
    opts = {"force": False, "read_only": False, "stale_days": DEFAULT_STALE_DAYS}
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--force":
            opts["force"] = True
        elif a == "--read-only":
            opts["read_only"] = True
        elif a == "--stale-days":
            opts["stale_days"] = int(argv[i + 1]); i += 1
        elif a in ("--help", "-h"):
            print(__doc__)
            sys.exit(0)
        else:
            print(f"backlog-consolidate: unknown arg {a}", file=sys.stderr)
            sys.exit(2)
        i += 1
    return opts


def load_open_proposals():
    items = []
    if not os.path.exists(STORE):
        return items
    with open(STORE, encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                o = json.loads(line)
            except json.JSONDecodeError:
                continue
            if o.get("status", "open") == "open":
                items.append(o)
    return items


def load_atone_triggers():
    """slug -> {severity_band, count(recurrence)} from atone's derived triggers."""
    out = {}
    if not os.path.exists(TRIGGERS):
        return out
    try:
        with open(TRIGGERS, encoding="utf-8", errors="replace") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError):
        return out
    for t in data:
        slug = t.get("from_slug")
        if slug:
            out[slug] = {
                "severity": t.get("severity_band", ""),
                "count": t.get("count", 0) or 0,
            }
    return out


def link_targets(item):
    """The set of `link:<stream>:<id>` tags on a proposal (provenance edges)."""
    return {t for t in item.get("tags", []) if t.startswith("link:")}


def link_types(item):
    """Distinct residue-SYSTEM types this item links to: {atone, dream, valence, prop, ...}.

    This is the corroboration signal: linking to two DIFFERENT systems means two
    independent residue streams flagged the same idea. An item's own `src:` tag is
    NOT corroboration — it only says who filed it (the auto-stub fires *because of*
    the atone link, so counting both would double-count one signal)."""
    types = set()
    for t in item.get("tags", []):
        if t.startswith("link:"):
            parts = t.split(":")
            if len(parts) >= 2 and parts[1]:
                types.add(parts[1])
    return types


def provenance(item):
    """All provenance tags for DISPLAY only (src + link types) — not corroboration."""
    out = set()
    for t in item.get("tags", []):
        if t.startswith("link:"):
            parts = t.split(":")
            if len(parts) >= 2 and parts[1]:
                out.add("link:" + parts[1])
        elif t.startswith("src:"):
            out.add(t)
    return out


def cluster(items):
    """Connected components over shared link targets. Returns list of lists of items."""
    parent = list(range(len(items)))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb

    target_to_idx = defaultdict(list)
    for i, it in enumerate(items):
        for tgt in link_targets(it):
            target_to_idx[tgt].append(i)
    for idxs in target_to_idx.values():
        for j in range(1, len(idxs)):
            union(idxs[0], idxs[j])

    groups = defaultdict(list)
    for i in range(len(items)):
        groups[find(i)].append(items[i])
    return list(groups.values())


def age_days(item):
    ts = item.get("ts", "")
    try:
        t = datetime.datetime.fromisoformat(ts.replace("Z", "+00:00"))
        return (now_utc() - t).days
    except (ValueError, AttributeError):
        return 0


def effort_rank(e):
    return {"small": 0, "medium": 1, "large": 2}.get(e, 1)


def bucket_order(b):
    return {"PROMOTE": 2, "WATCH": 1, "DROP-REVIEW": 0}.get(b, 0)


def assess(items, triggers, stale_days):
    """Return ranked list of triage rows with bucket PROMOTE / WATCH / DROP-REVIEW."""
    rows = []
    for grp in cluster(items):
        types = set()       # distinct residue-system types across the cluster
        prov = set()        # display-only provenance (src + link types)
        atone_severity = ""
        atone_recurrence = 0
        for it in grp:
            types |= link_types(it)
            prov |= provenance(it)
            for t in link_targets(it):
                if t.startswith("link:atone:"):
                    slug = t.split(":", 2)[2] if t.count(":") >= 2 else ""
                    info = triggers.get(slug)
                    if info:
                        if info["severity"] == "S3":
                            atone_severity = "S3"
                        atone_recurrence = max(atone_recurrence, info["count"])
        # Corroboration = independent agreement: multiple proposals clustering on
        # the same residue (len(grp)), OR one item linking >=2 distinct residue
        # systems (len(types)). A lone item linking one system is corroboration 1.
        corroboration = max(len(grp), len(types))
        rep = sorted(grp, key=lambda x: (effort_rank(x.get("effort", "medium")), -age_days(x)))[0]
        human = bool(HUMAN_SRCS & {t for t in rep.get("tags", []) if t.startswith("src:")})
        oldest_age = max(age_days(it) for it in grp)

        promote = (
            corroboration >= 2
            or atone_severity == "S3"
            or atone_recurrence >= 3
            or (human and rep.get("effort", "medium") in ("small", "medium"))
        )
        if promote:
            bucket = "PROMOTE"
        elif oldest_age > stale_days and corroboration < 2 and atone_severity != "S3":
            bucket = "DROP-REVIEW"
        else:
            bucket = "WATCH"

        value = (
            corroboration * 10
            + (20 if atone_severity == "S3" else 0)
            + atone_recurrence * 3
            + min(oldest_age, 60) * 0.1
        )
        rows.append({
            "bucket": bucket,
            "value": round(value, 1),
            "corroboration": corroboration,
            "streams": sorted(prov),
            "atone_severity": atone_severity,
            "atone_recurrence": atone_recurrence,
            "effort": rep.get("effort", "medium"),
            "age": oldest_age,
            "ids": [it.get("id", "?") for it in grp],
            "title": rep.get("title", "(no title)"),
            "category": rep.get("category", "other"),
            "links": sorted({t for it in grp for t in link_targets(it)}),
        })
    rows.sort(key=lambda r: (-bucket_order(r["bucket"]), -r["value"]))
    return rows


def render(rows, stale_days):
    today = now_utc().strftime("%Y-%m-%d")
    by = defaultdict(list)
    for r in rows:
        by[r["bucket"]].append(r)
    out = []
    out.append(f"# Backlog triage — {today}")
    out.append("")
    out.append(
        "Derived view of the open improvement backlog (`proposals.jsonl`), clustered by "
        "shared provenance and ranked. This file never changes state — act on items via "
        "`/backlog-triage` (or `propose.sh done|reject`). Regenerated weekly by "
        "`backlog-consolidate.py`."
    )
    out.append("")
    out.append(
        f"PROMOTE {len(by['PROMOTE'])} · WATCH {len(by['WATCH'])} · "
        f"DROP-REVIEW {len(by['DROP-REVIEW'])}  (total clusters: {len(rows)})"
    )
    out.append("")

    sections = [
        ("PROMOTE", "PROMOTE candidates", "Corroborated or proven-severe — worth acting on now."),
        ("WATCH", "Watch", "A single weak signal so far; waiting for a second stream to corroborate."),
        ("DROP-REVIEW", "Drop review", f"Open > {stale_days}d with no corroboration — candidates to reject."),
    ]
    for key, head, blurb in sections:
        items = by[key]
        out.append(f"## {head} ({len(items)})")
        out.append("")
        out.append(f"_{blurb}_")
        out.append("")
        if not items:
            out.append("(none)")
            out.append("")
            continue
        for r in items:
            sev = f" · atone:{r['atone_severity']}" if r["atone_severity"] else ""
            rec = f" · recurrence×{r['atone_recurrence']}" if r["atone_recurrence"] else ""
            out.append(
                f"- **{r['title']}**  "
                f"`[{r['category']}/{r['effort']}]`  "
                f"value={r['value']} · corroboration={r['corroboration']}{sev}{rec} · age={r['age']}d"
            )
            out.append(
                f"    - ids: {', '.join(r['ids'])}"
                + (f" · streams: {', '.join(r['streams'])}" if r["streams"] else "")
            )
            if r["links"]:
                out.append(f"    - links: {', '.join(r['links'])}")
        out.append("")
    return "\n".join(out) + "\n"


def main():
    opts = parse_cli(sys.argv[1:])

    # Weekly idempotency guard (skip if ran recently, unless --force / --read-only).
    if not opts["force"] and not opts["read_only"] and os.path.exists(MARKER):
        try:
            last = os.path.getmtime(MARKER)
            if (now_utc().timestamp() - last) < WEEKLY_SECONDS:
                print("backlog-consolidate: ran < 6 days ago; skipping (use --force).")
                return
        except OSError:
            pass

    items = load_open_proposals()
    triggers = load_atone_triggers()
    rows = assess(items, triggers, opts["stale_days"])
    content = render(rows, opts["stale_days"])

    promote = sum(1 for r in rows if r["bucket"] == "PROMOTE")
    if opts["read_only"]:
        sys.stdout.write(content)
        print(f"\n[read-only] {len(items)} open · {len(rows)} clusters · {promote} PROMOTE",
              file=sys.stderr)
        return

    os.makedirs(TOPICS, exist_ok=True)
    today = now_utc().strftime("%Y-%m-%d")
    outpath = os.path.join(TOPICS, f"backlog-triage-{today}.md")
    with open(outpath, "w", encoding="utf-8") as f:
        f.write(content)
    with open(MARKER, "w") as f:
        f.write(now_utc().strftime("%Y-%m-%dT%H:%M:%SZ") + "\n")
        f.write(hashlib.sha256(content.encode()).hexdigest()[:16] + "\n")
    # Machine-readable sidecar for the SessionStart surfacer (no markdown parsing).
    promote_rows = [r for r in rows if r["bucket"] == "PROMOTE"]
    sidecar = {
        "date": today,
        "report": outpath,
        "counts": {b: sum(1 for r in rows if r["bucket"] == b)
                   for b in ("PROMOTE", "WATCH", "DROP-REVIEW")},
        "promote": [{"title": r["title"], "value": r["value"], "ids": r["ids"]}
                    for r in promote_rows[:5]],
    }
    with open(SIDECAR, "w", encoding="utf-8") as f:
        json.dump(sidecar, f)
    print(f"backlog-consolidate: wrote {outpath}")
    print(f"  {len(items)} open proposals · {len(rows)} clusters · {promote} PROMOTE candidates")


if __name__ == "__main__":
    main()
