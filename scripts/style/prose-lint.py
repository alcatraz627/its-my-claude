#!/usr/bin/env python3
"""The prose engine: one definition of every writing tell, asked by every prose gate.

lint(text) is the original scorer (thesaurus-aligned lexicons; taxonomy and
provenance: style/sweep/20260727-simple-lang/). lint(text, surface) is the
engine: it returns the same score plus a list of findings, each naming the tell
(ids from the P0 inventory), where it sits in the text, and what the surface
does about it (block, block-pair, warn, score), read from style/profiles.json.
A surface is one of chat, doc, commit, github, deck, word, comment, ui_string.

CLI: FILE(s) | --json | stdin '-'; --profile SURFACE prints the findings as JSON
(--only a,b limits it to those tell ids). Exits 0 always (a linter reports;
gates decide). Override the profile file with PROSE_PROFILES=path.
Design and migration notes: features/prose-and-voice.md.
"""
import bisect, importlib.util, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))


def _load_core():
    name = "readability_core"
    mod = sys.modules.get(name)
    if mod is None:
        spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, name + ".py"))
        mod = importlib.util.module_from_spec(spec)
        sys.modules[name] = mod
        spec.loader.exec_module(mod)
    return mod


_RC = None


def core():
    """The readability module, loaded on first use so the scorer and the chat and
    comment checks keep working when only this file has been copied somewhere."""
    global _RC
    if _RC is None:
        _RC = _load_core()
    return _RC

BE = r"(?:am|is|are|was|were|be|been|being)"
PP_IRREG = r"(?:done|made|sent|read|built|kept|held|set|put|run|written|shown|given|taken|found|seen|known)"

# lexicons are thesaurus-aligned (style/thesaurus.jsonl), not STE's list
JARGON = ["leverage","leverages","leveraging","highest-leverage","high-leverage","utilize","utilizes",
    "facilitate","facilitates","delve","delves","comprehensive","comprehensively","crucial","vital",
    "seamless","seamlessly","robust","robustly","holistic","synergy","paradigm","cutting-edge",
    "effortless","world-class","revolutionary","elegant","delightful","turnkey","state-of-the-art",
    "game-changing","battle-tested","enterprise-grade","supercharge","unleash","production-ready"]
FILLER = ["simply","essentially","basically","in order to","a variety of","worth noting",
    "it's important to note","it is important to note","it should be noted","it's worth noting",
    "keep in mind","needless to say","as you can see","at the end of the day"]
HEDGE_ASSERT = ["typically","generally","usually","in most cases","for the most part"]
UNVERIFIED = ["should now work","should work now","should be fixed","that should do it",
    "this should fix","should be working"]
VERDICT_OPENER = re.compile(
    r"^\W*(?:\*\*)?(?:(?:Done|Perfect|Excellent|Awesome|Fantastic|Beautiful|Completed|Shipped)\s*[.!:—]|"
    r"All (?:done|set|good)\b|Everything (?:is|works)\b|Release is live\b)", re.I)
META_ID = re.compile(r"\b(?:thes|mist|aff|pin)-\d{8}")
# Zero budget (owner ruling D4a): any em dash counts, however it is spaced. An en dash
# counts only as a connective (spaced, or between letters), so digit ranges never do.
DASH = re.compile(r"—|\s–\s|(?<=[A-Za-z])–(?=[A-Za-z])")
# two high-precision forms only; a bare "not X" before a dash catches plain negation (validated 2026-07-27)
NOT_BUT = r"\bnot\s+[^.;,]{2,40},?\s+but\s+"
CONTRASTIVE_NOT_BUT = re.compile(NOT_BUT, re.I)
CONTRASTIVE = re.compile(NOT_BUT + r"|[—–]\s*it'?s\b", re.I)

# Named tells reported but not yet scored (weight 0), so existing gates keep
# their thresholds while the backlog is rewritten. Proposed once it lands:
# weight 1.5 each, which puts a doc with one per 100 words near the block line.
#
# contrast_list: chained negations ("not X, not Y, but Z", "isn't X, isn't Y")
# and the semicolon/colon antithesis ("It's not about A; it's about B").
CONTRAST_LIST = re.compile(
    r"\b(?:not|isn'?t|aren'?t|wasn'?t|doesn'?t|don'?t)\s+[^.;:,]{2,40},\s*(?:and\s+|nor\s+)?(?:not|isn'?t|aren'?t|never|no)\s+[^.;:]{2,40}"
    r"|\b(?:it|this|that|these|those)(?:'s|\s+is|\s+isn'?t|\s+is\s+not)\s+(?:not\s+)?(?:just\s+|only\s+)?(?:about\s+)?[^.;:]{2,40}[;:]\s*(?:it|this|that)'?s\b",
    re.I)
