---
brief: The gcc-mods plugin draws gcc's owner surfaces inside the Claude Code TUI (hub pane, band, status line, transcript restyles, wakes) and routes tagged hook output to the owner instead of the model.
triggers:
  - tool:gcc-mods
  - topic:mods
  - topic:plugin
  - phrase:/hub
  - phrase:the hub
  - phrase:put it in the hub
  - phrase:owner surface
  - phrase:hook_owner_wrap
  - phrase:catchup band
  - phrase:tasks pane
related:
  - mods/gcc-mods/README.md
  - scripts/hooks/hook-common.sh
  - features/hooks-tui-limits.md
  - assets/reports/20261006-mods-scour/PROPOSAL.md
tier: 2
category: features
updated: 2026-10-06
stale_after_days: 60
---

# gcc-mods

Claude Code mods (early access, CLI 2.1.291) can draw in the TUI, which hooks never could. `~/.claude/mods/gcc-mods` is gcc's mod: one hub pane (`/hub`), one band, one status line, transcript restyles, and the timers that wake an idle session. The user-facing description and the per-surface table are in its README.

## What changes for a hook author

Owner-facing text no longer has to ride through the model with "paste this verbatim". Wrap it:

```sh
. "$HOME/.claude/scripts/hooks/hook-common.sh"
emit_ctx "$EVENT" "$(printf '%s\n' "$box" | hook_owner_wrap log my-hook)"
# or, with a line the MODEL should read instead once the block is drawn:
hook_owner_wrap pane:tasks task-table-inject "The pane draws it; point there."
```

Surfaces: `toast`, `log` (a dim transcript line), `band`, `pane:nudges`, `pane:tasks`, `ask` (the engine's question dialog; the first line is the question, `- ` lines the options, the answer reaches the model as an owner-written row).

Keep the paste instruction inside the block and any model duty outside it. A session without the mod sees the tag as text and behaves as before; the Codex adapter unwraps it in `gcc_ctx_of`.

## How it loads

Every session loads it through `CLAUDE_CODE_PLUGIN_DIRS` in the `env` block of `~/.claude/settings.json`, and it starts off: hooks pass through and nothing is drawn until `/hub` turns it on for that session. A hook author can rely on neither state, which is why the owner tag must read as plain text when the mod is off. To stop loading it at all, remove that env entry; it takes effect in new sessions.

## Checks after a CLI update

`claude plugin validate`, `tsc` against the laid types, `claude plugin test` on the skills folder. The types file's first line names the CLI version that wrote it. The three validator rules the types cannot express: `$` is followed only into functions declared in the module file, an event is registered without a matcher at most once per module, and every `$.state` reference is spelled with literal `plugin` and `key`.

## Not built

Push approval buttons (owner, 2026-10-06: the Switchboard is the unified place for approvals). The push-approve origin check at `scripts/hooks/push-approve-prompt.sh:44` is still open and independent of the mod.
