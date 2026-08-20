#!/usr/bin/env bash
# Tests for skill-lint.py and skill-lint-nudge.sh: every check is shown firing on
# the case it guards and staying quiet on a clean skill; the hook fires on a
# SKILL.md write, stays silent elsewhere, honours the mute, and regenerates the
# index for a gcc skill. Run after any change to either file.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LINT="$HERE/../skill-lint.py"
HOOK="$HERE/skill-lint-nudge.sh"
T=$(mktemp -d)
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
has() { if printf '%s' "$2" | rg -q -- "$1"; then ok "$3"; else bad "$3 (wanted /$1/)"; fi; }
lacks(){ if printf '%s' "$2" | rg -q -- "$1"; then bad "$3 (found /$1/)"; else ok "$3"; fi; }

mkdir -p "$T/skills/good" "$T/skills/bad" "$T/skills/nofm"
cat > "$T/skills/good/SKILL.md" <<'MD'
---
name: good
description: Lints a SKILL.md against the harness field list and the house caps, then reports one line per finding. Use when a skill was just written or edited.
allowed-tools: Read, Bash, Agent
user-invocable: true
argument-hint: "<path>"
---

## Brief

One paragraph. Two lines.

## Step 0

Read the guidelines.

## Validation

Check that every finding names a line.

## Ledger

bash ~/.claude/scripts/skill-log.sh record good --task x
MD
cat > "$T/skills/bad/SKILL.md" <<MD
---
name: bad
description: $(printf 'x%.0s' $(seq 1 320))
allowed-tools: Read, Task, Bash
user-invokable: true
triggers: nope
argument-hint: "$(printf 'a%.0s' $(seq 1 130))"
---

## Brief

l1
l2
l3
l4
l5
l6
l7
l8
l9

## Steps

MUST MUST MUST NEVER NEVER ALWAYS

\`\`\`bash
mkdir -p .claude/skills/<name>
\`\`\`
MD
printf '# no frontmatter\n\ntext\n' > "$T/skills/nofm/SKILL.md"

echo "# lint: clean skill"
out=$(python3 "$LINT" "$T/skills/good/SKILL.md"); rc=$?
[ $rc -eq 0 ] && ok "exit 0 on clean" || bad "exit $rc on clean: $out"
has "clean" "$out" "prints clean"

echo "# lint: each check fires"
out=$(python3 "$LINT" "$T/skills/bad/SKILL.md"); rc=$?
[ $rc -eq 2 ] && ok "exit 2 with errors" || bad "exit $rc with errors"
for c in misspelled-field unknown-field description-long argument-hint-long task-tool brief-long validation-missing ledger-missing relative-skill-path emphasis; do has " $c " "$out" "fires: $c"; done
has "use \`user-invocable\`" "$out" "misspelling names the real field"
out=$(python3 "$LINT" "$T/skills/nofm/SKILL.md"); rc=$?
has "frontmatter-missing" "$out" "fires: frontmatter-missing"; [ $rc -eq 2 ] && ok "exit 2 on missing frontmatter" || bad "exit $rc on missing frontmatter"
printf -- '---\nname: x\nallowed-tools: Read\n---\n\n## Brief\n\nx\n' > "$T/skills/nofm/SKILL.md"
has "description-missing" "$(python3 "$LINT" "$T/skills/nofm/SKILL.md")" "fires: description-missing"
printf -- '---\nname: x\ndescription: ok\n---\n\n## Steps\n\nx\n' > "$T/skills/nofm/SKILL.md"
out=$(python3 "$LINT" "$T/skills/nofm/SKILL.md"); rc=$?
has "brief-missing" "$out" "fires: brief-missing"; [ $rc -eq 1 ] && ok "exit 1 on warnings only" || bad "exit $rc on warnings only"
has '"check": "brief-missing"' "$(python3 "$LINT" --json "$T/skills/nofm/SKILL.md")" "--json"
# a relative .claude/skills READ must not fire (only writes)
printf -- '---\nname: x\ndescription: ok\n---\n\n## Brief\n\nx\n\n```bash\nls .claude/skills/x/SKILL.md\nrg foo .claude/skills/\n```\n' > "$T/skills/nofm/SKILL.md"
lacks "relative-skill-path" "$(python3 "$LINT" "$T/skills/nofm/SKILL.md")" "relative path READ is not flagged"

echo "# hook"
mkhook() { jq -nc --arg t "$1" --arg f "$2" '{tool_name:$t, tool_input:{file_path:$f}, cwd:"/tmp"}' | HOME="$T/home" SKILL_LINT="$LINT" SKILLS_INDEX="$T/index.sh" bash "$HOOK" 2>/dev/null; }
mkdir -p "$T/home/.claude/scripts/hooks"; printf '#!/usr/bin/env bash\nexit 0\n' > "$T/home/.claude/scripts/hooks/warn-log.sh"
printf '#!/usr/bin/env bash\necho ran >> "%s/index.ran"\n' "$T" > "$T/index.sh"; chmod +x "$T/index.sh"
out=$(mkhook Write "$T/skills/bad/SKILL.md")
has "additionalContext" "$out" "fires on a bad SKILL.md write"
has "skill-lint" "$out" "names itself"
has "misspelled-field" "$out" "carries the findings"
has "error tier" "$out" "tier from exit code"
out=$(mkhook Write "$T/skills/good/SKILL.md")
[ -z "$out" ] && ok "silent on a clean SKILL.md" || bad "noisy on clean: $out"
out=$(mkhook Write "$T/skills/bad/README.md")
[ -z "$out" ] && ok "silent on a non-SKILL.md path" || bad "fired on README: $out"
out=$(mkhook Bash "$T/skills/bad/SKILL.md")
[ -z "$out" ] && ok "silent on a non-write tool" || bad "fired on Bash"
[ ! -f "$T/index.ran" ] && ok "no index regen for a non-gcc skill" || bad "index regenerated for a project skill"
mkdir -p "$T/home/.claude/skills/gccskill"; cp "$T/skills/good/SKILL.md" "$T/home/.claude/skills/gccskill/"
out=$(mkhook Write "$T/home/.claude/skills/gccskill/SKILL.md")
[ -f "$T/index.ran" ] && ok "index regenerated for a gcc skill" || bad "index not regenerated for a gcc skill"
touch "$T/home/.claude/.no-skill-lint-gate"
out=$(mkhook Write "$T/skills/bad/SKILL.md")
[ -z "$out" ] && ok "mute honoured" || bad "fired while muted"
rm -f "$T/home/.claude/.no-skill-lint-gate"

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
