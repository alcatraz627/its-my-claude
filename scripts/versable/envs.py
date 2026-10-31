#!/usr/bin/env python3
"""Where each versable-git repo deploys: staging and release branches, GCP project,
env docs, deploy workflows and preview setup, read from the repo itself.

Applies to versable-git repos only; anything else prints nothing (exit 0).

  versable-envs                 the repo you are in
  versable-envs speedway        one repo by name
  versable-envs --all           every repo vg's estate or a local clone knows
  versable-envs --live          also read Cloud Build triggers and the preview
                                deployer's bindings from GCP (needs gcloud login)
  versable-envs --brief         one line, for the SessionStart hook
  versable-envs --json

Sources, in the order they are trusted:
  .github/pr-context.config.json  branches.dev (staging alias), branches.release
  ~/Code/Versable/vg/estate.toml  GCP project for the repo
  docs/ and deploy/ *.md          the repo's own env and deploy docs
  .github/workflows/*.yml         push-triggered branches, preview WIF settings
  gcloud (with --live)            Cloud Build triggers, deployer IAM
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tomllib
from pathlib import Path

ORG = "versable-git"
CODE_ROOT = Path.home() / "Code" / "Versable"
ESTATE = CODE_ROOT / "vg" / "estate.toml"
DOC_RE = re.compile(r"(?i)(^|/)(docs|deploy)/(.*/)?[^/]*(environment|deploy)[^/]*\.md$")
LOCAL_ESTATE = Path.home() / ".config" / "vg" / "local.toml"


def sh(*args: str, cwd: Path | None = None, timeout: int = 20) -> str | None:
    try:
        r = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return r.stdout if r.returncode == 0 else None


def origin_repo(path: Path) -> str | None:
    """The repo name when `path` is a clone of a versable-git repo."""
    url = sh("git", "-C", str(path), "remote", "get-url", "origin")
    if not url:
        return None
    m = re.search(rf"[:/]{ORG}/([^/\s]+?)(\.git)?/?\s*$", url.strip())
    return m.group(1) if m else None


def find_clone(repo: str) -> Path | None:
    here = sh("git", "rev-parse", "--show-toplevel")
    if here and origin_repo(Path(here.strip())) == repo:
        return Path(here.strip())
    cand = CODE_ROOT / repo
    if cand.is_dir() and origin_repo(cand) == repo:
        return cand
    return None


def default_ref(clone: Path) -> str:
    head = sh("git", "-C", str(clone), "symbolic-ref", "--short", "refs/remotes/origin/HEAD")
    return head.strip() if head else "origin/main"


class Source:
    """Reads files from the repo's default branch, locally when a clone exists, else via gh."""

    def __init__(self, repo: str):
        self.repo = repo
        self.clone = find_clone(repo)
        self.ref = default_ref(self.clone) if self.clone else None

    def read(self, path: str) -> str | None:
        if self.clone:
            return sh("git", "-C", str(self.clone), "show", f"{self.ref}:{path}")
        out = sh("gh", "api", f"repos/{ORG}/{self.repo}/contents/{path}",
                 "-H", "Accept: application/vnd.github.raw")
        return out

    def files(self) -> list[str]:
        if self.clone:
            out = sh("git", "-C", str(self.clone), "ls-tree", "-r", "--name-only", self.ref)
        else:
            out = sh("gh", "api", f"repos/{ORG}/{self.repo}/git/trees/HEAD?recursive=1",
                     "--jq", ".tree[].path")
        return out.splitlines() if out else []


def estate() -> dict:
    """vg's team estate with the personal local.toml laid over it, as vg itself does."""
    merged: dict = {"projects": {}}
    for path in (ESTATE, LOCAL_ESTATE):
        try:
            data = tomllib.loads(path.read_text())
        except (OSError, tomllib.TOMLDecodeError):
            continue
        for short, p in (data.get("projects") or {}).items():
            merged["projects"].setdefault(short, {}).update(p)
    return merged


def project_for(repo: str, est: dict) -> dict | None:
    for short, p in (est.get("projects") or {}).items():
        if repo in (p.get("repos") or []):
            return {"short": short, "id": p.get("id"), "about": p.get("about"),
                    "regions": p.get("regions") or [p.get("region") or "us-central1"]}
    return None


CATALOG_REPO = "slack-automation"
CATALOG_PATH = "pr-board/playbooks/deploys.md"
CATALOG_COLS = {"Dev or staging", "Prod", "Where a preview appears", "What a change deploys",
                "How", "What is live", "Unknown"}


