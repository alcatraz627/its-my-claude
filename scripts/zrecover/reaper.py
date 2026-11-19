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
PROFILES = os.path.join(HERE, "profiles")
ROOT = os.path.expanduser("~/.claude/zrecover")
GRANTS = os.path.join(ROOT, "grants.json")
SLOWED = os.path.join(ROOT, "slowed.json")
SESSIONS =os.path.join(ROOT, "sessions.json")
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
    "freeze_min_share": 0.25,    # ...and hold this share of all CPU, or killing it changes nothing
    "freeze_warn_s": 45,         # notice before a non-urgent kill; hold + this + a scan stays inside the watchdog
    # A count limit, not a measure of whether a kill helped: on a saturated Mac neither CPU
    # nor the lagging load average can say that reliably.
    "freeze_kill_gap_s": 120,    # at least this long between CPU kills
    "freeze_max_kills": 2,       # ...and at most this many in freeze_kill_window_s
    "freeze_kill_window_s": 600, # a window, because load dipping for one scan must not end "a freeze"
    "countdown_gap_s": 150,      # a longer silence means the Mac slept, so the notice starts again
    "front_stale_s": 60,         # a failed frontmost lookup may reuse the last answer for this long
    "restore_below_ratio": 1.25, # load under this for restore_after_s ends a freeze's slowing
    "restore_after_s": 60,
    "lateness_log_every_s": 300, # tick lateness: a summary row on this cadence
    "lateness_alert_s": 5,       # ...and a row at once for a stall this long. Logged only, for now.
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
        "reaper.py", "mem-guard.py", "dev-guard.mjs", "pm2", "PM2", "tmux", "zellij",
        # the split session wrapper: killing keeper.py or hold.py costs a live session
        "keeper.py", "hold.py", "record.py", "client.py",
    ],
    "protected_paths": ["/System/", "/usr/libexec/", "/usr/sbin/", "/sbin/",
                        "/Library/Apple/", "/Library/SystemExtensions/"],
    # costly to lose but safe to slow: never killed, lowered in priority during a freeze
    "slow_only": [],
    "notify": True,
    # A named set of the settings above, from profiles/<name>.json (`zrecover profile`).
    "profile": None,
    "protected_add": [],         # names a profile adds to "protected"
    "warn_protected": False,     # notify when a protected app grows past the warn cap
    "guard_only": False,         # a Mac with no Claude Code: doctor skips the session extras
}

# Caps a profile may give as a share of this Mac's RAM, so one profile fits any size.
PERCENT_KEYS = {"warn_proc_pct": "warn_proc_gb", "kill_proc_pct": "kill_proc_gb",
                "swap_warn_pct": "swap_warn_gb", "grant_max_pct": "grant_max_gb"}

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


# The first ".app" on the path, so a Chrome tab, deep inside Chrome's own bundle, belongs to Chrome.
_APP_ROOT = re.compile(r"^(/(?:(?!\.app/).)*\.app)/")
# Only installed apps count: Python.app and Steam games also have Contents/MacOS.
_MAIN_APP = re.compile(r"^(?:/Applications|%s/Applications)/(?:(?!\.app/).)*\.app/Contents/MacOS/"
                       % re.escape(os.path.expanduser("~")))


def app_root(cmd):
    """The app bundle a process belongs to, or None for a plain program."""
    m = _APP_ROOT.match(cmd)
    return m.group(1) if m else None


def is_main_app(cmd):
    """True for an installed app's main process, the one that loses all its windows if killed."""
    return _MAIN_APP.match(cmd) is not None


def frontmost_pid():
    """The pid of the app in front of the owner, or None if macOS will not say."""
    try:
        asn = subprocess.run(["lsappinfo", "front"], capture_output=True, text=True, timeout=2).stdout.strip()
        if not asn:
            return None
        out = subprocess.run(["lsappinfo", "info", "-only", "pid", asn],
                             capture_output=True, text=True, timeout=2).stdout
    except (OSError, subprocess.SubprocessError):
        return None
    m = re.search(r'"?pid"?\s*=\s*(\d+)', out)
    return int(m.group(1)) if m else None


