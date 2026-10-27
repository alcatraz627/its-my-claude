#!/usr/bin/env python3
"""Refuses prose bound for GitHub that a person would bounce off.

Looks at the text an agent is about to post through gh (pr, issue, release and
gh api calls that carry a body) or the GitHub MCP, and refuses a wall: a dense
paragraph, a long line spliced with an em-dash or semicolon, or a run of
sentences that only name code and numbers. The checks are the ones doc-voice-gate
applies to docs (prose_readability.py). Slash-command triggers ("/clanky review")
and the owner's attribution line are not prose and never judged; the prose next
to them is. The marker itself stays guard-github-agent-marker.sh's business.

The same body is refused twice and goes through the third time with a note, so a
false positive cannot lock a session. Mute: GH_PROSE_OFF=1, or touch
~/.claude/.no-gh-prose-gate. Test: guard-gh-prose.test.sh
"""
import hashlib
import importlib.util
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import prose_readability as pr  # noqa: E402

MUTE = os.path.expanduser("~/.claude/.no-gh-prose-gate")
STATE_DIR = os.environ.get("GH_PROSE_STATE", "/tmp")
MAX_BLOCKS = 2
HOOK_ID = "guard-gh-prose"

_spec = importlib.util.spec_from_file_location("shellparse", os.path.join(HERE, "shellparse.py"))
shellparse = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(shellparse)

# subcommand pairs that carry prose, and the flags that hold it
BODY_FLAGS = {"--body", "-b"}
FILE_FLAGS = {"--body-file", "-F"}
NOTES_FLAGS = {"--notes", "-n"}
NOTES_FILE_FLAGS = {"--notes-file", "-F"}
COMMENT_FLAGS = {"--comment", "-c"}
SUBS = {
    ("pr", "create"): (BODY_FLAGS, FILE_FLAGS),
    ("pr", "edit"): (BODY_FLAGS, FILE_FLAGS),
    ("pr", "comment"): (BODY_FLAGS, FILE_FLAGS),
    ("pr", "review"): (BODY_FLAGS, FILE_FLAGS),
    ("pr", "merge"): (BODY_FLAGS, FILE_FLAGS),
    ("pr", "close"): (COMMENT_FLAGS, set()),
    ("pr", "reopen"): (COMMENT_FLAGS, set()),
    ("issue", "create"): (BODY_FLAGS, FILE_FLAGS),
    ("issue", "edit"): (BODY_FLAGS, FILE_FLAGS),
    ("issue", "comment"): (BODY_FLAGS, FILE_FLAGS),
    ("issue", "close"): (COMMENT_FLAGS, set()),
    ("issue", "reopen"): (COMMENT_FLAGS, set()),
    ("release", "create"): (NOTES_FLAGS, NOTES_FILE_FLAGS),
    ("release", "edit"): (NOTES_FLAGS, NOTES_FILE_FLAGS),
}
API_FIELD_FLAGS = {"-f", "-F", "--field", "--raw-field"}
BODY_KEY = re.compile(r"(^|[.\[\]])body(\]|$)")
SUBST_CAT_HEREDOC = re.compile(r"^\$\(\s*cat\s*<<-?\s*(['\"]?)(\w+)\1[^\n]*\n(.*?)\n[ \t]*\2[ \t]*\n?[ \t]*\)$", re.DOTALL)
SUBST_CAT_FILE = re.compile(r"^\$\(\s*cat\s+(\S+)\s*\)$")


