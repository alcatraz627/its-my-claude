#!/usr/bin/env python3
"""Tests for the prose engine (scripts/style/prose-lint.py): the profile API every
prose gate asks, with its tells ported from format-gate-stop.sh.

What is pinned here:
  1. every (tell, surface) the profile does not switch off finds a positive case
     and passes a negative one, and the case table covers the whole profile;
  2. the action on a finding is read from style/profiles.json (mutated copy via
     PROSE_PROFILES), as are the sentence caps and the score block line;
  3. the Python form of each chat regex agrees with the ripgrep form it replaced,
     probe line by probe line (skipped when rg is missing);
  4. spans point at the original text, and the old entry points still work.

Run:  python3 ~/.claude/scripts/hooks/tests/prose-engine.test.py
Mutation check: PROSE_LINT_PATH points at a copy of the engine with one tell weakened.
"""
import importlib.util, json, os, shutil, subprocess, sys, tempfile, unittest

ROOT = os.path.expanduser("~/.claude")
ENGINE = os.environ.get("PROSE_LINT_PATH") or os.path.join(ROOT, "scripts", "style", "prose-lint.py")
PROFILES = os.path.join(ROOT, "style", "profiles.json")
spec = importlib.util.spec_from_file_location("prose_engine_under_test", ENGINE)
pl = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pl)

D = chr(0x2014)      # the em dash, built from its code point so no source line carries one
EN = chr(0x2013)


def words(n, w="word"):
    return " ".join([w] * n)


def sentence(n):
    """One sentence of exactly n words."""
    return "The " + words(n - 1) + "."


def findings(text, surface, tell=None, **kw):
    r = pl.lint(text, surface, **kw)
    return [f for f in r["findings"] if tell is None or f["tell"] == tell]


# The case table: (tell, surface) -> (positive text, negative text).
LABELS3 = "**Status**: ok\n**Owner**: me\n**Next**: ship\n"
LABELS2 = "**Status**: ok\n**Owner**: me\n"
BOLD6 = " ".join(f"**b{i}x**" for i in range(6))
BOLD5 = " ".join(f"**b{i}x**" for i in range(5))
DENSE = " ".join(f"Sentence number {i} says something plain about the loader and its table." for i in range(6))
SPLICE = "The loader reads the config file and builds the table once; the table then feeds every later stage of it."
MECH = ("The `fetchUser()` call hits `src/api/user.ts` after 200ms. The `cache_key` goes to `lib/store.ts` at 50ms. "
        "The `retryCount` header reaches `src/net/http.ts` within 30ms.")
SCORE_HIGH = " ".join(sentence(60) for _ in range(3))

