
## Wake Cycle — 2026-04-14 16:12 UTC

### Insight (conf=0.82)
> The user has built a manual 'session persistence protocol' — core dump, catchup, continuation handoffs, and 'sorry continue' are all components of a human-engineered state management system compensating for AI's lack of persistent memory. This mirrors the exact same pattern as their SvelteKit data pipeline work: scrape (catchup), transform (re-orient context), upsert (continue where left off). The user is essentially running a 'data pipeline' on the AI itself, treating conversation state as data that needs ETL across context windows.

**Rule:** Treat the user's session management commands (core dump, catchup, sorry continue) as a formal protocol. When any of these are invoked, execute the corresponding phase precisely: core dump = serialize all active state/decisions/blockers; catchup = load and summarize without re-asking; sorry continue = resume exact last operation with zero preamble.

_Patterns: 584e7697-e747-48e6-9cd8-274ccffd99d8, f1057a8d-e978-416c-b52e-7ea8fd28e770, 2bca0a46-6579-4af7-a41c-44bfabdd7e70, ddce5474-8599-409f-a1fd-31f73445b461_

---
### Insight (conf=0.85)
> High tool-use sessions (50-103 tools) are the primary source of orphaned/zombie processes. The dev server on localhost:5173 combined with heavy multi-file refactoring creates a process management debt — background tasks complete silently while shell processes accumulate unnoticed. This is a 'garbage collection' problem: the system generates process debris proportional to task complexity, but has no automatic cleanup.

**Rule:** After any high tool-use turn (>20 tools), or when restarting the dev server, proactively check for and kill orphaned shell/node processes. Include a brief process cleanup summary. Treat process hygiene as a mandatory post-task step, not an optional one.

_Patterns: 1777377b-9097-421b-b159-d803db6676ea, 71584e9e-2556-4c0f-b671-ce1301df4e63, 255e5289-a615-46c4-875b-a0939b2211bd, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a_

---
### Insight (conf=0.88)
> The user's terse communication style ('please', 'just', 'those'), 'sorry continue' pattern, and duplicate message submissions all point to someone who is heavily multitasking and treating the AI as a co-pilot that should maintain state autonomously. Duplicate messages aren't confusion — they're impatient re-sends when the first didn't seem to register. The user's mental model is closer to a command-line interface than a conversation: commands in, results out, no ceremony.

**Rule:** Interpret all user messages as directives, not conversation starters. Never ask clarifying questions that could be resolved by examining project context. When a duplicate message arrives, silently treat the second as authoritative and proceed without commenting on the duplication. Keep responses action-oriented with minimal preamble.

_Patterns: 8a48f2a3-05bc-4565-b05e-00d28a1af177, ddce5474-8599-409f-a1fd-31f73445b461, e6db9887-7393-4f5c-b71d-840f5403166d_

---
### Insight (conf=0.65)
> The user's correction about single-source verification for news reveals a deeper epistemological principle they apply to their own data pipeline work: data integrity requires multi-source validation. Their scraping/transform pipeline for eBay/JEGS parts data likely faces the same problem — single-source product data can be stale, wrong, or incomplete. The user values cross-referencing as a general principle, not just for news. The permission issue pattern fits too: problems should be diagnosed from multiple angles, not assumed from a single symptom.

**Rule:** When reporting facts, diagnosing errors, or validating data pipeline outputs, always cross-reference multiple sources or checks before presenting conclusions. State the verification basis explicitly. This applies to code debugging (check logs AND state AND config), data quality (compare sources), and factual claims alike.

_Patterns: ef6f1e5e-411d-4460-919d-a15b9d09cb2f, e0efbf93-3db5-4ba7-b7b5-89640905ddd3, 2e13eec8-40bf-418e-9506-e5ba4d413e4e_

---
### Insight (conf=0.72)
> The user's preferences for clickable index HTML docs, dark/light mode, and XLSX exports all serve the same goal as their 'catchup' command: rapid re-orientation to complex state. Index pages with links = navigable project memory. XLSX exports = portable data snapshots (a 'core dump' for data). Dark/light mode = reducing friction for long sessions. These are all manifestations of a user who spends extended periods in deep work and optimizes ruthlessly for context-switching cost.

**Rule:** When generating any documentation, export, or UI artifact, optimize for scanability and rapid context recovery. Always include navigation/index structures in multi-page docs. Default to supporting both dark and light modes. Treat every output artifact as something the user will return to cold after hours or days away.

_Patterns: 7d59b38f-6578-4e5c-b7ea-533ca117d9ad, b944bcc7-d65b-42de-9013-c465888bfc75, cbe84ae7-774f-488f-aae2-6ffba44c3d13, 2bca0a46-6579-4af7-a41c-44bfabdd7e70_

---
### Insight (conf=0.78)
> The user's choice of Claude Opus for complex sessions, combined with multi-window continuations and 50-103 tool turns, suggests they are pushing against the fundamental limits of context windows as an architectural constraint. The 'core dump' command is essentially a manual checkpointing system — the same pattern used in distributed computing when processes might be killed and need to resume. The user is treating the AI session like a long-running batch job that could crash at any time, and has built crash-recovery infrastructure around it.

**Rule:** During high-complexity sessions, proactively offer mid-session state summaries (mini core dumps) at natural breakpoints — especially after completing a major sub-task or when tool count exceeds 40. Frame these as checkpoint saves, not interruptions. Include: what's done, what's in progress, what's next, and any blocking issues.

_Patterns: 3b921d16-b46c-4774-b2fe-71188ec21470, f1057a8d-e978-416c-b52e-7ea8fd28e770, 584e7697-e747-48e6-9cd8-274ccffd99d8, 71584e9e-2556-4c0f-b671-ce1301df4e63_

---
### Insight (conf=0.70)
> The combination of a complex SvelteKit app, data pipeline with scraping/transforms, XLSX exports, and terse user commands suggests this is likely a small business or solo operation where the user is simultaneously the product owner, developer, data engineer, and end user. The terse communication style isn't just personality — it's time pressure from wearing all hats. The eBay/JEGS parts data domain suggests automotive parts e-commerce, where data freshness and accuracy directly impact revenue.

**Rule:** Prioritize shipping over perfection. When multiple approaches exist, default to the one that produces working output fastest. The user's business likely depends on this pipeline running correctly, so treat data integrity bugs as high-severity and UI polish as lower priority unless explicitly requested.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, e0efbf93-3db5-4ba7-b7b5-89640905ddd3, cbe84ae7-774f-488f-aae2-6ffba44c3d13, 8a48f2a3-05bc-4565-b05e-00d28a1af177_

---


## Wake Cycle — 2026-04-14 16:13 UTC

### Insight (conf=0.95)
> The user has invented a manual 'session persistence protocol' (core dump → catchup) that mimics database transaction logging. This is essentially a human-designed write-ahead log (WAL) for AI context. The 'core dump' is the checkpoint write, and 'catchup' is the recovery/replay. This pattern emerges because context window limits force the user to become the persistence layer — the human is acting as the disk between volatile AI sessions.

**Rule:** When a session approaches 70% context usage, proactively offer to generate a structured state snapshot (like a WAL checkpoint) that includes: current task, blockers, recent decisions, file change summary, and next steps — formatted for optimal ingestion by the next session's catchup command.

_Patterns: 584e7697-e747-48e6-9cd8-274ccffd99d8, 2bca0a46-6579-4af7-a41c-44bfabdd7e70, 5c3499d0-aef9-4924-b559-e15bf88068ed, f1057a8d-e978-416c-b52e-7ea8fd28e770, 28b1145a-8c28-478d-8c2a-bc25d7da5eab_

---
### Insight (conf=0.92)
> The user's communication style (terse commands, 'sorry continue', explicit CORRECTIONs, minimal overhead preference) mirrors a command-line interface paradigm. They treat the AI assistant like a Unix shell — short imperative commands, interrupt/resume signals, and explicit error correction. This isn't just preference; it's an efficiency-maximizing protocol developed through high-volume tool-heavy sessions where verbosity wastes precious context window space.

**Rule:** Match the user's communication density. When the user sends a terse directive, respond with action first, explanation only if needed. Never ask clarifying questions that could be resolved by reading recent context. Treat 'sorry continue' as SIGCONT and resume the exact operation in progress.

_Patterns: 8a48f2a3-05bc-4565-b05e-00d28a1af177, ddce5474-8599-409f-a1fd-31f73445b461, 5c19b9a7-6c15-4698-954d-d60581fc7018, ad9fb072-5294-492c-a6b3-c2562125fab6_

---
### Insight (conf=0.88)
> There is a 'ghost state' anti-pattern across the entire stack: zombie shell processes, Playwright cache persistence, frontend caching issues, and dev server restarts all stem from the same root cause — stale state surviving across boundaries it shouldn't. The project has a systemic problem with state leaking between iterations. This is the 'cache invalidation is hard' problem manifesting at every layer simultaneously.

**Rule:** Before running tests, deployments, or major refactors, execute a 'clean slate' checklist: kill orphaned processes, clear Playwright cache, clear frontend/build caches, and restart dev server. Proactively do this rather than waiting for mysterious failures.

_Patterns: 1777377b-9097-421b-b159-d803db6676ea, be18cd2d-8a49-40fc-98c6-38e323904508, b6b68797-8bff-4e8e-b367-110f478596ad, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a_

---
### Insight (conf=0.62)
> The user applies the same epistemological principle to both data scraping and information verification: don't trust a single source. Spoofing real user behavior on automotive sites is about getting past gatekeepers to access ground truth; requiring multiple source verification for news is about the same thing — triangulating truth through redundant observation. The data pipeline's scrape-transform-upsert pattern is a formalized version of the multi-source verification approach applied to product data.

**Rule:** When scraping product data, build in cross-validation between sources (e.g., compare JEGS data against eBay listings for the same part number). When reporting on any external state (API status, current prices, news), always note the source and confidence level.

_Patterns: 0af4eedb-77ef-417d-a7c1-cf850d948a4f, ef6f1e5e-411d-4460-919d-a15b9d09cb2f, e0efbf93-3db5-4ba7-b7b5-89640905ddd3_

---
### Insight (conf=0.78)
> The async task notification pattern (fire-and-forget with 0-reply-char acknowledgements) is an emergent event-driven architecture within the AI session itself. The session has evolved into a message bus where the user is the orchestrator, background tasks are workers, and the AI is both a worker and a router. The high tool-count turns (50-103) represent batch processing bursts, while the 0-char notifications are heartbeats. This is essentially Kafka-in-a-chat-window.

**Rule:** When multiple parallel sub-tasks are running, maintain an internal task registry. On each notification receipt, update the registry silently. Only surface a summary when all tasks complete or when a failure requires intervention. Don't generate output for successful heartbeats.

_Patterns: 5eb7ad61-3993-45a1-adc5-801090d57609, 255e5289-a615-46c4-875b-a0939b2211bd, 17d7d163-8178-466f-8b80-ac9a0ca77757, 71584e9e-2556-4c0f-b671-ce1301df4e63_

---
### Insight (conf=0.82)
> UI iteration regressions and the need for repeated 'deep audit' passes suggest that the project lacks visual regression testing. The fallback to static/hardcoded values as a debugging strategy and the 'just worse' feedback pattern indicate the assistant is making changes without a reliable baseline to compare against. The deep audit cycles are compensating for the absence of snapshot testing.

**Rule:** Before making UI changes, capture the current visual state (screenshot or detailed description of key elements). After changes, explicitly compare against the baseline. When the user says something regressed, immediately offer to revert to the last known-good state before attempting fixes. Consider suggesting Playwright visual regression tests for critical UI components.

_Patterns: 98c09986-1196-42d7-b03c-a9e9055bd9b2, 27eacfef-fbb0-4fe3-aa4e-ca0fd4e35a1e, 68c55301-661d-403b-9c78-ca2db175a89d_

---
### Insight (conf=0.80)
> The user's strategic model switching (Opus for complex/deep work, Sonnet for lighter tasks) combined with documentation tasks requiring 40-78 tool calls and multiple continuations reveals a cost-optimization strategy that mirrors cloud compute spot-instance thinking. The user is treating AI models like compute tiers — using expensive 'instances' (Opus) only when the task complexity justifies it, and cheaper ones (Sonnet) for routine work. Context limit hits are the equivalent of spot instance preemptions.

**Rule:** For documentation generation and other high-tool-count tasks, proactively suggest breaking the work into Sonnet-appropriate chunks with clear handoff points, reserving Opus context for architectural decisions and complex debugging. Flag when a task is about to exceed a single context window so the user can decide whether to continue in Opus or switch.

_Patterns: 77e94f2c-f370-4a50-8c81-af479573573d, 3b921d16-b46c-4774-b2fe-71188ec21470, 5c3499d0-aef9-4924-b559-e15bf88068ed, 5ebb155f-41f7-4d7b-8f76-68cb84897b5f_

---
### Insight (conf=0.72)
> The user's documentation preferences (living documents, clickable index pages, dark/light mode) combined with the core dump pattern suggest they are building a 'second brain' system where both the project documentation AND the AI session state are meant to be human-browsable knowledge bases. The core dumps aren't just for the AI — they're for the user to review between sessions. The clickable index and dark mode preferences indicate someone who actually reads their own docs, possibly late at night.

**Rule:** Format core dumps and documentation with the assumption that a human will read them in a browser with dark mode. Include navigable structure (headers, links) rather than flat text. Make session state summaries scannable — use bullet points for decisions made, problems encountered, and next steps.

_Patterns: 6c1d1141-cca0-4465-b5cc-0798ac0c494f, 7d59b38f-6578-4e5c-b7ea-533ca117d9ad, b944bcc7-d65b-42de-9013-c465888bfc75, 584e7697-e747-48e6-9cd8-274ccffd99d8_

---
### Insight (conf=0.77)
> The combination of Drizzle ORM schema migrations, CI/CD pipeline work, XLSX export, and data pipeline transforms suggests this project is evolving from a scraping tool into a full data platform. The recurring XLSX export requirement indicates non-technical stakeholders who consume the data. The careful migration handling and CI/CD investment suggest the project is transitioning from 'hacker prototype' to 'production system' — and the pain points (zombie processes, cache issues, regressions) are growing pains of that transition.

**Rule:** When making architectural suggestions, bias toward production-readiness patterns: proper error handling, idempotent operations, migration rollback plans, and export format validation. The project has outgrown 'move fast and break things' — suggest guardrails proportional to the growing complexity.

_Patterns: 43ae3c67-dc14-4c50-b23d-2f2b17f4f725, 374f23a9-2051-4c1e-9eb5-e962349a3b8a, cbe84ae7-774f-488f-aae2-6ffba44c3d13, e0efbf93-3db5-4ba7-b7b5-89640905ddd3_

---
### Insight (conf=0.70)
> Duplicate message submissions, 'sorry continue' interruption recovery, and proactive permission issue resolution all point to a user who works in an environment with unreliable connectivity or who multitasks heavily across windows/contexts. The duplicate submissions are likely caused by network timeouts triggering re-sends, and the 'sorry continue' pattern suggests the user frequently context-switches away and back. The assistant should be resilient to 'noisy channel' communication — like TCP over a lossy link.

**Rule:** Implement idempotent response behavior: if a duplicate message arrives, acknowledge it briefly and continue the prior thread. When the user returns after an interruption, provide a one-line status update before continuing work. Don't wait for the user to ask where things stand.

_Patterns: e6db9887-7393-4f5c-b71d-840f5403166d, ddce5474-8599-409f-a1fd-31f73445b461, 2e13eec8-40bf-418e-9506-e5ba4d413e4e_

---


## Wake Cycle — 2026-04-14 16:29 UTC

### Insight (conf=0.88)
> The user's entire workflow is organized around state serialization/deserialization cycles (core dump → catchup) because context is the most fragile and valuable resource. This mirrors the same fragility seen in git worktree state loss and the multi-source verification correction — in all cases, the root problem is that implicit state gets silently lost. The user has learned to distrust implicit persistence everywhere and demands explicit checkpointing as a universal principle.

**Rule:** Treat all state as ephemeral by default. Before any context-destroying operation (session end, branch switch, worktree change, deployment), explicitly serialize and confirm preservation of current state. Never assume state will survive a transition.

_Patterns: 584e7697-e747-48e6-9cd8-274ccffd99d8, da2de271-e256-4cf3-b667-f87f371bcf02, 5c3499d0-aef9-4924-b559-e15bf88068ed, ef6f1e5e-411d-4460-919d-a15b9d09cb2f, 5287886b-6995-4b9f-a22f-38e91d2a0ce4_

---
### Insight (conf=0.85)
> The user operates in two distinct modes: a 'high-autonomy cruise control' mode (terse commands like 'keep going', 'more', tolerating 100+ tool calls) and a 'strict boundary' mode (correcting scope, demanding minimal changes). The terse communication isn't laziness — it's a trust-based protocol. Short commands signal 'you have autonomy within the current vector,' while explicit corrections signal 'you've drifted outside the vector.' The user is essentially implementing a PID controller: minimal intervention when on-track, sharp correction when off-track.

**Rule:** Interpret message length as an autonomy signal. Terse continuation messages ('keep going', 'more', 'please') mean stay on current trajectory with full autonomy. Explicit corrections or detailed instructions mean the trajectory has drifted — reduce autonomy, confirm scope, and make minimal targeted changes until trust is re-established.

_Patterns: 8a48f2a3-05bc-4565-b05e-00d28a1af177, edaeaf8c-9b6e-4652-b777-ccedba905520, ddce5474-8599-409f-a1fd-31f73445b461, 86e6683c-0a66-4f68-98ed-37c7e07c715e, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.82)
> There's a 'phantom state' anti-pattern across the entire stack: Playwright caches, Next.js/Vercel caches, ESLint config caching, session hook state, and deployment branch blacklists all share the same failure mode — stale cached state masquerading as current reality. Every debugging dead-end in this project likely starts with 'the code is correct but something cached is lying.' This is the infrastructure-level mirror of the session continuity problem.

**Rule:** When debugging any failure where the code appears correct, check for stale cached state FIRST before investigating code logic. Maintain a checklist of known cache layers (Playwright, Next.js/.next, Vercel build cache, ESLint cache, browser cache, dev server HMR state) and clear them systematically as step zero of debugging.

_Patterns: be18cd2d-8a49-40fc-98c6-38e323904508, b6b68797-8bff-4e8e-b367-110f478596ad, 295c0bce-0897-4663-8f79-bd54afd7579b, 2773a5b3-65d8-45a3-b9ad-933d815a2850, 1e71103e-781a-418b-ad01-299c33d2bed0_

---
### Insight (conf=0.87)
> The user's UI workflow is fundamentally adversarial to the agent's natural tendency to 'improve' things. The user iterates visually through small nudges ('better', 'revert colors', 'increase font') but the agent's instinct is to batch-optimize, add polish, and over-engineer. Every unsolicited enhancement (animations, visual effects) and every regression ('just worse') is the same collision: the user is sculpting clay incrementally while the agent tries to deliver a finished statue. The 'deep audit' pattern is the user's compromise — they want thoroughness, but on their schedule and scope.

**Rule:** For UI work, make exactly the change requested and nothing more — no 'while I'm here' improvements. Present the minimal diff. If you see obvious improvements, mention them as suggestions in text rather than implementing them. Wait for explicit 'deep audit' or similar commands before doing comprehensive passes.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, 98c09986-1196-42d7-b03c-a9e9055bd9b2, b4abf703-dfb0-4b24-bac3-1bd1e70703f7, 591772d9-3bb3-4daa-aaba-7e1cf4618ae9, 27eacfef-fbb0-4fe3-aa4e-ca0fd4e35a1e_

---
### Insight (conf=0.78)
> The user has built a personal 'operating system' for AI interaction: 'pick skill' sets the persona/mode, 'catchup' loads context, model switching (opus/sonnet) allocates compute resources, 'core dump' saves state. This is isomorphic to a real OS: process initialization → memory load → CPU scheduling → checkpoint/swap. The user is unconsciously (or consciously) treating the AI as a process that needs explicit lifecycle management because it lacks persistent memory.

**Rule:** Recognize and optimize for the user's session lifecycle protocol: (1) catchup = boot/context load — be fast and complete, (2) pick skill = process mode — lock into the persona, (3) terse commands = runtime execution — maintain high autonomy, (4) core dump = checkpoint — serialize comprehensively. Treat violations of this lifecycle (e.g., starting work without catchup, ending without core dump) as potential errors worth flagging.

_Patterns: 9334a969-ce7a-4286-90a9-f90fe26e1341, 77e94f2c-f370-4a50-8c81-af479573573d, 584e7697-e747-48e6-9cd8-274ccffd99d8, ef6f1e5e-411d-4460-919d-a15b9d09cb2f, 5ac572b8-2860-4b61-b617-5214c9898c3a_

---
### Insight (conf=0.75)
> There's a tension between the user's preference for sequential single-agent work and the existence of parallel async task infrastructure. The async task system exists but generates zombie processes and silent completions that need cleanup. The user prefers sequential work not because they don't understand parallelism, but because parallel execution creates orphaned state that violates their 'explicit state management' philosophy. Parallelism is only acceptable when it has clean lifecycle management (which it currently doesn't).

**Rule:** Only use parallel agents/tasks when: (1) the tasks are truly independent with no shared state, (2) each task has explicit completion signaling, and (3) cleanup of spawned processes is guaranteed. Default to sequential execution. If parallel execution is used, proactively check for and clean up zombie processes afterward.

_Patterns: 5eb7ad61-3993-45a1-adc5-801090d57609, 255e5289-a615-46c4-875b-a0939b2211bd, d07aa0a9-3da8-4d4c-8ae0-49b83d530ac6, 1777377b-9097-421b-b159-d803db6676ea_

---
### Insight (conf=0.83)
> The extremely high tool counts (50-229 per turn) combined with frequent context window exhaustion and multi-session continuations suggests that the user's projects are systematically at the boundary of what single-context AI sessions can handle. The 'incremental commit' preference isn't just about git hygiene — it's a survival strategy. Each commit is a savepoint that reduces the blast radius of a context window death. Documentation generation requiring 40-78 tool calls across multiple sessions is a canary: if documenting the work takes multiple sessions, the work itself is pushing fundamental limits.

**Rule:** For any task estimated to require >30 tool calls, proactively create intermediate checkpoints: commit partial progress, update notes, and produce a mini core dump at natural breakpoints. Don't wait for context exhaustion — treat every 40-50 tool calls as a checkpoint boundary. Structure work to be resumable from any checkpoint.

_Patterns: 00fb690c-b719-4a18-ad08-94adf937ae00, f1057a8d-e978-416c-b52e-7ea8fd28e770, 5ebb155f-41f7-4d7b-8f76-68cb84897b5f, fff0361d-bc74-4ca8-9f73-b9d5e0944f32, b17eede3-c8e7-4e88-a7cb-a1aac4c9f8a3_

---
### Insight (conf=0.72)
> The user is building a SvelteKit app that they actively test on mobile devices (hence the localhost accessibility and mobile navbar/hamburger menu requests). The false assumption about browser testing availability combined with the network configuration needs suggests the user has a more sophisticated local dev environment than the agent typically assumes. The UI requests (dark theme, tooltips, collapsible drawers) are likely driven by real mobile usage, not abstract design preferences.

**Rule:** When working on UI features, assume the user is testing on both desktop and mobile devices in real-time. Prioritize mobile-responsive implementations. Before making assumptions about the testing environment, ask or verify what's available rather than assuming limitations.

_Patterns: b6e83ca3-bb7d-4846-a222-858562313e2a, ad00c9dd-116d-497d-8d9c-eef93fce6609, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, 082e01ad-9c3a-48e3-9b66-6b96de0d56c5_

---
### Insight (conf=0.80)
> The user has developed a micro-language of control signals: 'CORRECTION' = hard stop and redirect, 'keep going' = maintain trajectory, 'sorry continue' = resume exactly, short words = inferred context. The user's explicit separation of implementation from documentation ('update notes after') reveals a deeper pattern: they want precise control over WHEN side effects happen, not just WHAT happens. The agent's tendency to bundle related work (implement + document + enhance) violates this temporal control preference.

**Rule:** Separate concerns temporally: do exactly the requested action, then stop and report. Don't bundle implementation with documentation updates, test writing, or cleanup unless explicitly asked. The user will request secondary actions (notes, docs, tests) as separate explicit steps when they're ready for them.

_Patterns: 5c19b9a7-6c15-4698-954d-d60581fc7018, ff7b37a5-17ae-466e-b55e-585866af824b, 9f41a150-aba6-4ecc-bc12-8a17638ce7e9, edaeaf8c-9b6e-4652-b777-ccedba905520_

---
### Insight (conf=0.70)
> The project (SvelteKit + data pipeline + eBay/JEGS parts + XLSX export + CI/CD) is essentially an e-commerce data aggregation platform. The recurring XLSX export need combined with the data pipeline work suggests the end users are parts buyers/sellers who work in spreadsheets. The multi-session continuity overhead is disproportionately caused by the data pipeline complexity — scraping, transforming, and upserting product data with attributes creates deeply interleaved state that's hard to checkpoint. The CI/CD work suggests the project is approaching or past MVP and moving toward production reliability.

**Rule:** When working on data pipeline features, prioritize idempotency and resumability in the pipeline itself (not just session state). Each pipeline stage should be independently re-runnable. XLSX export should be treated as a first-class output format, not an afterthought, since it's likely the primary way end users consume the data.

_Patterns: e0efbf93-3db5-4ba7-b7b5-89640905ddd3, cbe84ae7-774f-488f-aae2-6ffba44c3d13, b76b7252-944d-49f8-bb01-fa76c140a694, 374f23a9-2051-4c1e-9eb5-e962349a3b8a, 17c93150-f458-4f67-aa2d-6debc49c2687_

---


## Wake Cycle — 2026-04-14 16:29 UTC

### Insight (conf=0.78)
> The user's terse communication style ('keep going', 'move', 'sorry continue') is not just preference but an emergent optimization against context window scarcity. Every token the user spends on instructions is a token not available for work output. The user has evolved a minimalist command language that functions like a compressed instruction set — essentially treating the AI session as a constrained computing environment where input bandwidth must be minimized. This mirrors how embedded systems use compact opcodes.

**Rule:** Treat terse user commands as high-priority compressed instructions. Never ask for clarification on known continuation commands ('keep going', 'continue', 'move', 'more'). Maximize work output per user token spent. Reserve verbose communication for truly ambiguous situations only.

_Patterns: edaeaf8c-9b6e-4652-b777-ccedba905520, 8a48f2a3-05bc-4565-b05e-00d28a1af177, 2dfa1a6e-03f6-473e-8476-8a5da501300e, ddce5474-8599-409f-a1fd-31f73445b461, 9b7e0ad0-3043-484f-af71-f2d94eea7ed0_

---
### Insight (conf=0.72)
> There is a recurring 'state loss' anti-pattern across multiple layers: unstaged git changes get lost during worktree switches, session context gets lost at context boundaries, and zombie processes accumulate as orphaned state. All three are manifestations of the same fundamental problem — transitions between contexts (git branches, AI sessions, shell processes) that don't properly serialize and clean up state. The core dump command is the user's explicit solution for one layer; the same principle should be applied systematically to all layers.

**Rule:** Before ANY context transition (session end, git worktree switch, process restart), execute a state-preservation checklist: (1) check for unstaged changes, (2) check for running background processes, (3) serialize current task state. Treat all transitions as potential data loss events.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, 1777377b-9097-421b-b159-d803db6676ea, f1b15033-a4e3-4a70-84fa-4de726a42926_

---
### Insight (conf=0.85)
> The user has a strong 'conservation of agency' principle: they want to retain decision-making authority over scope, approach, and parallelism. Unsolicited enhancements, autonomous refactors, and parallel agent spawning all violate this principle. The user treats the AI as a precision tool (scalpel) not an autonomous agent (autopilot). This is philosophically consistent with their preference for sequential work and minimal changes — they want high control fidelity.

**Rule:** Never expand scope beyond what was explicitly requested. When tempted to add an enhancement, refactor, or spawn parallel work, stop and ask. The user's trust model is 'do exactly what I said, nothing more, and do it well.' Violations of this principle erode trust more than incomplete work does.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, b4abf703-dfb0-4b24-bac3-1bd1e70703f7, 591772d9-3bb3-4daa-aaba-7e1cf4618ae9, d07aa0a9-3da8-4d4c-8ae0-49b83d530ac6_

---
### Insight (conf=0.70)
> The user's iterative UI refinement pattern ('better', 'good but...', 'revert colors') functions like a human-in-the-loop gradient descent. They cannot fully specify the target state upfront but can evaluate each step and provide directional feedback. This is fundamentally different from implementation tasks where specs are clear. The agent should recognize when it's in 'gradient descent mode' (UI/visual work) vs 'execution mode' (pipeline/backend work) and adjust its response strategy accordingly — smaller steps with visual checkpoints in the former, larger autonomous runs in the latter.

**Rule:** For UI/visual tasks, make small incremental changes and present results for feedback before proceeding. For backend/pipeline tasks where the user says 'keep going', execute in larger autonomous batches. Detect which mode you're in based on the task domain and the user's feedback pattern.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, 082e01ad-9c3a-48e3-9b66-6b96de0d56c5, b6e83ca3-bb7d-4846-a222-858562313e2a_

---
### Insight (conf=0.55)
> There is a tension between the system's multi-agent/parallel task architecture (which generates many async notifications) and the user's explicit preference against parallel agents. The task notification system exists and generates significant traffic, but the user wants sequential single-agent work. This suggests the parallel infrastructure may have been set up speculatively or for a specific use case, and the volume of silent 0-tool notifications may itself be consuming context budget wastefully. The async task system may be an architectural liability rather than an asset for this user's workflow.

**Rule:** Minimize parallel task spawning. When async task notifications arrive with 0 tools/0 reply, acknowledge them silently and do not let them consume context. Consider whether the task notification system could be configured to batch or suppress routine completion signals.

_Patterns: 5eb7ad61-3993-45a1-adc5-801090d57609, 2e7d5054-603d-4ba1-92cb-41bca5de2463, f070277f-8098-4fa2-841e-46ad12536415, d07aa0a9-3da8-4d4c-8ae0-49b83d530ac6_

---
### Insight (conf=0.60)
> The user has built a meta-workflow for managing AI capabilities: 'pick skill' for persona selection, model switching for cost/capability tradeoffs, 'core dump' for state persistence, and 'catchup' for state restoration. This is essentially a manual operating system for AI sessions — process scheduling (model selection), memory management (core dump/catchup), and capability loading (pick skill). The user is unconsciously building an OS abstraction layer over the AI interaction.

**Rule:** Recognize and support the user's meta-workflow commands as first-class operations. When 'pick skill' is issued, fully commit to the persona. When 'core dump' is issued, be exhaustively thorough. When model is switched to opus, assume the task requires deeper reasoning. These are the user's 'system calls' — treat them with the reliability expected of an OS interface.

_Patterns: 9334a969-ce7a-4286-90a9-f90fe26e1341, 77e94f2c-f370-4a50-8c81-af479573573d, 584e7697-e747-48e6-9cd8-274ccffd99d8, ef6f1e5e-411d-4460-919d-a15b9d09cb2f_

---
### Insight (conf=0.50)
> Documentation generation requiring 40-78 tool calls and multiple session continuations is disproportionately expensive relative to its value. The high tool-call cost suggests documentation is being generated by reading and processing the entire codebase each time rather than being maintained incrementally. If the core dump mechanism already captures structured state, documentation could be generated as a byproduct of core dumps rather than as a separate expensive pass — amortizing the cost across sessions rather than concentrating it.

**Rule:** When executing core dumps, append a structured documentation delta (what changed this session, what was implemented, what's pending) that can be concatenated into running documentation. This reduces the need for expensive dedicated documentation generation sessions.

_Patterns: 5ebb155f-41f7-4d7b-8f76-68cb84897b5f, 5c3499d0-aef9-4924-b559-e15bf88068ed, 86e6683c-0a66-4f68-98ed-37c7e07c715e, 1db8913f-fb99-4f99-b283-177336d37471_

---
### Insight (conf=0.75)
> Cascading configuration errors (hook initialization, ESLint, Next.js bundling) share a common root cause: assumptions about environment state that are not verified. The session hook error cascaded because initialization state was assumed, ESLint config errors persisted because the config change impact wasn't verified, and browser testing was assumed unavailable without checking. All three are instances of 'assumption debt' — where an unverified assumption compounds into multi-session debugging. The fix is the same in all cases: verify, don't assume.

**Rule:** Before debugging any configuration or environment issue, first verify the actual current state (run the config, check the process, test the environment). Never assume state based on prior session knowledge — it may have changed. Spend 1 tool call verifying before spending 16 debugging a phantom.

_Patterns: 2773a5b3-65d8-45a3-b9ad-933d815a2850, 295c0bce-0897-4663-8f79-bd54afd7579b, b6e83ca3-bb7d-4846-a222-858562313e2a_

---
### Insight (conf=0.68)
> The user is simultaneously running at least two major projects (SvelteKit data pipeline/web app AND geopolitical simulation) plus maintaining strong opinions about dev tooling (Zellij, Ghostty). This suggests a power-user who context-switches between projects frequently, which amplifies the core dump/catchup pattern's importance — it's not just session continuity within a project but project-switching continuity. Core dumps should include project identification to avoid cross-contamination of context.

**Rule:** Always identify the active project at session start during catchup. Core dumps should prominently label which project they belong to. When a session starts with 'catchup', verify which project the user intends to work on before loading context, especially if recent sessions span multiple projects.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, 0808b72d-b9fe-4a81-ab98-9527f788595e, 4b14eec9-83e7-4004-ae67-fa3f9bfd17b2_

---
### Insight (conf=0.73)
> The user's preference for documentation as a separate explicit step, minimal changes only, and no autonomous scope expansion all point to a 'clean separation of concerns' philosophy applied to the AI interaction itself. Implementation, documentation, and refactoring are distinct phases that should not bleed into each other. This mirrors good software engineering (single responsibility principle) applied to the human-AI collaboration workflow.

**Rule:** Treat implementation, documentation, testing, and refactoring as separate phases. Never combine them unless explicitly asked. When finishing an implementation task, stop and report — don't auto-document or auto-refactor. Wait for the user to explicitly request the next phase.

_Patterns: 9f41a150-aba6-4ecc-bc12-8a17638ce7e9, ff7b37a5-17ae-466e-b55e-585866af824b, 591772d9-3bb3-4daa-aaba-7e1cf4618ae9_

---


## Wake Cycle — 2026-04-15 00:49 UTC

### Insight (conf=0.72)
> The user's geopolitical simulation project — modeling multi-agent state persistence across turns — mirrors the meta-problem they face with Claude itself: both systems need robust state serialization across context boundaries. The WAL/checkpoint infrastructure is essentially the same architectural problem as save-game state in their simulation. They may have unconsciously designed their Claude workflow to match the domain they're building in.

**Rule:** When building state persistence features in the simulation project, cross-reference patterns from the session continuity infrastructure (WAL, core-dump, catchup) — the problems are isomorphic and solutions may transfer bidirectionally.

_Patterns: 881b161f-3ee0-4597-ab7b-d6c2a860613d, 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, 1523746a-7091-4022-b130-7e28b7f77561_

---
### Insight (conf=0.88)
> The user's terse command style ('keep going', 'move', 'started') combined with tolerance for 50-150+ tool-call sessions reveals they treat Claude as a coprocessor, not a conversational partner. They issue opcodes, not sentences. The communication protocol is closer to a job scheduler (submit job → monitor → resume) than a chat. This means response verbosity is waste — every word the agent outputs that isn't status or a result is overhead in their mental model.

**Rule:** When the user issues a single-word or two-word directive, treat it as a job resumption signal: reconstruct intent from WAL/checkpoint state, emit a one-line acknowledgment, and begin execution. Do not ask clarifying questions unless genuinely blocked.

_Patterns: edaeaf8c-9b6e-4652-b777-ccedba905520, 8a48f2a3-05bc-4565-b05e-00d28a1af177, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 86e6683c-0a66-4f68-98ed-37c7e07c715e, ddce5474-8599-409f-a1fd-31f73445b461_

---
### Insight (conf=0.85)
> All four 'negative valence' corrections share a root cause: the agent acted on stale or inferred state instead of verifying current reality. Git worktree lost unstaged changes (assumed clean), wrong repo owner (inferred from memory), unsolicited animations (inferred user desire), scope creep (inferred expanded intent). The pattern is 'inference without verification' — the agent's greatest failure mode is confident extrapolation from incomplete context.

**Rule:** Before any destructive, creative, or scope-expanding action, verify the current state of the specific artifact being touched (git status, file read, explicit user confirmation). Never infer intent, cleanliness, or ownership from prior context alone.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, b4abf703-dfb0-4b24-bac3-1bd1e70703f7, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.82)
> There's a tension between the user's iterative UI refinement style ('better', 'good but...', 'revert colors') and their insistence on minimal changes with no scope creep. The resolution: the user wants to be the architect of incremental change — they control the delta. The agent should apply exactly the requested micro-change and stop, letting the user steer the next increment. The agent adding unsolicited 'improvements' breaks this steering loop.

**Rule:** In UI refinement loops, apply only the literal change requested. Never bundle aesthetic 'improvements' or 'while we're here' fixes. Present the result and wait — the user will issue the next micro-directive if they want more.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, 591772d9-3bb3-4daa-aaba-7e1cf4618ae9, b4abf703-dfb0-4b24-bac3-1bd1e70703f7, 84453a6d-54fb-45f2-9371-6b010b252776_

---
### Insight (conf=0.65)
> Context limits, hook cascading failures, and task notification noise are all symptoms of the same underlying problem: the agent infrastructure lacks backpressure. Context fills up without proactive compaction, hooks error-cascade without circuit breakers, and task notifications accumulate without filtering. The user has built manual backpressure (core-dump at milestones, not just at end) but the system itself doesn't self-regulate.

**Rule:** Implement proactive context hygiene: trigger a lightweight checkpoint every ~30 tool calls (not just at user request or session end), suppress task notification processing when >5 arrive in a burst, and add a 'hook health check' at session start to catch cascade risks early.

_Patterns: e218ac38-3844-4295-a972-c9dc01b22d13, 5c3499d0-aef9-4924-b559-e15bf88068ed, 2773a5b3-65d8-45a3-b9ad-933d815a2850, f070277f-8098-4fa2-841e-46ad12536415_

---
### Insight (conf=0.78)
> The user says they prefer sequential single-agent work, yet parallel sub-agents are observed as 'effective' for large docs/audits. The reconciliation: the user dislikes parallel agents for implementation (where they want steering control) but tolerates them for read-only bulk operations (documentation, audits) where the output is a report, not code changes. The preference is about control, not parallelism per se.

**Rule:** Use parallel sub-agents only for read-only, report-generating tasks (audits, documentation, codebase analysis). For any task that writes code or modifies state, use sequential single-agent execution so the user retains steering control at each step.

_Patterns: d07aa0a9-3da8-4d4c-8ae0-49b83d530ac6, 9e486a20-41bf-4d37-92de-95175dadb92e, 5eb7ad61-3993-45a1-adc5-801090d57609_

---
### Insight (conf=0.70)
> The user actively curates their toolchain at a meta-level: model switching (opus/sonnet for cost), persona selection (pick-skill), terminal multiplexer choice (Zellij over tmux). This is someone who optimizes the tool, not just what the tool produces. They likely value transparency about resource consumption (tokens, time, cost) and would appreciate the agent surfacing these tradeoffs proactively.

**Rule:** When a task could be done with either a heavy approach (many tool calls, opus-level reasoning) or a lighter one, briefly surface the tradeoff: 'This could be done in ~10 tool calls with X approach or ~40 with Y — which do you prefer?' Match the user's meta-optimization mindset.

_Patterns: 77e94f2c-f370-4a50-8c81-af479573573d, 9334a969-ce7a-4286-90a9-f90fe26e1341, 4b14eec9-83e7-4004-ae67-fa3f9bfd17b2_

---
### Insight (conf=0.80)
> The user's corrections form a coherent trust model: execute commands silently when directed (commit and push), but never exceed the boundary of what was asked. This is the 'trusted executor' pattern — high autonomy within scope, zero autonomy outside scope. The multi-source verification correction extends this to information too: don't just execute confidently, verify confidently. Trust is earned per-action, not blanket.

**Rule:** Operate as a 'trusted executor': within the explicitly requested scope, act decisively without confirmation. Outside that scope, stop completely — do not suggest, preview, or 'while we're here'. The boundary between inside and outside scope must be interpreted conservatively.

_Patterns: 8dc7fecd-8bd3-4317-91d9-d90453e3364f, ff7b37a5-17ae-466e-b55e-585866af824b, 84453a6d-54fb-45f2-9371-6b010b252776, ef6f1e5e-411d-4460-919d-a15b9d09cb2f_

---
### Insight (conf=0.73)
> The high volume of zero-content task notifications and the high tool-call counts are consuming context budget that could extend session life. The irony: the infrastructure built to manage session continuity (parallel tasks, notifications) is itself a contributor to hitting context limits sooner, creating more need for the very core-dump/catchup cycle it was meant to reduce.

**Rule:** Batch-suppress task notification acknowledgments — instead of processing each individually, accumulate them and emit a single summary ('4 tasks completed: X, Y, Z, W') to reduce context consumption. Target: save ~15-20% of context budget currently spent on notification round-trips.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, f070277f-8098-4fa2-841e-46ad12536415, 5c3499d0-aef9-4924-b559-e15bf88068ed, 1db8913f-fb99-4f99-b283-177336d37471_

---


## Wake Cycle — 2026-04-15 08:23 UTC

### Insight (conf=0.72)
> Context limits and git worktree issues share a root cause: state boundaries are invisible cliffs. Just as git worktree silently loses unstaged changes when switching, context compaction silently loses trailing specifics. Both are 'boundary crossing' failures where the system doesn't checkpoint before transitioning. The git owner verification issue is the same pattern in a third domain — inferring state across a boundary instead of re-reading it.

**Rule:** Before any boundary crossing (context compaction, worktree switch, repo/branch switch, session continuation), run an explicit 'pre-flight check': verify uncommitted state, confirm target identity, and write a checkpoint. Never rely on carried-forward assumptions across boundaries.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, e218ac38-3844-4295-a972-c9dc01b22d13, 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.55)
> The high volume of fire-and-forget task notifications (0 tools, 0 reply chars) combined with 50-150+ tool sessions suggests the system is evolving toward an 'event-driven microkernel' architecture where the agent is a scheduler dispatching and acknowledging async work, not a synchronous executor. Most of the agent's 'work' is actually coordination overhead, not implementation.

**Rule:** Track the ratio of coordination events (task notifications, sub-agent dispatches) to actual implementation tool calls per session. If coordination exceeds 40% of total events, the task decomposition is too granular — consolidate sub-tasks into fewer, larger units.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, f070277f-8098-4fa2-841e-46ad12536415, 5eb7ad61-3993-45a1-adc5-801090d57609, 86e6683c-0a66-4f68-98ed-37c7e07c715e_

---
### Insight (conf=0.82)
> Four independent corrections converge on a single personality trait: the user has a strong 'sovereignty boundary' — they want the agent to be a precise tool, not an autonomous collaborator. Unsolicited animations, scope expansion, autonomous implementation, and large refactors all violate the same principle: the agent acted on its own judgment instead of the user's explicit instruction. This isn't about code quality — it's about agency and control.

**Rule:** Default to 'scalpel mode': do exactly what was asked, nothing more. Before adding anything not explicitly requested — even if it seems obviously beneficial — ask. The cost of asking is near-zero; the cost of overstepping is trust erosion.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, b4abf703-dfb0-4b24-bac3-1bd1e70703f7, 84453a6d-54fb-45f2-9371-6b010b252776, 591772d9-3bb3-4daa-aaba-7e1cf4618ae9_

---
### Insight (conf=0.68)
> Apparent contradiction: user dislikes parallel agents BUT acknowledges they're effective for docs/audits. Combined with strategic model switching (opus vs sonnet) and terse communication style, this reveals a resource-optimization mindset — the user thinks in cost/benefit terms. Parallel agents aren't disliked in principle; they're disliked when the overhead (coordination noise, context fragmentation) exceeds the speedup. The user is essentially doing manual 'scheduling' — picking the right model and concurrency level per task.

**Rule:** Only propose parallel agents when: (a) sub-tasks are truly independent with no shared state, (b) each sub-task would take 20+ tool calls sequentially, and (c) the total is 3 or fewer agents. For everything else, default to sequential. Frame the proposal in cost/benefit terms the user already thinks in.

_Patterns: d07aa0a9-3da8-4d4c-8ae0-49b83d530ac6, 9e486a20-41bf-4d37-92de-95175dadb92e, 8a48f2a3-05bc-4565-b05e-00d28a1af177, 77e94f2c-f370-4a50-8c81-af479573573d_

---
### Insight (conf=0.60)
> The core-dump/catchup cycle is essentially a hand-rolled 'process hibernation' protocol — the user has reinvented OS-level suspend/resume at the AI session layer because the platform doesn't natively support it. The low-signal extraction warning pattern suggests the hibernation image is lossy, similar to how early OS hibernation lost GPU state. The system needs a 'hibernation fidelity score' to know how much context survived the round-trip.

**Rule:** When performing /catchup, compute and report a 'restoration confidence' score based on: age of last checkpoint (hours), number of compactions since checkpoint, presence of WAL entries, and completeness of file references. Display as a single line: 'Restoration confidence: HIGH/MEDIUM/LOW — [reason]'. This tells the user whether to trust the restored context or re-brief.

_Patterns: 584e7697-e747-48e6-9cd8-274ccffd99d8, da2de271-e256-4cf3-b667-f87f371bcf02, f1b15033-a4e3-4a70-84fa-4de726a42926, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.58)
> Hook initialization errors and context limit hits are both 'infrastructure reliability' failures that block the primary workflow. The user has built WAL/checkpoint infrastructure to survive context limits, but hook failures have no equivalent recovery path — they cascade and require manual debugging. The infrastructure layer (hooks, WAL, checkpoints) needs the same fault-tolerance design as the application layer.

**Rule:** Hooks should fail open, not closed. If a SessionStart hook errors, log the failure to WAL but proceed with the session — never block session start on hook success. Treat hook infrastructure with the same 'checkpoint before boundary crossing' discipline as context management.

_Patterns: 2773a5b3-65d8-45a3-b9ad-933d815a2850, 5c3499d0-aef9-4924-b559-e15bf88068ed, 1523746a-7091-4022-b130-7e28b7f77561_

---
### Insight (conf=0.62)
> The user has developed a personal 'boot sequence' — catchup, pick-skill, then terse continuation commands — that mirrors how an operating system initializes: load state from disk (catchup), set execution mode (pick-skill), then run (terse commands). The 'sorry continue' pattern is a soft reboot. This boot sequence is informal and fragile; formalizing it would reduce the cognitive load of session starts.

**Rule:** Detect the 'boot sequence' pattern automatically: if the first message is /catchup or contains 'continued from', immediately follow with a one-line status and ask 'Resume [last task] or new direction?' — skip the verbose context dump unless requested. Optimize for the 90% case where the user just wants to keep going.

_Patterns: ddce5474-8599-409f-a1fd-31f73445b461, 2dfa1a6e-03f6-473e-8476-8a5da501300e, ef9a0ad9-13be-470f-9881-2b6c679d640b, 9334a969-ce7a-4286-90a9-f90fe26e1341_

---
### Insight (conf=0.75)
> Three corrections form an 'autonomy calibration' spectrum: too much autonomy on commits (should be silent), too much autonomy on implementation (should ask first), too little diligence on verification (should check multiple sources). The user doesn't want less agent autonomy uniformly — they want autonomy precisely calibrated per action type: mechanical actions (git) = full auto, creative actions (code changes) = ask first, epistemic actions (fact claims) = verify thoroughly.

**Rule:** Classify each action as mechanical (git ops, file moves, formatting), creative (new code, refactors, UI changes), or epistemic (factual claims, current events, status reports). Mechanical = execute silently. Creative = confirm scope before acting. Epistemic = verify from multiple sources before stating.

_Patterns: ef6f1e5e-411d-4460-919d-a15b9d09cb2f, 8dc7fecd-8bd3-4317-91d9-d90453e3364f, ff7b37a5-17ae-466e-b55e-585866af824b_

---


## Wake Cycle — 2026-04-15 13:21 UTC

### Insight (conf=0.72)
> The user's terse, incremental communication style ('keep going', 'better', 'more') combined with iterative UI refinement suggests a REPL-like mental model for development — they treat the AI as an interactive interpreter where each message is a small delta, not a full specification. This is the opposite of the 'write a detailed spec upfront' pattern and requires the agent to maintain high-fidelity running state of intent.

**Rule:** When receiving terse continuation commands, reconstruct the full intent from the last 3-5 exchanges before acting — never ask 'what do you mean?' for messages like 'more' or 'keep going'. Maintain an implicit intent stack.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, edaeaf8c-9b6e-4652-b777-ccedba905520, 8a48f2a3-05bc-4565-b05e-00d28a1af177, 2dfa1a6e-03f6-473e-8476-8a5da501300e_

---
### Insight (conf=0.82)
> The extremely high tool-call counts (50-157) directly cause the context limit hits, which drive the session continuation pattern. This is a feedback loop: complex tasks require many tools → context fills → session breaks → state must be reconstructed → more tools for reconstruction → faster context fill in the next window. The user's workflow is stuck in an amplifying cycle.

**Rule:** When a session exceeds 40 tool calls, proactively checkpoint AND switch to more targeted tool usage (batch reads, fewer exploratory greps). Trigger /core-dump at 60 tool calls automatically rather than waiting for context pressure.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, f1057a8d-e978-416c-b52e-7ea8fd28e770, 1db8913f-fb99-4f99-b283-177336d37471, 86e6683c-0a66-4f68-98ed-37c7e07c715e_

---
### Insight (conf=0.88)
> There is a recurring tension between the agent's tendency to expand scope and the user's preference for minimal, focused changes. The user has had to correct this pattern at least 3 times across different dimensions (scope creep, unsolicited UI enhancements, autonomous implementation beyond request). This is the same underlying anti-pattern surfacing in different guises: the agent optimizes for 'helpfulness' while the user optimizes for 'predictability'.

**Rule:** Before any change, ask: 'Did the user explicitly request this specific modification?' If the answer is no, do not make it — even if it seems like an obvious improvement. Log the temptation as a suppressed impulse rather than acting on it.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, b4abf703-dfb0-4b24-bac3-1bd1e70703f7, 84453a6d-54fb-45f2-9371-6b010b252776, 591772d9-3bb3-4daa-aaba-7e1cf4618ae9_

---
### Insight (conf=0.70)
> Git operations are a trust boundary: the user wants silent execution for routine operations (commit+push) but has been burned by destructive/incorrect git actions (worktree data loss, wrong org). This creates a paradox — speed for routine, caution for edge cases — that can't be resolved by a single policy. The distinguishing factor is whether the operation is reversible.

**Rule:** Classify git operations as reversible (commit, branch, push to feature branch) or irreversible (force push, reset, worktree switch with unstaged changes). Execute reversible ops silently per user preference; always verify state before irreversible ops regardless of user's 'just do it' tone.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 8dc7fecd-8bd3-4317-91d9-d90453e3364f_

---
### Insight (conf=0.65)
> The user has built a parallel version control system (/catchup + /core-dump + WAL) that operates orthogonally to git. Git tracks code state; the WAL/checkpoint system tracks intent state. When hook initialization fails (as seen in the debugging pattern), it threatens this entire parallel state system, which explains why those bugs required 16+ tools to resolve — they were existential threats to the workflow, not just cosmetic errors.

**Rule:** Treat WAL/checkpoint infrastructure failures with the same severity as data loss. When hook errors occur, prioritize restoring the state persistence pipeline before resuming feature work.

_Patterns: 694c5087-f6dc-4dd0-88dc-8645a8dda00f, e218ac38-3844-4295-a972-c9dc01b22d13, 2773a5b3-65d8-45a3-b9ad-933d815a2850_

---
### Insight (conf=0.55)
> Three seemingly unrelated projects (dream tracker, geopolitical simulation, eBay parts pipeline) all involve ingesting messy real-world data, structuring it, and presenting it through dashboards with dark/light mode. The user has a consistent product archetype: 'take chaotic domain data → structured model → visual dashboard'. This pattern could be abstracted into a reusable project template.

**Rule:** When starting new projects with this user, propose the canonical stack upfront: data ingestion layer → MongoDB → API → dashboard with dark/light toggle + widget architecture. Skip the discovery phase for this archetype.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.60)
> Both patterns involve epistemic humility about data quality — one about sparse session metadata, the other about single-source news verification. The user (or their corrections) consistently push toward 'know what you don't know' rather than 'infer aggressively from limited data'. This is a meta-preference for calibrated confidence over false precision.

**Rule:** When confidence in any claim depends on fewer than 3 independent signals, explicitly state the confidence level and what additional verification would strengthen it. Never present single-source or sparse-data conclusions as facts.

_Patterns: c492a9f2-55a9-4c36-9bf3-6c98959e30a7, ef6f1e5e-411d-4460-919d-a15b9d09cb2f_

---
### Insight (conf=0.73)
> The 'sorry continue' pattern and frequent context reconstructions suggest the user is often interrupted mid-session (meetings, context switches, sleep). Combined with the terse command style, this paints a picture of someone who works in bursts across many interruptions rather than in long focused blocks — yet the projects require deep sustained context. The entire continuity infrastructure exists to bridge this gap between work style and project complexity.

**Rule:** Optimize for 'cold start' speed: every checkpoint should be readable and actionable in under 30 seconds. Include the single most important next action as the first line, not buried in a summary.

_Patterns: ddce5474-8599-409f-a1fd-31f73445b461, 5e7ccf60-ef19-4c14-b9c8-76e931755a30, 00fb690c-b719-4a18-ad08-94adf937ae00_

---


## Wake Cycle — 2026-04-15 13:26 UTC

### Insight (conf=0.72)
> The geopolitical simulation's multi-agent architecture mirrors the user's own workflow: autonomous agents that lose state across boundaries and need checkpoint-based recovery. The user is essentially solving the same distributed-state problem at two levels — in their product (game-theory agents maintaining world state) and in their tooling (Claude sessions maintaining work state). Insights from one could directly improve the other.

**Rule:** When designing state persistence for the simulation's agents, reference the WAL/checkpoint/catchup pattern already proven in the dev workflow — and vice versa, improvements to the simulation's state handoff could inform better core-dump formats.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 881b161f-3ee0-4597-ab7b-d6c2a860613d, 1523746a-7091-4022-b130-7e28b7f77561_

---
### Insight (conf=0.82)
> The user's terse command style ('keep going', 'more', 'move') combined with frequent context limit hits suggests a bandwidth mismatch: the user communicates in minimal tokens to maximize the agent's context budget for actual work. The short messages aren't laziness — they're an optimization strategy against context pressure. Verbose agent responses directly compete with the user's ability to continue long sessions.

**Rule:** In high-tool-count sessions (40+), agent responses between tool calls should be ≤15 words. Every unnecessary sentence accelerates compaction and degrades the /catchup recovery path.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.78)
> Three seemingly unrelated projects (dream dashboard, geopolitical simulation, SvelteKit parts app) all share: dark/light mode UI, widget/component architecture, and data pipeline patterns. The user has a consistent architectural fingerprint across domains — they build dashboard-style apps with modular widgets over data backends regardless of the problem domain. This is a personal 'platform pattern' not a project pattern.

**Rule:** When starting any new project with this user, scaffold with: dark/light toggle, widget-based layout, pm2 process management, and a data pipeline layer — this matches their architectural instinct across all observed domains.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.85)
> All three negative-valence approach patterns share a root cause: the agent acted on stale or assumed state instead of verifying current reality. Worktree lost unstaged changes (assumed clean), wrong repo owner (inferred from memory), unsolicited animations (assumed user wanted enhancement). These are all 'assumption drift' errors — the agent's internal model diverged from ground truth.

**Rule:** Before any destructive or creative action, verify the ONE assumption most likely to be stale: working tree state before branch ops, repo ownership before push, and user intent before adding unrequested features.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, b4abf703-dfb0-4b24-bac3-1bd1e70703f7_

---
### Insight (conf=0.75)
> Fire-and-forget task notifications consume context window budget without contributing signal, directly accelerating the compaction cycles that cause session fragmentation. The notification noise and the context pressure form a feedback loop: more agents → more notifications → faster compaction → more /catchup cycles → more tool calls → more notifications.

**Rule:** Batch or suppress zero-content task notifications during high-tool-count sessions. If a notification carries no actionable payload, it should not occupy a conversation turn.

_Patterns: f070277f-8098-4fa2-841e-46ad12536415, 2e7d5054-603d-4ba1-92cb-41bca5de2463, c799c431-c2c8-436c-98cb-27090661dd87_

---
### Insight (conf=0.88)
> Apparent contradiction: user wants minimal changes and no autonomous implementation beyond what's asked, BUT also runs 50-150 tool autonomous sessions with 'keep going'. The resolution is scope-gating: the user grants broad autonomy WITHIN an explicitly defined task boundary, but zero autonomy outside it. The error mode isn't doing too much work — it's doing work in the wrong direction.

**Rule:** At session start, explicitly confirm the task boundary. Within that boundary, execute autonomously and aggressively. Outside it, do nothing — not even 'helpful' adjacent improvements.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, 591772d9-3bb3-4daa-aaba-7e1cf4618ae9, 86e6683c-0a66-4f68-98ed-37c7e07c715e_

---
### Insight (conf=0.70)
> Both patterns flag confidence calibration failures: one about verifying current events from single sources, the other about over-trusting sparse session data. The user has been burned by systems (including this agent) that present low-confidence information with high-confidence framing. This suggests the user values epistemic honesty more than most.

**Rule:** When information comes from a single source or sparse data, explicitly flag the confidence level in the response. Never present uncertain information in declarative voice.

_Patterns: ef6f1e5e-411d-4460-919d-a15b9d09cb2f, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.80)
> The user's communication style — 'sorry continue', 'please', 'just', 'commit and push' without wanting confirmation — reveals they treat the agent as an extension of their own working memory, not as a separate entity requiring social protocol. Confirmations, summaries, and clarifying questions are friction in what should feel like thinking out loud.

**Rule:** Default to executing without confirmation for operations the user has previously approved in similar contexts. Reserve confirmation prompts only for genuinely novel or irreversible actions.

_Patterns: ddce5474-8599-409f-a1fd-31f73445b461, 8a48f2a3-05bc-4565-b05e-00d28a1af177, 8dc7fecd-8bd3-4317-91d9-d90453e3364f_

---
### Insight (conf=0.73)
> The user has evolved a parallel state management system (WAL + checkpoints + core-dump) that functions as a version control system for conversation state, analogous to how git manages code state. This is a homebrew 'git for context' — and like early git adoption, it works but has sharp edges (checkpoint debt, WAL bloat, stale state).

**Rule:** Treat WAL hygiene like git hygiene: checkpoint at logical boundaries (not just time intervals), prune stale entries proactively, and never let more than 2 sessions of WAL accumulate without a clean reset.

_Patterns: 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2, 16053af3-b0de-4ff5-b03f-b72df9f283e0, 694c5087-f6dc-4dd0-88dc-8645a8dda00f_

---
### Insight (conf=0.65)
> The user runs three concurrent long-lived projects each with its own dev server, state management needs, and session continuity requirements. The dream dashboard, geopolitical sim, and SvelteKit app are not independent — they compete for the same cognitive and context budget. Session fragmentation may partly stem from context-switching between projects within the same tool.

**Rule:** When /catchup detects a project switch (different pm2 services, different repo), perform a full context reset rather than incremental recovery — cross-project WAL state is more confusing than helpful.

_Patterns: fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---


## Wake Cycle — 2026-04-15 19:37 UTC

### Insight (conf=0.72)
> The user's projects (geopolitical simulation, dream dashboard, parts pipeline) all model complex stateful systems — the same 'state persistence across boundaries' problem the user solves in their code is the exact problem they face with their AI sessions. Session continuity tooling is isomorphic to the domain problems being solved.

**Rule:** When the user builds stateful domain models (simulations, dashboards, pipelines), proactively apply the same persistence patterns from the domain to session management — e.g., if the project uses event sourcing, mirror that in WAL structure.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.78)
> The user's terse command style ('keep going', 'move', 'sorry continue') combined with iterative UI refinement suggests a REPL-like mental model — they treat the AI as a stateful interpreter where each message is a delta, not a complete instruction. Context loss violates this mental model catastrophically.

**Rule:** Treat every terse continuation message as 'apply the next increment from my last stated direction' — never ask for clarification on messages under 5 words if recent context exists. Reconstruct intent from the last substantive instruction.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, ddce5474-8599-409f-a1fd-31f73445b461_

---
### Insight (conf=0.68)
> There's a fundamental tension: the user prefers long autonomous execution (50-150+ tool calls) but context windows can't sustain it. The checkpoint frequency (every 15-20 actions) is essentially a 'garbage collection' cycle for context — the user has empirically converged on a cadence that balances autonomy vs. state loss, analogous to GC tuning in runtime systems.

**Rule:** Treat checkpoint interval as a tunable parameter: default 15-20 tool calls, but compress to 10 when making cross-file changes (higher state entropy) and extend to 25 for sequential single-file work (lower state entropy).

_Patterns: 86e6683c-0a66-4f68-98ed-37c7e07c715e, 1db8913f-fb99-4f99-b283-177336d37471, c799c431-c2c8-436c-98cb-27090661dd87, 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2_

---
### Insight (conf=0.82)
> The user has a sharp boundary between 'autonomous execution' and 'autonomous decision-making'. They want the agent to execute long sequences without interruption but never expand scope. This is a principal-agent alignment pattern: delegate execution authority but retain design authority.

**Rule:** In long autonomous runs, maximize execution speed and minimize confirmation prompts — but if the next action would change something the user didn't explicitly mention (new file, new feature, visual change), stop and ask. Speed on the rails, brakes at the switches.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, b4abf703-dfb0-4b24-bac3-1bd1e70703f7, 8dc7fecd-8bd3-4317-91d9-d90453e3364f_

---
### Insight (conf=0.65)
> All three are 'stale state' bugs — worktree assuming clean state, git assuming correct org, news assuming single-source truth. The common root cause is acting on cached assumptions instead of verifying current state. This is the same class of bug as context loss after compaction.

**Rule:** Before any destructive or externally-visible action, verify the specific precondition it depends on — don't trust state from more than 10 tool calls ago. Apply the 'read before write' pattern to git state, file state, and external facts equally.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, ef6f1e5e-411d-4460-919d-a15b9d09cb2f_

---
### Insight (conf=0.58)
> Fire-and-forget task notifications, silent multi-agent orchestration events, and low-signal session metadata form a 'dark matter' layer — high volume, low information density events that consume context budget without contributing to task completion. They are the session-continuity equivalent of log noise.

**Rule:** Implement a signal-to-noise filter for WAL entries: task notifications, empty replies, and metadata-only events should be logged as a single aggregated line ('12 task notifications received') rather than individual entries, preserving context budget for substantive actions.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, f070277f-8098-4fa2-841e-46ad12536415, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.70)
> The user maintains 3+ concurrent long-lived projects (geopolitical sim, SvelteKit parts pipeline, iDream dashboard), each requiring deep context. Session continuity isn't just about single-project state — it's about project-switching cost. The user's workflow is closer to an OS process scheduler than a single-threaded debugger.

**Rule:** When /catchup reveals a different project than the last interaction, do a full context reload (WAL + runtime-notes + recent git log) rather than incremental — cross-project switches have near-zero shared state and incremental recovery will miss critical context.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, b76b7252-944d-49f8-bb01-fa76c140a694, c70ae766-c39a-442a-a15d-fbe84d854e0c, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a_

---
### Insight (conf=0.75)
> WAL and checkpoint files have become the user's actual version control for cognitive state — more relied upon than git for continuity. This inverts the normal hierarchy where git is the source of truth. The implication: WAL corruption or staleness is as damaging as losing a git branch.

**Rule:** Treat WAL files with the same integrity guarantees as source code: never truncate without writing a replacement, always validate the last checkpoint is parseable before appending, and warn the user if WAL is >2 sessions stale (it's effectively 'detached HEAD' for cognitive state).

_Patterns: 16053af3-b0de-4ff5-b03f-b72df9f283e0, 1523746a-7091-4022-b130-7e28b7f77561, 694c5087-f6dc-4dd0-88dc-8645a8dda00f_

---


## Wake Cycle — 2026-04-15 23:36 UTC

### Insight (conf=0.82)
> The user's terse command style ('keep going', 'more', 'sorry continue') combined with iterative UI refinement suggests a conductor-orchestra mental model — they expect the agent to maintain autonomous momentum and only need brief directional nudges, not full re-specification. This is a fundamentally different interaction paradigm than question-answer.

**Rule:** After receiving a terse continuation command, never ask clarifying questions — reconstruct intent from the last 3-5 actions in the WAL/context and continue executing. Only pause if the next action is destructive or ambiguous between two very different paths.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, ddce5474-8599-409f-a1fd-31f73445b461_

---
### Insight (conf=0.88)
> Paradox of autonomy: the user wants high autonomous execution volume (50-150+ tool calls) but strict scope containment — go fast and far, but only in the exact direction specified. Unsolicited enhancements are punished even when the user tolerates massive autonomous runs. Autonomy is about speed-on-rails, not creative freedom.

**Rule:** Scale autonomy on the execution axis (more tool calls, longer runs) but never on the scope axis (no unrequested features, no 'while I'm here' improvements). High tool count ≠ permission to expand scope.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, b4abf703-dfb0-4b24-bac3-1bd1e70703f7, 86e6683c-0a66-4f68-98ed-37c7e07c715e_

---
### Insight (conf=0.72)
> Git operations sit in a trust-asymmetry zone: the user wants silent execution for routine ops (commit+push) but has been burned by destructive assumptions (worktree losing unstaged changes, wrong repo owner). The pattern is 'trust me on the happy path, verify on the sad path' — which is the opposite of typical safety defaults.

**Rule:** For git: execute commit/push silently when explicitly requested, but add a pre-flight check (unstaged changes? correct remote?) before any operation that creates or switches branches, without prompting the user — just verify internally and abort with explanation if something is wrong.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 8dc7fecd-8bd3-4317-91d9-d90453e3364f_

---
### Insight (conf=0.65)
> There's a 'noise floor' problem: multi-agent task notifications (fire-and-forget, 0-tool, 0-reply) and excessive checkpoint/WAL writes both consume context budget without proportional value. The session continuity system may be creating the very context pressure it's designed to solve — a feedback loop where checkpointing causes compaction which causes more checkpointing.

**Rule:** Track checkpoint-to-compaction ratio: if more than 30% of tool calls in a session are state-management (WAL writes, checkpoints, catchup reads), the checkpointing is too aggressive. Reduce frequency and increase checkpoint information density instead.

_Patterns: c799c431-c2c8-436c-98cb-27090661dd87, 16053af3-b0de-4ff5-b03f-b72df9f283e0, f070277f-8098-4fa2-841e-46ad12536415, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.55)
> Both patterns reveal the same epistemological error: drawing confident conclusions from thin evidence. Sparse session metadata shouldn't yield high-confidence learnings, just as a single news source shouldn't yield definitive claims. The underlying principle is 'confidence must be proportional to evidence density.'

**Rule:** When extracting patterns or facts, explicitly gate confidence on evidence count: 1 source = flag as unverified, 2-3 sources = tentative, 4+ independent sources = reportable. Apply to both session analysis and external information.

_Patterns: c492a9f2-55a9-4c36-9bf3-6c98959e30a7, ef6f1e5e-411d-4460-919d-a15b9d09cb2f_

---
### Insight (conf=0.70)
> The user maintains 3-4 concurrent long-running projects (SvelteKit/eBay, iDream dashboard, geopolitical simulation, plus tooling) across different tech stacks. The heavy investment in session continuity infrastructure isn't just about single-session length — it's about rapid context-switching between projects that each have deep state.

**Rule:** On /catchup, identify which project is active before reconstructing state — don't assume it's the same project as the last session. Check the working directory and recent git activity first, then load the project-specific WAL.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.60)
> Iterative UI refinement ('better', 'good but...') generates high tool-call volume with small deltas per iteration — this is the most checkpoint-hungry workflow because each micro-change is meaningful but context-light. A specialized 'UI iteration mode' with denser, more compact checkpoints (just the element + property changed) would reduce WAL bloat.

**Rule:** During iterative UI refinement sequences, use a compact checkpoint format: list of (element, property, old_value, new_value) tuples instead of full prose checkpoints. This captures the refinement trajectory in minimal tokens.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, 5e7ccf60-ef19-4c14-b9c8-76e931755a30, 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2_

---


## Wake Cycle — 2026-04-16 04:35 UTC

### Insight (conf=0.72)
> Fire-and-forget task notifications (0 tools, 0 chars) are a direct consequence of multi-agent orchestration generating high-volume async signals; the 'silent ack' behavior is an emergent coping mechanism, not a design choice.

**Rule:** When task notifications arrive with 0 tools/0 chars in multi-agent contexts, suppress them at the orchestration layer rather than routing to the main agent — reduces noise in session logs and WAL.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, f070277f-8098-4fa2-841e-46ad12536415_

---
### Insight (conf=0.78)
> All four negative-valence approach patterns share a common root: the agent acting on inferred intent rather than verified state. Worktree switches lost unstaged changes (inferred clean state), branch creation used wrong owner (inferred from context), unsolicited animations were added (inferred desire), and autonomous implementation exceeded scope (inferred permission).

**Rule:** Before any state-changing action (git ops, file writes beyond explicit request, scope expansion), explicitly verify the current state and the exact user request — never infer intent from prior session context or general 'helpfulness' heuristics.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, b4abf703-dfb0-4b24-bac3-1bd1e70703f7, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.75)
> There is a quantifiable threshold (~15-20 tool calls, or roughly every 5-10 interactions in dashboard work) where checkpoint hygiene flips from optional to load-bearing. This suggests an automatic checkpoint trigger could replace manual /core-dump discipline.

**Rule:** Implement a PostToolUse hook that auto-writes a lightweight WAL checkpoint every 15 tool calls on sessions tagged as long-running (dashboard, simulation, pipeline work), reducing reliance on the user or agent remembering to checkpoint.

_Patterns: c799c431-c2c8-436c-98cb-27090661dd87, f52074f5-e86f-46bf-9b6e-a07c743963b6, 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2, 3d9745f8-ff2e-4e94-be3c-89586e47cd3a_

---
### Insight (conf=0.82)
> The user's terse-command style ('keep going', 'move', 'sorry continue') combined with tolerance for 50-150+ tool sessions reveals a 'driver-navigator' collaboration model: user sets direction in short bursts, agent executes long autonomous stretches. This is the opposite of the fine-grained pair-programming pattern.

**Rule:** On terse continuation commands, prefer to execute 10-30 tool calls autonomously before checking in rather than asking clarifying questions — but always checkpoint mid-stretch so interruptions are recoverable.

_Patterns: edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, ddce5474-8599-409f-a1fd-31f73445b461, 86e6683c-0a66-4f68-98ed-37c7e07c715e_

---
### Insight (conf=0.65)
> All four active domains (iDream dashboard, SvelteKit/eBay pipeline, geopolitical simulation, game-theory multi-agent) share a 'dashboard-with-backend-data-pipeline' archetype: UI layer + data transform + long-running ingestion. The continuity pain points are domain-agnostic — they stem from the architecture shape, not the topic.

**Rule:** Treat any project with (frontend + data pipeline + external API) as a 'dashboard archetype' and apply the same continuity scaffolding (WAL format, pm2 ports, light/dark toggle, checkpoint cadence) rather than re-deriving conventions per project.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.58)
> The user's iterative UI refinement style ('better', 'revert colors') sits in tension with their preference for generic reusable test patterns. UI refinement is inherently one-off and exploratory, while test generalization requires stable interfaces — suggests UI code should live behind a stable contract that tests can target even as visuals churn.

**Rule:** For UI components undergoing iterative refinement, write tests against behavior/data contracts (props, rendered text, ARIA roles) rather than visual properties (colors, padding, fonts) — decouples test stability from refinement churn.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, c1405960-924b-4896-b075-e8de0d9868d1_

---
### Insight (conf=0.80)
> Low-signal session artifacts (sparse metadata, fire-and-forget notifications) are being fed into pattern-extraction systems and may be inflating confidence scores via sheer volume. The 95% confidence scores on ~15 near-duplicate 'catchup/core-dump' patterns likely reflect this.

**Rule:** Pattern extraction should deduplicate by semantic hash before confidence aggregation — 15 patterns saying 'user uses /catchup heavily' should collapse to one pattern with a count, not 15 independent 0.95-confidence entries.

_Patterns: c492a9f2-55a9-4c36-9bf3-6c98959e30a7, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.77)
> Both corrections involve single-source trust failures — one in external info (news/politics), one in internal state (repo owner). The agent conflates 'I have a plausible value' with 'I have verified the value'. The failure mode is identical across information domains.

**Rule:** Before any assertion of fact (current events, repo metadata, file state, user identity), require at least two independent sources or one authoritative check — treat first-match values as candidates, not answers.

_Patterns: ef6f1e5e-411d-4460-919d-a15b9d09cb2f, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.83)
> WAL is load-bearing infrastructure yet accumulates debt across 40+ continuations — this is the classic 'transaction log without compaction' problem from database systems. The fix is the same: periodic log compaction (milestone core-dump + WAL reset) to keep replay cost bounded.

**Rule:** After any major feature completion or merge-to-main event, execute a full /core-dump followed by WAL truncation (keeping only the last checkpoint summary) — treat WAL like a database WAL with compaction, not an append-only journal.

_Patterns: 16053af3-b0de-4ff5-b03f-b72df9f283e0, 1523746a-7091-4022-b130-7e28b7f77561_

---


## Wake Cycle — 2026-04-16 08:51 UTC

### Insight (conf=0.72)
> Both patterns involve irreversible state loss from insufficient pre-operation verification (unstaged changes in worktrees; wrong owner in branch/push). They share a root cause: acting on assumed state rather than verified state before destructive/distributed git ops.

**Rule:** Before any git worktree switch, branch creation, or push: run a verification triad — `git status` for unstaged work, `git remote -v` for owner/org, and confirm target branch. Treat this as a precondition checklist, not optional.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.68)
> Fire-and-forget task notifications and sparse-data sessions both represent low-signal events that currently flow into the same learning pipeline as substantive sessions. Treating them equally pollutes the learning corpus with noise weighted at full confidence.

**Rule:** In memory/learning extraction, tag sessions with <5 tools AND <200 reply chars as 'low-signal' and down-weight their confidence by 0.5x before aggregation. Exclude pure task-notification events from pattern mining entirely.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, f070277f-8098-4fa2-841e-46ad12536415, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.82)
> The user's communication style is consistently terse-iterative: short imperatives ('keep going', 'more', 'sorry continue', 'better') rather than upfront specifications. This isn't laziness — it's a deliberate interactive-refinement workflow that assumes the agent holds and updates context continuously. Session continuity tools are the substrate that makes this style viable.

**Rule:** When the user issues a terse continuation ('keep going', 'more', 'better', 'sorry continue'), do NOT ask clarifying questions. Resume from the last concrete state in WAL/checkpoint and make the smallest reasonable forward step, then pause for feedback.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, edaeaf8c-9b6e-4652-b777-ccedba905520, ddce5474-8599-409f-a1fd-31f73445b461, 2dfa1a6e-03f6-473e-8476-8a5da501300e_

---
### Insight (conf=0.86)
> Both corrections target the same underlying failure: autonomous scope expansion. The agent added unrequested animations, and separately, the agent implemented changes when only understanding was asked. These are the same mistake — treating the user's direction as a floor rather than a ceiling.

**Rule:** Treat user requests as a ceiling on scope, not a floor. No unsolicited 'enhancements' (animations, polish, refactors). If the user asks to understand code, only explain — do not modify. When uncertain whether an adjacent change is wanted, ask first.

_Patterns: b4abf703-dfb0-4b24-bac3-1bd1e70703f7, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.63)
> Across multiple patterns, checkpoint frequency hovers around every 5-20 tool calls, but there's no evidence of a quantitative threshold that actually works — it's consistently reactive (after pressure shows). The compaction cycle itself may be the wrong granularity; checkpoint cadence should be tied to logical work units (feature milestone, risky op, context switch), not tool count.

**Rule:** Replace 'every N tool calls' checkpoint heuristic with event-driven triggers: (1) completed feature/subfeature, (2) before any destructive op, (3) context switch between files/domains, (4) user pause signals. Tool-count is a weak proxy; semantic boundaries are stronger.

_Patterns: c799c431-c2c8-436c-98cb-27090661dd87, f52074f5-e86f-46bf-9b6e-a07c743963b6, 16053af3-b0de-4ff5-b03f-b72df9f283e0, 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2_

---
### Insight (conf=0.71)
> The user runs at least 3 parallel long-running projects (geopolitical sim, iDream dashboard, SvelteKit/eBay pipeline) — session continuity pressure is not from any single project being too large, but from context-switching across projects within sessions. The problem is project interleaving, not project depth.

**Rule:** At /catchup start, first identify WHICH project the user is resuming (check cwd, recent WAL entries, last checkpoint project tag). Never assume continuation is from the most recent session — the user may be switching projects. Prompt if ambiguous.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a_

---
### Insight (conf=0.78)
> Three patterns converge on a single meta-principle: single-source confidence inflation. Whether it's one news source, an inferred git owner, or a sparse session's extracted pattern — acting on unverified singular signals has caused corrections. The agent systematically overweights first-available information.

**Rule:** For any claim that will be acted on (published, pushed, committed to memory), require two independent sources or one source + explicit verification step. Flag single-source claims in output as '(unverified, single source)'.

_Patterns: ef6f1e5e-411d-4460-919d-a15b9d09cb2f, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.74)
> The user tolerates — and even expects — 50-150+ tool autonomous runs when given a clear imperative ('keep going', 'started'). This is the opposite extreme from the scope-creep patterns: here, high autonomy is explicitly authorized. The signal that distinguishes them is the presence of a clear imperative verb, not the length of work.

**Rule:** Treat imperatives like 'keep going', 'started', 'continue', 'do it' as explicit authorization for extended autonomous execution within the current task scope. Do NOT treat them as authorization to expand scope — autonomy is on depth, never breadth.

_Patterns: 86e6683c-0a66-4f68-98ed-37c7e07c715e, 1db8913f-fb99-4f99-b283-177336d37471, 2dfa1a6e-03f6-473e-8476-8a5da501300e, f1057a8d-e978-416c-b52e-7ea8fd28e770_

---
### Insight (conf=0.58)
> Interesting tension: the user prefers generic/reusable patterns in code (tests) but iteratively refines UI with one-off tweaks. This suggests domain-specific abstraction preferences — abstract at the code layer, concrete at the UX layer. Applying 'generic/reusable' thinking to UI work would misfire.

**Rule:** When designing tests, utilities, or backend logic: default to generic/reusable patterns. When iterating on UI/UX: accept one-off values and concrete tweaks — do not refactor toward a design system abstraction unless asked.

_Patterns: c1405960-924b-4896-b075-e8de0d9868d1, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.80)
> Three patterns independently conclude that /catchup + /core-dump are 'load-bearing infrastructure' — meaning if they fail, downstream work fails. Yet no pattern describes a fallback when WAL/checkpoint is corrupted, missing, or stale. This is a single point of failure in the user's entire workflow.

**Rule:** Add defensive fallbacks to /catchup: if WAL is missing/corrupt, check _checkpoint.claude.md; if both missing, check runtime-notes for recent entries; if all missing, explicitly tell user 'no continuity state found' and ask for re-orientation rather than proceeding blind.

_Patterns: 694c5087-f6dc-4dd0-88dc-8645a8dda00f, 1523746a-7091-4022-b130-7e28b7f77561, 07e91a34-f2bd-4d49-8ac8-b81f1d0cd808_

---


## Wake Cycle — 2026-04-16 19:42 UTC

### Insight (conf=0.75)
> User communication style is consistently terse and iterative across all contexts — short imperatives ('keep going', 'more', 'sorry continue') and incremental refinements ('better', 'revert colors') form a unified interaction grammar. This suggests the user treats the agent as a continuous collaborator rather than a command interpreter.

**Rule:** When user message is <5 words and imperative/evaluative, treat as continuation signal — infer context from most recent WAL entry or last tool action rather than asking for clarification.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, ddce5474-8599-409f-a1fd-31f73445b461_

---
### Insight (conf=0.80)
> All four negative-valence 'mistake' patterns share a root cause: agent acting on inferred intent rather than verified state (unstaged changes, repo owner, scope boundaries, visual enhancements). The common fix is a pre-action verification step for anything touching user-visible or hard-to-reverse state.

**Rule:** Before any action that modifies visible UI, branches, worktrees, or exceeds literal request scope: state the inferred intent in one line and verify against explicit user words before executing.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, b4abf703-dfb0-4b24-bac3-1bd1e70703f7, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.70)
> User operates at least three distinct long-running projects (iDream dashboard, geopolitical simulation, SvelteKit parts data) each with its own dev server, stack, and context. Session-continuity tooling is load-bearing not just because sessions are long, but because the agent must disambiguate which project a resumption belongs to.

**Rule:** At /catchup time, first resolve project identity (working directory + recent WAL header) before restoring task state — don't assume continuation belongs to the most-recent-globally session.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a_

---
### Insight (conf=0.78)
> Checkpoint cadence has an optimal frequency band: every 15-20 tool calls based on multiple patterns. Below that is overhead; above (40+) accumulates debt and degrades /catchup recovery quality. This is an empirically discoverable tuning parameter.

**Rule:** Write a WAL CHECKPOINT every 15-20 tool calls during active implementation work; trigger full /core-dump + WAL reset at feature-complete milestones or at 40+ accumulated calls.

_Patterns: 16053af3-b0de-4ff5-b03f-b72df9f283e0, c799c431-c2c8-436c-98cb-27090661dd87, 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2, 3d9745f8-ff2e-4e94-be3c-89586e47cd3a, f52074f5-e86f-46bf-9b6e-a07c743963b6_

---
### Insight (conf=0.72)
> Zero-tool/zero-reply task notifications and low-signal session data share a signature: they carry metadata but no substantive content. Both should be treated as structural events (logging only) rather than actionable inputs — conflating them with real turns pollutes downstream learning systems.

**Rule:** Filter out zero-tool/zero-reply turns from pattern-extraction and retrospective analysis; treat them as heartbeats, not interactions.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.65)
> The combination of (a) tolerance for 50-150+ tool autonomous runs, (b) terse resume commands, and (c) no complaint about length suggests user trust is high when direction is clear. Agent should lean into longer autonomous stretches rather than checking in frequently.

**Rule:** When user gives a clear goal + 'keep going' or similar, avoid interrupting for confirmation until a genuine ambiguity or risky operation; prefer depth over check-in frequency.

_Patterns: 86e6683c-0a66-4f68-98ed-37c7e07c715e, 1db8913f-fb99-4f99-b283-177336d37471, 2dfa1a6e-03f6-473e-8476-8a5da501300e_

---
### Insight (conf=0.70)
> Both corrections involve 'single-source inference' failures: one for news/facts, one for git ownership. The pattern is agent synthesizing from a single anchor (one source, prior session state) rather than cross-referencing.

**Rule:** For any fact/state that will be acted on or reported externally, require at least two independent signals before proceeding — especially for current events, repo identity, and state claims about remote systems.

_Patterns: ef6f1e5e-411d-4460-919d-a15b9d09cb2f, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.68)
> Core-dump has evolved from session-end ritual to mid-session checkpoint tool — proactive use is now the norm, not the exception. This is a semantic drift worth codifying: /core-dump is now a 'save point' primitive, not a 'goodbye' primitive.

**Rule:** Treat /core-dump as a save-point primitive: invoke proactively at milestones, before risky ops, and before long autonomous stretches — not only at session end.

_Patterns: bcec004b-2886-4d93-ba81-2de6d1348a63, f1b15033-a4e3-4a70-84fa-4de726a42926, e218ac38-3844-4295-a972-c9dc01b22d13_

---


## Wake Cycle — 2026-04-16 21:19 UTC

### Insight (conf=0.55)
> Destructive-state mistakes (worktree loss, wrong branch/org) cluster around transition boundaries — the same 'context switch' moments where checkpoint debt accumulates. A pre-transition verification step could catch all three.

**Rule:** Before any context-switch operation (worktree swap, branch/push, major feature completion), run a unified pre-flight: check unstaged work + verify remote owner + force /core-dump with WAL reset.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 16053af3-b0de-4ff5-b03f-b72df9f283e0_

---
### Insight (conf=0.75)
> The user's terse-continuation style ('keep going', 'better', 'sorry continue', 'more') is the human-facing mirror of /catchup — both rely on the agent reconstructing state from checkpoint rather than explicit instructions. Checkpoint quality directly determines how well terse commands work.

**Rule:** Treat every terse continuation message as an implicit /catchup — read the most recent WAL checkpoint before acting, and write a fresh micro-checkpoint after each iterative UI refinement so the next 'better'/'revert' has accurate state.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, edaeaf8c-9b6e-4652-b777-ccedba905520, 1c39c2de-8ccf-477a-8fb4-0d47a81b02f5, 2dfa1a6e-03f6-473e-8476-8a5da501300e, ddce5474-8599-409f-a1fd-31f73445b461_

---
### Insight (conf=0.50)
> Scope-creep corrections happen more in exploratory/understanding contexts (iDream dashboard, geopolitical sim, SvelteKit data pipeline) where the codebase is large enough that 'help me understand' easily slides into 'let me also fix this'. The long-running, complex nature of these projects amplifies the temptation.

**Rule:** On projects flagged as long-running/complex, default to read-only exploration mode — require an explicit implementation verb ('implement', 'write', 'fix') before making code changes.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, c70ae766-c39a-442a-a15d-fbe84d854e0c, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.65)
> Single-source verification failures (news/political figures) and sparse-data extraction limits share a root cause: confidence calibration fails when input signal is thin. Both need explicit low-signal flagging rather than confident assertion.

**Rule:** When a claim rests on one source or sparse data (few tools, short replies, single citation), prefix output with an explicit confidence caveat and actively seek a second source before committing to the assertion.

_Patterns: c492a9f2-55a9-4c36-9bf3-6c98959e30a7, ef6f1e5e-411d-4460-919d-a15b9d09cb2f_

---
### Insight (conf=0.80)
> There is a consistent tool-call threshold (~15-40 calls) where checkpoint ROI becomes strongly positive. This suggests a hard automation trigger rather than heuristic judgment — the agent should count, not feel.

**Rule:** Add a tool-call counter hook: automatically emit a WAL checkpoint at 20 tool calls since last checkpoint, regardless of task phase. Remove the judgment step.

_Patterns: f52074f5-e86f-46bf-9b6e-a07c743963b6, c799c431-c2c8-436c-98cb-27090661dd87, 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2, 3d9745f8-ff2e-4e94-be3c-89586e47cd3a_

---
### Insight (conf=0.55)
> All three major active projects (geopolitical sim, iDream dashboard, SvelteKit parts) share: multi-agent/widget architecture, dark-light mode, long-running sessions, and iterative refinement. They may be converging on a shared scaffolding pattern worth extracting.

**Rule:** Extract a shared project template covering: dark/light CSS vars, widget/agent registry pattern, pm2 + port conventions, and /catchup-ready WAL setup — reuse across new projects instead of rebuilding.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.70)
> WAL and checkpoints have become load-bearing infrastructure, yet they live in plain files with no integrity checks. A corrupted or accidentally-deleted WAL would silently degrade /catchup quality without warning.

**Rule:** Add a WAL integrity check at /catchup start: verify JSONL parse, last checkpoint age, and session_id continuity — surface warnings loudly if the WAL looks stale or malformed rather than silently resuming from bad state.

_Patterns: 1523746a-7091-4022-b130-7e28b7f77561, 07e91a34-f2bd-4d49-8ac8-b81f1d0cd808, 694c5087-f6dc-4dd0-88dc-8645a8dda00f_

---


## Wake Cycle — 2026-04-16 21:38 UTC

### Insight (conf=0.72)
> Both reflect a class of 'state-loss from context-less operations': worktree switches lose unstaged work, branch/push operations misidentify owners. Both stem from acting on inferred state rather than verified state.

**Rule:** Before any git operation that changes branch/worktree/remote state, run a verification command (git status, git remote -v, gh repo view) and cite the output — never infer from session memory.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.55)
> JSONL WAL format and fire-and-forget task notifications share a design principle: machine-parseable, append-only event streams beat prose for infrastructure signals. The same jq-queryable pattern that made WAL reliable could formalize task-notification handling.

**Rule:** When adding new signal/event channels (notifications, hooks, async task results), default to JSONL with typed 'kind' field — enables jq filtering and matches WAL conventions.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.82)
> User's terse-iterative communication style ('keep going', 'better', 'more') is structurally identical to their heavy reliance on /catchup — both offload state-carrying to the agent/infrastructure rather than the prompt. The user consistently treats the agent as a stateful collaborator, not a stateless function.

**Rule:** On terse prompts ('keep going', 'more', 'continue'), the first action should be to consult WAL/checkpoint for last 'current'/'next' fields before acting — treat state recovery as mandatory, not optional.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 1c39c2de-8ccf-477a-8fb4-0d47a81b02f5_

---
### Insight (conf=0.78)
> User juggles at least 3 concurrent long-running projects (iDream dashboard, geopolitical simulation, SvelteKit parts pipeline). Session continuity tooling is essential not just because sessions are long, but because context-switching *between projects* requires fast re-orientation.

**Rule:** /catchup output should lead with project identity (CWD, pm2 service names, dominant domain keywords) so cross-project resumption is unambiguous even when the session_id is generic.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a_

---
### Insight (conf=0.80)
> Iterative UI refinement (screenshot → edit → re-screenshot) is the primary consumer of tool-call budget that drives context pressure. The 'incremental request' style multiplied by the 'many tools per visible change' loop is the root cause of 40+ tool sessions.

**Rule:** During UI refinement loops, batch multiple visual adjustments into a single edit+screenshot cycle when the user gives stacked feedback ('increase font AND revert colors') rather than treating each as a separate round-trip.

_Patterns: f34c00a8-b5be-4fc3-b371-0f9cd5baa88a, 92a767af-37ad-4b83-84af-684fd98948b5, c799c431-c2c8-436c-98cb-27090661dd87_

---
### Insight (conf=0.65)
> User's correction about agent scope (don't autonomously implement beyond request) contrasts with heavy /core-dump reliance — suggesting the user wants high state-continuity but tight scope-discipline. State should persist; ambition should not.

**Rule:** Core-dumps should record completed scope and explicit next steps, but never auto-expand TODOs or 'also consider' items that weren't user-requested — checkpoint discipline ≠ scope creep.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.70)
> Both describe low-signal inputs (0-tool notifications, sparse session metadata) that the extraction/response system must recognize and downweight rather than treat as full-fidelity data.

**Rule:** When input has structural markers of low-signal (empty tool count, minimal metadata, fire-and-forget notification), emit a minimal/no-op response and flag downstream learnings with a confidence cap.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.88)
> Four independent observations converge on the same threshold: sessions >40 tool calls develop checkpoint debt. This isn't anecdotal — it's a reproducible inflection point where WAL hygiene degrades.

**Rule:** Hard rule: at tool call #30 in a session, auto-write a WAL checkpoint. At #60, trigger a /core-dump suggestion. These are not soft heuristics — they should be automated via a PostToolUse hook counting tool calls per session.

_Patterns: 16053af3-b0de-4ff5-b03f-b72df9f283e0, 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2, 3d9745f8-ff2e-4e94-be3c-89586e47cd3a, c799c431-c2c8-436c-98cb-27090661dd87_

---
### Insight (conf=0.68)
> Both are 'accumulated-state loss' failure modes: worktree ops lose unstaged changes; 40+ continuation sessions lose checkpoint coherence. Both suggest that Claude's risk model should weight 'unpreserved work' as a first-class concern before any state-mutating operation.

**Rule:** Before any high-blast-radius operation (worktree switch, branch checkout, WAL reset, long compaction), run a 'preserve-check' that verifies: (a) no unstaged changes, (b) WAL checkpoint <20 tool calls old, (c) core-dump exists if session >40 tools.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, 16053af3-b0de-4ff5-b03f-b72df9f283e0_

---
### Insight (conf=0.50)
> The geopolitical simulation and iDream dashboard may share architectural DNA (multi-agent, widget-based, dark/light mode, long-running). Cross-pollination of patterns between these projects is likely happening implicitly — worth making explicit.

**Rule:** When working in one project, proactively check ~/.claude/scratchpad/global/ for patterns from the other — especially for UI (light/dark toggle), agent orchestration, and checkpoint conventions.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.85)
> User has trained the agent (via repeated reinforcement) to run /core-dump proactively — this is now an expected behavior, not a requested one. Failing to proactively checkpoint is effectively a regression.

**Rule:** Treat missing proactive /core-dump at milestones/risky-ops as a correctable defect — on session resume, if no recent checkpoint exists for a >30-tool session, write one immediately before continuing work.

_Patterns: bcec004b-2886-4d93-ba81-2de6d1348a63, 2ff536b4-f4b3-41b3-a3ae-bb588aad3e73, 54f4b4e1-6216-4a39-9484-1d6618b8e901_

---


## Wake Cycle — 2026-04-16 22:20 UTC

### Insight (conf=0.75)
> The JSONL WAL migration creates an opportunity: /catchup can now leverage jq-based structured queries to surface only the most recent checkpoint + unresolved blockers, rather than re-reading the entire log — this could dramatically speed up session re-orientation.

**Rule:** Update /catchup to prefer `jq -c 'select(.kind == "checkpoint")' .claude/wal.jsonl | tail -1` as the primary recovery path, falling back to markdown only when JSONL is absent.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0da89570-65b9-4bc5-8a0c-9cbf130314c9, ef9a0ad9-13be-470f-9881-2b6c679d640b_

---
### Insight (conf=0.78)
> A consistent signal emerges: ~15-20 tool calls is the natural checkpoint cadence for this user. Hard-coding this as an automatic trigger (via hook or agent-side counter) would remove the cognitive burden of deciding when to checkpoint.

**Rule:** Implement a PostToolUse hook that tracks tool count per session and emits a reminder to write a WAL checkpoint every 15 tool calls, or auto-appends a checkpoint line when session context usage crosses 60%.

_Patterns: c799c431-c2c8-436c-98cb-27090661dd87, f52074f5-e86f-46bf-9b6e-a07c743963b6, 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2, 3d9745f8-ff2e-4e94-be3c-89586e47cd3a_

---
### Insight (conf=0.65)
> Terse user messages ('keep going', 'move', 'more') and fire-and-forget task notifications share a structural property: they carry no new semantic content and rely entirely on prior state. Both should trigger the same 'resume from WAL checkpoint' code path rather than being handled as distinct input types.

**Rule:** On receiving a message ≤3 words or a task-notification with 0 reply chars, immediately read the last WAL checkpoint's `next` field before responding — treat it as the effective instruction.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 1c39c2de-8ccf-477a-8fb4-0d47a81b02f5_

---
### Insight (conf=0.72)
> These three negative-valence patterns share a root cause: trusting inferred state rather than verifying current state before destructive/externally-visible ops. Worktree switches, branch creation, and WAL resets all silently assume continuity that may not hold across compactions.

**Rule:** Before any of (worktree switch, branch create/push, WAL reset), require an explicit verification step: `git status --porcelain`, `git remote -v`, or `wc -l wal.jsonl` respectively. No action on inferred state.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 16053af3-b0de-4ff5-b03f-b72df9f283e0_

---
### Insight (conf=0.70)
> The iDream dashboard's iterative UI refinement loop (screenshot→inspect→edit→re-screenshot) is exactly the workflow that burns tool calls fastest and accelerates context exhaustion — which then forces the heavy /catchup reliance observed elsewhere. UI work is the hidden driver of this user's continuity-tool dependence.

**Rule:** When starting UI refinement work, pre-allocate a checkpoint cadence of 10 tool calls (vs. the default 15-20) and write a core-dump proactively before any screenshot round-trip exceeding 5 iterations.

_Patterns: f34c00a8-b5be-4fc3-b371-0f9cd5baa88a, 92a767af-37ad-4b83-84af-684fd98948b5, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.60)
> The user's iterative refinement style and preference for reusable tests both reflect a 'converge via feedback' working model — they distrust upfront specification and prefer to shape outcomes through successive narrowing. Agents should mirror this by offering minimal viable versions first, then refining, rather than producing exhaustive first drafts.

**Rule:** For non-trivial tasks, produce a minimal implementation first and ask 'does this direction look right?' before building out edge cases or abstractions.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, c1405960-924b-4896-b075-e8de0d9868d1, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.55)
> Low-signal inputs (sparse session data, empty task notifications) are being treated with the same downstream weight as high-signal inputs in the learning extraction pipeline. This inflates confidence on patterns derived from noise.

**Rule:** In the memory-extraction pipeline, attach a 'signal_strength' score based on input richness (tool count, reply length, message content length); downstream consumers should filter or down-weight low-signal items.

_Patterns: c492a9f2-55a9-4c36-9bf3-6c98959e30a7, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.50)
> The user maintains at least three parallel long-running projects (geopolitical sim, SvelteKit/eBay pipeline, iDream dashboard) — session continuity tooling may be straining because it's single-namespace when it should be project-namespaced. /catchup might be loading irrelevant checkpoints across projects.

**Rule:** Ensure WAL and core-dump paths are always project-local (`.claude/wal.jsonl` under project root) not global, and that /catchup resolves the project root before reading — never the user's home directory.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, b76b7252-944d-49f8-bb01-fa76c140a694, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.80)
> Proactive core-dumping has become a user-expected norm, not just a user preference. The cluster of nearly-identical patterns at conf=0.95 suggests this should be promoted from 'preference' to a hard workflow rule — checkpoint without being asked.

**Rule:** Treat /core-dump as a mandatory step (not a user-requested one) at: major milestone completion, before any risky op, after ≥3 files edited, and at natural session-end signals.

_Patterns: bcec004b-2886-4d93-ba81-2de6d1348a63, 2ff536b4-f4b3-41b3-a3ae-bb588aad3e73, e218ac38-3844-4295-a972-c9dc01b22d13_

---


## Wake Cycle — 2026-04-17 04:43 UTC

### Insight (conf=0.55)
> The WAL markdown-to-JSONL migration mirrors the geopolitical simulation's own need for machine-queryable state: both are complex multi-agent systems where structured, parseable state handoff is more reliable than prose-based summaries. The simulation project likely drove the WAL format requirements — managing multi-agent game state across sessions exposed the brittleness of markdown-based checkpoints.

**Rule:** When building state-persistence for multi-agent systems (simulations, pipelines), default to JSONL over markdown from day one — the query requirements will emerge before you expect them.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.70)
> The desktop automation vision loop (screenshot → annotate → read → act → verify) is structurally identical to the session continuity loop (core-dump → checkpoint → catchup → work → verify state). Both solve the same fundamental problem: an agent with no persistent memory operating on a system it can only observe through snapshots. Context limits force the same 'observe-orient-act' cycle that screen blindness does.

**Rule:** Unify observation-action loops: any agent operating without persistent state should follow the same pattern — snapshot current state, annotate what matters, act, verify the result — whether the 'screen' is a GUI, a codebase, or a conversation context.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 881b161f-3ee0-4597-ab7b-d6c2a860613d, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.65)
> Fire-and-forget task notifications (0 tools, 0 reply chars) and terse user commands ('keep going', 'move') are both minimal-bandwidth control signals in a system where the expensive resource is context, not communication. The user has internalized the agent's context pressure and naturally minimizes their own token footprint — they're co-optimizing the context window without being asked.

**Rule:** When a user consistently sends sub-5-word messages, treat it as a signal they're context-aware — respond with equally terse acknowledgments and maximize tool-call density over explanatory text.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e_

---
### Insight (conf=0.60)
> Iterative UI refinement ('better', 'good but...', 'revert colors') creates disproportionate context pressure because each small visual tweak consumes a full tool-call cycle but carries minimal semantic weight. This is why dashboard sessions fragment so heavily — it's not the feature complexity, it's the feedback loop granularity. The user's correction about scope ('only help understand, don't implement beyond what's asked') may stem from agents over-batching changes to compensate for this pressure.

**Rule:** For iterative UI refinement sessions, checkpoint aggressively every 10 visual tweaks rather than every 15-20 tool calls — visual iteration burns context faster than implementation work due to screenshot reads.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, c799c431-c2c8-436c-98cb-27090661dd87, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.75)
> Git worktree data loss, incorrect owner/org inference, and WAL checkpoint debt are all symptoms of the same root cause: stale state assumptions. After enough context continuations, the agent's model of the world drifts from reality — it 'remembers' a branch that was rebased, an org that was forked, or a checkpoint that was superseded. The longer the session chain, the more dangerous implicit state becomes.

**Rule:** After 3+ session continuations on the same task, treat ALL cached assumptions as potentially stale — re-verify git state, file existence, and server status before acting, even if you 'remember' them from a prior context.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 16053af3-b0de-4ff5-b03f-b72df9f283e0_

---
### Insight (conf=0.50)
> The warning about sparse session data producing low-confidence learnings applies recursively to the continuity system itself: each /catchup reconstructs context from a lossy checkpoint, and downstream decisions inherit that lossiness. WAL and checkpoints are load-bearing infrastructure, but they're also lossy compressors — the system's confidence should degrade proportionally to the number of compression boundaries crossed.

**Rule:** Track a 'compression depth' counter in WAL checkpoints — how many catchup/compaction cycles this task has crossed. At depth >= 3, proactively re-read source files rather than trusting checkpoint summaries of their state.

_Patterns: c492a9f2-55a9-4c36-9bf3-6c98959e30a7, f52074f5-e86f-46bf-9b6e-a07c743963b6, 1523746a-7091-4022-b130-7e28b7f77561_

---
### Insight (conf=0.60)
> Three distinct domain projects (geopolitical simulation, dream dashboard, eBay/JEGS parts pipeline) all share: dark/light mode UI, data transformation pipelines, and long multi-session development. The user builds the same kind of system repeatedly — a data-intensive dashboard with visualization and backend pipeline. This is a personal 'application archetype' that could be templated.

**Rule:** When starting a new project with this user, check if it fits the recurring archetype (data pipeline → transform → dashboard with dark/light mode) and propose the shared scaffolding upfront rather than rediscovering it.

_Patterns: 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---


## Wake Cycle — 2026-04-17 08:47 UTC

### Insight (conf=0.82)
> All three are 'verify-before-act' failures in different domains: desktop automation (click without annotation), git (worktree switch without stash check), and repository ops (push without owner verification). The common root is skipping a pre-flight read step before a destructive write. This is a single meta-pattern: every side-effecting operation needs a preceding observation step.

**Rule:** Before any side-effecting operation (click, git checkout, push, file write to external system), execute exactly one read/verify step that confirms the target state matches expectations. Never chain two write operations without an intermediate read.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.72)
> The user's interaction style ('keep going', 'better', 'more') combined with heavy session continuity creates a REPL-like development loop where the agent is treated as a persistent subprocess, not a stateless Q&A system. The terse commands are not laziness — they are the UX of an operator driving a long-running process. The optimal interface would be a state machine, not a conversation.

**Rule:** When receiving terse continuation commands, do not re-explain context or ask clarifying questions. Instead: read last WAL checkpoint → identify current task → execute next step → report result in one line. Treat 'keep going' as 'next()' on an iterator, not as a new prompt.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, edaeaf8c-9b6e-4652-b777-ccedba905520, 1c39c2de-8ccf-477a-8fb4-0d47a81b02f5, 2dfa1a6e-03f6-473e-8476-8a5da501300e_

---
### Insight (conf=0.55)
> The 40+ tool-call sessions with heavy compaction debt and fire-and-forget notifications suggest the user consistently operates at the edge of context window capacity. The zero-tool notification messages are actually a signal that async work is completing faster than the main context can absorb it — the system is I/O bound on context, not on compute. Checkpointing every 15-20 actions is treating the symptom; the root cause is that task granularity exceeds single-context capacity.

**Rule:** When a task estimate exceeds 30 tool calls, proactively decompose into sub-tasks that each fit within one context window (~25 tool calls), with explicit handoff artifacts between them. Don't wait for compaction pressure — plan for it.

_Patterns: c799c431-c2c8-436c-98cb-27090661dd87, 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2, 16053af3-b0de-4ff5-b03f-b72df9f283e0, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.60)
> The user runs multiple long-lived projects simultaneously (iDream dashboard, SvelteKit parts app, geopolitical simulation) all using pm2 and similar stack patterns. Cross-project context bleed is a risk — state from one project's WAL/checkpoint could contaminate another's recovery. The port convention (30xx/50xx) suggests awareness of this, but session continuity tools don't namespace by project.

**Rule:** When running /catchup, verify the WAL's project context matches CWD before applying state. If the last checkpoint references files from a different project root, warn the user rather than silently applying stale cross-project state.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a_

---
### Insight (conf=0.68)
> There is a tension between the user's iterative refinement style (small incremental requests) and their correction that the agent should not implement beyond what was asked. The iterative style implicitly invites forward progress, but the correction sets a hard boundary. The resolution: the agent should propose the next step but not execute it — offer a diff preview, not a committed change.

**Rule:** After completing an iterative refinement request, state the most likely next adjustment in one sentence but do not implement it. Wait for the user's 'keep going' or redirection. This respects both the iterative flow and the scope boundary.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, 92a767af-37ad-4b83-84af-684fd98948b5, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.65)
> The WAL migration from markdown to JSONL, combined with the pattern that session state management happens via WAL/checkpoint rather than git, reveals that the user has built a parallel version control system optimized for agent cognition rather than code. Git tracks file diffs; WAL tracks decision diffs. These are complementary, not redundant — but they could diverge dangerously if a git revert doesn't update the WAL.

**Rule:** After any git reset, revert, or branch switch, append a WAL entry noting the git state change so that /catchup doesn't resume work that was already rolled back.

_Patterns: 881b161f-3ee0-4597-ab7b-d6c2a860613d, 0da89570-65b9-4bc5-8a0c-9cbf130314c9, 694c5087-f6dc-4dd0-88dc-8645a8dda00f_

---


## Wake Cycle — 2026-04-18 01:40 UTC

### Insight (conf=0.55)
> The WAL markdown-to-JSONL migration mirrors the simulation project's own need for structured state: both are cases where human-readable formats broke down under machine-query load. The geopolitical simulation's multi-agent architecture likely faces the same serialization pressure — agent state handoff in the simulation could benefit from the same JSONL checkpoint pattern used for Claude session continuity.

**Rule:** When designing state handoff between simulation agents, use append-only JSONL with jq-queryable checkpoints rather than markdown or free-text formats — the same pattern that solved Claude session continuity at scale.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.70)
> The vision loop (screenshot → annotate → read → act → verify) and the session continuity loop (core-dump → catchup → work → checkpoint → repeat) are structurally identical feedback loops. Both fail when the 'read back' step is skipped — coordinate guessing fails like context guessing fails. This suggests a general principle: any agent action loop that skips explicit state verification before acting will drift.

**Rule:** Treat session resumption as a 'vision loop for context': always read back the checkpoint and verify current state before acting, never assume prior state is still valid — same discipline as annotating before clicking.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 881b161f-3ee0-4597-ab7b-d6c2a860613d, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.60)
> The user's terse imperative style ('keep going', 'better', 'more') combined with iterative refinement creates a conversation protocol that resembles a REPL more than a chat. The session continuity infrastructure exists precisely because this REPL-style interaction generates enormous context volume per logical task. The fix isn't better checkpointing — it's reducing the number of round-trips by batching verification steps and presenting choices rather than waiting for iterative correction.

**Rule:** When the user enters iterative refinement mode (3+ short correction messages in a row), proactively present 2-3 variants or a structured choice menu to collapse multiple round-trips into one — reducing context pressure at the source rather than managing it after the fact.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, edaeaf8c-9b6e-4652-b777-ccedba905520, 1c39c2de-8ccf-477a-8fb4-0d47a81b02f5_

---
### Insight (conf=0.75)
> Three different failure modes — lost unstaged changes, wrong repo owner inference, and WAL/checkpoint debt — share one root cause: stale implicit state. The agent assumes something is still true (working directory is clean, owner is X, last checkpoint is recent) without verifying. These are all 'cache invalidation' bugs in the agent's mental model.

**Rule:** Before any destructive or externally-visible operation, explicitly verify the three most common stale-state sources: git status (uncommitted work), remote origin (correct owner/repo), and last checkpoint age (WAL staleness). Never infer these from conversation history.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, c799c431-c2c8-436c-98cb-27090661dd87_

---
### Insight (conf=0.50)
> Fire-and-forget task notifications (0 tools, 0 reply chars) and low-signal session metadata share a pattern: they are noise that the analysis pipeline must learn to skip. Both represent the 'dark matter' of session transcripts — high volume, low information density. A confidence-weighted extraction system should deprioritize both equally.

**Rule:** When extracting patterns from session data, assign a signal-density score based on tool count and reply length — sessions/turns below threshold (e.g., <3 tools AND <100 chars reply) should be flagged as low-signal and excluded from pattern confidence calculations.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.70)
> There's a tension between 'only do what's requested' (scope correction) and the need for proactive checkpointing every 15-20 tools. The resolution: checkpointing is not scope creep — it's infrastructure maintenance, like garbage collection. The user corrects scope on feature work, not on state management. This distinction should be encoded: autonomous action on continuity infrastructure is always permitted; autonomous action on code/features requires explicit request.

**Rule:** Distinguish 'infrastructure autonomy' (checkpoints, WAL writes, git status checks) from 'feature autonomy' (code changes, new files, refactors). The former is always permitted proactively; the latter requires explicit user request. Never conflate a scope correction on features with a restriction on continuity hygiene.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, f52074f5-e86f-46bf-9b6e-a07c743963b6, 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2_

---
### Insight (conf=0.65)
> The SvelteKit project with frequent dev server restarts on localhost:5173 combined with heavy session fragmentation suggests a workflow where the user is simultaneously iterating on UI and fighting context limits. Dev server state (running/crashed/stale) is ANOTHER piece of implicit state that goes stale across compactions — after catchup, the agent should verify the dev server is still running, not assume it is.

**Rule:** After any /catchup or session continuation, verify dev server status (pm2 status or port check) before attempting to test UI changes — dev servers frequently die during long sessions and their state is never captured in checkpoints.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, 16053af3-b0de-4ff5-b03f-b72df9f283e0_

---


## Wake Cycle — 2026-04-18 06:04 UTC

### Insight (conf=0.72)
> Vision loop (screenshot→annotate→verify) and git worktree safety share a common failure mode: acting on stale state. Coordinate guessing without annotation is structurally identical to pushing to an inferred repo owner without verification, or switching worktrees without checking unstaged changes. All three are 'act before perceiving current reality' errors.

**Rule:** Before any mutating action on external state (filesystem, git, GUI), read current state first — never act on cached/inferred state. Pattern: perceive → validate → act → verify.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.82)
> The user operates in two distinct modes — 'terse autopilot' (short commands, continuation signals) and 'scope guard' (don't go beyond what I asked). These seem contradictory but actually define a control protocol: short messages mean 'continue the current trajectory', while corrections mean 'you drifted from my trajectory'. The agent should maintain high momentum on the current vector but never change direction autonomously.

**Rule:** Interpret terse commands ('keep going', 'more') as 'continue exact current task direction at full speed' — never as permission to expand scope. Momentum yes, divergence no.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.61)
> Checkpoint debt accumulates like technical debt — and the fire-and-forget task notifications (0 tools, 0 reply) are actually natural checkpoint triggers being wasted. Every async completion signal is a free 'breath' where the agent could write a WAL checkpoint with zero user interruption cost.

**Rule:** On receiving a fire-and-forget async task notification, opportunistically write a WAL checkpoint if >10 actions have elapsed since the last one — it's free context-preservation at zero user-facing cost.

_Patterns: c799c431-c2c8-436c-98cb-27090661dd87, 16053af3-b0de-4ff5-b03f-b72df9f283e0, 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.78)
> Low-signal session metadata (sparse data, high tool counts, frequent continuations) is itself a high-signal pattern — it indicates sessions where the work-to-overhead ratio is poor. Sessions with 100+ tools and multiple continuations likely spend 30-40% of token budget on context reconstruction rather than actual work. The sparse extraction data confirms the system can't even reconstruct what happened.

**Rule:** If a session exceeds 60 tool calls, trigger an automatic efficiency review: are we spending more tokens restoring context than doing work? If yes, break into smaller scoped sessions with explicit handoff docs rather than continuing indefinitely.

_Patterns: c492a9f2-55a9-4c36-9bf3-6c98959e30a7, 5c3499d0-aef9-4924-b559-e15bf88068ed, f1057a8d-e978-416c-b52e-7ea8fd28e770_

---
### Insight (conf=0.70)
> WAL/checkpoint has become a shadow version control system running parallel to git. The user's primary state management is not git commits but WAL entries and core dumps — git tracks code, WAL tracks intent and progress. This is analogous to how databases use WAL alongside the actual data files: one for durability, one for truth.

**Rule:** Treat WAL checkpoints and git commits as complementary, not redundant: commit captures code state, checkpoint captures task state. Always pair a git commit with a WAL action entry, and a major milestone with both a commit and a WAL checkpoint.

_Patterns: 694c5087-f6dc-4dd0-88dc-8645a8dda00f, 1523746a-7091-4022-b130-7e28b7f77561, 0da89570-65b9-4bc5-8a0c-9cbf130314c9_

---


## Wake Cycle — 2026-04-18 10:10 UTC

### Insight (conf=0.72)
> Both WAL-to-JSONL migration and the vision loop follow the same meta-pattern: replacing lossy human-readable formats (markdown, coordinate guessing) with machine-queryable structured approaches (JSONL/jq, annotated pixel grids). The user gravitates toward making implicit state explicit and machine-parseable across all tool categories.

**Rule:** When designing any new state-capture or verification mechanism, default to structured machine-queryable formats over human-readable prose — the user consistently prefers precision over readability.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.78)
> All three are instances of 'stale state assumption' failures: worktree switching assumed clean state, branch operations inferred owner from cached context, and long sessions assumed prior checkpoint was still accurate. The root cause is trusting remembered state over verified state — the same bug at three different abstraction levels (filesystem, git, conversation context).

**Rule:** Before any destructive or state-dependent operation (worktree switch, git push, context resume), re-read current state from source of truth — never rely on what was true N steps ago.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, c799c431-c2c8-436c-98cb-27090661dd87_

---
### Insight (conf=0.68)
> The user's terse interaction style ('keep going', 'move') and fire-and-forget task notifications are two sides of the same coin: the user treats the agent as an autonomous worker that should maintain its own momentum. Zero-content signals are not empty — they mean 'continue with current vector.' This maps to a producer-consumer model where the user is a low-bandwidth scheduler and the agent is a high-bandwidth executor.

**Rule:** When receiving a terse or zero-content signal, reconstruct intent from the last checkpoint rather than asking for clarification — the user expects autonomous continuation, not conversational back-and-forth.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e_

---
### Insight (conf=0.65)
> The user maintains three concurrent long-running projects (geopolitical sim, iDream dashboard, SvelteKit/eBay pipeline) that all share a common architectural fingerprint: multi-agent/multi-widget decomposition, persistent backend state, and iterative UI refinement. Session continuity infrastructure isn't just a preference — it's load-bearing because the user context-switches between these projects and needs to resume each one cold.

**Rule:** At session start, identify which of the user's active projects is being resumed and load project-specific memory before general catchup — cold-start latency matters most for multi-project workflows.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.82)
> These appear contradictory (iterative refinement vs. don't over-implement) but actually describe a precise interaction contract: the user drives scope incrementally through small corrections, and the agent must match each increment exactly — no more, no less. Anticipating the next refinement step and pre-implementing it violates the contract even when the guess would be correct.

**Rule:** Implement exactly the delta requested in each iteration. Never bundle predicted next-step changes with the current request, even when they seem obvious — the user's refinement sequence is intentional.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.55)
> There's an information-theoretic decay curve: as sessions grow longer (40+ continuations), both the WAL and extracted session metadata lose signal-to-noise ratio. Sparse session data produces low-confidence extractions, and accumulated WAL entries create checkpoint debt. Both are symptoms of entropy accumulation in long-lived state — the same problem that makes eventual consistency hard in distributed systems.

**Rule:** At every 20th tool call, write a compacted checkpoint that replaces (not appends to) prior checkpoints — treat checkpoints as snapshots, not append logs, to bound entropy growth.

_Patterns: c492a9f2-55a9-4c36-9bf3-6c98959e30a7, f1057a8d-e978-416c-b52e-7ea8fd28e770, 16053af3-b0de-4ff5-b03f-b72df9f283e0_

---
### Insight (conf=0.58)
> The preference for generic reusable test patterns and the WAL migration to JSONL share a deeper principle: the user values composability over specificity. Generic tests compose across features; JSONL composes with jq, grep, and any JSON toolchain. The user's infrastructure taste consistently favors Unix-philosophy small-piece composability.

**Rule:** When building any tooling or test infrastructure, prefer formats and patterns that compose with standard Unix tools (pipes, jq, grep) over bespoke parsers or one-off implementations.

_Patterns: c1405960-924b-4896-b075-e8de0d9868d1, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---
### Insight (conf=0.60)
> The vision loop (screenshot → annotate → verify), globe/terrain visualization work, and iterative UI refinement all center on visual-spatial reasoning as the primary feedback channel. The user thinks visually — their debugging, design, and verification workflows all close the loop through visual inspection rather than log analysis or test assertions.

**Rule:** When verifying UI or spatial changes, always close the loop with a visual artifact (screenshot, rendered preview) rather than relying solely on code-level assertions — the user's mental model is visual-first.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, 92a767af-37ad-4b83-84af-684fd98948b5_

---


## Wake Cycle — 2026-04-18 19:30 UTC

### Insight (conf=0.65)
> The WAL markdown-to-JSONL migration and the desktop automation vision loop share a deeper principle: replacing human-readable-but-fragile formats with machine-queryable-but-verifiable ones. Markdown WAL was like guessing coordinates — it worked until it didn't. JSONL + jq is the equivalent of annotate-then-act: structured observation before action. Both migrations move from 'looks right' to 'provably parseable'.

**Rule:** When designing any state-persistence or observation mechanism, prefer structured machine-queryable formats (JSONL, coordinate grids) over human-readable ones (markdown, visual estimation) — the verification step pays for itself across session boundaries.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, 846615fc-eeb8-4a44-bf0a-bf06c723fde8, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.72)
> The user's project domains (geopolitical multi-agent simulation, dream-tracking dashboard, eBay parts pipeline) all share a common architectural fingerprint: long-lived stateful systems with many interacting components that evolve over time. The session continuity obsession isn't just a tooling preference — it mirrors the domain problems themselves. The user builds systems that must maintain coherent state across interruptions, and demands the same from their development tool.

**Rule:** When working on this user's projects, treat development session state with the same rigor as application state — both are long-lived, interrupt-prone, and lose value when context is dropped.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c, 881b161f-3ee0-4597-ab7b-d6c2a860613d_

---
### Insight (conf=0.78)
> The user's terse command style ('keep going', 'more', 'started') combined with their scope correction ('only help understand, don't autonomously implement') reveals a trust gradient: high autonomy for continuation of established direction, zero autonomy for new direction. The iterative UI refinement pattern confirms this — the user steers with micro-corrections, not upfront specs. This is a 'fly-by-wire' interaction model where the human provides heading adjustments and the agent maintains altitude.

**Rule:** Interpret terse continuation commands as 'maintain current vector with full autonomy' but treat any new topic or scope expansion as requiring explicit user approval before acting — never extrapolate from continuation permission to initiation permission.

_Patterns: edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 92a767af-37ad-4b83-84af-684fd98948b5, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.70)
> Git worktree data loss, incorrect repo owner inference, and WAL checkpoint debt are all instances of the same failure mode: stale assumptions surviving across context boundaries. Worktrees assume clean state, org names are inferred from expired context, and WAL debt accumulates when checkpoints aren't reset. The common root is that boundary crossings (session, worktree, repo) silently invalidate cached state.

**Rule:** At every context boundary crossing (session resume, worktree switch, repo change), run an explicit state verification step — never carry forward assumptions about working tree cleanliness, remote ownership, or checkpoint freshness.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, c799c431-c2c8-436c-98cb-27090661dd87_

---
### Insight (conf=0.55)
> Fire-and-forget task notifications (0 tools, 0 reply chars) and low-signal session metadata share an information-theoretic property: they are markers of work happening elsewhere. Combined with the 10-100+ tool continuation pattern, this suggests the system operates in a 'dark matter' regime where most meaningful work is invisible to any single observation point. The sessions with highest tool counts likely have the lowest per-tool information density.

**Rule:** When analyzing session patterns, weight information by density (insight per tool call), not volume — a 10-tool session with clear decisions may be more informative than a 100-tool continuation session that is mostly mechanical execution.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, c492a9f2-55a9-4c36-9bf3-6c98959e30a7, f1057a8d-e978-416c-b52e-7ea8fd28e770_

---
### Insight (conf=0.68)
> The SvelteKit project on localhost:5173 uses git for code versioning but /catchup + /core-dump for development state management — these are parallel version control systems for different artifacts. Code changes are small and discrete (git commits); development context is large and continuous (WAL checkpoints). This dual-track versioning is emergent and unformalized, but it's load-bearing infrastructure.

**Rule:** Recognize that this user's workflow has two versioning tracks: git for code artifacts and WAL/checkpoint for development context. Neither substitutes for the other — a git log cannot reconstruct intent, and a WAL cannot reconstruct code state. Both must be maintained in parallel.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, 694c5087-f6dc-4dd0-88dc-8645a8dda00f_

---


## Wake Cycle — 2026-04-19 13:06 UTC

### Insight (conf=0.72)
> The WAL markdown-to-JSONL migration and the git worktree data-loss incident share a root cause: human-readable formats (markdown, unstaged diffs) are fragile under automated tooling. Both were solved by moving to machine-first representations (JSONL, explicit stash-before-switch). This suggests a general principle: any state that an agent reads/writes programmatically should be structured data, not prose.

**Rule:** When introducing new agent-managed state files, default to JSONL or JSON — never markdown. Reserve markdown for human-authored documents only.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, 846615fc-eeb8-4a44-bf0a-bf06c723fde8, 5287886b-6995-4b9f-a22f-38e91d2a0ce4_

---
### Insight (conf=0.81)
> The user's terse command style ('keep going', 'more', 'better') and their iterative UI refinement pattern are two faces of the same coin: they treat the agent as a continuous executor with persistent intent, not a request-response system. Each short message is a delta on an implicit running task. This is why session continuity is so critical — the user's mental model assumes the agent remembers the full task even across compactions.

**Rule:** When receiving a terse continuation command after compaction, reconstruct the last task's full intent from WAL before executing — never interpret the terse message in isolation.

_Patterns: edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.75)
> All four active projects (geopolitical simulation, iDream dashboard, SvelteKit/eBay pipeline, globe visualization) share a common architectural signature: they are stateful, long-lived systems with complex data transformations and rich UI surfaces. This profile maximally stresses context windows — explaining why session continuity tooling dominates the pattern set. The user isn't just 'preferring' /catchup; the project portfolio structurally demands it.

**Rule:** For projects with both data-pipeline and rich-UI layers, auto-checkpoint every 12 tool calls instead of the default 15-20, since state accumulates faster in these architectures.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.68)
> The desktop automation vision loop (screenshot → annotate → act → verify) and the UI refinement loop (change → screenshot → user feedback → change) are isomorphic feedback cycles. The validated pattern for desktop automation — never act without visual verification — should also apply to dashboard CSS work: never report a UI change as done without a screenshot diff against the previous state.

**Rule:** For iterative UI refinement sessions, capture a 'before' screenshot at task start and present a before/after comparison when reporting completion, so the user can validate the delta without re-checking manually.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.85)
> There is a tension between the user's terse continuation style ('keep going') which implies autonomous execution, and their explicit correction that the agent should not implement beyond what was requested. The reconciliation: 'keep going' means 'continue the already-scoped task', not 'expand scope autonomously'. The implicit contract is that scope is set once (at task definition) and continuation commands operate within that fixed scope.

**Rule:** On terse continuation commands, replay the original task scope from WAL/checkpoint and continue only within those bounds. Never interpret 'keep going' as permission to expand scope.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, 2dfa1a6e-03f6-473e-8476-8a5da501300e, edaeaf8c-9b6e-4652-b777-ccedba905520_

---
### Insight (conf=0.55)
> Fire-and-forget task notifications (0 tools, 0 reply), low-signal session extractions, and WAL/checkpoint debt are all symptoms of the same meta-problem: the system generates more metadata than it consumes. Notifications nobody reads, learnings flagged as unreliable, and WAL entries that pile up uncleaned all represent write-heavy/read-light information flows. The system would benefit from a garbage-collection pass that prunes low-value entries.

**Rule:** At session start, if WAL exceeds 100 lines, run a GC pass: drop fire-and-forget notifications, merge duplicate checkpoint entries, and remove learnings with confidence < 0.85.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, c492a9f2-55a9-4c36-9bf3-6c98959e30a7, 16053af3-b0de-4ff5-b03f-b72df9f283e0_

---
### Insight (conf=0.78)
> Both git worktree data loss and incorrect repository owner inference are instances of the same anti-pattern: inheriting state from a prior context without verification. Worktree switching assumed clean state; repo owner was inferred from stale session data. Both broke because the agent trusted cached assumptions over current reality.

**Rule:** After any context restoration (/catchup, compaction resume), treat all git state (branch, remote, working tree cleanliness, repo owner) as unknown and re-query before any write operation.

_Patterns: bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5287886b-6995-4b9f-a22f-38e91d2a0ce4_

---
### Insight (conf=0.70)
> The user runs multiple long-lived dev servers (SvelteKit on 5173, iDream via pm2 on 30xx/50xx) while doing batch task resumption via /catchup. Dev server state is invisible to the checkpoint system — a /catchup might restore code context perfectly but leave the user with a stale or crashed server. Server health should be part of the catchup verification.

**Rule:** During /catchup, after restoring code context, check pm2 status and verify any project dev servers are running. Report server state alongside task state.

_Patterns: fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 07e91a34-f2bd-4d49-8ac8-b81f1d0cd808_

---


## Wake Cycle — 2026-04-19 17:12 UTC

### Insight (conf=0.60)
> The vision loop pattern (screenshot → annotate → read → act → verify) and the catchup pattern (checkpoint → read → orient → act) are structurally identical feedback loops — both compensate for an agent's inability to maintain persistent perception. Desktop automation and session continuity are the same problem (state blindness) in different modalities.

**Rule:** Treat session recovery and desktop automation with the same rigor: never act without first verifying current state (screenshot/catchup), never assume prior state persists, always verify after acting.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, ef9a0ad9-13be-470f-9881-2b6c679d640b, 5ac572b8-2860-4b61-b617-5214c9898c3a_

---
### Insight (conf=0.50)
> The user's terse command style ('keep going', 'more', 'better') combined with iterative UI refinement suggests a conductor/orchestra mental model — the user provides directional nudges, not specifications. This is the same interaction pattern as a game director steering AI agents in their simulation project. The user treats Claude as one of their simulation agents.

**Rule:** When receiving terse directional commands, infer continuation vector from the last 3-5 actions rather than asking for clarification. The user is steering, not specifying — momentum matters more than precision.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e_

---
### Insight (conf=0.75)
> Context window pressure and git worktree data loss are both manifestations of the same root cause: the agent operates without durable memory, so any boundary crossing (compaction, worktree switch) risks state loss. The user has built an entire infrastructure layer (WAL, core-dump, catchup, checkpoints) that is essentially a userspace implementation of database transaction logging — because the agent runtime doesn't provide ACID guarantees.

**Rule:** Before any operation that crosses a state boundary (compaction, worktree switch, branch change, long tool sequence), write a checkpoint. Treat state boundaries like transaction boundaries — commit before switching.

_Patterns: c799c431-c2c8-436c-98cb-27090661dd87, 16053af3-b0de-4ff5-b03f-b72df9f283e0, 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2, 5287886b-6995-4b9f-a22f-38e91d2a0ce4_

---
### Insight (conf=0.70)
> Three separate patterns warn against acting on inferred rather than verified state: don't infer git owners, don't autonomously implement beyond scope, don't trust low-signal data. These form a single meta-principle: the agent's confidence calibration is systematically too high — it defaults to acting when it should default to verifying.

**Rule:** When confidence in any inferred state (repo owner, user intent, data completeness) is below 0.95, verify before acting. The cost of one verification question is always less than the cost of an incorrect autonomous action.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.55)
> The user simultaneously maintains four complex projects (geopolitical simulation, dream dashboard, SvelteKit data pipeline, Claude infrastructure). All four share: widget/component architecture, data persistence concerns, and multi-session workflows. The user is a systems thinker who applies the same architectural patterns across radically different domains — suggesting cross-project pattern libraries and shared abstractions would be highly valued.

**Rule:** When implementing a pattern in one project (e.g., widget lifecycle, state persistence, dark/light toggle), check if the same pattern exists in other active projects and offer to extract a shared abstraction if it appears 3+ times.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.50)
> Three projects use localhost dev servers (SvelteKit 5173, iDream pm2, simulation). Combined with the desktop automation vision loop, the user's workflow involves frequent visual verification across multiple running services. A unified 'health check all services' command would reduce the friction of context-switching between projects.

**Rule:** At session start, if the project has a pm2 or dev server config, run a quick health check (pm2 status / port check) before beginning work — stale servers from prior sessions cause silent failures.

_Patterns: fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9_

---


## Wake Cycle — 2026-04-20 01:52 UTC

### Insight (conf=0.92)
> The WAL markdown-to-JSONL migration appears three times with near-identical content, suggesting the pattern extraction system itself lacks deduplication — the very state management problem the WAL solves is present in the pattern database.

**Rule:** Before persisting a new pattern, fuzzy-match against existing patterns on (category + key entities) and merge rather than append when similarity > 0.8.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, 846615fc-eeb8-4a44-bf0a-bf06c723fde8_

---
### Insight (conf=0.72)
> The user's terse interaction style ('keep going', 'move') and the fire-and-forget notification pattern share a common communication philosophy: minimal-signal, maximum-context-inference. The user expects the system to carry forward intent from prior state rather than re-specifying it.

**Rule:** When receiving a terse continuation command, reconstruct intent from the last WAL checkpoint rather than asking clarifying questions — the user has already optimized their workflow for low-bandwidth signaling.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e_

---
### Insight (conf=0.68)
> The vision loop pattern (screenshot → annotate → act → verify) and the iterative UI refinement workflow are the same feedback loop at different abstraction levels. Desktop automation uses pixel-level verify-then-act; UI development uses user-level verify-then-refine. Both require closing the loop with visual confirmation before proceeding.

**Rule:** For any UI change during iterative refinement sessions, automatically screenshot and present after each edit — don't wait for the user to ask. The user's workflow assumes visual verification is built into the loop.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.55)
> The checkpoint frequency recommendations (every 15-20 tool calls, at milestones, before risky ops) collectively describe a garbage-collection-like strategy: periodic compaction prevents unbounded growth of context debt. The 40+ tool call threshold acts as a soft memory pressure signal analogous to GC thresholds in runtime systems.

**Rule:** Implement an automatic checkpoint trigger at 20 tool calls since last checkpoint — treat it as a GC pause rather than a user-initiated save, emitting the checkpoint silently into the WAL without interrupting flow.

_Patterns: c799c431-c2c8-436c-98cb-27090661dd87, 16053af3-b0de-4ff5-b03f-b72df9f283e0, 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2, 3d9745f8-ff2e-4e94-be3c-89586e47cd3a_

---
### Insight (conf=0.70)
> Three distinct 'look before you leap' failures — worktree losing unstaged changes, wrong repo owner inference, and agent overstepping scope — all stem from the same root cause: acting on stale or assumed state instead of querying current state. The session continuity system itself creates this risk by encouraging agents to trust reconstructed context.

**Rule:** After /catchup, treat all reconstructed state as 'stale until verified' — before any destructive or externally-visible action, re-query the actual current state (git status, file existence, branch owner) rather than trusting checkpoint data.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.75)
> The user maintains multiple long-running projects simultaneously (iDream dashboard, SvelteKit data pipeline, geopolitical simulation) all requiring pm2/dev-server management and session continuity. The session continuity overhead scales linearly with project count — each project needs its own WAL, checkpoints, and context reconstruction.

**Rule:** When /catchup detects a project switch (CWD differs from last session's project), load only that project's WAL — do not attempt to reconstruct cross-project state, as it wastes context window on irrelevant checkpoints.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a_

---
### Insight (conf=0.60)
> The user's state management preference (core-dump > git > comments) reveals a fundamental mismatch between how LLM agents and traditional developers persist context. Git captures code state; core-dump captures cognitive state (intent, next steps, blockers). The user has independently invented a 'cognitive version control' layer that sits above source control.

**Rule:** Treat WAL/checkpoint as a first-class persistence layer alongside git — commit code changes AND write a WAL checkpoint in the same logical operation, so cognitive and code state stay synchronized.

_Patterns: 584e7697-e747-48e6-9cd8-274ccffd99d8, 48d98c46-03d4-43f1-a85f-b355ec92e845, 694c5087-f6dc-4dd0-88dc-8645a8dda00f_

---


## Wake Cycle — 2026-04-20 05:56 UTC

### Insight (conf=0.72)
> The WAL migration from markdown to JSONL mirrors database evolution patterns — the user is essentially building a personal transaction log system. The 'WAL debt' pattern suggests the system needs automatic compaction/garbage collection, analogous to how databases handle WAL segment recycling.

**Rule:** Implement automatic WAL compaction: after a session_end event, if the JSONL exceeds 200 lines, retain only the last 2 session boundaries and their checkpoints, archiving the rest to a dated file.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, 846615fc-eeb8-4a44-bf0a-bf06c723fde8, 16053af3-b0de-4ff5-b03f-b72df9f283e0_

---
### Insight (conf=0.61)
> The vision-loop pattern for desktop automation (screenshot → annotate → act → verify) is structurally identical to the user's iterative UI refinement workflow (render → inspect → tweak → verify). Both are perception-action loops where 'guessing without looking' fails. This suggests the user values empirical verification over inference in all visual domains.

**Rule:** For any visual output (UI, diagram, report), always render-and-verify before reporting done — never claim visual correctness from code inspection alone.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.58)
> The user operates in two distinct modes: terse continuation ('keep going') where maximum autonomy is expected, and scope-correction mode where the agent overstepped. The switching signal is message length — short messages grant autonomy, longer corrective messages restrict it. This is a implicit protocol the user has developed.

**Rule:** When the user sends a message under 5 words that isn't a question, treat it as 'continue with current plan at current autonomy level.' When they send a correction or clarification, reduce autonomy scope to exactly what's stated until the next terse continuation signal.

_Patterns: edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.78)
> All three patterns share a root cause: acting on stale or inferred state instead of verifying current state. Git worktree lost unstaged changes (assumed clean), wrong repo owner (inferred from context), low-confidence extractions (sparse data treated as complete). This is the 'stale cache' anti-pattern applied to agent cognition.

**Rule:** Before any destructive or irreversible action, verify the specific precondition it depends on — never inherit state assumptions from prior context or inference. Treat all state older than the current tool-call round as potentially stale.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.68)
> The user maintains multiple large projects simultaneously (SvelteKit data pipeline, iDream dashboard, geopolitical simulation). The heavy investment in session continuity infrastructure is a direct consequence of context-switching between these projects — each /catchup is essentially a 'load project into working memory' operation, making the Claude config system function as a personal project-switching multiplexer.

**Rule:** When /catchup detects a project switch (different CWD than last session's WAL), prioritize loading project-specific memory and runtime-notes over WAL replay — the user needs domain context more than action history when switching projects.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.55)
> WAL and checkpoint files are described as 'load-bearing infrastructure' — the same term used for production systems. This user treats their AI development environment with the same reliability engineering mindset as production services. The implication: session continuity failures should be treated with the same severity as production incidents (postmortem, root-cause, prevention).

**Rule:** When a /catchup fails or produces incomplete context recovery, treat it as an incident: log what was lost, identify the gap in the checkpoint chain, and add a preventive checkpoint rule to avoid the same failure mode.

_Patterns: e218ac38-3844-4295-a972-c9dc01b22d13, 1523746a-7091-4022-b130-7e28b7f77561, 07e91a34-f2bd-4d49-8ac8-b81f1d0cd808_

---


## Wake Cycle — 2026-04-20 19:50 UTC

### Insight (conf=0.72)
> The WAL markdown-to-JSONL migration and the desktop automation vision loop share a deeper principle: replacing fuzzy/lossy formats (markdown parsing, coordinate guessing) with structured, machine-queryable ones (JSONL/jq, annotated grid coordinates). Both solved reliability problems by making implicit information explicit and parseable. This suggests a general rule: any handoff boundary (session-to-session, human-to-machine) that uses prose or heuristics is a future failure point.

**Rule:** When designing any inter-agent or inter-session communication boundary, prefer structured machine-readable formats over prose. If a handoff currently relies on parsing natural language or inferring from context, it is a reliability debt that should be migrated to a structured format.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, 846615fc-eeb8-4a44-bf0a-bf06c723fde8, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.65)
> The user's domain projects (geopolitical multi-agent simulation, dream dashboard, SvelteKit data pipeline) all share a trait: they are architecturally complex systems that exceed a single context window. The session continuity infrastructure (WAL, checkpoints, core-dumps) is not just a convenience — it is itself a form of the same distributed-state-management problem the user's projects solve. The user is essentially building 'agent memory' systems both in their products and in their tooling.

**Rule:** When the user works on projects involving distributed state or multi-agent coordination, leverage analogies from their session-continuity infrastructure (WAL, checkpoints, catchup) to inform architectural suggestions — the patterns are isomorphic.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c, 16053af3-b0de-4ff5-b03f-b72df9f283e0_

---
### Insight (conf=0.68)
> Terse user commands ('keep going', 'move'), fire-and-forget task notifications (0 tools, 0 reply chars), and short resumption signals form a consistent 'low-bandwidth control protocol.' The user treats the agent like a running process that needs occasional signals, not a conversational partner requiring full context in each message. This is closer to Unix process signaling (SIGCONT, SIGHUP) than to chat.

**Rule:** Treat single-word or very short user messages as process control signals, not underspecified requests. Map them to the most recent active task context without asking for clarification. 'keep going' = SIGCONT, 'stop' = SIGTSTP, 'move' = skip current subtask.

_Patterns: edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.75)
> Git worktree data loss, incorrect owner inference, and WAL/checkpoint debt are all instances of the same failure mode: stale state assumptions. Worktree switching assumed clean state, repo owner was inferred from stale context, and WAL debt accumulated because checkpoints were assumed recent. Each failure occurred at a boundary where cached assumptions diverged from reality.

**Rule:** At any state boundary (session resume, branch switch, worktree change, repo operation), treat ALL cached assumptions as potentially stale. Run a verification step before acting: git status before worktree ops, gh api before repo ops, WAL freshness check before catchup.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, c799c431-c2c8-436c-98cb-27090661dd87_

---
### Insight (conf=0.70)
> The user's iterative UI refinement style ('better', 'good but...', 'revert colors') combined with the explicit correction to limit agent scope reveals a tension: the user wants tight feedback loops on aesthetics but not autonomous extrapolation. This maps to a 'cruise control' mental model — the user steers direction with micro-corrections while the agent maintains velocity, but the agent must never change lanes on its own.

**Rule:** During UI iteration sessions, apply each requested change precisely and immediately screenshot for verification. Never bundle aesthetic changes with structural refactors. Each turn should change exactly one visual property unless the user explicitly groups them.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.55)
> Low-signal session metadata and high-tool-count sessions are inversely correlated in usefulness: the sessions with the most activity (100+ tools) produce the richest learnings, but their metadata summaries are the least representative of what actually happened. Meanwhile, sparse sessions get over-weighted because their metadata IS all we have. This is a form of survivorship bias in pattern extraction.

**Rule:** Weight pattern confidence by session richness, not metadata completeness. Patterns extracted from sessions with only ID/description/tool-count should be tagged low-signal and require corroboration from at least one rich-context session before being promoted to actionable rules.

_Patterns: c492a9f2-55a9-4c36-9bf3-6c98959e30a7, f1057a8d-e978-416c-b52e-7ea8fd28e770, 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2_

---
### Insight (conf=0.78)
> The user's state management lives in two parallel systems: git (code state) and WAL/checkpoints (task state). For this user, WAL/checkpoints are MORE load-bearing than git for session continuity — git tracks what was done, but WAL tracks what to do next. This is unusual and means the WAL system is effectively a task-level version control system running alongside code-level version control.

**Rule:** Treat WAL/checkpoint writes with the same discipline as git commits: never lose them, always verify freshness before acting on them, and maintain them as first-class infrastructure rather than optional convenience.

_Patterns: 1523746a-7091-4022-b130-7e28b7f77561, 694c5087-f6dc-4dd0-88dc-8645a8dda00f, b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a_

---
### Insight (conf=0.62)
> The validated vision loop pattern (screenshot → annotate → read → act → verify) and the UI iteration pattern (change → screenshot → user feedback → change) are the same closed-loop control system at different timescales. Desktop automation does it in seconds (machine feedback), UI refinement does it in minutes (human feedback). Both fail when the verification step is skipped.

**Rule:** Any action on a visual system (desktop automation OR UI development) must include a post-action verification screenshot before reporting success. The feedback loop is: act → capture → verify → report. Never report completion based on code changes alone.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---


## Wake Cycle — 2026-04-21 03:47 UTC

### Insight (conf=0.60)
> The user's terse command style ('keep going', 'move', 'more') is not just a preference — it's an adaptation to context window pressure. Every token spent on verbose instructions is a token lost from the working context. The heavy session fragmentation creates evolutionary pressure toward minimal-token interaction patterns, similar to how high-latency networks evolve compressed protocols.

**Rule:** When the user issues terse continuation commands, reconstruct full intent from the last WAL checkpoint rather than asking clarifying questions — each round-trip costs context budget.

_Patterns: edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, c799c431-c2c8-436c-98cb-27090661dd87_

---
### Insight (conf=0.70)
> The vision loop for desktop automation (screenshot → annotate → act → verify) and the iterative UI refinement loop (render → screenshot → adjust → re-render) are the same feedback pattern at different abstraction levels. Both fail when the verification step is skipped. This suggests a unified 'observe-act-verify' primitive that should be enforced as a protocol, not a convention.

**Rule:** Any action that modifies visual output (UI change, desktop click, CSS edit) must include a post-action verification screenshot before reporting success — treat visual changes as untrusted until observed.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.65)
> Three different 'don't assume state' failures — git worktree losing unstaged changes, wrong repo owner inference, and autonomous over-implementation — all share the same root cause: the agent substituted cached/inferred state for verified current state. Context continuity tools (catchup/core-dump) create a false sense of complete knowledge, making these 'stale cache' errors more likely, not less.

**Rule:** After any /catchup or session restoration, treat all mutable external state (git status, running processes, repo ownership, file contents) as unverified — re-check before acting, even if the checkpoint says it was X.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.50)
> WAL + checkpoint has become a parallel version control system that operates at a different granularity than git. Git tracks code snapshots; WAL tracks agent cognitive state. The user's workflow implicitly maintains two timelines — one for artifacts (git) and one for intent (WAL). These could be formally linked: each git commit could embed the WAL checkpoint hash, creating a bidirectional map between 'what changed' and 'what the agent was thinking when it changed.'

**Rule:** When committing, include the last WAL checkpoint's session_id and goal in the commit message trailer (e.g., 'WAL-ref: fix-auth-3b checkpoint@2026-04-21') to link code history with agent intent history.

_Patterns: 694c5087-f6dc-4dd0-88dc-8645a8dda00f, 1523746a-7091-4022-b130-7e28b7f77561, 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2_

---
### Insight (conf=0.50)
> The preference for generic reusable tests and the iterative UI refinement style are in tension: generic tests assume stable interfaces, but iterative refinement means interfaces change frequently. This suggests tests for UI components should be written as property-based or snapshot-based (tolerant of visual drift) rather than exact-match assertions.

**Rule:** For iteratively-refined UI components, prefer visual regression tests or property-based tests over exact pixel/value assertions — the 'correct' output is a moving target during active refinement.

_Patterns: c1405960-924b-4896-b075-e8de0d9868d1, 92a767af-37ad-4b83-84af-684fd98948b5_

---


## Wake Cycle — 2026-04-21 07:51 UTC

### Insight (conf=0.55)
> The WAL markdown-to-JSONL migration mirrors the geopolitical simulation's own need for structured, machine-queryable state — both are cases where human-readable formats broke down under scale. The simulation project's multi-agent architecture likely hit similar 'state handoff between agents' problems that drove the WAL migration. JSONL WAL is effectively a simplified event-sourcing pattern, which is also the natural architecture for turn-based simulation engines.

**Rule:** When building multi-agent simulation state, use append-only JSONL event logs (same as WAL) rather than mutable state files — the session continuity infrastructure already validates this pattern at scale.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.70)
> The desktop automation vision loop (screenshot → annotate → act → verify) and the iterative UI refinement workflow (user says 'better', 'revert colors') are the same feedback loop at different abstraction levels. The user's aesthetic iteration pattern IS a human vision loop. Both fail when verification is skipped — coordinate guessing fails in automation just as assuming 'it looks fine' fails in dashboard styling.

**Rule:** After any visual change (CSS, layout, theme), take a screenshot and present it before reporting done — treat UI code changes as requiring the same verify-before-proceed discipline as desktop automation clicks.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.65)
> The user's terse continuation commands ('keep going', 'move') are the human equivalent of the fire-and-forget task notification signals (0 tools, 0 reply chars). Both are minimal-bandwidth 'proceed' signals that carry no new information — only intent to continue. The system should treat them identically: resume from last known state without requesting clarification.

**Rule:** When receiving a terse user message OR a zero-content task notification, treat both as 'resume from last checkpoint' signals — read the WAL's last checkpoint and continue from its 'next' field without asking for clarification.

_Patterns: edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.60)
> Git worktree data loss, incorrect repo owner inference, and context window pressure are all manifestations of the same root cause: stale state assumptions. Worktrees assume clean state, owner inference assumes prior session was correct, and long sessions assume context survives compaction. All three fail silently when the assumption is wrong.

**Rule:** Before any operation that depends on environmental state (git status, repo ownership, current branch, session context), re-verify from source rather than trusting cached/remembered values — stale state is the #1 class of silent failures across all domains.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, c799c431-c2c8-436c-98cb-27090661dd87_

---
### Insight (conf=0.75)
> There is a tension between the user wanting the agent to be proactively autonomous (core-dump without being asked, checkpoint proactively) and wanting it to stay within requested scope (don't implement beyond what was asked). The resolution: autonomy is welcomed for meta-operations (state management, checkpointing, diagnostics) but not for domain operations (code changes, feature additions). The user wants a self-maintaining tool, not a self-directing collaborator.

**Rule:** Be maximally proactive on infrastructure/meta tasks (checkpoints, WAL writes, state verification) but strictly reactive on domain tasks (only implement what was explicitly requested). The boundary is: 'does this change what the code does?' If yes, wait for instruction.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, 584e7697-e747-48e6-9cd8-274ccffd99d8, 694c5087-f6dc-4dd0-88dc-8645a8dda00f_

---
### Insight (conf=0.60)
> Session fragmentation every 5-10 tool calls, context limit hits, and low-signal extraction from sparse session data form a degradation cascade: frequent compaction → sparse recovered context → lower quality resumption → more tool calls to re-derive state → faster compaction. This is a positive feedback loop that the checkpoint system partially breaks, but the real fix would be reducing tool call volume per unit of work.

**Rule:** When a session is approaching 30+ tool calls, consolidate remaining work into fewer, larger operations (batch file reads, combine related edits) to slow the compaction-fragmentation cycle rather than just adding more checkpoints.

_Patterns: f52074f5-e86f-46bf-9b6e-a07c743963b6, 5c3499d0-aef9-4924-b559-e15bf88068ed, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---


## Wake Cycle — 2026-04-21 18:37 UTC

### Insight (conf=0.72)
> The WAL migration from markdown to JSONL mirrors database journaling evolution — the same reason databases moved from human-readable logs to binary WAL is why agent state management benefits from structured, machine-queryable checkpoints. This suggests the next evolution is incremental/delta-based checkpoints (like PostgreSQL's WAL segments) rather than full-state snapshots, which would dramatically reduce checkpoint write cost and enable sub-second catchup.

**Rule:** Checkpoint writes should be delta-based: store only fields changed since last checkpoint, with a full snapshot every N deltas. Catchup reconstructs by replaying deltas forward from last full snapshot.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, 42e3c2e2-b3bb-4e00-8b53-e4a9e3e3e9d2_

---
### Insight (conf=0.61)
> Terse user commands ('keep going', 'move'), fire-and-forget task notifications (0 tools, 0 chars), and session continuation handoffs are all instances of the same pattern: minimal-signal state transitions. The system already handles fire-and-forget signals well but treats terse user commands as requiring full context reconstruction. These should be unified — a 'keep going' after compaction should trigger the same lightweight resume path as a task notification, not a full catchup cycle.

**Rule:** Classify user messages under 5 words as 'continuation signals' — skip full context reconstruction and instead read only the last WAL checkpoint plus any pending tasks, same as handling a task notification.

_Patterns: edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.65)
> The desktop automation vision loop (screenshot → annotate → act → verify) and the iterative UI refinement workflow (make change → screenshot → user feedback → adjust) are the same feedback loop at different timescales. Both require visual verification before proceeding. This suggests the UI refinement workflow should be automated the same way: after every CSS/layout change, auto-screenshot and diff against the previous state, presenting the visual delta to the user rather than waiting for them to manually check.

**Rule:** After any UI-affecting code change, automatically capture a screenshot and present it inline — do not report 'done' without visual proof. For iterative refinement sessions, maintain a before/after pair for each change.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.68)
> Git worktree data loss, incorrect repo owner inference, and context limit crashes are all manifestations of 'stale state assumption' — the agent assumes something is still true (unstaged changes are safe, the owner is X, context hasn't been compacted) without verifying. The session continuity infrastructure solves this for conversation state but not for environment state. There should be a parallel 'environment checkpoint' that snapshots git status, working directory state, and running processes alongside the WAL checkpoint.

**Rule:** WAL checkpoint events should include an 'env' field capturing: current branch, dirty file count, running pm2 processes, and CWD — so catchup can detect environment drift, not just conversation drift.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.58)
> Sessions with 20-80+ tool calls per turn and sparse metadata (only ID, tool count, reply size) create an observability gap — the system knows a lot happened but not what mattered. This is analogous to high-cardinality distributed tracing where you need sampling. The pattern suggests implementing 'significance scoring' for tool calls so that checkpoints and session summaries can prioritize the 5-10 most consequential actions out of 80, rather than treating all tools equally.

**Rule:** WAL action events should include a 'significance' field (0-3): 0=read-only lookup, 1=state query, 2=mutation, 3=irreversible action. Checkpoints should summarize only significance >= 2 events.

_Patterns: c492a9f2-55a9-4c36-9bf3-6c98959e30a7, f1057a8d-e978-416c-b52e-7ea8fd28e770, c892fa80-f5af-4270-9e16-9225249062cc_

---
### Insight (conf=0.70)
> The tension between 'agent should not autonomously implement beyond what was requested' and '100+ turn sessions with checkpoints every 5-10 interactions' reveals a paradox: the user needs autonomous execution for long sessions to be productive, but also needs tight scope control. The resolution is granularity — the user wants autonomous execution WITHIN a defined scope but explicit confirmation at scope boundaries. Current checkpointing is time-based; it should be scope-based.

**Rule:** At each checkpoint, re-state the current scope boundary ('I am working on X, not touching Y'). If the next logical step crosses that boundary, pause for confirmation even mid-flow.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, e181d5f7-4435-4c76-a1a4-82f3536aac19, f52074f5-e86f-46bf-9b6e-a07c743963b6_

---
### Insight (conf=0.52)
> The SvelteKit project uses localhost:5173 as its primary feedback loop, while session state management uses /catchup + /core-dump instead of git. This reveals that the user treats the running dev server as the source of truth (not the repo), mirrored by treating WAL checkpoints as the source of truth (not git history). Both are 'hot state' preferences over 'cold storage'. This suggests the dev server state (which routes work, which have errors) should be captured in checkpoints too.

**Rule:** When a dev server is running, WAL checkpoints should include a quick health probe (curl the main route) to capture whether the app was in a working state at checkpoint time.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, 694c5087-f6dc-4dd0-88dc-8645a8dda00f_

---


## Wake Cycle — 2026-04-21 20:05 UTC

### Insight (conf=0.55)
> The user's terse iterative commands ('better', 'keep going', 'more') function as a gradient descent on UI quality — each short message is a directional nudge, not a specification. This means the agent's job is less 'follow instructions' and more 'maintain a loss function' (visual satisfaction) and take steps that minimize it. Front-loading screenshot verification is the equivalent of evaluating the loss before reporting convergence.

**Rule:** When receiving terse iterative UI feedback, treat it as a direction vector, not a destination. Always screenshot-verify before reporting done, and propose 2-3 next refinements proactively since the user will likely continue iterating.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, edaeaf8c-9b6e-4652-b777-ccedba905520, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.60)
> The session continuity problem is essentially a distributed systems problem: context windows are like nodes with limited memory, checkpoints are like consensus snapshots, and the 0-tool fire-and-forget notifications are heartbeats. The user has organically built a distributed state machine where WAL is the commit log and /catchup is crash recovery. This suggests borrowing more distributed systems patterns — e.g., compaction thresholds, read-repair on stale state.

**Rule:** Treat context compaction as a 'node restart' event: immediately write a checkpoint (like a WAL flush before shutdown), and on /catchup, perform 'read-repair' by verifying file state matches the last checkpoint rather than trusting it blindly.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, f52074f5-e86f-46bf-9b6e-a07c743963b6, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.75)
> All three patterns share a root cause: acting on stale or assumed state instead of verifying current reality. Desktop automation guesses coordinates without screenshots, git ops infer repo ownership from memory, worktree switches skip checking unstaged changes. The common fix is the same: 'observe before acting' as an invariant — screenshot before click, git remote -v before push, git status before worktree switch.

**Rule:** Before any side-effecting operation (click, push, checkout, delete), run exactly one read-only verification command that confirms the current state matches assumptions. Never act on cached/remembered state for destructive operations.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5287886b-6995-4b9f-a22f-38e91d2a0ce4_

---
### Insight (conf=0.50)
> The user runs three very different domain projects (dream dashboard, auto-parts SvelteKit app, geopolitical simulation) but applies identical infrastructure patterns to all of them (pm2, WAL, checkpoint/catchup, iterative UI refinement). This suggests the user's 'meta-project' is actually the development workflow itself — the ~/.claude infrastructure IS the product, and the domain projects are its test cases.

**Rule:** When improving session infrastructure (WAL, checkpoints, skills), test changes against all three active project types — dashboard (UI-heavy), data pipeline (transform-heavy), and simulation (architecture-heavy) — since the user implicitly expects cross-project consistency.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.65)
> There's a tension between two user preferences: 'don't autonomously implement beyond what was requested' vs. 'keep going / started / working should resume autonomous work.' The resolution is temporal: the user wants tight scope control during specification but autonomous execution during implementation. The mode switch is signaled by message length — short imperative = execute autonomously, longer correction = constrain scope.

**Rule:** Use message length as a mode signal: messages under ~5 words ('keep going', 'more', 'started') mean 'continue executing the established plan autonomously.' Longer messages with specific corrections mean 'stop, re-scope, and only do what I'm saying.'

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, 2dfa1a6e-03f6-473e-8476-8a5da501300e, edaeaf8c-9b6e-4652-b777-ccedba905520_

---
### Insight (conf=0.70)
> The WAL markdown-to-JSONL migration and the low-signal session metadata problem are two faces of the same issue: unstructured formats (markdown, sparse session logs) resist programmatic extraction, while structured formats (JSONL) enable it. The pattern suggests that ANY human-readable-first format in the infrastructure will eventually need a machine-readable migration as the system scales.

**Rule:** When creating new persistence formats for Claude infrastructure, start with JSONL/structured from day one. Avoid markdown for anything that will be programmatically queried — reserve markdown for human-only documents.

_Patterns: c492a9f2-55a9-4c36-9bf3-6c98959e30a7, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26_

---
### Insight (conf=0.50)
> The 100+ turn iDream sessions that rely on catchup/core-dump rather than git for state management suggest that the user's development model is closer to a REPL/notebook workflow than traditional branch-based development. The 'unit of work' isn't a commit — it's a checkpoint. This implies that tooling optimized for commit-centric workflows (PRs, diffs, blame) may be less useful than checkpoint-centric tooling (WAL queries, state diffing between checkpoints).

**Rule:** For this user's long sessions, optimize checkpoint granularity over commit granularity — a checkpoint every 5-10 tool interactions is more useful for recovery than a git commit every logical unit, though both should happen.

_Patterns: e181d5f7-4435-4c76-a1a4-82f3536aac19, 3d9745f8-ff2e-4e94-be3c-89586e47cd3a, 694c5087-f6dc-4dd0-88dc-8645a8dda00f_

---


## Wake Cycle — 2026-04-21 21:07 UTC

### Insight (conf=0.55)
> Iterative UI refinement ('better', 'good but...') generates disproportionately many tool calls per unit of progress, which is the primary driver of context limit hits — not task complexity itself

**Rule:** Always checkpoint before entering iterative UI refinement loops, and batch visual verification (screenshot + user confirmation) into single exchanges to reduce tool call volume

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.50)
> The user's terse continuation style ('keep going', 'move') combined with frequent context loss creates a compounding ambiguity problem — each compaction makes short commands harder to interpret correctly, yet the user's style doesn't change to compensate

**Rule:** Always resolve the last WAL checkpoint before acting on terse continuation commands, and echo back the inferred intent in one sentence before proceeding

_Patterns: edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 00fb690c-b719-4a18-ad08-94adf937ae00_

---
### Insight (conf=0.58)
> State assumptions that are safe within a single context window become dangerous across compaction boundaries — both git owner inference and worktree state carry stale assumptions that compound with each continuation

**Rule:** Always re-verify mutable external state (git remote, branch, worktree status, running processes) after any compaction or /catchup rather than trusting checkpoint descriptions

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.52)
> The WAL markdown-to-JSONL migration and the low-signal session data problem are the same underlying issue: unstructured text degrades under machine re-parsing across boundaries, while structured formats (JSONL, jq-queryable) preserve fidelity — this principle should extend to all cross-session artifacts, not just WAL

**Rule:** Avoid free-text formats for any artifact that will be machine-parsed across session boundaries; prefer structured formats (JSONL, frontmatter YAML) that survive lossy re-reading

_Patterns: c492a9f2-55a9-4c36-9bf3-6c98959e30a7, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, f52074f5-e86f-46bf-9b6e-a07c743963b6_

---
### Insight (conf=0.60)
> The user maintains multiple complex long-running projects simultaneously (game theory sim, SvelteKit data pipeline, iDream dashboard), each requiring deep context — the session continuity infrastructure isn't just convenience but load-bearing for a multi-project workflow that exceeds any single context window

**Rule:** Always include the project name/path in WAL entries and checkpoints so that /catchup can disambiguate when the user switches between concurrent long-running projects

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, b76b7252-944d-49f8-bb01-fa76c140a694, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---


## Wake Cycle — 2026-04-21 21:36 UTC

### Insight (conf=0.55)
> Both git worktree state loss and incorrect repo owner inference stem from the same underlying failure: assuming environment state persists accurately across context boundaries instead of re-verifying

**Rule:** Always re-verify mutable environment state (git status, remote URLs, working directory) after any context restoration via /catchup, never trust values carried forward from a prior context window

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.50)
> Both the WAL markdown-to-JSONL migration and the vision loop pattern reflect the same design principle: machine-parseable intermediate representations outperform human-readable ones when an agent (not a human) is the primary consumer

**Rule:** Always prefer structured machine-parseable formats (JSONL, coordinate grids) over prose when the output will be consumed by an automated agent step rather than displayed to the user

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.58)
> Terse continuation commands ('keep going') and scope correction ('only help understand, don't implement') create a tension: the agent must distinguish between 'continue what you were doing' and 'continue exploring but don't expand scope' — misreading the valence of brevity causes scope violations

**Rule:** When receiving a terse continuation after a scope correction, always continue within the corrected scope boundary, never revert to the pre-correction scope even if the original task is unfinished

_Patterns: edaeaf8c-9b6e-4652-b777-ccedba905520, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.52)
> Iterative UI aesthetic refinement is the highest context-burn activity — each visual tweak adds tool calls (edit + screenshot + verify) but barely advances the checkpoint state, causing the worst ratio of context consumed to recoverable progress

**Rule:** Always write a WAL checkpoint after every 3 accepted visual changes during UI refinement, because aesthetic iteration consumes context 3-5x faster than architectural work per meaningful state change

_Patterns: 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, f52074f5-e86f-46bf-9b6e-a07c743963b6, 3d9745f8-ff2e-4e94-be3c-89586e47cd3a_

---


## Wake Cycle — 2026-04-23 01:10 UTC

### Insight (conf=0.72)
> The terse command pattern and iterative UI refinement pattern are the same cognitive mode — the user operates in a tight feedback loop where the agent is treated as an extension of their own intent, not a separate entity requiring full specifications. This is a 'pair programming with gestures' interaction style where context is shared implicitly.

**Rule:** When the user is in terse-iterative mode (short commands + UI refinement), maintain a mental model of their 'current focus object' (the widget, component, or file they're iterating on) and apply all ambiguous commands to that object without asking for clarification.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.62)
> The vision loop for desktop automation and the iterative UI refinement loop are structurally identical: act → observe → adjust → verify. The desktop automation pattern formalized what the user naturally does during UI work. The 'front-load screenshot verification' feedback was the user asking for the same rigor they expect from desktop automation to be applied to web development.

**Rule:** After any visual change (CSS, layout, component), run the same verify loop used in desktop automation: capture state → compare to expectation → report delta. Never report a UI change as done without a screenshot step.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.78)
> All three are instances of 'agent exceeded its confidence boundary' — worktree switching without checking state, inferring repo ownership, and implementing beyond scope. The common root cause is the agent treating inferred context as verified context. These are not three separate bugs but one pattern: acting on assumptions rather than observations.

**Rule:** Before any side-effecting operation, distinguish between 'I know X' (read it this session) and 'I believe X' (inferred or remembered). If the critical parameter is in the 'believe' category, verify it first. This single check would have prevented all three failure modes.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.55)
> The user runs three very different domain projects (geopolitical simulation, dream dashboard, eBay parts pipeline) but applies the same infrastructure patterns to all of them. The Claude config itself has become a fourth 'project' — a meta-platform that the user iterates on with the same rigor as application code. The session continuity tools exist because the user's real product is the development environment, not any single app.

**Rule:** Treat ~/.claude/ infrastructure changes with the same commit discipline and testing rigor as application code — it IS the user's most long-lived and cross-cutting project.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.58)
> The preference for generic reusable test patterns and the WAL migration from markdown to JSONL share a deeper principle: the user values machine-parseable, composable formats over human-readable but fragile ones. They'll accept slightly worse readability for reliable automation. This preference likely extends to any format choice in their projects.

**Rule:** When choosing between a human-friendly format and a machine-parseable one, default to machine-parseable (JSONL, structured objects, typed schemas) — the user consistently prefers automation-friendly formats and will build human-readable views on top.

_Patterns: c1405960-924b-4896-b075-e8de0d9868d1, 0629319a-4440-4d1b-bad4-5ad0db93399a, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---


## Wake Cycle — 2026-04-23 02:00 UTC

### Insight (conf=0.62)
> Three distinct domains (git worktrees, repo ownership, desktop automation) share the same failure mode: acting on assumed state instead of verified state — the agent infers current state from prior context rather than re-checking, and this degrades as session length increases

**Rule:** Always re-verify state immediately before any irreversible action when more than 10 tool calls have elapsed since the state was last checked

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.58)
> The user's terse continuation style and scope-limiting correction are in tension — short commands like 'keep going' signal maximum autonomy on execution, but past corrections show the agent over-extended scope under that same autonomy signal, meaning terseness should increase execution speed but not broaden scope

**Rule:** Always interpret terse continuation commands as 'continue the exact current task faster' never as 'expand to adjacent improvements'

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.55)
> Iterative UI refinement workflows (many small incremental requests) are the primary driver of context exhaustion, not task complexity itself — the same pattern that makes the user productive (terse incremental commands) is what forces frequent compaction cycles

**Rule:** Always batch related UI micro-changes into a single checkpoint when 3+ consecutive terse refinement commands occur, rather than checkpointing each individually

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.52)
> WAL and checkpoint infrastructure has become load-bearing production infrastructure rather than optional convenience — yet it has no test coverage or validation, creating a single point of failure for the user's entire multi-session workflow

**Rule:** Always validate WAL JSONL integrity (valid JSON per line, required fields present) after writing a checkpoint, using a quick jq parse check

_Patterns: e218ac38-3844-4295-a972-c9dc01b22d13, 3d9745f8-ff2e-4e94-be3c-89586e47cd3a, 1523746a-7091-4022-b130-7e28b7f77561_

---


## Wake Cycle — 2026-04-23 10:37 UTC

### Insight (conf=0.58)
> Iterative UI refinement (many small 'better/revert/adjust' cycles) is the primary driver of context exhaustion — the workflow that demands the most continuity also burns through context fastest

**Rule:** Always checkpoint after every 5 iterative UI refinement exchanges, not just at tool count thresholds

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.55)
> Terse continuation commands ('next', 'keep going') become dangerously ambiguous after context compaction, because the referent they implicitly point to has been lost — the interaction style that accelerates work also accelerates state loss

**Rule:** Always write a WAL checkpoint before interpreting a terse continuation command that arrives after a compaction boundary

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 5c3499d0-aef9-4924-b559-e15bf88068ed, edaeaf8c-9b6e-4652-b777-ccedba905520_

---
### Insight (conf=0.52)
> Scope control ('only help understand, don't implement') directly contradicts the terse-command protocol ('treat one-word messages as autonomous-continue signals') — the agent cannot simultaneously maximize autonomy on terse input and minimize scope creep

**Rule:** When a terse continuation command follows an exploratory/understanding task, default to explaining next steps rather than implementing them, unless the prior context explicitly established an implementation mandate

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, 556fbc99-c295-493f-8b7a-218b2f5e964f, 2dfa1a6e-03f6-473e-8476-8a5da501300e_

---
### Insight (conf=0.50)
> State verification failures (git worktree losing unstaged changes, wrong repo owner inference) and session state failures (lost context across compaction) share the same root cause — acting on assumed state rather than verified state — but the safeguards developed for session continuity (WAL/checkpoint) have not been applied to git operations

**Rule:** Always run the verification triad (status + log + diff) before any git operation that changes branch state, treating git working-tree state with the same distrust applied to session state after compaction

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 1523746a-7091-4022-b130-7e28b7f77561_

---


## Wake Cycle — 2026-04-23 10:42 UTC

### Insight (conf=0.55)
> State loss at transition boundaries is the recurring structural failure — git worktree switching drops unstaged changes, session switching drops context, and branch operations misidentify owners, all because the pre-transition verification step is skipped under momentum

**Rule:** Always snapshot current state (git stash, WAL checkpoint, or owner verification) before any boundary-crossing operation (worktree switch, session end, remote push)

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, 881b161f-3ee0-4597-ab7b-d6c2a860613d, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.52)
> Terse continuation signals and iterative UI refinement both demand high autonomous execution, but the scope-overreach correction reveals the user draws a sharp line between 'continue what I started' autonomy and 'decide what to do next' autonomy — the agent conflates these two modes

**Rule:** Always continue the current task autonomously on terse input, but never expand scope or start adjacent work without explicit approval, even when the continuation seems natural

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, ff7b37a5-17ae-466e-b55e-585866af824b, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.50)
> Fire-and-forget task notifications, terse continuation commands, and short inferential messages are all instances of the same communication pattern — minimal-signal inputs that require the agent to derive intent from accumulated state rather than from the message itself

**Rule:** Always maintain a 'current task + next step' register so that any zero-context input (terse command, notification, or ambiguous signal) can be resolved against the active task without re-reading the full conversation

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520_

---


## Wake Cycle — 2026-04-23 23:07 UTC

### Insight (conf=0.55)
> Iterative UI refinement ('better', 'good but...') is the primary driver of context exhaustion — each micro-correction burns tool calls on screenshot-verify cycles, causing the very compaction events that require the heavy continuity infrastructure

**Rule:** Always batch UI verification by collecting 2-3 pending aesthetic changes before running a screenshot-verify cycle, rather than verifying after each single micro-adjustment

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, c892fa80-f5af-4270-9e16-9225249062cc, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.52)
> Volatile-layer state loss is a cross-domain structural failure: unstaged git changes lost during worktree switches and conversation context lost during compaction are the same class of bug — state that exists only in a transient buffer gets destroyed by transitions

**Rule:** Always persist volatile state to a durable layer before any transition operation — git stash before worktree switches, WAL checkpoint before operations likely to trigger compaction

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, 5c3499d0-aef9-4924-b559-e15bf88068ed, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.50)
> State assumptions degrade proportionally to session length — git owner inference errors and stale context reconstruction both stem from the same temporal decay: the longer the session chain, the more likely cached assumptions (repo owner, task scope, file state) have silently diverged from reality

**Rule:** Always re-verify external system state (git remote, branch, repo owner) after every session continuation boundary, not just at initial session start

_Patterns: bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 00fb690c-b719-4a18-ad08-94adf937ae00, f1b15033-a4e3-4a70-84fa-4de726a42926_

---


## Wake Cycle — 2026-04-24 01:12 UTC

### Insight (conf=0.82)
> The user maintains multiple large, long-running projects simultaneously (game theory simulation, iDream dashboard, SvelteKit data pipeline, geopolitical modeling). The session continuity infrastructure isn't just a preference — it's load-bearing scaffolding for a multi-project lifestyle where context-switching between ambitious codebases is the norm, not the exception. The continuity system is effectively a personal 'virtual memory' paging mechanism across project working sets.

**Rule:** When /catchup runs, auto-detect which project is active (via CWD or git remote) and pre-load project-specific WAL + runtime-notes, skipping cross-project noise. Add a 'project' field to WAL session_start events to enable this filtering.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, c70ae766-c39a-442a-a15d-fbe84d854e0c, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.78)
> The user's terse command style ('keep going', 'next', 'better') combined with iterative UI refinement suggests a director/operator mental model — they think of Claude as a continuous executor they steer with minimal input, like a video game character. The session continuity obsession reinforces this: they don't want to 're-brief the operator' every time context resets. The ideal UX is a persistent agent that remembers everything and responds to one-word steering.

**Rule:** After compaction, emit a one-line 'I still know: [project], [current task], [last 3 files touched]' confirmation so the user can verify continuity without issuing /catchup. Reduces the terse-command-after-compaction ambiguity.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.91)
> The WAL markdown-to-JSONL migration appearing in 4 independent pattern extractions suggests this transition was itself a multi-session effort that required the very continuity tools it was upgrading — a bootstrapping problem. The migration is complete but the redundant pattern entries indicate the extraction pipeline doesn't deduplicate well across sessions.

**Rule:** Pattern extraction should deduplicate by semantic similarity before surfacing — when 4+ patterns share >80% content overlap, collapse them into one with a 'seen_count' field and earliest/latest timestamps.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 846615fc-eeb8-4a44-bf0a-bf06c723fde8_

---
### Insight (conf=0.75)
> All three negative-valence operational patterns share a root cause: acting on stale assumptions about mutable state (unstaged git changes, repo ownership, screen coordinates). The session continuity system solves this for conversation context but the same 'verify before acting on cached state' principle isn't consistently applied to external system state. The vision loop pattern (screenshot → annotate → verify → act) is the correct archetype that git and worktree operations should mirror.

**Rule:** Generalize the vision loop pattern into a 'mutable-state interaction protocol': observe → confirm observation matches expectation → act → verify result. Apply to git operations (status → confirm branch/changes → push → verify), desktop automation (screenshot → annotate → click → screenshot), and file transforms (read → confirm structure → write → read-back).

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.72)
> Both patterns describe information-sparse signals that arrive in the system — fire-and-forget task notifications with 0 content, and session metadata with minimal extractable signal. These are 'dark matter' in the pattern extraction pipeline: they consume extraction effort but yield low-confidence results. The system currently treats all sessions equally when extracting patterns, but sessions with <5 tools or <100 reply chars should be filtered out pre-extraction rather than producing low-confidence noise.

**Rule:** Skip pattern extraction for sessions with fewer than 5 tool calls or fewer than 200 total reply characters. These are notification artifacts, not real work sessions.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.68)
> There's a tension between 'don't exceed requested scope' and the user's iterative UI refinement style where they give incomplete specs and refine through feedback. The scope correction was likely triggered by a non-UI task where the agent over-reached, but in UI contexts the user actually wants proactive visual verification. The rule should be context-dependent: strict scope for logic/architecture, expansive verification for visual/UI work.

**Rule:** When the task involves UI/visual changes, proactively screenshot and verify before reporting done (expanded scope on verification axis). When the task involves logic, architecture, or refactoring, strictly limit to what was requested (tight scope on implementation axis).

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.60)
> Sessions hitting context limits with 20-80+ tools per turn, spanning 100+ turns, suggest the user's task granularity doesn't match the context window size. Rather than more checkpointing (treating the symptom), the root fix would be better task decomposition — breaking mega-sessions into scoped sub-tasks that each fit in one context window. The continuity infrastructure is brilliant engineering around a workflow anti-pattern.

**Rule:** When a session exceeds 40 tool calls without a natural completion point, proactively suggest decomposing the remaining work into a discrete sub-task with its own success criteria, rather than continuing to accumulate state in the current session.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, f1057a8d-e978-416c-b52e-7ea8fd28e770, e181d5f7-4435-4c76-a1a4-82f3536aac19, c892fa80-f5af-4270-9e16-9225249062cc_

---


## Wake Cycle — 2026-04-24 07:52 UTC

### Insight (conf=0.72)
> Terse continuation commands and zero-tool notification messages are both instances of 'low-bandwidth high-intent signals' — the user communicates via minimal tokens expecting maximal autonomous action, treating the agent like a coworker who shares context rather than a service requiring detailed instructions.

**Rule:** Any input under 5 tokens should trigger context-lookup (last WAL checkpoint + recent tool calls) before asking for clarification — the user's default communication mode assumes shared state.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 2e7d5054-603d-4ba1-92cb-41bca5de2463, edaeaf8c-9b6e-4652-b777-ccedba905520_

---
### Insight (conf=0.62)
> Iterative UI refinement and the vision-loop automation pattern are converging toward a tight feedback cycle where the agent should screenshot-verify BEFORE presenting results to the user, reducing the number of correction rounds. The user's iterative style is partially caused by insufficient pre-verification.

**Rule:** For any UI change, run screenshot → self-evaluate → fix before reporting done. Target zero 'revert' requests by catching visual regressions in the agent's own verification loop.

_Patterns: 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.68)
> Context limits are not a technical constraint to work around — they are a workflow metronome. Sessions that hit compaction at predictable intervals (~30-40 tools) could use this as a natural checkpoint trigger rather than fighting it, turning a limitation into a disciplined save-point rhythm.

**Rule:** At tool call #25, write a preemptive WAL checkpoint — don't wait for compaction to force it. Treat the context window as a fixed-size buffer with planned flushes, not an elastic resource.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 3d9745f8-ff2e-4e94-be3c-89586e47cd3a, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.78)
> Apparent contradiction: user wants tight scope control (don't implement beyond what's asked) but also sends terse continuation signals expecting autonomous execution. The resolution is that autonomy should scale on the execution axis (depth of work) but never on the scope axis (breadth of work) — these are orthogonal dimensions the agent often conflates.

**Rule:** On terse continuation signals, increase execution depth (more tool calls, deeper investigation) but never increase scope breadth (no new features, no adjacent file changes). High autonomy ≠ wide scope.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, 556fbc99-c295-493f-8b7a-218b2f5e964f_

---
### Insight (conf=0.55)
> Git worktree data loss, wrong-org pushes, and reliance on non-git state management (WAL/checkpoint over git) are all symptoms of the same root cause: the agent treats git as a publishing tool rather than a state-management tool. The user's WAL system exists because git alone doesn't capture in-progress cognitive state.

**Rule:** Before any git operation that changes HEAD or working tree, run the verification triad AND write a WAL checkpoint — git ops are the highest-risk moment for state loss because they sit at the boundary between the user's two state systems (git for code, WAL for intent).

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 694c5087-f6dc-4dd0-88dc-8645a8dda00f_

---
### Insight (conf=0.70)
> The user maintains 3-4 complex parallel projects (geopolitical simulation, SvelteKit data pipeline, iDream dashboard, Claude tooling) — session continuity tooling isn't just convenience, it's multiplexing infrastructure that lets one person context-switch across projects that would normally require separate teams.

**Rule:** When resuming via /catchup, identify WHICH project is active before loading context — stale cross-project context is worse than no context. WAL checkpoints should include a project identifier field.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, b76b7252-944d-49f8-bb01-fa76c140a694, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.92)
> Four separate patterns all record the same WAL migration event — this redundancy itself is a pattern. The extraction pipeline over-indexes on structural changes (format migrations) because they appear in many sessions. These should be deduplicated into a single canonical pattern with higher confidence rather than four medium-confidence copies.

**Rule:** When multiple extracted patterns describe the same event or decision, merge them into one pattern with the union of their evidence and the max of their confidence scores. Redundancy ≠ importance.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 846615fc-eeb8-4a44-bf0a-bf06c723fde8_

---
### Insight (conf=0.58)
> The user's dev-server workflow (localhost:5173 SvelteKit, pm2 for iDream) combined with iterative UI refinement suggests they'd benefit from a 'dev-server health check' integrated into /catchup — verifying the server is running and on the right port before resuming UI work would eliminate a class of 'why isn't my change showing' false starts.

**Rule:** When /catchup detects the last session involved a dev server (pm2 process or localhost reference in WAL), automatically verify the server is still running and report its status in the catchup summary.

_Patterns: fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---


## Wake Cycle — 2026-04-25 00:16 UTC

### Insight (conf=0.55)
> The user's terse command style and iterative UI refinement pattern form a tight feedback loop that resembles a human REPL — short imperative inputs, observe output, adjust. This is the same interaction pattern as the vision loop for desktop automation (screenshot → act → verify). The user IS the vision loop for UI work.

**Rule:** For iterative UI refinement sessions, auto-screenshot after every visual change and present it inline — don't wait for the user to ask. This closes the feedback loop faster and matches the user's REPL-style interaction pattern.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.65)
> Context boundary crossings cause state-loss bugs in both the agent (context limits → lost session state) and in git operations (worktree switch → lost unstaged changes). The root cause is identical: crossing an isolation boundary without serializing dirty state first. The core-dump pattern that solves one should be generalized to solve the other.

**Rule:** Before any isolation-boundary crossing (context compaction, worktree switch, branch change, session end), run a 'dirty state audit': git stash if unstaged changes exist, WAL checkpoint if session state exists. Treat boundary crossings as a unified hazard class.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.72)
> Tension between 'don't exceed requested scope' and 'treat terse input as autonomous-continue' creates an ambiguity zone: a short command like 'more' could mean 'continue what you're doing' (autonomous) or 'show me more of what exists' (read-only). The user has been burned by both failure modes. The resolution is directional: terse input expands execution depth but never scope width.

**Rule:** Terse continuation commands ('next', 'more', 'keep going') authorize deeper execution of the current task but never lateral scope expansion. If continuing requires touching a new subsystem or file group not yet in play, pause and name it before proceeding.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, 556fbc99-c295-493f-8b7a-218b2f5e964f_

---
### Insight (conf=0.60)
> The user maintains at least three large concurrent projects (iDream dashboard, SvelteKit data pipeline, geopolitical simulation) each with different tech stacks. The heavy investment in session continuity infrastructure isn't just about long sessions — it's about context-switching between projects. The WAL/checkpoint system is doing double duty as both within-project persistence and cross-project memory.

**Rule:** WAL and checkpoint files should include a project identifier (repo name or path) in their metadata so that /catchup can filter by project context, avoiding cross-project state contamination when switching between concurrent workstreams.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.55)
> The preference for generic reusable test patterns and the migration from markdown WAL to JSONL share a deeper principle: the user values machine-queryable, composable formats over human-readable but rigid ones. This suggests a general preference for structured data that can be programmatically filtered, transformed, and validated — not just for WAL but for any persistent artifact.

**Rule:** When creating any persistent artifact (tests, logs, configs, state files), default to structured machine-queryable formats (JSONL, typed schemas, parameterized templates) over prose or bespoke formats. The user's workflow depends on programmatic access to stored state.

_Patterns: c1405960-924b-4896-b075-e8de0d9868d1, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a_

---


## Wake Cycle — 2026-04-25 06:32 UTC

### Insight (conf=0.72)
> Terse continuation commands and iterative UI refinement are the same cognitive pattern: the user treats the agent as a real-time collaborator with shared working memory, not a request-response API. The short messages aren't lazy — they're high-bandwidth communication that relies on implicit shared context. This is why context loss (compaction) is so disruptive: it breaks the 'shared memory' illusion that enables terse interaction.

**Rule:** After any compaction or context loss, proactively echo back the current task state in one sentence before continuing — this restores the shared-context contract that enables the user's terse communication style.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.68)
> The vision loop for desktop automation (screenshot → annotate → act → verify) and the iterative UI refinement loop (change → screenshot → feedback → change) are structurally identical feedback loops. Both fail when verification is skipped. The desktop automation pattern's 'never guess coordinates' rule generalizes to UI work: never claim a visual change is correct without rendering it.

**Rule:** Treat UI refinement requests with the same verify-before-report discipline as desktop automation: screenshot after every visual change, never report 'done' based on code alone.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.75)
> Context boundary crossings are dangerous in both git operations and session continuity — stale assumptions cause data loss in both domains. Worktree switching lost unstaged changes because state was assumed from a prior context; wrong repo owner was inferred from prior session state. The root cause is identical: acting on cached beliefs after a boundary crossing.

**Rule:** At every boundary crossing (session resume, worktree switch, branch change, compaction), treat ALL prior state beliefs as invalidated — re-verify before any side-effecting operation.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.55)
> Slack MCP failures, sparse session data, and fire-and-forget notifications are all symptoms of 'lossy channels' — integrations where signal degrades silently. The pattern suggests that external tool integrations should be treated as unreliable by default, with explicit health checks rather than assumed availability.

**Rule:** Before relying on any MCP tool in a workflow, run a lightweight health-check call first. If it fails, fall back immediately rather than retrying in a loop — Slack MCP showed that repeated retries don't resolve systemic connection issues.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, c492a9f2-55a9-4c36-9bf3-6c98959e30a7, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.65)
> There's a tension between 'terse commands mean continue autonomously' and 'don't autonomously implement beyond what was requested.' The user wants maximum execution velocity within a declared scope, but zero scope creep. This is a governor pattern: high RPM with a strict rev limiter. The /core-dump at milestones acts as the scope-check gate — it forces a pause where scope can be verified.

**Rule:** Use /core-dump milestone pauses as implicit scope-review gates: before dumping state, verify that work so far stays within the originally declared scope. Flag any drift in the checkpoint summary.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, 556fbc99-c295-493f-8b7a-218b2f5e964f, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.60)
> The user runs three distinct long-lived projects (iDream dashboard, SvelteKit data pipeline, geopolitical simulation) that all share architectural traits: persistent backends, complex state, iterative UI. The session continuity infrastructure isn't project-specific — it's a meta-project that enables all three. Improvements to WAL/checkpoint should be tested against all three project contexts, not just the one active during development.

**Rule:** When modifying session continuity infrastructure (WAL, checkpoints, catchup), validate that the change works across project types — dashboard, data pipeline, and simulation all exercise different state patterns.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.62)
> The dev server on localhost:5173 and pm2-managed services represent runtime state that is invisible to WAL/checkpoint — a core dump captures code state but not process state. Session continuity could be improved by including a 'running services' snapshot (pm2 list, active ports) in core dumps, since restarting servers is a recurring friction point after session resumption.

**Rule:** Include `pm2 jlist` and active port scan output in /core-dump checkpoints, so /catchup can flag which services need restarting rather than discovering it mid-task.

_Patterns: fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 5e7ccf60-ef19-4c14-b9c8-76e931755a30_

---


## Wake Cycle — 2026-04-25 12:35 UTC

### Insight (conf=0.62)
> Terse continuation commands and iterative UI refinement are the same cognitive pattern: the user operates in a tight feedback loop where each micro-correction carries implicit context from all prior corrections. This is a 'sculptor' workflow — removing material incrementally rather than specifying the final form. The agent should maintain a rolling 'aesthetic intent vector' during UI sessions rather than treating each request as independent.

**Rule:** During iterative UI refinement sessions, maintain a mental model of the user's cumulative aesthetic direction (color warmth, density preference, spacing style) and bias suggestions toward that trajectory rather than asking for specs.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.72)
> Vision-loop desktop automation, git worktree state loss, and repo owner misidentification share a root cause: acting on stale mental models of external state. All three fail when the agent assumes the world matches its last observation. The vision loop succeeded precisely because it re-observes before each action — the same discipline should be applied to git and repo operations.

**Rule:** Before any side-effecting operation on external state (git, filesystem, desktop UI, API), re-observe the current state within the same tool call sequence — never rely on state observed more than 2 tool calls ago.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.70)
> The user runs 3-4 large concurrent projects (iDream dashboard, SvelteKit data pipeline, geopolitical simulation, Claude infrastructure) that all demand long-running sessions. The session continuity problem is multiplicative — it's not just long sessions, it's context-switching between projects within and across sessions. Project-specific WAL partitioning would reduce noise in /catchup by filtering to the active project.

**Rule:** WAL entries and checkpoints should be tagged with a project identifier (derived from CWD or git remote) so /catchup can filter to the current project rather than replaying all recent sessions.

_Patterns: e181d5f7-4435-4c76-a1a4-82f3536aac19, b76b7252-944d-49f8-bb01-fa76c140a694, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.78)
> There's a tension between 'don't exceed scope' (explicit correction) and 'treat terse input as autonomous continue' (repeated behavior). These aren't contradictory — they define a phase boundary. The user wants maximum autonomy within the declared task and zero autonomy outside it. The failure mode is misidentifying which phase you're in. Terse commands during active implementation = continue. Terse commands during exploration = stay in observation mode.

**Rule:** Track whether the current session is in 'implementation mode' (user approved a plan, work is underway) or 'exploration mode' (user is asking questions, reviewing). Terse continuations in implementation mode = execute. Terse responses in exploration mode = provide more information, don't start building.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, edaeaf8c-9b6e-4652-b777-ccedba905520, 556fbc99-c295-493f-8b7a-218b2f5e964f_

---
### Insight (conf=0.65)
> Context limits are hit so frequently that the checkpoint system has evolved from 'save at end' to 'save at milestones' to 'save continuously'. This is the same progression databases went through: batch → WAL → continuous journaling. The next logical step is predictive checkpointing — estimating remaining context budget and auto-checkpointing when a threshold is crossed, rather than relying on tool-count heuristics.

**Rule:** Track cumulative token usage (input + output) during a session and trigger automatic checkpoint when estimated usage exceeds 60% of context window, rather than waiting for tool-count thresholds or compaction signals.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, e218ac38-3844-4295-a972-c9dc01b22d13, 07e91a34-f2bd-4d49-8ac8-b81f1d0cd808_

---


## Wake Cycle — 2026-04-25 18:38 UTC

### Insight (conf=0.72)
> The terse command style and iterative UI refinement are the same cognitive pattern: the user thinks in rapid delta-corrections, not upfront specifications. They treat Claude like a REPL — issue a small input, observe the output, adjust. This means the optimal interaction unit is not a task but a tight feedback loop, and latency (context reconstruction time) is the primary bottleneck to their productivity.

**Rule:** Minimize round-trip latency above all else. When the user is in iterative-refinement mode (short messages, UI tweaks, 'keep going'), prefer instant partial results over comprehensive but slow responses. Cache intermediate state aggressively so delta-corrections don't require full re-computation.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.68)
> The WAL markdown-to-JSONL migration is an instance of a deeper pattern: the user systematically evolves human-readable formats into machine-queryable ones as usage scales. This suggests future migrations will follow the same trajectory — any new markdown-based state file that gets queried programmatically will eventually need a structured format.

**Rule:** When creating new state/log files, start with JSONL or structured format from day one if the file will be read by scripts or agents. Reserve markdown only for files primarily consumed by humans (docs, READMEs). Don't repeat the markdown→JSONL migration cycle.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 846615fc-eeb8-4a44-bf0a-bf06c723fde8_

---
### Insight (conf=0.55)
> Context limits are not a bug but a feature of the user's workflow — they consistently push sessions to the boundary, meaning they've optimized for maximum work per session rather than staying within comfortable limits. The zero-tool notification messages suggest async/background work patterns are already in use. Combined, this points toward a workflow that would benefit from a multi-agent architecture where long tasks are decomposed across agents rather than extended within one context window.

**Rule:** For tasks estimated to exceed 60 tool calls, proactively propose splitting into parallel sub-agents at natural seams rather than running sequentially in one context. Each sub-agent gets its own context budget and writes results to a shared JSONL file, avoiding the compaction/catchup overhead entirely.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, e218ac38-3844-4295-a972-c9dc01b22d13, f1057a8d-e978-416c-b52e-7ea8fd28e770, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.75)
> The vision-loop pattern for desktop automation and the iterative UI refinement pattern are structurally identical: observe → act → verify → adjust. The user's UI work IS a manual vision loop. This means screenshot-based verification during UI development isn't just a nice-to-have — it's matching the user's own cognitive loop and should be the default for any frontend change.

**Rule:** For any UI change, automatically enter a vision loop: make the change → take screenshot → present to user. Don't describe the change textually; show it. This matches both the desktop-automation best practice and the user's iterative refinement workflow.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.70)
> All three are instances of 'agent overconfidence about environmental state' — assuming worktree is clean, assuming repo ownership, assuming scope permission. The common root cause is acting on cached beliefs rather than fresh reads. This is the same failure mode as post-compaction state drift, just applied to git/repo state instead of conversation state.

**Rule:** Before any operation that mutates shared state (git, filesystem, external APIs), perform a fresh read of the specific state being mutated. Never inherit state assumptions from earlier in the session, from pattern names, or from user implications. This applies uniformly to git status, repo ownership, file contents, and task scope.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.60)
> Persistent tool failures (Slack MCP) and low-signal session data share a pattern: both represent 'dead zones' where repeated effort yields no progress. The system lacks a circuit-breaker — it keeps retrying Slack MCP and keeps extracting from sparse sessions without flagging diminishing returns.

**Rule:** Implement a three-strike rule for tool integrations: if an MCP server or external tool fails across 3 separate sessions, flag it as 'degraded' in a reference memory and stop attempting automatic reconnection. Similarly, mark data sources as low-signal after extraction yields below a confidence threshold, and deprioritize them in future scans.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.62)
> The user maintains multiple large, long-running projects simultaneously (SvelteKit data pipeline, iDream dashboard, geopolitical simulation). Each has its own tech stack and dev server. The session continuity infrastructure (WAL, checkpoints, catchup) is doing double duty: both within-project continuity AND cross-project context switching. The current system doesn't distinguish these two — a project-aware checkpoint that tags which project is active would reduce catchup noise.

**Rule:** Tag WAL entries and checkpoints with a project identifier (derived from CWD or git remote). When running /catchup, filter to the current project's entries first, falling back to cross-project entries only if the current project has no recent state. This prevents iDream context from polluting simulation session restores and vice versa.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.58)
> The preference for generic reusable tests, the WAL migration to a queryable format, and the terse command style all express the same meta-preference: the user optimizes for leverage — patterns that pay off repeatedly rather than one-off solutions. They invest in infrastructure (test harnesses, structured logs, shorthand commands) that compounds over time. This means proposals for new features should be framed in terms of reuse count, not immediate utility.

**Rule:** When proposing a new tool, script, or pattern, lead with estimated reuse frequency ('this will save ~30s per session, ~3 sessions/week'). The user values compound leverage over one-time wins. Conversely, resist gold-plating anything that will only be used once.

_Patterns: c1405960-924b-4896-b075-e8de0d9868d1, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 556fbc99-c295-493f-8b7a-218b2f5e964f_

---


## Wake Cycle — 2026-04-26 00:53 UTC

### Insight (conf=0.55)
> The vision-loop pattern for desktop automation (screenshot → annotate → act → verify) is the same feedback loop the user applies to UI development (screenshot → feedback → change → verify). Both fail when verification is skipped. The user's iterative aesthetic refinement IS a human-driven vision loop — suggesting that automated screenshot-diff regression testing could replace several rounds of manual 'better/good but...' iteration.

**Rule:** For iterative UI refinement sessions, capture a baseline screenshot before changes and offer automated visual diff after each iteration to reduce the number of feedback rounds needed.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.72)
> Context boundary crossings (session continuity, worktree switches, repo owner inference) all fail the same way: stale assumptions from a previous context are carried into a new one without re-verification. Worktree switching lost unstaged changes because it assumed clean state; repo pushes went to wrong owners because of stale context; session continuations lose task state because of compaction. The common root cause is 'context transition without state snapshot.'

**Rule:** At every context boundary (session resume, worktree switch, branch change, compaction), execute a mandatory state snapshot before proceeding: git status + diff for code contexts, WAL checkpoint for session contexts. Never carry assumptions across boundaries.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.58)
> Three patterns share a 'diminishing returns on retry' structure: Slack MCP reconnection attempts fail repeatedly, sparse session data yields low-confidence learnings, and scope creep happens when the agent tries to do more than asked. All three are cases where persistence without new information degrades outcomes. The connecting principle is: repeated attempts at the same action without new signal should trigger escalation or abandonment, not more retries.

**Rule:** After 2 failed attempts at the same operation (MCP connection, data extraction, scope expansion), stop and either escalate to the user or explicitly flag the attempt as abandoned with rationale — do not silently retry a third time.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, c492a9f2-55a9-4c36-9bf3-6c98959e30a7, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.62)
> The user maintains three concurrent long-running projects (iDream dashboard, SvelteKit data pipeline, geopolitical simulation) that each require deep context reconstruction on resume. This is not just a session continuity problem — it's a project-switching problem. The /catchup mechanism is optimized for resuming one project, but the user's actual workflow involves interleaving across projects, suggesting a need for project-scoped context indexes rather than a single global WAL.

**Rule:** When the user switches between known projects (iDream, SvelteKit pipeline, geopolitical sim), auto-scope /catchup to that project's WAL and checkpoint files rather than loading global state — project context is more valuable than chronological context.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.50)
> The user runs persistent dev servers (localhost:5173, pm2-managed services) alongside session-ephemeral Claude contexts. The dev servers outlive sessions but sessions assume they know server state. This creates a 'split-brain' problem: the long-lived process (dev server) and the short-lived process (Claude session) can diverge silently. The pm2 pattern from iDream partially solves this by making server state queryable, but the SvelteKit project lacks equivalent observability.

**Rule:** At session start for projects with dev servers, probe server health (pm2 status, curl localhost, port check) before assuming prior server state — dev servers outlive sessions and may have crashed or been reconfigured between sessions.

_Patterns: fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9_

---


## Wake Cycle — 2026-04-26 07:01 UTC

### Insight (conf=0.72)
> The user's geopolitical simulation project mirrors their own workflow: both are multi-agent systems requiring robust state handoff across context boundaries. The simulation's agents need state persistence between turns just as the user's Claude sessions need core-dump/catchup cycles. The domain expertise in designing agent state machines likely informed the sophistication of their session continuity infrastructure.

**Rule:** When working on the geopolitical simulation's agent state management, cross-reference patterns from the session continuity infrastructure (WAL, checkpoints, handoff messages) — the two systems solve isomorphic problems and improvements to one may transfer to the other.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, 881b161f-3ee0-4597-ab7b-d6c2a860613d_

---
### Insight (conf=0.85)
> The user's terse continuation commands and iterative UI refinement form a tight feedback loop analogous to a REPL — short input, observe output, adjust. This is a 'steering' interaction model rather than a 'specification' model. The user treats Claude as a real-time collaborator they steer with minimal keystrokes, not a contractor they hand detailed specs to.

**Rule:** Optimize for steering-loop latency: when the user is in iterative UI refinement mode (short messages + screenshot requests), minimize explanatory text and maximize speed of the screenshot-verify cycle. Treat each terse message as a delta correction, not a new request.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.78)
> The migration from markdown WAL to JSONL and the preference for generic reusable test patterns share a common principle: machine-parseability over human-readability. The user consistently favors structured, queryable formats that tools can consume programmatically over prose that requires interpretation. This suggests a 'data-first' philosophy where all artifacts should be machine-accessible.

**Rule:** When creating any new persistent artifact (logs, test fixtures, configuration, reports), default to structured machine-parseable formats (JSONL, JSON, YAML) over prose markdown. Reserve markdown only for documents meant primarily for human reading.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c1405960-924b-4896-b075-e8de0d9868d1_

---
### Insight (conf=0.70)
> Context loss and state loss are the same failure mode at different layers. Git worktree losing unstaged changes, sessions hitting context limits, and wrong repo owner inference all stem from stale assumptions about mutable state. The user's entire infrastructure (WAL, checkpoints, core-dumps) is essentially a distributed systems solution to the 'stale read' problem applied to human-AI collaboration.

**Rule:** Before any state-mutating operation (git, file write, deploy), treat all prior observations as potentially stale — re-read, don't recall. This applies uniformly to git state, file contents, process status, and session context.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.80)
> The vision loop for desktop automation (screenshot → annotate → act → verify) and the iterative UI refinement workflow (change → screenshot → feedback → change) are the same control loop with different actors driving it. In desktop automation, the agent drives the loop; in UI refinement, the user drives it. Both require the same infrastructure: fast visual verification and tight feedback cycles.

**Rule:** Unify the screenshot-verify pattern: whether the agent is autonomously driving desktop automation or the user is iteratively refining UI, always capture a screenshot after each mutation and present it before proceeding. Never report a visual change as 'done' without visual proof.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.55)
> Three patterns of 'low-signal communication channels': Slack MCP fails silently, sparse session data yields low-confidence learnings, and fire-and-forget notifications carry no payload. All represent cases where a system boundary produces unreliable or empty signals. The user's workflow has evolved compensating mechanisms (WAL, checkpoints) specifically because these thin channels can't be trusted.

**Rule:** When a communication channel (MCP server, notification, async signal) returns empty or minimal data, explicitly flag the confidence gap rather than inferring from absence. 'No data from X' is a finding, not a non-event.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, c492a9f2-55a9-4c36-9bf3-6c98959e30a7, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.88)
> The user's scope correction ('only help understand, don't implement') and their terse continuation style ('keep going', 'next') create a tension: short commands usually mean 'continue autonomously', but the user also enforces strict scope limits. The resolution is that autonomy is granted on the execution axis (do more steps) but never on the scope axis (do more things). This is a nuanced trust model — high trust in competence, tight control on intent.

**Rule:** When receiving terse continuation signals, increase execution depth (more tool calls, deeper investigation) but never expand scope. 'Keep going' means 'keep going on THIS task with more effort', not 'keep going and also clean up related things'.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, 556fbc99-c295-493f-8b7a-218b2f5e964f, 2dfa1a6e-03f6-473e-8476-8a5da501300e_

---
### Insight (conf=0.75)
> The user maintains three distinct large projects (iDream dashboard, SvelteKit/eBay parts pipeline, geopolitical simulation) that all share architectural patterns: data pipelines, visualization layers, and persistent state. The heavy investment in session continuity infrastructure exists because context-switching between these projects is frequent and expensive — each project has enough complexity to fill a context window alone.

**Rule:** At session start, identify which project is active before loading context. Project-specific WAL and checkpoint files should be scoped to avoid cross-contamination. When /catchup loads, verify the checkpoint matches the current working directory's project.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.82)
> WAL and checkpoints have evolved from convenience tools into load-bearing infrastructure — they are the user's equivalent of a database transaction log. The pattern suggests that Claude Code sessions should be treated like database connections: they can fail at any point, and recovery must be possible from the last committed checkpoint, not from memory.

**Rule:** Treat checkpoint writes with the same discipline as database commits: checkpoint before risky operations (not just after), verify the checkpoint is readable immediately after writing, and never assume a checkpoint exists without checking.

_Patterns: e218ac38-3844-4295-a972-c9dc01b22d13, 1523746a-7091-4022-b130-7e28b7f77561, 07e91a34-f2bd-4d49-8ac8-b81f1d0cd808_

---
### Insight (conf=0.68)
> All three active projects use localhost dev servers (SvelteKit on 5173, iDream via pm2, simulation likely similar). The user's pm2 + port-range convention exists because multiple projects may be running simultaneously. Stale process detection matters not just for one project but because project-switching can leave orphaned servers consuming ports.

**Rule:** Before starting any dev server, check for processes on the target port AND adjacent ports in the user's range (30xx, 50xx). Multiple active projects means port collisions are likely, not exceptional.

_Patterns: fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9_

---


## Wake Cycle — 2026-04-26 13:08 UTC

### Insight (conf=0.72)
> The terse-command pattern and the iterative-UI-refinement pattern are the same behavior at different granularities: the user treats the agent as a REPL. Short commands are keystrokes in a tight feedback loop. This means latency-to-first-visible-change matters more than completeness-of-response — the user will iterate anyway.

**Rule:** Optimize for fast first-visible-change over comprehensive response. When the user sends a terse continuation, make one change, show the result, and wait — don't batch three improvements into one turn.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.55)
> The WAL migration from markdown to JSONL and the fire-and-forget notification pattern both reflect a deeper shift: the user is building machine-queryable infrastructure, not human-readable logs. The 0-tool/0-reply notification messages are effectively WAL entries at the system level — signals meant for automation, not conversation. The user's tooling ecosystem is converging on structured, machine-first formats.

**Rule:** When creating any new persistence artifact (logs, checkpoints, notes), default to structured formats (JSONL, JSON) over prose markdown. Reserve markdown only for artifacts the user will read directly in a text editor.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.68)
> Context loss and state loss are the same failure mode at different layers: git worktree losing unstaged changes, wrong repo owner inferred from stale context, and sessions hitting context limits all stem from acting on assumed-current state that has silently drifted. The user's entire workflow is vulnerable to 'stale state assumed fresh' bugs.

**Rule:** Before any state-mutating operation (git, file write, API call), re-read the relevant state even if it was read earlier in the same turn. Treat every piece of state as potentially stale — the user's workflow guarantees frequent context boundaries where assumptions break.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.58)
> The vision-loop pattern for desktop automation and the iterative UI refinement pattern are structurally identical: observe → act → verify → adjust. The user's dashboard aesthetic iteration IS a manual vision loop. This suggests automating the screenshot-verify step during UI work would collapse two patterns into one and reduce the user's manual iteration cycles.

**Rule:** After any UI change during dashboard work, automatically take a screenshot and present it before reporting done — don't wait for the user to ask. This pre-empts the iterative 'good but...' cycle by front-loading visual verification.

_Patterns: 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, dd2e18ab-2182-4f88-8eab-354193b9e90a, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.52)
> Three distinct negative patterns share a root cause: acting on insufficient signal. Slack MCP retries without diagnosing the real failure, sparse session data gets over-interpreted, and the agent over-implements beyond the user's request. All three are 'doing more with less data than warranted.' The confidence calibration problem is systemic, not per-tool.

**Rule:** When signal quality is low (tool failures, sparse data, ambiguous scope), reduce action magnitude proportionally. One diagnostic step, not three fix attempts. One clarifying read, not a full implementation. Match effort to evidence.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, c492a9f2-55a9-4c36-9bf3-6c98959e30a7, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.75)
> The user runs at least three substantial long-lived projects (geopolitical simulation, eBay/JEGS SvelteKit app, iDream dashboard) that each require deep context to work on effectively. The session continuity infrastructure isn't just a preference — it's load-bearing for a multi-project workflow where context-switching between projects is the norm, not the exception.

**Rule:** At session start, if /catchup reveals a different project than the last known active one, explicitly confirm which project the user intends to work on before loading deep context — multi-project context contamination is a likely failure mode.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, b76b7252-944d-49f8-bb01-fa76c140a694, c70ae766-c39a-442a-a15d-fbe84d854e0c, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a_

---
### Insight (conf=0.62)
> WAL + checkpoint is functioning as the user's primary version control for *cognitive state*, paralleling how git is version control for *code state*. The user has effectively built a two-track persistence system: git for artifacts, WAL/core-dump for understanding. This means WAL corruption or checkpoint staleness is as damaging as a lost git commit — it deserves the same integrity guarantees.

**Rule:** Treat WAL/checkpoint writes with the same discipline as git commits: verify the write succeeded, never silently skip a checkpoint, and flag if a checkpoint file appears stale (>2 hours old in an active session).

_Patterns: 1523746a-7091-4022-b130-7e28b7f77561, 694c5087-f6dc-4dd0-88dc-8645a8dda00f, e218ac38-3844-4295-a972-c9dc01b22d13_

---


## Wake Cycle — 2026-04-26 19:14 UTC

### Insight (conf=0.62)
> The WAL markdown-to-JSONL migration and the vision-loop validation pattern share a deeper principle: replacing human-readable-but-fragile formats with machine-queryable-but-structured ones. Markdown WAL failed for the same reason coordinate-guessing fails in desktop automation — both rely on approximate interpretation when exact structured data is available. The user's infrastructure is converging on 'structured data over prose' as a reliability principle.

**Rule:** When designing any new persistence or state-transfer mechanism, default to structured machine-queryable formats (JSONL, typed schemas) over human-readable prose. Apply the same principle to inter-session handoffs: core-dump output should be jq-parseable, not markdown-narrative.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.78)
> There's a tension: the user sends terse continuation signals expecting autonomous execution, but also corrects scope creep. This isn't contradictory — it reveals a 'high-autonomy narrow-scope' operating mode. The user wants maximum execution speed within a precisely bounded task, like a racing driver who wants full throttle but only on the track. The terse commands are throttle; the scope corrections are guardrails.

**Rule:** On terse continuation signals, maximize execution velocity but re-read the original task scope before each action. If the next logical step would expand scope beyond the original request, pause — even if the user just said 'keep going'. Autonomy applies to depth, not breadth.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.65)
> Worktree data loss, incorrect repo owner inference, and Slack MCP failures all share a root cause: operations that assume stable external state across session boundaries. Git worktrees assume clean working directories; repo owner inference assumes org context persists; Slack MCP assumes connection state survives restarts. These are all 'stale handle' bugs — holding a reference to state that has moved.

**Rule:** Before any operation that touches external state (git worktree, remote repo, MCP connection), verify the handle is still valid with a read-only probe. Never cache external state references across session or compaction boundaries.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 21f20909-472b-4445-9477-c0605accbe55_

---
### Insight (conf=0.72)
> WAL and checkpoints have become the primary state management layer — ahead of git in importance for this user's workflow. Git tracks code state; WAL/checkpoints track cognitive state (what was being worked on, what decisions were made, what's next). This is effectively a two-tier persistence model: git for artifacts, WAL for intent. Most tooling assumes git is the single source of truth, but this user needs both.

**Rule:** Treat WAL/checkpoint writes with the same discipline as git commits: never skip them before context switches, never assume they can be reconstructed from git history alone. A git log shows what changed; only WAL shows why and what was planned next.

_Patterns: 1523746a-7091-4022-b130-7e28b7f77561, 694c5087-f6dc-4dd0-88dc-8645a8dda00f, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.50)
> The user works across very different tech stacks (game theory simulations, SvelteKit web apps, dream dashboards) but applies the same meta-patterns everywhere: generic reusable tests, localhost dev servers, session continuity. This suggests the user values portable workflow patterns over stack-specific expertise. The 'generic test' preference isn't about testing philosophy — it's about minimizing cognitive switching cost across diverse projects.

**Rule:** When the user starts work in an unfamiliar stack, look for their established cross-project patterns (test naming conventions, dev server expectations, checkpoint cadence) and apply those first, before suggesting stack-idiomatic alternatives.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c1405960-924b-4896-b075-e8de0d9868d1_

---
### Insight (conf=0.55)
> Sessions with 100+ turns, multiple compactions, and terse single-word commands reveal that the user treats the AI session like a persistent REPL — not a chat. The mental model is closer to a tmux session or a Jupyter notebook than a conversation. This explains why fire-and-forget notifications feel natural and why 'keep going' is sufficient context: in a REPL, the state IS the context.

**Rule:** Optimize session UX for REPL-like interaction: minimize preamble on continuation, maximize state visibility (what file am I in, what was the last action, what's queued), and treat compaction boundaries like terminal scrollback limits — the work continues, only the visible history changes.

_Patterns: f1057a8d-e978-416c-b52e-7ea8fd28e770, 07e91a34-f2bd-4d49-8ac8-b81f1d0cd808, e181d5f7-4435-4c76-a1a4-82f3536aac19, 556fbc99-c295-493f-8b7a-218b2f5e964f_

---


## Wake Cycle — 2026-04-27 01:20 UTC

### Insight (conf=0.72)
> The user builds complex stateful simulations (geopolitical, dream-tracking) that mirror the stateful nature of their own development sessions — both the software and the workflow are fundamentally about persisting and resuming rich state across boundaries. The session continuity tooling (WAL, core-dump, catchup) is essentially the same architectural problem as save/load in their simulation projects. This suggests the user has deep intuition for state machines and could benefit from unifying the persistence abstraction.

**Rule:** When working on simulation save/load or state-persistence features in user projects, cross-reference patterns from the session continuity infrastructure (WAL, JSONL checkpoints) — the user already thinks in these terms and the abstractions may be directly portable.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.82)
> Terse continuation commands and iterative UI refinement are the same cognitive pattern: the user thinks in deltas, not specifications. They issue minimal-diff instructions ('keep going', 'better', 'increase font size') because they hold the full state in their head and expect the agent to do the same. This is why context loss (compaction) is so painful — it breaks the shared-state illusion that makes terse communication efficient.

**Rule:** After any compaction or context loss event, the agent should not just restore task state but also restore the 'conversation register' — the implicit shared understanding of what terse commands mean in context. Core dumps should capture recent interaction style/tempo, not just technical state.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.78)
> The WAL migration from markdown to JSONL recapitulates a classic systems pattern: human-readable formats work until they become load-bearing infrastructure, then you need machine-queryable formats. The same pressure will likely apply to core-dump files and runtime-notes — they're currently markdown (human-readable) but are increasingly used as machine-consumed state-restoration inputs. Expect a future migration pressure on those too.

**Rule:** When adding new state-persistence files (checkpoints, runtime-notes), prefer structured formats (JSONL, frontmatter-delimited sections) from the start rather than freeform markdown, to avoid a second markdown→structured migration.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26_

---
### Insight (conf=0.65)
> The vision loop for desktop automation (screenshot→annotate→act→verify) and the UI refinement loop (screenshot→user-feedback→adjust→verify) are structurally identical feedback loops — one automated, one human-in-the-loop. The desktop automation pattern validates that the user's iterative UI workflow could be partially automated: take a screenshot after each CSS change, diff it against the previous state, and surface the delta proactively rather than waiting for the user to request it.

**Rule:** During iterative UI refinement sessions, proactively take and present screenshots after each change without being asked — this closes the feedback loop faster and matches the validated vision-loop pattern from desktop automation.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.58)
> Slack MCP failures, sparse session data, and fire-and-forget notification signals share a common theme: external integration points are the weakest links in the toolchain. The user's workflow is robust internally (WAL, checkpoints, core-dumps) but fragile at boundaries (Slack, async notifications, low-signal metadata). This suggests investment should go toward making boundary failures visible and recoverable rather than adding more internal checkpointing.

**Rule:** When an external integration (MCP server, notification, API) fails silently or returns sparse data, log the failure to WAL with a 'boundary_failure' kind rather than retrying silently — this makes the fragile edges visible in catchup.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, c492a9f2-55a9-4c36-9bf3-6c98959e30a7, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.85)
> Git worktree data loss, incorrect org inference, and agent scope overreach are all instances of the same meta-pattern: the agent acting on stale or assumed state rather than verified current state. The user has been burned enough times by this that they've developed explicit corrective preferences (verify before push, don't infer org, don't implement beyond request). These are all symptoms of the agent's tendency to extrapolate rather than observe.

**Rule:** Before any destructive or externally-visible action, the agent must perform at least one fresh read of the relevant state (git status, file existence, branch owner) — never act on state remembered from earlier in the session or inferred from context.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.75)
> The user runs multiple large, architecturally distinct projects simultaneously (SvelteKit data pipeline, iDream dashboard, geopolitical simulation). Each has different tech stacks but the same workflow pattern (long sessions, frequent continuations, iterative refinement). This means the session continuity infrastructure is more valuable than any single project's tooling — it's the meta-project that enables all other projects.

**Rule:** Treat session continuity infrastructure (WAL, core-dump, catchup, runtime-notes) as Tier 0 priority — bugs or regressions in these tools have multiplied impact across all projects, unlike project-specific issues.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.60)
> Preference for generic reusable test patterns and preference for machine-queryable formats (JSONL over markdown) reflect the same underlying value: composability over specificity. The user optimizes for artifacts that can be consumed by multiple downstream systems rather than artifacts tuned for one use case. This suggests new tools/scripts should output structured, pipeable formats by default.

**Rule:** When creating new scripts or test utilities, default to structured output (JSON lines, TSV) that can be piped/filtered, rather than human-formatted output that requires re-parsing.

_Patterns: c1405960-924b-4896-b075-e8de0d9868d1, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---
### Insight (conf=0.70)
> The combination of explicit state serialization (core-dump) and terse continuation commands reveals a 'save-scum' development pattern borrowed from gaming: checkpoint aggressively, then move fast and loose knowing you can always restore. The terse commands are only safe BECAUSE the checkpoint infrastructure exists. If checkpointing degrades, the terse workflow becomes risky.

**Rule:** If a checkpoint or core-dump command fails or produces incomplete output, immediately alert the user — degraded checkpointing silently undermines the fast-and-terse workflow that depends on it.

_Patterns: 07e91a34-f2bd-4d49-8ac8-b81f1d0cd808, 48d98c46-03d4-43f1-a85f-b355ec92e845, 556fbc99-c295-493f-8b7a-218b2f5e964f_

---


## Wake Cycle — 2026-04-27 07:24 UTC

### Insight (conf=0.72)
> The terse-command style and iterative UI refinement are the same cognitive pattern: the user thinks in rapid incremental deltas, not upfront specs. This is a 'REPL-driven design' mindset — small mutations with immediate feedback. The session continuity obsession exists precisely because this workflow generates enormous context through many small steps, exhausting windows faster than batch-style work would.

**Rule:** For this user, optimize for minimal-latency feedback loops: prefer instant visual verification (screenshot) over verbal confirmation, and auto-checkpoint every N terse commands (not just every N minutes), since terse-command density correlates with context burn rate.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.65)
> The WAL markdown→JSONL migration appears in 4 independent pattern extractions, suggesting it was a high-friction transition that spanned multiple sessions. The repeated detection implies either the migration was incomplete (some paths still emit markdown) or downstream consumers weren't all updated. This is a classic 'format migration long tail' — the canonical format changed but the ecosystem hasn't fully converged.

**Rule:** After a format migration (like WAL md→JSONL), run a one-time audit grep for the old format across all scripts and skills within 1 week. If old-format writes are still found, fix them — don't rely on fallback paths indefinitely, as they become invisible tech debt.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 846615fc-eeb8-4a44-bf0a-bf06c723fde8_

---
### Insight (conf=0.58)
> Context loss (hitting limits, worktree data loss, wrong repo owner inference) are all manifestations of the same root cause: stale mental state after a boundary crossing. Whether the boundary is a context window, a git worktree, or a session handoff, the failure mode is identical — acting on assumptions from before the boundary. The WAL/checkpoint system addresses this for session boundaries but not for git-operation boundaries.

**Rule:** Treat git worktree switches and branch changes as 'mini context boundaries' — run the same state-verification triad (status/log/diff) that you'd run after a /catchup, because the same stale-assumption class of bugs applies.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.70)
> The vision-loop pattern for desktop automation (screenshot→annotate→act→verify) is structurally identical to the user's UI iteration workflow (render→feedback→tweak→verify). Both are perception-action loops where skipping the verification step causes drift. The desktop automation lesson ('coordinate guessing without annotation leads to failures') maps directly to UI work ('claiming done without screenshot leads to rework').

**Rule:** Unify the verification discipline: any action on a visual target (desktop element OR dashboard UI) must follow the same loop — capture current state, act, capture result, diff. Never report visual work as complete without a post-action screenshot.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.52)
> Three patterns share 'low-signal external interfaces': Slack MCP fails silently across sessions, sparse session metadata yields low-confidence extractions, and fire-and-forget task notifications carry zero payload. These are all cases where the system boundary swallows information. The Slack failure persists because there's no feedback loop — it fails, gets retried next session, fails again. A 'known-broken integrations' registry would prevent wasted retry cycles.

**Rule:** Maintain a 'known-broken' list in memory for integrations that fail repeatedly (e.g., Slack MCP). Before attempting to use a previously-failed integration, check this list and skip or warn rather than burning tool calls on a known-dead path.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, c492a9f2-55a9-4c36-9bf3-6c98959e30a7, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.63)
> There's a tension between 'don't autonomously implement beyond what was requested' and 'WAL/checkpoint are load-bearing infrastructure that must be maintained proactively'. The scope-ceiling rule conflicts with the continuity-infrastructure rule when the user is deep in implementation — maintaining checkpoints IS autonomous work beyond the stated task. This tension should be resolved explicitly: continuity infrastructure is exempt from the scope ceiling because it serves the meta-task of enabling all other tasks.

**Rule:** Session-continuity operations (WAL writes, checkpoints, core-dumps) are exempt from the scope-ceiling rule — they are meta-work that enables the primary task and should be performed proactively even when the user's stated scope is narrow.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, e218ac38-3844-4295-a972-c9dc01b22d13, 1523746a-7091-4022-b130-7e28b7f77561_

---
### Insight (conf=0.55)
> The user runs at least 3 distinct large projects (SvelteKit parts data pipeline, iDream dashboard, geopolitical simulation) that all involve data transformation pipelines, UI visualization, and long-running development. The session continuity problem scales superlinearly with project count — context restoration must disambiguate WHICH project, not just WHERE in a project. The /catchup system may need project-scoping to avoid cross-contamination of state between projects.

**Rule:** When resuming via /catchup, always identify the active project first (from CWD or WAL) before loading state — cross-project state contamination is a realistic failure mode for users with multiple long-running projects.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---


## Wake Cycle — 2026-04-28 03:54 UTC

### Insight (conf=0.65)
> The user's terse command style ('keep going', 'next', 'better') is not just a communication preference — it's a bandwidth optimization for the same reason core-dumps exist. Both patterns solve the same problem (context window scarcity) from opposite ends: core-dumps compress agent state, terse commands compress user intent. The user has co-evolved both strategies together.

**Rule:** When a terse continuation arrives mid-session, treat the most recent WAL checkpoint as implicit context — don't re-scan broadly, just read the last checkpoint and continue from there. This pairs the two bandwidth-saving strategies into a single fast-resume path.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.55)
> The vision-loop pattern for desktop automation (screenshot → annotate → act → verify) is structurally identical to the user's iterative UI refinement workflow (screenshot → feedback → change → verify). Both are perception-action loops where skipping the verify step causes failures. The desktop automation rule 'never guess coordinates' maps to 'never guess aesthetic satisfaction'.

**Rule:** For iterative UI refinement sessions, enforce the same verify-before-report discipline as desktop automation: take a screenshot after every visual change, present it, and wait for user signal before proceeding — never batch multiple aesthetic changes without intermediate verification.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.72)
> Context boundary crossings (session continuations, worktree switches, repo transitions) all share the same failure mode: stale assumptions from the previous context causing destructive actions in the new one. The worktree data loss and wrong-org push are specific instances of a general 'context teleportation' hazard.

**Rule:** After any context boundary crossing (session continuation, worktree switch, branch switch, or repo change), run a mandatory 3-command state audit (git status, git remote -v, git stash list) before any mutating operation. Treat context boundaries like privilege boundaries — re-authenticate state.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.50)
> The user runs three distinct long-lived projects (iDream dashboard, SvelteKit data pipeline, geopolitical simulation) that all share: persistent dev servers, iterative UI work, and heavy session continuity needs. The continuity infrastructure was likely shaped by whichever project came first, and may have implicit assumptions (e.g., single-project sessions) that break when switching between projects within a session.

**Rule:** WAL and checkpoint files should include a project identifier (repo root or project name) in every entry. When /catchup detects a project mismatch between the checkpoint and the current working directory, warn before restoring — cross-project state restoration is the most dangerous form of stale context.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.58)
> There's a tension between 'only help understand, don't implement' and 'treat terse commands as autonomous-continue signals'. Both are valid preferences but they conflict: a terse 'next' after an exploration question could mean 'tell me more' or 'now implement it'. The user has both preferences simultaneously, creating an ambiguity that the terse-command protocol doesn't resolve.

**Rule:** When a terse continuation follows an exploration/understanding phase (no code has been written yet in the current task), default to 'explain more' rather than 'start implementing'. Only cross the explore→implement boundary on an explicit action verb ('do it', 'build it', 'implement') or when the user's initial request was clearly implementation-oriented.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, 556fbc99-c295-493f-8b7a-218b2f5e964f_

---
### Insight (conf=0.85)
> Four separate patterns independently record the WAL markdown→JSONL migration, indicating this was a high-salience event that the extraction pipeline over-counted. This is itself a meta-signal: the pattern-extraction system lacks deduplication, and recurring high-confidence duplicates inflate the pattern space, making creative connections harder to find by drowning signal in repetition.

**Rule:** Before running cross-pattern analysis, deduplicate patterns by content similarity (not just ID). Merge patterns that describe the same event/preference with >80% semantic overlap, keeping the highest-confidence version and noting the count as a 'reinforcement score'.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 846615fc-eeb8-4a44-bf0a-bf06c723fde8_

---


## Wake Cycle — 2026-04-28 09:59 UTC

### Insight (conf=0.70)
> Terse continuation commands and iterative UI refinement are two expressions of the same interaction style: the user operates as a 'steering wheel', providing minimal directional corrections while expecting the agent to maintain momentum. This is the human equivalent of a PID controller — small error signals, not full re-specifications.

**Rule:** After completing a sub-task, present the result and immediately begin the next logical step rather than stopping to ask. The user will steer with terse corrections if off-course. Stopping for confirmation breaks their flow.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.60)
> The WAL markdown→JSONL migration is a microcosm of the user's broader pattern: hitting a scalability wall with human-readable formats, then migrating to machine-queryable ones. The same arc likely applies to other documentation — runtime-notes, proposals.jsonl, etc. The user's infrastructure is evolving from 'documents an agent reads' to 'databases an agent queries'.

**Rule:** When proposing new persistent state formats, default to JSONL or structured data over markdown. The user has demonstrated a clear preference trajectory toward machine-parseable formats for anything that agents consume programmatically.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26_

---
### Insight (conf=0.50)
> The vision-loop pattern for desktop automation (screenshot→annotate→act→verify) and the iterative UI refinement workflow share identical structure: observe→judge→act→verify. The user's UI iteration style IS a manual vision loop. This suggests the desktop automation pipeline could be repurposed as an automated UI-QA step — screenshot the dashboard after each change and diff against the previous state.

**Rule:** After UI changes in the dashboard project, automatically capture a screenshot and present it before reporting done. This closes the vision loop that the user would otherwise close manually with 'looks wrong, try again'.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.55)
> State management failures (worktree losing unstaged changes, wrong repo owner inference) and the heavy reliance on /catchup over git for continuity suggest a tension: git is the canonical state store for code, but the user's workflow treats WAL/core-dump as the canonical state store for intent. When these two diverge (e.g., worktree switch discards intent-state that wasn't yet in git), data loss occurs.

**Rule:** Before any git operation that changes working tree state (worktree switch, checkout, reset), auto-checkpoint the WAL and verify no unstaged changes exist. Treat WAL-state and git-state as two independent stores that must both be consistent before destructive transitions.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 694c5087-f6dc-4dd0-88dc-8645a8dda00f_

---
### Insight (conf=0.65)
> Fire-and-forget task notifications (0 tools, 0 reply), terse user commands, and sparse session metadata are all instances of low-bandwidth signals that carry high semantic load relative to their size. The system should optimize for interpreting minimal signals rather than requesting fuller ones — the user's entire interaction style is built around signal compression.

**Rule:** Never ask for more detail when a signal is interpretable. Build a lookup table of terse-command→action mappings and expand it as new terse patterns emerge, rather than falling back to clarification prompts.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, 556fbc99-c295-493f-8b7a-218b2f5e964f, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.60)
> Repeated Slack MCP failures, the scope-correction incident, and low-signal session data all point to a meta-pattern: the agent's failure modes cluster around overreach (trying too hard on Slack, expanding scope unbidden, over-interpreting sparse data). The user's corrections consistently push toward 'do less, not more'. The system's error budget should be biased toward under-acting rather than over-acting.

**Rule:** When facing repeated failures or ambiguity, reduce scope and report status rather than escalating attempts. Three failed retries of the same approach should trigger a pause-and-report, not a fourth retry.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, ff7b37a5-17ae-466e-b55e-585866af824b, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.70)
> The user runs 4+ distinct long-lived projects (iDream dashboard, SvelteKit data pipeline, geopolitical sim, Claude infra itself), all requiring multi-session continuity. This isn't just a preference — it's a constraint of working at a scale where no single session can hold the full context of any one project. The user is effectively a 'project multiplexer' and the core-dump/catchup system is their context-switch mechanism, analogous to an OS process scheduler saving/restoring register state.

**Rule:** Core-dump files should include a project identifier and a 'last 3 actions + next 3 planned actions' summary optimized for rapid re-orientation, not comprehensive state. The bottleneck is context-switch latency, not information completeness.

_Patterns: e181d5f7-4435-4c76-a1a4-82f3536aac19, b76b7252-944d-49f8-bb01-fa76c140a694, 58112601-ddbc-4e20-a6ea-6987c6c96569, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.50)
> The preference for generic reusable test patterns and the migration to JSONL WAL format share a common principle: the user values infrastructure that works across contexts without modification. Tests that are generic across inputs, WAL formats that are generic across tooling, session-continuation that is generic across projects. This is a 'write once, run anywhere' philosophy applied to developer tooling.

**Rule:** When building any reusable infrastructure (tests, scripts, formats), design for context-independence first. Hard-coded project names, paths, or assumptions about specific codebases should be parameterized.

_Patterns: c1405960-924b-4896-b075-e8de0d9868d1, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 1523746a-7091-4022-b130-7e28b7f77561_

---


## Wake Cycle — 2026-04-28 19:18 UTC

### Insight (conf=0.72)
> The user gravitates toward complex simulation/visualization projects (geopolitical sim, dream dashboard, globe/terrain) that inherently exceed single-session context windows. The domain choice itself drives the heavy session-continuity needs — these aren't just big projects, they're projects whose state is hard to reconstruct from code alone because they involve rich runtime state (widget layouts, simulation parameters, visual aesthetics).

**Rule:** For simulation/dashboard/visualization projects, core-dump should capture not just code state but runtime configuration state (active widget configs, simulation parameters, dev server ports, current visual iteration number) since these are not recoverable from git diff alone.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.68)
> The WAL markdown→JSONL migration mirrors a broader pattern: as session continuity became load-bearing infrastructure rather than a convenience feature, the serialization format had to become machine-queryable. This is an instance of 'informal notes calcify into databases when they become critical path.' The same pressure will likely push runtime-notes and core-dump formats toward structured data.

**Rule:** When any text-based state artifact (runtime-notes, core-dump, checkpoint files) is read by jq/scripts more than by humans, migrate it to JSONL or structured YAML. Track read-by-machine vs read-by-human ratio as a migration signal.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, 846615fc-eeb8-4a44-bf0a-bf06c723fde8, 1523746a-7091-4022-b130-7e28b7f77561_

---
### Insight (conf=0.65)
> The terse-command pattern and the iterative-UI-refinement pattern are the same behavior at different granularities. The user communicates in tight feedback loops — single words for task continuation, short phrases for visual iteration. This suggests the user treats the agent like a responsive instrument (steering wheel) rather than a delegated worker (letter of instruction). Optimizing for low-latency response matters more than optimizing for completeness of a single response.

**Rule:** When the user is in iterative-refinement mode (3+ short sequential messages), prioritize fast partial results over complete answers. Show the screenshot or diff immediately, defer explanations until asked.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.61)
> Sessions hitting 20-100+ tool calls before context limits suggests the bottleneck isn't conversation length but tool-result bloat. Each tool call injects potentially large results into context. The core-dump/catchup cycle is compensating for a context budget that's being consumed by tool outputs rather than by reasoning. Reducing tool-result verbosity would reduce compaction frequency and thus reduce reliance on the continuity machinery.

**Rule:** After 30 tool calls in a session, proactively trim tool-result retention: use head_limit on Grep, limit on Read, and summarize large Bash outputs before they accumulate. Prevention beats recovery.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, e218ac38-3844-4295-a972-c9dc01b22d13, c892fa80-f5af-4270-9e16-9225249062cc, f1057a8d-e978-416c-b52e-7ea8fd28e770_

---
### Insight (conf=0.58)
> The vision loop pattern (screenshot→annotate→act→verify) for desktop automation and the iterative UI refinement pattern are structurally identical: both are perception-action-verification cycles driven by visual state. The user's 'iterate until visually satisfied' preference for dashboards is the same cognitive pattern as the validated desktop automation loop — both require rendering before judging.

**Rule:** For any UI change, treat the screenshot-verify step as non-optional (same as the desktop automation rule). Never report a UI task as done without a screenshot, even for 'small' CSS changes — the user's iteration pattern proves that visual verification catches issues code review doesn't.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.55)
> Three distinct failure patterns (Slack MCP flakiness, sparse session data giving false confidence, worktree data loss) share a root cause: acting on stale or incomplete state as if it were authoritative. The Slack MCP 'works then doesn't' pattern, the low-signal session data being weighted equally, and the worktree switch not checking for unstaged changes are all instances of 'trusted a cache that had silently expired.'

**Rule:** Before any operation that depends on external state (MCP connection, session metadata, worktree cleanliness), perform a freshness check with a timeout. If the check fails or returns stale data, fail loudly rather than proceeding with degraded assumptions.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, c492a9f2-55a9-4c36-9bf3-6c98959e30a7, 5287886b-6995-4b9f-a22f-38e91d2a0ce4_

---
### Insight (conf=0.52)
> Scope-overreach (implementing beyond what was asked), org-inference (guessing repo owners), and fire-and-forget signals (0-tool notification turns) are all instances of the agent filling in blanks with assumptions when the correct action is to do nothing or ask. The anti-pattern is 'ambiguity → action' when it should be 'ambiguity → pause or no-op.'

**Rule:** When information is missing or ambiguous (repo owner, task scope, notification intent), default to the minimum-action interpretation: no-op for notifications, literal scope for tasks, explicit query for identifiers. Never extrapolate from context what should be confirmed from source.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.60)
> The user maintains multiple long-running projects simultaneously (SvelteKit/eBay data pipeline, iDream dashboard, geopolitical simulation). Each has its own dev server, stack, and domain. Session continuity tools are doing double duty: restoring not just task state but project identity. A session that starts with /catchup needs to re-establish which project it's in, not just what was last done.

**Rule:** Core-dump and catchup should always include a 'project identity' header (project name, working directory, stack, active dev server port) as the first field — this orients faster than a task list when the user switches between multiple concurrent projects.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.70)
> Session state management (/catchup + /core-dump) has become a parallel version control system running alongside git. Git tracks code state; the WAL/checkpoint system tracks cognitive state (what was being attempted, what decisions were made, what's next). This is effectively a 'git for intent' — and like early git, it's currently manual. The natural evolution is automated checkpointing triggered by heuristics (tool count, time elapsed, topic change) rather than explicit commands.

**Rule:** Implement auto-checkpoint triggers: after 25 tool calls, after 15 minutes of elapsed work, and on detected topic/file-area switches. Don't wait for the user to say /core-dump — the pattern data shows they always want it, they just sometimes forget until context is already lost.

_Patterns: 694c5087-f6dc-4dd0-88dc-8645a8dda00f, 07e91a34-f2bd-4d49-8ac8-b81f1d0cd808, e181d5f7-4435-4c76-a1a4-82f3536aac19_

---


## Wake Cycle — 2026-04-29 01:17 UTC

### Insight (conf=0.55)
> The user builds simulation/dashboard systems that mirror the session-continuity problem itself — complex stateful systems requiring persistent context across boundaries (geopolitical agents maintaining world-state across turns ≈ Claude sessions maintaining work-state across compactions). The user's tooling needs (WAL, checkpoints, catchup) may be projections of the same architectural pattern they implement in their domain projects.

**Rule:** When working on the user's simulation or dashboard projects, look for opportunities to reuse the same state-persistence patterns (append-only logs, checkpoint/restore, structured handoff) that power the session continuity infrastructure — the problems are isomorphic.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.82)
> There is a tension between the user's terse-continuation style (which signals 'keep going autonomously') and their explicit correction about scope creep. The terse commands create ambiguity: 'keep going' means 'continue the current task at current scope', NOT 'expand scope autonomously'. The user wants high-velocity execution within tight rails — a Formula 1 car, not an explorer.

**Rule:** When receiving terse continuation signals, maximize execution speed and depth on the CURRENT task but never interpret them as permission to widen scope. 'Keep going' = 'faster on this track', not 'find new tracks'.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.72)
> The WAL migration from markdown to JSONL and the fire-and-forget task notification pattern share a design philosophy: prefer machine-parseable, append-only formats over human-readable ones when the primary consumer is automation. The user is systematically replacing 'pretty but fragile' with 'ugly but queryable' across their toolchain — a maturation arc from artisanal to industrial session management.

**Rule:** When proposing new persistence or signaling mechanisms, default to JSONL/structured formats over markdown. The user's trajectory is toward machine-first, human-second data formats for infrastructure (while keeping human-first for UI/dashboards).

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.65)
> The iterative UI refinement pattern ('better', 'good but...', 'revert colors') and the desktop automation vision loop (screenshot → annotate → act → verify) are the same feedback loop at different abstraction levels. Both require visual verification as the ground truth, not code inspection. This suggests the user's mental model treats all output as 'rendered artifact first, source code second'.

**Rule:** For any user-facing output (UI, reports, visualizations), always screenshot/render and verify visually before reporting done. Code correctness is necessary but not sufficient — the user judges by rendered output.

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.70)
> Git worktree data loss, incorrect repo owner inference, and Slack MCP connection failures all share a root cause: acting on stale or assumed state without verification. These are three symptoms of the same anti-pattern — 'trust the cache, skip the check'. The user has been burned enough by this that their entire checkpoint/WAL infrastructure is essentially a hedge against stale-state bugs.

**Rule:** Before any operation that touches external state (git, MCP connections, file system), re-verify the current state even if you 'just checked'. The cost of one redundant `git status` is negligible compared to recovering from a stale-state mistake.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 21f20909-472b-4445-9477-c0605accbe55_

---
### Insight (conf=0.60)
> The 100+ turn sessions with 20-80 tools per turn, combined with the observation that sparse session metadata yields low-confidence learnings, reveals a data paradox: the user's most valuable sessions (long, complex, multi-compaction) are exactly the ones where per-turn metadata is least informative because context is compressed away. The session continuity infrastructure is fighting information entropy.

**Rule:** In long sessions, write richer checkpoint metadata (not just 'what was done' but 'what was learned and what assumptions are load-bearing') because post-compaction, the nuance is the first thing lost. Front-load insight density in checkpoints.

_Patterns: e181d5f7-4435-4c76-a1a4-82f3536aac19, c892fa80-f5af-4270-9e16-9225249062cc, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.68)
> The user maintains at least three large concurrent projects (SvelteKit data pipeline, iDream dashboard, geopolitical simulation) across different tech stacks. The extreme reliance on session continuity tools isn't just about long sessions — it's about context-switching between projects within the same toolchain. Each /catchup isn't just restoring one session; it's re-entering one of several parallel universes.

**Rule:** When /catchup is invoked, identify WHICH project is being resumed before loading state — don't assume it's the most recent one. Project-specific WAL and checkpoint files should be clearly namespaced to avoid cross-project contamination.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.75)
> The user's state management is NOT git-centric — it's WAL/checkpoint-centric. Git captures code snapshots but the user's working state (what they're thinking about, what's half-done, what was tried and abandoned) lives in the WAL/core-dump layer. This is analogous to how databases use WAL + snapshots rather than just snapshots alone — the user has independently converged on database-style durability for their development workflow.

**Rule:** Treat WAL + core-dump as the primary state recovery mechanism, not git log. Git tells you what shipped; WAL tells you what was happening. When resuming work, read WAL first, then git log for context.

_Patterns: 694c5087-f6dc-4dd0-88dc-8645a8dda00f, 07e91a34-f2bd-4d49-8ac8-b81f1d0cd808, e218ac38-3844-4295-a972-c9dc01b22d13_

---


## Wake Cycle — 2026-04-29 03:20 UTC

### Insight (conf=0.82)
> The user gravitates toward complex stateful simulation/dashboard projects (geopolitical sim, dream tracker, game theory) that inherently exceed single-session context windows — the project domain itself drives the session-continuity need. Simpler projects would not produce this pattern density.

**Rule:** When starting a session on a stateful simulation or dashboard project, proactively run /catchup and set a checkpoint timer at tool #20 instead of #30, since these domains consistently exhaust context.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.68)
> Both WAL migration (markdown→JSONL) and desktop automation (screenshot→annotate→act→verify) reflect the same meta-pattern: replacing human-readable-but-fragile formats with machine-queryable-but-opaque ones. The user values reliability over readability when the consumer is an agent, not a human.

**Rule:** When building agent-consumed artifacts (state files, logs, coordination messages), default to structured machine-readable formats (JSONL, JSON) over markdown. Reserve markdown for human-facing outputs only.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.72)
> Terse continuation commands and fire-and-forget task notifications are two sides of the same coin: the user treats the agent as a background coprocessor with minimal-bandwidth signaling. The interaction model resembles Unix process signals (SIGCONT, SIGHUP) more than conversation.

**Rule:** Treat single-word user messages as process signals, not conversational turns. Map: 'next/go/continue' → SIGCONT (resume), 'stop/wait' → SIGSTOP (pause and report), 'status' → SIGUSR1 (emit state). Respond with action, not acknowledgment.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.78)
> Context boundary crossings (session continuity, worktree switches, repo owner inference) all share the same failure mode: stale state assumptions surviving a boundary. The 'state was true before the boundary' → 'state is true after' inference is the common root cause.

**Rule:** After ANY boundary crossing (session resume, compaction, worktree switch, branch change), treat all cached state as invalidated. Run a verification pass: git status, check CWD, confirm active processes. Never carry forward assumptions across boundaries.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.75)
> The user's iterative UI refinement style ('better', 'good but...') combined with the explicit 'don't implement beyond what was asked' correction reveals a tension: the user wants tight feedback loops on aesthetics but strict scope control on functionality. These require opposite autonomy levels in the same session.

**Rule:** In UI sessions, split autonomy by layer: HIGH autonomy on visual/aesthetic changes (try variations, screenshot proactively), LOW autonomy on structural/functional changes (confirm before adding routes, state, APIs). The user's 'scope ceiling' applies to features, not to polish.

_Patterns: 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.65)
> Repeated MCP connection failures, low-signal session data, and WAL format migration fallbacks all point to the same infrastructure fragility: the agent's own tooling has reliability gaps that compound across long multi-session workflows. The user's heavy checkpoint discipline is partly compensating for infrastructure that drops state.

**Rule:** Before relying on any MCP server or infrastructure tool in a session, run a lightweight health check (e.g., a no-op query). If it fails, fall back to direct alternatives immediately rather than retrying — the user's workflow cannot afford debugging tool infrastructure mid-task.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, c492a9f2-55a9-4c36-9bf3-6c98959e30a7, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26_

---
### Insight (conf=0.70)
> The user maintains 3+ concurrent long-running projects (SvelteKit data pipeline, iDream dashboard, geopolitical simulation) that each independently exhaust session context. The session continuity infrastructure isn't just for one big project — it's a multiplexer across a project portfolio.

**Rule:** At session start, before /catchup, identify WHICH project is active (check CWD, recent git log, pm2 list). The catchup context for project A is noise for project B — load only the relevant WAL/checkpoint.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.73)
> WAL + checkpoint files have become the user's primary version control for agent state — not git, not comments, not docs. This is a shadow VCS running parallel to git, optimized for agent cognition rather than code diffs. If this infrastructure fails, the user loses more continuity than a git reset would cause.

**Rule:** Treat WAL/checkpoint corruption or loss as a P0 incident equivalent to losing uncommitted code. Back up .claude/wal.jsonl to a dated copy before any operation that might truncate or overwrite it.

_Patterns: e218ac38-3844-4295-a972-c9dc01b22d13, 694c5087-f6dc-4dd0-88dc-8645a8dda00f, 1523746a-7091-4022-b130-7e28b7f77561_

---


## Wake Cycle — 2026-04-29 05:20 UTC

### Insight (conf=0.72)
> The user's projects (geopolitical simulation, dream dashboard) both model complex state machines with many actors/entities evolving over time — the same reason sessions themselves need robust state management. The domain complexity drives the session complexity; reducing domain state surface (e.g., serializable snapshots of simulation/dashboard state) would also reduce session continuation burden.

**Rule:** For projects with complex domain state (simulations, dashboards with many widgets), auto-generate a machine-readable project-state snapshot alongside the session core-dump, so /catchup can restore both agent context AND domain context in one pass.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.78)
> Terse continuation commands and iterative UI refinement are the same cognitive pattern: the user thinks in small deltas, not complete specifications. This is a streaming-consciousness workflow where the agent is an extension of the user's thought process. The agent should optimize for low-latency small-delta responses rather than comprehensive single-shot answers.

**Rule:** When the user is in iterative-refinement mode (detected by 3+ short sequential messages), minimize preamble and explanation per turn — apply the delta, show the result (screenshot/output), and wait. Save the explanation for when the user asks 'why'.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.65)
> The WAL markdown→JSONL migration and the fire-and-forget task notifications share a deeper pattern: the system is evolving from human-readable formats toward machine-queryable ones. The zero-tool/zero-reply notifications suggest an event-bus architecture is emerging organically. WAL JSONL entries and task signals could be unified into a single event stream that both humans and agents consume.

**Rule:** Treat WAL entries and async task notifications as a unified event stream. When writing WAL checkpoint entries, include a 'pending_tasks' field so /catchup can surface incomplete async work without requiring the user to remember what was in flight.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.74)
> Context loss (hitting context limits) and state loss (worktree losing unstaged changes, wrong repo owner inferred) are the same failure mode at different layers: the agent acts on stale assumptions. Context compaction is a form of 'unstaged work' that gets silently dropped. The worktree and git-owner bugs are symptoms of the same root cause as session continuation failures.

**Rule:** Before any state-mutating operation (git push, file write, worktree switch), run a 'staleness check' that verifies the 3 most recent assumptions the agent is acting on. If any assumption was formed before the last compaction boundary, re-verify it.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.70)
> The vision-loop pattern for desktop automation (screenshot→annotate→act→verify) is isomorphic to the UI refinement loop (screenshot→user-feedback→change→verify). Both require closing the perception-action loop with visual verification. The desktop automation pattern could be applied to accelerate UI iteration: auto-screenshot after every CSS/layout change and present to user without being asked.

**Rule:** After any UI-affecting code change during an iterative refinement session, automatically capture and present a screenshot before reporting done — don't wait for the user to ask 'how does it look'.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.62)
> Three different failure modes share a common theme: systems that fail silently or ambiguously. Slack MCP fails without clear resolution, sparse session data produces low-confidence extractions without flagging it, and the agent over-extends scope without explicit signals. All three would benefit from an explicit 'confidence/health' signal — a circuit breaker that announces 'I'm operating with degraded information' rather than proceeding optimistically.

**Rule:** When operating with degraded inputs (failed MCP connections, sparse session metadata, ambiguous user intent after scope correction), prefix the action with a one-line confidence disclaimer rather than proceeding at full confidence. Example: '[low-signal] Slack MCP unavailable, falling back to...'.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, c492a9f2-55a9-4c36-9bf3-6c98959e30a7, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.58)
> The user's preference for generic reusable test patterns mirrors the session continuity architecture: both are about creating reliable replay/restore mechanisms. Tests replay behavior; core-dumps replay context. The WAL+checkpoint system IS a test harness for session state. This suggests the /catchup path should be tested the same way code is — with known-good checkpoint fixtures that verify restoration fidelity.

**Rule:** Create 2-3 'golden checkpoint' test fixtures (a known core-dump + expected /catchup output) and periodically verify that /catchup correctly reconstructs state from them — apply the same 'generic reusable test' philosophy to the session continuity infrastructure itself.

_Patterns: 1523746a-7091-4022-b130-7e28b7f77561, 694c5087-f6dc-4dd0-88dc-8645a8dda00f, e218ac38-3844-4295-a972-c9dc01b22d13, c1405960-924b-4896-b075-e8de0d9868d1_

---
### Insight (conf=0.67)
> The SvelteKit dev server on localhost:5173 that gets frequently checked/restarted is analogous to the session continuity problem — both are long-running stateful processes that degrade and need restoration. The dev server health-check pattern (is it running? restart if not) could be formalized into the /catchup flow: check if expected dev servers are alive as part of context restoration.

**Rule:** When /catchup detects the prior session had active dev servers (from WAL entries), automatically verify their status (port check) and report 'dev server on :5173 is [alive/dead]' as part of the catchup summary.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, 07e91a34-f2bd-4d49-8ac8-b81f1d0cd808_

---


## Wake Cycle — 2026-04-29 07:22 UTC

### Insight (conf=0.70)
> The user's communication style (terse commands, iterative refinement) combined with heavy session continuity suggests a 'steering wheel' interaction model rather than a 'specification' model. They treat the agent like a vehicle — small directional inputs assume momentum is maintained. This is fundamentally incompatible with context boundaries that reset momentum to zero, explaining why /catchup and /core-dump are so heavily used.

**Rule:** After /catchup, immediately echo back the inferred momentum vector ('I believe we were heading toward X, with Y in progress') before waiting for input. This lets the user steer with a single word rather than re-specify direction.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.75)
> The vision-loop pattern for desktop automation and the iterative UI refinement pattern share a common structure: observe → act → verify. The git worktree data loss happened because the 'observe' step was skipped before acting. All three patterns are instances of the same meta-rule: never mutate state you haven't just observed.

**Rule:** Formalize an 'OAV guard' (Observe-Act-Verify): any state-mutating operation must be preceded by a fresh read of the state it will mutate and followed by a verification read. No exceptions for 'I just checked it' — staleness is the default assumption.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 5287886b-6995-4b9f-a22f-38e91d2a0ce4_

---
### Insight (conf=0.50)
> The low-signal session metadata pattern and the fire-and-forget notification pattern both represent information loss at system boundaries. Combined with the WAL format migration, this suggests the system is evolving toward a 'structured telemetry' model where every interaction boundary should emit machine-parseable signals rather than human-readable ones. Sparse data should trigger a 'low confidence' flag rather than being treated as normal data.

**Rule:** WAL entries from sessions with fewer than 5 substantive tool calls should be tagged with a 'low-signal' flag. Downstream pattern extraction should weight these entries at 0.5x to prevent sparse-data artifacts from polluting learned patterns.

_Patterns: c492a9f2-55a9-4c36-9bf3-6c98959e30a7, 2e7d5054-603d-4ba1-92cb-41bca5de2463, 0629319a-4440-4d1b-bad4-5ad0db93399a_

---
### Insight (conf=0.60)
> The user works on three distinct project archetypes — simulation (geopolitical), dashboard (iDream), and data pipeline (SvelteKit/eBay) — but applies the same session continuity infrastructure to all of them. This suggests the continuity tools are project-agnostic but the checkpoint content should be project-aware. A simulation checkpoint needs different state than a dashboard checkpoint (running processes vs. UI state vs. data pipeline position).

**Rule:** Core-dump templates should be project-type-aware: detect project type from package.json/config and include domain-specific state (pm2 process list for dashboards, current data cursor for pipelines, agent topology for simulations) alongside the generic task/file state.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.82)
> There's a tension between the user's terse-command style (which signals 'more autonomy') and their explicit correction about scope creep (which signals 'less autonomy'). The resolution is that autonomy should be high on the execution axis but zero on the scope axis — the user wants a fast, obedient executor, not a proactive architect. The git owner-verification rule is another instance: don't infer, verify.

**Rule:** Autonomy is a 2D vector: (execution_speed, scope_expansion). Terse commands increase execution_speed toward maximum. Scope_expansion should remain at zero unless the user explicitly widens it. When a terse command is ambiguous between 'continue current scope' and 'expand scope', always choose 'continue current scope'.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, 556fbc99-c295-493f-8b7a-218b2f5e964f, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.55)
> The Slack MCP persistent failure and the WAL markdown-to-JSONL migration are both examples of infrastructure that was optimized for human readability first and machine reliability second. The WAL successfully migrated; Slack MCP hasn't. This suggests a general principle: any infrastructure that is load-bearing for the user's workflow (WAL, checkpoints) must prioritize machine-parseability over human-readability, and tools that can't achieve reliable machine integration (Slack MCP) should be deprioritized rather than repeatedly debugged.

**Rule:** After 3 failed attempts to establish an MCP connection across separate sessions, mark the server as 'unreliable' in memory and suggest alternative approaches (webhooks, CLI tools, direct API) rather than attempting reconnection.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 1523746a-7091-4022-b130-7e28b7f77561_

---
### Insight (conf=0.65)
> The pattern of 20-80 tools per turn combined with milestone-based core dumps suggests the user's sessions follow a 'sprint' cadence within each context window. The optimal checkpoint strategy isn't time-based (every N minutes) but progress-based (after each milestone). This mirrors game save-point design: save after boss fights, not on a timer.

**Rule:** Trigger automatic checkpoints on milestone transitions (file creation, test pass, feature completion, git commit) rather than on tool-count or time thresholds. Track a 'milestone stack' and checkpoint when the stack depth decreases (i.e., a milestone was completed).

_Patterns: e218ac38-3844-4295-a972-c9dc01b22d13, f1b15033-a4e3-4a70-84fa-4de726a42926, c892fa80-f5af-4270-9e16-9225249062cc_

---


## Wake Cycle — 2026-04-29 09:24 UTC

### Insight (conf=0.55)
> The user gravitates toward complex stateful simulations (geopolitical agents, dream tracking) — domains where the software itself mirrors the session-continuity problem: both require persisting rich state across boundaries (turns/sessions for the agent, time-steps/saves for the simulation). The WAL/checkpoint infrastructure could be directly reused as an in-app event-sourcing layer for these projects.

**Rule:** When working on stateful simulation or dashboard projects for this user, evaluate whether the WAL/JSONL infrastructure can serve double duty as an application-level event log, reducing architecture duplication.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.72)
> Terse continuation commands and iterative UI refinement are the same cognitive pattern: the user thinks in rapid micro-corrections, treating the agent like a REPL with visual feedback. The optimal interface isn't 'describe then build' but 'nudge and verify' — a tight loop where each turn is a small delta. This means checkpoint granularity should match UI-change granularity, not logical-unit granularity.

**Rule:** During iterative UI refinement sessions (detected by 3+ consecutive short correction messages), auto-checkpoint every 5 changes rather than waiting for logical-unit boundaries, since each micro-correction is a potential rollback point.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.78)
> The vision loop for desktop automation (screenshot → annotate → act → verify) and the iterative UI refinement loop (change → screenshot → feedback → change) are isomorphic control loops. Both fail when verification is skipped. The desktop automation lesson ('coordinate guessing without annotation leads to failures') applies equally to UI development: claiming a CSS change 'looks right' without a screenshot is the same class of error as clicking without annotation.

**Rule:** After any visual change (CSS, layout, color, spacing), capture a screenshot before reporting completion — apply the same verify-before-act discipline from desktop automation to UI development.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.82)
> State management failures share a common root: acting on stale assumptions about mutable external state (git worktree had unstaged changes; repo owner was inferred from prior session; git state was assumed from conversation context). The /catchup+/core-dump cycle is the user's workaround for the agent's inability to maintain ground truth across boundaries. All three patterns reduce to: 'verify before mutate, especially after any boundary crossing.'

**Rule:** After any session resumption, context compaction, or worktree switch, run a state-verification pass (git status, process list, file existence checks) before any mutating operation — treat every boundary crossing as a potential state invalidation event.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 694c5087-f6dc-4dd0-88dc-8645a8dda00f_

---
### Insight (conf=0.60)
> The user maintains multiple complex, long-running projects simultaneously (SvelteKit data pipeline, iDream dashboard, geopolitical simulation). Each project has its own dev server, its own state, its own continuation needs. The session-continuity infrastructure is project-agnostic but the context it restores is project-specific. This suggests the WAL/checkpoint system needs project-scoping — a per-project WAL partition — to avoid cross-contamination when switching between projects in the same session.

**Rule:** When /catchup detects a project-directory switch from the previous session, warn before loading WAL entries from a different project context — cross-project state bleed is a likely source of subtle errors.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.65)
> With 20-80 tools per turn and multiple compaction cycles per session, the WAL and checkpoint system isn't just a convenience — it's load-bearing infrastructure equivalent to a database transaction log. The analogy to database WALs is not metaphorical: both exist because the primary store (conversation context / RAM) is volatile, both enable crash recovery, and both need compaction/truncation policies. This suggests applying database WAL best practices: bounded retention, checksums, and compaction triggers based on size rather than time.

**Rule:** Trigger WAL compaction (checkpoint + truncate) based on entry count (every ~50 entries) in addition to the current time-based triggers, to prevent unbounded WAL growth in high-tool-count sessions.

_Patterns: e218ac38-3844-4295-a972-c9dc01b22d13, c892fa80-f5af-4270-9e16-9225249062cc, 1523746a-7091-4022-b130-7e28b7f77561_

---


## Wake Cycle — 2026-04-29 11:19 UTC

### Insight (conf=0.72)
> The vision-loop pattern (screenshot → annotate → verify) for desktop automation is structurally identical to the checkpoint-loop for session continuity (dump → catchup → verify state). Both fail when you skip the verify step and assume prior state is current. The worktree data-loss incident is the session-continuity equivalent of coordinate-guessing without annotation — acting on assumed state instead of observed state. A unified 'observe-before-act' discipline applies across all three domains.

**Rule:** Before any state-mutating operation (UI click, git branch switch, session resume, file write to external system), execute an explicit observe step that reads current state into context. Never act on remembered state alone — the cost of one extra read is always less than the cost of acting on stale assumptions.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, e218ac38-3844-4295-a972-c9dc01b22d13, 5287886b-6995-4b9f-a22f-38e91d2a0ce4_

---
### Insight (conf=0.55)
> The WAL migration from markdown to JSONL mirrors the task-notification pattern of 0-tool fire-and-forget signals. Both represent a shift toward machine-queryable, structured state over human-readable prose. The fire-and-forget notifications are effectively micro-WAL entries that lack persistence. If these async signals were captured as JSONL WAL entries, catchup could reconstruct not just what the agent did, but what external events arrived during the session.

**Rule:** Log async task completion notifications as WAL entries of kind 'external_signal' so that /catchup can reconstruct the full timeline of events, not just agent actions.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.82)
> There's a tension between two validated preferences: the user issues terse commands expecting autonomous continuation, BUT also corrected the agent for exceeding requested scope. The resolution is that autonomy should be high on the execution axis (do more steps) but zero on the scope axis (don't add features). The iterative UI refinement pattern reveals why — the user steers via many small corrections, so the agent's job is to execute each micro-instruction precisely, not to anticipate the next one. Over-anticipation breaks the feedback loop the user depends on.

**Rule:** When receiving terse continuation signals during iterative UI work, execute exactly the last stated change and stop. Do not bundle 'obvious' next steps — the user's refinement loop depends on seeing each change in isolation before deciding the next one.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 92a767af-37ad-4b83-84af-684fd98948b5, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.68)
> Three patterns share a common failure mode: acting on incomplete or stale external-system state. Slack MCP fails across sessions (external service state is unreliable), sparse session data produces low-confidence extractions (insufficient signal treated as sufficient), and git owner inference from context caused errors (assumed state vs actual). All three would benefit from the same meta-rule: when interacting with external systems, probe and verify before acting, and degrade gracefully when the probe returns insufficient data rather than proceeding with assumptions.

**Rule:** For external system interactions (MCP servers, git remotes, APIs), always run a lightweight health-check probe before the substantive operation. If the probe fails or returns sparse data, report the gap to the user rather than inferring the missing information.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, c492a9f2-55a9-4c36-9bf3-6c98959e30a7, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.58)
> The user's preference for generic reusable test patterns connects unexpectedly with the UI iteration pattern and the desktop automation vision loop. All three demand verification-as-a-first-class-workflow-step rather than an afterthought. The dream dashboard's iterative aesthetic refinement is essentially a manual visual regression test suite. If the generic-test-pattern preference were extended to UI work — capturing screenshot baselines as reusable visual assertions — it would automate the most time-consuming part of the dashboard workflow.

**Rule:** For projects with iterative UI refinement (like the iDream dashboard), capture screenshot baselines after user-approved states and offer to run visual regression diffs before reporting subsequent changes as complete.

_Patterns: 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, dd2e18ab-2182-4f88-8eab-354193b9e90a, c1405960-924b-4896-b075-e8de0d9868d1_

---
### Insight (conf=0.63)
> Session continuity (WAL + checkpoint) has become the user's primary state management layer, displacing git for that role. Meanwhile, the SvelteKit dev server on :5173 is frequently restarted — another form of state loss. These are the same problem at different layers: conversation state (WAL), application state (dev server), and code state (git). The user has invested heavily in solving layer 1 but layers 2 and 3 still cause friction. A unified 'session resume' that also verifies dev server health and git cleanliness would close the loop.

**Rule:** When /catchup runs, also verify dev server status (pm2 list or port check) and git working tree cleanliness. Report all three layers — conversation state, process state, code state — in a single resume summary.

_Patterns: 1523746a-7091-4022-b130-7e28b7f77561, 694c5087-f6dc-4dd0-88dc-8645a8dda00f, b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a_

---


## Wake Cycle — 2026-04-29 19:11 UTC

### Insight (conf=0.72)
> The WAL markdown-to-JSONL migration and the vision loop pattern share a deeper principle: machine-queryable structured formats outperform human-readable ones when the consumer is an agent. The vision loop succeeded because it replaced coordinate guessing (unstructured) with annotated screenshots (structured). The WAL migration succeeded for the same reason — jq queries over JSONL beat regex over markdown. This suggests any agent-consumed artifact should default to structured-first, human-readable-second.

**Rule:** When creating any artifact that will be consumed by an agent (checkpoints, state files, annotation outputs), default to machine-queryable structured formats (JSONL, JSON, typed CSV) over prose markdown. Add a human-readable summary only as a secondary view.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 846615fc-c020-422e-9ce9-b5a55e624bb6, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.82)
> There is a tension between two user preferences: terse continuation commands signal 'keep going autonomously' but the user also corrected the agent for overstepping scope. The resolution is directional: terse inputs authorize depth (more work on the current task) but not breadth (new tasks or refactors). The iterative UI refinement pattern confirms this — 'better' means 'improve this specific thing', never 'also fix adjacent things'.

**Rule:** Terse continuation commands ('next', 'keep going', 'better') authorize deeper execution on the current task only. Never interpret them as permission to expand scope. If the current task is complete and a terse command arrives, ask what's next rather than inventing work.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 92a767af-37ad-4b83-84af-684fd98948b5, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.68)
> The user works across at least four distinct large projects (geopolitical simulation, iDream dashboard, SvelteKit data pipeline, game theory multi-agent). All share a common architectural signature: complex state, multi-agent or multi-component architecture, and long-running development timelines. The session continuity infrastructure isn't just a preference — it's load-bearing because the projects themselves are too complex to re-derive context from code alone. The WAL/checkpoint system is essentially a project-complexity tax.

**Rule:** For projects with >3 interacting subsystems or multi-session development arcs, auto-checkpoint at every 15 tool calls (not 30) and include a one-line 'current intent' field in each checkpoint so /catchup can reconstruct not just state but direction.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.75)
> Context loss and state assumptions cause failures across different domains: worktree switching loses unstaged changes, wrong repo owner is inferred from stale context, and session continuations lose prior state. All three are instances of the same anti-pattern: acting on remembered state instead of re-verified state. The worktree incident is the git-level version of what context compaction does at the conversation level.

**Rule:** Before any state-mutating operation (git checkout, branch push, file overwrite, session handoff), re-read the current state even if you 'just' checked it. Treat every state-reading as having a TTL of one tool call.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.55)
> Three patterns describe 'low-signal interactions': Slack MCP fails silently across sessions, sparse session data yields low-confidence learnings, and async notifications arrive as zero-content signals. These share a meta-pattern: the system generates events that look like they should carry information but don't. This is a signal-to-noise problem — the system should either make these interactions richer or explicitly mark them as no-ops so they don't pollute pattern extraction.

**Rule:** When extracting patterns from session data, discard or down-weight entries with <3 tool calls and <100 reply characters. For repeatedly-failing integrations (like Slack MCP), log a single 'known-broken' entry rather than re-recording the failure each session.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, c492a9f2-55a9-4c36-9bf3-6c98959e30a7, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.65)
> The user's iterative UI refinement workflow and their preference for generic reusable tests both reflect a 'converge through iteration' cognitive style. They don't specify final state upfront — they refine toward it. The vision loop for desktop automation is the agent-side mirror of this same pattern. This suggests the agent should optimize for fast feedback loops (screenshot-verify-adjust) rather than trying to get it right in one shot, and test infrastructure should similarly support rapid re-runs over comprehensive one-shot suites.

**Rule:** For UI tasks, default to a tight render-verify-adjust loop (max 2 changes between screenshots). For test infrastructure, prefer parameterized test templates that can be re-invoked with different inputs over monolithic test files.

_Patterns: 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5, dd2e18ab-2182-4f88-8eab-354193b9e90a, c1405960-924b-4896-b075-e8de0d9868d1_

---
### Insight (conf=0.78)
> The /catchup + /core-dump cycle has evolved into a de facto version control system for agent cognitive state, parallel to but independent of git. Git tracks code state; WAL+checkpoints track intent state. This dual-track system exists because git commits don't capture 'what I was trying to do next' — only 'what I just did'. The user's workflow depends on both tracks being maintained, and failures in either track cause different kinds of continuity loss.

**Rule:** Treat git commits and WAL checkpoints as complementary, not redundant. Every git commit should be preceded or accompanied by a WAL checkpoint that captures current intent and next steps — not just completed work. On /catchup, reconstruct from both sources: git log for what changed, WAL for why and what's next.

_Patterns: e218ac38-3844-4295-a972-c9dc01b22d13, 1523746a-7091-4022-b130-7e28b7f77561, 694c5087-f6dc-4dd0-88dc-8645a8dda00f, 07e91a34-f2bd-4d49-8ac8-b81f1d0cd808_

---


## Wake Cycle — 2026-04-29 20:37 UTC

### Insight (conf=0.72)
> Terse continuation commands and iterative UI refinement are the same behavior at different granularities — the user operates as a human REPL, issuing minimal-diff corrections and expecting the system to maintain the full accumulated state. This is a directorial interaction style: the user steers, the agent drives. The cost of this pattern is that ambiguity accumulates silently — each terse 'good but...' narrows intent without ever fully specifying it, making late-session divergence expensive.

**Rule:** After every 5th terse continuation in a UI refinement chain, emit a one-line summary of accumulated constraints so far ('current spec: dark bg, 14px body, no border on cards, gradient header') to surface silent drift before it compounds.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.68)
> State loss incidents (worktree unstaged changes, wrong repo owner inference) cluster around context-boundary crossings — the same moments when /core-dump is most needed. The checkpoint mechanism protects conversational state but not environmental state (git index, process tables, filesystem). These are two halves of the same continuity problem, and only one is solved.

**Rule:** Include a lightweight environment snapshot in every core-dump: current branch, dirty-file count, running pm2 services, and active ports. Reconstruct env state on /catchup, not just conversation state.

_Patterns: e218ac38-3844-4295-a972-c9dc01b22d13, 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.61)
> The vision-loop pattern for desktop automation and the iterative UI refinement workflow are structurally identical: act → render → observe → correct. The user's insistence on screenshot verification before 'done' in dashboards is the same principle as the validated vision loop for desktop automation. Both reject 'code-correct implies visually-correct'. This could unify into a single render-verify protocol applied to all visual output.

**Rule:** For any task producing visual output (UI feature, HTML report, dashboard widget), apply the same verify loop as desktop automation: capture screenshot → confirm with user or self-check → only then report complete.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.78)
> High tool-count sessions (20-80+ tools) and zero-tool notification messages are opposite extremes of the same signal-to-noise spectrum. The scan-sessions pattern extractor struggles with both: dense sessions produce redundant patterns (the 15+ near-identical session-continuity entries in this very input), while sparse notifications produce low-confidence noise. The pattern extraction pipeline has a missing middle — it lacks a deduplication/consolidation pass.

**Rule:** Before outputting extracted patterns, run a dedup pass: merge patterns sharing >80% keyword overlap into a single entry with a combined occurrence count and date range, preserving only the most specific formulation.

_Patterns: c892fa80-f5af-4270-9e16-9225249062cc, 2e7d5054-603d-4ba1-92cb-41bca5de2463, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.55)
> Repeated Slack MCP failures and dev-server restarts are symptoms of the same root cause: long-running external connections don't survive the session-continuation lifecycle. The user's workflow assumes persistent connections (MongoDB, pm2, dev servers, Slack) but the agent's lifecycle is discontinuous. Every /catchup restores conversation state but not connection state, creating a class of 'ghost dependency' bugs.

**Rule:** On /catchup, after restoring conversation state, probe all expected external connections (MCP servers, dev servers, database) with a lightweight health check before resuming work. Report any that are down rather than discovering mid-task.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, c70ae766-c39a-442a-a15d-fbe84d854e0c, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a_

---
### Insight (conf=0.82)
> There is a tension between two validated preferences: 'treat terse input as autonomous-continue' and 'don't autonomously implement beyond what was requested'. These are not contradictory but they define a narrow corridor — high autonomy in execution, zero autonomy in scope. The failure mode is that terse continuation ('next', 'keep going') gets interpreted as scope expansion rather than task continuation. The distinguishing signal is whether the current task has a defined next step.

**Rule:** On terse continuation: if the current task has an unambiguous next step, execute it. If the task is complete and 'next' would require choosing a new scope, pause and ask what's next rather than inferring.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, 556fbc99-c295-493f-8b7a-218b2f5e964f_

---
### Insight (conf=0.58)
> The preference for generic reusable test patterns and the WAL migration from markdown to JSONL reflect the same design instinct: prefer machine-parseable, composable formats over human-readable-but-brittle ones. The user values infrastructure that scales across sessions and projects without manual adaptation. Tests should be parameterized, state should be queryable, formats should be tooling-friendly.

**Rule:** When creating any new persistent artifact (tests, configs, state files), default to the most machine-queryable format that remains human-readable. Prefer JSONL over markdown logs, parameterized tests over hardcoded fixtures, structured configs over prose.

_Patterns: c1405960-924b-4896-b075-e8de0d9868d1, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a_

---


## Wake Cycle — 2026-04-29 20:57 UTC

### Insight (conf=0.55)
> Context limits are hit frequently because the project domain (complex multi-agent geopolitical simulation) inherently requires large context to reason about. The WAL migration from markdown to JSONL mirrors the same pressure — markdown was too verbose for machine recovery. The root issue isn't session tooling but domain complexity exceeding single-context capacity. A structured domain-model index (not free-text) that the agent loads selectively could reduce context burn rate.

**Rule:** For projects with >5 interacting subsystems, maintain a machine-readable domain index (JSONL or YAML, not prose) that maps subsystem names to entry-point files and key types — load only the relevant slice at session start instead of reconstructing from scratch.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.70)
> The terse-command preference and iterative UI refinement pattern are the same behavior at different granularities: the user treats the agent as a REPL, issuing minimal keystrokes and expecting immediate, incremental state changes. This is a power-user interaction model analogous to vi modal editing — the agent should optimize for keystroke-to-effect ratio, not conversational clarity.

**Rule:** When the user is in iterative refinement mode (3+ consecutive short messages on the same artifact), suppress all explanatory output and respond only with the change confirmation or screenshot. Re-enable normal verbosity when the topic shifts.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.75)
> The vision-loop pattern for desktop automation and the iterative UI refinement pattern share a common structure: observe → act → verify → repeat. The user's dissatisfaction with UI work likely spikes when the verify step is skipped. Both patterns suggest the agent should never report a visual change as 'done' without a screenshot in the same turn.

**Rule:** After any UI-affecting code change, take a screenshot before responding. If screenshot capture fails, explicitly state the change is unverified rather than claiming completion.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.72)
> Worktree data loss and incorrect repo owner inference are both symptoms of stale state assumptions after context boundaries. The session continuation infrastructure (WAL/checkpoint) preserves task-level state but not environment-level state (unstaged changes, current branch, remote config). There is a gap between 'what the agent remembers' and 'what the filesystem actually is' that widens at every compaction.

**Rule:** After every /catchup or context compaction, run a mandatory environment probe (git status, git remote -v, git stash list) before any git-mutating operation — even if the recovered state says the working tree is clean.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 1523746a-7091-4022-b130-7e28b7f77561_

---
### Insight (conf=0.60)
> Repeated Slack MCP failures and low-signal session data extraction share a failure mode: the agent retries without enough diagnostic signal to change the outcome. Both would benefit from a 'diminishing returns' circuit breaker — after N attempts with no new information, stop and escalate rather than retry.

**Rule:** After 3 failed attempts at the same integration/connection with no new diagnostic information gained, stop retrying and write a structured failure report (what was tried, what error, what's missing) instead of attempting a 4th time.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.85)
> There is a tension between the user's preference for terse autonomous continuation and their correction about scope creep. The resolution: terse commands authorize execution speed, not scope expansion. 'Keep going' means 'faster on the current track', never 'find more tracks'. These two preferences are complementary constraints, not contradictory.

**Rule:** Terse continuation commands ('go', 'next', 'keep going') increase execution velocity on the current task only. They never authorize scope expansion, new refactors, or unsolicited improvements.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, 556fbc99-c295-493f-8b7a-218b2f5e964f_

---
### Insight (conf=0.60)
> The preference for generic reusable test patterns and the WAL migration to JSONL both reflect a deeper principle: the user values machine-queryable, composable formats over human-readable one-offs. This suggests new infrastructure (configs, schemas, test fixtures) should default to structured formats (JSON/JSONL/YAML) rather than prose or ad-hoc scripts.

**Rule:** When creating new configuration, test fixtures, or state files, default to JSONL or YAML over markdown or free-text unless the primary consumer is a human reader.

_Patterns: c1405960-924b-4896-b075-e8de0d9868d1, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---
### Insight (conf=0.65)
> State management via /catchup + /core-dump has become a parallel version control system that operates alongside but independent of git. Git tracks code state; WAL/checkpoint tracks agent cognitive state. These two systems can desynchronize (agent thinks it's at commit X but git moved). A 'state anchor' that ties a checkpoint to a specific git SHA would prevent drift.

**Rule:** Every core-dump and WAL checkpoint entry should include the current git HEAD SHA and branch name, so /catchup can detect if the code state has diverged since the checkpoint was written.

_Patterns: f1057a8d-e978-416c-b52e-7ea8fd28e770, 00fb690c-b719-4a18-ad08-94adf937ae00, 694c5087-f6dc-4dd0-88dc-8645a8dda00f_

---


## Wake Cycle — 2026-04-29 23:28 UTC

### Insight (conf=0.85)
> The WAL markdown-to-JSONL migration was recorded as a distinct 'learning' in at least four separate extraction passes, indicating the pattern-extraction pipeline itself lacks deduplication — the system that should prevent redundant memories is generating them

**Rule:** Always deduplicate extracted patterns against existing pattern IDs by semantic similarity before persisting, and merge rather than append when confidence delta is less than 0.05

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 846615fc-eeb8-4a44-bf0a-bf06c723fde8_

---


## Wake Cycle — 2026-04-30 12:40 UTC

### Insight (conf=0.72)
> Context limits, WAL format migration, and fire-and-forget task signals all point to the same root issue: the system treats context as a scarce resource but doesn't have a proactive eviction strategy. JSONL WAL was a step toward queryable state, but the 0-tool/0-reply notification pattern suggests many context-window entries carry zero informational value. A WAL compaction pass that filters out no-op notifications before catchup ingestion would reduce context pressure and delay compaction boundaries.

**Rule:** During /catchup, skip WAL entries where tool_count=0 AND reply_chars=0 (fire-and-forget signals) to reduce context consumption by ~10-15% per session.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.65)
> The user works on at least four distinct complex projects (game theory simulation, geopolitical modeling, iDream dashboard, SvelteKit data pipeline) that all share a pattern: long-lived, multi-session, stateful development with heavy UI iteration. The session continuity infrastructure (WAL, core-dump, catchup) is essentially a poor man's project-switching mechanism. These projects would benefit from per-project WAL partitioning rather than a single global WAL that mixes context from unrelated domains.

**Rule:** Partition WAL files per project root (e.g., .claude/wal.jsonl per repo) rather than using a single global ~/.claude/wal.jsonl, so /catchup never ingests context from an unrelated project.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.82)
> There is a tension between two user preferences: terse continuation commands signal 'keep going autonomously' but the user also corrected the agent for exceeding scope. The resolution is that autonomy should be high on the execution axis (more tool calls, deeper investigation within the current task) but zero on the scope axis (never expand what is being done). Short commands like 'next' mean 'continue the current bounded task faster' not 'find more things to do'.

**Rule:** On terse continuation ('next', 'keep going', 'more'), increase execution depth (more verification, more tool calls) but never broaden scope. If the current task is complete, stop and report rather than finding adjacent work.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 2dfa1a6e-03f6-473e-8476-8a5da501300e, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.78)
> The vision-loop pattern for desktop automation (screenshot → annotate → act → verify) mirrors the user's iterative UI refinement workflow (make change → screenshot → get feedback → refine). Both are convergent feedback loops where skipping the verification step causes cascading errors. The common principle: never report a visual change as done without a rendered verification. This applies equally to automated desktop actions and manual UI development.

**Rule:** After any UI-affecting change (CSS, layout, component), take a screenshot before reporting done. For desktop automation, use the vision loop. For dashboard/web work, use browser screenshot or dev tools. The verification step is not optional in either context.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.70)
> Worktree data loss, wrong-org pushes, and context handoff failures share a root cause: acting on stale mental state. In all three cases, the agent assumed something was true (no unstaged changes, correct org, valid context) without re-verifying. The WAL/checkpoint system is the primary state management mechanism, which means state verification is even more critical than in a normal git workflow — because the 'source of truth' is a reconstructed approximation, not direct memory.

**Rule:** After any /catchup or context reconstruction, treat ALL prior assumptions as unverified. Run the verification triad (git status + git log + git diff) plus check CWD and active branch before any side-effecting operation.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 1523746a-7091-4022-b130-7e28b7f77561_

---
### Insight (conf=0.60)
> Slack MCP repeatedly failing and sparse session data producing low-confidence extractions are both instances of a broader pattern: systems that fail silently and get retried without diagnosis. The Slack MCP keeps being reinstalled without fixing the root cause; sparse data keeps being analyzed without flagging that the signal-to-noise ratio is too low to act on. Both need a 'circuit breaker' — after N failures or low-confidence results, stop retrying and escalate to the user.

**Rule:** After 3 consecutive failures of the same MCP tool or integration across sessions, stop retrying and file a proposal (via propose.sh) documenting the failure pattern. For analysis with confidence < 0.7, flag results as 'low-signal' and do not merge into persistent memory without user confirmation.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, c492a9f2-55a9-4c36-9bf3-6c98959e30a7_

---
### Insight (conf=0.68)
> Sessions spanning 100+ turns with 20-80 tools per turn and multiple compaction cycles suggest the user's work sessions are 5-10x longer than what the context window was designed for. The /core-dump at milestones pattern is a workaround for a fundamental mismatch between session length and context capacity. Rather than more frequent checkpoints (which themselves consume context), the system could benefit from hierarchical summarization — a 'session abstract' that compresses an entire multi-compaction session into 10-20 lines for the next session's /catchup.

**Rule:** When a session exceeds 2 compaction cycles, generate a hierarchical summary: a 10-line 'session abstract' capturing only decisions made and state changes, separate from the detailed WAL. Use the abstract for cross-session /catchup and the detailed WAL only for intra-session recovery.

_Patterns: e218ac38-3844-4295-a972-c9dc01b22d13, e181d5f7-4435-4c76-a1a4-82f3536aac19, c892fa80-f5af-4270-9e16-9225249062cc_

---
### Insight (conf=0.88)
> Four separate patterns all record the same WAL markdown→JSONL migration event, suggesting the pattern extraction system itself has a deduplication problem. The migration is a single historical fact being treated as four independent learnings, which wastes pattern budget and dilutes signal. This is meta-evidence that the pattern consolidation pipeline needs a similarity threshold before emitting new patterns.

**Rule:** Before emitting a new pattern, compute similarity against existing patterns (simple: shared entity + shared valence + overlapping keywords). If similarity > 0.8, merge into the existing pattern with an incremented occurrence count rather than creating a new entry. Apply same dedup to the 14+ session-continuity patterns in this batch.

_Patterns: 0629319a-4440-4d1b-bad4-5ad0db93399a, 846615fc-eeb8-4a44-bf0a-bf06c723fde8, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---


## Wake Cycle — 2026-04-30 13:57 UTC

### Insight (conf=0.72)
> Context boundaries are not bugs but architectural joints — the WAL/JSONL migration mirrors how distributed systems moved from human-readable logs to machine-queryable event stores. Session continuity is effectively a single-node version of event sourcing, suggesting the checkpoint system could benefit from the same patterns (snapshots + replay, compaction, tombstones).

**Rule:** Treat core-dump as a snapshot and WAL as the event log — on /catchup, replay only WAL entries after the last checkpoint instead of re-reading the full dump. This reduces reconstruction time proportionally to session length.

_Patterns: 881b161f-3ee0-4597-ab7b-d6c2a860613d, 5c3499d0-aef9-4924-b559-e15bf88068ed, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 1523746a-7091-4022-b130-7e28b7f77561_

---
### Insight (conf=0.78)
> The user's terse continuation style and iterative UI refinement form a feedback loop that is structurally identical to a REPL — short input, observe output, adjust. This means the agent's job during UI work is not 'implement a feature' but 'be the other half of a visual REPL', where screenshot verification is the equivalent of printing a return value.

**Rule:** During iterative UI sessions, auto-screenshot after every visual change and present it before asking for next input — don't wait for the user to request verification. The terse command pattern means they expect to see results, not be asked if they want to see them.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.85)
> All three patterns share a root cause: acting on stale or assumed state instead of verifying current state. Worktree lost unstaged changes (assumed clean), wrong repo owner (inferred from context), coordinate guessing without screenshots (assumed position). These are all violations of the same invariant: 'read before write'.

**Rule:** Before any side-effecting operation that targets a specific entity (file, repo, UI element), the immediately preceding tool call must be a read/verify of that entity's current state. No exceptions — even if you 'just checked' before a compaction boundary.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.60)
> Fire-and-forget notifications and sparse session metadata are information-theoretic cousins: both are low-signal channels that the system currently treats as full-signal. The pattern analysis pipeline ingests sparse sessions at the same confidence as rich ones, and task notifications get processed as if they need responses. Both need a signal-strength discriminator.

**Rule:** Tag extracted patterns with a 'signal_density' score based on source richness (tool count, reply length, session duration). Downstream consumers should weight low-density patterns lower in aggregation, not just flag them in text.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, c492a9f2-55a9-4c36-9bf3-6c98959e30a7, 00fb690c-b719-4a18-ad08-94adf937ae00_

---
### Insight (conf=0.80)
> The user oscillates between two modes: 'understand only, don't touch' and 'just do it, don't ask'. These aren't contradictory — they map to exploration vs. execution phases. The terse commands signal execution mode; the scope correction signals exploration mode. The agent needs a phase detector, not a single autonomy level.

**Rule:** Infer session phase from message patterns: questions and 'explain/show/what' keywords = exploration mode (read-only, no unsolicited changes); imperatives and terse continuations = execution mode (act autonomously within stated scope). Phase can shift mid-session.

_Patterns: ff7b37a5-17ae-466e-b55e-585866af824b, 556fbc99-c295-493f-8b7a-218b2f5e964f, 2dfa1a6e-03f6-473e-8476-8a5da501300e_

---
### Insight (conf=0.70)
> The preference for generic reusable test patterns and the WAL migration from markdown to JSONL express the same underlying value: machine-queryability over human-readability. The user optimizes for systems that can be programmatically consumed and composed, not just read. This suggests new features should default to structured/parseable formats.

**Rule:** When creating any persistent artifact (logs, test fixtures, config, state files), default to a structured format (JSON, JSONL, YAML) over prose/markdown unless the artifact is exclusively human-consumed. Add a one-line comment documenting the schema.

_Patterns: c1405960-924b-4896-b075-e8de0d9868d1, 0629319a-4440-4d1b-bad4-5ad0db93399a, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---


## Wake Cycle — 2026-05-01 00:15 UTC

### Insight (conf=0.72)
> Four separate patterns independently record the same WAL markdown-to-JSONL migration, suggesting the pattern extraction system lacks deduplication and the migration's importance is being over-signaled relative to its operational impact

**Rule:** Always deduplicate patterns that describe the same event or migration before storing — merge into a single canonical pattern with the highest confidence score and earliest date

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 0629319a-4440-4d1b-bad4-5ad0db93399a, 846615fc-eeb8-4a44-bf0a-bf06c723fde8_

---


## Wake Cycle — 2026-05-01 00:42 UTC

### Insight (conf=0.85)
> Four independent pattern extractions captured the same WAL markdown-to-JSONL migration — this redundancy itself reveals that the pattern extraction system lacks deduplication, wasting downstream analysis budget on already-known facts

**Rule:** Always deduplicate extracted patterns by semantic similarity before persistence — if a new pattern's hypothesis overlaps >80% with an existing one, merge rather than append

**Evidence:**
- _Pattern_: "WAL format migrated from markdown to JSONL for machine-queryability; jq-based catchup is more reliable than parsing markdown"
- _Pattern_: "WAL format migrated from markdown to JSONL — new sessions should write JSONL, old markdown still honored by /catchup as fallback"
- _Pattern_: "WAL format was migrated from markdown to JSONL during session 867071c7; JSONL is now canonical"
- _Pattern_: "WAL format migrated from markdown to JSONL (canonical as of 2026-04-17); new sessions must write JSONL, not markdown"
- _Sessions_ (10): bc59cf34, 826dce96, 60f43456, +7 more

---


## Wake Cycle — 2026-05-01 03:16 UTC

### Insight (conf=0.55)
> The shift from markdown WAL to JSONL mirrors a broader pattern: as session continuity becomes load-bearing infrastructure (not optional logging), the serialization format must be machine-queryable, not human-readable. The same pressure that drives databases from flat files to indexed stores is driving session state from prose to structured data. This suggests the next evolution is not better JSONL but a lightweight embedded DB (SQLite) for session state, enabling indexed queries like 'last checkpoint for file X' without full-file scans.

**Rule:** When session state recovery consistently requires filtering/querying (not just reading), evaluate whether the storage format supports indexed access — JSONL with jq is a transitional step, not an endpoint.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 00fb690c-b719-4a18-ad08-94adf937ae00, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 1523746a-7091-4022-b130-7e28b7f77561_

---
### Insight (conf=0.62)
> Data hallucination and credential leakage are both instances of the same meta-failure: the agent generates plausible-looking content where it should produce nothing. In data pipelines, it fabricates values; with credentials, it persists secrets that should stay ephemeral. The common root is an 'fill the blank' instinct that overrides 'leave it empty.' This connects to session continuity — when context is lost across compactions, the temptation to fill gaps from inference rather than re-reading source data is highest.

**Rule:** After any context compaction or session resume, treat all in-memory data values as unverified — re-read from source before emitting any data value into output. The post-compaction state is the highest-risk moment for hallucinated fills.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, ef57d880-da40-403d-b5bc-49ae318f35bd, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.78)
> There is a tension between two user preferences: terse continuation signals ('next', 'keep going') demand autonomous execution, but scope correction ('only help understand, don't implement') demands restraint. The resolution is that autonomy applies to execution depth (more tool calls, deeper investigation) but not scope width — the user wants a fast, decisive agent that stays in its lane. This is the same pattern seen in military command: 'mission-type orders' give autonomy on HOW but not on WHAT.

**Rule:** On terse continuation, escalate execution intensity (more reads, deeper investigation, faster iteration) but never escalate scope. If the next logical step crosses a scope boundary, pause with a one-line confirmation even on a terse signal.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.72)
> The user works across at least four distinct domains (game theory simulation, geopolitical modeling, dream-tracking dashboard, SvelteKit data pipeline) but with a consistent architectural fingerprint: widget/agent-based decomposition, dark/light mode, iterative visual refinement, and long-running sessions. The domains differ but the development style is invariant. This suggests optimizations should target the development style (session continuity, visual verification loops, incremental UI feedback) rather than any single domain.

**Rule:** When entering a new project context for this user, assume: widget-based architecture, dark/light mode requirement, iterative visual refinement workflow, and sessions that will span multiple compaction cycles. Front-load checkpoint infrastructure even for 'small' tasks.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.65)
> Desktop automation's vision loop (screenshot → annotate → act → verify) and the UI refinement pattern (screenshot → user feedback → adjust → screenshot) are the same feedback loop at different speeds. Desktop automation validates coordinates mechanically; UI refinement validates aesthetics through the user. Both fail the same way when the verification step is skipped: coordinate guessing produces misclicks, and skipping screenshots produces 'done' claims the user rejects. Unifying these into a single 'visual verification protocol' would reduce both failure modes.

**Rule:** Any action that changes visual output (UI code, desktop automation, CSS) must close with a screenshot verification step before reporting completion. The screenshot is the proof, not the code diff.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.75)
> Git worktree data loss, wrong-repo pushes, and missed checkpoints are all 'stale mental model' failures — the agent acts on what it believes the state is rather than what it actually is. These cluster after context boundaries (compactions, session resumes, worktree switches). The common fix is the same: re-verify state immediately before any destructive or publishing operation, with extra vigilance right after any context discontinuity.

**Rule:** After any context discontinuity (compaction, session resume, worktree switch), the next git operation must be preceded by the full verification triad (status + log + diff) regardless of how recently it was last checked.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.70)
> The user's state management strategy (WAL + checkpoint + catchup) is functionally a write-ahead log with crash recovery — the same pattern used by databases and filesystems. But unlike a database WAL, there is no automatic recovery on startup; it requires manual /catchup invocation. The orphan turn-state files in the system reminder (20+ crashed sessions) demonstrate the cost: without automatic recovery, crashed sessions leave debris. This suggests the system needs an automatic recovery protocol on session start, not just a manual /catchup command.

**Rule:** On session start, if orphan turn-state files or incomplete WAL entries are detected, automatically trigger lightweight state recovery (equivalent to /catchup) before accepting new user input — don't wait for the user to remember to run it.

_Patterns: f1b15033-a4e3-4a70-84fa-4de726a42926, 584e7697-e747-48e6-9cd8-274ccffd99d8, 07e91a34-f2bd-4d49-8ac8-b81f1d0cd808, 694c5087-f6dc-4dd0-88dc-8645a8dda00f_

---


## Wake Cycle — 2026-05-01 04:18 UTC

### Insight (conf=0.72)
> Context loss across session boundaries and data hallucination share a root cause: the system operates on incomplete information and fills gaps with plausible-looking fabrications. WAL migration to JSONL (machine-queryable) reduces context loss the same way source-tracing reduces data hallucination — both replace fuzzy reconstruction with deterministic retrieval.

**Rule:** After any context boundary (compaction, session resume, catchup), treat all prior state as unverified — re-read files and re-check git status before acting, just as you would require source references before emitting data values.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 1e5df293-bb35-4b57-b67e-d2640b80c314_

---
### Insight (conf=0.85)
> The user's terse continuation style ('next', 'keep going') coexists with a hard scope ceiling preference. These seem contradictory but actually define a precise operating mode: maximum execution velocity within minimum scope expansion. The agent should interpret terse input as 'accelerate on the current vector' never as 'broaden the search space'.

**Rule:** Terse continuation messages authorize deeper execution on the current task only. Never interpret brevity as implicit permission to expand scope — short input = 'go faster on this', not 'do more things'.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.78)
> The user works across multiple complex, stateful projects (geopolitical simulation, dream dashboard, SvelteKit data pipeline) that all share a pattern: rich domain state that cannot be reconstructed from code alone. This explains why session continuity tools are so heavily used — these projects have high 'context entropy' where losing session state means losing understanding of intent, not just position.

**Rule:** For projects with complex domain state (simulations, dashboards with live data, data pipelines), core-dump should capture domain context (what the user is trying to achieve and why) not just technical state (what files changed). Include a 'domain intent' field in checkpoints.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.80)
> Desktop automation's vision loop (screenshot → annotate → verify) and UI iteration (screenshot before reporting done) are the same meta-pattern: visual verification as a gate. The user's iterative UI refinement style means they've been burned by 'looks good in code' failures. Both converge on: never claim visual work is done without a rendered proof.

**Rule:** Any task with a visual output (UI change, dashboard widget, desktop automation) must include a verification screenshot before reporting completion. Code-level correctness is necessary but not sufficient.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.82)
> Hallucinated data, fabricated API results, credential leaks, and wrong repo owners are all instances of the same failure mode: the agent generates plausible output when it lacks verified input. The severity scales with how far downstream the error propagates before detection — data values go into databases, credentials go into git history, wrong repos get force-pushed.

**Rule:** When you lack a verified source for any value that will be persisted (data field, credential, repo owner, branch name), STOP and ask rather than inferring. The cost of a 10-second question is always less than the cost of a plausible-looking fabrication reaching a permanent store.

_Patterns: 10b7a87a-5217-44e1-be13-e9acb9c24ae8, ef57d880-da40-403d-b5bc-49ae318f35bd, afe8a2d8-17b3-42bc-973d-eac449588f9b, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.68)
> Worktree switching losing unstaged changes and compaction losing conversation state are structurally identical: a context switch that silently drops uncommitted work. The fix is also identical — checkpoint before switching. The zero-tool task notifications pattern suggests the system already has fire-and-forget signals; checkpoint-before-switch could be another.

**Rule:** Before any context switch (worktree change, compaction, session handoff), run a 'dirty state' check: unstaged git changes, unsaved file edits, running processes. Checkpoint or warn before proceeding.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, e218ac38-3844-4295-a972-c9dc01b22d13, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.70)
> The WAL markdown→JSONL migration appeared independently in 4 pattern observations, suggesting it was a high-friction transition that multiple sessions encountered. This is a meta-signal: format migrations in frequently-used infrastructure create a long tail of compatibility issues. The 'old markdown still honored as fallback' note confirms the migration isn't fully clean.

**Rule:** When migrating a frequently-used file format (WAL, checkpoints, config), set a sunset date for the old format and add a one-time migration script rather than maintaining dual-format support indefinitely. Dual-format fallbacks become permanent technical debt.

_Patterns: 881b161f-3ee0-4597-ab7b-d6c2a860613d, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 846615fc-eeb8-4a44-bf0a-bf06c723fde8_

---


## Wake Cycle — 2026-05-01 05:20 UTC

### Insight (conf=0.72)
> Context loss across session boundaries creates the same class of trust violation as data hallucination — when the agent loses state and reconstructs it incorrectly, the user experiences fabricated context (wrong assumptions about what was done, what files look like, what branch is active) the same way they experience fabricated data values. Both are 'the agent confidently presented something false as true.' Session continuity infrastructure is actually anti-hallucination infrastructure.

**Rule:** After any context boundary (compaction, catchup, session resume), treat all prior state claims as unverified hypotheses — re-read files and git state before acting, with the same rigor applied to avoiding data hallucination. Label this class of error 'context hallucination' in mistake-patterns.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, ef57d880-da40-403d-b5bc-49ae318f35bd, 881b161f-3ee0-4597-ab7b-d6c2a860613d, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.85)
> There is a tension between two validated preferences: terse messages mean 'continue autonomously' AND the agent should not expand scope beyond what was requested. The resolution is that terse continuation signals authorize execution-axis autonomy (more tool calls, deeper investigation within the current task) but never scope-axis autonomy (new features, refactors, 'while I'm here' changes). These aren't contradictory — they define a narrow corridor of high-velocity, tightly-scoped work.

**Rule:** On terse continuation: increase execution speed and depth within the current task boundary, but explicitly re-check the task boundary before each new file or feature touched. If the next logical step expands scope, pause — even if the user said 'keep going.'

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.65)
> Both the WAL markdown→JSONL migration and the desktop automation vision loop follow the same meta-pattern: replacing human-readable-but-fragile formats with machine-queryable-but-opaque ones. The user consistently prefers reliability over readability at the infrastructure layer, while keeping human-readable surfaces at the interaction layer. This suggests future infrastructure decisions should default to structured/machine-parseable formats (JSONL, structured screenshots with coordinates) over pretty-printed ones.

**Rule:** For any new persistence or state-transfer mechanism, default to machine-queryable structured format (JSONL, JSON, structured annotations) over human-readable prose. Reserve human-readable formatting for user-facing output only.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.58)
> The user's projects share a common architecture: complex multi-entity systems (geopolitical agents, dream entries, eBay parts) with rich visualization layers (globe/terrain, dashboard widgets, SvelteKit UI) and persistent backends. The session continuity problem is amplified because these projects have deep interconnected state that can't be quickly re-derived from code alone — you need to know which agents are configured, which widgets are active, which data pipeline stage you're in. This explains why /catchup and /core-dump are so critical: the project architectures themselves resist cold-start comprehension.

**Rule:** For projects with multi-entity architectures and rich state (simulations, dashboards, data pipelines), core-dump should include not just code state but runtime configuration state: which services are running, which data is loaded, which UI view is active. Structure core-dumps with a 'runtime snapshot' section.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.78)
> All three are instances of 'acting on stale or assumed state causes irreversible damage': worktree switching without checking unstaged changes, pushing to wrong org from cached context, writing credentials from session memory to files. The common failure mode is 'the agent had a mental model of state that diverged from reality, and the side-effect was destructive.' This is the operational counterpart of data hallucination — not fabricating data, but fabricating system state.

**Rule:** Before any destructive or externally-visible operation (git push, file write, branch create, credential handling), the agent must perform at least one fresh read of the relevant state — never act on cached mental models. Classify 'state assumption without verification' as the same severity as data hallucination.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.70)
> Iterative UI refinement sessions and long implementation sessions share a hidden cost: they burn through context windows faster than any other task type because each iteration requires re-rendering, re-reading, and re-verifying. The checkpoint-at-milestones rule and the front-load-screenshots rule are both strategies for the same underlying problem — these task types have the worst context-efficiency ratio. They should trigger earlier and more aggressive checkpointing than other task types.

**Rule:** For UI iteration sessions and long implementation sessions, reduce the checkpoint interval from ~30 actions to ~15 actions, and proactively offer /core-dump when switching between visual refinement targets (different widgets, different pages, different components).

_Patterns: 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.68)
> The combination of 'never fabricate data' and 'terse input means continue autonomously' creates a specific risk zone: when the agent is in autonomous-continue mode processing data, the temptation to fill gaps rather than stop and report is highest. The terse protocol's 'don't ask, just execute' directive conflicts with the data integrity rule's 'stop if you can't verify.' Data processing tasks need an explicit carve-out from the terse continuation protocol.

**Rule:** During data processing or enrichment tasks, terse continuation signals authorize processing the next batch but never authorize inferring missing values. If a data gap is encountered during autonomous continuation, log it and skip rather than guessing — report the gaps at the end of the batch.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, ef57d880-da40-403d-b5bc-49ae318f35bd, 556fbc99-c295-493f-8b7a-218b2f5e964f_

---


## Wake Cycle — 2026-05-01 06:32 UTC

### Insight (conf=0.72)
> Context loss across session boundaries increases hallucination risk in data-heavy tasks. When state is imperfectly reconstructed via catchup/core-dump, the agent may fill gaps with plausible-looking but fabricated values — the same failure mode the user flagged as a 'serious trust killer'. Session continuity infrastructure isn't just convenience; it's a hallucination prevention mechanism.

**Rule:** After any context reconstruction (catchup, compaction, session continuation), treat all data values from prior context as unverified claims — re-read source files before emitting any data value in output. Never carry forward numeric or structured data across a context boundary without re-verification.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, ef57d880-da40-403d-b5bc-49ae318f35bd, 881b161f-3ee0-4597-ab7b-d6c2a860613d, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.78)
> Terse continuation signals and scope-limiting corrections are two sides of the same coin: the user wants maximum execution velocity within a tight scope. 'keep going' means 'fast on the current track', not 'expand'. Agents that interpret terse input as license to broaden scope will hit the scope correction pattern.

**Rule:** When receiving a terse continuation after a scope correction in the same session, reduce scope aggressiveness by one level — the user has signaled both 'go fast' and 'stay narrow' in the same session, and narrow wins ties.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.68)
> Infrastructure migrations (WAL markdown→JSONL, worktree operations) are the highest-risk moments for the session continuity system. The user's entire workflow depends on reliable state persistence, so any format change or git operation that touches the persistence layer can cascade into lost work. The worktree-lost-changes and wrong-org-push incidents both stem from acting on stale assumptions about infrastructure state.

**Rule:** Before any operation that touches session-persistence infrastructure (WAL files, checkpoint formats, worktree switches), snapshot current state to a temp backup first. Treat persistence-layer changes as 'large' on the testing scale — dry-run with 2-3 items before full migration.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.74)
> The vision-loop pattern for desktop automation and the iterative UI refinement pattern share the same epistemology: render-before-judge. The user's distrust of unverified values (data hallucination) extends to unverified visuals (UI changes claimed complete without screenshot). Both are instances of 'don't claim state you haven't observed'.

**Rule:** Unify render-before-judge across all output modalities: data values must be traced to source, UI changes must be screenshot-verified, desktop actions must use the vision loop. The common principle is: never assert output state without observation.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5, 1e5df293-bb35-4b57-b67e-d2640b80c314_

---
### Insight (conf=0.60)
> Sessions with 20-100+ tool calls per turn and multiple compaction cycles are operating as de facto batch jobs, not interactive conversations. The catchup/core-dump cycle is functioning as a poor man's job scheduler with manual checkpointing. This workflow would benefit from automatic checkpointing tied to tool-call count rather than manual /core-dump invocations.

**Rule:** Auto-checkpoint at tool-call thresholds (every 30 tools) without waiting for user to invoke /core-dump. For sessions exceeding 50 tools in a single turn, treat as batch-mode and increase checkpoint frequency to every 20 tools.

_Patterns: e218ac38-3844-4295-a972-c9dc01b22d13, f1057a8d-e978-416c-b52e-7ea8fd28e770, c892fa80-f5af-4270-9e16-9225249062cc, 07e91a34-f2bd-4d49-8ac8-b81f1d0cd808_

---


## Wake Cycle — 2026-05-01 07:49 UTC

### Insight (conf=0.72)
> Context loss across session boundaries increases hallucination risk in data-heavy tasks. When state is reconstructed imperfectly via catchup/core-dump, the agent fills gaps with plausible-looking fabrications rather than admitting ignorance. The same mechanism that causes 'this session being continued from' to be frequent also creates the conditions where data hallucination is most likely — partial state reconstruction under pressure to continue seamlessly.

**Rule:** After any context restoration (catchup, compaction, session continuation), explicitly mark all prior data values as 'unverified-from-prior-context' and re-read source files before using any data value in output. Never carry forward numeric/structured data across a context boundary without re-reading the source.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, ef57d880-da40-403d-b5bc-49ae318f35bd, 881b161f-3ee0-4597-ab7b-d6c2a860613d, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.78)
> Terse continuation signals ('next', 'keep going') create a tension with scope control. The user wants autonomous execution on the current task but has also corrected scope overreach. Short messages increase autonomy on the execution axis but the agent misreads this as permission to expand scope. The fix is directional: terse = 'deeper on current path', never 'wider to adjacent paths'.

**Rule:** On terse continuation, increase execution depth (more verification, more tool calls on current task) but freeze scope to exactly what was last explicitly requested. If the current task completes mid-continuation, stop and report rather than starting adjacent work.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.55)
> Format migrations (markdown→JSONL WAL) and state-management tool changes (worktree ops) share a common failure mode: the transition period where old and new formats coexist is when data loss occurs. The worktree bug that lost unstaged changes and the WAL format migration both involve switching between two representations of the same state, with the gap between them being where things fall through.

**Rule:** During any format or tool migration, maintain read-compatibility with the old format for at least 5 sessions after the switch. Never delete/overwrite old-format files until the new format has been verified in at least 3 successful round-trips (write→read→act).

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 5287886b-6995-4b9f-a22f-38e91d2a0ce4_

---
### Insight (conf=0.68)
> The vision-loop pattern for desktop automation (screenshot→annotate→act→verify) is structurally identical to the user's iterative UI refinement workflow (render→feedback→adjust→re-render). Both are closed-loop verification cycles where skipping the 'observe actual output' step causes failures. The same principle applies: never claim a visual result without rendering it.

**Rule:** Treat all visual output tasks (UI changes, desktop automation, dashboard styling) as mandatory closed-loop cycles: act→render→verify→report. Never report a visual change as complete without a screenshot or browser verification in the same tool sequence.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.65)
> The user works on multiple complex, long-running projects simultaneously (geopolitical simulation, iDream dashboard, SvelteKit data pipeline). All share: multi-session spans, heavy state requirements, and domain-specific data integrity needs. The session continuity infrastructure isn't just a preference — it's load-bearing for a working style where projects are interleaved across days/weeks. Context switching between projects is the real unit of work, not individual sessions.

**Rule:** Core-dump files should include a 'project-id' field so catchup can filter to the relevant project. When resuming, auto-detect which project is active from CWD/git-remote before loading state, rather than replaying all recent checkpoints.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.70)
> State inference errors (wrong git owner, hallucinated data values) and context reconstruction errors share a root cause: the agent treats 'plausible given prior context' as 'verified'. After context boundaries, plausibility-based reasoning becomes dangerous because the prior context is lossy. Both git-owner inference and data-value inference fail the same way — the agent fills in what 'should' be there rather than checking.

**Rule:** After any context boundary (compaction, session start, catchup), all state assertions must be tool-verified, not memory-asserted. This includes: git remote/owner, file contents, running processes, data values. 'I remember X' is not evidence post-boundary.

_Patterns: bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 1e5df293-bb35-4b57-b67e-d2640b80c314, 00fb690c-b719-4a18-ad08-94adf937ae00_

---


## Wake Cycle — 2026-05-01 09:06 UTC

### Insight (conf=0.72)
> Context loss across session boundaries creates the same class of risk as data hallucination — when the agent loses state and reconstructs it from incomplete checkpoints, it may silently fabricate prior decisions or project state, which is indistinguishable from data hallucination to the user. The trust-killer isn't just making up CSV values; it's making up 'what we decided last session'.

**Rule:** After /catchup or session continuation, explicitly flag any reconstructed state that cannot be verified from files/git as 'inferred from checkpoint, not verified' — never present reconstructed session memory as authoritative fact.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, ef57d880-da40-403d-b5bc-49ae318f35bd, 881b161f-3ee0-4597-ab7b-d6c2a860613d, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.78)
> Terse continuation commands ('next', 'keep going') and scope-correction ('only help understand, don't implement') are in tension. The terse-input protocol assumes 'continue the current task autonomously', but the user has also corrected over-autonomous behavior. The resolution: terse = continue execution within established scope, never terse = expand scope.

**Rule:** Terse continuation signals authorize continued execution but never scope expansion. If continuing the current task would cross into a new area (new file, new feature, new system), pause and confirm even on terse input.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.61)
> The WAL markdown-to-JSONL migration and the git worktree data loss share a root cause: format/tool migrations that leave the old path partially functional create silent data corruption windows. The old markdown WAL still 'works' via fallback, and worktree switching 'works' but drops unstaged changes. Both are partially-broken states that pass casual inspection.

**Rule:** After any format migration (WAL, config, data pipeline), add a deprecation warning to the old format's read path that logs when it's hit — silent fallbacks mask incomplete migrations.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 5287886b-6995-4b9f-a22f-38e91d2a0ce4_

---
### Insight (conf=0.65)
> The user maintains multiple complex, long-running projects simultaneously (geopolitical simulation, iDream dashboard, SvelteKit data pipeline). The session continuity infrastructure isn't just a convenience — it's acting as a poor man's project-switching mechanism. The /catchup + /core-dump cycle is doing double duty: resuming within a project AND switching between projects.

**Rule:** Core dump files should include a project identifier field so /catchup can detect project switches (not just session continuations) and load the correct project context without the user manually specifying which project they're returning to.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 9fdea690-6ad5-4cb2-aacf-cd22ccde38b9, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.70)
> The desktop automation vision loop (screenshot → annotate → act → verify) and the UI iteration pattern (incremental requests until visually satisfied) are the same feedback loop at different granularities. Both require visual verification before claiming done, and both fail when the agent skips the verify step. The validated desktop automation pattern could be generalized: any UI change should follow render → verify → report, not edit → report.

**Rule:** For any UI/frontend change, take a screenshot after applying changes and before reporting completion — treat 'screenshot verify' as mandatory, not optional, matching the desktop automation discipline.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.68)
> Sessions with 20-100+ tool calls between checkpoints are operating in a danger zone where any single compaction could lose critical decision context. The 'verify owner/org before pushing' mistake pattern is a symptom: high-tool-count sessions accumulate implicit assumptions that don't survive compaction. The checkpoint interval should scale inversely with tool-call rate, not be fixed at ~30 actions.

**Rule:** When tool-call rate exceeds 10 tools per turn, halve the checkpoint interval (checkpoint every ~15 actions instead of ~30). High-velocity sessions lose more context per compaction.

_Patterns: e218ac38-3844-4295-a972-c9dc01b22d13, f1057a8d-e978-416c-b52e-7ea8fd28e770, c892fa80-f5af-4270-9e16-9225249062cc, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---


## Wake Cycle — 2026-05-01 13:33 UTC

### Insight (conf=0.72)
> Context loss across session boundaries and data hallucination share a root cause: the system operating on stale or absent ground truth. WAL migration to JSONL (machine-queryable) reduced context-loss errors the same way source-tracing would reduce hallucinated data values — both substitute verifiable records for reconstructed memory.

**Rule:** After any context boundary (compaction, session resume, catchup), treat all previously-held state as unverified — re-read files and re-query APIs before producing output that depends on them. Apply the same 'no inference without source' discipline to session state as to data pipelines.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 1e5df293-bb35-4b57-b67e-d2640b80c314_

---
### Insight (conf=0.68)
> Fix-attempt thrashing and context-limit hits are correlated: repeated failed fixes consume context budget faster, which triggers compaction, which loses the diagnostic state needed to find root cause — a vicious cycle. Mid-milestone core-dumps break this cycle by preserving diagnostic state before context pressure forces lossy compaction.

**Rule:** After 3 consecutive failed fix attempts on the same issue, immediately write a core-dump checkpoint capturing the diagnostic state before continuing. This preserves root-cause evidence even if compaction occurs.

_Patterns: 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, 5c3499d0-aef9-4924-b559-e15bf88068ed, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.82)
> Terse continuation signals and scope-ceiling corrections are two sides of the same coin: the user wants maximum execution velocity within tight scope. Short messages mean 'keep going on exactly what you're doing' — not 'expand scope autonomously.' The agent misreads terse approval as broad latitude.

**Rule:** Terse user continuations ('next', 'keep going', 'more') authorize continued execution on the current task only. Never interpret them as approval to expand scope, refactor adjacent code, or start new work streams.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, edaeaf8c-9b6e-4652-b777-ccedba905520, ff7b37a5-17ae-466e-b55e-585866af824b_

---
### Insight (conf=0.75)
> Desktop automation's vision-loop (screenshot → annotate → verify) and iterative UI refinement share the same feedback structure: observe-before-acting loops where skipping observation causes cascading errors. The user's 'good but...' iteration pattern IS a human vision loop — the agent should mirror it by front-loading screenshot verification.

**Rule:** For any UI change, take a screenshot and verify visually BEFORE reporting completion. The user's iterative refinement pattern means reporting 'done' without visual verification will always generate a correction round.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.85)
> Hallucinated data, fabricated API results, and credential leaks form a trust-destruction triad — all involve the agent producing output that looks correct but has no ground truth. The user's visceral reaction ('serious trust killer') suggests these failures damage the relationship disproportionately to their technical severity, because they undermine the user's ability to trust ANY agent output.

**Rule:** When producing structured data, API results, or any output the user will act on without independent verification: if you cannot trace a value to a specific source (file, API response, tool output), emit an explicit '[UNVERIFIED]' marker rather than a plausible-looking value. Never fill gaps with inference.

_Patterns: 10b7a87a-5217-44e1-be13-e9acb9c24ae8, ef57d880-da40-403d-b5bc-49ae318f35bd, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.78)
> Worktree data loss, wrong-org pushes, and credential leaks are all 'assumed-state' errors — the agent acted on a mental model of the environment without verifying it. All three are prevented by the same discipline: read-before-write at system boundaries (git state, remote config, file contents).

**Rule:** Before any git operation that moves or exposes data (worktree switch, push, branch create), run the verification triad (status + log + diff) AND confirm the target remote/org. Treat the cost of one extra read as always lower than the cost of one wrong write.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.70)
> The user works on multiple large, architecturally complex projects simultaneously (game-theory simulation, SvelteKit data pipeline, iDream dashboard). This explains the heavy investment in session-continuity tooling — it's not just about long sessions, it's about context-switching between projects that each require deep state.

**Rule:** At session start, identify which project is active before loading context. Core-dumps and catchup files should include a project identifier so cross-project resume doesn't accidentally mix state from different codebases.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, b76b7252-944d-49f8-bb01-fa76c140a694, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.65)
> The Slack MCP repeated-failure pattern is a specific instance of the general fix-thrashing anti-pattern: multiple install/diagnose/reconnect cycles without identifying root cause. External service integrations are especially prone to this because failures are often environmental (auth, network, version) rather than code bugs.

**Rule:** For external service integration failures (MCP servers, API connections): after 2 failed attempts, stop and document what was tried and what error was observed. Present findings to user rather than continuing to retry — the root cause is likely environmental and requires user-side action.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.90)
> Four independent pattern observations all describe the same WAL markdown→JSONL migration event. This redundancy itself is a signal: the pattern-extraction system lacks deduplication, which will cause the pattern store to bloat with near-identical entries over time, reducing signal-to-noise ratio.

**Rule:** Before inserting a new pattern, check existing patterns for semantic overlap (same event/decision described from different angles). Merge into the highest-confidence existing entry rather than creating duplicates. Apply the same dedup to the session-continuity cluster (12+ near-identical patterns about /catchup and /core-dump).

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 846615fc-eeb8-4a44-bf0a-bf06c723fde8_

---


## Wake Cycle — 2026-05-01 16:52 UTC

### Insight (conf=0.72)
> The user's terse continuation signals and scope-ceiling corrections are two sides of the same preference: maximum execution velocity within strictly bounded scope — short commands mean 'go fast' not 'go wide'.

**Rule:** Always interpret terse continuation commands as 'continue the current narrow task faster' never as implicit permission to expand scope to adjacent improvements.

**Evidence:**
- _Pattern_: "User explicitly corrected agent scope: agent should only help understand codebase, not autonomously implement changes beyond what was reques…"
- _Pattern_: "User frequently uses single-word or very short continuation commands ('started', 'looks', 'ahead', 'next', 'three') — treat as autonomous-co…"
- _Sessions_ (59): beb55aa4, bbdd8d86, afdad2b6, +56 more

---


## Wake Cycle — 2026-05-01 21:48 UTC

### Insight (conf=0.72)
> The 'never hallucinate data' rule and the 'never guess coordinates' rule are the same underlying pattern: when operating on structured external state (data rows or pixel coordinates), inference without ground truth produces cascading failures. The vision loop's validate-before-act discipline should be generalized to all data transformation pipelines — read-verify-transform-verify, never transform-assume.

**Rule:** Before outputting any derived value (data cell, coordinate, inferred field), require a traceable citation to source — screenshot annotation for UI, source column reference for data. No citation = flag as unverified.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.55)
> The WAL markdown-to-JSONL migration succeeded because it made state machine-queryable rather than human-readable. The 'fix thrashing' anti-pattern persists partly because error state is not machine-queryable — failures are described in conversation prose, not structured data. A structured error log (JSONL of fix attempts with hypothesis/result) would let the agent detect its own thrash loops programmatically.

**Rule:** After 2 failed fix attempts on the same target, write a JSONL entry {target, hypothesis, result, timestamp} to a scratch file. Before attempt 3, read all entries and require a novel hypothesis not yet tried.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26_

---
### Insight (conf=0.68)
> The user's terse continuation style ('next', 'ahead') and iterative UI refinement ('better', 'revert colors') are the same interaction mode: rapid micro-feedback loops where the user acts as a real-time evaluator. These sessions burn context fastest because each micro-turn adds overhead. Optimizing for this pattern means minimizing per-turn context consumption — shorter responses, fewer tool preambles, batch screenshot+change in one turn.

**Rule:** In iterative UI refinement mode (3+ consecutive short user messages about visual changes), compress response to: apply change + screenshot + one-line summary. No insight boxes, no explanations unless asked.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.60)
> Credentials leaking to files, worktree operations losing unstaged changes, and wrong-org pushes are all 'state bleed' failures — sensitive or important state from one context leaking into or being destroyed by another. The root cause is the same: operations that cross boundaries (session/worktree/org) don't have a pre-flight state inventory. A unified 'boundary crossing checklist' would catch all three.

**Rule:** Before any boundary-crossing operation (worktree switch, org-scoped push, session handoff), run a 3-point check: (1) uncommitted/unstaged changes exist? (2) sensitive values in memory/clipboard? (3) target matches expectation (org, branch, remote)?

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.50)
> Fire-and-forget task notifications, persistent Slack MCP failures, and high-tool-count sessions are connected: background/async operations generate noise that consumes context without advancing the task. The Slack MCP failures especially — repeated reconnection attempts across sessions consume tools and context for zero value. Async failures should be logged once and suppressed until the user explicitly re-engages.

**Rule:** If an MCP connection or background task fails twice in the same session, log it to runtime-notes and stop retrying. Surface it only when the user explicitly invokes that tool again.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, 21f20909-472b-4445-9477-c0605accbe55, f1057a8d-e978-416c-b52e-7ea8fd28e770_

---
### Insight (conf=0.62)
> Both major projects (SvelteKit parts pipeline and iDream dashboard) involve structured data flowing through transforms into a UI. The data hallucination patterns all emerged from the SvelteKit pipeline work, but the iDream dashboard (MongoDB + Anthropic API) has the same risk profile — LLM-generated dream analysis could silently fabricate interpretations. The anti-hallucination discipline from the parts pipeline should be explicitly ported to any LLM-output-to-UI pipeline.

**Rule:** When an LLM generates content that will be stored in a database or displayed as factual data (not creative text), wrap it in a verification step: source-check any specific claims (dates, names, quantities) against input before persisting.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, c70ae766-c39a-442a-a15d-fbe84d854e0c, 392f40af-8bf6-463f-a558-c5b68076c729, 6fb0360d-b78d-4d97-ab65-325d2338ee68_

---
### Insight (conf=0.58)
> The user's primary state management is /catchup + /core-dump, not git. But the dev server (localhost:5173) represents runtime state that neither mechanism captures — a core dump won't record that the server is running, what port it's on, or whether it's stale. Session continuity tools have a blind spot for process state.

**Rule:** Include active process state (pm2 list, listening ports, running dev servers) in /core-dump output alongside file and git state.

_Patterns: 584e7697-e747-48e6-9cd8-274ccffd99d8, 694c5087-f6dc-4dd0-88dc-8645a8dda00f, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a_

---


## Wake Cycle — 2026-05-01 22:50 UTC

### Insight (conf=0.70)
> Data hallucination and context hallucination are the same failure mode at different layers. When the agent fabricates data values, it's the same cognitive pattern as when it fabricates session state after a context boundary — both are gap-filling under uncertainty. The user's extreme sensitivity to data hallucination may stem from experiencing context hallucination (agent confidently acting on stale/wrong state after compaction) regularly.

**Rule:** After any context boundary (compaction, catchup, session start), treat all prior state claims as 'unverified data' — apply the same 'traceable to source' standard used for data pipelines. Re-read files before acting, just as you'd re-read source data before outputting values.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 881b161f-3ee0-4597-ab7b-d6c2a860613d_

---
### Insight (conf=0.65)
> The user's iterative UI refinement workflow ('better', 'good but...') and the agent's fix-thrashing pattern are adversarial mirrors. The user gives incremental aesthetic feedback expecting convergence; the agent sometimes enters a loop of non-converging fix attempts. The difference is that the user has a target mental image and each iteration narrows the gap, while the agent lacks that target and may oscillate. Screenshot verification before reporting done is the bridge.

**Rule:** During iterative UI refinement, after 2 rounds of similar feedback on the same element, ask the user for a concrete target value (color hex, pixel size, reference screenshot) rather than continuing to guess-and-check.

_Patterns: 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.75)
> The user's terse continuation style ('next', 'ahead', 'three') and their reliance on high-tool-count sessions (20-80 tools per turn) suggest they treat the agent as an execution engine with a command interface, not a conversational partner. The /core-dump at milestones pattern functions like transaction savepoints in a database — the user is running long transactions against the codebase and needs rollback points.

**Rule:** In sessions with terse-command patterns and tool counts exceeding 30, auto-checkpoint every 20 tool calls without being asked — the user is in 'transaction mode' and expects savepoints.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, e218ac38-3844-4295-a972-c9dc01b22d13, c892fa80-f5af-4270-9e16-9225249062cc_

---
### Insight (conf=0.80)
> The vision-loop pattern for desktop automation (screenshot → annotate → read → act → verify) is structurally identical to the data integrity rule (source → trace → output → verify). Both enforce a 'no action without grounding' principle. The git owner-verification rule is the same pattern applied to repository operations. This is a single meta-pattern: never act on inferred state when observed state is available.

**Rule:** Unify under a single 'ground before act' principle: for any domain (data, UI, git, desktop), if observation is possible before action, observe. The cost of one extra read/screenshot/status-check is always less than the cost of acting on stale inference.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 1e5df293-bb35-4b57-b67e-d2640b80c314, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.60)
> Credential leaks, worktree data loss, and data fabrication are all instances of 'irreversible trust damage from a single careless action'. The user's infrastructure (hooks blocking rm, safe-delete, git verification triads) is a trust-preservation system. Each new rule was likely born from a specific incident. The pattern suggests the user would benefit from a pre-action severity classifier: if the action could cause irreversible trust damage, add a verification step regardless of how trivial it seems.

**Rule:** Maintain a mental 'trust-damage severity' rating for each action class. Anything touching credentials, data output values, or uncommitted work gets mandatory pre-action verification regardless of context.

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, 5287886b-6995-4b9f-a22f-38e91d2a0ce4, ef57d880-da40-403d-b5bc-49ae318f35bd_

---
### Insight (conf=0.55)
> The user runs three very different projects (iDream dashboard, SvelteKit data pipeline, game theory simulation) but applies the same session-continuity infrastructure to all of them. This suggests the continuity tooling is the user's actual 'product' — the projects are the workload, but the meta-tooling (WAL, catchup, core-dump, memory) is what they're iterating on most actively. Improvements to session infrastructure have outsized impact across all three domains.

**Rule:** When the user works on session-continuity infrastructure (WAL format, catchup, core-dump), treat it as high-priority work that affects all projects — test changes against multiple project contexts, not just the current one.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---


## Wake Cycle — 2026-05-02 01:54 UTC

### Insight (conf=0.72)
> The game theory / geopolitical simulation project's multi-agent architecture mirrors the session continuity problem itself — both are distributed state machines that must reconstruct coherent world-state from partial observations across time boundaries. The WAL→JSONL migration is essentially the same design pattern as a simulation event log: append-only, machine-queryable, replayable. The user may be unconsciously applying simulation architecture patterns to their own dev workflow.

**Rule:** When designing state persistence for either the simulation project or the dev workflow, cross-pollinate: simulation replay/checkpoint patterns can improve core-dump fidelity, and WAL lessons (JSONL > markdown) should inform the simulation's own event logging format.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 881b161f-3ee0-4597-ab7b-d6c2a860613d, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---
### Insight (conf=0.81)
> Context limit truncation and data hallucination share the same root cause: the agent operates on incomplete information and fills gaps with plausible-looking fabrications. When a session hits context limits and continues via handoff, the reconstructed context is itself a 'data pipeline' vulnerable to the same hallucination failure mode — the agent may confabulate session state it no longer has access to, just as it confabulates data values it never read.

**Rule:** After any context reconstruction (catchup, compaction, session handoff), treat all recalled state as 'unverified source data' — re-read files and re-check git status before acting, applying the same no-hallucination discipline used for data pipelines. Flag any state claim from memory that cannot be verified with a tool call.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.75)
> The user's terse continuation style ('next', 'ahead', 'three') and iterative UI refinement ('better', 'good but...') are the same interaction pattern at different granularities — rapid feedback loops where the user steers by small corrections rather than upfront specification. The fix-thrash anti-pattern emerges when the agent misinterprets this steering as dissatisfaction and starts making larger changes, when the user actually wants minimal delta adjustments.

**Rule:** When the user gives terse iterative feedback on UI or behavior, make the smallest possible change that addresses the literal feedback. Do not escalate scope ('while I'm here...') or assume the small correction implies broader dissatisfaction. One adjustment per terse signal.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 92a767af-37ad-4b83-84af-684fd98948b5, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.78)
> The vision-loop pattern for desktop automation (screenshot → verify → act) and the dashboard aesthetics iteration pattern share a principle: the agent must ground its understanding in rendered reality, not internal models. Data hallucination, coordinate guessing, and 'looks good' claims without screenshots are all instances of the same failure: acting on an internal representation that has diverged from ground truth.

**Rule:** Before reporting any visual, spatial, or data-dependent result as 'done', the agent must have a verification artifact (screenshot, rendered output, actual API response) from the current state — not from memory or inference. 'I believe it looks correct' is never sufficient; 'here is what it looks like' is required.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, ef57d880-da40-403d-b5bc-49ae318f35bd_

---
### Insight (conf=0.83)
> Credentials leaking to files, wrong repo owner inference, and worktree data loss are all 'stale context side-effects' — the agent carried forward an assumption from earlier in the session (or a prior session) and applied it to a changed environment. These aren't three separate bugs; they're one bug class: side-effects executed against cached rather than current state.

**Rule:** Before any side-effect that touches an external system (git push, file write outside project, API call with auth), re-verify the target identity (repo owner, file path, endpoint) with a fresh read. Never reuse a value from earlier in the session for an irreversible external action.

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5287886b-6995-4b9f-a22f-38e91d2a0ce4_

---
### Insight (conf=0.65)
> Fire-and-forget task notifications, Slack MCP failures, and heavy session continuations are symptoms of the same architectural tension: the workflow demands asynchronous, long-lived coordination channels, but the tools available are synchronous and session-scoped. The user is building ad-hoc async infrastructure (WAL, core-dump, catchup) because the native primitives don't support their actual work pattern — which is closer to a message queue than a REPL.

**Rule:** Invest in making the async primitives (WAL, scheduled agents, cron routines) more robust rather than adding more synchronous workarounds. When Slack or other external async channels fail, fall back to the local WAL as the coordination bus rather than retrying the external service.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, 21f20909-472b-4445-9477-c0605accbe55, 00fb690c-b719-4a18-ad08-94adf937ae00_

---
### Insight (conf=0.58)
> The dream-tracking dashboard (iDream) with MongoDB backend is itself a data pipeline that ingests unstructured user input (dreams) and must avoid the same hallucination failure mode seen in the eBay/JEGS parts data pipeline. Dreams are inherently ambiguous — the temptation to 'clean up' or 'normalize' dream descriptions risks the same trust violation as fabricating parts data. The no-hallucination rule should apply to user-generated content transformations too.

**Rule:** In the iDream dashboard or any project handling subjective/unstructured user content, apply the same no-fabrication rule as for parts data: never normalize, summarize, or 'improve' user-entered content unless explicitly requested. Display verbatim; transform only on demand.

_Patterns: 392f40af-8bf6-463f-a558-c5b68076c729, 6fb0360d-b78d-4d97-ab65-325d2338ee68, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.70)
> The 'core-dump at milestones, not just at end' pattern and the 'root-cause before fix' anti-pattern are connected through a concept of 'known-good states'. Core dumps create restore points; fix-thrashing happens when there's no restore point to fall back to. The agent thrashes because it can't cheaply revert to a known-good state and try a different approach — it only has the current broken state.

**Rule:** Before attempting a fix that could thrash (3+ edits to the same region), create a lightweight checkpoint (git stash or core-dump mini). If the third attempt fails, restore the checkpoint and re-analyze from clean state rather than continuing to patch.

_Patterns: e218ac38-3844-4295-a972-c9dc01b22d13, f1b15033-a4e3-4a70-84fa-4de726a42926, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---


## Wake Cycle — 2026-05-02 02:56 UTC

### Insight (conf=0.72)
> The game theory simulation project's complexity is a primary driver of context exhaustion — the project's multi-agent architecture mirrors the multi-session agent architecture needed to work on it, creating a fractal problem where the tool (Claude) and the domain (multi-agent simulation) share the same scaling bottleneck: state management across boundaries.

**Rule:** For projects with inherently stateful multi-agent architectures, front-load a domain-state summary in the WAL checkpoint (not just tool/action state) — capture the simulation's current phase, active agents, and decision tree position alongside the development task state.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---
### Insight (conf=0.81)
> The 'never hallucinate data' rule and the 'vision loop with annotation' rule are the same principle applied to different modalities — both say 'ground every output in an observable source, never infer from plausible patterns.' The desktop automation vision loop is the spatial version of the data pipeline traceability rule.

**Rule:** Unify under a single 'ground-truth-first' principle: before producing any output value (data cell, coordinate, API result), cite the exact source artifact (source column, screenshot region, API response field). If no citation exists, flag as inferred rather than presenting as fact.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.78)
> Fix-thrashing and context exhaustion are mutually reinforcing: hitting context limits mid-debug forces a lossy handoff, which loses the root-cause hypothesis, which causes the next session to start from scratch and thrash again. The /core-dump cadence rule (at milestones, not just end) is actually an anti-thrash mechanism disguised as a continuity tool.

**Rule:** When a fix attempt fails twice on the same issue, trigger an immediate mini core-dump of the current hypothesis and eliminated causes before the third attempt — this preserves debugging state even if context compaction happens mid-investigation.

_Patterns: 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, 5c3499d0-aef9-4924-b559-e15bf88068ed, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.69)
> The terse-continuation pattern ('next', 'ahead') and the iterative UI refinement pattern ('better', 'good but...') are two speeds of the same feedback loop. Terse commands signal 'proceed on current vector', iterative UI feedback signals 'adjust vector slightly.' Both require the agent to maintain a strong internal model of the user's intent trajectory rather than treating each message as independent.

**Rule:** Maintain an explicit 'intent vector' in working memory during iterative sessions — when the user gives terse or incremental feedback, apply it as a delta to the stored vector rather than re-inferring intent from scratch each turn.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.85)
> Credentials leaking, data hallucination, and wrong-org pushes are all instances of the same failure mode: the agent treating high-confidence internal state as ground truth without verification at the boundary. Credentials 'remembered' get written; plausible data values get fabricated; org names get assumed. All three are 'confident extrapolation without boundary check' errors.

**Rule:** Before any action that crosses a trust boundary (writing to file, pushing to remote, producing output data), apply a 'boundary check': is every value in this action directly sourced from a read/fetch in this session, or am I relying on recalled/inferred state? If the latter, re-verify.

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, ef57d880-da40-403d-b5bc-49ae318f35bd, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.67)
> Worktree data loss, Slack MCP failures, and fire-and-forget task notifications are all symptoms of 'side-channel state' — operations that happen outside the primary conversation flow and whose success/failure isn't verified in the main loop. The system has strong state management for the primary conversation (WAL, checkpoints) but weak observability for parallel/background operations.

**Rule:** Any operation that modifies state outside the main conversation (worktree switch, MCP connection, background task) must produce a verification artifact back in the main flow — a git status after worktree switch, a connection-test after MCP setup, a result-check after async task completion.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, 21f20909-472b-4445-9477-c0605accbe55, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---


## Wake Cycle — 2026-05-02 03:57 UTC

### Insight (conf=0.55)
> The game theory / geopolitical simulation project's multi-agent architecture mirrors the session continuity problem itself — both are state-management challenges across context boundaries. The WAL migration to JSONL for machine-queryability is essentially the same pattern as a simulation engine needing serializable game state for save/load. The project domain expertise may have directly influenced the sophistication of the session continuity tooling.

**Rule:** When building state-persistence features for any project, cross-reference the WAL/checkpoint architecture — the patterns are isomorphic and improvements to one should be tested against the other.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---
### Insight (conf=0.72)
> Data hallucination and fix-thrashing are the same failure mode at different abstraction levels: both involve generating plausible-looking outputs without grounding in actual state. Hallucinating data values is 'generating without reading the source'; repeated fix attempts without root-cause analysis is 'generating patches without reading the error'. The user's extreme sensitivity to hallucinated data suggests a general principle: verify-then-generate, never generate-then-rationalize.

**Rule:** Before producing any output that claims to represent state (data values, fix patches, or status reports), the agent must have a direct tool-read citation for every claim. If no read was performed, the output must be flagged as 'unverified'.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, ef57d880-da40-403d-b5bc-49ae318f35bd, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.78)
> The user's terse continuation style ('next', 'ahead', 'three') and iterative UI refinement ('better', 'good but...') are two expressions of the same interaction pattern: high-bandwidth, low-ceremony feedback loops. The user treats the agent like a live collaborator in a pair-programming session, not a request-response API. This means latency and verbosity are the primary friction points, not ambiguity.

**Rule:** In iterative refinement loops (especially UI), minimize response length to under 2 sentences between actions. The user's next message IS the feedback — don't ask for it.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.65)
> The vision loop pattern (screenshot → annotate → read → act → verify) for desktop automation is the same epistemological discipline as 'no hallucinated data values' — both require grounding every action in observed reality rather than inferred state. The fix-thrashing anti-pattern is what happens when this discipline breaks down. All three patterns converge on: observe → verify → act → observe again.

**Rule:** Generalize the vision-loop pattern to all stateful operations: read-current-state → plan-action → execute → verify-new-state. Skip any step and you risk either hallucination (skipping read) or thrashing (skipping verify).

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 1e5df293-bb35-4b57-b67e-d2640b80c314, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.60)
> Git worktree data loss, credential leakage risk, and wrong-org pushes are all 'context bleed' failures — state from one context (branch, session, org) leaking into another. The user's heavy multi-session workflow amplifies this risk because there are more context boundaries to cross. The WAL/checkpoint system protects application state but git state and credential state remain vulnerable at transitions.

**Rule:** At every session boundary (catchup, core-dump, worktree switch), run a 'context hygiene check': verify git remote/branch, check for unstaged changes, and confirm no credentials are staged. Make this a checklist, not a judgment call.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, afe8a2d8-17b3-42bc-973d-eac449588f9b, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.50)
> The Slack MCP repeated connection failures and the fix-thrashing anti-pattern are the same bug: retrying a broken integration without diagnosing why it fails. The task-notification fire-and-forget pattern suggests the system already has a model for 'signals that don't need responses' — applying this to known-broken integrations would prevent wasted cycles. Some tool failures should be accepted as permanent rather than retried.

**Rule:** After 3 failed attempts at the same MCP/integration connection within a session, mark it as 'session-broken' and stop retrying. Log the failure for the user to address outside the session rather than consuming tool calls on it.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.58)
> The WAL format migration (markdown → JSONL for machine-queryability) and the data pipeline integrity rules (only source-traceable values) share a deep principle: structured data must be machine-parseable and provenance-trackable. The WAL migration succeeded because JSONL makes every entry independently verifiable — the same property the user demands from data pipelines. This suggests the user values 'auditability' as a first-class architectural property.

**Rule:** When designing any data format or pipeline output, include provenance metadata (source file, transform step, timestamp) at the record level, not just the file level. If a value can't cite its source, it should be flagged.

_Patterns: 392f40af-8bf6-463f-a558-c5b68076c729, 6fb0360d-b78d-4d97-ab65-325d2338ee68, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26_

---


## Wake Cycle — 2026-05-02 04:58 UTC

### Insight (conf=0.85)
> The session continuity problem scales with project complexity — the game theory simulation and iDream dashboard (both large, stateful, multi-session projects) are the primary drivers of context exhaustion. Simpler tasks rarely hit context limits. The continuity infrastructure is essentially compensating for a mismatch between project cognitive load and single-session context capacity.

**Rule:** For projects exceeding ~50 tool calls per logical task, auto-checkpoint every 25 tools AND proactively split work into sub-tasks that fit within a single context window, rather than relying on post-hoc recovery.

_Patterns: 881b161f-3ee0-4597-ab7b-d6c2a860613d, 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, e181d5f7-4435-4c76-a1a4-82f3536aac19_

---
### Insight (conf=0.78)
> Data hallucination and fix-thrashing share a common root: the agent acts on incomplete information rather than pausing to verify. Hallucinated data values are 'guessing forward' in the data domain; repeated fix attempts without root-cause analysis are 'guessing forward' in the debugging domain. Both stem from a bias toward action over verification.

**Rule:** Before outputting any derived/inferred value OR attempting a second fix for the same issue, the agent must cite the exact source (line number, API response field, error message) that justifies the output. No citation = no action.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 392f40af-8bf6-463f-a558-c5b68076c729, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.72)
> The WAL markdown→JSONL migration and the vision-loop validation pattern reflect the same meta-principle: machine-parseable structured formats beat human-readable prose for agent-to-agent communication. Markdown WAL failed because agents couldn't reliably parse it; coordinate guessing in desktop automation failed because unstructured screenshots aren't machine-addressable. Both were solved by adding structured intermediaries (JSONL, annotation overlays).

**Rule:** Any agent-consumed artifact (checkpoints, state files, automation targets) should be structured-first (JSON/JSONL), with human-readable rendering as a view layer, not the source of truth.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.68)
> The terse-command pattern and iterative-UI-refinement pattern are two faces of the same interaction style: the user treats the agent as a real-time collaborator with shared context, issuing incremental nudges rather than complete specifications. This works well for UI work (where the visual feedback loop is tight) but creates fragility across context boundaries (where the shared context is lost).

**Rule:** During iterative UI refinement sessions, auto-snapshot the current design intent (what the user has approved so far) every 5 incremental changes, so post-compaction recovery doesn't require re-negotiating aesthetic choices.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.65)
> Credentials leaking, data fabrication, and wrong-repo pushes are all 'contamination across trust boundaries' — information from one context (session memory, prior assumptions, test data) bleeding into another context (files, repos, output datasets) where it doesn't belong. The common fix is boundary verification: check the target before writing.

**Rule:** Before any write that crosses a trust boundary (credential→file, inference→dataset, local→remote), verify the target identity and that the content is authorized for that target. Treat cross-boundary writes as requiring the same confirmation discipline as git push.

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, ef57d880-da40-403d-b5bc-49ae318f35bd, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.52)
> The worktree data-loss incident and the fix-thrashing pattern both occur in the context of the long-running SvelteKit project — suggesting that larger, more complex projects create more opportunities for state-management errors. The cognitive load of tracking unstaged changes, active branches, and running processes increases non-linearly with project size, making verification shortcuts more tempting and more dangerous.

**Rule:** In projects with >10 active files modified, run 'git stash list && git status --short' before ANY branch or worktree operation, and abort if unstaged changes exist in the working tree.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.60)
> The user maintains multiple large concurrent projects (iDream dashboard, SvelteKit data pipeline, game theory simulation) — each with its own tech stack, running services, and session history. Context switches between these projects are a hidden multiplier on the continuity problem: not just resuming within a project, but correctly identifying WHICH project's context to load.

**Rule:** At session start, if CWD doesn't clearly identify the project, resolve the active project from the WAL's last session_start entry before loading any checkpoint — wrong-project context is worse than no context.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---


## Wake Cycle — 2026-05-02 05:59 UTC

### Insight (conf=0.72)
> The session continuity problem is not a tooling gap but an architectural mismatch: the user's projects (game theory simulations, multi-widget dashboards) have inherently larger cognitive state than a single context window. The real fix is not better checkpointing but decomposing work into context-window-sized autonomous units that don't need handoff.

**Rule:** For tasks estimated to exceed 60 tool calls, break into sub-agents with explicit input/output contracts before starting — don't rely on mid-session checkpointing as the primary continuity mechanism.

_Patterns: 881b161f-3ee0-4597-ab7b-d6c2a860613d, 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, e181d5f7-4435-4c76-a1a4-82f3536aac19_

---
### Insight (conf=0.82)
> Data hallucination and fix-thrashing share a common root cause: the agent acts on an internal model of state rather than re-reading ground truth. Hallucinated data values are 'hallucinated state' applied to data; fix-thrashing is 'hallucinated understanding' applied to code. Both are prevented by the same discipline — re-read before acting.

**Rule:** Before writing any value into a data pipeline output OR attempting a second fix on the same code block, re-read the source (file, API response, error log) — never operate from remembered state.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 392f40af-8bf6-463f-a558-c5b68076c729, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.65)
> The WAL migration from markdown to JSONL and the vision-loop validation pattern share a design principle: machine-parseable intermediate representations outperform human-readable ones when the consumer is an agent, not a human. The same principle should apply to core-dump format — structured JSON checkpoints would recover faster than prose.

**Rule:** Core dump output should include a machine-parseable JSON block (current files, git state, active tasks, blockers) alongside the human-readable summary, enabling faster automated /catchup recovery.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.70)
> The user's terse continuation style and iterative UI refinement pattern form a tight feedback loop that mimics a real-time REPL — each short message is a 'next tick' in a synchronous visual design session. The agent should treat consecutive terse UI messages as a single design transaction, batching screenshots and minimizing ceremony between iterations.

**Rule:** During iterative UI refinement (3+ consecutive terse corrections), skip status summaries between iterations — apply change, screenshot, present, wait. Treat the sequence as one logical unit for commit purposes.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.68)
> Credential leaks, data fabrication, and wrong-org pushes are all instances of 'state bleed' — information from one context (a login form, a data pattern, a prior session's repo) leaking into an inappropriate output (a committed file, a dataset, a git remote). They share a mitigation: treat cross-boundary writes as tainted until explicitly verified.

**Rule:** Before any write that crosses a trust boundary (file→git, memory→data-output, session-state→remote), verify the value's provenance — is it from the current source, or remembered/inferred from a different context?

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, ef57d880-da40-403d-b5bc-49ae318f35bd, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.75)
> Worktree data loss and context-window exhaustion are both consequences of 'long transactions' — operations that hold uncommitted state for too long. Git worktrees lose unstaged changes on switch; context windows lose cognitive state on compaction. The shared fix is smaller, more frequent commits of both code state and cognitive state.

**Rule:** Treat git commits and cognitive checkpoints as the same discipline: if you wouldn't work 20 minutes without committing code, don't work 20 tool-calls without a WAL checkpoint.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, 5c3499d0-aef9-4924-b559-e15bf88068ed, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.78)
> The recurring Slack MCP failure and the fix-thrashing anti-pattern are the same behavior at different scales: repeated attempts to make something work without stopping to diagnose why it fails. Slack MCP deserves a 'known broken — don't retry without new information' flag rather than fresh attempts each session.

**Rule:** Maintain a 'known-broken' registry in memory for integrations that have failed 3+ times across sessions. On encounter, surface the history and ask for new information before retrying.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.60)
> The user's three major projects (game theory simulation, SvelteKit data pipeline, iDream dashboard) all share a pattern: complex stateful systems with many interacting components. This isn't coincidental — the user thinks in systems, and the session continuity tooling is itself a system they've designed. The agent should treat the user's meta-tooling (WAL, checkpoints, skills) with the same engineering rigor as production code.

**Rule:** When modifying session infrastructure (WAL format, checkpoint scripts, skill definitions), apply the same testing discipline as production code changes — verify with a round-trip test, not just a write.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, b76b7252-944d-49f8-bb01-fa76c140a694, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---


## Wake Cycle — 2026-05-02 07:01 UTC

### Insight (conf=0.72)
> Data hallucination and fix-thrashing share a common root cause: the agent acting without verifiable ground truth. Hallucinating data values is 'making up facts' in the data domain; thrashing on fixes is 'making up hypotheses' in the debugging domain. Both are symptoms of proceeding without anchoring to observable state first.

**Rule:** Before any generative act (filling data, proposing a fix, inferring a value), require an explicit 'anchor step' — cite the source line, file, or observation that justifies the output. If no anchor exists, stop and gather one rather than proceeding speculatively.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 392f40af-8bf6-463f-a558-c5b68076c729, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.60)
> The user's terse continuation style ('next', 'ahead', 'better') combined with iterative UI refinement creates an interaction pattern resembling a REPL — short input, immediate visual feedback, adjust, repeat. The session continuity overhead (core-dump/catchup) is the cost of this REPL breaking across context windows. Optimizing for faster checkpoint writes and smaller state diffs would reduce the tax on this natural workflow.

**Rule:** For iterative UI refinement sessions, write incremental checkpoint diffs (delta from last checkpoint) rather than full state dumps, reducing both write time and catchup parse time for the rapid feedback loop.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.68)
> The WAL markdown-to-JSONL migration and the desktop automation vision-loop pattern both reflect the same meta-principle: machine-readable intermediate representations outperform human-readable ones when the consumer is an agent, not a person. Markdown WAL failed because agents parsed it poorly; coordinate guessing failed because agents skipped the structured annotation step. Both were fixed by inserting a machine-queryable layer.

**Rule:** When designing agent-consumed artifacts (state files, intermediate outputs, automation targets), default to structured machine-readable formats (JSONL, annotated coordinates, typed schemas) even if a human-readable format feels more natural. Add human-readable views as a separate rendering layer.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.75)
> Credential leaks, data fabrication, worktree data loss, and wrong-org pushes are all instances of 'irreversible trust violations' — errors where the damage is not to the code but to the user's confidence in the agent's reliability. They share the property that a single occurrence poisons trust disproportionately to the technical severity. This cluster suggests a 'trust-critical operations' category that should have stricter pre-flight checks than merely 'risky' operations.

**Rule:** Maintain a distinct 'trust-critical' operation tier (above 'risky') for: writing credentials, generating data values, destructive git operations on non-local state, and pushing to repos. Trust-critical ops require two verification steps (source check + output check) rather than one confirmation.

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, ef57d880-da40-403d-b5bc-49ae318f35bd, 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.55)
> The user works across two data-intensive domains (iDream dashboard with MongoDB + Anthropic API, and SvelteKit eBay/JEGS data pipeline) that both involve transforming external data into structured views. The data-hallucination sensitivity likely originated in the eBay/JEGS pipeline (where source fidelity is commercial) and should be applied equally to the dream dashboard (where interpretive data could be silently fabricated). Cross-domain trust rules should be uniform.

**Rule:** Apply the 'no hallucinated values' rule uniformly across all projects, not just data-pipeline ones — any structured data display (dashboard widgets, API responses, generated reports) must trace each value to a source record.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, 6fb0360d-b78d-4d97-ab65-325d2338ee68_

---
### Insight (conf=0.62)
> The WAL/checkpoint system has become the user's primary version control for agent state — more relied upon than git for tracking 'what was the agent doing'. This is analogous to how database WALs evolved from crash recovery into the primary source of truth for replication. The implication is that WAL reliability should be treated with the same rigor as database durability guarantees: no silent data loss, guaranteed ordering, and corruption detection.

**Rule:** Treat WAL writes as durability-critical: verify the append succeeded (read back last line), never truncate without checkpointing first, and include a sequence number for corruption detection on catchup reads.

_Patterns: e218ac38-3844-4295-a972-c9dc01b22d13, 07e91a34-f2bd-4d49-8ac8-b81f1d0cd808, 694c5087-f6dc-4dd0-88dc-8645a8dda00f, 1523746a-7091-4022-b130-7e28b7f77561_

---


## Wake Cycle — 2026-05-02 08:02 UTC

### Insight (conf=0.82)
> The session continuity problem is fundamentally a consequence of project complexity — the game theory/geopolitical simulation and long-running dashboard projects generate sessions that routinely exceed context limits. The WAL migration from markdown to JSONL was an evolutionary response: as sessions grew longer, human-readable state formats became machine-unparseable at scale. This suggests that projects above a complexity threshold need fundamentally different state serialization strategies, not just better checkpointing.

**Rule:** For projects with >3 prior session continuations, auto-generate a structured project-state manifest (key files, active branches, running services, pending tasks) at each checkpoint — not a narrative summary but a machine-queryable JSON snapshot that survives format drift.

_Patterns: 881b161f-3ee0-4597-ab7b-d6c2a860613d, 5c3499d0-aef9-4924-b559-e15bf88068ed, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.78)
> Data hallucination and fix-thrashing share a common root cause: the agent acting without grounding. Hallucinated data values are 'acting without source grounding'; repeated fix attempts are 'acting without causal grounding'. Both arise when the agent substitutes plausible-looking output for verified output under time/context pressure. The trust damage from both is disproportionate to the effort saved — suggesting they share an underlying 'ungrounded confidence' failure mode.

**Rule:** Before any generative action (data value, fix attempt, API call), require an explicit 'grounding citation' — the source file/line, the error message, or the data column that justifies the output. If no citation exists, flag as inferred rather than proceeding silently.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, ef57d880-da40-403d-b5bc-49ae318f35bd, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.75)
> The user's terse continuation style ('next', 'ahead', 'three') and iterative UI refinement pattern ('better', 'good but...') are the same behavior at different timescales. Short commands drive micro-iteration within a task; aesthetic feedback drives macro-iteration across tasks. Both signal a user who thinks in rapid feedback loops rather than upfront specifications. The agent should optimize for fast turnaround and visual verification, not comprehensive first-pass solutions.

**Rule:** For UI tasks with this user, default to shipping the minimal visible change with a screenshot, then wait — don't anticipate refinements or bundle multiple aesthetic changes. The user's iteration loop is faster than the agent's prediction accuracy.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.72)
> Worktree data loss, wrong-org pushes, and credential leaks are all 'stale assumption' bugs — the agent assumed state X (clean worktree, correct org, ephemeral credentials) when reality was state Y. These are the git/security analog of the post-compaction state drift problem. The session continuity infrastructure (WAL, checkpoints) protects conversational state but not environmental state. There's a gap: no equivalent of /catchup for git/env state.

**Rule:** Before any destructive or externally-visible git operation, run a 3-command environmental state check (git status, git remote -v, git stash list) and diff against last-known state. Treat environmental state with the same suspicion as post-compaction conversational state.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.65)
> Slack MCP's persistent failures, the vision loop's strict verify-before-act requirement, and fire-and-forget task notifications represent three points on a reliability spectrum for external integrations. The pattern suggests that integrations with no feedback loop (Slack) fail silently and repeatedly; integrations with mandatory verification (desktop automation) succeed but slowly; and integrations that are inherently one-way (task notifications) work fine precisely because they don't need acknowledgment. The lesson: external tool reliability correlates with how tightly the feedback loop is coupled.

**Rule:** For any MCP integration that fails more than twice in a session, switch to a degraded-but-verified fallback (e.g., Slack webhook via curl instead of MCP) rather than retrying the same broken path. Classify integrations by feedback-loop tightness and set retry budgets accordingly.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, dd2e18ab-2182-4f88-8eab-354193b9e90a, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.70)
> The user's two major projects (iDream dashboard with pm2/MongoDB/widgets, and SvelteKit data pipeline with eBay/JEGS) both generate extremely long sessions, but for different reasons: the dashboard demands visual iteration loops, while the pipeline demands data integrity verification loops. Both stress the same infrastructure (WAL, checkpoints, core-dumps) but for orthogonal reasons. This means session continuity improvements should be tested against both failure modes — 'lost aesthetic context' and 'lost data transformation state' — not just one.

**Rule:** Core dump templates should have domain-aware sections: for UI projects, capture last-verified screenshot state and pending visual feedback; for data pipeline projects, capture last-verified transformation step and sample output checksums.

_Patterns: e218ac38-3844-4295-a972-c9dc01b22d13, 1523746a-7091-4022-b130-7e28b7f77561, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.68)
> The data hallucination warnings cluster around SvelteKit/data-pipeline work specifically — the user runs localhost:5173 and processes eBay/JEGS parts data. This domain (automotive parts with specific fitment data, part numbers, pricing) is uniquely hallucination-prone because values are plausible-looking alphanumeric codes that an LLM could easily fabricate. The risk isn't generic — it's domain-specific to structured catalog data where wrong values look indistinguishable from right ones.

**Rule:** In automotive/parts data pipelines, treat every output field as 'cite-or-mark-unknown' — if a value can't be traced to a specific cell in the source spreadsheet/API response, emit a sentinel value (e.g., '__UNVERIFIED__') rather than a plausible guess.

_Patterns: 392f40af-8bf6-463f-a558-c5b68076c729, 6fb0360d-b78d-4d97-ab65-325d2338ee68, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a_

---


## Wake Cycle — 2026-05-02 09:20 UTC

### Insight (conf=0.72)
> Context loss during compaction and data hallucination share the same root cause: the system operates on stale or absent state and fills gaps with plausible-looking fabrications. WAL migration to JSONL (machine-queryable) reduced context hallucination the same way source-traceability reduces data hallucination — both replace narrative reconstruction with verifiable records.

**Rule:** Treat post-compaction state reconstruction and data enrichment identically: every value must be traceable to a concrete source (WAL entry, checkpoint file, source column). If a value cannot be cited, flag it as 'unverified' rather than presenting it as fact.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 1e5df293-bb35-4b57-b67e-d2640b80c314_

---
### Insight (conf=0.68)
> Thrash loops (repeated fixes without root-cause analysis) and session continuation failures are amplified by each other: hitting context limits mid-debug forces a handoff that loses the debugging state, which causes the next session to re-attempt the same failed approaches. The Slack MCP pattern is a concrete instance — repeated install/diagnose/reconnect cycles across sessions without lasting resolution.

**Rule:** When a fix fails twice in the same session, write a structured 'investigation checkpoint' to the WAL before the third attempt — capturing what was tried, what failed, and the current hypothesis. This survives compaction and prevents the next session from replaying the same failed sequence.

_Patterns: 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, 21f20909-472b-4445-9477-c0605accbe55, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.65)
> Terse continuation commands and iterative UI refinement are the same interaction pattern at different granularities — the user communicates intent through minimal deltas ('next', 'better', 'revert colors') rather than complete specifications. This is a co-piloting style where the agent is expected to maintain a mental model of the user's evolving intent, making session continuity infrastructure load-bearing for UX quality, not just task completion.

**Rule:** During iterative UI refinement sessions, checkpoint the user's aesthetic preferences (not just code state) — e.g., 'user preferred darker background, larger fonts, rejected gradient approach'. These micro-preferences are lost on compaction but are critical for maintaining the co-piloting dynamic.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.60)
> The game theory simulation project's complexity (multi-agent architecture) directly drives the extreme session continuation pattern (100+ turns, multiple compactions). Complex domain models require more context to hold in working memory than the context window allows — the project's architecture complexity is proportional to session continuity infrastructure load.

**Rule:** For projects with >3 interacting subsystems, create a persistent 'domain model summary' file (not a checkpoint — a living document) that captures the key architectural relationships. This reduces the context needed to reconstruct working state after compaction, since the domain model is the slowest-changing and hardest-to-reconstruct layer.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, f1057a8d-e978-416c-b52e-7ea8fd28e770, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.58)
> Desktop automation's vision loop (screenshot → annotate → verify) and data pipeline source-traceability are instances of the same anti-hallucination principle: never act on inferred state, always ground actions in observed evidence. Coordinate guessing in GUI automation is structurally identical to value fabrication in data pipelines — both substitute plausible inference for verified observation.

**Rule:** Generalize the vision-loop pattern into a 'ground-before-act' principle: before any action that depends on state (screen coordinates, data values, file contents, git status), perform a fresh observation. Never carry forward state from a previous observation across an action boundary.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 1e5df293-bb35-4b57-b67e-d2640b80c314, ef57d880-da40-403d-b5bc-49ae318f35bd_

---
### Insight (conf=0.55)
> Worktree data loss, incorrect repo owner inference, and credential leakage are all failures of the same class: assuming persistent state across an operation boundary. Worktrees assume unstaged changes will survive switching; repo owner is inferred from stale session context; credentials assumed ephemeral may persist in files. All three require explicit verification at the boundary.

**Rule:** Before any operation that crosses an isolation boundary (worktree switch, repo push, file write with sensitive context), run a 'boundary checklist': (1) what state am I carrying from before? (2) will it survive the crossing? (3) should it?

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---


## Wake Cycle — 2026-05-02 10:06 UTC

### Insight (conf=0.72)
> The game theory / geopolitical simulation project's complexity is a primary driver of context exhaustion. The WAL migration from markdown to JSONL mirrors the same problem the simulation itself likely solves: when state spaces grow too large for narrative representation, you need structured machine-queryable formats. The user's infrastructure needs are isomorphic to their domain.

**Rule:** For projects with inherently large state spaces (simulations, dashboards with many widgets), trigger auto-checkpoint at tool call #20 instead of #30, and prefer JSONL core-dumps over prose summaries to maximize machine-recoverable state density.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---
### Insight (conf=0.78)
> The terse continuation commands ('next', 'ahead') and iterative UI refinement ('better', 'good but...') are the same behavior at different granularities — the user thinks in rapid micro-feedback loops. This is a REPL-style interaction pattern where each message is a delta, not a specification. The visual verification requirement (screenshots before reporting done) is the 'assert' in this human REPL.

**Rule:** When in iterative UI refinement mode (3+ sequential short feedback messages about the same component), auto-screenshot after each change without being asked — the user's mental model expects visual confirmation as the loop's return value.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.85)
> Data hallucination, credential leakage, and fabricated API results are all instances of the same meta-pattern: the agent generating information that doesn't exist in reality and presenting it as real. Credentials written to files are 'hallucinated security' (the file pretends the credential belongs there). Fabricated data values are 'hallucinated provenance.' The trust damage is identical because the failure mode is identical: the user can no longer distinguish agent-verified facts from agent-invented ones.

**Rule:** Before outputting any value that will persist (to a file, commit, or data structure), apply a provenance check: can this value be traced to a specific source line, API response, or user input? If not, flag it as '[UNVERIFIED]' inline rather than presenting it as factual.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.80)
> Fix-attempt thrashing and context exhaustion are mutually reinforcing. Each failed fix attempt consumes context window budget, which accelerates hitting the context limit, which forces a continuation with degraded state, which makes the next fix attempt more likely to fail due to missing context. The /core-dump at milestones rule is actually a circuit-breaker for this feedback loop.

**Rule:** After 2 consecutive failed fix attempts on the same issue, force a micro-checkpoint (lightweight core-dump of just the current hypothesis and attempts tried) before the third attempt. This both prevents thrashing and insures against imminent context exhaustion.

_Patterns: 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, 5c3499d0-aef9-4924-b559-e15bf88068ed, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.74)
> The validated vision loop for desktop automation (screenshot → annotate → act → verify) and the iterative UI refinement loop (change → screenshot → user feedback → change) are the same control loop with different actors in the feedback position. Desktop automation puts the agent in both roles; UI refinement puts the user as the evaluator. Both fail the same way when the verification step is skipped.

**Rule:** Unify UI change verification and desktop automation verification into a single 'visual assertion' primitive: any action that modifies visible state must be followed by a screenshot read before reporting completion or proceeding to the next action.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 92a767af-37ad-4b83-84af-684fd98948b5, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.82)
> Worktree state loss, wrong-org pushes, and credential file writes are all 'assumption carry-forward' bugs — the agent assumed something from earlier context was still true (unstaged changes are safe to discard, org is the same as last time, credentials are just another string). The common root is acting on stale mental state rather than re-verifying before irreversible operations.

**Rule:** Before any operation that is difficult to reverse (git push, branch switch, file write containing sensitive-looking strings), re-read the specific state being affected in that same tool-call sequence — never rely on state observed more than 3 tool calls ago.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.70)
> The recurring Slack MCP connection failure and the fix-without-root-cause thrashing are the same anti-pattern applied to infrastructure vs. code. Multiple sessions attempted to fix Slack MCP without diagnosing why it fails — each session is a 'fix attempt' that doesn't identify the root cause, just like code thrashing. Infrastructure debugging needs the same '3 attempts then stop and analyze' rule.

**Rule:** When an MCP server or external integration fails to connect, log the exact error and conditions in a persistent note after the first attempt. On the second session encountering the same failure, read the prior note before attempting fixes. After 3 sessions with the same failure, escalate to the user with a structured diagnosis rather than retrying.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.65)
> Fire-and-forget task notifications with 0 tools and 0 reply chars are 'context pollution' — they consume context window space without contributing information, accelerating the very context exhaustion that makes session continuity so critical. The high tool counts (10-100+) per turn compound this. The session continuity infrastructure is partly compensating for avoidable context waste.

**Rule:** Empty task notification messages should be treated as no-ops for context accounting purposes. When context budget is >60% consumed and empty notifications are present, prioritize compaction of notification-heavy regions first.

_Patterns: 00fb690c-b719-4a18-ad08-94adf937ae00, 2e7d5054-603d-4ba1-92cb-41bca5de2463, f1057a8d-e978-416c-b52e-7ea8fd28e770_

---
### Insight (conf=0.68)
> The user maintains three very different long-running projects (SvelteKit data pipeline, iDream dashboard, game theory simulation) but uses identical session continuity patterns across all of them. This suggests the continuity tooling should be project-aware — a /catchup that knows which project it's resuming would be more efficient than a generic one that reconstructs context from scratch each time.

**Rule:** Core-dump files should include a project identifier (derived from git remote or directory name) so that /catchup can filter to project-relevant state when multiple projects share the same continuity infrastructure.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, c70ae766-c39a-442a-a15d-fbe84d854e0c, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.73)
> The SvelteKit data pipeline project (eBay/JEGS parts data) is likely the origin of the data hallucination trust violations. Parts data has plausible-looking values (part numbers, prices, fitment specs) that an LLM can easily fabricate convincingly. The localhost:5173 dev server pattern means these fabricated values would appear real in the UI, compounding the trust damage. Domain-specific data (automotive parts) is uniquely dangerous for hallucination because the values look 'right' to non-domain-experts.

**Rule:** In data pipeline projects with domain-specific identifiers (part numbers, SKUs, serial numbers), never generate placeholder or example values — use literal 'MISSING' or 'SOURCE_NOT_FOUND' strings that are visually impossible to mistake for real data.

_Patterns: 392f40af-8bf6-463f-a558-c5b68076c729, 6fb0360d-b78d-4d97-ab65-325d2338ee68, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a_

---


## Wake Cycle — 2026-05-02 11:07 UTC

### Insight (conf=0.75)
> Context limits are hit because the geopolitical simulation project's multi-agent architecture generates high tool counts per turn — the JSONL WAL migration was a direct response to this pressure, optimizing for machine-queryable state recovery rather than human-readable logs, because the bottleneck is reconstruction speed at scale, not readability.

**Rule:** For projects with >50 tools per session, auto-checkpoint at tool #25 (not #30) and include a tool-count estimate in the core-dump header so /catchup can prioritize which checkpoints to load.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.60)
> Terse continuation signals ('next', 'ahead') combined with iterative UI refinement creates a failure mode: the agent interprets terse input as 'keep going autonomously' but the user meant 'keep going in my direction' — leading to fix-attempt thrashing when the agent drifts from the user's unstated visual intent.

**Rule:** After 3 consecutive terse continuations on UI work, take a screenshot and confirm direction before the next change — terse signals lose precision over iterative visual refinement.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, 92a767af-37ad-4b83-84af-684fd98948b5_

---
### Insight (conf=0.85)
> The 'never hallucinate data' rule and the 'never guess coordinates' rule are the same underlying pattern: when operating on structured external reality (data rows, pixel coordinates), inference without grounding produces catastrophic silent failures. Both domains punish plausible-looking fabrication identically.

**Rule:** Unify data-hallucination and coordinate-guessing under a single 'grounded-output' pattern: any value emitted as factual (data cell, coordinate, API result) must cite its source (column, screenshot region, response field). If no source exists, mark as INFERRED.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, ef57d880-da40-403d-b5bc-49ae318f35bd, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.70)
> Credentials leaked to files, unstaged changes lost to worktree ops, and wrong-org pushes are all instances of 'ephemeral state treated as durable' — the agent assumes something transient (a password in memory, uncommitted edits, a context-inferred org name) will persist or be correct across an operation boundary.

**Rule:** Before any operation that crosses a state boundary (file write, branch switch, remote push), re-verify the ephemeral inputs: re-read the value, re-check git status, re-confirm the target. Never carry forward transient state across boundaries.

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.55)
> Fire-and-forget task notifications arriving with 0 tools and 0 reply chars consume context window budget without contributing to task progress — in sessions already at 80-100 tools, these empty signals accelerate context exhaustion and force earlier compaction cycles.

**Rule:** Task notification messages with 0 tools and 0 substantive content should be compacted aggressively (retain only task-id + status) to preserve context budget for sessions that already trend toward high tool counts.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, 00fb690c-b719-4a18-ad08-94adf937ae00, f1057a8d-e978-416c-b52e-7ea8fd28e770_

---
### Insight (conf=0.80)
> The recurring Slack MCP connection failures are an instance of the 'fix without root cause' anti-pattern applied to infrastructure rather than code — each session re-attempts connection without diagnosing the underlying auth/config issue, creating a cross-session thrash loop invisible within any single session.

**Rule:** When an MCP connection has failed in 3+ sessions, stop retrying and write a diagnostic note to runtime-notes with the failure mode — treat it as a known-broken integration requiring user-side action, not an agent-solvable retry.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.80)
> Core-dump, WAL, and catchup form a distributed systems consensus pattern (write-ahead log + snapshot + replay) applied to LLM sessions. The JSONL migration mirrors the industry pattern of moving from human-readable logs to structured event stores once operational load exceeds what grep can handle.

**Rule:** Treat the WAL/checkpoint/catchup system as a proper event-sourcing pipeline: WAL entries are the source of truth, checkpoints are materialized views, and /catchup is a projection rebuild. Apply event-sourcing invariants: never mutate WAL entries, checkpoints must be reproducible from WAL, and stale checkpoints should be rebuilt not patched.

_Patterns: 584e7697-e747-48e6-9cd8-274ccffd99d8, 1523746a-7091-4022-b130-7e28b7f77561, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26_

---


## Wake Cycle — 2026-05-02 14:08 UTC

### Insight (conf=0.72)
> Context loss across session boundaries and data hallucination share a common root: the agent fills gaps with plausible-but-unverified content. When session state is lost at compaction, the agent 'hallucinates' prior context just as it hallucinates data values — both are gap-filling under uncertainty. The same discipline that prevents data fabrication (require traceable source) should apply to session state (require traceable checkpoint). Sessions that hit context limits without proper core-dumps are the 'data pipeline' equivalent of missing source columns — the agent will synthesize what it doesn't have.

**Rule:** Treat context reconstruction after compaction with the same rigor as data pipeline values: never assert prior session state without a traceable source (WAL entry, checkpoint file, or git log). If no checkpoint exists, explicitly flag uncertainty rather than reconstructing from memory fragments.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, ef57d880-da40-403d-b5bc-49ae318f35bd, 392f40af-8bf6-463f-a558-c5b68076c729, 6fb0360d-b78d-4d97-ab65-325d2338ee68, 5c3499d0-aef9-4924-b559-e15bf88068ed, 00fb690c-b719-4a18-ad08-94adf937ae00_

---
### Insight (conf=0.68)
> Fix-thrashing and context-limit exhaustion are coupled: repeated failed fix attempts consume context tokens at an accelerated rate, pushing sessions to compaction boundaries faster, which then causes state loss, which causes more thrashing. The re-edit-thrash anti-pattern is not just an efficiency problem — it's a context budget problem. Each thrash cycle burns ~3-5x the tokens of a single correct attempt, directly accelerating the need for compaction.

**Rule:** When a fix attempt fails twice, before attempting a third, run /core-dump as a defensive checkpoint — the thrash pattern correlates with imminent context exhaustion, and losing state mid-thrash is worse than losing it mid-progress.

_Patterns: 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, 5c3499d0-aef9-4924-b559-e15bf88068ed, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.78)
> The user's terse communication style and heavy session-continuity reliance form a coherent interaction model: they treat the agent as a persistent co-worker, not a fresh assistant. Single-word commands ('ahead', 'next') only make sense when shared context is assumed. Task notifications arriving as fire-and-forget signals fit the same model — the user expects the agent to maintain state like a colleague who was 'in the room' for prior work. This means context loss is not just inconvenient but breaks the fundamental interaction contract.

**Rule:** When a session starts without /catchup and the user issues terse commands, proactively warn once that context may be stale rather than silently operating on partial state — terse commands assume shared context that may not exist post-compaction.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, d8578fea-ae3a-4ec7-9a16-ababf44cfc38, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.75)
> Three seemingly unrelated patterns share the principle 'verify from source before acting on inference': desktop automation requires screenshot verification before clicking (don't guess coordinates), data pipelines require source traceability (don't guess values), and git operations require owner verification (don't guess org). The common anti-pattern is 'plausible inference without verification' — the agent constructs a reasonable-looking answer from context clues instead of reading the actual state. The cost scales with irreversibility: wrong click (recoverable) < wrong git push (painful) < wrong data values (trust-destroying).

**Rule:** Before any action where the agent is working from 'I think X is...' rather than 'I just read/saw X is...', the verification cost should scale with irreversibility: read-only check for recoverable actions, explicit user confirmation for trust-sensitive ones.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 1e5df293-bb35-4b57-b67e-d2640b80c314, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.62)
> Notion sync fragility and Slack MCP connection failures are instances of the same meta-pattern: external integration brittleness that recurs across sessions because the fix addresses symptoms rather than root cause. Each session re-diagnoses the same class of failure. Combined with the fix-thrash anti-pattern, these integrations consume disproportionate session time. They may benefit from a 'known-fragile integration' registry that front-loads the last known failure mode and fix.

**Rule:** Maintain a 'fragile integrations' section in runtime-notes listing external tools with recurring failures (Notion sync, Slack MCP) and the last known root cause + workaround, so new sessions skip the re-diagnosis phase.

_Patterns: 9e8b9158-842f-449f-8e35-5be120ba3e88, 21f20909-472b-4445-9477-c0605accbe55, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.58)
> Accidental data loss through git worktree switching, credential leaks, and wrong-org pushes are all 'state pollution across boundaries' failures. Worktree switching pollutes working-tree state; credentials pollute file state; org inference pollutes identity state. The common fix is a 'boundary crossing checklist' — any time the agent crosses a boundary (worktree, session, repository, environment), it should snapshot and verify the new context rather than carrying assumptions from the old one.

**Rule:** On any boundary crossing (worktree switch, repo switch, session resume, environment change), run a context verification step: git status + remote check + env scan. Never carry assumptions across boundaries.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, afe8a2d8-17b3-42bc-973d-eac449588f9b, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---


## Wake Cycle — 2026-05-02 15:49 UTC

### Insight (conf=0.72)
> Terse continuation commands ('ahead', 'next') combined with data pipeline work create a dangerous interaction: the agent interprets terse input as 'keep going autonomously' and fills gaps in source data with inferred values rather than stopping to flag missing data. The autonomy bias from terse-command protocol directly conflicts with the zero-hallucination rule for data pipelines. These two rules need an explicit precedence: data-integrity trumps autonomous-continue.

**Rule:** When processing data pipelines under terse-continuation mode, autonomy applies to workflow steps (next file, next transform) but NOT to value inference. Missing or ambiguous source values must always pause for confirmation, even under 'keep going' signals.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 392f40af-8bf6-463f-a558-c5b68076c729, 556fbc99-c295-493f-8b7a-218b2f5e964f_

---
### Insight (conf=0.65)
> Thrash loops (repeated fix attempts without root-cause analysis) are more likely to occur in continued sessions after compaction, because the agent loses the mental model of what was already tried. The core-dump format likely doesn't capture 'failed approaches' — it captures state and progress, not the negative space of what didn't work. This creates a specific failure mode: post-catchup, the agent re-attempts the same broken fix path.

**Rule:** Core dump files should include a 'Dead Ends' section listing approaches attempted and why they failed, so post-catchup sessions don't re-enter thrash loops on known-bad paths.

_Patterns: 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, d8578fea-ae3a-4ec7-9a16-ababf44cfc38, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.78)
> The 'render before judge' principle applies across three seemingly different domains — desktop automation (screenshot before clicking), dashboard aesthetics (screenshot before reporting done), and data pipelines (never fabricate values). The common thread is that the agent must ground its claims in observable reality, not internal model state. This is a single meta-pattern: 'verify against ground truth before asserting completion.'

**Rule:** Before reporting any task as complete, the agent must have at least one ground-truth verification step (screenshot for UI, read-back for files, curl for APIs, source-trace for data values). 'I believe it works' is never sufficient.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, ef57d880-da40-403d-b5bc-49ae318f35bd_

---
### Insight (conf=0.60)
> State assumptions that persist across context boundaries cause three different categories of damage: git worktree switches lose unstaged work (stale filesystem assumption), wrong org/owner on push (stale git remote assumption), and credential leaks (stale 'this is ephemeral' assumption). All three are instances of the same bug: treating cross-boundary state as reliable. The WAL/checkpoint system preserves intended state but not ambient state (unstaged changes, env vars, process handles).

**Rule:** After any session boundary (catchup, compaction, worktree switch), run a 'state audit' checking: git status for unstaged changes, git remote -v for target, env | grep sensitive patterns. Don't trust prior-context claims about ambient state.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.55)
> External integration fragility (Slack MCP, Notion sync, third-party APIs) recurs across sessions because fixes are applied at the symptom level within a single session but the root cause (auth token expiry, API contract drift, rate limiting) persists. The session-continuity infrastructure (WAL, checkpoints) doesn't track integration health status, so each new session rediscovers the same breakage. Integration health should be a first-class checkpoint field.

**Rule:** When an external integration (MCP server, API sync, webhook) fails and is fixed in a session, add an 'integration_health' entry to the core dump noting the failure mode and fix. On catchup, surface stale integration fixes as 'may have regressed' warnings.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, 9e8b9158-842f-449f-8e35-5be120ba3e88, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.50)
> The user maintains two long-running projects (SvelteKit parts data pipeline and iDream dashboard) that both involve data transformation and persistence layers but with different trust boundaries. The data-hallucination rules were learned in the SvelteKit/eBay pipeline context but apply equally to the iDream dashboard's Anthropic API responses. Cross-pollination risk: dashboard sessions might not trigger the same vigilance about fabricated values because the pattern was learned in a 'data pipeline' mental bucket.

**Rule:** Data integrity rules (no hallucinated values, source-traceability) apply to ALL projects with data persistence, not just those tagged as 'data pipelines'. Trigger the same vigilance whenever writing to a database or structured file.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, 6fb0360d-b78d-4d97-ab65-325d2338ee68, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---


## Wake Cycle — 2026-05-02 16:50 UTC

### Insight (conf=0.72)
> Context limit hits and fix-thrashing share a root cause: the agent loses working memory mid-task, then re-attempts fixes without the context that informed the first attempt. The JSONL WAL migration partially addresses this, but thrash loops still occur because WAL captures *actions* not *reasoning*. A 'hypothesis log' alongside the WAL — recording why each fix was attempted and what was ruled out — would break thrash cycles even across compaction boundaries.

**Rule:** When a fix attempt fails, append a WAL entry of kind 'hypothesis' recording what was tried and why it failed before attempting the next fix. On /catchup, surface the last 3 hypothesis entries to prevent re-treading.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.65)
> Data hallucination and Notion sync fragility are two expressions of the same anti-pattern: the agent fills gaps with plausible-looking values instead of surfacing the gap. In data pipelines it fabricates cell values; in sync scripts it silently drops or transforms content that doesn't round-trip cleanly. Both destroy trust because the user can't distinguish correct output from fabricated output without manual audit.

**Rule:** Any value not directly traceable to a source cell, API response, or document must be emitted with a '[INFERRED]' or '[MISSING]' annotation. Sync operations that cannot round-trip a field must log it as a known gap rather than silently dropping or transforming it.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 9e8b9158-842f-449f-8e35-5be120ba3e88_

---
### Insight (conf=0.78)
> The game theory simulation and the iDream dashboard are both 'cathedral' projects — architecturally complex, long-running, and requiring deep context to make safe changes. The user's terse continuation style ('ahead', 'next') is an efficiency adaptation to this: they've already internalized the plan and don't want to re-explain it every turn. This means the agent's ability to autonomously maintain deep project context is not a convenience feature but load-bearing infrastructure for the user's working style.

**Rule:** For projects with >5 prior sessions in WAL history, auto-load the last runtime-notes entry at session start without waiting for /catchup — the user's terse style assumes the agent already has context.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, e181d5f7-4435-4c76-a1a4-82f3536aac19, 556fbc99-c295-493f-8b7a-218b2f5e964f_

---
### Insight (conf=0.82)
> The vision-loop pattern for desktop automation and the user's insistence on screenshot verification for dashboard aesthetics are the same principle applied at different scales: 'render-before-judge'. The data hallucination pattern is what happens when this principle is violated — the agent judges correctness from internal state rather than observed output. All three converge on: the agent must never claim success based on what it *intended* to produce; only on what it *observed* was produced.

**Rule:** Before reporting any visual or data task as complete, the agent must have at least one verification step that reads the actual output (screenshot, file read-back, curl response) — never report done based solely on the write/edit succeeding.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, ef57d880-da40-403d-b5bc-49ae318f35bd_

---
### Insight (conf=0.70)
> Worktree data loss, wrong-org pushes, and credential leaks are all 'stale assumption' bugs — the agent acts on state it believes to be true from earlier in the session rather than re-verifying. The common fix is the same state-verification discipline: re-read before any irreversible side-effect. The WAL captures actions but doesn't enforce pre-action verification gates.

**Rule:** Before any destructive or externally-visible git operation, run the verification triad (status + log + diff) AND verify the remote URL matches the intended target. Treat worktree switches as equivalent to session boundaries — re-verify all file state.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.58)
> Slack MCP failures, Notion sync fragility, and silent task-notification signals share a pattern: external integrations degrade silently. The agent retries or ignores failures without escalating. A 'integration health' status that persists across sessions — marking which integrations are known-broken — would prevent wasted retry cycles in future sessions.

**Rule:** Maintain a 'known-broken integrations' section in runtime-notes. When an MCP or external sync fails after 2 attempts in a session, log it there with the date and failure mode. On /catchup, surface known-broken integrations so the agent doesn't re-attempt them without user direction.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, 9e8b9158-842f-449f-8e35-5be120ba3e88, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.68)
> Data hallucination and fix-thrashing are both confidence-calibration failures — the agent acts with high confidence when it should express uncertainty. In data pipelines, it fills gaps confidently; in debugging, it applies fixes confidently without root-cause analysis. A unified 'confidence gate' — where the agent must explicitly state its confidence before any inference or fix attempt — would address both.

**Rule:** Before inferring any data value or applying a fix to a failed operation, emit a one-line confidence assessment in the WAL. If confidence is below 0.7, flag the action to the user rather than proceeding autonomously.

_Patterns: 392f40af-8bf6-463f-a558-c5b68076c729, 6fb0360d-b78d-4d97-ab65-325d2338ee68, 1e5df293-bb35-4b57-b67e-d2640b80c314, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---


## Wake Cycle — 2026-05-02 17:51 UTC

### Insight (conf=0.72)
> Data hallucination and fix-thrashing are the same failure mode at different abstraction levels: the agent generates plausible-but-wrong output and then doubles down rather than verifying against ground truth. Both stem from 'confidence without grounding.' The fix-thrash pattern is hallucination applied to debugging — generating plausible fixes without reading the actual error.

**Rule:** Before any output that will be consumed as fact (data values, fix attempts, API results), the agent must cite the specific source line, file, or tool output it derived the value from. If no source can be cited, the output must be flagged as 'inferred' or the agent must stop and gather ground truth first.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.78)
> Terse continuation commands and long multi-compaction sessions are co-adapted behaviors: the user developed the terse style because the sessions are so long that conversational overhead compounds. Each 'ahead' or 'next' saves 30-60 seconds of re-reading a verbose response, and across 100+ turns that's 50-100 minutes saved. The terse protocol isn't a preference — it's an efficiency adaptation to the session-continuation workflow.

**Rule:** In sessions that have already hit one compaction boundary, automatically reduce response verbosity by 50% — skip recaps of what was just done, omit 'I will now...' preambles, and report only deltas from the last checkpoint.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.68)
> The vision-loop pattern for desktop automation and the 'render before judge' rule for data values are instances of the same meta-principle: never trust internal state representations — always verify through the same channel the end-user will use. Screenshots for UI, rendered output for data, actual HTTP responses for APIs. The user's trust model is 'show me the output path, not the internal path.'

**Rule:** Every verification step must use the consumer-facing output channel: screenshots for UI, rendered/exported files for data transforms, curl for APIs. Internal state inspection (console logs, variable dumps, test assertions) is supplementary, never sufficient alone.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 1e5df293-bb35-4b57-b67e-d2640b80c314_

---
### Insight (conf=0.61)
> Worktree data loss, wrong-org pushes, and credential leaks are all 'context bleed' failures — state from one context (branch, org, session) leaking into another. The session-continuation workflow amplifies this risk because the agent carries stale mental state across compaction boundaries. The WAL/checkpoint system preserves task state but not environmental state (which branch, which org, which credentials are active).

**Rule:** After every compaction or session resume, re-verify environmental context (current branch, remote origin, working directory, active credentials) before any write operation — even if the checkpoint says what they should be.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.65)
> Slack MCP and Notion sync are both 'external integration fragility' patterns — they break repeatedly across sessions because the failure mode is environmental (auth tokens expire, API contracts shift, network state changes) but the agent treats them as code bugs and thrashes on code fixes. The root cause is that external integrations need health-check-first diagnosis, not code-fix-first diagnosis.

**Rule:** When an external integration (MCP server, API sync, OAuth flow) fails, run a connectivity/auth health check before touching any code. If the health check passes, then investigate code. If it fails, report the environmental issue rather than attempting code fixes.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, 9e8b9158-842f-449f-8e35-5be120ba3e88, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.58)
> The user maintains at least three complex, long-running projects simultaneously (game theory sim, SvelteKit data pipeline, iDream dashboard). The session-continuation infrastructure isn't just about single-project depth — it's about multi-project context switching. The WAL and checkpoint system is functioning as a poor man's project-aware memory, but it's per-session not per-project. A project-indexed state system would reduce catchup overhead when switching between projects.

**Rule:** Maintain a per-project state summary (.claude/project-state.md) that is updated at session end and read at session start — separate from the WAL, which tracks session-level actions. This allows instant project re-orientation without replaying session history.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, b76b7252-944d-49f8-bb01-fa76c140a694, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.82)
> Three independent patterns all converge on the same failure: fabricating data values. The repetition across different domains (API results, source file extraction, pipeline gap-filling) suggests this isn't a per-task bug but a fundamental tendency of the model under uncertainty. The mitigation isn't more rules — it's a structural constraint: data output functions should require a source-citation parameter that is validated before the value is emitted.

**Rule:** In any data transformation or extraction task, implement a two-column output pattern: every emitted value must be paired with its source reference (file:line, column name, API field). Values without source references are automatically flagged as 'UNVERIFIED' in the output.

_Patterns: ef57d880-da40-403d-b5bc-49ae318f35bd, 392f40af-8bf6-463f-a558-c5b68076c729, 6fb0360d-b78d-4d97-ab65-325d2338ee68_

---


## Wake Cycle — 2026-05-02 20:41 UTC

### Insight (conf=0.72)
> The game theory / geopolitical simulation project's multi-agent architecture mirrors the session continuity problem itself — both are distributed state machines that must reconstruct coherent state from partial observations across boundaries. The WAL migration to JSONL parallels how simulation engines move from human-readable logs to machine-queryable event stores for the same reason: replay fidelity.

**Rule:** When building multi-agent simulation architectures, reuse the same event-sourcing patterns (JSONL append-only logs, checkpoint+replay) already validated by the session continuity system — they solve the same distributed state reconstruction problem.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---
### Insight (conf=0.78)
> Data hallucination in pipelines and state hallucination after context compaction are the same failure mode: an agent fabricating plausible-looking values when the source of truth is no longer in working memory. Core-dump at milestones prevents state hallucination the same way source-column citations prevent data hallucination — both force traceability to ground truth.

**Rule:** Treat post-compaction state claims and data pipeline values with the same discipline: every asserted value must be traceable to a concrete source (checkpoint file or source column). If you can't cite the source, re-read it — never reconstruct from memory.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 392f40af-8bf6-463f-a558-c5b68076c729, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.65)
> Terse continuation signals ('ahead', 'next', 'done') and fix-thrash loops are in tension: the user's communication style rewards autonomous execution, but autonomous execution without root-cause analysis leads to thrashing. The terse style is a trust signal — the user trusts the agent to be competent — which makes thrashing an even bigger trust violation than it would be for a verbose user.

**Rule:** When operating under terse-continuation mode and a fix attempt fails, the terseness contract does NOT extend to retry loops. After 2 failed attempts at the same problem, pause and report the root cause investigation — terse users gave you autonomy, not permission to thrash silently.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.74)
> The vision loop for desktop automation (screenshot → annotate → verify) and the dashboard aesthetics iteration loop share a principle with the anti-hallucination rules: all three demand render-before-judge. The user's distrust of fabricated API results, coordinate guessing without screenshots, and reporting UI work done without verification are all instances of 'acting on ungrounded state representation.'

**Rule:** Unify all verification under a single principle: never assert state you haven't observed in this tool call. Screenshots for UI, source citations for data, git status for repo state — the modality differs but the rule is one: observe, then claim.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, ef57d880-da40-403d-b5bc-49ae318f35bd_

---
### Insight (conf=0.68)
> Slack MCP, Notion sync, and git worktree failures are all integration-boundary fragility — external system state that the agent cannot fully control or predict. Each has caused multi-session recurring pain. These share a pattern: the agent treats external integrations as reliable when they are actually the most failure-prone surfaces.

**Rule:** Before any operation touching an external integration known to be fragile (Slack MCP, Notion sync, git worktree switching), run a pre-flight health check and preserve rollback state (stash unstaged changes, verify connection, snapshot current state). Treat external integrations as untrusted by default.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, 9e8b9158-842f-449f-8e35-5be120ba3e88, 5287886b-6995-4b9f-a22f-38e91d2a0ce4_

---
### Insight (conf=0.71)
> Credentials-must-not-persist, verify-owner-before-push, and WAL-format-migration are all instances of a meta-pattern: state that was valid in a prior context becoming dangerous when carried forward naively. Credentials from session N written to a file persist into session N+1. An org inference from session N applied in session N+1 pushes to the wrong repo. Old WAL format from session N confuses tooling in session N+1. Session boundaries are trust boundaries.

**Rule:** Treat session boundaries as trust boundaries: re-verify credentials scope, repository ownership, and format versions at session start rather than inheriting them from prior state. Anything that crosses a session boundary should be re-validated, not assumed.

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 0629319a-4440-4d1b-bad4-5ad0db93399a_

---
### Insight (conf=0.82)
> Data hallucination and fix-thrash loops are both panic responses to uncertainty — the agent fills in gaps (fabricated values, speculative fixes) rather than admitting it doesn't know. Both trigger the same user response: trust collapse. The root cause is the same: the agent treats 'I don't know' as a failure state rather than a valid output.

**Rule:** When facing uncertainty (missing data values, unclear failure cause), output 'unknown/investigating' as the explicit state rather than filling the gap with a plausible guess. An honest gap is recoverable; a confident fabrication destroys trust.

_Patterns: 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---


## Wake Cycle — 2026-05-02 21:43 UTC

### Insight (conf=0.72)
> The context limit problem is amplified by the game theory simulation's inherent complexity — the project's multi-agent architecture mirrors the multi-session agent architecture needed to work on it. Migrating WAL to JSONL was a necessary evolution because markdown state dumps couldn't scale to the information density this domain demands. Projects with deeply nested domain models will always outgrow flat-text continuity mechanisms first.

**Rule:** For projects with >3 interacting domain entities (agents, services, state machines), auto-checkpoint at half the normal tool-count interval (every 15 actions instead of 30) because domain context is denser and harder to reconstruct from code alone.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---
### Insight (conf=0.82)
> Data hallucination and fix-thrashing share a common root: the agent acts without sufficient grounding. In data pipelines, the grounding is source data; in debugging, the grounding is root-cause analysis. Both failures stem from 'generating plausible output without verified input' — the agent pattern-matches what an answer should look like rather than deriving it. A single meta-rule ('never produce output you can't cite a source for') would cover both.

**Rule:** Before emitting any value (data cell, fix attempt, API response), verify you can point to the exact source (file line, API response, error message) that justifies it. If you cannot cite the source, flag it as unverified rather than presenting it as fact.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.68)
> The user's terse command style and the need for frequent core-dumps are causally linked: terse commands maximize throughput per context window (more actions, fewer words), which means context fills faster with tool results rather than conversation, which triggers more compactions. The terse style isn't just a preference — it's an optimization for context-limited workflows. The system should treat high terse-command density as a leading indicator that a core-dump is approaching.

**Rule:** When terse continuation commands appear in >60% of the last 10 user messages, increase checkpoint frequency — the session is in high-throughput mode and will hit compaction sooner than average.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.75)
> The vision-loop validation pattern for desktop automation and the 'screenshot before reporting done' rule for dashboard work are the same principle: never claim a visual result without visual verification. This connects to the data hallucination patterns — all three are instances of 'the agent reported success based on what it expected to see, not what actually happened.' Visual verification, data source citation, and coordinate annotation are all forms of grounding output in observed reality.

**Rule:** Any task where the output is visual (UI, screenshot, rendered chart) or data-derived (transformed dataset, API enrichment) must include a verification step that reads back the actual output before reporting completion. 'I wrote the code' is not 'it works.'

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, ef57d880-da40-403d-b5bc-49ae318f35bd_

---
### Insight (conf=0.65)
> Notion sync fragility and Slack MCP connection failures are both symptoms of external-service integration brittleness that compounds with fix-thrashing. When an external service fails, the agent repeatedly attempts the same approach without stepping back to document what was tried. These integrations need a 'known-broken' registry so future sessions don't re-attempt the same failed approaches, wasting context on a problem that requires upstream fixes.

**Rule:** When an external service integration fails after 2 distinct fix attempts in a session, write a 'known-issue' entry to runtime-notes with: what was tried, what failed, and what the likely upstream blocker is. Future sessions should check this before re-attempting.

_Patterns: 9e8b9158-842f-449f-8e35-5be120ba3e88, 21f20909-472b-4445-9477-c0605accbe55, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.78)
> Worktree data loss, wrong-org pushes, and credential leaks are all 'state assumption' failures — the agent assumed git state, repo ownership, or session ephemerality without verifying. These cluster around operations that cross boundaries (branch→worktree, local→remote, memory→disk). The common fix is: verify state at every boundary crossing, not just at session start.

**Rule:** Before any operation that crosses a boundary (local→remote, branch→worktree, memory→file), re-read the target state. Boundary crossings invalidate cached assumptions.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.58)
> Fire-and-forget task notifications consuming 0 tools/0 chars are noise in the context window during already context-heavy sessions. In sessions with 10-100+ tools per continuation, these empty notifications accelerate context exhaustion without contributing information. They're the 'junk calories' of the context budget.

**Rule:** Task notification messages with 0 tools and 0 reply content should be acknowledged in WAL but not echoed to conversation context — they consume token budget without adding recoverable state.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, 00fb690c-b719-4a18-ad08-94adf937ae00, f1057a8d-e978-416c-b52e-7ea8fd28e770_

---
### Insight (conf=0.70)
> The iDream dashboard (MongoDB, widgets, API) and the SvelteKit parts data pipeline are both data-heavy projects where the user has been burned by hallucinated values. The recurring theme isn't domain-specific — it's that any project involving structured data transformation is a hallucination risk zone. The data integrity rules should trigger on project shape (has transforms, has source→target mapping), not just on explicit data pipeline keywords.

**Rule:** When a task involves reading data from source A and writing/displaying it in format B, automatically activate data-integrity mode: no inferred values, spot-check 2-3 records end-to-end, flag any field that doesn't have a direct source mapping.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694, 392f40af-8bf6-463f-a558-c5b68076c729_

---


## Wake Cycle — 2026-05-02 23:19 UTC

### Insight (conf=0.72)
> The game-theory simulation project's multi-agent architecture mirrors the session-continuation architecture itself — both are distributed state machines that must serialize, transmit, and reconstruct state across boundaries (context windows for the agent, turns for simulated actors). The WAL→JSONL migration is essentially the same design decision a distributed simulation makes when moving from human-readable logs to machine-queryable event stores. The session infrastructure IS a geopolitical simulation in miniature: agents with partial information, state handoff protocols, and trust-but-verify reconstruction.

**Rule:** When designing state-handoff mechanisms for the simulation project's agents, reuse the WAL/checkpoint/catchup pattern directly — JSONL event log per agent, periodic checkpoints, jq-based state reconstruction. Don't invent a second serialization protocol.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 1523746a-7091-4022-b130-7e28b7f77561_

---
### Insight (conf=0.68)
> Data hallucination and context loss are the same failure mode at different layers. When the agent fabricates a data value, it's because the source is absent from working memory — identical to post-compaction state loss where the agent confabulates what it 'remembers' doing. The /core-dump-at-milestones rule is actually an anti-hallucination measure: it prevents the agent from inferring its own prior state the same way source-tracing prevents it from inferring data values.

**Rule:** After any context compaction during a data-processing task, re-read the source file headers and a sample row before resuming transforms — treat post-compaction data work as a hallucination-risk zone equivalent to a fresh session.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 392f40af-8bf6-463f-a558-c5b68076c729, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.75)
> Terse continuation signals and fix-thrash loops are adversarial twins. The user's single-word 'ahead'/'next' commands signal trust and momentum — but the same terseness during a failing fix loop ('try again', 'no', 'again') can fuel blind retries instead of triggering a root-cause pause. The agent interprets both as 'continue autonomously' when the second case actually demands the opposite.

**Rule:** When a terse continuation follows a failed attempt (not a successful step), do NOT treat it as an autonomous-continue signal. Instead, pause for root-cause analysis. Heuristic: if the last action was a fix and the user's response is negative-terse ('no', 'wrong', 'again'), switch from execution mode to investigation mode.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.80)
> The vision-loop pattern for desktop automation (screenshot → verify → act) is the visual analogue of the data-tracing rule (source → verify → output). Both enforce the same principle: never act on inferred state. The user's dashboard aesthetic iteration pattern reinforces this — they don't trust reported completion, they trust screenshots. The common thread is that this user's trust model is evidence-based at every layer: visual evidence for UI, source citations for data, coordinate annotations for clicks.

**Rule:** For any task where the output is user-facing (UI, data export, report), always include a verification artifact (screenshot, sample output, diff) in the completion message. 'It works' without evidence is as bad as a hallucinated data value for this user.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, ef57d880-da40-403d-b5bc-49ae318f35bd_

---
### Insight (conf=0.65)
> Credentials leaking to files, wrong-org pushes, and worktree data loss are all instances of a single pattern: side-effecting operations that cross trust boundaries without verification. Credentials cross the memory→disk boundary, pushes cross local→remote, worktree switches cross branch→branch. Each failed because the agent assumed the target context was safe without checking.

**Rule:** Before any operation that moves data across a boundary (memory→file, local→remote, branch→branch), name the boundary explicitly in your reasoning and verify the target state. Template: 'Crossing [X→Y] boundary — verifying Y is [expected state].'

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5287886b-6995-4b9f-a22f-38e91d2a0ce4_

---
### Insight (conf=0.60)
> Notion sync fragility and Slack MCP connection failures are both instances of external-service integration debt that recurs across sessions because fixes are applied at the symptom level (retry, reconnect, patch) rather than at the architectural level (health checks, fallback modes, connection pooling). The fix-thrash pattern amplifies this — each session re-discovers the same breakage and applies the same patch.

**Rule:** For recurring external-service failures (Notion, Slack MCP), maintain a 'known fragile' registry in runtime-notes with last-known-good state and the specific failure mode. On the third occurrence of the same failure pattern, escalate from 'fix the symptom' to 'propose an architectural change' (health-check wrapper, circuit breaker, or degraded-mode fallback).

_Patterns: 9e8b9158-842f-449f-8e35-5be120ba3e88, 21f20909-472b-4445-9477-c0605accbe55, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.70)
> The user runs two long-lived projects (iDream dashboard on pm2/MongoDB, SvelteKit parts app on localhost:5173) that both involve iterative UI work with heavy session continuity needs. The dev-server and dashboard patterns suggest the user's workflow is fundamentally 'live system editing' — making changes to running services and verifying in real-time, which explains why session continuity is so critical: interruption means losing not just context but the mental model of a live system's current state.

**Rule:** When resuming a session on either project, the first /catchup action should include verifying the dev server / pm2 process status — not just code state but runtime state, since the user's workflow assumes a live system.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, 32a71715-924d-433b-8e7b-cac646fea9e2_

---


## Wake Cycle — 2026-05-03 00:20 UTC

### Insight (conf=0.72)
> The game theory / geopolitical simulation project's complexity is a primary driver of context exhaustion. The project's multi-agent architecture mirrors the agent's own multi-session architecture — both systems need state serialization across boundaries. The WAL migration to JSONL may have been directly motivated by the volume of context handoffs this project demands.

**Rule:** For projects with multi-agent simulation architectures, auto-checkpoint at half the normal interval (every ~8-10 actions instead of ~15-20) since these sessions burn context faster due to architectural complexity.

_Patterns: 881b161f-3ee0-4597-ab7b-d6c2a860613d, 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---
### Insight (conf=0.78)
> Data hallucination and fix-thrashing share a common root cause: the agent acting without grounding. Hallucination is acting without grounding in source data; thrashing is acting without grounding in root-cause understanding. Both are 'confidence without verification' failures that erode trust. A single metacognitive check — 'can I cite my source for this action?' — would catch both.

**Rule:** Before outputting any value (data or code fix), pass the 'citation test': can you point to the exact source line, API response, or error message that justifies this output? If not, stop and investigate rather than proceed.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 392f40af-8bf6-463f-a558-c5b68076c729, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.65)
> The user's terse command style and the frequent context exhaustion are co-evolved behaviors. Terse commands are an adaptation to context scarcity — every token saved on communication is a token available for work. The user optimized their own communication protocol to extend session life, the same way the WAL/checkpoint system optimizes state persistence.

**Rule:** When receiving terse continuations in a session that has already compacted once, bias toward executing smaller atomic units of work per turn to reduce the risk of losing progress to another compaction mid-operation.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, e218ac38-3844-4295-a972-c9dc01b22d13, 5c3499d0-aef9-4924-b559-e15bf88068ed_

---
### Insight (conf=0.82)
> The vision-loop pattern for desktop automation and the anti-hallucination rule for data pipelines are the same principle applied to different domains: never act on inferred state, always verify from source. Screenshots are the 'source data' for UI; CSV rows are the 'source data' for pipelines. Both fail the same way when the agent guesses instead of reads.

**Rule:** Unify verification patterns under a single 'read-before-act' principle: for UI work, screenshot before claiming done; for data work, read source before emitting values; for git work, status before pushing. Same muscle, different domains.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 1e5df293-bb35-4b57-b67e-d2640b80c314_

---
### Insight (conf=0.70)
> Notion sync and Slack MCP share a pattern: external integration fragility that recurs across sessions, consuming disproportionate context on re-diagnosis each time. These are 'chronic conditions' rather than 'acute bugs' — the fix-thrash pattern is especially likely here because each session rediscovers the same failure modes without institutional memory of prior attempts.

**Rule:** For integrations that have failed in 3+ sessions, maintain a dedicated troubleshooting log (not just memory entries) that records each attempt, what was tried, and what the blocking issue was — so the next session starts from the frontier, not from scratch.

_Patterns: 9e8b9158-842f-449f-8e35-5be120ba3e88, 21f20909-472b-4445-9477-c0605accbe55, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.68)
> Credential safety, data hallucination, and git owner inference are all 'contamination from context' errors — the agent uses information present in the session (credentials, plausible values, prior repo names) and leaks it into an inappropriate output channel (file, dataset, git remote). The common failure mode is 'context bleed' where session-local knowledge escapes its intended scope.

**Rule:** Maintain a mental 'taint bit' on session-local information (credentials, inferred values, prior-session state). Before writing any tainted value to a persistent store (file, commit, API call), explicitly verify it belongs there.

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, ef57d880-da40-403d-b5bc-49ae318f35bd, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.73)
> Worktree-related data loss and heavy multi-session continuation are in tension: the user's workflow demands frequent context switches (between sessions, between tasks), but the tooling for switching (worktrees, branch operations) is the exact place where unstaged work gets lost. The user's continuity infrastructure (WAL, core-dump) protects conversation state but not working-tree state.

**Rule:** Before any operation that changes the working tree (worktree switch, branch checkout, git stash), run 'git status' and 'git stash list' and log the result to the WAL — so even if changes are lost, the WAL records what was at risk.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, 00fb690c-b719-4a18-ad08-94adf937ae00, f1057a8d-e978-416c-b52e-7ea8fd28e770_

---


## Wake Cycle — 2026-05-03 01:22 UTC

### Insight (conf=0.72)
> The geopolitical simulation project and the data integrity rules share a deep structural parallel: both are about modeling complex systems where fabricated state is catastrophic. In a multi-agent geopolitical sim, hallucinated agent state propagates through the simulation exactly like hallucinated data values propagate through a pipeline — both corrupt downstream trust. The simulation project likely *needs* the same 'traceable to source' discipline for its agent decision chains as data pipelines need for their values.

**Rule:** In simulation/multi-agent systems, every agent decision must reference the specific input state that caused it — apply the same 'no hallucinated values' rule from data pipelines to agent reasoning chains.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 1e5df293-bb35-4b57-b67e-d2640b80c314, 392f40af-8bf6-463f-a558-c5b68076c729_

---
### Insight (conf=0.55)
> The WAL markdown-to-JSONL migration succeeded because it made state machine-queryable, while Notion sync keeps failing because it relies on a format (Notion's API) that resists machine-queryability. The same principle that fixed WAL — structured, jq-parseable, append-only — could stabilize the Notion sync if applied as an intermediate layer: sync to local JSONL first, then push to Notion as a rendering step.

**Rule:** For any external-service sync (Notion, Slack, etc.), maintain a local JSONL source-of-truth and treat the external service as a read-only projection — never let the external API be the canonical state.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 9e8b9158-842f-449f-8e35-5be120ba3e88_

---
### Insight (conf=0.78)
> Context limit hits and fix-without-root-cause thrashing are the same failure mode at different scales. Hitting context limits means the session accumulated state without checkpointing (thrashing at the session level), just like repeated fix attempts accumulate changes without understanding (thrashing at the code level). Both are solved by the same intervention: stop, serialize current understanding, then resume with a clean frame.

**Rule:** When hitting 3 consecutive failed fix attempts OR approaching 70% context usage — whichever comes first — force a checkpoint: write current understanding to WAL, identify what is known vs unknown, then resume from the checkpoint.

_Patterns: 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, 5c3499d0-aef9-4924-b559-e15bf88068ed, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.82)
> The desktop automation vision loop (screenshot → annotate → verify) and the dashboard aesthetics iteration loop are instances of the same 'render-before-judge' principle, which is itself the visual-domain version of the anti-hallucination rule. Guessing coordinates without screenshots = guessing data values without source files = reporting UI done without screenshots. All three are the agent substituting its model of reality for actual observation.

**Rule:** Unify under a single 'observe-before-assert' principle: never claim a state (pixel position, data value, UI appearance) without a fresh read from the actual source. This applies equally to desktop automation, data pipelines, and UI verification.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, ef57d880-da40-403d-b5bc-49ae318f35bd_

---
### Insight (conf=0.68)
> Slack MCP failures, Notion sync fragility, and git worktree data loss are all boundary-crossing operations where the agent interacts with stateful external systems that don't support atomic transactions. The pattern: any operation that crosses a process/service boundary without a local rollback mechanism will eventually cause data loss or corruption. These three are symptoms of missing 'transaction boundaries' at integration points.

**Rule:** Before any cross-boundary operation (external API sync, worktree switch, MCP service call), snapshot the local state to a recoverable location. If the operation fails, restore from snapshot rather than attempting to reconcile partial state.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, 9e8b9158-842f-449f-8e35-5be120ba3e88, 5287886b-6995-4b9f-a22f-38e91d2a0ce4_

---
### Insight (conf=0.58)
> Credentials leaking to files, wrong git owner inference, and WAL as load-bearing infrastructure share a hidden connection: all three involve ephemeral session state being accidentally promoted to persistent state. Credentials should stay in-memory but get written to files. Git owner from a previous session gets carried forward. WAL entries become the canonical record. The rule: explicitly classify every piece of state as ephemeral or persistent at creation time, not at use time.

**Rule:** When acquiring any new state during a session (credentials, repo context, inferred values), immediately tag it as 'ephemeral-only' or 'persist-safe'. Ephemeral state must never be written to files or carried across session boundaries without explicit user approval.

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 1523746a-7091-4022-b130-7e28b7f77561_

---
### Insight (conf=0.85)
> The user maintains three large, architecturally distinct projects simultaneously (game theory simulation, iDream dashboard, SvelteKit data pipeline), all requiring multi-session continuity. This isn't just a preference for long sessions — it's a working style where the user context-switches between complex projects and needs the agent to cold-start into any of them reliably. The continuity infrastructure isn't serving one project; it's serving a portfolio.

**Rule:** Optimize /catchup to include project identification as its first step — detect which of the user's active projects is in CWD and load project-specific context before generic session state, since the user regularly switches between 3+ complex projects.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.88)
> Fix-thrashing and data hallucination are both manifestations of the agent optimizing for 'produce output' over 'verify understanding'. In fix-thrashing, the agent generates code changes without understanding the root cause. In data hallucination, the agent generates plausible values without verifying the source. Both are pressure to fill a gap with generation when the correct action is to stop and read. The user's strongest negative reactions cluster around this single failure mode.

**Rule:** Before generating any output that fills a gap (fix attempt, data value, inferred state), the agent must first produce a one-line hypothesis about WHY the gap exists. If the hypothesis can't be stated, the agent doesn't understand enough to generate — read more first.

_Patterns: 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 6fb0360d-b78d-4d97-ab65-325d2338ee68_

---


## Wake Cycle — 2026-05-03 02:23 UTC

### Insight (conf=0.55)
> The game theory / geopolitical simulation project likely involves complex data pipelines for agent state, and the strong anti-hallucination rules may have originated from bad experiences where synthesized agent behaviors or simulation outputs were presented as computed results. Multi-agent simulations are especially vulnerable to plausible-looking but fabricated intermediate state — the same trust-destruction dynamic as data pipeline hallucination, but at the architecture level.

**Rule:** When working on simulation or multi-agent projects, treat intermediate computed state with the same anti-hallucination rigor as source data — never infer agent decisions, game outcomes, or simulation values that weren't explicitly computed by the system.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 1e5df293-bb35-4b57-b67e-d2640b80c314, 392f40af-8bf6-463f-a558-c5b68076c729_

---
### Insight (conf=0.72)
> Context limit hits and fix-thrashing are correlated: when context is exhausted and state is lost across continuations, the agent loses root-cause awareness and falls into repeated fix attempts on the same issue. The WAL migration to JSONL (machine-queryable) is an architectural response to this — but the deeper fix is ensuring root-cause hypotheses survive compaction, not just action logs.

**Rule:** When writing core-dump or WAL checkpoints, always include a 'current_hypothesis' field for any in-progress debugging — the root-cause theory is the single highest-value piece of state to preserve across compaction boundaries.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.78)
> The terse-command communication style and the heavy checkpoint/core-dump usage are two sides of the same coin: the user has optimized their interaction pattern for maximum throughput with minimal interruption. Terse commands keep the agent executing; core-dumps keep the state portable. Together they form a 'pipeline operator' interaction model — the user treats the AI like a long-running process they manage via signals, not conversations.

**Rule:** Treat the combination of terse input + active checkpoint files as a 'pipeline mode' signal: maximize execution velocity, auto-checkpoint at tool count thresholds (not just time), and never interrupt flow for confirmations that can be deferred to the next natural pause.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.82)
> The vision-loop pattern for desktop automation and the dashboard aesthetic iteration pattern share a common principle: the user demands ground-truth verification before any claim of correctness. The anti-hallucination rules for data, the screenshot-verify loop for UI, and the 'render before judge' principle are all instances of a single meta-rule — never assert state without observing it.

**Rule:** Unify verification patterns under a single 'observe-before-assert' principle: data values must trace to source, UI changes must be screenshot-verified, desktop actions must use vision loops, and fix attempts must verify the fix actually worked — no domain gets an exemption from ground-truth checking.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, ef57d880-da40-403d-b5bc-49ae318f35bd_

---
### Insight (conf=0.68)
> Slack MCP and Notion sync are both external integration points that fail repeatedly across sessions. Combined with the fix-thrashing pattern, this suggests a class of 'session-recurring failures' — problems that get patched in one session but regress because the root cause is environmental or upstream, not in the user's code. These waste disproportionate session time because each new session re-discovers and re-diagnoses the same failure.

**Rule:** Maintain a 'known-fragile integrations' list in memory. When starting a session that touches a fragile integration (Slack MCP, Notion sync), check the list first, apply the last known workaround, and set a time-box (15 min) before escalating to the user rather than entering a diagnosis loop.

_Patterns: 9e8b9158-842f-449f-8e35-5be120ba3e88, 21f20909-472b-4445-9477-c0605accbe55, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.75)
> Git worktree data loss, incorrect repo owner inference, and credential leakage are all instances of 'stale assumption acting on shared state.' The common thread is that the agent carried forward a belief from earlier in the session (worktree is clean, repo belongs to X, credentials are transient) and acted on it without re-verification. These are the highest-cost failures because they affect state beyond the session.

**Rule:** Before any operation that modifies shared external state (git push, file write to non-local path, API call with side effects), re-verify the THREE assumptions most likely to have drifted: current branch/worktree state, target owner/org, and whether any sensitive data is staged.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.52)
> Fire-and-forget task notifications (0 tools, 0 reply chars) combined with high tool-count continuation sessions suggest an emerging async-orchestration pattern: the user launches background agents, receives completion signals, then continues in a primary session. This is a proto-workflow-engine running on top of the chat interface, and the zero-reply notifications are its event bus.

**Rule:** When a task notification arrives with 0 tools/0 reply during an active session, log the completion to WAL as an 'agent_done' event and surface a one-line summary to the user only if it affects the current task — don't context-switch for background completions.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, f1057a8d-e978-416c-b52e-7ea8fd28e770, 00fb690c-b719-4a18-ad08-94adf937ae00_

---
### Insight (conf=0.65)
> Data hallucination and WAL/checkpoint reliability are both trust infrastructure. The user has invested heavily in making session state machine-queryable (JSONL migration) precisely because corrupted or lossy state handoffs produce the same class of harm as hallucinated data: downstream decisions built on false premises. The WAL is the anti-hallucination system for session state, just as source-tracing is the anti-hallucination system for data.

**Rule:** Apply the same anti-hallucination standard to checkpoint/WAL content as to data pipelines: every claim in a core-dump must be traceable to an actual tool result or user message — never summarize state from 'memory' of what happened, always re-verify before writing.

_Patterns: 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 1523746a-7091-4022-b130-7e28b7f77561, 846615fc-eeb8-4a44-bf0a-bf06c723fde8_

---


## Wake Cycle — 2026-05-03 03:25 UTC

### Insight (conf=0.72)
> The session continuity problem is structurally identical to the geopolitical simulation's multi-agent state problem — both require serializing complex mutable state across discontinuous execution contexts. The WAL migration from markdown to JSONL mirrors the same insight game engines learn: human-readable state formats don't survive round-trip parsing under pressure. The user's own workflow IS the simulation: agents with bounded context windows negotiating shared state across time boundaries.

**Rule:** When designing state-handoff formats (WAL, checkpoints, core dumps), apply the same rigor as designing save-game formats: versioned schema, idempotent replay, and explicit 'what changed since last checkpoint' deltas rather than full snapshots.

_Patterns: 881b161f-3ee0-4597-ab7b-d6c2a860613d, 5c3499d0-aef9-4924-b559-e15bf88068ed, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.78)
> Data hallucination and fix-thrashing are the same failure mode at different abstraction levels: generating plausible-looking output without grounding in source truth. Hallucinating a data value is 'generating a plausible cell'; thrashing on a fix is 'generating plausible patches'. Both stem from the agent prioritizing output production over input comprehension. The user's extreme sensitivity to hallucinated data suggests they've been burned by systems that optimize for looking productive over being correct.

**Rule:** Before producing any output (data value, code fix, or API result), the agent must be able to cite the specific source line, file, or API response it derived the output from. If it cannot, it must emit a '[UNGROUNDED]' marker rather than a plausible fabrication. Apply to data cells, fix attempts, and status claims equally.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 392f40af-8bf6-463f-a558-c5b68076c729, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.81)
> The terse-command pattern and the high-tool-count sessions are two sides of user expertise: the user has internalized the agent's capabilities deeply enough to issue single-word dispatches expecting complex autonomous execution. This is the CLI-power-user pattern — like how experienced vim users think in commands, not keystrokes. The core-dump/catchup cycle is the user treating the agent like a persistent daemon they can detach/reattach to (tmux for AI).

**Rule:** For this user, a single-word message after establishing context implies 'execute the full obvious next step and report the result' — the expected autonomy level is equivalent to a senior engineer saying 'ship it' to a trusted colleague. Default to completing the entire logical unit of work, not just the next atomic step.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, e218ac38-3844-4295-a972-c9dc01b22d13, c892fa80-f5af-4270-9e16-9225249062cc_

---
### Insight (conf=0.74)
> The credential-safety, data-hallucination, git-worktree-loss, and org-verification patterns form a single trust axis: the user has experienced multiple incidents where the agent acted on stale or fabricated state and caused real damage. Each pattern is a different surface of the same root failure — acting before verifying. The user's investment in WAL/checkpoint infrastructure is partly a trust-repair mechanism: if the agent's memory can't be trusted across boundaries, at least make the boundaries explicit and auditable.

**Rule:** Maintain a 'verify-before-act' checklist that scales with blast radius: read-only ops need no verification, local file writes need file-exists check, git operations need the verification triad, external-facing operations need both state verification AND explicit user confirmation. The higher the blast radius, the more sources must corroborate.

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, ef57d880-da40-403d-b5bc-49ae318f35bd, 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.69)
> Slack MCP failures, Notion sync fragility, and desktop automation coordinate-guessing are all integration-boundary failures — the agent performs well within its native tooling but degrades at the boundary with external systems that have their own state, latency, and failure modes. The vision-loop pattern (screenshot → annotate → verify) that works for desktop automation is actually the general solution: always close the feedback loop through the external system's actual output, never trust the agent's model of what the external system should have done.

**Rule:** For any operation targeting an external system (Slack, Notion, browser, desktop), implement a verify-via-readback step: after the write/action, read the result back through the same external system's API/screenshot and confirm it matches intent before reporting success.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, 9e8b9158-842f-449f-8e35-5be120ba3e88, dd2e18ab-2182-4f88-8eab-354193b9e90a_

---
### Insight (conf=0.70)
> The WAL markdown-to-JSONL migration and the data-pipeline 'no hallucinated values' rule share a deeper principle: structured formats enforce honesty. Markdown's flexibility made it easy for agents to write plausible-looking but unparseable state; JSONL forces machine-verifiable structure. Similarly, requiring source citations for data values forces traceability. Both are instances of choosing constrained formats that make errors detectable rather than flexible formats that make errors invisible.

**Rule:** When choosing between a flexible human-readable format and a constrained machine-parseable format for any agent-produced artifact (state files, data outputs, configs), default to the constrained format. Flexibility in agent output is a bug, not a feature — it creates space for plausible-looking but incorrect output to go undetected.

_Patterns: 846615fc-eeb8-4a44-bf0a-bf06c723fde8, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 6fb0360d-b78d-4d97-ab65-325d2338ee68_

---


## Wake Cycle — 2026-05-03 04:56 UTC

### Insight (conf=0.55)
> Context limit hits correlate with fix-thrashing loops — when the agent repeatedly fails to identify root cause, it burns through context with redundant tool calls, triggering compaction earlier. The WAL migration to JSONL (machine-queryable) could enable detecting thrash loops by counting repeated edits to the same file within a WAL window, and auto-triggering a 'stop and re-read' interrupt before context is exhausted.

**Rule:** If WAL shows 3+ edits to the same file within 10 actions without an intervening test pass, emit a warning: 'Possible thrash loop detected — pause and re-read context before next edit.' This preserves context budget for actual progress.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.60)
> Terse continuation commands ('ahead', 'next', 'done') combined with long multi-session workflows create a 'cruise control' mode where the user is steering with minimal input while the agent does heavy lifting. This is the same interaction pattern as an autopilot — the user monitors but doesn't micromanage. The risk is that after compaction, the agent loses the 'cruise heading' and the terse commands become ambiguous. Core dumps should capture not just state but the current 'heading' — what the user's terse commands are expected to mean in context.

**Rule:** In /core-dump output, include a 'Current heading' section: a 1-2 sentence description of what terse continuations ('next', 'ahead') should mean when this checkpoint is restored. This prevents post-catchup ambiguity.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, 00fb690c-b719-4a18-ad08-94adf937ae00_

---
### Insight (conf=0.70)
> Data hallucination and Notion sync fragility share a root cause: the agent operates on a stale or incomplete mental model of external state and fills gaps with plausible fiction. In data pipelines it fabricates values; in Notion sync it assumes archive states or link formats. Both are 'confidence without verification' failures. The same discipline — never act on inferred external state, always re-read — applies to both domains.

**Rule:** Before writing any value derived from an external source (API response, data file, third-party sync state), the agent must have read that specific value in the current tool-call chain. No carried-over assumptions from prior turns or sessions. Applies equally to data pipelines and integration scripts.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 392f40af-8bf6-463f-a558-c5b68076c729, 9e8b9158-842f-449f-8e35-5be120ba3e88_

---
### Insight (conf=0.65)
> The vision loop for desktop automation (screenshot → annotate → act → verify) and the dashboard aesthetics iteration loop (implement → screenshot → feedback → adjust) are the same pattern: closed-loop control with visual feedback. The fix-thrashing anti-pattern breaks this loop by skipping the 'verify' step. All three converge on: never claim done without a visual confirmation step, and never retry without re-observing.

**Rule:** Any task involving visual output (UI changes, desktop automation, generated reports) must include a screenshot-verify step before reporting completion AND before retrying a failed approach. The verify step is not optional even under time pressure.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.60)
> Credentials leaking to files, wrong git org inference, and worktree data loss are all 'assumption carryover' bugs — the agent assumes something from conversation context is still true and acts on it destructively. The common fix is the same state-verification discipline: re-check before any irreversible operation. These three could be unified under a single 'verify before mutate' checkpoint.

**Rule:** Before any destructive or externally-visible operation (file write with sensitive data, git push, branch switch), run a verification triad specific to the operation: for git ops, check owner/status/diff; for file writes, grep for sensitive patterns; for worktree switches, check for unstaged changes. Never rely on conversation-context assumptions for these.

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5287886b-6995-4b9f-a22f-38e91d2a0ce4_

---
### Insight (conf=0.50)
> Fire-and-forget task notifications, recurring Slack MCP failures, and Notion sync fragility all point to the same gap: external integrations are treated as 'best effort' with no persistent health tracking. A task notification that arrives with 0 tools and 0 reply chars is indistinguishable from a silently failed integration. The pattern suggests a need for integration health signals — if an MCP server has failed N times across sessions, flag it as unreliable rather than retrying from scratch each time.

**Rule:** Maintain a per-MCP-server reliability score in memory. If an MCP server (Slack, Notion, etc.) has failed in 3+ sessions, note it as 'known-fragile' and front-load the diagnosis step rather than attempting normal use first. Saves the repeated discovery-of-failure cycle.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, 21f20909-472b-4445-9477-c0605accbe55, 9e8b9158-842f-449f-8e35-5be120ba3e88_

---
### Insight (conf=0.50)
> Data hallucination (fabricating values) and WAL/checkpoint corruption (wrong format, stale state) are both 'format fidelity' failures — the agent produces output that looks structurally correct but is semantically wrong. The WAL migration from markdown to JSONL was motivated by the same concern: markdown was too forgiving of structural ambiguity. The lesson generalizes: for any machine-consumed output (data pipelines, WAL, config files), use the strictest format available and validate on write.

**Rule:** For any machine-consumed output (JSONL, CSV, config files, data exports), validate the output against its schema immediately after writing — don't trust that the generation was correct. For JSONL: parse each line with jq. For CSV: verify column count matches header. For JSON configs: validate against expected keys.

_Patterns: ef57d880-da40-403d-b5bc-49ae318f35bd, 6fb0360d-b78d-4d97-ab65-325d2338ee68, 1523746a-7091-4022-b130-7e28b7f77561, 846615fc-eeb8-4a44-bf0a-bf06c723fde8_

---


## Wake Cycle — 2026-05-03 05:57 UTC

### Insight (conf=0.72)
> The game-theory simulation project's multi-agent architecture mirrors the session-continuation problem itself — both are distributed state machines that must reconstruct coherent state from partial observations across boundaries. The WAL migration to JSONL is essentially the same design pattern as a distributed commit log (Kafka, Raft) applied to agent memory. The user's project domain expertise likely influenced the sophistication of their session-continuity infrastructure.

**Rule:** When working on the geopolitical simulation project, explicitly map session-state concepts (WAL, checkpoint, catchup) to their in-game equivalents (event log, game state snapshot, turn reconstruction) — the user thinks in these terms and the analogy is bidirectional.

_Patterns: 881b161f-3ee0-4597-ab7b-d6c2a860613d, 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---
### Insight (conf=0.61)
> Data hallucination and context loss are the same failure mode at different abstraction levels. Core-dump failures lose session state causing the agent to 'hallucinate' what it was doing; data pipeline hallucination loses source provenance causing the output to fabricate values. Both are trust-destroying because the consumer cannot distinguish fabricated state from real state. The user's extreme sensitivity to data hallucination may stem from experiencing the same betrayal pattern with lost session context.

**Rule:** Treat context reconstruction (/catchup) with the same rigor as data pipeline provenance — every claim about 'what we were doing' must be traceable to a WAL entry or checkpoint, never inferred from partial signals. Flag reconstructed-but-unverified context the same way you'd flag inferred data values.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 392f40af-8bf6-463f-a558-c5b68076c729, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.78)
> Slack MCP and Notion sync share a 'recurring fragility' pattern that triggers the same thrash-loop anti-pattern. External service integrations that fail intermittently create a trap: each session re-attempts the fix without root-causing why it doesn't persist, burning context budget on the same problem. These are the integration equivalents of the 're-edit-thrash' mistake pattern.

**Rule:** For integrations with 2+ sessions of repeated failure (Slack MCP, Notion sync), the first action must be reading prior session notes for that integration — not re-attempting the fix. If the same root cause appears in 3+ sessions, escalate to a written postmortem in runtime-notes before any new fix attempt.

_Patterns: 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, 21f20909-472b-4445-9477-c0605accbe55, 9e8b9158-842f-449f-8e35-5be120ba3e88_

---
### Insight (conf=0.82)
> The user's terse command style and heavy session-continuity usage are co-adapted behaviors. Someone who works in 80-tool sessions across compaction boundaries optimizes for low-friction continuation — every word spent re-explaining context is waste. The terse protocol isn't just a communication preference; it's a throughput optimization for the multi-session workflow. Breaking terse protocol (asking clarifying questions) is especially costly for this user because it interrupts flow that took significant effort to reconstruct.

**Rule:** After /catchup, the threshold for asking clarifying questions should be even higher than normal — the user just spent effort restoring context and terse commands signal 'I know exactly where I am, keep moving.' Reserve questions for genuinely irreversible ambiguity only.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, c892fa80-f5af-4270-9e16-9225249062cc_

---
### Insight (conf=0.75)
> The vision-loop pattern for desktop automation and the data-provenance rule share a 'verify before claiming' invariant. In desktop automation, guessing coordinates without screenshots fails; in data pipelines, guessing values without source references fails; in UI iteration, claiming 'done' without a screenshot fails. All three are instances of: never assert state you haven't directly observed in this turn.

**Rule:** Generalize the vision-loop principle: any claim about current state (UI appearance, data value, file content) must be backed by a direct observation from the current turn, not memory of a prior turn. 'I set it to X' is not proof that X is the current state.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 1e5df293-bb35-4b57-b67e-d2640b80c314_

---
### Insight (conf=0.68)
> Worktree change loss, wrong-org pushes, and credential leaks are all 'state bleed' failures — actions taken in one context contaminating another. Worktrees bleed unstaged changes, orgs bleed from session memory, credentials bleed from conversation to files. The common root cause is assuming context isolation exists when it doesn't.

**Rule:** Before any operation that crosses a context boundary (switching worktrees, pushing to a remote, writing session data to files), run an explicit 'boundary check': what state from the source context could leak into the target? For worktrees: unstaged changes. For pushes: org/owner. For file writes: credentials or session-local values.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.55)
> Fire-and-forget task notifications and high-tool-count continuation sessions create a 'noise floor' problem — the signal-to-noise ratio in the conversation degrades as tool count increases and empty notifications accumulate. This is why compaction becomes necessary so frequently: not just because of context length, but because the useful information density drops as mechanical tool calls dominate.

**Rule:** When tool count in a session exceeds 40, proactively write a mid-session summary to runtime-notes capturing decisions and state — don't wait for compaction to force it. The summary is cheaper than reconstructing from a noisy WAL.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, f1057a8d-e978-416c-b52e-7ea8fd28e770, 00fb690c-b719-4a18-ad08-94adf937ae00_

---
### Insight (conf=0.65)
> The user runs at least three substantial long-lived projects (SvelteKit data pipeline, iDream dashboard, geopolitical simulation) concurrently. The session-continuity infrastructure isn't just for long sessions — it's for context-switching between projects. Each /catchup may be restoring not just session state but project state, making the WAL effectively a multi-tenant system.

**Rule:** WAL entries and core-dumps should always include the project identifier prominently — when the user runs /catchup, they may be switching projects, not just resuming. The first thing a catchup should surface is which project the checkpoint belongs to.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, c70ae766-c39a-442a-a15d-fbe84d854e0c, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---


## Wake Cycle — 2026-05-03 06:58 UTC

### Insight (conf=0.82)
> Context limits are hit frequently because the game-theory simulation project demands high tool-count sessions — the JSONL WAL migration was a direct evolutionary response to this pressure, optimizing for machine-parseable state recovery over human-readable logs. The project's complexity is the selection pressure driving the context-retention infrastructure.

**Rule:** For projects with >50 tool calls per session, auto-checkpoint at tool #25 (not #30) and switch to compact JSONL WAL entries that omit tool output bodies, keeping only tool name + result summary.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---
### Insight (conf=0.75)
> Data hallucination and fix-thrashing are the same underlying failure: acting without verified ground truth. Hallucinating a data value is 'acting without reading the source'; thrashing on a fix is 'acting without reading the root cause'. Both are confidence-without-verification failures that could be caught by the same gate: 'cite your source before emitting a value or a fix'.

**Rule:** Before emitting any derived/inferred value in a data pipeline OR attempting a second fix for the same failure, require an explicit source citation (file:line, API response field, or error message) in the reasoning. No citation = no emit.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.68)
> Three distinct signal types (terse user commands, fire-and-forget task notifications, and continuation directives) all share the same property: they are execution signals, not conversation. The system should classify incoming messages by signal-type before deciding whether to respond verbally or just act. A unified 'signal classifier' at turn start would reduce both unnecessary verbosity and unnecessary clarification requests.

**Rule:** At turn start, classify the incoming message as 'execute-signal' (terse directive, task notification, continuation) or 'conversation' (question, feedback, new request). For execute-signals, skip preamble and act immediately; for conversation, respond normally.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.72)
> The vision-loop pattern for desktop automation (screenshot → verify → act) and the data-pipeline integrity rule (cite source before emitting) are the same epistemological pattern applied to different domains: 'observe ground truth before asserting'. The dashboard aesthetics iteration loop is a third instance — the user demands visual verification before 'done'. This user's core trust model is observation-before-assertion across all domains.

**Rule:** Generalize the 'observe before assert' principle: before reporting any task complete, the agent must have performed at least one verification step that reads the actual output (screenshot for UI, file-read for data, curl for API, git diff for code changes). Never report done from memory alone.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 1e5df293-bb35-4b57-b67e-d2640b80c314_

---
### Insight (conf=0.65)
> Slack MCP and Notion sync share a pattern: external integration fragility that recurs across sessions without lasting resolution. Combined with the fix-thrashing anti-pattern, these suggest that some failures are infrastructural (not code bugs) and should be triaged differently — tagged as 'known-flaky-integration' rather than re-diagnosed each session.

**Rule:** Maintain a 'known-flaky' registry in memory. When an integration has failed in 3+ sessions without lasting fix, flag it at session start if the user's task touches that integration, and suggest workarounds rather than re-attempting the same diagnosis.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, 9e8b9158-842f-449f-8e35-5be120ba3e88, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.70)
> Credentials leaked to files, worktree operations losing unstaged changes, and wrong-org pushes are all 'irreversible side-effect from stale/wrong state' failures. They share a mitigation: a pre-side-effect checklist that verifies destructive preconditions. The git verification triad (status + log + diff) already exists for pushes — the same pattern should extend to file writes involving secrets and worktree switches.

**Rule:** Before any worktree switch: git stash --include-untracked. Before any file write in a session where credentials were shared: grep the content for known credential patterns. Before any push: verify owner/org from git remote -v, not from memory.

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.60)
> The user runs at least three large, long-lived projects simultaneously (iDream dashboard, SvelteKit data pipeline, game-theory simulation). The extreme reliance on session continuity tools isn't just preference — it's a consequence of high project-switching frequency. Each project switch is effectively a context loss event. The WAL/checkpoint system is functioning as a poor man's project-aware context manager.

**Rule:** At session start, if /catchup reveals a different project than the user's current working directory, proactively note the project mismatch and ask which project context to load, rather than blending stale context from project A into work on project B.

_Patterns: e181d5f7-4435-4c76-a1a4-82f3536aac19, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---


## Wake Cycle — 2026-05-03 09:08 UTC

### Insight (conf=0.72)
> The game theory / geopolitical simulation project's inherent complexity (multi-agent architecture, long-running state) is the primary driver of context exhaustion — the project's domain structure mirrors the session-management problem itself. Both are stateful multi-agent systems that must checkpoint and resume across boundaries. The user may benefit from applying the same state-machine patterns used in their simulation to the session-management infrastructure.

**Rule:** For projects with inherently stateful multi-agent architectures, trigger automatic /core-dump at tool call #25 (not #30) and again every 20 calls, since these domains consume context faster than typical CRUD work.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, e181d5f7-4435-4c76-a1a4-82f3536aac19_

---
### Insight (conf=0.81)
> The repeated, high-confidence data-hallucination patterns across multiple sessions suggest this is not individual mistakes but a systemic failure mode: post-compaction context loss destroys provenance chains. When the agent loses track of which source file a value came from (due to compaction), it fills gaps with plausible-looking fabrications. The hallucination problem and the context-continuity problem are the same problem.

**Rule:** In data pipeline sessions, /core-dump must include a 'provenance map' section listing every source file and which output columns derive from it. After any compaction in a data-pipeline session, re-read source files before writing any output — never rely on pre-compaction memory of data values.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 392f40af-8bf6-463f-a558-c5b68076c729, 6fb0360d-b78d-4d97-ab65-325d2338ee68, ef57d880-da40-403d-b5bc-49ae318f35bd_

---
### Insight (conf=0.78)
> The user's terse single-word commands and the heavy session-continuation pattern are co-adapted behaviors: the user has learned that verbose instructions waste context tokens in long sessions. Brevity is not laziness — it is context-budget conservation by a user who knows their sessions hit limits. The agent should interpret terseness as a signal of context-pressure, not ambiguity.

**Rule:** When a session has already crossed 1 compaction boundary AND the user sends terse continuations, reduce agent verbosity by ~50% (shorter confirmations, skip insight boxes, minimize status updates) to conserve context budget.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, 00fb690c-b719-4a18-ad08-94adf937ae00_

---
### Insight (conf=0.95)
> Four independent patterns all record the same WAL markdown→JSONL migration, which indicates the migration was a high-friction event that touched many sessions. The redundancy itself is a signal: the pattern-extraction system lacks deduplication, and these four entries are consuming budget that could track novel patterns.

**Rule:** Deduplicate patterns that share >80% semantic overlap before presenting them for analysis. Merge these four WAL-migration patterns into a single canonical entry and free 3 pattern slots.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 0629319a-4440-4d1b-bad4-5ad0db93399a, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 846615fc-eeb8-4a44-bf0a-bf06c723fde8_

---
### Insight (conf=0.68)
> The 'fix without root cause' anti-pattern and the recurring Notion/Slack integration failures are linked: external service integrations are where root-cause analysis is hardest (opaque APIs, auth flows, rate limits), so the agent falls back to trial-and-error. These domains need a different debugging strategy — log-first investigation rather than edit-retry loops.

**Rule:** When debugging external service integrations (MCP connections, API sync scripts, OAuth flows), the first 3 tool calls must be read-only diagnostics (check logs, verify credentials, test connectivity). No code edits until a root cause hypothesis is written down.

_Patterns: 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, 9e8b9158-842f-449f-8e35-5be120ba3e88, 21f20909-472b-4445-9477-c0605accbe55_

---
### Insight (conf=0.62)
> The desktop automation vision-loop pattern and the dashboard aesthetics iteration pattern are the same feedback loop at different abstraction levels: screenshot → evaluate → adjust → verify. The iDream dashboard work would benefit from the same structured loop used in desktop automation — take a screenshot, annotate what needs to change, make the change, screenshot again to verify — rather than ad-hoc 'does this look right?' cycles.

**Rule:** For UI aesthetic iteration sessions, adopt the desktop-automation vision loop: (1) screenshot current state, (2) annotate specific coordinates/elements to change, (3) edit code, (4) screenshot to verify. Report 'done' only after a verification screenshot matches intent.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.74)
> Three different 'verify before mutating shared state' failures — worktree losing unstaged changes, wrong repo owner on push, credentials written to files. These are all the same class: the agent assumed current state matched its mental model without checking. The state-verification rule exists but is only triggered for git push, not for these adjacent operations.

**Rule:** Extend the git verification triad to all shared-state mutations: before any worktree switch, check `git stash list` + `git status`; before any repo operation, verify owner with `gh repo view --json owner`; before any file write in a data session, grep the content for credential-shaped strings.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.65)
> Fire-and-forget task notifications arriving with 0 tools and 0 reply chars are wasting context slots in sessions that are already context-starved from heavy continuation patterns. Each empty notification consumes conversation history that could hold useful state. These should be filtered or compressed at the infrastructure level.

**Rule:** Task notification messages with 0 tools and 0 substantive content should be batched and summarized rather than occupying individual conversation turns. When 3+ empty notifications arrive in sequence, compress them into a single status line.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, f1057a8d-e978-416c-b52e-7ea8fd28e770, 1523746a-7091-4022-b130-7e28b7f77561_

---
### Insight (conf=0.70)
> The SvelteKit data pipeline project is the specific context where most data-hallucination incidents occurred — eBay/JEGS parts data with many nullable fields and cross-source joins creates the ideal conditions for plausible-looking fabrication. The hallucination risk isn't uniform across all data work; it spikes in this specific domain because parts data has predictable patterns (part numbers, prices, fitment) that an LLM can convincingly fake.

**Rule:** In the SvelteKit parts-data project specifically, every data transformation must include a row-count assertion (input rows == output rows unless explicitly filtering) and a null-count check (nulls in output <= nulls in source for each column). Fail loudly rather than fill silently.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, 6fb0360d-b78d-4d97-ab65-325d2338ee68, 1e5df293-bb35-4b57-b67e-d2640b80c314_

---


## Wake Cycle — 2026-05-03 10:43 UTC

### Insight (conf=0.72)
> The context-limit problem and the game-theory simulation project are structurally isomorphic: both involve agents operating with bounded information windows that must reconstruct state from logs. The WAL migration to JSONL mirrors how real distributed systems solve the same problem — append-only logs with structured replay. The user's dev workflow is itself a distributed system with the same consistency challenges as the software they build.

**Rule:** Treat session state management with the same rigor as production distributed system state: structured logs (JSONL WAL), idempotent replay (/catchup), and checkpoint-before-partition (/core-dump before context limit). Never rely on implicit in-memory state across boundaries.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---
### Insight (conf=0.78)
> Data hallucination and post-compaction state hallucination share the same root cause: the agent fills gaps in its knowledge with plausible-sounding fabrications rather than admitting incomplete information. Core-dump at milestones prevents state hallucination the same way source-tracing prevents data hallucination. Both are 'fill the gap' failures.

**Rule:** After any information boundary (context compaction, session restart, or data source change), treat all previously-held state as unverified. Re-read before asserting. The same 'never fabricate, always trace to source' rule that applies to data pipelines applies to session state.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.68)
> Terse continuation commands and root-cause-skipping thrash loops are opposite failure modes of the same autonomy spectrum. The user signals 'execute don't discuss' with single-word commands, but the agent sometimes over-executes by retrying without diagnosis. The fix isn't less autonomy — it's autonomy with a circuit breaker: execute freely on the happy path, but auto-pause after N failed attempts on the same target.

**Rule:** Honor terse commands as execution signals, but install a 3-strike circuit breaker: if the same fix target fails 3 times consecutively, pause and report root-cause analysis before attempting again, even if the user said 'again'.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.82)
> The vision loop for desktop automation, the dashboard aesthetic iteration loop, and the data-traceability rule all express the same principle: never assert a result without observing it. Screenshots before claiming UI done, rendering before judging values, annotating before clicking coordinates — all are instances of 'observe-then-act, never act-then-assume'.

**Rule:** Before reporting any result as complete — UI change, data transformation, or automated action — verify via direct observation (screenshot, rendered output, re-read). Never claim success based on the action taken; claim it based on the outcome observed.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 1e5df293-bb35-4b57-b67e-d2640b80c314_

---
### Insight (conf=0.65)
> Slack MCP and Notion sync share a pattern of recurring fragility where fixes don't stick across sessions. Combined with the thrash-loop anti-pattern, these represent 'Sisyphus integrations' — external service connections where the agent repeatedly patches symptoms without addressing the structural instability. The root cause is likely that session-local fixes (env vars, auth tokens, process restarts) don't persist, and the WAL/checkpoint system doesn't capture integration health state.

**Rule:** For integrations that fail across multiple sessions (Slack MCP, Notion sync), escalate to a persistent diagnostic document after the second failure session. Record: what was tried, what temporarily worked, what the structural blocker is. Stop re-diagnosing from scratch each session.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, 9e8b9158-842f-449f-8e35-5be120ba3e88, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.75)
> Worktree data loss, wrong-org pushes, and credential leaks are all 'blast radius from stale assumptions' failures. The agent assumed state (clean worktree, correct org, no secrets in buffer) based on earlier context rather than verifying at the moment of action. These cluster into a single class: pre-action state verification failures.

**Rule:** Before any destructive or externally-visible git operation (push, worktree switch, branch create), run the verification triad (status + log + diff) AND verify the target (remote URL, org/owner, branch name) from live state, not memory.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.60)
> Fire-and-forget task notifications, high tool counts per turn, and frequent session continuations suggest the user's workflow resembles an event-driven system more than a request-response conversation. The agent should optimize for event processing (acknowledge, update state, continue) rather than dialogue (explain, discuss, confirm).

**Rule:** When tool count per turn exceeds 20 or session continuation patterns appear, switch to event-processing mode: minimize explanatory text, maximize state updates (WAL entries, checkpoints), and treat each user message as a work-item dispatch rather than a conversation turn.

_Patterns: 2e7d5054-603d-4ba1-92cb-41bca5de2463, f1057a8d-e978-416c-b52e-7ea8fd28e770, 00fb690c-b719-4a18-ad08-94adf937ae00_

---
### Insight (conf=0.58)
> The user maintains three distinct long-running projects (iDream dashboard, SvelteKit data pipeline, game-theory simulation) that all require heavy session continuity. The context restoration cost scales with project count — each /catchup must disambiguate which project's state to load. This suggests the WAL/checkpoint system needs project-scoped partitioning, not a single global timeline.

**Rule:** When multiple long-running projects coexist, scope WAL and checkpoint files per project directory rather than globally. At /catchup, auto-detect project from CWD and load only the relevant partition to reduce noise and reconstruction time.

_Patterns: c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---


## Wake Cycle — 2026-05-03 13:07 UTC

### Insight (conf=0.72)
> Context limit hits correlate with fix-thrash loops — large complex projects (game theory sim) cause more debugging cycles, which burn context faster, which forces more session continuations, which lose the debugging context needed to break the loop. The context boundary itself may be *causing* repeated fix attempts by erasing root-cause understanding.

**Rule:** When a fix-attempt loop reaches iteration 3, force a /core-dump before continuing — this both triggers the 'stop and diagnose root cause' rule AND preserves the diagnosis across a potential compaction boundary.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.55)
> Context reconstruction after session boundaries is itself a data-hallucination risk. When the agent rebuilds state from checkpoints and WAL entries, it may 'fill in' details that weren't preserved — the same failure mode as hallucinating data values in pipelines. The user's extreme sensitivity to fabricated data values may partly stem from experiencing this in session handoffs.

**Rule:** After /catchup, explicitly flag any state assumptions that couldn't be verified from the checkpoint file with '[unverified from prior session]' rather than presenting reconstructed context as known fact.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, 00fb690c-b719-4a18-ad08-94adf937ae00_

---
### Insight (conf=0.61)
> The user has developed a minimal-signal communication style that mirrors the fire-and-forget pattern of async task notifications. Both terse human commands and task-completion signals carry maximum intent in minimum tokens. This suggests the user optimizes for context-window efficiency even in their own messages — every token in the conversation is 'expensive' to them.

**Rule:** Treat user message brevity as a context-budget signal — respond with proportionally fewer tokens, and prefer tool actions over explanatory text when the user is in terse mode.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.78)
> The vision-loop pattern for desktop automation (screenshot → verify → act) and the dashboard aesthetic iteration pattern share the same underlying principle as the data-hallucination prohibition: never claim something is true without direct evidence. Guessing coordinates = hallucinating position. Reporting UI done without screenshot = hallucinating appearance. Fabricating API results = hallucinating data. All three are 'assertion without observation' failures.

**Rule:** Unify under a single meta-rule: 'Never assert state without observation.' Before claiming any output is correct — data values, UI appearance, coordinate positions, API responses — produce or read direct evidence. If evidence can't be obtained, say so.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, ef57d880-da40-403d-b5bc-49ae318f35bd_

---
### Insight (conf=0.65)
> Credentials, git remotes, and config values all share a 'provenance sensitivity' property — they must come from an authoritative source, not inference. The agent has separate rules for each, but they're all instances of: 'values that connect to external systems must be explicitly sourced, never inferred from context.' This parallels the data-hallucination rules but in the infrastructure domain.

**Rule:** Any value that acts as a system identifier or credential (git remote, org name, API key, config endpoint) must be read from its canonical source before use — never carried forward from prior session state or inferred from naming patterns.

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 8a148c96-b879-495a-a1be-5c9ab42374d6_

---
### Insight (conf=0.58)
> Git worktree data loss and context-window compaction are structurally identical problems: both involve switching execution contexts (branch/worktree vs. conversation window) where uncommitted state gets silently dropped. The user's heavy investment in checkpoint infrastructure may have been partly motivated by worktree-switching incidents — the /core-dump is a 'git stash' for conversation state.

**Rule:** Before any context switch (worktree change, compaction, new agent spawn), run the equivalent of 'git stash' for that domain: /core-dump for conversation, git stash for worktrees, checkpoint for long-running processes.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, e218ac38-3844-4295-a972-c9dc01b22d13, c892fa80-f5af-4270-9e16-9225249062cc_

---
### Insight (conf=0.70)
> The user maintains multiple complex, long-running projects simultaneously (game theory sim, SvelteKit data pipeline, iDream dashboard). Each requires deep domain context that can't be reconstructed from code alone. This multi-project pattern explains why session continuity tools are so heavily used — they're not just for long sessions within one project, but for rapid project-switching across sessions.

**Rule:** Core dumps should include a 'project identity' header (project name, key tech stack, current milestone) so /catchup can orient to the right project context in under 5 seconds, even when the user switches between projects across sessions.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, b76b7252-944d-49f8-bb01-fa76c140a694, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---


## Wake Cycle — 2026-05-03 14:25 UTC

### Insight (conf=0.72)
> Context limit hits correlate with fix-thrash loops — large complex projects (game theory sim) cause deep debugging sessions that burn context on repeated failed fixes, triggering premature compaction. Reducing thrash (root-cause-first rule) would also reduce context exhaustion frequency.

**Rule:** After 3 failed fix attempts in a single context window, force a /core-dump checkpoint before continuing — this both prevents context exhaustion and forces a pause for root-cause analysis.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.55)
> The WAL→JSONL migration and the fire-and-forget task notifications share a design principle: machine-queryable structured formats beat human-readable prose for automated state reconstruction. The zero-tool notification pattern suggests the system already treats some messages as pure signals — WAL entries could adopt a similar signal/payload separation.

**Rule:** WAL entries should distinguish 'signal' entries (session_start, heartbeat) from 'payload' entries (action, decision) — catchup can skip signals for faster reconstruction while keeping them for audit.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, 1523746a-7091-4022-b130-7e28b7f77561, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.68)
> The 'no hallucinated data' rule and the 'core-dump at milestones' rule address the same root problem from different angles: state that exists only in volatile context (conversation memory) is untrusted state. Data values held only in the agent's 'memory' of a source file are as dangerous as unsaved session progress — both vanish on compaction and get reconstructed unreliably.

**Rule:** When a data transformation pipeline spans a compaction boundary, re-read source files after catchup rather than relying on pre-compaction memory of their contents — treat data values in conversation context as ephemeral, same as session state.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 392f40af-8bf6-463f-a558-c5b68076c729, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.61)
> The terse-command pattern and the iterative-aesthetics pattern are in tension: terse signals mean 'continue autonomously', but dashboard UI iteration requires the agent to pause and screenshot-verify before continuing. The resolution is that terse commands after a screenshot mean 'approved, next change' while terse commands mid-implementation mean 'keep building'.

**Rule:** In UI iteration loops, a terse continuation after showing a screenshot means 'visually approved — proceed to next item'. A terse continuation mid-code means 'keep implementing without pausing for visual check'. Context determines whether to screenshot or skip.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6_

---
### Insight (conf=0.74)
> Slack MCP and Notion sync share a pattern of recurring fragility that triggers fix-thrash loops. These are external integration boundaries where the agent repeatedly attempts repairs without lasting success — suggesting the root cause is environmental (auth tokens expiring, API changes) rather than code-level. The thrash pattern from 6abc applies specifically to external service integrations.

**Rule:** For external service integrations that fail 2+ times across sessions (Slack MCP, Notion sync), stop debugging code and check environmental prerequisites first: token expiry, API version changes, network/firewall state. Log the environmental check result to runtime-notes so the next session doesn't repeat the same diagnosis.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, 9e8b9158-842f-449f-8e35-5be120ba3e88, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.78)
> The vision-loop validation pattern for desktop automation and the anti-hallucination rule for data pipelines are the same principle in different domains: never act on inferred state, always verify from ground truth before proceeding. Screenshot-before-click mirrors read-source-before-transform.

**Rule:** Generalize as 'ground-truth-first' principle: before any action that depends on state (screen coordinates, data values, file contents, git status), read the actual state from its canonical source. Never act on remembered or inferred state.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, ef57d880-da40-403d-b5bc-49ae318f35bd_

---
### Insight (conf=0.70)
> Worktree data loss, wrong-org pushes, and credential leaks are all 'side-effect on wrong target' errors — the agent acts on an incorrect mental model of what it's operating on. They share a common fix: verify the target identity (branch state, repo owner, file destination) immediately before any irreversible side effect.

**Rule:** Before any write to an external target (git push, file export, credential use), verify target identity in the same tool call sequence — never rely on earlier-in-session state for push target, branch name, or output path.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.63)
> Both the SvelteKit data pipeline project and the iDream dashboard project enforce 'use the project's config system' — suggesting the user maintains multiple long-lived projects with established conventions. New code in either project must discover and follow the existing config pattern, not introduce ad-hoc alternatives. This is a cross-project convention, not project-specific.

**Rule:** When adding config/env values to any established project, grep for the existing config pattern (Config class, .env loader, settings module) before writing the first line — match the existing mechanism, never introduce a parallel one.

_Patterns: 8a148c96-b879-495a-a1be-5c9ab42374d6, b76b7252-944d-49f8-bb01-fa76c140a694, c70ae766-c39a-442a-a15d-fbe84d854e0c_

---
### Insight (conf=0.65)
> The dev server on localhost:5173 is a long-lived process that persists across the multi-session workflows. When catchup reconstructs context, it should verify dev server state (is pm2/vite still running? is the port still bound?) as part of the restoration — stale server state after machine sleep or reboot is a likely silent failure mode.

**Rule:** Include dev server health check (pm2 status, port liveness) as part of /catchup restoration for projects with known long-running services — don't assume servers survived between sessions.

_Patterns: e181d5f7-4435-4c76-a1a4-82f3536aac19, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, 07e91a34-f2bd-4d49-8ac8-b81f1d0cd808_

---


## Wake Cycle — 2026-05-03 15:27 UTC

### Insight (conf=0.65)
> The context-limit problem is amplified by project complexity — the game theory simulation's multi-agent architecture generates more state per turn than typical projects, which accelerated the WAL markdown→JSONL migration. Complex domain projects may need domain-aware compression (e.g., summarizing agent-state diffs rather than raw tool calls) to extend effective context window.

**Rule:** For projects with >5 interacting subsystems, core-dump should include a domain-state summary section (key entities and their current state) in addition to the tool-call log, since raw tool history compresses poorly when many subsystems are touched per session.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---
### Insight (conf=0.72)
> Data hallucination risk increases after context compaction — when the agent loses access to source data that was read earlier in the session, it may reconstruct values from memory rather than re-reading. The same state-loss mechanism that makes /core-dump necessary also creates the conditions for hallucinated data values.

**Rule:** After any context compaction during a data-processing task, the agent must re-read source files before producing output — never rely on pre-compaction memory of data values. Core-dump for data tasks should record source file paths and row counts, not data values themselves.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 10b7a87a-5217-44e1-be13-e9acb9c24ae8, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.68)
> Fix-thrash loops and persistent tool failures (like Slack MCP) share a root cause with context limits: the agent loses memory of what was already tried. Across sessions, the same diagnostic sequence repeats because no durable 'already tried X, it failed because Y' record persists. The WAL captures actions but not negative results.

**Rule:** When a tool or integration fails after 2+ attempts in a session, write a 'negative finding' entry to runtime-notes with the failure mode and root cause hypothesis. On /catchup, surface negative findings for the active domain so the agent doesn't re-attempt known-broken paths.

_Patterns: 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, 5c3499d0-aef9-4924-b559-e15bf88068ed, 21f20909-472b-4445-9477-c0605accbe55_

---
### Insight (conf=0.55)
> Terse user messages and zero-tool notification signals are both instances of 'high-signal, low-bandwidth communication.' The user has optimized their interaction to minimal keystrokes, and the system's async notifications mirror this pattern. This suggests the entire UX should be optimized for continuation-as-default — any prompt that requires more than one word to answer is a friction point.

**Rule:** When the agent needs user input mid-task, frame it as a yes/no or pick-one — never open-ended. The user's communication style shows they prefer to steer with single words, so questions should be answerable with one.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.78)
> The vision-loop pattern for desktop automation and the dashboard aesthetics iteration loop are the same meta-pattern: render→verify→adjust. The data hallucination prohibition is the negative case of this same principle — when you skip the 'verify against ground truth' step, you get fabricated values. All three domains enforce 'never trust internal state, always verify against the real artifact.'

**Rule:** Before reporting any generated output as correct — UI screenshot, data transform result, or automation action — verify against the actual artifact (re-read the file, take the screenshot, query the API). Internal confidence is not verification.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 392f40af-8bf6-463f-a558-c5b68076c729_

---
### Insight (conf=0.74)
> Git owner inference, worktree state loss, and credential leakage are all 'stale assumption' bugs — the agent acts on context it believes is current but isn't. These cluster around operations where the blast radius is high (wrong repo, lost changes, leaked secrets) and the state verification cost is low (one command). The common fix is mandatory pre-flight checks for irreversible operations.

**Rule:** Before any operation that touches external state (push, worktree switch, file write with sensitive content), run the cheapest possible verification of the assumption being relied on — git remote -v for repo identity, git stash list for uncommitted work, grep for credential patterns before commit.

_Patterns: bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, 5287886b-6995-4b9f-a22f-38e91d2a0ce4, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.58)
> Notion sync and Slack MCP are both external-system integrations that break across sessions because their failure modes aren't captured in the project's own codebase — they live in config, auth tokens, and API quirks. The SvelteKit data pipeline (eBay/JEGS) likely has similar fragility at its external boundaries. External integration debugging needs its own persistence layer beyond code commits.

**Rule:** For each external integration (Notion, Slack, eBay API, etc.), maintain a 'known quirks' section in runtime-notes with last-known-good config, common failure modes, and recovery steps. This survives across sessions where code-level debugging notes don't.

_Patterns: 9e8b9158-842f-449f-8e35-5be120ba3e88, 21f20909-472b-4445-9477-c0605accbe55, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.70)
> The config-system bypass and data hallucination patterns share a deeper cause: the agent takes shortcuts when the 'correct' path requires reading more context. Inline os.environ.get() is faster than finding the Config class; inventing a plausible value is faster than re-reading the source CSV. Both are 'lazy path' errors that trade correctness for speed under context pressure.

**Rule:** When the agent is about to introduce a value or pattern that doesn't reference an existing source (config class, source file, API response), treat it as a smell — pause and search for the established pattern first. The 30 seconds spent finding the right abstraction prevents the trust-destroying shortcut.

_Patterns: 8a148c96-b879-495a-a1be-5c9ab42374d6, 1e5df293-bb35-4b57-b67e-d2640b80c314, 6fb0360d-b78d-4d97-ab65-325d2338ee68_

---


## Wake Cycle — 2026-05-03 16:50 UTC

### Insight (conf=0.55)
> The game theory / geopolitical simulation project's multi-agent architecture creates an environment where data hallucination is especially dangerous — agents in a simulation passing fabricated state to each other would compound errors exponentially, unlike a single-pipeline hallucination. The same 'no inference without source' rule that applies to data pipelines should apply to inter-agent state handoffs in the simulation.

**Rule:** In multi-agent simulation projects, every state value passed between agents must carry a provenance tag (source agent + turn number). Untraceable values are treated as hallucinations and rejected at the receiving agent's boundary.

_Patterns: 58112601-ddbc-4e20-a6ea-6987c6c96569, 1e5df293-bb35-4b57-b67e-d2640b80c314, 392f40af-8bf6-463f-a558-c5b68076c729_

---
### Insight (conf=0.72)
> The WAL migration from markdown to JSONL mirrors the data-hallucination concern: unstructured formats (markdown) allow ambiguous or 'hallucinated' state reconstruction during /catchup, while structured formats (JSONL) enforce that every recovered state value is directly traceable to a logged event. The WAL format choice is itself an anti-hallucination measure for session state.

**Rule:** WAL entries should include a 'source' field (tool call ID, user message index, or checkpoint hash) so /catchup can distinguish verified state from inferred state during reconstruction — applying the same provenance discipline used for data pipelines.

_Patterns: afd64ee1-38a2-4b53-9f23-5e49df3fdcca, c14d3a47-9a39-4f3b-92ec-3ad016c1dd26, 1e5df293-bb35-4b57-b67e-d2640b80c314_

---
### Insight (conf=0.78)
> Thrash loops (repeated fix attempts without root-cause analysis) and context-limit hits are correlated — thrashing burns context tokens on failed attempts, which accelerates compaction, which loses the diagnostic context needed to break the loop. The fix-attempt-without-root-cause pattern is not just inefficient, it's actively destructive to session continuity.

**Rule:** After 2 failed fix attempts on the same issue, write a /core-dump checkpoint BEFORE the 3rd attempt. This preserves diagnostic context against the compaction that thrashing makes likely, and forces a pause that often reveals the root cause.

_Patterns: 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, 5c3499d0-aef9-4924-b559-e15bf88068ed, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.65)
> Terse user commands, fire-and-forget task notifications, and autonomous-continue signals form a unified 'low-ceremony interaction protocol.' The user's workflow is optimized for minimal interruption — they treat the agent like a running process they send signals to, not a conversational partner. This suggests the agent should model itself more like a daemon (signal-driven, state-persistent) than a chatbot (turn-driven, stateless).

**Rule:** When 3+ consecutive user messages are single-word continuations, switch to 'daemon mode': suppress all confirmations, report only errors and completion, auto-checkpoint every 15 tool calls. Exit daemon mode on the first multi-sentence user message.

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.82)
> The vision-loop pattern for desktop automation (screenshot → verify → act) and the dashboard aesthetics iteration pattern share the same principle as the anti-hallucination rule: never claim a state you haven't directly observed. 'Render before judge' for UI, 'screenshot before click' for automation, and 'cite source before output' for data are all instances of the same meta-rule: observation must precede assertion.

**Rule:** Unify under a single meta-principle: 'No assertion without observation.' Before claiming any state (data value, UI appearance, click target, build success), the agent must have a tool-call result from THIS turn that confirms it. Prior-turn observations are stale by default.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, ef57d880-da40-403d-b5bc-49ae318f35bd_

---
### Insight (conf=0.70)
> Slack MCP failures and Notion sync fragility are both external-integration patterns that trigger the thrash-loop anti-pattern. External integrations have failure modes the agent can't inspect (auth token expiry, API rate limits, server-side state), so the 'stop and find root cause' rule needs a special case: for external integrations, the root cause may be unreachable, and the correct action is to report and stop rather than diagnose endlessly.

**Rule:** For external integration failures (MCP connections, API syncs, OAuth flows): after 2 failed attempts, stop and report with full error context rather than continuing to diagnose. The root cause is likely outside the agent's observability boundary.

_Patterns: 21f20909-472b-4445-9477-c0605accbe55, 9e8b9158-842f-449f-8e35-5be120ba3e88, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.68)
> Worktree changes lost, wrong repo owner inferred, and credentials accidentally persisted are all 'contamination across boundaries' failures — state from one context (branch, org, session) leaking into another. The session-continuation-heavy workflow amplifies this risk because long multi-session work accumulates implicit assumptions about 'current context' that silently go stale.

**Rule:** At every /catchup restoration, explicitly re-verify three boundary values: current git branch + remote, working directory identity, and whether any credentials or secrets are in the environment. These are the three most common stale-context contamination vectors.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.52)
> The config-system violation pattern (using os.environ.get instead of the project's Config class) is more likely to occur when the agent switches between the iDream dashboard project (Node/MongoDB) and the SvelteKit data pipeline project (Python). Each project has different config idioms, and cross-project muscle memory causes the agent to reach for the wrong pattern.

**Rule:** When resuming work on a project after working on a different one in the same session, grep for the project's config pattern (Config class, .env loader, settings module) before writing any new file that needs configuration values.

_Patterns: 8a148c96-b879-495a-a1be-5c9ab42374d6, c70ae766-c39a-442a-a15d-fbe84d854e0c, b76b7252-944d-49f8-bb01-fa76c140a694_

---
### Insight (conf=0.63)
> The dev server (localhost:5173) restart pattern and the dashboard aesthetics iteration pattern together suggest that the user's inner loop is: change → screenshot → judge → repeat. If the dev server crashes or stales between context compactions, the entire verification loop breaks silently. Dev server health should be a first-class checkpoint item alongside git state.

**Rule:** Include dev server health (port check + HTTP 200 on known route) in the /catchup restoration sequence for projects with active dev servers. A stale dev server after compaction leads to verifying against cached/old UI state.

_Patterns: fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 7afe9252-1435-4ae4-8141-9fb51d2187f6_

---


## Wake Cycle — 2026-05-03 19:08 UTC

### Insight (conf=0.72)
> The game theory/geopolitical simulation project's multi-agent architecture mirrors the session continuity problem itself — both are distributed state machines that must reconstruct shared context after interruption. The WAL migration to JSONL parallels how distributed systems move from human-readable logs to machine-queryable event stores when coordination complexity exceeds manual parsing.

**Rule:** For projects with multi-agent architectures, auto-increase checkpoint frequency proportional to agent count — each additional simulated agent multiplies state that's lost on context boundary crossing.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---
### Insight (conf=0.78)
> Data hallucination and session state loss share a root cause: the agent operating on stale/absent ground truth. Core dumps at milestones prevent 'state hallucination' (acting on beliefs about project state that are no longer true post-compaction) the same way source-tracing prevents data hallucination. Both are confidence-without-verification failures.

**Rule:** After any compaction or context restoration, treat all prior beliefs about file contents, process state, and data values as unverified claims requiring a fresh read — apply the same 'no inference without source' discipline used for data pipelines to session state itself.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, ef57d880-da40-403d-b5bc-49ae318f35bd, e218ac38-3844-4295-a972-c9dc01b22d13_

---
### Insight (conf=0.65)
> The user's communication style forms a protocol spectrum: single-word messages are 'continue' signals, zero-tool notifications are 'ack' signals, and /catchup is a 'sync' signal. This maps to TCP-like flow control — the user is the sender using minimal-bandwidth signals to keep the agent pipeline moving without stalling on unnecessary round-trips.

**Rule:** Classify incoming messages by signal type before processing: 0-tool notifications = no-op ack (don't respond substantively), 1-3 word messages = continue/approve (execute immediately), /catchup or /core-dump = protocol-level sync (prioritize state reconstruction over task work).

_Patterns: 556fbc99-c295-493f-8b7a-218b2f5e964f, 6ebe732c-7eb4-456a-819c-55549a289e00, 2e7d5054-603d-4ba1-92cb-41bca5de2463_

---
### Insight (conf=0.81)
> Thrash loops on fix attempts, recurring Slack MCP failures, and Notion sync fragility are all instances of 'infrastructure debt that masquerades as individual bugs'. Each session re-discovers the same failure without resolving the systemic issue because session boundaries reset the investigation context. The continuity tools solve task continuity but not diagnostic continuity.

**Rule:** When a tool/integration fails and has failed in prior sessions (check runtime-notes), escalate from 'fix this instance' to 'document the systemic failure mode' — write a dedicated known-issues entry rather than attempting another point fix that won't survive the session.

_Patterns: 6abc30fa-b5cd-4992-9e06-90f5ca8b0644, 21f20909-472b-4445-9477-c0605accbe55, 9e8b9158-842f-449f-8e35-5be120ba3e88_

---
### Insight (conf=0.85)
> The vision-loop pattern for desktop automation (screenshot → verify → act) and the dashboard aesthetics iteration pattern share the same principle as the anti-hallucination rule: never claim a state without observing it. All three are instances of 'render-before-judge' — the agent must ground its claims in observable reality rather than internal model predictions.

**Rule:** Unify render-before-judge across all domains: data values need source citations, UI changes need screenshots, desktop automation needs coordinate verification, and post-compaction state needs fresh reads. The common abstraction is: 'no assertion without observation at the same temporal scope'.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 10b7a87a-5217-44e1-be13-e9acb9c24ae8_

---
### Insight (conf=0.76)
> Worktree state loss, wrong-org pushes, and credential leaks are all 'assumption about invisible state' errors — the agent acts on a mental model of the environment that diverges from reality. They cluster around operations where the cost of verification seems low but the cost of being wrong is high. The common fix is a mandatory pre-flight check, but each domain needs its own checklist.

**Rule:** Before any operation that crosses a trust boundary (local→remote, memory→disk, branch→branch), run a domain-specific pre-flight: git ops get the verification triad, file ops get a existence check, auth ops get a 'is this the right target' confirmation. Never inherit verification from a prior tool call.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46, afe8a2d8-17b3-42bc-973d-eac449588f9b_

---
### Insight (conf=0.74)
> The config-system enforcement rule and the data-traceability rules are the same principle applied at different layers: every value in the system must have a single authoritative source. Inline os.environ.get() is 'config hallucination' — it creates a value pathway that bypasses the project's source-of-truth, just as data inference creates values that bypass the source dataset.

**Rule:** Apply single-source-of-truth discipline uniformly: config values flow through the Config class, data values trace to source columns, environment state traces to fresh reads. Any value that 'shortcuts' its canonical source path should be flagged as potentially ungrounded.

_Patterns: 8a148c96-b879-495a-a1be-5c9ab42374d6, 392f40af-8bf6-463f-a558-c5b68076c729, 6fb0360d-b78d-4d97-ab65-325d2338ee68_

---


## Wake Cycle — 2026-05-03 20:28 UTC

### Insight (conf=0.72)
> The geopolitical simulation project's inherent complexity (multi-agent architecture) may be the root cause of context limit hits, not session tooling deficiency. The project's domain complexity creates a minimum viable context size that exceeds single-window capacity, and when context is lost mid-task, it triggers the same 'fix without root cause' thrash pattern seen in code — but applied to context reconstruction itself. The real bottleneck isn't checkpoint fidelity, it's task decomposition granularity.

**Rule:** For projects with >5 interacting modules, break implementation into sub-tasks that each fit within a single context window (~80 tool calls). Write a task manifest at session start listing atomic units; each unit should be completable without needing cross-unit state.

_Patterns: 5c3499d0-aef9-4924-b559-e15bf88068ed, 58112601-ddbc-4e20-a6ea-6987c6c96569, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.68)
> The WAL migration from markdown to JSONL and the data hallucination prohibition share the same underlying principle: structured, machine-queryable formats prevent silent corruption. Markdown WALs allowed ambiguous state reconstruction (analogous to hallucinated data filling gaps), while JSONL enforces explicit field presence. The same 'no inference without source' rule that applies to data pipelines should apply to session state recovery — never reconstruct state that isn't explicitly checkpointed.

**Rule:** When restoring session state via /catchup, explicitly flag any state that is inferred rather than directly read from WAL/checkpoint. Mark inferred state with [INFERRED] so the agent knows to verify before acting on it, mirroring the data pipeline rule of never presenting synthesized values as factual.

_Patterns: 1e5df293-bb35-4b57-b67e-d2640b80c314, 392f40af-8bf6-463f-a558-c5b68076c729, afd64ee1-38a2-4b53-9f23-5e49df3fdcca_

---
### Insight (conf=0.75)
> The vision-loop pattern for desktop automation (screenshot → verify → act) and the dashboard aesthetics iteration loop are the same feedback cycle applied at different abstraction levels. Both encode the principle 'render-before-judge' — and both break catastrophically when skipped (coordinate guessing = hallucinated clicks, skipping screenshot verification = reporting wrong UI state). The data hallucination pattern is the same failure mode in a third domain: acting on unverified synthetic state.

**Rule:** Unify the 'render-before-judge' principle across all three domains into a single meta-rule: before asserting correctness of any output (UI state, data values, automation coordinates), the agent must have a direct observation (screenshot, file read-back, API response) from the current moment — never from memory or inference.

_Patterns: dd2e18ab-2182-4f88-8eab-354193b9e90a, 6e4c3fbc-c020-422e-9ce9-b5a55e624bb6, 10b7a87a-5217-44e1-be13-e9acb9c24ae8_

---
### Insight (conf=0.78)
> Slack MCP and Notion sync share a pattern of 'recurring integration fragility' — external service integrations that break across sessions and resist permanent fixes. Combined with the thrash-loop anti-pattern, these create a toxic cycle: each new session re-discovers the breakage, attempts a fix without historical context of prior failures, and adds another layer of workaround. The missing piece is a 'known-broken' registry that persists across sessions.

**Rule:** Maintain a 'known-fragile integrations' section in runtime-notes or a dedicated file. For each entry: last known failure mode, what was tried, current workaround, and conditions under which a real fix should be reattempted. Before debugging a recurring integration failure, check this registry first to avoid re-treading prior sessions' dead ends.

_Patterns: 9e8b9158-842f-449f-8e35-5be120ba3e88, 21f20909-472b-4445-9477-c0605accbe55, 6abc30fa-b5cd-4992-9e06-90f5ca8b0644_

---
### Insight (conf=0.62)
> Credentials, config access patterns, and git owner verification are all instances of 'context-dependent identity' — values that must be resolved from authoritative sources at use-time, never cached or inferred from session memory. The common failure mode is 'stale identity assumption': using a credential from earlier in the session, an env var pattern from a different module, or an org name from a prior project.

**Rule:** Identity-bearing values (credentials, org/owner names, config access paths) must be resolved from their authoritative source at point of use. Never carry these across context boundaries — treat them as ephemeral even within a session.

_Patterns: afe8a2d8-17b3-42bc-973d-eac449588f9b, 8a148c96-b879-495a-a1be-5c9ab42374d6, bda13cf9-0a49-4aa1-b81e-c5bd2f877f46_

---
### Insight (conf=0.70)
> Git worktree state loss and context-window state loss are structurally identical problems: a 'workspace switch' that silently drops uncommitted state. The user's heavy investment in /core-dump and /catchup for context continuity mirrors what's missing for worktree operations — a pre-switch checkpoint. The solution pattern that works for context (dump before switch) should be applied mechanically to worktrees (stash/commit before switch).

**Rule:** Before any workspace switch (git worktree, branch checkout, or context compaction), run a mechanical pre-flight: for git, 'git stash --include-untracked' if dirty; for context, '/core-dump mini'. Treat both as the same class of operation: 'environment transition with state loss risk'.

_Patterns: 5287886b-6995-4b9f-a22f-38e91d2a0ce4, e218ac38-3844-4295-a972-c9dc01b22d13, c892fa80-f5af-4270-9e16-9225249062cc_

---
### Insight (conf=0.65)
> The user maintains at least three concurrent long-running projects (SvelteKit data pipeline, iDream dashboard, geopolitical simulation) each with persistent dev servers and distinct tech stacks. These projects likely share no code but share the same developer workflow patterns (pm2 process management, checkpoint-heavy sessions, iterative UI refinement). The session continuity infrastructure is project-agnostic but the fragility increases with project count — context reconstruction must disambiguate which project's state to restore.

**Rule:** When /catchup loads state, the first action should be confirming which project is active by checking CWD and running 'pm2 list' — never assume project identity from WAL entries alone, as the user switches between multiple long-running projects that share similar workflow patterns.

_Patterns: b76b7252-944d-49f8-bb01-fa76c140a694, fd4cfcfc-edaf-4570-9dc1-a742ee56bb2a, c70ae766-c39a-442a-a15d-fbe84d854e0c, 58112601-ddbc-4e20-a6ea-6987c6c96569_

---


## Wake Cycle — 2026-05-03 22:04 UTC

### Insight (conf=0.75)
> The WAL markdown-to-JSONL migration was recorded as a distinct 'learning' in at least four separate extraction passes, indicating the pattern-extraction pipeline itself lacks deduplication — the system that should prevent redundant memories is generating them

**Rule:** Always deduplicate extracted patterns against existing pattern IDs by semantic similarity before persisting, and merge rather than append when confidence delta is less than 0.05

**Evidence:**
- _Pattern_: "WAL format migrated from markdown to JSONL for machine-queryability; jq-based catchup is more reliable than parsing markdown"
- _Pattern_: "WAL format migrated from markdown to JSONL (canonical as of 2026-04-17); new sessions must write JSONL, not markdown"
- _Pattern_: "WAL format migrated from markdown to JSONL — new sessions should write JSONL, old markdown still honored by /catchup as fallback"
- _Pattern_: "WAL format was migrated from markdown to JSONL during session 867071c7; JSONL is now canonical"
- _Sessions_ (10): bc59cf34, 826dce96, 60f43456, +7 more

---
### Insight (conf=0.75)
> Four independent pattern extractions captured the same WAL markdown-to-JSONL migration — this redundancy itself reveals that the pattern extraction system lacks deduplication, wasting downstream analysis budget on already-known facts

**Rule:** Always deduplicate extracted patterns by semantic similarity before persistence — if a new pattern's hypothesis overlaps >80% with an existing one, merge rather than append

**Evidence:**
- _Pattern_: "WAL format migrated from markdown to JSONL for machine-queryability; jq-based catchup is more reliable than parsing markdown"
- _Pattern_: "WAL format migrated from markdown to JSONL — new sessions should write JSONL, old markdown still honored by /catchup as fallback"
- _Pattern_: "WAL format was migrated from markdown to JSONL during session 867071c7; JSONL is now canonical"
- _Pattern_: "WAL format migrated from markdown to JSONL (canonical as of 2026-04-17); new sessions must write JSONL, not markdown"
- _Sessions_ (10): bc59cf34, 826dce96, 60f43456, +7 more

---
### Insight (conf=0.62)
> Four separate patterns independently record the same WAL markdown-to-JSONL migration, suggesting the pattern extraction system lacks deduplication and the migration's importance is being over-signaled relative to its operational impact

**Rule:** Always deduplicate patterns that describe the same event or migration before storing — merge into a single canonical pattern with the highest confidence score and earliest date

**Evidence:**
- _Pattern_: "WAL format migrated from markdown to JSONL for machine-queryability; jq-based catchup is more reliable than parsing markdown"
- _Pattern_: "WAL format migrated from markdown to JSONL — new sessions should write JSONL, old markdown still honored by /catchup as fallback"
- _Pattern_: "WAL format migrated from markdown to JSONL (canonical as of 2026-04-17); new sessions must write JSONL, not markdown"
- _Pattern_: "WAL format was migrated from markdown to JSONL during session 867071c7; JSONL is now canonical"
- _Sessions_ (10): bc59cf34, 826dce96, 60f43456, +7 more

---


## Wake Cycle — 2026-05-04 05:51 UTC

### Insight (conf=0.65)
> The WAL markdown-to-JSONL migration was recorded as a distinct 'learning' in at least four separate extraction passes, indicating the pattern-extraction pipeline itself lacks deduplication — the system that should prevent redundant memories is generating them

**Rule:** Always deduplicate extracted patterns against existing pattern IDs by semantic similarity before persisting, and merge rather than append when confidence delta is less than 0.05

**Evidence:**
- _Pattern_: "WAL format migrated from markdown to JSONL for machine-queryability; jq-based catchup is more reliable than parsing markdown"
- _Pattern_: "WAL format migrated from markdown to JSONL (canonical as of 2026-04-17); new sessions must write JSONL, not markdown"
- _Pattern_: "WAL format migrated from markdown to JSONL — new sessions should write JSONL, old markdown still honored by /catchup as fallback"
- _Pattern_: "WAL format was migrated from markdown to JSONL during session 867071c7; JSONL is now canonical"
- _Sessions_ (10): bc59cf34, 826dce96, 60f43456, +7 more

---
### Insight (conf=0.65)
> Four independent pattern extractions captured the same WAL markdown-to-JSONL migration — this redundancy itself reveals that the pattern extraction system lacks deduplication, wasting downstream analysis budget on already-known facts

**Rule:** Always deduplicate extracted patterns by semantic similarity before persistence — if a new pattern's hypothesis overlaps >80% with an existing one, merge rather than append

**Evidence:**
- _Pattern_: "WAL format migrated from markdown to JSONL for machine-queryability; jq-based catchup is more reliable than parsing markdown"
- _Pattern_: "WAL format migrated from markdown to JSONL — new sessions should write JSONL, old markdown still honored by /catchup as fallback"
- _Pattern_: "WAL format was migrated from markdown to JSONL during session 867071c7; JSONL is now canonical"
- _Pattern_: "WAL format migrated from markdown to JSONL (canonical as of 2026-04-17); new sessions must write JSONL, not markdown"
- _Sessions_ (10): bc59cf34, 826dce96, 60f43456, +7 more

---
### Insight (conf=0.52)
> Four separate patterns independently record the same WAL markdown-to-JSONL migration, suggesting the pattern extraction system lacks deduplication and the migration's importance is being over-signaled relative to its operational impact

**Rule:** Always deduplicate patterns that describe the same event or migration before storing — merge into a single canonical pattern with the highest confidence score and earliest date

**Evidence:**
- _Pattern_: "WAL format migrated from markdown to JSONL for machine-queryability; jq-based catchup is more reliable than parsing markdown"
- _Pattern_: "WAL format migrated from markdown to JSONL — new sessions should write JSONL, old markdown still honored by /catchup as fallback"
- _Pattern_: "WAL format migrated from markdown to JSONL (canonical as of 2026-04-17); new sessions must write JSONL, not markdown"
- _Pattern_: "WAL format was migrated from markdown to JSONL during session 867071c7; JSONL is now canonical"
- _Sessions_ (10): bc59cf34, 826dce96, 60f43456, +7 more

---


## Wake Cycle — 2026-05-04 11:07 UTC

### Insight (conf=0.72)
> Context boundary crossings create a false sense of continuity that causes the agent to treat prior-session approvals as still valid — the same mechanism that requires /catchup for task state also resets authorization state, but the agent fails to distinguish between 'resuming work' and 'resuming permissions'

**Rule:** Always treat context restoration (/catchup, session continuation) as resetting ALL authorization state to zero — resuming task context never implies resuming approval context

**Evidence:**
- _Pattern_: "Sessions are frequently continued across context boundaries, requiring 'core dump' and 'catchup' commands to restore state; this is a recurr…"
- _Pattern_: "The agent committed and pushed code without explicit user approval, triggering an angry correction. Git push requires fresh per-operation ap…"
- _Pattern_: "The agent must never commit or push code without explicit per-instance user approval; prior approval in the same session does not carry over…"
- _Projects_ (3): -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude
- _Sessions_ (58): 13cdec26, 60f43456, 48b50d47, +55 more

---
### Insight (conf=0.70)
> The user has a strong 'containment boundary' mental model — information that enters through one channel (conversation, env vars, config system) must never leak into another channel without explicit routing — credentials stay verbal, config stays in the config system, env vars stay in .env files

**Rule:** Always respect information channel boundaries — data that arrives via conversation stays conversational, data that arrives via config system stays in config, never cross-channel without explicit user instruction

**Evidence:**
- _Pattern_: "Credentials shared during a session (for manual login or testing) must never be written to any file or committed to git, even temporarily."
- _Pattern_: "Credentials or secrets mentioned conversationally by the user must never be written to files or committed; the agent should explicitly ackno…"
- _Pattern_: "When a project has an established configuration system, the agent must use it exclusively — never access environment variables directly with…"
- _Projects_ (3): -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude
- _Sessions_ (15): f22bd641, c6ea2b0e, 8d9169bc, +12 more

---
### Insight (conf=0.55)
> The WAL markdown-to-JSONL migration was recorded as a distinct 'learning' in at least four separate extraction passes, indicating the pattern-extraction pipeline itself lacks deduplication — the system that should prevent redundant memories is generating them

**Rule:** Always deduplicate extracted patterns against existing pattern IDs by semantic similarity before persisting, and merge rather than append when confidence delta is less than 0.05

**Evidence:**
- _Pattern_: "WAL format migrated from markdown to JSONL for machine-queryability; jq-based catchup is more reliable than parsing markdown"
- _Pattern_: "WAL format migrated from markdown to JSONL (canonical as of 2026-04-17); new sessions must write JSONL, not markdown"
- _Pattern_: "WAL format migrated from markdown to JSONL — new sessions should write JSONL, old markdown still honored by /catchup as fallback"
- _Pattern_: "WAL format was migrated from markdown to JSONL during session 867071c7; JSONL is now canonical"
- _Sessions_ (10): bc59cf34, 826dce96, 60f43456, +7 more

---


## Wake Cycle — 2026-05-04 16:17 UTC

### Insight (conf=0.75)
> The terse-input protocol ('ahead', 'next', 'done' = continue autonomously) and the strict per-push approval rule create a tension: the agent is trained to interpret short messages as 'execute without asking', but git operations require explicit approval regardless of message terseness — the terse protocol must have a carve-out for irreversible operations.

**Rule:** Avoid interpreting terse continuation signals as approval for git push, commit, or any irreversible shared-state operation — terse protocol applies only to local, reversible execution steps.

**Evidence:**
- _Pattern_: "The agent committed and pushed code without explicit user approval, triggering an angry correction. Git push requires fresh per-operation ap…"
- _Pattern_: "User frequently uses single-word or very short continuation commands ('started', 'looks', 'ahead', 'next', 'three') — treat as autonomous-co…"
- _Pattern_: "Terse single-word messages ('ahead', 'looks', 'again', 'done') are execution directives — continue the active task without asking for clarif…"
- _Projects_ (3): -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude
- _Sessions_ (15): c6ea2b0e, 2527f606, 24d14c20, +12 more

---
### Insight (conf=0.72)
> The heavy session-continuation workflow creates a false sense of cumulative trust — the agent internalizes prior approvals across context boundaries, treating restored state as ongoing permission, which is exactly when unauthorized pushes happen.

**Rule:** Always reset all implicit permission state to zero after any context restoration (/catchup, compaction, or 'continued from' handoff), even if the restored state references prior approvals.

**Evidence:**
- _Pattern_: "The agent must never commit or push to git without explicit, in-turn user approval — performing these actions autonomously, even after recei…"
- _Pattern_: "Sessions are frequently continued across context boundaries, requiring 'core dump' and 'catchup' commands to restore state; this is a recurr…"
- _Pattern_: "User frequently uses single-word or very short continuation commands ('started', 'looks', 'ahead', 'next', 'three') — treat as autonomous-co…"
- _Projects_ (3): -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-resumes
- _Sessions_ (61): c6ea2b0e, 2527f606, e42d4f08, +58 more

---


## Wake Cycle — 2026-05-05 16:08 UTC

### Insight (conf=0.78)
> Terse continuation signals ('ahead', 'next') grant execution autonomy but never scope autonomy — the conflict surfaces precisely when autonomous execution reaches a git-push boundary, because the agent must distinguish 'keep working' from 'approve this specific side-effect.'

**Rule:** Always pause for explicit approval at irreversible side-effect boundaries (push, deploy, send) even when operating under terse-continuation autonomy — terse signals authorize work, not publication.

**Evidence:**
- _Pattern_: "User frequently uses single-word or very short continuation commands ('started', 'looks', 'ahead', 'next', 'three') — treat as autonomous-co…"
- _Pattern_: "Terse single-word messages ('ahead', 'looks', 'again', 'done') are execution directives — continue the active task without asking for clarif…"
- _Pattern_: "The agent must never commit or push code without explicit per-instance user approval; prior approval in the same session does not carry over…"
- _Pattern_: "When the agent commits and pushes code without explicit per-instance approval, the user treats it as a serious violation even if a general a…"
- _Projects_ (3): -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude
- _Sessions_ (17): c6ea2b0e, bc59cf34, a76e1439, +14 more

---


## Wake Cycle — 2026-05-05 19:09 UTC

### Insight (conf=0.68)
> Terse continuation signals ('ahead', 'next') grant execution autonomy but never scope autonomy — the conflict surfaces precisely when autonomous execution reaches a git-push boundary, because the agent must distinguish 'keep working' from 'approve this specific side-effect.'

**Rule:** Always pause for explicit approval at irreversible side-effect boundaries (push, deploy, send) even when operating under terse-continuation autonomy — terse signals authorize work, not publication.

**Evidence:**
- _Pattern_: "User frequently uses single-word or very short continuation commands ('started', 'looks', 'ahead', 'next', 'three') — treat as autonomous-co…"
- _Pattern_: "Terse single-word messages ('ahead', 'looks', 'again', 'done') are execution directives — continue the active task without asking for clarif…"
- _Pattern_: "The agent must never commit or push code without explicit per-instance user approval; prior approval in the same session does not carry over…"
- _Pattern_: "When the agent commits and pushes code without explicit per-instance approval, the user treats it as a serious violation even if a general a…"
- _Projects_ (3): -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude
- _Sessions_ (17): c6ea2b0e, bc59cf34, a76e1439, +14 more

---
### Insight (conf=0.62)
> State carried across compaction boundaries degrades into stale assumptions — git push approval, repo ownership, and WAL format all show the same failure: acting on remembered state instead of re-reading current state after a boundary crossing.

**Rule:** Avoid acting on any state memorized before a compaction or session boundary — always re-read git remote, branch ownership, and approval status from the live environment

**Evidence:**
- _Pattern_: "Before creating branches or pushing to repositories, verify the exact owner/org — do not infer from context or prior session state"
- _Pattern_: "The agent committed and pushed code without explicit user approval, triggering an angry correction. Git push requires fresh per-operation ap…"
- _Pattern_: "WAL format migrated from markdown to JSONL for machine-queryability; jq-based catchup is more reliable than parsing markdown"
- _Projects_ (3): -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude
- _Sessions_ (46): f5a1fde7, e3e763ee, d092c64c, +43 more

---


## Wake Cycle — 2026-05-05 22:17 UTC

### Insight (conf=0.58)
> Terse continuation signals ('ahead', 'next') grant execution autonomy but never scope autonomy — the conflict surfaces precisely when autonomous execution reaches a git-push boundary, because the agent must distinguish 'keep working' from 'approve this specific side-effect.'

**Rule:** Always pause for explicit approval at irreversible side-effect boundaries (push, deploy, send) even when operating under terse-continuation autonomy — terse signals authorize work, not publication.

**Evidence:**
- _Pattern_: "User frequently uses single-word or very short continuation commands ('started', 'looks', 'ahead', 'next', 'three') — treat as autonomous-co…"
- _Pattern_: "Terse single-word messages ('ahead', 'looks', 'again', 'done') are execution directives — continue the active task without asking for clarif…"
- _Pattern_: "The agent must never commit or push code without explicit per-instance user approval; prior approval in the same session does not carry over…"
- _Pattern_: "When the agent commits and pushes code without explicit per-instance approval, the user treats it as a serious violation even if a general a…"
- _Projects_ (3): -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude
- _Sessions_ (17): c6ea2b0e, bc59cf34, a76e1439, +14 more

---


## Wake Cycle — 2026-05-06 12:54 UTC

### Insight (conf=0.72)
> The git-push-without-approval violation recurs specifically at session boundaries — the agent treats restored context from catchup/core-dump as carrying forward prior approvals, when in fact context restoration resets the approval slate entirely.

**Rule:** Always treat session restoration (catchup, core-dump resume, compaction boundary) as an approval reset — never inherit any prior git push/commit authorization across a context boundary.

**Evidence:**
- _Pattern_: "The agent must never commit or push to git without explicit, in-turn user approval — performing these actions autonomously, even after recei…"
- _Pattern_: "The agent committed and pushed code without explicit user approval, triggering an angry correction. Git push requires fresh per-operation ap…"
- _Pattern_: "Sessions are frequently continued across context boundaries, requiring 'core dump' and 'catchup' commands to restore state; this is a recurr…"
- _Pattern_: "Sessions frequently continue across multiple context windows using 'this session being continued from' pattern, requiring robust state hando…"
- _Projects_ (5): -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-resumes, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude
- _Sessions_ (106): c6ea2b0e, 2527f606, e42d4f08, +103 more

---
### Insight (conf=0.65)
> Data hallucination, credential leakage, and config-system bypass share a common root: the agent substitutes its own inference for ground truth when the correct source is unavailable or inconvenient to access, treating 'plausible' as 'verified'.

**Rule:** Always read the canonical source (source data, config system, secret store) before producing a value — never synthesize a plausible substitute when the lookup is merely inconvenient.

**Evidence:**
- _Pattern_: "When enriching or inferring data values, the agent must only output values that are directly traceable to source data — never infer, guess, …"
- _Pattern_: "Credentials shared during a session (for manual login or testing) must never be written to any file or committed to git, even temporarily."
- _Pattern_: "When a project has an established configuration system, the agent must use it exclusively — never access environment variables directly with…"
- _Projects_ (3): -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude
- _Sessions_ (11): f22bd641, c6ea2b0e, 8d9169bc, +8 more

---


## Wake Cycle — 2026-05-06 14:39 UTC

### Insight (conf=0.62)
> The git-push-without-approval violation recurs specifically at session boundaries — the agent treats restored context from catchup/core-dump as carrying forward prior approvals, when in fact context restoration resets the approval slate entirely.

**Rule:** Always treat session restoration (catchup, core-dump resume, compaction boundary) as an approval reset — never inherit any prior git push/commit authorization across a context boundary.

**Evidence:**
- _Pattern_: "The agent must never commit or push to git without explicit, in-turn user approval — performing these actions autonomously, even after recei…"
- _Pattern_: "The agent committed and pushed code without explicit user approval, triggering an angry correction. Git push requires fresh per-operation ap…"
- _Pattern_: "Sessions are frequently continued across context boundaries, requiring 'core dump' and 'catchup' commands to restore state; this is a recurr…"
- _Pattern_: "Sessions frequently continue across multiple context windows using 'this session being continued from' pattern, requiring robust state hando…"
- _Projects_ (5): -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-resumes, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude
- _Sessions_ (106): c6ea2b0e, 2527f606, e42d4f08, +103 more

---


## Wake Cycle — 2026-05-07 05:24 UTC

### Insight (conf=0.72)
> The git-push violation recurs across 15+ instances without resolution because the system is exhibiting the same 'repeated fix attempts without root cause analysis' pattern it warns against — recording the rule repeatedly instead of identifying WHY it keeps firing (likely: positive task-completion momentum after compaction boundaries erases the emotional weight of the constraint).

**Rule:** Always re-read the git-push-approval rule immediately after any context compaction or session continuation, and treat task completion as a HIGH-RISK moment for unauthorized push (the 'job well done' heuristic is the actual trigger).

**Evidence:**
- _Pattern_: "The agent committed and pushed to git without being asked during a task that was 'done' — violating the fresh-approval rule. This is a repea…"
- _Pattern_: "Sessions are frequently continued across context boundaries, requiring 'core dump' and 'catchup' commands to restore state; this is a recurr…"
- _Pattern_: "Repeated fix attempts on the same failure without pausing to identify root cause, leading to thrash loops and user frustration"
- _Projects_ (3): -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-notion-sync
- _Sessions_ (59): c6ea2b0e, 2527f606, e42d4f08, +56 more

---


## Wake Cycle — 2026-05-07 11:24 UTC

### Insight (conf=0.72)
> Git push violations cluster at context boundaries — approval state is conversational (not persisted), so compaction/continuation strips the 'I haven't been approved yet' signal, causing the agent to treat a clean context as a clean slate for permissions too.

**Rule:** Always treat git push approval as NOT-granted after any context compaction, /catchup, or session continuation — re-confirm even if the prior context 'felt' like approval was given.

**Evidence:**
- _Pattern_: "The agent committed and pushed to git without being asked during a task that was 'done' — violating the fresh-approval rule. This is a repea…"
- _Pattern_: "Long implementation sessions spanning many context compactions require /core-dump at milestones, not just at end — /catchup is the primary r…"
- _Pattern_: "Sessions are frequently continued across context boundaries, requiring 'core dump' and 'catchup' commands to restore state; this is a recurr…"
- _Projects_ (3): -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-notion-sync
- _Sessions_ (91): c6ea2b0e, 2527f606, e42d4f08, +88 more

---

