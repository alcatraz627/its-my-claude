# Report skeleton

The markup the report styles expect. Fill the shell once, render every content
block with the shared block markup, then wrap the sections in the body for the
chosen style. Class names matter: the CSS targets them.

Controls that needed the local generator's script are left out: search, width
picker, code expand dialog, font and accent pickers, sidebar collapse. Their
CSS is harmless when unused. Keep the theme toggle.

## 1. Shell

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{title}</title>
<!-- Optional, only when the page has math: -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.css">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.js"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/contrib/auto-render.min.js"
  onload="renderMathInElement(document.body,{delimiters:[{left:'$$',right:'$$',display:true},{left:'$',right:'$',display:false}],throwOnError:false})"></script>
<style>
/* paste references/styles/shared-base.css here, then references/styles/{style}.css */
</style>
</head>
<body>
<script>
(function () {
  var root = document.documentElement, body = document.body, saved = null;
  try { saved = localStorage.getItem('report-theme'); } catch (e) {}
  var mq = window.matchMedia('(prefers-color-scheme: light)');
  function apply(mode) {
    var light = mode === 'light';
    root.classList.toggle('light', light);
    root.classList.toggle('dark', !light);
    if (body.dataset.darkTheme) body.dataset.theme = light ? 'paper' : body.dataset.darkTheme;
  }
  apply(saved || (mq.matches ? 'light' : 'dark'));
  mq.addEventListener('change', function (e) { if (!saved) apply(e.matches ? 'light' : 'dark'); });
  window.toggleTheme = function () {
    saved = root.classList.contains('light') ? 'dark' : 'light';
    try { localStorage.setItem('report-theme', saved); } catch (e) {}
    apply(saved);
  };
})();
</script>
<!-- style body from section 3 -->
</body>
</html>
```

The toggle button, placed where each style body shows `{toggle}`:

```html
<button class="theme-toggle" type="button" onclick="toggleTheme()" aria-label="Switch dark and light">&#9680; Theme</button>
```

Fonts: a style names its web fonts in its CSS and falls back to system fonts.
To load them, add a Google Fonts `<link>` for the families the CSS names
(Inter, JetBrains Mono, Crimson Pro, Playfair Display, Merriweather, Space
Grotesk, Plus Jakarta Sans, IBM Plex Mono). The page works without them.

## 2. Block markup

Every style except terminal, feed and jupyter (which wrap these, see section
3) renders content blocks like this. `{id}` is the heading slug: lowercase,
spaces to `-`, other symbols dropped, `-2` appended on a repeat.

```html
<section data-section-id="{id}">
  <h2 id="{id}">{H2 text}</h2>
  <p>Inline: <strong>b</strong> <em>i</em> <code>code</code> <a href="https://...">link</a></p>
  <hr>
  <blockquote>{quote html}</blockquote>
  <ul><li>{item}</li></ul>   <ol><li>{item}</li></ol>
  <h3 id="{id}">{H3}</h3>    <h4 id="{id}">{H4}</h4>
  <div class="table-wrap"><table><thead><tr><th>A</th></tr></thead><tbody><tr><td>1</td></tr></tbody></table></div>
  <div class="code-wrap">
    <div class="code-header"><span class="code-lang">{lang or text}</span><span class="code-line-count">{n} lines</span></div>
    <pre><code>{escaped code with token spans}</code></pre>
  </div>
  <div class="tree-wrap">
    <details open class="tree-node"><summary><span class="tree-label tree-dir-label">src/</span> <span class="tree-desc">{desc}</span></summary>
      <div class="tree-children"><div class="tree-leaf"><span class="tree-label tree-file-label" data-ext="ts">main.ts</span></div></div>
    </details>
  </div>
  <div class="math-block">$$ {latex} $$</div>
</section>
```

- Code over 10 lines: `<pre class="has-line-nums"><code>` with each line as
  `<span class="line-row"><span class="line-num">{n}</span><span class="line-content">{line}</span></span>`.
- Syntax colour: wrap tokens in `<span class="kw">` keyword, `st` string,
  `cm` comment, `nm` number, `tp` type, `at` attribute, `op` operator,
  `fn` function. Escape `<`, `>` and `&` first.
- Only the top-level tree directory gets `open`. Use a tree for directory
  listings drawn with `├──`, and a list for anything flat.

## 3. Style bodies

`{sections}` is the section markup from part 2. `{stats}` is a short line such
as "8 sections · 3 tables". `{nav}` is one link per H2.

**default**
```html
<header style="position:fixed;inset:0 0 auto 0;z-index:50;display:flex;gap:16px;align-items:flex-start;padding:12px 20px;background:var(--surface);border-bottom:1px solid var(--border);min-height:var(--header-h)">
  <div style="flex:1;min-width:0"><div class="hdr-title">{title}</div><div class="hdr-subtitle">{subtitle}</div></div>
  <span class="hdr-gen">Generated {date} · {stats}</span> {toggle}
