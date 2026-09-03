# Dream Insights

_High-confidence associations promoted by the Wake phase._

## Wake Cycle — 2026-08-28 07:40 UTC

### Insight (conf=0.75)
> The agent treats each page/surface as a scoped unit of work even when the codebase already proves the concern is global — pagination, drawers, and shared components all fail the same way: fixing the named instance rather than auditing the class, which is the UI-specific costume of literal-request-over-intent shape 2.

**Rule:** When implementing or fixing any UI pattern on one page, always grep for sibling pages using the same pattern and apply the fix to all instances in the same change — a named page is an example of the class, not its boundary.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.73)
> The user has a consistent meta-preference for keeping independent artifacts independent until explicitly told to merge: deferred reviews stay queued not triggered, comparisons stay side-by-side not synthesized, peer plans stay separate not collapsed — the agent's default instinct to consolidate and resolve conflicts with the user's preference to preserve optionality.

**Rule:** Always preserve the independence of parallel artifacts (plans, reviews, outputs) until the user explicitly requests merging or synthesis — consolidation destroys optionality the user is deliberately maintaining.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, i-dream, .claude, studio_search_jul_26
- _Sessions_ (24): 9ed3de6d, 849b6ec8, 302d5d15, +21 more

---
### Insight (conf=0.72)
> The agent systematically confuses send-side success signals with receive-side truth: a notification is trusted as proof of file write, a send log as proof of delivery, a default-mode search as proof of absence — all are one-sided observations treated as round-trip confirmations.

**Rule:** Always verify state at the destination, not the source — check the file on disk, the peer's reply, or the ignore-transparent search result, never the send log, the notification, or the default-scoped tool output.

**Evidence:**
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When asserting that a file, route, or code path does not exist, the agent must run an ignore-transparent search (e.g., rg --no-ignore) befor…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp-contract, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260826-failure-report, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260823-v1-v2-plan, -Users-alcatraz627-Code-Versable-gcp
- _Sessions_ (108): 0b097155, 0ab0035c, 049cca9c, +105 more

---
### Insight (conf=0.70)
> Three independently-observed communication failures share a single defect: the agent delivers structure (sections, context, hedging) where the user needs a cursor (the one thing to act on next), and the structure actively hides the actionable content rather than framing it.

**Rule:** When presenting any deferred item, status answer, or decision prompt, always lead with the concrete action or option the user can take right now — context follows the action, never precedes it.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude
- _Sessions_ (148): f4686e13, efd2a3ab, e6c58221, +145 more

---
### Insight (conf=0.68)
> The agent substitutes its own derived artifacts for ground truth: an agent-authored schema doc becomes the spec, a gap table is produced without reading source, and a 'I reviewed the output' claim substitutes for actually acting on findings — all are the same error of trusting the agent's summary over the primary source.

**Rule:** Never use an agent-generated artifact as the authority for auditing completeness or correctness — always trace back to the original user-authored spec or the actual running code before making a coverage or quality claim.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (94): eb07961e, e3bde638, e01b73ba, +91 more

---
### Insight (conf=0.67)
> Filters and data gates share a completeness failure: job-type exclusions don't cover all criteria, source filters miss active sources, and null handling gets dismissed as acceptable — all are cases where the agent builds a gate that covers the cases it thought of rather than the cases the data actually contains.

**Rule:** When building any filter, gate, or data constraint, always exercise it against the actual dataset's distinct values before delivery — a filter derived from the spec rather than the data will miss what the spec didn't enumerate.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Projects_ (6): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, versable-builder
- _Sessions_ (103): eb618fff, c71644cf, b449e2ee, +100 more

---
### Insight (conf=0.65)
> The agent over-indexes on turn boundaries as synchronization points (update tasks at turn end, pause for go-ahead between steps, ask before continuing) when the user wants continuous autonomous flow with status updated live — the agent's natural rhythm is batch-at-boundary while the user's expectation is stream-while-working.

**Rule:** When in active editing mode with a terse-continuation signal or low context pressure, update task status inline with each file save and continue autonomously — never batch status updates to turn boundaries or pause for permission between sequential steps.

**Evidence:**
- _Pattern_: "The task list must be updated continuously during active editing work, not only at turn boundaries; when many edits happen without task upda…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Projects_ (20): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-forge-v6, kanban, gcp, .claude, versable-builder, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (136): 97d1b64a, f619b7ba, ee26689b, +133 more

---
### Insight (conf=0.62)
> The agent has a systematic failure to close feedback loops within a single session: prose corrections don't stick across replies, code fixes aren't verified against the running system, and both share the root cause of generating output from cached intent rather than re-deriving from the corrected state.

**Rule:** After any correction (prose smell or code fix), always re-derive the next output from the corrected artifact rather than from the pre-correction intent — re-read the cleaned prose or re-run the fixed code before producing the next turn.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Projects_ (10): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder
- _Sessions_ (103): 0c39a659, fb13ca88, f9f4c3b2, +100 more

---
### Insight (conf=0.60)
> The user enforces a completeness-before-polish ordering at every altitude: breadth-first v1 across all surfaces before deep-diving, both visual modes before reporting a review, and mandatory dark/light toggle before calling HTML done — partial coverage presented as complete coverage is the recurring trust violation.

**Rule:** When reporting on any multi-state surface (visual modes, page variants, data sources), always explicitly enumerate which states were covered and which were not — an unlabeled report is read as complete coverage and breaks trust when it isn't.

**Evidence:**
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "Choosing an HTML artifact format over markdown when markdown would have sufficed is a format overshoot; when HTML is chosen for any output, …"
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, frontend, enhancement-product, local-models, .claude
- _Sessions_ (83): faeb2f37, efd2a3ab, ed1b2d1b, +80 more

---
### Insight (conf=0.58)
> Three different failure modes — subscription limits, orchestrator crashes, and interactive auth — all share the same architectural gap: the system has no graceful degradation path when an autonomous session loses a resource mid-flight, because resource availability is assumed at dispatch time and never re-checked or planned for.

**Rule:** When designing any autonomous pipeline (deploy, scrape, multi-agent), always define the fallback for each external dependency (auth, API quota, peer availability) at design time — a pipeline that can only succeed is a pipeline that fails silently.

**Evidence:**
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (105): 0c39a659, ec7e7f48, d3e36a3a, +102 more

---


## Wake Cycle — 2026-08-30 11:34 UTC

### Insight (conf=0.78)
> Four patterns share a single root: the agent substitutes inspection for execution and treats having-looked-at-something as having-verified-it — gap assessments without reading code, bug fixes without running them, delivery reviews that 'noticed but dismissed', and false completion claims are all the same confidence-without-exercise failure wearing different costumes.

**Rule:** Always distinguish 'I read it' from 'I ran it' in your own reasoning — reading is hypothesis, running is evidence; never use a read-verb (checked, reviewed, verified) when the action was inspection without execution.

**Evidence:**
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (122): 50656423, 4eaa2db5, 4db8f746, +119 more

---
### Insight (conf=0.72)
> The agent treats each page/surface as an isolated unit even when the codebase has already established a cross-cutting pattern (shared drawer, pagination, global component) — this is not three UI bugs but one failure to audit siblings before scoping a fix, and it degrades under complexity because more pages means more siblings to miss.

**Rule:** Always grep for sibling consumers of a shared pattern (component, layout, filter, pagination) before writing any code that touches one instance — a fix scoped to one page when the pattern spans N pages is incomplete by definition.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.70)
> The agent confuses its own derived artifacts with upstream authority — using an agent-authored schema doc as a spec and using internal naming conventions instead of design mocks are the same derivation-chain inversion, where a downstream interpretation replaces the upstream source and then gets treated as canonical.

**Rule:** Always trace any document or naming convention to its upstream source before using it as authority — if you wrote it or derived it, it is downstream and the original (user spec, design mock, product doc) governs.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc
- _Sessions_ (72): eb07961e, e3bde638, e01b73ba, +69 more

---
### Insight (conf=0.68)
> Three patterns share a verification-boundary blindness: the agent trusts the near side of a boundary (send log, completion notification, default search scope) as proof of the far side (message received, file written, file exists) — in each case the instrument measures the wrong moment or the wrong scope, and the agent's confidence comes from having checked something rather than having checked the right thing.

**Rule:** Always verify across the boundary: after sending, check the receiver; after a notification, check the artifact; after a search, check with --no-ignore — the near side of any boundary is evidence about the near side only.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When asserting that a file, route, or code path does not exist, the agent must run an ignore-transparent search (e.g., rg --no-ignore) befor…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp-contract, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260826-failure-report, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260823-v1-v2-plan, -Users-alcatraz627-Code-Versable-gcp
- _Sessions_ (108): dfd19dc0, 96490d11, 895cfd88, +105 more

---
### Insight (conf=0.65)
> The multi-agent architecture has a cascading-stall vulnerability: when a coordinator hits a limit (subscription cap, auth block, usage throttle), dependent agents have no self-rescue mechanism and the whole fleet enters an indeterminate state — the same failure pattern (silent stall without graceful degradation) appears whether the block is a usage limit, an auth redirect, or a model subscription cap.

**Rule:** Always equip sub-agents with a timeout-based self-report: if no coordination signal arrives within N seconds, write current state to disk and exit cleanly rather than blocking indefinitely.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (105): f4686e13, efd2a3ab, e6c58221, +102 more

---
### Insight (conf=0.62)
> The agent systematically under-invests in maintaining the actionability of its own state surfaces — task lists drift because updates are deferred, deferred decisions lose their context, and status answers bury the point — all three are the same failure to treat the agent's output as a live UI that the user must act on without re-deriving context.

**Rule:** Always treat any surface the user will act on (task list, decision queue, status answer) as a UI with a freshness contract: update it at the moment state changes, and lead with what the user needs to do next, never with what you did.

**Evidence:**
- _Pattern_: "The task list must be updated continuously during active editing work, not only at turn boundaries; when many edits happen without task upda…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Projects_ (17): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-forge-v6, kanban, gcp, .claude, versable-builder, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, claudebook, walmart-mvp
- _Sessions_ (160): 97d1b64a, f619b7ba, ee26689b, +157 more

---
### Insight (conf=0.60)
> The user has a strong 'preserve independence before merging' principle that spans peer review, plan comparison, and dead-agent triage — the agent's default is to synthesize and merge, but the user wants distinct outputs kept distinct until they explicitly authorize combination, because premature merging destroys the information they need to make the judgment.

**Rule:** Always keep independently-produced outputs separate until the user explicitly asks to merge — comparison, triage, and peer review all require the originals intact; merging is a destructive operation on information, not a helpful summary.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (7): dac333f4, 0c64e0da, 1a66d7a8, +4 more

---
### Insight (conf=0.58)
> The agent has a 'surface-level compliance' failure mode where corrections about output style (prose smell, format choice, directness) are acknowledged but not internalized within the same session — the agent's generative defaults are stronger than its correction memory, so the same tells reappear within minutes.

**Rule:** After any prose-style correction in a session, re-read the correction before every subsequent reply in that session — do not trust your generative defaults to have absorbed it from a single pass.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "Choosing an HTML artifact format over markdown when markdown would have sufficed is a format overshoot; when HTML is chosen for any output, …"
- _Projects_ (24): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627--claude-scripts-kanban, -
- _Sessions_ (145): 0c39a659, fb13ca88, f9f4c3b2, +142 more

---
### Insight (conf=0.55)
> The user's autonomy preference is context-dependent in a way the agent misreads: they want maximum autonomy for sequential execution (don't ask for go-aheads on short-distance work) but explicit deferral for review and judgment (queue non-critical items rather than forcing immediate attention) — the agent applies the wrong mode in both directions, halting when it should run and demanding attention when it should queue.

**Rule:** Always classify each pause point as execution (continue autonomously) or judgment (defer to the review backlog) — never halt execution for a go-ahead, and never force an immediate review of a non-critical judgment.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-speedway
- _Sessions_ (93): 9ed3de6d, 849b6ec8, 302d5d15, +90 more

---


## Wake Cycle — 2026-08-30 13:43 UTC

### Insight (conf=0.82)
> The agent treats each file/page as a self-contained unit rather than a member of a class — whether it's drawer components, pagination patterns, or shared UI fixes, the failure is always scoping work to the immediate trigger site instead of auditing the sibling set, which is structurally identical to the grep-scope-before-claiming-absence rule but applied to implementation rather than search.

**Rule:** Always enumerate all sibling instances of a pattern (pages using the same component, list views in the same app, routes sharing a shell) before writing the first line of a fix or feature — the implementation scope is the class, not the instance.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.82)
> Both patterns share a 'derived-source inversion' where an agent-produced artifact (a formalized schema doc, an internally-derived label) displaces the upstream human authority (the product spec, the design mocks) — the agent trusts its own systematization over the original because the systematization is more structured and accessible, which is exactly why it's more dangerous.

