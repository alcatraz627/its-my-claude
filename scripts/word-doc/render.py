#!/usr/bin/env python3
"""Turn a DOC.md into a .docx that opens cleanly in Word and Google Docs.

This is the build half of /word-doc. The agent owns the words and the structure
of DOC.md; this script owns everything a reader would otherwise have to judge by
eye: the fonts and sizes, the heading ramp, the code and diagram boxes, the table
look, the callout tints, the page and its footer. It also refuses a source that
would render badly (a diagram wider than the page, a skipped heading level, an
unknown callout) and says what to fix, so the fix happens in the markdown and
never in Word.

    python3 render.py DOC.md [-o OUT.docx] [--paper a4|letter]
                      [--font-body NAME] [--font-mono NAME] [--accent RRGGBB]
                      [--toc] [--number-sections] [--highlight STYLE]
                      [--check] [--open] [--strict]

Source shape (the whole contract, nothing else is special):

    ---                      frontmatter: title (required), subtitle, author,
    title: ...               date, toc: true, paper: a4|letter
    ---
    # Heading 1 .. #### 4    levels must not skip; H1 is a section
    ```python ... ```        a language tag means syntax highlighting
    ``` ... ```              no tag (or diagram/ascii/text) means a Diagram box,
                             lines kept verbatim; 78 columns max
    > [!NOTE] text           callout; NOTE TIP WARNING IMPORTANT CAUTION
    | a | b |  tables        6 columns max in portrait
    \\newpage                 a page break on a line of its own
    ```{.python caption="..."}  a caption under a code block or diagram
    ![alt](path)             an image; the file must exist
    Table: caption text      pandoc's table caption, a line before the table

--check renders the .docx through LibreOffice to PDF and PNG pages beside the
output (check/page-N.png) so the agent can look at them. --strict turns the
warnings into errors. Exit 0 on success, 1 on a source error, 2 on a tool error.
"""
import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import make_reference  # noqa: E402

SOFFICE = "/Applications/LibreOffice.app/Contents/MacOS/soffice"
DIAGRAM_MAX = 78
CODE_MAX = 84
TABLE_MAX_COLS = 6
CALLOUTS = {"NOTE", "TIP", "WARNING", "IMPORTANT", "CAUTION"}
DIAGRAM_CLASSES = {"", "diagram", "ascii", "text"}


class Findings:
    def __init__(self):
        self.errors, self.warnings = [], []

    def err(self, line, msg):
        self.errors.append((line, msg))

    def warn(self, line, msg):
        self.warnings.append((line, msg))


def read_meta(text):
    """The YAML we need is flat key: value. Anything fancier is pandoc's."""
    if not text.startswith("---\n"):
        return {}
    end = text.find("\n---", 4)
    if end < 0:
        return {}
    meta = {}
    for ln in text[4:end].splitlines():
        m = re.match(r'^([A-Za-z_][\w-]*):\s*(.*)$', ln)
        if m:
            v = m.group(2).strip()
            if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
                v = v[1:-1]
            meta[m.group(1)] = v
    return meta


