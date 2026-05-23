## dev-env: VS Code + uv Python setup for backend — 2026-02-25

**Purpose:** Fix VS Code Pylance import resolution, interpreter selection, and pytest discovery for a monorepo where Python lives in `backend/` and is managed by uv.

**Insights:**

1. macOS quarantines uv-managed Python binaries — the `@` in `ls -la` output signals extended attributes. Running the binary gets SIGKILL immediately. Fix: `xattr -dr com.apple.quarantine /Users/alcatraz627/.local/share/uv/python/cpython-3.13.1-macos-aarch64-none/` (recursive on the whole installation dir, not just the binary).
2. VS Code's "Unable to handle <uv-path>" error when selecting a Python interpreter is caused by symlink resolution — it follows `.venv/bin/python3` → uv's internal path and then rejects it. The fix is clearing quarantine (insight 1), not changing the interpreter path. Keep `python.defaultInterpreterPath` pointing to `.venv/bin/python3`.
3. Pylance needs the **source root** in `python.analysis.extraPaths`, not just site-packages. For a `backend/` subdirectory, add `${workspaceFolder}/backend` so imports like `from lib.config import ...` resolve. Site-packages alone is insufficient.
4. `python.terminal.activateEnvironment: false` disables the automatic `source .venv/bin/activate` on every new terminal — useful when using `uv run` as the execution wrapper instead.
5. Pytest discovery SIGKILL in VS Code is caused by running discovery from the workspace root (where no venv exists). Fix: set `python.testing.cwd` to `${workspaceFolder}/backend` and `python.testing.pytestArgs` to `["backend"]`.
6. `.vscode/settings.json` is gitignored in this project — all IDE config changes are local only, not shared with teammates or across machines.
7. `pyrightconfig.json` at the repo root should set `venvPath`, `venv`, `include`, and `extraPaths` for the backend. Without `include: ["backend"]`, Pyright may analyse the wrong root.

---


  ## core-dump: session snapshot (dashboard integration + image backfill) — 2026- 
  03-                                                                             
  25                                                                              
                                                                                  
  **Purpose:** Snapshot a session covering manual step testing, 24-image backfill,
  image-review dashboard, and legacy dashboard integration.                       
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. The Write tool requires a prior Read of the file — even for overwrite. Always
  Read (even just 5 lines) before Write, or use Edit for in-place changes.        
  2. The previous checkpoint file (_checkpoint-2026-03-24.claude.md) was a dated  
  variant; the default _checkpoint.claude.md overwrites in place. Use dated       
  filenames only when historical preservation is needed.                          
  3. Session had no filename argument — default path used correctly without       
  needing Glob lookup.                                                            
                                                                                  
  --------                                                                        


---

  ## generate-pdf: interview-goals.md — 2026-03-24 22:34                          
                                                                                  
  **Purpose:** Generate PDF of the interview goals reference document for the     
  resumes project.                                                                
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. Script ran cleanly on second invocation — md-to-pdf already cached from prior
  session, no Chromium download delay.                                            
  2. interview-goals.md contains tables and code-style blocks; CSS renders them   
  correctly at 254 KB — no layout issues observed.                                
  3. No --open flag used; user did not need auto-open for this run.               
                                                                                  
  --------                                                                        


---

  ## session: MCP catalog + add-mcp skill — 2026-03-24                            
                                                                                  
  **Purpose:** Created a central MCP catalog system so configs never need to be   
  written from scratch per-project.                                               
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. ~/.claude/mcp-catalog.json is the single source of truth for all MCP server  
  configs — keyed by name, includes metadata (tags, when-to-use, requiresEnv,     
  templateVars for substitutable fields like connection strings).                 
  2. The add-mcp skill reads the catalog, handles {{PLACEHOLDER}} substitution    
  interactively, merges into .mcp.json, and handles already-present keys          
  gracefully.                                                                     
  3. Global CLAUDE.md now instructs Claude to proactively check the catalog when a
  project's stack matches an entry (e.g. MongoDB detected in package.json → offer 
  mongodb-local).                                                                 
  4. Plugin-managed MCPs (Chrome DevTools, Playwright, Sentry, Slack)             
  intentionally excluded from catalog — they're controlled by their respective    
  plugins and shouldn't be double-configured.                                     
                                                                                  
  --------                                                                        


