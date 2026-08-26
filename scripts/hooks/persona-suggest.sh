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
  msg="This is a planning/decomposition task: run /router:pick-skill, which routes to /plan and can seat the task-goal-planner persona (persona.sh seat, logged)."
elif m 'write (the )?docs?|document (this|the)|technical doc|\badr\b|architecture doc|data-pattern doc'; then
  persona="technical-doc-writer"
  msg="This is doc authoring: run /router:pick-skill, which routes to /write-docs and seats technical-doc-writer (persona.sh seat, logged)."
elif m 'research|look (it|this) up|find out (about|whether)|compare .*(options|tools|libraries|vendors)|state of the|sources for'; then
  persona="web-researcher"
  msg="This is web research: run /router:pick-skill, which routes to /deep-research or seats web-researcher (cite everything, 2+ sources)."
elif m 'make an? image|generate (art|an image|a picture)|art[- ]direct|design (a|the|my) (logo|poster|visual|cover)'; then
  persona="art-director"
  msg="This is image generation: run /router:pick-skill, which routes to /generate-image and seats art-director."
fi

[[ -z "$persona" ]] && exit 0
already "$persona" && exit 0
mark "$persona"
jq -nc --arg m "[persona] ${msg} (Advisory; once per session. Mute: touch ~/.claude/personas/usage/.suggest-off)" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$m}}'
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook persona-suggest --action nudge --heeded unknown >/dev/null 2>&1 || true

# Arm the heed check. This hook suggests in the hook channel and is answered in
# personas/usage/events.jsonl, a ledger it never reads, so it accumulated 1381
# fires and zero heed lines. That absence was then read as "it never converts" —
# a conclusion drawn from missing instrumentation rather than from data, which is
# why task #31 says to instrument BEFORE tuning. heed-writeback.sh re-reads the
# usage log at each Stop and records the answer. One suggestion per session, so
# the marker is armed at most once and names the persona actually suggested.
bash "$HOME/.claude/scripts/hooks/heed-writeback.sh" arm \
  persona-suggest persona-adopted "$persona" "$sid" >/dev/null 2>&1 || true
exit 0
