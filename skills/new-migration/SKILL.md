---
name: new-migration
description: Generates a Drizzle ORM migration from a plain-English schema change description — updates the schema file and runs db:generate to produce the SQL migration. Project-specific: requires Drizzle ORM setup.
allowed-tools: Read, Edit, Write, Bash, Glob, Grep
user-invokable: true
argument-hint: "<description>"
---

## Brief

Takes a plain-English description of a database schema change, finds the right schema file, applies the Drizzle column/table change, then runs `npm run db:generate` to produce the migration SQL. Handles the full schema → migration workflow in one step.

# New Migration

Generates Drizzle ORM schema changes and their corresponding migrations from a plain-English description. Knows the project's schema conventions (`src/db/schema/`) and generates code that matches the existing style.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after.

## Usage

```
/new-migration <description>
```

**Arguments:**
- `description` (required): Plain-English description of the schema change. Examples:
  - "add expires_at column to sessions table"
  - "create a new notifications table with user_id, message, and read_at"
  - "rename the job_status column to status in jobs table"
  - "add index on users.email"

---

## Phase 1 — Parse the Description

Extract from the description:
- **Operation type:** add column / remove column / rename / add table / add index / modify type
- **Target table:** which table is affected
- **Column/field details:** name, type, nullable, default, references

If the description is ambiguous, ask one clarifying question before proceeding.

---

## Phase 2 — Find the Schema File

Read `src/db/schema/index.ts` to see available schema domain files.

Find the file that owns the target table:
```
Glob("src/db/schema/*.ts")
```

Read the relevant schema file to understand:
- Current table definition
- Column naming conventions (camelCase or snake_case)
- Existing column types used
- How foreign keys are defined

---

## Phase 3 — Generate the Schema Change

Apply the change to the schema file using `Edit`. Follow these conventions:

**Column types to use:**
```typescript
// Strings
text("column_name")
varchar("column_name", { length: 255 })

// Numbers
integer("column_name")
serial("column_name")  // auto-increment

// Timestamps
timestamp("column_name", { withTimezone: true })
timestamp("column_name", { withTimezone: true }).defaultNow()

// Boolean
boolean("column_name").default(false)

// Optional columns
text("column_name")  // nullable by default
text("column_name").notNull()  // required

// Foreign keys
integer("user_id").references(() => users.id, { onDelete: "cascade" })
```

Acquire lock before editing:
```bash
bash ~/.claude/skills/shared/lock-file.sh acquire "src/db/schema/<file>.ts" "new-migration"
```

Apply the edit, then release the lock.

Print: `  ✓ Schema updated: src/db/schema/<file>.ts`

---

## Phase 4 — Generate Migration

Run the migration generator:

```bash
npm run db:generate
```

This command runs `drizzle-kit generate` which compares the current schema against previous migrations and produces a new SQL file in `drizzle/`.

Find and read the generated migration file:
```
Glob("drizzle/*.sql")
```

Read the newest file and print its contents for the user to review.

---

## Phase 5 — Confirm and Advise

Source gum-tui.sh and render the summary:

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_header "Migration Generated"
gum_kv "Schema change" "<description>"
gum_kv "Schema file" "src/db/schema/<file>.ts"
gum_kv "Migration file" "drizzle/<timestamp>_<name>.sql"

# Print the SQL preview as a labelled panel:
gum_panel "SQL Preview (first 20 lines)" \
  "<first 20 lines of the generated SQL file>"

gum_panel "Next Steps" \
  "1. Review the SQL above carefully" \
  "2. Run: npm run db:migrate  (applies to your local DB)" \
  "3. Commit both the schema change and the migration file together"
```

---

## Notes

- Never applies the migration automatically — `npm run db:migrate` must be run manually after review.
- Never modifies the NextAuth adapter tables (`users`, `accounts`, `sessions`, `verificationTokens`) without explicit user confirmation — these have external constraints.
- If `npm run db:generate` produces no new file, it means the schema change matched the current DB state — print a note explaining this.
