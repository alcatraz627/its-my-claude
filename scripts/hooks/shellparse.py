#!/usr/bin/env python3
"""Read a Bash-tool command string the way the shell would, once, for every guard.

A guard that greps the raw string fires on a mention (`echo "git push origin
main"`, a heredoc that documents a verb) and misses a command that is wrapped,
quoted, path-qualified or sits behind a keyword (`bash -c "rm x"`, `do rm $f`,
`{ rm x; }`). This module is the one reader every Bash guard shares, so a fix
to how commands are read lands once.

The rule it enforces: a word is a command word only when it is the first word
of a simple command after prefixes (env, sudo, command ...) and keywords (do,
then, { ...) are peeled. Quoted text becomes a command only where the shell
would run it: `bash -c`, `eval`, `ssh` (remote part), `xargs`, `find -exec`,
`$( )` and backticks (also inside double quotes and unquoted heredocs), `<( )`,
and a heredoc fed to a shell. Everything else in quotes is data. The layout of
what `parse` returns, and the plan behind it, is in
assets/reports/20261026-push2-plan/plan.md section 3.

CLI (command on stdin; any internal error exits 2 with nothing on stdout, so
each guard keeps its own documented failure direction):

    shellparse.py json                 the whole parse as JSON
    shellparse.py has NAME [SUB...]    matching command lines; exit 1 when none
    shellparse.py skeleton             same-length text with quoted contents,
                                       heredoc bodies and comments blanked, but
                                       bash -c / eval bodies and $( ) left visible
    shellparse.py lines [--redirects]  one line per command run (name, then
                                       arguments), optionally each write
                                       redirect after it; exit 3 when unreadable
"""
import json
import re
import sys
from dataclasses import asdict, dataclass, field

SHELLS = {"bash", "sh", "zsh", "dash", "ksh"}
# Words that open or close a compound command. The word after an opener is a
# command the shell runs; a closer alone is no command at all.
OPENERS = {"if", "then", "elif", "else", "do", "while", "until", "!", "{", "(("}
CLOSERS = {"fi", "done", "esac", "}"}
# Wrappers that run the rest of the line, with the flags that take a value.
PREFIX_VALUE_FLAGS = {
    "env": {"-u", "-C", "-P", "-S"},
    "sudo": {"-u", "-g", "-h", "-p", "-C", "-D", "-r", "-t", "-U", "-T"},
    "doas": {"-u", "-C"},
    "nice": {"-n"},
    "exec": {"-a"},
    "timeout": {"-s", "-k", "--signal", "--kill-after"},
    "command": set(), "builtin": set(), "nohup": set(), "time": set(),
    "noglob": set(), "nocorrect": set(),
}
XARGS_VALUE_FLAGS = {"-I", "-n", "-P", "-L", "-d", "-E", "-s", "-J", "-R", "-S", "-a"}
SSH_VALUE_FLAGS = set("-b -c -D -E -e -F -I -i -J -L -l -m -O -o -p -Q -R -S -W -w -B".split())
SUBCOMMAND_VALUE_FLAGS = {
    "git": {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--config-env"},
    "gh": {"-R", "--repo", "--hostname"},
}
MAX_DEPTH = 6
CHAIN_OPS = {"&&", "||", ";", "|", "|&", "&", "\n"}
META = set(" \t\n;&|()<>")
ASSIGN_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(\[[^\]]*\])?\+?=")
REDIR_RE = re.compile(r"(\d*)(&>>|&>|>>|>\||>&|<<<|<<-|<<|<>|<&|>|<)")
OPS = ("&&", "||", ";;", ";&", "|&", "&", ";", "|", "(", ")")


@dataclass
class Word:
    text: str
    raw: str
    quoted: str = "none"   # none | single | double | ansi | mixed
    expands: bool = False
    span: tuple = None
    substs: list = field(default_factory=list, repr=False)  # (via, body, abs offset or None)


@dataclass
class Redirect:
    fd: str
    op: str
    target: Word = None
    heredoc: int = None


@dataclass
class Heredoc:
    delim: str
    body: str
    span: tuple
    quoted: bool
    fed_to_shell: bool = False
    owner: int = None


@dataclass
class Command:
    name: str
    argv: list
    assignments: list = field(default_factory=list)
    prefixes: list = field(default_factory=list)
    redirects: list = field(default_factory=list)
    via: str = "top"
    depth: int = 0
    segment: int = 0
    span: tuple = None

    def words(self):
        return [w.text for w in self.argv]

    def line(self):
        return " ".join([self.name] + [w.text for w in self.argv[1:]])


