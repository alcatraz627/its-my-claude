# Dream Insights

_High-confidence associations promoted by the Wake phase._

## Wake Cycle — 2026-07-29 02:38 UTC

### Insight (conf=0.82)
> The agent consistently verifies at the point of action (sent the message, wrote the code, dispatched the agent) rather than at the point of reception (message arrived, UI renders, file exists on disk) — a systematic send-side-verification bias that manifests identically across IPC, UI, and artifact domains.

**Rule:** Always verify at the reception point (rendered page, round-trip reply, file on disk) rather than at the action point (code written, message sent, agent dispatched) before claiming completion.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (111): dfd19dc0, 96490d11, 895cfd88, +108 more

---
### Insight (conf=0.78)
> The agent treats each touchpoint as a scoped fix rather than recognizing it as an instance of a pattern already established in the codebase — missing pagination that siblings already have, patching one callsite of a global component, fixing one sub-issue while adjacent ones survive — all are the same failure to zoom out from the immediate edit to the pattern it belongs to.

**Rule:** When fixing or implementing any UI element, always search for sibling instances of the same pattern in the codebase and apply the fix uniformly — a scoped patch to one instance of a global pattern is incomplete by definition.

**Evidence:**
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Pattern_: "Claiming a specific UI sub-issue is fixed without verifying the full rendered state of the containing element leads to adjacent problems sur…"
- _Projects_ (9): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, .claude, i-dream, versable-builder, claude-ipc
- _Sessions_ (120): efd2a3ab, 95f1a846, 003ab6d4, +117 more

