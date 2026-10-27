#!/usr/bin/env python3
"""The mechanics behind /quiz: checking, rendering, grading and recording a quiz
about an artifact the owner did not write.

The agent writes quiz.json (chunks, claims with slices, questions with keys);
this script does everything that should not cost a model call. It never writes
questions and never calls a model.

  quiz.py init --artifact REF --kind K [--path P ...] [--ask TEXT] [--slug S]
                                       new record folder; prints its path
  quiz.py check DIR                    lint quiz.json; exit 1 on any problem
  quiz.py hash DIR                     exit 3 when the artifact changed since init
  quiz.py render DIR --round N [--surface wizard|page]
                                       wizard JSON on stdout, or a decision page config
  quiz.py grade DIR q1=a q2=c ...      record picks, print the result per question
  quiz.py retry DIR                    chunks missed once, due another question
  quiz.py report DIR                   write map.md (held / shaky / missed) and print it

Records live in ~/.claude/assets/quizzes/<YYYYMMDD>-<slug>/ (QUIZ_HOME overrides).
Schema and rules: ~/.claude/skills/quiz/SKILL.md
"""
import argparse
import datetime
import hashlib
import json
import os
import re
import sys

HOME = os.environ.get("QUIZ_HOME", os.path.expanduser("~/.claude/assets/quizzes"))
KINDS = ("spec", "plan", "code-change", "app", "feature", "analysis", "presentation", "docs")
SLICE_MAX = 20
MARKDOWN = (".md", ".markdown", ".mdx")
NOT_SURE = "?"
HEADING = re.compile(r"^(#{1,6})\s+(.*)$")


def die(msg, code=2):
    print(msg, file=sys.stderr)
    sys.exit(code)


def load(d):
    p = os.path.join(d, "quiz.json")
    try:
        with open(p) as f:
            return json.load(f)
    except OSError:
        die(f"no quiz.json in {d}")
    except ValueError as e:
        die(f"quiz.json is not valid JSON: {e}")


def save(d, q):
    tmp = os.path.join(d, "quiz.json.tmp")
    with open(tmp, "w") as f:
        json.dump(q, f, indent=2, ensure_ascii=False)
    os.replace(tmp, os.path.join(d, "quiz.json"))


def artifact_hash(paths):
    """One hash over every file the quiz is about, so an edit anywhere triggers a remap."""
    h = hashlib.sha256()
    for p in sorted(paths):
        h.update(p.encode())
        try:
            with open(p, "rb") as f:
                h.update(f.read())
        except OSError:
            h.update(b"<missing>")
    return h.hexdigest()[:16]


def read_slice(s):
    """The text a slice points at, read from disk now; (lines, total) or an error string."""
    if "image" in s:
        if not os.path.isfile(s["image"]):
            return None, f"image not found: {s['image']}"
        return [f"[image] {s['image']}"], 1
    path = s.get("path")
    try:
        with open(path, errors="replace") as f:
            text = f.read().splitlines()
    except (OSError, TypeError):
        return None, f"slice file not readable: {path}"
    if "lines" in s:
        a, b = s["lines"]
        if a < 1 or b < a or b > len(text):
            return None, f"slice lines {a}-{b} outside {path} ({len(text)} lines)"
        return text[a - 1:b], b - a + 1
    if "anchor" in s:
        # Headings only mean something in markdown; a '# comment' in code is not one.
        if not path.lower().endswith(MARKDOWN):
            return None, f"anchor slices need a markdown file; use lines for {path}"
        want = s["anchor"].lstrip("#").strip().lower()
        heads, fenced = [], False
        for i, line in enumerate(text):
            if line.lstrip().startswith(("```", "~~~")):
                fenced = not fenced
            elif not fenced:
                m = HEADING.match(line)
                if m:
                    heads.append((i, len(m.group(1)), m.group(2).strip().lower()))
        for k, (i, level, title) in enumerate(heads):
            if title == want:
                end = next((j for j, lv, _ in heads[k + 1:] if lv <= level), len(text))
                return text[i:end], end - i
        return None, f"anchor '{s['anchor']}' not found in {path}"
    return None, "a slice needs lines, an anchor or an image"


