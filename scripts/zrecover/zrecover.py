#!/usr/bin/env python3
"""zrecover: keep the desktop session alive, and get Claude sessions back after a crash.

The CLI. The reaper engine is reaper.py, the screen mirror is wrap.py; this file
only parses, renders and routes. Every data command takes --json; colour is off
when stdout is not a TTY, NO_COLOR is set or TERM is dumb. Exit 0 ok, 1 failed,
2 usage. Design and thresholds: ~/.claude/features/zrecover.md
"""
import json, os, re, shlex, shutil, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import reaper  # noqa: E402
import sessions as sess  # noqa: E402

VERSION = "0.4.0"
SELF = "zrecover"
LABEL = "com.alcatraz.zrecover"
PLIST = os.path.expanduser(f"~/Library/LaunchAgents/{LABEL}.plist")
VENV_PY = os.path.join(HERE, ".venv", "bin", "python")
ZSHRC = os.path.expanduser("~/.zshrc")
ALIAS_LINE = 'alias claude="zrecover run claude"'
GB = reaper.GB

try:
    sys.stdout.reconfigure(line_buffering=True)
except (AttributeError, ValueError):
    pass


# colour, gated once
class C:
    on = sys.stdout.isatty() and not os.environ.get("NO_COLOR") and os.environ.get("TERM") != "dumb"

    @classmethod
    def off(cls):
        cls.on = False

    @classmethod
    def _c(cls, code, s):
        return f"\033[{code}m{s}\033[0m" if cls.on else s

    @classmethod
    def b(cls, s): return cls._c("1", s)
    @classmethod
    def y(cls, s): return cls._c("1;33", s)
    @classmethod
    def c(cls, s): return cls._c("36", s)
    @classmethod
    def g(cls, s): return cls._c("32", s)
    @classmethod
    def r(cls, s): return cls._c("31", s)
    @classmethod
    def d(cls, s): return cls._c("2", s)


def sec(title):
    print(f"\n{C.y(title)}")


def row(left, right, colour=C.c, width=46):
    print(f"  {colour(left.ljust(width))} {C.d(right)}")


def ex(cmd, note):
    print(f"  {C.d('$')} {cmd.ljust(46)} {C.d('# ' + note) if note else ''}")


def die(msg, hint=None, code=1):
    print(f"{SELF}: {msg}", file=sys.stderr)
    if hint:
        print(f"  {hint}", file=sys.stderr)
    sys.exit(code)


def out_json(obj):
    print(json.dumps(obj, indent=1, default=str))


def ago(ts):
    if not ts:
        return "never"
    s = time.time() - ts
    return f"{s:.0f}s" if s < 90 else f"{s / 60:.0f}m" if s < 5400 else f"{s / 3600:.1f}h"


def left(ts):
    s = max(0.0, ts - time.time())
    return f"{s / 60:.0f} min" if s < 5400 else f"{s / 3600:.1f} h"


def parse_duration(s):
    m = re.fullmatch(r"(\d+(?:\.\d+)?)([smhd]?)", (s or "").strip())
    if not m:
        die(f"bad duration {s!r}", "use 90m, 2h or 1d", 2)
    return float(m.group(1)) * {"": 60, "s": 1, "m": 60, "h": 3600, "d": 86400}[m.group(2)]


def opt(a, name, default=None):
    return a[a.index(name) + 1] if name in a and a.index(name) + 1 < len(a) else default


def wants_help(a):
    return "-h" in a or "--help" in a


# help
def help_main():
    cfg = reaper.load_config()
    print(f"{C.b(SELF)} {C.d('— desktop-session safeguard: reaper, screen mirror, crash resume')}")
    sec("USAGE")
    print(f"  {C.c(SELF)} <command> [options]        {C.d('--json on any data command · --plain · -h per command')}")
    sec("EXAMPLES")
    ex("zrecover status", "pressure, daemon heartbeat, top offenders, grants")
    ex("zrecover plan", "what the reaper would do right now, and why")
    ex("zrecover explain Frostpunk", "which rule or grant applies, effective limits")
    ex("zrecover allow --match llama-server --gb 40 --for 3h", "one big run, desktop still protected")
    ex("zrecover run claude", "Claude with its screen mirrored (the `claude` alias)")
    ex("zrecover restore --open", "after a reboot: every session back in Ghostty")
    ex("zrecover log 20 --kind kill", "what it killed lately")
    sec("WATCH")
    row("status [--json]", "readings, daemon, top memory and CPU, grants")
    row("plan [--json]", "dry-run scan: the actions it would take now")
    row("top [-n N] [--by mem|cpu] [--json]", "every own process with its verdict")
    row("explain <pid|name> [--json]", "verdict and effective limits for one process")
    row("log [N] [--kind k,k] [--follow] [--json]", "action log (kill, demote, warn-size, pressure…)")
    sec("STEER")
    row("allow --match RE|--pid N --gb G [--for 2h]", f"temporary cap for one run (max {cfg['grant_max_gb']} GB)")
    row("grants [--json] · revoke <id|all>", "list or end grants")
    row("pause [--for 1h] · resume", "idle the reaper; a pause with no --for holds until resume")
    row("rules [--json]", "globals and per-app rules in force")
    row("protect list|add|rm <name>", "names the reaper never touches")
    row("config show|get|set|unset|path|edit", "overrides in config.json (daemon restart to apply)")
    sec("RECOVER")
    row("run [--name L] [--every S] -- <cmd>", "run a TUI with its screen mirrored to disk")
    row("sessions [--detail] [--json]", "live Claude sessions; --detail adds last prompt and reply")
    row("restore [--open] [--only 1,3] [--reconstruct]", "sessions from before the last reboot (restore -h)")
    row("bundle list|show [N|latest]|now", "the 15-min resume bundle: one markdown with everything")
    row("screens [--json] · screen <pid|alias|latest>", "captured screens, or print one")
    sec("MAINTAIN")
    row("daemon status|start|stop|restart|install|uninstall", f"the LaunchAgent {LABEL}")
    row("doctor [--json]", "check everything the suite depends on; exit 1 on any issue")
    row("test [--no-claude] · examples · help <topic> · version", "")
    print(f"\n  {C.d('topics: zrecover help crash|slow|big|alias   ·   doc: ~/.claude/features/zrecover.md')}")


