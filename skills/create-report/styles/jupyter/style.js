/**
 * Jupyter-style report interactivity
 * - Theme toggle (light/dark)
 * - Code dialog expand
 * - Copy buttons on code blocks
 * - Width picker for notebook content
 * - Math rendering (KaTeX)
 * - External links open in new tab
 * - Inline code path coloring
 * - Search filtering with highlight
 * - Cell selection (blue left border)
 * - Run button animation per code cell
 * - Sidebar nav with scroll spy
 * - Print button
 */

(function () {
  "use strict";

  function onReady(fn) {
    if (document.readyState !== "loading") fn();
    else document.addEventListener("DOMContentLoaded", fn);
  }

  onReady(function () {
    var R = window.__RPT;
    if (!R) return;

    R.initThemeToggle(".theme-toggle", {
      storageKey: "rpt-theme",
      defaultTheme: "light",
      darkClass: "dark",
    });
    R.initCodeDialog("#code-dialog");
    R.initCopyButtons(".copy-btn");
    R.initWidthPicker(".notebook", "jupyter-width");
    R.initMath();
    R.openExternalLinks();
    R.initCodePaths();
    R.initSearch(
      "#search",
      "#search-count",
      "#no-results",
      "section[data-section-id]",
    );

    // Text size (shared utility — uses .text-size-btn[data-dir] convention)
    if (R.initTextSize) R.initTextSize(".notebook", "jupyter-text-size");

    // Custom jupyter features
    initCellSelection();
    initCellCollapse();
    initRunButtons();
    initSidebarNav();
    initSmoothScroll();
    initSidebarToggle();
    initSaveBtn();
  });

  /** Click a cell to "select" it — adds blue left border */
  function initCellSelection() {
    var cells = document.querySelectorAll(".nb-cell");
    cells.forEach(function (cell) {
      cell.addEventListener("click", function () {
        // Deselect all other cells
        document
          .querySelectorAll(".nb-cell.cell-selected")
          .forEach(function (c) {
            if (c !== cell) c.classList.remove("cell-selected");
          });
        cell.classList.toggle("cell-selected");
      });
    });
  }

  /** Click prompt area to collapse/expand cell content */
  function initCellCollapse() {
    document.querySelectorAll(".cell-prompt").forEach(function (prompt) {
      prompt.addEventListener("click", function (e) {
        e.stopPropagation();
        var cell = prompt.closest(".nb-cell");
        if (cell) cell.classList.toggle("cell-collapsed");
      });
    });
  }

  /** Click run button on code cells — brief "executed" animation */
  function initRunButtons() {
    var btns = document.querySelectorAll(".cell-run-btn");
    btns.forEach(function (btn) {
      btn.addEventListener("click", function (e) {
        e.stopPropagation();
        btn.classList.remove("running");
        // Force reflow to restart animation
        void btn.offsetWidth;
        btn.classList.add("running");
        setTimeout(function () {
          btn.classList.remove("running");
        }, 700);
      });
    });
  }

  /** Sidebar scroll spy and smooth scrolling */
  function initSidebarNav() {
    var toolbar = document.getElementById("nb-toolbar");
    var links = document.querySelectorAll(".nb-nav-link");
    var sections = document.querySelectorAll("section[data-section-id]");
    if (!links.length || !sections.length) return;

    function updateActive() {
      var offset = (toolbar ? toolbar.offsetHeight : 0) + 40;
      var activeId = "";

      sections.forEach(function (sec) {
        var rect = sec.getBoundingClientRect();
        if (rect.top <= offset) {
          activeId = sec.getAttribute("data-section-id") || "";
        }
      });

      links.forEach(function (link) {
        var href = link.getAttribute("href");
        if (href && href.slice(1) === activeId) {
          link.classList.add("active");
        } else {
          link.classList.remove("active");
        }
      });
    }

    var scrollTick = false;
    window.addEventListener("scroll", function () {
      if (!scrollTick) {
        requestAnimationFrame(function () {
          updateActive();
          scrollTick = false;
        });
        scrollTick = true;
      }
    });
    updateActive();
  }

  /** Smooth scroll for anchor links */
  function initSmoothScroll() {
    var toolbar = document.getElementById("nb-toolbar");
    document.querySelectorAll('a[href^="#"]').forEach(function (link) {
      link.addEventListener("click", function (e) {
        var id = link.getAttribute("href");
        if (!id || id.length < 2) return;
        var target = document.getElementById(id.slice(1));
        if (!target) return;
        e.preventDefault();
        var offset = (toolbar ? toolbar.offsetHeight : 0) + 16;
        var top = target.getBoundingClientRect().top + window.scrollY - offset;
        window.scrollTo({ top: top, behavior: "smooth" });
        history.replaceState(null, "", id);
      });
    });
  }

  /** Toggle sidebar visibility */
  function initSidebarToggle() {
    var btn = document.getElementById("nb-sidebar-toggle");
    var layout = document.querySelector(".nb-layout");
    if (!btn || !layout) return;
    try { if (localStorage.getItem("jupyter-sidebar") === "collapsed") layout.classList.add("sidebar-collapsed"); } catch (_) {}
    btn.addEventListener("click", function () {
      layout.classList.toggle("sidebar-collapsed");
      try { localStorage.setItem("jupyter-sidebar", layout.classList.contains("sidebar-collapsed") ? "collapsed" : "open"); } catch (_) {}
    });
  }

  /** Save HTML to disk */
  function initSaveBtn() {
    var btn = document.getElementById("nb-save-btn");
    if (!btn) return;
    btn.addEventListener("click", function () {
      var html = "<!DOCTYPE html>\n" + document.documentElement.outerHTML;
      var blob = new Blob([html], { type: "text/html" });
      var a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = (document.title || "notebook") + ".html";
      a.click();
      URL.revokeObjectURL(a.href);
    });
  }

  // ── Toolbar interface ─────────────────────────────────────────────────────
  window.__RPT_TOOLBAR = {
    print: function() { window.print(); },
    row2Html: window.__RPT_DEFAULT_ROW2_HTML || '',
    row2Init: function() {
      if (window.__RPT && __RPT.initWidthPicker) {
        __RPT.initWidthPicker('.notebook', 'jupyter-width');
      }
    },
  };
})();
