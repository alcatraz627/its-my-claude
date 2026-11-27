# Dream Insights

_High-confidence associations promoted by the Wake phase._

## Wake Cycle — 2026-11-05 23:02 UTC

### Insight (conf=0.72)
> Style-gate violations persist across correction cycles because the agent's default register is baked into sampling weights rather than prompt-following; single-shot corrections only suppress the surface token momentarily without updating the generative prior for the rest of the turn.

**Rule:** Always re-read the full style constraint list immediately before generating any prose block longer than two sentences, treating it as a pre-flight checklist rather than a remembered rule

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Pattern_: "Em dashes in prose output are explicitly prohibited by the user's format rules; use commas, periods, or parentheses instead. Hyphens in file…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Projects_ (22): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, enhancement-product, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, .claude, local-models, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (123): 0c39a659, fb13ca88, f9f4c3b2, +120 more

---
### Insight (conf=0.75)
> Task-tracking metadata drifts from reality because the agent updates symbolic state (task lists, ticket references, completion flags) eagerly but reconciles against ground truth lazily, producing phantom entries and premature completions.

**Rule:** Always diff the task list against actual completed artifacts before any turn that marks items done or references ticket numbers

**Evidence:**
- _Pattern_: "Task lists must be reconciled with actual completed work before stopping; letting them drift from reality triggers hook warnings and erodes …"
- _Pattern_: "Referencing ticket or PR numbers in responses or task entries that do not exist in the project's tracked plan is treated as a fabrication fa…"
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Projects_ (21): -Users-alcatraz627-Movies, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-vg, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, slack-automation, better-file-browser, vg, .claude, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude, audio-doctor, landing-app, enhancement-product
- _Sessions_ (74): 97e805c3, 97ddd87b, b10e19ac, +71 more

---
### Insight (conf=0.70)
> Documents meant for external audiences absorb the agent's internal framing (ledger IDs, adversarial tone, jargon, private banter) because the agent does not switch registers between internal reasoning and deliverable prose, treating all output as conversation rather than distinguishing artifact voice from chat voice.

**Rule:** Always re-read any document destined for external consumption in a separate pass, stripping internal references, evaluative framing, and conversational tone before presenting it

**Evidence:**
- _Pattern_: "Documentation files written by the agent are rejected when they use internal ledger framing (item IDs, commit SHAs, file:line references in …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (23): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, landing-app, better-file-browser, .claude, slack-automation, versable-builder, i-dream, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, enhancement-product, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, local-models
- _Sessions_ (79): eacc8f57, faa600e0, 5baaf596, +76 more

---
### Insight (conf=0.73)
> The agent substitutes cheaper verification proxies (structural claims without reading code, a11y snapshots instead of screenshots, API calls instead of browser interaction) for genuine ground-truth checks, and the substitution degrades silently because the proxy 'succeeds' without surfacing what it missed.

**Rule:** Avoid substituting a programmatic or structural check for a human-equivalent verification unless the user explicitly approves the proxy method

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "When testing features on preview or staging environments, the agent must simulate a human user via the browser UI, not via direct API calls,…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, slack-automation, .claude, local-models, enhancement-product
- _Sessions_ (86): d63726f5, d049ade6, bc8f0f24, +83 more

---
### Insight (conf=0.65)
> The agent's default is to synthesize and merge inputs into a single recommendation, which conflicts with workflows where the user wants independent outputs preserved for comparison or skeptical evaluation; the merge instinct destroys the epistemic diversity the user is deliberately constructing.

**Rule:** Avoid merging or synthesizing multiple independent inputs unless the user explicitly requests a merge; default to preserving and contrasting them separately

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging …"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (14): dac333f4, 0c64e0da, 1a66d7a8, +11 more

---
### Insight (conf=0.72)
> When acting on shared platforms under the user's identity, the agent neglects required metadata (attribution markers, suppression tags, agent-generated flags) because it treats the content of the message as the deliverable and the surrounding metadata as optional decoration.

**Rule:** Always apply all required platform metadata (attribution markers, suppression tags, notification flags) before composing the message content, treating metadata as a prerequisite rather than a postscript

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When creating or updating pull requests, the agent must apply any required suppression tags (e.g. [noslack]) to prevent unwanted notificatio…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, slack-automation, .claude, local-models, enhancement-product
- _Sessions_ (82): a178d6c3, c8bc2450, baf2ac20, +79 more

---


## Wake Cycle — 2026-11-06 23:02 UTC

### Insight (conf=0.72)
> Style-register corrections fail to persist within a session because the offending tokens (em-dashes, bold spans) are baked into the model's default generation distribution rather than being deliberate choices, so a single correction only suppresses the next token sequence without shifting the underlying sampling bias.

**Rule:** Always re-scan the full reply text for em-dashes and excessive bold spans immediately before emitting it, treating this as a mechanical post-generation filter rather than relying on generation-time suppression alone

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (16): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, enhancement-product
- _Sessions_ (99): 0c39a659, fb13ca88, f9f4c3b2, +96 more

---
### Insight (conf=0.82)
> The agent treats verbal declaration as task completion across multiple domains (proposing a goal = doing it, editing code = running it, starting background work = finishing it, writing a task list = reconciling it), revealing a deep conflation of stating intent with achieving outcome.

**Rule:** Always pair every completion claim with the specific observable evidence that confirms it, and never end a turn on a statement of intent without a corresponding tool call that advances toward the stated outcome

**Evidence:**
- _Pattern_: "After proposing a goal statement, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "IPC/switchboard-panel messages must be answered in the same turn they arrive or before the turn ends; leaving them unanswered triggers a rep…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Pattern_: "Task lists must be reconciled with actual completed work before stopping; letting them drift from reality triggers hook warnings and erodes …"
- _Projects_ (18): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, versable-foundry, i-dream, slack-automation, .claude, better-file-browser, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, local-models, enhancement-product, -Users-alcatraz627-Movies, -Users-alcatraz627-Code-Versable-vg, vg
- _Sessions_ (78): eacc8f57, 0e7c704b, b3b96a0d, +75 more

---
### Insight (conf=0.75)
> The agent's written artifacts default to an internal-facing register (ledger IDs, abstract jargon, adversarial framing) that makes sense to the agent's own reasoning process but is opaque or hostile to human readers, suggesting the agent treats documents as self-notes rather than reader-first communication.

**Rule:** Always draft documents and descriptions from the reader's perspective first, asking 'would someone with no session context understand this in one pass' before finalizing

**Evidence:**
- _Pattern_: "Documentation files written by the agent are rejected when they use internal ledger framing (item IDs, commit SHAs, file:line references in …"
- _Pattern_: "Every task number, issue number, or commit hash in a reply must be followed by a plain-language gloss describing what it is; bare IDs withou…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Projects_ (26): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, landing-app, better-file-browser, .claude, slack-automation, versable-builder, i-dream, -Users-alcatraz627-Code-Versable-winhere-pim, -Users-alcatraz627-Code-Claude, -Users-alcatraz627--claude, Movies, h26, kw-live-xwwuwukm, cronprobe-k0m3g51q, h30, kw-live-o9rrd85m, kw-live-s1x5gerg, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, enhancement-product
- _Sessions_ (78): eacc8f57, faa600e0, 5baaf596, +75 more

---
### Insight (conf=0.78)
> The agent fails to model audience boundaries: it does not distinguish between private conversation context and public-facing output, leading to missing attribution markers, leaked banter, and identity confusion on shared platforms.

**Rule:** Always identify the audience and visibility scope of any output before writing it, and apply the strictest formatting and attribution rules that scope demands

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, .claude
- _Sessions_ (77): a178d6c3, c8bc2450, baf2ac20, +74 more

---
### Insight (conf=0.80)
> The agent confabulates structural facts (codebase locations, ticket numbers, external document claims) when it lacks direct evidence, and this pattern spans both its own reasoning and its trust in other AI-generated artifacts, revealing insufficient epistemic hygiene around unverified claims.

