#!/usr/bin/env python3
"""Checks ui-verified-stop: a UI claim with no image after the last UI edit is
refused; a looked-at change, a non-UI change and an honest "not looked at" pass."""
import json, os, subprocess, sys, tempfile

HOOK = os.environ.get("UI_VERIFIED_HOOK", os.path.join(os.path.dirname(os.path.abspath(__file__)), "ui-verified-stop.py"))
tmp = tempfile.mkdtemp(prefix="uiv-")
passed = failed = 0


def user(text):
    return {"type": "user", "message": {"content": text}}


def edit(path):
    return {"type": "assistant", "message": {"content": [{"type": "tool_use", "name": "Edit", "input": {"file_path": path}}]}}


def image():
    return {"type": "user", "message": {"content": [{"type": "tool_result", "content": [{"type": "image", "source": {}}]}]}}


def say(text):
    return {"type": "assistant", "message": {"content": [{"type": "text", "text": text}]}}


def run(name, want, recs, sid, active=False):
    global passed, failed
    tp = os.path.join(tmp, name.replace(" ", "_") + ".jsonl")
    with open(tp, "w") as f:
        f.write("\n".join(json.dumps(r) for r in recs) + "\n")
    out = subprocess.run([sys.executable, HOOK], input=json.dumps(
        {"transcript_path": tp, "session_id": sid, "stop_hook_active": active}), capture_output=True, text=True,
        env={**os.environ, "WARN_LOG_STORE": os.path.join(tmp, "warn.jsonl")}).stdout
    got = "block" if '"block"' in out else "pass"
    if got == want:
        passed += 1
    else:
        failed += 1
        print(f"FAIL {name}: want {want} got {got}")


for s in range(1, 18):   # a previous run's once-per-reply markers must not leak in
    try:
        os.remove(f"/tmp/claude-uiverified-uiv{s:05d}")
    except OSError:
        pass
ask = user("fix the navbar")
run("ui edit, claim, no image", "block", [ask, edit("/x/nav.css"), say("The navbar is verified at 800 and 1400.")], "uiv00001")
run("ui edit, image after, claim", "pass", [ask, edit("/x/nav.css"), image(), say("Verified, it looks right.")], "uiv00002")
run("image before the edit only", "block", [ask, image(), edit("/x/nav.tsx"), say("Fixed and verified.")], "uiv00003")
run("non-ui edit", "pass", [ask, edit("/x/server.py"), say("Fixed, the tests pass.")], "uiv00004")
run("honest not looked at", "pass", [ask, edit("/x/nav.css"), say("Fixed in code; not looked at in a browser.")], "uiv00005")
run("no claim", "pass", [ask, edit("/x/nav.css"), say("Changed the padding on the navbar.")], "uiv00006")
run("stop hook already active", "pass", [ask, edit("/x/nav.css"), say("Verified.")], "uiv00007", active=True)
same = [ask, edit("/x/nav.css"), say("Verified the hub page.")]
run("first time", "block", same, "uiv00008")
run("same reply again", "pass", same, "uiv00008")
run("edit in an earlier turn", "pass", [ask, edit("/x/nav.css"), image(), user("and the colours?"), say("They work.")], "uiv00009")
run("honest not verified", "pass", [ask, edit("/x/nav.css"), say("Changed the padding, but it is not verified yet.")], "uiv00010")
run("fixed width is not a claim", "pass", [ask, edit("/x/nav.css"), say("Set a fixed width of 320px on the nav.")], "uiv00011")
run("working tree is not a claim", "pass", [ask, edit("/x/nav.css"), say("The working tree is dirty.")], "uiv00012")
run("script .js is not UI", "pass", [ask, edit("/x/scripts/build.js"), say("It works now; the parser is fixed.")], "uiv00013")
run("ui .js under src is UI", "block", [ask, edit("/x/src/nav.js"), say("It works now.")], "uiv00014")
run("claim in inline code", "pass", [ask, edit("/x/nav.css"), say("Added a `.works` class.")], "uiv00015")
sh = {"type": "assistant", "message": {"content": [{"type": "tool_use", "name": "Bash",
       "input": {"command": "sed -i '' 's/a/b/' /x/nav.css"}}]}}
run("ui edit through sed", "block", [ask, sh, say("Verified the nav.")], "uiv00017")
skill = {"type": "user", "message": {"content": "Base directory for this skill: /x"}}
run("skill text after the edit", "block", [ask, edit("/x/nav.css"), skill, say("Verified.")], "uiv00016")
for s in range(1, 18):
    try:
        os.remove(f"/tmp/claude-uiverified-uiv{s:05d}")
    except OSError:
        pass
print(f"{passed} passed, {failed} failed")
sys.exit(1 if failed else 0)
