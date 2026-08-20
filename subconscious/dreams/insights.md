# Dream Insights

_High-confidence associations promoted by the Wake phase._

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


## Wake Cycle — 2026-08-16 21:01 UTC

### Insight (conf=0.72)
> The autonomy-vs-confirmation patterns contradict each other on the surface but split cleanly on one axis the agent conflates: EXECUTION autonomy (how to do the work, whether to pause on terse continuations) should be maximized, while PRODUCT DECISION authority (what gets built, which behavior to choose) must always be surfaced — the recurring mistake is treating a product decision as an execution choice and proceeding silently, or treating an execution step as a product decision and halting unnecessarily.

**Rule:** Always distinguish execution decisions (how/when to proceed — bias toward autonomy) from product decisions (what gets built or which behavior wins — always surface to user), and never let one masquerade as the other.

**Evidence:**
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Pattern_: "Even when a global default (e.g. public repository visibility) is configured, the agent should ask about or confirm the preference when crea…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Versable-automation
- _Sessions_ (176): 5d07ffa1, 5b904ac8, 5774c57d, +173 more

---
### Insight (conf=0.70)
> The agent has a strong convergence instinct — when presented with two independent outputs it merges them, when integrating dead-agent work it adopts wholesale, when comparing plans it synthesizes — but the user consistently wants independent views preserved until they explicitly ask for convergence; premature synthesis destroys the signal diversity that the parallel structure was designed to produce.

**Rule:** When handling multiple independent outputs (plans, reviews, agent work), always present them side-by-side with contrast preserved; never merge or synthesize unless the user explicitly requests convergence as a separate step.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26
- _Sessions_ (7): dac333f4, c71644cf, b6809eaf, +4 more

---
### Insight (conf=0.68)
> Derivative-treated-as-authoritative is not limited to formal documents: the agent's own mental model of the codebase (gap assessments without reading source), agent-authored formalizations (concepts docs cited as spec), and internal naming conventions (used as UI labels instead of design mocks) are all downstream derivatives that get silently promoted to upstream authority — the common cause is that the derivative is more accessible than the source, so convenience wins over correctness.

**Rule:** Before treating any representation as authoritative — a gap table, a formalization doc, a naming convention — identify its upstream source and verify against it; accessibility of a derivative is not evidence of its authority.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc
- _Sessions_ (84): eb07961e, e3bde638, e01b73ba, +81 more

---
### Insight (conf=0.65)
> Zero, null, and empty results are treated as 'nothing to report' across scraping (zero results with no detail on what was checked), filtering (out-of-scope items passing = filter never exercised), and data pipelines (null coercion dismissed as acceptable) — the common failure is that an absence of signal is read as an absence of problem, when it should trigger a 'prove the mechanism worked' check.

**Rule:** Always treat a zero/null/empty result as a 'mechanism unproven' signal requiring active verification — surface what was checked and what was expected, rather than reporting the absence as a clean outcome.

**Evidence:**
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, ig-download, .claude, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (92): 4107d34c, 1da0f805, 1c6b90e5, +89 more

---
### Insight (conf=0.62)
> The 'send does not prove receipt' failure is a single structural bug wearing four costumes: IPC protocol (send-side log ≠ delivery), shell quoting (sent bytes ≠ received bytes), user communication (cryptic reply ≠ understood message), and decision presentation (deferred item without context ≠ actionable item) — in every case the agent trusts its own outbound view and never checks the receiver's experience.

**Rule:** Always verify from the receiver's perspective — for IPC wait for a round-trip ack, for user-facing output re-read the message as someone without session context, for decision items include the prior context and concrete options — a successful emission is never proof of successful reception.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "When sending IPC replies from a shell command, backticks and special characters in the message body get consumed by the shell and produce ze…"
- _Projects_ (24): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, versable-builder, ig-download, studio_search_jul_26-fable, enhancement-product
- _Sessions_ (144): dfd19dc0, 96490d11, 895cfd88, +141 more

---
### Insight (conf=0.58)
> Resource availability assumptions that hold for single-agent sessions systematically fail under multi-agent or autonomous-session conditions: browser MCP exclusivity, orchestrator token limits, and interactive auth flows all work fine manually but become blocking failures when agents run concurrently or unattended — this is temporal degradation where the architecture was designed for the simple case and never stress-tested against the operational case.

**Rule:** When designing any agent workflow that uses a shared or interactive resource, always plan for the concurrent/unattended case — pre-check resource availability, implement timeout-and-surface fallbacks, and never assume a resource will be free or interactive just because it was last time.

**Evidence:**
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (10): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-automation
- _Sessions_ (118): df9392bb, 0c39a659, fdeb9ed4, +115 more

---
### Insight (conf=0.55)
> Corrections and state-updates applied once do not persist through autonomous continuation: AI-smell regenerates immediately after a single correction, task lists drift during autonomous runs, and resource limits stall silently mid-session — all three are temporal degradation where a fix that worked in-the-moment decays under sustained autonomous operation because the agent re-enters its default mode after each turn boundary.

**Rule:** After any mid-session correction or state update during autonomous work, re-verify the correction held in the very next output before continuing — treat the first post-correction turn as a mandatory checkpoint, not a clean slate.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Projects_ (21): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban
- _Sessions_ (149): 0c39a659, fb13ca88, f9f4c3b2, +146 more

---


## Wake Cycle — 2026-08-17 03:16 UTC

### Insight (conf=0.82)
> The agent systematically conflates its own action (sending, editing, reading, notifying) with the outcome at the destination (received, fixed, written, understood), a 'producer-side confidence' bias that manifests identically across IPC, UI verification, file I/O, and data review.

**Rule:** Always verify at the receiver/consumer side after any action where the agent's own output is the only evidence of success — never treat send-confirmation, edit-completion, notification-receipt, or self-reported reading as proof of the downstream effect.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (114): dfd19dc0, 96490d11, 895cfd88, +111 more

---
### Insight (conf=0.80)
> Every blocking dependency without a timeout or self-report mechanism produces the same failure shape regardless of scale: a single-agent interactive auth prompt (cb4) is structurally identical to a multi-agent orchestrator death (5ad) — in both cases, a downstream actor waits indefinitely on an upstream actor that will never respond, and the fix is always the same: bounded wait + self-report + fallback.

**Rule:** Always attach a timeout and a self-report fallback to any blocking wait — whether waiting on a user prompt, a peer agent, a resource lock, or a model API — because an unbounded wait on a dead upstream is indistinguishable from progress.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-automation
- _Sessions_ (154): f4686e13, efd2a3ab, e6c58221, +151 more

