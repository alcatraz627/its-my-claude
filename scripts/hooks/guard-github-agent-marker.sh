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
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
case "$tool" in
  # The GitHub MCP posts the same comments without any gh command, so its
  # comment tools are checked on their body fields instead of a command line.
  mcp__github__add_issue_comment|mcp__github__create_pull_request_review)
    cmd=$(printf '%s' "$input" | jq -r '[.tool_input.body // empty, (.tool_input.comments // [])[].body // empty] | join("\n")' 2>/dev/null)
    ;;
  mcp__*) exit 0 ;;
  *) cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) ;;
esac
[ -n "$cmd" ] || { case "$tool" in mcp__*) ;; *) exit 0 ;; esac; }

# Posting surfaces only. Reads (gh pr view, gh api GET) pass untouched, and so
# does everything that is not a comment/review write.
posts=0
case "$tool" in mcp__github__*) posts=1 ;; esac
if printf '%s' "$cmd" | grep -qE 'gh (pr|issue) comment'; then posts=1; fi
# PR and issue bodies read as the owner too (a body-less `gh pr edit --title` is not gated).
if printf '%s' "$cmd" | grep -qE 'gh (pr|issue) (create|edit)' \
   && printf '%s' "$cmd" | grep -qE -- '(--body|--body-file|(^| )-b |(^| )-F )'; then posts=1; fi
if printf '%s' "$cmd" | grep -qE 'gh api' \
   && printf '%s' "$cmd" | grep -qE '(comments|reviews)' \
   && printf '%s' "$cmd" | grep -qE '(-X|--method) *(POST|PATCH|PUT)|-F +body|-f +body|--field +body|--raw-field +body'; then posts=1; fi
[ "$posts" = "1" ] || exit 0

# Body text = the inline command plus every readable file it names as a body source.
body="$cmd"
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
# --body-file X, --body-file=X, -F X (gh pr/issue create), -F body=@X, --field body=@X
files=$(printf '%s' "$cmd" | grep -oE -- '(--body-file[= ]+[^ ]+|body=@[^ ]+|(^| )-F [^ =]+( |$))' \
        | sed -E 's/--body-file[= ]+//; s/body=@//; s/^ ?-F //' | tr -d '"'"'" )
for f in $files; do
  p="$f"
  case "$p" in /*) ;; *) p="${cwd:-.}/$f" ;; esac
  [ -f "$p" ] && body="$body
$(cat "$p")"
done

# The marker must be there AND its phrase must be one of the owner's, verbatim.
# An invented phrase is the defect this check exists for (2026-10-09, PRs #337-#340).
problem="missing"
marker_line=$(printf '%s\n' "$body" | grep -F "$MARKER_HEAD" | head -1)
if [ -n "$marker_line" ]; then
  used=$(printf '%s' "$marker_line" | sed -nE 's/.*machine \(_(.*)_\).*/\1/p')
  problem="phrase"
  for ph in "${PHRASES[@]}"; do
    [ "$used" = "$ph" ] && { problem=""; break; }
  done
fi
[ -z "$problem" ] && exit 0

pick=${PHRASES[$((RANDOM % ${#PHRASES[@]}))]}
GH_LOGIN=$(gh api user --jq .login 2>/dev/null || echo "the-logged-in-gh-user")
if [ "$problem" = "phrase" ]; then
  echo "⛔ AGENT MARKER PHRASE NOT THE OWNER'S — the marker's phrase \"${used}\" is not on the owner's fixed list. Do not write your own; replace the whole marker line with the one below." >&2
fi
cat >&2 <<EOF
⛔ AGENT MARKER MISSING OR WRONG — this posts to GitHub under the owner's account,
and its body must carry the attribution marker (owner ruling 2026-08-24, no
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
