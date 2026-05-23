import type { ReportData } from "../../generate-html.ts";
import { esc, renderBlock, computeStats } from "../../generate-html.ts";

const FAVICON =
  "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='6' fill='%23171532'/%3E%3Crect x='4' y='8' width='24' height='16' rx='2' fill='%234338ca' opacity='0.6'/%3E%3Ccircle cx='16' cy='16' r='3' fill='%23e0e7ff'/%3E%3C/svg%3E";

const GOOGLE_FONTS_URL =
  "https://fonts.googleapis.com/css2?" +
  "family=Plus+Jakarta+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;0,800;1,300;1,400" +
  "&family=Inter:wght@300;400;500;600;700;800" +
  "&family=JetBrains+Mono:wght@400;700" +
  "&family=Fira+Code:wght@400;700" +
  "&display=swap";

const KATEX_CSS =
  "https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.css";
const KATEX_JS = "https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.js";
const KATEX_AUTO =
  "https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/contrib/auto-render.min.js";

export function buildHtml(data: ReportData): string {
  const totalSlides = data.sections.length;
  const statsStr = computeStats(data);
  const ogDesc = esc(data.subtitle ?? statsStr);

  /* Build slide sections */
  const slidesHtml = data.sections
    .map((section, i) => {
      const sectionBlocks = section.blocks.map(renderBlock).join("\n");
      const isTitle = i === 0;
      return [
        `<section class="slide${isTitle ? " slide--title" : ""}" data-section-id="${esc(section.id)}" data-slide-index="${i}">`,
        `  <div class="slide-inner">`,
        `    <h2 id="${esc(section.id)}">${esc(section.heading)}</h2>`,
        `    <div class="slide-content">`,
        sectionBlocks,
        `    </div>`,
        `  </div>`,
        `</section>`,
      ].join("\n");
    })
    .join("\n");

  /* Navigation dots */
  const dotsHtml = data.sections
    .map(
      (s, i) =>
        `<button class="nav-dot${i === 0 ? " active" : ""}" data-slide="${i}" aria-label="Go to slide ${i + 1}: ${esc(s.heading)}"></button>`,
    )
    .join("\n      ");

  /* Floating TOC */
  const tocHtml = data.sections
    .map(
      (s, i) =>
        `<a class="toc-item${i === 0 ? " active" : ""}" href="#${esc(s.id)}" data-slide="${i}">${esc(s.heading)}</a>`,
    )
    .join("\n      ");

  /* Color swatches */
  const SWATCHES = [
    { name: "indigo", hex: "#6366f1" },
    { name: "violet", hex: "#8b5cf6" },
    { name: "purple", hex: "#a855f7" },
    { name: "fuchsia", hex: "#d946ef" },
    { name: "pink", hex: "#ec4899" },
    { name: "rose", hex: "#f43f5e" },
    { name: "red", hex: "#ef4444" },
    { name: "orange", hex: "#f97316" },
    { name: "amber", hex: "#f59e0b" },
    { name: "yellow", hex: "#eab308" },
    { name: "lime", hex: "#84cc16" },
    { name: "emerald", hex: "#10b981" },
    { name: "teal", hex: "#14b8a6" },
    { name: "cyan", hex: "#06b6d4" },
    { name: "sky", hex: "#0ea5e9" },
    { name: "blue", hex: "#3b82f6" },
  ];
  const swatchesHtml = SWATCHES.map(
    (s) =>
      `<button class="color-dot" data-accent="${s.name}" style="background:${s.hex}" title="${s.name}"></button>`,
  ).join("\n            ");

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
<link rel="stylesheet" href="${KATEX_CSS}" crossorigin="anonymous">
<script defer src="${KATEX_JS}" crossorigin="anonymous"></script>
<script defer src="${KATEX_AUTO}" crossorigin="anonymous"></script>
<link rel="stylesheet" href="./styles.css">
</head>
<body>

<!-- Progress Bar -->
<div class="progress-bar" id="progress-bar"></div>

<!-- Slide Container -->
<div class="slide-container" id="slide-container">
  ${slidesHtml}
</div>

<!-- Floating TOC (right side) -->
<nav class="slide-toc" id="slide-toc" aria-label="Table of contents">
  <div class="toc-inner">
    ${tocHtml}
  </div>
</nav>

<!-- Navigation Dots -->
<nav class="nav-dots" id="nav-dots" aria-label="Slide navigation">
  ${dotsHtml}
</nav>

<!-- Slide Counter -->
<div class="slide-counter" id="slide-counter">
  <span id="current-slide">1</span> / <span id="total-slides">${totalSlides}</span>
</div>

<!-- Search Overlay -->
<div class="search-overlay" id="search-overlay" hidden>
  <div class="search-modal">
    <div class="search-header">
      <input type="text" id="search" placeholder="Search slides... (Esc to close)" aria-label="Search slides">
      <button class="search-close" id="search-close" aria-label="Close search">&times;</button>
    </div>
    <div class="search-results" id="search-results"></div>
    <span id="search-count" class="search-count"></span>
  </div>
</div>

<!-- Toolbar (all controls) -->
<div class="toolbar" id="toolbar">
  <div class="color-picker">
    <button class="toolbar-btn" id="color-btn" title="Accent color">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="4" fill="currentColor"/></svg>
    </button>
    <div id="color-menu" class="color-menu">
      ${swatchesHtml}
    </div>
  </div>

  <div class="width-picker">
    <button class="width-btn" data-width="sm">SM</button>
    <button class="width-btn active" data-width="md">MD</button>
    <button class="width-btn" data-width="lg">LG</button>
    <button class="width-btn" data-width="xl">XL</button>
  </div>

  <div class="text-size-picker">
    <button class="toolbar-btn text-size-btn" id="text-smaller" title="Decrease text size">A−</button>
    <span class="text-size-label" id="text-size-label">100%</span>
    <button class="toolbar-btn text-size-btn" id="text-larger" title="Increase text size">A+</button>
  </div>

  <button class="toolbar-btn" id="search-btn" aria-label="Search (Cmd+K)">
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
  </button>

</div>

<div id="no-results" hidden>No sections match your search.</div>

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

<!-- Footer stats (hidden, for metadata) -->
<footer class="slide-footer" hidden>
  <span>Generated: ${esc(data.generated)}</span>
  <span>${statsStr}</span>
</footer>

<script src="./report.js" defer></script>
</body>
</html>`;
}