@dataclass
class Op:
    op: str
    pos: int


@dataclass
class Parse:
    ok: bool = True
    commands: list = field(default_factory=list)
    heredocs: list = field(default_factory=list)
    comments: list = field(default_factory=list)
    operators: list = field(default_factory=list)
    skeleton: str = ""
    exec_bodies: list = field(default_factory=list)  # (via, text)


# Lexing

def match_close(s, i):
    """Index of the bracket closing the one at s[i] ('(' or '{'), or -1."""
    open_c = s[i]
    close_c = ")" if open_c == "(" else "}"
    depth, j, n = 1, i + 1, len(s)
    while j < n:
        c = s[j]
        if c == "\\":
            j += 2
            continue
        if c == "'":
            k = s.find("'", j + 1)
            if k < 0:
                return -1
            j = k + 1
            continue
        if c == '"':
            j = skip_double(s, j)
            if j < 0:
                return -1
            continue
        if c == "`":
            k = skip_backtick(s, j)
            if k < 0:
                return -1
            j = k + 1
            continue
        if c == open_c:
            depth += 1
        elif c == close_c:
            depth -= 1
            if depth == 0:
                return j
        j += 1
    return -1


def skip_double(s, i):
    """Index just past the double-quoted string opening at s[i], or -1."""
    j, n = i + 1, len(s)
    while j < n:
        c = s[j]
        if c == "\\":
            j += 2
            continue
        if c == '"':
            return j + 1
        if s.startswith("$(", j):
            k = match_close(s, j + 1)
            if k < 0:
                return -1
            j = k + 1
            continue
        if c == "`":
            k = skip_backtick(s, j)
            if k < 0:
                return -1
            j = k + 1
            continue
        j += 1
    return -1


def skip_backtick(s, i):
    """Index of the backtick closing the one at s[i], or -1."""
    j, n = i + 1, len(s)
    while j < n:
        if s[j] == "\\":
            j += 2
            continue
        if s[j] == "`":
            return j
        j += 1
    return -1


ANSI_ESCAPES = {"n": "\n", "t": "\t", "r": "\r", "\\": "\\", "'": "'", '"': '"', "a": "\a",
                "b": "\b", "e": "\x1b", "f": "\f", "v": "\v"}


