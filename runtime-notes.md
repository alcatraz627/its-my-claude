# Claude Runtime Notes

## session: Interactive inputs showcase constraints & demo results — demo-inpu-42 — 2026-04-06

**Purpose:** Test the interactive inputs MCP showcase end-to-end; identify UI constraint violations and document workarounds for future projects.

**Insights:**

1. **4-option hard cap on AskUserQuestion** — Both `pick_one` and `pick_many` max out at 4 choices. When you need more options (e.g., 5 features), use `form` with individual boolean toggles or split into related groups. The original showcase Example B had 5 features — fixed to 4 and documented overflow pattern.

2. **Custom escape hatch pattern works naturally** — When bounded input is needed but user might want unlisted values, adding a "Custom/Other" option that triggers a follow-up `text_input` felt intuitive in the demo. User selected "Custom" and typed `5084` for port without friction.

3. **Always demo interactive flows before shipping** — Examples that look good on paper break on contact with real UI constraints. The showcase had documented examples that violated the 4-option limit. Recommendation: run a real demo of any interactive-input flow before distributing the prompt, then update constraints docs based on findings.

4. **Composition pattern holds up** — Sequential multi-step flow (text → dropdown → checkboxes → number → confirm) kept user engaged; each answer informed the next step. No UI friction or confusion when properly scoped (each question max 4 options).

5. **AskUserQuestion as fallback is sufficient for demoing** — While the real `mcp__inputs__*` tools weren't available, AskUserQuestion demonstrated the interaction model and constraint patterns clearly. Useful for quick validation before setting up the full MCP.

---