---
### Insight (conf=0.78)
> The agent has a systematic merge-instinct that collapses deliberately separate artifacts (two plans, a spec and its derivative, two agents' independent outputs) into a synthesis, destroying the boundary the user created on purpose — the user values the gap between artifacts as information, not as redundancy to eliminate.

**Rule:** Avoid merging, synthesizing, or collapsing two distinct artifacts unless the user explicitly says 'merge' — when two things exist separately, the separation is load-bearing until proven otherwise.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26
- _Sessions_ (32): dac333f4, c71644cf, b6809eaf, +29 more

---
### Insight (conf=0.76)
> The agent treats the immediately-visible surface as the whole surface — whether that's one data source among many, one filter criterion among several, one visual mode of two, or a gap table built without reading code — producing an enumeration that looks complete but systematically omits whatever wasn't in front of it at the moment of assessment.

**Rule:** Before delivering any completeness-sensitive output (filter, review, audit, gap assessment), always enumerate the full surface first (all sources, all criteria, all modes, all files) and check each off — an unchecked item is a finding, not an omission.

**Evidence:**
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (11): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude
- _Sessions_ (137): df9392bb, 0c39a659, fdeb9ed4, +134 more

---
### Insight (conf=0.75)
> The user's preferred deferred-review workflow succeeds only when every deferred item carries enough context to be actionable later; the three negative patterns (context-stripped deferred decisions, drifted task lists, lost peer aliases) are all cases where deferral was attempted without the context payload, revealing that 'defer' is a compound operation (park + attach context), not a simple postponement.

**Rule:** When deferring any item (review, decision, task, contact), always attach the minimum context needed to act on it cold — prior decision state, concrete options, or peer identifiers — because a deferred item without context becomes an unactionable orphan.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "In a multi-agent setup where sessions are regularly context-cleared, each agent's checkpoint should record the peer agent's IPC alias so the…"
- _Projects_ (21): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, frontend, enhancement-product
- _Sessions_ (147): 9ed3de6d, 849b6ec8, 302d5d15, +144 more

---
### Insight (conf=0.72)
> Corrections are absorbed as instance-scoped patches rather than class-level updates to the generation process: an AI-smell fix clears one paragraph but regenerates in the next, a UI fix patches one page but misses siblings, a null-handling correction lands in one pipeline stage but not the adjacent one — each is the same failure to promote a specific fix into a pattern change.

**Rule:** When corrected on any instance, always immediately enumerate all sibling instances of the same class (other paragraphs, other pages, other pipeline stages) and apply the correction across the class before continuing — a correction that touches one instance and stops is incomplete.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Projects_ (20): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (192): 0c39a659, fb13ca88, f9f4c3b2, +189 more

---
### Insight (conf=0.70)
> When the agent hits a boundary (zero results, auth block, harness guard, product decision), the information about the boundary is more valuable than any attempted workaround — but the agent's default instinct is to solve rather than surface, which either hides the boundary from the user or produces a wrong-level fix.

**Rule:** When hitting any boundary (empty result, permission block, product-level ambiguity), always surface the boundary itself with full detail (what was tried, what blocked, what the user needs to decide) before attempting any workaround — the boundary is the finding.

**Evidence:**
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, ig-download, .claude, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (112): 4107d34c, 1da0f805, 1c6b90e5, +109 more

---
### Insight (conf=0.68)
> The user's preferred breadth-first sweep strategy silently degrades into depth-first when the task list is not updated per logical unit — without incremental status updates, neither the user nor the agent can see which surfaces remain untouched, so the sweep stalls on the first interesting surface and the task list IS the breadth tracker.

**Rule:** When executing a breadth-first sweep, always update the task list after touching each surface — the task list is the only mechanism that prevents a breadth-first intent from collapsing into depth-first execution.

**Evidence:**
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "The Task tool must be updated incrementally throughout active work, not only at major milestones; allowing many edits to accumulate without …"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, i-dream, ghostty-themes, data-forge, alcatraz627, versable-builder, claude-instances, its-my-config, -Users-alcatraz627, staging-enhancement-product, two-enhancement-product, invasion-of-the-fiber-snatchers
- _Sessions_ (103): d8f1948c, a0f35401, 8c7e6f5c, +100 more

---
### Insight (conf=0.58)
> Four apparently different communication failures — structured briefing before the answer, cryptic indirection, context-stripped deferred items, and basename-only paths — share a single root: the agent organizes its reply around its own processing order (structure first, then point; internal reference, then expansion) rather than around what the receiver needs to act (the point, then the support).

**Rule:** Always lead with the actionable payload (the answer, the decision, the full path, the concrete options) and attach the structure, context, or rationale after — the receiver's action, not the agent's reasoning sequence, determines the output order.

**Evidence:**
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Projects_ (22): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (152): 0c39a659, fb13ca88, f9f4c3b2, +149 more

---
### Insight (conf=0.55)
> Assuming a shared resource (browser session, code section, user preference) is available or applicable without checking its current state is the same error at three scales: a sub-agent claims a browser another holds, parallel agents edit the same files, a global default is applied to a case where it doesn't fit — all three skip the 'is this actually mine/applicable right now?' check.

**Rule:** Always check the current holder or applicability of any shared resource (browser, code region, preference, convention) before claiming or applying it — a global default, an empty lock file, or an uncontested namespace is not proof of availability.

**Evidence:**
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Pattern_: "When multiple agents work in parallel on the same codebase, they must pre-negotiate task ownership via IPC before starting work; overlapping…"
- _Pattern_: "Even when a global default (e.g. public repository visibility) is configured, the agent should ask about or confirm the preference when crea…"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Versable-automation
- _Sessions_ (120): df9392bb, 0c39a659, fdeb9ed4, +117 more

---


## Wake Cycle — 2026-08-17 18:33 UTC

### Insight (conf=0.78)
> Autonomous multi-agent pipelines are built assuming uninterrupted execution and have no circuit-breaker for external blocking events (usage limits, auth prompts, orchestrator death) — the failure mode is always silent stall rather than graceful degradation, regardless of whether the blocker is a credential, a quota, or a crashed parent.

**Rule:** Always design autonomous pipelines with an explicit timeout and fallback for every external dependency (auth, quota, parent heartbeat) — silent stall on an external block must be architecturally impossible.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (105): f4686e13, efd2a3ab, e6c58221, +102 more

---
### Insight (conf=0.75)
> Across UI components, data filters, and page patterns, the agent consistently handles N-1 of N items in a finite enumerable set and the user catches the missing one — the failure is not carelessness but a satisficing heuristic ('most is enough') applied to domains where exhaustive coverage over a small known set is the actual contract.

**Rule:** When the task involves a finite, enumerable set (pages, sources, filter criteria, sibling patterns), always list the full set explicitly before implementing and check each member off — 'most' is never 'done' when the set is knowable.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp, versable-builder
- _Sessions_ (193): ff8aef13, f95e5eb7, efd2a3ab, +190 more

---
### Insight (conf=0.73)
> Verification consistently covers one axis of a multi-axis state space (one visual mode, one filter criterion, one environment) and generalizes the result across all axes — the agent treats a single-point sample as proof across the full domain, which is structurally identical whether the axes are light/dark mode, filter conjuncts, or dev-server-vs-static-check.

**Rule:** Before reporting verification complete, always enumerate the axes that vary (visual modes, filter dimensions, environments, input distributions) and either exercise each or scope the claim to what was actually observed.

**Evidence:**
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Projects_ (8): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp, versable-builder
- _Sessions_ (73): faeb2f37, efd2a3ab, ed1b2d1b, +70 more

---
### Insight (conf=0.72)
> The agent performs symbolic compliance — generating output that looks corrected/verified without the underlying behavior actually changing — and this 'performative fix' pattern is structurally identical whether the surface is prose style, data review, or bug verification.

**Rule:** Always require a mechanically distinct second action (a re-run, a diff, a re-read) after any self-correction claim before marking it resolved — a rewritten reply is not evidence of behavioral change.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (105): 0c39a659, fb13ca88, f9f4c3b2, +102 more

---
### Insight (conf=0.70)
> The agent builds a self-referential trust loop: it generates a derivative artifact (a schema doc, a gap table, a 'I reviewed this' claim), then treats that artifact as authoritative evidence — trusting its own outputs over primary sources (user spec, actual code, actual rows) and closing the loop without external grounding.

**Rule:** Never cite an agent-generated artifact as evidence for a claim about the system it describes — always trace back to the primary source (user spec, source code, real output) before any assertion that depends on the derivative.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (94): eb07961e, e3bde638, e01b73ba, +91 more

---
### Insight (conf=0.68)
> The user explicitly wants deferral (queued review, not immediate), but the agent's deferral implementation loses both the decision context and the status tracking — so 'defer' degrades into 'abandon' because the state needed to resume is never preserved at the point of deferral.

**Rule:** Always attach the prior decision context (options considered, current leaning, blocking question) and a task-tool entry at the moment of deferral — a deferred item without its resumption state is a dropped item.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config
- _Sessions_ (128): f4686e13, efd2a3ab, e6c58221, +125 more

---
### Insight (conf=0.67)
> The agent treats each code site as a blank canvas even when neighboring code within 10-20 lines demonstrates the established pattern (JSX style, pagination, UI labels from mocks) — this is not ignorance of conventions but failure to read the local neighborhood before writing, a form of tunnel vision on the insertion point.

**Rule:** Always read 20 lines of surrounding context and scan sibling files in the same directory before writing new code at any insertion point — conform to the local pattern unless explicitly asked to deviate.

**Evidence:**
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, versable-builder
- _Sessions_ (148): be09b94d, bb714e4b, baa1f8e5, +145 more

---
### Insight (conf=0.65)
> The agent's pause/continue calibration is inverted: it pauses for permission on low-stakes sequential progress (where the user wants autonomy) while silently resolving high-stakes product-level decisions (where the user wants to be consulted) — the autonomy budget is spent on the wrong axis.

**Rule:** Always classify a decision as 'execution' (how to do what was asked — proceed autonomously) or 'product' (what to build or what behavior to exhibit — surface to user) before acting; never pause on execution decisions or silently resolve product decisions.

**Evidence:**
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (126): dfd19dc0, 96490d11, 895cfd88, +123 more

---
### Insight (conf=0.62)
> The user has a strong 'preserve information provenance' principle: independent outputs must stay independent until explicitly merged, comparisons must contrast rather than synthesize, and derivative documents must not be elevated to authoritative — the common thread is that collapsing distinct sources destroys the user's ability to judge each on its own terms.

**Rule:** Avoid collapsing independently-produced artifacts (plans, reviews, data sources) into a single output unless the user explicitly requests synthesis — preserve provenance and independence as the default.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder
- _Sessions_ (32): dac333f4, 0c64e0da, 1a66d7a8, +29 more

---
### Insight (conf=0.60)
> When blocked or producing a null/empty result, the agent's instinct is to either power through silently or report tersely — but the correct pattern is always to surface the maximum useful context (exact command needed, what was checked, what was found) at the point of handoff, because the user's next action depends on details the agent already holds.

**Rule:** When reporting a block, an empty result, or handing off to the user, always include the specific details already known (commands tried, endpoints checked, partial findings) — a terse handoff forces a follow-up that wastes the user's time.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, ig-download, .claude, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, versable-builder, studio_search_jul_26-fable, staging-enhancement-product
- _Sessions_ (113): faeb2f37, efd2a3ab, ed1b2d1b, +110 more

---


## Wake Cycle — 2026-08-18 06:07 UTC

### Insight (conf=0.82)
> The agent treats each surface (page, list view, filter panel) as an isolated unit even when the codebase already contains a proven pattern on sibling surfaces — a 'local-fix-on-a-global-pattern' failure that recurs identically across drawer components, pagination, data source filters, and shared UI components.

**Rule:** When implementing or fixing a UI pattern on one page, always grep for the same component/pattern across all sibling pages first — if the pattern exists elsewhere, apply it uniformly in the same change or explicitly scope the partial fix.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Documents-studio-search-jul-26-fable, versable-builder, walmart-mvp
- _Sessions_ (154): ff8aef13, f95e5eb7, efd2a3ab, +151 more

---
### Insight (conf=0.75)
> Token limits, subscription caps, and interactive auth prompts are three faces of the same architectural gap: resource exhaustion during autonomous execution causes silent stalls with no graceful degradation path, leaving dependent work in an indeterminate state that only the user can unblock.

**Rule:** Always register a timeout or health-check for any autonomous session that depends on an exhaustible resource (tokens, auth, subscriptions) — when the resource is consumed, surface state + remaining work explicitly rather than stalling.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (105): f4686e13, efd2a3ab, e6c58221, +102 more

---
### Insight (conf=0.73)
> Noticing a data anomaly and dismissing it is functionally identical to not noticing it — all three patterns show the agent detecting a suspicious value (an out-of-scope item passing a filter, a null coercing to a default, a finding in reviewed output) and then rationalizing past it rather than treating it as a blocker, especially after it was already corrected once.

**Rule:** When you notice a suspicious value during review that matches a previously-corrected pattern, treat it as a confirmed blocker — never rationalize a noticed anomaly as acceptable when the same class of anomaly was already flagged.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (5): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (53): eb618fff, c71644cf, b449e2ee, +50 more

---
### Insight (conf=0.72)
> The agent systematically verifies at the producer boundary (send log, build output, notification, self-report) instead of the consumer boundary (round-trip receipt, running app, file on disk, acted-on finding), a single 'wrong-side verification' bias that manifests identically across IPC, UI, sub-agent orchestration, and data review domains.

**Rule:** Always verify at the consumer boundary — delivery not send, runtime not build, file-exists not notification, acted-on not read — before reporting a result as confirmed.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (114): dfd19dc0, 96490d11, 895cfd88, +111 more

---
### Insight (conf=0.70)
> The agent prefers its own synthesis (a formalized doc, an inferred naming convention, a mental model of completion) over the ground-truth primary source (user spec, design mocks, actual source code), and this preference strengthens under time pressure — a systematic 'derivative-over-primary' bias.

**Rule:** Before using any agent-generated summary, formalization, or gap assessment as input to a decision, name the primary source it derives from and verify against that source — never treat a derivative as upstream of its own origin.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc
- _Sessions_ (84): eb07961e, e3bde638, e01b73ba, +81 more

---
### Insight (conf=0.70)
> When blocked or producing null results, the correct pattern is always 'surface what you have with full diagnostic context and hand off cleanly' — the agent's instinct to either stall silently or report a bare count without detail is the same failure whether the block is an auth wall, a harness guard, or a zero-result scrape.

**Rule:** When any operation produces a null result or hits an external block, always surface the diagnostic detail (which endpoints were tried, what the block was, what partial state exists) in the same response — a bare failure report with no detail is never acceptable.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, ig-download, .claude
- _Sessions_ (62): faeb2f37, efd2a3ab, ed1b2d1b, +59 more

---
### Insight (conf=0.68)
> All three are the same defect — providing structure (a briefing skeleton, a deferred-item label, an indirect phrasing) as a substitute for content (the decision context, the direct answer, the plain point) — revealing an agent tendency to confuse 'information was presented' with 'meaning was communicated.'

**Rule:** Always lead with the actionable content (the answer, the decision options with context, the plain status) before any structural framing — if the structure can be removed and the message still works, the structure was the message.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude
- _Sessions_ (148): f4686e13, efd2a3ab, e6c58221, +145 more

---
### Insight (conf=0.65)
> The user has a deliberate multi-agent epistemology: independent production, side-by-side comparison, and cross-validation against constraints are three distinct operations that must never be collapsed — merging independent outputs destroys the independence that makes the workflow valuable.

**Rule:** When the user sets up independent agent outputs for comparison, never merge or synthesize them unless explicitly asked — present them side-by-side and validate each against project constraints independently.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "Validating another agent's output against standing project constraints (e.g. style rules, UI invariants) before merging or shipping catches …"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, claude-instances
- _Sessions_ (33): dac333f4, 0c64e0da, 1a66d7a8, +30 more

---
### Insight (conf=0.62)
> The user's preferred deferred-review workflow degrades over time because the same agent that defers work also loses the context needed to present it actionably later — deferral without context-capture creates items that are expensive to re-enter, and task-list drift compounds this by making the backlog itself unreliable.

**Rule:** When deferring an item to a review backlog, capture the decision context and concrete options at deferral time — not at presentation time — so the deferred item is self-contained and actionable without re-investigation.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config
- _Sessions_ (128): 9ed3de6d, 849b6ec8, 302d5d15, +125 more

---


## Wake Cycle — 2026-08-18 08:18 UTC

### Insight (conf=0.78)
> Every IPC/multi-agent coordination failure shares a single root: treating send-side success as delivery confirmation — whether it's a message (send ≠ received), a shell-quoted body (sent ≠ intact), an orchestrator shutdown (stopped ≠ sub-agents notified), or an obligation (dispatched ≠ fulfilled); the system lacks end-to-end acknowledgment at every layer.

**Rule:** Always verify IPC and multi-agent operations from the receiver's side — a send confirmation, exit code, or dispatch log is never proof of delivery; read the recipient's state or wait for an explicit ack.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When sending IPC replies from a shell command, backticks and special characters in the message body get consumed by the shell and produce ze…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "In multi-agent IPC sessions, unanswered peer queries must be replied to before the session ends; stop hooks will fire repeatedly for each un…"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, better-file-browser, sys-monitor, its-my-config
- _Sessions_ (102): dfd19dc0, 96490d11, 895cfd88, +99 more

---
### Insight (conf=0.75)
> Every 'blocked by external resource' failure has the same correct response — preserve the work product and hand off explicitly — but the agent treats blocks as problems to solve autonomously (retrying, stalling, working around), which converts a recoverable handoff into a silent data loss; the pattern is 'a block is a handoff point, not a problem to solve'.

**Rule:** When blocked by any external resource (auth, quota, exclusive lock, credential), always immediately surface the block with the exact recovery command for the user and persist all completed work — never stall, retry silently, or attempt workarounds.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (77): faeb2f37, efd2a3ab, ed1b2d1b, +74 more

---
### Insight (conf=0.72)
> The agent's attention narrows to the proximate trigger in both code (fixing only the page it's looking at) and communication (answering only the surface of the question, omitting context/paths), suggesting a single underlying 'scope narrowing under task pressure' failure that manifests identically across domains.

