"""Offline tests for gdoc.py: draw.io blocks, pageless mode and body readability.

Run: uv run --with markdown --with pygments python3 ~/.claude/scripts/gdoc/gdoc.test.py
The Docs and Drive APIs are replaced by fakes, so nothing here touches Google. One test
renders a real draw.io diagram and is skipped when the draw.io command line is missing.
"""
import importlib.util
import pathlib
import tempfile
import unittest
from unittest import mock

HERE = pathlib.Path(__file__).parent
spec = importlib.util.spec_from_file_location("gdoc", HERE / "gdoc.py")
gdoc = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gdoc)

DRAWIO_XML = ('<mxfile><diagram id="d" name="Page-1"><mxGraphModel><root><mxCell id="0"/><mxCell id="1" parent="0"/>'
              '<mxCell id="a" value="Box" style="rounded=1;" vertex="1" parent="1"><mxGeometry x="10" y="10" width="80" height="40" as="geometry"/></mxCell>'
              '</root></mxGraphModel></diagram></mxfile>')


def kinds(blocks):
    return [b[0] for b in blocks]


class DrawioBlocks(unittest.TestCase):
    def test_fence_becomes_a_drawio_block(self):
        blocks = gdoc.md_blocks(f"Before.\n\n```drawio\n{DRAWIO_XML}\n```\n\nAfter.\n")
        self.assertEqual(kinds(blocks), ["p", "drawio", "p"])
        self.assertEqual(blocks[1][1], DRAWIO_XML)

    def test_file_reference_is_read_from_beside_the_markdown(self):
        with tempfile.TemporaryDirectory() as d:
            (pathlib.Path(d) / "flow.drawio").write_text(DRAWIO_XML + "\n")
            blocks = gdoc.md_blocks("![Flow](flow.drawio)\n", d)
        self.assertEqual(kinds(blocks), ["drawio"])
        self.assertEqual(blocks[0][1], DRAWIO_XML)

    def test_missing_file_stops_with_the_path(self):
        with tempfile.TemporaryDirectory() as d, self.assertRaises(SystemExit) as cm:
            gdoc.md_blocks("![Flow](nope.drawio)\n", d)
        self.assertIn("nope.drawio", str(cm.exception))

    def test_an_ordinary_image_is_not_taken_for_a_diagram(self):
        # The opposite proof: the .drawio match must not swallow plain images.
        blocks = gdoc.md_blocks("![Logo](logo.png)\n", "/nonexistent")
        self.assertNotIn("drawio", kinds(blocks))

    def test_a_drawio_name_inside_a_sentence_is_left_alone(self):
        blocks = gdoc.md_blocks("See ![x](flow.drawio) for the flow.\n", "/nonexistent")
        self.assertNotIn("drawio", kinds(blocks))


class DiagramImages(unittest.TestCase):
    def test_both_kinds_become_image_paragraphs_and_other_blocks_stay(self):
        fake_png = mock.Mock(stem="abc")
        with mock.patch.dict(gdoc.DIAGRAM_RENDERERS, {"mermaid": lambda s: fake_png, "drawio": lambda s: fake_png}), \
             mock.patch.object(gdoc, "drive_upload_shared", return_value=("fid", "https://x/uc?id=fid")), \
             mock.patch.object(gdoc, "png_width_pt", return_value=300):
            uploaded = []
            out = gdoc.diagrams_to_images("tok", "folder", [("mermaid", "graph TD"), ("drawio", "<x/>"), ("rule",)], uploaded)
        self.assertEqual(kinds(out), ["p", "p", "rule"])
        self.assertEqual(uploaded, ["fid", "fid"])

    def test_the_real_registry_routes_drawio_to_its_renderer(self):
        # The test above swaps the registry, so this one pins the shipped wiring itself.
        self.assertIs(gdoc.DIAGRAM_RENDERERS["drawio"], gdoc.render_drawio)
        self.assertIs(gdoc.DIAGRAM_RENDERERS["mermaid"], gdoc.render_mermaid)

    def test_missing_renderer_names_the_install_and_removal_commands(self):
        with mock.patch.object(gdoc.shutil, "which", return_value=None), \
             mock.patch.object(gdoc, "DRAWIO_APP_BIN", "/nonexistent/draw.io"), self.assertRaises(SystemExit) as cm:
            gdoc.drawio_bin()
        msg = str(cm.exception)
        self.assertIn("brew install --cask drawio", msg)
        self.assertIn("brew uninstall --cask drawio", msg)

    @unittest.skipUnless(gdoc.shutil.which("drawio") or pathlib.Path(gdoc.DRAWIO_APP_BIN).exists(), "draw.io command line not installed")
    def test_real_render_makes_a_png(self):
        with tempfile.TemporaryDirectory() as d, mock.patch.object(gdoc, "DRAWIO_CACHE", pathlib.Path(d)):
            png = gdoc.render_drawio(DRAWIO_XML)
            self.assertEqual(png.read_bytes()[:8], b"\x89PNG\r\n\x1a\n")
            self.assertGreater(gdoc.png_width_pt(png), 0)