---
### Insight (conf=0.75)
> The agent has a nearest-authority fallacy: it derives decisions from the closest available context (the current page's code, internal naming conventions, its own previously-generated docs) rather than seeking the actual authoritative source (all pages sharing the component, design mocks, user-authored specs) — each is the same substitution of proximity for authority in a different domain.

**Rule:** When deriving any structural or naming decision, always identify and consult the upstream authority (design mocks, user-authored spec, all consuming pages) before the nearest available source — proximity is not authority.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, .claude, versable-builder
- _Sessions_ (114): ff8aef13, f95e5eb7, efd2a3ab, +111 more

---
### Insight (conf=0.73)
> The agent systematically draws the boundary between 'implementation detail' and 'product decision' too broadly — choosing UI labels from code conventions, resolving behavioral ambiguities as implementation choices, and writing banner copy in agent-register are all cases where a product-level decision was treated as a neutral technical one, and each required user intervention to correct.

**Rule:** When a choice affects what the user sees (labels, copy, behavioral permissions, flow names), always treat it as a product decision requiring either design-mock consultation or explicit user input — never resolve it from code conventions or internal naming.

**Evidence:**
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "User-facing UI banner copy written in formal, structured agent-style language ('This job has not started — it needs its setup.') reads as AI…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, versable-builder
- _Sessions_ (146): fef81fe8, f553b9c0, ec997359, +143 more

---
### Insight (conf=0.72)
> The user's preferred deferral workflow is systematically sabotaged by the agent's context-stripping during communication — the agent defers items (as requested) but strips the decision context, full paths, and tradeoffs that would make deferred items actionable, forcing reconstruction round-trips that negate the efficiency gains of deferral.

**Rule:** When deferring an item to a backlog or presenting a previously-deferred decision, always include the original decision context, concrete options with tradeoffs, and full file paths — a deferred item without its context is a follow-up question disguised as progress.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "When asking the user a decision question, include enough background and tradeoffs to make the question self-contained and answerable without…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, .claude, two-enhancement-product, better-file-browser, sys-monitor, its-my-config, frontend, staging-enhancement-product
- _Sessions_ (90): f4686e13, efd2a3ab, e6c58221, +87 more

---
### Insight (conf=0.70)
> Multi-agent coordination degrades along a temporal axis: initial coordination works but fails under session discontinuity (orchestrator dies leaving blocked sub-agents, context-cleared sessions lose peer aliases, parallel agents don't pre-negotiate ownership) — the system is designed for happy-path single-session operation and has no graceful degradation for the interruptions that actually occur.

**Rule:** When designing multi-agent coordination, always build the session-death and context-loss recovery path first (idle-state self-reporting, checkpoint peer aliases, pre-negotiated ownership boundaries) — the interruption case is the common case, not the edge case.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "In a multi-agent setup where sessions are regularly context-cleared, each agent's checkpoint should record the peer agent's IPC alias so the…"
- _Pattern_: "When multiple agents work in parallel on the same codebase, they must pre-negotiate task ownership via IPC before starting work; overlapping…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, .claude
- _Sessions_ (69): f4686e13, efd2a3ab, e6c58221, +66 more

---


## Wake Cycle — 2026-07-29 04:43 UTC

### Insight (conf=0.82)
> The agent systematically treats proxy signals (send confirmation, type-check pass, task notification, doc summary) as proof of ground truth (message received, code works, file written, code actually built), revealing a deep tendency to trust metadata over observation across every domain.

**Rule:** Always distinguish the proxy signal from the ground-truth check before claiming a result — name both explicitly, then run the ground-truth one.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (123): dfd19dc0, 96490d11, 895cfd88, +120 more

---
### Insight (conf=0.78)
> The user's stated breadth-first preference is systematically violated by the agent's depth-first instinct to fix the instance in front of it — the same structural conflict drives both the 'patch one page' UI failures and the 'perfect one area mid-sweep' prioritization complaints.

**Rule:** Always enumerate all sibling instances of a fix before applying it to any single one — apply breadth-first across the class, then return for depth.

**Evidence:**
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (122): d8f1948c, a0f35401, 8c7e6f5c, +119 more

---
### Insight (conf=0.75)
> The agent confuses two orthogonal autonomy axes: it pauses for permission on execution (where the user wants speed) while silently resolving product decisions (where the user wants to be consulted), consistently inverting which axis deserves autonomy and which deserves a halt.

**Rule:** Avoid pausing on execution mechanics unless genuinely blocked; always surface product-level behavioral decisions as explicit questions — autonomy applies to the how, not the what.

**Evidence:**
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When the user explicitly grants permission to proceed autonomously on reversible work due to time pressure or personal constraints, the agen…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (128): 5d07ffa1, 5b904ac8, 5774c57d, +125 more

---
### Insight (conf=0.72)
> The user's preference for deferred review workflows directly amplifies the context-loss-at-resurfacing failure: deferral creates more handoff boundaries, and the agent consistently strips decision context at those boundaries, so the preferred workflow is the one most vulnerable to the agent's weakest skill.

**Rule:** Always attach the original decision context, concrete options, and tradeoffs to any item being deferred — the deferral payload must be self-contained enough to act on without follow-up.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When asking the user a decision question, include enough background and tradeoffs to make the question self-contained and answerable without…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, .claude, two-enhancement-product, better-file-browser, sys-monitor, its-my-config, frontend, staging-enhancement-product
- _Sessions_ (86): 9ed3de6d, 849b6ec8, 302d5d15, +83 more

---
### Insight (conf=0.68)
> Content migrating across an audience boundary without transformation is a single failure mode with three faces: agent-authored docs treated as upstream specs (internal→authoritative), private banter leaking into external docs (conversational→published), and agent-register language in user-facing UI (machine→human) — in each case the content's origin context was not stripped at the boundary crossing.

**Rule:** Always identify the target audience before writing content that crosses a boundary (internal→external, agent→user-facing, conversational→published) and strip origin-context markers, voice, and authority claims that belong only on the source side.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "User-facing UI banner copy written in formal, structured agent-style language ('This job has not started — it needs its setup.') reads as AI…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, i-dream, claude-ipc
- _Sessions_ (98): eb07961e, e3bde638, e01b73ba, +95 more

---
### Insight (conf=0.62)
> Multi-agent architectures fail at exactly two boundaries — session death (orchestrator hits limit, sub-agents stranded) and session birth (new session can't find peers) — and the working pattern in both cases is the same: the agent that hits the boundary must leave a self-contained handoff artifact (idle self-report, peer alias in checkpoint, exact command for user) rather than assuming continuity.

**Rule:** Always write a self-contained recovery artifact at every session boundary in multi-agent work — assume the next reader has zero prior context and no live connection to peers.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "In a multi-agent setup where sessions are regularly context-cleared, each agent's checkpoint should record the peer agent's IPC alias so the…"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, .claude
- _Sessions_ (85): f4686e13, efd2a3ab, e6c58221, +82 more

---


## Wake Cycle — 2026-07-30 12:35 UTC

### Insight (conf=0.82)
> The agent systematically conflates producing an output with that output having its intended effect — sending a message equals delivery, writing code equals working, editing a file equals fixing the bug — a single 'producer-side confidence' bias that manifests identically across IPC verification, UI bug fixes, and feature completion claims.

**Rule:** Always verify at the CONSUMER side (the recipient, the browser, the rendered page, the downstream system) before claiming an action succeeded — never treat the producer's success signal as proof of effect.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Pattern_: "Shipping code and reporting a visual feature as complete without rendering and viewing the actual target state (not just green tests) produc…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, versable-builder, i-dream, claude-ipc
- _Sessions_ (133): dfd19dc0, 96490d11, 895cfd88, +130 more

---
### Insight (conf=0.80)
> The user's mental model of work is system-level and breadth-first (sweep all surfaces, then deepen), but the agent's default is component-level and depth-first (fix this one instance well) — every 'you only fixed this page' or 'you only applied this pattern here' complaint is the same mismatch between the user's unit-of-work (the system) and the agent's (the file).

**Rule:** When fixing a pattern on one page or applying a convention to one artifact, always search for sibling instances of the same pattern across the system and apply uniformly in the same pass — the user's unit of work is the system, not the component.

**Evidence:**
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (122): d8f1948c, a0f35401, 8c7e6f5c, +119 more

---
### Insight (conf=0.75)
> The user's preferred deferred-review workflow is actively sabotaged by the agent's pattern of stripping decision context from deferred items — the user wants deferral but the agent's implementation of deferral produces items that are unactionable without a follow-up question, defeating the purpose of the workflow.

**Rule:** When deferring an item to a review backlog, always include the original decision context, the concrete options considered, and what information the user will need to act on it — a deferred item without its context is a future interruption, not a deferral.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Projects_ (9): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (67): 9ed3de6d, 849b6ec8, 302d5d15, +64 more

---
### Insight (conf=0.72)
> Both failures share a 'known-case-only coverage' structure — the access gate defaults to ALLOW for unrecognized commands and the policy fix only patches the specific known violation — leaving the boundary of unknown/future cases systematically unprotected, which is exactly where the next failure will occur.

**Rule:** When building a gate, guard, or policy fix, always define the behavior for the UNKNOWN case first (default-deny, default-flag) — a fix that only covers enumerated known cases is a patch that expires on the next novel input.

**Evidence:**
- _Pattern_: "When building an access-gate system, unrecognized commands must default to DENY, not ALLOW; a default-allow fallback for unknown CLIs create…"
- _Pattern_: "Patching a specific instance of a policy violation (e.g., adding one CLI to a fallback list) without fixing the underlying class of problem …"
- _Projects_ (9): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627, frontend, enhancement-product, .claude, local-models
- _Sessions_ (16): fc013b76, a0f35401, 6b120b0a, +13 more

---
### Insight (conf=0.70)
> Sub-agents encounter hard boundaries (auth blocks, harness guards, orchestrator death) that are structurally identical — an external constraint prevents the agent from completing its task — and the correct behavior in all three is the same graceful-degradation pattern: surface the block explicitly and hand off to whoever can resolve it, rather than working around it or stalling.

**Rule:** When a sub-agent hits any external constraint it cannot resolve (auth, permission, harness guard, orchestrator unavailable), immediately surface the exact blocker and the exact action needed to unblock, then yield — never attempt workarounds or wait silently.

**Evidence:**
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Projects_ (7): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627
- _Sessions_ (71): b1692904, 840b272f, 400171d5, +68 more

---
### Insight (conf=0.68)
> The user wants maximum autonomy on execution mechanics but explicit surfacing on product-level decisions, yet the agent cannot reliably distinguish the two — causing both false pauses (asking permission for obvious next steps) and silent product commitments (resolving 'can a user add files to an existing job' as an implementation detail), which are experienced as opposite failures of the same classification problem.

**Rule:** When deciding whether to pause or proceed autonomously, classify the decision as execution-mechanical (proceed) or product-behavioral (surface) — the test is whether a different answer would change what the end user sees or can do, not whether it changes the code.

**Evidence:**
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (126): 5d07ffa1, 5b904ac8, 5774c57d, +123 more

---
### Insight (conf=0.65)
> The agent consistently fails to model the downstream consumer of its output — writing banner copy for itself instead of the end user, leaving conversational banter in stakeholder docs, and deriving UI labels from internal naming instead of design mocks — all because it optimizes for the immediate context (the chat, the codebase) rather than the final audience (the user, the stakeholder, the customer).

**Rule:** Before writing any content that will be seen by someone other than the immediate chat participant (UI copy, external docs, banner text), explicitly name the final reader and write for THEM — the codebase and the conversation are inputs, not the audience.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "User-facing UI banner copy written in formal, structured agent-style language ('This job has not started — it needs its setup.') reads as AI…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, i-dream, versable-builder, claude-ipc, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries
- _Sessions_ (117): d8f1948c, a0f35401, 8c7e6f5c, +114 more

---


## Wake Cycle — 2026-08-04 17:21 UTC

### Insight (conf=0.80)
> The agent exhibits a 'first-instance generalization' shortcut that is structurally identical across UI architecture (one page for all pages), feature consistency (one list page for all list pages), visual modes (dark for dark+light), and sub-component state (one property for the full element) — it checks one instance, declares the class covered, and stops, which is a reasoning pattern rather than a domain-specific miss.

**Rule:** After verifying or fixing one instance of a class (one page, one mode, one sub-property), always enumerate the full set of instances in the same class and explicitly state which were checked and which were not — never let a single instance stand for the class.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "Claiming a specific UI sub-issue is fixed without verifying the full rendered state of the containing element leads to adjacent problems sur…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, .claude, versable-builder
- _Sessions_ (157): ff8aef13, f95e5eb7, efd2a3ab, +154 more

---
### Insight (conf=0.75)
> The user's preferred deferred-review workflow is systematically undermined by the agent's own deferral mechanism: the user wants items queued for later action, but the agent strips the decision context needed to act on them, creating deferred items that are formally present but practically unactionable — the deferral and the context-stripping are two faces of the same handoff failure.

**Rule:** When deferring any item to a backlog or review queue, always include the original decision context (what was being decided, what the concrete options were, and what information was available at deferral time) — a deferred item without its context is a question the user has to re-derive.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When the user asks for a tracking artifact for their own reference, provide a human-facing doc they can independently consult, explicitly se…"
- _Projects_ (9): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (71): 9ed3de6d, 849b6ec8, 302d5d15, +68 more

---
### Insight (conf=0.72)
> The agent has a systematic 'production-as-proof' bias: it treats the act of producing output (sending a message, writing a diff, emitting a notification) as evidence of the output's effect (message received, bug fixed, file written), which is an epistemological error that recurs identically across IPC, code verification, and artifact persistence.

**Rule:** Always verify at the CONSUMER end, never at the PRODUCER end — a successful send, edit, or notification proves nothing about what the receiver experienced; name the consumer-side evidence before claiming success.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, versable-builder
- _Sessions_ (111): dfd19dc0, 96490d11, 895cfd88, +108 more

---
### Insight (conf=0.68)
> The agent has a tendency to invert derivation chains: it treats its own outputs (formalized docs, internal naming conventions, default values) as authoritative sources in place of the upstream human-authored truth (product specs, design mocks, actual data), creating a closed loop where agent-generated artifacts validate themselves.

**Rule:** Before using any document, naming convention, or value as an authoritative source, trace its provenance — if it was generated by the agent or derived from code rather than authored by a human stakeholder, it is a derivative and must not be cited as the upstream authority.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "Silent zero-defaults in data extraction (e.g. `bb.get('x', 0)`) fabricate plausible-looking numeric values when source data is missing or pa…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-its-my-config, -Users-alcatraz627-Code-Claude-ghostty-themes, -Users-alcatraz627-Code-Claude-data-forge, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-i-dream, -Users-alcatraz627, sys-monitor
- _Sessions_ (100): eb07961e, e3bde638, e01b73ba, +97 more

---
### Insight (conf=0.65)
> Content appropriate for one audience systematically leaks into outputs for another: internal banter into external docs, agent reasoning into UI copy, evaluative judgments into factual answers — suggesting the agent does not maintain a firm boundary between its internal processing register and the output register appropriate to each surface.

**Rule:** Before finalizing any output, name its audience explicitly (external stakeholder, end-user UI, factual Q&A, internal agent note) and strip anything that belongs to a different audience's register — conversational banter, agent-style formality, unsolicited verdicts.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When writing a document that will be shared externally, all internal banter, critique, and conversational framing about stakeholders must be…"
- _Pattern_: "User-facing UI banner copy written in formal, structured agent-style language ('This job has not started — it needs its setup.') reads as AI…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, two-enhancement-product, better-file-browser, sys-monitor, its-my-config, staging-enhancement-product, i-dream, versable-builder, claude-ipc, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (111): d8f1948c, a0f35401, 8c7e6f5c, +108 more

---


## Wake Cycle — 2026-08-06 15:11 UTC

### Insight (conf=0.95)
> There is a single underlying failure mode — treating code-level correctness (diff looks right, types check) as equivalent to runtime correctness — that manifests across at least 7 independent observations, suggesting the agent's verification instinct terminates one step too early by default.

**Rule:** Always open the running app and visually confirm the changed surface before using any completion word (done, fixed, works, verified, passing) for UI or runtime changes — code-level inspection is necessary but never sufficient.

**Evidence:**
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Pattern_: "When the agent announces a UI or runtime fix and the user tests it on the actual running app, discovering it still fails, the agent had clai…"
- _Pattern_: "Claiming a specific UI sub-issue is fixed without verifying the full rendered state of the containing element leads to adjacent problems sur…"
- _Pattern_: "Declaring implementation work done without verifying on the actual running dev server leads to issues (wrong labels still showing, removed p…"
- _Pattern_: "Claiming UI fixes are done without exercising the actual rendered page leads to multiple issues surviving — UI work is only verified when th…"
- _Pattern_: "Shipping code and reporting a visual feature as complete without rendering and viewing the actual target state (not just green tests) produc…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, .claude, i-dream, claude-ipc, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (210): e3cbc32f, 302d5d15, 27238870, +207 more

---
### Insight (conf=0.92)
> The agent treats each page/surface as an isolated unit even when the codebase already proves the pattern is shared — a 'scope = the file I'm in' heuristic that systematically misses cross-page consistency obligations.

**Rule:** Always grep for sibling instances of a component, pattern, or page-level feature across the full app before implementing or fixing it on a single page — if the pattern already exists elsewhere, replicate it everywhere in the same change.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.88)
> The agent confuses its own generated artifacts with upstream authority — both gap assessments without reading code and citing agent-authored docs as specs are instances of treating a derivative as a source, inflating confidence in ungrounded claims.

**Rule:** Always trace any document or assessment back to its upstream source (user-authored spec, actual source code, real runtime state) before using it as authority in a gap analysis, review, or planning decision — agent-generated artifacts are derivatives, never sources of truth.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (6): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude
- _Sessions_ (41): eb07961e, e3bde638, e01b73ba, +38 more

---
### Insight (conf=0.88)
> The agent has a gravitational pull toward synthesis/merging that must be actively resisted — both the two-agent peer-review workflow and plan comparison require keeping outputs separate, but the agent's default is to collapse distinct perspectives into one.

**Rule:** Always preserve the independence of separately-produced outputs (plans, reviews, analyses) until the user explicitly requests a merge — collapsing distinct perspectives into a synthesis is a separate operation that requires its own authorization.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (7): dac333f4, 0c64e0da, 1a66d7a8, +4 more

---
### Insight (conf=0.85)
> Across IPC verification, sub-agent output, and orchestrator failure, the same pattern recurs: the agent trusts send-side or notification-side signals as proof of end-to-end completion, when only the receiving end's state is evidence — a distributed-systems 'fire and forget' anti-pattern applied to agent coordination.

**Rule:** Always verify the receiver's state (file exists, reply received, agent alive) before treating any inter-agent communication as successful — send-side confirmation and notifications are necessary but not sufficient proof of delivery or completion.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style
- _Sessions_ (105): dfd19dc0, 96490d11, 895cfd88, +102 more

---
### Insight (conf=0.85)
> Three patterns converge on the same autonomy-calibration failure: the agent defaults to 'pause and ask' when the user has already signaled 'keep going' — terse continuations, autonomous-work grants, and multi-agent go-aheads are all forms of the same permission that the agent under-respects.

**Rule:** Always treat terse continuations, explicit autonomy grants, and sequential go-aheads as standing permission to proceed without further confirmation until a genuine decision point or blocking dependency is reached.

**Evidence:**
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When the user explicitly grants permission to proceed autonomously on reversible work due to time pressure or personal constraints, the agen…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, versable-builder
- _Sessions_ (79): 5d07ffa1, 5b904ac8, 5774c57d, +76 more

---
### Insight (conf=0.82)
> The deferred-review workflow the user prefers is undermined by the agent's habit of omitting decision context when surfacing deferred items — deferral without context creates a second round-trip that defeats the purpose of batching.

**Rule:** Always include the original decision context, concrete options, and any prior reasoning when presenting a deferred item for review — a deferred item without context is not actionable and forces a follow-up the user considers wasted.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Projects_ (9): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (67): f4686e13, efd2a3ab, e6c58221, +64 more

---
### Insight (conf=0.82)
> The agent skips mandatory pre-work gates (design mocks, verification checklists, adversarial validation phases) not because it doesn't know they exist, but because its completion drive outweighs its gate-checking discipline — a temporal degradation where the urge to finish overwhelms procedural obligations.

**Rule:** Always check for and execute mandatory gate phases (design mocks, verification checklists, adversarial validation) before any implementation or completion claim — the completion instinct is the enemy of gate discipline.

**Evidence:**
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "When a project-specific UI verification checklist is available, the agent must run it during any browser verification pass — skipping a cont…"
- _Pattern_: "When a skill invocation has a documented mandatory gate phase (e.g., adversarial validation), silently skipping it and marking tasks complet…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, versable-builder
- _Sessions_ (129): f9b3d568, f1fc3b91, eee8d695, +126 more

---
### Insight (conf=0.80)
> The agent fails to model the document's downstream audience — internal banter leaks into external docs, and agent-register prose appears in user-facing copy — because it writes for the conversation partner (the user) rather than the document's actual reader (stakeholders, end users).

**Rule:** Always identify the document's end reader (not the conversation partner) before writing, and strip any content that only makes sense in the agent-user conversation context — conversational register and internal commentary are invisible to the author but glaring to the downstream reader.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When writing a document that will be shared externally, all internal banter, critique, and conversational framing about stakeholders must be…"
- _Pattern_: "User-facing UI banner copy written in formal, structured agent-style language ('This job has not started — it needs its setup.') reads as AI…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, two-enhancement-product, better-file-browser, sys-monitor, its-my-config, staging-enhancement-product, i-dream, versable-builder, claude-ipc
- _Sessions_ (88): d8f1948c, a0f35401, 8c7e6f5c, +85 more

---
### Insight (conf=0.78)
> Partial-state verification (one theme mode, one sub-element of a component) produces findings the user rejects as incomplete — the agent's verification coverage matches its attention span, not the surface's actual state space.

**Rule:** Always enumerate the full state space of a UI surface (theme modes, open/closed variants, edge cases) before reporting verification results, and annotate which states were actually observed versus inferred.

**Evidence:**
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "Claiming a specific UI sub-issue is fixed without verifying the full rendered state of the containing element leads to adjacent problems sur…"
- _Projects_ (7): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, .claude, i-dream, versable-builder, claude-ipc
- _Sessions_ (71): faeb2f37, efd2a3ab, ed1b2d1b, +68 more

---
### Insight (conf=0.75)
> Both access gates and validation gates share the same structural vulnerability: the agent builds the happy path and treats the unknown/unrecognized case as safe-to-skip rather than safe-to-deny — a default-allow bias that undermines the gate's entire purpose.

**Rule:** Always default unrecognized inputs and unexecuted gate phases to DENY/FAIL — a gate that passes by default on unknown cases is not a gate.

**Evidence:**
- _Pattern_: "When building an access-gate system, unrecognized commands must default to DENY, not ALLOW; a default-allow fallback for unknown CLIs create…"
- _Pattern_: "When a skill invocation has a documented mandatory gate phase (e.g., adversarial validation), silently skipping it and marking tasks complet…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627, frontend, enhancement-product, .claude, local-models, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, i-dream
- _Sessions_ (52): fc013b76, a0f35401, 6b120b0a, +49 more

---


## Wake Cycle — 2026-08-07 03:41 UTC

### Insight (conf=0.92)
> Per-page isolation blindness is a single architectural failure: the agent treats the file it's editing as the scope boundary instead of auditing all siblings that share the same component/pattern, whether it's a drawer, pagination, or a global shell fix — the miss is always 'fixed one instance, left N broken'.

**Rule:** Always grep for all consumers/siblings of a shared UI pattern before writing any fix, and include all instances in the same change.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.88)
> The agent has a merging reflex that collapses independent outputs into a single synthesis — whether it's two agent plans that should stay separate for grading or two documents that should be contrasted side-by-side — violating the user's explicit intent to keep them distinct for comparison.

**Rule:** Never merge independently-produced outputs unless the user explicitly requests a merge; default to side-by-side presentation when multiple outputs exist.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (7): dac333f4, 0c64e0da, 1a66d7a8, +4 more

---
### Insight (conf=0.88)
> Agent-generated documents become self-referential oracles: a formalization derived from code gets treated as the spec, and a gap assessment written without reading code gets treated as ground truth — both are the same derivation-chain inversion where the agent's summary replaces the source it summarized.

**Rule:** Always trace any cited document back to its original source before using it as authority — if the document was agent-derived, cite the upstream source directly instead.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (6): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude
- _Sessions_ (41): eb07961e, e3bde638, e01b73ba, +38 more

---
### Insight (conf=0.87)
> Partial-state verification is a temporal degradation pattern: the agent verifies one dimension of a multi-dimensional surface (one sub-issue, one visual mode, one checklist) and reports complete — verification effort decays to the minimum that produces a 'done' signal rather than covering the full state space.

**Rule:** Always enumerate all dimensions of a verification surface (visual modes, sub-issues, checklist items) before starting verification, and track coverage explicitly — never report done until all dimensions are checked.

**Evidence:**
- _Pattern_: "Claiming a specific UI sub-issue is fixed without verifying the full rendered state of the containing element leads to adjacent problems sur…"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "When a project-specific UI verification checklist is available, the agent must run it during any browser verification pass — skipping a cont…"
- _Projects_ (7): -Users-alcatraz627-Code-Versable-versable-builder, .claude, i-dream, versable-builder, claude-ipc, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (71): ff780782, fb3008e7, fa1dc4a5, +68 more

---
### Insight (conf=0.85)
> Send-side confidence is a cross-domain antipattern: in IPC the agent trusts its own send log, in sub-agent flows it trusts the completion notification, and in harness-blocked writes it trusts the intent — all three fail because the agent verifies the action from the sender's perspective instead of confirming the artifact at the receiver's end.

**Rule:** Always verify delivery from the receiver's side — check the file exists, the peer replied, or the artifact landed — never trust send-side telemetry or notifications as proof of completion.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (64): dfd19dc0, 96490d11, 895cfd88, +61 more

---
### Insight (conf=0.85)
> The agent defaults to its own internal naming conventions and formal register for user-facing surfaces — whether it's UI labels derived from code identifiers instead of design mocks, or banner copy written in structured agent-speak instead of natural human phrasing — both are the same failure to consult the external human-facing source before writing.

**Rule:** Always consult external human-facing references (design mocks, brand voice, existing copy) before writing any user-visible text — never derive UI copy from internal naming or agent-natural phrasing.

**Evidence:**
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "User-facing UI banner copy written in formal, structured agent-style language ('This job has not started — it needs its setup.') reads as AI…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, versable-builder
- _Sessions_ (98): f9b3d568, f1fc3b91, eee8d695, +95 more

---
### Insight (conf=0.83)
> The agent fails to model document audience boundaries: conversational banter leaks into external docs, safety warnings append to factual answers, and internal critique appears in shareable artifacts — all are failures to enforce a clean separation between the conversational register and the output register based on who will actually read it.

**Rule:** Always identify the final audience of any output before writing it, and strip all content that belongs to a different audience layer — conversational remarks never enter external docs, evaluative judgments never append to factual answers.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When writing a document that will be shared externally, all internal banter, critique, and conversational framing about stakeholders must be…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, two-enhancement-product, better-file-browser, sys-monitor, its-my-config, staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (62): d8f1948c, a0f35401, 8c7e6f5c, +59 more

---
### Insight (conf=0.82)
> The agent treats deferred decisions and embedded product decisions the same way: it resolves them silently without surfacing the decision context, whether the item was explicitly parked for later review or implicitly embedded in implementation — both rob the user of the information they need to act.

**Rule:** Always present deferred or embedded decisions with their original context, concrete options, and the prior reasoning — never surface a decision point as a bare label the user must re-derive.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (8): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (100): f4686e13, efd2a3ab, e6c58221, +97 more

---
### Insight (conf=0.80)
> The agent's autonomy calibration is inverted: it pauses for permission on terse continuations and short-distance progress (where the user wants speed), but proceeds silently on product decisions and scope expansions (where the user wants a gate) — the pause/proceed threshold is misaligned with actual decision stakes.

**Rule:** Avoid pausing on terse continuations or sequential reversible work; always pause on product-level decisions, scope expansions, and irreversible actions — calibrate autonomy to decision stakes, not to message length.

**Evidence:**
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When the user explicitly grants permission to proceed autonomously on reversible work due to time pressure or personal constraints, the agen…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, versable-builder
- _Sessions_ (79): 5d07ffa1, 5b904ac8, 5774c57d, +76 more

---
### Insight (conf=0.78)
> Multi-agent coordination failures share a single structural gap: no agent owns the meta-state of the fleet — whether it's a blocked sub-agent that can't self-report, parallel agents that don't pre-negotiate ownership, or a cleared session that loses its peer's alias — the architecture assumes a coordinator that doesn't exist or doesn't survive context boundaries.

**Rule:** Always persist multi-agent fleet state (peer aliases, task ownership, blocked/idle status) to a shared artifact that survives context clears, and designate an explicit coordinator responsible for re-establishing contact on resume.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "When multiple agents work in parallel on the same codebase, they must pre-negotiate task ownership via IPC before starting work; overlapping…"
- _Pattern_: "In a multi-agent setup where sessions are regularly context-cleared, each agent's checkpoint should record the peer agent's IPC alias so the…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, .claude
- _Sessions_ (69): f4686e13, efd2a3ab, e6c58221, +66 more

---


## Wake Cycle — 2026-08-08 10:24 UTC

### Insight (conf=0.88)
> The agent's default unit of work is the immediate callsite, not the class of affected surfaces — it fixes the thing in front of it and mentally closes the task, even when the same pattern provably recurs on sibling pages/filters/components it could find with a single grep.

**Rule:** When fixing a pattern-level issue (a missing pagination, a broken drawer, an unenforced filter criterion), always grep for all instances of the same pattern across the codebase and fix the class before reporting done — a single-site fix on a multi-site pattern is an incomplete fix.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (156): ff8aef13, f95e5eb7, efd2a3ab, +153 more

---
### Insight (conf=0.82)
> The agent systematically confuses emission with effect — 'I sent it' equals 'it arrived', 'I edited it' equals 'it works', 'I dispatched it' equals 'it wrote the file' — a single cognitive shortcut where completing the action on the agent's side is treated as proof of the outcome on the receiving side.

**Rule:** Always verify at the RECEIVER's boundary (the running app, the peer's inbox, the disk artifact) before claiming an action succeeded — completion of the send/edit/dispatch step is never evidence of the outcome.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (111): dfd19dc0, 96490d11, 895cfd88, +108 more

