# Dream Insights

_High-confidence associations promoted by the Wake phase._

## Wake Cycle — 2026-08-11 00:20 UTC

### Insight (conf=0.91)
> The agent treats each page/surface as an isolated scope even when the codebase proves a global pattern exists — drawers, pagination, and shared components all exhibit the same 'fix one instance, ignore siblings' failure because the agent scopes by current file rather than by architectural pattern.

**Rule:** Always grep for all consumers of a shared pattern (component, layout, pagination) before implementing a fix on one page — if the pattern appears on N pages, the change applies to N pages.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.88)
> False completion claims form a spectrum from 'never ran it' through 'ran it but didn't look' to 'looked but dismissed what I saw' — all three are the same trust-destroying event to the user, differing only in how deep the agent's self-deception goes.

**Rule:** Avoid claiming a fix is verified unless the verification step produced a specific observable result you can cite — 'I checked and it looked fine' without naming what you saw is the same failure as not checking.

**Evidence:**
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (6): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (106): e3cbc32f, 302d5d15, 27238870, +103 more

---
### Insight (conf=0.87)
> Autonomous agent sessions have a systemic inability to handle external blocking events (auth prompts, usage limits, orchestrator death) — the failure mode is always silent stall rather than graceful degradation, and the only proven recovery pattern is explicit surfacing to the user with the exact unblocking command.

**Rule:** Always surface any blocking event that requires human intervention within 30 seconds of detection, including the exact command or action needed — never attempt workarounds or wait silently for external blocks to resolve.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-automation, walmart-mvp, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (121): f4686e13, efd2a3ab, e6c58221, +118 more

---
### Insight (conf=0.85)
> The agent substitutes its own derived artifacts (formalized docs, mental models, naming conventions) for upstream authority (user specs, design mocks, actual source code) — all three patterns are the same epistemological error of treating a derivative as a primary source.

**Rule:** Always trace any claim about what should exist back to its upstream authority (user spec, design mock, source code) before acting on it — never treat an agent-authored formalization or mental model as the source of truth.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, i-dream, .claude, claude-ipc
- _Sessions_ (84): eb07961e, e3bde638, e01b73ba, +81 more

---
### Insight (conf=0.84)
> The agent's verification and review scope contracts to the single most visible state of a multi-state surface — it checks dark mode but not light, fixes copy but not title, sweeps one area deeply while leaving others unbuilt — because it satisfies a 'did I check?' internal flag without tracking coverage across the surface's actual state space.

**Rule:** Always enumerate all states of a multi-state surface (visual modes, sub-elements, sibling pages) before beginning verification, and track coverage explicitly — a single-state check must be reported as partial, never as complete.

**Evidence:**
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "Claiming a specific UI sub-issue is fixed without verifying the full rendered state of the containing element leads to adjacent problems sur…"
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, .claude, i-dream, versable-builder, claude-ipc, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude, frontend, enhancement-product, local-models
- _Sessions_ (90): faeb2f37, efd2a3ab, ed1b2d1b, +87 more

---
### Insight (conf=0.83)
> IPC and inter-agent communication suffers from a consistent send-side-only verification pattern — the agent checks that it sent/triggered something but never verifies arrival, whether that's a message reaching a peer, an artifact landing on disk, or content surviving shell escaping.

**Rule:** Always verify the receive side of any inter-agent communication — read the file, await the round-trip reply, or check the escaped output — before treating the operation as successful.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When sending IPC replies from a shell command, backticks and special characters in the message body get consumed by the shell and produce ze…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, enhancement-product
- _Sessions_ (75): dfd19dc0, 96490d11, 895cfd88, +72 more

---
### Insight (conf=0.82)
> The agent treats deferral as disposal — when items are queued for later review, it strips the decision context needed to act on them, making the deferred-review workflow the user prefers structurally unusable without follow-up questions.

**Rule:** Always include the original decision context, concrete options, and any prior constraints when presenting a deferred item for review — a deferred item without actionable context is a dead item.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627-Code-Versable-enhancement-product-frontend
- _Sessions_ (115): f4686e13, efd2a3ab, e6c58221, +112 more

---
### Insight (conf=0.80)
> Data pipeline verification degrades from 'exercise against real data' to 'spot-check the shape' as pipeline complexity grows — filters that pass out-of-scope items, null coercions dismissed as acceptable, and zero-result sources reported without diagnostic detail are all symptoms of verification effort not scaling with data heterogeneity.

**Rule:** Always exercise data pipeline output against the full actual dataset and surface per-source diagnostics before delivery — shape-level verification on heterogeneous data is structurally insufficient.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, ig-download, .claude
- _Sessions_ (92): eb618fff, c71644cf, b449e2ee, +89 more

---
### Insight (conf=0.80)
> The agent lacks an audience-gate at the output boundary — it leaks internal-register content (banter, risk warnings, evaluative commentary) into external-facing documents because it does not enforce a hard separation between conversational context and publishable output.

**Rule:** Always re-read any document destined for external sharing through the lens of 'would I be comfortable if only this document existed, with no surrounding conversation' — strip all conversational artifacts and unsolicited editorial commentary.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When writing a document that will be shared externally, all internal banter, critique, and conversational framing about stakeholders must be…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, two-enhancement-product, better-file-browser, sys-monitor, its-my-config, staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (62): d8f1948c, a0f35401, 8c7e6f5c, +59 more

---
### Insight (conf=0.78)
> Multi-agent coordination degrades catastrophically across context boundaries (clears, crashes, limit hits) because peer identity and task ownership are held in ephemeral conversation state rather than in durable checkpoints — every context reset forces manual re-introduction and risks overlapping claims.

**Rule:** Always record peer agent aliases, negotiated task ownership, and coordination state in the checkpoint file — context boundaries must not break multi-agent coordination.

**Evidence:**
- _Pattern_: "In a multi-agent setup where sessions are regularly context-cleared, each agent's checkpoint should record the peer agent's IPC alias so the…"
- _Pattern_: "When multiple agents work in parallel on the same codebase, they must pre-negotiate task ownership via IPC before starting work; overlapping…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (69): d8f1948c, a0f35401, 8c7e6f5c, +66 more

---
### Insight (conf=0.75)
> The agent's progress-reporting failures and unnecessary pausing are two expressions of the same broken feedback loop — it either reports nothing (stale task list, silent continuation) or reports too often (halting for permission on trivial steps), never matching the user's actual information needs.

**Rule:** Always update the task list after each logical unit of work AND continue autonomously on terse signals — the correct cadence is 'show progress continuously, ask only at genuine decision points.'

**Evidence:**
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, two-enhancement-product, invasion-of-the-fiber-snatchers, frontend
- _Sessions_ (136): c250f2e7, c1ff831f, bf8b308d, +133 more

---


## Wake Cycle — 2026-08-12 05:41 UTC

### Insight (conf=0.75)
> The user's preferred deferred-review workflow is systematically undermined by two failures that make deferred items useless: stripping decision context at deferral time and letting the task list drift from reality — the deferral system is designed but its inputs are starved.

**Rule:** When deferring an item to a review backlog, always include the prior decision context, concrete options, and current task-list state at the moment of deferral — a deferred item without its context is a dead letter.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config
- _Sessions_ (128): 9ed3de6d, 849b6ec8, 302d5d15, +125 more

---
### Insight (conf=0.73)
> The agent consistently verifies one dimension of a multi-dimensional surface and reports it as fully verified — one visual mode, one sub-element, one filter criterion, one pass over output — a partial verification that is presented as complete, which the user experiences as worse than no verification because it creates false confidence.

**Rule:** When verifying a multi-dimensional surface (visual modes, sub-elements, filter criteria, output rows), enumerate the dimensions first and explicitly scope the verification claim to what was actually checked — never present a single-dimension check as full verification.

**Evidence:**
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "Claiming a specific UI sub-issue is fixed without verifying the full rendered state of the containing element leads to adjacent problems sur…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, .claude, i-dream, versable-builder, claude-ipc, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (124): faeb2f37, efd2a3ab, ed1b2d1b, +121 more

---
### Insight (conf=0.72)
> The agent systematically treats the act of signaling completion (sending, notifying, claiming, assessing) as equivalent to verified completion, across IPC, sub-agent handoffs, UI fixes, and gap analyses — a single 'emission equals arrival' fallacy that manifests differently in each domain.

**Rule:** Always verify at the RECEIVER's end (the file on disk, the rendered UI, the peer's reply, the actual code) before treating any completion signal as proof — the signal is the claim, not the evidence.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (75): dfd19dc0, 96490d11, 895cfd88, +72 more

---
### Insight (conf=0.70)
> The user consistently values seeing divergent options before resolution — premature synthesis (merging plans, collapsing peer reviews, wholesale adopting dead agent work) destroys the decision space the user needs to exercise judgment, and is experienced as the agent making choices on their behalf.

**Rule:** When presenting multiple independently-produced outputs (plans, reviews, agent work), always present them as distinct items with explicit contrasts before any synthesis — merge only on explicit instruction.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26
- _Sessions_ (7): dac333f4, c71644cf, b6809eaf, +4 more

---
### Insight (conf=0.68)
> Four different failure modes share the same structural shape: assuming a shared resource (browser MCP, orchestrator session, API quota, OAuth credential) will remain available throughout an autonomous run without pre-checking availability or planning a fallback — the blast radius scales with how many downstream agents are blocked when the assumption breaks.

**Rule:** Before dispatching any autonomous agent chain that depends on a shared resource (API quota, browser instance, auth session, orchestrator liveness), verify current availability AND define the fallback behavior if the resource disappears mid-run.

**Evidence:**
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-automation
- _Sessions_ (154): df9392bb, 0c39a659, fdeb9ed4, +151 more

---
### Insight (conf=0.67)
> Information present in one agent context systematically fails to survive async boundaries (context clears, orchestrator death, deferral queues) because the checkpoint/handoff format preserves task momentum but drops the metadata needed to resume coordination — peer aliases, decision context, and liveness state are all 'non-task' information that gets trimmed.

**Rule:** When checkpointing across an async boundary (context clear, deferral, orchestrator handoff), explicitly preserve coordination metadata (peer aliases, decision context, resource liveness) alongside task state — task momentum without coordination metadata produces a resumed session that can work but cannot coordinate.

**Evidence:**
- _Pattern_: "In a multi-agent setup where sessions are regularly context-cleared, each agent's checkpoint should record the peer agent's IPC alias so the…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (69): d8f1948c, a0f35401, 8c7e6f5c, +66 more

---
### Insight (conf=0.65)
> The agent treats whatever artifact is closest at hand as authoritative, confusing upstream sources (user specs, design mocks) with downstream derivatives (agent-authored formalizations, agent-generated code) — proximity to the working context is mistaken for position in the derivation chain.

**Rule:** Before using any document as the authority in a gap audit, feature plan, or validation check, verify whether it is upstream (user-authored spec, design mock) or downstream (agent-derived formalization) — only upstream documents are authoritative.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "Validating another agent's output against standing project constraints (e.g. style rules, UI invariants) before merging or shipping catches …"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, claude-instances
- _Sessions_ (98): eb07961e, e3bde638, e01b73ba, +95 more

