# 0061: svc stops services a person is not using

`svc` used to treat any new connection as use, with one 12-hour limit for every
service. A health check kept a service up forever, and a person on a kept-alive
connection could read as idle. Now only evidence of a person counts, each service
can have its own limit, and dedicated work takes an expiring hold. The policy table
is in `features/dev-servers.md`.

## What changed

- `scripts/dev-servers/svc-sample.py` traces each connection to the program that made
  it and decides use from that. The default limit is 2 hours (`--idle-min`).
  `--idle-hours` and `SVC_IDLE_HOURS` are gone; `SVC_IDLE_MIN` replaces them.
- `scripts/dev-servers/svc-holds.py` is new and writes holds and per-service policy.
- `svc` gains `hold`, `release`, `touch` and `policy`. `svc status` gains limit, last
  use and reason columns.
- New state in `~/.claude/dev-servers/`: `svc-policy.json`, `svc-holds.json` and the
  `svc-touch/` folder. `svc-never-reap` still works.
- Starting a service now counts by pm2's own start time. A service revived soon after
  a reap used to be reaped again on the next pass, because the start was never seen.
- bfb reports the active local tab's port through its notes host (`svc_seen`), which
  needs the `alarms` and `idle` permissions and an extension reload.

## Rollback

Restore the two scripts from git. The new state files are ignored by the old code.

## Verification

`python3 scripts/tests/test-svc-policy.py`, and in bfb `node e2e/svc-seen-walk.mjs`.
A live run on a throwaway pm2 app confirmed polling did not keep it up, that a touch
and a hold did, and that the polling check fails when the rule is deliberately broken.
