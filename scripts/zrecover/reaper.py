#!/usr/bin/env python3
"""zrecover reaper: the watchdog that stops one process from taking the Mac down.

Kills a process that balloons past a memory cap or is the biggest one when the
kernel reports memory pressure, and demotes (then, if the machine stays pinned,
kills) a sustained CPU hog. Only this user's processes, never system paths or
protected names. It also keeps the live-session snapshot that `zrecover restore`
replays after a crash. Design, thresholds and tuning: ~/.claude/features/zrecover.md

Usage (normally through `zrecover`):
  reaper.py status            current readings, top offenders, what it would do
  reaper.py run [--dry-run]   the daemon (the LaunchAgent runs this)
  reaper.py run --once        one full scan, then exit

Tuning: ~/.claude/scripts/zrecover/config.json overrides any key in DEFAULTS.
Pause:  touch ~/.claude/.no-zrecover   (the daemon idles while the file exists)
"""
import ctypes, ctypes.util, json, os, re, signal, sqlite3, struct, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
CONFIG = os.path.join(HERE, "config.json")
ROOT = os.path.expanduser("~/.claude/zrecover")
GRANTS = os.path.join(ROOT, "grants.json")
SESSIONS = os.path.join(ROOT, "sessions.json")
LAST_BOOT = os.path.join(ROOT, "last-boot.json")
STATE = os.path.join(ROOT, "daemon.json")
WRAPS = os.path.join(ROOT, "wraps")
SCREENS = os.path.join(ROOT, "screens")
IPC_DB = os.path.expanduser("~/.claude-ipc/data/ipc.sqlite")
LOG = os.path.expanduser("~/.claude/logs/zrecover.jsonl")
PAUSE_FILE = os.path.expanduser("~/.claude/.no-zrecover")
GB = 1024 ** 3

DEFAULTS = {
    "tick_s": 2,                 # pressure/load read cadence (sysctl only, no fork)
    "scan_every_s": 10,          # full process scan cadence
    # memory
    "warn_proc_gb": 12,          # notify once when a process passes this
    "kill_proc_gb": 24,          # kill any killable process past this (~37% of 64 GB)
    "pressure_warn_hold_s": 20,  # sustained kernel "warn" before acting
    "pressure_min_target_gb": 3, # on "warn", only kill a target at least this big
    "critical_min_target_gb": 1, # on "critical", act on anything this big
    "swap_warn_gb": 12,          # swap past this counts as "warn" pressure
    "after_kill_cooldown_s": 20, # let memory settle before the next pressure kill
    # cpu
    "cpu_demote_cores": 3.0,     # sustained cores used by one process
    "cpu_demote_after_s": 90,
    "cpu_kill_after_s": 600,     # after demotion, kill only if still hot this long
    "cpu_kill_load_ratio": 1.0,  # ...and loadavg(1m) / ncpu is at least this
    # freeze: the whole machine is pinned, so skip the demote ladder and kill the
    # top CPU consumer outright. Must land well inside the ~150 s WindowServer
    # watchdog that panics the kernel.
    "freeze_load_ratio": 1.5,    # loadavg(1m) / ncpu
    "freeze_hold_s": 30,
    "freeze_min_cores": 1.0,     # a target must itself be burning at least this
    "pressure_first": False,     # global default; rules below turn it on
    # grants (`zrecover allow`): a temporary higher cap for one run. Never above
    # grant_max_gb, and the pressure and freeze rules still apply, which is what
    # keeps the desktop alive when a granted process grows anyway.
    "grant_max_gb": 48,
    "sessions_every_s": 30,      # live-session snapshot cadence for `zrecover restore`
    "screens_keep_days": 14,
    "bundle_every_s": 900,       # resume bundle (markdown, one place to resume from)
    "bundles_keep_days": 14,
    # per-app overrides, first match wins; keys fall back to the globals above.
    # pressure_first: under memory pressure, shed these before the generic largest.
    "rules": [
        {"name": "ollama", "match": r"ollama|llama[-_]server|mlx_vlm|mlx_lm",
         "kill_proc_gb": 20, "pressure_first": True},
        {"name": "steam", "match": r"steam_osx|Steam Helper|/Steam/steamapps/",
         "warn_proc_gb": 10, "kill_proc_gb": 16, "cpu_demote_cores": 6,
         "cpu_demote_after_s": 30, "cpu_kill_after_s": 120, "pressure_first": True},
        # (?i): the CLT framework python shows up as "Python", venvs as "python3"
        {"name": "servers", "match": r"(?i)^(node|bun|python3?|next-server|uvicorn|vite|tsx|ts-node)\b",
         "kill_proc_gb": 8, "cpu_demote_cores": 4, "cpu_demote_after_s": 60,
         "cpu_kill_after_s": 180, "pressure_first": True},
    ],
    # identity
    "protected": [
        "claude", "codex", "ghostty", "Ghostty", "WindowServer", "loginwindow",
        "Finder", "Dock", "SystemUIServer", "ControlCenter", "launchd",
        "kernel_task", "sshd", "Switchboard", "Karabiner", "1Password",
        "reaper.py", "mem-guard.py", "dev-guard.mjs", "pm2", "tmux", "zellij",
        # the split session wrapper: killing keeper.py or hold.py costs a live session
        "keeper.py", "hold.py", "record.py", "client.py",
    ],
    "protected_paths": ["/System/", "/usr/libexec/", "/usr/sbin/", "/sbin/",
                        "/Library/Apple/", "/Library/SystemExtensions/"],
    "notify": True,
}