def help_topic(t):
    if t in ("crash", "crashed", "reboot"):
        print(C.b("after a crash or reboot"))
        ex("zrecover restore", "what was open, with resume commands and screens")
        ex("zrecover restore --open", "reopen all of them in Ghostty")
        ex("zrecover screen latest", "the last captured screen (prompt-box draft included)")
        ex("zrecover log 30", "what the reaper saw before it went down")
    elif t in ("slow", "frozen", "lag"):
        print(C.b("the machine is slow right now"))
        ex("zrecover plan", "is the reaper about to act, on what")
        ex("zrecover top --by cpu", "who is burning cores")
        ex("zrecover top --by mem", "who is holding memory")
        ex("zrecover explain <pid>", "why that one is or is not a target")
    elif t in ("big", "model", "game", "grant"):
        print(C.b("a run that legitimately needs more memory"))
        ex("zrecover allow --match llama-server --gb 40 --for 3h", "by name")
        ex("zrecover allow --pid 72489 --gb 30", "by pid, 2h default")
        ex("zrecover grants", "see and time-check them")
        print(f"  {C.d('a grant lifts the per-process cap only; pressure and freeze rules still fire')}")
    elif t in ("alias", "claude", "wrap"):
        print(C.b("the claude alias"))
        print(f"  ~/.zshrc: {ALIAS_LINE}   {C.d('interactive only; scripts see the real binary')}")
        ex("command claude", "bypass the wrapper for one run")
        ex("zrecover run --name notes -- claude", "label a session for zrecover screens")
    else:
        die(f"no help topic {t!r}", "topics: crash · slow · big · alias", 2)


def examples():
    print(f"{C.b('zrecover examples')} {C.d('— every line is pasteable')}")
    sec("WATCH")
    ex("zrecover status --json | jq .readings", "machine readings as data")
    ex("zrecover top -n 15 --by cpu", "fifteen hottest processes")
    ex("zrecover plan --json", "would-act list for a script")
    ex("zrecover explain 'Steam Helper'", "verdict for a name (regex)")
    ex("zrecover log --follow", "tail the action log")
    sec("STEER")
    ex("zrecover allow --match Frostpunk --gb 30 --for 4h --note game", "")
    ex("zrecover pause --for 30m", "a benchmark you do not want interrupted")
    ex("zrecover protect add 'Final Cut'", "then: zrecover daemon restart")
    ex("zrecover config set kill_proc_gb 20", "then: zrecover daemon restart")
    sec("RECOVER")
    ex("zrecover sessions --json | jq '.sessions[].alias'", "")
    ex("zrecover restore --only 1,2 --dry-run", "show the open commands, run nothing")
    ex("zrecover screen enh-scrape-bug", "a session's screen by alias")
    sec("MAINTAIN")
    ex("zrecover doctor", "exit 1 if anything is wrong")
    ex("zrecover daemon restart", "after editing config")
    ex("zrecover test --no-claude", "fast tests only")


# WATCH
def daemon_state():
    st = reaper.read_state()
    alive = bool(st and reaper.alive(st["pid"]))
    fresh = bool(st and time.time() - st["last_tick"] < 3 * reaper.load_config()["tick_s"] + 5)
    return {"state": st, "alive": alive, "fresh": fresh}


def colour_pressure(name):
    return {"normal": C.g, "warn": C.y, "critical": C.r}.get(name, str)(name)


def tag(p):
    k = p["class"]
    if k == "protected":
        return C.d("protected    ")
    if k == "grant":
        return C.g(f"grant {p['gb']:.0f}G".ljust(13))
    if k == "rule":
        return C.c(f"rule:{p['rule']}".ljust(13))
    return "killable     "


def cmd_status(a):
    cfg = reaper.load_config()
    r = reaper.Reaper(cfg, dry_run=True)
    rd = reaper.readings()
    rows = reaper.sample_procs(r)
    grants = active_grants()
    dm = daemon_state()
    if "--json" in a:
        out_json({"readings": rd, "daemon": dm, "grants": grants,
                  "top_mem": sorted(rows, key=lambda p: -p["mem"])[:10],
                  "top_cpu": sorted(rows, key=lambda p: -p["cores"])[:10]})
        return
    paused = f"paused until {time.strftime('%H:%M', time.localtime(rd['paused_until']))}" if rd["paused_until"] \
        else C.y("PAUSED") if rd["paused"] else "active"
    print(f"{C.b(SELF)}  pressure {colour_pressure(rd['pressure_name'])}  swap {rd['swap_gb']:.1f}G  "
          f"load {rd['load1']:.1f}/{rd['ncpu']} ({rd['load_ratio']:.2f})  ram {rd['ram_gb']}G  {paused}")
    if dm["alive"]:
        st = dm["state"]
        print(f"  daemon pid {st['pid']} up {ago(st['started'])}, last tick {ago(st['last_tick'])} ago"
              + (C.d("  dry-run") if st.get("dry_run") else "")
              + ("" if dm["fresh"] else C.r("  STALE heartbeat")))
    else:
        print(C.r("  daemon not running") + C.d("   → zrecover daemon start"))
    print(C.d(f"  caps warn {cfg['warn_proc_gb']}G kill {cfg['kill_proc_gb']}G · cpu >{cfg['cpu_demote_cores']}c "
              f"{cfg['cpu_demote_after_s']}s demote, {cfg['cpu_kill_after_s']}s kill · freeze load/ncpu>"
              f"{cfg['freeze_load_ratio']} {cfg['freeze_hold_s']}s"))
    sec("top by memory")
    for p in sorted(rows, key=lambda p: -p["mem"])[:8]:
        print(f"  {tag(p)}  {p['mem_gb']:6.2f}G  {p['pid']:<6} {p['ident'][:80]}")
    sec("top by cpu (cores, 1 s sample)")
    for p in sorted(rows, key=lambda p: -p["cores"])[:5]:
        print(f"  {tag(p)}  {p['cores']:5.2f}c  {p['pid']:<6} {p['ident'][:80]}")
    sec("grants")
    print_grants(grants)