</header>
<div style="display:flex;margin-top:var(--header-h)">
  <nav class="sidebar" style="position:sticky;top:var(--header-h);height:calc(100vh - var(--header-h));overflow-y:auto;padding:12px 0 24px;width:var(--sidebar-w);flex-shrink:0;background:var(--surface);border-right:1px solid var(--border)">
    <ul><li class="nav-group">Sections</li>
      <li class="nav-section nav-h2"><a href="#{id}">{H2}</a><ul><li class="nav-section nav-h3"><a href="#{id}">{H3}</a></li></ul></li></ul>
  </nav>
  <main class="content" style="flex-grow:1;min-width:0;padding:48px 64px;max-width:960px">{sections}</main>
</div>
```

**notion**: wrap each section in `<div class="card">`.
```html
<nav class="jump-bar"><div class="breadcrumb">Report <span class="sep">/</span> <span class="crumb-title">{title}</span></div>
  <div class="jump-links"><a href="#{id}">{H2}</a></div><div class="nav-tools"><span class="report-stats">{stats}</span>{toggle}</div></nav>
<div class="page"><div class="title-block"><h1>{title}</h1><p class="subtitle">{subtitle}</p><div class="meta"><span>{date}</span><span>{stats}</span></div></div>
  <div class="card">{section}</div></div>
```

**minimal**
```html
<div class="toc-bar"><details><summary class="toc-toggle"><span>Contents</span></summary>
  <div class="toc-content"><ul class="toc-list"><li><a href="#{id}">{H2}</a><ul class="toc-children"><li><a href="#{id}">{H3}</a></li></ul></li></ul></div></details></div>
<main class="page"><header class="title-block"><h1>{title}</h1><p class="subtitle">{subtitle}</p><div class="meta"><span>{date}</span><span>{stats}</span>{toggle}</div></header>{sections}</main>
```

**academic** and **corporate** number sections in the heading: section `<section class="report-section" data-section-id="{id}"><h2 id="{id}"><span class="section-num">1.</span> {H2}</h2>`, subsection `<h3 id="{id}"><span class="section-num">1.1</span> {H3}</h3>`. Contents rows: `<li><a href="#{id}"><span class="toc-num">1.</span> {H2}</a><ul class="toc-sub"><li><a href="#{id}"><span class="toc-num">1.1</span> {H3}</a></li></ul></li>`. Corporate adds `<span class="toc-dots"></span>` before each `</a>`.
```html
<!-- academic -->
<div class="running-header"><span class="running-title">{title}</span>{toggle}</div>
<div class="paper"><header class="paper-header"><h1 class="paper-title">{title}</h1><div class="paper-meta"><span class="paper-date">{date}</span><span class="paper-stats">{stats}</span></div></header>
  <div class="abstract"><h2 class="abstract-heading">Abstract</h2><p class="abstract-text">{subtitle}</p></div><hr class="rule">
  <nav class="toc"><div class="toc-header"><h2>Contents</h2></div><ul class="toc-list">{rows}</ul></nav><hr class="rule">{sections}</div>

<!-- corporate: body gets data-watermark="CONFIDENTIAL" (or DRAFT), or no attribute for none -->
<div class="report"><header class="report-header"><h1>{title}</h1><p class="report-subtitle">{subtitle}</p>
  <div class="report-meta"><div class="meta-row"><span class="meta-label">DATE</span><span class="meta-value">{date}</span></div>
  <div class="meta-row"><span class="meta-label">CONTENTS</span><span class="meta-value">{stats}</span></div>
  <div class="meta-row"><span class="meta-label">PREPARED BY</span><span class="meta-value">{author}</span></div></div>{toggle}</header>
  <hr class="divider"><nav class="toc"><div class="toc-header"><h2>Table of Contents</h2></div><ul class="toc-list">{rows}</ul></nav><hr class="divider">{sections}</div>
