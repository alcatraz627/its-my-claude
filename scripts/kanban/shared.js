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
const HELP_ICON = `<svg width="15" height="15" viewBox="0 0 16 16" fill="none"><circle cx="8" cy="8" r="6.2" stroke="currentColor" stroke-width="1.3"/><path d="M6.3 6.2a1.75 1.75 0 1 1 1.9 1.85V9.4" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/><circle cx="8.1" cy="11.6" r=".75" fill="currentColor"/></svg>`;
const CLOSE_ICON = `<svg width="14" height="14" viewBox="0 0 16 16" fill="none"><path d="m4.6 4.6 6.8 6.8M11.4 4.6l-6.8 6.8" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/></svg>`;
const THEME_ICON = `<svg width="15" height="15" viewBox="0 0 16 16" fill="none"><circle cx="8" cy="8" r="5.6" stroke="currentColor" stroke-width="1.3"/><path d="M8 2.4a5.6 5.6 0 0 0 0 11.2V2.4Z" fill="currentColor"/></svg>`;

// `active` is one of boards | asks | drafts. `onView` is optional: a page that
// switches in place (the hub) handles its own two views; a page that does not
// (drafts) navigates.
//
// Three zones (UNIFIED-SURFACES phase 0). Left is who and where, middle is what
// you are looking for here, right is what is true on every page plus this page's
// own group. A page supplies its identity, its find control and its actions; it
// never re-implements the parts that must not move, which is what "I shouldn't
// lose access to common things in the navbar across" asks for.
//
// `find` and `actions` are elements the page owns and this mounts; `help` is a
// handler, and the help control is ABSENT rather than dead on a page that has no
// modal yet (charter §7 states: a control that cannot act is hidden, never
// silently greyed).
function navbar({ mount, active, title, sub, crumb, identity, find, actions, counts = {},
                  peers, help, onView }) {
  const el = typeof mount === "string" ? document.querySelector(mount) : mount;
  if (!el) return null;
  // add, never replace: a page may already carry a class its own CSS reads
  // (the board styles .brow .crumb, and losing that class loses the crumb)
  el.classList.add("navbar");
  el.innerHTML =
    `<div class="nz nzid">` +
      `<button class="nlogo" id="nbHome" aria-label="home"` +
      ` data-tip="Every board, your asks and your drafts (g b)">${MARK_ICON}</button>` +
      (crumb ? `<span class="ncrumb">${crumb}</span>` : "") +
      (identity ? `<span class="nident" id="nbIdent"></span>`
                : `<span class="ntx"><h1 id="nbTitle"></h1><span class="nsub" id="nbSub"></span></span>`) +
    `</div>` +
    `<div class="nz nzfind" id="nbFind"></div>` +
    `<div class="nz nzcommon">` +
      `<div class="views" role="tablist">` +
        ["boards", "asks", "drafts"].map((v, i) =>
          `<a href="${v === "drafts" ? "/drafts" : v === "asks" ? "/?view=asks" : "/"}" data-v="${v}" data-k="${i + 1}" role="tab"
              class="${v === active ? "on" : ""} k-${v}"
              data-tip="${v === "boards" ? "Every project an agent is working on" : v === "asks" ? "Things you wrote down for an agent to sort" : "Your documents, the rung above an ask"} · press ${i + 1}">
             <span class="vi">${NAV_ICON[v]}</span><span class="vt">${v === "boards" ? "Boards" : v === "asks" ? "Your asks" : "Drafts"}</span>
             <span class="vn">${counts[v] ?? ""}</span></a>`).join("") +
      `</div>` +
      `<span class="npeers" id="nbPeers"></span>` +
      `<span class="npage" id="nbActions"></span>` +
      `<button class="icon ghost" id="nbTheme" data-tip="Light and dark (t)" aria-label="toggle theme">${THEME_ICON}</button>` +
      (help ? `<button class="icon ghost" id="nbHelp" data-tip="Shortcuts, terminology and how it works (?)" aria-label="help">${HELP_ICON}</button>` : "") +
    `</div>`;
  if (identity) document.getElementById("nbIdent").append(identity);
  else { document.getElementById("nbTitle").textContent = title ?? "";
         document.getElementById("nbSub").textContent = sub ?? ""; }
  document.getElementById("nbHome").onclick = () => { location.href = "/"; };
  document.getElementById("nbTheme").onclick = toggleTheme;
  if (help) document.getElementById("nbHelp").onclick = help;
  if (find) document.getElementById("nbFind").append(find);
  if (actions) document.getElementById("nbActions").append(actions);
  if (peers) document.getElementById("nbPeers").append(peers);
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

// g-then-a-letter, for pages that do not own their key map. The board does own
// it, and `g` there already edits a card's goal, so the board reaches the same
// places with `b` (its go-to picker) instead. One letter, two meanings, and the
// page that got there first keeps it.
let gArmed = null;
const GO = { b: "/", a: "/?view=asks", d: "/drafts" };

// ---------- the help modal ----------
// The board's modal is the one the owner asked to reuse, so this is that shape
// rather than a new one: a titled dialog, a tab strip on the quieter ground,
// one scrolling pane at a time, Esc the only way out.
//
// Two ways in, because the board's panes are long hand-written tables and
// moving them into JavaScript would be a rewrite, not a reuse. A page that
// already has the markup gets ADOPTED — this takes over the tab strip, the
// close and the Escape, and leaves the panes alone. A page that has none gets
// one BUILT from a tab spec. Either way the behaviour has one implementation.
function helpModal({ id = "help", title = "Help", sub = "", tabs = [], onOpen, onShow } = {}) {
  let el = document.getElementById(id);
  const adopted = !!el;
  if (!el) {
    el = document.createElement("div");
    el.id = id;
    el.setAttribute("role", "dialog");
    el.setAttribute("aria-modal", "true");
    el.setAttribute("aria-label", "help");
    el.innerHTML =
      `<div class="box">` +
        `<div class="htitle"><span class="hmark">${MARK_ICON}</span>` +
          `<span class="htx"><b></b><i></i></span><span class="hsp"></span>` +
          `<button class="hclose icon" type="button" aria-label="close" data-tip="Close (Esc)">${CLOSE_ICON}</button></div>` +
        (tabs.length > 1 ? `<div class="htabs" role="tablist">` +
          tabs.map((t, i) => `<button class="htab${i ? "" : " on"}" data-pane="${id}-${t.id}" role="tab"` +
            ` aria-selected="${i ? "false" : "true"}"><span class="hi">${t.icon ?? ""}</span>` +
            `<span class="ht"><b></b><i></i></span></button>`).join("") +
        `</div>` : "") +
        tabs.map((t, i) => `<div class="hpane${i ? "" : " on"}" id="${id}-${t.id}" role="tabpanel"></div>`).join("") +
      `</div>`;
    document.body.appendChild(el);
    el.querySelector(".htitle .htx b").textContent = title;
    el.querySelector(".htitle .htx i").textContent = sub;
    // textContent, not innerHTML: a label is a label, never markup
    [...el.querySelectorAll(".htab")].forEach((b, i) => {
      b.querySelector(".ht b").textContent = tabs[i].label;
      b.querySelector(".ht i").textContent = tabs[i].sub ?? "";
    });
  }
  const panes = () => [...el.querySelectorAll(".hpane")];
  const strip = () => [...el.querySelectorAll(".htab")];
  const show = (tab) => {
    strip().forEach((t) => { const on = t === tab;
      t.classList.toggle("on", on); t.setAttribute("aria-selected", String(on)); });
    panes().forEach((p) => p.classList.toggle("on", p.id === tab.dataset.pane));
    // a host may fill a pane the first time it is shown rather than up front
    if (onShow) onShow(tab.dataset.pane, document.getElementById(tab.dataset.pane));
  };
  const close = () => { if (el.style.display !== "flex") return; el.style.display = "none"; };
  const open = () => {
    if (el.style.display === "flex") return close();
    el.style.display = "flex";
    tabs.forEach((t) => { if (t.build) t.build(document.getElementById(`${id}-${t.id}`)); });
    if (onOpen) onOpen(el);
    strip()[0]?.focus();
  };
  strip().forEach((t) => { t.onclick = () => show(t); });
  if (!adopted) {
    el.querySelector(".hclose")?.addEventListener("click", close);
    // Esc only, and only when this one is open (charter §9)
    addEventListener("keydown", (e) => { if (e.key === "Escape" && el.style.display === "flex") close(); });
  }
  return { el, open, close, show, adopted };
}

// The keys THIS file binds, written once. helpModal() renders them, so the
// reference and the behaviour cannot disagree: change a binding above and the
// modal changes with it.
const SHARED_KEYS = [
  { group: "Go", rows: [["1", "Boards"], ["2", "Your asks"], ["3", "Drafts"],
                        ["g b", "the hub"], ["g a", "your asks"], ["g d", "drafts"]] },
  { group: "Everywhere", rows: [["t", "light and dark"], ["?", "this reference"],
                                ["esc", "close it"]] },
];
const keysTable = (groups) => `<table><tbody>` + groups.map((g) =>
  `<tr><td colspan="2" class="grouphead"></td></tr>` +
  g.rows.map(() => `<tr><td></td><td></td></tr>`).join("")).join("") + `</tbody></table>`;
// built as structure first and filled as text, so a label can never be markup
function fillKeys(pane, groups) {
  pane.innerHTML = keysTable(groups);
  const rows = [...pane.querySelectorAll("tr")];
  let i = 0;
  for (const g of groups) {
    rows[i++].querySelector("td").textContent = g.group;
    for (const [key, what] of g.rows) {
      const tds = rows[i++].querySelectorAll("td");
      tds[0].replaceChildren(...key.split(" ").map((k) => {
        const el = document.createElement("kbd"); el.textContent = k; return el; }));
      tds[1].textContent = what;
    }
  }
}

// ? opens the page's help, on every page that mounted one
let theHelp = null;
const registerHelp = (h) => { theHelp = h; return h; };

// One key map for all three, so the entrance behaves like the board.
// A page that already owns a richer key map says so with data-keys="own" on
// <html> and handles t and the view digits itself. The board does: its keys are
// suppressed while a modal, a picker or the note popover is open, and this
// handler has no such guard, so without the opt-out t would fire twice and would
// fire inside overlays that deliberately swallow it.
addEventListener("keydown", (e) => {
  if (document.documentElement.dataset.keys === "own") return;
  // optional call: a keydown whose target is the document has no .matches, and
  // the throw used to take the whole handler with it
  if (e.target.matches?.("input,textarea,[contenteditable]")) return;
  if (e.metaKey || e.ctrlKey || e.altKey) return;
  if (gArmed) { clearTimeout(gArmed); gArmed = null;
    if (GO[e.key]) { location.href = GO[e.key]; return; } }
  if (e.key === "g") { gArmed = setTimeout(() => { gArmed = null; }, 1400); return; }
  if (e.key === "?" && theHelp) { theHelp.open(); return; }
  if (e.key === "t") return toggleTheme();
  const hit = document.querySelector(`.views a[data-k="${e.key}"]`);
  if (hit) hit.click();
});