def cmd_plan(a):
    actions = reaper.plan(reaper.load_config())
    if "--json" in a:
        out_json({"would": actions})
        return
    if not actions:
        print(f"{C.g('nothing to do')} {C.d('— no process over a cap, no pressure, no sustained hog')}")
        return
    print(C.b(f"the reaper would take {len(actions)} action(s) now:"))
    for x in actions:
        print(f"  {C.r(x['action']):<10} pid {x['pid']:<6} {x['mem_gb']:.1f}G  {x['reason']}"
              + (C.d(f"  [{x['rule']}]") if x.get("rule") else ""))


def cmd_top(a):
    n = int(opt(a, "-n", 20))
    by = opt(a, "--by", "mem")
    if by not in ("mem", "cpu"):
        die(f"--by must be mem or cpu, not {by!r}", code=2)
    rows = reaper.sample_procs(reaper.Reaper(reaper.load_config(), dry_run=True))
    rows = sorted(rows, key=(lambda p: -p["mem"]) if by == "mem" else (lambda p: -p["cores"]))[:n]
    if "--json" in a:
        out_json(rows)
        return
    print(f"  {'verdict':<13}  {'mem':>7} {'cpu':>6}  {'pid':<6} command")
    for p in rows:
        print(f"  {tag(p)}  {p['mem_gb']:6.2f}G {p['cores']:5.2f}c  {p['pid']:<6} {p['ident'][:70]}")


def find_procs(needle):
    r = reaper.Reaper(reaper.load_config(), dry_run=True)
    r.reload_grants(time.time())
    procs = reaper.snapshot()
    # never report the CLI itself or the shell that launched it: their command
    # lines contain whatever pattern was typed
    for me in (os.getpid(), os.getppid()):
        procs.pop(me, None)
    if needle.isdigit():
        p = procs.get(int(needle))
        return r, [p] if p else []
    try:
        rx = re.compile(needle, re.I)
    except re.error as e:
        die(f"bad pattern: {e}", code=2)
    return r, [p for p in procs.values() if rx.search(p["cmd"])]


def cmd_explain(a):
    if not a or wants_help(a):
        die("usage: zrecover explain <pid|name-regex> [--json]", code=2)
    r, hits = find_procs(a[0])
    if not hits:
        die(f"no own process matches {a[0]!r}", "zrecover top lists them", 1)
    out = []
    for p in hits[:10]:
        v = reaper.verdict(r, p)
        out.append({"pid": p["pid"], "ident": reaper.short(p["cmd"], 120), "mem_gb": round(p["mem"] / GB, 2),
                    **v, "limits": reaper.effective_limits(r, p) if v["class"] != "protected" else None})
    if "--json" in a:
        out_json(out)
        return
    for o in out:
        print(f"{C.b(str(o['pid']))}  {o['ident'][:90]}")
        why = f" ({o.get('rule') or o.get('grant')})" if o.get("rule") or o.get("grant") else ""
        print(f"  {o['mem_gb']:.2f} GB now · verdict {C.c(o['class'])}{why}")
        if o["limits"]:
            L = o["limits"]
            print(C.d(f"  warn {L['warn_proc_gb']}G · kill {L['kill_proc_gb']}G · cpu >{L['cpu_demote_cores']}c for "
                      f"{L['cpu_demote_after_s']}s demote, +{L['cpu_kill_after_s']}s kill · "
                      f"{'shed first' if L['pressure_first'] else 'shed by size'} under pressure"))
        else:
            print(C.d("  never touched (protected name or system path)"))
    if len(hits) > 10:
        print(C.d(f"  …and {len(hits) - 10} more; narrow the pattern"))


def fmt_log(x):
    act = x.get("action", "?")
    col = C.r if act == "kill" else C.y if act in ("demote", "warn-size", "pressure-warn", "freeze-warn") else C.d
    extra = ""
    if act == "start":
        extra = f" pid {x.get('pid')}" + (" dry-run" if x.get("dry_run") else "")
    elif "pid" in x:
        extra = f" pid {x['pid']} {x.get('mem_gb', 0):.1f}G {reaper.short(x.get('cmd', ''), 60)}"
    if x.get("reason"):
        extra += f"  {C.d(x['reason'])}"
    return f"{C.d(x.get('ts', ''))} {col(act.ljust(14))}{extra}"


def cmd_log(a):
    n = next((int(x) for x in a if x.isdigit()), 20)
    kinds = set(opt(a, "--kind", "").split(",")) - {""}
    try:
        with open(reaper.LOG) as f:
            lines = f.readlines()
    except OSError:
        die("no log yet", f"the daemon writes {reaper.LOG}; zrecover daemon status", 1)
    recs = []
    for ln in lines:
        try:
            recs.append(json.loads(ln))
        except ValueError:
            pass
    if kinds:
        recs = [x for x in recs if x.get("action") in kinds]
    recs = recs[-n:]
    if "--json" in a:
        out_json(recs)
    else:
        for x in recs:
            print(fmt_log(x))
    if "--follow" in a:
        with open(reaper.LOG) as f:
            f.seek(0, 2)
            try:
                while True:
                    ln = f.readline()
                    if not ln:
                        time.sleep(0.5)
                        continue
                    try:
                        x = json.loads(ln)
                    except ValueError:
                        continue
                    if not kinds or x.get("action") in kinds:
                        print(fmt_log(x))
            except KeyboardInterrupt:
                pass


