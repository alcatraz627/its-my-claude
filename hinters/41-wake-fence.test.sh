#!/usr/bin/env bash
# 41-wake-fence.test.sh — a wake prompt while the owner typed inside the window
# gets the fence; a quiet session, a non-wake prompt, a cron-only transcript and
# the mute stay silent. One mutation: the fence text removed reads as silent.
set -uo pipefail
H=/Users/alcatraz627/.claude/hinters/41-wake-fence.sh
Q=/Users/alcatraz627/.claude/scripts/session-mgmt/owner-quiet.py
pass=0; fail=0; ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }
T=$(mktemp -d); REAL="$HOME"; export HOME="$T"
mkdir -p "$HOME/.claude/hinters" "$HOME/.claude/scripts/session-mgmt" "$HOME/.claude/projects/-Users-x-proj"
cp "$H" "$HOME/.claude/hinters/"; cp "$Q" "$HOME/.claude/scripts/session-mgmt/"
H="$HOME/.claude/hinters/41-wake-fence.sh"
SID=wwwwwwww-0000-4000-8000-000000000000; export CLAUDE_HINT_SID=$SID
TP="$HOME/.claude/projects/-Users-x-proj/$SID.jsonl"
iso(){ python3 -c 'import datetime,sys; print((datetime.datetime.now(datetime.timezone.utc)-datetime.timedelta(seconds=int(sys.argv[1]))).strftime("%Y-%m-%dT%H:%M:%S.000Z"))' "$1"; }
tx(){ # tx <owner-seconds-ago|none> [cron-seconds-ago]
  : > "$TP"
  [ "$1" != none ] && jq -cn --arg ts "$(iso "$1")" '{type:"user", timestamp:$ts, message:{role:"user", content:"what are you doing?"}}' >> "$TP"
  [ -n "${2:-}" ] && jq -cn --arg ts "$(iso "$2")" '{type:"user", timestamp:$ts, message:{role:"user", content:"Wake check. Two steps, in this order."}}' >> "$TP"
  jq -cn '{type:"assistant", message:{role:"assistant", content:[{type:"text", text:"ok"}]}}' >> "$TP"
}
WAKE="Wake check. Two steps, in this order. Do not skip step 1."
run(){ printf '%s' "$1" | bash "$H"; }

tx 120
out=$(run "$WAKE"); printf '%s' "$out" | rg -q '^\[wake-fence\] The owner typed in this session 2 min ago. This wake picks NOTHING' && ok "owner typed 2 min ago: the wake gets the fence" || ko "no fence: $out"
tx 7200
[ -z "$(run "$WAKE")" ] && ok "owner quiet 2h: silent" || ko "fired when quiet"
tx 120
[ -z "$(run "go on")" ] && ok "a non-wake prompt: silent" || ko "fired on a normal prompt"
tx 7200 30
[ -z "$(run "$WAKE")" ] && ok "a cron wake 30s ago is not the owner: silent" || ko "cron read as owner"
tx none
[ -z "$(run "$WAKE")" ] && ok "no owner prompt at all: silent" || ko "fired with no owner"
tx 120
out=$(WAKE_FENCE_IDLE_S=60 run "$WAKE"); [ -z "$out" ] && ok "the window is a knob (60s makes 120s-ago quiet)" || ko "knob ignored"
out=$(printf '%s' "Heartbeat: take the next row" | bash "$H"); printf '%s' "$out" | rg -q 'wake-fence' && ok "a heartbeat prompt is fenced too" || ko "heartbeat not fenced"
touch "$HOME/.claude/.no-wake-fence"; [ -z "$(run "$WAKE")" ] && ok "mute honoured" || ko "mute"; rm -f "$HOME/.claude/.no-wake-fence"
tx 120; M="$HOME/.claude/hinters/mut.sh"; sed 's/^printf .*wake-fence.*$/exit 0/' "$H" > "$M"
[ -z "$(printf '%s' "$WAKE" | bash "$M")" ] && ok "MUTATION: without the fence line the hinter is silent (the assertion above is load-bearing)" || ko "mutant still fired"
export HOME="$REAL"; trash "$T" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
