#!/usr/bin/env python3
"""Says whether a pull request can be merged right now, and names what stops it if not.

It reads GitHub live every run, so a push or a main that moved a minute ago shows.
It only reads: it never merges, comments, retriggers a review or fetches into a clone.

    ready-to-merge.py [<pr>] [--repo-dir DIR] [--json]

<pr> is a URL, owner/repo#N or repo#N (org defaults to versable-git); with none, the
PR of the branch checked out here. Exit 0 ready, 1 blocked, 2 GitHub could not be read.

The Clanky reading (review of the head, answered findings) and the PR parsing come from
hooks/pr-review-gate.py, imported and not copied. The list of checks and how each is
read: assets/reports/20261103-gcc-build/lane-c.md. Test: bash scripts/pr/ready-to-merge.test.sh
"""
import importlib.util
import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
GATE_PATH = os.environ.get("READY_TO_MERGE_GATE", os.path.join(HERE, "..", "hooks", "pr-review-gate.py"))
ENVS = os.environ.get("READY_TO_MERGE_ENVS", os.path.join(HERE, "..", "versable", "envs.py"))
POLL_S = float(os.environ.get("READY_TO_MERGE_POLL_S", 3))
POLLS = 3
SUBPROCESS_S = 30

spec = importlib.util.spec_from_file_location("pr_review_gate", GATE_PATH)
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)

PASSING = {"SUCCESS", "NEUTRAL", "SKIPPED"}
EXTRA_FIELDS = "mergeStateStatus,reviewDecision,baseRefName,headRefName,headRefOid,statusCheckRollup,latestReviews"
THREADS_QUERY = (
    "query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){"
    "reviewThreads(first:100){totalCount nodes{isResolved isOutdated path "
    "comments(first:1){nodes{author{login} body}}}}}}}"
)


class Rows:
    """The verdict is built from these: each is blocks, warns, ok or not checked."""

    def __init__(self):
        self.rows = []

    def add(self, status, check, text, details=None):
        self.rows.append({"status": status, "check": check, "text": text, "details": details or []})

    def blockers(self):
        return [r for r in self.rows if r["status"] == "blocks"]


def plural(n, one, many=None):
    return f"{n} {one if n == 1 else (many or one + 's')}"


def read_pr(ref):
    """The PR from GitHub, read again while it is still working out whether it can merge."""
    for attempt in range(POLLS):
        pr = gate.fetch(ref)
        raw = gate.gh("pr", "view", gate.url(ref), "--json", EXTRA_FIELDS)
        extra = json.loads(raw) if raw else None
        if pr and extra and pr.get("mergeable") != "UNKNOWN" and extra.get("mergeStateStatus") != "UNKNOWN":
            break
        if attempt < POLLS - 1:
            time.sleep(POLL_S)
    return pr, extra


def latest_checks(rollup):
    """The newest run of each check. GitHub keeps every rerun, and an old cancelled one must not count."""
    newest = {}
    for c in rollup or []:
        if c.get("__typename") == "StatusContext":
            name, workflow = c.get("context") or "status", ""
            state = c.get("state") or ""
            done, result = state not in ("PENDING", "EXPECTED"), state
        else:
            name, workflow = c.get("name") or "check", c.get("workflowName") or ""
            done, result = c.get("status") == "COMPLETED", c.get("conclusion") or ""
        started = c.get("startedAt") or ""
        if started.startswith("0001") or not started:
            started = "9999"  # queued and not started yet: it is the newest run, not the oldest
        slot = (workflow, name)
        if slot not in newest or started >= newest[slot][0]:
            newest[slot] = (started, f"{workflow}: {name}" if workflow else name, done, result)
    return [(label, done, result) for _, label, done, result in newest.values()]


def check_state(rows, pr):
    if pr.get("state") != "OPEN":
        rows.add("blocks", "Open", f"The PR is {str(pr.get('state')).lower()}, so there is nothing to merge.")
        return False
    rows.add("ok", "Open", "The PR is open.")
    return True


def check_draft(rows, pr):
    if pr.get("isDraft"):
        rows.add("blocks", "Draft", "The PR is still a draft. Mark it ready for review first.")
    else:
        rows.add("ok", "Draft", "The PR is not a draft.")


def check_conflicts(rows, pr, extra):
    base = extra.get("baseRefName")
    if pr.get("mergeable") == "UNKNOWN":
        rows.add("blocks", "Conflicts", "GitHub has not finished working out whether the branch conflicts. Run this again in a minute.")
    elif pr.get("mergeable") == "CONFLICTING":
        rows.add("blocks", "Conflicts", f"The branch conflicts with {base}, which has moved since it was cut. Rebase or merge {base} into it.")
    else:
        rows.add("ok", "Conflicts", f"None. GitHub can merge it into {base}.")


