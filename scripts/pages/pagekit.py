"""Build an HTML page in the shared house style, as one self-contained file.

A generator imports this, hands over a title and a body, and gets back a page
that carries the shared colours, components and behaviour inline. The same file
is the local preview and the thing that gets published, so they cannot differ.

    import sys; sys.path.insert(0, "/Users/<you>/.claude/scripts/pages")
    import pagekit
    html = pagekit.page("Title", pagekit.size_columns(body_html))

From markdown:  pagekit.from_markdown(text)  (needs the `markdown` package).
Guide: ~/.claude/conventions/pages.md
"""
import html as _html
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
COLORS = HERE.parent.parent / "conventions" / "html-assets" / "colors.css"

NOTES_COL = 9.0   # percent of the table, for a trailing column of buttons
ID_COL = 8.0      # percent, for a column that holds only short ids
WIDE_FROM = 8     # a table scrolls sideways only from this many columns


def slug(text):
    """The anchor a heading gets. It matches what GitHub and most markdown viewers make."""
    s = re.sub(r"<[^>]+>", "", text)
    s = re.sub(r"['’]", "", _html.unescape(s).lower())
    return re.sub(r"[^a-z0-9]+", "-", s).strip("-")


def _text(cell):
    return _html.unescape(re.sub(r"<[^>]+>", " ", cell)).strip()


def size_columns(body, button_col_class=None):
    """Give every table column a width that follows how much it holds.

    Left alone, a browser gives a column of ids the same room as a column of
    sentences. Here a column's share grows with the square root of its usual cell
    length, so the widest text column stays within about three times the
    narrowest. A column holding only short ids gets a small fixed share.
    """
    def table(m):
        t = m.group(0)
        heads = re.findall(r"<th\b([^>]*)>(.*?)</th>", t, flags=re.S)
        rows = [re.findall(r"<td\b[^>]*>(.*?)</td>", r, flags=re.S) for r in re.findall(r"<tr\b[^>]*>(.*?)</tr>", t, flags=re.S)]
        rows = [r for r in rows if r]
        if not heads or not rows:
            return t
        has_buttons = bool(button_col_class) and button_col_class in heads[-1][0]
        n = len(heads) - (1 if has_buttons else 0)
        weights, fixed = [], []
        for c in range(n):
            lengths = sorted(len(_text(r[c])) for r in rows if c < len(r))
            usual = lengths[len(lengths) * 3 // 4] if lengths else 0
            longest = lengths[-1] if lengths else 0
            head_len = len(_text(heads[c][1]))
            if longest <= 8:
                fixed.append(max(ID_COL, head_len * 0.9))
                weights.append(0)
            else:
                fixed.append(0)
                weights.append(min(9.0, max(3.0, usual ** 0.5, head_len * 0.35)))
        room = 100.0 - (NOTES_COL if has_buttons else 0) - sum(fixed)
        if sum(weights):
            widths = [f if f else room * w / sum(weights) for f, w in zip(fixed, weights)]
        else:
            widths = [f * (room + sum(fixed)) / (sum(fixed) or 1) for f in fixed]
        cols = "".join(f'<col style="width:{w:.1f}%">' for w in widths)
        if has_buttons:
            cols += f'<col style="width:{NOTES_COL}%">'
        cls = ' class="kit-wide"' if len(heads) >= WIDE_FROM else ""
        return re.sub(r"<table[^>]*>", f"<table{cls}><colgroup>{cols}</colgroup>", t, count=1)
    return re.sub(r"<table\b[^>]*>.*?</table>", table, body, flags=re.S)


def heading_ids(body):
    """Every heading gets an anchor, so any section can be linked to."""
    return re.sub(r"<(h[2-4])>(.*?)</\1>", lambda m: f'<{m.group(1)} id="{slug(m.group(2))}">{m.group(2)}</{m.group(1)}>', body, flags=re.S)


def side_by_side(body):
    """Two or three labelled lists in a row sit beside each other. In markdown, each is a bold line then a list."""
    block = r"<p><strong>([^<.]+)</strong></p>\s*(<ul>(?:(?!</ul>).)*</ul>)\s*"
    def run(m):
        cols = re.findall(block, m.group(0), flags=re.S)
        return '<div class="kit-cols">' + "".join(f'<section class="kit-col"><h4>{label}</h4>{items}</section>' for label, items in cols) + "</div>"
    return re.sub(r"(?:%s){2,}" % block, run, body, flags=re.S)


def cell_lists(body):
    """A table cell written as a lead line and bullets (`Lead.<br>• one<br>• two`) becomes a real list."""
    def cell(m):
        inner = m.group(1)
        if not re.search(r"<br\s*/?>\s*•", inner):
            return m.group(0)
        parts = [x.strip() for x in re.split(r"<br\s*/?>", inner)]
        lead = "".join(f"<p>{x}</p>" for x in parts if x and not x.startswith("•"))
        items = "".join(f"<li>{x[1:].strip()}</li>" for x in parts if x.startswith("•"))
        return f"<td>{lead}<ul>{items}</ul></td>"
    return re.sub(r"<td>(.*?)</td>", cell, body, flags=re.S)


def from_markdown(text):
    """Markdown to a body in the house style: anchors, real lists in cells, side-by-side lists, sized columns."""
    import markdown
    body = markdown.Markdown(extensions=["tables", "fenced_code", "sane_lists"]).convert(text)
    return size_columns(heading_ids(side_by_side(cell_lists(body))))


def main():
    """pagekit.py <in.md> <out.html> [title]: one markdown file to one page."""
    import sys
    if len(sys.argv) < 3:
        sys.exit("usage: uv run --with markdown python3 pagekit.py <in.md> <out.html> [title]")
    src, out = Path(sys.argv[1]), Path(sys.argv[2])
    text = src.read_text()
    first = re.search(r"^# (.+)$", text, flags=re.M)
    title = sys.argv[3] if len(sys.argv) > 3 else (first.group(1) if first else src.stem)
    if first:
        text = text.replace(first.group(0), "", 1)
    out.write_text(page(title, from_markdown(text)))
    print(out)


def page(title, body, tabs=None, extra_css="", extra_js=""):
    """One self-contained HTML file. `tabs` is a list of (key, label); each body panel then carries data-kit-panel."""
    esc = _html.escape(title)
    tab_bar = ""
    if tabs:
        tab_bar = '<nav class="kit-tabs" role="tablist">' + "".join(
            f'<button class="kit-tab" role="tab" data-kit-tab="{k}">{_html.escape(label)}</button>' for k, label in tabs) + "</nav>"
    return f"""<!doctype html>
<html lang="en" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{esc}</title>
<style>
{COLORS.read_text()}
{(HERE / "kit.css").read_text()}
{extra_css}
</style>
</head>
<body>
<header class="kit-bar"><div class="kit-bar-inner"><h1 class="kit-title">{esc}</h1><button type="button" class="kit-theme" data-kit-theme>Light</button></div>{tab_bar}</header>
<main class="kit-page">
{body}
</main>
<script>
{(HERE / "kit.js").read_text()}
{extra_js}
</script>
</body>
</html>
"""


if __name__ == "__main__":
    main()
