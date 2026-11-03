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
        self.assertNotIn("lineSpacing", heading["namedStyle"]["paragraphStyle"])

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


if __name__ == "__main__":
    unittest.main(verbosity=1)
