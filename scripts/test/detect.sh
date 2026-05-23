#!/usr/bin/env bash
# scripts/test/detect.sh — Detect testing framework + command for a folder.
#
# Cache: ~/.claude/cache/test-patterns/<encoded-folder>.json
# Cache hit  → print cached pattern (<200ms target)
# Cache miss → scan folder structure, detect framework, write cache
# Stale cache → caller runs cached cmd; failure surfaces; agent re-detects
#
# Designed for /test skill. Folders rarely change their test infra; cache
# can be aggressive. Re-detection on test-not-found errors is an acceptable
# rare cost.
#
# Usage:
#   detect.sh [folder]              # default: $PWD; prints JSON
#   detect.sh --refresh [folder]    # force re-detect (bypass cache)
#   detect.sh --list                # list all cached entries

set -uo pipefail

CACHE_DIR="$HOME/.claude/cache/test-patterns"
mkdir -p "$CACHE_DIR"

REFRESH=0
LIST=0
FOLDER="$PWD"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --refresh) REFRESH=1 ;;
    --list)    LIST=1 ;;
    -*)        printf 'unknown flag: %s\n' "$1" >&2; exit 2 ;;
    *)         FOLDER="$1" ;;
  esac
  shift
done

if (( LIST )); then
  ls "$CACHE_DIR" 2>/dev/null
  exit 0
fi

# Resolve folder to absolute
FOLDER=$(cd "$FOLDER" 2>/dev/null && pwd) || { printf 'no such dir\n' >&2; exit 1; }
ENCODED=$(printf '%s' "$FOLDER" | sed 's|/|-|g')
CACHE="$CACHE_DIR/${ENCODED}.json"

# Cache hit — print and exit (fast path)
if [[ -f "$CACHE" && $REFRESH -eq 0 ]]; then
  cat "$CACHE"
  exit 0
fi

# Detect framework. Walk-up to find the nearest project-config marker.
TYPE=""
TEST_CMD=""
RUNNER=""
INSTALL_HINT=""

probe_dir() {
  local d="$1"
  # Python: pytest if pyproject.toml or pytest.ini or setup.cfg
  if [[ -f "$d/pyproject.toml" || -f "$d/pytest.ini" || -f "$d/setup.cfg" ]]; then
    if [[ -f "$d/.venv/bin/pytest" ]]; then
      TYPE="pytest"; RUNNER="./.venv/bin/pytest"
    elif command -v pytest >/dev/null 2>&1; then
      TYPE="pytest"; RUNNER="pytest"
    else
      TYPE="pytest"; RUNNER="python3 -m pytest"
    fi
    TEST_CMD="$RUNNER"
    return 0
  fi
  # Node/JS: detect from package.json
  if [[ -f "$d/package.json" ]]; then
    local script
    script=$(python3 -c "import json; p=json.load(open('$d/package.json')); print(p.get('scripts',{}).get('test',''))" 2>/dev/null)
    # Detect framework from devDeps
    local has_vitest has_jest has_mocha
    has_vitest=$(python3 -c "import json; p=json.load(open('$d/package.json')); print('1' if 'vitest' in (p.get('devDependencies',{})|p.get('dependencies',{})) else '')" 2>/dev/null)
    has_jest=$(python3 -c "import json; p=json.load(open('$d/package.json')); print('1' if 'jest' in (p.get('devDependencies',{})|p.get('dependencies',{})) else '')" 2>/dev/null)
    has_mocha=$(python3 -c "import json; p=json.load(open('$d/package.json')); print('1' if 'mocha' in (p.get('devDependencies',{})|p.get('dependencies',{})) else '')" 2>/dev/null)
    # Pick package manager
    local pm=npm
    [[ -f "$d/pnpm-lock.yaml" ]] && pm=pnpm
    [[ -f "$d/yarn.lock" ]]     && pm=yarn
    [[ -f "$d/bun.lockb" ]]     && pm=bun
    if [[ -n "$has_vitest" ]]; then
      TYPE="vitest"; RUNNER="npx vitest"
    elif [[ -n "$has_jest" ]]; then
      TYPE="jest"; RUNNER="npx jest"
    elif [[ -n "$has_mocha" ]]; then
      TYPE="mocha"; RUNNER="npx mocha"
    elif [[ -n "$script" ]]; then
      TYPE="npm-test"; RUNNER="$pm test"
    fi
    [[ -n "$TYPE" ]] && { TEST_CMD="$RUNNER"; return 0; }
  fi
  # Rust: Cargo.toml
  if [[ -f "$d/Cargo.toml" ]]; then
    TYPE="cargo"; RUNNER="cargo test"; TEST_CMD="$RUNNER"; return 0
  fi
  # Go: go.mod
  if [[ -f "$d/go.mod" ]]; then
    TYPE="go"; RUNNER="go test ./..."; TEST_CMD="$RUNNER"; return 0
  fi
  # Bun direct
  if [[ -f "$d/bun.lockb" || -f "$d/bunfig.toml" ]]; then
    TYPE="bun"; RUNNER="bun test"; TEST_CMD="$RUNNER"; return 0
  fi
  return 1
}

# Walk up from FOLDER to find a project root with a known test config
d="$FOLDER"
while [[ "$d" != "/" && -z "$TYPE" ]]; do
  if probe_dir "$d"; then
    PROJECT_ROOT="$d"
    break
  fi
  d=$(dirname "$d")
done

if [[ -z "$TYPE" ]]; then
  printf '{"folder": %s, "detected": false, "reason": "no known test marker found"}\n' "\"$FOLDER\""
  exit 1
fi

# Write cache
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
python3 -c "
import json
d = {
  'folder':       '$FOLDER',
  'project_root': '${PROJECT_ROOT:-$FOLDER}',
  'framework':    '$TYPE',
  'runner':       '$RUNNER',
  'test_cmd':     '$TEST_CMD',
  'detected_at':  '$TS',
}
print(json.dumps(d, indent=2))
" > "$CACHE"
cat "$CACHE"
