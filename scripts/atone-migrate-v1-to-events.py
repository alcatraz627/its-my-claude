#!/usr/bin/env python3
"""
atone-migrate-v1-to-events.py
─────────────────────────────
Smart, guided migration of ~/.claude/mistake-patterns.md (v1) to JSONL events.

This is NOT just a heuristic parser. It carries a CLASSIFICATION TABLE that
maps each slug to its hand-judged severity, cluster, and tags — built from
agent reading of each pattern body. The classification table is the
"guided" half; the regex parsing is the "structural" half.

Defaults (when slug missing from table): S2, no cluster, no extra tags.
Field extraction (issue/cause/fix/what_not/precheck): tries structured
section headers (**Why:**, **How to apply:**, etc.) and falls back to
chunking the body if those aren't present.

Output:
    ~/.claude/atone/events.jsonl.draft
    /tmp/atone-migrate-report.txt
"""

from __future__ import annotations
import re
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from collections import Counter

SRC = Path.home() / ".claude" / "mistake-patterns.md"
DST = Path.home() / ".claude" / "atone" / "events.jsonl.draft"
RCA_SRC = Path.home() / ".claude" / "mistake-patterns" / "2026-04-28-sherpa-data-loss-rca.md"
RCA_DST_DIR = Path.home() / ".claude" / "atone" / "rca"
REPORT = Path("/tmp/atone-migrate-report.txt")

# ─── Classification table (hand-judged) ──────────────────────────
# Schema: slug → (severity, cluster_or_None, extra_tags)
#
# Clusters:
#   A — Ungrounded assertion
#   B — Claim-ready-before-runtime
#   C — Literal-list-as-action / lost-the-user's-frame
#   D — Output-shape laziness
#   E — Convention-blind code