def catalog_rows(repo: str) -> dict[str, str]:
    """Clanky's infra catalog cells for this repo: the maintained, owner-reviewed source."""
    text = Source(CATALOG_REPO).read(CATALOG_PATH) or ""
    out: dict[str, str] = {}
    header: list[str] = []
    for line in text.splitlines():
        if not line.startswith("|"):
            header = []
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if not header:
            header = cells
            continue
        if set("".join(cells)) <= set("-: "):
            continue
        # A row may carry an alias after the name, e.g. "walmart-mvp (walmart)".
        if cells and (cells[0].strip("` ").split() or [""])[0].strip("`") == repo:
            for h, v in zip(header, cells):
                if h in CATALOG_COLS and v:
                    out.setdefault(h, v)
    return out


def push_branches(text: str) -> list[str]:
    """Branches a workflow runs on for a push, read loosely (no YAML parser on hand)."""
    m = re.search(r"(?m)^\s{2}push:\s*\n((?:\s{4,}.*\n?)*)", text)
    if not m:
        return []
    block = m.group(1)
    inline = re.search(r"(?m)^\s+branches:\s*\[([^\]]*)\]", block)
    if inline:
        return [b.strip().strip("'\"") for b in inline.group(1).split(",") if b.strip()]
    listed = re.search(r"(?m)^\s+branches:\s*\n((?:\s+-\s*.*\n?)*)", block)
    if listed:
        return [l.split("-", 1)[1].strip().strip("'\"") for l in listed.group(1).splitlines() if "-" in l]
    return []


def describe(repo: str, est: dict, live: bool, quick: bool = False) -> dict:
    src = Source(repo)
    info: dict = {"repo": repo, "clone": str(src.clone) if src.clone else None}

    cfg_raw = src.read(".github/pr-context.config.json")
    try:
        branches = (json.loads(cfg_raw) if cfg_raw else {}).get("branches") or {}
    except json.JSONDecodeError:
        branches = {}
    info["staging_branch"] = branches.get("dev")
    info["release_branch"] = branches.get("release")
    info["branch_source"] = ".github/pr-context.config.json" if branches else None

    info["project"] = project_for(repo, est)
    info["catalog"] = {} if quick else catalog_rows(repo)

    files = src.files()
    info["env_docs"] = sorted(f for f in files if DOC_RE.search(f) and "/archive/" not in f)

    workflows = []
    preview = None
    for f in [] if quick else files:
        if not re.match(r"\.github/workflows/[^/]+\.ya?ml$", f):
            continue
        text = src.read(f) or ""
        pb = push_branches(text)
        if "deploy" in f or "preview" in f or pb:
            workflows.append({"file": f, "push": pb,
                              "manual": "workflow_dispatch" in text})
        if "preview" in f and "workload_identity_provider" in text:
            prov = re.search(r"WIF_PROVIDER:\s*(\S+)", text)
            dep = re.search(r"DEPLOYER:\s*(\S+)", text)
            preview = {"workflow": f, "provider": prov.group(1) if prov else None,
                       "deployer": dep.group(1) if dep else None}
    info["workflows"] = workflows
    info["preview"] = preview
    info["preview_setup_script"] = next((f for f in files if f.endswith("preview-github-setup.sh")), None)

    if live and info["project"]:
        info["triggers"] = live_triggers(info["project"])
        if preview and preview.get("deployer"):
            preview["wif_bound"] = deployer_bound(preview["deployer"], repo)
    return info


def live_triggers(project: dict) -> list[dict]:
    out = []
    # First-gen triggers live in "global", whatever region the project runs in.
    for region in [*project["regions"], "global"]:
        raw = sh("gcloud", "builds", "triggers", "list", f"--project={project['id']}",
                 f"--region={region}", "--format=json", timeout=40)
        for t in json.loads(raw) if raw else []:
            # 2nd-gen repository triggers, 1st-gen GitHub triggers, then mirrored repos.
            push = ((t.get("repositoryEventConfig") or {}).get("push")
                    or (t.get("github") or {}).get("push")
                    or t.get("triggerTemplate") or {})
            rec = t.get("repositoryEventConfig") or {}
            source = (rec.get("repository") or "").rsplit("/", 1)[-1] or (t.get("github") or {}).get("name")
            out.append({"name": t.get("name"), "region": region, "source": source,
                        "branch": push.get("branch") or push.get("branchName"),
                        "tag": push.get("tag") or push.get("tagName"),
                        "disabled": bool(t.get("disabled"))})
    return out


