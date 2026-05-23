/// <reference types="node" />
/**
 * generate-table.ts
 * Generates a fully self-contained interactive HTML table page from structured JSON data.
 * All CSS, JS, and data are inlined — no external dependencies, no server required.
 *
 * Usage:
 *   npx tsx .claude/skills/create-report/table/generate-table.ts \
 *     <data_json_path> <output_html_path> [flags...]
 *
 * ─── INPUT FORMAT ─────────────────────────────────────────────────────────────
 *
 *   {
 *     "headers": ["Col1", "Col2", ...],
 *     "rows": [["val1", "val2", ...], ...],
 *     "meta": { "source": "filename.csv", "count": 100 }   ← optional
 *   }
 *
 * ─── FLAGS ────────────────────────────────────────────────────────────────────
 *
 *   --title "My Table"
 *       Page heading. Default: derived from meta.source, or "Data Table".
 *
 *   --theme dark|light
 *       Color scheme. Default: dark.
 *
 *   --columns "Col1,Col2,Col3"
 *       Comma-separated subset of columns to display. Default: all columns.
 *
 *   --sort-by "ColName:asc"  |  --sort-by "ColName:desc"
 *       Default sort on load. Default: original row order.
 *
 *   --search
 *       Enable a live search bar filtering across all visible columns.
 *
 *   --pagination N
 *       Rows per page with first/prev/next/last navigation. 0 = no pagination. Default: 0.
 *
 *   --export csv          Add "↓ Export CSV" button.
 *   --export json         Add "↓ Export JSON" button.
 *   --export both         Add both CSV and JSON export buttons.
 *
 *   --highlight-rules '[...]'
 *       JSON array of row highlight rules. Each rule:
 *         { "column": "Status", "value": "Error", "color": "red" }
 *         { "column": "Score", "operator": "lt", "value": "50", "color": "yellow" }
 *       Operators: eq (default) | not | lt | gt | lte | gte | contains | startsWith | endsWith
 *       Named colors: red | yellow | green | blue | purple | orange | cyan | pink
 *       Custom color: any CSS color string, e.g. "#ff4444" or "rgba(255,100,0,0.2)"
 *
 *   --frozen-columns N
 *       Freeze the first N columns (sticky left on horizontal scroll). Default: 0.
 *
 *   --column-types '{"Col":"type"}'
 *       JSON object mapping column names to display types:
 *         "text"    — plain left-aligned text (default)
 *         "number"  — right-align, apply --number-format
 *         "date"    — format via --date-format
 *         "boolean" — render as ✓ or ✗ icon
 *         "badge"   — colored pill, color auto-assigned by value hash
 *         "url"     — clickable link (<a href>)
 *         "email"   — mailto: link
 *         "code"    — monospace pre-formatted text
 *
 *   --number-format "pattern"
 *       Supported patterns:
 *         "0,0"      — integer with thousands separator (1,234)
 *         "0,0.00"   — fixed 2 decimal places (1,234.56)
 *         "0,0.##"   — up to 2 decimals, trailing zeros stripped (1,234.5)
 *         "0%"       — percentage (45%)
 *         "0.00%"    — percentage with 2 decimals (45.67%)
 *         "$0,0.00"  — currency prefix ($ 1,234.56)
 *       Default: raw value.
 *
 *   --date-format "YYYY-MM-DD"
 *       Date display format. Tokens: YYYY YY MM M DD D HH H mm ss.
 *       Default: "YYYY-MM-DD".
 *
 *   --striped
 *       Alternating row background colors.
 *
 *   --compact
 *       Reduced row height and font size for dense data.
 *
 *   --caption "Caption text"
 *       Subtitle displayed below the main heading.
 *
 *   --column-widths '{"ColName":"120px","Other":"20%"}'
 *       JSON object of per-column CSS width values.
 *
 *   --max-cell-width "320px"
 *       Maximum width for any cell before text is truncated with ellipsis. Default: 400px.
 *
 *   --row-numbers
 *       Add a leading "#" column showing the original row index.
 *
 * ─── ADDING NEW FLAGS ─────────────────────────────────────────────────────────
 *
 *   When the agent needs a feature not yet here:
 *   1. Add the flag to the parseArgs() function
 *   2. Add the flag type to TableConfig interface
 *   3. Implement the rendering logic in generateHtml() or the embedded JS
 *   4. Document the new flag in this header comment
 *
 * ─── EXAMPLES ─────────────────────────────────────────────────────────────────
 *
 *   Basic with search and pagination:
 *     npx tsx generate-table.ts data.json out.html --title "Sales" --search --pagination 25
 *
 *   With types, highlighting, export:
 *     npx tsx generate-table.ts data.json out.html \
 *       --column-types '{"Amount":"number","Date":"date","Active":"boolean","Status":"badge"}' \
 *       --number-format "$0,0.00" \
 *       --highlight-rules '[{"column":"Status","value":"Error","color":"red"},{"column":"Active","value":"false","color":"yellow"}]' \
 *       --export both --search --striped
 *
 *   Frozen columns with subset:
 *     npx tsx generate-table.ts data.json out.html \
 *       --columns "ID,Name,Status,Score" \
 *       --frozen-columns 2 \
 *       --sort-by "Score:desc" \
 *       --theme light --compact
 */

