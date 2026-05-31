# v5.0 Themes

> ⚠ Breaking changes — top-of-doc callout (per VERIFIER FM-2/FM-3)
>
> - internal-api-auth-refactor
> - tanstack-query-persist-removal
> - filter-tabs-v2-refactor
> - vertex-ai-migration
> - pipeline-steps-collection-drop
> - jobs-fe-modularization
> - scraper-success-refund-flow
> - tooltip-system-rewrite
> - deploy-info-cleanup
> - structured-job-output-errors
> - backend-logger-consolidation
> - slack-webhooks-architecture

> ℹ Ambiguity flags (carried over from V2 + Verifier):
>
> - SHA references are best-effort. Many commits cited are post-TSV-cutoff (development-branch tips). For exact SHA attribution use `git log --since=<release-fork-point>`.
> - Under-reported V1 chunks (04-fe-jobs_p1: 33/50, 06-fe-admin: 40/44) have been spot-recovered via Verifier FM-1. Some long-tail files may still lack a dedicated theme home.
> - Working-tree (unstaged) edits at PR time are noted per theme when known; for inflight inconsistencies see the closed ISS-004 case.

## Theme: circuit-breaker-resilience

Type: feature
Coupling: BE-only
Summary: Adds a per-worker circuit breaker with a fleet-level consensus layer so transient downstream failures stop being retried into a storm. Local breakers trip independently; once a quorum of workers trip in a window, the fleet marks the bucket open in Redis and a single half-open probe controls recovery. Per-customer scoping is supported via `(module, team_id)` keys when `WORKER_BREAKER_IS_GLOBAL=0`.
Files (representative, ≤8): backend/lib/breakers/**init**.py, backend/lib/breakers/local.py, backend/lib/breakers/consensus.py, backend/lib/breakers/decorator.py, backend/lib/breakers/scope.py, backend/lib/breakers/status.py, backend/lib/breakers/errors.py, backend/lib/breakers/notify.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: retry-budget

Type: feature
Coupling: BE-only
Summary: Adds a fleet-wide retry budget primitive in Redis. When `WORKER_RETRY_BUDGET_PER_MIN` is exhausted on a downstream bucket, further retries fail fast with `RetryBudgetExhausted`, preventing a retry storm during incidents.
Files (representative, ≤8): backend/lib/redis/retry_budget.py, backend/lib/helpers/retry.py, backend/tests/redis/test_retry_budget.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: resilient-decorator

Type: feature
Coupling: BE-only
Summary: New `@resilient` decorator that composes circuit breaker (outermost) + retry budget (innermost) into a single call-site annotation. Opt-in per pipeline-method/IO callsite. Includes `STANDARD_TRANSIENT` exception tuple and a `swallow_resilience_failures` context manager for fire-and-forget paths.
Files (representative, ≤8): backend/lib/breakers/decorator.py, backend/tests/breakers/test_decorator.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: deferred-task-outcome

Type: feature
Coupling: FE+BE coupled
Summary: New `TaskOutcome.deferred` path: when a breaker opens or retry budget is exhausted mid-task, the task is parked with a cooldown (`next_eligible_at`) and `defer_count++` instead of failing. Past a configurable `WORKER_MAX_DEFER_COUNT` the task terminal-fails with cause `deferred_max`. FE surfaces an inline "deferred" badge on item rows.
Files: backend/lib/tasks/claimer.py, backend/lib/tasks/task_runner.py, backend/lib/types/**init**.py, backend/tests/integration/test_deferred_e2e.py, frontend/src/app/jobs/(list)/utils/job-output.errors.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 1

## Theme: worker-heartbeat-redis

Type: feature
Coupling: BE-only
Summary: Worker liveness moves from a Mongo `active_workers` row (leaks on crash) to a Redis `worker:hb:{id}` key with a 15s rolling TTL. The `/workers` endpoint now returns the intersection of Mongo and Redis; dead workers are filtered out. Mongo retains a 24h TTL on `terminated_at`.
Files: backend/lib/redis/worker_heartbeat.py, backend/worker/heartbeat.py, backend/api/workers.py, backend/api/internal/dashboard.py, backend/tests/api/test_workers_endpoint.py, backend/tests/redis/test_worker_heartbeat.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: heartbeat-reaper

Type: feature
Coupling: BE-only
Summary: A reaper process scans for tasks holding stale Redis heartbeats past a grace window and releases their locks so another worker can re-claim them. Reaper releases emit a summary alert to Slack.
Files: backend/lib/tasks/heartbeat_reaper.py, backend/cron/notify_jobs.py, backend/tests/tasks/test_heartbeat_reaper.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: cycle-bucket-quota-gate

Type: feature
Coupling: BE-only
Summary: Adds a Redis "cycle bucket" fast-path check that workers consult on every task pickup to validate the team still has an active credit cycle. Three-state model (HIT / NEGATIVE-CACHE / MISS) with TTL clamped to cycle end and a refresh lock to prevent thundering herds.
Files: backend/lib/redis/cycle_bucket.py, backend/lib/tasks/claimer.py, backend/worker/workerspot.py, backend/worker/workerv2.py, backend/tests/redis/test_cycle_bucket.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: graceful-worker-drain

Type: feature
Coupling: BE-only
Summary: Workers now drain in-flight tasks on SIGTERM (with a configurable `WORKER_DRAIN_TIMEOUT_SEC`) before exiting, instead of dropping work mid-flight. Signal handling moved into the asyncio loop.
Files: backend/worker/drain.py, backend/run_workers.py, backend/tests/worker/test_drain.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: audit-events

Type: feature
Coupling: BE-only
Summary: New typed `audit_events` collection (with a 90-day TTL and 5 indexes) tracking every job/task/item state transition with actor, before/after state, correlation_id, and parent_event_id. Replaces ad-hoc log-only auditing. Slack-pings on write failure but never blocks the action being recorded.
Files: backend/lib/audit/**init**.py, backend/lib/types/audit_events.py, backend/lib/database/**init**.py, backend/tests/audit/test_audit_events.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: structured-job-output-errors

Type: breaking
Coupling: FE+BE coupled
Summary: Replaces ad-hoc string-matching on backend error messages with a stable `cause_code` + `cause_context` envelope. FE renders user-facing messages by switching on the code and interpolating context — no more silent drift when the BE phrasing changes.
Files: backend/lib/jobs/formats/errors.py, frontend/src/app/jobs/(list)/utils/job-output.errors.ts, frontend/src/data/jobs/output.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: job-pause-resume-hard-delete

Type: feature
Coupling: FE+BE coupled
Summary: First-class pause/resume/cancel/hard-delete on jobs and per-item. Adds `Status.paused` (non-terminal, invisible to the claimer), `POST /{job_id}/pause|resume`, `DELETE /{job_id}/hard`, `POST /items/{item_id}/pause|resume`, and a new FE progress cell with paused state, inline resume button, and gray bar fill.
Files: backend/api/jobs.py, backend/api/tasks.py, backend/lib/jobs/lifecycle.py, backend/tests/jobs/test_pause_resume.py, frontend/src/app/jobs/(list)/components/progress-cell.tsx, frontend/src/app/jobs/(list)/components/data-history-row-actions.tsx, frontend/src/data/jobs/actions.ts, frontend/src/data/jobs/job-state.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: admin-force-status

Type: feature
Coupling: FE+BE coupled
Summary: Admins can override an item's terminal state (`canceled` | `failed` | `completed`) with a reason; the latest task flips unconditionally and an `admin_override` record is appended to `item.errors`. Includes an `undo-force-status` endpoint that replays the prior audit event's `before_state`. Surfaced via a dedicated admin UI on the team page.
Files: backend/api/tasks.py, backend/lib/tasks/admin.py, backend/tests/integration/test_admin_override_flow.py, backend/tests/jobs/test_admin_override.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: job-duplicate-stage1

Type: feature
Coupling: BE-only
Summary: `POST /{source_job_id}/duplicate` creates a new Stage-1 job that copies `wizard_state` from the source so the FE can pre-fill the upload wizard. Stage 2 (pipeline + tasks) is deferred.
Files: backend/api/jobs.py, backend/lib/jobs/**init**.py
Commits: 155ab80f (start storing ui wizard state in job metadata)
Issues raised: none

## Theme: jobs-list-aggregates

Type: improvement
Coupling: FE+BE coupled
Summary: Jobs list ships in two modes: lean (existing) and enriched (`include_aggregates=true`) which inlines per-status item counts via a new `jobs/aggregations.py` Mongo pipeline. Drops the legacy `items_count` field, adds `processed_count` semantic fix (terminal state, not success-only), a reconciliation cron, and an `isJobTerminalCheap` helper.
Files: backend/api/jobs.py, backend/lib/jobs/**init**.py, backend/lib/jobs/aggregations.py, backend/scripts/reconcile_run_processed_count.py, frontend/src/data/jobs/job-state.ts, frontend/src/app/jobs/jobs.types.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: job-output-rendering-refactor

Type: improvement
Coupling: BE-only
Summary: Job output / preview / export pipeline restructured into typed modules: `formats/cache.py`, `formats/errors.py`, `formats/metadata.py`, `formats/runner.py`. Adds output caching (`JOB_OUTPUT_CACHE_TTL_SEC`), visibility filtering (internal / admin_only), `include_errors` / `include_metadata` flags, and an `excludeUnmappedFields` export option exposed in FE.
Files: backend/lib/jobs/formats/cache.py, backend/lib/jobs/formats/errors.py, backend/lib/jobs/formats/runner.py, backend/lib/jobs/formats/metadata.py, backend/lib/jobs/formats/functions.py, backend/lib/jobs/formats/types.py, backend/tests/job_outputs/test_runner.py, frontend/src/app/jobs/(list)/components/export-output.tsx
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: jobs-fe-modularization

Type: breaking
Coupling: FE-only
Summary: `src/data/jobs.data.ts` is split into a `src/data/jobs/` submodule (actions, api, display, export, job-state, list-filter, output, row-cells, status). Display helpers moved out of `data-history-v3.utils.ts` (deleted). `useJobActions` consolidates rerun/pause/resume mutations.
Files: frontend/src/data/jobs/actions.ts, frontend/src/data/jobs/api.ts, frontend/src/data/jobs/display.ts, frontend/src/data/jobs/export.ts, frontend/src/data/jobs/job-state.ts, frontend/src/data/jobs/list-filter.ts, frontend/src/data/jobs/output.ts, frontend/src/data/jobs/row-cells.tsx
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 1

## Theme: widgets-v2

Type: feature
Coupling: FE-only
Summary: New `src/core/widgets-v2/` primitive set: orchestrator hook (`useWidget`), `WidgetTable`, `WidgetToolbar`, `SelectionColumn`, `ResetFiltersButton`, plus `use-search-filter` and `use-selection-state` hooks. State syncs to URL via `useQSync`. Powers the new `/admin/jobs` page and is the planned replacement for ad-hoc table wrappers.
Files: frontend/src/core/widgets-v2/index.ts, frontend/src/core/widgets-v2/use-widget.ts, frontend/src/core/widgets-v2/widget-table.tsx, frontend/src/core/widgets-v2/components/widget-toolbar.tsx, frontend/src/core/widgets-v2/components/selection-column.tsx, frontend/src/core/widgets-v2/components/reset-filters-button.tsx, frontend/src/core/widgets-v2/hooks/use-search-filter.ts, frontend/src/core/widgets-v2/hooks/use-selection-state.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: use-query-sync

Type: feature
Coupling: FE-only
Summary: Bidirectional URL ↔ React state sync subsystem (`useQSync`) with framework-free RSC-safe primitives, codecs (string/number/bool/array/json/base64), per-key debounce, dev-time introspection registry exposed at `window.__qSync`, presets (search/tab/filter/pagination/etc.), and a cross-instance pub/sub emitter (`share: true`). 12 new files including full test coverage.
Files: frontend/src/utils/hooks/use-query-sync/index.ts, frontend/src/utils/hooks/use-query-sync/core.ts, frontend/src/utils/hooks/use-query-sync/codecs.ts, frontend/src/utils/hooks/use-query-sync/emitter.ts, frontend/src/utils/hooks/use-query-sync/history.ts, frontend/src/utils/hooks/use-query-sync/presets.ts, frontend/src/utils/hooks/use-query-sync/registry.ts, frontend/src/utils/hooks/use-query-sync/types.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: client-logger

Type: feature
Coupling: FE-only
Summary: Production-grade frontend logger with isomorphic context (AsyncLocalStorage on server, module state on client), PII masking, per-browser-visit `logger_sid` cookie (7d), and 5 sinks: console, file (dev), memory-buffer (dev-on/prod-off, localStorage-persisted), browser→server (POST `/api/log` batch), and server→logger-crab. Auto-instruments `withServer` and `routeWrapper` with request-id binding.
Files: frontend/src/utils/logger/index.ts, frontend/src/utils/logger/context.ts, frontend/src/utils/logger/mask.ts, frontend/src/utils/logger/session-id.ts, frontend/src/utils/logger/sinks/browser-server-sink.ts, frontend/src/utils/logger/sinks/crab-sink-shared.ts, frontend/src/utils/logger/sinks/memory-buffer-sink.ts, frontend/src/core/logger/logger-identity-sync.tsx
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 2

## Theme: backend-logger-consolidation

Type: breaking
Coupling: BE-only
Summary: New `lib/logging/` package as the single configuration point for backend logging. Importing the module runs config (idempotent); all callers go through `PrintLogger(label=...)` or `loguru.logger` directly. Centralizes `LOG_FORMAT` (simple/verbose/minimal/json), removes per-worker overrides of the loguru handler.
Files: backend/lib/logging/**init**.py, backend/run_worker.py, backend/run_workers.py, backend/worker/workerv2.py, backend/tests/logging/test_logging.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: admin-logs-page

Type: feature
Coupling: FE-only
Summary: New `/admin/logs` page with three tabs: Memory (in-page ring buffer, useSyncExternalStore), Crab (fetches from logger-crab dashboard API at 5s interval), Demo (12 buttons to emit synthetic events across all severities + correlated/error-chain/burst). Includes 6 demo server actions for end-to-end logger smoke testing.
Files: frontend/src/app/admin/logs/page.tsx, frontend/src/app/admin/logs/demo-view.tsx, frontend/src/app/admin/logs/crab.actions.ts, frontend/src/app/admin/logs/actions.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: admin-all-jobs-page

Type: feature
Coupling: FE-only
Summary: New `/admin/jobs` page (`src/app/admin/jobs/page.tsx`, 451 lines) showing every job across all teams with search, team / status / job-type / deleted filters, URL-synced pagination, 10s refetch, and preview-output modal on row click. Built on `widgets-v2`.
Files: frontend/src/app/admin/jobs/page.tsx, frontend/src/app/admin/admin.data.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: scraper-success-refund-flow

Type: breaking
Coupling: FE+BE coupled
Summary: Reworks the scraper-success submission flow: refund path moved from client-side fan-out (`processCreditsGroup` charge+refund) to a unified `refundCreditsDb` server action with a `PartToRefund` shape mirroring the chargedParts row. Adds a new "save_stats" step that records a versioned `ScraperSuccessStats` snapshot to job metadata. Adds a credit-cycle picker in S4 (with `(Latest)` / `(Job)` / `(Job + Latest)` tags) and changes excluded-columns from `string[]` to `Map<sheet, Set<col>>` for per-sheet granularity.
Files: frontend/src/app/admin/scraper-requests/scrape-success/steps/s4-finalize-changes.tsx, frontend/src/app/admin/scraper-requests/scrape-success/use-scraper-submit.ts, frontend/src/app/admin/scraper-requests/scrape-success/utils/helpers.ts, frontend/src/app/admin/scraper-requests/scrape-success/utils/types.ts, frontend/src/app/admin/scraper-requests/scrape-success/steps/submit-progress.tsx, frontend/src/app/admin/scraper-requests/scrape-success/steps/submit-summary.tsx, frontend/src/app/admin/scraper-requests/scrape-success/use-scraper-parts.ts
Commits: 9f00492c (scrape success + preview modal improvements)
Issues raised: 1

## Theme: image-gen-color-remap

Type: feature
Coupling: BE-only
Summary: Color-remap pipeline migrates from a single-shot call to a retry loop with structural validation (edge-IoU 70% + edge-weighted SSIM 30%). New 4-strategy entry point (target image / swatch file / color text / hex direct), per-attempt S3 upload, "is_best" selection, and a Flash-vs-Pro model selector. Public response shape now carries `attempts[]` + `similarity_score`. Migrates Gemini client init to Vertex AI (`VERTEX_API_KEY`).
Files: backend/lib/providers/nanobanana/color_remap.py, backend/lib/providers/nanobanana/structural_validation.py, backend/lib/providers/nanobanana/gemini.py, backend/lib/providers/gemini/**init**.py, backend/api/image_enhancement.py, backend/static/demos/image-enhancement/index.html, backend/static/demos/edge-compare/index.html
Commits: 2992cf3d (color_remap.py swatch changes), 41a7dd6f (add model name to image gen payload), 7c9326fb (image gen debug 404 handle), 86705286/1b0e27f6 (UI admin preview), b36127c9 (image gen prompt update)
Issues raised: 1

## Theme: integration-test-framework

Type: infra
Coupling: BE-only
Summary: Full integration-test harness: scenario YAML runner (`scenario_runner.py`, 838 lines), job-run timeline recorder (Mongo polling + Redis snapshots, with change-stream fallback + SQLite sink), HTML swimlane flow viewer (`flow.html` + 1772-line `flow-app.js`), multi-run aggregator, and 9 scenario YAMLs (HP1, HP2, B4, B7, B8, B9, B10, B11). Gated by `INTEGRATION_CHAOS_ENABLED` and `INTEGRATION_HTTP_CAPTURE_PATH`.
Files: backend/scripts/integration/scenario_runner.py, backend/scripts/integration/run_all.py, backend/scripts/integration/recorder/flow_builder.py, backend/scripts/integration/recorder/mongo_poller.py, backend/scripts/integration/recorder/redis_snapshotter.py, backend/scripts/integration/recorder/sqlite_sink.py, backend/scripts/integration/scenarios/B4-chaos-pause.yaml, backend/scripts/integration/scenarios/B7-breaker-fsm-roulette.yaml
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 2

## Theme: mock-pipeline

Type: infra
Coupling: BE-only
Summary: New `MockPipelineMethod` with three tiers of knobs for controllable-failure testing: latency, retryable/terminal errors, structured error payload (Tier 1); `resilient_wrap`, `retry_hiccup_after` (Tier 2); adversarial probes like `hog_resource_ms` (Tier 3). Used by the chaos scenarios.
Files: backend/lib/pipeline/methods/mock.py, backend/tests/pipeline/test_mock_tier2.py, backend/tests/pipeline/test_mock_tier3.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: chaos-injection

Type: infra
Coupling: BE-only
Summary: Test-only chaos module that monkey-patches `AsyncTaskClaimer._transition` to drop writes based on a Redis-gated injection key (counted or infinite mode, auto-clearing). Hard import gate raises `ImportError` unless `Config.INTEGRATION_CHAOS_ENABLED=True`.
Files: backend/lib/integration/chaos.py, backend/lib/integration/**init**.py, backend/tests/integration/test_integration_chaos.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 1

## Theme: http-capture-middleware

Type: infra
Coupling: BE-only
Summary: Env-gated ASGI middleware that appends one JSONL row per request (`{ts, method, path, query, status, duration_ms, content_length}`) when `INTEGRATION_HTTP_CAPTURE_PATH` is set. Failures are swallowed (observability, not load-bearing). Powers the integration recorder.
Files: backend/api/http_capture.py, backend/api/util.py, backend/tests/api/test_http_capture.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: slack-webhooks-architecture

Type: breaking
Coupling: BE-only
Summary: Slack webhook stack split into 4 modules: `_transport.py` (HTTP, sync+async, 4xx/5xx/429 classification), `blocks.py` (Block Kit primitives), `templates.py` (per-topic Block Kit templates), `channels.py` (topic→webhook routing with cascade fallback). Callers name a `SlackTopic` instead of choosing a URL. New webhooks for `INCIDENTS`, `DEFERS`, `DAILY`, `PREFLIGHT`, `REAPER`.
Files: backend/lib/webhooks/\_transport.py, backend/lib/webhooks/blocks.py, backend/lib/webhooks/templates.py, backend/lib/webhooks/channels.py, backend/lib/webhooks/slack.py, backend/tests/webhooks/test_slack_failure.py, frontend/src/utils/slack/slack-blocks-templates.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 1

## Theme: preflight-checklist

Type: infra
Coupling: BE-only
Summary: New prod-boot preflight checklist (`lib/config/preflight.py`, 530 lines) that runs read-only checks against Mongo / Redis / Postgres / S3 / httpx / breaker consensus / Sentry, classifies each as PASS/WARN/ERROR, and posts a single Slack report per role per deploy (Redis dedup-lock on commit SHA). Gated by `PREFLIGHT_ENABLED`.
Files: backend/lib/config/preflight.py, backend/lib/config/**init**.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 1

## Theme: sentry-centralization

Type: improvement
Coupling: BE-only
Summary: Sentry init consolidated into `lib/sentry/__init__.py` — single entry point, env (local/development/production) and release tag come from `Config`, fixes prior misclassification (dev service with `DEBUG=False` reported as production). Applies to API server, worker, and pipeline runner.
Files: backend/lib/sentry/**init**.py, backend/run_worker.py, backend/run_workers.py, backend/pipeline_runner.py, backend/lib/config/app_init.py, frontend/sentry.server.config.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: cycles-cron-monitoring

Type: feature
Coupling: FE-only
Summary: New Vercel cron route (`/api/cron/expiring-cycles`, daily 14:00 UTC) that scans team credit allocations within 3-day and 12-day horizons, classifies urgency into 5 tiers (alarm/critical/warning/watch/ok), and posts a Block Kit report to Slack with admin contacts per team. Includes a full Vitest suite for pure helpers.
Files: frontend/src/app/api/cron/expiring-cycles/route.ts, frontend/src/app/api/cron/expiring-cycles/team-health.utils.ts, frontend/src/app/api/cron/expiring-cycles/team-health.utils.test.ts, frontend/src/app/api/cron/cron.utils.ts, frontend/vercel.json
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 1

## Theme: pg-team-credit-allocation-gate

Type: feature
Coupling: BE-only
Summary: Backend now validates an active credit cycle exists in Postgres (`team_credit_allocation`) on `create_job` and on every worker task pickup. New `get_active_cycle_for_team(team_id)` helper queries by `datetime.date` (asyncpg constraint, not isoformat). Mirrors the cycle bucket fast-path; the PG read is the source of truth.
Files: backend/api/auth_db.py, backend/api/jobs.py, backend/lib/jobs/**init**.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 1

## Theme: internal-api-auth-refactor

Type: breaking
Coupling: BE-only
Summary: Internal API routes migrate from cookie+password auth (`_DASHBOARD_PASSWORD`, `_DASHBOARD_COOKIE_NAME`) to an HMAC-compared `x-api-token` header (`ADMIN_API_TOKEN`). `require_dashboard_auth` is gone; all internal routes now use the new `InternalApiDependency`.
Files: backend/api/auth.py, backend/api/internal/**init**.py, backend/api/internal/dashboard.py, backend/api/internal/helpers.py, backend/api/internal/scraper.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 1

## Theme: e2e-test-routes

Type: infra
Coupling: FE+BE coupled
Summary: Test-only routes guarded by `E2E_TEST_SECRET` header + blocked on `app.versable.ai` host. BE `_e2e_test.py` exposes `latestJob`, `jobOutput`, `cleanupOrphanJobs` ops. FE `/api/e2e-test/route.ts` mirrors with `credits`, `cleanupOrphans`, `creditLedger` ops. Powers the new Playwright suite v2.
Files: backend/api/\_e2e_test.py, backend/api/api.py, frontend/src/app/api/e2e-test/route.ts, frontend/test/utils/db-client.ts, frontend/test/utils/cleanup.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 1

## Theme: e2e-playwright-suite-v2

Type: infra
Coupling: FE-only
Summary: Playwright suite restructured into per-step `lib/*` modules (login, account, jobs-list, upload, S2 stages, credits, data-history, general). Adds nav-snapback detection (5s/3s heuristic), per-test console-buffer capture, credit-delta assertions, a 4-tier module-recovery guard, and a run summary report. New `E2E_SUITE_VERSION` constant in `test/test.utils.ts`.
Files: frontend/test/basic.spec.ts, frontend/test/lib/login.ts, frontend/test/lib/jobs-list.ts, frontend/test/lib/upload.ts, frontend/test/lib/dashboard-credits.ts, frontend/test/utils/nav-tracker.ts, frontend/test/utils/test-fixture.ts, frontend/test/test.utils.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: gh-pages-portal-and-docs

Type: infra
Coupling: infra-only
Summary: New gh-pages portal (`/` → `/e2e/`, `/docs/`, `/docs-raw/`) with a full E2E test reports dashboard (dark/light toggle, pass-rate bar, trend dots over last 14 runs) and a Docsify SPA shell for product docs. Includes Python scripts for sidebar + metadata + raw index generation, run by `docs-deploy.yaml`.
Files: .github/scripts/dashboard-header.html, .github/scripts/dashboard-footer.html, .github/scripts/portal-index.html, .github/scripts/docsify-index.html, .github/scripts/generate-sidebar.py, .github/scripts/generate-metadata.py, .github/scripts/generate-docs-raw-index.py, .github/workflows/docs-deploy.yaml
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 1

## Theme: ci-pr-automation

Type: infra
Coupling: infra-only
Summary: PR automation suite: `auto-pr-body.yml` (auto-fill PR body with typed sections, labels, nudge), `claude-code-review.yml`, `commit-nudge.yml`, `label-pr.yml`, `notion-sync.yaml`, plus tightened `frontend-pr-check.yml`. Concurrency group `gh-pages-deploy` shared between docs and e2e workflows (sequential, no cancel-in-progress).
Files: .github/workflows/auto-pr-body.yml, .github/workflows/claude-code-review.yml, .github/workflows/commit-nudge.yml, .github/workflows/label-pr.yml, .github/workflows/notion-sync.yaml, .github/workflows/frontend-pr-check.yml
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: e2e-workflow-hardening

Type: improvement
Coupling: infra-only
Summary: `frontend-e2e-test.yaml` bumps Node 20→22, splits Playwright `install` from `install-deps` (OS deps not cached), changes default `BASE_URL` from v3→v4 (current staging), adds `SLACK_NOTIFY` mode (`all`/`failures`/`off`), keeps only 20 most recent reports, adds `.nojekyll`, and triggers on `e2e-test-v2/*` branches + a 12-hour schedule.
Files: .github/workflows/frontend-e2e-test.yaml, frontend/scripts/prune-artifacts.sh, prune-artifacts.sh
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: tanstack-query-persist-removal

Type: breaking
Coupling: FE-only
Summary: `PersistQueryClientProvider` is gone. `src/core/query/query-client-provider.tsx` is deleted (41 lines), `@tanstack/query-async-storage-persister` and `@tanstack/react-query-persist-client` removed from `package.json`. `react-query.ts` strips `_queryPersister`, `refetchOnWindowFocus`, and `refetchOnReconnect`. App now uses plain `QueryClientProvider`; gcTime still retains.
Files: frontend/src/core/query/query-client-provider.tsx (deleted), frontend/src/utils/react-query.ts, frontend/package.json, frontend/package-lock.json
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 1

## Theme: deploy-info-cleanup

Type: breaking
Coupling: FE-only
Summary: `await getAppDeploymentUrl()` (8+ async callsites) is replaced with the static `DeployInfo.AppUrl` constant. Eliminates async at module-init paths; `config.utils.ts` reads `VERCEL_PROJECT_PRODUCTION_URL` first for Vercel deployments. `BasePageTitle` adds an env label for staging/dev tabs.
Files: frontend/src/utils/env/env.utils.ts, frontend/src/app/api/config/config.utils.ts, frontend/src/app/admin/info/[token]/page.tsx, frontend/src/app/help/[slug]/page.tsx, frontend/src/app/password/forgot/send/[email]/route.ts, frontend/src/app/lab/ebay-poster/image/route.tsx, frontend/src/app/layout.tsx, frontend/src/data/token.data.ts
Commits: 2b58f41b, ca8c4235 (getAppDeploymentUrl → DeployInfo.AppUrl)
Issues raised: none

## Theme: session-refresh-disabled

Type: fix
Coupling: FE-only
Summary: `SessionRefreshObserver` is gutted to a no-op stub. `router.refresh()` on auth transitions was racing in-flight soft navigations and causing "snap-back" — see `docs/known-issues/nav-snapback-race.md`. Auth session signOut now also drops the `logger_sid` cookie and no longer calls `revalidateTag("token")` (avoided 401 bursts per ADR-007).
Files: frontend/src/core/auth/session-refresh-observer.tsx, frontend/src/app/api/auth/[...nextauth]/auth-options.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 2

## Theme: modal-url-sync

Type: improvement
Coupling: FE-only
Summary: Modals can now sync to URL via `useModal({ urlSync })`. Adds `ModalUrlKeys` registry, lifts modal state out of per-row components to the table level (prevents stacked duplicates), and replaces `PreviewId` setParam with a URL-synced atom. Powers the new preview-job-output modal flow.
Files: frontend/src/core/modal/modal.tsx, frontend/src/core/modal/modal.utils.ts, frontend/src/core/modal/modal.data.ts, frontend/src/app/jobs/(list)/data-history-v3/data-history-v3.table.tsx, frontend/src/app/jobs/(list)/components/data-history.modals.tsx, frontend/src/app/jobs/(list)/modals/preview-job-output.params.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: filter-tabs-v2-refactor

Type: breaking
Coupling: FE-only
Summary: `FilterTabsV2` switches from internal state (`cacheKey`, `setTabFilter`, `_tabState`) to external URL-driven state via `useQSync`. Adds `shallow`, `listenPopState`, and other parameters. Props signature is completely changed — every caller migrated.
Files: frontend/src/core/tabs/filter-tabs-v2.tsx
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 1

## Theme: dev-tools-inspector

Type: feature
Coupling: FE-only
Summary: New dev-only `AppDevInspector` portal (bottom-right, dev-gated). Module-based: `qsync-module` (live URL/dict/value rows from `qSyncRegistry`) and `settings-module` (flag status grid + memory-buffer toggle). Plugs into `app-devtools.tsx`.
Files: frontend/src/core/dev-tools/app-dev-inspector.tsx, frontend/src/core/dev-tools/modules/index.ts, frontend/src/core/dev-tools/modules/qsync-module.tsx, frontend/src/core/dev-tools/modules/settings-module.tsx, frontend/src/core/dev-tools/modules/types.ts, frontend/src/core/layout/app-wrapper/app-devtools.tsx
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: tooltip-system-rewrite

Type: breaking
Coupling: FE-only
Summary: `ShowTooltip` component is being phased out in favor of data-driven `data-tooltip-*` attributes resolved by `getAppTooltip`. Callers no longer wrap children; instead they spread tooltip props on the element. Includes new `tooltip.utils.ts` + tests.
Files: frontend/src/core/tooltip/tooltip.tsx, frontend/src/core/tooltip/tooltip.utils.ts, frontend/src/core/tooltip/tooltip.utils.test.ts, frontend/src/core/select-template/select-template.enhancement.tsx
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: error-boundaries-and-default-error-page

Type: feature
Coupling: FE-only
Summary: Adds Next.js segment error boundaries to `/`, `/account`, `/admin`, `/files`, `/jobs` via a new shared `DefaultErrorPage` component. `error-boundary.tsx` extended with `AppErrorFallbackProps` for react-error-boundary ↔ Next.js segment-error compatibility.
Files: frontend/src/core/page/default-error.tsx, frontend/src/app/admin/error.tsx, frontend/src/app/account/error.tsx, frontend/src/app/files/error.tsx, frontend/src/app/jobs/error.tsx, frontend/src/utils/error-boundary.tsx
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: fiber-snatcher-runtime

Type: infra
Coupling: FE-only
Summary: New dev-only `fiber-snatcher-runtime.ts` exposes React fiber state to the external `fiber-snatcher` CLI tool for deterministic state reads and dispatch in dev. Companion `.fiber-snatcher/config.json` declares the auth bypass pattern.
Files: frontend/src/dev/fiber-snatcher-runtime.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: image-gen-key-resolution

Type: improvement
Coupling: FE+BE coupled
Summary: Image-gen output column key resolution now follows a typed priority chain (`options.image_gen_key` → `generated_columns` registry by role → `pipeline_history` legacy fallback → `DEFAULT_IMAGE_GEN_KEY_NAME`). `getJobSpecificOptions` on FE reads `metadata.generated_columns` first (v2.1+) with pipeline_history fallback for older jobs. Backend has a 318-line test for the priority chain + dedup for color_remap.
Files: backend/tests/job_outputs/test_keys.py, frontend/src/utils/hooks/use-job-data.ts, backend/lib/jobs/formats/functions.py
Commits: 43d027d4 (save custom job output settings for image_gen_key), 1ecc0da5 (research mode high/low for preview)
Issues raised: none

## Theme: scraper-target-fixture

Type: infra
Coupling: infra-only
Summary: Self-hosted E2E fixture page at `public/e2e-fixtures/scraper-target.html` with documented expected extraction values, SVG data-URI product images, specs table, and `data-*` attributes for field mapping. Lets the scraper test run without depending on any third-party site.
Files: frontend/public/e2e-fixtures/scraper-target.html
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: badge-system-css

Type: improvement
Coupling: FE-only
Summary: New `.badge-text` base class + 8 color variants (primary/secondary/accent/neutral/info/success/warning/error) with `.badge-shade` modifier for background fill. Also adds numeric `--secondary-dark-num: 137 176 205` CSS var so opacity modifiers work via `rgb()`.
Files: frontend/src/app/globals.css
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: scraper-requests-dashboard

Type: feature
Coupling: BE-only
Summary: New `GET /internal/scraper/requests/enriched` endpoint that filters scraper requests by team/job/status/deleted, derives status from `custom_job_values.status` → `scraper_config.last_status` → `pending|missing` cascade (mirrors FE), and enriches each row with owner details (user/team) via a single Postgres round-trip.
Files: backend/api/internal/scraper.py, backend/api/internal/helpers.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: vertex-ai-migration

Type: breaking
Coupling: BE-only
Summary: Gemini providers (`lib/providers/gemini`, `lib/providers/nanobanana/gemini.py`, `lib/providers/nanobanana/upscaler.py`, `lib/providers/nanobanana/color_remap.py`) switch from `GEMINI_API_KEY` to `VERTEX_API_KEY` with `vertexai=True`. Any env-group missing `VERTEX_API_KEY` will boot-fail.
Files: backend/lib/providers/gemini/**init**.py, backend/lib/providers/nanobanana/**init**.py, backend/lib/providers/nanobanana/gemini.py, backend/lib/providers/nanobanana/upscaler.py, backend/lib/providers/nanobanana/color_remap.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 1

## Theme: config-knob-explosion

Type: infra
Coupling: BE-only
Summary: `Config` gains 52+ new env vars across logging, observability, worker lifecycle, circuit breaker, retry budget, drain timeout, reaper grace, job-output cache, preflight, integration test toggles, and admin API token. `ENV` default changes from `"development"` → `"local"`. New required vars need Render env-group updates before deploy.
Files: backend/lib/config/**init**.py, backend/lib/config/helpers.py, backend/lib/config/app_init.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 2

## Theme: mongo-indexes

Type: perf
Coupling: BE-only
Summary: 6 new Mongo indexes created on boot: `tasks.(item_id, added_at desc)` (preview aggregate), `tasks.(next_eligible_at)` sparse (deferred-cooldown filter), `tasks.(job_id, added_at desc)` (getJobAggregates), `redis_history._expires_at` TTL, `active_workers.terminated_at` TTL 24h, and 5 indexes on `audit_events` (kind+ts, target, actor, team+kind, correlation_id, plus 90-day TTL).
Files: backend/lib/config/app_init.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: pipeline-steps-collection-drop

Type: breaking
Coupling: BE-only
Summary: The `pipeline_steps` Mongo collection is removed from the codebase entirely (writes + reads + type definition). Migration to drop the actual collection in prod is tracked as a separate OPS task (#85).
Files: backend/lib/database/**init**.py, backend/api/\_inspect.py, backend/lib/pipeline/processor/**init**.py
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: 1

## Theme: enhancement-agent-v2-product-type

Type: improvement
Coupling: BE-only
Summary: `EnhancementAgentV2` Input gains an optional `product_type` field that conditionally swaps the system-prompt header between "universal" and product-specific. New sample test pipeline `007_ENHANCEMENT_AGENT_V2_Custom.json` with HVAC Parts.
Files: backend/lib/agents/EnhancementAgentV2.py, backend/pipeline-files/tests/007_ENHANCEMENT_AGENT_V2_Custom.json
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: credit-worker-shutdown-safety

Type: fix
Coupling: FE-only
Summary: Standalone `credit-worker/run.ts` hardens shutdown: explicit `shuttingDown` flag, SIGINT+SIGTERM handlers that gracefully close Redis + PG pool, main loop changes to `while (!shuttingDown)`, exit guard in BRPOP catch. Removes the bespoke logger wrapper in favor of `console.*`. Standalone `_package.json` deleted (consolidated into root).
Files: frontend/credit-worker/run.ts, frontend/credit-worker/banner.svg, frontend/credit-worker/\_package.json (deleted)
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: structured-cause-fe-render

Type: improvement
Coupling: FE-only
Summary: FE migrates from regex-matching error message strings to switching on a stable `cause_code` and interpolating `cause_context`. Eliminates a documented anti-pattern flagged in `~/.claude/rules/error-classification.md`. Adds `failActionMessage` helper to wrap `getApiError` with a standard "Unable to ${action}" template.
Files: frontend/src/app/jobs/(list)/utils/job-output.errors.ts, frontend/src/utils/error.ts, frontend/src/data/jobs/output.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: lookup-route-and-helper-cleanup

Type: improvement
Coupling: FE-only
Summary: New `AdminRoutes.Jobs` + `AdminRoutes.AdminLogs` route constants, `AuthRoutes.GetPasswordReset(token)` helper, `app-links.utils.ts` expanded with job/scraper link generators. `icons.ts` consolidates `react-icons` imports under `IconFor` enum.
Files: frontend/src/utils/routing.ts, frontend/src/utils/core/app-links.data.ts, frontend/src/utils/core/app-links.utils.ts, frontend/src/utils/icons.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Themes added by V2 Verifier (FM-1)

## Theme: dev-console-filter

Type: improvement
Coupling: FE-only
Summary: New dev-only `console.error` allowlist suppressor + 89-line test suite. Filters known-noisy console messages in development so real errors are visible. Self-contained and observable in dev UX.
Files: frontend/src/utils/dev-console-filter.ts, frontend/src/utils/dev-console-filter.test.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: fe-worker-redis-cache

Type: feature
Coupling: FE-only
Summary: New `"use server"` Redis-namespace caching primitive declaring a global `_workerNamespaceRedis: Redis` singleton, integrates with `DeployInfo`. Non-trivial helper, likely consumed alongside `cycle-bucket-quota-gate` / `pg-team-credit-allocation-gate` consumer-side.
Files: frontend/src/utils/redis/worker-cache.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: be-unauthorized-server-handler

Type: feature
Coupling: FE-only
Summary: New server-action utility for graceful 401 handling from Python-BE (distinct from the client axios interceptor) plus a 149-line test suite. Related to `session-refresh-disabled` and the `route-wrapper.server.utils.ts` logger refactor, but is a distinct concern (BE-401 → cookie clear + redirect server-side).
Files: frontend/src/utils/permission/handle-backend-unauthorized.server.ts, frontend/src/utils/permission/handle-backend-unauthorized.server.test.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: upload-wizard-v2-polish

Type: improvement
Coupling: FE-only
Summary: S1 upload page got a major refactor (155 added lines) and the s2\* family received non-trivial updates (`s2ig-apply-image-gen.tsx` +93 -14, etc.). FE upload-wizard surface changes for v2 — distinct from the BE `image-gen-color-remap` work.
Files: frontend/src/app/jobs/v2/pages/s1-upload.tsx, frontend/src/app/jobs/v2/pages/s2ig-apply-image-gen.tsx
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none

## Theme: slack-fe-channel-data

Type: feature
Coupling: FE-only
Summary: New `SlackChannelWebhooks` data module (UserSupport / ScrapeRequest / CustomerReports / DevLogs env-var map) on the FE side, and shrinking of `slack.ts` from hardcoded actions to a 3-line stub. Companion to the BE `slack-webhooks-architecture` work.
Files: frontend/src/utils/slack/slack.data.ts, frontend/src/utils/slack/slack.ts, frontend/src/utils/slack/slack.server.ts, frontend/src/utils/slack/slack.type.ts
Commits: (post-cutoff branch tip — see git log for exact SHAs)
Issues raised: none