class Lexer:
    """One pass over a command string: words, operators, redirects, heredocs, comments.

    Quote state, substitutions and heredoc collection share the walk, because a
    << inside quotes is text and a quote inside a heredoc body is text; two
    passes in either order get one of them wrong.
    """

    def __init__(self, s, base=None):
        self.s, self.n, self.i = s, len(s), 0
        self.base = base            # absolute offset of s, or None when unknown
        self.toks = []              # Word | Redirect | Op
        self.heredocs = []
        self.pending = []           # (heredoc index, delim, strip_tabs)
        self.comments = []
        self.blank = []             # local spans blanked in the skeleton
        self.keep = []              # local spans kept visible inside a blank
        self.ok = True

    def abs(self, a, b):
        return None if self.base is None else (self.base + a, self.base + b)

    def run(self):
        s = self.s
        while self.i < self.n:
            c = s[self.i]
            if c in " \t":
                self.i += 1
            elif s.startswith("\\\n", self.i):
                self.i += 2
            elif c == "\n":
                self.toks.append(Op("\n", self.i))
                self.i += 1
                if self.pending:
                    self.read_bodies()
            elif c == "#":
                j = s.find("\n", self.i)
                j = self.n if j < 0 else j
                self.comments.append(self.abs(self.i, j) or (self.i, j))
                self.blank.append((self.i, j))
                self.i = j
            elif self.redirect():
                pass
            elif c in ";&|()" and not s.startswith("((", self.i):
                op = next(o for o in OPS if s.startswith(o, self.i))
                self.toks.append(Op(op, self.i))
                self.i += len(op)
            elif s.startswith("((", self.i):
                # Arithmetic command `(( i++ ))`: a word, not two subshells.
                k = match_close(s, self.i + 1)
                end = self.n if k < 0 else k + 1
                if k >= 0 and end < self.n and s[end] == ")":
                    end += 1
                self.blank.append((self.i + 2, max(self.i + 2, end - 2)))
                self.toks.append(Word("((", s[self.i:end], span=self.abs(self.i, end)))
                self.i = end
            else:
                w = self.word()
                if w is not None:
                    self.toks.append(w)
        if self.pending:
            self.ok = False
        return self

    def redirect(self):
        s = self.s
        if s.startswith("<(", self.i) or s.startswith(">(", self.i):
            return False
        m = REDIR_RE.match(s, self.i)
        if not m:
            return False
        fd, op = m.group(1), m.group(2)
        start = self.i
        self.i = m.end()
        while self.i < self.n and s[self.i] in " \t":
            self.i += 1
        if self.i >= self.n or s[self.i] in "\n;&|()" or (s[self.i] in "<>" and not s.startswith("<(", self.i) and not s.startswith(">(", self.i)):
            self.toks.append(Redirect(fd, op))
            return True
        target = self.word()
        r = Redirect(fd, op, target)
        if op in ("<<", "<<-") and target is not None:
            idx = len(self.heredocs)
            self.heredocs.append(Heredoc(target.text, "", None, target.quoted != "none" or "\\" in target.raw))
            self.pending.append((idx, target.text, op == "<<-"))
            r.heredoc = idx
        self.toks.append(r)
        return True

    def read_bodies(self):
        s = self.s
        first = True
        while self.pending and self.i <= self.n:
            idx, delim, strip_tabs = self.pending.pop(0)
            if not first and self.i < self.n and s[self.i] == "\n":
                self.i += 1   # the next body starts on the line after this terminator
            first = False
            start = self.i
            pos = self.i
            found = False
            while pos < self.n:
                nl = s.find("\n", pos)
                line_end = self.n if nl < 0 else nl
                line = s[pos:line_end]
                if (line.lstrip("\t") if strip_tabs else line) == delim:
                    body_end = pos
                    self.i = line_end
                    found = True
                    break
                pos = line_end + 1
            if not found:
                body_end = self.n
                self.i = self.n
                self.ok = False
            h = self.heredocs[idx]
            h.body = s[start:body_end]
            h.span = self.abs(start, body_end) or (start, body_end)
            self.blank.append((start, body_end))
            if not h.quoted:
                # An unquoted delimiter means $( ) and backticks in the body run.
                for via, body, off in find_substs(h.body, start):
                    h_off = None if self.base is None else self.base + off
                    self.keep.append((off - (2 if via == "$()" else 1), off + len(body) + 1))
                    self.toks.append(Word("", "", substs=[("heredoc " + via, body, h_off)]))

    def word(self):
        s = self.s
        start = self.i
        text, kinds, expands, substs = [], set(), False, []
        while self.i < self.n:
            c = s[self.i]
            if c in "<>" and self.i + 1 < self.n and s[self.i + 1] == "(":
                k = match_close(s, self.i + 1)
                if k < 0:
                    self.ok = False
                    k = self.n - 1
                substs.append(("<()", s[self.i + 2:k], self.off(self.i + 2)))
                text.append(s[self.i:k + 1])
                expands = True
                self.i = k + 1
                continue
            if c in META:
                break
            if c == "\\":
                if self.i + 1 < self.n and s[self.i + 1] == "\n":
                    self.i += 2
                    continue
                text.append(s[self.i + 1:self.i + 2])
                kinds.add("escape")
                self.i += 2
                continue
            if c == "'":
                k = s.find("'", self.i + 1)
                if k < 0:
                    self.ok = False
                    k = self.n
                text.append(s[self.i + 1:k])
                self.blank.append((self.i + 1, k))
                kinds.add("single")
                self.i = k + 1
                continue
            if s.startswith("$'", self.i):
                j, out = self.i + 2, []
                while j < self.n and s[j] != "'":
                    if s[j] == "\\" and j + 1 < self.n:
                        out.append(ANSI_ESCAPES.get(s[j + 1], "\\" + s[j + 1]))
                        j += 2
                        continue
                    out.append(s[j])
                    j += 1
                if j >= self.n:
                    self.ok = False
                text.append("".join(out))
                self.blank.append((self.i + 2, min(j, self.n)))
                kinds.add("ansi")
                self.i = j + 1
                continue
            if c == '"':
                self.double(text, substs)
                kinds.add("double")
                if "$" in text[-1] or "`" in text[-1]:
                    expands = True
                continue
            if c == "`":
                k = skip_backtick(s, self.i)
                if k < 0:
                    self.ok = False
                    k = self.n
                substs.append(("backtick", s[self.i + 1:k], self.off(self.i + 1)))
                text.append(s[self.i:k + 1])
                expands = True
                self.i = k + 1
                continue
            if c == "$" and self.i + 1 < self.n:
                nxt = s[self.i + 1]
                if s.startswith("$((", self.i):
                    k = match_close(s, self.i + 1)
                    k = self.n - 1 if k < 0 else k
                    self.blank.append((self.i + 3, max(self.i + 3, k - 1)))
                    text.append(s[self.i:k + 1])
                    expands = True
                    self.i = k + 1
                    continue
                if nxt in "({":
                    k = match_close(s, self.i + 1)
                    if k < 0:
                        self.ok = False
                        k = self.n - 1
                    if nxt == "(":
                        substs.append(("$()", s[self.i + 2:k], self.off(self.i + 2)))
                    text.append(s[self.i:k + 1])
                    expands = True
                    self.i = k + 1
                    continue
                if nxt.isalnum() or nxt in "_?@#$!*-":
                    expands = True
            text.append(c)
            self.i += 1
        if self.i == start:
            # A lone metacharacter the walk did not claim; step past it.
            self.i += 1
            return None
        kinds.discard("escape")
        quoted = "none" if not kinds else (kinds.pop() if len(kinds) == 1 else "mixed")
        return Word("".join(text), s[start:self.i], quoted, expands, self.abs(start, self.i), substs)

    def off(self, local):
        return None if self.base is None else self.base + local

    def double(self, text, substs):
        """Consume a "..." string at self.i, appending its value and its substitutions."""
        s = self.s
        j, out = self.i + 1, []
        inner_start = j
        while j < self.n:
            c = s[j]
            if c == "\\" and j + 1 < self.n:
                if s[j + 1] in '$`"\\':
                    out.append(s[j + 1])
                elif s[j + 1] != "\n":
                    out.append(s[j:j + 2])
                j += 2
                continue
            if c == '"':
                break
            if s.startswith("$((", j):
                k = match_close(s, j + 1)
                k = self.n - 1 if k < 0 else k
                out.append(s[j:k + 1])
                j = k + 1
                continue
            if s.startswith("$(", j):
                k = match_close(s, j + 1)
                if k < 0:
                    self.ok = False
                    k = self.n - 1
                substs.append(("$()", s[j + 2:k], self.off(j + 2)))
                self.keep.append((j, k + 1))
                out.append(s[j:k + 1])
                j = k + 1
                continue
            if c == "`":
                k = skip_backtick(s, j)
                if k < 0:
                    self.ok = False
                    k = self.n - 1
                substs.append(("backtick", s[j + 1:k], self.off(j + 1)))
                self.keep.append((j, k + 1))
                out.append(s[j:k + 1])
                j = k + 1
                continue
            out.append(c)
            j += 1
        if j >= self.n:
            self.ok = False
        self.blank.append((inner_start, min(j, self.n)))
        text.append("".join(out))
        self.i = j + 1


