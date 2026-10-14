#!/usr/bin/env bash
# once-injectors.test.sh: the kanban line stays silent while the board is
# mothballed, the HEALTH stale-worktree line reaches the model once a day, and
# the muted-gates line is repeated only when the set of mutes changes.
# KL / HC / MG point the suite at mutated copies of the three scripts.
set -uo pipefail
REAL="$HOME"
KL="${KL:-$REAL/.claude/scripts/kanban/session-start-line.sh}"
HC="${HC:-$REAL/.claude/scripts/health-check.sh}"
MG="${MG:-$REAL/.claude/scripts/session-mgmt/muted-gates.sh}"
pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }
ctx(){ jq -r '(.additionalContext // .hookSpecificOutput.additionalContext // empty)' 2>/dev/null; }

# ---- kanban line
K=$(mktemp -d); mkdir -p "$K/boards/b1"
printf '{"boards":{"b1":{"root":"/x/proj","name":"B One"}}}' > "$K/registry.json"
printf '{"n1":{"note":"look at this","updatedAt":"2026-10-14T10:00:00.000Z"}}' > "$K/boards/b1/notes.json"
printf '{"lastAckTs":0}' > "$K/boards/b1/ack.json"
kl(){ printf '{"cwd":"/x/proj"}' | env KANBAN_ROOT="$K" bash "$KL" | ctx; }
[ -n "$(kl)" ] && ok "kanban: an active board with unread notes still speaks" || ko "kanban: active board silent"
: > "$K/.mothballed"
[ -z "$(kl)" ] && ok "kanban: silent once the board is mothballed" || ko "kanban: spoke while mothballed"
trash "$K/.mothballed"
[ -n "$(kl)" ] && ok "kanban: speaks again when un-mothballed" || ko "kanban: still silent after un-mothball"

# ---- HEALTH stale worktrees, once a day
T=$(mktemp -d); export HOME="$T"; mkdir -p "$T/.claude"
ln -s "$REAL/.claude/scripts" "$T/.claude/scripts"
R=$(mktemp -d)
git -C "$R" init -q -b main
git -C "$R" -c user.email=a@b -c user.name=n commit -q --allow-empty -m init
git -C "$R" worktree add -q "$R-wt1" -b wt1
touch -t 202601010000 "$R-wt1"
hc(){ printf '{"session_id":"s","cwd":"%s"}' "$R" | bash "$HC" 2>"$T/stderr"; }
o=$(hc | ctx)
printf '%s' "$o" | rg -q "Stale worktree" && ok "health: first session of the day carries the worktree line" || ko "health: first session silent: $o"
o=$(hc | ctx)
[ -z "$o" ] && ok "health: second session the same day: silent" || ko "health: repeated: $o"
rg -q "Stale worktree" "$T/stderr" && ok "health: the owner's box still shows it" || ko "health: owner box lost the worktree line"
git -C "$R" worktree add -q "$R-wt2" -b wt2
touch -t 202601010000 "$R-wt2"
o=$(hc | ctx)
printf '%s' "$o" | rg -q "wt2" && ok "health: a new stale worktree is announced" || ko "health: new worktree silent: $o"
printf '%s' "$o" | rg -q "wt1" && ko "health: old worktree repeated beside the new one" || ok "health: old worktree not repeated"
for d in "$T"/.claude/.inject-once/health-worktree/d-*; do mv "$d" "$T/.claude/.inject-once/health-worktree/d-2000-01-01"; done
o=$(hc | ctx)
printf '%s' "$o" | rg -q "wt1" && ok "health: the next day speaks again" || ko "health: next day silent: $o"
export HOME="$REAL"

# ---- muted-gates, once per change
M=$(mktemp -d); mkdir -p "$M/scripts/hooks" "$M/hinters"
mg(){ printf '{}' | env INJECT_ONCE_DIR="$M/.once" MUTED_GATES_ROOT="$M" bash "$MG" | ctx; }
: > "$M/.no-foo-gate"
[ -n "$(mg)" ] && ok "gates: a new set of mutes is announced" || ko "gates: new set silent"
[ -z "$(mg)" ] && ok "gates: the same set is silent" || ko "gates: same set repeated"
[ -z "$(mg)" ] && ok "gates: still silent on the third session" || ko "gates: third session repeated"
: > "$M/.no-bar-gate"
o=$(mg)
printf '%s' "$o" | rg -q "no-bar-gate" && ok "gates: an added mute is announced" || ko "gates: added mute silent"
trash "$M/.no-foo-gate" "$M/.no-bar-gate"
[ -z "$(mg)" ] && ok "gates: no mutes: silent" || ko "gates: spoke with no mutes"
: > "$M/.no-foo-gate"
[ -n "$(mg)" ] && ok "gates: mutes returning after a clean spell are announced again" || ko "gates: returning mute silent"

trash "$K" "$T" "$R" "$R-wt1" "$R-wt2" "$M" 2>/dev/null || true
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]