# split_phrase: one sentence cut in two by a colon or semicolon, each half long
# enough to stand alone, the second half starting lowercase (a spliced
# elaboration). Dashes are counted by two_split_dash; list intros (the tail has
# two or more commas) and short label rows never match.
SPLIT_PHRASE = re.compile(r"^[^:;—–]{25,}[:;]\s+[a-z][^:;—–]{20,}$")

# Chat tells. Patterns copied from format-gate-stop.sh, which now asks this engine.
_WS = r"[ \t\r\f\v]"            # POSIX [[:space:]] without the newline: chat checks run per line
PRAISE_OPENER = re.compile(
    r"^(you'?re (absolutely |completely |exactly )?right|great (question|point|idea|catch)|excellent|perfect[.!]|fair question|what a )",
    re.I)
LABEL_CHAT = re.compile(r"^" + _WS + r"*[-*•]?" + _WS + r"*\*\*[^*]{2,40}\*\*" + _WS + r"*:")
BOLD_SPAN = re.compile(r"\*\*[^*]+\*\*")
DECORATION_EMOJI = re.compile(
    r"^" + _WS + r"*(#{1,6}" + _WS + r"*)?(\U0001F534|\U0001F7E1|\U0001F7E2|\U0001F7E0|\U0001F6A6|\U0001F3AF|"
    r"\U0001F680|\U0001F525|\U0001F4A1|\U0001F4CA|\U0001F9E0|✨|\U0001F6D1|\U0001F4CC|⚡|❗|"
    r"✅|⚠️|❌)")
STAR = "★"
OPTION_MENU = re.compile(r"(would you like me to|do you want me to|shall i|want me to) .+ or .+\?", re.I)
# Comment emoji: whole Unicode blocks, anywhere in the comment (arrows excluded on purpose).
COMMENT_EMOJI = re.compile("[\U0001f000-\U0001faff\U00002600-\U000026ff\U00002700-\U000027bf\U0001f1e6-\U0001f1ff]")
# Word-doc Label:fragment: the colon sits inside the bold and text must follow.
LABEL_WORD = re.compile(r"^\s*(?:[-*]\s+)?\*\*[^*]{1,40}:\*\*\s+\S")

# One em-dash rule per surface (the zero budget applies everywhere; they differ only in
# how an en dash is read).
DASH_FOR = {
    "chat": re.compile(r"—"),
    "doc": DASH, "commit": DASH, "ui_string": DASH,
    "deck": re.compile(r"—"), "word": re.compile(r"—"),
    "comment": re.compile(r"—|\s–\s"),
}


def dash_rule(surface):
    """The em-dash pattern for a surface. GitHub text uses the readability module's
    rule (any em dash; an en dash unless it sits between digits)."""
    return core().DASH if surface == "github" else DASH_FOR[surface]

WEIGHTS = {"fused_25_35": 1, "fused_35_50": 3, "fused_over_50": 6, "two_split_dash": 1,
           "contrastive_scaffold": 1.5, "verdict_first_opener": 3, "unverified_claim": 4,
           "filler_hedge": 1.5, "hedged_assertion": 1, "jargon_marketing": 2,
           "passive": 1, "nominalization": 1, "semicolon": 0.5,
           "split_phrase": 0, "contrast_list": 0}

# Which tell id owns each score key.
KEY_TELL = {"fused_25_35": "sentence-length", "fused_35_50": "sentence-length", "fused_over_50": "sentence-length",
            "two_split_dash": "em-dash", "contrastive_scaffold": "contrastive-scaffold",
            "verdict_first_opener": "verdict-opener", "unverified_claim": "unverified-claim",
            "filler_hedge": "filler-hedge", "hedged_assertion": "hedged-assertion",
            "jargon_marketing": "jargon-marketing", "passive": "passive", "nominalization": "nominalization",
            "semicolon": "semicolon", "split_phrase": "two-split", "contrast_list": "contrast-list"}

