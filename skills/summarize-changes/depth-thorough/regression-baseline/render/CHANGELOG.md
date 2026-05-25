# v5.0 Engineering Changelog

Scope: ~1209 files / ~273 commits. Worker reliability + observability + jobs UI polish + auth/cycles gate. Many commits cited as "see git log" — work landed on development-branch tips post-TSV cutoff; for exact attribution use `git log --since=<release-fork-point>`.

> ⚠ BREAKING — USER-VISIBLE (read before deploy)
>
> - **TanStack Query persist removed** — `PersistQueryClientProvider` is gone; returning users no longer have a localStorage cache. First jobs-list paint after a long idle reloads from network (1-2s). `refetchOnWindowFocus` and `refetchOnReconnect` also dropped.
> - **Scraper-success refund flow rewritten** — client-side `processCreditsGroup` fan-out replaced by unified `refundCreditsDb` server action. New S4 credit-cycle picker, new `PartToRefund` shape, `excludedColumns` is now `Map<sheet, Set<col>>` (per-sheet granularity).
> - **Structured job-output errors** — backend now emits `{cause_code, cause_context}` envelope; FE renders user-facing messages by switching on the code. Customer-facing error text may shift slightly (more specific, less generic).
> - **Deferred-task state surfaced in UI** — items can show a new inline "deferred" badge when a breaker opens or retry budget is exhausted; self-recovers once cooldown elapses.
> - **Pause/Resume/Hard-delete on jobs and items** — new progress cell with paused state + inline resume button.
> - **Job-output preview/export** — new visibility filtering (`internal` / `admin_only`), `include_errors` / `include_metadata` flags, FE `excludeUnmappedFields` export option.

> 🔧 BREAKING — INTERNAL ONLY (engineering coordination)
>
> - **Internal API auth refactor** — cookie+password (`_DASHBOARD_PASSWORD`, `_DASHBOARD_COOKIE_NAME`, `require_dashboard_auth`) removed wholesale. Replaced by HMAC `x-api-token` header (`ADMIN_API_TOKEN`) via `InternalApiDependency`. No compat layer.
> - **`FilterTabsV2` props signature replaced** — internal-state props (`cacheKey`, `setTabFilter`, `_tabState`) removed; component now external/URL-driven via `useQSync`. All in-tree callers migrated.
> - **`src/data/jobs.data.ts` split** — into `src/data/jobs/` submodule (actions, api, display, export, job-state, list-filter, output, row-cells, status). `data-history-v3.utils.ts` and `modals/job.utils.tsx` deleted.
> - **`getAppDeploymentUrl()` → `DeployInfo.AppUrl` constant** — 8+ async callsites de-async'd; `VERCEL_PROJECT_PRODUCTION_URL` is the new primary source.
> - **Gemini → Vertex AI** — all image-gen client init switched from `GEMINI_API_KEY` to `VERTEX_API_KEY` with `vertexai=True`. Missing env-var = boot fail.
> - **Backend logger consolidation** — `lib/logging/` is the single config point; per-worker loguru handler overrides removed.
> - **Slack webhook routing** — callers name a `SlackTopic`; URL choice handled by `channels.py` with cascade fallback. New webhooks: INCIDENTS, DEFERS, DAILY, PREFLIGHT, REAPER.
> - **`pipeline_steps` collection removed from code** — writes + reads + type definition gone. Mongo collection drop is OPS task #85 (post-deploy grace).
> - **Tooltip system rewrite** — `ShowTooltip` wrapper phased out; callers spread `data-tooltip-*` props instead.
> - **`SessionRefreshObserver`** — gutted to no-op stub. Export still resolves; importers expecting side-effects get silently no-op.

