---
name: No speculative output descriptions in agents
description: When spawning agents that produce files (e.g. via /create-report), instruct them not to describe the visual design or content of the output — only return the file path. Prevents hallucinated descriptions of what was generated.
type: feedback
---

When spawning agents that invoke skills producing files (like /create-report), do NOT let the agent describe what the output looks like. Agents confabulate visual details (color schemes, layout choices) that don't match the actual deterministic output.

**Why:** In a batch of 22 /create-report agents, every agent described unique color palettes and layouts, but the skill uses a fixed TypeScript template — all reports share the same visual chrome. The agent self-reports were hallucinated.

**How to apply:** Append to agent prompts: "Do not describe the visual design or layout of the output. Only return the output file path and confirm success or failure." This applies to any agent that produces files via a skill or script where the agent doesn't control the visual output.
