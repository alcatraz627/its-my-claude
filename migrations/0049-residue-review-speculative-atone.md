# 0049: the residue review and the speculative-atone loop

**Date:** 2026-08-20
**Type:** new subsystem (scheduled auditor + ledger + two hooks) + decision-page wake fix
**Sessions:** valid-docx-7a

## What changed

1. **Speculative-atone ledger**: `~/.claude/atone/speculative.jsonl`, surface
   `scripts/atone-speculative.sh` (add / pending / confirm / refute / stats).
   Confirm requires a real `mist-` id in the kernel-locked ledger; refute requires
   40+ chars of cited evidence; burst-safe unique ids; space-tolerant id matching.
2. **Residue review runner**: `~/Code/Claude/i-dream/scripts/residue-review.sh`
   (i-dream family per ruling D3a): per active session (heartbeat peers, deduped by
   sessionId, cap 5), transcript window since last run capped at the day, one
   headless subscription opus spawn each (i-dream's flags: --print, key env removed,
   cwd /tmp), findings filed as speculative atones + one ipc per session (service
   identity residue-review). Proven live on this session: 10 nominations filed,
   ipc delivered.
3. **Enforcement**: `scripts/hooks/speculative-atone-hint.sh` (UserPromptSubmit,
   re-injects pending rows every turn, escalates at 5) +
   `speculative-atone-stop.sh` (Stop; blocks turn-ends once per nag level past 5).
   Registered in settings.json. Mutes: `.no-spec-atone-hint`, `.no-spec-atone-gate`.
   Proven: hinter fired live (nag 1 fixture, nag 2 real), gate blocked at n=5 and
   stayed loop-safe.
4. **Schedule**: gcc-schedule job `residue-review`, daily 23:00 with a Mon-Fri
   guard in the command, plist `com.alcatraz.residue-review` + Automations calendar
   companion (scheduling-discipline).
5. **Decision-page wake fixed** (owner-corrected 2x, S3 mist-20260819-232855-dc):
   `pending add` prints the exact run_in_background watcher command (proven to wake
   the session on submit); `server.py` registers `dp-server --service` at boot and
   pushes via claude-ipc on submit (proven delivered).

## Why

Owner rulings spec-atone D1-D7 + notes (D4 a+ipc, D7 opus high), 2026-08-20;
PLAN + rulings verbatim: `assets/reports/20260820-speculative-atone/PLAN.md`.

## Jurisdiction expansion (framed, not shipped)

ipc residue, skill-usage outcomes, subagent dispatch hygiene: one auditor prompt
file each behind the same runner. Not built until the atone domain proves out.
