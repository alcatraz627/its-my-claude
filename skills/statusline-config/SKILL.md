---
name: statusline-config
description: Interactively toggle statusline segments and profiles
allowed-tools: [Read, Edit, Glob, mcp__inputs__pick_one, mcp__inputs__pick_many, mcp__inputs__confirm, mcp__inputs__form]
---

# Statusline Config

Interactively view and toggle statusline segment visibility across profiles.

## Config Location

`~/.claude/statusline.conf` — INI-style with sections `[default]`, `[minimal]`, `[full]`, `[custom]`. Each segment is `key=value` where value is `1` (always on), `0` (always off), or `auto` (context-dependent).

## Segments Reference

Segments are grouped by category:

| Category | Segments |
|---|---|
| Core | `dir`, `git`, `model`, `context`, `agent`, `session_id` |
| Display | `icons` (0=text, 1=nerd font) |
| Cost/Performance | `cost`, `duration`, `lines`, `rate`, `countdown`, `cpu`, `warn_200k` |
| Agent-decided | `tools`, `wal`, `ctx_comp`, `uncommitted`, `ext_changes`, `scratchpad`, `complexity`, `turns`, `network` |
| Contextual | `pm2`, `ports`, `mcp`, `pr` |
| Analytics | `sparkline`, `depletion`, `subagents`, `timeline` |
| System/Environment | `mem`, `disk`, `tok_speed`, `git_stash`, `uptime` |
| Efficiency/Insight | `edit_ratio`, `branch_age`, `cost_vel`, `focus_file`, `test_status` |
| Token Analytics | `cache_hit`, `cache_write`, `out_ratio` |
| Git/Workflow | `merge_conflicts`, `files_touched` |
| Runtime/Environment | `runtime_ver`, `cloud`, `sudo` |
| Environment Context | `tmux`, `docker` |
| Tool Telemetry | `exit_code`, `latency` |

## Adaptive Behavior

The statusline uses three layers of filtering:
1. **Config** (this file): static user preference per segment (1/0/auto)
2. **Width tier**: segments auto-hide at narrow widths (>=140=full, 100-139=normal, 80-99=narrow, <80=compact)
3. **Session phase**: early sessions (<5 turns) suppress efficiency metrics; deep sessions (>20 turns) show everything
4. **Budget trimming**: if line 2 segments would overflow, lowest-priority segments are dropped automatically

## Interactive Input

**Prefer MCP interactive inputs over free-text questions.** When asking the user what to change:
- Use `mcp__inputs__pick_one` for profile selection
- Use `mcp__inputs__pick_many` for selecting segments to toggle
- Use `mcp__inputs__confirm` before applying changes

## Playground Link

For visual customization with live preview, mention the web playground:
```
node ~/.claude/assets/static/statusline-server.mjs
# Then open http://localhost:5081
```

## Execution Phases

### Phase 1 — Read and Display

1. Read `~/.claude/statusline.conf` using the Read tool.
2. Parse all three profiles: `[default]`, `[minimal]`, `[full]`.
3. Display the current state as a comparison table, grouped by category. Use this exact format:

```
Statusline Configuration — All Profiles
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 Segment        │ default │ minimal │  full
────────────────┼─────────┼─────────┼────────
 CORE
 dir            │    1    │    1    │    1
 git            │    1    │    1    │    1
 model          │    1    │    1    │    1
 context        │    1    │    1    │    1
 agent          │  auto   │  auto   │    1
 session_id     │  auto   │    0    │    1
────────────────┼─────────┼─────────┼────────
 DISPLAY
 icons          │    0    │    0    │    1
────────────────┼─────────┼─────────┼────────
 COST / PERF
 cost           │  auto   │    0    │    1
 ...            │   ...   │   ...   │   ...
────────────────┼─────────┼─────────┼────────
 (remaining categories follow the same pattern)
```

Use the actual current values from the file, not hardcoded values. Render the full table with all segments, not truncated.

4. After the table, print a legend:
   - `1` = always visible
   - `0` = always hidden
   - `auto` = shown based on context/heuristics

5. State which profile is currently active. Check for `$STATUSLINE_PROFILE` env var; if unset, state that `default` is active.

### Phase 1.5 — Live Preview of Current Config

Before asking what to change, show a live rendered preview of the active profile at two widths. Use the Bash tool:

