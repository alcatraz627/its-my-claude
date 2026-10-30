# Categorical bug classes

Each class earned its place because the user complained about it after every
test had passed. Each entry gives what it looks like, why tests miss it, and
the check that catches it. Run the checks on the real UI. The console snippets
go in the browser devtools console on the user's page, or inside an artifact
you built.

## 1. Transparent floating layer

- **Looks like**: a dropdown, popover, tooltip or menu whose text mixes with
  the content behind it.
- **Tests miss it** because "the menu opens" passes, and a screenshot at rest
  never shows the overlap.
- **Check**: open the layer over content and screenshot it. Every floating
  panel needs a non-transparent `background-color` and a border or shadow.

```js
[...document.querySelectorAll('[role=menu],[role=listbox],[role=dialog],[role=tooltip]')]
  .map(e => [e, getComputedStyle(e).backgroundColor, getComputedStyle(e).boxShadow])
```

## 2. Sibling controls at mismatched scale

- **Looks like**: a select beside a button, or two inputs in one row, at
  different font sizes, heights or border colors.
- **Tests miss it** because each control works on its own.
- **Check**: read computed styles of neighbours and compare. A mismatch is a
  finding, not a preference.

```js
[...document.querySelectorAll('button,input,select')]
  .map(e => { const s = getComputedStyle(e);
    return [e, s.fontSize, s.height, s.borderColor, s.color, s.backgroundColor]; })
```

## 3. Height chain with no definite ancestor

- **Looks like**: the whole page scrolls when a table or panel was meant to
  scroll inside a fixed frame.
- **Tests miss it** because all content is present and reachable.
- **Check**: compare `scrollHeight` with `clientHeight` on the page, the card
  and the intended scroller. A `height: 100%` chain needs a definite ancestor
  height. `min-height: 100vh` makes every child resolve to content size.

```js
[document.scrollingElement, ...document.querySelectorAll('main,section,[class*=scroll]')]
  .map(e => [e, e.scrollHeight, e.clientHeight])
```

## 4. Action with no feedback

- **Looks like**: the user clicks save or delete and nothing visible happens.
- **Tests miss it** because the data changed correctly.
- **Check**: every action that changes data shows a toast or inline state on
  start, on success and on error. Read the handler for all three paths.

## 5. Ghost fade where a skeleton belongs

- **Looks like**: the whole screen dims or fades while one region loads.
- **Tests miss it** because the data arrives.
- **Check**: each region that loads data renders its own skeleton at real
  sizes. A global opacity change on the shell is a finding.

## 6. Low contrast

- **Looks like**: grey text on a grey surface, readable only on a good monitor.
- **Tests miss it** because the text is in the DOM.
- **Check**: compute the ratio for every new text and background pair. Below
  4.5:1 for body text is a finding even when the user picked the colors. Say
  so once, then it is their call.

## 7. Raw identifiers where a name exists

- **Looks like**: a UUID, database key or slug shown where a human name is
  available.
- **Tests miss it** because the value is correct.
- **Check**: scan the rendered text for id-shaped strings and ask whether a
  name exists for each.

## 8. Silent truncation

- **Looks like**: a cell or label cut off with an ellipsis, hiding the part
  that differs between rows.
- **Tests miss it** because the element renders.
- **Check**: `scrollWidth > clientWidth` on a text element means it is cut.
  Decide whether that was intended or whether the text had to fit.

```js
[...document.querySelectorAll('td,th,label,span')]
  .filter(e => e.scrollWidth > e.clientWidth).map(e => [e, e.textContent])
```

## 9. Em-dashes in UI copy

- **Looks like**: an em-dash in a label, tooltip or message, which reads as
  generated text.
- **Check**: search the rendered text and the source strings for the em-dash
  character (U+2014). Restructure each sentence with a period, colon or comma.