import { readFileSync, writeFileSync, mkdirSync } from "fs";
import { dirname, resolve } from "path";

// ─── Types ────────────────────────────────────────────────────────────────────

interface TableData {
  headers: string[];
  rows: string[][];
  meta?: { source?: string; count?: number; title?: string };
}

type ColType = "text" | "number" | "date" | "boolean" | "badge" | "url" | "email" | "code";
type ExportMode = "csv" | "json" | "both";

interface HighlightRule {
  column: string;
  value?: string;
  operator?: "eq" | "not" | "lt" | "gt" | "lte" | "gte" | "contains" | "startsWith" | "endsWith";
  color: string;
}

interface TableConfig {
  title: string;
  theme: "dark" | "light";
  columns?: string[];
  sortBy?: { column: string; dir: "asc" | "desc" };
  search: boolean;
  pagination: number;
  export?: ExportMode;
  highlightRules: HighlightRule[];
  frozenColumns: number;
  columnTypes: Record<string, ColType>;
  numberFormat?: string;
  dateFormat: string;
  striped: boolean;
  compact: boolean;
  caption?: string;
  columnWidths: Record<string, string>;
  maxCellWidth: string;
  rowNumbers: boolean;
}

// ─── CLI Parsing ──────────────────────────────────────────────────────────────

function parseArgs(): { dataPath: string; outputPath: string; config: TableConfig } {
  const args = process.argv.slice(2);
  if (args.length < 2) {
    console.error("Usage: npx tsx generate-table.ts <data.json> <output.html> [flags]");
    process.exit(1);
  }

  const dataPath = args[0];
  const outputPath = args[1];
  const flags = args.slice(2);

  const get = (flag: string): string | undefined => {
    const idx = flags.indexOf(flag);
    return idx === -1 ? undefined : flags[idx + 1];
  };
  const has = (flag: string): boolean => flags.includes(flag);

  function parseJson<T>(flag: string, raw: string | undefined): T {
    if (!raw) return {} as T;
    try {
      return JSON.parse(raw) as T;
    } catch {
      console.error(`${flag}: invalid JSON — ${raw}`);
      process.exit(1);
    }
  }

  function parseSortBy(raw: string | undefined): { column: string; dir: "asc" | "desc" } | undefined {
    if (!raw) return undefined;
    const colonIdx = raw.lastIndexOf(":");
    if (colonIdx === -1) return { column: raw.trim(), dir: "asc" };
    return {
      column: raw.slice(0, colonIdx).trim(),
      dir: (raw.slice(colonIdx + 1).trim() as "asc" | "desc") || "asc",
    };
  }

  const config: TableConfig = {
    title: get("--title") || "",
    theme: (get("--theme") as "dark" | "light") || "dark",
    columns: get("--columns")
      ?.split(",")
      .map((c) => c.trim())
      .filter(Boolean),
    sortBy: parseSortBy(get("--sort-by")),
    search: has("--search"),
    pagination: Math.max(0, parseInt(get("--pagination") || "0", 10)),
    export: (get("--export") as ExportMode) || undefined,
    highlightRules: parseJson<HighlightRule[]>(
      "--highlight-rules",
      get("--highlight-rules")
    ) as HighlightRule[],
    frozenColumns: Math.max(0, parseInt(get("--frozen-columns") || "0", 10)),
    columnTypes: parseJson<Record<string, ColType>>("--column-types", get("--column-types")),
    numberFormat: get("--number-format"),
    dateFormat: get("--date-format") || "YYYY-MM-DD",
    striped: has("--striped"),
    compact: has("--compact"),
    caption: get("--caption"),
    columnWidths: parseJson<Record<string, string>>("--column-widths", get("--column-widths")),
    maxCellWidth: get("--max-cell-width") || "400px",
    rowNumbers: has("--row-numbers"),
  };

  // Normalize highlight rules array (might come as {} if empty JSON)
  if (!Array.isArray(config.highlightRules)) config.highlightRules = [];

  return { dataPath, outputPath, config };
}

// ─── Validation ───────────────────────────────────────────────────────────────

function validateData(data: TableData): void {
  if (!data || typeof data !== "object") {
    console.error("Data JSON must be an object");
    process.exit(1);
  }
  if (!Array.isArray(data.headers) || data.headers.length === 0) {
    console.error('Data JSON must have a non-empty "headers" array');
    process.exit(1);
  }
  if (!Array.isArray(data.rows)) {
    console.error('Data JSON must have a "rows" array');
    process.exit(1);
  }
}

