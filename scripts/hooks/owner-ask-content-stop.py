#!/usr/bin/env python3
"""Refuses to end a turn on an ask the owner cannot answer, or cannot judge.

Two kinds of ask are held. (1) "Rule on R1 to R3", with the rulings' content only
in a report file, made the owner go and find what R1 to R3 were (2026-10-24,
versable-ingest: "WHAT THE FUCK ARE THEY WHY CANT YOU SHOW ME THOSE DID A HOOK NOT
BLOCK YOU"). An ask whose subject is a bare id, a run of ids or a file path blocks
the turn once; the agent re-sends it with each question, its options and its
default inline. (2) A list under a "needs you" style lead-in where two or more
items are bare commands with no why ("delete the VM", "rotate the keys"; atone
mist-20261028-184946-19). The agent re-sends it saying why each is needed, what
led to it, or what happens if it is not done. A single bare item, an item with a
reason clause, and any reply linking a decision page pass: a false fire costs the
owner a re-send, so borderline lists are left alone.

Stop hook. Blocks once per distinct reply, then becomes a note so a session can
never wedge on it. Fenced code is ignored.
Mute: touch ~/.claude/.no-owner-ask-gate · Test: owner-ask-content-stop.test.sh
"""
import hashlib
import json
import os
import re
import subprocess
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hookpop  # noqa: E402

MUTE = os.path.expanduser("~/.claude/.no-owner-ask-gate")
STATE = os.environ.get("OWNER_ASK_STATE", "/tmp")

ASK = re.compile(
    r"\b(rule on|ruling on|decide|decision on|approve|sign off on|pick(?! up)|choose|your call on|"
    r"need(?:s)? you to|waiting on you|blocked on you|please (?:confirm|answer|rule|review|decide)|"
    r"answer (?:the )?(?:open )?(?:questions?|rulings?|asks?)|answer(?=\s+(?:[A-Z]{1,3}\d|#\d)))\b",
    re.IGNORECASE,
)
ID = r"(?:\b[A-Z]{1,3}\d{1,3}[a-z]?\b|#\d+\b|\bprop-[\w-]+|\b(?:decision|question|ruling|item|gate)\s+\d+\b)"
IDS = re.compile(ID, re.IGNORECASE)
FILE = re.compile(r"(?:^|[\s(`])(?:[~/.\w-]+/)*[\w.-]+\.(?:md|html|json|txt)\b")
PAGE = re.compile(r"https?://\S+/dp/\S+")
FENCE = re.compile(r"```.*?```", re.DOTALL)
# Signs the question itself is in the reply: a question mark, lettered or numbered
# options, a stated default, or a quoted choice.
CONTENT = re.compile(r"\?|\b[a-d]\)\s|\(\s*default|\bdefault(?:s)?\b|\bwhether\b|\boptions?:|\bor\b", re.IGNORECASE)
# "decide when to rotate the key" states its question; "rule on R1 when you can" does not.
QUESTION_OBJECT = re.compile(r"^\s*(?:on\s+)?(?:whether|when|how|which|what|if)\b", re.IGNORECASE)
# The id or file has to be the verb's object: soon after it, before the clause ends.
NEAR = 60
CLAUSE_END = re.compile(r"[,;:]\s|\s\u2014\s|\.\s")


def last_reply(tp):
    text = ""
    with open(tp, errors="replace") as f:
        for line in f:
            try:
                d = json.loads(line)
            except ValueError:
                continue
            if d.get("type") != "assistant":
                continue
            parts = (d.get("message") or {}).get("content") or []
            t = "\n".join(p.get("text", "") for p in parts if isinstance(p, dict) and p.get("type") == "text")
            if t.strip():
                text = t
    return text


def bare_asks(text):
    """Sentences that ask the owner for something named only by id or file."""
    text = FENCE.sub(" ", text)
    hits = []
    for sent in re.split(r"(?<=[.!])\s+|\n+", text):
        if PAGE.search(sent):
            continue
        # A verb inside a path ("step9-decide-effort/spec.md") is not an ask.
        masked = FILE.sub(lambda m: " " * len(m.group(0)), sent)
        if any(bare_object(sent[ask.end():]) for ask in ASK.finditer(masked)):
            hits.append(sent.strip())
    return hits


def bare_object(tail):
    """True when what follows an ask verb is only ids or a file, with no question in words."""
    tail = re.sub(r"^\s*[:\u2014-]\s*", " ", tail)  # "Decide: H2, H7" lists its object after a colon
    if QUESTION_OBJECT.search(tail):
        return False
    end = CLAUSE_END.search(tail)
    near = tail[:min(NEAR, end.start() if end else NEAR)]
    first = IDS.search(near) or FILE.search(near)
    if not first:
        return False
    # "Pick the staging VM service user (#16)": the id labels a described thing.
    if len([w for w in re.findall(r"[A-Za-z]{2,}", near[:first.start()]) if w.lower() not in STOP]) >= 2:
        return False
    # Strip the ids and paths: what is left must say what is being asked.
    rest = FILE.sub(" ", IDS.sub(" ", tail))
    return not (CONTENT.search(rest) or len(re.findall(r"[A-Za-z]{3,}", rest)) > 8)


STOP = {"the", "on", "a", "an", "to", "for", "in", "of", "and", "you", "your", "please", "items", "questions", "open"}