---

  ## improve-config: MCPs, plugins, global context audit — 2026-03-24             
                                                                                  
  **Purpose:** Audit active MCPs, plugins, and hooks for runtime impact and       
  redundancy; applied deduplication fix.                                          
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. Three plugins were registered from BOTH claude-plugins-official AND claude-  
  code-plugins: code-review, commit-commands, frontend-design. Duplicate          
  registrations cause non-deterministic command resolution — always prefer the -  
  official versions.                                                              
  2. Global ~/.claude/.mcp.json has localhost MCPs (mongodb, redis, postgres) that
  target hardcoded local ports — these should live in per-project .mcp.json, not  
  the global config, to avoid startup noise on unrelated projects.                
  3. The Vercel plugin is the heaviest hook contributor: it fires Node.js         
  processes on every Read/Edit/Write/Bash (PreToolUse), every UserPromptSubmit    
  (x2), and every PostToolUse Bash (x4). This is ~7 hook process launches per Bash
  call. Acceptable for Vercel projects; significant overhead for non-Vercel work. 
  4. The Stop hook runs a claude-haiku agent (timeout=15s) on every response to   
  generate a tab title — this is cosmetic and may be worth disabling for high-    
  throughput sessions.                                                            
                                                                                  
  --------                                                                        


---

  ## improve-skill: core-dump — absolute lock-file paths for global use — 2026-03-
  24                                                                              
                                                                                  
  **Purpose:** Fix core-dump SKILL.md to use ~/.claude/skills/shared/ absolute    
  paths so the skill works when called from any directory, not just a project root
  containing .claude/.                                                            
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. Skills that can be invoked from any directory (like core-dump) must reference
  shared scripts by absolute path (~/.claude/skills/shared/) — relative paths like .
  claude/skills/shared/ only resolve from project roots that contain .claude/.    
  2. lock-file.sh stores its locks relative to its own script location ($(dirname 
  "$0")/locks), so the locks directory is always ~/.claude/skills/shared/locks/   
  regardless of where the script is called from — the script itself is already    
  directory-agnostic, only the call-site paths were broken.                       
  3. prepend-runtime-note.sh also uses SCRIPT_DIR internally and is already       
  directory-safe — only the invocation path in SKILL.md needed updating.          


---

  ## core-dump: Session checkpoint for parallel downloads — 2026-03-21            
                                                                                  
  **Purpose:** Captured session state after implementing parallel poster download 
  engine and comparing Excel attribute coverage.                                  
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. Previous checkpoint had extensive carry-forward items (deployment plan,      
  uncommitted fixes) — preserved key items in new checkpoint to avoid data loss   
  2. Excel comparison was straightforward: xlsx package already available in      
  project's node_modules, no install needed                                       
  3. posters/ vs posters_last/ comparison via comm -23 on sorted ls output is fast
  and reliable for file-level diff                                                
                                                                                  
  --------                                                                        


---

  ## core-dump: JSON-to-XLSX pipeline checkpoint — 2026-03-20                     
                                                                                  
  **Purpose:** Checkpoint the session covering creation of json_to_xlsx.py and the
  normalize preset pipeline.                                                      
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. The parse-excel/ folder is the right home for JSON-to-XLSX work — it has a   
  venv with openpyxl and existing Excel-related scripts.                          
  2. normalize.json stem is used as the preset key — if the input file is renamed,
  the preset won't match. Consider documenting this for users.                    
  3. Non-ASCII scan found 7 distinct characters, all typography-related (smart    
  quotes, dashes, degree sign). The regex [^\x00-\x7F] is a clean catch-all.      
                                                                                  
  --------                                                                        


---

# Core Dump — 2026-03-18T18:43

## Initial Goal

Generate an HTML report from the enriched JEGS product catalog JSON export (`transformed-output-enriched.json`, Mar 17 2026), then analyze the data for attribute anomalies, title pattern issues, and quality oddities.

## Agent Actions

