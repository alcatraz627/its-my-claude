#!/usr/bin/env bash
#
# ==========================================================================
#  STATUS: NOT FIT FOR PURPOSE. DISABLED. DO NOT RELY ON THIS.
#
#  A skeptical review on 2026-08-14 ran a 53-case suite and found 36
#  mismatches; an independent 14-case re-check let 13 through. Confirmed
#  bypasses include `bash -lc "<rm>"`, `sh -c`, `eval`, subshells, command
#  substitution, `find -delete`, `: > file`, `git clean -fdx`,
#  `git checkout -- .`, `git branch -D`, git and rm by absolute path, and
#  `gh repo delete`.
#
#  The first of those is fatal in practice: Codex shells out through
#  `<shell> -lc '<cmd>'`, which is precisely the wrapped form that passes.
#
#  Root cause is architectural, not a patchable regex bug. Matching regexes
#  against raw shell text cannot gate a shell: quoting, indirection
#  (`R=rm; $R -rf x`), and interpreter nesting each defeat it, and each
#  patch adds a false-positive surface (`npm rm`, `docker rm`, and
#  `git log --grep commit` were all denied by the version under review).
#
#  Real enforcement for Codex is the SANDBOX (`--sandbox read-only` for
#  analysis, `workspace-write` for edits, never the bypass flags), which is
#  OS-enforced rather than text-matched. The prose imperatives in
#  ../preamble.md are the behavioural layer, and in the one live test they
#  worked: told to rm a file, Codex refused and moved it aside instead.
#
#  Kept only as the worked example behind that conclusion. Registration is
#  disabled in $CODEX_HOME/hooks.json. Full findings:
#  ~/.claude/assets/reports/20260814-2145-skeptical-review/review.md
# ==========================================================================
#
# Original intent below. It also fails open when python3 is missing, since
# deny() pipes through it and a failed interpreter yields empty stdout plus
# exit 0, which is how this event signals allow. Exit 2 with a reason on
# stderr is the deny channel that needs no interpreter.
#
# This is deliberately NOT a port of the owner's 40 PreToolUse hooks. Almost all
# of those tune a teammate (prefer rg over grep, comment hygiene, prose quality),
# and a contractor's output gets reviewed anyway. These three are different: they
# are the ones where review happens after the damage.
#
# Contract (Codex 0.147, read off the binary's embedded JSON schema AND its
# runtime validation strings, which disagree with each other):
#   stdin  {"tool_name": "...", "tool_input": {...}, "session_id": "...", ...}
#   stdout {"hookSpecificOutput": {"hookEventName": "PreToolUse",
#                                  "permissionDecision": "deny",
#                                  "permissionDecisionReason": "<non-empty>"}}
#
# The schema advertises an allow|deny|ask enum, but the runtime rejects two of
# the three: "PreToolUse hook returned unsupported permissionDecision:allow" and
# ":ask" are both error strings in the binary, as is returning deny with an empty
# reason. So deny is the ONLY decision this event accepts, every deny must carry
# a reason, and the pass path emits nothing at all rather than a decision the
# runtime would reject.
#
# Exit 0 always. A non-zero exit is a hook failure, not a deny.
set -uo pipefail

# Silence is consent here: emitting no decision is how a PreToolUse hook passes.
allow() { exit 0; }

deny() {
  python3 - "$1" <<'PY'
import json, sys
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": sys.argv[1],
}}))
PY
  exit 0
}

payload=$(cat) || allow

# Pull the command out of tool_input. Codex names the shell tool differently
# across versions, so match on the presence of a command string rather than on a
# tool name allowlist: a renamed tool would silently bypass a name check.
cmd=$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = d.get("tool_input") or {}
v = ti.get("command") or ti.get("cmd") or ti.get("script") or ""
if isinstance(v, list):
    v = " ".join(str(x) for x in v)
sys.stdout.write(str(v))
' 2>/dev/null) || allow

[ -n "$cmd" ] || allow

# rm in any form. Covers \rm, /bin/rm, env rm, and sudo rm; does not fire on
# substrings of other words (rmdir is a separate call, npm's "rm" is scoped by
# the word boundary on both sides).
if printf '%s' "$cmd" | grep -Eq '(^|[;&|]|[[:space:]])\\?(/[a-z/]*/)?rm([[:space:]]|$)'; then
  deny "Blocked: rm. This owner never deletes; move the file aside instead (trash <path>, or mv to a scratch dir) and say in your handback exactly where you put it."
fi

# git subcommands that touch history or a remote. The working tree is fair game;
# these are not.
#
# Match any token between `git` and the verb rather than only flags: `git -C /repo
# rebase` puts a bare value there, and a flags-only pattern lets it straight
# through. [^;&|]* stops at a shell separator so a later pipeline stage cannot be
# mistaken for a git argument.
if printf '%s' "$cmd" | grep -Eq '(^|[;&|]|[[:space:]])git[^;&|]*[[:space:]](commit|push|rebase|cherry-pick|reset|revert)([[:space:]]|$)'; then
  deny "Blocked: git history/remote mutation. Most of this owner's repos are human-gated by policy. Prepare the change, leave it unstaged, and describe it in _codex-handback.claude.md. The owner runs git themselves."
fi

if printf '%s' "$cmd" | grep -Eq '(^|[;&|]|[[:space:]])gh[[:space:]]+(pr|release)[[:space:]]+(create|merge|close)'; then
  deny "Blocked: gh writes are visible to collaborators. Draft the content into a file and hand it back instead."
fi

allow
