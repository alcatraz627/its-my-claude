---
migration: 0016
title: Add selective CLI access gating (PreToolUse hook + cli-gating policy)
session: claude-audit-2e@2026-05-21
status: complete
date: 2026-05-21
---

# Migration 0016 — Selective CLI Access Gating

## Why

Prod-write commands to deployment CLIs (render, vercel, gh) had no middle tier between coarse allow/deny. This adds a PreToolUse[Bash] hook that hard-stops prod / unknown-env writes so the human confirms, while reads + proven-dev writes pass freely.

Design rendered via `/magi --mode lite` (archive `~/.claude/assets/magi/20260521-0509-cli-gating-design/`). Per gcc-hygiene: a new top-level script dir + a new settings.json hook + a new convention file each require a migration entry.

## What changes

| Addition | Path |
|---|---|
| New scripts dir | `~/.claude/scripts/cli-gating/` (gate-cli-actions.sh, gate_cli_actions.py, test-gates.sh) |
| New policy config | `~/.claude/conventions/cli-gating.json` (JSON not YAML — no PyYAML dependency on this machine) |
| New PreToolUse hook | `settings.json` PreToolUse[Bash], inserted right after `safe-delete.sh` |
| New runtime markers | `~/.claude/cli-gating.off` (kill switch), optional per-project `<cwd>/.claude/cli-gating.json` (tighten-only) |

## Key design decisions (from the /magi deliberation + verification)

