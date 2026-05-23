#!/usr/bin/env bash
# propose-config-from-insights.sh — extract dream-learned rules and propose them
# as CLAUDE.md additions. Does NOT auto-apply — proposals require user confirmation.
#
# Usage:
#   bash ~/.claude/scripts/dream/propose-config-from-insights.sh
#
# Reads:   ~/.claude/subconscious/dreams/insights.md
#          ~/.claude/subconscious/dreams/insight-feedback.jsonl (if present)
#          ~/.claude/CLAUDE.md (for duplicate detection)
# Writes:  ~/.claude/claudew/pending-config-proposals.jsonl (append)
#
# High-confidence threshold: conf >= 0.85 (stricter than runtime-notes injection)
# Insights with "down" feedback are excluded.
# Insights whose rule text is already in CLAUDE.md are skipped.
#
# Called by: post-wake.sh hook, or manually.

set -euo pipefail

INSIGHTS_SRC="${HOME}/.claude/subconscious/dreams/insights.md"
FEEDBACK_FILE="${HOME}/.claude/subconscious/dreams/insight-feedback.jsonl"
CLAUDE_MD="${HOME}/.claude/CLAUDE.md"
PROPOSALS_FILE="${HOME}/.claude/claudew/pending-config-proposals.jsonl"
THRESHOLD="0.85"
MAX_PROPOSALS=5

mkdir -p "$(dirname "$PROPOSALS_FILE")"

[[ -f "$INSIGHTS_SRC" ]] || { echo "propose-config: no insights file, skipping." >&2; exit 0; }

python3 - "$INSIGHTS_SRC" "$FEEDBACK_FILE" "$CLAUDE_MD" "$PROPOSALS_FILE" "$THRESHOLD" "$MAX_PROPOSALS" <<'PYEOF'
import sys, re, json, os, hashlib
from datetime import datetime, timezone

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

# Read existing proposals to avoid duplicates and count pending
existing_hashes = set()
pending_count = 0
if os.path.exists(proposals_file):
    with open(proposals_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
                existing_hashes.add(obj.get('rule_hash', ''))
                if obj.get('status') == 'pending':
                    pending_count += 1
            except json.JSONDecodeError:
                pass

# Don't stage more if user hasn't reviewed existing pending proposals
if pending_count >= max_proposals:
    print(f"propose-config: {pending_count} pending proposals already queued, skipping.", file=sys.stderr)
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

    # Extract insight ID (first pattern UUID)
    insight_id = ''
    pat_match = re.search(r'_Patterns:\s*([^_]+)_', block)
    if pat_match:
        first_uuid = pat_match.group(1).split(',')[0].strip()
        if len(first_uuid) >= 8:
            insight_id = first_uuid

    # Skip if user gave thumbs-down
    if insight_id and feedback.get(insight_id) == 'down':
        continue

    # Skip if rule already exists in CLAUDE.md (fuzzy: check first 80 chars)
    rule_sig = rule[:80].lower().strip()
    if rule_sig in claude_md:
        continue

    # Skip if already proposed
    rule_hash = hashlib.sha256(rule.encode()).hexdigest()[:16]
    if rule_hash in existing_hashes:
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
remaining_slots = max(0, max_proposals - pending_count)
candidates = candidates[:remaining_slots]

if not candidates:
    print("propose-config: no new proposals above threshold.", file=sys.stderr)
    sys.exit(0)

# Append proposals to JSONL
ts = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
with open(proposals_file, 'a') as f:
    for c in candidates:
        proposal = {
            'ts': ts,
            'status': 'pending',
            'conf': round(c['conf'], 2),
            'rule': c['rule'],
            'rule_hash': c['rule_hash'],
            'insight_id': c['insight_id'],
            'user_approved_insight': c['user_approved'],
        }
        f.write(json.dumps(proposal) + '\n')

print(f"propose-config: {len(candidates)} new config proposal(s) staged.", file=sys.stderr)
PYEOF
