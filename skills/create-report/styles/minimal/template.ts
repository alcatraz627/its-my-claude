import type { ReportData } from "../../generate-html.ts";
import {
  esc,
  renderBlock,
  renderSection,
  computeStats,
} from "../../generate-html.ts";

// Minimal text-lines icon — matches the ultra-clean aesthetic
const FAVICON =
  "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='8' fill='%23f8fafc' stroke='%23e2e8f0' stroke-width='2'/%3E%3Crect x='8' y='9' width='16' height='1.5' rx='.75' fill='%2394a3b8'/%3E%3Crect x='8' y='14' width='12' height='1.5' rx='.75' fill='%23cbd5e1'/%3E%3Crect x='8' y='19' width='14' height='1.5' rx='.75' fill='%23cbd5e1'/%3E%3Crect x='8' y='24' width='10' height='1.5' rx='.75' fill='%23e2e8f0'/%3E%3C/svg%3E";

export function buildHtml(data: ReportData): string {
  const statsStr = computeStats(data);
  const ogDesc = esc(data.subtitle ?? statsStr);

  // Build TOC links inside a collapsible <details>
  const tocLinks = data.nav
    .map((item) => {
      const children = item.children
        ? item.children
            .map((c) => `<li><a href="#${esc(c.id)}">${esc(c.text)}</a></li>`)
            .join("\n            ")
        : "";
      const childList = children
        ? `\n          <ul class="toc-children">\n            ${children}\n          </ul>`
        : "";
      return `<li><a href="#${esc(item.id)}">${esc(item.text)}</a>${childList}</li>`;
    })
    .join("\n        ");

  // Build sections — no card wrapper, just flowing content
  const sectionBlocks = data.sections
    .map((section) => renderSection(section))
    .join("\n\n  ");

  // Meta line
  const metaParts = [esc(data.generated), statsStr].filter(Boolean);
  const metaSpans = metaParts
    .map((m) => `<span>${m}</span>`)
    .join("\n        ");

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${esc(data.title)}</title>
<meta property="og:title" content="${esc(data.title)}">
<meta property="og:description" content="${ogDesc}">
<meta property="og:type" content="article">
<meta name="twitter:card" content="summary">
<meta name="twitter:title" content="${esc(data.title)}">
<meta name="twitter:description" content="${ogDesc}">
<link rel="icon" href="${FAVICON}">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.css" crossorigin="anonymous">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.js" crossorigin="anonymous"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/contrib/auto-render.min.js" crossorigin="anonymous"></script>
<link rel="stylesheet" href="./styles.css">
</head>
<body>

<!-- Collapsible TOC at top -->
<div class="toc-bar">
  <details id="toc-details">
    <summary class="toc-toggle">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="15" y2="12"/><line x1="3" y1="18" x2="10" y2="18"/></svg>
      <span>Contents</span>
    </summary>
    <div class="toc-content">
      <div class="toc-search-wrap">
        <input type="text" id="search" placeholder="Search..." autocomplete="off" spellcheck="false">
        <span id="search-count"></span>
      </div>
      <ul class="toc-list">
        ${tocLinks}
      </ul>
    </div>
  </details>
</div>

<!-- Code expand dialog -->
<dialog id="code-dialog">
  <div class="dlg-header">
    <span class="dlg-lang"></span>
    <span class="dlg-title"></span>
    <span class="dlg-actions">
      <span class="dlg-lines"></span>
      <button class="dlg-copy">Copy</button>
      <button class="dlg-close">Close</button>
    </span>
  </div>
  <div class="dlg-body"></div>
</dialog>

<!-- No results -->
<div id="no-results">No sections match your search.</div>

<main class="page">

  <!-- Title -->
  <header class="title-block">
    <h1>${esc(data.title)}</h1>
    ${data.subtitle ? `<p class="subtitle">${esc(data.subtitle)}</p>` : ""}
    <div class="meta">
      ${metaSpans}
    </div>
  </header>

  <!-- Sections -->
  ${sectionBlocks}

</main>

<script src="./report.js" defer></script>
</body>
</html>`;
}
