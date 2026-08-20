#!/usr/bin/env bash
# export-agents-md.sh — regenerate $CODEX_HOME/AGENTS.md, the instruction file
# Codex loads on every turn. DERIVED from two inputs; never hand-edit the output.
#
#   adapters/codex/preamble.md  (hand-authored: the working agreement)
# + rules/00-index.md           (generated: the one-line-per-rule menu)
# = $CODEX_HOME/AGENTS.md
#
# Why generated: gcc-hygiene principle 1, authoritative source beats derived view.
# The preamble and the rule briefs each have exactly one home; this file is a view
# of them. Editing the output means the next run silently reverts you.
#
# Why a router and not a dump: rules/*.md is ~176k chars of standing instruction.
# Claude Code autoloads that under a subscription. Codex bills per token on every
# turn, and $CODEX_HOME/AGENTS.md is re-sent each time. So the index ships (about
# 12k chars) and Codex reads full rules from ~/.claude/rules/ on demand.
#
# Run after editing the preamble, or after rules-index.sh regenerates the index.
set -uo pipefail

CLAUDE_DIR="$HOME/.claude"
PREAMBLE="$CLAUDE_DIR/adapters/codex/preamble.md"
INDEX="$CLAUDE_DIR/rules/00-index.md"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
OUT="$CODEX_HOME/AGENTS.md"

# Codex truncates the instruction file at project_doc_max_bytes rather than
# erroring, so an oversized AGENTS.md fails silently and invisibly. Default is
# 32 KiB; override CODEX_DOC_MAX_BYTES if config.toml sets a different cap.
MAX_BYTES="${CODEX_DOC_MAX_BYTES:-32768}"

die() { printf 'export-agents-md: %s\n' "$1" >&2; exit 1; }

# The cap is the only thing standing between us and Codex's silent truncation,
# so a typo in the override must not disable it. There is no `set -e` here, so
# an unvalidated non-numeric value would fail the -gt test, print a shell error,
# and let the write proceed with exit 0.
case "$MAX_BYTES" in
  ''|*[!0-9]*) die "CODEX_DOC_MAX_BYTES must be a positive integer, got: '$MAX_BYTES'" ;;
esac
[ "$MAX_BYTES" -gt 0 ] || die "CODEX_DOC_MAX_BYTES must be greater than zero"

[ -f "$PREAMBLE" ] || die "missing preamble: $PREAMBLE"
[ -f "$INDEX" ] || die "missing rules index: $INDEX
  regenerate it first: bash $CLAUDE_DIR/scripts/rules-index.sh"
[ -d "$CODEX_HOME" ] || die "CODEX_HOME is not a directory: $CODEX_HOME"

stamp=$(date '+%Y-%m-%d %H:%M')
tmp=$(mktemp "${TMPDIR:-/tmp}/agents-md.XXXXXX") || die "mktemp failed"
trap 'rm -f "$tmp"' EXIT

{
  printf '<!-- DERIVED FILE. NEVER hand-edit. -->\n'
  printf '<!-- Generated %s by ~/.claude/scripts/export-agents-md.sh -->\n' "$stamp"
  printf '<!-- Sources: ~/.claude/adapters/codex/preamble.md + ~/.claude/rules/00-index.md -->\n'
  printf '<!-- Edit the preamble, or a rule brief + rules-index.sh, then re-run. -->\n\n'

  cat "$PREAMBLE"
  printf '\n'

  # The index carries YAML frontmatter aimed at Claude Code's trigger matcher.
  # Codex has no such matcher, so strip it: drop everything through the second
  # '---' delimiter. Guard on line 1 so a frontmatter-less index passes through.
  #
  # If the frontmatter never closes, this eats the whole file and emits nothing.
  # That would ship a preamble-only AGENTS.md, under the byte cap, with a success
  # message. The row-count assertion below is what catches it.
  awk 'NR==1 && $0=="---" {infm=1; next} infm && $0=="---" {infm=0; next} !infm' "$INDEX"
} > "$tmp"

# The index's payload is its table. If the strip ate it, fail loudly rather than
# shipping a router with no rules in it.
rows_in=$(grep -c '^| `' "$INDEX" || true)
rows_out=$(grep -c '^| `' "$tmp" || true)
[ "$rows_out" -gt 0 ] || die "frontmatter strip produced no rule rows from $INDEX
  (unterminated frontmatter would do this). Refusing to ship a ruleless router."
[ "$rows_out" -eq "$rows_in" ] || die "rule-row count changed during assembly: \
$rows_in in, $rows_out out. Refusing to ship a partial menu."

bytes=$(wc -c < "$tmp" | tr -d ' ')
if [ "$bytes" -gt "$MAX_BYTES" ]; then
  die "output is ${bytes} bytes, over the ${MAX_BYTES} cap.
  Codex TRUNCATES rather than erroring, so shipping this would silently drop the
  tail. Shorten the preamble, or raise project_doc_max_bytes in config.toml and
  re-run with CODEX_DOC_MAX_BYTES set to match."
fi

mv -f "$tmp" "$OUT" || die "could not write $OUT"
trap - EXIT

printf 'wrote %s\n  %s bytes of %s cap (%s%% used), %s lines\n' \
  "$OUT" "$bytes" "$MAX_BYTES" "$(( bytes * 100 / MAX_BYTES ))" "$(wc -l < "$OUT" | tr -d ' ')"
