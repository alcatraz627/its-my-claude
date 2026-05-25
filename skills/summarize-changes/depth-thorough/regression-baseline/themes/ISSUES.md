# v5.0 Release Issues — Final

## DEFINITELY (confirmed bugs/regressions)

- **[ISS-002]** `files.py:debug_imagegen_keys` ships with a `print()` call

  - theme: image-gen-color-remap
  - file: `backend/api/files.py`
  - evidence: V1 chunk 18 "Adds debug print: print('status code', result.status_code)". Confirmed in `diffs/18-be-api-rest.diff:476`.
  - Suggested action: **fix** — replace with `logger.debug(...)` before merge.

- **[ISS-003]** Internal API auth refactor is a hard break with no compatibility layer

  - theme: internal-api-auth-refactor
  - file: `backend/api/internal/__init__.py`
  - evidence: cookie+password auth (`_DASHBOARD_PASSWORD`, `_DASHBOARD_COOKIE_NAME`, `require_dashboard_auth`) removed wholesale and replaced with `InternalApiDependency` (HMAC token). Any external consumer / bookmark / Postman config depending on cookie auth returns 403 immediately on deploy.
  - Suggested action: **verify** `ADMIN_API_TOKEN` provisioned in prod env-group BEFORE deploy; communicate the URL/header change to anyone with bookmarked internal admin URLs.

- **[ISS-013]** Preflight Redis-dedup-lock uses `RENDER_GIT_COMMIT` as the dedup key
  - theme: preflight-checklist
  - file: `backend/lib/config/preflight.py`
  - evidence: same-SHA redeploy after env-var fix skips the preflight report. Confirmed operational gap (not a smell) per V1 + VERIFIER FM-4. On a Render redeploy of the SAME commit (rollback, manual restart, env-var fix), no preflight report fires — operators may miss an actually-failing preflight on a no-code-change boot.
  - Suggested action: **fix** — switch the dedup key to `commit_sha + deploy_timestamp_bucket` (e.g. 15-min bucket) so same-SHA redeploys re-emit the report. Acceptable interim: **monitor** and manually invoke preflight after any same-SHA redeploy.

## MAYBE (smells needing verification)

- **[ISS-005]** `chaos.py` monkey-patches `AsyncTaskClaimer._transition` on import

  - theme: chaos-injection
  - file: `backend/lib/integration/chaos.py`
  - why-suspicious: Hard import gate raises `ImportError` unless `Config.INTEGRATION_CHAOS_ENABLED=True`. If the env var ever ships as truthy in a prod env-group by accident (typo, copy-paste from dev), prod workers silently drop Mongo writes via Redis-gated injection.
  - Suggested action: **verify** no prod env-group has `INTEGRATION_CHAOS_ENABLED=true`. Long-term: add a runtime guard that ALSO refuses to enable if `ENV=production`.

- **[ISS-006]** Vertex AI migration assumes `VERTEX_API_KEY` provisioned in every image-gen env-group

  - theme: vertex-ai-migration
  - file: `backend/lib/providers/gemini/__init__.py`
  - why-suspicious: 4 client init sites switched from `GEMINI_API_KEY` → `VERTEX_API_KEY` simultaneously. Missing env-var = boot/runtime fail. No compat fallback.
  - Suggested action: **verify** `VERTEX_API_KEY` present in dev + staging + prod env-groups before deploy.

