"""Map the owner's directions doc onto a task store's goal tags.

Reads `## 🧭 <direction>` / `### 🎯 <goal>` / `✅ **Accepted when:** <check>` from
the doc, matches each goal to a metadata.goal string in the store (exact, then
case-insensitive prefix both ways), and prints either the task.sh commands
(--apply runs them) or the unmatched list. Additive: only the .goals sidecar
is written, never a row.
"""
import json, glob, os, re, subprocess, sys

doc, store = sys.argv[1], sys.argv[2]
apply = "--apply" in sys.argv
sid8 = os.path.basename(store).replace("session-", "")
goals = {}
for f in glob.glob(os.path.join(store, "*.json")):
    try: g = (json.load(open(f)).get("metadata") or {}).get("goal") or ""
    except Exception: continue
    if g: goals[g] = goals.get(g, 0) + 1

entries, cur_dir, cur_goal = [], None, None
for line in open(doc, encoding="utf-8"):
    m = re.match(r"^## 🧭 (.+?)\s*$", line)
    if m: cur_dir = m.group(1).strip(); continue
    m = re.match(r"^### 🎯 (.+?)\s*$", line)
    if m: cur_goal = m.group(1).strip(); entries.append({"dir": cur_dir, "goal": cur_goal, "when": ""}); continue
    m = re.match(r"^✅ \*\*Accepted when:\*\*\s*(.+?)\s*$", line)
    if m and entries and entries[-1]["goal"] == cur_goal: entries[-1]["when"] = m.group(1).strip()

def norm(s): return re.sub(r"[^a-z0-9 ]", "", s.lower()).strip()
matched, unmatched = [], []
for e in entries:
    hit = None
    if e["goal"] in goals: hit = e["goal"]
    else:
        ng = norm(e["goal"])
        for g in goals:
            n = norm(g)
            if n == ng or n.startswith(ng) or ng.startswith(n): hit = g; break
    (matched if hit else unmatched).append((e, hit))

T = os.path.expanduser("~/.claude/scripts/task-table/task.sh")
for e, hit in matched:
    cmd = ["bash", T, "--session", sid8, "goal", hit, "--direction", e["dir"]] + (["--when", e["when"]] if e["when"] else [])
    if apply:
        r = subprocess.run(cmd, capture_output=True, text=True)
        print(("ok   " if r.returncode == 0 else "FAIL ") + hit[:70] + ("" if r.returncode == 0 else "  " + r.stderr.strip()[:120]))
    else:
        print(f"match  {e['dir'][:32]:32}  ->  {hit[:60]}  ({goals[hit]} rows)")
for e, _ in unmatched:
    print(f"UNMATCHED  {e['goal'][:80]}")
print(f"\n{len(matched)} matched, {len(unmatched)} unmatched, {len(goals)} goal tags in the store")
