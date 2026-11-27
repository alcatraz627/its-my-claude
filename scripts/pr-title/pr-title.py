#!/usr/bin/env python3
"""Names a pull request from its git data, in the owner's title style.

One model writes the title from the commits, the full file list and the diff, and
a model from another family checks it against the same data, revising it only when
it misleads. Nothing the calling agent says about the change reaches either model:
the owner wants titles judged against the raw diff. The calling agent keeps the
last word and can replace a title it finds misleading.

Usage:
  pr-title.py [-C REPO] [--base REF] [--head REF] [--layers 1|2] [--json]
  pr-title.py --pr N --repo OWNER/NAME [--layers 1|2] [--json]
  pr-title.py --input FILE.json [--layers 1|2] [--json]   (a saved git-data record)

Exit 0 with the title on stdout; exit 3 when no title could be made, so a caller
keeps its own. Writer and checker models: PR_TITLE_WRITER (default gpt-6-luna,
through codex) and PR_TITLE_CHECKER (default sonnet, through claude -p).
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
HOME = os.path.expanduser("~")
WRITER = os.environ.get("PR_TITLE_WRITER", "gpt-6-luna")
CHECKER = os.environ.get("PR_TITLE_CHECKER", "sonnet")
CLAUDE_BIN = os.environ.get("CLAUDE_BIN", os.path.join(HOME, ".local", "bin", "claude"))
DIFF_CAP = 24000   # characters of diff; the commit subjects and file list are never cut
TIMEOUT_S = 240
SHAPE = re.compile(r"^(feat|fix|docs|refactor|test|ci|deploy|chore|security|perf)(\([a-z0-9._-]+\))?: \S.*$")


def fits(title):
    """Whether a title has the owner's shape and length: under 72 in all, at most 60 after the colon."""
    return bool(SHAPE.match(title)) and len(title) < 72 and len(title.split(": ", 1)[-1]) <= 60


def git(repo, *args):
    r = subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError("git %s: %s" % (" ".join(args), r.stderr.strip()[:200]))
    return r.stdout


def default_base(repo):
    """The merge base with the remote's default branch, or with main/master."""
    for ref in ("origin/HEAD", "origin/main", "origin/master", "main", "master"):
        try:
            return git(repo, "merge-base", ref, "HEAD").strip()
        except RuntimeError:
            continue
    raise RuntimeError("no base branch found; pass --base")


def from_git(repo, base, head):
    base = base or default_base(repo)
    remote = ""
    try:
        remote = git(repo, "remote", "get-url", "origin").strip()
    except RuntimeError:
        pass
    numstat = git(repo, "diff", "--numstat", "%s...%s" % (base, head))
    files = []
    for line in numstat.splitlines():
        parts = line.split("\t")
        if len(parts) == 3:
            files.append({"path": parts[2], "additions": parts[0], "deletions": parts[1]})
    return {"repo": re.sub(r"(\.git)?$", "", remote.rsplit(":", 1)[-1].split("github.com/")[-1]) or os.path.basename(repo),
            "commits": [s for s in git(repo, "log", "--format=%s", "%s..%s" % (base, head)).splitlines() if s],
            "files": files, "diff": git(repo, "diff", "%s...%s" % (base, head))}


def from_pr(number, slug):
    def gh(*args):
        r = subprocess.run(["gh", *args], capture_output=True, text=True)
        if r.returncode != 0:
            raise RuntimeError("gh %s: %s" % (" ".join(args[:3]), r.stderr.strip()[:200]))
        return r.stdout
    view = json.loads(gh("pr", "view", str(number), "--repo", slug, "--json", "commits,files"))
    return {"repo": slug,
            "commits": [c.get("messageHeadline", "") for c in view.get("commits") or []],
            "files": [{"path": f["path"], "additions": f.get("additions"), "deletions": f.get("deletions")}
                      for f in view.get("files") or []],
            "diff": gh("pr", "diff", str(number), "--repo", slug)}


