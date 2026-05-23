import type { ReportData, Section, Block } from "../../generate-html.ts";
import { esc, highlight, renderBlock, computeStats, countBlocksOfType } from "../../generate-html.ts";

const FAVICON =
  "data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'><rect width='32' height='32' rx='16' fill='%231d9bf0'/><path d='M8 18c0-3.3 2.7-6 6-6h1v-2l4 3-4 3v-2h-1a4 4 0 0 0-4 4v1H8v-1zm16-4c0 3.3-2.7 6-6 6h-1v2l-4-3 4-3v2h1a4 4 0 0 0 4-4v-1h2v1z' fill='%23fff'/></svg>";

const GOOGLE_FONTS_URL =
  "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap";

/** Convert a section heading into a hashtag: "Executive Summary" -> "#ExecutiveSummary" */
function toHashtag(heading: string): string {
  return (
    "#" +
    heading
      .replace(/[^a-zA-Z0-9\s]/g, "")
      .split(/\s+/)
      .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
      .join("")
  );
}

/** Generate a fake relative timestamp from section index. */
function fakeTimestamp(index: number, total: number): string {
  if (index === 0) return "just now";
  if (index === 1) return "2m";
  const minutes = index * 3 + Math.floor(index * 1.5);
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h`;
  return `${Math.floor(hours / 24)}d`;
}

/** Determine the @tag for a section based on its content types. */
function sectionTag(section: Section): string {
  const hasTable = countBlocksOfType(section.blocks, ["table"]) > 0;
  const hasCode = countBlocksOfType(section.blocks, ["code"]) > 0;
  const hasMath = countBlocksOfType(section.blocks, ["math"]) > 0;
  if (hasTable) return "@data";
  if (hasCode) return "@code";
  if (hasMath) return "@math";
  return "@report";
}

/** Render a single block, wrapping certain types in feed-specific containers. */
function renderFeedBlock(block: Block): string {
  switch (block.type) {
    case "blockquote":
      // Quoted-tweet style
      return `<div class="quoted-post">
        <div class="quoted-border"></div>
        <div class="quoted-content">${block.html}</div>
      </div>`;
    case "code":
      return `<div class="snippet-card code-wrap">
        <div class="snippet-header">
          <span class="snippet-lang code-lang">${esc(block.lang) || "text"}</span>
          <div class="snippet-actions">
            <button class="copy-btn" title="Copy code">Copy</button>
            <button class="code-expand" title="Expand">Expand</button>
          </div>
        </div>
        <pre><code>${highlight(block.content, block.lang)}</code></pre>
      </div>`;
    case "table":
      return `<div class="data-card">
        <table>
          <thead><tr>${block.headers.map((h) => `<th>${esc(h)}</th>`).join("")}</tr></thead>
          <tbody>${block.rows.map((r) => `<tr>${r.map((c) => `<td>${c}</td>`).join("")}</tr>`).join("")}</tbody>
        </table>
      </div>`;
    case "ul":
      return `<div class="thread-replies"><ul>${block.items.map((i) => `<li>${i}</li>`).join("")}</ul></div>`;
    case "ol":
      return `<div class="thread-replies"><ol>${block.items.map((i, idx) => `<li>${i}</li>`).join("")}</ol></div>`;
    case "subsection":
    case "subsubsection": {
      const tag = block.level === 3 ? "h3" : "h4";
      const hashtag = toHashtag(block.heading);
      return `<div class="thread-reply" id="${esc(block.id)}">
        <${tag}>${esc(block.heading)}</${tag}>
        <span class="hashtag">${esc(hashtag)}</span>
        ${block.blocks.map(renderFeedBlock).join("\n")}
      </div>`;
    }
    default:
      return renderBlock(block);
  }
}

/** Render a section as a feed post card. */
function renderPostCard(section: Section, index: number, total: number): string {
  const hashtag = toHashtag(section.heading);
  const timestamp = fakeTimestamp(index, total);
  const tag = sectionTag(section);
  const likeCount = Math.floor(section.blocks.length * 3 + index * 7 + 12);
  const retweetCount = Math.floor(section.blocks.length + index * 2 + 3);
  const replyCount = section.blocks.filter(
    (b) => b.type === "subsection" || b.type === "subsubsection"
  ).length;

  const avatarUrl = `https://api.dicebear.com/7.x/pixel-art/svg?seed=${encodeURIComponent(section.id)}`;
  const blocksHtml = section.blocks.map(renderFeedBlock).join("\n");

  return `<article class="post-card" data-section-id="${esc(section.id)}">
  <div class="timeline-connector"></div>
  <div class="post-inner">
    <img class="post-avatar-img" src="${avatarUrl}" alt="" width="40" height="40" loading="lazy">
    <div class="post-body">
      <div class="post-header">
        <span class="post-handle">${esc(tag)}</span>
        <span class="post-dot">&middot;</span>
        <span class="post-time">${esc(timestamp)}</span>
      </div>
      <h2 id="${esc(section.id)}">${esc(section.heading)}</h2>
      <div class="post-content">
        ${blocksHtml}
      </div>
      <div class="post-hashtag">${esc(hashtag)}</div>
      <div class="post-actions">
        <button class="action-btn action-reply" title="Replies">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
          </svg>
          <span>${replyCount || ""}</span>
        </button>
        <button class="action-btn action-retweet" title="Repost">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="17 1 21 5 17 9"/><path d="M3 11V9a4 4 0 0 1 4-4h14"/>
            <polyline points="7 23 3 19 7 15"/><path d="M21 13v2a4 4 0 0 1-4 4H3"/>
          </svg>
          <span>${retweetCount}</span>
        </button>
        <button class="action-btn action-like" title="Like">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
          </svg>
          <span>${likeCount}</span>
        </button>
        <button class="action-btn action-share" title="Share">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
            <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/>
            <polyline points="16 6 12 2 8 6"/><line x1="12" y1="2" x2="12" y2="15"/>
          </svg>
        </button>
      </div>
    </div>
  </div>
</article>`;
}

