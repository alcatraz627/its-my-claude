#!/usr/bin/env bash
# guard-pr-title-tags.sh: makes sure a `gh pr create` (or `gh pr edit --title`)
# carries the title tags the repo asks for, by adding the missing ones.
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
# Any spelling of a tag counts ([no-slack], [NoSlack]).
#
# What it does about a missing tag: it rewrites the command's title to carry the
# tag (PreToolUse `updatedInput`, with the command's other fields kept) and tells
# the agent what it did, so the PR opens right on the first call. It only rewrites
# a title it can read exactly: a plain or quoted word on a top-level command. A
# title built from a variable or `$( )`, a command nested in `bash -c`, and
# `--fill` without `--title` (the title then comes from the commit message) are
# refused instead, with the corrected command or the flag to add.
#
# One-call override, no machine-wide mute needed: put `PR_TITLE_TAGS_OFF=1` in
# front of that one gh command, for a PR that should open without the tags.
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
import glob, importlib.util, json, os, re, shlex, subprocess, sys

DEFAULT_TAGS = ["[noslack]"]
RULE_FILES = [".claude/pr-title-tags", "CLAUDE.md", "AGENTS.md"]
DIRECTIVE = re.compile(r"PR-TITLE-TAGS:\s*(.*)")
CODE_ROOT = os.environ.get("GUARD_PR_TAGS_CODE_ROOT", os.path.expanduser("~/Code"))
OVERRIDE = "PR_TITLE_TAGS_OFF"
OVERRIDE_HINT = ("To open this PR without the tags, put %s=1 in front of that one gh command "
                 "(for example: %s=1 gh pr create ...); no machine-wide mute is needed." % (OVERRIDE, OVERRIDE))
# The title step (owner ruling D21a, 2026-11-26): a new PR is named by the pr-title tool
# from the branch's own git data, and the agent keeps the last word.
TITLE_TOOL = os.environ.get("PR_TITLE_TOOL", os.path.expanduser("~/.claude/scripts/pr-title/pr-title.py"))
KEEP = "PR_TITLE_KEEP"
STEP_MUTE = os.path.expanduser("~/.claude/.no-pr-title-step")
STEP_TIMEOUT_S = 240


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
    """argv after `gh pr <sub>`: title, repo, fill, and where the title sits.

    The last two are (index of the title word in argv, whether it is the
    attached `--title=...` form), or (None, False) with no title.
    """
    title, repo, fill, at, attached = None, None, False, None, False
    i = 0
    while i < len(argv):
        a = argv[i]
        if a in ("-t", "--title") and i + 1 < len(argv):
            title, at, attached = argv[i + 1], i + 1, False
            i += 2
            continue
        if a.startswith("--title="):
            title, at, attached = a[len("--title="):], i, True
        elif a in ("-R", "--repo") and i + 1 < len(argv):
            repo = argv[i + 1]; i += 2; continue
        elif a.startswith("--repo="):
            repo = a[len("--repo="):]
        elif a in ("-f", "--fill", "--fill-first", "--fill-verbose"):
            fill = True
        i += 1
    return title, repo, fill, at, attached


def flag_value(argv, short, long):
    for i, a in enumerate(argv):
        if a in (short, long) and i + 1 < len(argv):
            return argv[i + 1]
        if a.startswith(long + "="):
            return a[len(long) + 1:]
    return None


def title_step(argv, top, cwd):
    """The title pr-title writes for this checkout's branch, or None to keep the agent's.

    Runs only when the PR's branch is the checkout the command runs in: a --head
    naming another branch, or a -R repo cloned elsewhere, has no local git data to
    read. Any failure keeps the agent's title.
    """
    if os.path.exists(STEP_MUTE) or os.environ.get("PR_TITLE_STEP_OFF") == "1" or not top or top != toplevel(cwd):
        return None
    head = flag_value(argv, "-H", "--head")
    if head and head != git(top, "rev-parse", "--abbrev-ref", "HEAD"):
        return None
    cmd = ["python3", TITLE_TOOL, "-C", top, "--json"]
    base = flag_value(argv, "-B", "--base")
    if base:
        ref = "origin/" + base if git(top, "rev-parse", "--verify", "-q", "origin/" + base) else base
        cmd += ["--base", ref]
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=STEP_TIMEOUT_S)
        res = json.loads(r.stdout) if r.returncode == 0 else {}
    except Exception:
        return None
    return res.get("title") if res.get("shape_ok") else None


def readable(word, command):
    """Whether this word's text is exactly what the shell will pass, and its place in the command string is known."""
    return (command.via == "top" and command.depth == 0 and word.span is not None and not word.expands
            and not word.substs and word.quoted in ("none", "single", "double"))