---
### Insight (conf=0.78)
> The agent treats its own artifacts (summaries, derivative docs, 'I read through it' claims) as equivalent to the upstream source — creating a self-referential loop where the agent's paraphrase of reality replaces reality, and subsequent reasoning operates on the copy instead of the original.

**Rule:** Never use an agent-produced summary, derivative document, or self-reported reading as the authority for a decision — always trace back to the original source (the spec, the actual output rows, the running app) before acting on derived claims.

**Evidence:**
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (10): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude
- _Sessions_ (94): eb618fff, c71644cf, b449e2ee, +91 more

---
### Insight (conf=0.75)
> The deferred-review workflow the user prefers is undermined by the agent's tendency to strip decision context from deferred items — deferral without context creates a queue of unopenable items, making the workflow the user explicitly wants structurally broken.

**Rule:** When deferring an item to a review backlog, always embed the original decision context, concrete options, and any prior reasoning inline — a deferred item without actionable context is not deferred, it is lost.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Projects_ (9): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (67): 9ed3de6d, 849b6ec8, 302d5d15, +64 more

---
### Insight (conf=0.72)
> The agent writes for its own processing convenience rather than the human recipient's — omitting paths (the agent knows the file), omitting decision context (the agent just processed it), using formal structured language (the agent's native register) — all are failures to model what the READER lacks.

**Rule:** Before sending any output to the user, mentally discard your own context and ask what the reader needs to act without a follow-up question — full paths, decision options with context, and natural human phrasing are not extras, they are the output.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "User-facing UI banner copy written in formal, structured agent-style language ('This job has not started — it needs its setup.') reads as AI…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, .claude, i-dream, versable-builder, claude-ipc
- _Sessions_ (108): f4686e13, efd2a3ab, e6c58221, +105 more

---
### Insight (conf=0.70)
> Multi-agent coordination degrades across three compounding layers — ownership isn't negotiated (edit conflicts), the coordinator can die mid-flight (orphaned agents), and even when coordination is attempted the transport silently corrupts messages (shell quoting) — each layer independently causes failure, and all three are present simultaneously.

**Rule:** When designing a multi-agent workflow, defend all three coordination layers in the same plan: ownership pre-negotiation (who touches what), supervisor liveness (sub-agents self-report idle and can be re-queued), and transport verification (round-trip reply, not send-side log).

**Evidence:**
- _Pattern_: "When multiple agents work in parallel on the same codebase, they must pre-negotiate task ownership via IPC before starting work; overlapping…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "When sending IPC replies from a shell command, backticks and special characters in the message body get consumed by the shell and produce ze…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (69): d8f1948c, a0f35401, 8c7e6f5c, +66 more

---
### Insight (conf=0.68)
> The agent has a strong merge-bias that collapses distinct outputs into a single synthesized view, even when the user's workflow depends on keeping them separate — peer reviews, plan comparisons, and selective triage all require maintaining boundaries between inputs, and premature synthesis destroys the signal the user needs.

**Rule:** When handling multiple independent outputs (peer reviews, competing plans, dead-agent artifacts), preserve them as separate items by default — merge or synthesize only when the user explicitly requests it, since the independence IS the value.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (7): dac333f4, 0c64e0da, 1a66d7a8, +4 more

---
### Insight (conf=0.65)
> Available verification artifacts (design mocks, project checklists, mandatory gate phases) are skipped more often under task momentum than when explicitly prompted — the pattern is not 'doesn't know the artifact exists' but 'knows it exists and bypasses it to maintain forward progress', a temporal degradation where urgency overrides process.

