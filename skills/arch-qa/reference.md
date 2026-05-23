# arch-qa — Reference Material

Extended examples and self-update instructions. Referenced from SKILL.md when needed.

---

## Example: "How does password reset work?"

### Execution

**Step 1:** Search for password reset entry points

```bash
grep -r "password.*reset\|forgot.*password" --include="*.{tsx,ts,py}" -i
```

**Step 2:** Find UI component

```bash
glob "**/forgot-password*.{tsx,jsx}"
glob "**/reset-password*.{tsx,jsx}"
```

**Step 3:** Find API endpoints

```bash
grep -r "reset.*password" --include="**/api/**/*.{ts,py}"
```

**Step 4:** Trace the flow

- Read: `app/forgot-password/page.tsx` → UI form
- Read: `api/auth/reset-password.ts` → API handler
- Read: `lib/auth/password-reset.ts` → Business logic
- Read: `lib/messaging/email.ts` → Email sending

**Step 5:** Check email templates

```bash
glob "**/email-templates/**/*reset*"
```

### Answer Output Template

```markdown
# How Password Reset Works

## Overview

Password reset is a two-step process: user requests reset via email, then sets new password via token link.

## Architecture Flow

User submits email
  → POST /api/auth/forgot-password
    → Generate reset token
    → Save token to database
    → Send email with reset link
      → User clicks link
        → GET /reset-password?token=xxx
          → Verify token
            → POST /api/auth/reset-password
              → Validate token → Hash new password → Update user record → Clear reset token
                → Redirect to login
```

---

## Self-Update Instructions (Run after answering)

After successfully answering a question about this project, update `SKILL.md` to make future answers faster.

### What to Update

#### 1. Add Question Examples

Add the answered question to the "Example questions" section in SKILL.md:

- The actual question answered
- Category (auth, data flow, integration, etc.)
- Key files discovered

#### 2. Update Search Patterns

If you discovered effective Grep patterns, add them to Phase 3:

```bash
# Example — if this project uses a specific auth pattern:
grep -r "authService\|loginUser\|authenticateUser"
```

#### 3. Add Project-Specific Patterns

Document patterns unique to this project in a `## Project-Specific Patterns` section:

```markdown
## Project-Specific Patterns (Learned from Q&A)

**Last updated:** [date]

### Authentication
- Token storage: [localStorage/cookies/httpOnly]
- Auth library: [next-auth/clerk/custom]

### API Structure
- Pattern: [REST/GraphQL/tRPC]
- Location: [api/ or app/api/]
```

#### 4. Replace Generic Examples

If the project uses different tools than the examples show, replace them:

**Before (generic):**

```bash
grep -r "login\|sign.?in\|authenticate"
```

**After (project-specific):**

```bash
# Find login handlers (uses authService pattern)
grep -r "authService\|loginUser\|authenticateUser"
```

#### 5. Update File Path Examples

Replace generic paths with actual project paths found during the run.

### When to Update

Update SKILL.md when:

1. **First question answered** — Add actual project structure
2. **New pattern discovered** — Add to relevant section
3. **Common question** — Add to examples if asked multiple times
4. **Better search found** — Replace generic Grep with project-specific

### How to Update

Use the Edit tool on SKILL.md:

```
Edit:
  file_path: .claude/skills/arch-qa/SKILL.md
  old_string: [section with generic examples]
  new_string: [section with project-specific examples]
```
