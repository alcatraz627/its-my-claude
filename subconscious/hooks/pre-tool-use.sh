#!/bin/bash
# i-dream's own background claude calls carry I_DREAM_CHILD=1; their hooks must
# not feed the daemon (it was downvoting its own intentions, 2026-10-06).
[ -n "${I_DREAM_CHILD:-}" ] && exit 0
case "${CLAUDE_CODE_ENTRYPOINT:-}" in ""|cli|claude-vscode) ;; *) exit 0 ;; esac
# i-dream: PreToolUse hook — compiled-intervention nudges (advisory only).
# stdout carries at most one hookSpecificOutput/additionalContext JSON.
HOOK_INPUT=$(cat)
IDREAM_INPUT="$HOOK_INPUT" python3 << 'PYEOF' 2>/dev/null || true
import sys, re, json, time, os, hashlib
import os.path as _p

raw = os.environ.get("IDREAM_INPUT", "")
if not raw:
    sys.exit(0)
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)

tool =data.get("tool_name", "") or ""
ipath = _p.expanduser("~/.claude/i-dream/interventions.json")
if not tool or not _p.exists(ipath):
    sys.exit(0)
try:
    items = json.load(open(ipath))
except Exception:
    sys.exit(0)

ti = data.get("tool_input") or {}
target = ""
for k in ("command", "file_path", "path", "url"):
    v = ti.get(k)
    if isinstance(v, str) and v:
        target = v
        break
cwd = data.get("cwd", "") or ""
proj = _p.basename(cwd.rstrip("/")) if cwd else ""
sid = data.get("session_id", "") or ""

live, shadow = [], []
# ReDoS guard (validation MAJOR-1): a catastrophic compiler-authored pattern
# aborts the whole match loop within 2s — silent exit 0, no stdout — instead
# of stalling the tool call. Subject capped as the second belt.
import signal as _sig
def _rex_abort(_s, _f):
    raise TimeoutError()
_sig.signal(_sig.SIGALRM, _rex_abort)
_sig.alarm(2)
subject = target[:4000]
try:
    for it in items:
        if it.get("form") != "nudge":
            continue
        trg = it.get("trigger") or {}
        if trg.get("tool") != tool:
            continue
        tp = trg.get("project")
        if tp and tp != proj:
            continue
        pat = trg.get("input_pattern")
        if pat:
            # Point-of-use validation: a broken compiler-drafted pattern
            # skips silently rather than firing wrong.
            try:
                if not re.search(pat, subject, re.IGNORECASE):
                    continue
            except TimeoutError:
                raise
            except Exception:
                continue
        (live if it.get("state") == "live" else shadow).append(it)
except TimeoutError:
    sys.exit(0)
_sig.alarm(0)

if not live and not shadow:
    sys.exit(0)
# Every match is ledgered (display caps never gate telemetry).
try:
    with open(_p.expanduser("~/.claude/i-dream/would-fire.jsonl"), "a") as f:
        for it in shadow + live:
            f.write(json.dumps({"id": it.get("id", ""), "sid": sid,
                "state": it.get("state", ""), "surface": "tool",
                "tool": tool, "ts": int(time.time())}) + "\n")
except Exception:
    pass
def _first_time(it):
    # Once per nudge per session: the same nudge on every Write was the bulk
    # of the noise. Atomic create, so concurrent tool calls cannot both win.
    sid8 = "".join(c for c in sid[:64] if c.isalnum() or c in "-_")
    if not sid8:
        return True
    d = _p.expanduser("~/.claude/.inject-once/idream-nudge/s-" + sid8)
    key = hashlib.sha1(str(it.get("id", "")).encode("utf-8", "replace")).hexdigest()[:16]
    try:
        os.makedirs(d, exist_ok=True)
        os.close(os.open(_p.join(d, key), os.O_CREAT | os.O_EXCL | os.O_WRONLY))
    except FileExistsError:
        return False
    except Exception:
        pass
    return True

shown = []
for it in live:
    if _first_time(it):
        shown.append(it)
    if len(shown) == 2:
        break
if shown:
    lines = ["[i-dream:%s] %s" % (str(it.get("id", ""))[:8], it.get("body", ""))
             for it in shown]
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": "\n".join(lines)}}))
PYEOF
exit 0