def preflight(src_path, text, f):
    meta = read_meta(text)
    if not meta.get("title"):
        f.err(1, "frontmatter needs a title: (it becomes the cover line and the footer)")

    lines = text.splitlines()
    in_fence, fence_lang, fence_start, fence_lines = False, None, 0, []
    prev_level, heading_lines = 0, []
    table_row_cols, table_start = None, 0
    body_since_heading = True

    for i, ln in enumerate(lines, 1):
        if ln.startswith("```") or ln.startswith("~~~"):
            if not in_fence:
                in_fence, fence_start, fence_lines = True, i, []
                info = ln.strip("`~").strip()
                if " " in info and not info.startswith("{"):
                    f.err(i, 'fence options need braces: ```{.lang caption="..."}; without them pandoc reads the line as text')
                fence_lang = (info.split()[0] if info else "")
                fence_lang = fence_lang.lstrip("{").rstrip("}").lstrip(".")
                body_since_heading = True
                continue
            in_fence = False
            width = max((len(l) for l in fence_lines), default=0)
            if fence_lang in DIAGRAM_CLASSES:
                if width > DIAGRAM_MAX:
                    f.err(fence_start, f"diagram is {width} columns wide; {DIAGRAM_MAX} is the page. Wrap or split it")
                if not fence_lines:
                    f.warn(fence_start, "empty code fence")
            else:
                if width > CODE_MAX:
                    f.warn(fence_start, f"code line of {width} columns may wrap; {CODE_MAX} is safe at 9pt in every viewer. Break the line")
                if len(fence_lines) > 40:
                    f.warn(fence_start, f"{len(fence_lines)}-line code block; a reader skims past 40. Show the part that matters")
            continue
        if in_fence:
            fence_lines.append(ln)
            continue

        m = re.match(r'^(#{1,6})\s+(.*)', ln)
        if m:
            level = len(m.group(1))
            if level > 4:
                f.warn(i, f"heading level {level}; Word readers lose the thread past 4. Flatten it")
            if prev_level and level > prev_level + 1:
                f.err(i, f"heading jumps from level {prev_level} to {level}; levels must not skip")
            if heading_lines and not body_since_heading and level > heading_lines[-1][1]:
                f.warn(heading_lines[-1][0], "heading with no text before its first sub-heading; say what the section is for, or drop a level")
            heading_lines.append((i, level))
            prev_level = level
            body_since_heading = False
            continue

        if ln.strip().startswith("|"):
            cols = len([c for c in ln.strip().strip("|").split("|")])
            if table_row_cols is None:
                table_row_cols, table_start = cols, i
                if cols > TABLE_MAX_COLS:
                    f.warn(i, f"table has {cols} columns; past {TABLE_MAX_COLS} the cells wrap to one word per line. Split it or move columns into rows")
            elif cols != table_row_cols and not re.match(r'^\s*\|?\s*:?-+', ln):
                f.err(i, f"table row has {cols} cells, header has {table_row_cols} (table starts line {table_start})")
            body_since_heading = True
            continue
        table_row_cols = None

        cm = re.match(r'^>\s*\[!(\w+)\]', ln)
        if cm and cm.group(1) not in CALLOUTS:
            f.err(i, f"unknown callout [!{cm.group(1)}]; use " + " ".join(sorted(CALLOUTS)))

        for im in re.finditer(r'!\[[^\]]*\]\(([^)\s]+)', ln):
            p = im.group(1)
            if not p.startswith(("http://", "https://", "data:")):
                if not (Path(src_path).parent / p).exists() and not Path(p).exists():
                    f.err(i, f"image not found: {p}")

        if ln.strip():
            body_since_heading = True

    if in_fence:
        f.err(fence_start, "code fence never closed")
    if heading_lines and heading_lines[0][1] != 1:
        f.warn(heading_lines[0][0], "first heading is not level 1; sections start at #")
    return meta


def report(f, strict):
    for ln, msg in f.errors:
        print(f"  error  line {ln}: {msg}")
    for ln, msg in f.warnings:
        print(f"  warn   line {ln}: {msg}")
    return bool(f.errors) or (strict and bool(f.warnings))


def run_pandoc(src, out, ref, number, highlight, toc):
    cmd = ["pandoc", str(src), "-o", str(out),
           "--from", "markdown+raw_tex+pipe_tables+fenced_code_attributes+yaml_metadata_block",
           "--reference-doc", str(ref),
           "--lua-filter", str(HERE / "filters.lua"),
           "--syntax-highlighting", highlight,
           "--metadata", "lang=en-GB"]
    if number:
        cmd += ["--number-sections"]
    if toc:
        cmd += ["--metadata", "toc=true"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stderr.strip() or "pandoc failed", file=sys.stderr)
        sys.exit(2)
    if r.stderr.strip():
        print("  pandoc:", r.stderr.strip())