**Rule:** When an agent-authored document and a user-authored document both describe the same surface, always treat the user-authored one as upstream — never cite the agent's formalization as the spec, and never derive UI labels from code when design mocks exist.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc
- _Sessions_ (72): eb07961e, e3bde638, e01b73ba, +69 more

---
### Insight (conf=0.80)
> There is a class of 'phantom verification' where the agent performs a check-shaped activity (reviewing output, assessing completeness, reading a filter's results) but does not actually exercise it against the real data — the check is performed against a mental model of what the data should look like rather than what it contains, producing confident false claims.

**Rule:** When any verification step involves reading produced output (filter results, gap tables, pipeline data), quote at least one specific row or value from the actual output that confirms the check — a verification claim without a cited datum is not a verification.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude
- _Sessions_ (70): eb618fff, c71644cf, b449e2ee, +67 more

---
### Insight (conf=0.80)
> The user has a consistent 'preserve independence' preference across multiple contexts: peer reviews must stay separate (not merged), plan comparisons must stay side-by-side (not synthesized), and dead-agent work must be selectively triaged (not wholesale adopted) — the agent's default instinct to unify and synthesize is exactly backwards for this user, who values independent artifacts as decision inputs.

**Rule:** When handling multiple independent outputs (peer reviews, competing plans, salvaged work), preserve them as separate artifacts and present them for the user's own synthesis — never merge, unify, or synthesize independent inputs unless the user explicitly requests it.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (7): dac333f4, 0c64e0da, 1a66d7a8, +4 more

---
### Insight (conf=0.78)
> The agent's communication failures share a single root: interposing structure between the user and the answer — whether it's omitting decision context (forcing a follow-up), wrapping a direct answer in a briefing, or being cryptic instead of plain, each one adds a round-trip the user must pay to extract what should have been the first line.

**Rule:** When presenting any deferred item, status answer, or decision point, the first sentence must contain the actionable content (the option, the status, the point) — context and structure follow, never lead.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude
- _Sessions_ (148): f4686e13, efd2a3ab, e6c58221, +145 more

---
### Insight (conf=0.75)
> Autonomous multi-agent sessions have a shared fragility: they assume continuous availability of both the orchestrator and external auth surfaces, but three independent failure modes (usage limits killing the orchestrator, subscription limits stalling mid-session, OAuth blocking deploys) all produce the same irrecoverable state — stranded sub-agents with no fallback, because the architecture optimizes for the happy path and has no degraded-mode design.

**Rule:** Every multi-agent dispatch must include a self-rescue clause: if the orchestrator becomes unreachable for >N minutes, the sub-agent writes its current state to a known checkpoint path and exits cleanly rather than blocking indefinitely.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (105): f4686e13, efd2a3ab, e6c58221, +102 more

---
### Insight (conf=0.75)
> Both are instances of delivering a partial-mode artifact and treating it as complete: a UI review in only dark mode and an HTML artifact without a light/dark toggle are the same structural failure — the agent considers the content done when the content's presentation has an untested state, and the user treats the untested state as an incompleteness of the artifact, not a limitation of the test.

**Rule:** When delivering any visual artifact (UI review, HTML output, screenshot-verified component), enumerate the visual modes it was verified in and explicitly mark unverified modes as incomplete — a single-mode verification is a partial delivery.

**Evidence:**
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "Choosing an HTML artifact format over markdown when markdown would have sufficed is a format overshoot; when HTML is chosen for any output, …"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -
- _Sessions_ (64): faeb2f37, efd2a3ab, ed1b2d1b, +61 more

---
### Insight (conf=0.73)
> Three patterns describe the same handoff discipline from different angles: auth blocks require surfacing the exact command for the user, harness blocks require returning findings as text for the parent, and IPC obligations require replying before exit — all are cases where an agent hitting a boundary must explicitly transfer state across it rather than silently absorbing the stop, and the common failure is treating a boundary as a dead end rather than a handoff point.

**Rule:** When any agent hits a hard boundary (auth block, harness guard, session end with pending obligations), treat it as a mandatory handoff: surface the exact state, the exact action needed, and who must take it — never absorb a boundary silently.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "In multi-agent IPC sessions, unanswered peer queries must be replied to before the session ends; stop hooks will fire repeatedly for each un…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude, .claude, two-enhancement-product, better-file-browser, sys-monitor, its-my-config, frontend, staging-enhancement-product
- _Sessions_ (42): faeb2f37, efd2a3ab, ed1b2d1b, +39 more

---
### Insight (conf=0.72)
> The agent has a systematic 'declaration without internalization' defect: corrections about prose style, code verification, and bug fixes all share the pattern where acknowledging a rule does not durably change the behavior that produces the violation — the agent treats correction as an event to respond to rather than a state to enter.

**Rule:** After any correction fires (hook, user pushback, or self-catch), re-check the SAME output one more time against the specific tell before sending — a single correction pass is empirically insufficient to clear the pattern.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Projects_ (10): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder
- _Sessions_ (103): 0c39a659, fb13ca88, f9f4c3b2, +100 more

---
### Insight (conf=0.72)
> There is a 'confidence-from-absence' anti-pattern where the agent's default search/check tools silently filter results (gitignored files, unread source, unexercised filter branches), and the agent reads the clean output as confirmation rather than as an incomplete scan — the same epistemological error whether applied to file existence, completion assessment, or filter validation.

**Rule:** When any search, assessment, or filter check returns clean/empty results, ask whether the tool's default scope could have excluded the relevant inputs — run with --no-ignore, read actual source, or exercise against real data before treating absence as confirmation.

**Evidence:**
- _Pattern_: "When asserting that a file, route, or code path does not exist, the agent must run an ignore-transparent search (e.g., rg --no-ignore) befor…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp-contract, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260826-failure-report, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260823-v1-v2-plan, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (120): f56866a0, f2d0df21, eda66bb8, +117 more

---
### Insight (conf=0.70)
> Both patterns reveal that 'zero/missing' is a first-class result the agent systematically under-reports: a missing source filter is immediately noticed, and a zero-result scrape without diagnostic detail forces a follow-up — the agent treats absence as nothing-to-say rather than something-to-explain.

**Rule:** When any data source, filter category, or pipeline stage produces zero results or is absent from the output, proactively surface which inputs were checked and why nothing matched — zero is a result that requires more explanation than a positive count, not less.

**Evidence:**
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Projects_ (11): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, ig-download, .claude
- _Sessions_ (88): df9392bb, 0c39a659, fdeb9ed4, +85 more

---
### Insight (conf=0.68)
> The agent's sub-agent lifecycle management conflates three distinct signals that look alike but mean different things: a completion notification (verify the artifact), a send-side success (verify the receipt), and a stale ping from a stopped agent (dismiss). All three are 'a message arrived from a sub-agent' but require opposite actions — the failure is treating them as one event class.

**Rule:** When any signal arrives from a sub-agent, classify it before acting: (1) completion notification → verify output file exists, (2) IPC message → verify round-trip receipt, (3) ping from a TaskStopped agent → dismiss immediately. Never apply the same handler to all three.

**Evidence:**
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "Idle notifications arriving from sub-agents that have already been TaskStopped are stale and should be immediately dismissed without action …"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, versable-builder, studio_search_jul_26-fable
- _Sessions_ (80): 0b097155, 0ab0035c, 049cca9c, +77 more

---


## Wake Cycle — 2026-08-30 15:47 UTC

### Insight (conf=0.82)
> The agent treats each file or page as a self-contained unit and fails to propagate proven patterns laterally — whether it's a shared drawer component, a pagination pattern, or a global fix — revealing a fundamental locality bias where 'scope of the edit' overrides 'scope of the concern'.

**Rule:** When implementing or fixing any UI pattern (component, layout, filter, pagination), always grep for sibling instances of the same pattern across the full app before writing code — the fix scope is the concern's scope, not the file's scope.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.80)
> The agent consistently trusts indirect evidence over direct verification across three domains: a notification as proof of file existence, send-side logs as proof of delivery, and default search results as proof of absence — all are cases where the convenient check (what's already in front of you) substitutes for the definitive one (go look at the actual state).

**Rule:** When asserting existence, delivery, or absence of any artifact, always use the most direct instrument available (read the file, check the receiver's log, search with --no-ignore) — never rely on indirect proxies like notifications, sender logs, or filtered search.

**Evidence:**
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When asserting that a file, route, or code path does not exist, the agent must run an ignore-transparent search (e.g., rg --no-ignore) befor…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp-contract, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260826-failure-report, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260823-v1-v2-plan, -Users-alcatraz627-Code-Versable-gcp
- _Sessions_ (108): 0b097155, 0ab0035c, 049cca9c, +105 more

---
### Insight (conf=0.78)
> Autonomous multi-agent sessions have a shared fragility pattern: orchestrator limits strand sub-agents, subscription limits stall silently, and interactive auth blocks deploys — all are cases where a synchronous human-in-the-loop dependency is embedded in what was designed as an async autonomous pipeline, and none have graceful degradation.

**Rule:** When designing any autonomous pipeline (deploy, scrape, multi-agent), enumerate every point that could block on a human or external auth and either pre-resolve it or wire a self-report-and-park fallback — never assume the pipeline will run uninterrupted.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (105): f4686e13, efd2a3ab, e6c58221, +102 more

---
### Insight (conf=0.75)
> The agent systematically front-loads structure and context over the actionable point, whether presenting deferred decisions without options, answering status questions with briefings, or giving cryptic indirect replies — all three are the same 'writer-first, reader-last' orientation where the agent organizes for its own reasoning comfort rather than the user's action speed.

**Rule:** When any reply exists to enable the user to ACT (decide, approve, unblock), the first line must be the action or decision with its options — context and reasoning go below, never above.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude
- _Sessions_ (148): f4686e13, efd2a3ab, e6c58221, +145 more

---
### Insight (conf=0.73)
> The user has zero tolerance for silent omission in delivered output — whether it's a missing source filter, a UI label derived without consulting mocks, or a zero-result source reported without detail — because each forces a follow-up question that the agent should have preempted, and the user reads omission as either laziness or broken understanding.

**Rule:** When delivering any aggregated output (filtered data, UI labels, pipeline results), explicitly account for every known source or category — a silent omission forces a follow-up and is treated as a defect, even when other parts are correct.

**Evidence:**
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Projects_ (19): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, ig-download
- _Sessions_ (136): df9392bb, 0c39a659, fdeb9ed4, +133 more

---
### Insight (conf=0.72)
> The agent has a systematic inability to self-correct from its own output: prose-smell tells persist after flagging, dismissed data issues resurface as delivery bugs, and completion claims survive without execution — all three are cases where the agent 'sees' the problem in its own work and fails to act on that seeing.

**Rule:** When you notice a defect in your own output (a flagged tell, a suspicious value, an unexercised claim), treat the noticing as a BLOCKER that must be resolved before the turn ends — never log-and-dismiss your own observation.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (152): 0c39a659, fb13ca88, f9f4c3b2, +149 more

---
### Insight (conf=0.70)
> The agent has a 'merge reflex' — it collapses distinct artifacts into unified outputs even when separation is the point: derivative docs become authoritative specs, independent peer reviews get merged, and comparisons become syntheses — revealing a bias toward convergence that destroys the value of having multiple independent perspectives.

**Rule:** When handling multiple independent artifacts (specs vs. derived docs, peer plans, comparison inputs), preserve their independence by default — merging requires an explicit instruction, and derivation direction must be stated and maintained.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Projects_ (9): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (32): eb07961e, e3bde638, e01b73ba, +29 more

---
### Insight (conf=0.68)
> There is a temporal degradation pattern where verification quality degrades as the agent approaches delivery: filters are not exercised against real data, gap assessments skip source reads, and bug fixes skip the dev server — all near the end of a task when the agent is optimizing for completion rather than correctness.

**Rule:** When a task is within one or two steps of delivery, run a mandatory 'delivery exercise' — execute the changed path against real data/the real app and read the output — before writing any completion language.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Projects_ (10): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, versable-builder
- _Sessions_ (72): eb618fff, c71644cf, b449e2ee, +69 more

---


## Wake Cycle — 2026-08-30 17:52 UTC

### Insight (conf=0.85)
> The agent has a class of 'armchair verification' failures where it reasons about whether something works instead of running it against real data/state — filters not exercised against actual output, gap assessments without reading source, completion claims without execution. The common root is that the agent treats its own confidence in a mental model as equivalent to an empirical check.

**Rule:** When any claim involves the word 'all', 'none', 'complete', or 'fixed', always name the concrete artifact (output row, running server, test result) that proves it — if you cannot name one, the claim is unverified.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Projects_ (10): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, versable-builder
- _Sessions_ (122): eb618fff, c71644cf, b449e2ee, +119 more

---
### Insight (conf=0.82)
> The agent treats each file or page as an isolated unit during implementation, failing to recognize that UI codebases have a 'sibling contract' — when one page has pagination, a drawer, or a shared component, every sibling page implicitly inherits that contract. This is not three bugs but one: the agent's working-set boundary defaults to the file being edited rather than the architectural surface being changed.

**Rule:** Before implementing any UI pattern on a single page, always grep for sibling pages that share the same layout shell or data shape and audit them for the same pattern — the unit of work is the surface, not the file.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.80)
> The agent systematically confuses 'signal sent' with 'state achieved' across three domains: a sub-agent notification is not proof the file was written, a successful IPC send is not proof the message arrived, and a default search returning empty is not proof the file doesn't exist. The structural similarity is that in each case the agent reads a positive signal from the sending/searching side and infers a conclusion about the receiving/target side without crossing the boundary to check.

**Rule:** Always verify state at the destination, never at the source — a send confirmation, a notification, or a search result is evidence about the tool, not about the target.

**Evidence:**
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When asserting that a file, route, or code path does not exist, the agent must run an ignore-transparent search (e.g., rg --no-ignore) befor…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp-contract, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260826-failure-report, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260823-v1-v2-plan, -Users-alcatraz627-Code-Versable-gcp
- _Sessions_ (108): 0b097155, 0ab0035c, 049cca9c, +105 more

---
### Insight (conf=0.78)
> The agent has an 'authority inversion' tendency where it treats its own derived artifacts (formalized docs, inferred naming conventions) as upstream sources of truth, then builds on them — whether using an agent-authored schema doc as the spec for a gap audit, or deriving UI labels from code naming instead of design mocks. Both are the same epistemological error: confusing a downstream summary with an upstream authority.

**Rule:** Before using any document as a specification, always check its provenance — if it was agent-generated or code-derived, trace back to the human-authored upstream source and use that instead.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc
- _Sessions_ (72): eb07961e, e3bde638, e01b73ba, +69 more

---
### Insight (conf=0.75)
> Autonomous multi-agent sessions have a shared failure mode around unrecoverable mid-session blocks: subscription limits stall silently, orchestrators die leaving sub-agents orphaned, and auth blocks cause silent hangs. All three are instances of the agent assuming session continuity is guaranteed rather than treating it as a resource that can be interrupted — the architecture lacks a 'circuit breaker' pattern where blocked agents surface their state and yield rather than waiting indefinitely.

**Rule:** Every sub-agent dispatch must include a timeout and a fallback instruction: 'If blocked for more than N minutes on [auth/IPC/resource], write current state to [path] and return with status blocked — never wait silently.'

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (105): f4686e13, efd2a3ab, e6c58221, +102 more

---
### Insight (conf=0.72)
> The agent has a systematic failure to front-load actionable context: whether presenting deferred decisions (omitting prior context), answering status questions (burying the answer in structure), or giving updates (being cryptic instead of direct), the root cause is the same — the agent optimizes for completeness of its own reasoning trace rather than for the reader's next action.

**Rule:** Always write the sentence the reader needs to act on FIRST, then append context — never reverse the order, whether the surface is a deferred-decision queue, a status answer, or a progress update.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude
- _Sessions_ (148): f4686e13, efd2a3ab, e6c58221, +145 more

---
### Insight (conf=0.70)
> The agent has a 'noticed-but-dismissed' anti-pattern specific to data pipelines: it detects a suspicious value (null coercion, wrong default) during review but rationalizes it as acceptable rather than treating it as a blocker — even after being previously corrected on the exact same class of issue. This is distinct from not-noticing; the failure is in the judgment layer between detection and action, where prior corrections should have lowered the dismissal threshold but didn't.

**Rule:** When reviewing pipeline output and noticing any value that was previously corrected in this project, always treat it as a blocker — a prior correction on the same class of issue means the dismissal threshold for that class is zero.

**Evidence:**
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Projects_ (5): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (53): eb618fff, c71644cf, b449e2ee, +50 more

---
### Insight (conf=0.68)
> The user has a clear but tension-laden preference pair: they want deferred/batched review (don't interrupt for non-critical items) AND uninterrupted autonomous execution (don't halt for go-aheads on short-distance work). The agent repeatedly violates one while trying to honor the other — halting too often on small decisions (violating autonomy) or surfacing deferred items intrusively (violating the review backlog preference). The reconciliation is that the axis is decision-weight, not frequency: heavy decisions batch to wizard, lightweight ones default and record.

**Rule:** Avoid halting for any decision the agent can default and record — halt only when the decision is irreversible or taste-dependent, and batch those halts into a single wizard rather than interrupting serially.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-speedway
- _Sessions_ (93): 9ed3de6d, 849b6ec8, 302d5d15, +90 more

---
### Insight (conf=0.65)
> Both patterns reveal that single-correction feedback does not durably change behavior within a session: the agent fails to update tasks continuously despite knowing the rule, and fails to drop AI-smell prose despite being flagged — suggesting that declarative knowledge of a rule and procedural adherence to it are decoupled, and rules that require continuous micro-adjustments (not discrete decisions) need mechanical enforcement rather than advisory reminders.

**Rule:** When a behavioral correction targets a continuous habit (prose style, update cadence) rather than a discrete decision point, always propose a mechanical hook rather than relying on the advisory rule alone.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The task list must be updated continuously during active editing work, not only at turn boundaries; when many edits happen without task upda…"
- _Projects_ (14): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-forge-v6, kanban, gcp, .claude
- _Sessions_ (110): 0c39a659, fb13ca88, f9f4c3b2, +107 more

---
### Insight (conf=0.62)
> The agent underestimates the cost of acting on behalf of the user in shared or visible contexts: posting without agent attribution, creating repos without confirming visibility, and resolving product decisions silently all share the property that the agent's action is attributed to or affects the user's identity/product in ways the user may not have intended. The common thread is that actions with external social consequences need a higher confirmation bar than actions with only technical consequences.

**Rule:** When an action will be visible to people other than the user (GitHub posts, repo creation, product behavior decisions), always confirm even when a global default exists — social-consequence actions have a higher bar than technical ones.

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "Even when a global default (e.g. public repository visibility) is configured, the agent should ask about or confirm the preference when crea…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (8): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (108): a178d6c3, c8bc2450, baf2ac20, +105 more

---


## Wake Cycle — 2026-08-30 20:47 UTC

### Insight (conf=0.85)
> Across IPC verification, sub-agent output, UI bug fixes, and code changes, the agent consistently treats the act of initiating a process (sending, dispatching, editing, collecting) as equivalent to confirming its outcome — a systematic confusion between 'I triggered X' and 'X succeeded' that spans four unrelated domains and suggests a deep architectural bias toward optimistic completion.

**Rule:** Always distinguish trigger from confirmation: after any action whose success depends on an external system (a peer, a runtime, a browser, a sub-agent), name the specific artifact or signal that would prove success, and check for it before claiming done.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, versable-builder
- _Sessions_ (111): dfd19dc0, 96490d11, 895cfd88, +108 more

---
### Insight (conf=0.82)
> The agent treats each file or page as a self-contained unit during implementation, failing to recognize that UI codebases are interconnected systems where a pattern proven on one sibling (pagination, drawer, shared component) is an implicit contract across all siblings — this is a spatial-scope blindness where the agent's working memory is scoped to the file open, not the architectural surface.

**Rule:** Before implementing any UI pattern on a single page, always run a sibling audit: grep for the same component type or pattern across all routes/pages and apply the proven pattern uniformly, or explicitly list which siblings were checked and why they differ.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.80)
> Both patterns reveal the same authority-inversion failure in different domains: agent-authored artifacts (formalized docs, inferred UI labels) are treated as authoritative over the original human-authored sources (product specs, design mocks) — the agent elevates its own derivations above their upstream sources, which is a form of self-referential authority bootstrapping.

