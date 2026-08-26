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
   `.gitignore`, so this scans what is already tracked or trackable:
   ```bash
   cd ~/.claude && rg -n -o \
     'ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|xoxb-[A-Za-z0-9-]{10,}|figd_[A-Za-z0-9]+|AKIA[A-Z0-9]{16}|-----BEGIN [A-Z ]*PRIVATE KEY' \
     . -g '!.git'
   ```
   ANY output → **STOP**, do not commit. Remove the secret or `.gitignore` it first.
   Never commit `.env`, credentials, tokens (`rules/never-modify-anthropic-credentials.md`).

   **If this commit starts tracking a directory that was ignored, scan that
   directory separately with `--no-ignore` before committing it.** The scan above
   inherits `.gitignore`, so a previously-ignored path is invisible to it, and the
   bytes entering the repo are exactly the ones nothing has read. The reassurance
   in the line above holds only while the ignore set and the tracked set agree,
   and starting to track something is the moment they disagree.

   ```bash
   rg --no-ignore -n -o '<same pattern>' <the-newly-tracked-dir>
   ```

   Cheap tell that you are in this case: `git status` shows deletions whose
   matching additions never appear. Lived case 2026-08-20, mig 0048: 431 files
   moved into a new top-level `skills-parked/`, which the allowlist ignored by
   default, so a root-scoped `rg --files .` returned zero hits under it.

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

4. **Commit with a SCOPED add.** This repo is multi-session: `git add -A`
   sweeps a sibling session's in-progress edits into your commit. Name the
   files your change touched:
   ```bash
   git -C ~/.claude add <paths your change touched>
   git -C ~/.claude commit -m "<message>"
   ```
   `add -A` is reserved for a deliberate learned-state sync commit
   (`Sync <date>, N files`), made only when no sibling session is mid-edit
   (`claude-ipc peers` shows who is live; when unsure, scope the add).

5. **Push.** This is `its-my-claude`'s `main` — pushing is an explicit, per-request
   act; the human asking you to commit+push IS the approval for that push:
   ```bash
   git -C ~/.claude push origin main
   ```
   Rejected (non-fast-forward = another session pushed) → step 2's rebase, retry.

5b. **If the push waits on the owner's sentinel, release the lock first** and
   re-acquire it for the push. The lock's 300s TTL is shorter than a human
   approval wait, and holding it blocks every sibling commit meanwhile
   (prop-20260808-052330-57). A local `commit-msg` hook in this repo strips any
   harness signature trailer before the commit lands (prop-20260722-123329-41).
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
