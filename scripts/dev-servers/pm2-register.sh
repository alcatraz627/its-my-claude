#!/usr/bin/env bash
# ~/.claude/scripts/dev-servers/pm2-register.sh
# Allocate ports and register/deregister pm2 apps in the port registry.
#
# Commands:
#   pm2-register.sh register --name <project> --type server|pair [OPTIONS]
#   pm2-register.sh deregister --name <project>
#   pm2-register.sh change --name <project> --suffix <nn>
#   pm2-register.sh list
#
# Options for register:
#   --name <n>         Project name (used for pm2 process names and .test domain)
#   --type server      Backend only → port 50xx
#   --type pair        Frontend + backend → ports 30xx + 50xx (same suffix)
#   --suffix <nn>      Force a specific 2-digit suffix (default: auto-picked)
#   --framework <f>    vite (default) | next | svelte | express
#   --cwd <path>       Project root (default: $PWD)

set -euo pipefail

REGISTRY="$HOME/.claude/scratchpad/global/port-registry.md"
TODAY=$(date +%Y-%m-%d)

# Suffixes to never use:
#   00-09 (too low), 73/74 (5173/5174 = Vite defaults), 80 (8080 = Webpack)
FORBIDDEN_SUFFIXES=(00 01 02 03 04 05 06 07 08 09 73 74 80)

# ── Helpers ──────────────────────────────────────────────────────────────────

die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "  $*"; }

hr() { echo "────────────────────────────────────────────────────────────"; }

get_used_suffixes() {
  # Extract 30xx/50xx port numbers from registry table rows, return last 2 digits
  grep "^|" "$REGISTRY" 2>/dev/null \
    | grep -v "^| Port\|^|---\|^| —" \
    | grep -oE '\b[35]0[1-9][0-9]\b' \
    | sed 's/^[35]0//' \
    | sort -u
}

is_forbidden() {
  local s="$1"
  for f in "${FORBIDDEN_SUFFIXES[@]}"; do
    [[ "$s" == "$f" ]] && return 0
  done
  return 1
}

pick_suffix() {
  local used
  used=$(get_used_suffixes || true)
  local attempts=0
  while (( attempts < 200 )); do
    local n=$(( RANDOM % 90 + 10 ))
    local pad
    printf -v pad "%02d" "$n"
    is_forbidden "$pad" && (( attempts++ )) && continue
    if ! printf '%s\n' "$used" | grep -qx "$pad"; then
      echo "$pad"
      return
    fi
    (( attempts++ ))
  done
  die "No free port suffix found (10-99). Check port-registry.md."
}

validate_suffix() {
  local s="$1"
  printf -v s "%02d" "$s"
  is_forbidden "$s" && die "Suffix ${s} is forbidden (reserved port range)."
  if get_used_suffixes | grep -qx "$s"; then
    die "Suffix ${s} is already used. Check port-registry.md or pick another."
  fi
  echo "$s"
}

# Append a single row to the registry table (before ## sections)
append_registry_row() {
  local port="$1" service="$2" project="$3" ecosystem="$4"
  local new_row="| ${port} | ${service} | ${project} | ${ecosystem} | online | ${TODAY} |"
  python3 - "$REGISTRY" "$new_row" <<'PYEOF'
import sys
path, new_row = sys.argv[1], sys.argv[2]
with open(path) as f:
    lines = f.readlines()
# Find the last table data row (not header or divider)
insert_at = None
for i, line in enumerate(lines):
    stripped = line.strip()
    if (stripped.startswith('|')
            and not stripped.startswith('| Port')
            and '---' not in stripped
            and '| —' not in stripped):
        insert_at = i
if insert_at is None:
    lines.append(new_row + '\n')
else:
    lines.insert(insert_at + 1, new_row + '\n')
with open(path, 'w') as f:
    f.writelines(lines)
PYEOF
}

# Remove all rows for a given project name from the registry
remove_registry_rows() {
  local project="$1"
  python3 - "$REGISTRY" "$project" <<'PYEOF'
import sys
path, project = sys.argv[1], sys.argv[2]
with open(path) as f:
    lines = f.readlines()
# Match rows where column 3 (project) equals the given name
filtered = []
for line in lines:
    if line.startswith('|'):
        cols = [c.strip() for c in line.split('|')]
        # cols[0]='' cols[1]=port cols[2]=service cols[3]=project ...
        if len(cols) > 3 and cols[3] == project:
            continue
    filtered.append(line)
with open(path, 'w') as f:
    f.writelines(filtered)
PYEOF
}

