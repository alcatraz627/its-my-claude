import type { ReportData } from "../../generate-html.ts";
import { esc, renderBlock, renderSection, renderNav, computeStats } from "../../generate-html.ts";

const FAVICON =
  "data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'><rect x='4' y='2' width='24' height='28' rx='2' fill='%23fff' stroke='%2337352f' stroke-width='1.5'/><path d='M20 2 L20 10 L28 10' fill='%23f7f7f5' stroke='%2337352f' stroke-width='1.5' stroke-linejoin='round'/><line x1='9' y1='15' x2='23' y2='15' stroke='%23d3d1cb'/><line x1='9' y1='19' x2='23' y2='19' stroke='%23d3d1cb'/><line x1='9' y1='23' x2='18' y2='23' stroke='%23d3d1cb'/></svg>";

const GOOGLE_FONTS_URL =
  "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap";

export function buildHtml(data: ReportData): string {
  const statsStr = computeStats(data);
  const ogDesc = esc(data.subtitle ?? statsStr);

  // Build breadcrumb nav links
  const navLinks = data.nav
    .map((item) => `<a href="#${esc(item.id)}">${esc(item.text)}</a>`)
    .join("\n    ");

  // Build section cards: wrap each renderSection output in a .card div
  const sectionCards = data.sections
    .map(
      (section) =>
        `<div class="card">\n${renderSection(section)}\n</div>`
    )
    .join("\n\n  ");

  // Build meta items from generated date and stats
  const metaParts = [esc(data.generated), statsStr].filter(Boolean);
  const metaSpans = metaParts.map((m) => `<span>${m}</span>`).join("\n      ");

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
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="${GOOGLE_FONTS_URL}" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.css" crossorigin="anonymous">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.js" crossorigin="anonymous"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/contrib/auto-render.min.js" crossorigin="anonymous"></script>
<link rel="stylesheet" href="./styles.css">
</head>
<body>

<!-- Jump-link bar -->
<nav class="jump-bar" id="jump-bar">
  <div class="breadcrumb">
    <span class="breadcrumb-icon">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
    </span>
    Report <span class="sep">/</span> <span class="crumb-title">${esc(data.title)}</span>
  </div>
  <div class="jump-links" id="jump-links">
    ${navLinks}
  </div>
  <div class="nav-tools">
    <span class="report-stats">${statsStr}</span>
    <div class="width-picker">
      <button class="width-btn" data-width="sm">SM</button>
      <button class="width-btn" data-width="md">MD</button>
      <button class="width-btn" data-width="lg">LG</button>
      <button class="width-btn" data-width="xl">XL</button>
    </div>
  </div>
  <div class="search-wrap">
    <svg class="search-icon" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round">
      <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
    </svg>
    <input type="text" id="search" placeholder="Search..." autocomplete="off" spellcheck="false">
    <span id="search-count"></span>
  </div>
</nav>

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

<div class="page">

  <!-- Title -->
  <div class="title-block">
    <h1>${esc(data.title)}</h1>
    ${data.subtitle ? `<p class="subtitle">${esc(data.subtitle)}</p>` : ""}
    <div class="meta">
      ${metaSpans}
    </div>
  </div>

  <!-- Sections -->
  ${sectionCards}

</div>

<script src="./report.js" defer></script>
</body>
</html>`;
}