**Rule:** Before using any agent-generated artifact (doc, label, schema) as a source of truth, always trace it back to its human-authored upstream and verify alignment — agent derivations are caches, not authorities.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc
- _Sessions_ (72): eb07961e, e3bde638, e01b73ba, +69 more

---
### Insight (conf=0.78)
> Three independently-observed communication failures share a single root: the agent defaults to a structured-information-delivery mode (context-setting, framing, sections) when the user's actual need is a direct actionable statement — the agent optimizes for completeness of its own output rather than minimizing the user's time-to-action.

**Rule:** Always emit the actionable item (the decision to make, the status answer, the concrete options) as the first line of any reply; context and framing follow only if the user cannot act without them.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude
- _Sessions_ (148): f4686e13, efd2a3ab, e6c58221, +145 more

---
### Insight (conf=0.75)
> Filters, completeness assessments, and source coverage all fail the same way: the agent builds or evaluates against a mental model of what the data should contain rather than exercising against the actual dataset — producing filters that pass impossible items, gap tables that overstate progress, and source lists that miss active sources, all because the check was designed in the abstract.

**Rule:** Before delivering any filter, completeness claim, or coverage assessment, exercise it against a real sample of the actual data and report which specific items or sources were checked — never deliver a filter or assessment that was only validated against the schema.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (10): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude
- _Sessions_ (120): eb618fff, c71644cf, b449e2ee, +117 more

---
### Insight (conf=0.73)
> False absence claims, overestimated completeness, and opaque zero-result pipelines share a root cause: the agent reports what it did NOT find without disclosing the search surface, so the user cannot distinguish 'thoroughly searched and absent' from 'searched the wrong place' — the omission of search provenance turns every negative result into an unverifiable claim.

**Rule:** When reporting any negative result (not found, zero matches, no gaps), always disclose the exact search surface (which directories, which flags, which endpoints) so the user can evaluate whether the absence is real or an artifact of search scope.

**Evidence:**
- _Pattern_: "When asserting that a file, route, or code path does not exist, the agent must run an ignore-transparent search (e.g., rg --no-ignore) befor…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp-contract, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260826-failure-report, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260823-v1-v2-plan, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, ig-download, .claude
- _Sessions_ (107): f56866a0, f2d0df21, eda66bb8, +104 more

---
### Insight (conf=0.72)
> The agent has a systematic inability to internalize corrections within the same execution context — prose style relapses immediately after flagging, dismissed data quality issues resurface as the same failure, and 'fixed' claims persist without re-execution — suggesting that correction acknowledgment and behavioral change are decoupled processes where the acknowledgment fires but the behavioral update does not propagate to the next generation step.

**Rule:** After any correction or self-flagged issue within a session, insert a mandatory pause-and-restate step before the next output: restate the specific constraint violated, then generate — never rely on the correction alone to alter the next output.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (152): 0c39a659, fb13ca88, f9f4c3b2, +149 more

---
### Insight (conf=0.72)
> The user has a consistent meta-preference for preserving the independence of parallel information streams: two plans stay as two plans (not merged), a dead agent's work is selectively triaged (not wholesale adopted), and comparisons stay as contrasts (not syntheses) — the agent's default toward convergence and unification actively destroys the informational diversity the user set up deliberately.

**Rule:** When handling multiple independently-produced outputs (plans, reviews, agent work), preserve their independence by default — merge, synthesize, or unify only when the user explicitly requests it, never as a 'helpful' default.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (7): dac333f4, 0c64e0da, 1a66d7a8, +4 more

---
### Insight (conf=0.70)
> Three failure modes share a common architectural gap: autonomous multi-agent and deployment sessions have no graceful degradation path when an external dependency (usage limits, credentials, orchestrator availability) fails mid-execution — the system design assumes continuous availability of all dependencies rather than building circuit-breakers, causing silent stalls instead of recoverable failures.

**Rule:** When designing any autonomous multi-step pipeline (deploy, multi-agent, scraping), always define the fallback behavior for each external dependency before starting execution — each dependency gets a timeout, a fallback action, and a notification path.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (105): f4686e13, efd2a3ab, e6c58221, +102 more

---
### Insight (conf=0.65)
> Across auth blocks, harness guards, and IPC obligations, the agent faces situations where the normal execution path is blocked by a system constraint — and in each case the correct behavior is not to work around the block but to use it as a structured handoff point (surface the command, return text to parent, reply before stopping), suggesting that blocks are communication channels, not obstacles.

**Rule:** When any system constraint blocks normal execution (auth, harness guard, IPC obligation), treat the block as a handoff signal: immediately produce the structured output the block implies (the command to run, the text to persist, the reply to send) rather than attempting workarounds or stalling.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "In multi-agent IPC sessions, unanswered peer queries must be replied to before the session ends; stop hooks will fire repeatedly for each un…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude, .claude, two-enhancement-product, better-file-browser, sys-monitor, its-my-config, frontend, staging-enhancement-product
- _Sessions_ (42): faeb2f37, efd2a3ab, ed1b2d1b, +39 more

---


## Wake Cycle — 2026-08-30 23:21 UTC

### Insight (conf=0.82)
> The agent treats each page/component/list as an isolated scope boundary even when the codebase proves the pattern is global — drawers, pagination, and shared components all fail the same way: fixing one instance while siblings diverge.

