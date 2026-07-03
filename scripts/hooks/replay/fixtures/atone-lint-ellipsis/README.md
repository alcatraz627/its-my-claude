# atone-lint ellipsis / destructive-doc fixtures

These are **content fixtures** (not transcript fixtures): each `.md` is fed to
`atone-lint.sh --file <fixture>` and the outcome is asserted. The hook under test
is the shared `atone-lint.sh` catalog, invoked live by both
`hooks/guard-cluster-e-smells.sh` (PreToolUse) and `hooks/review-gate-stop.sh`
(Stop).

| fixture                            | rule | class | expected                                   |
|------------------------------------|------|-------|--------------------------------------------|
| `fp-prose-pipe-ellipsis.md`        | R7   | FP    | silent — `…` in prose / inline-code pipes  |
| `fp-review-doc-destructive.md`     | R3   | FP    | silent — a doc quoting destructive UI code |
| `tp-rendered-truncated-table.md`   | R7   | TP    | fires — `…` at fixed-width cell boundaries  |

Run:

```bash
LINT=~/.claude/scripts/atone-lint.sh
for f in fp-prose-pipe-ellipsis fp-review-doc-destructive; do
  out=$(bash "$LINT" --file "$f.md")
  [ -z "$out" ] && echo "PASS silent  $f" || echo "FAIL fired   $f"
done
out=$(bash "$LINT" --file tp-rendered-truncated-table.md)
printf '%s' "$out" | rg -q 'fixed-width table-cell' && echo "PASS fires   tp" || echo "FAIL silent  tp"
```

Corpus anchor for the TP class (a real rendered-table-saved-as-source in the
account history): `assets/reports/20260531-tui-autocontinue/cc-native-ratelimit.md:342`.
