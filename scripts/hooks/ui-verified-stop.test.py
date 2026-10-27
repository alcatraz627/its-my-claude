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


LEDGER = os.path.join(tmp, "events.jsonl")


def write_ledger(rows):
    with open(LEDGER, "w") as f:
        f.write("".join(json.dumps(r) + "\n" for r in rows))


def ui_atone(days_ago, slug="shipping-css-ui-changes-without-visual-verification"):
    import datetime
    ts = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=days_ago)).strftime("%Y-%m-%dT%H:%M:%SZ")
    return {"id": f"mist-{days_ago}-{slug[:6]}", "ts": ts, "slug": slug}


write_ledger([])
HEED = os.path.join(tmp, "warn.jsonl")


def run(name, want, recs, sid, active=False, lam=None, keep=False):
    """want: block | warn | pass. warn = a systemMessage, no block."""
    global passed, failed
    tp = os.path.join(tmp, name.replace(" ", "_") + ".jsonl")
    with open(tp, "w") as f:
        f.write("\n".join(json.dumps(r) for r in recs) + "\n")
    payload = {"transcript_path": tp, "session_id": sid, "stop_hook_active": active}
    if lam is not None:
        payload["last_assistant_message"] = lam
    out = subprocess.run([sys.executable, HOOK], input=json.dumps(payload), capture_output=True, text=True,
        env={**os.environ, "WARN_LOG_STORE": HEED, "ATONE_EVENTS_FILE": LEDGER}).stdout
    got = "block" if '"block"' in out else ("warn" if "ui-verified" in out and "systemMessage" in out else "pass")
    if got == want:
        passed += 1
    else:
        failed += 1
        print(f"FAIL {name}: want {want} got {got} {out[:120]}")
    return out


def heed_count(verdict):
    if not os.path.exists(HEED):
        return 0
    return sum(1 for l in open(HEED) if '"kind":"heed"' in l.replace(" ", "") and f'"heeded":"{verdict}"' in l.replace(" ", ""))


def clear_state():
    import glob
    for f in glob.glob("/tmp/claude-uiverified-*uiv*") + glob.glob("/tmp/claude-uiverified-note-uiv*"):
        try:
            os.remove(f)
        except OSError:
            pass


clear_state()   # a previous run's once-per-reply markers must not leak in
ask = user("fix the navbar")
run("ui edit, claim, no image", "block", [ask, edit("/x/nav.css"), say("The navbar is verified at 800 and 1400.")], "uiv00001")
run("ui edit, image read, claim with no frame: warns, never blocks", "warn", [ask, edit("/x/nav.css"), image(), say("Verified, it looks right.")], "uiv00002")
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

# ---- the frame-description check (D5) ----
FRAME = "The screenshot shows the navbar at 800px: the logo sits left, three links centre, and the avatar right. "
img = image()
a2 = user("fix the navbar")
run("looked, claim, no frame description: warns", "warn", [a2, edit("/x/nav.css"), img, say("Verified, it looks right.")], "uiv00020")
note = "/tmp/claude-uiverified-note-uiv00020"
if os.path.exists(note) and "frame" in open(note).read():
    passed += 1
else:
    failed += 1
    print("FAIL the warning is queued for the agent in the note file")
run("same reply again stays silent", "pass", [a2, edit("/x/nav.css"), img, say("Verified, it looks right.")], "uiv00020")
run("frame described first, then verdict", "pass", [a2, edit("/x/nav.css"), img, say(FRAME + "Verified, it looks right.")], "uiv00021")
run("verdict first, frame after", "warn", [a2, edit("/x/nav.css"), img, say("Verified. " + FRAME)], "uiv00022")
run("a seeing word but under 80 characters before the verdict", "warn", [a2, edit("/x/nav.css"), img, say("The screenshot shows it. Verified.")], "uiv00023")
run("long text with no seeing word before the verdict", "warn", [a2, edit("/x/nav.css"), img, say("I changed the padding on the navbar and reran the build twice with no complaints from the compiler. It looks right.")], "uiv00024")
run("honest wording still passes", "pass", [a2, edit("/x/nav.css"), img, say("Changed the padding; not looked at in a browser.")], "uiv00025")
run("no claim still passes", "pass", [a2, edit("/x/nav.css"), img, say("Changed the padding on the navbar.")], "uiv00026")
run("no UI edit still passes", "pass", [a2, edit("/x/server.py"), img, say("Verified, it works.")], "uiv00027")

# Escalation by atone count.
write_ledger([ui_atone(1), ui_atone(3)])
run("two UI atones in 14 days: still a warning", "warn", [a2, edit("/x/nav.css"), img, say("Verified, it looks right.")], "uiv00028")
write_ledger([ui_atone(1), ui_atone(3), ui_atone(9, "ui-verified-by-dom-read-not-render")])
out = run("three UI atones in 14 days: block", "block", [a2, edit("/x/nav.css"), img, say("Verified, it looks right.")], "uiv00029")
if "3 UI-verification events" in out:
    passed += 1
else:
    failed += 1
    print("FAIL the escalated block names the atone count")
run("the escalated block is once per reply", "pass", [a2, edit("/x/nav.css"), img, say("Verified, it looks right.")], "uiv00029")
write_ledger([ui_atone(1), ui_atone(3), ui_atone(20)])
run("an atone older than 14 days does not count", "warn", [a2, edit("/x/nav.css"), img, say("Verified, it looks right.")], "uiv00030")
write_ledger([ui_atone(1, "dense-briefing-instead-of-a-direct-answer"), ui_atone(2, "dense-briefing-instead-of-a-direct-answer"),
              ui_atone(3, "dense-briefing-instead-of-a-direct-answer")])
