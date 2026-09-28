#!/usr/bin/env python3
"""Build the reference.docx that gives a /word-doc document its look.

A .docx carries its typography as named styles, and pandoc copies those styles
from a "reference" document. This script produces that reference from pandoc's
own default, with the house theme written over it: the fonts, the heading ramp
and colour, the code block and diagram boxes, the table banding, the callout
tints, the page size and margins, and a footer with the title and page numbers.
Nothing here is hand-edited in Word; the theme is code, so it diffs and repeats.

    python3 make_reference.py OUT.docx [--paper a4|letter] [--font-body NAME]
                                        [--font-mono NAME] [--accent RRGGBB]

Fonts are names, not files. The viewer's machine must have them, so the defaults
are the ones Word and Google Docs both ship: Calibri for text, Consolas for code.
"""
import argparse
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

THEME = {
    "font_body": "Calibri",
    "font_mono": "Consolas",
    "accent": "1F3A5F",      # deep slate blue: headings, rules, table header
    "accent_soft": "D9E2EC",  # light accent: heading rules, borders
    "ink": "1F2933",          # body text
    "muted": "52606D",        # subtitle, captions, quotes
    "code_bg": "F5F7FA",
    "code_border": "CBD2D9",
    "band": "F5F7FA",         # table banding
    "grid": "CBD2D9",         # table rules
    "body_pt": 11,
    "code_pt": 9,
    "diagram_pt": 9,
}

CALLOUTS = {
    # name, shading, left bar
    "Callout Note":      ("E8F0FE", "1A73E8"),
    "Callout Tip":       ("E6F4EA", "1E8E3E"),
    "Callout Warning":   ("FEF7E0", "E37400"),
    "Callout Important": ("F3E8FD", "8430CE"),
}

PAPER = {
    "a4":     dict(w=11906, h=16838),
    "letter": dict(w=12240, h=15840),
}
MARGIN = 720  # half inch, in twips; halved by owner ruling 2026-09-01


def load_theme_spec(path=None):
    """The ruled theme lives in theme.json beside this script; the dicts above
    are the fallback when it is absent. Returns (theme, callouts) where callouts
    maps style name -> (fill, bar)."""
    # The shared spec (~/.claude/scripts/shared/doc-style.json) holds the callouts for
    # every document skill and a "docx" section with this renderer's fonts and palette;
    # theme.json beside this script is the older single-target file and still wins if present.
    shared = Path(__file__).parent.parent / "shared" / "doc-style.json"
    p = Path(path) if path else Path(__file__).parent / "theme.json"
    t = dict(THEME)
    c = dict(CALLOUTS)
    if not p.exists() and shared.exists():
        raw = json.loads(shared.read_text(encoding="utf-8"))
        spec = dict(raw.get("docx", {}))
        spec["callouts"] = raw.get("callouts", {})
        p = shared
    elif p.exists():
        spec = json.loads(p.read_text(encoding="utf-8"))
    if p.exists():
        f = spec.get("fonts", {})
        t["font_body"] = f.get("body", t["font_body"])
        t["font_mono"] = f.get("mono", t["font_mono"])
        pal = spec.get("palette", {})
        for k in ("accent", "accent_soft", "secondary", "tint", "ink", "muted",
                  "code_bg", "code_border", "grid", "band"):
            if k in pal:
                t[k] = pal[k]
        for kind, v in spec.get("callouts", {}).items():
            name = "Callout " + kind.capitalize()
            if "fill" in v and "bar" in v:
                c[name] = (v["fill"], v["bar"])
    t.setdefault("secondary", t["accent"])
    t.setdefault("tint", t["band"])
    return t, c


def hp(pt):
    """Points to Word half-points."""
    return int(round(pt * 2))


def run_fonts(t, mono=False):
    f = t["font_mono"] if mono else t["font_body"]
    return f'<w:rFonts w:ascii="{f}" w:hAnsi="{f}" w:cs="{f}" w:eastAsia="{f}"/>'


