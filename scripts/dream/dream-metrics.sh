#!/usr/bin/env bash
# dream-metrics.sh — extract actionable session-level metrics from events.jsonl
#
# Produces four signal types:
#   1. Session quality scores — productivity metrics per session
#   2. Recurring error taxonomy — clustered tool failures
#   3. Topic drift detection — project/focus shifts over time
#   4. Collaboration style — correction vs confirmation patterns
#
# Output: ~/.claude/subconscious/dreams/dream-metrics.json
# Called by: post-wake.sh, or manually.

set -euo pipefail

EVENTS_FILE="${HOME}/.claude/events.jsonl"
OUTPUT_FILE="${HOME}/.claude/subconscious/dreams/dream-metrics.json"

mkdir -p "$(dirname "$OUTPUT_FILE")"

[[ -f "$EVENTS_FILE" ]] || { echo "dream-metrics: no events file, skipping." >&2; exit 0; }

python3 - "$EVENTS_FILE" "$OUTPUT_FILE" <<'PYEOF'
import sys, json, re
from datetime import datetime, timezone
from collections import defaultdict, Counter

events_file = sys.argv[1]
output_file = sys.argv[2]

# Parse all events
events = []
with open(events_file, 'r') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            pass

if not events:
    print("dream-metrics: no events to analyze.", file=sys.stderr)
    sys.exit(0)

# ─── 1. Session Quality Scoring ─────────────────────────────────────

sessions = defaultdict(lambda: {
    'tools': Counter(),
    'errors': 0,
    'tool_count': 0,
    'prompts': 0,
    'compacts': 0,
    'start': None,
    'stop': None,
    'project': '',
    'cost': 0.0,
    'prompt_previews': [],
})

for ev in events:
    sid = ev.get('session_id', '')
    if not sid:
        continue
    s = sessions[sid]
    kind = ev.get('event', '')

    if kind == 'SessionStart':
        s['start'] = ev.get('ts', '')
        s['project'] = ev.get('project', '')
    elif kind == 'Stop':
        s['stop'] = ev.get('ts', '')
        cost = ev.get('cost_delta_usd')
        if cost:
            try:
                s['cost'] += float(cost)
            except (ValueError, TypeError):
                pass
    elif kind == 'PostToolUse':
        tool = ev.get('tool', 'unknown')
        s['tools'][tool] += 1
        s['tool_count'] += 1
        if ev.get('error'):
            s['errors'] += 1
    elif kind == 'UserPromptSubmit':
        s['prompts'] += 1
        preview = ev.get('prompt_preview', '')
        if preview:
            s['prompt_previews'].append(preview)
    elif kind in ('PostCompact', 'PreCompact'):
        s['compacts'] += 1

def parse_ts(ts_str):
    if not ts_str:
        return None
    try:
        return datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
    except (ValueError, AttributeError):
        return None

session_scores = []
for sid, s in sessions.items():
    tc = s['tool_count']
    if tc == 0:
        continue  # skip empty sessions

    # Quality heuristics:
    # - tool diversity (unique tools / total tools) — higher = more varied work
    # - error rate (errors / tools) — lower = cleaner execution
    # - efficiency (tools per prompt) — higher = more autonomous
    # - completion (has stop event) — finished sessions score higher

    diversity = len(s['tools']) / tc if tc else 0
    error_rate = s['errors'] / tc if tc else 0
    efficiency = tc / s['prompts'] if s['prompts'] else tc
    completed = 1.0 if s['stop'] else 0.5

    # Duration
    start_dt = parse_ts(s['start'])
    stop_dt = parse_ts(s['stop'])
    duration_min = 0
    if start_dt and stop_dt:
        duration_min = max(0, (stop_dt - start_dt).total_seconds() / 60)

    # Composite score: 0-100
    # Weights: completion (20), low errors (30), diversity (25), efficiency (25)
    score = (
        completed * 20 +
        max(0, (1 - error_rate * 5)) * 30 +  # penalize errors heavily
        min(diversity * 2, 1) * 25 +  # cap diversity contribution
        min(efficiency / 20, 1) * 25  # cap efficiency at 20 tools/prompt
    )
    score = max(0, min(100, round(score, 1)))

    session_scores.append({
        'session_id': sid,
        'project': s['project'],
        'score': score,
        'tool_count': tc,
        'error_count': s['errors'],
        'error_rate': round(error_rate, 3),
        'diversity': round(diversity, 3),
        'efficiency': round(efficiency, 1),
        'prompts': s['prompts'],
        'compactions': s['compacts'],
        'duration_min': round(duration_min, 1),
        'completed': bool(s['stop']),
        'start': s['start'] or '',
    })

session_scores.sort(key=lambda x: x['score'], reverse=True)

# Summary stats
scores = [s['score'] for s in session_scores]
avg_score = round(sum(scores) / len(scores), 1) if scores else 0
top_sessions = session_scores[:5]
bottom_sessions = session_scores[-5:] if len(session_scores) > 5 else []

# ─── 2. Recurring Error Taxonomy ────────────────────────────────────

error_events = [e for e in events if e.get('error') and e.get('event') == 'PostToolUse']
error_by_tool = Counter()
error_by_project = Counter()
for e in error_events:
    error_by_tool[e.get('tool', 'unknown')] += 1
    error_by_project[e.get('project', 'unknown')] += 1

