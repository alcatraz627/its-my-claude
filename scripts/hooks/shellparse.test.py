#!/usr/bin/env python3
"""Tests for shellparse.py: which words come out as commands, and what they carry.

Run: python3 shellparse.test.py   (SP=<path> points it at a mutated copy)
"""
import importlib.util
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.environ.get("SP", os.path.join(HERE, "shellparse.py"))
spec = importlib.util.spec_from_file_location("shellparse", SRC)
sp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sp)

passed = failed = 0


def check(label, cond, detail=""):
    global passed, failed
    if cond:
        passed += 1
        print(f"  ok    {label}")
    else:
        failed += 1
        print(f"  FAIL  {label}  {detail}")


def names(cmd):
    return [c.name for c in sp.parse(cmd).commands if c.name]


def lines(cmd, name):
    return [c.line() for c in sp.commands(cmd, name)]


print("── commands the shell runs come out; mentions do not ──")
for cmd, want in [
    ('echo "do not rm -rf the repo"', []),
    ('git commit -m "docs: explain git push origin main"', []),
    ('rg -n "next|vercel|gh" src/', []),
    ("python3 -c \"patterns = ['git stash list', 'git reset']\"", []),
    ("claude-ipc send --to peer 'I ran git stash earlier, FYI'", []),
    ("cat <<'EOF'\nRunbook: git reset HEAD is forbidden here\nEOF", []),
    ("cat > notes.md <<'EOF'\nsudo rm -rf /tmp/x\nEOF", []),
    ("rm -rf build", ["rm -rf build"]),
    ('bash -c "rm notes.txt"', ["rm notes.txt"]),
    ("ls | xargs rm", ["rm"]),
    ("find . -name x -exec rm {} \\;", ["rm {}"]),
    ("sudo rm notes.txt", ["rm notes.txt"]),
    ("/bin/rm a", ["rm a"]),
    ("command rm a", ["rm a"]),
    ("env -i FOO=1 rm a", ["rm a"]),
    ("timeout 5 rm a", ["rm a"]),
    ("nice -n 5 rm a", ["rm a"]),
    ("for f in a b; do rm $f; done", ["rm $f"]),
    ("{ rm x; }", ["rm x"]),
    ("if true; then rm x; fi", ["rm x"]),
    ("while false; do rm x; done", ["rm x"]),
    ("! rm x", ["rm x"]),
    ("echo $((1<<n))\nrm x", ["rm x"]),
    ('echo "$(rm x)"', ["rm x"]),
    ("echo `rm x`", ["rm x"]),
    ("diff <(rm x) y", ["rm x"]),
    ("x=$(rm y)", ["rm y"]),
    ("cat <<EOF\n$(rm q)\nEOF", ["rm q"]),
    ("cat <<'EOF'\n$(rm q)\nEOF", []),
    ("cat <<EOF | bash\nrm w\nEOF", ["rm w"]),
    ("bash <<EOF\nrm w\nEOF", ["rm w"]),
    ("cat <<EOF > out.sh\nrm w\nEOF", []),
    ('eval "rm z"', ["rm z"]),
    ("command -v rm", []),
    ("case $x in a) rm a;; b) rm b;; esac", ["rm a", "rm b"]),
    ("f() { rm x; }; f", ["rm x"]),
    ("echo rm # rm in a comment", []),
    ("sh -lc 'rm a'", ["rm a"]),
    ("bash -o pipefail -c 'rm a'", ["rm a"]),
]:
    got = lines(cmd, "rm")
    check(f"rm in {cmd!r:.60}", got == want, f"got {got}")

print("── case patterns and function names are not commands ──")
check("case pattern words are dropped", "b" not in names("case $x in a) ls;; b) ls;; esac"), names("case $x in a) ls;; b) ls;; esac"))
check("function name before () is dropped", names("f() { ls; }") == ["ls"], names("f() { ls; }"))
check("for header is not a command", names("for f in a b; do ls; done") == ["ls"], names("for f in a b; do ls; done"))
check("substitution in a for header still runs", "rm" in names("for f in $(rm x); do :; done"))

print("── words, quoting and spans ──")
p = sp.parse("git -C '/a b' push origin \"main\"")
c = p.commands[0]
check("de-quoted argv", c.words() == ["git", "-C", "/a b", "push", "origin", "main"], c.words())
check("quote kinds recorded", [w.quoted for w in c.argv] == ["none", "none", "single", "none", "none", "double"], [w.quoted for w in c.argv])
check("span covers the command", c.span == (0, len("git -C '/a b' push origin \"main\"")), c.span)
w = sp.parse("echo $'a\\tb'").commands[0].argv[1]
check("ansi-c quoting decoded", w.text == "a\tb" and w.quoted == "ansi", repr(w.text))
check("expands flags $ outside single quotes", sp.parse('echo "$HOME" \'$X\'').commands[0].argv[1].expands and not sp.parse("echo '$X'").commands[0].argv[1].expands)
check("assignments split off", sp.parse("A=1 B=2 make").commands[0].assignments == [("A", "1"), ("B", "2")])
check("prefixes recorded", sp.parse("sudo env X=1 nohup make").commands[0].prefixes == ["sudo", "env", "nohup"])
check("via and depth for bash -c", [(c.via, c.depth) for c in sp.commands('bash -c "ls"', "ls")] == [("bash -c", 1)])
check("segment index follows the chain", [c.segment for c in sp.parse("a; b && c | d").commands] == [0, 1, 2, 3])

print("── redirects are their own tokens ──")
c = sp.parse("echo x>/etc/hosts 2>&1").commands[0]
check("attached > is a redirect, not part of the word", c.words() == ["echo", "x"], c.words())
check("redirect ops and targets", [(r.fd, r.op, r.target.text) for r in c.redirects] == [("", ">", "/etc/hosts"), ("2", ">&", "1")], c.redirects)
check("&> redirect", sp.parse("make &>log").commands[0].redirects[0].op == "&>")
check("herestring is not a heredoc", not sp.parse("cat <<<EOF").heredocs)

