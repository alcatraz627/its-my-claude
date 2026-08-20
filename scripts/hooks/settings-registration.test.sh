#!/usr/bin/env bash
# Every hook this machine registers must actually be able to run.
#
# WHY THIS EXISTS. heed-writeback.sh was committed at mode 100644 and registered
# in settings.json as a bare path, so every Stop tried to exec it and got 126.
# It stayed dead for two days while looking completely alive: the registration was
# present, its callers were arming markers, markers were appearing on disk. The
# only artifact that disagreed was a mode bit, and nothing reads mode bits. Its
# entire tier — the heed instrument for advisory nudges — recorded nothing, and
# the silence was then read as "advisories do not convert".
#
# /doctor Step 3 already checks this and would have caught it. It only runs when a
# human types /doctor, and nobody did. This suite puts the same question where a
# hook edit already goes, so the answer arrives from work rather than from ritual.
#
# THE DISTINCTION THAT MATTERS. A command's first token decides whether the mode
# bit is load-bearing:
#     ~/.claude/scripts/hooks/x.sh          bare path — MUST be executable
#     bash ~/.claude/scripts/hooks/x.sh     interpreter reads it — mode is irrelevant
# Checking every .sh mentioned anywhere in the command conflates the two and warns
# about files that are working fine, which is how a real warning gets skimmed past.

set -uo pipefail
cd "$(dirname "$0")" || exit 1

SETTINGS="${SETTINGS_JSON:-$HOME/.claude/settings.json}"

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok   $1"; }
bad() { fail=$((fail+1)); echo "  FAIL $1"; }

# Prints one "<kind> <path>" line per broken registration; silent when all is well.
# Kinds: missing (no such file) | notexec (bare-path target without the user x bit).
audit() {
  python3 - "$1" <<'PY'
import json, os, stat, sys

INTERPRETERS = {"bash", "sh", "zsh", "python3", "python", "node", "/bin/bash",
                "/bin/sh", "/usr/bin/env", "/usr/bin/python3"}

try:
    doc = json.load(open(sys.argv[1]))
except Exception as e:
    print(f"unparseable {sys.argv[1]}"); sys.exit(0)

cmds = []
def walk(o):
    if isinstance(o, dict):
        if o.get("type") == "command" and "command" in o:
            cmds.append(o["command"])
        for v in o.values():
            walk(v)
    elif isinstance(o, list):
        for v in o:
            walk(v)
# The whole document, not only .hooks: statusLine.command is the same bare-path
# registration one key away, and was missed until the 2026-08-18 review (I1).
walk(doc)

for c in sorted(set(cmds)):
    tok = c.split()[0] if c.split() else ""
    # Only a bare-path invocation needs the bit. Anything handed to an interpreter
    # is read, not exec'd, and its mode says nothing about whether it works.
    if tok in INTERPRETERS:
        continue
    # Not a path at all (an inline jq/printf one-liner); nothing to check.
    if "/" not in tok:
        continue
    p = os.path.expanduser(tok)
    if not os.path.exists(p):
        print(f"missing {tok}")
    elif not (os.stat(p).st_mode & stat.S_IXUSR):
        print(f"notexec {tok}")
PY
}

# ── the live assertion: this machine's real settings.json ────────────────────
echo "== every bare-path hook in the real settings.json can execute =="
live=$(audit "$SETTINGS")
if [ -z "$live" ]; then
  ok "all bare-path registrations exist and are executable"
else
  bad "broken registrations found:"
  printf '       %s\n' $live
fi

