---
name: Test Naming and Generic Test Patterns
description: User prefers generic, reusable tests with specific naming conventions over one-off test files
type: feedback
originSessionId: f7f0db0b-05e4-4b6a-b2db-50cf416260e4
---
User pushed back on test naming conventions and wanted tests made more generic (session 0467461b: "naming convention tests different instead", "enhance make generic").

**Why:** A test was written with a specific naming style the user didn't prefer, and the test was too narrow/specific when it should be reusable.

**How to apply:** When writing tests, ask about or follow the project's existing naming convention (check the test folder README if present). Prefer parameterized/generic test structures over copy-pasted specific tests. When the user says "make it generic", extract repeated patterns into shared helpers or parameterized test cases.