# sysctl via ctypes (no subprocess per tick)
_libc = ctypes.CDLL(ctypes.util.find_library("c"), use_errno=True)
_libproc = ctypes.CDLL("/usr/lib/libproc.dylib", use_errno=True)


def _sysctl_raw(name, size):
    buf = ctypes.create_string_buffer(size)
    n = ctypes.c_size_t(size)
    if _libc.sysctlbyname(name.encode(), buf, ctypes.byref(n), None, ctypes.c_size_t(0)) != 0:
        return None
    return buf.raw[:n.value]


def sysctl_int(name):
    raw = _sysctl_raw(name, 8)
    if raw is None:
        return None
    return int.from_bytes(raw, "little")


def pressure_level():
    """Kernel memory-pressure level: 1 normal, 2 warn, 4 critical."""
    return sysctl_int("kern.memorystatus_vm_pressure_level")


def swap_used_bytes():
    # struct xsw_usage { u64 total; u64 avail; u64 used; u32 pagesize; bool encrypted; }
    raw = _sysctl_raw("vm.swapusage", 32)
    return struct.unpack_from("<QQQ", raw)[2] if raw else 0


NCPU = sysctl_int("hw.ncpu") or os.cpu_count() or 8
MEMSIZE = sysctl_int("hw.memsize") or 64 * GB


def footprint_bytes(pid):
    """Physical footprint (resident + compressed), what Activity Monitor calls
    Memory. RSS undercounts a leaking process once the compressor holds it."""
    # rusage_info_v0: uuid[16], then u64 fields; ri_phys_footprint is the 8th.
    buf = ctypes.create_string_buffer(96)
    if _libproc.proc_pid_rusage(ctypes.c_int(pid), ctypes.c_int(0), buf) != 0:
        return None
    return struct.unpack_from("<Q", buf.raw, 16 + 8 * 7)[0]


# process table
def parse_cputime(s):
    days, rest = s.split("-", 1) if "-" in s else ("0", s)
    sec = 0.0
    for part in rest.split(":"):
        sec = sec * 60 + float(part)
    return sec + int(days) * 86400


def snapshot():
    """Own-uid processes: pid -> dict(ppid, cpu_s, mem, cmd)."""
    uid = os.getuid()
    out = subprocess.run(["ps", "-axo", "pid=,ppid=,uid=,cputime=,command="],
                         capture_output=True, text=True).stdout
    procs = {}
    for line in out.splitlines():
        m = re.match(r"\s*(\d+)\s+(\d+)\s+(\d+)\s+([\d:.\-]+)\s+(.*)$", line)
        if not m or int(m.group(3)) != uid:
            continue
        pid = int(m.group(1))
        mem = footprint_bytes(pid)
        if mem is None:
            continue
        procs[pid] = {"pid": pid, "ppid": int(m.group(2)), "cpu_s": parse_cputime(m.group(4)),
                      "mem": mem, "cmd": m.group(5)}
    return procs


