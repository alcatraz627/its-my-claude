"""Interactive mermaid diagrams for pages built on the kit.

A diagram becomes a viewer you can pan, zoom, search and walk through: hover
to see a step's connections, focus on one step, step through the flow, drag
boxes, and export SVG, PNG or the mermaid text. The mermaid source is never
changed. Guide: conventions/pages.md, section "Diagrams".

As a CLI, one markdown file's diagram becomes one full-window page:

    python3 diagram.py doc.md out.html [--title T] [--index N]

From Python, inside a page made with pagekit.page():

    import diagram
    css, js = diagram.assets()
    body = diagram.block(src, md=doc_text, file=doc_path)
    html = pagekit.page("Title", body, extra_css=css, extra_js=js)

The mermaid bundle (about 5 MB) is fetched once into ~/.cache/gcc/mermaid and
inlined, so each page still opens offline as one file.
"""
import argparse
import html
import json
import re
import sys
import urllib.request
from pathlib import Path

HERE = Path(__file__).parent
MERMAID_VERSION = "12.2.0"
CACHE = Path.home() / ".cache/gcc/mermaid" / MERMAID_VERSION / "mermaid.min.js"


def mermaid_js():
    """The mermaid bundle's text, fetched once and cached."""
    if not CACHE.exists():
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        url = f"https://cdn.jsdelivr.net/npm/mermaid@{MERMAID_VERSION}/dist/mermaid.min.js"
        with urllib.request.urlopen(url, timeout=60) as r:
            CACHE.write_bytes(r.read())
    return CACHE.read_text()


def script_safe(text):
    """Text inside a <script> element must not close it early."""
    return text.replace("</script", "<\\/script")


def assets():
    """(css, js) to pass to pagekit.page() as extra_css and extra_js."""
    return (HERE / "diagram.css").read_text(), script_safe(mermaid_js()) + "\n" + (HERE / "diagram.js").read_text()


_n = 0


def block(src, md=None, file=None, key=None, height=None, panel=True, expand=True, name=None, full=False):
    """The HTML for one diagram viewer. `src` is mermaid text; `md` the doc it came from (feeds the side panel)."""
    global _n
    _n += 1
    el = f"dl-{_n}"
    opts = {"src": src, "md": md, "file": file, "key": key or el, "height": height, "panel": panel, "expand": expand, "name": name}
    data = script_safe(json.dumps({k: v for k, v in opts.items() if v is not None}))
    cls = ' class="dl-full"' if full else ""
    return (f'<div id="{el}"{cls}></div>\n'
            f'<script type="application/json" id="{el}-opts">{data}</script>\n'
            f'<script>addEventListener("DOMContentLoaded", () => MermaidLab.mount(document.getElementById("{el}"), '
            f'JSON.parse(document.getElementById("{el}-opts").textContent)));</script>\n')


def diagrams_in(md):
    """Every mermaid block in a markdown text, in order."""
    return re.findall(r"```mermaid\n(.*?)```", md, re.S)


def main():
    ap = argparse.ArgumentParser(description="Turn a markdown file's mermaid diagram into an interactive page.")
    ap.add_argument("doc", type=Path, help="markdown file holding a ```mermaid block")
    ap.add_argument("out", type=Path, help="HTML file to write")
    ap.add_argument("--title", help="page title (default: the doc's first heading)")
    ap.add_argument("--index", type=int, default=0, help="which mermaid block, counting from 0")
    a = ap.parse_args()
    sys.path.insert(0, str(HERE.parent))
    import pagekit

    md = a.doc.read_text()
    found = diagrams_in(md)
    if not found:
        sys.exit(f"no ```mermaid block in {a.doc}")
    if a.index >= len(found):
        sys.exit(f"{a.doc} has {len(found)} mermaid blocks; --index {a.index} is past the end")
    title = a.title or next((m.group(1) for m in re.finditer(r"^#\s+(.*)", md, re.M)), a.doc.stem)
    css, js = assets()
    css += "\n.kit-page { max-width: none; padding: 0; } .kit-bar-inner { max-width: none; } .dl-full { --dl-height: calc(100vh - var(--dl-bar, 53px)); }"
    js += "\ndocument.documentElement.style.setProperty('--dl-bar', (document.querySelector('.kit-bar')?.offsetHeight ?? 53) + 'px');"
    body = block(found[a.index], md=md, file=a.doc.resolve().as_uri(), key=a.doc.stem, expand=False, name=a.doc.stem, full=True)
    a.out.write_text(pagekit.page(html.unescape(title), body, extra_css=css, extra_js=js))
    print(f"{a.out} ({a.out.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