def styles_override(t, callouts=None):
    """The paragraph/character/table styles the theme owns. Each entry replaces
    the style of the same id in pandoc's default, or is appended if new."""
    acc, soft, ink, muted = t["accent"], t["accent_soft"], t["ink"], t["muted"]
    callouts = callouts or CALLOUTS
    S = {}

    S["Normal"] = f'''
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/><w:qFormat/>
    <w:pPr><w:spacing w:after="120" w:line="276" w:lineRule="auto"/></w:pPr>
    <w:rPr>{run_fonts(t)}<w:sz w:val="{hp(t["body_pt"])}"/><w:szCs w:val="{hp(t["body_pt"])}"/><w:lang w:val="en-GB"/></w:rPr>
  </w:style>'''

    S["BodyText"] = '''
  <w:style w:type="paragraph" w:styleId="BodyText">
    <w:name w:val="Body Text"/><w:basedOn w:val="Normal"/><w:link w:val="BodyTextChar"/><w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="140"/></w:pPr>
  </w:style>'''

    S["FirstParagraph"] = '''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="FirstParagraph">
    <w:name w:val="First Paragraph"/><w:basedOn w:val="BodyText"/><w:next w:val="BodyText"/><w:qFormat/>
  </w:style>'''

    # Compact is what pandoc uses inside table cells and tight lists.
    S["Compact"] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="Compact">
    <w:name w:val="Compact"/><w:basedOn w:val="BodyText"/><w:qFormat/>
    <w:pPr><w:spacing w:before="40" w:after="40" w:line="259" w:lineRule="auto"/></w:pPr>
    <w:rPr><w:sz w:val="{hp(10)}"/><w:szCs w:val="{hp(10)}"/></w:rPr>
  </w:style>'''

    # Heading ramp: 20 / 15 / 12.5 / 11 pt, accent colour, keep-with-next.
    # H1 carries a thin rule under it so a new top-level section reads as a section.
    ramp = [
        (1, 20, 520, 180, True),
        (2, 15, 400, 130, False),
        (3, 12.5, 300, 90, False),
        (4, 11, 260, 60, False),
    ]
    for lvl, pt, before, after, rule in ramp:
        border = (f'<w:pBdr><w:bottom w:val="single" w:sz="6" w:space="4" w:color="{soft}"/></w:pBdr>'
                  if rule else "")
        italic = "<w:i/>" if lvl == 4 else ""
        S[f"Heading{lvl}"] = f'''
  <w:style w:type="paragraph" w:styleId="Heading{lvl}">
    <w:name w:val="heading {lvl}"/><w:basedOn w:val="Normal"/><w:next w:val="BodyText"/><w:link w:val="Heading{lvl}Char"/><w:uiPriority w:val="9"/><w:qFormat/>
    <w:pPr><w:keepNext/><w:keepLines/>{border}<w:spacing w:before="{before}" w:after="{after}"/><w:outlineLvl w:val="{lvl-1}"/></w:pPr>
    <w:rPr>{run_fonts(t)}<w:b/>{italic}<w:color w:val="{acc}"/><w:sz w:val="{hp(pt)}"/><w:szCs w:val="{hp(pt)}"/></w:rPr>
  </w:style>'''

    S["Title"] = f'''
  <w:style w:type="paragraph" w:styleId="Title">
    <w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:next w:val="BodyText"/><w:link w:val="TitleChar"/><w:uiPriority w:val="10"/><w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="140"/><w:contextualSpacing/></w:pPr>
    <w:rPr>{run_fonts(t)}<w:b/><w:color w:val="{acc}"/><w:sz w:val="{hp(28)}"/><w:szCs w:val="{hp(28)}"/></w:rPr>
  </w:style>'''
    S["Subtitle"] = f'''
  <w:style w:type="paragraph" w:styleId="Subtitle">
    <w:name w:val="Subtitle"/><w:basedOn w:val="Normal"/><w:next w:val="BodyText"/><w:link w:val="SubtitleChar"/><w:uiPriority w:val="11"/><w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="220"/></w:pPr>
    <w:rPr>{run_fonts(t)}<w:color w:val="{muted}"/><w:sz w:val="{hp(14)}"/><w:szCs w:val="{hp(14)}"/></w:rPr>
  </w:style>'''
    for sid, name in (("Author", "Author"), ("Date", "Date")):
        S[sid] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="{sid}">
    <w:name w:val="{name}"/><w:basedOn w:val="Normal"/><w:next w:val="BodyText"/><w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="40"/></w:pPr>
    <w:rPr><w:color w:val="{muted}"/><w:sz w:val="{hp(10.5)}"/><w:szCs w:val="{hp(10.5)}"/></w:rPr>
  </w:style>'''

    # Code block, per the ruled theme: solid accent bar left, dashed hairline on
    # the other three sides, soft-card fill. Never split across pages when it
    # can be helped.
    cb = t["code_border"]
    code = f'''<w:pBdr><w:top w:val="dashed" w:sz="6" w:space="6" w:color="{cb}"/><w:left w:val="single" w:sz="18" w:space="8" w:color="{acc}"/><w:bottom w:val="dashed" w:sz="6" w:space="6" w:color="{cb}"/><w:right w:val="dashed" w:sz="6" w:space="8" w:color="{cb}"/></w:pBdr>
      <w:shd w:val="clear" w:color="auto" w:fill="{t["code_bg"]}"/>
      <w:spacing w:before="160" w:after="220" w:line="240" w:lineRule="auto"/>
      <w:ind w:left="120" w:right="120"/><w:keepLines/>'''
    S["SourceCode"] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="SourceCode">
    <w:name w:val="Source Code"/><w:basedOn w:val="Normal"/><w:link w:val="VerbatimChar"/>
    <w:pPr>{code}</w:pPr>
    <w:rPr>{run_fonts(t, mono=True)}<w:sz w:val="{hp(t["code_pt"])}"/><w:szCs w:val="{hp(t["code_pt"])}"/></w:rPr>
  </w:style>'''

    # Diagram: an ASCII figure. The ruled theme gives it the same dressed box as
    # code (the dir tree was the specimen the ruling was made on).
    S["Diagram"] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="Diagram">
    <w:name w:val="Diagram"/><w:basedOn w:val="Normal"/>
    <w:pPr>{code}</w:pPr>
    <w:rPr>{run_fonts(t, mono=True)}<w:color w:val="{ink}"/><w:sz w:val="{hp(t["diagram_pt"])}"/><w:szCs w:val="{hp(t["diagram_pt"])}"/></w:rPr>
  </w:style>'''

    # Inline code.
    S["VerbatimChar"] = f'''
  <w:style w:type="character" w:customStyle="1" w:styleId="VerbatimChar">
    <w:name w:val="Verbatim Char"/><w:basedOn w:val="BodyTextChar"/>
    <w:rPr>{run_fonts(t, mono=True)}<w:shd w:val="clear" w:color="auto" w:fill="EEF1F5"/><w:sz w:val="{hp(t["body_pt"] - 1.5)}"/><w:szCs w:val="{hp(t["body_pt"] - 1.5)}"/></w:rPr>
  </w:style>'''

    # Block quote.
    S["BlockText"] = f'''
  <w:style w:type="paragraph" w:styleId="BlockText">
    <w:name w:val="Block Text"/><w:basedOn w:val="BodyText"/><w:next w:val="BodyText"/><w:uiPriority w:val="9"/><w:qFormat/>
    <w:pPr><w:pBdr><w:left w:val="single" w:sz="12" w:space="10" w:color="{soft}"/></w:pBdr><w:spacing w:before="100" w:after="140"/><w:ind w:left="360" w:right="360"/></w:pPr>
    <w:rPr><w:i/><w:color w:val="{muted}"/></w:rPr>
  </w:style>'''

    # Callouts, per the ruled layout: a head paragraph (glyph + kind, in the
    # kind's colour) and the body under it. Same fill and bar on both, so Word
    # merges them into one visual block; the head keeps next.
    for name, (fill, bar) in callouts.items():
        sid = name.replace(" ", "")
        box = (f'<w:pBdr><w:left w:val="single" w:sz="24" w:space="10" w:color="{bar}"/></w:pBdr>'
               f'<w:shd w:val="clear" w:color="auto" w:fill="{fill}"/>')
        S[sid + "Head"] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="{sid}Head">
    <w:name w:val="{name} Head"/><w:basedOn w:val="Normal"/><w:next w:val="{sid}"/><w:qFormat/>
    <w:pPr><w:keepNext/><w:keepLines/>{box}<w:spacing w:before="200" w:after="20"/></w:pPr>
    <w:rPr><w:b/><w:color w:val="{bar}"/><w:spacing w:val="16"/><w:sz w:val="{hp(9.5)}"/><w:szCs w:val="{hp(9.5)}"/></w:rPr>
  </w:style>'''
        S[sid] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="{sid}">
    <w:name w:val="{name}"/><w:basedOn w:val="Normal"/><w:qFormat/>
    <w:pPr>{box}<w:spacing w:before="0" w:after="220"/><w:keepLines/></w:pPr>
    <w:rPr><w:sz w:val="{hp(t["body_pt"] - 0.5)}"/><w:szCs w:val="{hp(t["body_pt"] - 0.5)}"/></w:rPr>
  </w:style>'''

    for sid, name in (("Caption", "Caption"), ("TableCaption", "Table Caption"), ("ImageCaption", "Image Caption")):
        based = "Caption" if sid != "Caption" else "Normal"
        S[sid] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="{sid}">
    <w:name w:val="{name}"/><w:basedOn w:val="{based}"/><w:qFormat/>
    <w:pPr><w:spacing w:before="60" w:after="200"/><w:jc w:val="center"/></w:pPr>
    <w:rPr><w:i/><w:color w:val="{muted}"/><w:sz w:val="{hp(9.5)}"/><w:szCs w:val="{hp(9.5)}"/></w:rPr>
  </w:style>'''

    S["TableSpacer"] = '''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="TableSpacer">
    <w:name w:val="Table Spacer"/><w:basedOn w:val="Normal"/>
    <w:pPr><w:spacing w:before="0" w:after="200" w:line="240" w:lineRule="auto"/></w:pPr>
    <w:rPr><w:sz w:val="8"/><w:szCs w:val="8"/></w:rPr>
  </w:style>'''

    S["Hyperlink"] = f'''
  <w:style w:type="character" w:styleId="Hyperlink">
    <w:name w:val="Hyperlink"/><w:basedOn w:val="DefaultParagraphFont"/>
    <w:rPr><w:color w:val="{acc}"/></w:rPr>
  </w:style>'''

    # Contents, per the ruled indent-rail: an accent rail down the left of every
    # entry, level 1 semibold, deeper levels indented and muted.
    rail = f'<w:pBdr><w:left w:val="single" w:sz="18" w:space="14" w:color="{acc}"/></w:pBdr>'
    for lvl, ind in ((1, 300), (2, 660), (3, 1020)):
        bold = "<w:b/>" if lvl == 1 else ""
        color = "" if lvl == 1 else f'<w:color w:val="{muted}"/>'
        S[f"TOC{lvl}"] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="TOC{lvl}">
    <w:name w:val="TOC {lvl}"/><w:basedOn w:val="Normal"/><w:qFormat/>
    <w:pPr>{rail}<w:spacing w:before="{40 if lvl > 1 else 100}" w:after="60"/><w:ind w:left="{ind}"/></w:pPr>
    <w:rPr>{bold}{color}<w:sz w:val="{hp(10.5)}"/><w:szCs w:val="{hp(10.5)}"/></w:rPr>
  </w:style>'''

    S["TOCHeading"] = f'''
  <w:style w:type="paragraph" w:styleId="TOCHeading">
    <w:name w:val="TOC Heading"/><w:basedOn w:val="Heading1"/><w:next w:val="BodyText"/><w:uiPriority w:val="39"/><w:unhideWhenUsed/><w:qFormat/>
    <w:pPr><w:outlineLvl w:val="9"/></w:pPr>
  </w:style>'''

    # Table, per the ruled dotted-separator treatment: no header fill, accent
    # header text over a dashed accent rule, dashed light separators between
    # rows, no banding, breathing room in every cell.
    g = t["grid"]
    S["Table"] = f'''
  <w:style w:type="table" w:default="1" w:styleId="Table">
    <w:name w:val="Table"/><w:basedOn w:val="TableNormal"/><w:qFormat/>
    <w:tblPr>
      <w:tblInd w:w="0" w:type="dxa"/>
      <w:tblBorders>
        <w:insideH w:val="dashed" w:sz="4" w:space="0" w:color="{g}"/>
      </w:tblBorders>
      <w:tblCellMar><w:top w:w="80" w:type="dxa"/><w:left w:w="110" w:type="dxa"/><w:bottom w:w="80" w:type="dxa"/><w:right w:w="110" w:type="dxa"/></w:tblCellMar>
    </w:tblPr>
    <w:tblStylePr w:type="firstRow">
      <w:rPr><w:b/><w:color w:val="{acc}"/></w:rPr>
      <w:tcPr><w:tcBorders><w:bottom w:val="dashed" w:sz="8" w:space="0" w:color="{acc}"/></w:tcBorders><w:vAlign w:val="center"/></w:tcPr>
    </w:tblStylePr>
  </w:style>'''
    return S


