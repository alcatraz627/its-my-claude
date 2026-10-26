#!/usr/bin/env python3
"""One shared suite that runs real commands through every Bash guard that owns them.

Each guard has its own suite, and each suite only knows its own guard. This
one holds the cross-cutting promise of the shared parser: a mention never
blocks any migrated guard, a real dangerous command still blocks the guard
that owns it, and each known gap is pinned so its fix is noticed the day it
lands. The row tables come from the Push 2 plan (assets/reports/
20261026-push2-plan/plan.md section 4).

Expectations per guard:
    fire     must fire today
    quiet    must not fire
    xfire    a known false fire, pinned: it fires today; when it stops, the
             row fails so the marker is moved to quiet
    xquiet   a known miss, pinned the same way in the other direction

"Fire" for a blocking guard is exit 2, {"decision":"block"}, or a deny/ask
permissionDecision; for a nudge it is any additionalContext; for the two
allow-only hooks it is an allow.

Run: python3 guard-corpus.test.py            (exit 0 = pass)
     python3 guard-corpus.test.py --matrix   every row through every guard, no asserts
"""
import json
import os
import subprocess
import sys
import tempfile

HOME = os.path.expanduser("~")
S = f"{HOME}/.claude/scripts"
GUARDS = {
    "safe-delete": f"{S}/safe-delete.sh",
    "git-push": f"{S}/hooks/guard-git-push.sh",
    "github-agent-marker": f"{S}/hooks/guard-github-agent-marker.sh",
    "quoted-text": f"{S}/hooks/quoted-text-is-not-a-command.py",
    "allow-claude-ipc": f"{S}/hooks/allow-claude-ipc.py",
    "guard-policy": f"{S}/hooks/guard-policy.sh",
    "gate-cli-actions": f"{S}/cli-gating/gate-cli-actions.sh",
    "dev-server-port": f"{S}/hooks/guard-dev-server-port.sh",
    "rg-replace-bundle": f"{S}/hooks/guard-rg-replace-bundle.sh",
    "protect-atone-raw": f"{S}/protect-atone-raw.sh",
    "index-manipulation": f"{S}/hooks/prevent-unsolicited-index-manipulation.sh",
    "secret-file-read": f"{S}/hooks/guard-secret-file-read.sh",
    "command-chaining": f"{S}/hooks/guard-command-chaining.sh",
    "zsh-path-var": f"{S}/hooks/guard-zsh-path-var.sh",
    "env-dump": f"{S}/hooks/guard-env-dump.sh",
    "system-dir-writes": f"{S}/hooks/guard-system-dir-writes.sh",
    "block-nested-claude": f"{S}/block-nested-claude.sh",
    "repo-visibility": f"{S}/hooks/guard-repo-visibility.sh",
    "curl-post-auth": f"{S}/hooks/block-curl-post-auth.sh",
    "user-commit": f"{S}/hooks/guard-user-commit.sh",
    "migrate-hint": f"{S}/migrate-hint.sh",
    "anthropic-credentials": f"{S}/hooks/guard-anthropic-credentials.sh",
    "commit-signature": f"{S}/hooks/guard-commit-signature.sh",
}
ALLOW_ONLY = {"quoted-text", "allow-claude-ipc"}
# Guards that read commands through shellparse today. Every F row must pass all of them.
MIGRATED = {"safe-delete", "git-push", "github-agent-marker", "guard-policy", "repo-visibility", "curl-post-auth", "user-commit", "system-dir-writes"}

# The trailer is assembled at run time: the ai-signature Write hook refuses the literal in any file.
TRAILER = "Co-Authored" + "-By: Claude <noreply@anthropic.com>"

