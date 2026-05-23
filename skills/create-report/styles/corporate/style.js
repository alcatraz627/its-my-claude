/**
 * Corporate report interactivity
 * Uses shared __RPT modules + local TOC toggle / print / section numbering
 */

(function () {
  "use strict";

  // ─── TOC toggle ────────────────────────────────────────────────────────────
  const tocToggle = document.getElementById("toc-toggle");
  const tocList = document.getElementById("toc-list");

  if (tocToggle && tocList) {
    tocToggle.addEventListener("click", function () {
      const isCollapsed = tocList.classList.toggle("collapsed");
      tocToggle.textContent = isCollapsed ? "Show" : "Hide";
    });
  }

  // ─── Smooth scroll for anchor links ────────────────────────────────────────
  document.querySelectorAll('a[href^="#"]').forEach(function (link) {
    link.addEventListener("click", function (e) {
      var id = link.getAttribute("href");
      if (!id || id.length < 2) return;
      var target = document.getElementById(id.slice(1));
      if (!target) return;
      e.preventDefault();
      var top = target.getBoundingClientRect().top + window.scrollY - 24;
      window.scrollTo({ top: top, behavior: "smooth" });
      history.replaceState(null, "", id);
    });
  });

  // ─── Shared module initialization ──────────────────────────────────────────
  if (window.__RPT) {
    // Theme toggle — corporate defaults to light
    __RPT.initThemeToggle('.theme-toggle', { defaultTheme: 'light' });

    // Code dialog for expand buttons
    __RPT.initCodeDialog('#code-dialog');

    // Copy buttons on code blocks
    __RPT.initCopyButtons('.copy-btn');

    // Search
    __RPT.initSearch('#search', '#search-count', '#no-results', '.report-section');

    // Width picker
    __RPT.initWidthPicker('.report', 'corporate-width');

    // External links open in new tab
    __RPT.openExternalLinks();

    // Inline code path:line coloring
    __RPT.initCodePaths();
  }

  // ─── KaTeX math rendering ─────────────────────────────────────────────────
  document.addEventListener("DOMContentLoaded", function () {
    if (window.__RPT) {
      __RPT.initMath();
    }
  });

  // ── Toolbar interface ─────────────────────────────────────────────────────
  window.__RPT_TOOLBAR = {
    print: function() { window.print(); },
    row2Html: window.__RPT_DEFAULT_ROW2_HTML || '',
    row2Init: function() {
      if (window.__RPT && __RPT.initWidthPicker) {
        __RPT.initWidthPicker('.report', 'corporate-width');
      }
    },
  };
})();