CLASSIFICATION: dict[str, tuple[str, str | None, list[str]]] = {
    "bypass-abstraction-instead-of-extending":                          ("S2", "E",  ["refactor"]),
    "chesterton-fence":                                                 ("S2", "A",  ["refactor"]),
    "assumed-prior-context":                                            ("S2", "A",  ["communication"]),
    "hallucinated-values-in-interactive-wizard-options":                ("S2", "A",  ["ui"]),
    "batch-verification-skip":                                          ("S2", "B",  ["testing"]),
    "shipping-css-ui-changes-without-visual-verification":              ("S2", "B",  ["css", "frontend"]),
    "committing-without-explicit-request":                              ("S3", None, ["policy-violation", "git"]),
    "blank-lines-inside-markdown-tables":                               ("S1", "D",  ["markdown"]),
    "html-outputs-missing-dark-light-mode-toggle":                      ("S1", "D",  ["html"]),
    "overriding-user-commented-preferences":                            ("S3", None, ["policy-violation", "user-respect"]),
    "missed-skill-invocation-after-compaction-resume":                  ("S2", "A",  ["compaction", "skills"]),
    "fix-committed-but-binary-not-rebuilt":                             ("S2", "B",  ["build"]),
    "treating-truncated-api-data-as-complete":                          ("S2", "A",  ["pagination"]),
    "infra-before-grep":                                                ("S2", "A",  ["scope-creep"]),
    "re-edit-same-location-re-edit":                                    ("S2", "B",  ["debugging"]),
    "fix-attempt-without-root-cause-fix-attempt":                       ("S2", "A",  ["debugging"]),
    "self-heal-becomes-the-write-path":                                 ("S3", None, ["concurrency", "data-integrity"]),
    "concurrent-load-mutate-save-without-a-mutex":                      ("S3", None, ["concurrency", "data-loss", "has-rca"]),
    "dismissing-user-reported-symptoms-with-partial-verification":      ("S2", "A",  ["user-respect"]),
    "patching-surface-symptoms-across-multiple-commits":                ("S2", "A",  ["debugging"]),
    "env-mutating-tool-saves-its-own-override-as-the-prior-value":     ("S2", None, ["architecture"]),
    "mcp-server-silently-shadowed-by-plugin":                          ("S2", None, ["mcp", "plugins"]),
    "adding-env-var-reads-without-checking-the-project-s-config-pattern":("S2", "E",["config"]),
    "status-verdict-from-stale-mental-model-no-re-check":              ("S2", "A",  ["state"]),
    "ghost-test-server-processes-from-port-reuse-broad-pkill":         ("S2", None, ["sysadmin"]),
    "catchup-loaded-stale-checkpoint-from-claude-after-clear":         ("S2", None, ["checkpoint", "system-bug"]),
    "js-escape-sequences-inside-server-side-template-literals":        ("S3", "D",  ["js", "templating", "same-session-repeat"]),
    "string-message-regex-match-for-selector-flow":                    ("S2", "E",  ["error-handling", "ts"]),
    "speculative-abstractions-without-a-load-bearing-caller":          ("S2", "E",  ["yagni"]),
    "twin-opt-in-opt-out-flags-for-one-gate":                          ("S1", None, ["config"]),
    "mirroring-server-owned-constants-on-the-client":                  ("S2", "E",  ["frontend", "constants"]),
    "defaulting-to-the-conventional-source-when-authoring-around-a-domain-noun": ("S2", "A", ["communication"]),
    "conflating-type-only-emission-with-type-check-time-path":         ("S2", "A",  ["ts", "build"]),
    "sub-agent-material-output-left-in-conversation-only":             ("S3", None, ["sub-agent", "data-loss"]),
    "unsolicited-index-manipulation":                                  ("S3", None, ["git", "policy-violation", "user-respect"]),
    "generalize-before-enumerate":                                     ("S3", "C",  ["communication", "git", "repeat-offender"]),
    "omit-intersection-drops-generic-propagation-through-function":    ("S2", "A",  ["ts"]),
    "display-label-as-state-key":                                      ("S1", "E",  ["frontend"]),
    "skip-existing-usage-check":                                       ("S2", "A",  ["convention"]),
    "tunnel-vision-debug-target":                                      ("S2", "A",  ["debugging"]),
    "getanimations-vs-transitions":                                    ("S1", "A",  ["css"]),
    "position-shift-remount":                                          ("S2", "A",  ["react"]),
    "suspect-without-import-grep":                                     ("S2", "A",  ["debugging"]),
    "helper-return-type-assumption":                                   ("S3", "A",  ["py", "deploy"]),
    "name-without-meaning":                                            ("S2", None, ["communication"]),
    "sycophantic-deference-on-coupled-decisions":                     ("S3", None, ["communication", "design"]),
    "ascii-art-tables-instead-of-gum-tools":                          ("S2", "D",  ["output-shape", "repeat-offender"]),
    "structural-claim-without-reading-code":                          ("S3", "A",  ["architecture", "same-session-repeat"]),
    "raw-process-env-instead-of-project-flag":                        ("S2", "E",  ["config", "frontend"]),
    "declared-ready-without-runtime-exercise":                        ("S3", "B",  ["frontend", "deploy"]),
    "trusted-linter-reminder-without-diffing":                        ("S3", "A",  ["linter", "silent-regression"]),
    "source-comment-hygiene":                                         ("S2", "D",  ["comments", "repeat-offender"]),
    "duplicate-type-declarations-across-files":                       ("S1", "E",  ["ts"]),
    "wrapper-hook-that-delegates-the-work-it-s-supposed-to-absorb":   ("S2", "E",  ["frontend", "react", "design"]),
    "open-question-dismissed-without-explaining-what-it-means":       ("S2", None, ["communication"]),
    "repeatedly-emphasizing-ops-setup-that-user-already-addressed":   ("S1", None, ["communication"]),
    "delta-drift-in-derived-counts":                                  ("S2", "A",  ["state"]),
    "scope-exclusion-drift-during-long-staging":                      ("S3", "C",  ["git", "user-respect"]),
    "cli-convention-guess-instead-of-read":                           ("S2", "A",  ["convention", "cli"]),
    "registered-by-import-only-assumption":                           ("S2", "A",  ["py"]),
    "defensive-style-coercion-that-crashes-on-real-inputs":           ("S2", "A",  ["py"]),
    "self-permitting-exception-to-an-adr-hard-rule":                  ("S3", None, ["policy-violation"]),
    "proposed-fix-breaks-design-invariant":                           ("S2", "A",  ["architecture"]),
    "hypothesis-without-validation-when-the-fix-looks-obvious":       ("S2", "A",  ["debugging"]),
    "unprompted-infra-scope-creep":                                   ("S2", None, ["scope-creep"]),
}

# ─── Helpers ─────────────────────────────────────────────────────

SECTION_HEADERS = re.compile(
    # Match **Header**, **Header:**, **Header.**  — colon may live inside or outside the bold
    r"\*\*([A-Z][\w \-/]+?)[:.]?\*\*[:.]?\s*", re.MULTILINE
)


