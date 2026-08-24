// kinds.js — what KINDS of thing this app has, in one place.
//
// The app addresses things at two levels, a KIND and an INSTANCE within it, and
// the kinds used to be written out by hand in every consumer: the navbar's map,
// a CSS rule per hue, the search palette, the board switcher. Adding a fourth
// meant finding all of them. The count is whatever this file declares.
//
// No imports and no DOM at load, so a page can <script> it and bun can require
// it. Same shape as match.js, same reason. Why not three: NAV-UNIFICATION.md.

const KINDS = [
  {
    id: "boards",
    label: "Boards",                 // the human word (charter §2), on the tab
    // What the crumb calls the kind's index: "All <indexLabel>". Separate from
    // label because the tab wants the owner's word and the crumb wants a
    // plural that reads after "All": the tab says "Your asks", the crumb says
    // "All asks", never "All your asks".
    indexLabel: "boards",
    href: "/",
    key: "1",                        // the number that reaches it
    hue: "--blue",                   // the kind's accelerator tint, on top of grouping
    tip: "Every project an agent is working on",
    // Where this kind's instances come from, and how to read them out of the
    // response. Everything that asks "what is there, of this kind" — the tab's
    // count, the palette, the board's search — goes through this one pair, so
    // the count and the list can never disagree about what counts.
    api: "/api/boards",
    listOf: (j) => j.boards ?? [],
    // Where this kind sits in the board's search results. SEARCH-DESIGN.md §4
    // ranks by how often the intent occurs, which is not the order the tab bar
    // shows: from inside a board, "which board" is the least local question and
    // comes last.
    searchRank: 3,
    // Switched in place by a page that owns both views, rather than navigated.
    inPage: true,
    icon: `<svg width="13" height="13" viewBox="0 0 16 16" fill="none"><rect x="1.8" y="2.6" width="5" height="10.8" rx="1.4" stroke="currentColor" stroke-width="1.2"/><rect x="9.2" y="2.6" width="5" height="6.6" rx="1.4" stroke="currentColor" stroke-width="1.2"/></svg>`,
  },
  {
    id: "asks",
    label: "Your asks",
    indexLabel: "asks",
    href: "/?view=asks",
    key: "2",
    hue: "--amber",
    tip: "Things you wrote down for an agent to sort",
    searchRank: 1,
    api: "/api/items",
    // An ask that has landed on a board is a card now, and an archived one is
    // put away: neither is something to go to.
    listOf: (j) => (j.items ?? []).filter((i) => !i.landing && !i.archived),
    inPage: true,
    icon: `<svg width="13" height="13" viewBox="0 0 16 16" fill="none"><path d="M3.4 2.6h9.2v8.2L9.4 13.4H3.4V2.6Z" stroke="currentColor" stroke-width="1.2" stroke-linejoin="round"/><path d="M12.6 10.8H9.4v2.6" stroke="currentColor" stroke-width="1.2" stroke-linejoin="round"/></svg>`,
  },
  {
    id: "drafts",
    label: "Drafts",
    indexLabel: "drafts",
    href: "/drafts",
    key: "3",
    hue: "--violet",
    tip: "Your documents, the rung above an ask",
    searchRank: 2,
    api: "/api/drafts",
    listOf: (j) => (j.drafts ?? []).filter((d) => !d.isTemplate),
    inPage: false,                   // a real page; let the link navigate
    icon: `<svg width="13" height="13" viewBox="0 0 16 16" fill="none"><path d="M10.6 2.8 13.2 5.4 5.6 13H3v-2.6l7.6-7.6Z" stroke="currentColor" stroke-width="1.2" stroke-linejoin="round"/></svg>`,
  },
  {
    id: "decisions",
    label: "Decisions",
    indexLabel: "decisions",
    href: "/?view=decisions",
    key: "4",
    hue: "--teal",
    tip: "Pages an agent built for you to rule on",
    searchRank: 4,
    api: "/api/surfaces",
    // the tab is an indicator: it counts what NEEDS you, the way asks does;
    // the hub's own view still lists every page, answered ones included
    listOf: (j) => (j.decisions ?? []).filter((d) => d.pending),
    inPage: true,
    icon: `<svg width="13" height="13" viewBox="0 0 16 16" fill="none"><rect x="2.2" y="2.2" width="11.6" height="11.6" rx="2" stroke="currentColor" stroke-width="1.2"/><path d="M5.2 8.3 7.1 10.2 10.8 5.9" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
  },
  {
    id: "previews",
    label: "Previews",
    indexLabel: "previews",
    href: "/?view=previews",
    key: "5",
    hue: "--pink",
    tip: "One-off pages agents rendered for you to look at",
    searchRank: 5,
    api: "/api/surfaces",
    listOf: (j) => j.previews ?? [],
    inPage: true,
    icon: `<svg width="13" height="13" viewBox="0 0 16 16" fill="none"><path d="M1.8 8S4.2 3.6 8 3.6 14.2 8 14.2 8 11.8 12.4 8 12.4 1.8 8 1.8 8Z" stroke="currentColor" stroke-width="1.2"/><circle cx="8" cy="8" r="1.8" stroke="currentColor" stroke-width="1.2"/></svg>`,
  },
  // Sessions lands here when its page does (CHAT-HISTORY.md, D-ch-1..3). It is
  // a kind, not a special case: one entry, and the navbar, the hue, the key and
  // the palette all follow. Nothing else has to be edited to add it, which is
  // the whole point of this file.
];

const kindIds = () => KINDS.map((k) => k.id);
const kindById = (id) => KINDS.find((k) => k.id === id);
// The label a person reads. Falls back to the id so an unregistered kind shows
// as something rather than as blank.
const kindLabel = (id) => kindById(id)?.label ?? id;

// A classic script in the browser, where these become globals; a CommonJS
// module under bun. No "export" keyword: that is a syntax error in a plain
// <script>, and the pages load this as one.
if (typeof module !== "undefined" && module.exports)
  module.exports = { KINDS, kindIds, kindById, kindLabel };
