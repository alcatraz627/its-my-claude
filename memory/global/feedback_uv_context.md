---
name: Use uv and avoid context overflow
description: User requires uv package manager and warns against loading large files into context
type: feedback
---

Use `uv` package manager instead of pip/pip install for this project.

**Why:** User preference for uv as the default Python package manager.

**How to apply:** Use `uv run`, `uv pip install`, `uv sync` instead of `pip install`. Check for pyproject.toml/uv.lock.

---

Do not load large files or datasets into memory/context. Write scripts to parse or understand data. Only read what is needed.

**Why:** Context overflow has been a problem — conversation ran out of context in a previous session.

**How to apply:** When analyzing data, write a small Python script and run it via Bash. When reading files, use offset/limit params. Never read full YAML data files or large outputs directly into conversation.