def identity(cmd):
    """Basename of every token, so `/Users/x/Code/Claude/venv/bin/python` is not
    mistaken for a Claude session just because a path segment says Claude."""
    return " ".join(os.path.basename(t) if "/" in t else t for t in cmd.split())


def short(cmd, n=90):
    return identity(cmd)[:n]


# the watchdog
class Reaper:
    def __init__(self, cfg, dry_run=False):
        self.cfg = cfg
        self.dry = dry_run
        self.protected = re.compile(
            r"(^|\s)(" + "|".join(re.escape(p) for p in cfg["protected"]) + r")(\s|$|[.\-])")
        self.me = {os.getpid(), os.getppid()}
        self.prev_cpu = {}        # pid -> (cpu_s, wall)
        self.hot_since = {}       # pid -> wall when it first ran hot
        self.demoted_at = {}      # pid -> wall it was demoted
        self.warned = set()       # pids already warned about size
        self.warn_since = None    # wall when pressure "warn" began
        self.last_kill = 0.0
        self.last_scan = 0.0
        self.killed = set()       # pids killed this scan, so no later rule re-targets them
        self.freeze_since = None  # wall when load first crossed freeze_load_ratio
        self.rules = [(r, re.compile(r["match"])) for r in cfg.get("rules", [])]
        self.grants, self.grants_mtime = [], None
        self.last_sessions = 0.0
        self.last_bundle = 0.0

    def rule_for(self, p):
        # Rules match the full path too: a Steam game is only identifiable by
        # living under .../Steam/steamapps/. Over-matching a rule only tightens caps.
        ident = identity(p["cmd"])
        for r, rx in self.rules:
            if rx.search(ident) or rx.search(p["cmd"]):
                return r
        return None

    def reload_grants(self, now):
        try:
            mtime = os.stat(GRANTS).st_mtime
        except OSError:
            self.grants, self.grants_mtime = [], None
            return
        if mtime != self.grants_mtime:
            self.grants_mtime = mtime
            self.grants = [g for g in load_grants() if g["until"] > now]
            if not self.dry:
                log({"action": "grants-reloaded", "count": len(self.grants)})

    def grant_for(self, p):
        for g in self.grants:
            if g.get("pid") == p["pid"] or (g.get("match") and re.search(g["match"], p["cmd"])):
                return g
        return None

    def limit(self, p, key):
        g = self.grant_for(p)
        if g:
            if key in ("kill_proc_gb", "warn_proc_gb"):
                return min(g["gb"], self.cfg["grant_max_gb"])
            if key == "pressure_first":
                return False
        r = self.rule_for(p)
        return r[key] if r and key in r else self.cfg[key]

    # identity guard: the one place that decides "never touch this"
    def killable(self, p):
        if p["pid"] <= 1 or p["pid"] in self.me:
            return False
        exe = p["cmd"].split(" ", 1)[0]
        if any(exe.startswith(pp) for pp in self.cfg["protected_paths"]):
            return False
        return not self.protected.search(identity(p["cmd"]))

    def act(self, kind, p, reason, **extra):
        rec = {"action": kind, "pid": p["pid"], "mem_gb": round(p["mem"] / GB, 2),
               "cmd": p["cmd"][:240], "reason": reason, "dry_run": self.dry, **extra}
        if self.dry:
            log(rec)
            return True
        if kind == "kill":
            ok = kill(p["pid"])
            self.last_kill = time.time()
            self.killed.add(p["pid"])
        elif kind == "demote":
            ok = subprocess.run(["taskpolicy", "-b", "-p", str(p["pid"])],
                                capture_output=True).returncode == 0
        else:
            ok = True
        log({**rec, "ok": ok})
        if self.cfg["notify"]:
            notify(f"zrecover: {kind} {os.path.basename(p['cmd'].split(' ', 1)[0])}",
                   f"pid {p['pid']} · {rec['mem_gb']} GB · {reason}")
        return ok

    def scan(self, now, pressure, swap, load_ratio):
        procs = snapshot()
        c = self.cfg
        # forget pids that exited
        for d in (self.prev_cpu, self.hot_since, self.demoted_at):
            for pid in [k for k in d if k not in procs]:
                del d[pid]
        self.warned &= set(procs)
        self.killed.clear()

        self.reload_grants(now)
        cand = sorted((p for p in procs.values() if self.killable(p)), key=lambda p: -p["mem"])
        for p in cand:
            r = self.rule_for(p)
            p["rule"] = r["name"] if r else None
            if self.grant_for(p):
                p["rule"] = f"grant:{self.grant_for(p)['id']}"

        # 1. per-process memory cap
        for p in cand:
            kill_gb, warn_gb = self.limit(p, "kill_proc_gb"), self.limit(p, "warn_proc_gb")
            if p["mem"] >= kill_gb * GB:
                self.act("kill", p, f"footprint {p['mem'] / GB:.1f} GB >= {kill_gb} GB cap", rule=p["rule"])
            elif p["mem"] >= warn_gb * GB and p["pid"] not in self.warned:
                self.warned.add(p["pid"])
                self.act("warn-size", p, f"footprint {p['mem'] / GB:.1f} GB >= {warn_gb} GB", rule=p["rule"])

        # 2. system memory pressure: shed the largest killable process
        sustained_warn = self.warn_since is not None and now - self.warn_since >= c["pressure_warn_hold_s"]
        if now - self.last_kill >= c["after_kill_cooldown_s"]:
            floor = None
            if pressure is not None and pressure >= 4:
                floor = c["critical_min_target_gb"]
            elif sustained_warn:
                floor = c["pressure_min_target_gb"]
            if floor is not None:
                # pressure_first apps go ahead of the generic largest; granted ones go last
                order = sorted(cand, key=lambda p: (bool(self.grant_for(p)),
                                                    not self.limit(p, "pressure_first"), -p["mem"]))
                target = next((p for p in order if p["pid"] not in self.killed and p["mem"] >= floor * GB), None)
                why = f"pressure={pressure} swap={swap / GB:.1f}G"
                if target and alive(target["pid"]):
                    self.act("kill", target, why, rule=target["rule"])
                    self.warn_since = None
                else:
                    log({"action": "pressure-no-target", "reason": why})

        # 3. cpu rate per process since the last scan
        rates, prev_t = {}, {}
        for p in cand:
            pid = p["pid"]
            prev = self.prev_cpu.get(pid)
            self.prev_cpu[pid] = (p["cpu_s"], now)
            if prev and now - prev[1] > 0 and pid not in self.killed:
                rates[pid] = (p["cpu_s"] - prev[0]) / (now - prev[1])
                prev_t[pid] = prev[1]

        # 4. freeze: machine pinned for freeze_hold_s, kill the top burner outright
        if load_ratio >= c["freeze_load_ratio"]:
            if self.freeze_since is None:
                self.freeze_since = now
                log({"action": "freeze-warn", "load_ratio": round(load_ratio, 2)})
            if now - self.freeze_since >= c["freeze_hold_s"] and now - self.last_kill >= c["after_kill_cooldown_s"]:
                top = max(rates, key=rates.get, default=None)
                if top is not None and rates[top] >= c["freeze_min_cores"]:
                    p = procs[top]
                    self.act("kill", p, f"machine frozen: load/ncpu={load_ratio:.2f} for "
                                        f"{now - self.freeze_since:.0f}s, top burner at {rates[top]:.1f} cores",
                             cores=round(rates[top], 1), rule=p["rule"])
                else:
                    log({"action": "freeze-no-target", "load_ratio": round(load_ratio, 2)})
        else:
            self.freeze_since = None

        # 5. cpu hog: demote first, kill only if still hot and the machine stays saturated
        for p in cand:
            pid = p["pid"]
            if pid in self.killed or pid not in rates:
                continue
            cores = rates[pid]
            if cores < self.limit(p, "cpu_demote_cores"):
                self.hot_since.pop(pid, None)
                continue
            since = self.hot_since.setdefault(pid, prev_t[pid])
            if pid not in self.demoted_at and now - since >= self.limit(p, "cpu_demote_after_s"):
                self.demoted_at[pid] = now
                self.act("demote", p, f"{cores:.1f} cores for {now - since:.0f}s", cores=round(cores, 1), rule=p["rule"])
            elif (pid in self.demoted_at and now - self.demoted_at[pid] >= self.limit(p, "cpu_kill_after_s")
                  and load_ratio >= c["cpu_kill_load_ratio"]):
                self.act("kill", p, f"{cores:.1f} cores, still hot {now - self.demoted_at[pid]:.0f}s "
                                    f"after demotion, load/ncpu={load_ratio:.2f}", cores=round(cores, 1), rule=p["rule"])
                self.demoted_at.pop(pid, None)

        if now - self.last_sessions >= c["sessions_every_s"]:
            self.last_sessions = now
            try:
                live = write_sessions(procs)
                prune_screens(c["screens_keep_days"])
                if now - self.last_bundle >= c["bundle_every_s"]:
                    self.last_bundle = now
                    import sessions as sess
                    md = sess.write_bundle(live, boot_time(), c["bundles_keep_days"])
                    log({"action": "bundle", "path": md, "sessions": len(live)})
            except Exception as e:
                log({"action": "sessions-error", "err": repr(e)[:300]})
        return procs

    def tick(self, now):
        pressure = pressure_level()
        swap = swap_used_bytes()
        load_ratio = os.getloadavg()[0] / NCPU
        warn = (pressure is not None and pressure >= 2) or swap >= self.cfg["swap_warn_gb"] * GB
        if warn and self.warn_since is None:
            self.warn_since = now
            log({"action": "pressure-warn", "pressure": pressure, "swap_gb": round(swap / GB, 1)})
        elif not warn:
            self.warn_since = None
        urgent = pressure is not None and pressure >= 4
        if urgent or warn or now - self.last_scan >= self.cfg["scan_every_s"]:
            self.last_scan = now
            self.scan(now, pressure, swap, load_ratio)