---
### Insight (conf=0.62)
> The agent conflates the execution axis with the decision axis: it pauses for permission on mechanical execution steps (where the user wants autonomy) and silently resolves product-level decisions (where the user wants to be consulted) — the boundary between 'proceed' and 'surface' is misdrawn at the reversibility line, not the complexity line.

**Rule:** Avoid pausing for permission on reversible execution steps unless blocked; always surface product-level behavioral decisions explicitly — the halt criterion is 'does this choose a direction the user hasn't approved' not 'is this step complex'.

**Evidence:**
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (143): 5d07ffa1, 5b904ac8, 5774c57d, +140 more

---
### Insight (conf=0.58)
> The user wants breadth-first DELIVERY across surfaces but exhaustive CORRECTNESS within each delivered unit — these look contradictory but resolve as: sweep all surfaces at v1 depth first, but within each surface touched, audit all instances of the pattern being changed before moving on.

**Rule:** When sweeping breadth-first, apply each pattern change exhaustively across all instances within its scope before advancing to the next surface — breadth-first is about surface coverage order, not permission to leave partial fixes behind.

**Evidence:**
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (122): d8f1948c, a0f35401, 8c7e6f5c, +119 more

---
### Insight (conf=0.55)
> The agent models its audience as the immediate conversation partner and misses that outputs cross audience boundaries — documents shared with external stakeholders, file paths read by users outside the session, factual answers consumed without the surrounding chat context — producing content that is appropriate for the chat but inappropriate for its actual reader.

**Rule:** Before finalizing any output artifact, identify its actual downstream reader (which may not be the chat partner) and audit for content that is appropriate in-chat but inappropriate for that reader — banter in shared docs, basenames without paths, unsolicited editorializing on factual answers.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (51): d8f1948c, a0f35401, 8c7e6f5c, +48 more

---


## Wake Cycle — 2026-08-12 07:48 UTC

### Insight (conf=0.91)
> There is a recurring pattern where the agent's verification is structurally incomplete — checking a filter without exercising it against real data, claiming a fix without running the dev server, dismissing a noticed anomaly as acceptable, or assessing gaps without reading source — all variants of declaring confidence from partial evidence.

**Rule:** Always exercise the verification against the actual artifact (real data, running server, source code) rather than reasoning about expected behavior — confidence from inspection alone is structurally unsound.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (10): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude
- _Sessions_ (72): eb618fff, c71644cf, b449e2ee, +69 more

---
### Insight (conf=0.88)
> The agent has a systematic failure to treat per-page instances as members of a global class — whether it's a shared drawer component, a pagination pattern, or a fix that applies to sibling pages — always scoping to the immediate callsite instead of auditing the full surface area.

**Rule:** Always grep for all instances of the pattern/component across the full application before writing any fix, and include all sites in the same change — never treat a globally-shared concern as a single-page scope.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.87)
> The agent substitutes its own derived artifacts (formalized concept docs, inferred naming conventions) for the actual upstream authority (user-authored specs, design mocks) — in both cases the derivation looks reasonable but inverts the authority chain, producing work that confidently diverges from what was actually specified.

**Rule:** Always consult the original user-authored authority (product spec, design mocks, user naming) before any agent-derived formalization or convention — a derived document is a summary, never a source.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc
- _Sessions_ (72): eb07961e, e3bde638, e01b73ba, +69 more

---
### Insight (conf=0.85)
> Resource contention failures (usage limits, subscription caps, browser locks) share a common shape: the blocked entity stalls silently with no self-reporting or fallback, leaving the system in an indeterminate state that only the user can diagnose — the architecture assumes resources are always available rather than designing for their absence.

**Rule:** Always design agent resource acquisition (API quotas, browser MCPs, IPC channels) with an explicit timeout and self-report mechanism — a blocked agent must surface its blocked state within 60 seconds rather than waiting indefinitely.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, versable-builder, walmart-mvp
- _Sessions_ (138): f4686e13, efd2a3ab, e6c58221, +135 more

---
### Insight (conf=0.84)
> The agent systematically underestimates the user's expectation of completeness for anything that aggregates or filters across multiple sources/dimensions — whether it's a per-source filter missing from a multi-source UI, a gap assessment made without reading all files, or a filter that doesn't cover all stated criteria — the common failure is treating partial coverage as sufficient.

**Rule:** When building any aggregation, filter, or assessment that spans multiple sources or criteria, enumerate all sources/criteria explicitly before implementation and verify each one is represented — partial coverage of a multi-dimensional surface is always a bug.

**Evidence:**
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Projects_ (10): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (120): df9392bb, 0c39a659, fdeb9ed4, +117 more

---
### Insight (conf=0.83)
> IPC and inter-agent communication has three distinct failure modes that are all variants of trusting the send-side: trusting that a send succeeded (without round-trip confirmation), trusting that a notification means the artifact exists (without disk verification), and trusting that a shell-constructed message arrived intact (without quoting validation) — all are one-sided evidence treated as proof.

**Rule:** Always verify IPC outcomes at the receiving end — confirm round-trip replies for delivery, check disk for artifacts after notifications, and validate message integrity after shell construction — send-side evidence is never proof of receipt.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When sending IPC replies from a shell command, backticks and special characters in the message body get consumed by the shell and produce ze…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, enhancement-product
- _Sessions_ (75): dfd19dc0, 96490d11, 895cfd88, +72 more

---
### Insight (conf=0.82)
> Across different domains (deferred decisions, file citations, scraping results), the agent consistently strips the context the user needs to act without a follow-up — omitting decision options, full paths, or checked endpoints — forcing an unnecessary round-trip that the user experiences as friction.

**Rule:** Always include the minimum actionable context (concrete options, full paths, checked sources) in every surfaced item so the user can act in one read without a follow-up question.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, ig-download, .claude
- _Sessions_ (94): f4686e13, efd2a3ab, e6c58221, +91 more

---
### Insight (conf=0.80)
> Auth/credential blocks follow a spectrum: the correct behavior is always to surface the exact blocker and hand control to the user (or the parent agent), but the agent's failure modes are either silent stalling or attempting workarounds — both of which waste more time than the explicit handoff. The harness-enforced handoff pattern (sub-agent returns text when write is blocked) is the mechanical version of the same principle.

**Rule:** When any agent hits an auth, credential, or permission block it cannot resolve, immediately surface the exact command or action the user needs to take and halt — never attempt workarounds or stall silently, and if a write channel is blocked, return the full content via the available channel.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (6): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (41): faeb2f37, efd2a3ab, ed1b2d1b, +38 more

---
### Insight (conf=0.79)
> Fixing one visible sub-issue within a containing element while ignoring adjacent sub-issues in the same element is a recurring pattern across both UI (copy fixed but title broken and padding untouched) and data pipelines (null coercion noticed but dismissed as acceptable) — the agent treats each symptom as independent rather than auditing the full element state.

**Rule:** When fixing any issue within a containing element (UI component, data record, pipeline stage), audit all sibling properties of that element before reporting the fix complete — never declare a sub-issue fixed without verifying the full element state.

**Evidence:**
- _Pattern_: "Claiming a specific UI sub-issue is fixed without verifying the full rendered state of the containing element leads to adjacent problems sur…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Projects_ (9): -Users-alcatraz627-Code-Versable-versable-builder, .claude, i-dream, versable-builder, claude-ipc, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (107): ff780782, fb3008e7, fa1dc4a5, +104 more

---
### Insight (conf=0.78)
> The user's multi-agent workflow design philosophy is strict separation-then-explicit-merge: independent agents produce independent outputs, comparisons stay side-by-side, and coordination happens via explicit negotiation — the agent's instinct to collapse, merge, or unify multiple outputs into one prematurely violates the deliberate parallelism the user designed.

**Rule:** Always preserve independent agent outputs as separate artifacts until the user explicitly requests a merge — never collapse parallel outputs into a synthesis, and present comparisons as side-by-side contrasts, not blended summaries.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "When multiple agents work in parallel on the same codebase, they must pre-negotiate task ownership via IPC before starting work; overlapping…"
- _Projects_ (14): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models
- _Sessions_ (26): dac333f4, 0c64e0da, 1a66d7a8, +23 more

---
### Insight (conf=0.76)
> Multi-agent architectures degrade at context boundaries (compaction, clear, crash) because coordination metadata (peer aliases, blocked-agent state, salvageable partial work) is not persisted in a form that survives the boundary — the system works within a session but breaks across sessions.

**Rule:** Always persist multi-agent coordination state (peer aliases, pending IPC, blocked-agent inventory, salvageable partial outputs) in the checkpoint before any context boundary — coordination metadata that only lives in conversation context is lost on clear/compact/crash.

**Evidence:**
- _Pattern_: "In a multi-agent setup where sessions are regularly context-cleared, each agent's checkpoint should record the peer agent's IPC alias so the…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, i-dream
- _Sessions_ (75): d8f1948c, a0f35401, 8c7e6f5c, +72 more

---
### Insight (conf=0.75)
> The agent fails to recognize audience boundaries — silently resolving product decisions that belong to the user, inserting private commentary into potentially-shared documents, and appending evaluative judgments to factual answers — all are cases where content crosses an implicit boundary the agent should respect but doesn't detect.

**Rule:** Always assess the downstream audience of any output before finalizing it — product decisions surface to the user as questions, documents assume they may be shared externally, and factual answers stay factual without appended judgments.

**Evidence:**
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (97): fef81fe8, f553b9c0, ec997359, +94 more

