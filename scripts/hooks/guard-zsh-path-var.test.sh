#!/usr/bin/env bash
# Tests for guard-zsh-path-var.sh + zsh-path-scan.py.
#
# WARN_LOG_STORE is set below because the previous version of this suite did not
# set it, so every run appended ~8 synthetic block events to the live telemetry
# ledger and poisoned the fire-rate data hook-design decisions read.
#
# Cases marked [adv] came from the 2026-08-13 adversarial review of v1 (24/24
# green while missing the canonical footgun); cases marked [r2] came from the
# same review's second pass over the state-machine rewrite. Every [adv]/[r2]
# footgun row was proven against real zsh 5.9 before it became a test.
#
# HOOK and SCAN are env-overridable so a copy of the pair can be tested in
# isolation (mutation runs need this; the review had to rebuild the suite to
# get it). The hook under test is rewired to $SCAN via a temp copy either way.

export WARN_LOG_STORE="${TMPDIR:-/tmp}/zsh-path-guard-test-events.jsonl"
HOOK="${HOOK:-$HOME/.claude/scripts/hooks/guard-zsh-path-var.sh}"
SCAN="${SCAN:-$HOME/.claude/scripts/hooks/zsh-path-scan.py}"
pass=0; fail=0

WORK=$(mktemp -d)
RUNHOOK="$WORK/hook-under-test.sh"
cp "$HOOK" "$RUNHOOK"
sed -i '' "s#\$HOME/.claude/scripts/hooks/zsh-path-scan.py#$SCAN#" "$RUNHOOK"

verdict() {  # <hook-script> <command>  → WARN | PASS
  local out
  out=$(jq -cn --arg c "$2" '{tool_name:"Bash", tool_input:{command:$c}}' | bash "$1" 2>/dev/null)
  case "$out" in *additionalContext*) echo WARN ;; *) echo PASS ;; esac
}

expect() {  # <want> <label> <command>
  local got; got=$(verdict "$RUNHOOK" "$3")
  if [ "$got" = "$1" ]; then
    printf '  \033[32m✓\033[0m %-8s %s\n' "$got" "$2"; pass=$((pass+1))
  else
    printf '  \033[31m✗\033[0m wanted %-4s got %-4s  %s\n' "$1" "$got" "$2"; fail=$((fail+1))
  fi
}

echo "── must WARN: real zsh footguns ──"
expect WARN "while read path"                'printf "x\n" | while read path; do echo hi; done'
expect WARN "while read ts path"             'ls | while read ts path; do echo "$ts"; done'
expect WARN "while read -r path"             'ls | while read -r path; do echo hi; done'
expect WARN "[adv] while IFS= read -r path"  'printf "a/b\n" | while IFS= read -r path; do :; done'
expect WARN "[adv] IFS=: read -rA path <<<"  'IFS=: read -rA path <<< "aaa:bbb"'
expect WARN "for path in"                    'for path in /a /b; do echo hi; done'
expect WARN "[adv] time-prefixed for path"   'time for path in a b; do :; done'
expect WARN "[adv] footgun beside a heredoc" 'for path in x y; do :; done; cat <<EOF > /tmp/s.sh
hello
EOF'
expect WARN "[adv] path= beside arithmetic"  'path=/tmp/nowhere; echo $((1<<2))'
# A word-operand shift is the case that actually needs blank_arithmetic: <<n
# matches the heredoc-opener pattern, so without blanking it swallows line 2.
expect WARN "arith shift then footgun"       'echo $((1<<n))
for path in a; do :; done'
expect WARN "bare assignment"                'path=/tmp/x'
expect WARN "export assignment"              'export path=/tmp/x'
expect WARN "[adv] path= as command prefix"  'path=/tmp/nowhere env sh -c "echo hi"'
expect WARN "second in a chain"              'cd /tmp && for path in *; do echo hi; done'
expect WARN "[r2] then path="                'if true; then path=/nope; fi'
expect WARN "[r2] do path="                  'for i in 1; do path=/nope; done'
expect WARN "[r2] else path="                'if false; then :; else path=/nope; fi'
expect WARN "[r2] brace group"               '{ path=/nope; }'
expect WARN "[r2] one-line fn local path="   'f(){ local path=/nope; }; f'
expect WARN "[r2] local path, no value"      'f(){ local path; }; f'
expect WARN "[r2] local -a path"             'f(){ local -a path; }; f'
expect WARN "[r2] local path x=1"            'f(){ local path x=1; }; f'
expect WARN "[r2] read -s path (zsh -s has no arg)" 'print hi | read -s path'
expect WARN "[r2] read -n path (zsh -n has no arg)" 'print hi | read -n path'
expect WARN "[r2] read -t path (zsh -t arg is attached)" 'print hi | read -t path'
expect WARN "[r2] read -d : path"            'print "a:b" | read -d : path'
expect WARN "[r2] select path in"            'select path in a b; do break; done'
expect WARN "[r2] ! path="                   '! path=/nope'
ANSI_CASE="echo \$'it\\'s'; for path in a; do :; done"
expect WARN "[r2] \$'...' desync then footgun" "$ANSI_CASE"
expect WARN "[r2] << inside quotes then footgun" 'git commit -m "shift << n notes"
for path in *; do :; done'
expect WARN "[r2] herestring then footgun"   'grep x <<<WORD
for path in a; do :; done'
expect WARN "[r2] spaced herestring then footgun" 'grep x <<< WORD
for path in a; do :; done'
expect WARN "[r2] escaped quote outside quotes" "echo don\\'t; for path in a; do :; done"
expect WARN "[r2] footgun after closed heredoc" 'cat <<EOF
body
EOF
for path in a; do :; done'
expect WARN "[r2] footgun after closed quoted heredoc" "cat <<'SH'
body
SH
for path in a; do :; done"

