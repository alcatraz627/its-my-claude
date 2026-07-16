#!/usr/bin/env bash
# thesaurus.sh — CLI for the style thesaurus: the user's accumulated verdicts on
# how Claude writes (word choice, comments, prose, report structure). One JSONL
# entry per verdict; consumers (critic persona, watcher) read the capped derived
# digests, never this raw ledger, so accumulation can't drown a model's context.
#
# Usage:
#   thesaurus.sh add --pattern "<what to catch>" --verdict ban|prefer|rewrite-to
#                    [--class vocab|comment|prose|structure] [--rewrite "<to>"]
#                    [--example "<sample>"] [--scope all|report|docs|comment|chat]
#                    [--source user|critic|watcher|canon] [--status active|candidate]
#   thesaurus.sh list [--status S] [--class C]
#   thesaurus.sh digest            regenerate style/derived/<class>.md (capped)
#   thesaurus.sh hit <id>          count an enforcement (critic/watcher telemetry)
#   thesaurus.sh review            weekly triage: hits, candidates, prune hints
#
# Rules encoded here (not just documented):
#   - non-user sources are FORCED to status=candidate — agents propose, the
#     weekly review promotes; taste enters the active set only via the human.
#   - digest caps at $DIGEST_CAP entries per class, hits desc then newest first.
set -uo pipefail

STYLE_DIR="${STYLE_DIR:-$HOME/.claude/style}"
LEDGER="$STYLE_DIR/thesaurus.jsonl"
DERIVED="$STYLE_DIR/derived"
DIGEST_CAP="${DIGEST_CAP:-40}"

command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; exit 1; }
mkdir -p "$STYLE_DIR" "$DERIVED"

cmd="${1:-}"; shift || true

case "$cmd" in
  add)
    class="prose"; scope="all"; source="user"; status="active"
    pattern=""; verdict=""; rewrite=""; example=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --class)   class="$2"; shift 2 ;;
        --pattern) pattern="$2"; shift 2 ;;
        --verdict) verdict="$2"; shift 2 ;;
        --rewrite) rewrite="$2"; shift 2 ;;
        --example) example="$2"; shift 2 ;;
        --scope)   scope="$2"; shift 2 ;;
        --source)  source="$2"; shift 2 ;;
        --status)  status="$2"; shift 2 ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
      esac
    done
    [ -n "$pattern" ] && [ -n "$verdict" ] || { echo "add needs --pattern and --verdict" >&2; exit 2; }
    case "$class" in vocab|comment|prose|structure) ;; *) echo "bad --class" >&2; exit 2 ;; esac
    case "$verdict" in ban|prefer|rewrite-to) ;; *) echo "bad --verdict" >&2; exit 2 ;; esac
    # Agents never write straight into the active set.
    [ "$source" != "user" ] && [ "$source" != "canon" ] && status="candidate"
    id="thes-$(date +%Y%m%d-%H%M%S)-$(printf '%02x' $((RANDOM % 256)))"
    jq -cn --arg id "$id" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg class "$class" --arg scope "$scope" --arg pattern "$pattern" \
      --arg verdict "$verdict" --arg rewrite "$rewrite" --arg example "$example" \
      --arg source "$source" --arg status "$status" \
      '{id:$id, ts:$ts, class:$class, scope:$scope, pattern:$pattern,
        verdict:$verdict, rewrite:$rewrite, example:$example,
        source:$source, status:$status, hits:0}' >> "$LEDGER"
    echo "added $id ($class/$scope, $verdict, status=$status)"
    ;;

  list)
    fstatus=""; fclass=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --status) fstatus="$2"; shift 2 ;;
        --class)  fclass="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    [ -f "$LEDGER" ] || exit 0
    jq -r --arg fs "$fstatus" --arg fc "$fclass" \
      'select(($fs=="" or .status==$fs) and ($fc=="" or .class==$fc))
       | "\(.id)  \(.status)/\(.class)/\(.scope)  hits:\(.hits)  \(.verdict): \(.pattern)"' "$LEDGER"
    ;;

  digest)
    [ -f "$LEDGER" ] || { echo "no ledger yet" >&2; exit 0; }
    for class in vocab comment prose structure; do
      out="$DERIVED/$class.md"
      body=$(jq -rs --arg c "$class" --argjson cap "$DIGEST_CAP" '
        map(select(.class==$c and .status=="active"))
        | sort_by([-.hits, .ts]) | reverse | sort_by(-.hits)
        | .[:$cap]
        | map("- [\(.id)] \(.verdict): \(.pattern)"
              + (if .rewrite != "" then " → \(.rewrite)" else "" end)
              + " (scope: \(.scope))")
        | join("\n")' "$LEDGER")
      if [ -n "$body" ]; then
        {
          echo "# thesaurus digest — $class (cap $DIGEST_CAP, active only)"
          echo ""
          echo "$body"
          echo ""
          echo "_Derived from style/thesaurus.jsonl — regen: thesaurus.sh digest. Do not hand-edit._"
        } > "$out"
        echo "wrote $out ($(printf '%s\n' "$body" | wc -l | tr -d ' ') entries)"
      else
        rm -f "$out" 2>/dev/null || true
      fi
    done
    ;;

  hit)
    id="${1:-}"; [ -n "$id" ] || { echo "hit needs an id" >&2; exit 2; }
    [ -f "$LEDGER" ] || exit 0
    bash "$HOME/.claude/skills/shared/lock-file.sh" acquire "$LEDGER" "thesaurus-hit" >/dev/null 2>&1 || true
    tmp=$(mktemp)
    jq -c --arg id "$id" 'if .id==$id then .hits += 1 else . end' "$LEDGER" > "$tmp" && mv -f "$tmp" "$LEDGER"
    bash "$HOME/.claude/skills/shared/lock-file.sh" release "$LEDGER" "thesaurus-hit" >/dev/null 2>&1 || true
    ;;

  review)
    [ -f "$LEDGER" ] || { echo "no ledger yet"; exit 0; }
    echo "== thesaurus weekly review =="
    echo "-- counts --"
    jq -rs 'group_by(.status)[] | "\(.[0].status): \(length)"' "$LEDGER"
    echo "-- top enforced (keep) --"
    jq -rs 'map(select(.status=="active")) | sort_by(-.hits) | .[:5][]
            | "\(.hits)x  \(.id)  \(.pattern)"' "$LEDGER"
    echo "-- zero-hit active >30d (prune?) --"
    cutoff=$(date -u -v-30d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '30 days ago' +%Y-%m-%dT%H:%M:%SZ)
    jq -rs --arg cut "$cutoff" 'map(select(.status=="active" and .hits==0 and .ts < $cut))[]
            | "\(.id)  \(.pattern)"' "$LEDGER"
    echo "-- candidates awaiting your verdict (promote: edit status→active; reject: →pruned) --"
    jq -rs 'map(select(.status=="candidate"))[] | "\(.id)  [\(.source)] \(.verdict): \(.pattern)"' "$LEDGER"
    ;;

  *)
    sed -n '2,20p' "$0"
    exit 2
    ;;
esac