CASES = {
    ("em-dash", "chat"): (f"This works {D} mostly.", f"This works, mostly. `a {D} b` stays in code."),
    ("em-dash", "doc"): (f"The loader reads it{D}then stops.", f"The loader reads it, then stops. Pages 2024{EN}2026 stay."),
    ("em-dash", "commit"): (f"The loader reads it {D} then stops.", "The loader reads it, then stops."),
    ("em-dash", "github"): (f"It reads the file {D} then stops.", "It reads the file, then stops."),
    ("em-dash", "deck"): (f"# Title\n\nA claim {D} here.", "# Title\n\nA claim, here."),
    ("em-dash", "word"): (f"# Title\n\nA claim{D}here.", "# Title\n\nA claim, here."),
    ("em-dash", "comment"): (f"// builds the table {D} once", "// builds the table once"),
    ("em-dash", "ui_string"): (f"Saved {D} your changes are safe", "Saved, your changes are safe"),
    ("verdict-opener", "chat"): ("Done. The thing works.\n\nMore text follows here.", "The thing works. Done later."),
    ("verdict-opener", "doc"): ("Done. The loader now reads the file.", "The loader reads the file. Done."),
    ("verdict-opener", "commit"): ("Everything works. The loader reads the file.", "The loader reads the file."),
    ("praise-opener", "chat"): ("You're absolutely right, that is a bug.", "The bug is real, and you spotted it."),
    ("label-fragment", "chat"): (LABELS3, LABELS2),
    ("label-fragment", "word"): ("- **Status:** fine here\n- **Owner:** them now\n- **Next:** ship it\n",
                                 "- **Status:** fine here\n- **Owner:** them now\n"),
    ("bold-spam", "chat"): (BOLD6, BOLD5),
    ("decoration-emoji", "chat"): ("\U0001F680 Launch notes\nmore text", "Launch \U0001F680 notes mid-line"),
    ("decoration-emoji", "comment"): ("// shipped \U0001F680", "// shipped"),
    ("contrastive-scaffold", "chat"): ("This is not a cache problem, but a race in the loader.", "This is a cache problem."),
    ("contrastive-scaffold", "doc"): ("This is not a cache problem, but a race in the loader.", "This is a cache problem."),
    ("contrastive-scaffold", "commit"): ("This is not a cache problem, but a race in the loader.", "This is a cache problem."),
    ("contrast-list", "doc"): ("The fix is not a rule, not a reminder, but a hook that runs at commit time.",
                               "The hook runs at commit time, not at write time."),
    ("contrast-list", "commit"): ("The fix is not a rule, not a reminder, but a hook that runs at commit time.",
                                  "The hook runs at commit time, not at write time."),
    ("sentence-length", "doc"): (sentence(26), sentence(25)),
    ("sentence-length", "commit"): (sentence(26), sentence(25)),
    ("sentence-length", "deck"): (sentence(26), sentence(25)),
    ("sentence-length", "word"): (sentence(31), sentence(30)),
    ("lint-score-block", "doc"): (SCORE_HIGH, "The loader reads the config file. It builds the table once."),
    ("lint-score-block", "commit"): (SCORE_HIGH, "The loader reads the config file. It builds the table once."),
    ("jargon-marketing", "doc"): ("We leverage the data in the table.", "We read the data in the table."),
    ("jargon-marketing", "commit"): ("We leverage the data in the table.", "We read the data in the table."),
    ("jargon-marketing", "ui_string"): ("A seamless way to save", "A quick way to save"),
    ("unverified-claim", "doc"): ("This should now work for the loader.", "This works for the loader, tested today."),
    ("unverified-claim", "commit"): ("This should now work for the loader.", "This works for the loader, tested today."),
    ("unverified-claim", "ui_string"): ("This should now work for you", "This works for you"),
    ("dense-block", "doc"): (DENSE, "A short plain paragraph."),
    ("dense-block", "github"): (DENSE, "A short plain paragraph."),
    ("spliced-line", "doc"): (SPLICE, "The loader reads the config file. It builds the table once."),
    ("spliced-line", "github"): (SPLICE, "The loader reads the config file. It builds the table once."),
    # tells the profile file does not list: the engine's own defaults
    ("star-decoration", "chat"): ("★ Insight\nmore text", "No stars here."),
    ("option-menu-closer", "chat"): ("Shipped it.\n\nWould you like me to ship it or wait?", "Shipped it.\n\nSay when to start."),
    ("mechanism-run", "doc"): (MECH, "The loader reads the config file. It builds the table once."),
    ("mechanism-run", "github"): (MECH, "The loader reads the config file. It builds the table once."),
}


