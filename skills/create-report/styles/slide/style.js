/* style.js — Slide / Presentation style interactive behaviours */
(function () {
  "use strict";

  var root = document.documentElement;

  // ── Safe localStorage ──────────────────────────────────────────────────────
  var store = (function () {
    var mem = {};
    try {
      localStorage.setItem("__rpt_test", "1");
      localStorage.removeItem("__rpt_test");
      return localStorage;
    } catch (_) {
      return {
        getItem: function (k) { return k in mem ? mem[k] : null; },
        setItem: function (k, v) { mem[k] = String(v); },
        removeItem: function (k) { delete mem[k]; },
      };
    }
  })();

  // ── Shared module calls ────────────────────────────────────────────────────
  __RPT.initCodeDialog("#code-dialog");
  __RPT.initCopyButtons(".copy-btn");
  __RPT.openExternalLinks();
  __RPT.initCodePaths();

  // ── Math rendering ─────────────────────────────────────────────────────────
  document.addEventListener("DOMContentLoaded", function () {
    __RPT.initMath();
  });
  if (document.readyState !== "loading") {
    setTimeout(function () {
      __RPT.initMath();
    }, 100);
  }

  // ── Theme restore (floating toolbar handles toggle) ───────────────────────
  (function initTheme() {
    var saved = store.getItem("rpt-theme") || "light";
    if (saved === "light") root.classList.add("light");
  })();

  // ── Accent color picker ───────────────────────────────────────────────────
  var ACCENTS = {
    indigo:  { label: "Indigo",  rgb: "99, 102, 241",  hex: "#6366f1" },
    violet:  { label: "Violet",  rgb: "139, 92, 246",  hex: "#8b5cf6" },
    purple:  { label: "Purple",  rgb: "168, 85, 247",  hex: "#a855f7" },
    fuchsia: { label: "Fuchsia", rgb: "217, 70, 239",  hex: "#d946ef" },
    pink:    { label: "Pink",    rgb: "236, 72, 153",  hex: "#ec4899" },
    rose:    { label: "Rose",    rgb: "244, 63, 94",   hex: "#f43f5e" },
    red:     { label: "Red",     rgb: "239, 68, 68",   hex: "#ef4444" },
    orange:  { label: "Orange",  rgb: "249, 115, 22",  hex: "#f97316" },
    amber:   { label: "Amber",   rgb: "245, 158, 11",  hex: "#f59e0b" },
    yellow:  { label: "Yellow",  rgb: "234, 179, 8",   hex: "#eab308" },
    lime:    { label: "Lime",    rgb: "132, 204, 22",  hex: "#84cc16" },
    emerald: { label: "Emerald", rgb: "16, 185, 129",  hex: "#10b981" },
    teal:    { label: "Teal",    rgb: "20, 184, 166",  hex: "#14b8a6" },
    cyan:    { label: "Cyan",    rgb: "6, 182, 212",   hex: "#06b6d4" },
    sky:     { label: "Sky",     rgb: "14, 165, 233",  hex: "#0ea5e9" },
    blue:    { label: "Blue",    rgb: "59, 130, 246",  hex: "#3b82f6" },
  };

  function applyAccent(name) {
    var a = ACCENTS[name] || ACCENTS.indigo;
    root.style.setProperty("--accent", a.hex);
    root.style.setProperty("--accent-rgb", a.rgb);
    root.style.setProperty("--accent-dim", "rgba(" + a.rgb + ", .15)");
    root.style.setProperty("--accent-glow", "rgba(" + a.rgb + ", .3)");
    root.style.setProperty("--dot-active", a.hex);
    store.setItem("rpt-accent", name);
    document.querySelectorAll(".color-dot").forEach(function (d) {
      d.classList.toggle("active", d.getAttribute("data-accent") === name);
    });
  }

  applyAccent(store.getItem("rpt-accent") || "indigo");

  var colorBtn = document.getElementById("color-btn");
  var colorMenu = document.getElementById("color-menu");
  if (colorBtn && colorMenu) {
    colorBtn.addEventListener("click", function (e) {
      e.stopPropagation();
      colorMenu.classList.toggle("open");
    });
    document.querySelectorAll(".color-dot").forEach(function (d) {
      d.addEventListener("click", function () {
        applyAccent(d.getAttribute("data-accent"));
        colorMenu.classList.remove("open");
      });
    });
    document.addEventListener("click", function () {
      colorMenu.classList.remove("open");
    });
  }

  // ── Width picker ──────────────────────────────────────────────────────────
  var widthBtns = document.querySelectorAll(".width-btn");
  var slideContainer = document.getElementById("slide-container");

  (function initWidth() {
    var saved = store.getItem("rpt-width") || "md";
    if (slideContainer) {
      slideContainer.className = slideContainer.className.replace(/\bwidth-\w+/g, "");
      slideContainer.classList.add("width-" + saved);
    }
    widthBtns.forEach(function (b) {
      b.classList.toggle("active", b.getAttribute("data-width") === saved);
    });
  })();

  widthBtns.forEach(function (btn) {
    btn.addEventListener("click", function () {
      var w = btn.getAttribute("data-width");
      if (slideContainer) {
        slideContainer.className = slideContainer.className.replace(/\bwidth-\w+/g, "");
        slideContainer.classList.add("width-" + w);
      }
      widthBtns.forEach(function (b) {
        b.classList.toggle("active", b.getAttribute("data-width") === w);
      });
      store.setItem("rpt-width", w);
    });
  });

  // ── Text size picker ──────────────────────────────────────────────────────
  var textSizeLabel = document.getElementById("text-size-label");
  var textSmaller = document.getElementById("text-smaller");
  var textLarger = document.getElementById("text-larger");
  var textScale = parseInt(store.getItem("rpt-text-scale") || "100", 10);

  function applyTextScale() {
    if (slideContainer) {
      slideContainer.style.fontSize = textScale + "%";
    }
    if (textSizeLabel) {
      textSizeLabel.textContent = textScale + "%";
    }
    store.setItem("rpt-text-scale", String(textScale));
  }
  applyTextScale();

  if (textSmaller) {
    textSmaller.addEventListener("click", function () {
      textScale = Math.max(60, textScale - 10);
      applyTextScale();
    });
  }
  if (textLarger) {
    textLarger.addEventListener("click", function () {
      textScale = Math.min(160, textScale + 10);
      applyTextScale();
    });
  }

  // ── DOM references ─────────────────────────────────────────────────────────
  var container = document.getElementById("slide-container");
  var slides = document.querySelectorAll(".slide");
  var dots = document.querySelectorAll(".nav-dot");
  var progressBar = document.getElementById("progress-bar");
  var currentSlideEl = document.getElementById("current-slide");
  var totalSlides = slides.length;
  var currentIndex = 0;

  // ── Navigate to slide ──────────────────────────────────────────────────────
  function goToSlide(index) {
    if (index < 0) index = 0;
    if (index >= totalSlides) index = totalSlides - 1;
    currentIndex = index;
    slides[index].scrollIntoView({ behavior: "smooth", block: "start" });
    updateUI();
  }

  // ── TOC references ──────────────────────────────────────────────────────
  var tocItems = document.querySelectorAll(".toc-item");

  function updateUI() {
    // Update dots
    dots.forEach(function (dot, i) {
      dot.classList.toggle("active", i === currentIndex);
    });
    // Update counter
    if (currentSlideEl) {
      currentSlideEl.textContent = String(currentIndex + 1);
    }
    // Update progress bar
    var pct = totalSlides > 1 ? (currentIndex / (totalSlides - 1)) * 100 : 100;
    if (progressBar) {
      progressBar.style.width = pct + "%";
    }
    // Update TOC active item
    tocItems.forEach(function (item, i) {
      item.classList.toggle("active", i === currentIndex);
    });
  }

  // ── Detect current slide on scroll ─────────────────────────────────────────
  function detectCurrentSlide() {
    var containerRect = container.getBoundingClientRect();
    var best = 0;
    var bestDist = Infinity;
    slides.forEach(function (slide, i) {
      var rect = slide.getBoundingClientRect();
      var dist = Math.abs(rect.top - containerRect.top);
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    });
    if (best !== currentIndex) {
      currentIndex = best;
      updateUI();
    }
  }

  if (container) {
    container.addEventListener("scroll", detectCurrentSlide, {
      passive: true,
    });
  }

  // Also handle window scroll for mobile (no snap mode)
  window.addEventListener(
    "scroll",
    function () {
      if (window.innerWidth <= 768) {
        detectCurrentSlide();
      }
    },
    { passive: true },
  );

  // ── Arrow key navigation ───────────────────────────────────────────────────
  document.addEventListener("keydown", function (e) {
    // Skip if search overlay is open or user is in an input
    if (
      document.getElementById("search-overlay") &&
      !document.getElementById("search-overlay").hidden
    )
      return;
    if (
      e.target.tagName === "INPUT" ||
      e.target.tagName === "TEXTAREA" ||
      e.target.tagName === "SELECT"
    )
      return;

    if (e.key === "ArrowRight" || e.key === "ArrowDown") {
      e.preventDefault();
      goToSlide(currentIndex + 1);
    } else if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
      e.preventDefault();
      goToSlide(currentIndex - 1);
    } else if (e.key === "Home") {
      e.preventDefault();
      goToSlide(0);
    } else if (e.key === "End") {
      e.preventDefault();
      goToSlide(totalSlides - 1);
    }
  });

  // ── Dot navigation click handlers ──────────────────────────────────────────
  dots.forEach(function (dot) {
    dot.addEventListener("click", function () {
      var idx = parseInt(dot.getAttribute("data-slide"), 10);
      if (!isNaN(idx)) goToSlide(idx);
    });
  });

  // ── TOC click handlers ────────────────────────────────────────────────────
  tocItems.forEach(function (item) {
    item.addEventListener("click", function (e) {
      e.preventDefault();
      var idx = parseInt(item.getAttribute("data-slide"), 10);
      if (!isNaN(idx)) goToSlide(idx);
    });
  });

  // ── Search overlay (Cmd+K / Ctrl+K) ───────────────────────────────────────
  var searchOverlay = document.getElementById("search-overlay");
  var searchInput = document.getElementById("search");
  var searchCloseBtn = document.getElementById("search-close");
  var searchBtn = document.getElementById("search-btn");
  var searchResults = document.getElementById("search-results");
  var searchCount = document.getElementById("search-count");

  function openSearch() {
    if (searchOverlay) {
      searchOverlay.hidden = false;
      if (searchInput) {
        searchInput.value = "";
        searchInput.focus();
      }
      updateSearchResults("");
    }
  }

  function closeSearch() {
    if (searchOverlay) {
      searchOverlay.hidden = true;
    }
  }

  // Cmd+K / Ctrl+K to open
  document.addEventListener("keydown", function (e) {
    if ((e.metaKey || e.ctrlKey) && e.key === "k") {
      e.preventDefault();
      if (searchOverlay && !searchOverlay.hidden) {
        closeSearch();
      } else {
        openSearch();
      }
    }
    if (e.key === "Escape") {
      closeSearch();
    }
  });

  if (searchBtn) {
    searchBtn.addEventListener("click", openSearch);
  }
  if (searchCloseBtn) {
    searchCloseBtn.addEventListener("click", closeSearch);
  }

  // Close on overlay background click
  if (searchOverlay) {
    searchOverlay.addEventListener("click", function (e) {
      if (e.target === searchOverlay) closeSearch();
    });
  }

  // Extract snippet around first match for context preview
  function getSnippet(fullText, query, maxLen) {
    var lower = fullText.toLowerCase();
    var idx = lower.indexOf(query);
    if (idx === -1) return "";
    var start = Math.max(0, idx - 40);
    var end = Math.min(fullText.length, idx + query.length + 60);
    var snip =
      (start > 0 ? "..." : "") +
      fullText.slice(start, end).trim() +
      (end < fullText.length ? "..." : "");
    return snip;
  }

  function updateSearchResults(query) {
    if (!searchResults) return;
    searchResults.innerHTML = "";
    var q = (query || "").toLowerCase().trim();
    var matches = [];

    slides.forEach(function (slide, i) {
      var h2 = slide.querySelector("h2");
      var heading = h2 ? h2.textContent : "Slide " + (i + 1);
      // Gather all visible text from paragraphs, list items, code, table cells
      var textParts = [];
      slide
        .querySelectorAll("p, li, td, th, code, blockquote, .slide-content")
        .forEach(function (el) {
          var t = el.textContent || "";
          if (t.trim()) textParts.push(t.trim());
        });
      var fullText = heading + " " + textParts.join(" ");

      if (!q || fullText.toLowerCase().indexOf(q) !== -1) {
        var snippet = q ? getSnippet(fullText, q, 100) : "";
        matches.push({ index: i, heading: heading, snippet: snippet });
      }
    });

    matches.forEach(function (m) {
      var item = document.createElement("div");
      item.className = "search-result-item";
      var label = document.createElement("div");
      label.className = "search-result-label";
      label.textContent = "Slide " + (m.index + 1) + ": " + m.heading;
      item.appendChild(label);
      if (m.snippet) {
        var snipEl = document.createElement("div");
        snipEl.className = "search-result-snippet";
        // Bold the matched term in snippet
        var lowerSnip = m.snippet.toLowerCase();
        var matchIdx = lowerSnip.indexOf(q);
        if (matchIdx !== -1) {
          snipEl.innerHTML =
            escHtml(m.snippet.slice(0, matchIdx)) +
            "<mark>" +
            escHtml(m.snippet.slice(matchIdx, matchIdx + q.length)) +
            "</mark>" +
            escHtml(m.snippet.slice(matchIdx + q.length));
        } else {
          snipEl.textContent = m.snippet;
        }
        item.appendChild(snipEl);
      }
      item.addEventListener("click", function () {
        goToSlide(m.index);
        closeSearch();
      });
      searchResults.appendChild(item);
    });

    if (searchCount) {
      searchCount.textContent = q
        ? matches.length + " of " + totalSlides + " slides"
        : totalSlides + " slides";
    }
  }

  function escHtml(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }

  if (searchInput) {
    searchInput.addEventListener("input", function () {
      updateSearchResults(searchInput.value);
    });
  }

  // ── Initialize UI state ────────────────────────────────────────────────────
  updateUI();

  // ── Toolbar interface ─────────────────────────────────────────────────────
  window.__RPT_TOOLBAR = {
    print: function() { window.print(); },
  };
})();
