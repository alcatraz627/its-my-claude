# /clean-html — Usage Guide

## What it does

Strips HTML markup and converts to clean, readable markdown while downloading embedded media (images, videos, PDFs) and removing UI clutter. Outputs a folder with markdown, media files, and metadata.

## Usage

```
/clean-html <source> [--output <name>]
```

| Argument          | Type     | Description                                                                            |
| ----------------- | -------- | -------------------------------------------------------------------------------------- |
| `<source>`        | required | HTML input: file path (`./page.html`), URL (`https://example.com`), or raw HTML string |
| `--output <name>` | optional | Custom output folder name; defaults to source filename                                 |

## Examples

### Example 1: Clean a local HTML file

```
/clean-html article.html
```

Creates `article/` folder with:

- `article/index.md` — cleaned markdown
- `article/media/` — any embedded images, PDFs, videos
- `article/metadata.json` — source info and download log

### Example 2: Fetch and clean a remote page

```
/clean-html https://example.com/blog/post
```

Fetches the page, creates `example.com-blog-post/` folder, downloads all linked media, outputs cleaned markdown.

### Example 3: Clean raw HTML with custom output name

```
/clean-html "<html><body><h1>Title</h1><p>Content...</p></body></html>" --output my-doc
```

Creates `my-doc/` folder with cleaned markdown and any embedded media.

## Caveats

- **Never modifies the original HTML file** — read-only only
- **Output folder isolated** in current working directory — all files stay together
- **Media downloads can fail** gracefully — failed URLs are logged in `metadata.json` but don't block the run
- **Requires clean_html.ts script** to exist at `.claude/skills/clean-html/clean_html.ts`
- **If HTML is convoluted,** the agent may fall back to manual cleanup instead of using the script
- **JavaScript and CSS imports are excluded** — only media and document links are downloaded

## Dependencies

| Dependency    | Type              | Notes                                                                     |
| ------------- | ----------------- | ------------------------------------------------------------------------- |
| GUIDELINES.md | Shared rules      | Read at start of every run                                                |
| clean_html.ts | TypeScript script | Must exist at `.claude/skills/clean-html/clean_html.ts` and be executable |
| WebFetch      | Tool              | Fetches remote URLs and downloads media                                   |
| Read          | Tool              | Reads local HTML files                                                    |
| Write         | Tool              | Creates output folder and markdown files                                  |
| Bash          | Tool              | Runs `mkdir`, `curl` for downloads, `ls` for verification                 |

## Tips

- Use `/clean-html <source>` to quickly convert any HTML to markdown
- Chain with `/create-report` to turn the cleaned markdown into a polished HTML report
- Check `metadata.json` to see which media files were downloaded and any failures
- Output folder contains everything needed — archive the folder to preserve the cleaned content
