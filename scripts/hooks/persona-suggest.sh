#!/usr/bin/env bash
# Suggests adopting a matching persona when the prompt clearly calls for one.
#
# Working-mode personas (~/.claude/personas/) are picked up only when the agent
# reads the file — there is no proactive trigger. This UserPromptSubmit hook is
# that trigger: it matches the prompt against a curated set of strong cues and,
# on a clear hit, injects one advisory line pointing at the relevant persona.
# Conservative by design — it fires only on unambiguous cues, at most once per
# persona per session, so it primes rather than nags.
#
# Runtime contract: UserPromptSubmit hook. Reads {session_id, prompt, ...} on
# stdin; prints one {additionalContext} JSON object on a match, nothing
# otherwise. Dedup sentinel: /tmp/claude-personasuggest-<sid8> (one line per
# already-suggested persona). Mute: touch ~/.claude/personas/usage/.suggest-off.
# Always exits 0 — an advisory hook must never block a prompt.

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
[[ -f "$HOME/.claude/personas/usage/.suggest-off" ]] && exit 0
input=$(cat 2>/dev/null) || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' | tr '[:upper:]' '[:lower:]')
[[ -z "$sid" || -z "$prompt" ]] && exit 0

SENT="/tmp/claude-personasuggest-${sid:0:8}"
already() { [[ -f "$SENT" ]] && grep -qx "$1" "$SENT"; }
mark()    { echo "$1" >> "$SENT"; }

# Curated strong cues → (persona, advisory). First match wins; one suggestion per
# prompt. Order = priority. grep -Eq, case-insensitive (prompt already lowercased).
m() { printf '%s' "$prompt" | grep -Eq "$1"; }

persona="" ; msg=""
if   m 'should (i|we) build|what should (i|we) (do next|build)|prioriti|worth building|trim the (scope|backlog)'; then
  persona="strategic-triad"
  msg="This is a scope/prioritization call — consider the strategic triad (closer / platform-builder / pragmatist) or /magi, not a single answer."
elif m '\b(review|audit) (my|the|this) (code|change|changes|diff|pr|branch)|is this (right|correct|safe)|check my work|skeptical'; then
  persona="skeptical-reviewer"
  msg="This looks like a code review — run /skeptical-review (it dispatches the skeptical-reviewer persona: coverage-first, grounded findings)."
elif m '\b(plan|decompose|sequence|break (this|it) down)\b|how should (i|we) approach|roadmap'; then
  persona="task-goal-planner"
  msg="This is a planning/decomposition task — consider adopting ~/.claude/personas/task-goal-planner.md (bounded plan that seeds the Task tool)."
elif m 'write (the )?docs?|document (this|the)|technical doc|\badr\b|architecture doc|data-pattern doc'; then
  persona="technical-doc-writer"
  msg="This is doc authoring — consider ~/.claude/personas/technical-doc-writer.md (Diátaxis + ground-in-code + route the voice pass)."
elif m 'research|look (it|this) up|find out (about|whether)|compare .*(options|tools|libraries|vendors)|state of the|sources for'; then
  persona="web-researcher"
  msg="This is web research — consider ~/.claude/personas/web-researcher.md (cite-everything, ≥2 sources) or /deep-research for a heavy deliverable."
elif m 'make an? image|generate (art|an image|a picture)|art[- ]direct|design (a|the|my) (logo|poster|visual|cover)'; then
  persona="art-director"
  msg="This is image generation — consider ~/.claude/personas/art-director.md (guided brief → generate→critique→refine)."
fi

[[ -z "$persona" ]] && exit 0
already "$persona" && exit 0
mark "$persona"
jq -nc --arg m "[persona] ${msg} (Advisory; once per session. Mute: touch ~/.claude/personas/usage/.suggest-off)" \
  '{additionalContext:$m}'
exit 0