def gdoc_theme():
    """The Google Docs look from the shared spec, as the flat theme dict the Harbor styles also read."""
    sys.path.insert(0, str(Path(__file__).parent.parent / "shared"))
    import doc_style
    L = doc_style.load_look("gdoc")
    L["title_align"] = doc_style.load_raw().get("docx", {}).get("title_align")
    t = dict(THEME)
    t["font_heading"] = L["fonts"]["heading"]
    t.update(font_body=L["fonts"]["body"], font_mono=L["fonts"]["mono"], accent=L["palette"]["accent"],
             accent_soft=L["table"]["border"], ink=L["palette"]["ink"], muted=L["palette"]["muted"],
             code_bg=L["palette"]["code_bg"], code_border=L["palette"]["code_bg"], grid=L["table"]["border"],
             band=L["table"]["first_col_fill"], body_pt=L["sizes"]["body"], code_pt=L["sizes"]["code"],
             diagram_pt=L["sizes"]["code"], secondary=L["palette"]["accent"], tint=L["table"]["first_col_fill"])
    callouts = {"Callout " + k.capitalize(): (v["fill"], v["bar"]) for k, v in L["callouts"].items()}
    return t, callouts, L


def mono_face(family, weight):
    """Word picks a weight by family name, so a static cut is named: 'JetBrains Mono ExtraLight'."""
    names = {100: "Thin", 200: "ExtraLight", 300: "Light", 500: "Medium", 600: "SemiBold", 700: "Bold", 800: "ExtraBold"}
    return f"{family} {names[weight]}" if weight in names else family


