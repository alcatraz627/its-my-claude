#!/usr/bin/env python3
"""Turn DECK.md into one self-contained slide deck (deck.html), deterministically.

The agent writes the markdown; this script owns every decision the owner asked to
take out of the agent's hands (2026-08-18): the one theme, the slide chrome, the
keyboard nav, the presenter-notes window, print, deep links, the overflow estimate,
and the "no colour outside the tokens" check. Stdlib only, no network, no build.

Source shape (one file, DECK.md):

    # Deck title                 the title slide; the next lines until "## " are its body
    sub: one-line takeaway       (any slide) dim line under the title
    kicker: EYEBROW              (any slide) small uppercase label above the title
    ## Slide title               one "## " per slide
    - bullets, 1. numbered, paragraphs, **bold**, `code`, [links](url), *em*
    | tables |                   a column named ruling / caveat / status / verdict is toned by value
    ```text  (or ```ascii)       a monospace diagram, width-budgeted (113 chars at 14px)
    ```html                      raw HTML passthrough for a shape this file does not know
    :::stat 42% | what it means  big number + caption
    :::open path | how           "here is the file, here is how to open it" row
    :::open url | label | how    the same with a label instead of the raw url
    leave: text                  the slide's gradient take-away line (the approved deck's "leave" idiom)
    :::callout <kind> text       one-line callout; kinds below
    :::callout <kind>            block callout, closed by ":::"
    :::cards  … --- … :::        card grid; each card is a block, first line = card title
    :::cols   … --- … :::        two columns
    > notes: full sentences      presenter notes; NEVER rendered in the main window

Callout kinds. Neutral: note (hairline), tip (accent hairline), quote (large quote,
attribution on the last line "-- name"), aside (dim, small), term (definition:
first line is the term). Visual: info (accent wash), ok (green wash), warn (amber),
bad (red), stat (big number inside a wash), ask (the approved deck's "ask box": accent
border, THE ASK label). Anything else falls back to note and is reported.

Overflow: the one failure all three source decks hit first. Each slide gets an
estimated line count (bullets 1, paragraph ceil(len/95), table rows, pre lines,
stat 4, cards max-of-columns, callouts by lines). Over BUDGET is an error unless
--allow-overflow, and check.sh measures the real thing in headless Chrome.

Usage: render.py DECK.md [-o deck.html] [--allow-overflow] [--allow-color] [--json]
Exit: 0 ok · 1 overflow/colour errors (file still written) · 2 usage.
"""
import html, json, math, os, re, sys

BUDGET = 18          # estimated lines per slide before it is an error
DIAGRAM_COLS = 113   # gcc-fable: fits a 72rem <pre> at 14px
# The theme IS the deck look the owner approved on 2026-08-17
# (versable-builder/.claude/output/20260817-presentation/deck.html): its palette, its
# centered slide-inner, its gradient kicker and stat numbers, its pill "Show" row, its
# chrome. Changing this look needs a parity screenshot pair and the owner's word
# (atone mist-20260818-151647-b8, S3: a from-scratch theme replaced it uncalled).
TOKENS_DARK = {"bg": "#10151c", "surface": "#161c26", "surface2": "#1b222e", "text": "#e6e9ee", "dim": "#8b93a3",
               "border": "rgba(255,255,255,0.10)", "accent": "#6366f1", "accent2": "#0ea5e9",
               "warn": "#e3b341", "bad": "#f87171", "ok": "#4ade80"}
TOKENS_LIGHT = {"bg": "#f1f4f6", "surface": "#ffffff", "surface2": "#e9edf1", "text": "#1c2430", "dim": "#5b6472",
                "border": "rgba(0,0,0,0.10)", "accent": "#6366f1", "accent2": "#0ea5e9",
                "warn": "#9a6700", "bad": "#cf222e", "ok": "#1a7f37"}
KINDS = {"note", "tip", "quote", "aside", "term", "info", "ok", "warn", "bad", "stat", "ask"}

def esc(s): return html.escape(s, quote=False)

def inline(s):
    s = esc(s)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"(?<![*\w])\*([^*]+)\*(?![*\w])", r"<em>\1</em>", s)
    s = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', s)
    return s

