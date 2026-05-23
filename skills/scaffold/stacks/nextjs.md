# Next.js 15 — App Router + TypeScript + Tailwind

## Meta
- Runtime: node
- Default port: 3010
- Install command: npm install
- Run command: npm run dev
- Test command: npx vitest run

## Dependencies
next: ^15
react: ^19
react-dom: ^19

## Dev Dependencies
typescript: ^5.7
@types/node: ^22
@types/react: ^19
@types/react-dom: ^19
tailwindcss: ^4
@tailwindcss/postcss: ^4
postcss: ^8
vitest: ^3
@vitejs/plugin-react: latest
eslint: ^9
eslint-config-next: ^15
prettier: ^3

## Files

### package.json
```json
{
  "name": "{{name}}",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev --port {{port}}",
    "build": "next build",
    "start": "next start --port {{port}}",
    "lint": "next lint",
    "test": "vitest run",
    "test:watch": "vitest",
    "typecheck": "tsc --noEmit"
  }
}
```

### next.config.ts
```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Enable React strict mode for catching common bugs
  reactStrictMode: true,
};

export default nextConfig;
```

### tsconfig.json
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

### postcss.config.mjs
```javascript
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};

export default config;
```

### src/app/globals.css
```css
@import "tailwindcss";
```

### src/app/layout.tsx
```tsx
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "{{name}}",
  description: "Built with Next.js",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-white text-slate-900 antialiased">
        {children}
      </body>
    </html>
  );
}
```

### src/app/page.tsx
```tsx
export default function Home() {
  return (
    <main className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="text-4xl font-bold tracking-tight">{{name}}</h1>
      <p className="mt-4 text-lg text-slate-600">
        Edit <code className="rounded bg-slate-100 px-1.5 py-0.5 text-sm font-mono">src/app/page.tsx</code> to get started.
      </p>
    </main>
  );
}
```

### src/app/api/health/route.ts
```typescript
import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({
    status: "ok",
    timestamp: new Date().toISOString(),
  });
}
```

### src/lib/utils.ts
```typescript
import { type ClassValue, clsx } from "clsx";

/**
 * Merge Tailwind classes safely. Add `clsx` and `tailwind-merge` as needed.
 * Placeholder — replace with your preferred class merging utility.
 */
export function cn(...inputs: ClassValue[]) {
  return clsx(inputs);
}
```

### .env.example
```bash
# App
NEXT_PUBLIC_APP_URL=http://localhost:{{port}}

# Database (if needed)
# DATABASE_URL=postgresql://user:pass@localhost:5432/{{name}}

# Auth (if needed)
# NEXTAUTH_SECRET=generate-a-secret-here
# NEXTAUTH_URL=http://localhost:{{port}}
```

### .gitignore
```
node_modules/
.next/
out/
dist/
.env
.env.local
.env.*.local
*.tsbuildinfo
next-env.d.ts
.vercel
.turbo
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

[*.md]
trim_trailing_whitespace = false
```

### vitest.config.ts
```typescript
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    globals: true,
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});
```

### src/__tests__/health.test.ts
```typescript
import { describe, it, expect } from "vitest";
import { GET } from "@/app/api/health/route";

describe("GET /api/health", () => {
  it("returns ok status", async () => {
    const response = await GET();
    const body = await response.json();
    expect(body.status).toBe("ok");
    expect(body.timestamp).toBeDefined();
  });
});
```
