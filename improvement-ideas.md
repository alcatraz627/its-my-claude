# Claude Improvement Ideas

Broadly applicable insights from sessions — not project-specific.

---

## 2026-04-17 — Build hash strategy for compiled widget/binary staleness detection

**Context:** i-dream menubar widget fix was committed but binary not rebuilt; user saw persistent truncation bug for 24h+ because the running binary predated the source fix by 5 minutes.

**Strategy:** For any project with a compiled binary (Swift, Rust, C, Go) that is separately deployed from its source:

1. **Embed build hash at compile time** — generate a `build-info.swift` (or equivalent) with `commitHash`, `sourceHash` (md5 of source), and `builtAt` timestamp. Compile it alongside the main source. The binary now carries its own provenance.

2. **Write a `.build-info` sidecar** — after every successful compile, write `commit=`, `src_hash=`, `built_at=` to a plain text file next to the binary. `.gitignore` both the generated swift file and the sidecar.

3. **Expose in `--status`** — the build/management script's `--status` command reads `.build-info`, computes current source hash, and warns with `⚠ SOURCE HAS CHANGED — binary is stale!` if they diverge.

4. **Expose in running binary** — log build hash at startup and show in tooltip/status so you can cross-check what version is actually live without stopping the process.

**When to apply:** Any project where "edit source → commit → done" leaves a stale binary running. Especially relevant for: macOS menubar widgets (Swift), background daemons (Rust/Go), CLI tools installed to PATH. Check binary mtime vs commit mtime — if binary is older, rebuild.

---

## 2026-04-11 — Claude Bash tool uses `zsh -f`; only `settings.json` env fixes PATH

**Context:** Session debugging `! ls` → "command not found" in Claude CLI.

Claude Code's Bash tool invokes commands as `zsh -f -c "eval 'cmd'"`. The `-f` flag
(fast mode) bypasses ALL zsh rc files including `.zshenv`, `.zshrc`, `.zprofile`. This
means:
- PATH seen by the Bash tool = exactly what Claude's own process has at startup
- `.zshenv` fixes, `path_helper`, `brew shellenv` — none help at runtime
- **The only effective fix**: add `"PATH"` to `settings.json` `env` section

When PATH is broken and you need to diagnose: use `/usr/bin/python3` (absolute path,
side-steps PATH entirely) with `os.environ` + `repr()` to inspect the exact bytes of env vars.

---

## 2026-04-10 — Consolidate repeated subprocess forks in daemon loops

When a bash daemon loop calls `$(date +%s)` (or any other pure function) multiple times per iteration, each call forks a subprocess (~2-5ms). Consolidating into a single `_NOW=$(date +%s)` at loop top and reusing `$_NOW` throughout eliminates N-1 forks per cycle. In a 4s-interval loop with 9 date calls, this saves ~40ms/cycle — small individually but compounds over hours. Same principle applies to any idempotent-within-iteration shell command: `whoami`, `hostname`, `uname`, etc. Always hoist to loop top.

## 2026-04-10 — Gate expensive periodic operations with timestamp files

For daemon background tasks that run expensive operations (e.g., `find . -maxdepth 4` scanning thousands of files), use a simple timestamp file to enforce a cadence longer than the main loop interval. Pattern: write `$_NOW` to a cadence file after each run, check `(( _NOW - last_ts < CADENCE ))` before running. This is simpler and more reliable than modulo-based counters (which reset on daemon restart) and doesn't require tracking iteration counts. The timestamp file naturally survives daemon restarts and can be deleted to force an immediate re-run.

## 2026-04-10 — NVM `--no-use` + `nvm use` alias is the optimal NVM startup trade-off

NVM's `nvm_auto` function (scans `.nvmrc`, switches versions) consumes 400ms+ per shell start — typically 60%+ of total startup. Using `--no-use` loads NVM's functions without the auto-switch, saving that time entirely. Node is still available via homebrew or system PATH. Adding a short alias (`nv` → `nvm use`) makes on-demand version switching frictionless. The lazy-load pattern (`nvm() { unset -f nvm; source nvm.sh; nvm "$@"; }`) is even faster but loses tab-completion for nvm subcommands until first invocation. `--no-use` is the better trade-off for most users.

