#!/usr/bin/env bash
# guard-anthropic-credentials.sh — PreToolUse hard-stop on ANY attempt to SET
# the Anthropic API key or a global-blast-radius credential.
#
# Why a hard block: a bad/changed key crashes EVERY Claude instance at once, and
# the agent that did it dies with them — only the human can recover. So the
# correct action is always "ask the user." (Incident 2026-05-24.)
#
# Distinguishes SETTING (blocked) from MENTIONING (allowed) — a grep/regex/echo
# that merely contains "ANTHROPIC_API_KEY" (e.g. the secret-scan guards) passes.
#
# Mute (almost never): touch ~/.claude/.allow-cred-write

set -uo pipefail
[ -f "$HOME/.claude/.allow-cred-write" ] && exit 0

input=$(cat 2>/dev/null)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)

CRED='(ANTHROPIC_API_KEY|ANTHROPIC_AUTH_TOKEN|CLAUDE_API_KEY|ANTHROPIC_BASE_URL)'

block() {
  jq -cn --arg r "🛑 CREDENTIAL GUARD — refusing to modify the Anthropic key / global credential.

$1

A bad value crashes EVERY Claude instance at once and the agent that set it dies with them — only YOU can recover it. Do NOT do this. Instead, hand the exact command to the user and ask them to run it themselves, then continue.
(rules/never-modify-anthropic-credentials.md · override: touch ~/.claude/.allow-cred-write)" \
    '{decision:"block", reason:$r}' 2>/dev/null || true
  exit 0
}

case "$tool" in
  Bash)
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
    [ -n "$cmd" ] || exit 0
    # SET patterns (command-position assignment / export / config / keychain / system env).
    # Use word-ish boundaries; these match an ASSIGNMENT, not a mention in a string.
    if printf '%s' "$cmd" | rg -q "(^|[;&|]|export[[:space:]]+)$CRED[[:space:]]*=" \
       || printf '%s' "$cmd" | rg -q "launchctl[[:space:]]+setenv[[:space:]]+$CRED" \
       || printf '%s' "$cmd" | rg -q "setx[[:space:]]+$CRED" \
       || printf '%s' "$cmd" | rg -qi "claude[[:space:]]+config[[:space:]]+set.*(api.?key|auth.?token|apiKey)" \
       || printf '%s' "$cmd" | rg -qi "security[[:space:]]+add-generic-password.*anthropic" \
       || printf '%s' "$cmd" | rg -q "(>|>>|tee)[[:space:]]*[^|]*\.claude\.json"; then
      block "Blocked command: $cmd"
    fi
    # redirect that writes a cred assignment into a shell profile
    if printf '%s' "$cmd" | rg -q "$CRED[[:space:]]*=" \
       && printf '%s' "$cmd" | rg -q "(>|>>|tee).*(\.zshenv|\.zshrc|\.zprofile|\.zenv|\.bashrc|\.profile)"; then
      block "Blocked: writing an Anthropic credential into a shell profile: $cmd"
    fi
    exit 0
    ;;
  Edit|Write|MultiEdit)
    fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
    content=$(printf '%s' "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null)
    case "$fp" in
      *.claude.json|*/.claude.json)
        block "Blocked: editing $fp (Claude auth/account file). Auth changes are yours to make." ;;
    esac
    # editing a shell profile / settings.json to ADD a cred assignment
    case "$fp" in
      *.zshenv|*.zshrc|*.zprofile|*.zenv|*.bashrc|*.profile|*/settings.json)
        if printf '%s' "$content" | rg -q "$CRED[[:space:]]*[:=]"; then
          block "Blocked: adding an Anthropic credential to $fp."
        fi ;;
    esac
    exit 0
    ;;
  *) exit 0 ;;
esac
