#!/usr/bin/env bash
# guard-speculative-export.sh — PostToolUse[Edit|Write], SYNCHRONOUS, WARN-ONLY.
#
# Catches the agent adding an EXPORTED symbol that has no caller anywhere in the
# tree — pure speculative API surface. The enforced rule:
# rules/speculative-abstractions-without-a-load-bearing-caller.md.
#
# It only ever NUDGES (emits additionalContext); it never blocks. A block at this
# signal's ~35% false-positive floor would be muted on sight (see the empirical
# replay in assets/reports/20260630-s3-gate-leak/). The nudge is cheap to dismiss
# in one line ("wiring it next edit"), so the residual FP costs ~nothing.
#
# MUST be wired SYNCHRONOUS in settings.json (matcher "Edit|Write", NO async
# flag). An async PostToolUse hook's stdout is invisible to the agent on this
# machine (verified hook-output contract) — the nudge would run, log telemetry,
# emit perfect JSON, and reach nobody. Sync is the only channel that lands.
#
# Detection = V2 "zero-caller including own-file" (ts-prune `(used in module)` /
# knip `ignoreExportsUsedInFile` semantics). A symbol used anywhere in the tree —
# a satisfies/as cast or union member in its own file, a real callsite elsewhere —
# is suppressed. Only a symbol whose sole occurrence is its own declaration fires.
#
# Two reference-counting modes (SPECEXPORT_MODE, default lenient):
#   strict  — any non-declaration reference anywhere suppresses.
#   lenient — references in TEST files, on comment-only lines, or inside string
#             literals do NOT count as callers (tests are not consumers; a helper
#             that ships WITH a unit test is still speculative surface). Default.
#
# Mute: touch ~/.claude/.no-speculative-export-gate

set -uo pipefail

# --- Mute + tool availability (silent exit on any doubt) --------------------
[ -f "$HOME/.claude/.no-speculative-export-gate" ] && exit 0
command -v rg >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null || true)
[ -z "$INPUT" ] && exit 0