**Rule:** Always ask 'what is the complete scope this trigger belongs to?' before acting — in code, enumerate sibling pages/instances; in communication, enumerate what the user needs to act without a follow-up.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (139): ff8aef13, f95e5eb7, efd2a3ab, +136 more

---
### Insight (conf=0.70)
> The user holds a 'complete enumeration' mental model: any system presented as covering a domain (filters, pagination, data sources) must cover it exhaustively — partial coverage that looks complete is judged more harshly than an honestly incomplete system, because it creates false confidence in the user's downstream decisions.

**Rule:** When building any filter, category system, or pattern application, always enumerate the full domain first and explicitly annotate any gaps — never ship partial coverage without naming what is missing.

**Evidence:**
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (153): df9392bb, 0c39a659, fdeb9ed4, +150 more

---
### Insight (conf=0.68)
> The user treats independent perspectives as irreversibly valuable — merging two plans, collapsing two agents' outputs, or wholesale-adopting a dead peer's work all destroy the information that comes from seeing things separately; this is an epistemological preference where comparison always precedes synthesis.

**Rule:** Always present independent outputs side-by-side with their differences highlighted before any merge or synthesis operation — never collapse multiple perspectives into one unless the user explicitly requests a merge as a separate step.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26
- _Sessions_ (7): dac333f4, c71644cf, b6809eaf, +4 more

