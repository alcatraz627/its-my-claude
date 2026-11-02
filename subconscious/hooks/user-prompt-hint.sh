#!/bin/bash
# i-dream's own background claude calls carry I_DREAM_CHILD=1; their hooks must
# not feed the surface (it was downvoting its own intentions, 2026-10-06).
[ -n "${I_DREAM_CHILD:-}" ] && exit 0
# Hints are for a person at a terminal or editor; headless runs (claude -p
# linters, jurors) only pay for them. Mirrors events::is_interactive_entrypoint.
case "${CLAUDE_CODE_ENTRYPOINT:-}" in ""|cli|claude-vscode) ;; *) exit 0 ;; esac
# i-dream: UserPromptSubmit hint hook, registered SYNCHRONOUS (no "async").
# stdout carries at most one hookSpecificOutput/additionalContext JSON.
# Mute: touch ~/.claude/.no-idream-hints
exec 2>/dev/null
[ -f "$HOME/.claude/.no-idream-hints" ] && exit 0
HOOK_INPUT=$(cat)
IDREAM_INPUT="$HOOK_INPUT" python3 << 'PYEOF' || true
import sys, re, json, time, os, hashlib
import os.path as _p

raw = os.environ.get("IDREAM_INPUT", "")
if not raw:
    sys.exit(0)
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)
prompt = data.get("prompt", "") or ""
if not isinstance(prompt, str) or not prompt:
    sys.exit(0)
# Machine-written prompts (task notifications, seat briefs) are not the owner
# talking, whatever the entrypoint says.
if prompt.lstrip().startswith(("<task-notification>", "You are", "You enforce")):
    sys.exit(0)

cwd = data.get("cwd", "") or ""
proj = _p.basename(cwd.rstrip("/")) if cwd else ""
sid = data.get("session_id", "") or ""

def _rules():
    # The daemon answers with the rules this prompt is about, and spends their
    # fires only after writing them. Give up quickly: a prompt must never wait.
    import socket
    words = sorted({w.lower() for w in re.findall(r"[A-Za-z][A-Za-z-]{3,}", prompt[:4000])})[:400]
    try:
        s = socket.socket(socket.AF_UNIX)
        s.settimeout(1.0)
        s.connect("/Users/alcatraz627/.claude/subconscious/daemon.sock")
        s.sendall((json.dumps({"event": "prompt_rules", "session_id": sid, "cwd": cwd,
            "entrypoint": os.environ.get("CLAUDE_CODE_ENTRYPOINT") or None,
            "prompt_words": words}) + "\n").encode())
        reply = b""
        while True:
            chunk = s.recv(65536)
            if not chunk:
                break
            reply += chunk
        s.close()
        return [l for l in reply.decode("utf-8", "replace").splitlines() if l.strip()]
    except Exception:
        return []

def _finish(hints):
    # Hints and rules travel in one block: the harness reads one JSON object.
    lines = hints + _rules()
    if lines:
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": "\n".join(lines)}}))
    sys.exit(0)

ipath = _p.expanduser("~/.claude/i-dream/interventions.json")
try:
    items = json.load(open(ipath))
except Exception:
    _finish([])

# ReDoS guard: compiler-authored patterns get a hard 2s budget for the whole
# match loop and a capped subject. A catastrophic pattern aborts to a silent
# exit 0 instead of stalling the prompt.
import signal as _sig
def _rex_abort(_s, _f):
    raise TimeoutError()
_sig.signal(_sig.SIGALRM, _rex_abort)
_sig.alarm(2)
subject = prompt[:4000]
live, shadow = [], []
try:
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
        # Point-of-use validation: a broken pattern skips rather than firing wrong.
        try:
            if not re.search(pat, subject, re.IGNORECASE):
                continue
        except TimeoutError:
            raise
        except Exception:
            continue
        (live if it.get("state") == "live" else shadow).append(it)
except TimeoutError:
    _finish([])
_sig.alarm(0)

if not live and not shadow:
    _finish([])
# Every match is ledgered (display caps never gate telemetry).
try:
    with open(_p.expanduser("~/.claude/i-dream/would-fire.jsonl"), "a") as f:
        for it in shadow + live:
            f.write(json.dumps({"id": it.get("id", ""), "sid": sid,
                "state": it.get("state", ""), "surface": "prompt",
                "ts": int(time.time())}) + "\n")
except Exception:
    pass

# Hints that say the same thing about a bare "continue": show at most one.
FAMILIES = [("e454d031", "8c24512f", "65cfe4c2")]
def _family(it):
    i8 = str(it.get("id", ""))[:8]
    for n, fam in enumerate(FAMILIES):
        if i8 in fam:
            return n
    return None

def _first_time(it):
    # Atomic create: a concurrent prompt in the same session cannot both win.
    sid8 = "".join(c for c in sid[:64] if c.isalnum() or c in "-_")
    if not sid8:
        return True
    d = _p.expanduser("~/.claude/.inject-once/idream-hint/s-" + sid8)
    key = hashlib.sha1(str(it.get("id", "")).encode("utf-8", "replace")).hexdigest()[:16]
    try:
        os.makedirs(d, exist_ok=True)
        os.close(os.open(_p.join(d, key), os.O_CREAT | os.O_EXCL | os.O_WRONLY))
    except FileExistsError:
        return False
    except Exception:
        pass
    return True

shown, fams = [], set()
for it in live:
    fam = _family(it)
    if fam is not None and fam in fams:
        continue
    if not _first_time(it):
        continue
    if fam is not None:
        fams.add(fam)
    shown.append(it)
    if len(shown) == 2:
        break
_finish(["[i-dream:%s] %s" % (str(it.get("id", ""))[:8], it.get("body", ""))
         for it in shown])
PYEOF
exit 0