# Treatment for tells style/profiles.json does not list: today's behaviour, unchanged.
# A tell the file lists always wins.
_SCORE_DOC = {"doc": "score", "commit": "score"}
DEFAULT_ACTIONS = {
    "star-decoration": {"chat": "warn"},
    "option-menu-closer": {"chat": "warn"},
    "mechanism-run": {"doc": "warn", "github": "block"},
    "filler-hedge": _SCORE_DOC, "hedged-assertion": _SCORE_DOC, "passive": _SCORE_DOC,
    "nominalization": _SCORE_DOC, "semicolon": _SCORE_DOC, "two-split": _SCORE_DOC,
}
SCORING_ACTIONS = ("score", "block", "block-pair")
CAP_ALIAS = {"commit": "doc"}      # a commit adds doc lines, so it keeps the doc cap
DEFAULT_PROFILES = os.path.join(HERE, "..", "..", "style", "profiles.json")
_PROFILE_CACHE = {}
# Built-in copy of style/profiles.json, used only when that file cannot be found beside
# this script (a standalone copy of the engine). A test keeps it equal to the file.
_FALLBACK_JSON = (
    '{"actions":{"block":"the gate refuses the reply, write or commit","block-pair":"counts towar'
    'd a block when two or more block-pair tells appear together (chat only)","warn":"a note to t'
    'he agent; nothing is refused","score":"adds its weight to the prose-lint score; a score abov'
    'e lint_score_block blocks","off":"not checked on this surface"},"surfaces":{"chat":"the agen'
    't\'s final reply (format-gate-stop.sh)","doc":"markdown, html and txt written by Edit or Writ'
    'e (guard-prose-quality.sh, doc-voice-gate.py)","commit":"lines a commit adds to gcc docs (gi'
    't-prose-gate.py)","github":"text bound for GitHub (guard-gh-prose.py)","deck":"slides (scrip'
    'ts/deck/lint.py)","word":"Word docs (scripts/word-doc/lint.py)","comment":"code comments (gu'
    'ard-comment-hygiene.sh, cleanup-comments)","ui_string":"user-facing string literals in code '
    '(code-copy-lint.py)"},"caps":{"sentence_words":{"doc":25,"deck":25,"word":30,"procedure":20,'
    '"chat":null},"lint_score_block":8,"chat_prose_chars":{"warn":1500,"block":2600}},"tells":{"e'
    'm-dash":{"pattern":"any U+2014, irrespective of usage (D4a)","chat":"block","doc":"block","c'
    'ommit":"block","github":"block","deck":"block","word":"block","comment":"warn","ui_string":"'
    'block"},"verdict-opener":{"chat":"warn","doc":"block","commit":"block","github":"off","deck"'
    ':"off","word":"off","comment":"off","ui_string":"off"},"praise-opener":{"chat":"block-pair",'
    '"doc":"off","commit":"off","github":"off","deck":"off","word":"off","comment":"off","ui_stri'
    'ng":"off"},"label-fragment":{"chat":"block-pair","doc":"off","commit":"off","github":"off","'
    'deck":"off","word":"warn","comment":"off","ui_string":"off"},"bold-spam":{"chat":"block-pair'
    '","doc":"off","commit":"off","github":"off","deck":"off","word":"off","comment":"off","ui_st'
    'ring":"off"},"decoration-emoji":{"chat":"block-pair","doc":"off","commit":"off","github":"of'
    'f","deck":"off","word":"off","comment":"warn","ui_string":"off"},"contrastive-scaffold":{"ch'
    'at":"warn","doc":"score","commit":"score","github":"off","deck":"off","word":"off","comment"'
    ':"off","ui_string":"off"},"contrast-list":{"chat":"off","doc":"score","commit":"block","gith'
    'ub":"off","deck":"off","word":"off","comment":"off","ui_string":"off"},"sentence-length":{"c'
    'hat":"off","doc":"score","commit":"score","github":"off","deck":"warn","word":"warn","commen'
    't":"off","ui_string":"off"},"lint-score-block":{"chat":"off","doc":"block","commit":"block",'
    '"github":"off","deck":"off","word":"off","comment":"off","ui_string":"off"},"jargon-marketin'
    'g":{"chat":"off","doc":"score","commit":"score","github":"off","deck":"off","word":"off","co'
    'mment":"off","ui_string":"block"},"unverified-claim":{"chat":"off","doc":"score","commit":"s'
    'core","github":"off","deck":"off","word":"off","comment":"off","ui_string":"block"},"dense-b'
    'lock":{"chat":"off","doc":"warn","commit":"off","github":"block","deck":"off","word":"off","'
    'comment":"off","ui_string":"off"},"spliced-line":{"chat":"off","doc":"warn","commit":"off","'
    'github":"block","deck":"off","word":"off","comment":"off","ui_string":"off"}}}'
)


def profiles_path():
    return os.environ.get("PROSE_PROFILES") or DEFAULT_PROFILES


def load_profiles(path=None):
    """style/profiles.json (or the PROSE_PROFILES override), re-read when it changes."""
    p = os.path.abspath(path or profiles_path())
    if not os.path.exists(p) and not path and not os.environ.get("PROSE_PROFILES"):
        return json.loads(_FALLBACK_JSON)
    st = os.stat(p)
    key = (p, st.st_mtime_ns, st.st_size)
    hit = _PROFILE_CACHE.get(p)
    if hit and hit[0] == key:
        return hit[1]
    with open(p, encoding="utf-8") as f:
        data = json.load(f)
    _PROFILE_CACHE[p] = (key, data)
    return data


def action_for(tell, surface, profiles=None):
    """What the surface does about the tell: block, block-pair, warn, score or off."""
    profiles = profiles or load_profiles()
    row = (profiles.get("tells") or {}).get(tell)
    if row is None:
        row = DEFAULT_ACTIONS.get(tell, {})
    return row.get(surface) or "off"


