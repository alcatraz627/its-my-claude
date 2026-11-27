#!/usr/bin/env python3
"""Pairs each long agent reply with the owner's next message, for the weekly register-friction audit.

Walks every transcript in a run's manifest and writes one row per owner message that follows an
assistant text message of 400+ characters, with mechanical features of both sides. Nothing here
judges friction; it measures so a later classifier can.

Who counts as the owner comes from the transcript's own origin fields (turnOrigin, promptSource,
isMeta, origin.kind), read through transcript_origin.classify. Most user-role records are written by
machines (hooks, task notifications, skills, peers, timers), so wording is never used to tell them
apart, except for old records that predate those fields.

Usage: friction-extract.py RUN_DIR   (reads RUN_DIR/manifest/transcripts.jsonl, writes RUN_DIR/corpus/pairs.jsonl)
"""
import json, os, re, sys
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from transcript_origin import classify

# Only consulted for records with no origin fields at all (kind legacy_human).
LEGACY_SKIP = ('<system-reminder>', '[SYSTEM NOTIFICATION', '<command-name>', '<local-command',
               'Caveat: The messages below', '[Request interrupted', 'hook additional context',
               '<task-notification>', 'This is how Claude Code surfaces',
               'This session is being continued from a previous conversation',
               'Base directory for this skill', '<command-message>', '<command-args>',
               '<teammate-message', 'Another Claude session sent a message',
               'Stop hook feedback', '[stop hook feedback]', 'treat as your directive',
               'Goal check-in:', 'Wake check.', 'DEADLINE CHECK', '=== CHECKPOINT',
               '[ctx-signal]', '[persisted-output]', 'task-notification')
MARKERS = re.compile(r'(?i)\b(again|sigh|ugh|wtf|stop|why did|why are|not what|no[,.] |confus|dense|salad|essay|skim|simpler|plainly|too (long|much)|i asked|i said|re-?read)\b')
MIN_AGENT_LEN = 400
MIN_COMMAND_ARGS = 15


def blocks(m):
    c = m.get('content')
    if isinstance(c, str): return c
    if isinstance(c, list):
        return '\n'.join(b.get('text', '') for b in c if isinstance(b, dict) and b.get('type') == 'text')
    return ''


def toks(s): return set(re.findall(r'[a-z]{3,}', s.lower()))


def overlap(a, b):
    A, B = toks(a), toks(b)
    return round(len(A & B) / max(1, len(A)), 3) if A else 0.0


def feats_agent(t):
    return {"alen": len(t), "alines": t.count('\n') + 1,
            "bullets": len(re.findall(r'^\s*[-*•] ', t, re.M)),
            "tabrows": len(re.findall(r'^\|', t, re.M)),
            "bold": t.count('**') // 2, "headers": len(re.findall(r'^#+ ', t, re.M)),
            "qmarks": t.count('?'), "fences": t.count('```') // 2,
            "boxch": sum(t.count(c) for c in '─│┌┐└')}


def parse_ts(s):
    try: return datetime.fromisoformat(s.replace('Z', '+00:00')).timestamp()
    except Exception: return None


def owner_words(rec):
    """The owner's own words in this record as (kind, text, via_command), or None when someone else wrote it.

    A slash command counts through its arguments, which the owner typed; the command wrapper does not.
    """
    if rec.get('isSidechain') or rec.get('promptSource') in ('sdk', 'system'):
        return None
    kind, text, _queued = classify(rec)
    if kind == 'command':
        cm = re.search(r'<command-name>/?([\w-]+)</command-name>', text)
        am = re.search(r'<command-args>(.*?)</command-args>', text, re.S)
        args = am.group(1).strip() if am else ''
        if not cm or len(args) < MIN_COMMAND_ARGS: return None
        return kind, args, cm.group(1)
    if kind == 'human':
        return (kind, text, None) if text else None
    if kind == 'legacy_human':
        if not text or any(m in text for m in LEGACY_SKIP): return None
        return kind, text, None
    return None


def extract(manifest_path, out):
    """Write one pair row per owner reply to `out`; return (files, pairs)."""
    npairs = nfiles = 0
    with open(manifest_path) as mf:
        manifest = [json.loads(line) for line in mf if line.strip()]
    for man in manifest:
        nfiles += 1
        last_a = None; last_a_ts = None; last_a_model = None; prev_owner = ""
        idx = -1; sess = None
        try:
            with open(man["path"], errors="replace") as tf:
                lines = tf.readlines()
            for lineno, raw in enumerate(lines, 1):
                try: rec = json.loads(raw)
                except Exception: continue
                idx += 1
                t = rec.get('type')
                if t == 'assistant':
                    txt = blocks(rec.get('message', {}))
                    if txt.strip():
                        last_a = txt; last_a_ts = parse_ts(rec.get('timestamp', ''))
                        last_a_model = rec.get('message', {}).get('model', '')
                        sess = rec.get('sessionId', sess)
                elif t in ('user', 'attachment'):
                    words = owner_words(rec)
                    if words is None: continue
                    kind, txt, via_cmd = words
                    if last_a is None or len(last_a) < MIN_AGENT_LEN: prev_owner = txt; continue
                    ots = parse_ts(rec.get('timestamp', ''))
                    row = {"path": man["path"], "project": man["project"], "session": sess,
                           "idx": idx, "line": lineno, "origin": kind, "ts": rec.get('timestamp', ''),
                           "model": last_a_model,
                           **feats_agent(last_a),
                           "olen": len(txt), "markers": bool(MARKERS.search(txt)),
                           "marker_hits": MARKERS.findall(txt)[:5],
                           "latency_s": round(ots - last_a_ts) if ots and last_a_ts else None,
                           "reask": overlap(prev_owner, txt) if prev_owner else 0.0, "via_command": via_cmd,
                           "quoteback": overlap(txt, last_a),
                           "agent_tail": last_a[-1500:], "owner_text": txt[:1500]}
                    out.write(json.dumps(row) + "\n"); npairs += 1
                    prev_owner = txt; last_a = None
        except Exception as e:
            print(f"skip {man['path']}: {e}", file=sys.stderr)
    return nfiles, npairs


if __name__ == "__main__":
    run = sys.argv[1]
    with open(f"{run}/corpus/pairs.jsonl", "w") as out:
        nfiles, npairs = extract(f"{run}/manifest/transcripts.jsonl", out)
    print(f"files={nfiles} pairs={npairs}")
