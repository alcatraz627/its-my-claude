# Committing ~/.claude (the `its-my-claude` repo)

> The standard procedure EVERY Claude follows to commit + push this config repo.
> `~/.claude` is its OWN git repo (remote `its-my-claude`), included as a submodule
> in `its-my-config`. The aggregate `its-my-config/sync.sh` does **not** commit this
> repo — it only bumps the submodule pointer, and its secret-scan **excludes** this
> dir (`-g '!claude'`). So committing `~/.claude` is a SEPARATE step, done the same
> way each time, **with its own secret-scan**. (A past bulk-sync that skipped the
> scan leaked an Anthropic key — atone `bulk-sync-without-secret-scan`.)

## Procedure — in order, do not skip steps 0 or 1

0. **Acquire the commit lock.** This repo is multi-session — other Claudes commit
   here concurrently (your edits can get swept into their `git add -A`). Serialize
   commits with the shared write-lock (reads are never blocked; only commits wait):
   ```bash
   bash ~/.claude/skills/shared/lock-file.sh acquire ~/.claude/.git gcc-commit
   ```
   If another session holds it, this retries, then prints the owner — wait, then
   retry. **Always release in step 6**, even if you abort partway.

1. **Secret-scan the committable surface FIRST** (before `git add`). `rg` respects
   `.gitignore`, so this scans exactly what would be pushed:
   ```bash
   cd ~/.claude && rg -n -o \
     'ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|xoxb-[A-Za-z0-9-]{10,}|figd_[A-Za-z0-9]+|AKIA[A-Z0-9]{16}|-----BEGIN [A-Z ]*PRIVATE KEY' \
     . -g '!.git'
   ```
   ANY output → **STOP**, do not commit. Remove the secret or `.gitignore` it first.
   Never commit `.env`, credentials, tokens (`rules/never-modify-anthropic-credentials.md`).

2. **Verification triad — this repo is MULTI-SESSION; it moves under you.** Other
   Claude sessions commit here concurrently. Before pushing:
   ```bash
   git -C ~/.claude fetch origin
   git -C ~/.claude status --short                       # what you'll commit
   git -C ~/.claude rev-list --count HEAD..origin/main   # >0 = you are BEHIND
   ```
   If behind > 0 → `git -C ~/.claude pull --rebase origin main` (resolve conflicts),
   then re-run the secret-scan.

3. **Review.** Most churn is auto-generated learned state (`subconscious/`,
   `i-dream/`, `metacog/`) — committed normally. Confirm no secrets, no stray
   `_*.claude.md` scratch, no `wal.*` (those are gitignored).

4. **Commit** with a descriptive message (pure learned-state churn may use
   `Sync <date> — N files`):
   ```bash
   git -C ~/.claude add -A
   git -C ~/.claude commit -m "<message>"
   ```

5. **Push.** This is `its-my-claude`'s `main` — pushing is an explicit, per-request
   act; the human asking you to commit+push IS the approval for that push:
   ```bash
   git -C ~/.claude push origin main
   ```
   Rejected (non-fast-forward = another session pushed) → step 2's rebase, retry.

6. **Release the lock** — ALWAYS, even if you aborted at any earlier step:
   ```bash
   bash ~/.claude/skills/shared/lock-file.sh release ~/.claude/.git gcc-commit
   ```

7. **(Optional) bump the aggregate** so `its-my-config` points at the new commit:
   ```bash
   bash ~/Code/Claude/its-my-config/sync.sh
   ```

## Hard rules
- **Hold the `gcc-commit` lock** (step 0) for the whole commit→push, release in
  step 6. This is what stops two Claudes interleaving edits/commits on this repo.
- Step 1's secret-scan is **mandatory and runs before `git add`**. No exceptions.
- Never `git push --force` here (shared, multi-session history).
- Don't commit machine-local junk (`_*.claude.md`, `wal.*`, lock files) — they're
  gitignored; keep them that way.