def parse(src):
    """Return (meta, slides). A slide is {title, kicker, sub, blocks, notes, est}."""
    lines = src.splitlines()
    slides, cur, meta = [], None, {"title": ""}
    def new(title, kind="slide"):
        s = {"title": title, "kicker": "", "sub": "", "blocks": [], "notes": [], "kind": kind}
        slides.append(s); return s
    i = 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith("# ") and not cur:
            meta["title"] = ln[2:].strip(); cur = new(meta["title"], "title"); i += 1; continue
        if ln.startswith("## "):
            cur = new(ln[3:].strip()); i += 1; continue
        if cur is None:
            cur = new(meta["title"] or "Untitled", "title")
        if ln.startswith("kicker:"): cur["kicker"] = ln[7:].strip(); i += 1; continue
        if ln.startswith("sub:"): cur["sub"] = ln[4:].strip(); i += 1; continue
        if ln.startswith("leave:"): cur["blocks"].append({"t": "leave", "text": ln[6:].strip()}); i += 1; continue
        if ln.startswith("> notes:"):
            note = [ln[8:].strip()]; i += 1
            while i < len(lines) and lines[i].startswith(">"):
                note.append(lines[i][1:].strip()); i += 1
            cur["notes"].append(" ".join(x for x in note if x)); continue
        if ln.startswith("```"):
            lang = ln[3:].strip().lower(); body = []; i += 1
            while i < len(lines) and not lines[i].startswith("```"): body.append(lines[i]); i += 1
            i += 1
            kind = "diagram" if lang in ("text", "ascii", "diagram", "") else ("html" if lang == "html" else "code")
            cur["blocks"].append({"t": kind, "lang": lang, "lines": body}); continue
        if ln.startswith(":::stat "):
            v, _, cap = ln[8:].partition("|"); cur["blocks"].append({"t": "stat", "value": v.strip(), "cap": cap.strip()}); i += 1; continue
        if ln.startswith(":::open "):
            # :::open <path-or-url> | <label> | <how>   (label and how optional; a
            # two-part form is path | how, as before)
            segs = [x.strip() for x in ln[8:].split("|")]
            path = segs[0]; label = segs[1] if len(segs) > 2 else ""; how = segs[-1] if len(segs) > 1 else ""
            cur["blocks"].append({"t": "open", "path": path, "label": label, "how": how}); i += 1; continue
        if ln.startswith(":::callout"):
            rest = ln[len(":::callout"):].strip(); kind, _, text = rest.partition(" ")
            kind = kind.strip().lower() or "note"
            if text.strip():
                cur["blocks"].append({"t": "callout", "kind": kind, "lines": [text.strip()]}); i += 1; continue
            body = []; i += 1
            while i < len(lines) and lines[i].strip() != ":::": body.append(lines[i]); i += 1
            i += 1; cur["blocks"].append({"t": "callout", "kind": kind, "lines": body}); continue
        if ln.startswith(":::cards") or ln.startswith(":::cols"):
            # Depth-aware: a :::callout block INSIDE a column closes with its own ":::",
            # which used to end the columns early and leave the callout as raw text
            # (slack-automation deck, slide 7, 2026-08-18).
            t = "cards" if ln.startswith(":::cards") else "cols"; parts, buf, depth = [], [], 0; i += 1
            while i < len(lines):
                l = lines[i]
                if l.strip() == ":::":
                    if depth == 0: break
                    depth -= 1; buf.append(l)
                elif l.startswith(":::") and not l.startswith((":::stat ", ":::open ")) and (l.startswith((":::cards", ":::cols")) or (l.startswith(":::callout") and len(l.split(None, 2)) <= 2)):
                    depth += 1; buf.append(l)
                elif l.strip() == "---" and depth == 0: parts.append(buf); buf = []
                else: buf.append(l)
                i += 1
            parts.append(buf); i += 1
            cur["blocks"].append({"t": t, "parts": [p for p in parts if any(x.strip() for x in p)]}); continue
        if ln.startswith("|"):
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                if not all(re.fullmatch(r":?-{2,}:?", c) for c in cells): rows.append(cells)
                i += 1
            cur["blocks"].append({"t": "table", "rows": rows}); continue
        if re.match(r"^\s*[-*] ", ln) or re.match(r"^\s*\d+\. ", ln):
            items, ordered = [], bool(re.match(r"^\s*\d+\. ", ln))
            while i < len(lines) and (re.match(r"^\s*[-*] ", lines[i]) or re.match(r"^\s*\d+\. ", lines[i])):
                items.append(re.sub(r"^\s*([-*]|\d+\.) ", "", lines[i])); i += 1
            cur["blocks"].append({"t": "list", "items": items, "ordered": ordered}); continue
        if ln.strip() == "": i += 1; continue
        para = [ln.strip()]; i += 1
        while i < len(lines) and lines[i].strip() and not re.match(r"^(#{1,2} |[-*] |\d+\. |\||```|:::|> notes:|kicker:|sub:)", lines[i]):
            para.append(lines[i].strip()); i += 1
        cur["blocks"].append({"t": "p", "text": " ".join(para)})
    return meta, slides

