# i-dream Integration Request — codex-sessions

Per `i-dream contract` §8, a system's first integration is a report for the
owner, not a self-registration. Everything below is staged in
`~/.claude/adapters/codex/i-dream/`; registering is one `cp` (see the manifest
header). Codex ledger events (proposals, atone, affirm, pins filed through
`gcc`) already reach i-dream through the existing domains, tagged `src:codex`;
this request is only about Codex's own session history.

1. SYSTEM: Codex CLI session history (`~/.codex/sessions/**/rollout-*.jsonl`).
   Why dream over it: it is the only record of the third agent on this machine.
   A Claude session that dispatches a Codex seat records the dispatch; the seat's
   own run is invisible to every gcc loop unless this domain exists.
2. PATTERN: synthesized (`extract-events.sh` derives one event per session).
3. EVENT STREAM:
   - path: `~/.claude/adapters/codex/i-dream/events.jsonl` (extractor output)
   - id_field: `id` (the Codex thread id, stable) / ts_field: `ts`
   - sample event:
     `{"id":"01a08198-73f4-7da3-a8ab-2228919c42ce","ts":"2026-09-08T15:17:27.184Z","cwd":"/Users/alcatraz627/Code/Versable/slack-automation","slug":"vscode","originator":"Claude Code","cli_version":"0.149.1","first_prompt":"<task> Review the diff of branch integrate/bot-and-dig..."}`
4. IMPORTANCE: none. `[hinter].weight = 0.5`, below every active-signal domain,
   so a session line can never evict an atone pattern from the session-start
   top-5.
5. CATEGORIZATION: `slug` = launch source (`exec`, `cli`, `vscode`,
   `subagent:review`, `subagent:thread_spawn`, `subagent:other`). Recurrence of
   a slug is a launch-pattern signal, not a mistake.
6. prompt_fields: `["slug", "originator", "cwd", "first_prompt"]`
7. PROCESSING: cluster hand-offs by project and shape; flag the same task handed
   to fresh sessions repeatedly (a hand-off that did not land); name projects
   where Codex runs with no Claude checkpoint beside it. Prompt staged at
   `dream/prompt.md`.
8. RETURN CHANNEL: none in v1. Insights are read from `dream/insights.jsonl`
   and the daily digest.
9. CADENCE: weekly dream, daily consolidation (the extractor is cheap).
10. OPEN QUESTIONS:
    - Should `first_prompt` (240 chars of the opening ask) go to the dream LLM
      at all? It is the most informative field and the most likely to carry a
      path or a name the owner would not want summarized. Default staged: yes.
    - The rollouts hold 70 files, 92 MB. The extractor reads the first 200 KB of
      each, which covers `session_meta` and the first user turn; confirm that
      bound is acceptable rather than reading whole files.
