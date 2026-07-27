<!-- i-dream project brief · 2026-07-26T20:23:55.946655+00:00 · 20 patterns / 7 insights -->
## What this project is about
versable-builder is a product-building UI platform with shared shell components (sidebar, drawer, modal), paginated list pages, design-mock-driven labels, and multi-agent IPC coordination. Work runs in high-velocity autonomous sessions with significant parallelism.

## Things to do (or keep doing)
- Always read design mocks before implementing any UI element name, label, or structure — internal naming conventions are not the authority here
- Audit ALL pages sharing a component before writing any code; apply fixes simultaneously across every user of the component
- Exercise every fix on the actual running dev server before declaring it done — code inspection is not verification
- Increase task-list sync frequency during parallel or burst work, not decrease it; anchor sync after every completed logical unit

## Things to avoid
- Don't treat agent-authored summaries, gap analyses, or derivative docs as ground truth — trace every authority claim back to running code, user spec, or actual output
- Don't convert absent data into a definite answer (zero, false, ALLOW); emit UNCERTAIN or DENY when a lookup returns empty
- Don't route through the user what the agent can resolve autonomously; when deferral is needed, include the prior decision context plus ≥2 concrete options
- Don't confirm an IPC message delivered from send-side logs alone — a round-trip reply is required

## Open questions / known gaps
- Design mock consultation is repeatedly skipped despite being a stated authority; needs to be the literal first action before any UI naming or labeling work
- No stable rhythm for state-sync during high-parallelism bursts; git state, task lists, and peer ownership regularly drift under velocity