print("── heredocs ──")
p = sp.parse("cat <<'A' > x\nbody1\nA\ncat <<-B\n\tbody2\n\tB\necho done")
check("two heredocs collected", [h.body for h in p.heredocs] == ["body1\n", "\tbody2\n"], [h.body for h in p.heredocs])
check("<<- strips tabs from the terminator", names("cat <<-B\n\tx\n\tB\nls") == ["cat", "ls"], names("cat <<-B\n\tx\n\tB\nls"))
check("indented plain terminator does not close", not sp.parse("cat <<A\nx\n  A\n").ok)
check("heredoc owner recorded", p.heredocs[0].owner == 0)
check("quoted delimiter recorded", p.heredocs[0].quoted and not p.heredocs[1].quoted)
check("unclosed heredoc is not ok", not sp.parse("cat <<A\nnever closed").ok)
check("two heredocs on one line", [h.body for h in sp.parse("paste <<A <<B\na\nA\nb\nB").heredocs] == ["a\n", "b\n"])
check("a << inside quotes is text", not sp.parse("echo 'a <<EOF'").heredocs)
check("heredoc fed to shell is marked", sp.parse("cat <<E | sh\nls\nE").heredocs[0].fed_to_shell)
check("-F - message comes from the heredoc", sp.message_args(sp.parse("git commit -F - <<'E'\nmsg here\nE").commands[0], sp.parse("git commit -F - <<'E'\nmsg here\nE")) == ["msg here\n"])

print("── operators and ok ──")
p = sp.parse("a && b || c; d | e & f\ng")
check("top-level operators in order", [o.op for o in p.operators] == ["&&", "||", ";", "|", "&", "\n"], [o.op for o in p.operators])
check("operators inside quotes are not operators", not sp.parse('git commit -m "fix a && b"').operators)
check("operators inside $( ) are not top level", [o.op for o in sp.parse("echo $(a && b)").operators] == [])
check("unclosed quote is not ok", not sp.parse("echo 'oops").ok)
check("unclosed $( is not ok", not sp.parse("echo $(ls").ok)

print("── skeleton ──")
cmd = "git commit -m 'git push' && echo \"$(git push)\" # git push"
p = sp.parse(cmd)
check("skeleton keeps length", len(p.skeleton) == len(cmd))
check("skeleton blanks single quotes and comments", p.skeleton.count("git push") == 1, repr(p.skeleton))
check("skeleton keeps $( ) inside double quotes", "$(git push)" in p.skeleton, repr(p.skeleton))
br = p._bridge
check("bridge keeps bash -c bodies", "git push" in sp.parse('bash -c "git push"')._bridge and "git push" not in sp.parse('bash -c "git push"').skeleton)
check("skeleton blanks heredoc bodies", "secret" not in sp.parse("cat <<E\nsecret\nE").skeleton)
check("skeleton blanks arithmetic", "<<" not in sp.parse("echo $((1<<n))").skeleton)

print("── helpers ──")
check("has: git push after -C", len(sp.has("git -C /x push origin main", "git", "push")) == 1)
check("has: gh --repo r pr create", len(sp.has("gh --repo o/r pr create", "gh", "pr", "create")) == 1)
check("has: git commit is not git push", not sp.has("git commit -m push", "git", "push"))
wt = sp.write_targets("echo x > a; cp b c; tee d e; dd if=f of=g; sed -i '' -e s/x/y/ h; mkdir -p i; echo 2>&1; bash -c 'echo > j'")
check("write_targets", [p for p, _ in wt] == ["a", "c", "d", "e", "g", "h", "i", "j"], wt)
check("message_args", sp.message_args(sp.parse('git commit -m "a" --message=b -mc').commands[0]) == ["a", "b", "c"])
check("message_args gh", sp.message_args(sp.parse('gh pr create -t T -b B').commands[0]) == ["T", "B"])
check("command_lines unwraps runners and keeps one line per command",
      sp.command_lines('npx -y vercel --prod; pnpm dlx wrangler deploy; rg "a|gh" x; gh pr comment 1 --body "a\nb"')
      == ["vercel --prod", "wrangler deploy", "rg a|gh x", "gh pr comment 1 --body a b"],
      sp.command_lines('npx -y vercel --prod; pnpm dlx wrangler deploy; rg "a|gh" x; gh pr comment 1 --body "a\nb"'))
check("exec_texts includes $( ) bodies", "rm x" in sp.exec_texts('echo "$(rm x)"'))
check("exec_texts",sp.exec_texts('bash -c "ls; rm x"') == ["ls; rm x", "ls", "rm x"], sp.exec_texts('bash -c "ls; rm x"'))

print("── CLI ──")
def cli(*args, stdin=""):
    r = subprocess.run([sys.executable, SRC, *args], input=stdin, capture_output=True, text=True)
    return r.returncode, r.stdout


rc, out = cli("has", "git", "push", stdin='echo "git push"; bash -c "git push origin main"')
check("has exit 0 with the line", rc == 0 and out.strip() == "git push origin main", (rc, out))
rc, out = cli("has", "git", "push", stdin='echo "git push"')
check("has exit 1 when none", rc == 1 and out == "", (rc, out))
rc, out = cli("json", stdin="ls -l")
check("json parses", rc == 0 and '"name": "ls"' in out)
rc, out = cli("bogus", stdin="ls")
check("bad mode exits 2", rc == 2 and out == "")

print(f"---- pass={passed} fail={failed}")
sys.exit(1 if failed else 0)