1. Invoked `/create-report` with a JSON file path — adapted the skill (which normally expects markdown) to build structured report JSON directly from product data, skipping the markdown intermediary.
2. Ran Node.js scripts to extract summary stats: 590 items, all JEGS brand, 492 unique part types, 467/590 with images, avg 5 features and 5 attributes per item, avg description ~500 chars.
3. Ran deeper analysis: top part type categories (Fuel Tank 18x, Fuel Tank Sending Unit 12x), top attribute keys (Material 265x, Finish 162x, Color 133x), category distribution.
4. Built structured `ReportData` JSON (6 sections: Overview, Data Quality, Part Categories, Attribute Analysis, Featured Products, Product Index with all 590 rows) and wrote to `.claude/report-data.tmp.json`.
5. Ran `generate-html.ts` via `npx tsx` — succeeded on first attempt, output to `.claude/output/20260318-1843-transformed-output-enric/index.html`.
6. Background cleanup task (`rm` + `open Chrome`) was killed — shell had `rm` aliased to interactive mode; fixed with `rm -f`.
7. **Data analysis Q1 (attribute lengths):** Longest attr keys are full sentences (anomalies); shortest legitimate keys are 3-4 chars (`Set`, `Use`). Longest value is 123 chars on `555-10015` (composite spec block). Encoding corruption found on `555-41400` Includes field (`/8` npt, truncated with `"cellen"`).
8. **Data analysis Q2 (title anomalies):** Pattern `"JEGS [Part Type] [Descriptors] - [Part Number]"` is perfectly consistent — no missing JEGS prefix, no part number mismatches. Found **5 titles with literal `"N/A"` embedded** before the part number suffix (e.g., `"...OEM-S N/A - 555-90625"`), likely from a blank fitment/year source column bleeding into title generation.
9. **Data analysis Q3 (attribute oddities):**
   - `555-28030` (Blue RTV) and `555-93778`/`555-93777` (window switches): features used as attribute **keys** with value `"Yes"` — Features & Benefits leaked into attribute table.
   - `555-62114`, `555-62102`: `Includes` values have **list items concatenated without delimiters** (newline-stripping artifact from source).
   - `555-41400`: `Includes` value has **encoding corruption** (`/8` npt, mid-word cutoff).
   - `555-10015`: `"Style Mini"` key has a 123-char dimension block as value — looks like a composite field split gone wrong.
   - 5 items have color/finish descriptors under `Material` key (e.g., `"Black Rubber"`, `"Clear Acrylic"`).
   - 306 singleton attribute keys (appear in exactly 1 product) — suggests no controlled vocabulary enforcement in the enhancement pipeline.

## Current Expectation

User has the HTML report open and has reviewed the analysis findings. No explicit next step requested — likely reviewing findings and deciding whether to fix the pipeline or the data.

## Pending Items

- No in-progress tasks from this session.
- Potential follow-ups (not yet requested):
  - Fix `N/A` title generation for items with blank fitment/year fields
  - Fix feature-bleed into attribute keys (RTV, window switch items)
  - Fix `Includes` concatenation issue (missing delimiters)
  - Fix encoding corruption in `555-41400`
  - Investigate/resolve the prior hanging issue with `call-ebay-poster-api.js` (documented in MEMORY.md)

---

_Generated by /core-dump. Resume with /catchup._

---

  ## create-skill: created catchup — 2026-02-26 02:25                             
                                                                                  
  **Purpose:** Build the companion skill to /core-dump that resumes a cleared     
  session from a _*.claude.md checkpoint with minimum token usage.                
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. The inverted presentation order (pending → expectation → goal) is the key    
  design decision — users resuming a session need to know "what's next"           
  immediately, not re-read where they started. This is the opposite of how /core- 
  dump writes sections.                                                           
  2. The "file not found → glob → ask user" fallback pattern is reusable for any  
  skill that defaults to a specific file — it's friendlier than a hard error and  
  enables multi-checkpoint workflows.                                             
  3. Targeted Grep over full Read is the primary token-reduction mechanism. The   
  checkpoint's agent actions log provides enough location context (file path +    
  symbol/line hint) to scope the Grep correctly — this contract between /core-dump
  and /catchup should be kept explicit.                                           
  4. The hand-off question ("which pending item to start with?") is a deliberate  
  stop — without it, the skill would autonomously prioritize and start work,      
  potentially in the wrong direction after a context break.                       
  5. Runtime notes scanning for "task-domain keywords" is inherently fuzzy — a    
  future improvement could have /core-dump tag the checkpoint with skill names or 
  domain labels that /catchup can match exactly.                                  
                                                                                  
  --------                                                                        


