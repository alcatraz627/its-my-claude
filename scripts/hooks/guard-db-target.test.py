#!/usr/bin/env python3
"""Checks guard-db-target: a schema-changing command against a non-local database
host that the command does not name is refused; local hosts, named hosts, offline
SQL, read-only commands and mere mentions of the verbs pass."""
import json, os, subprocess, sys, tempfile

HOOK = os.environ.get("DBT_HOOK", os.path.join(os.path.dirname(os.path.abspath(__file__)), "guard-db-target.py"))
tmp = tempfile.mkdtemp(prefix="dbt-")
WARN = os.path.join(tmp, "warn.jsonl")
passed = failed = 0
if os.path.exists(os.path.expanduser("~/.claude/.no-db-target-gate")):
    print("mute file present, test would pass vacuously")
    sys.exit(2)

ENV = {k: v for k, v in os.environ.items()
       if k not in ("DATABASE_URL", "SQLALCHEMY_DATABASE_URI", "DB_URL", "POSTGRES_URL", "DATABASE_URI",
                    "PGHOST", "DB_HOST", "POSTGRES_HOST", "MYSQL_HOST", "DATABASE_HOST")}
ENV["WARN_LOG_STORE"] = WARN


def make_dir(name, env_text, sub=""):
    d = os.path.join(tmp, name)
    os.makedirs(os.path.join(d, sub), exist_ok=True)
    with open(os.path.join(d, sub, ".env"), "w") as f:
        f.write(env_text)
    return d


REMOTE = make_dir("remote", "DATABASE_URL=postgresql://app:pw@10.1.2.3:5432/app\n")
REMOTE_SUB = make_dir("remote_sub", "DATABASE_URL=postgresql+psycopg2://app:pw@db.shared.example.com/app\n", "backend")
LOCAL = make_dir("local", "DATABASE_URL=postgresql://app:pw@localhost:5432/app\n")
COMPOSE = make_dir("compose", "DATABASE_URL=postgresql://app:pw@db:5432/app\n")
CLOUDSQL = make_dir("cloudsql", "DATABASE_URL=postgresql://app:pw@/app?host=/cloudsql/proj:region:inst\n")
BARE = os.path.join(tmp, "bare")
os.makedirs(BARE, exist_ok=True)
DROPSQL = os.path.join(tmp, "drop.sql")
with open(DROPSQL, "w") as f:
    f.write("ALTER TABLE t ADD c int;\nDROP TABLE old_t;\n")


def run(name, want, cwd, command, sid):
    """want: deny | warn | allow"""
    global passed, failed
    out = subprocess.run([sys.executable, HOOK], input=json.dumps(
        {"tool_name": "Bash", "tool_input": {"command": command}, "cwd": cwd, "session_id": sid}),
        capture_output=True, text=True, env=ENV).stdout
    got = "deny" if '"deny"' in out else ("warn" if "additionalContext" in out else "allow")
    if got == want:
        passed += 1
    else:
        failed += 1
        print(f"FAIL {name}: want {want} got {got} {out[:140]}")
    return out


def drop_markers(*sids):
    for s in sids:
        try:
            os.remove(f"/tmp/claude-dbtarget-{s[:8]}")
        except OSError:
            pass


sids = [f"dbt{n:05d}" for n in range(1, 40)]
drop_markers(*sids)
n = iter(sids)

# Refused: configured host is remote and the command does not name it.
run("alembic upgrade, remote .env", "deny", REMOTE, "alembic upgrade head", next(n))
run("alembic downgrade after cd into backend", "deny", tmp, f"cd {REMOTE_SUB}/backend && alembic downgrade -1", next(n))
run("alembic from a repo root with backend/.env", "deny", REMOTE_SUB, "alembic upgrade head", next(n))
run("uv run alembic", "deny", REMOTE, "uv run alembic upgrade head", next(n))
run("python -m alembic", "deny", REMOTE, "python3 -m alembic upgrade head", next(n))
run("psql DROP TABLE", "deny", REMOTE, 'psql -c "DROP TABLE users"', next(n))
run("psql TRUNCATE", "deny", REMOTE, "psql -c 'truncate table events'", next(n))
run("psql -f a file that drops", "deny", REMOTE, f"psql -f {DROPSQL}", next(n))
run("cloud sql socket host", "deny", CLOUDSQL, "alembic upgrade head", next(n))
run("env-prefixed alembic still seen", "deny", REMOTE, "FOO=1 alembic upgrade head", next(n))
run("after a chain separator", "deny", REMOTE, "echo hi && alembic upgrade head", next(n))

# Allowed: local, named, offline, read-only.
run("explicit remote URL in the command names itself", "allow", LOCAL,
    "DATABASE_URL=postgresql://u:p@db.other.example.com/x alembic upgrade head", next(n))
run("local .env", "allow", LOCAL, "alembic upgrade head", next(n))
run("compose service name", "allow", COMPOSE, "alembic upgrade head", next(n))
run("remote host named in the command", "allow", REMOTE, "DB_TARGET_ACK=10.1.2.3 alembic upgrade head", next(n))
run("explicit local URL beats a remote .env", "allow", REMOTE,
    "DATABASE_URL=postgresql://u@localhost/db alembic upgrade head", next(n))
run("psql -h remote, host named by the flag", "allow", REMOTE, 'psql -h db.prod.example.com -c "DROP TABLE x"', next(n))
run("offline sql generation", "allow", REMOTE, "alembic upgrade head --sql", next(n))
run("alembic current", "allow", REMOTE, "alembic current", next(n))
run("alembic history", "allow", REMOTE, "alembic history --verbose", next(n))
run("psql select", "allow", REMOTE, 'psql -c "SELECT count(*) FROM users"', next(n))
run("psql DROP against a localhost flag", "allow", REMOTE, 'psql -h localhost -c "DROP TABLE x"', next(n))

# Mentions are not commands.
run("echo of the command", "allow", REMOTE, 'echo "alembic upgrade head"', next(n))
run("rg for the verbs", "allow", REMOTE, "rg -n 'DROP TABLE|alembic upgrade' src/", next(n))
run("commit message", "allow", REMOTE, 'git commit -m "run alembic upgrade; then DROP TABLE x"', next(n))
run("heredoc body", "allow", REMOTE, "cat <<'EOF'\nalembic upgrade head\nEOF", next(n))
run("psql DROP only in an echo", "allow", REMOTE, 'echo "psql -c DROP TABLE users"', next(n))
run("a path that merely contains alembic", "allow", REMOTE, "ls backend/alembic/versions", next(n))

# Unresolvable host: a note, not a refusal.
run("no host anywhere", "warn", BARE, "alembic upgrade head", next(n))

# Heed: refused, then the same command with the host named.
sid = next(n)
run("heed setup refuses", "deny", REMOTE, "alembic upgrade head", sid)
run("heed: named re-run passes", "allow", REMOTE, "DB_TARGET_ACK=10.1.2.3 alembic upgrade head", sid)
rows = [json.loads(l) for l in open(WARN)] if os.path.exists(WARN) else []
if any(r.get("kind") == "heed" and r.get("heeded") == "true" and r.get("hook_id") == "guard-db-target" for r in rows):
    passed += 1
else:
    failed += 1
    print("FAIL heed row missing after the host was named")

drop_markers(*sids)
print(f"{passed} passed, {failed} failed")
sys.exit(1 if failed else 0)