def check_branch_rules(rows, pr, extra):
    state = extra.get("mergeStateStatus")
    if state == "UNKNOWN":
        rows.add("blocks", "Branch rules", "GitHub has not finished working out the branch rules. Run this again in a minute.")
    elif state == "BEHIND":
        rows.add("blocks", "Branch rules", f"The branch is behind {extra.get('baseRefName')} and the rules need it up to date. Update the branch.")
    elif state == "BLOCKED":
        pass  # reported at the end, and only when no other row already explains it
    elif state == "DIRTY":
        if pr.get("mergeable") != "CONFLICTING":
            rows.add("blocks", "Branch rules", "GitHub says the branch cannot be merged cleanly.")
    elif state == "DRAFT":
        pass  # the draft row already says it
    elif state in ("CLEAN", "HAS_HOOKS", "UNSTABLE"):
        extra_words = " Some checks that the rules do not require are failing." if state == "UNSTABLE" else ""
        rows.add("ok" if state != "UNSTABLE" else "warns", "Branch rules", f"GitHub reports nothing the rules require is missing.{extra_words}")
    else:
        rows.add("blocks", "Branch rules", f"GitHub gave an answer this command does not know ({state}). Look at the PR page.")


def check_ci(rows, extra):
    runs = latest_checks(extra.get("statusCheckRollup"))
    if not runs:
        rows.add("ok", "Checks", "The PR has no checks.")
        return
    failing = sorted(f"{label} ({result.lower().replace('_', ' ')})" for label, done, result in runs if done and result not in PASSING)
    pending = sorted(label for label, done, _ in runs if not done)
    required_ok = extra.get("mergeStateStatus") in ("CLEAN", "HAS_HOOKS")
    if pending:
        rows.add("blocks", "Checks", f"{plural(len(pending), 'check is', 'checks are')} still running on the latest push.", pending)
    if failing and required_ok:
        rows.add("warns", "Checks", f"{plural(len(failing), 'check')} failed, but GitHub says none of them is required.", failing)
    elif failing:
        rows.add("blocks", "Checks", f"{plural(len(failing), 'check')} failed on the latest push.", failing)
    if not pending and not failing:
        rows.add("ok", "Checks", f"All {plural(len(runs), 'check')} passed on the latest push (the newest run of each).")


def check_reviews(rows, extra):
    decision = extra.get("reviewDecision") or ""
    asked = sorted({(r.get("author") or {}).get("login", "someone") for r in extra.get("latestReviews") or []
                    if r.get("state") == "CHANGES_REQUESTED"})
    if decision == "CHANGES_REQUESTED" or asked:
        who = ", ".join(asked) or "a reviewer"
        rows.add("blocks", "Human review", f"{who} asked for changes and has not approved since.")
    elif decision == "REVIEW_REQUIRED":
        rows.add("blocks", "Human review", "The rules need an approving review and there is none yet.")
    elif decision == "APPROVED":
        rows.add("ok", "Human review", "Approved, and nobody has asked for changes.")
    else:
        rows.add("ok", "Human review", "The rules do not require a review on this PR.")


def read_threads(ref):
    raw = gate.gh("api", "graphql", "-f", f"query={THREADS_QUERY}", "-f", f"o={ref[0]}", "-f", f"r={ref[1]}", "-F", f"n={ref[2]}")
    try:
        return json.loads(raw)["data"]["repository"]["pullRequest"]["reviewThreads"]
    except (TypeError, ValueError, KeyError):
        return None


def check_threads(rows, ref):
    threads = read_threads(ref)
    if threads is None:
        rows.add("unchecked", "Open threads", "Could not read the review threads from GitHub, so unanswered comments are not ruled out.")
        return
    open_ones = []
    for t in threads.get("nodes") or []:
        if t.get("isResolved"):
            continue
        first = ((t.get("comments") or {}).get("nodes") or [{}])[0]
        who = (first.get("author") or {}).get("login", "someone")
        body = " ".join((first.get("body") or "").split())
        open_ones.append(f"{t.get('path')}, {who}: {body[:90]}")
    more = threads.get("totalCount", 0) > len(threads.get("nodes") or [])
    if open_ones:
        rows.add("blocks", "Open threads", f"{plural(len(open_ones), 'review thread is', 'review threads are')} not marked resolved.", open_ones)
    elif more:
        rows.add("unchecked", "Open threads", f"The PR has {threads['totalCount']} threads and only the first 100 were read.")
    else:
        rows.add("ok", "Open threads", "Every review thread is resolved." if threads.get("totalCount") else "There are no review threads.")