def sentence_cap(surface, profiles=None, procedure=False):
    caps = (profiles or load_profiles()).get("caps", {}).get("sentence_words", {})
    if procedure and caps.get("procedure"):
        return caps["procedure"]
    return caps.get(surface, caps.get(CAP_ALIAS.get(surface)))


class TextView:
    """A transformed copy of some text that remembers, for every character, which
    stretch of the original it came from, so a finding made on the stripped copy
    can still point at the original."""

    def __init__(self, text, spans=None):
        self.text = text
        self._spans = spans if spans is not None else [(i, i + 1) for i in range(len(text))]

    def span(self, s, e):
        """Original (start, end) for the view range [s, e)."""
        n = len(self._spans)
        if n == 0:
            return (0, 0)
        if e <= s:
            i = min(s, n - 1)
            return (self._spans[i][0], self._spans[i][0])
        return (self._spans[s][0], self._spans[min(e, n) - 1][1])

    def sub(self, rx, repl, count=0):
        out, sp, pos, done = [], [], 0, 0
        for m in rx.finditer(self.text):
            if count and done >= count:
                break
            s, e = m.span()
            r = repl(m) if callable(repl) else repl
            out.append(self.text[pos:s]); sp.extend(self._spans[pos:s])
            if r:
                origin = self.span(s, e)
                out.append(r); sp.extend([origin] * len(r))
            pos = e
            done += 1
        out.append(self.text[pos:]); sp.extend(self._spans[pos:])
        return TextView("".join(out), sp)

    def drop_lines(self, drop):
        """Remove every line for which drop(index, line) is true, with its newline."""
        out, sp, first, pos = [], [], True, 0
        for i, line in enumerate(self.text.split("\n")):
            ls, le = pos, pos + len(line)
            pos = le + 1
            if drop(i, line):
                continue
            if not first:
                out.append("\n"); sp.append(self._spans[ls - 1])
            first = False
            out.append(line); sp.extend(self._spans[ls:le])
        return TextView("".join(out), sp)


def _line_at(t, i):
    a = t.rfind("\n", 0, i) + 1
    b = t.find("\n", i)
    return t[a:] if b < 0 else t[a:b]


def _sentence_spans(prose):
    """[start, end) of every sentence: a line, cut after . ! ? or a colon when an
    upper-case letter, digit or quote follows."""
    out, pos = [], 0
    split = re.compile(r"(?<=[.!?:])\s+(?=[A-Z0-9\"'])")
    for line in prose.split("\n"):
        base = pos
        pos += len(line) + 1
        lead = len(line) - len(line.lstrip())
        s = line.strip()
        if not s:
            continue
        cur = 0

        def add(a, b):
            part = s[a:b]
            p = part.strip()
            if p:
                off = base + lead + a + (len(part) - len(part.lstrip()))
                out.append((off, off + len(p)))
        for m in split.finditer(s):
            add(cur, m.start())
            cur = m.end()
        add(cur, len(s))
    return out


def _sentences(text):
    return [text[a:b] for a, b in _sentence_spans(text)]


def _wc(s): return len(re.findall(r"[A-Za-z0-9][A-Za-z0-9'\-/]*", s))


def _phrase_hits(text, phrases):
    """(start, end) of every phrase hit, phrase by phrase, on lower-cased text."""
    low = text.lower(); out = []
    for ph in phrases:
        for m in re.finditer(r"(?<![a-z])" + re.escape(ph) + r"(?![a-z])", low):
            out.append(m.span())
    return out


def _count(text, phrases, spans, label):
    n = 0
    for a, b in _phrase_hits(text, phrases):
        n += 1
        if len(spans[label]) < 3:
            spans[label].append(text[max(0, a-30):b+30].strip())
    return n


def strip_view(text):
    """The prose of a document: fences, quoted lines and table rows dropped, inline
    code replaced by a placeholder word."""
    v = TextView(text).sub(re.compile(r"```.*?```", re.S), " ")
    v = v.drop_lines(lambda i, l: l.lstrip().startswith((">", "|")))
    return v.sub(re.compile(r"`[^`]*`"), " CODEREF ")


def strip_code(text):
    return strip_view(text).text