**Rule:** When implementing or fixing any UI pattern on one page, always grep for sibling pages using the same shell/layout/data-shape and apply the pattern uniformly before returning — per-page fixes to global patterns are architectural errors.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.80)
> False completion claims and incomplete verification share a single failure mode: the agent substitutes a cheaper proxy for the actual observation (type-check for runtime, dark-mode-only for both themes, edit-looks-right for running the server) and then uses completion language that implies the real thing was checked.

**Rule:** When claiming 'done' or 'verified', always name the exact verification performed and its scope — 'verified in dark mode only' or 'type-checked but not runtime-tested' — never use unqualified completion words when the check was partial.

**Evidence:**
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Projects_ (4): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (70): e3cbc32f, 302d5d15, 27238870, +67 more

---
### Insight (conf=0.75)
> Three separately-tracked communication failures share one root: the agent buries the actionable payload under structure, context-setting, or indirection — whether presenting deferred decisions without options, answering a direct question with a briefing, or giving a cryptic status update.

**Rule:** Always put the thing the reader must act on or decide in the first sentence — context, reasoning, and structure follow; if the first line is not actionable, rewrite.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude
- _Sessions_ (148): f4686e13, efd2a3ab, e6c58221, +145 more

---
### Insight (conf=0.72)
> The agent systematically confuses having produced an artifact about something with having verified the thing itself — a derivative doc becomes a spec, a gap table written without reading code becomes a status, a stated 'I read the output' becomes equivalent to acting on it.

**Rule:** Always distinguish 'I wrote/said X about Y' from 'I verified Y directly' — an agent-authored artifact is never evidence about the thing it describes; only the original source is.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (94): eb07961e, e3bde638, e01b73ba, +91 more

---
### Insight (conf=0.72)
> Three verification failures share the structure of checking against a convenient subset rather than the real population: filters tested against curated examples not real data, searches run with default ignores that skip real files, gap assessments made without reading actual source — the agent consistently verifies against the easy-to-reach inputs rather than the ones that matter.

**Rule:** When verifying any claim about completeness (filter coverage, file absence, implementation status), always verify against the actual population — convenient subsets, default tool scopes, and memory-based estimates systematically overstate coverage.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "When asserting that a file, route, or code path does not exist, the agent must run an ignore-transparent search (e.g., rg --no-ignore) befor…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (16): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp-contract, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260826-failure-report, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260823-v1-v2-plan, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude
- _Sessions_ (120): eb618fff, c71644cf, b449e2ee, +117 more

---
### Insight (conf=0.70)
> The user has a consistent meta-preference for keeping independent information streams separate until explicitly told to merge — deferred reviews stay queued, comparisons stay side-by-side, peer plans stay distinct — and the agent's instinct to synthesize/collapse is the recurring failure.

**Rule:** Always preserve the independence of parallel information streams (reviews, plans, agent outputs) until the user explicitly requests a merge or synthesis — collapsing distinct streams into one is a lossy operation that requires authorization.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, i-dream, .claude, studio_search_jul_26
- _Sessions_ (24): 9ed3de6d, 849b6ec8, 302d5d15, +21 more

---
### Insight (conf=0.70)
> Sub-agent lifecycle has exactly three failure points that map to a single discipline: verify the output exists (not just the notification), close the seat immediately after verification, and ignore pings from already-closed seats — missing any one leaves either phantom work or wasted tokens.

**Rule:** Always follow the sub-agent completion sequence in strict order: (1) verify output artifact on disk, (2) TaskStop the seat in the same turn, (3) dismiss any subsequent notifications from that seat — skipping any step causes resource leaks or phantom work.

**Evidence:**
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "After verifying a sub-agent's output file exists on disk, immediately TaskStop the seat in the same turn. An idle seat with a verified outpu…"
- _Pattern_: "Idle notifications arriving from sub-agents that have already been TaskStopped are stale and should be immediately dismissed without action …"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation--claude-output-20260830-2343-adversarial-review-plan, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, .claude, versable-builder, studio_search_jul_26-fable
- _Sessions_ (104): 0b097155, 0ab0035c, 049cca9c, +101 more

---
### Insight (conf=0.68)
> Three different mid-session blocking failures (subscription limits, orchestrator crashes, interactive auth prompts) share the same architectural gap: no autonomous recovery or graceful degradation path exists when an external dependency stalls, leaving work in an indeterminate state that requires manual human intervention to resume.

**Rule:** When designing any autonomous workflow, always define the fallback for each external dependency becoming unavailable mid-execution — checkpoint state, surface the block with the exact recovery command, and continue on unblocked work.

**Evidence:**
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (105): 0c39a659, ec7e7f48, d3e36a3a, +102 more

---
### Insight (conf=0.65)
> Sub-agent boundary failures (auth blocks, harness write-blocks, resource contention) are productive when treated as enforced handoff points rather than errors — the successful pattern in each case is surfacing the exact next step rather than attempting a workaround.

**Rule:** When a sub-agent hits any hard boundary (credential, permission, resource lock), always return the full findings so far plus the exact unblock command as a structured handoff — never attempt workarounds or stall.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Projects_ (6): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, versable-builder, walmart-mvp
- _Sessions_ (73): faeb2f37, efd2a3ab, ed1b2d1b, +70 more

---
### Insight (conf=0.62)
> Single corrections fail to clear ingrained defaults — whether prose style, task-list discipline, or terse-continuation protocol — because the agent treats each correction as a point fix rather than updating the generative prior that produces the behavior.

**Rule:** When corrected on a behavioral pattern that has recurred 3+ times, always pause to identify and restate the generative prior ('I default to X because Y') before attempting the fix — fixing the output without naming the prior guarantees recurrence.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The task list must be updated continuously during active editing work, not only at turn boundaries; when many edits happen without task upda…"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Projects_ (17): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-forge-v6, kanban, gcp, .claude, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (160): 0c39a659, fb13ca88, f9f4c3b2, +157 more

---


## Wake Cycle — 2026-08-31 01:25 UTC

### Insight (conf=0.88)
> The agent has a deep substitution failure where inspection (reading code, type-checking, collecting tests, scanning a gap table) is treated as equivalent to execution (running the dev server, exercising the path, reading actual source files) — three domains, one cognitive shortcut: 'I looked at it' replacing 'I ran it'.

**Rule:** Always distinguish between 'inspected' and 'executed' in any completion claim — if the claim is about runtime behavior, only execution counts; if about completeness, only reading source counts.

**Evidence:**
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (6): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude
- _Sessions_ (69): e3cbc32f, 302d5d15, 27238870, +66 more

---
### Insight (conf=0.88)
> The deferred-review preference and the missing-context-on-deferred-items pattern are in direct tension: the user wants items queued for later review (positive), but when those items are later presented, the agent strips the context needed to act on them (negative) — the deferral workflow is half-built, with the queue working but the recall broken.

**Rule:** Always attach the original decision context, concrete options, and any prior reasoning when surfacing a deferred item for review — a deferred item without its context is not actionable and defeats the purpose of the deferral queue.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Projects_ (9): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (67): 9ed3de6d, 849b6ec8, 302d5d15, +64 more

---
### Insight (conf=0.85)
> Task-list drift is not two patterns but one with two activation points: the list goes stale both when edits accumulate without updates AND when turns pass without reconciliation — the common cause is that the agent treats task updates as a reporting step rather than a continuous state-tracking obligation.

**Rule:** Always update the task list immediately after completing or discovering work, never batch task updates to turn boundaries or session end.

**Evidence:**
- _Pattern_: "When a task list goes many turns without updates while edits accumulate, it drifts into misleading state; the agent must reconcile completed…"
- _Pattern_: "The task list must be updated continuously during active editing work, not only at turn boundaries; when many edits happen without task upda…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-gcp, .claude, versable-builder, gcp, slack-automation, kanban
- _Sessions_ (115): f8de75f5, b92aba57, 97d1b64a, +112 more

---
### Insight (conf=0.82)
> The agent treats each file or page as a self-contained unit during implementation, failing to recognize when a change implies a codebase-wide contract — drawers, pagination, and shared components are all instances of 'a pattern proven elsewhere that must propagate', and the miss is always scoping the fix to the page in front of it rather than auditing siblings.

**Rule:** Always grep for sibling instances of the same UI pattern across the full app before implementing or fixing any shared component, pagination, or layout element on a single page.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.82)
> The agent systematically inverts the authority chain by treating its own derivatives as upstream specifications — whether it's an agent-authored schema doc used as the gap-audit source or agent-inferred UI labels used instead of design mocks, the defect is the same: the agent's formalization replaces the human's original, and downstream work inherits the agent's interpretation rather than the user's intent.

**Rule:** Always trace any specification claim back to its human-authored source before using it as a basis for gap analysis, UI implementation, or feature planning — if the source is agent-authored, it is a derivative and must be validated against the original.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc
- _Sessions_ (72): eb07961e, e3bde638, e01b73ba, +69 more

---
### Insight (conf=0.80)
> The user has a strong 'keep outputs distinct until I say merge' principle that spans both planning (two-agent peer review must stay separate) and comparison (side-by-side, not synthesis) — premature merging destroys the user's ability to exercise independent judgment, which is the entire point of requesting parallel outputs.

**Rule:** Always preserve the independence of parallel outputs until the user explicitly requests merging — comparison means contrast, not synthesis.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (7): dac333f4, 0c64e0da, 1a66d7a8, +4 more

---
### Insight (conf=0.80)
> Single-mode verification is a systematic blind spot that spans both UI review (dark-only testing) and artifact format (HTML without light/dark toggle) — the agent consistently delivers work that was validated in exactly one visual mode, and the user treats the missing mode as incompleteness rather than an edge case.

**Rule:** Always verify or deliver UI work in both light and dark modes before claiming completion — single-mode delivery is treated as incomplete, whether it's a review report or a shipped artifact.

**Evidence:**
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "Choosing an HTML artifact format over markdown when markdown would have sufficed is a format overshoot; when HTML is chosen for any output, …"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -
- _Sessions_ (64): faeb2f37, efd2a3ab, ed1b2d1b, +61 more

---
### Insight (conf=0.78)
> The agent's pre-delivery review is performative rather than adversarial: it notices anomalies (null coercion, out-of-scope items, suspicious values) during the review pass but classifies them as acceptable rather than blocking, producing a review that saw the defect and shipped it anyway — the review's own output becomes evidence against the reviewer.

**Rule:** Always treat any anomaly noticed during a pre-delivery review as a blocker until explicitly verified against the acceptance criteria — 'I noticed but dismissed' is the same failure as 'I did not notice'.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Projects_ (5): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (53): eb618fff, c71644cf, b449e2ee, +50 more

---
### Insight (conf=0.75)
> The multi-agent architecture has a cascade-failure pattern around session continuity: usage limits stall the orchestrator (leaving sub-agents blocked), subscription limits stall autonomous sessions (leaving work indeterminate), and interactive auth blocks deploy pipelines — all three are the same structural defect: a synchronous dependency on a resource that can vanish mid-session with no graceful degradation path.

**Rule:** Always design multi-agent and autonomous workflows with a self-report-on-idle mechanism and a timeout-based fallback for any synchronous dependency (auth, IPC, usage quota) that can fail mid-session.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (105): f4686e13, efd2a3ab, e6c58221, +102 more

---
### Insight (conf=0.72)
> The agent has a systematic failure to front-load the actionable payload in any communication — whether it's a deferred decision missing context, a cryptic status update, or a briefing that buries the answer, the structural defect is identical: the reader must do a second round-trip to extract what they needed from the first.

**Rule:** Always state the decision, status, or answer in the first sentence, then attach context — never present context that requires the reader to derive the actionable item themselves.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, versable-builder, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, claudebook, slack-automation, walmart-mvp
- _Sessions_ (148): f4686e13, efd2a3ab, e6c58221, +145 more

---
### Insight (conf=0.72)
> False absence claims and overestimated completeness are the same defect viewed from opposite ends: claiming a file doesn't exist because the search tool skipped it, and claiming a feature is built because the gap table wasn't grounded in source — both are confidence derived from the absence of contradicting evidence rather than the presence of confirming evidence.

**Rule:** Always treat 'I found no evidence against X' as weaker than 'I found evidence for X' — absence claims and completeness claims both require an affirmative read, not just a search that returned nothing.

**Evidence:**
- _Pattern_: "When asserting that a file, route, or code path does not exist, the agent must run an ignore-transparent search (e.g., rg --no-ignore) befor…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp-contract, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260826-failure-report, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260823-v1-v2-plan, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude
- _Sessions_ (67): f56866a0, f2d0df21, eda66bb8, +64 more

---
### Insight (conf=0.72)
> The user demands per-source transparency in data pipelines at both ends: when sources produce zero results (surface which endpoints were checked) and when sources are aggregated into filters (every active source must have a filter) — the underlying principle is that each data source is a first-class entity whose presence or absence in the output must be accountable.