def extract_sections(body: str) -> dict[str, str]:
    """Pull **Heading:** ... blocks. Returns dict normalized to lowercase keys."""
    # Strip Triggered line first
    body = re.sub(r"\nTriggered:.*", "", body, flags=re.DOTALL)
    out: dict[str, str] = {}
    # Find all bold headers and their offsets
    matches = list(SECTION_HEADERS.finditer(body))
    for i, m in enumerate(matches):
        key = m.group(1).strip().lower()
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(body)
        out[key] = body[start:end].strip()
    return out


def parse_slug_title(header: str) -> tuple[str, str]:
    h = header.replace("## Pattern:", "", 1).strip()
    for sep in [" — ", " – ", " - ", "—"]:
        if sep in h:
            slug_part, title = h.split(sep, 1)
            slug_part, title = slug_part.strip(), title.strip()
            break
    else:
        slug_part, title = h, h
    slug = re.sub(r"[^a-zA-Z0-9-]+", "-", slug_part).strip("-").lower()
    return slug or "unknown", title


def parse_triggers(body: str) -> list[str]:
    dates = []
    for line in body.split("\n"):
        if line.strip().lower().startswith("triggered:"):
            for m in re.finditer(r"\b(20\d{2}-\d{2}-\d{2})\b", line):
                dates.append(m.group(1))
    return sorted(set(dates)) or ["2026-04-01"]


def build_fields(body: str, slug: str) -> dict[str, str]:
    """Extract issue/cause/fix/what_not_to_do/precheck from body."""
    sections = extract_sections(body)

    # Heuristic mapping — multiple v1 section names map to one field
    def first(keys: list[str]) -> str:
        for k in keys:
            if k in sections and sections[k]:
                return sections[k][:600]
        return ""

    cause    = first(["why", "cause", "root cause", "why bad", "deeper cause"])
    issue    = first(["real incident", "what happened", "incident", "symptom"])
    fix      = first(["fix", "fix shape", "the fix"])
    what_not = first(["what not to do"])
    precheck = first(["how to spot", "pre-answer test", "trigger", "how to apply"])

    # Body sans-Triggered, for the "general" content
    general_body = re.sub(r"\nTriggered:.*", "", body, flags=re.DOTALL).strip()
    # Strip section markdown for general content
    general_clean = SECTION_HEADERS.sub("", general_body).strip()[:1000]

    if not issue:
        issue = general_clean[:600] or "(see source body in v1 mistake-patterns.md)"
    if not cause:
        cause = "(parser could not isolate cause — see issue field; user-review)"
    if not fix:
        fix = "(no explicit fix recorded — see issue field; user-review)"
    if not what_not:
        # Derive what-not from precheck or first paragraph
        what_not = precheck[:300] if precheck else \
                   general_clean.split("\n\n", 1)[0][:300] or "(user-review)"

    return {
        "issue": issue.strip(),
        "cause": cause.strip(),
        "fix": fix.strip(),
        "what_not_to_do": what_not.strip(),
        "precheck": precheck.strip() if precheck else "",
    }


def build_event(slug: str, title: str, body: str, trigger_date: str,
                seq: int, total: int) -> dict:
    sev, cluster, extra_tags = CLASSIFICATION.get(slug, ("S2", None, []))

    fields = build_fields(body, slug)
    dt = datetime.strptime(trigger_date, "%Y-%m-%d").replace(
        hour=12, minute=0, second=seq, tzinfo=timezone.utc
    )
    event_id = f"mist-{dt.strftime('%Y%m%d-%H%M%S')}-m{seq:02x}"
    ts = dt.strftime("%Y-%m-%dT%H:%M:%SZ")
    note = f"[migrated v1, occurrence {seq+1}/{total} of slug]"

    return {
        "id": event_id,
        "ts": ts,
        "slug": slug,
        "title": title[:200],
        "issue": f"{note} {fields['issue']}".strip(),
        "cause": fields["cause"],
        "fix": fields["fix"],
        "what_not_to_do": fields["what_not_to_do"],
        "precheck": fields["precheck"] or None,
        "severity": sev,
        "cluster": cluster,
        "project": None,
        "tags": sorted(set(extra_tags + ["migrated-from-v1"])),
        "files": [],
        "rca_id": None,  # Set below for the sherpa RCA
    }