def _detect(prose, cap=25, proc_cap=None):
    """Every score-key hit in stripped prose as {key: [(start, end), ...]}."""
    sp = _sentence_spans(prose)
    inst = {k: [] for k in WEIGHTS}
    words = 0
    for a, b in sp:
        w = _wc(prose[a:b])
        words += w
        c = cap
        if proc_cap is not None and re.match(r"\s*\d+[.)]\s", _line_at(prose, a)):
            c = proc_cap
        lo2, lo3 = max(35, c + 5), max(50, c + 20)
        if w > lo3: inst["fused_over_50"].append((a, b))
        elif w > lo2: inst["fused_35_50"].append((a, b))
        elif w > c: inst["fused_25_35"].append((a, b))
    inst["two_split_dash"] = [m.span() for m in DASH.finditer(prose)]
    inst["contrastive_scaffold"] = [m.span() for m in CONTRASTIVE.finditer(prose)]
    inst["split_phrase"] = [(a, b) for a, b in sp
                            if not prose[a:b].lstrip().startswith(("-", "*", "#", "|")) and SPLIT_PHRASE.match(prose[a:b])
                            and prose[a:b].split(":")[-1].count(",") < 2 and prose[a:b].split(";")[-1].count(",") < 2]
    inst["contrast_list"] = [m.span() for m in CONTRAST_LIST.finditer(prose)]
    if sp and VERDICT_OPENER.match(prose[sp[0][0]:sp[0][1]]):
        inst["verdict_first_opener"] = [sp[0]]
    inst["unverified_claim"] = _phrase_hits(prose, UNVERIFIED)
    inst["filler_hedge"] = _phrase_hits(prose, FILLER)
    inst["hedged_assertion"] = _phrase_hits(prose, HEDGE_ASSERT)
    inst["jargon_marketing"] = _phrase_hits(prose, JARGON)
    inst["passive"] = [m.span() for m in re.finditer(rf"\b{BE}\s+(?:\w+ed|{PP_IRREG})\b", prose, re.I)]
    inst["nominalization"] = ([m.span() for m in re.finditer(r"\b(?:perform(?:s|ed)?|conduct(?:s|ed)?|carry out|carries out|make use of)\b", prose, re.I)]
                              + [m.span() for m in re.finditer(r"\b\w{4,}(?:tion|ment|ance|ence)\s+of\b", prose, re.I)])
    inst["semicolon"] = [(i, i + 1) for i, ch in enumerate(prose) if ch == ";"]
    return inst, sp, words or 1


def _dash_window(prose, a, b):
    """Text around a dash for a report line. A dash set off by a space on each side
    is reported with those spaces, as the spaced-dash rule always did."""
    if a > 0 and b < len(prose) and prose[a - 1].isspace() and prose[b].isspace():
        a, b = a - 1, b + 1
    return prose[max(0, a - 40):b + 40].strip()


# Legacy report snippets: how much text surrounds a hit, and how many are kept.
_WINDOW = {"contrastive_scaffold": (20, 30), "contrast_list": (20, 30)}


def _legacy_spans(prose, inst, sp):
    spans = {k: [] for k in WEIGHTS}
    for key in ("fused_25_35", "fused_35_50", "fused_over_50"):
        spans[key] = [prose[a:b][:100] for a, b in inst[key][:3]]
    spans["two_split_dash"] = [_dash_window(prose, a, b) for a, b in inst["two_split_dash"][:3]]
    for key, (pre, post) in _WINDOW.items():
        spans[key] = [prose[max(0, a - pre):b + post].strip() for a, b in inst[key][:3]]
    spans["split_phrase"] = [prose[a:b][:100] for a, b in inst["split_phrase"][:3]]
    if inst["verdict_first_opener"]:
        a, b = inst["verdict_first_opener"][0]
        spans["verdict_first_opener"] = [prose[a:b][:100]]
    for key in ("unverified_claim", "filler_hedge", "hedged_assertion", "jargon_marketing"):
        spans[key] = [prose[max(0, a - 30):b + 30].strip() for a, b in inst[key][:3]]
    return spans


def _score(inst, words, counts):
    weighted = sum(WEIGHTS[k] * len(v) for k, v in inst.items() if counts(k))
    score = weighted * 100.0 / words
    if words < 60:                      # short texts inflate per-100w; damp linearly under 60 words
        score *= words / 60.0
    return round(score, 2)


def lint(text, surface=None, only=None, procedure=False):
    """Judge prose. Without a surface: the original scorer, {"score", "words",
    "violations", "spans"} (or {"skipped", "score"} for style-system traffic).
    With a surface (chat, doc, commit, github, deck, word, comment, ui_string): the
    same plus "findings", each {"tell", "action", "span", "line", "text", "snippet",
    "context"} for every tell the profile does not switch off there. "span" is
    [start, end) in the text you passed (null for whole-text findings). only limits
    the run to those tell ids; procedure=True holds numbered steps to the procedure cap."""
    if surface is None:
        return _legacy_report(text)
    profiles = load_profiles()
    if surface not in profiles.get("surfaces", {}):
        raise ValueError(f"unknown surface {surface!r}; expected one of {sorted(profiles.get('surfaces', {}))}")
    return _surface_report(text, surface, profiles, set(only) if only else None, procedure)


def _legacy_report(text):
    """The original scorer: every rule on, the 25-word cap, no surface."""
    pv = strip_view(text)
    prose = pv.text
    if len(META_ID.findall(prose)) >= 2:
        return {"skipped": "style-system meta-traffic (rule-ID density)", "score": 0.0}
    inst, sp, words = _detect(prose, 25, None)
    spans = _legacy_spans(prose, inst, sp)
    return {"score": _score(inst, words, lambda key: True), "words": words,
            "violations": {k: len(v) for k, v in inst.items() if v},
            "spans": {k: s for k, s in spans.items() if s}}


