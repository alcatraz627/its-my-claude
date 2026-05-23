import type { ReportData } from "../../generate-html.ts";
import { esc, highlight, renderBlock, renderSection, renderNav, computeStats, countBlocksOfType } from "../../generate-html.ts";

const FAVICON = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='6' fill='%230f172a'/%3E%3Crect x='5' y='18' width='5' height='9' rx='1' fill='%233b82f6'/%3E%3Crect x='13' y='12' width='5' height='15' rx='1' fill='%238b5cf6'/%3E%3Crect x='21' y='6' width='5' height='21' rx='1' fill='%2310b981'/%3E%3C/svg%3E";

/**
 * Build dashboard-style HTML report.
 * Dark slate background, gradient blue-purple header, metric cards,
 * left sidebar nav, status pills, accordion sections.
 */
export function buildHtml(data: ReportData): string {
  const totalSections = data.sections.length;
  const totalTables = data.sections.reduce((acc, s) => acc + countBlocksOfType(s.blocks, ["table"]), 0);
  const totalCode = data.sections.reduce((acc, s) => acc + countBlocksOfType(s.blocks, ["code"]), 0);

  // Build sidebar nav links from data.nav
  const navLinks = data.nav
    .map(
      (item, i) =>
        `<a href="#${esc(item.id)}"${i === 0 ? ' class="active"' : ""}><span class="icon">●</span> ${esc(item.text)}</a>`
    )
    .join("\n      ");

  // Build metric cards
  const metrics = [
    { label: "Sections", value: String(totalSections), sub: "In this report" },
    { label: "Tables", value: String(totalTables), sub: "Data tables rendered" },
    { label: "Code Blocks", value: String(totalCode), sub: "Syntax-highlighted" },
    { label: "Generated", value: esc(data.generated).split("T")[0], sub: "Report creation date" },
  ];

  const metricCards = metrics
    .map(
      (m) =>
        `<div class="metric-card">
            <div class="label">${m.label}</div>
            <div class="value">${m.value}</div>
            <div class="sub">${m.sub}</div>
          </div>`
    )
    .join("\n        ");

  // Build content sections as accordions
  const sectionHtml = data.sections
    .map(
      (section) =>
        `<a id="${esc(section.id)}"></a>
      <details open>
        <summary>
          <span class="section-bar"></span>
          <h2>${esc(section.heading)}</h2>
        </summary>
        <div class="section-content">
          ${section.blocks.map(renderBlock).join("\n          ")}
        </div>
      </details>`
    )
    .join("\n\n      ");

  const statsStr = computeStats(data);
  const ogDesc = esc(data.subtitle ?? statsStr);

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
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
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

<!-- Header -->
<div class="header">
  <div class="header-top">
    <div class="header-title">
      <h1>${esc(data.title)}</h1>
      ${data.subtitle ? `<p>${esc(data.subtitle)}</p>` : `<p>${statsStr}</p>`}
    </div>
    <button id="sidebar-toggle" class="sidebar-toggle" title="Toggle sidebar">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
    </button>
  </div>
  <div class="header-search">
    <input type="text" id="search" placeholder="Search sections... (Ctrl+K)" autocomplete="off">
    <span id="search-count"></span>
  </div>
</div>

<div id="no-results" style="display:none;text-align:center;padding:48px 20px;color:var(--text-muted);font-size:0.9rem;">No sections match your search.</div>

<div class="layout">
  <!-- Sidebar -->
  <nav class="sidebar">
    <div class="sidebar-label">Report Sections</div>
    ${navLinks}
  </nav>

  <!-- Content -->
  <main class="content">

    <!-- Metric Cards -->
    <div class="metrics">
      ${metricCards}
    </div>

    <!-- Sections -->
    ${sectionHtml}

  </main>
</div>

</body>
</html>`;
}