class Matrix(unittest.TestCase):
    def test_every_live_pair_has_a_case(self):
        profiles = pl.load_profiles()
        live = set()
        for tell, row in profiles["tells"].items():
            for surface, action in row.items():
                if surface in profiles["surfaces"] and action != "off":
                    live.add((tell, surface))
        for tell, row in pl.DEFAULT_ACTIONS.items():
            if tell not in profiles["tells"]:
                for surface, action in row.items():
                    if action != "off":
                        live.add((tell, surface))
        scoring_only = {"filler-hedge", "hedged-assertion", "passive", "nominalization", "semicolon", "two-split"}
        missing = sorted(p for p in live if p not in CASES and p[0] not in scoring_only)
        self.assertEqual(missing, [], "profile rows with no test case")

    def test_each_case_fires_and_stays_quiet(self):
        profiles = pl.load_profiles()
        for (tell, surface), (pos, neg) in CASES.items():
            want = pl.action_for(tell, surface, profiles)
            self.assertNotEqual(want, "off", f"{tell}/{surface} is off in the profile; drop the case")
            with self.subTest(tell=tell, surface=surface):
                hit = findings(pos, surface, tell)
                self.assertTrue(hit, f"{tell} on {surface}: positive case found nothing")
                self.assertEqual({f["action"] for f in hit}, {want})
                self.assertEqual(findings(neg, surface, tell), [], f"{tell} on {surface}: negative case fired")

    def test_off_surfaces_stay_off(self):
        # a verdict opener advises in chat and is not checked on GitHub text
        self.assertEqual(findings("Done. The thing works.", "github", "verdict-opener"), [])
        self.assertEqual(findings(sentence(40), "chat", "sentence-length"), [])
        self.assertEqual(findings(LABELS3, "doc", "label-fragment"), [])