def claims_by_id(q):
    return {c["id"]: (ch, c) for ch in q.get("chunks", []) for c in ch.get("claims", [])}


def problems(q):
    """Everything that would make a question unfair or unanswerable.

    A quiz.json too malformed to inspect comes back as one problem naming the
    first thing that broke, never as a traceback.
    """
    try:
        return _problems(q)
    except (AttributeError, KeyError, TypeError, ValueError) as e:
        return [f"quiz.json is malformed ({type(e).__name__}: {e}); see the schema in SKILL.md"]


def _problems(q):
    out = []
    if not isinstance(q, dict):
        raise TypeError("top level must be an object")
    if not q["artifact"].get("paths"):
        out.append("artifact.paths is empty, so a changed artifact cannot be detected; init with --path")
    if q.get("artifact", {}).get("kind") not in KINDS:
        out.append(f"artifact.kind must be one of {', '.join(KINDS)}")
    claims = claims_by_id(q)
    chunk_ids = {ch["id"] for ch in q.get("chunks", [])}
    for cid, (ch, c) in claims.items():
        s = c.get("slice")
        if not s:
            out.append(f"claim {cid}: no slice")
            continue
        lines, total = read_slice(s)
        if lines is None:
            out.append(f"claim {cid}: {total}")
        elif "image" not in s:
            phrase = (c.get("key_phrase") or "").lower()
            if not phrase:
                out.append(f"claim {cid}: no key_phrase")
            elif phrase not in "\n".join(lines).lower():
                out.append(f"claim {cid}: slice no longer contains '{c['key_phrase']}'")
    for ch in q["chunks"]:
        deps = ch.get("depends_on", [])
        if not isinstance(deps, list) or any(d not in chunk_ids or d == ch["id"] for d in deps):
            out.append(f"chunk {ch['id']}: depends_on must list other existing chunk ids")
    rounds, seen_ids = {}, set()
    for item in q.get("questions", []):
        qid = item["id"]
        if qid in seen_ids:
            out.append(f"{qid}: duplicate question id")
        seen_ids.add(qid)
        rnd = item.get("round")
        if not isinstance(rnd, int) or isinstance(rnd, bool) or rnd < 1:
            out.append(f"{qid}: round must be a whole number from 1")
        rounds.setdefault(rnd, []).append(item)
        if not str(item.get("stem") or "").strip():
            out.append(f"{qid}: no stem")
        if item.get("claim") not in claims:
            out.append(f"{qid}: claim '{item.get('claim')}' does not exist")
        elif claims[item["claim"]][0]["id"] != item.get("chunk"):
            out.append(f"{qid}: chunk '{item.get('chunk')}' is not the chunk its claim belongs to")
        if item.get("chunk") not in chunk_ids:
            out.append(f"{qid}: chunk '{item.get('chunk')}' does not exist")
        opts = item.get("options", [])
        codes = [o["code"] for o in opts]
        if any(not isinstance(c, str) or not c or c in ("x", NOT_SURE) for c in codes):
            out.append(f"{qid}: option codes must be non-empty strings other than 'x' and '{NOT_SURE}' (reserved)")
        if any(not str(o.get("label") or "").strip() for o in opts):
            out.append(f"{qid}: every option needs a label")
        labels = [str(o.get("label", "")).strip().lower() for o in opts]
        if len(set(labels)) != len(labels):
            out.append(f"{qid}: two options share a label")
        if len(codes) < 2 or len(set(codes)) != len(codes):
            out.append(f"{qid}: needs two or more distinct option codes")
        if item.get("key") not in codes:
            out.append(f"{qid}: key '{item.get('key')}' is not an option")
        if not item.get("why"):
            out.append(f"{qid}: no why")
        missing = [c for c in codes if c != item.get("key") and c not in (item.get("wrong") or {})]
        if missing:
            out.append(f"{qid}: no wrong line for {', '.join(missing)}")
    if q.get("questions") and 1 not in rounds:
        out.append("there is no round 1")
    if 1 in rounds and not any(i.get("requirement") is True for i in rounds[1]):
        out.append("round 1 has no requirement question (one built from the owner's ask)")
    return out