def find_substs(text, base):
    """$( ) and backtick bodies in an unquoted heredoc body: (via, body, local offset)."""
    out, i, n = [], 0, len(text)
    while i < n:
        if text[i] == "\\":
            i += 2
            continue
        if text.startswith("$((", i):
            k = match_close(text, i + 1)
            i = n if k < 0 else k + 1
            continue
        if text.startswith("$(", i):
            k = match_close(text, i + 1)
            if k < 0:
                break
            out.append(("$()", text[i + 2:k], base + i + 2))
            i = k + 1
            continue
        if text[i] == "`":
            k = skip_backtick(text, i)
            if k < 0:
                break
            out.append(("backtick", text[i + 1:k], base + i + 1))
            i = k + 1
            continue
        i += 1
    return out


# Building commands

def basename(word):
    return word.rsplit("/", 1)[-1]


def peel(words):
    """Split leading assignments, keywords and wrappers off a word list.

    Returns (assignments, prefixes, argv, lookup_only). lookup_only is true for
    `command -v X` and `type X`-like lookups that never run X.
    """
    assigns, prefixes, i = [], [], 0
    lookup = False
    while i < len(words):
        w = words[i]
        if w.quoted == "none" and w.text in OPENERS | CLOSERS:
            i += 1
            continue
        if w.quoted == "none" and w.text == "function" and i + 1 < len(words):
            i += 2
            continue
        if ASSIGN_RE.match(w.raw):
            k, _, v = w.text.partition("=")
            assigns.append((k.rstrip("+"), v))
            i += 1
            continue
        b = basename(w.text)
        if b in PREFIX_VALUE_FLAGS and w.quoted == "none":
            prefixes.append(b)
            vflags = PREFIX_VALUE_FLAGS[b]
            i += 1
            while i < len(words):
                f = words[i].text
                if b == "command" and f in ("-v", "-V"):
                    lookup = True
                if b == "env" and ASSIGN_RE.match(words[i].raw):
                    k, _, v = f.partition("=")
                    assigns.append((k, v))
                    i += 1
                elif f.startswith("-") and len(f) > 1 and f != "--":
                    i += 2 if f in vflags else 1
                elif f == "--":
                    i += 1
                    break
                elif b == "nice" and re.match(r"^-\d+$", f):
                    i += 1
                else:
                    break
            if b == "timeout" and i < len(words):
                i += 1  # the duration
            continue
        break
    return assigns, prefixes, words[i:], lookup