## 2026-04-10 — Double-sourcing detection: `[[ -o login ]]` guard in .zshrc

When `.zshrc` sources `.zprofile` for compatibility with non-login shells (e.g., VS Code integrated terminal), it causes double-loading in login shells (Ghostty, iTerm2, SSH) where `.zprofile` is already sourced by zsh before `.zshrc`. The fix is `[[ -o login ]] || source ~/.zprofile` — the `-o login` option is set by zsh in login shells. This eliminates redundant NVM/pyenv/brew initialization that can add 400ms+ to startup. This pattern applies to any "ensure loaded once" scenario across shell config files.

---

## 2026-04-09 — Commented-out activation line pattern is hard to distinguish from "feature disabled"

When a variable is hardcoded to a safe default (`use_icons=0`) and the config-driven activation line is commented out, future agents (and humans) read `use_icons=0` and conclude icons are unsupported — not just unconfigured. Prefer an explicit inline comment: `use_icons=0  # set by seg_icons config below` to make the two-step initialization contract visible. Applies broadly to any feature flag with a separate activation source.

## 2026-04-09 — bash statusline: nested JSON required for smoke tests

statusline.sh uses jq with deeply nested paths (`.workspace.current_dir`, `.model.display_name`, `.rate_limits.five_hour.used_percentage`). Flat test JSON silently routes to `glow` for Markdown rendering, which outputs "glow version 2.0.0" — a misleading non-error. Always use the nested structure matching the actual jq extraction block when testing.

## 2026-04-09 — macOS daemon context: command availability & write restrictions

- **macOS pm2 daemon has a stripped PATH**: `lsof`, `curl`, `sleep`, `mkdir`, `head`, `tail`, `npm`, `npx` are all unavailable without setting `PATH=/opt/homebrew/bin:/usr/local/bin:/bin:/usr/bin` explicitly. Use absolute paths (`/usr/sbin/lsof`, `/usr/bin/crontab`) or set env when spawning children.
- **`crontab` writes hang in daemon context**: macOS blocks `crontab -` stdin writes and `crontab <file>` from non-GUI sessions. Read (`crontab -l`) works fine. Root cause: security framework requires GUI session for write authorization. Workaround: store the intended state in an app-managed JSON config and overlay it on top of `crontab -l` reads.
- **pm2 restart race → EADDRINUSE**: pm2 `restart` doesn't guarantee the old process releases its port before the new one starts. Pattern: find PID via `/usr/sbin/lsof -i tcp:<port>`, kill it, then `pm2 delete <name>` + `pm2 start` for a clean cycle.
- **3-pass code review loop yields diminishing returns intentionally**: Round 1 finds test/selector bugs, Round 2 finds security/dead-code/cleanup issues, Round 3 finds edge cases in newly written code. Each reviewer prompt should narrow to what was just changed, not re-review everything.

## 2026-04-08 — "Footer row" via last group in priority-ordered drop system

When a layout system drops groups from a priority-ordered list (highest→lowest), appending a new group at the very end automatically gives it "footer row" behavior: it renders last and is the first to be dropped on overflow. No special layout code needed. This pattern applies to any priority-trimmed rendering system (status bars, dashboards, terminal UIs).

## 2026-04-08 — Avoid displaying numeric values that collide with test string checks

Test assertions like `"200K" not in output` will break if any segment starts displaying "200K" as data (e.g., context window size = 200K tokens). Use distinct formats for display — `↑85K` instead of `85K/200K` — to keep "200K" as a unique marker for the warning condition. Applies generally: reserve "sentinel strings" in test assertions for one meaning only.

## 2026-04-07 — Variable shadowing in single-function request handlers