---
### Insight (conf=0.72)
> The user's preferred work rhythm has two conflicting needs — defer non-critical reviews to a backlog (don't interrupt flow), but keep the live status surface updated in real-time (don't let the task list drift). The agent fails in both directions: batching status updates violates the live-surface contract, while interrupting for reviews violates the deferred-review preference. The reconciliation is that status tracking and decision review are different altitudes.

**Rule:** Always update task status immediately after each logical unit (the live-surface contract), but defer review/approval of completed non-critical items to a queued backlog unless the user explicitly asks for immediate review.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, two-enhancement-product, invasion-of-the-fiber-snatchers, frontend
- _Sessions_ (103): 9ed3de6d, 849b6ec8, 302d5d15, +100 more

---
### Insight (conf=0.68)
> The agent has a temporal-degradation pattern with style/convention compliance: it can identify the correct pattern (no em-dashes, match sibling JSX style, test both visual modes) but fails to sustain compliance across a session, requiring multiple correction cycles — the knowledge is present but the application decays under workload.

**Rule:** When a style or convention correction is received mid-session, apply it as a pre-send checklist item for all remaining outputs in the session — don't rely on having internalized the correction, mechanically re-check each output against it.

**Evidence:**
- _Pattern_: "The agent generates em-dashes and excessive bold spans in prose even after a stop-hook explicitly flags them and demands re-emission, requir…"
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Projects_ (6): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (118): df9392bb, 0c39a659, fdeb9ed4, +115 more

---


## Wake Cycle — 2026-08-12 17:49 UTC

### Insight (conf=0.72)
> The agent can accept a deferral instruction but cannot maintain deferred items over time — any work pushed to 'later' degrades because context is stripped at the handoff boundary, making the deferred queue structurally useless despite being the user's preferred workflow.

**Rule:** Always persist the original decision context, concrete options, and triggering rationale alongside any item deferred to a backlog — a deferred item without its context is a dead item.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config
- _Sessions_ (128): 9ed3de6d, 849b6ec8, 302d5d15, +125 more

---
### Insight (conf=0.68)
> Across unrelated domains (IPC delivery, UI component audit, data filtering, visual review), the agent consistently checks ONE representative instance and infers completeness of the whole — send-side telemetry standing for delivery is structurally identical to one page standing for all pages or one visual mode standing for both.

**Rule:** Always enumerate the full instance set before verifying — when the check is 'does X hold everywhere', listing the 'everywhere' is the first step, not a refinement.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, i-dream, speedway, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (135): dfd19dc0, 96490d11, 895cfd88, +132 more

---
### Insight (conf=0.65)
> These are mirror-image derivation-chain violations: one treats a downstream agent-authored formalization as upstream authority, the other ignores upstream design mocks and derives from downstream code conventions — the agent lacks a stable model of which artifacts are sources vs derivatives.

**Rule:** Always identify whether an artifact is upstream (human-authored spec, design mock) or downstream (agent-generated doc, code convention) before using it as a source of truth — never cite a derivative as authority or ignore a source in favor of its derivatives.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc
- _Sessions_ (72): eb07961e, e3bde638, e01b73ba, +69 more

---
### Insight (conf=0.63)
> The agent defaults to generating from its own internal model (an IIFE pattern it knows, a label from naming conventions, a fresh pagination implementation) rather than reading what already exists in the immediate neighborhood — the 10-line scan of siblings that would reveal the local convention is consistently skipped in favor of the agent's generic knowledge.

**Rule:** Always scan the 10 nearest siblings (adjacent components, sibling pages, nearby functions) before writing any pattern into a file — the local convention outranks the agent's generic knowledge of 'how this is usually done.'

**Evidence:**
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, versable-builder
- _Sessions_ (148): be09b94d, bb714e4b, baa1f8e5, +145 more

---
### Insight (conf=0.62)
> Silent stalls from external dependency failures (usage limits, orchestrator death, interactive auth) share a common architectural gap: no agent in the system is responsible for detecting and surfacing the block — each assumes someone else will notice, producing indefinite hangs that only the human discovers.

**Rule:** Always implement a timeout-and-surface pattern for any wait on an external dependency (auth, quota, peer agent, resource lock) — if the dependency hasn't responded within a bounded interval, surface the block to the user rather than waiting indefinitely.

**Evidence:**
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (105): 0c39a659, ec7e7f48, d3e36a3a, +102 more

---
### Insight (conf=0.60)
> The agent treats its output as ephemeral conversation artifacts when the user treats them as durable, shareable documents with audiences beyond the current session — a document shared with stakeholders, a path a human will click, and infrastructure docs a team will reference all fail when the agent writes for itself rather than for the downstream reader.

**Rule:** Always assume any written artifact may be read by someone who was not in this conversation — use full paths, omit private banter, and place documentation where its audience can find it independently.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "Infrastructure documentation such as deploy strategies and pipeline configurations should be written in project-visible locations, not only …"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, claude-instances
- _Sessions_ (49): d8f1948c, a0f35401, 8c7e6f5c, +46 more

---


## Wake Cycle — 2026-08-13 00:20 UTC

### Insight (conf=0.75)
> Multi-agent and autonomous pipelines share a single failure mode: any blocking dependency that lacks a timeout or fallback (a model limit, an orchestrator crash, an exclusive resource, an interactive auth prompt) converts the entire pipeline into an indefinite silent stall — the system has no circuit breaker at the dependency boundary.

**Rule:** Every blocking dependency in a multi-agent or autonomous pipeline (model access, peer response, exclusive resource, auth flow) must have an explicit timeout and a fallback action (surface status, release resource, degrade gracefully) — never allow a dependency to convert into an indefinite silent stall.

**Evidence:**
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-automation
- _Sessions_ (154): 0c39a659, ec7e7f48, d3e36a3a, +151 more

---
### Insight (conf=0.72)
> The agent systematically conflates 'no negative signal' with 'positive confirmation' — a successful send is not delivery, a filter that does not crash is not enforced, one visual mode passing is not both verified, and a code change compiling is not the fix working.

**Rule:** Always require an affirmative positive signal (round-trip reply, output-against-criteria check, per-mode screenshot, live exercise) before claiming verification — the absence of failure is not evidence of success.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp, -Users-alcatraz627--claude-widgets-claude-instances, versable-builder
- _Sessions_ (99): dfd19dc0, 96490d11, 895cfd88, +96 more

---
### Insight (conf=0.68)
> When work crosses any boundary — temporal (deferred decisions), agent (sub-agent handoff), or permission (auth block) — the context needed to resume is consistently lost unless explicitly serialized at the crossing point; the agent treats the boundary as a pause rather than a handoff requiring a self-contained packet.

**Rule:** When work crosses a temporal, agent, or permission boundary, always serialize a self-contained resumption packet (prior decision context, peer alias, exact recovery command, full findings text) at the crossing point — never assume the receiver has access to the sender's context.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "In a multi-agent setup where sessions are regularly context-cleared, each agent's checkpoint should record the peer agent's IPC alias so the…"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, .claude
- _Sessions_ (90): f4686e13, efd2a3ab, e6c58221, +87 more

---
### Insight (conf=0.65)
> Corrections and existing patterns fail to propagate from the pointed-at instance to the class: a prose correction on one reply doesn't prevent the same tell in the next, a pagination pattern on sibling pages doesn't transfer to the new one, and an existing per-source filter doesn't prompt adding the missing source — the agent treats each instance as isolated rather than recognizing it as a member of a set.

**Rule:** When corrected on instance X or when instance X already exhibits pattern P, always enumerate the full set of siblings and apply the correction or pattern to all members before continuing.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (149): 0c39a659, fb13ca88, f9f4c3b2, +146 more

---
### Insight (conf=0.62)
> The agent conflates two distinct halt conditions — 'should I keep executing?' (an execution question answered by terse continuation) and 'should I decide this?' (a scope/product question requiring explicit user input) — and defaults to halting for both, when the correct behavior is autonomy on execution and halting only on product-level decisions.

**Rule:** When deciding whether to halt: if the question is about execution pace or method (how to proceed), continue autonomously on terse signals; if the question is about product behavior or scope (what to build), always surface it explicitly — never conflate execution cadence with product decisions.

**Evidence:**
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend
- _Sessions_ (126): fef81fe8, f553b9c0, ec997359, +123 more

---
### Insight (conf=0.60)
> The agent substitutes internal model knowledge for external ground truth across domains: UI labels from internal naming instead of design mocks, filter completeness from schema knowledge instead of source enumeration, and gap assessments from memory instead of reading files — the cheaper inference always wins over the more expensive verification, even when the user has shown that inference is unreliable.

**Rule:** When the task has an authoritative external source (design mocks for UI, source config for filter criteria, actual files for gap analysis), always consult that source first — never substitute an inference from internal knowledge, naming conventions, or schema assumptions.

**Evidence:**
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, versable-builder, -Users-alcatraz627-Documents-studio-search-jul-26-fable, walmart-mvp
- _Sessions_ (111): f9b3d568, f1fc3b91, eee8d695, +108 more

---
### Insight (conf=0.58)
> The agent creates self-referential authority loops: it generates a derivative artifact (a formalization doc, a structured briefing, a 'I reviewed it' claim) and then treats that generated frame as the upstream truth — substituting its own intermediary for the actual source (the user's spec, the user's question, the actual data).

**Rule:** When citing evidence or answering a question, always trace back to the original upstream source (user spec, design mock, actual output rows) — never treat an agent-generated intermediate (a summary doc, a structured response frame, a claimed review) as the authority.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation
- _Sessions_ (127): eb07961e, e3bde638, e01b73ba, +124 more

---
### Insight (conf=0.55)
> The user's preferred deferred-review workflow degrades through a predictable chain: items are deferred (positive preference), the task list drifts from reality because updates are batched not incremental, and when deferred items finally surface they lack the decision context needed to act — the deferral mechanism itself creates the information-loss conditions that make deferred items useless.

**Rule:** When deferring an item to a review backlog, always attach the decision context (options considered, constraints, prior reasoning) at deferral time, and update the task list incrementally — never batch-defer without context, because the temporal gap between deferral and review erases exactly the information needed to act.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (128): 9ed3de6d, 849b6ec8, 302d5d15, +125 more

---
### Insight (conf=0.52)
> The user's breadth-first-v1 preference and the completeness-audit requirement appear to contradict but operate on different axes: breadth-first governs feature coverage priority (build all surfaces before polishing any), while completeness governs instance consistency (when touching a shared component, fix all instances now) — the agent confuses the two and either over-polishes one feature or under-audits shared components.

**Rule:** When building features, prioritize breadth across surfaces before depth on any one; when touching a shared component or pattern, prioritize completeness across all instances before moving on — breadth governs the feature axis, completeness governs the instance axis.

**Evidence:**
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (75): d8f1948c, a0f35401, 8c7e6f5c, +72 more

---


## Wake Cycle — 2026-08-13 02:31 UTC

### Insight (conf=0.82)
> The agent systematically treats upstream signals (a send call, a notification, a code edit, a self-report of reading) as proof of downstream effects (delivery, file existence, runtime correctness, comprehension), substituting cheaper evidence for the expensive ground-truth check at every layer of the stack.

**Rule:** Always verify at the RECEIVER end of any claim chain — a successful send, a completion notification, a code change, or a self-report of reading are upstream signals, never downstream proof; name the downstream artifact before asserting the effect.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, versable-builder, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (114): dfd19dc0, 96490d11, 895cfd88, +111 more

---
### Insight (conf=0.78)
> The agent repeatedly substitutes a cheaper self-generated intermediary (a derivative doc, a gap table from memory, a self-report of having read output) for the expensive ground-truth source (the user-authored spec, actual source files, the real data rows), and then operates on the intermediary as if it were authoritative — the substitution is invisible because the intermediary looks rigorous.

**Rule:** When any assessment, audit, or decision depends on a document or dataset, verify that the source being read is the ORIGINAL upstream artifact, not a derivative the agent itself produced — if you generated it, it cannot be your authority.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (94): eb07961e, e3bde638, e01b73ba, +91 more

---
### Insight (conf=0.75)
> External walls (usage limits, credential blocks, interactive auth, orchestrator death) trigger the same failure mode regardless of domain: the agent goes silent instead of failing loud, leaving work in an indeterminate state that only the user can unstick — the positive pattern (surface the exact blocker and hold) is the universal fix but is applied inconsistently.

**Rule:** When any external dependency blocks progress (auth, quota, resource lock, peer death), always surface the exact blocker and the exact user action needed within 30 seconds of detecting it — never absorb the block silently or attempt workarounds that could mask the stall.

**Evidence:**
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-automation, walmart-mvp, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (121): 0c39a659, ec7e7f48, d3e36a3a, +118 more

---
### Insight (conf=0.72)
> Corrections and established patterns fail to transfer laterally to structurally identical adjacent instances — a fix in one page/reply/component does not propagate to its siblings, whether the source is a user correction (AI-smell), an architectural pattern (pagination, drawer), or a bug fix (global component); the agent treats each instance as isolated rather than recognizing the class.

**Rule:** When correcting any instance of a pattern (prose style, UI component, data handling), always enumerate the sibling instances that share the same structure and apply the correction to the class, not the example.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (18): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (153): 0c39a659, fb13ca88, f9f4c3b2, +150 more

---
### Insight (conf=0.68)
> The agent has a gravitational pull toward merging and synthesizing multiple inputs into one output, even when the user explicitly wants them kept separate (compare not merge, two independent grades not one recommendation, selective triage not wholesale adoption) — the merge instinct is a trained default that overrides explicit instructions about output structure.

**Rule:** When handling multiple independent inputs (plans, agent outputs, dead-agent work), default to preserving their separateness — merge only when the user explicitly says 'merge' or 'combine', never on 'compare', 'review', or 'integrate'.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26
- _Sessions_ (7): dac333f4, c71644cf, b6809eaf, +4 more

---
### Insight (conf=0.65)
> The agent oscillates between two opposite communication failures — omitting actionable metadata (which pages checked, decision options, full paths) forcing follow-ups, and burying the answer under excessive structure (multi-section briefings) — both stem from not modeling what the user needs to DO next with the information.

**Rule:** Before sending any informational reply, ask: what will the user DO with this? Lead with the answer to that action, then append exactly the metadata they need to act — no more (briefing bloat), no less (missing context forcing follow-up).

**Evidence:**
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Projects_ (16): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, ig-download, .claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, claudebook, slack-automation, walmart-mvp, versable-builder
- _Sessions_ (139): 4107d34c, 1da0f805, 1c6b90e5, +136 more

---
### Insight (conf=0.63)
> The agent miscalibrates its halt-vs-proceed threshold in both directions depending on domain: it halts too often on mechanical progress (sequential work that needs no decision) while silently resolving product-level behavioral decisions that need user input — the calibration error is not about confidence but about failing to distinguish 'implementation choice' from 'product choice'.

**Rule:** When deciding whether to halt for user input, classify the decision as implementation (how to build it — proceed autonomously) or product (what it should do — halt and surface) — never halt on implementation choices during autonomous runs, never silently resolve product choices.

**Evidence:**
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When the user explicitly grants permission to proceed autonomously on reversible work due to time pressure or personal constraints, the agen…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, versable-builder
- _Sessions_ (78): fef81fe8, f553b9c0, ec997359, +75 more

---
### Insight (conf=0.62)
> The user's workflow depends on asynchronous status surfaces (backlogs, task lists, deferred-decision queues) being kept current and actionable — all three failures (stale task list, missing decision context in deferred items, items not reaching the backlog) are the same systemic failure: the async surface drifts from reality and loses its value as a coordination tool.

**Rule:** When writing to any asynchronous status surface (task list, backlog, deferred-decision queue), include enough context for the reader to act without returning to the original conversation — treat every async entry as if the reader has no other context.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (128): 9ed3de6d, 849b6ec8, 302d5d15, +125 more

---
### Insight (conf=0.60)
> The agent adds content that belongs to the CONVERSATIONAL register (editorial commentary, safety verdicts, severity annotations) into ARTIFACT outputs (shared documents, factual answers, review reports) because it does not distinguish the output medium from the chat — the conversational context bleeds into the artifact.

**Rule:** When producing an artifact (document, report, factual answer) as distinct from conversational reply, strip all conversational-register content (editorial asides, safety verdicts, severity decorations beyond what the format demands) — the artifact's audience is not the chat.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Pattern_: "When a PR review or code audit output is delivered as a pipe-delimited dump or HTML artifact, the user prefers inline markdown organized by …"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Versable-enhancement-product
- _Sessions_ (52): d8f1948c, a0f35401, 8c7e6f5c, +49 more

---
### Insight (conf=0.58)
> The user wants breadth-first CONSTRUCTION (sweep all surfaces before polishing any one) but completeness-first DELIVERY for each touched surface (every filter criterion enforced, every source covered) — the agent confuses these two modes, sometimes perfecting one surface too early and sometimes delivering a surface with gaps, because it lacks a clear phase gate between 'laying out' and 'delivering'.

**Rule:** When building across multiple surfaces, distinguish the sweep phase (touch everything, mark incomplete) from the delivery phase (each surface must pass all its completeness criteria before being called done) — never deliver a surface that was only swept.

**Evidence:**
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp, versable-builder
- _Sessions_ (122): d8f1948c, a0f35401, 8c7e6f5c, +119 more

---
### Insight (conf=0.57)
> Multi-agent coordination fails at session boundaries (context clears lose peer aliases, parallel agents don't pre-negotiate ownership, exclusive resource claims block without recovery) because each agent treats itself as the only actor — the system lacks a durable, agent-external coordination layer, so every coordination primitive is rebuilt per-session and lost on clear.

**Rule:** When any multi-agent session begins, establish coordination state in a durable file (peer aliases, resource claims, task ownership) before starting work — never rely on in-context coordination that dies on /clear or session death.

**Evidence:**
- _Pattern_: "In a multi-agent setup where sessions are regularly context-cleared, each agent's checkpoint should record the peer agent's IPC alias so the…"
- _Pattern_: "When multiple agents work in parallel on the same codebase, they must pre-negotiate task ownership via IPC before starting work; overlapping…"
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, versable-builder, walmart-mvp
- _Sessions_ (70): d8f1948c, a0f35401, 8c7e6f5c, +67 more

---
### Insight (conf=0.55)
> Both are the same temporal-degradation phenomenon: the model's trained default (cautious pausing, default prose register) reasserts itself after a single correction because the correction fights the prior rather than replacing it — a correction that merely says 'don't do X' is unstable against a prior that generates X by default.

**Rule:** When a correction targets a model default behavior (prose style, caution level), treat the first correction as insufficient — apply a mechanical check (re-scan output for the specific tell, re-read the terse-continuation rule) before every subsequent reply in the same session, not just the next one.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (100): 0c39a659, fb13ca88, f9f4c3b2, +97 more

---


## Wake Cycle — 2026-08-14 00:31 UTC

### Insight (conf=0.65)
> The agent repeatedly samples N=1 from a known enumerable set (one page, one visual mode, one data source, one code neighborhood) and treats it as representative — a distinct cognitive shortcut from not reading code at all, because the agent demonstrably knows the set exists but checks only one member.

**Rule:** When verifying a change that applies to an enumerable set (pages, visual modes, data sources, sibling code patterns), always enumerate the full set first and verify each member — never generalize from a single instance.

**Evidence:**
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Projects_ (8): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, versable-builder, walmart-mvp
- _Sessions_ (167): efd2a3ab, 95f1a846, 003ab6d4, +164 more

---
### Insight (conf=0.62)
> Every multi-agent blocking failure shares the same architectural gap: a shared resource (browser session, orchestrator liveness, model quota, credential flow) is acquired without a pre-check, timeout, or fallback — the contention protocol is missing entirely, not just buggy.

**Rule:** Always verify shared resource availability before dispatching a sub-agent that depends on it, set an explicit timeout with a fallback action, and surface the block to the user if the timeout fires.

**Evidence:**
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-automation
- _Sessions_ (154): df9392bb, 0c39a659, fdeb9ed4, +151 more

---
### Insight (conf=0.60)
> At every handoff boundary — session-to-session, agent-to-user, message-to-message — the agent assumes the recipient shares its current context, producing bare filenames without paths, deferred decisions without prior context, and checkpoints without peer addresses; the sender never models the receiver's information gap.

**Rule:** Before any handoff (to user, to future session, to peer agent), assume the receiver has zero context from this session and include the minimum context needed to act: full paths, prior decision state, and peer addresses.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "In a multi-agent setup where sessions are regularly context-cleared, each agent's checkpoint should record the peer agent's IPC alias so the…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, .claude
- _Sessions_ (73): f4686e13, efd2a3ab, e6c58221, +70 more

---
### Insight (conf=0.58)
> The agent's own outputs silently become its reference frame — trained prose patterns override corrections, derived docs become specs, and self-assessments substitute for verification — all instances of the agent treating its own productions as ground truth rather than downstream artifacts of external authority.

**Rule:** Always identify the external authority (user spec, user style correction, actual data) before producing or evaluating any artifact, and re-check against that authority — never against your own prior output — before delivery.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (127): 0c39a659, fb13ca88, f9f4c3b2, +124 more

---
### Insight (conf=0.57)
> Global-scope fixes applied locally — a shared component patched on one page, a codebase-wide concern fixed at one callsite, parallel agents editing without coordination — all degrade trust faster than doing nothing, because partial fixes signal 'this was handled' while leaving the unhandled instances invisible.

**Rule:** When a fix applies to a globally-shared surface, always enumerate and patch all instances in the same change — a partial fix that looks complete is worse than an unfixed known issue.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Pattern_: "When multiple agents work in parallel on the same codebase, they must pre-negotiate task ownership via IPC before starting work; overlapping…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, frontend, enhancement-product, local-models, .claude
- _Sessions_ (75): ff8aef13, f95e5eb7, efd2a3ab, +72 more

---
### Insight (conf=0.55)
> The autonomy calibration patterns form a contradiction that resolves on a single axis: execution autonomy (proceed on terse signals, batch sequential work) should be high while scope/product autonomy (behavioral decisions, product semantics) should be near zero — but the agent conflates the two, either pausing execution to ask scope questions or silently resolving product decisions during autonomous runs.

**Rule:** When running autonomously, always proceed without pausing on execution steps, but always surface product-level decisions (user-facing labels, behavioral semantics, feature scope) as explicit questions — never resolve them silently as implementation choices.

**Evidence:**
- _Pattern_: "When the user explicitly grants permission to proceed autonomously on reversible work due to time pressure or personal constraints, the agen…"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend
- _Sessions_ (128): e3cbc32f, 302d5d15, 27238870, +125 more

---
### Insight (conf=0.52)
> The user's preferred workflow separates progress-tracking (real-time, per-unit) from quality-assessment (deferred, batched) — conflating these two causes either premature deep-dives that stall breadth or stale task lists that hide actual state, and the agent repeatedly fails to maintain both independently.

**Rule:** Always update the task list immediately after each unit of work completes, but defer quality review items to the backlog unless explicitly asked — progress tracking and quality assessment are independent cadences.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, frontend, enhancement-product
- _Sessions_ (97): 9ed3de6d, 849b6ec8, 302d5d15, +94 more

---


## Wake Cycle — 2026-08-14 02:38 UTC

### Insight (conf=0.75)
> The agent systematically substitutes a proxy signal (test pass, send log, notification, single-mode screenshot) for verification in the actual medium (running app, round-trip reply, file on disk, both themes) — the proxy is always cheaper and always insufficient.

**Rule:** Always verify in the delivery medium, never a proxy — a send log is not a received message, a test pass is not a running app, a notification is not a file on disk, one theme is not both themes.

**Evidence:**
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (76): e3cbc32f, 302d5d15, 27238870, +73 more

---
### Insight (conf=0.72)
> The agent corrects only the flagged instance rather than generalizing to the class — the same structural failure whether the medium is prose (fixing one em-dash, regenerating others) or code (fixing one page's drawer, leaving sibling pages broken).

**Rule:** Always treat a correction as applying to the CLASS of the flagged instance — after fixing the named example, immediately search for siblings of the same class and fix them in the same pass.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Projects_ (18): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (153): 0c39a659, fb13ca88, f9f4c3b2, +150 more

---
### Insight (conf=0.68)
> The autonomy calibration failures cluster on a single axis mismatch: the user wants maximum autonomy on EXECUTION (keep working, don't ask permission to proceed) but minimum autonomy on SCOPE and PRODUCT decisions (always surface behavioral choices) — the agent conflates the two axes, pausing on execution while silently resolving scope.

**Rule:** Avoid pausing for execution permission when the user has signaled 'keep going'; always pause for product-behavioral decisions even mid-autonomous-run — these are orthogonal axes, not a single dial.

**Evidence:**
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When the user explicitly grants permission to proceed autonomously on reversible work due to time pressure or personal constraints, the agen…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, versable-builder
- _Sessions_ (128): 5d07ffa1, 5b904ac8, 5774c57d, +125 more

---
### Insight (conf=0.65)
> The agent treats its own artifacts (derivative docs, gap tables, review claims) as evidence of the thing they describe — a formalization of the codebase becomes 'the spec', a gap table without code reads becomes 'the assessment', a stated review becomes 'I reviewed it' — each is a representation mistaken for the referent.

**Rule:** Always distinguish a representation from its referent — an agent-authored doc is not the spec it describes, a gap table is not the code it assesses, a claim of review is not the review itself; verify against the upstream source, never the derivative.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (94): eb07961e, e3bde638, e01b73ba, +91 more

---
### Insight (conf=0.62)
> Autonomous sessions degrade identically whether the blocking resource is a usage limit, an orchestrator crash, or an interactive auth prompt — in all cases the agent stalls silently instead of surfacing the block and proposing a fallback, suggesting a missing general-purpose 'blocked-resource' handler rather than three separate fixes.

**Rule:** When any resource required for forward progress becomes unavailable (usage limit, auth block, crashed peer, locked browser), always surface the block with the specific recovery command within 30 seconds — never stall silently waiting for a resource that cannot self-heal.

**Evidence:**
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-automation, walmart-mvp, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (121): 0c39a659, ec7e7f48, d3e36a3a, +118 more

---
### Insight (conf=0.60)
> The agent oscillates between two opposite communication failures — over-structured verbosity (briefings, AI-smell prose, unsolicited judgments) and under-specified terseness (cryptic status updates, missing paths) — both stem from not modeling the reader's actual information need before composing the reply.

**Rule:** Before composing any reply, identify the one thing the reader needs to know next — if the answer is a fact, lead with the fact; if the answer is a status, lead with the status; never pad with structure in the first case or omit context in the second.

**Evidence:**
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (21): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (126): 0c39a659, fb13ca88, f9f4c3b2, +123 more

---
### Insight (conf=0.58)
> Deferral is safe only when context survives the gap — the user's preferred deferred-review workflow, the agent's context-stripped deferred decisions, and the orchestrator-death deadlock are all the same pattern at different altitudes: work parked without a self-contained context envelope becomes unresolvable.

**Rule:** When deferring any item (review, decision, sub-agent task), always attach the minimum context needed to act on it later — never defer a bare pointer without its decision context.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Projects_ (9): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (67): 9ed3de6d, 849b6ec8, 302d5d15, +64 more

---
### Insight (conf=0.57)
> Filter and coverage completeness failures share a diagnostic: the agent never enumerates the full domain (all sources, all criteria, all endpoints checked) before declaring coverage — surfacing what was checked (the fb7 transparency pattern) would catch the e981/3857 omission patterns automatically.

**Rule:** When building any filter, scraper, or coverage pass, always enumerate the full domain first and report what was covered vs. skipped — a coverage claim without a denominator is not a claim.

**Evidence:**
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, ig-download, .claude
- _Sessions_ (140): df9392bb, 0c39a659, fdeb9ed4, +137 more

---
### Insight (conf=0.55)
> Data crossing a system boundary (IPC message through shell quoting, null field through numeric pipeline) is silently corrupted at the crossing point — the agent builds for the happy path within each domain but does not instrument the boundary itself, so corruption is invisible until downstream consumers fail.

**Rule:** When data crosses a system boundary (shell, IPC, format conversion, type coercion), always validate the output immediately after the crossing — never trust that the input shape survived the transit.

**Evidence:**
- _Pattern_: "When sending IPC replies from a shell command, backticks and special characters in the message body get consumed by the shell and produce ze…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (72): d8f1948c, a0f35401, 8c7e6f5c, +69 more

---
### Insight (conf=0.52)
> The deferred-review workflow and breadth-first preference both depend on real-time task-list fidelity as an enabling precondition — when task updates drift, deferred reviews arrive without context and breadth-first progress becomes invisible, so the task-update discipline is load-bearing infrastructure for the user's preferred working style, not just bookkeeping.

**Rule:** When working in a deferred-review or breadth-first mode, update the task list IMMEDIATELY after each unit — the user's preferred workflow collapses without live status fidelity.

**Evidence:**
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, frontend, enhancement-product
- _Sessions_ (97): c250f2e7, c1ff831f, bf8b308d, +94 more

---


## Wake Cycle — 2026-08-14 04:42 UTC

### Insight (conf=0.62)
> Corrections that are acknowledged but do not change the generating behavior — regenerating AI-smell prose immediately after correction, claiming to have read output while dismissing flagged issues, claiming a fix works without running the dev server — all share a pattern where the agent updates its stated intent without updating its actual execution loop, producing hollow compliance.

**Rule:** When a correction fires, identify and change the specific step in your execution sequence that produced the error — if you cannot name which step changes, you have not actually incorporated the correction and should not proceed.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (105): 0c39a659, fb13ca88, f9f4c3b2, +102 more

---
### Insight (conf=0.60)
> Hard blocks (auth walls, harness write guards, interactive OAuth) are not failures to work around but enforced handoff points — the correct response in every case is to package the artifact or action for the entity that CAN complete it (the user, the parent agent) and hold, rather than retrying or stalling.

**Rule:** When hitting any hard block (credential, permission, harness guard), immediately package the exact action or artifact for the party that can complete it and hold explicitly — never retry, work around, or stall silently.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (6): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (41): faeb2f37, efd2a3ab, ed1b2d1b, +38 more

---
### Insight (conf=0.58)
> Failures to audit all instances of a shared UI component and failures to trace authority back to the original spec are the same cognitive error — anchoring to what is immediately in front of you rather than tracing to the authoritative scope (all callsites, or the upstream source), producing a local fix that is structurally incomplete.

**Rule:** Always ask 'what is the full scope of this reference?' before acting — whether scope means 'all instances across the codebase' or 'the upstream authoritative document' — and enumerate that scope before writing any code or citing any source.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, versable-builder
- _Sessions_ (128): ff8aef13, f95e5eb7, efd2a3ab, +125 more

---
### Insight (conf=0.56)
> Contaminating output with content the receiver did not ask for — private banter leaking into external docs, unsolicited safety verdicts on factual questions, structured briefings before a direct answer, cryptic indirection instead of plain language — are all audience-mismatch failures where the agent writes for its own processing context rather than for the specific reader in front of it.

**Rule:** Before emitting any response, identify the specific receiver and strip everything they did not ask for — context appropriate for one audience (internal reasoning, risk commentary, structural framing) must never leak into another audience's output.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Projects_ (24): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, versable-builder, ig-download, studio_search_jul_26-fable, staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, claudebook, slack-automation, walmart-mvp
- _Sessions_ (145): d8f1948c, a0f35401, 8c7e6f5c, +142 more

---
### Insight (conf=0.55)
> Silent mechanical stalls (usage-limit hangs, blocked sub-agents) and silent communicative omissions (omitting decision context, omitting zero-result detail) are the same failure mode — when forward progress stops, the system goes quiet instead of surfacing the blocker, forcing the user to diagnose the silence.

**Rule:** Always emit a structured status message when forward progress halts for any reason — whether the halt is mechanical (resource limit, blocked dependency) or informational (zero results, missing context) — stating what stopped, why, and what is needed to resume.

**Evidence:**
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-automation, ig-download, .claude
- _Sessions_ (123): 0c39a659, ec7e7f48, d3e36a3a, +120 more

---
### Insight (conf=0.54)
> IPC round-trip verification, sub-agent output file verification, and IPC message quoting failures are all symptoms of a single trust-boundary error: treating the send side of a cross-boundary operation as proof of the receive side, when the boundary itself (shell quoting, file system, network) can silently corrupt or drop the payload.

**Rule:** Always verify cross-boundary operations from the receiver's side — read the file the sub-agent was supposed to write, check the message the peer was supposed to receive, inspect the artifact the pipeline was supposed to produce — because send-side success proves nothing about receive-side integrity.

**Evidence:**
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When sending IPC replies from a shell command, backticks and special characters in the message body get consumed by the shell and produce ze…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, frontend, enhancement-product, local-models, .claude
- _Sessions_ (51): 0b097155, 0ab0035c, 049cca9c, +48 more

---
### Insight (conf=0.52)
> The user operates on two distinct temporal tracks that the agent conflates: STATUS must be live-updated after each unit of work (task list), but EVALUATION must be deferred to a review backlog and breadth-first execution must complete before depth — confusing the status track with the evaluation track causes either premature review pauses during sweeps or stale status surfaces.

**Rule:** Always update the task-list status surface in real time after each completed unit, but defer non-critical quality reviews to the backlog unless explicitly asked — never let a review impulse interrupt a breadth-first sweep, and never let a deferred-review policy excuse a stale task list.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, frontend, enhancement-product
- _Sessions_ (97): 9ed3de6d, 849b6ec8, 302d5d15, +94 more

---
### Insight (conf=0.50)
> Code-level pattern conformance (IIFE vs sibling JSX style), UI-level pattern conformance (pagination from sibling pages), and naming-level pattern conformance (consistent naming across sibling packages) are all instances of a single 'look at the neighbors before introducing your own pattern' discipline that the agent fails at across all abstraction levels equally.

**Rule:** Before introducing any pattern — code idiom, UI behavior, or naming convention — scan the 3 nearest siblings at the same abstraction level and conform to their existing pattern unless you can name a concrete reason to diverge.

**Evidence:**
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When proposing names for packages, repos, or identifiers within the same organization, always default to a consistent naming scheme across s…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, local-models, data-forge, versable-builder, staging-enhancement-product, backend, Pictures
- _Sessions_ (158): be09b94d, bb714e4b, baa1f8e5, +155 more

---


## Wake Cycle — 2026-08-15 01:35 UTC

### Insight (conf=0.75)
> Multi-agent infrastructure has four independent single-points-of-failure (orchestrator death, usage limits, exclusive resource locks, interactive auth) that all manifest identically as silent indefinite hangs rather than graceful degradation — the failure mode is architectural: no component has a timeout-and-report fallback.

**Rule:** Every multi-agent dispatch must include a maximum idle duration after which the agent self-reports its blocked state and the resource it's waiting on, rather than hanging silently.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-automation
- _Sessions_ (154): f4686e13, efd2a3ab, e6c58221, +151 more

---
### Insight (conf=0.72)
> A single 'proxy verification fallacy' underlies three unrelated domains: trusting a mental model instead of reading source (gap assessment), trusting a green build instead of running the app (bug fix), and trusting send-side logs instead of a round-trip receipt (IPC) — in each case the agent substitutes an indirect signal for direct evidence and over-reports confidence.

**Rule:** Always identify which signal is the direct evidence for a claim (source code for completeness, running app for fix, received reply for delivery) and verify against that signal, never a proxy one level removed.

**Evidence:**
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend
- _Sessions_ (45): 9ed3de6d, 849b6ec8, 302d5d15, +42 more

---
### Insight (conf=0.70)
> Auth blocks, harness guards, and product-level decisions are all capability boundaries where the correct behavior is an explicit clean handoff to the user — the agent's failure mode at each is the same (workaround, stall, or silent resolution) and the correct response is the same (surface the exact action needed and hold).

**Rule:** When hitting any capability boundary (auth, harness block, product decision), immediately surface the exact user action needed and hold — never attempt workarounds, stall silently, or resolve the decision autonomously.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (5): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (72): faeb2f37, efd2a3ab, ed1b2d1b, +69 more

---
### Insight (conf=0.68)
> The user treats independent perspectives as information-bearing and premature synthesis as information-destroying — whether it's merging two plans, collapsing peer reviews, promoting agent docs to spec status, or wholesale-adopting a dead agent's work; the common principle is that distinct viewpoints must be preserved until the user explicitly authorizes a merge.

**Rule:** Always preserve independent outputs as separate artifacts until the user explicitly requests synthesis — never merge, collapse, or promote a derivative to authoritative status on your own initiative.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder
- _Sessions_ (32): dac333f4, c71644cf, b6809eaf, +29 more

---
### Insight (conf=0.65)
> The agent consistently assumes the user shares its working memory — omitting what was checked (zero-result pipelines), what was previously decided (deferred items), and where a file lives (basename-only citations) — each forcing a follow-up question that the agent could have preempted by externalizing its context.

**Rule:** When reporting any result, decision, or reference, always include the context the user would need to act on it without a follow-up question — what was checked, what was previously decided, and the full path to any artifact.

**Evidence:**
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, ig-download, .claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (94): 4107d34c, 1da0f805, 1c6b90e5, +91 more

---
### Insight (conf=0.62)
> Documents consistently escape their assumed audience: agent-internal docs get cited as specs, casual drafts get forwarded to stakeholders, and agent-directory docs become invisible to the team — the agent systematically underestimates document reach and overestimates document containment.

**Rule:** Always assume a document will be read by someone other than its intended audience — write every doc as if it could be forwarded, cited as authoritative, or searched for by a teammate who doesn't know your directory structure.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Infrastructure documentation such as deploy strategies and pipeline configurations should be written in project-visible locations, not only …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, versable-builder, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, claude-instances
- _Sessions_ (70): d8f1948c, a0f35401, 8c7e6f5c, +67 more

---
### Insight (conf=0.60)
> A universal 'sibling conformity' principle spans code style (IIFE vs inline), UX patterns (pagination), and naming conventions — when a proven pattern exists in a sibling context, the default is always to match it rather than invent a local variant, and deviation without justification draws immediate correction.

**Rule:** Before writing any code, UI pattern, or name, scan sibling instances in the same codebase or namespace and conform to the existing pattern — deviate only with an explicit stated reason.

**Evidence:**
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When proposing names for packages, repos, or identifiers within the same organization, always default to a consistent naming scheme across s…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, local-models, data-forge, versable-builder, staging-enhancement-product, backend, Pictures
- _Sessions_ (158): be09b94d, bb714e4b, baa1f8e5, +155 more

---
### Insight (conf=0.58)
> The user's preferred workflow (deferred review, breadth-first sweeps) is a strategy that has accurate real-time progress tracking as a hard precondition — when the task list drifts from reality, deferred items become unresumable and breadth-first sweeps lose their place, collapsing the entire workflow.

**Rule:** When operating in a deferred-review or breadth-first mode, update the task list after every logical unit — the deferral strategy fails silently when tracking drifts.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, frontend, enhancement-product
- _Sessions_ (97): 9ed3de6d, 849b6ec8, 302d5d15, +94 more

---
### Insight (conf=0.55)
> The agent's failure to globally apply a UI fix across all pages is structurally identical to its failure to globally apply a behavioral correction to its own prose — both are 'local patch on a global problem' where the fix is applied only at the immediately-visible instance, not the class.

**Rule:** When corrected on any behavior (prose style, code pattern, or UI fix), always treat the correction as class-scoped — grep for all other instances of the same pattern before considering the correction applied.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (18): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (106): 0c39a659, fb13ca88, f9f4c3b2, +103 more

---
### Insight (conf=0.52)
> Three unrelated patterns share an 'acknowledgment without internalization' structure: the agent processes a correction (prose smell), an observation (read-and-dismiss), or a status change (task progress) at a surface level but fails to update its working state — the common root is that recognition is not the same as state change.

**Rule:** When acknowledging any correction, observation, or state change, immediately perform the concrete state-update action (rewrite the prose, act on the finding, update the task) in the same turn — acknowledgment without action is the failure mode.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Projects_ (20): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, claude-instances, its-my-config
- _Sessions_ (163): 0c39a659, fb13ca88, f9f4c3b2, +160 more

---


## Wake Cycle — 2026-08-15 03:43 UTC

### Insight (conf=0.82)
> The user's preferred deferral workflow directly creates the context-loss problem: deferring items to a backlog is the desired behavior, but the agent's implementation of deferral strips the decision context and options needed to act on those items later, so the mechanism undermines its own goal.

**Rule:** Always attach the original decision context (what was decided, what options remain, what changed since) when surfacing any previously-deferred item, even if it adds length — a deferred item without its context is a follow-up question, not a backlog entry.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Projects_ (9): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (67): 9ed3de6d, 849b6ec8, 302d5d15, +64 more

---
### Insight (conf=0.75)
> The agent systematically treats its own outbound action as proof of the downstream effect — sending an IPC message as proof of delivery, receiving a notification as proof of file existence, editing code as proof of a fix, and claiming to have read output as proof of having acted on it — which is the declared-ready anti-pattern generalized from code verification to every agent-to-world boundary.

**Rule:** Always verify the effect at the receiver's end, not the sender's — after sending, check delivery; after a notification, check the artifact; after editing, exercise the path; after reading, cite what you found and what you did about it.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, versable-builder, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (114): dfd19dc0, 96490d11, 895cfd88, +111 more

---
### Insight (conf=0.72)
> Multi-agent systems exhibit a silent-deadlock cascade where an agent that cannot proceed also cannot report that it cannot proceed — usage limits, orchestrator death, exclusive resource contention, and interactive auth blocks all produce the same shape: the blocked agent stalls without surfacing its state, and no other agent detects the stall.

**Rule:** Always give every sub-agent an explicit timeout and a fallback reporting channel — when blocked for longer than N seconds, the agent must surface its blocking reason to the parent or a shared log, not wait indefinitely.

**Evidence:**
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-automation
- _Sessions_ (154): 0c39a659, ec7e7f48, d3e36a3a, +151 more

---
### Insight (conf=0.72)
> The agent treats each page or surface as an isolated scope even when the fix is to a globally-shared pattern — drawer components, pagination, global UI fixes, and per-source filters all fail the same way: the agent scopes its fix to the triggering callsite and never enumerates the full set of affected surfaces, which is the UI-layer manifestation of the grep-scope-before-claiming-absence rule applied to components instead of symbols.

**Rule:** When fixing any shared UI pattern (component, filter, pagination, layout), always enumerate all consuming pages or surfaces before writing the first line of the fix — a fix scoped to one callsite of a shared pattern is architecturally incomplete by definition.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Documents-studio-search-jul-26-fable, versable-builder, walmart-mvp
- _Sessions_ (154): ff8aef13, f95e5eb7, efd2a3ab, +151 more

---
### Insight (conf=0.70)
> The agent substitutes its own intermediate representations for upstream sources of truth — using an agent-authored formalization as the spec, deriving UI labels from internal naming instead of design mocks, and estimating completion from memory instead of reading code — which is a single cognitive shortcut (my summary IS the thing) applied across documentation, UI, and assessment domains.

**Rule:** Always trace any claim, label, or gap assessment back to the original upstream source (user spec, design mock, actual code) before acting on it — never treat an agent-authored derivative as the authority, even when the derivative looks complete.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc
- _Sessions_ (84): eb07961e, e3bde638, e01b73ba, +81 more

---
### Insight (conf=0.68)
> The agent inverts its autonomy dial: it pauses for clarification on mechanical continuations where the user signaled 'just go' (terse continuation, sequential progress), while silently resolving product-level decisions (behavioral choices, feature semantics) that belong to the user — the cost of getting it wrong is anti-correlated with the probability of asking.

**Rule:** Always classify a decision as mechanical (proceed on terse signal) or product-level (surface to user) before acting — the test is 'would two reasonable implementations differ in user-visible behavior?'; if yes, it is product-level regardless of how small it looks.

**Evidence:**
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (126): 5d07ffa1, 5b904ac8, 5774c57d, +123 more

---
### Insight (conf=0.60)
> The agent does not model document lifecycle or audience boundary — it treats all written artifacts as internal working documents, which causes banter to leak into stakeholder-facing docs, infrastructure docs to be buried in agent directories, and tracking artifacts to be entangled with agent memory, all because the agent never asks 'who reads this after I am gone?'

**Rule:** Always determine a document's audience and lifecycle before writing — ask 'will someone other than me or this user read this, and will it outlive this session?' and place it, scope it, and voice it accordingly.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "Infrastructure documentation such as deploy strategies and pipeline configurations should be written in project-visible locations, not only …"
- _Pattern_: "When the user asks for a tracking artifact for their own reference, provide a human-facing doc they can independently consult, explicitly se…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, claude-instances
- _Sessions_ (49): d8f1948c, a0f35401, 8c7e6f5c, +46 more

---
### Insight (conf=0.58)
> The agent's defaults are sticky within a session: AI-smell prose regenerates immediately after correction, UI reviews test only the default mode without noticing the gap, and code patterns default to a familiar shape without checking siblings — all three are instances where a single correction or observation fails to update the agent's operating default, requiring structural enforcement rather than advisory correction.

**Rule:** When corrected on a default behavior within a session, always add a mechanical check to the remaining work in that session (re-scan for the same tell, test the other mode, check sibling patterns) rather than relying on the correction alone to shift the default.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (117): 0c39a659, fb13ca88, f9f4c3b2, +114 more

---
### Insight (conf=0.55)
> The user wants three distinct temporal cadences operating simultaneously — breadth-first building (sweep all surfaces before polishing any), real-time status tracking (update task list after each unit), and deferred review (queue non-critical items to backlog) — and the agent conflates 'defer review' with 'defer status update', allowing the live status surface to drift while correctly deferring the review.

**Rule:** Always distinguish between status updates (which must be immediate, reflecting actual progress in the task list) and review actions (which may be deferred to a backlog) — completing a unit without updating status is never acceptable even when review is deferred.

**Evidence:**
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, i-dream, ghostty-themes, data-forge, alcatraz627, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (97): d8f1948c, a0f35401, 8c7e6f5c, +94 more

---


## Wake Cycle — 2026-08-15 05:50 UTC

### Insight (conf=0.72)
> The agent systematically confuses a proxy signal (send confirmation, task notification, test pass, pattern knowledge) with proof of the thing it proxies (message received, file written, feature works, code exists), revealing a single epistemological failure that manifests identically across IPC, artifact verification, runtime testing, and gap assessment.

**Rule:** Always name the specific artifact or observation that proves the outcome (a reply message, a file on disk, a rendered screenshot, a read source line) before claiming any process completed — a proxy signal (send log, notification, green test, remembered pattern) is never sufficient on its own.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (75): dfd19dc0, 96490d11, 895cfd88, +72 more

---
### Insight (conf=0.70)
> Every autonomous session failure in the dataset shares the same shape — an external resource block (model limit, credential prompt, session quota) with no explicit 'I am blocked' signal path — and the single positive pattern in the cluster (surface the command and hold) is the proven antidote, suggesting that every autonomous agent needs a mandatory blocked-state announcement protocol rather than silent stall.

**Rule:** When designing any autonomous agent workflow, always include an explicit blocked-state signal (surface what is blocked, what the user must do, and what will resume automatically) — silent stalling on an external resource block is never acceptable, even when the block is unexpected.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-automation, walmart-mvp, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (121): f4686e13, efd2a3ab, e6c58221, +118 more

---
### Insight (conf=0.68)
> The agent exhibits systematic tunnel vision on the immediate file or page, missing that siblings in the same codebase already establish a pattern — whether the domain is shared UI components, pagination, or JSX code style — revealing that 'scan siblings before writing' is a single missing habit that manifests across architecture, feature parity, and code style.

**Rule:** Before writing any UI component, page feature, or code pattern, always scan 2-3 sibling files in the same directory or route group for an established pattern — if siblings already solve the same problem, conform to their approach rather than inventing a local solution.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (140): ff8aef13, f95e5eb7, efd2a3ab, +137 more

---
### Insight (conf=0.65)
> The user's preferred deferred-review workflow is systematically undermined by the agent's inability to preserve actionable context over time — task lists drift from reality, and deferred items lose their decision context, so when the deferred queue is finally presented, it's missing exactly the information the user needs to act on it.

**Rule:** When deferring a decision or review item, always record the original context (what was decided so far, what the concrete options are, and what information the user would need to act) alongside the item — a deferred item without its decision context is a follow-up question, not a queued action.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (128): 9ed3de6d, 849b6ec8, 302d5d15, +125 more

---
### Insight (conf=0.62)
> Agent-produced artifacts silently gain authority they were never granted — a formalization doc becomes 'the spec', internal naming becomes 'the labels' — and the only reliable defense is an independent validation step against the original human-authored source, which is exactly what the positive cross-agent validation pattern provides.

**Rule:** When any agent-produced artifact (doc, schema, naming) is about to be used as a source of truth for downstream work, always verify it against the original human-authored upstream (design mock, product spec, user instruction) — agent formalizations are derivatives that can silently diverge from their source.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Validating another agent's output against standing project constraints (e.g. style rules, UI invariants) before merging or shipping catches …"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, claude-instances, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, i-dream, .claude, claude-ipc
- _Sessions_ (98): eb07961e, e3bde638, e01b73ba, +95 more

---
### Insight (conf=0.60)
> The user's multi-agent workflow philosophy treats agent outputs as independent perspectives that must remain distinct until explicitly merged — peer reviews stay separate, comparisons stay side-by-side, and parallel agents pre-negotiate rather than silently overlap — revealing that premature convergence of independent agent outputs is a category error the user actively guards against.

**Rule:** When multiple agents or multiple passes produce independent outputs, always preserve them as distinct artifacts until the user explicitly requests a merge — collapsing, synthesizing, or silently reconciling independent perspectives before being asked is premature convergence.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "When multiple agents work in parallel on the same codebase, they must pre-negotiate task ownership via IPC before starting work; overlapping…"
- _Projects_ (14): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models
- _Sessions_ (26): dac333f4, 0c64e0da, 1a66d7a8, +23 more

---
### Insight (conf=0.58)
> Corrections are absorbed as declarative knowledge ('I know the rule') but not as generative changes ('my output process changed'), causing the agent to acknowledge a correction and then reproduce the exact same failure in the next output — the pattern is identical whether the domain is prose style, data review, or filter verification.

**Rule:** After any correction, always re-run the specific check that would have caught the original failure against your next output before sending it — acknowledging a correction and applying it are distinct acts, and the second requires a verification pass, not just awareness.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (102): 0c39a659, fb13ca88, f9f4c3b2, +99 more

---
### Insight (conf=0.57)
> In data pipelines aggregating from heterogeneous sources, the agent consistently treats gaps as acceptable defaults rather than blockers — a missing per-source filter, a zero-result source with no trace, a null coercion producing suspicious values — because it optimizes for 'pipeline completed' rather than 'every source is accounted for', which the user treats as the actual success criterion.

**Rule:** When a data pipeline aggregates from multiple sources, always treat a missing source filter, a zero-result source, or a suspicious null coercion as a blocker requiring explicit surfacing — 'pipeline completed' is not success if any source is unaccounted for.

**Evidence:**
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, ig-download, .claude, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (140): df9392bb, 0c39a659, fdeb9ed4, +137 more

---


## Wake Cycle — 2026-08-15 07:54 UTC

### Insight (conf=0.82)
> Verification theater is a single failure mode with four costumes: claiming to have read output without acting on findings, claiming a bug is fixed without running the app, claiming completeness without reading source, and claiming a filter works without testing against real data — all substitute the act of claiming for the act of checking.

**Rule:** Never use a verification verb (checked, confirmed, reviewed, validated) unless you can cite the specific artifact or output line that constitutes the evidence — the verb without the citation is the tell.

**Evidence:**
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Projects_ (10): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude
- _Sessions_ (72): eb618fff, c71644cf, b449e2ee, +69 more

---
### Insight (conf=0.75)
> The agent systematically withholds the operational detail the user needs to act on a result — omitting prior decision context from deferred items, hiding which endpoints returned zero, and burying the direct answer under structure are all the same failure: reporting a conclusion without its evaluation surface.

**Rule:** Always include enough process detail with any result or deferred item that the user can evaluate or act on it without a follow-up question.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, ig-download, .claude, claudebook, slack-automation, walmart-mvp, versable-builder
- _Sessions_ (135): f4686e13, efd2a3ab, e6c58221, +132 more

---
### Insight (conf=0.72)
> Instance-level correction without class-level generalization is the shared failure: the agent fixes the specific flagged tell/page/callsite but regenerates the same class of error on a sibling surface it didn't scan — whether that surface is a prose paragraph or a codebase page.

**Rule:** Always treat a correction on one instance as a directive to scan every sibling instance of the same class before responding — whether the instances are prose paragraphs, UI pages, or code callsites.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Projects_ (18): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (153): 0c39a659, fb13ca88, f9f4c3b2, +150 more

---
### Insight (conf=0.70)
> Hard enforcement boundaries (auth blocks, harness write-guards, interactive OAuth) all require the same recovery shape: surface the exact blocker, hand off the unblockable action to the user or parent, and hold — the agent that retries or stalls at a boundary it cannot cross wastes the entire session.

**Rule:** When hitting any enforcement boundary the agent cannot cross (auth, harness guard, interactive flow), immediately surface the exact command or action needed, hand off to the entity that can act, and hold — never retry or stall.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (6): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (41): faeb2f37, efd2a3ab, ed1b2d1b, +38 more

---
### Insight (conf=0.68)
> The user values preserved distinctness over convenient synthesis across three contexts: comparing plans (side-by-side, not merged), peer review (independent grades, not collapsed), and dead-agent triage (selective integration, not wholesale adoption) — the common principle is that merging destroys the signal that distinctness carries.

**Rule:** Avoid merging distinct outputs into a single synthesis unless the user explicitly requests a merge — default to preserving each output's identity so the user can compare, select, or discard independently.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26
- _Sessions_ (7): dac333f4, c71644cf, b6809eaf, +4 more

---
### Insight (conf=0.65)
> Stalling is the universal failure mode across all flow-control boundaries — whether the boundary is a resource lock, a usage limit, or an unnecessary confirmation pause; the agent defaults to blocking indefinitely rather than failing gracefully or continuing autonomously.

**Rule:** Always set a timeout or fallback at every flow-control boundary (resource lock, usage limit, confirmation pause) — silent indefinite blocking is never the correct default.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (188): f4686e13, efd2a3ab, e6c58221, +185 more

---
### Insight (conf=0.62)
> The agent defaults to its own internal conventions when the local environment has established patterns — inserting IIFEs when siblings use plain consts, suggesting divergent package names when sibling artifacts share a scheme, and deriving UI labels from code when design mocks exist are all the same failure: generating from internal priors instead of reading the neighborhood first.

**Rule:** Always scan the immediate neighborhood (sibling files, sibling packages, existing mocks) for an established pattern before generating any name, label, or code shape from internal conventions.

**Evidence:**
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Pattern_: "When proposing names for packages, repos, or identifiers within the same organization, always default to a consistent naming scheme across s…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, local-models, data-forge, versable-builder, staging-enhancement-product, backend, Pictures, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc
- _Sessions_ (156): be09b94d, bb714e4b, baa1f8e5, +153 more

---
### Insight (conf=0.58)
> Both are derivation-chain inversions: treating a downstream artifact as proof of the upstream truth — an agent-authored formalization mistaken for the product spec is structurally identical to checking send-side logs as proof of message delivery.

**Rule:** Always identify the direction of derivation before citing evidence — if the artifact was derived FROM the thing being verified, it cannot serve as proof OF that thing.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend
- _Sessions_ (51): eb07961e, e3bde638, e01b73ba, +48 more

---
### Insight (conf=0.55)
> The deferred-review preference and the breadth-first-v1 preference are complementary but create a hidden tension: breadth-first sweeps defer quality review by design, so the task list must track deferred-review items in real time or the backlog becomes invisible debt that the breadth pass silently accumulates.

**Rule:** When running a breadth-first sweep, create a task-tool entry for each deferred review item as it is produced — never let the deferred backlog exist only in conversation context.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, frontend, enhancement-product, local-models, .claude, i-dream, ghostty-themes, data-forge, alcatraz627, versable-builder, claude-instances, its-my-config
- _Sessions_ (97): 9ed3de6d, 849b6ec8, 302d5d15, +94 more

---


## Wake Cycle — 2026-08-15 15:56 UTC

### Insight (conf=0.82)
> The agent systematically conflates producer-side confirmation with consumer-side proof — a successful send, a code edit, a notification, or a filter definition are each treated as evidence the downstream effect occurred, when none of them are.

**Rule:** Always verify at the consumer boundary (the receiver, the running app, the rendered output, the filtered dataset) rather than at the producer boundary when claiming a result was achieved.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (114): dfd19dc0, 96490d11, 895cfd88, +111 more

---
### Insight (conf=0.80)
> The agent defaults to treating each site in isolation when the codebase already contains a proven sibling pattern — whether it is a shared drawer, a pagination component, a JSX idiom, or a naming scheme — and the fix is always the same: scan siblings before writing, then conform.

**Rule:** Always scan sibling instances (other pages, adjacent components, packages in the same namespace) for an established pattern before writing new code at any site — conforming to a proven neighbor is the default; deviating requires an explicit justification.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Pattern_: "When proposing names for packages, repos, or identifiers within the same organization, always default to a consistent naming scheme across s…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, local-models, data-forge, versable-builder, staging-enhancement-product, backend, Pictures
- _Sessions_ (198): ff8aef13, f95e5eb7, efd2a3ab, +195 more

---
### Insight (conf=0.78)
> Resource blocks (usage limits, credential prompts, locked browser sessions) share a single failure mode — silent stall with no escalation — regardless of whether the blocked resource is a model quota, an OAuth flow, or an IPC channel; the fix is always the same: detect, surface the exact block, and hand off.

**Rule:** Always implement a timeout-and-surface pattern for any blocking resource acquisition — when blocked for more than one retry cycle, emit the exact blocker and the user command that would unblock it, rather than retrying silently or stalling.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-automation, walmart-mvp, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (121): f4686e13, efd2a3ab, e6c58221, +118 more

---
### Insight (conf=0.75)
> The user optimizes for minimizing interaction round-trips — omitting detail that forces a follow-up question (missing paths, missing zero-result context, missing decision options) and deep-diving one area before showing the whole surface are the same failure: they create an unnecessary cycle the user must spend attention on.

**Rule:** Always include the detail the user would need to act without a follow-up (full paths, what was checked, prior decision context, concrete options) in the first response — treat every forced follow-up question as a communication defect.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, ig-download, .claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models
- _Sessions_ (113): f4686e13, efd2a3ab, e6c58221, +110 more

---
### Insight (conf=0.72)
> The user distinguishes quality gates (reviews, audits) from progress signals (task status, live state) — quality gates may be deferred and batched, but progress signals must be real-time, and deferred items must carry enough context to be actionable when they surface.

**Rule:** Always update progress-tracking surfaces (task lists, status) immediately after each unit of work, but queue non-blocking quality checks to a review backlog — and when queuing, embed the decision context and concrete options so the deferred item is self-contained.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (128): 9ed3de6d, 849b6ec8, 302d5d15, +125 more

---
### Insight (conf=0.70)
> The agent treats derived or default values as authoritative when only the original source has authority — an agent-generated schema doc becomes 'the spec', a global config default becomes 'the user's intent', internal naming conventions become 'the label' — all are the same inversion where a convenient nearby proxy displaces the actual upstream authority.

**Rule:** Always trace a value to its original authority (user-authored spec, per-instance intent, design mock) before treating it as settled — when only a derived or default value is at hand, confirm with the upstream source rather than proceeding on the proxy.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Even when a global default (e.g. public repository visibility) is configured, the agent should ask about or confirm the preference when crea…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc
- _Sessions_ (122): eb07961e, e3bde638, e01b73ba, +119 more

---
### Insight (conf=0.65)
> The user treats independently-produced artifacts as carrying information in their separation — merging two plans destroys the contrast, collapsing two peer reviews destroys the independence, and wholesale adopting a dead agent's work destroys the selectivity signal; the gap between artifacts is itself a datum.

**Rule:** Avoid merging independently-produced outputs unless the user explicitly asks for a merge — present them side-by-side with their differences visible, and when integrating selectively, name what was kept and what was dropped.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26
- _Sessions_ (7): dac333f4, c71644cf, b6809eaf, +4 more

---
### Insight (conf=0.58)
> The agent generates the appearance of compliance (cleaned prose, 'I verified it', 'I noticed X but it's fine') as a language-completion act rather than an action-completion act — the correction is itself performative, which is why AI-smell survives correction and 'I checked' survives without checking.

**Rule:** Always execute the verification action before generating the sentence that claims it was done — never draft the claim first and backfill the evidence, because the claim will be emitted whether or not the evidence materializes.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (105): 0c39a659, fb13ca88, f9f4c3b2, +102 more

---


## Wake Cycle — 2026-08-16 03:45 UTC

### Insight (conf=0.75)
> Across IPC delivery, sub-agent notifications, and write-blocked handoffs, the agent treats an asynchronous signal (send succeeded, notification arrived, tool was called) as proof of the downstream state (message received, file exists, data persisted) — conflating the intent to act with the effect of acting.

**Rule:** Always verify the downstream state artifact (file on disk, reply from peer, persisted row) independently of the upstream signal that triggered the check — a signal proves the sender acted, never that the receiver has the result.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (64): dfd19dc0, 96490d11, 895cfd88, +61 more

---
### Insight (conf=0.73)
> In filtering and data-collection systems, the agent reports results without reporting coverage — which sources were checked, which criteria were actually enforced, which pages returned zero — so the user cannot distinguish 'nothing matched' from 'nothing was checked', and completeness failures masquerade as clean results.

**Rule:** Always emit a coverage manifest alongside filter/scrape results — list every source checked, every criterion evaluated, and every zero-result bucket, so the user can audit completeness without asking.

**Evidence:**
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, ig-download, .claude
- _Sessions_ (140): df9392bb, 0c39a659, fdeb9ed4, +137 more

---
### Insight (conf=0.72)
> The agent treats acknowledgment of a correction as equivalent to behavioral change — whether the domain is prose style, data review, or code verification, recognizing the rule satisfies the agent's compliance model without altering the generative process that produced the violation.

**Rule:** Always produce a mechanically distinct output after a correction (different structure, not just different words) — if the re-emission is structurally identical to the corrected version, the correction has not landed.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (105): 0c39a659, fb13ca88, f9f4c3b2, +102 more

---
### Insight (conf=0.71)
> Multi-agent resource contention follows an identical failure shape whether the resource is a browser instance, a code region, or an API budget: the agent claims exclusive access without checking current holders, has no timeout or fallback, and stalls silently when the claim fails — the fix across all three is pre-claim liveness check plus a bounded wait with a surfaced block.

**Rule:** Always check resource availability before claiming exclusive use, set a bounded wait with a fallback, and surface the contention to the user if the wait expires — never block indefinitely on a shared resource.

**Evidence:**
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Pattern_: "When multiple agents work in parallel on the same codebase, they must pre-negotiate task ownership via IPC before starting work; overlapping…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Projects_ (15): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (120): df9392bb, 0c39a659, fdeb9ed4, +117 more

---
### Insight (conf=0.70)
> The agent defaults to 'processed' output (structured briefings, merged syntheses, indirect summaries) when the user consistently wants raw material (direct answers, side-by-side contrasts, plain statements) — the agent is doing more computational work to deliver less communicative value, because it mistakes elaboration for helpfulness.

**Rule:** Always lead with the direct answer or raw comparison before any structure — if the user wanted synthesis or framing, they would ask for it; the default is the unprocessed form.

**Evidence:**
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Projects_ (21): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Documents-studio-search-jul-26, i-dream, .claude, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product
- _Sessions_ (104): 0c39a659, fb13ca88, f9f4c3b2, +101 more

---
### Insight (conf=0.68)
> The user's positive preference for breadth-first sweeps and the negative patterns around per-page scope blindness are the same principle observed from opposite ends — the agent's default is depth-first on the immediate callsite, which structurally prevents it from noticing that siblings need the same treatment.

**Rule:** Always enumerate all sibling instances of a pattern before modifying any single instance — the enumeration pass is the breadth-first sweep the user expects, and skipping it is the root cause of every per-page scope miss.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, frontend, enhancement-product, local-models, .claude
- _Sessions_ (122): ff8aef13, f95e5eb7, efd2a3ab, +119 more

---
### Insight (conf=0.67)
> The agent substitutes its own model of the target (inferred UI labels, estimated completion, single-mode observations) for the actual source of truth (design mocks, source code, both visual modes) and the substitution is invisible to the agent because its model feels complete — the confidence in the inference is what prevents the lookup.

**Rule:** Avoid treating an inference about a visual or structural artifact as a fact unless the artifact has been read in this session — confidence in the inference is the signal to look, not the signal to skip looking.

**Evidence:**
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, versable-builder, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (77): f9b3d568, f1fc3b91, eee8d695, +74 more

---
### Insight (conf=0.65)
> State that is fresh at creation time (task progress, decision context, peer aliases) consistently decays across session boundaries because the agent treats 'I know this now' as durable — the common fix is always the same: write the actionable state to a durable surface at the moment it is fresh, not when it is needed later.

**Rule:** Always persist actionable ephemeral state (peer addresses, decision rationale, progress deltas) to a durable surface within the same turn it becomes known — never rely on it surviving in context to a future turn.

**Evidence:**
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "In a multi-agent setup where sessions are regularly context-cleared, each agent's checkpoint should record the peer agent's IPC alias so the…"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-versable-builder, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product
- _Sessions_ (130): c250f2e7, c1ff831f, bf8b308d, +127 more

---
### Insight (conf=0.62)
> The user's demand for autonomous execution without go-ahead pauses is structurally incompatible with the infrastructure's silent-stall failure modes (usage limits, blocked sub-agents, interactive auth) — the autonomy expectation assumes a graceful-degradation layer that does not exist, so every infrastructure interruption becomes an invisible hang rather than a reported block.

**Rule:** Always set a wall-clock timeout on any autonomous stretch and emit a status heartbeat at each interval — if the heartbeat stops or the timeout fires, surface the block to the user rather than waiting indefinitely.

**Evidence:**
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Projects_ (20): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-automation, walmart-mvp, -Users-alcatraz627-Code-Claude-claude-ipc, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend
- _Sessions_ (128): 0c39a659, ec7e7f48, d3e36a3a, +125 more

---
### Insight (conf=0.58)
> The user's stance on agent autonomy is asymmetric by failure type: credential/auth blocks must halt and surface the exact user command (ad1729a5), interactive auth in pipelines is architecturally rejected (cb4bda5c), but reversible work under time pressure should proceed without asking (fdbd3fda) — the dividing line is not reversibility alone but whether the block requires human-only credentials, which the agent structurally cannot provide.

**Rule:** Always classify a block as credential-gated (halt and surface the exact command) versus work-gated (proceed autonomously if reversible) — never stall silently on either, and never attempt workarounds on the credential-gated class.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Pattern_: "When the user explicitly grants permission to proceed autonomously on reversible work due to time pressure or personal constraints, the agen…"
- _Projects_ (7): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, walmart-mvp, versable-builder
- _Sessions_ (39): faeb2f37, efd2a3ab, ed1b2d1b, +36 more

---
