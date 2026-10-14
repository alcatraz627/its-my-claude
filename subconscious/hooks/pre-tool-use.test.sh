#!/usr/bin/env bash
# pre-tool-use.test.sh: the i-dream tool-time nudge speaks once per file per
# session, still ledgers every match, and honours the narrowed triggers.
# HOOK=<path> points the suite at a mutated copy.
set -uo pipefail
REAL="$HOME"
HOOK="${HOOK:-$REAL/.claude/subconscious/hooks/pre-tool-use.sh}"
INTERV="${INTERV:-$REAL/.claude/i-dream/interventions.json}"
pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }

T=$(mktemp -d); export HOME="$T"; mkdir -p "$T/.claude/i-dream"
cat > "$T/.claude/i-dream/interventions.json" <<'JSON'
[
 {"id":"aaaaaaaa11111111","form":"nudge","state":"live","trigger":{"tool":"Edit","input_pattern":"\\.py$"},"body":"A-body"},
 {"id":"bbbbbbbb22222222","form":"nudge","state":"live","trigger":{"tool":"Write","input_pattern":"/docs/","content_pattern":"(there is no |does not exist)"},"body":"B-body"},
 {"id":"cccccccc33333333","form":"nudge","state":"shadow","trigger":{"tool":"Edit","input_pattern":"\\.py$"},"body":"C-body"},
 {"id":"dddddddd44444444","form":"nudge","state":"live","trigger":{"tool":"Bash","project":"gcp","input_pattern":"gcloud"},"body":"D-body"}
]
JSON
LEDGER="$T/.claude/i-dream/would-fire.jsonl"

fire(){ # tool sid cwd file-or-command [content]
  local tool="$1" sid="$2" cwd="$3" arg="$4" content="${5:-}"
  case "$tool" in
    Bash) jq -nc --arg t "$tool" --arg s "$sid" --arg c "$cwd" --arg a "$arg" '{tool_name:$t,session_id:$s,cwd:$c,tool_input:{command:$a}}' ;;
    *)    jq -nc --arg t "$tool" --arg s "$sid" --arg c "$cwd" --arg a "$arg" --arg x "$content" '{tool_name:$t,session_id:$s,cwd:$c,tool_input:{file_path:$a,content:$x,new_string:$x}}' ;;
  esac | bash "$HOOK"
}
has(){ printf '%s' "$1" | rg -q "$2"; }

o=$(fire Edit s1aaaaaa /x/proj /x/proj/a.py)
has "$o" "A-body" && ok "first edit of a file fires" || ko "first edit silent"
has "$o" "C-body" && ko "shadow nudge leaked into context" || ok "shadow nudge never injected"
o=$(fire Edit s1aaaaaa /x/proj /x/proj/a.py)
[ -z "$o" ] && ok "second edit of the same file is silent" || ko "repeat fired: $o"
o=$(fire Edit s1aaaaaa /x/proj /x/proj/b.py)
has "$o" "A-body" && ok "a different file fires again" || ko "different file silent"
o=$(fire Edit s2bbbbbb /x/proj /x/proj/a.py)
has "$o" "A-body" && ok "a new session fires again (reset condition)" || ko "new session silent"

n=$(wc -l < "$LEDGER" | tr -d ' ')
# 4 edits x (live A + shadow C) = 8 ledger rows, repeats included
[ "$n" = "8" ] && ok "every match is still ledgered, repeats included ($n rows)" || ko "ledger rows=$n want 8"

o=$(fire Write s3cccccc /x/proj /x/proj/docs/n.md "We did the work today.")
[ -z "$o" ] && ok "doc write with no absence claim is silent" || ko "doc write fired: $o"
o=$(fire Write s3cccccc /x/proj /x/proj/docs/n.md "There is no existing helper for this.")
has "$o" "B-body" && ok "doc write asserting absence fires" || ko "absence claim silent"

o=$(fire Bash s4dddddd /x/gcp "gcloud run deploy")
has "$o" "D-body" && ok "brains-seat project (gcp) fires" || ko "gcp silent"
o=$(fire Bash s4dddddd /x/other "gcloud run deploy")
[ -z "$o" ] && ok "other project is silent" || ko "other project fired"

# The shipped intervention file keeps the cuts.
q(){ jq -r "$1" "$INTERV"; }
[ "$(q '.[]|select(.id|startswith("fbbe2e1a"))|.state')" = "shadow" ] && ok "fbbe2e1a (comment length) is shadowed" || ko "fbbe2e1a is live"
[ "$(q '.[]|select(.id|startswith("3c40a861"))|.state')" = "shadow" ] && ok "3c40a861 (absolute paths) is shadowed" || ko "3c40a861 is live"
[ -n "$(q '.[]|select(.id|startswith("91c2e2e7"))|.trigger.content_pattern // empty')" ] && ok "91c2e2e7 is narrowed by content" || ko "91c2e2e7 not narrowed"
[ "$(q '.[]|select(.id|startswith("2026cc3b"))|.trigger.project // empty')" = "gcp" ] && ok "2026cc3b is scoped to the brains seat (gcp)" || ko "2026cc3b unscoped"

export HOME="$REAL"; trash "$T" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
