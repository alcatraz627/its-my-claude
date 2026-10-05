#!/usr/bin/env python3
"""Publish a set of markdown files into one Google Doc, one tab per file, styled by
the shared document spec, and keep it updated in place.

The markdown is the source of truth. The first run creates the Doc in the named
Drive folder; every run rewrites the Cover tab (the README, with its links to the
other files turned into links to their tabs) and one tab per file. Headings,
paragraphs, bullets, numbered lists, tables, code blocks, callouts, quotes, bold,
italic, inline code and links are recreated through the Docs API, in the fonts,
sizes, colours and table look of ~/.claude/scripts/shared/doc-style.json ("gdoc").

Auth is the signed-in gcloud account with a Drive scope (`gcloud auth login
--enable-gdrive-access`, once, by the owner). Nothing here talks to Slack or a bot.

Usage:
  gdoc.py <config.json> --confirm            publish (create or update)
  gdoc.py <config.json> --dry-run            parse the markdown and stop
  gdoc.py <config.json> --status             account, folder, doc id, scopes
  gdoc.py <config.json> --samples "<tab>"    append one sample of every block to that tab

Config (JSON): account, folder, title, cover (a markdown file, becomes the Cover
tab), docs (markdown paths, one tab each). Written back: doc_id, tabs {file: tabId}.
"""
import argparse
import json
import pathlib
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from html.parser import HTMLParser

DOCS = "https://docs.googleapis.com/v1/documents"
sys.path.insert(0, str(pathlib.Path.home() / ".claude" / "scripts" / "shared"))
import doc_style  # noqa: E402

DRIVE_SCOPES = ("https://www.googleapis.com/auth/drive", "https://www.googleapis.com/auth/drive.file",
                "https://www.googleapis.com/auth/documents")
G = doc_style.load_look("gdoc")
SPEC = {"callouts": G["callouts"]}
CALLOUT_RE = re.compile(r"^\[!(NOTE|TIP|WARNING|IMPORTANT|CAUTION)\]\s*")
SOFT_BREAK = "\u000b"  # a line break inside one paragraph, so a block keeps one box
SAMPLES_HEADING = "Blocks the document skills produce"


def is_stroke(ch):
    """Box drawing, arrows and arrowheads: the parts of a text diagram drawn lighter."""
    o = ord(ch)
    return 0x2190 <= o <= 0x21FF or 0x2500 <= o <= 0x257F or 0x25A0 <= o <= 0x25FF or 0x27F0 <= o <= 0x27FF


def sh(*cmd):
    return subprocess.run(cmd, capture_output=True, text=True, check=True).stdout.strip()