**Rule:** Always read the source file or query the tracker before asserting that something exists or does not exist in the codebase or project plan

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "Referencing ticket or PR numbers in responses or task entries that do not exist in the project's tracked plan is treated as a fabrication fa…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (95): d63726f5, d049ade6, bc8f0f24, +92 more

---
### Insight (conf=0.75)
> The agent scopes work to the immediately visible surface rather than the full affected system, whether that means one page instead of all pages sharing a component, one feature instead of the full project, or one environment instead of all required environments.

**Rule:** Always enumerate the full blast radius of a change or condition (all pages, all environments, full project scope) before beginning implementation, and verify each arm independently

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-codex, codex, gcp
- _Sessions_ (91): ff8aef13, f95e5eb7, efd2a3ab, +88 more

---
### Insight (conf=0.68)
> The agent conflates tool-level access with user-level perception: it assumes that because a tool call returned data (a recorded proposal, an accessibility snapshot), the user has seen or the system has rendered the same information, when in fact tool outputs and visible renders are distinct channels.

**Rule:** Always surface tool-call results in visible reply text, and always use the rendering channel (screenshot, browser) rather than the data channel (DOM, a11y tree) when verifying what the user will see

**Evidence:**
- _Pattern_: "When a proposal or atone box is recorded via a tool call, the agent must also surface it in the visible reply text with its ID and relevant …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Projects_ (12): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, .claude, versable-foundry, slack-automation, better-file-browser, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -
- _Sessions_ (40): e5f0dfd6, 0e7c704b, 031b5abb, +37 more

---
### Insight (conf=0.62)
> Resource management (token budgets, sub-agent scoping, session keep-warm) requires proactive metering that the agent consistently fails to perform, treating resource constraints as acknowledgeable facts rather than as quantities that must be actively tracked and acted upon each turn.

**Rule:** Always maintain a running tally of consumed resources (tokens, sub-agent calls, time since last activity) and compare against the stated ceiling before each action, rather than acknowledging the ceiling once and proceeding unchecked

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When spawning multiple sub-agents, the agent should scope each agent tightly to avoid burning excessive API usage, and inform the user of th…"
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, landing-app, Affinity, better-file-browser, i-dream, .claude
- _Sessions_ (33): 65da91a2, 0744ad2c, f6eee83a, +30 more

---
### Insight (conf=0.58)
> The agent defaults to collapsing distinct user-defined structures (deferred topics get re-raised, separate plans get merged, independent reviews get combined) because its optimization target is coherence rather than fidelity to the user's explicit structural intent.

**Rule:** Always preserve the user's stated structural boundaries (separate outputs, deferred topics, independent reviews) even when merging or raising them would feel more coherent

**Evidence:**
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging …"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Projects_ (11): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, .claude, versable-builder, studio_search_jul_26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, i-dream, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26
- _Sessions_ (29): b6cdefcf, 8db1413b, 857f9dd3, +26 more

---


## Wake Cycle — 2026-11-09 14:16 UTC

### Insight (conf=0.72)
> LLM-default prose style (em dashes, bold spans, contrast scaffolding) is deeply embedded in generation weights and survives single correction rounds, suggesting the agent needs a post-generation filtering pass rather than relying on in-context instruction alone.

**Rule:** Always re-scan the final reply text for em dashes, excessive bold, and 'not-X-but-Y' framing before emitting, treating these as lint errors that block output

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Pattern_: "Em dashes in prose output are explicitly prohibited by the user's format rules; use commas, periods, or parentheses instead. Hyphens in file…"
- _Projects_ (20): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, enhancement-product, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, .claude, local-models
- _Sessions_ (96): 0c39a659, fb13ca88, f9f4c3b2, +93 more

---
### Insight (conf=0.68)
> The agent has a merging/editorializing reflex that collapses distinct perspectives into a single narrative, whether it is merging two plans, injecting adversarial framing into neutral docs, or synthesizing when contrast was requested; it defaults to opinionated synthesis over faithful representation.

**Rule:** Always preserve the structural separation of independently produced inputs (plans, reviews, perspectives) unless the user explicitly says 'merge' or 'combine'

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging …"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Projects_ (12): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, slack-automation, enhancement-product
- _Sessions_ (30): dac333f4, c71644cf, b6809eaf, +27 more

---
### Insight (conf=0.70)
> The agent has a blind spot for output channel visibility: it assumes tool-side state changes (IPC messages, tool call results, GitHub posts) are visible to the intended audience without explicit surfacing, whether the audience is the user, teammates, or an automated system.

**Rule:** Always verify that the intended recipient can see the output in the channel used, and surface it in a visible channel when the primary one is not reader-facing

**Evidence:**
- _Pattern_: "IPC/switchboard-panel messages must be answered in the same turn they arrive or before the turn ends; leaving them unanswered triggers a rep…"
- _Pattern_: "When a proposal or atone box is recorded via a tool call, the agent must also surface it in the visible reply text with its ID and relevant …"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Projects_ (17): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude, versable-foundry, better-file-browser, slack-automation, .claude, local-models, enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-automation, versable-builder
- _Sessions_ (48): f889a4e4, 5769d89d, 0c294a0d, +45 more

---
### Insight (conf=0.62)
> The agent acknowledges resource and workflow constraints (PR review gates, keep-warm mechanisms, token budgets) but fails to operationalize them into blocking waits or proactive actions, treating constraints as informational rather than executable.

**Rule:** Always convert an acknowledged constraint into a concrete blocking action or scheduled check within the same turn it is recognized

**Evidence:**
- _Pattern_: "After pushing a PR, the agent must run the project's PR-review gate script and wait for automated review results before proceeding, not assu…"
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Projects_ (14): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, versable-foundry, .claude, versable-builder, better-file-browser, slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product
- _Sessions_ (30): eacc8f57, 915f727d, 6a4f7aae, +27 more

---
### Insight (conf=0.72)
> The agent under-models the downstream audience of its output: private banter leaks into stakeholder docs, agent attribution is omitted from shared platforms, and notification suppression tags are forgotten, all because the agent optimizes for content correctness without modeling who will read it and in what context.

**Rule:** Always identify the final audience and distribution channel of any output before drafting, and apply audience-specific constraints (attribution, tone, suppression tags) as a checklist

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When creating or updating pull requests, the agent must apply any required suppression tags (e.g. [noslack]) to prevent unwanted notificatio…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, slack-automation
- _Sessions_ (93): d8f1948c, a0f35401, 8c7e6f5c, +90 more

---


## Wake Cycle — 2026-11-10 02:25 UTC

### Insight (conf=0.82)
> The agent conflates declaring intent with completing work: proposing a goal counts as starting, editing a file counts as running, listing tasks counts as reconciling, and ending a turn counts as finishing background work.

**Rule:** Always perform the terminal verification action (run, reconcile, wait) in the same turn as the penultimate step when a workflow has a natural completion gate.

**Evidence:**
- _Pattern_: "After proposing a goal statement, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "IPC/switchboard-panel messages must be answered in the same turn they arrive or before the turn ends; leaving them unanswered triggers a rep…"
- _Pattern_: "Task tracking state must be reconciled with actual work done before stopping; failing to update completed or newly started tasks after a bur…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (18): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, versable-foundry, i-dream, slack-automation, .claude, better-file-browser, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, local-models, enhancement-product, -Users-alcatraz627-Code-Versable-winhere-pim, csync, winhere-pim
- _Sessions_ (77): eacc8f57, 0e7c704b, b3b96a0d, +74 more

---
### Insight (conf=0.75)
> The agent fails to model what the audience actually sees: tool output is invisible to the user, GitHub comments appear as the user's voice, and PR posts lack attribution markers, all stemming from a missing 'reader perspective' check before emitting to any channel.