echo "── must STAY SILENT: lookalikes and safe code ──"
expect PASS "python for-in (quoted)"         'python3 -c "for path in [1,2]: print(path)"'
expect PASS "awk for-in (quoted)"            'awk "{for (path in a) print}" f.txt'
expect PASS "rg pattern containing ="        "rg 'path=[^&]*' file.txt"
# The wild false positive of 2026-08-12: an escaped quote inside a double-quoted
# rg pattern broke sed's pairing and stranded path='/ in statement position.
expect PASS "[adv] the real Versable FP"     'rg -n "path=\"/|path='"'"'/" frontend/src/App.tsx'
expect PASS "jq .path selector"              "jq -r '.path' f.json"
expect PASS "safe loop var p"                'for p in /a /b; do echo hi; done'
expect PASS "safe loop var line"             'while read line; do echo hi; done < f'
expect PASS "safe loop var sha"              'git log --format=%H | while read sha; do echo hi; done'
expect PASS "echo of a literal"              'echo "path=1"'
expect PASS "quoted text holding ; path="    'git commit -m "fix; path=1 handling"'
expect PASS "quoted text holding ; for"      'echo "note; for path in x"'
expect PASS "[adv] multi-line dquote path="  'git commit -m "line one
path=nothing here"'
expect PASS "[adv] multi-line squote for"    "git commit -m 'line one
for path in x'"
expect PASS "[adv] multi-line quoted read"   'echo "intro text
read path from the docs"'
expect PASS "find -name path"                'find . -name path'
expect PASS "uppercase PATH prefix"          'PATH=/x:$PATH ls'
expect PASS "heredoc authoring bash"         'cat <<EOF > s.sh
for path in a; do echo; done
EOF'
expect PASS "no path at all"                 'ls -la /tmp'
expect PASS "[r2] read -p path (no coprocess in a tool call)" 'print hi | read -p path'
expect PASS "[r2] read -k path (no tty in a tool call)" 'read -k path'
expect PASS "[r2] read from a file named path" 'read -r v < path'
expect PASS "[r2] backslash-quoted delimiter" 'cat <<\EOF > s.sh
for path in a; do :; done
EOF'
expect PASS "[r2] non-word delimiter"        "cat <<'END-OF-F' > s.sh
for path in a; do :; done
END-OF-F"
expect PASS "[r2] indented EOF inside plain heredoc body" 'cat <<EOF > s.sh
  EOF
for path in a; do :; done
EOF'
TABBED_CASE=$(printf 'cat <<-EOF > s.sh\n\tfor path in a; do :; done\n\tEOF')
expect PASS "[r2] <<- tab-indented body and terminator" "$TABBED_CASE"
expect PASS "[r2] \${path} expansion"        'echo ${path}'
expect PASS "[r2] comment line"              '# for path in a; do :; done'

echo "── labels: the reported shape must name the construct ──"
expect_label() {  # <want> <label> <command>
  local got; got=$(printf '%s' "$3" | python3 "$SCAN")
  if [ "$got" = "$1" ]; then
    printf '  \033[32m✓\033[0m %-28s %s\n' "\"$got\"" "$2"; pass=$((pass+1))
  else
    printf '  \033[31m✗\033[0m wanted \"%s\" got \"%s\"  %s\n' "$1" "$got" "$2"; fail=$((fail+1))
  fi
}
expect_label "path+=("                  "append form"          'path+=(/x /y)'
expect_label "local path="              "quoted value keeps declarer label" 'local path="$1"'
expect_label "select path in"           "select names itself"  'select path in a b; do break; done'
expect_label "path= as a command prefix" "prefix form"         'path=/tmp/nowhere env sh -c "echo hi"'
expect_label "local path (no value)"    "bare local"           'f(){ local path; }; f'