def gapi(tok, url, method="GET", body=None):
    req = urllib.request.Request(url, data=json.dumps(body).encode() if body is not None else None, method=method)
    req.add_header("Authorization", f"Bearer {tok}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=180) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        raise SystemExit(f"{method} {url.split('?')[0]} -> {e.code}: {e.read().decode(errors='replace')[:800]}")


def rgb(hexstr):
    h = hexstr.lstrip("#")
    return {"color": {"rgbColor": {"red": int(h[0:2], 16) / 255, "green": int(h[2:4], 16) / 255, "blue": int(h[4:6], 16) / 255}}}


def pt(n):
    return {"magnitude": n, "unit": "PT"}


def edge(hexcolor, width, padding):
    return {"color": rgb(hexcolor), "width": pt(width), "padding": pt(padding), "dashStyle": "SOLID"}


def box(fill, pad, left=None, right=True):
    """Paragraph borders drawn in the fill colour: invisible, but their padding gives the box room inside."""
    b = {"borderTop": edge(fill, 1, pad), "borderBottom": edge(fill, 1, pad)}
    if right: b["borderRight"] = edge(fill, 1, pad)
    b["borderLeft"] = edge(left[0], left[1], pad) if left else edge(fill, 1, pad)
    return b


def text_style(start, end, tab, font=None, weight=None, size=None, color=None, italic=None, offset=None):
    ts, f = {}, []
    if font: ts["weightedFontFamily"] = {"fontFamily": font, "weight": weight or 400}; f.append("weightedFontFamily")
    if size: ts["fontSize"] = pt(size); f.append("fontSize")
    if color: ts["foregroundColor"] = rgb(color); f.append("foregroundColor")
    if italic is not None: ts["italic"] = italic; f.append("italic")
    if offset: ts["baselineOffset"] = offset; f.append("baselineOffset")
    return {"updateTextStyle": {"range": {"startIndex": start, "endIndex": end, "tabId": tab}, "textStyle": ts, "fields": ",".join(f)}}


def stroke_spans(text):
    """UTF-16 [start, end) spans of the stroke characters in a diagram."""
    spans, i, start = [], 0, None
    for ch in text:
        if is_stroke(ch):
            if start is None: start = i
        elif start is not None:
            spans.append((start, i)); start = None
        i += u16(ch)
    if start is not None: spans.append((start, i))
    return spans


def highlight_requests(text, lang, start, tab):
    """Token colours from pygments (the same tango palette pandoc uses in Word), merged into runs."""
    try:
        from pygments.lexers import get_lexer_by_name
        from pygments.styles import get_style_by_name
        from pygments.util import ClassNotFound
    except ImportError:
        print("  note: pygments missing, code left uncoloured (run with --with pygments)"); return []
    try:
        lexer = get_lexer_by_name(lang, stripnl=False, ensurenl=False)
    except ClassNotFound:
        return []
    style = get_style_by_name(G["code"]["highlight"])
    spans, i = [], 0
    for ttype, value in lexer.get_tokens(text):
        n = u16(value)
        st = style.style_for_token(ttype)
        key = (st["color"], st["bold"], st["italic"])
        if value.strip() and (st["color"] or st["bold"] or st["italic"]):
            if spans and spans[-1][2] == key and spans[-1][1] == i:
                spans[-1][1] = i + n
            else:
                spans.append([i, i + n, key])
        i += n
    reqs = []
    for a, z, (color, bold, italic) in spans:
        ts, f = {"bold": bool(bold), "italic": bool(italic)}, ["bold", "italic"]
        if color: ts["foregroundColor"] = rgb(color); f.append("foregroundColor")
        reqs.append({"updateTextStyle": {"range": {"startIndex": start + a, "endIndex": start + z, "tabId": tab}, "textStyle": ts, "fields": ",".join(f)}})
    return reqs


def paragraphs(content):
    """Every paragraph in a body, including those inside table cells."""
    for el in content:
        if "paragraph" in el:
            yield el["paragraph"]
        elif "table" in el:
            for row in el["table"]["tableRows"]:
                for cell in row["tableCells"]:
                    yield from paragraphs(cell["content"])


def place_objects(tok, doc_id, tid):
    """Swap each object marker for the image, chip, footnote or page break it stands for, last first."""
    body = tab_body(get_doc(tok, doc_id), tid)
    found = []
    for p in paragraphs(body.get("content", [])):
        for x in p["elements"]:
            tr = x.get("textRun")
            if not tr: continue
            for m in OBJ_RE.finditer(tr["content"]):
                found.append((x["startIndex"] + u16(tr["content"][:m.start()]), u16(m.group(0)), int(m.group(1))))
    if not found: return 0
    reqs, notes = [], []
    for idx, n, k in sorted(found, reverse=True):
        kind, o = OBJECTS[k]
        loc = {"index": idx, "tabId": tid}
        reqs.append({"deleteContentRange": {"range": {"startIndex": idx, "endIndex": idx + n, "tabId": tid}}})
        if kind == "image":
            ok = o["uri"].startswith(("http://", "https://")) and o["uri"].lower().split("?")[0].endswith((".png", ".jpg", ".jpeg", ".gif"))
            if ok:
                reqs.append({"insertInlineImage": {"location": loc, "uri": o["uri"]}})
            else:
                print(f"  note: image {o['uri']!r} is not a public PNG, JPEG or GIF URL; its alt text stands in")
                reqs.append({"insertText": {"location": loc, "text": f"[{o['alt'] or 'image'}]"}})
        elif kind == "person":
            reqs.append({"insertPerson": {"location": loc, "personProperties": {"email": o["email"]}}})
        elif kind == "date":
            reqs.append({"insertDate": {"location": loc, "dateElementProperties": {"timestamp": o["date"] + "T12:00:00Z"}}})
        elif kind == "richlink":
            reqs.append({"insertRichLink": {"location": loc, "richLinkProperties": {"uri": o["uri"]}}})
        elif kind == "pagebreak":
            reqs.append({"insertPageBreak": {"location": loc}})
        elif kind == "footnote":
            reqs.append({"createFootnote": {"location": loc}})
            notes.append(o["text"])
    replies = gapi(tok, f"{DOCS}/{doc_id}:batchUpdate", "POST", {"requests": reqs}).get("replies", [])
    ids = [r["createFootnote"]["footnoteId"] for r in replies if "createFootnote" in r]
    if ids:
        batch(tok, doc_id, [{"insertText": {"endOfSegmentLocation": {"segmentId": fid, "tabId": tid}, "text": text}}
                            for fid, text in zip(ids, notes)])
    return len(found)


def strip_md(text):
    text = re.sub(r"^---\n.*?\n---\n", "", text, count=1, flags=re.S)
    return re.sub(r"<!-- sessions: .*? -->\n?", "", text)


# A block is ("h", level, runs) ("p", runs) ("li", depth, ordered, runs) ("code", text, lang) ("diagram", text)
# ("table", rows, meta) ("callout", KIND, runs) ("quote", runs) ("rule",). A run is (text, set of styles).
# meta is {"variant": "main"|"light", "header": bool}.

class Blocks(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.blocks, self.runs, self.style, self.list_stack = [], [], [], []
        self.in_pre, self.pre_text, self.table, self.row, self.cell = False, "", None, None, None
        self.block_kind, self.quote_depth, self.next_variant = None, 0, "main"

    def handle_comment(self, data):
        m = re.match(r"\s*table:\s*(\w+)", data)
        if m: self.next_variant = m.group(1)

    def _flush(self):
        if self.block_kind and self.runs:
            kind = self.block_kind
            if kind[0] == "p" and self.quote_depth:
                first = self.runs[0][0]
                m = CALLOUT_RE.match(first)
                if m:
                    self.runs[0] = (first[m.end():], self.runs[0][1])
                    kind = ("callout", m.group(1))
                else:
                    kind = ("quote",)
            self.blocks.append(kind + (self.runs,))
        self.block_kind, self.runs = None, []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
            self._flush(); self.block_kind = ("h", int(tag[1]))
        elif tag == "p":
            if self.cell is None:
                self._flush(); self.block_kind = ("p",)
        elif tag in ("ul", "ol"):
            self._flush(); self.list_stack.append(tag == "ol")
        elif tag == "li":
            self._flush(); self.block_kind = ("li", len(self.list_stack), self.list_stack[-1] if self.list_stack else False)
        elif tag == "pre":
            self._flush(); self.in_pre, self.pre_text, self.pre_lang = True, "", ""
        elif tag == "table":
            self._flush(); self.table = []
        elif tag == "tr":
            self.row = []
        elif tag in ("td", "th"):
            self.cell = []
        elif tag in ("strong", "b"):
            self.style.append("bold")
        elif tag in ("em", "i"):
            self.style.append("italic")
        elif tag == "code" and self.in_pre:
            self.pre_lang = (a.get("class") or "").replace("language-", "").split(" ")[0]
        elif tag == "code" and not self.in_pre:
            self.style.append("code")
        elif tag == "a":
            self.style.append("link:" + a.get("href", ""))
        elif tag == "br":
            self.handle_data("\n")
        elif tag == "img":
            self.handle_data(obj_marker("image", {"uri": a.get("src", ""), "alt": a.get("alt", "")}))
        elif tag == "hr":
            self._flush(); self.blocks.append(("rule",))
        elif tag == "blockquote":
            self._flush(); self.quote_depth += 1

    def handle_endtag(self, tag):
        if tag in ("h1", "h2", "h3", "h4", "h5", "h6", "p", "li"):
            self._flush()
        elif tag in ("ul", "ol"):
            self._flush()
            if self.list_stack: self.list_stack.pop()
        elif tag == "pre":
            self.in_pre = False
            if self.pre_lang in ("", "diagram", "ascii", "text"):
                self.blocks.append(("diagram", self.pre_text.rstrip("\n")))
            else:
                self.blocks.append(("code", self.pre_text.rstrip("\n"), self.pre_lang))
        elif tag in ("td", "th"):
            self.row.append(self.cell); self.cell = None
        elif tag == "tr":
            if self.row: self.table.append(self.row)
            self.row = None
        elif tag == "table":
            rows, header = self.table, True
            if rows and not any(runs_text(c).strip() for c in rows[0]):
                rows, header = rows[1:], False  # an empty header row: a header-less card table
            self.blocks.append(("table", rows, {"variant": self.next_variant, "header": header}))
            self.table, self.next_variant = None, "main"
        elif tag in ("strong", "b", "em", "i", "a") or (tag == "code" and not self.in_pre):
            if self.style: self.style.pop()
        elif tag == "blockquote":
            self._flush(); self.quote_depth = max(0, self.quote_depth - 1)

    def handle_data(self, data):
        if self.in_pre:
            self.pre_text += data; return
        if self.cell is not None:
            self.cell.append((data, set(self.style))); return
        if self.block_kind is None:
            if not data.strip(): return
            self.block_kind = ("p",)
        self.runs.append((data.replace("\n", " "), set(self.style)))


OBJECTS = []  # inline objects placed after the text pass: (kind, payload)
OBJ_RE = re.compile("⁣O(\\d+)⁣")
RICH_HOSTS = ("docs.google.com", "drive.google.com", "sheets.google.com", "slides.google.com")


def obj_marker(kind, payload):
    OBJECTS.append((kind, payload))
    return f"⁣O{len(OBJECTS) - 1}⁣"


def md_blocks(text):
    import markdown  # provided by `uv run --with markdown`
    # Footnotes: the definitions leave the text and each reference becomes an object marker.
    notes = dict(re.findall(r"^\[\^([^\]]+)\]:\s*(.+)$", text, flags=re.M))
    text = re.sub(r"^\[\^[^\]]+\]:.*\n?", "", text, flags=re.M)
    text = re.sub(r"\[\^([^\]]+)\]", lambda m: obj_marker("footnote", {"text": notes.get(m.group(1), "")}) if m.group(1) in notes else m.group(0), text)
    h = markdown.Markdown(extensions=["tables", "fenced_code", "sane_lists"]).convert(text)
    p = Blocks(); p.feed(h); p._flush()
    return pad_inline_code(chips(p.blocks))


def chips(blocks):
    """Links shaped like a person, a date or a Google file become chips; a \\newpage paragraph becomes a page break."""
    def fix(runs):
        out = []
        for t, st in runs:
            link = next((s[5:] for s in st if s.startswith("link:")), None)
            if link and link.startswith("mailto:"):
                out.append((obj_marker("person", {"email": link[7:], "name": t}), set()))
            elif link and link.startswith("date:"):
                out.append((obj_marker("date", {"date": link[5:], "text": t}), set()))
            elif link and t.strip() == link and urllib.parse.urlparse(link).hostname in RICH_HOSTS:
                out.append((obj_marker("richlink", {"uri": link}), set()))
            else:
                out.append((t, st))
        return out
    fixed = []
    for b in blocks:
        if b[0] == "p" and runs_text(b[1]).strip() == "\\newpage":
            fixed.append(("p", [(obj_marker("pagebreak", {}), set())]))
        elif b[0] in ("h", "p", "li", "callout", "quote"):
            fixed.append(b[:-1] + (fix(b[-1]),))
        elif b[0] == "table":
            fixed.append(("table", [[fix(c) for c in r] for r in b[1]], b[2]))
        else:
            fixed.append(b)
    return fixed


def pad_inline_code(blocks):
    """Docs has no padding on a text run, so inline code gets a thin space either side in the same tint."""
    pad = G["inline_code"]["pad"]
    def fix(runs):
        out = []
        for t, st in runs:
            if "code" in st and t:
                out += [(pad, {"codepad"}), (t, st), (pad, {"codepad"})]
            else:
                out.append((t, st))
        return out
    fixed = []
    for b in blocks:
        if b[0] in ("h", "p", "li", "callout", "quote"):
            fixed.append(b[:-1] + (fix(b[-1]),))
        elif b[0] == "table":
            fixed.append(("table", [[fix(c) for c in r] for r in b[1]], b[2]))
        else:
            fixed.append(b)
    return fixed


def u16(s):
    return len(s.encode("utf-16-le")) // 2


def runs_text(runs):
    return "".join(t for t, _ in runs)


def relink(blocks, link_map):
    """Turn links to markdown files into links to their tabs."""
    def fix(runs):
        out = []
        for t, st in runs:
            st = set(st)
            for s in list(st):
                if s.startswith("link:"):
                    target = s[5:].split("#")[0]
                    if target in link_map:
                        st.discard(s); st.add("link:" + link_map[target])
            out.append((t, st))
        return out
    fixed = []
    for b in blocks:
        if b[0] in ("h", "p", "li", "callout", "quote"):
            fixed.append(b[:-1] + (fix(b[-1]),))
        elif b[0] == "table":
            fixed.append(("table", [[fix(c) for c in r] for r in b[1]], b[2]))
        else:
            fixed.append(b)
    return fixed


def style_requests(runs, start, tab, base_size=None):
    out, i = [], start
    for text, st in runs:
        n = u16(text)
        if n and st:
            ts, fields = {}, []
            if "bold" in st: ts["bold"] = True; fields.append("bold")
            if "italic" in st: ts["italic"] = True; fields.append("italic")
            if "code" in st:
                ts["weightedFontFamily"] = {"fontFamily": G["fonts"]["mono"]}; fields.append("weightedFontFamily")
                ts["backgroundColor"] = rgb(G["palette"]["code_bg"]); fields.append("backgroundColor")
                ts["fontSize"] = pt((base_size or G["sizes"]["body"]) + G["inline_code"]["size_delta"]); fields.append("fontSize")
            if "codepad" in st:
                ts["backgroundColor"] = rgb(G["palette"]["code_bg"]); fields.append("backgroundColor")
            link = next((s[5:] for s in st if s.startswith("link:")), None)
            if link and link.startswith("http"):
                ts["link"] = {"url": link}; fields.append("link")
            if fields:
                out.append({"updateTextStyle": {"range": {"startIndex": i, "endIndex": i + n, "tabId": tab},
                                                "textStyle": ts, "fields": ",".join(fields)}})
        i += n
    return out


def named_style_requests(tab):
    """The heading ramp, title, subtitle and body from the spec, set on the tab's named styles."""
    f, sz, col, wt, sp = G["fonts"], G["sizes"], G["heading_colors"], G["heading_weights"], G["spacing"]
    reqs = []
    def one(name, key, font):
        ts = {"weightedFontFamily": {"fontFamily": font, "weight": wt.get(key, 400)}, "fontSize": pt(sz[key]), "bold": False, "italic": key == "h6"}
        fields = ["weightedFontFamily", "fontSize", "bold", "italic"]
        if key in col: ts["foregroundColor"] = rgb(col[key]); fields.append("foregroundColor")
        ps, pfields = {}, []
        if key in sp:
            ps = {"spaceAbove": pt(sp[key][0]), "spaceBelow": pt(sp[key][1])}; pfields = ["spaceAbove", "spaceBelow"]
        if key.startswith("h"):
            ps["keepWithNext"] = True; pfields.append("keepWithNext")
        reqs.append({"updateNamedStyle": {"tabId": tab, "namedStyle": {"namedStyleType": name, "textStyle": ts, "paragraphStyle": ps},
                                          "fields": ",".join(["namedStyleType"] + ["textStyle." + x for x in fields] + ["paragraphStyle." + x for x in pfields])}})
    one("NORMAL_TEXT", "body", f["body"]); one("TITLE", "title", f["title"]); one("SUBTITLE", "subtitle", f["title"])
    for i in range(1, 7): one(f"HEADING_{i}", f"h{i}", f["heading"] if i < 6 else f["body"])
    return reqs


def tab_requests(blocks, tab):
    """Text pass: everything but tables, appended in order; a table leaves a marker paragraph."""
    reqs, cursor, markers = [], 1, []
    def para(text, pstyle):
        nonlocal cursor
        t = text + "\n"
        reqs.append({"insertText": {"location": {"index": cursor, "tabId": tab}, "text": t}})
        start = cursor; cursor += u16(t)
        reqs.append({"updateParagraphStyle": {"range": {"startIndex": start, "endIndex": cursor, "tabId": tab},
                                              "paragraphStyle": pstyle, "fields": ",".join(pstyle)}})
        return start
    # Google reads leading tabs as nesting only when one bullets request covers the whole list.
    run = None  # [start, tabs, preset] of the list being written
    def end_list():
        nonlocal cursor, run
        if run:
            reqs.append({"createParagraphBullets": {"range": {"startIndex": run[0], "endIndex": cursor, "tabId": tab}, "bulletPreset": run[2]}})
            cursor -= run[1]  # the request consumes the leading tabs it used for nesting
            run = None
    boxed, prev = ("code", "diagram", "callout", "quote"), None
    for b in blocks:
        kind = b[0]
        if kind != "li":
            end_list()
        if kind in boxed and prev in boxed:
            # Google fuses adjacent paragraphs whose borders match; a small empty line keeps two boxes apart.
            s = para("", {"namedStyleType": "NORMAL_TEXT", "spaceAbove": pt(0), "spaceBelow": pt(0), "lineSpacing": 100})
            reqs.append(text_style(s, s + 1, tab, size=4))
        prev = kind
        if kind == "h":
            s = para(runs_text(b[2]), {"namedStyleType": f"HEADING_{min(b[1], 6)}"})
            reqs += style_requests(b[2], s, tab)
        elif kind == "p":
            s = para(runs_text(b[1]), {"namedStyleType": "NORMAL_TEXT"})
            reqs += style_requests(b[1], s, tab)
        elif kind == "li":
            depth, ordered, runs = b[1], b[2], list(b[3])
            lead = max(depth - 1, 0)
            L = G["lists"]
            check = runs and re.match(r"^\[[ xX]\]\s+", runs[0][0])
            if check:
                runs[0] = (runs[0][0][check.end():], runs[0][1])
            s = para("\t" * lead + runs_text(runs), {"namedStyleType": "NORMAL_TEXT", "lineSpacing": L["line_spacing"],
                                                     "spaceAbove": pt(L["space_above"]), "spaceBelow": pt(L["space_below"])})
            reqs += style_requests(runs, s + lead, tab)
            if run is None:
                run = [s, 0, "BULLET_CHECKBOX" if check else "NUMBERED_DECIMAL_ALPHA_ROMAN" if ordered else "BULLET_DISC_CIRCLE_SQUARE"]
            run[1] += lead
        elif kind in ("code", "diagram"):
            C, bg = G["code"], G["palette"]["code_bg"]
            text = b[1].replace("\n", SOFT_BREAK)
            bar = (C["bar"], C["bar_pt"]) if kind == "code" else None
            s = para(text, {"namedStyleType": "NORMAL_TEXT", "shading": {"backgroundColor": rgb(bg)}, **box(bg, C["pad_pt"], left=bar),
                            "indentStart": pt(C["pad_pt"]), "indentFirstLine": pt(C["pad_pt"]), "indentEnd": pt(C["pad_pt"]),
                            "spaceAbove": pt(C["space_pt"]), "spaceBelow": pt(C["space_pt"]), "lineSpacing": C["line_spacing"], "keepLinesTogether": True})
            weight = C["weight"] if kind == "code" else C["diagram_weight"]
            reqs.append(text_style(s, cursor, tab, font=G["fonts"]["mono"], weight=weight, size=G["sizes"]["code"]))
            if kind == "diagram":
                for a, z in stroke_spans(text):
                    reqs.append(text_style(s + a, s + z, tab, font=G["fonts"]["mono"], weight=C["stroke_weight"], color=C["stroke"]))
            else:
                reqs += highlight_requests(b[1], b[2], s, tab)
        elif kind == "callout":
            c, K = SPEC["callouts"][b[1]], G["callout"]
            label = f"{c['glyph']} {c['label'].upper() if K['label_upper'] else c['label']}"
            s = para(label + SOFT_BREAK + runs_text(b[2]),
                     {"namedStyleType": "NORMAL_TEXT", "shading": {"backgroundColor": rgb(c["fill"])},
                      **box(c["fill"], K["pad_pt"], left=(c["bar"], K["bar_pt"])),
                      "indentStart": pt(K["indent_pt"]), "indentFirstLine": pt(K["indent_pt"]), "indentEnd": pt(K["pad_pt"]),
                      "spaceAbove": pt(K["space_pt"]), "spaceBelow": pt(K["space_pt"]), "lineSpacing": 115})
            reqs.append(text_style(s, cursor, tab, font=K["body_font"], weight=K["body_weight"], size=K["body_pt"], color=K["body_color"]))
            reqs.append(text_style(s, s + u16(label), tab, font=K["label_font"], weight=K["label_weight"], size=K["label_pt"], color=c["bar"]))
            if c.get("glyph_pt"):  # JetBrains Mono draws ◈ at about half the size of its other glyphs
                reqs.append(text_style(s, s + u16(c["glyph"]), tab, font=K["label_font"], weight=K["label_weight"], size=c["glyph_pt"], color=c["bar"]))
            reqs += style_requests(b[2], s + u16(label) + 1, tab, base_size=K["body_pt"])
        elif kind == "quote":
            Q = G["quote"]
            mark = Q["mark"] + " "
            s = para(mark + runs_text(b[1]),
                     {"namedStyleType": "NORMAL_TEXT", "shading": {"backgroundColor": rgb(Q["fill"])},
                      **box(Q["fill"], Q["pad_pt"], left=(Q["bar"], Q["bar_pt"])),
                      "indentStart": pt(Q["indent_pt"]), "indentFirstLine": pt(Q["indent_pt"]), "indentEnd": pt(Q["pad_pt"]),
                      "spaceAbove": pt(Q["space_pt"]), "spaceBelow": pt(Q["space_pt"]), "lineSpacing": 115})
            reqs.append(text_style(s, cursor, tab, font=Q["font"], size=Q["pt"], color=Q["color"], italic=Q["italic"]))
            reqs.append(text_style(s, s + 1, tab, font=Q.get("mark_font") or Q["font"], size=Q["mark_pt"], color=Q["mark_color"], italic=False, offset=Q["mark_offset"]))
            reqs += style_requests(b[1], s + u16(mark), tab, base_size=Q["pt"])
        elif kind == "rule":
            R = G["rule"]
            para("", {"namedStyleType": "NORMAL_TEXT", "borderBottom": edge(R["color"], R["pt"], 0),
                      "spaceAbove": pt(R["space_pt"]), "spaceBelow": pt(R["space_pt"])})
        elif kind == "table":
            marker = f"⁣TABLE{len(markers)}⁣"
            para(marker, {"namedStyleType": "NORMAL_TEXT"})
            markers.append((b[1], b[2]))
    end_list()
    return reqs, markers


def find_markers(tab_body):
    out = []
    for el in tab_body.get("content", []):
        p = el.get("paragraph")
        if not p: continue
        text = "".join(x.get("textRun", {}).get("content", "") for x in p["elements"])
        m = re.match(r"⁣TABLE(\d+)⁣\n", text)
        if m: out.append((int(m.group(1)), el["startIndex"], el["endIndex"]))
    return out


def table_insert_requests(markers_found, tables, tab):
    reqs = []
    for idx, start, end in sorted(markers_found, key=lambda x: -x[1]):
        rows = tables[idx][0]
        reqs.append({"deleteContentRange": {"range": {"startIndex": start, "endIndex": end - 1, "tabId": tab}}})
        reqs.append({"insertTable": {"rows": len(rows), "columns": max(len(r) for r in rows), "location": {"index": start, "tabId": tab}}})
    return reqs


def column_widths(rows):
    """Proportional to the longest cell in each column, clamped so a short column stays narrow."""
    T = G["table"]
    cols = max(len(r) for r in rows)
    weights, words = [], []
    for c in range(cols):
        texts = [runs_text(r[c]) for r in rows if c < len(r)]
        longest = max((len(t) for t in texts), default=0)
        weights.append(min(max(longest, T["min_col_weight"]), T["max_col_weight"]))
        body_word = max((len(w) for t in texts[1:] for w in t.split()), default=0)
        head_word = max((len(w) for w in texts[0].split()), default=0) if texts else 0
        words.append(max(body_word * 5.8, head_word * 6.6))  # Comfortaa headers set wider than the body
    total = sum(weights) or 1
    widths = [T["page_width_pt"] * w / total for w in weights]
    # Every column gets its longest word unbroken, taken from the widest columns so the table still fits.
    need = [min(n + 2 * T["padding_pt"] + 6, T["page_width_pt"] / 2) for n in words]
    page, floor = T["page_width_pt"], 24
    if sum(need) > page * 0.8:
        # Not every word fits with room for text: cap the longest-word columns so the short ones stay whole.
        lo, hi = 0.0, max(need)
        for _ in range(40):
            cap = (lo + hi) / 2
            lo, hi = (cap, hi) if sum(min(n, cap) for n in need) < page * 0.8 else (lo, cap)
        need = [min(n, lo) for n in need]
    short = sum(max(0, n - w) for n, w in zip(need, widths))
    if short:
        spare = sum(max(0, w - n) for n, w in zip(need, widths)) or 1
        widths = [n if n > w else w - (w - n) * short / spare for n, w in zip(need, widths)]
    widths = [max(w, floor) for w in widths]
    return [round(w * page / sum(widths), 2) for w in widths]


def cell_range(loc, row, col, nrows, ncols):
    return {"tableCellLocation": {"tableStartLocation": loc, "rowIndex": row, "columnIndex": col}, "rowSpan": nrows, "columnSpan": ncols}


def cell_style(rng, style):
    return {"updateTableCellStyle": {"tableRange": rng, "tableCellStyle": style, "fields": ",".join(style)}}


def table_style_requests(tab_body, tables_in_order, tab):
    """Column widths, borders, padding, fills for each table's variant, then the cell text, last cell first."""
    T, TL = G["table"], G["table_light"]
    reqs, tables = [], [el for el in tab_body.get("content", []) if "table" in el][-len(tables_in_order):]
    def line(color, width, dash=T["dash"]):
        return {"color": rgb(color), "width": pt(width), "dashStyle": dash}
    pad = pt(T["padding_pt"])
    cells = []
    for el, (rows, meta) in zip(tables, tables_in_order):
        t, loc = el["table"], {"index": el["startIndex"], "tabId": tab}
        nrows, ncols = t["rows"], t["columns"]
        light, header = meta["variant"] == "light", meta["header"]
        for ci, w in enumerate(column_widths(rows)):
            reqs.append({"updateTableColumnProperties": {"tableStartLocation": loc, "columnIndices": [ci],
                                                         "tableColumnProperties": {"widthType": "FIXED_WIDTH", "width": pt(w)}, "fields": "width,widthType"}})
        whole = cell_range(loc, 0, 0, nrows, ncols)
        edges = ("borderTop", "borderBottom", "borderLeft", "borderRight")
        if light:
            # No fill and no verticals: white edges everywhere, then a separator under every row, then the header rule.
            reqs.append(cell_style(whole, {**{e: line("FFFFFF", 1, "SOLID") for e in edges},
                                           "paddingTop": pad, "paddingBottom": pad, "paddingLeft": pad, "paddingRight": pad}))
            reqs.append(cell_style(whole, {"borderBottom": line(TL["separator"], TL["separator_pt"], TL["dash"])}))
            if header:
                reqs.append(cell_style(cell_range(loc, 0, 0, 1, ncols), {"borderBottom": line(TL["rule"], TL["rule_pt"], TL["dash"])}))
        else:
            reqs.append(cell_style(whole, {**{e: line(T["border"], T["border_pt"]) for e in edges},
                                           "paddingTop": pad, "paddingBottom": pad, "paddingLeft": pad, "paddingRight": pad}))
            if header:
                # After the body grid, so the edge the two share takes the header colour.
                reqs.append(cell_style(cell_range(loc, 0, 0, 1, ncols), {"backgroundColor": rgb(T["header_fill"]),
                                                                         **{e: line(T["header_border"], T["border_pt"]) for e in edges}}))
            first = 1 if header else 0
            if T["first_col"] and nrows > first:
                reqs.append(cell_style(cell_range(loc, first, 0, nrows - first, 1), {"backgroundColor": rgb(T["first_col_fill"])}))
        if header and T.get("pin_header") and nrows > 1:
            reqs.append({"pinTableHeaderRows": {"tableStartLocation": loc, "pinnedHeaderRowsCount": 1}})
        # A row moves whole to the next page rather than splitting.
        reqs.append({"updateTableRowStyle": {"tableStartLocation": loc, "rowIndices": list(range(nrows)), "tableRowStyle": {"preventOverflow": True}, "fields": "preventOverflow"}})
        head_color = TL["header_text"] if light else T["header_text"]
        for r, trow in enumerate(t["tableRows"]):
            for c, tcell in enumerate(trow["tableCells"]):
                runs = rows[r][c] if r < len(rows) and c < len(rows[r]) else []
                cells.append((tcell["content"][0]["startIndex"], runs, header and r == 0, head_color, c == 0 and r >= (1 if header else 0)))
    for start, runs, is_head, head_color, is_label in sorted(cells, key=lambda x: -x[0]):
        text = runs_text(runs).strip(" \t\n")  # not .strip(): it would eat the thin spaces padding inline code
        end = start + u16(text) if text else start + 1
        if text:
            reqs.append({"insertText": {"location": {"index": start, "tabId": tab}, "text": text}})
        ts = {"fontSize": pt(T["font_pt"]), "weightedFontFamily": {"fontFamily": T["header_font"] if is_head else T["body_font"]}, "bold": bool((is_label and T.get("bold_first_col")) or (is_head and T.get("header_bold"))),
              "foregroundColor": rgb(head_color if is_head else T["text"])}
        reqs.append({"updateTextStyle": {"range": {"startIndex": start, "endIndex": end, "tabId": tab}, "textStyle": ts,
                                         "fields": "fontSize,weightedFontFamily,bold,foregroundColor"}})
        reqs.append({"updateParagraphStyle": {"range": {"startIndex": start, "endIndex": end, "tabId": tab},
                                              "paragraphStyle": {"spaceAbove": pt(0), "spaceBelow": pt(0), "lineSpacing": T["line_spacing"]},
                                              "fields": "spaceAbove,spaceBelow,lineSpacing"}})
        if text and not is_head:
            reqs += style_requests(list(runs), start, tab, base_size=T["font_pt"])
            # A bulleted line inside a cell hangs its wrapped text under the first word, with a little air below.
            off = 0
            for line_text in text.split("\n"):
                if line_text.startswith("\u2022 "):
                    a = start + off; z = a + u16(line_text)
                    reqs.append({"updateParagraphStyle": {"range": {"startIndex": a, "endIndex": z, "tabId": tab},
                                                          "paragraphStyle": {"indentStart": pt(9), "indentFirstLine": pt(0), "spaceBelow": pt(2)},
                                                          "fields": "indentStart,indentFirstLine,spaceBelow"}})
                off += u16(line_text) + 1
    return reqs


def get_doc(tok, doc_id):
    return gapi(tok, f"{DOCS}/{doc_id}?includeTabsContent=true")


def batch(tok, doc_id, requests, chunk=400):
    for i in range(0, len(requests), chunk):
        gapi(tok, f"{DOCS}/{doc_id}:batchUpdate", "POST", {"requests": requests[i:i + chunk]})


def tab_body(doc, tab_id):
    def walk(tabs):
        for t in tabs:
            if t["tabProperties"]["tabId"] == tab_id: return t["documentTab"]["body"]
            r = walk(t.get("childTabs", []))
            if r: return r
    return walk(doc.get("tabs", []))


def write_tab(tok, doc_id, tid, blocks, clear=True):
    body = tab_body(get_doc(tok, doc_id), tid)
    end = body["content"][-1]["endIndex"]
    if clear and end > 2:
        batch(tok, doc_id, [{"deleteContentRange": {"range": {"startIndex": 1, "endIndex": end - 1, "tabId": tid}}}])
    reqs, tables = tab_requests(blocks, tid)
    if not clear:
        shift = end - 2  # append before the tab's final newline, which the API keeps
        for r in reqs:
            for k in ("insertText",):
                if k in r: r[k]["location"]["index"] += shift
            for k in ("updateParagraphStyle", "updateTextStyle", "createParagraphBullets"):
                if k in r: r[k]["range"]["startIndex"] += shift; r[k]["range"]["endIndex"] += shift
    batch(tok, doc_id, named_style_requests(tid) + reqs)
    if tables:
        body = tab_body(get_doc(tok, doc_id), tid)
        batch(tok, doc_id, table_insert_requests(find_markers(body), tables, tid))
        body = tab_body(get_doc(tok, doc_id), tid)
        batch(tok, doc_id, table_style_requests(body, tables, tid))
    place_objects(tok, doc_id, tid)
    return len(reqs), len(tables)


SAMPLES_MD = "## " + SAMPLES_HEADING + """

Every block /gdoc and /word-doc can write, once each, in the shared style. Compare against the samples above and change the spec, not the document.

### Paragraph with inline styles

Plain text with **bold**, *italic*, `inline code`, and [a link](https://example.com). Sentences are short and the point comes first.

### Bullets

- A first point
- A second point, with a nested list
    - A nested point
    - Another nested point
- A third point

### Numbered steps

1. Read the spec
2. Change the spec, not the document
3. Re-run the skill

### Checklist

- [ ] Review the Style Guide
- [ ] Change the spec
- [ ] Re-run both skills

### Table

| Column | What it holds | Why it matters |
|---|---|---|
| Source | A logical feed | Each upload is a generation |
| Claim | One source's value for one field | Never overwritten |
| Revision | The whole catalog at one moment | Every export pins one |

### Table, light variant

A comment line `<!-- table: light -->` before a table picks the light variant, for lighter concerns.

<!-- table: light -->
| Column | What it holds | Why it matters |
|---|---|---|
| Source | A logical feed | Each upload is a generation |
| Claim | One source's value for one field | Never overwritten |
| Revision | The whole catalog at one moment | Every export pins one |

### Card table

An empty header row makes a card: no header, the first column tinted.

| | |
|---|---|
| For | Engineering |
| Serves | The technical discussion with the team |
| Answers to | Doc 02 for the words |

### Code block

```python
def current(field, claims, order):
    # the first ranked source wins
    ranked = [c for s in order for c in claims if c.source == s]
    return ranked[0] if ranked else None
```

```markdown
## A heading in markdown

Some **bold** text, a [link](https://example.com), and a list:

- one
- two
```

### Text diagram

```
  Source ─▶ Source file ─▶ Source row ─▶ Claim ─▶ Record ─▶ Revision
```

### Callouts

> [!NOTE] A note carries context the reader can skip.

> [!TIP] A tip names a shortcut worth taking.

> [!WARNING] A warning names a way to lose data or time.

> [!IMPORTANT] An important block names the one thing the reader must not miss.

> [!CAUTION] A caution names an irreversible action.

### Quote

> Stop arguing about the model in a meeting; argue about row 41.

### Rich content

A footnote sits at the end of a sentence.[^1] Chips carry live objects: a person, [Aakarsh](mailto:aakarsh@versable.ai), a date, [Oct 1, 2026](date:2026-10-01), and a Google file as a rich link: <DOC_URL>

An inline image from a public URL:

![Sample image](https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png)

A rule separates sections:

---

Text after the rule.

[^1]: A footnote is written as [^1] in the text and a [^1]: line anywhere in the file.
"""


def archive(tok, doc_id, cfg, confirm):
    """Retire an old Doc: its title (the Drive file name) gains an [Archive] prefix, then it goes to the trash.

    Trash, not permanent delete: Drive keeps it restorable for 30 days. Refuses a Doc outside the
    config's folder or the Doc the config currently publishes to."""
    files = "https://www.googleapis.com/drive/v3/files"
    meta = gapi(tok, f"{files}/{doc_id}?fields=id,name,parents,trashed&supportsAllDrives=true")
    print(f"archive  {meta['name']!r}  ({doc_id}), trashed={meta.get('trashed')}")
    if doc_id == cfg.get("doc_id"):
        print("STOP: that is the Doc this config publishes to."); return 2
    if cfg["folder"] not in meta.get("parents", []):
        print(f"STOP: the Doc is not in the config's folder {cfg['folder']}."); return 2
    if not confirm:
        print("STOP: re-run with --confirm to rename and trash it."); return 2
    name = meta["name"] if meta["name"].startswith("[Archive]") else "[Archive] " + meta["name"]
    gapi(tok, f"{files}/{doc_id}?supportsAllDrives=true", "PATCH", {"name": name})
    done = gapi(tok, f"{files}/{doc_id}?supportsAllDrives=true&fields=name,trashed", "PATCH", {"trashed": True})
    print(f"archived {done['name']!r}, trashed={done['trashed']} (restore from Drive's trash within 30 days)")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("config"); ap.add_argument("--confirm", action="store_true")
    ap.add_argument("--dry-run", action="store_true"); ap.add_argument("--status", action="store_true")
    ap.add_argument("--samples", metavar="TAB", help="append one sample of every block to the named tab")
    ap.add_argument("--archive", metavar="DOC_ID", help="with --confirm: prefix a Doc's title with [Archive] and move it to Drive's trash")
    a = ap.parse_args()
    cfg_path = pathlib.Path(a.config).resolve(); cfg = json.loads(cfg_path.read_text()); base = cfg_path.parent
    acct = sh("gcloud", "auth", "list", "--filter=status:ACTIVE", "--format=value(account)")
    print(f"account  {acct}  (expected {cfg['account']})")
    print(f"folder   https://drive.google.com/drive/folders/{cfg['folder']}")
    print(f"title    {cfg['title']}")
    print(f"doc_id   {cfg.get('doc_id') or '(none yet: first run creates the Doc)'}")
    if acct != cfg["account"]:
        print(f"STOP: active gcloud account is not {cfg['account']}."); return 2

    files = [cfg["cover"]] + list(cfg["docs"])
    parsed = []
    for rel in files:
        p = base / rel; text = strip_md(p.read_text())
        m = re.search(r"^# (.+)$", text, flags=re.M)
        parsed.append((p.name, m.group(1).strip() if m else p.stem, md_blocks(text)))
        kinds = [b[0] for b in parsed[-1][2]]
        print(f"  {p.name:28} {len(kinds):4} blocks  h {kinds.count('h')}  p {kinds.count('p')}  li {kinds.count('li')}  table {kinds.count('table')}  code {kinds.count('code')}  diagram {kinds.count('diagram')}  callout {kinds.count('callout')}")
    if a.dry_run: return 0

    tok = sh("gcloud", "auth", "print-access-token")
    with urllib.request.urlopen(f"https://oauth2.googleapis.com/tokeninfo?access_token={tok}", timeout=20) as r:
        sc = json.load(r).get("scope", "").split()
    if a.status: print("scopes   " + " ".join(s.rsplit('/', 1)[-1] for s in sc))
    if not any(s in sc for s in DRIVE_SCOPES):
        print("STOP: the gcloud token has no Drive scope. The owner runs, once, in a browser:\n  gcloud auth login --enable-gdrive-access"); return 2
    if a.status: return 0
    if a.archive:
        return archive(tok, a.archive, cfg, a.confirm)
    if not a.confirm and not a.samples: print("STOP: re-run with --confirm after the owner confirms the account and folder above."); return 2

    doc_id = cfg.get("doc_id")
    if not doc_id:
        meta = {"name": cfg["title"], "mimeType": "application/vnd.google-apps.document", "parents": [cfg["folder"]]}
        doc_id = gapi(tok, "https://www.googleapis.com/drive/v3/files?supportsAllDrives=true", "POST", meta)["id"]
        cfg["doc_id"] = doc_id; cfg_path.write_text(json.dumps(cfg, indent=2) + "\n")
        print(f"created  {doc_id}")
    doc = get_doc(tok, doc_id)
    by_title = {t["tabProperties"]["title"]: t["tabProperties"]["tabId"] for t in doc["tabs"]}

    if a.samples:
        tid = by_title.get(a.samples)
        if not tid: print(f"STOP: no tab titled {a.samples!r}; tabs are {sorted(by_title)}"); return 2
        # Replace the previous samples, from their heading to the end of the tab; the owner's own samples above stay.
        body = tab_body(get_doc(tok, doc_id), tid)
        start = next((el["startIndex"] for el in body["content"] if "paragraph" in el and SAMPLES_HEADING in
                      "".join(x.get("textRun", {}).get("content", "") for x in el["paragraph"]["elements"])), None)
        end = body["content"][-1]["endIndex"]
        if start and end - 1 > start:
            batch(tok, doc_id, [{"deleteContentRange": {"range": {"startIndex": start, "endIndex": end - 1, "tabId": tid}}}])
            print(f"  removed the previous samples ({end - 1 - start} characters)")
        samples = SAMPLES_MD.replace("DOC_URL", f"https://docs.google.com/document/d/{doc_id}/edit")
        n, t = write_tab(tok, doc_id, tid, md_blocks(samples), clear=False)
        print(f"  appended samples to {a.samples!r}: {n} requests, {t} tables")
        print(f"url      https://docs.google.com/document/d/{doc_id}/edit?tab={tid}"); return 0

    tabs = cfg.setdefault("tabs", {})
    old_ids = set(tabs.values())
    first_tab = doc["tabs"][0]["tabProperties"]["tabId"]
    plan, adds = [(parsed[0][0], first_tab, parsed[0][2])], []
    for i, (name, title, blocks) in enumerate(parsed[1:], start=1):
        tid = tabs.get(name) or by_title.get(title)
        if not tid: adds.append({"addDocumentTab": {"tabProperties": {"title": title[:50], "index": i}}})
        plan.append((name, tid, blocks))
    if adds:
        batch(tok, doc_id, adds)
        by_title = {t["tabProperties"]["title"]: t["tabProperties"]["tabId"] for t in get_doc(tok, doc_id)["tabs"]}
        plan = [(n, tid or by_title[[t for nm, t, _ in parsed if nm == n][0][:50]], b) for n, tid, b in plan]
    tabs.clear()
    for name, tid, _ in plan:
        tabs[name] = tid
    # A tab this script made earlier that no file maps to any more (a file dropped, or the README moved to the cover) goes.
    stale = [{"deleteTab": {"tabId": tid}} for tid in old_ids if tid not in tabs.values() and tid in by_title.values()]
    batch(tok, doc_id, stale + [{"updateDocumentTabProperties": {"tabProperties": {"tabId": first_tab, "title": parsed[0][1][:50]}, "fields": "title"}}])
    cfg_path.write_text(json.dumps(cfg, indent=2) + "\n")

    link_map = {name: f"https://docs.google.com/document/d/{doc_id}/edit?tab={tid}" for name, tid, _ in plan}
    for name, tid, blocks in plan:
        n, t = write_tab(tok, doc_id, tid, relink(blocks, link_map))
        print(f"  wrote   {name:28} {n:5} requests, {t} tables")
    print(f"url      https://docs.google.com/document/d/{doc_id}/edit")
    return 0


if __name__ == "__main__":
    sys.exit(main())