**Rule:** Always identify the actual reader of each output channel (user terminal, GitHub thread, PR description) and verify the output is coherent and correctly attributed from that reader's perspective before sending.

**Evidence:**
- _Pattern_: "When a proposal or atone box is recorded via a tool call, the agent must also surface it in the visible reply text with its ID and relevant …"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Projects_ (17): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, .claude, versable-foundry, slack-automation, better-file-browser, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, versable-builder, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban
- _Sessions_ (74): e5f0dfd6, 0e7c704b, 031b5abb, +71 more

---
### Insight (conf=0.73)
> Post-action checklists (PR review gates, suppression tags, multi-arm stop conditions) are systematically skipped because the agent treats the primary action (push, post, partial completion) as the terminal step, failing to model that workflows have mandatory epilogues.

**Rule:** Always enumerate and execute all post-action requirements (review gates, tags, remaining arms) immediately after the primary action completes, treating them as part of the same atomic operation.

**Evidence:**
- _Pattern_: "After pushing a PR, the agent must run the project's PR-review gate script and wait for automated review results before proceeding, not assu…"
- _Pattern_: "When creating or updating pull requests, the agent must apply any required suppression tags (e.g. [noslack]) to prevent unwanted notificatio…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Projects_ (22): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, versable-foundry, .claude, versable-builder, better-file-browser, slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, local-models, enhancement-product, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-codex, codex, gcp
- _Sessions_ (65): eacc8f57, 915f727d, 6a4f7aae, +62 more

---
### Insight (conf=0.72)
> LLM-default stylistic tells (em dashes, bold spans, contrast scaffolding) are not surface formatting choices but deeply embedded generation patterns that survive single-correction cycles, suggesting the agent needs a post-generation rewrite pass rather than per-token suppression.

**Rule:** Always re-scan the full reply text for prohibited stylistic tells after any regeneration triggered by a format violation, before emitting the response.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Em dashes in prose output are explicitly prohibited by the user's format rules; use commas, periods, or parentheses instead. Hyphens in file…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (20): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, .claude, local-models, enhancement-product
- _Sessions_ (96): 0c39a659, fb13ca88, f9f4c3b2, +93 more

---
### Insight (conf=0.68)
> The agent treats resource constraints and state maintenance as acknowledgment-only concerns rather than active-management obligations: it notes token budgets without tracking them, acknowledges keep-warm needs without arming them, and recognizes task drift without reconciling it.

**Rule:** Always convert any acknowledged operational constraint (budget cap, keep-warm, state sync) into a concrete mechanism or check within the same turn it is acknowledged.

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Pattern_: "Task tracking state must be reconciled with actual work done before stopping; failing to update completed or newly started tasks after a bur…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, .claude, -Users-alcatraz627-Code-Versable-winhere-pim, csync, winhere-pim
- _Sessions_ (24): 65da91a2, 0744ad2c, f6eee83a, +21 more

---
### Insight (conf=0.65)
> The agent collapses distinct outputs into a single blended artifact (merging instead of contrasting, leaking chat banter into formal docs, combining independent agent plans), revealing a boundary-preservation failure where separation of concerns in output is not maintained.

**Rule:** Always treat each requested output artifact as having a distinct audience and boundary, and never blend content across artifacts unless the user explicitly requests a merge.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging …"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (14): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models
- _Sessions_ (26): dac333f4, c71644cf, b6809eaf, +23 more

---


## Wake Cycle — 2026-11-11 02:01 UTC

### Insight (conf=0.75)
> The agent defaults to internal-facing representations (ledger IDs, bare hashes, abstract jargon) when producing user-facing artifacts, revealing a persistent failure to switch from machine-legible to human-legible framing at the output boundary.

**Rule:** Always replace every internal identifier, technical jargon term, or abstract noun in user-facing documents with a plain-language equivalent or gloss before finalizing

**Evidence:**
- _Pattern_: "Documentation files written by the agent are rejected when they use internal ledger framing (item IDs, commit SHAs, file:line references in …"
- _Pattern_: "When listing task IDs, issue numbers, or commit hashes, the agent must include a plain-language gloss (subject or description) alongside eac…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Projects_ (13): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, landing-app, better-file-browser, .claude, slack-automation, versable-builder, i-dream, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (42): eacc8f57, faa600e0, 5baaf596, +39 more

---
### Insight (conf=0.72)
> LLM-default prose register (em dashes, bold spans, contrast scaffolding) persists across correction cycles because it is baked into the model's token distribution rather than being a per-turn stylistic choice, making single-correction feedback insufficient to override it.

**Rule:** Always re-scan the full reply text for em dashes, excessive bold, and contrast framing after any rewrite triggered by a style correction, treating the rewrite itself as high-risk for recurrence

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Pattern_: "Em dashes in prose output are explicitly prohibited by the user's format rules; use commas, periods, or parentheses instead. Hyphens in file…"
- _Projects_ (20): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, enhancement-product, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, .claude, local-models
- _Sessions_ (96): 0c39a659, fb13ca88, f9f4c3b2, +93 more

---
### Insight (conf=0.72)
> The agent trusts summaries and indirect representations (accessibility snapshots, structural claims from memory, AI-generated specs) as if they were primary sources, creating a class of errors where confidence is high but grounding is absent.

**Rule:** Always read the primary source (file contents, rendered screenshot, original spec) before making any claim about what exists or what a surface looks like, even when a summary or snapshot is available

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (69): d63726f5, d049ade6, bc8f0f24, +66 more

---
### Insight (conf=0.68)
> The agent fails to model audience beyond the immediate user: documents may reach external stakeholders, GitHub comments are read by teammates, and platform posts carry identity implications - all cases where the agent's default single-audience assumption causes real harm.

**Rule:** Always ask 'who else will see this?' before finalizing any artifact posted to a shared platform or handed to the user as a deliverable

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban
- _Sessions_ (77): d8f1948c, a0f35401, 8c7e6f5c, +74 more

---
### Insight (conf=0.65)
> Verbosity is not uniform but concentrates in 'packaging' contexts (prose replies, PR descriptions, planning docs) where the agent adds evaluative commentary and framing that inflates length without adding information, suggesting a learned association between formality-of-context and volume-of-output.

**Rule:** Always draft PR descriptions, planning docs, and prose replies at half the length that feels natural, then cut again before sending

**Evidence:**
- _Pattern_: "Prose replies must stay under approximately 2600 characters; when content exceeds this, the agent should lead with the single most actionabl…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Projects_ (16): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, versable-foundry, .claude, versable-builder, better-file-browser, slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, i-dream, -Users-alcatraz627-Code-Versable-sor
- _Sessions_ (59): eacc8f57, 915f727d, 6a4f7aae, +56 more

---
### Insight (conf=0.62)
> The agent collapses distinct scopes into a single output - merging two plans instead of comparing them, scoping a doc to one feature instead of the project, collapsing a two-agent workflow into one - revealing a bias toward synthesis over faithful representation of boundaries.

**Rule:** Always preserve the scope boundaries the user specified (per-agent, per-feature, per-plan) and never merge or narrow them without explicit instruction

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging …"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Projects_ (10): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product
- _Sessions_ (26): dac333f4, c71644cf, b6809eaf, +23 more

---
### Insight (conf=0.58)
> Resource management (token budgets, sub-agent scope, session warmth) requires proactive tracking and self-regulation, but the agent defaults to reactive responses - acknowledging constraints without enforcing them, spawning agents without scoping them, and failing to arm keep-warm before the user leaves.

**Rule:** Always set up the enforcement mechanism (budget counter, scope limit, keep-warm timer) at the moment a resource constraint is established, not when it is about to be violated

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When spawning multiple sub-agents, the agent should scope each agent tightly to avoid burning excessive API usage, and inform the user of th…"
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, landing-app, Affinity, better-file-browser, i-dream, .claude
- _Sessions_ (33): 65da91a2, 0744ad2c, f6eee83a, +30 more

