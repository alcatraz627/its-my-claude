#!/usr/bin/env bash
# guard-policy.sh — holds agents to the owner's allow/block policy for actions
# taken as the owner: GitHub, Slack, Linear, deploys, and heavy local models.
#
# The owner sets each policy with one click in the menu bar panel (pol.sh
# underneath). This hook maps a tool call to its policy key and applies the
# value: allow passes silently, block refuses with a message that says the
# owner switched it off (so the agent reports it instead of asking to approve),
# warn passes with a note. The same policy covers every route to the action:
# the gh CLI and the GitHub MCP, wrangler, the Vercel and Slack connectors.
#
# Runtime contract: PreToolUse on Bash and on the mcp__github__, Slack, Linear
# and Vercel connector tools. Reads the payload on stdin. Exit 0 = allow (maybe
# with additionalContext), exit 2 = block, reason on stderr. Read-only tools and
# commands never consult the policy. Fails open: no jq, no registry or an
# unreadable store means the policy has no opinion and the call proceeds.
#
# Commits and pushes are not here: guard-user-commit.sh and guard-git-push.sh
# read git.commit, git.push and git.push_main themselves, next to the checks
# they already own. The GitHub MCP's push tools are here because no git
# command runs for them.
#
# Known over-match (accepted, the same trade guard-user-commit makes): a Bash
# command that merely mentions "wrangler deploy" inside a quoted string is
# treated as a deploy. It only matters while that policy is block.
set -uo pipefail
command -v jq >/dev/null 2>&1 || exit 0
POL="${POL_SH:-$HOME/.claude/scripts/pol/pol.sh}"
[ -f "$POL" ] || exit 0

input=$(cat 2>/dev/null) || exit 0
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)

key=""; what=""

# ── MCP connectors: decide read versus write by the tool's verb ──────────────
verb_of() { printf '%s' "${1##*__}"; }
is_read_verb() {
  case "$1" in
    get_*|list_*|search_*|read_*|count_*|aggregate_*|query_*|extract_*|filter_*) return 0;;
  esac
  return 1
}

