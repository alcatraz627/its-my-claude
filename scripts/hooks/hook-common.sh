#!/usr/bin/env bash
# hook-common.sh — small primitives shared across the Stop / PreToolUse hooks.
#
# What this is, in human terms: two operations that a dozen hooks each hand-rolled
# a copy of — deriving a short per-session tag for /tmp marker paths, and the
# "fire once per distinct claim, then step aside on repeats" loop-safety check.
# Centralizing them fixes one latent bug (an absent session id produced a dangling
# marker path like /tmp/claude-<name>-) and gives new hooks one correct copy to
# source instead of pasting the idiom yet again. Provenance: the 2026-07-11 hook
# subsystem audit, assets/reports/20260711-subsystem-review/hooks.md §2c, §3.
#
# Source it (defines functions only — sourcing has no side effects):
#   . "$HOME/.claude/scripts/hooks/hook-common.sh"

# hook_sid8 <session_id> — echo an 8-char, marker-safe session tag.
#
# Returns the first 8 characters of the session id, or the literal "nosid" when
# the id is empty. Every hook builds /tmp marker paths as
# /tmp/claude-<name>-<sid8>; without this guard an absent session_id collapses the
# path to a dangling "/tmp/claude-<name>-" suffix, so unrelated turns collide on
# one marker. Only 1 of ~29 hand-rolled call sites guarded this (audit §2c).
hook_sid8() {
  local sid="${1:-}"
  local s8="${sid:0:8}"
  if [ -n "$s8" ]; then printf '%s' "$s8"; else printf 'nosid'; fi
}

# hook_loop_check <marker_path> <content> — loop-safety signature check.
#
# Decides whether <content> is a NEW trigger this session or a REPEAT of the one
# already recorded at <marker_path>, using the shasum-signature idiom every Stop
# hook copies by hand. Records the new signature as a side effect so the next call
# sees it. The caller keeps its own divergent behaviour (block vs soft vs silent,
# heed-logging) around this decision — this owns only the mechanism.
#
#   returns 0  → NEW: the signature differs from the stored one (or none was
#                stored / could be computed). The marker has been updated to this
#                signature; the caller should fire (block / soft).
#   returns 1  → REPEAT: an identical, non-empty signature is already stored. The
#                caller should step aside (soft note / silent), NOT re-fire.
#
# An unhashable/empty signature (e.g. shasum unavailable) is treated as NEW, which
# matches the `[ "$sig" = "$prev" ] && [ -n "$sig" ]` guard every call site used.
hook_loop_check() {
  local marker="${1:-}" content="${2:-}"
  local sig prev
  sig=$(printf '%s' "$content" | shasum 2>/dev/null | awk '{print $1}')
  prev=""
  [ -f "$marker" ] && prev=$(cat "$marker" 2>/dev/null)
  if [ -n "$sig" ] && [ "$sig" = "$prev" ]; then
    return 1
  fi
  printf '%s' "$sig" > "$marker" 2>/dev/null || true
  return 0
}

