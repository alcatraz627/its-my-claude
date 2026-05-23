---
name: Always test with small sample before full run
description: MANDATORY — test every transform/script on 2-3 rows before running on full data, verify output types and serialization
type: feedback
---

Always test transforms and pipelines on a small sample (2-3 rows) before running on full data.

**Why:** Skipping this caused `[object Object]` in Excel exports — arrays of objects were passed to `.join('\n')` which calls `.toString()`. Also caused Excel cell overflow (>32K chars). The JSON data was fine but the xlsx export path was broken. Would have been caught immediately with a 2-row test + readback.

**How to apply:** After writing any new transform or modifying io/export code:
1. Run with `--limit 3` or a small test array
2. Inspect every field in the output — check types, not just row counts
3. For file exports: read the file back and verify cell contents
4. Only then run on full data