def fonts(name):
    return f'<w:rFonts w:ascii="{name}" w:hAnsi="{name}" w:cs="{name}" w:eastAsia="{name}"/>'


def sz(pt):
    return f'<w:sz w:val="{hp(pt)}"/><w:szCs w:val="{hp(pt)}"/>'


def tw(pt):
    """Points to twips."""
    return int(round(pt * 20))


def gdoc_styles(t, callouts, L):
    """The Google Docs look in Word: the Harbor style set first, then every style the look owns replaced."""
    S = styles_override(t, callouts)
    F, Z, T, C, K, Q, Li = L["fonts"], L["sizes"], L["table"], L["code"], L["callout"], L["quote"], L["lists"]
    ink, muted, bg = L["palette"]["ink"], L["palette"]["muted"], L["palette"]["code_bg"]

    def para(sid, name, ppr, rpr, based="Normal", extra=""):
        S[sid] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="{sid}">
    <w:name w:val="{name}"/><w:basedOn w:val="{based}"/>{extra}<w:qFormat/>
    <w:pPr>{ppr}</w:pPr><w:rPr>{rpr}</w:rPr>
  </w:style>'''

    def char(sid, name, rpr):
        S[sid] = f'''
  <w:style w:type="character" w:customStyle="1" w:styleId="{sid}">
    <w:name w:val="{name}"/><w:basedOn w:val="DefaultParagraphFont"/>
    <w:rPr>{rpr}</w:rPr>
  </w:style>'''

    def box(fill, pad, left=None):
        l = (f'<w:left w:val="single" w:sz="{int(left[1] * 8)}" w:space="{pad}" w:color="{left[0]}"/>' if left
             else f'<w:left w:val="single" w:sz="4" w:space="{pad}" w:color="{fill}"/>')
        return (f'<w:pBdr><w:top w:val="single" w:sz="4" w:space="{pad}" w:color="{fill}"/>{l}'
                f'<w:bottom w:val="single" w:sz="4" w:space="{pad}" w:color="{fill}"/>'
                f'<w:right w:val="single" w:sz="4" w:space="{pad}" w:color="{fill}"/></w:pBdr>')

    S["Normal"] = f'''
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/><w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/></w:pPr>
    <w:rPr>{fonts(F["body"])}{sz(Z["body"])}<w:lang w:val="en-GB"/></w:rPr>
  </w:style>'''
    S["BodyText"] = '''
  <w:style w:type="paragraph" w:styleId="BodyText">
    <w:name w:val="Body Text"/><w:basedOn w:val="Normal"/><w:link w:val="BodyTextChar"/><w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="0"/></w:pPr>
  </w:style>'''
    # Tight list items; table cells are moved to TableText by render.py, so this is lists only.
    S["Compact"] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="Compact">
    <w:name w:val="Compact"/><w:basedOn w:val="BodyText"/><w:qFormat/>
    <w:pPr><w:spacing w:before="{tw(Li["space_above"])}" w:after="{tw(Li["space_below"])}" w:line="{int(240 * Li["line_spacing"] / 100)}" w:lineRule="auto"/></w:pPr>
  </w:style>'''
    para("TableText", "Table Text", '<w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/>', sz(T["font_pt"]))

    names = {"title": ("Title", "Title"), "subtitle": ("Subtitle", "Subtitle")}
    jc = f'<w:jc w:val="{L.get("title_align", "left")}"/>' if L.get("title_align") else ""
    for key, (sid, name) in names.items():
        before, after = L["spacing"][key]
        color = f'<w:color w:val="{muted}"/>' if key == "subtitle" else ""
        S[sid] = f'''
  <w:style w:type="paragraph" w:styleId="{sid}">
    <w:name w:val="{name}"/><w:basedOn w:val="Normal"/><w:next w:val="BodyText"/><w:qFormat/>
    <w:pPr><w:spacing w:before="{tw(before)}" w:after="{tw(after)}"/>{jc}</w:pPr>
    <w:rPr>{fonts(F["title"])}{color}{sz(Z[key])}</w:rPr>
  </w:style>'''
    for lvl in range(1, 7):
        key = f"h{lvl}"
        before, after = L["spacing"][key]
        color = L["heading_colors"].get(key, ink)
        font = F["heading"] if lvl < 6 else F["body"]
        italic = "<w:i/>" if lvl == 6 else ""
        S[f"Heading{lvl}"] = f'''
  <w:style w:type="paragraph" w:styleId="Heading{lvl}">
    <w:name w:val="heading {lvl}"/><w:basedOn w:val="Normal"/><w:next w:val="BodyText"/><w:link w:val="Heading{lvl}Char"/><w:uiPriority w:val="9"/><w:qFormat/>
    <w:pPr><w:keepNext/><w:keepLines/><w:spacing w:before="{tw(before)}" w:after="{tw(after)}"/><w:outlineLvl w:val="{lvl - 1}"/></w:pPr>
    <w:rPr>{fonts(font)}{italic}<w:color w:val="{color}"/>{sz(Z[key])}</w:rPr>
  </w:style>'''

    pad = C["pad_pt"]
    rest = (f'<w:shd w:val="clear" w:color="auto" w:fill="{bg}"/>'
            f'<w:spacing w:before="{tw(C["space_pt"] + pad)}" w:after="{tw(C["space_pt"] + pad)}" w:line="240" w:lineRule="auto"/>'
            f'<w:ind w:left="{tw(pad)}" w:right="{tw(pad)}"/><w:keepLines/>')
    code_ppr = box(bg, pad, left=(C["bar"], C["bar_pt"])) + rest
    diagram_ppr = box(bg, pad) + rest
    S["SourceCode"] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="SourceCode">
    <w:name w:val="Source Code"/><w:basedOn w:val="Normal"/><w:link w:val="VerbatimChar"/>
    <w:pPr>{code_ppr}</w:pPr>
    <w:rPr>{fonts(mono_face(F["mono"], C["weight"]))}{sz(Z["code"])}</w:rPr>
  </w:style>'''
    para("Diagram", "Diagram", diagram_ppr, f'{fonts(mono_face(F["mono"], C["diagram_weight"]))}<w:color w:val="{ink}"/>{sz(Z["code"])}')
    char("DiagramStroke", "Diagram Stroke", f'{fonts(mono_face(F["mono"], C["stroke_weight"]))}<w:color w:val="{C["stroke"]}"/>')

    code_pt = Z["body"] + L["inline_code"]["size_delta"]
    S["VerbatimChar"] = f'''
  <w:style w:type="character" w:customStyle="1" w:styleId="VerbatimChar">
    <w:name w:val="Verbatim Char"/><w:basedOn w:val="BodyTextChar"/>
    <w:rPr>{fonts(F["mono"])}<w:shd w:val="clear" w:color="auto" w:fill="{bg}"/>{sz(code_pt)}</w:rPr>
  </w:style>'''
    char("VerbatimPad", "Verbatim Pad", f'<w:shd w:val="clear" w:color="auto" w:fill="{bg}"/>')

    S["Hyperlink"] = f'''
  <w:style w:type="character" w:styleId="Hyperlink">
    <w:name w:val="Hyperlink"/><w:basedOn w:val="DefaultParagraphFont"/>
    <w:rPr><w:color w:val="{L["palette"]["link"]}"/><w:u w:val="single"/></w:rPr>
  </w:style>'''

    # Quote: keyline in the accent over the lightest tint; edges in the tint carry the padding.
    S["BlockText"] = f'''
  <w:style w:type="paragraph" w:styleId="BlockText">
    <w:name w:val="Block Text"/><w:basedOn w:val="BodyText"/><w:next w:val="BodyText"/><w:uiPriority w:val="9"/><w:qFormat/>
    <w:pPr>{box(Q["fill"], Q["pad_pt"], left=(Q["bar"], Q["bar_pt"]))}<w:shd w:val="clear" w:color="auto" w:fill="{Q["fill"]}"/>
      <w:spacing w:before="{tw(Q["space_pt"] + Q["pad_pt"])}" w:after="{tw(Q["space_pt"] + Q["pad_pt"])}" w:line="276" w:lineRule="auto"/><w:ind w:left="{tw(Q["indent_pt"])}" w:right="{tw(Q["pad_pt"])}"/></w:pPr>
    <w:rPr>{fonts(Q["font"])}{"<w:i/>" if Q["italic"] else ""}<w:color w:val="{Q["color"]}"/>{sz(Q["pt"])}</w:rPr>
  </w:style>'''
    char("QuoteMark", "Quote Mark", f'{fonts(Q.get("mark_font") or Q["font"])}<w:i w:val="0"/><w:color w:val="{Q["mark_color"]}"/>{sz(Q["mark_pt"])}')

    # Callouts: one paragraph, the key line then the text under it, both at the same indent.
    for name, (fill, bar) in callouts.items():
        sid = name.replace(" ", "")
        kind = name.split(" ", 1)[1]
        S[sid] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="{sid}">
    <w:name w:val="{name}"/><w:basedOn w:val="Normal"/><w:qFormat/>
    <w:pPr>{box(fill, K["pad_pt"], left=(bar, K["bar_pt"]))}<w:shd w:val="clear" w:color="auto" w:fill="{fill}"/>
      <w:spacing w:before="{tw(K["space_pt"] + K["pad_pt"])}" w:after="{tw(K["space_pt"] + K["pad_pt"])}" w:line="276" w:lineRule="auto"/>
      <w:ind w:left="{tw(K["indent_pt"])}" w:right="{tw(K["pad_pt"])}"/><w:keepLines/></w:pPr>
    <w:rPr>{fonts(mono_face(K["body_font"], K["body_weight"]))}<w:color w:val="{K["body_color"]}"/>{sz(K["body_pt"])}</w:rPr>
  </w:style>'''
        # Base family plus bold: a named ExtraBold cut is not found by every viewer.
        bold = "<w:b/>" if K["label_weight"] >= 600 else ""
        char(f"CalloutKey{kind}", f"Callout Key {kind}",
             f'{fonts(K["label_font"])}{bold}<w:color w:val="{bar}"/>{sz(K["label_pt"])}')
        gpt = L["callouts"].get(kind.upper(), {}).get("glyph_pt") or K["label_pt"]
        char(f"CalloutGlyph{kind}", f"Callout Glyph {kind}",
             f'{fonts(K["label_font"])}{bold}<w:color w:val="{bar}"/>{sz(gpt)}')

    R = L["rule"]
    para("Rule", "Rule", f'<w:pBdr><w:bottom w:val="single" w:sz="{int(R["pt"] * 8)}" w:space="1" w:color="{R["color"]}"/></w:pBdr>'
                         f'<w:spacing w:before="{tw(R["space_pt"])}" w:after="{tw(R["space_pt"])}" w:line="240" w:lineRule="auto"/>', sz(2))
    para("BoxSpacer", "Box Spacer", '<w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/>', sz(2))

    # Table: filled header with a dashed border in its own colour, dashed body grid two tones lighter,
    # body text in the darkest tone, first column in the lightest.
    hb = f'w:val="dashed" w:sz="{int(T["border_pt"] * 8)}" w:space="0" w:color="{T["header_border"]}"'
    gb = f'w:val="dashed" w:sz="{int(T["border_pt"] * 8)}" w:space="0" w:color="{T["border"]}"'
    first_col = (f'<w:tblStylePr w:type="firstCol"><w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="{T["first_col_fill"]}"/></w:tcPr></w:tblStylePr>'
                 if T["first_col"] else "")
    p = tw(T["padding_pt"])
    S["Table"] = f'''
  <w:style w:type="table" w:default="1" w:styleId="Table">
    <w:name w:val="Table"/><w:basedOn w:val="TableNormal"/><w:qFormat/>
    <w:rPr><w:color w:val="{T["text"]}"/>{sz(T["font_pt"])}</w:rPr>
    <w:tblPr>
      <w:tblInd w:w="0" w:type="dxa"/>
      <w:tblBorders><w:top {gb}/><w:left {gb}/><w:bottom {gb}/><w:right {gb}/><w:insideH {gb}/><w:insideV {gb}/></w:tblBorders>
      <w:tblCellMar><w:top w:w="{p}" w:type="dxa"/><w:left w:w="{p}" w:type="dxa"/><w:bottom w:w="{p}" w:type="dxa"/><w:right w:w="{p}" w:type="dxa"/></w:tblCellMar>
    </w:tblPr>
    <w:tblStylePr w:type="firstRow">
      <w:rPr>{fonts(T["header_font"])}<w:b w:val="0"/><w:color w:val="{T["header_text"]}"/></w:rPr>
      <w:tcPr><w:tcBorders><w:top {hb}/><w:left {hb}/><w:bottom {hb}/><w:right {hb}/><w:insideV {hb}/></w:tcBorders>
        <w:shd w:val="clear" w:color="auto" w:fill="{T["header_fill"]}"/></w:tcPr>
    </w:tblStylePr>
    {first_col}
  </w:style>'''
    TL = L["table_light"]
    rule = f'w:val="dashed" w:sz="{int(TL["rule_pt"] * 8)}" w:space="0" w:color="{TL["rule"]}"'
    sep = f'w:val="dashed" w:sz="{int(TL["separator_pt"] * 8)}" w:space="0" w:color="{TL["separator"]}"'
    S["TableLight"] = f'''
  <w:style w:type="table" w:customStyle="1" w:styleId="TableLight">
    <w:name w:val="Table Light"/><w:basedOn w:val="TableNormal"/><w:qFormat/>
    <w:rPr><w:color w:val="{T["text"]}"/>{sz(T["font_pt"])}</w:rPr>
    <w:tblPr>
      <w:tblInd w:w="0" w:type="dxa"/>
      <w:tblBorders><w:bottom {sep}/><w:insideH {sep}/></w:tblBorders>
      <w:tblCellMar><w:top w:w="{p}" w:type="dxa"/><w:left w:w="{p}" w:type="dxa"/><w:bottom w:w="{p}" w:type="dxa"/><w:right w:w="{p}" w:type="dxa"/></w:tblCellMar>
    </w:tblPr>
    <w:tblStylePr w:type="firstRow">
      <w:rPr>{fonts(T["header_font"])}<w:b w:val="0"/><w:color w:val="{TL["header_text"]}"/></w:rPr>
      <w:tcPr><w:tcBorders><w:bottom {rule}/></w:tcBorders></w:tcPr>
    </w:tblStylePr>
  </w:style>'''
    return S


