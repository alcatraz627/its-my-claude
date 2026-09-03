#!/usr/bin/env bash
# guard-dev-server-port.test.sh — runnable checks for the dev-server port gate.
#
# Six false-fire proposals accumulated against this guard in three weeks while it
# had no test file at all. That is the cost this suite exists to stop: with
# nothing pinning the behaviour, each fix could silently undo an earlier one, and
# one did. The heredoc blanking added for prop-20260826-235336-54 was overwritten
# three lines later by the hook_cmd_skeleton assignment, so it never ran once.
#
# The controls matter more than the cases. This guard blocks via
# {"decision":"block"} on stdout with exit 0, NOT exit 2 — a probe that only reads
# the exit code sees every block as "allowed" and gives a broken hook a clean bill
# of health. Both mechanisms are checked below.
#
# The port fixtures are DERIVED from the live ledger rather than hardcoded, so a
# released pin or an expired claim cannot rot this file into a false failure.
#
# Run: bash ~/.claude/scripts/hooks/guard-dev-server-port.test.sh   (exit 0 = pass)

set -uo pipefail

# Keep test fires out of the live audit ledger. Without this, test events are
# indistinguishable from real ones, which is how 102 test events were once read
# as live adherence data (audit 2026-08-18).
export WARN_LOG_STORE="$(mktemp "${TMPDIR:-/tmp}/warnlog-devport-XXXXXX")"

HERE="$(cd "$(dirname "$0")" && pwd)"
# GUARD_UNDER_TEST lets the mutation harness point this suite at a deliberately
# broken copy. A suite that can only ever run against the real file cannot prove
# its own cases are load-bearing, and a guard whose tests have never gone red for
# the right reason is untested (rules/exercise-based-verification.md).
HOOK="${GUARD_UNDER_TEST:-$HERE/guard-dev-server-port.sh}"
PORTS="$HOME/.claude/scripts/dev-servers/ports.sh"
NEUTRAL_CWD="$HOME/.claude"     # no vite/next config here, so no port is sniffed

pass=0; fail=0; skip=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — got [$2] want [$3]"; fi; }
skipcase(){ skip=$((skip+1)); echo "  SKIP: $1 — $2"; }

verdict(){ # verdict <command> [cwd] -> BLOCK|allow
  local out rc cwd="${2:-$NEUTRAL_CWD}"
  out=$(jq -nc --arg c "$1" --arg d "$cwd" \
          '{tool_name:"Bash",tool_input:{command:$c},cwd:$d}' \
        | bash "$HOOK" 2>/dev/null); rc=$?
  if [ "$rc" -eq 2 ]; then echo BLOCK; return; fi
  if printf '%s' "$out" | rg -q '"decision":"block"' 2>/dev/null; then echo BLOCK; return; fi
  echo allow
}

# ── fixtures derived from the live ledger ───────────────────────────────────
PINNED_PORT=$($PORTS list 2>/dev/null | awk '$3=="pinned"{print $1; exit}')
CLAIMED_PORT=$($PORTS list 2>/dev/null | awk '$3=="claimed"{print $1; exit}')
FREE_PORT=$($PORTS next --tier 3 2>/dev/null)

echo "fixtures: pinned=$PINNED_PORT claimed=$CLAIMED_PORT free=$FREE_PORT"
echo

# ════════════════════════════════════════════════════════════════════════════
echo "── PARITY: real unguarded launches must still BLOCK ──"
# These are the guard's entire reason to exist. A fix that stops the false fires
# by firing less would show up here first.
ok "A-P1  portless vite"          "$(verdict 'vite')"                    BLOCK
ok "A-P2  portless npm run dev"   "$(verdict 'npm run dev')"             BLOCK
ok "A-P3  next dev"               "$(verdict 'next dev')"                BLOCK
ok "A-P4  framework-default port" "$(verdict 'vite --port 5173')"        BLOCK
ok "A-P5  python http.server"     "$(verdict 'python3 -m http.server')"  BLOCK
ok "      portless pnpm dev"      "$(verdict 'pnpm dev')"                BLOCK
ok "      portless uvicorn"       "$(verdict 'uvicorn app:app')"         BLOCK
ok "      env-prefixed launch"    "$(verdict 'NODE_ENV=development vite')" BLOCK

if [ -n "$PINNED_PORT" ]; then
  ok "A-P6  launch on a pinned port" "$(verdict "vite --port $PINNED_PORT")" BLOCK
else
  skipcase "A-P6  launch on a pinned port" "no pinned port in the ledger"
