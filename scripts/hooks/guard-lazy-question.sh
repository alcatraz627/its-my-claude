#!/usr/bin/env bash
# guard-lazy-question.sh — PreToolUse hook on AskUserQuestion.
#
# Nudges when the agent asks the user a question without having consulted the
# codebase in the current turn. Grounded in real user pushback ("why would you
# ask me such lazy questions") — a question that the code could have answered,
# asked before the agent looked.
#
# Mechanism: on every AskUserQuestion, walk the CURRENT turn's tool history
# (from the last genuine human prompt to now, treating task-notifications /
# system-reminders / stop-hook-feedback as transparent interruptions, not
# boundaries). If that window contains a Read / Grep / Glob / LS — or a
# code-reading Bash (cat, rg, fd, head, tail, ls, sed, awk, git diff/show/log,
# …) — the question is INFORMED, so this stays silent. If NOT, it emits one
# soft nudge: check the code first; ask only what the code cannot tell you.
#
# ADVISORY, never blocks. A genuinely user-only question (a preference, a design
# call the code can't answer) must still go through — this only reminds. The
# false-positive floor is the class of genuine preference/decision questions
# asked without a read; the nudge is written to be self-defeating there ("ask
# only what the code cannot tell you") so a misfire costs the agent one glance.
#
# PreToolUse DOES fire for AskUserQuestion in this harness (verified against
# recorded transcripts: hookName "PreToolUse:AskUserQuestion"). If a future
# harness stops delivering it, this hook simply never runs — it fails silent.
#
# Output contract: {hookSpecificOutput:{hookEventName:"PreToolUse",
# additionalContext:<msg>}} on stdout, exit 0 always. Silent exit 0 on any
# doubt (no jq/python3, no transcript, muted, not AskUserQuestion, turn too long
# to delimit).
#
# Mute:          touch ~/.claude/.no-lazy-question-gate
# One-shot skip: LAZY_QUESTION_OFF=1
# Telemetry:     warn-log.sh --hook guard-lazy-question --action nudge

set -uo pipefail

INPUT=$(cat 2>/dev/null || echo "{}")
command -v jq >/dev/null 2>&1 || exit 0
printf '%s' "$INPUT" | jq empty 2>/dev/null || exit 0

# Mute honored early — before any real work.
[ "${LAZY_QUESTION_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.no-lazy-question-gate" ] && exit 0

TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')
[ "$TOOL" = "AskUserQuestion" ] || exit 0

TX=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty')
[ -n "$TX" ] && [ -f "$TX" ] || exit 0

command -v python3 >/dev/null 2>&1 || exit 0

# Scan the current turn for a code-read. Prints exactly one of:
#   READ    — a read/grep/glob/code-reading-bash was seen this turn → informed
#   NOREAD  — turn delimited, no read seen → lazy-question candidate
#   UNKNOWN — could not delimit the turn within the window → stay silent (safe)
verdict=$(CLAUDE_LQ_TX="$TX" python3 <<'PY' 2>/dev/null || echo UNKNOWN
import json, os, re
from collections import deque

tx = os.environ.get("CLAUDE_LQ_TX", "")
if not tx:
    print("UNKNOWN"); raise SystemExit

# Bounded tail — a turn essentially never exceeds this many transcript entries,
# and reads that make a question "informed" land well within it. Reading via a
# maxlen deque keeps memory flat regardless of transcript size.
WINDOW = 900
try:
    with open(tx, encoding="utf-8", errors="replace") as f:
        lines = deque(f, maxlen=WINDOW)
except Exception:
    print("UNKNOWN"); raise SystemExit

# Injected/synthetic "user" entries are NOT real human turn boundaries — the
# agent's read may precede such an interruption, so we scan through them.
SYNTHETIC_PREFIXES = (
    "<task-notification>", "<system-reminder>", "Stop hook feedback:",
    "Caveat:", "This session is being continued", "[api-recovery]",
    "<post-compact", "<local-command", "<command-name>",
)

def real_user_prompt(o):
    if o.get("type") != "user":
        return False
    m = o.get("message")
    if not isinstance(m, dict) or m.get("role") != "user":
        return False
    c = m.get("content")
    if isinstance(c, str):
        text = c
    elif isinstance(c, list):
        if any(isinstance(x, dict) and x.get("type") == "tool_result" for x in c):
            return False  # tool result, not a human prompt
        text = " ".join(
            x.get("text", "") for x in c
            if isinstance(x, dict) and x.get("type") == "text"
        )
    else:
        return False
    t = text.lstrip()
    return not any(t.startswith(p) for p in SYNTHETIC_PREFIXES)

READ_TOOLS = {"Read", "Grep", "Glob", "LS", "NotebookRead"}
# Bash sub-commands that inspect file/code content (NOT git status, NOT mkdir…).
BASH_READ_RE = re.compile(
    r'(?:^|[|;&]|\s)(?:cat|rg|grep|egrep|fgrep|fd|find|head|tail|less|more|bat|'
    r'sed|awk|nl|wc|column|jq|yq|xxd|od|strings|ripgrep)\b'
    r'|git\s+(?:diff|show|log|grep|blame)'
    r'|(?:^|[|;&]|\s)ls\b'
)

found_read = False
delimited = False
for raw in reversed(lines):
    raw = raw.strip()
    if not raw:
        continue
    try:
        o = json.loads(raw)
    except Exception:
        continue
    if real_user_prompt(o):
        delimited = True
        break
    if o.get("type") == "assistant":
        m = o.get("message", {})
        c = m.get("content") if isinstance(m, dict) else None
        if isinstance(c, list):
            for blk in c:
                if not (isinstance(blk, dict) and blk.get("type") == "tool_use"):
                    continue
                name = blk.get("name", "")
                if name in READ_TOOLS:
                    found_read = True
                    break
                if name == "Bash":
                    cmd = ""
                    inp = blk.get("input")
                    if isinstance(inp, dict):
                        cmd = inp.get("command", "") or ""
                    if BASH_READ_RE.search(cmd):
                        found_read = True
                        break
    if found_read:
        break

if found_read:
    print("READ")
elif delimited:
    print("NOREAD")
else:
    # Window exhausted without hitting a human prompt: a turn this long is
    # almost certainly informed. Default silent (FP-safe).
    print("UNKNOWN")
PY
)

[ "$verdict" = "NOREAD" ] || exit 0

msg="[lazy-question] You are asking the user a question but did NOT read/grep the codebase this turn. If any part of this is answerable from the code (which file, which pattern, current value, existing convention, whether X already exists), check first — ask only what the code cannot tell you. If it is a genuine preference / design / user-intent call the code can't answer, proceed.  →→ SURFACE this to the user in your reply as a bordered callout (rules/surface-hook-nudges-to-user.md). (mute: touch ~/.claude/.no-lazy-question-gate)"

jq -n --arg c "$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse", additionalContext:$c}}'
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-lazy-question --action nudge --heeded unknown >/dev/null 2>&1 || true
exit 0