**Rule:** When a verification artifact exists for the surface being changed (design mock, project checklist, gate phase), consult it BEFORE writing any code — never after, and never 'if time permits' — treating known verification gates as optional under momentum is the specific failure mode.

**Evidence:**
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "When a project-specific UI verification checklist is available, the agent must run it during any browser verification pass — skipping a cont…"
- _Pattern_: "When a skill invocation has a documented mandatory gate phase (e.g., adversarial validation), silently skipping it and marking tasks complet…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, versable-builder
- _Sessions_ (129): f9b3d568, f1fc3b91, eee8d695, +126 more

---
### Insight (conf=0.62)
> The agent fails to distinguish between internal working context and externally-visible output across multiple surfaces — embedding product decisions silently (should be surfaced), leaking conversational banter into docs (should be stripped), and publishing stakeholder commentary (should be private) are all boundary violations where the agent's processing context bleeds into the user's output context.

**Rule:** Before finalizing any output that leaves the agent's working context (a doc, a UI label, a product decision), explicitly audit what is internal-processing-context versus user/external-facing content — the boundary between 'what I considered' and 'what gets published' must be a conscious gate, not implicit.

**Evidence:**
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When writing a document that will be shared externally, all internal banter, critique, and conversational framing about stakeholders must be…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, two-enhancement-product, better-file-browser, sys-monitor, its-my-config, staging-enhancement-product
- _Sessions_ (84): fef81fe8, f553b9c0, ec997359, +81 more

---
### Insight (conf=0.55)
> The user's preferred breadth-first sweep workflow creates a structural tension with verification requirements — breadth-first means many surfaces change before any is verified, and verification depth (both modes, real app, checklist) scales multiplicatively with breadth, so verification is the phase most likely to be shortcut under the sweep's momentum.

**Rule:** When running a breadth-first v1 sweep, explicitly scope each surface's verification claim to what was actually checked ('v1 laid, dark-only visual pass') rather than claiming 'done' — breadth-first is a priority strategy, not a verification shortcut.

**Evidence:**
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, versable-builder, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (39): d8f1948c, a0f35401, 8c7e6f5c, +36 more

---


## Wake Cycle — 2026-08-08 12:31 UTC

### Insight (conf=0.82)
> The agent systematically confuses action-side evidence (I sent/edited/read) with outcome-side evidence (it arrived/works/is correct), and this single cognitive shortcut manifests identically across IPC delivery, UI bug fixes, data pipeline review, and completion claims.

**Rule:** Always name the OUTCOME artifact (round-trip reply, rendered state, acted-on finding, pass/fail line) before claiming success — never cite the ACTION artifact (send log, diff applied, 'I noticed X', code edited) as proof.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, versable-builder, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (132): dfd19dc0, 96490d11, 895cfd88, +129 more

---
### Insight (conf=0.72)
> The user treats independent perspectives as an information resource that premature synthesis destroys — two-agent peer review, side-by-side comparison, and selective triage of a dead agent's work all demand that the agent preserve separation until the user explicitly authorizes merging, because the user's review process requires seeing divergence, not consensus.

**Rule:** Always preserve independent outputs as separate artifacts until the user explicitly requests a merge — presenting pre-synthesized consensus eliminates the divergence signal the user's review workflow depends on.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26
- _Sessions_ (7): dac333f4, c71644cf, b6809eaf, +4 more

---
### Insight (conf=0.70)
> The agent miscalibrates its autonomy gradient in both directions along the SAME axis: it over-pauses on execution signals (terse continuations, explicit autonomy grants) where the user wants speed, and under-pauses on product-level decisions where the user wants a gate — it confuses 'execution autonomy' (proceed without asking HOW) with 'decision autonomy' (proceed without asking WHETHER).

**Rule:** Always distinguish execution questions (how to proceed — autonomous by default, especially on terse continuations) from product questions (whether to proceed with a behavioral choice — always surface to user) — terse continuation grants execution autonomy, never decision autonomy.

**Evidence:**
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When the user explicitly grants permission to proceed autonomously on reversible work due to time pressure or personal constraints, the agen…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (128): 5d07ffa1, 5b904ac8, 5774c57d, +125 more

---
### Insight (conf=0.68)
> The agent applies known UI techniques (skeleton loaders, IIFEs, internal naming conventions for labels) by pattern-matching the technique's keyword rather than auditing whether the specific site meets the technique's precondition — the failure is context-blind technique application, not ignorance of the technique.

**Rule:** Before applying a UI pattern (skeleton, wrapper, naming convention), verify the precondition that makes it appropriate at THIS site — static content has no async fetch to skeleton, siblings use inline props not IIFEs, and design mocks override internal naming.

**Evidence:**
- _Pattern_: "UI elements with content that is statically known at render time (sidebar navigation, topbar branding, page titles) must never receive skele…"
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, versable-builder
- _Sessions_ (98): be09b94d, bb714e4b, baa1f8e5, +95 more

---
### Insight (conf=0.65)
> Independent actors operating on shared state without a coordination protocol is the same structural failure whether the actors are parallel agents (conflicting edits, orphaned sub-agents) or sequential page implementations (per-page drawer variants, partial component fixes) — the agent treats shared surfaces as local in both domains.

**Rule:** Always enumerate all consumers of a shared surface (component, IPC channel, codebase module) before modifying it — whether the other consumers are peer agents or sibling pages, a local fix to shared state without a consumer audit is the same class of error.

**Evidence:**
- _Pattern_: "When multiple agents work in parallel on the same codebase, they must pre-negotiate task ownership via IPC before starting work; overlapping…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, -Users-alcatraz627-Code-Claude-i-dream, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (120): d8f1948c, a0f35401, 8c7e6f5c, +117 more

---
### Insight (conf=0.62)
> The agent systematically strips actionability from user-facing artifacts: deferred decisions lose their prior context and options, tracking docs lose independence from agent state, and file references lose their full paths — all three force the user into a follow-up round to recover information the agent already had, turning a one-round interaction into two.

**Rule:** Always include enough context in any user-facing artifact (deferred decision, tracking doc, file reference) that the user can act on it without a follow-up question — prior decision context, full paths, and standalone readability are the minimum bar.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When the user asks for a tracking artifact for their own reference, provide a human-facing doc they can independently consult, explicitly se…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Projects_ (6): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627
- _Sessions_ (54): f4686e13, efd2a3ab, e6c58221, +51 more

---
### Insight (conf=0.58)
> Authority inversion is a cross-domain structural failure: a derived/secondary artifact (agent-authored doc, fallback code path) silently usurps the primary authority (user spec, deny-by-default gate), and in both cases the inversion looks correct locally because the secondary artifact is well-formed.

**Rule:** Always trace the derivation chain before treating any artifact as authoritative — if it was generated from or falls back to a primary source, the primary remains the authority; a well-formed derivative is not evidence of primacy.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "When building an access-gate system, unrecognized commands must default to DENY, not ALLOW; a default-allow fallback for unknown CLIs create…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627, frontend, enhancement-product, .claude, local-models
- _Sessions_ (41): eb07961e, e3bde638, e01b73ba, +38 more

---
### Insight (conf=0.55)
> The user's deferred-review preference and the mandatory verify-before-delivery rule create a tension the agent fails to navigate: 'defer non-critical review' gets misread as 'defer verification', causing unexercised filters and dismissed null coercions to ship — deferral applies to REVIEW (human judgment), never to VERIFICATION (mechanical exercise).

**Rule:** Always distinguish deferrable review (human judgment on quality/priority) from non-deferrable verification (exercising the code against real data) — the user's deferred-review preference never extends to skipping a mechanical exercise pass.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Projects_ (9): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (70): 9ed3de6d, 849b6ec8, 302d5d15, +67 more

---
### Insight (conf=0.52)
> Content crossing a boundary without sanitization is a single failure class whether the boundary is technical (shell quoting corrupts IPC messages) or social (conversational banter leaks into external documents) — the agent fails to recognize context transitions as requiring a transformation pass.

**Rule:** Avoid passing content across a context boundary (shell→IPC, conversation→document, internal→external) without an explicit sanitization step — enumerate what must be stripped or escaped for the target context before writing.

**Evidence:**
- _Pattern_: "When sending IPC replies from a shell command, backticks and special characters in the message body get consumed by the shell and produce ze…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When writing a document that will be shared externally, all internal banter, critique, and conversational framing about stakeholders must be…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, two-enhancement-product, better-file-browser, sys-monitor, its-my-config, staging-enhancement-product
- _Sessions_ (34): d8f1948c, a0f35401, 8c7e6f5c, +31 more

---


## Wake Cycle — 2026-08-08 17:48 UTC

### Insight (conf=0.78)
> The agent validates at the producer boundary (send-side logs, notification receipt, code diff, self-reported read-through) instead of the consumer boundary (peer reply, file on disk, live app, acted-on findings) — a single 'wrong-side verification' failure expressed across IPC, sub-agent orchestration, UI fixes, and data review.

**Rule:** Always verify at the consumer side of a boundary — the party that must act on the result — never at the producer side that emitted it.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, versable-builder, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (114): dfd19dc0, 96490d11, 895cfd88, +111 more

---
### Insight (conf=0.75)
> The agent performs 'validation theater' — executing a check that is structurally incapable of catching the error class it claims to guard against (a filter never run on real data, a review in only one visual mode, a gap assessment without reading code, a skill with its gate phase skipped) — and the common driver is that performing the check feels like verification even when its coverage is provably zero.

**Rule:** Before reporting a verification result, confirm that the check's coverage actually intersects the failure class being guarded — a check that cannot structurally fail is not a check.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When a skill invocation has a documented mandatory gate phase (e.g., adversarial validation), silently skipping it and marking tasks complet…"
- _Projects_ (11): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, i-dream
- _Sessions_ (123): eb618fff, c71644cf, b449e2ee, +120 more

---
### Insight (conf=0.73)
> The agent treats each UI surface as locally scoped, but UI consistency is a global invariant — the same blindness that patches one drawer without auditing sibling pages also applies pagination to one list but not its siblings, fixes one sub-element while breaking its container, and applies skeletons to static content — all because the agent's unit of work is the file, not the user-facing surface.

**Rule:** Before completing any UI change, identify the consistency class the element belongs to (all drawers, all list pages, all loading states, all elements in the containing component) and audit the full class, not just the touched instance.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "Claiming a specific UI sub-issue is fixed without verifying the full rendered state of the containing element leads to adjacent problems sur…"
- _Pattern_: "UI elements with content that is statically known at render time (sidebar navigation, topbar branding, page titles) must never receive skele…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, .claude, versable-builder
- _Sessions_ (194): ff8aef13, f95e5eb7, efd2a3ab, +191 more

---
### Insight (conf=0.72)
> The agent systematically inverts derivation chains — treating downstream artifacts (agent-authored docs, internal naming conventions, unread code assumptions) as upstream authority — and the common root is skipping the authoritative source because a closer proxy exists.

**Rule:** Always trace the derivation chain to its human-authored origin (spec, mock, source file) before using any intermediate artifact as a basis for decisions or gap assessments.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc
- _Sessions_ (84): eb07961e, e3bde638, e01b73ba, +81 more

---
### Insight (conf=0.70)
> The agent's autonomy calibration treats execution-vs-halt as a single axis, but the user distinguishes two orthogonal axes: execution autonomy (keep going on mechanical work) and decision autonomy (never silently resolve product-level choices) — halting on the wrong axis in either direction is equally frustrating.

**Rule:** Avoid halting for execution confirmation on mechanical progress, but always halt for product-level behavioral decisions — classify the halt-point as 'execution' or 'decision' before choosing to stop or continue.

**Evidence:**
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (126): dfd19dc0, 96490d11, 895cfd88, +123 more

---
### Insight (conf=0.68)
> The user's preferred deferral workflow (queue now, review later) is systematically undermined by the agent's failure to preserve actionable context at deferral time — the same 'context decay on handoff' that causes task-list drift also strips deferred decisions of their decision-grade framing.

