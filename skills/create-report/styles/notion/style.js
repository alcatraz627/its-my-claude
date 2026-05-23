/**
 * Notion-style report interactivity
 * - Theme toggle (light/dark)
 * - Code dialog expand
 * - Copy buttons on code blocks
 * - Width picker for page content
 * - Math rendering (KaTeX)
 * - External links open in new tab
 * - Inline code path coloring
 * - Search filtering with highlight
 * - Scroll-aware nav link activation with auto-scroll
 * - Smooth scroll for anchor links
 */

(function () {
  "use strict";

  // ─── Shared module init ─────────────────────────────────────────────────────
  if (window.__RPT) {
    __RPT.initCodeDialog('#code-dialog');
    __RPT.initCopyButtons('.copy-btn');
    __RPT.initWidthPicker('.page', 'notion-width');
    __RPT.openExternalLinks();
    __RPT.initCodePaths();
  }

  // ─── Math init (needs DOMContentLoaded for KaTeX scripts to load) ─────────
  document.addEventListener("DOMContentLoaded", function () {
    if (window.__RPT) {
      __RPT.initMath();
    }
  });

  // ─── DOM refs ──────────────────────────────────────────────────────────────
  const searchInput = document.getElementById("search");
  const searchCount = document.getElementById("search-count");
  const jumpBar = document.getElementById("jump-bar");
  const jumpLinksContainer = document.getElementById("jump-links");
  const cards = document.querySelectorAll(".card");
  const jumpLinks = jumpBar ? jumpBar.querySelectorAll(".jump-links a") : [];

  // ─── Smooth scroll for nav links ──────────────────────────────────────────
  document.querySelectorAll('a[href^="#"]').forEach((link) => {
    link.addEventListener("click", (e) => {
      const id = link.getAttribute("href")?.slice(1);
      if (!id) return;
      const target = document.getElementById(id);
      if (!target) return;
      e.preventDefault();
      const offset = (jumpBar ? jumpBar.offsetHeight : 0) + 16;
      const top = target.getBoundingClientRect().top + window.scrollY - offset;
      window.scrollTo({ top, behavior: "smooth" });
      history.replaceState(null, "", `#${id}`);
    });
  });

  // ─── Scroll spy: highlight active nav link + auto-scroll into view ────────
  function updateActiveLink() {
    if (!jumpLinks.length) return;
    const offset = (jumpBar ? jumpBar.offsetHeight : 0) + 40;
    let activeId = "";

    cards.forEach((card) => {
      const section = card.querySelector("section[data-section-id]");
      if (!section) return;
      const rect = card.getBoundingClientRect();
      if (rect.top <= offset) {
        activeId = section.getAttribute("data-section-id") || "";
      }
    });

    jumpLinks.forEach((link) => {
      const href = link.getAttribute("href")?.slice(1);
      if (href === activeId) {
        link.classList.add("active");
        // Scroll the nav links container to bring active link into view
        if (jumpLinksContainer) {
          const containerRect = jumpLinksContainer.getBoundingClientRect();
          const linkRect = link.getBoundingClientRect();
          const scrollLeft = jumpLinksContainer.scrollLeft;
          const linkLeft = linkRect.left - containerRect.left + scrollLeft;
          const linkRight = linkLeft + linkRect.width;
          const containerWidth = containerRect.width;

          if (linkLeft < scrollLeft || linkRight > scrollLeft + containerWidth) {
            jumpLinksContainer.scrollTo({
              left: linkLeft - containerWidth / 2 + linkRect.width / 2,
              behavior: "smooth"
            });
          }
        }
      } else {
        link.classList.remove("active");
      }
    });
  }

  let scrollTick = false;
  window.addEventListener("scroll", () => {
    if (!scrollTick) {
      requestAnimationFrame(() => {
        updateActiveLink();
        scrollTick = false;
      });
      scrollTick = true;
    }
  });
  updateActiveLink();

  // ─── Search ───────────────────────────────────────────────────────────────
  let searchTimeout;
  const MARK_CLASS = "search-hit";

  function clearMarks() {
    document.querySelectorAll(`mark.${MARK_CLASS}`).forEach((m) => {
      const parent = m.parentNode;
      if (parent) {
        parent.replaceChild(document.createTextNode(m.textContent || ""), m);
        parent.normalize();
      }
    });
  }

  function highlightText(node, regex) {
    if (node.nodeType === Node.TEXT_NODE) {
      const text = node.textContent || "";
      if (!regex.test(text)) return 0;
      regex.lastIndex = 0;
      const frag = document.createDocumentFragment();
      let last = 0;
      let count = 0;
      let match;
      while ((match = regex.exec(text)) !== null) {
        if (match.index > last) {
          frag.appendChild(document.createTextNode(text.slice(last, match.index)));
        }
        const mark = document.createElement("mark");
        mark.className = MARK_CLASS;
        mark.textContent = match[0];
        frag.appendChild(mark);
        last = regex.lastIndex;
        count++;
      }
      if (last < text.length) {
        frag.appendChild(document.createTextNode(text.slice(last)));
      }
      if (count > 0 && node.parentNode) {
        node.parentNode.replaceChild(frag, node);
      }
      return count;
    }

    if (
      node.nodeType === Node.ELEMENT_NODE &&
      !/^(script|style|mark|input|textarea)$/i.test(node.tagName)
    ) {
      const children = Array.from(node.childNodes);
      let count = 0;
      for (const child of children) {
        count += highlightText(child, regex);
      }
      return count;
    }
    return 0;
  }

  function doSearch(query) {
    clearMarks();
    const noResults = document.getElementById("no-results");

    if (!query.trim()) {
      cards.forEach((c) => c.classList.remove("search-hidden"));
      if (searchCount) searchCount.textContent = "";
      if (noResults) noResults.classList.remove("visible");
      return;
    }

    const escaped = query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const regex = new RegExp(`(${escaped})`, "gi");
    let totalHits = 0;
    let visibleCards = 0;

    cards.forEach((card) => {
      const hits = highlightText(card, regex);
      if (hits > 0) {
        card.classList.remove("search-hidden");
        totalHits += hits;
        visibleCards++;
      } else {
        card.classList.add("search-hidden");
      }
    });

    if (searchCount) {
      searchCount.textContent = totalHits > 0 ? `${totalHits} found` : "0 found";
    }
    if (noResults) {
      if (visibleCards === 0) {
        noResults.classList.add("visible");
      } else {
        noResults.classList.remove("visible");
      }
    }
  }

  if (searchInput) {
    searchInput.addEventListener("input", () => {
      clearTimeout(searchTimeout);
      searchTimeout = setTimeout(() => doSearch(searchInput.value), 200);
    });

    // Cmd/Ctrl+K to focus search
    document.addEventListener("keydown", (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        searchInput.focus();
        searchInput.select();
      }
      // Escape to clear search
      if (e.key === "Escape" && document.activeElement === searchInput) {
        searchInput.value = "";
        doSearch("");
        searchInput.blur();
      }
    });
  }

  // ── Toolbar interface ─────────────────────────────────────────────────────
  window.__RPT_TOOLBAR = {
    print: function() { window.print(); },
    row2Html: window.__RPT_DEFAULT_ROW2_HTML || '',
    row2Init: function() {
      if (window.__RPT && __RPT.initWidthPicker) {
        __RPT.initWidthPicker('.page', 'notion-width');
      }
    },
  };
})();
