---
name: sync-api-types
description: Reads FastAPI Pydantic models from ../backend/ and diffs their fields against the TypeScript types used in src/ to consume those endpoints — reports mismatches and prints corrected type definitions. Project-specific: requires FastAPI backend + TypeScript frontend monorepo.
allowed-tools: Read, Glob, Grep, Edit, Write
user-invokable: true
argument-hint: "[endpoint-path]"
context: fork
---

## Brief

Reads FastAPI Pydantic `BaseModel` subclasses from `../backend/` and compares their fields against the TypeScript interfaces consuming those endpoints in `src/`. Reports field-level mismatches (missing fields, wrong types, nullability drift) and prints corrected TypeScript definitions for the user to copy. Keeps the frontend type-safe as the backend evolves.

# Sync API Types

Cross-stack type safety auditor. Reads Pydantic models from the FastAPI backend (`../backend/`) and diffs them against the TypeScript interfaces used to consume those endpoints in the frontend. Surfaces type drift before it causes runtime errors.

**Backend:** `../backend/` — FastAPI Python (readable, **never written to** by this skill)
**Frontend:** `src/` — TypeScript types and interfaces

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before any Edit/Write to frontend files,
> and release it immediately after. **Never write to `../backend/` under any circumstances.**

## Usage

```
/sync-api-types [endpoint-path]
```

| Argument        | Type     | Description                                                                                    |
| --------------- | -------- | ---------------------------------------------------------------------------------------------- |
| `endpoint-path` | optional | Restrict to a specific endpoint path (e.g. `/api/jobs`). Defaults to all discovered endpoints. |

---

## Phase 1 — Discover Backend Response Shapes

### 1.1 — Find Pydantic models

```
Glob("../backend/**/*.py")
Grep("class .*\(BaseModel\)", glob="../backend/**/*.py", output_mode="content")
```

For each `class MyModel(BaseModel):` found, read the class body to extract:

- Field names (snake_case)
- Field types (`str`, `int`, `bool`, `Optional[X]`, `List[X]`, `datetime`, etc.)
- Optional vs required status (`Optional[X]` = nullable; plain type = required)

Build a model catalogue:

```
MyModel (../backend/api/jobs.py:45):
  id: int (required)
  name: str (required)
  created_at: datetime (required)
  description: Optional[str] = None (nullable)
```

### 1.2 — Map endpoints to response shapes

```
Grep("response_model=", glob="../backend/**/*.py", output_mode="content")
```

For each `@router.get("/path", response_model=MyModel)` found, record:

- HTTP method and path
- Pydantic model name used as `response_model`

### 1.3 — Filter by endpoint-path (if provided)

If an `endpoint-path` argument was given, filter discovered routes to only those whose path contains the argument string.

Print:

```
  Backend: N Pydantic models discovered
  Endpoints: N routes mapped to models
```

---

## Phase 2 — Discover Frontend Type Definitions

### 2.1 — Match by model name

For each backend model name (e.g., `JobResponse`, `UserProfile`):

```
Grep("interface <ModelName>|type <ModelName> =", glob="src/**/*.{ts,tsx}", output_mode="files_with_matches")
```

Also search for camelCase variants (e.g., `job_response` → `JobResponse`) and partial name matches.

For each match, read the surrounding type definition to extract field names and TypeScript types.

### 2.2 — Handle missing frontend types

If a backend model has NO matching TypeScript type: record it as `MISSING_TYPE`. Phase 3 will generate a suggested type definition.

---

## Phase 3 — Diff and Report

### 3.1 — Apply type mapping rules

| Pydantic                  | TypeScript                |
| ------------------------- | ------------------------- |
| `str`                     | `string`                  |
| `int`, `float`            | `number`                  |
| `bool`                    | `boolean`                 |
| `Optional[X]`             | `X \| null`               |
| `List[X]`                 | `X[]`                     |
| `datetime`                | `string` (ISO 8601)       |
| `dict` / `Dict[str, Any]` | `Record<string, unknown>` |
| `None` (return type)      | `void` or omit            |

**Field name mapping:** Pydantic snake_case → TypeScript camelCase (e.g., `created_at` → `createdAt`).

**Flag MISMATCH if:**

- Frontend type is missing a field the backend sends
- Frontend type has an extra field the backend doesn't send
- Field type doesn't match after applying the table above
- Nullability doesn't match (backend `Optional` → frontend non-nullable)

### 3.2 — Generate corrected TypeScript (print only)

For each mismatch and each `MISSING_TYPE`, print the corrected TypeScript type definition as a code block. **Do NOT auto-apply** — print only for the user to review and copy.

### 3.3 — Output report

Source gum-tui.sh and render using panels. Render only sections that have data:

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_header "Sync API Types: <endpoint-path or 'all endpoints'>"
gum_info "Backend models scanned: N | Frontend types matched: N | Missing: N"

# Render only if mismatches exist — one gum_panel per mismatched model:
gum_panel "MISMATCH: JobResponse" \
  "JobResponse (../backend/api/jobs.py:45) ↔ (src/data/pipeline/pipeline.types.ts:12)" \
  "" \
  "✗ MISSING in frontend:  pipeline_id (number)" \
  "✗ TYPE MISMATCH:        created_at — backend: datetime→string, frontend: Date" \
  "✗ EXTRA in frontend:    legacyField (not in backend model)"

# Then print suggested TypeScript fix as a code block in the output.

# Render only if missing frontend types exist:
gum_panel "MISSING FRONTEND TYPES" \
  "✗ TeamMemberResponse — no TypeScript type found" \
  "  Suggested location: src/data/team/team.types.ts"

# Render only if in-sync types exist:
gum_panel "IN SYNC" \
  "✓ UserResponse ↔ UserResponse — all N fields match" \
  "✓ PipelineArgs ↔ PipelineArgs — all N fields match"

gum_complete "sync-api-types" \
  "Mismatches=N models" \
  "Missing TS types=N" \
  "In sync=N"
```

If all in sync: call `gum_success "All backend types are in sync with frontend TypeScript definitions."`

---

## Notes

- **Backend is read-only** — this skill never writes to `../backend/`.
- Uses `context: fork` — reads both repos without polluting the main conversation context.
- Generated TypeScript type definitions are printed to terminal only — the user must copy them to the appropriate file and commit.
- If the backend uses FastAPI's automatic OpenAPI schema, consider fetching `/openapi.json` from the running dev server as an alternative to static Pydantic analysis.
- Snake_case → camelCase conversion is automatic. If the backend uses a different naming convention (e.g., already camelCase), the diff may have false positives — review carefully.
- `Optional[X]` in Python maps to `X | null` in TypeScript. The frontend may use `X | undefined` — both are acceptable; only flag if the frontend is completely non-nullable when the backend is optional.
