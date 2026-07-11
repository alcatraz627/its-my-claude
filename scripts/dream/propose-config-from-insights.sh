#!/usr/bin/env bash
# propose-config-from-insights.sh — turn a high-confidence dream insight into a
# proposal on the ONE improvement backlog, where it competes for attention and
# gets decided like every other proposal. Never auto-applies.
#
# Usage:
#   bash ~/.claude/scripts/dream/propose-config-from-insights.sh
#
# Reads:   ~/.claude/subconscious/dreams/insights.md
#          ~/.claude/subconscious/dreams/insight-feedback.jsonl (if present)
#          ~/.claude/CLAUDE.md (for duplicate detection)
# Writes:  ~/.claude/proposals.jsonl, via `propose.sh add` (the only writer).
#
# It used to append to its own store (claudew/pending-config-proposals.jsonl),
# which nothing triaged: those rows were re-injected at every SessionStart, never
# entered the backlog, never accrued corroboration, and their only advertised
# lifecycle was "the agent hand-edits the JSONL". In weeks they produced zero
# decisions. Now a dream rule arrives tagged `link:dream:<insight-id>` and is
# decided at /backlog-triage with everything else. The old file is kept as a
# read-only archive; nothing writes it. (Migration 0031.)
#
# High-confidence threshold: conf >= 0.85 (stricter than runtime-notes injection)
# Insights with "down" feedback are excluded.
# Insights whose rule text is already in CLAUDE.md are skipped.
# A thumbs-up insight arrives pre-corroborated (the human already endorsed it).
#
# Called by: post-wake.sh hook, or manually.

set -euo pipefail

INSIGHTS_SRC="${HOME}/.claude/subconscious/dreams/insights.md"
FEEDBACK_FILE="${HOME}/.claude/subconscious/dreams/insight-feedback.jsonl"
CLAUDE_MD="${HOME}/.claude/CLAUDE.md"
# The canonical backlog. Dedup reads it directly; writes go through propose.sh.
PROPOSALS_FILE="${PROPOSE_STORE:-${HOME}/.claude/proposals.jsonl}"
THRESHOLD="0.85"
MAX_PROPOSALS=5

[[ -f "$INSIGHTS_SRC" ]] || { echo "propose-config: no insights file, skipping." >&2; exit 0; }

python3 - "$INSIGHTS_SRC" "$FEEDBACK_FILE" "$CLAUDE_MD" "$PROPOSALS_FILE" "$THRESHOLD" "$MAX_PROPOSALS" <<'PYEOF'
import sys, re, json, os, hashlib, subprocess

insights_file  = sys.argv[1]
feedback_file  = sys.argv[2]
claude_md_file = sys.argv[3]
proposals_file = sys.argv[4]
threshold      = float(sys.argv[5])
max_proposals  = int(sys.argv[6])

# Read insights
with open(insights_file, 'r') as f:
    content = f.read()

