#!/usr/bin/env bash
# friction-audit.sh — the weekly register-friction audit (regfric D4,
# owner-approved 2026-08-20). Reruns the proven sweep pipeline on the trailing
# 7 days: extract (agent-output, owner-reply) pairs, classify on the gemini
# lane, and append one summary row to ~/.claude/style/friction-ledger.jsonl.
# This is the loop that measures whether the register gates are working, and
# measures the gates themselves (fire/heed counts from counter-gate.jsonl).
# Read-only over transcripts; ~$1-2 per run, gemini flash only.
# Usage: friction-audit.sh [--days 7] [--dry]  (dry: extract + count, no model)
set -uo pipefail
DAYS=7; DRY=0
while [ $# -gt 0 ]; do case "$1" in
  --days) DAYS="$2"; shift 2;; --dry) DRY=1; shift;; *) shift;; esac; done
RUN="$HOME/.claude/style/sweep/$(date +%Y%m%d)-audit"
mkdir -p "$RUN/manifest" "$RUN/corpus" "$RUN/candidates" "$RUN/classified"
python3 - "$RUN" "$DAYS" <<'PY'
import glob, json, os, sys, time
run, days = sys.argv[1], int(sys.argv[2])
cutoff = time.time() - days*86400
with open(f"{run}/manifest/transcripts.jsonl", "w") as out:
    for p in glob.glob(os.path.expanduser("~/.claude/projects/*/*.jsonl")):
        st = os.stat(p)
        if st.st_mtime < cutoff or st.st_size < 10240: continue
        out.write(json.dumps({"path": p, "project": os.path.basename(os.path.dirname(p))}) + "\n")
PY
python3 "$HOME/.claude/scripts/style/friction-extract.py" "$RUN"
np=$(wc -l < "$RUN/corpus/pairs.jsonl" | tr -d ' ')
[ "$np" -gt 0 ] || { echo "friction-audit: no pairs; nothing to audit"; exit 0; }
python3 - "$RUN" <<'PY'
import json, sys
run = sys.argv[1]
rows = [json.loads(l) for l in open(f"{run}/corpus/pairs.jsonl")]
for i, r in enumerate(rows): r["id"] = f"w{i:03d}"
SH = 35
for n in range(0, len(rows), SH):
    with open(f"{run}/candidates/shard-{n//SH:02d}.jsonl", "w") as f:
        for r in rows[n:n+SH]:
            f.write(json.dumps({"id": r["id"], "via_command": r.get("via_command"),
                "feats": {k: r[k] for k in ("alen","olen","reask","markers")},
                "agent_tail": r["agent_tail"][-900:], "owner_text": r["owner_text"][:600]}) + "\n")
PY
if [ "$DRY" = 1 ]; then echo "friction-audit --dry: $np pairs extracted to $RUN"; exit 0; fi
PROMPT="$HOME/.claude/style/sweep/20260820-regfric-fc30/scripts/l1-prompt.txt"
for sh in "$RUN"/candidates/shard-*.jsonl; do
  n=$(basename "$sh" .jsonl)
  for attempt in 1 2; do
    out=$(cat "$sh" | lm gemini "$(cat "$PROMPT")" --json --timeout 160 2>/dev/null) || true
    parsed=$(printf '%s' "$out" | python3 -c "
import json, sys
try:
    raw = json.load(sys.stdin)
    good = [json.loads(l) for l in raw.get('text','').splitlines() if l.strip().startswith('{')]
    print(json.dumps(good) if len(good) >= 1 else '')
except Exception: print('')")
    [ -n "$parsed" ] && { printf '%s' "$parsed" > "$RUN/classified/$n.done.json"; break; }
  done
done
python3 - "$RUN" <<'PY'
import json, sys, glob, collections, os, time
run = sys.argv[1]
rows = [r for f in glob.glob(f"{run}/classified/*.done.json") for r in json.load(open(f))]
c = collections.Counter(r["label"] for r in rows)
total = sum(c.values()); fr = total - c.get("fine", 0)
# gate telemetry for the same window
cg = os.path.expanduser("~/.claude/logs/counter-gate.jsonl"); breaches = rowsn = 0
cutoff = time.time() - 7*86400
if os.path.exists(cg):
    for l in open(cg):
        try:
            r = json.loads(l); rowsn += 1; breaches += r.get("breach") is True
        except Exception: pass
summary = {"ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "pairs": total,
    "friction": fr, "rate": round(fr/max(1,total), 3), "labels": dict(c),
    "gate_rows": rowsn, "gate_breaches": breaches, "run": run}
with open(os.path.expanduser("~/.claude/style/friction-ledger.jsonl"), "a") as f:
    f.write(json.dumps(summary) + "\n")
print(json.dumps(summary, indent=1))
PY
