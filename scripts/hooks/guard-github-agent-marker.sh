#!/usr/bin/env bash
# guard-github-agent-marker.sh — no comment reaches GitHub under the owner's
# account without the owner's attribution marker in its body.
#
# Owner ruling 2026-08-24, after two S3s on the same slug
# (agent-comment-posted-without-agent-attribution): every agent-written comment
# posted via gh reads as the owner in a notification preview unless the marker
# is in the body. The marker text is the owner's, verbatim, with ONE of the
# bracket phrases picked at random and shown in italics.
#
# NO BYPASS BY DESIGN. The owner asked for no mute file, so this guard has
# none; the only way past it is to add the marker, and the block message
# hands the agent the exact line to paste.
set -u

MARKER_HEAD="Generated via a 🤖 on @"
PHRASES=(
  "what even is a safeguard"
  "what even is risk mitigation"
  "what even is critical infrastructure"
  "he will mess up one day because of this"
  "he got lazy"
  "he bought into the agentic hype"
  "mythos class model btw"
  "the same agent species that helped in Venezuela"
)

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$cmd" ] || exit 0

# Posting surfaces only. Reads (gh pr view, gh api GET) pass untouched, and so
# does everything that is not a comment/review write.
posts=0
if printf '%s' "$cmd" | grep -qE 'gh (pr|issue) comment'; then posts=1; fi
if printf '%s' "$cmd" | grep -qE 'gh api' \
   && printf '%s' "$cmd" | grep -qE '(comments|reviews)' \
   && printf '%s' "$cmd" | grep -qE '(-X|--method) *(POST|PATCH|PUT)|-F +body|-f +body|--field +body|--raw-field +body'; then posts=1; fi
[ "$posts" = "1" ] || exit 0

# Marker present? Check the inline command text first, then every readable
# file the command references as a body source.
has_marker=0
if printf '%s' "$cmd" | grep -qF "$MARKER_HEAD"; then has_marker=1; fi
if [ "$has_marker" = "0" ]; then
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
  # --body-file X, --body-file=X, -F body=@X, --field body=@X
  files=$(printf '%s' "$cmd" | grep -oE -- '(--body-file[= ]+[^ ]+|body=@[^ ]+)' \
          | sed -E 's/--body-file[= ]+//; s/body=@//' | tr -d '"'"'" )
  for f in $files; do
    p="$f"
    case "$p" in /*) ;; *) p="${cwd:-.}/$f" ;; esac
    if [ -f "$p" ] && grep -qF "$MARKER_HEAD" "$p"; then has_marker=1; break; fi
  done
fi
[ "$has_marker" = "1" ] && exit 0

pick=${PHRASES[$((RANDOM % ${#PHRASES[@]}))]}
GH_LOGIN=$(gh api user --jq .login 2>/dev/null || echo "the-logged-in-gh-user")
cat >&2 <<EOF
⛔ AGENT MARKER MISSING — this posts to GitHub under the owner's account, and
its body does not carry the attribution marker (owner ruling 2026-08-24, no
bypass exists for this gate).

Add this line near the TOP of the comment body (line 2 of the body is the
ruled spot), as a markdown blockquote, then re-run the same command:

  > Generated via a 🤖 on @${GH_LOGIN} machine (_${pick}_)

The bracket phrase is picked at random per comment from the owner's fixed
list; use the one printed above for this comment. If the body comes from a
file, add the line to the file. Reads and non-comment gh commands are not
gated.
EOF
exit 2