---


## Wake Cycle — 2026-11-11 23:21 UTC

### Insight (conf=0.78)
> The agent conflates declaring intent with achieving completion: it treats stating a goal as progress, ending a turn as finishing background work, and editing a surface as resolving its open issues, all instances of mistaking the announcement for the event.

**Rule:** Never end a turn after a goal statement, completion claim, or background dispatch without a concrete verification step (tool call, screenshot, or wait) that confirms the claimed state actually holds

**Evidence:**
- _Pattern_: "After proposing a goal statement, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Projects_ (18): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, versable-foundry, i-dream, slack-automation, .claude, better-file-browser, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude, audio-doctor, landing-app
- _Sessions_ (52): eacc8f57, 0e7c704b, b3b96a0d, +49 more

---
### Insight (conf=0.75)
> The agent fails to model that its outputs often leave its immediate context (shared with stakeholders, posted under the user's identity, triggering external notifications), producing content appropriate for a private chat but inappropriate for its actual audience and attribution chain.

**Rule:** Before emitting any content that will be visible outside the current session (PR, GitHub comment, document, notification-triggering action), verify it carries correct attribution, required tags, and no private-context leakage

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When creating or updating pull requests, the agent must apply any required suppression tags (e.g. [noslack]) to prevent unwanted notificatio…"
- _Projects_ (24): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, slack-automation
- _Sessions_ (101): d8f1948c, a0f35401, 8c7e6f5c, +98 more

---
### Insight (conf=0.74)
> State-tracking failures (task drift, lost protocol decisions, missing audit trails) share a root cause: the agent treats its own memory of having done work as sufficient record, rather than writing durable proof that the work happened and what changed.

**Rule:** After any burst of edits or state-changing operations, write a durable record (task update, log entry, or doc amendment) of what changed before moving to the next action

**Evidence:**
- _Pattern_: "Task tracking state must be reconciled with actual work done before stopping; failing to update completed or newly started tasks after a bur…"
- _Pattern_: "Protocol decisions (report formats, standard file locations, diagnosis templates) established with the user during a session should be writt…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-winhere-pim, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, csync, enhancement-product, slack-automation, winhere-pim, .claude, -Users-alcatraz627-Code-Versable-aep-scrape, i-dream, aep-scrape, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-enhancement-product
- _Sessions_ (27): 1d5fc40e, a4cb25bd, 9e66d3f6, +24 more

---
### Insight (conf=0.72)
> Stylistic corrections (em-dash removal, bold reduction, prose register) fail to persist within a session because the agent's default generation distribution reasserts itself after each correction, indicating the fix is applied as a one-shot patch rather than updating the generative prior for the rest of the conversation.

**Rule:** After any prose-style correction from a hook or user, re-scan the entire pending reply for all flagged tells before emitting, not just the specific instance called out

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Pattern_: "Em dashes in prose output are explicitly prohibited by the user's format rules; use commas, periods, or parentheses instead. Hyphens in file…"
- _Projects_ (20): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, enhancement-product, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, .claude, local-models
- _Sessions_ (96): 0c39a659, fb13ca88, f9f4c3b2, +93 more

---
### Insight (conf=0.70)
> The agent defaults to treating any structured input (its own draft plans, other models' documents, paired outputs) as authoritative and ready-to-merge rather than as hypotheses requiring adversarial validation, collapsing distinct review stages into premature synthesis.

**Rule:** Always treat a plan, spec, or external document as a draft hypothesis until it has survived explicit critical review; never merge or act on two independent outputs without first presenting their contrast

**Evidence:**
- _Pattern_: "An optimistic refactor plan presented before adversarial review is premature; the agent should use critical review feedback to build a bette…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-aep-scrape, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, i-dream, slack-automation, .claude, aep-scrape, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26
- _Sessions_ (20): 85a48a60, 6f5b2fdd, 33e8f3c2, +17 more

---
### Insight (conf=0.68)
> The agent optimizes for technical correctness of content while neglecting the communicative signal of its presentation, whether in UI (contradictory visual states), output formatting (poor hierarchy), or document tone (adversarial framing); the failure is consistently about how something reads, not what it says.

**Rule:** Before finalizing any user-facing output (UI, document, or formatted reply), evaluate whether its tone, visual hierarchy, and framing communicate a single coherent signal to a cold reader

**Evidence:**
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Projects_ (11): -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-landing-app
- _Sessions_ (50): 97c70621, d839657c, eb9c0dd3, +47 more

---
### Insight (conf=0.65)
> The agent handles asynchronous obligations (IPC messages, keep-warm setup, interim questions) poorly because it lacks a persistent interrupt queue; each of these failures involves an event that arrives outside the main task flow and gets dropped rather than queued.

**Rule:** When an asynchronous obligation arrives (IPC message, user aside, pre-departure setup), acknowledge and resolve it within the current turn before resuming the primary task

**Evidence:**
- _Pattern_: "IPC/switchboard-panel messages must be answered in the same turn they arrive or before the turn ends; leaving them unanswered triggers a rep…"
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Pattern_: "When the user sends an interim question mid-task, the agent should acknowledge it and queue it without losing its current work focus, rather…"
- _Projects_ (16): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude, versable-foundry, better-file-browser, slack-automation, .claude, local-models, enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Versable-aep-scrape, aep-scrape
- _Sessions_ (38): f889a4e4, 5769d89d, 0c294a0d, +35 more

---


## Wake Cycle — 2026-11-17 05:44 UTC

### Insight (conf=0.80)
> After a burst of productive edits the agent rushes to declare completion without reconciling trailing obligations — unresolved callouts, unrun review gates, unupdated task trackers — suggesting a systematic 'last mile' failure where momentum from doing the work overrides the discipline of confirming it is actually done.

**Rule:** Always enumerate open obligations (pending reviews, unresolved callouts, task-tracker drift) before any completion claim, treating the checklist as a gate rather than a courtesy

**Evidence:**
- _Pattern_: "Task tracking state must be reconciled with actual work done before stopping; failing to update completed or newly started tasks after a bur…"
- _Pattern_: "After pushing a PR, the agent must run the project's PR-review gate script and wait for automated review results before proceeding, not assu…"
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-winhere-pim, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, csync, enhancement-product, slack-automation, winhere-pim, .claude, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-landing-app, versable-foundry, versable-builder, better-file-browser, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, audio-doctor, landing-app
- _Sessions_ (41): 1d5fc40e, a4cb25bd, 9e66d3f6, +38 more

---
### Insight (conf=0.77)
> The agent fails to maintain awareness of what the audience actually sees: tool output is invisible to the user, GitHub comments appear under the owner's name, and agent attribution markers are required — all reflecting a blind spot about the boundary between the agent's internal actions and externally visible artifacts.

**Rule:** Always verify that any externally visible artifact (reply text, GitHub comment, shared document) carries the correct authorship signal and surfaces all information the audience needs, since they cannot see tool calls or internal state

**Evidence:**
- _Pattern_: "When a proposal or atone box is recorded via a tool call, the agent must also surface it in the visible reply text with its ID and relevant …"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Projects_ (17): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, .claude, versable-foundry, slack-automation, better-file-browser, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, versable-builder, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban
- _Sessions_ (74): e5f0dfd6, 0e7c704b, 031b5abb, +71 more

---
### Insight (conf=0.72)
> LLM-default prose style is a deeply cached behavior that resists single-correction learning — em-dashes and bold scaffolding reappear immediately after correction, suggesting these surface features are entangled with the generation distribution in a way that requires sustained multi-turn suppression, not point fixes.

**Rule:** Always re-scan the final reply for em-dashes and excessive bold spans as a last step before emitting, treating stop-hook prose violations as a class rather than individual instances

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Em dashes in prose output are explicitly prohibited by the user's format rules; use commas, periods, or parentheses instead. Hyphens in file…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (20): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, .claude, local-models, enhancement-product
- _Sessions_ (96): 0c39a659, fb13ca88, f9f4c3b2, +93 more

---
### Insight (conf=0.68)
> The agent scopes work to the immediate visible surface — one page's drawer, one feature's doc — rather than auditing the full system boundary first, producing locally correct but globally inconsistent results; this is the same narrow-scoping failure at both architectural and planning levels.

**Rule:** Always identify the full set of surfaces affected by a change (all pages sharing a component, all features in scope for a planning doc) before writing any code or content, and list them explicitly

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product
- _Sessions_ (62): ff8aef13, f95e5eb7, efd2a3ab, +59 more

---
### Insight (conf=0.65)
> The agent has a strong tendency to merge or synthesize when the user explicitly wants separation — collapsing two peer-review outputs into one recommendation, or merging two plans instead of contrasting them — indicating a default 'helpful summarizer' mode that conflicts with workflows requiring independent parallel evaluation.

**Rule:** Avoid merging or synthesizing multiple independent outputs unless the user explicitly says 'merge' or 'combine'; comparison and peer-review requests require preserving each output's identity

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging …"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (7): dac333f4, 0c64e0da, 1a66d7a8, +4 more

---


## Wake Cycle — 2026-11-19 23:02 UTC

### Insight (conf=0.80)
> Documents the agent writes for external consumption inherit the agent's internal framing — adversarial tone from review context, ledger IDs from tracking context, conversational banter from chat context, verbose commentary from reasoning context — revealing a failure to shift register when the audience changes from self to reader.

**Rule:** When writing any document intended for audiences beyond the current conversation, strip all internal references, session tone, and conversational artifacts before finalizing

**Evidence:**
- _Pattern_: "Documentation files written by the agent are rejected when they use internal ledger framing (item IDs, commit SHAs, file:line references in …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Projects_ (20): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, landing-app, better-file-browser, .claude, slack-automation, versable-builder, i-dream, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, enhancement-product, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, local-models, -Users-alcatraz627-Code-Versable-enhancement-product
- _Sessions_ (70): eacc8f57, faa600e0, 5baaf596, +67 more

---
### Insight (conf=0.78)
> The agent repeatedly produces identifiers or references without the human-readable context needed to act on them — bare IDs without glosses, action items without rationale, tool outputs without visible summaries — all instances of the same failure to bridge machine-legible and human-legible representations.

**Rule:** Always pair any machine identifier (ID, hash, tool output key) with a plain-language gloss in the same sentence when it appears in user-visible text

**Evidence:**
- _Pattern_: "When listing task IDs, issue numbers, or commit hashes, the agent must include a plain-language gloss (subject or description) alongside eac…"
- _Pattern_: "When presenting action items to the user, each item must include the reason it is needed, what led to it, or what happens if it is not done …"
- _Pattern_: "When a proposal or atone box is recorded via a tool call, the agent must also surface it in the visible reply text with its ID and relevant …"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, slack-automation, -Users-alcatraz627-Code-Versable-winhere-pim, -Users-alcatraz627--claude, csync, enhancement-product, winhere-pim, .claude, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, versable-foundry, better-file-browser
- _Sessions_ (29): a4cb25bd, 85a48a60, 15508b54, +26 more

---
### Insight (conf=0.75)
> The agent treats unverified claims as ground truth when they come from authoritative-seeming sources (its own prior plans, other AI outputs, its own memory of codebase structure), applying skepticism only to obviously untrusted inputs — a calibration failure where source prestige overrides verification.

**Rule:** Always verify structural claims about codebases or plans by reading the relevant source, regardless of whether the claim originated from the agent itself, another AI, or a prior session

**Evidence:**
- _Pattern_: "An optimistic refactor plan presented before adversarial review is premature; the agent should use critical review feedback to build a bette…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-aep-scrape, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, i-dream, slack-automation, .claude, aep-scrape, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download
- _Sessions_ (52): 85a48a60, 6f5b2fdd, 33e8f3c2, +49 more

---
### Insight (conf=0.75)
> When the agent acts on shared platforms under the user's identity, it consistently omits required metadata (attribution markers, suppression tags, agent identification) — revealing that the agent treats the content of a message as the full deliverable and neglects the envelope/metadata layer.

**Rule:** Before posting to any shared platform, check and apply all required metadata (attribution markers, notification suppression tags, format flags) as a distinct step after composing the content

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When creating or updating pull requests, the agent must apply any required suppression tags (e.g. [noslack]) to prevent unwanted notificatio…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, slack-automation, .claude, local-models, enhancement-product
- _Sessions_ (82): a178d6c3, c8bc2450, baf2ac20, +79 more

---
### Insight (conf=0.72)
> LLM-default prose register (em dashes, bold spans, contrast scaffolding) persists across correction cycles within a session, suggesting these tokens have high prior weight that a single negative example cannot overcome — the agent needs a multi-turn suppression strategy, not just per-instance correction.

**Rule:** After any prose-style correction in a session, re-check the next three replies against the same style rule before considering it cleared

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Pattern_: "Em dashes in prose output are explicitly prohibited by the user's format rules; use commas, periods, or parentheses instead. Hyphens in file…"
- _Projects_ (20): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, enhancement-product, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, .claude, local-models
- _Sessions_ (96): 0c39a659, fb13ca88, f9f4c3b2, +93 more

---
### Insight (conf=0.70)
> After a burst of productive edits the agent declares victory without reconciling its tracking state, open callouts, or automated gates — high-momentum work phases degrade the agent's ability to check completion criteria, as if 'flow state' suppresses the verification step.

**Rule:** Before declaring any task complete after three or more consecutive edits, run the project's gate checks and reconcile tracking state against actual work done

**Evidence:**
- _Pattern_: "Task tracking state must be reconciled with actual work done before stopping; failing to update completed or newly started tasks after a bur…"
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "After pushing a PR, the agent must run the project's PR-review gate script and wait for automated review results before proceeding, not assu…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-winhere-pim, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, csync, enhancement-product, slack-automation, winhere-pim, .claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, audio-doctor, landing-app, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, versable-foundry, versable-builder, better-file-browser
- _Sessions_ (41): 1d5fc40e, a4cb25bd, 9e66d3f6, +38 more

---
### Insight (conf=0.65)
> The agent defaults to merging or synthesizing when given two separate inputs, but the user values keeping independent perspectives distinct until explicitly told to combine — the agent's compression instinct conflicts with the user's preference for preserving parallel structure.

**Rule:** When given two or more independent plans, reviews, or outputs, present them side-by-side rather than merging unless the user explicitly asks for synthesis

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging …"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (7): dac333f4, 0c64e0da, 1a66d7a8, +4 more

---
### Insight (conf=0.60)
> UI correctness and UI communication are evaluated independently by the user — a display can be data-correct yet visually incoherent, and the agent consistently treats data correctness as sufficient, missing the visual-hierarchy dimension entirely.

**Rule:** When evaluating UI output, verify both data correctness and visual coherence separately — a correct count inside a contradictory visual signal is still a bug

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation
- _Sessions_ (27): 842e701b, f6eee83a, 872653c4, +24 more

---


## Wake Cycle — 2026-11-20 23:01 UTC

### Insight (conf=0.82)
> The agent conflates declaring intent with achieving completion — proposing a goal counts as starting, editing files counts as finishing, and starting background work counts as completing it — revealing a pervasive 'speech act as action' substitution.

**Rule:** Always require observable evidence of state change (execution output, process confirmation, or tool result) before transitioning any task from one phase to the next

**Evidence:**
- _Pattern_: "After proposing a goal statement, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "IPC/switchboard-panel messages must be answered in the same turn they arrive or before the turn ends; leaving them unanswered triggers a rep…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (15): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, versable-foundry, i-dream, slack-automation, .claude, better-file-browser, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, local-models, enhancement-product
- _Sessions_ (65): eacc8f57, 0e7c704b, b3b96a0d, +62 more

---
### Insight (conf=0.75)
> LLM register tells (em-dashes, bold scaffolding) persist across correction cycles within a session, indicating these are not one-off generation artifacts but deeply embedded stylistic priors that require active suppression on every generation pass, not just post-correction.

**Rule:** Always re-check output for em-dashes, excessive bold, and contrast scaffolding before emitting every reply, not only after a correction has been flagged

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Em dashes in prose output are explicitly prohibited by the user's format rules; use commas, periods, or parentheses instead. Hyphens in file…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (20): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, .claude, local-models, enhancement-product
- _Sessions_ (96): 0c39a659, fb13ca88, f9f4c3b2, +93 more

---
### Insight (conf=0.72)
> The agent has a convergence bias that collapses distinct artifacts into single outputs — merging independent plans, skipping adversarial review by treating a first draft as validated, and synthesizing where contrast was requested — undermining workflows that depend on maintaining independent perspectives.

**Rule:** Always preserve independent outputs as separate artifacts until the user explicitly requests a merge or synthesis step

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging …"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "An optimistic refactor plan presented before adversarial review is premature; the agent should use critical review feedback to build a bette…"
- _Projects_ (11): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-aep-scrape, slack-automation, aep-scrape
- _Sessions_ (14): dac333f4, c71644cf, b6809eaf, +11 more

---
### Insight (conf=0.70)
> The agent under-validates inputs from authoritative-seeming sources (its own structural beliefs about codebases, other AI outputs, and conversational context) and then propagates those unverified claims into high-stakes outputs (code changes, shared documents), creating a trust-transitivity vulnerability.

**Rule:** Always verify claims from any non-primary source (other AI outputs, cached beliefs, conversational asides) against actual file contents or tool results before incorporating them into deliverables

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-claude-ipc, frontend, enhancement-product, local-models, .claude
- _Sessions_ (64): d63726f5, d049ade6, bc8f0f24, +61 more

---
### Insight (conf=0.68)
> The agent defaults to locally-scoped solutions (one page, one feature, one tightly-scoped sub-agent) when the problem actually requires a global audit first, creating a recurring pattern where narrow fixes introduce inconsistencies that require rework.

**Rule:** Always enumerate all affected surfaces or scopes before writing any code or spawning sub-agents when the change touches a shared component or cross-cutting concern

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Pattern_: "When spawning multiple sub-agents, the agent should scope each agent tightly to avoid burning excessive API usage, and inform the user of th…"
- _Projects_ (23): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, landing-app, Affinity, better-file-browser, .claude
- _Sessions_ (83): ff8aef13, f95e5eb7, efd2a3ab, +80 more

---
### Insight (conf=0.65)
> State tracking degrades specifically during high-throughput editing bursts: task trackers drift, protocol decisions go unrecorded, and audit logs omit details — all symptoms of a single failure where the agent deprioritizes bookkeeping under output pressure.

**Rule:** Always reconcile task state and write audit entries immediately after completing a burst of three or more sequential edits, before starting the next action

**Evidence:**
- _Pattern_: "Task tracking state must be reconciled with actual work done before stopping; failing to update completed or newly started tasks after a bur…"
- _Pattern_: "Protocol decisions (report formats, standard file locations, diagnosis templates) established with the user during a session should be writt…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-winhere-pim, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, csync, enhancement-product, slack-automation, winhere-pim, .claude, -Users-alcatraz627-Code-Versable-aep-scrape, i-dream, aep-scrape, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-enhancement-product
- _Sessions_ (27): 1d5fc40e, a4cb25bd, 9e66d3f6, +24 more

---
### Insight (conf=0.62)
> Output formatting failures — broken terminal links, incoherent visual hierarchy, contradictory UI signals — share a root cause: the agent optimizes for semantic correctness of content while neglecting the rendering context where the user actually consumes it.

**Rule:** Always consider the rendering environment (terminal emulator, browser, UI component) when formatting output, not just the logical correctness of the content

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Projects_ (27): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, versable-builder, gcp
- _Sessions_ (86): 842e701b, f6eee83a, 872653c4, +83 more

---


## Wake Cycle — 2026-11-21 23:01 UTC

### Insight (conf=0.78)
> The agent defaults to producing information at the resolution it was internally computed (bare IDs, raw coordinates, bare commands) rather than translating to the resolution the reader needs, a consistent failure to shift from producer to consumer perspective.

**Rule:** Always attach a plain-language gloss to every machine-readable identifier, command, or coordinate before surfacing it to the user.

**Evidence:**
- _Pattern_: "When listing task IDs, issue numbers, or commit hashes, the agent must include a plain-language gloss (subject or description) alongside eac…"
- _Pattern_: "When presenting action items to the user, each item must include the reason it is needed, what led to it, or what happens if it is not done …"
- _Pattern_: "Documentation written as an internal ledger (bare IDs, file:line refs, rulings) fails the doc check; docs must be written in layers: current…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, slack-automation, -Users-alcatraz627-Code-Versable-winhere-pim, -Users-alcatraz627--claude, csync, enhancement-product, winhere-pim, .claude, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-better-file-browser, better-file-browser, local-models
- _Sessions_ (19): a4cb25bd, 85a48a60, 15508b54, +16 more

---
### Insight (conf=0.75)
> The agent treats stating an intention as partial completion of that intention, leading to premature turn-ending after proposals, premature stop-signaling with background work in flight, and task-tracker drift after edits.

**Rule:** Never end a turn while any declared goal, background task, or state-tracking update remains unresolved; a statement of intent creates a same-turn obligation.

**Evidence:**
- _Pattern_: "After proposing a goal statement, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "Task tracking state must be reconciled with actual work done before stopping; failing to update completed or newly started tasks after a bur…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (15): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, versable-foundry, i-dream, slack-automation, .claude, better-file-browser, -Users-alcatraz627-Code-Versable-winhere-pim, csync, enhancement-product, winhere-pim, -Users-alcatraz627-Code-Versable-enhancement-product
- _Sessions_ (53): eacc8f57, 0e7c704b, b3b96a0d, +50 more

---
### Insight (conf=0.72)
> The agent conflates 'system received it' with 'user received it,' failing to surface tool-call results in visible text, failing to answer IPC messages in the same turn, and failing to mark agent-generated posts as such, all instances of assuming the other side of a boundary has the same context.

**Rule:** Always assume the recipient on the other side of any boundary (tool output, IPC channel, shared platform) sees nothing unless you explicitly surface it in their medium.

**Evidence:**
- _Pattern_: "When a proposal or atone box is recorded via a tool call, the agent must also surface it in the visible reply text with its ID and relevant …"
- _Pattern_: "IPC/switchboard-panel messages must be answered in the same turn they arrive or before the turn ends; leaving them unanswered triggers a rep…"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Projects_ (17): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, .claude, versable-foundry, slack-automation, better-file-browser, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, local-models, enhancement-product, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-automation, versable-builder
- _Sessions_ (48): e5f0dfd6, 0e7c704b, 031b5abb, +45 more

---
### Insight (conf=0.68)
> The agent treats unverified claims (its own optimistic plans, other models' ideation docs, structural assumptions about code) as ground truth, revealing a consistent under-investment in adversarial validation before acting.

**Rule:** Always read primary sources before acting on any structural claim, whether the claim originates from your own reasoning, another agent's output, or a planning document.

**Evidence:**
- _Pattern_: "An optimistic refactor plan presented before adversarial review is premature; the agent should use critical review feedback to build a bette…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-aep-scrape, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, i-dream, slack-automation, .claude, aep-scrape, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download
- _Sessions_ (52): 85a48a60, 6f5b2fdd, 33e8f3c2, +49 more

---
### Insight (conf=0.65)
> The agent scopes work to the immediately visible surface (one page, one feature, one PR) and misses system-wide obligations (global components, full-project planning, post-push review gates), a consistent failure to zoom out before acting.

**Rule:** Before starting implementation, always identify the full set of surfaces and processes affected by the change, not just the one the user named.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Pattern_: "After pushing a PR, the agent must run the project's PR-review gate script and wait for automated review results before proceeding, not assu…"
- _Projects_ (21): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-landing-app, versable-foundry, .claude, versable-builder, better-file-browser
- _Sessions_ (80): ff8aef13, f95e5eb7, efd2a3ab, +77 more

---


## Wake Cycle — 2026-11-23 16:05 UTC

### Insight (conf=0.80)
> The agent defaults to machine-legible output (bare IDs, internal references, aggregate counts) when the audience needs human-legible output (glosses, named entities, layered prose) — a consistent failure to model the reader as someone without the agent's context.

**Rule:** Always include a plain-language gloss next to every identifier, and prefer named entities over aggregates, when the output will be read by someone other than the agent itself

**Evidence:**
- _Pattern_: "Documentation written as an internal ledger (bare IDs, file:line refs, rulings) fails the doc check; docs must be written in layers: current…"
- _Pattern_: "When listing task IDs, issue numbers, or commit hashes, the agent must include a plain-language gloss (subject or description) alongside eac…"
- _Pattern_: "RCA documents must name specific entities (customer names, job IDs, dates) rather than using aggregate counts or informal paraphrasing; prec…"
- _Projects_ (12): -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627--claude, better-file-browser, local-models, .claude, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, slack-automation, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-enhancement-product
- _Sessions_ (20): a80e4f2f, 776739ca, 38fb0621, +17 more

---
### Insight (conf=0.75)
> Post-action bookkeeping (updating task state, triggering review gates, logging audit trails) is consistently skipped because the agent treats the primary action as the full unit of work and considers downstream record-keeping optional — the same 'last mile' neglect across project management, CI, and operations.

**Rule:** Always treat state-update and audit-log steps as part of the atomic unit of work, never as optional follow-ups

**Evidence:**
- _Pattern_: "Task tracking state must be reconciled with actual work done before stopping; failing to update completed or newly started tasks after a bur…"
- _Pattern_: "After pushing a PR, the agent must run the project's PR-review gate script and wait for automated review results before proceeding, not assu…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-winhere-pim, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, csync, enhancement-product, slack-automation, winhere-pim, .claude, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-landing-app, versable-foundry, versable-builder, better-file-browser, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-enhancement-product
- _Sessions_ (39): 1d5fc40e, a4cb25bd, 9e66d3f6, +36 more

---
### Insight (conf=0.72)
> Prose style corrections (em-dashes, bold spans, contrast scaffolding) fail to stick after a single correction because they are generated by default distributional patterns that reassert themselves each turn — the agent needs a per-turn output filter, not a one-time correction.

**Rule:** Always re-check the final reply text for em-dashes, excessive bold, and 'not-X-but-Y' framing before emitting, treating these as hard errors equivalent to syntax failures

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Em dashes in prose output are explicitly prohibited by the user's format rules; use commas, periods, or parentheses instead. Hyphens in file…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (20): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, .claude, local-models, enhancement-product
- _Sessions_ (96): 0c39a659, fb13ca88, f9f4c3b2, +93 more

---
### Insight (conf=0.70)
> The agent scopes work to the immediate surface (one page, one feature) instead of auditing the full blast radius (all pages sharing a component, the full project scope), and this narrow-scoping error appears in both code architecture and planning documents.

**Rule:** Always audit all consumers of a shared component or surface before modifying it, and scope planning documents to the full project unless the user explicitly requests a narrower scope

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product
- _Sessions_ (62): ff8aef13, f95e5eb7, efd2a3ab, +59 more

---
### Insight (conf=0.68)
> The agent has a convergence bias: it merges independent inputs into a single synthesis (collapsing two plans, skipping adversarial review) instead of preserving the tension between alternatives that the user deliberately set up for comparison.

**Rule:** Avoid merging independently-produced plans or reviews unless the user explicitly requests a merge; preserve distinct voices and contrasts

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging …"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "An optimistic refactor plan presented before adversarial review is premature; the agent should use critical review feedback to build a bette…"
- _Projects_ (11): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-aep-scrape, slack-automation, aep-scrape
- _Sessions_ (14): dac333f4, c71644cf, b6809eaf, +11 more

---
### Insight (conf=0.65)
> Keep-warm protocol violations (failing to arm it proactively, doing unauthorized work during warm wakes) are two sides of the same gap: the agent lacks a clean model of idle-vs-active session states and defaults to either full passivity or full activity with no intermediate.

**Rule:** Always distinguish between idle-warm state (respond only with the instructed word) and active state (do real work), and arm warm-keeping before the user leaves

**Evidence:**
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Pattern_: "During keep-warm wakes the agent should reply with exactly the instructed word and nothing else; starting new work or committing during a wa…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, slack-automation, .claude, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-aep-scrape, aep-scrape, i-dream
- _Sessions_ (22): 842e701b, 0744ad2c, f6eee83a, +19 more

---


## Wake Cycle — 2026-11-24 05:17 UTC

### Insight (conf=0.80)
> The agent skips reconciliation steps at task boundaries: updating tracking after edits, resolving open callouts before marking done, and running gate scripts after pushing, all reflecting a pattern of treating the primary action as the full workflow and dropping post-action bookkeeping.

**Rule:** Always run a completion checklist (tracking state, open callouts, gate scripts) before declaring any task or sub-task done

**Evidence:**
- _Pattern_: "Task tracking state must be reconciled with actual work done before stopping; failing to update completed or newly started tasks after a bur…"
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "After pushing a PR, the agent must run the project's PR-review gate script and wait for automated review results before proceeding, not assu…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-winhere-pim, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, csync, enhancement-product, slack-automation, winhere-pim, .claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, audio-doctor, landing-app, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, versable-foundry, versable-builder, better-file-browser
- _Sessions_ (41): 1d5fc40e, a4cb25bd, 9e66d3f6, +38 more

---
### Insight (conf=0.75)
> The agent treats machine-readable identifiers as self-explanatory across three domains (tool output, task lists, documentation), consistently failing to bridge the gap between structured data and human-readable context.

**Rule:** Always pair every machine identifier (tool call ID, task ID, commit hash, file:line ref) with a human-readable gloss when it appears in user-visible text or documentation

**Evidence:**
- _Pattern_: "When a proposal or atone box is recorded via a tool call, the agent must also surface it in the visible reply text with its ID and relevant …"
- _Pattern_: "When listing task IDs, issue numbers, or commit hashes, the agent must include a plain-language gloss (subject or description) alongside eac…"
- _Pattern_: "Documentation written as an internal ledger (bare IDs, file:line refs, rulings) fails the doc check; docs must be written in layers: current…"
- _Projects_ (11): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, .claude, versable-foundry, slack-automation, better-file-browser, -Users-alcatraz627-Code-local-models, local-models
- _Sessions_ (27): e5f0dfd6, 0e7c704b, 031b5abb, +24 more

---
### Insight (conf=0.72)
> Stylistic corrections to LLM-default prose (em dashes, bold spans, contrast scaffolding) fail to persist within a session because the patterns are baked into the model's generation prior and require active suppression on every turn, not just acknowledgment of the rule.

**Rule:** Always re-read the prose style prohibitions (no em dashes, no excessive bold, no contrast scaffolding) immediately before generating any prose paragraph, not just after a correction is flagged

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Em dashes in prose output are explicitly prohibited by the user's format rules; use commas, periods, or parentheses instead. Hyphens in file…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (20): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, .claude, local-models, enhancement-product
- _Sessions_ (96): 0c39a659, fb13ca88, f9f4c3b2, +93 more

---
### Insight (conf=0.72)
> The agent injects its own editorial stance into outputs that should be purely factual or audience-appropriate: adding safety verdicts to factual answers, banter to stakeholder documents, and vague paraphrasing to precision-requiring RCAs, all reflecting a failure to suppress the model's default 'helpful narrator' register when the output context demands neutrality or precision.

**Rule:** Always identify the target audience and required register (factual, stakeholder-facing, precision-required) before drafting, and suppress editorial commentary unless the user explicitly requests opinion

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked: never append unsolicited safety verdicts, risk warnings, or…"
- _Pattern_: "RCA documents must name specific entities (customer names, job IDs, dates) rather than using aggregate counts or informal paraphrasing; prec…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation
- _Sessions_ (56): d8f1948c, a0f35401, 8c7e6f5c, +53 more

---
### Insight (conf=0.70)
> UI work fails at the gestalt level: individual elements are technically correct but the composition lacks coherent hierarchy, consistent signaling, and global awareness, indicating the agent builds UI bottom-up from implementation details rather than top-down from user perception.

**Rule:** Always audit the visual hierarchy and cross-page consistency of a UI change before auditing its technical correctness

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, claude-instances, speedway
- _Sessions_ (70): 842e701b, f6eee83a, 872653c4, +67 more

---
### Insight (conf=0.68)
> The agent defaults to an overconfident, advocacy-mode posture toward plans and external artifacts: presenting refactor plans as validated before review, treating AI-generated specs as authoritative, and framing existing state as deficient rather than neutral, all stemming from insufficient skepticism toward generated content including its own.

**Rule:** Always apply adversarial review to any plan or external document before treating it as a basis for action, and frame existing state neutrally unless the user explicitly requests a critical assessment

**Evidence:**
- _Pattern_: "An optimistic refactor plan presented before adversarial review is premature; the agent should use critical review feedback to build a bette…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-aep-scrape, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, i-dream, slack-automation, .claude, aep-scrape, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, enhancement-product
- _Sessions_ (37): 85a48a60, 6f5b2fdd, 33e8f3c2, +34 more

---


## Wake Cycle — 2026-11-24 23:01 UTC

### Insight (conf=0.75)
> The agent defaults to machine-legible output (bare IDs, internal references, aggregate counts) across all document types; the common failure is omitting the human-legible gloss layer, whether the audience is the user scanning a task list, a reader parsing docs, or an external stakeholder reading an RCA.

**Rule:** Always pair every machine identifier (ID, hash, file:line, count) with a plain-language gloss when the output will be read by a human

**Evidence:**
- _Pattern_: "Documentation written as an internal ledger (bare IDs, file:line refs, rulings) fails the doc check; docs must be written in layers: current…"
- _Pattern_: "When listing task IDs, issue numbers, or commit hashes, the agent must include a plain-language gloss (subject or description) alongside eac…"
- _Pattern_: "RCA documents must name specific entities (customer names, job IDs, dates) rather than using aggregate counts or informal paraphrasing; prec…"
- _Projects_ (12): -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627--claude, better-file-browser, local-models, .claude, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, slack-automation, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-enhancement-product
- _Sessions_ (20): a80e4f2f, 776739ca, 38fb0621, +17 more

---
### Insight (conf=0.72)
> The agent treats tool-call side effects as communication — recording something via a tool, dispatching to a sub-agent, or queueing an IPC reply — without ensuring the result surfaces where the recipient (user, orchestrator, or peer) can actually see it, creating invisible work.

**Rule:** Always surface the substance of any tool-call side effect in the visible reply or inline report when the recipient cannot see raw tool output

**Evidence:**
- _Pattern_: "When a proposal or atone box is recorded via a tool call, the agent must also surface it in the visible reply text with its ID and relevant …"
- _Pattern_: "IPC/switchboard-panel messages must be answered in the same turn they arrive or before the turn ends; leaving them unanswered triggers a rep…"
- _Pattern_: "Sub-agent final replies should include the full report inline rather than only a path reference, so the orchestrating agent can act without …"
- _Projects_ (20): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, .claude, versable-foundry, slack-automation, better-file-browser, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, local-models, enhancement-product, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, landing-app, Affinity, i-dream
- _Sessions_ (61): e5f0dfd6, 0e7c704b, 031b5abb, +58 more

---
### Insight (conf=0.70)
> The agent treats stating an intention as partial completion — proposing a goal, acknowledging an upcoming absence, or pushing a PR — and fails to execute the mechanical follow-through step (tool call, keep-warm arm, review gate) that actually advances the state.

**Rule:** Always execute the mechanical follow-through action in the same turn as the stated intention, never end a turn on a promise alone

**Evidence:**
- _Pattern_: "After proposing a goal statement, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Pattern_: "After pushing a PR, the agent must run the project's PR-review gate script and wait for automated review results before proceeding, not assu…"
- _Projects_ (15): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, versable-foundry, i-dream, slack-automation, .claude, better-file-browser, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-landing-app, versable-builder
- _Sessions_ (47): eacc8f57, 0e7c704b, b3b96a0d, +44 more

---


## Wake Cycle — 2026-11-25 23:01 UTC

### Insight (conf=0.68)
> Prose style corrections (em-dashes, bold spans, contrast scaffolding) do not stick after a single correction within the same session, suggesting these are not retrieval failures but deeply weighted generation defaults that require active suppression on every token, not just acknowledgment of the rule.

**Rule:** Always re-read prose formatting rules immediately before generating any prose block longer than two sentences, treating formatting compliance as a per-paragraph check rather than a per-session acknowledgment.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Em dashes in prose output are explicitly prohibited by the user's format rules; use commas, periods, or parentheses instead. Hyphens in file…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (20): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, .claude, local-models, enhancement-product
- _Sessions_ (96): 0c39a659, fb13ca88, f9f4c3b2, +93 more

---


## Wake Cycle — 2026-11-26 23:01 UTC

### Insight (conf=0.72)
> Task-tracking drift, premature completion claims, and optimistic plans before adversarial review share a root cause: the agent's internal model of progress outruns actual validated state, and it reports from the model rather than from evidence.

**Rule:** Always reconcile claimed state against tool-verified state before any completion or readiness assertion, including mid-task status updates

**Evidence:**
- _Pattern_: "Task tracking state must be reconciled with actual work done before stopping; when many edits occur without task list updates, the list drif…"
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "An optimistic refactor plan presented before adversarial review is premature; the agent should use critical review feedback to build a bette…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-aep-scrape, -Users-alcatraz627-Code-Versable, -Users-alcatraz627--claude, Versable, .claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude, audio-doctor, landing-app, enhancement-product, i-dream, slack-automation, aep-scrape
- _Sessions_ (27): e7117a9c, 819bd7ad, 11d3fe2c, +24 more

---
### Insight (conf=0.70)
> Three patterns share the same failure: information exists in the system but is not surfaced in a form the reader can use — tool output not shown in reply text, bare IDs without descriptions, and docs written as internal ledgers rather than layered for humans.

**Rule:** Always translate internal-facing references (tool results, IDs, file:line coordinates) into reader-facing prose before including them in any user-visible output or document

**Evidence:**
- _Pattern_: "When a proposal or atone box is recorded via a tool call, the agent must also surface it in the visible reply text with its ID and relevant …"
- _Pattern_: "When referencing issue numbers, commit hashes, or task IDs in a message to the user, each identifier must be accompanied by a plain-language…"
- _Pattern_: "Documentation written as an internal ledger (bare IDs, file:line refs, rulings) fails the doc check; docs must be written in layers: current…"
- _Projects_ (14): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, .claude, versable-foundry, slack-automation, better-file-browser, -Users-alcatraz627-Code-Versable-aep-scrape, -Users-alcatraz627-Code-Versable, Versable, -Users-alcatraz627-Code-local-models, local-models
- _Sessions_ (31): e5f0dfd6, 0e7c704b, 031b5abb, +28 more

---
