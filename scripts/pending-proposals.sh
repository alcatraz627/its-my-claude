#!/bin/bash
# pending-proposals.sh — SessionStart hook that checks for pending dream-learned
# config proposals and injects them into Claude's context for user review.
#
# Output: JSON {"additionalContext": "..."} to stdout if proposals exist, else silent exit.
#
# Reads: ~/.claude/claudew/pending-config-proposals.jsonl
# This script never modifies the proposals file — only reads and presents.

PROPOSALS_FILE="$HOME/.claude/claudew/pending-config-proposals.jsonl"

[ -f "$PROPOSALS_FILE" ] || exit 0

python3 - "$PROPOSALS_FILE" <<'PYEOF'
import sys, json

proposals_file = sys.argv[1]

pending = []
try:
    with open(proposals_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
                if obj.get('status') == 'pending':
                    pending.append(obj)
            except json.JSONDecodeError:
                pass
except OSError:
    sys.exit(0)

if not pending:
    sys.exit(0)

# Build context message
lines = [
    "## Pending Config Proposals (Dream-Learned)",
    f"_{len(pending)} rule(s) extracted from dream insights with high confidence._",
    "_These were auto-generated from i-dream memory consolidation. Present each to the user for approval before adding to CLAUDE.md._",
    ""
]

for i, p in enumerate(pending, 1):
    conf = p.get('conf', 0)
    rule = p.get('rule', '(unknown)')
    approved = " (user-upvoted insight)" if p.get('user_approved_insight') else ""
    lines.append(f"**{i}.** (conf={conf:.2f}{approved}) {rule}")

lines.append("")
lines.append("_To act on these: present each rule to the user, ask if they want it added to CLAUDE.md. "
             "If accepted, add it under a '## Dream-Learned Rules' section. "
             "Then update the proposal status from 'pending' to 'accepted' or 'rejected' in the JSONL file._")

print(json.dumps({"additionalContext": "\n".join(lines)}))
PYEOF