- **[ISS-007]** Crab logger config drift between FE and BE

  - theme: client-logger / backend-logger-consolidation
  - file: `frontend/src/utils/logger/env.ts`
  - why-suspicious: V1 chunk 13 "no NEXT*PUBLIC_LOGGER_CRAB*_ antipattern"; crab credentials server-only. But BE chunk 15 has `LOGGER*CRAB*_`Config knobs marked pending (task #75 still open). If`LOGGER_CRAB_TOKEN/URL/ENABLED` aren't yet wired on Render, server-side crab sink reports as configured-incomplete (silent observability gap).
  - Suggested action: **verify** task #75 closure status before relying on crab sink for prod observability; **monitor** logger-crab dashboard for first 24h post-deploy to confirm BE events flowing.

- **[ISS-009]** Job-output cache key includes team but no schema version

  - theme: job-output-rendering-refactor
  - file: `backend/lib/jobs/formats/cache.py`
  - why-suspicious: V1 says "key prefix: `job_output:{job_id}:{team}:{hash}`". Output format/visibility rules change in this very PR (visibility=admin_only, include_errors, include_metadata flags). Users may see stale cached previews until TTL expires.
  - Suggested action: **fix** — set `JOB_OUTPUT_CACHE_DISABLED=true` for first prod boot, OR add a schema-version segment to the cache key. Re-enable cache after one stable boot cycle.

- **[ISS-010]** `FilterTabsV2` props are a complete signature break

  - theme: filter-tabs-v2-refactor
  - file: `frontend/src/core/tabs/filter-tabs-v2.tsx`
  - why-suspicious: V1 explicitly: "Props signature completely changed; migration required." Verifier FM-4 spot-checked grep — real tab-related matches use the new pattern; unrelated `cacheKey` strings (Redis cache key naming) are false-positives.
  - Suggested action: **monitor** — re-run `rg "cacheKey|setTabFilter|_tabState" frontend/src/core/tabs frontend/src/app` post-merge to confirm zero remaining callers of the old prop signature. Otherwise: ignore.

- **[ISS-011]** TanStack Query persist removal — gcTime is the only retention layer now

  - theme: tanstack-query-persist-removal
  - file: `frontend/src/utils/react-query.ts`
  - why-suspicious: Removing `refetchOnWindowFocus` AND `refetchOnReconnect` defaults simultaneously with the localStorage persister means a user returning to a tab will neither auto-refetch nor have a cached copy. CLAUDE.md note #5 already warns "TanStack Query is NOT persisted… Still invalidate explicitly after mutations".
  - Suggested action: **verify** with a focused QA pass on jobs dashboard — open in two tabs, mutate in one, switch back to the other; confirm acceptable refresh behavior.

- **[ISS-012]** `expiring-cycles` cron has no auth gate beyond `guardCronRequest`

  - theme: cycles-cron-monitoring
  - file: `frontend/src/app/api/cron/expiring-cycles/route.ts`
  - why-suspicious: V1 "`guardCronRequest(req)` checks Bearer token (prod) or query param (dev)." If `CRON_SECRET` isn't set on Vercel (workflow lists it as `requiredEnvVars`), the cron 401s silently every day at 14:00 UTC.
  - Suggested action: **verify** `CRON_SECRET` set on Vercel prod env before relying on this cron for Slack alerts; **monitor** first scheduled run (14:00 UTC after deploy).

- **[ISS-019]** gh-pages concurrency group needs verification post-deploy

  - theme: gh-pages-portal-and-docs
  - file: `.github/workflows/docs-deploy.yaml` + `.github/workflows/frontend-e2e-test.yaml`
  - why-suspicious: Both workflows share `gh-pages-deploy` with `cancel-in-progress: false`. Observable in `.github/workflows/*` files — a 1-file read confirms it. If a long-running e2e schedule pins the queue, docs deploys back up.
  - Suggested action: **monitor** queue depth after first scheduled e2e run; if docs deploys stall, split groups (e.g., `gh-pages-docs` vs `gh-pages-e2e` with explicit rendezvous).

- **[ISS-020] / TO-CHECK overlap — see TO-CHECK below.**

## TO-CHECK (ops/human verification required)

- **[ISS-008]** Job duplicate copies `wizard_state` but Stage 2 (pipeline + tasks) is deferred

  - theme: job-duplicate-stage1
  - file: `backend/api/jobs.py`
  - re-categorized from MAYBE per VERIFIER FM-4 — deliberately-deferred Stage 2 (task #78 pending). The UI labeling concern is the only real risk: admin button looks like a full clone.
  - Owner: **frontend**
  - Suggested action: label review at the admin call site so admins aren't confused by a job that duplicates without pipeline.

- **[ISS-014]** Provision 52+ new env vars before deploy

  - theme: config-knob-explosion
  - what-to-check: Critical for boot: `ADMIN_API_TOKEN`, `VERTEX_API_KEY`, `WORKER_BREAKER_*`, `WORKER_RETRY_BUDGET_PER_MIN`, `WORKER_DRAIN_TIMEOUT_SEC`, `SLACK_*_WEBHOOK_URL` cascade (INCIDENTS/DEFERS/DAILY/PREFLIGHT/REAPER). Task #63 (Audit env keys on Render dev + prod env-groups) still pending.
  - Owner: **ops**
  - Suggested action: block deploy on task #63 completion.

- **[ISS-015]** Drop `pipeline_steps` Mongo collection post-deploy

  - theme: pipeline-steps-collection-drop
  - what-to-check: Task #85 pending. Code no longer writes/reads `pipeline_steps`, but the collection lingers in prod Mongo.
  - Owner: **ops**
  - Suggested action: drop after deploy stabilizes (1-2 weeks grace).

- **[ISS-016]** `team_credit_allocation` PG schema must exist in prod

  - theme: pg-team-credit-allocation-gate
  - what-to-check: Worker queries `team_credit_allocation` on every task pickup via `get_active_cycle_for_team`. Confirm table exists, populated for all active teams, indexed on `(team_id, cycle_start, cycle_end, deleted_at)`. asyncpg requires `datetime.date` (not isoformat string) — confirm `cycle_start`/`cycle_end` are `DATE` columns.
  - Owner: **backend** (with **ops** verification on prod schema)

- **[ISS-017]** Slack webhook URLs must be configured before topic-routed alerts fire

  - theme: slack-webhooks-architecture
  - what-to-check: `SLACK_CIRCUIT_BREAKER_WEBHOOK_URL`, `SLACK_DAILY_REPORT_WEBHOOK_URL`, `SLACK_DEFER_ALERT_WEBHOOK_URL`, `PREFLIGHT_REPORT_WEBHOOK_URL`. Cascade falls back to `SLACK_WEBHOOK_URL` per `channels.py`, but dedicated channels are the design intent.
  - Owner: **ops**
  - Suggested action: verify all 4 webhook URLs in prod env-group.

- **[ISS-018]** E2E test secret must be set + host-blocked on prod

  - theme: e2e-test-routes
  - what-to-check: `E2E_TEST_SECRET` env var. Routes return 418 if host matches `app.versable.ai` — confirm guard is bulletproof for custom-domain CNAMEs, www. variants before route ships.
  - Owner: **backend**

- **[ISS-020]** Job-output cache TTL — pick a value before enabling
  - theme: job-output-rendering-refactor
  - what-to-check: `JOB_OUTPUT_CACHE_TTL_SEC` new and unset = uncached. With visibility / include_metadata / include_errors flags now in play, set TTL conservatively (e.g. 60s) for first prod boot, tune up. Also confirm `JOB_LIFECYCLE_CACHE_TTL_SEC` (per-process "is this job deleted?" TTL) is reasonable.
  - Owner: **backend** (with **ops** for env-group set)

## CLOSED

- **[ISS-001]** `SessionRefreshObserver` is shipped as no-op stub

  - theme: session-refresh-disabled
  - file: `frontend/src/core/auth/session-refresh-observer.tsx`
  - resolution: Code-check confirmed — `rg` for `SessionRefreshObserver` import sites in `frontend/src` returned only the definition file. No external callers. Component being a no-op stub is safe; layout call site already removed. Closed.

- **[ISS-004]** `data-history-v3.utils.ts` modified vs deleted (stale git status)
  - resolution: File is deleted in working tree; the prior git status snapshot was stale. Confirmed via `ls` — no such file. Migrated to `src/data/jobs/` submodule per jobs-fe-modularization theme. Closed.
