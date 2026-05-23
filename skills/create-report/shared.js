/**
 * shared.js — Reusable interactive modules for create-report templates.
 *
 * Attaches to window.__RPT namespace. Templates call only what they need:
 *   __RPT.initThemeToggle('#theme-btn');
 *   __RPT.initSearch('#search', '#search-count', '#no-results', 'section[data-section-id]');
 *   __RPT.initCodeDialog('#code-dialog');
 *   __RPT.initCopyButtons('.copy-btn');
 *   __RPT.initWidthPicker('main.content', 'rpt-width');
 *   __RPT.initMath();
 *   __RPT.openExternalLinks();
 */
(function () {
  "use strict";

  const root = document.documentElement;

  // ── Safe localStorage (file:// may block access) ──────────────────────────
  const store = (() => {
    const mem = Object.create(null);
    try {
      localStorage.setItem("__rpt_test", "1");
      localStorage.removeItem("__rpt_test");
      return localStorage;
    } catch (_) {
      return {
        getItem: (k) => (k in mem ? mem[k] : null),
        setItem: (k, v) => {
          mem[k] = String(v);
        },
        removeItem: (k) => {
          delete mem[k];
        },
      };
    }
  })();

  // ── SVG icons ─────────────────────────────────────────────────────────────
  const SUN_SVG =
    '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="2" x2="12" y2="4"/><line x1="12" y1="20" x2="12" y2="22"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="2" y1="12" x2="4" y2="12"/><line x1="20" y1="12" x2="22" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>';
  const MOON_SVG =
    '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>';

  // ── Theme Toggle ──────────────────────────────────────────────────────────
  /**
   * @param {string} btnSelector - CSS selector for the toggle button
   * @param {object} opts
   * @param {string} opts.storageKey - localStorage key (default: 'rpt-theme')
   * @param {string} opts.darkClass - class to add for light mode (default: 'light')
   * @param {string} opts.defaultTheme - 'dark' or 'light' (default: 'dark')
   * @param {string} opts.lightLabel - label text for light mode
   * @param {string} opts.darkLabel - label text for dark mode
   */
  function initThemeToggle(btnSelector, opts) {
    opts = Object.assign(
      {
        storageKey: "rpt-theme",
        darkClass: "light",
        defaultTheme: "light",
        lightLabel: "Light",
        darkLabel: "Dark",
        // 'light-class': html.light = light mode (default for most templates)
        // 'dark-class':  html.dark  = dark mode (for templates where :root is already light)
        convention: "light-class",
      },
      opts,
    );

    var btn = document.querySelector(btnSelector);
    if (!btn) return;

    var saved = store.getItem(opts.storageKey) || opts.defaultTheme;
    if (opts.convention === "dark-class") {
      if (saved === "dark") root.classList.add(opts.darkClass);
    } else {
      if (saved === "light") root.classList.add(opts.darkClass);
    }

    function isCurrentlyLight() {
      return opts.convention === "dark-class"
        ? !root.classList.contains(opts.darkClass)
        : root.classList.contains(opts.darkClass);
    }

    function sync() {
      var light = isCurrentlyLight();
      btn.innerHTML = light
        ? SUN_SVG + ' <span class="btn-label">' + opts.lightLabel + "</span>"
        : MOON_SVG + ' <span class="btn-label">' + opts.darkLabel + "</span>";
    }
    sync();

    btn.addEventListener("click", function () {
      root.classList.toggle(opts.darkClass);
      store.setItem(opts.storageKey, isCurrentlyLight() ? "light" : "dark");
      sync();
    });

    return {
      getTheme: () => (isCurrentlyLight() ? "light" : "dark"),
    };
  }

  // ── Search (Chrome-like: multi-word OR, next/back cycling, match index) ──
  /**
   * Chrome-like find-in-page. Splits query by spaces (OR search), highlights
   * all matching words, provides next/back cycling with index/count display.
   *
   * Expected HTML near the search input:
   *   <input id="search">
   *   <span id="search-count"></span>           ← shows "3 / 12"
   *   <button class="search-prev">▲</button>    ← optional, auto-created if missing
   *   <button class="search-next">▼</button>    ← optional, auto-created if missing
   *
   * @param {string} inputSel
   * @param {string} countSel
   * @param {string} noResultsSel
   * @param {string} sectionSel
   * @param {object} opts
   */
  function initSearch(inputSel, countSel, noResultsSel, sectionSel, opts) {
    opts = Object.assign(
      { navLinkSel: null, hiddenClass: "hidden-search" },
      opts,
    );

    var searchEl = document.querySelector(inputSel);
    var countEl = document.querySelector(countSel);
    var noResultEl = document.querySelector(noResultsSel);
    var allSections = Array.from(document.querySelectorAll(sectionSel));
    if (!searchEl || !allSections.length) return;

    // Auto-create prev/next buttons if not present
    var wrap = searchEl.closest(".search-wrap") || searchEl.parentElement;
    var prevBtn = wrap.querySelector(".search-prev");
    var nextBtn = wrap.querySelector(".search-next");
    if (!prevBtn || !nextBtn) {
      var navContainer = document.createElement("span");
      navContainer.className = "search-nav";
      navContainer.innerHTML =
        '<button class="search-prev" title="Previous (Shift+Enter)">&#9650;</button>' +
        '<button class="search-next" title="Next (Enter)">&#9660;</button>';
      if (countEl && countEl.parentNode) {
        countEl.parentNode.insertBefore(navContainer, countEl.nextSibling);
      } else {
        wrap.appendChild(navContainer);
      }
      prevBtn = navContainer.querySelector(".search-prev");
      nextBtn = navContainer.querySelector(".search-next");
    }

    // State
    var allMarks = []; // all <mark> elements in document order
    var currentIdx = -1;
    var ACTIVE_CLASS = "search-active";

    function clearMarks() {
      allSections.forEach(function (sec) {
        sec.querySelectorAll("mark").forEach(function (m) {
          var parent = m.parentNode;
          if (parent)
            parent.replaceChild(
              document.createTextNode(m.textContent || ""),
              m,
            );
        });
        sec.normalize();
      });
      allMarks = [];
      currentIdx = -1;
    }

    function addMarksForWord(el, word) {
      var walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
      var nodes = [];
      var n;
      while ((n = walker.nextNode())) {
        if (n.parentElement && !n.parentElement.closest("script,style,mark"))
          nodes.push(n);
      }
      nodes.forEach(function (node) {
        var txt = node.textContent || "";
        var lo = txt.toLowerCase();
        if (!lo.includes(word)) return;
        var frag = document.createDocumentFragment();
        var last = 0;
        var idx = lo.indexOf(word, last);
        while (idx !== -1) {
          if (idx > last)
            frag.appendChild(document.createTextNode(txt.slice(last, idx)));
          var mark = document.createElement("mark");
          mark.textContent = txt.slice(idx, idx + word.length);
          frag.appendChild(mark);
          last = idx + word.length;
          idx = lo.indexOf(word, last);
        }
        if (last < txt.length)
          frag.appendChild(document.createTextNode(txt.slice(last)));
        if (node.parentNode) node.parentNode.replaceChild(frag, node);
      });
    }

    function updateCount() {
      if (!countEl) return;
      if (allMarks.length === 0) {
        countEl.textContent = "";
        return;
      }
      countEl.textContent = currentIdx + 1 + " / " + allMarks.length;
    }

    function goToMark(idx) {
      if (allMarks.length === 0) return;
      // Remove active from previous
      if (currentIdx >= 0 && currentIdx < allMarks.length) {
        allMarks[currentIdx].classList.remove(ACTIVE_CLASS);
      }
      currentIdx =
        ((idx % allMarks.length) + allMarks.length) % allMarks.length;
      var mark = allMarks[currentIdx];
      mark.classList.add(ACTIVE_CLASS);
      mark.scrollIntoView({ behavior: "smooth", block: "center" });
      updateCount();
    }

    function goNext() {
      goToMark(currentIdx + 1);
    }
    function goPrev() {
      goToMark(currentIdx - 1);
    }

    var timer;
    function doSearch() {
      var raw = (searchEl.value || "").trim().toLowerCase();
      clearMarks();

      if (!raw) {
        allSections.forEach(function (sec) {
          sec.classList.remove(opts.hiddenClass, "search-reveal");
        });
        if (opts.navLinkSel) {
          document.querySelectorAll(opts.navLinkSel).forEach(function (n) {
            n.classList.remove(opts.hiddenClass);
          });
        }
        if (noResultEl) noResultEl.style.display = "none";
        updateCount();
        return;
      }

      // Split by spaces for OR search, filter empty
      var words = raw.split(/\s+/).filter(function (w) {
        return w.length > 0;
      });

      // For section visibility: a section matches if ANY word is found
      allSections.forEach(function (sec) {
        var text = (sec.textContent || "").toLowerCase();
        var hit = words.some(function (w) {
          return text.includes(w);
        });
        sec.classList.toggle(opts.hiddenClass, !hit);
        if (hit) {
          sec.classList.remove("search-reveal");
          void sec.offsetHeight;
          sec.classList.add("search-reveal");
          // Add marks for each word
          words.forEach(function (w) {
            addMarksForWord(sec, w);
          });
        }
      });

      // Nav link visibility
      if (opts.navLinkSel) {
        allSections.forEach(function (sec) {
          var id = sec.dataset.sectionId || sec.id || "";
          if (!id) return;
          var link = document.querySelector(
            opts.navLinkSel + ' a[href="#' + id + '"]',
          );
          var navItem = link && link.closest(opts.navLinkSel);
          if (navItem)
            navItem.classList.toggle(
              opts.hiddenClass,
              sec.classList.contains(opts.hiddenClass),
            );
        });
      }

      // Collect all marks in document order
      allMarks = Array.from(document.querySelectorAll("mark"));

      if (noResultEl)
        noResultEl.style.display = allMarks.length === 0 ? "block" : "none";

      // Jump to first match
      if (allMarks.length > 0) {
        goToMark(0);
      } else {
        updateCount();
      }
    }

    // Event handlers
    searchEl.addEventListener("input", function () {
      clearTimeout(timer);
      timer = setTimeout(doSearch, 180);
    });
    searchEl.addEventListener("keydown", function (e) {
      if (e.key === "Escape") {
        searchEl.value = "";
        doSearch();
        searchEl.blur();
      } else if (e.key === "Enter") {
        e.preventDefault();
        if (e.shiftKey) {
          goPrev();
        } else {
          goNext();
        }
      }
    });
    document.addEventListener("keydown", function (e) {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        searchEl.focus();
        searchEl.select();
      }
    });

    prevBtn.addEventListener("click", function (e) {
      e.preventDefault();
      goPrev();
    });
    nextBtn.addEventListener("click", function (e) {
      e.preventDefault();
      goNext();
    });
  }

  // ── Code Dialog ───────────────────────────────────────────────────────────
  /**
   * @param {string} dialogSel - CSS selector for the <dialog> element
   */
  function initCodeDialog(dialogSel) {
    var dialog = document.querySelector(dialogSel);
    if (!dialog) return;

    var dlgLang = dialog.querySelector(".dlg-lang");
    var dlgTitle = dialog.querySelector(".dlg-title");
    var dlgLines = dialog.querySelector(".dlg-lines");
    var dlgBody = dialog.querySelector(".dlg-body");
    var dlgCopy = dialog.querySelector(".dlg-copy");
    var dlgClose = dialog.querySelector(".dlg-close");

    function setupCopy(btn, getText) {
      if (!btn) return;
      btn.addEventListener("click", function (e) {
        e.stopPropagation();
        var text = getText();
        if (!text) return;
        navigator.clipboard.writeText(text).then(function () {
          btn.textContent = "Copied!";
          btn.classList.add("copied");
          setTimeout(function () {
            btn.textContent = "Copy";
            btn.classList.remove("copied");
          }, 2000);
        });
      });
    }

    function openDialog(wrap) {
      var pre = wrap.querySelector("pre");
      var code = wrap.querySelector("pre code");
      var langEl = wrap.querySelector(".code-lang");
      var lang = langEl ? langEl.textContent : "";
      var lines = (code ? code.textContent || "" : "").split("\n").length;

      if (dlgLang) dlgLang.textContent = lang || "text";
      if (dlgTitle)
        dlgTitle.textContent = lang ? lang + " snippet" : "Code preview";
      if (dlgLines)
        dlgLines.textContent = lines + " line" + (lines !== 1 ? "s" : "");

      if (dlgBody) {
        dlgBody.innerHTML = "";
        if (pre) dlgBody.appendChild(pre.cloneNode(true));
      }

      if (dlgCopy) {
        dlgCopy.textContent = "Copy";
        dlgCopy.classList.remove("copied");
        // Remove old listener by cloning
        var newCopy = dlgCopy.cloneNode(true);
        dlgCopy.parentNode.replaceChild(newCopy, dlgCopy);
        dlgCopy = newCopy;
        dialog.querySelector(".dlg-copy"); // re-query not needed, we have ref
        setupCopy(newCopy, function () {
          return code ? code.textContent || "" : "";
        });
      }

      dialog.showModal();
      if (dlgBody) dlgBody.scrollTop = 0;
    }

    function closeDialog() {
      dialog.setAttribute("data-closing", "");
      dialog.addEventListener(
        "animationend",
        function () {
          dialog.removeAttribute("data-closing");
          dialog.close();
        },
        { once: true },
      );
      // Fallback if no animation
      setTimeout(function () {
        if (dialog.hasAttribute("data-closing")) {
          dialog.removeAttribute("data-closing");
          dialog.close();
        }
      }, 400);
    }

    // Wire expand buttons and pre clicks
    document.querySelectorAll(".code-wrap").forEach(function (wrap) {
      var expandBtn = wrap.querySelector(".code-expand");
      if (expandBtn)
        expandBtn.addEventListener("click", function (e) {
          e.stopPropagation();
          openDialog(wrap);
        });
      // Pre click removed — only expand button opens the dialog
    });

    if (dlgClose) dlgClose.addEventListener("click", closeDialog);
    dialog.addEventListener("click", function (e) {
      var r = dialog.getBoundingClientRect();
      if (
        e.clientX < r.left ||
        e.clientX > r.right ||
        e.clientY < r.top ||
        e.clientY > r.bottom
      ) {
        closeDialog();
      }
    });
    dialog.addEventListener("keydown", function (e) {
      if (e.key === "Escape") {
        e.preventDefault();
        closeDialog();
      }
    });
  }

  // ── Copy Buttons ──────────────────────────────────────────────────────────
  function initCopyButtons(sel) {
    document.querySelectorAll(sel || ".copy-btn").forEach(function (btn) {
      var wrap = btn.closest(".code-wrap");
      btn.addEventListener("click", function (e) {
        e.stopPropagation();
        var code = wrap && wrap.querySelector("pre code");
        var text = code ? code.textContent || "" : "";
        if (!text) return;
        navigator.clipboard.writeText(text).then(function () {
          btn.textContent = "Copied!";
          btn.classList.add("copied");
          setTimeout(function () {
            btn.textContent = "Copy";
            btn.classList.remove("copied");
          }, 2000);
        });
      });
    });
  }

  // ── Width Picker ──────────────────────────────────────────────────────────
  var WIDTH_MAP = { sm: "640px", md: "960px", lg: "1200px", xl: "100%" };

  function initWidthPicker(contentSel, storageKey) {
    storageKey = storageKey || "rpt-width";
    var contentEl = document.querySelector(contentSel);
    if (!contentEl) return;

    var active = store.getItem(storageKey) || "md";

    function apply(w) {
      // Use CSS classes instead of inline maxWidth to avoid overriding
      // style-specific width rules (e.g., slide template's !important rules)
      contentEl.style.maxWidth = '';  // Clear any legacy inline style
      ['width-sm', 'width-md', 'width-lg', 'width-xl'].forEach(function(cls) {
        contentEl.classList.remove(cls);
      });
      if (w) contentEl.classList.add('width-' + w);
      active = w;
      store.setItem(storageKey, w);
      document.querySelectorAll(".width-btn").forEach(function (b) {
        b.classList.toggle("active", b.dataset.width === w);
      });
    }
    apply(active);

    document.querySelectorAll(".width-btn").forEach(function (btn) {
      btn.addEventListener("click", function () {
        apply(btn.dataset.width);
      });
    });

    return {
      getWidth: function () {
        return active;
      },
    };
  }

  // ── Math (KaTeX) ──────────────────────────────────────────────────────────
  function initMath() {
    if (typeof renderMathInElement !== "undefined") {
      renderMathInElement(document.body, {
        delimiters: [
          { left: "$$", right: "$$", display: true },
          { left: "$", right: "$", display: false },
          { left: "\\\\(", right: "\\\\)", display: false },
          { left: "\\\\[", right: "\\\\]", display: true },
        ],
        throwOnError: false,
      });
    }
  }

  // ── External Links ────────────────────────────────────────────────────────
  function openExternalLinks() {
    document.querySelectorAll('a[href^="http"]').forEach(function (a) {
      a.setAttribute("target", "_blank");
      a.setAttribute("rel", "noopener noreferrer");
    });
  }

  // ── Inline code path:line coloring ────────────────────────────────────────
  function initCodePaths() {
    var PATH_RE = /^(.+\.[a-z0-9]+):(\d+)$/i;
    document
      .querySelectorAll("p code, li code, td code")
      .forEach(function (el) {
        var text = el.textContent || "";
        var m = PATH_RE.exec(text.trim());
        if (!m) return;
        el.classList.add("code-path");
        el.innerHTML =
          '<span class="code-path-file">' +
          m[1] +
          "</span>" +
          '<span class="code-path-line">:' +
          m[2] +
          "</span>";
      });
  }

  // ── Style Picker ──────────────────────────────────────────────────────────
  /**
   * @param {string} btnSel    - CSS selector for the toggle button
   * @param {string} menuSel   - CSS selector for the dropdown menu
   */
  function initStylePicker(btnSel, menuSel) {
    var btn = document.querySelector(btnSel);
    var menu = document.querySelector(menuSel);
    if (!btn || !menu) return;
    if (btn._stylePickerInit) return;
    btn._stylePickerInit = true;

    var currentStyle = window.__RPT_CURRENT_STYLE || "default";
    var generatedStyles = window.__RPT_GENERATED_STYLES || [];

    function closeMenu() {
      menu.classList.remove("open");
      btn.setAttribute("aria-expanded", "false");
      var pf = document.getElementById("style-preview-float");
      if (pf) pf.classList.remove("visible");
    }
    function toggleMenu() {
      var isOpen = menu.classList.toggle("open");
      btn.setAttribute("aria-expanded", String(isOpen));
    }

    btn.addEventListener("click", function (e) {
      e.stopPropagation();
      toggleMenu();
    });
    document.addEventListener("click", function () {
      closeMenu();
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") closeMenu();
    });

    // Style preview float on hover — move to body to escape transform containing block
    var previewFloat = document.getElementById("style-preview-float");
    if (previewFloat) {
      document.body.appendChild(previewFloat);
      var previewSvg = previewFloat.querySelector("svg");
      menu.addEventListener("mouseover", function (e) {
        var opt = e.target.closest(".style-opt");
        if (!opt || !opt.dataset.preview) {
          previewFloat.classList.remove("visible");
          return;
        }
        previewSvg.innerHTML = opt.dataset.preview;
        var menuRect = menu.getBoundingClientRect();
        var optRect = opt.getBoundingClientRect();
        var top = optRect.top + optRect.height / 2 - 60;
        top = Math.max(8, Math.min(top, window.innerHeight - 140));
        previewFloat.style.top = top + "px";
        previewFloat.style.left = menuRect.left - 192 + "px";
        previewFloat.classList.add("visible");
      });
      menu.addEventListener("mouseleave", function () {
        previewFloat.classList.remove("visible");
      });
    }

    // Handle clicks on style option buttons
    menu.addEventListener("click", function (e) {
      e.stopPropagation();
      var opt = e.target.closest(".style-opt");
      if (!opt) return;

      var style = opt.dataset.style;
      if (!style || style === currentStyle) {
        closeMenu();
        return;
      }

      var isReady = opt.dataset.ready === "true";
      if (isReady) {
        // Open pre-generated style in new tab
        window.open("./" + style + "/index.html", "_blank");
        closeMenu();
      } else {
        // Copy restyle command to clipboard and show polished toast
        var reportDir = window.__RPT_REPORT_DIR || "";
        var cmd =
          "bash ~/.claude/skills/create-report/restyle-report.sh " +
          reportDir +
          " " +
          style;
        function showRestyleToast(cmdText) {
          // Remove any existing toast
          var old = document.querySelector(".restyle-toast");
          if (old) old.remove();
          var toast = document.createElement("div");
          toast.className = "restyle-toast";
          toast.innerHTML =
            '<span class="restyle-toast-label">Copied to clipboard</span>' +
            '<code class="restyle-toast-cmd">' +
            cmdText.replace(/</g, "&lt;") +
            "</code>";
          document.body.appendChild(toast);
          setTimeout(function () {
            toast.style.opacity = "0";
            toast.style.transform = "translateY(8px)";
            toast.style.transition = "opacity 0.2s, transform 0.2s";
            setTimeout(function () {
              toast.remove();
            }, 200);
          }, 2500);
        }
        if (navigator.clipboard) {
          navigator.clipboard.writeText(cmd).then(function () {
            showRestyleToast(cmd);
          });
        } else {
          showRestyleToast(cmd + " (copy manually)");
        }
        closeMenu();
      }
    });

    // Mark already-generated styles as ready (in case state changed after page load)
    menu.querySelectorAll(".style-opt").forEach(function (opt) {
      if (
        generatedStyles.indexOf(opt.dataset.style) !== -1 &&
        opt.dataset.style !== currentStyle
      ) {
        opt.dataset.ready = "true";
        var badge = opt.querySelector(".style-badge");
        if (!badge) {
          var b = document.createElement("span");
          b.className = "style-badge style-badge-ready";
          b.textContent = "ready";
          opt.appendChild(b);
        }
      }
    });
  }

  // ── Reading Progress Bar ─────────────────────────────────────────────────
  function initProgressBar() {
    if (document.querySelector(".reading-progress")) return; // already initialized
    var bar = document.createElement("div");
    bar.className = "reading-progress";
    document.body.appendChild(bar);
    var ticking = false;
    window.addEventListener("scroll", function () {
      if (!ticking) {
        requestAnimationFrame(function () {
          var scrollTop = window.scrollY || document.documentElement.scrollTop;
          var docHeight =
            document.documentElement.scrollHeight - window.innerHeight;
          var pct = docHeight > 0 ? (scrollTop / docHeight) * 100 : 0;
          bar.style.width = Math.min(100, pct) + "%";
          ticking = false;
        });
        ticking = true;
      }
    });
  }

  // ── Text Size Controls ──────────────────────────────────────────────────
  /**
   * @param {string} contentSel - CSS selector for the main content area
   * @param {string} storeKey   - localStorage key for persisting size
   */
  function initTextSize(contentSel, storeKey) {
    storeKey = storeKey || "rpt-text-size";
    var content = document.querySelector(contentSel);
    if (!content) return;
    if (content._textSizeInit) return;
    content._textSizeInit = true;

    var sizes = [80, 90, 100, 110, 120, 130];
    var current = parseInt(store.getItem(storeKey) || "100", 10);
    if (sizes.indexOf(current) === -1) current = 100;

    function apply() {
      content.style.fontSize = current + "%";
      var label = document.querySelector(".text-size-label");
      if (label) label.textContent = current + "%";
      store.setItem(storeKey, String(current));
    }
    apply();

    document.addEventListener("click", function (e) {
      var btn = e.target.closest(".text-size-btn");
      if (!btn) return;
      var dir = btn.dataset.dir;
      var idx = sizes.indexOf(current);
      if (dir === "down" && idx > 0) {
        current = sizes[idx - 1];
      } else if (dir === "up" && idx < sizes.length - 1) {
        current = sizes[idx + 1];
      }
      apply();
    });
  }

  // ── Scroll to Top ──────────────────────────────────────────────────────
  function initScrollToTop() {
    if (document.querySelector(".scroll-top-btn")) return; // already initialized
    var btn = document.createElement("button");
    btn.className = "scroll-top-btn";
    btn.title = "Scroll to top";
    btn.setAttribute("aria-label", "Scroll to top");
    btn.innerHTML =
      '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><polyline points="18 15 12 9 6 15"/></svg>';
    document.body.appendChild(btn);

    var ticking = false;
    window.addEventListener("scroll", function () {
      if (!ticking) {
        requestAnimationFrame(function () {
          var y = window.scrollY || document.documentElement.scrollTop;
          if (y > 400) {
            btn.classList.add("visible");
          } else {
            btn.classList.remove("visible");
          }
          ticking = false;
        });
        ticking = true;
      }
    });

    btn.addEventListener("click", function () {
      window.scrollTo({ top: 0, behavior: "smooth" });
    });
  }

  // ── Notion-compatible HTML builder ─────────────────────────────────────
  // Walks the report DOM and emits only the flat semantic elements that
  // Notion's clipboard parser recognises as block types.
  function toNotionHtml(root) {
    var parts = [];

    // Preserve inline formatting (bold, italic, code, links) but strip classes/styles
    function inlineHtml(el) {
      var out = "";
      el.childNodes.forEach(function (n) {
        if (n.nodeType === 3) {
          // text node
          out += n.textContent;
          return;
        }
        if (n.nodeType !== 1) return;
        var tag = n.tagName.toLowerCase();
        if (tag === "strong" || tag === "b") {
          out += "<strong>" + inlineHtml(n) + "</strong>";
        } else if (tag === "em" || tag === "i") {
          out += "<em>" + inlineHtml(n) + "</em>";
        } else if (tag === "code") {
          out += "<code>" + n.textContent + "</code>";
        } else if (tag === "a") {
          out += '<a href="' + (n.getAttribute("href") || "") + '">' + inlineHtml(n) + "</a>";
        } else if (tag === "br") {
          out += "<br>";
        } else {
          // Unwrap unknown inline wrappers (spans, etc.)
          out += inlineHtml(n);
        }
      });
      return out;
    }

    function walk(el) {
      var children = el.children;
      for (var i = 0; i < children.length; i++) {
        var node = children[i];
        var tag = node.tagName.toLowerCase();

        // Skip hidden, toolbar, nav, dialog elements
        if (node.hidden || node.offsetParent === null && tag !== "body" && tag !== "html") continue;
        if (tag === "nav" || tag === "dialog" || tag === "script" || tag === "style") continue;
        if (node.classList.contains("floating-toolbar") ||
            node.classList.contains("toolbar") ||
            node.classList.contains("sidebar") ||
            node.classList.contains("metrics") ||
            node.classList.contains("header-controls") ||
            node.classList.contains("toc-bar") ||
            node.classList.contains("toc") ||
            node.classList.contains("running-header") ||
            node.classList.contains("search-wrap") ||
            node.classList.contains("dlg-header")) continue;

        // Headings
        if (tag === "h1") {
          parts.push("<h1>" + inlineHtml(node) + "</h1>");
        } else if (tag === "h2") {
          parts.push("<h2>" + inlineHtml(node) + "</h2>");
        } else if (tag === "h3") {
          parts.push("<h3>" + inlineHtml(node) + "</h3>");
        } else if (tag === "h4") {
          // Notion only has H1-H3, map H4 to bold paragraph
          parts.push("<p><strong>" + inlineHtml(node) + "</strong></p>");
        }
        // Paragraphs
        else if (tag === "p") {
          var text = node.textContent.trim();
          if (text) parts.push("<p>" + inlineHtml(node) + "</p>");
        }
        // Horizontal rules / dividers
        else if (tag === "hr") {
          parts.push("<hr>");
        }
        // Blockquotes
        else if (tag === "blockquote") {
          parts.push("<blockquote>" + inlineHtml(node) + "</blockquote>");
        }
        // Lists (unordered and ordered)
        else if (tag === "ul") {
          var items = node.querySelectorAll(":scope > li");
          var listHtml = "<ul>";
          items.forEach(function (li) { listHtml += "<li>" + inlineHtml(li) + "</li>"; });
          listHtml += "</ul>";
          parts.push(listHtml);
        } else if (tag === "ol") {
          var oItems = node.querySelectorAll(":scope > li");
          var oListHtml = "<ol>";
          oItems.forEach(function (li) { oListHtml += "<li>" + inlineHtml(li) + "</li>"; });
          oListHtml += "</ol>";
          parts.push(oListHtml);
        }
        // Code blocks
        else if (tag === "pre") {
          var codeEl = node.querySelector("code");
          var codeText = codeEl ? codeEl.textContent : node.textContent;
          parts.push("<pre><code>" + codeText + "</code></pre>");
        }
        // Tables
        else if (tag === "table") {
          var tableHtml = "<table>";
          node.querySelectorAll("tr").forEach(function (tr) {
            tableHtml += "<tr>";
            tr.querySelectorAll("th, td").forEach(function (cell) {
              var cellTag = cell.tagName.toLowerCase();
              tableHtml += "<" + cellTag + ">" + inlineHtml(cell) + "</" + cellTag + ">";
            });
            tableHtml += "</tr>";
          });
          tableHtml += "</table>";
          parts.push(tableHtml);
        }
        // Containers — recurse into divs, sections, details, main, article, etc.
        else if (tag === "div" || tag === "section" || tag === "details" ||
                 tag === "main" || tag === "article" || tag === "summary" ||
                 tag === "header" || tag === "footer" || tag === "figure") {
          walk(node);
        }
        // Skip everything else (canvas, svg, img, form, input, etc.)
      }
    }

    walk(root);
    return parts.join("\n");
  }

  // ── Copy For Menu (Notion / Slack) ─────────────────────────────────────
  /**
   * @param {string} btnSel  - CSS selector for the toggle button
   * @param {string} menuSel - CSS selector for the dropdown
   */
  function initCopyForMenu(btnSel, menuSel) {
    var btn = document.querySelector(btnSel);
    var menu = document.querySelector(menuSel);
    if (!btn || !menu) return;
    if (btn._copyForInit) return;
    btn._copyForInit = true;

    function closeMenu() {
      menu.classList.remove("open");
      btn.setAttribute("aria-expanded", "false");
    }
    function toggleMenu() {
      var isOpen = menu.classList.toggle("open");
      btn.setAttribute("aria-expanded", String(isOpen));
    }

    btn.addEventListener("click", function (e) {
      e.stopPropagation();
      toggleMenu();
    });
    document.addEventListener("click", function () {
      closeMenu();
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") closeMenu();
    });

    function getReportContent() {
      var main =
        document.querySelector("main.content") ||
        document.querySelector("main") ||
        document.querySelector(".content") ||
        document.body;
      return main;
    }

    function showFeedback(optEl, msg) {
      var label = optEl.querySelector(".copy-for-label");
      var orig = label ? label.textContent : "";
      if (label) label.textContent = msg;
      setTimeout(function () {
        if (label) label.textContent = orig;
      }, 1500);
    }

    menu.addEventListener("click", function (e) {
      e.stopPropagation();
      var opt = e.target.closest(".copy-for-opt");
      if (!opt) return;

      var format = opt.dataset.format;
      var content = getReportContent();

      if (format === "notion") {
        // Build Notion-compatible HTML from semantic elements
        var html = toNotionHtml(content);
        if (navigator.clipboard && window.ClipboardItem) {
          var blob = new Blob([html], { type: "text/html" });
          navigator.clipboard
            .write([new ClipboardItem({ "text/html": blob })])
            .then(function () {
              showFeedback(opt, "Copied!");
            })
            .catch(function () {
              showFeedback(opt, "Failed");
            });
        } else {
          // Fallback: copy as plain text
          navigator.clipboard.writeText(content.innerText).then(function () {
            showFeedback(opt, "Copied (text)");
          });
        }
      } else if (format === "slack") {
        // Convert to Slack mrkdwn format
        var text = content.innerText || content.textContent || "";
        // Basic mrkdwn: keep structure, trim excessive whitespace
        text = text.replace(/\n{3,}/g, "\n\n").trim();
        if (navigator.clipboard) {
          navigator.clipboard.writeText(text).then(function () {
            showFeedback(opt, "Copied!");
          });
        }
      } else if (format === "markdown") {
        // Simple markdown: headings + text
        var md = "";
        content.querySelectorAll("h1,h2,h3,h4,p,li,code,pre").forEach(function (el) {
          var tag = el.tagName.toLowerCase();
          var t = el.textContent.trim();
          if (!t) return;
          if (tag === "h1") md += "# " + t + "\n\n";
          else if (tag === "h2") md += "## " + t + "\n\n";
          else if (tag === "h3") md += "### " + t + "\n\n";
          else if (tag === "h4") md += "#### " + t + "\n\n";
          else if (tag === "li") md += "- " + t + "\n";
          else if (tag === "pre") md += "```\n" + t + "\n```\n\n";
          else if (tag === "code" && el.parentElement.tagName !== "PRE") return;
          else md += t + "\n\n";
        });
        if (navigator.clipboard) {
          navigator.clipboard.writeText(md.trim()).then(function () {
            showFeedback(opt, "Copied!");
          });
        }
      }

      closeMenu();
    });
  }

  // ── Print: force tree <details> open ─────────────────────────────────────
  // CSS cannot toggle the `open` attribute — use beforeprint/afterprint events.
  (function () {
    var savedStates = [];
    window.addEventListener("beforeprint", function () {
      savedStates = [];
      document.querySelectorAll("details.tree-node").forEach(function (d) {
        savedStates.push({ el: d, wasOpen: d.open });
        d.open = true;
      });
    });
    window.addEventListener("afterprint", function () {
      savedStates.forEach(function (s) {
        s.el.open = s.wasOpen;
      });
      savedStates = [];
    });
  })();

  // ── Expose namespace ──────────────────────────────────────────────────────
  window.__RPT = {
    store: store,
    initThemeToggle: initThemeToggle,
    initSearch: initSearch,
    initCodeDialog: initCodeDialog,
    initCopyButtons: initCopyButtons,
    initWidthPicker: initWidthPicker,
    initStylePicker: initStylePicker,
    initMath: initMath,
    openExternalLinks: openExternalLinks,
    initCodePaths: initCodePaths,
    initProgressBar: initProgressBar,
    initTextSize: initTextSize,
    initScrollToTop: initScrollToTop,
    initCopyForMenu: initCopyForMenu,
    WIDTH_MAP: WIDTH_MAP,
  };
})();
