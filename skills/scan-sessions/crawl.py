"""
crawl.py — Walk ~/.claude/projects/**/*.jsonl and index into SQLite.

Incremental by default: tracks mtime + size per file, skips unchanged.
Force full re-crawl with rescan=True.
"""

import json
import os
import sqlite3
from pathlib import Path
from datetime import datetime, timezone

PROJECTS_DIR = os.path.expanduser("~/.claude/projects")
DB_PATH = os.path.expanduser("~/.claude/assets/scan-sessions/index.db")


def get_db(db_path=None):
    """Open (or create) the SQLite database and return connection."""
    path = db_path or DB_PATH
    os.makedirs(os.path.dirname(path), exist_ok=True)
    conn = sqlite3.connect(path)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")
    conn.row_factory = sqlite3.Row
    _create_tables(conn)
    return conn


def _create_tables(conn):
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS sessions (
            id TEXT PRIMARY KEY,
            project TEXT NOT NULL,
            project_dir TEXT,
            filepath TEXT NOT NULL,
            started TEXT,
            ended TEXT,
            turn_count INTEGER DEFAULT 0,
            user_turns INTEGER DEFAULT 0,
            assistant_turns INTEGER DEFAULT 0,
            model TEXT,
            version TEXT,
            cwd TEXT,
            file_size INTEGER,
            file_mtime REAL,
            indexed_at TEXT
        );

        CREATE TABLE IF NOT EXISTS turns (
            session_id TEXT NOT NULL,
            idx INTEGER NOT NULL,
            type TEXT NOT NULL,
            role TEXT,
            ts TEXT,
            content_text TEXT,
            tool_name TEXT,
            tool_input_json TEXT,
            tool_result_text TEXT,
            is_error INTEGER DEFAULT 0,
            model TEXT,
            usage_json TEXT,
            PRIMARY KEY (session_id, idx),
            FOREIGN KEY (session_id) REFERENCES sessions(id)
        );

        CREATE TABLE IF NOT EXISTS signals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT NOT NULL,
            turn_idx INTEGER,
            kind TEXT NOT NULL,
            severity TEXT DEFAULT 'info',
            payload_json TEXT,
            created_at TEXT,
            FOREIGN KEY (session_id) REFERENCES sessions(id)
        );

        CREATE INDEX IF NOT EXISTS idx_signals_kind ON signals(kind);
        CREATE INDEX IF NOT EXISTS idx_signals_session ON signals(session_id);
        CREATE INDEX IF NOT EXISTS idx_turns_session ON turns(session_id);
        CREATE INDEX IF NOT EXISTS idx_sessions_project ON sessions(project);
    """)
    conn.commit()


def _derive_project(filepath, cwd=None):
    """Extract a human-readable project name.

    Strategy:
    1. If CWD is available, derive from last 2 path segments of CWD
    2. Otherwise, find the project folder (direct child of ~/.claude/projects/)
       and derive from that, preferring known path segments.
    """
    # Prefer CWD — it's the actual working directory, unambiguous
    if cwd:
        segments = cwd.rstrip("/").split("/")
        # Skip home dir prefix to get meaningful segments
        # e.g. /Users/user/Code/MyProject → Code/MyProject
        home = os.path.expanduser("~")
        rel = cwd.replace(home, "").strip("/")
        parts = rel.split("/")
        if len(parts) >= 2:
            return "/".join(parts[-2:])
        return parts[-1] if parts else cwd

    # Fallback: derive from project folder name in ~/.claude/projects/
    p = Path(filepath)
    projects_dir = Path(PROJECTS_DIR)

    # Walk up until we find the direct child of projects/
    try:
        rel = p.relative_to(projects_dir)
        project_folder = rel.parts[0]  # e.g. "-Users-alcatraz627-Code-MyProject"
    except ValueError:
        return Path(filepath).parent.name

    # The folder name encodes the path with / and . both replaced by -
    # We can't perfectly decode, but we can take meaningful trailing segments
    # Strip leading -Users-<username>- prefix
    decoded = project_folder.lstrip("-")
    # Find the username segment (typically the 2nd segment after "Users")
    parts = decoded.split("-")
    # Skip "Users" and the username to get to the project path
    user_idx = 0
    for i, part in enumerate(parts):
        if part == "Users" and i + 1 < len(parts):
            user_idx = i + 2  # skip "Users" and username
            break

    meaningful = parts[user_idx:] if user_idx < len(parts) else parts
    # Join remaining parts — we lose the original hyphen/separator distinction,
    # but for display purposes this is good enough
    name = "-".join(meaningful) if meaningful else project_folder
    # Take last 2 dash-groups as a rough project label
    dash_groups = name.split("-")
    if len(dash_groups) > 4:
        return "/".join(dash_groups[-2:])
    return name


def _extract_text(content, include_tool_results=False):
    """Extract plain text from message content (string or content blocks).

    By default skips tool_result blocks — those are indexed as separate turns.
    """
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        texts = []
        for block in content:
            if isinstance(block, dict):
                if block.get("type") == "text":
                    texts.append(block.get("text", ""))
                elif block.get("type") == "tool_result" and include_tool_results:
                    rc = block.get("content", "")
                    if isinstance(rc, str):
                        texts.append(rc[:500])
                    elif isinstance(rc, list):
                        for r in rc:
                            if isinstance(r, dict) and r.get("type") == "text":
                                texts.append(r.get("text", "")[:500])
        return "\n".join(texts)
    return ""


def _extract_tool_uses(content):
    """Extract tool_use blocks from assistant message content."""
    tools = []
    if not isinstance(content, list):
        return tools
    for block in content:
        if isinstance(block, dict) and block.get("type") == "tool_use":
            tools.append({
                "id": block.get("id", ""),
                "name": block.get("name", ""),
                "input": block.get("input", {}),
            })
    return tools


def _extract_tool_results(content):
    """Extract tool_result blocks from user message content."""
    results = []
    if not isinstance(content, list):
        return results
    for block in content:
        if isinstance(block, dict) and block.get("type") == "tool_result":
            rc = block.get("content", "")
            text = rc if isinstance(rc, str) else _extract_text([block])
            results.append({
                "tool_use_id": block.get("tool_use_id", ""),
                "is_error": bool(block.get("is_error")),
                "content": text[:1000],
            })
    return results


def crawl(conn, rescan=False, projects_dir=None):
    """Crawl JSONL files and index into SQLite.

    Returns (new_sessions, updated_sessions, skipped).
    """
    pdir = projects_dir or PROJECTS_DIR
    if not os.path.isdir(pdir):
        return 0, 0, 0

    # Load existing file index for incremental check
    existing = {}
    if not rescan:
        for row in conn.execute("SELECT filepath, file_mtime, file_size FROM sessions"):
            existing[row["filepath"]] = (row["file_mtime"], row["file_size"])

    # Find all JSONL files
    jsonl_files = []
    for root, dirs, files in os.walk(pdir):
        for f in files:
            if f.endswith(".jsonl") and not f.startswith("."):
                full = os.path.join(root, f)
                # Skip non-session files (skill-injections, etc.)
                if "skill-injection" in f or "events" in f:
                    continue
                jsonl_files.append(full)

    new_count = 0
    updated_count = 0
    skipped = 0

    for filepath in jsonl_files:
        try:
            stat = os.stat(filepath)
            mtime = stat.st_mtime
            size = stat.st_size
        except OSError:
            continue

        # Incremental check
        if filepath in existing:
            old_mtime, old_size = existing[filepath]
            if mtime == old_mtime and size == old_size:
                skipped += 1
                continue
            updated_count += 1
        else:
            new_count += 1

        _index_session(conn, filepath, mtime, size)

    # Prune sessions whose files no longer exist
    live_files = set(jsonl_files)
    all_db_files = conn.execute("SELECT filepath FROM sessions").fetchall()
    pruned = 0
    for row in all_db_files:
        if row["filepath"] not in live_files:
            sid = conn.execute("SELECT id FROM sessions WHERE filepath = ?",
                               (row["filepath"],)).fetchone()
            if sid:
                conn.execute("DELETE FROM turns WHERE session_id = ?", (sid["id"],))
                conn.execute("DELETE FROM signals WHERE session_id = ?", (sid["id"],))
                conn.execute("DELETE FROM sessions WHERE id = ?", (sid["id"],))
                pruned += 1

    conn.commit()
    return new_count, updated_count, skipped


def _index_session(conn, filepath, mtime, size):
    """Parse a single JSONL file and upsert session + turns."""
    session_id = Path(filepath).stem
    # Handle subagent sessions
    if Path(filepath).parent.name == "subagents":
        session_id = Path(filepath).stem

    # Project derivation deferred until after CWD is extracted from JSONL

    # Delete existing data for re-index
    conn.execute("DELETE FROM turns WHERE session_id = ?", (session_id,))
    conn.execute("DELETE FROM signals WHERE session_id = ?", (session_id,))

    turns_data = []
    first_ts = None
    last_ts = None
    model = None
    version = None
    cwd = None
    user_turns = 0
    assistant_turns = 0
    turn_idx = 0

    try:
        with open(filepath, "r", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue

                obj_type = obj.get("type", "")
                ts = obj.get("timestamp", "")

                # Track timestamps
                if ts:
                    if first_ts is None:
                        first_ts = ts
                    last_ts = ts

                # Extract metadata from first entries
                if not version and obj.get("version"):
                    version = obj["version"]
                if not cwd and obj.get("cwd"):
                    cwd = obj["cwd"]

                # Only index user and assistant turns
                if obj_type not in ("user", "assistant"):
                    continue

                msg = obj.get("message", {})
                if not isinstance(msg, dict):
                    continue

                role = msg.get("role", obj_type)
                content = msg.get("content", "")

                if obj_type == "user":
                    user_turns += 1
                    content_text = _extract_text(content)

                    # Check for tool results in user messages
                    tool_results = _extract_tool_results(content)
                    for tr in tool_results:
                        turns_data.append((
                            session_id, turn_idx, "tool_result", "tool",
                            ts, tr["content"][:1000],
                            None, None, tr["content"][:500],
                            1 if tr["is_error"] else 0,
                            None, None
                        ))
                        turn_idx += 1

                    # Only index if there's actual text content
                    if content_text.strip():
                        turns_data.append((
                            session_id, turn_idx, "user", "user",
                            ts, content_text[:2000],
                            None, None, None, 0,
                            None, None
                        ))
                        turn_idx += 1

                elif obj_type == "assistant":
                    assistant_turns += 1
                    if not model and msg.get("model"):
                        model = msg["model"]

                    content_text = _extract_text(content)
                    usage = msg.get("usage")
                    usage_json = json.dumps(usage) if usage else None

                    # Extract tool uses
                    tool_uses = _extract_tool_uses(content)

                    if content_text.strip():
                        turns_data.append((
                            session_id, turn_idx, "assistant", "assistant",
                            ts, content_text[:2000],
                            None, None, None, 0,
                            model, usage_json
                        ))
                        turn_idx += 1

                    for tu in tool_uses:
                        input_json = json.dumps(tu["input"])[:2000]
                        turns_data.append((
                            session_id, turn_idx, "tool_use", "assistant",
                            ts, None,
                            tu["name"], input_json, None, 0,
                            model, None
                        ))
                        turn_idx += 1

    except OSError:
        return

    # Derive project from CWD (now known) or fall back to filepath
    project = _derive_project(filepath, cwd=cwd)

    # Upsert session
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    project_dir = str(Path(filepath).parent)

    conn.execute("""
        INSERT OR REPLACE INTO sessions
        (id, project, project_dir, filepath, started, ended,
         turn_count, user_turns, assistant_turns,
         model, version, cwd, file_size, file_mtime, indexed_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        session_id, project, project_dir, filepath,
        first_ts, last_ts,
        turn_idx, user_turns, assistant_turns,
        model, version, cwd, size, mtime, now
    ))

    # Batch insert turns
    if turns_data:
        conn.executemany("""
            INSERT OR REPLACE INTO turns
            (session_id, idx, type, role, ts, content_text,
             tool_name, tool_input_json, tool_result_text, is_error,
             model, usage_json)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, turns_data)
