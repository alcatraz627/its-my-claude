#!/usr/bin/env python3
"""P1 of the vocab sweep: extract the user's actual words from transcripts.

Reads the P0 manifest, walks each transcript, and emits one JSONL row per
HUMAN user message: {ts, project, session, msg_idx, text, lookback, lookahead}.
Purity is the whole game here: transcript "user" rows include tool results,
system reminders, hook injections, and command scaffolding that are not the
user's words. Everything mechanical that could poison the vocabulary metric
is stripped or skipped here, once, so no later phase re-litigates it.

Usage: sweep-extract.py <run-dir>
"""
import json, os, re, sys

RUN = sys.argv[1]
CODE_FENCE = re.compile(r'```.*?```', re.S)
INLINE_CODE = re.compile(r'`[^`]*`')
URL = re.compile(r'https?://\S+')
PATHLIKE = re.compile(r'(?:~|/)[\w.~/-]{2,}')
SENTENCE_PUNCT = re.compile(r'[.!?]')

SKIP_MARKERS = (
    '<system-reminder>', '[SYSTEM NOTIFICATION', '<command-name>',
    '<local-command', 'Caveat: The messages below', '[Request interrupted',
    'hook additional context', '<task-notification>', 'This is how Claude Code surfaces',
    # harness-generated payloads riding the user role: assistant-voiced, not the user
    'This session is being continued from a previous conversation',
    'Base directory for this skill', '<command-message>', '<command-args>',
    '<teammate-message', 'Another Claude session sent a message',
    'Stop hook feedback', '[stop hook feedback]', 'treat as your directive',
)
IMAGE_MARKER = re.compile(r'\[Image: [^\]]*\]')

def clean(text):
    text = IMAGE_MARKER.sub(' ', text)
    text = CODE_FENCE.sub(' ', text)
    text = INLINE_CODE.sub(' ', text)
    text = URL.sub(' ', text)
    text = PATHLIKE.sub(' ', text)
    # drop pasted blocks: runs of >15 lines with no sentence punctuation
    out, run = [], []
    for line in text.splitlines():
        run.append(line)
        if SENTENCE_PUNCT.search(line):
            out.extend(run); run = []
    if len(run) <= 15: out.extend(run)
    return '\n'.join(out).strip()

def text_blocks(msg):
    c = msg.get('content')
    if isinstance(c, str): return c
    if isinstance(c, list):
        return '\n'.join(b.get('text', '') for b in c if isinstance(b, dict) and b.get('type') == 'text')
    return ''

def human_user_text(rec):
    if rec.get('type') != 'user': return None
    if rec.get('promptSource') in ('sdk', 'system'): return None  # machine-dispatched
    m = rec.get('message', {})
    c = m.get('content')
    if isinstance(c, list) and any(isinstance(b, dict) and b.get('type') == 'tool_result' for b in c):
        return None  # tool results ride the user role; not human words
    t = text_blocks(m)
    if not t.strip(): return None
    if any(s in t for s in SKIP_MARKERS): return None
    if t.lstrip().startswith(('<', '{')): return None  # scaffolding/JSON, not prose
    return t

n_out = 0
with open(f'{RUN}/manifest/transcripts.jsonl') as mf:
    manifest = [json.loads(l) for l in mf]
by_project = {}
for entry in manifest:
    recs = []
    with open(entry['path'], errors='replace') as f:
        for i, line in enumerate(f):
            try: recs.append((i, json.loads(line)))
            except json.JSONDecodeError: continue
    # headless transcripts (claude -p / SDK runs): every "user" row is a
    # machine prompt (juror dispatches, watcher judgments) — skip the file
    if any(r.get('entrypoint') == 'sdk-cli' for _, r in recs[:5]):
        continue
    rows = []
    for idx, (i, rec) in enumerate(recs):
        t = human_user_text(rec)
        if t is None: continue
        cleaned = clean(t)
        if len(cleaned) < 3: continue
        # nearest assistant TEXT either side; tool-call-only assistant records
        # carry no text, so keep scanning past them (they dominated the first run)
        lookback = lookahead = ''
        for j in range(idx - 1, max(idx - 13, -1), -1):
            if recs[j][1].get('type') == 'assistant':
                t2 = text_blocks(recs[j][1].get('message', {})).strip()
                if t2: lookback = t2[-400:]; break
        for j in range(idx + 1, min(idx + 13, len(recs))):
            if recs[j][1].get('type') == 'assistant':
                t2 = text_blocks(recs[j][1].get('message', {})).strip()
                if t2: lookahead = t2[:400]; break
        rows.append({'ts': rec.get('timestamp', ''), 'project': entry['project'],
                     'session': os.path.basename(entry['path'])[:8], 'msg_idx': i,
                     'text': cleaned, 'lookback': lookback, 'lookahead': lookahead})
    if rows:
        by_project.setdefault(entry['project'], []).extend(rows)
        n_out += len(rows)

# template dedup: long text repeated near-verbatim across many sessions is
# injected scaffolding (hook digests, rubrics), not the user; short genuine
# idioms ("keep going") survive via the length floor
from collections import defaultdict as _dd
groups = _dd(list)
for proj, rows in by_project.items():
    for r in rows:
        key = ' '.join(r['text'].lower().split())[:240]
        groups[key].append((proj, r))
dropped = 0
template_keys = {k for k, v in groups.items()
                 if len(k) >= 200 and len(set((p, r['session']) for p, r in v)) >= 5}
for proj in list(by_project):
    kept = [r for r in by_project[proj]
            if ' '.join(r['text'].lower().split())[:240] not in template_keys]
    dropped += len(by_project[proj]) - len(kept)
    by_project[proj] = kept
    if not kept: del by_project[proj]
n_out -= dropped
print(f'template dedup: dropped {dropped} rows across {len(template_keys)} template groups')

os.makedirs(f'{RUN}/corpus', exist_ok=True)
for proj, rows in by_project.items():
    with open(f'{RUN}/corpus/{proj}.jsonl', 'w') as f:
        for r in rows: f.write(json.dumps(r) + '\n')
print(f'extracted {n_out} human user messages across {len(by_project)} projects')