# hook_box <title> [width] — wrap stdin in a titled box, echo it to stdout.
#
# Gives a blocking reason a shape the reader can scan instead of a wall of text.
# The body arrives on stdin so a caller can build it with printf and pipe it in;
# long lines are wrapped on word boundaries so nothing runs off the edge.
#
#   reason=$(printf 'line one\nline two\n' | hook_box "⛔ MY GATE")
#
# The box is deliberately open on the right — a top rule, a left rail, a bottom
# rule, and no closing column. That is the shape rules/surface-hook-nudges-to-user.md
# tells the agent to re-render hook output in, so a reason built here can be
# pasted into a reply verbatim. It also sidesteps the alignment bug the closed
# form invites: box-drawing characters and emoji occupy more display columns
# than bash counts, so a right border drifts by a column or two per line and the
# raggedness is exactly what the box was added to avoid.
hook_box() {
  local title="${1:-}" width="${2:-72}" line
  local rule='' i=0
  # Fill to `width` after the title, or a short tail if the title already runs long.
  local fill=$(( width - ${#title} - 4 ))
  [ "$fill" -lt 3 ] && fill=3
  while [ "$i" -lt "$fill" ]; do rule="${rule}─"; i=$((i + 1)); done
  printf '┌─ %s %s\n' "$title" "$rule"
  # -s breaks on spaces so words stay whole; the 2 accounts for the "│ " rail.
  # fold leaves the break space at the end of the line, so trim before printing.
  # The `|| [ -n "$line" ]` is load-bearing: read reports failure on a final line
  # with no newline, and callers build these bodies with printf, which routinely
  # ends without one. Without it the last line of every reason is dropped.
  fold -s -w $((width - 2)) 2>/dev/null | sed 's/[[:space:]]*$//' \
  | while IFS= read -r line || [ -n "$line" ]; do
      if [ -n "$line" ]; then printf '│ %s\n' "$line"; else printf '│\n'; fi
    done
  # width - 1 dashes, because the corner character is itself the first column.
  # Counting a full `width` here made every box one character wider at the
  # bottom than at the top, in every box this ever drew.
  rule=''; i=0
  while [ "$i" -lt $((width - 1)) ]; do rule="${rule}─"; i=$((i + 1)); done
  printf '└%s\n' "$rule"
}

# hook_box_kind <kind> <name> [attr] [width] — vocab-aware hook_box.
#
# Composes the v2 anatomy (emoji emitter, kind · name title, heavy rails for
# gates, right-anchored attr) by delegating to scripts/box/box.sh, so a
# hook-composed box and an agent-composed box read one dialect from one
# vocabulary (scripts/box/vocab.tsv). Body arrives on stdin exactly like
# hook_box, and is captured BEFORE the delegate runs so a failed delegate
# cannot eat it. Falls back to a plain hook_box title when box.sh is missing
# or fails — a hook degrades, never dies, on a half-installed tree.
hook_box_kind() {
  local kind="${1:-}" name="${2:-}" attr="${3:-}" width="${4:-72}" body out
  local boxsh="${BOX_SH:-$HOME/.claude/scripts/box/box.sh}"
  body=$(cat)
  if [ -x "$boxsh" ]; then
    if [ -n "$attr" ]; then
      out=$(printf '%s\n' "$body" | "$boxsh" "$kind" "$name" --attr "$attr" --width "$width" 2>/dev/null) || out=''
    else
      out=$(printf '%s\n' "$body" | "$boxsh" "$kind" "$name" --width "$width" 2>/dev/null) || out=''
    fi
    if [ -n "$out" ]; then printf '%s\n' "$out"; return 0; fi
  fi
  printf '%s\n' "$body" | hook_box "$kind · $name" "$width"
}

# hook_clear_reset <sid8> <counter_file> — reset a per-process counter after /clear.
#
# The per-process counters keyed by ${PPID} (the tool tally, ctx %) survive a
# /clear because /clear does not restart the Claude process — so their pre-clear
# values leak into the fresh session (false auto-checkpoint / ctx-pressure /
# todo-discipline nudges). The SessionStart source==clear injector cannot reach
# those PPID files (its own PPID is the orchestrator's), so it drops a session-
# keyed sentinel `/tmp/claude-clear-reset-<sid8>`; the reader — which DOES know
# the right PPID — calls this at the top to drop a stale counter. Idempotent:
# once the reader rewrites its counter, the counter's mtime beats the sentinel,
# so it will not reset again this session.
hook_clear_reset() {
  local sid8="${1:-}" counter="${2:-}"
  [ -n "$sid8" ] && [ -n "$counter" ] || return 0
  local sentinel="/tmp/claude-clear-reset-${sid8}"
  if [ -f "$sentinel" ] && [ -f "$counter" ] && [ "$sentinel" -nt "$counter" ]; then
    rm -f "$counter" 2>/dev/null || true
  fi
}

# hook_cmd_skeleton — blank the CONTENTS of quoted regions in a shell command,
# so a matcher sees what the command INVOKES rather than what it merely MENTIONS.
#
# The mention-versus-invocation bug is this account's standing hook defect class:
# 17 hooks match against `.tool_input.command` raw, so any command carrying a
# quoted string that happens to contain `gh`, `rm`, a protected path, or a banned
# flag reads as an invocation of it. Three false fires landed in one session on
# 2026-08-15 alone (cli-gating on a python string, protect-atone-raw twice on a
# path quoted inside a JSON payload).
#
# USE IT AS THE SECOND STAGE, never the first. Match the raw command as before,
# and only when that hits, re-check against the skeleton:
#
#     printf '%s' "$cmd" | rg -q "$PAT" || exit 0          # cheap, unchanged
#     printf '%s' "$cmd" | hook_cmd_skeleton | rg -q "$PAT" || exit 0   # confirm
#
# That ordering keeps the cost at zero for the vast majority of commands, which
# never match at all, and pays roughly 2ms only on a candidate. Do not invert it.
#
# Quote characters are preserved and their contents become spaces, so the command
# skeleton keeps its token boundaries. Blanking to spaces rather than to a filler
# character matters: it separates tokens instead of welding them into new ones.
#
# Scope, stated because a helper that hides its limits is worse than none: this
# handles single quotes, double quotes, and backslash escapes. It does NOT parse
# heredoc bodies, command substitution, or ANSI-C `$'...'` quoting. A heredoc body
# is still raw text to a matcher, so a hook that must be right about heredocs
# needs its own handling.
#
# QUOTE STATE DOES NOT CARRY ACROSS NEWLINES. awk resets per record, so in a
# multi-line quoted argument only the FIRST line is blanked and lines 2..N are
# treated as bare text. A `git commit -m "subject\n\nbody"` therefore keeps its
# body visible to a matcher. This is why a guard whose whole job is to read the
# CONTENTS of a quoted argument must not be migrated: see the note below on
# guard-commit-signature, where a single-line trailer would be blanked away and
# the guard silently disarmed while the multi-line form still matched. That
# split behaviour is worse than either outcome alone, because the guard would
# pass its own tests on whichever form the test happened to use.
#
# DO NOT MIGRATE A SECURITY GUARD TO THIS. The filter assumes quoted text is
# inert prose, and for a guard protecting against a dangerous ACTION that
# assumption is false: `eval "export ANTHROPIC_API_KEY=x"` and `bash -c "<destructive>"`
# both put a real invocation inside quotes, so blanking would DISARM the guard
# rather than de-noise it. The trade differs by guard:
#
#   nuisance guard  (prefer-rg, prefer-read, a path-mention notice)
#       a false fire costs an interrupted turn, a miss costs nothing.
#       Migrate. The filter only ever removes noise.
#
#   security guard  (credentials, destructive deletes, push gates, tmp-jail)
#       a false fire costs an interrupted turn, a MISS can be unrecoverable.
#       Do NOT migrate. Accept the false fires, or teach the guard to see
#       through `eval` and `bash -c` explicitly before touching its matcher.
#
# There is a THIRD category the cost-of-miss split alone does not catch, found
# 2026-08-16 while migrating the nuisance tier: a guard whose matcher targets the
# CONTENTS of a quoted argument rather than the command being run. Blanking is
# not de-noising there, it is deleting the only thing the guard reads.
# guard-commit-signature is the live example: every banned trailer arrives inside
# `commit -m "..."`, so the skeleton erases exactly what it exists to catch. Ask
# not only "what does a miss cost" but "does this guard read the quotes?" — if it
# does, it stays raw no matter how cheap its misses are.
#
# This is the cost-of-miss question from features/hook-design.md applied to the
# matcher rather than to the consequence, and it is the reason this helper is
# opt-in per hook instead of being wired into a shared reader.
hook_cmd_skeleton() {
  awk '
  {
    line = $0; out = ""; state = 0   # 0 bare, 1 single-quoted, 2 double-quoted
    n = length(line)
    for (i = 1; i <= n; i++) {
      c = substr(line, i, 1)
      if (state == 0) {
        if (c == "\\" && i < n) { out = out c substr(line, i+1, 1); i++ }
        else if (c == "'"'"'") { out = out c; state = 1 }
        else if (c == "\"")    { out = out c; state = 2 }
        else out = out c
      } else if (state == 1) {
        if (c == "'"'"'") { out = out c; state = 0 } else out = out " "
      } else {
        if (c == "\\" && i < n) { out = out "  "; i++ }
        else if (c == "\"") { out = out c; state = 0 }
        else out = out " "
      }
    }
    print out
  }'
}
