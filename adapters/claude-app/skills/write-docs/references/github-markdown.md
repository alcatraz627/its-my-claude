# GitHub markdown: what renders and what does not

Behaviors that each cost a review round before anyone knew them.

| What happens | How it shows | What to do |
|---|---|---|
| A callout (`> [!NOTE]`) inside `<details>` renders as a plain quote | The callout box vanishes in a collapsed section | Inside `<details>`, use a bold line and a list instead |
| A link to a file on the PR branch 404s until merge when it targets `main` | Reviewers click dead links in the PR body | Link to the head commit (`/blob/<sha>/path`) for files the PR adds or moves |
| A long table with inline links balloons the body | A 50-row table reached 39k characters | Define reference links once at the foot (`[r1]: https://...`). The same table fell to 24k |
| Raw `<svg>` pasted into markdown | Many renderers outside github.com show the `<text>` nodes as loose words | Commit the SVG as a file and reference it with `<img src="...">` |
| A relative link written from the wrong folder | Works in the editor preview, 404s on GitHub | Write links relative to the file that holds them, then check each target exists |
| Anchor links after a heading rename | `[see quotas](#quota-checks)` silently goes nowhere | Search the doc for the old anchor after every rename |

## Anchors

GitHub builds a heading's anchor by lowercasing it, dropping punctuation
except hyphens, and replacing spaces with hyphens. `## Quota checks (v2)`
becomes `#quota-checks-v2`. A repeated heading gets `-1`, `-2` appended.

## Callouts

Five kinds: `NOTE`, `TIP`, `IMPORTANT`, `WARNING`, `CAUTION`. The marker sits
alone on the first line of the quote:

```markdown
> [!WARNING]
> Running the migration twice duplicates every invoice line.
```

One callout per page is the useful budget. A page of callouts trains the
reader to skip all of them.

## Collapsible sections

```markdown
<details>
<summary>Full error output</summary>

Leave a blank line after the summary, or the markdown inside will not render.

</details>
```

## Tables

- Cells hold phrases. Past about twelve words, the content wants a section.
- A pipe inside a cell needs escaping as `\|`, including inside inline code.
- Keep tables under about eight columns. Wider ones wrap badly on narrow
  screens and in Google Docs.

## Mermaid

GitHub renders fenced `mermaid` blocks in issues, PRs, READMEs and wikis. See
`diagrams` for when to use one and when box-drawing is the better choice.