> ✅ PRE-DEPLOY CHECKLIST (must complete before merge)
>
> - [ ] Env vars set on prod Render env-group: `ADMIN_API_TOKEN`, `VERTEX_API_KEY`, `WORKER_BREAKER_*` (incl. `WORKER_BREAKER_IS_GLOBAL`), `WORKER_RETRY_BUDGET_PER_MIN`, `WORKER_DRAIN_TIMEOUT_SEC`, `WORKER_MAX_DEFER_COUNT`, `JOB_OUTPUT_CACHE_TTL_SEC`, `JOB_LIFECYCLE_CACHE_TTL_SEC`, `LOGGER_CRAB_*` (if enabling crab sink), `E2E_TEST_SECRET`, `CRON_SECRET` (Vercel), `PREFLIGHT_ENABLED`
> - [ ] Slack webhook URLs configured: `SLACK_CIRCUIT_BREAKER_WEBHOOK_URL`, `SLACK_DAILY_REPORT_WEBHOOK_URL`, `SLACK_DEFER_ALERT_WEBHOOK_URL`, `PREFLIGHT_REPORT_WEBHOOK_URL` (cascade falls back to `SLACK_WEBHOOK_URL` but dedicated channels are the design intent)
> - [ ] Postgres: `team_credit_allocation` table exists in prod, populated for all active teams, indexed on `(team_id, cycle_start, cycle_end, deleted_at)`; confirm `cycle_start`/`cycle_end` are `DATE` columns (asyncpg requires `datetime.date`, not isoformat)
> - [ ] Mongo: confirm `tasks.(item_id, added_at desc)` index exists (preview aggregate) — boot creates 6 new indexes; verify they reached steady state
> - [ ] Cron jobs: `/api/cron/expiring-cycles` (daily 14:00 UTC, Vercel cron — needs `CRON_SECRET`); `daily_worker_stats` (24h in-process scheduler, no external cron)
> - [ ] External services: `VERTEX_API_KEY` provisioned in dev + staging + prod env-groups; Sentry release tag confirmed
> - [ ] Post-deploy: drop `pipeline_steps` Mongo collection after 1-2 week grace period (task #85)
> - [ ] First-boot tuning: set `JOB_OUTPUT_CACHE_TTL_SEC=60` initially, consider `JOB_OUTPUT_CACHE_DISABLED=true` for first boot, tune up after stable
> - [ ] Confirm NO prod env-group has `INTEGRATION_CHAOS_ENABLED=true` — chaos.py would silently drop Mongo writes if enabled
> - [ ] Verify `app.versable.ai` host guard on `_e2e_test.py` covers custom-domain CNAMEs and www. variants
> - [ ] Audit env keys on Render dev + prod env-groups (task #63) — 52+ new Config knobs; block deploy on completion
> - [ ] Verify gh-pages concurrency: `docs-deploy.yaml` and `frontend-e2e-test.yaml` share `gh-pages-deploy` group with `cancel-in-progress: false` — watch queue depth post first scheduled run

---

# Major Features

## circuit-breaker-resilience

Per-worker circuit breaker with a fleet-level consensus layer so transient downstream failures stop being retried into a storm. Local breakers trip independently; once a quorum trips in a window, the fleet marks the bucket open in Redis and a single half-open probe controls recovery. Per-customer scoping via `(module, team_id)` keys when `WORKER_BREAKER_IS_GLOBAL=0`.
Files: `backend/lib/breakers/__init__.py`, `backend/lib/breakers/local.py`, `backend/lib/breakers/consensus.py`, `backend/lib/breakers/decorator.py`, `backend/lib/breakers/scope.py`
Risk: high
Commits: see git log

## retry-budget

Fleet-wide retry budget primitive in Redis. When `WORKER_RETRY_BUDGET_PER_MIN` is exhausted on a downstream bucket, further retries fail fast with `RetryBudgetExhausted`, preventing a retry storm during incidents.
Files: `backend/lib/redis/retry_budget.py`, `backend/lib/helpers/retry.py`, `backend/tests/redis/test_retry_budget.py`
Risk: medium
Commits: see git log

## resilient-decorator

`@resilient` composes circuit breaker (outermost) + retry budget (innermost) into one annotation. Opt-in per pipeline-method/IO callsite. Includes `STANDARD_TRANSIENT` exception tuple and `swallow_resilience_failures` context manager.
Files: `backend/lib/breakers/decorator.py`, `backend/tests/breakers/test_decorator.py`
Risk: medium
Commits: see git log

## deferred-task-outcome

New `TaskOutcome.deferred`: when a breaker opens or retry budget is exhausted mid-task, the task is parked with `next_eligible_at` cooldown and `defer_count++` instead of failing. Past `WORKER_MAX_DEFER_COUNT` the task terminal-fails with `deferred_max`. FE surfaces an inline "deferred" badge.
Files: `backend/lib/tasks/claimer.py`, `backend/lib/tasks/task_runner.py`, `backend/lib/types/__init__.py`, `backend/tests/integration/test_deferred_e2e.py`, `frontend/src/app/jobs/(list)/utils/job-output.errors.ts`
Risk: high
Commits: see git log

## worker-heartbeat-redis

Worker liveness moves from Mongo `active_workers` (leaks on crash) to Redis `worker:hb:{id}` with a 15s rolling TTL. `/workers` endpoint returns intersection of Mongo + Redis; dead workers filtered out. Mongo retains 24h TTL on `terminated_at`.
Files: `backend/lib/redis/worker_heartbeat.py`, `backend/worker/heartbeat.py`, `backend/api/workers.py`, `backend/api/internal/dashboard.py`
Risk: medium
Commits: see git log

## heartbeat-reaper

Reaper scans for tasks holding stale Redis heartbeats past a grace window and releases their locks. Reaper releases emit a summary alert to Slack.
Files: `backend/lib/tasks/heartbeat_reaper.py`, `backend/cron/notify_jobs.py`, `backend/tests/tasks/test_heartbeat_reaper.py`
Risk: medium
Commits: see git log

## cycle-bucket-quota-gate

Redis "cycle bucket" fast-path check on every task pickup validating the team still has an active credit cycle. Three-state model (HIT / NEGATIVE-CACHE / MISS) with TTL clamped to cycle end and a refresh lock against thundering herd.
Files: `backend/lib/redis/cycle_bucket.py`, `backend/lib/tasks/claimer.py`, `backend/worker/workerspot.py`, `backend/worker/workerv2.py`
Risk: high
Commits: see git log

## graceful-worker-drain

Workers drain in-flight tasks on SIGTERM (configurable `WORKER_DRAIN_TIMEOUT_SEC`) before exiting. Signal handling moved into asyncio loop.
Files: `backend/worker/drain.py`, `backend/run_workers.py`, `backend/tests/worker/test_drain.py`
Risk: medium
Commits: see git log

## audit-events

Typed `audit_events` collection (90-day TTL, 5 indexes) tracking every job/task/item state transition with actor, before/after state, correlation_id, parent_event_id. Replaces ad-hoc log-only auditing. Slack-pings on write failure but never blocks the recorded action.
Files: `backend/lib/audit/__init__.py`, `backend/lib/types/audit_events.py`, `backend/lib/database/__init__.py`
Risk: medium
Commits: see git log

## job-pause-resume-hard-delete

First-class pause/resume/cancel/hard-delete on jobs and per-item. Adds `Status.paused` (non-terminal, invisible to claimer), `POST /{job_id}/pause|resume`, `DELETE /{job_id}/hard`, `POST /items/{item_id}/pause|resume`, plus new FE progress cell with paused state and gray bar fill.
Files: `backend/api/jobs.py`, `backend/api/tasks.py`, `backend/lib/jobs/lifecycle.py`, `frontend/src/app/jobs/(list)/components/progress-cell.tsx`, `frontend/src/data/jobs/actions.ts`
Risk: high
Commits: see git log

## admin-force-status

Admins can override an item's terminal state (`canceled` | `failed` | `completed`) with a reason; the latest task flips unconditionally and an `admin_override` is appended to `item.errors`. Includes `undo-force-status` that replays the prior audit event's `before_state`. Surfaced via admin UI on the team page.
Files: `backend/api/tasks.py`, `backend/lib/tasks/admin.py`, `backend/tests/integration/test_admin_override_flow.py`
Risk: high
Commits: see git log

## job-duplicate-stage1

`POST /{source_job_id}/duplicate` creates a new Stage-1 job copying `wizard_state` so the FE can pre-fill the upload wizard. Stage 2 (pipeline + tasks) deferred (task #78).
Files: `backend/api/jobs.py`, `backend/lib/jobs/__init__.py`
Risk: low
Commits: `155ab80f`

## widgets-v2

`src/core/widgets-v2/` primitive set: orchestrator hook (`useWidget`), `WidgetTable`, `WidgetToolbar`, `SelectionColumn`, `ResetFiltersButton`, plus `use-search-filter` / `use-selection-state` hooks. State syncs to URL via `useQSync`. Powers new `/admin/jobs` and is the planned replacement for ad-hoc table wrappers.
Files: `frontend/src/core/widgets-v2/index.ts`, `frontend/src/core/widgets-v2/use-widget.ts`, `frontend/src/core/widgets-v2/widget-table.tsx`
Risk: medium
Commits: see git log

## use-query-sync

Bidirectional URL ↔ React state sync (`useQSync`) — framework-free RSC-safe primitives, codecs (string/number/bool/array/json/base64), per-key debounce, dev-time `window.__qSync` registry, presets, cross-instance pub/sub (`share: true`). 12 new files with full test coverage.
Files: `frontend/src/utils/hooks/use-query-sync/index.ts`, `core.ts`, `codecs.ts`, `emitter.ts`, `presets.ts`, `registry.ts`
Risk: medium
Commits: see git log

## client-logger

Production-grade FE logger with isomorphic context (AsyncLocalStorage on server, module state on client), PII masking, per-browser-visit `logger_sid` cookie (7d), and 5 sinks: console, file (dev), memory-buffer (dev-on/prod-off, localStorage-persisted), browser→server (POST `/api/log` batch), and server→logger-crab. Auto-instruments `withServer` and `routeWrapper` with request-id binding.
Files: `frontend/src/utils/logger/index.ts`, `context.ts`, `mask.ts`, `session-id.ts`, `sinks/browser-server-sink.ts`, `sinks/crab-sink-shared.ts`
Risk: medium
Commits: see git log

## admin-logs-page

New `/admin/logs` page with three tabs: Memory (in-page ring buffer via `useSyncExternalStore`), Crab (fetches logger-crab dashboard at 5s interval), Demo (12 buttons emitting synthetic events across all severities). Includes 6 demo server actions for end-to-end smoke testing.
Files: `frontend/src/app/admin/logs/page.tsx`, `demo-view.tsx`, `crab.actions.ts`, `actions.ts`
Risk: low
Commits: see git log

## admin-all-jobs-page

`/admin/jobs` (451 lines) showing every job across all teams with search, team / status / job-type / deleted filters, URL-synced pagination, 10s refetch, preview-output modal on row click. Built on `widgets-v2`.
Files: `frontend/src/app/admin/jobs/page.tsx`, `frontend/src/app/admin/admin.data.ts`
Risk: low
Commits: see git log

## image-gen-color-remap

Color-remap pipeline migrates from single-shot to retry loop with structural validation (edge-IoU 70% + edge-weighted SSIM 30%). 4-strategy entry point (target image / swatch file / color text / hex direct), per-attempt S3 upload, `is_best` selection, Flash-vs-Pro model selector. Public response now carries `attempts[]` + `similarity_score`. Migrates Gemini client init to Vertex AI (`VERTEX_API_KEY`).
Files: `backend/lib/providers/nanobanana/color_remap.py`, `structural_validation.py`, `gemini.py`, `backend/api/image_enhancement.py`
Risk: high
Commits: `2992cf3d`, `41a7dd6f`, `7c9326fb`, `86705286`, `1b0e27f6`, `b36127c9`

## cycles-cron-monitoring

Vercel cron (`/api/cron/expiring-cycles`, daily 14:00 UTC) scans team credit allocations within 3-day and 12-day horizons, classifies urgency into 5 tiers (alarm/critical/warning/watch/ok), posts a Block Kit report to Slack with admin contacts per team. Full Vitest suite for pure helpers.
Files: `frontend/src/app/api/cron/expiring-cycles/route.ts`, `team-health.utils.ts`, `cron.utils.ts`, `frontend/vercel.json`
Risk: medium
Commits: see git log

## pg-team-credit-allocation-gate

Backend validates an active credit cycle exists in Postgres (`team_credit_allocation`) on `create_job` and on every worker task pickup. New `get_active_cycle_for_team(team_id)` (asyncpg, queries by `datetime.date`). Mirrors cycle bucket fast-path; PG is source of truth.
Files: `backend/api/auth_db.py`, `backend/api/jobs.py`, `backend/lib/jobs/__init__.py`
Risk: high
Commits: see git log

## dev-tools-inspector

Dev-only `AppDevInspector` portal (bottom-right). Module-based: `qsync-module` (live URL/dict/value rows from `qSyncRegistry`) and `settings-module` (flag status grid + memory-buffer toggle).
Files: `frontend/src/core/dev-tools/app-dev-inspector.tsx`, `modules/qsync-module.tsx`, `settings-module.tsx`
Risk: low
Commits: see git log

## error-boundaries-and-default-error-page

Next.js segment error boundaries on `/`, `/account`, `/admin`, `/files`, `/jobs` via shared `DefaultErrorPage`. `error-boundary.tsx` extended with `AppErrorFallbackProps` for react-error-boundary ↔ Next.js compatibility.
Files: `frontend/src/core/page/default-error.tsx`, `frontend/src/app/admin/error.tsx`, `account/error.tsx`, `files/error.tsx`, `jobs/error.tsx`
Risk: low
Commits: see git log

## scraper-requests-dashboard

`GET /internal/scraper/requests/enriched` filters scraper requests by team/job/status/deleted, derives status from `custom_job_values.status` → `scraper_config.last_status` → `pending|missing` cascade (mirrors FE), enriches each row with owner details via single Postgres round-trip.
Files: `backend/api/internal/scraper.py`, `backend/api/internal/helpers.py`
Risk: low
Commits: see git log

## fe-worker-redis-cache

New `"use server"` Redis-namespace caching primitive declaring `_workerNamespaceRedis: Redis` singleton, integrates with `DeployInfo`. Likely consumed alongside `cycle-bucket-quota-gate` / `pg-team-credit-allocation-gate` consumer-side.
Files: `frontend/src/utils/redis/worker-cache.ts`
Risk: medium
Commits: see git log

## be-unauthorized-server-handler

Server-action utility for graceful 401 handling from Python-BE (distinct from client axios interceptor) + 149-line test suite. BE-401 → cookie clear + redirect server-side.
Files: `frontend/src/utils/permission/handle-backend-unauthorized.server.ts`, `.test.ts`
Risk: low
Commits: see git log

## slack-fe-channel-data

`SlackChannelWebhooks` data module on FE side (UserSupport / ScrapeRequest / CustomerReports / DevLogs env-var map). `slack.ts` shrinks from hardcoded actions to a 3-line stub. Companion to BE slack-webhooks-architecture.
Files: `frontend/src/utils/slack/slack.data.ts`, `slack.ts`, `slack.server.ts`, `slack.type.ts`
Risk: low
Commits: see git log

# Improvements

## jobs-list-aggregates

Jobs list ships in two modes: lean (existing) and enriched (`include_aggregates=true`) which inlines per-status item counts via new `jobs/aggregations.py` Mongo pipeline. Drops legacy `items_count`, adds `processed_count` semantic fix (terminal state, not success-only), reconciliation cron, `isJobTerminalCheap` helper.
Files: `backend/api/jobs.py`, `backend/lib/jobs/__init__.py`, `backend/lib/jobs/aggregations.py`, `backend/scripts/reconcile_run_processed_count.py`, `frontend/src/data/jobs/job-state.ts`
Risk: medium
Commits: see git log

## job-output-rendering-refactor

Output / preview / export pipeline restructured into typed modules: `formats/cache.py`, `errors.py`, `metadata.py`, `runner.py`. Adds output caching (`JOB_OUTPUT_CACHE_TTL_SEC`), visibility filtering (internal / admin_only), `include_errors` / `include_metadata` flags, `excludeUnmappedFields` export option.
Files: `backend/lib/jobs/formats/cache.py`, `errors.py`, `runner.py`, `metadata.py`, `functions.py`, `types.py`, `frontend/src/app/jobs/(list)/components/export-output.tsx`
Risk: medium
Commits: see git log

## sentry-centralization

Sentry init consolidated into `lib/sentry/__init__.py` — single entry point, env (local/development/production) + release tag from `Config`. Fixes prior misclassification (dev service with `DEBUG=False` reported as production).
Files: `backend/lib/sentry/__init__.py`, `backend/run_worker.py`, `backend/run_workers.py`, `backend/pipeline_runner.py`, `backend/lib/config/app_init.py`, `frontend/sentry.server.config.ts`
Risk: medium
Commits: see git log

## modal-url-sync

Modals can sync to URL via `useModal({ urlSync })`. Adds `ModalUrlKeys` registry, lifts modal state out of per-row components to the table level (prevents stacked duplicates), replaces `PreviewId` setParam with URL-synced atom. Powers preview-job-output modal flow.
Files: `frontend/src/core/modal/modal.tsx`, `modal.utils.ts`, `modal.data.ts`, `frontend/src/app/jobs/(list)/data-history-v3/data-history-v3.table.tsx`
Risk: low
Commits: see git log

## image-gen-key-resolution

Image-gen output column key resolution now follows typed priority chain (`options.image_gen_key` → `generated_columns` registry by role → `pipeline_history` legacy fallback → `DEFAULT_IMAGE_GEN_KEY_NAME`). FE `getJobSpecificOptions` reads `metadata.generated_columns` first (v2.1+), pipeline_history fallback for older jobs. 318-line BE test for priority chain + color_remap dedup.
Files: `backend/tests/job_outputs/test_keys.py`, `frontend/src/utils/hooks/use-job-data.ts`, `backend/lib/jobs/formats/functions.py`
Risk: medium
Commits: `43d027d4`, `1ecc0da5`

## badge-system-css

New `.badge-text` base class + 8 color variants (primary/secondary/accent/neutral/info/success/warning/error) with `.badge-shade` modifier. Adds numeric `--secondary-dark-num: 137 176 205` CSS var so opacity modifiers work via `rgb()`.
Files: `frontend/src/app/globals.css`
Risk: low
Commits: see git log

## enhancement-agent-v2-product-type

`EnhancementAgentV2` Input gains optional `product_type` field that conditionally swaps the system-prompt header between "universal" and product-specific. New sample test pipeline `007_ENHANCEMENT_AGENT_V2_Custom.json` with HVAC Parts.
Files: `backend/lib/agents/EnhancementAgentV2.py`, `backend/pipeline-files/tests/007_ENHANCEMENT_AGENT_V2_Custom.json`
Risk: low
Commits: see git log

## structured-cause-fe-render

FE migrates from regex-matching error message strings to switching on stable `cause_code` and interpolating `cause_context`. Eliminates the documented anti-pattern in `~/.claude/rules/error-classification.md`. Adds `failActionMessage` helper.
Files: `frontend/src/app/jobs/(list)/utils/job-output.errors.ts`, `frontend/src/utils/error.ts`, `frontend/src/data/jobs/output.ts`
Risk: low
Commits: see git log

## lookup-route-and-helper-cleanup

New `AdminRoutes.Jobs` + `AdminRoutes.AdminLogs` route constants, `AuthRoutes.GetPasswordReset(token)`, `app-links.utils.ts` expanded with job/scraper link generators. `icons.ts` consolidates `react-icons` imports under `IconFor` enum.
Files: `frontend/src/utils/routing.ts`, `frontend/src/utils/core/app-links.data.ts`, `app-links.utils.ts`, `frontend/src/utils/icons.ts`
Risk: low
Commits: see git log

## dev-console-filter

New dev-only `console.error` allowlist suppressor + 89-line test suite. Filters known-noisy console messages in development so real errors stay visible.
Files: `frontend/src/utils/dev-console-filter.ts`, `.test.ts`
Risk: low
Commits: see git log

## upload-wizard-v2-polish

S1 upload page refactor (+155 lines) and s2\* family non-trivial updates (`s2ig-apply-image-gen.tsx` +93 -14, etc.). FE upload-wizard surface changes for v2 — distinct from BE `image-gen-color-remap`.
Files: `frontend/src/app/jobs/v2/pages/s1-upload.tsx`, `s2ig-apply-image-gen.tsx`
Risk: medium
Commits: see git log

# Fixes

## session-refresh-disabled

`SessionRefreshObserver` gutted to no-op stub. `router.refresh()` on auth transitions was racing in-flight soft navigations causing "snap-back" — see `docs/known-issues/nav-snapback-race.md`. SignOut now also drops the `logger_sid` cookie and no longer calls `revalidateTag("token")` (avoided 401 bursts per ADR-007).
Files: `frontend/src/core/auth/session-refresh-observer.tsx`, `frontend/src/app/api/auth/[...nextauth]/auth-options.ts`
Risk: medium
Commits: see git log

## credit-worker-shutdown-safety

Standalone `credit-worker/run.ts` hardens shutdown: explicit `shuttingDown` flag, SIGINT+SIGTERM handlers gracefully close Redis + PG pool, main loop changes to `while (!shuttingDown)`, exit guard in BRPOP catch. Removes bespoke logger wrapper in favor of `console.*`. Standalone `_package.json` deleted (consolidated into root).
Files: `frontend/credit-worker/run.ts`, `frontend/credit-worker/banner.svg`
Risk: medium
Commits: see git log

# Performance

## mongo-indexes

6 new Mongo indexes created on boot: `tasks.(item_id, added_at desc)` (preview aggregate), `tasks.(next_eligible_at)` sparse (deferred-cooldown), `tasks.(job_id, added_at desc)` (getJobAggregates), `redis_history._expires_at` TTL, `active_workers.terminated_at` TTL 24h, 5 indexes on `audit_events` (kind+ts, target, actor, team+kind, correlation_id) + 90-day TTL.
Files: `backend/lib/config/app_init.py`
Risk: low
Commits: see git log

# Infrastructure

## integration-test-framework

Full harness: scenario YAML runner (`scenario_runner.py`, 838 lines), job-run timeline recorder (Mongo polling + Redis snapshots, change-stream fallback + SQLite sink), HTML swimlane viewer (`flow.html` + 1772-line `flow-app.js`), multi-run aggregator, 9 scenario YAMLs (HP1, HP2, B4, B7-B11). Gated by `INTEGRATION_CHAOS_ENABLED` and `INTEGRATION_HTTP_CAPTURE_PATH`.
Files: `backend/scripts/integration/scenario_runner.py`, `run_all.py`, `recorder/flow_builder.py`, `mongo_poller.py`, `redis_snapshotter.py`, `sqlite_sink.py`, `scenarios/*.yaml`
Risk: low (test-only)
Commits: see git log

## mock-pipeline

`MockPipelineMethod` with three knob tiers for controllable-failure testing: latency, retryable/terminal errors, structured error payload (Tier 1); `resilient_wrap`, `retry_hiccup_after` (Tier 2); adversarial probes (`hog_resource_ms`) (Tier 3). Used by chaos scenarios.
Files: `backend/lib/pipeline/methods/mock.py`, `backend/tests/pipeline/test_mock_tier2.py`, `test_mock_tier3.py`
Risk: low (test-only)
Commits: see git log

## chaos-injection

Test-only chaos module that monkey-patches `AsyncTaskClaimer._transition` to drop writes based on a Redis-gated injection key (counted or infinite mode, auto-clearing). Hard import gate raises `ImportError` unless `Config.INTEGRATION_CHAOS_ENABLED=True`.
Files: `backend/lib/integration/chaos.py`, `__init__.py`, `backend/tests/integration/test_integration_chaos.py`
Risk: medium (if accidentally enabled in prod)
Commits: see git log

## http-capture-middleware

Env-gated ASGI middleware appending one JSONL row per request (`{ts, method, path, query, status, duration_ms, content_length}`) when `INTEGRATION_HTTP_CAPTURE_PATH` is set. Failures swallowed (observability, not load-bearing). Powers integration recorder.
Files: `backend/api/http_capture.py`, `backend/api/util.py`, `backend/tests/api/test_http_capture.py`
Risk: low
Commits: see git log

## preflight-checklist

Prod-boot preflight checklist (`lib/config/preflight.py`, 530 lines) running read-only checks against Mongo / Redis / Postgres / S3 / httpx / breaker consensus / Sentry, classifies each PASS/WARN/ERROR, posts a single Slack report per role per deploy (Redis dedup-lock on commit SHA). Gated by `PREFLIGHT_ENABLED`.
Files: `backend/lib/config/preflight.py`, `backend/lib/config/__init__.py`
Risk: medium
Commits: see git log

## e2e-test-routes

Test-only routes guarded by `E2E_TEST_SECRET` header + blocked on `app.versable.ai` host. BE `_e2e_test.py` exposes `latestJob`, `jobOutput`, `cleanupOrphanJobs` ops. FE `/api/e2e-test/route.ts` mirrors with `credits`, `cleanupOrphans`, `creditLedger`. Powers Playwright suite v2.
Files: `backend/api/_e2e_test.py`, `backend/api/api.py`, `frontend/src/app/api/e2e-test/route.ts`, `frontend/test/utils/db-client.ts`, `cleanup.ts`
Risk: medium (if host guard leaks)
Commits: see git log

## e2e-playwright-suite-v2

Playwright suite restructured into per-step `lib/*` modules (login, account, jobs-list, upload, S2 stages, credits, data-history, general). Adds nav-snapback detection (5s/3s heuristic), per-test console-buffer capture, credit-delta assertions, 4-tier module-recovery guard, run summary report. New `E2E_SUITE_VERSION` constant.
Files: `frontend/test/basic.spec.ts`, `test/lib/login.ts`, `jobs-list.ts`, `upload.ts`, `dashboard-credits.ts`, `test/utils/nav-tracker.ts`, `test-fixture.ts`, `test.utils.ts`
Risk: low (test-only)
Commits: see git log

## gh-pages-portal-and-docs

New gh-pages portal (`/` → `/e2e/`, `/docs/`, `/docs-raw/`) with full E2E reports dashboard (dark/light toggle, pass-rate bar, 14-run trend dots) and Docsify SPA shell for product docs. Python scripts for sidebar + metadata + raw index generation, run by `docs-deploy.yaml`.
Files: `.github/scripts/dashboard-header.html`, `dashboard-footer.html`, `portal-index.html`, `docsify-index.html`, `generate-sidebar.py`, `generate-metadata.py`, `generate-docs-raw-index.py`, `.github/workflows/docs-deploy.yaml`
Risk: low
Commits: see git log

## ci-pr-automation

PR automation: `auto-pr-body.yml` (auto-fill PR body with typed sections, labels, nudge), `claude-code-review.yml`, `commit-nudge.yml`, `label-pr.yml`, `notion-sync.yaml`, tightened `frontend-pr-check.yml`. Concurrency group `gh-pages-deploy` shared between docs and e2e (sequential, no cancel-in-progress).
Files: `.github/workflows/auto-pr-body.yml`, `claude-code-review.yml`, `commit-nudge.yml`, `label-pr.yml`, `notion-sync.yaml`, `frontend-pr-check.yml`
Risk: low
Commits: see git log

## e2e-workflow-hardening

`frontend-e2e-test.yaml` bumps Node 20→22, splits Playwright `install` from `install-deps` (OS deps not cached), changes default `BASE_URL` v3→v4, adds `SLACK_NOTIFY` mode (`all`/`failures`/`off`), keeps 20 most recent reports, adds `.nojekyll`, triggers on `e2e-test-v2/*` branches + 12h schedule.
Files: `.github/workflows/frontend-e2e-test.yaml`, `frontend/scripts/prune-artifacts.sh`, `prune-artifacts.sh`
Risk: low
Commits: see git log

## fiber-snatcher-runtime

Dev-only `fiber-snatcher-runtime.ts` exposes React fiber state to the external `fiber-snatcher` CLI for deterministic state reads + dispatch in dev. Companion `.fiber-snatcher/config.json` declares auth bypass pattern.
Files: `frontend/src/dev/fiber-snatcher-runtime.ts`
Risk: low (dev-only)
Commits: see git log

## scraper-target-fixture

Self-hosted E2E fixture at `public/e2e-fixtures/scraper-target.html` with documented expected extraction values, SVG data-URI product images, specs table, `data-*` attributes for field mapping. Lets scraper test run without depending on any third-party site.
Files: `frontend/public/e2e-fixtures/scraper-target.html`
Risk: low
Commits: see git log

## config-knob-explosion

`Config` gains 52+ new env vars across logging, observability, worker lifecycle, circuit breaker, retry budget, drain timeout, reaper grace, job-output cache, preflight, integration test toggles, admin API token. `ENV` default changes `"development"` → `"local"`. New required vars need Render env-group updates before deploy.
Files: `backend/lib/config/__init__.py`, `backend/lib/config/helpers.py`, `app_init.py`
Risk: high (deploy-blocking if env-groups not updated)
Commits: see git log

# Breaking Changes (full inventory)

## structured-job-output-errors _(user-visible)_

Replaces ad-hoc string-matching with `cause_code` + `cause_context` envelope. FE renders user-facing messages by switching on the code and interpolating context — no more silent drift when BE phrasing changes. Adds `cause_code`, `cause_context`, `status_code` fields on `JobOutputCause`.
Files: `backend/lib/jobs/formats/errors.py`, `frontend/src/app/jobs/(list)/utils/job-output.errors.ts`, `frontend/src/data/jobs/output.ts`
Risk: medium
Commits: see git log

## jobs-fe-modularization _(internal)_

`src/data/jobs.data.ts` split into `src/data/jobs/` submodule (actions, api, display, export, job-state, list-filter, output, row-cells, status). Display helpers moved out of `data-history-v3.utils.ts` (deleted, -160). `modals/job.utils.tsx` deleted wholesale (-315). `useJobActions` consolidates rerun/pause/resume mutations. Any external code importing from legacy paths breaks.
Files: `frontend/src/data/jobs/actions.ts`, `api.ts`, `display.ts`, `export.ts`, `job-state.ts`, `list-filter.ts`, `output.ts`, `row-cells.tsx`
Risk: medium
Commits: see git log

## scraper-success-refund-flow _(user-visible)_

Reworks scraper-success submission: refund path moved from client-side fan-out (`processCreditsGroup` charge+refund) to unified `refundCreditsDb` server action with `PartToRefund` mirroring chargedParts row. Adds "save_stats" step recording versioned `ScraperSuccessStats` to job metadata. Adds credit-cycle picker in S4 (`(Latest)` / `(Job)` / `(Job + Latest)` tags). Changes excluded-columns from `string[]` to `Map<sheet, Set<col>>`. `processCreditsGroup` signature removed `isRefund`.
Files: `frontend/src/app/admin/scraper-requests/scrape-success/steps/s4-finalize-changes.tsx`, `use-scraper-submit.ts`, `utils/helpers.ts`, `utils/types.ts`, `submit-progress.tsx`, `submit-summary.tsx`, `use-scraper-parts.ts`
Risk: high
Commits: `9f00492c` (post-TSV: `c53f3699`)

## tooltip-system-rewrite _(internal)_

`ShowTooltip` wrapper component phased out in favor of data-driven `data-tooltip-*` attributes resolved by `getAppTooltip`. Callers no longer wrap children; instead spread tooltip props on the element. New `tooltip.utils.ts` + tests. Call-site pattern is a contract break for all consumers.
Files: `frontend/src/core/tooltip/tooltip.tsx`, `tooltip.utils.ts`, `tooltip.utils.test.ts`, `frontend/src/core/select-template/select-template.enhancement.tsx`
Risk: medium
Commits: see git log

## deploy-info-cleanup _(internal)_

`await getAppDeploymentUrl()` (8+ async callsites) replaced with static `DeployInfo.AppUrl`. Eliminates async at module-init paths; `config.utils.ts` reads `VERCEL_PROJECT_PRODUCTION_URL` first. `BasePageTitle` adds env label for staging/dev tabs. Author flagged break risk in commit subject.
Files: `frontend/src/utils/env/env.utils.ts`, `frontend/src/app/api/config/config.utils.ts`, `frontend/src/app/admin/info/[token]/page.tsx`, `frontend/src/app/help/[slug]/page.tsx`, `frontend/src/app/layout.tsx`, `frontend/src/data/token.data.ts`
Risk: medium
Commits: `2b58f41b`, `ca8c4235`

## backend-logger-consolidation _(internal)_

New `lib/logging/` is single configuration point for backend logging. Importing the module runs config (idempotent); callers use `PrintLogger(label=...)` or `loguru.logger` directly. Centralizes `LOG_FORMAT` (simple/verbose/minimal/json), removes per-worker overrides. Internal logging-config contract change.
Files: `backend/lib/logging/__init__.py`, `backend/run_worker.py`, `run_workers.py`, `backend/worker/workerv2.py`, `backend/tests/logging/test_logging.py`
Risk: medium
Commits: see git log

## slack-webhooks-architecture _(internal)_

Slack webhook stack split into 4 modules: `_transport.py` (HTTP, 4xx/5xx/429 classification), `blocks.py` (Block Kit primitives), `templates.py` (per-topic Block Kit templates), `channels.py` (topic→webhook routing with cascade fallback). Callers name a `SlackTopic` instead of choosing a URL. New webhooks for INCIDENTS, DEFERS, DAILY, PREFLIGHT, REAPER. `SlackBlockTemplates` namespace expanded — touched-by callers must migrate.
Files: `backend/lib/webhooks/_transport.py`, `blocks.py`, `templates.py`, `channels.py`, `slack.py`, `frontend/src/utils/slack/slack-blocks-templates.ts`
Risk: medium
Commits: see git log

## internal-api-auth-refactor _(internal)_

Internal API routes migrate from cookie+password auth (`_DASHBOARD_PASSWORD`, `_DASHBOARD_COOKIE_NAME`) to HMAC-compared `x-api-token` header (`ADMIN_API_TOKEN`). `require_dashboard_auth` removed; all internal routes use new `InternalApiDependency`. No compat layer — any consumer with cookie-auth bookmark/Postman config 403s on deploy.
Files: `backend/api/auth.py`, `backend/api/internal/__init__.py`, `dashboard.py`, `helpers.py`, `scraper.py`
Risk: high
Commits: see git log

## tanstack-query-persist-removal _(user-visible)_

`PersistQueryClientProvider` removed. `src/core/query/query-client-provider.tsx` deleted (-41). `@tanstack/query-async-storage-persister` and `@tanstack/react-query-persist-client` removed from `package.json`. `react-query.ts` strips `_queryPersister`, `refetchOnWindowFocus`, `refetchOnReconnect`. App now uses plain `QueryClientProvider`; `gcTime` is the only retention layer.
Files: `frontend/src/core/query/query-client-provider.tsx` (deleted), `frontend/src/utils/react-query.ts`, `frontend/package.json`, `package-lock.json`
Risk: high
Commits: see git log

## filter-tabs-v2-refactor _(internal)_

`FilterTabsV2` switches from internal state (`cacheKey`, `setTabFilter`, `_tabState`) to external URL-driven state via `useQSync`. Adds `shallow`, `listenPopState`, other params. Props signature completely changed — every in-tree caller migrated.
Files: `frontend/src/core/tabs/filter-tabs-v2.tsx`
Risk: medium
Commits: post-TSV: `fc813fad`

## vertex-ai-migration _(internal)_

Gemini providers (`lib/providers/gemini`, `lib/providers/nanobanana/gemini.py`, `upscaler.py`, `color_remap.py`) switch from `GEMINI_API_KEY` to `VERTEX_API_KEY` with `vertexai=True`. Any env-group missing `VERTEX_API_KEY` boot-fails. No compat fallback.
Files: `backend/lib/providers/gemini/__init__.py`, `backend/lib/providers/nanobanana/__init__.py`, `gemini.py`, `upscaler.py`, `color_remap.py`
Risk: high
Commits: see git log

## pipeline-steps-collection-drop _(internal)_

`pipeline_steps` Mongo collection removed from codebase entirely (writes + reads + type definition). Migration to drop the actual collection in prod tracked as OPS task #85.
Files: `backend/lib/database/__init__.py`, `backend/api/_inspect.py`, `backend/lib/pipeline/processor/__init__.py`
Risk: low (code-only; ops drop deferred)
Commits: see git log
