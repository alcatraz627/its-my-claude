#!/usr/bin/env python3
"""Find TOP-LEVEL shell chaining operators in a Bash-tool command.

Why this is not a grep. The operators we care about are `&&`, `;` and `|`, and
all three appear constantly inside things that are not operators at all: a
regex alternation (`rg 'a|b'`), a quoted message, an escaped find terminator
(`-exec ... \\;`), a heredoc body, a `||` fallback that is one word, and the
`|` inside a jq filter. A naive match fires on every one of those, and a guard
whose only real-world fire is a false positive is worse than no guard.

So this walks the string once, tracking single quotes, double quotes,
backslash escapes, `$( )` depth and heredoc bodies, and reports an operator
only when it sits at the top level of the command outside all of them.

Reads the command on stdin. Prints one short reason per distinct operator
found, or nothing. Exit 0 always when it ran; the caller fails open on a
non-zero exit.
"""
import re
import sys


def find_heredoc_bodies(cmd):
    """Character ranges belonging to heredoc bodies, which are data not code."""
    spans = []
    for m in re.finditer(r"<<-?\s*'?\"?([A-Za-z_][A-Za-z0-9_]*)'?\"?", cmd):
        tag = m.group(1)
        # body starts after the line the redirection sits on
        nl = cmd.find("\n", m.end())
        if nl == -1:
            continue
        end = re.search(rf"^\s*{re.escape(tag)}\s*$", cmd[nl:], re.M)
        spans.append((nl, nl + end.start() if end else len(cmd)))
    return spans


def scan(cmd):
    hidden = find_heredoc_bodies(cmd)

    def in_heredoc(i):
        return any(a <= i < b for a, b in hidden)

    hits = []
    i, n = 0, len(cmd)
    sq = dq = False
    depth = 0  # $( ) and ` ` nesting
    while i < n:
        c = cmd[i]
        if in_heredoc(i):
            i += 1
            continue
        if c == "\\":
            i += 2
            continue
        if sq:
            if c == "'":
                sq = False
            i += 1
            continue
        if dq:
            if c == '"':
                dq = False
            i += 1
            continue
        if c == "'":
            sq = True
            i += 1
            continue
        if c == '"':
            dq = True
            i += 1
            continue
        if cmd.startswith("$(", i):
            depth += 1
            i += 2
            continue
        if c == ")" and depth:
            depth -= 1
            i += 1
            continue
        if depth:
            i += 1
            continue
        # top level from here
        if cmd.startswith("&&", i):
            hits.append("&&")
            i += 2
            continue
        if cmd.startswith("||", i):
            hits.append("||")
            i += 2
            continue
        if c == "|":
            hits.append("|")
            i += 1
            continue
        if c == ";":
            hits.append(";")
            i += 1
            continue
        i += 1
    return hits


def main():
    cmd = sys.stdin.read()
    if not cmd.strip():
        return
    # A shell loop or an if/case is ONE statement whose semicolons are syntax,
    # not chaining. The owner's own wake payload is such a loop, and blocking
    # those would be a false fire on a construct the rule never meant.
    if re.search(r"\b(for|while|until|if|case)\b", cmd):
        return
    hits = scan(cmd)
    if not hits:
        return
    order, seen = [], set()
    for h in hits:
        if h not in seen:
            seen.add(h)
            order.append(h)
    print(" ".join(order))


if __name__ == "__main__":
    main()
