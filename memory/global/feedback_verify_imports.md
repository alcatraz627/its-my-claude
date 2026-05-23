---
name: feedback_verify_imports
description: Always check import sites and actual usage before reporting audit findings — reading component definitions in isolation leads to false positives
type: feedback
---

Always verify that a component/function is actually used before including it in an audit finding. Check import sites, not just definitions.

**Why:** In the arch-qa audit, `AppQueryClientProvider` was flagged as causing double hydration, but it was commented out at its only import site (dead code). Similarly, `/_info` routes were flagged as unauthenticated, but they sit under admin paths that the proxy already protects. Reading files in isolation without tracing how they're wired leads to false positives.

**How to apply:** For any audit or architecture analysis, always grep for import/usage sites of the component or function being analyzed. If usage is commented out, it's dead code — flag it as dead code, not a bug. For auth-related findings, trace the full request path (proxy → route handler → function) before claiming something is unprotected.
