#!/usr/bin/env python3
"""Refuses a schema-changing database command whose target host is not local and
is not spelled out in the command.

The failure it stops: an agent runs `alembic upgrade` or a DROP believing the
database is a laptop one, while the project's .env points at a shared cloud
instance, and no command in the path prints a host. Four schema commands, one a
DROP COLUMN, ran against a live sandbox that way on 2026-09-04
(prop-20260904-024153-33). A warning already failed there, because the agent had
been told the database was shared and read it as news about someone else's change.
Naming the host is the step that was missing, so naming it is the way through.

PreToolUse on Bash. A command counts when it runs `alembic upgrade|downgrade`
(not with --sql, which only prints SQL), or runs psql, pgcli, mysql, mariadb or
usql with a DROP TABLE/COLUMN/SCHEMA/DATABASE or a TRUNCATE in its text. The
target host is read, in order, from the command (a URL, -h/--host, PGHOST=,
DATABASE_URL=), then from .env, alembic.ini and sibling files near the working
directory, then from this process's environment. A host is local when it is
localhost, a loopback address, 0.0.0.0, host.docker.internal, a unix socket path or
a single-label name (a compose service). Anything else must appear in the command
text, for example `DB_TARGET_ACK=db.example.com alembic upgrade head`. When no host
can be found the command passes with a note, because the guard cannot judge it.

Mentions are not commands: the verb must sit at a command position (quoted text and
heredoc bodies are blanked first), so an echo, an rg pattern or a commit message
that contains `alembic upgrade` or `DROP TABLE` does not fire.
Mute: touch ~/.claude/.no-db-target-gate
"""
import importlib.util, json, os, re, subprocess, sys

HOME = os.path.expanduser("~")
if os.path.exists(os.path.join(HOME, ".claude", ".no-db-target-gate")):
    sys.exit(0)
try:
    inp = json.load(sys.stdin)
except ValueError:
    sys.exit(0)
if not isinstance(inp, dict) or inp.get("tool_name") != "Bash":
    sys.exit(0)
cmd = (inp.get("tool_input") or {}).get("command") or ""
if not cmd.strip():
    sys.exit(0)

try:
    spec = importlib.util.spec_from_file_location("strip_payloads", os.path.join(HOME, ".claude/scripts/hooks/strip-payloads.py"))
    sp = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(sp)
    skeleton = sp.strip_payloads(cmd)
except Exception:
    skeleton = re.sub(r"'[^']*'|\"[^\"]*\"", "''", cmd)

POS = r"(?:^|[\n;&|(]|&&|\|\||\bthen\b|\bdo\b)\s*"
WRAP = r"(?:\w+=\S+\s+|(?:sudo|time|nohup|env)\s+|(?:uv|poetry|pipenv)\s+run\s+|python3?\s+-m\s+|docker\s+(?:compose\s+)?exec\s+(?:-\S+\s+)*\S+\s+|kubectl\s+exec\s+\S+\s+(?:-\S+\s+)*--\s+)*"
ALEMBIC = re.compile(POS + WRAP + r"(?:\S*/)?alembic\b([^\n;&|]*)", re.I)
SQLCLI = re.compile(POS + WRAP + r"(?:\S*/)?(psql|pgcli|mysql|mariadb|usql)\b([^\n;&|]*)", re.I)
DESTRUCTIVE = re.compile(r"\b(DROP\s+(?:TABLE|COLUMN|SCHEMA|DATABASE)|TRUNCATE)\b", re.I)

what = None
m = ALEMBIC.search(skeleton)
if m and re.search(r"\b(upgrade|downgrade)\b", m.group(1)) and "--sql" not in m.group(1):
    what = "alembic " + re.search(r"\b(upgrade|downgrade)\b", m.group(1)).group(1)
if what is None:
    m = SQLCLI.search(skeleton)
    if m:
        body = cmd
        f = re.search(r"(?:^|\s)(?:-f|--file)[=\s]+(\S+\.sql)\b", m.group(2))
        if f and os.path.isfile(os.path.expanduser(f.group(1))):
            try:
                body += "\n" + open(os.path.expanduser(f.group(1)), errors="replace").read()
            except OSError:
                pass
        d = DESTRUCTIVE.search(body)
        if d:
            what = "%s with %s" % (m.group(1).lower(), re.sub(r"\s+", " ", d.group(1).upper()))
if what is None:
    sys.exit(0)

URL_HOST = re.compile(r"[a-z][a-z0-9+.\-]*://(?:[^@/\s'\"]*@)?(\[[^\]]+\]|[^:/?#\s'\"]+)", re.I)
KEYS_URL = ("DATABASE_URL", "SQLALCHEMY_DATABASE_URI", "DB_URL", "POSTGRES_URL", "DATABASE_URI")
KEYS_HOST = ("PGHOST", "DB_HOST", "POSTGRES_HOST", "MYSQL_HOST", "DATABASE_HOST")