class _Finder:
    """Collects findings for one surface and maps spans back to the caller's text."""

    def __init__(self, text, surface, profiles, only):
        self.text, self.surface, self.profiles, self.only = text, surface, profiles, only
        self.out = []
        self._starts = None

    def action(self, tell):
        return action_for(tell, self.surface, self.profiles)

    def want(self, tell):
        return self.action(tell) != "off" and (self.only is None or tell in self.only)

    def _line(self, pos):
        if self._starts is None:
            self._starts = [0] + [m.end() for m in re.finditer(r"\n", self.text)]
        return bisect.bisect_right(self._starts, pos)

    def add(self, tell, span, snippet=None, context=None, text=None):
        """span is (start, end) in the caller's text, or None."""
        a = self.text[span[0]:span[1]] if span else ""
        self.out.append({"tell": tell, "action": self.action(tell),
                         "span": list(span) if span else None,
                         "line": self._line(span[0]) if span else None,
                         "text": (text if text is not None else a)[:120],
                         "snippet": snippet if snippet is not None else a[:120],
                         "context": (context if context is not None else a)[:200]})

    def add_view(self, tell, view, s, e, snippet=None, context=None):
        self.add(tell, view.span(s, e), snippet, context if context is not None else _line_at(view.text, s),
                 text=view.text[s:e])


def _chat_views(text):
    v0 = TextView(text)
    fenced, flags = False, []
    for line in v0.text.split("\n"):
        if re.match(_WS + r"*```", line):
            fenced = not fenced
            flags.append(True)
        else:
            flags.append(fenced)
    p1 = v0.drop_lines(lambda i, l: flags[i])
    p2 = p1.sub(re.compile(r"`[^`\n]*`"), "").drop_lines(lambda i, l: re.match(_WS + r"*>", l))
    p3 = p2.drop_lines(lambda i, l: re.match(_WS + r"*\|", l))
    return p2, p3


def _lines(view):
    """(offset, line) for every line of the view."""
    pos = 0
    for line in view.text.split("\n"):
        yield pos, line
        pos += len(line) + 1


def _chat(fd):
    p2, p3 = _chat_views(fd.text)
    if fd.want("em-dash"):
        for m in DASH_FOR["chat"].finditer(p2.text):
            fd.add_view("em-dash", p2, m.start(), m.end())
    if fd.want("decoration-emoji"):
        for off, line in _lines(p3):
            m = DECORATION_EMOJI.search(line)
            if m:
                fd.add_view("decoration-emoji", p3, off + m.start(), off + m.end())
    if fd.want("label-fragment"):
        hits = [(off, line, LABEL_CHAT.search(line)) for off, line in _lines(p3)]
        hits = [h for h in hits if h[2]]
        if len(hits) >= 3:
            for off, line, m in hits:
                fd.add_view("label-fragment", p3, off + m.start(), off + m.end())
    if fd.want("bold-spam"):
        hits = [(off, m) for off, line in _lines(p3) for m in BOLD_SPAN.finditer(line)]
        if len(hits) > 5:
            for off, m in hits:
                fd.add_view("bold-spam", p3, off + m.start(), off + m.end())
    first = next(((off, line) for off, line in _lines(p3) if re.search(r"\S", line)), None)
    if first:
        off, line = first
        if PRAISE_OPENER.match(line):
            if fd.want("praise-opener"):
                fd.add_view("praise-opener", p3, off, off + len(line))
        elif fd.want("verdict-opener") and VERDICT_OPENER.match(line):
            fd.add_view("verdict-opener", p3, off, off + len(line))
    if fd.want("contrastive-scaffold"):
        for off, line in _lines(p3):
            for m in CONTRASTIVE_NOT_BUT.finditer(line):
                fd.add_view("contrastive-scaffold", p3, off + m.start(), off + m.end())
    if fd.want("star-decoration"):
        for off, line in _lines(p3):
            i = line.find(STAR)
            if i >= 0:
                fd.add_view("star-decoration", p3, off + i, off + i + 1)
    if fd.want("option-menu-closer"):
        tail = [(off, line) for off, line in _lines(p3) if re.search(r"\S", line)][-3:]
        for off, line in tail:
            m = OPTION_MENU.search(line)
            if m:
                fd.add_view("option-menu-closer", p3, off + m.start(), off + m.end())
                break