def shell_c_body(argv):
    """`bash -c BODY` (or -lc, -ec ...): BODY, else None."""
    i = 1
    while i < len(argv):
        w = argv[i].text
        if w in ("-o", "+o", "-O", "+O", "--rcfile", "--init-file"):
            i += 2
            continue
        if w.startswith("-") and not w.startswith("--") and "c" in w[1:]:
            return argv[i + 1].text if i + 1 < len(argv) else ""
        if not w.startswith("-") and not w.startswith("+"):
            return None
        i += 1
    return None


def shell_reads_stdin(argv):
    ops = [w.text for w in argv[1:]]
    if "-s" in ops:
        return True
    i = 0
    while i < len(ops):
        if ops[i] in ("-o", "+o", "-O", "+O", "--rcfile", "--init-file"):
            i += 2
            continue
        if not (ops[i].startswith("-") or ops[i].startswith("+")):
            return False
        i += 1
    return True


class Builder:
    def __init__(self, src):
        self.src = src
        self.p = Parse()
        self.exec_words = []   # depth-0 words whose quoted body the shell runs

    def parse(self, s, via="top", depth=0, segment=0, base=0):
        if depth > MAX_DEPTH:
            return
        lx = Lexer(s, base).run()
        if not lx.ok:
            self.p.ok = False
        if depth == 0:
            self.lexer = lx
            self.p.comments = lx.comments
        hd_base = len(self.p.heredocs)
        for h in lx.heredocs:
            self.p.heredocs.append(h)
        groups = []   # (words+redirects, terminating op, segment index, pipe group)
        cur, seg, pipe = [], segment, 0
        toks = lx.toks
        for t_i, t in enumerate(toks):
            if isinstance(t, Op):
                groups.append((cur, t.op, seg, pipe, t_i))
                cur = []
                if depth == 0 and t.op in CHAIN_OPS | {"(", ")", ";;", ";&"}:
                    self.p.operators.append(Op(t.op, t.pos))
                if depth == 0 and t.op in CHAIN_OPS:
                    seg += 1
                if t.op not in ("|", "|&"):
                    pipe += 1
            else:
                cur.append(t)
        groups.append((cur, None, seg, pipe, len(toks)))

        stdin_shells = set()   # pipe groups with a shell reading stdin
        owned = []             # (heredoc local idx, pipe group, owner cmd index, owner is stdin shell)
        case_pattern = False
        for g_i, (items, op, seg_i, pipe_i, t_i) in enumerate(groups):
            words = [x for x in items if isinstance(x, Word)]
            redirs = [x for x in items if isinstance(x, Redirect)]
            # Substitutions run wherever they sit, even in a dropped header.
            for w in words + [r.target for r in redirs if r.target is not None]:
                for sv, body, off in w.substs:
                    self.p.exec_bodies.append((sv, body))
                    self.parse(body, sv, depth + 1, seg_i, off)
            heads = [w.text for w in words[:1] if w.quoted == "none"]
            if case_pattern and op == ")":
                case_pattern = False
                continue
            if heads and heads[0] == "case":
                case_pattern = True
                if op == ")":
                    case_pattern = False
                continue
            if op in (";;", ";&"):
                case_pattern = True
            if heads and heads[0] in ("for", "select"):
                continue
            # `f() { ...; }`: the name before an empty () pair is a definition.
            if op == "(" and len(words) == 1 and t_i + 1 < len(toks) and isinstance(toks[t_i + 1], Op) and toks[t_i + 1].op == ")":
                continue
            if not words and not redirs:
                continue
            assigns, prefixes, argv, lookup = peel(words)
            if lookup or not argv:
                if redirs:
                    c = Command("", [], assigns, prefixes, redirs, via, depth, seg_i, None)
                    self.add(c, depth, items)
                    for r in redirs:
                        if r.heredoc is not None:
                            owned.append((hd_base + r.heredoc, pipe_i, len(self.p.commands) - 1, False))
                continue
            name = basename(argv[0].text)
            c = Command(name, argv, assigns, prefixes, redirs, via, depth, seg_i, None)
            idx = self.add(c, depth, items)
            reads = False
            if name in SHELLS:
                body = shell_c_body(argv)
                if body is not None:
                    pos = next((k for k in range(1, len(argv)) if argv[k].text == body and k > 0 and argv[k - 1].text.startswith("-")), None)
                    if depth == 0 and pos is not None:
                        self.exec_words.append(argv[pos])
                    self.exec(body, "bash -c", depth, seg_i)
                elif shell_reads_stdin(argv):
                    reads = True
                    stdin_shells.add(pipe_i)
            elif name == "eval" and len(argv) > 1:
                if depth == 0:
                    self.exec_words.extend(argv[1:])
                self.exec(" ".join(w.text for w in argv[1:]), "eval", depth, seg_i)
            elif name == "ssh":
                rest, k = [], 1
                while k < len(argv):
                    t = argv[k].text
                    if t in SSH_VALUE_FLAGS:
                        k += 2
                        continue
                    if t.startswith("-"):
                        k += 1
                        continue
                    rest = argv[k + 1:]
                    break
                if rest:
                    self.exec(" ".join(w.text for w in rest), "ssh", depth, seg_i)
            elif name == "xargs":
                k = 1
                while k < len(argv) and argv[k].text.startswith("-"):
                    k += 2 if argv[k].text in XARGS_VALUE_FLAGS else 1
                if k < len(argv):
                    self.sub(argv[k:], "xargs", depth, seg_i)
            elif name == "find":
                k = 0
                while k < len(argv):
                    if argv[k].text in ("-exec", "-execdir", "-ok", "-okdir"):
                        j = k + 1
                        while j < len(argv) and argv[j].text not in (";", "+"):
                            j += 1
                        self.sub(argv[k + 1:j], "find -exec", depth, seg_i)
                        k = j
                    k += 1
            for r in redirs:
                if r.heredoc is not None:
                    owned.append((hd_base + r.heredoc, pipe_i, idx, reads))

        for h_i, pipe_i, owner, reads in owned:
            h = self.p.heredocs[h_i]
            h.owner = owner
            if reads or pipe_i in stdin_shells:
                h.fed_to_shell = True
                self.exec(h.body, "heredoc|shell", depth, self.p.commands[owner].segment)

    def add(self, c, depth, items):
        if depth == 0:
            spans = [x.span for x in items if isinstance(x, Word) and x.span] + \
                    [x.target.span for x in items if isinstance(x, Redirect) and x.target is not None and x.target.span]
            if spans:
                c.span = (min(a for a, _ in spans), max(b for _, b in spans))
        self.p.commands.append(c)
        return len(self.p.commands) - 1

    def exec(self, body, via, depth, seg):
        self.p.exec_bodies.append((via, body))
        self.parse(body, via, depth + 1, seg, None)

    def sub(self, words, via, depth, seg):
        """A command spelled as arguments of xargs or find -exec."""
        if depth + 1 > MAX_DEPTH or not words:
            return
        assigns, prefixes, argv, lookup = peel(words)
        if lookup or not argv:
            return
        c = Command(basename(argv[0].text), argv, assigns, prefixes, [], via, depth + 1, seg, None)
        self.p.commands.append(c)
        if c.name in SHELLS:
            body = shell_c_body(argv)
            if body is not None:
                self.exec(body, "bash -c", depth + 1, seg)

    def skeleton(self, keep_exec):
        s = self.src
        mask = [False] * len(s)
        lx = getattr(self, "lexer", None)
        if lx is None:
            return s
        for a, b in lx.blank:
            for k in range(max(a, 0), min(b, len(s))):
                mask[k] = True
        keeps = list(lx.keep)
        if keep_exec:
            keeps += [w.span for w in self.exec_words if w.span]
        for a, b in keeps:
            for k in range(max(a, 0), min(b, len(s))):
                mask[k] = False
        return "".join(" " if m and ch != "\n" else ch for ch, m in zip(s, mask))


