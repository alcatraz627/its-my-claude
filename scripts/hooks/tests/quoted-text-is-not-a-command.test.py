"""The quoted-text hook: allow a mention, stay silent when the quoted text runs.

The must-be-silent half is the point. A deny glob that matches only because a
command is quoted inside `bash -c`, `sh -c`, `eval`, `ssh` or a heredoc fed to
a shell is a real command, and an allow from this hook would override the tier
that exists to stop it (D33 audit, 2026-10-15: all six wrapper forms were
allowed). A plain `echo "sudo rm"` must still be allowed, or the hook is dead.

HOOK_UNDER_TEST points the suite at a mutated copy; the copy must sit in
scripts/hooks/ so it finds shell-scan.py.
"""

import json
import os
import subprocess
import sys
import tempfile

HOOK = os.environ.get("HOOK_UNDER_TEST", "/Users/alcatraz627/.claude/scripts/hooks/quoted-text-is-not-a-command.py")

# Sandbox HOME carrying only the deny globs, so the live settings never matter.
HOME = tempfile.mkdtemp(prefix="qtinc-")
os.makedirs(os.path.join(HOME, ".claude"))
with open(os.path.join(HOME, ".claude", "settings.json"), "w") as fh:
    json.dump({"permissions": {"deny": ["Bash(*sudo rm*)", "Bash(*launchctl unload*)", "Bash(*defaults write*)"]}}, fh)

MUST_ALLOW = [
    ('echo "sudo rm -rf /tmp/x"', "a mention in echo"),
    ('git commit -m "never run sudo rm"', "a mention in a commit message"),
    ("cat > notes.md <<'EOF'\nsudo rm -rf /tmp/x\nEOF", "a heredoc written to a file"),
    ("ls | tee out.txt <<'EOF'\nlaunchctl unload x\nEOF", "a heredoc with no shell to read it"),
]

MUST_BE_SILENT = [
    ('bash -c "sudo rm -rf /tmp/x"', "bash -c"),
    ("sh -c 'launchctl unload ~/x.plist'", "sh -c"),
    ("eval 'defaults write com.x y 1'", "eval"),
    ('ssh host "sudo rm /x"', "ssh remote command"),
    ("bash <<'EOF'\nsudo rm x\nEOF", "heredoc fed to bash"),
    ("cat <<'EOF' | bash\nsudo rm x\nEOF", "heredoc piped to bash"),
    ('echo "sudo rm"; bash -c "sudo rm x"', "a mention beside a real wrapper"),
    ("sudo rm -rf /tmp/x", "a bare command (tiers decide)"),
]


def decision(command: str) -> str:
    payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": command}, "cwd": HOME})
    env = dict(os.environ, HOME=HOME)
    out = subprocess.run([sys.executable, HOOK], input=payload, capture_output=True, text=True, env=env, timeout=20).stdout
    if not out.strip():
        return "silent"
    return json.loads(out)["hookSpecificOutput"]["permissionDecision"]


def main() -> int:
    passed = failed = 0
    for command, why in MUST_ALLOW:
        got = decision(command)
        if got == "allow":
            passed += 1
            print(f"  ok    allows: {why}")
        else:
            failed += 1
            print(f"  FAIL  {why}: wanted allow, got {got}")
    for command, why in MUST_BE_SILENT:
        got = decision(command)
        if got == "silent":
            passed += 1
            print(f"  ok    silent: {why}")
        else:
            failed += 1
            print(f"  FAIL  {why}: wanted silent, got {got}")
    print(f"---- pass={passed} fail={failed}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