def deployer_bound(deployer: str, repo: str) -> bool | None:
    project = deployer.split("@", 1)[1].split(".", 1)[0]
    raw = sh("gcloud", "iam", "service-accounts", "get-iam-policy", deployer,
             f"--project={project}", "--format=json", timeout=40)
    if raw is None:
        return None
    for b in json.loads(raw).get("bindings", []):
        if b.get("role") == "roles/iam.workloadIdentityUser" and any(
                m.endswith(f"/attribute.repository/{ORG}/{repo}") for m in b.get("members", [])):
            return True
    return False


def brief(i: dict) -> str:
    stg = i["staging_branch"] or "not set"
    rel = i["release_branch"] or "not set"
    proj = i["project"]["id"] if i["project"] else "not in vg estate"
    doc = f"; env docs: {', '.join(i['env_docs'][:2])}" if i["env_docs"] else ""
    return (f"versable-git/{i['repo']}: staging branch `{stg}`, release branch `{rel}`, "
            f"GCP `{proj}`{doc}. Full map: `python3 ~/.claude/scripts/versable/envs.py` "
            "(add --live for Cloud Build triggers and preview IAM). "
            "Read it before asking the owner which branch deploys where.")


def render(i: dict) -> str:
    L = [f"versable-git/{i['repo']}" + (f"   (clone: {i['clone']})" if i["clone"] else "   (no local clone, read via gh)")]
    src = i["branch_source"] or "no .github/pr-context.config.json"
    L.append(f"  staging branch   {i['staging_branch'] or 'not set'}   ({src})")
    L.append(f"  release branch   {i['release_branch'] or 'not set'}")
    p = i["project"]
    L.append(f"  GCP project      {p['id']} ({p['short']}: {p['about']})" if p else "  GCP project      not in vg estate.toml")
    for k, v in (i.get("catalog") or {}).items():
        L.append(f"  catalog: {k}\n      {v}")
    for d in i["env_docs"]:
        L.append(f"  env doc          {d}")
    for w in i["workflows"]:
        push = ", ".join(w["push"]) or "-"
        L.append(f"  workflow         {w['file']}   push: {push}{'   manual' if w['manual'] else ''}")
    pv = i["preview"]
    if pv:
        bound = pv.get("wif_bound")
        state = "" if bound is None else ("   GitHub may act as deployer" if bound else "   NOT bound: run the preview setup script")
        L.append(f"  preview          {pv['workflow']} as {pv['deployer']}{state}")
    if i["preview_setup_script"]:
        L.append(f"  preview setup    {i['preview_setup_script']}")
    for t in i.get("triggers") or []:
        what = f"branch {t['branch']}" if t["branch"] else f"tag {t['tag']}"
        src = f"   from {t['source']}" if t.get("source") else ""
        L.append(f"  build trigger    {t['name']} ({t['region']})   {what}{src}{'   disabled' if t['disabled'] else ''}")
    return "\n".join(L)


def all_repos(est: dict) -> list[str]:
    names = {r for p in (est.get("projects") or {}).values() for r in (p.get("repos") or [])}
    if CODE_ROOT.is_dir():
        for d in CODE_ROOT.iterdir():
            if (d / ".git").exists() and (r := origin_repo(d)) and d.name == r:
                names.add(r)
    return sorted(names)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("repo", nargs="?")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--live", action="store_true")
    ap.add_argument("--brief", action="store_true")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    est = estate()
    if a.all:
        repos = all_repos(est)
    elif a.repo:
        repos = [a.repo.removeprefix(f"{ORG}/")]
    else:
        top = sh("git", "rev-parse", "--show-toplevel")
        repo = origin_repo(Path(top.strip())) if top else None
        if not repo:
            if not a.brief:
                print("not inside a versable-git clone; name a repo or use --all", file=sys.stderr)
            return 0
        repos = [repo]

    infos = [describe(r, est, a.live, quick=a.brief) for r in repos]
    if a.json:
        print(json.dumps(infos if a.all else infos[0], indent=2))
    elif a.brief:
        print(brief(infos[0]))
    else:
        print("\n\n".join(render(i) for i in infos))
    return 0


if __name__ == "__main__":
    sys.exit(main())
