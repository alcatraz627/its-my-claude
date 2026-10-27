#!/usr/bin/env python3
"""Print the remote command of every ssh invocation in a shell command line.

Reads a command from stdin and writes one line per ssh call at a command
position: the text ssh would run on the other machine, with the shell quoting
around it removed. `ssh host 'ps auxe'` and `ssh -p 22 host ps auxe` both
print `ps auxe`. An ssh call with no remote command (an interactive login)
prints nothing. Used by guard-env-dump.sh so the remote side of an ssh gets the
same scrutiny as a local command.

A command it cannot tokenise (unbalanced quotes) prints nothing and exits 0,
which opens the gate rather than blocking on a broken scanner.
"""

import shlex
import sys

# ssh options that consume the next token as their value.
WITH_ARG = set("bcDEeFIiJLlmOopQRSWw")


def remote_commands(cmd: str):
    lexer = shlex.shlex(cmd.replace("\n", " ; "), posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    tokens = list(lexer)
    segment = []
    segments = []
    for tok in tokens:
        if tok and set(tok) <= set(";&|()"):
            segments.append(segment)
            segment = []
        else:
            segment.append(tok)
    segments.append(segment)

    for seg in segments:
        if not seg or seg[0] not in ("ssh", "/usr/bin/ssh"):
            continue
        i = 1
        while i < len(seg) and seg[i].startswith("-"):
            flag = seg[i]
            takes_arg = len(flag) == 2 and flag[1] in WITH_ARG
            i += 2 if takes_arg else 1
        i += 1  # the host
        if i < len(seg):
            yield " ".join(seg[i:])


def main() -> int:
    try:
        for remote in remote_commands(sys.stdin.read()):
            print(remote)
    except Exception:
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
