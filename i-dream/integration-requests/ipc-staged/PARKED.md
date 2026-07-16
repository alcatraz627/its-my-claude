# ipc domain — parked 2026-07-13 (process-audit phase 2)

Moved out of the live `~/.claude/i-dream/domains/` directory because its event
stream (`~/.claude-ipc/i-dream-events.jsonl`) has been 0 bytes since creation:
`extract-events.sh` has never emitted a single event, so the domain was
registered live while contributing nothing (census finding #4, 2026-07-12).

Re-promote by moving `ipc.toml` back into `~/.claude/i-dream/domains/` once the
extractor demonstrably writes events. The activation gate that claude-audit's
ACTIVATION.md defines applies here too: real events first, promotion second.

---

## RE-PROMOTED 2026-07-16 (session catch-audit-7f)

Gate satisfied: the hardened `~/.claude-ipc/extract-events.sh` wrote 132 events
in one exercised run (all valid JSONL, zero hidden/empty bodies), and its
failure path was proven to leave the store untouched (exit 127 with the CLI
absent, store checksum unchanged, no temp leftovers).

Why it had been empty, per the claude-ipc maintainer (msg-5ef258877b304503) and
our own forensics: the original one-liner piped `claude-ipc log` with stderr
discarded, so a failing/absent verb yielded a silent 0-byte store; and two
CLI-side traps persisted into 2026-07 (party-scoped body redaction since
02dddca needs `--operator`; piped output >~64KB truncates mid-JSON until their
flush fix deploys — bounded with `--since` and file capture, never a pipe).

Canonical manifest now lives at `~/.claude/i-dream/domains/ipc.toml` with a LIVE
header; `ipc.toml` here remains the historical staging artifact
(claude-audit precedent).
