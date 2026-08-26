## Brief

Thin dispatcher for the statusline CLI. Runs shell scripts directly — minimal LLM overhead.
Claude's only role is routing the command and, for `audit --claude`, summarizing findings.

**0-LLM path (preferred):** Add to `.zshrc` and bypass Claude entirely:
```bash
statusline() { bash ~/.claude/scripts/statusline/sl-cli.sh "$@"; }
```

---

## Usage

```
/statusline <config|explain|audit> [args...]
```

| Subcommand   | Description                                               |
| ------------ | --------------------------------------------------------- |
| `config`     | Show active profile — all segment on/off/auto values      |
| `explain`    | Widget reference: what each widget shows, when it fires   |
| `audit`      | Audit config for issues; optionally invoke Claude analysis|
| `playground` | Playground server — status, start, stop, open             |
| `open`       | Open a statusline file in editor or browser               |

**config options:**
- `--profile <name>` — use a specific profile (default: `$STATUSLINE_PROFILE` or `custom`)
- `--raw` — raw key=value output

**explain filter:**
- `L1` / `L2` / `L3` / `L4` — show only widgets on that line
- `<widget-name>` — show only matching widget (partial match)

**audit options:**
- `--profile <name>` — audit a specific profile
- `--claude` — append structured output for Claude to analyze

**playground actions:**
- `start` — print start instructions (server must be launched by user)
- `open` — open in browser (live server) or static HTML fallback
- `stop` — kill process on port 5081
- (no arg) — show server status + start instructions

**open targets:**
- `sh` — statusline.sh (main render script)
- `conf` — statusline.conf (segment settings)
- `skill` — this SKILL.md
- `playground` — statusline-playground.html
- `dev-guide` — statusline-dev-guide.md
- `widget-ref` — latest widget reference HTML
- `audit`, `cli` — the audit/dispatcher scripts
- (no arg) — list all targets

---

## Execution

### Step 1 — Parse the subcommand

Read the first token from ARGUMENTS. Everything after it is forwarded as-is to the script.

### Step 2 — Run the script

Run the script via Bash tool. Print the **exact output** — no summarizing, no reformatting.

```bash
bash ~/.claude/scripts/statusline/sl-cli.sh <subcommand> [forwarded-args]
```

### Step 3 — Post-processing

**config / explain:** Print output verbatim. Done. Do not add commentary unless the user asks a follow-up question.

**audit (without `--claude`):** Print output verbatim. Done.

**audit (with `--claude` flag OR user asks for analysis):**
Run: `bash ~/.claude/scripts/statusline/sl-cli.sh audit --claude [other-args]`

When the output contains `---CLAUDE_ANALYSIS_REQUEST---`, analyze the findings:
1. Summary line: `N pass, N warn, N fail`
2. For each warning/failure — root cause + specific fix
3. If all pass — confirm healthy + any optional improvements

Keep the analysis concise. Use a bullet per issue. Do not repeat the raw audit output.

---

## Notes

- Do NOT modify statusline.sh or statusline.conf during this skill — this skill is read-only
- Never truncate or paraphrase script output — print it exactly
- If the user asks for fixes, explain what to change and let them confirm before editing
- For anything beyond display (editing segments, changing config), the user should use the main statusline improvement workflow
