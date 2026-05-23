/**
 * data-table style — report.js
 * Tab switching, table row filtering/search, numeric cell detection,
 * copy buttons, code expand, theme toggle, color picker, and shared utilities.
 */
(function () {
  "use strict";

  // ── Color Presets ───────────────────────────────────────────
  var COLOR_PRESETS = {
    forest: { primary: "#16a34a", light: "#f0fdf4", text: "#ffffff" },
    ocean: { primary: "#2563eb", light: "#eff6ff", text: "#ffffff" },
    sunset: { primary: "#ea580c", light: "#fff7ed", text: "#ffffff" },
    grape: { primary: "#7c3aed", light: "#f5f3ff", text: "#ffffff" },
    slate: { primary: "#475569", light: "#f8fafc", text: "#ffffff" },
    rose: {
      primary: "#e11d48",
      light: "rgba(225,29,72,0.08)",
      text: "#ffffff",
    },
    teal: {
      primary: "#0d9488",
      light: "rgba(13,148,136,0.08)",
      text: "#ffffff",
    },
    amber: {
      primary: "#d97706",
      light: "rgba(217,119,6,0.08)",
      text: "#ffffff",
    },
    indigo: {
      primary: "#4f46e5",
      light: "rgba(79,70,229,0.08)",
      text: "#ffffff",
    },
    emerald: {
      primary: "#059669",
      light: "rgba(5,150,105,0.08)",
      text: "#ffffff",
    },
    cyan: {
      primary: "#0891b2",
      light: "rgba(8,145,178,0.08)",
      text: "#ffffff",
    },
    fuchsia: {
      primary: "#c026d3",
      light: "rgba(192,38,211,0.08)",
      text: "#ffffff",
    },
    lime: {
      primary: "#65a30d",
      light: "rgba(101,163,13,0.08)",
      text: "#ffffff",
    },
    sky: { primary: "#0284c7", light: "rgba(2,132,199,0.08)", text: "#ffffff" },
    stone: {
      primary: "#78716c",
      light: "rgba(120,113,108,0.08)",
      text: "#ffffff",
    },
  };

  var STORAGE_KEY = "datatable-color";

  // ── Apply Color Preset ──────────────────────────────────────
  function applyColorPreset(name) {
    var preset = COLOR_PRESETS[name];
    if (!preset) return;
    var root = document.documentElement;
    root.style.setProperty("--primary", preset.primary);
    root.style.setProperty("--primary-light", preset.light);
    root.style.setProperty("--primary-text", preset.text);

    // Update header bar background directly
    var header = document.querySelector(".header-bar");
    if (header) header.style.background = preset.primary;

    // Update swatch
    var swatch = document.querySelector(".color-swatch");
    if (swatch) swatch.style.background = preset.primary;

    // Mark active option (header dropdown and toolbar dots)
    document.querySelectorAll(".color-option, .dt-color-btn").forEach(function (btn) {
      btn.classList.toggle("active", btn.dataset.color === name);
    });

    // Persist
    try {
      localStorage.setItem(STORAGE_KEY, name);
    } catch (_) {}
  }

  // ── Color Picker Logic ──────────────────────────────────────
  function initColorPicker() {
    var picker = document.querySelector(".color-picker");
    if (!picker) return;

    var toggle = picker.querySelector(".color-picker-toggle");
    if (toggle) {
      toggle.addEventListener("click", function (e) {
        e.stopPropagation();
        picker.classList.toggle("open");
      });
    }

    document.querySelectorAll(".color-option").forEach(function (btn) {
      btn.addEventListener("click", function (e) {
        e.stopPropagation();
        applyColorPreset(btn.dataset.color);
        picker.classList.remove("open");
      });
    });

    // Close on outside click
    document.addEventListener("click", function () {
      picker.classList.remove("open");
    });

    // Restore saved color
    try {
      var saved = localStorage.getItem(STORAGE_KEY);
      if (saved && COLOR_PRESETS[saved]) {
        applyColorPreset(saved);
      }
    } catch (_) {}
  }

  // ── All DOM-dependent init deferred to DOMContentLoaded ────
  // After inlining, the <script> runs in <head> before the body
  // is parsed, so querySelectorAll(".tab-btn") etc. would return
  // empty NodeLists. Wrapping in DOMContentLoaded fixes this.

  function initTabsAndFilters() {
    // ── Tab Switching ────────────────────────────────────────
    var tabButtons = document.querySelectorAll(".tab-btn");
    var tabPanels = document.querySelectorAll(".tab-panel");

    function switchTab(tabId) {
      tabButtons.forEach(function (btn) {
        btn.classList.toggle("active", btn.dataset.tab === tabId);
      });
      tabPanels.forEach(function (panel) {
        panel.classList.toggle("active", panel.dataset.panel === tabId);
      });
      // Update row count for the newly active panel
      updateRowCount();
    }

    tabButtons.forEach(function (btn) {
      btn.addEventListener("click", function () {
        switchTab(btn.dataset.tab);
      });
    });

    // Support hash-based navigation: #section-id activates that tab
    function activateFromHash() {
      var hash = location.hash.slice(1);
      if (!hash) return;
      var matchingBtn = Array.from(tabButtons).find(function (btn) {
        return btn.dataset.tab === hash;
      });
      if (matchingBtn) {
        switchTab(hash);
      }
    }

    window.addEventListener("hashchange", activateFromHash);
    activateFromHash();

    // ── Numeric Cell Detection ─────────────────────────────────
    // Right-align cells that contain numbers, percentages, currencies

    var NUM_RE = /^[\s$\u20ac\u00a3\u00a5]?-?[\d,]+\.?\d*\s*%?$/;

    function detectNumericCells() {
      document.querySelectorAll("td").forEach(function (td) {
        var text = td.textContent.trim();
        if (NUM_RE.test(text)) {
          td.classList.add("cell-number");
        }
      });
    }

    detectNumericCells();

    // ── Column Sorting ───────────────────────────────────────────
    // Click a <th> to cycle: none → ascending → descending → none

    function initColumnSorting() {
      document.querySelectorAll(".table-wrap table").forEach(function (table) {
        var headers = Array.from(table.querySelectorAll("thead th"));
        headers.forEach(function (th, colIndex) {
          th.style.cursor = "pointer";
          th.setAttribute("data-sort", "none"); // none | asc | desc
          th.addEventListener("click", function () {
            var current = th.getAttribute("data-sort");
            // Reset all headers in this table
            headers.forEach(function (h) {
              h.setAttribute("data-sort", "none");
            });
            var next = current === "none" ? "asc" : current === "asc" ? "desc" : "none";
            th.setAttribute("data-sort", next);
            sortTable(table, colIndex, next);
          });
        });
      });
    }

    function sortTable(table, colIndex, direction) {
      var tbody = table.querySelector("tbody");
      if (!tbody) return;
      var rows = Array.from(tbody.querySelectorAll("tr"));
      if (direction === "none") {
        // Restore original order using data attribute
        rows.sort(function (a, b) {
          return (parseInt(a.dataset.origIdx, 10) || 0) - (parseInt(b.dataset.origIdx, 10) || 0);
        });
      } else {
        rows.sort(function (a, b) {
          var cellA = a.querySelectorAll("td")[colIndex];
          var cellB = b.querySelectorAll("td")[colIndex];
          if (!cellA || !cellB) return 0;
          var textA = cellA.textContent.trim();
          var textB = cellB.textContent.trim();
          // Try numeric comparison first
          var numA = parseFloat(textA.replace(/[$€£¥,%\s]/g, ""));
          var numB = parseFloat(textB.replace(/[$€£¥,%\s]/g, ""));
          var cmp;
          if (!isNaN(numA) && !isNaN(numB)) {
            cmp = numA - numB;
          } else {
            cmp = textA.localeCompare(textB, undefined, { sensitivity: "base" });
          }
          return direction === "desc" ? -cmp : cmp;
        });
      }
      rows.forEach(function (row) {
        tbody.appendChild(row);
      });
    }

    // Store original row indices for reset
    document.querySelectorAll("tbody tr").forEach(function (row, i) {
      row.dataset.origIdx = String(i);
    });

    initColumnSorting();

    // ── Cell Expand (truncated cells) ────────────────────────────
    // Click a truncated cell to toggle full content visibility

    function initCellExpand() {
      document.querySelectorAll("td").forEach(function (td) {
        // Only add expand behavior if content might be truncated
        if (td.scrollWidth > td.clientWidth || td.textContent.length > 60) {
          td.classList.add("cell-expandable");
          td.addEventListener("click", function (e) {
            if (e.target.closest("a, button, code")) return; // Don't interfere with links/buttons
            td.classList.toggle("cell-expanded");
          });
        }
      });
    }

    initCellExpand();

    // ── Tab Row Counts ───────────────────────────────────────────
    // Show row count in tab buttons like "Sales (42)"

    function updateTabCounts() {
      tabButtons.forEach(function (btn) {
        var tabId = btn.dataset.tab;
        var panel = document.querySelector('.tab-panel[data-panel="' + tabId + '"]');
        if (!panel) return;
        var allRows = panel.querySelectorAll("tbody tr");
        var total = allRows.length;
        if (total === 0) return; // No table in this panel
        // Store original label once
        if (!btn.dataset.origLabel) {
          btn.dataset.origLabel = btn.textContent;
        }
        var visibleRows = Array.from(allRows).filter(function (r) {
          return !r.classList.contains("row-hidden");
        }).length;
        var query = searchInput ? searchInput.value.trim() : "";
        if (query && visibleRows !== total) {
          btn.textContent = btn.dataset.origLabel + " (" + visibleRows + "/" + total + ")";
        } else {
          btn.textContent = btn.dataset.origLabel + " (" + total + ")";
        }
      });
    }

    updateTabCounts();

    // ── Table Search / Filter ──────────────────────────────────

    var searchInput = document.getElementById("table-search");
    var rowCountEl = document.getElementById("row-count");
    var noResultsEl = document.getElementById("no-results");

    function getActivePanel() {
      return document.querySelector(".tab-panel.active");
    }

    function getAllTableRows(container) {
      if (!container) return [];
      return Array.from(container.querySelectorAll("tbody tr"));
    }

    function clearHighlights(container) {
      if (!container) return;
      container.querySelectorAll(".search-match").forEach(function (el) {
        var parent = el.parentNode;
        parent.replaceChild(document.createTextNode(el.textContent), el);
        parent.normalize();
      });
    }

    function highlightText(td, query) {
      // Walk text nodes and wrap matches
      var walker = document.createTreeWalker(td, NodeFilter.SHOW_TEXT, null);
      var matches = [];
      var lowerQuery = query.toLowerCase();

      var node;
      while ((node = walker.nextNode())) {
        var text = node.textContent;
        var idx = text.toLowerCase().indexOf(lowerQuery);
        if (idx !== -1) {
          matches.push({ node: node, idx: idx, length: query.length });
        }
      }

      // Apply highlights in reverse to preserve node positions
      for (var i = matches.length - 1; i >= 0; i--) {
        var m = matches[i];
        var after = m.node.splitText(m.idx + m.length);
        var matchNode = m.node.splitText(m.idx);
        var span = document.createElement("span");
        span.className = "search-match";
        span.textContent = matchNode.textContent;
        matchNode.parentNode.replaceChild(span, matchNode);
      }
    }

    function filterRows(query) {
      var panel = getActivePanel();
      if (!panel) return;

      clearHighlights(panel);
      var rows = getAllTableRows(panel);
      var lowerQuery = query.toLowerCase().trim();
      var visible = 0;
      var total = rows.length;

      rows.forEach(function (tr) {
        if (!lowerQuery) {
          tr.classList.remove("row-hidden");
          visible++;
          return;
        }

        var cells = Array.from(tr.querySelectorAll("td"));
        var match = cells.some(function (td) {
          return td.textContent.toLowerCase().includes(lowerQuery);
        });

        tr.classList.toggle("row-hidden", !match);

        if (match) {
          visible++;
          // Highlight matching text
          cells.forEach(function (td) {
            if (td.textContent.toLowerCase().includes(lowerQuery)) {
              highlightText(td, query.trim());
            }
          });
        }
      });

      if (total > 0) {
        rowCountEl.textContent = lowerQuery
          ? visible + " of " + total + " rows"
          : total + " rows";
      }

      // Show/hide no-results message
      if (noResultsEl) {
        noResultsEl.style.display =
          total > 0 && visible === 0 ? "block" : "none";
      }

      // Update tab button counts
      updateTabCounts();
    }

    function updateRowCount() {
      var panel = getActivePanel();
      if (!panel) return;
      var rows = getAllTableRows(panel);
      var visible = rows.filter(function (r) {
        return !r.classList.contains("row-hidden");
      }).length;
      var total = rows.length;

      if (total > 0) {
        var query = searchInput ? searchInput.value.trim() : "";
        rowCountEl.textContent = query
          ? visible + " of " + total + " rows"
          : total + " rows";
      } else {
        rowCountEl.textContent = "";
      }
    }

    if (searchInput) {
      var debounceTimer;
      searchInput.addEventListener("input", function () {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(function () {
          filterRows(searchInput.value);
        }, 120);
      });

      // Clear filter when switching tabs
      tabButtons.forEach(function (btn) {
        btn.addEventListener("click", function () {
          // Re-apply current filter to new tab
          setTimeout(function () {
            filterRows(searchInput.value);
          }, 10);
        });
      });
    }

    // Initial row count
    updateRowCount();

    // ── Keyboard Shortcuts ─────────────────────────────────────

    document.addEventListener("keydown", function (e) {
      // Ctrl/Cmd+F focuses the filter input
      if ((e.ctrlKey || e.metaKey) && e.key === "f" && searchInput) {
        // Only intercept if a table is visible in the active panel
        var panel = getActivePanel();
        if (panel && panel.querySelector("table")) {
          e.preventDefault();
          searchInput.focus();
          searchInput.select();
        }
      }

      // Escape clears the filter
      if (
        e.key === "Escape" &&
        searchInput &&
        document.activeElement === searchInput
      ) {
        searchInput.value = "";
        filterRows("");
        searchInput.blur();
      }
    });
  } // end initTabsAndFilters

  // ── Shared Utilities (from __RPT) ──────────────────────────

  document.addEventListener("DOMContentLoaded", function () {
    // Init tabs, search, filter, keyboard shortcuts (needs DOM)
    initTabsAndFilters();

    if (typeof window.__RPT !== "undefined") {
      // Code dialog — upgrades expand buttons to open modal
      __RPT.initCodeDialog("#code-dialog");

      // Copy buttons
      __RPT.initCopyButtons(".copy-btn");

      // KaTeX math rendering
      __RPT.initMath();

      // Open external links in new tab
      __RPT.openExternalLinks();

      // Colorize inline code paths (file.ext:line)
      __RPT.initCodePaths();
    }

    // Color picker
    initColorPicker();
  });

  // ── Toolbar interface ─────────────────────────────────────────────────────
  var colorBtnsHtml = Object.keys(COLOR_PRESETS).map(function(name) {
    return '<button class="dt-color-btn" data-color="' + name + '" style="background:' + COLOR_PRESETS[name].primary + '" title="' + name.charAt(0).toUpperCase() + name.slice(1) + '"></button>';
  }).join("");

  window.__RPT_TOOLBAR = {
    print: function() { window.print(); },
    row2Html: '<div class="ftb-group dt-color-picker" style="display:inline-flex;gap:4px;align-items:center;flex-wrap:wrap">' + colorBtnsHtml + '</div>',
    row2Init: function() {
      var saved = null;
      try { saved = localStorage.getItem(STORAGE_KEY); } catch (_) {}
      document.querySelectorAll(".floating-toolbar .dt-color-btn").forEach(function(btn) {
        if (saved) btn.classList.toggle("active", btn.dataset.color === saved);
        btn.addEventListener("click", function() { applyColorPreset(btn.dataset.color); });
      });
      if (!saved) {
        var forestBtn = document.querySelector('.floating-toolbar .dt-color-btn[data-color="forest"]');
        if (forestBtn) forestBtn.classList.add("active");
      }
    },
  };
})();
