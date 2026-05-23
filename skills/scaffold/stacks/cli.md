# Node.js CLI Tool — TypeScript

## Meta
- Runtime: node
- Default port: none
- Install command: npm install
- Run command: npx tsx src/index.ts
- Test command: npx vitest run

## Dependencies
commander: ^13
chalk: ^5

## Dev Dependencies
typescript: ^5.7
@types/node: ^22
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
  "type": "module",
  "bin": {
    "{{name}}": "./dist/index.js"
  },
  "files": ["dist"],
  "scripts": {
    "dev": "tsx src/index.ts",
    "build": "tsc",
    "prepublishOnly": "npm run build",
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
    "declaration": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### src/index.ts
```typescript
#!/usr/bin/env node
import { Command } from "commander";

const program = new Command();

program
  .name("{{name}}")
  .description("A CLI tool")
  .version("0.1.0");

program
  .command("hello")
  .description("Say hello")
  .argument("[name]", "who to greet", "world")
  .action((name: string) => {
    console.log(`Hello, ${name}!`);
  });

program.parse();
```

### tests/index.test.ts
```typescript
import { describe, it, expect } from "vitest";
import { execSync } from "child_process";

describe("CLI", () => {
  it("runs hello command", () => {
    const output = execSync("npx tsx src/index.ts hello Claude").toString().trim();
    expect(output).toBe("Hello, Claude!");
  });

  it("runs hello with default name", () => {
    const output = execSync("npx tsx src/index.ts hello").toString().trim();
    expect(output).toBe("Hello, world!");
  });
});
```

### .gitignore
```
node_modules/
dist/
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
