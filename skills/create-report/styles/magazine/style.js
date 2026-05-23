/* style.js — Magazine style interactive behaviours */
(function () {
  'use strict';

  // ── Shared module calls ────────────────────────────────────────────────────
  __RPT.initCodeDialog('#code-dialog');
  __RPT.initCopyButtons('.copy-btn');
  __RPT.initSearch('#search', '#search-count', '#no-results', 'section');
  __RPT.openExternalLinks();
  __RPT.initCodePaths();

  // ── Math rendering (must wait for KaTeX scripts to load) ───────────────────
  document.addEventListener('DOMContentLoaded', function () {
    __RPT.initMath();
  });
  // Also try after a short delay in case DOMContentLoaded already fired
  if (document.readyState !== 'loading') {
    setTimeout(function () { __RPT.initMath(); }, 100);
  }

  // ── Smooth scroll for anchor links ────────────────────────────────────────
  document.querySelectorAll('a[href^="#"]').forEach(function (link) {
    link.addEventListener('click', function (e) {
      var target = document.querySelector(link.getAttribute('href'));
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  });

  // ── Theme Color Picker ──────────────────────────────────────────────────
  var ACCENT_STORAGE_KEY = 'mag-theme-accent';
  var ACCENT_SECONDARIES = {
    '#8b2252': '#c2185b',
    '#1e3a5f': '#2d5a8e',
    '#2d6a4f': '#40916c',
    '#7c2d82': '#a855a8',
    '#9c4221': '#c96a3e',
    '#0d6a6e': '#14919b',
    '#374151': '#6b7280',
    '#92400e': '#b45309'
  };

  function applyAccentColor(hex) {
    document.documentElement.style.setProperty('--magazine-accent', hex);
    var secondary = ACCENT_SECONDARIES[hex] || hex;
    document.documentElement.style.setProperty('--accent-secondary', secondary);
    // Update progress bar gradient if it exists
    if (progressBar) {
      progressBar.style.background = 'linear-gradient(90deg,' + hex + ',' + secondary + ')';
    }
  }

  var cpSelect = document.getElementById('cp-theme');
  if (cpSelect) {
    var savedAccent = __RPT.store.getItem(ACCENT_STORAGE_KEY);
    if (savedAccent) {
      applyAccentColor(savedAccent);
      for (var j = 0; j < cpSelect.options.length; j++) {
        if (cpSelect.options[j].value === savedAccent) {
          cpSelect.selectedIndex = j;
          break;
        }
      }
    }
    cpSelect.addEventListener('change', function () {
      var val = cpSelect.value;
      applyAccentColor(val);
      __RPT.store.setItem(ACCENT_STORAGE_KEY, val);
    });
  }

  // ── Reading progress bar ──────────────────────────────────────────────────
  var progressBar = document.createElement('div');
  var currentAccent = __RPT.store.getItem(ACCENT_STORAGE_KEY) || '#8b2252';
  var currentSecondary = ACCENT_SECONDARIES[currentAccent] || '#c2185b';
  progressBar.style.cssText = 'position:fixed;top:0;left:0;height:3px;background:linear-gradient(90deg,' + currentAccent + ',' + currentSecondary + ');z-index:9999;transition:width 0.15s;width:0';
  document.body.appendChild(progressBar);

  function updateProgress() {
    var scrollTop = window.scrollY;
    var docHeight = document.documentElement.scrollHeight - window.innerHeight;
    var pct = docHeight > 0 ? (scrollTop / docHeight) * 100 : 0;
    progressBar.style.width = pct + '%';
  }
  window.addEventListener('scroll', updateProgress, { passive: true });
  updateProgress();

  // ── Font Picker ───────────────────────────────────────────────────────────
  var FONT_KEYS = [
    { id: 'fp-heading', cssVar: '--font-heading', storageKey: 'mag-font-heading' },
    { id: 'fp-body',    cssVar: '--font-body',    storageKey: 'mag-font-body' },
    { id: 'fp-code',    cssVar: '--font-code',    storageKey: 'mag-font-code' }
  ];

  FONT_KEYS.forEach(function (cfg) {
    var select = document.getElementById(cfg.id);
    if (!select) return;

    // Restore from localStorage
    var saved = __RPT.store.getItem(cfg.storageKey);
    if (saved) {
      document.documentElement.style.setProperty(cfg.cssVar, saved);
      // Set the select to the saved value
      for (var i = 0; i < select.options.length; i++) {
        if (select.options[i].value === saved) {
          select.selectedIndex = i;
          break;
        }
      }
    }

    select.addEventListener('change', function () {
      var val = select.value;
      document.documentElement.style.setProperty(cfg.cssVar, val);
      __RPT.store.setItem(cfg.storageKey, val);
    });
  });

  // ── Toolbar interface ─────────────────────────────────────────────────────
  window.__RPT_TOOLBAR = {
    print: function() { window.print(); },
  };
})();
