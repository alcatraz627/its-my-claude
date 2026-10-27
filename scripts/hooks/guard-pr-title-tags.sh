#!/usr/bin/env bash
# guard-pr-title-tags.sh — refuses a `gh pr create` (or `gh pr edit --title`)
# whose title lacks the tags the repo asks for.
#
# Agent-raised PRs cost Slack noise and bot-review money, so the owner wants a
# tag in the title ([noslack], sometimes [nobot]) at the moment the PR opens,
# when it is too late to take the notice back (rules/pr-nobot-noslack-codex-review.md).
# The tags are a per-repo call, so the hook asks the repo first:
#
#   1. A line `PR-TITLE-TAGS: [noslack] [nobot]` in the repo's .claude/pr-title-tags,
#      CLAUDE.md or AGENTS.md (first file that has one wins). `none` means the
#      repo wants no tag. `allow-fill` lets `--fill` through without a title.
#   2. Otherwise the global default: [noslack] only. [nobot] stays a judgment
#      call per PR, so it is never demanded by default.
#
# The repo is the command's own: `-R/--repo owner/name` (found as a local clone
# under ~/Code by its origin remote) or the working directory, after any
# `cd` earlier in the command. A repo with no local clone gets the default.
# Any spelling of a tag counts ([no-slack], [NoSlack]). `--fill` without
# `--title` is refused because the title then comes from the commit message and
# the tag cannot be promised.
#
# PreToolUse on Bash. Fails open if jq, python3 or the shell scanner is missing.
# Mute: touch ~/.claude/.no-pr-title-tags-gate  (machine-wide)  or PR_TITLE_TAGS_OFF=1
# Test: bash ~/.claude/scripts/hooks/guard-pr-title-tags.test.sh
set -u
[ -f "$HOME/.claude/.no-pr-title-tags-gate" ] && exit 0
[ "${PR_TITLE_TAGS_OFF:-}" = "1" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0
[ "$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)" = "Bash" ] || exit 0
printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null | grep -q 'gh' || exit 0

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
export HOOK_INPUT="$input" HOOK_DIR
exec python3 -I - <<'PY'
import glob, importlib.util, json, os, re, subprocess, sys

DEFAULT_TAGS = ["[noslack]"]
RULE_FILES = [".claude/pr-title-tags", "CLAUDE.md", "AGENTS.md"]
DIRECTIVE = re.compile(r"PR-TITLE-TAGS:\s*(.*)")
CODE_ROOT = os.environ.get("GUARD_PR_TAGS_CODE_ROOT", os.path.expanduser("~/Code"))


def allow():
    sys.exit(0)


def load_scanner():
    spec = importlib.util.spec_from_file_location(
        "shell_scan", os.path.join(os.environ["HOOK_DIR"], "shell-scan.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def git(d, *args):
    try:
        r = subprocess.run(["git", "-C", d, *args], capture_output=True, text=True, timeout=5)
        return r.stdout.strip() if r.returncode == 0 else ""
    except Exception:
        return ""


def toplevel(d):
    return git(d, "rev-parse", "--show-toplevel") if os.path.isdir(d) else ""


def origin_slug(d):
    url = git(d, "remote", "get-url", "origin")
    m = re.search(r"([\w.-]+/[\w.-]+?)(?:\.git)?/?$", url)
    return m.group(1).lower() if m else ""


def clone_for(repo_arg, cwd):
    """The local checkout of owner/name, or "" when there is none."""
    parts = repo_arg.strip().split("/")
    name = parts[-1].lower()
    slug = "/".join(parts[-2:]).lower() if len(parts) >= 2 else ""
    top = toplevel(cwd)
    cands = [top] if top else []
    for pat in ("{r}/{n}", "{r}/*/{n}", "{r}/*/*/{n}"):
        cands += sorted(glob.glob(pat.format(r=CODE_ROOT, n=parts[-1])))
    for d in cands:
        if not os.path.isdir(d):
            continue
        got = origin_slug(d)
        if got and (got == slug or (not slug and got.endswith("/" + name))):
            return toplevel(d) or d
    return ""


def repo_rule(top):
    """(tags, allow_fill, source) from the repo's own directive, else the default."""
    if top:
        for rel in RULE_FILES:
            p = os.path.join(top, rel)
            try:
                text = open(p, encoding="utf-8", errors="replace").read()
            except OSError:
                continue
            m = DIRECTIVE.search(text)
            if not m:
                continue
            line = m.group(1)
            tags = re.findall(r"\[[^\]\s]+\]", line)
            words = line.lower()
            return tags, "allow-fill" in words, p
    return list(DEFAULT_TAGS), False, "the default rule (rules/pr-nobot-noslack-codex-review.md)"


def tag_re(tag):
    name = tag.strip("[]").lower().replace("-", "")
    if name.startswith("no") and len(name) > 2:
        name = "no-?" + name[2:]
    return re.compile(r"\[\s*" + name + r"\s*\]", re.IGNORECASE)


def parse(argv):
    """argv after `gh pr <sub>`: title, repo, fill, has_title."""
    title, repo, fill = None, None, False
    i = 0
    while i < len(argv):
        a = argv[i]
        if a in ("-t", "--title") and i + 1 < len(argv):
            title = argv[i + 1]; i += 2; continue
        if a.startswith("--title="):
            title = a[len("--title="):]
        elif a in ("-R", "--repo") and i + 1 < len(argv):
            repo = argv[i + 1]; i += 2; continue
        elif a.startswith("--repo="):
            repo = a[len("--repo="):]
        elif a in ("-f", "--fill", "--fill-first", "--fill-verbose"):
            fill = True
        i += 1
    return title, repo, fill


def deny(reason):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason}}))
    try:
        subprocess.run(["bash", os.path.join(os.environ["HOOK_DIR"], "warn-log.sh"),
                        "--hook", "guard-pr-title-tags", "--action", "block",
                        "--cwd", os.getcwd()], capture_output=True, timeout=5)
    except Exception:
        pass
    sys.exit(0)