_CACHE = {}


def parse(cmd):
    """Parse `cmd` once; repeated calls with the same string reuse the result."""
    if cmd in _CACHE:
        return _CACHE[cmd]
    b = Builder(cmd)
    b.parse(cmd)
    b.p.skeleton = b.skeleton(keep_exec=False)
    b.p._bridge = b.skeleton(keep_exec=True)
    if len(_CACHE) > 64:
        _CACHE.clear()
    _CACHE[cmd] = b.p
    return b.p


# Helpers guards call

def commands(cmd, name=None):
    return [c for c in parse(cmd).commands if name is None or c.name == name]


def subcommand_words(c):
    """The words after the command name with global flags (and their values) skipped."""
    vflags = SUBCOMMAND_VALUE_FLAGS.get(c.name, set())
    out, k, argv = [], 1, c.argv
    while k < len(argv):
        t = argv[k].text
        if t in vflags:
            k += 2
            continue
        if t.startswith("-") and not out:
            k += 1
            continue
        out.append(t)
        k += 1
    return out


def has(cmd, name, *subs):
    """Commands named `name` whose leading subcommand words are `subs`."""
    return [c for c in commands(cmd, name) if subcommand_words(c)[:len(subs)] == list(subs)]


WRITE_LAST = {"cp", "mv", "ln", "install", "rsync", "ditto"}
WRITE_ALL = {"tee", "touch", "mkdir", "trash", "truncate"}
WRITE_OPS = {">", ">>", ">|", "&>", "&>>", "<>"}