def fake_docs(initial_mode, applies=True):
    """A stand-in for the Docs API holding tab t.0 and t.1; `applies` False makes it ignore mode changes."""
    state = {"t.0": initial_mode, "t.1": initial_mode}

    def gapi(tok, url, method="GET", body=None):
        if method == "POST":
            for r in body["requests"]:
                u = r["updateDocumentStyle"]
                if applies: state[u["tabId"]] = u["documentStyle"]["documentFormat"]["documentMode"]
            return {}
        return {"tabs": [{"tabProperties": {"tabId": t}, "documentTab": {"documentStyle": {"documentFormat": {"documentMode": m}}}}
                         for t, m in state.items()]}
    return gapi


class PagelessMode(unittest.TestCase):
    def test_request_sets_pageless_on_each_tab(self):
        reqs = gdoc.document_mode_requests(["t.0", "t.1"])
        self.assertEqual([r["updateDocumentStyle"]["tabId"] for r in reqs], ["t.0", "t.1"])
        for r in reqs:
            self.assertEqual(r["updateDocumentStyle"]["documentStyle"], {"documentFormat": {"documentMode": "PAGELESS"}})
            self.assertEqual(r["updateDocumentStyle"]["fields"], "documentFormat.documentMode")

    def test_paged_option_asks_for_pages(self):
        reqs = gdoc.document_mode_requests(["t.0"], pageless=False)
        self.assertEqual(reqs[0]["updateDocumentStyle"]["documentStyle"]["documentFormat"]["documentMode"], "PAGES")

    def test_a_paged_doc_reads_back_pageless(self):
        with mock.patch.object(gdoc, "gapi", fake_docs("PAGES")):
            self.assertEqual(gdoc.set_document_mode("tok", "doc", ["t.0", "t.1"]), [])

    def test_a_refused_change_is_reported_not_swallowed(self):
        # The opposite proof: if Docs ignores the request, the read-back names the tabs that stayed paged.
        with mock.patch.object(gdoc, "gapi", fake_docs("PAGES", applies=False)):
            self.assertEqual(gdoc.set_document_mode("tok", "doc", ["t.0", "t.1"]), ["t.0", "t.1"])

    def test_a_tab_with_no_mode_reads_as_pages(self):
        doc = {"tabs": [{"tabProperties": {"tabId": "t.0"}, "documentTab": {"documentStyle": {}}}]}
        self.assertEqual(gdoc.document_modes(doc), {"t.0": "PAGES"})


def normal_text(reqs):
    return next(r["updateNamedStyle"] for r in reqs if r["updateNamedStyle"]["namedStyle"]["namedStyleType"] == "NORMAL_TEXT")