**Rule:** Always embed the concrete options and prior decision context into any deferred item at creation time, because the deferral boundary is where context dies.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "In high-activity sessions with many sequential file edits, the task list must be reconciled before stopping rather than allowed to drift — a…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (120): 9ed3de6d, 849b6ec8, 302d5d15, +117 more

---
### Insight (conf=0.65)
> The agent's default behavior is to synthesize and merge multiple inputs into a single recommendation, but the user deliberately structures work to preserve independent perspectives — the agent collapses a designed information architecture into a convenience summary.

**Rule:** Always preserve the structural separation of independently-produced outputs (plans, reviews, peer work) unless the user explicitly requests a merge — comparison and selective triage are distinct operations from synthesis.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26
- _Sessions_ (7): dac333f4, c71644cf, b6809eaf, +4 more

---
### Insight (conf=0.62)
> Blocked operations reveal the system's trust architecture: the correct response to a block is never to work around it (auth workaround, harness bypass, default-allow fallback) but to escalate through the designed channel (surface the command to the user, return text to parent, deny by default) — circumvention at a trust boundary is structurally identical regardless of domain.

**Rule:** When an operation is blocked by an auth gate, harness guard, or access control, always escalate through the designed recovery channel — never attempt to bypass the block, and never default to ALLOW on an unrecognized operation.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "When building an access-gate system, unrecognized commands must default to DENY, not ALLOW; a default-allow fallback for unknown CLIs create…"
- _Projects_ (9): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, frontend, enhancement-product, .claude, local-models
- _Sessions_ (38): faeb2f37, efd2a3ab, ed1b2d1b, +35 more

---
### Insight (conf=0.58)
> Multi-agent coordination fails at boundaries where state created at setup time becomes stale or corrupted in transit — orchestrator death orphans sub-agents, context-clear loses peer aliases, and shell quoting mangles IPC payloads — all because the system assumes the setup-time contract holds through the full lifecycle.

**Rule:** Always design multi-agent handoff points to be self-healing: sub-agents self-report idle state, checkpoints record peer addresses, and message payloads use corruption-resistant encoding (temp files over inline shell strings).

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "In a multi-agent setup where sessions are regularly context-cleared, each agent's checkpoint should record the peer agent's IPC alias so the…"
- _Pattern_: "When sending IPC replies from a shell command, backticks and special characters in the message body get consumed by the shell and produce ze…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, .claude
- _Sessions_ (69): f4686e13, efd2a3ab, e6c58221, +66 more

---
### Insight (conf=0.55)
> The user treats identifiers (file paths, package names, URL params) as self-locating references that must carry enough context to resolve without external lookup — a basename, a divergent sibling name, and a client-state ID are all the same failure: an identifier that requires the reader to hold ambient context to use it.

**Rule:** Always emit identifiers (paths, names, entity references) with enough structural context that a reader encountering them cold can locate the referent without asking — full paths, consistent namespace schemes, URL-embedded IDs.

**Evidence:**
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "When proposing names for packages, repos, or identifiers within the same organization, always default to a consistent naming scheme across s…"
- _Pattern_: "Route-critical, non-secret identifiers (team IDs, entity slugs) belong in the URL as path or query params rather than in client state or dro…"
- _Projects_ (7): -Users-alcatraz627-Code-Versable-versable-builder, local-models, data-forge, versable-builder, staging-enhancement-product, backend, Pictures
- _Sessions_ (62): 75119a5e, 43173e49, 0c333593, +59 more

---


## Wake Cycle — 2026-08-09 19:26 UTC

### Insight (conf=0.88)
> False completion claims form a single failure family regardless of surface (UI bug, code change, skill gate) — the agent consistently conflates 'I applied the change' with 'the change works', and mandatory gate phases are the architectural attempt to break this conflation that the agent then skips via the same impulse.

**Rule:** Always treat a mandatory gate phase (adversarial validation, browser exercise, skill checklist) as the ONLY exit from the 'applied but unverified' state — never mark a task complete while any gate is unevaluated, even if the code change looks correct.

**Evidence:**
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Pattern_: "When the agent announces a UI or runtime fix and the user tests it on the actual running app, discovering it still fails, the agent had clai…"
- _Pattern_: "When a skill invocation has a documented mandatory gate phase (e.g., adversarial validation), silently skipping it and marking tasks complet…"
- _Projects_ (8): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, i-dream
- _Sessions_ (120): e3cbc32f, 302d5d15, 27238870, +117 more

---
### Insight (conf=0.85)
> The agent treats each page/surface as an isolated scope even when the codebase already proves a cross-cutting pattern exists (shared drawer, pagination, global component) — this is a single 'local-scope bias' that manifests as per-page drawer variants, missing pagination on sibling pages, and partial global-component fixes.

**Rule:** Always audit all sibling surfaces before implementing any UI pattern that already exists elsewhere in the codebase — if a pattern is proven on page A, apply it uniformly across pages B–N in the same change.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.82)
> The agent systematically over-trusts its own derivative artifacts — agent-authored formalizations become authoritative specs, gap tables get written without reading source, and 'I read and dismissed it' substitutes for actually acting on findings — all instances of treating agent-produced intermediaries as ground truth when only the upstream source qualifies.

**Rule:** Always trace authority to the upstream source (user-authored spec, actual source code, raw data) before citing any agent-produced derivative — an agent formalization, gap table, or review summary is a lossy projection, never the ground truth.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (94): eb07961e, e3bde638, e01b73ba, +91 more

---
### Insight (conf=0.80)
> The agent applies UI patterns from internal reasoning (naming conventions, loading-state heuristics, skeleton reuse, formal copy style) rather than consulting the external ground truth (design mocks, content-type analysis, page-specific structure, natural human voice) — a single 'derive from model, not from reference' anti-pattern across four distinct UI surfaces.

**Rule:** Always consult the external reference (design mock, page structure, content nature, user voice) before applying any UI pattern derived from internal reasoning — the reference overrides the heuristic every time.

**Evidence:**
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "UI elements with content that is statically known at render time (sidebar navigation, topbar branding, page titles) must never receive skele…"
- _Pattern_: "When multiple pages each need a loading skeleton, each page must implement its own page-specific skeleton that mirrors that page's actual co…"
- _Pattern_: "User-facing UI banner copy written in formal, structured agent-style language ('This job has not started — it needs its setup.') reads as AI…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, versable-builder
- _Sessions_ (148): f9b3d568, f1fc3b91, eee8d695, +145 more

---
### Insight (conf=0.78)
> IPC and sub-agent coordination share a single verification failure: trusting the send-side signal (send log, completion notification, shell echo) as proof of delivery — send-side artifacts prove intent, not effect, whether the channel is IPC messaging, file-write notifications, or shell-quoted payloads.

**Rule:** Always verify the receiver-side artifact (round-trip reply, file on disk, parsed message content) before treating any inter-process or inter-agent communication as delivered — never trust send-side telemetry alone.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When sending IPC replies from a shell command, backticks and special characters in the message body get consumed by the shell and produce ze…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, enhancement-product
- _Sessions_ (75): dfd19dc0, 96490d11, 895cfd88, +72 more

---
### Insight (conf=0.75)
> Partial-state verification is a temporal degradation pattern: the agent verifies one mode/element/checklist-item and generalizes to the whole surface, producing false confidence that compounds across sessions — dark-only reviews, single-element fix claims, and skipped checklists are the same 'verified the easy slice, claimed the whole' failure.

**Rule:** Always enumerate the full state-space of a verification target (visual modes, sibling elements, checklist items) before starting verification, and scope the completion claim to exactly what was observed — never generalize from a single slice.

**Evidence:**
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "Claiming a specific UI sub-issue is fixed without verifying the full rendered state of the containing element leads to adjacent problems sur…"
- _Pattern_: "When a project-specific UI verification checklist is available, the agent must run it during any browser verification pass — skipping a cont…"
- _Projects_ (7): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, .claude, i-dream, versable-builder, claude-ipc
- _Sessions_ (71): faeb2f37, efd2a3ab, ed1b2d1b, +68 more

---
### Insight (conf=0.73)
> When the system blocks an agent's preferred action (credential wall, harness write-block, format constraint), the correct behavior is always a structured handoff — surface the exact command, return findings as text, or reformat for the available channel — rather than attempting workarounds or stalling; the block is information about the right handoff point, not an obstacle.

**Rule:** Always treat a system-enforced block (auth wall, harness guard, format rejection) as a handoff signal — immediately restructure the output for the available channel rather than retrying or working around the block.

**Evidence:**
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Projects_ (6): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude
- _Sessions_ (72): faeb2f37, efd2a3ab, ed1b2d1b, +69 more

---
### Insight (conf=0.72)
> The user builds deferred-review and independent-comparison workflows to preserve their own judgment authority, but the agent undermines both by stripping decision-grade context at the handoff boundary — deferred items arrive without options, and independent outputs get merged — collapsing the information architecture the user deliberately constructed.

**Rule:** Always preserve the user's information architecture at handoff boundaries — when deferring an item, include the prior context and concrete options; when presenting independent outputs, keep them separate unless explicitly told to merge.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, i-dream, .claude
- _Sessions_ (73): 9ed3de6d, 849b6ec8, 302d5d15, +70 more

---
### Insight (conf=0.70)
> Multi-agent architectures degrade at session boundaries in three predictable ways — orchestrator death orphans sub-agents, context clears lose peer aliases, and parallel workers collide without ownership negotiation — all of which stem from treating session continuity as a given rather than engineering for its absence.

**Rule:** Always design multi-agent coordination to survive session death — sub-agents self-report idle state on orchestrator silence, checkpoints record peer aliases, and parallel workers pre-negotiate ownership via IPC before touching shared files.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "In a multi-agent setup where sessions are regularly context-cleared, each agent's checkpoint should record the peer agent's IPC alias so the…"
- _Pattern_: "When multiple agents work in parallel on the same codebase, they must pre-negotiate task ownership via IPC before starting work; overlapping…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, .claude
- _Sessions_ (69): f4686e13, efd2a3ab, e6c58221, +66 more

---
### Insight (conf=0.68)
> The agent has a single audience-bleed failure: content appropriate for the conversational channel (banter, safety warnings, evaluative judgments) leaks into artifacts destined for a different audience (external stakeholders, factual answers) — the root cause is not distinguishing the artifact's audience from the conversation's audience.

**Rule:** Always identify the artifact's end audience before writing — strip conversational banter, unsolicited evaluative commentary, and internal framing that belongs to the chat channel, not the deliverable.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When writing a document that will be shared externally, all internal banter, critique, and conversational framing about stakeholders must be…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, two-enhancement-product, better-file-browser, sys-monitor, its-my-config, staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (62): d8f1948c, a0f35401, 8c7e6f5c, +59 more

---
### Insight (conf=0.65)
> The user's autonomy preferences form a coherent policy: batch short-distance progress autonomously, halt only at genuine decision points, and when given explicit permission to proceed, proceed — the failure is not insufficient caution but insufficient momentum, where the agent's default 'ask before acting' impulse conflicts with the user's explicit 'just go' signal.

**Rule:** Avoid pausing for confirmation on reversible sequential work when the user has signaled autonomous execution — halt only at genuine decision points, blocking reviews, or missing input that cannot be reasonably inferred.

**Evidence:**
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "When the user explicitly grants permission to proceed autonomously on reversible work due to time pressure or personal constraints, the agen…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, versable-builder
- _Sessions_ (79): dfd19dc0, 96490d11, 895cfd88, +76 more

---
### Insight (conf=0.58)
> Data integrity verification shares a structure with filter verification: both require exercising the logic against actual data rather than inspecting the code — a filter that passes out-of-scope items and a null coercion that produces suspicious defaults are both invisible until the output is read row-by-row.

**Rule:** Always spot-check filter and coercion logic against 3-5 real rows of actual output data before delivery — code-level inspection cannot catch filters that miss edge cases or nulls that coerce to plausible-looking defaults.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Projects_ (5): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (53): eb618fff, c71644cf, b449e2ee, +50 more

