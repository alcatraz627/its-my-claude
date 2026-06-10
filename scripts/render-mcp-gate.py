#!/usr/bin/env python3
"""PreToolUse gate for Render MCP WRITE-grade tools (GLOBAL — loads every session).

Every Render write to ANY env (dev / staging / prod) requires explicit per-call
human approval. `query_render_postgres` (arbitrary SQL, can read prod PII) and
`select_workspace` (state change) are treated as write-grade too. Read-only tools
(list_*/get_*/logs/deploys/metrics) pass.

Registered globally under matcher `mcp__render__.*` (fires on ALL render tools);
this script decides read vs write, so there is no dependency on matcher-regex
alternation support. exit 2 blocks the call even under
--dangerously-skip-permissions — the only unskippable mechanism.

Flow:
  no nonce -> exit 2 with the exact nonce path + target ENV (so the agent's
              AskUserQuestion can state which env it's approving).
  fresh nonce -> exit 0 (allow once), nonce consumed.
Fail-closed: any parse problem on a gated tool blocks.

stdin: the PreToolUse JSON payload ({tool_name, tool_input, cwd, ...}).
"""
import sys
import os
import json
import hashlib
import time

GATED_PREFIXES = ("mcp__render__create_", "mcp__render__update_")
GATED_EXACT = {"mcp__render__query_render_postgres", "mcp__render__select_workspace"}
NONCE_TTL_SEC = 300


def _strings(obj):
    if isinstance(obj, str):
        yield obj
    elif isinstance(obj, dict):
        for v in obj.values():
            yield from _strings(v)
    elif isinstance(obj, list):
        for v in obj:
            yield from _strings(v)


def _block(msg):
    sys.stderr.write(msg)
    sys.exit(2)


def _load_map(cwd):
    # cwd may be the repo root OR a subdir; the resource map can live in either
    # the cwd's .claude or a frontend/.claude (this project's layout). Search both.
    for cand in (
        os.path.join(cwd, ".claude", "render-resource-map.json"),
        os.path.join(cwd, "frontend", ".claude", "render-resource-map.json"),
    ):
        try:
            with open(cand) as f:
                m = json.load(f).get("resources", {})
            if m:
                return m
        except Exception:
            continue
    return {}


def main():
    raw = sys.stdin.read()
    try:
        data = json.loads(raw)
    except Exception:
        _block("RENDER WRITE GATE: unparseable hook payload on a gated tool - blocked for safety.\n")

    tool = data.get("tool_name", "") or ""
    if not (tool.startswith(GATED_PREFIXES) or tool in GATED_EXACT):
        sys.exit(0)  # a read tool (list_*/get_*/logs/...) — allow

    tinput = data.get("tool_input", {})
    cwd = data.get("cwd", ".") or "."
    mapping = _load_map(cwd)

    env = "unknown"
    for v in _strings(tinput):
        if v in mapping:
            env = mapping[v]
            break

    canon = json.dumps({"t": tool, "i": tinput}, sort_keys=True, separators=(",", ":"))
    h = hashlib.sha256(canon.encode()).hexdigest()[:16]
    nonce = os.path.expanduser(f"~/.claude/.render-approve-{h}")

    if os.path.exists(nonce):
        try:
            age = time.time() - os.path.getmtime(nonce)
            os.remove(nonce)  # one-shot: consume whether fresh or stale
            if age <= NONCE_TTL_SEC:
                sys.exit(0)  # approved — allow this one call
        except Exception:
            pass  # fall through to block

    label = {
        "prod": "PRODUCTION  (extra scrutiny)",
        "staging": "STAGING",
        "dev": "dev",
        "unknown": "UNKNOWN - treat as production",
    }.get(env, env)

    _block(
        "RENDER WRITE GATE - human approval required (fires even in bypass mode).\n\n"
        f"  Tool:        {tool}\n"
        f"  Target env:  {label}\n\n"
        "Policy: EVERY Render write to ANY env is approval-gated, per call.\n"
        "To proceed:\n"
        "  1. SHOW the user the exact tool call (tool + args) + a one-line plain-English\n"
        "     note of what it does and its effect, THEN ask with AskUserQuestion (state\n"
        "     the target env above). Never ask for approval without showing the call first.\n"
        f"  2. On approval:  touch {nonce}\n"
        "  3. Re-issue the EXACT same tool call. Approval is one-shot"
        f" and expires in {NONCE_TTL_SEC}s.\n"
    )


if __name__ == "__main__":
    main()