fi
if [ -n "$CLAIMED_PORT" ]; then
  ok "A-P7  launch on a claimed port" "$(verdict "vite --port $CLAIMED_PORT")" BLOCK
else
  skipcase "A-P7  launch on a claimed port" "no claimed port in the ledger"
fi

# A pm2 prefix must not smuggle a raw launch past the gate (review finding 8).
ok "A-P10 pm2 prefix + raw launch" "$(verdict 'pm2 ls; vite')"           BLOCK

echo
echo "── PARITY: documented escapes and non-launches must PASS ──"
ok "A-P8  PORTS_OK=1 escape"      "$(verdict 'PORTS_OK=1 vite')"         allow
# A-P9 records that pm2 commands pass, which they must. It does NOT isolate the
# pm2 exemption line: mutation M3 removed that line and this case stayed green,
# because LAUNCH_RE cannot match a command starting with `pm2` in the first place.
# Labelled honestly so nobody reads a green here as proof the exemption works.
ok "A-P9  pm2 command passes (not an exemption proof)" "$(verdict 'pm2 restart api')" allow
ok "A-P12 quoted mention"         "$(verdict "echo 'vite --port 3000'")" allow
ok "      rg searching the string" "$(verdict "rg -n 'npm run dev' package.json")" allow

# A-P11 — the config-sniffed port. This was the highest-frequency historical
# false fire (review finding 3): the framework-recommended place to pin a port is
# the project config, and blocking that correct setup is worse than useless.
if [ -n "$FREE_PORT" ]; then
  CFGDIR=$(mktemp -d "${TMPDIR:-/tmp}/devport-cfg-XXXXXX")
  printf 'export default { server: { port: %s } }\n' "$FREE_PORT" > "$CFGDIR/vite.config.ts"
  ok "A-P11 config-sniffed port honoured" "$(verdict 'vite' "$CFGDIR")"  allow
  # left for the OS to reap: this account bans rm, and trashing a temp dir on
  # every test run would fill the user's Trash with fixtures
else
  skipcase "A-P11 config-sniffed port" "ports.sh next --tier 3 returned nothing"
fi

echo
echo "── FILED FALSE FIRES: every one must PASS ──"
# Each case is one open proposal. When a case goes green the proposal is closable,
# and the id below is what to close.

ok "F1 cd  deploy script taking --env dev  (prop-20260818-013023-cd)" \
   "$(verdict 'bash scripts/deploy.sh --env dev')"                     allow

ok "F2 c1  npx tsx one-off script         (prop-20260820-191107-c1)" \
   "$(verdict 'npx tsx scripts/backfill.ts')"                          allow

ok "F3 fa  echo prose naming a launcher   (prop-20260811-113509-fa)" \
   "$(verdict "echo 'to start, use npm run dev'")"                     allow

# The two heredoc cases below are ONE bug: the blanking at guard-dev-server-port.sh:56
# is discarded at :68, which re-reads \$CMD instead of \$SCAN. They pass today only
# when the launcher sits mid-line, because LAUNCH_RE anchors at line start.
ok "F4a b5 heredoc prose, launcher mid-line  (prop-20260825-073424-b5)" \
   "$(verdict "$(printf 'cat <<EOF > /tmp/d.md\nplease run vite now\nEOF')")" allow

ok "F4b b5 heredoc prose, launcher at line start (prop-20260825-073424-b5)" \
   "$(verdict "$(printf 'cat <<EOF > /tmp/d.md\nvite --port 3000 is what we used\nEOF')")" allow

ok "F5 b6  git commit -F - heredoc message  (prop-20260903-131552-b6)" \
   "$(verdict "$(printf "git commit -q -F - <<'EOF'\nnpm run dev now uses 6200\nEOF")")" allow

ok "F6 94  npx vite-node one-off runner     (prop-20260825-215830-94)" \
   "$(verdict 'npx vite-node scripts/seed.ts')"                        allow

ok "F6b    npx vite-plugin-inspect          (same word-boundary defect)" \
   "$(verdict 'npx vite-plugin-inspect --help')"                       allow

echo
echo "── CONTROL: the suite can tell a block from an allow ──"
# Without this, a hook that never fires at all would show a perfect score.
ok "control: guard CAN block" "$(verdict 'vite')"                       BLOCK
ok "control: guard CAN allow" "$(verdict 'ls -la')"                     allow

echo
echo "---- pass=$pass fail=$fail skip=$skip"
[ "$fail" -eq 0 ]