# A list the reply hands the owner to act on: "Needs you:", "Waiting on you", "Can you do these".
INTRO = re.compile(
    r"\b(waiting on you|blocked on you|needs? you|needs? your|for you to|on your side|your (?:move|turn|call|action)|"
    r"owner (?:asks?|gates?|actions?|items?)|asks? for you|actions? for you|decisions? for you|"
    r"what i need from you|can you|could you|please do)\b",
    re.IGNORECASE,
)
BULLET = re.compile(r"^\s*(?:[-*•]|\d{1,2}[.)])\s+(.*\S)\s*$")
# A list item that is a bare command: a verb first, with a short object after it.
IMPERATIVE = re.compile(
    r"^(?:please\s+)?[*_`]*(?:delete|remove|approve|rotate|rule on|decide|run|re-?run|restart|reboot|confirm|"
    r"sign off|merge|push|deploy|revoke|grant|enable|disable|kill|drop|reset|renew|switch|set|share|send|provide|"
    r"give|pick|choose|answer|review|test|trash|tear down|shut down|upgrade|update|create|add|pay|unblock|"
    r"log in|retire|archive|stop|start|cancel|install|reboot)\b",
    re.IGNORECASE,
)
# Words that say why: a cause, a consequence, or what the action unlocks.
REASON = re.compile(
    r"\b(because|so that|so (?:we|i|it|the|you)|since|otherwise|if not|if you (?:don'?t|do not)|or else|"
    r"which (?:is|are|will|lets?|means?|blocks?|costs?)|to (?:avoid|stop|unblock|keep|let|make|prevent|free|save|allow|"
    r"fix|close|clear|finish|get|see|check)|in order|due to|needed (?:for|to)|blocks?|blocking|unblocks?|"
    r"costs?|costing|leak(?:s|ed|ing)?|expires?|expired|before|after|until|when|while|why|for the)\b"
    r"|[—–]|\s-\s|\(\s*[^)]*\b\w+\s+\w+\s+\w+[^)]*\)|\?",
    re.IGNORECASE,
)
ITEM_WORDS = 14  # a longer item is explaining itself


def reasonless_asks(text):
    """List items handed to the owner as bare commands. Fires on two or more in one list."""
    text = FENCE.sub(" ", text)
    if PAGE.search(text):
        return []
    lines = text.split("\n")
    out = []
    i = 0
    while i < len(lines):
        if BULLET.match(lines[i]) is None and INTRO.search(lines[i]) and len(lines[i]) < 200:
            items, j, blanks = [], i + 1, 0
            while j < len(lines):
                m = BULLET.match(lines[j])
                if m:
                    items.append(m.group(1))
                    blanks = 0
                elif not lines[j].strip() and blanks == 0:
                    blanks = 1
                else:
                    break
                j += 1
            bare = [it for it in items if bare_command(it)]
            if len(bare) >= 2:
                out.extend(bare)
            i = j
        else:
            i += 1
    return out


def bare_command(item):
    plain = re.sub(r"[*_`]", "", item).strip()
    if not IMPERATIVE.match(item.strip()):
        return False
    if len(re.findall(r"[A-Za-z0-9'-]+", plain)) > ITEM_WORDS:
        return False
    return REASON.search(plain) is None


def warn_log(action):
    """Record this fire in the hook ledger. Telemetry never gets to break the hook."""
    try:
        subprocess.run(["bash", os.path.expanduser("~/.claude/scripts/hooks/warn-log.sh"), "--hook", "owner-ask", "--action", action],
                       capture_output=True, timeout=5)
    except (OSError, subprocess.SubprocessError):
        pass


def main():
    if os.path.exists(MUTE) or os.environ.get("OWNER_ASK_GATE_OFF") == "1" or not hookpop.should_run():
        return
    try:
        inp = json.load(sys.stdin)
        tp = inp.get("transcript_path")
        # The Stop input carries the reply just sent; the transcript lags one
        # message at Stop time, so it is only the fallback.
        reply = inp.get("last_assistant_message") or (last_reply(tp) if tp and os.path.exists(tp) else "")
    except (ValueError, OSError):
        return
    hits = bare_asks(reply)
    bare = [] if hits else reasonless_asks(reply)
    if not hits and not bare:
        return
    sig = hashlib.sha1(reply.encode()).hexdigest()[:16]
    mark = os.path.join(STATE, f"owner-ask-{str(inp.get('session_id'))[:8]}-{sig}")
    quoted = "; ".join(f'"{h[:120]}"' for h in (hits or bare)[:3])
    if os.path.exists(mark):
        what = "by id or file only" if hits else "with no reason attached"
        warn_log("soft")
        print(json.dumps({"systemMessage": f"Owner-ask gate: this reply still asks {what} ({quoted})."}))
        return
    try:
        open(mark, "w").close()
    except OSError:
        pass
    if hits:
        reason = (
            f"Your reply asks the owner to act on something named only by an id or a file: {quoted}. "
            "The owner cannot answer without opening it. Re-send the reply with each item spelled out inline: "
            "the question in one sentence, the options, and your default. For more than three, use a decision page "
            "(/decision-wizard) and link it.")
    else:
        reason = (
            f"Your reply hands the owner commands with no reason: {quoted}. "
            "Re-send it with each item saying why it is needed, what led to it, or what happens if it is not done. "
            "The owner decides faster, and rightly refuses what they cannot justify. For a batch, use a decision page "
            "(/decision-wizard) and link it.")
    warn_log("block")
    print(json.dumps({"decision": "block", "reason": reason}, ensure_ascii=False))


if __name__ == "__main__":
    main()