class Readability(unittest.TestCase):
    def setUp(self):
        self._read, self._spacing = dict(gdoc.READ), dict(gdoc.G["spacing"])
        gdoc.READ.clear(); gdoc.READ.update(gdoc.READABILITY_DEFAULTS)

    def tearDown(self):
        gdoc.READ.clear(); gdoc.READ.update(self._read)
        gdoc.G["spacing"].clear(); gdoc.G["spacing"].update(self._spacing)

    def test_body_gets_looser_lines_a_gap_and_no_stranded_lines(self):
        ns = normal_text(gdoc.named_style_requests("t.0"))
        ps = ns["namedStyle"]["paragraphStyle"]
        self.assertEqual(ps["lineSpacing"], 115)
        self.assertEqual(ps["spaceBelow"], {"magnitude": 6, "unit": "PT"})
        self.assertTrue(ps["avoidWidowAndOrphan"])
        for f in ("lineSpacing", "spaceBelow", "avoidWidowAndOrphan"):
            self.assertIn("paragraphStyle." + f, ns["fields"])

    def test_headings_are_not_given_the_body_settings(self):
        heading = next(r["updateNamedStyle"] for r in gdoc.named_style_requests("t.0")
                       if r["updateNamedStyle"]["namedStyle"]["namedStyleType"] == "HEADING_2")
        ps = heading["namedStyle"]["paragraphStyle"]
        self.assertEqual(ps.get("lineSpacing"), gdoc.G["heading_line_spacing"])
        self.assertNotIn("avoidWidowAndOrphan", ps)

    def test_turning_it_off_leaves_docs_own_defaults(self):
        gdoc.READ.clear()
        ns = normal_text(gdoc.named_style_requests("t.0"))
        self.assertNotIn("lineSpacing", ns["namedStyle"]["paragraphStyle"])
        self.assertNotIn("paragraphStyle.lineSpacing", ns["fields"])

    def test_a_config_value_overrides_the_default(self):
        gdoc.READ.update({"line_spacing": 130, "space_below": 10})
        ps = normal_text(gdoc.named_style_requests("t.0"))["namedStyle"]["paragraphStyle"]
        self.assertEqual((ps["lineSpacing"], ps["spaceBelow"]["magnitude"]), (130, 10))

    def test_a_body_spacing_entry_wins_over_the_readability_gap(self):
        gdoc.G["spacing"]["body"] = [2, 3]
        ps = normal_text(gdoc.named_style_requests("t.0"))["namedStyle"]["paragraphStyle"]
        self.assertEqual((ps["spaceAbove"]["magnitude"], ps["spaceBelow"]["magnitude"]), (2, 3))
        self.assertEqual(ps["lineSpacing"], 115)


class ListNesting(unittest.TestCase):
    def test_two_space_indent_nests(self):
        blocks = gdoc.md_blocks("- one\n  - inner\n- two\n")
        self.assertEqual([b[1] for b in blocks if b[0] == "li"], [1, 2, 1])

    def test_four_space_indent_still_nests(self):
        blocks = gdoc.md_blocks("- one\n    - inner\n")
        self.assertEqual([b[1] for b in blocks if b[0] == "li"], [1, 2])

    def test_code_fences_keep_their_indent(self):
        # The opposite proof: a list-looking line inside fenced code is not touched.
        self.assertEqual(gdoc.widen_list_indent("```\n  - x\n```"), "```\n  - x\n```")


def cell(text):
    return [(text, {})]


class TableWidths(unittest.TestCase):
    def setUp(self):
        self._width = gdoc.G["table"]["page_width_pt"]
        gdoc.G["table"]["page_width_pt"] = 516

    def tearDown(self):
        gdoc.G["table"]["page_width_pt"] = self._width

    def test_widths_fill_the_text_column(self):
        rows = [[cell("Goal"), cell("Status")], [cell("Ship it"), cell("Done")]]
        self.assertAlmostEqual(sum(gdoc.column_widths(rows)), 516, delta=0.1)

    def test_prose_column_gets_the_room_and_a_status_column_stays_narrow(self):
        prose = "Writing it needs a Versable admin since 25 Nov. One more place has no caller and can be deleted"
        rows = [[cell("Measure"), cell("State"), cell("Proof")]] + [[cell("Removed the routes that ran code"), cell("ok"), cell(prose)]] * 3
        w = gdoc.column_widths(rows)
        self.assertLess(w[1], 70)
        self.assertGreater(w[2], w[0])

    def test_two_long_columns_split_by_how_much_text_each_holds(self):
        # Both columns pass the old 48-character cap, which split them evenly; the longer one must now win.
        long, short = "x " * 49, "y " * 27
        rows = [[cell("A"), cell("B")]] + [[cell(long), cell(short)]] * 4
        w = gdoc.column_widths(rows)
        self.assertGreater(w[0], w[1] * 1.3)

    def test_a_short_label_column_stays_on_one_line(self):
        rows = [[cell(""), cell("")], [cell("Time to code execution"), cell("word " * 60)]]
        w = gdoc.column_widths(rows)
        self.assertGreaterEqual(w[0], len("Time to code execution") * 5)

    def test_every_column_keeps_its_longest_word_whole(self):
        rows = [[cell("Header"), cell("Notes")], [cell("internationalisation"), cell("word " * 80)]]
        w = gdoc.column_widths(rows)
        self.assertGreaterEqual(w[0], len("internationalisation") * 5)