run("three atones of an unrelated slug do not count", "warn", [a2, edit("/x/nav.css"), img, say("Verified, it looks right.")], "uiv00031")
write_ledger([])

# The Stop input's reply beats a transcript that lags one message behind.
run("input reply is judged, not the stale transcript tail", "warn",
    [a2, edit("/x/nav.css"), img, say("Changed the padding on the navbar.")], "uiv00032", lam="Verified, it looks right.")
run("input reply claims nothing, transcript tail did", "pass",
    [a2, edit("/x/nav.css"), img, say("Verified, it looks right.")], "uiv00033", lam="Changed the padding on the navbar.")
run("input reply with no image read is still blocked", "block",
    [a2, edit("/x/nav.css"), say("Changed the padding.")], "uiv00034", lam="The navbar is verified at 800.")

# Heed: a warning, then a reply with the frame (true); a warning, then the same shortfall (false).
try:
    os.remove(HEED)
except OSError:
    pass
run("heed setup: warn", "warn", [a2, edit("/x/nav.css"), img, say("Verified, it looks right.")], "uiv00035")
run("heed: next claim carries the frame", "pass", [a2, edit("/x/nav.css"), img, say(FRAME + "Verified, it looks right.")], "uiv00035")
if heed_count("true") == 1 and heed_count("false") == 0:
    passed += 1
else:
    failed += 1
    print(f"FAIL heed true after a described frame (true={heed_count('true')} false={heed_count('false')})")
try:
    os.remove(HEED)
except OSError:
    pass
run("heed setup 2: warn", "warn", [a2, edit("/x/nav.css"), img, say("Verified, it looks right.")], "uiv00036")
run("heed: the shortfall again", "warn", [a2, edit("/x/nav.css"), img, say("Now it is verified, looks good.")], "uiv00036")
if heed_count("false") == 1 and heed_count("true") == 0:
    passed += 1
else:
    failed += 1
    print(f"FAIL heed false when the shortfall repeats (true={heed_count('true')} false={heed_count('false')})")

# ---- review turns: a visual verdict with no UI edit and no look ----
def tool(name, **inp):
    return {"type": "assistant", "message": {"content": [{"type": "tool_use", "name": name, "input": inp}]}}


rv = user("review the landing page across widths 360 to 1600")
LA = "/Users/alcatraz627/Code/Versable/landing-app"
# Reconstructed from the 2026-10-20 landing-app width review (atone mist-20261020-120344-a4):
# the verdict came from CSS and computed styles, with no render looked at.
css_only = [rv, tool("Bash", command=f"rg -n '@media|@container|grid-template' {LA}/src/styles/base.css"),
            tool("Read", file_path=f"{LA}/src/styles/base.css"),
            tool("Read", file_path=f"{LA}/src/components/module-extraction.tsx")]
verdict = "The layout holds up at 360, 390 and 400px: the extraction module looks right and nothing overflows."
run("review: verdict from CSS alone", "block", css_only + [say(verdict)], "uiv00040")
run("review: same reply again", "pass", css_only + [say(verdict)], "uiv00040")
run("review: after reading a screenshot file", "pass",
    css_only + [tool("Read", file_path=f"{LA}/.claude/output/shots/extraction-360.png"), say(verdict)], "uiv00041")
run("review: after an image came back", "pass", css_only + [image(), say(verdict)], "uiv00042")
run("review: after a browser screenshot tool", "pass",
    css_only + [tool("mcp__plugin_playwright_playwright__browser_take_screenshot"), say(verdict)], "uiv00043")
run("review: after a devtools screenshot", "pass",
    css_only + [tool("mcp__plugin_chrome-devtools-mcp_chrome-devtools__take_screenshot"), say(verdict)], "uiv00044")
run("review: after lm see", "pass",
    css_only + [tool("Bash", command="lm see /x/extraction-360.png --crop 400x300+0+0 'are the values cut off?'"), say(verdict)], "uiv00045")
run("review: an accessibility snapshot is not a look", "block",
    css_only + [tool("mcp__plugin_playwright_playwright__browser_snapshot"), say(verdict)], "uiv00046")
run("review: lm see only in a past turn", "block",
    [tool("Bash", command="lm see /x/a.png 'q'"), user("now the tablet widths")] + css_only[1:] + [say(verdict)], "uiv00047")
run("review: UI mentioned, no verdict", "pass",
    css_only + [say("The extraction module has a compact grid below 768px at base.css:1291 and the sweep covers 400 to 1600px.")], "uiv00048")
run("review: verdict about something that is not a UI", "pass",
    [rv, tool("Bash", command="pytest -q"), say("Verified: the migration ran and the tests pass.")], "uiv00049")
# Real message from the same session (turn that only read CSS and said where it expected trouble).
run("review: 'fixed in pixels' describes CSS, it is no verdict", "pass",
    css_only + [say("While it runs I read the responsive CSS for the animated visuals. These are where I expect "
                    "phone-width trouble, because their layouts are fixed in pixels: the hero graphic below 1024px.")], "uiv00053")
run("review: honest about not looking", "pass",
    css_only + [say("The CSS suggests it holds up at 360px, but I have not looked at a render, so this is not verified.")], "uiv00050")
run("review: stop hook already active", "pass", css_only + [say(verdict)], "uiv00051", active=True)
run("review: input reply is judged", "block", css_only + [say("Read base.css.")], "uiv00052", lam=verdict)

clear_state()
print(f"{passed} passed, {failed} failed")
sys.exit(1 if failed else 0)
