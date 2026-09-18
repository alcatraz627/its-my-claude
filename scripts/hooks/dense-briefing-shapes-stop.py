"""Detector half of dense-briefing-shapes-stop.sh. Reads a transcript, prints one
line per shape found in the current turn's last reply, nothing when clean.
Kept out of the bash file because the patterns carry backticks, which a heredoc
inside $( ) cannot hold."""
import json, os, re, sys

recs = []
with open(sys.argv[1], errors="replace") as fh:
    for line in fh.readlines()[-600:]:
        try:
            recs.append(json.loads(line))
        except ValueError:
            pass


def text_of(r):
    c = (r.get("message") or {}).get("content")
    if isinstance(c, str):
        return c
    return "\n".join(b.get("text", "") for b in (c or []) if isinstance(b, dict) and b.get("type") == "text")


HARNESS = re.compile(r"^\s*(<system-reminder>|\[Image:|<command-name>|<local-command|Caveat:|<task-notification>)")
last_user = None
for i in range(len(recs) - 1, -1, -1):
    r = recs[i]
    if r.get("type") != "user":
        continue
    c = (r.get("message") or {}).get("content")
    if isinstance(c, list) and any(isinstance(b, dict) and b.get("type") == "tool_result" for b in c):
        continue
    t = text_of(r).strip()
    if not t or HARNESS.match(t):
        continue
    last_user = i
    break
if last_user is None:
    sys.exit(0)
turn = recs[last_user:]
user_text = text_of(recs[last_user])
reply = ""
for r in reversed(turn):
    if r.get("type") == "assistant" and text_of(r).strip():
        reply = text_of(r)
        break
if len(reply) < 600:
    sys.exit(0)

prose = re.sub(r"```.*?```", "", reply, flags=re.S)
prose = re.sub(r"`[^`]*`", "", prose)
prose = "\n".join(l for l in prose.splitlines() if not re.match(r"^\s*[>|]", l))

tells = []

# shape 2: a markdown file written this turn whose headings the reply repeats
paths = []
for r in turn:
    if r.get("type") != "assistant":
        continue
    for b in (r.get("message") or {}).get("content") or []:
        if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") in ("Write", "Edit"):
            p = (b.get("input") or {}).get("file_path") or ""
            if p.endswith(".md") and os.path.isfile(p):
                paths.append(p)


def norm(s):
    return re.sub(r"[^a-z0-9 ]", "", s.lower()).strip()


reply_lines = {norm(l.strip().lstrip("#* ").rstrip("*: ")) for l in prose.splitlines() if l.strip()}
for p in dict.fromkeys(paths):
    try:
        heads = [norm(l.lstrip("# ")) for l in open(p, errors="replace") if re.match(r"^#{1,4}\s+\S", l)]
    except OSError:
        continue
    heads = [h for h in heads if len(h) >= 8]
    hit = [h for h in heads if h in reply_lines]
    if len(hit) >= 2:
        tells.append(f"shape 2: the reply repeats {len(hit)} heading(s) of {os.path.basename(p)}, written this turn ({hit[0][:40]!r}, ...). The owner can open the file; the reply owes the path and the one decision.")
        break

# shape 3: a stated criterion in the ask, a done-claim in the reply, no overlap
crit = [s.strip() for s in re.split(r"(?<=[.!?\n])\s+", user_text)
        if re.search(r"\b(must|make sure|never|don'?t|do not|should|i want|has to|needs? to)\b", s, re.I)]
if crit and re.search(r"\b(done|fixed|verified|shipped|works|passing|completed?|resolved)\b", prose, re.I):
    STOP = {"must", "make", "sure", "never", "dont", "should", "want", "needs", "need", "have", "this", "that",
            "with", "from", "into", "them", "they", "then", "also", "when", "what", "please", "just", "only",
            "about", "after", "before", "there", "their", "would", "could", "which", "where", "while"}

    def words(s):
        return {w for w in re.findall(r"[a-z]{5,}", s.lower()) if w not in STOP}

    rw = words(prose)
    missed = [s for s in crit if words(s) and not (words(s) & rw)]
    if missed:
        tells.append(f"shape 3: the reply claims done and names nothing from the stated criterion {missed[0][:70]!r}. Mark it pass, fail, or not exercised before the summary.")

if tells:
    print("\n".join(tells))