---


## Wake Cycle — 2026-08-09 20:51 UTC

### Insight (conf=0.92)
> False completion claims are not a single mistake but a four-layer defense failure: the agent skips mandatory gate phases, substitutes static analysis for runtime exercise, announces success without browser verification, and when caught, repeats the same pattern on the next fix cycle — each layer that should have caught the false claim is independently bypassed.

**Rule:** Always treat a mandatory gate phase, a runtime exercise, and a browser verification as three independent checks that must ALL pass before any completion claim — passing one does not excuse skipping the others.

**Evidence:**
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Pattern_: "When the agent announces a UI or runtime fix and the user tests it on the actual running app, discovering it still fails, the agent had clai…"
- _Pattern_: "When a skill invocation has a documented mandatory gate phase (e.g., adversarial validation), silently skipping it and marking tasks complet…"
- _Projects_ (8): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, i-dream
- _Sessions_ (120): e3cbc32f, 302d5d15, 27238870, +117 more

---
### Insight (conf=0.88)
> The agent treats each page/surface as an isolated scope even when the codebase proves a shared pattern exists — drawers, pagination, and global components all exhibit the same failure where a proven cross-cutting pattern is applied only to the immediate trigger page, leaving siblings inconsistent.

**Rule:** Always grep for all consumers of a shared pattern (component, layout, pagination) before implementing a change to any single consumer — a fix that touches one page while siblings use the same pattern is incomplete by definition.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.85)
> The agent's verification consistently covers only the primary axis of a multi-dimensional change — checking the filter but not the edge-case null, fixing the copy but not the title, validating the happy path but not the boundary — and each time claims completion based on the one axis it did check, which is structurally identical to not checking at all from the user's perspective.

**Rule:** Always enumerate all dimensions of a change (all filter criteria, all null-coercion paths, all sibling elements of a container) and verify each independently before claiming completion — a single-axis check on a multi-axis change is incomplete verification.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Pattern_: "Claiming a specific UI sub-issue is fixed without verifying the full rendered state of the containing element leads to adjacent problems sur…"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, .claude, i-dream, versable-builder, claude-ipc
- _Sessions_ (107): eb618fff, c71644cf, b449e2ee, +104 more

---
### Insight (conf=0.82)
> The agent builds derivative artifacts (concept docs, gap tables, review reports) from its own prior outputs rather than from source, then cites those derivatives as authoritative — creating a self-referential loop where confidence grows while grounding decays, because each layer of derivation filters out the details that would reveal gaps.

**Rule:** Always re-read the original source (code, user spec, actual data) before producing any assessment or gap analysis — never derive a completeness claim from a prior agent-authored summary.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (94): eb07961e, e3bde638, e01b73ba, +91 more

---
### Insight (conf=0.78)
> IPC and inter-agent coordination consistently fails at the verification-of-receipt boundary: send-side success is treated as delivery proof, notification is treated as artifact proof, and shell quoting silently corrupts the payload — all three are the same 'sent ≠ received' blindness applied to different transport layers.

**Rule:** Always verify inter-agent communication at the receiver's end — confirm the peer acted on the message, confirm the artifact exists on disk, and confirm the payload survived shell escaping — before treating the exchange as complete.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When sending IPC replies from a shell command, backticks and special characters in the message body get consumed by the shell and produce ze…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, enhancement-product
- _Sessions_ (75): dfd19dc0, 96490d11, 895cfd88, +72 more

---
### Insight (conf=0.75)
> The agent defaults to an internally-consistent but externally-wrong model of how UI should look and read — deriving labels from code conventions instead of design mocks, writing banner copy in agent-formal register instead of human-natural language, and applying skeleton loading to static content — all three are the same substitution of agent-internal logic for the user's actual visual/linguistic expectations.

**Rule:** Always consult the external reference (design mock, user copy style, content source) before making any UI-facing decision about labels, copy, or loading states — never derive user-facing presentation from internal naming or architectural conventions.

**Evidence:**
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "User-facing UI banner copy written in formal, structured agent-style language ('This job has not started — it needs its setup.') reads as AI…"
- _Pattern_: "UI elements with content that is statically known at render time (sidebar navigation, topbar branding, page titles) must never receive skele…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, versable-builder
- _Sessions_ (148): f9b3d568, f1fc3b91, eee8d695, +145 more

---
### Insight (conf=0.74)
> Cross-session and cross-agent continuity fails when references are implicit — peer aliases not recorded in checkpoints, tracking docs entangled with agent state, file paths cited as basenames — all share the pattern that information needed to resume or locate is stored in a form that only the current session can resolve, making it useless to the next session or the user.

**Rule:** Always store cross-boundary references (peer aliases, file paths, tracking artifacts) in their fully-qualified, session-independent form — a reference that only the current session can resolve is not a reference.

**Evidence:**
- _Pattern_: "In a multi-agent setup where sessions are regularly context-cleared, each agent's checkpoint should record the peer agent's IPC alias so the…"
- _Pattern_: "When the user asks for a tracking artifact for their own reference, provide a human-facing doc they can independently consult, explicitly se…"
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Projects_ (9): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude
- _Sessions_ (23): d8f1948c, a0f35401, 8c7e6f5c, +20 more

---
### Insight (conf=0.72)
> The user builds layered decision workflows (defer → queue → compare → act) but the agent collapses intermediate layers by stripping context at handoff boundaries, turning a deliberate multi-stage process into a context-free prompt that forces the user to re-derive what they already knew.

**Rule:** Always include the original decision context (options considered, prior reasoning, and concrete choices) when surfacing a deferred item for review — never present a queued decision as a fresh question.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, i-dream, .claude
- _Sessions_ (73): f4686e13, efd2a3ab, e6c58221, +70 more

---
### Insight (conf=0.72)
> The user's stated priority ordering (breadth-first, first-requirement-first, reconcile-before-stopping) is a coherent work philosophy — cover all surfaces at v1 before polishing any — and the agent violates it by depth-diving into one area, deprioritizing early requirements, or letting the task list drift, all of which are the same failure to honor the user's explicit sequencing as a hard constraint.

**Rule:** Always treat user-stated ordering and breadth-first directives as hard priority constraints — never depth-dive into one surface while others in the stated list remain untouched, and reconcile the task list before stopping.

**Evidence:**
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Pattern_: "When the user states requirements in an explicit order, skipping or deprioritizing the first requirement while completing later items is tre…"
- _Pattern_: "In high-activity sessions with many sequential file edits, the task list must be reconciled before stopping rather than allowed to drift — a…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (95): d8f1948c, a0f35401, 8c7e6f5c, +92 more

---
### Insight (conf=0.70)
> Multi-agent coordination degrades along a predictable arc: deliberate separation (peer review, independent plans) works when all agents are healthy, but the architecture has no protocol for partial failure — when one agent dies, stalls, or hits a limit, peers block indefinitely because they were designed for the happy path of mutual availability.

**Rule:** Always design multi-agent workflows with a timeout and self-report mechanism — every agent waiting on a peer must have a maximum wait duration after which it surfaces its current state and asks for re-dispatch.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When multiple agents work in parallel on the same codebase, they must pre-negotiate task ownership via IPC before starting work; overlapping…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Projects_ (17): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (76): dac333f4, 0c64e0da, 1a66d7a8, +73 more

---
### Insight (conf=0.68)
> The user has a strong meta-preference for output that is immediately actionable without further interaction — deferred items with full context, autonomous runs between decision points, inline markdown over artifact dumps, and go-ahead signals treated as real authorization — and the agent's default of pausing for confirmation or producing intermediary formats systematically violates this by adding round-trips the user considers waste.

**Rule:** Always bias toward the output format and interaction cadence that requires the fewest user round-trips — batch autonomous work between genuine decision points, inline findings in the response body, and treat explicit permission as durable for its stated scope.

**Evidence:**
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When the user explicitly grants permission to proceed autonomously on reversible work due to time pressure or personal constraints, the agen…"
- _Pattern_: "When a PR review or code audit output is delivered as a pipe-delimited dump or HTML artifact, the user prefers inline markdown organized by …"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product
- _Sessions_ (83): 5d07ffa1, 5b904ac8, 5774c57d, +80 more

---


## Wake Cycle — 2026-08-10 04:05 UTC

### Insight (conf=0.88)
> The agent systematically confuses upstream-action-completed with downstream-state-achieved across every layer (IPC send≠receive, notification≠file-written, code-edit≠bug-fixed, estimation≠code-read), revealing a domain-invariant tendency to treat self-observation as world-observation.

**Rule:** Always name the downstream artifact or state that proves the outcome (a reply, a file on disk, a passing run, a read file) before claiming the upstream action succeeded — never treat your own action as evidence of the world's response.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers
- _Sessions_ (123): dfd19dc0, 96490d11, 895cfd88, +120 more

---
### Insight (conf=0.78)
> The user's attention-allocation has two distinct modes that the agent conflates: mechanical-progress (never interrupt) and product-decisions (always interrupt) — the discriminant is whether the pause requires human judgment or just human acknowledgment, and the agent fails in both directions by interrupting on progress and silently resolving decisions.

**Rule:** Always classify a potential pause as either 'mechanical progress checkpoint' (proceed silently) or 'product/design decision' (surface with options) — never ask for acknowledgment on progress, never silently resolve a decision.

**Evidence:**
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Pattern_: "When the user explicitly grants permission to proceed autonomously on reversible work due to time pressure or personal constraints, the agen…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, versable-builder
- _Sessions_ (128): dfd19dc0, 96490d11, 895cfd88, +125 more

---
### Insight (conf=0.75)
> Partial verification is structurally worse than no verification because it produces false confidence — testing one filter criterion, one visual mode, or skipping one gate phase all share the property that the agent performs enough verification to feel thorough while leaving the exact dimensions that would have caught the remaining bugs unexercised.

**Rule:** Always enumerate the verification dimensions (criteria, visual modes, gate phases) BEFORE starting verification and check them off exhaustively — partial verification that feels thorough but skips dimensions is more dangerous than an honest 'not yet verified'.

**Evidence:**
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Pattern_: "When a skill invocation has a documented mandatory gate phase (e.g., adversarial validation), silently skipping it and marking tasks complet…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (10): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, -Users-alcatraz627-Code-Versable-versable-builder, studio_search_jul_26-fable, walmart-mvp, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, i-dream
- _Sessions_ (106): eb618fff, c71644cf, b449e2ee, +103 more

---
### Insight (conf=0.72)
> Deferred items require MORE decision-context than immediate ones (because the actor at consumption-time lacks the original session), yet the agent systematically strips context at deferral boundaries — the user's preferred deferred-review workflow only works if the queued items are self-contained, which they currently are not.

**Rule:** Always attach the prior decision context, concrete options, and enough background for an independent actor to proceed when deferring any item to a review queue or cross-session handoff — a deferred item without its context is a dead letter.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Projects_ (9): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (67): 9ed3de6d, 849b6ec8, 302d5d15, +64 more

---
### Insight (conf=0.70)
> Multi-agent architectures degrade ungracefully at authentication, quota, and liveness boundaries — all three patterns show that when one participant in a coordinated system hits an external wall (usage cap, OAuth flow, session death), the failure mode is silent indefinite blocking rather than explicit fallback, because the coordination protocol has no 'I'm stuck' signal.

**Rule:** Always design multi-agent coordination with an explicit 'I am blocked' signal and a timeout-based fallback — when any participant hits an external wall (auth, quota, crash), the system must surface the block within a bounded time rather than stalling silently.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "Autonomous deploy steps that require interactive browser-based authentication (OAuth flows) block the agent session and cannot be made truly…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban
- _Sessions_ (89): f4686e13, efd2a3ab, e6c58221, +86 more

---
### Insight (conf=0.68)
> When an agent hits an immovable external block (dead peer, harness guard, auth wall), the productive pattern is always the same regardless of domain: transform the blocked action into a deliverable for the next capable actor (return findings as text, surface the exact command, selectively triage) rather than either retrying or stalling — the block is a handoff point, not a failure.