# Read existing feedback (insight_id → "up"/"down")
feedback = {}
if os.path.exists(feedback_file):
    with open(feedback_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
                feedback[obj['insight_id']] = obj['rating']
            except (json.JSONDecodeError, KeyError):
                pass

# Read CLAUDE.md for duplicate checking
claude_md = ''
if os.path.exists(claude_md_file):
    with open(claude_md_file, 'r') as f:
        claude_md = f.read().lower()

# Read the canonical backlog: skip insights already filed (by their link:dream:
# edge, which is the stable identity), and stop staging while unreviewed dream
# proposals are still open — a dream that nobody has judged is not a mandate to
# queue five more.
existing_dream_ids = set()
existing_hashes = set()
open_dream_count = 0
if os.path.exists(proposals_file):
    with open(proposals_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            tags = obj.get('tags') or []
            # Identify our own rows by the src tag, which is ALWAYS written.
            # (Keying on link:dream: instead would skip every insight that has no
            # parseable insight-id — and then miss its rulehash, so the next run
            # would re-file it as a duplicate. That bug shipped for exactly one
            # test run.)
            if 'src:dream-consolidation' not in tags:
                continue
            for t in tags:
                if t.startswith('link:dream:'):
                    existing_dream_ids.add(t.split('link:dream:', 1)[1])
                elif t.startswith('rulehash:'):
                    existing_hashes.add(t.split('rulehash:', 1)[1])
            if obj.get('status') == 'open':
                open_dream_count += 1

if open_dream_count >= max_proposals:
    print(f"propose-config: {open_dream_count} dream proposals still open on the backlog; "
          f"staging nothing new (decide them at /backlog-triage).", file=sys.stderr)
    sys.exit(0)

# Parse insights
blocks = re.split(r'(?=### Insight)', content)
candidates = []

for block in blocks:
    conf_match = re.search(r'\(conf=([\d.]+)\)', block)
    if not conf_match:
        continue
    conf = float(conf_match.group(1))
    if conf < threshold:
        continue

    # Extract rule
    rule_match = re.search(r'\*\*Rule:\*\*\s*(.+?)(?:\n\n|\n_Patterns|\Z)', block, re.DOTALL)
    if not rule_match:
        continue
    rule = ' '.join(rule_match.group(1).strip().split())

    # Insight identity.
    #
    # This used to read a `_Patterns: <uuid>, …_` line, but insights.md now emits
    # `_Pattern_: "<quoted text>"` — so the regex silently matched nothing and
    # every insight got an empty id (no link: edge, no dedup). Rather than chase
    # a format that drifts, key on the rule TEXT: same rule -> same hash, across
    # runs and across format changes. The old uuid form is still honoured if a
    # file in that shape shows up.
    rule_hash = hashlib.sha256(rule.encode()).hexdigest()[:16]
    insight_id = rule_hash
    legacy = re.search(r'_Patterns:\s*([0-9a-f-]{8,})', block)
    if legacy:
        insight_id = legacy.group(1).strip()

    # Skip if user gave thumbs-down
    if insight_id and feedback.get(insight_id) == 'down':
        continue

    # Skip if rule already exists in CLAUDE.md (fuzzy: check first 80 chars)
    rule_sig = rule[:80].lower().strip()
    if rule_sig in claude_md:
        continue

    # Skip if already on the backlog — by insight id (stable) or rule text.
    if rule_hash in existing_hashes:
        continue
    if insight_id and insight_id in existing_dream_ids:
        continue

    # Boost score if user gave thumbs-up
    boost = 0.05 if feedback.get(insight_id) == 'up' else 0
    candidates.append({
        'conf': conf + boost,
        'rule': rule,
        'rule_hash': rule_hash,
        'insight_id': insight_id,
        'user_approved': feedback.get(insight_id) == 'up',
    })

# Sort by confidence (with boost), take remaining slots
candidates.sort(key=lambda x: x['conf'], reverse=True)
remaining_slots = max(0, max_proposals - open_dream_count)
candidates = candidates[:remaining_slots]

if not candidates:
    print("propose-config: no new proposals above threshold.", file=sys.stderr)
    sys.exit(0)

# File each onto the canonical backlog via propose.sh — the only writer. A
# thumbs-up insight carries `corroborated:human-upvote`, so the gate can see that
# a human already endorsed the underlying insight; that is a genuine second
# stream, not the dream agreeing with itself.
PROPOSE = os.path.expanduser('~/.claude/scripts/propose.sh')
filed = 0
for c in candidates:
    title = c['rule'] if len(c['rule']) <= 90 else c['rule'][:87] + '...'
    body = (
        f"Dream-learned rule (confidence {round(c['conf'], 2)}) from i-dream memory "
        f"consolidation.\n\n"
        f"**Proposed rule:**\n{c['rule']}\n\n"
        f"**Suggested placement:** ~/.claude/CLAUDE.md Tier-0, or a rules/*.md entry "
        f"if it needs more than three sentences.\n\n"
        f"**Insight id:** {c['insight_id'] or '(none)'}\n"
        f"**Human feedback on the source insight:** "
        f"{'thumbs-up' if c['user_approved'] else 'none yet'}\n\n"
        f"Filed automatically by propose-config-from-insights.sh. Decide at "
        f"/backlog-triage like any other proposal — do not hand-edit the store."
    )
    tags = [f"link:dream:{c['insight_id']}"] if c['insight_id'] else []
    tags += ["src:dream-consolidation", f"rulehash:{c['rule_hash']}"]
    if c['user_approved']:
        tags.append("corroborated:human-upvote")

    r = subprocess.run(
        ['bash', PROPOSE, 'add',
         '--title', f"[dream] {title}",
         '--body', body,
         '--category', 'config',
         '--effort', 'small',
         '--tags', ' '.join(tags),
         '--session', 'dream-consolidation'],
        capture_output=True, text=True,
    )
    if r.returncode == 0:
        filed += 1
    else:
        print(f"propose-config: propose.sh refused a proposal: "
              f"{(r.stderr or '').strip()[:120]}", file=sys.stderr)

print(f"propose-config: {filed} dream proposal(s) filed to the backlog.", file=sys.stderr)
PYEOF
