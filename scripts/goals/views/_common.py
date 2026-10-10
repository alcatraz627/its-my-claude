"""Shared argument handling for the views: scope flags, --json, --detail."""
import argparse, json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import goalstore as G   # noqa: E402
import render as R      # noqa: E402

SID = os.environ.get("CLAUDE_CODE_SESSION_ID", "")


def parse(doc, extra=None):
    p = argparse.ArgumentParser(description=doc)
    p.add_argument("--all", action="store_true", help="every live goal, any project")
    p.add_argument("--project", help="goals whose projects[] names this repo (path or basename)")
    p.add_argument("--goal", help="one goal: id, prefix, or a unique word of its outcome")
    p.add_argument("--archived", action="store_true", help="include met and dropped goals")
    p.add_argument("--json", action="store_true")
    p.add_argument("--detail", action="store_true", help="every line; the height law is off")
    for f in extra or []: p.add_argument(f)
    return p.parse_args()


def goals_for(a):
    if a.goal:
        try: return [G.load(G.resolve(a.goal))]
        except G.GoalError as e:
            print(f"view: {e}", file=sys.stderr); sys.exit(2)
    gs = G.in_scope(SID or None, os.getcwd(), a.project, a.all)
    if a.archived: gs += G.all_goals(include_archived=True)[len(G.ids()):]
    return gs


def scope_text(a, goals):
    return R.scope_line(goals, SID or None, os.getcwd(), a.project, a.all)


def armed_text():
    gid = G.session_goal(SID) if SID else None
    if not gid or not G.exists(gid): return ""
    return G.load(gid)["outcome"]


def armed_state():
    """(text, label): the harness /goal is what actually stops the agent; the record's
    pointer is memory. Say which one holds, in goal.sh's own two-source terms."""
    text = armed_text()
    if not text: return "", "\U0001F3AF no /goal armed"
    harness = False
    try:
        import subprocess
        r = subprocess.run(["bash", os.path.expanduser("~/.claude/scripts/goal/goal.sh"), "harness", "--sid", SID],
                           capture_output=True, text=True, timeout=8)
        j = json.loads(r.stdout or "{}")
        harness = bool(j.get("armed")) and (j.get("text") or "").strip()[:40].lower() == text[:40].lower()
    except Exception:
        harness = False
    if harness: return text, "\U0001F3AF armed, on the /goal line below"
    return text, "\U0001F3AF linked, no /goal armed: paste the line below to arm it"


def emit_json(obj):
    print(json.dumps(obj, indent=2, ensure_ascii=False))
