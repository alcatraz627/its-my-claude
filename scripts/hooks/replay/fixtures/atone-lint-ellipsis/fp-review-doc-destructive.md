# FP fixture (R3) — a review doc that quotes destructive UI code

Path contains "review" (matches the R3 glob) and the body quotes `onClick` plus
destructive verbs (delete/remove/revert). Expected: atone-lint fires NOTHING —
a markdown findings report describes UI code without being an interactive
surface. The R3 destructive-action nudge must be scoped off `.md`/`.txt`/`.mdx`.

The panel exposes a delete button:

```tsx
<Button onClick={() => remove(job.id)}>Delete</Button>
```

We should verify the precondition: the revert action must be hidden, not just
runtime-guarded, when the job list is empty.