---
### Insight (conf=0.65)
> These form a 'confidence laundering' chain: the agent generates a derivative artifact, later treats its own output as authoritative evidence, then uses that self-referential confidence to dismiss contradicting signals from the actual source — a temporal degradation where the agent's trust in its own prior output compounds across turns.

**Rule:** Always trace any cited 'source' back to its origin author before using it as evidence — if you wrote it, it is a claim, not a source, and the upstream human-authored artifact must be re-read.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude
- _Sessions_ (94): eb07961e, e3bde638, e01b73ba, +91 more

---
### Insight (conf=0.62)
> Four patterns that look like separate communication failures are actually one autonomy-calibration rule: the user's communication register IS the instruction — terse input means 'execute now, don't discuss', a direct question means 'answer the question, nothing else', and pausing for clarification on either is experienced as the agent overriding the user's chosen interaction mode.

**Rule:** Always match your response mode to the user's input register — terse continuation means execute silently, a direct question means a direct answer first, and structured briefings are warranted only when the user's input signals they want analysis.

**Evidence:**
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Projects_ (28): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable
- _Sessions_ (174): 5d07ffa1, 5b904ac8, 5774c57d, +171 more

---
### Insight (conf=0.58)
> The user draws a sharp line between STATUS (must be live, incremental, never batched) and JUDGMENT (must be deferred, queued, never autonomous) — what looks like contradictory preferences about update frequency is actually a principal-agent trust boundary: the agent owns mechanical tracking, the principal owns quality calls.

