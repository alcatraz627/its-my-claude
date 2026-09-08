"""How long since the owner last typed in a session, read from its transcript.

Prints the seconds since the last prompt a PERSON typed: a user record with
string or text content that is not a cron wake, a heartbeat, a task
notification, a system reminder or a slash-command echo. Prints "unknown" when
no such record carries a timestamp. Two callers share this so their idea of
"the owner is mid-conversation" cannot drift: speculative-atone-stop.sh (the
gate waits for quiet) and hinters/41-wake-fence.sh (a wake picks nothing while
he is talking).

Usage: python3 owner-quiet.py <transcript.jsonl> [tail-lines]
"""
import datetime, json, sys, time

MACHINE = ("Wake check", "Heartbeat", "<task-notification", "[SYSTEM", "Caveat:",
           "<local-command", "<system-reminder", "<command-name>", "Stop hook feedback:",
           "Base directory for this skill:", "Another Claude session sent")

def main():
    path = sys.argv[1]
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 600
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            lines = f.readlines()[-n:]
    except OSError:
        print("unknown"); return
    last = None
    for l in lines:
        try: r = json.loads(l)
        except Exception: continue
        if r.get("type") != "user": continue
        c = (r.get("message") or {}).get("content")
        if isinstance(c, str): t = c
        elif isinstance(c, list):
            t = " ".join(b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text")
            if not t: continue
        else: continue
        if t.lstrip().startswith(MACHINE): continue
        if r.get("timestamp"): last = r["timestamp"]
    if last is None:
        print("unknown"); return
    try:
        dt = datetime.datetime.fromisoformat(str(last).replace("Z", "+00:00"))
        print(int(time.time() - dt.timestamp()))
    except Exception:
        print("unknown")

if __name__ == "__main__":
    main()
