#!/usr/bin/env python3
"""Find the commands a Bash-tool string would actually run, however they are spelled.

A guard that greps the raw command string has two opposite blind spots. It
fires on a mention (`echo "git push origin main"`), and it misses a command
that is wrapped, quoted, path-qualified or prefixed (`bash -c "git push origin
main"`, `/usr/bin/git push origin +main`, `command rm x`, `xargs rm`). This
module reads the string like a shell would: it splits on top-level operators,
tokenizes each simple command, peels off prefixes such as `env`, `sudo` and
`command`, and looks inside the arguments of `bash -c`, `eval`, `xargs`,
`find -exec`, command substitutions and heredocs that feed a shell.

Words that are only arguments of echo, rg, git commit and the like never come
out as commands, so a mention stays silent.

Modes (the command is read from stdin; a failure inside this script exits
non-zero so the calling hook can fall back to its own matching):

    shell-scan.py push    one line per `cd DIR` and per `git [-C DIR] push ARGS`,
                          arguments de-quoted, in the order they would run
    shell-scan.py rm      one line naming each deletion found (rm, unlink,
                          find -delete), or nothing
    shell-scan.py gh      one line per `gh ARGS` command, arguments de-quoted

As a library: `scan_commands(cmd)` returns argv lists, and `exec_texts(cmd)`
returns the text that a wrapper (bash -c, eval, ssh, a heredoc fed to a shell)
would execute.
"""
import re
import shlex
import sys

SHELLS = {"bash", "sh", "zsh", "dash", "ksh"}
PREFIXES = {"command", "builtin", "exec", "env", "sudo", "doas", "nohup", "time", "nice"}
MAX_DEPTH = 5
XARGS_WITH_VALUE = {"-I", "-n", "-P", "-L", "-d", "-E", "-s", "-J", "-R", "-S"}
REDIRECT = re.compile(r"^\d*[<>&]")
ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
HEREDOC = re.compile(r"(?<!<)<<(?!<)-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1")


def split_heredocs(cmd):
    """Return (cmd with heredoc bodies removed, list of bodies)."""
    bodies = []
    out = []
    pos = 0
    while True:
        m = HEREDOC.search(cmd, pos)
        if not m:
            out.append(cmd[pos:])
            break
        nl = cmd.find("\n", m.end())
        if nl == -1:
            out.append(cmd[pos:])
            break
        end = re.search(rf"^[ \t]*{re.escape(m.group(2))}[ \t]*$", cmd[nl + 1:], re.M)
        stop = nl + 1 + end.start() if end else len(cmd)
        out.append(cmd[pos:nl + 1])
        bodies.append(cmd[nl + 1:stop])
        pos = stop
    return "".join(out), bodies


def split_segments(cmd):
    """Split on top-level ; && || | & newline, keeping quoted text and $( ) whole."""
    cmd = cmd.replace("\\\n", " ")
    segs, cur = [], []
    i, n = 0, len(cmd)
    sq = dq = False
    depth = 0
    while i < n:
        c = cmd[i]
        if c == "\\" and not sq:
            cur.append(cmd[i:i + 2])
            i += 2
            continue
        if sq:
            if c == "'":
                sq = False
            cur.append(c)
            i += 1
            continue
        if dq:
            if c == '"':
                dq = False
            elif cmd.startswith("$(", i):
                depth += 1
                cur.append("$(")
                i += 2
                continue
            elif c == ")" and depth:
                depth -= 1
            cur.append(c)
            i += 1
            continue
        if c == "'":
            sq = True
        elif c == '"':
            dq = True
        elif cmd.startswith("$(", i):
            depth += 1
            cur.append("$(")
            i += 2
            continue
        elif c == ")" and depth:
            depth -= 1
        elif c == "#" and (not cur or cur[-1][-1:].isspace()) and not depth:
            while i < n and cmd[i] != "\n":
                i += 1
            continue
        elif depth == 0 and c in ";\n|&()":
            prev = cmd[i - 1] if i else ""
            nxt = cmd[i + 1] if i + 1 < n else ""
            if c == "&" and (prev in "<>" or nxt == ">"):
                cur.append(c)
                i += 1
                continue
            segs.append("".join(cur))
            cur = []
            i += 1
            continue
        cur.append(c)
        i += 1
    segs.append("".join(cur))
    return [s.strip() for s in segs if s.strip()]


def subst_bodies(text):
    """Bodies of $( ) and backtick substitutions that the shell would run."""
    out = []
    i, n = 0, len(text)
    sq = False
    while i < n:
        c = text[i]
        if c == "\\":
            i += 2
            continue
        if c == "'":
            sq = not sq
        elif not sq and text.startswith("$(", i):
            depth, j = 1, i + 2
            while j < n and depth:
                depth += (text[j] == "(") - (text[j] == ")")
                j += 1
            out.append(text[i + 2:j - 1])
            i = j
            continue
        elif not sq and c == "`":
            j = text.find("`", i + 1)
            if j != -1:
                out.append(text[i + 1:j])
                i = j + 1
                continue
        i += 1
    return out