def host_of_url(text):
    u = URL_HOST.search(text or "")
    if not u:
        return None
    q = re.search(r"[?&]host=([^&\s'\"]+)", text)
    return (q.group(1) if q else u.group(1)).strip("[]")


def host_in_command():
    for pat in (r"(?:DATABASE_URL|SQLALCHEMY_DATABASE_URI|DB_URL|POSTGRES_URL)=(\S+)", r"-x\s+\w*url=(\S+)"):
        x = re.search(pat, cmd, re.I)
        if x and host_of_url(x.group(1)):
            return host_of_url(x.group(1))
    if host_of_url(cmd):
        return host_of_url(cmd)
    for pat in (r"\bPGHOST=(\S+)", r"(?:^|\s)(?:-h|--host)[=\s]+([^\s'\"]+)", r"\b(?:DB_HOST|POSTGRES_HOST|MYSQL_HOST)=(\S+)"):
        x = re.search(pat, cmd)
        if x:
            return x.group(1).strip("'\"")
    return None


def host_from_pairs(pairs):
    for k in KEYS_URL:
        if pairs.get(k) and host_of_url(pairs[k]):
            return host_of_url(pairs[k])
    for k in KEYS_HOST:
        if pairs.get(k):
            return pairs[k].strip("'\"")
    return None


def read_pairs(path):
    pairs = {}
    try:
        for line in open(path, errors="replace"):
            line = line.strip()
            if line.startswith("export "):
                line = line[7:]
            if "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                pairs[k.strip()] = v.strip().strip("'\"")
    except OSError:
        pass
    return pairs


def host_in_files():
    start = inp.get("cwd") or os.getcwd()
    cd = re.search(POS + r"cd\s+(\S+)", skeleton)
    if cd:
        target = os.path.expanduser(cd.group(1).strip("'\""))
        start = target if os.path.isabs(target) else os.path.join(start, target)
    c = re.search(r"(?:^|\s)-c\s+(\S+\.ini)\b", cmd)
    here = os.path.abspath(start)
    for _ in range(4):
        for rel in (".env", ".env.local", "backend/.env", ".env.development", "backend/.env.local"):
            h = host_from_pairs(read_pairs(os.path.join(here, rel)))
            if h:
                return h
        ini = [os.path.join(here, "alembic.ini"), os.path.join(here, "backend", "alembic.ini")]
        if c:
            ini.insert(0, c.group(1) if os.path.isabs(c.group(1)) else os.path.join(here, c.group(1)))
        for p in ini:
            if os.path.isfile(p):
                x = re.search(r"^\s*sqlalchemy\.url\s*=\s*(\S+)", open(p, errors="replace").read(), re.M)
                if x and host_of_url(x.group(1)):
                    return host_of_url(x.group(1))
        parent = os.path.dirname(here)
        if parent == here:
            break
        here = parent
    return None


def host_in_process_env():
    return host_from_pairs({k: os.environ.get(k, "") for k in KEYS_URL + KEYS_HOST})


def is_local(host):
    h = host.lower()
    if h in ("localhost", "0.0.0.0", "::1", "host.docker.internal", "") or h.startswith("127."):
        return True
    if h.startswith("/"):
        return not h.startswith("/cloudsql/")
    return "." not in h and ":" not in h


host = host_in_command() or host_in_files() or host_in_process_env()
LOG = os.path.join(HOME, ".claude/scripts/hooks/warn-log.sh")
sid8 = (inp.get("session_id") or "nosid")[:8]
mark = "/tmp/claude-dbtarget-%s" % sid8


def log_event(*args):
    subprocess.run(["bash", LOG, "--hook", "guard-db-target", *args], capture_output=True)


if not host:
    log_event("--action", "nudge", "--heeded", "unknown", "--detail", "unresolved host: " + what)
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext":
        "[db-target] This runs %s but I could not find which database host it targets (no URL or host in the command, "
        "no DATABASE_URL in .env or alembic.ini near the working directory). Say which database it hits before "
        "trusting the result." % what}}))
    sys.exit(0)

if is_local(host):
    sys.exit(0)

if host.lower() in cmd.lower():
    if os.path.exists(mark):
        log_event("--heed-of", "guard-db-target:" + sid8, "--heeded", "true")
        os.remove(mark)
    sys.exit(0)

open(mark, "w").write(host)
log_event("--action", "block", "--heeded", "unknown", "--detail", "%s on %s" % (what, host))
reason = ("[db-target] Refused: this runs %s against %s, which is not a local database and is not named in the "
          "command. The config points at it quietly and nothing in the path prints the host (4 schema commands hit a "
          "live sandbox that way on 2026-09-04). Confirm with the owner that %s is the intended target, then re-run "
          "with the host written in the command, for example `DB_TARGET_ACK=%s %s ...`. Do not rewrite the config to "
          "dodge this. Mute: touch ~/.claude/.no-db-target-gate") % (what, host, host, host, what.split()[0])
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
                                         "permissionDecisionReason": reason}}))
