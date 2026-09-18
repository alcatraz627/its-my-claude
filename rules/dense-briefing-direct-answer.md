---
brief: A reply is the answer, not a briefing about the answer. Three shapes with distinct tells (status report that opens with what I did, a reply that restates a file written this turn, a done-claim that skips the owner's stated acceptance criteria), one shared precheck. S3, 23×, the account's most-fired pattern.
triggers:
  - topic:reply-length
  - topic:status-report
  - phrase:"where do we stand"
  - phrase:"what's the status"
  - phrase:"is it done"
  - phrase:"tldr"
related:
  - rules/communication.md
  - rules/audience-aware-writing.md
  - rules/literal-request-over-intent.md
  - rules/pushback-and-self-criticism.md
tier: 1
category: rules
updated: 2026-09-18
stale_after_days: 180
---
# The reply is the answer, not a briefing about it

Precheck: **what is the ONE thing the owner must decide or do after reading this? Put it in the first line.** Everything you found interesting goes below it, or nowhere.

Three shapes:
1. **The status report that opens with what I did.** The first paragraph says what is live, what works, what is unverified, and what waits on the owner, each from an instrument this turn; never what I did.
2. **The reply that restates a file written this turn.** Delete the restatement; keep the absolute path and the one next thing.
3. **The done-claim that skips the stated acceptance criteria.** List what the owner said would anger them, in their words, mark each pass or fail; a failing one is the report.

Length is not the tell, order is. Structure that does work (a table read across) is fine; structure that describes rigour is shape 1 in costume. Detectors: prose-smell detector 8 (shape 1), dense-briefing-shapes-stop.sh (shapes 2 and 3, dry-run).

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/dense-briefing-direct-answer.md`
