# FP fixture — deliberate ellipsis in prose with inline-code pipes

Expected: atone-lint fires NOTHING (no ellipsis warning). Every `…` below is a
deliberate elision inside flowing prose / inline code, not a truncated table.

The gate reads the wrong `atone.sh add` … then writes a failure marker.

Another prose line: run `head file | tail` … and inspect the result.

The pipe `cmd | jq '.x'` fails when the input is empty, so we guard it … carefully.

A citation with an ID pattern: events are keyed `mist-…` and appended under a lock.

Shell inline code inside a real GFM table cell (must not fire):

| pct  | where            | note                                          |
|------|------------------|-----------------------------------------------|
| 25%  | atone-lint.sh:53 | `slug_count` runs `rg -c … \|\| echo 0`; benign |
