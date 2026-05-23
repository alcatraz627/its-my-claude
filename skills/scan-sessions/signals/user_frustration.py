"""
Detect user frustration signals from session turns.

Signals:
- Frustration keywords in user messages ("no", "stop", "don't", "wrong", etc.)
- Short corrective replies (<=5 words after assistant action)
- Repeated corrections in sequence
"""

import re

# Lexicon of frustration indicators, grouped by severity
FRUSTRATION_KEYWORDS = {
    "high": [
        r"\bno\b[.!]*$",        # bare "no" as full message
        r"\bstop\b",
        r"\brevert\b",
        r"\bundo\b",
        r"\bwrong\b",
        r"\bincorrect\b",
        r"you'?re wrong",
        r"that'?s wrong",
        r"that'?s not (right|correct|what)",
        r"why did you",
        r"why would you",
        r"i (said|told you|asked)",
        r"i didn'?t (ask|want|say)",
        r"don'?t do th(at|is)",
    ],
    "medium": [
        r"\bactually\b,?\s*(no|don)",
        r"\bnot what i",
        r"try again",
        r"start over",
        r"from scratch",
        r"go back",
        r"\bno[,.]?\s+(that|this|i|it|the|do|please)",
        r"please (don'?t|stop|revert)",
    ],
    "low": [
        r"\bhmm\b",
        r"\bugh\b",
        r"\bsigh\b",
        r"not (quite|exactly)",
        r"close but",
        r"almost",
    ],
}

# Pre-compile patterns
_COMPILED = {
    sev: [re.compile(p, re.IGNORECASE) for p in patterns]
    for sev, patterns in FRUSTRATION_KEYWORDS.items()
}

SHORT_REPLY_THRESHOLD = 5  # words

# System-generated preambles that look like user text but aren't real user input.
# These appear as the first user turn after compaction or session continuation.
_BOILERPLATE_PATTERNS = [
    re.compile(p, re.IGNORECASE | re.DOTALL)
    for p in [
        r"^This session is being continued",
        r"^<command-",              # skill invocation tags
        r"^<system-reminder",       # system context
        r"^Summary:",               # compaction summaries
        r"^Continue the conversation",
        r"^If you need specific details from before compaction",
        r"^The following skills",
        r"^Tool loaded",
        r"^Keep going\.?$",         # continuation prompts
        r"^I'm back",
        r"^\[Request interrupted",       # user hit Escape/cancel
        r"^\[Message cancelled",         # cancelled messages
        r"^<user-prompt-submit-hook",    # hook-injected context
    ]
]


def _is_boilerplate(text):
    """Return True if text is system-generated, not real user frustration."""
    for pat in _BOILERPLATE_PATTERNS:
        if pat.search(text):
            return True
    # Long messages (>500 chars) are usually pasted context, not corrections
    if len(text) > 500:
        return True
    return False


def extract_user_frustration(conn, session_id):
    """Extract frustration signals from a session's turns.

    Returns list of signal dicts ready for insertion.
    """
    signals = []

    turns = conn.execute("""
        SELECT idx, type, role, content_text, ts
        FROM turns
        WHERE session_id = ? AND type IN ('user', 'assistant', 'tool_use')
        ORDER BY idx
    """, (session_id,)).fetchall()

    prev_was_assistant_action = False

    for turn in turns:
        if turn["type"] in ("assistant", "tool_use"):
            prev_was_assistant_action = True
            continue

        if turn["type"] != "user" or not turn["content_text"]:
            continue

        text = turn["content_text"].strip()

        # Skip system-generated boilerplate
        if _is_boilerplate(text):
            prev_was_assistant_action = False
            continue

        # Check keyword matches
        for severity, patterns in _COMPILED.items():
            for pat in patterns:
                if pat.search(text):
                    signals.append({
                        "session_id": session_id,
                        "turn_idx": turn["idx"],
                        "kind": "user_frustration",
                        "severity": severity,
                        "payload": {
                            "pattern": pat.pattern,
                            "text_preview": text[:200],
                            "subtype": "keyword",
                        },
                    })
                    break  # one match per severity level is enough
            else:
                continue
            break  # stop checking lower severities once matched

        # Short corrective reply after assistant action
        word_count = len(text.split())
        if prev_was_assistant_action and word_count <= SHORT_REPLY_THRESHOLD:
            # Only flag if it's not a simple confirmation
            lower = text.lower().strip(".,!? ")
            exact_confirmations = {"yes", "ok", "okay", "sure", "thanks", "thank you",
                           "great", "good", "perfect", "nice", "cool", "done",
                           "yep", "yeah", "y", "lgtm", "looks good", "keep going"}
            # Also check if text contains any confirmation phrase (handles compound phrases)
            partial_confirmations = [
                "looks good", "keep going", "sounds good", "go ahead",
                "that's right", "that works", "carry on", "continue",
                "let's go", "let's do", "let's start", "get started",
            ]
            # Short instructions are NOT frustration — filter them out
            instruction_patterns = [
                "now ", "also ", "how to", "how do", "what about",
                "add ", "fix ", "change ", "update ", "show ", "list ",
                "can you", "please ", "do the ", "run ", "make ",
                "for the ", "for this", "same for", "also for",
            ]
            is_confirmation = (
                lower in exact_confirmations
                or any(p in lower for p in partial_confirmations)
                or any(lower.startswith(p) for p in instruction_patterns)
            )
            if not is_confirmation:
                signals.append({
                    "session_id": session_id,
                    "turn_idx": turn["idx"],
                    "kind": "user_frustration",
                    "severity": "low",
                    "payload": {
                        "text_preview": text[:200],
                        "word_count": word_count,
                        "subtype": "short_reply",
                    },
                })

        prev_was_assistant_action = False

    return signals
