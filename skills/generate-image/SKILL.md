---
name: generate-image
description: Generates raster images from a text prompt using the LOCAL imagine model (mflux/MLX Flux on Apple Silicon — $0, offline, no cloud). Uses only models already cached on this machine (qwen is the kept default; ~3–8 min per image, stated up front), NEVER downloads a model without explicit confirmation, drives the backend headlessly, reads the result back to actually look at it, and offers the real refine/vary/redo iteration loop. Use when the user wants a photo, texture, painterly image, concept art, a cover image, or any raster (non-vector) graphic. For icons/logos/diagrams/vector art use /svg instead.
allowed-tools: Read, Bash, Write
argument-hint: "[image prompt] [--model qwen (default; use a CACHED model)] [--style ...]"
user-invocable: true
---

## Brief

A thin, honest wrapper around the local `imagine` CLI (mflux/MLX Flux — local GPU,
$0, offline). `imagine` returns no JSON on the generate path and is meant for a human
at a TTY; this skill supplies the missing agent-facing structure (pin the output path,
run headless, check the exit code, read the JSONL history tail) and the judgment
(which model, surfacing the qwen latency tradeoff, reading the image back before
declaring done, offering the native iteration verbs instead of regenerating blind).

There is **no cloud image-gen** in this account, by design — `imagine` is the only
backend (`rules/model-tier-routing.md`: imagegen → local, $0). If `imagine` is
missing, this skill fails loud rather than inventing a cloud call.

## Step 0 — Guidelines + backend check

Read `~/.claude/skills/GUIDELINES.md` and apply it for the run.

```bash
command -v imagine || { echo "imagine not on PATH — the local image-gen backend (~/Code/local-models) is unavailable on this machine. No cloud fallback exists by design. Stopping."; exit 1; }
```
If missing, stop with that message. Do NOT attempt a cloud/API image call — none is
configured, and inventing one violates both model-tier routing and the no-speculative-
backend doctrine.

## Phase 1 — Intent + model choice (use a CACHED model; NEVER download without asking)

**Use only models already on disk. A cold model means a multi-GB download — that is a
STOP-and-ask, never an autonomous action.** (This account prunes image models to
reclaim space and keeps only the good ones; schnell was deliberately removed as not
good enough. Do not resurrect a pruned model to "be thorough.")

First, see what's actually cached — that is your model menu:
```bash
ls ~/.cache/huggingface/hub/ | rg -i 'flux|qwen|stable'   # the models you may use freely
```

| Model | Status on this account | Use |
|---|---|---|
| **qwen** (Qwen-Image) | **kept — the default** | the preferred local model; strong overall + legible in-image text. ~3–8 min per image; that wait is expected, say so up front |
| FLUX.1-dev ControlNet (Canny) | kept | edge/structure-guided generation |
| schnell / flux2 / dev(base) | **removed / not cached** | do NOT default to these and do NOT download them without explicit confirmation — schnell was purged as inadequate |

Default to **qwen** (the model the user keeps). Tell the user the ~3–8 min wait before
running — it's inherent to the good local model, not a fault. Map style words to
`--style` presets (`photo | cinematic | anime | watercolor | 3d | cyberpunk`). Offer
`--enhance` for a thin prompt (local Ollama; silent fallback to the raw idea if down).

**If the user asks for a model that isn't cached: STOP and ask.** A download is ~10–24GB
and many minutes — a resource commitment only the user authorizes. Never launch it as a
verification/"just to be sure" step (the mistake that graduated this rule —
`bash ~/.claude/scripts/atone.sh search unconfirmed-download`).
```bash
model_dir=~/.cache/huggingface/hub/models--Qwen--Qwen-Image   # map requested model → its HF dir
if [ ! -d "$model_dir" ] || ls "$model_dir"/blobs/*.incomplete >/dev/null 2>&1; then
  echo "'$model' isn't cached — using it means a ~GB download. NOT doing that without your OK. Use a cached model (see the ls above), or confirm the download."; exit 0
fi
```

Map any style words to `--style` presets rather than hand-writing suffixes:
`photo | cinematic | anime | watercolor | 3d | cyberpunk`. Offer `--enhance` (gemma4
rewrites a terse idea into a rich prompt) when the prompt is thin — note it depends on
the local Ollama server and silently falls back to the raw idea if that's down.

## Phase 2 — Generate (the one driving command)