def render_pages(out):
    """docx -> pdf -> png pages, beside the output, for the agent to look at."""
    if not Path(SOFFICE).exists() or not shutil.which("pdftoppm"):
        print("  check: needs LibreOffice.app and pdftoppm (brew install poppler); skipped")
        return None
    cdir = out.parent / "check"
    cdir.mkdir(exist_ok=True)
    for old in cdir.glob("page-*.png"):
        old.unlink()
    # A private profile dir keeps a running LibreOffice from swallowing the call.
    with tempfile.TemporaryDirectory() as prof:
        r = subprocess.run([SOFFICE, "--headless", f"-env:UserInstallation=file://{prof}",
                            "--convert-to", "pdf", "--outdir", str(cdir), str(out)],
                           capture_output=True, text=True, timeout=180)
    pdf = cdir / (out.stem + ".pdf")
    if not pdf.exists():
        print("  check: LibreOffice produced no PDF:", (r.stderr or r.stdout).strip()[-300:])
        return None
    subprocess.run(["pdftoppm", "-r", "60", "-png", str(pdf), str(cdir / "page")], check=True)
    pages = sorted(cdir.glob("page-*.png"), key=lambda p: int(re.search(r'(\d+)\.png$', p.name).group(1)))
    return pdf, pages


def main(argv=None):
    ap = argparse.ArgumentParser(description="DOC.md -> .docx for /word-doc")
    ap.add_argument("src")
    ap.add_argument("-o", "--out")
    ap.add_argument("--paper", choices=["a4", "letter"])
    ap.add_argument("--font-body")
    ap.add_argument("--font-mono")
    ap.add_argument("--accent")
    ap.add_argument("--toc", action="store_true")
    ap.add_argument("--number-sections", action="store_true")
    ap.add_argument("--highlight", default="tango",
                    help="pandoc style: tango kate pygments zenburn breezedark monochrome (tango reads best on the tinted box)")
    ap.add_argument("--check", action="store_true", help="also render PDF + PNG pages into check/ beside the output")
    ap.add_argument("--open", action="store_true", help="open the .docx when done")
    ap.add_argument("--strict", action="store_true", help="warnings fail the build")
    a = ap.parse_args(argv)

    src = Path(a.src).resolve()
    if not src.exists():
        print(f"no such file: {src}", file=sys.stderr)
        return 2
    text = src.read_text(encoding="utf-8")
    f = Findings()
    meta = preflight(src, text, f)
    print(f"preflight {src}")
    if report(f, a.strict):
        print(f"  {len(f.errors)} error(s); fix the source, not the output")
        return 1
    if not f.warnings:
        print("  clean")

    out = Path(a.out).resolve() if a.out else src.with_suffix(".docx")
    out.parent.mkdir(parents=True, exist_ok=True)
    toc = a.toc or meta.get("toc", "").lower() in ("true", "yes", "1")
    paper = a.paper or meta.get("paper", "a4")
    with tempfile.TemporaryDirectory() as td:
        ref = Path(td) / "reference.docx"
        make_reference.build(str(ref), paper=paper, font_body=a.font_body, font_mono=a.font_mono,
                             accent=a.accent)
        run_pandoc(src, out, ref, a.number_sections, a.highlight, toc)
    size = out.stat().st_size
    print(f"wrote {out} ({size // 1024} KB, paper {paper}, toc {'on' if toc else 'off'})")

    if a.check:
        res = render_pages(out)
        if res:
            pdf, pages = res
            print(f"check {len(pages)} page(s): {pdf}")
            for p in pages:
                print(f"  {p}")
            print("  look at the pages before calling it done")
    if a.open:
        subprocess.run(["open", str(out)])
    return 0


if __name__ == "__main__":
    sys.exit(main())
