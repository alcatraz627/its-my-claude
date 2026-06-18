---
name: autocorrect
description: Manage the autocorrect typo-correction dictionaries — view/edit mappings, review correction logs, teach new corrections, and check stats. Use to inspect or tune the autocorrect hinter that runs on every prompt.
user-invokable: true
---

# /autocorrect — Manage Typo Correction Dictionaries

## Brief

Manage the autocorrect pipeline: view/edit dictionaries, review correction logs, teach new mappings, and check stats. The autocorrect system runs as a hinter (`~/.claude/hinters/00-autocorrect.sh`) on every user prompt via the hint-injector hook.

## Usage

```
/autocorrect [subcommand] [args]
```

| Subcommand | Description |
|---|---|
| `/autocorrect` | Show current stats (fire rate, top corrections, dict sizes) |
| `/autocorrect list [dict]` | Show dictionary contents: `custom-terms`, `typo-map`, or `blacklist` |
| `/autocorrect add <word>` | Add to custom-terms.txt (word is valid, never correct it) |
| `/autocorrect teach <wrong>=<right>` | Add `wrong -> right` to typo-map.txt |
| `/autocorrect remove <word>` | Remove from whichever dictionary contains it |
| `/autocorrect ignore <word>` | Add to blacklist.txt (never propose corrections for this) |
| `/autocorrect log [N]` | Show last N correction events from the log (default: 20) |
| `/autocorrect undo [N]` | Mark last N corrections as wrong, add originals to blacklist |
| `/autocorrect test <sentence>` | Run autocorrect on a test sentence without logging |
| `/autocorrect stats` | Full stats: corrections/day, top words, false-positive rate |

## Step 0: Load Shared Guidelines

Read `~/.claude/skills/GUIDELINES.md`. Apply all rules for the duration of this skill run.

## Phase 1 — Parse Subcommand

Parse the args string. If no subcommand or empty args, default to `stats`.

## Phase 2 — Execute

### `list [dict]`

Read and display the contents of the specified dictionary file from `~/.claude/assets/autocorrect/`:

| Dict | File | Format |
|---|---|---|
| `custom-terms` | `custom-terms.txt` | One word per line (known-good terms) |
| `typo-map` | `typo-map.txt` | `wrong -> right` per line |
| `blacklist` | `blacklist.txt` | One word per line (never correct) |

If no dict specified, show a summary of all three: entry count and last 5 entries each.

### `add <word>`

1. Check the word isn't already in custom-terms.txt
2. Append the word (lowercase) to `~/.claude/assets/autocorrect/custom-terms.txt`
3. Sort the file alphabetically
4. Confirm: `Added "<word>" to custom-terms (N total entries)`

### `teach <wrong>=<right>`

1. Parse `wrong=right` from the argument (accept `=` or `->` as separator)
2. Check the mapping doesn't already exist in typo-map.txt
3. Append `wrong -> right` to `~/.claude/assets/autocorrect/typo-map.txt`
4. Sort the file alphabetically
5. Confirm: `Taught: "<wrong>" → "<right>" (N total mappings)`

### `remove <word>`

1. Search all three dictionary files for the word
2. Remove matching lines
3. Report which file(s) were modified

### `ignore <word>`

1. Append the word to `~/.claude/assets/autocorrect/blacklist.txt`
2. Also remove from typo-map.txt if it appears as a correction target
3. Confirm: `Ignored "<word>" — will never be corrected (N blacklisted)`

### `log [N]`

1. Read `~/.claude/.autocorrect-log.jsonl`
2. Show the last N entries (default 20) in a table: timestamp, original, corrected, layer, session
3. Use `gum table` for formatting

### `undo [N]`

1. Read the last N entries from the log
2. For each: add the original word to blacklist.txt
3. Confirm: `Undone N corrections. Added to blacklist: word1, word2, ...`

### `test <sentence>`

1. Run: `echo "<sentence>" | bash ~/.claude/hinters/00-autocorrect.sh`
2. Display the output (or "No corrections found")
3. Do NOT write to the log

### `stats` (default)

1. Read `~/.claude/.autocorrect-log.jsonl`
2. Compute and display:
   - Total corrections logged
   - Unique words corrected
   - Top 10 most-corrected words
   - Corrections per day (last 7 days)
   - Dictionary sizes (custom-terms, typo-map, blacklist)
3. Use `gum table` for the top-words table

## Phase 3 — Completion

Print a one-line status and offer related actions:

```
Options: list, add <word>, teach <a>=<b>, ignore <word>, log, test <sentence>
```

## Notes

- Dictionary files are plain text, one entry per line, `#` comments supported
- The autocorrect hinter runs as part of the hint-injector pipeline on every UserPromptSubmit
- Corrections are additive (injected as additionalContext), never rewrite the prompt
- Log file: `~/.claude/.autocorrect-log.jsonl` — JSONL with ts, sid, orig, corrected, layer, accepted fields
- Latency budget: <50ms total for the hinter (currently ~34ms including Python startup)