def tokenize_segment(seg):
    try:
        return shlex.split(seg, posix=True)
    except ValueError:
        return seg.split()


def peel_prefixes(argv):
    """Drop env assignments and wrapper words (env, sudo, command ...) from the front."""
    i = 0
    while i < len(argv):
        w = argv[i]
        if ASSIGNMENT.match(w):
            i += 1
        elif w.rsplit("/", 1)[-1] in PREFIXES:
            i += 1
            while i < len(argv) and (argv[i].startswith("-") or ASSIGNMENT.match(argv[i])):
                i += 1
        else:
            break
    return argv[i:]


def shell_body(argv):
    """If argv is `bash -c BODY` (or -lc, -ic ...), return BODY, else None."""
    for i, w in enumerate(argv[1:], 1):
        if w.startswith("-") and not w.startswith("--") and "c" in w[1:]:
            return argv[i + 1] if i + 1 < len(argv) else ""
        if not w.startswith("-"):
            return None
    return None


class Walk:
    """Collects every simple command and every wrapper body found in one string."""

    def __init__(self):
        self.shell_reads_stdin = False
        self.exec_bodies = []
        self.argvs = []

    def run(self, cmd, depth=0):
        if depth > MAX_DEPTH:
            return
        text, heredocs = split_heredocs(cmd)
        for seg in split_segments(text):
            self.simple(seg, depth)
            for body in subst_bodies(seg):
                self.run(body, depth + 1)
        if self.shell_reads_stdin:
            for body in heredocs:
                self.exec_bodies.append(body)
                self.run(body, depth + 1)
            self.shell_reads_stdin = False

    def simple(self, seg, depth):
        argv = peel_prefixes(tokenize_segment(seg))
        if not argv:
            return
        base = argv[0].rsplit("/", 1)[-1]
        if base in SHELLS:
            body = shell_body(argv)
            if body is not None:
                self.exec_bodies.append(body)
                self.run(body, depth + 1)
            elif all(w.startswith("-") or REDIRECT.match(w) for w in argv[1:]):
                self.shell_reads_stdin = True
            return
        if base == "eval" and len(argv) > 1:
            body = " ".join(argv[1:])
            self.exec_bodies.append(body)
            self.run(body, depth + 1)
            return
        if base == "ssh":
            rest = [w for w in argv[1:] if not w.startswith("-")]
            if len(rest) > 1:
                self.exec_bodies.append(" ".join(rest[1:]))
            return
        if base == "xargs":
            i = 1
            while i < len(argv) and argv[i].startswith("-"):
                i += 2 if argv[i] in XARGS_WITH_VALUE else 1
            if i < len(argv):
                self.simple(" ".join(shlex.quote(w) for w in argv[i:]), depth + 1)
            return
        if base == "find":
            for i, w in enumerate(argv):
                if w in ("-exec", "-execdir", "-ok", "-okdir"):
                    j = i + 1
                    while j < len(argv) and argv[j] not in (";", "+"):
                        j += 1
                    self.simple(" ".join(shlex.quote(x) for x in argv[i + 1:j]), depth + 1)
        self.argvs.append([base] + argv[1:])


def scan_commands(cmd):
    walk = Walk()
    walk.run(cmd)
    return walk.argvs


def exec_texts(cmd):
    """Texts a wrapper would execute, plus each of their command segments."""
    walk = Walk()
    walk.run(cmd)
    out = []
    for body in walk.exec_bodies:
        out.append(body)
        text, _ = split_heredocs(body)
        out.extend(split_segments(text))
    return out


def git_push_line(argv):
    i, opts = 1, []
    while i < len(argv) and argv[i].startswith("-"):
        if argv[i] in ("-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path"):
            if argv[i] == "-C" and i + 1 < len(argv):
                opts.append("-C " + argv[i + 1])
            i += 2
        else:
            i += 1
    if i < len(argv) and argv[i] == "push":
        args = [w for w in argv[i + 1:] if not re.match(r"^\d*[<>]|^&>", w)]
        return " ".join(["git"] + opts + ["push"] + args)
    return None


def push_lines(cmd):
    out = []
    for argv in scan_commands(cmd):
        if argv[0] == "cd" and len(argv) > 1:
            out.append("cd " + argv[1])
        elif argv[0] == "git":
            line = git_push_line(argv)
            if line:
                out.append(line)
    return out


def rm_hits(cmd):
    out = []
    for argv in scan_commands(cmd):
        if argv[0] in ("rm", "unlink"):
            out.append(" ".join(argv))
        elif argv[0] == "find" and "-delete" in argv:
            out.append(" ".join(argv))
    return out


def gh_lines(cmd):
    return [" ".join(argv) for argv in scan_commands(cmd) if argv[0] == "gh"]


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    cmd = sys.stdin.read()
    if mode == "push":
        lines = push_lines(cmd)
    elif mode == "rm":
        lines = rm_hits(cmd)
    elif mode == "gh":
        lines = gh_lines(cmd)
    else:
        print("usage: shell-scan.py push|rm|gh < command", file=sys.stderr)
        return 2
    for line in lines:
        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
