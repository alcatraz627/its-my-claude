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
  // The two absence clauses. Every other clause here names something a card
  // HAS, and the grammar had no way to ask what a card LACKS — so `sync` could
  // end with "24 still unnamed, 46 untagged" and then offer only one-at-a-time
  // fixes, with no way to list the cards it had just counted. A message that
  // opens a loop has to be able to close it. (automation, 2026-08-26, from
  // populating a 69-card board: "the only route is status --cards and reading
  // 60 lines by eye".)
  "is:unnamed", "is:untagged",
  "since:new", "since:moved", "since:done", "since:blocked",
  "tag:<kind>:<name>", "<a word to search for>",
];
// The two operator words. They are grammar, not clauses: they never match a
// card, they do not count against maxClauses, and a view made only of them
// selects nothing in particular.
const OPERATORS = new Set(["or", "not"]);
const isOperator = (c) => OPERATORS.has(String(c ?? "").trim().toLowerCase());
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
    // Unnamed means no HUMAN name: an auto-generated brief is a starting point,
    // not a name, and it is exactly what the sync digest is counting when it
    // says "124 auto-named, 22 still unnamed".
    case "is:unnamed":    return !card.titleBrief || !!card.briefAuto;
    case "is:untagged":   return ctx.tagsOf(card.id).length === 0;
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
// The full grammar, ruled by the owner on 2026-08-23 (D4b). Precedence, from
// that ruling: NOT binds a single clause, AND binds tighter than OR, and there
// are no parentheses. AND is still the space between two clauses, so every
// view written before this parses to exactly what it did before.
//
//   is:open not tag:area:docs           -> open AND (not docs)
//   tag:milestone:M2 is:blocked or review-me
//                                       -> (M2 AND blocked) OR (review-me)
//
// Parsed once rather than per card, because the board re-filters on every
// keystroke across every card and the parse does not depend on the card.
function parseQuery(clauses) {
  const groups = [];
  let current = [];
  let negateNext = false;
  for (const raw of clauses ?? []) {
    const c = String(raw ?? "").trim().toLowerCase();
    if (!c) continue;
    if (c === "or") {
      // A trailing or dangling `or` starts a group that never fills; dropping
      // the empty one keeps `a or` meaning `a` rather than matching everything.
      if (current.length) groups.push(current);
      current = []; negateNext = false;
      continue;
    }
    if (c === "not") { negateNext = true; continue; }
    current.push({ clause: c, neg: negateNext });
    negateNext = false;
  }
  if (current.length) groups.push(current);
  return groups;
}

// A parsed query matches when ANY group matches, and a group matches when
// EVERY term in it does. An empty query matches everything, which is what an
// empty filter box has always meant.
function matchParsed(card, groups, ctx) {
  if (!groups.length) return true;
  return groups.some((g) => g.every((t) => {
    const hit = matchClause(card, t.clause, ctx);
    return t.neg ? !hit : hit;
  }));
}

// Parse and match in one call, for a caller holding a card and a clause list.
const matchQuery = (card, clauses, ctx) => matchParsed(card, parseQuery(clauses), ctx);

// The name every existing caller already uses. Kept, and now the full grammar:
// a clause list with no `or` and no `not` parses to one AND group, which is
// what this did before.
const matchView = matchQuery;

// A classic script in the browser, where these become globals; a CommonJS
// module under bun, which re-exports them. No "export" keyword, because that
// is a syntax error in a plain <script> and the board loads it as one.
if (typeof module !== "undefined" && module.exports)
  module.exports = { VIEW_LIMITS, CLAUSE_GRAMMAR, OPERATORS, isOperator,
                     isKnownClause, matchClause, parseQuery, matchParsed, matchQuery, matchView };
