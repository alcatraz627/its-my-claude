# Orchestration contract — how the dispatching agent runs `--depth thorough`

The deterministic phases live in `scripts/`. The LLM phases are dispatched by the
calling agent via the Agent tool. This file is the contract that agent follows.

## Phase sequence

```
1. discover        scripts/depth-runner.sh discover <source-spec>
2. chunk           scripts/depth-runner.sh chunk
3. slice           scripts/depth-runner.sh slice <range> [--include-worktree]
4. select-chunks   scripts/depth-runner.sh select-chunks <all|N|range>
5. inventory       FAN-OUT: one general-purpose sub-agent per selected chunk
6. normalize       scripts/depth-runner.sh normalize inventory/
7. verify-coverage scripts/depth-runner.sh verify-coverage
8. themes          one sub-agent (phases/themes.md)
9. validate-shas   scripts/depth-runner.sh validate-shas themes/THEMES.md 01-commits.tsv
10. verify         one opus sub-agent (phases/verify.md + charters/<name>.md)
11. incorporate    one sub-agent (phases/incorporate.md)
12. synthesize     FAN-OUT: one opus sub-agent per audience (parallel)
```

## Dispatch rules (non-negotiable)

1. **Inventory sub-agents are `general-purpose`, NOT `Explore`.** Explore has a
   restricted tool set and hallucinates write-refusals. (W2)
2. **Every sub-agent prompt names an absolute output path + "write before
   returning".** Verify the file exists before consuming. (per `rules/sub-agent-outputs.md`)
3. **Synthesize is N parallel calls — one per audience.** Never one call for all
   audiences (output-token blowout + uneven quality).

## Failure handling (W4 — mid-flow adaptation)

After EACH fan-out phase (inventory, synthesize), inspect every sub-agent's return
abstract for failure markers before proceeding:

| Marker in return text | Meaning | Action |
|---|---|---|
| "cannot write", "safety restriction", "unable to save" | Agent refused (usually Explore) | **Retry once as general-purpose.** If it refuses again, save the inline content manually + flag. |
| "could not read", "file not found", "no such file" | Bad input path | Check the path; re-dispatch with corrected path. |
| empty return / timeout | Agent died | Retry once with a halved chunk (split the chunk's file list in two). |
| return without the expected "wrote X" confirmation | Possible silent failure | Verify the output file exists with `test -f`; if missing, retry. |

After retry exhaustion (1 retry per chunk), mark the chunk `_failed` in a note and
**continue** — the themes phase sees the gap via `verify-coverage`. Do NOT abort the
whole run for one bad chunk.

If >25% of inventory chunks fail, STOP and surface to the user — something systemic
is wrong (rate limit, bad diff slicing, model outage).

## Coverage budget (W3)

`select-chunks` controls how many chunks get inventoried:
- `all` — every semantic chunk (full fidelity; most expensive)
- `<N>` — first N by diff size (largest-first; good cost/coverage tradeoff)
- `<range>` — explicit, e.g. `1-10,15,20-25`

When subsetting, **annotate the byte-coverage % in `themes/THEMES.md` top-of-doc** so
readers know what was skipped. The themes prompt expects this note.

## Progress (W7)

Each `depth-runner.sh` phase appends to `_progress.log`. For fan-out phases, the
dispatching agent should print a one-line status after the batch returns
("inventory: 13/14 ok, 1 retried"). `_progress.log` + `inventory/_coverage.json`
together are the run's audit trail.

## Per-repo config (W5)

If the repo root has a `.discover-excludes` file, `apply-filters.py` reads it
automatically (one glob per line). Use this for docs-as-code repos that want
`docs/**` excluded, or any repo-specific noise. Document the trade-off to the user
on first run: the global default does NOT exclude docs.