def main():
    text = SRC.read_text(encoding="utf-8", errors="replace")
    blocks = re.split(r"\n(?=[ \t]*## Pattern:)", text)
    blocks = [b for b in blocks if re.search(r"^[ \t]*## Pattern:", b, re.MULTILINE)]
    blocks = [b.lstrip() if b.lstrip().startswith("## Pattern:") else b for b in blocks]

    events = []
    pattern_summary = []
    cluster_counts = Counter()
    severity_counts = Counter()
    unclassified = []  # slugs not in CLASSIFICATION

    for block in blocks:
        header, body = block.split("\n", 1) if "\n" in block else (block, "")
        slug, title = parse_slug_title(header)
        dates = parse_triggers(body)
        if slug not in CLASSIFICATION:
            unclassified.append(slug)
        for i, d in enumerate(dates):
            ev = build_event(slug, title, body, d, i, len(dates))
            events.append(ev)
            cluster_counts[ev["cluster"] or "-"] += 1
            severity_counts[ev["severity"]] += 1
        pattern_summary.append({
            "slug": slug, "title": title[:80], "triggers": len(dates),
            "severity": events[-1]["severity"] if events else "?",
            "cluster": events[-1]["cluster"] if events else "-",
        })

    # Pre-attach the existing sherpa RCA to the concurrent-mutex slug, if present
    if RCA_SRC.exists():
        rca_event = next(
            (e for e in events
             if e["slug"] == "concurrent-load-mutate-save-without-a-mutex"),
            None,
        )
        if rca_event:
            RCA_DST_DIR.mkdir(parents=True, exist_ok=True)
            # Write a copy under atone/rca/ with the event's ID
            new_rca_path = RCA_DST_DIR / f"{rca_event['id']}.md"
            if not new_rca_path.exists():
                new_rca_path.write_text(
                    RCA_SRC.read_text(encoding="utf-8", errors="replace"),
                    encoding="utf-8",
                )
            rca_event["rca_id"] = rca_event["id"]

    DST.parent.mkdir(parents=True, exist_ok=True)
    with DST.open("w", encoding="utf-8") as f:
        for ev in events:
            f.write(json.dumps(ev, ensure_ascii=False) + "\n")

    # Report
    with REPORT.open("w", encoding="utf-8") as r:
        r.write(f"atone migration report — {datetime.now(timezone.utc).isoformat()}\n")
        r.write(f"source:  {SRC}\n")
        r.write(f"draft:   {DST}\n\n")
        r.write(f"patterns parsed:    {len(blocks)}\n")
        r.write(f"events emitted:     {len(events)}\n")
        r.write(f"severity breakdown: {dict(severity_counts)}\n")
        r.write(f"cluster breakdown:  {dict(cluster_counts)}\n")
        r.write(f"unclassified slugs: {len(unclassified)}  "
                f"(used S2 / no cluster defaults)\n")
        if unclassified:
            for s in unclassified:
                r.write(f"  - {s}\n")
        r.write("\nper-pattern summary (sorted by trigger count desc):\n\n")
        for p in sorted(pattern_summary, key=lambda x: (-x["triggers"], x["slug"])):
            r.write(f"  {p['triggers']}× {p['severity']:>2} c:{p['cluster'] or '-':<4} "
                    f"{p['slug']}\n")
        r.write("\nslugs with >=2 triggers (recurrence priorities):\n")
        for p in sorted(pattern_summary, key=lambda x: -x["triggers"]):
            if p["triggers"] >= 2:
                r.write(f"  {p['triggers']}× {p['severity']} {p['slug']}\n")
        r.write("\nseverity → slug map:\n")
        for sev_target in ("S3", "S2", "S1"):
            r.write(f"\n  [{sev_target}]\n")
            for p in sorted(pattern_summary, key=lambda x: x["slug"]):
                if p["severity"] == sev_target:
                    r.write(f"    - {p['slug']} ({p['triggers']}×, c:{p['cluster'] or '-'})\n")

    print(f"OK  wrote {len(events)} events from {len(blocks)} patterns")
    print(f"    draft:    {DST}")
    print(f"    report:   {REPORT}")
    print(f"    severity: {dict(severity_counts)}")
    print(f"    clusters: {dict(cluster_counts)}")
    if unclassified:
        print(f"    NOTE: {len(unclassified)} slug(s) unclassified — defaulted to S2/none")
    else:
        print(f"    NOTE: 100% slugs classified — no defaults applied")


if __name__ == "__main__":
    main()