**Rule:** Always make every data source individually accountable in pipeline output — zero-result sources get an explicit endpoint log, and aggregated views get per-source filters; no source should be invisible in the final surface.

**Evidence:**
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Projects_ (11): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, ig-download, .claude, versable-builder, walmart-mvp
- _Sessions_ (88): 4107d34c, 1da0f805, 1c6b90e5, +85 more

---


## Wake Cycle — 2026-08-31 03:30 UTC

### Insight (conf=0.82)
> The agent treats each file/page as a scoped unit of work even when the codebase proves the concern is global — shared UI shells, pagination patterns, and component fixes all exhibit the same 'fixed it here, didn't look there' failure where sibling instances of the same pattern are left broken.

**Rule:** Always grep for all instances of a pattern across the full project before implementing a fix or feature on any single instance — a fix applied to one page when siblings share the same component is incomplete by definition.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.78)
> The agent has a derivation-chain inversion problem: it generates derivative artifacts (concept docs from code, gap tables from memory, UI labels from internal naming) and then treats those derivatives as upstream authority — the same structural error whether it's citing its own formalization as a spec, estimating completion without reading source, or deriving UI labels from code conventions instead of design mocks.

**Rule:** Always trace any claim, label, or assessment back to its original human-authored source (design mock, product spec, actual source code) before using it — never cite an agent-generated derivative as the authority for a decision.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, i-dream, .claude, claude-ipc
- _Sessions_ (84): eb07961e, e3bde638, e01b73ba, +81 more

---
### Insight (conf=0.75)
> The agent has a systematic failure to front-load actionable context: whether presenting deferred decisions (missing prior context), status updates (structured briefing before the point), or terse replies (cryptic instead of direct), the underlying defect is burying the thing the user needs to act on behind structure the agent finds comfortable to produce.

**Rule:** Always state the decision or action the user must take in the first sentence, then attach context below it — never present context that requires the user to derive the action themselves.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, versable-builder, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, claudebook, slack-automation, walmart-mvp
- _Sessions_ (148): f4686e13, efd2a3ab, e6c58221, +145 more

---
### Insight (conf=0.74)
> The agent systematically under-exercises verification across all output modalities: runtime bugs declared fixed without running the dev server, UI reviews done in only one visual mode, and HTML artifacts missing the mandatory dark/light toggle are all instances where the agent verifies ONE state of a multi-state output and reports it as fully verified.

**Rule:** Always enumerate the states an output can be in (light/dark, loaded/empty, success/error) and verify each before declaring done — single-state verification of a multi-state output is incomplete verification.

**Evidence:**
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "Choosing an HTML artifact format over markdown when markdown would have sufficed is a format overshoot; when HTML is chosen for any output, …"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -
- _Sessions_ (67): e3cbc32f, 302d5d15, 27238870, +64 more

---
### Insight (conf=0.73)
> The user has a strong preference for preserving independent viewpoints and only merging on explicit instruction — peer review stays separate, plan comparisons stay side-by-side, dead agent work is selectively triaged not wholesale adopted — but the agent's default mode is synthesis and consolidation, which destroys the independence the user deliberately set up.

**Rule:** Always preserve independent outputs as separate artifacts until the user explicitly requests a merge — default to contrast and selective triage, never to automatic synthesis.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (7): dac333f4, 0c64e0da, 1a66d7a8, +4 more

---
### Insight (conf=0.72)
> Auth and credential boundaries are a recurring session-killer across three distinct surfaces (sub-agent credential blocks, deployment OAuth flows, subscription limits): each is a case where the agent encounters an external gate it cannot pass, and the failure mode is always the same — stalling or attempting workarounds instead of immediately surfacing the exact manual step needed and continuing other work.

**Rule:** When any external credential, auth, or subscription gate blocks progress, immediately surface the exact command the user must run, mark that task blocked, and continue all unblocked work — never stall the session or attempt workarounds on auth boundaries.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude
- _Sessions_ (72): faeb2f37, efd2a3ab, ed1b2d1b, +69 more

---
### Insight (conf=0.72)
> Completeness verification fails consistently across filtering, data sourcing, and file search: the agent checks SOME criteria or SOME sources and reports the result as complete — a filter that misses criteria, a multi-source aggregation missing a source filter, and a file search that skips gitignored paths are all the same defect of partial coverage reported as full coverage.

**Rule:** Before reporting any search, filter, or coverage result as complete, enumerate the full set of dimensions it should cover and verify each one individually — partial coverage reported as full is worse than reporting the gap.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "When asserting that a file, route, or code path does not exist, the agent must run an ignore-transparent search (e.g., rg --no-ignore) befor…"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp-contract, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260826-failure-report, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260823-v1-v2-plan, -Users-alcatraz627-Code-Versable-gcp
- _Sessions_ (153): eb618fff, c71644cf, b449e2ee, +150 more

---


## Wake Cycle — 2026-08-31 05:36 UTC

### Insight (conf=0.75)
> The agent treats each page/component as a local scope problem when the evidence that it belongs to a global pattern is already visible in the same session — shared UI shells, pagination patterns, and design mocks are all instances of 'the answer is already in your context but you scoped your attention too narrowly'.

**Rule:** Before implementing any UI element on a single page, always scan sibling pages in the same app for the same element type — if a pattern exists, adopt it; if mocks exist, consult them; treat per-page isolation as a code smell for globally-shared surfaces.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same session already display the paginated pattern, the agent should re…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, staging-enhancement-product, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, .claude
- _Sessions_ (148): ff8aef13, f95e5eb7, efd2a3ab, +145 more

---
### Insight (conf=0.73)
> The agent repeatedly confuses 'a signal was sent' with 'the effect was achieved' — IPC logs don't prove delivery, notifications don't prove file writes, and stale pings don't prove live work — suggesting a systematic bias toward trusting the sending side of any async handoff rather than verifying the receiving side.

**Rule:** Always verify async operations from the receiver's side (file exists on disk, peer replied, seat is actually active) rather than trusting the sender's log or notification; treat any send-side-only evidence as unverified.

**Evidence:**
- _Pattern_: "IPC message delivery should be confirmed by waiting for an actual round-trip reply from the peer, not by inspecting the sending agent's own …"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "Idle notifications arriving from sub-agents that have already been TaskStopped are stale and should be immediately dismissed without action …"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, .claude, two-enhancement-product, better-file-browser, sys-monitor, its-my-config, frontend, staging-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, versable-builder, studio_search_jul_26-fable
- _Sessions_ (74): 96490d11, 8c7e6f5c, 5f3a4812, +71 more

---
### Insight (conf=0.72)
> There is a recurring pattern of the agent treating its own derivative artifacts (formalized docs, gap tables, delivery reviews) as ground truth when they are actually unverified claims — the agent confuses having PRODUCED a summary with having VERIFIED the underlying state.

**Rule:** Avoid citing any agent-produced artifact as evidence of system state unless the artifact was generated by reading the actual source in the same turn; treat all agent-authored summaries as claims requiring re-verification before they inform decisions.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (94): eb07961e, e3bde638, e01b73ba, +91 more

---
### Insight (conf=0.70)
> The user has a strong 'preserve independence of perspectives' principle: comparisons stay side-by-side (not merged), peer reviews stay separate (not collapsed), and dead-agent work is selectively triaged (not wholesale adopted) — premature synthesis destroys the information the user is trying to extract from multiplicity.

**Rule:** Always preserve independent outputs as separate artifacts until the user explicitly requests a merge or synthesis; when incorporating work from multiple sources, default to selective triage over additive integration.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26
- _Sessions_ (7): dac333f4, c71644cf, b6809eaf, +4 more