def cmd_init(a):
    stamp = datetime.date.today().strftime("%Y%m%d")
    # A URL's last segment is often just a number (pull/9), so keep three segments.
    tail = "-".join(a.artifact.rstrip("/").split("/")[-3:]) if "://" in a.artifact else os.path.basename(a.artifact.rstrip("/"))
    slug = a.slug or re.sub(r"[^a-z0-9]+", "-", tail.lower()).strip("-")[:40] or "artifact"
    d = os.path.join(HOME, f"{stamp}-{slug}")
    n = 2
    while os.path.exists(d):
        d = os.path.join(HOME, f"{stamp}-{slug}-{n}")
        n += 1
    os.makedirs(d)
    paths = [os.path.abspath(p) for p in (a.path or [])]
    save(d, {"artifact": {"ref": a.artifact, "kind": a.kind, "paths": paths, "hash": artifact_hash(paths)},
             "ask": a.ask or "", "created": datetime.datetime.now().isoformat(timespec="seconds"),
             "chunks": [], "questions": [], "answers": []})
    print(d)


def cmd_check(a):
    p = problems(load(a.dir))
    for line in p:
        print(f"FAIL {line}")
    print("READY" if not p else f"{len(p)} problem(s)")
    return 1 if p else 0


def cmd_hash(a):
    q = load(a.dir)
    art = q["artifact"]
    now = artifact_hash(art.get("paths", []))
    if now == art.get("hash"):
        print("same")
        return 0
    print(f"changed: {art.get('hash')} -> {now}; remap the changed chunks, then: quiz.py hash {a.dir} --accept")
    if a.accept:
        art["hash"] = now
        save(a.dir, q)
        return 0
    return 3


def round_questions(q, n):
    qs = [i for i in q["questions"] if i.get("round") == n]
    if not qs:
        die(f"no questions for round {n}")
    return qs


def cmd_render(a):
    q = load(a.dir)
    p = problems(q)
    if p:
        die("quiz.json fails check; run quiz.py check first:\n  " + "\n  ".join(p), 1)
    qs = round_questions(q, a.round)
    title = f"Quiz · {os.path.basename(q['artifact']['ref'].rstrip('/'))} · round {a.round}"
    if a.surface == "wizard":
        # "Not sure" is always offered: a lucky guess would otherwise read as held.
        steps = [{"name": i["id"], "message": i["stem"],
                  "fields": [{"name": "pick", "label": "Your answer", "type": "string",
                              "enum": [o["code"] for o in i["options"]] + [NOT_SURE],
                              "enum_labels": [f"{o['code']}) {o['label']}" for o in i["options"]] + ["not sure"]}]}
                 for i in qs]
        print(json.dumps({"title": title, "steps": steps}, ensure_ascii=False))
        return 0
    # The decision page contract needs one recommended option per decision, so a
    # neutral first option carries it and nothing on the page leaks the key.
    decisions = [{"id": i["id"].upper(), "question": i["stem"], "context": f"chunk: {chunk_title(q, i['chunk'])}",
                  "options": [{"code": "x", "label": "answer below", "rec": True}] +
                             [{"code": o["code"], "label": o["label"]} for o in i["options"]]}
                 for i in qs]
    slug = os.path.basename(a.dir)
    cfg = {"title": title, "storageKey": f"quiz-{slug}-r{a.round}", "copyHeader": f"quiz {slug} r{a.round}",
           "intro": "Pick one answer per question, then Submit. Grading happens in the terminal.",
           "decisions": decisions, "sections": []}
    print(json.dumps(cfg, indent=2, ensure_ascii=False))
    return 0


def chunk_title(q, cid):
    return next((c["title"] for c in q["chunks"] if c["id"] == cid), cid)


