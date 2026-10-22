# Dream Insights

_High-confidence associations promoted by the Wake phase._

## Wake Cycle — 2026-10-01 05:28 UTC

### Insight (conf=0.88)
> The agent systematically substitutes cheaper verification proxies (static checks, snapshots, code reading, green tests) for the actual exercise the user demands (running the app, rendering the page, clicking the button), and each proxy type is a distinct surface of the same underlying failure: conflating 'checked' with 'exercised'.

**Rule:** Always identify whether the verification instrument measures the claim being made — a type check measures types, a snapshot measures structure, only a browser render measures appearance — and never declare a claim verified by an instrument that measures a different dimension.

**Evidence:**
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "Shipping code and reporting a visual feature as complete without rendering and viewing the actual target state (not just green tests) produc…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, .claude, i-dream, claude-ipc
- _Sessions_ (132): 1cd54c1d, 14422091, 06fa3e6a, +129 more

---
### Insight (conf=0.82)
> Four independently filed patterns all describe the same root failure: the agent treats 'path information is present somewhere in the reply' as equivalent to 'the user can act on the path', when the actual constraint is that the path must be visually unambiguous, clickable, and complete at the point the user's eye lands on it.

**Rule:** Always emit every file path as a standalone absolute plain-text string on its own line or clause, never only inside markdown syntax, never immediately before a period, and never as a basename alone — the path must be copy-pasteable from the terminal without editing.

**Evidence:**
- _Pattern_: "A file path in terminal output immediately followed by a period is swallowed into Ghostty's auto-link, making the path unclickable; always f…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Projects_ (8): -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Personal-controlelr, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-local-models
- _Sessions_ (61): f174913c, d63d7b95, 99eabe29, +58 more

---
### Insight (conf=0.80)
> The agent has a consistent pattern of declaring completion on multi-condition gates after satisfying only one condition — 'ready to merge' without checking merge state, 'fixed' without testing in browser, 'done' with only one of two environments verified — suggesting the completion signal fires on first positive evidence rather than after exhausting all required checks.

**Rule:** Always enumerate all arms of a completion condition before checking any of them, then check each independently and mark completion only when every arm has a passing result — partial completion of a multi-arm condition is never completion.

**Evidence:**
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Pattern_: "When the agent announces a UI or runtime fix and the user tests it on the actual running app, discovering it still fails, the agent had clai…"
- _Projects_ (17): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, gcp, better-file-browser, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude-codex, codex, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude
- _Sessions_ (111): fb88b328, f67f42ae, f0272391, +108 more

---
### Insight (conf=0.78)
> The agent treats its own model of the world as ground truth and acts on it without verification — claiming code doesn't exist without reading it, escalating about blocked hardware without checking, accepting a scope reduction without probing, building a domain model without questioning it — all are instances of acting on an internal belief rather than an observed state.

**Rule:** Always verify a belief against the live system before acting on it or presenting it as fact — especially when the belief would narrow scope, trigger an escalation, or justify skipping work.

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "When the agent raises concerns about a blocked state (e.g. hardware unreachable), it should verify current state first before escalating or …"
- _Pattern_: "When an agent implements a domain model without questioning whether the model makes business sense (e.g., a billing unit with no clear divis…"
- _Pattern_: "When a sub-agent or steward proposes a scope reduction, the agent must independently probe feasibility before presenting the narrowed scope …"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-speedway, slack-automation, enhancement-product, gcp, speedway, .claude, controlelr, -Users-alcatraz627-Documents-studio-search-jul-26-fable-runs-20260806-r1-report, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder
- _Sessions_ (137): d63726f5, d049ade6, bc8f0f24, +134 more

---
### Insight (conf=0.75)
> The agent has a deeply embedded 'register' that survives single corrections — AI-smell prose (em-dashes, jargon, excessive structure) is not a surface formatting choice but a generative default that reasserts itself within turns, suggesting the correction must target the generation strategy (rewrite pass) rather than the output (spot fix).

**Rule:** Always run a full prose-register rewrite pass on the entire reply after any style correction in a session, rather than patching only the flagged sentence, because the generative default reasserts in unflagged sentences.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "Commit messages and PR descriptions must be concise and human-sounding; the user explicitly audits these artifacts with a style review tool …"
- _Projects_ (24): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-two-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product-frontend--claude-output-20260723-pr264-review, -Users-alcatraz627-Code-Versable-enhancement-product-backend, -Users-alcatraz627-Code-Versable-enhancement-product--github-workflows, frontend, claude-ipc, i-dream, claude-instances
- _Sessions_ (130): 0c39a659, fb13ca88, f9f4c3b2, +127 more

---
### Insight (conf=0.72)
> The agent defaults to synthesis and summarization even when the user explicitly requested preservation of distinct artifacts — 'show me X' becomes 'here is my summary of X', 'compare A and B' becomes 'here is a merged view' — indicating a compression bias that destroys the separation the user needs for their own judgment.

**Rule:** Always preserve artifact boundaries when the user's verb is 'show', 'compare', or 'contrast' — surface the originals side by side and never merge, synthesize, or summarize unless the user's verb is explicitly 'merge' or 'combine'.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to be 'shown' a document or artifact, the agent must surface the artifact itself — not a prose summary of its contents. A…"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation
- _Sessions_ (57): dac333f4, c71644cf, b6809eaf, +54 more

---
### Insight (conf=0.70)
> All three concern the agent producing output under the user's identity without adequate provenance marking — GitHub comments without attribution, documents with inappropriate banter, posts without agent markers — revealing that the agent does not maintain a stable model of 'this output will be read as if the user wrote it' across different output surfaces.

**Rule:** Always apply the audience-identity check before any output that exits the local session: 'Will this be attributed to the user? If yes, would the user be comfortable with every sentence being read as their own words by the most hostile reader?'

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, .claude
- _Sessions_ (77): a178d6c3, c8bc2450, baf2ac20, +74 more

---
### Insight (conf=0.65)
> Both patterns describe the same temporal decay failure at different altitudes: heartbeat payloads embed stale state readings, and audit dispatches use stale derived documents instead of authoritative sources — in both cases, a snapshot taken at time T is trusted at time T+N without re-derivation, and the staleness is invisible to the consumer.

**Rule:** Always trace any document or data payload to its authoritative live source before acting on it — if the artifact is derived, cached, or embedded rather than queried, treat its factual claims as potentially stale and re-derive from the source.

**Evidence:**
- _Pattern_: "Heartbeat or resume payloads that embed live state readings (counts, SHA hashes, gate lists, diagnoses) go stale within hours and cause subs…"
- _Pattern_: "When dispatching a sub-agent to audit feature completeness or capability gaps, the agent must verify which document is the authoritative use…"
- _Projects_ (3): -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder
- _Sessions_ (53): d909e97d, c5dbca60, c40512a0, +50 more

---
### Insight (conf=0.62)
> The agent adds structural overhead (briefings, warnings, goal-line ceremonies) as a substitute for forward progress — each pattern is an instance where the agent produced meta-work (a briefing about the answer, a safety verdict nobody asked for, a goal line with no follow-through) instead of the actual work, suggesting a tendency to mistake framing for delivery.

**Rule:** Always check before ending a turn: did this turn produce a concrete artifact or advance state, or did it only describe/frame/propose one? If the latter and no blocker exists, continue to the artifact.

**Evidence:**
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Pattern_: "Printing a /goal paste line and ending the turn without making any further tool call is a rule violation; a proposed goal is not a stop cond…"
- _Projects_ (22): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627-Code-Versable-sor
- _Sessions_ (148): 0c39a659, fb13ca88, f9f4c3b2, +145 more

---


## Wake Cycle — 2026-10-01 23:11 UTC

### Insight (conf=0.85)
> The agent systematically conflates proof-of-structure with proof-of-behavior — static checks, accessibility snapshots, and code-reading all feel like verification but none exercise the runtime path, revealing a single underlying failure to distinguish 'parseable' from 'working'.

**Rule:** Always ask 'did I observe the OUTPUT of execution, not just the INPUT to it?' before any done-claim — if the last artifact read was source code, a type-check, a collect, or a DOM tree rather than a rendered result or a pass/fail line, the claim is not ready.

**Evidence:**
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "Claiming a UI change is done without actually running the changed path and reading the rendered output triggers a hook correction; only a li…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Projects_ (26): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, gcp, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -
- _Sessions_ (137): 1cd54c1d, 14422091, 06fa3e6a, +134 more

---
### Insight (conf=0.82)
> The agent has a systematic bias toward declaring completion at the first positive signal rather than checking all required conditions — whether it is a single passing test standing in for runtime verification, one arm of a multi-arm condition, or a green CI standing in for merge-readiness, the pattern is premature closure on partial evidence.

**Rule:** Always enumerate every arm of a done-condition before declaring completion — if the stop condition has N requirements, name all N and check each; a single positive signal is not completion unless N equals one.

**Evidence:**
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Projects_ (16): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, gcp, better-file-browser, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude-codex, codex, sys-monitor
- _Sessions_ (130): fb88b328, f67f42ae, f0272391, +127 more

---
### Insight (conf=0.80)
> Four path-formatting rules are actually one invariant: a file path is a UI element whose rendered form in the user's terminal must be clickable and unambiguous — every violation (trailing period, basename-only, hidden inside markdown link, short-label hyperlink) breaks the same user workflow of click-to-open.

**Rule:** Always emit file paths as standalone absolute plain-text strings followed by a non-period character — never inside markdown link syntax, never as a basename, never immediately before a sentence-ending period.

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-local-models
- _Sessions_ (70): be8b40b2, 7e2f0302, a913e430, +67 more

---
### Insight (conf=0.78)
> Structural claims without grounding (codebase assertions without file reads, ticket references without existence checks, scope reductions without feasibility probes) share a common failure: the agent treats its own confident belief as evidence, skipping the 10-second verification that would catch the error.

**Rule:** Always verify any factual claim about external state (file contents, ticket existence, feature feasibility) with a tool call before including it in a reply — treat the agent's own belief as a hypothesis, never as evidence.

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "Referencing ticket or PR numbers in responses or task entries that do not exist in the project's tracked plan is treated as a fabrication fa…"
- _Pattern_: "When a sub-agent or steward proposes a scope reduction, the agent must independently probe feasibility before presenting the narrowed scope …"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor, -Users-alcatraz627-Documents-studio-search-jul-26-fable-runs-20260806-r1-report, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder
- _Sessions_ (119): d63726f5, d049ade6, bc8f0f24, +116 more

---
### Insight (conf=0.75)
> Style-gate violations (em-dashes, path-period) persist across consecutive replies because the agent's prose generation draws from a deeply embedded register that a single correction cannot override — the fix requires a pre-emission scan pass, not a post-correction acknowledgment.

**Rule:** Always run a mechanical character-level scan (em-dash, en-dash, path-before-period) on the draft reply buffer before emitting any text, treating the scan as a blocking gate rather than a post-hoc correction.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Projects_ (30): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (136): 0c39a659, fb13ca88, f9f4c3b2, +133 more

---
### Insight (conf=0.72)
> The agent defaults to a 'demonstrate competence' frame (structured briefings, multi-section summaries, status inventories) when the user's actual frame is 'give me the next thing to act on' — the mismatch is not verbosity per se but a misread of the user's cognitive mode as evaluative when it is executive.

**Rule:** Always classify the user's current mode as either 'evaluative' (they are deciding something) or 'executive' (they want the next action) before composing a reply — in executive mode, lead with the one actionable fact and suppress all structure that demonstrates rigor.

**Evidence:**
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "After a session catchup, the agent emitted a verbose status briefing instead of immediately resuming work; the user expects action, not a su…"
- _Pattern_: "When the agent emits a multi-paragraph status update listing what it did rather than leading with the one thing the user must decide or do, …"
- _Projects_ (34): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp
- _Sessions_ (157): 0c39a659, fb13ca88, f9f4c3b2, +154 more

---
### Insight (conf=0.72)
> Both patterns punish local fixes to global structures — a per-page drawer variant and a dropdown-instead-of-path-param are structurally identical mistakes where the agent solves a symptom on one surface without auditing how the same concept is handled system-wide, producing inconsistency that compounds.

