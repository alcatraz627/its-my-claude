# Renderer probe, every construct at once

This exists to be looked at. The `/doc` CSS changed on 2026-08-25 and the
caveat ledger asked for a re-check against the renderer, which had itself
gained tables and images since the CSS was last judged.

Ordinary paragraph text, long enough to show the measure and the line height
working together, because a measure that is right for one line is right for
none. The rag should sit comfortably and the eye should find the next line
without hunting for it.

## A second-level heading

Its rule should sit close under the words, and the space above it should be
clearly larger than the space below, so this paragraph reads as belonging to
the heading rather than floating between two of them.

### A third level

**Bold text**, *italic text*, ~~struck through~~, and `inline code` in a
sentence, plus a bare URL like https://example.com/some/path to check the
autolinker.

#### A fourth level

##### A fifth

###### And a sixth

## Lists

- First item, short.
- Second item, deliberately long so it wraps and shows whether the hanging
  indent lines up under the text rather than under the marker.
- Third item with `code` and **bold** inside it.
  - A nested item.
  - Another nested item.
    - And a third level of nesting.
- Back to the top level.

1. An ordered item.
2. A second one.
3. A third, with a nested unordered list:
   - inner one
   - inner two

## A table

| Construct | Should look like | Notes |
|---|---|---|
| Heading | more space above than below | h2 carries a rule |
| Table | header shaded, rows striped | scrolls alone if wide |
| Code | one visual language | inline and block agree |
| Quote | a left rule, quieter text | never a box |

## A wide table, which must scroll inside itself and never widen the page

| Column one is long | Column two is also long | Column three | Column four | Column five | Column six |
|---|---|---|---|---|---|
| a value here | another value here | more content | and more | and yet more | the last one |

## A quote

> A block quote, which should read as quieter than body text and carry a left
> rule rather than a box.
>
> With a second paragraph inside it.

## Code

```javascript
function example(a, b) {
  // a fenced block, which should not wrap and should scroll if it is long enough to need to
  const result = a.map((x) => x * b).filter(Boolean);
  return result.length ? result : null;
}
```

    An indented code block, the older syntax.

## A horizontal rule follows

---

And text after it, to show the spacing the rule earns on both sides.

## An image with nowhere to resolve from

![a relative image](./nonexistent.png)

## Links

An [inline link](https://example.com) and a [link with `code`](https://example.com)
inside the label.