```bash
PREVIEW_JSON='{"model":{"display_name":"Claude Sonnet 4.6"},"context_window":{"remaining_percentage":62,"total_input_tokens":45000,"total_output_tokens":8000,"context_window_size":200000},"cost":{"total_cost_usd":0.38,"total_duration_ms":900000,"total_lines_added":24,"total_lines_removed":6,"cache_read_input_tokens":36000,"cache_creation_input_tokens":9000},"rate_limits":{"five_hour":{"used_percentage":43,"resets_at":9999999999},"seven_day":{"used_percentage":8}},"workspace":{"current_dir":"'"$HOME"'"},"session_id":"preview-00"}'

echo "── Preview: ${ACTIVE_PROFILE} @ 140 cols ──"
echo "$PREVIEW_JSON" | STATUSLINE_COLS=140 STATUSLINE_PROFILE=${ACTIVE_PROFILE} bash ~/.claude/scripts/statusline/statusline.sh 2>/dev/null

echo "── Preview: ${ACTIVE_PROFILE} @ 80 cols ──"
echo "$PREVIEW_JSON" | STATUSLINE_COLS=80 STATUSLINE_PROFILE=${ACTIVE_PROFILE} bash ~/.claude/scripts/statusline/statusline.sh 2>/dev/null
```

Replace `${ACTIVE_PROFILE}` with the active profile. This shows what the statusline currently looks like before any changes are made.

### Phase 2 — Ask What to Toggle

Ask the user what they want to change. Accept any of these input styles:

- **Single toggle**: "turn off sparkline in default" or "sparkline=0 in default"
- **Bulk toggle**: "turn off all analytics in minimal" (applies to the category)
- **Multi-segment**: "enable cost, duration, lines in default"
- **Profile copy**: "make minimal match default for cost/perf segments"
- **Value cycling**: "cycle agent in default" (cycles 1 → 0 → auto → 1)

Parse the user's intent and confirm what changes will be made BEFORE applying. Show a mini-diff like:

```
Proposed changes to [default]:
  sparkline:  auto → 0
  depletion:  auto → 0
```

Wait for the user to confirm (yes/y/ok/go/do it) or revise.

### Phase 3 — Apply and Show Diff

1. Use the Edit tool to modify `~/.claude/statusline.conf`, changing only the specific `key=value` lines in the target profile section(s).
2. Preserve all comments, blank lines, and section ordering exactly as they are.
3. After editing, re-read the file to verify changes landed correctly.
4. Show a before/after summary:

```
Applied 2 changes to [default]:
  sparkline:  auto → 0  ✓
  depletion:  auto → 0  ✓
```

5. **Show live preview**: after applying changes, render a live preview of the statusline by piping a synthetic JSON blob through the script at 120 and 80 cols. Use this exact command:

```bash
PREVIEW_JSON='{"model":{"display_name":"Claude Sonnet 4.6"},"context_window":{"remaining_percentage":62,"total_input_tokens":45000,"total_output_tokens":8000,"context_window_size":200000},"cost":{"total_cost_usd":0.38,"total_duration_ms":900000,"total_lines_added":24,"total_lines_removed":6},"rate_limits":{"five_hour":{"used_percentage":43,"resets_at":9999999999},"seven_day":{"used_percentage":8}},"workspace":{"current_dir":"'"$HOME"'"},"session_id":"preview-00"}'

echo "── 120 cols ──"
echo "$PREVIEW_JSON" | STATUSLINE_COLS=120 STATUSLINE_PROFILE=<PROFILE> bash ~/.claude/scripts/statusline/statusline.sh 2>/dev/null

echo "── 80 cols ──"
echo "$PREVIEW_JSON" | STATUSLINE_COLS=80 STATUSLINE_PROFILE=<PROFILE> bash ~/.claude/scripts/statusline/statusline.sh 2>/dev/null
```

Replace `<PROFILE>` with the profile that was just edited. The output shows the rendered statusline — use the Bash tool to run this and display the result to the user.

6. Ask if the user wants to make more changes. If yes, loop back to Phase 2.

### Phase 4 — Profile Switch (Optional)

If the user asks to switch the active profile, explain that the active profile is controlled by the environment variable:

```
export STATUSLINE_PROFILE=minimal
```

Offer to add this to their shell RC file (`~/.zshrc` or `~/.bashrc`) if they want it permanent. Do NOT modify shell RC files without explicit confirmation.

## Rules

- **Never delete sections or comments** from the config file. Only modify `key=value` lines.
- **Validate values**: only accept `1`, `0`, or `auto` as segment values. Reject anything else and explain why.
- **icons is special**: its values mean `0`=text labels, `1`=nerd font icons. Mention this when the user toggles it.
- **Unknown segments**: if the user references a segment name not in the file, warn them and list the valid segment names.
- **Preserve formatting**: maintain the exact whitespace and comment structure of the original file.
- If the user asks to "reset" a profile, set all values to match what that profile conceptually represents:
  - `default` = core segments on, everything else `auto`
  - `minimal` = core on, everything else `0` (except `warn_200k` and `network` which stay `auto`)
  - `full` = everything `1` (except `complexity` which is `0` per current config)