file_path=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$file_path" ] && exit 0
case "$file_path" in /*) : ;; *) file_path="${PWD}/${file_path}" ;; esac

# TS/JS only — the whole speculative-export class is a TS/JS phenomenon.
case "$file_path" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.mts|*.cts) : ;;
  *) exit 0 ;;
esac

mode="${SPECEXPORT_MODE:-lenient}"
case "$mode" in strict|lenient) : ;; *) mode="lenient" ;; esac

# --- Payload (the text this Edit/Write added) -------------------------------
payload=$(printf '%s' "$INPUT" | jq -r '
  .tool_input.content
  // .tool_input.new_string
  // ((.tool_input.edits // []) | map(.new_string // "") | join("\n"))
  // empty' 2>/dev/null)
[ -z "$payload" ] && exit 0

# --- Project root: nearest ancestor with a project marker -------------------
root=""; d=$(dirname "$file_path")
while [ "$d" != "/" ] && [ -n "$d" ]; do
  if [ -e "$d/package.json" ] || [ -d "$d/.git" ] || [ -f "$d/tsconfig.json" ] || [ -f "$d/pyproject.toml" ] || [ -f "$d/go.mod" ]; then
    root="$d"; break
  fi
  d=$(dirname "$d")
done
[ -z "$root" ] && exit 0   # no project context → don't guess, don't fire

# --- Session id for the once-per-symbol sentinel ----------------------------
sid=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
if [ -z "$sid" ] && [ -f "$HOME/.claude/.current-session-id" ]; then
  sid=$(tr -d '[:space:]' < "$HOME/.claude/.current-session-id" 2>/dev/null)
fi
sid8="${sid:0:8}"; [ -z "$sid8" ] && sid8="nosid"

# --- Helpers ----------------------------------------------------------------

# Generic / short names that recur per-file and are rarely the speculative class.
is_generic() {
  case "$1" in
    run|main|setup|init|start|stop|index|render|create|update|build|parse|format|props|config|options|state|default|handler|handle|toString|valueOf) return 0 ;;
    *) return 1 ;;
  esac
}

is_test_file() {
  case "$1" in
    *.test.*|*.spec.*|*/__tests__/*|*.stories.*|*.fixtures.*|*.mock.*|*.d.ts) return 0 ;;
    *) return 1 ;;
  esac
}

# A BUILD ARTIFACT (compiled/bundled twin), not hand-authored source. Reused
# verbatim from guard-duplicate-symbol.sh — only ever filters a reference OUT
# (can never manufacture a fire). Layered: bundler dirs/ext → gitignored →
# committed-artifact signature → minified single-line.
is_build_output() {
  local p="$1"
  case "$p" in
    */dist/*|*/build/*|*/out/*|*/.next/*|*/node_modules/*|*/vendor/*|*.min.js|*.bundle.js|*.min.css) return 0 ;;
  esac
  git -C "$root" check-ignore -q "$p" 2>/dev/null && return 0
  head -c 4000 "$p" 2>/dev/null | rg -q 'sourceMappingURL|esbuild|webpackBootstrap|__esModule' 2>/dev/null && return 0
  local firstlen lines
  firstlen=$(head -n 1 "$p" 2>/dev/null | wc -c | tr -d ' ')
  lines=$(wc -l < "$p" 2>/dev/null | tr -d ' ')
  [ "${firstlen:-0}" -gt 1000 ] && [ "${lines:-99}" -lt 3 ] && return 0
  return 1
}

# GATE 2 + GATE 3(def-file half): file kinds that legitimately export symbols a
# tree-grep cannot see being consumed → suppress the WHOLE file. Barrels, package
# entry targets, .d.ts, framework auto-discovered routes, standalone scripts/bins,
# test files, build artifacts.
def_file_exempt() {
  local p="$1" base
  base=$(basename "$p")
  is_test_file "$p" && return 0            # GATE 3 test-def exemption (+ .d.ts)
  is_build_output "$p" && return 0
  case "$base" in
    index.ts|index.tsx|index.js|index.jsx|index.mjs|index.cjs|index.mts|index.cts) return 0 ;;  # barrel/entry
    page.tsx|page.jsx|page.ts|page.js|route.ts|route.js|route.tsx|route.jsx|\
    layout.tsx|layout.jsx|layout.ts|layout.js|loading.tsx|loading.jsx|\
    error.tsx|error.jsx|default.tsx|default.jsx|template.tsx|not-found.tsx|\
    middleware.ts|middleware.js|+page.svelte|+layout.svelte|+server.ts|+page.ts|+page.server.ts) return 0 ;;  # framework routes
  esac
  case "$p" in
    */scripts/*|*/bin/*|*/perf/*|*/tools/*|*/benchmark*/*|*/benchmarks/*) return 0 ;;  # standalone scripts/bins
  esac
  # package.json#exports / main / module / bin targets → external consumers.
  if [ -f "$root/package.json" ]; then
    local tgt
    while IFS= read -r tgt; do
      [ -z "$tgt" ] && continue
      tgt="${tgt#./}"
      [ "$root/$tgt" = "$p" ] && return 0
    done < <(jq -r '
      [ .main, .module, .browser,
        (.bin | if type=="string" then . elif type=="object" then .[] else empty end),
        (.exports | .. | strings) ]
      | map(select(. != null and (type=="string"))) | .[]' "$root/package.json" 2>/dev/null)
  fi
  return 1
}

# Opt-out / hedge marker on NAME's declaration line or the line directly above,
# read from the on-disk (post-write) def-file. Lets a deliberately-reserved export
# be marked once and stop the nudge recurring.
has_optout_marker() {
  local name="$1" ln above ctx
  ln=$(rg -n "export\s+(?:declare\s+)?(?:async\s+)?(?:abstract\s+)?(?:function|const|let|var|type|interface|class|enum)\s+${name}\b" "$file_path" 2>/dev/null | head -1 | cut -d: -f1)
  [ -z "$ln" ] && return 1
  above=$((ln - 1))
  if [ "$above" -ge 1 ]; then
    ctx=$(sed -n "${above}p;${ln}p" "$file_path" 2>/dev/null)
  else
    ctx=$(sed -n "${ln}p" "$file_path" 2>/dev/null)
  fi
  printf '%s' "$ctx" | rg -q '@public|speculative-ok|knip-ignore|ts-prune-ignore-next|\[claude@' 2>/dev/null && return 0
  return 1
}

# Does one rg hit (content of a `file:lineno:content` line) count as a real
# consuming reference to NAME? Applies the FP-1 declaration-line anchoring and,
# in lenient mode, the test/comment/string exclusions.
counts_as_ref() {
  local file="$1" content="$2" name="$3"
  # FP-1 fix: drop ONLY lines that DECLARE name itself (name right after the kind
  # keyword). A line that merely MENTIONS name in its body — e.g.
  #   export const fetchUserList = () => fetchUser()
  # — is a real USE of fetchUser and must count.
  printf '%s' "$content" | rg -q "export\s+(?:declare\s+)?(?:async\s+)?(?:abstract\s+)?(?:function|const|let|var|type|interface|class|enum)\s+${name}\b" 2>/dev/null && return 1
  if [ "$mode" = lenient ]; then
    is_test_file "$file" && return 1                                   # tests aren't consumers
    printf '%s' "$content" | rg -q '^\s*(//|/\*|\*)' 2>/dev/null && return 1  # comment-only line
    # Strip inline comments + string literals; if name no longer appears, its
    # only occurrence on this line was inside a string/comment → not a ref.
    local stripped
    stripped=$(printf '%s' "$content" | sed -e 's://.*::' -e 's:/\*[^*]*\*/::g' -e "s:'[^']*'::g" -e 's:"[^"]*"::g' -e 's:`[^`]*`::g')
    printf '%s' "$stripped" | rg -q "\b${name}\b" 2>/dev/null || return 1
  fi
  return 0
}

# --- Extract exported symbols this edit ADDED -------------------------------
# All speculative-surface kinds (fn AND type/interface/class/enum AND non-fn
# const/let/var). Excludes `export default` (no stable name) and `export {…}`
# re-exports (not matched by the decl regex at all).
decl='export\s+(?:declare\s+)?(?:async\s+)?(?:abstract\s+)?(?:function|const|let|var|type|interface|class|enum)\s+([A-Za-z_$][A-Za-z0-9_$]*)'
names=$(printf '%s' "$payload" | rg -o --no-line-number "$decl" -r '$1' 2>/dev/null | sort -u)
[ -z "$names" ] && exit 0

# GATE 2/3 def-file exemption suppresses the whole file cheaply.
def_file_exempt "$file_path" && exit 0

# Hard cap: check at most the first 5 candidate names (bounds rg passes → <2s).
total_names=$(printf '%s\n' "$names" | grep -c . 2>/dev/null); total_names=${total_names:-0}
names=$(printf '%s\n' "$names" | head -5)
truncated=0
[ "$total_names" -gt 5 ] && truncated=1

globs=(-g '*.ts' -g '*.tsx' -g '*.js' -g '*.jsx' -g '*.mjs' -g '*.cjs' -g '*.mts' -g '*.cts' \
       -g '!**/node_modules/**' -g '!**/dist/**' -g '!**/build/**' -g '!**/.next/**' -g '!**/out/**')

rel="${file_path#$root/}"
fires=""
while IFS= read -r name; do
  [ -z "$name" ] && continue
  [ "${#name}" -lt 5 ] && continue
  is_generic "$name" && continue
  case "$name" in *'$'*) continue ;; esac      # `$` would mis-anchor the rg regex
  [ -f "/tmp/claude-specexport-${sid8}-${name}" ] && continue   # once per (symbol, session)
  has_optout_marker "$name" && continue        # // @public | // speculative-ok | …

  # V2 zero-caller check: scan the tree for `\bNAME\b`; a single real consuming
  # reference (per counts_as_ref) suppresses the fire.
  used=0
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    hfile="${hit%%:*}"
    rest="${hit#*:}"; hcontent="${rest#*:}"    # strip `file:` then `lineno:`
    is_build_output "$hfile" && continue
    if counts_as_ref "$hfile" "$hcontent" "$name"; then used=1; break; fi
  done < <(rg -n --no-heading "${globs[@]}" "\b${name}\b" "$root" 2>/dev/null)

  [ "$used" -eq 1 ] && continue                # has a real caller → not speculative

  touch "/tmp/claude-specexport-${sid8}-${name}" 2>/dev/null || true
  fires="${fires}  ▸ \`${name}\` in ${rel}"$'\n'
done <<< "$names"

[ -z "$fires" ] && exit 0

trunc_note=""
[ "$truncated" -eq 1 ] && trunc_note=$'\n'"(This write added >5 exports; only the first 5 were checked.)"

msg="[speculative-abstraction] You added exported symbol(s) with NO caller anywhere in the tree (including their own file):
${fires}If you're not wiring a consumer this turn, inline each at its callsite instead of exporting speculative API surface — let helpers crystallize from ≥2 real callsites. If a consumer lands later this turn, ignore this. (Advisory; fires once per symbol per session.)${trunc_note}
Rule: rules/speculative-abstractions-without-a-load-bearing-caller.md
Mute: touch ~/.claude/.no-speculative-export-gate"

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-speculative-export --action nudge --heeded unknown --cwd "$(printf '%s' "$INPUT" | jq -r '.cwd//empty' 2>/dev/null)" --target "$file_path" >/dev/null 2>&1 || true
jq -nc --arg m "$msg" '{additionalContext:$m}' 2>/dev/null || true
exit 0