class Pageless(unittest.TestCase):
    def setUp(self):
        self._t, self._sp, self._img = dict(gdoc.G["table"]), dict(gdoc.G["spacing"]), gdoc.PAGE_WIDTH_PT

    def tearDown(self):
        gdoc.G["table"].clear(); gdoc.G["table"].update(self._t)
        gdoc.G["spacing"].clear(); gdoc.G["spacing"].update(self._sp)
        gdoc.PAGE_WIDTH_PT = self._img

    def test_tables_and_images_take_the_pageless_column(self):
        gdoc.apply_pageless()
        self.assertEqual(gdoc.G["table"]["page_width_pt"], 516)
        self.assertEqual(gdoc.PAGE_WIDTH_PT, 516)

    def test_without_pageless_tables_keep_the_page_width(self):
        # The opposite proof: the spec's base table width is the paged one.
        self.assertEqual(gdoc.G["table"]["page_width_pt"], 468)


def para_style_on(reqs, start):
    return [r["updateParagraphStyle"]["paragraphStyle"] for r in reqs
            if "updateParagraphStyle" in r and r["updateParagraphStyle"]["range"]["startIndex"] == start]


class Rhythm(unittest.TestCase):
    def test_a_paragraph_after_a_list_gets_a_gap(self):
        reqs, _ = gdoc.tab_requests(gdoc.md_blocks("- one\n- two\n\nAfter.\n"), "t.0")
        last_item = len("one\n") + 1
        gap = {"spaceBelow": {"magnitude": gdoc.READ["space_below"], "unit": "PT"}}
        self.assertIn(gap, para_style_on(reqs, last_item))

    def test_a_heading_after_a_list_gets_no_extra_gap(self):
        # The opposite proof: a heading brings its own space above.
        reqs, _ = gdoc.tab_requests(gdoc.md_blocks("- one\n- two\n\n## Next\n"), "t.0")
        gap = {"spaceBelow": {"magnitude": gdoc.READ["space_below"], "unit": "PT"}}
        self.assertNotIn(gap, para_style_on(reqs, len("one\n") + 1))

    def test_the_opening_heading_has_no_space_above(self):
        reqs, _ = gdoc.tab_requests(gdoc.md_blocks("## Opening\n\nText.\n\n## Later\n"), "t.0")
        heads = [r["updateParagraphStyle"]["paragraphStyle"] for r in reqs
                 if "updateParagraphStyle" in r and r["updateParagraphStyle"]["paragraphStyle"].get("namedStyleType") == "HEADING_2"]
        self.assertEqual(heads[0].get("spaceAbove"), {"magnitude": 0, "unit": "PT"})
        self.assertNotIn("spaceAbove", heads[1])

    def test_appended_blocks_keep_their_first_heading_space(self):
        reqs, _ = gdoc.tab_requests(gdoc.md_blocks("# Samples\n"), "t.0", opening=False)
        self.assertEqual(reqs[1]["updateParagraphStyle"]["paragraphStyle"]["namedStyleType"], "HEADING_1")
        self.assertNotIn("spaceAbove", reqs[1]["updateParagraphStyle"]["paragraphStyle"])


def styles_in_order(reqs):
    return [r["updateParagraphStyle"]["paragraphStyle"].get("namedStyleType") for r in reqs
            if "updateParagraphStyle" in r and "namedStyleType" in r["updateParagraphStyle"]["paragraphStyle"]]


