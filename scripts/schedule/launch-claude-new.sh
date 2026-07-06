#!/usr/bin/env bash
# Open a Ghostty window that starts a FRESH Claude Code session with a chosen
# model + permission mode — safely, from a scheduled (launchd) context. Sibling
# of launch-claude-resume.sh; that one resumes an existing session by UUID, this
# one boots a new session (no --resume) and pins the model (e.g. claude-fable-5).
#
# Why this wrapper exists: a scheduled launch goes through `open … zsh -lc`, whose
# login shell sources ~/.zprofile (brew shellenv + ~/.local/bin → the full PATH the
# session's hooks/tools need). We still exec claude by ABSOLUTE PATH (never relying
# on a PATH lookup) and source ~/.local/bin/env defensively/idempotently, so nothing
# breaks even if the profile changes. (launchd's own env is bare; the Ghostty login
# shell is what restores PATH — not this env-source, which is belt-and-suspenders.)
#
# Permission mode is a REQUIRED arg (no silent default): pass acceptEdits for an
# audit-style run (auto-accepts edits, still gates Bash), or default / plan.
# This wrapper never passes --allow-dangerously-skip-permissions.
#
# Usage:  launch-claude-new.sh <model> <permission-mode> [first-turn-prompt] [workdir]
# Set DRYRUN=1 to print the composed launch command instead of opening Ghostty.
set -uo pipefail

MODEL="${1:?usage: launch-claude-new.sh <model> <permission-mode> [prompt] [workdir]}"
PERM="${2:?usage: launch-claude-new.sh <model> <permission-mode> [prompt] [workdir]}"
PROMPT="${3:-}"
WORKDIR="${4:-$HOME/.claude}"
CLAUDE="$HOME/.local/bin/claude"

case "$PERM" in acceptEdits|default|plan) : ;; *)
  echo "launch-claude-new: refusing permission-mode '$PERM' (allowed: acceptEdits|default|plan)" >&2; exit 2 ;; esac

write_meta() { [[ -n "${GCC_SCHED_META:-}" ]] && printf '%s\n' "$@" > "$GCC_SCHED_META"; return 0; }

if [[ ! -x "$CLAUDE" ]]; then
  write_meta "outcome=failed" "reason=claude_missing" "stage=preflight"
  echo "launch-claude-new: claude not executable at $CLAUDE" >&2; exit 1
fi
if ! { [[ -d /Applications/Ghostty.app ]] || [[ -d "$HOME/Applications/Ghostty.app" ]]; }; then
  write_meta "outcome=failed" "reason=ghostty_missing" "stage=preflight"
  echo "launch-claude-new: Ghostty.app not found" >&2; exit 1
fi

# printf %q keeps every argument a single token when zsh re-parses the string.
# exec -a claude: force argv[0]="claude" even though we exec the ABSOLUTE binary
# path (needed so a launchd job finds it, §PATH note above). Without this, the
# process presents as `/…/.local/bin/claude …`, and tools that key on argv[0] —
# notably the claude-instances widget's scanner — don't recognise it as a session.
inner=". \"\$HOME/.local/bin/env\" 2>/dev/null; cd $(printf %q "$WORKDIR") && exec -a claude $(printf %q "$CLAUDE") --permission-mode $(printf %q "$PERM") --model $(printf %q "$MODEL")"
[[ -n "$PROMPT" ]] && inner+=" $(printf %q "$PROMPT")"

if [[ -n "${DRYRUN:-}" ]]; then
  printf 'open -na Ghostty.app --args -e zsh -lc %q\n' "$inner"; exit 0
fi

write_meta "outcome=unknown" "reason=post_handoff" "stage=handoff"
if open -na 'Ghostty.app' --args -e zsh -lc "$inner"; then exit 0
else write_meta "outcome=failed" "reason=open_failed" "stage=open"; exit 1; fi