def read_file(path, cwd):
    p = os.path.expanduser(path.strip("'\""))
    if not os.path.isabs(p):
        p = os.path.join(cwd or ".", p)
    try:
        with open(p, encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return None


def resolve(text, cwd):
    """The literal text of a shell word that carries a body. A `$(cat <<EOF)` or
    `$(cat FILE)` is read; any other substitution or variable is dropped, since
    its value is not known before the command runs."""
    m = SUBST_CAT_HEREDOC.match(text)
    if m:
        return m.group(3)
    m = SUBST_CAT_FILE.match(text)
    if m:
        got = read_file(m.group(1), cwd)
        return got if got is not None else ""
    text = re.sub(r"\$\([^)]*\)|\$\{[^}]*\}|\$[A-Za-z_]\w*", "", text)
    return text


def json_bodies(blob):
    """Every string under a "body" key in a JSON payload, however deep."""
    try:
        data = json.loads(blob)
    except ValueError:
        return []
    out = []

    def walk(x):
        if isinstance(x, dict):
            for k, v in x.items():
                if k == "body" and isinstance(v, str):
                    out.append(v)
                else:
                    walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    walk(data)
    return out


def flag_values(argv, flags):
    """(flag, value) pairs for `--flag value`, `--flag=value` and glued `-bvalue`."""
    out, k = [], 0
    while k < len(argv):
        t = argv[k]
        if t in flags and k + 1 < len(argv):
            out.append((t, argv[k + 1]))
            k += 2
            continue
        for f in flags:
            if f.startswith("--") and t.startswith(f + "="):
                out.append((f, t[len(f) + 1:]))
        k += 1
    return out


def stdin_bodies(parse):
    return [h.body for h in parse.heredocs]


def gh_posts(cmd, cwd):
    """(label, body) for every gh command in a Bash string that posts prose."""
    parse = shellparse.parse(cmd)
    posts = []
    for c in parse.commands:
        if c.name != "gh":
            continue
        sub = tuple(shellparse.subcommand_words(c)[:2])
        words = c.words()[1:]
        if sub in SUBS:
            body_flags, file_flags = SUBS[sub]
            label = "gh " + " ".join(sub)
            for _f, v in flag_values(words, body_flags):
                posts.append((label, resolve(v, cwd)))
            for _f, v in flag_values(words, file_flags):
                if v == "-":
                    posts += [(label, b) for b in stdin_bodies(parse)]
                else:
                    got = read_file(v, cwd)
                    if got is not None:
                        posts.append((label, got))
        elif sub[:1] == ("api",):
            label = "gh api"
            for _f, v in flag_values(words, API_FIELD_FLAGS):
                key, _, val = v.partition("=")
                if not BODY_KEY.search(key):
                    continue
                if val == "@-":
                    posts += [(label, b) for b in stdin_bodies(parse)]
                elif val.startswith("@") and _f in ("-F", "--field"):
                    got = read_file(val[1:], cwd)
                    if got is not None:
                        posts.append((label, got))
                else:
                    posts.append((label, resolve(val, cwd)))
            for _f, v in flag_values(words, {"--input"}):
                blob = "\n".join(stdin_bodies(parse)) if v == "-" else read_file(v, cwd)
                posts += [(label, b) for b in json_bodies(blob or "")]
    return [(label, b) for label, b in posts if b and b.strip()]


def mcp_posts(tool, tool_input):
    """Bodies in a GitHub MCP call: the body field and any review comments."""
    out = []
    body = tool_input.get("body")
    if isinstance(body, str):
        out.append((tool.replace("mcp__github__", "github "), body))
    for c in tool_input.get("comments") or []:
        if isinstance(c, dict) and isinstance(c.get("body"), str):
            out.append((tool.replace("mcp__github__", "github "), c["body"]))
    return [(label, b) for label, b in out if b.strip()]


def state_path(sid):
    return os.path.join(STATE_DIR, "claude-ghprose-%s.json" % (sid or "unknown")[:8])


def load(sid):
    try:
        with open(state_path(sid)) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {"seen": {}}


def save(sid, st):
    try:
        with open(state_path(sid), "w") as f:
            json.dump(st, f)
    except OSError:
        pass


def warn_log(action, detail="", extra=()):
    args = ["bash", os.path.expanduser("~/.claude/scripts/hooks/warn-log.sh"), "--hook", HOOK_ID,
            "--action", action, "--heeded", "unknown"]
    if detail:
        args += ["--detail", detail[:78]]
    subprocess.run(args + list(extra), capture_output=True)


def heed_log(key, heeded):
    subprocess.run(["bash", os.path.expanduser("~/.claude/scripts/hooks/warn-log.sh"), "--hook", HOOK_ID,
                    "--heed-of", key, "--heeded", heeded], capture_output=True)


def describe(found):
    parts = []
    if "dense" in found:
        parts.append("dense block (%d): a paragraph or bullet that packs several sentences into one wall, e.g. \"%s\""
                     % (len(found["dense"]), found["dense"][0]))
    if "spliced" in found:
        parts.append("spliced line (%d): a line joined with an em-dash or a semicolon, e.g. \"%s\""
                     % (len(found["spliced"]), found["spliced"][0]))
    if "mechanism" in found:
        parts.append("mechanism run (%d): three or more sentences in a row that only name code, paths and numbers, "
                     "with no plain sentence saying what it means for the reader, e.g. \"%s\""
                     % (len(found["mechanism"]), found["mechanism"][0]))
    return parts


ADVICE = """Rewrite the body so a person skimming it gets the point:
  1. Open with one plain sentence on what changed for the reader, then a short list with one plain sentence per item.
  2. Move names, paths, measurements and reasoning into a Details section after the list, one fact per bullet.
  3. Split every long line into sentences. No em-dashes, no semicolons.
  4. Keep the attribution marker line, and keep slash-command triggers such as "/clanky review" as they are.
Then run the same command again."""


def judge(posts):
    """The readability findings across all posts, or {} when every body reads fine."""
    merged = {}
    for _label, body in posts:
        for k, v in pr.analyze(body).items():
            merged.setdefault(k, []).extend(v)
    return merged


def main():
    if os.environ.get("GH_PROSE_OFF") == "1" or os.path.exists(MUTE):
        return 0
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0
    tool = data.get("tool_name") or ""
    ti = data.get("tool_input") or {}
    try:
        if tool == "Bash":
            cmd = ti.get("command") or ""
            if "gh" not in cmd:
                return 0
            posts = gh_posts(cmd, data.get("cwd"))
        elif tool.startswith("mcp__github__"):
            posts = mcp_posts(tool, ti)
        else:
            return 0
        if not posts:
            return 0
        found = judge(posts)
    except Exception:
        return 0   # a bug here must never block a post by accident
    sid = data.get("session_id")
    st = load(sid)
    if not found:
        if st.pop("last_block", None):
            heed_log("%s:%s" % (HOOK_ID, (sid or "x")[:8]), "true")
            save(sid, st)
        return 0
    digest = hashlib.sha1("\n".join(b for _l, b in posts).encode("utf-8", "replace")).hexdigest()[:12]
    n = st["seen"].get(digest, 0)
    if n >= MAX_BLOCKS:
        warn_log("soft", "same body sent a third time")
        heed_log("%s:%s" % (HOOK_ID, (sid or "x")[:8]), "false")
        print(json.dumps({"systemMessage": "gh prose check: this body still reads as a wall (%s) but was refused "
                          "twice already, so it went through. Fix it in the next edit."
                          % ", ".join(sorted(found))}))
        return 0
    st["seen"][digest] = n + 1
    st["last_block"] = digest
    save(sid, st)
    warn_log("block", ", ".join("%d %s" % (len(v), k) for k, v in found.items()))
    label = posts[0][0]
    sys.stderr.write("PROSE NOT READABLE for %s: this text is about to be posted to GitHub and a person has to "
                     "read it.\n- %s\n%s\n" % (label, "\n- ".join(describe(found)), ADVICE))
    return 2


if __name__ == "__main__":
    sys.exit(main())