F = [  # id, command, cwd key, guard named in the plan, expectation for that guard
    ("F1", 'rg -n "next|vercel|gh" src/', "plain", "guard-policy", "quiet"),
    ("F2", "ps -axo pid,command | rg 'next-server|next dev'", "plain", "dev-server-port", "quiet"),
    ("F3", "git add src/cli.ts && git commit -m 'add serve and tail verbs'", "plain", "dev-server-port", "quiet"),
    ("F4", "cat <<EOF > /tmp/d.md\nvite --port 3000 is what we used\nEOF", "plain", "dev-server-port", "quiet"),
    ("F5", "git commit -q -F - <<'EOF'\nnpm run dev now uses 6200\nEOF", "plain", "dev-server-port", "quiet"),
    ("F6", "cat > /tmp/ck.md <<'EOF'\nnpx next start -p 6225\nEOF", "plain", "dev-server-port", "quiet"),
    ("F7", "bash scripts/deploy.sh --env dev", "plain", "dev-server-port", "quiet"),
    ("F8", "npx vite-node scripts/seed.ts", "plain", "dev-server-port", "quiet"),
    ("F9", 'rg -n "jq -r .cwd" scripts/', "plain", "rg-replace-bundle", "quiet"),
    ("F10", "cat <<EOF > /tmp/gh.md\ngh release create v1\nEOF", "plain", "gate-cli-actions", "quiet"),
    ("F11", 'python3 -c "print(1); x=\\"gh pr list\\""', "plain", "gate-cli-actions", "quiet"),
    ("F12", 'jq -n --arg i "log is atone/events.jsonl" .', "plain", "protect-atone-raw", "quiet"),
    ("F13", "python3 -c \"patterns = ['git stash list', 'git reset']\"", "plain", "index-manipulation", "quiet"),
    ("F14", "claude-ipc send --to peer 'I ran git stash earlier, FYI'", "plain", "index-manipulation", "quiet"),
    ("F15", "cat <<'EOF'\nRunbook: git reset HEAD is forbidden here\nEOF", "plain", "index-manipulation", "quiet"),
    ("F16", "claude-ipc send --to peer 'the token lives in ~/.npmrc on that box'", "plain", "secret-file-read", "quiet"),
    ("F17", 'echo "do not rm -rf the repo"', "plain", "safe-delete", "quiet"),
    ("F18", 'git commit -m "docs: explain git push origin main"', "main", "git-push", "quiet"),
    ("F19", 'echo "bash -c \\"git push origin main\\""', "main", "git-push", "quiet"),
    ("F20", 'echo "run gh pr create --title t --body x later"', "plain", "github-agent-marker", "quiet"),
    ("F21", "cat > notes.md <<'EOF'\nsudo rm -rf /tmp/x\nEOF", "plain", "safe-delete", "quiet"),
    ("F22", 'git commit -m "fix a && b parsing"', "plain", "command-chaining", "quiet"),
    ("F23", "rg -n 'alpha|beta' /abs/path", "plain", "command-chaining", "quiet"),
    ("F24", "rg -n \"path=\\\"/|path='/\" frontend/src/App.tsx", "plain", "zsh-path-var", "quiet"),
    ("F25", "git commit -m 'run env to see vars'", "plain", "env-dump", "quiet"),
    ("F26", 'git commit -m "docs: never tee /etc/hosts"', "plain", "system-dir-writes", "quiet"),
    ("F27", "echo 'writes to ~/.claude/.claude/ are blocked' > /tmp/note.txt", "plain", "block-nested-claude", "quiet"),
    ("F28", 'echo "gh repo create versable-git/x --public is banned"', "plain", "repo-visibility", "quiet"),
    ("F29", "echo 'curl -X POST -H \"Authorization: Bearer abc\" https://api.example.com'", "plain", "curl-post-auth", "quiet"),
    ("F30", 'echo "next step: git commit"', "protected", "user-commit", "quiet"),
    ("F31", 'rg -n "mv ~/.claude/old" notes.md', "plain", "migrate-hint", "quiet"),
]