// ─── Escape helper (server-side, for embedding into HTML attributes) ───────────

function esc(s: string): string {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// ─── HTML Generation ──────────────────────────────────────────────────────────

function generateHtml(data: TableData, config: TableConfig): string {
  const allHeaders = data.headers;

  // Resolve visible columns
  const visibleHeaders =
    config.columns && config.columns.length > 0
      ? config.columns.filter((c) => allHeaders.includes(c))
      : [...allHeaders];

  const colIndices = visibleHeaders.map((h) => allHeaders.indexOf(h));

  // Derive title
  const title =
    config.title ||
    data.meta?.title ||
    (data.meta?.source
      ? data.meta.source.replace(/\.[^.]+$/, "").replace(/[-_]/g, " ")
      : "Data Table");

  const frozenCount = Math.min(config.frozenColumns, visibleHeaders.length);

  // Build the embedded config for client-side JS (include everything the JS needs)
  const embedConfig = {
    title,
    theme: config.theme,
    visibleHeaders,
    colIndices,
    allHeaders,
    sortBy: config.sortBy || null,
    search: config.search,
    pagination: config.pagination,
    export: config.export || null,
    highlightRules: config.highlightRules,
    frozenCount,
    columnTypes: config.columnTypes,
    numberFormat: config.numberFormat || null,
    dateFormat: config.dateFormat,
    striped: config.striped,
    compact: config.compact,
    maxCellWidth: config.maxCellWidth,
    columnWidths: config.columnWidths,
    rowNumbers: config.rowNumbers,
  };

  const rowCount = data.rows.length;
  const colCount = visibleHeaders.length;

  const hasToolbar = config.search || !!config.export;

  return `<!DOCTYPE html>
<html lang="en" data-theme="${config.theme}">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${esc(title)}</title>
<style>
${generateCSS(config, frozenCount)}
</style>
</head>
<body>
<div class="page">
  <header class="page-header">
    <div class="header-left">
      <h1 class="page-title">${esc(title)}</h1>
      ${config.caption ? `<p class="caption">${esc(config.caption)}</p>` : ""}
    </div>
    <div class="header-meta">
      <span class="meta-badge">${rowCount.toLocaleString()} rows</span>
      <span class="meta-badge">${colCount} col${colCount !== 1 ? "s" : ""}</span>
      ${data.meta?.source ? `<span class="meta-source">${esc(data.meta.source)}</span>` : ""}
    </div>
  </header>

  ${
    hasToolbar
      ? `<div class="toolbar">
    ${config.search ? `<div class="search-wrap"><svg class="search-icon" viewBox="0 0 20 20" fill="none"><circle cx="8.5" cy="8.5" r="5" stroke="currentColor" stroke-width="1.5"/><path d="M13 13l3.5 3.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg><input type="search" id="search-input" placeholder="Search all columns…" autocomplete="off" spellcheck="false"></div>` : `<div></div>`}
    <div class="toolbar-actions">
      ${config.export === "csv" || config.export === "both" ? `<button class="btn" id="export-csv"><svg viewBox="0 0 16 16" fill="none"><path d="M8 2v8m0 0L5 7m3 3l3-3" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M3 11v2a1 1 0 001 1h8a1 1 0 001-1v-2" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>Export CSV</button>` : ""}
      ${config.export === "json" || config.export === "both" ? `<button class="btn" id="export-json"><svg viewBox="0 0 16 16" fill="none"><path d="M8 2v8m0 0L5 7m3 3l3-3" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M3 11v2a1 1 0 001 1h8a1 1 0 001-1v-2" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>Export JSON</button>` : ""}
    </div>
  </div>`
      : ""
  }

  <div class="table-scroll-wrap" id="table-wrap">
    <table id="main-table"${config.striped ? ' class="striped"' : ""}${config.compact ? ' class="compact"' : ""}>
      <thead>
        <tr>
          ${config.rowNumbers ? `<th class="th-rownum col-rn" data-no-sort>#</th>` : ""}
          ${visibleHeaders
            .map((h, i) => {
              const isFrozen = i < frozenCount;
              const colType = config.columnTypes[h] || "text";
              const isNumeric = colType === "number";
              const widthStyle = config.columnWidths[h]
                ? `min-width:${config.columnWidths[h]};max-width:${config.columnWidths[h]};`
                : "";
              return `<th class="sortable${isFrozen ? " frozen" : ""}" data-col="${i}" data-key="${esc(h)}" data-type="${colType}"${widthStyle ? ` style="${widthStyle}"` : ""}>${esc(h)}<span class="sort-icon" aria-hidden="true"></span></th>`;
            })
            .join("\n          ")}
        </tr>
      </thead>
      <tbody id="tbody"></tbody>
    </table>
  </div>

  <div class="table-footer">
    ${
      config.pagination > 0
        ? `<div class="pagination-bar" id="pagination-bar">
      <button class="btn btn-sm" id="first-btn" title="First page">«</button>
      <button class="btn btn-sm" id="prev-btn" title="Previous page">‹</button>
      <span class="page-info" id="page-info"></span>
      <button class="btn btn-sm" id="next-btn" title="Next page">›</button>
      <button class="btn btn-sm" id="last-btn" title="Last page">»</button>
    </div>`
        : `<div></div>`
    }
    <div class="row-count-wrap"><span class="row-count" id="row-count"></span></div>
  </div>
</div>

<script>
(function () {
'use strict';

// ─── Embedded config and data ──────────────────────────────────────────────
const C = ${JSON.stringify(embedConfig)};
const D = ${JSON.stringify({ headers: data.headers, rows: data.rows })};

// ─── State ────────────────────────────────────────────────────────────────
let sortCol = C.sortBy ? C.sortBy.column : null;
let sortDir = C.sortBy ? C.sortBy.dir : 'asc';
let query   = '';
let page    = 0;

// ─── Helpers ──────────────────────────────────────────────────────────────
function esc(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function formatNumber(v, fmt) {
  const n = parseFloat(String(v).replace(/[^0-9.-]/g, ''));
  if (isNaN(n) || !fmt) return v;
  let prefix = '', suffix = '', num = n, pattern = fmt;
  if (pattern.startsWith('$')) { prefix = '$'; pattern = pattern.slice(1); }
  if (pattern.endsWith('%')) { suffix = '%'; pattern = pattern.slice(0, -1); num = num * 100; }
  const dotIdx = pattern.indexOf('.');
  let decimals = 0, trimZeros = false;
  if (dotIdx !== -1) {
    const dec = pattern.slice(dotIdx + 1);
    decimals = dec.length;
    trimZeros = dec.includes('#');
  }
  const useCommas = pattern.includes(',');
  let result = trimZeros
    ? parseFloat(num.toFixed(decimals)).toString()
    : num.toFixed(decimals);
  if (useCommas) {
    const parts = result.split('.');
    parts[0] = parts[0].replace(/\\B(?=(\\d{3})+(?!\\d))/g, ',');
    result = parts.join('.');
  }
  return prefix + result + suffix;
}

function formatDate(v, fmt) {
  if (!v || v === 'null') return '';
  const d = new Date(v);
  if (isNaN(d.getTime())) return String(v);
  const p = n => String(n).padStart(2, '0');
  return fmt
    .replace('YYYY', d.getFullYear()).replace('YY', String(d.getFullYear()).slice(-2))
    .replace('MM', p(d.getMonth() + 1)).replace('M', d.getMonth() + 1)
    .replace('DD', p(d.getDate())).replace('D', d.getDate())
    .replace('HH', p(d.getHours())).replace('H', d.getHours())
    .replace('mm', p(d.getMinutes())).replace('ss', p(d.getSeconds()));
}

const BADGE_PALETTE = [
  '#6366f1','#8b5cf6','#ec4899','#f43f5e','#f97316',
  '#eab308','#22c55e','#06b6d4','#3b82f6','#a855f7'
];
function badgeColor(v) {
  let h = 0;
  for (let i = 0; i < v.length; i++) h = Math.imul(31, h) + v.charCodeAt(i) | 0;
  return BADGE_PALETTE[Math.abs(h) % BADGE_PALETTE.length];
}

function formatCell(rawVal, colName) {
  const type = C.columnTypes[colName] || 'text';
  const v = String(rawVal == null ? '' : rawVal);
  switch (type) {
    case 'number':  return esc(formatNumber(v, C.numberFormat));
    case 'date':    return esc(formatDate(v, C.dateFormat));
    case 'boolean': {
      const truthy = v && v !== '0' && v.toLowerCase() !== 'false' && v !== '';
      return truthy ? '<span class="bool-true">✓</span>' : '<span class="bool-false">✗</span>';
    }
    case 'badge': {
      const color = badgeColor(v);
      return \`<span class="badge" style="background:\${color}20;color:\${color};border:1px solid \${color}40">\${esc(v)}</span>\`;
    }
    case 'url':   return v ? \`<a href="\${esc(v)}" target="_blank" rel="noopener noreferrer">\${esc(v)}</a>\` : '';
    case 'email': return v ? \`<a href="mailto:\${esc(v)}">\${esc(v)}</a>\` : '';
    case 'code':  return \`<code>\${esc(v)}</code>\`;
    default:      return esc(v);
  }
}

const HIGHLIGHT_MAP = {
  red:    'rgba(239,68,68,0.15)', yellow: 'rgba(234,179,8,0.15)',
  green:  'rgba(34,197,94,0.15)', blue:   'rgba(59,130,246,0.15)',
  purple: 'rgba(168,85,247,0.15)', orange: 'rgba(249,115,22,0.15)',
  cyan:   'rgba(6,182,212,0.15)', pink:   'rgba(236,72,153,0.15)',
};
function highlightBg(row) {
  for (const rule of C.highlightRules) {
    const si = D.headers.indexOf(rule.column);
    if (si === -1) continue;
    const cv = String(row[si] == null ? '');
    const rv = String(rule.value == null ? '');
    const op = rule.operator || 'eq';
    let match = false;
    if (op === 'eq')         match = cv.toLowerCase() === rv.toLowerCase();
    else if (op === 'not')   match = cv.toLowerCase() !== rv.toLowerCase();
    else if (op === 'lt')    match = parseFloat(cv) < parseFloat(rv);
    else if (op === 'gt')    match = parseFloat(cv) > parseFloat(rv);
    else if (op === 'lte')   match = parseFloat(cv) <= parseFloat(rv);
    else if (op === 'gte')   match = parseFloat(cv) >= parseFloat(rv);
    else if (op === 'contains')   match = cv.toLowerCase().includes(rv.toLowerCase());
    else if (op === 'startsWith') match = cv.toLowerCase().startsWith(rv.toLowerCase());
    else if (op === 'endsWith')   match = cv.toLowerCase().endsWith(rv.toLowerCase());
    if (match) return HIGHLIGHT_MAP[rule.color] || rule.color;
  }
  return null;
}

// ─── Data pipeline ────────────────────────────────────────────────────────
function sortedRows() {
  if (!sortCol) return [...D.rows];
  const si = D.headers.indexOf(sortCol);
  if (si === -1) return [...D.rows];
  const type = C.columnTypes[sortCol] || 'text';
  return [...D.rows].sort((a, b) => {
    let av = a[si] ?? '', bv = b[si] ?? '';
    if (type === 'number') {
      av = parseFloat(String(av).replace(/[^0-9.-]/g, '')) || 0;
      bv = parseFloat(String(bv).replace(/[^0-9.-]/g, '')) || 0;
      return sortDir === 'asc' ? av - bv : bv - av;
    }
    if (type === 'date') {
      av = new Date(String(av)).getTime() || 0;
      bv = new Date(String(bv)).getTime() || 0;
      return sortDir === 'asc' ? av - bv : bv - av;
    }
    av = String(av).toLowerCase(); bv = String(bv).toLowerCase();
    return sortDir === 'asc' ? (av < bv ? -1 : av > bv ? 1 : 0) : (bv < av ? -1 : bv > av ? 1 : 0);
  });
}

function filteredRows(rows) {
  if (!query) return rows;
  const q = query.toLowerCase();
  return rows.filter(row =>
    C.colIndices.some(i => String(row[i] ?? '').toLowerCase().includes(q))
  );
}

// ─── Rendering ────────────────────────────────────────────────────────────
function renderTable() {
  const tbody = document.getElementById('tbody');
  const all = filteredRows(sortedRows());
  const perPage = C.pagination;
  const pageRows = perPage > 0 ? all.slice(page * perPage, (page + 1) * perPage) : all;

  tbody.innerHTML = pageRows.map((row, ri) => {
    const bg = highlightBg(row);
    const style = bg ? \` style="background:\${bg}"\` : '';
    const cells = C.visibleHeaders.map((h, ci) => {
      const srcIdx = C.colIndices[ci];
      const val = row[srcIdx] ?? '';
      const type = C.columnTypes[h] || 'text';
      const frozen = ci < C.frozenCount ? ' frozen' : '';
      const align = type === 'number' ? 'right' : 'left';
      return \`<td class="td\${frozen}" style="text-align:\${align}">\${formatCell(val, h)}</td>\`;
    }).join('');
    const rnCell = C.rowNumbers ? \`<td class="td-rn td">\${(perPage > 0 ? page * perPage : 0) + ri + 1}</td>\` : '';
    return \`<tr\${style}>\${rnCell}\${cells}</tr>\`;
  }).join('');

  updateSortIcons();
  updatePagination(all.length);
  updateRowCount(all.length, pageRows.length, D.rows.length);

  if (C.frozenCount > 0) applyFrozenOffsets();
}

function updateSortIcons() {
  document.querySelectorAll('#main-table th.sortable').forEach(th => {
    const key = th.dataset.key;
    const icon = th.querySelector('.sort-icon');
    if (!icon) return;
    if (key === sortCol) {
      icon.textContent = sortDir === 'asc' ? '↑' : '↓';
      th.classList.add('sorted');
    } else {
      icon.textContent = '';
      th.classList.remove('sorted');
    }
  });
}

function updatePagination(filteredCount) {
  const bar = document.getElementById('pagination-bar');
  if (!bar) return;
  const perPage = C.pagination;
  if (perPage <= 0) return;
  const totalPages = Math.max(1, Math.ceil(filteredCount / perPage));
  page = Math.min(page, totalPages - 1);
  document.getElementById('page-info').textContent = \`Page \${page + 1} of \${totalPages}\`;
  document.getElementById('first-btn').disabled = page === 0;
  document.getElementById('prev-btn').disabled  = page === 0;
  document.getElementById('next-btn').disabled  = page >= totalPages - 1;
  document.getElementById('last-btn').disabled  = page >= totalPages - 1;
}

function updateRowCount(filtered, showing, total) {
  const el = document.getElementById('row-count');
  if (!el) return;
  if (filtered === total) {
    el.textContent = \`\${total.toLocaleString()} rows\`;
  } else {
    el.textContent = \`\${filtered.toLocaleString()} of \${total.toLocaleString()} rows\`;
  }
}

function applyFrozenOffsets() {
  requestAnimationFrame(() => {
    const ths = Array.from(document.querySelectorAll('#main-table thead th.frozen'));
    let left = 0;
    ths.forEach(th => {
      th.style.left = left + 'px';
      left += th.offsetWidth;
    });
    document.querySelectorAll('#main-table tbody tr').forEach(tr => {
      const tds = Array.from(tr.querySelectorAll('td.frozen'));
      let l = 0, i = 0;
      tds.forEach(td => {
        td.style.left = l + 'px';
        l += ths[i] ? ths[i].offsetWidth : td.offsetWidth;
        i++;
      });
    });
  });
}

// ─── Export ───────────────────────────────────────────────────────────────
function downloadFile(content, filename, mime) {
  const blob = new Blob([content], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = filename;
  document.body.appendChild(a); a.click();
  document.body.removeChild(a); URL.revokeObjectURL(url);
}

function exportCsv() {
  const rows = filteredRows(sortedRows());
  const csvEsc = v => {
    const s = String(v ?? '');
    return s.includes(',') || s.includes('"') || s.includes('\\n')
      ? '"' + s.replace(/"/g, '""') + '"' : s;
  };
  const lines = [
    C.visibleHeaders.map(csvEsc).join(','),
    ...rows.map(row => C.colIndices.map(i => csvEsc(row[i])).join(','))
  ];
  downloadFile(lines.join('\\n'), C.title.replace(/[^a-z0-9]+/gi, '-') + '.csv', 'text/csv');
}

function exportJson() {
  const rows = filteredRows(sortedRows());
  const objects = rows.map(row => {
    const obj = {};
    C.visibleHeaders.forEach((h, i) => { obj[h] = row[C.colIndices[i]] ?? null; });
    return obj;
  });
  downloadFile(JSON.stringify(objects, null, 2), C.title.replace(/[^a-z0-9]+/gi, '-') + '.json', 'application/json');
}

// ─── Events ───────────────────────────────────────────────────────────────
function setupEvents() {
  // Sort on header click
  document.querySelectorAll('#main-table th.sortable').forEach(th => {
    if (th.dataset.noSort) return;
    th.addEventListener('click', () => {
      const key = th.dataset.key;
      if (sortCol === key) {
        sortDir = sortDir === 'asc' ? 'desc' : 'asc';
      } else {
        sortCol = key; sortDir = 'asc';
      }
      page = 0;
      renderTable();
    });
  });

  // Search
  const si = document.getElementById('search-input');
  if (si) {
    si.addEventListener('input', e => {
      query = e.target.value;
      page = 0;
      renderTable();
    });
  }

  // Pagination
  const first = document.getElementById('first-btn');
  const prev  = document.getElementById('prev-btn');
  const next  = document.getElementById('next-btn');
  const last  = document.getElementById('last-btn');
  if (first) first.addEventListener('click', () => { page = 0; renderTable(); });
  if (prev)  prev.addEventListener('click',  () => { page = Math.max(0, page - 1); renderTable(); });
  if (next)  next.addEventListener('click',  () => { page++; renderTable(); });
  if (last)  last.addEventListener('click', () => {
    const total = filteredRows(sortedRows()).length;
    page = Math.max(0, Math.ceil(total / C.pagination) - 1);
    renderTable();
  });

  // Export
  const csvBtn = document.getElementById('export-csv');
  if (csvBtn) csvBtn.addEventListener('click', exportCsv);
  const jsonBtn = document.getElementById('export-json');
  if (jsonBtn) jsonBtn.addEventListener('click', exportJson);
}

// ─── Init ─────────────────────────────────────────────────────────────────
renderTable();
setupEvents();

}());
</script>
</body>
</html>`;
}

// ─── CSS Generation ───────────────────────────────────────────────────────────

function generateCSS(config: TableConfig, frozenCount: number): string {
  return `
/* ── Reset & base ── */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

/* ── Theme variables ── */
:root {
  --bg:          #09090b;
  --surface:     #18181b;
  --surface-2:   #27272a;
  --surface-3:   #3f3f46;
  --border:      #3f3f46;
  --border-l:    #52525b;
  --text:        #fafafa;
  --text-muted:  #a1a1aa;
  --text-dim:    #71717a;
  --accent:      #6366f1;
  --accent-dim:  #4338ca;
  --th-bg:       #1c1c1f;
  --td-bg:       #09090b;
  --td-bg-alt:   #111113;
  --td-hover:    #1c1c1f;
  --shadow:      0 1px 3px rgba(0,0,0,.4);
  --radius:      6px;
  --bool-true:   #22c55e;
  --bool-false:  #71717a;
  --frozen-shadow: 4px 0 8px rgba(0,0,0,.4);
}
[data-theme="light"] {
  --bg:          #f4f4f5;
  --surface:     #ffffff;
  --surface-2:   #f4f4f5;
  --surface-3:   #e4e4e7;
  --border:      #d4d4d8;
  --border-l:    #a1a1aa;
  --text:        #09090b;
  --text-muted:  #52525b;
  --text-dim:    #71717a;
  --accent:      #4f46e5;
  --accent-dim:  #6366f1;
  --th-bg:       #f4f4f5;
  --td-bg:       #ffffff;
  --td-bg-alt:   #fafafa;
  --td-hover:    #f0f0f1;
  --shadow:      0 1px 3px rgba(0,0,0,.1);
  --bool-true:   #16a34a;
  --bool-false:  #a1a1aa;
  --frozen-shadow: 4px 0 8px rgba(0,0,0,.12);
}

/* ── Layout ── */
html, body { height: 100%; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
       background: var(--bg); color: var(--text); font-size: 14px; line-height: 1.5; }

.page { display: flex; flex-direction: column; height: 100vh; max-height: 100vh; }

/* ── Header ── */
.page-header {
  display: flex; align-items: flex-start; justify-content: space-between;
  padding: 20px 24px 14px; border-bottom: 1px solid var(--border);
  background: var(--surface); gap: 16px; flex-shrink: 0;
}
.page-title { font-size: 18px; font-weight: 600; letter-spacing: -0.01em; }
.caption    { font-size: 13px; color: var(--text-muted); margin-top: 3px; }
.header-meta { display: flex; align-items: center; gap: 8px; flex-shrink: 0; }
.meta-badge  {
  font-size: 11px; font-weight: 500; padding: 2px 8px;
  background: var(--surface-2); border: 1px solid var(--border);
  border-radius: 99px; color: var(--text-muted);
}
.meta-source { font-size: 11px; color: var(--text-dim); font-family: monospace; }

/* ── Toolbar ── */
.toolbar {
  display: flex; align-items: center; justify-content: space-between;
  padding: 10px 24px; border-bottom: 1px solid var(--border);
  background: var(--surface); gap: 12px; flex-shrink: 0;
}
.search-wrap { position: relative; flex: 1; max-width: 400px; }
.search-icon {
  position: absolute; left: 10px; top: 50%; transform: translateY(-50%);
  width: 15px; height: 15px; color: var(--text-dim); pointer-events: none;
}
#search-input {
  width: 100%; padding: 7px 12px 7px 34px;
  background: var(--surface-2); border: 1px solid var(--border);
  border-radius: var(--radius); color: var(--text); font-size: 13px;
  outline: none; transition: border-color .15s;
}
#search-input:focus { border-color: var(--accent); }
#search-input::placeholder { color: var(--text-dim); }
.toolbar-actions { display: flex; gap: 8px; }

/* ── Buttons ── */
.btn {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 6px 14px; font-size: 13px; font-weight: 500;
  background: var(--surface-2); border: 1px solid var(--border);
  border-radius: var(--radius); color: var(--text); cursor: pointer;
  transition: background .15s, border-color .15s; user-select: none; white-space: nowrap;
}
.btn:hover { background: var(--surface-3); border-color: var(--border-l); }
.btn:active { transform: translateY(1px); }
.btn:disabled { opacity: .4; cursor: not-allowed; transform: none; }
.btn svg { width: 14px; height: 14px; flex-shrink: 0; }
.btn-sm { padding: 4px 10px; font-size: 12px; }

/* ── Table scroll container ── */
.table-scroll-wrap {
  flex: 1; overflow: auto; min-height: 0;
  background: var(--td-bg);
}

/* ── Table ── */
#main-table {
  border-collapse: separate; border-spacing: 0;
  width: 100%; min-width: max-content;
  font-size: ${config.compact ? "12px" : "13px"};
}

/* ── Headers ── */
#main-table thead { position: sticky; top: 0; z-index: 10; }
#main-table th {
  padding: ${config.compact ? "7px 12px" : "10px 14px"};
  background: var(--th-bg); border-bottom: 1px solid var(--border);
  font-weight: 600; font-size: 11px; text-transform: uppercase;
  letter-spacing: 0.04em; color: var(--text-muted);
  white-space: nowrap; user-select: none; text-align: left;
}
#main-table th.sortable { cursor: pointer; }
#main-table th.sortable:hover { background: var(--surface-3); color: var(--text); }
#main-table th.sorted { color: var(--accent); }
.sort-icon { display: inline-block; width: 12px; margin-left: 4px; font-size: 10px; }
.th-rownum { color: var(--text-dim); width: 40px; }

/* ── Cells ── */
#main-table td {
  padding: ${config.compact ? "5px 12px" : "8px 14px"};
  border-bottom: 1px solid var(--border);
  vertical-align: middle;
  max-width: ${config.maxCellWidth};
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  background: var(--td-bg);
  transition: background .1s;
}
#main-table td.td-rn { color: var(--text-dim); font-size: 11px; font-family: monospace; }
#main-table tbody tr:last-child td { border-bottom: none; }
#main-table tbody tr:hover td { background: var(--td-hover); }

/* ── Striped ── */
#main-table.striped tbody tr:nth-child(even) td { background: var(--td-bg-alt); }
#main-table.striped tbody tr:nth-child(even):hover td { background: var(--td-hover); }

/* ── Frozen columns ── */
${
  frozenCount > 0
    ? `
#main-table th.frozen,
#main-table td.frozen {
  position: sticky; z-index: 2;
  background: inherit;
}
#main-table thead th.frozen { z-index: 12; }
/* Shadow on last frozen column */
#main-table th.frozen:last-of-type,
#main-table td.frozen:last-of-type {
  box-shadow: var(--frozen-shadow);
}
`
    : ""
}

/* ── Cell content types ── */
.bool-true  { color: var(--bool-true); font-size: 15px; }
.bool-false { color: var(--bool-false); font-size: 15px; }
.badge {
  display: inline-block; padding: 1px 8px; border-radius: 99px;
  font-size: 11px; font-weight: 500; white-space: nowrap;
}
#main-table td a { color: var(--accent); text-decoration: none; }
#main-table td a:hover { text-decoration: underline; }
#main-table td code {
  font-family: 'SF Mono', ui-monospace, monospace; font-size: 11px;
  background: var(--surface-2); padding: 1px 5px; border-radius: 3px;
}

/* ── Table footer ── */
.table-footer {
  display: flex; align-items: center; justify-content: space-between;
  padding: 10px 24px; border-top: 1px solid var(--border);
  background: var(--surface); flex-shrink: 0; gap: 16px;
}
.pagination-bar { display: flex; align-items: center; gap: 6px; }
.page-info { font-size: 13px; color: var(--text-muted); padding: 0 6px; min-width: 100px; text-align: center; }
.row-count-wrap { text-align: right; }
.row-count { font-size: 12px; color: var(--text-dim); }

/* ── Empty state ── */
#tbody:empty::after {
  content: 'No rows match your search.';
  display: block; padding: 40px; text-align: center;
  color: var(--text-dim); font-size: 13px;
}

/* ── Scrollbar ── */
.table-scroll-wrap::-webkit-scrollbar { width: 8px; height: 8px; }
.table-scroll-wrap::-webkit-scrollbar-track { background: transparent; }
.table-scroll-wrap::-webkit-scrollbar-thumb { background: var(--surface-3); border-radius: 99px; }
.table-scroll-wrap::-webkit-scrollbar-thumb:hover { background: var(--border-l); }
`;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

const { dataPath, outputPath, config } = parseArgs();

let rawData: TableData;
try {
  rawData = JSON.parse(readFileSync(dataPath, "utf-8")) as TableData;
} catch (e) {
  console.error(`Failed to read/parse data JSON: ${dataPath}`);
  console.error(e instanceof Error ? e.message : String(e));
  process.exit(1);
}

validateData(rawData);

const html = generateHtml(rawData, config);

mkdirSync(dirname(resolve(outputPath)), { recursive: true });
writeFileSync(outputPath, html, "utf-8");

const colsShown = config.columns ? config.columns.length : rawData.headers.length;
console.log(
  `✓ Table generated: ${outputPath}\n` +
    `  ${rawData.rows.length.toLocaleString()} rows · ${colsShown} columns · ` +
    `theme: ${config.theme}` +
    (config.search ? " · search" : "") +
    (config.pagination > 0 ? ` · ${config.pagination}/page` : "") +
    (config.export ? ` · export: ${config.export}` : "")
);
