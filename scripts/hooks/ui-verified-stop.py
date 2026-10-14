#!/usr/bin/env python3
"""Refuses a reply that calls a UI change verified, done or working when nobody
looked at it.

The failure it stops: an agent edits a page, checks properties it chose itself,
and reports "verified" while the defects the owner sees are on screen in the first
screenshot. Six S3 atones in one session (2026-08-26) had that shape, and the
advisory rule did not bind (prop-20260826-093335-6e).

Stop hook. Blocks once per distinct reply when all three hold in the current turn:
a UI file (html, css, scss, js, jsx, tsx, vue, svelte) was edited; no image reached
the model after the last such edit (a Read of an image, or a screenshot tool that
returns one); and the final reply claims verified, works, fixed or looks right.
Writing "not looked at" or "UNCONFIRMED" beside the claim is the honest way
through. Sibling: declared-ready-stop.sh only nudges on style edits and counts a
screenshot taken but never read as seen. Mute: touch ~/.claude/.no-ui-verified-gate
"""
import hashlib, json, os, re, subprocess, sys

HOME = os.path.expanduser("~")
if os.path.exists(os.path.join(HOME, ".claude", ".no-ui-verified-gate")):
    sys.exit(0)
try:
    inp = json.load(sys.stdin)
except ValueError:
    sys.exit(0)
if not isinstance(inp, dict):
    sys.exit(0)
if inp.get("stop_hook_active"):
    sys.exit(0)
tp = inp.get("transcript_path") or ""
if not os.path.isfile(tp):
    sys.exit(0)

recs = []
with open(tp, errors="replace") as fh:
    for line in fh.readlines()[-4000:]:
        try:
            recs.append(json.loads(line))
        except ValueError:
            pass


def content_of(r):
    c = (r.get("message") or {}).get("content")
    return c if isinstance(c, list) else ([{"type": "text", "text": c}] if isinstance(c, str) else [])


HARNESS = re.compile(r"^\s*(<system-reminder>|\[Image:|<command-name>|<local-command|Caveat:|<task-notification>"
                     r"|\[keepwarm\]|Base directory for this skill:|Stop hook feedback:)")
start = None
for i in range(len(recs) - 1, -1, -1):
    r = recs[i]
    if r.get("type") != "user":
        continue
    bs = [b for b in content_of(r) if isinstance(b, dict)]
    if any(b.get("type") == "tool_result" for b in bs):
        continue
    t = "".join(b.get("text", "") for b in bs if b.get("type") == "text").strip()
    if t and not HARNESS.match(t):
        start = i
        break
if start is None:
    sys.exit(0)

# Markup and style files are UI wherever they live; a .js file only in a UI-looking
# directory, because most .js here is scripts and hooks.
UI = re.compile(r"\.(html?|css|scss|jsx|tsx|vue|svelte)$"
                r"|/(src|components|pages|public|static|app|web|ui|frontend|views|kanban)/[^/]*\.js$", re.I)
# A shell command that rewrites a markup or style file: sed -i, a redirect, tee.
BASH_WRITE = re.compile(r"(sed\s+-i\S*\s[^;&|]*|>{1,2}\s*|\btee\s+(-a\s+)?)\S*\.(html?|css|scss|jsx|tsx|vue|svelte)\b", re.I)
last_edit, last_seen, reply = -1, -1, ""
for i, r in enumerate(recs[start:], start):
    for b in content_of(r):
        if not isinstance(b, dict):
            continue
        kind = (r.get("type"), b.get("type"))
        if kind == ("assistant", "tool_use") and b.get("name") in ("Edit", "Write", "MultiEdit") \
                and UI.search((b.get("input") or {}).get("file_path") or ""):
            last_edit = i
        elif kind == ("assistant", "tool_use") and b.get("name") == "Bash" \
                and BASH_WRITE.search((b.get("input") or {}).get("command") or ""):
            last_edit = i
        elif kind == ("user", "tool_result"):
            c = b.get("content")
            if isinstance(c, list) and any(isinstance(x, dict) and x.get("type") == "image" for x in c):
                last_seen = i
        elif kind == ("assistant", "text") and b.get("text", "").strip():
            reply = b["text"]
if last_edit < 0 or last_seen > last_edit or not reply:
    sys.exit(0)

prose = re.sub(r"`[^`\n]*`", "", re.sub(r"```.*?```", "", reply, flags=re.S))
claim = re.search(r"\b((?<!not )(?<!un)verified|(it|this|that|now|everything) works|works now|is working"
                  r"|(is|are|now) fixed|fixed (it|the|this|that)|fixed(?=[.!])|looks (right|good|correct)"
                  r"|renders (correctly|fine))\b", prose, re.I)
honest = re.search(r"not looked at|UNCONFIRMED|not (yet )?(verified|looked|checked)|unverified"
                   r"|ha(ve|s)( not|n't) (been )?(verified|looked|checked)", prose, re.I)
if not claim or honest:
    sys.exit(0)

state = f"/tmp/claude-uiverified-{(inp.get('session_id') or 'x')[:8]}"
h = hashlib.sha1(reply.encode()).hexdigest()[:12]
try:
    if open(state).read().strip() == h:
        sys.exit(0)
except OSError:
    pass
with open(state, "w") as f:
    f.write(h)
subprocess.run(["bash", os.path.join(HOME, ".claude/scripts/hooks/warn-log.sh"), "--hook", "ui-verified",
                "--action", "block", "--heeded", "unknown"], capture_output=True)
print(json.dumps({"decision": "block", "reason":
    f"[ui-verified] The reply says \"{claim.group(0)}\" about a UI change, but no image reached you after the last "
    "UI edit this turn. Take a screenshot and read it (describe the frame first), or write \"not looked at\" beside "
    "the claim. rules/ui-visual-verification.md. Mute: touch ~/.claude/.no-ui-verified-gate"}))