def _md_view(text, tables):
    """Deck and Word text: front matter, fences, comments and (Word) tables dropped,
    code spans removed."""
    lines = text.split("\n")
    front = bool(lines) and lines[0].strip() == "---"
    state = {"fence": False, "front": front}

    def drop(i, line):
        if state["front"]:
            if i > 0 and line.strip() == "---":
                state["front"] = False
            return True
        if line.startswith("```") or line.startswith("~~~"):
            state["fence"] = not state["fence"]
            return True
        s = line.strip()
        return state["fence"] or s.startswith("<!--") or s == "\\newpage" or (tables and s.startswith("|"))
    return TextView(text).drop_lines(drop).sub(re.compile(r"`[^`]*`"), "")


def _word_label_runs(view):
    run = []
    for off, line in _lines(view):
        s = line.strip()
        is_row = (s and not s.startswith("|") and not re.match(r"^#{1,6}\s", s) and not s.startswith(">")
                  and LABEL_WORD.match(s))
        if is_row:
            run.append((off, line))
            continue
        if len(run) >= 3:
            yield run
        run = []
    if len(run) >= 3:
        yield run


def _prose_family(fd, surface, procedure):
    """Tells that read stripped prose: doc, commit, ui_string, plus sentence length
    and the em-dash for deck and Word."""
    prof = fd.profiles
    if surface in ("doc", "commit"):
        pv = strip_view(fd.text)
    elif surface in ("deck", "word"):
        pv = _md_view(fd.text, tables=(surface == "word"))
    else:
        pv = TextView(fd.text)
    prose = pv.text
    if surface in ("doc", "commit") and fd.only is None and len(META_ID.findall(prose)) >= 2:
        return None
    cap = sentence_cap(surface, prof) or 25
    proc = sentence_cap(surface, prof, True) if procedure else None
    inst, sp, words = _detect(prose, cap, proc)
    if surface in ("doc", "commit", "ui_string"):
        if fd.want("em-dash"):
            for a, b in inst["two_split_dash"]:
                fd.add_view("em-dash", pv, a, b, snippet=_dash_window(prose, a, b))
    elif fd.want("em-dash"):
        for m in DASH_FOR[surface].finditer(prose):
            fd.add_view("em-dash", pv, m.start(), m.end(), snippet=prose[max(0, m.start() - 40):m.end() + 40].strip())
    if surface in ("doc", "commit"):
        if fd.want("verdict-opener") and inst["verdict_first_opener"]:
            a, b = inst["verdict_first_opener"][0]
            fd.add_view("verdict-opener", pv, a, b, snippet=prose[a:b][:100])
        if fd.want("contrastive-scaffold"):
            for a, b in inst["contrastive_scaffold"]:
                fd.add_view("contrastive-scaffold", pv, a, b, snippet=prose[max(0, a - 20):b + 30].strip())
        if fd.want("contrast-list"):
            for a, b in inst["contrast_list"]:
                fd.add_view("contrast-list", pv, a, b, snippet=prose[max(0, a - 20):b + 30].strip())
        for key, tell in (("filler_hedge", "filler-hedge"), ("hedged_assertion", "hedged-assertion"),
                          ("passive", "passive"), ("nominalization", "nominalization"),
                          ("semicolon", "semicolon"), ("split_phrase", "two-split")):
            if fd.want(tell):
                for a, b in inst[key]:
                    fd.add_view(tell, pv, a, b, snippet=prose[max(0, a - 30):b + 30].strip())
    if surface in ("doc", "commit", "ui_string"):
        for key, tell in (("jargon_marketing", "jargon-marketing"), ("unverified_claim", "unverified-claim")):
            if fd.want(tell):
                for a, b in inst[key]:
                    fd.add_view(tell, pv, a, b, snippet=prose[max(0, a - 30):b + 30].strip())
    if fd.want("sentence-length"):
        for key in ("fused_25_35", "fused_35_50", "fused_over_50"):
            for a, b in inst[key]:
                fd.add_view("sentence-length", pv, a, b, snippet=prose[a:b][:100])
    if surface == "word" and fd.want("label-fragment"):
        for run in _word_label_runs(pv):
            off0, last = run[0][0], run[-1]
            fd.add_view("label-fragment", pv, off0, last[0] + len(last[1]))
    return inst, words, pv


def _readability(fd, surface):
    """Dense blocks, spliced lines and internals-only runs. A block is judged on the
    text the reader sees (front matter and HTML comments removed)."""
    if not any(fd.want(t) for t in ("dense-block", "spliced-line", "mechanism-run")) and not (
            surface == "github" and fd.want("em-dash")):
        return
    rc = core()
    cv = TextView(fd.text).sub(rc.FRONT, "", count=1).sub(rc.HTML_COMMENT, "")
    starts, pos = [], 0
    for ln in cv.text.splitlines(keepends=True):
        starts.append((pos, pos + len(ln.rstrip("\r\n"))))
        pos += len(ln)

    def at(block):
        a = starts[block.line - 1][0]
        b = starts[max(block.end, block.line) - 1][1]
        return a, b

    if fd.want("dense-block"):
        for b, snip in rc.dense_findings(cv.text, clean_first=False):
            fd.add_view("dense-block", cv, *at(b), snippet=snip)
    dash_here = surface == "github" and fd.want("em-dash")
    if dash_here or fd.want("spliced-line"):
        for kind, snip, b in rc.spliced_findings(cv.text, dashes=dash_here, semicolons=True,
                                                 dash_re=dash_rule(surface), clean_first=False):
            if kind == "dash":
                fd.add_view("em-dash", cv, *at(b), snippet=snip)
            elif fd.want("spliced-line"):
                fd.add_view("spliced-line", cv, *at(b), snippet=snip)
    if fd.want("mechanism-run"):
        for b, snip in rc.mechanism_findings(cv.text, clean_first=False):
            fd.add_view("mechanism-run", cv, *at(b), snippet=snip)


