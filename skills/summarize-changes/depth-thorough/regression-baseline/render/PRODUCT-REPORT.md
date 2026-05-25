# v5.0 Release — Product Summary

> Released: pending. Theme of release: worker reliability, end-to-end observability, and jobs UI polish — the platform now self-recovers from transient downstream failures, surfaces what's happening to users, and gives admins direct control over stuck items.

## What customers will notice

- **Faster, more reliable job processing.** When an upstream provider hiccups, jobs no longer cascade into a retry storm — they pause briefly, recover automatically, and resume. Users will occasionally see a small "deferred" badge on an item; that's the system pacing itself, and it self-resolves once the downstream recovers.
- **Pause and resume on jobs.** Users can now pause a job (or an individual item) and resume it later from the same row, instead of having to cancel and restart. A new progress bar shows paused state with an inline resume button.
- **Clearer error messages.** Job-output errors are now generated from a stable error code (not parsed from prose), so the same problem always shows the same message — and messages can be more specific to the actual cause.
- **First page load after a long idle is slightly slower.** TanStack Query's localStorage cache was removed because it was causing stale data on returning visits. The jobs list now refetches from the network on first paint after a long tab idle — expect a 1-2s loading state. After that initial load, behavior is unchanged.
- **File preview & export tightened.** Job-output preview supports `include_errors` and `include_metadata` toggles, and a new `excludeUnmappedFields` export option.

## What admins / internal users will notice

- **`/admin/jobs` page.** A single cross-team admin view of every job in the system, with team / status / job-type / deleted filters, URL-synced state, 10s auto-refresh, and click-to-preview on any row.
- **Force-status overrides.** Admins can flip a stuck item to `canceled`, `failed`, or `completed` with a reason; the change is audit-logged. An `undo-force-status` action replays the prior state if needed.
- **Scraper-success refund flow rewritten.** The submission flow now uses a unified server action for refunds (faster, atomic), a credit-cycle picker in S4 (`Latest` / `Job` / `Job + Latest`), per-sheet excluded-columns granularity, and records a versioned `ScraperSuccessStats` snapshot on each submit.
- **`/admin/logs` page.** Three tabs for inspecting frontend logs — a live in-memory ring buffer, a feed from the logger-crab dashboard (5s refresh), and a demo tab with 12 buttons to emit synthetic events for smoke-testing.
- **Scraper-requests dashboard enhanced.** New enriched endpoint with team/job/status/deleted filters and per-row owner enrichment (user + team) in a single round-trip.
- **Team credit-cycle visibility.** The expiring-cycles cron posts a daily Block Kit Slack report (14:00 UTC) classifying every active team into 5 urgency tiers and listing admin contacts.

## Platform improvements (invisible but load-bearing)

- **Worker reliability — circuit breakers and retry budgets.** Transient downstream failures (provider 5xxs, timeouts) no longer get retried into a storm. Per-worker breakers trip independently; a fleet-level consensus layer in Redis coordinates recovery via a single half-open probe. A fleet-wide retry budget fails fast once exhausted.
- **Graceful worker shutdown.** Workers now drain in-flight tasks on SIGTERM (configurable timeout) instead of dropping work mid-flight. Heartbeats moved to Redis with rolling TTL; a reaper releases locks held by crashed workers.
- **Postgres credit-cycle gate.** Every task pickup now confirms the team has an active credit cycle, both via a Redis fast-path and a Postgres source-of-truth check on create-job and worker pickup.
- **Centralized observability.** Sentry init consolidated (fixes prior env-misclassification of dev as production). A new typed audit-events collection (90-day TTL) tracks every job/task/item state transition with actor + before/after state. New frontend logger with PII masking, isomorphic context, and five sinks.
- **Slack alert routing.** Alerts now name a topic (incidents / defers / daily / preflight / reaper) and the system routes to the right channel with cascade fallback. Operators stop seeing every alert in one firehose.

## Known caveats for first 1-2 weeks post-release

- **TanStack persist removed.** Returning users see a brief loading state on first jobs-list paint after a long tab idle. Normal within 1-2 seconds.
- **Internal-API auth migration.** Any team member with bookmarked internal admin URLs from before this release will need to re-login. The cookie + dashboard-password auth on internal routes was retired in favor of a header-based token; old bookmarks 403.
- **Job-output cache TTL conservative on first boot.** Cache TTL is intentionally short (60s) on first prod boot — preview rebuilds on every reload until ops tunes it up after stable.
- **Increased Slack alert volume in week 1.** Breaker thresholds and retry-budget limits are new — expect some tuning. Alerts in `#incidents` and `#defer-alerts` are normal; they self-resolve. If an alert recurs without resolving, escalate.
- **Deferred-state badges visible during downstream outages.** Items briefly showing a "deferred" badge means the system parked the task during a downstream hiccup — it recovers automatically. Not a user-action item.
- **Force-status admin tool is a hammer.** Admins flipping items to `failed`/`completed` should record a reason; audit-logged for review.

## For CS to know

- **The "deferred" badge is NORMAL and self-recovers.** If a customer asks "why is my item stuck on 'deferred'?", the answer is: a downstream provider had a brief hiccup, the system is pacing retries, and it will recover automatically. Escalate only if the badge persists >1 hour on the same item.
- **Returning users may see a brief loading state.** The jobs list no longer caches in the browser — first paint after a long tab idle takes 1-2s longer than before. Not a bug.
- **Error message wording may shift.** Some customer-facing job-output errors will read slightly differently — more specific to the actual cause, less generic. Same underlying problem, clearer wording.
- **Pause/resume is new.** Customers asking for "stop a job temporarily" now have it. Point them to the new progress cell with the resume button.
- **Internal bookmarks need refresh.** Any internal team member with a bookmarked `/internal/...` URL from before this release will need to re-login. Direct them to the relevant admin page via the sidebar.
- **First 1-2 weeks: alert volume in Slack may run high.** Engineering is tuning breaker thresholds. If a customer escalation lines up with a Slack alert storm, that's expected — the system is working as designed (failing fast instead of cascading).
