import type { ReportData } from "../../generate-html.ts";
import { esc, highlight, renderBlock, renderSection, renderNav, computeStats } from "../../generate-html.ts";

const FAVICON = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Crect x='10' y='15' width='80' height='70' rx='4' fill='%231e293b'/%3E%3Crect x='16' y='22' width='30' height='6' rx='1' fill='%23c2185b'/%3E%3Crect x='16' y='32' width='68' height='3' rx='1' fill='%23e0dcd4'/%3E%3Crect x='16' y='38' width='68' height='3' rx='1' fill='%23e0dcd4'/%3E%3Crect x='16' y='44' width='30' height='3' rx='1' fill='%23e0dcd4'/%3E%3Crect x='16' y='50' width='30' height='3' rx='1' fill='%23e0dcd4'/%3E%3Crect x='16' y='56' width='30' height='3' rx='1' fill='%23e0dcd4'/%3E%3Crect x='50' y='44' width='34' height='18' rx='2' fill='%238b2252' opacity='0.3'/%3E%3Crect x='16' y='64' width='68' height='3' rx='1' fill='%23e0dcd4'/%3E%3Crect x='16' y='70' width='50' height='3' rx='1' fill='%23e0dcd4'/%3E%3C/svg%3E";

const GOOGLE_FONTS_URL =
  "https://fonts.googleapis.com/css2?" +
  "family=Playfair+Display:ital,wght@0,400;0,700;0,900;1,400;1,700" +
  "&family=Merriweather:ital,wght@0,300;0,400;0,700;1,300;1,400" +
  "&family=Lora:ital,wght@0,400;0,700;1,400" +
  "&family=Source+Serif+4:ital,wght@0,300;0,400;0,700;1,300;1,400" +
  "&family=Crimson+Text:ital,wght@0,400;0,700;1,400" +
  "&family=Libre+Baskerville:ital,wght@0,400;0,700;1,400" +
  "&family=Source+Sans+3:wght@300;400;600;700" +
  "&family=Inter:wght@300;400;600;700" +
  "&family=IBM+Plex+Sans:wght@300;400;600;700" +
  "&family=JetBrains+Mono:wght@400;700" +
  "&family=Fira+Code:wght@400;700" +
  "&family=IBM+Plex+Mono:wght@400;700" +
  "&family=Cormorant+Garamond:ital,wght@0,400;0,700;0,900;1,400" +
  "&family=Sorts+Mill+Goudy:ital@0;1" +
  "&family=Vollkorn:ital,wght@0,400;0,700;0,900;1,400" +
  "&family=DM+Serif+Display:ital@0;1" +
  "&family=Bitter:ital,wght@0,400;0,700;0,900;1,400" +
  "&family=Lato:ital,wght@0,300;0,400;0,700;1,300;1,400" +
  "&family=PT+Serif:ital,wght@0,400;0,700;1,400" +
  "&family=Noto+Serif:ital,wght@0,300;0,400;0,700;1,300;1,400" +
  "&family=Literata:ital,wght@0,300;0,400;0,700;1,300;1,400" +
  "&family=Spectral:ital,wght@0,300;0,400;0,700;1,300;1,400" +
  "&family=Source+Code+Pro:wght@400;700" +
  "&family=Inconsolata:wght@400;700" +
  "&family=Ubuntu+Mono:wght@400;700" +
  "&family=Roboto+Mono:wght@400;700" +
  "&family=Anonymous+Pro:wght@400;700" +
  "&display=swap";

const KATEX_CSS = "https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.css";
const KATEX_JS = "https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.js";
const KATEX_AUTO = "https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/contrib/auto-render.min.js";