def _surface_report(text, surface, profiles, only, procedure):
    fd = _Finder(text, surface, profiles, only)
    rep = {"surface": surface, "score": 0.0, "words": 0, "violations": {}, "spans": {}, "findings": fd.out}
    if surface == "chat":
        _chat(fd)
    elif surface == "comment":
        if fd.want("em-dash"):
            for m in DASH_FOR["comment"].finditer(text):
                fd.add("em-dash", m.span(), snippet=text[max(0, m.start() - 40):m.end() + 40].strip(), context=_line_at(text, m.start()))
        if fd.want("decoration-emoji"):
            for m in COMMENT_EMOJI.finditer(text):
                fd.add("decoration-emoji", m.span(), context=_line_at(text, m.start()))
    elif surface in ("doc", "commit", "ui_string", "deck", "word"):
        score_wanted = fd.want("lint-score-block")
        prose_tells = ("em-dash", "verdict-opener", "contrastive-scaffold", "contrast-list", "sentence-length",
                       "jargon-marketing", "unverified-claim", "filler-hedge", "hedged-assertion", "passive",
                       "nominalization", "semicolon", "two-split", "label-fragment")
        if score_wanted or any(fd.want(t) for t in prose_tells):
            got = _prose_family(fd, surface, procedure)
            if got is None:
                return {"surface": surface, "skipped": "style-system meta-traffic (rule-ID density)",
                        "score": 0.0, "findings": []}
            inst, words, pv = got
            counts = lambda key: action_for(KEY_TELL[key], surface, profiles) in SCORING_ACTIONS
            rep.update({"score": _score(inst, words, counts), "words": words,
                        "violations": {k: len(v) for k, v in inst.items() if v},
                        "spans": {k: s for k, s in _legacy_spans(pv.text, inst, None).items() if s}})
            if score_wanted:
                limit = (profiles.get("caps") or {}).get("lint_score_block", 8)
                if rep["score"] > limit:
                    fd.add("lint-score-block", None, snippet=f"score {rep['score']}/100w (block line {limit})", text=str(limit))
        if surface in ("doc",):
            _readability(fd, surface)
    elif surface == "github":
        _readability(fd, surface)
    return rep


def main(argv):
    as_json = "--json" in argv
    profile, only, files, i = None, None, [], 0
    while i < len(argv):
        a = argv[i]
        if a == "--profile" and i + 1 < len(argv):
            profile = argv[i + 1]; i += 2; continue
        if a.startswith("--profile="):
            profile = a.split("=", 1)[1]; i += 1; continue
        if a == "--only" and i + 1 < len(argv):
            only = [t for t in argv[i + 1].split(",") if t]; i += 2; continue
        if a not in ("--json", "-"):
            files.append(a)
        i += 1

    def run(text):
        if profile:
            try:
                return lint(text, profile, only=only)
            except Exception as e:      # a linter reports; it never takes the caller down
                return {"surface": profile, "error": str(e), "score": 0.0, "findings": []}
        return lint(text)

    if not files:
        r = run(sys.stdin.read())
        if profile or as_json:
            print(json.dumps(r, indent=2))
        else:
            print(f"stdin  score={r['score']}  " + " ".join(f"{k}={n}" for k, n in r.get("violations", {}).items()))
        return 0
    for f in files:
        if not os.path.exists(f):
            print(f"{f}: not found: check the path, or pipe content via stdin (cmd | prose-lint.py)")
            continue
        r = run(open(f, errors="replace").read())
        if profile or as_json:
            print(json.dumps({"file": f, **r}, indent=2))
        elif "skipped" in r:
            print(f"{os.path.basename(f):32} skipped ({r['skipped']})")
        else:
            top = sorted(r["violations"].items(), key=lambda kv: -WEIGHTS[kv[0]] * kv[1])[:3]
            named = [f"{k} x{r['violations'][k]}" for k in ("split_phrase", "contrast_list") if k in r["violations"]]
            print(f"{os.path.basename(f):32} score={r['score']:6.2f} words={r['words']:5d}  worst: " +
                  (", ".join(f"{k} x{n}" for k, n in top) or "clean") +
                  ("  tells: " + ", ".join(named) if named else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