# the watchdog
class Reaper:
    def __init__(self, cfg, dry_run=False):
        self.cfg = cfg
        self.dry = dry_run
        self.protected = re.compile(
            r"(^|\s)(" + "|".join(re.escape(p) for p in cfg["protected"]) + r")(\s|$|[.\-])")
        # A bad hand-edited value must not stop the watchdog.
        raw = cfg.get("slow_only")
        slow = [x for x in raw if isinstance(x, str) and x] if isinstance(raw, list) else []
        self.slow_names = re.compile(
            r"(^|\s)(" + "|".join(re.escape(p) for p in slow) + r")(\s|$|[.\-])") if slow else None
        self.frontmost = frontmost_pid
        self.rates_all = {}       # pid -> cores, every own process, measured at the start of a scan
        self.procs = {}
        self.now = time.time()    # this scan's clock
        self.pending = {}         # pid -> {since, seen}: when its kill countdown began and was last renewed
        self.asked = set()        # pids whose countdown was renewed this scan
        self.slowed = {}          # pid -> (wall demoted, proc), only those a freeze slowed and will restore
        self.slow_refused = {}    # pid -> wall to try again, after taskpolicy refused
        self.calm_since = None    # wall load last fell under restore_below_ratio
        self.last_front = None    # (wall, answer) of the last frontmost lookup that worked
        self.front_stale = False  # this scan's frontmost answer is a reused one
        self.cpu_kills = []       # walls of recent CPU kills, for the count limit
        self.kill_failed = {}     # pid -> wall to try again, so one unkillable process blocks nothing
        self.pause_tried = False  # this pause's one try at giving priority back
        self.limit_logged = False
        self.no_target_logged = False
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
        self.front_cache = None   # this scan's frontmost app lookup, wrapped so "unknown" is cached too
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
            rows = load_grants()
            rows = rows if isinstance(rows, list) else []
            good = [g for g in rows if usable_grant(g)]
            if len(good) != len(rows):
                log({"action": "grants-ignored", "count": len(rows) - len(good)})
            self.grants = [g for g in good if g["until"] > now]
            if not self.dry:
                log({"action": "grants-reloaded", "count": len(self.grants)})

    def grant_matches(self, g, p):
        return g.get("pid") == p["pid"] or (g.get("match") and re.search(g["match"], p["cmd"]))

    def grant_for(self, p):
        """The memory grant covering a process. A class grant is not one."""
        for g in self.grants:
            # The file is only re-read when it changes, so expiry has to be checked here.
            if not g.get("class") and g["until"] > time.time() and self.grant_matches(g, p):
                return g
        return None

    def process_class(self, p):
        """What may be done to a process: protected (nothing), slow-only (lower its
        priority, never kill it) or restartable (lower its priority, then kill it)."""
        if p["pid"] <= 1 or p["pid"] in self.me:
            return "protected"
        exe = p["cmd"].split(" ", 1)[0]
        if any(exe.startswith(pp) for pp in self.cfg["protected_paths"]):
            return "protected"
        ident = identity(p["cmd"])
        if self.protected.search(ident):
            return "protected"
        for g in self.grants:
            if g.get("class") and g.get("until", 0) > time.time() and self.grant_matches(g, p):
                return g["class"]
        if self.slow_names and self.slow_names.search(ident):
            return "slow-only"
        return "restartable"

    def can_touch(self, p):
        """Whether the slowing rule may act on a process. Tests narrow this to their own children."""
        return True

    def front_app(self, procs):
        """The frontmost app as {pid, root}, looked up at most once a scan. One failed lookup
        reuses the last answer, because every CPU rule stops on "unknown". None if unknown."""
        if self.front_cache is None:
            try:
                pid = self.frontmost()
            except Exception:
                pid = None
            self.front_stale = False
            if pid is not None:
                cmd = (procs.get(pid) or {}).get("cmd", "")
                answer = {"pid": pid, "root": app_root(cmd)}
                self.last_front = (self.now, answer)
            elif self.last_front and self.now - self.last_front[0] <= self.cfg["front_stale_s"]:
                answer = self.last_front[1]
                self.front_stale = True
            else:
                answer = None
            self.front_cache = (answer,)
        return self.front_cache[0]

    def is_front(self, p, front):
        if front is None:
            return False
        root = app_root(p["cmd"])
        return p["pid"] == front["pid"] or (root is not None and root == front["root"])

    def cpu_exempt(self, p, front):
        """True when CPU alone must not kill this process: the main process of an installed
        app, or anything of the app the owner is using. If that app is unknown, nothing is
        safe to kill. Memory rules do not ask this, because running out of memory is the emergency."""
        return is_main_app(p["cmd"]) or front is None or self.is_front(p, front)

    def burners(self):
        """The five busiest processes of any class, so a log row shows what was really using the CPU."""
        top = sorted(self.rates_all.items(), key=lambda kv: -kv[1])[:5]
        out = []
        for pid, cores in top:
            p = self.procs.get(pid)
            if p:
                out.append({"pid": pid, "cores": round(cores, 1), "name": short(p["cmd"], 40),
                            "class": self.process_class(p)})
        return out

    def rate_total(self):
        return sum(self.rates_all.values())

    def cpu_kill_allowed(self, now):
        """Whether a new CPU kill countdown may start: at most freeze_max_kills in
        freeze_kill_window_s, spaced by freeze_kill_gap_s. The notice counts towards the gap,
        so the kill itself lands on time. This covers every CPU kill, freeze or ladder."""
        c = self.cfg
        self.cpu_kills = [t for t in self.cpu_kills if now - t < c["freeze_kill_window_s"]]
        if len(self.cpu_kills) >= c["freeze_max_kills"]:
            if not self.limit_logged:
                self.limit_logged = True
                log({"action": "freeze-kill-limit", "reason": f"{len(self.cpu_kills)} CPU kills in "
                     f"{c['freeze_kill_window_s']:.0f}s, no more for now", "burners": self.burners()})
            return False
        self.limit_logged = False
        if not self.cpu_kills:
            return True
        return now - self.cpu_kills[-1] >= c["freeze_kill_gap_s"] - c["freeze_warn_s"]

    def cpu_kill_done(self, now):
        """Count a CPU kill against the limit."""
        self.cpu_kills.append(now)

    def kill_after_notice(self, p, reason, now, **extra):
        """Kill a process once its countdown has run, telling the owner when it starts.
        Returns True only when the kill happened. A scan that stops asking calls it off."""
        pid, wait = p["pid"], self.cfg["freeze_warn_s"]
        self.asked.add(pid)
        entry = self.pending.get(pid)
        # A gap longer than the watchdog allows means the Mac slept, so the owner gets a fresh
        # notice. A shorter gap can be the very stall this rule exists for, so it must not restart.
        if entry is None or now - entry["seen"] > self.cfg["countdown_gap_s"]:
            entry = self.pending[pid] = {"since": now, "seen": now, "cores": extra.get("cores", 0)}
            if wait > 0:
                self.act("kill-countdown", p, f"{reason}; kill in {wait:.0f}s unless it clears", **extra)
                return False
        entry["seen"] = now
        # On a reused frontmost answer the owner may have just switched to this very app.
        if now - entry["since"] < wait or self.front_stale:
            return False
        self.pending.pop(pid, None)
        self.asked.discard(pid)
        ok = self.act("kill", p, reason, **extra)
        if not ok:
            self.kill_failed[pid] = now + 600
        return ok

    def end_countdowns(self, procs):
        """Call off any countdown no rule renewed this scan. In a freeze with the frontmost
        app unknown, nothing could renew them, so they wait rather than being called off."""
        for pid in [x for x in self.pending if x not in procs]:
            del self.pending[pid]
        for pid in [x for x in self.kill_failed if x not in procs]:
            del self.kill_failed[pid]
        if self.front_cache == (None,) and self.freeze_since is not None:
            return
        for pid in [x for x in self.pending if x not in self.asked]:
            del self.pending[pid]
            if pid in procs:
                self.act("kill-cancelled", procs[pid], "the condition cleared")

    def freeze_target(self, rates, procs, front):
        """Who a freeze may kill: burning enough, a real share of all CPU, and not exempt.
        A countdown already running goes first and has a lower bar, so a shifting top burner or
        a share that wobbles around the limit cannot keep restarting it, unless something
        burning at least twice as much appears: that one should not wait behind a small one."""
        c, total = self.cfg, self.rate_total()

        def worth_killing(pid, cores):
            entry = self.pending.get(pid)
            ease = 0.6 if entry else 1.0
            # Easing absorbs a wobble. A process that has mostly stopped burning has cleared.
            if entry and cores < entry["cores"] * 0.5:
                return False
            return (cores >= c["freeze_min_cores"] * ease and total > 0
                    and cores / total >= c["freeze_min_share"] * ease)

        fits = [pid for pid, cores in rates.items()
                if worth_killing(pid, cores) and not self.cpu_exempt(procs[pid], front)
                and self.kill_failed.get(pid, 0) <= self.now]
        if not fits:
            return None
        top = max(fits, key=lambda pid: rates[pid])
        running = [pid for pid in fits if pid in self.pending]
        if running:
            first = max(running, key=lambda pid: rates[pid])
            if rates[top] < 2 * rates[first]:
                return procs[first]
        return procs[top]

    def slow_down(self, procs, front, load_ratio):
        """During a freeze, lower the priority of what must not be killed. The frontmost app
        is left alone, and a main app only when the frontmost app is known not to be it."""
        min_cores = self.cfg["cpu_demote_cores"]
        for pid, cores in self.rates_all.items():
            p = procs.get(pid)
            if (p is None or pid in self.slowed or self.slow_refused.get(pid, 0) > self.now
                    or cores < min_cores or not self.can_touch(p)):
                continue
            cls = self.process_class(p)
            if not (cls == "slow-only" or (cls == "restartable" and is_main_app(p["cmd"]) and front is not None)):
                continue
            if self.is_front(p, front):
                continue
            # Recorded first: a stop signal can land while taskpolicy runs, and restore_all
            # can only give back what it knows about.
            if not self.dry:
                self.slowed[pid] = (time.time(), p)
                self.save_slowed()
            if not self.act("demote", p, f"{cores:.1f} cores in a freeze, load/ncpu={load_ratio:.2f}",
                            cores=round(cores, 1), rule=p.get("rule")):
                self.slowed.pop(pid, None)
                self.save_slowed()
                self.slow_refused[pid] = self.now + 300

    def restore_slowed(self, procs, now, load_ratio):
        """Give back the priority a freeze took: at once for an app that came to the front,
        and for the rest once load has stayed low for a while."""
        gone = [x for x in self.slowed if x not in procs]
        for pid in gone:
            del self.slowed[pid]
        if gone:
            self.save_slowed()
        for pid in [x for x in self.slow_refused if x not in procs]:
            del self.slow_refused[pid]
        if not self.slowed:
            self.calm_since = None
            return
        front = self.front_app(procs)
        for pid, (_, p) in list(self.slowed.items()):
            if self.is_front(p, front):
                self.restore(pid, "it came to the front")
        c = self.cfg
        if load_ratio >= c["restore_below_ratio"]:
            self.calm_since = None
            return
        if self.calm_since is None:
            self.calm_since = now
        if now - self.calm_since >= c["restore_after_s"]:
            for pid in list(self.slowed):
                self.restore(pid, f"load/ncpu={load_ratio:.2f}")
            self.calm_since = None   # anything taskpolicy refused is tried again after another calm wait

    def restore(self, pid, reason):
        """Give one process its priority back, keeping it on the list if taskpolicy refuses."""
        _, p = self.slowed[pid]
        if self.act("restore", p, reason):
            del self.slowed[pid]
            self.save_slowed()

    def save_slowed(self):
        """Keep the slowed pids on disk, so a daemon killed outright can give them back when
        it next starts. A reused pid does no harm: restoring a normal process changes nothing."""
        try:
            os.makedirs(os.path.dirname(SLOWED), exist_ok=True)
            tmp = SLOWED + ".tmp"
            with open(tmp, "w") as f:
                json.dump(list(self.slowed), f)
            os.replace(tmp, SLOWED)
        except OSError:
            pass

    def restore_all(self, reason="the daemon is stopping"):
        """Give everything back when the daemon leaves or is paused, one try each."""
        for pid in list(self.slowed):
            self.restore(pid, reason)

    def on_pause(self):
        """Stand down while paused: give back what was slowed, drop countdowns and start any
        freeze afresh. Pausing is how the owner says to leave a job alone. This runs on every
        paused tick, so a restore taskpolicy refuses gets one try, not a notice every 2 s."""
        self.pending.clear()
        self.freeze_since = None
        if self.slowed and not self.pause_tried:
            self.restore_all("zrecover is paused")
        self.pause_tried = True

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
        return self.process_class(p) == "restartable"

    def act(self, kind, p, reason, **extra):
        rec = {"action": kind, "pid": p["pid"], "mem_gb": round(p["mem"] / GB, 2),
               "cmd": p["cmd"][:240], "reason": reason, "dry_run": self.dry, **extra}
        if kind in ("kill", "demote", "restore", "kill-countdown"):
            rec["burners"] = self.burners()
        if self.dry:
            log(rec)
            return True
        if kind == "kill":
            ok = kill(p["pid"])
            self.last_kill = self.now
            self.killed.add(p["pid"])
        elif kind == "demote":
            ok = set_background(p["pid"], True)
        elif kind == "restore":
            ok = set_background(p["pid"], False)
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
        self.now = now
        self.pause_tried = False
        self.front_cache = None
        self.asked = set()
        self.procs = procs

        # cpu rate per process since the last scan, measured first so every row can name the burners
        self.rates_all, prev_t = {}, {}
        for pid, p in procs.items():
            prev = self.prev_cpu.get(pid)
            self.prev_cpu[pid] = (p["cpu_s"], now)
            if prev and now - prev[1] > 0:
                self.rates_all[pid] = max(0.0, (p["cpu_s"] - prev[0]) / (now - prev[1]))
                prev_t[pid] = prev[1]

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

        # A protected app is never touched, but its owner may want to hear it is growing.
        if c.get("warn_protected"):
            for p in procs.values():
                if (p["mem"] >= c["warn_proc_gb"] * GB and p["pid"] not in self.warned and p["pid"] not in self.me
                        and self.protected.search(identity(p["cmd"]))
                        and not any(p["cmd"].startswith(pp) for pp in c["protected_paths"])):
                    self.warned.add(p["pid"])
                    self.act("warn-size", p, f"footprint {p['mem'] / GB:.1f} GB, protected so left running")

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

        # 3. the CPU rates a kill may act on
        rates = {p["pid"]: self.rates_all[p["pid"]] for p in cand
                 if p["pid"] in self.rates_all and p["pid"] not in self.killed}

        # 4. freeze: machine pinned for freeze_hold_s, slow what can only be slowed, then
        # kill the top burner if that would help, after a notice
        if load_ratio >= c["freeze_load_ratio"]:
            if self.freeze_since is None:
                self.freeze_since = now
                log({"action": "freeze-warn", "load_ratio": round(load_ratio, 2)})
            if now - self.freeze_since >= c["freeze_hold_s"]:
                front = self.front_app(procs)
                self.slow_down(procs, front, load_ratio)
                if now - self.last_kill >= c["after_kill_cooldown_s"] and self.cpu_kill_allowed(now):
                    p = self.freeze_target(rates, procs, front)
                    if p is not None:
                        cores = rates[p["pid"]]
                        if self.kill_after_notice(p, f"machine frozen: load/ncpu={load_ratio:.2f} for "
                                                     f"{now - self.freeze_since:.0f}s, top burner at {cores:.1f} cores",
                                                  now, cores=round(cores, 1), rule=p["rule"]):
                            self.cpu_kill_done(now)
                    else:
                        rec = {"action": "freeze-no-target", "load_ratio": round(load_ratio, 2)}
                        # A first scan has no rates yet, so it must not use up this row.
                        burners = self.burners()
                        if burners and not self.no_target_logged:
                            self.no_target_logged = True
                            rec["burners"] = burners
                        log(rec)
        else:
            self.freeze_since = None
            self.no_target_logged = False

        # 5. cpu hog: demote first, kill only if still hot and the machine stays saturated
        for p in cand:
            pid = p["pid"]
            if pid in self.killed or pid not in rates:
                continue
            cores = rates[pid]
            if cores < self.limit(p, "cpu_demote_cores") or self.kill_failed.get(pid, 0) > now:
                self.hot_since.pop(pid, None)
                continue
            # A main app or the app in use only ever gets the freeze rule's slowing, which is
            # undone afterwards. This ladder's demotion lasts for the life of the process.
            front = self.front_app(procs)
            if front is None and not is_main_app(p["cmd"]):
                continue   # unknown is not exempt: hold everything until the lookup works again
            if self.cpu_exempt(p, front):
                self.hot_since.pop(pid, None)
                if self.demoted_at.pop(pid, None) is not None and not self.dry:
                    self.act("restore", p, "it is now exempt")
                continue
            since = self.hot_since.setdefault(pid, prev_t[pid])
            if pid not in self.demoted_at and now - since >= self.limit(p, "cpu_demote_after_s"):
                self.demoted_at[pid] = now
                self.act("demote", p, f"{cores:.1f} cores for {now - since:.0f}s", cores=round(cores, 1), rule=p["rule"])
            elif (pid in self.demoted_at and now - self.demoted_at[pid] >= self.limit(p, "cpu_kill_after_s")
                  and load_ratio >= c["cpu_kill_load_ratio"] and self.cpu_kill_allowed(now)):
                if self.kill_after_notice(p, f"{cores:.1f} cores, still hot {now - self.demoted_at[pid]:.0f}s "
                                             f"after demotion, load/ncpu={load_ratio:.2f}",
                                          now, cores=round(cores, 1), rule=p["rule"]):
                    self.demoted_at.pop(pid, None)
                    self.cpu_kill_done(now)

        self.end_countdowns(procs)
        self.restore_slowed(procs, now, load_ratio)

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
def set_background(pid, on):
    """Lower a process to background priority, or give its normal priority back."""
    return subprocess.run(["taskpolicy", "-b" if on else "-B", "-p", str(pid)],
                          capture_output=True).returncode == 0


def alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


def restore_left_behind():
    """Give back what a daemon killed outright left slowed. Called once, when one starts,
    and a bad file must never stop the watchdog from starting."""
    try:
        with open(SLOWED) as f:
            pids = json.load(f)
        for pid in pids if isinstance(pids, list) else []:
            if isinstance(pid, int) and pid > 1 and alive(pid):
                log({"action": "restore", "pid": pid, "ok": set_background(pid, False),
                     "reason": "left slowed by the last daemon"})
    except FileNotFoundError:   # the normal case: nothing was left behind
        return
    except Exception as e:
        log({"action": "tick-error", "err": repr(e)[:300]})
    try:
        os.remove(SLOWED)
    except OSError:
        pass


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


def usable_grant(g):
    """Whether a grants file row can be acted on. A bad row is skipped rather than
    allowed to raise inside a scan, which would switch off every rule while it exists."""
    if not isinstance(g, dict) or isinstance(g.get("until"), bool) or not isinstance(g.get("until"), (int, float)):
        return False
    if "class" in g:
        if g["class"] not in ("slow-only", "protected"):
            return False
    elif not isinstance(g.get("gb"), (int, float)):
        return False
    if "match" in g:
        try:
            re.compile(g["match"])
        except (re.error, TypeError):
            return False
    return True


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