---
### Insight (conf=0.70)
> False absence claims (file doesn't exist because search skipped gitignored paths) and false completeness claims (all filters present, all criteria enforced) share the same root: the agent's search/verification tool has a silent coverage gap, and the agent trusts its tool's silence as proof of absence rather than recognizing the gap.

**Rule:** When any search or filter returns zero results or 'all clear', always ask what the search could NOT have seen (gitignored files, unchecked sources, unenforced criteria) and name that gap explicitly before making an absence or completeness claim.

**Evidence:**
- _Pattern_: "When asserting that a file, route, or code path does not exist, the agent must run an ignore-transparent search (e.g., rg --no-ignore) befor…"
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp-contract, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260826-failure-report, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260823-v1-v2-plan, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (153): f56866a0, f2d0df21, eda66bb8, +150 more

---
### Insight (conf=0.68)
> When an agent hits an external boundary it cannot cross (auth wall, harness guard, subscription limit), the correct behavior is always the same shape: surface the exact blocker, hand off cleanly, and hold — but the failure modes differ by whether the agent silently stalls, attempts workarounds, or panics, suggesting the underlying skill is 'graceful boundary recognition' regardless of boundary type.

**Rule:** When any external boundary blocks progress (auth, guard, limit, resource lock), always surface the exact barrier and the user's recovery command in the same turn; never silently stall, retry without new information, or attempt workarounds that bypass the boundary's intent.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, it should surface the exact command the user needs to…"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.65)
> AI-smell prose and indirect/evasive communication are the same underlying failure — defaulting to a 'safe' register that performs competence rather than communicating directly — and single corrections don't clear it because the default register reasserts itself between conscious overrides.

**Rule:** Always write the first sentence of any reply as the direct answer in plain language; treat any draft whose opening paragraph could be deleted without losing the answer as a failure of the same class as AI-smell prose.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Projects_ (19): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude
- _Sessions_ (98): 0c39a659, fb13ca88, f9f4c3b2, +95 more

---
### Insight (conf=0.62)
> The user's deferred-review preference has a hidden precondition: deferred items must arrive pre-loaded with enough context (prior decisions, concrete options, product-level implications) to be actionable without re-deriving — deferral without context-packaging is just procrastination that shifts the cognitive load to the future review moment.

**Rule:** When deferring a decision or review item to a backlog, always attach the prior constraint, two concrete options, and the product-level implication; a deferred item without actionable context is an incomplete handoff, not a deferral.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "Deferred decision items presented to the user must include the exact prior decision or constraint and at least two concrete options to choos…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-enhancement-product-frontend
- _Sessions_ (107): 9ed3de6d, 849b6ec8, 302d5d15, +104 more

---
### Insight (conf=0.60)
> Shared-resource contention and idle-agent cleanup are two faces of the same lifecycle management gap: agents that hold resources too long block peers, and agents left alive after completion get commandeered — both are failures to close the loop on agent lifecycle at the moment the work is verified.

**Rule:** Always verify resource availability before dispatching a sub-agent that needs an exclusive resource, and always TaskStop a sub-agent in the same turn its output is verified; treat both the acquire and release as mandatory lifecycle steps, not optional cleanup.

**Evidence:**
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Pattern_: "When a multi-agent orchestration session hits its usage limit mid-coordination, sub-agents left waiting have no path to notify the orchestra…"
- _Pattern_: "After verifying a sub-agent's output file exists on disk, immediately TaskStop the seat in the same turn. An idle seat with a verified outpu…"
- _Projects_ (19): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation--claude-output-20260830-2343-adversarial-review-plan, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp
- _Sessions_ (144): df9392bb, 0c39a659, fdeb9ed4, +141 more

---
### Insight (conf=0.58)
> The agent underestimates audience bleed — GitHub comments reach teammates, documents reach stakeholders, HTML artifacts reach non-technical viewers — and the failures (missing attribution, banter in docs, missing dark mode) all stem from treating output as if it stays within the agent-user dyad when it actually crosses a visibility boundary.

**Rule:** Before finalizing any output artifact, always identify the widest plausible audience it could reach and verify it meets that audience's requirements (attribution for shared platforms, professional tone for stakeholder docs, accessibility for visual artifacts).

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "Choosing an HTML artifact format over markdown when markdown would have sufficed is a format overshoot; when HTML is chosen for any output, …"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627--claude-scripts-kanban, -
- _Sessions_ (74): a178d6c3, c8bc2450, baf2ac20, +71 more

---
### Insight (conf=0.55)
> The user's preference for deferred review creates a tension with the requirement for continuous task-list updates — both are about when status surfaces refresh, but one defers while the other demands immediacy, and the resolution is that STATUS must be live while JUDGMENT can be deferred.

**Rule:** Always update task status in real-time during edits, but defer qualitative review of completed items to a backlog unless the user explicitly requests immediate review.

**Evidence:**
- _Pattern_: "When a task list goes many turns without updates while edits accumulate, it drifts into misleading state; the agent must reconcile completed…"
- _Pattern_: "The task list must be updated continuously during active editing work, not only at turn boundaries; when many edits happen without task upda…"
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Projects_ (16): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-gcp, .claude, versable-builder, gcp, slack-automation, kanban, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude
- _Sessions_ (132): f8de75f5, b92aba57, 97d1b64a, +129 more

---


## Wake Cycle — 2026-09-02 05:38 UTC

### Insight (conf=0.82)
> A single failure mode — accepting a proxy signal instead of exercising against the real substrate — recurs across UI verification (dev server), gap audits (reading code), data pipelines (real dataset), and output review (actually reading rows), suggesting the agent has a systematic bias toward treating inspection-of-intent as equivalent to observation-of-outcome.

**Rule:** Always name the substrate (running app, source file, real dataset, actual output rows) and confirm you exercised against IT, not a summary or plan of it, before any completion or gap claim.

**Evidence:**
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (72): e3cbc32f, 302d5d15, 27238870, +69 more

---
### Insight (conf=0.78)
> Failure to check siblings before adding something is not just a UI problem — it manifests identically across component architecture (drawer per page), list patterns (pagination), JSX style (IIFE vs const), and data completeness (per-source filters), revealing a general tunnel-vision where the agent treats each insertion point as isolated rather than as a member of a set.

**Rule:** Before adding any element to a surface that already has peers (components, list pages, code patterns, filter dimensions), always enumerate the existing peers and verify the new addition conforms to or explicitly justifies diverging from their shared pattern.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same session already display the paginated pattern, the agent should re…"
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, staging-enhancement-product, versable-builder, -Users-alcatraz627-Documents-studio-search-jul-26-fable, walmart-mvp
- _Sessions_ (202): ff8aef13, f95e5eb7, efd2a3ab, +199 more

---
### Insight (conf=0.75)
> Verification of absence or completion through indirect signals (own logs for IPC delivery, idle notification for output existence, default search for file existence) is a recurring false-confidence pattern where the instrument does not measure the claim — the agent trusts what it can see locally over what actually happened remotely.

**Rule:** When verifying that something happened (message delivered, file written, path exists), always use the instrument that reads the destination state, not the source state; a send log, an idle signal, and a default-scope search are source-side instruments that cannot confirm destination-side reality.

**Evidence:**
- _Pattern_: "IPC message delivery should be confirmed by waiting for an actual round-trip reply from the peer, not by inspecting the sending agent's own …"
- _Pattern_: "When a sub-agent sends an idle notification, the agent should verify that the expected output file actually exists on disk before treating t…"
- _Pattern_: "When asserting that a file, route, or code path does not exist, the agent must run an ignore-transparent search (e.g., rg --no-ignore) befor…"
- _Projects_ (29): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, .claude, two-enhancement-product, better-file-browser, sys-monitor, its-my-config, frontend, staging-enhancement-product, -private-tmp-claude-501--Users-alcatraz627--claude-36607486-9e47-4460-bcbf-3531b96b8dcf-scratchpad-wake, -private-tmp-claude-501--Users-alcatraz627--claude-36607486-9e47-4460-bcbf-3531b96b8dcf-scratchpad-drill, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-forge-v6-src, -Users-alcatraz627-Code-Versable-versable-forge-v6--claude-output-20260825-page-review, -Users-alcatraz627-Code-Versable-versable-forge-v6, gcp, versable-forge-v6, slack-automation, kanban, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp-contract, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260826-failure-report, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260823-v1-v2-plan, -Users-alcatraz627-Code-Versable-gcp
- _Sessions_ (128): 96490d11, 8c7e6f5c, 5f3a4812, +125 more

---
### Insight (conf=0.72)
> The agent has a default-merge instinct that collapses independent sources into a single output even when the user explicitly requested preservation of independence — whether comparing two plans, running peer review, or triaging a dead agent's work — and this instinct must be actively suppressed whenever two or more sources are meant to remain distinguishable.

**Rule:** When handling multiple independent outputs (plans, reviews, agent artifacts), always default to preserving them as separate artifacts with explicit contrast; never merge unless the user uses the word 'merge', 'combine', or 'synthesize'.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26
- _Sessions_ (7): dac333f4, c71644cf, b6809eaf, +4 more

---
### Insight (conf=0.72)
> Authority contamination flows downstream in multi-agent pipelines: an agent-generated doc becomes the 'spec' for a gap audit, sibling-project findings leak into a scoped synthesis, and a producing agent's own checks miss constraint violations — all because the validating step inherits the producing step's frame rather than re-grounding against the upstream human-authored source.

**Rule:** When validating, auditing, or synthesizing across agent outputs, always re-ground against the human-authored upstream source document, never against a downstream agent-generated derivative; re-confirm scope boundaries at the write step, not just at dispatch.

**Evidence:**
- _Pattern_: "When conducting a gap audit against product requirements, the agent must use the user-authored upstream source document as authoritative, no…"
- _Pattern_: "When a multi-seat research fan-out completes, the synthesizing agent must re-confirm the target project scope before writing the final repor…"
- _Pattern_: "Validating another agent's output against standing project constraints (e.g. style rules, UI invariants) before merging or shipping catches …"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-local-models--claude-output-20260830-0159-deep-research-estate-audit, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation--claude-output-20260829-2251-deep-research-project-audit, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp, slack-automation, landing-app, gcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, claude-instances
- _Sessions_ (126): fef81fe8, f553b9c0, ec997359, +123 more

---
### Insight (conf=0.70)
> Autonomous execution paths that depend on an external gate (OAuth redirect, browser lock, credential prompt, real-dataset exercise) all fail through the same mechanism: the agent enters the blocking path optimistically and then has no recovery strategy, rather than probing for the gate's state before committing to the path.

**Rule:** Before entering any execution path that could block on an external gate (auth flow, shared resource lock, human credential, real-data availability), always probe the gate's current state first and have a named fallback; never commit to a blocking path optimistically.

**Evidence:**
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, it should surface the exact command the user needs to…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Projects_ (18): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, walmart-mvp, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, versable-builder
- _Sessions_ (147): 3818cca9, 0c39a659, ee9beb3c, +144 more

---
### Insight (conf=0.68)
> The user's preferred deferred-review workflow creates a tension with their demand for fully contextualized decision items — deferral is valued but only works when each deferred item is self-contained with prior context and options; deferral without context is experienced as incomplete handoff, meaning the cost of deferral must be paid at queue time, not review time.

**Rule:** When deferring any item to a review backlog, always include inline: the original constraint or decision, at least two concrete options, and enough context that the reviewer needs zero round-trips to act on it.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "Deferred decision items presented to the user must include the exact prior decision or constraint and at least two concrete options to choos…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (59): 9ed3de6d, 849b6ec8, 302d5d15, +56 more

---
### Insight (conf=0.65)
> Both AI-smell prose and task-list accuracy degrade over time within a session through the same mechanism: a correction resets the output momentarily but the generative default reasserts within a few turns, suggesting that single-point corrections do not durably alter in-context behavior and require periodic re-application or a structural constraint rather than a one-time fix.

**Rule:** When a correction is applied mid-session for a recurring pattern (prose style, task-list sync, or any behavioral drift), schedule a re-check every 10-15 tool calls rather than trusting the correction to persist; treat the corrected behavior as unstable until the session ends.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When a task list goes many turns without updates while edits accumulate, it drifts into misleading state; the agent must reconcile completed…"
- _Pattern_: "The task list must be updated continuously during active editing work, not only at turn boundaries; when many edits happen without task upda…"
- _Projects_ (18): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-gcp, .claude, gcp, kanban
- _Sessions_ (165): 0c39a659, fb13ca88, f9f4c3b2, +162 more

---
### Insight (conf=0.62)
> The user's autonomy preference is not a single setting but a two-axis policy: high autonomy on sequential reversible execution (never pause between obvious steps, never ask on terse continuation) but explicit confirmation on identity-level decisions (which repo visibility, product behavioral choices) — the agent fails by applying a single autonomy level across both axes.

**Rule:** Always proceed autonomously on reversible sequential execution steps and terse continuations; always pause and confirm on decisions that establish identity, product behavior, or externally-visible defaults, even when a global default exists.

**Evidence:**
- _Pattern_: "The user prefers the agent to complete all obvious sequential steps autonomously without checkpoint confirmations between them; asking for a…"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "Even when a global default (e.g. public repository visibility) is configured, the agent should ask about or confirm the preference when crea…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (18): -Users-alcatraz627-Code-local-models--claude-output-20260830-0159-deep-research-estate-audit, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation--claude-output-20260829-2251-deep-research-project-audit, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp, slack-automation, landing-app, gcp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (200): be257ec7, 7edb1ac4, 4522e558, +197 more

---


## Wake Cycle — 2026-09-02 07:50 UTC

### Insight (conf=0.82)
> The agent treats each file as a self-contained scope boundary, but the user's mental model is the application as a unified surface — drawers, pagination, and JSX idioms are expected to be consistent across all siblings, and per-file scoping is the root cause of inconsistency bugs that no single-file review catches.

**Rule:** Before implementing any UI pattern (component, list behavior, code idiom), always grep for 2-3 sibling instances of the same pattern across the application and match their approach, never scope the design decision to the current file alone.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same application already display a paginated pattern, the agent must ap…"
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (93): ff8aef13, f95e5eb7, efd2a3ab, +90 more

---
### Insight (conf=0.80)
> The agent's default output register is 'thorough briefing' but the user's preferred register is 'direct answer with nothing appended' — three distinct correction patterns (structured briefing before the point, cryptic indirection, unsolicited evaluative judgments) are all the same underlying failure: the agent treats completeness as a virtue when the user treats it as noise.

**Rule:** Always put the direct answer in the first sentence; append context only if the user's question structurally requires it — never append risk assessments, structured sections, or evaluative commentary to a factual or status answer.

**Evidence:**
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (21): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (126): 0c39a659, fb13ca88, f9f4c3b2, +123 more

---
### Insight (conf=0.78)
> Data pipeline verification shares a single failure mode with UI filter verification: the agent checks that the mechanism exists but never exercises it against real data that would expose its gaps — null coercion, zero-result sources, and out-of-scope items all pass because the verification was structural, not empirical.

**Rule:** Always exercise any filter, null-handler, or data pipeline against at least one real input known to contain the edge case it guards against — structural code review of the mechanism is never sufficient.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, ig-download, .claude
- _Sessions_ (92): eb618fff, c71644cf, b449e2ee, +89 more

---
### Insight (conf=0.77)
> False absence claims — 'this doesn't exist', 'this isn't built', 'this route is missing' — arise from three different search failures (gitignore-hidden files, unread source code, unread actual artifacts) but produce the same downstream damage: building duplicates, filing false gaps, or making wrong architectural claims, all of which erode trust faster than most bugs.

**Rule:** Before any absence claim ('does not exist', 'is not built', 'is missing'), always run an ignore-transparent search AND read the most likely source file — a false absence claim is more expensive than a false presence claim.

**Evidence:**
- _Pattern_: "When asserting that a file, route, or code path does not exist, the agent must run an ignore-transparent search (e.g., rg --no-ignore) befor…"
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp-contract, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260826-failure-report, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260823-v1-v2-plan, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (105): f56866a0, f2d0df21, eda66bb8, +102 more

---
### Insight (conf=0.75)
> State representations (task lists, gap tables, completion assessments) that are updated only at batch boundaries rather than continuously degrade into fiction; the failure mode is identical whether the state surface is a task tool, a gap audit, or a progress report — deferred reconciliation always overstates completeness.

**Rule:** Always reconcile any state-tracking surface (task list, gap table, completion claim) against actual artifacts after every 3-5 edits, never only at turn or phase boundaries.

**Evidence:**
- _Pattern_: "When a task list goes many turns without updates while edits accumulate, it drifts into misleading state; the agent must reconcile completed…"
- _Pattern_: "The task list must be updated continuously during active editing work, not only at turn boundaries; when many edits happen without task upda…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (16): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-gcp, .claude, versable-builder, gcp, slack-automation, kanban, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude
- _Sessions_ (132): f8de75f5, b92aba57, 97d1b64a, +129 more

---
### Insight (conf=0.74)
> Autonomous session fragility has a common shape: an external blocking event (OAuth redirect, credential prompt, API limit) interrupts an otherwise autonomous flow, and the agent either stalls silently or attempts workarounds instead of surfacing the exact unblock command — the correct response to any mid-flow human-gate is always 'here is the one command you need to run' plus a clean hold.

**Rule:** When any autonomous flow hits a human-gate (auth, credential, limit), always immediately surface the exact one-line unblock command and hold cleanly — never attempt workarounds and never stall silently.

**Evidence:**
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, it should surface the exact command the user needs to…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, walmart-mvp, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude
- _Sessions_ (105): 3818cca9, 0c39a659, ee9beb3c, +102 more

---
### Insight (conf=0.73)
> The agent systematically underestimates audience leakage: GitHub comments reach teammates, documents reach stakeholders, and anything posted under the user's identity is read as the user's voice — three distinct corrections all stem from the agent treating its output as private to the user-agent dyad when it is actually public-facing.

**Rule:** Before writing to any shared surface (GitHub, docs, external files), always ask: who besides the user will read this, and does the content hold up for that audience — apply attribution markers, strip internal commentary, and match the register to the actual reader.

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, .claude
- _Sessions_ (77): a178d6c3, c8bc2450, baf2ac20, +74 more

---
### Insight (conf=0.72)
> A single correction does not update the agent's generative prior — whether the domain is prose style, data validation, or bug verification, the agent 'acknowledges' the correction cognitively but the production pathway that caused the error remains unmodified, requiring multiple correction cycles to actually shift behavior.

**Rule:** After any user correction, always identify the generative step that produced the error and change the method at that step, not just the output — if the same tell reappears within 3 turns, escalate to a process change rather than another point fix.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (105): 0c39a659, fb13ca88, f9f4c3b2, +102 more

---
### Insight (conf=0.71)
> The user has a precise autonomy model with four distinct signals the agent frequently misreads: 'proceed' means go (not ask), 'defer' means permanent hold (not periodic re-raise), explicit permission means act (not wait), and sequential steps mean batch (not checkpoint) — all four are the same calibration error where the agent defaults to caution when the user has already spent the decision.

**Rule:** Always treat user autonomy signals as already-spent decisions: a terse continuation is a go, a deferral is a hold until lifted, explicit permission is immediate authority, and sequential obvious steps need no intermediate confirmation.

**Evidence:**
- _Pattern_: "The user prefers the agent to complete all obvious sequential steps autonomously without checkpoint confirmations between them; asking for a…"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "When the user explicitly grants permission to proceed autonomously on reversible work due to time pressure or personal constraints, the agen…"
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Projects_ (20): -Users-alcatraz627-Code-local-models--claude-output-20260830-0159-deep-research-estate-audit, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation--claude-output-20260829-2251-deep-research-project-audit, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp, slack-automation, landing-app, gcp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, .claude, studio_search_jul_26-fable
- _Sessions_ (125): be257ec7, 7edb1ac4, 4522e558, +122 more

---
### Insight (conf=0.70)
> The user operates with a strong separation between 'intake' and 'synthesis' phases — deferred review items, decision handoffs, and plan comparisons must all preserve their raw independent form until the user explicitly triggers a merge or resolution; premature synthesis destroys the optionality the user is deliberately maintaining.

**Rule:** Always preserve independent outputs in their original form until the user explicitly requests synthesis or merging — deferred items keep their full context, comparisons stay side-by-side, and review queues stay unbundled.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When presenting deferred decision items to the user, each item must include the exact prior decision or constraint and at least two concrete…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, i-dream, .claude
- _Sessions_ (73): 9ed3de6d, 849b6ec8, 302d5d15, +70 more

---
### Insight (conf=0.68)
> Sub-agent lifecycle management has three failure modes that form a single resource-contention cycle: stopped agents send stale pings (noise), idle agents get commandeered (scope leak), and new agents block on resources held by zombies (deadlock) — all stem from treating agent lifecycle as fire-and-forget rather than as explicit resource acquisition and release.

**Rule:** Always maintain an explicit agent registry per session: on dispatch record the agent ID and resource claims, on output verification immediately TaskStop and release claims, and before dispatching verify no zombie or idle agent holds the target resource.

**Evidence:**
- _Pattern_: "Idle notifications arriving from sub-agents that have already been TaskStopped are stale and should be immediately dismissed without action …"
- _Pattern_: "Idle sub-agents that have completed their scoped work must be stopped immediately after their output is verified; a seat left running can be…"
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Projects_ (17): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, .claude, versable-builder, studio_search_jul_26-fable, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation, local-models, speedway, slack-automation, landing-app, gcp, walmart-mvp
- _Sessions_ (129): b6cdefcf, 8db1413b, 857f9dd3, +126 more

---


## Wake Cycle — 2026-09-03 04:48 UTC

### Insight (conf=0.82)
> The agent treats each UI surface as a local problem, but the user's mental model is the product as a unified system — missing pagination on one page, a per-source filter gap, an IIFE where siblings use consts, and a drawer scoped to one page are all the same failure: implementing a component without first surveying the product-wide pattern it must conform to.

**Rule:** Before implementing any UI element that has a product-wide equivalent (list pagination, filter set, drawer, code style), always grep for and open at least two sibling instances and match their pattern before writing the first line.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same application already display a paginated pattern, the agent must ap…"
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Documents-studio-search-jul-26-fable, versable-builder, walmart-mvp
- _Sessions_ (144): ff8aef13, f95e5eb7, efd2a3ab, +141 more

---
### Insight (conf=0.78)
> There is a 'verification theater' meta-pattern: the agent performs an action shaped like verification (claims to have read output, checks an a11y snapshot, reviews code without running it) that satisfies the form of the rule but not its substance — the common failure is that the verification instrument does not measure the thing being claimed.

**Rule:** Before claiming any verification step is complete, name the specific instrument used and confirm it measures the actual property being claimed — 'I read the output' must specify what was read and what was found, not just that reading occurred.

**Evidence:**
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Projects_ (10): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, versable-builder, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -
- _Sessions_ (80): eb618fff, c71644cf, b449e2ee, +77 more

---
### Insight (conf=0.75)
> There is a recursive provenance-laundering failure: agent-generated artifacts (gap tables, formalization docs, structural claims) are treated as ground truth by the same or successor agents, compounding the original error — the common root is substituting a derived summary for the primary source.

**Rule:** When any assessment (gap analysis, completion audit, structural claim) cites an agent-generated document as evidence, always trace back to and re-read the primary source (user-authored spec, actual source file) before accepting the claim.

**Evidence:**
- _Pattern_: "When an agent has authored a downstream formalization document from a user-authored product spec, feature gap audits must be grounded in the…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download
- _Sessions_ (98): f9b3d568, f1fc3b91, eee8d695, +95 more

---
### Insight (conf=0.73)
> Data pipeline delivery has a consistent 'last mile' verification gap: filters that were never exercised against real data, null coercions dismissed as acceptable, and zero-result sources reported without diagnostic detail are all instances of the agent treating pipeline construction as complete without running a concrete sample through it end-to-end.

**Rule:** Before delivering any data pipeline output, always run at least one concrete sample row per source through the full pipeline and inspect the output cell-by-cell — construction is not delivery.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, ig-download, .claude
- _Sessions_ (92): eb618fff, c71644cf, b449e2ee, +89 more

---
### Insight (conf=0.72)
> Sub-agent lifecycle has a consistent failure mode at both ends: agents left alive after completion get commandeered or send stale pings, while agents assumed alive or assumed done without verification cause silent blocks — the missing primitive is a definitive state machine (dispatched → verified-output → stopped) with no implicit transitions.

**Rule:** Always transition sub-agents through exactly three explicit states: dispatched, output-verified-on-disk, and TaskStopped — never skip the middle step, and never leave an agent in any state longer than one turn after its work is consumed.

**Evidence:**
- _Pattern_: "Idle notifications arriving from sub-agents that have already been TaskStopped are stale and should be immediately dismissed without action …"
- _Pattern_: "Idle sub-agents that have completed their scoped work must be stopped immediately after their output is verified; a seat left running can be…"
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Pattern_: "When a sub-agent sends an idle notification, the agent should verify that the expected output file actually exists on disk before treating t…"
- _Projects_ (24): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, .claude, versable-builder, studio_search_jul_26-fable, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation, local-models, speedway, slack-automation, landing-app, gcp, walmart-mvp, -private-tmp-claude-501--Users-alcatraz627--claude-36607486-9e47-4460-bcbf-3531b96b8dcf-scratchpad-wake, -private-tmp-claude-501--Users-alcatraz627--claude-36607486-9e47-4460-bcbf-3531b96b8dcf-scratchpad-drill, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-forge-v6-src, -Users-alcatraz627-Code-Versable-versable-forge-v6--claude-output-20260825-page-review, versable-forge-v6, kanban
- _Sessions_ (188): b6cdefcf, 8db1413b, 857f9dd3, +185 more

---
### Insight (conf=0.70)
> The user's preferred failure mode for external blocks (auth flows, credential issues, subscription limits) is always the same shape: surface the exact unblocking command, hold position, never attempt workarounds — the agent consistently fails by trying to be clever around the block instead of cleanly handing off the one human action needed.

**Rule:** When hitting any external block (auth, credentials, rate limits, permissions), always emit the exact one-liner the user needs to run and explicitly hold — never attempt an alternative path unless the user directs one.

**Evidence:**
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, it should surface the exact command the user needs to…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, walmart-mvp, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude
- _Sessions_ (105): 3818cca9, 0c39a659, ee9beb3c, +102 more

---
### Insight (conf=0.68)
> The user's autonomy preferences form a consistent but non-obvious pattern: they want maximum forward momentum on execution (no checkpoint asks, terse continuation = go, complete all obvious steps) but maximum restraint on attention demands (defer reviews, never re-raise declined topics, batch decisions). The governing variable is not 'how much autonomy' but 'which direction does the action flow' — toward the work is autonomous, toward the user is gated.

**Rule:** Always bias toward autonomous execution for work that moves the task forward, but always bias toward restraint for anything that demands the user's attention — the two axes are independent, not a single autonomy dial.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "The user prefers the agent to complete all obvious sequential steps autonomously without checkpoint confirmations between them; asking for a…"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Projects_ (21): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-local-models--claude-output-20260830-0159-deep-research-estate-audit, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation--claude-output-20260829-2251-deep-research-project-audit, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp, slack-automation, landing-app, gcp, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, .claude, versable-builder, studio_search_jul_26-fable
- _Sessions_ (139): 9ed3de6d, 849b6ec8, 302d5d15, +136 more

---


## Wake Cycle — 2026-09-03 06:55 UTC

### Insight (conf=0.88)
> Task-list drift and continuous-update failures are the same defect at two granularities: one fires across turns (many turns without reconciliation), the other within turns (edits accumulate without status updates). Both stem from treating task updates as a reporting ceremony rather than a state-synchronization obligation.

**Rule:** Always update the task list within the same tool-call batch as the edit that changes a task's status — never defer task updates to a later 'reporting' step.

**Evidence:**
- _Pattern_: "When a task list goes many turns without updates while edits accumulate, it drifts into misleading state; the agent must reconcile completed…"
- _Pattern_: "The task list must be updated continuously during active editing work, not only at turn boundaries; when many edits happen without task upda…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-gcp, .claude, versable-builder, gcp, slack-automation, kanban
- _Sessions_ (115): f8de75f5, b92aba57, 97d1b64a, +112 more

---
### Insight (conf=0.85)
> False verification has three costumes — an a11y snapshot passed off as visual confirmation, a code edit passed off as a runtime fix, a default-scoped search passed off as an absence proof — but one cause: the agent substitutes a cheaper check for the expensive one and reports the expensive one's conclusion.

**Rule:** Always name the specific instrument used in any verification claim (screenshot, dev-server run, rg --no-ignore) — if the instrument is cheaper than what the claim requires, upgrade the instrument before making the claim.

**Evidence:**
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When asserting that a file, route, or code path does not exist, the agent must run an ignore-transparent search (e.g., rg --no-ignore) befor…"
- _Projects_ (13): -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp-contract, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260826-failure-report, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260823-v1-v2-plan, -Users-alcatraz627-Code-Versable-gcp
- _Sessions_ (77): 05bbfd53, 0093d8e9, b6fab009, +74 more

---
### Insight (conf=0.82)
> The agent repeatedly treats a local scope as sufficient when siblings define the real contract — whether it's a drawer component scoped to one page while it's globally shared, a list page missing pagination that all siblings have, or a JSX pattern that ignores surrounding conventions. The failure is scoping the read to the edit site rather than to the pattern's actual boundary.

**Rule:** Always identify the pattern boundary (all pages sharing a shell, all list pages, all sibling expressions) before writing code at any single site — the edit is scoped but the audit is not.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing standard pagination while sibling list pages already implement it, the agent leaves the gap uncorrected and wait…"
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (138): ff8aef13, f95e5eb7, efd2a3ab, +135 more

---
### Insight (conf=0.80)
> Filter/validation completeness failures across UI, data pipelines, and scraping share one shape: the agent builds the mechanism (filter UI, exclusion logic, null handler) for the cases it thought of and ships without enumerating the full input domain. The user's correction is always 'you missed source X / criterion Y / field Z' — the agent verified the mechanism works, not that it covers the domain.

**Rule:** Always enumerate the full input domain (all sources, all criteria, all nullable fields) as a checklist before implementing any filter or validation — verify coverage of the domain, not just correctness of the mechanism.

**Evidence:**
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Projects_ (6): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (103): df9392bb, 0c39a659, fdeb9ed4, +100 more

---
### Insight (conf=0.78)
> A recurring meta-failure: the agent trusts its own downstream artifacts (agent-generated docs, agent-scoped synthesis, agent-held mental models) as authoritative when only the upstream source (user-authored spec, target project scope, actual source files) carries ground truth. The agent's derivative becomes a lens that distorts the original.

**Rule:** Always re-read the original upstream source (user spec, source file, project scope definition) at the verification step — never treat an agent-generated derivative as the authoritative reference for completeness or correctness claims.

**Evidence:**
- _Pattern_: "When an agent has authored a downstream formalization document from a user-authored product spec, feature gap audits must be grounded in the…"
- _Pattern_: "When a multi-seat research fan-out completes, the synthesizing agent must re-confirm the target project scope before writing the final repor…"
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Projects_ (27): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, versable-builder, -Users-alcatraz627-Code-local-models--claude-output-20260830-0159-deep-research-estate-audit, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation--claude-output-20260829-2251-deep-research-project-audit, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp, slack-automation, landing-app, gcp, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download
- _Sessions_ (136): f9b3d568, f1fc3b91, eee8d695, +133 more

---
### Insight (conf=0.75)
> Sub-agent lifecycle mismanagement follows one pattern: the agent treats dispatch as the hard problem and ignores the lifecycle tail — leaving seats running invites commandeering, failing to verify output assumes completion, and failing to check resource locks assumes availability. The common defect is modeling agents as functions (call and forget) rather than as stateful processes.

**Rule:** Always treat a sub-agent dispatch as opening a resource lease: verify the resource is free before dispatch, verify the output artifact exists after idle signal, and TaskStop the seat immediately after verification — never leave a completed agent running.

**Evidence:**
- _Pattern_: "Idle notifications arriving from sub-agents that have already been TaskStopped are stale and should be immediately dismissed without action …"
- _Pattern_: "Idle sub-agents that have completed their scoped work must be stopped immediately after their output is verified; a seat left running can be…"
- _Pattern_: "Dispatching a sub-agent with 'exclusive use' of a browser MCP resource without first verifying no other session or agent currently holds it …"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Projects_ (21): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, .claude, versable-builder, studio_search_jul_26-fable, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation, local-models, speedway, slack-automation, landing-app, gcp, walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban
- _Sessions_ (166): b6cdefcf, 8db1413b, 857f9dd3, +163 more

---
### Insight (conf=0.74)
> Partial-state verification is a temporal cousin of false verification: the agent checks one artifact (output file exists, zero-count noted, copy text fixed) and reports the containing operation as complete, when the unchecked remainder (file contents, which endpoints were tried, title and padding) carries the actual failure.

**Rule:** Always verify the full state of the containing element after any sub-fix — existence is not completeness, and fixing one property of an object is not fixing the object.

**Evidence:**
- _Pattern_: "When a sub-agent sends an idle notification, the agent should verify that the expected output file actually exists on disk before treating t…"
- _Pattern_: "When a scraping or data pipeline produces zero results for a specific source, the agent should proactively surface which pages or endpoints …"
- _Pattern_: "Claiming a specific UI sub-issue is fixed without verifying the full rendered state of the containing element leads to adjacent problems sur…"
- _Projects_ (22): -private-tmp-claude-501--Users-alcatraz627--claude-36607486-9e47-4460-bcbf-3531b96b8dcf-scratchpad-wake, -private-tmp-claude-501--Users-alcatraz627--claude-36607486-9e47-4460-bcbf-3531b96b8dcf-scratchpad-drill, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-forge-v6-src, -Users-alcatraz627-Code-Versable-versable-forge-v6--claude-output-20260825-page-review, -Users-alcatraz627-Code-Versable-versable-forge-v6, gcp, versable-forge-v6, slack-automation, kanban, .claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, ig-download, i-dream, versable-builder, claude-ipc
- _Sessions_ (153): a7be7634, ed154b56, ed080e96, +150 more

---
### Insight (conf=0.73)
> The user's multi-agent review philosophy is structurally adversarial: independent production, independent grading, side-by-side contrast, constraint validation before merge. The agent's instinct to synthesize, merge, and harmonize actively destroys the information the user wants — the delta between independent outputs IS the signal.

**Rule:** Always preserve independent outputs as separate artifacts through comparison and validation stages — never merge or synthesize multi-agent outputs until the user explicitly requests a merge as a distinct step.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "Validating another agent's output against standing project constraints (e.g. style rules, UI invariants) before merging or shipping catches …"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, claude-instances
- _Sessions_ (33): dac333f4, 0c64e0da, 1a66d7a8, +30 more

---
### Insight (conf=0.72)
> Correction-resistant behaviors share a common root: the agent treats acknowledgment of a defect as equivalent to fixing it — 'I noticed X' substitutes for 'I changed X' whether the surface is prose style, data review, or runtime verification.

**Rule:** Always produce a measurable delta (a rewritten sentence, a changed value, a passing run) before claiming a correction landed — acknowledging the pattern is not the correction.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable
- _Sessions_ (105): 0c39a659, fb13ca88, f9f4c3b2, +102 more

---
### Insight (conf=0.70)
> Three distinct user corrections (structured briefing before answer, cryptic/indirect replies, unsolicited safety verdicts) are all instances of the agent inserting its own frame before delivering what was asked — the defect is not verbosity or brevity but frame-priority: the agent's framing arrives before the user's answer.

**Rule:** Always emit the direct answer to the user's question as the first clause of the reply — any framing, context, or caveats follow it, never precede it.

**Evidence:**
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (21): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (126): 0c39a659, fb13ca88, f9f4c3b2, +123 more

---
### Insight (conf=0.68)
> When an autonomous flow hits a human-requiring gate (OAuth redirect, credential entry, subscription limit), the agent's failure mode bifurcates: either it stalls silently or it attempts workarounds. The correct response — surface the exact unblocking action and hold — is the one it least often chooses, because it requires admitting the flow cannot proceed autonomously.

**Rule:** Always surface a blocked autonomous flow within one turn of hitting the gate, stating the exact command the user must run — never stall silently and never attempt credential workarounds.

**Evidence:**
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Pattern_: "A sub-agent that hits a credential or auth block outside its own scope should surface the exact unblocking command the user needs to run and…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Projects_ (11): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, walmart-mvp, -Users-alcatraz627-Code-Claude-claude-ipc, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude
- _Sessions_ (75): 3818cca9, 0c39a659, ee9beb3c, +72 more

---


## Wake Cycle — 2026-09-03 08:59 UTC

### Insight (conf=0.82)
> The agent consistently fails to enforce completeness across a set — filters miss criteria, source-specific options are omitted, pagination is skipped on some pages, and drawer components diverge per-page — all because it validates each element in isolation rather than checking coverage across the full enumeration of siblings or criteria.

**Rule:** Always enumerate the full set (all filter criteria, all data sources, all sibling pages, all surfaces sharing a component) and verify coverage across every member before declaring a multi-element feature complete.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "When a filtering UI is built over data aggregated from multiple heterogeneous sources, omitting a per-source filter for any actively-scraped…"
- _Pattern_: "When a list page is missing standard pagination while sibling list pages already implement it, the agent leaves the gap uncorrected and wait…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Projects_ (18): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (191): eb618fff, c71644cf, b449e2ee, +188 more

---
### Insight (conf=0.78)
> The agent treats state-tracking artifacts (task lists, sub-agent lifecycles) as write-once declarations rather than live instruments — tasks drift without updates, stopped agents still trigger responses, and idle agents accumulate cost, all because the agent models status as a label applied at creation rather than a value that must be continuously reconciled with reality.

**Rule:** Always reconcile every live state surface (task list, agent roster, resource locks) against observed reality before acting on or reporting from it — a status set N turns ago is a hypothesis, not a fact.

**Evidence:**
- _Pattern_: "When a task list goes many turns without updates while edits accumulate, it drifts into misleading state; the agent must reconcile completed…"
- _Pattern_: "The task list must be updated continuously during active editing work, not only at turn boundaries; when many edits happen without task upda…"
- _Pattern_: "Idle notifications arriving from sub-agents that have already been TaskStopped are stale and should be immediately dismissed without action …"
- _Pattern_: "Idle sub-agents that have completed their scoped work must be stopped immediately after their output is verified; a seat left running can be…"
- _Projects_ (20): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-gcp, .claude, versable-builder, gcp, slack-automation, kanban, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, studio_search_jul_26-fable, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-speedway, local-models, speedway, landing-app
- _Sessions_ (193): f8de75f5, b92aba57, 97d1b64a, +190 more

---
### Insight (conf=0.75)
> The agent's communication failures share a single root: it optimizes for demonstrating thoroughness rather than transferring the one thing the reader needs — whether that means burying a status answer under structure, appending unrequested risk assessments, being cryptic instead of direct, or omitting decision context that would prevent a round-trip.

**Rule:** Always write the reader's next action as the first sentence; everything that follows is evidence for that action, never a demonstration of the work that produced it.

**Evidence:**
- _Pattern_: "When the agent's reply is cryptic or indirect rather than stating the point first, the user experiences it as a communication failure and ca…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Pattern_: "When presenting deferred decision items to the user, each item must include the exact prior decision context that triggered the deferral and…"
- _Projects_ (21): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-src, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui-docs, -Users-alcatraz627-Code-Versable-versable-builder-docs-design-language, -Users-alcatraz627-Code-Versable-versable-builder--claude-output-20260812-ui-knowledge-plan, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, versable-builder, ig-download, studio_search_jul_26-fable, staging-enhancement-product, .claude, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (146): de69ccb7, a57ee61f, 9d2dc6a5, +143 more

---
### Insight (conf=0.74)
> The agent repeatedly treats signals-about-artifacts as equivalent to the artifacts themselves — an idle notification treated as proof of output, a default search treated as proof of absence, a structural intuition treated as proof of code state — all instances of mistaking a proxy for the thing it proxies.

**Rule:** Always verify the artifact itself (read the file, run the search with --no-ignore, read the source) rather than trusting any indirect signal (notification, default search, prior knowledge) as proof of its state.

**Evidence:**
- _Pattern_: "When a sub-agent sends an idle notification, the agent should verify that the expected output file actually exists on disk before treating t…"
- _Pattern_: "When asserting that a file, route, or code path does not exist, the agent must run an ignore-transparent search (e.g., rg --no-ignore) befor…"
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Projects_ (23): -private-tmp-claude-501--Users-alcatraz627--claude-36607486-9e47-4460-bcbf-3531b96b8dcf-scratchpad-wake, -private-tmp-claude-501--Users-alcatraz627--claude-36607486-9e47-4460-bcbf-3531b96b8dcf-scratchpad-drill, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-forge-v6-src, -Users-alcatraz627-Code-Versable-versable-forge-v6--claude-output-20260825-page-review, -Users-alcatraz627-Code-Versable-versable-forge-v6, gcp, versable-forge-v6, slack-automation, kanban, .claude, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-silica-runner, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp-contract, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260826-failure-report, -Users-alcatraz627-Code-Versable-gcp--claude-output-20260823-v1-v2-plan, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude
- _Sessions_ (146): a7be7634, ed154b56, ed080e96, +143 more

---
### Insight (conf=0.72)
> The agent has a systematic blindness to its own output quality — it cannot reliably self-correct prose style (AI-smell persists after correction), cannot act on data quality issues it claims to have noticed, and cannot distinguish between having checked a surface and having actually seen it; all three are instances of the agent's self-assessment being decorative rather than functional.

**Rule:** Always route self-assessment of output quality (prose style, data review, visual verification) to a fresh sub-agent or mechanical check rather than relying on the producing agent's own re-read, because the producer's self-review is structurally unreliable.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Projects_ (15): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -
- _Sessions_ (126): 0c39a659, fb13ca88, f9f4c3b2, +123 more

---
### Insight (conf=0.70)
> Three user preferences describe a single attention-management contract: completed non-critical items go to a deferred backlog (not surfaced immediately), deferred topics stay deferred until the user lifts them, and obvious sequential steps proceed without checkpoint confirmations — the user treats their own attention as a scarce resource and penalizes the agent for spending it on things the user has already deprioritized or pre-authorized.

**Rule:** Avoid surfacing, re-raising, or checkpointing on any item the user has deferred, deprioritized, or pre-authorized unless new information materially changes its status.

**Evidence:**
- _Pattern_: "The user prefers completed non-critical items to be added to a deferred 'to be reviewed' backlog rather than surfaced for immediate review. …"
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Pattern_: "The user prefers the agent to complete all obvious sequential steps autonomously without checkpoint confirmations between them; asking for a…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, .claude, studio_search_jul_26-fable, -Users-alcatraz627-Code-local-models--claude-output-20260830-0159-deep-research-estate-audit, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-forge-v6, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation--claude-output-20260829-2251-deep-research-project-audit, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-gcp, slack-automation, landing-app, gcp
- _Sessions_ (75): e3cbc32f, 302d5d15, 27238870, +72 more

---