class TitleBlock(unittest.TestCase):
    def test_opening_h1_is_the_title_and_the_next_line_the_subtitle(self):
        reqs, _ = gdoc.tab_requests(gdoc.md_blocks("# Ops review\n\nWeekly review | Nov 27, 2026 | A. C.\n\nBody.\n\n# Part two\n"), "t.0")
        self.assertEqual(styles_in_order(reqs), ["TITLE", "SUBTITLE", "NORMAL_TEXT", "HEADING_1"])

    def test_a_heading_after_the_title_gets_no_subtitle(self):
        # The opposite proof: only a paragraph directly after the title becomes the subtitle.
        reqs, _ = gdoc.tab_requests(gdoc.md_blocks("# Ops review\n\n## Notes\n\nBody.\n"), "t.0")
        self.assertEqual(styles_in_order(reqs), ["TITLE", "HEADING_2", "NORMAL_TEXT"])

    def test_ordinary_intro_prose_after_the_title_stays_body_text(self):
        # An existing README cover opens with prose; it must not shrink into the Subtitle face.
        reqs, _ = gdoc.tab_requests(gdoc.md_blocks("# Project guide\n\nThis guide explains the setup.\n\n## Install\n"), "t.0")
        self.assertEqual(styles_in_order(reqs), ["TITLE", "NORMAL_TEXT", "HEADING_2"])

    def test_title_and_headings_get_tight_leading_and_title_aligns_left(self):
        named = {r["updateNamedStyle"]["namedStyle"]["namedStyleType"]: r["updateNamedStyle"]["namedStyle"]["paragraphStyle"]
                 for r in gdoc.named_style_requests("t.0")}
        self.assertEqual(named["TITLE"]["alignment"], "START")
        self.assertEqual(named["SUBTITLE"]["alignment"], "START")
        self.assertEqual(named["HEADING_2"]["lineSpacing"], gdoc.G["heading_line_spacing"])
        self.assertNotEqual(named["NORMAL_TEXT"].get("lineSpacing"), gdoc.G["heading_line_spacing"])


class CodeColours(unittest.TestCase):
    def colours(self, src, lang="python"):
        reqs = gdoc.highlight_requests(src, lang, 1, "t.0")
        return {src[r["updateTextStyle"]["range"]["startIndex"] - 1:r["updateTextStyle"]["range"]["endIndex"] - 1]:
                r["updateTextStyle"]["textStyle"] for r in reqs}

    def test_keywords_strings_and_comments_take_the_spec_palette(self):
        c = self.colours('def f():\n    return "x"  # note\n')
        self.assertEqual(c["def"]["foregroundColor"], gdoc.rgb(gdoc.G["code"]["colors"]["Keyword"]))
        self.assertEqual(c['"x"']["foregroundColor"], gdoc.rgb(gdoc.G["code"]["colors"]["Literal.String"]))
        self.assertTrue(c["# note"]["italic"])

    def test_the_most_specific_token_type_wins(self):
        c = self.colours("def f():\n    return None\n")
        self.assertEqual(c["None"]["foregroundColor"], gdoc.rgb(gdoc.G["code"]["colors"]["Keyword.Constant"]))


class ContentChecks(unittest.TestCase):
    GOOD = "# Ops review\n\nWeekly review | Nov 27, 2026 | A. C.\n\n## Notes\n\n- one\n- two\n\n## Part\n\nText.\n"

    def test_a_house_style_doc_passes(self):
        self.assertEqual(gdoc.content_checks(gdoc.md_blocks(self.GOOD)), [])

    def test_each_rule_is_named_when_broken(self):
        bad = ("# A title that runs far past five words\n\nno subtitle here\n\n## Summary\n\n- a\n\n"
               "## Notes\n\n- a\n- b\n- c\n- d\n\n## Open questions\n\n- x\n")
        notes = " ".join(gdoc.content_checks(gdoc.md_blocks(bad)))
        for phrase in ("5 or fewer", "<topic>", '"## Notes"', "skip"):
            self.assertIn(phrase, notes)

    def test_notes_with_more_than_three_points_or_prose_is_flagged(self):
        notes = gdoc.content_checks(gdoc.md_blocks(self.GOOD.replace("- two\n", "- two\n- three\n- four\n\nProse.\n")))
        self.assertTrue(any("3" in n for n in notes) and any("only a bullet list" in n for n in notes))

    def test_doc_name_fixes_the_date_once(self):
        cfg = {"title": "Ops review"}
        name = gdoc.doc_name(cfg)
        self.assertRegex(name, r"^Ops review \| [A-Z][a-z]{2} \d{1,2}, \d{4} \| .+$")
        cfg["date"] = "Jul 14, 2026"
        self.assertTrue(gdoc.doc_name(cfg).startswith("Ops review | Jul 14, 2026 | "))


class MermaidTheme(unittest.TestCase):
    def test_spec_colours_reach_mermaid_with_a_hash(self):
        conf = gdoc.mermaid_config()
        self.assertEqual(conf["theme"], "base")
        self.assertTrue(conf["themeVariables"]["primaryColor"].startswith("#"))
        self.assertFalse(conf["themeVariables"]["fontFamily"].startswith("#"))


if __name__ == "__main__":
    unittest.main(verbosity=1)
