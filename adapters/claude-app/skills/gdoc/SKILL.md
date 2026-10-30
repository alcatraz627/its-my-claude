---
name: gdoc
description: Publishes markdown as a Google Doc in a Drive folder through the Google Drive connector, for readers who do not read markdown. Shows the target first, writes on a yes, reads it back.
---

# Google Doc publish

Turns markdown (pasted, uploaded, or written in this chat) into a Google Doc
in a Drive folder the user picks, so people who do not read markdown can
open, comment on and share it. The markdown stays the source of truth.
Content flows one way, markdown to Doc.

## When to use

- "Put this in a Google Doc", "publish these docs to Drive", "share this with
  people who do not use GitHub"
- Re-publishing a doc set that changed since the last publish

Not for editing an existing Google Doc by hand, or for a doc that will live
and be edited in Drive from now on. For that, write it in Drive directly.

If the Google Drive connector is not connected in this chat, say so and
hand back the cleaned markdown for the user to import by hand.

## What the connector can and cannot do

Say this to the user plainly the first time it matters.

| Need | With the Drive connector | Fallback |
|---|---|---|
| Create a Doc from markdown | Yes. Upload the markdown as text with a markdown content type and let Drive convert it to a Google Doc | none needed |
| Put it in a folder | Yes, by folder id | none needed |
| Rename, move, lock read-only, share | Yes | none needed |
| Replace the body of an existing Doc, keeping its link | No. The Drive connector updates a file's details, not its content | See "Re-publishing" below |
| One tab per markdown file | No. Tabs need the Docs API | One Doc with each file as a top-level section, or one Doc per file in the folder |
| House styling (table fills, code boxes, fonts) | No. The Doc gets Drive's default conversion | Accept the default look, or style by hand in Docs |
| Mermaid diagrams as images | No image insert | Render the diagram in the sandbox, upload the PNG to the same folder, and link it where the diagram was |

If this chat also has a tool that edits Google Doc content directly (a Docs
connector, or a Google Workspace skill with edit access), use it for the
rows marked No, and say which tool did the work.

## The run

### 1. Prepare the markdown

- Strip frontmatter and HTML comments. Drive shows them as text.
- For several files, pick the layout with the user once: one Doc with each
  file under its own top-level heading and a contents list first (the
  default), or one Doc per file plus a short index Doc that links them.
- Links between the files become links to headings in the single Doc, or to
  the other Docs. Fix them after the first publish, once the targets exist.
- Mermaid blocks follow the fallback in the table above.

### 2. Confirm the target, every run

Show one block and ask for a yes:

```
Publish   "Design notes v3"   (3 files, single Doc, 412 lines)
Folder    Team docs / Design  (link)
Mode      new Doc  |  re-publish over "Design notes v2" (link)
Account   the Google account the connector is signed in as
```

Silence is not a yes. A folder the user did not name is a stop, not a guess.

### 3. Publish

Create the Doc in the folder with the prepared markdown. Then read its
content back through the connector and compare: every heading present,
tables intact, no raw markup showing. A block that converted wrong is
reported with what it looks like, not hidden.

### 4. Report

The Doc link, the folder link, and anything that did not survive conversion.

## Re-publishing and the stable link

The Drive connector cannot rewrite an existing Doc's body, so a plain
re-publish makes a new Doc with a new link. To keep one link people can
bookmark:

1. **Share the folder link as the stable link.** The folder always holds the
   current version.
2. Publish the new version into the folder under the plain title.
3. With the user's go-ahead, rename the old Doc to `[Superseded] <title>`,
   lock it read-only, and set its description to the new Doc's link. Anyone
   with an old link sees at once where to go.
4. Move the old Doc to trash only if the user asks. It stays restorable for
   30 days.

Before overwriting, check whether the old Doc has comments or edits made in
Drive. Those are lost to readers of the new version. Name them and ask
whether to carry them into the markdown first.

## Boundaries

- Nothing is written to Drive without the target block and a yes.
- Never share a Doc more widely than the folder already is, unless the user
  asks for that share by name.
- Never trash or delete without the user naming the file.
- Never claim the Doc looks right without reading it back.