# STEER
def active_grants():
    now = time.time()
    return [g for g in reaper.load_grants() if g["until"] > now]


def print_grants(grants):
    if not grants:
        print(C.d("  none"))
    for g in grants:
        who = f"pid {g['pid']}" if "pid" in g else g["match"]
        print(f"  {C.c(g['id'])}  {who:<36} {g['gb']:.0f} GB  {left(g['until'])} left  {C.d(g.get('note', ''))}")


def cmd_allow(a):
    if not a or wants_help(a):
        print(f"{C.b('zrecover allow')} --match RE | --pid N  --gb G  [--for 2h] [--note text] [--json]")
        print(C.d("  lifts the memory cap for the match, up to grant_max_gb; pressure and freeze rules still apply"))
        sys.exit(0 if a else 2)
    match, pid, gb = opt(a, "--match"), opt(a, "--pid"), opt(a, "--gb")
    if not gb or not (match or pid):
        die("need --gb and one of --match RE / --pid N", "zrecover allow -h", 2)
    if match:
        try:
            re.compile(match)
        except re.error as e:
            die(f"bad --match: {e}", code=2)
    if pid and not reaper.alive(int(pid)):
        die(f"pid {pid} is not running", "zrecover top", 1)
    cfg = reaper.load_config()
    gb = float(gb)
    if gb > cfg["grant_max_gb"]:
        print(f"{SELF}: {gb:.0f} GB capped at grant_max_gb={cfg['grant_max_gb']}", file=sys.stderr)
        gb = cfg["grant_max_gb"]
    now = time.time()
    g = {"id": time.strftime("%H%M%S"), "gb": gb, "until": now + parse_duration(opt(a, "--for", "2h")),
         "note": opt(a, "--note", ""), "created": now}
    if match:
        g["match"] = match
    if pid:
        g["pid"] = int(pid)
    reaper.save_grants(active_grants() + [g])
    if "--json" in a:
        out_json(g)
        return
    print(f"granted {C.c(g['id'])}: {'pid ' + pid if pid else match} may use up to {gb:.0f} GB until "
          f"{time.strftime('%H:%M', time.localtime(g['until']))}. {C.d('zrecover revoke ' + g['id'] + ' to end early.')}")
    if not daemon_state()["alive"]:
        print(C.y("  note: the daemon is not running, so nothing is enforced right now"))


def cmd_revoke(a):
    if not a or wants_help(a):
        die("usage: zrecover revoke <id|all>", "zrecover grants", 2)
    grants = reaper.load_grants()
    if a[0] == "all":
        reaper.save_grants([])
        print(f"revoked {len(grants)} grant(s)")
        return
    keep = [g for g in grants if g["id"] != a[0]]
    if len(keep) == len(grants):
        die(f"no grant {a[0]}", "zrecover grants", 1)
    reaper.save_grants(keep)
    print(f"revoked {a[0]}")


def cmd_grants(a):
    grants = active_grants()
    if "--json" in a:
        out_json(grants)
    else:
        print_grants(grants)


def cmd_pause(a):
    until = time.time() + parse_duration(opt(a, "--for")) if "--for" in a else None
    os.makedirs(os.path.dirname(reaper.PAUSE_FILE), exist_ok=True)
    with open(reaper.PAUSE_FILE, "w") as f:
        f.write(f"{until:.0f}" if until else "")
    print("paused " + (f"until {time.strftime('%H:%M', time.localtime(until))}" if until else "until `zrecover resume`")
          + C.d(f"  ({reaper.PAUSE_FILE})"))


def cmd_resume(_a):
    try:
        os.remove(reaper.PAUSE_FILE)
        print("resumed")
    except FileNotFoundError:
        print("not paused")


GLOBAL_KEYS = ("warn_proc_gb", "kill_proc_gb", "pressure_warn_hold_s", "pressure_min_target_gb",
               "critical_min_target_gb", "swap_warn_gb", "cpu_demote_cores", "cpu_demote_after_s",
               "cpu_kill_after_s", "cpu_kill_load_ratio", "freeze_load_ratio", "freeze_hold_s", "grant_max_gb")


def cmd_rules(a):
    cfg = reaper.load_config()
    glob = {k: cfg[k] for k in GLOBAL_KEYS}
    if "--json" in a:
        out_json({"globals": glob, "rules": cfg["rules"], "protected": cfg["protected"],
                  "protected_paths": cfg["protected_paths"]})
        return
    sec("globals")
    for k, v in glob.items():
        row(k, str(v), C.g, 26)
    sec("per-app rules (first match wins; matched on identity and full path)")
    for r in cfg["rules"]:
        over = {k: v for k, v in r.items() if k not in ("name", "match")}
        print(f"  {C.c(r['name'].ljust(10))} {C.d(r['match'])}")
        print(f"  {'':<10} {', '.join(f'{k}={v}' for k, v in over.items())}")
    sec("protected names")
    print("  " + ", ".join(cfg["protected"]))
    print(C.d("  paths: " + ", ".join(cfg["protected_paths"])))


