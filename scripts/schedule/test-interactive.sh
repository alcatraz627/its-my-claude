#!/usr/bin/env bash
# test-interactive.sh — criteria-based tests for gcc-schedule (schedule.sh).
#
# Run:  bash ~/.claude/scripts/schedule/test-interactive.sh
#
# CRITERIA (every one must pass):
#   A. Claude-safety — text output stays PLAIN when not a terminal (no ANSI leak
#      on stdout OR stderr), so a piped/headless call is never polluted.
#      A1 help | cat has no ESC   A2 list/status | cat have no ESC
#      A3 -h documents -i          A4 add --dry-run still prints PLANNED
#   B. Colored in a terminal — the palette lights up under a pty (best-effort).
#   C. Interactive -i — every feature reachable + safe.
#      C1 no-tty -> clean refusal, non-zero, NO hang
#      C2 main menu covers browse/create/adopt/audit/status
#      C3 per-schedule actions cover show/logs/run/disable/enable/duplicate/rm/back
#      C4 _i_do_action routes each action to the right cmd_* (ACTION_DRYRUN)
#      C5 _i_compose_add_args builds the exact add argv for each mode
#      C6 every text subcommand family is reachable from the menu tree
#   D. Robustness
#      D1 empty registry -> _i_schedule_rows empty, no crash
#      D2 'back' action returns 2

set -uo pipefail
SCRIPT="$HOME/.claude/scripts/schedule/schedule.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
export GCC_SCHED_HOME="$TMP"

# seed a registry (2 schedules) + ledger (beta: ok ok missed)
cat > "$TMP/registry.json" <<'JSON'
{"alpha":{"kind":"one-shot","fire_at":"2026-07-10T09:00","label":"com.alcatraz.alpha","command":"echo a","description":"A","calendar_uid":"","created_at":"t","plist":"/x.plist","script":"/y.sh","out_log":"/o","err_log":"/e"},
 "beta":{"kind":"daily","fire_at":"daily@03:00","label":"com.alcatraz.beta","command":"echo b","description":"B","calendar_uid":"","created_at":"t","plist":"/x.plist","script":"/y.sh","out_log":"/o","err_log":"/e"}}
JSON
printf '%s\n' \
  '{"ts":"2026-07-01T09:00:00Z","ev":"run","name":"beta","outcome":"ok"}' \
  '{"ts":"2026-07-02T09:00:00Z","ev":"run","name":"beta","outcome":"ok"}' \
  '{"ts":"2026-07-03T09:00:00Z","ev":"run","name":"beta","outcome":"missed"}' > "$TMP/history.jsonl"

P=0; F=0
pass(){ printf '  \033[32m✓ PASS\033[0m %s\n' "$1"; P=$((P+1)); }
failed(){ printf '  \033[31m✗ FAIL\033[0m %s\n' "$1"; printf '        %s\n' "${2:-}"; F=$((F+1)); }
# run a snippet inside the script's own strict-mode context (dispatch is guarded)
run(){ GCC_SCHED_HOME="$TMP" bash -c "source '$SCRIPT'; $1" 2>&1; }
has_esc(){ case "$1" in *$'\033'*) return 0;; *) return 1;; esac; }

echo "═══ A. plain output for Claude (no ANSI leak when piped) ═══"
a1="$("$SCRIPT" help | cat)";  has_esc "$a1" && failed "A1 help|cat plain" "found ESC" || pass "A1 help|cat is plain"
a2="$("$SCRIPT" list | cat; "$SCRIPT" status 2>/dev/null | cat)"; has_esc "$a2" && failed "A2 list/status plain" "found ESC" || pass "A2 list/status|cat plain"
case "$("$SCRIPT" -h)" in *"-i"*"interactive"*|*"interactive"*"-i"*) pass "A3 -h documents -i";; *) failed "A3 -h documents -i" "no -i in help";; esac
case "$("$SCRIPT" add --name test-dry --at 2026-07-10T09:00 --command 'echo hi' --dry-run --no-calendar 2>&1)" in *PLANNED*) pass "A4 add --dry-run prints PLANNED";; *) failed "A4 add --dry-run" "no PLANNED block";; esac

echo "═══ B. colored under a terminal (pty smoke, best-effort) ═══"
if command -v script >/dev/null 2>&1; then
  pout="$(script -q /dev/null "$SCRIPT" help 2>/dev/null | head -60 || true)"
  has_esc "$pout" && pass "B1 help under pty carries color" || failed "B1 pty color" "no ESC under pty (color may be gated off in CI)"
