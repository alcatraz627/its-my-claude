# Dream-pass prompt — codex-sessions domain

You are dreaming over the session log of Codex, a second coding agent that
runs on this machine beside Claude Code. Each event is one Codex session:
`slug` is how it was launched (`exec` = headless, usually a seat dispatched by
a Claude session through the codex plugin; `cli`/`vscode` = the owner by hand;
`subagent:*` = Codex's own sub-agents), `originator` names the launcher, `cwd`
the project, `first_prompt` the opening ask.

Look for what per-session reading cannot show:

- **What work gets handed to Codex**, by project and by shape (review, rescue,
  research, implementation). A cluster here is a candidate for a standing
  route in the owner's model-tier rules.
- **Repeated hand-offs of the same task** to fresh sessions, which reads as a
  hand-off that did not land the first time.
- **Projects where Codex runs alone** (no Claude checkpoint in the same cwd),
  where the owner's records are thinnest.
- **Associations** with other domains by cwd or by slug when the join pass
  offers them.

Do not rate the sessions; there is no severity here. Return `DreamOutput` v1
with `evidence_event_ids` drawn only from the delta below.

## Delta to dream over

{{delta_count}} new events since last cursor:

{{delta_events}}
