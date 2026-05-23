/// <reference types="node" />
/**
 * generate-html.ts — Renders structured JSON into a self-contained HTML report.
 *
 * Pipeline: JSON → validate → renderStyle → inlineAssets → single HTML file
 * Supports 13 styles via pluggable template.ts modules in styles/<name>/.
 *
 * Usage:
 *   npx tsx generate-html.ts <json> <output> [--style <name>] [--all-styles]
 */

import {
  readFileSync,
  writeFileSync,
  existsSync,
  mkdirSync,
  readdirSync,
} from "fs";
import { resolve, dirname, basename, join } from "path";
import { fileURLToPath } from "url";

// Sibling root assets: styles.css, report.js, shared-base.css, shared.js
const SKILL_DIR = dirname(fileURLToPath(import.meta.url));

const STYLE_GROUPS: { label: string; styles: string[] }[] = [
  { label: "Classic", styles: ["default", "minimal", "notion"] },
  { label: "Data", styles: ["dashboard", "data-table", "jupyter"] },
  { label: "Creative", styles: ["neon", "terminal", "magazine", "feed"] },
  { label: "Print", styles: ["academic", "corporate", "slide"] },
];

const STYLE_DESCRIPTIONS: Record<string, string> = {
  default: "Dark sidebar with accent colors",
  notion: "Clean Notion-style with cards",
  dashboard: "Analytics dashboard with metrics",
  magazine: "Editorial with serif typography",
  terminal: "Green-on-black retro terminal",
  "data-table": "Spreadsheet table layout",
  feed: "Social feed timeline cards",
  corporate: "Print-ready corporate report",
  academic: "LaTeX-inspired academic paper with serif fonts",
  neon: "Cyberpunk neon-glow dark theme with gradients",
  minimal: "Ultra-clean reading-focused layout",
  jupyter: "Jupyter notebook with executable-style cells",
  slide: "Presentation slide deck with navigation",
};

const STYLE_COLORS: Record<string, string> = {
  default: "#6366f1",
  notion: "#9b9a97",
  dashboard: "#3b82f6",
  magazine: "#8b2252",
  terminal: "#33ff33",
  "data-table": "#16a34a",
  feed: "#1d9bf0",
  corporate: "#0f2b46",
  academic: "#374151",
  neon: "#00f0ff",
  minimal: "#6b7280",
  jupyter: "#f57c00",
  slide: "#818cf8",
};

// ─── Types ────────────────────────────────────────────────────────────────────

export interface NavChild {
  id: string;
  text: string;
  level: 3;
}
export interface NavItem {
  id: string;
  text: string;
  level: 2;
  children?: NavChild[];
}

export interface ParagraphBlock {
  type: "paragraph";
  html: string;
}
export interface HrBlock {
  type: "hr";
}
export interface CodeBlock {
  type: "code";
  lang: string;
  content: string;
}
export interface TableBlock {
  type: "table";
  headers: string[];
  rows: string[][];
}
export interface ListBlock {
  type: "ul" | "ol";
  items: string[];
}
export interface BlockquoteBlock {
  type: "blockquote";
  html: string;
}
export interface SubsectionBlock {
  type: "subsection";
  id: string;
  heading: string;
  level: 3;
  blocks: Block[];
}
export interface SubSubsectionBlock {
  type: "subsubsection";
  id: string;
  heading: string;
  level: 4;
  blocks: Block[];
}
export interface TreeNode {
  label: string;
  desc?: string;
  children?: TreeNode[];
}
export interface TreeBlock {
  type: "tree";
  nodes: TreeNode[];
}
export interface MathBlock {
  type: "math";
  latex: string;
  display?: boolean; // default true (block-level); false for inline-style rendering
}

export type Block =
  | ParagraphBlock
  | HrBlock
  | CodeBlock
  | TableBlock
  | ListBlock
  | BlockquoteBlock
  | SubsectionBlock
  | SubSubsectionBlock
  | TreeBlock
  | MathBlock;

export interface Section {
  id: string;
  heading: string;
  level: 2;
  blocks: Block[];
}
export interface ReportData {
  title: string;
  subtitle?: string | null;
  generated: string;
  nav: NavItem[];
  sections: Section[];
}

// ─── Validation ───────────────────────────────────────────────────────────────

const VALID_TYPES = new Set([
  "paragraph",
  "hr",
  "code",
  "table",
  "ul",
  "ol",
  "blockquote",
  "math",
  "subsection",
  "subsubsection",
  "tree",
]);

function assertStr(v: unknown, path: string, field: string): void {
  if (typeof v !== "string" || !v)
    throw new Error(
      `[${path}] requires a non-empty string "${field}". Got: ${JSON.stringify(v)}`,
    );
}

function validateBlock(b: unknown, path: string): void {
  if (typeof b !== "object" || b === null || Array.isArray(b))
    throw new Error(
      `[${path}] Expected a block object, got ${JSON.stringify(b)}`,
    );
  const blk = b as Record<string, unknown>;
  if (typeof blk.type !== "string")
    throw new Error(
      `[${path}] Block missing required string field "type". Got: ${JSON.stringify(blk)}`,
    );
  if (!VALID_TYPES.has(blk.type))
    throw new Error(
      `[${path}] Invalid block type "${blk.type}". Valid: ${[...VALID_TYPES].join(", ")}`,
    );

  switch (blk.type) {
    case "paragraph":
    case "blockquote":
      if (typeof blk.html !== "string")
        throw new Error(
          `[${path}] "${blk.type}" requires string "html". Got: ${JSON.stringify(blk.html)}`,
        );
      break;
    case "code":
      if (typeof blk.lang !== "string")
        throw new Error(
          `[${path}] "code" requires string "lang" (use "" if unknown). Got: ${JSON.stringify(blk.lang)}`,
        );
      if (typeof blk.content !== "string")
        throw new Error(
          `[${path}] "code" requires string "content". Got: ${JSON.stringify(blk.content)}`,
        );
      break;
    case "table":
      if (
        !Array.isArray(blk.headers) ||
        blk.headers.some((h) => typeof h !== "string")
      )
        throw new Error(
          `[${path}] "table" requires string[] "headers". Got: ${JSON.stringify(blk.headers)}`,
        );
      if (!Array.isArray(blk.rows))
        throw new Error(
          `[${path}] "table" requires string[][] "rows". Got: ${JSON.stringify(blk.rows)}`,
        );
      (blk.rows as unknown[]).forEach((row, i) => {
        if (!Array.isArray(row))
          throw new Error(
            `[${path}.rows[${i}]] Each row must be string[]. Got: ${JSON.stringify(row)}`,
          );
      });
      break;
    case "ul":
    case "ol":
      if (
        !Array.isArray(blk.items) ||
        blk.items.some((i) => typeof i !== "string")
      )
        throw new Error(
          `[${path}] "${blk.type}" requires string[] "items". Got: ${JSON.stringify(blk.items)}`,
        );
      break;
    case "subsection":
    case "subsubsection":
      assertStr(blk.id, path, "id");
      assertStr(blk.heading, path, "heading");
      if (!Array.isArray(blk.blocks))
        throw new Error(
          `[${path}] "${blk.type}" requires a "blocks" array. Got: ${JSON.stringify(blk.blocks)}`,
        );
      (blk.blocks as unknown[]).forEach((child, i) =>
        validateBlock(child, `${path}.blocks[${i}]`),
      );
      break;
    case "tree":
      if (!Array.isArray(blk.nodes))
        throw new Error(
          `[${path}] "tree" requires a "nodes" array. Got: ${JSON.stringify(blk.nodes)}`,
        );
      (blk.nodes as unknown[]).forEach((node, i) =>
        validateTreeNode(node, `${path}.nodes[${i}]`),
      );
      break;
    case "math":
      if (typeof blk.latex !== "string")
        throw new Error(
          `[${path}] "math" requires string "latex". Got: ${JSON.stringify(blk.latex)}`,
        );
      break;
  }
}

function validateTreeNode(node: unknown, path: string): void {
  if (typeof node !== "object" || node === null)
    throw new Error(
      `[${path}] Expected a tree node object, got ${JSON.stringify(node)}`,
    );
  const n = node as Record<string, unknown>;
  if (typeof n.label !== "string" || !n.label)
    throw new Error(
      `[${path}] Tree node requires a non-empty string "label". Got: ${JSON.stringify(n.label)}`,
    );
  if (n.desc !== undefined && typeof n.desc !== "string")
    throw new Error(
      `[${path}] Tree node "desc" must be a string. Got: ${JSON.stringify(n.desc)}`,
    );
  if (n.children !== undefined) {
    if (!Array.isArray(n.children))
      throw new Error(
        `[${path}] Tree node "children" must be an array. Got: ${JSON.stringify(n.children)}`,
      );
    (n.children as unknown[]).forEach((child, i) =>
      validateTreeNode(child, `${path}.children[${i}]`),
    );
  }
}