# ── Remote pushes: any route that moves a branch on GitHub without git ───────
# Is owner/repo the GitHub remote of a repo in protected-repos.list? Those repos
# need a per-push owner approval, which only `git push` (guard-git-push.sh) can
# collect, so every other route is refused there.
protected_remote() {
  local want list entry url
  want=$(printf '%s/%s' "$1" "$2" | tr 'A-Z' 'a-z'); want="${want%.git}"
  [ "$want" != "/" ] || return 1
  list="$HOME/.claude/protected-repos.list"
  [ -f "$list" ] || return 1
  while IFS= read -r entry; do
    entry="${entry%%#*}"; entry=$(printf '%s' "$entry" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
    [ -n "$entry" ] || continue
    case "$entry" in "~"/*) entry="$HOME/${entry#\~/}";; esac
    while IFS= read -r url; do
      url=$(printf '%s' "$url" | tr 'A-Z' 'a-z' | sed -E 's#^.*github\.com[:/]##; s#\.git$##')
      [ "$url" = "$want" ] && return 0
    done < <(git -C "$entry" remote -v 2>/dev/null | awk '{print $2}' | sort -u)
  done < "$list"
  return 1
}

# Sets key and what for a push of branch to owner/repo, or refuses it outright
# for a protected repo. An empty branch means the default branch: treated as main.
push_kind() { # owner repo branch via
  local b; b=$(printf '%s' "$3" | tr 'A-Z' 'a-z')
  if protected_remote "$1" "$2"; then
    printf '⛔ %s/%s is a protected repo: every push needs the owner'"'"'s fresh approval, which only `git push` from the local checkout can collect. This route (%s) has no approval step, so it is refused. Push with git instead.\n' "$1" "$2" "$4" >&2
    exit 2
  fi
  case "$b" in
    main|master|"") key="git.push_main"; what="a change to ${b:-the default branch} of $1/$2 through $4";;
    *) key="git.push"; what="a push to $b of $1/$2 through $4";;
  esac
}

case "$tool" in
  mcp__github__*)
    v=$(verb_of "$tool")
    if is_read_verb "$v"; then exit 0; fi
    case "$v" in
      add_issue_comment|create_pull_request_review) key="github.comment"; what="a GitHub comment";;
      push_files|create_or_update_file|delete_file|create_branch|update_pull_request_branch)
        o=$(printf '%s' "$input" | jq -r '.tool_input.owner // empty' 2>/dev/null)
        r=$(printf '%s' "$input" | jq -r '.tool_input.repo // empty' 2>/dev/null)
        b=$(printf '%s' "$input" | jq -r '.tool_input.branch // empty' 2>/dev/null)
        push_kind "$o" "$r" "$b" "the GitHub MCP";;
      *) key="github.write"; what="a GitHub write ($v)";;
    esac;;
  mcp__claude_ai_Slack__*|mcp__slack__*)
    # Slack tools carry a product prefix (slack_read_channel), so the verb follows it.
    v=$(verb_of "$tool"); v="${v#slack_}"
    is_read_verb "$v" && exit 0
    case "$v" in *_draft) exit 0;; esac
    key="slack.post"; what="a Slack action as you ($v)";;
  mcp__claude_ai_Linear__*|mcp__linear__*)
    v=$(verb_of "$tool")
    is_read_verb "$v" && exit 0
    key="linear.write"; what="a Linear write as you ($v)";;
  mcp__claude_ai_Vercel__*|mcp__vercel__*)
    v=$(verb_of "$tool")
    is_read_verb "$v" && exit 0
    case "$v" in status|web_fetch_vercel_url|artifact_query|search_vercel_documentation) exit 0;; esac
    key="deploy.vercel"; what="a Vercel change ($v)";;
  mcp__file-tools__http_request)
    # The sanctioned route for REST calls (credentialed curl writes are blocked
    # by block-curl-post-auth.sh), so a write to a service API meets the same
    # policy as its CLI and MCP.
    method=$(printf '%s' "$input" | jq -r '(.tool_input.method // "GET") | ascii_upcase' 2>/dev/null)
    case "$method" in GET|HEAD|OPTIONS) exit 0;; esac
    url=$(printf '%s' "$input" | jq -r '.tool_input.url // empty | ascii_downcase' 2>/dev/null)
    case "$url" in
      *api.github.com/*/comments*|*api.github.com/*/reviews*) key="github.comment"; what="a GitHub comment through the REST API";;
      *api.github.com/repos/*/*/git/refs*|*api.github.com/repos/*/*/contents/*)
        # Branch moves: a ref write names its branch in the path (or, for a new
        # ref, in the body); a contents write names it in the body or means the
        # default branch.
        rest="${url#*api.github.com/repos/}"; o="${rest%%/*}"; rest="${rest#*/}"; r="${rest%%/*}"
        body=$(printf '%s' "$input" | jq -c '.tool_input.body // {} | if type == "string" then (try fromjson catch {}) else . end' 2>/dev/null)
        case "$url" in
          */git/refs/heads/*) b="${url#*/git/refs/heads/}"; b="${b%%\?*}";;
          */git/refs*) b=$(printf '%s' "$body" | jq -r '.ref // empty' 2>/dev/null); b="${b#refs/heads/}";;
          *) b=$(printf '%s' "$body" | jq -r '.branch // empty' 2>/dev/null);;
        esac
        push_kind "$o" "$r" "$b" "the REST API";;
      *api.github.com/*) key="github.write"; what="a GitHub write through the REST API";;
      *slack.com/api/*) key="slack.post"; what="a Slack action as you through the API";;
      *api.linear.app/*)
        # GraphQL sends reads as POST too; only a mutation writes.
        printf '%s' "$input" | jq -r '.tool_input.body // "" | tostring' 2>/dev/null | grep -q 'mutation' || exit 0
        key="linear.write"; what="a Linear write through the API";;
      *api.vercel.com/*) key="deploy.vercel"; what="a Vercel change through the API";;
      *api.cloudflare.com/*) key="deploy.cloudflare"; what="a Cloudflare change through the API";;
      *) exit 0;;
    esac;;
  Bash)
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
    [ -n "$cmd" ] || exit 0
    # Most Bash calls name none of these tools; one in-process match on the
    # tool name as a whole word lets them leave before any grep runs.
    [[ "$cmd" =~ (^|[^[:alnum:]_-])(gh|wrangler|vercel|imagine|mflux-generate[a-z-]*|see|lm)([^[:alnum:]_-]|$) ]] || exit 0
    # Start of a command word. "/" is included so /opt/homebrew/bin/gh and
    # ./node_modules/.bin/wrangler are the same command as gh and wrangler.
    S='(^|[;&|(`[:space:]/])'
    GH="${S}gh[[:space:]]+"
    # gh api: the method is explicit (-X/--method) or implied. With no -X, any
    # field or input flag makes it a POST, exactly as gh itself decides.
    api_write=0; api_ep=""
    if printf '%s' "$cmd" | grep -qE "${GH}api([[:space:]]|$)"; then
      api_args=$(printf '%s' "$cmd" | sed -E 's/.*(^|[;&|(`[:space:]\/])gh[[:space:]]+api([[:space:]]|$)//')
      m=$(printf '%s' "$api_args" | grep -oE '(-X|--method)[[:space:]=]*[A-Za-z]+' | head -1 | grep -oE '[A-Za-z]+$' | tr 'a-z' 'A-Z')
      case "$m" in
        POST|PATCH|PUT|DELETE) api_write=1;;
        "") printf '%s' "$api_args" | grep -qE '(^|[[:space:]])(-f|-F|--field|--raw-field|--input)([[:space:]=]|$)' && api_write=1;;
      esac
      api_ep=$(printf '%s' "$api_args" | tr ' ' '\n' | grep -vE '^-|^$|=' | head -1 | tr -d "\"'" | sed -E 's#^/+##')
      # GraphQL sends reads as POST; only a mutation writes.
      if [ "$api_write" = 1 ] && [ "$api_ep" = "graphql" ] && ! printf '%s' "$cmd" | grep -q 'mutation'; then api_write=0; fi
    fi
    if printf '%s' "$cmd" | grep -qE "${GH}(pr|issue)[[:space:]]+comment|${GH}pr[[:space:]]+review"; then
      key="github.comment"; what="a GitHub comment"
    elif [ "$api_write" = 1 ] && printf '%s' "$api_ep" | grep -qE '(comments|reviews)'; then
      key="github.comment"; what="a GitHub comment"
    elif [ "$api_write" = 1 ] && printf '%s' "$api_ep" | grep -qE '^repos/[^/]+/[^/]+/(git/refs|contents/)'; then
      o=$(printf '%s' "$api_ep" | cut -d/ -f2); r=$(printf '%s' "$api_ep" | cut -d/ -f3)
      case "$api_ep" in
        */git/refs/heads/*) b="${api_ep#*/git/refs/heads/}";;
        */git/refs*) b=$(printf '%s' "$api_args" | grep -oE 'ref=[^[:space:]]+' | head -1 | sed -E 's/^ref=//; s#^refs/heads/##' | tr -d "\"'");;
        *) b=$(printf '%s' "$api_args" | grep -oE 'branch=[^[:space:]]+' | head -1 | sed -E 's/^branch=//' | tr -d "\"'");;
      esac
      push_kind "$o" "$r" "$b" "gh api"
    elif printf '%s' "$cmd" | grep -qE "${GH}(pr|issue)[[:space:]]+(create|edit|close|reopen|merge|ready|lock|unlock|delete|transfer|pin|unpin|develop)|${GH}repo[[:space:]]+(create|delete|edit|fork|rename|archive|unarchive)|${GH}release[[:space:]]+(create|delete|edit|upload)|${GH}label[[:space:]]+(create|edit|delete)"; then
      key="github.write"; what="a GitHub write"
    elif [ "$api_write" = 1 ]; then
      key="github.write"; what="a GitHub API write"
    elif printf '%s' "$cmd" | grep -qE "${S}wrangler[[:space:]]+(deploy|publish|rollback|delete|versions[[:space:]]+deploy|pages[[:space:]]+deploy|secret[[:space:]]+(put|delete|bulk)|kv[[:space:]:]+(key[[:space:]]+)?(put|delete)|kv[[:space:]]+bulk[[:space:]]+(put|delete)|kv:bulk[[:space:]]+(put|delete)|r2[[:space:]]+object[[:space:]]+(put|delete)|r2[[:space:]]+bucket[[:space:]]+(create|delete)|d1[[:space:]]+(execute|migrations[[:space:]]+apply|delete))"; then
      key="deploy.cloudflare"; what="a Cloudflare change through wrangler"
    elif printf '%s' "$cmd" | grep -qE "${S}vercel[[:space:]]+(deploy|--prod|promote|rollback|redeploy|remove|rm|alias[[:space:]]+(set|rm)|env[[:space:]]+(add|rm|update)|domains[[:space:]]+(add|rm|remove))|${S}vercel[[:space:]]*($|[;&|])"; then
      key="deploy.vercel"; what="a Vercel deploy or change"
    elif printf '%s' "$cmd" | grep -qE "${S}(imagine|mflux-generate[a-z-]*)([[:space:]]|$)|${S}lm[[:space:]]+(imagine|see)([[:space:]]|$)|${S}see[[:space:]]+[^|;&]*\.(png|jpe?g|webp|gif)|${S}lm[[:space:]]+q[[:space:]]+[^|;&]*(--big|-m[[:space:]]+big)"; then
      key="model.heavy_local"; what="a heavy local model"
    else
      exit 0
    fi;;
  *) exit 0;;
