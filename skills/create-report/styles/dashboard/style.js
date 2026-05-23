/**
 * Dashboard report — interactive JS
 * Handles: sidebar active state, smooth scroll, theme toggle, accent picker,
 * search, code dialog, copy buttons, math, external links, code paths
 */
(function () {
  "use strict";

  // ─── Accent Color Presets ──────────────────────────────────────────────────
  var ACCENT_PRESETS = {
    blue:    { hex: "#3b82f6", rgb: "59, 130, 246",  secondary: "#8b5cf6" },
    purple:  { hex: "#8b5cf6", rgb: "139, 92, 246",  secondary: "#c084fc" },
    emerald: { hex: "#10b981", rgb: "16, 185, 129",  secondary: "#34d399" },
    amber:   { hex: "#f59e0b", rgb: "245, 158, 11",  secondary: "#fbbf24" },
    rose:    { hex: "#f43f5e", rgb: "244, 63, 94",   secondary: "#fb7185" },
    cyan:    { hex: "#06b6d4", rgb: "6, 182, 212",   secondary: "#22d3ee" },
    orange:  { hex: "#f97316", rgb: "249, 115, 22",  secondary: "#fb923c" },
    lime:    { hex: "#84cc16", rgb: "132, 204, 22",  secondary: "#a3e635" },
    pink:    { hex: "#ec4899", rgb: "236, 72, 153",  secondary: "#f472b6" },
    indigo:  { hex: "#6366f1", rgb: "99, 102, 241",  secondary: "#818cf8" }
  };
  var ACCENT_KEY = "dashboard-accent";

  function applyAccent(name) {
    var preset = ACCENT_PRESETS[name];
    if (!preset) return;
    var r = document.documentElement;
    r.style.setProperty("--accent", preset.hex);
    r.style.setProperty("--accent-rgb", preset.rgb);
    r.style.setProperty("--accent-secondary", preset.secondary);
    // Update active button
    document.querySelectorAll(".accent-btn").forEach(function (btn) {
      btn.classList.toggle("active", btn.dataset.accent === name);
    });
    try { localStorage.setItem(ACCENT_KEY, name); } catch (_) {}
  }

  // Restore saved accent on load (before DOMContentLoaded for faster paint)
  try {
    var savedAccent = localStorage.getItem(ACCENT_KEY);
    if (savedAccent && ACCENT_PRESETS[savedAccent]) {
      var r = document.documentElement;
      var p = ACCENT_PRESETS[savedAccent];
      r.style.setProperty("--accent", p.hex);
      r.style.setProperty("--accent-rgb", p.rgb);
      r.style.setProperty("--accent-secondary", p.secondary);
    }
  } catch (_) {}

  // ─── DOMContentLoaded ──────────────────────────────────────────────────────
  document.addEventListener("DOMContentLoaded", function () {

    // ─── Shared module calls ───────────────────────────────────────────────
    if (window.__RPT) {
      __RPT.initThemeToggle('.theme-toggle', { defaultTheme: 'light' });
      __RPT.initCodeDialog('#code-dialog');
      __RPT.initCopyButtons('.copy-btn');
      __RPT.initSearch('#search', '#search-count', '#no-results', 'details');
      __RPT.initMath();
      __RPT.openExternalLinks();
      __RPT.initCodePaths();
    }

    // ─── Sidebar toggle ────────────────────────────────────────────────────
    var toggleBtn = document.getElementById("sidebar-toggle");
    var layout = document.querySelector(".layout");
    if (toggleBtn && layout) {
      var key = "dashboard-sidebar";
      try { if (localStorage.getItem(key) === "collapsed") layout.classList.add("sidebar-collapsed"); } catch (_) {}
      toggleBtn.addEventListener("click", function () {
        layout.classList.toggle("sidebar-collapsed");
        try { localStorage.setItem(key, layout.classList.contains("sidebar-collapsed") ? "collapsed" : "open"); } catch (_) {}
      });
    }

    // ─── Sidebar active link tracking ──────────────────────────────────────
    var sidebarLinks = document.querySelectorAll(".sidebar a[href^='#']");
    var sectionAnchors = [];

    sidebarLinks.forEach(function (link) {
      var id = link.getAttribute("href")?.slice(1);
      if (id) {
        var el = document.getElementById(id);
        if (el) sectionAnchors.push({ id: id, el: el, link: link });
      }
    });

    function updateActiveLink() {
      var current = sectionAnchors[0];
      var scrollY = window.scrollY + 120;
      for (var i = 0; i < sectionAnchors.length; i++) {
        if (sectionAnchors[i].el.offsetTop <= scrollY) current = sectionAnchors[i];
      }
      sidebarLinks.forEach(function (l) { l.classList.remove("active"); });
      if (current) current.link.classList.add("active");
    }

    if (sectionAnchors.length) {
      window.addEventListener("scroll", updateActiveLink, { passive: true });
      updateActiveLink();
    }

    // Smooth scroll for sidebar links
    sidebarLinks.forEach(function (link) {
      link.addEventListener("click", function (e) {
        var id = link.getAttribute("href")?.slice(1);
        var target = id && document.getElementById(id);
        if (target) {
          e.preventDefault();
          target.scrollIntoView({ behavior: "smooth", block: "start" });
        }
      });
    });

  });

  // ── Toolbar interface ─────────────────────────────────────────────────────
  var accentBtnsHtml = Object.keys(ACCENT_PRESETS).map(function(name) {
    return '<button class="accent-btn" data-accent="' + name + '" style="background:' + ACCENT_PRESETS[name].hex + '" title="' + name.charAt(0).toUpperCase() + name.slice(1) + '"></button>';
  }).join("");

  window.__RPT_TOOLBAR = {
    print: function() { window.print(); },
    row2Html: '<div class="ftb-group accent-picker" style="display:inline-flex;gap:4px;align-items:center">' + accentBtnsHtml + '</div>',
    row2Init: function() {
      var saved = null;
      try { saved = localStorage.getItem(ACCENT_KEY); } catch (_) {}
      document.querySelectorAll(".floating-toolbar .accent-btn").forEach(function (btn) {
        if (saved) btn.classList.toggle("active", btn.dataset.accent === saved);
        btn.addEventListener("click", function () { applyAccent(btn.dataset.accent); });
      });
      if (!saved) {
        var blueBtn = document.querySelector('.floating-toolbar .accent-btn[data-accent="blue"]');
        if (blueBtn) blueBtn.classList.add("active");
      }
    },
  };
})();
