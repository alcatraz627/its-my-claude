#!/usr/bin/env python3
"""P1 of the register-friction sweep: (agent-output, owner-reply) pairs.

Walks each manifested transcript and emits one row per HUMAN owner message
that follows an assistant text message, with mechanical features on both
sides. Recall-first: nothing here judges friction; it measures and records
so P2 can cut. Machine-dispatched prompts (promptSource sdk/system) and
scaffolding-marker payloads are skipped using the vocab sweep's proven list."""
import json, os, re, sys
from datetime import datetime

RUN = sys.argv[1]
SKIP = ('<system-reminder>', '[SYSTEM NOTIFICATION', '<command-name>', '<local-command',
        'Caveat: The messages below', '[Request interrupted', 'hook additional context',
        '<task-notification>', 'This is how Claude Code surfaces',
        'This session is being continued from a previous conversation',
        'Base directory for this skill', '<command-message>', '<command-args>',
        '<teammate-message', 'Another Claude session sent a message',
        'Stop hook feedback', '[stop hook feedback]', 'treat as your directive',
        'Goal check-in:', 'Wake check.', 'DEADLINE CHECK', '=== CHECKPOINT',
        '[ctx-signal]', '[persisted-output]', 'task-notification')
MARKERS = re.compile(r'(?i)\b(again|sigh|ugh|wtf|stop|why did|why are|not what|no[,.] |confus|dense|salad|essay|skim|simpler|plainly|too (long|much)|i asked|i said|re-?read)\b')

def blocks(m):
    c = m.get('content')
    if isinstance(c, str): return c
    if isinstance(c, list):
        return '\n'.join(b.get('text','') for b in c if isinstance(b, dict) and b.get('type')=='text')
    return ''

def toks(s): return set(re.findall(r'[a-z]{3,}', s.lower()))
def overlap(a, b):
    A, B = toks(a), toks(b)
    return round(len(A & B) / max(1, len(A)), 3) if A else 0.0

def feats_agent(t):
    return {"alen": len(t), "alines": t.count('\n')+1,
            "bullets": len(re.findall(r'^\s*[-*•] ', t, re.M)),
            "tabrows": len(re.findall(r'^\|', t, re.M)),
            "bold": t.count('**')//2, "headers": len(re.findall(r'^#+ ', t, re.M)),
            "qmarks": t.count('?'), "fences": t.count('```')//2,
            "boxch": sum(t.count(c) for c in '─│┌┐└')}

def parse_ts(s):
    try: return datetime.fromisoformat(s.replace('Z','+00:00')).timestamp()
    except Exception: return None

out = open(f"{RUN}/corpus/pairs.jsonl", "w"); npairs = nfiles = 0
for line in open(f"{RUN}/manifest/transcripts.jsonl"):
    man = json.loads(line); nfiles += 1
    last_a = None; last_a_ts = None; last_a_model = None; prev_owner = ""
    idx = -1; sess = None
    try:
        for raw in open(man["path"], errors="replace"):
            try: rec = json.loads(raw)
            except Exception: continue
            idx += 1
            t = rec.get('type')
            if t == 'assistant':
                txt = blocks(rec.get('message', {}))
                if txt.strip():
                    last_a = txt; last_a_ts = parse_ts(rec.get('timestamp',''))
                    last_a_model = rec.get('message',{}).get('model','')
                    sess = rec.get('sessionId', sess)
            elif t == 'user':
                if rec.get('promptSource') in ('sdk','system'): continue
                if rec.get('isSidechain'): continue
                txt = blocks(rec.get('message', {}))
                via_cmd = None
                cm = re.search(r'<command-name>/?([\w-]+)</command-name>', txt)
                if cm:
                    # owner-typed slash command: the args are the owner's words
                    am = re.search(r'<command-args>(.*?)</command-args>', txt, re.S)
                    args = (am.group(1).strip() if am else '')
                    if len(args) < 15: continue
                    via_cmd = cm.group(1); txt = args
                elif not txt.strip() or any(m in txt for m in SKIP):
                    continue
                if last_a is None or len(last_a) < 400: prev_owner = txt; continue
                ots = parse_ts(rec.get('timestamp',''))
                row = {"path": man["path"], "project": man["project"], "session": sess,
                       "idx": idx, "ts": rec.get('timestamp',''), "model": last_a_model,
                       **feats_agent(last_a),
                       "olen": len(txt), "markers": bool(MARKERS.search(txt)),
                       "marker_hits": MARKERS.findall(txt)[:5],
                       "latency_s": round(ots-last_a_ts) if ots and last_a_ts else None,
                       "reask": overlap(prev_owner, txt) if prev_owner else 0.0, "via_command": via_cmd,
                       "quoteback": overlap(txt, last_a),
                       "agent_tail": last_a[-1500:], "owner_text": txt[:1500]}
                out.write(json.dumps(row)+"\n"); npairs += 1
                prev_owner = txt; last_a = None
    except Exception as e:
        print(f"skip {man['path']}: {e}", file=sys.stderr)
print(f"files={nfiles} pairs={npairs}")
