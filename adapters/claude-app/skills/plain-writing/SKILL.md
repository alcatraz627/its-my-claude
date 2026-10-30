---
name: plain-writing
description: Writing standard for docs, READMEs, reports, PR text, emails and release notes. Plain, verdict-last, no AI tells. Use when drafting or cleaning up prose that people will read.
---

# Plain writing

For any text a person reads as a document: docs, READMEs, reports, RCAs,
changelogs, PR descriptions, emails, announcements. Not for code, and not for
ordinary chat replies.

## What good looks like

1. **One idea per sentence, in the order the reader needs it.** Condition
   first, then the instruction. Cause before effect.
2. **A named actor doing a named action.** "The parser reads the file."
3. **One name per thing, every time.** A second name reads as a second thing,
   so repeating the noun is correct.
4. **Facts before any conclusion.** State what is done, what is not, and what
   needs review. Any verdict comes last and reads as advisory. Never open with
   Done, Perfect, Complete or Live.

## Rules

- **Words.** The short common word: use, start, help, before, about, get,
  show, also. No marketing adjectives (seamless, robust, powerful, intuitive,
  comprehensive).
- **Verbs.** Active voice with a named actor. "Analyze the log", not "perform
  an analysis of the log".
- **Sentences.** At most 20 words for an instruction, 25 for description.
- **Punctuation.** Zero em-dashes. No semicolons. Restructure with a period,
  colon, comma or parentheses.
- **Paragraphs.** One topic each, six sentences at most. Steps go in a
  numbered list, one action per item.
- **Structure.** Three or more items that share fields go in a table. One
  causal thread stays prose. Section titles name what the reader searches for
  ("Quota checks"), not a story beat ("What happens next").
- Write only the requested text. No preamble and no closing remarks.

## Two modes

- **Strict** for procedures, runbooks and error messages, where a misreading
  costs something. Every rule applies, plus no contractions.
- **Flavored** for READMEs, PR descriptions and general docs. Keeps the
  sentence, voice and verdict-last rules but reads naturally. Flavored is not
  strict with fewer words: it keeps a human voice.

## Do not flatten these

- A deliberate passive that keeps the actor out on purpose
- Domain terms and identifiers: keep the name the domain already uses
- Quotes, error strings and command output: rewriting a quote misquotes it
- Numbers, paths and citations: precision is content

## Reports and reviews

Each finding runs symptom, impact, path, detail, in that order. The symptom
is what breaks at the level the reader sees it. The impact is why it matters.
The path is how the visible thing connects to the buried one. The detail (the
file and line, the flag) ends a finding and is never the whole of it.

Say what was examined and why before listing findings. Caveats are content: a
summary keeps the original claim's qualifiers ("unconfirmed", "only for new
accounts") or does not make the claim. Every number points to a source the
reader can check.

## Judged deliverables (PR text, READMEs, announcements)

- Read two or three accepted examples from the same place first. They carry
  the register the reader already said yes to.
- Show the content list before writing prose. The wrong list, rewritten
  nicely, is the expensive failure.
- One rejection means redraft. A second rejection means ask what is wrong,
  because your model of what they want is off.
- Start every redraft from the original request, not the latest objection.
- When told a sentence is wrong, fix the claim. Deleting it drops content.

## Before handing it over

Check the draft against `references/ai-tells.md`. A list of tells is a
detector, not a ban list: a doc can pass every entry and still read
generated. The test is whether a reader who distrusts AI-written docs would
take the page seriously.
Then check `references/language-quality.md` for structural defects.

You cannot see your own voice. If a fresh reviewer (a new chat, or another
person) is available for a voice pass, use one.