# ── Ecosystem snippet generators ─────────────────────────────────────────────

ecosystem_server() {
  local name="$1" port="$2" cwd="$3"
  cat <<EOF
// ecosystem.config.cjs
module.exports = {
  apps: [
    {
      name: '${name}-backend',
      script: 'src/server.js',    // ← adjust to your entry point
      cwd: '${cwd}',
      watch: false,
      autorestart: true,
      max_restarts: 5,
      restart_delay: 2000,
      env: {
        NODE_ENV: 'development',
        PORT: '${port}',
      },
      out_file: '.pm2/logs/backend-out.log',
      error_file: '.pm2/logs/backend-err.log',
      merge_logs: true,
    },
  ],
};
EOF
}

ecosystem_pair() {
  local name="$1" fe_port="$2" be_port="$3" cwd="$4" framework="$5"

  local fe_script fe_args
  case "$framework" in
    next)   fe_script="node_modules/.bin/next"; fe_args="dev -p ${fe_port} -H 0.0.0.0" ;;
    svelte) fe_script="node_modules/.bin/vite"; fe_args="dev --port ${fe_port} --host" ;;
    *)      fe_script="node_modules/.bin/vite"; fe_args="--port ${fe_port} --host" ;;
  esac

  cat <<EOF
// ecosystem.config.cjs
module.exports = {
  apps: [
    // ── Frontend ─────────────────────────────────────────────────────────
    {
      name: '${name}-frontend',
      script: '${fe_script}',
      args: '${fe_args}',
      cwd: '${cwd}',
      watch: false,
      autorestart: true,
      max_restarts: 5,
      restart_delay: 2000,
      env: {
        NODE_ENV: 'development',
        PORT_FRONTEND: '${fe_port}',
      },
      out_file: '.pm2/logs/frontend-out.log',
      error_file: '.pm2/logs/frontend-err.log',
      merge_logs: true,
    },

    // ── Backend ──────────────────────────────────────────────────────────
    {
      name: '${name}-backend',
      script: 'src/server.js',    // ← adjust to your entry point
      cwd: '${cwd}',
      watch: false,
      autorestart: true,
      max_restarts: 5,
      restart_delay: 2000,
      env: {
        NODE_ENV: 'development',
        PORT_BACKEND: '${be_port}',
        PORT_FRONTEND: '${fe_port}',
      },
      out_file: '.pm2/logs/backend-out.log',
      error_file: '.pm2/logs/backend-err.log',
      merge_logs: true,
    },
  ],
};
EOF
}

# ── Commands ─────────────────────────────────────────────────────────────────

