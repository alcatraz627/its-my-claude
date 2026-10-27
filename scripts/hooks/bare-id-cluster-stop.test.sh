#!/usr/bin/env bash
# Tests for bare-id-cluster-stop.sh. BAREID_HOOK points the run at another copy
# of the hook, to watch the new rows fail against an older one.
#
# The two rows that matter most are the NEGATIVES. A gate on a text shape earns
# its place by staying quiet, and this account writes about ids constantly while
# building id-rendering tools. A false fire on a rendered table would be a fire
# on every /tasks run, which is how a gate gets muted in a day.
set -uo pipefail
H="${BAREID_HOOK:-$HOME/.claude/scripts/hooks/bare-id-cluster-stop.sh}"
pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }
ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }

T=$(mktemp -d)
# The hook's loop guard writes /tmp/claude-bareid-<sid8> and that file OUTLIVES the
# test run, so a second invocation starts already "seen" and the fire rows go
# quiet for the wrong reason. This bit me during a mutation test: the restored
# file failed the same row the mutation did, which reads exactly like a real
# regression. Clear the marks for the sids this file uses, before and after.
for _s in aaaaaaaa bbbbbbbb cccccccc; do rm -f "/tmp/claude-bareid-$_s"; done
_n=0
run() {  # run <assistant-text> [sid] -> "<decision>: <reason>", or empty
  # Every call gets its OWN session id unless one is named. Sharing one made every
  # row after the first fire pass because the LOOP GUARD silenced it, not because
  # the hook judged it quiet: the negatives were vacuous and two mutations sailed
  # through green. Only the loop-safety rows below deliberately reuse a sid.
  _n=$((_n+1))
  local txt="$1" sid="${2:-$(printf 'f%07d-1111-2222-3333-444444444444' "$_n")}"
  local tr="$T/$RANDOM.jsonl"
  python3 - "$tr" "$txt" <<'PY'
import json, sys
open(sys.argv[1], "w").write(json.dumps({
    "type": "assistant",
    "message": {"role": "assistant", "content": [{"type": "text", "text": sys.argv[2]}]},
}) + "\n")
PY
  printf '{"session_id":"%s","transcript_path":"%s"}' "$sid" "$tr" \
    | bash "$H" 2>/dev/null | jq -r 'if (.decision // .systemMessage) then (.decision // "warn") + ": " + (.reason // .systemMessage) else empty end' 2>/dev/null
}

echo "== it fires on the shape that caused two S3s in one day =="
out=$(run "Still pending on you: #59 #91 #39 #153 #130 #89. I will keep going.")
[ -n "$out" ] && ok "a run of six bare ids fires" || ko "the real failing shape did not fire"
case "$out" in block:*) ok "it blocks, not just warns" ;; *) ko "did not block: ${out:0:40}" ;; esac
case "$out" in *"chat prose obeys it too"*) ok "it cites the owner's actual rule" ;;
                                            *) ko "message does not cite the rule" ;; esac

echo "== and on the D-code shape I shipped myself =="
out=$(run "Your only open gate is #105, the deck D1 D2 D3 D4 D5, waiting on you.")
[ -n "$out" ] && ok "a run of D-codes fires" || ko "D-code cluster missed"

echo "== NEGATIVES: it stays quiet where ids are legitimate =="
out=$(run "I closed #98, which made core-dump emit the glanced field, and #99, which added the tasks render to catchup.")
[ -z "$out" ] && ok "ids each carrying a subject stay quiet" || ko "false fire on glossed ids: $out"

# A BARE pair, no connecting word: "and" is not in the separator class, so a
# fixture written as "#114 and #115" could not fail however low the bar went.
out=$(run "Two rows failed: #114 #115.")
[ -z "$out" ] && ok "a bare pair is not a cluster (the bar is three)" || ko "false fire on a bare pair"

TABLE='Here is the table:

```
GATES (you)   (3)
  #32  Draft the run-mode proposal
done (98): #1 #2 #3 #4 #5 #6 #7 #8 #9 #10 #11 #12 #13
```

Nothing else is pending.'
out=$(run "$TABLE")
[ -z "$out" ] && ok "a rendered table in a fence never fires (its collapse is ruled)" \
              || ko "FALSE FIRE ON A RENDERED TABLE, this would fire on every /tasks run: $out"

