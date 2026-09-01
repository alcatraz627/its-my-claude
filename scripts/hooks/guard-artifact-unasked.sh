#!/usr/bin/env bash
# guard-artifact-unasked.sh — an Artifact publish needs the owner to have asked
# for a hosted surface.
#
# Publishing sends user content to claude.ai, off this machine. Atone slug
# published-to-external-host-unasked is S3 three times, always the same shape:
# the owner asks for a plan or a report, the agent writes the file AND ALSO
# authors an HTML page and publishes it, unasked. One of those pages carried
# named customers and internal roadmap material.
#
# This blocks rather than warns, which features/hook-design.md reserves for high
# cost-of-miss, because both halves of its test are satisfied. The miss is
# irreversible: content that reached a host may be cached or indexed after
# deletion. And a floor exists, named by the owner's own precheck on the third
# event: write the file into the project and offer the page in one sentence. A
# blocked publish therefore costs a draft, never the deliverable.
#
# It reads the recent USER turns only. The owner's ask is the authorisation, so
# the agent cannot satisfy this gate by talking itself into it.
#
# Mute: touch ~/.claude/.no-artifact-gate (machine-wide until removed).
set -uo pipefail
[ -f "$HOME/.claude/.no-artifact-gate" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v rg >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null) || exit 0

# Only the publish path sends content anywhere. Reading, listing, watching, and
# the asset/comment verbs are not exfiltration and are never gated.
action=$(printf '%s' "$input" | jq -r '.tool_input.action // "publish"' 2>/dev/null)
case "$action" in
  publish|"") ;;
  *) exit 0 ;;
esac

# An update to a page the owner already has is not a new publish.
url=$(printf '%s' "$input" | jq -r '.tool_input.url // empty' 2>/dev/null)
[ -n "$url" ] && exit 0

tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$tp" ] && [ -f "$tp" ] || exit 0

# The owner's own words, last few turns. Their ask is the authorisation.
#
# type=="user" is NOT the owner: every tool_result rides back under the same
# type, by API convention. Measured on this machine's transcripts, tool_results
# outnumber real turns 605 to 37 in one file, and the last six type=="user"
# entries are routinely all tool output. Reading those means the gate answers
# from a grep result instead of a person, in both directions: an owner ask
# scrolls out of the window, and any tool output containing "page" or "link"
# satisfies it. So keep only entries whose content is a plain string, or an
# array carrying no tool_result block.
asks=$(tail -n 600 "$tp" 2>/dev/null | python3 -c '
import json, sys
turns = []
for line in sys.stdin:
    try: d = json.loads(line)
    except Exception: continue
    if d.get("type") != "user": continue
    c = d.get("message", {}).get("content")
    if isinstance(c, str):
        turns.append(c)
    elif isinstance(c, list):
        if any(isinstance(b, dict) and b.get("type") == "tool_result" for b in c):
            continue
        turns.append(" ".join(b.get("text", "") for b in c if isinstance(b, dict)))
print(" ".join(turns[-6:]))' 2>/dev/null || true)
[ -n "$asks" ] || exit 0

# Generous on purpose: a false block costs a round trip, and the owner phrases
# this many ways. Any of these in a recent turn means they asked.
if printf '%s' "$asks" | rg -qi \
  'artifact|publish|hosted|host it|shareable|share it|a page|web page|webpage|link me|send me a link|site|dashboard|deck|slides|claude\.ai|browser' \
  2>/dev/null; then
  exit 0
fi

reason="artifact-unasked: publishing sends this content to claude.ai, off this machine, and nothing in the owner's recent turns asked for a hosted or shareable surface. Atone published-to-external-host-unasked is S3 x3, one of them shipping named customers to a host. Do this instead: write the file into the project, hand over its absolute path, and offer the page in one sentence. If they did ask and this missed it, say so and retry. Mute: touch ~/.claude/.no-artifact-gate"

jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
exit 0
