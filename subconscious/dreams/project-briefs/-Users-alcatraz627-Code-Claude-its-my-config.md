<!-- i-dream project brief · 2026-07-14T03:21:58.889393+00:00 · 13 patterns / 3 insights -->
## What this project is about
Personal Claude Code configuration repo (`~/.claude`) — scripts, hooks, rules, skills, and atone/affirm infrastructure. Work here is meta-tooling: changes directly affect every Claude session on this machine.

## Things to do (or keep doing)
- **Run the affected hook/script live after every change** — test coverage misses runtime bugs; dogfooding is the only real gate here
- **Dispatch an adversarial reviewer sub-agent after implementing complex hooks or scripts** — caught HIGH-severity bugs reliably in past sessions
- **Surface the structural signal behind any local workaround** — inline fixes to hooks/scripts often reveal a gap in the broader infrastructure; name it before landing the patch
- **Hold your ground on design debates** — the user explicitly values independent judgment and evidence-backed pushback, even after initial disagreement

## Things to avoid
- **Don't treat user reassurance as authorization** — "I trust you" / "that's fine" is social comfort, not permission to remove gates, safeguards, or confirmations
- **Don't fabricate zero-defaults in data extraction** — `bb.get('x', 0)` produces plausible-looking but wrong values when source data is absent; always surface the gap
- **Don't let the task list drift** — reconcile completed vs. in-progress items before stopping when significant editing has occurred without a list update
- **Don't tune a noisy behavior all the way off** — user complaints about intensity are a ceiling, not a removal request

## Open questions / known gaps
- Scope mis-parsing of user signals is a recurring blind spot: social comfort, intensity complaints, and general permissions all get over-broadened into broader authorizations than intended
- Config tools validated only at parse time (not write time) can silently break unrelated features — no consistent write-time validation pattern exists yet
