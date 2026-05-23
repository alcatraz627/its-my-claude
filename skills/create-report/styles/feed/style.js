/* ── Feed Style — Interactive Behaviors ───────────────────────────────────── */

(function () {
  "use strict";

  // ── Wait for shared module ──────────────────────────────────────────────
  function onReady(fn) {
    if (document.readyState !== "loading") fn();
    else document.addEventListener("DOMContentLoaded", fn);
  }

  onReady(function () {
    var R = window.__RPT;
    if (!R) return;

    // ── Code dialog ───────────────────────────────────────────────────────
    R.initCodeDialog("#code-dialog");

    // ── Copy buttons ──────────────────────────────────────────────────────
    R.initCopyButtons(".copy-btn");

    // ── Width picker — use feed-container, default to "lg" ────────────────
    R.initWidthPicker(".feed-container", "feed-width");

    // ── Math rendering ────────────────────────────────────────────────────
    R.initMath();

    // ── External links open in new tab ────────────────────────────────────
    R.openExternalLinks();

    // ── Inline code path coloring ─────────────────────────────────────────
    R.initCodePaths();

    // ── Search ────────────────────────────────────────────────────────────
    initFeedSearch();

    // ── Like / Retweet toggles ────────────────────────────────────────────
    initLikeRetweet();

    // ── Share button ──────────────────────────────────────────────────────
    initShareButton();

    // ── Smooth scroll ─────────────────────────────────────────────────────
    initSmoothScroll();

    // ── TOC toggle ────────────────────────────────────────────────────────
    initTocToggle();

    // ── TOC scroll spy ────────────────────────────────────────────────────
    initTocScrollSpy();
  });

  // ── TOC Toggle ────────────────────────────────────────────────────────

  function initTocToggle() {
    var toggle = document.getElementById("toc-toggle");
    var sidebar = document.getElementById("toc-sidebar");
    if (!toggle || !sidebar) return;

    var isDesktop = window.matchMedia("(min-width: 1081px)");

    // Desktop: visible by default; mobile: hidden by default
    if (!isDesktop.matches) {
      sidebar.classList.add("toc-hidden");
    }

    toggle.addEventListener("click", function () {
      if (isDesktop.matches) {
        sidebar.classList.toggle("toc-hidden");
      } else {
        sidebar.classList.toggle("toc-visible-mobile");
      }
    });

    // Close TOC when clicking a link inside it (mobile convenience)
    sidebar.addEventListener("click", function (e) {
      if (e.target.closest(".toc-link") && !isDesktop.matches) {
        sidebar.classList.remove("toc-visible-mobile");
      }
    });

    // Close TOC when clicking outside on mobile
    document.addEventListener("click", function (e) {
      if (!isDesktop.matches &&
          sidebar.classList.contains("toc-visible-mobile") &&
          !sidebar.contains(e.target) &&
          !toggle.contains(e.target)) {
        sidebar.classList.remove("toc-visible-mobile");
      }
    });
  }

  // ── Feed Search (reuse existing inline logic) ───────────────────────────

  function initFeedSearch() {
    var searchInput = document.getElementById("search");
    var searchCount = document.getElementById("search-count");
    var noResults = document.getElementById("no-results");

    if (!searchInput) return;

    var debounceTimer;
    searchInput.addEventListener("input", function () {
      clearTimeout(debounceTimer);
      var self = this;
      debounceTimer = setTimeout(function () {
        filterPosts(self.value.trim());
      }, 150);
    });

    // Cmd+K / Ctrl+K focus
    document.addEventListener("keydown", function (e) {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        searchInput.focus();
        searchInput.select();
      }
      if (e.key === "Escape" && document.activeElement === searchInput) {
        searchInput.value = "";
        filterPosts("");
        searchInput.blur();
      }
    });

    function filterPosts(query) {
      var posts = document.querySelectorAll(".post-card");
      var q = query.toLowerCase();
      var visible = 0;

      posts.forEach(function (post) {
        if (!q) {
          post.classList.remove("search-hidden");
          visible++;
          return;
        }
        var text = post.textContent.toLowerCase();
        if (text.includes(q)) {
          post.classList.remove("search-hidden");
          visible++;
        } else {
          post.classList.add("search-hidden");
        }
      });

      if (searchCount) {
        searchCount.textContent = q ? visible + " of " + posts.length : "";
      }
      if (noResults) {
        noResults.style.display = q && visible === 0 ? "block" : "none";
      }
    }
  }

  // ── Like / Retweet Toggle ───────────────────────────────────────────────

  function initLikeRetweet() {
    document.addEventListener("click", function (e) {
      var likeBtn = e.target.closest(".action-like");
      if (likeBtn) {
        e.preventDefault();
        var span = likeBtn.querySelector("span");
        if (!span) return;
        var isLiked = likeBtn.classList.toggle("liked");
        var count = parseInt(span.textContent, 10) || 0;
        if (isLiked) {
          span.textContent = count + 1;
          likeBtn.style.color = "var(--like-color)";
          likeBtn.querySelector("svg").style.fill = "var(--like-color)";
        } else {
          span.textContent = Math.max(0, count - 1);
          likeBtn.style.color = "";
          likeBtn.querySelector("svg").style.fill = "none";
        }
        return;
      }

      var rtBtn = e.target.closest(".action-retweet");
      if (rtBtn) {
        e.preventDefault();
        var rtSpan = rtBtn.querySelector("span");
        if (!rtSpan) return;
        var isRT = rtBtn.classList.toggle("retweeted");
        var rtCount = parseInt(rtSpan.textContent, 10) || 0;
        if (isRT) {
          rtSpan.textContent = rtCount + 1;
          rtBtn.style.color = "var(--retweet-color)";
          rtBtn.querySelector("svg").style.stroke = "var(--retweet-color)";
        } else {
          rtSpan.textContent = Math.max(0, rtCount - 1);
          rtBtn.style.color = "";
          rtBtn.querySelector("svg").style.stroke = "";
        }
      }
    });
  }

  // ── Share Button ────────────────────────────────────────────────────────

  function initShareButton() {
    document.addEventListener("click", function (e) {
      var shareBtn = e.target.closest(".action-share");
      if (!shareBtn) return;

      e.preventDefault();
      var card = shareBtn.closest(".post-card");
      if (!card) return;

      var heading = card.querySelector("h2");
      var sectionId = card.getAttribute("data-section-id");

      if (navigator.share) {
        navigator.share({
          title: heading ? heading.textContent : document.title,
          url: window.location.href.split("#")[0] + "#" + sectionId,
        }).catch(function () {});
      } else {
        var url = window.location.href.split("#")[0] + "#" + sectionId;
        navigator.clipboard.writeText(url).then(function () {
          var svg = shareBtn.querySelector("svg");
          if (svg) {
            svg.style.stroke = "var(--accent)";
            setTimeout(function () {
              svg.style.stroke = "";
            }, 1500);
          }
        });
      }
    });
  }

  // ── Smooth Scroll ───────────────────────────────────────────────────────

  function initSmoothScroll() {
    document.addEventListener("click", function (e) {
      var link = e.target.closest('a[href^="#"]');
      if (!link) return;

      var id = link.getAttribute("href").slice(1);
      var target = document.getElementById(id);
      if (!target) return;

      e.preventDefault();
      target.scrollIntoView({ behavior: "smooth", block: "start" });
    });
  }

  // ── TOC Scroll Spy ──────────────────────────────────────────────────────

  function initTocScrollSpy() {
    var tocLinks = document.querySelectorAll(".toc-link");
    if (!tocLinks.length) return;

    var sections = [];
    tocLinks.forEach(function (link) {
      var id = link.getAttribute("data-section-id");
      var el = id && document.getElementById(id);
      if (el) sections.push({ el: el, link: link });
    });

    if (!sections.length) return;

    var headerOffset = 70; // account for sticky header

    function updateActive() {
      var scrollY = window.scrollY + headerOffset;
      var active = null;

      for (var i = sections.length - 1; i >= 0; i--) {
        if (sections[i].el.offsetTop <= scrollY) {
          active = sections[i];
          break;
        }
      }

      // Default to first if none found
      if (!active && sections.length) active = sections[0];

      tocLinks.forEach(function (link) {
        link.classList.remove("active");
      });

      if (active) {
        active.link.classList.add("active");
        // Scroll the TOC sidebar to keep active item visible
        var sidebar = document.getElementById("toc-sidebar");
        if (sidebar) {
          var linkRect = active.link.getBoundingClientRect();
          var sidebarRect = sidebar.getBoundingClientRect();
          if (linkRect.bottom > sidebarRect.bottom || linkRect.top < sidebarRect.top) {
            active.link.scrollIntoView({ block: "nearest", behavior: "smooth" });
          }
        }
      }
    }

    var scrollTimer;
    window.addEventListener("scroll", function () {
      cancelAnimationFrame(scrollTimer);
      scrollTimer = requestAnimationFrame(updateActive);
    }, { passive: true });

    // Initial call
    updateActive();
  }

  // ── Toolbar interface ─────────────────────────────────────────────────────
  window.__RPT_TOOLBAR = {
    print: function() { window.print(); },
    row2Html: window.__RPT_DEFAULT_ROW2_HTML || '',
    row2Init: function() {
      if (window.__RPT && __RPT.initWidthPicker) {
        __RPT.initWidthPicker('.feed-container', 'feed-width');
      }
    },
  };
})();