def cmd_grade(a):
    q = load(a.dir)
    art = q["artifact"]
    if art.get("paths") and artifact_hash(art["paths"]) != art.get("hash"):
        die(f"the artifact changed since the map was built; remap, then quiz.py hash {a.dir} --accept", 3)
    by_id = {i["id"]: i for i in q["questions"]}
    claims = claims_by_id(q)
    answered = {ans["q"] for ans in q["answers"]}
    picks, skipped = [], []
    for token in a.picks:
        qid, pick = parse_pick(token, by_id)
        codes = [o["code"] for o in by_id[qid]["options"]]
        if pick == "x":  # the decision page's neutral default: the owner left it untouched
            skipped.append(qid)
            continue
        if pick not in codes and pick != NOT_SURE:
            die(f"{qid}: '{pick}' is not an option ({', '.join(codes)}, or {NOT_SURE} for not sure); nothing recorded")
        if qid in answered or qid in (p[0] for p in picks):
            die(f"{qid} is already answered; write a new question for a retry; nothing recorded")
        picks.append((qid, pick))
    right = 0
    for qid, pick in picks:
        item = by_id[qid]
        ok = pick == item["key"]
        right += ok
        q["answers"].append({"q": qid, "chunk": item["chunk"], "claim": item["claim"], "pick": pick, "right": ok,
                             "ts": datetime.datetime.now().isoformat(timespec="seconds")})
        if ok:
            print(f"✓ {qid}  {item['why']}")
            continue
        label = next((o["label"] for o in item["options"] if o["code"] == item["key"]), item["key"])
        wrong = "Not sure is an honest answer; here is the part that settles it." if pick == NOT_SURE \
            else (item.get("wrong") or {}).get(pick, "")
        print(f"✗ {qid}  you picked {pick}: {wrong}")
        print(f"   answer {item['key']}) {label}. {item['why']}")
        s = claims[item["claim"]][1]["slice"]
        lines, total = read_slice(s)
        if lines is None:
            print(f"   slice unreadable: {total}")
            continue
        where = s.get("image") or f"{s['path']}" + (f":{s['lines'][0]}-{s['lines'][1]}" if "lines" in s else
                                                     f" § {s['anchor']}" if "anchor" in s else "")
        print(f"   ── {where}")
        for line in lines[:SLICE_MAX]:
            print(f"   │ {line}")
        if total > SLICE_MAX:
            print(f"   │ … {total - SLICE_MAX} more lines in {where}")
    save(a.dir, q)
    print(f"{right}/{len(picks)} right" + (f", {len(skipped)} left unanswered ({', '.join(skipped)})" if skipped else ""))
    return 0


def parse_pick(token, by_id):
    """Read 'q1=b', or the decision page's 'Q1b' form, into (question id, code)."""
    m = re.match(r"^([\w.-]+)=(\S+)$", token)
    if m and m.group(1) in by_id:
        return m.group(1), m.group(2)
    for qid in sorted(by_id, key=len, reverse=True):
        if token.upper().startswith(qid.upper()) and len(token) > len(qid):
            return qid, token[len(qid):]
    die(f"bad pick '{token}': want <question id>=<option code> (or the page's Q1b form)")


def chunk_states(q):
    """Where the owner stands on each chunk, from every answer given about it.

    held: never wrong · shaky: wrong before, right last time · retry due: wrong
    once and not yet retried · missed: wrong more than once and wrong last time.
    Also returns, per chunk, the claim of the latest wrong answer.
    """
    seen, last_wrong = {}, {}
    for ans in q["answers"]:
        seen.setdefault(ans["chunk"], []).append(ans["right"])
        if not ans["right"]:
            last_wrong[ans["chunk"]] = ans.get("claim")
    states = {}
    for ch in q["chunks"]:
        r = seen.get(ch["id"])
        if not r:
            states[ch["id"]] = "unasked"
        elif all(r):
            states[ch["id"]] = "held"
        elif r[-1]:
            states[ch["id"]] = "shaky"
        elif r.count(False) == 1:
            states[ch["id"]] = "retry due"
        else:
            states[ch["id"]] = "missed"
    return states, last_wrong


