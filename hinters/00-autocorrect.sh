#!/usr/bin/env bash
# 00-autocorrect.sh — Layer 0/1 typo correction hinter.
#
# Reads prompt text from stdin. Emits correction hints to stdout.
# Exits silently if no corrections found.
#
# Layer 0: Custom-term dictionary (skip known-good words)
# Layer 1: Known-typo map (deterministic replacements)
#
# Never touches: code spans, paths, constants, function calls, blacklisted words.

set -uo pipefail

DICT_DIR="${HOME}/.claude/assets/autocorrect"
CUSTOM_TERMS="${DICT_DIR}/custom-terms.txt"
TYPO_MAP="${DICT_DIR}/typo-map.txt"
BLACKLIST="${DICT_DIR}/blacklist.txt"

# Read prompt from stdin, store in temp file for Python to read
PROMPT=$(cat 2>/dev/null || echo "")
[[ -z "$PROMPT" ]] && exit 0

TMPFILE=$(mktemp /tmp/autocorrect-prompt.XXXXXX)
printf '%s' "$PROMPT" > "$TMPFILE"
trap "rm -f '$TMPFILE'" EXIT

python3 - "$CUSTOM_TERMS" "$TYPO_MAP" "$BLACKLIST" "$TMPFILE" <<'PYEOF'
import sys, re, os

custom_file = sys.argv[1]
typo_file = sys.argv[2]
blacklist_file = sys.argv[3]
prompt_file = sys.argv[4]

with open(prompt_file, 'r') as f:
    prompt = f.read().strip()
if not prompt:
    sys.exit(0)

# Load custom terms (Layer 0 — known-good words)
custom_terms = set()
try:
    with open(custom_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                custom_terms.add(line.lower())
except OSError:
    pass

# Load typo map (Layer 1 — deterministic corrections)
typo_map = {}
try:
    with open(typo_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if ' -> ' in line:
                wrong, right = line.split(' -> ', 1)
                typo_map[wrong.strip().lower()] = right.strip()
except OSError:
    pass

# Load blacklist (never correct these)
blacklist = set()
try:
    with open(blacklist_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                blacklist.add(line.lower())
except OSError:
    pass

# Tokenize prompt, preserving code spans and paths
# Strategy: split on whitespace, then classify each token

def should_skip(token):
    """Returns True if this token should never be autocorrected."""
    # Inside backticks (already stripped by tokenizer, but check for residual)
    if '`' in token:
        return True
    # Paths: starts with /, ~, ./, ../
    if re.match(r'^[/~.]', token):
        return True
    # Constants: ALL_CAPS_WITH_UNDERSCORES
    if re.match(r'^[A-Z_][A-Z0-9_]*$', token):
        return True
    # Function calls: ends with () or contains .word(
    if token.endswith('()') or re.search(r'\.\w+\(', token):
        return True
    # Has dots (likely a domain, file extension, or method chain)
    if '.' in token and not token.endswith('.'):
        return True
    # Flags: starts with -
    if token.startswith('-'):
        return True
    # Contains special chars (likely not prose)
    if re.search(r'[{}()\[\]@#$%^&*=+|<>]', token):
        return True
    return False

# Remove code spans from consideration
code_span_pattern = re.compile(r'`[^`]+`')
# Track which portions are code spans so we skip tokens from them
code_spans = set()
for m in code_span_pattern.finditer(prompt):
    for i in range(m.start(), m.end()):
        code_spans.add(i)

# Tokenize
corrections = []
words = re.findall(r'\S+', prompt)

for word in words:
    # Find word position in prompt to check if it's in a code span
    idx = prompt.find(word)
    if idx >= 0 and any(i in code_spans for i in range(idx, idx + len(word))):
        continue

    # Strip trailing punctuation for lookup
    clean = re.sub(r'[.,;:!?\'")\]]+$', '', word)
    clean = re.sub(r'^[(\["\']', '', clean)
    lower = clean.lower()

    if not lower or len(lower) < 3:
        continue

    if should_skip(clean):
        continue

    # Blacklist check
    if lower in blacklist:
        continue

    # Layer 0: custom terms — known-good, skip
    if lower in custom_terms:
        continue

    # Layer 1: typo map — deterministic correction
    if lower in typo_map:
        corrected = typo_map[lower]
        # Preserve original case pattern
        if clean[0].isupper() and corrected[0].islower():
            corrected = corrected[0].upper() + corrected[1:]
        corrections.append((clean, corrected))

if not corrections:
    sys.exit(0)

# Log corrections to JSONL
import json, datetime
log_path = os.path.join(os.path.expanduser("~"), ".claude", ".autocorrect-log.jsonl")
ts = datetime.datetime.now(datetime.timezone.utc).isoformat()
sid = os.environ.get("CLAUDE_SESSION_ID", "")
try:
    with open(log_path, 'a') as lf:
        for orig, fixed in corrections[:5]:
            lf.write(json.dumps({
                "ts": ts, "sid": sid, "orig": orig, "corrected": fixed,
                "layer": 1, "accepted": None
            }) + "\n")
except OSError:
    pass

# Emit hint
parts = [f'"{orig}" → "{fixed}"' for orig, fixed in corrections[:5]]  # cap at 5
print(f'[autocorrect] Detected likely typos: {", ".join(parts)}')
PYEOF
