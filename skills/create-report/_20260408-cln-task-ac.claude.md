# Quick Summary (for LLMs) — 2026-04-08T00:00:00Z

> This session completed the three remaining cleanup items from the prior `fix-tmpl-ab` session. The dead `?t=Date.now()` cache-busting suffix was removed from the tsx import in `generate-html.ts` (line 1373). The EISDIR bug in `--all-styles` mode was fixed by computing a `baseDir` that handles both directory-path and filename-path invocations. Orphaned `.report-toolbar` and `.mini-toolbar` CSS blocks were removed from `academic/style.css`, `corporate/style.css`, and `minimal/style.css` (226 lines removed total). The HTTP server on port 8774 (PID 7600) was killed. All tasks are complete — no pending items remain from either session.

# Core Dump — 2026-04-08T00:00:00Z

## Initial Goal

Complete the remaining cleanup tasks left over from the prior `fix-tmpl-ab` session:
1. Kill the HTTP verification server on port 8774
2. Remove dead cache-busting code in `generate-html.ts`
3. Fix EISDIR error in `--all-styles` mode
4. Remove orphaned `.report-toolbar` / `.mini-toolbar` CSS from academic, corporate, and minimal style files

## Agent Actions

1. Ran parallel investigation: `lsof -i :8774` (confirmed PID 7600 still running), grepped `generate-html.ts` for `writeFileSync` and `await import(templatePath`, identified EISDIR source and cache-busting line.
2. Read `generate-html.ts:1365-1410` — confirmed dead suffix `"?t=" + Date.now()` at line 1373; tsx strips query strings from local imports so this was always a no-op.
3. Read `generate-html.ts:1440-1507` — understood the full `allStylesMode` block: `outputDir = dirname(resolvedOutput)` assumption breaks when `resolvedOutput` is a bare directory path (no `.html` suffix), causing `writeFileSync(resolvedOutput, ...)` to hit EISDIR.
4. Read `generate-html.ts:994-1043` (`renderFloatingToolbar`) — confirmed injected toolbar uses `class="floating-toolbar"`, `class="ftb-btn"`, `#theme-btn`, `#print-btn` — zero overlap with `.report-toolbar` / `.theme-toggle` / `.print-btn` classes in template CSS files.
5. Grepped all 4 style CSS files for `report-toolbar` / `mini-toolbar` — found orphaned blocks in academic (lines 701-752), corporate (lines 645-703), minimal (lines 588-686), plus scattered references in media queries and print styles. Dashboard was clean.
6. Read `academic/style.css:698-860`, `corporate/style.css:642-760`, `minimal/style.css:583-750` to determine exact removal boundaries.
7. **Fixed `generate-html.ts:1373`** — removed `"?t=" + Date.now()` suffix from `await import(templatePath)`.
8. **Fixed `generate-html.ts` allStylesMode block** — added `baseDir` computation: if `resolvedOutput` ends in `.html`, use `outputDir` (dirname); otherwise treat `resolvedOutput` itself as the output directory. All style subdirs and launcher write now use `baseDir` instead of `outputDir`/`resolvedOutput` directly.
9. **Removed orphaned CSS from `academic/style.css`** — deleted `/* --- Floating Toolbar */` block + Width Picker sub-rules (lines 701-752), `.report-toolbar {}` in 768px media query, `.report-toolbar .width-picker` in 480px media query, `.report-toolbar,` from print styles selector list.
10. **Removed orphaned CSS from `corporate/style.css`** — deleted `/* ─── Floating Toolbar */` block + Width Picker sub-rules (lines 645-703), `.report-toolbar,` from print styles.
11. **Removed orphaned CSS from `minimal/style.css`** — deleted entire `/* ─── Floating mini-toolbar */` section (~98 lines, all `.mini-toolbar` rules), `.mini-toolbar .width-picker` from 640px media query, `.mini-toolbar,` from print styles.
12. Killed PID 7600 — port 8774 server confirmed gone.
13. Verified: grep for `report-toolbar` / `mini-toolbar` across all 3 style CSS files returns zero matches.
14. Verified: `generate-html.ts` grep confirms `baseDir` at line 1476, no `Date.now()` remaining.

## Current Expectation

All cleanup tasks are complete. The user invoked `/core-dump` — they are archiving session state and may `/clear` or continue with other work.

## Pending Items

- None. All items from the prior `fix-tmpl-ab` session and this session are resolved.

## Session Insights

**What worked well:**
- Parallel investigation (lsof + grep + read simultaneously) resolved all reconnaissance in one round trip
- Reading `renderFloatingToolbar` HTML output to confirm class names before deciding which CSS is truly orphaned — prevented accidentally removing CSS that the injected toolbar still uses
- The `baseDir` fix is backward-compatible: when called with `/path/to/index.html` (the normal SKILL invocation), behavior is identical to before; only the edge case of a bare directory path is now handled

**What didn't work:**
- Nothing notable this session — all edits were surgical and verified immediately

**Gotchas encountered:**
- Dashboard had zero orphaned CSS — prior session had already cleaned it or it never had the old toolbar styles. Only academic, corporate, minimal needed cleanup.
- The `.theme-toggle`, `.print-btn`, `.width-picker`, `.width-btn` standalone rules (without `.report-toolbar` prefix) are technically orphaned too (injected toolbar uses `#theme-btn.ftb-btn`, not `.theme-toggle`), but they were left in place since they're harmless and the task scope was `.report-toolbar`/`.mini-toolbar` blocks specifically
- In `minimal/style.css` the `.mini-toolbar,` in print styles was part of a multi-selector list — only that one line needed removing, keeping `.toc-bar,` and `dialog#code-dialog,` intact

**Notes for future agents:**
- `generate-html.ts` allStylesMode now accepts either `/path/to/output/index.html` OR `/path/to/output/` as the output target — the `baseDir` logic at line 1476 handles both
- The `?t=Date.now()` cache-busting trick for tsx imports has never worked — tsx strips query strings from local file imports. If module caching becomes a problem again, the only working fix is running each template as a separate `npx tsx` process
- Line counts post-cleanup: academic 853, corporate 750, minimal 757

**User feedback received:**
- Session started from a compacted/resumed context — user asked to proceed with remaining tasks without preamble. No corrections this session.

---

_Generated by /core-dump. Resume with /catchup._
