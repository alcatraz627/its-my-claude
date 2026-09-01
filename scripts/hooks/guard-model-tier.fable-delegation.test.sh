#!/usr/bin/env bash
# Job 2b: a fable lane may not delegate authoring; it may delegate review.
set -uo pipefail
H="$HOME/.claude/scripts/hooks/guard-model-tier.sh"
T=$(mktemp -d); pass=0; fail=0
ck(){ if [ "$2" = "$3" ]; then echo "  ok    $1"; pass=$((pass+1)); else echo "  FAIL  $1 (got $3 want $2)"; fail=$((fail+1)); fi; }
run(){ # <parent-model> <sub-model> <prompt>
python3 - "$1" "$2" "$3" "$T" <<'PY'
import json,sys
p,m,pr,t=sys.argv[1:5]
open(f"{t}/tr.jsonl","w").write(json.dumps({"type":"assistant","message":{"role":"assistant","model":p,"content":[]}})+"\n")
open(f"{t}/in.json","w").write(json.dumps({"tool_name":"Agent","transcript_path":f"{t}/tr.jsonl",
  "session_id":"t","tool_input":{"model":m,"prompt":pr}}))
PY
bash "$H" < "$T/in.json" 2>/dev/null | rg -c 'FABLE MAY NOT DELEGATE' 2>/dev/null || echo 0; }

echo "dispatcher = fable"
ck "authoring docs -> BLOCK"        1 "$(run claude-fable-5 sonnet 'write the ingestion documentation for the console')"
ck "draft a spec -> BLOCK"          1 "$(run claude-fable-5 sonnet 'draft the design spec for the export module')"
ck "implement -> BLOCK"             1 "$(run claude-fable-5 opus 'implement the exporter and refactor the writer')"
ck "review -> allowed"              0 "$(run claude-fable-5 sonnet 'review the docs and find what is wrong')"
ck "verify -> allowed"              0 "$(run claude-fable-5 sonnet 'verify the export ran and reproduce the failure')"
ck "adversarial on docs -> allowed" 0 "$(run claude-fable-5 opus 'adversarial gate: break this documentation set')"
ck "cheap grep -> allowed"          0 "$(run claude-fable-5 haiku 'find every caller of writeExport')"
echo "dispatcher = opus / sonnet (must be untouched)"
ck "opus -> sonnet authoring"       0 "$(run claude-opus-5 sonnet 'write the ingestion documentation')"
ck "opus -> fable authoring"        0 "$(run claude-opus-5 fable 'write the ingestion documentation')"
ck "sonnet -> sonnet authoring"     0 "$(run claude-sonnet-5 sonnet 'write the ingestion documentation')"
rm -rf "$T"
echo "---- pass=$pass fail=$fail ----"; [ "$fail" -eq 0 ]
