<!-- i-dream project brief · 2026-08-06T15:14:44.191580+00:00 · 3 patterns / 0 insights -->
## What this project is about
A search/filtering pipeline over Fable model runs — likely produces ranked or scored output lists that get reviewed and handed off. Dominant working style: generate, self-verify, deliver clean results.

## Things to do (or keep doing)
- **Read your own output before claiming it's ready** — for any ranked, enumerated, or scored list, scan every row yourself before delivery; don't trust that generation = correctness
- **Filter against domain criteria actively** — before handing off a scored list, sweep for entries that obviously violate the stated scope and drop them; don't leave that as the user's job

## Things to avoid
- **Don't resurface rejected background automation** — if the user declined a pm2 service, cron, warm-up process, or similar in any prior turn, do not re-propose it later, even as a side suggestion
- **Stop delivering lists you haven't read** — producing output and immediately handing it off without a self-review pass is the primary failure mode here; it ships irrelevant entries as if they were valid hits

## Open questions / known gaps
- _(no signal yet)_ on what "domain criteria" means concretely for this search surface — clarify with the user before filtering aggressively
