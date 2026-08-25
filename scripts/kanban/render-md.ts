// The markdown the doc viewer, the charter modal and the editor preview all read.
//
// Hand-rolled and deliberately not full CommonMark: zero dependencies, and the
// owner's fence on it is "I don't want to overcomplicate just incrementally
// improv". It lives in its own file rather than inside server.ts because it is
// a pure function of its input and the only way to check it was to boot a second
// server on the live port. test/test-render.sh drives it directly.

export function renderMd(input: string): string {
  // \r is a line terminator in JS, so `.` never matches it: without this every
  // heading, list and table in a CRLF file falls through to a paragraph.
  const src = input.replace(/\r\n?/g, "\n");
  const esc = (s: string) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  // GFM, kept incremental on the owner's own fence ("I don't want to overcomplicate
  // just incrementally improv"): strikethrough, emphasis, bare-URL autolinks.
  //
  // Code spans are lifted OUT first and put back LAST. Replacing them in place is
  // not enough, and that is the whole reason for the detour: every later pass
  // still walks the produced string, so `~~x~~` inside backticks came back struck
  // through. Markup inside code must stay literal, or code cannot quote markup.
  // esc() is for TEXT nodes: it handles & < > and deliberately leaves quotes
  // alone, because a quote in prose is a quote. Every value below that lands
  // inside an HTML ATTRIBUTE needs the quote closed off as well, or the value
  // ends the attribute and starts a new one:
  //
  //   ![x" onerror="alert(1)](http://e/a.png)
  //     -> <img src="http://e/a.png" alt="x" onerror="alert(1)" ...>
  //
  // That is live JS, and it is reachable from any card note or draft body
  // through /api/mdpreview, which unlike /doc takes arbitrary client text.
  const attr = (v: string) => String(v).replace(/"/g, "&quot;").replace(/'/g, "&#39;");
  const inline = (s: string) => {
    const spans: string[] = [];
    let out = s.replace(/`([^`]+)`/g, (_m, code) => `\u0000${spans.push(code) - 1}\u0000`);
    out = out
      .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
      .replace(/~~([^~]+)~~/g, "<del>$1</del>")
      .replace(/(^|[\s(])\*([^*\s][^*]*)\*(?=[\s).,;:!?]|$)/g, "$1<em>$2</em>")
      // Images BEFORE links, because ![alt](src) contains [alt](src) and the
      // link rule would eat the inside and leave a stray "!".
      //
      // A relative path only means something relative to a document, and a note
      // has no document, so it says so inline rather than emitting a broken
      // <img>. An empty frame reads as "the image is missing"; this reads as
      // "there is nowhere to resolve this from", which is the true one.
      .replace(/!\[([^\]]*)\]\(([^)\s]+)\)/g, (_m: string, alt: string, src: string) =>
        /^(https?:)?\/\//.test(src) || src.startsWith("/")
          ? `<img src="${attr(src)}" alt="${attr(alt)}" loading="lazy" style="max-width:100%;height:auto;border-radius:8px">`
          : `<span class="cnote">image <code>${src}</code> is relative, and this surface has no document to resolve it from</span>`)
      .replace(/\[([^\]]+)\]\((https?:[^)]+)\)/g,
        (_m: string, text: string, href: string) => `<a href="${attr(href)}" rel="noopener">${text}</a>`)
      .replace(/(^|[\s(])(https?:\/\/[^\s<)]+)/g,
        (_m: string, lead: string, url: string) => `${lead}<a href="${attr(url)}" rel="noopener">${url}</a>`);
    return out.replace(/\u0000(\d+)\u0000/g, (_m, n) => `<code>${spans[Number(n)]}</code>`);
  };
  const out: string[] = [];
  // Blocks carry the source line they started on, so /doc?line=N can scroll to
  // the place a card was harvested from. The fence split eats one line per ```.
  let srcLine = 1;
  const anchor = (n: number) => ` id="L${n}"`;
  // split on line-initial fences only: a ``` inside inline code is not a fence,
  // and treating it as one swallowed the rest of the document into a <pre>
  src.replace(/<!--[\s\S]*?-->/g, "").split(/^[ \t]*```[^\n]*$/m).forEach((block, i) => {
    const blockStart = srcLine;
    srcLine += block.split("\n").length - 1;
    if (i % 2 === 1) { out.push(`<pre${anchor(blockStart)}><code>${esc(block.replace(/^[a-z]*\n/, ""))}</code></pre>`); return; }
    const lines = esc(block).split("\n");
    // esc() only rewrites &, < and >, never line count, so the two arrays
    // index together. A quote needs the raw text back: it is re-parsed as a
    // document, and re-escaping an already-escaped line yields "&amp;gt;".
    const rawLines = block.split("\n");
    let para: string[] = [];
    let paraLine = blockStart;
    let listLine = blockStart;
    let quoteLine = blockStart;
    // Lists nest, so this is a stack of open levels rather than one list. A flat
    // model silently rendered three levels of nesting as one run of siblings.
    type LItem = { text: string; kids: string };
    type Lvl = { tag: "ul" | "ol"; items: LItem[]; indent: number };
    let stack: Lvl[] = [];
    let table: string[][] | null = null;
    const flushPara = () => { if (para.length) { out.push(`<p${anchor(paraLine)}>${inline(para.join(" "))}</p>`); para = []; } };
    const renderLvl = (lv: Lvl, outer: boolean) =>
      `<${lv.tag}${outer ? anchor(listLine) : ""}>` +
      lv.items.map((it) => `<li>${inline(it.text)}${it.kids}</li>`).join("") +
      `</${lv.tag}>`;
    // close every level deeper than `keep`, folding each into its parent's last item
    const closeTo = (keep: number) => {
      while (stack.length > keep) {
        const lv = stack.pop()!;
        const html = renderLvl(lv, stack.length === 0);
        const p = stack[stack.length - 1];
        if (p && p.items.length) p.items[p.items.length - 1].kids += html;
        else out.push(html);
      }
    };
    const flushList = () => closeTo(0);
    // A table indented under a list item is that item's content. It used to
    // close the list instead, so a numbered procedure with a table under step 1
    // restarted at 1 on step 2 — two <ol> elements, both starting at one, which
    // reads as a renderer that cannot count. `kids` is the same slot nested
    // lists already fold into.
    let tableInList = false;
    const flushTable = () => {
      if (!table) return;
      const [head, ...rows] = table;
      const html =
        "<table><thead><tr>" + head.map((c) => `<th>${inline(c)}</th>`).join("") + "</tr></thead><tbody>" +
        rows.map((r) => "<tr>" + r.map((c) => `<td>${inline(c)}</td>`).join("") + "</tr>").join("") + "</tbody></table>";
      const host = stack[stack.length - 1];
      if (tableInList && host && host.items.length) host.items[host.items.length - 1].kids += html;
      else out.push(html);
      table = null; tableInList = false;
    };
    // Quotes were passing through as literal "> " text, and the docs carry 224
    // lines of them. The first fix rendered prose only, on the reasoning that no
    // quote in this repo held a list — true when written, false since
    // docs/SIMPLIFICATION-REPORT.md began quoting agents' replies verbatim and
    // one of them is numbered. So the body is re-parsed as its own document,
    // which costs one recursion and buys every construct at once.
    //
    // It terminates because each level strips its own "> " marker, so the inner
    // document is strictly shorter. Anchors are stripped from the inner render:
    // they would be a second id="L1" on the page, and the quote already carries
    // the outer one.
    let quote: string[] | null = null;
    const flushQuote = () => {
      if (!quote) return;
      const inner = renderMd(quote.join("\n")).replace(/ id="L\d+"/g, "");
      out.push(`<blockquote${anchor(quoteLine)}>${inner}</blockquote>`);
      quote = null;
    };
    const flushAll = () => { flushPara(); flushList(); flushTable(); flushQuote(); };
    for (const [idx, l] of lines.entries()) {
      const here = blockStart + idx;
      if (!para.length) paraLine = here;
      if (!stack.length) listLine = here;
      const h = l.match(/^(#{1,6}) (.*)$/);
      if (h) { flushAll(); out.push(`<h${h[1].length}${anchor(here)}>${inline(h[2])}</h${h[1].length}>`); continue; }
      // &gt;, not >: esc() runs on the whole block before this loop sees a line
      const bq = l.match(/^&gt;\s?(.*)$/);
      if (bq) {
        flushPara(); flushList(); flushTable();
        if (!quote) { quote = []; quoteLine = here; }
        // the RAW line, because flushQuote re-parses this as markdown
        quote.push((rawLines[idx] ?? "").replace(/^\s*>\s?/, ""));
        continue;
      }
      flushQuote();
      if (/^\s*\|.*\|\s*$/.test(l)) {
        flushPara();
        // Indented deeper than the item that opened the list, so it is the
        // item's content; keep the list open and let flushTable fold it in.
        const tIndent = (l.match(/^[ \t]*/)?.[0] ?? "").replace(/\t/g, "    ").length;
        if (stack.length && tIndent > stack[stack.length - 1].indent) tableInList = true;
        else flushList();
        const cells = l.trim().replace(/^\||\|$/g, "").split("|").map((c) => c.trim());
        // GFM requires ONE dash minimum in a separator row, not two. `| - | - |`
        // is valid and was being rendered as a literal data row of hyphens.
        if (cells.every((c) => /^:?-+:?$/.test(c))) continue; // separator row
        (table ??= []).push(cells);
        continue;
      }
      flushTable();
      const ol = l.match(/^\s*\d+\.\s+(.*)$/);
      const ul = l.match(/^\s*[-*]\s+(.*)$/);
      // A checkbox is what the harvester reads to mint a card, so a doc full of
      // them rendering as literal "[ ]" was the one gap worth closing here.
      const box = ul && ul[1].match(/^\[([ xX])\]\s+(.*)$/);
      if (ol || ul) {
        flushPara();
        const tag: "ul" | "ol" = ol ? "ol" : "ul";
        // depth is the leading whitespace; a tab counts as four columns
        const indent = (l.match(/^[ \t]*/)?.[0] ?? "").replace(/\t/g, "    ").length;
        if (!stack.length) { listLine = here; stack.push({ tag, items: [], indent }); }
        else {
          while (stack.length > 1 && indent < stack[stack.length - 1].indent) closeTo(stack.length - 1);
          const top = stack[stack.length - 1];
          if (indent > top.indent) stack.push({ tag, items: [], indent });
          else if (top.tag !== tag) { closeTo(stack.length - 1); stack.push({ tag, items: [], indent }); }
        }
        stack[stack.length - 1].items.push({ kids: "", text: box
          ? `<span class="tbox${box[1] === " " ? "" : " on"}">${box[1] === " " ? "" : "\u2713"}</span>${inline(box[2])}`
          : (ol ?? ul)![1] });
        continue;
      }
      // Setext: an underline of = or - promotes the paragraph above it. Checked
      // before the rule, because "---" under text is an h2 and only "---" on its
      // own is a horizontal rule. Docs written elsewhere arrive with these and
      // they used to render as body text, so the document lost its title.
      const setext = l.trim().match(/^(=+|-+)$/);
      if (setext && para.length) {
        const lvl = setext[1][0] === "=" ? 1 : 2;
        out.push(`<h${lvl}${anchor(paraLine)}>${inline(para.join(" "))}</h${lvl}>`);
        para = [];
        continue;
      }
      if (/^---+$/.test(l.trim())) { flushAll(); out.push("<hr>"); continue; }
      if (!l.trim()) { flushAll(); continue; }
      // A hard-wrapped list item continues on the following line; markdown calls
      // this a lazy continuation. Without it any wrapped bullet ENDED its list and
      // the rest of the sentence became a paragraph outside it, so a hard-wrapped
      // ordered list rendered as a run of one-item lists each numbered "1." with
      // its second half adrift. Every doc in this repo is wrapped at ~80 columns,
      // so this was the common case rather than an edge one.
      if (stack.length && stack[stack.length - 1].items.length) {
        const its = stack[stack.length - 1].items;
        its[its.length - 1].text += " " + l.trim();
        continue;
      }
      flushList();
      para.push(l.trim());
    }
    flushAll();
  });
  return out.join("\n");
}