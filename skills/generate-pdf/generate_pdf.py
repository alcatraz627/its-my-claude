#!/usr/bin/env python3
"""
generate_pdf.py — Convert a markdown file to a compact, styled PDF.

Usage:
    python3 generate_pdf.py <input.md>
    python3 generate_pdf.py <input.md> --open
    python3 generate_pdf.py <input.md> --style professional
    python3 generate_pdf.py <input.md> --style academic --toc --cover
    python3 generate_pdf.py <input.md> --landscape

Output: Same directory as input, same filename, .pdf extension.

Styles: default, professional, academic, compact
Flags: --open, --style <name>, --toc, --cover, --landscape

Requires: npx with md-to-pdf (auto-downloaded on first run via npx --yes)
"""

import sys
import os
import subprocess
import json
import tempfile
import re
from datetime import datetime

# ─── CSS Design ───────────────────────────────────────────────────────────────
# Dark code blocks, blue accent headings, compact margins, clean tables.
CSS = """
@page {
  size: A4;
  margin: 14mm 16mm 16mm 16mm;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
  font-size: 10.5pt;
  line-height: 1.58;
  color: #1e293b;
  max-width: none;
}

/* ── Headings ── */
h1 {
  font-size: 20pt;
  font-weight: 700;
  color: #0f172a;
  border-bottom: 2.5px solid #3b82f6;
  padding-bottom: 7px;
  margin: 4px 0 18px 0;
}

h2 {
  font-size: 13.5pt;
  font-weight: 600;
  color: #1e293b;
  border-left: 4px solid #3b82f6;
  padding-left: 10px;
  margin: 22px 0 10px 0;
  page-break-after: avoid;
}

h3 {
  font-size: 11pt;
  font-weight: 600;
  color: #334155;
  margin: 14px 0 5px 0;
  page-break-after: avoid;
}

h4 {
  font-size: 10pt;
  font-weight: 600;
  color: #475569;
  margin: 10px 0 4px 0;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

/* ── Body text ── */
p { margin: 0 0 8px 0; }

strong { font-weight: 600; color: #0f172a; }

em { color: #334155; }

a { color: #2563eb; text-decoration: none; }

/* ── Inline code ── */
code:not(pre code) {
  font-family: 'SF Mono', 'Fira Code', 'JetBrains Mono', 'Menlo', Consolas, monospace;
  font-size: 8.5pt;
  background: #f1f5f9;
  color: #0f172a;
  border: 1px solid #e2e8f0;
  border-radius: 3px;
  padding: 1px 5px;
}

/* ── Code blocks ── */
pre {
  background: #0f172a !important;
  border-radius: 6px;
  padding: 11px 14px;
  margin: 6px 0 12px 0;
  border-left: 3px solid #3b82f6;
  page-break-inside: avoid;
}

pre code,
pre code.hljs {
  font-family: 'SF Mono', 'Fira Code', 'JetBrains Mono', 'Menlo', Consolas, monospace;
  font-size: 8pt;
  line-height: 1.55;
  background: transparent !important;
  padding: 0 !important;
  border: none !important;
  border-radius: 0 !important;
  color: #e2e8f0;
}

/* Syntax token overrides (atom-one-dark base + adjustments) */
.hljs                { background: #0f172a !important; color: #e2e8f0 !important; }
.hljs-keyword,
.hljs-selector-tag   { color: #93c5fd !important; font-weight: 600; }
.hljs-string,
.hljs-attr-value     { color: #86efac !important; }
.hljs-comment,
.hljs-quote          { color: #64748b !important; font-style: italic; }
.hljs-number,
.hljs-literal        { color: #fbbf24 !important; }
.hljs-function,
.hljs-title          { color: #60a5fa !important; }
.hljs-type,
.hljs-class          { color: #f9a8d4 !important; }
.hljs-built_in       { color: #67e8f9 !important; }
.hljs-variable       { color: #fcd34d !important; }
.hljs-params         { color: #fdba74 !important; }
.hljs-attr           { color: #a5f3fc !important; }
.hljs-symbol,
.hljs-bullet         { color: #34d399 !important; }
.hljs-tag            { color: #f472b6 !important; }
.hljs-name           { color: #93c5fd !important; }
.hljs-meta           { color: #94a3b8 !important; }
.hljs-deletion       { color: #fca5a5 !important; background: rgba(239,68,68,0.15) !important; }
.hljs-addition       { color: #86efac !important; background: rgba(34,197,94,0.15) !important; }

/* ── Tables ── */
table {
  width: 100%;
  border-collapse: collapse;
  font-size: 9.5pt;
  margin: 6px 0 12px 0;
  page-break-inside: avoid;
}

thead tr {
  background: #1e293b;
  color: #f8fafc;
}

th {
  padding: 7px 10px;
  text-align: left;
  font-weight: 600;
  font-size: 8.5pt;
  letter-spacing: 0.03em;
  text-transform: uppercase;
}

td {
  padding: 6px 10px;
  border-bottom: 1px solid #e2e8f0;
  vertical-align: top;
}

tbody tr:nth-child(even) { background: #f8fafc; }

/* ── Blockquotes ── */
blockquote {
  margin: 8px 0;
  padding: 8px 12px;
  border-left: 3px solid #94a3b8;
  background: #f8fafc;
  color: #475569;
  font-size: 9.5pt;
  font-style: italic;
  border-radius: 0 4px 4px 0;
}
blockquote p { margin: 0; }

/* ── Lists ── */
ul, ol {
  padding-left: 18px;
  margin: 3px 0 8px 0;
}
li { margin-bottom: 3px; }
li > ul, li > ol { margin-top: 2px; margin-bottom: 2px; }

/* Nested list tighter */
ul ul, ol ol, ul ol, ol ul { margin-bottom: 0; }

/* ── Horizontal rule ── */
hr {
  border: none;
  border-top: 1px solid #e2e8f0;
  margin: 12px 0;
}

/* ── Page break rules ── */
h1, h2, h3 { page-break-after: avoid; }
pre, table, blockquote { page-break-inside: avoid; }
"""

