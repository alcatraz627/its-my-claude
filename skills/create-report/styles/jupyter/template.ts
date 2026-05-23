import type { ReportData, Section, Block } from "../../generate-html.ts";
import {
  esc,
  renderBlock,
  highlight,
  computeStats,
} from "../../generate-html.ts";

const FAVICON =
  "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='6' fill='%23f37626'/%3E%3Ccircle cx='16' cy='8' r='3' fill='%23fff'/%3E%3Ccircle cx='8' cy='24' r='2.5' fill='%239e9e9e'/%3E%3Ccircle cx='24' cy='24' r='2.5' fill='%234e4e4e'/%3E%3C/svg%3E";

const KATEX_CSS =
  "https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.css";
const KATEX_JS = "https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.js";
const KATEX_AUTO =
  "https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/contrib/auto-render.min.js";

const JETBRAINS_MONO =
  "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;700&display=swap";

/** Track cell numbering across the entire notebook */
interface CellCounter {
  inN: number;
  outN: number;
}

/** Wrap a single block in a Jupyter-style cell div */
function renderCell(block: Block, counter: CellCounter): string {
  switch (block.type) {
    case "code": {
      counter.inN++;
      const n = counter.inN;
      return [
        `<div class="nb-cell nb-cell-code" data-cell-type="code">`,
        `  <div class="cell-prompt cell-prompt-in">In&nbsp;[${n}]:</div>`,
        `  <div class="cell-content">`,
        `    <div class="cell-run-wrap"><button class="cell-run-btn" aria-label="Run cell" title="Run cell">&#9654;</button></div>`,
        renderBlock(block),
        `  </div>`,
        `</div>`,
      ].join("\n");
    }
    case "table": {
      counter.outN++;
      const n = counter.outN;
      return [
        `<div class="nb-cell nb-cell-output" data-cell-type="output">`,
        `  <div class="cell-prompt cell-prompt-out">Out[${n}]:</div>`,
        `  <div class="cell-content">`,
        renderBlock(block),
        `  </div>`,
        `</div>`,
      ].join("\n");
    }
    case "math": {
      counter.outN++;
      const n = counter.outN;
      return [
        `<div class="nb-cell nb-cell-output" data-cell-type="output">`,
        `  <div class="cell-prompt cell-prompt-out">Out[${n}]:</div>`,
        `  <div class="cell-content">`,
        renderBlock(block),
        `  </div>`,
        `</div>`,
      ].join("\n");
    }
    case "tree": {
      counter.outN++;
      const n = counter.outN;
      return [
        `<div class="nb-cell nb-cell-output" data-cell-type="output">`,
        `  <div class="cell-prompt cell-prompt-out">Out[${n}]:</div>`,
        `  <div class="cell-content">`,
        renderBlock(block),
        `  </div>`,
        `</div>`,
      ].join("\n");
    }
    case "subsection": {
      const tag = "h3";
      const innerCells = block.blocks
        .map((b) => renderCell(b, counter))
        .join("\n");
      return [
        `<div class="nb-cell nb-cell-markdown" data-cell-type="markdown">`,
        `  <div class="cell-prompt cell-prompt-md"></div>`,
        `  <div class="cell-content">`,
        `    <${tag} id="${esc(block.id)}">${esc(block.heading)}</${tag}>`,
        `  </div>`,
        `</div>`,
        innerCells,
      ].join("\n");
    }
    case "subsubsection": {
      const tag = "h4";
      const innerCells = block.blocks
        .map((b) => renderCell(b, counter))
        .join("\n");
      return [
        `<div class="nb-cell nb-cell-markdown" data-cell-type="markdown">`,
        `  <div class="cell-prompt cell-prompt-md"></div>`,
        `  <div class="cell-content">`,
        `    <${tag} id="${esc(block.id)}">${esc(block.heading)}</${tag}>`,
        `  </div>`,
        `</div>`,
        innerCells,
      ].join("\n");
    }
    default: {
      // paragraph, blockquote, ul, ol, hr — markdown cells
      return [
        `<div class="nb-cell nb-cell-markdown" data-cell-type="markdown">`,
        `  <div class="cell-prompt cell-prompt-md"></div>`,
        `  <div class="cell-content">`,
        renderBlock(block),
        `  </div>`,
        `</div>`,
      ].join("\n");
    }
  }
}

/** Render all blocks in a section as Jupyter cells */
function renderSectionCells(section: Section, counter: CellCounter): string {
  const headingCell = [
    `<div class="nb-cell nb-cell-markdown nb-cell-heading" data-cell-type="markdown">`,
    `  <div class="cell-prompt cell-prompt-md"></div>`,
    `  <div class="cell-content">`,
    `    <h2 id="${esc(section.id)}">${esc(section.heading)}</h2>`,
    `  </div>`,
    `</div>`,
  ].join("\n");

  const blockCells = section.blocks
    .map((b) => renderCell(b, counter))
    .join("\n");

  return [
    `<section data-section-id="${esc(section.id)}">`,
    headingCell,
    blockCells,
    `</section>`,
  ].join("\n");
}