def judge(cmd, cwd, scanner, step=True):
    """What this command string needs: (edits, refusals).

    An edit is ((start, end), replacement, note) for a title that can be fixed in
    place; a refusal is the message for a command that cannot be. With step off
    (the read-back of a rewrite), the title step is not run again.
    """
    edits, refusals = [], []
    parsed = scanner.shellparse.parse(cmd)
    for c in parsed.commands:
        if not c.name or c.via == "ssh":
            continue
        argv = [c.name] + c.words()[1:]
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
        # The override is scoped to the one gh command it prefixes.
        if any(n == OVERRIDE and str(v).strip() in ("1", "true", "yes") for n, v in c.assignments):
            continue
        title, repo_arg, fill, at, attached = parse(argv[k + 2:])
        at = None if at is None else at + k + 2
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
            refusals.append(
                "pr-title-tags: `gh pr %s --fill` without --title takes the title from the "
                "commit message, so the %s tag(s) %s asks for cannot be promised. Add an "
                "explicit title to the same command, for example: --title \"%s <title>\". "
                "Rule: %s. %s"
                % (sub, where, " ".join(tags), " ".join(tags), source, OVERRIDE_HINT))
            continue

        word = c.argv[at] if at is not None and at < len(c.argv) else None
        stepped = None
        keep = any(n == KEEP and str(v).strip() in ("1", "true", "yes") for n, v in c.assignments)
        if step and sub == "create" and not keep and word is not None and readable(word, c):
            stepped = title_step(argv[k + 2:], top, cwd)
        if stepped:
            # Tags the agent chose stay; only the words after them are replaced.
            kept = re.findall(r"\[[^\]\s]+\]", title)
            stepped = " ".join(kept + [stepped]) if stepped != title else None
        base_title = stepped or title
        missing = [t for t in tags if not tag_re(t).search(base_title)]
        if not missing and not stepped:
            continue
        fixed = (" ".join(missing) + " " + base_title) if missing else base_title
        if word is not None and readable(word, c):
            rep = shlex.quote(fixed)
            if attached:
                rep = "--title=" + rep
            if stepped:
                note = ("the title step named this PR from its commits and diff: \"%s\" (your title was \"%s\"). "
                        "If it misleads, keep yours: put %s=1 in front of the gh command, or fix it after with "
                        "%s=1 gh pr edit <number> --title \"...\"" % (fixed, title, KEEP, KEEP))
            else:
                note = "%s title is now \"%s\", as %s requires (source: %s)" % (sub, fixed, where, source)
            edits.append((word.span, rep, note))
            continue
        refusals.append(
            "pr-title-tags: the title \"%s\" is missing %s, which %s requires (Slack and bot "
            "notices go out the moment the PR opens and cannot be recalled), and this command's "
            "title cannot be rewritten safely (it is built by the shell or nested in another "
            "command). Re-run with --title \"%s\". Source: %s. The tags are a per-repo call; a "
            "repo can set its own with a `PR-TITLE-TAGS:` line in CLAUDE.md. %s"
            % (title, " ".join(missing), where, fixed, source, OVERRIDE_HINT))
    return edits, refusals


def log(action):
    try:
        subprocess.run(["bash", os.path.join(os.environ["HOOK_DIR"], "warn-log.sh"),
                        "--hook", "guard-pr-title-tags", "--action", action,
                        "--cwd", os.getcwd()], capture_output=True, timeout=5)
    except Exception:
        pass


def deny(reason):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason}}))
    log("block")
    sys.exit(0)


def rewrite(tool_input, cmd, edits):
    """Print the allow decision carrying the command with its titles fixed, and stop."""
    new_cmd = cmd
    for (start, end), rep, _ in sorted(edits, key=lambda e: e[0][0], reverse=True):
        new_cmd = new_cmd[:start] + rep + new_cmd[end:]
    notes = "; ".join(n for _, _, n in edits)
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow",
        "permissionDecisionReason": "pr-title-tags rewrote the PR title: " + notes,
        "updatedInput": {**tool_input, "command": new_cmd},
        "additionalContext": "pr-title-tags: the PR title was rewritten (%s). Slack and bot notices cannot be "
                             "recalled once a PR opens. %s" % (notes, OVERRIDE_HINT)}}))
    log("nudge")
    sys.exit(0)


try:
    data = json.loads(os.environ["HOOK_INPUT"])
    tool_input = data["tool_input"]
    cmd = tool_input["command"]
    cwd = data.get("cwd") or os.getcwd()
    scanner = load_scanner()
    edits, refusals = judge(cmd, cwd, scanner)
except Exception:
    allow()

if refusals:
    deny(refusals[0])
if edits:
    # Trust the rewrite only if reading it back finds nothing left to fix.
    try:
        probe = cmd
        for (start, end), rep, _ in sorted(edits, key=lambda e: e[0][0], reverse=True):
            probe = probe[:start] + rep + probe[end:]
        again_edits, again_refusals = judge(probe, cwd, scanner, step=False)
    except Exception:
        again_edits, again_refusals = [None], []
    if again_edits or again_refusals:
        deny("pr-title-tags: the title is missing a tag this repo requires and the hook could not "
             "rewrite this command safely. Add the tag to --title yourself (" +
             "; ".join(n for _, _, n in edits) + "). " + OVERRIDE_HINT)
    rewrite(tool_input, cmd, edits)
allow()
PY
