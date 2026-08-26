---
name: diagram
description: Renders terminal diagrams — flowcharts, sequence diagrams, trees, tables, state machines, and architecture layouts — using gum-tui.sh for box-accurate rendering. Use when explaining spatial or hierarchical structures visually.
allowed-tools: Bash
user-invocable: true
argument-hint: "<description of what to diagram>"
---

## Brief

Renders rich terminal diagrams by generating and executing bash scripts via `gum-tui.sh`.
Supports 6 diagram types, auto-detected from the input description. Uses `gum style`,
`gum table`, and `gum join` for all box/table rendering — never outputs raw Unicode art
as inline text, which produces misaligned borders.

## Step 0: Load Shared Guidelines and Runtime Context

Source `~/.claude/skills/shared/gum-tui.sh` before rendering any diagram:

```bash
source ~/.claude/skills/shared/gum-tui.sh
```

If `gum` is not installed, fall back to raw Unicode rendering and warn the user:

```bash
command -v gum >/dev/null 2>&1 || { echo "⚠ gum not found — install with: brew install gum"; }
```

Also read `.claude/skills/runtime-notes.md` for past rendering notes relevant to this skill.

# ASCII Diagram Generator

Renders rich terminal diagrams using gum-tui.sh for consistent box borders and aligned output.
Supports 6 diagram types, auto-detected from the input description.

## Usage

```
/diagram <description>
```

**Examples:**
- `/diagram flowchart: user -> login -> validate -> issue token -> dashboard`
- `/diagram sequence: client -> api -> db -> api -> client with error handling`
- `/diagram tree: src/ with components/, hooks/, utils/, pages/`
- `/diagram state: idle -> loading -> success/error -> idle`
- `/diagram architecture: React frontend -> Next.js API -> PostgreSQL + Redis`
- `/diagram table: compare REST vs GraphQL vs gRPC on speed, complexity, caching`

## Diagram Type Detection

Detect the diagram type from keywords in the input:
- **flowchart**: "flow", "->", "process", "steps", "pipeline", "workflow"
- **sequence**: "sequence", "client -> server", "request/response", "call"
- **tree**: "tree", "hierarchy", "directory", "structure", "src/"
- **table**: "compare", "vs", "table", "matrix", columns
- **state**: "state", "idle", "transition", "FSM"
- **architecture**: "architecture", "layer", "frontend/backend", "system"

If ambiguous, default to **flowchart**.

## Rendering Execution Model

**Always render by generating a bash script and executing it via the Bash tool.** Do NOT
output raw Unicode art as inline text — character-width alignment issues cause broken
borders when Claude generates text directly.

The workflow for every diagram:

1. Determine diagram type
2. Write a bash script that sources `gum-tui.sh` and uses gum commands to render
3. Execute it via `Bash`
4. The gum-rendered output appears in the terminal

```bash
source ~/.claude/skills/shared/gum-tui.sh
# ... gum commands specific to diagram type ...
```

**Gum rendering map by diagram type:**

| Type | Primary gum tools |
|------|-------------------|
| Table/comparison | `gum table --print` via `gum_table` |
| Architecture | `gum style --border` + `gum join --horizontal` for nested boxes |
| Flowchart nodes | `gum style --border rounded/normal` per node + hand-crafted arrows |
| Sequence | Hand-crafted Unicode lifelines (gum not used) |
| Tree | Hand-crafted Unicode tree chars (gum not used) |
| State machine | `gum style --border` for states + hand-crafted arrows |

**Arrows and connectors** are still hand-crafted Unicode — gum handles boxes, not routing.
Use the character palette below for all arrow/connector work.

## Rendering Rules

### Universal constraints
- Maximum width: 78 characters (fits in 80-col terminal with 1-char margin)
- Boxes MUST use gum commands — never hand-draw a box with raw Unicode
- Arrows/connectors/lifelines use the hand-crafted palette below
- No emoji — use ASCII/Unicode box-drawing only for connectors
- Labels inside boxes: pass as arguments to `gum style`, gum handles centering

### Character palette (connectors and arrows only — boxes use gum)
```
Arrows:   ──▶  ◀──  │▼  ▲│  ── ▷  ◁ ──
Dashed:   ╌╌╌▶  ┆  ╎    (optional/async flows)
Junctions: ├ ┤ ┬ ┴ ┼    (for tree/sequence joining)
Tree:     ├── └── │      (directory/hierarchy trees)
```

### 1. Flowchart

Render each node with `gum style --border`, then join with arrow connectors:

```bash
source ~/.claude/skills/shared/gum-tui.sh

START=$(gum style --border rounded --padding '0 2' 'Start')
STEP1=$(gum style --border normal --padding '0 2' 'Validate Input')
STEP2=$(gum style --border normal --padding '0 2' 'Process')
END=$(gum style --border rounded --padding '0 2' 'End')

gum join --horizontal "$START" " ──▶ " "$STEP1" " ──▶ " "$STEP2" " ──▶ " "$END"
```

For vertical branches, print nodes with arrow lines between them:

```bash
echo "$STEP2"
echo "        │"
echo "        ▼"
echo "$(gum style --border normal --padding '0 2' 'Alt Path')"
```

