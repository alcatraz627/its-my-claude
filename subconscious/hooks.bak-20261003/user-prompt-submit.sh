#!/bin/bash
# i-dream: UserPromptSubmit hook — sentiment signals + compiled-intervention
# hints (felt-metabolism Phase 2).
# NOTE: this hook is registered async, and an async UserPromptSubmit hook's stdout
#       never reaches the model (verified 2026-09-05). It therefore emits NOTHING
#       to stdout; LIVE intervention hints reach the model through the sync
#       PreToolUse sibling, and every match is still written to the would-fire
#       ledger here.
# No daemon-up guard here on purpose: the sentiment send needs the socket,
# but the intervention interpreter is file-only and must run regardless.
SOCKET="/Users/alcatraz627/.claude/subconscious/daemon.sock"

# Save stdin before it is consumed; pass prompt and socket path to Python via env vars
HOOK_INPUT=$(cat)

# Analyze and send a user_signal event to the daemon (best-effort, no stdout)
IDREAM_INPUT="$HOOK_INPUT" IDREAM_SOCKET="$SOCKET" python3 << 'PYEOF' 2>/dev/null || true
import sys, re, json, time, os, socket as _sock

raw = os.environ.get("IDREAM_INPUT", "")
sock_path = os.environ.get("IDREAM_SOCKET", "")
if not raw:
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
    s.sendall(payload + b"\n")
    s.close()
except Exception:
    pass

# ── Compiled-intervention interpreter (felt-metabolism B1, prompt surface) ──
# LIVE hints inject one additionalContext JSON (display capped at 2); every
# match — shadow, candidate, AND live — is appended to the would-fire ledger,
# because display caps must never gate telemetry. Patterns are re-validated
# here with re.search inside try/except: a broken compiler-drafted pattern
# skips silently rather than firing wrong (the point-of-use check).
try:
    import os.path as _p
    import signal as _sig
    ipath = _p.expanduser("~/.claude/i-dream/interventions.json")
    if _p.exists(ipath):
        items = json.load(open(ipath))
        cwd = data.get("cwd", "") or ""
        proj = _p.basename(cwd.rstrip("/")) if cwd else ""
        sid = data.get("session_id", "") or ""
        live_hits, shadow_hits = [], []
        # ReDoS guard (validation MAJOR-1): compiler-authored patterns get a
        # hard 2s budget for the WHOLE match loop and a capped subject — a
        # catastrophic pattern aborts to the silent-skip path (exit 0, no
        # stdout) instead of stalling this blocking hook.
        def _rex_abort(_s, _f):
            raise TimeoutError()
        _sig.signal(_sig.SIGALRM, _rex_abort)
        _sig.alarm(2)
        subject = prompt[:4000]
        for it in items:
            if it.get("form") != "hint":
                continue
            trg = it.get("trigger") or {}
            tp = trg.get("project")
            if tp and tp != proj:
                continue
            pat = trg.get("prompt_pattern")
            if not pat:
                continue
            try:
                if not re.search(pat, subject, re.IGNORECASE):
                    continue
            except TimeoutError:
                raise
            except Exception:
                continue
            (live_hits if it.get("state") == "live" else shadow_hits).append(it)
        _sig.alarm(0)
        if live_hits or shadow_hits:
            try:
                with open(_p.expanduser("~/.claude/i-dream/would-fire.jsonl"), "a") as f:
                    for it in shadow_hits + live_hits:
                        f.write(json.dumps({"id": it.get("id", ""), "sid": sid,
                            "state": it.get("state", ""), "surface": "prompt",
                            "ts": int(time.time())}) + "\n")
            except Exception:
                pass
        # LIVE hints used to print one additionalContext JSON here. This hook is
        # registered async on UserPromptSubmit and the harness never returns that
        # stdout (canary 2026-09-05: zero deliveries in any transcript), so the
        # owner ruled to strip the payload and keep the ledger above. The sync
        # PreToolUse sibling (pre-tool-use.sh) still delivers hints at tool time.
        # To revive prompt-time hints, register this hook synchronous and print
        # json.dumps({"additionalContext": ...}) here again.
except Exception:
    pass
PYEOF
# Touch activity signal (always, regardless of socket availability)
touch "/Users/alcatraz627/.claude/subconscious/.last-activity"
