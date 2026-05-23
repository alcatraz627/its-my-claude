# Turborepo Monorepo — Next.js App + Shared UI Package

## Meta
- Runtime: node
- Default port: 3030
- Install command: npm install
- Run command: npm run dev
- Test command: npm run test

## Dependencies
(managed per-workspace)

## Dev Dependencies
turbo: ^2

## Files

### package.json
```json
{
  "name": "{{name}}",
  "private": true,
  "workspaces": ["apps/*", "packages/*"],
  "scripts": {
    "dev": "turbo dev",
    "build": "turbo build",
    "lint": "turbo lint",
    "test": "turbo test",
    "typecheck": "turbo typecheck"
  },
  "devDependencies": {
    "turbo": "^2"
  }
}
```

### turbo.json
```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "dist/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {},
    "test": {},
    "typecheck": {}
  }
}
```

### apps/web/package.json
```json
{
  "name": "@{{name}}/web",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev --port {{port}}",
    "build": "next build",
    "start": "next start --port {{port}}",
    "lint": "next lint",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "next": "^15",
    "react": "^19",
    "react-dom": "^19",
    "@{{name}}/ui": "*"
  },
  "devDependencies": {
    "typescript": "^5.7",
    "@types/react": "^19",
    "@types/react-dom": "^19"
  }
}
```

### apps/web/next.config.ts
```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  transpilePackages: ["@{{name}}/ui"],
};

export default nextConfig;
```

### apps/web/tsconfig.json
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "strict": true,
    "noEmit": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

### apps/web/src/app/layout.tsx
```tsx
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "{{name}}",
  description: "Monorepo web app",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

### apps/web/src/app/page.tsx
```tsx
import { Button } from "@{{name}}/ui";

export default function Home() {
  return (
    <main style={{ maxWidth: 720, margin: "0 auto", padding: "4rem 1.5rem" }}>
      <h1>{{name}}</h1>
      <p>Monorepo web app using shared UI package.</p>
      <Button>Shared Button</Button>
    </main>
  );
}
```

### packages/ui/package.json
```json
{
  "name": "@{{name}}/ui",
  "version": "0.1.0",
  "main": "./src/index.ts",
  "types": "./src/index.ts",
  "exports": {
    ".": "./src/index.ts"
  },
  "scripts": {
    "typecheck": "tsc --noEmit"
  },
  "devDependencies": {
    "typescript": "^5.7",
    "@types/react": "^19"
  },
  "peerDependencies": {
    "react": "^19"
  }
}
```

### packages/ui/tsconfig.json
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "strict": true,
    "noEmit": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx"
  },
  "include": ["src"]
}
```

### packages/ui/src/index.ts
```typescript
export { Button } from "./Button";
```

### packages/ui/src/Button.tsx
```tsx
import type { ButtonHTMLAttributes } from "react";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary";
}

export function Button({ variant = "primary", children, ...props }: ButtonProps) {
  const styles = {
    primary: { background: "#2563eb", color: "white", border: "none" },
    secondary: { background: "transparent", color: "#2563eb", border: "1px solid #2563eb" },
  };

  return (
    <button
      style={{
        ...styles[variant],
        padding: "8px 16px",
        borderRadius: 6,
        fontWeight: 500,
        cursor: "pointer",
      }}
      {...props}
    >
      {children}
    </button>
  );
}
```

### .gitignore
```
node_modules/
.next/
dist/
out/
.env
.env.local
*.tsbuildinfo
.turbo/
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
