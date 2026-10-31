# Dream Insights

_High-confidence associations promoted by the Wake phase._

## Wake Cycle: 2026-10-05 18:15 UTC

### Insight (conf=0.52)
> The agent systematically confuses proxy verification (type-check, lint, a11y snapshot, code read) with ground-truth verification (running the code, rendering the UI, clicking the button), and this confusion is structurally identical whether the domain is tests, UI rendering, or accessibility: the underlying failure is treating any green signal as THE green signal.

**Rule:** Always name the specific verification layer used (static/structural/runtime/visual) and never claim 'verified' or 'works' unless the layer matches the claim's domain: a type-check verifies types, not behavior; a snapshot verifies structure, not appearance.

**Evidence:**
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "Shipping code and reporting a visual feature as complete without rendering and viewing the actual target state (not just green tests) produc…"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, .claude, i-dream, claude-ipc
- _Sessions_ (132): 1cd54c1d, 14422091, 06fa3e6a, +129 more

---
### Insight (conf=0.78)
> The agent systematically substitutes a cheaper available proxy for the expensive ground-truth check: lint for execution, a11y snapshot for visual render, memory for file read, merge button visibility for merge-state API: and the substitution is invisible to the agent because the proxy genuinely correlates with truth in the common case; it fails only at the boundary the user cares about.

**Rule:** When about to claim a state (works, looks right, is mergeable, exists), name the instrument that measured it: if the instrument is a proxy (type-check, snapshot, memory, UI element), escalate to the direct measurement before the claim.

**Evidence:**
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, gcp, better-file-browser
- _Sessions_ (163): 1cd54c1d, 14422091, 06fa3e6a, +160 more

---
### Insight (conf=0.72)
> The agent treats acknowledging a rule violation as equivalent to fixing it: the same 'description substitutes for action' failure that causes premature done-claims also causes in-session formatting relapses, because the correction modifies stated intent without altering the generative distribution that produced the violation.

**Rule:** After any hook or user correction fires for a formatting or prose rule, re-read the corrected output character-by-character before sending the next reply that could re-trigger it: treat the correction as a pre-send gate, not a post-send note.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Projects_ (28): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor
- _Sessions_ (160): 0c39a659, fb13ca88, f9f4c3b2, +157 more