def cmd_retry(a):
    q = load(a.dir)
    states, _ = chunk_states(q)
    due = [c for c, s in states.items() if s == "retry due"]
    for c in due:
        asked = {i["claim"] for i in q["questions"] if i["chunk"] == c}
        fresh = [cl["id"] for ch in q["chunks"] if ch["id"] == c for cl in ch["claims"] if cl["id"] not in asked]
        print(f"{c}  {chunk_title(q, c)}  unused claims: {', '.join(fresh) or 'none (reuse one, reword)'}")
    if not due:
        print("none")
    return 0


def cmd_report(a):
    q = load(a.dir)
    states, last_wrong = chunk_states(q)
    claims = claims_by_id(q)
    dependents = {ch["id"]: 0 for ch in q["chunks"]}
    for ch in q["chunks"]:
        for dep in ch.get("depends_on", []):
            if dep in dependents:
                dependents[dep] += 1
    mark = {"held": "held", "shaky": "shaky", "missed": "missed", "retry due": "retry due", "unasked": "-"}
    n = {s: sum(v == s for v in states.values()) for s in mark}
    out = [f"# Quiz map: {q['artifact']['ref']}", "",
           f"{n['held']} held, {n['shaky']} shaky, {n['missed']} missed, {n['retry due']} due a retry, "
           f"{n['unasked']} not asked.", "",
           "| chunk | state | what to know |", "|---|---|---|"]
    weak = []
    for ch in q["chunks"]:
        st = states[ch["id"]]
        # Point at the claim the owner actually got wrong, not the chunk's first one.
        missed = claims.get(last_wrong.get(ch["id"]), (None, None))[1]
        weak_state = st in ("shaky", "missed", "retry due")
        know = missed["text"] if missed and weak_state else ""
        out.append(f"| {ch['title']} | {mark[st]} | {know} |")
        if weak_state and missed:
            weak.append((dependents[ch["id"]], st != "shaky", ch, missed))
    weak.sort(key=lambda w: (w[0], w[1]), reverse=True)
    if weak:
        out += ["", "## Read these next", ""]
        for _, _, ch, c in weak[:3]:
            s = c["slice"]
            where = s.get("image") or s["path"] + (f":{s['lines'][0]}-{s['lines'][1]}" if "lines" in s else
                                                   f" § {s['anchor']}" if "anchor" in s else "")
            out.append(f"- {ch['title']}: `{where}`")
    flags = problems(q)
    if flags:
        out += ["", "## Questions to distrust", ""] + [f"- {f}" for f in flags]
    text = "\n".join(out) + "\n"
    with open(os.path.join(a.dir, "map.md"), "w") as f:
        f.write(text)
    print(text, end="")
    return 0


def main():
    ap = argparse.ArgumentParser(prog="quiz.py", description=__doc__.split("\n\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("init")
    p.add_argument("--artifact", required=True)
    p.add_argument("--kind", required=True, choices=KINDS)
    p.add_argument("--path", action="append")
    p.add_argument("--ask")
    p.add_argument("--slug")
    for name in ("check", "retry", "report"):
        sub.add_parser(name).add_argument("dir")
    p = sub.add_parser("hash")
    p.add_argument("dir")
    p.add_argument("--accept", action="store_true")
    p = sub.add_parser("render")
    p.add_argument("dir")
    p.add_argument("--round", type=int, required=True)
    p.add_argument("--surface", choices=("wizard", "page"), default="wizard")
    p = sub.add_parser("grade")
    p.add_argument("dir")
    p.add_argument("picks", nargs="+")
    a = ap.parse_args()
    fn = {"init": cmd_init, "check": cmd_check, "hash": cmd_hash, "render": cmd_render,
          "grade": cmd_grade, "retry": cmd_retry, "report": cmd_report}[a.cmd]
    sys.exit(fn(a) or 0)


if __name__ == "__main__":
    main()