def est_block(b):
    if b["t"] == "p": return max(1, math.ceil(len(b["text"]) / 95))
    if b["t"] == "list": return sum(max(1, math.ceil(len(x) / 90)) for x in b["items"])
    if b["t"] == "table": return len(b["rows"]) + 1
    if b["t"] in ("diagram", "code", "html"): return len(b["lines"])
    if b["t"] == "stat": return 4
    if b["t"] == "open": return 2
    if b["t"] == "callout": return 1 + sum(max(1, math.ceil(len(x) / 90)) for x in b["lines"])
    if b["t"] in ("cards", "cols"): return 2 + max((sum(max(1, math.ceil(len(x) / 45)) for x in p) for p in b["parts"]), default=0)
    return 1

def estimate(s):
    n = 2 + (1 if s["sub"] else 0) + (1 if s["kicker"] else 0)
    return n + sum(est_block(b) for b in s["blocks"])

def tone_for(v):
    v = v.lower()
    if re.search(r"\b(holds|ok|yes|supported|verified|done|met|green|stays)\b", v): return "ok"
    if re.search(r"\b(no|contradicted|blocked|missed|failed|red|broken|dropped)\b", v): return "bad"
    if re.search(r"\b(caveat|partial|overstated|warn|unsourced|pending|open|unclear|risk)\b", v): return "warn"
    return ""

def render_block(b, problems, sid):
    t = b["t"]
    if t == "p": return f'<p class="text">{inline(b["text"])}</p>'
    if t == "leave": return f'<p class="leave">{inline(b["text"])}</p>'
    if t == "list":
        tag = "ol" if b["ordered"] else "ul"
        return f'<{tag} class="body-list">' + "".join(f"<li>{inline(x)}</li>" for x in b["items"]) + f"</{tag}>"
    if t == "table":
        rows = b["rows"]
        if not rows: return ""
        head = rows[0]; toned = [i for i, h in enumerate(head) if h.lower() in ("ruling", "caveat", "status", "verdict", "state")]
        out = "<table><thead><tr>" + "".join(f"<th>{inline(h)}</th>" for h in head) + "</tr></thead><tbody>"
        for r in rows[1:]:
            out += "<tr>" + "".join(
                (f'<td class="tone-{tone_for(c)}">' if i in toned and tone_for(c) else "<td>") + inline(c) + "</td>"
                for i, c in enumerate(r)) + "</tr>"
        return out + "</tbody></table>"
    if t == "diagram":
        w = max((len(x) for x in b["lines"]), default=0)
        if w > DIAGRAM_COLS: problems.append(f"slide {sid}: diagram is {w} columns wide; budget is {DIAGRAM_COLS}")
        return '<pre class="diagram">' + esc("\n".join(b["lines"])) + "</pre>"
    if t == "code": return f'<pre class="code"><code>{esc(chr(10).join(b["lines"]))}</code></pre>'
    if t == "html": return "\n".join(b["lines"])
    if t == "stat": return f'<div class="stat"><div class="stat-num">{inline(b["value"])}</div><div class="stat-cap">{inline(b["cap"])}</div></div>'
    if t == "open":
        p = b["path"]; href = p if re.match(r"^https?://", p) else "file://" + p
        label = inline(b.get("label") or ""); how = inline(b["how"]) if b["how"] else ""
        shown = esc(p) if not label else label
        return (f'<div class="show-row"><span class="show-label">Show</span><a href="{esc(href)}" target="_blank" rel="noopener noreferrer">'
                f'{("<span>" + shown + "</span>") if label else ""}<span class="show-path">{esc(p) if not label else ""}</span></a>'
                f'{("<span class=\"show-note\">" + how + "</span>") if how else ""}</div>')
    if t == "callout":
        kind = b["kind"]
        if kind not in KINDS: problems.append(f"slide {sid}: unknown callout kind '{kind}', rendered as note"); kind = "note"
        lines = [x for x in b["lines"] if x.strip()]
        if kind == "quote":
            attr = ""
            if lines and lines[-1].startswith("-- "): attr = f'<div class="quote-attr">{inline(lines[-1][3:])}</div>'; lines = lines[:-1]
            return f'<blockquote class="callout quote"><div>{inline(" ".join(lines))}</div>{attr}</blockquote>'
        if kind == "term" and lines:
            return f'<div class="callout term"><div class="term-name">{inline(lines[0])}</div><div>{inline(" ".join(lines[1:]))}</div></div>'
        if kind == "ask" and lines:
            return f'<div class="callout ask"><p class="ask-label">The ask</p>' + "".join(f"<p>{inline(x)}</p>" for x in lines) + "</div>"
        if kind == "stat" and lines:
            v, _, cap = lines[0].partition("|")
            return f'<div class="callout stat-callout"><div class="stat-num">{inline(v.strip())}</div><div class="stat-cap">{inline(cap.strip() or " ".join(lines[1:]))}</div></div>'
        body = "".join(f"<p>{inline(x)}</p>" for x in lines)
        return f'<div class="callout {kind}">{body}</div>'
    if t in ("cards", "cols"):
        cls = "cards" if t == "cards" else "cols"
        parts = []
        for p in b["parts"]:
            p = [x for x in p if x.strip()]
            title = ""
            if t == "cards" and p and not p[0].startswith((":::", "```", "|", "-", "*")) and not re.match(r"^\d+\. ", p[0]):
                title, p = p[0], p[1:]
            _, sub = parse("## x\n" + "\n".join(p))
            inner = "".join(render_block(sb, problems, sid) for sb in sub[0]["blocks"]) if sub else ""
            if t == "cards":
                parts.append(f'<div class="card">' + (f'<div class="card-title">{inline(title)}</div>' if title else "") + inner + "</div>")
            else:
                parts.append('<div class="col">' + inner + "</div>")
        return f'<div class="{cls}">' + "".join(parts) + "</div>"
    return ""