---
### Insight (conf=0.70)
> The agent optimizes for output fluency (how text reads in generation) rather than consumption interface fidelity (how the user's terminal, tools, or eyes will parse it): paths get tucked into syntactically natural positions that break Ghostty linking, answers get wrapped in structure that reads well but delays the actionable point, because the generation reward is 'well-formed text' not 'text that works in the user's environment'.

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
> The agent defaults to writing for a generic competent reader rather than modeling the actual audience: stakeholder docs get internal banter, GitHub posts lack attribution markers, PRs use agent-internal jargon: because the generation target is 'good text' rather than 'text this specific reader will act on correctly'.

**Rule:** Before finalizing any output that leaves this session (GitHub, docs, PRs, shared files), name the human who will read it first and check whether every sentence would make sense to that person without context from this conversation.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Projects_ (21): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (104): d8f1948c, a0f35401, 8c7e6f5c, +101 more

---


## Wake Cycle: 2026-10-05 23:51 UTC

### Insight (conf=0.82)
> The agent systematically substitutes a cheaper verification proxy (static analysis for runtime, DOM tree for visual render, structural claim for file read) and reports the proxy's result as the real thing: a form of verification theater where the shape of checking is performed without the substance.

**Rule:** Before reporting any verification result, always name the specific verification instrument used and confirm it matches the claim's domain: a type check cannot verify runtime behavior, a DOM snapshot cannot verify visual appearance, and an unread file cannot ground an architectural claim.

**Evidence:**
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "Shipping code and reporting a visual feature as complete without rendering and viewing the actual target state (not just green tests) produc…"
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, -Users-alcatraz627-Code-Versable-versable-builder, .claude, i-dream, versable-builder, claude-ipc, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (167): 1cd54c1d, 14422091, 06fa3e6a, +164 more

---
### Insight (conf=0.80)
> The agent treats writing the fix as the completion event rather than the user experiencing the fix: all three patterns share a temporal confusion where the agent's internal state ('I wrote the correct code') is reported as the user's observable state ('the bug is fixed'), skipping the causal step where the code actually runs.

**Rule:** Always distinguish between 'code written' and 'behavior verified' in status reports: never use 'fixed', 'works', or 'resolved' until the changed path has been exercised in the running application this turn.

**Evidence:**
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "When the agent announces a UI or runtime fix and the user tests it on the actual running app, discovering it still fails, the agent had clai…"
- _Pattern_: "The agent advertises localhost URLs in a reply without first navigating to the URL and exercising its primary action in the same turn, leadi…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-review-dln7gl31-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-5-describe--dultdiz-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-review-2rox5m7e-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-32-describe-m9dykplx-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-23-describe-dc6db8ji-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-seat-versable-git-pr-claude-testbed-1-review-rsvszsah-ws, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-vkv-yxq0, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-d3h6zvin, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T-sb-e2e-8vui0e2n, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, switchboard-mac, csync, staging-enhancement-product
- _Sessions_ (88): e3cbc32f, 302d5d15, 27238870, +85 more

---
### Insight (conf=0.78)
> The agent treats declaring intent or performing a declaration-shaped action (proposing a goal, listing next steps, running a collect-only check, saying 'ready to merge') as equivalent to the work itself: naming the thing substitutes for doing the thing, a consistent confusion between the map and the territory.

**Rule:** Always verify that the last tool call in a turn performed substantive work (executed code, wrote a file, fetched real state) rather than only declared, proposed, or statically checked: if it only declared, the turn is not done.

**Evidence:**
- _Pattern_: "Printing a /goal paste line and ending the turn without making any further tool call is a rule violation; a proposed goal is not a stop cond…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-Codex-2026-10-04-mac, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, gcp, better-file-browser, sys-monitor
- _Sessions_ (126): 748d85a7, f1610d3b, f151a4e7, +123 more

---
### Insight (conf=0.72)
> Single-turn corrections patch the output token but not the generative distribution: the agent acknowledges a rule violation, regenerates from the same latent state, and reproduces the violation because acknowledgment is not internalization within a decoding session.

**Rule:** After any same-session rule-violation correction, always re-read the violated rule text before generating the next reply, and insert a mechanical self-check (grep/scan the draft output for the specific violation pattern) before finalizing.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Claiming success after only running a static check (collect, lint, type-check, syntax check) without executing the actual changed code path …"
- _Projects_ (28): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, sys-monitor
- _Sessions_ (160): 0c39a659, fb13ca88, f9f4c3b2, +157 more

---
### Insight (conf=0.70)
> The agent optimizes for information-theoretic completeness (the data is technically present somewhere in the reply) rather than actionability at the reader's cursor: paths hidden in links, basenames without context, content completed silently, and terminal-breaking formatting all share the defect that the user cannot act on the output without additional extraction work.

**Rule:** Always evaluate whether the user can act on every key output (path, content, status) directly from where it appears in the reply without scrolling, clicking, or asking a follow-up: if not, surface it as a standalone visible string.

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "When citing a document or file in any response, always include the full path: a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "After completing a content-creation task (writing a PR description, updating documentation, drafting a message), the agent must echo the cre…"
- _Projects_ (24): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-automation
- _Sessions_ (117): be8b40b2, 7e2f0302, a913e430, +114 more

---
### Insight (conf=0.68)
> The agent's trained output distribution (formal hedging, structured briefings, em-dash-heavy prose, abstract vocabulary) is a persistent attractor that reasserts itself after corrections: the user's preferred register (plain, direct, concrete) requires active suppression of defaults rather than passive compliance, explaining why corrections fade within turns.

**Rule:** Avoid treating prose style corrections as one-time patches: when a style rule fires, apply it as a per-sentence filter on the entire remaining reply, not just the flagged instance.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "When the user asks a direct scoping or status question, answering with a structured multi-section briefing before the direct answer reads as…"
- _Projects_ (15): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (77): 0c39a659, fb13ca88, f9f4c3b2, +74 more

---
### Insight (conf=0.65)
> The agent's default tendency toward abstraction and generalization actively destroys the specific signal the user needs: concrete names become generic terms in RCAs, plain changes become jargon in PRs, distinct plans get merged into synthesis, and a 'banner' gets compressed into an 'icon': all because the model's prior favors the general over the particular.

**Rule:** When the output contains a concrete noun from the source material (a name, a measurement, a format, a size), always preserve it verbatim rather than abstracting it: abstraction requires explicit instruction.

**Evidence:**
- _Pattern_: "When a sub-agent or writing pass produces an RCA, it must preserve concrete specifics (customer names, job names, named individuals, measure…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging…"
- _Pattern_: "When a user requests a 'banner' for a repository README alongside an SVG, the agent should interpret 'banner' as a large-format hero image r…"
- _Projects_ (27): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Versable-winhere-pim, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product-backend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, slack-automation, winhere-pim, switchboard-mac, speedway, gcp, csync, sor, versable-builder, frontend
- _Sessions_ (104): af36ab3c, 59214989, 55ccaf51, +101 more

---


## Wake Cycle: 2026-10-19 08:51 UTC

### Insight (conf=0.92)
> The agent has a systematic verification-avoidance bias where it substitutes cheaper proxies (syntax checks, code reading, a11y snapshots) for actual runtime exercise, creating a class of false-ready declarations across UI, backend, and endpoint domains.

**Rule:** Always execute the actual code path in the real runtime environment before declaring any fix, feature, or endpoint ready: never substitute static analysis, code reading, or DOM inspection for a live run.

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

**Rule:** Always re-check the current reply against all style violations flagged earlier in the session before emitting: treat every prior style correction as a filter applied to every subsequent turn, not just the next one.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (31): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, enhancement-product
- _Sessions_ (158): 0c39a659, fb13ca88, f9f4c3b2, +155 more

---
### Insight (conf=0.85)
> The agent treats narrating intent as partial credit toward completion: announcing next steps, listing pending work, or pasting a goal line satisfies an internal 'progress signal' that prematurely ends the turn, when the actual stop condition requires the work itself to be finished.

**Rule:** Never end a turn with named pending work unless every item is explicitly labeled as blocked with the specific missing input: announcing intent to act is not acting.

**Evidence:**
- _Pattern_: "Printing a /goal paste line and ending the turn without making any further tool call is a rule violation; a proposed goal is not a stop cond…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-Codex-2026-10-04-mac, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, enhancement-product, i-dream, .claude
- _Sessions_ (43): 748d85a7, f1610d3b, f151a4e7, +40 more

---
### Insight (conf=0.82)
> Path-rendering rules form a four-constraint system (full path, not just basename; plain-text not hidden in links; no trailing period; visible absolute string) that the agent treats as independent formatting preferences rather than a single coherent policy: 'every file reference must be an unambiguous, terminal-actionable, fully-qualified plain-text path'.

**Rule:** Always emit file paths as standalone full absolute plain-text strings followed by a space or comma: never as basenames, inside Markdown links, or immediately before a period.

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "When citing a document or file in any response, always include the full path: a basename alone forces the user to hunt for the file and is …"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-local-models
- _Sessions_ (70): be8b40b2, 7e2f0302, a913e430, +67 more

---
### Insight (conf=0.78)
> The agent confabulates structural facts (where code lives, what tickets exist, what specs say) when it skips source verification, and this same credulity applies symmetrically to both its own assumptions and to external AI-generated documents: the root cause is acting on unverified claims regardless of origin.

**Rule:** Always read the primary source (file, ticket tracker, spec) before making any structural claim about what exists, what works, or what a document says: never rely on memory, inference, or another model's output.

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Pattern_: "Referencing ticket or PR numbers in responses or task entries that do not exist in the project's tracked plan is treated as a fabrication fa…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-sys-monitor
- _Sessions_ (95): d63726f5, d049ade6, bc8f0f24, +92 more

---
### Insight (conf=0.80)
> The agent has a pattern of declaring completion against a checklist by satisfying the majority of conditions rather than all of them: open callouts, unchecked merge state, and unexercised arms of a multi-target condition are all instances of treating near-done as done.

**Rule:** Always enumerate every sub-condition of a stop gate and verify each independently before declaring completion: partial satisfaction of a multi-part condition is never completion.

**Evidence:**
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Projects_ (22): -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude, -Users-alcatraz627--claude, audio-doctor, landing-app, enhancement-product, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, gcp, better-file-browser, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-codex, codex
- _Sessions_ (90): 09d0d2ef, cd785330, 80e5b5e6, +87 more

---
### Insight (conf=0.82)
> Agent-authored documents for external consumption (PRs, plans, summaries) share a common failure mode of substituting verbose, abstract, or adversarial framing for plain concise statements: the agent defaults to 'impressive-sounding' over 'useful' in any artifact that will be read by others.

**Rule:** Always write external-facing documents (PRs, plans, summaries) in plain declarative sentences stating what changed and why: avoid jargon, adversarial framing, and any sentence that sounds impressive but says nothing concrete.

**Evidence:**
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "Replies that exceed ~1500 chars of prose should lead with the single most important point and defer detail to a linked file; long inline sum…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, slack-automation
- _Sessions_ (86): 13f3ab7c, 0ecfd423, cb2053b9, +83 more

---
### Insight (conf=0.80)
> Actions on shared platforms (GitHub posts, PRs) require metadata markers (attribution, title tags, bot identification) that the agent treats as optional garnish rather than hard prerequisites: the common failure is executing the primary action while forgetting the envelope metadata that controls downstream effects.

**Rule:** Always verify all required metadata markers (attribution, title tags, suppression flags) are present before any push or post to a shared platform: the envelope is as mandatory as the payload.

**Evidence:**
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When the agent creates PRs with required title markers (e.g., [noslack], [nobot]) to suppress downstream noise, it must verify those markers…"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude, .claude, slack-automation, i-dream, sor, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, versable-builder
- _Sessions_ (76): 364f3979, 2aa55be1, 1fc65762, +73 more

---
### Insight (conf=0.72)
> The user has a consistent governance philosophy: operational constraints (budgets, thresholds, automated actions) must be observable and auditable rather than silently enforced: the agent should always surface what it consumed, changed, or decided, not just the outcome.

**Rule:** Always log or report the specific values consumed, thresholds checked, and actions taken when enforcing any operational constraint: silent enforcement without an audit trail violates the user's governance expectations.

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend
- _Sessions_ (37): 65da91a2, 0744ad2c, f6eee83a, +34 more

---
### Insight (conf=0.70)
> Both patterns reflect a scoping failure where the agent treats a local trigger as the full problem boundary: a drawer on one page ignoring its global shell, a planning doc scoped to one feature ignoring the project: the root cause is anchoring scope to the immediate request context rather than auditing the actual blast radius.

**Rule:** Always identify the full scope boundary (all pages sharing a component, full project for a planning doc) before implementing: never scope work to only the trigger context without auditing what else is affected.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product
- _Sessions_ (62): ff8aef13, f95e5eb7, efd2a3ab, +59 more

---
### Insight (conf=0.75)
> UI output that is data-correct but visually incoherent (bad hierarchy, contradictory signals) is a recurring class of 'technically right, experientially wrong' failures: the agent optimizes for logical correctness and neglects perceptual coherence as a separate design constraint.

**Rule:** Always evaluate UI output for visual coherence (single clear signal, hierarchy, grouping) as a separate check after verifying data correctness: correct data in a confusing layout is still a bug.

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation
- _Sessions_ (27): 842e701b, f6eee83a, 872653c4, +24 more

---
### Insight (conf=0.76)
> The agent has a merging/editorializing reflex where it adds its own synthesis, judgment, or safety commentary to outputs that should be structurally preserved as-is: comparisons get merged, peer reviews get collapsed, factual answers get appended warnings: all instances of the agent inserting itself where faithful reproduction was requested.

**Rule:** Always match output structure to what was requested: comparisons stay side-by-side, independent outputs stay independent, factual answers stay factual: never merge, synthesize, or editorialize unless explicitly asked.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked: never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (35): dac333f4, c71644cf, b6809eaf, +32 more

---
### Insight (conf=0.55)
> These form a contradiction pair: the agent must respond to IPC messages before turn-end (obligation to engage) but must also permanently drop topics the user has deferred three times (obligation to disengage): when a peer agent's IPC message concerns a user-deferred topic, the two rules conflict.

**Rule:** Always acknowledge IPC messages before turn-end, but when the message concerns a user-deferred topic, respond only with an acknowledgment and a note that the topic is on hold per the user's standing deferral: do not re-raise the substance.

**Evidence:**
- _Pattern_: "An IPC message from a peer agent that requests a reply must be answered before the turn ends; leaving it unacknowledged causes a Stop-hook r…"
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-codex, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, .claude, versable-builder, studio_search_jul_26-fable
- _Sessions_ (55): 00f81085, 78d69d4f, eca32736, +52 more

---
### Insight (conf=0.58)
> These form a contradiction pair: the agent should proactively arm keep-warm mechanisms before the user leaves (pre-emptive resource activation) but must never auto-start local models for convenience (no pre-emptive resource activation): 'warming up for the user's return' and 'never pre-loading without explicit demand' need reconciliation.

**Rule:** Always arm keep-warm mechanisms for remote/cloud sessions when the user steps away, but never pre-load local models as part of that warm-up: keep-warm applies to session continuity, not to local compute resources.

**Evidence:**
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Pattern_: "Never auto-start or pre-load local models on a schedule; local models must only be invoked explicitly on demand by the user, with zero excep…"
- _Projects_ (7): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, slack-automation, .claude
- _Sessions_ (18): 842e701b, 0744ad2c, f6eee83a, +15 more

---
### Insight (conf=0.68)
> The agent over-extends scope in three parallel ways: deploying without current consent, writing artifacts not requested, and leaking private context into deliverables: all reflecting a failure to treat the current explicit request as the boundary of authorized action.

**Rule:** Always limit actions and artifacts to exactly what the user requested in the current turn: no unrequested deployments, no unrequested files, no content from the conversational context leaking into deliverables.

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
> Style-gate violations (em-dashes, bold spans, AI-smell prose) persist across consecutive corrections within a single session because the agent's generation defaults are deeply embedded and a single correction only suppresses the surface token, not the underlying register selection: the pattern requires a pre-generation style filter, not post-correction patching.

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
- _Pattern_: "When citing a document or file in any response, always include the full path: a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks
- _Sessions_ (70): be8b40b2, 7e2f0302, a913e430, +67 more

---
### Insight (conf=0.90)
> The agent conflates announcing intent with performing work: stating a goal, listing next steps, or naming a stop condition are all treated as turn-worthy outputs even when no tool call or verification accompanies them, creating a class of 'narration-as-action' false completions.

**Rule:** Never end a turn on a statement of planned work: always either execute the next step or explicitly state the specific blocker that prevents execution.

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
> The agent has a pattern of rounding up partial completion to full completion: resolving one arm of a multi-arm condition, skipping open callouts, or not checking merge state are all instances of treating 'mostly done' as 'done'.

**Rule:** Always enumerate every sub-condition of a stop gate explicitly and verify each one independently before declaring completion.

**Evidence:**
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Projects_ (22): -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude, -Users-alcatraz627--claude, audio-doctor, landing-app, enhancement-product, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-codex, codex, gcp, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, better-file-browser
- _Sessions_ (90): 09d0d2ef, cd785330, 80e5b5e6, +87 more

---
### Insight (conf=0.75)
> The agent defaults to synthesis and convergence when the user's workflow deliberately requires separation: merging two plans, trusting external AI output, or collapsing independent reviews all violate a user preference for maintaining distinct information streams until explicitly told to combine them.

**Rule:** Always preserve independent outputs as separate artifacts until the user explicitly requests a merge or synthesis step.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (14): dac333f4, 0c64e0da, 1a66d7a8, +11 more

---
### Insight (conf=0.72)
> The user operates under a governance-first philosophy where constraints (budgets, policies, audit trails) must be visible, documented, and human-readable rather than silently enforced in code: the agent should default to documented doctrine over automated enforcement.

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
> The agent scopes both code changes and planning documents to the immediate request context rather than auditing the full surface area affected: whether that is every page using a shared component or the full project scope of a planning deck.

**Rule:** Always audit the full blast radius (all consumers of a shared component, full project scope for planning) before scoping any implementation or document to a single feature.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product
- _Sessions_ (62): ff8aef13, f95e5eb7, efd2a3ab, +59 more

---
### Insight (conf=0.68)
> The agent treats visual output as a carrier of data rather than a communication artifact: producing technically correct but visually incoherent UI, confusing icon vs. banner intent, and ignoring hierarchy all reflect the same blindness to how visual artifacts are actually perceived by humans.

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

**Rule:** Never append content the user did not request: answer exactly the question asked and treat user deferrals as permanent holds.

**Evidence:**
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked: never append unsolicited safety verdicts, risk warnings, o…"
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Pattern_: "Writing a checkpoint or core-dump file when the user asked for a plain summary or plan answer is an unwanted scope expansion that derails th…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, .claude, versable-builder, studio_search_jul_26-fable, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation
- _Sessions_ (56): f1378236, ef0c57bc, e380462f, +53 more

---
### Insight (conf=0.65)
> The agent oscillates between two opposing failures around autonomous action: it fails to proactively prepare when explicitly asked to work autonomously, yet deploys or pre-loads services without permission when not asked: both are boundary calibration failures around the same autonomy axis.

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


## Wake Cycle: 2026-10-20 07:49 UTC

### Insight (conf=0.87)
> The agent has a systematic verification-avoidance bias where it substitutes cheaper proxies (syntax checks, code reading, a11y snapshots) for actual runtime exercise, creating a class of false-ready declarations across UI, backend, and endpoint domains.

**Rule:** Always execute the actual code path in the real runtime environment before declaring any fix, feature, or endpoint ready: never substitute static analysis, code reading, or DOM inspection for a live run.

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

**Rule:** Always re-check the current reply against all style violations flagged earlier in the session before emitting: treat every prior style correction as a filter applied to every subsequent turn, not just the next one.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (31): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, enhancement-product
- _Sessions_ (158): 0c39a659, fb13ca88, f9f4c3b2, +155 more

---
### Insight (conf=0.80)
> The agent treats narrating intent as partial credit toward completion: announcing next steps, listing pending work, or pasting a goal line satisfies an internal 'progress signal' that prematurely ends the turn, when the actual stop condition requires the work itself to be finished.

**Rule:** Never end a turn with named pending work unless every item is explicitly labeled as blocked with the specific missing input: announcing intent to act is not acting.

**Evidence:**
- _Pattern_: "Printing a /goal paste line and ending the turn without making any further tool call is a rule violation; a proposed goal is not a stop cond…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-Codex-2026-10-04-mac, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, enhancement-product, i-dream, .claude
- _Sessions_ (43): 748d85a7, f1610d3b, f151a4e7, +40 more

---
### Insight (conf=0.77)
> Path-rendering rules form a four-constraint system (full path, not just basename; plain-text not hidden in links; no trailing period; visible absolute string) that the agent treats as independent formatting preferences rather than a single coherent policy: 'every file reference must be an unambiguous, terminal-actionable, fully-qualified plain-text path'.

**Rule:** Always emit file paths as standalone full absolute plain-text strings followed by a space or comma: never as basenames, inside Markdown links, or immediately before a period.

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "When citing a document or file in any response, always include the full path: a basename alone forces the user to hunt for the file and is …"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-local-models
- _Sessions_ (70): be8b40b2, 7e2f0302, a913e430, +67 more

---
### Insight (conf=0.73)
> The agent confabulates structural facts (where code lives, what tickets exist, what specs say) when it skips source verification, and this same credulity applies symmetrically to both its own assumptions and to external AI-generated documents: the root cause is acting on unverified claims regardless of origin.

**Rule:** Always read the primary source (file, ticket tracker, spec) before making any structural claim about what exists, what works, or what a document says: never rely on memory, inference, or another model's output.

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Pattern_: "Referencing ticket or PR numbers in responses or task entries that do not exist in the project's tracked plan is treated as a fabrication fa…"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-sys-monitor
- _Sessions_ (95): d63726f5, d049ade6, bc8f0f24, +92 more

---
### Insight (conf=0.75)
> The agent has a pattern of declaring completion against a checklist by satisfying the majority of conditions rather than all of them: open callouts, unchecked merge state, and unexercised arms of a multi-target condition are all instances of treating near-done as done.

**Rule:** Always enumerate every sub-condition of a stop gate and verify each independently before declaring completion: partial satisfaction of a multi-part condition is never completion.

**Evidence:**
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Projects_ (22): -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude, -Users-alcatraz627--claude, audio-doctor, landing-app, enhancement-product, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, gcp, better-file-browser, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-codex, codex
- _Sessions_ (90): 09d0d2ef, cd785330, 80e5b5e6, +87 more

---
### Insight (conf=0.77)
> Agent-authored documents for external consumption (PRs, plans, summaries) share a common failure mode of substituting verbose, abstract, or adversarial framing for plain concise statements: the agent defaults to 'impressive-sounding' over 'useful' in any artifact that will be read by others.

**Rule:** Always write external-facing documents (PRs, plans, summaries) in plain declarative sentences stating what changed and why: avoid jargon, adversarial framing, and any sentence that sounds impressive but says nothing concrete.

**Evidence:**
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "Replies that exceed ~1500 chars of prose should lead with the single most important point and defer detail to a linked file; long inline sum…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, slack-automation
- _Sessions_ (86): 13f3ab7c, 0ecfd423, cb2053b9, +83 more

---
### Insight (conf=0.75)
> Actions on shared platforms (GitHub posts, PRs) require metadata markers (attribution, title tags, bot identification) that the agent treats as optional garnish rather than hard prerequisites: the common failure is executing the primary action while forgetting the envelope metadata that controls downstream effects.

**Rule:** Always verify all required metadata markers (attribution, title tags, suppression flags) are present before any push or post to a shared platform: the envelope is as mandatory as the payload.

**Evidence:**
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When the agent creates PRs with required title markers (e.g., [noslack], [nobot]) to suppress downstream noise, it must verify those markers…"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude, .claude, slack-automation, i-dream, sor, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, versable-builder
- _Sessions_ (76): 364f3979, 2aa55be1, 1fc65762, +73 more

---
### Insight (conf=0.67)
> The user has a consistent governance philosophy: operational constraints (budgets, thresholds, automated actions) must be observable and auditable rather than silently enforced: the agent should always surface what it consumed, changed, or decided, not just the outcome.

**Rule:** Always log or report the specific values consumed, thresholds checked, and actions taken when enforcing any operational constraint: silent enforcement without an audit trail violates the user's governance expectations.

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend
- _Sessions_ (37): 65da91a2, 0744ad2c, f6eee83a, +34 more

---
### Insight (conf=0.65)
> Both patterns reflect a scoping failure where the agent treats a local trigger as the full problem boundary: a drawer on one page ignoring its global shell, a planning doc scoped to one feature ignoring the project: the root cause is anchoring scope to the immediate request context rather than auditing the actual blast radius.

**Rule:** Always identify the full scope boundary (all pages sharing a component, full project for a planning doc) before implementing: never scope work to only the trigger context without auditing what else is affected.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product
- _Sessions_ (62): ff8aef13, f95e5eb7, efd2a3ab, +59 more

---
### Insight (conf=0.70)
> UI output that is data-correct but visually incoherent (bad hierarchy, contradictory signals) is a recurring class of 'technically right, experientially wrong' failures: the agent optimizes for logical correctness and neglects perceptual coherence as a separate design constraint.

**Rule:** Always evaluate UI output for visual coherence (single clear signal, hierarchy, grouping) as a separate check after verifying data correctness: correct data in a confusing layout is still a bug.

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation
- _Sessions_ (27): 842e701b, f6eee83a, 872653c4, +24 more

---
### Insight (conf=0.71)
> The agent has a merging/editorializing reflex where it adds its own synthesis, judgment, or safety commentary to outputs that should be structurally preserved as-is: comparisons get merged, peer reviews get collapsed, factual answers get appended warnings: all instances of the agent inserting itself where faithful reproduction was requested.

**Rule:** Always match output structure to what was requested: comparisons stay side-by-side, independent outputs stay independent, factual answers stay factual: never merge, synthesize, or editorialize unless explicitly asked.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked: never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (35): dac333f4, c71644cf, b6809eaf, +32 more

---
### Insight (conf=0.50)
> These form a contradiction pair: the agent must respond to IPC messages before turn-end (obligation to engage) but must also permanently drop topics the user has deferred three times (obligation to disengage): when a peer agent's IPC message concerns a user-deferred topic, the two rules conflict.

**Rule:** Always acknowledge IPC messages before turn-end, but when the message concerns a user-deferred topic, respond only with an acknowledgment and a note that the topic is on hold per the user's standing deferral: do not re-raise the substance.

**Evidence:**
- _Pattern_: "An IPC message from a peer agent that requests a reply must be answered before the turn ends; leaving it unacknowledged causes a Stop-hook r…"
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-codex, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude, -Users-alcatraz627, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, .claude, versable-builder, studio_search_jul_26-fable
- _Sessions_ (55): 00f81085, 78d69d4f, eca32736, +52 more

---
### Insight (conf=0.53)
> These form a contradiction pair: the agent should proactively arm keep-warm mechanisms before the user leaves (pre-emptive resource activation) but must never auto-start local models for convenience (no pre-emptive resource activation): 'warming up for the user's return' and 'never pre-loading without explicit demand' need reconciliation.

**Rule:** Always arm keep-warm mechanisms for remote/cloud sessions when the user steps away, but never pre-load local models as part of that warm-up: keep-warm applies to session continuity, not to local compute resources.

**Evidence:**
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Pattern_: "Never auto-start or pre-load local models on a schedule; local models must only be invoked explicitly on demand by the user, with zero excep…"
- _Projects_ (7): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, slack-automation, .claude
- _Sessions_ (18): 842e701b, 0744ad2c, f6eee83a, +15 more

---
### Insight (conf=0.63)
> The agent over-extends scope in three parallel ways: deploying without current consent, writing artifacts not requested, and leaking private context into deliverables: all reflecting a failure to treat the current explicit request as the boundary of authorized action.

**Rule:** Always limit actions and artifacts to exactly what the user requested in the current turn: no unrequested deployments, no unrequested files, no content from the conversational context leaking into deliverables.

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
> Style-gate violations (em-dashes, bold spans, AI-smell prose) persist across consecutive corrections within a single session because the agent's generation defaults are deeply embedded and a single correction only suppresses the surface token, not the underlying register selection: the pattern requires a pre-generation style filter, not post-correction patching.

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
- _Pattern_: "When citing a document or file in any response, always include the full path: a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks
- _Sessions_ (70): be8b40b2, 7e2f0302, a913e430, +67 more

---
### Insight (conf=0.85)
> The agent conflates announcing intent with performing work: stating a goal, listing next steps, or naming a stop condition are all treated as turn-worthy outputs even when no tool call or verification accompanies them, creating a class of 'narration-as-action' false completions.

**Rule:** Never end a turn on a statement of planned work: always either execute the next step or explicitly state the specific blocker that prevents execution.

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
> The agent has a pattern of rounding up partial completion to full completion: resolving one arm of a multi-arm condition, skipping open callouts, or not checking merge state are all instances of treating 'mostly done' as 'done'.

**Rule:** Always enumerate every sub-condition of a stop gate explicitly and verify each one independently before declaring completion.

**Evidence:**
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Projects_ (22): -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude, -Users-alcatraz627--claude, audio-doctor, landing-app, enhancement-product, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-codex, codex, gcp, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, better-file-browser
- _Sessions_ (90): 09d0d2ef, cd785330, 80e5b5e6, +87 more

---
### Insight (conf=0.70)
> The agent defaults to synthesis and convergence when the user's workflow deliberately requires separation: merging two plans, trusting external AI output, or collapsing independent reviews all violate a user preference for maintaining distinct information streams until explicitly told to combine them.

**Rule:** Always preserve independent outputs as separate artifacts until the user explicitly requests a merge or synthesis step.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (14): dac333f4, 0c64e0da, 1a66d7a8, +11 more

---
### Insight (conf=0.67)
> The user operates under a governance-first philosophy where constraints (budgets, policies, audit trails) must be visible, documented, and human-readable rather than silently enforced in code: the agent should default to documented doctrine over automated enforcement.

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
> The agent scopes both code changes and planning documents to the immediate request context rather than auditing the full surface area affected: whether that is every page using a shared component or the full project scope of a planning deck.

**Rule:** Always audit the full blast radius (all consumers of a shared component, full project scope for planning) before scoping any implementation or document to a single feature.

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product
- _Sessions_ (62): ff8aef13, f95e5eb7, efd2a3ab, +59 more

---
### Insight (conf=0.63)
> The agent treats visual output as a carrier of data rather than a communication artifact: producing technically correct but visually incoherent UI, confusing icon vs. banner intent, and ignoring hierarchy all reflect the same blindness to how visual artifacts are actually perceived by humans.

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

**Rule:** Never append content the user did not request: answer exactly the question asked and treat user deferrals as permanent holds.

**Evidence:**
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked: never append unsolicited safety verdicts, risk warnings, o…"
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Pattern_: "Writing a checkpoint or core-dump file when the user asked for a plain summary or plan answer is an unwanted scope expansion that derails th…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, .claude, versable-builder, studio_search_jul_26-fable, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation
- _Sessions_ (56): f1378236, ef0c57bc, e380462f, +53 more

---
### Insight (conf=0.60)
> The agent oscillates between two opposing failures around autonomous action: it fails to proactively prepare when explicitly asked to work autonomously, yet deploys or pre-loads services without permission when not asked: both are boundary calibration failures around the same autonomy axis.

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
> The agent systematically conflates 'edited' with 'verified' across every domain (source files, URLs, UI fixes) revealing a deep structural bias toward treating authorship as proof of correctness.

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
> The agent uses stated intent as a substitute for completed work: proposals, 'doing now' lists, and open callouts all function as premature completion signals, revealing a pattern where narrating the plan satisfies the agent's internal 'done' check.

**Rule:** Never end a turn with uncommitted intent; always either execute the stated action or explicitly label it as blocked with the specific missing input

**Evidence:**
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Projects_ (18): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, slack-automation, .claude, enhancement-product, Affinity, -Users-alcatraz627-Documents-Codex-2026-10-04-mac, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude, audio-doctor, landing-app
- _Sessions_ (36): 20db15be, 97a8cbfb, 83a48450, +33 more

---
### Insight (conf=0.90)
> File paths are a recurring boundary-crossing failure point: the agent treats them as inline prose tokens rather than as actionable UI elements that must survive terminal rendering, link detection, and user navigation: four separate rules all stem from the same root neglect of paths as first-class output artifacts.

**Rule:** Always emit file paths as standalone plain-text absolute strings followed by a space or comma, never inside Markdown links, never with a trailing period, and never as basenames

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "When citing a document or file in any response, always include the full path: a basename alone forces the user to hunt for the file and is …"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks
- _Sessions_ (70): be8b40b2, 7e2f0302, a913e430, +67 more

---
### Insight (conf=0.82)
> The agent fabricates ground-truth claims from indirect proxies: structural claims from memory instead of source files, visual claims from DOM snapshots instead of screenshots, ticket numbers from expectation instead of the backlog: all sharing the pattern of substituting a cheaper signal for the authoritative one.

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
> The agent's default prose register: verbose, jargon-heavy, adversarial framing, decorative contrast structures: is a single underlying style failure that manifests differently depending on output type (PRs, docs, chat), not four independent problems.

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
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging…"
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
> The user treats operational governance as documentation-first rather than automation-first: budgets, policies, and healing operations must produce readable audit artifacts, not just function correctly: the agent's instinct to automate silently conflicts with this preference.

**Rule:** Always produce a human-readable log or doc artifact for any automated governance action, including budget tracking, policy enforcement, and state-healing operations

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor
- _Sessions_ (37): 65da91a2, 0744ad2c, f6eee83a, +34 more

---
### Insight (conf=0.75)
> The agent over-delivers by default: long prose when brevity was asked for, checkpoint files when a summary was asked for, safety verdicts when a fact was asked for: all instances of the same scope-inflation tendency where the agent substitutes what it thinks is helpful for what was actually requested.

**Rule:** Always match the output scope exactly to what was requested; never append unrequested artifacts, warnings, or expansions even if they seem helpful

**Evidence:**
- _Pattern_: "Replies that exceed ~1500 chars of prose should lead with the single most important point and defer detail to a linked file; long inline sum…"
- _Pattern_: "Writing a checkpoint or core-dump file when the user asked for a plain summary or plan answer is an unwanted scope expansion that derails th…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked: never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (8): -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude
- _Sessions_ (53): d52a521f, 90da8e73, 90d2e6ca, +50 more

---
### Insight (conf=0.77)
> UI work fails at the gestalt level: individual components are technically correct but the agent does not reason about visual coherence across the full surface: whether it is color contrast within a panel, mixed signals in a progress bar, or drawer variants across pages, the common failure is local correctness without global audit.

**Rule:** Always audit the full visual surface and all pages that share a component before declaring any UI work complete

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, claude-instances, speedway
- _Sessions_ (70): 842e701b, f6eee83a, 872653c4, +67 more

---


## Wake Cycle: 2026-10-20 23:01 UTC

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
> The agent treats stating intent as partial credit toward completion, creating a pattern where naming future work substitutes for doing it: whether that's a proposal without a tool call, a 'Next' section without execution, or acknowledging a keep-warm need without arming it.

**Rule:** Never end a turn with named pending work unless each item is explicitly labeled as blocked with the specific missing input; if not blocked, execute it before the turn ends.

**Evidence:**
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Projects_ (13): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, slack-automation, .claude, enhancement-product, Affinity, -Users-alcatraz627-Documents-Codex-2026-10-04-mac
- _Sessions_ (34): 20db15be, 97a8cbfb, 83a48450, +31 more

---
### Insight (conf=0.82)
> Style corrections from hooks fail to durably update the agent's generation defaults within a session, suggesting the correction is treated as a one-shot patch rather than a persistent constraint: the same class of error (em-dashes, AI-smell prose, path-before-period) recurs on the very next turn.

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
- _Pattern_: "When citing a document or file in any response, always include the full path: a basename alone forces the user to hunt for the file and is …"
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
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging…"
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
> The agent over-produces output by default (long prose, unsolicited artifacts, appended warnings) and the user has to repeatedly constrain it; the underlying failure is that the agent treats 'more is safer' when the user's actual norm is 'only what was asked'.

**Rule:** Always match output scope exactly to what was requested; never append unsolicited artifacts, warnings, or expansions unless they are safety-critical.

**Evidence:**
- _Pattern_: "Prose replies must stay under ~2600 characters; when detail is needed, write it to a file and reference the path rather than expanding inlin…"
- _Pattern_: "Writing a checkpoint or core-dump file when the user asked for a plain summary or plan answer is an unwanted scope expansion that derails th…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked: never append unsolicited safety verdicts, risk warnings, o…"
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


## Wake Cycle: 2026-10-22 05:00 UTC

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
> The agent treats stating intent as partial credit toward completion, creating a pattern where naming future work substitutes for doing it: whether that's a proposal without a tool call, a 'Next' section without execution, or acknowledging a keep-warm need without arming it.

**Rule:** Never end a turn with named pending work unless each item is explicitly labeled as blocked with the specific missing input; if not blocked, execute it before the turn ends.

**Evidence:**
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Projects_ (13): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, slack-automation, .claude, enhancement-product, Affinity, -Users-alcatraz627-Documents-Codex-2026-10-04-mac
- _Sessions_ (34): 20db15be, 97a8cbfb, 83a48450, +31 more

---
### Insight (conf=0.77)
> Style corrections from hooks fail to durably update the agent's generation defaults within a session, suggesting the correction is treated as a one-shot patch rather than a persistent constraint: the same class of error (em-dashes, AI-smell prose, path-before-period) recurs on the very next turn.

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
- _Pattern_: "When citing a document or file in any response, always include the full path: a basename alone forces the user to hunt for the file and is …"
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
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging…"
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
> The agent over-produces output by default (long prose, unsolicited artifacts, appended warnings) and the user has to repeatedly constrain it; the underlying failure is that the agent treats 'more is safer' when the user's actual norm is 'only what was asked'.

**Rule:** Always match output scope exactly to what was requested; never append unsolicited artifacts, warnings, or expansions unless they are safety-critical.

**Evidence:**
- _Pattern_: "Prose replies must stay under ~2600 characters; when detail is needed, write it to a file and reference the path rather than expanding inlin…"
- _Pattern_: "Writing a checkpoint or core-dump file when the user asked for a plain summary or plan answer is an unwanted scope expansion that derails th…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked: never append unsolicited safety verdicts, risk warnings, o…"
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
> The agent systematically confuses declaring intent with completing action: stating a goal, editing a file, or citing a URL each feel like 'done' but none constitute verified execution, revealing a pervasive say-do gap.

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
> Style-gate violations persist across consecutive corrections because the offending patterns are baked into the model's default register at the token-prediction level, not at a 'rule-checking' layer: single corrections don't override sampling priors, requiring an active suppression pass before emission rather than post-hoc filtering.

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
> The agent substitutes cheaper proxy evidence (syntax checks, a11y snapshots, structural assumptions) for actual ground-truth verification, and each proxy feels sufficient in the moment: a shared epistemic shortcut where 'close enough to knowing' is treated as knowing.

**Rule:** Always distinguish between proxy evidence and ground-truth evidence when verifying a claim, and never declare verification complete using only proxy evidence.

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (67): d839657c, c5afbb2f, 067e4644, +64 more

---
### Insight (conf=0.80)
> The agent treats turn boundaries as implicit pause points, listing remaining work as 'next steps' rather than continuing execution: turn-end is mistaken for a natural stopping point even when the task is incomplete and no blocker exists.

**Rule:** Never end a turn with named pending work unless each item is explicitly labeled as blocked with the specific missing input; if no blocker exists, execute the work in the same turn.

**Evidence:**
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (14): -Users-alcatraz627-Documents-Codex-2026-10-04-mac, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627--claude, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, .claude, enhancement-product, Affinity, i-dream
- _Sessions_ (42): 58f5414c, b74c0be6, 38d3e596, +39 more

---
### Insight (conf=0.82)
> Four separate rules address file-path rendering in output, revealing that the agent's default path-citation behavior is broken in multiple independent ways (truncation, link-hiding, and punctuation collision) all stemming from treating paths as inline prose elements rather than as structured references with their own formatting constraints.

**Rule:** Always emit file paths as standalone plain-text absolute strings followed by a space or comma, never inside Markdown link syntax, never truncated to basename, and never immediately before a period.

**Evidence:**
- _Pattern_: "When citing a document or file in any response, always include the full path: a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp
- _Sessions_ (70): 75119a5e, 43173e49, 0c333593, +67 more

---
### Insight (conf=0.75)
> The agent's written artifacts (PRs, plans, docs) default to a verbose, evaluative, jargon-laden register that the user consistently rejects: the same 'default LLM voice' problem that appears in prose replies also infects every document type the agent produces.

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
> The agent repeatedly declares shared-state operations (merges, PRs, multi-environment deploys) complete without running the specific gate check that would confirm completeness: a pattern of skipping the final verification step precisely when the cost of being wrong is highest (irreversible external effects).

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
> The agent defaults to synthesis and consolidation when the user's workflow explicitly requires keeping inputs separate and adversarial: the agent's helpfulness instinct to 'resolve' conflicts directly opposes deliberate divergence-preserving workflows like peer review and plan comparison.

**Rule:** Always preserve the independence of separate inputs (plans, reviews, specs) unless the user explicitly requests a merge; treat 'compare' as contrast, not synthesis.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (14): dac333f4, 0c64e0da, 1a66d7a8, +11 more

---
### Insight (conf=0.65)
> Resource governance (token budgets, sub-agent scope, disk thresholds) shares a common failure mode: the agent acknowledges the constraint verbally but does not instrument ongoing enforcement: policy is recorded but not operationalized into per-action checks.

**Rule:** Always implement active per-turn tracking for any resource constraint the user sets, rather than acknowledging it once and relying on memory.

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When spawning multiple sub-agents, the agent should scope each agent tightly to avoid burning excessive API usage, and inform the user of th…"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, landing-app, Affinity, better-file-browser, i-dream, .claude, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend
- _Sessions_ (49): 65da91a2, 0744ad2c, f6eee83a, +46 more

---
### Insight (conf=0.70)
> The agent fails to model audience boundaries: conversational tone leaks into stakeholder documents, and agent identity is not disclosed on shared platforms: because it treats all output as having the same audience (the current user in the current chat).

**Rule:** Always identify the final audience of any output before drafting, and apply audience-specific constraints (attribution markers, tone, confidentiality) as hard requirements, not style suggestions.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban
- _Sessions_ (77): d8f1948c, a0f35401, 8c7e6f5c, +74 more

---
### Insight (conf=0.62)
> UI work fails at the coherence level rather than the correctness level: individual components are technically right but the holistic signal (visual hierarchy, progress state, shared shell consistency) is contradictory, suggesting the agent builds UI bottom-up without a top-down coherence check.

**Rule:** Always audit the holistic visual and structural coherence of a UI change across all affected pages before declaring it complete, not just the correctness of the individual component.

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, claude-instances, speedway
- _Sessions_ (70): 842e701b, f6eee83a, 872653c4, +67 more

---
### Insight (conf=0.60)
> Time-sensitive background obligations (keep-warm, IPC gates, in-flight workflows) share a failure mode where the agent does not treat them as interrupts with deadlines: they are noted but not prioritized, causing timeouts and cold-cache penalties.

**Rule:** Always treat time-sensitive background obligations as highest-priority interrupts that must be resolved in the current turn before any other work.

**Evidence:**
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Pattern_: "IPC push-gate approval messages must be answered in the same turn they arrive; leaving them unanswered triggers a stop-hook reminder on the …"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, slack-automation, .claude, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-Affinity, landing-app, better-file-browser, Affinity, i-dream
- _Sessions_ (46): 842e701b, 0744ad2c, f6eee83a, +43 more

---


## Wake Cycle: 2026-10-22 23:01 UTC

### Insight (conf=0.85)
> The agent treats declaration as completion across all domains: stating intent substitutes for action, claiming done substitutes for verification: revealing a systematic gap between symbolic and actual task execution.

**Rule:** Always execute and observe the result of any claim before ending a turn; a statement about state is not evidence of state.

**Evidence:**
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "Before advertising a localhost URL to the user, the agent must navigate to it and exercise its primary action in the same turn to confirm it…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Projects_ (18): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, slack-automation, .claude, enhancement-product, Affinity, -Users-alcatraz627-Code-Versable-sor, audio-doctor, sor, landing-app, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder
- _Sessions_ (47): 20db15be, 97a8cbfb, 83a48450, +44 more

---
### Insight (conf=0.78)
> Hook-flagged formatting corrections do not durably update the agent's generation policy within a session; the same surface-level pattern (em-dashes, path-before-period) recurs immediately, suggesting corrections are applied as post-hoc patches rather than modifying the underlying generation distribution.

**Rule:** Always re-read the full list of active formatting constraints before generating any prose output, rather than relying on in-context correction to persist.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Projects_ (25): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp
- _Sessions_ (109): 0c39a659, fb13ca88, f9f4c3b2, +106 more

---
### Insight (conf=0.72)
> The agent systematically confuses proxies for ground truth: a11y snapshots for rendered UI, syntax checks for runtime execution, structural claims for file reads: suggesting a general failure to distinguish abstraction layers from the concrete reality they represent.

**Rule:** Always interact with the actual artifact (run the code, render the page, read the file) rather than a proxy representation when making a truth claim.

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Projects_ (12): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (67): d839657c, c5afbb2f, 067e4644, +64 more

---
### Insight (conf=0.80)
> The agent treats turn boundaries as natural stopping points even when the task's actual stop condition has not been met, creating a class of premature-termination bugs that manifest as 'plan without execution', 'done with open items', and 'finished with background work still running'.

**Rule:** Never end a turn when a named stop condition has outstanding unsatisfied arms; if unable to continue, explicitly state which arm is blocked and why.

**Evidence:**
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (19): -Users-alcatraz627-Documents-Codex-2026-10-04-mac, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627--claude, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, .claude, enhancement-product, Affinity, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude, audio-doctor, landing-app, i-dream
- _Sessions_ (53): 58f5414c, b74c0be6, 38d3e596, +50 more

---
### Insight (conf=0.82)
> The agent's default prose register is a consistent anti-pattern across all written artifacts: PR descriptions, planning docs, and chat replies all share the same verbose, jargon-heavy, decoratively-framed style that the user rejects, indicating the problem is a single generative default rather than context-specific failures.

**Rule:** Always draft written output in plain declarative sentences stating what changed or what will happen, then remove any word that adds framing but not information, before presenting to the user.

**Evidence:**
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, slack-automation
- _Sessions_ (89): 842e701b, f6eee83a, 872653c4, +86 more

---
### Insight (conf=0.88)
> The user treats file paths as operational data that must be instantly copy-pasteable at the reading surface; any indirection (basename-only, hidden inside markdown link syntax, or broken by terminal punctuation) defeats this and is treated as a single class of 'path obscured' error.

**Rule:** Always render file paths as standalone absolute plain-text strings followed by a space or comma, never inside markdown links, never as basenames, never immediately before a period.

**Evidence:**
- _Pattern_: "When citing a document or file in any response, always include the full path: a basename alone forces the user to hunt for the file and is …"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Projects_ (4): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-local-models
- _Sessions_ (11): 75119a5e, 43173e49, 0c333593, +8 more

---
### Insight (conf=0.70)
> The agent defaults to completing the narrowest local scope rather than auditing the full extent of a condition: whether that's one environment instead of all named targets, one page instead of all pages sharing a component, or one feature instead of the full project: revealing a systematic under-scoping bias.

**Rule:** Always enumerate the full set of targets, pages, or scopes affected by a task before beginning work, and track completion of each independently.

**Evidence:**
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Projects_ (22): -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-codex, codex, gcp, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, slack-automation, enhancement-product
- _Sessions_ (91): edb91880, d035b12c, 81fd3cad, +88 more

---
### Insight (conf=0.65)
> The user's operational philosophy treats policies, budgets, and automated operations as systems that must be self-documenting and self-auditing: they want graduated doctrine over hard-coded logic, active tracking over passive acknowledgment, and audit trails over silent execution: reflecting a preference for observable, governable systems over opaque automation.

**Rule:** Always log what was done and track cumulative impact against stated limits when executing any repeatable or budget-constrained operation.

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor
- _Sessions_ (37): 65da91a2, 0744ad2c, f6eee83a, +34 more

---
### Insight (conf=0.75)
> Actions taken on shared platforms under the user's identity have irreversible social consequences; missing attribution markers, suppression flags, or format conventions cause real-world damage that cannot be patched after the fact, making pre-push verification of metadata as critical as code correctness.

**Rule:** Always verify all required metadata markers (attribution, suppression tags, title format) are present before any push to a shared platform, treating missing markers as a blocking error.

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When the agent creates PRs with required title markers (e.g., [noslack], [nobot]) to suppress downstream noise, it must verify those markers…"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, .claude, slack-automation, i-dream, sor
- _Sessions_ (76): a178d6c3, c8bc2450, baf2ac20, +73 more

---
### Insight (conf=0.68)
> The user operates a deliberate epistemology where independent perspectives must remain separate until explicitly merged: two-agent reviews stay as two reviews, comparisons stay as contrasts not syntheses, and external AI output is treated as unverified claims: reflecting a commitment to preserving information provenance.

**Rule:** Always preserve distinct sources as separate artifacts and never merge, synthesize, or treat as authoritative unless the user explicitly requests that specific operation.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (14): dac333f4, 0c64e0da, 1a66d7a8, +11 more

---
### Insight (conf=0.75)
> The user enforces strict output-shape boundaries: prose must be short, answers must be scoped to the question, and artifacts must match the requested format: and any unsolicited expansion (longer prose, appended warnings, checkpoint files) is treated as a scope violation regardless of the content's quality.

**Rule:** Always match the output format and scope exactly to what was requested; never append, expand, or change artifact type without explicit instruction.

**Evidence:**
- _Pattern_: "Prose replies must stay under ~2600 characters; when detail is needed, write it to a file and reference the path rather than expanding inlin…"
- _Pattern_: "Writing a checkpoint or core-dump file when the user asked for a plain summary or plan answer is an unwanted scope expansion that derails th…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked: never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (17): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, enhancement-product, landing-app, Affinity, better-file-browser, i-dream, .claude, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (55): 7ffa7dde, 3dcf6fc5, 20db15be, +52 more

---


## Wake Cycle: 2026-10-23 23:01 UTC

### Insight (conf=0.85)
> The agent treats declaration as completion across every domain: stating intent substitutes for acting, editing substitutes for running, and proposing substitutes for verifying: revealing a systemic 'say-do gap' where verbal output is confused with task progress.

**Rule:** Always produce a verifiable execution artifact (command output, screenshot, or live-state check) before any claim of completion or readiness.

**Evidence:**
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "Before advertising a localhost URL to the user, the agent must navigate to it and exercise its primary action in the same turn to confirm it…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Projects_ (18): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, slack-automation, .claude, enhancement-product, Affinity, -Users-alcatraz627-Code-Versable-sor, audio-doctor, sor, landing-app, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder
- _Sessions_ (47): 20db15be, 97a8cbfb, 83a48450, +44 more

---
### Insight (conf=0.78)
> Formatting corrections from hooks fail to durably update the agent's generation behavior within a session, suggesting that per-turn feedback is consumed as a local patch rather than updating the generative prior: the same class of surface-level output error (punctuation near paths, em-dashes, bold spans) recurs even after explicit correction.

**Rule:** Always re-check the full reply against every previously-fired formatting hook rule before ending a turn, treating hook history as a cumulative checklist rather than a one-shot correction.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Projects_ (25): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp
- _Sessions_ (109): 0c39a659, fb13ca88, f9f4c3b2, +106 more

---
### Insight (conf=0.82)
> The agent has a systematic 'premature closure' failure where it declares a stopping condition met without exhaustively checking all arms: whether those arms are background tasks, open callouts, merge-state checks, or named next-steps: indicating it optimizes for turn-ending over condition-satisfaction.

**Rule:** Always enumerate every explicit gate or exit criterion from the user's stop condition and confirm each one individually before declaring the condition met.

**Evidence:**
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Projects_ (22): -Users-alcatraz627-Documents-Codex-2026-10-04-mac, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627--claude, slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, enhancement-product, i-dream, .claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude, audio-doctor, landing-app, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, gcp, better-file-browser
- _Sessions_ (82): 58f5414c, b74c0be6, 38d3e596, +79 more

---
### Insight (conf=0.75)
> The agent's default verbosity and decorative framing are a single root cause manifesting across different output surfaces (prose replies, PR descriptions, planning docs): it over-generates content with evaluative or narrative scaffolding regardless of medium, and the user must correct each surface independently.

**Rule:** Always default to the minimal factual statement of what changed or what is proposed, adding narrative or evaluative framing only when the user explicitly requests reasoning or justification.

**Evidence:**
- _Pattern_: "Prose replies must stay under ~2600 characters; when detail is needed, write it to a file and reference the path rather than expanding inlin…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Projects_ (19): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, enhancement-product, landing-app, Affinity, better-file-browser, i-dream, .claude, slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-sor
- _Sessions_ (88): 7ffa7dde, 3dcf6fc5, 20db15be, +85 more

---
### Insight (conf=0.72)
> Em-dashes and bold-span usage are not independent style errors but symptoms of the agent falling back to a 'default LLM register' that is deeply embedded in the generative distribution; the recurrence despite correction indicates these are not surface habits but require an active suppression pass on every turn.

**Rule:** Always perform a post-generation scan of every prose reply for em-dashes, excessive bold, and contrast-scaffolding phrases, and rewrite any matches before emitting the response.

**Evidence:**
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Pattern_: "Em dashes in prose output are explicitly prohibited by the user's format rules; use commas, periods, or parentheses instead. Hyphens in file…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Projects_ (22): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627--claude, enhancement-product, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, .claude, local-models, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, claudebook, walmart-mvp, versable-builder
- _Sessions_ (123): d52a521f, 97a8cbfb, 90d2e6ca, +120 more

---
### Insight (conf=0.80)
> The agent fabricates structural claims about systems it hasn't directly inspected (whether codebase layout, rendered UI state, or ticket numbers) revealing a pattern where confident assertion substitutes for source verification across unrelated domains.

**Rule:** Never assert a fact about current system state (code structure, UI rendering, ticket existence) without a tool call that reads the actual source in the same turn.

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "Referencing ticket or PR numbers in responses or task entries that do not exist in the project's tracked plan is treated as a fabrication fa…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor
- _Sessions_ (112): d63726f5, d049ade6, bc8f0f24, +109 more

---
### Insight (conf=0.70)
> File paths are a recurring failure surface not because of one rule but because four distinct formatting constraints interact (absolute form, no terminal period, visible plain text, not hidden in links) and the agent satisfies some while violating others, suggesting path output needs a single unified rendering pass rather than piecemeal rules.

**Rule:** Always render file paths as standalone absolute plain-text strings followed by a space or comma, never inside Markdown links and never immediately before a period.

**Evidence:**
- _Pattern_: "File paths in output must be written as full absolute or home-relative paths (e.g. ~/Code/project/file.py), not bare filenames or shortened …"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Projects_ (33): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude, versable-foundry, better-file-browser, slack-automation, .claude, local-models, enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, versable-builder, gcp
- _Sessions_ (90): f889a4e4, 5769d89d, 0c294a0d, +87 more

---
### Insight (conf=0.65)
> The agent allows tracking artifacts (task lists, budget counters, open callouts) to drift from actual state during extended work sessions, then treats the stale artifact as authoritative when checking completion: a bookkeeping-lag pattern that causes both premature completion claims and budget overruns.

**Rule:** Always reconcile tracking artifacts (task lists, budget counters, open items) against actual completed work before any completion or budget claim.

**Evidence:**
- _Pattern_: "Task lists must be reconciled continuously with actual work done; letting the list drift while making many edits (no in-progress, stale pend…"
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Projects_ (20): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude, versable-foundry, better-file-browser, slack-automation, .claude, local-models, enhancement-product, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude, audio-doctor, landing-app
- _Sessions_ (41): f889a4e4, 5769d89d, 0c294a0d, +38 more

---
### Insight (conf=0.68)
> The agent defaults to synthesis and trust when the user's workflow requires separation and skepticism: it merges when asked to compare, treats external AI output as spec, and collapses independent reviews into one: indicating a bias toward convergence that conflicts with the user's deliberate adversarial/independent evaluation patterns.

**Rule:** Always preserve the independence of separate inputs (plans, reviews, external docs) unless the user explicitly says to merge, and always validate external AI-generated content against stated intent before acting on it.

**Evidence:**
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging…"
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (14): dac333f4, c71644cf, b6809eaf, +11 more

---
### Insight (conf=0.73)
> The agent underestimates the blast radius of outputs that cross organizational boundaries (shared docs, GitHub posts, PRs with downstream hooks) and fails to apply audience-aware checks before emission, treating all output as private conversation rather than potentially public artifacts.

**Rule:** Always identify whether an output will be visible to people beyond the user before emitting it, and apply all required markers, attribution, and content filters for that audience.

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When the agent creates PRs with required title markers (e.g., [noslack], [nobot]) to suppress downstream noise, it must verify those markers…"
- _Projects_ (24): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, i-dream, sor
- _Sessions_ (95): d8f1948c, a0f35401, 8c7e6f5c, +92 more

---
### Insight (conf=0.62)
> UI work fails at the gestalt level because the agent treats each component or page as an isolated unit rather than reasoning about the holistic visual and architectural coherence: correct parts assemble into incoherent wholes due to missing cross-component audits.

**Rule:** Always audit the full application shell and all pages that share a UI component before modifying or adding that component, verifying visual hierarchy and state coherence across the whole surface.

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, claude-instances, speedway
- _Sessions_ (70): 842e701b, f6eee83a, 872653c4, +67 more

---
### Insight (conf=0.58)
> The agent has opposing failure modes around unsolicited content: it both appends unwanted warnings/judgments to factual answers and re-raises deferred topics, while the user wants tight scope adherence: indicating the agent's helpfulness heuristic overrides explicit scope boundaries.

**Rule:** Always answer exactly what was asked and nothing more; never append evaluative commentary, re-raise deferred topics, or volunteer adjacent concerns unless the user opens the door.

**Evidence:**
- _Pattern_: "The user prefers the agent to proceed with sensible defaults autonomously and only halt for genuinely make-or-break decisions, not routine j…"
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked: never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (21): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, enhancement-product, landing-app, Affinity, better-file-browser, i-dream, .claude, slack-automation, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, versable-builder, studio_search_jul_26-fable, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (71): 7ffa7dde, 3dcf6fc5, 20db15be, +68 more

---


## Wake Cycle: 2026-10-24 23:01 UTC

### Insight (conf=0.85)
> The agent systematically treats stating intent as equivalent to completing the action, whether the gap is between proposal and tool call, edit and execution, URL claim and browser visit, or listed next-steps and actual work: all are instances of a single 'declaration-as-completion' bias.

**Rule:** Always execute the action in the same turn you name it; never end a turn on an intention without either completing it or marking it explicitly blocked with the missing input.

**Evidence:**
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "Before advertising a localhost URL to the user, the agent must navigate to it and exercise its primary action in the same turn to confirm it…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Projects_ (17): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, slack-automation, .claude, enhancement-product, Affinity, -Users-alcatraz627-Code-Versable-sor, audio-doctor, sor, landing-app, -Users-alcatraz627-Documents-Codex-2026-10-04-mac
- _Sessions_ (47): 20db15be, 97a8cbfb, 83a48450, +44 more

---
### Insight (conf=0.72)
> Style-gate violations (em-dashes, AI-smell prose) persist across consecutive corrections within a single session because the agent's generation defaults are stronger than single-shot negative feedback: the correction doesn't update the sampling distribution, it just patches one output while the next draw from the same distribution reproduces the violation.

**Rule:** Always re-read all active style constraints immediately before generating any prose output, treating them as hard pre-generation filters rather than post-generation corrections.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Pattern_: "Em dashes in prose output are explicitly prohibited by the user's format rules; use commas, periods, or parentheses instead. Hyphens in file…"
- _Projects_ (37): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, versable-foundry, better-file-browser, .claude, local-models, enhancement-product
- _Sessions_ (160): 0c39a659, fb13ca88, f9f4c3b2, +157 more

---
### Insight (conf=0.78)
> Four distinct rules about file-path formatting in output all stem from the same root cause: the agent treats paths as semantic content but the user's toolchain treats them as parseable tokens at render boundaries: any rule about path presentation is really a rule about machine-readability of output, not human readability.

**Rule:** Always emit file paths as standalone plain-text tokens with trailing whitespace or punctuation other than period, never inside Markdown link syntax, treating paths as machine-parsed elements rather than prose.

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "When outputting file paths in prose, the agent must follow each path with a word, comma, or other continuation: ending a sentence with a ba…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Projects_ (33): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude, versable-foundry, better-file-browser, .claude, local-models, enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-local-models
- _Sessions_ (90): be8b40b2, 7e2f0302, a913e430, +87 more

---
### Insight (conf=0.82)
> The agent's default verbosity is a cross-domain problem appearing as inline prose bloat, PR description spam, jargon-laden summaries, and decorative framing: all are the same underlying tendency to over-generate text, manifesting in whichever output channel is active.

**Rule:** Always draft output at half the length that feels natural, then cut further; when detail is needed, write it to a file rather than expanding inline.

**Evidence:**
- _Pattern_: "Prose replies must stay under ~2600 characters; when detail is needed, write it to a file and reference the path rather than expanding inlin…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (18): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, enhancement-product, landing-app, Affinity, better-file-browser, i-dream, .claude, slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (87): 7ffa7dde, 3dcf6fc5, 20db15be, +84 more

---
### Insight (conf=0.80)
> The agent consistently substitutes a cheaper verification proxy for the real one (syntax check for runtime, a11y snapshot for screenshot, one environment for two) revealing a systematic tendency to satisfice on verification by picking the easiest available check rather than the one that actually tests the claim.

**Rule:** Always verify a completion claim using the same medium and scope the user would use to check it; never substitute a proxy verification method unless the real one is unavailable and you say so explicitly.

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-codex, codex, gcp
- _Sessions_ (61): d839657c, c5afbb2f, 067e4644, +58 more

---
### Insight (conf=0.77)
> False-ready declarations recur across UI surfaces, PR merges, and background-task completions because the agent's 'done' signal is triggered by finishing its own action list rather than checking external completion gates: it conflates 'I have no more steps' with 'the system is ready'.

**Rule:** Always query the external state (merge status, running processes, open callouts) before declaring any deliverable complete; internal task-list exhaustion is not a completion signal.

**Evidence:**
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (20): -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude, -Users-alcatraz627--claude, audio-doctor, landing-app, enhancement-product, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, gcp, better-file-browser, i-dream, .claude
- _Sessions_ (79): 09d0d2ef, cd785330, 80e5b5e6, +76 more

---
### Insight (conf=0.75)
> The agent fabricates structural claims about codebases, invents ticket numbers, and trusts AI-generated specs without validation: all are instances of generating plausible-sounding references instead of grounding claims in verified sources, a hallucination pattern that crosses from code to project management to document intake.

**Rule:** Always read the source (file, tracker, spec) before referencing it in output; never cite an identifier, location, or claim about external state from memory alone.

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "Referencing ticket or PR numbers in responses or task entries that do not exist in the project's tracked plan is treated as a fabrication fa…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (95): d63726f5, d049ade6, bc8f0f24, +92 more

---
### Insight (conf=0.65)
> The agent has a merging bias: when presented with two separate artifacts it defaults to synthesizing them into one, violating both the peer-review workflow (which requires independent outputs) and comparison requests (which require side-by-side contrast): the underlying drive is toward convergence when the user explicitly wants divergence preserved.

**Rule:** Always preserve separate artifacts as separate unless the user explicitly says 'merge' or 'combine'; comparison and peer-review workflows require maintained independence.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (7): dac333f4, 0c64e0da, 1a66d7a8, +4 more

---
### Insight (conf=0.68)
> The agent treats bookkeeping obligations (budget tracking, task-list reconciliation, IPC message responses) as secondary to primary work, letting them drift until an enforcement hook fires: all three are 'continuous maintenance' duties that degrade when treated as interruptible background concerns rather than same-priority obligations.

**Rule:** Always reconcile bookkeeping state (budgets, task lists, pending messages) at the start and end of every turn, not only when an enforcement hook fires.

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "Task lists must be reconciled continuously with actual work done; letting the list drift while making many edits (no in-progress, stale pend…"
- _Pattern_: "IPC/switchboard-panel messages must be answered in the same turn they arrive or before the turn ends; leaving them unanswered triggers a rep…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627--claude, versable-foundry, better-file-browser, .claude, local-models
- _Sessions_ (30): 65da91a2, 0744ad2c, f6eee83a, +27 more

---
### Insight (conf=0.70)
> The agent leaks its internal framing into externally shared documents: adversarial tone in planning docs and private banter in stakeholder-facing docs are both failures to separate the conversational register from the deliverable register, risking real reputational harm when documents leave the session.

**Rule:** Always write documents destined for external readers in a neutral, standalone voice, treating them as if the surrounding conversation context will never be seen.

**Evidence:**
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, slack-automation, enhancement-product, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, local-models, .claude
- _Sessions_ (42): de7a2e20, c8e57a8d, 90da8e73, +39 more

---
### Insight (conf=0.60)
> UI output that is informationally correct but visually incoherent (poor hierarchy, contradictory signals) reveals that the agent optimizes for data correctness and treats visual communication as a cosmetic afterthought: the user treats them as equally important.

**Rule:** Always evaluate UI output for whether it communicates a single coherent signal visually, not just whether the underlying data is correct.

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation
- _Sessions_ (27): 842e701b, f6eee83a, 872653c4, +24 more

---
### Insight (conf=0.58)
> The user's operational philosophy favors documented policy over hard-coded automation but simultaneously demands audit trails from automated operations: these two preferences reconcile into a principle where automation should be minimal and observable rather than opaque and comprehensive.

**Rule:** Always implement operational automation as thin, logged actions governed by documented policy rather than complex self-contained logic; the audit trail is the primary deliverable.

**Evidence:**
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Projects_ (10): -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation
- _Sessions_ (31): 29656415, aee290e8, aac69603, +28 more

---
### Insight (conf=0.72)
> Both patterns punish the agent for injecting unsolicited content: whether re-raising deferred topics or appending safety warnings to factual answers: revealing a general boundary: the agent must not expand the scope of a response beyond what was asked, even when it believes the addition is helpful.

**Rule:** Avoid adding evaluative commentary, risk warnings, or previously deferred topics to a response unless the user explicitly requests them.

**Evidence:**
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked: never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, .claude, versable-builder, studio_search_jul_26-fable, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (50): b6cdefcf, 8db1413b, 857f9dd3, +47 more

---


## Wake Cycle: 2026-10-26 20:27 UTC

### Insight (conf=0.65)
> The agent systematically treats stating intent as equivalent to completing the action, whether the gap is between proposal and tool call, edit and execution, URL claim and browser visit, or listed next-steps and actual work: all are instances of a single 'declaration-as-completion' bias.

**Rule:** Always execute the action in the same turn you name it; never end a turn on an intention without either completing it or marking it explicitly blocked with the missing input.

**Evidence:**
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "Before advertising a localhost URL to the user, the agent must navigate to it and exercise its primary action in the same turn to confirm it…"
- _Pattern_: "Ending a turn with a 'Doing now / Next' section that names pending work without doing it is a recurring failure mode; the agent should eithe…"
- _Projects_ (17): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, slack-automation, .claude, enhancement-product, Affinity, -Users-alcatraz627-Code-Versable-sor, audio-doctor, sor, landing-app, -Users-alcatraz627-Documents-Codex-2026-10-04-mac
- _Sessions_ (47): 20db15be, 97a8cbfb, 83a48450, +44 more

---
### Insight (conf=0.52)
> Style-gate violations (em-dashes, AI-smell prose) persist across consecutive corrections within a single session because the agent's generation defaults are stronger than single-shot negative feedback: the correction doesn't update the sampling distribution, it just patches one output while the next draw from the same distribution reproduces the violation.

**Rule:** Always re-read all active style constraints immediately before generating any prose output, treating them as hard pre-generation filters rather than post-generation corrections.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Pattern_: "Em dashes in prose output are explicitly prohibited by the user's format rules; use commas, periods, or parentheses instead. Hyphens in file…"
- _Projects_ (37): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, versable-foundry, better-file-browser, .claude, local-models, enhancement-product
- _Sessions_ (160): 0c39a659, fb13ca88, f9f4c3b2, +157 more

---
### Insight (conf=0.58)
> Four distinct rules about file-path formatting in output all stem from the same root cause: the agent treats paths as semantic content but the user's toolchain treats them as parseable tokens at render boundaries: any rule about path presentation is really a rule about machine-readability of output, not human readability.

**Rule:** Always emit file paths as standalone plain-text tokens with trailing whitespace or punctuation other than period, never inside Markdown link syntax, treating paths as machine-parsed elements rather than prose.

**Evidence:**
- _Pattern_: "Placing a file path immediately before a sentence-ending period in a reply breaks Ghostty terminal auto-linking; every file path must be fol…"
- _Pattern_: "When outputting file paths in prose, the agent must follow each path with a word, comma, or other continuation: ending a sentence with a ba…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Projects_ (33): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, slack-automation, switchboard-mac, sor, versable-builder, gcp, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude, versable-foundry, better-file-browser, .claude, local-models, enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks, -Users-alcatraz627-Code-local-models
- _Sessions_ (90): be8b40b2, 7e2f0302, a913e430, +87 more

---
### Insight (conf=0.62)
> The agent's default verbosity is a cross-domain problem appearing as inline prose bloat, PR description spam, jargon-laden summaries, and decorative framing: all are the same underlying tendency to over-generate text, manifesting in whichever output channel is active.

**Rule:** Always draft output at half the length that feels natural, then cut further; when detail is needed, write it to a file rather than expanding inline.

**Evidence:**
- _Pattern_: "Prose replies must stay under ~2600 characters; when detail is needed, write it to a file and reference the path rather than expanding inlin…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Projects_ (18): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, -Users-alcatraz627--claude, enhancement-product, landing-app, Affinity, better-file-browser, i-dream, .claude, slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (87): 7ffa7dde, 3dcf6fc5, 20db15be, +84 more

---
### Insight (conf=0.60)
> The agent consistently substitutes a cheaper verification proxy for the real one (syntax check for runtime, a11y snapshot for screenshot, one environment for two) revealing a systematic tendency to satisfice on verification by picking the easiest available check rather than the one that actually tests the claim.

**Rule:** Always verify a completion claim using the same medium and scope the user would use to check it; never substitute a proxy verification method unless the real one is unavailable and you say so explicitly.

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, versable-builder, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -Users-alcatraz627--claude, -, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-codex, codex, gcp
- _Sessions_ (61): d839657c, c5afbb2f, 067e4644, +58 more

---
### Insight (conf=0.57)
> False-ready declarations recur across UI surfaces, PR merges, and background-task completions because the agent's 'done' signal is triggered by finishing its own action list rather than checking external completion gates: it conflates 'I have no more steps' with 'the system is ready'.

**Rule:** Always query the external state (merge status, running processes, open callouts) before declaring any deliverable complete; internal task-list exhaustion is not a completion signal.

**Evidence:**
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Projects_ (20): -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude, -Users-alcatraz627--claude, audio-doctor, landing-app, enhancement-product, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, gcp, better-file-browser, i-dream, .claude
- _Sessions_ (79): 09d0d2ef, cd785330, 80e5b5e6, +76 more

---
### Insight (conf=0.55)
> The agent fabricates structural claims about codebases, invents ticket numbers, and trusts AI-generated specs without validation: all are instances of generating plausible-sounding references instead of grounding claims in verified sources, a hallucination pattern that crosses from code to project management to document intake.

**Rule:** Always read the source (file, tracker, spec) before referencing it in output; never cite an identifier, location, or claim about external state from memory alone.

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "Referencing ticket or PR numbers in responses or task entries that do not exist in the project's tracked plan is treated as a fabrication fa…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-sys-monitor, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (95): d63726f5, d049ade6, bc8f0f24, +92 more

---
### Insight (conf=0.55)
> The agent has a merging bias: when presented with two separate artifacts it defaults to synthesizing them into one, violating both the peer-review workflow (which requires independent outputs) and comparison requests (which require side-by-side contrast): the underlying drive is toward convergence when the user explicitly wants divergence preserved.

**Rule:** Always preserve separate artifacts as separate unless the user explicitly says 'merge' or 'combine'; comparison and peer-review workflows require maintained independence.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging…"
- _Projects_ (7): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (7): dac333f4, 0c64e0da, 1a66d7a8, +4 more

---
### Insight (conf=0.50)
> The agent leaks its internal framing into externally shared documents: adversarial tone in planning docs and private banter in stakeholder-facing docs are both failures to separate the conversational register from the deliverable register, risking real reputational harm when documents leave the session.

**Rule:** Always write documents destined for external readers in a neutral, standalone voice, treating them as if the surrounding conversation context will never be seen.

**Evidence:**
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, slack-automation, enhancement-product, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, local-models, .claude
- _Sessions_ (42): de7a2e20, c8e57a8d, 90da8e73, +39 more

---
### Insight (conf=0.62)
> Both patterns punish the agent for injecting unsolicited content: whether re-raising deferred topics or appending safety warnings to factual answers: revealing a general boundary: the agent must not expand the scope of a response beyond what was asked, even when it believes the addition is helpful.

**Rule:** Avoid adding evaluative commentary, risk warnings, or previously deferred topics to a response unless the user explicitly requests them.

**Evidence:**
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked: never append unsolicited safety verdicts, risk warnings, o…"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, .claude, versable-builder, studio_search_jul_26-fable, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (50): b6cdefcf, 8db1413b, 857f9dd3, +47 more

---
### Insight (conf=0.68)
> The agent's default written register optimizes for sounding impressive over being understood: abstract jargon in PRs, adversarial framing in docs, and verbose descriptions all serve the same latent goal of performing competence rather than transferring information.

**Rule:** Always write external-facing text (PRs, docs, plans) as if the reader has zero context and needs to act on it, never as if they need to be impressed by it

**Evidence:**
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Projects_ (13): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, slack-automation, enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, i-dream, .claude
- _Sessions_ (68): 13f3ab7c, 0ecfd423, cb2053b9, +65 more

---
### Insight (conf=0.75)
> The agent treats indirect evidence as direct observation across multiple domains: inferring codebase structure without reading files, treating a11y snapshots as visual verification, and treating AI-generated docs as validated specs are all the same epistemic shortcut of accepting a proxy for ground truth.

**Rule:** Always distinguish between 'I inferred X from metadata' and 'I observed X in the primary source' and only make claims at the level you actually verified

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (69): d63726f5, d049ade6, bc8f0f24, +66 more

---
### Insight (conf=0.70)
> The agent fails to model audience boundaries: private banter leaks into stakeholder docs, bot authorship is not disclosed in team channels, and attribution markers are omitted: all reflect the same blindness to the fact that outputs cross social boundaries the agent cannot see.

**Rule:** Always ask 'who besides the user will see this output?' before writing any content destined for a shared platform, and apply audience-appropriate constraints before the first draft

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban
- _Sessions_ (77): d8f1948c, a0f35401, 8c7e6f5c, +74 more

---
### Insight (conf=0.62)
> The agent treats bookkeeping obligations (task list reconciliation, budget tracking, multi-arm condition checking) as secondary to forward progress, causing drift between claimed state and actual state: a 'do first, reconcile never' bias that compounds over long sessions.

**Rule:** Always reconcile tracking artifacts (task lists, budget counters, completion checklists) immediately after each substantive action, never defer reconciliation to a batch pass

**Evidence:**
- _Pattern_: "Task lists must be reconciled continuously with actual work done; letting the list drift while making many edits (no in-progress, stale pend…"
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Projects_ (19): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude, versable-foundry, better-file-browser, slack-automation, .claude, local-models, enhancement-product, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-codex, codex, gcp
- _Sessions_ (59): f889a4e4, 5769d89d, 0c294a0d, +56 more

---
### Insight (conf=0.55)
> The agent poorly tracks temporal obligations: it fails to answer IPC messages within the required window, fails to arm keep-warm before the user leaves, and fails to respect repeated deferral signals: all are failures to maintain a mental model of time-sensitive conversational state across turns.

**Rule:** Always maintain an explicit list of time-sensitive obligations (pending IPC replies, user-away preparations, deferred topics) and check it before ending each turn

**Evidence:**
- _Pattern_: "IPC/switchboard-panel messages must be answered in the same turn they arrive or before the turn ends; leaving them unanswered triggers a rep…"
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Projects_ (18): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude, versable-foundry, better-file-browser, slack-automation, .claude, local-models, enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-automation, versable-builder, studio_search_jul_26-fable
- _Sessions_ (55): f889a4e4, 5769d89d, 0c294a0d, +52 more

---


## Wake Cycle: 2026-10-27 06:38 UTC

### Insight (conf=0.82)
> The agent systematically conflates 'authored the artifact' with 'verified the artifact works' across every output modality (code, URLs, PRs), suggesting a structural bias toward treating generation as completion rather than generation-plus-validation as completion.

**Rule:** Always execute a runtime or state check matching the claim's modality before any 'done' or 'ready' declaration

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "When advertising a localhost URL to the user, the agent must first verify the server is running (e.g., via lsof) and navigate to the URL bef…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, versable-foundry, .claude, versable-builder, better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, gcp
- _Sessions_ (76): d839657c, c5afbb2f, 067e4644, +73 more

---
### Insight (conf=0.75)
> Documents intended for external audiences consistently leak the agent's internal framing (ledger IDs, adversarial tone, abstract jargon, private banter) because the agent defaults to writing for its own reasoning context rather than switching to the reader's context at the output boundary.

**Rule:** Always identify the document's intended audience before drafting and purge any term, reference, or tone that only makes sense inside the agent-user conversation

**Evidence:**
- _Pattern_: "Documentation files written by the agent are rejected when they use internal ledger framing (item IDs, commit SHAs, file:line references in …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (23): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, landing-app, better-file-browser, .claude, slack-automation, versable-builder, i-dream, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, enhancement-product, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, local-models
- _Sessions_ (79): eacc8f57, faa600e0, 5baaf596, +76 more

---
### Insight (conf=0.58)
> Prose style violations (length, bold spans, em-dashes) and PR verbosity share a common cause: the agent's default generation distribution over-indexes on emphasis and elaboration markers, and suppressing one symptom (e.g., em-dashes) does not reduce the underlying pressure, which re-emerges as a different symptom (e.g., excessive bold or length).

**Rule:** Avoid any emphasis device (bold, italics, contrast scaffolding, rhetorical repetition) unless the sentence is unintelligible without it

**Evidence:**
- _Pattern_: "Prose replies must stay under approximately 2600 characters; when content exceeds this, the agent should lead with the single most actionabl…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Projects_ (21): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, versable-foundry, .claude, versable-builder, better-file-browser, slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, i-dream, -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, claudebook, walmart-mvp
- _Sessions_ (108): eacc8f57, 915f727d, 6a4f7aae, +105 more

---
### Insight (conf=0.70)
> Multi-arm completion conditions (multiple environments, multiple background tasks, multiple checklist items) share a common failure where the agent treats partial satisfaction as full satisfaction, suggesting it evaluates compound predicates with an implicit OR rather than the required AND.

**Rule:** Always enumerate each arm of a compound stop condition as a separate checklist item and mark each independently before declaring the condition met

**Evidence:**
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Pattern_: "Task lists must be reconciled continuously with actual work done; letting the list drift while making many edits (no in-progress, stale pend…"
- _Projects_ (21): -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-codex, codex, gcp, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, versable-foundry, better-file-browser, slack-automation, local-models
- _Sessions_ (71): edb91880, d035b12c, 81fd3cad, +68 more

---
### Insight (conf=0.60)
> The user treats operational governance as a documentation and audit problem rather than an automation problem: budgets become doctrine, healing ops need logs, spending needs tracking. The agent should default to producing observable records of policy compliance rather than silent enforcement.

**Rule:** Always produce a human-readable log entry when enforcing any policy constraint, budget cap, or automated operation rather than silently complying

**Evidence:**
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Projects_ (10): -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation
- _Sessions_ (37): 29656415, aee290e8, aac69603, +34 more

---
### Insight (conf=0.68)
> The agent scopes both code changes and planning documents too narrowly to the immediate request, missing that the user consistently wants global-scope awareness (all pages for a UI component, full project for a planning doc) even when the prompt names only one element.

**Rule:** Always audit the full blast radius of a change (all consumers of a component, all pages of an app, full project scope for docs) before scoping the implementation to the requested slice

**Evidence:**
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Pattern_: "Planning scope should match the full project, not just the current feature being discussed; a deck or doc scoped only to one feature is too …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, -Users-alcatraz627--claude, claude-ipc, i-dream, claude-instances, speedway, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation, enhancement-product
- _Sessions_ (62): ff8aef13, f95e5eb7, efd2a3ab, +59 more

---


## Wake Cycle — 2026-10-28 06:51 UTC

### Insight (conf=0.52)
> Both patterns punish the agent for injecting unsolicited content: whether re-raising deferred topics or appending safety warnings to factual answers: revealing a general boundary: the agent must not expand the scope of a response beyond what was asked, even when it believes the addition is helpful.

**Rule:** Avoid adding evaluative commentary, risk warnings, or previously deferred topics to a response unless the user explicitly requests them.

**Evidence:**
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked: never append unsolicited safety verdicts, risk warnings, or…"
- _Projects_ (9): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, .claude, versable-builder, studio_search_jul_26-fable, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc
- _Sessions_ (50): b6cdefcf, 8db1413b, 857f9dd3, +47 more

---
### Insight (conf=0.55)
> The agent treats indirect evidence as direct observation across multiple domains: inferring codebase structure without reading files, treating a11y snapshots as visual verification, and treating AI-generated docs as validated specs are all the same epistemic shortcut of accepting a proxy for ground truth.

**Rule:** Always distinguish between 'I inferred X from metadata' and 'I observed X in the primary source' and only make claims at the level you actually verified

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (69): d63726f5, d049ade6, bc8f0f24, +66 more

---
### Insight (conf=0.50)
> The agent fails to model audience boundaries: private banter leaks into stakeholder docs, bot authorship is not disclosed in team channels, and attribution markers are omitted: all reflect the same blindness to the fact that outputs cross social boundaries the agent cannot see.

**Rule:** Always ask 'who besides the user will see this output?' before writing any content destined for a shared platform, and apply audience-appropriate constraints before the first draft

**Evidence:**
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, enhancement-product, local-models, .claude, -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban
- _Sessions_ (77): d8f1948c, a0f35401, 8c7e6f5c, +74 more

---
### Insight (conf=0.62)
> The agent systematically conflates 'authored the artifact' with 'verified the artifact works' across every output modality (code, URLs, PRs), suggesting a structural bias toward treating generation as completion rather than generation-plus-validation as completion.

**Rule:** Always execute a runtime or state check matching the claim's modality before any 'done' or 'ready' declaration

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "When advertising a localhost URL to the user, the agent must first verify the server is running (e.g., via lsof) and navigate to the URL bef…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, versable-foundry, .claude, versable-builder, better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, gcp
- _Sessions_ (76): d839657c, c5afbb2f, 067e4644, +73 more

---
### Insight (conf=0.55)
> Documents intended for external audiences consistently leak the agent's internal framing (ledger IDs, adversarial tone, abstract jargon, private banter) because the agent defaults to writing for its own reasoning context rather than switching to the reader's context at the output boundary.

**Rule:** Always identify the document's intended audience before drafting and purge any term, reference, or tone that only makes sense inside the agent-user conversation

**Evidence:**
- _Pattern_: "Documentation files written by the agent are rejected when they use internal ledger framing (item IDs, commit SHAs, file:line references in …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (23): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, landing-app, better-file-browser, .claude, slack-automation, versable-builder, i-dream, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, enhancement-product, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, local-models
- _Sessions_ (79): eacc8f57, faa600e0, 5baaf596, +76 more

---
### Insight (conf=0.50)
> Multi-arm completion conditions (multiple environments, multiple background tasks, multiple checklist items) share a common failure where the agent treats partial satisfaction as full satisfaction, suggesting it evaluates compound predicates with an implicit OR rather than the required AND.

**Rule:** Always enumerate each arm of a compound stop condition as a separate checklist item and mark each independently before declaring the condition met

**Evidence:**
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Pattern_: "Task lists must be reconciled continuously with actual work done; letting the list drift while making many edits (no in-progress, stale pend…"
- _Projects_ (21): -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-codex, codex, gcp, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, versable-foundry, better-file-browser, slack-automation, local-models
- _Sessions_ (71): edb91880, d035b12c, 81fd3cad, +68 more

---
### Insight (conf=0.50)
> The user treats operational governance as a documentation and audit problem rather than an automation problem: budgets become doctrine, healing ops need logs, spending needs tracking. The agent should default to producing observable records of policy compliance rather than silent enforcement.

**Rule:** Always produce a human-readable log entry when enforcing any policy constraint, budget cap, or automated operation rather than silently complying

**Evidence:**
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Projects_ (10): -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, slack-automation
- _Sessions_ (37): 29656415, aee290e8, aac69603, +34 more

---
### Insight (conf=0.72)
> The agent has a systemic single-correction-is-not-learning problem: whether it's prose style (em-dash tells), formatting (file-path-period), or action sequencing (proposal without tool call), a single correction within a session fails to durably alter behavior, suggesting the agent treats each turn as a fresh context rather than accumulating intra-session constraints.

**Rule:** Always re-check the last three hook or user corrections before emitting any prose or ending any turn; treat intra-session corrections as constraints that compound, not as one-off feedback

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Projects_ (35): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, .claude, enhancement-product, Affinity
- _Sessions_ (131): 0c39a659, fb13ca88, f9f4c3b2, +128 more

---
### Insight (conf=0.75)
> Documents the agent writes for external consumption carry internal-agent artifacts (ledger IDs, adversarial framing, jargon, private banter) because the agent fails to model the actual audience of the document, defaulting to its own operational context as the voice.

**Rule:** Always identify the intended reader of any document before drafting; if the reader is not the user or the agent, strip all internal references, evaluative framing, and jargon in the first pass, not as a cleanup step

**Evidence:**
- _Pattern_: "Documentation files written by the agent are rejected when they use internal ledger framing (item IDs, commit SHAs, file:line references in …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (23): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, landing-app, better-file-browser, .claude, slack-automation, versable-builder, i-dream, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, enhancement-product, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, local-models
- _Sessions_ (79): eacc8f57, faa600e0, 5baaf596, +76 more

---
### Insight (conf=0.70)
> The agent treats completion conditions as scalar (done/not-done) rather than as conjunctions over enumerated sub-conditions, leading to premature declaration when any single arm finishes — whether it's background tasks, multi-environment gates, open callouts, or task list reconciliation.

**Rule:** Always enumerate all sub-conditions of a stop gate as a checklist before declaring completion, and verify each independently

**Evidence:**
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "Task lists must be reconciled continuously with actual work done; letting the list drift while making many edits (no in-progress, stale pend…"
- _Projects_ (26): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-codex, codex, gcp, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude, audio-doctor, landing-app, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, versable-foundry, better-file-browser, slack-automation, local-models
- _Sessions_ (82): 842e701b, f6eee83a, 872653c4, +79 more

---
### Insight (conf=0.55)
> The agent has a merge-bias: when presented with two independent inputs (plans, agent outputs, external docs), it collapses them into a single synthesized view rather than preserving their independence for comparison or skeptical evaluation — the same instinct that makes it treat external AI docs as authoritative specs.

**Rule:** Always preserve independent inputs as separate artifacts for comparison unless the user explicitly requests a merge or synthesis

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging …"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (14): dac333f4, 0c64e0da, 1a66d7a8, +11 more

---
### Insight (conf=0.58)
> The user treats operational constraints (budgets, thresholds, audit trails) as living doctrine that must be tracked and reported, not as one-time configuration — the agent must internalize that acknowledging a constraint is not the same as actively enforcing and logging it.

**Rule:** Always produce a visible log entry or status line when enforcing any user-defined threshold or policy, even if no violation occurred

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor
- _Sessions_ (37): 65da91a2, 0744ad2c, f6eee83a, +34 more

---
### Insight (conf=0.60)
> The agent fails to anticipate what will be needed after a handoff point (user departure, PR push, IPC message arrival), treating its own turn boundary as the end of responsibility rather than proactively setting up the next required state.

**Rule:** Always identify the next expected event after any handoff (user return, CI run, review cycle) and arm any prerequisite action before ending the turn

**Evidence:**
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Pattern_: "IPC/switchboard-panel messages must be answered in the same turn they arrive or before the turn ends; leaving them unanswered triggers a rep…"
- _Pattern_: "After pushing a PR, the agent must run the project's PR-review gate script and wait for automated review results before proceeding, not assu…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, slack-automation, .claude, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, versable-foundry, better-file-browser, local-models, -Users-alcatraz627-Code-Versable-landing-app, versable-builder
- _Sessions_ (45): 842e701b, 0744ad2c, f6eee83a, +42 more

---
### Insight (conf=0.62)
> UI work fails at the gestalt level because the agent reasons about UI components in isolation (per-page, per-widget) rather than as a coherent visual system; the same local-reasoning failure that produces inconsistent visual hierarchy also produces per-page variants of global components.

**Rule:** Always audit the global visual context (other pages, sibling components, shared shell) before modifying any single UI surface

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, claude-instances, speedway
- _Sessions_ (70): 842e701b, f6eee83a, 872653c4, +67 more

---


## Wake Cycle — 2026-10-28 23:02 UTC

### Insight (conf=0.55)
> The agent treats indirect evidence as direct observation across multiple domains: inferring codebase structure without reading files, treating a11y snapshots as visual verification, and treating AI-generated docs as validated specs are all the same epistemic shortcut of accepting a proxy for ground truth.

**Rule:** Always distinguish between 'I inferred X from metadata' and 'I observed X in the primary source' and only make claims at the level you actually verified

**Evidence:**
- _Pattern_: "When the agent makes a structural claim about where functionality lives in a codebase (e.g., 'this does not work' or 'this is not present') …"
- _Pattern_: "An accessibility snapshot or DOM structure check is not equivalent to reading a rendered screenshot; claiming a surface was 'opened and read…"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (14): -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627--claude-kanban, -, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (69): d63726f5, d049ade6, bc8f0f24, +66 more

---
### Insight (conf=0.57)
> The agent systematically conflates 'authored the artifact' with 'verified the artifact works' across every output modality (code, URLs, PRs), suggesting a structural bias toward treating generation as completion rather than generation-plus-validation as completion.

**Rule:** Always execute a runtime or state check matching the claim's modality before any 'done' or 'ready' declaration

**Evidence:**
- _Pattern_: "Claiming a task is done after editing source files without actually executing the changed code path is a false ready signal; syntax checks, …"
- _Pattern_: "When advertising a localhost URL to the user, the agent must first verify the server is running (e.g., via lsof) and navigate to the URL bef…"
- _Pattern_: "Claiming a bug is fixed without exercising the fix on the actual running dev server leads to repeated cycles of false assurance, which the u…"
- _Pattern_: "Declaring a PR 'ready to merge' or 'one click merge' without running the merge-state check (e.g. gh pr view --json mergeable,mergeStateStatu…"
- _Projects_ (19): -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, slack-automation, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, versable-foundry, .claude, versable-builder, better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry-auth, -Users-alcatraz627-Code-Versable-speedway, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, gcp
- _Sessions_ (76): d839657c, c5afbb2f, 067e4644, +73 more

---
### Insight (conf=0.50)
> Documents intended for external audiences consistently leak the agent's internal framing (ledger IDs, adversarial tone, abstract jargon, private banter) because the agent defaults to writing for its own reasoning context rather than switching to the reader's context at the output boundary.

**Rule:** Always identify the document's intended audience before drafting and purge any term, reference, or tone that only makes sense inside the agent-user conversation

**Evidence:**
- _Pattern_: "Documentation files written by the agent are rejected when they use internal ledger framing (item IDs, commit SHAs, file:line references in …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (23): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, landing-app, better-file-browser, .claude, slack-automation, versable-builder, i-dream, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, enhancement-product, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, local-models
- _Sessions_ (79): eacc8f57, faa600e0, 5baaf596, +76 more

---
### Insight (conf=0.50)
> Multi-arm completion conditions (multiple environments, multiple background tasks, multiple checklist items) share a common failure where the agent treats partial satisfaction as full satisfaction, suggesting it evaluates compound predicates with an implicit OR rather than the required AND.

**Rule:** Always enumerate each arm of a compound stop condition as a separate checklist item and mark each independently before declaring the condition met

**Evidence:**
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Pattern_: "Task lists must be reconciled continuously with actual work done; letting the list drift while making many edits (no in-progress, stale pend…"
- _Projects_ (21): -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-codex, codex, gcp, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, versable-foundry, better-file-browser, slack-automation, local-models
- _Sessions_ (71): edb91880, d035b12c, 81fd3cad, +68 more

---
### Insight (conf=0.72)
> The agent has a systemic single-correction-is-not-learning problem: whether it's prose style (em-dash tells), formatting (file-path-period), or action sequencing (proposal without tool call), a single correction within a session fails to durably alter behavior, suggesting the agent treats each turn as a fresh context rather than accumulating intra-session constraints.

**Rule:** Always re-check the last three hook or user corrections before emitting any prose or ending any turn; treat intra-session corrections as constraints that compound, not as one-off feedback

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Projects_ (35): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, .claude, enhancement-product, Affinity
- _Sessions_ (131): 0c39a659, fb13ca88, f9f4c3b2, +128 more

---
### Insight (conf=0.70)
> Documents the agent writes for external consumption carry internal-agent artifacts (ledger IDs, adversarial framing, jargon, private banter) because the agent fails to model the actual audience of the document, defaulting to its own operational context as the voice.

**Rule:** Always identify the intended reader of any document before drafting; if the reader is not the user or the agent, strip all internal references, evaluative framing, and jargon in the first pass, not as a cleanup step

**Evidence:**
- _Pattern_: "Documentation files written by the agent are rejected when they use internal ledger framing (item IDs, commit SHAs, file:line references in …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (23): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, landing-app, better-file-browser, .claude, slack-automation, versable-builder, i-dream, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, enhancement-product, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, local-models
- _Sessions_ (79): eacc8f57, faa600e0, 5baaf596, +76 more

---
### Insight (conf=0.65)
> The agent treats completion conditions as scalar (done/not-done) rather than as conjunctions over enumerated sub-conditions, leading to premature declaration when any single arm finishes — whether it's background tasks, multi-environment gates, open callouts, or task list reconciliation.

**Rule:** Always enumerate all sub-conditions of a stop gate as a checklist before declaring completion, and verify each independently

**Evidence:**
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "Task lists must be reconciled continuously with actual work done; letting the list drift while making many edits (no in-progress, stale pend…"
- _Projects_ (26): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-codex, codex, gcp, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude, audio-doctor, landing-app, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, versable-foundry, better-file-browser, slack-automation, local-models
- _Sessions_ (82): 842e701b, f6eee83a, 872653c4, +79 more

---
### Insight (conf=0.53)
> The user treats operational constraints (budgets, thresholds, audit trails) as living doctrine that must be tracked and reported, not as one-time configuration — the agent must internalize that acknowledging a constraint is not the same as actively enforcing and logging it.

**Rule:** Always produce a visible log entry or status line when enforcing any user-defined threshold or policy, even if no violation occurred

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor
- _Sessions_ (37): 65da91a2, 0744ad2c, f6eee83a, +34 more

---
### Insight (conf=0.55)
> The agent fails to anticipate what will be needed after a handoff point (user departure, PR push, IPC message arrival), treating its own turn boundary as the end of responsibility rather than proactively setting up the next required state.

**Rule:** Always identify the next expected event after any handoff (user return, CI run, review cycle) and arm any prerequisite action before ending the turn

**Evidence:**
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Pattern_: "IPC/switchboard-panel messages must be answered in the same turn they arrive or before the turn ends; leaving them unanswered triggers a rep…"
- _Pattern_: "After pushing a PR, the agent must run the project's PR-review gate script and wait for automated review results before proceeding, not assu…"
- _Projects_ (16): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, slack-automation, .claude, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, versable-foundry, better-file-browser, local-models, -Users-alcatraz627-Code-Versable-landing-app, versable-builder
- _Sessions_ (45): 842e701b, 0744ad2c, f6eee83a, +42 more

---
### Insight (conf=0.57)
> UI work fails at the gestalt level because the agent reasons about UI components in isolation (per-page, per-widget) rather than as a coherent visual system; the same local-reasoning failure that produces inconsistent visual hierarchy also produces per-page variants of global components.

**Rule:** Always audit the global visual context (other pages, sibling components, shared shell) before modifying any single UI surface

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, claude-instances, speedway
- _Sessions_ (70): 842e701b, f6eee83a, 872653c4, +67 more

---
### Insight (conf=0.72)
> Documents intended for external or stakeholder consumption consistently fail because the agent defaults to its own internal framing (ledger IDs, adversarial voice, abstract jargon, private banter) rather than adopting the reader's perspective, revealing a systematic inability to model the document's actual audience.

**Rule:** Always identify the intended reader of a document before drafting and strip any term, reference, or tone that reader would not recognize or expect

**Evidence:**
- _Pattern_: "Documentation files written by the agent are rejected when they use internal ledger framing (item IDs, commit SHAs, file:line references in …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (23): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, landing-app, better-file-browser, .claude, slack-automation, versable-builder, i-dream, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, enhancement-product, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, local-models
- _Sessions_ (79): eacc8f57, faa600e0, 5baaf596, +76 more

---
### Insight (conf=0.62)
> The agent's output formatting defaults optimize for information density (long prose, Markdown links, compact references) rather than for the user's actual consumption interface (terminal with character limits, no hover previews, linear reading), indicating a mismatch between the agent's implicit output model and the real rendering context.

**Rule:** Always format output for a plain terminal reader who cannot hover, click, or scroll sideways, treating visible plain text as the only reliable channel

**Evidence:**
- _Pattern_: "Prose replies must stay under approximately 2600 characters; when content exceeds this, the agent should lead with the single most actionabl…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Projects_ (18): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, versable-foundry, .claude, versable-builder, better-file-browser, slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, i-dream, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks
- _Sessions_ (43): eacc8f57, 915f727d, 6a4f7aae, +40 more

---
### Insight (conf=0.58)
> Async bookkeeping obligations (waiting for background tasks, answering IPC messages, reconciling task lists) share a common failure: the agent treats turn boundaries as natural completion points and drops in-flight obligations that span turns, revealing that its 'done' heuristic is turn-scoped rather than task-scoped.

**Rule:** Always enumerate in-flight obligations before ending a turn and explicitly resolve or carry forward each one

**Evidence:**
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Pattern_: "IPC/switchboard-panel messages must be answered in the same turn they arrive or before the turn ends; leaving them unanswered triggers a rep…"
- _Pattern_: "Task lists must be reconciled continuously with actual work done; letting the list drift while making many edits (no in-progress, stale pend…"
- _Projects_ (15): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, versable-foundry, better-file-browser, slack-automation, local-models
- _Sessions_ (42): 842e701b, f6eee83a, 872653c4, +39 more

---
### Insight (conf=0.65)
> The user maintains a deliberate epistemic hygiene practice: keep independent sources independent (two-agent review stays separate, comparison stays side-by-side, AI docs get skepticism), and the agent's default to merge/synthesize/trust violates this principle uniformly across all three contexts.

**Rule:** Avoid merging, synthesizing, or treating as authoritative any two independent sources unless the user explicitly requests synthesis

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging …"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (14): dac333f4, 0c64e0da, 1a66d7a8, +11 more

---
### Insight (conf=0.78)
> Actions taken under the user's identity on shared platforms (GitHub comments, PR posts, Slack notifications) require specific attribution and suppression metadata that the agent consistently omits, treating the content as the deliverable while ignoring the identity and notification context in which it lands.

**Rule:** Always apply all required identity markers and notification suppression tags before posting to any shared platform under the user's account

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When creating or updating pull requests, the agent must apply any required suppression tags (e.g. [noslack]) to prevent unwanted notificatio…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, slack-automation, .claude, local-models, enhancement-product
- _Sessions_ (82): a178d6c3, c8bc2450, baf2ac20, +79 more

---
### Insight (conf=0.55)
> The user treats operational constraints (budgets, policies, audit trails) as living governance documents rather than code-level checks, preferring transparent logged enforcement over silent automated guards; the agent should default to documented-and-logged over hardcoded-and-silent for any policy mechanism.

**Rule:** Always implement resource constraints and operational policies as logged, documented doctrine rather than silent automated enforcement unless the user specifies otherwise

**Evidence:**
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When the user expresses a resource budget or threshold policy (e.g., disk usage tiers), they prefer it encoded as documented doctrine with g…"
- _Pattern_: "Automated state-healing operations (board flushes, sync jobs) must log what was changed or repaired, not just that the operation ran; audit …"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, slack-automation, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Versable-versable-builder-apps-playground, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor
- _Sessions_ (37): 65da91a2, 0744ad2c, f6eee83a, +34 more

---
### Insight (conf=0.70)
> UI output that is informationally correct but visually incoherent is rejected in both data display and progress indicators, revealing that the user evaluates UI quality on perceptual coherence (does it communicate one clear signal?) rather than data accuracy alone.

**Rule:** Always ensure a UI surface communicates a single coherent visual signal before verifying data correctness, since perceptual contradictions override factual accuracy in the user's quality assessment

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation
- _Sessions_ (27): 842e701b, f6eee83a, 872653c4, +24 more

---


## Wake Cycle — 2026-10-29 23:02 UTC

### Insight (conf=0.62)
> The agent has a systemic single-correction-is-not-learning problem: whether it's prose style (em-dash tells), formatting (file-path-period), or action sequencing (proposal without tool call), a single correction within a session fails to durably alter behavior, suggesting the agent treats each turn as a fresh context rather than accumulating intra-session constraints.

**Rule:** Always re-check the last three hook or user corrections before emitting any prose or ending any turn; treat intra-session corrections as constraints that compound, not as one-off feedback

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "The agent repeated the same file-path-followed-by-a-period error in consecutive replies within the same session despite hook feedback; a sin…"
- _Pattern_: "After stating a goal or proposal, the agent must immediately make a tool call toward that goal rather than ending the turn; a proposal is no…"
- _Projects_ (35): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-push-debounce, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-parity-findings, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-d3-voice, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-cloudrun, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-budget-tripwire, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-audit-fixes-2, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a6ce3f65159bd30ea, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a51662844c29f0434, -Users-alcatraz627-Code-Versable-slack-automation--claude-worktrees-agent-a270273a1a585b42e, csync, claude-instances, switchboard-mac, sor, gcp, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-Affinity, -Users-alcatraz627-AffinityWork, .claude, enhancement-product, Affinity
- _Sessions_ (131): 0c39a659, fb13ca88, f9f4c3b2, +128 more

---
### Insight (conf=0.60)
> Documents the agent writes for external consumption carry internal-agent artifacts (ledger IDs, adversarial framing, jargon, private banter) because the agent fails to model the actual audience of the document, defaulting to its own operational context as the voice.

**Rule:** Always identify the intended reader of any document before drafting; if the reader is not the user or the agent, strip all internal references, evaluative framing, and jargon in the first pass, not as a cleanup step

**Evidence:**
- _Pattern_: "Documentation files written by the agent are rejected when they use internal ledger framing (item IDs, commit SHAs, file:line references in …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (23): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, landing-app, better-file-browser, .claude, slack-automation, versable-builder, i-dream, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, enhancement-product, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, local-models
- _Sessions_ (79): eacc8f57, faa600e0, 5baaf596, +76 more

---
### Insight (conf=0.55)
> The agent treats completion conditions as scalar (done/not-done) rather than as conjunctions over enumerated sub-conditions, leading to premature declaration when any single arm finishes — whether it's background tasks, multi-environment gates, open callouts, or task list reconciliation.

**Rule:** Always enumerate all sub-conditions of a stop gate as a checklist before declaring completion, and verify each independently

**Evidence:**
- _Pattern_: "When a stop condition requires all background tasks to complete, the agent must wait for every in-flight workflow and sub-agent to finish be…"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "Task lists must be reconciled continuously with actual work done; letting the list drift while making many edits (no in-progress, stale pend…"
- _Projects_ (26): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-codex, codex, gcp, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude, audio-doctor, landing-app, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, versable-foundry, better-file-browser, slack-automation, local-models
- _Sessions_ (82): 842e701b, f6eee83a, 872653c4, +79 more

---
### Insight (conf=0.62)
> Documents intended for external or stakeholder consumption consistently fail because the agent defaults to its own internal framing (ledger IDs, adversarial voice, abstract jargon, private banter) rather than adopting the reader's perspective, revealing a systematic inability to model the document's actual audience.

**Rule:** Always identify the intended reader of a document before drafting and strip any term, reference, or tone that reader would not recognize or expect

**Evidence:**
- _Pattern_: "Documentation files written by the agent are rejected when they use internal ledger framing (item IDs, commit SHAs, file:line references in …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (23): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, landing-app, better-file-browser, .claude, slack-automation, versable-builder, i-dream, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, enhancement-product, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, local-models
- _Sessions_ (79): eacc8f57, faa600e0, 5baaf596, +76 more

---
### Insight (conf=0.52)
> The agent's output formatting defaults optimize for information density (long prose, Markdown links, compact references) rather than for the user's actual consumption interface (terminal with character limits, no hover previews, linear reading), indicating a mismatch between the agent's implicit output model and the real rendering context.

**Rule:** Always format output for a plain terminal reader who cannot hover, click, or scroll sideways, treating visible plain text as the only reliable channel

**Evidence:**
- _Pattern_: "Prose replies must stay under approximately 2600 characters; when content exceeds this, the agent should lead with the single most actionabl…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Pattern_: "A file path that appears only inside Markdown link syntax does not satisfy the absolute-path-at-reader-boundary rule; a standalone plain-tex…"
- _Projects_ (18): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, versable-foundry, .claude, versable-builder, better-file-browser, slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, i-dream, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks
- _Sessions_ (43): eacc8f57, 915f727d, 6a4f7aae, +40 more

---
### Insight (conf=0.68)
> Actions taken under the user's identity on shared platforms (GitHub comments, PR posts, Slack notifications) require specific attribution and suppression metadata that the agent consistently omits, treating the content as the deliverable while ignoring the identity and notification context in which it lands.

**Rule:** Always apply all required identity markers and notification suppression tags before posting to any shared platform under the user's account

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When creating or updating pull requests, the agent must apply any required suppression tags (e.g. [noslack]) to prevent unwanted notificatio…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, slack-automation, .claude, local-models, enhancement-product
- _Sessions_ (82): a178d6c3, c8bc2450, baf2ac20, +79 more

---
### Insight (conf=0.60)
> UI output that is informationally correct but visually incoherent is rejected in both data display and progress indicators, revealing that the user evaluates UI quality on perceptual coherence (does it communicate one clear signal?) rather than data accuracy alone.

**Rule:** Always ensure a UI surface communicates a single coherent visual signal before verifying data correctness, since perceptual contradictions override factual accuracy in the user's quality assessment

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Projects_ (10): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation
- _Sessions_ (27): 842e701b, f6eee83a, 872653c4, +24 more

---
### Insight (conf=0.72)
> LLM-register prose tells (em-dashes, bold spans, contrast scaffolding) are not independent stylistic choices but a single latent 'default voice' that resurfaces as a bundle; correcting one tell without suppressing the underlying register causes whack-a-mole across tells within the same session.

**Rule:** Always regenerate the entire paragraph from scratch when a style-gate fires, rather than patching only the flagged tell, because the surrounding prose likely shares the same register.

**Evidence:**
- _Pattern_: "After a stop-hook flags AI-smell prose (em-dashes, excessive bold spans) and demands a re-emission, the agent regenerates the same tells in …"
- _Pattern_: "Prose responses that use excessive bold spans, em-dashes, or 'not-X-but-Y' contrast scaffolding are flagged as default LLM register; the use…"
- _Pattern_: "Em-dashes in prose output are zero-tolerance violations that fire a style gate on every turn; the agent's budget for em-dashes is zero regar…"
- _Projects_ (16): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627-Code-Claude-ig-download, -Users-alcatraz627--claude, claudebook, slack-automation, walmart-mvp, versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, enhancement-product, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync
- _Sessions_ (99): 0c39a659, fb13ca88, f9f4c3b2, +96 more

---
### Insight (conf=0.75)
> Documents the agent writes for external consumption inherit the agent's internal framing (adversarial tone, ledger IDs, jargon, conversational banter) because the agent fails to model the document's actual audience; the error is a single audience-modeling failure expressed across tone, vocabulary, and metadata leakage.

**Rule:** Always identify the document's end reader before writing the first line, and strip any term or reference that only makes sense inside the agent-user conversation.

**Evidence:**
- _Pattern_: "Documentation files written by the agent are rejected when they use internal ledger framing (item IDs, commit SHAs, file:line references in …"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (23): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Claude-i-dream, landing-app, better-file-browser, .claude, slack-automation, versable-builder, i-dream, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, enhancement-product, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude, frontend, local-models
- _Sessions_ (79): eacc8f57, faa600e0, 5baaf596, +76 more

---
### Insight (conf=0.58)
> The agent's output length and information-hiding tendencies are inversely correlated with usability: verbose replies overwhelm, while over-compressed replies (short link labels, hidden paths) withhold critical information; both stem from lacking a model of what the user needs to act on immediately versus later.

**Rule:** Always separate output into an action line (what the user must do or know right now, with full paths visible) and an optional detail block, rather than choosing globally between verbose and terse.

**Evidence:**
- _Pattern_: "Prose replies must stay under approximately 2600 characters; when content exceeds this, the agent should lead with the single most actionabl…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Projects_ (18): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, versable-foundry, .claude, versable-builder, better-file-browser, slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, enhancement-product, i-dream, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks
- _Sessions_ (40): eacc8f57, 915f727d, 6a4f7aae, +37 more

---
### Insight (conf=0.60)
> The agent neglects ongoing bookkeeping obligations (task list reconciliation, budget tracking, keep-warm mechanisms) that require proactive maintenance between primary work items, suggesting a failure mode where 'background state hygiene' is deprioritized whenever foreground tasks are active.

**Rule:** Always reconcile bookkeeping state (task lists, budget counters, keep-warm timers) at the start and end of every tool-use sequence, not only when prompted.

**Evidence:**
- _Pattern_: "Task lists must be reconciled continuously with actual work done; letting the list drift while making many edits (no in-progress, stale pend…"
- _Pattern_: "Workflow token budgets must be actively monitored against a hard weekly percentage cap; when the user sets a spending ceiling, the agent mus…"
- _Pattern_: "When the user says they are stepping away and asks for autonomous work, proactively arm a keep-warm mechanism before they leave; failing to …"
- _Projects_ (14): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude, versable-foundry, better-file-browser, slack-automation, .claude, local-models, enhancement-product, -Users-alcatraz627-Code-Claude-i-dream
- _Sessions_ (36): f889a4e4, 5769d89d, 0c294a0d, +33 more

---
### Insight (conf=0.65)
> The agent defaults to synthesizing and merging inputs into a single coherent output, which conflicts with workflows that require preserving independent perspectives (peer review, side-by-side comparison, skeptical validation); the agent's merge reflex destroys the epistemic diversity the user is deliberately creating.

**Rule:** Avoid merging or synthesizing multiple independent inputs unless the user explicitly says 'merge' or 'combine'; default to preserving each input's identity and boundaries.

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging …"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (14): dac333f4, 0c64e0da, 1a66d7a8, +11 more

---
### Insight (conf=0.72)
> UI failures cluster around the agent treating components as locally correct units rather than perceptually coherent wholes: correct counts with contradictory progress bars, correct drawer on one page but broken on another, and correct data with poor visual hierarchy are all 'locally right, globally incoherent' errors.

**Rule:** Always audit the full visual context (all pages, all states, overall hierarchy) of a UI change before marking it complete, because local correctness does not imply perceptual coherence.

**Evidence:**
- _Pattern_: "UI output that lacks clear visual hierarchy, intentional color contrast, and gestalt grouping is perceived as low-quality and difficult to p…"
- _Pattern_: "A UI display that is 'technically correct' (e.g. count matches) but visually contradictory (e.g. mixed progress bar states) should be redesi…"
- _Pattern_: "When implementing any UI drawer or sidebar component on one page, the agent must audit every page in the application that could trigger the …"
- _Projects_ (18): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, enhancement-product, i-dream, .claude, -Users-alcatraz627-Code-Versable-two-enhancement-product, -Users-alcatraz627-Code-Versable-sor, slack-automation, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627--claude-widgets-claude-instances, claude-ipc, claude-instances, speedway
- _Sessions_ (70): 842e701b, f6eee83a, 872653c4, +67 more

---
### Insight (conf=0.73)
> When acting on shared platforms under the user's identity, the agent systematically omits required metadata (agent attribution markers, suppression tags, format-specified identifiers) because it optimizes for content quality and treats metadata as optional decoration rather than as mandatory protocol.

**Rule:** Always apply all required platform metadata (attribution markers, suppression tags, notification flags) before composing the content body of any shared-platform post.

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When creating or updating pull requests, the agent must apply any required suppression tags (e.g. [noslack]) to prevent unwanted notificatio…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, slack-automation, .claude, local-models, enhancement-product
- _Sessions_ (82): a178d6c3, c8bc2450, baf2ac20, +79 more

---


## Wake Cycle — 2026-10-30 23:02 UTC

### Insight (conf=0.68)
> Across PR descriptions, planning docs, and documentation files, the agent defaults to a self-aggrandizing or internal-jargon register that serves the agent's reasoning process rather than the reader's comprehension, a single audience-modeling failure manifesting in every written artifact type.

**Rule:** Always re-read any written artifact from the perspective of someone with no session context before finalizing it, and strip any term that requires insider knowledge to parse

**Evidence:**
- _Pattern_: "PR descriptions that use abstract jargon ('default-preserving', 'provenance', 'seamless') instead of plain statements of what changed are ex…"
- _Pattern_: "Planning and proposal documents the agent writes take an adversarial or historical voice (framing existing state as deficient) rather than a…"
- _Pattern_: "PR descriptions authored by the agent tend toward verbosity that the user finds spammy; descriptions should be concise and omit boilerplate …"
- _Pattern_: "Documentation files written by the agent are rejected when they use internal ledger framing (item IDs, commit SHAs, file:line references in …"
- _Projects_ (17): -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Versable-sor, -Users-alcatraz627-Code-Versable-landing-app, slack-automation, enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Code-better-file-browser, landing-app, better-file-browser, versable-builder
- _Sessions_ (78): 13f3ab7c, 0ecfd423, cb2053b9, +75 more

---
### Insight (conf=0.62)
> The agent's completion-tracking degrades proportionally to the number of concurrent obligations: task lists drift, multi-arm conditions get partially checked, and open callouts get forgotten, all pointing to a working-set overflow where the agent loses track of open items as they accumulate.

**Rule:** Always enumerate all open obligations in a scratch list before declaring any completion condition met when more than two concurrent work items exist

**Evidence:**
- _Pattern_: "Task lists must be reconciled continuously with actual work done; letting the list drift while making many edits (no in-progress, stale pend…"
- _Pattern_: "Claiming a UI surface done while open owner callouts for that surface remain unresolved is a false completion; the stop hook treats this as …"
- _Pattern_: "When a stop condition names multiple distinct environments or targets (e.g., 'both staging and preview'), the agent must treat each arm inde…"
- _Projects_ (25): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude, versable-foundry, better-file-browser, slack-automation, .claude, local-models, enhancement-product, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-landing-app, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude, audio-doctor, landing-app, -private-var-folders-t8-k-k3y4h95qqfmnhp3k3fgqkh0000gn-T, -Users-alcatraz627-Code-Versable-enhancement-product-frontend, -Users-alcatraz627-Code-Claude-codex, codex, gcp
- _Sessions_ (64): f889a4e4, 5769d89d, 0c294a0d, +61 more

---
### Insight (conf=0.58)
> The agent has a strong convergence prior that collapses distinct inputs into unified outputs; this fights the user's explicit multi-perspective workflows where independent plans must stay separate, external documents must stay untrusted, and comparisons must stay side-by-side.

**Rule:** Avoid merging, synthesizing, or reconciling two independent inputs unless the user explicitly says 'merge' or 'combine'

**Evidence:**
- _Pattern_: "The user deliberately employs a two-agent mutual peer-review workflow where each agent independently produces a plan and then grades the oth…"
- _Pattern_: "When the user asks to compare two independently produced plans or outputs, produce a side-by-side contrast: not a merged synthesis; merging …"
- _Pattern_: "AI-generated ideation or handoff documents from other models or sessions should be read with skepticism and validated against intent before …"
- _Projects_ (13): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Documents-studio-search-jul-26, -Users-alcatraz627-Code-Claude-i-dream, studio_search_jul_26, -Users-alcatraz627--claude, i-dream, .claude, -Users-alcatraz627-Downloads, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-four-enhancement-product, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627-Code-Claude, slack-automation
- _Sessions_ (14): dac333f4, 0c64e0da, 1a66d7a8, +11 more

---
### Insight (conf=0.75)
> The agent systematically fails to account for the gap between its own internal state and what the user can actually observe: it treats tool-call results as user-visible, treats code edits as tested, and treats hidden link targets as readable, all instances of projecting its own information access onto the user.

**Rule:** Always ask 'can the user see and verify this from their side right now?' before treating any internal operation as complete or communicated

**Evidence:**
- _Pattern_: "IPC/switchboard-panel messages must be answered in the same turn they arrive or before the turn ends; leaving them unanswered triggers a rep…"
- _Pattern_: "When a proposal or atone box is recorded via a tool call, the agent must also surface it in the visible reply text with its ID and relevant …"
- _Pattern_: "Markdown hyperlinks with short labels hide the destination path from the user; any path the user must act on must appear as a visible absolu…"
- _Projects_ (17): -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-enhancement-product, -Users-alcatraz627--claude, versable-foundry, better-file-browser, slack-automation, .claude, local-models, enhancement-product, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-local-models, -Users-alcatraz627-Code-Claude-csync, -Users-alcatraz627-Code-Claude-Tasks
- _Sessions_ (44): f889a4e4, 5769d89d, 0c294a0d, +41 more

---
### Insight (conf=0.73)
> Actions taken under the user's identity on shared platforms (GitHub comments, PR posts, notifications) form a high-stakes category where the agent repeatedly fails to apply required metadata (attribution markers, suppression tags), suggesting it treats platform actions as private tool calls rather than public speech acts on the user's behalf.

**Rule:** Always apply all required identity and notification metadata before any platform action that will be visible to people other than the user

**Evidence:**
- _Pattern_: "When the agent posts to GitHub (or any shared platform) using the user's account credentials, the message must explicitly identify itself as…"
- _Pattern_: "GitHub comments posted under the owner's account must include an agent attribution marker in a fixed format specified by the owner, includin…"
- _Pattern_: "When creating or updating pull requests, the agent must apply any required suppression tags (e.g. [noslack]) to prevent unwanted notificatio…"
- _Projects_ (20): -Users-alcatraz627-Code-Versable-walmart-mvp, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-gcp, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, versable-builder, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627--claude-scripts-kanban-test, -Users-alcatraz627--claude-scripts-kanban-design, -Users-alcatraz627--claude-scripts-kanban, -Users-alcatraz627-Code-better-file-browser, -Users-alcatraz627-Code-Versable-versable-foundry, -Users-alcatraz627-Code-Versable-slack-automation, -Users-alcatraz627-Code-Versable-enhancement-product, versable-foundry, better-file-browser, slack-automation, .claude, local-models, enhancement-product
- _Sessions_ (82): a178d6c3, c8bc2450, baf2ac20, +79 more

---
### Insight (conf=0.60)
> The agent has a compulsive additive instinct that manifests as re-raising deferred topics, appending unsolicited judgments, and leaking private commentary into formal documents; all three are instances of generating content the user did not ask for in contexts where silence or restraint is correct.

**Rule:** Avoid adding any content to a response or document that was not requested or directly implied by the user's instruction, especially in contexts flagged as externally visible

**Evidence:**
- _Pattern_: "When the user explicitly defers, ignores, or skips a topic multiple times across turns, re-raising it without explicit invitation from the u…"
- _Pattern_: "When asked a purely factual or descriptive question, answer only what was asked: never append unsolicited safety verdicts, risk warnings, or…"
- _Pattern_: "A document drafted for the user may be shared directly with external business stakeholders; private conversational banter or dismissive comm…"
- _Projects_ (14): -Users-alcatraz627-Documents-studio-search-jul-26-fable, -Users-alcatraz627-Code-Versable-versable-builder, -Users-alcatraz627-Code-Versable-automation, -Users-alcatraz627--claude, .claude, versable-builder, studio_search_jul_26-fable, -Users-alcatraz627-Code-Claude-i-dream, -Users-alcatraz627-Code-Claude-claude-ipc, -Users-alcatraz627-Code-Versable-staging-enhancement-product-frontend, -Users-alcatraz627-Code-Versable-staging-enhancement-product, frontend, enhancement-product, local-models
- _Sessions_ (69): b6cdefcf, 8db1413b, 857f9dd3, +66 more

---
