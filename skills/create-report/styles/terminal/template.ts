import type { ReportData, Section, Block, TableBlock, CodeBlock, ListBlock, BlockquoteBlock, SubsectionBlock, SubSubsectionBlock, TreeBlock, TreeNode, MathBlock } from "../../generate-html.ts";
import { esc, highlight, computeStats } from "../../generate-html.ts";

const FAVICON = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='4' fill='%23000'/%3E%3Ctext x='3' y='24' font-family='monospace' font-size='22' font-weight='bold' fill='%2333ff33'%3E%3E_%3C/text%3E%3C/svg%3E";

const GOOGLE_FONTS_URL =
  "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&display=swap";

const KATEX_CSS = "https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.css";
const KATEX_JS = "https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.js";
const KATEX_AUTO = "https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/contrib/auto-render.min.js";

// ─── Terminal-specific block rendering ───────────────────────────────────────

/** Render an ASCII-art table with | and - borders, plus status coloring. */
function renderTermTable(block: TableBlock): string {
  const cols = block.headers.length;
  // Compute column widths (max of header and all row cells)
  const widths: number[] = [];
  for (let c = 0; c < cols; c++) {
    let max = stripHtml(block.headers[c]).length;
    for (const row of block.rows) {
      const cell = row[c] ?? "";
      max = Math.max(max, stripHtml(cell).length);
    }
    widths.push(max + 2); // padding
  }

  const sep = "+" + widths.map((w) => "-".repeat(w + 2)).join("+") + "+";
  const fmtRow = (cells: string[]) =>
    "| " +
    cells
      .map((cell, i) => {
        const plain = stripHtml(cell);
        const pad = widths[i] - plain.length;
        return " " + colorizeStatus(cell) + " ".repeat(Math.max(pad, 0)) + " ";
      })
      .join("| ") +
    "|";

  const lines = [
    sep,
    fmtRow(block.headers),
    sep,
    ...block.rows.map((r) => fmtRow(r)),
    sep,
  ];

  return `<div class="ascii-table"><pre>${lines.join("\n")}</pre></div>`;
}

/** Strip HTML tags for width calculation. */
function stripHtml(s: string): string {
  return s.replace(/<[^>]*>/g, "").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"');
}

/** Colorize [OK], [WARN], [FAIL] status indicators. */
function colorizeStatus(s: string): string {
  return s
    .replace(/\[OK\]/g, '<span class="status-ok">[OK]</span>')
    .replace(/\[WARN\]/g, '<span class="status-warn">[WARN]</span>')
    .replace(/\[FAIL\]/g, '<span class="status-fail">[FAIL]</span>');
}

/** Render a code block with terminal styling. */
function renderTermCode(block: CodeBlock): string {
  const lang = esc(block.lang) || "text";
  const label = block.lang ? `// ${lang}` : "";
  return [
    `<div class="code-block">`,
    label ? `  <div class="code-label">${label}</div>` : "",
    `  <pre><code>${highlight(block.content, block.lang)}</code></pre>`,
    `</div>`,
  ]
    .filter(Boolean)
    .join("\n");
}

/** Render a list with terminal-style dashes. */
function renderTermList(block: ListBlock): string {
  const items = block.items
    .map((item) => {
      const colored = colorizeStatus(item);
      return `<div class="term-list-item">- ${colored}</div>`;
    })
    .join("\n");
  return `<div class="term-list">${items}</div>`;
}

/** Render a blockquote with terminal > prefix. */
function renderTermBlockquote(block: BlockquoteBlock): string {
  // Split the html by <br> or newlines and prefix each with >
  const lines = block.html.split(/<br\s*\/?>|\n/).map((l) => `> ${l}`);
  return `<div class="blockquote">${lines.join("<br>")}</div>`;
}

/** Render tree nodes with ASCII art connectors. */
function renderTermTreeNode(node: TreeNode, prefix: string, isLast: boolean): string {
  const connector = isLast ? "\\-- " : "|-- ";
  const childPrefix = prefix + (isLast ? "    " : "|   ");
  const label = esc(node.label);
  const desc = node.desc ? ` <span class="tree-desc">${esc(node.desc)}</span>` : "";
  let result = `${prefix}${connector}${label}${desc}\n`;
  if (node.children) {
    node.children.forEach((child, i) => {
      result += renderTermTreeNode(child, childPrefix, i === node.children!.length - 1);
    });
  }
  return result;
}

/** Render a tree block as ASCII art. */
function renderTermTree(block: TreeBlock): string {
  let content = "";
  block.nodes.forEach((node, i) => {
    content += renderTermTreeNode(node, "", i === block.nodes.length - 1);
  });
  return `<div class="code-block"><pre>${content}</pre></div>`;
}