**Rule:** Always grep for every surface that uses the same semantic concept before implementing a fix or feature on one surface — if the concept appears in N places, the change must be consistent across all N or explicitly justified per divergence.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Acknowledging a routing or structural pattern in one place but implementing a workaround elsewhere (e.g., dropdown instead of path param for…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (47): ff8aef13, f95e5eb7, efd2a3ab, +44 more

---
### Insight (conf=0.70)
> The user treats independent outputs as independent cognitive objects that must remain distinct until explicitly merged — collapsing two plans into a synthesis or two comparisons into a recommendation destroys the user's ability to form their own judgment, which is the point of requesting two in the first place.

**Rule:** Always preserve the independence of separately-produced outputs when presenting them — never merge, synthesize, or recommend across them unless the user explicitly asks for a merged view.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (7): dac333f4, 0c64e0da, 1a66d7a8, +4 more

---
### Insight (conf=0.68)
> Goal-line proposals and turn-ending named-next-work are the same structural failure: the agent treats meta-statements about work as work itself, burning a turn on ceremony that produces no artifact and no progress.

**Rule:** Avoid ending a turn on any meta-statement about the work (goal proposals, named next steps, status summaries) unless the next step is genuinely blocked on external input — if you can do the thing, do it instead of naming it.

**Evidence:**
- _Pattern_: "Printing a /goal paste line and ending the turn without making any further tool call is a rule violation; a proposed goal is not a stop cond…"
- _Pattern_: "When the agent offers a goal line at session start for a clearly scoped, mechanical continuation task, the user finds it friction-adding and…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp
- _Sessions_ (81): 748d85a7, f1610d3b, f151a4e7, +78 more

---


## Wake Cycle — 2026-10-02 01:23 UTC

### Insight (conf=0.82)
> The agent systematically substitutes cheaper-to-obtain proxies for the actual verification target across unrelated domains: static checks for runtime, a11y snapshots for visual renders, derived docs for source specs, markdown links for visible paths — all share the structure of 'I checked something adjacent and reported it as the real thing'.

**Rule:** Always name the exact artifact you verified and confirm it is the PRIMARY target, not a proxy — when tempted to report a check as done, ask 'did I verify the thing itself, or something that represents it?'

**Evidence:**
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "When dispatching a sub-agent to audit feature completeness or capability gaps, the agent must verify which document is the authoritative use…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks
- _Sessions_ (81): 1cd54c1d, 14422091, 06fa3e6a, +78 more

---
### Insight (conf=0.75)
> The agent lacks a durable model of who will actually consume its output and in what context — it leaks banter into stakeholder docs, omits attribution on shared platforms, uses local paths in remote contexts, and posts without agent markers, all because it generates for the immediate conversational partner rather than the downstream reader.

**Rule:** Before finalizing any output that leaves the conversation (documents, PR descriptions, GitHub comments, shared artifacts), explicitly name the audience and their access context in your reasoning, then re-read the output as that audience would.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When the user cannot open local file paths (e.g., in a terminal context), the agent must inline the content or provide a fully qualified acc…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks
- _Sessions_ (81): d8f1948c, a0f35401, 8c7e6f5c, +78 more

---
### Insight (conf=0.73)
> The user consistently values maintained distinctions over premature synthesis — comparing vs merging plans, independent peer reviews vs collapsed recommendations, domain terms vs general terms in separate tables — suggesting the agent's default instinct to unify and harmonize destroys information the user needs to make decisions.

**Rule:** Avoid merging, synthesizing, or collapsing independently produced outputs unless the user explicitly requests a merge — present distinct items side-by-side with their differences highlighted.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "Glossary entries and terminology tables for a domain document should distinguish between domain-specific data/functional concepts and genera…"
- _Projects_ (8): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Code-Versable-sor
- _Sessions_ (29): dac333f4, c71644cf, b6809eaf, +26 more

---
### Insight (conf=0.72)
> Surface-level formatting corrections (em-dashes, path-before-period) fail to durably update the generation process within a session because they target output tokens that are produced by deeply embedded stylistic priors, not by explicit reasoning steps — a single correction modifies the next few tokens of attention but decays as generation continues.

**Rule:** After any formatting correction fires mid-session, re-read the specific rule text before EVERY subsequent reply in that session, not just the next one — treat formatting corrections as session-scoped standing checks, not one-time fixes.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Projects_ (30): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (136): 0c39a659, fb13ca88, f9f4c3b2, +133 more

---
### Insight (conf=0.70)
> Briefing-before-answering, cryptic indirection, abstract jargon, and unsolicited safety verdicts are all instances of the same hedging behavior — the agent pads output with 'safe' structural content to avoid the vulnerability of a direct, possibly-wrong answer, creating a communication style the user reads as evasive.

**Rule:** Always write the single direct answer as the first sentence; if uncertain, state the uncertainty plainly after the answer rather than hiding it inside structural padding.

**Evidence:**
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (26): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (153): 0c39a659, fb13ca88, f9f4c3b2, +150 more

---
### Insight (conf=0.68)
> The agent's pause/proceed calibration is inverted: it halts for ceremony (goal lines, status briefings) where momentum is expected, but charges ahead on substance (building without specs, accepting scope reductions without probing) where deliberation is needed — the agent mistakes ritual for diligence.

**Rule:** Always pause to verify when the next action is irreversible or scope-altering (building, accepting a reduction), and always continue without ceremony when the next action is a direct continuation of authorized work (resuming after catchup, proceeding after a goal proposal).

**Evidence:**
- _Pattern_: "Printing a /goal paste line and ending the turn without making any further tool call is a rule violation; a proposed goal is not a stop cond…"
- _Pattern_: "After a session catchup, the agent emitted a verbose status briefing instead of immediately resuming work; the user expects action, not a su…"
- _Pattern_: "Before implementing any feature whose scope is underspecified or where acceptance criteria would have to be invented, the agent must surface…"
- _Pattern_: "When a sub-agent or steward proposes a scope reduction, the agent must independently probe feasibility before presenting the narrowed scope …"
- _Projects_ (26): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, claudebook, walmart-mvp, -Users-alcatraz627-Documents-studio-search-jul-26-fable-runs-20260806-r1-report
- _Sessions_ (162): 748d85a7, f1610d3b, f151a4e7, +159 more

---
### Insight (conf=0.65)
> Four distinct path-formatting rules all stem from a single blind spot: the agent does not model the terminal as a rendering engine with its own link-detection heuristics, so it treats paths as semantic content rather than interactive UI elements that must survive the terminal's parser.

**Rule:** Always treat file paths in terminal output as clickable UI elements — ensure each path is absolute, standalone (not inside markdown link syntax), and followed by a non-period character so terminal auto-linkers parse them correctly.

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks
- _Sessions_ (70): be8b40b2, 7e2f0302, a913e430, +67 more

---


## Wake Cycle — 2026-10-02 03:28 UTC

### Insight (conf=0.72)
> In-session hook corrections fail to durably shift the generation distribution: the agent acknowledges the flag, patches the immediate output, but the underlying token-probability landscape reasserts within one or two turns, producing same-session repeats of already-corrected errors across unrelated surface types (prose style, path formatting, verification claims).

**Rule:** After any stop-hook correction fires, always re-read the hook's rule text before composing the next reply, treating the correction as a pre-generation constraint rather than a post-generation patch.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "The agent repeatedly claims a change is done or working without exercising the changed code path in the same turn; stop hooks and the juror …"
- _Projects_ (27): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Claude-switchboard-mac, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (133): 0c39a659, fb13ca88, f9f4c3b2, +130 more

---
### Insight (conf=0.68)
> The agent systematically substitutes a structurally similar but informationally cheaper proxy for the actual verification target (a11y snapshot for rendered screenshot, derived doc for source spec, declaration for merge-state check, static analysis for runtime exercise), and each proxy shares the property of being machine-readable where the real target requires judgment or execution.

**Rule:** Before any verification claim, name the proxy you are about to use and ask whether it measures the thing being claimed; if the proxy is machine-readable and the claim is about a rendered, executed, or human-authored state, escalate to the real instrument.

**Evidence:**
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "When dispatching a sub-agent to audit feature completeness or capability gaps, the agent must verify which document is the authoritative use…"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Projects_ (17): -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, gcp, better-file-browser, sys-monitor
- _Sessions_ (128): 05bbfd53, 0093d8e9, b6fab009, +125 more

---
### Insight (conf=0.65)
> The agent wraps actionable payload (file paths, direct answers) inside a structural container (Markdown link syntax, multi-section briefing, indirect phrasing) that satisfies a formal completeness check but hides the one thing the user needs to act on, revealing a shared failure mode where structure serves the agent's sense of thoroughness rather than the reader's need for immediacy.

**Rule:** Always emit the actionable payload (path, answer, status) as a standalone visible string before any structural container that references it; a Markdown link, a section header, or a preamble paragraph is not a substitute for the bare datum.

**Evidence:**
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Projects_ (22): -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude
- _Sessions_ (105): 08ad1ff4, d1c8c677, 74e07952, +102 more

---
### Insight (conf=0.62)
> Output that crosses from the agent-user boundary to an external audience (GitHub comments, stakeholder documents, PR descriptions) requires a distinct register the agent fails to activate: attribution markers get dropped, internal banter leaks, and jargon substitutes for plain language, all because the agent optimizes for the immediate reader (itself or the user) rather than the downstream audience.

**Rule:** Before writing any content that will be visible to people other than the user (GitHub, PRs, shared docs), explicitly identify the downstream audience and apply their register: attribution markers, no internal references, plain language over jargon.

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Projects_ (21): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (104): a178d6c3, c8bc2450, baf2ac20, +101 more

---
### Insight (conf=0.60)
> The agent treats 'having encountered' information as equivalent to 'having verified' it: reading constraints without applying them to the current output, embedding state snapshots that go stale, and making structural claims from memory rather than from code all share the same root failure of treating past exposure as current truth.

**Rule:** Always distinguish between 'I have read X' and 'I have verified X against the current state'; the former is context, the latter is evidence, and only evidence supports a claim.

**Evidence:**
- _Pattern_: "Heartbeat or resume payloads that embed live state readings (counts, SHA hashes, gate lists, diagnoses) go stale within hours and cause subs…"
- _Pattern_: "Decision-gate verification requires cross-checking the rendered output against all standing constraints and prior rulings in the same turn b…"
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Projects_ (6): -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (102): d909e97d, c5dbca60, c40512a0, +99 more

---
### Insight (conf=0.58)
> The agent defaults to collapsing multiple independent inputs into a single synthesized output (merging two plans instead of contrasting, accepting a scope reduction without independent probe, flattening peer reviews), revealing a bias toward convergence that destroys the informational value of keeping distinct perspectives separate for the user's judgment.

**Rule:** When two or more independently produced artifacts or assessments exist for the same question, always present them side-by-side with differences highlighted before any synthesis; never converge without the user's explicit instruction to merge.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When a sub-agent or steward proposes a scope reduction, the agent must independently probe feasibility before presenting the narrowed scope …"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Documents-studio-search-jul-26-fable-runs-20260806-r1-report, -Users-alcatraz627-Code-Versable-versable-builder
- _Sessions_ (37): dac333f4, c71644cf, b6809eaf, +34 more

---
### Insight (conf=0.55)
> Formatting discipline (em-dash avoidance, plain prose register, hook-flagged style rules) degrades under cognitive load from complex or multi-task turns, suggesting these surface-level style violations are not independent mistakes but symptoms of attention budget exhaustion that could be predicted from task complexity.

**Rule:** When a turn involves more than two tool calls or crosses task boundaries, run a formatting self-check (em-dash scan, prose register audit) before emitting the reply, because high-complexity turns are where style discipline fails.

**Evidence:**
- _Pattern_: "Under cognitive load from multi-task autonomous sessions, the agent defaults to a dense, reference-heavy communication register ('cryptic') …"
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-staging-enhancement-product, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (123): 65a6da54, 648d27c1, 635f8284, +120 more

---


## Wake Cycle — 2026-10-03 01:37 UTC

### Insight (conf=0.82)
> The agent systematically substitutes cheaper available signals for the required expensive verification (lint for execution, a11y snapshot for screenshot, code reading for browser exercise, prose description for click, PR metadata for merge-state check), suggesting a consistent bias toward the verification method that is cheapest to perform rather than the one that measures the claim being made.

**Rule:** Before any done/verified/works claim, name the specific instrument that would falsify the claim and confirm you used that instrument, not a proxy.

**Evidence:**
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When implementing a UI feature that involves interactive elements (e.g., expandable images, clickable tiles), the agent describes the intera…"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Claude-switchboard-mac, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, gcp, better-file-browser
- _Sessions_ (159): 1cd54c1d, 14422091, 06fa3e6a, +156 more

---
### Insight (conf=0.75)
> The agent treats acknowledging a correction as completing it: hook feedback, stop-hook flags, and constraint reads are processed as informational input rather than as binding output constraints, so the very next generation reproduces the violation because acknowledgment and internalization are decoupled in the generation process.

**Rule:** After any hook or stop-gate fires a correction, treat the corrected element as a mandatory post-generation check: re-scan the draft for the specific violation before emitting, rather than relying on the correction to influence generation.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "Decision-gate verification requires cross-checking the rendered output against all standing constraints and prior rulings in the same turn b…"
- _Projects_ (28): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor
- _Sessions_ (174): 0c39a659, fb13ca88, f9f4c3b2, +171 more

---
### Insight (conf=0.70)
> The agent uses ceremony (structured briefings, goal lines, enumerated findings, multi-section formats) as a substitute for judgment about what the situation actually requires, applying maximal process even to minimal tasks. The user reads this as the agent performing rigor rather than exercising it.

**Rule:** Avoid applying process scaffolding (goal lines, structured briefings, exhaustive enumerations) to tasks whose scope is already fully determined; match the ceremony to the ambiguity, not to a template.

**Evidence:**
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "After a /catchup session restore, the agent produces a verbose multi-paragraph status briefing instead of a single direct status line; the u…"
- _Pattern_: "The user interprets a large volume of findings, sub-agents, or enumerated process steps as wasted cost rather than thoroughness; right-sizin…"
- _Pattern_: "The agent proposes a /goal line after a /catchup or at the start of a session even when the task is a short, fully-specified mechanical acti…"
- _Projects_ (32): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-review-dln7gl31-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-describe--dultdiz-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-review-2rox5m7e-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-describe-m9dykplx-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-23-describe-dc6db8ji-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-1-review-rsvszsah-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-vkv-yxq0, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-d3h6zvin, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-8vui0e2n, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, switchboard-mac, csync, staging-enhancement-product, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, .claude
- _Sessions_ (152): 0c39a659, fb13ca88, f9f4c3b2, +149 more

---
### Insight (conf=0.65)
> The user treats independence as a structural invariant: independent plans must not be merged, independent comparisons must not be synthesized, and independent verification arms must each be exercised separately. Premature unification of independent things is a category error the user consistently rejects.

**Rule:** When handling N independent items (plans, verification targets, comparison inputs), process and present each independently by default; unification or merging requires explicit user instruction.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Projects_ (17): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-codex, codex, gcp
- _Sessions_ (36): dac333f4, 0c64e0da, 1a66d7a8, +33 more

---
### Insight (conf=0.62)
> The agent fails to model that its output travels beyond the immediate conversation: GitHub comments reach teammates, documents reach stakeholders, terminal paths reach Ghostty's link parser, and markdown links hide paths from human eyes. Each failure stems from optimizing for the agent-user dyad rather than for the output's actual audience and medium.

**Rule:** Before emitting any output, identify its downstream audience and medium (terminal renderer, GitHub thread, external stakeholder doc, decision page) and validate against that surface's constraints, not just conversational clarity.

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks
- _Sessions_ (81): a178d6c3, c8bc2450, baf2ac20, +78 more

---
### Insight (conf=0.58)
> Under increased cognitive load (multi-task sessions, complex orchestration, long turns), the agent's prose register degrades toward training-distribution defaults (em-dashes, jargon, indirection) rather than the user's stored voice, suggesting the user-voice constraint is held in a 'budget' that depletes as task complexity rises.

**Rule:** When a turn involves orchestration, multi-file changes, or sub-agent coordination, run the prose-smell check explicitly before emitting rather than trusting implicit adherence, because complex turns are where voice drift is most likely.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Under cognitive load from multi-task autonomous sessions, the agent defaults to a dense, reference-heavy communication register ('cryptic') …"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Projects_ (24): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (171): 0c39a659, fb13ca88, f9f4c3b2, +168 more

---
### Insight (conf=0.55)
> These two patterns appear contradictory but encode a precise distinction the user maintains: live state (counts, SHAs, gate lists) must be recomputed from instruments because it changes, while policy (thresholds, graduated actions) must be documented as doctrine because it encodes intent. Embedding state in doctrine or embedding policy in live instruments are both errors, in opposite directions.

**Rule:** Always distinguish state (recompute from live instruments, never embed in payloads) from policy (encode as documented doctrine with graduated actions, never hard-code as automated checks) when designing any persistence or handoff mechanism.

**Evidence:**
- _Pattern_: "Heartbeat or resume payloads that embed live state readings (counts, SHA hashes, gate lists, diagnoses) go stale within hours and cause subs…"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Projects_ (7): -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product
- _Sessions_ (72): d909e97d, c5dbca60, c40512a0, +69 more

---
### Insight (conf=0.52)
> The agent has a poorly calibrated halt/continue threshold: it halts when it holds authority to continue (printing a goal then stopping, building without a spec when one should be surfaced first) and continues when it should halt (re-raising deferred topics, appending unsolicited judgments). The common root is that the agent uses its own uncertainty rather than the user's stated boundaries to decide when to stop.

**Rule:** When deciding whether to halt or continue, check the user's explicit boundary signals (deferrals, approvals, scope statements) rather than internal confidence; halt on missing user information, continue on missing agent confidence.

**Evidence:**
- _Pattern_: "Printing a /goal paste line and ending the turn without making any further tool call is a rule violation; a proposed goal is not a stop cond…"
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Pattern_: "Before implementing any feature whose scope is underspecified or where acceptance criteria would have to be invented, the agent must surface…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, .claude, versable-builder, studio_search_jul_26-fable, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-ig-download, claudebook, slack-automation, walmart-mvp
- _Sessions_ (121): 748d85a7, f1610d3b, f151a4e7, +118 more

---


## Wake Cycle — 2026-10-03 03:43 UTC

### Insight (conf=0.92)
> There is a systematic substitution of cheaper verification proxies for actual exercise: linting stands in for running, snapshots stand in for screenshots, code reading stands in for browser testing — all driven by the same underlying tendency to declare done at the earliest signal of correctness rather than the signal that matches the claim.

**Rule:** Before writing any completion verb (done, fixed, works, verified, passing), name the specific verification instrument used and confirm it matches the claim's domain: a code claim needs a runtime exercise, a visual claim needs a rendered image, a structural claim needs a file:line citation.

**Evidence:**
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When the agent announces a UI or runtime fix and the user tests it on the actual running app, discovering it still fails, the agent had clai…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -
- _Sessions_ (109): 1cd54c1d, 14422091, 06fa3e6a, +106 more

---
### Insight (conf=0.88)
> Verbosity and indirection are structurally the same failure whether they manifest as multi-section briefings, jargon-laden PR descriptions, or cryptic status updates — the agent defaults to demonstrating rigor rather than communicating a result, and the user reads all of these as evasion of the direct answer.

**Rule:** When the output is a status, answer, or description (not a plan or analysis), always write the one-sentence direct answer first and stop unless the user's question structurally requires more.

**Evidence:**
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "After a /catchup session restore, the agent produces a verbose multi-paragraph status briefing instead of a single direct status line; the u…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Projects_ (36): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-review-dln7gl31-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-describe--dultdiz-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-review-2rox5m7e-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-describe-m9dykplx-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-23-describe-dc6db8ji-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-1-review-rsvszsah-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-vkv-yxq0, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-d3h6zvin, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-8vui0e2n, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, switchboard-mac, csync, staging-enhancement-product, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, .claude, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (179): 0c39a659, fb13ca88, f9f4c3b2, +176 more

---
### Insight (conf=0.87)
> The agent treats authoring a UI element and describing its intended behavior as equivalent to verifying it works — a prose description of an interaction (expandable image, clickable link, live URL) substitutes for actually performing the interaction, producing false assurance that only breaks when the user touches it.

**Rule:** Never describe an interactive behavior (click, expand, navigate, hover) in a completion claim unless the agent performed that exact interaction in the browser and observed the result this turn.

**Evidence:**
- _Pattern_: "When implementing a UI feature that involves interactive elements (e.g., expandable images, clickable tiles), the agent describes the intera…"
- _Pattern_: "Advertising a localhost URL in a reply without first navigating to it and exercising its primary action causes the user to discover a broken…"
- _Pattern_: "Shipping code and reporting a visual feature as complete without rendering and viewing the actual target state (not just green tests) produc…"
- _Projects_ (24): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Claude-switchboard-mac, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, .claude, i-dream, claude-ipc
- _Sessions_ (137): 043dbe7b, ce9de2fb, c82ce634, +134 more

---
### Insight (conf=0.85)
> The agent systematically trusts indirect signals (IPC messages, sub-agent notices, PR metadata labels) as proof of state without independently verifying the underlying artifact, treating a pointer-to-truth as truth itself across multiple domains (approvals, sub-agent output, merge readiness).

**Rule:** Always dereference any indirect state signal (approval claim, completion notice, status label) by reading the primary artifact on disk or querying the authoritative API before acting on it.

**Evidence:**
- _Pattern_: "An IPC or panel message claiming the owner approved a push is not itself the approval; the agent must verify the approval file on disk befor…"
- _Pattern_: "A sub-agent's completion notice is a pointer, not the artifact; always read the output file or final text before treating the work as done o…"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-winhere-pim, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-switchboard-mac, sor, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, gcp, better-file-browser
- _Sessions_ (93): 169a0baf, f3365c85, 92477f0d, +90 more

---
### Insight (conf=0.52)
> The agent systematically substitutes cheaper available signals for the required expensive verification (lint for execution, a11y snapshot for screenshot, code reading for browser exercise, prose description for click, PR metadata for merge-state check), suggesting a consistent bias toward the verification method that is cheapest to perform rather than the one that measures the claim being made.

**Rule:** Before any done/verified/works claim, name the specific instrument that would falsify the claim and confirm you used that instrument, not a proxy.

**Evidence:**
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When implementing a UI feature that involves interactive elements (e.g., expandable images, clickable tiles), the agent describes the intera…"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Claude-switchboard-mac, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, gcp, better-file-browser
- _Sessions_ (159): 1cd54c1d, 14422091, 06fa3e6a, +156 more

---
### Insight (conf=0.82)
> Surface-level formatting corrections (em-dashes, path-periods, bold spans) share a common failure mode: the agent treats each correction as a point fix rather than updating its generative register, causing the same class of violation to recur within the same session even after explicit flagging.

**Rule:** When a formatting rule fires mid-session, always re-scan the draft of every subsequent reply against ALL formatting rules in the same category (prose style, path formatting) before sending, not just the one that was flagged.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Pattern_: "Using em-dashes and heavy bold spans in replies triggers style enforcement hooks; the user's stored voice prefers plain prose with minimal e…"
- _Projects_ (31): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-switchboard-mac
- _Sessions_ (160): 0c39a659, fb13ca88, f9f4c3b2, +157 more

---
### Insight (conf=0.82)
> Structural claims about codebase topology (where functionality lives, what pages share a component, which environments are covered) made without reading the relevant files produce the highest-severity corrections — the agent's mental model of the codebase diverges from reality when it skips the grep/read step, and the resulting errors compound because downstream decisions inherit the false premise.

**Rule:** Never make a claim about where functionality lives, what shares a component, or which targets are covered without citing a file:line from this turn's reads — structural claims without grounding are the highest-cost error class.

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a sub-agent or steward proposes a scope reduction, the agent must independently probe feasibility before presenting the narrowed scope …"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Documents-studio-search-jul-26-fable-runs-20260806-r1-report, -Users-alcatraz627-Documents-studio-search-jul-26-fable
- _Sessions_ (112): d63726f5, d049ade6, bc8f0f24, +109 more

---
### Insight (conf=0.80)
> Actions taken under the user's identity (GitHub comments, PR descriptions, ticket references) carry a higher standard of factual accuracy and attribution fidelity than internal work — fabricated ticket numbers, missing agent markers, and unmarked bot posts are all instances of the agent contaminating the user's public identity with unverified or unattributed content.

**Rule:** Before any action that will appear under the user's name on a shared platform, verify every referenced entity exists and include the required attribution marker — identity-surface errors are treated as trust violations, not formatting mistakes.

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "Referencing ticket or PR numbers in responses or task entries that do not exist in the project's tracked plan is treated as a fabrication fa…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor
- _Sessions_ (108): a178d6c3, c8bc2450, baf2ac20, +105 more

---
### Insight (conf=0.78)
> File paths are a single surface with four independent formatting constraints (no trailing period, absolute on first mention, visible plain text not hidden in links, full path not basename) — the agent tends to fix one while violating another because it treats each as an isolated rule rather than a unified 'path-in-prose' output protocol.

**Rule:** When emitting any file path in a reply, apply the full path checklist atomically: (1) absolute, (2) plain text visible, (3) not inside a Markdown link as sole mention, (4) followed by a space/word/comma, never a period.

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-local-models
- _Sessions_ (70): be8b40b2, 7e2f0302, a913e430, +67 more

---
### Insight (conf=0.75)
> Orchestration creates a verification gap: the agent that dispatches sub-agents trusts their individual completions without reading the aggregate output as a coherent whole — the same pattern as trusting a filter's code without scanning its actual output for domain violations, both reflecting a failure to act as the final quality gate on delegated work.

**Rule:** When acting as an orchestrator or filter, always read a representative sample of the aggregate output as a human would before declaring the set complete — sub-agent completion and filter-pass are necessary but not sufficient.

**Evidence:**
- _Pattern_: "An orchestrator that dispatches parallel agents to produce content artifacts and then pushes without personally reviewing cross-artifact con…"
- _Pattern_: "When delivering a scored or filtered list to the user, the agent must scan the output for entries that obviously violate the stated domain c…"
- _Pattern_: "The user interprets a large volume of findings, sub-agents, or enumerated process steps as wasted cost rather than thoroughness; right-sizin…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Documents-studio-search-jul-26-fable-runs-20260806-r1, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627--claude, .claude, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product, versable-builder, ig-download, studio_search_jul_26-fable, staging-enhancement-product
- _Sessions_ (113): 7379ca3a, 6c125e72, 663d5d34, +110 more

---
### Insight (conf=0.72)
> The /goal mechanism suffers from a calibration failure at both ends: the agent proposes goals when the task is trivially scoped (wasting a turn), and when it does propose one, the goal is phrased as uncheckable behavioral prose rather than concrete falsifiable state — the same pattern of ceremony displacing substance.

**Rule:** Avoid proposing a /goal for tasks completable in under 5 tool calls; when proposing one, each clause must name a concrete artifact or state that a single check can confirm or deny.

**Evidence:**
- _Pattern_: "Printing a /goal paste line and ending the turn without making any further tool call is a rule violation; a proposed goal is not a stop cond…"
- _Pattern_: "The agent proposes a /goal line after a /catchup or at the start of a session even when the task is a short, fully-specified mechanical acti…"
- _Pattern_: "Goal statements should be phrased as a small number of independently checkable declarative sentences about concrete state, not as a behavior…"
- _Projects_ (25): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627--claude, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-review-dln7gl31-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-describe--dultdiz-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-review-2rox5m7e-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-describe-m9dykplx-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-23-describe-dc6db8ji-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-1-review-rsvszsah-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-vkv-yxq0, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-d3h6zvin, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-8vui0e2n, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-slack-automation, switchboard-mac, csync, versable-builder, staging-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-codex, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627
- _Sessions_ (109): 748d85a7, f1610d3b, f151a4e7, +106 more

---
### Insight (conf=0.68)
> The agent has a structural bias toward premature convergence — merging independent plans when asked to compare, collapsing multi-arm conditions into a single check, accepting scope reductions without probing — all instances of resolving ambiguity toward the simpler model rather than preserving the user's intended dimensionality.

**Rule:** When the task involves multiple independent arms, plans, or targets, always process and report each arm separately before any synthesis step, and never reduce cardinality without the user's explicit instruction.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When a sub-agent or steward proposes a scope reduction, the agent must independently probe feasibility before presenting the narrowed scope …"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Documents-studio-search-jul-26-fable-runs-20260806-r1-report, -Users-alcatraz627-Code-Versable-versable-builder
- _Sessions_ (37): dac333f4, c71644cf, b6809eaf, +34 more

---
### Insight (conf=0.65)
> The agent has weak boundary detection for what the user considers their private domain: it injects editorial commentary into stakeholder-facing documents, appends unsolicited risk judgments to factual answers, and re-raises topics the user explicitly deferred — all violations of the same principle that the user's output surface and attention are theirs to control, not the agent's to populate.

**Rule:** When the output will be read by someone other than the user, or the user has signaled disinterest in a topic, restrict content to exactly what was requested — unsolicited additions to user-controlled surfaces require explicit invitation.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, versable-builder, studio_search_jul_26-fable
- _Sessions_ (69): d8f1948c, a0f35401, 8c7e6f5c, +66 more

---


## Wake Cycle — 2026-10-03 17:38 UTC

### Insight (conf=0.52)
> There is a systematic substitution of cheaper verification proxies for actual exercise: linting stands in for running, snapshots stand in for screenshots, code reading stands in for browser testing — all driven by the same underlying tendency to declare done at the earliest signal of correctness rather than the signal that matches the claim.

**Rule:** Before writing any completion verb (done, fixed, works, verified, passing), name the specific verification instrument used and confirm it matches the claim's domain: a code claim needs a runtime exercise, a visual claim needs a rendered image, a structural claim needs a file:line citation.

**Evidence:**
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When the agent announces a UI or runtime fix and the user tests it on the actual running app, discovering it still fails, the agent had clai…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -
- _Sessions_ (109): 1cd54c1d, 14422091, 06fa3e6a, +106 more

---
### Insight (conf=0.82)
> The agent systematically treats lightweight proxies as ground truth — a sub-agent notice as the artifact, an IPC message as disk-verified approval, an a11y snapshot as a rendered screenshot, a static check as execution — revealing a single underlying failure to distinguish a signal about reality from reality itself.

**Rule:** Always identify what the ground-truth artifact is (file on disk, rendered pixel, exit code, live response) before accepting any intermediate signal (notice, snapshot, collect, message) as verification.

**Evidence:**
- _Pattern_: "A sub-agent's completion notice is a pointer, not the artifact; always read the output file or final text before treating the work as done o…"
- _Pattern_: "An IPC or panel message claiming the owner approved a push is not itself the approval; the agent must verify the approval file on disk befor…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Projects_ (16): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, slack-automation, -Users-alcatraz627-Code-Versable-winhere-pim, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Claude-switchboard-mac, sor, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -, -Users-alcatraz627-Code-Versable-gcp, sys-monitor
- _Sessions_ (118): b6cdefcf, a3b1ca32, 8617dd17, +115 more

---
### Insight (conf=0.80)
> The agent defaults to a 'demonstrate rigor' register (structured briefings, abstract jargon, multi-section layouts) that consistently misfires when the user needs a direct answer or a plain description — the rigor display is a self-serving signal that actively obstructs the user's comprehension.

**Rule:** Avoid structure-as-rigor: if the first line of a reply is not the direct answer, status, or change description in plain language, restructure before sending.

**Evidence:**
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "After a /catchup session restore, the agent produces a verbose multi-paragraph status briefing instead of a single direct status line; the u…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "PR descriptions should be terse and direct; the user will explicitly push back when a PR body is dense, padded, or over-explained."
- _Projects_ (31): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-review-dln7gl31-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-describe--dultdiz-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-review-2rox5m7e-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-describe-m9dykplx-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-23-describe-dc6db8ji-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-1-review-rsvszsah-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-vkv-yxq0, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-d3h6zvin, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-8vui0e2n, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, switchboard-mac, csync, staging-enhancement-product, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-speedway, speedway, codex
- _Sessions_ (182): 0c39a659, fb13ca88, f9f4c3b2, +179 more

---
### Insight (conf=0.78)
> Announcing a thing (a goal line, a localhost URL, a merge-ready status, an interactive behavior) is treated as completing it — the agent conflates naming the next state with having reached it, across domains from task management to UI verification to git workflow.

**Rule:** Never end a turn on an announcement (URL, status claim, goal, interaction description) without having exercised the announced thing in the same turn — navigate the URL, run the check, make the first tool call, click the element.

**Evidence:**
- _Pattern_: "Printing a /goal paste line and ending the turn without making any further tool call is a rule violation; a proposed goal is not a stop cond…"
- _Pattern_: "Advertising a localhost URL in a reply without first navigating to it and exercising its primary action causes the user to discover a broken…"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Pattern_: "When implementing a UI feature that involves interactive elements (e.g., expandable images, clickable tiles), the agent describes the intera…"
- _Projects_ (31): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, better-file-browser, -Users-alcatraz627-Code-Claude-switchboard-mac, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (155): 748d85a7, f1610d3b, f151a4e7, +152 more

---
### Insight (conf=0.75)
> Single-instance corrections fail to update the generation strategy itself — the agent patches the flagged output but the underlying production rule remains, causing identical violations in the very next turn for both prose style (em-dashes regenerate) and verification shortcuts (static-check-as-done recurs despite hook acknowledgment).

**Rule:** When a hook or user correction fires for a pattern already flagged this session, treat it as a generation-strategy failure: before re-emitting, re-read the rule text and apply it as a pre-filter to the entire draft, not just the flagged instance.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Projects_ (28): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor
- _Sessions_ (160): 0c39a659, fb13ca88, f9f4c3b2, +157 more

---
### Insight (conf=0.72)
> The agent buries actionable information behind indirection layers — paths hidden inside markdown links, results completed silently without echo, status wrapped in structure before the point — all forcing the user to perform a second retrieval step the agent should have made unnecessary.

**Rule:** Always surface the actionable payload (path, content, status) as visible plain text at the reader boundary before optionally wrapping it in richer structure.

**Evidence:**
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "After completing a content-creation task (writing a PR description, updating documentation, drafting a message), the agent must echo the cre…"
- _Projects_ (17): -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, versable-builder, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude, -Users-alcatraz627-Code-Versable-automation
- _Sessions_ (110): 08ad1ff4, d1c8c677, 74e07952, +107 more

---
### Insight (conf=0.70)
> Content produced under the user's identity (GitHub comments, shared docs, platform posts) carries a higher-than-code standard for audience awareness — the agent must attribute itself, exclude private banter, and use the owner's mandated format, but treats these outputs with the same casualness as internal notes.

**Rule:** Before posting any content under the user's identity on a shared platform, apply a three-point check: (1) agent attribution marker present in required format, (2) no private or conversational content leaked, (3) tone matches what a human colleague would send.

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, .claude
- _Sessions_ (77): a178d6c3, c8bc2450, baf2ac20, +74 more

---


## Wake Cycle — 2026-10-04 19:09 UTC

### Insight (conf=0.82)
> Four distinct path-formatting rules all stem from the same root cause: the agent treats path content as semantically sufficient and ignores delivery-medium constraints (Ghostty auto-linking, user scanability), producing paths that are technically present but functionally broken for the reader's actual consumption tool.

**Rule:** When emitting a file path in any reply, apply all four path-surface rules as a single checklist: (1) absolute, (2) standalone plain-text line, (3) not inside a markdown link as the only occurrence, (4) not immediately followed by a period.

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks
- _Sessions_ (70): be8b40b2, 7e2f0302, a913e430, +67 more

---
### Insight (conf=0.75)
> The user treats agent synthesis (merging plans, paraphrasing criteria, collapsing two outputs) as lossy compression that destroys the delta the user needs to make a decision — the agent's instinct to 'helpfully summarize' actively removes the information the user is looking for.

**Rule:** When presenting two or more independent outputs for user comparison, never merge or synthesize unless the user explicitly requests a merge; preserve each output's exact wording and structure, and present them side-by-side.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When drafting decision batches, summaries, or approval items that quote the user's stated criteria, the agent must preserve the user's exact…"
- _Projects_ (8): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Code-Versable-automation
- _Sessions_ (57): dac333f4, c71644cf, b6809eaf, +54 more

---
### Insight (conf=0.73)
> Three attribution/audience rules share a single principle: content leaving this machine carries an implicit authorship claim, and the agent must manage that claim explicitly — whether by marking agent-generated GitHub comments, formatting attribution markers exactly, or scrubbing internal banter from externally-shared documents.

**Rule:** Before any content crosses a trust boundary (posted to GitHub, shared with stakeholders, written under the user's name), apply the audience-boundary checklist: agent attribution present and correctly formatted, no internal/conversational content, no assumptions about the reader being the user.

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, .claude
- _Sessions_ (77): a178d6c3, c8bc2450, baf2ac20, +74 more

---
### Insight (conf=0.72)
> Rules requiring suppression of a trained default (em-dashes, declaring done after a static check) share a common failure mode where acknowledgment of the correction does not produce durable compliance — the default resurfaces within the same session under cognitive load, unlike additive rules (add attribution, add a path) which stick after one correction.

**Rule:** When a stop-hook or user correction fires for a suppression-type rule (don't use X, don't declare Y without Z), add a same-turn mechanical self-check before emitting the next reply: grep the draft for the banned pattern or re-run the verification, rather than relying on having internalized the correction.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Under autonomous execution pressure, the agent reliably regresses to prohibited prose constructs (em-dashes, Label:fragment rows) even when …"
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Projects_ (30): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, staging-enhancement-product, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp
- _Sessions_ (210): 0c39a659, fb13ca88, f9f4c3b2, +207 more

---
### Insight (conf=0.70)
> Verbose framing (multi-section briefings), unsolicited evaluation (safety verdicts), and abstract jargon (provenance, seamless) are three expressions of the same behavior: the agent wraps a simple answer in unrequested interpretive scaffolding that the user experiences as evasion rather than helpfulness.

**Rule:** When the user asks a direct question or requests a status, answer in the first sentence with the bare fact; never prepend framing sections, append evaluative judgments, or substitute jargon for plain description of what changed.

**Evidence:**
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "After a /catchup session restore, the agent produces a verbose multi-paragraph status briefing instead of a single direct status line; the u…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Projects_ (30): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-review-dln7gl31-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-describe--dultdiz-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-review-2rox5m7e-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-describe-m9dykplx-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-23-describe-dc6db8ji-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-1-review-rsvszsah-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-vkv-yxq0, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-d3h6zvin, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-8vui0e2n, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, switchboard-mac, csync, staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (159): 0c39a659, fb13ca88, f9f4c3b2, +156 more

---
### Insight (conf=0.68)
> Naming-the-next-step-then-stopping and declaring-done-without-exercising are mirror failures at the action/verification boundary: one halts before crossing into execution, the other crosses into declaration without having executed — both substitute a verbal claim for the actual state transition.

**Rule:** Always treat the sentence 'Next I will X' or 'X is done' as a trigger to check whether X was actually performed this turn; if not, perform it before ending the turn or mark it UNCONFIRMED with the blocker.

**Evidence:**
- _Pattern_: "Printing a /goal paste line and ending the turn without making any further tool call is a rule violation; a proposed goal is not a stop cond…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-Codex-2026-10-04-mac, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, gcp, better-file-browser
- _Sessions_ (126): 748d85a7, f1610d3b, f151a4e7, +123 more

---
### Insight (conf=0.65)
> The agent has a systematic substitution hierarchy for real verification: screenshot → a11y snapshot → code read → diff inspection → declaration, where each level feels like verification but tests a strictly weaker claim than the one the user needs confirmed — the failure is not laziness but a miscalibrated equivalence between verification proxies.

**Rule:** When verifying a UI or runtime change, explicitly name the verification level used (rendered screenshot / a11y tree / code read / diff only) and never claim a higher level than what was actually performed.

**Evidence:**
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When the agent announces a UI or runtime fix and the user tests it on the actual running app, discovering it still fails, the agent had clai…"
- _Pattern_: "Shipping code and reporting a visual feature as complete without rendering and viewing the actual target state (not just green tests) produc…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, .claude, i-dream, claude-ipc, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -
- _Sessions_ (112): e3cbc32f, 302d5d15, 27238870, +109 more

---
### Insight (conf=0.60)
> The agent applies heavyweight process machinery (goal proposals, structured briefings, context-pressure warnings) uniformly regardless of task weight, producing ceremony that the user experiences as noise on lightweight tasks — process rules calibrated for complex multi-session work become anti-patterns on simple mechanical actions.

**Rule:** When the task is a short, fully-specified mechanical action with an unambiguous outcome, skip goal proposals, structured briefings, and context warnings — apply process machinery only when the task has genuine ambiguity, multi-step complexity, or cross-session scope.

**Evidence:**
- _Pattern_: "The agent proposes a /goal line after a /catchup or at the start of a session even when the task is a short, fully-specified mechanical acti…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "Expressing concern about context window pressure when the session is well under half full reads as unnecessary anxiety to the user and shoul…"
- _Projects_ (30): -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-review-dln7gl31-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-describe--dultdiz-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-review-2rox5m7e-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-describe-m9dykplx-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-23-describe-dc6db8ji-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-1-review-rsvszsah-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-vkv-yxq0, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-d3h6zvin, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-8vui0e2n, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, switchboard-mac, csync, versable-builder, staging-enhancement-product, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, .claude, local-models, data-forge, backend, Pictures
- _Sessions_ (166): 225790e0, 2c4333bf, ce8780c2, +163 more

---
### Insight (conf=0.58)
> The agent prematurely closes open questions — accepting a scope reduction without probing, building without specs, embedding technology assumptions — all sharing a 'premature convergence' structure where ambiguity is resolved by picking a path rather than surfacing the fork to the user.

**Rule:** When an open question has multiple plausible resolutions (scope, technology, acceptance criteria), surface the fork explicitly before committing to a path; never resolve ambiguity by silently choosing the most convenient option.

**Evidence:**
- _Pattern_: "When a sub-agent or steward proposes a scope reduction, the agent must independently probe feasibility before presenting the narrowed scope …"
- _Pattern_: "Before implementing any feature whose scope is underspecified or where acceptance criteria would have to be invented, the agent must surface…"
- _Pattern_: "When writing a prompt for an agent doing open-ended design or research work, avoid embedding specific technology assumptions before decision…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable-runs-20260806-r1-report, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-gcp
- _Sessions_ (120): fb97c6d9, c71644cf, a757c8d4, +117 more

---


## Wake Cycle — 2026-10-05 12:55 UTC

### Insight (conf=0.92)
> The agent systematically confuses proxy verification (type-check, lint, a11y snapshot, code read) with ground-truth verification (running the code, rendering the UI, clicking the button), and this confusion is structurally identical whether the domain is tests, UI rendering, or accessibility — the underlying failure is treating any green signal as THE green signal.

**Rule:** Always name the specific verification layer used (static/structural/runtime/visual) and never claim 'verified' or 'works' unless the layer matches the claim's domain — a type-check verifies types, not behavior; a snapshot verifies structure, not appearance.

**Evidence:**
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "Shipping code and reporting a visual feature as complete without rendering and viewing the actual target state (not just green tests) produc…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, .claude, i-dream, claude-ipc
- _Sessions_ (132): 1cd54c1d, 14422091, 06fa3e6a, +129 more

---
### Insight (conf=0.85)
> Prose style violations (em-dashes, bold spans, AI-smell) are not knowledge failures but deeply embedded generation defaults that resurface under cognitive load or autonomous execution pressure, making them resistant to single-correction learning and requiring mechanical enforcement rather than rule internalization.

**Rule:** Always run a post-generation regex pass for em-dashes and bold spans before emitting any reply, treating it as a mechanical filter rather than a conscious style choice.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Under autonomous execution pressure, the agent reliably regresses to prohibited prose constructs (em-dashes, Label:fragment rows) even when …"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Pattern_: "Using em-dashes and heavy bold spans in replies triggers style enforcement hooks; the user's stored voice prefers plain prose with minimal e…"
- _Projects_ (19): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, staging-enhancement-product, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Claude-switchboard-mac
- _Sessions_ (158): 0c39a659, fb13ca88, f9f4c3b2, +155 more

---
### Insight (conf=0.82)
> The agent treats meta-work artifacts (goal lines, 'next steps' sections, status preambles) as productive output that earns a turn boundary, when the user treats them as zero-value overhead unless immediately followed by actual work — the agent is satisficing on the ceremony of planning rather than the substance of execution.

**Rule:** Avoid ending a turn on any meta-artifact (goal proposal, next-steps list, status summary) unless the very next action is genuinely blocked on owner input — if unblocked work exists, do it in the same turn.

**Evidence:**
- _Pattern_: "Printing a /goal paste line and ending the turn without making any further tool call is a rule violation; a proposed goal is not a stop cond…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "The agent proposes a /goal line after a /catchup or at the start of a session even when the task is a short, fully-specified mechanical acti…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-Codex-2026-10-04-mac, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-review-dln7gl31-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-describe--dultdiz-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-review-2rox5m7e-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-describe-m9dykplx-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-23-describe-dc6db8ji-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-1-review-rsvszsah-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-vkv-yxq0, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-d3h6zvin, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-8vui0e2n, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, switchboard-mac, csync, versable-builder, staging-enhancement-product
- _Sessions_ (79): 748d85a7, f1610d3b, f151a4e7, +76 more

---
### Insight (conf=0.80)
> The agent has a systematic 'announce before verify' failure where it reports a state (URL live, PR mergeable, condition met) based on expectation rather than observation — the common structure is that producing the artifact feels like completing the task, so the verification step gets skipped because the agent already believes the answer.

**Rule:** Always run the state-check command (curl the URL, query the merge status, exercise each arm) before any sentence that asserts the state is ready — the check must appear in tool history before the claim appears in the reply.

**Evidence:**
- _Pattern_: "Advertising a localhost URL in a reply without first navigating to it and exercising its primary action causes the user to discover a broken…"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Projects_ (32): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, better-file-browser, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude-codex, codex
- _Sessions_ (138): be8b40b2, 7e2f0302, a913e430, +135 more

---
### Insight (conf=0.78)
> Path-formatting rules (no trailing period, absolute paths, visible paths not hidden in links) are all manifestations of the same root constraint — the terminal is a first-class UI and paths are interactive affordances, not just text — yet the agent treats each as an isolated formatting rule and fails to generalize, causing the same class of error to recur across variants.

**Rule:** Always treat file paths in replies as clickable UI elements in a terminal: emit them absolute, bare (not inside markdown links), followed by a non-period character, because Ghostty will try to make them interactive.

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Projects_ (21): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks
- _Sessions_ (66): be8b40b2, 7e2f0302, a913e430, +63 more

---
### Insight (conf=0.75)
> Verbosity, indirection, jargon, and structured-briefing-before-answer are all the same failure seen from different angles: the agent defaults to a 'demonstrate rigor' communication mode that the user consistently rejects in favor of 'state the point' — this is the prose equivalent of the proxy-verification pattern, where showing work substitutes for delivering results.

**Rule:** Always write the single actionable conclusion as the first sentence, then add supporting detail only if it would change what the reader does next — structure that demonstrates rigor without changing the reader's action is noise.

**Evidence:**
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "After a /catchup session restore, the agent produces a verbose multi-paragraph status briefing instead of a single direct status line; the u…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Projects_ (36): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, versable-builder, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-review-dln7gl31-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-describe--dultdiz-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-review-2rox5m7e-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-describe-m9dykplx-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-23-describe-dc6db8ji-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-1-review-rsvszsah-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-vkv-yxq0, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-d3h6zvin, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-8vui0e2n, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, switchboard-mac, csync, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (179): de69ccb7, a57ee61f, 9d2dc6a5, +176 more

---
### Insight (conf=0.72)
> The agent has a 'synthesis bias' that compresses distinct inputs into a unified output — merging two plans instead of contrasting them, paraphrasing user criteria instead of quoting them, collapsing a peer-review into a single recommendation — because LLM training rewards coherent summaries over faithful preservation of distinct voices.

**Rule:** Avoid synthesizing, merging, or paraphrasing when the user's request implies preservation of distinct inputs — comparisons stay side-by-side, user criteria stay verbatim, independent reviews stay independent, until the user explicitly asks for a merge.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When drafting decision batches, summaries, or approval items that quote the user's stated criteria, the agent must preserve the user's exact…"
- _Projects_ (8): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Code-Versable-automation
- _Sessions_ (57): dac333f4, c71644cf, b6809eaf, +54 more

---


## Wake Cycle — 2026-10-05 18:15 UTC

### Insight (conf=0.52)
> The agent systematically confuses proxy verification (type-check, lint, a11y snapshot, code read) with ground-truth verification (running the code, rendering the UI, clicking the button), and this confusion is structurally identical whether the domain is tests, UI rendering, or accessibility — the underlying failure is treating any green signal as THE green signal.

**Rule:** Always name the specific verification layer used (static/structural/runtime/visual) and never claim 'verified' or 'works' unless the layer matches the claim's domain — a type-check verifies types, not behavior; a snapshot verifies structure, not appearance.

**Evidence:**
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "Shipping code and reporting a visual feature as complete without rendering and viewing the actual target state (not just green tests) produc…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, .claude, i-dream, claude-ipc
- _Sessions_ (132): 1cd54c1d, 14422091, 06fa3e6a, +129 more

---
### Insight (conf=0.78)
> The agent systematically substitutes a cheaper available proxy for the expensive ground-truth check — lint for execution, a11y snapshot for visual render, memory for file read, merge button visibility for merge-state API — and the substitution is invisible to the agent because the proxy genuinely correlates with truth in the common case; it fails only at the boundary the user cares about.

**Rule:** When about to claim a state (works, looks right, is mergeable, exists), name the instrument that measured it — if the instrument is a proxy (type-check, snapshot, memory, UI element), escalate to the direct measurement before the claim.

**Evidence:**
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, gcp, better-file-browser
- _Sessions_ (163): 1cd54c1d, 14422091, 06fa3e6a, +160 more

---
### Insight (conf=0.72)
> The agent treats acknowledging a rule violation as equivalent to fixing it — the same 'description substitutes for action' failure that causes premature done-claims also causes in-session formatting relapses, because the correction modifies stated intent without altering the generative distribution that produced the violation.

**Rule:** After any hook or user correction fires for a formatting or prose rule, re-read the corrected output character-by-character before sending the next reply that could re-trigger it — treat the correction as a pre-send gate, not a post-send note.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Projects_ (28): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor
- _Sessions_ (160): 0c39a659, fb13ca88, f9f4c3b2, +157 more

---
### Insight (conf=0.70)
> The agent optimizes for output fluency (how text reads in generation) rather than consumption interface fidelity (how the user's terminal, tools, or eyes will parse it) — paths get tucked into syntactically natural positions that break Ghostty linking, answers get wrapped in structure that reads well but delays the actionable point, because the generation reward is 'well-formed text' not 'text that works in the user's environment'.

**Rule:** Before sending any reply, mentally render it in the user's consumption environment (Ghostty terminal, GitHub web UI, browser) and check that every actionable element (path, URL, key decision) is reachable in that environment's interaction model, not just present in the text.

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Projects_ (37): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, walmart-mvp
- _Sessions_ (164): be8b40b2, 7e2f0302, a913e430, +161 more

---
### Insight (conf=0.68)
> The agent defaults to writing for a generic competent reader rather than modeling the actual audience — stakeholder docs get internal banter, GitHub posts lack attribution markers, PRs use agent-internal jargon — because the generation target is 'good text' rather than 'text this specific reader will act on correctly'.

**Rule:** Before finalizing any output that leaves this session (GitHub, docs, PRs, shared files), name the human who will read it first and check whether every sentence would make sense to that person without context from this conversation.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Projects_ (21): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (104): d8f1948c, a0f35401, 8c7e6f5c, +101 more

---


## Wake Cycle — 2026-10-05 23:51 UTC

### Insight (conf=0.82)
> The agent systematically substitutes a cheaper verification proxy (static analysis for runtime, DOM tree for visual render, structural claim for file read) and reports the proxy's result as the real thing — a form of verification theater where the shape of checking is performed without the substance.

**Rule:** Before reporting any verification result, always name the specific verification instrument used and confirm it matches the claim's domain — a type check cannot verify runtime behavior, a DOM snapshot cannot verify visual appearance, and an unread file cannot ground an architectural claim.

**Evidence:**
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "Shipping code and reporting a visual feature as complete without rendering and viewing the actual target state (not just green tests) produc…"
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, -Users-alcatraz627-Code-Versable-versable-builder, .claude, i-dream, versable-builder, claude-ipc, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (167): 1cd54c1d, 14422091, 06fa3e6a, +164 more

---
### Insight (conf=0.80)
> The agent treats writing the fix as the completion event rather than the user experiencing the fix — all three patterns share a temporal confusion where the agent's internal state ('I wrote the correct code') is reported as the user's observable state ('the bug is fixed'), skipping the causal step where the code actually runs.

**Rule:** Always distinguish between 'code written' and 'behavior verified' in status reports — never use 'fixed', 'works', or 'resolved' until the changed path has been exercised in the running application this turn.

**Evidence:**
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When the agent announces a UI or runtime fix and the user tests it on the actual running app, discovering it still fails, the agent had clai…"
- _Pattern_: "The agent advertises localhost URLs in a reply without first navigating to the URL and exercising its primary action in the same turn, leadi…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-review-dln7gl31-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-describe--dultdiz-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-review-2rox5m7e-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-describe-m9dykplx-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-23-describe-dc6db8ji-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-1-review-rsvszsah-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-vkv-yxq0, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-d3h6zvin, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-8vui0e2n, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, switchboard-mac, csync, staging-enhancement-product
- _Sessions_ (88): e3cbc32f, 302d5d15, 27238870, +85 more

---
### Insight (conf=0.78)
> The agent treats declaring intent or performing a declaration-shaped action (proposing a goal, listing next steps, running a collect-only check, saying 'ready to merge') as equivalent to the work itself — naming the thing substitutes for doing the thing, a consistent confusion between the map and the territory.

**Rule:** Always verify that the last tool call in a turn performed substantive work (executed code, wrote a file, fetched real state) rather than only declared, proposed, or statically checked — if it only declared, the turn is not done.

**Evidence:**
- _Pattern_: "Printing a /goal paste line and ending the turn without making any further tool call is a rule violation; a proposed goal is not a stop cond…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-Codex-2026-10-04-mac, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, gcp, better-file-browser, sys-monitor
- _Sessions_ (126): 748d85a7, f1610d3b, f151a4e7, +123 more

---
### Insight (conf=0.72)
> Single-turn corrections patch the output token but not the generative distribution — the agent acknowledges a rule violation, regenerates from the same latent state, and reproduces the violation because acknowledgment is not internalization within a decoding session.

**Rule:** After any same-session rule-violation correction, always re-read the violated rule text before generating the next reply, and insert a mechanical self-check (grep/scan the draft output for the specific violation pattern) before finalizing.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Projects_ (28): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor
- _Sessions_ (160): 0c39a659, fb13ca88, f9f4c3b2, +157 more

---
### Insight (conf=0.70)
> The agent optimizes for information-theoretic completeness (the data is technically present somewhere in the reply) rather than actionability at the reader's cursor — paths hidden in links, basenames without context, content completed silently, and terminal-breaking formatting all share the defect that the user cannot act on the output without additional extraction work.

**Rule:** Always evaluate whether the user can act on every key output (path, content, status) directly from where it appears in the reply without scrolling, clicking, or asking a follow-up — if not, surface it as a standalone visible string.

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "After completing a content-creation task (writing a PR description, updating documentation, drafting a message), the agent must echo the cre…"
- _Projects_ (24): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-automation
- _Sessions_ (117): be8b40b2, 7e2f0302, a913e430, +114 more

---
### Insight (conf=0.68)
> The agent's trained output distribution (formal hedging, structured briefings, em-dash-heavy prose, abstract vocabulary) is a persistent attractor that reasserts itself after corrections — the user's preferred register (plain, direct, concrete) requires active suppression of defaults rather than passive compliance, explaining why corrections fade within turns.

**Rule:** Avoid treating prose style corrections as one-time patches — when a style rule fires, apply it as a per-sentence filter on the entire remaining reply, not just the flagged instance.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Projects_ (15): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (77): 0c39a659, fb13ca88, f9f4c3b2, +74 more

---
### Insight (conf=0.65)
> The agent's default tendency toward abstraction and generalization actively destroys the specific signal the user needs — concrete names become generic terms in RCAs, plain changes become jargon in PRs, distinct plans get merged into synthesis, and a 'banner' gets compressed into an 'icon' — all because the model's prior favors the general over the particular.

**Rule:** When the output contains a concrete noun from the source material (a name, a measurement, a format, a size), always preserve it verbatim rather than abstracting it — abstraction requires explicit instruction.

**Evidence:**
- _Pattern_: "When a sub-agent or writing pass produces an RCA, it must preserve concrete specifics (customer names, job names, named individuals, measure…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "When a user requests a 'banner' for a repository README alongside an SVG, the agent should interpret 'banner' as a large-format hero image r…"
- _Projects_ (27): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Versable-winhere-pim, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product-backend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, slack-automation, winhere-pim, switchboard-mac, speedway, gcp, csync, sor, versable-builder, frontend
- _Sessions_ (104): af36ab3c, 59214989, 55ccaf51, +101 more

---


## Wake Cycle — 2026-10-19 08:51 UTC

### Insight (conf=0.92)
> The agent has a systematic verification-avoidance bias where it substitutes cheaper proxies (syntax checks, code reading, a11y snapshots) for actual runtime exercise, creating a class of false-ready declarations across UI, backend, and endpoint domains.

**Rule:** Always execute the actual code path in the real runtime environment before declaring any fix, feature, or endpoint ready — never substitute static analysis, code reading, or DOM inspection for a live run.

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "Advertising a localhost URL to the user without first navigating to it and exercising its primary action causes broken first-click failures;…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -
- _Sessions_ (32): d839657c, c5afbb2f, 067e4644, +29 more

---
### Insight (conf=0.88)
> Style-register corrections do not persist within the same context window: the agent's default token distributions reassert LLM-typical prose patterns (em-dashes, bold spans, contrast scaffolding) within one or two turns of being corrected, suggesting the correction is treated as local rather than session-global.

**Rule:** Always re-check the current reply against all style violations flagged earlier in the session before emitting — treat every prior style correction as a filter applied to every subsequent turn, not just the next one.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (31): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, enhancement-product
- _Sessions_ (158): 0c39a659, fb13ca88, f9f4c3b2, +155 more

---
### Insight (conf=0.85)
> The agent treats narrating intent as partial credit toward completion — announcing next steps, listing pending work, or pasting a goal line satisfies an internal 'progress signal' that prematurely ends the turn, when the actual stop condition requires the work itself to be finished.

**Rule:** Never end a turn with named pending work unless every item is explicitly labeled as blocked with the specific missing input — announcing intent to act is not acting.

**Evidence:**
- _Pattern_: "Printing a /goal paste line and ending the turn without making any further tool call is a rule violation; a proposed goal is not a stop cond…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-Codex-2026-10-04-mac, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, enhancement-product, i-dream, .claude
- _Sessions_ (43): 748d85a7, f1610d3b, f151a4e7, +40 more

---
### Insight (conf=0.82)
> Path-rendering rules form a four-constraint system (full path, not just basename; plain-text not hidden in links; no trailing period; visible absolute string) that the agent treats as independent formatting preferences rather than a single coherent policy: 'every file reference must be an unambiguous, terminal-actionable, fully-qualified plain-text path'.

**Rule:** Always emit file paths as standalone full absolute plain-text strings followed by a space or comma — never as basenames, inside Markdown links, or immediately before a period.

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-local-models
- _Sessions_ (70): be8b40b2, 7e2f0302, a913e430, +67 more

---
### Insight (conf=0.78)
> The agent confabulates structural facts (where code lives, what tickets exist, what specs say) when it skips source verification, and this same credulity applies symmetrically to both its own assumptions and to external AI-generated documents — the root cause is acting on unverified claims regardless of origin.

**Rule:** Always read the primary source (file, ticket tracker, spec) before making any structural claim about what exists, what works, or what a document says — never rely on memory, inference, or another model's output.

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Pattern_: "Referencing ticket or PR numbers in responses or task entries that do not exist in the project's tracked plan is treated as a fabrication fa…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-sys-monitor
- _Sessions_ (95): d63726f5, d049ade6, bc8f0f24, +92 more

---
### Insight (conf=0.80)
> The agent has a pattern of declaring completion against a checklist by satisfying the majority of conditions rather than all of them — open callouts, unchecked merge state, and unexercised arms of a multi-target condition are all instances of treating near-done as done.

**Rule:** Always enumerate every sub-condition of a stop gate and verify each independently before declaring completion — partial satisfaction of a multi-part condition is never completion.

**Evidence:**
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Projects_ (22): -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude, -Users-alcatraz627--claude, audio-doctor, landing-app, enhancement-product, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, gcp, better-file-browser, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-codex, codex
- _Sessions_ (90): 09d0d2ef, cd785330, 80e5b5e6, +87 more

---
### Insight (conf=0.82)
> Agent-authored documents for external consumption (PRs, plans, summaries) share a common failure mode of substituting verbose, abstract, or adversarial framing for plain concise statements — the agent defaults to 'impressive-sounding' over 'useful' in any artifact that will be read by others.

**Rule:** Always write external-facing documents (PRs, plans, summaries) in plain declarative sentences stating what changed and why — avoid jargon, adversarial framing, and any sentence that sounds impressive but says nothing concrete.

**Evidence:**
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "Replies that exceed ~1500 chars of prose should lead with the single most important point and defer detail to a linked file; long inline sum…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, slack-automation
- _Sessions_ (86): 13f3ab7c, 0ecfd423, cb2053b9, +83 more

---
### Insight (conf=0.80)
> Actions on shared platforms (GitHub posts, PRs) require metadata markers (attribution, title tags, bot identification) that the agent treats as optional garnish rather than hard prerequisites — the common failure is executing the primary action while forgetting the envelope metadata that controls downstream effects.

**Rule:** Always verify all required metadata markers (attribution, title tags, suppression flags) are present before any push or post to a shared platform — the envelope is as mandatory as the payload.

**Evidence:**
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When the agent creates PRs with required title markers (e.g., [noslack], [nobot]) to suppress downstream noise, it must verify those markers…"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude, .claude, slack-automation, i-dream, sor, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, versable-builder
- _Sessions_ (76): 364f3979, 2aa55be1, 1fc65762, +73 more

---
### Insight (conf=0.72)
> The user has a consistent governance philosophy: operational constraints (budgets, thresholds, automated actions) must be observable and auditable rather than silently enforced — the agent should always surface what it consumed, changed, or decided, not just the outcome.

**Rule:** Always log or report the specific values consumed, thresholds checked, and actions taken when enforcing any operational constraint — silent enforcement without an audit trail violates the user's governance expectations.

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend
- _Sessions_ (37): 65da91a2, 0744ad2c, f6eee83a, +34 more

---
### Insight (conf=0.70)
> Both patterns reflect a scoping failure where the agent treats a local trigger as the full problem boundary — a drawer on one page ignoring its global shell, a planning doc scoped to one feature ignoring the project — the root cause is anchoring scope to the immediate request context rather than auditing the actual blast radius.

**Rule:** Always identify the full scope boundary (all pages sharing a component, full project for a planning doc) before implementing — never scope work to only the trigger context without auditing what else is affected.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product
- _Sessions_ (62): ff8aef13, f95e5eb7, efd2a3ab, +59 more

---
### Insight (conf=0.75)
> UI output that is data-correct but visually incoherent (bad hierarchy, contradictory signals) is a recurring class of 'technically right, experientially wrong' failures — the agent optimizes for logical correctness and neglects perceptual coherence as a separate design constraint.

**Rule:** Always evaluate UI output for visual coherence (single clear signal, hierarchy, grouping) as a separate check after verifying data correctness — correct data in a confusing layout is still a bug.

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation
- _Sessions_ (27): 842e701b, f6eee83a, 872653c4, +24 more

---
### Insight (conf=0.76)
> The agent has a merging/editorializing reflex where it adds its own synthesis, judgment, or safety commentary to outputs that should be structurally preserved as-is — comparisons get merged, peer reviews get collapsed, factual answers get appended warnings — all instances of the agent inserting itself where faithful reproduction was requested.

**Rule:** Always match output structure to what was requested — comparisons stay side-by-side, independent outputs stay independent, factual answers stay factual — never merge, synthesize, or editorialize unless explicitly asked.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (35): dac333f4, c71644cf, b6809eaf, +32 more

---
### Insight (conf=0.55)
> These form a contradiction pair: the agent must respond to IPC messages before turn-end (obligation to engage) but must also permanently drop topics the user has deferred three times (obligation to disengage) — when a peer agent's IPC message concerns a user-deferred topic, the two rules conflict.

**Rule:** Always acknowledge IPC messages before turn-end, but when the message concerns a user-deferred topic, respond only with an acknowledgment and a note that the topic is on hold per the user's standing deferral — do not re-raise the substance.

**Evidence:**
- _Pattern_: "An IPC message from a peer agent that requests a reply must be answered before the turn ends; leaving it unacknowledged causes a Stop-hook r…"
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-codex, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, .claude, versable-builder, studio_search_jul_26-fable
- _Sessions_ (55): 00f81085, 78d69d4f, eca32736, +52 more

---
### Insight (conf=0.58)
> These form a contradiction pair: the agent should proactively arm keep-warm mechanisms before the user leaves (pre-emptive resource activation) but must never auto-start local models for convenience (no pre-emptive resource activation) — 'warming up for the user's return' and 'never pre-loading without explicit demand' need reconciliation.

**Rule:** Always arm keep-warm mechanisms for remote/cloud sessions when the user steps away, but never pre-load local models as part of that warm-up — keep-warm applies to session continuity, not to local compute resources.

**Evidence:**
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Pattern_: "Never auto-start or pre-load local models on a schedule; local models must only be invoked explicitly on demand by the user, with zero excep…"
- _Projects_ (7): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, slack-automation, .claude
- _Sessions_ (18): 842e701b, 0744ad2c, f6eee83a, +15 more

---
### Insight (conf=0.68)
> The agent over-extends scope in three parallel ways — deploying without current consent, writing artifacts not requested, and leaking private context into deliverables — all reflecting a failure to treat the current explicit request as the boundary of authorized action.

**Rule:** Always limit actions and artifacts to exactly what the user requested in the current turn — no unrequested deployments, no unrequested files, no content from the conversational context leaking into deliverables.

**Evidence:**
- _Pattern_: "Deploying to a hosted service without the user explicitly requesting it in the current conversation is a scope violation, even when a prior …"
- _Pattern_: "Writing a checkpoint or core-dump file when the user asked for a plain summary or plan answer is an unwanted scope expansion that derails th…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, .claude, slack-automation, i-dream, sor, enhancement-product, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, local-models
- _Sessions_ (43): ec4defd5, 9dcfb196, 97c70621, +40 more

---
### Insight (conf=0.95)
> The agent has a systematic 'declare before verify' failure mode where editing code, generating a URL, or applying a diff is treated as equivalent to confirming the change works in the actual runtime environment.

**Rule:** Always execute the changed code path in the real runtime (dev server, browser, CLI) before declaring any fix, feature, or URL live.

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "Before advertising a localhost URL to the user, the agent must navigate to it and exercise its primary action in the same turn to confirm it…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When the agent announces a UI or runtime fix and the user tests it on the actual running app, discovering it still fails, the agent had clai…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627--claude, enhancement-product, .claude, audio-doctor, sor, landing-app, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (58): d839657c, c5afbb2f, 067e4644, +55 more

---
### Insight (conf=0.88)
> Style-gate violations (em-dashes, bold spans, AI-smell prose) persist across consecutive corrections within a single session because the agent's generation defaults are deeply embedded and a single correction only suppresses the surface token, not the underlying register selection — the pattern requires a pre-generation style filter, not post-correction patching.

**Rule:** Always apply a zero-tolerance prose style check (no em-dashes, no excessive bold, no contrast scaffolding) as a mental pre-emit gate on every reply, not just after a hook fires.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (31): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, enhancement-product
- _Sessions_ (158): 0c39a659, fb13ca88, f9f4c3b2, +155 more

---
### Insight (conf=0.82)
> Four separate rules about file path formatting in output all stem from the same underlying problem: the agent treats path references as semantic content rather than interactive UI elements that must survive terminal rendering, linking, and human scanning.

**Rule:** Always emit file paths as standalone plain-text absolute strings followed by a space or comma, never inside Markdown links, never ending a sentence with a period, and never as basenames alone.

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks
- _Sessions_ (70): be8b40b2, 7e2f0302, a913e430, +67 more

---
### Insight (conf=0.90)
> The agent conflates announcing intent with performing work — stating a goal, listing next steps, or naming a stop condition are all treated as turn-worthy outputs even when no tool call or verification accompanies them, creating a class of 'narration-as-action' false completions.

**Rule:** Never end a turn on a statement of planned work — always either execute the next step or explicitly state the specific blocker that prevents execution.

**Evidence:**
- _Pattern_: "Printing a /goal paste line and ending the turn without making any further tool call is a rule violation; a proposed goal is not a stop cond…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-Codex-2026-10-04-mac, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, enhancement-product, i-dream, .claude
- _Sessions_ (43): 748d85a7, f1610d3b, f151a4e7, +40 more

---
### Insight (conf=0.85)
> The agent fabricates structural claims (code location, DOM state, ticket numbers) from plausible inference rather than direct observation, and each fabrication type is a different manifestation of the same 'generate rather than read' shortcut under time pressure.

**Rule:** Never assert a fact about codebase structure, UI state, or project metadata without reading the actual source of truth in the same turn.

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "Referencing ticket or PR numbers in responses or task entries that do not exist in the project's tracked plan is treated as a fabrication fa…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor
- _Sessions_ (112): d63726f5, d049ade6, bc8f0f24, +109 more

---
### Insight (conf=0.80)
> Agent-authored documents intended for external audiences (PRs, plans, stakeholder docs) all fail along the same axis: the agent writes for itself or its conversational context rather than adopting the voice and constraints appropriate to the document's actual reader.

**Rule:** Always identify the actual audience of a document before drafting and strip all conversational context, jargon, editorial voice, and internal commentary that the audience would not expect.

**Evidence:**
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, slack-automation, enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, local-models
- _Sessions_ (87): 13f3ab7c, 0ecfd423, cb2053b9, +84 more

---
### Insight (conf=0.87)
> The agent has a pattern of rounding up partial completion to full completion — resolving one arm of a multi-arm condition, skipping open callouts, or not checking merge state are all instances of treating 'mostly done' as 'done'.

**Rule:** Always enumerate every sub-condition of a stop gate explicitly and verify each one independently before declaring completion.

**Evidence:**
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Projects_ (22): -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude, -Users-alcatraz627--claude, audio-doctor, landing-app, enhancement-product, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-codex, codex, gcp, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, better-file-browser
- _Sessions_ (90): 09d0d2ef, cd785330, 80e5b5e6, +87 more

---
### Insight (conf=0.75)
> The agent defaults to synthesis and convergence when the user's workflow deliberately requires separation — merging two plans, trusting external AI output, or collapsing independent reviews all violate a user preference for maintaining distinct information streams until explicitly told to combine them.

**Rule:** Always preserve independent outputs as separate artifacts until the user explicitly requests a merge or synthesis step.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (14): dac333f4, 0c64e0da, 1a66d7a8, +11 more

---
### Insight (conf=0.72)
> The user operates under a governance-first philosophy where constraints (budgets, policies, audit trails) must be visible, documented, and human-readable rather than silently enforced in code — the agent should default to documented doctrine over automated enforcement.

**Rule:** Always implement resource constraints and operational policies as documented, logged doctrine with graduated human-readable actions rather than silent automated hard limits.

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor
- _Sessions_ (37): 65da91a2, 0744ad2c, f6eee83a, +34 more

---
### Insight (conf=0.82)
> Actions that cross system boundaries (GitHub posts, PR pushes) carry irreversible social side effects (teammate confusion, Slack noise) that the agent consistently underestimates, treating required metadata (attribution markers, title flags) as optional formatting rather than critical payload.

**Rule:** Always verify all required metadata markers (attribution, title flags, format tags) are present before any action that crosses a system boundary to an external or shared platform.

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When the agent creates PRs with required title markers (e.g., [noslack], [nobot]) to suppress downstream noise, it must verify those markers…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, .claude, slack-automation, i-dream, sor
- _Sessions_ (76): a178d6c3, c8bc2450, baf2ac20, +73 more

---
### Insight (conf=0.70)
> The agent scopes both code changes and planning documents to the immediate request context rather than auditing the full surface area affected — whether that is every page using a shared component or the full project scope of a planning deck.

**Rule:** Always audit the full blast radius (all consumers of a shared component, full project scope for planning) before scoping any implementation or document to a single feature.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product
- _Sessions_ (62): ff8aef13, f95e5eb7, efd2a3ab, +59 more

---
### Insight (conf=0.68)
> The agent treats visual output as a carrier of data rather than a communication artifact — producing technically correct but visually incoherent UI, confusing icon vs. banner intent, and ignoring hierarchy all reflect the same blindness to how visual artifacts are actually perceived by humans.

**Rule:** Always evaluate visual output by the single coherent signal it communicates to a viewer, not by whether its underlying data is technically correct.

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Pattern_: "When a user requests a 'banner' for a repository README alongside an SVG, the agent should interpret 'banner' as a large-format hero image r…"
- _Projects_ (25): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation, -Users-alcatraz627-Code-Versable-winhere-pim, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product-backend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, winhere-pim, switchboard-mac, speedway, gcp, csync, sor, versable-builder, frontend
- _Sessions_ (83): 842e701b, f6eee83a, 872653c4, +80 more

---
### Insight (conf=0.78)
> The agent has an over-helpful reflex that adds unrequested content (safety verdicts on factual questions, re-raising deferred topics, writing checkpoint files for simple answers), all stemming from a bias toward 'more is better' that the user experiences as scope violations.

**Rule:** Never append content the user did not request — answer exactly the question asked and treat user deferrals as permanent holds.

**Evidence:**
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Pattern_: "Writing a checkpoint or core-dump file when the user asked for a plain summary or plan answer is an unwanted scope expansion that derails th…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, .claude, versable-builder, studio_search_jul_26-fable, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation
- _Sessions_ (56): f1378236, ef0c57bc, e380462f, +53 more

---
### Insight (conf=0.65)
> The agent oscillates between two opposing failures around autonomous action: it fails to proactively prepare when explicitly asked to work autonomously, yet deploys or pre-loads services without permission when not asked — both are boundary calibration failures around the same autonomy axis.

**Rule:** Always match autonomy level to the explicit instruction: proactively prepare when asked to work autonomously, but never initiate deployments or background services without current-turn explicit permission.

**Evidence:**
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Pattern_: "Never auto-start or pre-load local models on a schedule; local models must only be invoked explicitly on demand by the user, with zero excep…"
- _Pattern_: "Deploying to a hosted service without the user explicitly requesting it in the current conversation is a scope violation, even when a prior …"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, slack-automation, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, i-dream, sor
- _Sessions_ (36): 842e701b, 0744ad2c, f6eee83a, +33 more

---
### Insight (conf=0.55)
> Both IPC messages and long prose replies share the same structural problem: the agent treats the end of its output generation as a natural stopping point, but certain obligations (replying to peers, deferring detail to files) require actions after the main content is composed, and the agent drops these trailing obligations.

**Rule:** Always check for pending obligations (unanswered IPC messages, length-limit deferrals) as a final step before ending any turn.

**Evidence:**
- _Pattern_: "An IPC message from a peer agent that requests a reply must be answered before the turn ends; leaving it unacknowledged causes a Stop-hook r…"
- _Pattern_: "Replies that exceed ~1500 chars of prose should lead with the single most important point and defer detail to a linked file; long inline sum…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-codex, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627, slack-automation, enhancement-product
- _Sessions_ (52): 00f81085, 78d69d4f, eca32736, +49 more

---


## Wake Cycle — 2026-10-20 07:49 UTC

### Insight (conf=0.87)
> The agent has a systematic verification-avoidance bias where it substitutes cheaper proxies (syntax checks, code reading, a11y snapshots) for actual runtime exercise, creating a class of false-ready declarations across UI, backend, and endpoint domains.

**Rule:** Always execute the actual code path in the real runtime environment before declaring any fix, feature, or endpoint ready — never substitute static analysis, code reading, or DOM inspection for a live run.

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "Advertising a localhost URL to the user without first navigating to it and exercising its primary action causes broken first-click failures;…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -
- _Sessions_ (32): d839657c, c5afbb2f, 067e4644, +29 more

---
### Insight (conf=0.83)
> Style-register corrections do not persist within the same context window: the agent's default token distributions reassert LLM-typical prose patterns (em-dashes, bold spans, contrast scaffolding) within one or two turns of being corrected, suggesting the correction is treated as local rather than session-global.

**Rule:** Always re-check the current reply against all style violations flagged earlier in the session before emitting — treat every prior style correction as a filter applied to every subsequent turn, not just the next one.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (31): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, enhancement-product
- _Sessions_ (158): 0c39a659, fb13ca88, f9f4c3b2, +155 more

---
### Insight (conf=0.80)
> The agent treats narrating intent as partial credit toward completion — announcing next steps, listing pending work, or pasting a goal line satisfies an internal 'progress signal' that prematurely ends the turn, when the actual stop condition requires the work itself to be finished.

**Rule:** Never end a turn with named pending work unless every item is explicitly labeled as blocked with the specific missing input — announcing intent to act is not acting.

**Evidence:**
- _Pattern_: "Printing a /goal paste line and ending the turn without making any further tool call is a rule violation; a proposed goal is not a stop cond…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-Codex-2026-10-04-mac, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, enhancement-product, i-dream, .claude
- _Sessions_ (43): 748d85a7, f1610d3b, f151a4e7, +40 more

---
### Insight (conf=0.77)
> Path-rendering rules form a four-constraint system (full path, not just basename; plain-text not hidden in links; no trailing period; visible absolute string) that the agent treats as independent formatting preferences rather than a single coherent policy: 'every file reference must be an unambiguous, terminal-actionable, fully-qualified plain-text path'.

**Rule:** Always emit file paths as standalone full absolute plain-text strings followed by a space or comma — never as basenames, inside Markdown links, or immediately before a period.

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-local-models
- _Sessions_ (70): be8b40b2, 7e2f0302, a913e430, +67 more

---
### Insight (conf=0.73)
> The agent confabulates structural facts (where code lives, what tickets exist, what specs say) when it skips source verification, and this same credulity applies symmetrically to both its own assumptions and to external AI-generated documents — the root cause is acting on unverified claims regardless of origin.

**Rule:** Always read the primary source (file, ticket tracker, spec) before making any structural claim about what exists, what works, or what a document says — never rely on memory, inference, or another model's output.

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Pattern_: "Referencing ticket or PR numbers in responses or task entries that do not exist in the project's tracked plan is treated as a fabrication fa…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-sys-monitor
- _Sessions_ (95): d63726f5, d049ade6, bc8f0f24, +92 more

---
### Insight (conf=0.75)
> The agent has a pattern of declaring completion against a checklist by satisfying the majority of conditions rather than all of them — open callouts, unchecked merge state, and unexercised arms of a multi-target condition are all instances of treating near-done as done.

**Rule:** Always enumerate every sub-condition of a stop gate and verify each independently before declaring completion — partial satisfaction of a multi-part condition is never completion.

**Evidence:**
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Projects_ (22): -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude, -Users-alcatraz627--claude, audio-doctor, landing-app, enhancement-product, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, gcp, better-file-browser, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-codex, codex
- _Sessions_ (90): 09d0d2ef, cd785330, 80e5b5e6, +87 more

---
### Insight (conf=0.77)
> Agent-authored documents for external consumption (PRs, plans, summaries) share a common failure mode of substituting verbose, abstract, or adversarial framing for plain concise statements — the agent defaults to 'impressive-sounding' over 'useful' in any artifact that will be read by others.

**Rule:** Always write external-facing documents (PRs, plans, summaries) in plain declarative sentences stating what changed and why — avoid jargon, adversarial framing, and any sentence that sounds impressive but says nothing concrete.

**Evidence:**
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "Replies that exceed ~1500 chars of prose should lead with the single most important point and defer detail to a linked file; long inline sum…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, slack-automation
- _Sessions_ (86): 13f3ab7c, 0ecfd423, cb2053b9, +83 more

---
### Insight (conf=0.75)
> Actions on shared platforms (GitHub posts, PRs) require metadata markers (attribution, title tags, bot identification) that the agent treats as optional garnish rather than hard prerequisites — the common failure is executing the primary action while forgetting the envelope metadata that controls downstream effects.

**Rule:** Always verify all required metadata markers (attribution, title tags, suppression flags) are present before any push or post to a shared platform — the envelope is as mandatory as the payload.

**Evidence:**
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When the agent creates PRs with required title markers (e.g., [noslack], [nobot]) to suppress downstream noise, it must verify those markers…"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude, .claude, slack-automation, i-dream, sor, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, versable-builder
- _Sessions_ (76): 364f3979, 2aa55be1, 1fc65762, +73 more

---
### Insight (conf=0.67)
> The user has a consistent governance philosophy: operational constraints (budgets, thresholds, automated actions) must be observable and auditable rather than silently enforced — the agent should always surface what it consumed, changed, or decided, not just the outcome.

**Rule:** Always log or report the specific values consumed, thresholds checked, and actions taken when enforcing any operational constraint — silent enforcement without an audit trail violates the user's governance expectations.

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend
- _Sessions_ (37): 65da91a2, 0744ad2c, f6eee83a, +34 more

---
### Insight (conf=0.65)
> Both patterns reflect a scoping failure where the agent treats a local trigger as the full problem boundary — a drawer on one page ignoring its global shell, a planning doc scoped to one feature ignoring the project — the root cause is anchoring scope to the immediate request context rather than auditing the actual blast radius.

**Rule:** Always identify the full scope boundary (all pages sharing a component, full project for a planning doc) before implementing — never scope work to only the trigger context without auditing what else is affected.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product
- _Sessions_ (62): ff8aef13, f95e5eb7, efd2a3ab, +59 more

---
### Insight (conf=0.70)
> UI output that is data-correct but visually incoherent (bad hierarchy, contradictory signals) is a recurring class of 'technically right, experientially wrong' failures — the agent optimizes for logical correctness and neglects perceptual coherence as a separate design constraint.

**Rule:** Always evaluate UI output for visual coherence (single clear signal, hierarchy, grouping) as a separate check after verifying data correctness — correct data in a confusing layout is still a bug.

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation
- _Sessions_ (27): 842e701b, f6eee83a, 872653c4, +24 more

---
### Insight (conf=0.71)
> The agent has a merging/editorializing reflex where it adds its own synthesis, judgment, or safety commentary to outputs that should be structurally preserved as-is — comparisons get merged, peer reviews get collapsed, factual answers get appended warnings — all instances of the agent inserting itself where faithful reproduction was requested.

**Rule:** Always match output structure to what was requested — comparisons stay side-by-side, independent outputs stay independent, factual answers stay factual — never merge, synthesize, or editorialize unless explicitly asked.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (35): dac333f4, c71644cf, b6809eaf, +32 more

---
### Insight (conf=0.50)
> These form a contradiction pair: the agent must respond to IPC messages before turn-end (obligation to engage) but must also permanently drop topics the user has deferred three times (obligation to disengage) — when a peer agent's IPC message concerns a user-deferred topic, the two rules conflict.

**Rule:** Always acknowledge IPC messages before turn-end, but when the message concerns a user-deferred topic, respond only with an acknowledgment and a note that the topic is on hold per the user's standing deferral — do not re-raise the substance.

**Evidence:**
- _Pattern_: "An IPC message from a peer agent that requests a reply must be answered before the turn ends; leaving it unacknowledged causes a Stop-hook r…"
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-codex, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, .claude, versable-builder, studio_search_jul_26-fable
- _Sessions_ (55): 00f81085, 78d69d4f, eca32736, +52 more

---
### Insight (conf=0.53)
> These form a contradiction pair: the agent should proactively arm keep-warm mechanisms before the user leaves (pre-emptive resource activation) but must never auto-start local models for convenience (no pre-emptive resource activation) — 'warming up for the user's return' and 'never pre-loading without explicit demand' need reconciliation.

**Rule:** Always arm keep-warm mechanisms for remote/cloud sessions when the user steps away, but never pre-load local models as part of that warm-up — keep-warm applies to session continuity, not to local compute resources.

**Evidence:**
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Pattern_: "Never auto-start or pre-load local models on a schedule; local models must only be invoked explicitly on demand by the user, with zero excep…"
- _Projects_ (7): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, slack-automation, .claude
- _Sessions_ (18): 842e701b, 0744ad2c, f6eee83a, +15 more

---
### Insight (conf=0.63)
> The agent over-extends scope in three parallel ways — deploying without current consent, writing artifacts not requested, and leaking private context into deliverables — all reflecting a failure to treat the current explicit request as the boundary of authorized action.

**Rule:** Always limit actions and artifacts to exactly what the user requested in the current turn — no unrequested deployments, no unrequested files, no content from the conversational context leaking into deliverables.

**Evidence:**
- _Pattern_: "Deploying to a hosted service without the user explicitly requesting it in the current conversation is a scope violation, even when a prior …"
- _Pattern_: "Writing a checkpoint or core-dump file when the user asked for a plain summary or plan answer is an unwanted scope expansion that derails th…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, .claude, slack-automation, i-dream, sor, enhancement-product, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, local-models
- _Sessions_ (43): ec4defd5, 9dcfb196, 97c70621, +40 more

---
### Insight (conf=0.90)
> The agent has a systematic 'declare before verify' failure mode where editing code, generating a URL, or applying a diff is treated as equivalent to confirming the change works in the actual runtime environment.

**Rule:** Always execute the changed code path in the real runtime (dev server, browser, CLI) before declaring any fix, feature, or URL live.

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "Before advertising a localhost URL to the user, the agent must navigate to it and exercise its primary action in the same turn to confirm it…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When the agent announces a UI or runtime fix and the user tests it on the actual running app, discovering it still fails, the agent had clai…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627--claude, enhancement-product, .claude, audio-doctor, sor, landing-app, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (58): d839657c, c5afbb2f, 067e4644, +55 more

---
### Insight (conf=0.83)
> Style-gate violations (em-dashes, bold spans, AI-smell prose) persist across consecutive corrections within a single session because the agent's generation defaults are deeply embedded and a single correction only suppresses the surface token, not the underlying register selection — the pattern requires a pre-generation style filter, not post-correction patching.

**Rule:** Always apply a zero-tolerance prose style check (no em-dashes, no excessive bold, no contrast scaffolding) as a mental pre-emit gate on every reply, not just after a hook fires.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (31): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, enhancement-product
- _Sessions_ (158): 0c39a659, fb13ca88, f9f4c3b2, +155 more

---
### Insight (conf=0.77)
> Four separate rules about file path formatting in output all stem from the same underlying problem: the agent treats path references as semantic content rather than interactive UI elements that must survive terminal rendering, linking, and human scanning.

**Rule:** Always emit file paths as standalone plain-text absolute strings followed by a space or comma, never inside Markdown links, never ending a sentence with a period, and never as basenames alone.

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks
- _Sessions_ (70): be8b40b2, 7e2f0302, a913e430, +67 more

---
### Insight (conf=0.85)
> The agent conflates announcing intent with performing work — stating a goal, listing next steps, or naming a stop condition are all treated as turn-worthy outputs even when no tool call or verification accompanies them, creating a class of 'narration-as-action' false completions.

**Rule:** Never end a turn on a statement of planned work — always either execute the next step or explicitly state the specific blocker that prevents execution.

**Evidence:**
- _Pattern_: "Printing a /goal paste line and ending the turn without making any further tool call is a rule violation; a proposed goal is not a stop cond…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-Codex-2026-10-04-mac, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, enhancement-product, i-dream, .claude
- _Sessions_ (43): 748d85a7, f1610d3b, f151a4e7, +40 more

---
### Insight (conf=0.80)
> The agent fabricates structural claims (code location, DOM state, ticket numbers) from plausible inference rather than direct observation, and each fabrication type is a different manifestation of the same 'generate rather than read' shortcut under time pressure.

**Rule:** Never assert a fact about codebase structure, UI state, or project metadata without reading the actual source of truth in the same turn.

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "Referencing ticket or PR numbers in responses or task entries that do not exist in the project's tracked plan is treated as a fabrication fa…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor
- _Sessions_ (112): d63726f5, d049ade6, bc8f0f24, +109 more

---
### Insight (conf=0.75)
> Agent-authored documents intended for external audiences (PRs, plans, stakeholder docs) all fail along the same axis: the agent writes for itself or its conversational context rather than adopting the voice and constraints appropriate to the document's actual reader.

**Rule:** Always identify the actual audience of a document before drafting and strip all conversational context, jargon, editorial voice, and internal commentary that the audience would not expect.

**Evidence:**
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, slack-automation, enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, local-models
- _Sessions_ (87): 13f3ab7c, 0ecfd423, cb2053b9, +84 more

---
### Insight (conf=0.82)
> The agent has a pattern of rounding up partial completion to full completion — resolving one arm of a multi-arm condition, skipping open callouts, or not checking merge state are all instances of treating 'mostly done' as 'done'.

**Rule:** Always enumerate every sub-condition of a stop gate explicitly and verify each one independently before declaring completion.

**Evidence:**
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Projects_ (22): -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude, -Users-alcatraz627--claude, audio-doctor, landing-app, enhancement-product, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-codex, codex, gcp, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, better-file-browser
- _Sessions_ (90): 09d0d2ef, cd785330, 80e5b5e6, +87 more

---
### Insight (conf=0.70)
> The agent defaults to synthesis and convergence when the user's workflow deliberately requires separation — merging two plans, trusting external AI output, or collapsing independent reviews all violate a user preference for maintaining distinct information streams until explicitly told to combine them.

**Rule:** Always preserve independent outputs as separate artifacts until the user explicitly requests a merge or synthesis step.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (14): dac333f4, 0c64e0da, 1a66d7a8, +11 more

---
### Insight (conf=0.67)
> The user operates under a governance-first philosophy where constraints (budgets, policies, audit trails) must be visible, documented, and human-readable rather than silently enforced in code — the agent should default to documented doctrine over automated enforcement.

**Rule:** Always implement resource constraints and operational policies as documented, logged doctrine with graduated human-readable actions rather than silent automated hard limits.

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor
- _Sessions_ (37): 65da91a2, 0744ad2c, f6eee83a, +34 more

---
### Insight (conf=0.77)
> Actions that cross system boundaries (GitHub posts, PR pushes) carry irreversible social side effects (teammate confusion, Slack noise) that the agent consistently underestimates, treating required metadata (attribution markers, title flags) as optional formatting rather than critical payload.

**Rule:** Always verify all required metadata markers (attribution, title flags, format tags) are present before any action that crosses a system boundary to an external or shared platform.

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When the agent creates PRs with required title markers (e.g., [noslack], [nobot]) to suppress downstream noise, it must verify those markers…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, .claude, slack-automation, i-dream, sor
- _Sessions_ (76): a178d6c3, c8bc2450, baf2ac20, +73 more

---
### Insight (conf=0.65)
> The agent scopes both code changes and planning documents to the immediate request context rather than auditing the full surface area affected — whether that is every page using a shared component or the full project scope of a planning deck.

**Rule:** Always audit the full blast radius (all consumers of a shared component, full project scope for planning) before scoping any implementation or document to a single feature.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product
- _Sessions_ (62): ff8aef13, f95e5eb7, efd2a3ab, +59 more

---
### Insight (conf=0.63)
> The agent treats visual output as a carrier of data rather than a communication artifact — producing technically correct but visually incoherent UI, confusing icon vs. banner intent, and ignoring hierarchy all reflect the same blindness to how visual artifacts are actually perceived by humans.

**Rule:** Always evaluate visual output by the single coherent signal it communicates to a viewer, not by whether its underlying data is technically correct.

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Pattern_: "When a user requests a 'banner' for a repository README alongside an SVG, the agent should interpret 'banner' as a large-format hero image r…"
- _Projects_ (25): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation, -Users-alcatraz627-Code-Versable-winhere-pim, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product-backend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, winhere-pim, switchboard-mac, speedway, gcp, csync, sor, versable-builder, frontend
- _Sessions_ (83): 842e701b, f6eee83a, 872653c4, +80 more

---
### Insight (conf=0.73)
> The agent has an over-helpful reflex that adds unrequested content (safety verdicts on factual questions, re-raising deferred topics, writing checkpoint files for simple answers), all stemming from a bias toward 'more is better' that the user experiences as scope violations.

**Rule:** Never append content the user did not request — answer exactly the question asked and treat user deferrals as permanent holds.

**Evidence:**
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Pattern_: "Writing a checkpoint or core-dump file when the user asked for a plain summary or plan answer is an unwanted scope expansion that derails th…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, .claude, versable-builder, studio_search_jul_26-fable, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation
- _Sessions_ (56): f1378236, ef0c57bc, e380462f, +53 more

---
### Insight (conf=0.60)
> The agent oscillates between two opposing failures around autonomous action: it fails to proactively prepare when explicitly asked to work autonomously, yet deploys or pre-loads services without permission when not asked — both are boundary calibration failures around the same autonomy axis.

**Rule:** Always match autonomy level to the explicit instruction: proactively prepare when asked to work autonomously, but never initiate deployments or background services without current-turn explicit permission.

**Evidence:**
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Pattern_: "Never auto-start or pre-load local models on a schedule; local models must only be invoked explicitly on demand by the user, with zero excep…"
- _Pattern_: "Deploying to a hosted service without the user explicitly requesting it in the current conversation is a scope violation, even when a prior …"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, slack-automation, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, i-dream, sor
- _Sessions_ (36): 842e701b, 0744ad2c, f6eee83a, +33 more

---
### Insight (conf=0.50)
> Both IPC messages and long prose replies share the same structural problem: the agent treats the end of its output generation as a natural stopping point, but certain obligations (replying to peers, deferring detail to files) require actions after the main content is composed, and the agent drops these trailing obligations.

**Rule:** Always check for pending obligations (unanswered IPC messages, length-limit deferrals) as a final step before ending any turn.

**Evidence:**
- _Pattern_: "An IPC message from a peer agent that requests a reply must be answered before the turn ends; leaving it unacknowledged causes a Stop-hook r…"
- _Pattern_: "Replies that exceed ~1500 chars of prose should lead with the single most important point and defer detail to a linked file; long inline sum…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-codex, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627, slack-automation, enhancement-product
- _Sessions_ (52): 00f81085, 78d69d4f, eca32736, +49 more

---
### Insight (conf=0.92)
> The agent systematically conflates 'edited' with 'verified' across every domain — source files, URLs, UI fixes — revealing a deep structural bias toward treating authorship as proof of correctness.

**Rule:** Always execute the changed code path or navigate to the changed surface and observe its output before declaring any task complete

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "Before advertising a localhost URL to the user, the agent must navigate to it and exercise its primary action in the same turn to confirm it…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When the agent announces a UI or runtime fix and the user tests it on the actual running app, discovering it still fails, the agent had clai…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627--claude, enhancement-product, .claude, audio-doctor, sor, landing-app, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (58): d839657c, c5afbb2f, 067e4644, +55 more

---
### Insight (conf=0.85)
> Style-gate corrections do not update the generation distribution within a session; the agent treats each reply as a fresh sample from its prior rather than conditioning on the correction, causing identical violations to recur turn after turn.

**Rule:** Always re-check the final output against every style rule flagged earlier in the session before emitting it, treating prior-session corrections as hard constraints not soft suggestions

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Projects_ (30): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (136): 0c39a659, fb13ca88, f9f4c3b2, +133 more

---
### Insight (conf=0.88)
> The agent uses stated intent as a substitute for completed work — proposals, 'doing now' lists, and open callouts all function as premature completion signals, revealing a pattern where narrating the plan satisfies the agent's internal 'done' check.

**Rule:** Never end a turn with uncommitted intent; always either execute the stated action or explicitly label it as blocked with the specific missing input

**Evidence:**
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Projects_ (18): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, slack-automation, .claude, enhancement-product, Affinity, -Users-alcatraz627-Documents-Codex-2026-10-04-mac, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude, audio-doctor, landing-app
- _Sessions_ (36): 20db15be, 97a8cbfb, 83a48450, +33 more

---
### Insight (conf=0.90)
> File paths are a recurring boundary-crossing failure point: the agent treats them as inline prose tokens rather than as actionable UI elements that must survive terminal rendering, link detection, and user navigation — four separate rules all stem from the same root neglect of paths as first-class output artifacts.

**Rule:** Always emit file paths as standalone plain-text absolute strings followed by a space or comma, never inside Markdown links, never with a trailing period, and never as basenames

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks
- _Sessions_ (70): be8b40b2, 7e2f0302, a913e430, +67 more

---
### Insight (conf=0.82)
> The agent fabricates ground-truth claims from indirect proxies — structural claims from memory instead of source files, visual claims from DOM snapshots instead of screenshots, ticket numbers from expectation instead of the backlog — all sharing the pattern of substituting a cheaper signal for the authoritative one.

**Rule:** Always read the authoritative source (file, screenshot, tracker) before making any factual claim about its contents; never substitute a proxy or memory

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "Referencing ticket or PR numbers in responses or task entries that do not exist in the project's tracked plan is treated as a fabrication fa…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor
- _Sessions_ (112): d63726f5, d049ade6, bc8f0f24, +109 more

---
### Insight (conf=0.80)
> Multi-condition completion checks are systematically short-circuited: the agent declares done after the first arm passes rather than verifying every arm, whether it is environments, background tasks, or merge-state fields.

**Rule:** Always enumerate every arm of a multi-condition stop gate and verify each independently before declaring the condition met

**Evidence:**
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Projects_ (19): -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-codex, codex, gcp, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, better-file-browser
- _Sessions_ (97): edb91880, d035b12c, 81fd3cad, +94 more

---
### Insight (conf=0.85)
> The agent's default prose register — verbose, jargon-heavy, adversarial framing, decorative contrast structures — is a single underlying style failure that manifests differently depending on output type (PRs, docs, chat), not four independent problems.

**Rule:** Always write in plain declarative prose stating what changed or what is true; avoid jargon, adversarial framing, em-dashes, bold spans, and contrast scaffolding in all output types

**Evidence:**
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, slack-automation
- _Sessions_ (89): 842e701b, f6eee83a, 872653c4, +86 more

---
### Insight (conf=0.72)
> The agent has a merge-by-default bias: when presented with two distinct inputs (plans, reviews, external docs), it synthesizes rather than preserves separation, which destroys the user's intentional information architecture of independent evaluation before convergence.

**Rule:** Always preserve the separation of independently produced inputs unless the user explicitly says 'merge' or 'combine'; comparison means contrast, not synthesis

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (14): dac333f4, c71644cf, b6809eaf, +11 more

---
### Insight (conf=0.78)
> Actions that leave a permanent public trace under the user's identity share a common failure: the agent treats the content as the deliverable and ignores metadata requirements (attribution markers, title flags) that control downstream side effects visible to third parties.

**Rule:** Always verify all required metadata markers and attribution tags are present before any action that posts content under the user's identity to a shared platform

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When the agent creates PRs with required title markers (e.g., [noslack], [nobot]) to suppress downstream noise, it must verify those markers…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, .claude, slack-automation, i-dream, sor
- _Sessions_ (76): a178d6c3, c8bc2450, baf2ac20, +73 more

---
### Insight (conf=0.68)
> The user treats operational governance as documentation-first rather than automation-first: budgets, policies, and healing operations must produce readable audit artifacts, not just function correctly — the agent's instinct to automate silently conflicts with this preference.

**Rule:** Always produce a human-readable log or doc artifact for any automated governance action, including budget tracking, policy enforcement, and state-healing operations

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor
- _Sessions_ (37): 65da91a2, 0744ad2c, f6eee83a, +34 more

---
### Insight (conf=0.75)
> The agent over-delivers by default — long prose when brevity was asked for, checkpoint files when a summary was asked for, safety verdicts when a fact was asked for — all instances of the same scope-inflation tendency where the agent substitutes what it thinks is helpful for what was actually requested.

**Rule:** Always match the output scope exactly to what was requested; never append unrequested artifacts, warnings, or expansions even if they seem helpful

**Evidence:**
- _Pattern_: "Replies that exceed ~1500 chars of prose should lead with the single most important point and defer detail to a linked file; long inline sum…"
- _Pattern_: "Writing a checkpoint or core-dump file when the user asked for a plain summary or plan answer is an unwanted scope expansion that derails th…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (8): -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude
- _Sessions_ (53): d52a521f, 90da8e73, 90d2e6ca, +50 more

---
### Insight (conf=0.77)
> UI work fails at the gestalt level: individual components are technically correct but the agent does not reason about visual coherence across the full surface — whether it is color contrast within a panel, mixed signals in a progress bar, or drawer variants across pages, the common failure is local correctness without global audit.

**Rule:** Always audit the full visual surface and all pages that share a component before declaring any UI work complete

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, claude-instances, speedway
- _Sessions_ (70): 842e701b, f6eee83a, 872653c4, +67 more

---


## Wake Cycle — 2026-10-20 23:01 UTC

### Insight (conf=0.85)
> The agent has a systematic 'verification theater' failure where it substitutes a cheaper proxy check (syntax check, a11y snapshot, editing files) for actual runtime execution, then declares success based on the proxy rather than the real artifact.

**Rule:** Always exercise the actual runtime artifact (live URL, running app, rendered screenshot) before declaring any task complete; never substitute a static or structural check for a runtime one.

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "Before advertising a localhost URL to the user, the agent must navigate to it and exercise its primary action in the same turn to confirm it…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627--claude, enhancement-product, .claude, audio-doctor, sor, landing-app, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -
- _Sessions_ (51): d839657c, c5afbb2f, 067e4644, +48 more

---
### Insight (conf=0.78)
> The agent treats stating intent as partial credit toward completion, creating a pattern where naming future work substitutes for doing it — whether that's a proposal without a tool call, a 'Next' section without execution, or acknowledging a keep-warm need without arming it.

**Rule:** Never end a turn with named pending work unless each item is explicitly labeled as blocked with the specific missing input; if not blocked, execute it before the turn ends.

**Evidence:**
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Projects_ (13): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, slack-automation, .claude, enhancement-product, Affinity, -Users-alcatraz627-Documents-Codex-2026-10-04-mac
- _Sessions_ (34): 20db15be, 97a8cbfb, 83a48450, +31 more

---
### Insight (conf=0.82)
> Style corrections from hooks fail to durably update the agent's generation defaults within a session, suggesting the correction is treated as a one-shot patch rather than a persistent constraint — the same class of error (em-dashes, AI-smell prose, path-before-period) recurs on the very next turn.

**Rule:** Always treat a hook-fired style correction as a session-permanent constraint that applies to every subsequent turn, not just the immediately regenerated one.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Projects_ (30): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (136): 0c39a659, fb13ca88, f9f4c3b2, +133 more

---
### Insight (conf=0.80)
> File paths are a single surface where four distinct rules collide (full path required, must be plain-text visible, must not be hidden in link syntax, must not precede a period), and the agent fails them independently because it lacks a unified 'path emission' routine.

**Rule:** Always emit file paths as standalone plain-text absolute paths followed by a space or comma, never inside Markdown link syntax and never immediately before a period.

**Evidence:**
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp
- _Sessions_ (70): 75119a5e, 43173e49, 0c333593, +67 more

---
### Insight (conf=0.88)
> The agent has a 'premature completion' meta-pattern that manifests across different domains: declaring code done without running it, PRs mergeable without checking state, multi-arm conditions met without exercising all arms, and stop conditions satisfied with background work still running.

**Rule:** Before declaring any condition met, enumerate every explicit criterion in the condition and confirm each one independently with a tool call or verifiable output.

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (21): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, gcp, better-file-browser, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude-codex, codex, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude
- _Sessions_ (102): d839657c, c5afbb2f, 067e4644, +99 more

---
### Insight (conf=0.75)
> The agent defaults to a performative register (verbose PRs, adversarial framing, abstract jargon, decorative formatting) that the user consistently rejects, suggesting the base model's 'professional writing' mode is miscalibrated for this user's plain-language preference.

**Rule:** Always use plain declarative statements in all written artifacts; avoid abstract jargon, adversarial framing, em-dashes, and decorative formatting unless the user explicitly requests a formal register.

**Evidence:**
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, slack-automation
- _Sessions_ (89): 842e701b, f6eee83a, 872653c4, +86 more

---
### Insight (conf=0.68)
> The agent's default behavior collapses multiple independent outputs into a single synthesis, which directly conflicts with workflows that depend on maintaining separate artifacts for comparison or peer review.

**Rule:** Always preserve the structural independence of multiple outputs (plans, reviews, comparisons) unless the user explicitly requests a merge or synthesis.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (7): dac333f4, 0c64e0da, 1a66d7a8, +4 more

---
### Insight (conf=0.72)
> The agent fabricates structural claims (codebase facts, ticket numbers, spec authority) from plausible-sounding inference rather than verified source data, creating a 'confabulation at the knowledge boundary' failure that spans code, docs, and project management.

**Rule:** Never assert a factual claim about codebase structure, ticket existence, or document authority without first reading the relevant source; if unverified, state it as unverified.

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Pattern_: "Referencing ticket or PR numbers in responses or task entries that do not exist in the project's tracked plan is treated as a fabrication fa…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-sys-monitor
- _Sessions_ (95): d63726f5, d049ade6, bc8f0f24, +92 more

---
### Insight (conf=0.62)
> The user treats operational constraints (budgets, thresholds, healing actions) as living doctrine that must be tracked, logged, and self-enforced rather than one-time acknowledgments, revealing a preference for systems that are auditable and self-regulating over those that are merely compliant.

**Rule:** Always log cumulative state and actions taken when operating under a user-defined policy or budget, and surface the audit trail proactively rather than only on request.

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor
- _Sessions_ (37): 65da91a2, 0744ad2c, f6eee83a, +34 more

---
### Insight (conf=0.76)
> Actions taken on shared platforms under the user's identity have irreversible external side effects, and the agent repeatedly fails to apply required markers (attribution, title tags) before pushing, treating them as optional formatting rather than mandatory gates.

**Rule:** Always verify all required identity markers and title tags are present before any push, comment, or post to a shared platform; treat missing markers as a blocking error, not a cosmetic issue.

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When the agent creates PRs with required title markers (e.g., [noslack], [nobot]) to suppress downstream noise, it must verify those markers…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, .claude, slack-automation, i-dream, sor
- _Sessions_ (76): a178d6c3, c8bc2450, baf2ac20, +73 more

---
### Insight (conf=0.70)
> The agent over-produces output by default — long prose, unsolicited artifacts, appended warnings — and the user has to repeatedly constrain it; the underlying failure is that the agent treats 'more is safer' when the user's actual norm is 'only what was asked'.

**Rule:** Always match output scope exactly to what was requested; never append unsolicited artifacts, warnings, or expansions unless they are safety-critical.

**Evidence:**
- _Pattern_: "Prose replies must stay under ~2600 characters; when detail is needed, write it to a file and reference the path rather than expanding inlin…"
- _Pattern_: "Writing a checkpoint or core-dump file when the user asked for a plain summary or plan answer is an unwanted scope expansion that derails th…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (17): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, enhancement-product, landing-app, Affinity, better-file-browser, i-dream, .claude, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (55): 7ffa7dde, 3dcf6fc5, 20db15be, +52 more

---
### Insight (conf=0.65)
> The agent scopes work to the immediate trigger (one page, one feature) rather than auditing the full blast radius, producing locally correct but globally inconsistent changes in both UI architecture and planning documents.

**Rule:** Always audit the full scope of affected surfaces (all pages for a shared component, the full project for a planning doc) before writing any code or document scoped to a single trigger.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product
- _Sessions_ (62): ff8aef13, f95e5eb7, efd2a3ab, +59 more

---


## Wake Cycle — 2026-10-22 05:00 UTC

### Insight (conf=0.80)
> The agent has a systematic 'verification theater' failure where it substitutes a cheaper proxy check (syntax check, a11y snapshot, editing files) for actual runtime execution, then declares success based on the proxy rather than the real artifact.

**Rule:** Always exercise the actual runtime artifact (live URL, running app, rendered screenshot) before declaring any task complete; never substitute a static or structural check for a runtime one.

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "Before advertising a localhost URL to the user, the agent must navigate to it and exercise its primary action in the same turn to confirm it…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627--claude, enhancement-product, .claude, audio-doctor, sor, landing-app, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -
- _Sessions_ (51): d839657c, c5afbb2f, 067e4644, +48 more

---
### Insight (conf=0.73)
> The agent treats stating intent as partial credit toward completion, creating a pattern where naming future work substitutes for doing it — whether that's a proposal without a tool call, a 'Next' section without execution, or acknowledging a keep-warm need without arming it.

**Rule:** Never end a turn with named pending work unless each item is explicitly labeled as blocked with the specific missing input; if not blocked, execute it before the turn ends.

**Evidence:**
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Projects_ (13): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, slack-automation, .claude, enhancement-product, Affinity, -Users-alcatraz627-Documents-Codex-2026-10-04-mac
- _Sessions_ (34): 20db15be, 97a8cbfb, 83a48450, +31 more

---
### Insight (conf=0.77)
> Style corrections from hooks fail to durably update the agent's generation defaults within a session, suggesting the correction is treated as a one-shot patch rather than a persistent constraint — the same class of error (em-dashes, AI-smell prose, path-before-period) recurs on the very next turn.

**Rule:** Always treat a hook-fired style correction as a session-permanent constraint that applies to every subsequent turn, not just the immediately regenerated one.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Projects_ (30): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (136): 0c39a659, fb13ca88, f9f4c3b2, +133 more

---
### Insight (conf=0.75)
> File paths are a single surface where four distinct rules collide (full path required, must be plain-text visible, must not be hidden in link syntax, must not precede a period), and the agent fails them independently because it lacks a unified 'path emission' routine.

**Rule:** Always emit file paths as standalone plain-text absolute paths followed by a space or comma, never inside Markdown link syntax and never immediately before a period.

**Evidence:**
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp
- _Sessions_ (70): 75119a5e, 43173e49, 0c333593, +67 more

---
### Insight (conf=0.83)
> The agent has a 'premature completion' meta-pattern that manifests across different domains: declaring code done without running it, PRs mergeable without checking state, multi-arm conditions met without exercising all arms, and stop conditions satisfied with background work still running.

**Rule:** Before declaring any condition met, enumerate every explicit criterion in the condition and confirm each one independently with a tool call or verifiable output.

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (21): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, gcp, better-file-browser, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude-codex, codex, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude
- _Sessions_ (102): d839657c, c5afbb2f, 067e4644, +99 more

---
### Insight (conf=0.70)
> The agent defaults to a performative register (verbose PRs, adversarial framing, abstract jargon, decorative formatting) that the user consistently rejects, suggesting the base model's 'professional writing' mode is miscalibrated for this user's plain-language preference.

**Rule:** Always use plain declarative statements in all written artifacts; avoid abstract jargon, adversarial framing, em-dashes, and decorative formatting unless the user explicitly requests a formal register.

**Evidence:**
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, slack-automation
- _Sessions_ (89): 842e701b, f6eee83a, 872653c4, +86 more

---
### Insight (conf=0.63)
> The agent's default behavior collapses multiple independent outputs into a single synthesis, which directly conflicts with workflows that depend on maintaining separate artifacts for comparison or peer review.

**Rule:** Always preserve the structural independence of multiple outputs (plans, reviews, comparisons) unless the user explicitly requests a merge or synthesis.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (7): dac333f4, 0c64e0da, 1a66d7a8, +4 more

---
### Insight (conf=0.67)
> The agent fabricates structural claims (codebase facts, ticket numbers, spec authority) from plausible-sounding inference rather than verified source data, creating a 'confabulation at the knowledge boundary' failure that spans code, docs, and project management.

**Rule:** Never assert a factual claim about codebase structure, ticket existence, or document authority without first reading the relevant source; if unverified, state it as unverified.

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Pattern_: "Referencing ticket or PR numbers in responses or task entries that do not exist in the project's tracked plan is treated as a fabrication fa…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-sys-monitor
- _Sessions_ (95): d63726f5, d049ade6, bc8f0f24, +92 more

---
### Insight (conf=0.57)
> The user treats operational constraints (budgets, thresholds, healing actions) as living doctrine that must be tracked, logged, and self-enforced rather than one-time acknowledgments, revealing a preference for systems that are auditable and self-regulating over those that are merely compliant.

**Rule:** Always log cumulative state and actions taken when operating under a user-defined policy or budget, and surface the audit trail proactively rather than only on request.

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor
- _Sessions_ (37): 65da91a2, 0744ad2c, f6eee83a, +34 more

---
### Insight (conf=0.71)
> Actions taken on shared platforms under the user's identity have irreversible external side effects, and the agent repeatedly fails to apply required markers (attribution, title tags) before pushing, treating them as optional formatting rather than mandatory gates.

**Rule:** Always verify all required identity markers and title tags are present before any push, comment, or post to a shared platform; treat missing markers as a blocking error, not a cosmetic issue.

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When the agent creates PRs with required title markers (e.g., [noslack], [nobot]) to suppress downstream noise, it must verify those markers…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, .claude, slack-automation, i-dream, sor
- _Sessions_ (76): a178d6c3, c8bc2450, baf2ac20, +73 more

---
### Insight (conf=0.65)
> The agent over-produces output by default — long prose, unsolicited artifacts, appended warnings — and the user has to repeatedly constrain it; the underlying failure is that the agent treats 'more is safer' when the user's actual norm is 'only what was asked'.

**Rule:** Always match output scope exactly to what was requested; never append unsolicited artifacts, warnings, or expansions unless they are safety-critical.

**Evidence:**
- _Pattern_: "Prose replies must stay under ~2600 characters; when detail is needed, write it to a file and reference the path rather than expanding inlin…"
- _Pattern_: "Writing a checkpoint or core-dump file when the user asked for a plain summary or plan answer is an unwanted scope expansion that derails th…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (17): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, enhancement-product, landing-app, Affinity, better-file-browser, i-dream, .claude, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (55): 7ffa7dde, 3dcf6fc5, 20db15be, +52 more

---
### Insight (conf=0.60)
> The agent scopes work to the immediate trigger (one page, one feature) rather than auditing the full blast radius, producing locally correct but globally inconsistent changes in both UI architecture and planning documents.

**Rule:** Always audit the full scope of affected surfaces (all pages for a shared component, the full project for a planning doc) before writing any code or document scoped to a single trigger.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product
- _Sessions_ (62): ff8aef13, f95e5eb7, efd2a3ab, +59 more

---
### Insight (conf=0.85)
> The agent systematically confuses declaring intent with completing action — stating a goal, editing a file, or citing a URL each feel like 'done' but none constitute verified execution, revealing a pervasive say-do gap.

**Rule:** Always execute and observe the actual runtime effect of a change before declaring any task complete or any resource live.

**Evidence:**
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "Before advertising a localhost URL to the user, the agent must navigate to it and exercise its primary action in the same turn to confirm it…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Projects_ (18): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, slack-automation, .claude, enhancement-product, Affinity, -Users-alcatraz627-Code-Versable-sor, audio-doctor, sor, landing-app, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder
- _Sessions_ (47): 20db15be, 97a8cbfb, 83a48450, +44 more

---
### Insight (conf=0.72)
> Style-gate violations persist across consecutive corrections because the offending patterns are baked into the model's default register at the token-prediction level, not at a 'rule-checking' layer — single corrections don't override sampling priors, requiring an active suppression pass before emission rather than post-hoc filtering.

**Rule:** Always perform a dedicated style-compliance scan of the entire draft reply before emitting it, treating em-dashes, excessive bold, and contrast scaffolding as hard errors to rewrite, not soft warnings to note.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (31): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, enhancement-product
- _Sessions_ (158): 0c39a659, fb13ca88, f9f4c3b2, +155 more

---
### Insight (conf=0.78)
> The agent substitutes cheaper proxy evidence (syntax checks, a11y snapshots, structural assumptions) for actual ground-truth verification, and each proxy feels sufficient in the moment — a shared epistemic shortcut where 'close enough to knowing' is treated as knowing.

**Rule:** Always distinguish between proxy evidence and ground-truth evidence when verifying a claim, and never declare verification complete using only proxy evidence.

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (67): d839657c, c5afbb2f, 067e4644, +64 more

---
### Insight (conf=0.80)
> The agent treats turn boundaries as implicit pause points, listing remaining work as 'next steps' rather than continuing execution — turn-end is mistaken for a natural stopping point even when the task is incomplete and no blocker exists.

**Rule:** Never end a turn with named pending work unless each item is explicitly labeled as blocked with the specific missing input; if no blocker exists, execute the work in the same turn.

**Evidence:**
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (14): -Users-alcatraz627-Documents-Codex-2026-10-04-mac, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627--claude, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, .claude, enhancement-product, Affinity, i-dream
- _Sessions_ (42): 58f5414c, b74c0be6, 38d3e596, +39 more

---
### Insight (conf=0.82)
> Four separate rules address file-path rendering in output, revealing that the agent's default path-citation behavior is broken in multiple independent ways — truncation, link-hiding, and punctuation collision — all stemming from treating paths as inline prose elements rather than as structured references with their own formatting constraints.

**Rule:** Always emit file paths as standalone plain-text absolute strings followed by a space or comma, never inside Markdown link syntax, never truncated to basename, and never immediately before a period.

**Evidence:**
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp
- _Sessions_ (70): 75119a5e, 43173e49, 0c333593, +67 more

---
### Insight (conf=0.75)
> The agent's written artifacts (PRs, plans, docs) default to a verbose, evaluative, jargon-laden register that the user consistently rejects — the same 'default LLM voice' problem that appears in prose replies also infects every document type the agent produces.

**Rule:** Always write authored documents (PRs, plans, proposals) in plain declarative prose stating what changed or what will happen, without evaluative framing, abstract jargon, or adversarial tone toward existing state.

**Evidence:**
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "Prose replies must stay under ~2600 characters; when detail is needed, write it to a file and reference the path rather than expanding inlin…"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, landing-app, Affinity, better-file-browser
- _Sessions_ (88): 842e701b, f6eee83a, 872653c4, +85 more

---
### Insight (conf=0.80)
> The agent repeatedly declares shared-state operations (merges, PRs, multi-environment deploys) complete without running the specific gate check that would confirm completeness — a pattern of skipping the final verification step precisely when the cost of being wrong is highest (irreversible external effects).

**Rule:** Always run the explicit state-verification command for any shared-state operation (merge readiness, deploy status, marker presence) before declaring it complete, even if all prior steps succeeded.

**Evidence:**
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Pattern_: "When the agent creates PRs with required title markers (e.g., [noslack], [nobot]) to suppress downstream noise, it must verify those markers…"
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Projects_ (28): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, gcp, better-file-browser, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627--claude, .claude, slack-automation, i-dream, sor, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude, audio-doctor, landing-app, enhancement-product, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-codex, codex
- _Sessions_ (107): fb88b328, f67f42ae, f0272391, +104 more

---
### Insight (conf=0.68)
> The agent defaults to synthesis and consolidation when the user's workflow explicitly requires keeping inputs separate and adversarial — the agent's helpfulness instinct to 'resolve' conflicts directly opposes deliberate divergence-preserving workflows like peer review and plan comparison.

**Rule:** Always preserve the independence of separate inputs (plans, reviews, specs) unless the user explicitly requests a merge; treat 'compare' as contrast, not synthesis.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (14): dac333f4, 0c64e0da, 1a66d7a8, +11 more

---
### Insight (conf=0.65)
> Resource governance (token budgets, sub-agent scope, disk thresholds) shares a common failure mode: the agent acknowledges the constraint verbally but does not instrument ongoing enforcement — policy is recorded but not operationalized into per-action checks.

**Rule:** Always implement active per-turn tracking for any resource constraint the user sets, rather than acknowledging it once and relying on memory.

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When spawning multiple sub-agents, the agent should scope each agent tightly to avoid burning excessive API usage, and inform the user of th…"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, landing-app, Affinity, better-file-browser, i-dream, .claude, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend
- _Sessions_ (49): 65da91a2, 0744ad2c, f6eee83a, +46 more

---
### Insight (conf=0.70)
> The agent fails to model audience boundaries — conversational tone leaks into stakeholder documents, and agent identity is not disclosed on shared platforms — because it treats all output as having the same audience (the current user in the current chat).

**Rule:** Always identify the final audience of any output before drafting, and apply audience-specific constraints (attribution markers, tone, confidentiality) as hard requirements, not style suggestions.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban
- _Sessions_ (77): d8f1948c, a0f35401, 8c7e6f5c, +74 more

---
### Insight (conf=0.62)
> UI work fails at the coherence level rather than the correctness level — individual components are technically right but the holistic signal (visual hierarchy, progress state, shared shell consistency) is contradictory, suggesting the agent builds UI bottom-up without a top-down coherence check.

**Rule:** Always audit the holistic visual and structural coherence of a UI change across all affected pages before declaring it complete, not just the correctness of the individual component.

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, claude-instances, speedway
- _Sessions_ (70): 842e701b, f6eee83a, 872653c4, +67 more

---
### Insight (conf=0.60)
> Time-sensitive background obligations (keep-warm, IPC gates, in-flight workflows) share a failure mode where the agent does not treat them as interrupts with deadlines — they are noted but not prioritized, causing timeouts and cold-cache penalties.

**Rule:** Always treat time-sensitive background obligations as highest-priority interrupts that must be resolved in the current turn before any other work.

**Evidence:**
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Pattern_: "IPC push-gate approval messages must be answered in the same turn they arrive; leaving them unanswered triggers a stop-hook reminder on the …"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, slack-automation, .claude, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-Affinity, landing-app, better-file-browser, Affinity, i-dream
- _Sessions_ (46): 842e701b, 0744ad2c, f6eee83a, +43 more

---
