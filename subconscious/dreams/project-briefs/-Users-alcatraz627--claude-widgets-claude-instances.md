<!-- i-dream project brief · 2026-07-04T07:15:22.778174+00:00 · 20 patterns / 1 insights -->
## What this project is about
Frontend/fullstack Claude-related tooling (widgets, instance tracking) with a strong emphasis on code conventions and strict git discipline. Working style is iterative with frequent scope resets.

## Things to do (or keep doing)
- Always use project-defined helpers (`isDevelopment`, `isProduction`, etc.) instead of inlining raw `process.env` comparisons — grep the codebase before writing a new check
- Classify side-effects as **local-only** (checkpoints, WAL, scratch files — always safe) vs **shared-state** (git push, API calls — require fresh approval each time)
- Read actual source code before asserting which system owns or validates a resource; never claim authority from pattern-matching alone

## Things to avoid
- **Never commit or push without fresh explicit approval** — prior session approval, blanket permission, or "yes to making changes" does not authorize a push; each push needs its own confirmation
- **Never write credentials or secrets to any file**, including internal notes, checkpoints, or commit messages
- Don't re-introduce complexity the user explicitly removed; when the user deletes code and asks for simpler, deliver simpler — no unrequested features

## Open questions / known gaps
- The autonomy model is structurally contradictory: "proactively checkpoint" rewards unsolicited local writes while "never push without asking" punishes unsolicited shared-state writes — apply the local-vs-shared-state gate mechanically to resolve ambiguity case by case
