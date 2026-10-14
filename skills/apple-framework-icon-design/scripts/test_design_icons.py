#!/usr/bin/env python3
"""Palette and browser-safe glyph geometry regressions."""

import unittest
import xml.etree.ElementTree as ET

from design_icons import hex_oklch, lint
from stack_logo import GLYPHS, Spec, _keep_chroma, _palette, _scale_path, glyph_markup, icon_svg, oklch


class GlyphTests(unittest.TestCase):
    def test_path_commands_scale_lengths_but_not_arc_angles_or_flags(self):
        path = "M.1-.2 3e-1,.4 h-.5 v.6 l.7 .8 c.1 .2 .3 .4 .5 .6 s.1 .2 .3 .4 q.1 .2 .3 .4 t.1 .2 a.5 .6 45 011-.2 Z"
        self.assertEqual(
            _scale_path(path, 100),
            "M 10 -20 30 40 h -50 v 60 l 70 80 c 10 20 30 40 50 60 s 10 20 30 40 q 10 20 30 40 t 10 20 a 50 60 45 0 1 100 -20 Z",
        )
        self.assertEqual(_scale_path("M0 0 A.2 .3 -30 1 0 .8 .9", 100),
                         "M 0 0 A 20 30 -30 1 0 80 90")

    def test_library_strokes_and_dashes_are_emitted_at_browser_safe_scale(self):
        for name, glyph in GLYPHS.items():
            with self.subTest(glyph=name):
                root = ET.fromstring(glyph_markup(glyph, "white", 1))
                strokes = [p for p in root.iter("path") if "stroke" in p.attrib]
                for path in strokes:
                    self.assertAlmostEqual(float(path.attrib["stroke-width"]) / 100, glyph.get("width", 0.16))
                if strokes:
                    self.assertEqual(root[0].attrib["transform"], "scale(0.01)")
        root = ET.fromstring(glyph_markup(GLYPHS["dashed_plus"], "white", 1))
        self.assertEqual(next(root.iter("path")).attrib["stroke-dasharray"], "26 18")

    def test_custom_transform_and_mixed_shapes_share_the_original_geometry(self):
        glyph = {"style": "fill", "d": "M0 0H.5V.5Z", "extra": "M-.5 0H.5",
                 "width": .12, "rects": [[-.2, -.3, .4, .6]], "round": .1,
                 "dots": [[.2, .3, .04]], "knock": [[-.2, -.3, .02]],
                 "transform": "translate(.2 -.1) rotate(30)"}
        root = ET.fromstring(glyph_markup(glyph, "white", .8, ["red"], "blue"))
        self.assertEqual(root[0].attrib["transform"], glyph["transform"])
        group = root[0][0]
        self.assertEqual(group.attrib["transform"], "scale(0.01)")
        self.assertEqual(group[0].attrib["d"], "M 0 0 H 50 V 50 Z")
        self.assertEqual(group[2].attrib["fill"], "red")
        self.assertEqual(group[3].attrib, {"cx": "20", "cy": "30", "r": "4", "fill": "white"})
        self.assertEqual(group[4].attrib, {"cx": "-20", "cy": "-30", "r": "2", "fill": "blue"})

    def test_glyph_gradient_uses_the_same_coordinate_space_in_every_style(self):
        for style in ("stacked", "volumetric", "flat"):
            for glyph, bound in (("braces", "100"), ("spark", "1")):
                with self.subTest(style=style, glyph=glyph):
                    root = ET.fromstring(icon_svg(Spec(style=style, glyph=glyph, glyph_gradient=["red", "blue"])))
                    gradient = next(e for e in root.iter() if e.attrib.get("id", "").endswith("-gg"))
                    self.assertEqual(gradient.attrib["x1"], "-" + bound)
                    self.assertEqual(gradient.attrib["x2"], bound)


class PaletteTests(unittest.TestCase):
    def test_separated_dark_face_and_pastel_are_reported(self):
        table = {
            'lid': Spec(face_colors=['#333333', '#333333'],
                        band_colors=['#cccccc', '#dddddd', '#eeeeee']),
            'pastel': Spec(face_colors=[oklch(0.81, 0.10, 300)] * 2,
                           band_colors=[oklch(0.81, 0.10, 300)] * 3),
        }
        findings = lint(table)
        for reason in ('seam', 'dark face', 'pastel'):
            self.assertTrue(any(reason in item for item in findings), findings)

    def test_explicit_rose_ramp_retains_chroma(self):
        spec = Spec(
            face_colors=[oklch(0.67, 0.20, 25)] * 2,
            band_colors=[oklch(0.59, 0.20, 25), oklch(0.67, 0.18, 10), oklch(0.81, 0.16, 0)],
        )
        self.assertEqual(lint({'rose': spec}), [])
        lightness, chroma = hex_oklch(_palette(spec).bands[-1])
        self.assertGreaterEqual(lightness, 0.80)
        self.assertGreaterEqual(chroma, 0.11)

    def test_chroma_adjustment_is_bounded_and_preserves_in_gamut_colors(self):
        self.assertEqual(_keep_chroma(0.60, 0.10, 150), 0.60)
        lowered = _keep_chroma(0.81, 0.16, 0)
        self.assertGreaterEqual(lowered, 0.75 - 1e-9)
        self.assertLess(lowered, 0.81)
        original = hex_oklch(oklch(0.81, 0.16, 0))[1]
        adjusted = hex_oklch(oklch(lowered, 0.16, 0))[1]
        self.assertGreater(adjusted, original)


if __name__ == '__main__':
    unittest.main()
