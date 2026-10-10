## session: v6 system of records proposal deck [sor-plan-7f] · 2026-09-28

**Purpose:** a thirteen-slide alignment deck for the CEO, PM, and engineers, built from a nine-doc planning suite and a working mock, in-project at sor/deck.

**Insights:**
- The outline dropped the second-problem slide and the honest-numbers slide; the mock slide carries the one number (28 checks) and its notes carry what is not built. The diagram sits sixth, after the definition and requirements, because the argument had to be made before the picture.
- lint went 3 to 0 in one pass, all on one slide: nine principles as bullets became a two-column table, and "import, run, and export" became "every run".
- Two side-by-side 2880px screenshots in a flex row overflowed sideways and were unreadable; one full-width screenshot with object-fit cover and max-height reads.
- A leave line said "four paying customers" where the source says three paying and one on speculation; caught by reading the screenshot, not by any script.

---

## session: foundry and walmart deck [forge-brains] · 2026-09-05

**Purpose:** a fourteen-slide briefing on the walmart port, built from the plan of record, integration's audit, the parity and cutover pages and the caller contract.

**Insights:**
- The outline dropped the second-problem slide and moved the diagram to third; the argument had to open before the picture.
- render.py read a store row id written as `#637` as a hex colour literal; write row numbers as words or `row 637`.
- lint went 14 to 0 in one pass: eight bullets over 140 chars, two slides over 90 words, one numbers slide with no source word. The cure was splitting sentences and moving the source phrase into the notes, and the render then flagged the slide the extra bullet pushed over budget.
- The opus reviewer returned 104 rows, 97 supported: one contradiction (a heading said four rungs done, the table said three), four overstatements (a stale test count in the present tense, "five things" the runbook counts as six, "the same copy" where only bytes are proven, "every row" where only walmart's rows were driven live), two unsourced presenter notes. Every one was in the author's own summarising words, never in a quoted number.
- The reviewer spot-checked the audit's code citations and found one loose line range; a deck that cites an audit inherits the audit's anchors.

---

## session: versable-canon deck rebuild [vb-fable] · 2026-08-18

**Purpose:** rebuilt the versable-builder canon deck from the previous night's deck as material only, on the updated skill.

**Insights:**
- The outline left the skeleton at two problem slides plus a where-the-cost-sits slide before the picture, and two proof slides; the adversary said the picture slide is where "so what" starts, so the argument had to be made before it.
- lint went 43 to 6 to 0: nearly all bullets over 140 chars and slides over 90 words; the cure was moving detail into notes, not rewording.
- The claim reviewer (sonnet low) found 4 contradictions in a deck written from a fresh evidence ledger: a number attached to the wrong instance (three call sites belonged to a different Select duplicate), a quote attributed to the pass that surfaced it instead of the owner, a "caught by" cell inverted, and a file count nobody could reproduce. A ledger is a pointer, not a proof; the reviewer re-ran the commands.
- An opus adversary pass on "will anyone care" is worth its seat: it named the one TALKS slide sitting where persuasion happens and a defensive tone the author could not see (titles asserting honesty, notes braced for "why a week"). Fixed in thirty minutes.
- automation's four points came in over ipc and made three slides better than the ledger could; ask the sibling lanes early.

---