def cmd_protect(a):
    cfg = reaper.load_config()
    user = reaper.load_user_config()
    names = list(user.get("protected", cfg["protected"]))
    sub = a[0] if a else "list"
    if sub == "list":
        print("\n".join(names))
    elif sub in ("add", "rm") and len(a) > 1:
        name = a[1]
        if sub == "add":
            if name in names:
                die(f"{name!r} is already protected", code=1)
            names.append(name)
        else:
            if name not in names:
                die(f"{name!r} is not in the list", "zrecover protect list", 1)
            names.remove(name)
        user["protected"] = names
        reaper.save_user_config(user)
        print(f"{sub} {name}: {len(names)} protected names. {C.d('zrecover daemon restart to apply')}")
    else:
        die("usage: zrecover protect list | add <name> | rm <name>", code=2)


def cmd_config(a):
    sub = a[0] if a else "show"
    user = reaper.load_user_config()
    if sub == "path":
        print(reaper.CONFIG)
    elif sub == "show":
        cfg = reaper.load_config()
        if "--json" in a:
            out_json({"effective": cfg, "overrides": user, "path": reaper.CONFIG})
            return
        print(C.d(f"# effective config; * = set in {reaper.CONFIG}"))
        for k, v in cfg.items():
            mark = C.y("*") if k in user else " "
            shown = f"[{len(v)} items]" if isinstance(v, list) else json.dumps(v)
            print(f"{mark} {C.g(k.ljust(24))} {shown}")
    elif sub == "get" and len(a) > 1:
        cfg = reaper.load_config()
        if a[1] not in cfg:
            die(f"no key {a[1]!r}", "zrecover config show", 1)
        print(json.dumps(cfg[a[1]]))
    elif sub == "set" and len(a) > 2:
        key, raw = a[1], a[2]
        if key not in reaper.DEFAULTS:
            die(f"no key {key!r}", "zrecover config show lists them", 2)
        try:
            val = json.loads(raw)
        except ValueError:
            val = raw
        want = type(reaper.DEFAULTS[key])
        if want is float and isinstance(val, int):
            val = float(val)
        if want is int and isinstance(val, float) and val.is_integer():
            val = int(val)
        if not isinstance(val, want) or isinstance(val, bool) is not (want is bool):
            die(f"{key} wants {want.__name__}, got {type(val).__name__}", code=2)
        user[key] = val
        reaper.save_user_config(user)
        print(f"{key} = {json.dumps(val)}  {C.d('zrecover daemon restart to apply')}")
    elif sub == "unset" and len(a) > 1:
        if a[1] not in user:
            die(f"{a[1]!r} is not overridden", "zrecover config show", 1)
        del user[a[1]]
        reaper.save_user_config(user)
        print(f"{a[1]} back to default {json.dumps(reaper.DEFAULTS[a[1]])}  {C.d('zrecover daemon restart to apply')}")
    elif sub == "edit":
        ed = os.environ.get("VISUAL") or os.environ.get("EDITOR") or "nano"
        os.execvp(ed, [ed, reaper.CONFIG])
    else:
        die("usage: zrecover config show|get <k>|set <k> <v>|unset <k>|path|edit", code=2)


# RECOVER
def python_for_wrap():
    """Resolver: $ZRECOVER_PY → the suite venv → none (the caller falls back to a bare exec)."""
    cand = os.environ.get("ZRECOVER_PY")
    if cand and os.path.exists(cand):
        return cand
    if os.path.exists(VENV_PY):
        return VENV_PY
    return None


def cmd_run(a):
    if not a or wants_help(a):
        print(f"{C.b('zrecover run')} [--name LABEL] [--every SECONDS] -- <command> [args]")
        print(C.d("  passes the terminal straight through and mirrors the screen to ~/.claude/zrecover/screens/<pid>.txt"))
        sys.exit(0 if a else 2)
    py = python_for_wrap()
    if not py:
        print(f"{SELF}: no python with pyte (set ZRECOVER_PY, or: uv venv {HERE}/.venv; uv pip install pyte); "
              "running bare", file=sys.stderr)
        cmd = a[a.index("--") + 1:] if "--" in a else a
        os.execvp(cmd[0], cmd)
    args = a if ("--" in a or a[0].startswith("--")) else ["--"] + a
    os.execv(py, [py, os.path.join(HERE, "wrap.py")] + args)


