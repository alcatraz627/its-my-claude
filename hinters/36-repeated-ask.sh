#!/usr/bin/env bash
# 36-repeated-ask.sh — UserPromptSubmit hinter: the user says they already asked.
#
# Shape 7 of rules/literal-request-over-intent.md: "a repeated or escalating ask
# means the last answer missed." When a request comes back louder, the signal is not
# that the user wants more effort in the same register. It is that the previous reply
# did not deliver what was asked. Recorded failure: three escalating asks for a UI
# pass answered with reviews and micro-fixes (atone mist-20260811-142119-a5, S3).
#
# WHAT IT KEYS ON, AND WHY NOT THE OBVIOUS THING. The obvious detector is lexical
# overlap with a recent prompt. It was built and measured against 794 real prompts
# and rejected:
#
#   overlap >=4 words, ratio >=0.6   8.44%   mostly topic follow-ups
#   overlap >=6 words, ratio >=0.8   5.67%   quieter, but silent on the S3 case
#   length-aware (short 3/0.6)       9.19%   worse; short prompts share generic words
#
# The two shapes have opposite sizes. The S3 case is a SHORT escalating ask sharing
# three words; the false positives are LONG follow-ups sharing many words by topic
# alone. No single overlap threshold separates them, because the real signal is not
# lexical similarity at all. It is that the user is restating something already
# answered badly, which needs knowing what the answer was.
#
# So this keys on the user SAYING SO. "I asked", "as I said", "again:", "you still
# didn't". Measured on the same corpus: 0.41%, three fires, all three genuine, one
# of them verbatim shape 7 ("No I asked you IF the session start hook entry..."). A
# topical link to a recent prompt is still required, so a fresh complaint about
# something unrelated stays quiet.
#
# Sibling, not overlap. 35-correction-loop.sh measures correction DENSITY over a
# window and says so in its own header ("not same-issue semantics"); it suggests a
# fresh session. This fires on one explicit escalation and says re-read the ask.
#
# State: /tmp/claude-repeatask-<sid8> — one normalized prompt per line, last 8.
# Mute: touch ~/.claude/.no-repeated-ask (machine-wide, like every .no-* mute).

set -uo pipefail
PROMPT=$(cat 2>/dev/null || echo "")
[ -z "$PROMPT" ] && exit 0
[ -f "$HOME/.claude/.no-repeated-ask" ] && exit 0

# CLAUDE_HINT_SID is exported by hint-injector.sh from the hook payload. The date
# fallback pools concurrent sessions, so it is a last resort rather than a default.
SID="${CLAUDE_HINT_SID:-${CLAUDE_SESSION_ID:-}}"
[ -n "$SID" ] || SID="nosid-$(date +%Y-%m-%d)"
STATE="/tmp/claude-repeatask-${SID:0:8}"

python3 - "$PROMPT" "$STATE" <<'PY'
import os, re, sys

prompt, state = sys.argv[1], sys.argv[2]

# Most "user" turns in this account's transcripts are machine-generated: skill
# invocations, hook feedback, task notifications, peer mail, compaction notices,
# bash-mode echoes. Excluding only the four obvious shapes left the overlap
# prototype at 27%, nearly all of it these. None is a person asking twice.
if re.match(r"^\s*(<system-reminder>|\[Image:|<command-name>|<local-command|Caveat:"
            r"|Base directory for this skill:|Stop hook feedback:|<task-notification>"
            r"|<teammate-message|Another Claude session sent a message:"
            r"|This session is being continued|A session-scoped Stop hook"
            r"|<cross-session-message|PreToolUse:|PostToolUse:|<user-prompt-submit-hook>"
            r"|<bash-input>|<bash-stdout>|<bash-stderr>|\[Request interrupted)", prompt, re.I):
    sys.exit(0)

# The user stating outright that this is not the first time.
ESCALATION = re.compile(
    r"\b(i (already |just )?(asked|said|told you)|as i (said|asked|mentioned)"
    r"|i'?ve (asked|said|told)|for the (second|third|last) time"
    r"|like i said|you (still |keep )?(missed|ignored|didn'?t)|that'?s not what i)\b"
    # "again:" / "again," ends in punctuation, so it cannot sit inside the shared
    # trailing \b (review 2026-08-18, I5): it gets its own arm.
    r"|\bagain[:,]", re.I)

STOP = set("""a an the and or but if then so of to in on at for with by from as is are was were
be been being do does did doing have has had having i you it this that these those we they me my
your our their can could should would will shall may might must not no yes just now also very
please lets let s t re ve ll d m""".split())

def words(t):
    t = re.sub(r"```.*?```", " ", t, flags=re.S)      # code blocks are not the ask
    t = re.sub(r"`[^`]*`", " ", t)
    t = re.sub(r"[^a-z0-9\s]", " ", t.lower())
    return [w for w in t.split() if w not in STOP and len(w) > 2]

cur = words(prompt)
prev = []
if os.path.exists(state):
    try:
        prev = [l.rstrip("\n") for l in open(state) if l.strip()]
    except Exception:
        prev = []

hit = None
if len(cur) >= 3 and ESCALATION.search(prompt):
    cs = set(cur)
    for i, line in enumerate(reversed(prev)):      # i=0 is the most recent
        ps = set(line.split())
        if len(ps) < 3:
            continue
        # Only a topical link, not similarity. The escalation phrase already carries
        # the signal; this just confirms it is about something we have discussed,
        # so a fresh complaint on a new subject does not trip it.
        if len(cs & ps) >= 2:
            hit = (i + 1, sorted(cs & ps)[:5])
            break

# Persist regardless of whether we fired, keeping the last 8.
try:
    with open(state, "w") as f:
        for line in (prev + [" ".join(cur)])[-8:]:
            f.write(line + "\n")
except Exception:
    pass

if hit:
    turns_ago, shared = hit
    ago = "your previous prompt" if turns_ago == 1 else f"a prompt {turns_ago} back"
    print(f"[repeated-ask] This reads as a re-ask of {ago} (shared: {', '.join(shared)}). "
          f"Per rules/literal-request-over-intent.md shape 7, an ask arriving again means the last "
          f"answer missed, not that it needed more of the same. Do not answer again in the same "
          f"register with more effort. Work out what was asked that you did not deliver, and say "
          f"what you are doing differently. The instrument for this is /intake: run it on the ask "
          f"before answering. (mute: touch ~/.claude/.no-repeated-ask)")
PY
exit 0