When a Node.js `handleRequest(req, res)` function declares `const path = urlObj.pathname`, it shadows `const path = require('path')` at module scope. Any route handler that later calls `path.join()` silently fails (calls undefined method on a string). `node -c` syntax check passes fine — only runtime testing catches it. **Mitigation**: in monolithic request handlers, either rename the local variable (e.g., `pathname`) or use `require('path')` inline inside route bodies that need filesystem operations.

---

## 2026-04-06 — create-report table cell escaping + pixel art SVG lessons

- **`renderTable()` in create-report `esc()`-escapes all table cell content.** This means `<code>`, `<strong>`, and `<a href>` tags in table cell JSON data render as literal text like `<code>npm run dev</code>`. Tables expect **plain text only** in the data JSON. Meanwhile, `paragraph.html`, `ul.items`, `ol.items`, and `blockquote.html` pass through raw HTML. Know which block type you're targeting before deciding whether to include HTML markup.
- **macOS `cp` is aliased to `cp -i` (interactive)** in many shells, which blocks in non-interactive contexts with "overwrite? (y/n)" prompt that silently fails. Workaround: use `cat source > target` (shell redirect bypasses the alias) or `/bin/cp -f`.
- **Pixel art SVG technique**: use small viewBox (256x128) displayed at 2x (512x256) with `shape-rendering="crispEdges"` for blocky retro aesthetics. Opacity on same fill color (0.1-0.9) creates depth cheaper than adding colors. Dithering (alternating opacity at edges) simulates gradients.

---

## 2026-04-06 — macOS bash 3.2 compatibility & self-referential sync

- **Always assume bash 3.2 on macOS** — avoid `${var,,}`, `$BASHPID`, `declare -A`, `|&`. Use `tr`, `$$` with `bash -c` wrapper, regular arrays, and `2>&1 |` respectively. This session hit the same bash 3.2 issue _twice_ in different scripts.
- **Secret scan regex needs `\b` word boundaries** — patterns like `sk-` match mid-word ("task-specific") without them. Production scanners use token entropy + prefix matching.
- **Scripts that sync files should sync themselves** — the sync-config.sh drift between source-of-truth and repo copy went unnoticed for days because the script didn't include itself in its own file list.
- **PPID is readonly in bash** — cannot override with `VAR=val cmd`. For testing scripts that read `$PPID`, use `bash -c '...'` wrapper where `$$` naturally becomes the child's `$PPID`.
- **Dry-run before destructive operations** catches issues like false-positive secret scans before they block real commits.

---

## 2026-04-06 — MCP elicitation for structured user input

- **Reading SDK `.d.ts` files directly** is faster and more precise than searching docs for API shapes. The type definitions at `spec.types.d.ts` had the exact schema structures, field names, and response types.
- **Titled enums** (`oneOf: [{const, title}]`) are significantly better UX than bare `enum: []` — they let you show a display label alongside the value. The SDK also supports titled multi-select via `items.anyOf`.
- **Multi-select uses `type: "array"`** not `type: "string"` with some flag — the schema type changes entirely for multi-select vs single-select enums.
- **`elicitInput()` lives on the low-level `Server`**, not on `McpServer` — access via `mcpServer.server.elicitInput()`. Easy to miss since you register tools on `McpServer`.
- **MCP servers for tool extension** is the only way to add genuinely new callable tools to Claude Code. Skills orchestrate existing tools; hooks react to events; only MCP servers create new tools.

---

## 2026-04-06 — impr-repo-4c