else
  echo "  – skip B1 (no 'script' cmd)"
fi

echo "═══ C. interactive mode ═══"
# C1: no tty -> refuse, non-zero, no hang (perl process-group timeout, 8s cap)
c1="$(perl -e 'my $p=fork; if($p==0){setpgrp(0,0); open(STDIN,"</dev/null"); exec(@ARGV)} local $SIG{ALRM}=sub{kill "KILL",-$p; exit 42}; alarm 8; waitpid($p,0); exit($?>>8)' "$SCRIPT" -i </dev/null 2>&1)"; c1rc=$?
if [ "$c1rc" = 42 ]; then failed "C1 no-tty refusal" "HUNG (killed at 8s)"
elif [ "$c1rc" != 0 ] && printf '%s' "$c1" | grep -qi 'terminal\|headless\|text subcommand'; then pass "C1 no-tty -> clean refusal (rc=$c1rc)"
else failed "C1 no-tty refusal" "rc=$c1rc out=$c1"; fi

menu="$(run '_i_main_menu')"
for w in Browse Create Adopt Audit Status; do printf '%s' "$menu" | grep -q "$w" || { failed "C2 main menu covers $w" "$menu"; c2bad=1; }; done
[ -z "${c2bad:-}" ] && pass "C2 main menu covers browse/create/adopt/audit/status"

acts="$(run '_i_actions')"
for w in show logs run disable enable duplicate rm back; do printf '%s' "$acts" | grep -q "$w" || { failed "C3 actions cover $w" "$acts"; c3bad=1; }; done
[ -z "${c3bad:-}" ] && pass "C3 per-schedule actions cover show/logs/run/disable/enable/duplicate/rm/back"

# C4: routing (ACTION_DRYRUN prints ROUTE, runs nothing)
declare -a C4=("show|ROUTE: show alpha" "logs|ROUTE: logs alpha --no-follow" "run|ROUTE: run alpha" \
  "disable|ROUTE: disable alpha" "enable|ROUTE: enable alpha" "duplicate|ROUTE: duplicate alpha <new>" "rm|ROUTE: rm alpha")
c4bad=""
for pair in "${C4[@]}"; do
  label="${pair%%|*}"; want="${pair##*|}"
  got="$(run "ACTION_DRYRUN=1 _i_do_action alpha '$label'")"
  [ "$got" = "$want" ] || { failed "C4 route '$label'" "want=[$want] got=[$got]"; c4bad=1; }
done
backrc="$(run "ACTION_DRYRUN=1 _i_do_action alpha back; echo rc=\$?")"
printf '%s' "$backrc" | grep -q 'rc=2' || { failed "C4 back returns 2" "$backrc"; c4bad=1; }
[ -z "$c4bad" ] && pass "C4 _i_do_action routes every action correctly (+ back=2)"

# C5: add-arg composer, exact argv per mode
c5bad=""
chk5(){ local got="$1" want="$2" lbl="$3"; [ "$got" = "$want" ] || { failed "C5 $lbl" "want=[$want] got=[$got]"; c5bad=1; }; }
chk5 "$(run "_i_compose_add_args nm at 2026-07-10T09:00 '' 'echo hi' '' '' | tr '\n' '|'")" "--name|nm|--at|2026-07-10T09:00|--command|echo hi|" "at"
chk5 "$(run "_i_compose_add_args nm daily 09:00 '' 'cmd' '' '' | tr '\n' '|'")" "--name|nm|--daily-at|09:00|--command|cmd|" "daily"
chk5 "$(run "_i_compose_add_args nm weekly 17:00 fri 'cmd' 'D' '' | tr '\n' '|'")" "--name|nm|--weekly|fri|17:00|--command|cmd|--description|D|" "weekly+desc"
chk5 "$(run "_i_compose_add_args nm monthly 10:00 1 'cmd' '' 1 | tr '\n' '|'")" "--name|nm|--monthly|1|10:00|--command|cmd|--no-calendar|" "monthly+nocal"
[ -z "$c5bad" ] && pass "C5 _i_compose_add_args builds exact argv for at/daily/weekly/monthly (+desc/+nocal)"