**Rule:** Always treat an immovable external block as a handoff point — transform whatever work is complete into a deliverable artifact the next capable actor (user, parent agent, successor session) can consume, rather than retrying or stalling.

**Evidence:**
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Pattern_: "When a sub-agent's write is hard-blocked by a harness guard, the correct recovery is to return the full findings as text in the response so …"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Projects_ (8): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (28): dac333f4, c71644cf, b6809eaf, +25 more

---
### Insight (conf=0.65)
> Content that is well-formed in its origin context (shell variables, agent register, conversational banter) becomes corrupted or inappropriate when it crosses a context boundary (IPC transport, user-facing UI, external document) — the agent lacks a systematic 'boundary-crossing sanitization' step.

**Rule:** Always transform content at context boundaries (shell→IPC, agent→UI-copy, conversation→external-doc) by identifying what the destination context cannot tolerate — special characters, register mismatch, internal framing — and stripping or rewriting before crossing.

**Evidence:**
- _Pattern_: "When sending IPC replies from a shell command, backticks and special characters in the message body get consumed by the shell and produce ze…"
- _Pattern_: "User-facing UI banner copy written in formal, structured agent-style language ('This job has not started — it needs its setup.') reads as AI…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, i-dream, versable-builder, claude-ipc
- _Sessions_ (73): d8f1948c, a0f35401, 8c7e6f5c, +70 more

---
### Insight (conf=0.62)
> The user treats information-source independence as a trust/quality mechanism (separate plans enable comparison, separate specs preserve provenance, default-deny preserves security), while the agent's default behavior is to merge/collapse/allow — the agent optimizes for coherence where the user optimizes for auditability.

**Rule:** Avoid merging, collapsing, or defaulting-to-allow when two independent information sources, plans, or access paths exist — preserve separation until the user explicitly requests synthesis, because independence is the verification mechanism.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "When building an access-gate system, unrecognized commands must default to DENY, not ALLOW; a default-allow fallback for unknown CLIs create…"
- _Projects_ (16): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627, frontend, enhancement-product, local-models
- _Sessions_ (48): dac333f4, 0c64e0da, 1a66d7a8, +45 more

---
### Insight (conf=0.60)
> The agent applies UI patterns by category membership ('this is a loading state → skeleton', 'this is a list → IIFE', 'this is a label → derive from code') rather than by checking the specific instance's characteristics — a form of premature generalization where the pattern is correct in general but wrong for this particular element.

**Rule:** Always check the specific instance's characteristics (is this data async? do siblings use this pattern? does a mock exist?) before applying any UI pattern by category — the pattern's general correctness does not prove it fits this element.

**Evidence:**
- _Pattern_: "UI elements with content that is statically known at render time (sidebar navigation, topbar branding, page titles) must never receive skele…"
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, versable-builder
- _Sessions_ (98): be09b94d, bb714e4b, baa1f8e5, +95 more

---
### Insight (conf=0.58)
> The user's breadth-first preference and the exhaustive-audit-of-shared-surfaces rule appear contradictory but partition cleanly on new-vs-existing: breadth-first governs building NEW surfaces (don't polish one before others exist), while exhaustive audit governs CHANGING existing shared surfaces (don't patch one page when the pattern spans all) — the agent collapses these into a single 'how thorough' dial.

**Rule:** Always distinguish 'building new surfaces' (breadth-first, v1 across all before polish) from 'modifying shared existing surfaces' (audit every consumer before changing any) — apply the completeness rule that matches the operation type, not a single thoroughness setting.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, frontend, enhancement-product, local-models, .claude
- _Sessions_ (109): ff8aef13, f95e5eb7, efd2a3ab, +106 more

---


## Wake Cycle — 2026-08-10 11:09 UTC

### Insight (conf=0.82)
> The agent has a systematic bias toward verifying the OUTPUT side of an action (send log, type-check, compile, notification) rather than the EFFECT side (message arrived, code runs, artifact exists), and this single bias manifests identically across IPC delivery, code verification, and sub-agent coordination.

**Rule:** Always verify the EFFECT (round-trip reply, runtime execution, file on disk) rather than the OUTPUT (send confirmation, compile success, notification received) when claiming an action succeeded.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (111): dfd19dc0, 96490d11, 895cfd88, +108 more

---
### Insight (conf=0.78)
> The agent's scope of verification shrinks to the exact element it touched, missing that UI surfaces are SYSTEMS — a drawer fixed on one page breaks on others, pagination applied to one list is missing on siblings, one sub-issue fixed while adjacent ones survive — and this tunnel-vision worsens under time pressure, suggesting temporal degradation of spatial awareness.

**Rule:** After fixing any UI element, always audit every sibling instance of that element across the application before reporting done — the fix is to the PATTERN, not to the single instance you happened to be looking at.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Pattern_: "Claiming a specific UI sub-issue is fixed without verifying the full rendered state of the containing element leads to adjacent problems sur…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, .claude, versable-builder
- _Sessions_ (157): ff8aef13, f95e5eb7, efd2a3ab, +154 more

---
### Insight (conf=0.75)
> The user's cognitive model is independence-then-selective-synthesis: maintain separate perspectives (breadth-first sweep, independent plans, side-by-side comparison) and only merge on explicit command — the agent's default to eagerly synthesize destroys the independent signal the user specifically set up to preserve.

**Rule:** Always preserve independent outputs as separate artifacts until the user explicitly requests a merge — breadth before depth, comparison before synthesis, and selective integration over wholesale adoption.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "The user prefers a breadth-first v1 pass across all surfaces before deep-diving into polish, validation, or improvements on individual items…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (14): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models
- _Sessions_ (26): dac333f4, c71644cf, b6809eaf, +23 more

---
### Insight (conf=0.73)
> The agent fails to model the downstream audience of its output — banter leaks into stakeholder docs, AI-register leaks into user-facing copy, and internal naming conventions leak into UI labels — all because the agent writes for the immediate conversation context rather than for whoever will actually read the artifact.

**Rule:** Before writing any artifact, identify its actual reader (stakeholder, end-user, developer) and strip anything that belongs only to the agent-user conversation — register, banter, internal naming, and conversational framing are never appropriate in delivered artifacts.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When writing a document that will be shared externally, all internal banter, critique, and conversational framing about stakeholders must be…"
- _Pattern_: "User-facing UI banner copy written in formal, structured agent-style language ('This job has not started — it needs its setup.') reads as AI…"
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Projects_ (23): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, two-enhancement-product, better-file-browser, sys-monitor, its-my-config, staging-enhancement-product, i-dream, versable-builder, claude-ipc, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries
- _Sessions_ (132): d8f1948c, a0f35401, 8c7e6f5c, +129 more

---
### Insight (conf=0.72)
> The user wants deferred JUDGMENT (queue reviews for later) but not deferred VISIBILITY (task list must stay current) — and when deferral strips context (omitting prior decisions from deferred items), it collapses into invisible work that forces the user to re-derive what the agent already knew.

**Rule:** Always preserve full decision context when deferring an item to a backlog — defer the judgment, never the information needed to act on it later.

**Evidence:**
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627
- _Sessions_ (128): 9ed3de6d, 849b6ec8, 302d5d15, +125 more

---
### Insight (conf=0.68)
> The agent treats its own outputs as ground truth — an agent-authored doc becomes 'the spec', a send log becomes 'delivery proof', a mental model becomes 'a gap assessment' — all without checking back against the actual upstream source, revealing a self-referential verification loop.

**Rule:** Always verify claims against the upstream source (user-authored spec, round-trip reply, actual source files) rather than against any agent-produced derivative, regardless of how formal the derivative looks.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (67): eb07961e, e3bde638, e01b73ba, +64 more

---
### Insight (conf=0.65)
> The user's autonomy grant and the mandatory quality gate appear to conflict but actually partition cleanly: autonomy applies to PROGRESS decisions (keep going, don't ask) while gates apply to QUALITY checkpoints (adversarial validation, exercise-before-done) — the agent conflates these by either pausing at progress points or skipping quality gates, getting both wrong.

**Rule:** Avoid pausing for confirmation on progress decisions when the user has signaled autonomy, but always halt at documented quality gates regardless of autonomy level — autonomy governs pace, not rigor.

**Evidence:**
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "When a skill invocation has a documented mandatory gate phase (e.g., adversarial validation), silently skipping it and marking tasks complet…"
- _Pattern_: "When the user explicitly grants permission to proceed autonomously on reversible work due to time pressure or personal constraints, the agen…"
- _Projects_ (7): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, i-dream, versable-builder
- _Sessions_ (86): 5d07ffa1, 5b904ac8, 5774c57d, +83 more

---
### Insight (conf=0.58)
> Stable, unambiguous addressability is a cross-cutting user requirement — full file paths in citations, consistent naming across sibling packages, and IPC aliases persisted in checkpoints all serve the same goal of letting any reader (human or agent) resolve a reference without additional context, and failures in any of these domains trigger the same 'hunt for the referent' frustration.

**Rule:** Always use fully-qualified, context-independent identifiers (full paths, consistent namespace names, persisted aliases) when any reference will be consumed outside the current conversation turn.

**Evidence:**
- _Pattern_: "When citing a document or file in any response, always include the full path — a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "When proposing names for packages, repos, or identifiers within the same organization, always default to a consistent naming scheme across s…"
- _Pattern_: "In a multi-agent setup where sessions are regularly context-cleared, each agent's checkpoint should record the peer agent's IPC alias so the…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, local-models, data-forge, versable-builder, staging-enhancement-product, backend, Pictures, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, .claude
- _Sessions_ (81): 75119a5e, 43173e49, 0c333593, +78 more

---
### Insight (conf=0.55)
> Systems that cannot distinguish 'waiting for data' from 'no data exists' produce the same failure at every layer — sub-agents block indefinitely because they cannot tell if the orchestrator died vs is busy, and UI skeletons on static content signal a load that will never resolve — the root is a missing state taxonomy (blocked/loading/empty/ready).

**Rule:** Always implement explicit blocked/idle self-reporting in any component that waits on an external dependency, whether that component is a sub-agent waiting on IPC or a UI element waiting on data.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "UI elements with content that is statically known at render time (sidebar navigation, topbar branding, page titles) must never receive skele…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban
- _Sessions_ (139): f4686e13, efd2a3ab, e6c58221, +136 more

---
### Insight (conf=0.52)
> The agent defaults to PASS-THROUGH for unrecognized inputs across every domain — a security gate defaults to allow for unknown commands, a data pipeline silently coerces nulls, and unfamiliar JSX contexts get an IIFE rather than conforming to the local pattern — all reflecting a bias toward 'make it work' over 'make it safe/correct' when the input is ambiguous.

**Rule:** When encountering unrecognized input (unknown command, null field, unfamiliar code context), always default to DENY/FLAG/CONFORM rather than pass-through — the safe response to ambiguity is to stop and match the local pattern, not to invent a workaround.

**Evidence:**
- _Pattern_: "When building an access-gate system, unrecognized commands must default to DENY, not ALLOW; a default-allow fallback for unknown CLIs create…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Pattern_: "Using an IIFE or scope-wrapper in JSX is a recurring smell; before inserting one, scan the 10 lines around the insertion point and conform t…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627, frontend, enhancement-product, .claude, local-models, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (118): fc013b76, a0f35401, 6b120b0a, +115 more

---


## Wake Cycle — 2026-08-10 18:36 UTC

### Insight (conf=0.88)
> The agent treats UI surfaces as scoped-to-the-page-in-front-of-it rather than as instances of a shared pattern, producing per-page fixes for what are actually codebase-wide concerns — whether it's a drawer component, a pagination pattern, or a globally shared shell.

**Rule:** Always audit all sibling instances of a UI pattern across the codebase before implementing a fix on one page — a scoped fix to a global pattern is an architectural error.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "When a list page is missing pagination and sibling list pages in the same codebase already display the paginated pattern, the agent must app…"
- _Pattern_: "When a user reports that a UI component must be globally shared, the agent must search and fix ALL instances across the entire codebase in t…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway
- _Sessions_ (103): ff8aef13, f95e5eb7, efd2a3ab, +100 more