function validateNav(item: unknown, path: string): void {
  if (typeof item !== "object" || item === null)
    throw new Error(
      `[${path}] Expected a nav item object, got ${JSON.stringify(item)}`,
    );
  const n = item as Record<string, unknown>;
  assertStr(n.id, path, "id");
  assertStr(n.text, path, "text");
  if (n.children !== undefined) {
    if (!Array.isArray(n.children))
      throw new Error(
        `[${path}] "children" must be an array. Got: ${JSON.stringify(n.children)}`,
      );
    (n.children as unknown[]).forEach((c, i) =>
      validateNav(c, `${path}.children[${i}]`),
    );
  }
}

function validateSection(s: unknown, path: string): void {
  if (typeof s !== "object" || s === null)
    throw new Error(
      `[${path}] Expected a section object, got ${JSON.stringify(s)}`,
    );
  const sec = s as Record<string, unknown>;
  assertStr(sec.id, path, "id");
  assertStr(sec.heading, path, "heading");
  if (!Array.isArray(sec.blocks))
    throw new Error(
      `[${path}] Section requires a "blocks" array. Got: ${JSON.stringify(sec.blocks)}`,
    );
  (sec.blocks as unknown[]).forEach((b, i) =>
    validateBlock(b, `${path}.blocks[${i}]`),
  );
}

export function validate(raw: unknown): ReportData {
  if (typeof raw !== "object" || raw === null)
    throw new Error(`Root must be a JSON object. Got: ${typeof raw}`);
  const d = raw as Record<string, unknown>;
  assertStr(d.title, "root", "title");
  assertStr(d.generated, "root", "generated");
  if (!Array.isArray(d.nav))
    throw new Error(
      `Root requires a "nav" array. Got: ${JSON.stringify(d.nav)}`,
    );
  if (!Array.isArray(d.sections))
    throw new Error(
      `Root requires a "sections" array. Got: ${JSON.stringify(d.sections)}`,
    );
  (d.nav as unknown[]).forEach((item, i) => validateNav(item, `nav[${i}]`));
  (d.sections as unknown[]).forEach((sec, i) =>
    validateSection(sec, `sections[${i}]`),
  );
  // Safe after structural validation — all required fields checked above
  return d as ReportData;
}

// ─── Utilities ────────────────────────────────────────────────────────────────