out=$(run 'Colours used: #fff #000 #333 and #ccc, plus the dates 2026-10-23 and 20261023.')
[ -z "$out" ] && ok "hex colours, dates and plain numbers are not ids" || ko "false fire on colours/dates: $out"

out=$(run 'Encodings tried: UTF-8, SHA-256 and MD-5, none of them helped.')
[ -z "$out" ] && ok "UTF-8 / SHA-256 style names are not ticket keys" || ko "false fire on encoding names"

out=$(run 'Fixed in `35fca8e` (the Linear query now asks for fewer fields) and in `4501b77` (trash removes only the thinking block).')
[ -z "$out" ] && ok "backticked hashes that each carry their subject stay quiet" || ko "false fire on glossed hashes: $out"

echo "== wider shapes: commit hashes, ticket keys, 'and' / 'or', in or out of backticks =="
# Recovered from the 2026-10-23 slack-automation session 87a62e3c: the last line
# of the reply that closed out the pass, word for word.
REAL='#487 is pushed and now deploying. The test suites pass on main.

Still open:
- **Linear facts list:** I have not seen a successful refresh yet.
- **#487, #488, #489:** say the word and I will close them.'
out=$(run "$REAL")
[ -n "$out" ] && ok "recovered 23 Oct closing line (#487, #488, #489) blocks" || ko "recovered 23 Oct line slipped through"

# Reconstructed from the atone row: the decision line asked 'Close #487, #488 and
# #489?' and cited commit shas, written in backticks, with no description.
RECON='Fixed and deployed in `35fca8e`, `4501b77` and `44fc049`.

Close #487, #488 and #489?'
out=$(run "$RECON")
[ -n "$out" ] && ok "reconstructed 23 Oct reply (hashes in backticks + 'and') blocks" || ko "reconstructed 23 Oct reply slipped through"

out=$(run 'Shipped in 35fca8e, 4501b77 or 44fc049, depending on the branch.')
[ -n "$out" ] && ok "bare hashes joined by commas and 'or' block" || ko "bare hashes missed"

out=$(run 'Open tickets: VER-101 / VER-102 / VER-103.')
[ -n "$out" ] && ok "VER-123 style keys joined by slashes block" || ko "ticket keys missed"

out=$(run 'Mixed: #12, `a1b2c3d` and VER-77 are all done.')
[ -n "$out" ] && ok "mixed id kinds count together" || ko "mixed kinds missed"

echo "== the legitimate counterparts pass =="
GLOSSED='Three issues are fixed and deployed:
- Issue 487 (the share address, stale status after a regenerate): fixed in 44fc049, which points the reply at the existing drive_account helper.
- Issue 488 (extract cannot read a gdoc attached in Slack): fixed in 35fca8e.
- Issue 489 (trashing the thinking block deleted the whole answer): fixed in 4501b77.
I closed all three myself, with a comment on each.'
out=$(run "$GLOSSED")
[ -z "$out" ] && ok "each id named with its subject passes" || ko "false block on a glossed reply: $out"

FENCED='Closing summary:

```
#487  share address and regenerate status      44fc049
#488  extract cannot read a gdoc in Slack       35fca8e
#489  trash removed the whole answer            4501b77
done: #1 #2 #3 #4 #5 #6
```

All three are deployed.'
out=$(run "$FENCED")
[ -z "$out" ] && ok "a fenced table of ids passes" || ko "false block on a fenced table: $out"

echo "== loop safety: it does not re-fire on an unchanged message =="
S2=bbbbbbbb-1111-2222-3333-444444444444
one=$(run "pending: #59 #91 #39" "$S2")
two=$(run "pending: #59 #91 #39" "$S2")
[ -n "$one" ] && [ -z "$two" ] && ok "fires once, then steps aside" \
  || ko "re-fired on an identical message (one='${one:0:20}' two='${two:0:20}')"

echo "== the mute is honoured =="
touch "$HOME/.claude/.no-bare-id-gate"
out=$(run "pending: #59 #91 #39 #153" cccccccc-1111-2222-3333-444444444444)
[ -z "$out" ] && ok "mute file silences it" || ko "mute ignored"
rm -f "$HOME/.claude/.no-bare-id-gate"

rm -f /tmp/claude-bareid-f000* /tmp/claude-bareid-bbbbbbbb /tmp/claude-bareid-cccccccc
rm -rf "$T"
echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