def footer_xml():
    """Footer: document title on the left, "Page N of M" on the right."""
    return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
            '<w:p><w:pPr><w:pStyle w:val="Footer"/><w:tabs><w:tab w:val="right" w:pos="9026"/></w:tabs></w:pPr>'
            '<w:r><w:fldChar w:fldCharType="begin"/></w:r><w:r><w:instrText xml:space="preserve"> TITLE </w:instrText></w:r>'
            '<w:r><w:fldChar w:fldCharType="separate"/></w:r><w:r><w:t></w:t></w:r><w:r><w:fldChar w:fldCharType="end"/></w:r>'
            '<w:r><w:tab/><w:t xml:space="preserve">Page </w:t></w:r>'
            '<w:r><w:fldChar w:fldCharType="begin"/></w:r><w:r><w:instrText xml:space="preserve"> PAGE </w:instrText></w:r>'
            '<w:r><w:fldChar w:fldCharType="separate"/></w:r><w:r><w:t>1</w:t></w:r><w:r><w:fldChar w:fldCharType="end"/></w:r>'
            '<w:r><w:t xml:space="preserve"> of </w:t></w:r>'
            '<w:r><w:fldChar w:fldCharType="begin"/></w:r><w:r><w:instrText xml:space="preserve"> NUMPAGES </w:instrText></w:r>'
            '<w:r><w:fldChar w:fldCharType="separate"/></w:r><w:r><w:t>1</w:t></w:r><w:r><w:fldChar w:fldCharType="end"/></w:r>'
            '</w:p></w:ftr>')