- **Always use function replacers for `String.replace()` when the replacement comes from file content.** String replacers interpret `$&`, `$'`, `` $` ``, `$1`-`$9` as backreferences. JS source code containing `"\\$&"` (a common regex-escape pattern) gets silently corrupted. Fix: `str.replace(pattern, () => replacement)`.
- **Check escaping symmetry in HTML rendering:** When a function escapes headers but not body cells (or vice versa), it creates an XSS vector that's invisible in normal testing. Audit both sides of any template construct.
- **`initThemeToggle`'s `defaultTheme` param means "the state when no CSS class is applied"**, not "the initial visual appearance." For a light-default template, set `defaultTheme: "dark"` with `darkClass: "dark"` — counterintuitive but correct because "dark" is the base (no-class) state that presents as light visually.
- **Three-layer mistake learning system**: (1) `check-human-comments.sh` PreToolUse hook warns when editing files with `NOTE(by human)` markers, (2) `~/.claude/mistake-patterns.md` indexes recurring mistake categories (max 20, pattern-level not incident-level), (3) CLAUDE.md "After User Corrections" ritual: state mistake → identify pattern → update patterns file → check if hook can prevent → fix. This externalizes learning so future agents benefit without needing the incident history in context.
- **Batch verification kills secondary changes**: When making N changes in one edit, the primary change gets verified via screenshot/test, but "while I'm here" additions get zero dedicated verification. Rule: N changes = N verification steps. Each distinct change needs its own before/after check.
- **Number heuristics are not visual verification**: Don't judge if a CSS value is "wrong" by comparing to typical ranges. `line-height: 0.25` on `display: block` elements with their own padding doesn't behave like 0.25 on inline text. Render first, judge second.

---

## 2026-04-06 — mcp-disbl-4e (MCP file-tools build)

1. **Output envelope pattern for MCP tools:** When building MCP tools that return data, let the caller control context cost via parameters (limit, offset, columns, sample, format, max_chars). The model can start cheap (format:"summary") and progressively drill in. This avoids the "50k rows in context" problem entirely.
2. **Read-Write pipeline for format conversion:** Instead of N×M converter functions, build N readers + M writers and pipe through a JS intermediate. Any readable format converts to any writable format automatically. The bridge: structured arrays can be treated as tabular rows.
3. **ESM + require() trap:** In ESM modules ("type": "module" in package.json), `require()` silently fails or throws confusing errors. Caught this in `detect.js` (readHead) and `envelope.js` (buildMetaHeader). Always use static imports or dynamic `await import()` in ESM.
4. **Global MCP servers for cross-project utility:** If an MCP server is broadly useful (file I/O, HTTP), add it to `~/.claude.json` not just the project's `.mcp.json`. Combined with CLAUDE.md guidance, agents reach for it naturally instead of reinventing parsing per-session.

---

## 2026-04-06 — impro-core-8a (visual alignment fix)

5. **Unicode horizontal box-drawing characters (`═` U+2550, `─` U+2500) render narrower than standard glyphs in many terminal fonts.** Over 60+ repetitions, the cumulative sub-pixel drift visibly misaligns right borders. C `wcwidth()` reports them as 1-wide (correct at the cell level), but the font's glyph advance width is slightly less than 1 em. Fix: use ASCII `=` and `-` for horizontal fills. Unicode corners and verticals (`╔╗╚╝╠╣║`) are safe since they don't accumulate. Individual Geometric Shapes (`◆◇▶△◎`) and most Math Operators (`⊕⊙`) are also safe. Exception: `⊞` (U+229E) and `⊶` (U+22B6) render wider in some fonts — avoid them.

---

## 2026-04-06 — impro-core-8a

1. **Edit tool + Unicode box-drawing:** When editing near Unicode-heavy content (box-drawing chars like `─`, `┌`, `│`), the old_string match can fail due to encoding differences. Workaround: use Grep to locate the exact line, then Read with offset to get the precise text before editing.
2. **Two-layer guard removal:** When removing a restriction (e.g., "auto-only" guard), check both the configuration layer (settings.json matcher) AND the implementation layer (shell script internal checks). Missing one leaves the restriction partially in place.
3. **Section numbering after insertions:** When inserting a new numbered section mid-document (e.g., adding §2.5 between §2.4 and §2.5), always verify the entire numbering sequence afterward — gaps or duplicates are easy to miss.
4. **Sub-agent context isolation is architectural:** `context: fork` means sub-agents start blank. Any skill that needs to synthesize the current conversation cannot delegate to sub-agents. This is a fundamental constraint, not a bug to work around.

---

## 2026-04-06 — impro-core-8a (library extraction + formalization)

5. **Extract-from-working-code beats design-first for utility libraries.** Starting with a working inline implementation (core-dump's visual builder) and extracting into `banner.py` produced a better API than designing the library from scratch would have. Real-world constraints (alignment at W=68, theme variations, section patterns) drove the API design naturally.
6. **Shared library formalization has 3 layers: package, docs, discoverability.** Making utilities work (`__init__.py`, tests) is necessary but not sufficient. Agents also need: (a) documentation at point-of-import (`README.md`), (b) session-start discoverability (`CLAUDE.md` section), and (c) mandatory convention (`GUIDELINES.md` section). Missing any layer means the library exists but doesn't get used.

---

## 2026-04-06 — catch-read-a6 (premature commit lesson)

- **"Do not push" means "no git operations at all"** — not "commit but don't push." Users think in terms of "persist to remote" vs "keep local." When they say "don't push," they mean "I want this to stay as working-tree changes." Only commit when the user explicitly says "commit." This is already in CLAUDE.md but easy to override with conventional dev workflow assumptions.
- **Inline SVGs don't render on GitHub** — the sanitizer strips `<svg>` tags for security. Save as `.svg` file and reference via `<img src="...">`. But note: `<a xlink:href>` links inside the SVG also don't work when embedded via `<img>` — the browser treats it as an isolated rendering context. Clickable links must live in the surrounding markdown.

---

  ## 2026-04-17 — Browser automation via JXA tab.execute                          
                                                                                  
  • **JXA **tab.execute({javascript: ...})** beats visual screenshots for web     
  text** — reads any Chrome tab's DOM without requiring the window to be visible  
  or frontmost. Python json.dumps(js_code) for safe embedding avoids all          
  quoting/heredoc issues.                                                         
  • ytd-compact-video-renderer** fails for YouTube** (shadow DOM) — use #secondary-
  inner a[href*="watch"] + deduplication by href as the universal YouTube sidebar 
  selector.                                                                       
  • **Chrome window index stability**: after chrome.windows[N].index = 1, all     
  indices shift. Always re-enumerate post any index assignment. Sequence for safe 
  bring-to-front: chrome.activate() → windows[N].index = 1 → capture within 500ms.
  • **AppleScript vs JXA for Chrome**: AppleScript count windows returns only 1   
  (frontmost). JXA chrome.windows.length returns all. Always use JXA for any multi-
  window Chrome work.                                                             


  ## 2026-05-04 — five gotchas from a 19-feature shipping session             
                                                                              
  **Bash **<script>** strips aliases AND functions, even within the same shell
  session.** A subprocess inherits exported env (PATH, HOME, etc.) but no     
  shell-state aliases or functions. If a binary you use is a self-referencing 
  alias (e.g. alias claude='claude --allow-dangerously-skip-permissions'),    
  scripts                                                                     
  that call claude directly will fail to find it via command -v. Defensive    
  multi-path search across known install locations beats env-debugging — bake 
  a                                                                           
  5-path fallback list into any cron/launchd shell script that needs claude.  
                                                                              
  launchctl load** is in Claude Code's "always-prompt" permission category.** 
  Three forms (compound + simple + absolute path) all denied. Pivot fast to ! 
  launchctl load … for inline user execution rather than trying variants. Same
  likely applies to crontab -e, defaults write, anything that touches macOS   
  launchd / loginitems / plist registrations.                                 
                                                                              
  **Format-string brace pitfall in Rust.** Inside a format!() body, every { is
  interpreted as a placeholder anchor. JS comments containing { name:         
  viewObject, ... } will compile-error. Fix: {{ ... }} everywhere a literal   
  brace is needed. This recurs whenever embedding JS/TS objects in Rust       
  template strings.                                                           
                                                                              
  #[serde(default)]** only helps the wire format, not the source-code         
  initializer.** Adding a field to a struct with #[serde(default)] lets legacy
  on-disk data deserialize cleanly, but every Rust struct-literal site        
  (production AND test fixtures) must still specify the new field. Plan for at
  least 2-3 cascade fixes after any schema addition.                          
                                                                              
  grep** aliased to **ugrep** is a silent papercut on power-user macOS        
  setups.** Verification commands using grep will fail with "no PATTERN       
  specified". When asking a user to run a verification one-liner, default to  
  /usr/bin/grep to bypass any aliases. Especially relevant for "paste this    
  command" interactions.                                                      

---

## 2026-05-05 — `/create-skill` should auto-inject anti-pattern callouts for audit/summary skills

**Context:** While building `/summarize-changes`, v1 silently defaulted to git as the only source for "changes" — exactly the lazy framing the user explicitly didn't want. The fix in v2 was a four-rule "Load-bearing anti-patterns" block at the top of the SKILL.md (commits-as-signals-not-boundaries, never-paraphrase-subjects, don't-ignore-ambient-signals, ASK-on-conflict). Without that block, a future maintainer (or future Claude) re-running the skill could easily slide back into the same default.

**Idea:** When `/create-skill` detects that the skill being authored is in the audit / summary / review / look-back category (heuristics: description contains words like "summarize", "audit", "review", "changelog", "history", "activity", "recap"), the wizard should prompt for "what conventional defaults must this skill explicitly avoid?" and inject the answers as a numbered anti-pattern callout block immediately after `## Brief`. Each callout should reference the phase that enforces it.

