import type { ReportData } from "../../generate-html.ts";
import {
  esc,
  renderBlock,
  renderSection,
  renderNav,
  computeStats,
} from "../../generate-html.ts";

const FAVICON =
  "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='4' fill='%230a0a0f'/%3E%3Ctext x='4' y='23' font-family='monospace' font-size='20' font-weight='bold' fill='%2300f0ff'%3EN%3C/text%3E%3Ctext x='16' y='23' font-family='monospace' font-size='20' font-weight='bold' fill='%23ff00ff'%3EX%3C/text%3E%3C/svg%3E";

const GOOGLE_FONTS_URL =
  "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;700&family=Space+Grotesk:wght@400;500;600;700&display=swap";

const KATEX_CSS =
  "https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.css";
const KATEX_JS = "https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.js";
const KATEX_AUTO =
  "https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/contrib/auto-render.min.js";

export function buildHtml(data: ReportData): string {
  const statsStr = computeStats(data);
  const ogDesc = esc(data.subtitle ?? statsStr);

  // Build sidebar nav links
  const navLinks = data.nav
    .map(
      (item, i) =>
        `<a href="#${esc(item.id)}"${i === 0 ? ' class="active"' : ""}><span class="nav-indicator"></span><span class="nav-text">${esc(item.text)}</span></a>`,
    )
    .join("\n      ");

  // Build sections with data-section-id
  const sectionHtml = data.sections
    .map(
      (section) =>
        `<section class="neon-section" data-section-id="${esc(section.id)}">
        <a id="${esc(section.id)}"></a>
        <div class="section-header">
          <div class="section-glow-bar"></div>
          <h2>${esc(section.heading)}</h2>
          <div class="section-actions">
            <button class="section-copy-btn" title="Copy section" aria-label="Copy section">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>
            </button>
          </div>
        </div>
        <div class="section-content">
          ${section.blocks.map(renderBlock).join("\n          ")}
        </div>
      </section>`,
    )
    .join("\n\n      ");

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
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="${GOOGLE_FONTS_URL}" rel="stylesheet">
<link rel="stylesheet" href="${KATEX_CSS}" crossorigin="anonymous">
<script defer src="${KATEX_JS}" crossorigin="anonymous"></script>
<script defer src="${KATEX_AUTO}" crossorigin="anonymous"></script>
<link rel="stylesheet" href="./styles.css">
</head>
<body>

<!-- Scanline overlay -->
<div class="scanline-overlay"></div>

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
<header class="neon-header">
  <div class="header-top">
    <div class="header-title">
      <h1>${esc(data.title)}</h1>
      ${data.subtitle ? `<p class="subtitle">${esc(data.subtitle)}</p>` : `<p class="subtitle">${statsStr}</p>`}
    </div>
    <div class="header-controls">
      <div class="width-picker">
        <button class="width-btn" data-width="sm">SM</button>
        <button class="width-btn" data-width="md">MD</button>
        <button class="width-btn" data-width="lg">LG</button>
        <button class="width-btn" data-width="xl">XL</button>
      </div>
      <div class="neon-color-picker">
        <button class="neon-color-toggle" title="Neon accent color">
          <span class="neon-swatch"></span>
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
        </button>
        <div class="neon-color-dropdown" id="neon-color-dropdown"></div>
      </div>
    </div>
    <div class="header-search">
      <input type="text" id="search" placeholder="Search... (Ctrl+K)" autocomplete="off" spellcheck="false">
      <span id="search-count"></span>
    </div>
  </div>
</header>

<div id="no-results" style="display:none;text-align:center;padding:48px 20px;color:var(--text-muted);font-size:0.9rem;font-family:'JetBrains Mono',monospace;">No sections match your search.</div>

<div class="layout">
  <!-- Sidebar -->
  <nav class="sidebar">
    <div class="sidebar-label">// SECTIONS</div>
    ${navLinks}
  </nav>

  <!-- Content -->
  <main class="content">
    ${sectionHtml}
  </main>
</div>

<script src="./report.js" defer></script>
</body>
</html>`;
}