```

**dashboard**: each section is an open accordion.
```html
<div class="header"><div class="header-top"><div class="header-title"><h1>{title}</h1><p>{subtitle or stats}</p></div>{toggle}</div></div>
<div class="layout"><nav class="sidebar"><div class="sidebar-label">Report Sections</div><a href="#{id}" class="active"><span class="icon">●</span> {H2}</a></nav>
  <main class="content">
    <div class="metrics"><div class="metric-card"><div class="label">Sections</div><div class="value">8</div><div class="sub">In this report</div></div><!-- 4 cards --></div>
    <a id="{id}"></a><details open><summary><span class="section-bar"></span><h2>{H2}</h2></summary><div class="section-content">{blocks}</div></details>
  </main></div>
```

**magazine**: the first section's blocks go inside `<div class="two-col">`, every section ends with `<div class="ornament">&bull; &bull; &bull;</div>`.
```html
<div class="top-bar"><div class="top-bar-left"></div><div class="top-bar-right">{toggle}</div></div>
<header class="hero"><h1>{title}</h1><p class="subtitle">{subtitle}</p><p class="report-stats">{stats}</p><p class="issue-info">Report No. {year}-Q{n} &middot; {month} {year}</p></header>
<main class="content">{sections}<footer class="footnotes"><span>Generated: {date}</span><span>{stats}</span></footer></main>
```

**terminal**: body is `<body data-theme="matrix" data-dark-theme="matrix">` (any dark palette name). The title needs its typing animation inline, with N the title length.
```html
<style>.report-title{animation:typing 2.4s steps(N,end) .5s forwards}@keyframes typing{from{width:0}to{width:Nch}}</style>
<div class="terminal-window"><div class="title-bar"><span class="dot close"></span><span class="dot minimize"></span><span class="dot maximize"></span>
  <span class="title-text">report.sh &mdash; bash</span><div class="title-bar-right">{toggle}</div></div>
  <div class="terminal-body content">
    <div style="display:flex;align-items:baseline"><div class="report-title">{title}</div><span class="cursor">&#x2588;</span></div>
    <div class="subtitle">&gt; {subtitle}</div><div class="system-stats">[sys] {stats}</div>
    <nav class="nav"><div class="prompt">&gt; ls sections/</div><div class="nav-links"><a href="#{id}">[01] {H2}</a></div></nav>
    <div class="section" id="{id}"><div class="section-header">=== [01] {H2} ===</div>{terminal blocks}</div>
  </div></div>
```
Terminal blocks: tables are ASCII art in `<div class="ascii-table"><pre>+----+\n| a  |\n+----+</pre></div>`, code is `<div class="code-block"><div class="code-label">// {lang}</div><pre><code>…</code></pre></div>`, list items are `<div class="term-list"><div class="term-list-item">- {item}</div></div>`, quotes are `<div class="blockquote">&gt; {line}</div>`, `hr` is `<div class="term-hr">────────</div>`, subsections are `<div class="subsection-header">--- {H3} ---</div>`, trees are `|-- ` and `\-- ` text in a code-block. Colour `[OK]` `[WARN]` `[FAIL]` with `<span class="status-ok|status-warn|status-fail">`.

**data-table**: one tab per H2, needs the tab script below.
```html
<header class="header-bar"><div class="header-content"><div class="header-left"><h1>{title}</h1></div><div class="header-right"><p class="header-subtitle">{subtitle}</p>{toggle}</div></div></header>
<div class="stats-bar"><div class="stats-inner"><span class="stat-item"><strong>3</strong> Tables</span><span class="stat-item stat-summary">{stats}</span></div></div>
<div class="tab-bar"><div class="tab-scroll"><button class="tab-btn active" data-tab="{id}">{H2}</button></div></div>
<main class="main-content"><div class="tab-panel active" data-panel="{id}" id="{id}"><div class="panel-header"><h2>{H2}</h2></div><div class="panel-body">{blocks}</div></div></main>
<script>document.querySelectorAll('.tab-btn').forEach(function(b){b.onclick=function(){document.querySelectorAll('.tab-btn,.tab-panel').forEach(function(e){e.classList.toggle('active',e.dataset.tab===b.dataset.tab||e.dataset.panel===b.dataset.tab)})}})</script>
```

