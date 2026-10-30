# Escapes in JS emitted from a template literal

When server code emits JavaScript from inside a backtick template literal (a
Node `renderPage()` returning HTML with an inline `<script>`), every escape
sequence in that JS is consumed by the server-side template before the
browser sees it.

## What happens

```javascript
function renderPage() {
  return `
    <script>
      const k = '\n';       // the template turns \n into a real newline
    </script>
  `;
}
```

The browser receives:

```javascript
const k = '
';                          // unterminated string: SyntaxError
```

One SyntaxError stops the whole script, so every interactive control on the
page dies: the theme toggle, the nav, every button. One line, total damage.

## Why the usual checks miss it

The server file is valid JS, because the template is just a string, so a
syntax check of it passes. Only the substituted output is broken, and no
server-side check ever sees that. Fetching the page and searching the HTML
misses it too. The bug appears only when the browser runs the script.

## The rule

1. **Double every escape** inside the template:
   - `\\n` reaches the browser as `\n`
   - `\\'` reaches it as `\'`
   - `\\\\` reaches it as `\\`
   - `\\${` reaches it as `\${`
2. **Better:** move the script to a static `.js` file loaded with
   `<script src="...">`. Then ordinary syntax checks cover it.
3. **Required:** before calling the page ready, open it in a real browser and
   click something. A fetch or a test run does not count.

## Diagnostic

"The buttons stopped working" or "SyntaxError on line N" in the console, and
the last file edited is a renderer with a `<script>` block inside a backtick
string.