export function buildHtml(data: ReportData): string {
  const contentHtml = data.sections.map((section, i) => {
    const sectionBlocks = section.blocks.map(renderBlock).join("\n");
    // First section gets two-column layout and drop-cap treatment
    const wrapClass = i === 0 ? ' class="two-col"' : "";
    return [
      `<section data-section-id="${esc(section.id)}">`,
      `  <h2 id="${esc(section.id)}">${esc(section.heading)}</h2>`,
      i === 0 ? `<div class="two-col">${sectionBlocks}</div>` : sectionBlocks,
      `  <div class="ornament">&bull; &bull; &bull;</div>`,
      `</section>`,
    ].join("\n");
  }).join("\n");

  const statsStr = computeStats(data);
  const ogDesc = esc(data.subtitle ?? statsStr);
  const now = new Date();
  const qtr = `Q${Math.ceil((now.getMonth() + 1) / 3)}`;
  const issueInfo = `Report No. ${now.getFullYear()}-${qtr} &middot; ${now.toLocaleString("en-US", { month: "long" })} ${now.getFullYear()}`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=0.9">
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
<script defer src="${KATEX_JS}" crossorigin="anonymous"></script>
<script defer src="${KATEX_AUTO}" crossorigin="anonymous"></script>
<link rel="stylesheet" href="./styles.css">
</head>
<body>

<!-- Top Bar -->
<div class="top-bar">
  <div class="top-bar-left">
    <div class="search-wrap">
      <input type="text" id="search" placeholder="Search sections... (Ctrl+K)" aria-label="Search sections">
      <span id="search-count"></span>
    </div>
  </div>
  <div class="top-bar-right">
    <div class="font-picker">
      <label>
        <span class="fp-label">Heading</span>
        <select id="fp-heading">
          <option value="'Playfair Display', Georgia, serif">Playfair Display</option>
          <option value="'Lora', Georgia, serif">Lora</option>
          <option value="'Source Serif 4', Georgia, serif">Source Serif 4</option>
          <option value="'Crimson Text', Georgia, serif">Crimson Text</option>
          <option value="'Libre Baskerville', Georgia, serif">Libre Baskerville</option>
          <option value="'Cormorant Garamond', Georgia, serif">Cormorant Garamond</option>
          <option value="'Sorts Mill Goudy', Georgia, serif">Sorts Mill Goudy</option>
          <option value="'Vollkorn', Georgia, serif">Vollkorn</option>
          <option value="'DM Serif Display', Georgia, serif">DM Serif Display</option>
          <option value="'Bitter', Georgia, serif">Bitter</option>
        </select>
      </label>
      <label>
        <span class="fp-label">Body</span>
        <select id="fp-body">
          <option value="'Merriweather', Georgia, serif">Merriweather</option>
          <option value="'Lora', Georgia, serif">Lora</option>
          <option value="'Source Sans 3', sans-serif">Source Sans 3</option>
          <option value="'Inter', sans-serif">Inter</option>
          <option value="'IBM Plex Sans', sans-serif">IBM Plex Sans</option>
          <option value="'Lato', sans-serif">Lato</option>
          <option value="'PT Serif', Georgia, serif">PT Serif</option>
          <option value="'Noto Serif', Georgia, serif">Noto Serif</option>
          <option value="'Literata', Georgia, serif">Literata</option>
          <option value="'Spectral', Georgia, serif">Spectral</option>
        </select>
      </label>
      <label>
        <span class="fp-label">Code</span>
        <select id="fp-code">
          <option value="'JetBrains Mono', monospace">JetBrains Mono</option>
          <option value="'Fira Code', monospace">Fira Code</option>
          <option value="'IBM Plex Mono', monospace">IBM Plex Mono</option>
          <option value="'Source Code Pro', monospace">Source Code Pro</option>
          <option value="'Inconsolata', monospace">Inconsolata</option>
          <option value="'Ubuntu Mono', monospace">Ubuntu Mono</option>
          <option value="'Roboto Mono', monospace">Roboto Mono</option>
          <option value="'Anonymous Pro', monospace">Anonymous Pro</option>
        </select>
      </label>
    </div>
    <div class="color-picker">
      <label>
        <span class="fp-label">Theme</span>
        <select id="cp-theme">
          <option value="#8b2252">Burgundy</option>
          <option value="#1e3a5f">Navy</option>
          <option value="#2d6a4f">Forest</option>
          <option value="#7c2d82">Plum</option>
          <option value="#9c4221">Rust</option>
          <option value="#0d6a6e">Teal</option>
          <option value="#374151">Charcoal</option>
          <option value="#92400e">Gold</option>
        </select>
      </label>
    </div>
  </div>
</div>

<!-- Hero Header -->
<header class="hero">
  <h1>${esc(data.title)}</h1>
  ${data.subtitle ? `<p class="subtitle">${esc(data.subtitle)}</p>` : ""}
  <p class="report-stats">${statsStr}</p>
  <p class="issue-info">${issueInfo}</p>
</header>

<main class="content">
  ${contentHtml}

  <!-- Footnote Metadata -->
  <footer class="footnotes">
    <span>Generated: ${esc(data.generated)}</span>
    <span>${statsStr}</span>
  </footer>
</main>

<div id="no-results">No sections match your search.</div>

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
