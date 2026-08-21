// shared.js — the behaviour every kanban surface has in common.
//
// Same reason as shared.css: the theme toggle, the tooltip and the page nav
// were re-implemented per page, so a fix landed on one surface and not the
// others. This is the one copy. Charter: UI-CHARTER.md.

// ---------- theme ----------
const applyTheme = (t) => {
  document.documentElement.dataset.theme = t;
  document.body.dataset.theme = t;
  localStorage.setItem("kanban-theme", t);
};
const toggleTheme = () =>
  applyTheme(document.documentElement.dataset.theme === "dark" ? "light" : "dark");
applyTheme(localStorage.getItem("kanban-theme") || "dark");

// ---------- time ----------
// Seconds matter for something just written, which the drafts page knew and the
// others did not. Converged on the more informative of the two rather than on
// whichever happened to be lifted first.
const ago = (ms) => {
  const s = Math.max(0, (Date.now() - ms) / 1000);
  if (s < 90) return `${Math.round(s)}s`;
  if (s < 5400) return `${Math.round(s / 60)}m`;
  if (s < 172800) return `${Math.round(s / 3600)}h`;
  return `${Math.round(s / 86400)}d`;
};

// a path's varying end is its identity, so shortening drops the head
function tailTrim(el) {
  const full = el.dataset.tip || el.title || el.textContent;
  el.dataset.tip = full; el.removeAttribute("title"); el.textContent = full;
  let guard = 300;
  while (el.scrollWidth > el.clientWidth && el.textContent.length > 12 && guard--) {
    el.textContent = "…" + el.textContent.replace(/^…/, "").slice(3);
  }
}

// ---------- the tooltip ----------
// Delegated on [data-tip], so a re-render never orphans a listener, and driven
// by data-tip rather than title= so nothing double-fires.
(function tooltip() {
  if (document.getElementById("tip")) return;
  const t = document.createElement("div");
  t.id = "tip"; t.setAttribute("role", "tooltip"); t.setAttribute("aria-hidden", "true");
  document.body.appendChild(t);
  let timer = null, forEl = null;
  const hide = () => {
    clearTimeout(timer); forEl = null;
    t.classList.remove("on"); t.setAttribute("aria-hidden", "true");
    setTimeout(() => { if (!forEl) t.style.display = "none"; }, 120);
  };
  const show = (el) => {
    const body = el.dataset.tip; if (!body) return;
    t.replaceChildren();
    if (el.dataset.tiph) {
      const h = document.createElement("b"); h.className = "tiph"; h.textContent = el.dataset.tiph; t.append(h);
    }
    t.append(document.createTextNode(body));
    forEl = el;
    const r = el.getBoundingClientRect();
    t.style.display = "block";
    const b = t.getBoundingClientRect();
    let top = r.bottom + 9, below = true;
    if (top + b.height > innerHeight - 8) { top = Math.max(8, r.top - b.height - 9); below = false; }
    const left = Math.min(Math.max(8, r.left), Math.max(8, innerWidth - b.width - 8));
    t.style.top = `${top}px`; t.style.left = `${left}px`;
    t.classList.toggle("below", below); t.classList.toggle("above", !below);
    t.style.setProperty("--ax", `${Math.min(Math.max(10, r.left + r.width / 2 - left - 4.5), Math.max(10, b.width - 19))}px`);
    t.classList.add("on"); t.setAttribute("aria-hidden", "false");
  };
  document.addEventListener("pointerover", (e) => {
    const el = e.target.closest?.("[data-tip]");
    if (!el || el === forEl) return;
    clearTimeout(timer);
    timer = setTimeout(() => show(el), 260);
  });
  document.addEventListener("pointerout", (e) => {
    const el = e.target.closest?.("[data-tip]");
    if (el && !el.contains(e.relatedTarget)) hide();
  });
  addEventListener("scroll", hide, true);
  addEventListener("keydown", (e) => { if (e.key === "Escape") hide(); });
})();