/** HTML-escape a value for safe embedding in HTML attributes and text nodes. */
export function esc(s: string | null | undefined): string {
  return String(s ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/**
 * Creates a protect/restore pair that shields already-rendered HTML spans from
 * being corrupted by subsequent regex passes. Each captured span is stored by
 * index; the \x02N\x03 sentinel cannot appear in HTML-escaped source code.
 *
 * Usage:
 *   const { protect, restore } = makePlaceholder();
 *   const result = restore(input.replace(pattern, (m) => protect(`<span>${m}</span>`)));
 */
function makePlaceholder() {
  const segs: string[] = [];
  const protect = (html: string): string => {
    segs.push(html);
    return `\x02_${segs.length - 1}_\x03`;
  };
  const restore = (s: string): string =>
    s.replace(/\x02_(\d+)_\x03/g, (_, i) => segs[+i]);
  return { protect, restore };
}

/**
 * Count how many blocks of the given types exist in a block list, recursing
 * into subsection and subsubsection blocks.
 */
export function countBlocksOfType(blocks: Block[], types: string[]): number {
  let n = 0;
  for (const b of blocks) {
    if (types.includes(b.type)) n++;
    if (
      (b.type === "subsection" || b.type === "subsubsection") &&
      "blocks" in b
    ) {
      n += countBlocksOfType((b as SubsectionBlock).blocks, types);
    }
  }
  return n;
}

// ─── Syntax Highlighting ──────────────────────────────────────────────────────
// Each highlighter receives an HTML-escaped string and returns HTML with <span>
// class tags applied. The protect/restore pattern prevents later regex passes
// from corrupting class= attributes or string values inserted by earlier passes.

/** Highlight bash/sh/shell: comments → keywords → strings. */
/** Internal — use highlight() dispatcher instead. */
function highlightBash(escaped: string): string {
  const { protect, restore } = makePlaceholder();
  return restore(
    escaped
      .replace(/(#[^\n]*)/g, (m) => protect(`<span class="cm">${m}</span>`))
      .replace(/("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')/g, (m) =>
        protect(`<span class="st">${m}</span>`),
      )
      .replace(
        /\b(npm|node|npx|cd|ls|find|grep|cat|mkdir|rm|echo|export|source|curl|git|docker|make|chmod|cp|mv)\b/g,
        (m) => protect(`<span class="kw">${m}</span>`),
      ),
  );
}

/** Highlight TypeScript / JavaScript: comments → strings → decorators → keywords → numbers. */
function highlightTS(escaped: string): string {
  const { protect, restore } = makePlaceholder();
  return restore(
    escaped
      .replace(/(\/\/[^\n]*)/g, (m) => protect(`<span class="cm">${m}</span>`))
      .replace(
        /("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|`(?:[^`\\]|\\.)*`)/g,
        (m) => protect(`<span class="st">${m}</span>`),
      )
      .replace(/(@[A-Za-z_$][\w$]*)/g, (m) =>
        protect(`<span class="at">${m}</span>`),
      )
      .replace(
        /\b(const|let|var|function|return|import|export|from|type|interface|class|extends|implements|async|await|new|if|else|for|while|switch|case|break|default|null|undefined|true|false|typeof|keyof|in|of|throw|try|catch|finally|void|never|any|string|number|boolean)\b/g,
        (m) => protect(`<span class="kw">${m}</span>`),
      )
      // JSX component tags: <Component, </Component, <Auth.Provider (HTML-escaped < is &lt;)
      .replace(/(&lt;\/?[A-Z][\w.]*)/g, (m) =>
        protect(`<span class="tp">${m}</span>`),
      )
      // JSX HTML tags: &lt;div, &lt;/span, &lt;input (lowercase tags)
      .replace(
        /(&lt;\/?)((?:div|span|p|a|ul|ol|li|h[1-6]|img|input|button|form|table|thead|tbody|tr|th|td|nav|main|header|footer|section|article|aside|label|select|option|textarea)\b)/g,
        (_, bracket, tag) =>
          protect(`<span class="op">${bracket}</span>`) +
          protect(`<span class="kw">${tag}</span>`),
      )
      .replace(/\b(\d+\.?\d*n?)\b/g, (m) =>
        protect(`<span class="nm">${m}</span>`),
      ),
  );
}

/** Highlight JSON: property keys → string values → numeric values → booleans/null.
 *  After esc(), double quotes become &quot; so regexes must match that entity. */
function highlightJSON(escaped: string): string {
  const { protect, restore } = makePlaceholder();
  const Q = "&quot;"; // escaped double quote
  // Match a quoted string: &quot;...&quot; (no nested &quot; allowed since JSON strings don't contain unescaped quotes)
  const qStr = `${Q}[^${Q}]*${Q}`;
  const keyRe = new RegExp(`(${qStr})\\s*:`, "g");
  const valRe = new RegExp(`:\\s*(${qStr})`, "g");
  return restore(
    escaped
      // Property keys: "key":
      .replace(
        keyRe,
        (m, k) => protect(`<span class="kw">${k}</span>`) + m.slice(k.length),
      )
      // String values: : "value"
      .replace(
        valRe,
        (m, v) =>
          m.slice(0, m.length - v.length) +
          protect(`<span class="st">${v}</span>`),
      )
      // Numeric values: : 123
      .replace(
        /:\s*(-?\d+\.?\d*)/g,
        (m, n) =>
          m.slice(0, m.length - n.length) +
          protect(`<span class="nm">${n}</span>`),
      )
      // Booleans and null
      .replace(/\b(true|false|null)\b/g, (m) =>
        protect(`<span class="at">${m}</span>`),
      ),
  );
}

/** Highlight CSS / SCSS: block comments → property names → values. */
function highlightCSS(escaped: string): string {
  const { protect, restore } = makePlaceholder();
  return restore(
    escaped
      .replace(/(\/\*[\s\S]*?\*\/)/g, (m) =>
        protect(`<span class="cm">${m}</span>`),
      )
      .replace(
        /([a-z-]+)\s*:/g,
        (m, p) => protect(`<span class="kw">${p}</span>`) + ":",
      )
      .replace(
        /:\s*([^;{}\n\x02\x03]+)/g,
        (m, v) => ": " + protect(`<span class="st">${v.trim()}</span>`),
      ),
  );
}

/** Highlight Python: comments → triple-quoted strings → strings → decorators → keywords → numbers. */
function highlightPython(escaped: string): string {
  const { protect, restore } = makePlaceholder();
  return restore(
    escaped
      .replace(/(#[^\n]*)/g, (m) => protect(`<span class="cm">${m}</span>`))
      .replace(
        /((&quot;){3}[\s\S]*?(&quot;){3}|(&apos;){3}[\s\S]*?(&apos;){3})/g,
        (m) => protect(`<span class="st">${m}</span>`),
      )
      .replace(/("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')/g, (m) =>
        protect(`<span class="st">${m}</span>`),
      )
      .replace(/(@[A-Za-z_][\w.]*)/g, (m) =>
        protect(`<span class="at">${m}</span>`),
      )
      .replace(
        /\b(def|class|import|from|return|if|elif|else|for|while|try|except|finally|with|as|raise|pass|break|continue|yield|lambda|async|await|and|or|not|in|is|None|True|False|self|print|len|range|type|int|str|float|list|dict|set|tuple|bool|super|property|staticmethod|classmethod|isinstance|__init__|__name__|__main__)\b/g,
        (m) => protect(`<span class="kw">${m}</span>`),
      )
      .replace(/\b(\d+\.?\d*j?)\b/g, (m) =>
        protect(`<span class="nm">${m}</span>`),
      ),
  );
}

/** Highlight YAML: comments → string values → keys → booleans/nulls → numbers → anchors/aliases. */
function highlightYAML(escaped: string): string {
  const { protect, restore } = makePlaceholder();
  return restore(
    escaped
      .replace(/(#[^\n]*)/g, (m) => protect(`<span class="cm">${m}</span>`))
      .replace(/("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')/g, (m) =>
        protect(`<span class="st">${m}</span>`),
      )
      .replace(
        /^(\s*[A-Za-z_][\w.-]*)(\s*:)/gm,
        (_, key, colon) => protect(`<span class="kw">${key}</span>`) + colon,
      )
      .replace(
        /:\s+(true|false|yes|no|null|~)\b/gi,
        (m, v) => ": " + protect(`<span class="at">${v}</span>`),
      )
      .replace(
        /:\s+(\d+\.?\d*)\b/g,
        (m, n) => ": " + protect(`<span class="nm">${n}</span>`),
      )
      .replace(/([&*][\w-]+)/g, (m) => protect(`<span class="tp">${m}</span>`)),
  );
}

/** Highlight Markdown: headings → bold → italic → inline code → links → list markers. */
function highlightMarkdown(escaped: string): string {
  const { protect, restore } = makePlaceholder();
  return restore(
    escaped
      .replace(/^(#{1,6}\s+.*)$/gm, (m) =>
        protect(`<span class="kw">${m}</span>`),
      )
      .replace(/(\*\*[^*]+\*\*|__[^_]+__)/g, (m) =>
        protect(`<span class="st">${m}</span>`),
      )
      .replace(/(?<!\*)\*(?!\*)([^*]+)\*(?!\*)/g, (m) =>
        protect(`<span class="at">${m}</span>`),
      )
      .replace(/(`[^`]+`)/g, (m) => protect(`<span class="tp">${m}</span>`))
      .replace(/(\[(?:[^\]\\]|\\.)*\]\([^)]*\))/g, (m) =>
        protect(`<span class="nm">${m}</span>`),
      )
      .replace(/^(\s*[-*+]|\s*\d+\.)\s/gm, (m) =>
        protect(`<span class="cm">${m}</span>`),
      ),
  );
}

/**
 * Dispatch to the appropriate language highlighter given raw source code.
 * Returns HTML-escaped plain text for unsupported languages.
 */
export function highlight(code: string, lang: string): string {
  const e = esc(code);
  if (lang === "bash" || lang === "sh" || lang === "shell" || lang === "zsh")
    return highlightBash(e);
  if (["ts", "tsx", "js", "jsx", "typescript", "javascript"].includes(lang))
    return highlightTS(e);
  if (lang === "json") return highlightJSON(e);
  if (lang === "css" || lang === "scss") return highlightCSS(e);
  if (lang === "python" || lang === "py") return highlightPython(e);
  if (lang === "yaml" || lang === "yml") return highlightYAML(e);
  if (lang === "markdown" || lang === "md") return highlightMarkdown(e);
  return e;
}

// ─── Block Rendering ──────────────────────────────────────────────────────────

/**
 * Render a directory or file node in the tree block.
 * Directories become expandable <details> elements; files get a data-ext
 * attribute for CSS extension-based coloring.
 */
export function renderTreeNode(node: TreeNode, depth = 0): string {
  const isDir = !!node.children?.length;
  const labelCls = isDir
    ? "tree-label tree-dir-label"
    : "tree-label tree-file-label";
  const extMatch = !isDir && node.label.match(/\.([a-z0-9]+)$/i);
  const extAttr = extMatch
    ? ` data-ext="${esc(extMatch[1].toLowerCase())}"`
    : "";
  const label = `<span class="${labelCls}"${extAttr}>${esc(node.label)}</span>`;
  const desc = node.desc
    ? ` <span class="tree-desc">${esc(node.desc)}</span>`
    : "";
  if (isDir) {
    const children = node
      .children!.map((c) => renderTreeNode(c, depth + 1))
      .join("");
    return [
      `<details${depth === 0 ? " open" : ""} class="tree-node">`,
      `  <summary>${label}${desc}</summary>`,
      `  <div class="tree-children">${children}</div>`,
      `</details>`,
    ].join("\n");
  }
  return `<div class="tree-leaf">${label}${desc}</div>`;
}

/** Render a fenced code block with a labelled header, copy button, and expand button.
 *  Adds line numbers when the block has more than 10 lines. */
function renderCodeBlock(block: CodeBlock): string {
  const lang = esc(block.lang) || "text";
  const highlighted = highlight(block.content, block.lang);
  const lines = block.content.split("\n");
  const lineCount = lines.length;
  const showLineNums = lineCount > 10;

  let codeHtml: string;
  if (showLineNums) {
    // Wrap each line with a line-number gutter
    const highlightedLines = highlighted.split("\n");
    const gutterWidth = String(lineCount).length;
    const numberedLines = highlightedLines
      .map((line, i) => {
        const num = String(i + 1).padStart(gutterWidth, " ");
        return `<span class="line-row"><span class="line-num" aria-hidden="true">${num}</span><span class="line-content">${line}</span></span>`;
      })
      .join("\n");
    codeHtml = `<pre class="has-line-nums"><code>${numberedLines}</code></pre>`;
  } else {
    codeHtml = `<pre><code>${highlighted}</code></pre>`;
  }

  return [
    `<div class="code-wrap">`,
    `  <div class="code-header">`,
    `    <span class="code-lang">${lang}</span>`,
    `    <span class="code-line-count">${lineCount} line${lineCount !== 1 ? "s" : ""}</span>`,
    `    <div class="code-actions">`,
    `      <button class="code-expand" aria-label="Expand">`,
    `        <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">`,
    `          <polyline points="15 3 21 3 21 9"/><polyline points="9 21 3 21 3 15"/>`,
    `          <line x1="21" y1="3" x2="14" y2="10"/><line x1="3" y1="21" x2="10" y2="14"/>`,
    `        </svg> Expand`,
    `      </button>`,
    `      <button class="copy-btn">Copy</button>`,
    `    </div>`,
    `  </div>`,
    `  ${codeHtml}`,
    `</div>`,
  ].join("\n");
}

/** Render a data table with sticky thead and zebra-striped rows. */
function renderTable(block: TableBlock): string {
  const head = block.headers.map((h) => `<th>${h}</th>`).join("");
  const rows = block.rows
    .map((r) => `<tr>${r.map((c) => `<td>${c}</td>`).join("")}</tr>`)
    .join("");
  return `<div class="table-wrap"><table><thead><tr>${head}</tr></thead><tbody>${rows}</tbody></table></div>`;
}

/**
 * Render a single content block. Complex types (code, table) delegate to
 * dedicated helpers; simple types are rendered inline.
 */
export function renderBlock(block: Block): string {
  switch (block.type) {
    case "paragraph":
      return `<p>${block.html}</p>`;
    case "hr":
      return `<hr>`;
    case "blockquote":
      return `<blockquote>${block.html}</blockquote>`;
    case "ul":
      return `<ul>${block.items.map((i) => `<li>${i}</li>`).join("")}</ul>`;
    case "ol":
      return `<ol>${block.items.map((i) => `<li>${i}</li>`).join("")}</ol>`;
    case "code":
      return renderCodeBlock(block);
    case "table":
      return renderTable(block);
    case "subsection":
    case "subsubsection": {
      const tag = block.level === 3 ? "h3" : "h4";
      return `<${tag} id="${esc(block.id)}">${esc(block.heading)}</${tag}>${block.blocks.map(renderBlock).join("")}`;
    }
    case "tree":
      return `<div class="tree-wrap">${block.nodes.map((n) => renderTreeNode(n, 0)).join("")}</div>`;
    case "math": {
      const display = block.display !== false;
      if (display) {
        return `<div class="math-block">$$${block.latex}$$</div>`;
      }
      return `<span class="math-inline">$${block.latex}$</span>`;
    }
  }
}

// ─── Document Rendering ───────────────────────────────────────────────────────

/** Render a top-level H2 section with all its nested blocks. */
export function renderSection(section: Section): string {
  return [
    `<section data-section-id="${esc(section.id)}">`,
    `  <h2 id="${esc(section.id)}">${esc(section.heading)}</h2>`,
    section.blocks.map(renderBlock).join("\n"),
    `</section>`,
  ].join("\n");
}

/** Render the sidebar navigation tree with H2 groups and H3 children. */
export function renderNav(nav: NavItem[]): string {
  return nav
    .map((item) => {
      const children = item.children?.length
        ? `<ul>${item.children
            .map(
              (c) =>
                `<li class="nav-section nav-h3"><a href="#${esc(c.id)}">${esc(c.text)}</a></li>`,
            )
            .join("")}</ul>`
        : "";
      return `<li class="nav-section nav-h2"><a href="#${esc(item.id)}">${esc(item.text)}</a>${children}</li>`;
    })
    .join("");
}

/** Build the human-readable stats summary shown in the report header
 *  (e.g. "8 sections · 12 code blocks · 3 tables"). */
export function computeStats(data: ReportData): string {
  const totalCode = data.sections.reduce(
    (acc, s) => acc + countBlocksOfType(s.blocks, ["code"]),
    0,
  );
  const totalTables = data.sections.reduce(
    (acc, s) => acc + countBlocksOfType(s.blocks, ["table"]),
    0,
  );
  const sc = data.sections.length;
  return [
    `${sc} section${sc !== 1 ? "s" : ""}`,
    totalCode ? `${totalCode} code block${totalCode !== 1 ? "s" : ""}` : "",
    totalTables ? `${totalTables} table${totalTables !== 1 ? "s" : ""}` : "",
  ]
    .filter(Boolean)
    .join(" · ");
}

// ─── HTML Template ────────────────────────────────────────────────────────────
// To add a new Google Font: append its query params to GOOGLE_FONTS_URL,
// add a button in renderFontMenu(), and add FONTS + FONT_LABELS entries in report.js.

const GOOGLE_FONTS_URL =
  "https://fonts.googleapis.com/css2?" +
  "family=Inter:ital,wght@0,400;0,500;0,600;0,700" +
  "&family=Source+Sans+3:ital,wght@0,400;0,600" +
  "&family=Merriweather:ital,wght@0,400;0,700" +
  "&family=Roboto:wght@400;500;700" +
  "&family=Open+Sans:wght@400;600;700" +
  "&family=Nunito:wght@400;600;700" +
  "&family=DM+Sans:wght@400;500;700" +
  "&family=Work+Sans:wght@400;500;700" +
  "&family=Lora:ital,wght@0,400;0,700;1,400" +
  "&family=Playfair+Display:ital,wght@0,400;0,700;1,400" +
  "&family=Plus+Jakarta+Sans:wght@400;500;600;700" +
  "&family=Space+Grotesk:wght@400;500;600;700" +
  "&family=IBM+Plex+Sans:wght@400;500;600;700" +
  "&family=IBM+Plex+Mono:wght@400;500" +
  "&family=Crimson+Pro:ital,wght@0,400;0,600;1,400" +
  "&family=EB+Garamond:ital,wght@0,400;0,700;1,400" +
  "&family=Libre+Baskerville:ital,wght@0,400;0,700;1,400" +
  "&display=swap";

/** Render the font picker dropdown. To add a font: add a button here, add
 *  the font to GOOGLE_FONTS_URL above, and add entries to report.js FONTS map. */
function renderFontMenu(): string {
  return `<div id="ftb-font-menu" class="font-menu">
        <div class="font-group-label">Sans-serif</div>
        <button class="font-opt" data-font="system">System UI <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="inter">Inter <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="roboto">Roboto <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="opensans">Open Sans <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="source">Source Sans <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="nunito">Nunito <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="dmsans">DM Sans <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="worksans">Work Sans <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="helvetica">Helvetica Neue <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="verdana">Verdana <span class="font-preview">Aa</span></button>
        <div class="font-group-label">Serif</div>
        <button class="font-opt" data-font="georgia">Georgia <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="lora">Lora <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="merriweather">Merriweather <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="playfair">Playfair Display <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="palatino">Palatino <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="crimson">Crimson Pro <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="garamond">EB Garamond <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="libre">Libre Baskerville <span class="font-preview">Aa</span></button>
        <div class="font-group-label">Modern</div>
        <button class="font-opt" data-font="jakarta">Plus Jakarta Sans <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="spacegrotesk">Space Grotesk <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="ibmplex">IBM Plex Sans <span class="font-preview">Aa</span></button>
        <div class="font-group-label">Monospace</div>
        <button class="font-opt" data-font="mono">JetBrains Mono <span class="font-preview">Aa</span></button>
        <button class="font-opt" data-font="ibmplexmono">IBM Plex Mono <span class="font-preview">Aa</span></button>
      </div>`;
}

/** Tiny SVG wireframe previews for each style — shown on hover in the style picker. */
const STYLE_PREVIEWS: Record<string, string> = {
  default: `<rect fill="#0f0f17" width="160" height="100" rx="4"/>
    <rect fill="#1a1a2e" x="0" y="0" width="40" height="100" rx="4"/>
    <rect fill="#6366f1" x="6" y="8" width="28" height="3" rx="1"/>
    <rect fill="#2d2d44" x="6" y="16" width="24" height="2" rx="1"/><rect fill="#2d2d44" x="6" y="22" width="20" height="2" rx="1"/><rect fill="#2d2d44" x="6" y="28" width="22" height="2" rx="1"/>
    <rect fill="#6366f1" x="50" y="10" width="50" height="4" rx="1" opacity=".3"/><rect fill="#e2e8f0" x="50" y="20" width="90" height="2" rx="1" opacity=".4"/><rect fill="#e2e8f0" x="50" y="26" width="80" height="2" rx="1" opacity=".3"/><rect fill="#1a1a2e" x="50" y="36" width="100" height="30" rx="3"/><rect fill="#e2e8f0" x="50" y="74" width="70" height="2" rx="1" opacity=".3"/>`,
  notion: `<rect fill="#ffffff" width="160" height="100" rx="4"/>
    <rect fill="#f7f6f3" x="0" y="0" width="160" height="14" rx="4"/><rect fill="#37352f" x="8" y="5" width="40" height="4" rx="1"/>
    <rect fill="#fff" x="12" y="22" width="136" height="30" rx="4" stroke="#e3e2de" stroke-width=".5"/><rect fill="#f7f6f3" x="16" y="26" width="60" height="3" rx="1"/><rect fill="#9b9a97" x="16" y="32" width="90" height="2" rx="1" opacity=".5"/><rect fill="#9b9a97" x="16" y="38" width="70" height="2" rx="1" opacity=".5"/>
    <rect fill="#fff" x="12" y="58" width="136" height="30" rx="4" stroke="#e3e2de" stroke-width=".5"/><rect fill="#f7f6f3" x="16" y="62" width="50" height="3" rx="1"/>`,
  dashboard: `<rect fill="#0f172a" width="160" height="100" rx="4"/>
    <rect fill="#1e293b" x="4" y="4" width="36" height="20" rx="3"/><rect fill="#3b82f6" x="8" y="8" width="16" height="6" rx="1"/><rect fill="#64748b" x="8" y="17" width="24" height="2" rx="1"/>
    <rect fill="#1e293b" x="44" y="4" width="36" height="20" rx="3"/><rect fill="#10b981" x="48" y="8" width="16" height="6" rx="1"/><rect fill="#64748b" x="48" y="17" width="24" height="2" rx="1"/>
    <rect fill="#1e293b" x="84" y="4" width="36" height="20" rx="3"/><rect fill="#f59e0b" x="88" y="8" width="16" height="6" rx="1"/>
    <rect fill="#1e293b" x="124" y="4" width="32" height="20" rx="3"/><rect fill="#ef4444" x="128" y="8" width="16" height="6" rx="1"/>
    <rect fill="#1e293b" x="4" y="28" width="76" height="68" rx="3"/><rect fill="#3b82f6" x="10" y="40" width="6" height="30" rx="1" opacity=".7"/><rect fill="#3b82f6" x="20" y="50" width="6" height="20" rx="1" opacity=".5"/><rect fill="#3b82f6" x="30" y="35" width="6" height="35" rx="1" opacity=".8"/><rect fill="#3b82f6" x="40" y="45" width="6" height="25" rx="1" opacity=".6"/>
    <rect fill="#1e293b" x="84" y="28" width="72" height="68" rx="3"/>`,
  magazine: `<rect fill="#faf8f5" width="160" height="100" rx="4"/>
    <rect fill="#8b2252" x="8" y="6" width="60" height="5" rx="1"/><rect fill="#333" x="8" y="14" width="40" height="2" rx="1" opacity=".4"/>
    <rect fill="#eee" x="8" y="22" width="68" height="40" rx="2"/><rect fill="#8b2252" x="12" y="26" width="30" height="3" rx="1" opacity=".3"/>
    <rect fill="#333" x="84" y="22" width="68" height="2" rx="1" opacity=".5"/><rect fill="#333" x="84" y="28" width="64" height="2" rx="1" opacity=".4"/><rect fill="#333" x="84" y="34" width="68" height="2" rx="1" opacity=".5"/><rect fill="#333" x="84" y="40" width="60" height="2" rx="1" opacity=".4"/><rect fill="#333" x="84" y="46" width="66" height="2" rx="1" opacity=".3"/>
    <rect fill="#8b2252" x="8" y="68" width="144" height=".5" opacity=".3"/>`,
  terminal: `<rect fill="#0a0a0a" width="160" height="100" rx="4"/>
    <rect fill="#1a1a1a" x="0" y="0" width="160" height="12" rx="4"/><circle fill="#ff5f57" cx="8" cy="6" r="2.5"/><circle fill="#febc2e" cx="16" cy="6" r="2.5"/><circle fill="#28c840" cx="24" cy="6" r="2.5"/>
    <rect fill="#33ff33" x="8" y="18" width="12" height="3" rx="1" opacity=".8"/><rect fill="#33ff33" x="24" y="18" width="60" height="3" rx="1" opacity=".4"/>
    <rect fill="#33ff33" x="8" y="26" width="8" height="2" rx="1" opacity=".6"/><rect fill="#33ff33" x="20" y="26" width="80" height="2" rx="1" opacity=".3"/>
    <rect fill="#33ff33" x="8" y="32" width="8" height="2" rx="1" opacity=".6"/><rect fill="#33ff33" x="20" y="32" width="50" height="2" rx="1" opacity=".3"/>
    <rect fill="#33ff33" x="8" y="42" width="4" height="3" rx="1" opacity=".9"/><rect fill="#33ff33" x="14" y="42" width="1" height="3" opacity=".5"/>`,
  "data-table": `<rect fill="#f8fafc" width="160" height="100" rx="4"/>
    <rect fill="#16a34a" x="0" y="0" width="160" height="10" rx="4"/><rect fill="#fff" x="6" y="3" width="30" height="4" rx="1" opacity=".8"/>
    <rect fill="#e2e8f0" x="4" y="16" width="152" height="8"/><rect fill="#64748b" x="8" y="18" width="24" height="4" rx="1" opacity=".5"/><rect fill="#64748b" x="48" y="18" width="30" height="4" rx="1" opacity=".5"/><rect fill="#64748b" x="96" y="18" width="20" height="4" rx="1" opacity=".5"/>
    <rect fill="#fff" x="4" y="26" width="152" height="8"/><rect fill="#334155" x="8" y="28" width="30" height="4" rx="1" opacity=".3"/><rect fill="#334155" x="48" y="28" width="24" height="4" rx="1" opacity=".3"/>
    <rect fill="#f1f5f9" x="4" y="36" width="152" height="8"/><rect fill="#334155" x="8" y="38" width="28" height="4" rx="1" opacity=".3"/>
    <rect fill="#fff" x="4" y="46" width="152" height="8"/>`,
  feed: `<rect fill="#15202b" width="160" height="100" rx="4"/>
    <circle fill="#1d9bf0" cx="16" cy="16" r="6" opacity=".7"/><rect fill="#e7e9ea" x="28" y="12" width="30" height="3" rx="1"/><rect fill="#71767b" x="28" y="18" width="20" height="2" rx="1" opacity=".6"/>
    <rect fill="#71767b" x="28" y="26" width="100" height="2" rx="1" opacity=".4"/><rect fill="#71767b" x="28" y="32" width="80" height="2" rx="1" opacity=".3"/>
    <rect fill="#2f3336" x="8" y="42" width="144" height=".5"/>
    <circle fill="#1d9bf0" cx="16" cy="54" r="6" opacity=".7"/><rect fill="#e7e9ea" x="28" y="50" width="24" height="3" rx="1"/><rect fill="#71767b" x="28" y="56" width="16" height="2" rx="1" opacity=".6"/>
    <rect fill="#1e3a4f" x="28" y="64" width="110" height="26" rx="6"/>`,
  corporate: `<rect fill="#fff" width="160" height="100" rx="4"/>
    <rect fill="#0f2b46" x="0" y="0" width="160" height="14" rx="4"/><rect fill="#fff" x="8" y="4" width="40" height="5" rx="1" opacity=".8"/>
    <rect fill="#0f2b46" x="12" y="22" width="80" height="5" rx="1"/><rect fill="#64748b" x="12" y="32" width="136" height="2" rx="1" opacity=".4"/><rect fill="#64748b" x="12" y="38" width="120" height="2" rx="1" opacity=".3"/>
    <rect fill="#f0f4f8" x="12" y="48" width="136" height="40" rx="2"/><rect fill="#0f2b46" x="16" y="52" width="40" height="3" rx="1" opacity=".3"/><rect fill="#64748b" x="16" y="60" width="100" height="2" rx="1" opacity=".3"/>`,
  academic: `<rect fill="#fefefe" width="160" height="100" rx="4"/>
    <rect fill="#374151" x="30" y="8" width="100" height="5" rx="1"/><rect fill="#6b7280" x="50" y="16" width="60" height="2" rx="1" opacity=".5"/>
    <rect fill="#374151" x="20" y="26" width="30" height="3" rx="1" opacity=".6"/>
    <rect fill="#4b5563" x="20" y="34" width="120" height="2" rx="1" opacity=".4"/><rect fill="#4b5563" x="20" y="40" width="118" height="2" rx="1" opacity=".35"/><rect fill="#4b5563" x="20" y="46" width="120" height="2" rx="1" opacity=".4"/><rect fill="#4b5563" x="20" y="52" width="100" height="2" rx="1" opacity=".35"/>
    <rect fill="#374151" x="20" y="62" width="25" height="3" rx="1" opacity=".6"/><rect fill="#4b5563" x="20" y="70" width="120" height="2" rx="1" opacity=".4"/>`,
  neon: `<rect fill="#0a0a1a" width="160" height="100" rx="4"/>
    <rect fill="#00f0ff" x="8" y="8" width="50" height="5" rx="1" opacity=".8"/><rect fill="#ff00ff" x="8" y="16" width="30" height="2" rx="1" opacity=".5"/>
    <rect fill="#00f0ff" x="8" y="26" width="144" height=".5" opacity=".3"/>
    <rect fill="#1a1a3e" x="8" y="32" width="68" height="40" rx="4" stroke="#00f0ff" stroke-width=".5" opacity=".6"/><rect fill="#00f0ff" x="14" y="36" width="30" height="3" rx="1" opacity=".5"/>
    <rect fill="#1a1a3e" x="84" y="32" width="68" height="40" rx="4" stroke="#ff00ff" stroke-width=".5" opacity=".6"/><rect fill="#ff00ff" x="90" y="36" width="30" height="3" rx="1" opacity=".5"/>
    <rect fill="#00f0ff" x="8" y="80" width="144" height="12" rx="3" opacity=".1"/><rect fill="#00f0ff" x="14" y="84" width="40" height="3" rx="1" opacity=".4"/>`,
  minimal: `<rect fill="#fafafa" width="160" height="100" rx="4"/>
    <rect fill="#111" x="30" y="12" width="100" height="5" rx="1"/><rect fill="#6b7280" x="50" y="22" width="60" height="2" rx="1" opacity=".4"/>
    <rect fill="#e5e7eb" x="30" y="32" width="100" height=".5"/>
    <rect fill="#374151" x="30" y="42" width="100" height="2" rx="1" opacity=".5"/><rect fill="#374151" x="30" y="48" width="96" height="2" rx="1" opacity=".4"/><rect fill="#374151" x="30" y="54" width="100" height="2" rx="1" opacity=".5"/><rect fill="#374151" x="30" y="60" width="80" height="2" rx="1" opacity=".4"/>
    <rect fill="#e5e7eb" x="30" y="70" width="100" height=".5"/>`,
  jupyter: `<rect fill="#fff" width="160" height="100" rx="4"/>
    <rect fill="#f57c00" x="0" y="0" width="160" height="10" rx="4"/><rect fill="#fff" x="6" y="3" width="24" height="4" rx="1" opacity=".8"/>
    <rect fill="#f5f5f5" x="4" y="16" width="152" height="24" rx="3" stroke="#e0e0e0" stroke-width=".5"/><rect fill="#f57c00" x="4" y="16" width="3" height="24" rx="1"/><rect fill="#333" x="14" y="20" width="60" height="2" rx="1" opacity=".4"/><rect fill="#333" x="14" y="26" width="80" height="2" rx="1" opacity=".3"/><rect fill="#333" x="14" y="32" width="50" height="2" rx="1" opacity=".3"/>
    <rect fill="#f5f5f5" x="4" y="46" width="152" height="24" rx="3" stroke="#e0e0e0" stroke-width=".5"/><rect fill="#42a5f5" x="4" y="46" width="3" height="24" rx="1"/><rect fill="#333" x="14" y="50" width="70" height="2" rx="1" opacity=".4"/>`,
  slide: `<rect fill="#1e1b4b" width="160" height="100" rx="4"/>
    <rect fill="#312e81" x="4" y="4" width="152" height="72" rx="4"/>
    <rect fill="#818cf8" x="20" y="16" width="80" height="6" rx="1" opacity=".8"/><rect fill="#a5b4fc" x="20" y="28" width="120" height="2" rx="1" opacity=".4"/><rect fill="#a5b4fc" x="20" y="34" width="100" height="2" rx="1" opacity=".3"/>
    <rect fill="#818cf8" x="20" y="46" width="50" height="16" rx="3" opacity=".2"/><rect fill="#818cf8" x="78" y="46" width="50" height="16" rx="3" opacity=".2"/>
    <circle fill="#818cf8" cx="74" cy="84" r="3" opacity=".5"/><circle fill="#818cf8" cx="82" cy="84" r="3" opacity=".8"/><circle fill="#818cf8" cx="90" cy="84" r="3" opacity=".5"/>`,
};

function renderStylePicker(
  currentStyle: string,
  allStyles: string[],
  generatedStyles: string[],
): string {
  const allSet = new Set(allStyles);

  function renderItem(s: string): string {
    const desc = STYLE_DESCRIPTIONS[s] ?? s;
    const color = STYLE_COLORS[s] ?? "#888";
    const isCurrent = s === currentStyle;
    const isReady = generatedStyles.includes(s);
    const badge = isCurrent
      ? `<span class="style-badge">current</span>`
      : isReady
        ? `<span class="style-badge style-badge-ready">ready</span>`
        : "";
    const preview = STYLE_PREVIEWS[s] ?? "";
    const previewAttr = preview
      ? ` data-preview="${esc(preview)}"`
      : "";
    return `<button class="style-opt${isCurrent ? " active" : ""}" data-style="${esc(s)}" data-ready="${isReady ? "true" : "false"}" title="${esc(desc)}"${previewAttr}><span class="style-dot" style="background:${color}"></span><span class="style-info"><span class="style-name">${esc(s)}</span><span class="style-desc">${esc(desc)}</span></span>${badge}</button>`;
  }

  const parts: string[] = [];
  const rendered = new Set<string>();

  for (const group of STYLE_GROUPS) {
    const items = group.styles.filter((s) => allSet.has(s));
    if (items.length === 0) continue;
    parts.push(`<div class="style-group-label">${esc(group.label)}</div>`);
    for (const s of items) {
      parts.push(renderItem(s));
      rendered.add(s);
    }
  }

  // Any styles not in a group (e.g., user-created custom styles)
  const ungrouped = allStyles.filter((s) => !rendered.has(s));
  if (ungrouped.length > 0) {
    parts.push(`<div class="style-group-label">Custom</div>`);
    for (const s of ungrouped) {
      parts.push(renderItem(s));
    }
  }

  return parts.join("\n");
}

/**
 * Renders the row 2 HTML for the default template toolbar extension.
 * Contains: font picker, accent color picker, width picker, text size picker.
 * Injected at runtime via window.__RPT_TOOLBAR.row2Html.
 */
function renderDefaultRow2Html(): string {
  return `<div class="ftb-group ftb-font-group">
      <button id="ftb-font-btn" class="ftb-btn ftb-dropdown-btn" title="Change font family" aria-expanded="false">
        <span class="ftb-icon">Aa</span>
        <span class="font-label ftb-label">System</span>
        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><polyline points="6 9 12 15 18 9"/></svg>
      </button>
      ${renderFontMenu()}
    </div>
    <div class="ftb-group color-picker">
      <button id="ftb-color-btn" class="ftb-btn" title="Change accent color">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
          <circle cx="13.5" cy="6.5" r=".5"/><circle cx="17.5" cy="10.5" r=".5"/>
          <circle cx="8.5" cy="7.5" r=".5"/><circle cx="6.5" cy="12.5" r=".5"/>
          <path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z"/>
        </svg>
        <span class="ftb-label">Color</span>
      </button>
      <div id="ftb-color-menu" class="color-menu">
        <div class="font-group-label">Accent Color</div>
        <div class="color-swatches">
          <button class="color-swatch" data-accent="indigo"  style="--swatch:#6366f1" title="Indigo"></button>
          <button class="color-swatch" data-accent="violet"  style="--swatch:#8b5cf6" title="Violet"></button>
          <button class="color-swatch" data-accent="purple"  style="--swatch:#a855f7" title="Purple"></button>
          <button class="color-swatch" data-accent="fuchsia" style="--swatch:#d946ef" title="Fuchsia"></button>
          <button class="color-swatch" data-accent="pink"    style="--swatch:#ec4899" title="Pink"></button>
          <button class="color-swatch" data-accent="rose"    style="--swatch:#f43f5e" title="Rose"></button>
          <button class="color-swatch" data-accent="red"     style="--swatch:#ef4444" title="Red"></button>
          <button class="color-swatch" data-accent="orange"  style="--swatch:#f97316" title="Orange"></button>
          <button class="color-swatch" data-accent="amber"   style="--swatch:#f59e0b" title="Amber"></button>
          <button class="color-swatch" data-accent="yellow"  style="--swatch:#eab308" title="Yellow"></button>
          <button class="color-swatch" data-accent="lime"    style="--swatch:#84cc16" title="Lime"></button>
          <button class="color-swatch" data-accent="emerald" style="--swatch:#10b981" title="Emerald"></button>
          <button class="color-swatch" data-accent="teal"    style="--swatch:#14b8a6" title="Teal"></button>
          <button class="color-swatch" data-accent="cyan"    style="--swatch:#06b6d4" title="Cyan"></button>
          <button class="color-swatch" data-accent="sky"     style="--swatch:#0ea5e9" title="Sky"></button>
          <button class="color-swatch" data-accent="blue"    style="--swatch:#3b82f6" title="Blue"></button>
        </div>
      </div>
    </div>
    <span class="ftb-sep"></span>
    <div class="ftb-group width-picker" title="Content width">
      <button class="width-btn" data-width="sm" title="Small (640px)">SM</button>
      <button class="width-btn active" data-width="md" title="Medium (960px)">MD</button>
      <button class="width-btn" data-width="lg" title="Large (1200px)">LG</button>
      <button class="width-btn" data-width="xl" title="Full width">XL</button>
    </div>
    <div class="ftb-group text-size-picker" title="Text size">
      <button class="text-size-btn" data-dir="down" title="Decrease text size">A&minus;</button>
      <span class="text-size-label">100%</span>
      <button class="text-size-btn" data-dir="up" title="Increase text size">A+</button>
    </div>`;
}

/**
 * Renders the unified floating toolbar widget used by ALL templates.
 * Row 1 (always visible): theme toggle, copy-for, print, style picker.
 * Row 2 (optional): populated at runtime via window.__RPT_TOOLBAR.row2Html + row2Init().
 * Print button delegates to window.__RPT_TOOLBAR.print() if defined, else window.print().
 * Uses unique IDs (ftb-theme-btn, ftb-print-btn) to avoid conflicts with template nav buttons.
 */
function renderFloatingToolbar(
  currentStyle: string,
  generatedStyles: string[],
): string {
  const allStyles = listStyles();
  const pickerItems = renderStylePicker(currentStyle, allStyles, generatedStyles);

  return `
<!-- Unified floating toolbar -->
<div class="floating-toolbar" id="floating-toolbar">
  <div class="ftb-row ftb-row-2" id="ftb-row-2" style="display:none"></div>
  <div class="ftb-row ftb-row-1">
    <button id="ftb-theme-btn" class="ftb-btn" title="Toggle light/dark theme">🌙</button>
    <span class="ftb-sep"></span>
    <div class="ftb-group copy-for-picker" id="copy-for-wrap">
      <button id="copy-for-btn" class="ftb-btn ftb-dropdown-btn" title="Copy report content" aria-expanded="false">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
          <rect x="9" y="9" width="13" height="13" rx="2" ry="2"/>
          <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>
        </svg>
        <span class="ftb-label">Copy</span>
        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><polyline points="6 9 12 15 18 9"/></svg>
      </button>
      <div id="copy-for-menu" class="copy-for-menu">
        <button class="copy-for-opt" data-format="notion"><span class="copy-for-icon">N</span><span class="copy-for-label">Copy for Notion</span></button>
        <button class="copy-for-opt" data-format="slack"><span class="copy-for-icon">#</span><span class="copy-for-label">Copy for Slack</span></button>
        <button class="copy-for-opt" data-format="markdown"><span class="copy-for-icon">M&darr;</span><span class="copy-for-label">Copy as Markdown</span></button>
      </div>
    </div>
    <button id="ftb-print-btn" class="ftb-btn" title="Print report">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
        <polyline points="6 9 6 2 18 2 18 9"/>
        <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/>
        <rect x="6" y="14" width="12" height="8"/>
      </svg>
    </button>
    <span class="ftb-sep"></span>
    <div class="ftb-group style-picker" id="style-picker-wrap">
      <button id="style-picker-btn" class="ftb-btn ftb-dropdown-btn" title="Switch report style" aria-expanded="false">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
          <rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/>
          <rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/>
        </svg>
        <span class="ftb-label">${esc(currentStyle)}</span>
        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><polyline points="6 9 12 15 18 9"/></svg>
      </button>
      <div id="style-menu" class="style-menu">
        ${pickerItems}
      </div>
      <div id="style-preview-float" class="style-preview-float" aria-hidden="true">
        <svg viewBox="0 0 160 100" xmlns="http://www.w3.org/2000/svg"></svg>
      </div>
    </div>
  </div>
</div>
<script>
(function() {
  var root = document.documentElement;

  // ── Theme button ─────────────────────────────────────────────────────────
  var themeBtn = document.getElementById('ftb-theme-btn');
  function syncThemeIcon() {
    if (themeBtn) themeBtn.textContent = root.classList.contains('light') ? '☀️' : '🌙';
  }
  syncThemeIcon();
  if (themeBtn) {
    themeBtn.addEventListener('click', function() {
      root.classList.toggle('light');
      // Sync inverse dark class for templates that use html.dark (jupyter)
      if (root.classList.contains('light')) {
        root.classList.remove('dark');
      } else {
        root.classList.add('dark');
      }
      syncThemeIcon();
      try { localStorage.setItem('rpt-theme', root.classList.contains('light') ? 'light' : 'dark'); } catch(e){}
      // Notify templates that coordinate on a shared theme event
      root.dispatchEvent(new CustomEvent('rpt:theme-change', { detail: { theme: root.classList.contains('light') ? 'light' : 'dark' } }));
    });
  }

  // ── Print button — delegates to __RPT_TOOLBAR.print() if registered ──────
  var printBtn = document.getElementById('ftb-print-btn');
  if (printBtn) {
    printBtn.addEventListener('click', function() {
      if (window.__RPT_TOOLBAR && typeof window.__RPT_TOOLBAR.print === 'function') {
        window.__RPT_TOOLBAR.print();
      } else {
        window.print();
      }
    });
  }

  // ── Close all toolbar dropdowns on outside click / Escape ─────────────────
  document.addEventListener('click', function() {
    document.querySelectorAll('.floating-toolbar .style-menu, .floating-toolbar .copy-for-menu, .floating-toolbar .font-menu, .floating-toolbar .color-menu').forEach(function(m) { m.classList.remove('open'); });
  });
  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
      document.querySelectorAll('.floating-toolbar .style-menu, .floating-toolbar .copy-for-menu, .floating-toolbar .font-menu, .floating-toolbar .color-menu').forEach(function(m) { m.classList.remove('open'); });
    }
  });

  // ── DOMContentLoaded: inject row 2, init shared RPT features ─────────────
  document.addEventListener('DOMContentLoaded', function() {
    // Inject row 2 from __RPT_TOOLBAR if provided by the template
    var row2 = document.getElementById('ftb-row-2');
    if (row2 && window.__RPT_TOOLBAR && window.__RPT_TOOLBAR.row2Html) {
      row2.innerHTML = window.__RPT_TOOLBAR.row2Html;
      row2.style.display = '';
      if (typeof window.__RPT_TOOLBAR.row2Init === 'function') {
        window.__RPT_TOOLBAR.row2Init();
      }
    }
    // Init shared __RPT features
    if (window.__RPT) {
      if (window.__RPT.initStylePicker) window.__RPT.initStylePicker('#style-picker-btn', '#style-menu');
      if (window.__RPT.initProgressBar) window.__RPT.initProgressBar();
      if (window.__RPT.initScrollToTop) window.__RPT.initScrollToTop();
      if (window.__RPT.initTextSize) window.__RPT.initTextSize('main,.content,article,.notebook,.slide-container', 'rpt-text-size');
      if (window.__RPT.initCopyForMenu) window.__RPT.initCopyForMenu('#copy-for-btn', '#copy-for-menu');
    }
  });
})();
</script>`;
}

/** Assemble the complete self-contained HTML page for the report. */
export function buildHtml(
  data: ReportData,
  currentStyle = "default",
  generatedStyles: string[] = [],
  outputDir = "",
): string {
  const allStyles = listStyles();
  const navHtml = `<ul><li class="nav-group">Sections</li>${renderNav(data.nav)}</ul>`;
  const contentHtml = data.sections.map(renderSection).join("\n");
  const statsStr = computeStats(data);

  const ogDesc = esc(data.subtitle ?? statsStr);

  return `<!DOCTYPE html>
<html lang="en" class="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<script>
// Restore saved theme before first paint to prevent flash
(function(){try{var t=localStorage.getItem('rpt-theme');if(t==='dark'){document.documentElement.classList.remove('light');document.documentElement.classList.add('dark');}}catch(e){}})();
</script>
<title>${esc(data.title)}</title>
<meta property="og:title" content="${esc(data.title)}">
<meta property="og:description" content="${ogDesc}">
<meta property="og:type" content="article">
<meta name="twitter:card" content="summary">
<meta name="twitter:title" content="${esc(data.title)}">
<meta name="twitter:description" content="${ogDesc}">
<script src="https://cdn.tailwindcss.com"></script>
<script>tailwind.config = { darkMode: "class", corePlugins: { preflight: false } };</script>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="${GOOGLE_FONTS_URL}" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.css" crossorigin="anonymous">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.js" crossorigin="anonymous"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/contrib/auto-render.min.js" crossorigin="anonymous"></script>
<link rel="stylesheet" href="./styles.css">
</head>
<body>

<!-- Header -->
<header class="fixed inset-x-0 top-0 z-50 flex flex-wrap items-start gap-x-4 gap-y-1 px-5 py-3
               bg-[var(--surface)] border-b border-[var(--border)]"
        style="min-height:var(--header-h)">

  <button id="sidebar-toggle" class="sidebar-toggle" title="Toggle sidebar (⌘B)" aria-label="Toggle sidebar">
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
  </button>

  <div class="flex-1 min-w-0 flex flex-col justify-center" title="${esc(data.title)}${data.subtitle ? " — " + esc(data.subtitle ?? "") : ""}">
    <div class="hdr-title">${esc(data.title)}</div>
    ${data.subtitle ? `<div class="hdr-subtitle">${esc(data.subtitle)}</div>` : ""}
  </div>

  <div class="search-wrap" title="Search report content (⌘K)">
    <span class="search-icon">
      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round">
        <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
      </svg>
    </span>
    <input type="text" id="search" placeholder="Search… (⌘K)" autocomplete="off" spellcheck="false">
    <span id="search-count"></span>
  </div>

  <span class="hdr-gen" title="Generated ${esc(data.generated)} · ${statsStr}">Generated ${esc(data.generated)} · ${statsStr}</span>
</header>

<!-- Layout -->
<div id="rpt-layout" class="flex" style="margin-top:var(--header-h);min-height:calc(100vh - var(--header-h))">

  <nav class="sidebar shrink-0 bg-[var(--surface)] border-r border-[var(--border)]"
       style="position:sticky;top:var(--header-h);height:calc(100vh - var(--header-h));overflow-y:auto;padding:12px 0 24px;width:var(--sidebar-w)">
    ${navHtml}
  </nav>

  <main class="content grow min-w-0" style="padding:48px 64px;max-width:960px">
    ${contentHtml}
    <div id="no-results">No sections match your search — try different terms.</div>
  </main>

</div>

<!-- Code preview dialog -->
<dialog id="code-dialog">
  <div class="dlg-header">
    <span class="dlg-lang"></span>
    <span class="dlg-title"></span>
    <div class="dlg-actions">
      <span class="dlg-lines"></span>
      <button class="dlg-copy">Copy</button>
      <button class="dlg-close" aria-label="Close">✕</button>
    </div>
  </div>
  <div class="dlg-body"></div>
</dialog>

<script>
window.__RPT_CURRENT_STYLE = ${JSON.stringify(currentStyle)};
window.__RPT_GENERATED_STYLES = ${JSON.stringify(generatedStyles)};
window.__RPT_REPORT_DIR = ${JSON.stringify(outputDir)};
window.__RPT_DEFAULT_ROW2_HTML = ${JSON.stringify(renderDefaultRow2Html())};
</script>
<script src="./report.js" defer></script>
<script>
document.addEventListener("DOMContentLoaded", function() {
  if (typeof renderMathInElement !== "undefined") {
    renderMathInElement(document.body, {
      delimiters: [
        { left: "$$", right: "$$", display: true },
        { left: "$", right: "$", display: false },
        { left: "\\\\(", right: "\\\\)", display: false },
        { left: "\\\\[", right: "\\\\]", display: true }
      ],
      throwOnError: false
    });
  }
});
</script>
${renderFloatingToolbar(currentStyle, generatedStyles)}
</body>
</html>`;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Minimal launcher page listing links to all generated styles. */
function buildLauncherHtml(data: ReportData, styles: string[]): string {
  const cards = styles
    .map((s) => {
      const desc = STYLE_DESCRIPTIONS[s] ?? s;
      return `<a href="./${esc(s)}/index.html" class="sc"><strong>${esc(s)}</strong><span>${esc(desc)}</span></a>`;
    })
    .join("\n");
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(data.title)} — All Styles</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:system-ui,sans-serif;background:#0f0f17;color:#e2e8f0;min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:48px 24px;gap:16px}
h1{font-size:1.4rem;font-weight:700}
p{color:#64748b;font-size:0.85rem}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:12px;width:100%;max-width:860px;margin-top:8px}
.sc{display:block;background:#1a1a2e;border:1px solid #2d2d44;border-radius:10px;padding:18px 20px;text-decoration:none;color:inherit;transition:border-color 0.15s,transform 0.15s}
.sc:hover{border-color:#6366f1;transform:translateY(-2px)}
.sc strong{display:block;font-size:0.9rem;margin-bottom:5px;color:#a5b4fc}
.sc span{font-size:0.75rem;color:#64748b}
</style>
</head>
<body>
<h1>${esc(data.title)}</h1>
<p>Select a style to view this report</p>
<div class="grid">
${cards}
</div>
</body>
</html>`;
}

/** Write data.json alongside an already-written report. */
function writeSharedOutputs(outputDir: string, data: ReportData): void {
  writeFileSync(
    join(outputDir, "data.json"),
    JSON.stringify(data, null, 2),
    "utf8",
  );
}

/**
 * Inline external CSS/JS references into the HTML string, producing a
 * single self-contained file. External CDN references (Google Fonts,
 * KaTeX, Tailwind) are left as-is — they enhance the page but the
 * report is functional without them.
 */
function inlineAssets(html: string, css: string, js: string): string {
  let result = html;
  // Inline CSS: <link rel="stylesheet" href="./styles.css"> → <style>
  // Use function replacer to avoid $-sequence interpretation in CSS content
  result = result.replace(
    /<link\s+rel="stylesheet"\s+href="\.\/styles\.css"\s*\/?>/,
    () => (css ? `<style>\n${css}\n</style>` : ""),
  );
  // Inline JS: remove the original <script defer> tag and inject the code
  // before </body>. The `defer` attribute only works on external scripts;
  // inline <script> blocks run immediately when parsed. Placing the inlined
  // script at end-of-body ensures all DOM elements exist when it executes.
  if (js) {
    // Remove the original script tag from <head>
    result = result.replace(
      /<script\s+src="\.\/report\.js"\s+defer><\/script>/,
      () => "",
    );
    // Inject before </body> so DOM is fully parsed
    result = result.replace(
      /<\/body>/,
      () => `<script>\n${js}\n</script>\n</body>`,
    );
  } else {
    result = result.replace(
      /<script\s+src="\.\/report\.js"\s+defer><\/script>/,
      () => "",
    );
  }
  return result;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

function loadData(raw: unknown): ReportData {
  try {
    return validate(raw);
  } catch (e) {
    console.error(
      `Error: Invalid report data structure.\n` +
        `Validation failed: ${(e as Error).message}\n\n` +
        `Fix the JSON and try again.`,
    );
    process.exit(1);
  }
}

/** List available style names by scanning the styles/ directory. */
export function listStyles(): string[] {
  const stylesDir = join(SKILL_DIR, "styles");
  const builtIn = ["default"];
  if (!existsSync(stylesDir)) return builtIn;
  const dirs = readdirSync(stylesDir, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name);
  return [...builtIn, ...dirs];
}

/** Render a single style, returning the html/css/js strings. */
async function renderStyle(
  data: ReportData,
  styleName: string,
  sharedCss: string,
  sharedJs: string,
  generatedStyles: string[] = [],
  outputDir = "",
): Promise<{ html: string; css: string; js: string }> {
  if (styleName === "default") {
    return {
      html: buildHtml(data, styleName, generatedStyles, outputDir),
      css:
        sharedCss +
        "\n\n" +
        readFileSync(join(SKILL_DIR, "styles.css"), "utf8"),
      js:
        sharedJs + "\n\n" + readFileSync(join(SKILL_DIR, "report.js"), "utf8"),
    };
  }

  const styleDir = join(SKILL_DIR, "styles", styleName);
  if (!existsSync(styleDir)) {
    console.error(`Error: Style "${styleName}" not found at "${styleDir}"`);
    console.error(`Available styles: ${listStyles().join(", ")}`);
    process.exit(1);
  }

  const templatePath = join(styleDir, "template.ts");
  if (!existsSync(templatePath)) {
    console.error(`Error: Style "${styleName}" is missing template.ts`);
    process.exit(1);
  }

  const styleMod = await import(templatePath);
  if (typeof styleMod.buildHtml !== "function") {
    console.error(
      `Error: Style "${styleName}" template.ts must export a buildHtml(data) function`,
    );
    process.exit(1);
  }

  const styleCss = existsSync(join(styleDir, "style.css"))
    ? readFileSync(join(styleDir, "style.css"), "utf8")
    : "";
  const styleJs = existsSync(join(styleDir, "style.js"))
    ? readFileSync(join(styleDir, "style.js"), "utf8")
    : "";
  const rawHtml = styleMod.buildHtml(data);
  const globalsScript = `<script>\nwindow.__RPT_CURRENT_STYLE = ${JSON.stringify(styleName)};\nwindow.__RPT_GENERATED_STYLES = ${JSON.stringify(generatedStyles)};\nwindow.__RPT_REPORT_DIR = ${JSON.stringify(outputDir)};\n</script>`;
  const htmlWithGlobals = rawHtml.includes("</head>")
    ? rawHtml.replace("</head>", globalsScript + "\n</head>")
    : rawHtml + globalsScript;
  // Inject unified floating toolbar for all templates.
  // Row 1 provides: theme, copy-for, print, style-picker (universal cross-template features).
  // Row 2 is populated at runtime via window.__RPT_TOOLBAR.row2Html registered by each template's JS.
  const floatingToolbar = renderFloatingToolbar(styleName, generatedStyles);
  const html = htmlWithGlobals.includes("</body>")
    ? htmlWithGlobals.replace("</body>", floatingToolbar + "\n</body>")
    : htmlWithGlobals + floatingToolbar;
  return {
    html,
    css: sharedCss + "\n\n" + styleCss,
    js: sharedJs + "\n\n" + styleJs,
  };
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  let jsonPath: string | undefined;
  let outputPath: string | undefined;
  let styleName = "default";
  let allStylesMode = false;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--style" && args[i + 1]) {
      styleName = args[i + 1];
      i++;
    } else if (args[i] === "--all-styles") {
      allStylesMode = true;
    } else if (!jsonPath) {
      jsonPath = args[i];
    } else if (!outputPath) {
      outputPath = args[i];
    }
  }

  if (!jsonPath || !outputPath) {
    console.error(
      "Usage: npx tsx generate-html.ts <json_path> <output_html_path> [--style <name>] [--all-styles]",
    );
    console.error(`\nAvailable styles: ${listStyles().join(", ")}`);
    process.exit(1);
  }

  const resolvedJson = resolve(jsonPath);
  if (!existsSync(resolvedJson)) {
    console.error(`Error: JSON file not found at "${resolvedJson}"`);
    process.exit(1);
  }

  let raw: unknown;
  try {
    raw = JSON.parse(readFileSync(resolvedJson, "utf8"));
  } catch (e) {
    console.error(`Error: Failed to parse JSON.\n${(e as Error).message}`);
    process.exit(1);
  }

  const data = loadData(raw);

  // Load shared assets (prepended to every style's CSS/JS)
  const sharedCss = existsSync(join(SKILL_DIR, "shared-base.css"))
    ? readFileSync(join(SKILL_DIR, "shared-base.css"), "utf8")
    : "";
  const sharedJs = existsSync(join(SKILL_DIR, "shared.js"))
    ? readFileSync(join(SKILL_DIR, "shared.js"), "utf8")
    : "";

  const resolvedOutput = resolve(outputPath);
  const outputDir = dirname(resolvedOutput);
  mkdirSync(outputDir, { recursive: true });
  // When called via restyle-report.sh, input is <root>/data.json → root dir is its dirname.
  // When called initially, input is a temp file → root is outputDir itself.
  const reportRootDir =
    basename(resolvedJson) === "data.json" ? dirname(resolvedJson) : outputDir;

  if (allStylesMode) {
    // Support both a directory path and a filename (e.g. /out/index.html) as output target.
    // When outputPath ends in .html, use its dirname; otherwise treat it as the output dir.
    const baseDir = resolvedOutput.toLowerCase().endsWith(".html")
      ? outputDir
      : resolvedOutput;
    mkdirSync(baseDir, { recursive: true });
    const styles = listStyles();
    for (const style of styles) {
      const styleOutDir = join(baseDir, style);
      mkdirSync(styleOutDir, { recursive: true });
      const { html, css, js } = await renderStyle(
        data,
        style,
        sharedCss,
        sharedJs,
        styles,
        reportRootDir,
      );
      // Single self-contained HTML file — CSS and JS inlined
      writeFileSync(
        join(styleOutDir, "index.html"),
        inlineAssets(html, css, js),
        "utf8",
      );
      console.info(`  ✓ ${style}/`);
    }
    // Write launcher at root
    writeFileSync(join(baseDir, "index.html"), buildLauncherHtml(data, styles), "utf8");
    writeSharedOutputs(baseDir, data);
    console.info(`✓ All ${styles.length} styles written to: ${baseDir}/`);
    console.info(`  Launcher: ${join(baseDir, "index.html")}`);
    console.info(`  Switch styles without Claude:`);
    console.info(
      `  bash ~/.claude/skills/create-report/restyle-report.sh ${baseDir} terminal`,
    );
  } else {
    // Single style — self-contained HTML with CSS/JS inlined
    const { html, css, js } = await renderStyle(
      data,
      styleName,
      sharedCss,
      sharedJs,
      [],
      reportRootDir,
    );
    writeFileSync(resolvedOutput, inlineAssets(html, css, js), "utf8");
    // Only write data.json at the root (skip when generating a substyle subdir via restyle-report.sh)
    if (outputDir === reportRootDir) writeSharedOutputs(reportRootDir, data);
    console.info(
      `✓ Report written to: ${resolvedOutput} (style: ${styleName})`,
    );
    console.info(`  data.json saved — switch styles without Claude:`);
    console.info(
      `  bash ~/.claude/skills/create-report/restyle-report.sh ${reportRootDir} terminal`,
    );
  }
}

// Only run CLI when this file is the entry point (not when imported by style templates)
const _entryFile = process.argv[1] ? resolve(process.argv[1]) : "";
const _thisFile = fileURLToPath(import.meta.url);
if (_entryFile === _thisFile) {
  main();
}
