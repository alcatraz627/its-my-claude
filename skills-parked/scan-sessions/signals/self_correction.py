"""
Detect assistant self-correction patterns.

Signals:
- "I apologize", "let me fix", "actually", "I was wrong" in assistant text
- Immediate re-edit of a file just edited (edit → edit same file within 3 turns)
"""

import re

SELF_CORRECTION_PATTERNS = [
    (re.compile(p, re.IGNORECASE), label)
    for p, label in [
        (r"I apologi[sz]e", "apology"),
        (r"let me (fix|correct|update|redo)", "fix_attempt"),
        (r"I (was|made a|made an) (wrong|mistake|error)", "admission"),
        (r"actually,?\s+(that|I|the|let)", "actually"),
        (r"I should have", "hindsight"),
        (r"that was incorrect", "admission"),
        (r"my (mistake|error|bad)", "admission"),
        (r"sorry.{0,20}(wrong|incorrect|mistake|error)", "apology"),
        (r"I (forgot|missed|overlooked)", "oversight"),
    ]
]


def extract_self_correction(conn, session_id):
    """Extract self-correction signals from assistant turns."""
    signals = []

    turns = conn.execute("""
        SELECT idx, type, content_text, tool_name, tool_input_json, ts
        FROM turns
        WHERE session_id = ? AND type IN ('assistant', 'tool_use')
        ORDER BY idx
    """, (session_id,)).fetchall()

    # Track recent file edits for re-edit detection
    recent_edits = {}  # filepath → turn_idx

    for turn in turns:
        # Check assistant text for self-correction language
        if turn["type"] == "assistant" and turn["content_text"]:
            text = turn["content_text"]
            for pat, label in SELF_CORRECTION_PATTERNS:
                if pat.search(text):
                    signals.append({
                        "session_id": session_id,
                        "turn_idx": turn["idx"],
                        "kind": "self_correction",
                        "severity": "medium",
                        "payload": {
                            "subtype": label,
                            "text_preview": text[:200],
                        },
                    })
                    break  # one match per turn

        # Check for re-edits (Edit tool on same file within 5 turns)
        if turn["type"] == "tool_use" and turn["tool_name"] in ("Edit", "Write"):
            try:
                import json
                inp = json.loads(turn["tool_input_json"]) if turn["tool_input_json"] else {}
                filepath = inp.get("file_path", "")
            except (json.JSONDecodeError, TypeError):
                filepath = ""

            if filepath and filepath in recent_edits:
                gap = turn["idx"] - recent_edits[filepath]
                if gap <= 5:
                    signals.append({
                        "session_id": session_id,
                        "turn_idx": turn["idx"],
                        "kind": "self_correction",
                        "severity": "medium",
                        "payload": {
                            "subtype": "re_edit",
                            "filepath": filepath,
                            "gap_turns": gap,
                        },
                    })

            recent_edits[filepath] = turn["idx"]

    return signals
