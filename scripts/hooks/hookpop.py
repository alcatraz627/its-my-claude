"""Who a hook is for: a person's turn, or a machine's. The Python half of hook_should_run.

A style or format gate is advice for someone reading the reply. In a headless claude -p run
or a keep-warm ping nobody is reading, so advice there only buys another paid turn. Safety
guards never ask this question.

Mirror of hook_should_run and hook_is_automated_prompt in hook-common.sh; hook-common.test.sh
runs both against the same cases.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))


def _prefixes():
    with open(os.path.join(HERE, "automated-prompts.txt")) as f:
        return tuple(line.rstrip("\n") for line in f if line.strip())


PREFIXES = _prefixes()


def is_automated_prompt(prompt):
    """True when nobody typed this prompt: a task notification, a wake, a harness note."""
    return (prompt or "").lstrip().startswith(PREFIXES)


def background_live(inp):
    """True when background work is still running, so a reply waiting on it has not stopped.

    The inbox watcher runs for the whole session, so it does not count.
    """
    tasks = inp.get("background_tasks") if isinstance(inp, dict) else None
    if not isinstance(tasks, list):
        return False
    return any(isinstance(t, dict) and t.get("status") == "running" and "watch-inbox" not in str(t.get("command", ""))
               for t in tasks)


def in_keepwarm_wake(sid=None):
    """True during a keep-warm ping's turn. keepwarm.py owns the marker."""
    sid = sid or os.environ.get("CLAUDE_CODE_SESSION_ID") or ""
    folder = os.environ.get("KEEPWARM_WAKE_DIR", "/tmp")
    return bool(sid) and os.path.exists(os.path.join(folder, "claude-keepwarm-wake-%s" % sid[:8]))


def should_run(population="owner-turn", sid=None):
    """Should a hook written for this population act now?

    owner-turn: only when a person may read the reply. Not headless, not a keep-warm ping.
    no-wake: everywhere except a keep-warm ping, for a gate a headless run also has to meet.
    """
    if os.environ.get("HOOK_TEST") == "1" and os.environ.get("HOOK_POPULATION_TEST") != "1":
        return True
    if in_keepwarm_wake(sid):
        return False
    if population == "no-wake":
        return True
    return not os.environ.get("CLAUDE_CODE_ENTRYPOINT", "").startswith("sdk")