export function buildHtml(data: ReportData): string {
  const statsStr = computeStats(data);
  const ogDesc = esc(data.subtitle ?? statsStr);
  const counter: CellCounter = { inN: 0, outN: 0 };

  /* Build sidebar nav */
  const navItems = data.nav
    .map((item) => {
      const children = item.children?.length
        ? `<ul class="nb-nav-children">${item.children
            .map(
              (c) =>
                `<li><a href="#${esc(c.id)}" class="nb-nav-link nb-nav-h3">${esc(c.text)}</a></li>`,
            )
            .join("")}</ul>`
        : "";
      return `<li><a href="#${esc(item.id)}" class="nb-nav-link nb-nav-h2">${esc(item.text)}</a>${children}</li>`;
    })
    .join("\n      ");

  /* Build notebook cells */
  const notebookCells = data.sections
    .map((s) => renderSectionCells(s, counter))
    .join("\n\n");

  const metaParts = [esc(data.generated), statsStr].filter(Boolean);
  const metaSpans = metaParts.map((m) => `<span>${m}</span>`).join(" ");

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
<link href="${JETBRAINS_MONO}" rel="stylesheet">
<link rel="stylesheet" href="${KATEX_CSS}" crossorigin="anonymous">
<script defer src="${KATEX_JS}" crossorigin="anonymous"></script>
<script defer src="${KATEX_AUTO}" crossorigin="anonymous"></script>
<link rel="stylesheet" href="./styles.css">
</head>
<body>

<!-- Jupyter toolbar -->
<div class="nb-toolbar" id="nb-toolbar">
  <div class="nb-toolbar-left">
    <div class="nb-toolbar-menu">
      <span class="nb-menu-item">File</span>
      <span class="nb-menu-item">Edit</span>
      <span class="nb-menu-item">View</span>
      <span class="nb-menu-item">Cell</span>
      <span class="nb-menu-item">Kernel</span>
      <span class="nb-menu-item">Help</span>
    </div>
    <div class="nb-toolbar-actions">
      <button class="nb-toolbar-btn" id="nb-sidebar-toggle" title="Toggle sidebar" aria-label="Toggle sidebar">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
      </button>
      <button class="nb-toolbar-btn" id="nb-save-btn" title="Download notebook HTML" aria-label="Save">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg>
      </button>
      <span class="nb-toolbar-sep"></span>
      <button class="nb-toolbar-btn cell-run-all" title="Run all cells" aria-label="Run all">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><polygon points="5,3 19,12 5,21"/></svg>
      </button>
      <button class="nb-toolbar-btn" title="Stop" aria-label="Stop">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><rect x="4" y="4" width="16" height="16" rx="2"/></svg>
      </button>
      <button class="nb-toolbar-btn" title="Restart kernel" aria-label="Restart">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 11-2.12-9.36L23 10"/></svg>
      </button>
    </div>
  </div>
  <div class="nb-toolbar-right">
    <div class="search-wrap">
      <svg class="search-icon" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round">
        <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
      </svg>
      <input type="text" id="search" placeholder="Search..." autocomplete="off" spellcheck="false">
      <span id="search-count"></span>
    </div>
    <span class="nb-kernel-status">Python 3 | Idle</span>
  </div>
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
<div id="no-results">No cells match your search.</div>

<div class="nb-layout">
  <!-- Sidebar nav -->
  <aside class="nb-sidebar" id="nb-sidebar">
    <div class="nb-sidebar-header">
      <svg width="16" height="16" viewBox="0 0 32 32" fill="none">
        <rect width="32" height="32" rx="6" fill="#f37626"/>
        <circle cx="16" cy="8" r="3" fill="#fff"/>
        <circle cx="8" cy="24" r="2.5" fill="#9e9e9e"/>
        <circle cx="24" cy="24" r="2.5" fill="#4e4e4e"/>
      </svg>
      <span>Notebook</span>
    </div>
    <nav class="nb-nav">
      <ul>
        ${navItems}
      </ul>
    </nav>
  </aside>

  <!-- Main notebook area -->
  <main class="notebook" id="notebook">
    <div class="nb-header">
      <h1>${esc(data.title)}</h1>
      ${data.subtitle ? `<p class="nb-subtitle">${esc(data.subtitle)}</p>` : ""}
      <div class="nb-meta">${metaSpans}</div>
    </div>

    <div class="nb-cells">
      ${notebookCells}
    </div>
  </main>
</div>

<script src="./report.js" defer></script>
</body>
</html>`;
}