CSS = """
:root{--bg:%(bg)s;--surface:%(surface)s;--surface-2:%(surface2)s;--text:%(text)s;--dim:%(dim)s;--border:%(border)s;--accent:%(accent)s;--accent-2:%(accent2)s;--warn:%(warn)s;--bad:%(bad)s;--ok:%(ok)s;
--accent-grad:linear-gradient(90deg,var(--accent),var(--accent-2));
--sans:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;--mono:ui-monospace,SFMono-Regular,"SF Mono",Menlo,Consolas,"Liberation Mono",monospace}
:root[data-theme="light"],html.light{--bg:%(lbg)s;--surface:%(lsurface)s;--surface-2:%(lsurface2)s;--text:%(ltext)s;--dim:%(ldim)s;--border:%(lborder)s;--warn:%(lwarn)s;--bad:%(lbad)s;--ok:%(lok)s}
*{box-sizing:border-box}html,body{margin:0;padding:0;height:100%;background:var(--bg);color:var(--text);font-family:var(--sans);overflow:hidden}
code,.mono{font-family:var(--mono)}code{font-size:.9em;background:var(--surface-2);border:1px solid var(--border);border-radius:4px;padding:0 .3em}
a{color:var(--accent-2)}
.deck{position:relative;width:100vw;height:100vh;background:var(--bg)}
.slide{display:none;position:absolute;inset:0;align-items:center;justify-content:center;padding:6vh 8vw}
.slide.active{display:flex}
.slide-inner{width:100%;max-width:920px;max-height:88vh;overflow-y:auto;display:flex;flex-direction:column;gap:.9rem}
.slide.title .slide-inner{text-align:center;align-items:center}
.slide-inner.wide{max-width:1180px}
.kicker{margin:0;font-size:.85rem;font-weight:700;letter-spacing:.04em;text-transform:uppercase;background:var(--accent-grad);-webkit-background-clip:text;background-clip:text;color:transparent}
.headline{margin:0;font-size:clamp(1.6rem,3.4vw,2.6rem);line-height:1.2;font-weight:750;color:var(--text)}
.slide.title .headline{font-size:clamp(2.2rem,5vw,3.6rem)}
.lede{margin:0;font-size:1.3rem;color:var(--dim)}
.body-list{margin:0;padding:0;list-style:none;display:flex;flex-direction:column;gap:.55rem}
.body-list li{position:relative;padding-left:1.15rem;font-size:1.05rem;line-height:1.45;color:var(--text)}
.body-list li::before{content:"";position:absolute;left:0;top:.55em;width:6px;height:6px;border-radius:50%;background:var(--accent-grad)}
ol.body-list{counter-reset:n}ol.body-list li::before{content:counter(n) ".";counter-increment:n;width:auto;height:auto;border-radius:0;background:none;top:0;color:var(--accent-2);font-weight:700;font-size:.9em}
p.text{margin:0;font-size:1.05rem;line-height:1.5}
.leave{margin:0;font-size:1.05rem;font-weight:650;background:var(--accent-grad);-webkit-background-clip:text;background-clip:text;color:transparent}
.muted-note{margin:0;font-size:.95rem;color:var(--dim);font-style:italic}
pre.diagram,pre.code{margin:0;background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:1rem 1.2rem;font-family:var(--mono);font-size:.82rem;line-height:1.5;overflow-x:auto;color:var(--text);white-space:pre}
.show-row{display:flex;flex-wrap:wrap;align-items:center;gap:.6rem;padding-top:.4rem;border-top:1px solid var(--border);margin-top:.2rem}
.show-label{font-size:.78rem;font-weight:700;letter-spacing:.04em;text-transform:uppercase;color:var(--dim);margin-right:.2rem}
.show-row a{display:inline-flex;align-items:baseline;gap:.4rem;text-decoration:none;background:var(--surface);border:1px solid var(--border);border-radius:999px;padding:.3rem .75rem;color:var(--text);font-size:.9rem}
.show-row a:hover{border-color:var(--accent)}.show-row a .show-path{color:var(--dim);font-family:var(--mono);font-size:.8rem}
.show-row .show-note{font-size:.9rem;color:var(--dim);font-style:italic}
.stats-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:.9rem 1.4rem}
.stat{display:flex;flex-direction:column;gap:.15rem}
.stat-num{font-size:clamp(1.6rem,3vw,2.1rem);font-weight:800;background:var(--accent-grad);-webkit-background-clip:text;background-clip:text;color:transparent;line-height:1.1}
.stat-cap{font-size:.85rem;color:var(--dim);line-height:1.3}
table{border-collapse:collapse;width:100%;font-size:.95rem;margin:0}th,td{text-align:left;padding:.45rem .7rem;border-bottom:1px solid var(--border);vertical-align:top}
th{color:var(--dim);font-weight:700;font-size:.78rem;text-transform:uppercase;letter-spacing:.04em}
td.tone-ok{color:var(--ok);font-weight:600}td.tone-bad{color:var(--bad);font-weight:600}td.tone-warn{color:var(--warn);font-weight:600}
.callout{background:var(--surface);border:1px solid var(--border);border-left:3px solid var(--dim);border-radius:12px;padding:.9rem 1.2rem;font-size:1rem;line-height:1.45;text-align:left}
.callout p{margin:0}.callout p+p{margin-top:.35rem}
.callout.tip,.callout.info,.callout.ask,.callout.stat-callout{border-left-color:var(--accent)}
.callout.ok{border-left-color:var(--ok)}.callout.warn{border-left-color:var(--warn)}.callout.bad{border-left-color:var(--bad)}
.callout.aside{border:0;background:none;color:var(--dim);font-size:.95rem;font-style:italic;padding:.1rem 0}
.callout.term .term-name{font-weight:700;margin-bottom:.15rem}
.callout.ask{box-shadow:0 0 0 1px rgba(99,102,241,.15) inset}
.ask-label{margin:0 0 .35rem;font-size:.78rem;font-weight:700;letter-spacing:.04em;text-transform:uppercase;background:var(--accent-grad);-webkit-background-clip:text;background-clip:text;color:transparent}
.callout.ask p{font-size:1.15rem}
.callout.stat-callout{display:flex;gap:1rem;align-items:baseline}
blockquote.callout.quote{margin:0;font-style:italic;font-size:1.15rem}.quote-attr{font-style:normal;font-size:.9rem;color:var(--dim);margin-top:.35rem}
.col p.text,.card p.text{font-size:.98rem}.col .callout,.card .callout{font-size:.95rem;padding:.7rem 1rem}
.cards,.cols{display:grid;grid-template-columns:repeat(auto-fit,minmax(16rem,1fr));gap:.9rem}.cols{grid-template-columns:1fr 1fr}
.card{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:.9rem 1.1rem;font-size:.95rem;text-align:left}.card-title{font-weight:700;margin-bottom:.35rem}.card ul{margin:.2rem 0 0;padding-left:1.1rem}.card p{margin:.15rem 0}
.chrome{position:fixed;top:0;right:0;left:0;display:flex;justify-content:flex-end;align-items:flex-start;gap:.5rem;padding:1rem 1.2rem;pointer-events:none;z-index:30}
.btn{pointer-events:auto;background:var(--surface);border:1px solid var(--border);color:var(--text);border-radius:999px;height:2.5rem;min-width:2.5rem;padding:0 .8rem;font:inherit;font-size:.85rem;cursor:pointer;display:inline-flex;align-items:center;justify-content:center;gap:.4rem;text-decoration:none}
.btn:hover{border-color:var(--accent)}.btn svg{width:16px;height:16px}
.slide-counter{position:fixed;right:1.2rem;bottom:1rem;font-size:.85rem;color:var(--dim);font-family:var(--mono);z-index:30}
.nav-hint{position:fixed;left:1.2rem;bottom:1rem;font-size:.78rem;color:var(--dim);z-index:30}
.nav-hint kbd{font-family:var(--mono);background:var(--surface);border:1px solid var(--border);border-radius:4px;padding:.05rem .35rem;font-size:.75rem}
.notes-overlay{position:fixed;inset:0;z-index:40;background:rgba(0,0,0,.55);display:flex;align-items:flex-end}
:root[data-theme="light"] .notes-overlay,html.light .notes-overlay{background:rgba(20,25,35,.35)}
.notes-overlay[hidden]{display:none}
.notes-panel{width:100%;max-height:60vh;overflow-y:auto;background:var(--surface);border-top:1px solid var(--border);padding:1.4rem 8vw 1.6rem;box-shadow:0 -8px 30px rgba(0,0,0,.35)}
.notes-kicker{margin:0 0 .6rem;font-size:.78rem;font-weight:700;letter-spacing:.04em;text-transform:uppercase;color:var(--dim)}
.notes-say p{margin:0;font-size:1rem;line-height:1.5;color:var(--text)}
.slide.over .slide-inner::before{content:"OVERFLOW";align-self:flex-start;color:var(--bad);font-weight:700;border:2px solid var(--bad);padding:.1rem .5rem;border-radius:.4rem;font-size:.8rem}
/* presenter mode: the same file with ?notes=1 */
body.presenter .deck,body.presenter .chrome,body.presenter .nav-hint,body.presenter .slide-counter{display:none}
.presenter-view{display:none;height:100vh;padding:4vh 6vw;flex-direction:column;gap:1rem}body.presenter .presenter-view{display:flex}
.presenter-view .pv-head{display:flex;justify-content:space-between;color:var(--dim);font-family:var(--mono)}
.presenter-view .pv-title{font-size:1.6rem;font-weight:700}.presenter-view .pv-notes{font-size:1.6rem;line-height:1.5;flex:1;overflow:auto}
.presenter-view .pv-next{color:var(--dim);border-top:1px solid var(--border);padding-top:.8rem}
@media (max-width:720px){.stats-grid{grid-template-columns:repeat(2,1fr)}}
@media print{html,body{overflow:visible;height:auto}.deck{height:auto}.slide{display:flex;position:relative;height:100vh;page-break-after:always}.chrome,.nav-hint,.slide-counter,.notes-overlay{display:none}}
"""