/** Render a single block in terminal style. */
function renderTermBlock(block: Block): string {
  switch (block.type) {
    case "paragraph":
      return `<p>${colorizeStatus(block.html)}</p>`;
    case "hr":
      return `<div class="term-hr">────────────────────────────────────────────────</div>`;
    case "blockquote":
      return renderTermBlockquote(block);
    case "ul":
    case "ol":
      return renderTermList(block);
    case "code":
      return renderTermCode(block);
    case "table":
      return renderTermTable(block);
    case "subsection":
    case "subsubsection": {
      const prefix = block.type === "subsection" ? "--- " : "-- ";
      const suffix = block.type === "subsection" ? " ---" : " --";
      return `<div class="subsection-header">${prefix}${esc(block.heading)}${suffix}</div>\n${block.blocks.map(renderTermBlock).join("\n")}`;
    }
    case "tree":
      return renderTermTree(block);
    case "math":
      return block.display !== false
        ? `<div class="math-block">$$${block.latex}$$</div>`
        : `<span class="math-inline">$${block.latex}$</span>`;
  }
}

/** Render a full section in terminal style. */
function renderTermSection(section: Section, index: number): string {
  const num = String(index + 1).padStart(2, "0");
  return [
    `<div class="section" id="${esc(section.id)}">`,
    `  <div class="section-header">=== [${num}] ${esc(section.heading)} ===</div>`,
    section.blocks.map(renderTermBlock).join("\n"),
    `</div>`,
  ].join("\n");
}

// ─── Main buildHtml ──────────────────────────────────────────────────────────

export function buildHtml(data: ReportData): string {
  const statsStr = computeStats(data);
  const ogDesc = esc(data.subtitle ?? statsStr);

  // Build navigation links with [01] [02] prefix
  const navLinks = data.nav
    .map((item, i) => {
      const num = String(i + 1).padStart(2, "0");
      return `<a href="#${esc(item.id)}">[${num}] ${esc(item.text)}</a>`;
    })
    .join("\n        ");

  // Build sections
  const sections = data.sections
    .map((section, i) => renderTermSection(section, i))
    .join("\n\n    ");

  // Calculate typing animation width based on title length
  const titleLen = data.title.length;

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
<style>
  .report-title {
    animation: typing 2.4s steps(${titleLen}, end) 0.5s forwards;
  }
  @keyframes typing {
    from { width: 0; }
    to { width: ${titleLen}ch; }
  }
</style>
</head>
<body data-theme="matrix">

<div class="terminal-window">
  <!-- Title bar -->
  <div class="title-bar">
    <span class="dot close"></span>
    <span class="dot minimize"></span>
    <span class="dot maximize"></span>
    <span class="title-text">report.sh &mdash; bash &mdash; <span class="title-res">80x40</span></span>
    <div class="title-bar-right">
      <div class="width-picker">
        <button class="width-btn" data-width="sm">[SM]</button>
        <button class="width-btn" data-width="md">[MD]</button>
        <button class="width-btn" data-width="lg">[LG]</button>
        <button class="width-btn" data-width="xl">[XL]</button>
      </div>
      <select id="theme-select" class="theme-select" title="Terminal color theme">
        <option value="matrix">Matrix Green</option>
        <option value="amber">Amber CRT</option>
        <option value="dracula">Dracula Purple</option>
        <option value="solarized">Solarized</option>
        <option value="nord">Nord Blue</option>
        <option value="monokai">Monokai</option>
        <option value="gruvbox">Gruvbox</option>
        <option value="catppuccin">Catppuccin</option>
        <option value="tokyonight">Tokyo Night</option>
        <option value="onedark">One Dark</option>
        <option value="cyberpunk">Cyberpunk</option>
        <option value="phosphor">Phosphor</option>
        <option value="ibm3278">IBM 3278</option>
        <option value="sunset">Sunset</option>
        <option value="ice">Ice</option>
        <option value="paper">Paper (Light)</option>
      </select>
    </div>
  </div>

  <div class="terminal-body content">
    <!-- Title with typing animation -->
    <div style="display:flex;align-items:baseline;">
      <div class="report-title">${esc(data.title)}</div><span class="cursor">&#x2588;</span>
    </div>
    ${data.subtitle ? `<div class="subtitle">&gt; ${esc(data.subtitle)}</div>` : ""}
    <div class="system-stats">[sys] ${esc(statsStr)}</div>

    <!-- Search -->
    <div class="search-bar">
      <label class="search-label" for="search">grep:</label>
      <input type="text" id="search" class="search-input" placeholder="pattern..." autocomplete="off" spellcheck="false">
      <span id="search-count" class="search-count"></span>
    </div>

    <!-- Navigation -->
    <nav class="nav">
      <div class="prompt">&gt; ls sections/</div>
      <div class="nav-links">
        ${navLinks}
      </div>
    </nav>

    <!-- No results -->
    <div id="no-results" class="no-results" style="display:none;">
      <pre>grep: no matches found</pre>
    </div>

    <!-- Sections -->
    ${sections}

  </div><!-- .content -->
</div><!-- .terminal-window -->

<script src="./report.js" defer></script>
</body>
</html>`;
}