# ── the hinter registry: hint-injector.sh silently skips a non-executable hinter ─
echo "== every ~/.claude/hinters/*.sh is executable (the injector skips 644 silently) =="
badh=$(for h in "$HOME"/.claude/hinters/*.sh; do [ -x "$h" ] || echo "notexec $h"; done)
[ -z "$badh" ] && ok "all hinters carry the x bit" || { bad "non-executable hinters:"; printf '       %s\n' $badh; }

# ── fixtures: prove the checker can fail, and does not over-fire ─────────────
fixture() {
  local dir="$1" cmd="$2"
  mkdir -p "$dir"
  jq -n --arg c "$cmd" '{hooks:{Stop:[{hooks:[{type:"command",command:$c}]}]}}' > "$dir/settings.json"
}

T=$(mktemp -d "${TMPDIR:-/tmp}/hookreg-XXXXXX")
mkdir -p "$T/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$T/bin/good.sh"; chmod 755 "$T/bin/good.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$T/bin/nox.sh";  chmod 644 "$T/bin/nox.sh"

echo "== a bare-path target without the x bit is caught =="
fixture "$T/a" "$T/bin/nox.sh resolve"
[ "$(audit "$T/a/settings.json")" = "notexec $T/bin/nox.sh" ] \
  && ok "flags notexec — the exact shape that shipped dead for two days" \
  || bad "did not flag a 644 bare-path hook, got: $(audit "$T/a/settings.json")"

echo "== a bare-path statusLine.command without the x bit is caught (I1) =="
mkdir -p "$T/s"; jq -n --arg c "$T/bin/nox.sh" '{statusLine:{type:"command",command:$c},hooks:{}}' > "$T/s/settings.json"
[ "$(audit "$T/s/settings.json")" = "notexec $T/bin/nox.sh" ] \
  && ok "statusLine.command is audited too" \
  || bad "statusLine.command not audited, got: $(audit "$T/s/settings.json")"

echo "== the same file invoked through bash is NOT flagged =="
fixture "$T/b" "bash $T/bin/nox.sh resolve"
[ -z "$(audit "$T/b/settings.json")" ] \
  && ok "mode is irrelevant when an interpreter reads the file" \
  || bad "false positive on an interpreter-invoked 644 script"

# The row above passes for the wrong reason on its own: the bare word "bash" has
# no "/" in it, so the not-a-path branch already skipped it and the interpreter
# list was never consulted. Four live registrations use a FULL-PATH interpreter
# (`/bin/bash ~/.claude/scripts/hooks/subagent-box.sh`), which only the
# interpreter list can handle. This is the row that actually exercises it.
fixture "$T/b2" "/bin/bash $T/bin/nox.sh resolve"
[ -z "$(audit "$T/b2/settings.json")" ] \
  && ok "a FULL-PATH interpreter is recognised, and its 644 target is not flagged" \
  || bad "flagged a script that /bin/bash reads rather than execs"

echo "== a registration pointing at nothing is caught =="
fixture "$T/c" "$T/bin/vanished.sh"
[ "$(audit "$T/c/settings.json")" = "missing $T/bin/vanished.sh" ] \
  && ok "flags missing" \
  || bad "did not flag a registration with no file behind it"

echo "== a healthy registration is silent =="
fixture "$T/d" "$T/bin/good.sh --flag"
[ -z "$(audit "$T/d/settings.json")" ] \
  && ok "no output when everything is fine" \
  || bad "flagged a working hook: $(audit "$T/d/settings.json")"

echo "== an inline one-liner is not mistaken for a path =="
fixture "$T/e" "jq -n '{systemMessage: \"hi\"}'"
[ -z "$(audit "$T/e/settings.json")" ] \
  && ok "an inline jq command is not treated as a missing script" \
  || bad "inline command flagged as a broken path: $(audit "$T/e/settings.json")"

echo "== a settings.json that will not parse says so, rather than passing =="
printf '{"hooks": {"Stop": [ {"hooks": [ {"type":"comm' > "$T/broken.json"
case "$(audit "$T/broken.json")" in
  unparseable*) ok "an unreadable settings file is reported, never silently green" ;;
  *)            bad "a corrupt settings.json produced no finding" ;;
esac

rm -rf "$T"
echo "---"; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
