"""Says who wrote a message that reached the agent: the owner, a peer session, a hook, a timer, a skill or a background task.

The transcript marks this itself (turnOrigin, promptSource, isMeta, origin.kind),
so nothing here guesses from wording except for records that predate those fields.
"""
import re

LEGACY_SCAFFOLD = ("<command-name>", "<local-command", "<task-notification>", "<system-reminder>", "Keep-warm wake",
                   "[Request interrupted", "Caveat:", "<bash-input>", "<bash-stdout>", "<command-message>",
                   "This session is being continued", "Base directory for this skill", "Stop hook", "[Image:",
                   "[keepwarm]", "Another Claude session sent")
COMMAND = re.compile(r"<command-(?:name|message)>/?([\w:.-]+)</command-(?:name|message)>")


def _text(msg):
    c = msg.get("content")
    if isinstance(c, str):
        return c
    if isinstance(c, list):
        if any(isinstance(b, dict) and b.get("type") == "tool_result" for b in c):
            return None
        return "\n".join(b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text")
    return None


def classify(d):
    """Return (kind, text, queued) for one transcript record, or (None, '', False) when it is not an incoming message.

    kind is one of: human, command, peer, scheduled, task, stop_hook, skill, meta, compaction, plugin, legacy_human.
    """
    t = d.get("type")
    if t == "attachment":
        a = d.get("attachment") or {}
        if a.get("type") != "queued_command":
            return None, "", False
        o = a.get("origin") if isinstance(a.get("origin"), dict) else {}
        p = a.get("prompt") if isinstance(a.get("prompt"), str) else ""
        if o.get("kind") == "human":
            return "human", p.strip(), True
        return "task", p, True
    if t != "user":
        return None, "", False
    text = _text(d.get("message") or {})
    if text is None:
        return None, "", False
    head = text.lstrip()
    if head.startswith("This session is being continued"):
        return "compaction", text, False
    if head.startswith("Another Claude session sent"):
        return "peer", text, False
    if d.get("isMeta"):
        if head.startswith("Stop hook"):
            return "stop_hook", text, False
        if head.startswith("Base directory for this skill"):
            return "skill", text, False
        if d.get("turnOrigin") == "scheduled":
            return "scheduled", text, False
        return "meta", text, False
    origin = d.get("turnOrigin")
    okind = d["origin"].get("kind") if isinstance(d.get("origin"), dict) else None
    if origin in ("task_notification", "auto_continuation"):
        return "task", text, False
    if origin == "scheduled":
        return "scheduled", text, False
    if origin in ("system", "sdk") or okind == "plugin":
        return "plugin", text, False
    if origin == "peer":
        return "peer", text, False
    if COMMAND.search(head[:300]) or head.startswith(("<local-command", "<bash-input>", "<bash-stdout>")):
        return "command", text, False
    if origin == "human" or okind == "human":
        return "human", text.strip(), d.get("promptSource") == "queued"
    if head.startswith(LEGACY_SCAFFOLD) or not head:
        return "meta", text, False
    return "legacy_human", text.strip(), False