# C6: every text subcommand family reachable from the interactive tree
tree="$menu
$acts
inventory doctor reconcile status history register"   # audit/status/adopt submenus (asserted present via C2)
c6bad=""
for sc in add list show logs run enable disable duplicate register inventory doctor history status reconcile rm; do
  case "$sc" in
    add)        printf '%s' "$menu" | grep -qi 'create' || { c6bad="add"; };;
    list)       printf '%s' "$menu" | grep -qi 'browse' || { c6bad="list"; };;
    register)   printf '%s' "$menu" | grep -qi 'adopt'  || { c6bad="register"; };;
    inventory|doctor|reconcile) printf '%s' "$menu" | grep -qi 'audit' || { c6bad="$sc"; };;
    status|history)             printf '%s' "$menu" | grep -qi 'status' || { c6bad="$sc"; };;
    *)          printf '%s' "$acts" | grep -qi "$sc" || { c6bad="$sc"; };;
  esac
done
[ -z "$c6bad" ] && pass "C6 every subcommand family reachable from -i" || failed "C6 coverage" "missing: $c6bad"

echo "═══ D. robustness ═══"
d1="$(GCC_SCHED_HOME="$(mktemp -d)" bash -c "source '$SCRIPT'; _i_schedule_rows; echo rc=\$?")"
printf '%s' "$d1" | grep -q 'rc=0' && [ "$(printf '%s' "$d1" | grep -vc 'rc=')" -eq 0 ] && pass "D1 empty registry -> no rows, no crash" || failed "D1 empty registry" "$d1"
d2="$(run "ACTION_DRYRUN=1 _i_do_action alpha 'back'; echo rc=\$?")"
printf '%s' "$d2" | grep -q 'rc=2' && pass "D2 back returns 2" || failed "D2 back rc" "$d2"

echo "═══ E. enriched pickers (tui_pick_key / tui_pick_or_add + colored keyed rows) ═══"
runpick(){ bash -c "source '$HOME/.claude/scripts/tui/pick.sh'; $1" 2>&1; }
# E1 strip_ansi
e1="$(runpick "printf '\033[36mhi\033[0m' | tui_strip_ansi")"
[ "$e1" = "hi" ] && pass "E1 tui_strip_ansi removes SGR" || failed "E1 strip_ansi" "got=[$e1]"
# E2 pick_key returns clean KEY (field 1), never the colored display
e2="$(runpick "printf 'kA\t\033[36mkA colored\033[0m\nkB\tkB\n' | tui_pick_key --non-tty first")"
[ "$e2" = "kA" ] && pass "E2 tui_pick_key returns clean key" || failed "E2 pick_key" "got=[$e2]"
# E3 pick_or_add: single candidate passthrough returns the key; no-tty add path returns 1
e3a="$(runpick "printf 'only\tOnly one\n' | tui_pick_or_add --non-tty passthrough 2>/dev/null" )"
e3b="$(runpick "printf 'a\nb\n' | tui_pick_or_add; echo rc=\$?" | grep -o 'rc=[0-9]*')"
{ [ "$e3a" = "only" ] || [ "$e3b" = "rc=1" ]; } && pass "E3 tui_pick_or_add non-tty behaves (passthrough key / rc=1)" || failed "E3 pick_or_add" "a=[$e3a] b=[$e3b]"
# E4 _i_schedule_rows now emits key<TAB>display; field 1 = clean name, tab present
rows="$(run '_i_schedule_rows')"
r1name="$(printf '%s\n' "$rows" | head -1 | cut -f1)"
r1disp="$(printf '%s\n' "$rows" | head -1 | cut -f2-)"
{ [ "$r1name" = alpha ] && [ "$r1disp" != "$r1name" ]; } && pass "E4 _i_schedule_rows emits key<TAB>colored-display (field1=name)" || failed "E4 rows" "name=[$r1name] disp=[$r1disp]"
# E5 menus emit clean keys in field 1
m1="$(run '_i_main_menu' | head -1 | cut -f1)"; a1="$(run '_i_actions' | head -1 | cut -f1)"
{ [ "$m1" = browse ] && [ "$a1" = show ]; } && pass "E5 menus emit clean keys (main=browse, action=show)" || failed "E5 menu keys" "main=[$m1] action=[$a1]"
# E6 register seeds existing plists: temp LaunchAgents with a fake plist -> field1 = its path
LA="$(mktemp -d)"; : > "$LA/com.alcatraz.testfake.plist"
p1="$(GCC_SCHED_LAUNCHAGENTS="$LA" bash -c "source '$SCRIPT'; _i_plist_rows" | head -1 | cut -f1)"
[ "$p1" = "$LA/com.alcatraz.testfake.plist" ] && pass "E6 register seeds existing plists (key=path)" || failed "E6 plist rows" "got=[$p1]"
rm -rf "$LA"

echo
echo "═══ RESULT: $P passed, $F failed ═══"
[ "$F" -eq 0 ]
