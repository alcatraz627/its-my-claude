<!-- i-dream project brief · 2026-05-13T12:17:48.319838+00:00 · 6 patterns / 10 insights -->
## What this project is about
A Downloads directory used as a general-purpose scratchpad — mixed one-off tasks, tooling experiments, and agent infrastructure work. Sessions tend to be exploratory with occasional multi-phase shipments.

## Things to do (or keep doing)
- Write WAL entries as JSONL (`scripts/wal/wal.sh`) — markdown format is legacy fallback only
- Decompose umbrella requests into sequential sub-tasks; surface progress at each checkpoint before moving on
- Commit after each logical phase/shipment unit; push every 2–3 commits — never batch multiple phases into one commit
- Wait for monitor completion events on long background tasks; do not poll or assume done

## Things to avoid
- Don't ship nav/sidebar expanded by default — user expects collapsed with hamburger toggle; confirm UI state before marking UI tasks complete
- Don't create new persistence files in markdown when JSONL is available — prefer structured, machine-queryable formats from the start
- Don't batch phases into one commit or defer commits until "everything is done"

## Open questions / known gaps
- Pattern extraction pipeline has a deduplication gap: high-salience events (like the WAL migration) appear as 4+ redundant patterns; deduplication logic should run before surfacing insights
