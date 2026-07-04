#!/usr/bin/env bash
# guard-banned-vocab.sh — PreToolUse[Write|Edit|MultiEdit], SYNCHRONOUS.
#
# Blocks an edit/write from ADDING a term a project has explicitly declared
# off-limits. This exists because a real, repeated user correction — "stop
# writing <forbidden term> in this doc" (e.g. 'Impersonation') — kept coming
# back: the agent would re-introduce the banned word a document later, having
# forgotten the earlier correction. A per-project vocab file makes the ban
# durable and mechanical instead of relying on the agent's memory.
#
# OPT-IN — INERT UNLESS A PROJECT OPTS IN. The gate reads a per-project file at
# <project-root>/.claude/banned-vocab.txt. If that file does NOT exist anywhere
# up the tree from the edited file, the gate exits 0 silently — it does nothing.
# That is why this is a BLOCK and not a nudge: the ban is a rule the USER wrote
# down for THIS project, so a block is warranted and the false-positive rate is
# structurally near-zero (a project only opts in when it means it).
#
# ─────────────────────────────────────────────────────────────────────────────
# banned-vocab.txt FORMAT (place at <project-root>/.claude/banned-vocab.txt)
# ─────────────────────────────────────────────────────────────────────────────
#   • One entry per line.
#   • Two line shapes:
#       Impersonation                       ← ban the term, no suggestion
#       Impersonation => Access delegation   ← ban + suggest a replacement
#   • Blank lines are ignored.
#   • A line whose first non-space char is '#' is a comment.
#   • Matching is CASE-INSENSITIVE and WHOLE-WORD: 'Impersonation' matches
#     "the Impersonation flow" but NOT "ImpersonationService" (camelCase) nor
#     "impersonation_service" (snake_case) — an identifier is not a prose word.
#   • Multi-word phrases work: `click here => the settings page`.
#   • Terms shorter than 2 chars are skipped (a 1-char whole-word ban is noise).
#
#   Example file:
#       # Words we never use in customer-facing docs
#       Impersonation => Access delegation
#       blacklist      => denylist
#       whitelist      => allowlist
#       simply
# ─────────────────────────────────────────────────────────────────────────────
#
# SCOPE — text/doc files (.md/.mdx/.markdown/.txt/.rst/.adoc) plus common source
# files (so a banned term in a code comment or string is caught too). Whole-word
# matching keeps code identifiers from tripping it. Non-text/data/binary files
# and the banned-vocab.txt file itself are skipped.
#
# Output contract: {decision:"block", reason:...} on stdout, exit 0 always.
# Silent exit 0 on any doubt (no jq/rg, no file_path, wrong file type, no
# vocab file, no added text).
#
# Telemetry: warn-log.sh --hook guard-banned-vocab --action block (|| true,
# never alters stdout/exit).
#
# Mute: touch ~/.claude/.no-banned-vocab-gate

set -uo pipefail

# ── Mute (first executable line) ────────────────────────────────────────────
[ -f "$HOME/.claude/.no-banned-vocab-gate" ] && exit 0

# ── Hard dependencies — silent no-op if missing ─────────────────────────────
command -v jq >/dev/null 2>&1 || exit 0
command -v rg >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null || true)
[ -z "$INPUT" ] && exit 0
printf '%s' "$INPUT" | jq empty 2>/dev/null || exit 0

TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
case "$TOOL" in Write | Edit | MultiEdit) ;; *) exit 0 ;; esac

file_path=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$file_path" ] && exit 0

# Resolve a relative path against the hook's CWD.
case "$file_path" in /*) : ;; *) file_path="$PWD/$file_path" ;; esac

# Never scan the vocab file itself — it legitimately lists the banned terms.
case "$file_path" in */.claude/banned-vocab.txt) exit 0 ;; esac

# Text/doc + reasonable source scope. Data/binary/lock files stay out.
case "$file_path" in
  *.md | *.mdx | *.markdown | *.txt | *.rst | *.adoc | *.rest) ;;
  *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs | *.py | *.rb | *.go | *.rs) ;;
  *.java | *.kt | *.php | *.c | *.cc | *.cpp | *.h | *.hpp | *.cs | *.swift) ;;
  *.css | *.scss | *.less | *.html | *.htm | *.vue | *.svelte | *.sh | *.sql) ;;
  *) exit 0 ;;
esac

# ── Find the opt-in vocab file: nearest ancestor with .claude/banned-vocab.txt ─
vocab=""
d=$(dirname "$file_path")
while [ "$d" != "/" ] && [ -n "$d" ]; do
  if [ -f "$d/.claude/banned-vocab.txt" ]; then
    vocab="$d/.claude/banned-vocab.txt"
    break
  fi
  d=$(dirname "$d")
done
[ -z "$vocab" ] && exit 0   # project has NOT opted in → gate is inert

# ── The text this edit ADDS (only the new slice, per tool) ──────────────────
NEW_CONTENT=""
case "$TOOL" in
  Write)     NEW_CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null) ;;
  Edit)      NEW_CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.new_string // empty' 2>/dev/null) ;;
  MultiEdit) NEW_CONTENT=$(printf '%s' "$INPUT" | jq -r '[.tool_input.edits[]?.new_string] | join("\n") // empty' 2>/dev/null) ;;
esac
[ -z "$NEW_CONTENT" ] && exit 0

# ── Trim helper (bash 3.2 safe) ─────────────────────────────────────────────
trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# ── Scan the added text against each banned entry ───────────────────────────
hits=""
while IFS= read -r raw || [ -n "$raw" ]; do
  line=$(trim "$raw")
  [ -z "$line" ] && continue
  case "$line" in \#*) continue ;; esac   # full-line comment

  if [[ "$line" == *"=>"* ]]; then
    term=$(trim "${line%%=>*}")
    repl=$(trim "${line#*=>}")
  else
    term="$line"; repl=""
  fi
  [ -z "$term" ] && continue
  [ "${#term}" -lt 2 ] && continue   # a 1-char whole-word ban is noise

  # Case-insensitive, whole-word, literal (-F so regex-meta in the term is safe).
  if printf '%s' "$NEW_CONTENT" | rg -Fiw -q -- "$term" 2>/dev/null; then
    if [ -n "$repl" ]; then
      hits="${hits}  • the term \"${term}\" is banned in this project (.claude/banned-vocab.txt); use \"${repl}\" instead
"
    else
      hits="${hits}  • the term \"${term}\" is banned in this project (.claude/banned-vocab.txt)
"
    fi
  fi
done < "$vocab"

[ -z "$hits" ] && exit 0

# ── Block ───────────────────────────────────────────────────────────────────
reason="⛔ BANNED VOCABULARY — this write to $(basename "$file_path") adds a term this project has explicitly banned:
${hits}Rephrase to remove it (or use the suggested replacement) and re-submit.
This ban is declared by the project at .claude/banned-vocab.txt. Genuinely need the term (e.g. quoting it)? Edit that file to remove the entry, or mute: touch ~/.claude/.no-banned-vocab-gate"

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-banned-vocab --action block --heeded unknown --cwd "$(printf '%s' "$INPUT" | jq -r '.cwd//empty' 2>/dev/null)" --target "$file_path" >/dev/null 2>&1 || true
jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
exit 0
