#!/usr/bin/env bash
# Stops a test file from keeping the whole environment where a failure prints it.
#
# A test that copies os.environ (or stores the **kw of a stubbed subprocess
# call, which carry env=) and later prints or asserts on that value writes
# every live API token into the transcript the first time the check fails.
# A command guard cannot see code, so this reads the file being written.
#
# PreToolUse on Write, Edit and MultiEdit. Only test, spec, fixture and probe
# files are examined, and only a change that introduces the pattern is refused.
# Passing a copied environment on (env=env) or reading single keys is fine.
# Mute: touch ~/.claude/.no-env-capture-gate

set -uo pipefail

[ -f "$HOME/.claude/.no-env-capture-gate" ] && exit 0
input=$(cat 2>/dev/null)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
case "$tool" in Write | Edit | MultiEdit) ;; *) exit 0 ;; esac

fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -n "$fp" ] || exit 0

# Code files that look like tests: by name, or under a test or fixture directory.
base=$(basename "$fp")
case "$base" in *.py | *.js | *.jsx | *.ts | *.tsx | *.mjs | *.cjs) ;; *) exit 0 ;; esac
case "$base" in
  test_* | *_test.* | *.test.* | *.spec.* | conftest.py) ;;
  *)
    case "/$fp" in
      */tests/* | */test/* | */__tests__/* | */fixtures/* | */probe/*) ;;
      *) exit 0 ;;
    esac
    ;;
esac

SCAN="$HOME/.claude/scripts/hooks/env-capture-scan.py"
[ -f "$SCAN" ] || exit 0
found=$(printf '%s' "$input" | python3 "$SCAN" 2>/dev/null)
[ -n "$found" ] || exit 0

reason="[env-capture] Refused: this test code ${found//$'\n'/; }. The environment of this shell holds live API tokens, and the first failing assertion or error message would print all of them into the transcript. Keep only what the test needs: record argv and the flags you assert on (for a stub, {\"shell\": kw.get(\"shell\")}), pass the copied environment on with env=env without printing or asserting on it, and read single keys by name. If the whole environment really must be compared, drop the secret-looking keys first. Mute: touch ~/.claude/.no-env-capture-gate"
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-env-capture-test --action block --heeded unknown >/dev/null 2>&1 || true
jq -nc --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
exit 0