esac

[ -n "$key" ] || exit 0
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
val=$(bash "$POL" get "$key" --cwd "$cwd" 2>/dev/null) || exit 0

case "$key:$val" in
  git.push_main:ask)
    # The one-time approval flow lives in guard-git-push.sh for git pushes; an
    # MCP push has no nonce channel, so ask means the owner does it this once.
    printf '⛔ %s needs the owner'"'"'s fresh approval (policy git.push_main = ask), and the GitHub MCP has no approval channel. Push with git instead, where guard-git-push.sh runs the one-time approval, or ask the owner to set git.push_main to allow in the menu bar policy panel.\n' "$what" >&2
    exit 2;;
  *:ask)
    # One owner OK per call, through the same typed-line channel the push gate
    # uses: this blocks with a token, the owner types "approve <key> <token>",
    # policy-ask-prompt.sh writes a single-use approval, and the retried call
    # consumes it here. Per session and per key, so approvals never cross.
    sid_raw=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
    sid=$(printf '%s' "$sid_raw" | tr -c 'A-Za-z0-9._-' '_'); [ -n "$sid" ] || sid="nosession"
    ask_dir="$HOME/.claude/.policy-ask"
    mkdir -p "$ask_dir" 2>/dev/null
    base="$ask_dir/${sid}--${key}"
    if [ -f "$base.approved" ]; then
      rm -f "$base.approved" "$base.nonce"
      bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-policy --action ask-approved-used --heeded yes --detail "$key" >/dev/null 2>&1 || true
      exit 0
    fi
    nonce=$(jq -r '.nonce // empty' "$base.nonce" 2>/dev/null)
    if [ -z "$nonce" ]; then
      nonce=$(od -An -N4 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')
      [ -n "$nonce" ] || nonce=$(date +%s | tail -c 8)
      jq -cn --arg n "$nonce" --arg k "$key" --arg w "$what" --argjson ts "$(date +%s)" \
        '{nonce:$n, key:$k, what:$w, ts:$ts}' > "$base.nonce" 2>/dev/null || true
    fi
    printf '⛔ %s needs the owner'"'"'s OK first (policy %s = ask). Print this line to the owner, bare on its own line, then keep working on other things; do not call AskUserQuestion for it:\n     approve %s %s\nWhen a [policy-ask] line says it is approved, run the same call again. One approval covers one call. The owner can also type: deny %s\n' "$what" "$key" "$key" "$nonce" "$key" >&2
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-policy --action ask-blocked --heeded unknown --detail "$key" >/dev/null 2>&1 || true
    exit 2;;
  model.heavy_local:warn)
    msg="[policy · model.heavy_local = warn] RAM will be tight while $what runs, and other work on the machine may slow down. Run it anyway when the output quality justifies it: do not swap in a smaller model, split it into weaker calls, or skip a check to save memory. One strong model call beats a dozen weak ones."
    jq -cn --arg c "$msg" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $c}}'
    exit 0;;
  *:block)
    printf '⛔ The owner has switched off %s (policy %s = block). Do not ask the owner to approve it: tell them it is off, and that they can turn it on in the menu bar policy panel if they want it. Carry on with the rest of the work.\n' "$what" "$key" >&2
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-policy --action block --heeded unknown --detail "$key" >/dev/null 2>&1 || true
    exit 2;;
esac
exit 0