JS = r"""
(function(){
  var qs=new URLSearchParams(location.search);
  var LS='deck-theme:'+DECK_ID;
  var light=qs.get('light')==='1'||localStorage.getItem(LS)==='light';
  function applyTheme(){document.documentElement.classList.toggle('light',light);document.documentElement.setAttribute('data-theme',light?'light':'dark');}
  applyTheme();
  var slides=[].slice.call(document.querySelectorAll('.slide'));
  var chan=null;try{chan=new BroadcastChannel('deck:'+DECK_ID);}catch(e){}
  var presenter=qs.get('notes')==='1';
  var cur=0;
  function show(i,fromPeer){i=Math.max(0,Math.min(slides.length-1,i));cur=i;
    slides.forEach(function(el,k){el.classList.toggle('active',k===i);});
    document.getElementById('num').textContent=(i+1)+' / '+slides.length;
    var n=NOTES[i]||'';var np=document.getElementById('notes-say');if(np)np.textContent=n||'(no notes for this slide)';
    var pv=document.getElementById('pv');if(pv){pv.querySelector('.pv-num').textContent=(i+1)+' / '+slides.length;
      pv.querySelector('.pv-title').textContent=TITLES[i]||'';pv.querySelector('.pv-notes').textContent=n||'(no notes for this slide)';
      pv.querySelector('.pv-next').textContent=(i+1<slides.length)?('next: '+TITLES[i+1]):'last slide';}
    if(!fromPeer){try{localStorage.setItem('deck-pos:'+DECK_ID,String(i));if(chan)chan.postMessage({i:i,t:Date.now()});}catch(e){}}
    history.replaceState(null,'','?'+(presenter?'notes=1&':'')+'s='+(i+1)+(light?'&light=1':''));
  }
  if(chan)chan.onmessage=function(e){if(e.data&&typeof e.data.i==='number')show(e.data.i,true);};
  window.addEventListener('storage',function(e){if(e.key==='deck-pos:'+DECK_ID)show(parseInt(e.newValue||'0',10),true);});
  var overlay=document.getElementById('notes-overlay');
  function toggleNotes(){overlay.hidden=!overlay.hidden;}
  document.addEventListener('keydown',function(e){
    if(e.target.tagName==='INPUT')return;
    if(e.key==='ArrowRight'||e.key==='ArrowDown'||e.key===' '||e.key==='PageDown'){e.preventDefault();show(cur+1);}
    else if(e.key==='ArrowLeft'||e.key==='ArrowUp'||e.key==='PageUp'){e.preventDefault();show(cur-1);}
    else if(e.key==='Home'){show(0);}else if(e.key==='End'){show(slides.length-1);}
    else if(e.key==='n'||e.key==='N'){toggleNotes();}
    else if(e.key==='t'){toggleTheme();}
    else if(e.key==='Escape'){overlay.hidden=true;}
  });
  function toggleTheme(){light=!light;applyTheme();localStorage.setItem(LS,light?'light':'dark');}
  document.getElementById('theme-btn').onclick=toggleTheme;
  document.getElementById('notes-btn').onclick=function(){window.open(location.pathname+'?notes=1&s='+(cur+1),'deck-notes','width=900,height=650');};
  document.getElementById('strip-btn').onclick=toggleNotes;
  overlay.addEventListener('click',function(e){if(e.target===overlay)overlay.hidden=true;});
  if(presenter)document.body.classList.add('presenter');
  var s=parseInt(qs.get('s')||'0',10);if(!s){try{s=parseInt(localStorage.getItem('deck-pos:'+DECK_ID)||'1',10);}catch(e){s=1;}}
  show((s||1)-1,true);
  // ?check=1: measure real overflow per slide and write it into the DOM for check.sh (--dump-dom)
  if(qs.get('check')==='1'){var rep=[];slides.forEach(function(el,i){el.classList.add('active');var b=el.querySelector('.slide-inner');var over=b&&(b.scrollHeight>b.clientHeight+2);
    if(over)el.classList.add('over');rep.push({slide:i+1,title:TITLES[i],over:!!over,scroll:b?b.scrollHeight:0,client:b?b.clientHeight:0});el.classList.toggle('active',i===cur);});
    var pre=document.createElement('pre');pre.id='deck-check';pre.textContent=JSON.stringify(rep);document.body.appendChild(pre);}
})();
"""

