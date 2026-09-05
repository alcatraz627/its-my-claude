#!/usr/bin/env bash
# Checks which files in hinters/ the injector will run. It builds a throwaway
# HOME with three hinters and asserts that only a real, executable hinter is
# heard: a *.test.sh file is skipped even when it carries the execute bit, and a
# non-executable file is skipped as before.
#
# Why this exists: on 2026-08-20 four *.test.sh files landed in hinters/ with
# mode 755. The injector loads every executable *.sh, so every prompt in every
# session ran four test suites (one slept a second, one flipped machine-wide mute
# files, one wrote ~9,000 fake rows into the weekly-usage telemetry). Found by
# gcc-map v4, 2026-09-05.
#
# Run: bash ~/.claude/scripts/hint-injector.test.sh
set -uo pipefail

INJECTOR="$(cd "$(dirname "$0")" && pwd)/hint-injector.sh"
pass=0; fail=0
ok()   { echo "  ok    $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL  $1"; fail=$((fail+1)); }

TMP_HOME=$(mktemp -d /tmp/hint-injector-test.XXXXXX)
trap 'trash "$TMP_HOME" 2>/dev/null || true' EXIT
mkdir -p "$TMP_HOME/.claude/hinters"

printf '#!/usr/bin/env bash\necho REAL-MARK\n'   > "$TMP_HOME/.claude/hinters/10-real.sh"
printf '#!/usr/bin/env bash\necho TEST-MARK\n'   > "$TMP_HOME/.claude/hinters/10-real.test.sh"
printf '#!/usr/bin/env bash\necho NOEXEC-MARK\n' > "$TMP_HOME/.claude/hinters/20-noexec.sh"
chmod 755 "$TMP_HOME/.claude/hinters/10-real.sh" "$TMP_HOME/.claude/hinters/10-real.test.sh"
chmod 644 "$TMP_HOME/.claude/hinters/20-noexec.sh"

out=$(printf '{"prompt":"hello","session_id":"inj-test"}' | HOME="$TMP_HOME" bash "$INJECTOR" 2>&1 || true)

case "$out" in *REAL-MARK*)   ok  "a real executable hinter is heard" ;;
                *)            bad "a real executable hinter is heard (output: $out)" ;; esac
case "$out" in *TEST-MARK*)   bad "an executable *.test.sh is skipped (it ran)" ;;
                *)            ok  "an executable *.test.sh is skipped" ;; esac
case "$out" in *NOEXEC-MARK*) bad "a non-executable hinter is skipped (it ran)" ;;
                *)            ok  "a non-executable hinter is skipped" ;; esac

echo "---- pass=$pass fail=$fail ----"
[[ $fail -eq 0 ]]
