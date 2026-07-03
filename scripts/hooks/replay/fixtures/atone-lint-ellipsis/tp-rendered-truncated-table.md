# TP fixture — a TTY-rendered/truncated table saved as source

Expected: atone-lint FIRES the ellipsis warning on the truncated rows. These are
fixed-width space-padded columns with `…` sitting at a cell-truncation boundary —
the signature of gum/glow output pasted as source instead of markdown.

Scenario          | Native Supp… | Behavior          | Citation
Backoff retry     | Partial …    | resumes on 429    | docs/limits.md
Idle warm keep    | Full support | keeps model warm… | lm-warm.sh:22