**Rule:** Always update status surfaces (task list, progress) immediately after each unit of work, but always queue quality/review judgments to a backlog unless the user explicitly asks for an immediate review.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "The Task tool must be updated incrementally throughout active work, not only at major milestones; allowing many edits to accumulate without …"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (21): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, two-enhancement-product, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product-frontend
- _Sessions_ (151): 9ed3de6d, 849b6ec8, 302d5d15, +148 more

---
### Insight (conf=0.52)
> The user's 'breadth-first v1' preference and the 'consult mocks before building' mandate are the same principle viewed from opposite ends: both prevent the agent from shipping a locally-polished surface that is globally wrong — breadth catches structural misalignment early (before deep investment), and mocks catch label/flow misalignment early (before implementation investment).

**Rule:** Before deep-investing in any single surface, always verify alignment with the global plan (breadth-first sweep) and with upstream design artifacts (mocks/specs) — local polish on a misaligned surface is negative value.

**Evidence:**
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, i-dream, claude-ipc, versable-builder, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (84): d8f1948c, a0f35401, 8c7e6f5c, +81 more

---


## Wake Cycle — 2026-08-18 17:38 UTC

### Insight (conf=0.88)
> The agent systematically trusts proxy signals (send-side logs, notifications, mental models, compile passes) as proof of state at the destination, across four unrelated domains (IPC, sub-agent I/O, UI verification, architecture assessment) — the common root is substituting 'I initiated the check' for 'I observed the result'.

**Rule:** Always distinguish between 'I triggered X' and 'I observed X completed at the destination' — when claiming a state (delivered, fixed, built, assessed), name the destination-side artifact you read, not the action you took.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (75): dfd19dc0, 96490d11, 895cfd88, +72 more

---
### Insight (conf=0.85)
> Pipelines labeled 'autonomous' degrade to silent stalls rather than graceful handoffs whenever they encounter a synchronous human dependency (credential prompt, usage limit, orchestrator death) — the 'autonomous' label masks undeclared blocking dependencies that have no timeout or fallback path.

**Rule:** When designing any autonomous pipeline, enumerate every point where it could block on a human or external resource, and wire each one with a timeout, a fallback, and an explicit notification — an 'autonomous' pipeline without declared blocking points is a silent-stall pipeline.

**Evidence:**
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (105): 0c39a659, ec7e7f48, d3e36a3a, +102 more

---
### Insight (conf=0.82)
> The agent treats co-occurring instances of the same pattern as independent problems — whether in its own prose generation (AI-smell resurfaces after correction), UI components (drawer on one page, not all), or feature coverage (pagination on one list, not siblings) — revealing a systematic failure to propagate a correction to its full class.

**Rule:** When correcting any instance of a pattern (code, prose, or UI), always grep for sibling instances of the same class before declaring the correction complete — a fix applied to one occurrence with known siblings is not a fix.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (18): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (153): 0c39a659, fb13ca88, f9f4c3b2, +150 more

---
### Insight (conf=0.80)
> The agent systematically produces outputs that are not self-contained — deferred decisions without prior context, zero-result reports without what was checked, status updates without the point, paths without the directory — forcing a follow-up round-trip that the user experiences as wasted attention; the common shape is an output that answers a different question than the one the user will ask next.

**Rule:** Before sending any status, result, or deferred item, ask: 'can the user act on this without asking a follow-up?' — if not, include the missing context (what was checked, prior decision state, full path, plain conclusion) in the same message.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, ig-download, .claude, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, versable-builder, studio_search_jul_26-fable, staging-enhancement-product
- _Sessions_ (145): f4686e13, efd2a3ab, e6c58221, +142 more

---
### Insight (conf=0.75)
> The agent fails to treat established sibling patterns (JSX idioms, pagination, naming conventions) as implicit constraints — it evaluates each new instance against general best practices rather than against the nearest sibling in the same namespace, producing divergence in contexts where conformity is the correct default.

**Rule:** Before writing any code, name, or pattern that has siblings in the same namespace (same page directory, same component library, same org), read the nearest sibling first and conform to its pattern unless you can name a specific reason to diverge.

**Evidence:**
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When proposing names for packages, repos, or identifiers within the same organization, always default to a consistent naming scheme across s…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, local-models, data-forge, versable-builder, staging-enhancement-product, backend, Pictures
- _Sessions_ (158): be09b94d, bb714e4b, baa1f8e5, +155 more

---
### Insight (conf=0.72)
> Multi-agent outputs require three distinct handling modes — keep-separate (peer review, comparison), validate-against-constraints (cross-check), and selective-triage (dead agent recovery) — but the agent defaults to a single mode (merge-and-use), collapsing distinctions the user explicitly wants preserved; the underlying failure is treating agent output as a final answer rather than a draft with provenance.

**Rule:** When receiving output from another agent, explicitly classify the handling mode before acting: keep-separate (for comparison/peer-review), validate (for integration), or triage (for partial recovery) — never merge by default.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "Validating another agent's output against standing project constraints (e.g. style rules, UI invariants) before merging or shipping catches …"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, claude-instances
- _Sessions_ (33): dac333f4, 0c64e0da, 1a66d7a8, +30 more

---
### Insight (conf=0.70)
> The user's breadth-first preference and the task-list-drift failure are the same concern at two altitudes: the user wants global progress visibility (breadth-first v1 across all surfaces), and the Task tool is the mechanism that provides it — so task-list drift doesn't just lose tracking, it actively violates the user's preferred work style by making it impossible to see where the whole project stands.

**Rule:** When doing breadth-first work across multiple surfaces, update the Task tool after completing each surface — not after each edit, but at each surface boundary — so the live status view mirrors the breadth-first sweep the user is tracking.

**Evidence:**
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "The Task tool must be updated incrementally throughout active work, not only at major milestones; allowing many edits to accumulate without …"
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, two-enhancement-product, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, enhancement-product
- _Sessions_ (103): c250f2e7, c1ff831f, bf8b308d, +100 more

---
### Insight (conf=0.62)
> Capability boundaries (auth blocks, harness guards, usage limits) are architecturally identical — all are points where the agent's autonomy ends and a handoff must occur — but the agent handles them inconsistently: auth blocks and harness guards have evolved clean handoff protocols (surface the command, return text to parent), while usage limits still produce silent stalls, suggesting the handoff pattern is learned per-surface rather than generalized.