def operands(argv, value_flags=()):
    out, k = [], 1
    while k < len(argv):
        t = argv[k].text
        if t == "--":
            out.extend(w.text for w in argv[k + 1:])
            break
        if t.startswith("-") and len(t) > 1:
            k += 2 if t in value_flags else 1
            continue
        out.append(t)
        k += 1
    return out


def write_targets(cmd):
    """Paths a command writes: redirect targets plus the operands write verbs write.

    Returns (path, how) pairs, `how` being "redirect" or the verb name.
    """
    out = []
    for c in parse(cmd).commands:
        for r in c.redirects:
            if r.op in WRITE_OPS and r.target is not None:
                out.append((r.target.text, "redirect"))
            elif r.op == ">&" and r.target is not None and not re.match(r"^(\d+|-)$", r.target.text):
                out.append((r.target.text, "redirect"))
        n = c.name
        if n in WRITE_LAST:
            words = c.words()
            if "-t" in words and words.index("-t") + 1 < len(words):
                out.append((words[words.index("-t") + 1], n))
            else:
                ops = operands(c.argv, {"-S", "-B", "--suffix"})
                if len(ops) >= 2:
                    out.append((ops[-1], n))
        elif n in WRITE_ALL:
            for o in operands(c.argv, {"-s", "-m", "-r"} if n in ("truncate", "mkdir") else ()):
                out.append((o, n))
        elif n == "dd":
            for w in c.argv[1:]:
                if w.text.startswith("of="):
                    out.append((w.text[3:], n))
        elif n == "sed" and any(w.text.startswith("-i") or w.text == "--in-place" for w in c.argv[1:]):
            out.extend((p, n) for p in sed_files(c.argv))
        elif n == "perl" and any(re.match(r"^-[a-zA-Z]*i", w.text) for w in c.argv[1:]):
            out.extend((p, n) for p in operands(c.argv, {"-e", "-E", "-M", "-I"}))
    return out


def sed_files(argv):
    files, script_given, k = [], False, 1
    while k < len(argv):
        t = argv[k].text
        if t in ("-e", "-f", "--expression", "--file"):
            script_given = True
            k += 2
            continue
        if t == "-i":
            # BSD sed: `-i ''` or `-i .bak` takes the next word as the suffix.
            if k + 1 < len(argv) and (argv[k + 1].text == "" or argv[k + 1].text.startswith(".")):
                k += 1
            k += 1
            continue
        if t.startswith("-") and len(t) > 1:
            k += 1
            continue
        files.append(t)
        k += 1
    return files if script_given else files[1:]