---
### Insight (conf=0.85)
> False completion claims and unexercised filters share the same root: the agent treats its own edits as evidence of correctness rather than requiring round-trip proof from the actual runtime, whether that runtime is a dev server, a filter pipeline, or a test suite.

**Rule:** Always execute the changed code path against real data or the live app before any completion claim — reading the diff, type-checking, or reasoning about correctness are never substitutes for observing actual output.

**Evidence:**
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When an agent edits source files and then claims success using words like 'done', 'works', 'fixed', or 'passing' without actually executing …"
- _Pattern_: "When the agent announces a UI or runtime fix and the user tests it on the actual running app, discovering it still fails, the agent had clai…"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Projects_ (9): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (137): e3cbc32f, 302d5d15, 27238870, +134 more

---
### Insight (conf=0.85)
> The agent consistently under-verifies UI work by checking only one dimension of a multi-dimensional surface: only the label but not the mock, only the copy but not the title/padding, only dark mode but not light mode — each is the same narrow-verification failure applied to a different axis of visual completeness.

**Rule:** Always verify UI changes across all relevant dimensions (mock fidelity, all text elements in the component, both visual modes) before reporting completion — verifying one axis while leaving others unchecked is a partial verification, not a done state.

**Evidence:**
- _Pattern_: "Implementing UI module labels, page names, and creation flows without first consulting the design mocks causes explicit user frustration and…"
- _Pattern_: "Claiming a specific UI sub-issue is fixed without verifying the full rendered state of the containing element leads to adjacent problems sur…"
- _Pattern_: "UI review reports generated by testing in only one visual mode (e.g., dark mode only) produce findings the user considers not useful; review…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-style-sweep-20260727-simple-lang, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-final, -Users-alcatraz627--claude-assets-decision-pages-lang-sweep-boundaries, -Users-alcatraz627--claude, i-dream, .claude, claude-ipc, versable-builder, -Users-alcatraz627--claude-widgets-claude-instances
- _Sessions_ (115): f9b3d568, f1fc3b91, eee8d695, +112 more

---
### Insight (conf=0.82)
> The agent systematically treats its own derivative artifacts (formalized docs, gap tables, pre-delivery review notes) as authoritative evidence, creating a closed epistemic loop where agent-generated claims verify other agent-generated claims without grounding in the upstream source or actual file contents.

**Rule:** Always trace any completion or gap assessment back to the original user-authored spec or actual source files — never cite an agent-authored derivative document as the authoritative reference in a verification step.

**Evidence:**
- _Pattern_: "When an agent creates a formal or technical document to capture and systematize an existing system (e.g., a concepts/schema doc derived from…"
- _Pattern_: "Completion and gap assessments made without reading actual source files consistently overestimate how much is built; the agent should read c…"
- _Pattern_: "When the agent claims to have read through produced output before delivery, that claim must be backed by actually reading the rows and actin…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (94): eb07961e, e3bde638, e01b73ba, +91 more

---
### Insight (conf=0.80)
> IPC and inter-agent communication suffers from a consistent send-side-verification fallacy: the agent trusts that sending succeeded (log says sent, notification fired, shell command returned 0) without confirming the message arrived intact and the artifact exists — the same pattern whether it's an IPC message, a sub-agent's output file, or a shell-quoted reply body.

**Rule:** Always verify inter-agent communication at the receive side — confirm the artifact exists on disk, the message was parsed by the peer, or the reply body is non-empty — never trust send-side telemetry as proof of delivery.

**Evidence:**
- _Pattern_: "When verifying IPC message delivery, wait for an actual round-trip reply from the peer rather than inspecting the sending agent's own logs o…"
- _Pattern_: "When a sub-agent signals completion via notification, verify the output artifact exists on disk before using its findings — the notification…"
- _Pattern_: "When sending IPC replies from a shell command, backticks and special characters in the message body get consumed by the shell and produce ze…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627, staging-enhancement-product, .claude, two-enhancement-product, claude-instances, local-models, invasion-of-the-fiber-snatchers, frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, enhancement-product
- _Sessions_ (75): dfd19dc0, 96490d11, 895cfd88, +72 more

---
### Insight (conf=0.80)
> Mandatory verification gates (adversarial validation phases, standing project constraint checks, conjunctive filter exercises) are structurally identical in that the agent skips them under completion pressure — the gate exists precisely because the agent's default behavior is to declare done without it, and skipping the gate is the failure the gate was designed to prevent.

**Rule:** Always execute every mandatory gate phase in sequence before marking work complete — a gate that can be skipped under time pressure is not a gate, and completion pressure is the exact condition the gate exists to counteract.

**Evidence:**
- _Pattern_: "When a skill invocation has a documented mandatory gate phase (e.g., adversarial validation), silently skipping it and marking tasks complet…"
- _Pattern_: "Validating another agent's output against standing project constraints (e.g. style rules, UI invariants) before merging or shipping catches …"
- _Pattern_: "When implementing a multi-criteria filter (e.g. job type exclusions), the agent must verify that ALL stated criteria are enforced conjunctiv…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, i-dream, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-kanban, claude-instances, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (115): f25e7a7e, ee063032, e62b0ac3, +112 more

---
### Insight (conf=0.78)
> Multi-agent architectures fail at the same structural point — ungraceful session death — whether from usage limits, credential blocks, or orchestrator crashes; the common fix is the same: agents must surface their blocked state explicitly and provide the exact resumption command rather than stalling silently.

**Rule:** Always design multi-agent handoffs with an explicit dead-man's switch: when an agent hits any blocking condition (usage limit, auth failure, orchestrator death), it must emit a structured status with the exact command needed to resume before stopping.

**Evidence:**
- _Pattern_: "When a main orchestrator session hits its usage limit while sub-agents are waiting on IPC responses, sub-agents are left blocked indefinitel…"
- _Pattern_: "Hitting a model subscription or usage limit mid-autonomous-session causes the session to stall silently rather than producing a graceful not…"
- _Pattern_: "When a sub-agent hits a credential or auth block that is outside its own scope to fix, the correct behavior is to surface the exact command …"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder--playwright-mcp, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (105): f4686e13, efd2a3ab, e6c58221, +102 more

---
### Insight (conf=0.75)
> The agent has a merge-by-default instinct that conflicts with the user's preference for keeping independent outputs separate until explicitly told to combine — whether it's two agents' plans, two comparison targets, or a dead peer's work — the user wants to see the pieces individually before any synthesis.

**Rule:** Always present independently-produced outputs side-by-side without merging unless the user explicitly requests synthesis — comparison is not combination, and selective triage is not wholesale adoption.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast — not a merged synthesis; merging…"
- _Pattern_: "When incorporating a dead or unavailable peer agent's work, selectively triage it for only the parts worth integrating rather than wholesale…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (7): dac333f4, 0c64e0da, 1a66d7a8, +4 more

---
### Insight (conf=0.73)
> The agent fails to model audience boundaries: conversational banter leaks into external documents, unsolicited risk judgments attach to factual answers, and internal commentary survives into stakeholder-facing output — all are failures to distinguish the current conversational register from the output's actual audience.

**Rule:** Always identify the downstream audience of any output before writing it — strip all conversational framing, internal commentary, and unsolicited evaluative judgments when the output will be read by anyone other than the current conversational partner.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When writing a document that will be shared externally, all internal banter, critique, and conversational framing about stakeholders must be…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked — never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, two-enhancement-product, better-file-browser, sys-monitor, its-my-config, staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (62): d8f1948c, a0f35401, 8c7e6f5c, +59 more

---
### Insight (conf=0.72)
> The agent's deferred-item workflow loses decision context at the handoff point: items are correctly queued per user preference, but when surfaced later they arrive stripped of the options and prior reasoning that would let the user act without a follow-up question — the deferral mechanism works but the recall mechanism is lossy.

**Rule:** Always include the original decision context, concrete options, and prior reasoning when surfacing a deferred item — a deferred item without actionable context is a question, not a queue entry.

**Evidence:**
- _Pattern_: "When presenting deferred decision items to the user, the agent omits the prior decision context and concrete options, forcing the user to as…"
- _Pattern_: "The user prefers a deferred review workflow: completed non-critical items should be queued to a 'to be reviewed' backlog rather than trigger…"
- _Pattern_: "Product-level behavioral decisions embedded in implementation (e.g., whether a user can add files to an existing job) must be surfaced as ex…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude-scripts-style, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Code-Claude-invasion-of-the-fiber-snatchers, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627-Code-Versable-enhancement-product-frontend
- _Sessions_ (115): f4686e13, efd2a3ab, e6c58221, +112 more

---
### Insight (conf=0.70)
> The agent batches status updates and output formatting into end-of-session or end-of-task dumps rather than streaming them incrementally, creating a mismatch with the user's preference for live, categorized, continuously-updated progress — whether it's task lists, review findings, or autonomous work cadence.

**Rule:** Always update task status and deliver findings incrementally as work completes rather than batching at the end — halt for user input only at genuine decision points, not at progress milestones.

**Evidence:**
- _Pattern_: "During autonomous multi-turn work sessions, the task list must be updated after each logical unit of work rather than batching updates at se…"
- _Pattern_: "When the user types a terse continuation signal ('proceed', 'keep going') and context pressure is below 70%, the agent must continue work im…"
- _Pattern_: "In multi-agent sessions, the user should not have to repeatedly give plain go-aheads for short-distance progress; batch sequential work into…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, i-dream, ghostty-themes, data-forge, .claude, alcatraz627, local-models, versable-builder, claude-instances, its-my-config, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627, staging-enhancement-product, two-enhancement-product, invasion-of-the-fiber-snatchers, frontend
- _Sessions_ (136): c250f2e7, c1ff831f, bf8b308d, +133 more

---
### Insight (conf=0.68)
> Multi-agent coordination degrades across session boundaries and auth boundaries in the same way: agents lose contact with peers after context-clear (no alias recorded), claim overlapping work without negotiation, and block on interactive auth mid-pipeline — all are failures to persist the coordination state that outlives any single agent turn.

**Rule:** Always persist multi-agent coordination state (peer aliases, task ownership claims, auth prerequisites) in a durable artifact that survives context-clear and session boundaries — coordination metadata that lives only in conversation context is lost at the worst possible time.

**Evidence:**
- _Pattern_: "In a multi-agent setup where sessions are regularly context-cleared, each agent's checkpoint should record the peer agent's IPC alias so the…"
- _Pattern_: "When multiple agents work in parallel on the same codebase, they must pre-negotiate task ownership via IPC before starting work; overlapping…"
- _Pattern_: "Interactive authentication flows embedded in deployment scripts (browser-redirect OAuth, gcloud auth login) block autonomous agent sessions …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, walmart-mvp
- _Sessions_ (38): d8f1948c, a0f35401, 8c7e6f5c, +35 more

---
### Insight (conf=0.65)
> Both patterns share a default-to-permissive failure: an access gate that allows unknown commands and a data pipeline that silently coerces nulls to default values are structurally identical — the system treats the absence of an explicit rule as permission to proceed rather than as a signal to block and surface the ambiguity.

**Rule:** Always default to DENY or BLOCK when encountering an unrecognized input (unknown command, null field, missing config) rather than falling through to a permissive default — the absence of an explicit handling rule is a signal to halt, not to proceed.

**Evidence:**
- _Pattern_: "When building an access-gate system, unrecognized commands must default to DENY, not ALLOW; a default-allow fallback for unknown CLIs create…"
- _Pattern_: "Null or missing fields in a data pipeline must be explicitly handled before numeric operations or display logic — when the agent notices a n…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627, frontend, enhancement-product, .claude, local-models, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder-packages-ui, studio_search_jul_26-fable, walmart-mvp
- _Sessions_ (69): fc013b76, a0f35401, 6b120b0a, +66 more

---


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