def footer_style(t):
    return f'''
  <w:style w:type="paragraph" w:styleId="Footer">
    <w:name w:val="footer"/><w:basedOn w:val="Normal"/>
    <w:pPr><w:pBdr><w:top w:val="single" w:sz="4" w:space="6" w:color="{t["accent_soft"]}"/></w:pBdr><w:spacing w:after="0"/></w:pPr>
    <w:rPr><w:color w:val="{t["muted"]}"/><w:sz w:val="{hp(9)}"/><w:szCs w:val="{hp(9)}"/></w:rPr>
  </w:style>'''


def sect_pr(paper, footer_rid, margin=MARGIN):
    p = PAPER[paper]
    return (f'<w:sectPr><w:footerReference w:type="default" r:id="{footer_rid}"/>'
            f'<w:footnotePr><w:numRestart w:val="eachSect"/></w:footnotePr>'
            f'<w:pgSz w:w="{p["w"]}" w:h="{p["h"]}"/>'
            f'<w:pgMar w:top="{margin}" w:right="{margin}" w:bottom="{margin}" w:left="{margin}" w:header="360" w:footer="360" w:gutter="0"/>'
            f'<w:cols w:space="708"/></w:sectPr>')


def default_look():
    shared = Path(__file__).parent.parent / "shared" / "doc-style.json"
    if shared.exists():
        return json.loads(shared.read_text(encoding="utf-8")).get("docx", {}).get("look", "harbor")
    return "harbor"


