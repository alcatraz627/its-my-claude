/**
 * Minimal-style report interactivity
 * - Theme toggle (light default, dark optional)
 * - Code dialog expand
 * - Copy buttons on code blocks (hover-reveal)
 * - Width picker (SM/MD/LG)
 * - Math rendering (KaTeX)
 * - External links open in new tab
 * - Inline code path coloring
 * - Search filtering with highlight
 * - Smooth scroll for TOC links
 * - Floating mini-toolbar fade-in on scroll
 */

(function () {
  "use strict";

  // ─── Shared module init ─────────────────────────────────────────────────────
  if (window.__RPT) {
    __RPT.initThemeToggle(".theme-toggle", {
      storageKey: "rpt-theme",
      defaultTheme: "light",
    });
    __RPT.initCodeDialog("#code-dialog");
    __RPT.initCopyButtons(".copy-btn");
    __RPT.initWidthPicker(".page", "minimal-width");
    __RPT.openExternalLinks();
    __RPT.initCodePaths();
  }

  // ─── Math init ──────────────────────────────────────────────────────────────
  document.addEventListener("DOMContentLoaded", function () {
    if (window.__RPT) {
      __RPT.initMath();
    }
  });

  // ─── DOM refs ───────────────────────────────────────────────────────────────
  const searchInput = document.getElementById("search");
  const searchCount = document.getElementById("search-count");
  const tocBar = document.querySelector(".toc-bar");
  const sections = document.querySelectorAll("section[data-section-id]");
  const miniToolbar = document.getElementById("mini-toolbar");

  // ─── Smooth scroll for TOC links ────────────────────────────────────────────
  document.querySelectorAll('a[href^="#"]').forEach(function (link) {
    link.addEventListener("click", function (e) {
      var id = link.getAttribute("href");
      if (!id) return;
      id = id.slice(1);
      var target = document.getElementById(id);
      if (!target) return;
      e.preventDefault();
      var offset = (tocBar ? tocBar.offsetHeight : 0) + 16;
      var top = target.getBoundingClientRect().top + window.scrollY - offset;
      window.scrollTo({ top: top, behavior: "smooth" });
      history.replaceState(null, "", "#" + id);
      // Collapse TOC after clicking
      var details = document.getElementById("toc-details");
      if (details) details.removeAttribute("open");
    });
  });

  // ─── Floating toolbar: show on scroll ───────────────────────────────────────
  var scrollTick = false;
  window.addEventListener("scroll", function () {
    if (!scrollTick) {
      requestAnimationFrame(function () {
        if (miniToolbar) {
          if (window.scrollY > 200) {
            miniToolbar.classList.add("visible");
          } else {
            miniToolbar.classList.remove("visible");
          }
        }
        scrollTick = false;
      });
      scrollTick = true;
    }
  });

  // ─── Search ─────────────────────────────────────────────────────────────────
  var searchTimeout;
  var MARK_CLASS = "search-hit";

  function clearMarks() {
    document.querySelectorAll("mark." + MARK_CLASS).forEach(function (m) {
      var parent = m.parentNode;
      if (parent) {
        parent.replaceChild(document.createTextNode(m.textContent || ""), m);
        parent.normalize();
      }
    });
  }

  function highlightText(node, regex) {
    if (node.nodeType === Node.TEXT_NODE) {
      var text = node.textContent || "";
      if (!regex.test(text)) return 0;
      regex.lastIndex = 0;
      var frag = document.createDocumentFragment();
      var last = 0;
      var count = 0;
      var match;
      while ((match = regex.exec(text)) !== null) {
        if (match.index > last) {
          frag.appendChild(
            document.createTextNode(text.slice(last, match.index)),
          );
        }
        var mark = document.createElement("mark");
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
      var children = Array.from(node.childNodes);
      var count = 0;
      for (var i = 0; i < children.length; i++) {
        count += highlightText(children[i], regex);
      }
      return count;
    }
    return 0;
  }

  function doSearch(query) {
    clearMarks();
    var noResults = document.getElementById("no-results");

    if (!query.trim()) {
      sections.forEach(function (s) {
        s.classList.remove("search-hidden");
      });
      if (searchCount) searchCount.textContent = "";
      if (noResults) noResults.classList.remove("visible");
      return;
    }

    var escaped = query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    var regex = new RegExp("(" + escaped + ")", "gi");
    var totalHits = 0;
    var visibleSections = 0;

    sections.forEach(function (section) {
      var hits = highlightText(section, regex);
      if (hits > 0) {
        section.classList.remove("search-hidden");
        totalHits += hits;
        visibleSections++;
      } else {
        section.classList.add("search-hidden");
      }
    });

    if (searchCount) {
      searchCount.textContent =
        totalHits > 0 ? totalHits + " found" : "0 found";
    }
    if (noResults) {
      if (visibleSections === 0) {
        noResults.classList.add("visible");
      } else {
        noResults.classList.remove("visible");
      }
    }
  }

  if (searchInput) {
    searchInput.addEventListener("input", function () {
      clearTimeout(searchTimeout);
      searchTimeout = setTimeout(function () {
        doSearch(searchInput.value);
      }, 200);
    });

    // Cmd/Ctrl+K to focus search
    document.addEventListener("keydown", function (e) {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        // Open TOC if closed
        var details = document.getElementById("toc-details");
        if (details && !details.open) details.setAttribute("open", "");
        searchInput.focus();
        searchInput.select();
      }
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
        __RPT.initWidthPicker('.page', 'minimal-width');
      }
    },
  };
})();