# Actions, caps and thresholds come from the profile file.
class ProfileIsRead(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.path = os.path.join(self.tmp, "profiles.json")
        with open(PROFILES) as f:
            self.data = json.load(f)
        self.old = os.environ.get("PROSE_PROFILES")

    def tearDown(self):
        if self.old is None:
            os.environ.pop("PROSE_PROFILES", None)
        else:
            os.environ["PROSE_PROFILES"] = self.old
        shutil.rmtree(self.tmp, ignore_errors=True)

    def use(self, mutate):
        mutate(self.data)
        with open(self.path, "w") as f:
            json.dump(self.data, f)
        os.environ["PROSE_PROFILES"] = self.path

    def test_action_changes_with_the_file(self):
        text = f"This works {D} mostly."
        self.assertEqual(findings(text, "chat", "em-dash")[0]["action"], "block")
        self.use(lambda d: d["tells"]["em-dash"].update(chat="warn"))
        self.assertEqual(findings(text, "chat", "em-dash")[0]["action"], "warn")
        self.use(lambda d: d["tells"]["em-dash"].update(chat="off"))
        self.assertEqual(findings(text, "chat", "em-dash"), [])

    def test_verdict_opener_weight_per_surface_is_the_file(self):
        text = "Done. The loader now reads the file."
        self.assertEqual(findings(text, "doc", "verdict-opener")[0]["action"], "block")
        self.use(lambda d: d["tells"]["verdict-opener"].update(doc="warn"))
        self.assertEqual(findings(text, "doc", "verdict-opener")[0]["action"], "warn")

    def test_sentence_cap_comes_from_the_file(self):
        self.assertTrue(findings(sentence(26), "doc", "sentence-length"))
        self.use(lambda d: d["caps"]["sentence_words"].update(doc=40))
        self.assertEqual(findings(sentence(26), "doc", "sentence-length"), [])
        self.assertTrue(findings(sentence(41), "doc", "sentence-length"))

    def test_word_cap_comes_from_the_file(self):
        self.assertEqual(findings(sentence(28), "word", "sentence-length"), [])
        self.use(lambda d: d["caps"]["sentence_words"].update(word=20))
        self.assertTrue(findings(sentence(28), "word", "sentence-length"))

    def test_score_block_line_comes_from_the_file(self):
        text = SCORE_HIGH
        self.assertTrue(findings(text, "doc", "lint-score-block"))
        self.use(lambda d: d["caps"].update(lint_score_block=500))
        self.assertEqual(findings(text, "doc", "lint-score-block"), [])

    def test_a_score_action_counts_toward_the_score_only_when_the_file_says_so(self):
        text = "We leverage the data. We leverage the data again. We leverage the data once more here today."
        before = pl.lint(text, "doc")["score"]
        self.assertGreater(before, 0)
        self.use(lambda d: d["tells"]["jargon-marketing"].update(doc="off"))
        self.assertLess(pl.lint(text, "doc")["score"], before)

    def test_cli_reads_the_override_too(self):
        self.use(lambda d: d["tells"]["em-dash"].update(chat="warn"))
        r = subprocess.run([sys.executable, ENGINE, "--profile", "chat", "-"], input=f"A {D} b.", text=True,
                           capture_output=True, env={**os.environ, "PROSE_PROFILES": self.path})
        out = json.loads(r.stdout)
        self.assertEqual(out["findings"][0]["action"], "warn")

    def test_a_missing_override_is_an_error_not_a_silent_default(self):
        os.environ["PROSE_PROFILES"] = os.path.join(self.tmp, "nope.json")
        with self.assertRaises(OSError):
            pl.lint("Plain text.", "chat")

    def test_built_in_fallback_equals_the_shipped_file(self):
        fallback = json.loads(pl._FALLBACK_JSON)
        for key in ("actions", "surfaces", "caps", "tells"):
            self.assertEqual(fallback[key], self.data[key], f"embedded {key} drifted from style/profiles.json")


# The Python form of each chat regex agrees with the ripgrep form it replaced.
RG = shutil.which("rg")
# Copied from the bash that format-gate-stop.sh used to run (effective regexes, after bash unquoting).
OLD_EMOJI = ("^[[:space:]]*(#{1,6}[[:space:]]*)?(\U0001F534|\U0001F7E1|\U0001F7E2|\U0001F7E0|\U0001F6A6|\U0001F3AF|"
             "\U0001F680|\U0001F525|\U0001F4A1|\U0001F4CA|\U0001F9E0|✨|\U0001F6D1|\U0001F4CC|⚡|❗|"
             "✅|⚠️|❌)")
OLD_LABEL = "^[[:space:]]*[-*•]?[[:space:]]*\\*\\*[^*]{2,40}\\*\\*[[:space:]]*:"
OLD_BOLD = "\\*\\*[^*]+\\*\\*"
OLD_PRAISE = "^(you'?re (absolutely |completely |exactly )?right|great (question|point|idea|catch)|excellent|perfect[.!]|fair question|what a )"
OLD_VERDICT = ("^\\W*(\\*\\*)?((Done|Perfect|Excellent|Awesome|Fantastic|Beautiful|Completed|Shipped)\\s*[.!:\\x{2014}]"
               "|All (done|set|good)\\b|Everything (is|works)\\b|Release is live\\b)")
OLD_CONTRA = "\\bnot\\s+[^.;,]{2,40},?\\s+but\\s+"
OLD_STAR = "★"
OLD_CLOSER = "(would you like me to|do you want me to|shall i|want me to) .+ or .+\\?"


def rg(args, text):
    r = subprocess.run([RG, *args], input=text.encode(), capture_output=True)
    return r.stdout.decode().strip()


def rg_count(pattern, text, flags=()):
    out = rg(["-c", *flags, "--", pattern], text)
    return int(out) if out else 0


def rg_matches(pattern, text, flags=()):
    out = rg(["-co", *flags, "--", pattern], text)
    return int(out) if out else 0


def tell_n(text, tell):
    return len(findings(text, "chat", tell))


@unittest.skipUnless(RG, "ripgrep not installed")
class ChatMatchesRipgrep(unittest.TestCase):
    def check(self, probes, tell, old_count):
        for text in probes:
            with self.subTest(tell=tell, probe=text):
                self.assertEqual(tell_n(text, tell), old_count(text))

    def test_decoration_emoji(self):
        probes = ["\U0001F680 x", "## \U0001F3AF Goal", "x \U0001F680", "⚠️ warn", "⚠ bare warn",
                  "✅ done", "  ✅ indented", "\t❌ tab", "plain line", "#✨ no space", "####### \U0001F525 seven"]
        self.check(probes, "decoration-emoji", lambda t: rg_count(OLD_EMOJI, t))

    def test_label_fragment(self):
        rows = ["**Status**: ok", "- **Owner**: me", "* **Next**: ship", "• **Why**: because", "**A**: too short",
                "**Sixty chars " + "x" * 30 + "**: long", "**Status:** colon inside", "plain **bold** text: no"]
        probes = ["\n".join(rows[:3]), "\n".join(rows[:2] + [rows[4]]), "\n".join(rows), "\n".join(rows[3:4] * 3),
                  "\n".join(["  " + r for r in rows[:3]]), "\n".join(rows[:2])]

        def old(t):
            n = rg_count(OLD_LABEL, t)
            return n if n >= 3 else 0
        self.check(probes, "label-fragment", old)

    def test_bold_spam(self):
        probes = [BOLD6, BOLD5, "**a** **b**\n**c** **d** **e** **f** **g**", "**a\nb** **c** **d** **e** **f** **g**",
                  "**one** **two**", "**x*y** " * 7]

        def old(t):
            n = rg_matches(OLD_BOLD, t)
            return n if n > 5 else 0
        self.check(probes, "bold-spam", old)

    def praise_verdict(self, text):
        first = next((ln for ln in text.split("\n") if ln.strip()), "")
        praise = rg_count(OLD_PRAISE, first, ["-i"]) > 0
        verdict = (not praise) and rg_count(OLD_VERDICT, first, ["-i", "-P"]) > 0
        return praise, verdict

    def test_praise_and_verdict_openers(self):
        probes = ["You're absolutely right", "YOU'RE RIGHT", "  you're right", "Great question!", "great catch", "Excellent work",
                  "Perfect!", "Perfect", "What a day", "what a", "Done.", "**Done.**", "\"Done.\"", "Done", "Done!", "done:",
                  "All set", "all good here", "Everything works", "Everything is fine", "Release is live today",
                  "Shipped:", "Done" + D, "Completed.", "\n\nDone. after blank lines", "Fair question", "Awesome. Next",
                  "Not done.", "(Done.)", "The work is Done."]
        for text in probes:
            praise, verdict = self.praise_verdict(text)
            with self.subTest(probe=text):
                self.assertEqual(tell_n(text, "praise-opener") > 0, praise)
                self.assertEqual(tell_n(text, "verdict-opener") > 0, verdict)

    def test_contrastive_scaffold(self):
        probes = ["This is not a cache problem, but a race.", "not abc, but b and not cde but d", "NOT abc BUT d",
                  "not a, but b", "not one thing. but another", "not abc,\nbut next line", "it is not abc; but d",
                  "not " + "x" * 41 + " but y", "not " + "x" * 40 + " but y", "cannot abc but d"]
        self.check(probes, "contrastive-scaffold", lambda t: rg_matches(OLD_CONTRA, t, ["-i", "-P"]))

    def test_star_decoration(self):
        probes = ["★ Insight", "x ★ y\n★", "no star", "★★ two on a line"]
        self.check(probes, "star-decoration", lambda t: rg_count(OLD_STAR, t))

    def test_option_menu_closer(self):
        probes = ["Done.\n\nWould you like me to ship it or wait?", "Shall I run it or skip it?", "want me to do x or y?",
                  "Do you want me to stop?", "Would you like me to ship it or wait", "WOULD YOU LIKE ME TO a or b?",
                  "Would you like me to ship it or wait?\n\n\n\nl2\nl3\nl4", "Would you like me to ship it or wait?\nl2\nl3\nl4",
                  "Would you like me to ship it or wait?\nl2\nl3"]

        def old(t):
            tail = [ln for ln in t.split("\n") if ln.strip()][-3:]
            return 1 if rg_count(OLD_CLOSER, "\n".join(tail), ["-i"]) else 0
        for text in probes:
            with self.subTest(probe=text):
                self.assertEqual(1 if tell_n(text, "option-menu-closer") else 0, old(text))


# Views, spans and the old entry points.
class ChatViews(unittest.TestCase):
    def test_code_quotes_and_fences_are_not_prose(self):
        text = f"Plain.\n```\nin a fence {D} here\n```\n> quoted {D} line\n`code {D}` end\n"
        self.assertEqual(findings(text, "chat", "em-dash"), [])

    def test_table_rows_still_count_for_the_dash_but_not_for_smell(self):
        text = f"| a | b {D} c |\n"
        self.assertEqual(len(findings(text, "chat", "em-dash")), 1)
        self.assertEqual(findings("| **A**: x |\n| **B**: y |\n| **C**: z |\n", "chat", "label-fragment"), [])

    def test_spans_point_at_the_original_text(self):
        text = f"```\nfence\n```\nSee `code` and more {D} here. Then {D} again.\n"
        hits = findings(text, "chat", "em-dash")
        self.assertEqual(len(hits), 2)
        for f in hits:
            a, b = f["span"]
            self.assertEqual(text[a:b], D)
        self.assertEqual(hits[0]["line"], 4)

    def test_doc_spans_survive_stripping(self):
        text = f"```\nx\n```\n\n> quote\n\nUse `a b` for it{D}now.\n"
        a, b = findings(text, "doc", "em-dash")[0]["span"]
        self.assertEqual(text[a:b], D)

    def test_github_dash_finding_marks_its_block(self):
        text = f"First paragraph is plain.\n\nSecond has a dash {D} in it.\n"
        f = findings(text, "github", "em-dash")[0]
        self.assertEqual(text[f["span"][0]:f["span"][1]], f"Second has a dash {D} in it.")

    def test_github_block_with_a_dash_and_a_semicolon_counts_once_but_a_doc_counts_both(self):
        text = f"The loader reads the config file {D} and builds the table once; the table then feeds every later stage of it."
        self.assertEqual([f["tell"] for f in pl.lint(text, "github")["findings"]], ["em-dash"])
        self.assertEqual(len(findings(text, "doc", "spliced-line")), 1)
        self.assertEqual(len(findings(text, "doc", "em-dash")), 1)

    def test_github_dash_inside_code_span_is_not_a_dash(self):
        self.assertEqual(findings(f"Run `a {D} b` now.", "github", "em-dash"), [])

    def test_en_dash_is_a_connective_only_where_the_old_rule_said_so(self):
        self.assertEqual(findings(f"Pages 10{EN}20 are fine.", "doc", "em-dash"), [])
        self.assertTrue(findings(f"files{EN}then writes", "doc", "em-dash"))
        self.assertTrue(findings(f"a {EN} b", "doc", "em-dash"))
        self.assertEqual(findings(f"a {EN} b", "chat", "em-dash"), [])
        self.assertTrue(findings(f"a {EN} b", "github", "em-dash"))
        self.assertEqual(findings(f"Pages 10{EN}20 fine.", "github", "em-dash"), [])


class OldEntryPoints(unittest.TestCase):
    def test_lint_without_a_surface_is_the_original_report(self):
        r = pl.lint(f"We leverage the data {D} fine.")
        self.assertEqual(set(r), {"score", "words", "violations", "spans"})
        self.assertEqual(r["violations"]["two_split_dash"], 1)
        self.assertEqual(r["violations"]["jargon_marketing"], 1)

    def test_meta_traffic_is_skipped(self):
        r = pl.lint("See mist-20260101 and thes-20260102 for the verdicts.")
        self.assertIn("skipped", r)
        self.assertEqual(pl.lint("See mist-20260101 and thes-20260102 for it.", "doc")["findings"], [])

    def test_cli_json_shape_is_unchanged(self):
        r = subprocess.run([sys.executable, ENGINE, "--json", "-"], input="A plain sentence here.", text=True, capture_output=True)
        out = json.loads(r.stdout)
        self.assertEqual(r.returncode, 0)
        self.assertNotIn("findings", out)

    def test_cli_profile_prints_findings_and_exits_zero(self):
        r = subprocess.run([sys.executable, ENGINE, "--profile", "doc", "-"], input=f"A {D} b.", text=True, capture_output=True)
        out = json.loads(r.stdout)
        self.assertEqual(r.returncode, 0)
        self.assertEqual([f["tell"] for f in out["findings"]][:1], ["em-dash"])

    def test_cli_only_limits_the_tells(self):
        text = f"Done. A {D} b."
        r = subprocess.run([sys.executable, ENGINE, "--profile", "doc", "--only", "verdict-opener", "-"], input=text,
                           text=True, capture_output=True)
        self.assertEqual({f["tell"] for f in json.loads(r.stdout)["findings"]}, {"verdict-opener"})

    def test_unknown_surface_is_an_error(self):
        with self.assertRaises(ValueError):
            pl.lint("text", "nope")

    def test_prose_readability_still_imports_and_agrees(self):
        hooks = os.path.join(ROOT, "scripts", "hooks")
        spec2 = importlib.util.spec_from_file_location("pr_reexport", os.path.join(hooks, "prose_readability.py"))
        pr = importlib.util.module_from_spec(spec2)
        spec2.loader.exec_module(pr)
        for name in ("analyze", "blocks", "plain", "sentences", "dense_blocks", "spliced_lines", "mechanism_runs",
                     "is_dense", "is_mechanism", "DASH", "Block"):
            self.assertTrue(hasattr(pr, name), name)
        self.assertEqual(set(pr.analyze(DENSE)), {"dense"})
        self.assertEqual(pr.analyze(f"A plain line {D} with a dash."), {"spliced": ["dash: A plain line " + D + " with a dash."]})
        self.assertEqual(pr.analyze(f"A plain line {D} with a dash.", dashes=False), {})

    def test_every_gate_asks_the_engine(self):
        for name in ("guard-prose-quality.sh", "git-prose-gate.py", "guard-gh-prose.py", "doc-voice-gate.py", "format-gate-stop.sh"):
            with open(os.path.join(ROOT, "scripts", "hooks", name)) as f:
                src = f.read()
            self.assertIn("prose-lint.py", src, f"{name} no longer asks the engine")


class GatesReadTheProfile(unittest.TestCase):
    """Each migrated gate follows the profile file: with its tell turned down to a
    warning in a copy of the file, the gate that blocked now lets the text through."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        with open(PROFILES) as f:
            self.data = json.load(f)
        self.hooks = os.path.join(ROOT, "scripts", "hooks")

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def profile(self, mutate):
        mutate(self.data)
        path = os.path.join(self.tmp, "profiles.json")
        with open(path, "w") as f:
            json.dump(self.data, f)
        return {**os.environ, "PROSE_PROFILES": path, "WARN_LOG_STORE": os.path.join(self.tmp, "warn.jsonl")}

    def test_guard_prose_quality(self):
        home = os.path.join(self.tmp, "home")
        os.makedirs(os.path.join(home, ".claude"))
        os.symlink(os.path.join(ROOT, "scripts"), os.path.join(home, ".claude", "scripts"))
        payload = json.dumps({"tool_name": "Write", "session_id": "pe-gpq",
                              "tool_input": {"file_path": os.path.join(self.tmp, "guide.md"),
                                             "content": f"The cache keeps reads in memory {D} it saves a trip to disk."}})

        def run(env):
            r = subprocess.run(["bash", os.path.join(self.hooks, "guard-prose-quality.sh")], input=payload, text=True,
                               capture_output=True, env={**env, "HOME": home})
            return "block" in r.stdout
        base = {**os.environ, "WARN_LOG_STORE": os.path.join(self.tmp, "warn.jsonl")}
        self.assertTrue(run(base))
        self.assertFalse(run(self.profile(lambda d: d["tells"]["em-dash"].update(doc="warn"))))

    def test_git_prose_gate(self):
        repo = os.path.join(self.tmp, "r")
        os.makedirs(os.path.join(repo, "rules"))
        env0 = {**os.environ, "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null"}
        env0.pop("PROSE_GATE_BYPASS", None)
        subprocess.run(["git", "init", "-q"], cwd=repo, env=env0)
        with open(os.path.join(repo, "rules", "n.md"), "w") as f:
            f.write(f"The loader reads the config file {D} it builds the table once.\n")
        subprocess.run(["git", "add", "-A"], cwd=repo, env=env0)
        gate = os.path.join(self.hooks, "git-prose-gate.py")
        self.assertEqual(subprocess.run([sys.executable, gate], cwd=repo, env=env0, capture_output=True).returncode, 1)
        env = {**self.profile(lambda d: d["tells"]["em-dash"].update(commit="warn")), "GIT_CONFIG_GLOBAL": "/dev/null"}
        env.pop("PROSE_GATE_BYPASS", None)
        self.assertEqual(subprocess.run([sys.executable, gate], cwd=repo, env=env, capture_output=True).returncode, 0)

    def test_guard_gh_prose(self):
        body = " ".join(f"Sentence number {i} says something plain about the loader and its table." for i in range(6))
        payload = json.dumps({"tool_name": "mcp__github__add_issue_comment", "session_id": "pe-gh1", "tool_input": {"body": body}})
        gate = os.path.join(self.hooks, "guard-gh-prose.py")

        def run(env):
            e = {**env, "GH_PROSE_STATE": self.tmp}
            return subprocess.run([sys.executable, gate], input=payload, text=True, capture_output=True, env=e).returncode
        self.assertEqual(run(os.environ), 2)
        os.remove(os.path.join(self.tmp, "claude-ghprose-pe-gh1.json")) if os.path.exists(os.path.join(self.tmp, "claude-ghprose-pe-gh1.json")) else None
        self.assertEqual(run(self.profile(lambda d: d["tells"]["dense-block"].update(github="off"))), 0)

    def test_doc_voice_gate(self):
        spec3 = importlib.util.spec_from_file_location("dv_under_test", os.path.join(self.hooks, "doc-voice-gate.py"))
        dv = importlib.util.module_from_spec(spec3)
        spec3.loader.exec_module(dv)
        old = os.environ.get("PROSE_PROFILES")
        try:
            os.environ.pop("PROSE_PROFILES", None)
            self.assertIn("dense", dv.skim(DENSE))
            os.environ["PROSE_PROFILES"] = self.profile(lambda d: d["tells"]["dense-block"].update(doc="off"))["PROSE_PROFILES"]
            self.assertNotIn("dense", dv.skim(DENSE))
        finally:
            if old is None:
                os.environ.pop("PROSE_PROFILES", None)
            else:
                os.environ["PROSE_PROFILES"] = old

    def test_format_gate(self):
        reply = f"The cache keeps reads in memory {D} it saves a trip to disk."
        payload = json.dumps({"session_id": "pefgate00", "transcript_path": "", "stop_hook_active": False,
                              "last_assistant_message": reply})
        marker = "/tmp/claude-format-gate-pefgate0"

        def run(env):
            for p in (marker, "/tmp/claude-format-tripped-pefgate0"):
                if os.path.exists(p):
                    os.remove(p)
            r = subprocess.run(["bash", os.path.join(self.hooks, "format-gate-stop.sh")], input=payload, text=True,
                               capture_output=True, env=env)
            return r.stdout
        try:
            base = {**os.environ, "WARN_LOG_STORE": os.path.join(self.tmp, "warn.jsonl")}
            self.assertIn('"decision":"block"', run(base))
            out = run(self.profile(lambda d: d["tells"]["em-dash"].update(chat="warn")))
            self.assertNotIn('"decision":"block"', out)
            self.assertIn("emdash (advisory)", out)
        finally:
            for p in (marker, "/tmp/claude-format-tripped-pefgate0"):
                if os.path.exists(p):
                    os.remove(p)


class Procedure(unittest.TestCase):
    def test_numbered_steps_use_the_procedure_cap_when_asked(self):
        text = "1. " + sentence(22)
        self.assertEqual(findings(text, "doc", "sentence-length"), [])
        self.assertTrue(findings(text, "doc", "sentence-length", procedure=True))


if __name__ == "__main__":
    unittest.main(verbosity=2)