def render(data):
    diff = data["diff"]
    cut = len(diff) > DIFF_CAP
    lines = ["Repo: %s" % data["repo"], "", "Commit subjects (%d):" % len(data["commits"])]
    lines += ["- " + c for c in data["commits"]] or ["- (none)"]
    lines += ["", "Files changed (%d), +added/-deleted:" % len(data["files"])]
    lines += ["- %s +%s/-%s" % (f["path"], f["additions"], f["deletions"]) for f in data["files"]]
    lines += ["", "Diff%s:" % (" (first %d of %d characters)" % (DIFF_CAP, len(diff)) if cut else ""), diff[:DIFF_CAP]]
    return "\n".join(lines)


def brief(name):
    with open(os.path.join(HERE, name)) as f:
        return f.read()


def clean(text):
    for line in (text or "").strip().splitlines():
        line = line.strip().strip("`").strip('"').strip()
        if line:
            return line
    return ""


def write_title(prompt):
    """The writer: codex in an empty folder with a read-only sandbox, so it sees only the prompt."""
    with tempfile.TemporaryDirectory(prefix="pr-title-") as tmp:
        out = os.path.join(tmp, "title.txt")
        r = subprocess.run(["codex", "exec", "-m", WRITER, "-s", "read-only", "--skip-git-repo-check", "--ephemeral",
                            "-C", tmp, "-o", out, "-"], input=prompt, capture_output=True, text=True, timeout=TIMEOUT_S)
        try:
            with open(out) as f:
                return clean(f.read()), r.returncode
        except OSError:
            return "", r.returncode or 1


def check_title(prompt):
    r = subprocess.run([CLAUDE_BIN, "-p", "--model", CHECKER], input=prompt, capture_output=True, text=True,
                       timeout=TIMEOUT_S)
    return clean(r.stdout), r.returncode


def main(argv):
    ap = argparse.ArgumentParser(description="Name a pull request from its git data.")
    ap.add_argument("-C", dest="repo", default=".")
    ap.add_argument("--base")
    ap.add_argument("--head", default="HEAD")
    ap.add_argument("--pr", type=int)
    ap.add_argument("--repo", dest="slug")
    ap.add_argument("--input")
    ap.add_argument("--layers", type=int, choices=(1, 2), default=2)
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args(argv)
    try:
        if a.input:
            with open(a.input) as f:
                data = json.load(f)
        elif a.pr:
            if not a.slug:
                ap.error("--pr needs --repo OWNER/NAME")
            data = from_pr(a.pr, a.slug)
        else:
            data = from_git(os.path.abspath(a.repo), a.base, a.head)
    except (RuntimeError, OSError, ValueError) as e:
        print("pr-title: %s" % e, file=sys.stderr)
        return 3
    if not data.get("files"):
        print("pr-title: the change touches no files", file=sys.stderr)
        return 3
    facts = render(data)
    result = {"writer": WRITER, "checker": CHECKER if a.layers == 2 else None}
    try:
        title, code = write_title(brief("writer-brief.md") + "\n\n## Input\n\n" + facts)
    except subprocess.TimeoutExpired:
        title, code = "", 124
    result["written"] = title
    if not title:
        print("pr-title: the writer gave no title (exit %s)" % code, file=sys.stderr)
        return 3
    final = title
    if a.layers == 2:
        try:
            verdict, _ = check_title(brief("checker-brief.md") + "\n\n## Title\n\n" + title + "\n\n## Git data\n\n" + facts)
        except subprocess.TimeoutExpired:
            verdict = ""
        result["check"] = verdict or "(no answer)"
        m = re.match(r"revise:\s*(.+?)\s*(\|\s*(.*))?$", verdict, re.I)
        # A revision that breaks the shape or the length is worse than the title it replaces.
        if m and fits(clean(m.group(1))):
            final = clean(m.group(1))
            result["why"] = (m.group(3) or "").strip()
    result["title"] = final
    result["shape_ok"] = fits(final)
    print(json.dumps(result) if a.json else final)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
