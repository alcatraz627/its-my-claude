import type { ReportData } from "../../generate-html.ts";
import { esc, highlight, renderBlock, renderSection, computeStats } from "../../generate-html.ts";

const FAVICON =
  "data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'><rect width='32' height='32' rx='4' fill='%230f2b46'/><rect x='5' y='12' width='22' height='14' rx='2' fill='none' stroke='%23fff' stroke-width='1.5'/><rect x='10' y='8' width='12' height='6' rx='1' fill='none' stroke='%23fff' stroke-width='1.5'/><circle cx='16' cy='19' r='2' fill='%23fff'/></svg>";

export function buildHtml(data: ReportData): string {
  const statsStr = computeStats(data);
  const ogDesc = esc(data.subtitle ?? statsStr);

  // Build numbered table of contents
  const tocEntries = data.nav
    .map((item, i) => {
      const num = i + 1;
      const children = item.children?.length
        ? `<ul class="toc-sub">${item.children
            .map(
              (c, j) =>
                `<li><a href="#${esc(c.id)}"><span class="toc-num">${num}.${j + 1}</span> ${esc(c.text)}<span class="toc-dots"></span></a></li>`
            )
            .join("")}</ul>`
        : "";
      return `<li><a href="#${esc(item.id)}"><span class="toc-num">${num}.</span> ${esc(item.text)}<span class="toc-dots"></span></a>${children}</li>`;
    })
    .join("\n      ");

  // Render numbered sections
  const numberedSections = data.sections
    .map((section, i) => {
      const num = i + 1;
      // Render blocks, numbering subsections
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
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Crimson+Pro:ital,wght@0,400;0,600;1,400&display=swap">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500&display=swap">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.css" crossorigin="anonymous">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.js" crossorigin="anonymous"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/contrib/auto-render.min.js" crossorigin="anonymous"></script>
<link rel="stylesheet" href="./styles.css">
</head>
<body data-watermark="CONFIDENTIAL">

<!-- Report -->
<div class="report">

  <!-- Header -->
  <header class="report-header">
    <h1>${esc(data.title)}</h1>
    ${data.subtitle ? `<p class="report-subtitle">${esc(data.subtitle)}</p>` : ""}
    <div class="report-meta">
      <div class="meta-row"><span class="meta-label">DATE</span><span class="meta-value">${esc(data.generated)}</span></div>
      <div class="meta-row"><span class="meta-label">CONTENTS</span><span class="meta-value">${statsStr}</span></div>
      <div class="meta-row"><span class="meta-label">PREPARED BY</span><span class="meta-value">Auto-generated report</span></div>
    </div>
  </header>

  <hr class="divider">

  <!-- Table of Contents -->
  <nav class="toc" id="toc">
    <div class="toc-header">
      <h2>Table of Contents</h2>
      <div class="toc-actions">
        <button class="toc-toggle" id="toc-toggle" aria-label="Toggle table of contents">Hide</button>
      </div>
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

  <hr class="divider">

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
