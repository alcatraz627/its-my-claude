---
name: arch-qa
description: Answers technical architecture questions by tracing code paths through the codebase — analyzing feature implementations, data flows, auth middleware, and service integrations — and outputting a structured architecture analysis.
allowed-tools: Read, Glob, Grep, Bash
user-invokable: true
argument-hint: "<question>"
context: fork
---

## Brief

Answers technical architecture questions by systematically tracing code paths through the codebase — from UI entry points down to backend services, auth middleware, and data stores. Runs in an isolated forked context to avoid polluting the main conversation with hundreds of file reads.

# Architecture Q&A

Answers technical architecture questions by systematically exploring the codebase, tracing code paths, and analyzing implementation patterns. Runs as an autonomous agent (`context: fork`) — all file reads happen in an isolated context, returning a single structured answer.

## Usage

```
/arch-qa <question>
```

**Arguments:**

- `question` (required): The technical question about the project architecture

**Example questions:**

- "How does user authentication work?"
- "How is password reset implemented?"
- "What's the data export flow?"
- "How are jobs processed in the background?"
- "How does the payment system work?"
- "What happens when a user uploads a file?"
- "How are API requests authenticated?"

## Question Categories

This skill can answer questions in several categories:

### 1. Feature Implementation

"How does [feature] work?"

- Traces the code path from UI to backend
- Identifies key functions and modules
- Explains the data flow

### 2. Data Flow

"How does data flow from [A] to [B]?"

- Maps the data transformation pipeline
- Identifies intermediate processing steps
- Shows where data is stored and retrieved

### 3. Authentication/Authorization

"How is [auth feature] implemented?"

- Identifies auth middleware
- Shows token/session management
- Explains permission checks

### 4. Integration Points

"How does the app integrate with [service]?"

- Finds API client code
- Shows configuration
- Explains data mapping

### 5. State Management

"How is [state] managed?"

- Identifies state management approach
- Shows state flow
- Explains updates and subscriptions

## Step 0: Load Shared Guidelines

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, and post-run insights — for the entire
duration of this skill run.

## Workflow

### Phase 1: Parse and Categorize the Question

Extract the key components:

- **Feature/System**: What feature is being asked about? (e.g., "authentication", "file upload", "payment")
- **Question Type**: Implementation, flow, integration, or troubleshooting?
- **Scope**: Frontend, backend, or full-stack?

### Phase 2: Identify Entry Points

Based on the question type, find the entry points:

**For UI Features:**

```bash
# Find relevant page/component files
glob "**/*{feature_name}*.{tsx,jsx,vue,svelte}"
glob "**/pages/**/*{feature_name}*.{tsx,jsx}"
glob "**/app/**/*{feature_name}*.{tsx,jsx}"
```

**For Backend Features:**

```bash
# Find API routes
glob "**/api/**/*{feature_name}*.{py,js,ts}"
glob "**/routes/**/*{feature_name}*.{py,js,ts}"

# Find service/library files
glob "**/lib/**/*{feature_name}*.{py,js,ts}"
glob "**/services/**/*{feature_name}*.{py,js,ts}"
```

**For Data Models:**

```bash
# Find type definitions or models
glob "**/types/**/*{feature_name}*.{ts,py}"
glob "**/models/**/*{feature_name}*.{py,js,ts}"
```

### Phase 3: Search for Key Patterns

Use Grep to find implementation details:

**Authentication example:**

```bash
# Find login handlers
rg -i "login|sign.?in|authenticate" -g "*.{js,ts,py}"

# Find token/session creation
rg -i "token|session|jwt|cookie" -g "*.{js,ts,py}"

# Find middleware
rg -i "middleware|auth.*check|require.*auth" -g "*.{js,ts,py}"
```

**Data flow example:**

```bash
# Find API calls
rg "fetch.*{endpoint}|axios.*{endpoint}" -g "*.{js,ts,tsx}"

# Find data transformations
rg "map|transform|process.*data" -g "*.{js,ts,py}"

# Find database queries
rg "find|query|select.*from" -g "*.{js,ts,py}"
```

### Phase 4: Trace the Code Path

For each entry point found, read the file and trace dependencies:

1. **Read the entry point file**

   - Identify imports/dependencies
   - Find the main function/component

2. **Follow the chain**

   - Read imported modules
   - Track function calls
   - Identify external service calls

