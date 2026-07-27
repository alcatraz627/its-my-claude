<!-- i-dream project brief · 2026-07-18T06:40:45.860505+00:00 · 20 patterns / 9 insights -->
## What this project is about
Local LLM model suite and tooling (`q`/`imagine`/`warm`/`lm`), with heavy multi-agent and IPC coordination patterns as first-class concerns. Work style is autonomous, parallel, breadth-first sweeps before polish.

## Things to do (or keep doing)
- **Batch sequential work into autonomous runs**; halt only at genuine decision points or missing user input — don't route routine go-aheads through the user.
- **Verify IPC delivery via actual round-trip reply** from the peer, not send-side logs or telemetry; a successful send is not confirmed delivery.
- **Update the Task tool after each logical unit** during multi-agent sessions — task lists drift fatally when batched to session end.
- **Ground in the existing codebase first** (read `docs/STATE.md`, explore before touching code), then surface a recommendation.

## Things to avoid
- **Don't use `rg -rn`** — `-r` means `--replace`, not recursive; use `rg -n` for line numbers in recursive searches.
- **Don't default-ALLOW on unrecognized commands** in any gate/access system; unknown inputs must DENY explicitly.
- **Don't treat proxy evidence as direct verification** — a test pass, send-success, or class name is not proof the actual outcome occurred.
- **Don't patch a specific instance** of a structural policy violation without fixing the underlying structural default; the gap remains exploitable.

## Open questions / known gaps
- Multi-agent parallel work consistently causes stale state (task lists, branch pointers, IPC aliases) — no single invalidation signal exists; re-verify ALL cached cross-turn state after any parallel burst.
- IPC shell escaping is a recurring silent failure; backticks and special chars in message bodies must be quoted or heredoc-passed every time.