def check_clanky(rows, ref, pr):
    head7 = (pr.get("headRefOid") or "")[:7]
    if gate.NOBOT.search(pr.get("title") or ""):
        rows.add("unchecked", "Clanky review", "Skipped on purpose: the title carries a no-bot tag.")
        return
    if gate.out_of_usage(pr):
        rows.add("blocks", "Clanky review", f"Clanky ran out of Claude usage on its last try, so {head7} has no review yet.")
        return
    if not pr.get("reviews") and not pr.get("review_sha"):
        if ref[0] == gate.ORG:
            rows.add("blocks", "Clanky review", "Clanky has not reviewed this PR yet.")
        else:
            rows.add("unchecked", "Clanky review", "No Clanky review on this PR, and this is not a versable-git repo.")
        return
    if not gate.review_current(pr):
        rows.add("blocks", "Clanky review", f"Clanky's last review is of an older push ({(pr.get('review_sha') or '?')[:7]}). The latest push {head7} has none.")
        return
    done = gate.dispositions(ref, pr["review_sha"])

    def answer(n, text):
        d = done.get(n)
        return d if d and d[2] in (None, text) else None

    unanswered = [f"{n}. {t}" for n, t in pr["findings"] if not answer(n, t)]
    still_open = [f"{n}. {t}" for n, t in pr["findings"] if answer(n, t) and answer(n, t)[0] == "will-fix"]
    if unanswered:
        rows.add("blocks", "Clanky review", f"Clanky reviewed {head7} and {plural(len(unanswered), 'finding has', 'findings have')} no answer yet.", unanswered)
    if still_open:
        rows.add("blocks", "Clanky review", f"{plural(len(still_open), 'finding is', 'findings are')} marked will-fix and not fixed yet.", still_open)
    if not unanswered and not still_open:
        kinds = {}
        for n, t in pr["findings"]:
            kinds[answer(n, t)[0]] = kinds.get(answer(n, t)[0], 0) + 1
        said = ", ".join(f"{v} {k}" for k, v in sorted(kinds.items()))
        rows.add("ok", "Clanky review", f"Clanky reviewed {head7}" + (f" and every finding is answered ({said})." if said else " and raised nothing."))


def run(cmd, cwd=None):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=SUBPROCESS_S, cwd=cwd)
    except (OSError, subprocess.SubprocessError):
        return None
    return r.stdout.strip() if r.returncode == 0 else None


def env_map(ref):
    """Staging and release branches and the clone path from the versable env map, or {}."""
    if ref[0].lower() != gate.ORG.lower():
        return {}
    out = run([sys.executable, ENVS, ref[1], "--json"])
    try:
        return json.loads(out) if out else {}
    except ValueError:
        return {}


def check_base(rows, ref, extra, envmap):
    base, head = extra.get("baseRefName"), extra.get("headRefName")
    staging, release = envmap.get("staging_branch"), envmap.get("release_branch")
    if ref[0].lower() != gate.ORG.lower():
        rows.add("unchecked", "Target branch", f"No environment map for {ref[0]}, so the target branch {base} is not compared with one.")
    elif not staging:
        rows.add("unchecked", "Target branch", f"The environment map has no branch for {ref[1]}, so the target branch {base} is not compared with one.")
    elif base != staging and base == release and head != staging:
        rows.add("blocks", "Target branch", f"The PR targets {base}, which is production. Feature PRs target {staging}.")
    elif base != staging and head != staging:
        rows.add("warns", "Target branch", f"The PR targets {base}, but the environment map says staging is {staging}.")
    else:
        rows.add("ok", "Target branch", f"{base} is where the environment map expects this PR to go.")


def find_clone(ref, repo_dir, hint):
    for d in [repo_dir, hint]:
        if not d or not os.path.isdir(d):
            continue
        origin = run(["git", "-C", d, "remote", "get-url", "origin"]) or ""
        if f"{ref[0]}/{ref[1]}".lower() in re.sub(r"\.git$", "", origin.lower()).replace(":", "/"):
            return d
    return None