try:
    data = json.loads(os.environ["HOOK_INPUT"])
    cmd = data["tool_input"]["command"]
    cwd = data.get("cwd") or os.getcwd()
    argvs = load_scanner().scan_commands(cmd)
except Exception:
    allow()

for argv in argvs:
    if argv[0] == "cd" and len(argv) > 1:
        t = os.path.expanduser(argv[1])
        cwd = t if os.path.isabs(t) else os.path.join(cwd, t)
        continue
    if argv[0] != "gh":
        continue
    try:
        k = argv.index("pr")
        sub = argv[k + 1]
    except (ValueError, IndexError):
        continue
    if sub not in ("create", "edit"):
        continue
    title, repo_arg, fill = parse(argv[k + 2:])
    if sub == "edit" and title is None:
        continue
    if sub == "create" and title is None and not fill:
        continue

    # Anything between `gh` and `pr` can carry -R too (`gh -R x pr create`).
    if repo_arg is None:
        pre = argv[1:k]
        for j, a in enumerate(pre):
            if a in ("-R", "--repo") and j + 1 < len(pre):
                repo_arg = pre[j + 1]

    top = clone_for(repo_arg, cwd) if repo_arg else toplevel(cwd)
    tags, allow_fill, source = repo_rule(top)
    where = repo_arg or os.path.basename(top or cwd)

    if title is None:
        if allow_fill or not tags:
            continue
        deny("pr-title-tags: `gh pr %s --fill` without --title takes the title from the "
             "commit message, so the %s tag(s) %s asks for cannot be promised. Give an "
             "explicit title, for example: --title \"%s <title>\". Rule: %s. "
             "Mute: touch ~/.claude/.no-pr-title-tags-gate"
             % (sub, where, " ".join(tags), " ".join(tags), source))

    missing = [t for t in tags if not tag_re(t).search(title)]
    if not missing:
        continue
    fixed = " ".join(missing) + " " + title
    deny("pr-title-tags: the title \"%s\" is missing %s, which %s requires (Slack and bot "
         "notices go out the moment the PR opens and cannot be recalled). Re-run with "
         "--title \"%s\". Source: %s. The tags are a per-repo call; a repo can set its own "
         "with a `PR-TITLE-TAGS:` line in CLAUDE.md. Mute: touch ~/.claude/.no-pr-title-tags-gate"
         % (title, " ".join(missing), where, fixed, source))
allow()
PY