SVG_SUN = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>'
SVG_NOTES = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="4" width="18" height="16" rx="2"/><path d="M7 9h10M7 13h6"/></svg>'
SVG_STRIP = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 18h16M4 14h16M4 6h16M4 10h10"/></svg>'

def render(src, allow_overflow=False, allow_color=False):
    meta, slides = parse(src)
    problems, errors = [], []
    deck_id = re.sub(r"[^a-z0-9]+", "-", meta["title"].lower())[:40] or "deck"
    parts, titles, notes = [], [], []
    for n, s in enumerate(slides, 1):
        s["est"] = estimate(s)
        if s["est"] > BUDGET:
            (problems if allow_overflow else errors).append(f"slide {n} '{s['title']}': estimated {s['est']} lines, budget {BUDGET}; split it or cut")
        wide = any(b["t"] in ("table", "diagram", "cards", "cols", "code", "html") for b in s["blocks"])
        pieces, run = [], []
        def flush():
            if run: pieces.append('<div class="stats-grid">' + "".join(run) + "</div>"); run.clear()
        for b in s["blocks"]:
            if b["t"] == "stat": run.append(render_block(b, problems, n)); continue
            flush(); pieces.append(render_block(b, problems, n))
        flush()
        body = "".join(pieces)
        head = (f'<p class="kicker">{inline(s["kicker"])}</p>' if s["kicker"] else "")
        head += f'<h1 class="headline">{inline(s["title"])}</h1>'
        if s["sub"]: head += f'<p class="lede">{inline(s["sub"])}</p>'
        parts.append(f'<section class="slide {s["kind"]}" id="s{n}"><div class="slide-inner{" wide" if wide else ""}">{head}{body}</div></section>')
        titles.append(s["title"]); notes.append(" ".join(s["notes"]))
    body_html = "\n".join(parts)
    # No colour outside the token block: a hex or rgb literal in the rendered body is an error.
    for m in re.finditer(r"(#[0-9a-fA-F]{3,8}\b|rgba?\(|hsla?\()", body_html):
        (problems if allow_color else errors).append(f"colour literal '{m.group(1)}' in slide content; use var(--accent|--warn|--bad|--ok|--dim)")
        break
    toks = {**TOKENS_DARK, **{"l" + k: v for k, v in TOKENS_LIGHT.items()}}
    css = re.sub(r"%\((\w+)\)s", lambda m: toks[m.group(1)], CSS)   # CSS itself uses % (12%, 100%), so no %-format
    doc = f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{esc(meta["title"])}</title>