def check_unpushed(rows, ref, pr, extra, repo_dir, hint):
    head, branch = pr.get("headRefOid") or "", extra.get("headRefName") or ""
    d = find_clone(ref, repo_dir, hint)
    if not d or not run(["git", "-C", d, "rev-parse", "--verify", "--quiet", f"refs/heads/{branch}"]):
        rows.add("unchecked", "Local commits", f"No local clone with a branch called {branch} was found, so unpushed commits are not ruled out.")
        return
    if run(["git", "-C", d, "cat-file", "-e", f"{head}^{{commit}}"]) is None:
        rows.add("warns", "Local commits", f"The clone at {d} has not fetched the latest push {head[:7]}, so it cannot be compared. Fetch first.")
        return
    n = int(run(["git", "-C", d, "rev-list", "--count", f"{head}..refs/heads/{branch}"]) or 0)
    if n:
        rows.add("blocks", "Local commits", f"{plural(n, 'commit')} on your local {branch} {'is' if n == 1 else 'are'} not on the PR yet. Push them.")
    else:
        rows.add("ok", "Local commits", f"Everything on your local {branch} is already on the PR.")


def verdict(rows, ref, head7):
    blockers = rows.blockers()
    name = gate.key(ref)
    if blockers:
        return f"NOT READY TO MERGE: {name} has {plural(len(blockers), 'blocker')}."
    unchecked = [r for r in rows.rows if r["status"] == "unchecked"]
    tail = f" {plural(len(unchecked), 'check was', 'checks were')} not run, listed below." if unchecked else ""
    return f"READY TO MERGE: {name} at {head7} has no blockers.{tail}"


def check_pr(ref, repo_dir):
    rows = Rows()
    pr, extra = read_pr(ref)
    if not pr or not extra:
        return None, None
    if pr.get("headRefOid") != extra.get("headRefOid"):
        rows.add("blocks", "Latest push", "A push landed while this was reading GitHub. Run it again.")
        return rows, pr
    if check_state(rows, pr):
        check_draft(rows, pr)
        check_conflicts(rows, pr, extra)
        check_branch_rules(rows, pr, extra)
        check_ci(rows, extra)
        check_reviews(rows, extra)
        check_threads(rows, ref)
        check_clanky(rows, ref, pr)
        envmap = env_map(ref)
        check_base(rows, ref, extra, envmap)
        check_unpushed(rows, ref, pr, extra, repo_dir, envmap.get("clone"))
        if extra.get("mergeStateStatus") == "BLOCKED" and not rows.blockers():
            rows.add("blocks", "Branch rules", "GitHub says the branch rules are not met, and nothing above shows why (a required check or review this cannot see). Look at the PR page.")
        rows.add("unchecked", "Preview", "Not checked: there is no per-repo way yet to ask which commit a preview is serving. Open the preview and compare its commit with the latest push.")
    return rows, pr


def current_pr(repo_dir):
    out = gate.gh("pr", "view", "--json", "url", cwd=repo_dir)
    try:
        return json.loads(out)["url"]
    except (TypeError, ValueError, KeyError):
        return None


def main(argv):
    args, repo_dir, as_json, target = list(argv), os.getcwd(), False, None
    while args:
        a = args.pop(0)
        if a == "--json":
            as_json = True
        elif a == "--repo-dir" and args:
            repo_dir = os.path.abspath(args.pop(0))
        elif a in ("-h", "--help"):
            print(__doc__)
            return 0
        else:
            target = a
    target = target or current_pr(repo_dir)
    ref = gate.parse_ref(target) if target else None
    if not ref:
        print("Which PR? Give a URL, owner/repo#N or repo#N, or run it inside a clone whose branch has a PR.", file=sys.stderr)
        return 2
    rows, pr = check_pr(ref, repo_dir)
    if rows is None:
        print(f"Could not read {gate.key(ref)} from GitHub. Check `gh auth status`; if gh needs a token, run it as "
              f"`with-token GITHUB_TOKEN -- python3 {os.path.abspath(__file__)} ...`.", file=sys.stderr)
        return 2
    head7 = (pr.get("headRefOid") or "")[:7]
    line = verdict(rows, ref, head7)
    if as_json:
        print(json.dumps({"ready": not rows.blockers(), "pr": gate.key(ref), "head": pr.get("headRefOid"),
                          "verdict": line, "checks": rows.rows}, indent=2))
    else:
        print(line)
        for r in rows.rows:
            print(f"  {r['status']:<9} {r['check']:<14} {r['text']}")
            for d in r["details"]:
                print(f"{'':27}- {d}")
        print(f"Read live from GitHub at {time.strftime('%H:%M:%S')}, latest push {head7}.")
    return 1 if rows.blockers() else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
