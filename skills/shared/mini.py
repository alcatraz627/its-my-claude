"""
mini.py — Python shim for the mini-model callable.

Usage:
    from shared.mini import mini
    title = mini("Fix auth bug", template="session-title")
    answer = mini("what does jq -r do", template="doc-lookup")
    cmd = mini("find large files", template="cmd-compose", backend="local")
"""

import subprocess
import os

MINI_CORE = os.path.expanduser("~/.claude/scripts/mini-core.sh")


def mini(
    prompt: str,
    template: str | None = None,
    backend: str = "auto",
    max_tokens: int = 200,
    context_file: str | None = None,
    timeout: float = 10.0,
) -> str:
    """Call the mini-model dispatcher and return the result text.

    Args:
        prompt: The input text or query.
        template: Optional template name (e.g., "session-title", "doc-lookup").
        backend: "auto" (default), "local" (Ollama), or "cloud" (Haiku).
        max_tokens: Maximum output tokens.
        context_file: Optional file path to include as context.
        timeout: Subprocess timeout in seconds.

    Returns:
        The model's response text, stripped of trailing whitespace.
        Empty string on any failure.
    """
    args = ["bash", MINI_CORE]

    if backend == "local":
        args.append("--local")
    elif backend == "cloud":
        args.append("--quality")

    args.extend(["--max-tokens", str(max_tokens)])

    if context_file:
        args.extend(["--context", context_file])

    if template:
        args.extend(["--template", template])

    args.append(prompt)

    try:
        result = subprocess.run(
            args,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return result.stdout.strip()
    except (subprocess.TimeoutExpired, OSError):
        return ""
