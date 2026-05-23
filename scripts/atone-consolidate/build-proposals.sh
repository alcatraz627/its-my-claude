#!/usr/bin/env bash
# Auto-extracted from atone-consolidate.sh by the split refactor (2026-05-15).
# This file is intended to be sourced (not executed) by atone-consolidate.sh.
# Functions defined here rely on env vars + helpers from atone-common.sh
# and atone-consolidate/helpers.sh.

build_proposals() {
  # Build the "already proposed" exclusion set
  local skip_slugs
  skip_slugs=$(already_proposed_slugs)

  local drafted=0
  local report_lines=""

  # Process atone (mistakes) only — affirm doesn't need prevention proposals
  while IFS=$'\t' read -r src slug cnt sev_str ts cluster title latest_id; do
    [ -z "$slug" ] && continue

    # Skip if already proposed
    if echo "$skip_slugs" | grep -qFx "$slug"; then
      continue
    fi

    # Qualifying conditions: count >= 3 OR severity S3
    if [ "$cnt" -lt 3 ] && [ "$sev_str" != "S3" ]; then
      continue
    fi

    # Pull tags + project + precheck from the latest event for this slug
    local latest_event
    latest_event=$(jq -c --arg slug "$slug" '
      [.] as $rest | first(.[]? | select(.slug == $slug))
    ' < <(jq -c --arg slug "$slug" 'select(.slug == $slug)' "${EVENTS_VIEW:-$EVENTS}" 2>/dev/null | tail -1))

    local tags_json project precheck
    tags_json=$(echo "$latest_event" | jq -c '.tags // []')
    project=$(echo "$latest_event" | jq -r '.project // ""')
    precheck=$(echo "$latest_event" | jq -r '.precheck // ""')

    # Decide target
    local target
    target=$(route_target "$slug" "$sev_str" "$cnt" "$cluster" "$tags_json" "$project")

    # Build proposal body based on target
    local prop_title prop_body
    case "$target" in
      hook-draft)
        prop_title="[atone] hook proposal: $slug"
        prop_body="$(cat <<EOF
Auto-drafted from atone pattern (slug: $slug, severity: $sev_str, recurrences: $cnt).

**Mechanical signature:** likely matchable on a Bash command pattern or Edit/Write file_path.

**Proposed hook**: PreToolUse on Bash (and possibly Edit/Write).

**Detection regex (suggested — verify and refine):**
\`\`\`
$(echo "$slug" | tr '-' '|')
\`\`\`

**Injection / block message:**
${precheck:-(precheck field empty — review the latest event for actionable text)}

**Source events:** \`atone.sh search $slug\`
**Latest event:** $latest_id
EOF
)"
        ;;
      skill-enhancement)
        prop_title="[atone] skill enhancement: $slug"
        prop_body="$(cat <<EOF
Auto-drafted from atone pattern (slug: $slug, severity: $sev_str, recurrences: $cnt).

**Suggested target:** a domain-relevant skill (route-audit, type-audit, or similar). Pick by tag overlap:
$(echo "$tags_json" | jq -r 'join(", ")')

**Behavior to add to the skills pre-action checks:**
${precheck:-(precheck empty — derive from \`atone.sh show $latest_id\`)}

**Source events:** \`atone.sh search $slug\`
EOF
)"
        ;;
      project-claude-md)
        prop_title="[atone] project CLAUDE.md addition: $slug"
        prop_body="$(cat <<EOF
Auto-drafted from atone pattern (slug: $slug, severity: $sev_str, recurrences: $cnt).

**Suggested target:** ${project}/.claude/CLAUDE.md (project-level rules section).

**Content to add:**
${precheck:-(precheck empty — derive from \`atone.sh show $latest_id\`)}

**Source events:** \`atone.sh search $slug\`
EOF
)"
        ;;
      claude-md-rule)
        prop_title="[atone] CLAUDE.md Tier-0 rule: $slug"
        prop_body="$(cat <<EOF
Auto-drafted from atone pattern (slug: $slug, severity: $sev_str, recurrences: $cnt).

**Suggested placement:** ~/.claude/CLAUDE.md Tier-0 (always-load).

**Proposed rule (≤3 sentences):**
${precheck:-${title:-(no rule text yet — review and write)}}

**Source events:** \`atone.sh search $slug\`
EOF
)"
        ;;
      rules-entry)
        prop_title="[atone] rules/$slug.md entry"
        prop_body="$(cat <<EOF
Auto-drafted from atone pattern (slug: $slug, severity: $sev_str, recurrences: $cnt).

**Suggested target:** ~/.claude/rules/$slug.md (or merge into an existing rules file).

**Body (expand from precheck/what-not-to-do):**
${precheck:-(precheck empty — read latest event for context)}

**Source events:** \`atone.sh search $slug\`
EOF
)"
        ;;
    esac

    # File the proposal via propose.sh
    bash "$HOME/.claude/scripts/propose.sh" add \
      --title "$prop_title" \
      --body "$prop_body" \
      --category "hooks" \
      --effort "small" \
      --tags "atone-prevention $target $slug" \
      --session "atone-consolidate" \
      >/dev/null 2>&1

    drafted=$((drafted + 1))
    report_lines="${report_lines}  • [$target] $slug ($sev_str, ${cnt}x)\n"

  done < <(aggregate_slugs atone "${EVENTS_VIEW:-$EVENTS}")

  # Annotate proposals.jsonl entries that came from atone with .type = atone-prevention
  # propose.sh's category was "hooks" — that's its native field. We re-mark via
  # appending a marker line. Actually: propose.sh tracks the type internally;
  # we use tags to find them later (tag "atone-prevention" is set).

  if [ $drafted -gt 0 ]; then
    _ok "drafted $drafted prevention proposal(s) to proposals.jsonl"
    printf '%b' "$report_lines"
  else
    _info "no new prevention proposals (qualifying slugs already proposed or none qualifying)"
  fi
}

