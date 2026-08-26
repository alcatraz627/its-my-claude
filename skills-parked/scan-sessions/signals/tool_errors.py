"""
Detect tool errors and failures.

Signals:
- tool_result with is_error=1
- Permission denied patterns in tool results
- Timeout errors
- Grouped by tool name for per-tool reliability stats
"""

import re

ERROR_PATTERNS = [
    (re.compile(p, re.IGNORECASE), category)
    for p, category in [
        # Permissions
        (r"permission denied", "permission"),
        (r"EACCES|EPERM", "permission"),
        (r"not allowed|not permitted|access denied", "permission"),
        (r"deny|denied by hook", "hook_denied"),
        # Timeouts
        (r"timed? ?out|TimeoutExpired|deadline exceeded", "timeout"),
        # Not found
        (r"not found|ENOENT|No such file|does not exist|doesn't exist", "not_found"),
        (r"no matches found|no results", "not_found"),
        (r"command not found", "missing_cmd"),
        # Syntax / parse
        (r"syntax error|SyntaxError|parse error|ParseError", "syntax"),
        (r"unexpected token|unexpected end|unterminated", "syntax"),
        (r"JSON\.parse|JSONDecodeError|invalid json", "parse"),
        # Connection / network
        (r"connection refused|ECONNREFUSED", "connection"),
        (r"ECONNRESET|ETIMEDOUT|network error", "connection"),
        (r"fetch failed|request failed|HTTP [45]\d\d", "http_error"),
        # File system
        (r"already exists|EEXIST", "exists"),
        (r"ENOSPC|no space|disk full", "disk"),
        (r"EISDIR|is a directory", "wrong_type"),
        (r"ENOTDIR|not a directory", "wrong_type"),
        # Tool-specific
        (r"old_string.*not found|not unique in the file", "edit_mismatch"),
        (r"InputValidationError", "validation"),
        (r"rate limit|429|too many requests", "rate_limit"),
        (r"BLOCKED:|hook error:", "hook_denied"),
        (r"has been denied|Permission to use .* has been denied", "permission"),
        (r"Cancelled:.*parallel tool call", "cancelled"),
        (r"MCP error|Authentication Failed", "mcp_error"),
        (r"File has not been read yet|Read it first", "precondition"),
        (r"SAFE DELETE.*rm.*blocked|'rm' is blocked", "hook_denied"),
        (r"exceeds maximum allowed tokens|content.*exceeds.*tokens", "token_limit"),
        (r"exceeds maximum allowed size", "token_limit"),
        (r"too large to read|file too large", "token_limit"),
        # Browser / Playwright / DevTools
        (r"Target page.*has been closed|browser has been closed", "browser_error"),
        (r"browser is already running", "browser_error"),
        (r"Protocol error", "browser_error"),
        # Permission prompts (user didn't approve)
        (r"Permission to use \w+ with command", "permission"),
        # Stale state
        (r"modified since read|File has been modified", "stale_read"),
        (r"no workspace set", "config_error"),
        # Validation
        (r"path should be a", "validation"),
        # Process
        (r"killed|SIGKILL|SIGTERM|OOM", "killed"),
        (r"exit code [1-9]|exited with|non-zero", "exit_code"),
        # Import / module
        (r"ModuleNotFoundError|ImportError|Cannot find module", "import"),
        (r"TypeError|AttributeError|NameError|ReferenceError", "runtime"),
    ]
]


def extract_tool_errors(conn, session_id):
    """Extract tool error signals from a session."""
    signals = []

    # Get tool_result turns with is_error flag
    error_results = conn.execute("""
        SELECT idx, tool_result_text, ts
        FROM turns
        WHERE session_id = ? AND type = 'tool_result' AND is_error = 1
        ORDER BY idx
    """, (session_id,)).fetchall()

    for turn in error_results:
        text = turn["tool_result_text"] or ""
        category = "unknown"
        for pat, cat in ERROR_PATTERNS:
            if pat.search(text):
                category = cat
                break

        signals.append({
            "session_id": session_id,
            "turn_idx": turn["idx"],
            "kind": "tool_error",
            "severity": "high" if category in ("permission", "timeout") else "medium",
            "payload": {
                "category": category,
                "text_preview": text[:300],
            },
        })

    # Also check tool_use turns followed by error-like content in results
    tool_uses = conn.execute("""
        SELECT t1.idx, t1.tool_name, t1.tool_input_json,
               t2.content_text, t2.tool_result_text, t2.is_error
        FROM turns t1
        LEFT JOIN turns t2 ON t2.session_id = t1.session_id
            AND t2.type = 'tool_result'
            AND t2.idx > t1.idx
            AND t2.idx <= t1.idx + 3
        WHERE t1.session_id = ? AND t1.type = 'tool_use'
        ORDER BY t1.idx
    """, (session_id,)).fetchall()

    # Track per-tool stats
    tool_stats = {}
    for row in tool_uses:
        name = row["tool_name"] or "unknown"
        if name not in tool_stats:
            tool_stats[name] = {"total": 0, "errors": 0}
        tool_stats[name]["total"] += 1

        result_text = row["tool_result_text"] or row["content_text"] or ""
        if row["is_error"]:
            tool_stats[name]["errors"] += 1

    # Emit per-tool reliability signal if error rate > 20%
    for tool_name, stats in tool_stats.items():
        if stats["total"] >= 3 and stats["errors"] / stats["total"] > 0.2:
            signals.append({
                "session_id": session_id,
                "turn_idx": -1,  # session-level
                "kind": "tool_error",
                "severity": "high",
                "payload": {
                    "subtype": "high_error_rate",
                    "tool_name": tool_name,
                    "total": stats["total"],
                    "errors": stats["errors"],
                    "error_rate": round(stats["errors"] / stats["total"], 2),
                },
            })

    return signals