echo "── mutation: each component must be load-bearing ──"
MUT="$WORK/mut"; mkdir -p "$MUT"
mutate() {  # <label> <old-exact-string> <new-string> <command> <verdict-under-mutation>
  cp "$SCAN" "$MUT/scan.py"; cp "$RUNHOOK" "$MUT/hook.sh"
  python3 - "$MUT/scan.py" "$2" "$3" <<'PY'
import ast, sys
p, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
src = open(p).read()
if old not in src:
    sys.exit(3)
mutated = src.replace(old, new, 1)
try:
    ast.parse(mutated)
except SyntaxError:
    sys.exit(4)
open(p, "w").write(mutated)
PY
  local mrc=$?
  if [ "$mrc" -eq 3 ]; then
    printf '  \033[31m✗\033[0m MUTATION DID NOT APPLY (anchor missing, not dead code): %s\n' "$1"
    fail=$((fail+1)); return
  fi
  if [ "$mrc" -eq 4 ]; then
    # A mutation that breaks the parse would trip the hook's fail-open and read
    # as PASS for the wrong reason; refuse to count it either way.
    printf '  \033[31m✗\033[0m MUTATION BROKE THE PARSE (bad mutation, not dead code): %s\n' "$1"
    fail=$((fail+1)); return
  fi
  sed -i '' "s#$SCAN#$MUT/scan.py#" "$MUT/hook.sh"
  local got; got=$(verdict "$MUT/hook.sh" "$4")
  if [ "$got" = "$5" ]; then
    printf '  \033[32m✓\033[0m mutation changed behaviour: %s\n' "$1"; pass=$((pass+1))
  else
    printf '  \033[31m✗\033[0m mutation was a NO-OP (dead code): %s\n' "$1"; fail=$((fail+1))
  fi
}

mutate "double-quote tracking" \
'            if c == '"'"'"'"'"':
                in_quote = '"'"'"'"'"'' \
'            if c == chr(1):
                in_quote = '"'"'"'"'"'' \
'git commit -m "line one
path=nothing here"' WARN

mutate "single-quote tracking" \
'            if c == "'"'"'":
                in_quote = "'"'"'"' \
'            if c == chr(2):
                in_quote = "'"'"'"' \
"git commit -m 'line one
for path in x'" WARN

mutate "heredoc body blanking" \
'        if pending:' \
'        if False and pending:' \
'cat <<EOF > s.sh
for path in a; do echo; done
EOF' WARN

mutate "keyword peel reaches statement position" \
'        if head in KEYWORDS:' \
'        if False and head in KEYWORDS:' \
'if true; then path=/nope; fi' PASS

mutate "VAR= prefix peel catches IFS= read -r path" \
'        if ASSIGN_RE.match(head):' \
'        if False and ASSIGN_RE.match(head):' \
'printf "a/b\n" | while IFS= read -r path; do :; done' PASS

mutate "blank_arithmetic stops <<n being read as a heredoc" \
'    out, i = list(s), 0' \
'    return s
    out, i = list(s), 0' \
'echo $((1<<n))
for path in a; do :; done' PASS

mutate "declarer arm catches one-line fn local path=" \
'        if head in DECLARERS:' \
'        if False and head in DECLARERS:' \
'f(){ local path=/nope; }; f' PASS

mutate "bare local path arm" \
'any(t == "path" for t in rest)' \
'any(t == "__never__" for t in rest)' \
'f(){ local path; }; f' PASS

mutate "brace-group splitting in segments()" \
'r"(?:[;|&\n()]|(?<!\$)\{|\})+"' \
'r"(?:[;|&\n()])+"' \
'{ path=/nope; }' PASS

mutate "failed << match must advance past both brackets" \
'                    i = m.end()
                    continue
                i += 2
                continue' \
'                    i = m.end()
                    continue
                i += 1
                continue' \
'grep x <<<WORD
for path in a; do :; done' PASS

mutate "column-0 terminator rule for plain <<" \
'            term = line.lstrip("\t") if strip_tabs else line' \
'            term = line.strip()' \
'cat <<EOF > s.sh
  EOF
for path in a; do :; done
EOF' WARN

mutate "quoted heredoc delimiter recognition" \
"(?:'(?P<d1>[^']+)'" \
"(?:'(?P<d1>NEVER)'" \
"cat <<'SH'
body
SH
for path in a; do :; done" PASS

rm -rf "$WORK"
rm -f "$WARN_LOG_STORE"
printf '\n  %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
