#!/usr/bin/env bash
# Tests for guard-zsh-path-var.sh.
#
# Two halves. The first asserts the guard fires on real footguns and stays quiet
# on lookalikes. The second MUTATES the guard and asserts the tests go red — a
# guard whose suite passes with its logic removed is testing nothing
# (rules/testing.md § [mutation-test-the-guard]). Mutation is copy-based, so
# nothing uncommitted is ever at risk.

HOOK="$HOME/.claude/scripts/hooks/guard-zsh-path-var.sh"
pass=0; fail=0

# Feed a command to a hook script; echo BLOCK or PASS.
verdict() {  # <hook-script> <command>
  local out
  out=$(jq -cn --arg c "$2" '{tool_name:"Bash", tool_input:{command:$c}}' | bash "$1" 2>/dev/null)
  case "$out" in *'"decision":"block"'*) echo BLOCK ;; *) echo PASS ;; esac
}

expect() {  # <want> <label> <command>
  local got; got=$(verdict "$HOOK" "$3")
  if [ "$got" = "$1" ]; then
    printf '  \033[32m✓\033[0m %-9s %s\n' "$got" "$2"; pass=$((pass+1))
  else
    printf '  \033[31m✗\033[0m wanted %-5s got %-5s  %s\n' "$1" "$got" "$2"; fail=$((fail+1))
  fi
}

echo "── must FIRE: real zsh footguns ──"
expect BLOCK "while read path"          'printf "x\n" | while read path; do echo hi; done'
expect BLOCK "while read ts path"       'ls | while read ts path; do echo "$ts"; done'
expect BLOCK "while read -r path"       'ls | while read -r path; do echo hi; done'
expect BLOCK "for path in"              'for path in /a /b; do echo hi; done'
expect BLOCK "bare assignment"          'path=/tmp/x'
expect BLOCK "export assignment"        'export path=/tmp/x'
expect BLOCK "second in a chain"        'cd /tmp && for path in *; do echo hi; done'

echo "── must STAY SILENT: lookalikes and safe code ──"
expect PASS  "python for-in (quoted)"   'python3 -c "for path in [1,2]: print(path)"'
expect PASS  "awk for-in (quoted)"      'awk "{for (path in a) print}" f.txt'
expect PASS  "rg pattern containing =" "rg 'path=[^&]*' file.txt"
expect PASS  "jq .path selector"        "jq -r '.path' f.json"
expect PASS  "safe loop var p"          'for p in /a /b; do echo hi; done'
expect PASS  "safe loop var line"       'while read line; do echo hi; done < f'
expect PASS  "safe loop var sha"        'git log --format=%H | while read sha; do echo hi; done'
expect PASS  "echo of a literal"        'echo "path=1"'
# The case quote-blanking exists for: a `;` INSIDE a quoted string splits the
# command into segments, stranding quoted prose in statement position.
expect PASS  "quoted text holding ; path=" 'git commit -m "fix; path=1 handling"'
expect PASS  "quoted text holding ; for"   'echo "note; for path in x"'
expect PASS  "find -name path"          'find . -name path'
expect PASS  "uppercase PATH prefix"    'PATH=/x:$PATH ls'
expect PASS  "heredoc authoring bash"   'cat <<EOF > s.sh
for path in a; do echo; done
EOF'
expect PASS  "no path at all"           'ls -la /tmp'

echo "── mutation: each guard component must be load-bearing ──"
MUT=$(mktemp -d)
mutate() {  # <label> <sed-expr> <command> <verdict-that-proves-it-mattered>
  local m="$MUT/h.sh"
  sed "$2" "$HOOK" > "$m"
  local got; got=$(verdict "$m" "$3")
  if [ "$got" = "$4" ]; then
    printf '  \033[32m✓\033[0m mutation changed behaviour: %s\n' "$1"; pass=$((pass+1))
  else
    printf '  \033[31m✗\033[0m mutation was a NO-OP (component is dead code): %s\n' "$1"; fail=$((fail+1))
  fi
}
# Remove quote-blanking → quoted prose containing `;` gets stranded in statement
# position and false-fires. (The python case does NOT prove this: the `^for`
# anchor already protects it, so mutating here left it green and the mutation
# test correctly reported a no-op.)
mutate "quote-blanking protects quoted prose holding a ;" \
       's|^scan=$(blank_quotes "$command")|scan="$command"|' \
       'git commit -m "fix; path=1 handling"' BLOCK
# Remove the heredoc skip → the heredoc case must start false-firing.
mutate "heredoc skip is what protects script authoring" \
       '/case "\$command" in \*.<<.\*) exit 0 ;; esac/d' \
       'cat <<EOF > s.sh
for path in a; do echo; done
EOF' BLOCK
# Remove the for-loop matcher → the real footgun must stop being caught.
mutate "for-loop matcher actually catches for path in" \
       's|\^for\[\[:space:\]\]+path|^forXX[[:space:]]+path|' \
       'for path in /a /b; do echo hi; done' PASS
rm -rf "$MUT"

printf '\n  %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
