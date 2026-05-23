"""
Detect skill invocations and their outcomes.

Signals:
- Skill invoked (detected via Skill tool_use)
- Success/failure of skill execution
- Per-skill reliability tracking

Outcome heuristics:
- error: tool_result with is_error within 10 turns
- rejected: user frustration keywords immediately after
- confirmed_success: explicit praise ("thanks", "perfect", etc.)
- implicit_success: user moves on to a new topic (no correction, no error)
- unknown: no user turn found within lookahead window
"""

import json
import re

# Words that signal rejection — must be near the start or standalone
_REJECTION_PATTERNS = [
    re.compile(p, re.IGNORECASE)
    for p in [
        r"^\s*no\b",
        r"\bwrong\b",
        r"\bstop\b",
        r"\brevert\b",
        r"\bundo\b",
        r"\bthat'?s not",
        r"\bdon'?t\b",
        r"\bnot what",
        r"\bwhy did you",
    ]
]

# Words that signal explicit praise / confirmation
_PRAISE_PATTERNS = [
    re.compile(p, re.IGNORECASE)
    for p in [
        r"\bthanks?\b",
        r"\bgreat\b",
        r"\bperfect\b",
        r"\bgood\b",
        r"\bnice\b",
        r"\blgtm\b",
        r"\blooks? good\b",
        r"\bawesome\b",
        r"\bexcellent\b",
    ]
]

# System-generated preambles to skip (same as user_frustration.py)
_SKIP_PATTERNS = [
    re.compile(p, re.IGNORECASE)
    for p in [
        r"^This session is being continued",
        r"^<command-",
        r"^<system-reminder",
        r"^Summary:",
        r"^Continue the conversation",
        r"^Keep going\.?$",
        r"^Tool loaded\.?$",
    ]
]


def _is_system_text(text):
    """Return True if text is system-generated, not real user input."""
    for pat in _SKIP_PATTERNS:
        if pat.search(text):
            return True
    return len(text) > 500


def _is_new_instruction(text):
    """Heuristic: text looks like a new user instruction, not a correction.

    A new instruction typically:
    - Has 5+ words (substantive)
    - Doesn't start with rejection words
    - Isn't just a single-word confirmation
    """
    words = text.split()
    if len(words) < 3:
        return False

    for pat in _REJECTION_PATTERNS:
        if pat.search(text):
            return False

    return True


def extract_skill_outcomes(conn, session_id):
    """Extract skill outcome signals from a session."""
    signals = []

    # Find Skill tool_use turns
    skill_uses = conn.execute("""
        SELECT idx, tool_input_json, ts
        FROM turns
        WHERE session_id = ? AND type = 'tool_use' AND tool_name = 'Skill'
        ORDER BY idx
    """, (session_id,)).fetchall()

    if not skill_uses:
        return signals

    # For each skill invocation, look at subsequent turns for success/failure
    all_turns = conn.execute("""
        SELECT idx, type, role, content_text, tool_result_text, is_error
        FROM turns
        WHERE session_id = ?
        ORDER BY idx
    """, (session_id,)).fetchall()

    turn_map = {t["idx"]: t for t in all_turns}
    max_idx = max(turn_map.keys()) if turn_map else 0

    for su in skill_uses:
        try:
            inp = json.loads(su["tool_input_json"]) if su["tool_input_json"] else {}
            skill_name = inp.get("skill", "unknown")
        except (json.JSONDecodeError, TypeError):
            skill_name = "unknown"

        outcome = "unknown"
        evidence = ""
        saw_error = False
        saw_user_turn = False

        # Look ahead up to 40 turns for outcome indicators
        # (complex skills like create-report generate 20+ tool calls before user responds)
        for offset in range(1, 41):
            next_idx = su["idx"] + offset
            if next_idx not in turn_map:
                continue
            nt = turn_map[next_idx]

            # Track errors — but don't break yet, user response matters more
            if nt["is_error"] and not saw_error:
                saw_error = True
                evidence = (nt["tool_result_text"] or nt["content_text"] or "")[:200]

            # User turn is the definitive signal
            if nt["type"] == "user" and nt["content_text"]:
                text = nt["content_text"].strip()

                # Skip system-generated text
                if _is_system_text(text):
                    continue

                saw_user_turn = True

                # Check for rejection first (highest priority)
                for pat in _REJECTION_PATTERNS:
                    if pat.search(text):
                        outcome = "rejected"
                        evidence = text[:200]
                        break
                if outcome == "rejected":
                    break

                # Check for explicit praise
                for pat in _PRAISE_PATTERNS:
                    if pat.search(text):
                        outcome = "confirmed_success"
                        evidence = text[:100]
                        break
                if outcome == "confirmed_success":
                    break

                # Topic change = implicit success
                # User moved on without complaining → skill worked
                if _is_new_instruction(text):
                    outcome = "implicit_success"
                    evidence = text[:80]
                    break

        # If we saw an error but user didn't complain, downgrade to "error_recovered"
        if saw_error and outcome in ("implicit_success", "confirmed_success"):
            outcome = "error_recovered"

        # If we only saw errors and no user response, it's a hard error
        if saw_error and not saw_user_turn:
            outcome = "error"

        # If no user turn followed at all (end of session), treat as implicit success
        # The user ended the session without correcting → skill likely worked
        if not saw_user_turn and not saw_error:
            # Check if the skill was near the end of the session
            remaining = max_idx - su["idx"]
            if remaining < 50:
                outcome = "implicit_success"
                evidence = "(session ended without correction)"

        signals.append({
            "session_id": session_id,
            "turn_idx": su["idx"],
            "kind": "skill_outcome",
            "severity": "high" if outcome in ("error", "rejected") else "info",
            "payload": {
                "skill_name": skill_name,
                "outcome": outcome,
                "evidence": evidence,
            },
        })

    return signals