# side effects
def alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


def kill(pid, grace_s=4.0):
    """SIGTERM, wait, SIGKILL. True once the process is gone."""
    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        return True
    except PermissionError:
        return False
    deadline = time.time() + grace_s
    while time.time() < deadline:
        if not alive(pid):
            return True
        time.sleep(0.2)
    try:
        os.kill(pid, signal.SIGKILL)
    except ProcessLookupError:
        return True
    time.sleep(0.3)
    return not alive(pid)


def notify(title, body):
    tn = "/opt/homebrew/bin/terminal-notifier"
    try:
        if os.path.exists(tn):
            subprocess.Popen([tn, "-title", title, "-message", body, "-group", "zrecover"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            subprocess.Popen(["osascript", "-e", f"display notification {json.dumps(body)} "
                              f"with title {json.dumps(title)}"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError:
        pass


def log(rec):
    rec = {"ts": time.strftime("%Y-%m-%dT%H:%M:%S"), **rec}
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    with open(LOG, "a") as f:
        f.write(json.dumps(rec) + "\n")


def load_grants():
    try:
        with open(GRANTS) as f:
            return json.load(f)
    except (OSError, ValueError):
        return []


def save_grants(grants):
    os.makedirs(ROOT, exist_ok=True)
    tmp = GRANTS + ".tmp"
    with open(tmp, "w") as f:
        json.dump(grants, f, indent=1)
    os.replace(tmp, GRANTS)


def boot_time():
    # struct timeval { i64 sec; i32 usec; }
    raw = _sysctl_raw("kern.boottime", 16)
    return struct.unpack_from("<q", raw)[0] if raw else 0


def ipc_sessions():
    """Claude sessions the IPC broker knows: pid -> row, newest registration per pid."""
    rows = {}
    try:
        db = sqlite3.connect(f"file:{IPC_DB}?mode=ro", uri=True, timeout=1.0)
        cur = db.execute("select alias, session_id, cwd, pid, tty, last_seen from registry_snapshot "
                         "where pid is not null and session_id not like 'svc:%' order by last_seen")
        for alias, sid, cwd, pid, tty, seen in cur:
            rows[int(pid)] = {"pid": int(pid), "alias": alias, "session_id": sid, "cwd": cwd,
                              "tty": tty, "last_seen": seen}
        db.close()
    except sqlite3.Error:
        pass
    return rows


def wrapped_sessions():
    out = {}
    try:
        names = os.listdir(WRAPS)
    except OSError:
        return out
    for n in names:
        try:
            with open(os.path.join(WRAPS, n)) as f:
                w = json.load(f)
            out[int(w["pid"])] = w
        except (OSError, ValueError, KeyError):
            pass
    return out


def write_sessions(procs):
    """The snapshot `zrecover restore` replays: every live claude session, with its
    resume id and, when it runs under `zrecover run`, its last screen file.
    Rolled over on the first write after a reboot so the pre-crash set survives."""
    boot = boot_time()
    try:
        with open(SESSIONS) as f:
            prev = json.load(f)
        if prev.get("boot") != boot:
            os.replace(SESSIONS, LAST_BOOT)
    except (OSError, ValueError):
        pass
    ipc, wraps = ipc_sessions(), wrapped_sessions()
    sessions = []
    for pid, p in procs.items():
        ident = identity(p["cmd"])
        if not re.match(r"claude(\s|$)", ident) or " -p " in f" {ident} ":
            continue
        row = {"pid": pid, "cmd": p["cmd"][:200], "started": None}
        row.update({k: v for k, v in ipc.get(pid, {}).items() if k != "pid"})
        w = wraps.get(pid)
        if w:
            row.update({"wrapped": True, "screen": w["screen"], "cwd": w.get("cwd") or row.get("cwd"),
                        "tty": w.get("tty") or row.get("tty"), "started": w.get("started")})
        sessions.append(row)
    os.makedirs(ROOT, exist_ok=True)
    tmp = SESSIONS + ".tmp"
    with open(tmp, "w") as f:
        json.dump({"boot": boot, "ts": time.time(), "sessions": sessions}, f, indent=1)
    os.replace(tmp, SESSIONS)
    return sessions


def prune_screens(keep_days):
    cutoff = time.time() - keep_days * 86400
    try:
        for n in os.listdir(SCREENS):
            p = os.path.join(SCREENS, n)
            if os.stat(p).st_mtime < cutoff:
                os.remove(p)
    except OSError:
        pass


def load_user_config():
    """The overrides file alone (empty dict when absent or unreadable)."""
    try:
        with open(CONFIG) as f:
            return json.load(f)
    except FileNotFoundError:
        return {}
    except (OSError, ValueError) as e:
        print(f"zrecover: ignoring unreadable {CONFIG}: {e}", file=sys.stderr)
        return {}


def save_user_config(user):
    tmp = CONFIG + ".tmp"
    with open(tmp, "w") as f:
        json.dump(user, f, indent=1)
    os.replace(tmp, CONFIG)


def load_config():
    cfg = dict(DEFAULTS)
    cfg.update(load_user_config())
    return cfg


# pause: the file holds an expiry epoch, or nothing for "until resumed"
def paused_until():
    """None when not paused; the expiry epoch (or float('inf')) when paused.
    An expired pause file is removed on the way out."""
    try:
        with open(PAUSE_FILE) as f:
            raw = f.read().strip()
    except OSError:
        return None
    if not raw:
        return float("inf")
    try:
        until = float(raw)
    except ValueError:
        return float("inf")
    if until <= time.time():
        try:
            os.remove(PAUSE_FILE)
        except OSError:
            pass
        return None
    return until


def write_state(rec):
    """Heartbeat for `zrecover status` and `doctor`: what the daemon saw last."""
    os.makedirs(ROOT, exist_ok=True)
    tmp = STATE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(rec, f)
    os.replace(tmp, STATE)


def read_state():
    try:
        with open(STATE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


# readings for the CLI (rendering lives in zrecover.py)
def readings():
    lvl = pressure_level()
    swap = swap_used_bytes()
    load1 = os.getloadavg()[0]
    until = paused_until()
    return {"pressure": lvl, "pressure_name": {1: "normal", 2: "warn", 4: "critical"}.get(lvl, str(lvl)),
            "swap_gb": round(swap / GB, 2), "load1": round(load1, 2), "ncpu": NCPU,
            "load_ratio": round(load1 / NCPU, 2), "ram_gb": round(MEMSIZE / GB),
            "paused": until is not None, "paused_until": None if until in (None, float("inf")) else until}


def verdict(r, p):
    """How the reaper sees one process: protected, a grant, a rule, or plain killable."""
    if not r.killable(p):
        return {"class": "protected"}
    g = r.grant_for(p)
    if g:
        return {"class": "grant", "grant": g["id"], "gb": g["gb"]}
    rule = r.rule_for(p)
    if rule:
        return {"class": "rule", "rule": rule["name"]}
    return {"class": "killable"}


def effective_limits(r, p):
    return {k: r.limit(p, k) for k in ("warn_proc_gb", "kill_proc_gb", "cpu_demote_cores",
                                       "cpu_demote_after_s", "cpu_kill_after_s", "pressure_first")}


def sample_procs(r, sample_s=1.0):
    """Own processes with a CPU rate measured over sample_s, each with its verdict."""
    procs = snapshot()
    first = {pid: p["cpu_s"] for pid, p in procs.items()}
    time.sleep(sample_s)
    procs = snapshot()
    r.reload_grants(time.time())
    rows = []
    for pid, p in procs.items():
        p["cores"] = round(max(0.0, p["cpu_s"] - first.get(pid, p["cpu_s"])) / sample_s, 2)
        p["mem_gb"] = round(p["mem"] / GB, 3)
        p["ident"] = short(p["cmd"], 120)
        p.update(verdict(r, p))
        rows.append(p)
    return rows


def plan(cfg):
    """A dry-run scan: every action the reaper would take right now, and why."""
    r = Reaper(cfg, dry_run=True)
    actions = []
    orig = globals()["log"]

    def capture(rec):
        if rec.get("action") in ("kill", "demote", "warn-size"):
            actions.append(rec)
    globals()["log"] = capture
    try:
        rd = readings()
        r.scan(time.time(), rd["pressure"], rd["swap_gb"] * GB, rd["load_ratio"])
        time.sleep(1.0)
        r.scan(time.time(), rd["pressure"], rd["swap_gb"] * GB, rd["load_ratio"])
    finally:
        globals()["log"] = orig
    return actions


def other_reaper_running():
    out = subprocess.run(["pgrep", "-f", "scripts/zrecover/reaper.py run"], capture_output=True, text=True)
    return any(int(x) != os.getpid() for x in out.stdout.split() if x.isdigit())


def run(cfg, dry_run, once):
    r = Reaper(cfg, dry_run=dry_run)
    if once:
        r.tick(time.time())
        return
    if other_reaper_running():
        print("zrecover reaper: already running; not starting a second")
        return
    log({"action": "start", "pid": os.getpid(), "dry_run": dry_run,
         "config": {k: v for k, v in cfg.items() if k not in ("protected", "protected_paths")}})
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    started = time.time()
    while True:
        now = time.time()
        until = paused_until()
        if until is None:
            try:
                r.tick(now)
            except Exception as e:  # a bad tick must never kill the watchdog
                log({"action": "tick-error", "err": repr(e)[:300]})
        try:
            write_state({"pid": os.getpid(), "started": started, "last_tick": now, "last_scan": r.last_scan,
                         "paused_until": None if until in (None, float("inf")) else until, "paused": until is not None,
                         "dry_run": dry_run, "grants": len(r.grants), "warn_since": r.warn_since,
                         "freeze_since": r.freeze_since})
        except OSError:
            pass
        time.sleep(cfg["tick_s"])


def main():
    a = sys.argv[1:]
    cfg = load_config()
    if not a or a[0] in ("-h", "--help", "help"):
        print(__doc__)
    elif a[0] == "status":
        print(json.dumps({"readings": readings(), "top": sorted(sample_procs(Reaper(cfg, dry_run=True)),
                                                                  key=lambda p: -p["mem"])[:10]}, indent=1))
    elif a[0] == "run":
        run(cfg, dry_run="--dry-run" in a, once="--once" in a)
    else:
        print(f"reaper: unknown command {a[0]!r} (status | run [--dry-run] [--once])", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
