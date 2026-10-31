# Agent-first tools

When the primary user of a tool is an AI agent (a CLI another session drives,
a daemon an agent queries, a debug bridge for agent-led work), that user has no
eyes and no patience problem. It is blind but fast, mechanical but diligent,
pays an attention cost for every byte of output, and needs the next step
offered in every response. Design for that user.

Where this comes from: a rebuild of a browser-driving tool for agents. Mining
205 real invocations of the first version found that 18% of calls died on
ambiguity errors that offered no fix, agents inserted 106 manual sleeps, and
28 screenshots were the only way to observe state. The principles below
answer those numbers.

## Five obligations: each agent handicap becomes a tool duty

| Agent property | Tool obligation |
|---|---|
| Blind but fast | Every action returns a compact state delta. Observing never costs a second call. |
| Mechanical but diligent | Waits, retries and verification live inside actions, not in the agent's judgment. |
| Pays for attention | Budget every output: scope, truncate, paginate, rank. Heavy payloads go to files. |
| Needs next-step discovery | Every response carries affordances. Errors propose the fix (candidates, hints). |
| Expresses ambiguity while blind | Accept intent, return ranked candidates in one round trip. Never "narrow it" without the list. |

## Fifteen principles

1. Observe as structured semantic text. Screenshot only to verify.
2. Mint short refs in observations. Actions take refs, never raw selectors.
3. Staleness is an explicit contract: a dead ref says so and says what to do.
4. Budget every observation. A 114K-token page snapshot is the canonical
   failure.
5. Every action returns a post-action delta: what changed because of it.
6. Never return silence. Confirm empty results explicitly.
7. Errors propose the fix: ranked candidates, the exact next command.
8. Reject invalid input at submit time. Do not repair it afterwards.
9. Wait automatically inside every action, with a tiny named wait vocabulary.
   No agent sleeps.
10. Offer framework-level settledness (network and queries idle), not
    "this text appeared" proxies.
11. Ship composite actions for known multi-step patterns.
12. Macros are first-class: authored once in plain language, resolution
    cached, replay deterministic.
13. Fuzzy targeting returns ranked candidates from deterministic tiers, never
    open-ended generation.
14. One actor per shared surface. Serialize mutations or the deltas corrupt.
15. Journal everything, failures included. The journal seeds macros and
    after-the-fact debugging.

## Worked example: an error that proposes the fix

Bad, and the agent is stuck:

```
error: selector "Save" matched 3 elements
```

Good, and the agent's next call is obvious:

```
ambiguous: "Save" matched 3 elements
  e12  button "Save"         in dialog "Edit profile"   (visible, enabled)
  e31  button "Save draft"   in toolbar                 (visible, enabled)
  e47  menuitem "Save as…"   in menu "File"             (hidden)
next: click e12   or   click "Save" --within "Edit profile"
```

## Lessons the research did not predict

- **Do not assume the target describes itself.** Principle 1 assumes the app
  has structured semantics (roles, labels, text). Low-accessibility apps
  defeat every semantic lookup and the tool degrades to a useless component
  name. Fall through to structural inference, and when that is ambiguous too,
  hand the agent the raw evidence (icon, handler source, nearby text), never a
  dead label.
- **The framework holds what the page does not.** In a React app a control's
  label often lives in a component prop, not in the DOM: a closed dropdown's
  items, an unrendered tooltip's text. A conditional render gates mounting,
  not the value's existence, so that content is readable from the trigger's
  ancestor props with no interaction. Read the framework's state for meaning,
  not only the DOM.
- **Honest unknowns beat fabricated calm.** When observation is impossible
  (the document died mid-read), report `unknown`, never a value that implies
  nothing happened.
- **The tool's own instrumentation must not pollute its telemetry.** Minting
  refs tripped the mutation observer and produced false activity signals.
- **Identity needs a generation tag.** Same-named things across page reloads
  silently alias without one.
- **Test through the real entry path** (CLI, then daemon, then browser). That
  review found four signal corruptions that type checks and unit tests could
  not see.

## When this applies

Building or reworking any tool an agent drives: local CLIs, daemons, MCP
servers, debug bridges. Human-first tools follow `tui-design.md` and
`cli-design.md` instead. When one tool serves both, design the machine surface
first and render the human view from it.
