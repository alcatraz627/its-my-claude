#!/usr/bin/env python3
"""Refuses to end a turn on an ask the owner cannot answer without opening something.

"Rule on R1 to R3", with the rulings' content only in a report file, made the
owner go and find what R1 to R3 were (2026-10-24, versable-ingest: "WHAT THE FUCK
ARE THEY WHY CANT YOU SHOW ME THOSE DID A HOOK NOT BLOCK YOU"). An ask whose
subject is a bare id, a run of ids or a file path blocks the turn once; the agent
re-sends it with each question, its options and its default inline. A decision
page link passes: the page carries the content.

Stop hook. Blocks once per distinct reply, then becomes a note so a session can
never wedge on it. Fenced code is ignored.
Mute: touch ~/.claude/.no-owner-ask-gate · Test: owner-ask-content-stop.test.sh
"""
import hashlib
import json
import os
import re
import sys

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


def main():
    if os.path.exists(MUTE) or os.environ.get("OWNER_ASK_GATE_OFF") == "1":
        return
    try:
        inp = json.load(sys.stdin)
        tp = inp.get("transcript_path")
        reply = last_reply(tp) if tp and os.path.exists(tp) else ""
    except (ValueError, OSError):
        return
    hits = bare_asks(reply)
    if not hits:
        return
    sig = hashlib.sha1(reply.encode()).hexdigest()[:16]
    mark = os.path.join(STATE, f"owner-ask-{str(inp.get('session_id'))[:8]}-{sig}")
    quoted = "; ".join(f'"{h[:120]}"' for h in hits[:3])
    if os.path.exists(mark):
        print(json.dumps({"systemMessage": f"Owner-ask gate: this reply still asks by id or file only ({quoted})."}))
        return
    try:
        open(mark, "w").close()
    except OSError:
        pass
    print(json.dumps({"decision": "block", "reason": (
        f"Your reply asks the owner to act on something named only by an id or a file: {quoted}. "
        "The owner cannot answer without opening it. Re-send the reply with each item spelled out inline: "
        "the question in one sentence, the options, and your default. For more than three, use a decision page "
        "(/decision-wizard) and link it.")}, ensure_ascii=False))


if __name__ == "__main__":
    main()