Pin the output path, always pass `--no-open` (don't rely on TTY auto-detect — one
flag, removes all doubt), and check the exit code:

```bash
OUT="$HOME/.claude/assets/images/gen-$(date +%s).png"   # or <project>/assets/ in a project
imagine -m <model> [-s STEPS] [--style NAME] [--seed N] -o "$OUT" --no-open "<prompt>"
rc=$?
```
Resolve `$OUT` to a project's `assets/` when in a project; use `~/.claude/assets/images/`
globally (never a relative path under `~/.claude` — the `.claude/.claude` nest is
hook-blocked). On `rc != 0`, read the printed `FAILED` section back to the user — do
not retry blind.

## Phase 3 — Confirm the output (trust the file + JSONL, not stdout)

```bash
test -f "$OUT" || { echo "imagine exited $rc but produced no file at $OUT"; }
tail -n1 ~/Code/local-models/outputs/imagine-history.jsonl
```
The JSONL tail is the authoritative record (`seed`, `steps`, `ms`, `model`, `output`,
the entry's history number) — read it rather than scraping the colored stdout. Note
the history line number **N** (the count of lines in that file) for the iteration
verbs below.

## Phase 4 — Show the result (render-before-judge)

`Read` the PNG (the Read tool renders it inline) and actually look at it before
declaring success — did it match the intent? This is the same render-before-judge
rule as `/svg`: a generated file that exists is not a verified good image.

## Phase 5 — Offer the iteration loop (don't just stop)

On feedback, use `imagine`'s native verbs against the history entry **N** from Phase 3
instead of regenerating from scratch (which loses the seed and the lineage):

- "warmer light" / "less clutter" / any directed tweak → `imagine refine N "<delta>"` (seed-locked, small change)
- "show me another take" → `imagine vary N` (fresh seed, same prompt/model)
- "that one was right, redo it" → `imagine redo N` (exact re-run)
- "start from this image" → `imagine --from <path> --strength 0.5 "<prompt>"` (img2img; whole-image only — NO region/mask editing exists, say so if asked to change just one part)

Each iteration re-runs Phase 3 + 4 (confirm + look). Surface these verbs proactively;
don't make the user ask how to change it.

## Phase 6 — Optional local critique (self-check, non-blocking)

Before declaring done on something high-stakes, optionally run a local vision critique
against the stated goal:

```bash
imagine critique "$OUT" "<what it was supposed to be>"
```
Returns a gemma4-vision report (what it is / does it match / what's wrong / fixes).
It depends on the local Ollama server (240s cap); if the result is literally
`(no response)`, treat it as "critique unavailable," not an empty critique — never
block completion on it.

## Phase 7 — Completion block

```
What was done:   <one line — what was generated>
Files created:   <absolute path to the .png>
Model / seed:    <model · seed>   (seed = how to reproduce exactly)
Time:            <ms from the JSONL, humanized>
Looked at it:    <yes — matches intent | issues noted>
Critique:        <ran | skipped | unavailable>
```

## Notes

- **Local-only, $0, offline** — this is the `imagine` lane of `rules/model-tier-routing.md`.
  No cloud path exists or should be added; the backend check in Step 0 is the single
  point of failure and it fails loud.
- **qwen is the default because it's the model this account KEPT** — schnell was
  pruned as not good enough. Use a cached model; state the ~3–8 min wait up front so
  it doesn't read as broken. Never download a model to "test" or "be thorough" —
  that's a confirmed, user-authorized action only.
- **`imagine` already tracks history + seeds + a gallery** (`imagine gallery` →
  `outputs/index.html`, dark/light toggle built in). Don't reinvent history tracking
  in the skill — read the JSONL, use the verbs.
- **Companion:** `/svg` for vector/geometric/logo/icon/diagram work. Photographic /
  painterly / textured → here; crisp geometric / scalable → `/svg`.
- **Post-run:** prepend a runtime-notes entry via `prepend-runtime-note.sh` if the run
  surfaced anything reusable (a model that nailed a hard prompt, a style preset combo).

## See Also

- `~/.claude/features/local-models.md` — the full local suite (`imagine`/`warm`/`see`/`q`)
- `~/.claude/rules/model-tier-routing.md` — imagegen → local, $0, no cloud
- `~/.claude/skills/svg/SKILL.md` — the vector companion
- `~/Code/local-models/outputs/imagine-history.jsonl` — the authoritative generation record