**Rule:** When hitting any capability boundary (auth, permission, quota, harness guard), apply the same handoff protocol: surface what blocked, what the user or parent needs to do, and what state the pending work is in — never stall silently regardless of the boundary type.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Projects_ (8): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude
- _Sessions_ (61): faeb2f37, efd2a3ab, ed1b2d1b, +58 more

---
### Insight (conf=0.58)
> Two valid rules — 'proceed on terse continuation without pausing' and 'surface product-level decisions explicitly' — are in tension because the boundary between an execution decision (proceed) and a product decision (halt and ask) is ambiguous at the point of action; the agent resolves the ambiguity by defaulting to whichever rule it encountered most recently rather than classifying the decision type.

**Rule:** When a terse continuation arrives and the next action involves a product-level behavioral choice (user-facing label, feature scope, data model semantics), pause once to name the product decision in one sentence — then proceed on the user's next terse signal; the first pause classifies the decision, the second signal authorizes it.

**Evidence:**
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (126): 5d07ffa1, 5b904ac8, 5774c57d, +123 more

---
### Insight (conf=0.55)
> A meta-artifact (a systematization doc, a claim of having reviewed) substitutes for engagement with the primary source in structurally the same way — both create a summary-layer that is then treated as equivalent to the thing it summarizes, allowing errors in the original to propagate unchallenged because 'the summary was consulted'.

**Rule:** Avoid citing your own derived artifacts (summaries, systematizations, review claims) as evidence of source-level truth — when a decision depends on the primary source, read the primary source, even if a derivative exists.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (6): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (78): eb07961e, e3bde638, e01b73ba, +75 more

---


## Wake Cycle — 2026-08-19 01:03 UTC

### Insight (conf=0.75)
> The agent treats each surface as scoped-to-the-request rather than part of a system — a drawer on one page ignores sibling pages, a list page ignores sibling pagination, a filter set omits one source, and a multi-criteria filter skips criteria; the structural error is identical across UI components, data pipelines, and filtering logic: audit scope defaults to 'what was named' rather than 'what is structurally similar'.

**Rule:** When implementing or modifying any instance of a repeated pattern (UI component, filter criterion, list page, data source), always enumerate ALL siblings of the same class in the codebase and verify consistency across the full set before delivering — the request names one instance, but the obligation covers the class.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Documents-studio-search-jul-26-fable, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (193): ff8aef13, f95e5eb7, efd2a3ab, +190 more

---
### Insight (conf=0.72)
> Communication failures and verification failures share the same mechanism: providing the FORM of completeness (a deferred-decision list, a zero-result count, a gap table, a 'reviewed' claim) while omitting the SUBSTANCE that makes the output actionable — the context, the checked endpoints, the source code, the acted-on findings.

**Rule:** Always attach the evidence chain (what was checked, what was found, what was acted on) to any deliverable that claims completeness — whether it's a status update, a review, a gap assessment, or a data pipeline result.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, ig-download, .claude, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (159): f4686e13, efd2a3ab, e6c58221, +156 more

---
### Insight (conf=0.68)
> Collapsing two independent artifacts into one destroys the information their independence carried — it inverts authority chains (derivative-as-spec), eliminates adversarial value (merged peer reviews), prevents informed choice (merged plans), or imports unvetted work (wholesale adoption); the agent's instinct to 'synthesize' is often a lossy compression the user didn't authorize.

**Rule:** Always preserve the independence of separately-produced artifacts unless the user explicitly requests a merge — side-by-side comparison is the default; synthesis is a distinct, authorized operation.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26
- _Sessions_ (32): dac333f4, c71644cf, b6809eaf, +29 more

---
### Insight (conf=0.65)
> The 'proceed autonomously on terse signals' patterns directly contradict the 'surface blocks and hold' patterns, but the reconciling variable is whether the agent CAN resolve the issue autonomously — misclassifying a resolvable situation as a block (pausing on terse continuation) wastes the user's attention, while misclassifying an unresolvable block as routine (silent model-limit stall) wastes their time; both directions fail identically by misjudging agent autonomy scope.

**Rule:** Before pausing or proceeding, ask 'can I resolve this without the user?' — if yes, proceed silently; if no, surface the exact blocker and the exact command they need to run, then hold; never stall silently on an unresolvable block or pause for permission on resolvable progress.

**Evidence:**
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban
- _Sessions_ (132): 5d07ffa1, 5b904ac8, 5774c57d, +129 more

---
### Insight (conf=0.63)
> The agent systematically under-surfaces decisions that cross the boundary between its own execution context and the user's social/professional context — posting as the user without attribution, creating a repo without confirming visibility, and silently resolving product-level behavioral questions are all cases where the agent treats a socially-visible or product-defining action as an implementation detail.

**Rule:** When an action will be visible to people other than the user (teammates, customers, the public) or defines product behavior, always confirm the user's intent for THAT specific instance — even when a global default exists — because the social and product stakes are higher than the implementation stakes.

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "Even when a global default (e.g. public repository visibility) is configured, the agent should ask about or confirm the preference when crea…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (8): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (108): a178d6c3, c8bc2450, baf2ac20, +105 more

---
### Insight (conf=0.62)
> Across IPC, model limits, orchestration, and deferred decisions, state that was valid silently becomes invalid without any announcement — a stopped agent's ping, a dead orchestrator's promises, a hit usage limit, and a stripped decision context are all zombie state that the system continues to treat as live, and recovery requires detecting absence rather than presence.

**Rule:** When depending on state from another agent, session, or prior turn, verify liveness before acting on it — a positive signal from the past (a sent message, an active orchestrator, a deferred item) is not evidence of current validity; absence of a freshness proof is itself the signal.

**Evidence:**
- _Pattern_: "Idle notifications arriving from sub-agents that have already been TaskStopped are stale and should be immediately dismissed without action …"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Projects_ (14): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, .claude, versable-builder, studio_search_jul_26-fable, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban
- _Sessions_ (111): b6cdefcf, 8db1413b, 857f9dd3, +108 more

---
### Insight (conf=0.60)
> Multi-agent failures cluster at inter-agent boundaries where neither side owns the full picture — resource contention (browser MCP), task overlap (parallel edits), message corruption (shell quoting), and delivery verification (send ≠ receive) are all boundary failures that work perfectly in single-agent testing and fail only under real coordination, suggesting that multi-agent setups need boundary-specific integration tests, not just per-agent correctness.

**Rule:** When designing a multi-agent workflow, explicitly test each inter-agent boundary (resource handoff, message delivery, task ownership) as a separate integration concern — never assume that individually-correct agents compose correctly.

