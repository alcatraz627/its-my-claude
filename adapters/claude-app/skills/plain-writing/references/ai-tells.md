# AI tells

The patterns that make a reader sense a language model wrote the text, each
with its fix. Ordered roughly by how strongly they signal it.

| Tell | Example | Fix |
|---|---|---|
| Em-dashes as connective tissue | "Upload is fast — and it scales." | Period, colon, comma or parentheses. Budget is zero. |
| Rule-of-three triads | "Fast, reliable, and scalable." | Write the true count: two or four if that is what there is |
| "Not X, it's Y" antithesis | "It's not a mapping: it's a contract." | State what the thing is |
| Narrative setup before the noun | "Before a customer can do anything, they need..." | Lead with the subject: "Upload is the first step of every job." |
| Metaphors for mechanics | dance, handoff, orchestrates, under the hood, behind the scenes, dives into | Say what the code does |
| Editorial hedges | deceptively, surprisingly, interestingly, crucially, notably, importantly | Show the importance with a fact |
| Filler adverbs | simply, just, essentially, basically, actually, really, quite, obviously | Delete |
| Hedged assertions | typically, generally, usually, in most cases, tends to | State the condition, or the measured number with its source |
| Meta-commentary | "It's worth noting", "In this section we'll walk through" | Delete; the heading already says it |
| Nominalizations | "The validation of the map is the responsibility of the endpoint" | "The endpoint validates the map." |
| Marketing words | seamless, robust, powerful, intuitive, elegant, comprehensive | Name the actual behavior |
| Capability framing | "This allows us to reuse it" | Describe what happens: "On reconfigure, the saved map loads as the default." |
| Lecture transitions | "Now that we've covered X, let's look at Y" | New heading, no transition |
| Vague headings | and beyond, and more, deep dive, putting it all together | Name the section's actual scope |
| Uniform rhythm | Every bullet the same length, every section the same shape | Let importance set length |
| Bold-label bullet armies | Ten bullets in a row starting "**Term:** sentence" | Use a table, or plain prose |
| Echo summaries | "In short, the transaction keeps billing safe." | Delete; the reader just read it |
| Sweeping ranges | "From quick lookups to deep audits" | Name the real cases |
| Over-bolding | A bold phrase in every sentence | One bold term per section, at most |
| Precision theater | "Approximately ~5s or so" | One qualifier, or the measured value |
| Placeholder examples | foo, bar, Acme Corp, John Doe | Use a real (sanitized) value |
| Anthropomorphized code | "The function happily accepts" | Code has no moods |
| Self-labeled scope | "A comprehensive guide to..." | "Covers X. Does not cover Y." |
| Defensive framing | "Two things are both true here, so neither is mistaken" | State both facts flat, without the framing |

## Find-and-flag words

Search the draft for these. Not every hit is wrong, but every hit deserves a
second look:

seamless, robust, powerful, intuitive, simply, just, essentially, basically,
actually, typically, generally, under the hood, behind the scenes, it's worth
noting, allows us to, let's, dive into, walk through, deep dive, deceptively,
surprisingly, not just, hunt for, dance, handoff, and beyond, and more,
load-bearing, in this section, crucially, notably, importantly, comprehensive,
in short, in conclusion, happily, gracefully

## Common regressions while fixing

- Over-correcting into telegram prose. Keep complete sentences.
- Swapping one cliché for another ("at its core" for "under the hood").
- Losing the fact while deleting the voice. "A sloppy config shows up four
  steps later" is bad voice but holds a real fact. Keep the fact.
- Section intros regress first. Give them a final pass on their own.
