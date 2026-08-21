# Express.js + TypeScript + Structured Routes

## Meta
- Runtime: node
- Default port: 5020
- Install command: npm install
- Run command: npm run dev
- Test command: npx vitest run

## Dependencies
express: ^5
dotenv: ^16
cors: ^2
helmet: ^8
zod: ^3

## Dev Dependencies
typescript: ^5.7
@types/node: ^22
@types/express: ^5
tsx: ^4
vitest: ^3
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
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "lint": "eslint src/",
    "test": "vitest run",
    "typecheck": "tsc --noEmit"
  }
}
```

### tsconfig.json
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### src/index.ts
```typescript
import express from "express";
import cors from "cors";
import helmet from "helmet";
import { config } from "./config.js";
import { healthRouter } from "./routes/health.js";

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

app.use("/health", healthRouter);

// Add route modules here:
// app.use("/api/users", usersRouter);

app.listen(config.port, () => {
  console.log(`${config.appName} listening on port ${config.port}`);
});

export { app };
```

### src/config.ts
```typescript
import "dotenv/config";

export const config = {
  port: parseInt(process.env.PORT || "{{port}}", 10),
  appName: process.env.APP_NAME || "{{name}}",
  nodeEnv: process.env.NODE_ENV || "development",
} as const;
```

### src/routes/health.ts
```typescript
import { Router } from "express";

export const healthRouter = Router();

healthRouter.get("/", (_req, res) => {
  res.json({
    status: "ok",
    timestamp: new Date().toISOString(),
  });
});
```

### src/middleware/error-handler.ts
```typescript
import type { Request, Response, NextFunction } from "express";

export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction,
) {
  console.error(err.stack);
  res.status(500).json({
    error: "Internal Server Error",
    message: process.env.NODE_ENV === "development" ? err.message : undefined,
  });
}
```

### tests/health.test.ts
```typescript
import { describe, it, expect } from "vitest";
import request from "supertest";
import { app } from "../src/index.js";

describe("GET /health", () => {
  it("returns ok status", async () => {
    const res = await request(app).get("/health");
    expect(res.status).toBe(200);
    expect(res.body.status).toBe("ok");
  });
});
```

### .env.example
```bash
PORT={{port}}
APP_NAME={{name}}
NODE_ENV=development
# DATABASE_URL=postgresql://user:pass@localhost:5432/{{name}}
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