**feed**: each H2 is a post. Use an inline SVG circle with an initial for the avatar, never a remote image.
```html
<header class="top-bar"><div class="top-bar-inner"><div class="top-bar-left"><div class="bar-info"><span class="bar-title">{title}</span><span class="bar-subtitle">{subtitle}</span></div></div><div class="top-bar-right">{toggle}</div></div></header>
<main class="feed-container"><div class="feed-timeline">
  <article class="post-card" data-section-id="{id}"><div class="timeline-connector"></div><div class="post-inner">
    <svg class="post-avatar-img" width="40" height="40" viewBox="0 0 40 40"><circle cx="20" cy="20" r="20" fill="var(--accent)"/><text x="20" y="26" text-anchor="middle" font-size="16" fill="#fff">D</text></svg>
    <div class="post-body"><div class="post-header"><span class="post-handle">@data</span><span class="post-dot">&middot;</span><span class="post-time">2m</span></div>
      <h2 id="{id}">{H2}</h2><div class="post-content">{feed blocks}</div><div class="post-hashtag">#{HeadingInCamelCase}</div></div></div></article>
</div></main><footer class="feed-footer"><span>{date} &middot; {stats}</span></footer>
```
Feed blocks: quotes are `<div class="quoted-post"><div class="quoted-border"></div><div class="quoted-content">…</div></div>`, code is `<div class="snippet-card code-wrap"><div class="snippet-header"><span class="snippet-lang code-lang">{lang}</span></div><pre><code>…</code></pre></div>`, tables are `<div class="data-card"><table>…</table></div>`, lists sit in `<div class="thread-replies">`, subsections are `<div class="thread-reply" id="{id}"><h3>{H3}</h3><span class="hashtag">#{H3}</span>{blocks}</div>`. Handle: `@data` with a table, `@code` with code, `@math` with math, else `@report`.

**jupyter**: every block is a cell. Counters `In [n]` and `Out[n]` run across the whole page.
```html
<div class="nb-toolbar"><div class="nb-toolbar-left"><div class="nb-toolbar-menu"><span class="nb-menu-item">File</span><span class="nb-menu-item">Edit</span><span class="nb-menu-item">View</span></div></div>
  <div class="nb-toolbar-right"><span class="nb-kernel-status">Python 3 | Idle</span>{toggle}</div></div>
<div class="nb-layout"><aside class="nb-sidebar"><div class="nb-sidebar-header"><span>Notebook</span></div>
  <nav class="nb-nav"><ul><li><a href="#{id}" class="nb-nav-link nb-nav-h2">{H2}</a><ul class="nb-nav-children"><li><a href="#{id}" class="nb-nav-link nb-nav-h3">{H3}</a></li></ul></li></ul></nav></aside>
  <main class="notebook"><div class="nb-header"><h1>{title}</h1><p class="nb-subtitle">{subtitle}</p><div class="nb-meta"><span>{date}</span> <span>{stats}</span></div></div>
    <div class="nb-cells"><section data-section-id="{id}">
      <div class="nb-cell nb-cell-markdown nb-cell-heading"><div class="cell-prompt cell-prompt-md"></div><div class="cell-content"><h2 id="{id}">{H2}</h2></div></div>
      <div class="nb-cell nb-cell-code"><div class="cell-prompt cell-prompt-in">In&nbsp;[1]:</div><div class="cell-content">{code-wrap}</div></div>
      <div class="nb-cell nb-cell-output"><div class="cell-prompt cell-prompt-out">Out[1]:</div><div class="cell-content">{table, math or tree}</div></div>
      <div class="nb-cell nb-cell-markdown"><div class="cell-prompt cell-prompt-md"></div><div class="cell-content">{paragraph, list, quote}</div></div>
    </section></div></main></div>
```

**neon**
```html
<div class="scanline-overlay"></div>
<header class="neon-header"><div class="header-top"><div class="header-title"><h1>{title}</h1><p class="subtitle">{subtitle}</p></div><div class="header-controls">{toggle}</div></div></header>
<div class="layout"><nav class="sidebar"><div class="sidebar-label">// SECTIONS</div><a href="#{id}" class="active"><span class="nav-indicator"></span><span class="nav-text">{H2}</span></a></nav>
  <main class="content"><section class="neon-section" data-section-id="{id}"><a id="{id}"></a>
    <div class="section-header"><div class="section-glow-bar"></div><h2>{H2}</h2></div><div class="section-content">{blocks}</div></section></main></div>
```

**slide**: the first section is the title slide. Scroll snapping moves between slides with no script.
```html
<div class="slide-container">
  <section class="slide slide--title" data-section-id="{id}" data-slide-index="0"><div class="slide-inner"><h2 id="{id}">{H2}</h2><div class="slide-content">{blocks}</div></div></section>
  <section class="slide" data-section-id="{id}" data-slide-index="1">…</section>
</div>
<nav class="slide-toc"><div class="toc-inner"><a class="toc-item active" href="#{id}">{H2}</a></div></nav>
<div class="toolbar">{toggle}</div>
```
Set an accent with `data-accent="emerald"` on `<html>`.
