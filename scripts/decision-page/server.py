#!/usr/bin/env python3
"""Static file server for the decision-pages registry, plus a submit endpoint.

Serves ~/.claude/assets/decision-pages over http exactly like `python -m
http.server` (directory URLs resolve to index.html), and adds one POST route:

    POST /_submit/<slug>   body: {"answer": "<the paste string>"}

which writes <slug>/.answer.json and drops <slug> from .pending.txt. That lets a
decision page hand its answer straight back to the agent that created it: the
agent watches for <slug>/.answer.json (Monitor tool or a poll) and wakes when the
human clicks Submit, instead of the human copy-pasting into chat.

Single-user, localhost-only. Started under pm2 by decision-page.sh (name
"decision-pages", port 5197). Override the port with DP_PORT.
"""
import json
import os
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote

REG = os.path.expanduser("~/.claude/assets/decision-pages")
PORT = int(os.environ.get("DP_PORT", "5197"))
PEND = os.path.join(REG, ".pending.txt")


def _clear_pending(slug):
    """Drop one slug from the pending ledger (best-effort, atomic rewrite)."""
    try:
        if not os.path.exists(PEND):
            return
        keep = [l for l in open(PEND).read().splitlines()
                if l.strip() and l.strip() != slug]
        tmp = PEND + ".srv.tmp"
        with open(tmp, "w") as f:
            f.write("\n".join(keep) + ("\n" if keep else ""))
        os.replace(tmp, PEND)
    except OSError:
        pass


class DPHandler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=REG, **k)

    def _json(self, code, obj):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        if not self.path.startswith("/_submit/"):
            return self._json(404, {"error": "no such endpoint"})
        slug = unquote(self.path[len("/_submit/"):]).strip("/").split("/")[0]
        page = os.path.join(REG, slug)
        # slug must be a real page dir directly under REG (no path traversal)
        if not slug or os.path.dirname(os.path.abspath(page)) != os.path.abspath(REG) \
                or not os.path.isdir(page):
            return self._json(404, {"error": "unknown slug"})
        n = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(n) if n else b""
        try:
            payload = json.loads(raw or b"{}")
        except ValueError:
            payload = {"answer": raw.decode("utf-8", "replace")}
        rec = {"answer": payload.get("answer", ""), "submitted_at": int(time.time())}
        tmp = os.path.join(page, ".answer.json.tmp")
        with open(tmp, "w") as f:
            json.dump(rec, f, indent=1)
        os.replace(tmp, os.path.join(page, ".answer.json"))
        _clear_pending(slug)
        return self._json(200, {"ok": True, "slug": slug})

    def log_message(self, *args):
        pass  # quiet — per-request logs add nothing useful under pm2


if __name__ == "__main__":
    os.makedirs(REG, exist_ok=True)
    ThreadingHTTPServer(("127.0.0.1", PORT), DPHandler).serve_forever()