**Also:** `/create-skill` should optionally generate a starter `## Validation Examples` block with 3–5 placeholder scenarios when the category is summary/audit/review — gives `/improve-skill` something concrete to score against from day one rather than auto-generating vibes-based examples on first improvement.

**Promotion path:** if 2+ more sessions fall into the same trap (defaulting to convention when authoring around a domain noun), promote the heuristic into a hard requirement in `~/.claude/skills/create-skill/SKILL.md`'s Phase 4 (constraints).

## 2026-05-05 — Three-axis input decomposition is a reusable structural pattern

**Context:** `/summarize-changes` v1 had a flat 8-option scope picker that conflated time-axis (when), source-axis (which artifacts), and shape-axis (worktree vs index vs branch). The redesign split into three orthogonal pick steps — Time / Topic / Source — and the resulting structure was visibly cleaner. Source became multi-pick rather than single-pick, which captured the "WAL + git + checkpoints" use case naturally.

**Idea:** Add a section to `~/.claude/skills/create-skill/SKILL.md` (or a sub-doc it references) describing the orthogonal-axes pattern as a default for any skill with >2 input dimensions. Include the heuristic: if a single picker is generating > 6 options OR if some options are mutually exclusive while others compose, you have multiple axes hiding inside one picker — decompose them.


                                                                              
  --------                                                                    
                                                                              
  ## 2026-05-14 — Prompt design with structured-goals → N-subagent generation 
  →                                                                           
  voting + independent pick                                                   
                                                                              
  **Context:** Designing a non-trivial prompt (e.g. an LLM-call within a      
  pipeline) where small differences in framing materially change output       
  quality. Single-Claude prompt-design is anchored on whatever the first draft
  looks like; no diversity in approach.                                       
                                                                              
  **Workflow:**                                                               
                                                                              
  1. **Write a META-PROMPT first**, not the prompt itself. The meta-prompt    
  specifies:                                                                  
      • **Goal** of the eventual prompt (what the LLM should produce — domain,
      tone, themes)                                                           
      • **Flow** the eventual prompt should follow (sections, ordering,       
      structure)                                                              
      • **Argument-interpretation layer** — how the eventual prompt's runtime 
      args (e.g. content_length, style_hint) should shape its output          
      • **Randomization vector** — a list of variations the eventual prompt   
      can pick from (e.g. "as a joke, as a newspaper article, as a dialogue") 
      so identical args give varied outputs                                   
      • **Anti-goals** — what to avoid (e.g. "too nerdy, too obscure, drift   
      into thesaurus territory")                                              
  2. **Dispatch the meta-prompt to N subagents in parallel** (recommend N=5). 
  Each writes its own version of the eventual prompt based on the meta-prompt.
  Persist every version to disk (per sub-agent-outputs rule).                 
  3. **Show outputs to the user.** Let them see all N before voting.          
  4. **Re-dispatch the N subagents in a voting round.** Each receives all N   
  outputs and votes for the best one (with a one-line reason). Persist vote   
  tallies.                                                                    
  5. **Independently form your own opinion.** Read all N outputs yourself.    
  Pick the best. Don't peek at the votes first — independent judgment.        
  6. **Present both picks side-by-side.** Subagent winner + your winner. If   
  they match: confirm and explain why. If they don't: explain the gap — what  
  the subagents valued vs what you valued. The user makes the final call with 
  both signals in front of them.                                              
                                                                              
  **Why this works:**                                                         
                                                                              
  • **N=5 generates real diversity** — different framings, different          
  priorities. Single-Claude exploration converges; parallel exploration       
  diverges.                                                                   
  • **Voting catches non-obvious losers** — a prompt that looks good in       
  isolation may have a flaw 4 of 5 subagents notice but the original author   
  didn't.                                                                     
  • **Independent pick is the consistency check** — if subagent vote and      
  independent pick disagree, the disagreement is the interesting signal.      
  Usually one side weighs aesthetics differently than the other.              
  • **Persist everything** — the meta-prompt, the N outputs, the votes, both  
  picks. Lets the user compare reasoning later, and lets future runs of this  
  workflow improve the meta-prompt.                                           
                                                                              
  **When to use:**                                                            
                                                                              
  • Any LLM-call inside a product (where prompt quality is load-bearing)      
  • Any "design the system prompt" task for an agent                          
  • Any creative-writing task where style variation matters                   
  • NOT for code-gen prompts (those have a clearer correctness signal)        
                                                                              
  **When NOT to use:**                                                        
                                                                              
  • Simple prompts where one draft is obviously sufficient                    
  • Time-sensitive tasks — this workflow takes 10-15 minutes minimum          
  • Prompts where the design space is narrow (a one-shot extraction prompt)   
                                                                              
  **Concrete first run scheduled:** 2026-05-19 (Tuesday 11:30 AM) — philosophy
  poem/prose prompt for the mock pipeline method, themed                      
  Hegel/Spinoza/Wittgenstein/Orwell/Heidegger/Hume/Locke. LaunchAgent at      
  ~/Library/LaunchAgents/com.alcatraz.philosophy-prompt-tuesday.plist fires   
  the                                                                         
  session and self-cleans.                                                    


  ## 2026-05-25 — cred-rgate-b8 (hook hygiene + atone tooling)                
                                                                              
  • **Disabling a hook is a two-edit operation:** the script AND its settings.
  json registration. Renaming the script alone (e.g. *.disabled-by-claude)    
  while a *synchronous* Stop/PreToolUse registration still points at it makes 
  every invocation emit exit 127 / No such file or directory — strictly worse 
  than leaving the hook on. Always: drop the registration in the same change, 
  then smoke-test (echo '{"hook_event_name":"Stop"}' | sh -c '<registered-    
  path>' → expect exit 0).                                                    
  • **A "too noisy / too aggressive" complaint = tune down, not turn off.**   
  Apply the smallest trigger change and stop unless the user explicitly says  
  remove. Reassurance ("I generally trust claude") is not a removal mandate.  
  (S3 atone over-corrected-tuning-request-into-disable.)                      
  • atone.sh add --rca-content "$(cat file)"** mangles leading whitespace**   
  (fails its own rca-lint with "N% leading whitespace"). Use --rca-file PATH  
  instead — it cats inside the CLI and passes. (prop-20260525-132203-b4.)     
  • **atone juror gate cuts both ways:** it prevented a *false* self-atone    
  (the Anthropic-key incident wasn't this session's action — verified zero key-
  assignment sites) and confirmed a *real* S3. Don't reflexively self-atone   
  for an angry-user incident you didn't cause; verify involvement first.      


## 2026-05-28 — Hook scripts created via Write lack `+x`

When a hook script is created via the Write tool and wired into `settings.json` as a bare `command` (no `bash` prefix), the OS execs it directly and fails with `Permission denied` because Write produces mode 644. Result: the hook never runs and spams non-blocking errors on every matching tool call. Worse, if the hook IS a guardrail (like `guard-anthropic-credentials.sh`), the protection is silently advisory.

**Apply:** when creating any hook script, immediately `chmod +x` it AND `git add` it in the same step so the executable bit survives across machines. Sister pattern to `rules/skill-spec-update-not-honored-by-running-session.md` — a spec/wiring change without a data-path-level enforcement check is advisory-only. Consider a pre-commit or PreToolUse hook that flags new files under `scripts/hooks/` lacking +x.

  ## 2026-05-31 — Heredoc strips Swift \(...) interpolation even with single- 
  quoted delimiter                                                            
                                                                              
  Tried writing a Swift test to /tmp/sysmon-fmt-check.swift with              
  cat > file <<'SWIFT' ... SWIFT. Per POSIX, single-quoted heredoc            
  delimiter should suppress all expansions and preserve backslashes           
  literally. In this shell environment (zsh, macOS), the backslashes in       
  Swift string interpolation \(name) were stripped — the file landed with     
  literal (name) text, producing useless output on swift run.                 
                                                                              
  **Lesson:** for any file with shell-meta sequences (\(, $(, backslash       
  escapes), use the Write tool directly instead of heredoc. The Write tool    
  treats the content as opaque bytes; heredoc does not, even with             
  single-quoted delimiter in some shells.                                     
                                                                              
  **Diagnostic:** the Swift compiler warned immutable value 'label' was       
  never used — symptom of \(label) becoming the bare token (label)            
  after the backslash was eaten.                                              


  ## 2026-05-31 — audit-recon-7c (migration git/perms hardening)              
                                                                              
  • **The migration exec-bit trap:** rsync -a preserves file modes but git    
  clone/git pull restores the *committed* mode. A chmod +x applied on disk but
  never committed survives a file-copy migration yet dies on the next         
  clone/pull — silently re-breaking a bare-path hook. Fix: when               
  creating/fixing a hook, stage the mode (git add after chmod, or git update- 
  index --chmod=+x) and verify git ls-files -s shows 100755. Verify origin's  
  mode with git ls-tree origin/main <path>.                                   
  • **Verify a merge by diffing back, not by absence of conflict markers.** A 
  clean 3-way merge with no markers can still silently drop content when a    
  "take theirs" policy hits a curated file both sides grew. After merging, git
  diff <local-snapshot>..<merged> -- ':!<daemon-state>' and eyeball the       
  removals. Superset check (+N/-0) tells you take-local is lossless.          
  • permissions.deny** substring globs are read-blocking tyranny.** Bash(*    
  /dev*) blocks ANY command containing  /dev — reads, args, even an           
  echo/commit-message mention. Prefer a precise PreToolUse hook that matches  
  write *forms* (> >> tee dd rm chmod/chown -R) and de-quotes the command     
  first so paths inside string literals aren't matched.                       
  • **Cache split:** permissions.deny is read at session-start (cached; edits 
  apply next session) but PreToolUse **hook scripts are re-read per tool      
  call** (edits apply immediately). Removing a deny rule won't help the       
  current session; a new/edited hook will.                                    
  • **Stop-hook **decision:block** is the only server-independent, no-        
  injection way to auto-continue a TUI.** Bare Ghostty + no tmux + macOS      
  removing TIOCSTI = external input injection is impossible. A per-session opt-
  in Stop hook with a consecutive-error streak cap (resets on clean turn)     
  gives safe error-recovery without keystroke automation.                     

