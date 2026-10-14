#!/usr/bin/env bash
# Tests for adapter.sh: a decay verdict on a hook with heed rows becomes a TUNE or
# PRUNE proposal; on a hook with none (heed UNMEASURED) the verdict is withheld and
# an INSTRUMENT proposal is filed instead.
set -uo pipefail
ADAPTER="$(cd "$(dirname "$0")" && pwd)/adapter.sh"
T=$(mktemp -d)
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

cat > "$T/propose.sh" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$T/filed.txt"
EOF
chmod +x "$T/propose.sh"
printf '%s\n' '{"id":"heed-1","ts":"2026-10-01T00:00:00Z","kind":"heed","hook_id":"measured-hook","heeded":"false","ref":"measured-hook:abc"}' \
              '{"id":"warn-1","ts":"2026-10-01T00:00:00Z","kind":"warn","hook_id":"unmeasured-hook","fired":1,"heeded":"unknown"}' > "$T/warn.jsonl"

run() { # run <slug> <action> → files into $T/filed.txt
  : > "$T/seen"; : > "$T/filed.txt"
  jq -nc --arg s "$1" --arg a "$2" '{insights:[{type:"decay_candidate", slug:$s, action:$a, rationale:"fires a lot, never heeded"}]}' \
    | PROPOSE_SH="$T/propose.sh" ADAPTER_SEEN="$T/seen" WARN_EVENTS_FILE="$T/warn.jsonl" bash "$ADAPTER" >/dev/null 2>&1
  cat "$T/filed.txt"
}

out=$(run measured-hook remove)
case "$out" in *"REMOVE hook 'measured-hook'"*) ok "measured hook: the remove verdict is filed" ;; *) bad "measured hook: the remove verdict is filed: $out" ;; esac

out=$(run unmeasured-hook remove)
case "$out" in
  *"INSTRUMENT hook 'unmeasured-hook'"*"UNMEASURED"*) ok "unmeasured hook: an INSTRUMENT proposal is filed" ;;
  *) bad "unmeasured hook: an INSTRUMENT proposal is filed: $out" ;;
esac
case "$out" in *"REMOVE hook"*|*"TUNE hook"*) bad "unmeasured hook: no remove or tune verdict may be filed" ;; *) ok "unmeasured hook: no remove or tune verdict is filed" ;; esac

out=$(run never-fired-hook tune)
case "$out" in *"INSTRUMENT hook 'never-fired-hook'"*) ok "a hook absent from telemetry is also unmeasured" ;; *) bad "a hook absent from telemetry is also unmeasured: $out" ;; esac

# A mention of a measured slug inside another row must not count as its heed rows.
printf '%s\n' '{"id":"heed-2","ts":"2026-10-01T00:00:00Z","kind":"heed","hook_id":"other","heeded":"true","ref":"unmeasured-hook:x"}' >> "$T/warn.jsonl"
out=$(run unmeasured-hook remove)
case "$out" in *"INSTRUMENT hook 'unmeasured-hook'"*) ok "a slug named only in another hook's ref is still unmeasured" ;; *) bad "a slug named only in another hook's ref is still unmeasured: $out" ;; esac

echo "---- pass=$pass fail=$fail"
trash "$T" 2>/dev/null || true
[ $fail -eq 0 ]
