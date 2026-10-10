# /tasks project-identity: scenarios exercised by identity.test.sh

One line per scenario. `[core]` marks the i-dream/gcc identity mix-up this fix
exists for. `[edge]` marks a related breakage the same machinery can produce.
Each line is tagged with the invariant(s) it targets from
`~/.claude/assets/reports/20260922-tasks-identity-fix/contract.md`.

- [core] I1: `task.sh add --project <path>` records `metadata.project` verbatim on the row.
- [core] I1: `task.sh add` with no `--project` defaults `metadata.project` to the CWD's git root.
- [core] I5: an explicit `--project` row and a CWD-default row carry a distinguishing marker. Some `metadata.*project*` key differs between them, so a reader can tell a declared attribution from an inferred one.
- [core] I2: `task.sh update <id>` run from a different repo's CWD does not relabel an existing row's `metadata.project`.
- [edge] I2: `task.sh start <id>` run from a different repo's CWD does not relabel it either. The drift check is not specific to one subcommand.
- [core] I3: `task-table.sh --project A` returns A's row and excludes B's, in a store holding both.
- [core] I3: `task-table.sh --project B` returns B's row and excludes A's, in the same store.
- [core] I3: the disjoint union of `--project A` and `--project B` covers every row actually planted for A and B. No row is lost between the two filtered views.
- [core] I3: `--project <basename>` (for example `i-dream`) matches the same rows as `--project <full path>`.
- [core] I4: a store stamped with A (`.project`) that also holds a B-attributed row renders a loud mismatch line in the human table.
- [edge] I4: the same mismatch is also detectable in `--json` output, not only the human render, so machine callers are not blind to it.
- [core] I6: a hand-crafted row with no `metadata.project` field at all (the pre-fix shape) still appears in the unfiltered render.
- [core] I6: that legacy row is found by `--project <store's own .project stamp>`, the fallback I6 specifies.
- [edge] I6: a lone legacy row consistent with its store's stamp does not itself trip the I4 conflict guard. No false alarm on ordinary pre-fix stores.
- [edge]: a row filed through a symlinked CWD resolves `metadata.project` to the real, symlink-resolved repo root, not the symlink path.
- [edge]: that symlink resolution is stable across two separate `add` calls through the same link. No drift call to call.
- [edge]: a row filed from deep inside a repo (`repo/a/b/c`) resolves to the repo's toplevel, not the subdirectory.
- [edge] I3: a row filed with CWD equal to `~/.claude` never leaks into another project's `--project` filter. The config dir is not "a project".
- [edge] I3: that `~/.claude`-filed row is still findable by filtering on its own true recorded project value. It is not lost, just never falsely attributed elsewhere.
- [edge] I1: a repo path containing spaces and non-ASCII characters round-trips through `metadata.project` byte for byte.
- [edge] I3: `--project` filtering works with a path argument containing spaces and unicode.
- [edge] I3: `--project app` does not sweep in `app-v2`'s row. No accidental substring match.
- [edge] I3: `--project app-v2` does not sweep in `app`'s row. Checked both directions of the collision.
- [edge]: two `task.sh add` calls from different project CWDs, launched concurrently into the same store, both leave valid JSON. The per-store lock holds under a race, not just under serial calls.
- [edge]: under that same race, neither row is lost. Both ids land.
- [edge]: under that same race, neither row is cross-attributed to the other writer's project.
- [edge] I3: `--project` against an empty store exits cleanly (0), not an error.
- [edge] I3: `--project <path that matches nothing in this store>` returns zero rows rather than silently falling back to the unfiltered store.
- [canary]: the pre-fix baseline render (no `--project` at all) still runs, so a red result above is the invariant failing, not a broken sandbox.

## Seeds from the contract not turned into a separate line

These are covered incidentally by the scenarios above rather than as their
own line. Noted here so nothing from the contract's seed list got silently
dropped.

- "Cross-cutting write: create a gcc task from an i-dream CWD." The I4
  scenario above is this shape generalized, with A and B standing in for
  i-dream and gcc. A literal `~/.claude`-domain-vs-repo-domain version is the
  I3 `~/.claude` scenario.
- "Empty and mixed stores." Both the empty-store case and the mixed A/B store
  case are exercised directly.
