#!/usr/bin/env bash
# Tests for pol.sh: resolution, scopes, validation, snoozes, the owner-only
# write rule, corrupt and missing files, backups, and concurrent writers.
# Everything runs against a sandboxed store; the real ~/.claude/policy is never
# read or written.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
POL="$HERE/pol.sh"
REAL_REG="$HOME/.claude/policy/registry.json"
T=$(mktemp -d)
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
eq()  { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (want '$3', got '$2')"; fi; }

export POL_ROOT="$T/pol"
mkdir -p "$POL_ROOT"
cp -f "$REAL_REG" "$POL_ROOT/registry.json"
NOW=1800000000
export POL_NOW=$NOW
p() { bash "$POL" "$@" 2>/dev/null; }

git init -q -b main "$T/repo" && git -C "$T/repo" commit -q --allow-empty -m x
git -C "$T/repo" worktree add -q "$T/wt" -b feat 2>/dev/null
git init -q -b main "$T/other" && git -C "$T/other" commit -q --allow-empty -m x
mkdir -p "$T/plain"

echo "== defaults and global values =="
eq "default bool" "$(p get github.comment)" "allow"
eq "default enum" "$(p get git.push_main)" "ask"
eq "default number" "$(p get ops.usage_gate_pct)" "90"
p set github.comment block --global >/dev/null
eq "global set" "$(p get github.comment)" "block"
eq "global applies inside a repo" "$(p get github.comment --cwd "$T/repo")" "block"
p set ops.usage_gate_pct 75 >/dev/null
eq "number stored as a number" "$(jq -r '.global["ops.usage_gate_pct"].value | type' "$POL_ROOT/policy.json")" "number"

echo "== project overrides =="
p set github.comment allow --project "$T/repo" >/dev/null
eq "override wins in its repo" "$(p get github.comment --cwd "$T/repo")" "allow"
eq "worktree shares the main repo's override" "$(p get github.comment --cwd "$T/wt")" "allow"
eq "other repo keeps global" "$(p get github.comment --cwd "$T/other")" "block"
eq "non-repo dir keeps global" "$(p get github.comment --cwd "$T/plain")" "block"
eq "subdirectory resolves to repo root" "$(bash "$POL" root "$T/repo/.git/..")" "$(cd "$T/repo" && pwd -P)"
bash "$POL" set slack.post block --project "$T/repo" >/dev/null 2>&1; rc=$?
eq "global-only key refuses a project override" "$rc" "2"
p clear github.comment --project "$T/repo" >/dev/null
eq "clear falls back to global" "$(p get github.comment --cwd "$T/repo")" "block"
eq "empty project map is pruned" "$(jq -r '.projects | length' "$POL_ROOT/policy.json")" "0"

echo "== validation =="
before=$(cat "$POL_ROOT/policy.json")
for bad_case in "github.comment yes" "git.push_main maybe" "ops.usage_gate_pct 150" "ops.usage_gate_pct abc" "ops.usage_gate_pct 10"; do
  set -- $bad_case
  bash "$POL" set "$1" "$2" >/dev/null 2>&1; rc=$?
  eq "refuses $1=$2" "$rc" "2"
done
eq "refused values leave the store unchanged" "$(cat "$POL_ROOT/policy.json")" "$before"
bash "$POL" get no.such.key >/dev/null 2>&1; rc=$?
eq "unknown key exits 3" "$rc" "3"
bash "$POL" set no.such.key allow >/dev/null 2>&1; rc=$?
eq "set of unknown key exits 3" "$rc" "3"

echo "== snoozes =="
p set slack.post allow >/dev/null
p snooze slack.post --for 1h --then block >/dev/null
eq "value holds before the flip" "$(p get slack.post)" "allow"
eq "value flips after the time" "$(POL_NOW=$((NOW + 3601)) bash "$POL" get slack.post)" "block"
bash "$POL" snooze slack.post --for 1h --then allow >/dev/null 2>&1; rc=$?
eq "snooze to the current value is refused" "$rc" "2"
bash "$POL" snooze slack.post --for -5h --then block >/dev/null 2>&1; rc=$?
eq "snooze with a bad duration is refused" "$rc" "2"
POL_NOW=$((NOW + 7200)) bash "$POL" unsnooze slack.post >/dev/null 2>&1
eq "unsnooze after expiry keeps the flipped value" "$(p get slack.post)" "block"
eq "unsnooze drops the timer" "$(jq -r '.global["slack.post"].until // "none"' "$POL_ROOT/policy.json")" "none"
# A snooze on a project with no override of its own keeps what applies there now.
p set git.push allow --global >/dev/null
p snooze git.push --for 2h --then block --project "$T/other" >/dev/null
eq "project snooze starts from the resolved value" "$(p get git.push --cwd "$T/other")" "allow"
eq "project snooze flips only that project" "$(POL_NOW=$((NOW + 7201)) bash "$POL" get git.push --cwd "$T/other")/$(POL_NOW=$((NOW + 7201)) bash "$POL" get git.push --cwd "$T/repo")" "block/allow"
p snooze model.heavy_local --for 30m --then warn >/dev/null
eq "json reports the live snooze" "$(p json | jq -r '.policies[] | select(.key == "model.heavy_local") | "\(.snooze.scope):\(.snooze.then):\(.snooze.expired)"')" "global:warn:false"

echo "== json for the panel =="
j=$(p json --cwd "$T/repo")
eq "every registry entry is present" "$(jq '.policies | length' <<<"$j")" "$(jq length "$POL_ROOT/registry.json")"
eq "project scope reported" "$(jq -r .project <<<"$j")" "$(cd "$T/repo" && pwd -P)"
eq "source is global for a global value" "$(jq -r '.policies[] | select(.key == "github.comment") | .source' <<<"$j")" "global"
eq "source is default otherwise" "$(jq -r '.policies[] | select(.key == "linear.write") | .source' <<<"$j")" "default"
eq "projects list includes overridden repos" "$(p json | jq -r '.projects | length')" "1"

echo "== bad files never break a reader =="
cp -f "$POL_ROOT/policy.json" "$T/good.json"
printf '{' > "$POL_ROOT/policy.json"
eq "corrupt store resolves to defaults" "$(p get github.comment)" "allow"
bash "$POL" get github.comment >/dev/null 2>&1; rc=$?
eq "corrupt store get exits 0" "$rc" "0"
printf '{"global":{"github.comment":{"value":"yes"}},"projects":{}}' > "$POL_ROOT/policy.json"
eq "invalid stored value falls back to default" "$(p get github.comment)" "allow"
printf '{"global":{"github.comment":"block"},"projects":{}}' > "$POL_ROOT/policy.json"
eq "a bare non-object entry is ignored" "$(p get github.comment)" "allow"
mv -f "$POL_ROOT/registry.json" "$T/reg.json"
out=$(bash "$POL" get github.comment 2>/dev/null); rc=$?
eq "missing registry: get exits 3" "$rc" "3"
eq "missing registry: get prints nothing" "$out" ""
mv -f "$T/reg.json" "$POL_ROOT/registry.json"
cp -f "$T/good.json" "$POL_ROOT/policy.json"

echo "== backups rotate, nothing piles up =="
for v in 55 60 65 70 75 80 85; do p set ops.usage_gate_pct "$v" >/dev/null; done
eq "at most 5 backups" "$(ls "$POL_ROOT" | grep -c '^policy.json.bak')" "5"
eq "newest backup holds the previous value" "$(jq -r '.global["ops.usage_gate_pct"].value' "$POL_ROOT/policy.json.bak.1")" "80"
eq "no temp file left behind" "$(ls -a "$POL_ROOT" | grep -c 'tmp')" "0"

echo "== concurrent writers =="
keys="github.write linear.write deploy.vercel deploy.cloudflare git.commit files.env_read"
for k in $keys; do bash "$POL" set "$k" block >/dev/null 2>&1 & done
wait
n=0; for k in $keys; do [ "$(p get "$k")" = "block" ] && n=$((n+1)); done
eq "every parallel write landed" "$n" "6"
eq "no lock left behind" "$([ -d "$POL_ROOT/.lock" ] && echo held || echo free)" "free"

echo "== only the owner writes the real store =="
FH="$T/fakehome"; mkdir -p "$FH/.claude/policy"
cp -f "$REAL_REG" "$FH/.claude/policy/registry.json"
out=$(env -u POL_ROOT HOME="$FH" CLAUDECODE=1 bash "$POL" set slack.post block 2>&1); rc=$?
eq "agent shell refused on the real store" "$rc" "4"
eq "refusal names the panel" "$(grep -c 'policy panel' <<<"$out")" "1"
eq "refused write created nothing" "$([ -f "$FH/.claude/policy/policy.json" ] && echo written || echo none)" "none"
env -u POL_ROOT -u CLAUDECODE -u AI_AGENT -u CODEX_THREAD_ID -u CODEX_SANDBOX -u GCC_DISPATCH HOME="$FH" bash "$POL" set slack.post block >/dev/null 2>&1; rc=$?
eq "owner shell writes the real store" "$rc" "0"
eq "agent shell may still read" "$(env -u POL_ROOT HOME="$FH" CLAUDECODE=1 bash "$POL" get slack.post)" "block"

echo "== session-start line =="
inj=$(printf '{"cwd":"%s"}' "$T/repo" | bash "$POL" inject)
eq "inject emits additionalContext" "$(jq -r 'has("additionalContext")' <<<"$inj")" "true"
eq "inject names a changed value" "$(jq -r '.additionalContext | contains("github.comment=block")' <<<"$inj")" "true"
eq "inject says allowed needs no approval" "$(jq -r '.additionalContext | contains("needs no approval request")' <<<"$inj")" "true"
p set model.codex encourage >/dev/null
eq "inject carries the codex nudge" "$(printf '{}' | bash "$POL" inject | jq -r '.additionalContext | contains("Codex is encouraged")')" "true"

git -C "$T/repo" worktree remove --force "$T/wt" 2>/dev/null
echo
echo "pol.sh: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