MESSAGE_FLAGS = {"-m", "--message", "--body", "--title", "--body-file", "--notes"}


def message_args(command, p=None):
    """Values a command takes as message text: -m, --message, -F - (its heredoc), --body, --title."""
    out, argv, k = [], command.argv, 1
    gh_short = {"-b", "-t"} if command.name == "gh" else set()
    while k < len(argv):
        t = argv[k].text
        if t in MESSAGE_FLAGS | gh_short and k + 1 < len(argv):
            out.append(argv[k + 1].text)
            k += 2
            continue
        if t in ("-F", "--file") and k + 1 < len(argv):
            if argv[k + 1].text == "-" and p is not None:
                out.extend(h.body for h in p.heredocs if h.owner is not None and p.commands[h.owner] is command)
            k += 2
            continue
        for f in ("--message=", "--body=", "--title="):
            if t.startswith(f):
                out.append(t[len(f):])
        if t.startswith("-m") and len(t) > 2 and not t.startswith("--"):
            out.append(t[2:])
        k += 1
    return out


RUNNERS = {"npx": {"-p", "--package"}, "bunx": {"-p", "--package"}, "pnpx": set()}
RUNNER_PAIRS = {("pnpm", "dlx"), ("yarn", "dlx"), ("npm", "exec"), ("bun", "x")}


def command_lines(cmd, redirects=False):
    """One line per command the shell would run: its name, then its arguments.

    A package runner (npx vercel, pnpm dlx wrangler) is unwrapped to the tool it
    runs, so a guard can match the tool at the start of a line. Newlines inside
    an argument become spaces, so one command is always one line. With
    redirects, each write redirect follows its command as its own line,
    "> target" or ">> target", so a guard can anchor on it too.
    """
    out = []
    for c in parse(cmd).commands:
        writes = []
        if redirects:
            for r in c.redirects:
                if r.target is None:
                    continue
                if r.op in WRITE_OPS or (r.op == ">&" and not re.match(r"^(\d+|-)$", r.target.text)):
                    writes.append((">>" if r.op in (">>", "&>>") else ">") + " " + r.target.text.replace("\n", " "))
        if not c.name:
            out.extend(writes)
            continue
        words = c.words()
        rest = None
        if c.name in RUNNERS:
            k = 1
            while k < len(words) and words[k].startswith("-"):
                k += 2 if words[k] in RUNNERS[c.name] else 1
            rest = words[k:]
        elif len(words) > 1 and (c.name, words[1]) in RUNNER_PAIRS:
            rest = words[2:]
        if rest:
            words = [basename(rest[0])] + rest[1:]
        else:
            words = [c.name] + words[1:]
        out.append(" ".join(w.replace("\n", " ") for w in words))
        out.extend(writes)
    return out


def exec_texts(cmd):
    """Texts a wrapper would execute, plus each simple command inside them."""
    out = []
    for _via, body in parse(cmd).exec_bodies:
        out.append(body)
        out.extend(body[c.span[0]:c.span[1]] for c in parse(body).commands if c.depth == 0 and c.span)
    return out


# CLI

def to_json(p):
    d = asdict(p)
    for c in d["commands"]:
        for w in c["argv"]:
            w.pop("substs", None)
        for r in c["redirects"]:
            if r["target"]:
                r["target"].pop("substs", None)
    d["exec_bodies"] = [{"via": v, "text": t} for v, t in p.exec_bodies]
    return d


def main(argv):
    mode = argv[1] if len(argv) > 1 else ""
    cmd = sys.stdin.read()
    if mode == "json":
        sys.stdout.write(json.dumps(to_json(parse(cmd))) + "\n")
        return 0
    if mode == "has" and len(argv) > 2:
        hits = has(cmd, argv[2], *argv[3:])
        for c in hits:
            print(c.line())
        return 0 if hits else 1
    if mode == "skeleton":
        sys.stdout.write(parse(cmd)._bridge)
        return 0
    if mode == "lines":
        # Exit 3 on a command the parser cannot read, so the guard falls back to its raw match.
        if not parse(cmd).ok:
            return 3
        for line in command_lines(cmd, redirects="--redirects" in argv[2:]):
            print(line)
        return 0
    print("usage: shellparse.py json | has NAME [SUB...] | skeleton | lines  < command", file=sys.stderr)
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except Exception:  # noqa: BLE001  the guard picks its own failure direction
        sys.exit(2)
