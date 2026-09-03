# deployq checks — named, not free shell.
#
# A spec may only ask for a check that exists here. That is the same property as
# named targets: a queue file must not become a shell. Add a check by writing a
# function, not by putting a command in a spec.
#
# Every check: run_check <name> <repo> <ref> <target>; exit 0 pass, non-zero fail.
# Print one line of evidence either way — a check whose reading nobody can see is
# an assertion, not a check.

_dq_url_for() {  # target -> the URL its post-checks probe, from the registry
  awk -F'\t' -v n="$1" '$1==n && $0 !~ /^#/ {print $4; exit}' "$HERE/targets.tsv"
}

# Defers to the estate's existing preflight rather than re-asking the question.
# It already distinguishes the three states that all surface as the same
# unhelpful "auth" error, and prints the one command that fixes each — which is
# better error-returning than a bare token probe, and is why this calls it.
check_gcloud_alive() {
  local pf="${DEPLOYQ_PREFLIGHT:-$HOME/Code/Versable/gcp/bin/gcp-preflight.sh}"
  if [ ! -x "$pf" ] && [ ! -f "$pf" ]; then
    echo "no gcp-preflight.sh at $pf; cannot judge the session"; return 1
  fi
  local out; out=$(bash "$pf" 2>&1); local rc=$?
  case $rc in
    0) echo "preflight: ready" ; return 0 ;;
    1) echo "preflight: REAUTH NEEDED — the human runs the ADC login; $(echo "$out" | rg -o 'gcloud auth[^ ]*.*' | head -1)" ; return 1 ;;
    2) echo "preflight: no account logged in" ; return 1 ;;
    3) echo "preflight: gcloud not installed / not on PATH" ; return 1 ;;
    *) echo "preflight: unexpected exit $rc" ; return 1 ;;
  esac
}

check_ref_exists() {
  local repo="$2" ref="$3"
  [ -n "$ref" ] || { echo "no ref pinned; wrapper decides"; return 0; }
  if git -C "$repo" cat-file -e "${ref}^{commit}" 2>/dev/null; then
    echo "$ref resolves in $repo"; return 0
  fi
  echo "$ref does not resolve in $repo"; return 1
}

check_tests_green() {
  local repo="$2"
  [ -f "$repo/package.json" ] || { echo "no package.json; skipped"; return 0; }
  local out; out=$(cd "$repo" && npm test --silent 2>&1 | tail -3)
  if [ $? -eq 0 ]; then echo "npm test passed: ${out##*$'\n'}"; return 0; fi
  echo "npm test failed: ${out##*$'\n'}"; return 1
}

check_clean_tree() {
  local repo="$2"
  local d; d=$(git -C "$repo" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  [ "$d" = "0" ] && { echo "tree clean"; return 0; }
  echo "$d uncommitted change(s) — deploying something not in git"; return 1
}

# --- post-checks: they ask the RUNNING service, not the build ---------------

check_health_200() {
  local u; u=$(_dq_url_for "$4"); [ -n "$u" ] || { echo "no url registered"; return 1; }
  local c; c=$(curl -s -o /dev/null -m 20 -w '%{http_code}' "$u/health")
  [ "$c" = "200" ] && { echo "$u/health -> 200"; return 0; }
  echo "$u/health -> $c"; return 1
}

# The load-bearing one: does the thing that is RUNNING serve the sha we asked
# for? This is what catches a build that quietly deployed something else.
check_build_info_matches_ref() {
  local ref="$3" u; u=$(_dq_url_for "$4"); [ -n "$u" ] || { echo "no url registered"; return 1; }
  local served; served=$(curl -s -m 20 "$u/build-info" | jq -r '.commit // empty' 2>/dev/null)
  [ -n "$served" ] || { echo "$u/build-info gave no commit"; return 1; }
  [ -z "$ref" ] && { echo "serving $served (no ref pinned to compare)"; return 0; }
  case "$ref" in "$served"*) echo "serving $served, matches requested $ref"; return 0 ;; esac
  case "$served" in "$ref"*) echo "serving $served, matches requested $ref"; return 0 ;; esac
  echo "REQUESTED $ref BUT SERVING $served"; return 1
}

check_no_private_jwks() {
  local u; u=$(_dq_url_for "$4"); [ -n "$u" ] || { echo "no url registered"; return 1; }
  local n; n=$(curl -s -m 20 "$u/.well-known/jwks.json" \
    | jq -r '[.keys[]?|keys[]]|map(select(.=="d" or .=="p" or .=="q" or .=="dp" or .=="dq" or .=="qi"))|length' 2>/dev/null)
  [ "$n" = "0" ] && { echo "jwks carries public halves only"; return 0; }
  echo "JWKS EXPOSES ${n:-?} PRIVATE COMPONENT(S)"; return 1
}

check_unauth_refused() {
  local u; u=$(_dq_url_for "$4"); [ -n "$u" ] || { echo "no url registered"; return 1; }
  local c; c=$(curl -s -o /dev/null -m 20 -w '%{http_code}' "$u/me")
  case "$c" in 401|403) echo "/me without a bearer -> $c"; return 0 ;; esac
  echo "/me without a bearer -> $c, expected a refusal"; return 1
}

# Born from a real incident: a ticket asked for f3a9ff9, the wrapper deployed the
# working tree's HEAD (8b7f56d), and build-info-matches-ref caught it AFTER the
# deploy. `ref` is an expectation, not an instruction — the wrapper decides what
# ships. So assert the expectation BEFORE spending a deploy, and fail closed.
check_head_matches_ref() {
  local repo="$2" ref="$3"
  [ -n "$ref" ] || { echo "no ref pinned; the wrapper's HEAD is whatever ships"; return 0; }
  local head; head=$(git -C "$repo" rev-parse --short HEAD 2>/dev/null)
  [ -n "$head" ] || { echo "cannot read HEAD in $repo"; return 1; }
  case "$ref" in "$head"*) echo "HEAD is $head, matches requested $ref"; return 0 ;; esac
  case "$head" in "$ref"*) echo "HEAD is $head, matches requested $ref"; return 0 ;; esac
  echo "HEAD is $head BUT THE TICKET ASKS FOR $ref — the wrapper ships HEAD, so this would deploy the wrong thing"
  return 1
}

run_check() {
  local name="$1"
  case "$name" in
    gcloud-alive)            check_gcloud_alive "$@" ;;
    ref-exists)              check_ref_exists "$@" ;;
    head-matches-ref)        check_head_matches_ref "$@" ;;
    tests-green)             check_tests_green "$@" ;;
    clean-tree)              check_clean_tree "$@" ;;
    health-200)              check_health_200 "$@" ;;
    build-info-matches-ref)  check_build_info_matches_ref "$@" ;;
    no-private-jwks)         check_no_private_jwks "$@" ;;
    unauth-refused)          check_unauth_refused "$@" ;;
    *) echo "unknown check '$name' — checks are named, not free shell"; return 1 ;;
  esac
}