cmd_register() {
  local name="" type="" suffix="" cwd="$PWD" framework="vite"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name)      name="$2";      shift 2 ;;
      --type)      type="$2";      shift 2 ;;
      --suffix)    suffix="$2";    shift 2 ;;
      --cwd)       cwd="$2";       shift 2 ;;
      --framework) framework="$2"; shift 2 ;;
      *) die "Unknown option: $1" ;;
    esac
  done

  [[ -z "$name"  ]] && die "--name is required"
  [[ -z "$type"  ]] && die "--type is required (server or pair)"
  [[ "$type" != "server" && "$type" != "pair" ]] && die "--type must be 'server' or 'pair'"

  if [[ -z "$suffix" ]]; then
    suffix=$(pick_suffix)
  else
    suffix=$(validate_suffix "$suffix")
  fi

  local be_port="50${suffix}"
  local fe_port="30${suffix}"
  local ecosystem_path="${cwd}/ecosystem.config.cjs"
  local rel_ecosystem="~/${ecosystem_path#"$HOME/"}"

  echo ""
  echo "Registered: ${name}  (suffix: ${suffix})"
  hr

  if [[ "$type" == "server" ]]; then
    append_registry_row "$be_port" "backend" "$name" "$rel_ecosystem"
    info "Backend:  http://localhost:${be_port}"
    info "          http://local.${be_port}.run  (zero-config, via nginx+dnsmasq)"
    echo ""
    echo "── ecosystem.config.cjs snippet ─────────────────────────────────────"
    ecosystem_server "$name" "$be_port" "$cwd"
  else
    append_registry_row "$fe_port" "frontend" "$name" "$rel_ecosystem"
    append_registry_row "$be_port" "backend"  "$name" "$rel_ecosystem"
    info "Frontend: http://localhost:${fe_port}"
    info "          http://local.${fe_port}.run"
    info "Backend:  http://localhost:${be_port}"
    info "          http://local.${be_port}.run"
    info ".test:    http://${name}.test  →  frontend"
    info "          http://${name}-api.test  →  backend"
    info "          (run gen-nginx-conf.sh + nginx reload to activate .test)"
    echo ""
    echo "── ecosystem.config.cjs snippet ─────────────────────────────────────"
    ecosystem_pair "$name" "$fe_port" "$be_port" "$cwd" "$framework"
  fi

  echo ""
  hr
  echo "Next steps:"
  info "1. Save the snippet above to ${cwd}/ecosystem.config.cjs"
  info "2. pm2 start ecosystem.config.cjs && pm2 save"
  if [[ "$type" == "pair" ]]; then
    info "3. (optional) gen-nginx-conf.sh && sudo nginx -s reload  ← for .test domains"
  fi
  echo ""
}

cmd_deregister() {
  local name=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name) name="$2"; shift 2 ;;
      *) die "Unknown option: $1" ;;
    esac
  done
  [[ -z "$name" ]] && die "--name is required"

  remove_registry_rows "$name"
  echo "Removed '${name}' from port registry."
  echo ""
  echo "To stop pm2 processes:"
  echo "  pm2 delete ${name}-backend ${name}-frontend 2>/dev/null; pm2 save"
}

cmd_change() {
  local name="" new_suffix=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name)   name="$2";       shift 2 ;;
      --suffix) new_suffix="$2"; shift 2 ;;
      *) die "Unknown option: $1" ;;
    esac
  done
  [[ -z "$name"       ]] && die "--name is required"
  [[ -z "$new_suffix" ]] && die "--suffix <nn> is required"

  new_suffix=$(validate_suffix "$new_suffix")

  echo "Removing old registry entries for '${name}'..."
  remove_registry_rows "$name"

  echo ""
  echo "Now re-register with the new suffix:"
  echo "  pm2-register.sh register --name ${name} --type <server|pair> --suffix ${new_suffix}"
  echo ""
  echo "Also update ecosystem.config.cjs in your project to use the new ports:"
  echo "  Frontend: 30${new_suffix}   Backend: 50${new_suffix}"
}

cmd_list() {
  echo ""
  echo "Port Registry"
  hr
  grep "^|" "$REGISTRY" | grep -v "^|---" | head -30
  echo ""
  echo "Live pm2 processes:"
  export PATH="$PATH:/opt/homebrew/bin"
  pm2 list 2>/dev/null || echo "  (pm2 not running or not found at /opt/homebrew/bin/pm2)"
}

usage() {
  cat <<'EOF'
pm2-register.sh — Port allocation and pm2 app registration

Commands:
  register    --name <n> --type server|pair [--suffix <nn>] [--cwd <path>] [--framework vite|next|svelte]
  deregister  --name <n>
  change      --name <n> --suffix <nn>
  list

Examples:
  pm2-register.sh register --name my-api --type server
  pm2-register.sh register --name my-app --type pair --framework next
  pm2-register.sh register --name my-app --type pair --suffix 47
  pm2-register.sh deregister --name my-api
  pm2-register.sh change --name my-app --suffix 55
  pm2-register.sh list
EOF
}

# ── Main ─────────────────────────────────────────────────────────────────────

[[ $# -eq 0 ]] && usage && exit 0

COMMAND="$1"; shift

case "$COMMAND" in
  register)   cmd_register   "$@" ;;
  deregister) cmd_deregister "$@" ;;
  change)     cmd_change     "$@" ;;
  list)       cmd_list ;;
  help|--help|-h) usage ;;
  *) die "Unknown command: ${COMMAND}. Use: register|deregister|change|list" ;;
esac
