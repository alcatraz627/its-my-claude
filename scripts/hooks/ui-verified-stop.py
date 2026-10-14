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
screenshot taken but never read as seen.

Second check (owner D5, 2026-10-15): when the image WAS read but the reply gives the
verdict without first describing what is on screen, that is a warning, not a block:
the frame description is what proves the image was read, and the owner wants the
agent to weigh it. The warning reaches the owner as a systemMessage now and the agent
as context on the next prompt (ui-verified-hint.sh), because a Stop hook has no
non-blocking channel to the agent. It escalates to a block once the atone ledger
holds 3 or more events in the UI-verification slugs (UI_SLUGS) within 14 days: the
slug of record is shipping-css-ui-changes-without-visual-verification, plus its
render-not-read siblings. A frame description is, before the claim, at least 80
characters of prose that carries a seeing word (screenshot, frame, on screen, I see,
shows, displays, visible, rendered).

Heed: a later UI claim that carries the image, or a frame description, after a fire
records heeded:true; the same shortfall again records heeded:false.
Mute: touch ~/.claude/.no-ui-verified-gate
"""
import datetime, hashlib, json, os, re, subprocess, sys

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
# The Stop input carries the reply that just ended the turn; the transcript tail lags
# one message at Stop time, so a reply read from it is the previous one.
reply = inp.get("last_assistant_message") or reply
if last_edit < 0 or not reply:
    sys.exit(0)

prose = re.sub(r"`[^`\n]*`", "", re.sub(r"```.*?```", "", reply, flags=re.S))
claim = re.search(r"\b((?<!not )(?<!un)verified|(it|this|that|now|everything) works|works now|is working"
                  r"|(is|are|now) fixed|fixed (it|the|this|that)|fixed(?=[.!])|looks (right|good|correct)"
                  r"|renders (correctly|fine))\b", prose, re.I)
honest = re.search(r"not looked at|UNCONFIRMED|not (yet )?(verified|looked|checked)|unverified"
                   r"|ha(ve|s)( not|n't) (been )?(verified|looked|checked)", prose, re.I)
if not claim or honest:
    sys.exit(0)

LOG = os.path.join(HOME, ".claude/scripts/hooks/warn-log.sh")
sid8 = (inp.get("session_id") or "x")[:8]
state = f"/tmp/claude-uiverified-{sid8}"
fired = f"/tmp/claude-uiverified-fired-{sid8}"     # the last fire, for heed: "block" or "frame"
reply_hash = hashlib.sha1(reply.encode()).hexdigest()[:12]


def log_row(*args):
    subprocess.run(["bash", LOG, "--hook", "ui-verified", *args], capture_output=True)


def record_heed(verdict):
    log_row("--heed-of", f"ui-verified:{sid8}", "--heeded", verdict)
    try:
        os.remove(fired)
    except OSError:
        pass


def already_said(path):
    try:
        return open(path).read().strip() == reply_hash
    except OSError:
        return False


def remember(path):
    with open(path, "w") as f:
        f.write(reply_hash)


if last_seen <= last_edit:
    # Nobody looked. Unchanged: block once per distinct reply.
    if already_said(state):
        sys.exit(0)
    remember(state)
    if os.path.exists(fired):
        record_heed("false")
    open(fired, "w").write("block")
    log_row("--action", "block", "--heeded", "unknown")
    print(json.dumps({"decision": "block", "reason":
        f"[ui-verified] The reply says \"{claim.group(0)}\" about a UI change, but no image reached you after the last "
        "UI edit this turn. Take a screenshot and read it (describe the frame first), or write \"not looked at\" beside "
        "the claim. rules/ui-visual-verification.md. Mute: touch ~/.claude/.no-ui-verified-gate"}))
    sys.exit(0)

# An image was read after the last UI edit. Did the reply describe the frame first?
before = prose[:claim.start()]
SEEING = re.compile(r"\b(screenshots?|screen ?shots?|frames?|on[- ]screen|i (can )?see|i saw|i read|shows?|showing|shown"
                    r"|displays?|displaying|visible|rendered|renders)\b", re.I)
if len(before.strip()) >= 80 and SEEING.search(before):
    if os.path.exists(fired):
        record_heed("true")
    sys.exit(0)

if already_said(state + "-frame"):
    sys.exit(0)
remember(state + "-frame")
if os.path.exists(fired):
    record_heed("false")

UI_SLUGS = {"shipping-css-ui-changes-without-visual-verification", "ui-verified-by-dom-read-not-render",
            "ui-verified-by-console-not-by-reading-the-render", "ui-verdict-from-clipped-screenshot",
            "ui-claim-without-comparing-against-the-previous-render",
            "documented-gesture-as-working-without-driving-it"}
ESCALATE_AT, WINDOW_DAYS = 3, 14
cutoff = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=WINDOW_DAYS)).strftime("%Y-%m-%dT%H:%M:%SZ")
n_atones = 0
try:
    for line in open(os.environ.get("ATONE_EVENTS_FILE") or os.path.join(HOME, ".claude/atone/events.jsonl"), errors="replace"):
        if '"slug"' not in line:
            continue
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("slug") in UI_SLUGS and (ev.get("ts") or "") >= cutoff:
            n_atones += 1
except OSError:
    pass

say = (f"The reply says \"{claim.group(0)}\" about a UI change and the image was read, but it does not describe what "
       "is on screen before saying so. Write the frame first (what you see, in your own words, 80 characters or more), "
       "then the verdict; the description is what shows the image was read. rules/ui-visual-verification.md.")
open(fired, "w").write("frame")
if n_atones >= ESCALATE_AT:
    log_row("--action", "block", "--heeded", "unknown", "--detail", f"{n_atones} UI atones in {WINDOW_DAYS}d")
    print(json.dumps({"decision": "block", "reason":
        f"[ui-verified] {say} Blocking this time because the atone ledger holds {n_atones} UI-verification events in "
        f"the last {WINDOW_DAYS} days (shipping-css-ui-changes-without-visual-verification and siblings). "
        "Mute: touch ~/.claude/.no-ui-verified-gate"}))
else:
    log_row("--action", "nudge", "--heeded", "unknown", "--detail", f"{n_atones} UI atones in {WINDOW_DAYS}d")
    note = f"[ui-verified] {say} Weigh it; it is a warning. It turns into a block at {ESCALATE_AT} UI-verification atones in {WINDOW_DAYS} days (now {n_atones})."
    try:
        open(f"/tmp/claude-uiverified-note-{sid8}", "w").write(note)
    except OSError:
        pass
    print(json.dumps({"systemMessage": f"⚠ ui-verified: UI claim without a frame description first ({n_atones} UI atones in {WINDOW_DAYS}d; blocks at {ESCALATE_AT})."}))
