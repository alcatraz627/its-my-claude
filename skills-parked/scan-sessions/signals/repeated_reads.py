"""
Detect repeated file reads — a sign of confusion or context loss.

Signals:
- Same file Read 3+ times in a session
- Multiple Reads of same file within short turn windows (possible context loss)
"""

import json
from collections import Counter


def extract_repeated_reads(conn, session_id):
    """Extract repeated-read signals from a session."""
    signals = []

    reads = conn.execute("""
        SELECT idx, tool_name, tool_input_json, ts
        FROM turns
        WHERE session_id = ? AND type = 'tool_use' AND tool_name = 'Read'
        ORDER BY idx
    """, (session_id,)).fetchall()

    # Count reads per file
    file_reads = Counter()
    file_indices = {}  # filepath → list of turn indices

    for turn in reads:
        try:
            inp = json.loads(turn["tool_input_json"]) if turn["tool_input_json"] else {}
            filepath = inp.get("file_path", "")
        except (json.JSONDecodeError, TypeError):
            continue

        if not filepath:
            continue

        file_reads[filepath] += 1
        if filepath not in file_indices:
            file_indices[filepath] = []
        file_indices[filepath].append(turn["idx"])

    # Flag files read 3+ times
    for filepath, count in file_reads.items():
        if count >= 3:
            indices = file_indices[filepath]
            # Check if reads are clustered (within 20 turns of each other)
            spread = indices[-1] - indices[0] if len(indices) > 1 else 0

            signals.append({
                "session_id": session_id,
                "turn_idx": indices[-1],  # last read
                "kind": "repeated_reads",
                "severity": "medium" if count >= 5 else "low",
                "payload": {
                    "filepath": filepath,
                    "read_count": count,
                    "turn_spread": spread,
                    "subtype": "clustered" if spread < 30 else "spread",
                },
            })

    return signals
