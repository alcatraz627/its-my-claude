/**
 * Neon cyberpunk report — interactive JS
 * Uses window.__RPT namespace for shared modules.
 * Custom: neon accent cycling (cyan/magenta/pink), sidebar tracking,
 * print button, smooth scroll.
 */

(function () {
  "use strict";

  // ─── Neon Accent Presets ────────────────────────────────────────────────────
  var NEON_VARS = {
    // Blues & cyans
    cyan:       { hex: "#00f0ff", rgb: "0, 240, 255",   secondary: "#ff00ff" },
    ice:        { hex: "#72f1f7", rgb: "114, 241, 247", secondary: "#ff2d95" },
    sky:        { hex: "#0ea5e9", rgb: "14, 165, 233",  secondary: "#ff00ff" },
    blue:       { hex: "#3b82f6", rgb: "59, 130, 246",  secondary: "#ff2d95" },
    electric:   { hex: "#0066ff", rgb: "0, 102, 255",   secondary: "#ff00ff" },
    // Purples & pinks
    violet:     { hex: "#8b5cf6", rgb: "139, 92, 246",  secondary: "#ff00ff" },
    purple:     { hex: "#a855f7", rgb: "168, 85, 247",  secondary: "#00f0ff" },
    magenta:    { hex: "#ff00ff", rgb: "255, 0, 255",   secondary: "#00f0ff" },
    pink:       { hex: "#ff2d95", rgb: "255, 45, 149",  secondary: "#00f0ff" },
    rose:       { hex: "#f43f5e", rgb: "244, 63, 94",   secondary: "#ff00ff" },
    // Warm
    red:        { hex: "#ef4444", rgb: "239, 68, 68",   secondary: "#00f0ff" },
    orange:     { hex: "#ff6b00", rgb: "255, 107, 0",   secondary: "#00f0ff" },
    amber:      { hex: "#ffbf00", rgb: "255, 191, 0",   secondary: "#ff2d95" },
    yellow:     { hex: "#facc15", rgb: "250, 204, 21",  secondary: "#ff2d95" },
    // Greens
    lime:       { hex: "#a3e635", rgb: "163, 230, 53",  secondary: "#ff00ff" },
    green:      { hex: "#39ff14", rgb: "57, 255, 20",   secondary: "#00f0ff" },
    emerald:    { hex: "#10b981", rgb: "16, 185, 129",  secondary: "#ff00ff" },
    teal:       { hex: "#14b8a6", rgb: "20, 184, 166",  secondary: "#ff2d95" },
  };
  var NEON_STORAGE_KEY = "neon-accent";

  function applyNeonAccent(name) {
    var preset = NEON_VARS[name];
    if (!preset) return;
    var root = document.documentElement;
    root.setAttribute("data-neon", name);
    root.style.setProperty("--accent", preset.hex);
    root.style.setProperty("--accent-rgb", preset.rgb);
    root.style.setProperty("--accent-secondary", preset.secondary);
    try {
      localStorage.setItem(NEON_STORAGE_KEY, name);
    } catch (_) {}
  }

  // Restore saved accent immediately (before DOM ready)
  try {
    var saved = localStorage.getItem(NEON_STORAGE_KEY);
    if (saved && NEON_VARS[saved]) {
      var root = document.documentElement;
      root.setAttribute("data-neon", saved);
      root.style.setProperty("--accent", NEON_VARS[saved].hex);
      root.style.setProperty("--accent-rgb", NEON_VARS[saved].rgb);
      root.style.setProperty("--accent-secondary", NEON_VARS[saved].secondary);
    }
  } catch (_) {}

  // ─── Shared module initialization ──────────────────────────────────────────
  if (window.__RPT) {
    __RPT.initCodeDialog("#code-dialog");
    __RPT.initCopyButtons(".copy-btn");
    __RPT.initWidthPicker(".content", "neon-width");
    __RPT.openExternalLinks();
    __RPT.initCodePaths();
  }

  // ─── DOMContentLoaded ──────────────────────────────────────────────────────
  document.addEventListener("DOMContentLoaded", function () {
    // ─── Math rendering ──────────────────────────────────────────────────
    if (window.__RPT) {
      __RPT.initMath();
      __RPT.initSearch(
        "#search",
        "#search-count",
        "#no-results",
        ".neon-section",
      );
    }

    // ─── Accent dropdown (dynamically populated from NEON_VARS) ────────────
    var picker = document.querySelector(".neon-color-picker");
    if (picker) {
      // Build dropdown buttons from NEON_VARS
      var dropdown = document.getElementById("neon-color-dropdown");
      if (dropdown) {
        var html = "";
        Object.keys(NEON_VARS).forEach(function (name) {
          var p = NEON_VARS[name];
          var label = name.charAt(0).toUpperCase() + name.slice(1);
          html += '<button class="neon-color-opt" data-neon="' + name + '"><span class="neon-dot" style="background:' + p.hex + '"></span> ' + label + '</button>';
        });
        dropdown.innerHTML = html;
      }
      var toggle = picker.querySelector(".neon-color-toggle");
      if (toggle) {
        toggle.addEventListener("click", function (e) {
          e.stopPropagation();
          picker.classList.toggle("open");
        });
      }
      document.querySelectorAll(".neon-color-opt").forEach(function (btn) {
        btn.addEventListener("click", function (e) {
          e.stopPropagation();
          applyNeonAccent(btn.dataset.neon);
          picker.classList.remove("open");
          var swatch = document.querySelector(".neon-swatch");
          if (swatch && NEON_VARS[btn.dataset.neon]) swatch.style.background = NEON_VARS[btn.dataset.neon].hex;
          document.querySelectorAll(".neon-color-opt").forEach(function (b) {
            b.classList.toggle("active", b.dataset.neon === btn.dataset.neon);
          });
        });
      });
      document.addEventListener("click", function () { picker.classList.remove("open"); });
      // Mark initial active state
      var savedNeon = "cyan";
      try { savedNeon = localStorage.getItem(NEON_STORAGE_KEY) || "cyan"; } catch (_) {}
      document.querySelectorAll(".neon-color-opt").forEach(function (b) {
        b.classList.toggle("active", b.dataset.neon === savedNeon);
      });
      var swatch = document.querySelector(".neon-swatch");
      if (swatch && NEON_VARS[savedNeon]) swatch.style.background = NEON_VARS[savedNeon].hex;
    }

    // ─── Section copy buttons ───────────────────────────────────────────
    document.querySelectorAll(".section-copy-btn").forEach(function (btn) {
      btn.addEventListener("click", function () {
        var section = btn.closest(".neon-section");
        if (!section) return;
        var content = section.querySelector(".section-content");
        if (!content) return;
        var text = content.innerText || content.textContent || "";
        navigator.clipboard.writeText(text).then(function () {
          btn.innerHTML = "✓";
          setTimeout(function () {
            btn.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>';
          }, 1500);
        });
      });
    });

    // ─── Sidebar active link tracking ───────────────────────────────────
    var sidebarLinks = document.querySelectorAll(".sidebar a[href^='#']");
    var sectionAnchors = [];

    sidebarLinks.forEach(function (link) {
      var id = link.getAttribute("href");
      if (!id || id.length < 2) return;
      var el = document.getElementById(id.slice(1));
      if (el) sectionAnchors.push({ id: id.slice(1), el: el, link: link });
    });

    function updateActiveLink() {
      var current = sectionAnchors[0];
      var scrollY = window.scrollY + 140;
      for (var i = 0; i < sectionAnchors.length; i++) {
        if (sectionAnchors[i].el.offsetTop <= scrollY)
          current = sectionAnchors[i];
      }
      sidebarLinks.forEach(function (l) {
        l.classList.remove("active");
      });
      if (current) current.link.classList.add("active");
    }

    if (sectionAnchors.length) {
      window.addEventListener("scroll", updateActiveLink, { passive: true });
      updateActiveLink();
    }

    // ─── Smooth scroll for sidebar links ────────────────────────────────
    sidebarLinks.forEach(function (link) {
      link.addEventListener("click", function (e) {
        var id = link.getAttribute("href");
        if (!id || id.length < 2) return;
        var target = document.getElementById(id.slice(1));
        if (target) {
          e.preventDefault();
          target.scrollIntoView({ behavior: "smooth", block: "start" });
          history.replaceState(null, "", id);
        }
      });
    });
  });

  // ── Toolbar interface ─────────────────────────────────────────────────────
  window.__RPT_TOOLBAR = {
    print: function() { window.print(); },
    row2Html: window.__RPT_DEFAULT_ROW2_HTML || '',
    row2Init: function() {
      if (window.__RPT && __RPT.initWidthPicker) {
        __RPT.initWidthPicker('.content', 'neon-width');
      }
    },
  };
})();