- **exit-2 hard-block, NOT native `permissionDecision:"ask"`.** Reason: the installed `claude` alias uses `--allow-dangerously-skip-permissions`, under which the `ask`/`deny` permission path can be inert. exit-2 fires regardless of permission mode. (CC#39344 — the ask-overrides-deny bug voter-3 cited — was real but fixed in v2.1.101; this machine runs v2.1.145. The skip-permissions reason is the load-bearing one. See archive `08-verification-39344.md`.)
- **JSON config, not YAML.** PyYAML is not installed; a YAML config would have silently fallen back to a hardcoded policy. JSON uses the stdlib.
- **allowlist-of-read-verbs + fail-closed**, prove-dev-or-treat-as-prod, per-CLI `default_env` (vercel default=dev/preview-safe; render default=prod).

## What does NOT change

- No existing paths renamed or removed.
- Existing PreToolUse hooks (safe-delete, prefer-ripgrep, block-nested-claude, etc.) untouched — disjoint command sets, no double-prompts.
- settings.json backed up to `settings.json.bak-cligating-20260521`.

## Skeptical review + hardening (2026-05-21)

A Stop-hook-forced `/skeptical-review` (fresh adversarial sub-agent) caught two classes of defect that the original 40-case suite missed — logged as atone `mist-20260521-001233-cf` (S3):

1. **The live shim loaded `cli-gating.yaml` after the config was converted to `.json`** — `load_policy` silently fell back to a divergent hardcoded policy, so the live hook never ran the audited JSON. The test suite passed only because it called the Python core directly with the JSON path, never the shim. **Fixed:** shim now loads `.json` (3 refs); test suite now includes end-to-end cases piping hook JSON through the shim.
2. **5 confirmed bypass families** (demonstrated by execution): absolute-path / launcher-wrapper (`/usr/bin/gh`, `env`, `nohup`, `timeout`, `sudo`) dodging the literal-name test; `&` background separator not split; process substitution `<()` undetected; `gh api -X DELETE` masked as a read; dev-signal substring smuggled into a quoted arg; `vercel promote/alias` auto-allowed. **All fixed** — basename+launcher normalization, `&`/process-sub separators, gh-api method gating, token-level signal matching, vercel `safe_default_verbs` catch-all.

## Verification

- [x] `test-gates.sh` — **56/56 core + 10/10 end-to-end-through-shim**, incl. all 12 reviewer-demonstrated bypasses + false-positive guards
- [x] Tests now exercise the PRODUCTION entry point (the shim), not just the inner Python core
- [x] settings.json valid JSON after edit; hook re-enabled post-hardening
- [x] Skeptically reviewed (report: `assets/reports/20260521-skeptical-review-cli-gating/review.md`)
- [ ] /gate-add skill (deferred to a follow-up — JSON is hand-editable in the meantime)
- [ ] kubectl gate (Phase 2 — kubeconfig-context env authority)
- [ ] Project-level tighten-only merge (currently project policy fully replaces global when present)

## False-positive fix (2026-05-21, from real agent incidents)

Reviewed last-2-day transcripts across 4 sessions/projects (frontend, a Versable sub-agent, i-dream) — agents were getting blocked on legitimate work. Four false-positive classes, all from one root error (treating "a gated CLI NAME appears" as "a gated WRITE is happening"):

| FP | Incident | Fix |
|---|---|---|
| reads with `--jq`/`--json` (`gh run view … --jq '{…'`) | shlex fails on the filter → unparseable-fallback blocked any segment starting with `gh` | read-verb allowlist now checked FIRST, even when the segment fails to tokenize (best-effort verb) |
| `bash render-visual.sh` | `\brender\b` matched the substring in the script name | gated CLI must now be the COMMAND TOKEN (basename-equal), never a substring |
| `cat > file <<HEREDOC` (no gated CLI) | >50-segment cap fired regardless of gated-CLI presence | cap now applies ONLY when a gated command is actually present |
| `RID=$(gh run list …)` (read) | substitution check blanket-blocked any gated name in `$()` | substitutions now CLASSIFIED by content — a gated read inside `$()` passes |

Core principle, revised: **gate only when a gated CLI is the actual command token AND it's a write.** Reads always pass; script-names/substrings/no-CLI commands pass. Launcher/shell-wrapped WRITES (`env gh`, `/usr/bin/gh`, `bash -c "render deploy --prod"`, `eval "…"`) still gated. `eval` and `bash -c` now recurse into their content (a wrapped read passes, a wrapped write blocks). Tests: 66 core + 10 shim, incl. a regression row per incident.

## False-NEGATIVE fix (2026-05-22, from skeptical-review)

The false-positive fix above over-corrected — a skeptical-review found the gate had swung permissive and now let real prod WRITES through. Confirmed + fixed:

| Sev | Slip (was ALLOW, now BLOCK) | Fix |
|---|---|---|
| CRITICAL | `render services delete` / `env-vars set` / `deploys cancel` — a read-namespace prefix laundered a write subcommand | `MUTATING_SUBCMD` override: a mutating sub-verb (delete/set/scale/cancel/…) anywhere skips the read-allowlist |
| CRITICAL | `bash -lc 'render deploy --prod'` — combined `-lc` flag dodged the `-c` recursion | SHELL_C now matches `-c` AND combined short flags ending in `c` (`-lc`/`-xc`) |
| HIGH | `vercel deploy -p` / `--prod=true` / `--target production` / `--target=production` | added prod_signals (`-p`, `--target production`); `_split_eq` normalizes `--key=val` before signal matching |
| MEDIUM | adapter dedupe `grep -qF` → substring false-match | `grep -qxF` (exact line) |
| LOW | hook-feedback id entropy + `slowed-me-done` typo | +PID +8 hex; typo fixed |

Lesson (over-correction): a gate has TWO failure directions; fixing false-positives needs a paired "did a real write just start passing?" check. Tests: **82 core + 10 shim**, with a BLOCK row per demonstrated slip AND an ALLOW row per namespace read (proving no swing-back). Reviewed; coverage recorded. (`gh pr merge feature/main-work` blocking is accepted — pr merge gates regardless; only the reason string is imprecise.)

## Honest threat-model note

This hook is a **seatbelt against accidental prod writes, not a vault door.** The hardening closes accidental footguns and single-token evasions, but a determined bypass (e.g. a wrapper script the classifier can't see into) remains possible by design. Scoped API tokens are the real boundary.