T = [  # id, command, cwd key, owning guard
    ("T1", "rm -rf build", "plain", "safe-delete"),
    ("T2", 'bash -c "rm notes.txt"', "plain", "safe-delete"),
    ("T3", "ls | xargs rm", "plain", "safe-delete"),
    ("T4", "find . -name x -exec rm {} \\;", "plain", "safe-delete"),
    ("T5", "sudo rm notes.txt", "plain", "safe-delete"),
    ("T6", "git push origin main", "main", "git-push"),
    ("T7", 'bash -c "git push origin main"', "main", "git-push"),
    ("T8", 'echo "$(git push origin main)"', "main", "git-push"),
    ("T9", "cat <<EOF | bash\ngit push origin main\nEOF", "main", "git-push"),
    ("T10", "git push origin +main", "main", "git-push"),
    ("T11", 'gh pr comment 12 --body "looks good"', "plain", "github-agent-marker"),
    ("T12", 'bash -c "gh pr comment 12 --body hi"', "plain", "github-agent-marker"),
    ("T13", "npx vercel --prod", "plain", "guard-policy"),
    ("T14", "$(brew --prefix)/bin/vercel --prod", "plain", "guard-policy"),
    ("T15", "./node_modules/.bin/wrangler deploy", "plain", "guard-policy"),
    ("T16", "gh api repos/o/r/issues/1/comments -X POST -f body=hi", "plain", "guard-policy"),
    ("T17", "gh release create v1", "plain", "gate-cli-actions"),
    ("T18", 'bash -c "render deploy --prod"', "plain", "gate-cli-actions"),
    ("T19", "sed -E 's/=.*/=<redacted>/' pr-board/.env", "plain", "secret-file-read"),
    ("T20", "ls -la .env && cat .env", "plain", "secret-file-read"),
    ("T21", 'cat "$HOME/.env"', "plain", "secret-file-read"),
    ("T22a", "vite", "plain", "dev-server-port"),
    ("T22b", "npm run dev", "plain", "dev-server-port"),
    ("T23", "NODE_ENV=development vite", "plain", "dev-server-port"),
    ("T24", "vite --help; vite", "plain", "dev-server-port"),
    ("T25", "export ANTHROPIC_API_KEY=x", "plain", "anthropic-credentials"),
    ("T26", 'eval "export ANTHROPIC_API_KEY=x"', "plain", "anthropic-credentials"),
    ("T27", "launchctl setenv ANTHROPIC_API_KEY x", "plain", "anthropic-credentials"),
    ("T28", "echo x > /etc/hosts", "plain", "system-dir-writes"),
    ("T29", "cat <<EOF > /etc/hosts\nx\nEOF", "plain", "system-dir-writes"),
    ("T30", f'git commit -m "x" -m "{TRAILER}"', "plain", "commit-signature"),
    ("T31", "git commit --no-verify -m x", "plain", "commit-signature"),
    ("T32", "git reset HEAD frontend/", "plain", "index-manipulation"),
    ("T33", "git stash list; git stash pop", "plain", "index-manipulation"),
    ("T34", "cd /tmp && env", "plain", "env-dump"),
    ("T35", "git status && git log -3", "plain", "command-chaining"),
    ("T36", "for path in /a /b; do echo hi; done", "plain", "zsh-path-var"),
    ("T37", "f(){ local path; }; f", "plain", "zsh-path-var"),
    ("T38", 'curl -X POST -H "Authorization: Bearer abc123" https://api.example.com/v1/things', "plain", "curl-post-auth"),
    ("T39", "gh repo create versable-git/x --public", "plain", "repo-visibility"),
    ("T40", "git commit -m x", "protected", "user-commit"),
    ("T41", "rg -r '' foo src/", "plain", "rg-replace-bundle"),
]

N = [  # id, command, cwd key, owning guard, expectation today
    ("N1", "for f in a b; do rm $f; done", "plain", "safe-delete", "fire"),
    ("N2", "{ rm x; }", "plain", "safe-delete", "fire"),
    ("N3", "echo $((1<<n))\nrm x", "plain", "safe-delete", "fire"),
    ("N4", "if true; then git push origin main; fi", "main", "git-push", "fire"),
    ("N5", 'bash -c "echo x > /etc/hosts"', "plain", "system-dir-writes", "fire"),
    ("N6", 'claude-ipc send --to a "$(sudo rm x)"', "plain", "allow-claude-ipc", "quiet"),
    ("N7", "rg -rn foo src/", "plain", "rg-replace-bundle", "fire"),
    ("N8", "echo for && ls", "plain", "command-chaining", "fire"),
    # Found by this suite: the ask/deny-tier allow hook read $( ) inside quotes as a mention.
    ("N9", 'claude-ipc send --to a "$(sudo rm x)"', "plain", "quoted-text", "quiet"),
    # Found by allow-claude-ipc's own suite: shlex kept `hi;` as one word, so the chain was allowed.
    ("N10", "claude-ipc send --to peer hi; git push", "plain", "allow-claude-ipc", "quiet"),
]

F_EXTRA = [  # false fires a second guard has on an F row's command
    ("F10", "cat <<EOF > /tmp/gh.md\ngh release create v1\nEOF", "plain", "guard-policy", "quiet"),
    ("F20", 'echo "run gh pr create --title t --body x later"', "plain", "guard-policy", "quiet"),
]

# A guard the owner has switched off cannot be exercised; its rows are skipped and named.
OFF_MARKERS = {"gate-cli-actions": f"{HOME}/.claude/cli-gating.off"}


