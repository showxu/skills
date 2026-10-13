#!/usr/bin/env python3
"""Palette regressions for slab lighting and gamut-aware colors."""

import unittest

from design_icons import hex_oklch, lint
from stack_logo import Spec, _keep_chroma, _palette, oklch


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