# ─── Style registry ───────────────────────────────────────────────────────────
STYLES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "styles")
AVAILABLE_STYLES = ["default", "professional", "academic", "compact"]

# ─── PDF render options ────────────────────────────────────────────────────────
PDF_OPTIONS = {
    "format": "A4",
    "printBackground": True,
    "margin": {
        "top": "14mm",
        "right": "16mm",
        "bottom": "14mm",
        "left": "16mm"
    }
}

# Margin overrides per style
STYLE_MARGINS = {
    "professional": {"top": "20mm", "right": "22mm", "bottom": "22mm", "left": "22mm"},
    "academic": {"top": "25mm", "right": "25mm", "bottom": "30mm", "left": "25mm"},
    "compact": {"top": "10mm", "right": "12mm", "bottom": "12mm", "left": "12mm"},
}


def _parse_args():
    """Parse CLI arguments."""
    args = {"input": None, "open": False, "style": "default",
            "toc": False, "cover": False, "landscape": False}

    i = 1
    while i < len(sys.argv):
        arg = sys.argv[i]
        if arg == "--open":
            args["open"] = True
        elif arg == "--style" and i + 1 < len(sys.argv):
            i += 1
            args["style"] = sys.argv[i]
        elif arg == "--toc":
            args["toc"] = True
        elif arg == "--cover":
            args["cover"] = True
        elif arg == "--landscape":
            args["landscape"] = True
        elif not arg.startswith("--") and args["input"] is None:
            args["input"] = arg
        i += 1

    return args


def _load_style_css(style_name):
    """Load CSS for a named style. Falls back to embedded default."""
    if style_name == "default":
        return CSS

    css_path = os.path.join(STYLES_DIR, f"{style_name}.css")
    if os.path.exists(css_path):
        with open(css_path, "r") as f:
            return f.read()

    print(f"  Warning: Style '{style_name}' not found at {css_path}, using default")
    return CSS


def _generate_toc(md_content):
    """Extract headings from markdown and generate a TOC block."""
    headings = re.findall(r'^(#{2,4})\s+(.+)$', md_content, re.MULTILINE)
    if len(headings) < 3:
        return ""

    toc_lines = ["\n---\n\n## Table of Contents\n"]
    for hashes, title in headings:
        level = len(hashes) - 2  # h2=0, h3=1, h4=2
        indent = "  " * level
        slug = re.sub(r'[^a-z0-9-]', '', title.lower().replace(' ', '-'))
        toc_lines.append(f"{indent}- [{title}](#{slug})")

    toc_lines.append("\n---\n")
    return "\n".join(toc_lines)


