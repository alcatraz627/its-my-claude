// match.js — what a view MEANS, in one place.
//
// The board filters on every keystroke, so matching has to run in the browser;
// the CLI has to answer `view <name>` the same way. lib.ts cannot be loaded by
// a page and shared.js touches the DOM at load, so neither could host this.
// A file with no imports and no DOM can be <script>-tagged AND imported by
// bun, which is the only shape that makes "the two surfaces cannot disagree"
// true rather than aspirational.

// A view is a NAME over a QUERY, never a list of card ids: it is right
// tomorrow without anyone maintaining it (#39, charter §11).
const VIEW_LIMITS = { nameMin: 2, nameMax: 40, maxClauses: 4, maxWords: 1 };

// The grammar the board already understood, written down. A clause the CLI
// cannot name is one the owner would have to learn by reading source.
const CLAUSE_GRAMMAR = [
  "is:open", "is:blocked", "is:settled", "needs-you", "review-me",
  "since:new", "since:moved", "since:done", "since:blocked",
  "tag:<kind>:<name>", "<a word to search for>",
];
const isKnownClause = (c) =>
  CLAUSE_GRAMMAR.includes(c) || c.startsWith("tag:") || !/^(is|since):/.test(c);

// ctx supplies the things only a caller knows: what "recently" means on this
// board, and where the notes and tags live.
function matchClause(card, clause, ctx) {
  const c = String(clause ?? "").trim().toLowerCase();
  if (!c) return true;
  switch (c) {
    case "needs-you":     return !!card.verify?.needsHuman;
    case "review-me":     return ctx.reviewOf(card.id);
    case "is:blocked":    return card.lane === "blocked";
    case "is:open":       return card.lane !== "done" && card.lane !== "stale";
    case "is:settled":    return card.lane === "done" || card.lane === "stale";
    case "since:done":    return ctx.since(card.updatedAt) && card.lane === "done";
    case "since:blocked": return ctx.since(card.updatedAt) && card.lane === "blocked";
    case "since:new":     return ctx.since(card.createdAt);
    case "since:moved":   return ctx.since(card.updatedAt) && card.lane !== "done"
                                 && card.lane !== "blocked" && !ctx.since(card.createdAt);
  }
  if (c.startsWith("tag:")) {
    const want = c.slice(4);
    return ctx.tagsOf(card.id).some((t) =>
      `${t.kind}:${t.name}`.toLowerCase() === want || t.name.toLowerCase() === want);
  }
  const hay = [card.title, card.heading, card.tag, card.source?.path, ctx.noteOf(card.id),
    ...(card.subs ?? []).map((s) => s.title)].filter(Boolean).join(" ").toLowerCase();
  return hay.includes(c);
}
// clauses are ANDed; OR and NOT are deferred until a view needs them
const matchView = (card, clauses, ctx) => clauses.every((cl) => matchClause(card, cl, ctx));

// A classic script in the browser, where these become globals; a CommonJS
// module under bun, which re-exports them. No "export" keyword, because that
// is a syntax error in a plain <script> and the board loads it as one.
if (typeof module !== "undefined" && module.exports)
  module.exports = { VIEW_LIMITS, CLAUSE_GRAMMAR, isKnownClause, matchClause, matchView };
