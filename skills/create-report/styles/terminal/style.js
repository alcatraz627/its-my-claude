/**
 * Terminal style — report.js
 *
 * Handles:
 * - Smooth scroll for nav links
 * - Active section highlighting in nav
 * - Copy button for code blocks (if added)
 * - Keyboard navigation
 * - Theme switching
 * - Search, width picker, math, external links
 */

(function () {
  "use strict";

  // ─── Theme switcher ───────────────────────────────────────────────────────────

  var themeSelect = document.getElementById("theme-select");
  var savedTheme = (__RPT.store.getItem("terminal-theme")) || "matrix";

  function applyTheme(theme) {
    document.body.setAttribute("data-theme", theme);
    __RPT.store.setItem("terminal-theme", theme);
    if (themeSelect) themeSelect.value = theme;
  }

  applyTheme(savedTheme);

  if (themeSelect) {
    themeSelect.addEventListener("change", function () {
      applyTheme(themeSelect.value);
    });
  }

  // ─── Smooth scrolling for nav links ──────────────────────────────────────────

  document.querySelectorAll('.nav-links a[href^="#"]').forEach(function (link) {
    link.addEventListener("click", function (e) {
      e.preventDefault();
      var target = document.querySelector(this.getAttribute("href"));
      if (target) {
        target.scrollIntoView({ behavior: "smooth", block: "start" });
        // Update URL hash without jumping
        history.pushState(null, "", this.getAttribute("href"));
      }
    });
  });

  // ─── Active section tracking ─────────────────────────────────────────────────

  var sections = document.querySelectorAll(".section");
  var navLinks = document.querySelectorAll(".nav-links a");

  function updateActiveNav() {
    var scrollTop = window.scrollY + 120;
    var active = null;

    sections.forEach(function (section) {
      if (section.offsetTop <= scrollTop) {
        active = section.id;
      }
    });

    navLinks.forEach(function (link) {
      var href = link.getAttribute("href");
      if (href === "#" + active) {
        link.style.textShadow = "0 0 10px rgba(51, 255, 51, 0.7)";
        link.style.color = "";
        link.classList.add("active-nav");
      } else {
        link.style.textShadow = "";
        link.style.color = "";
        link.classList.remove("active-nav");
      }
    });
  }

  var scrollTimer;
  window.addEventListener("scroll", function () {
    if (scrollTimer) cancelAnimationFrame(scrollTimer);
    scrollTimer = requestAnimationFrame(updateActiveNav);
  });

  updateActiveNav();

  // ─── Copy button for code blocks ─────────────────────────────────────────────

  document.querySelectorAll(".code-block").forEach(function (block) {
    var pre = block.querySelector("pre");
    if (!pre) return;

    var btn = document.createElement("button");
    btn.className = "copy-btn";
    btn.textContent = "Copy";
    btn.style.cssText =
      "position:absolute;top:8px;right:8px;background:var(--term-border);color:var(--term-text);" +
      "border:1px solid var(--term-text);padding:2px 8px;font-size:11px;cursor:pointer;" +
      "font-family:inherit;opacity:0;transition:opacity 0.2s;border-radius:2px;";

    block.style.position = "relative";
    block.appendChild(btn);

    block.addEventListener("mouseenter", function () {
      btn.style.opacity = "1";
    });
    block.addEventListener("mouseleave", function () {
      btn.style.opacity = "0";
    });

    btn.addEventListener("click", function () {
      var code = pre.querySelector("code");
      var text = (code || pre).textContent || "";
      navigator.clipboard.writeText(text).then(function () {
        btn.textContent = "Copied!";
        btn.style.color = "var(--term-bright)";
        setTimeout(function () {
          btn.textContent = "Copy";
          btn.style.color = "var(--term-text)";
        }, 1500);
      });
    });
  });

  // ─── Keyboard shortcuts ──────────────────────────────────────────────────────

  document.addEventListener("keydown", function (e) {
    // Press 1-9 to jump to section
    if (!e.ctrlKey && !e.metaKey && !e.altKey) {
      var active = document.activeElement;
      if (active && (active.tagName === "INPUT" || active.tagName === "TEXTAREA" || active.tagName === "SELECT")) return;

      var num = parseInt(e.key, 10);
      if (num >= 1 && num <= sections.length) {
        e.preventDefault();
        sections[num - 1].scrollIntoView({ behavior: "smooth", block: "start" });
      }
    }

    // Press 't' to scroll to top
    if (e.key === "t" && !e.ctrlKey && !e.metaKey && !e.altKey) {
      var active = document.activeElement;
      if (active && (active.tagName === "INPUT" || active.tagName === "TEXTAREA" || active.tagName === "SELECT")) return;
      e.preventDefault();
      window.scrollTo({ top: 0, behavior: "smooth" });
    }
  });

  // ─── Flicker effect on title bar dots ────────────────────────────────────────

  var dots = document.querySelectorAll(".title-bar .dot");
  dots.forEach(function (dot) {
    dot.addEventListener("mouseenter", function () {
      dot.style.boxShadow = "0 0 8px " + getComputedStyle(dot).backgroundColor;
    });
    dot.addEventListener("mouseleave", function () {
      dot.style.boxShadow = "";
    });
  });

  // ─── Shared module integrations ──────────────────────────────────────────────

  // Search
  __RPT.initSearch('#search', '#search-count', '#no-results', '.section');

  // Copy buttons (shared module — also works alongside hover copy above)
  __RPT.initCopyButtons('.copy-btn');

  // Width picker
  __RPT.initWidthPicker('.terminal-window', 'terminal-width');

  // Math rendering
  __RPT.initMath();

  // External links open in new tab
  __RPT.openExternalLinks();

  // ── Toolbar interface ─────────────────────────────────────────────────────
  window.__RPT_TOOLBAR = {
    print: function() { window.print(); },
    row2Html: window.__RPT_DEFAULT_ROW2_HTML || '',
    row2Init: function() {
      if (window.__RPT && __RPT.initWidthPicker) {
        __RPT.initWidthPicker('.terminal-window', 'terminal-width');
      }
    },
  };
})();