def load_snapshot(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def resume_cmd(s):
    return sess.resume_command(s.get("cwd"), s.get("session_id"))


def print_sessions(snap, title, detail=False):
    if not snap:
        print(f"{title}: {C.d('no snapshot yet')}")
        return []
    when = snap.get("ts")
    head = ("written " + ago(when) + " ago, ") if when else ""
    print(f"{C.b(title)} {C.d(head + 'boot ' + time.strftime('%Y-%m-%d %H:%M', time.localtime(snap['boot'])))}")
    rows = snap["sessions"]
    for i, s in enumerate(rows, 1):
        kind = C.g("wrapped") if s.get("wrapped") else C.y("rebuilt") if s.get("reconstructed") else C.d("bare   ")
        print(f"  {i:>2}. {kind}  {(s.get('alias') or (s.get('session_id') or '?')[:8]):<28} {s.get('cwd') or '?'}")
        print(f"       {C.c(resume_cmd(s))}")
        t = s.get("transcript") or {}
        if detail and t.get("mtime"):
            print(f"       {C.d('last activity ' + time.strftime('%m-%d %H:%M', time.localtime(t['mtime'])))}")
        if detail and t.get("last_user"):
            print(f"       {C.d('prompt: ' + sess.excerpt(t['last_user'], 110))}")
        if detail and t.get("last_assistant"):
            print(f"       {C.d('reply:  ' + sess.excerpt(t['last_assistant'], 110))}")
        if s.get("screen") and os.path.exists(s["screen"]):
            print(f"       {C.d('screen: ' + s['screen'])}")
    if not rows:
        print(C.d("  (none)"))
    return rows


def cmd_sessions(a):
    snap = load_snapshot(reaper.SESSIONS)
    if "--detail" in a and snap:
        snap["sessions"] = [sess.enrich(dict(s)) for s in snap["sessions"]]
    if "--json" in a:
        out_json(snap or {"sessions": []})
        return
    print_sessions(snap, "live sessions", detail="--detail" in a)


def cmd_bundle(a):
    sub = a[0] if a and not a[0].startswith("-") else "list"
    if sub == "now":
        live = (load_snapshot(reaper.SESSIONS) or {"sessions": []})["sessions"]
        md = sess.write_bundle(live, reaper.boot_time(), reaper.load_config()["bundles_keep_days"])
        print(md if "--json" not in a else json.dumps({"path": md, "sessions": len(live)}))
        return
    if sub == "show":
        bundles = sess.list_bundles()
        want = a[1] if len(a) > 1 else "latest"
        if want == "latest":
            hit = bundles[-1] if bundles else None
        elif want.isdigit():
            hit = bundles[int(want) - 1] if 0 < int(want) <= len(bundles) else None
        else:
            hit = next((b for b in bundles if want in os.path.basename(b["md"])), None)
        if not hit:
            die(f"no bundle {want!r}", "zrecover bundle list", 1)
        with open(hit["path"] if "--json" in a else hit["md"]) as f:
            sys.stdout.write(f.read())
        return
    if sub == "list":
        bundles = sess.list_bundles()
        if "--json" in a:
            out_json(bundles)
            return
        if not bundles:
            print(C.d("no bundles yet; the daemon writes one every 15 min, or: zrecover bundle now"))
            return
        boot = reaper.boot_time()
        for i, b in enumerate(bundles, 1):
            mark = "" if b["boot"] == boot else C.y("  previous boot")
            print(f"  {i:>3}. {time.strftime('%Y-%m-%d %H:%M', time.localtime(b['ts']))}  {b['count']} session(s)  "
                  f"{C.d(b['md'])}{mark}")
        print(C.d(f"\n  zrecover bundle show [N|latest] · latest: {os.path.join(sess.BUNDLES, 'latest.md')}"))
        return
    die("usage: zrecover bundle list | show [N|latest] | now", code=2)


def crash_snapshot(a):
    """Where restore gets its rows: --from FILE, else last-boot.json, else the newest
    bundle from a previous boot, else --reconstruct from transcripts and the registry."""
    boot = reaper.boot_time()
    if "--from" in a:
        return load_snapshot(opt(a, "--from")), f"from {opt(a, '--from')}"
    if "--reconstruct" in a:
        before = time.mktime(time.strptime(opt(a, "--before"), "%Y-%m-%d %H:%M")) if "--before" in a \
            else (sess.latest_panic_ts() or boot)
        hours = float(opt(a, "--hours", 12))
        live = {s.get("session_id") for s in (load_snapshot(reaper.SESSIONS) or {"sessions": []})["sessions"]}
        ipc = reaper.ipc_sessions()
        succeeded = set()
        try:
            import sqlite3
            db = sqlite3.connect(f"file:{reaper.IPC_DB}?mode=ro", uri=True, timeout=1)
            succeeded = {r[0] for r in db.execute("select succeeded_sid from registry_snapshot where succeeded_sid is not null")}
            db.close()
        except Exception:
            pass
        rows = sess.sessions_before_crash(before, hours, ipc, exclude_sids=live | succeeded)
        return {"boot": before, "sessions": rows}, (f"rebuilt from transcripts active in the {hours:g} h before "
                                                   f"{time.strftime('%Y-%m-%d %H:%M', time.localtime(before))}")
    snap = load_snapshot(reaper.LAST_BOOT)
    if snap:
        return snap, "last-boot snapshot"
    b = sess.last_bundle_before_boot(boot)
    if b:
        return load_snapshot(b["path"]), f"bundle {os.path.basename(b['md'])}"
    return None, "nothing recorded before this boot; try --reconstruct"


def cmd_restore(a):
    if wants_help(a):
        print(f"{C.b('zrecover restore')} [--open] [--only 1,3] [--dry-run] [--detail] [--json]")
        print(f"{' ' * 17}[--from FILE] [--reconstruct [--before 'YYYY-MM-DD HH:MM'] [--hours 12]]")
        print(C.d("  sources, in order: --from · last-boot.json · newest bundle from a previous boot · --reconstruct"))
        return
    snap, source = crash_snapshot(a)
    if "--json" in a:
        out_json({"source": source, **(snap or {"sessions": []})})
        return
    rows = print_sessions(snap, f"sessions before the last reboot ({source})", detail="--detail" in a or "--reconstruct" in a)
    if not rows:
        if snap is None:
            print(C.d(f"  {source}"))
        return
    chosen = rows
    pick = opt(a, "--only")
    if pick:
        try:
            idx = sorted({int(x) for x in pick.split(",")})
        except ValueError:
            die("--only wants numbers from the list, like 1,3", code=2)
        chosen = [rows[i - 1] for i in idx if 0 < i <= len(rows)]
    if "--open" in a or "--dry-run" in a:
        print()
        for s in chosen:
            argv = ["open", "-na", "Ghostty.app", "--args",
                    f"--working-directory={s.get('cwd') or os.path.expanduser('~')}", "-e", "zsh", "-ic", resume_cmd(s)]
            if "--dry-run" in a:
                print("  " + " ".join(shlex.quote(x) for x in argv))
            else:
                subprocess.Popen(argv)
                time.sleep(0.8)
        if "--dry-run" not in a:
            print(f"opened {len(chosen)} Ghostty window(s) {C.d('(a second Ghostty instance; it quits when they close)')}")
    else:
        print(C.d("\n  --open launches them in Ghostty · --only 1,3 picks · --dry-run shows the commands"))


def screens_list():
    out = []
    try:
        names = os.listdir(reaper.SCREENS)
    except OSError:
        return out
    wraps = reaper.wrapped_sessions()
    snap = load_snapshot(reaper.SESSIONS) or {"sessions": []}
    alias_by_pid = {s["pid"]: s.get("alias") for s in snap["sessions"]}
    for n in names:
        if not n.endswith(".txt"):
            continue
        p = os.path.join(reaper.SCREENS, n)
        pid = int(n[:-4]) if n[:-4].isdigit() else None
        st = os.stat(p)
        out.append({"pid": pid, "path": p, "mtime": st.st_mtime, "bytes": st.st_size,
                    "live": pid in wraps, "alias": alias_by_pid.get(pid)})
    return sorted(out, key=lambda s: -s["mtime"])


def cmd_screens(a):
    rows = screens_list()
    if "--json" in a:
        out_json(rows)
        return
    if not rows:
        print(C.d("no captures yet; run claude through `zrecover run`"))
        return
    for s in rows:
        live = C.g("live") if s["live"] else C.d("gone")
        print(f"  {live}  {ago(s['mtime']):>5} ago  pid {s['pid']:<6} {(s['alias'] or ''):<24} {s['path']}")


def cmd_screen(a):
    if not a or wants_help(a):
        die("usage: zrecover screen <pid|alias|latest>", "zrecover screens", 2)
    rows = screens_list()
    want = a[0]
    if want == "latest":
        hit = rows[0] if rows else None
    elif want.isdigit():
        hit = next((s for s in rows if s["pid"] == int(want)), None)
    else:
        hit = next((s for s in rows if s["alias"] == want), None)
    if not hit:
        die(f"no capture for {want!r}", "zrecover screens", 1)
    with open(hit["path"]) as f:
        sys.stdout.write(f.read())


# MAINTAIN
def launchctl(*args):
    return subprocess.run(["launchctl", *args], capture_output=True, text=True)


def target():
    return f"gui/{os.getuid()}/{LABEL}"


def cmd_daemon(a):
    sub = a[0] if a else "status"
    if sub == "status":
        dm = daemon_state()
        loaded = launchctl("print", target()).returncode == 0
        if "--json" in a:
            out_json({"loaded": loaded, "plist": PLIST, "plist_exists": os.path.exists(PLIST), **dm})
            return
        print(f"{LABEL}: {'loaded' if loaded else C.r('not loaded')} · plist "
              f"{'present' if os.path.exists(PLIST) else C.r('missing')}")
        if dm["alive"]:
            st = dm["state"]
            print(f"  running pid {st['pid']}, up {ago(st['started'])}, last tick {ago(st['last_tick'])} ago, "
                  f"last scan {ago(st['last_scan'])} ago, {st['grants']} grant(s)"
                  + ("" if dm["fresh"] else C.r("  STALE")))
        else:
            print(C.r("  no live daemon") + C.d("  → zrecover daemon start"))
        print(C.d(f"  log {reaper.LOG}"))
    elif sub == "start":
        if not os.path.exists(PLIST):
            die("no plist", "zrecover daemon install", 1)
        r = launchctl("bootstrap", f"gui/{os.getuid()}", PLIST)
        if r.returncode and "already" not in r.stderr.lower():
            die(r.stderr.strip() or "bootstrap failed", code=1)
        print("started")
    elif sub == "stop":
        launchctl("bootout", target())
        print("stopped (back on `zrecover daemon start` or next login)")
    elif sub == "restart":
        r = launchctl("kickstart", "-k", target())
        if r.returncode:
            die(r.stderr.strip() or "kickstart failed", "zrecover daemon start", 1)
        time.sleep(1.2)
        cmd_daemon(["status"])
    elif sub == "install":
        write_plist()
        launchctl("bootstrap", f"gui/{os.getuid()}", PLIST)
        print(f"installed {PLIST} and loaded it")
    elif sub == "uninstall":
        launchctl("bootout", target())
        if os.path.exists(PLIST):
            os.remove(PLIST)
        print("unloaded and removed the LaunchAgent")
    else:
        die("usage: zrecover daemon status|start|stop|restart|install|uninstall", code=2)


def write_plist():
    body = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>{LABEL}</string>
  <!-- gcc-zrecover runs reaper.py; named so Login Items shows "gcc-zrecover" -->
  <key>ProgramArguments</key><array>
    <string>{os.path.join(HERE, 'gcc-zrecover')}</string>
  </array>
  <key>EnvironmentVariables</key><dict>
    <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <!-- A long-running watchdog, not a timer: it must be alive at the moment
       the machine starts to struggle. Not niced, so a saturated CPU cannot
       starve the one process meant to fix it. -->
  <key>KeepAlive</key><true/>
  <key>RunAtLoad</key><true/>
  <key>ThrottleInterval</key><integer>30</integer>
  <key>LowPriorityIO</key><true/>
  <key>StandardOutPath</key><string>{os.path.expanduser('~/.claude/logs/zrecover.out.log')}</string>
  <key>StandardErrorPath</key><string>{os.path.expanduser('~/.claude/logs/zrecover.err.log')}</string>
</dict></plist>
"""
    os.makedirs(os.path.dirname(PLIST), exist_ok=True)
    with open(PLIST, "w") as f:
        f.write(body)


def cmd_doctor(a):
    checks = []

    def check(name, ok, detail="", fix=""):
        checks.append({"check": name, "ok": bool(ok), "detail": detail, "fix": fix})

    cfg = reaper.load_config()
    dm = daemon_state()
    check("LaunchAgent plist", os.path.exists(PLIST), PLIST, "zrecover daemon install")
    check("LaunchAgent loaded", launchctl("print", target()).returncode == 0, LABEL, "zrecover daemon start")
    check("daemon alive", dm["alive"], f"pid {dm['state']['pid']}" if dm["state"] else "no heartbeat", "zrecover daemon start")
    check("daemon heartbeat fresh", dm["fresh"], f"last tick {ago(dm['state']['last_tick'])} ago" if dm["state"] else "",
          "zrecover daemon restart")
    check("not paused", not reaper.paused_until(), reaper.PAUSE_FILE, "zrecover resume")
    try:
        with open(reaper.CONFIG) as f:
            json.load(f)
        check("config.json parses", True, reaper.CONFIG)
    except FileNotFoundError:
        check("config.json parses", True, "no overrides (defaults)")
    except ValueError as e:
        check("config.json parses", False, str(e), f"fix or trash {reaper.CONFIG}")
    bad = [k for k in reaper.load_user_config() if k not in reaper.DEFAULTS]
    check("config keys known", not bad, ", ".join(bad) or "all known", "zrecover config unset <key>")
    try:
        for r in cfg["rules"]:
            re.compile(r["match"])
        check("rule regexes compile", True, f"{len(cfg['rules'])} rules")
    except re.error as e:
        check("rule regexes compile", False, str(e), "zrecover config edit")
    g = reaper.load_grants()
    check("grants file parses", isinstance(g, list), f"{len(active_grants())} active", f"trash {reaper.GRANTS}")
    py = python_for_wrap()
    has_pyte = bool(py) and subprocess.run([py, "-c", "import pyte"], capture_output=True).returncode == 0
    check("python with pyte for `run`", has_pyte, py or "none",
          f"uv venv {HERE}/.venv --python 3.12; uv pip install --python {VENV_PY} pyte")
    check("zrecover on PATH", shutil.which("zrecover") is not None, shutil.which("zrecover") or "", "zcmd install")
    alias = False
    try:
        with open(ZSHRC) as f:
            alias = ALIAS_LINE in f.read()
    except OSError:
        pass
    check("claude alias in ~/.zshrc", alias, "interactive claude runs through the wrapper", f"add: {ALIAS_LINE}")
    check("IPC registry readable", os.path.exists(reaper.IPC_DB) and reaper.ipc_sessions() is not None, reaper.IPC_DB,
          "claude-ipc broker (restore takes session ids from it)")
    check("log dir writable", os.access(os.path.dirname(reaper.LOG), os.W_OK), reaper.LOG, "")
    snap = load_snapshot(reaper.SESSIONS)
    check("session snapshot recent", bool(snap and time.time() - snap["ts"] < 3 * cfg["sessions_every_s"]),
          f"{ago(snap['ts'])} ago" if snap else "none", "zrecover daemon restart")
    check("notifier available", os.path.exists("/opt/homebrew/bin/terminal-notifier") or bool(shutil.which("osascript")),
          "", "brew install terminal-notifier")
    acts = reaper.plan(cfg)
    check("no action pending", not acts, f"{len(acts)} action(s) due" if acts else "idle", "zrecover plan")
    ok = all(c["ok"] for c in checks)
    if "--json" in a:
        out_json({"ok": ok, "checks": checks})
    else:
        print(C.b("zrecover doctor"))
        for c in checks:
            mark = C.g("✓") if c["ok"] else C.r("✗")
            fix = "" if c["ok"] or not c["fix"] else C.d(f"  → {c['fix']}")
            print(f"  {mark} {c['check']:<28} {C.d(c['detail'][:70])}{fix}")
        bad = [c for c in checks if not c["ok"]]
        print(f"\n  {C.g('all good') if not bad else C.y(str(len(bad)) + ' issue(s)')}")
    sys.exit(0 if ok else 1)


def cmd_test(a):
    r1 = subprocess.run([sys.executable, os.path.join(HERE, "test_reaper.py")]).returncode
    r2 = subprocess.run([sys.executable, os.path.join(HERE, "test_cli.py")]).returncode
    r4 = subprocess.run([sys.executable, os.path.join(HERE, "test_sessions.py")]).returncode
    py = python_for_wrap()
    r3 = subprocess.run([py, os.path.join(HERE, "test_wrap.py")] + a).returncode if py else 1
    sys.exit(r1 or r2 or r3 or r4)


COMMANDS = {
    "status": cmd_status, "plan": cmd_plan, "top": cmd_top, "explain": cmd_explain, "log": cmd_log,
    "allow": cmd_allow, "revoke": cmd_revoke, "grants": cmd_grants, "pause": cmd_pause, "resume": cmd_resume,
    "rules": cmd_rules, "protect": cmd_protect, "config": cmd_config,
    "run": cmd_run, "sessions": cmd_sessions, "restore": cmd_restore, "screens": cmd_screens, "screen": cmd_screen,
    "bundle": cmd_bundle,
    "daemon": cmd_daemon, "doctor": cmd_doctor, "test": cmd_test,
}
OWN_HELP = ("run", "allow", "explain", "revoke", "screen", "restore")


def main():
    a = sys.argv[1:]
    if "--plain" in a or "--json" in a:
        C.off()
        a = [x for x in a if x != "--plain"]
    if not a or a[0] in ("-h", "--help"):
        help_main()
        return
    if a[0] in ("version", "--version", "-V"):
        print(f"{SELF} {VERSION}")
        return
    if a[0] == "help":
        help_main() if len(a) == 1 else help_topic(a[1])
        return
    if a[0] == "examples":
        examples()
        return
    if a[0] == "reap":
        sys.argv = [sys.argv[0]] + a[1:]
        reaper.main()
        return
    fn = COMMANDS.get(a[0])
    if not fn:
        near = [c for c in COMMANDS if c.startswith(a[0][:3])]
        die(f"unknown command {a[0]!r}", f"did you mean: {', '.join(near)}" if near else "zrecover -h", 2)
    if wants_help(a[1:]) and a[0] not in OWN_HELP:
        help_main()
        return
    fn(a[1:])


if __name__ == "__main__":
    main()