---

  ## create-skill: created core-dump — 2026-02-26 02:00                           
                                                                                  
  **Purpose:** Build a skill that writes a compact session checkpoint             
  (_checkpoint.claude.md) to the project root, condensing the active conversation 
  for hand-off to /catchup after /clear.                                          
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. The "overwrite not append" constraint is load-bearing for core-dump          
  correctness — checkpoints are snapshots, not logs. Make this explicit in the    
  skill or consumers may expect accumulaton behavior.                             
  2. Filename detection via "starts with _ or ends in .md" covers 99% of cases but
  could collide with a user passing a relative path like "src/foo.md" — a future  
  refinement could restrict to basename-only tokens.                              
  3. The _*.claude.md convention emerged from this skill's design and was         
  immediately promoted to GUIDELINES §9 — a good example of a naming decision that
  should be made at skill creation time, not discovered later.                    
  4. Pairing a "dump" skill with a "catchup" companion is a clean pattern for     
  stateless session continuity — the dump skill's output contract (four sections: 
  goal, actions, expectation, pending) should be documented in the catchup skill's
  input spec too.                                                                 
  5. Style instructions as free-form trailing args (vs. named flags) keeps        
  invocation natural but makes the skill harder to test mechanically — document   
  this trade-off in the skill's Notes section if /catchup ever needs to verify    
  checkpoint structure.                                                           
                                                                                  
  --------                                                                        


---

## user-config: edit — added gum to GUIDELINES + gum-guide.md — 2026-02-20 05:35
**Purpose:** Add gum as an available TUI option for all skills via GUIDELINES.md, and create a comprehensive guide for multi-turn interactions and data visualization.

**Insights:**
1. Adding a new shared tool to GUIDELINES.md is the right single-source-of-truth approach — every skill inherits it without per-skill edits, as long as the guide reference is clear.
2. The gum-guide.md belongs in `shared/` alongside the shell scripts — it's infrastructure documentation, not skill-specific content, so it's always in scope for any skill author.
3. `gum confirm` exits 0/1 rather than printing yes/no — skills must use it in `if` conditionals, not capture its output; this is a common gotcha worth documenting explicitly.
4. The four multi-turn patterns (loop menu, wizard, approval gate, progress tracking) cover 95% of skill interaction needs — documenting them as named patterns gives future skill authors a vocabulary to reach for.
5. `gum spin` suppresses inner command stdout — skills that need the output of a spun command must redirect inside the inner bash -c string to a temp file.

---


  ## improve-skill: create-report — Added OG + Twitter meta tags — 2026-02-23     
                                                                                  
  **Purpose:** Add Open Graph and Twitter Card metadata to the HTML reports       
  generated by create-report.                                                     
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. The ogDesc variable is computed from data.subtitle ?? statsStr — this is the 
  right fallback order: structured subtitle wins over the computed stats string,  
  so reports with rich metadata always prefer it.                                 
  2. OG tags placed immediately after <title> in <head> is the conventional order;
  some crawlers stop parsing the head early, so position matters.                 
  3. og:type = "article" is the correct OG type for document-style content        
  (reports, documentation, indexes) — distinguish from "website" (homepages) or   
  "profile".                                                                      
  4. twitter:card = "summary" (not "summary_large_image") is appropriate since    
  there's no og:image — Twitter falls back gracefully but won't show a card at all
  if the card type is mismatched.                                                 
  5. The ogDesc variable is declared before the template literal and reused for   
  both OG and Twitter tags — avoids duplicating the esc(data.subtitle ?? statsStr)
  expression inline in the template string where it would be harder to read.      
                                                                                  
  --------                                                                        


---

  ## project-index: Incremental scan — no changes detected — 2026-02-23 18:30     
                                                                                  
  **Purpose:** Fourth run of /project-index — same-day incremental scan 6.5 hours 
  after last run. Verified codebase stability.                                    
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. Same-day re-scans with no intervening commits are effectively no-ops — the   
  entire scan completed quickly with zero drift detected. Consider adding a "skip 
  if no git changes since last run" optimization.                                 
  2. The 3 unstaged WIP files (s2ig, pipeline.args, pipeline.types) have persisted
  across two runs now — they represent the active image generation feature branch 
  that has not been committed yet.                                                
  3. The export scan across src/utils/ produces ~330 matches — reading the full   
  output is the bottleneck. For incremental runs, a git diff --name-only check    
  against the export directories first would allow skipping the export scan       
  entirely when no files changed.                                                 
  4. Backend api/ listing is stable at ~20 files — no new endpoints added since   
  the service/ and internal/ subdirectories were documented.                      
  5. All 7 code snippets remain valid and unchanged — snippet freshness can be    
  verified by checking git log --oneline -1 -- <file> for each snippet source file
  rather than re-reading the full files.                                          