- Start/end nodes: `--border rounded`
- Process nodes: `--border normal`
- Decision nodes: `--border double`
- Arrows: `──▶` horizontal, `│` + `▼` vertical

### 2. Sequence Diagram

```
  Client          API           Database
    │               │               │
    │──── GET /users ────▶│               │
    │               │──── SELECT * ──▶│
    │               │◀──── rows ──────│
    │◀── 200 JSON ──│               │
    │               │               │
```

- Participant names centered above lifelines
- Lifelines are vertical `│`
- Messages are horizontal `────▶` and `◀────`
- Return messages use dashed `╌╌╌▶`
- Self-calls loop back with `┐│┘`

### 3. Tree / Hierarchy

```
  project/
  ├── src/
  │   ├── components/
  │   │   ├── Button.tsx
  │   │   └── Modal.tsx
  │   ├── hooks/
  │   │   └── useAuth.ts
  │   └── utils/
  │       └── format.ts
  ├── tests/
  └── package.json
```

- Use `├──` for branches, `└──` for last item
- Use `│   ` for continuation lines
- Directories end with `/`

### 4. Table / Comparison

Always use `gum table --print` — never hand-draw table borders:

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_table "Feature,REST,GraphQL,gRPC" \
  "Speed,Fast,Medium,Fastest" \
  "Complexity,Low,High,Medium" \
  "Caching,Native,Manual,None"
```

- First row is the header — gum handles separator rendering automatically
- Column widths auto-fit to content
- Use `gum_table --sep $'\t'` if cell values contain commas

### 5. State Machine

Use `gum style --border` per state, connect with arrow lines:

```bash
source ~/.claude/skills/shared/gum-tui.sh

IDLE=$(gum style --border rounded --padding '0 2' 'Idle')
LOADING=$(gum style --border normal --padding '0 2' 'Loading')
SUCCESS=$(gum style --border normal --padding '0 2' 'Success')
ERROR=$(gum style --border double --padding '0 2' 'Error')

# Main path (horizontal)
gum join --horizontal "$IDLE" " ──▶ " "$LOADING" " ──▶ " "$SUCCESS"
# Error branch (below loading — hand-craft the vertical arrow)
echo "                │"
echo "                ▼"
echo "$ERROR"
```

- Initial state: `--border rounded`
- Normal states: `--border normal`
- Error/terminal states: `--border double`
- Transition labels: plain text between gum-joined elements

### 6. Architecture / Layer Diagram

Use `gum style --border double` for layer containers, `gum style --border rounded` for
inner components, and `gum join --horizontal` to arrange components side by side:

```bash
source ~/.claude/skills/shared/gum-tui.sh

# Inner component boxes
REACT=$(gum style --border rounded --padding '0 1' 'React')
REDUX=$(gum style --border rounded --padding '0 1' 'Redux')
ROUTER=$(gum style --border rounded --padding '0 1' 'Router')

# Components row
COMP_ROW=$(gum join --horizontal "$REACT" "  " "$REDUX" "  " "$ROUTER")

# Layer container
FRONTEND=$(gum style --border double --padding '0 2' --width 56 \
  "$(gum style --bold --foreground 4 'Frontend')" "$COMP_ROW")
echo "$FRONTEND"
echo "                     │ REST API"
echo "                     ▼"

EXPRESS=$(gum style --border rounded --padding '0 1' 'Express')
AUTH=$(gum style --border rounded --padding '0 1' 'Auth')
BE_ROW=$(gum join --horizontal "$EXPRESS" "  " "$AUTH")
BACKEND=$(gum style --border double --padding '0 2' --width 56 \
  "$(gum style --bold --foreground 4 'Backend')" "$BE_ROW")
echo "$BACKEND"
echo "       │                              │"
echo "       ▼                              ▼"
gum join --horizontal \
  "$(gum style --border normal --padding '0 2' 'PostgreSQL')" \
  "          " \
  "$(gum style --border normal --padding '0 2' 'Redis')"
```

- Layer containers: `--border double`
- Inner components: `--border rounded`
- External/data services: `--border normal`
- Connections between layers: hand-crafted arrow lines between gum blocks

## Proactive Use Guidelines

When Claude is explaining architecture, data flows, state machines, request lifecycles, directory structures, or decision processes, it SHOULD proactively include a diagram **without being asked**, alongside the text explanation. The diagram should:

1. Come BEFORE the text explanation (visual first, then details)
2. Be executed via the Bash tool (not output as inline text) so gum renders it properly
3. For inline explanations where Bash isn't appropriate: use a markdown code block with hand-crafted Unicode connectors and tree chars only — no boxes
4. Include a brief title line above the diagram

Do NOT use diagrams for:
- Simple linear lists (use bullet points)
- Single function explanations
- Configuration examples
- Error messages

## Graph-Easy Fallback

If `graph-easy` is installed (`command -v graph-easy`), complex graph layouts can be delegated to it:

```bash
echo "[Start] -> [Process] -> [End]" | graph-easy --as=boxart
```

Check availability silently. If not installed, use gum-tui.sh (the primary path). Do not suggest installing graph-easy.
