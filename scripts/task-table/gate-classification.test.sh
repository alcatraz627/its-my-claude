#!/usr/bin/env bash
# gate-classification.test.sh — what counts as an owner gate, and what does not.
#
# The owner's GATES band showed 16 rows on 2026-09-04 of which 2 were real. The
# other 14 were rows waiting on OTHER WORK, painted in the owner's colour, and
# because GATES renders first and the height cap allocates greedily, those 14
# rows pushed his entire 181-row queue off the screen. He saw a wall of things he
# could not act on and none of the work.
#
# Cause: AGENT_BLOCKED required a colon immediately after the keyword
# ("BLOCKED-BY:"), while the convention as actually written puts the colon after
# the referent ("blocked-by #404: ..."). One regex, fourteen false gates.
#
# This suite pins the classifier against REAL blocked_on strings taken from that
# queue, so the next edit to the regex has to keep them classified correctly.
#
# Run: bash ~/.claude/scripts/task-table/gate-classification.test.sh  (exit 0 = pass)

set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
python3 - "$HERE/task-table.sh" <<'PY'
import re, sys

src = open(sys.argv[1]).read()
m = re.search(r'^AGENT_BLOCKED = re\.compile\(\s*(.*?)\)\s*$', src, re.M | re.S)
if not m:
    print("FAIL: could not find AGENT_BLOCKED in task-table.sh"); sys.exit(1)
AGENT_BLOCKED = eval("re.compile(" + m.group(1) + ")", {"re": re})

# (label, blocked_on, is_owner_gate) — verbatim from session f04ae843, 2026-09-04
CASES = [
 ("#574 owner must apply a migration", "USER: apply integration's migration to the shared dev database, or say who does", True),
 ("#599 owner must drop a sentinel",   "USER: one push sentinel, then this deploy clears both blockers at once", True),
 ("#386 waits on another task",        "blocked-by #404: gcp-watcher gates the board BEFORE it goes to the owner", False),
 ("#5   waits on another task",        "blocked-by #338: the owner already PARKED this", False),
 ("#168 deferred by the owner",        "blocked-by later: the owner's own words were 'task for later'", False),
 ("#387 waits on a component",         "blocked-by the admin panel and the auth.versable.ai domain", False),
 ("#400 waits on a recon",             "blocked-by the final docs recon; then vb-fable", False),
 ("#469 waits on V1",                  "blocked-by post-V1: the owner's own words", False),
 ("#471 waits on V1 and a decision",   "blocked-by post-V1, and by the per-person admin auth decision", False),
 ("#522 sequenced by a signed plan",   "plan signed 2026-09-03; sequenced in WALMART-BUILD.md", False),
 ("#567 waits on a deploy",            "blocked-by phase 3 deploy to dev", False),
 # the other prefixes the convention documents
 ("AGENT: the agent's own wait",       "AGENT: mine to build once the schema lands", False),
 ("ME: same, other spelling",          "ME: still drafting", False),
 ("AFTER: sequencing",                 "AFTER #12 merges", False),
 ("WAITING: external actor",           "WAITING on the vendor to answer", False),
 ("EXTERNAL: third party",             "EXTERNAL: DNS propagation", False),
 ("DEPENDS ON: sequencing",            "DEPENDS ON the auth module", False),
 # a bare owner ask with no prefix still reads as a gate
 ("no prefix, plain owner ask",        "your ruling on the naming", True),
]

fails = 0
for label, text, want_gate in CASES:
    got_gate = not AGENT_BLOCKED.match(text)
    if got_gate != want_gate:
        fails += 1
        print(f"  FAIL: {label}")
        print(f"        text: {text[:78]}")
        print(f"        classified as {'OWNER GATE' if got_gate else 'other work'}, "
              f"want {'OWNER GATE' if want_gate else 'other work'}")

gates = sum(1 for _, t, _ in CASES if not AGENT_BLOCKED.match(t))
print(f"  of {len(CASES)} real rows, {gates} classify as owner gates")
print(f"---- pass={len(CASES)-fails} fail={fails}")
sys.exit(1 if fails else 0)
PY