def profile_names():
    try:
        return sorted(f[:-5] for f in os.listdir(PROFILES) if f.endswith(".json"))
    except OSError:
        return []


def load_profile(name):
    """One profile's settings, or nothing when no profile is set. A guard must still run
    on a bad profile, so a broken one is reported and the built-in settings apply."""
    if not name:
        return {}
    try:
        with open(os.path.join(PROFILES, f"{name}.json")) as f:
            return json.load(f)
    except (OSError, ValueError) as e:
        print(f"zrecover: ignoring profile {name!r}: {e}", file=sys.stderr)
        return {}


def apply_percents(block):
    """Turn caps given as a share of RAM into the gigabytes the reaper compares against."""
    for pct, gb in PERCENT_KEYS.items():
        if pct in block:
            block[gb] = round(block[pct] / 100.0 * MEMSIZE / GB, 1)


def load_config():
    """Settings in rising priority: built-in, then the chosen profile, then this Mac's overrides."""
    user = load_user_config()
    cfg = dict(DEFAULTS)
    # Each layer resolves its own percentages, so a cap this Mac sets in gigabytes
    # still beats a share of RAM from its profile.
    for layer in (load_profile(user.get("profile")), dict(user)):
        apply_percents(layer)
        cfg.update(layer)
    cfg["rules"] = [dict(r) for r in cfg.get("rules", [])]
    for rule in cfg["rules"]:
        apply_percents(rule)
    cfg["protected"] = list(cfg["protected"]) + [p for p in cfg.get("protected_add", []) if p not in cfg["protected"]]
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
    """How the reaper sees one process: protected, slow-only, a grant, a rule, or plain killable."""
    cls = r.process_class(p)
    if cls != "restartable":
        return {"class": cls}
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
        if rec.get("action") in ("kill", "demote", "warn-size", "kill-countdown"):
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


