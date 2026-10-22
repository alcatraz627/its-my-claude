#!/usr/bin/env bash
# Tests for guard-extension-root.sh: each case feeds a tool call and checks
# whether the hook blocks it (exit 2) or lets it through (exit 0).

set -uo pipefail
HOOK="$HOME/.claude/scripts/hooks/guard-extension-root.sh"
ext=$(mktemp -d)
plain=$(mktemp -d)
printf '{ "manifest_version": 3, "name": "x" }\n' > "$ext/manifest.json"
printf '{ "name": "not an extension" }\n' > "$plain/manifest.json"
pass=0; fail=0

run() {  # name, expected exit, json
  local got
  printf '%s' "$3" | bash "$HOOK" 2>/dev/null; got=$?
  if [ "$got" = "$2" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $1: expected $2, got $got"; fi
}

run "write _ file in extension root" 2 "{\"tool_input\":{\"file_path\":\"$ext/_20261020-x.claude.md\"},\"cwd\":\"$ext\"}"
run "write _ file under .claude" 0 "{\"tool_input\":{\"file_path\":\"$ext/.claude/_20261020-x.claude.md\"},\"cwd\":\"$ext\"}"
run "write normal file in root" 0 "{\"tool_input\":{\"file_path\":\"$ext/notes.md\"},\"cwd\":\"$ext\"}"
run "write _locales" 0 "{\"tool_input\":{\"file_path\":\"$ext/_locales\"},\"cwd\":\"$ext\"}"
run "write _ file next to non-extension manifest" 0 "{\"tool_input\":{\"file_path\":\"$plain/_x.md\"},\"cwd\":\"$plain\"}"
run "relative write target" 2 "{\"tool_input\":{\"file_path\":\"_x.md\"},\"cwd\":\"$ext\"}"
run "bash symlink into root" 2 "{\"tool_input\":{\"command\":\"ln -sf _a.md $ext/_checkpoint.claude.md\"},\"cwd\":\"/\"}"
run "bash relative redirect" 2 "{\"tool_input\":{\"command\":\"echo hi > _x.md\"},\"cwd\":\"$ext\"}"
run "bash read only" 0 "{\"tool_input\":{\"command\":\"ls $ext/_x.md\"},\"cwd\":\"$ext\"}"
run "bash move _ file out of root" 0 "{\"tool_input\":{\"command\":\"mv $ext/_x.md $ext/.claude/_x.md\"},\"cwd\":\"$ext\"}"
run "bash copy into root" 2 "{\"tool_input\":{\"command\":\"cp /tmp/a.md $ext/_x.md\"},\"cwd\":\"$ext\"}"
run "bash move normal file under .claude" 0 "{\"tool_input\":{\"command\":\"mv $ext/notes.md $ext/.claude/_x.md\"},\"cwd\":\"$ext\"}"

trash "$ext" "$plain" 2>/dev/null
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
