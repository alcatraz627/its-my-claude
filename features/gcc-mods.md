---
brief: The gcc-mods plugin draws a few passive owner surfaces inside the Claude Code TUI (clickable paths, the resume band, the status line, wakes). No pane and no hook router since 2026-10-15.
triggers:
  - tool:gcc-mods
  - topic:mods
  - topic:plugin
  - phrase:/hub
  - phrase:the hub
  - phrase:catchup band
  - phrase:hook_owner_wrap
related:
  - mods/gcc-mods/README.md
  - scripts/hooks/hook-common.sh
  - features/hooks-tui-limits.md
  - assets/reports/20261015-queue/q-design-mods-trim.md
tier: 2
category: features
updated: 2026-10-15
stale_after_days: 60
---

# gcc-mods

Claude Code mods (early access, CLI 2.1.291) can draw in the TUI, which hooks never could. `~/.claude/mods/gcc-mods` is gcc's mod. Since the 2026-10-15 trim it draws only surfaces that need no opening: home paths as clickable absolute links, one band (a pending decision page, the resume offer after a clear, continue when agent-ready rows are open, the core-dump insert past 70 percent), one status line, and the timers that wake an idle session when a decision page is answered or a seat report lands. The six-tab hub pane, snippets, and the hook router are gone. The README holds the per-surface table.

## For a hook author

There is no router any more, so `hook_owner_wrap` output reaches the model as plain text whether the mod is on or off. Write owner-facing text so it reads correctly as text, and keep any duty for the model outside the tagged block. The Codex adapter still unwraps the tag in `gcc_ctx_of`.

## How it loads

Every session loads it through `CLAUDE_CODE_PLUGIN_DIRS` in the `env` block of `~/.claude/settings.json`, and it starts off: nothing is drawn until `/hub on` turns it on for that session, or the `startOn` switch in `/config` turns it on everywhere. To stop loading it at all, remove that env entry; it takes effect in new sessions.

## Checks after a CLI update

Call the binary by path, `/Users/alcatraz627/.local/bin/claude`, because the bare name refuses `plugin test` from inside a session. Run `claude plugin validate`, `tsc` against the laid types, and `claude plugin test` on `~/.claude/mods/gcc-mods`. The types file's first line names the CLI version that wrote it. The three validator rules the types cannot express: `$` is followed only into functions declared in the module file, an event is registered without a matcher at most once per module, and every `$.state` reference is spelled with literal `plugin` and `key`.

## Not built

Push approval buttons (owner, 2026-10-06: the Switchboard is the unified place for approvals).
