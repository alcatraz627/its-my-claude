"""Open a built page in headless Chrome and check what a reader would meet.

A screenshot shows one moment. This drives the page: it loads it, scrolls it,
switches the theme, and measures. It exits non-zero when any check fails, so a
build can depend on it.

    uv run --with playwright python3 check_page.py <file-or-url> [--out DIR] [--hash-routing]

--hash-routing: the page handles `#...` links in its own script (tabs, views),
so an in-page link is checked by clicking it, not by looking for a matching id.
Guide: ~/.claude/conventions/pages.md
"""
import json
import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

MEASURE = """() => {
  const res = {tables: 0, scroll_sideways: [], page_overflow: false, dead_links: [], theme_button: false};
  res.page_overflow = document.documentElement.scrollWidth > innerWidth + 2;
  res.theme_button = !!document.querySelector('[data-kit-theme], [data-theme-toggle]');
  const hidden = [];
  document.querySelectorAll('[hidden]').forEach(e => { hidden.push(e); e.hidden = false; });
  document.querySelectorAll('table').forEach((t, i) => {
    res.tables++;
    const wrap = t.parentElement.getBoundingClientRect().width;
    if (t.getBoundingClientRect().width > wrap + 2) {
      const h = t.tHead ? Array.from(t.tHead.rows[0].cells).map(c => c.textContent.trim()).join(' | ') : '';
      res.scroll_sideways.push('table ' + i + ': ' + h);
    }
  });
  hidden.forEach(e => { e.hidden = true; });
  if (!HASH_ROUTING) {
    document.querySelectorAll('a[href^="#"]').forEach(a => {
      const id = decodeURIComponent(a.getAttribute('href').slice(1));
      if (id && !document.getElementById(id)) res.dead_links.push('#' + id);
    });
  }
  return res;
}"""

# Text that cannot be read. A theme switch can change the page and still leave text the colour of its background.
CONTRAST = """() => {
  const cv = document.createElement('canvas'); cv.width = cv.height = 1;
  const cx = cv.getContext('2d', {willReadFrequently: true});
  function rgba(c) { cx.clearRect(0, 0, 1, 1); cx.fillStyle = '#000'; cx.fillStyle = c; cx.fillRect(0, 0, 1, 1); return Array.from(cx.getImageData(0, 0, 1, 1).data); }
  function lum([r, g, b]) { const f = v => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }; return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b); }
  function backdrop(el) {
    for (let e = el; e; e = e.parentElement) { const c = rgba(getComputedStyle(e).backgroundColor); if (c[3] > 200) return c; }
    return rgba(getComputedStyle(document.documentElement).backgroundColor)[3] > 200 ? rgba(getComputedStyle(document.documentElement).backgroundColor) : [255, 255, 255, 255];
  }
  const bad = [], seen = new Set();
  const els = Array.from(document.querySelectorAll('p, li, td, th, h1, h2, h3, h4, a, button, label')).filter(e => e.offsetParent !== null && e.textContent.trim().length > 2 && e.children.length === 0);
  els.slice(0, 400).forEach(e => {
    const fg = rgba(getComputedStyle(e).color), bg = backdrop(e);
    const a = lum(fg), b = lum(bg), ratio = (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
    const key = e.tagName + getComputedStyle(e).color;
    if (ratio < 3 && !seen.has(key)) { seen.add(key); bad.push(e.tagName.toLowerCase() + ' "' + e.textContent.trim().slice(0, 40) + '" at ' + ratio.toFixed(1) + ' to 1'); }
  });
  return bad;
}"""

STICKY = """() => {
  const bar = document.querySelector('.kit-bar, header');
  const top = bar ? bar.getBoundingClientRect().bottom : 0;
  const tall = Array.from(document.querySelectorAll('table')).find(t => t.offsetParent !== null && t.tHead && t.getBoundingClientRect().height > innerHeight);
  if (!tall) return {tested: false};
  window.scrollTo(0, tall.getBoundingClientRect().top + scrollY + 300);
  return new Promise(done => setTimeout(() => {
    const gap = Math.round(tall.tHead.getBoundingClientRect().top - top);
    done({tested: true, gap});
  }, 300));
}"""


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not args:
        sys.exit(__doc__)
    target = args[0]
    url = target if "://" in target else Path(target).resolve().as_uri()
    out = Path(sys.argv[sys.argv.index("--out") + 1]) if "--out" in sys.argv else Path.cwd()
    if "--out" in sys.argv:
        args = [a for a in args if a != str(out)]
    out.mkdir(parents=True, exist_ok=True)
    hash_routing = "--hash-routing" in sys.argv
    failures = []

    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        page = browser.new_page(viewport={"width": 1440, "height": 900})
        errors = []
        page.on("pageerror", lambda e: errors.append(str(e)))
        page.goto(url)
        page.wait_for_timeout(500)

        res = page.evaluate(MEASURE.replace("HASH_ROUTING", "true" if hash_routing else "false"))
        sticky = page.evaluate(STICKY)
        page.evaluate("() => window.scrollTo(0, 0)")

        themes = {}
        bg = lambda: page.evaluate("() => getComputedStyle(document.body).backgroundColor")
        themes["first"] = bg()
        unreadable = {"first theme": page.evaluate(CONTRAST)}
        page.screenshot(path=str(out / "check-first-theme.png"))
        toggle = page.locator("[data-kit-theme], [data-theme-toggle]").first
        if res["theme_button"]:
            toggle.click()
            page.wait_for_timeout(200)
            themes["second"] = bg()
            unreadable["second theme"] = page.evaluate(CONTRAST)
            page.screenshot(path=str(out / "check-second-theme.png"))
        browser.close()

    if errors:
        failures.append(f"page errors: {errors}")
    if res["page_overflow"]:
        failures.append("the page itself scrolls sideways at 1440 wide")
    if res["scroll_sideways"]:
        failures.append(f"tables that scroll sideways: {res['scroll_sideways']}")
    if res["dead_links"]:
        failures.append(f"in-page links with no target: {sorted(set(res['dead_links']))}")
    if not res["theme_button"]:
        failures.append("no theme switch on the page")
    elif themes.get("first") == themes.get("second"):
        failures.append("the theme switch did not change the background")
    for theme, found in unreadable.items():
        if found:
            failures.append(f"text too close to its background in the {theme}: {found[:8]}")
    if sticky.get("tested") and abs(sticky["gap"]) > 3:
        failures.append(f"a tall table's header sits {sticky['gap']}px from the bar, not under it")

    report = {"url": url, "tables": res["tables"], "sticky": sticky, "themes": themes, "failures": failures}
    (out / "check-page.json").write_text(json.dumps(report, indent=1))
    print(json.dumps(report, indent=1))
    print("PASS" if not failures else f"FAIL: {len(failures)} check(s)")
    sys.exit(1 if failures else 0)


main()
