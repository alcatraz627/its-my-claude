# Static HTML / CSS / JS with Live Reload

## Meta
- Runtime: node (for dev server only)
- Default port: 3040
- Install command: npm install
- Run command: npm run dev
- Test command: (none — open index.html in browser)

## Dev Dependencies
live-server: ^1.2

## Files

### package.json
```json
{
  "name": "{{name}}",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "npx live-server --port={{port}} --no-browser",
    "format": "npx prettier --write '**/*.{html,css,js}'"
  }
}
```

### index.html
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>{{name}}</title>
  <link rel="stylesheet" href="styles/main.css" />
</head>
<body>
  <main class="container">
    <h1>{{name}}</h1>
    <p>Edit <code>index.html</code> to get started.</p>
  </main>
  <script src="scripts/main.js"></script>
</body>
</html>
```

### styles/main.css
```css
*,
*::before,
*::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
  font-size: 16px;
  line-height: 1.6;
  color: #1e293b;
  background: #ffffff;
}

.container {
  max-width: 720px;
  margin: 0 auto;
  padding: 4rem 1.5rem;
}

h1 {
  font-size: 2.5rem;
  font-weight: 700;
  letter-spacing: -0.02em;
}

p {
  margin-top: 1rem;
  color: #475569;
}

code {
  font-family: "SF Mono", "Fira Code", Consolas, monospace;
  font-size: 0.875em;
  background: #f1f5f9;
  padding: 2px 6px;
  border-radius: 3px;
}
```

### scripts/main.js
```javascript
// Entry point — add your JavaScript here.
console.log("{{name}} loaded");
```

### .gitignore
```
node_modules/
.env
.DS_Store
```

### .editorconfig
```ini
root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true
```
