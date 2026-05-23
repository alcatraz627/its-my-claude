---
name: Node.js require() Cache Clearing
description: Always clear require.cache before re-loading config or transform files in the pipeline engine — cached modules ignore file edits
type: feedback
---

Clear require.cache before loading run.config.js and transform files in the pipeline engine.

**Why:** Node.js caches modules on first require(). When users edit configs or transforms and re-run, the engine loads the old cached version. This is invisible — no error, no warning, just stale behavior. The engine (pipeline/engine.js lines 47-49, 117-120) already does `delete require.cache[require.resolve(path)]` before loading.

**How to apply:** Any new code that dynamically loads JS files via require() in the pipeline must clear the cache first. This applies to run configs, transform files, and any future plugin system. If switching to ESM import(), use `import(path + '?t=' + Date.now())` cache-busting instead.
