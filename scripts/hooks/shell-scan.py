#!/usr/bin/env python3
"""Find the commands a Bash-tool string would actually run (a thin layer over shellparse.py).

Kept so the guards that call it keep working unchanged. The reading itself
lives in shellparse.py.

Modes (the command is read from stdin; a failure exits non-zero so the calling
hook can fall back to its own matching):

    shell-scan.py push    one line per `cd DIR` and per `git [-C DIR] push ARGS`
    shell-scan.py rm      one line naming each deletion found (rm, unlink, find -delete)
    shell-scan.py gh      one line per `gh ARGS` command

As a library: `scan_commands(cmd)` returns argv lists, `exec_texts(cmd)` the
text that a wrapper (bash -c, eval, ssh, a heredoc fed to a shell) would run.
"""
import importlib.util
import os
import sys

# SHELLPARSE_UNDER_TEST lets the corpus point the guards at a mutated copy.
_spec = importlib.util.spec_from_file_location("shellparse", os.environ.get(
    "SHELLPARSE_UNDER_TEST", os.path.join(os.path.dirname(os.path.abspath(__file__)), "shellparse.py")))
shellparse = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(shellparse)


def scan_commands(cmd):
    # A command run on another machine over ssh is not a local deletion or push.
    return [[c.name] + c.words()[1:] for c in shellparse.parse(cmd).commands
            if c.name and c.via != "ssh"]


def exec_texts(cmd):
    return shellparse.exec_texts(cmd)


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
        return " ".join(["git"] + opts + ["push"] + argv[i + 1:])
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
    return [" ".join(a) for a in scan_commands(cmd)
            if a[0] in ("rm", "unlink") or (a[0] == "find" and "-delete" in a)]


def gh_lines(cmd):
    return [" ".join(a) for a in scan_commands(cmd) if a[0] == "gh"]


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    cmd = sys.stdin.read()
    fn = {"push": push_lines, "rm": rm_hits, "gh": gh_lines}.get(mode)
    if fn is None:
        print("usage: shell-scan.py push|rm|gh < command", file=sys.stderr)
        return 2
    for line in fn(cmd):
        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
