# Vite + React + TypeScript + Tailwind

## Meta
- Runtime: node
- Default port: 3020
- Install command: npm install
- Run command: npm run dev
- Test command: npx vitest run

## Dependencies
react: ^19
react-dom: ^19
react-router: ^7

## Dev Dependencies
typescript: ^5.7
@types/react: ^19
@types/react-dom: ^19
@vitejs/plugin-react: ^4
vite: ^6
tailwindcss: ^4
@tailwindcss/vite: ^4
vitest: ^3
jsdom: ^26
eslint: ^9
prettier: ^3

## Files

### package.json
```json
{
  "name": "{{name}}",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite --port {{port}}",
    "build": "tsc -b && vite build",
    "preview": "vite preview --port {{port}}",
    "lint": "eslint src/",
    "test": "vitest run",
    "test:watch": "vitest",
    "typecheck": "tsc --noEmit"
  }
}
```

### vite.config.ts
```typescript
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import path from "path";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});
```

### tsconfig.json
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2023", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "skipLibCheck": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"]
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
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

### src/main.tsx
```tsx
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import "./index.css";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
```

### src/index.css
```css
@import "tailwindcss";
```

### src/App.tsx
```tsx
export function App() {
  return (
    <main className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="text-4xl font-bold tracking-tight">{{name}}</h1>
      <p className="mt-4 text-lg text-slate-600">
        Edit <code className="rounded bg-slate-100 px-1.5 py-0.5 text-sm font-mono">src/App.tsx</code> to get started.
      </p>
    </main>
  );
}
```

### src/__tests__/App.test.tsx
```tsx
import { describe, it, expect } from "vitest";
import { render, screen } from "@testing-library/react";
import { App } from "../App";

describe("App", () => {
  it("renders heading", () => {
    render(<App />);
    expect(screen.getByRole("heading", { level: 1 })).toBeDefined();
  });
});
```

### .env.example
```bash
VITE_APP_TITLE={{name}}
# VITE_API_URL=http://localhost:5020
```

### .gitignore
```
node_modules/
dist/
.env
.env.local
*.tsbuildinfo
coverage/
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