def setup_dirs():
    root = tempfile.mkdtemp(prefix="guard-corpus-")
    plain = os.path.join(root, "plain")
    os.makedirs(plain)
    main = os.path.join(root, "main")
    prot = os.path.join(root, "protected")
    for d in (main, prot):
        os.makedirs(d)
        subprocess.run(["git", "init", "-q", "-b", "main", d], check=True)
        subprocess.run(["git", "-C", d, "commit", "-q", "--allow-empty", "-m", "init"], check=True,
                       env={**os.environ, "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t",
                            "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@t"})
    os.makedirs(os.path.join(prot, ".claude"))
    open(os.path.join(prot, ".claude", "require-user-commit"), "w").close()
    # Every policy reads "block", so the owner's live menu-bar switches cannot turn a gate off
    # mid-suite. Not "ask": the ask path writes a real pending approval under ~/.claude/.policy-ask
    # that the Switchboard panel shows the owner (it did, 2026-10-26, and was approved).
    stub = os.path.join(root, "pol-stub.sh")
    with open(stub, "w") as fh:
        # git.commit stays allow: F rows hold real commits whose messages are the mention under test.
        fh.write('#!/bin/bash\n[ "$1" = get ] || exit 0\ncase "$2" in git.commit) echo allow;; *) echo block;; esac\n')
    os.chmod(stub, 0o755)
    return root, {"plain": plain, "main": main, "protected": prot, "pol": stub}


def fired(guard, cmd, cwd, env):
    payload = json.dumps({"session_id": "guard-corpus", "hook_event_name": "PreToolUse",
                          "tool_name": "Bash", "tool_input": {"command": cmd}, "cwd": cwd})
    path = GUARDS[guard]
    argv = ["python3", path] if path.endswith(".py") else ["bash", path]
    try:
        r = subprocess.run(argv, input=payload, capture_output=True, text=True, cwd=cwd, env=env, timeout=20)
    except subprocess.TimeoutExpired:
        return "timeout"
    out = r.stdout
    d = {}
    # Guards print one compact line or pretty-printed JSON (jq -n); try both.
    for chunk in (out.strip(), (out.strip().splitlines() or [""])[-1]):
        try:
            d = json.loads(chunk) if chunk else {}
            break
        except Exception:  # noqa: BLE001  a non-JSON reply is read by substring below
            continue
    hso = d.get("hookSpecificOutput") or {}
    pd = hso.get("permissionDecision")
    if guard in ALLOW_ONLY:
        return pd == "allow"
    return (r.returncode == 2 or d.get("decision") == "block" or pd in ("deny", "ask")
            or bool(hso.get("additionalContext")) or '"decision":"block"' in out.replace(" ", ""))


def main():
    matrix = "--matrix" in sys.argv
    root, dirs = setup_dirs()
    env = {**os.environ, "WARN_LOG_STORE": os.path.join(root, "warn.jsonl"), "POL_SH": dirs["pol"]}
    for mute in ("CHAIN_GUARD_OFF", "ZSH_PATH_GUARD_OFF", "PORTS_OK"):
        env.pop(mute, None)
    passed = failed = 0

    skipped = 0

    def judge(rid, guard, cmd, cwd_key, want):
        nonlocal passed, failed, skipped
        marker = OFF_MARKERS.get(guard)
        if marker and os.path.exists(marker):
            skipped += 1
            print(f"  SKIP  {rid:5} {guard:22} switched off by {marker}")
            return
        got = fired(guard, cmd, dirs[cwd_key], env)
        if got == "timeout":
            ok, note = False, "timed out"
        elif want in ("fire", "xfire"):
            ok, note = got is True, ("fires" if got else "silent")
        else:
            ok, note = got is False, ("silent" if not got else "fires")
        tag = {"xfire": "known false fire", "xquiet": "known miss"}.get(want, want)
        if ok:
            passed += 1
            print(f"  ok    {rid:5} {guard:22} {tag}")
        else:
            failed += 1
            hint = " (the gap closed: move this row to quiet/fire)" if want in ("xfire", "xquiet") else ""
            print(f"  FAIL  {rid:5} {guard:22} want {tag}, {note}{hint}")

    if matrix:
        rows = [(r[0], r[1], r[2]) for r in F + T + N]
        for rid, cmd, ck in rows:
            hits = [g for g in GUARDS if fired(g, cmd, dirs[ck], env) is True]
            print(f"{rid:5} {', '.join(hits) or '-'}")
        return 0

    print("── false fires: the named guard, and every migrated guard ──")
    for rid, cmd, ck, guard, want in F:
        judge(rid, guard, cmd, ck, want)
        for g in sorted(MIGRATED - {guard}):
            judge(rid, g, cmd, ck, "quiet")
    for rid, cmd, ck, guard, want in F_EXTRA:
        judge(rid, guard, cmd, ck, want)
    print("── true positives: the owning guard still fires ──")
    for rid, cmd, ck, guard in T:
        judge(rid, guard, cmd, ck, "fire")
    print("── misses the migration closes ──")
    for rid, cmd, ck, guard, want in N:
        judge(rid, guard, cmd, ck, want)
    print(f"---- pass={passed} fail={failed} skip={skipped}")
    subprocess.run(["trash", root], capture_output=True)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