3. **Build the flow diagram** (mentally or in notes)
   ```
   UI Component
     → API Route Handler
       → Service Layer
         → Database/External API
           → Response transformation
             → UI Update
   ```

### Phase 5: Analyze Key Files

For each file in the code path:

**Extract:**

- **Purpose**: What does this file do?
- **Inputs**: What data/parameters does it accept?
- **Processing**: What transformations or logic does it perform?
- **Outputs**: What does it return?
- **Side effects**: Does it modify state, write to DB, send notifications?
- **Dependencies**: What other modules/services does it use?

**Read strategically:**

- Don't read entire files - focus on relevant functions
- Use line ranges to read specific sections
- Look for JSDoc/docstrings for quick understanding

### Phase 6: Identify Configuration

Find related configuration:

```bash
# Environment variables
rg "{FEATURE_NAME}" -g ".env*"

# Config files
read config/{feature}.json
read lib/config/{feature}.ts
```

### Phase 7: Check for Related Tests

Tests often reveal usage patterns:

```bash
glob "**/*.test.{js,ts,py}"
glob "**/*.spec.{js,ts,py}"
rg "describe.*{feature}|test.*{feature}" -g "*.{test,spec}.{js,ts,py}"
```

### Phase 8: Document the Answer

Structure the answer as follows:

```markdown
# How [Feature] Works

## Overview

[1-2 sentence high-level explanation]

## Architecture Flow
```

[Step-by-step flow diagram in text/ASCII art]

```

## Key Components

### Frontend
- **File:** `path/to/component.tsx`
  - **Purpose:** [what it does]
  - **Key functions:** `functionName()` - [description]

### Backend
- **File:** `path/to/handler.py`
  - **Purpose:** [what it does]
  - **Key functions:** `functionName()` - [description]

### Database/State
- **Collection/Table:** `collection_name`
  - **Schema:** [key fields]
  - **Accessed by:** [which files]

## Data Flow

1. **User Action:** [what triggers the flow]
2. **Request:** [API call or event]
3. **Processing:** [what happens to the data]
4. **Storage:** [where/how data is saved]
5. **Response:** [what's returned to user]

## Configuration

- Environment variables: `VAR_NAME` - [purpose]
- Config files: `path/to/config` - [settings]

## Security/Permissions

- [Authentication/authorization checks]
- [Permission requirements]
- [Data validation]

## Error Handling

- [How errors are caught and handled]
- [User-facing error messages]
- [Logging/monitoring]

## Related Files

- [List of all relevant files with brief descriptions]

## Notes

- [Any gotchas, technical debt, or important considerations]
- [Future improvements or known issues]
```

## Example Questions and Self-Update Instructions

See `reference.md` in this directory for:

- A full worked example ("How does password reset work?") with step-by-step execution and answer template
- Instructions for self-updating this SKILL.md after answering a question (adding project-specific patterns, replacing generic examples)

## Best Practices

### When tracing code:

1. **Start broad, then narrow** - Use Grep to find all mentions, then focus on key files
2. **Follow imports** - Track dependencies to understand the full picture
3. **Read tests** - Tests show expected behavior and edge cases
4. **Check git history** - Recent commits may explain why something works the way it does
5. **Don't read everything** - Focus on the specific question, use line offsets for large files

### When answering:

1. **Be concise** - Provide enough detail to understand, but don't overwhelm
2. **Use diagrams** - ASCII flow diagrams are very helpful
3. **Link to code** - Always reference specific files and line numbers
4. **Highlight security** - Call out auth checks, validation, etc.
5. **Note gotchas** - Mention any surprising or non-obvious behavior

### When stuck:

1. **Search broader** - Try synonyms or related terms
2. **Check package.json** - Dependencies might reveal the approach
3. **Look for examples** - Similar features might use the same pattern
4. **Read docs/comments** - README files often have architecture notes
5. **Ask for clarification** - If the question is ambiguous, ask the user to narrow it

## Related Skills

- `/project-index` - Build a full project index first for better context (run this first!)
- `/code-review` - Review specific implementations found during Q&A

## Tips

- **First run `/project-index`** to build context about the project
- Keep a mental model of common patterns (e.g., "API route → service layer → DB")
- Use the project index (if available) as a starting reference
- When explaining flows, think: UI → API → Logic → Data → Response
- Don't assume - trace the actual code, even if you think you know the pattern
- **Don't read everything** — focus on the specific question, use line offsets for large files