def patch_styles(xml, t, callouts=None, S=None):
    S = S or styles_override(t, callouts)
    S["Footer"] = footer_style(t)
    # docDefaults: the body font and ink colour everywhere a style does not say
    # otherwise. The colour lives HERE and not in Normal on purpose: Word applies a
    # paragraph style above a table style, so an ink colour on Normal would beat the
    # white header text the Table style asks for.
    xml = re.sub(r'<w:rPrDefault>.*?</w:rPrDefault>',
                 f'<w:rPrDefault><w:rPr>{run_fonts(t)}<w:color w:val="{t["ink"]}"/><w:sz w:val="{hp(t["body_pt"])}"/><w:szCs w:val="{hp(t["body_pt"])}"/><w:lang w:val="en-GB"/></w:rPr></w:rPrDefault>',
                 xml, flags=re.S)
    for sid, block in S.items():
        pat = re.compile(r'\n?\s*<w:style [^>]*w:styleId="%s".*?</w:style>' % re.escape(sid), re.S)
        if pat.search(xml):
            xml = pat.sub(lambda m: block, xml, count=1)
        else:
            xml = xml.replace("</w:styles>", block + "\n</w:styles>")
    return xml


def build(out, paper="a4", font_body=None, font_mono=None, accent=None, theme=None, look=None):
    look = look or default_look()
    S, margin = None, MARGIN
    if look == "gdoc":
        t, callouts, L = gdoc_theme()
        margin = tw(L["page"]["margins_pt"])
    else:
        t, callouts = load_theme_spec(theme)
    if font_body: t["font_body"] = font_body
    if font_mono: t["font_mono"] = font_mono
    if accent: t["accent"] = accent.lstrip("#").upper()
    if look == "gdoc":
        S = gdoc_styles(t, callouts, L)

    tmp = Path(out).with_suffix(".base.docx")
    subprocess.run(["pandoc", "-o", str(tmp), "--print-default-data-file", "reference.docx"], check=True)
    zin = zipfile.ZipFile(tmp)
    zout = zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED)
    footer_rid = "rId99"
    for item in zin.infolist():
        data = zin.read(item.filename)
        if item.filename == "word/styles.xml":
            data = patch_styles(data.decode("utf-8"), t, callouts, S).encode("utf-8")
        elif item.filename == "word/document.xml":
            d = data.decode("utf-8")
            if 'xmlns:r=' not in d.split('>', 2)[1]:
                d = d.replace('<w:document ', '<w:document xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" ', 1)
            d = re.sub(r'<w:sectPr>.*?</w:sectPr>', sect_pr(paper, footer_rid, margin), d, flags=re.S)
            data = d.encode("utf-8")
        elif item.filename == "word/_rels/document.xml.rels":
            d = data.decode("utf-8").replace(
                "</Relationships>",
                f'<Relationship Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Id="{footer_rid}" Target="footer1.xml"/></Relationships>')
            data = d.encode("utf-8")
        elif item.filename == "[Content_Types].xml":
            d = data.decode("utf-8").replace(
                "</Types>",
                '<Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/></Types>')
            data = d.encode("utf-8")
        elif item.filename == "word/fontTable.xml":
            # Declare both fonts with their family and pitch, so a machine that lacks
            # them substitutes a font of the same shape (a mono for the mono) instead of
            # whatever the viewer's default is.
            d = data.decode("utf-8")
            # Word has no fallback list; a missing font is swapped for the installed one closest to this
            # declared shape. Body: Calibri's shape. Mono: Consolas's. Headings: Century Gothic's (geometric).
            decl = [(t["font_body"], "swiss", "variable", "020F0502020204030204"),
                    (t["font_mono"], "modern", "fixed", "020B0609020204030204")]
            if t.get("font_heading"):
                decl.append((t["font_heading"], "swiss", "variable", "020B0502020202020204"))
            for name, fam, pitch, panose in decl:
                if f'w:name="{name}"' not in d:
                    d = d.replace("</w:fonts>",
                                  f'<w:font w:name="{name}"><w:panose1 w:val="{panose}"/><w:charset w:val="00"/>'
                                  f'<w:family w:val="{fam}"/><w:pitch w:val="{pitch}"/></w:font></w:fonts>')
            data = d.encode("utf-8")
        zout.writestr(item, data)
    zout.writestr("word/footer1.xml", footer_xml())
    zout.close()
    zin.close()
    tmp.unlink()
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("out")
    ap.add_argument("--paper", choices=sorted(PAPER), default="a4")
    ap.add_argument("--font-body")
    ap.add_argument("--font-mono")
    ap.add_argument("--accent")
    ap.add_argument("--look", choices=["harbor", "gdoc"], help="default: the spec's docx.look")
    a = ap.parse_args(argv)
    build(a.out, a.paper, a.font_body, a.font_mono, a.accent, look=a.look)
    print(a.out)


if __name__ == "__main__":
    sys.exit(main())