// ---------- the page chrome ----------
// Three views, reachable from all of them, with the same keys everywhere. The
// partial navigation graph was the audit's headline finding: you could not
// reach Asks from Drafts at all.
const NAV_ICON = {
  boards: `<svg width="13" height="13" viewBox="0 0 16 16" fill="none"><rect x="1.8" y="2.6" width="5" height="10.8" rx="1.4" stroke="currentColor" stroke-width="1.2"/><rect x="9.2" y="2.6" width="5" height="6.6" rx="1.4" stroke="currentColor" stroke-width="1.2"/></svg>`,
  asks: `<svg width="13" height="13" viewBox="0 0 16 16" fill="none"><path d="M3.4 2.6h9.2v8.2L9.4 13.4H3.4V2.6Z" stroke="currentColor" stroke-width="1.2" stroke-linejoin="round"/><path d="M12.6 10.8H9.4v2.6" stroke="currentColor" stroke-width="1.2" stroke-linejoin="round"/></svg>`,
  drafts: `<svg width="13" height="13" viewBox="0 0 16 16" fill="none"><path d="M10.6 2.8 13.2 5.4 5.6 13H3v-2.6l7.6-7.6Z" stroke="currentColor" stroke-width="1.2" stroke-linejoin="round"/></svg>`,
};
const MARK_ICON = `<svg width="16" height="16" viewBox="0 0 16 16" fill="none"><rect x="1.6" y="2.4" width="4.6" height="11.2" rx="1.5" stroke="currentColor" stroke-width="1.3"/><rect x="7.6" y="2.4" width="4.6" height="7" rx="1.5" stroke="currentColor" stroke-width="1.3"/><path d="M14.4 5v6.6" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/></svg>`;
const THEME_ICON = `<svg width="15" height="15" viewBox="0 0 16 16" fill="none"><circle cx="8" cy="8" r="5.6" stroke="currentColor" stroke-width="1.3"/><path d="M8 2.4a5.6 5.6 0 0 0 0 11.2V2.4Z" fill="currentColor"/></svg>`;

// `active` is one of boards | asks | drafts. `onView` is optional: a page that
// switches in place (the hub) handles its own two views; a page that does not
// (drafts) navigates.
function pageHead({ mount, active, title, sub, onView, counts = {} }) {
  const el = typeof mount === "string" ? document.querySelector(mount) : mount;
  if (!el) return null;
  el.className = "pagehead";
  el.innerHTML =
    `<span class="hmark">${MARK_ICON}</span>` +
    `<span class="htx"><h1 id="phTitle"></h1><span class="hsub" id="phSub"></span></span>` +
    `<span class="hsp"></span>` +
    `<div class="views" role="tablist">` +
      ["boards", "asks", "drafts"].map((v, i) =>
        `<a href="${v === "drafts" ? "/drafts" : v === "asks" ? "/?view=asks" : "/"}" data-v="${v}" data-k="${i + 1}" role="tab"
            class="${v === active ? "on" : ""}"
            data-tip="${v === "boards" ? "Every project an agent is working on" : v === "asks" ? "Things you wrote down for an agent to sort" : "Your documents, the rung above an ask"} · press ${i + 1}">
           <span class="vi">${NAV_ICON[v]}</span><span class="vt">${v === "boards" ? "Boards" : v === "asks" ? "Your asks" : "Drafts"}</span>
           <span class="vn">${counts[v] ?? ""}</span></a>`).join("") +
    `</div>` +
    `<button class="ico" id="phTheme" data-tip="Light and dark (t)" aria-label="toggle theme">${THEME_ICON}</button>`;
  document.getElementById("phTitle").textContent = title;
  document.getElementById("phSub").textContent = sub;
  document.getElementById("phTheme").onclick = toggleTheme;
  // a page that switches in place intercepts; everything else navigates
  if (onView) {
    el.querySelectorAll(".views a").forEach((a) => {
      a.onclick = (e) => {
        const v = a.dataset.v;
        if (v === "drafts") return;              // a real page, let it navigate
        e.preventDefault(); onView(v);
      };
    });
  }
  return el;
}

// One key map for all three, so the entrance behaves like the board.
addEventListener("keydown", (e) => {
  // optional call: a keydown whose target is the document has no .matches, and
  // the throw used to take the whole handler with it
  if (e.target.matches?.("input,textarea,[contenteditable]")) return;
  if (e.metaKey || e.ctrlKey || e.altKey) return;
  if (e.key === "t") return toggleTheme();
  const hit = document.querySelector(`.views a[data-k="${e.key}"]`);
  if (hit) hit.click();
});