error_taxonomy = {
    'total_errors': len(error_events),
    'by_tool': dict(error_by_tool.most_common(10)),
    'by_project': dict(error_by_project.most_common(10)),
    'error_rate_overall': round(len(error_events) / len([
        e for e in events if e.get('event') == 'PostToolUse'
    ]), 4) if any(e.get('event') == 'PostToolUse' for e in events) else 0,
}

# ─── 3. Topic Drift Detection ───────────────────────────────────────

# Track project switches over time (ordered by session start)
timed_sessions = [(s['start'], s['project'], s['session_id'])
                  for s in session_scores if s['start'] and s['project']]
timed_sessions.sort()

# Detect drift: consecutive sessions on different projects
project_sequence = []
for ts, proj, sid in timed_sessions:
    project_sequence.append({'ts': ts, 'project': proj, 'session_id': sid})

# Recent focus: last 10 sessions
recent = project_sequence[-10:] if len(project_sequence) >= 10 else project_sequence
recent_projects = Counter(s['project'] for s in recent)
primary_focus = recent_projects.most_common(1)[0][0] if recent_projects else 'unknown'

# Drift events: consecutive project switches
drift_events = []
for i in range(1, len(project_sequence)):
    if project_sequence[i]['project'] != project_sequence[i-1]['project']:
        drift_events.append({
            'ts': project_sequence[i]['ts'],
            'from': project_sequence[i-1]['project'],
            'to': project_sequence[i]['project'],
        })

# Drift rate: switches per session
drift_rate = round(len(drift_events) / len(project_sequence), 3) if project_sequence else 0

topic_drift = {
    'primary_focus': primary_focus,
    'recent_projects': dict(recent_projects),
    'drift_rate': drift_rate,
    'total_switches': len(drift_events),
    'recent_switches': drift_events[-5:] if drift_events else [],
}

# ─── 4. Collaboration Style Metrics ─────────────────────────────────

# Analyze prompt previews for correction vs confirmation patterns
correction_patterns = [
    r'\bno\b', r'\bnot\b', r'\bdon\'?t\b', r'\bstop\b', r'\bwrong\b',
    r'\brevert\b', r'\bundo\b', r'\bfix\b', r'\bactually\b',
    r'\binstead\b', r'\bwhy did\b', r'\bshould(n\'?t| not)\b',
]
confirmation_patterns = [
    r'\byes\b', r'\bgood\b', r'\bperfect\b', r'\bgreat\b', r'\bthanks\b',
    r'\bcorrect\b', r'\bexactly\b', r'\bnice\b', r'\blgtm\b',
    r'\bkeep\s+going\b', r'\bcontinue\b', r'\bapproved?\b',
]
directive_patterns = [
    r'^(add|fix|create|update|change|remove|delete|move|rename|build|run|test|deploy|check|read|show|list)',
]

total_prompts = 0
corrections = 0
confirmations = 0
directives = 0
terse_count = 0  # < 20 chars

all_previews = []
for ev in events:
    if ev.get('event') != 'UserPromptSubmit':
        continue
    preview = ev.get('prompt_preview', '').strip()
    if not preview:
        continue
    total_prompts += 1
    all_previews.append(preview)
    lower = preview.lower()

    if len(preview) < 20:
        terse_count += 1
    if any(re.search(p, lower) for p in correction_patterns):
        corrections += 1
    if any(re.search(p, lower) for p in confirmation_patterns):
        confirmations += 1
    if any(re.search(p, lower) for p in directive_patterns):
        directives += 1

collab_style = {
    'total_prompts': total_prompts,
    'corrections': corrections,
    'confirmations': confirmations,
    'directives': directives,
    'terse_messages': terse_count,
    'correction_rate': round(corrections / total_prompts, 3) if total_prompts else 0,
    'confirmation_rate': round(confirmations / total_prompts, 3) if total_prompts else 0,
    'directive_rate': round(directives / total_prompts, 3) if total_prompts else 0,
    'terse_rate': round(terse_count / total_prompts, 3) if total_prompts else 0,
    'style_label': '',  # filled below
}

# Classify collaboration style
cr = collab_style['correction_rate']
dr = collab_style['directive_rate']
tr = collab_style['terse_rate']
if dr > 0.5 and tr > 0.3:
    collab_style['style_label'] = 'command-line'
elif cr > 0.2:
    collab_style['style_label'] = 'corrective'
elif dr > 0.3:
    collab_style['style_label'] = 'directive'
else:
    collab_style['style_label'] = 'conversational'

# ─── Output ──────────────────────────────────────────────────────────

output = {
    'generated_at': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'events_analyzed': len(events),
    'sessions_analyzed': len(session_scores),
    'session_quality': {
        'average_score': avg_score,
        'top_sessions': top_sessions,
        'bottom_sessions': bottom_sessions,
    },
    'error_taxonomy': error_taxonomy,
    'topic_drift': topic_drift,
    'collaboration_style': collab_style,
}

with open(output_file, 'w') as f:
    json.dump(output, f, indent=2)

print(f"dream-metrics: analyzed {len(events)} events across {len(session_scores)} sessions. "
      f"Avg quality: {avg_score}/100, errors: {error_taxonomy['total_errors']}, "
      f"style: {collab_style['style_label']}.", file=sys.stderr)
PYEOF