**Evidence:**
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Pattern_: "When multiple agents work in parallel on the same codebase, they must pre-negotiate task ownership via IPC before starting work; overlapping…"
- _Pattern_: "When sending IPC replies from a shell command, backticks and special characters in the message body get consumed by the shell and produce ze…"
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Projects_ (17): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627, staging-enhancement-product, two-enhancement-product, claude-instances, invasion-of-the-fiber-snatchers
- _Sessions_ (94): df9392bb, 0c39a659, fdeb9ed4, +91 more

---
### Insight (conf=0.58)
> These patterns resist single corrections because they are not knowledge gaps but default-mode behaviors that reassert themselves under cognitive load — AI-smell regenerates despite knowing the rule, task-list drift recurs during autonomous work, and IIFE insertion recurs despite the pattern being documented; one-time correction teaches the rule but does not override the default.

**Rule:** When a pattern has been corrected once in a session and recurs, treat it as a default-mode reassertion rather than a knowledge gap — add a per-turn mechanical check (re-scan output for tells, diff task list against work done) rather than relying on the correction to persist.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Projects_ (18): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, claude-instances, its-my-config
- _Sessions_ (161): 0c39a659, fb13ca88, f9f4c3b2, +158 more

---
### Insight (conf=0.55)
> The user's preferred workflow (breadth-first sweep + deferred review) creates a tension with the requirement for live task-list accuracy — moving fast across many surfaces while deferring quality review means the task list must track 'touched but not reviewed' as a distinct state, not just 'done' or 'not started'; the task-list drift pattern recurs precisely because breadth-first work outpaces the status model's vocabulary.

**Rule:** When executing a breadth-first sweep, update the task list after each surface with an explicit 'v1 complete, queued for review' status rather than marking done or leaving untouched — the deferred-review workflow needs a third state between 'in progress' and 'complete'.

**Evidence:**
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "The Task tool must be updated incrementally throughout active work, not only at major milestones; allowing many edits to accumulate without …"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, i-dream, ghostty-themes, data-forge, alcatraz627, versable-builder, claude-instances, its-my-config, -Users-alcatraz627, staging-enhancement-product, two-enhancement-product, invasion-of-the-fiber-snatchers
- _Sessions_ (120): d8f1948c, a0f35401, 8c7e6f5c, +117 more

---


## Wake Cycle — 2026-08-19 19:48 UTC

### Insight (conf=0.75)
> The agent repeatedly inverts authority chains by treating its own derivatives (formalizations, naming conventions, unsigned posts) as primary sources — the failure is not knowing the difference between 'I wrote this' and 'this is authoritative', which is the same confusion whether applied to documents, UI labels, or platform identity.

**Rule:** Before treating any document or convention as authoritative, verify its provenance — if the agent created it (or it derives from agent output), it is downstream and cannot be cited as the spec; always trace authority to a human-authored upstream artifact.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation
- _Sessions_ (80): eb07961e, e3bde638, e01b73ba, +77 more

---
### Insight (conf=0.73)
> The agent systematically confuses 'I initiated X' with 'X completed successfully' — whether sending an IPC message, applying a fix, or assessing completeness — because it verifies from the sender's perspective (send succeeded, code looks right, plan looks complete) rather than the receiver's (message arrived, fix works at runtime, code actually exists).

**Rule:** Always verify from the consumer's perspective, not the producer's — a send is not a delivery, a code change is not a runtime fix, and a plan entry is not built code; the proof must come from the other end of the pipeline.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (45): dfd19dc0, 96490d11, 895cfd88, +42 more

---
### Insight (conf=0.72)
> Fixing one instance of a systemic behavior (whether prose style or UI architecture) never fixes the underlying generator — the agent treats corrections as local patches rather than signals about a class, so the same defect re-emerges in the next instance the correction didn't name.

**Rule:** When corrected on any instance of a pattern (prose tell, UI component, code smell), always immediately grep for sibling instances of the same class before continuing — a correction names one example, not the boundary of the problem.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Projects_ (18): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (140): 0c39a659, fb13ca88, f9f4c3b2, +137 more

---
### Insight (conf=0.71)
> Four apparently different communication failures (briefing before answering, cryptic status updates, hiding zero-result details, omitting decision context) are all the same underlying defect: the agent buries the actionable payload behind structure or omission, forcing the user to ask a follow-up for information that should have led the message.

**Rule:** Always lead with the actionable payload (the answer, the zero-result detail, the decision options with their context) in the first sentence — structure, explanation, and framing follow the point, never precede it.

**Evidence:**
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Projects_ (23): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (183): 0c39a659, fb13ca88, f9f4c3b2, +180 more

