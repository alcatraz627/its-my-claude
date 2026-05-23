---
name: test
description: Run tests for the current folder using a cached per-folder framework detection. First run probes the folder for pyproject.toml/package.json/Cargo.toml/go.mod etc and caches the resulting test command; subsequent runs reuse the cache (sub-200ms). Stale-cache failure is an acceptable rare cost — re-detect on test-not-found errors. Use when the user asks to run tests, validate changes, or check a specific test file/function. Nudges toward thoroughness — adjacent tests, coverage checks, and result analysis.
allowed-tools: Read, Glob, Grep, Bash
argument-hint: "[path | -k keyword | --refresh | --thorough | --only]"
user-invokable: true
---

## Brief

Run the right test framework for the current folder without you having to remember which package manager / runner / pyenv-activation it uses. Cache the lookup so the second invocation is sub-200ms. Nudge toward verifying adjacent surface area, not just the one failing test.

## Why this exists

Test commands vary wildly: `./.venv/bin/pytest -k X`, `npx vitest run`, `pnpm test`, `cargo test --lib`, `go test -run TestX`. Claude rediscovers the right command per session, often getting it slightly wrong (wrong pm, wrong venv path, missing flags). Cache it; trust folders don't change infra often.

## Usage

```
/test                          # run cached test command for CWD's folder
/test src/auth                 # run for a specific subdir
/test -k login                 # pass keyword filter (pytest/vitest support -k)
/test --refresh                # bypass cache; re-detect framework
/test --only                   # just run; skip thoroughness nudges
/test --thorough               # full pass: tests + coverage + adjacent surface
```

## Phase 1 — Resolve test command

```bash
~/.claude/scripts/test/detect.sh "$FOLDER"
```

Output is JSON: `{folder, project_root, framework, runner, test_cmd, detected_at}`. Cache lives at `~/.claude/cache/test-patterns/<encoded>.json`.

If `detected: false` (no known config), tell the user: "no test framework detected for `$FOLDER` — supports pytest, vitest, jest, mocha, cargo, go, bun, npm/pnpm/yarn `test` script. Initialize one or pass `--refresh` after setting up." Don't try to guess.

## Phase 2 — Run the cached command

```bash
cd "$PROJECT_ROOT"
$TEST_CMD $EXTRA_ARGS 2>&1 | tail -30
exit_code=${PIPESTATUS[0]}
```

Where `$EXTRA_ARGS` derives from skill args:
- `-k <kw>` → append `-k <kw>` for pytest/vitest
- bare path arg → append the path (works for pytest, vitest, jest)

## Phase 3 — Result analysis

Parse the tail output for common failure signatures:

| Pattern | Action |
|---|---|
| `test command not found` / `No such file or directory` | Cache stale — re-run with `--refresh` once, then re-execute |
| `FAILED`/`failed`/`Error:` summary | Surface the first failure with file:line; suggest reading the source |
| `ImportError`/`ModuleNotFoundError` | Surface the missing module; suggest `pip install -e .` or check venv |
| All pass | Continue to thoroughness phase |

## Phase 4 — Thoroughness nudges (skip if --only)

Even if tests pass, ask:

1. **Did the change touch tests that AREN'T in this run?** Run `Grep` for the function/class name across all test files. If hits in other test files NOT covered by current command, suggest running those too.
2. **Coverage?** If framework supports it (`pytest --cov`, `vitest --coverage`), offer to add it.
3. **Type/lint?** Ask if `mypy` / `tsc --noEmit` / `eslint` / equivalent should run before declaring done.
4. **Integration vs unit?** If only unit tests ran, point to integration test paths if they exist (`tests/integration/`, `e2e/`).

These are NUDGES — surface them, let the user pick which to actually run.

## Phase 5 — Exit summary

```
─────────────────────────────────────────────────────
  /test ran in <project_root>
─────────────────────────────────────────────────────
  Command:     <test_cmd>
  Framework:   <framework>
  Exit code:   <N>
  Tests:       <N passed, M failed>  (parsed from output)
  Duration:    <Ts>

  Cache hit:   yes/no (detected_at <ts>)

  Thoroughness:
    [ ] adjacent tests not run (3 candidate files in src/auth/__tests__)
    [ ] coverage not measured
    [ ] type-check not run

  Re-run:  /test  (or /test --refresh if framework changed)
─────────────────────────────────────────────────────
```

## Notes

- **Cache invalidation** is intentionally lazy: only on `--refresh` OR on `command-not-found` failure. The cost of a stale cache is one failed run; the win is sub-200ms detection on every other invocation.
- **Per-folder cache:** `src/auth/` and `src/api/` might cache differently if they have nested configs. Walk-up logic finds the nearest project root.
- **Don't pre-cache:** wait for first /test invocation; no eager scanning.
- **The detect.sh script is the source of truth** for framework support. To add a new framework, edit there.

## See also

- `scripts/test/detect.sh` — the cache manager
- `~/.claude/cache/test-patterns/` — cached entries
