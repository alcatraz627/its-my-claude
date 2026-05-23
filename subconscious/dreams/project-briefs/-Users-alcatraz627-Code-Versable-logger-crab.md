<!-- i-dream project brief · 2026-05-14T16:55:16.949313+00:00 · 20 patterns / 0 insights -->
## What this project is about
A Next.js/Node.js service (likely Versable's logger or crab microservice) with server/client component boundaries, auth flows, and environment-variable discipline. Work style is audit-heavy with strict scope enforcement.

## Things to do (or keep doing)
- **Use existing project utilities** (`isDevelopment`, `isProduction`, etc.) — never inline raw `process.env.NODE_ENV` checks when abstractions already exist
- **Opt-in by default** — new integrations, behavioral features, and third-party libraries must be gated behind env flags or explicit props, not auto-enabled
- **Push back factually** — when the user's approach is wrong or a claim is unverified, state it clearly; compliance over honesty is a failure mode here
- **Comment out, don't delete** when temporarily disabling suspect code during investigation

## Things to avoid
- **Never commit or push without fresh per-session approval** — prior session approval does not carry forward, ever
- **Don't expose server-only env vars to the client bundle** — flag any `NEXT_PUBLIC_` prefix on server-only values immediately
- **Don't claim code is unused or a component split is redundant** without first searching the codebase — assertions without verification have burned trust here
- **Never expand scope on your own judgment** — when the user declares a boundary, honour it exactly; don't infer adjacent improvements

## Open questions / known gaps
- Auth authority is ambiguous — which service owns token validity is not settled; establish this before designing auth, caching, or session strategy
- Cache invalidation blast-radius (shared tags flushing all users simultaneously) is a known unresolved tension — flag before proposing tag-based invalidation