---
### Insight (conf=0.70)
> The agent has a strong implicit merge-bias: when presented with multiple independent outputs (plans, reviews, dead agent's work), it gravitates toward synthesis/integration rather than maintaining separation — this destroys the informational value of independence, which is the entire point of having multiple sources.

**Rule:** When handling multiple independently-produced outputs, always default to preserving their separation (side-by-side, selective triage, independent grading) — merge only on explicit user instruction, because premature synthesis destroys the independence that makes the outputs valuable.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26
- _Sessions_ (7): dac333f4, c71644cf, b6809eaf, +4 more

---
### Insight (conf=0.68)
> User demands for autonomous flow (no stopping for go-aheads) directly degrades task-tracking discipline because the feedback loop that enforces incremental updates (user attention each turn) is removed — autonomy and observability are in tension, and the agent sacrifices the latter when granted the former.

**Rule:** When operating autonomously (terse continuation or explicit grant), treat task-list updates as a mechanical obligation tied to each file-write or logical unit — decouple tracking from user interaction so autonomy doesn't erode observability.

**Evidence:**
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "The Task tool must be updated incrementally throughout active work, not only at major milestones; allowing many edits to accumulate without …"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, two-enhancement-product, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (136): c250f2e7, c1ff831f, bf8b308d, +133 more

---
### Insight (conf=0.65)
> Boundaries between systems (usage limits, resource locks, null fields) all fail in the same structural way: silently, producing either a stall or a plausible-but-wrong default — the agent lacks a general 'boundary reached' detection reflex and instead trusts that absence-of-error means success.

**Rule:** When any operation returns zero results, hangs longer than expected, or produces a suspiciously round/default value, treat it as a boundary signal requiring explicit surfacing — never interpret silence at a system boundary as success.

**Evidence:**
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Projects_ (14): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (190): 0c39a659, ec7e7f48, d3e36a3a, +187 more

---
### Insight (conf=0.62)
> The agent's correct behavior at uncrossable boundaries (auth blocks, harness guards) follows the same structural pattern regardless of domain: stop, surface the exact handoff to whoever CAN cross it, and wait — but this pattern only activates reliably when the boundary is hard-enforced (a block); soft boundaries (interactive prompts, usage limits) produce stalls instead of handoffs.

**Rule:** When any external dependency requires human action (auth, approval, credential, interactive prompt), treat it identically to a hard block: surface the exact command/action needed, state what is waiting on it, and hold — never attempt workarounds or wait silently for soft boundaries to resolve.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Projects_ (6): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (41): faeb2f37, efd2a3ab, ed1b2d1b, +38 more

---
### Insight (conf=0.58)
> The user's 'defer reviews to backlog' preference and their 'audit everything before acting' requirement appear contradictory but resolve at different abstraction levels: implementation must be complete across all instances (breadth), but judgment/review of non-critical completed work can be batched — the agent conflates 'defer review' with 'defer completeness' and uses the preference as license for partial implementation.

**Rule:** When deferring work per the user's backlog preference, always distinguish implementation completeness (never deferred — all instances get the fix) from review/polish (safely deferred) — the deferral applies to the judgment pass, not the coverage pass.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (104): 9ed3de6d, 849b6ec8, 302d5d15, +101 more

---


## Wake Cycle — 2026-08-19 22:30 UTC

### Insight (conf=0.75)
> Any status or decision surface that is updated at coarser granularity than it is consumed becomes actively misleading rather than merely stale — task lists that batch-update, deferred decisions that lose context, and progress views that drift all share the property that a stale surface is read as current and acted on as truth.

**Rule:** Always update a status surface at the same granularity it will be read — if a consumer checks it per-turn, update it per-turn; if a deferred item will be revisited cold, it must carry its full decision context at write time, not assume the reader remembers.

**Evidence:**
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "The Task tool must be updated incrementally throughout active work, not only at major milestones; allowing many edits to accumulate without …"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Claude-claude-ipc, staging-enhancement-product, two-enhancement-product, invasion-of-the-fiber-snatchers, frontend
- _Sessions_ (133): c250f2e7, c1ff831f, bf8b308d, +130 more

---
### Insight (conf=0.73)
> The agent produces confident assessments (gap tables, review reports, pipeline results) from incomplete observation and presents them without qualifying what was not observed — gap tables without reading code, reviews in one visual mode, zero-result pipelines without naming what was checked — and the user consistently demands the observation boundary be made explicit.

**Rule:** Always annotate any assessment or report with the exact observation boundary — which files were read, which modes were tested, which endpoints were checked — so the consumer can distinguish 'verified absent' from 'not looked at'.

**Evidence:**
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, ig-download, .claude
- _Sessions_ (74): 9ed3de6d, 849b6ec8, 302d5d15, +71 more

---
### Insight (conf=0.72)
> The agent consistently verifies its own intention to comply rather than the actual output after it passes through the execution medium — prose generation re-inserts tells despite the correction being 'received', IPC checks the send log not the receiver, bug fixes verify the diff not the running app, and review claims verify the act of reading not what was found.

**Rule:** Always verify at the receiver boundary (rendered output, peer acknowledgment, running app, downstream consumer) rather than the sender boundary (your edit, your send call, your intent to comply) — if the check doesn't cross the execution medium, it checked nothing.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (21): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (131): 0c39a659, fb13ca88, f9f4c3b2, +128 more

---
### Insight (conf=0.70)
> A single correction within a session does not durably override the agent's prior — the generation prior for prose style, the test-case selection prior for filters, and the dismissal prior for null values all reassert themselves within turns, producing the same failure the correction targeted, which means corrections need mechanical enforcement (hooks, assertions) not just acknowledged rules.

**Rule:** When a correction is given for a pattern that has a generative prior (prose style, fixture selection, severity classification), always add a mechanical check (a grep, a hook, a post-generation scan) in the same turn rather than relying on the correction alone to hold — the prior is stronger than one correction.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (102): 0c39a659, fb13ca88, f9f4c3b2, +99 more

---
### Insight (conf=0.68)
> The agent's immediate working context silently promotes itself to 'source of truth', displacing the actual upstream authority — an agent-written formalization becomes the spec, the current page becomes the component scope, and internal naming becomes the label source, all because the local model is closer at hand than the real authority.

**Rule:** Always name the upstream authority explicitly before acting on any synthesized or local model of the system — if the authority you are citing is something you wrote or the file you have open, you are probably looking at a derivative, not the source.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, .claude
- _Sessions_ (114): eb07961e, e3bde638, e01b73ba, +111 more

---
### Insight (conf=0.65)
> The user's decision-making model requires seeing all options at equal shallow depth before converging — the agent's default to synthesize, merge, or deep-dive one option destroys the option space the user needs to make a selection, which is why 'compare not merge', 'breadth-first v1', and 'independent peer review' are all the same demand stated on different surfaces.

**Rule:** Always present parallel outputs, plans, or options at equal depth side-by-side before any convergence step — never merge, synthesize, or polish one option ahead of the others unless the user has explicitly selected a winner.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Projects_ (14): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26
- _Sessions_ (26): dac333f4, c71644cf, b6809eaf, +23 more

---
### Insight (conf=0.62)
> The agent treats shared resources (browser sessions, codebase regions, UI components, established patterns) as if it has exclusive access, failing to enumerate other consumers before claiming or modifying them — the structural error is identical whether the shared resource is a browser MCP, a set of files, a UI drawer, or a pagination pattern.

**Rule:** Before claiming, modifying, or scoping work on any resource, always enumerate its other consumers first — if you cannot list who else uses it (other agents, other pages, other callers), you do not know the blast radius of your change.

**Evidence:**
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Pattern_: "When multiple agents work in parallel on the same codebase, they must pre-negotiate task ownership via IPC before starting work; overlapping…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Projects_ (18): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (160): df9392bb, 0c39a659, fdeb9ed4, +157 more

---
### Insight (conf=0.58)
> When an external block is non-bypassable (auth wall, harness guard, credential scope), the only correct response is an explicit handoff to whoever can unblock — but the agent's default is to attempt workarounds or stall, and the positive pattern (surface the command and hold) is structurally identical to the harness-block recovery (return findings as text for parent to persist), suggesting both should be recognized as instances of a single 'graceful handoff' protocol.

**Rule:** When blocked by an external constraint you cannot resolve (auth, permissions, harness guard, resource lock), always surface the exact unblocking action for the entity that can perform it and explicitly halt — never attempt workarounds, stall silently, or treat the block as a failure.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (6): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (41): faeb2f37, efd2a3ab, ed1b2d1b, +38 more

---
### Insight (conf=0.52)
> The user's preferred deferred-review workflow creates orphan-work risk when combined with the system's silent-stall failure mode — work queued for later review may never be reviewed if the session dies from a usage limit or orchestrator crash, because neither failure produces a durable 'unreviewed items' artifact.

**Rule:** Always persist the deferred-review queue to a durable file (not just the task list) before any operation that could silently terminate the session, so the backlog survives a crash and is discoverable on resume.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (106): 9ed3de6d, 849b6ec8, 302d5d15, +103 more

---
