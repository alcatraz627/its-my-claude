import type { ReportData } from "../../generate-html.ts";
import {
  esc,
  renderBlock,
  computeStats,
  highlight,
} from "../../generate-html.ts";

const FAVICON =
  "data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'><rect width='32' height='32' rx='2' fill='%23f5f5f0'/><rect x='4' y='3' width='24' height='26' rx='1' fill='none' stroke='%23333' stroke-width='1.2'/><line x1='8' y1='8' x2='24' y2='8' stroke='%23333' stroke-width='1'/><line x1='8' y1='12' x2='24' y2='12' stroke='%23999' stroke-width='0.6'/><line x1='8' y1='15' x2='24' y2='15' stroke='%23999' stroke-width='0.6'/><line x1='8' y1='18' x2='24' y2='18' stroke='%23999' stroke-width='0.6'/><line x1='8' y1='21' x2='20' y2='21' stroke='%23999' stroke-width='0.6'/></svg>";

export function buildHtml(data: ReportData): string {
  const statsStr = computeStats(data);
  const ogDesc = esc(data.subtitle ?? statsStr);

  // Build numbered table of contents (two-column layout)
  const tocEntries = data.nav
    .map((item, i) => {
      const num = i + 1;
      const children = item.children?.length
        ? `<ul class="toc-sub">${item.children
            .map(
              (c, j) =>
                `<li><a href="#${esc(c.id)}"><span class="toc-num">${num}.${j + 1}</span> ${esc(c.text)}</a></li>`,
            )
            .join("")}</ul>`
        : "";
      return `<li><a href="#${esc(item.id)}"><span class="toc-num">${num}.</span> ${esc(item.text)}</a>${children}</li>`;
    })
    .join("\n      ");

  // Render numbered sections
  const numberedSections = data.sections
    .map((section, i) => {
      const num = i + 1;
      let subIdx = 0;
      const blocksHtml = section.blocks
        .map((block) => {
          if (block.type === "subsection") {
            subIdx++;
            const subNum = `${num}.${subIdx}`;
            return `<h3 id="${esc(block.id)}"><span class="section-num">${subNum}</span> ${esc(block.heading)}</h3>${block.blocks.map(renderBlock).join("\n")}`;
          }
          return renderBlock(block);
        })
        .join("\n");

      return `<section class="report-section" data-section-id="${esc(section.id)}">
  <h2 id="${esc(section.id)}"><span class="section-num">${num}.</span> ${esc(section.heading)}</h2>
${blocksHtml}
</section>`;
    })
    .join("\n\n  ");

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
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Crimson+Pro:ital,wght@0,400;0,600;0,700;1,400&family=JetBrains+Mono:wght@400;500&display=swap">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.css" crossorigin="anonymous">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.js" crossorigin="anonymous"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/contrib/auto-render.min.js" crossorigin="anonymous"></script>
<link rel="stylesheet" href="./styles.css">
</head>
<body>

<!-- Running header -->
<div class="running-header">
  <span class="running-title">${esc(data.title)}</span>
  <span class="running-section"></span>
</div>

<!-- Paper -->
<div class="paper">

  <!-- Title block -->
  <header class="paper-header">
    <h1 class="paper-title">${esc(data.title)}</h1>
    <div class="paper-meta">
      <span class="paper-date">${esc(data.generated)}</span>
      <span class="paper-stats">${statsStr}</span>
    </div>
  </header>

  ${
    data.subtitle
      ? `<!-- Abstract -->
  <div class="abstract">
    <h2 class="abstract-heading">Abstract</h2>
    <p class="abstract-text">${esc(data.subtitle)}</p>
  </div>`
      : ""
  }

  <hr class="rule">

  <!-- Table of Contents -->
  <nav class="toc" id="toc">
    <div class="toc-header">
      <h2>Contents</h2>
      <button class="toc-toggle" id="toc-toggle" aria-label="Toggle table of contents">Hide</button>
    </div>
    <div class="search-wrap">
      <input type="text" id="search" placeholder="Search report... (Ctrl+K)" aria-label="Search report">
      <span id="search-count"></span>
    </div>
    <ul class="toc-list" id="toc-list">
      ${tocEntries}
    </ul>
  </nav>

  <div id="no-results" style="display:none;">No matching sections found.</div>

  <hr class="rule">

  <!-- Sections -->
  ${numberedSections}

</div>

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

<script src="./report.js" defer></script>
</body>
</html>`;
}
