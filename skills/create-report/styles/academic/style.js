/**
 * Academic report interactivity
 * Uses shared __RPT modules + local TOC toggle / print / scroll spy / search
 */

(function () {
  "use strict";

  // --- TOC toggle -----------------------------------------------------------
  var tocToggle = document.getElementById("toc-toggle");
  var tocList = document.getElementById("toc-list");

  if (tocToggle && tocList) {
    tocToggle.addEventListener("click", function () {
      var isCollapsed = tocList.classList.toggle("collapsed");
      tocToggle.textContent = isCollapsed ? "Show" : "Hide";
    });
  }

  // --- Smooth scroll for anchor links ---------------------------------------
  document.querySelectorAll('a[href^="#"]').forEach(function (link) {
    link.addEventListener("click", function (e) {
      var id = link.getAttribute("href");
      if (!id || id.length < 2) return;
      var target = document.getElementById(id.slice(1));
      if (!target) return;
      e.preventDefault();
      var top = target.getBoundingClientRect().top + window.scrollY - 48;
      window.scrollTo({ top: top, behavior: "smooth" });
      history.replaceState(null, "", id);
    });
  });

  // --- Scroll spy for running header ----------------------------------------
  function initScrollSpy() {
    var runningSection = document.querySelector(".running-section");
    if (!runningSection) return;

    var sections = document.querySelectorAll(".report-section");
    if (!sections.length) return;

    var ticking = false;
    window.addEventListener("scroll", function () {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(function () {
        var scrollY = window.scrollY + 80;
        var current = "";
        sections.forEach(function (sec) {
          if (sec.offsetTop <= scrollY) {
            var h2 = sec.querySelector("h2");
            if (h2) current = h2.textContent;
          }
        });
        runningSection.textContent = current;
        ticking = false;
      });
    });
  }

  // --- Shared module initialization -----------------------------------------
  function onReady(fn) {
    if (document.readyState !== "loading") fn();
    else document.addEventListener("DOMContentLoaded", fn);
  }

  onReady(function () {
    var R = window.__RPT;
    if (!R) return;

    // Theme toggle -- academic defaults to light
    R.initThemeToggle(".theme-toggle", { defaultTheme: "light" });

    // Code dialog for expand buttons
    R.initCodeDialog("#code-dialog");

    // Copy buttons on code blocks
    R.initCopyButtons(".copy-btn");

    // Width picker -- .paper is the main content container
    R.initWidthPicker(".paper", "academic-width");

    // KaTeX math rendering
    R.initMath();

    // External links open in new tab
    R.openExternalLinks();

    // Inline code path:line coloring
    R.initCodePaths();

    // Search
    R.initSearch("#search", "#search-count", "#no-results", ".report-section");

    // Scroll spy for running header
    initScrollSpy();
  });

  // ── Toolbar interface ─────────────────────────────────────────────────────
  window.__RPT_TOOLBAR = {
    print: function() { window.print(); },
    row2Html: window.__RPT_DEFAULT_ROW2_HTML || '',
    row2Init: function() {
      if (window.__RPT && __RPT.initWidthPicker) {
        __RPT.initWidthPicker('.paper', 'academic-width');
      }
    },
  };
})();
