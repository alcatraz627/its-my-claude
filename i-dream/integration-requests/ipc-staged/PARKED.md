# ipc domain — parked 2026-07-13 (process-audit phase 2)

Moved out of the live `~/.claude/i-dream/domains/` directory because its event
stream (`~/.claude-ipc/i-dream-events.jsonl`) has been 0 bytes since creation:
`extract-events.sh` has never emitted a single event, so the domain was
registered live while contributing nothing (census finding #4, 2026-07-12).

Re-promote by moving `ipc.toml` back into `~/.claude/i-dream/domains/` once the
extractor demonstrably writes events. The activation gate that claude-audit's
ACTIVATION.md defines applies here too: real events first, promotion second.
