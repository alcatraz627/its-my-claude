#!/usr/bin/env bash
# Checks the muted-gates SessionStart injector against a throwaway config root:
# silent with no sentinels, one line naming each present .no-* / *-off file with
# the script that honours it, and the lane's own mute skipped.
# Run: bash ~/.claude/scripts/session-mgmt/muted-gates.test.sh
set -uo pipefail

INJ="$(cd "$(dirname "$0")" && pwd)/muted-gates.sh"
pass=0; fail=0
ok()  { echo "  ok    $1"; pass=$((pass+1)); }
bad() { echo "  FAIL  $1"; fail=$((fail+1)); }

T=$(mktemp -d /tmp/muted-gates-test.XXXXXX)
trap 'trash "$T" 2>/dev/null || true' EXIT
mkdir -p "$T/scripts/hooks" "$T/hinters"
printf '#!/usr/bin/env bash\n# Mute: touch ~/.claude/.no-foo-gate\n' > "$T/scripts/hooks/foo-gate.sh"
printf '#!/usr/bin/env bash\n[ -f "$HOME/.claude/.bar-off" ] && exit 0\n' > "$T/hinters/10-bar.sh"

run() { printf '{}' | INJECT_ONCE_DIR="$T/.once" MUTED_GATES_ROOT="$T" bash "$INJ" 2>/dev/null; }

out=$(run)
[ -z "$out" ] && ok "no sentinels: silent" || bad "no sentinels: emitted '$out'"

touch "$T/.no-foo-gate" "$T/.bar-off" "$T/.no-sessionstart-inject" "$T/.allow-something"
out=$(run)
ctx=$(printf '%s' "$out" | jq -r '.additionalContext // empty' 2>/dev/null)
[ -n "$ctx" ] && ok "sentinels present: emits additionalContext" || bad "sentinels present: no additionalContext in '$out'"
case "$ctx" in *".no-foo-gate (today, mutes foo-gate.sh)"*) ok "names the .no-* sentinel with its owning script" ;; *) bad "foo row wrong: $ctx" ;; esac
case "$ctx" in *".bar-off (today, mutes 10-bar.sh)"*)       ok "names the *-off sentinel with its owning hinter" ;; *) bad "bar row wrong: $ctx" ;; esac
case "$ctx" in *".no-sessionstart-inject"*) bad "lists the lane's own mute" ;; *) ok "skips the lane's own mute" ;; esac
case "$ctx" in *".allow-something"*)        bad "lists an enabler sentinel" ;;   *) ok "skips enabler sentinels" ;; esac

touch "$T/.no-orphan"
ctx=$(run | jq -r '.additionalContext // empty' 2>/dev/null)
case "$ctx" in *".no-orphan (today, mutes ?)"*) ok "a sentinel no script names shows ? as owner" ;; *) bad "orphan row wrong: $ctx" ;; esac

# Mutes kept in a feature's own folder, and the bare name.off shape.
mkdir -p "$T/atone" "$T/personas/usage" "$T/projects/x"
printf '#!/usr/bin/env bash\n[ -f "$HOME/.claude/cli-gating.off" ] && exit 0\n' > "$T/scripts/hooks/gate-cli.sh"
touch "$T/atone/.nudge-off" "$T/personas/usage/.suggest-off" "$T/cli-gating.off" "$T/projects/x/.no-transcript-noise"
ctx=$(run | jq -r '.additionalContext // empty' 2>/dev/null)
case "$ctx" in *"atone/.nudge-off ("*) ok "finds a mute one folder down" ;; *) bad "atone/.nudge-off missing: $ctx" ;; esac
case "$ctx" in *"personas/usage/.suggest-off ("*) ok "finds a mute two folders down" ;; *) bad "suggest-off missing: $ctx" ;; esac
case "$ctx" in *"cli-gating.off (today, mutes gate-cli.sh)"*) ok "finds a bare name.off mute with its owner" ;; *) bad "cli-gating.off row wrong: $ctx" ;; esac
case "$ctx" in *"no-transcript-noise"*) bad "looked inside a pruned data folder" ;; *) ok "skips the data folders" ;; esac

echo "---- pass=$pass fail=$fail ----"
[ $fail -eq 0 ]