class TickLateness:
    """How late the daemon wakes from its sleep, which measures whether the machine is really
    stuck rather than merely busy. Recorded only, until a few days of rows show a threshold."""

    def __init__(self, every_s, alert_s):
        self.every_s, self.alert_s = every_s, alert_s
        self.samples, self.last = [], None

    def add(self, late_s, now, load_ratio):
        if self.last is None:
            self.last = now
        self.samples.append(late_s)
        if now - self.last >= self.every_s:
            s = sorted(self.samples)
            log({"action": "tick-lateness", "n": len(s), "p50_ms": round(s[len(s) // 2] * 1000),
                 "max_ms": round(s[-1] * 1000), "over_1s": sum(1 for x in s if x >= 1),
                 "load_ratio": round(load_ratio, 2),
                 "reason": f"p50 {s[len(s) // 2] * 1000:.0f} ms, max {s[-1] * 1000:.0f} ms over {len(s)} ticks"})
            self.samples, self.last = [], now
        if late_s >= self.alert_s:
            log({"action": "tick-lateness", "stall_s": round(late_s, 2), "load_ratio": round(load_ratio, 2),
                 "reason": f"woke {late_s:.1f}s late"})


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
    if not dry_run:
        restore_left_behind()
    started = time.time()
    lateness =TickLateness(cfg["lateness_log_every_s"], cfg["lateness_alert_s"])
    try:
        while True:
            now = time.time()
            until = paused_until()
            if until is None:
                try:
                    r.tick(now)
                except Exception as e:  # a bad tick must never kill the watchdog
                    log({"action": "tick-error", "err": repr(e)[:300]})
            else:
                try:
                    r.on_pause()
                except Exception as e:
                    log({"action": "tick-error", "err": repr(e)[:300]})
            try:
                write_state({"pid": os.getpid(), "started": started, "last_tick": now, "last_scan": r.last_scan,
                             "paused_until": None if until in (None, float("inf")) else until,
                             "paused": until is not None, "dry_run": dry_run, "grants": len(r.grants),
                             "warn_since": r.warn_since, "freeze_since": r.freeze_since})
            except OSError:
                pass
            # Only the sleep is timed, so a slow scan is not mistaken for a stuck machine.
            # monotonic does not count the Mac's own sleep, which would read as a huge stall.
            before = time.monotonic()
            time.sleep(cfg["tick_s"])
            try:
                lateness.add(max(0.0, time.monotonic() - before - cfg["tick_s"]), time.time(),
                             os.getloadavg()[0] / NCPU)
            except Exception:  # this only measures, so it must never stop the watchdog
                pass
    finally:
        signal.signal(signal.SIGTERM, signal.SIG_IGN)  # a second stop must not interrupt the restore
        r.restore_all()


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
