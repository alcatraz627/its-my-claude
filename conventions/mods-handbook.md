---
brief: How anything gcc draws inside the Claude Code TUI should look and behave (mods and the statusline), the band-row presets, the chip and link rules, and where borrowed community-mod ideas belong.
triggers:
  - topic:mods
  - topic:statusline
  - tool:gcc-mods
  - tool:statusline.sh
  - phrase:"band row"
  - phrase:"mod surface"
  - phrase:"statusline chip"
related:
  - features/gcc-mods.md
  - mods/gcc-mods/README.md
  - mods/gcc-mods/GUIDE.md
  - conventions/tui-handbook.md
  - conventions/pages.md
  - assets/reports/20261015-hub-statusline/PLAN.md
tier: 2
category: conventions
updated: 2026-10-15
stale_after_days: 90
---

# Mods handbook: what gcc draws inside Claude Code

Two things draw inside the Claude Code TUI: `scripts/statusline/statusline.sh` (always on, every session) and the gcc-mods plugin (`mods/gcc-mods`, off until `/hub on`). This page is the shared visual language for both, so an offer, a gauge or a link looks and behaves the same wherever it appears. The CLI, TUI and HTML-page equivalents are `conventions/cli-help-design.md`, `conventions/tui-handbook.md` and `conventions/pages.md`.

## Hard rules (each was learned the hard way)

1. No Button carries a `hotkey`, and nothing takes keyboard focus by itself. A focused pane once turned typed letters into button presses and ate a long prompt (2026-10-06).
2. Anything put into the prompt box is inserted at the cursor, never written over a draft.
3. The statusline must stand on its own: the mod is off by default, so nothing the owner relies on lives only in the mod.
4. Show the same number the same way everywhere. Context is shown as USED percent, never remaining (owner, 2026-10-15: "remaining is a bad metric since we already cap earlier").
5. Never drop a segment the statusline shows today without the owner's say (owner, 2026-10-15: "I don't wanna lose info I have today").

## Which surface for what

| Surface | What it can do | Use it for |
|---|---|---|
| statusline.sh lines | ANSI color, OSC 8 links that open on click (URLs, files, custom schemes such as `vscode://`), re-run every N seconds with the `refreshInterval` setting | Always-on state: who, spend, work, code, system |
| mod status line (`$.ui.status`) | One plain text line; no links, no clicks | Counts that need the mod's data (gates, ready rows, seats, mail) |
| band above the prompt (`AbovePrompt`) | Text, Links, Buttons, hover styles | One offer that needs an action: a decision page, a resume, a core-dump |
| pane (`$.ui.open` without `focus`) | A framed region, docked at 110+ columns in fullscreen, inline otherwise | Display-only views (a larger image, a task list). Text and Box only |
| toast, transcript line | Brief notices | Confirmations; never the only place a fact appears |

Clicking: statusline text can be a link but not a button. A link can open a page, a file, or a custom URL scheme; running an action from a click needs a scheme handler or the band's Buttons.

## Band rows

Preset **S1** is the default for every band row (owner, 2026-10-15: "lets do S1, let this be the preset for all going forward"). One line per offer:

```
[kind chip] title · detail · link        [primary] [secondary] ✕
```

- Kind chip: glyph plus one word, chip background `#24283b`, foreground by kind: decide `#7dcfff`, resume `#9ece6a`, context or warning `#e0af68`, error `#f7768e`.
- Title in the plain foreground; detail dim.
- A link is a `Link`, underlined on hover, never a raw URL in text.
- Actions are Buttons: one primary (filled `#3d59a1`), the rest secondary (chip background). Hover lightens a Button.
- `✕` hides the band; it turns red on hover. It sits on the same line, never its own line.

Saved presets, for uses still to be assigned ("we'll bifurcate specific uses later"):

- **S2, accent bar:** a `▎` bar in the kind color, at most two lines (title line, then link and actions). For an offer that needs one more line of context.
- **S3, rounded box:** a round-bordered Box titled with the kind chip. For a heavier offer the owner should not miss.

Previews: `assets/decision-pages/statusline-1015b/band-s1.png`, `band-s2.png`, `band-s3.png`.

## Statusline visual language

- **Lines are categories:** who, spend, work, code, system, one per line, each led by a glyph in its hue (who `#7aa2f7`, spend `#e0af68`, work `#7dcfff`, code `#bb9af7`, system `#737aa2`).
- **Color means state:** green fine, yellow watch, red act now; labels dim, values in the plain foreground.
- **Chips** (soft `#24283b` background) mark a value that is a live gauge or needs the owner. A healthy, static value stays plain.
- **Glyph vocabulary** (from flightdeck): `●` warm or active, `○` cold or idle, `◐` running, `✓` passed, `✗` failed, `↻` time to reset, `▮▮▮▯` effort, a two-tone gauge with a `┊` tick at the auto-compact line.
- **Numbers in words:** `31 changed`, `1h30m`, `380K/1M`, `11¢/turn`, `cold in 42m`.
- **Links:** a path or page the owner may open is an OSC 8 link. Every file, markdown included, links as `file://<absolute path>` and opens in its native app; `.md` already opens in the browser by default. Never route a file through the kanban doc viewer (owner, 2026-10-15: "please let them open natively").
- **Optional segments appear only when they apply**, as today. Mocks show a "busy" state with everything present; say so on any mock so it does not read as the everyday look.

## Borrowed ideas and where they go

| Idea | From | Goes to | Notes |
|---|---|---|---|
| Cold re-read price, warm/cold clock | cache-tax | statusline spend line; S1 band row when the cache is cold and the context is large | Prices from `scripts/usage-stats.py` RATES only; never drop or delay a message (cache-tax's refuse mode can) |
| "Ping was warm" check (read above 0, write under 10% of read) | cache-tax | `scripts/keepwarm/keepwarm.py` health check | Logs a failed warm-up; keepwarm stays the only warmer |
| Gauge, state dots, `↻`, effort meter, width tiers, role colors | flightdeck | statusline and band | Visual only; flightdeck's digit and letter hotkeys are not copied |
| Image opener and larger view | image-view | band (S1 row with an `open` Button running `open <png>`) and an unfocused display-only pane | Reuse its image lookup and `sips` conversion; check the CPU cost of a fast poll first |
| Git colors and activity flashes | filetree | maybe the code line | The plugin itself is skipped: focused pane with letter hotkeys |

## Checks before calling a surface done

Render it and look (rule `ui-visual-verification`): a screenshot in the real terminal or a Ghostty-palette mock, read back. For the mod, run the three checks in `mods/gcc-mods/README.md`. Any new Button is covered by the existing no-hotkey test.