---

  ## project-index: Incremental scan — corrected atom count, expanded             
  exports/backend — 2026-02-23 12:00                                              
                                                                                  
  **Purpose:** Third run of /project-index — incremental scan 3 days after last   
  run. Focused on verifying changes, correcting previous inaccuracies, and        
  expanding coverage.                                                             
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. The Jotai atom count was wrong in the previous two runs (claimed "only 1 atom
  file") — grepping for atom\(|atomWithStorage\( found 5 atoms across 4 files. The
  atomWithStorage import from jotai/utils was missed because previous runs only   
  grepped for atom(. Always include both atom( and atomWithStorage( in the search 
  pattern.                                                                        
  2. The backend api/ directory grew significantly since the first index (from 8  
  files to 18+) — the internal/ and service/ subdirectories are new organizational
  layers. Backend should be re-scanned periodically even when frontend hasn't     
  changed.                                                                        
  3. Expanding the Key Utility Exports table from 34 to 52 rows by including      
  permission hooks, error utilities, Slack helpers, and Redis cache significantly 
  improves the index's usefulness as a lookup reference.                          
  4. The pipeline architecture section now documents the getPipelineArgsMap       
  registry pattern — this is the key abstraction that makes the pipeline system   
  extensible. Future indexing should track new entries in this map.               
  5. No dependency, route, migration, or hook changes in 3 days — the codebase is 
  in a stable maintenance phase with only pipeline argument refinement (image-gen 
  V2 args) in progress.                                                           


---

  ## invalidate-audit: First full codebase scan — 2026-02-21                      
                                                                                  
  **Purpose:** Scan all useM() and useMutation() calls across src/ and classify   
  each for missing TanStack Query cache invalidation.                             
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. useM wraps onSettled with an invalidate() call internally — so for useM calls,
  the audit criterion is presence of invalidate or invalidateKey prop, NOT an     
  explicit onSettled block. Raw useMutation still needs explicit                  
  onSuccess/onSettled.                                                            
  2. Many mutations use imperative invalidation in the calling handler (e.g.,     
  handleSaveRow calls callUpdateUser then queryClient.invalidateQueries) rather   
  than inside the mutation config. These are technically safe but fragile — if the
  mutation is called from a different code path, invalidation is skipped.         
  3. Preview-only mutations (callRunPipeline, callPreviewEnhancement, preview-    
  profile-card.tsx) intentionally have no cache invalidation since they only      
  update local state. A // no-invalidate comment would suppress false positives   
  here.                                                                           
  4. Fire-and-forget mutations (Slack notifications, login token generation,      
  stripe checkout redirect, site inspector fetch) are all useM without invalidate 
  but are legitimately fire-and-forget. Recommend adding // no-invalidate comments
  to suppress them in future audit runs.                                          
  5. use-credit.ts:22 (callCreditJobItems) is a raw useMutation with no           
  onSuccess/onSettled at all — but it's used as a utility called from other       
  mutations' onSuccess handlers, so this is a pattern rather than a bug.          
  6. callUpdateUser in team-users.tsx:56 and callRerunJob in data-history-row-    
  actions.tsx:116 are the clearest actionable WARNING cases — they mutate state   
  without any subsequent cache refresh.                                           
                                                                                  
  --------                                                                        


---

  ## create-skill: created pick-skill — 2026-02-21 00:30                          
                                                                                  
  **Purpose:** Build a new skill that routes raw user prompts to the best matching
  skill using the catalogue, with clarifying questions and gum confirm gate.      
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. The 7-question wizard produced a complete, well-scoped skill on the first    
  plan pass — no revision needed, suggesting the Q&A order (goal → usage →        
  constraints → tools → examples → extras) is well-calibrated for meta-skills like
  routers.                                                                        
  2. "Execute after confirming" as a constraint is better formalized as a gum     
  confirm gate at 2.3 rather than a general prohibition — makes it testable and   
  explicit in the workflow.                                                       
  3. The no-match fallback (surface 3 partial matches + suggest /create-skill) is 
  a natural extension of the skill catalogue pattern — every routing skill should 
  have this as its terminal state.                                                
  4. Post-run /create-report integration is cleanly handled as an offer, not a    
  forced step — the condition (markdown output exists) prevents it from firing on 
  skills that only print to terminal.                                             
                                                                                  
  --------                                                                        


---

  ## create-report: Fixed sequential regex corruption in highlight() — 2026-02-20 
  17:35                                                                           
                                                                                  
  **Purpose:** Debug and fix broken syntax highlighting where span class          
  attributes were being re-highlighted by subsequent regex passes.                
                                                                                  
  **Root cause:** highlight() applied regexes sequentially on already-mutated     
  strings. After step 1 wrapped //comment in <span class="cm">, step 2's keyword  
  regex matched class inside class="cm", and step 3's string regex matched "cm" as
  a string literal. Each pass corrupted the HTML injected by the prior pass.      
                                                                                  
  **Fix:** Use control-character placeholder tokens (\x02N\x03) to protect already-
  rendered spans before applying subsequent regex passes. Restore placeholders at 
  the end. Applied to all four language branches (bash, ts/tsx/js/jsx, json,      
  css/scss).                                                                      
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. The bug only manifests when highlighted code contains TSX/TS keywords like   
  class, type, string, or boolean — which are common in HTML attributes like      
  class="cm". Plain flow-diagram code (lang="") is unaffected since no            
  highlighting runs.                                                              
  2. Diagnosis path: user showed garbled HTML output → Grep for affected string in
  index.html → saw <span <span class="kw">class</span>=<span                      
  class="st">"cm"</span>> → immediately identified sequential regex corruption.   
  3. \x02 and \x03 are safe sentinel characters — they cannot appear in HTML-     
  escaped source code and are invisible to all the regex patterns used for        
  highlighting.                                                                   
  4. The JSON LLM parsing step should always use lang: "ts" or lang: "tsx" for    
  TypeScript/TSX code blocks, not lang: "" — using the correct language enables   
  highlighting and exposed this bug.                                              
  5. When generating JSON for create-report: write it via Python json.dump()      
  rather than bash heredoc to avoid line-wrapping control characters inside JSON  
  strings.                                                                        
                                                                                  
  --------                                                                        


---

  ## improve-claude: full 5-phase config overhaul — 2026-02-20                    
                                                                                  
  **Purpose:** Ran /improve-claude with internet research to find and implement   
  all                                                                             
  major gaps in the .claude/ setup — CLAUDE.md, hooks, path-scoped rules, new     
  skills, cleanup of deprecated skills.                                           
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. $FILE_PATH env var in PostToolUse hooks has a known bug — use jq -r '.       
  tool_input.file_path // empty' from stdin JSON instead.                         
  2. settings.local.json is auto-modified by Claude Code every time a new Bash    
  command is approved — repeated cleanups were needed. Wildcard entries like      
  Bash(bash .claude/skills/shared/lock-file.sh:*) help but don't prevent absolute-
  path duplicates.                                                                
  3. CLAUDE.md at project root is the most reliable way to load project           
  conventions at session start — more reliable than relying on context-prime being
  run manually.                                                                   
  4. .claude/rules/*.md with paths: YAML frontmatter is the correct pattern for   
  path-scoped instructions (e.g. db schema rules only when editing src/db/). As of
  2026, this is a native Claude Code feature.                                     
  5. context: fork in SKILL.md frontmatter isolates heavy read-only skills (like  
  pr-review) from the main conversation context window — important for large      
  codebase scans.                                                                 
  6. The disable-model-invocation: true frontmatter field prevents Claude from    
  auto-triggering a skill without explicit user invocation — use for sensitive or 
  heavy skills.                                                                   
  7. When writing many SKILL.md files in one session, context compression can     
  occur — the session continuation mechanism preserved all completed work         
  correctly via the JSONL transcript.                                             


---

  ## improve-claude: Internet research + improvements.md — 2026-02-20 01:00       
                                                                                  
  **Purpose:** Deep web research on Claude Code config best practices + full      
  .claude/ audit to produce improvements.md with 17 fixes and 10 new skill ideas. 
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. Two research agents in parallel (config best practices + skill ideas)        
  produced far more thorough output than a single sequential search — total 46    
  tool calls across both agents covering official docs, GitHub, and community     
  sites.                                                                          
  2. The $FILE_PATH env var in hooks has a known bug in some Claude Code versions 
  — always use jq -r '.tool_input.file_path' from stdin for reliable file path    
  extraction in PostToolUse hooks.                                                
  3. Dynamic injection !`command` in SKILL.md files is confirmed working and is   
  the correct way to build /context-prime style skills that inject live git/system
  state.                                                                          
  4. disable-model-invocation: true and context: fork are real frontmatter fields 
  not documented in this project's GUIDELINES.md — worth adding to the shared     
  conventions.                                                                    
  5. With 11 skills loaded, the skill description context budget (~16,000 chars)  
  may be approached — removing the 2 deprecated skills (improve-claude, new-skill)
  reclaims ~300 chars of budget.                                                  
  6. The .claude/rules/ directory with YAML paths: frontmatter for path-scoped    
  rules is a powerful pattern none of the existing skills use — ideal for "always 
  run db:generate after schema edits" type rules.                                 


---

  ## project-index: added Key Utility Exports + Key Code Snippets — 2026-02-20    
  06:23                                                                           
                                                                                  
  **Purpose:** Incremental scan run after /improve-skill added Step 5.5 (symbol-  
  level export scanning) and Step 6.5 (code snippet collection). Primary goal:    
  produce an index that actually answers "where is useQ defined?" and "what does  
  withServer do?"                                                                 
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. The export scan (^export (function|const|class|type|interface|enum)) across  
  src/utils/hooks/ returned 37 hooks — the "32 hooks total" count in the index was
  undercounted. Worth updating on the next full scan.                             
  2. createKeyedContext returns [Provider, useCtx] as const but the useCtx        
  signature uses Partial<T> — callers get the value with || undefined fallback,   
  not a required-field guarantee. This is intentional permissiveness, not a bug.  
  3. The single Jotai atom file pattern is architecturally significant: the       
  project chose TanStack Query for server state + React Context for page state +  
  Jotai only for auth SSR coordination. Document this "three-layer state" pattern 
  explicitly in the index.                                                        
  4. The report-data.tmp.json was left over from a previous session (Step 6       
  cleanup failed). Always verify the temp file is deleted after a successful run; 
  leftover JSON from a prior run can cause the Write tool to require a Read first.
  5. The two new sections (Key Utility Exports + Key Code Snippets) add ~230 lines
  to the index (1004 total vs 751 before) — still comfortably within the create-  
  report skill's parsing capacity.                                                
  6. Slugifying subsection IDs for Key Code Snippets required stripping /, ., and 
  — from file path headings. Using only alphanumeric + - avoids anchor link issues
  in the HTML nav.                                                                


---

  ## improve-claude: skill renaming for terminology consistency — 2026-02-20 07:00
                                                                                  
  **Purpose:** Rename improve-claude → improve-config and new-skill → create-skill
  to                                                                              
  align naming conventions across the skill family (verb-noun for creation skills,
  improve- for improvement skills).                                               
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. Skill renaming cannot delete directories, so the pattern is: write new dir + 
  deprecate old SKILL.md to user-invokable: false stub — old dirs must be deleted 
  manually by the user.                                                           
  2. The improve-claude name was confusing because it sounds like improving       
  "Claude the AI" rather than the .claude/ config directory — the improve-        
  <subject> pattern only works when the subject matches what's being improved.    
  3. settings.local.json permissions require explicit Skill(name) entries — a     
  rename must update this file or the permission prompt will fire on first        
  invocation of the new skill name.                                               
  4. Writing new SKILL.md files from a full content template is more reliable than
  Edit-patching for renames — avoids whitespace/encoding mismatches that cause    
  "string not found" errors.                                                      
  5. The actual file on disk may have slightly different frontmatter than what was
  shown in the skill invocation system message (e.g., WebFetch in allowed-tools) —
  always Read the file before Edit operations.                                    
                                                                                  
  --------                                                                        


---

  ## improve-skill: project-index — added export-level scanning (Step 5.5) — 2026-
  02-20                                                                           
  05:50                                                                           
                                                                                  
  **Purpose:** Add a new Step 5.5 to document named exports from utility modules, 
  answering "why aren't useQ/withServer in the index?"                            
                                                                                  
  **Insights:**                                                                   
                                                                                  
  1. The skill was file-level only — use-q.ts appeared but useQ never did. The gap
  between "file exists" and "what it exports" is the most common missing layer in 
  codebase indexes.                                                               
  2. ^export (function|const|class|type|interface|enum) as a single Grep pattern  
  across src/utils/*.ts and src/utils/hooks/*.ts captures all meaningful exports  
  in one pass — no need to read each file individually.                           
  3. Pre-populating the confirmed exports table in Project-Specific Patterns means
  future runs start with a baseline of ~17 known symbols and only need to         
  verify/extend, not rediscover.                                                  
  4. Filter rules matter: without explicit skip rules (re-exports, export {},     
  trivially-named), the table fills with noise. The "skip" list in Step 5.5 is as 
  important as the scan itself.                                                   
  5. The Step 7 output template now has a ## Key Utility Exports placeholder —    
  this means create-report's LLM will see it in context and know to render it as a
  table section, not skip it.                                                     
                                                                                  
  --------                                                                        


---

## improve-skill: project-index — focused on HTML UI + data collection — 2026-02-20 04:00
**Purpose:** Improve project-index output to include expandable directory trees, clickable package URLs, and code snippet previews in the HTML report.

**Insights:**
1. The `tree` block type change spans three files: `generate-html.ts` (types + rendering), `styles.css` (CSS classes), and `create-report/SKILL.md` (LLM parsing instructions). All three must be updated together or the block renders but looks unstyled.
2. `generate-html.ts` already had a `<dialog>` expand mechanism for code blocks — the code snippet feature in project-index will activate this UI that was previously dormant (no snippets were ever collected).
3. For npm URL links: the `ul` block type already supports inline HTML in `items[]` strings, so `<a href="...">package-name</a>` works in dependency lists without any schema changes. The link generation is purely a data-collection instruction change in project-index.
4. The Prettier format of SKILL.md changes triple-backtick fenced blocks inside template sections into four-backtick ```` blocks (to escape inner fences) — be aware of this if editing template code blocks manually.
5. Smoke-testing `generate-html.ts` with `npx tsx ... 2>&1` before writing post-run notes is the fastest way to validate TypeScript changes compile and produce correct HTML — do this before declaring success.

---


---

## new-skill: Created improve-claude skill — 2026-02-20 05:24
**Purpose:** Run /new-skill to build the improve-claude skill through the full 7-question wizard, plan review, and file generation.

**Insights:**
1. The Grep glob param bug (drop glob when path is already a subdir) appeared again in Phase 0 when scanning for existing skill names — confirming this is the most common failure point for new skill runs.
2. The Q&A loop worked well with 4 examples in Q6 — the formalization step added clarity that the user's raw examples lacked (especially the workflow-composition example).
3. The `--dry-run` flag emerged from user discussion rather than the original spec; the argument design phase benefits from explicitly asking "would a preview mode help?" for audit-style skills.
4. Naming flags after standard CLI conventions (`--scope`, `--skip`, `--dry-run`) rather than inventing custom names reduces cognitive load — worth raising proactively when formalizing Q3.
5. The plan outline format (Phase 2) was enough for the user to approve in one pass; no revision needed — suggesting the 7-question structure produces sufficient detail when followed faithfully.

---

## user-config: Overview run — 2026-02-20 03:30
**Purpose:** First run of /user-config — scan .claude/, verify all skill briefs exist, and print the formatted config overview.

**Insights:**
1. Grepping for `## Brief` across the full `.claude/skills/` tree without a `glob` param returned all results in one call — more reliable than reading each SKILL.md individually.
2. The `runtime-notes.md` line count is a poor proxy for "number of entries" — counting `---` separators or `## ` headings would be more accurate in future runs.
3. `settings.local.json` contains a `Skill(create-report)` permission alongside bash permissions — the overview should distinguish skill permissions from bash permissions for clarity.
4. The Grep `glob` param bug: when `path` is already a subdirectory and `glob` uses `*/SKILL.md`, no matches are returned — drop the `glob` and scan the directory directly instead.

---

## create-report: project-index.md → project-index.html — 2026-02-20 (resumed run)
**Purpose:** Generate a polished HTML report from the project index markdown via the LLM → JSON → npx tsx pipeline.

**Insights:**
1. The JSON temp file persisted across the context-window break, allowing the run to resume at Step 4 without re-parsing the markdown — the LLM's work survived compaction.
2. `npx tsx generate-html.ts` succeeded on the first attempt with no validation errors, confirming the `&amp;` escaping and duplicate-ID slugification done during parsing were correct.
3. The early-exit check (skip generation if HTML already exists) should be placed before reading the markdown — this avoids even loading a potentially large file when just opening Chrome.
4. Using `open -a "Google Chrome"` returns immediately (background process), so cleanup of temp files should happen before the open call.

---
