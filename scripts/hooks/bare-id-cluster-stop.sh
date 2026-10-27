#!/usr/bin/env bash
# bare-id-cluster-stop.sh: Stop hook: stop a closing reply that lists ids with
# no words saying what they are, once per message.
#
# THE FAILURE. Asked "show me what is pending on me", an agent replies with
# "#59 #91 #39 #153 #130 #89" and four hundred words of bold-headed prose. Every
# fact correct, and unusable: an id is a lookup key, and the person reading has
# to open a file to learn what any of them is. It recurs across sessions (the
# slug is dense-briefing-instead-of-a-direct-answer, and later
# bare-identifier-where-the-name-belongs), and the advisory version of this hook
# fired many times without changing the count. The owner approved promoting it
# from a warning to a block.
#
# WHAT COUNTS AS AN ID. #123, a ticket key such as VER-123, a D-code such as D12,
# and a commit hash (7 to 40 hex characters holding at least one digit and one
# letter, so plain words and plain numbers are not hashes). Backticks do not hide
# them: a hash is almost always written in backticks. Three or more of them
# joined only by spaces, commas, slashes, "·", "and" or "or" are a cluster; an id
# followed by its subject is what the gloss rule asks for and is never one.
#
# WHAT STAYS EXEMPT. A fenced code block. A rendered /tasks table is a ruled
# shape whose "done (98): #1 #2 #3 …" line is a deliberate collapse inside a
# block the reader can see is a table. The defect is a cluster loose in prose.
#
# BLOCKS ONCE. The block fires on a message, and the identical message never
# blocks again (hook_loop_check), so a reply that is genuinely about the ids, or
# one the agent re-sends unchanged, goes through on the second try.
#
# Mute: touch ~/.claude/.no-bare-id-gate (machine-wide until removed).

set -uo pipefail
[ -f "$HOME/.claude/.no-bare-id-gate" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

HOOK_COMMON="$HOME/.claude/scripts/hooks/hook-common.sh"
[ -r "$HOOK_COMMON" ] || exit 0
. "$HOOK_COMMON"

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$tp" ] && [ -f "$tp" ] || exit 0
sid8=$(hook_sid8 "$sid")

# JSON {"prose": <final message, fences removed>, "hits": [<cluster>, ...]}.
# Backticks cannot appear literally in the python: it lives inside a $(...)
# command substitution, where bash still treats a backtick as an open-quote even
# through a quoted heredoc. Spell them chr(96); `bash -n` is the check that
# catches a slip.
result=$(python3 - "$tp" <<'PY' 2>/dev/null
import json, re, sys
last = ""
for line in open(sys.argv[1], errors="replace"):
    try: d = json.loads(line)
    except Exception: continue
    if d.get("type") != "assistant": continue
    c = (d.get("message") or {}).get("content") or []
    t = "".join(b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text")
    if t.strip(): last = t

bt = chr(96)
prose = re.sub(bt * 3 + ".*?" + bt * 3, " ", last, flags=re.S)
# Unwrap inline code instead of dropping it: a commit hash lives there.
prose = re.sub(bt + "([^" + bt + "]*)" + bt, r"\1", prose)
flat = prose.replace("**", "")

NOT_TICKETS = {"UTF", "SHA", "MD", "ISO", "RFC", "TLS", "AES", "HTTP", "ASCII", "RSA"}
TOKEN = (r"(?:#\d{1,5}\b"
         r"|\b[A-Z]{2,6}-\d{1,5}\b"
         r"|\bD\d{1,2}\b"
         r"|\b(?=[0-9a-f]*\d)(?=[0-9a-f]*[a-f])[0-9a-f]{7,40}\b)")
SEP = r"(?:\s*[,/·]\s*(?:(?:and|or)\s+)?|\s+(?:and|or)\s+|\s+)"
CLUSTER = re.compile(TOKEN + "(?:" + SEP + TOKEN + "){2,}")

hits = []
for m in CLUSTER.finditer(flat):
    toks = re.findall(TOKEN, m.group(0))
    real = [t for t in toks if t.split("-")[0] not in NOT_TICKETS]
    if len(real) >= 3:
        hits.append(m.group(0).strip())
print(json.dumps({"prose": prose, "hits": hits[:3]}))
PY
)
[ -n "$result" ] || exit 0
prose=$(printf '%s' "$result" | jq -r '.prose' 2>/dev/null)
hit=$(printf '%s' "$result" | jq -r '.hits[]?' 2>/dev/null)
[ -n "${prose//[[:space:]]/}" ] || exit 0

MARK="/tmp/claude-bareid-${sid8}"
if [ -z "$hit" ]; then
  if [ -f "$MARK" ]; then
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook bare-id-cluster \
      --heed-of "bare-id:$sid8" --heeded true >/dev/null 2>&1 || true
    rm -f "$MARK" 2>/dev/null || true
  fi
  exit 0
fi

if ! hook_loop_check "$MARK" "$prose"; then
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook bare-id-cluster \
    --heed-of "bare-id:$sid8" --heeded false >/dev/null 2>&1 || true
  exit 0
fi

# A block reason is shown clipped on one line, so it stays compact.
hit_flat=$(printf '%s' "$hit" | tr '\n' '|' | sed 's/|/ | /g')
reason="bare-id: the final message lists ids with no words saying what they are (${hit_flat}). The reader has to look each one up. Re-send with each id followed by its subject in plain words (what the issue, commit or task is, and what you are asking about it), or put a real table in a code fence. The owner's rule: every task number, issue number or commit hash carries a gloss, and chat prose obeys it too. Mute: touch ~/.claude/.no-bare-id-gate"

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook bare-id-cluster --action block \
  --heeded unknown >/dev/null 2>&1 || true
jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
exit 0
