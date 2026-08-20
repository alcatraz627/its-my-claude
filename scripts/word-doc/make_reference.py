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
MARGIN = 1440  # 1 inch, in twips (1/20 pt)


def hp(pt):
    """Points to Word half-points."""
    return int(round(pt * 2))


def run_fonts(t, mono=False):
    f = t["font_mono"] if mono else t["font_body"]
    return f'<w:rFonts w:ascii="{f}" w:hAnsi="{f}" w:cs="{f}" w:eastAsia="{f}"/>'


def styles_override(t):
    """The paragraph/character/table styles the theme owns. Each entry replaces
    the style of the same id in pandoc's default, or is appended if new."""
    acc, soft, ink, muted = t["accent"], t["accent_soft"], t["ink"], t["muted"]
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
        (1, 20, 480, 120, True),
        (2, 15, 360, 80, False),
        (3, 12.5, 280, 60, False),
        (4, 11, 240, 40, False),
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
    <w:pPr><w:spacing w:before="0" w:after="60"/><w:contextualSpacing/></w:pPr>
    <w:rPr>{run_fonts(t)}<w:b/><w:color w:val="{acc}"/><w:sz w:val="{hp(28)}"/><w:szCs w:val="{hp(28)}"/></w:rPr>
  </w:style>'''
    S["Subtitle"] = f'''
  <w:style w:type="paragraph" w:styleId="Subtitle">
    <w:name w:val="Subtitle"/><w:basedOn w:val="Normal"/><w:next w:val="BodyText"/><w:link w:val="SubtitleChar"/><w:uiPriority w:val="11"/><w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="120"/></w:pPr>
    <w:rPr>{run_fonts(t)}<w:color w:val="{muted}"/><w:sz w:val="{hp(14)}"/><w:szCs w:val="{hp(14)}"/></w:rPr>
  </w:style>'''
    for sid, name in (("Author", "Author"), ("Date", "Date")):
        S[sid] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="{sid}">
    <w:name w:val="{name}"/><w:basedOn w:val="Normal"/><w:next w:val="BodyText"/><w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="40"/></w:pPr>
    <w:rPr><w:color w:val="{muted}"/><w:sz w:val="{hp(10.5)}"/><w:szCs w:val="{hp(10.5)}"/></w:rPr>
  </w:style>'''

    # Code block: mono, tinted, accent bar on the left, never split across pages
    # when it can be helped.
    code = f'''<w:pBdr><w:left w:val="single" w:sz="18" w:space="8" w:color="{acc}"/></w:pBdr>
      <w:shd w:val="clear" w:color="auto" w:fill="{t["code_bg"]}"/>
      <w:spacing w:before="120" w:after="160" w:line="240" w:lineRule="auto"/>
      <w:ind w:left="120"/><w:keepLines/>'''
    S["SourceCode"] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="SourceCode">
    <w:name w:val="Source Code"/><w:basedOn w:val="Normal"/><w:link w:val="VerbatimChar"/>
    <w:pPr>{code}</w:pPr>
    <w:rPr>{run_fonts(t, mono=True)}<w:sz w:val="{hp(t["code_pt"])}"/><w:szCs w:val="{hp(t["code_pt"])}"/></w:rPr>
  </w:style>'''

    # Diagram: an ASCII figure. Same box as code but a full hairline frame and
    # no accent bar, so the eye reads "figure", not "snippet".
    S["Diagram"] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="Diagram">
    <w:name w:val="Diagram"/><w:basedOn w:val="Normal"/>
    <w:pPr><w:pBdr><w:top w:val="single" w:sz="4" w:space="6" w:color="{t["code_border"]}"/><w:left w:val="single" w:sz="4" w:space="8" w:color="{t["code_border"]}"/><w:bottom w:val="single" w:sz="4" w:space="6" w:color="{t["code_border"]}"/><w:right w:val="single" w:sz="4" w:space="8" w:color="{t["code_border"]}"/></w:pBdr>
      <w:shd w:val="clear" w:color="auto" w:fill="{t["code_bg"]}"/>
      <w:spacing w:before="120" w:after="160" w:line="240" w:lineRule="auto"/><w:ind w:left="120" w:right="120"/><w:keepLines/></w:pPr>
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

    for name, (fill, bar) in CALLOUTS.items():
        sid = name.replace(" ", "")
        S[sid] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="{sid}">
    <w:name w:val="{name}"/><w:basedOn w:val="Normal"/><w:qFormat/>
    <w:pPr><w:pBdr><w:left w:val="single" w:sz="24" w:space="10" w:color="{bar}"/></w:pBdr><w:shd w:val="clear" w:color="auto" w:fill="{fill}"/><w:spacing w:before="120" w:after="160"/><w:ind w:left="120" w:right="120"/><w:keepLines/></w:pPr>
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
    <w:pPr><w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/></w:pPr>
    <w:rPr><w:sz w:val="8"/><w:szCs w:val="8"/></w:rPr>
  </w:style>'''

    S["Hyperlink"] = f'''
  <w:style w:type="character" w:styleId="Hyperlink">
    <w:name w:val="Hyperlink"/><w:basedOn w:val="DefaultParagraphFont"/>
    <w:rPr><w:color w:val="{acc}"/><w:u w:val="single"/></w:rPr>
  </w:style>'''

    for lvl, ind in ((1, 0), (2, 360), (3, 720)):
        bold = "<w:b/>" if lvl == 1 else ""
        S[f"TOC{lvl}"] = f'''
  <w:style w:type="paragraph" w:customStyle="1" w:styleId="TOC{lvl}">
    <w:name w:val="TOC {lvl}"/><w:basedOn w:val="Normal"/><w:qFormat/>
    <w:pPr><w:spacing w:before="{40 if lvl > 1 else 100}" w:after="20"/><w:ind w:left="{ind}"/></w:pPr>
    <w:rPr>{bold}<w:sz w:val="{hp(10.5)}"/><w:szCs w:val="{hp(10.5)}"/></w:rPr>
  </w:style>'''

    S["TOCHeading"] = f'''
  <w:style w:type="paragraph" w:styleId="TOCHeading">
    <w:name w:val="TOC Heading"/><w:basedOn w:val="Heading1"/><w:next w:val="BodyText"/><w:uiPriority w:val="39"/><w:unhideWhenUsed/><w:qFormat/>
    <w:pPr><w:outlineLvl w:val="9"/></w:pPr>
  </w:style>'''

    # Table: header row in accent with white text, horizontal hairlines only,
    # banded body rows, breathing room in every cell.
    g, band = t["grid"], t["band"]
    S["Table"] = f'''
  <w:style w:type="table" w:default="1" w:styleId="Table">
    <w:name w:val="Table"/><w:basedOn w:val="TableNormal"/><w:qFormat/>
    <w:tblPr>
      <w:tblInd w:w="0" w:type="dxa"/>
      <w:tblBorders>
        <w:top w:val="single" w:sz="6" w:space="0" w:color="{acc}"/>
        <w:bottom w:val="single" w:sz="6" w:space="0" w:color="{acc}"/>
        <w:insideH w:val="single" w:sz="4" w:space="0" w:color="{g}"/>
      </w:tblBorders>
      <w:tblCellMar><w:top w:w="70" w:type="dxa"/><w:left w:w="110" w:type="dxa"/><w:bottom w:w="70" w:type="dxa"/><w:right w:w="110" w:type="dxa"/></w:tblCellMar>
    </w:tblPr>
    <w:tblStylePr w:type="firstRow">
      <w:rPr><w:b/><w:color w:val="FFFFFF"/></w:rPr>
      <w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="{acc}"/><w:vAlign w:val="center"/></w:tcPr>
    </w:tblStylePr>
    <w:tblStylePr w:type="band2Horz">
      <w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="{band}"/></w:tcPr>
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


def sect_pr(paper, footer_rid):
    p = PAPER[paper]
    return (f'<w:sectPr><w:footerReference w:type="default" r:id="{footer_rid}"/>'
            f'<w:footnotePr><w:numRestart w:val="eachSect"/></w:footnotePr>'
            f'<w:pgSz w:w="{p["w"]}" w:h="{p["h"]}"/>'
            f'<w:pgMar w:top="{MARGIN}" w:right="{MARGIN}" w:bottom="{MARGIN}" w:left="{MARGIN}" w:header="708" w:footer="708" w:gutter="0"/>'
            f'<w:cols w:space="708"/></w:sectPr>')


def patch_styles(xml, t):
    S = styles_override(t)
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


def build(out, paper="a4", font_body=None, font_mono=None, accent=None):
    t = dict(THEME)
    if font_body: t["font_body"] = font_body
    if font_mono: t["font_mono"] = font_mono
    if accent: t["accent"] = accent.lstrip("#").upper()

    tmp = Path(out).with_suffix(".base.docx")
    subprocess.run(["pandoc", "-o", str(tmp), "--print-default-data-file", "reference.docx"], check=True)
    zin = zipfile.ZipFile(tmp)
    zout = zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED)
    footer_rid = "rId99"
    for item in zin.infolist():
        data = zin.read(item.filename)
        if item.filename == "word/styles.xml":
            data = patch_styles(data.decode("utf-8"), t).encode("utf-8")
        elif item.filename == "word/document.xml":
            d = data.decode("utf-8")
            if 'xmlns:r=' not in d.split('>', 2)[1]:
                d = d.replace('<w:document ', '<w:document xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" ', 1)
            d = re.sub(r'<w:sectPr>.*?</w:sectPr>', sect_pr(paper, footer_rid), d, flags=re.S)
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
            for name, fam, pitch, panose in ((t["font_body"], "swiss", "variable", "020F0502020204030204"),
                                             (t["font_mono"], "modern", "fixed", "020B0609020204030204")):
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
    a = ap.parse_args(argv)
    build(a.out, a.paper, a.font_body, a.font_mono, a.accent)
    print(a.out)


if __name__ == "__main__":
    sys.exit(main())
