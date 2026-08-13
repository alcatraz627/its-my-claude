#!/usr/bin/env python3
"""Decides whether a shell command assigns to zsh's $path, which silently wipes $PATH.

Reads the command on stdin. Prints a short label naming the shape it found, or
nothing at all when the command is clean. Always exits 0.

This is a separate Python file because sed is line-oriented and cannot track
quote state, which produced real false fires. The scan is two passes: blank
$((...)) bodies so 1<<n is never read as a heredoc opener, then one line-by-line
walk that tracks quote state ('...', "...", $'...'), collects heredoc openers in
every zsh delimiter form (<<-, quoted, backslashed), and blanks quoted spans and
heredoc bodies. Herestrings (<<<) need no special case: the delimiter charset
excludes <, and a failed << match advances past both brackets, so <<<WORD can
never register a body. The suite pins that advance with a mutation.
What survives blanking is shell syntax in statement position; only that is matched.
"""
import re
import sys

# Words that can lead a statement without being the statement.
KEYWORDS = {"while", "until", "do", "then", "else", "if", "elif",
            "time", "nohup", "command", "builtin", "!"}
# Keywords that can precede a variable assignment.
DECLARERS = {"export", "local", "declare", "typeset", "readonly", "integer"}
# zsh read(1) flags after which the next token is not a variable name. Measured
# on zsh 5.9, not copied from bash: -d consumes its delimiter argument; -t does
# NOT consume (its timeout must be attached, so `read -t path` assigns path);
# -s and -n consume nothing; -p and -k stay here because without a coprocess or
# TTY they fail before assigning, so warning on their operand is a false fire.
ARG_FLAGS = {"-d", "-u", "-p", "-k"}

ASSIGN_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(\+)?=")
PATH_ASSIGN_RE = re.compile(r"^path(\+)?=")

# <<[-] then a delimiter: 'quoted', "quoted", \escaped, or bare. Bare excludes
# shell metacharacters, and excluding < is what makes <<< inert here.
HEREDOC_OPEN = re.compile(
    r"<<(?P<dash>-)?\s*(?:'(?P<d1>[^']+)'|\"(?P<d2>[^\"]+)\"|\\(?P<d3>\S+)|(?P<d4>[^\s;|&<>()]+))"
)


def blank_arithmetic(s):
    """Replace $(( ... )) bodies with spaces so << inside them is not a heredoc."""
    out, i = list(s), 0
    while True:
        j = s.find("$((", i)
        if j < 0:
            break
        depth, k = 0, j + 1
        while k < len(s):
            if s[k] == "(":
                depth += 1
            elif s[k] == ")":
                depth -= 1
                if depth == 0:
                    break
            k += 1
        for m in range(j + 3, min(k, len(s))):
            out[m] = " "
        i = k + 1 if k > j else j + 3
    return "".join(out)


def blank_shell(s):
    """Blank quoted spans and heredoc bodies in one walk, sharing state.

    Quote state and heredoc collection must be one pass: a << inside a quoted
    string is text, and a quote inside a heredoc body is text. Two passes in
    either order get one of those wrong. Terminator rules follow zsh: a plain
    << terminator must sit at column 0; <<- strips leading tabs only.
    """
    lines = s.split("\n")
    out_lines = []
    pending = []      # FIFO of (delimiter, strip_tabs); shell fills bodies in order
    in_quote = None   # None | "'" | '"' | "$'"  — persists across lines
    for line in lines:
        if pending:
            delim, strip_tabs = pending[0]
            term = line.lstrip("\t") if strip_tabs else line
            if term == delim:
                pending.pop(0)
            out_lines.append("")
            continue
        buf = list(line)
        i, n = 0, len(line)
        while i < n:
            c = line[i]
            if in_quote:
                if in_quote == "'":
                    if c == "'":
                        in_quote = None
                    else:
                        buf[i] = " "
                    i += 1
                    continue
                # "..." and $'...' both escape with backslash; '...' does not.
                if c == "\\":
                    buf[i] = " "
                    if i + 1 < n:
                        buf[i + 1] = " "
                    i += 2
                    continue
                if (in_quote == '"' and c == '"') or (in_quote == "$'" and c == "'"):
                    in_quote = None
                else:
                    buf[i] = " "
                i += 1
                continue
            if c == "\\":
                i += 2
                continue
            if c == "$" and line.startswith("$'", i):
                in_quote = "$'"
                i += 2
                continue
            if c == "'":
                in_quote = "'"
                i += 1
                continue
            if c == '"':
                in_quote = '"'
                i += 1
                continue
            if line.startswith("<<", i):
                m = HEREDOC_OPEN.match(line, i)
                if m:
                    delim = m.group("d1") or m.group("d2") or m.group("d3") or m.group("d4")
                    pending.append((delim, bool(m.group("dash"))))
                    i = m.end()
                    continue
                i += 2
                continue
            i += 1
        out_lines.append("".join(buf))
    return "\n".join(out_lines)


def segments(s):
    """Split into statement-position chunks on the separators zsh honours.

    { and } delimit brace groups and one-line function bodies, so they split
    too — except ${, which is parameter expansion, not a group opener.
    """
    return [seg for seg in re.split(r"(?:[;|&\n()]|(?<!\$)\{|\})+", s)]


def footgun_shape(seg):
    """Name the footgun shape in one statement, or return None if it is clean."""
    toks = seg.split()
    while toks:
        head = toks[0]
        if head in KEYWORDS:
            toks = toks[1:]
            continue
        if head in DECLARERS:
            rest = toks[1:]
            while rest and rest[0].startswith("-"):
                rest = rest[1:]
            for t in rest:
                if PATH_ASSIGN_RE.match(t):
                    return "%s path=" % head
            # `local path` with no value sets PATH to empty — measured on zsh
            # 5.9. typeset/declare without a value leave PATH intact.
            if head == "local" and any(t == "path" for t in rest):
                return "local path (no value)"
            return None
        if ASSIGN_RE.match(head):
            if PATH_ASSIGN_RE.match(head):
                if head.startswith("path+="):
                    return "path+=("
                if len(toks) > 1 and not all("=" in t for t in toks):
                    return "path= as a command prefix"
                return "path="
            toks = toks[1:]  # non-path VAR=value prefix: peel and keep looking
            continue
        break
    if not toks:
        return None

    if toks[0] in ("for", "select") and len(toks) > 1 and toks[1] == "path":
        return "%s path in" % toks[0]

    if toks[0] == "read":
        i, names = 1, []
        while i < len(toks):
            t = toks[i]
            if t.startswith("-"):
                i += 2 if t in ARG_FLAGS else 1
                continue
            if t in ("<", ">", ">>"):
                i += 2  # bare redirect: skip the operator and its target word
                continue
            if t.startswith("<") or t.startswith(">"):
                i += 1
                continue
            names.append(t)
            i += 1
        if "path" in names:
            return "read ... path"
    return None


def main():
    cmd = sys.stdin.read()
    if not cmd.strip():
        return
    scan = blank_shell(blank_arithmetic(cmd))
    for seg in segments(scan):
        hit = footgun_shape(seg.strip())
        if hit:
            sys.stdout.write(hit)
            return


if __name__ == "__main__":
    main()
