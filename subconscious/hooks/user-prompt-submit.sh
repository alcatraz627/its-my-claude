#!/bin/bash
# i-dream: UserPromptSubmit hook — captures conversational sentiment signals
# NOTE: stdout is injected into the user message by Claude Code.
#       This script MUST emit nothing to stdout.
SOCKET="/Users/alcatraz627/.claude/subconscious/daemon.sock"
if [ ! -S "$SOCKET" ]; then exit 0; fi

# Save stdin before it is consumed; pass prompt and socket path to Python via env vars
HOOK_INPUT=$(cat)

# Analyze and send a user_signal event to the daemon (best-effort, no stdout)
IDREAM_INPUT="$HOOK_INPUT" IDREAM_SOCKET="$SOCKET" python3 << 'PYEOF' 2>/dev/null || true
import sys, re, json, time, os, socket as _sock

raw = os.environ.get("IDREAM_INPUT", "")
sock_path = os.environ.get("IDREAM_SOCKET", "")
if not raw or not sock_path:
    sys.exit(0)
try:
    data = json.loads(raw)
    prompt = data.get("prompt", "")
except Exception:
    sys.exit(0)

if not prompt:
    sys.exit(0)

# ALL-CAPS words (≥2 letters) — proxy for emphasis or frustration
uppercase_words = len(re.findall(r"\b[A-Z]{2,}\b", prompt))

# Frustration and swear word detection
swear_re = re.compile(
    r"\b(wtf|what\s+the\s+f(?:uck)?|fuck(?:ing)?|shit|bullshit|damn(?:it)?|"
    r"crap|imbecile|idiot|moron|stupid|dumb|awful|terrible|horrible|broken|"
    r"worst|useless|garbage|trash|ridiculous|absurd|pathetic)\b",
    re.IGNORECASE
)
swear_count = len(swear_re.findall(prompt))

# Correction / pushback signals
correction_re = re.compile(
    r"(no,?\s+that|wrong[.! ]|undo\s+this|revert\s+this|not\s+right|"
    r"not\s+what\s+i\s+want|i\s+said\b|try\s+again|go\s+back|start\s+over|"
    r"you\s+misunderstood|not\s+correct|please\s+fix|you.?re\s+wrong|"
    r"that.?s\s+wrong|no\s+no\b|stop\s+doing|i\s+didn.?t\s+ask)",
    re.IGNORECASE
)
correction = bool(correction_re.search(prompt))

# Positive feedback signals
positive_re = re.compile(
    r"(perfect[.! ]|exactly[.! ]|great\s+job|well\s+done|"
    r"that.?s\s+(?:right|correct|perfect)|yes,?\s+that|"
    r"good\s+work|nice\s+work|thank\s*(?:s|\s+you)|"
    r"brilliant|excellent|nailed\s+it|love\s+it|that\s+works|"
    r"awesome|fantastic|spot\s+on)",
    re.IGNORECASE
)
positive = bool(positive_re.search(prompt))

# Composite frustration score [0.0, 1.0]
score = 0.0
if swear_count > 0:     score += min(0.5, swear_count * 0.2)
if uppercase_words > 0: score += min(0.3, uppercase_words * 0.1)
if correction:          score += 0.3
frustration_score = round(min(1.0, score), 2)

ts = int(time.time())
payload = json.dumps({
    "event": "user_signal",
    "ts": ts,
    "uppercase_words": uppercase_words,
    "swear_count": swear_count,
    "correction": correction,
    "positive": positive,
    "frustration_score": frustration_score
}).encode()

try:
    s = _sock.socket(_sock.AF_UNIX)
    s.connect(sock_path)
    s.sendall(payload)
    s.close()
except Exception:
    pass
PYEOF
# Touch activity signal (always, regardless of socket availability)
touch "/Users/alcatraz627/.claude/subconscious/.last-activity"