def _generate_cover(md_content, input_path):
    """Generate a cover page block to prepend to the markdown."""
    # Extract title from first H1
    title_match = re.search(r'^#\s+(.+)$', md_content, re.MULTILINE)
    title = title_match.group(1) if title_match else os.path.splitext(os.path.basename(input_path))[0]

    date_str = datetime.now().strftime("%B %d, %Y")

    cover = f"""<div style="display:flex;flex-direction:column;justify-content:center;align-items:center;min-height:85vh;text-align:center;">
<h1 style="font-size:28pt;border:none;margin-bottom:20px;">{title}</h1>
<p style="font-size:12pt;color:#64748b;">{date_str}</p>
</div>

<div style="page-break-after:always;"></div>

"""
    return cover


def _highlight_style(style_name):
    """Pick highlight.js theme based on PDF style."""
    if style_name == "academic":
        return "github"
    return "atom-one-dark"


def main():
    args = _parse_args()

    if not args["input"]:
        print("Usage: python3 generate_pdf.py <input.md> [--open] [--style <name>] [--toc] [--cover] [--landscape]")
        print(f"Styles: {', '.join(AVAILABLE_STYLES)}")
        sys.exit(1)

    input_path = os.path.abspath(args["input"])
    if not os.path.exists(input_path):
        print(f"Error: File not found: {input_path}")
        sys.exit(1)

    style_name = args["style"]
    if style_name not in AVAILABLE_STYLES:
        print(f"Error: Unknown style '{style_name}'. Available: {', '.join(AVAILABLE_STYLES)}")
        sys.exit(1)

    base = os.path.splitext(input_path)[0]
    expected_output = base + ".pdf"

    # Load CSS for the selected style
    css_content = _load_style_css(style_name)

    # Build PDF options with style-specific margins
    pdf_opts = dict(PDF_OPTIONS)
    if style_name in STYLE_MARGINS:
        pdf_opts["margin"] = STYLE_MARGINS[style_name]
    if args["landscape"]:
        pdf_opts["landscape"] = True

    # Pre-process markdown if --cover or --toc
    md_input = input_path
    temp_md = None
    if args["cover"] or args["toc"]:
        with open(input_path, "r") as f:
            md_content = f.read()

        prepend = ""
        if args["cover"]:
            prepend += _generate_cover(md_content, input_path)
        if args["toc"]:
            toc_block = _generate_toc(md_content)
            if toc_block:
                prepend += toc_block

        if prepend:
            temp_md_file = tempfile.NamedTemporaryFile(
                mode="w", suffix=".md", delete=False, dir=os.path.dirname(input_path)
            )
            temp_md_file.write(prepend + md_content)
            temp_md_file.close()
            md_input = temp_md_file.name
            temp_md = temp_md_file.name

    # Write temp CSS
    css_file = tempfile.NamedTemporaryFile(mode="w", suffix=".css", delete=False)
    css_file.write(css_content)
    css_file.close()
    css_path = css_file.name

    try:
        cmd = [
            "npx", "--yes", "md-to-pdf",
            "--highlight-style", _highlight_style(style_name),
            "--stylesheet", css_path,
            "--pdf-options", json.dumps(pdf_opts),
            md_input,
        ]

        print(f"  Rendering: {os.path.basename(input_path)} (style: {style_name})")
        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            print("md-to-pdf error:")
            print(result.stderr)
            sys.exit(1)

        # If we used a temp markdown, the output is next to it — move to expected location
        if temp_md:
            temp_output = os.path.splitext(temp_md)[0] + ".pdf"
            if os.path.exists(temp_output) and temp_output != expected_output:
                os.rename(temp_output, expected_output)

        if os.path.exists(expected_output):
            size_kb = os.path.getsize(expected_output) / 1024
            print(f"  Style:     {style_name}")
            print(f"  Output:    {expected_output}")
            print(f"  Size:      {size_kb:.1f} KB")
            if args["cover"]:
                print("  Cover:     yes")
            if args["toc"]:
                print("  TOC:       yes")
            if args["landscape"]:
                print("  Layout:    landscape")
            if args["open"]:
                subprocess.run(["open", expected_output])
        else:
            print(f"Error: Expected output not found at {expected_output}")
            print("md-to-pdf stdout:", result.stdout)
            sys.exit(1)

    finally:
        os.unlink(css_path)
        if temp_md and os.path.exists(temp_md):
            os.unlink(temp_md)


if __name__ == "__main__":
    main()