<script>(function(){{try{{var l=localStorage.getItem('deck-theme:{deck_id}')==='light'||location.search.indexOf('light=1')>-1;if(l)document.documentElement.classList.add('light');document.documentElement.setAttribute('data-theme',l?'light':'dark');}}catch(e){{}}}})();</script>
<style>{css}</style></head>
<body>
<div class="chrome">
  <button class="btn" id="strip-btn" aria-label="Toggle notes panel" title="notes panel (n)">{SVG_STRIP}</button>
  <button class="btn" id="notes-btn" aria-label="Open presenter notes window" title="presenter notes, second screen">{SVG_NOTES} notes ↗</button>
  <button class="btn" id="theme-btn" aria-label="Toggle light/dark" title="theme (t)">{SVG_SUN}</button>
</div>
<main class="deck">
{body_html}
</main>
<div class="slide-counter" id="num">1 / {len(slides)}</div>
<div class="nav-hint"><kbd>←</kbd> <kbd>→</kbd> slides · <kbd>n</kbd> notes · <kbd>t</kbd> theme</div>
<div class="notes-overlay" id="notes-overlay" hidden><div class="notes-panel"><p class="notes-kicker">Speaker notes</p><div class="notes-say" id="notes-say"></div></div></div>
<div class="presenter-view" id="pv"><div class="pv-head"><span>presenter</span><span class="pv-num"></span></div><div class="pv-title"></div><div class="pv-notes"></div><div class="pv-next"></div></div>
<script>var DECK_ID={json.dumps(deck_id)};var TITLES={json.dumps(titles)};var NOTES={json.dumps(notes)};</script>
<script>{JS}</script>
</body></html>
"""
    report = {"title": meta["title"], "slides": len(slides), "deck_id": deck_id,
              "estimates": [{"n": i + 1, "title": s["title"], "est": s["est"], "notes": bool(s["notes"])} for i, s in enumerate(slides)],
              "problems": problems, "errors": errors}
    return doc, report

def main(argv):
    if len(argv) < 2 or argv[1] in ("-h", "--help"): print(__doc__); return 2
    src_path = argv[1]; out = None; allow_overflow = allow_color = as_json = False
    i = 2
    while i < len(argv):
        if argv[i] == "-o": out = argv[i + 1]; i += 2
        elif argv[i] == "--allow-overflow": allow_overflow = True; i += 1
        elif argv[i] == "--allow-color": allow_color = True; i += 1
        elif argv[i] == "--json": as_json = True; i += 1
        else: print(f"render.py: unknown flag {argv[i]}", file=sys.stderr); return 2
    src = open(src_path, encoding="utf-8").read()
    doc, report = render(src, allow_overflow, allow_color)
    out = out or os.path.join(os.path.dirname(os.path.abspath(src_path)), "deck.html")
    with open(out, "w", encoding="utf-8") as f: f.write(doc)
    report["out"] = out
    if as_json: print(json.dumps(report, indent=2))
    else:
        print(f"deck: {report['slides']} slides -> {out}")
        for e in report["estimates"]:
            flag = " OVER" if e["est"] > BUDGET else ""
            print(f"  {e['n']:>2}  est {e['est']:>2}/{BUDGET}{flag}  {'notes' if e['notes'] else '     '}  {e['title']}")
        for p in report["problems"]: print(f"  note: {p}")
        for e in report["errors"]: print(f"  ERROR: {e}")
    return 1 if report["errors"] else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