/** Build TOC sidebar entries. */
function buildTocHtml(sections: Section[]): string {
  return sections
    .map(
      (s) =>
        `<li class="toc-item"><a class="toc-link" href="#${esc(s.id)}" data-section-id="${esc(s.id)}">${esc(s.heading)}</a></li>`
    )
    .join("\n");
}

export function buildHtml(data: ReportData): string {
  const statsStr = computeStats(data);
  const ogDesc = esc(data.subtitle ?? statsStr);

  const postsHtml = data.sections
    .map((section, i) => renderPostCard(section, i, data.sections.length))
    .join("\n");

  const tocHtml = buildTocHtml(data.sections);

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
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.css" crossorigin="anonymous">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.js" crossorigin="anonymous"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/contrib/auto-render.min.js" crossorigin="anonymous"></script>
<link rel="stylesheet" href="./styles.css">
</head>
<body>

<!-- Code expand dialog -->
<dialog id="code-dialog">
  <div class="dlg-header">
    <span class="dlg-lang">text</span>
    <span class="dlg-title">Code preview</span>
    <div class="dlg-actions">
      <span class="dlg-lines"></span>
      <button class="dlg-copy">Copy</button>
      <button class="dlg-close">Close</button>
    </div>
  </div>
  <div class="dlg-body"></div>
</dialog>

<!-- TOC Toggle -->
<button class="toc-toggle" id="toc-toggle" title="Toggle contents">
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/>
  </svg>
</button>

<!-- TOC Sidebar -->
<nav class="toc-sidebar" id="toc-sidebar">
  <div class="toc-header">Contents</div>
  <ul class="toc-list">
    ${tocHtml}
  </ul>
</nav>

<!-- Top bar -->
<header class="top-bar">
  <div class="top-bar-inner">
    <div class="top-bar-left">
      <div class="bar-info">
        <span class="bar-title">${esc(data.title)}</span>
        ${data.subtitle ? `<span class="bar-subtitle">${esc(data.subtitle)}</span>` : ""}
      </div>
    </div>
    <div class="top-bar-right">
      <div class="search-wrap">
        <svg class="search-icon" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round">
          <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
        </svg>
        <input type="text" id="search" placeholder="Search posts..." autocomplete="off" spellcheck="false">
        <span id="search-count"></span>
      </div>
      <div class="width-picker">
        <button class="width-btn" data-width="sm">SM</button>
        <button class="width-btn" data-width="md">MD</button>
        <button class="width-btn active" data-width="lg">LG</button>
        <button class="width-btn" data-width="xl">XL</button>
      </div>
    </div>
  </div>
</header>

<!-- Feed -->
<main class="feed-container">
  <div class="feed-timeline">
    ${postsHtml}
  </div>
  <div id="no-results" class="no-results">No posts match your search.</div>
</main>

<!-- Footer with stats -->
<footer class="feed-footer">
  <span>${esc(data.generated)} &middot; ${esc(statsStr)}</span>
</footer>

<script src="./report.js" defer></script>
</body>
</html>`;
}
