import type { ReportData } from "../../generate-html.ts";
import { esc, highlight, renderBlock, computeStats, countBlocksOfType } from "../../generate-html.ts";

const FAVICON =
  "data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'><rect width='32' height='32' rx='4' fill='%23f0fdf4'/><rect x='4' y='4' width='24' height='4' fill='%2316a34a'/><rect x='4' y='12' width='11' height='3' rx='1' fill='%2316a34a' opacity='0.5'/><rect x='17' y='12' width='11' height='3' rx='1' fill='%2316a34a' opacity='0.3'/><rect x='4' y='18' width='11' height='3' rx='1' fill='%2316a34a' opacity='0.3'/><rect x='17' y='18' width='11' height='3' rx='1' fill='%2316a34a' opacity='0.5'/></svg>";

/**
 * Build data-table/spreadsheet-style HTML report.
 * Light background, full-width tables with sticky headers, zebra striping,
 * tabbed navigation (each H2 section = a tab), search/filter bar,
 * green header bar, compact typography optimized for data-heavy content.
 */
export function buildHtml(data: ReportData): string {
  const totalSections = data.sections.length;
  const totalTables = data.sections.reduce((acc, s) => acc + countBlocksOfType(s.blocks, ["table"]), 0);
  const totalCode = data.sections.reduce((acc, s) => acc + countBlocksOfType(s.blocks, ["code"]), 0);
  const totalRows = data.sections.reduce((acc, s) => {
    let rows = 0;
    const countRows = (blocks: any[]) => {
      for (const b of blocks) {
        if (b.type === "table") rows += b.rows.length;
        if ((b.type === "subsection" || b.type === "subsubsection") && b.blocks) countRows(b.blocks);
      }
    };
    countRows(s.blocks);
    return acc + rows;
  }, 0);

  const statsStr = computeStats(data);
  const ogDesc = esc(data.subtitle ?? statsStr);

  // Build tab buttons from sections
  const tabButtons = data.sections
    .map(
      (section, i) =>
        `<button class="tab-btn${i === 0 ? " active" : ""}" data-tab="${esc(section.id)}">${esc(section.heading)}</button>`
    )
    .join("\n        ");

  // Build tab panels — each section is a panel
  const tabPanels = data.sections
    .map(
      (section, i) =>
        `<div class="tab-panel${i === 0 ? " active" : ""}" data-panel="${esc(section.id)}" id="${esc(section.id)}">
          <div class="panel-header">
            <h2>${esc(section.heading)}</h2>
          </div>
          <div class="panel-body">
            ${section.blocks.map(renderBlock).join("\n            ")}
          </div>
        </div>`
    )
    .join("\n\n      ");

  // Stats bar items
  const statItems = [
    { label: "Sections", value: String(totalSections) },
    { label: "Tables", value: String(totalTables) },
    { label: "Rows", value: String(totalRows) },
    { label: "Code Blocks", value: String(totalCode) },
    { label: "Generated", value: esc(data.generated).split("T")[0] },
  ];

  const statsBarHtml = statItems
    .map((s) => `<span class="stat-item"><strong>${s.value}</strong> ${s.label}</span>`)
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
<link rel="icon" href="${FAVICON}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=IBM+Plex+Mono:wght@400;500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js"></script>
<link rel="stylesheet" href="./styles.css">
<script src="./report.js" defer></script>
</head>
<body>

<!-- Code Dialog -->
<dialog id="code-dialog">
  <div class="dlg-header">
    <span class="dlg-lang"></span>
    <span class="dlg-title"></span>
    <div class="dlg-actions">
      <span class="dlg-lines"></span>
      <button class="dlg-copy">Copy</button>
      <button class="dlg-close">Close</button>
    </div>
  </div>
  <div class="dlg-body"></div>
</dialog>

<!-- Header Bar -->
<header class="header-bar">
  <div class="header-content">
    <div class="header-left">
      <svg class="header-icon" width="20" height="20" viewBox="0 0 32 32" fill="none">
        <rect width="32" height="32" rx="4" fill="#f0fdf4"/>
        <rect x="4" y="4" width="24" height="4" fill="#fff"/>
      </svg>
      <h1>${esc(data.title)}</h1>
    </div>
    <div class="header-right">
      ${data.subtitle ? `<p class="header-subtitle">${esc(data.subtitle)}</p>` : ""}
    </div>
  </div>
</header>

<!-- Stats / Formula Bar -->
<div class="stats-bar">
  <div class="stats-inner">
    ${statsBarHtml}
    <span class="stat-item stat-summary">${esc(statsStr)}</span>
  </div>
</div>

<!-- Filter Bar -->
<div class="filter-bar">
  <div class="filter-inner">
    <div class="search-box">
      <svg class="search-icon" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
        <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
      </svg>
      <input type="text" id="table-search" placeholder="Filter rows..." autocomplete="off">
    </div>
    <span class="row-count" id="row-count"></span>
  </div>
</div>

<!-- Tab Navigation -->
<div class="tab-bar">
  <div class="tab-scroll">
    ${tabButtons}
  </div>
</div>

<!-- No Results -->
<div id="no-results" style="display:none">
  <p>No matching rows found.</p>
</div>

<!-- Tab Panels -->
<main class="main-content">
  ${tabPanels}
</main>

</body>
</html>`;
}
