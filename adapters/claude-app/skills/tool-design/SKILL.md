---
name: tool-design
description: Designs CLI tools, TUIs, small single-user dashboards and tools an agent will drive. Help text, pipe mode, destructive-op safety, fzf launchers, safe state, one-command run checks.
---

# Tool design

How to design a tool someone will use from a terminal, a local browser tab, or
an agent's tool calls. The question that picks the reference is who the user
is, and how they see the output.

| The tool's user | They see output as | Read |
|---|---|---|
| A person typing commands | Text in a terminal, often piped | `references/cli-design.md` |
| A person browsing a list and acting on it | An interactive terminal screen | `references/tui-design.md` |
| A person watching local state in a browser | A single-page local dashboard | `references/dashboard-tools.md` |
| An AI agent calling the tool | Bytes it pays attention for, with no eyes | `references/agent-first-tools.md` |
| Anyone, while you build it | The one command that proves it works | `references/run-and-observe.md` |

Most tools touch two rows. A CLI with an interactive mode reads the first two.
A tool for both a person and an agent designs the agent surface first and
renders the human view from it. Every build reads the last row.

## The user's default taste

For developer tools the user wants dark, dense, terminal-dashboard style, and
keyboard-first. Every common action has a key. Mouse support is a bonus, never
the only path. Output is compact, aligned and monospace for data. Color
carries meaning (ok, warn, danger, active), never decoration. The project's
existing conventions outrank these defaults.

## The rules that cross every kind of tool

**Output**
- Plain when piped. Detect a non-TTY, honor `NO_COLOR` and `TERM=dumb`, and
  offer `--json` where `tool | jq` makes sense.
- Content meant to be saved comes out as source by default. Rendering needs a
  flag.
- Never return silence. An empty result says it is empty.
- Unknown is shown as labelled unknown, never as a plausible zero.

**Errors**
- An error names the conflict and the next move in one message. "Refused" on
  its own is not an error message.
- For an agent, an ambiguous request returns ranked candidates and the exact
  next command, in the same response.

**Destruction**
- Exact matching by default in any picker that destroys.
- Show the count and the ids before a bulk destroy.
- Floor-guard any value where zero or negative quietly means "all".
- Replace by rotating to a backup, never by unlinking first.

**State**
- One source of truth. Reads never write.
- One lock around load, mutate and save for every writer.
- Writes are atomic: temp file, then rename.

**Structure**
- Split the UI from the actions. Hidden verbs (`tool --__feed`,
  `tool --__kill ...`) that take arguments and print let tests drive the logic
  and let the interactive shell stay thin.
- Pick the lightest stack. A list-browse-act tool is fzf, not a framework. A
  dashboard is vanilla JS on one page, not a build pipeline.

**Verification**
- Before the first feature, build the one command that runs the tool and shows
  the result, including the warning state and the empty input.

## Working through a design

1. **Name the user and the surface** from the table. If the user's ask leaves
   it open (a "tool" that could be a CLI or a page), ask once, or state the
   reading you are taking.
2. **Read the matching reference** and list which of its rules this tool
   triggers. A read-only lister does not need the destructive-tool section.
3. **Write the run command first.** A `--self-test`, a `make check`, or a
   short script. In claude.ai, build and run it in the sandbox. When the tool
   runs only on the user's machine, hand them the command and say what output
   means pass.
4. **Sketch the surface before code**: the help text for a CLI, the key map
   and preview contents for a TUI, the response shape for an agent tool, the
   state file shape and endpoint list for a dashboard. Show it to the user when
   the shape is a real choice.
5. **Build infrastructure before features.** For a dashboard that means state,
   lock, server, watcher, page, in that order. For a CLI it means the hidden
   verbs, then the interactive layer over them.
6. **Run it** through the real entry path, in the states that matter, and
   report what you ran and what it printed.

## Visual parts

For colors, status lights and the dashboard page's look, use
`design-reference`. Its severity rule matters here too: a status light fires on
evidence of a felt problem, and a steady amber is a bug. To review a rendered
dashboard, use `ui-critique`.

## Boundaries

- The patterns are general. Do not invent the user's file paths, ports or
  tool names. Ask, or use placeholders they can fill.
- A design for a tool that runs on the user's machine ends with the exact
  commands to install and run it, not with "set it up".
- Code samples are starting points in the language the project already uses.
  Translate rather than adding a second runtime.

## Related skills

`design-reference` (color, layout, page tokens), `ui-critique` (reviewing a
rendered UI), `mock-app` (a clickable mock before building), `change-plan`
(planning the build with a check per step), `code-rules` (code conventions),
`write-docs` (the README and man page), `skeptical-review` (reviewing the
finished tool).
