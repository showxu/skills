"""Run document, style, lint and failure-path regressions without a native renderer."""

import base64
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import struct
import sys
import tempfile
import unittest
from unittest.mock import patch
import zlib

import app_icons

SCRIPT = Path(__file__).with_name("app_icons.py")
SVG = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><path fill="white" d="M256 256H768V768H256Z"/></svg>'


class DocumentTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "glyph.svg").write_text(SVG)
        self.spec = {"background": "#123456", "groups": [{"layers": [{"source": "glyph.svg"}]}]}
        self.design = self.root / "DESIGN.md"
        self.out = self.root / "output"
        self.write_design()

    def write_design(self):
        self.design.write_text("# Design\n\n## Iconography\n\n```json\n" +
                               json.dumps({"app_icons": {"example": self.spec}}) + "\n```\n")

    def invoke(self, *args):
        return subprocess.run([sys.executable, str(SCRIPT), str(self.design), "--name", "example", *map(str, args)],
                              capture_output=True, text=True,
                              env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"))

    def generate(self):
        result = self.invoke("--out", self.out, "--document-only")
        self.assertEqual(result.returncode, 0, result.stderr)

    def hashes(self):
        return {str(p.relative_to(self.out)): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in self.out.rglob("*") if p.is_file()}

    def test_document_is_self_contained(self):
        self.generate()
        document = json.loads((self.out / "example.icon/icon.json").read_text())
        name = document["groups"][0]["layers"][0]["image-name"]
        self.assertEqual((self.out / "example.icon/Assets" / name).read_text(), SVG)
        self.assertNotIn(str(self.root), json.dumps(document))
        result = self.invoke("--check", self.out, "--document-only")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_drift_check_reports_all_changes_without_writing(self):
        self.generate()
        (self.out / "example.icon/icon.json").write_text("{}\n")
        (self.out / "example.icon/Assets/01-01.svg").unlink()
        (self.out / "extra.txt").write_text("retained")
        before = self.hashes()
        result = self.invoke("--check", self.out, "--document-only")
        self.assertEqual(result.returncode, 1)
        for expected in ("drift\texample.icon/icon.json", "missing\texample.icon/Assets/01-01.svg", "extra\textra.txt"):
            self.assertIn(expected, result.stdout)
        self.assertEqual(before, self.hashes())

    def test_existing_output_is_preserved(self):
        self.generate()
        before = self.hashes()
        result = self.invoke("--out", self.out, "--document-only")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(before, self.hashes())

    def test_native_document_preserves_foreground_occlusion(self):
        self.spec["groups"] = [
            {"name": "Back", "layers": [{"source": "glyph.svg", "name": "Backdrop"}]},
            {"name": "Front", "layers": [
                {"source": "glyph.svg", "name": "Shadow"},
                {"source": "glyph.svg", "name": "Foreground"}]}]
        self.write_design()
        self.generate()
        groups = json.loads((self.out / "example.icon/icon.json").read_text())["groups"]
        self.assertEqual([g["name"] for g in groups], ["Front", "Back"])
        self.assertEqual([layer["name"] for layer in groups[0]["layers"]], ["Foreground", "Shadow"])

    def test_missing_layer_does_not_publish_partial_output(self):
        (self.root / "glyph.svg").unlink()
        result = self.invoke("--out", self.out, "--document-only")
        self.assertEqual(result.returncode, 1)
        self.assertIn("missing or unsupported layer", result.stderr)
        self.assertFalse(self.out.exists())

    def test_material_range_is_validated(self):
        self.spec["groups"][0]["shadow"] = {"kind": "neutral", "opacity": 2}
        self.write_design()
        result = self.invoke("--out", self.out, "--document-only")
        self.assertEqual(result.returncode, 1)
        self.assertIn("shadow.opacity", result.stderr)
        self.assertFalse(self.out.exists())

    def test_explicit_missing_renderer_does_not_fall_back(self):
        result = self.invoke("--out", self.out, "--ictool", self.root / "missing-ictool")
        self.assertEqual(result.returncode, 1)
        self.assertIn("export-capable ictool was not found", result.stderr)
        self.assertFalse(self.out.exists())

    def test_live_text_is_rejected(self):
        (self.root / "glyph.svg").write_text(SVG.replace("<path", "<text>Example</text><path"))
        result = self.invoke("--out", self.out, "--document-only")
        self.assertEqual(result.returncode, 1)
        self.assertIn("outlined artwork", result.stderr)
        self.assertFalse(self.out.exists())


class RenderDimensionsTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)

    def png(self, path, width, height):
        def chunk(kind, data):
            return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
        header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
        rows = (b"\0" + b"\xff\0\0\xff" * width) * height
        path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) +
                         chunk(b"IDAT", zlib.compress(rows)) + chunk(b"IEND", b""))

    def test_native_renderer_dimensions_are_verified(self):
        def wrong_size(args):
            self.png(Path(args[args.index("--output-file") + 1]), 16, 16)
            return ""
        glyph = self.root / "glyph.svg"
        glyph.write_text(SVG)
        spec = {"background": "#123456", "groups": [{"layers": [{"source": "glyph.svg"}]}]}
        with patch.object(app_icons, "run", side_effect=wrong_size):
            with self.assertRaisesRegex(ValueError, "expected 1024x1024, got 16x16"):
                app_icons.build("example", spec, self.root, self.root / "candidate", "liquid-glass", "renderer")

    def test_web_renderer_dimensions_are_verified(self):
        target = self.root / "web.png"
        with patch.object(app_icons, "run", side_effect=lambda _: self.png(target, 32, 32)):
            with self.assertRaisesRegex(ValueError, "expected 180x180, got 32x32"):
                app_icons.render_png(self.root / "web.svg", target, 180)
        app_icons.png_payload(target, 32)

    def test_drift_tolerates_single_level_rounding_only(self):
        def write(path, pixel):
            def chunk(kind, data):
                return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
            rows = b"".join(b"\0" + bytes(pixel) + b"\0\0\0\xff" for _ in range(2))
            path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 2, 2, 8, 6, 0, 0, 0)) +
                             chunk(b"IDAT", zlib.compress(rows)) + chunk(b"IEND", b""))
        base, near, far = (self.root / f"{n}.png" for n in ("base", "near", "far"))
        write(base, (100, 100, 100, 255))
        write(near, (101, 100, 99, 255))
        write(far, (102, 100, 100, 255))
        self.assertTrue(app_icons.same_pixels(base, near))
        self.assertFalse(app_icons.same_pixels(base, far))

    def test_missing_png_header_is_rejected(self):
        target = self.root / "invalid.png"
        target.write_bytes(b"\x89PNG\r\n\x1a\n")
        with self.assertRaisesRegex(ValueError, "image header"):
            app_icons.png_payload(target, 1024)

    def test_entry_generation_reaches_renderer_and_manifest(self):
        calls = []

        def renderer(args):
            args = list(map(str, args))
            calls.append(args)
            if "--export-image" in args:
                size = int(args[args.index("--width") + 1])
                self.png(Path(args[args.index("--output-file") + 1]), size, size)
            elif "-w" in args:
                size = int(args[args.index("-w") + 1])
                self.png(Path(args[args.index("-o") + 1]), size, size)
            elif "-o" in args:
                self.png(Path(args[args.index("-o") + 1]), 1, 1)
            return "renderer 1"
        (self.root / "glyph.svg").write_text(SVG)
        spec = {"background": "#123456", "groups": [{"layers": [{"source": "glyph.svg"}]}],
                "styles": {"liquid-glass": {"design_generation": 27}}}
        out = self.root / "candidate"
        with patch.object(app_icons, "run", side_effect=renderer):
            app_icons.build("example", spec, self.root, out, "liquid-glass", "renderer")
        exports = [c for c in calls if "--export-image" in c]
        self.assertEqual(len(exports), 18)
        self.assertTrue(all(c[c.index("--design-generation") + 1] == "27" for c in exports))
        manifest = json.loads((out / "manifest.json").read_text())
        self.assertEqual((manifest["style"], manifest["rendering"], manifest["design_generation"]),
                         ("liquid-glass", "native", 27))
        for name in ("favicon-16.png", "favicon-32.png", "icon-192.png", "icon-512.png",
                     "avatar-1024.png", "apple-touch-icon.png", "maskable-512.png"):
            self.assertIn(f"web/{name}", manifest["files"])


class StyleTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / "glyph.svg").write_text(SVG)
        (self.root / "texture.svg").write_text(SVG.replace("white", "black"))
        self.spec = {"background": "#123456", "groups": [{"layers": [{"source": "glyph.svg"}]},
                                                        {"layers": [{"source": "glyph.svg"}]}]}

    def invoke(self, spec, *args):
        design = self.root / "DESIGN.md"
        design.write_text("# Design\n\n## Iconography\n\n```json\n" +
                          json.dumps({"app_icons": {"example": spec}}) + "\n```\n")
        return subprocess.run([sys.executable, str(SCRIPT), str(design), "--name", "example", *map(str, args)],
                              capture_output=True, text=True, env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"))

    def test_entries_default_to_liquid_glass(self):
        self.assertEqual(app_icons.select_style(self.spec, None), "liquid-glass")

    def test_several_styles_require_a_choice(self):
        result = self.invoke({**self.spec, "styles": {"flat": {}, "gloss": {}}}, "--out", self.root / "out")
        self.assertEqual(result.returncode, 1)
        self.assertIn("--style is required", result.stderr)
        self.assertFalse((self.root / "out").exists())

    def test_unknown_style_and_misplaced_options_are_rejected(self):
        for styles, message in (({"aqua": {}}, "unknown style"),
                                ({"flat": {"unclipped": [1]}}, "does not accept"),
                                ({"gloss": {"design_generation": 26}}, "does not accept"),
                                ({"liquid-glass": {"design_generation": 18}}, "design_generation must be"),
                                ({"mac-tile": {"unclipped": [3]}}, "unclipped must list")):
            with self.subTest(styles=styles):
                with self.assertRaisesRegex(ValueError, message):
                    app_icons.prepare({**self.spec, "styles": styles}, self.root, next(iter(styles)))

    def test_generation_flag_is_not_accepted(self):
        result = self.invoke(self.spec, "--out", self.root / "out", "--design-generation", "26")
        self.assertEqual(result.returncode, 2)
        self.assertIn("unrecognized arguments", result.stderr)

    def test_document_only_is_limited_to_liquid_glass(self):
        result = self.invoke({**self.spec, "styles": {"flat": {}}}, "--out", self.root / "out", "--document-only")
        self.assertEqual(result.returncode, 1)
        self.assertIn("liquid-glass", result.stderr)
        self.assertFalse((self.root / "out").exists())

    def test_style_groups_replace_the_shared_groups(self):
        spec = {**self.spec, "styles": {"flat": {}, "gloss": {"groups": [{"layers": [{"source": "texture.svg"}]}]}}}
        _, _, shared, _ = app_icons.prepare(spec, self.root, "flat")
        _, _, gloss, _ = app_icons.prepare(spec, self.root, "gloss")
        self.assertEqual(len(shared), 2)
        self.assertEqual(len(gloss), 1)
        self.assertIn(b"black", gloss[0]["art"][0][1])

    def test_continuous_shapes_meet_each_edge_at_the_departure(self):
        departure = app_icons.CONTINUOUS[0] * 229
        path = app_icons.continuous_path(0, 0, 1024, 229)
        for point in ((1024 - departure, 0), (1024, 1024 - departure), (departure, 1024), (0, departure)):
            self.assertIn(f"{point[0]:.2f} {point[1]:.2f}", path)
        self.assertEqual(path.count("C"), 12)
        flat = app_icons.compose("flat", self.spec, app_icons.prepare(self.spec, self.root, "liquid-glass")[2])
        self.assertIn(app_icons.continuous_path(0, 0, 1024, app_icons.FLAT_RADIUS * 1024), flat)

    def test_mac_tile_fits_art_and_lets_listed_groups_break_out(self):
        spec = {**self.spec, "styles": {"mac-tile": {"unclipped": [2]}}}
        _, _, groups, _ = app_icons.prepare(spec, self.root, "mac-tile")
        svg = app_icons.compose("mac-tile", spec, groups)
        inset, side, radius = app_icons.MAC_TILE
        self.assertIn(app_icons.continuous_path(inset, inset, side, radius), svg)
        self.assertEqual(svg.count('clip-path="url(#shape)"'), 1)
        self.assertIn(f'stdDeviation="{app_icons.MAC_SHADOW[1]}"', svg)
        payloads = [base64.b64decode(v) for v in re.findall(r"base64,([^\"]+)", svg)]
        margin = inset * 1024 / side
        widened = f'viewBox="{-margin:.4f} {-margin:.4f} {1024 + 2 * margin:.4f} {1024 + 2 * margin:.4f}"'
        self.assertEqual(sum(widened.encode() in p for p in payloads), 1)
        full = app_icons.compose("mac-tile", spec, groups, masked=False)
        self.assertNotIn("clip-path", full.split("</defs>")[1])
        self.assertNotIn("filter=", full)

    def test_gloss_highlight_is_part_of_every_composition(self):
        _, _, groups, _ = app_icons.prepare(self.spec, self.root, "liquid-glass")
        for masked in (True, False):
            svg = app_icons.compose("gloss", self.spec, groups, masked=masked)
            self.assertIn(app_icons.GLOSS_PATH, svg)
        self.assertIn(f'rx="{app_icons.GLOSS_RADIUS * 1024:.2f}"', svg)


class LintTests(unittest.TestCase):
    size = 64

    def group(self, label, cells, rgb=(255, 255, 255), clipped=True):
        pixels = [(*rgb, 255) if (i % self.size, i // self.size) in cells else (0, 0, 0, 0)
                  for i in range(self.size * self.size)]
        return {"label": label, "clipped": clipped, "pixels": pixels}

    def box(self, x0, y0, x1, y1):
        return {(x, y) for x in range(x0, x1) for y in range(y0, y1)}

    def findings(self, groups, outline=None, base=0.2):
        outline = outline or [True] * (self.size * self.size)
        return app_icons.lint_findings(groups, outline, base, self.size, 1)

    def test_stroke_width_comes_from_the_widest_point(self):
        cover = [(i % self.size, i // self.size) in self.box(10, 10, 15, 15) for i in range(self.size ** 2)]
        self.assertEqual(app_icons.shape_widths(cover, self.size), [5])

    def test_clean_layers_have_no_findings(self):
        self.assertEqual(self.findings([self.group("Panel", self.box(16, 16, 48, 48))]), [])

    def test_thin_detail_is_reported_at_small_size(self):
        found = self.findings([self.group("Line", self.box(30, 8, 31, 56))])
        self.assertEqual(len(found), 1)
        self.assertIn("narrower than 1 px", found[0])

    def test_artwork_outside_the_shape_is_reported(self):
        outline = [(i % self.size, i // self.size) in self.box(8, 8, 56, 56) for i in range(self.size ** 2)]
        groups = [self.group("Edge", self.box(0, 16, 40, 48)), self.group("Free", self.box(0, 16, 40, 48),
                                                                         clipped=False)]
        found = [f for f in self.findings(groups, outline) if "outside the shape" in f]
        self.assertEqual([f.split(":")[0] for f in found], ["Edge"])

    def test_close_lightness_is_reported_against_background_and_overlaps(self):
        base = app_icons.lightness(0x12, 0x34, 0x56)
        groups = [self.group("Back", self.box(8, 8, 40, 40), (0x14, 0x36, 0x58)),
                  self.group("Front", self.box(24, 24, 56, 56), (0x16, 0x38, 0x5a))]
        found = self.findings(groups, base=base)
        self.assertEqual(sum("background" in f for f in found), 2)
        self.assertEqual(sum("where they overlap" in f for f in found), 1)

    def test_group_count_is_advisory(self):
        groups = [self.group(f"G{i}", self.box(8 + i, 8, 40 + i, 40), (40 * i, 40 * i, 40 * i)) for i in range(4)]
        self.assertTrue(any("4 groups" in f for f in self.findings(groups, base=1.0)))


@unittest.skipUnless(shutil.which("rsvg-convert"), "rsvg-convert renders the SVG styles")
class StyleRenderingTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / "glyph.svg").write_text(SVG)
        spec = {"background": "#123456", "gradient": True, "groups": [{"layers": [{"source": "glyph.svg"}]}],
                "styles": {"flat": {}, "mac-tile": {}, "gloss": {}}}
        self.design = self.root / "DESIGN.md"
        self.design.write_text("# Design\n\n## Iconography\n\n```json\n" +
                               json.dumps({"app_icons": {"example": spec}}) + "\n```\n")

    def invoke(self, *args):
        return subprocess.run([sys.executable, str(SCRIPT), str(self.design), "--name", "example", *map(str, args)],
                              capture_output=True, text=True, env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"))

    def test_each_style_renders_and_checks_clean(self):
        for style in ("flat", "mac-tile", "gloss"):
            with self.subTest(style=style):
                out = self.root / style
                result = self.invoke("--out", out, "--style", style)
                self.assertEqual(result.returncode, 0, result.stderr)
                manifest = json.loads((out / "manifest.json").read_text())
                self.assertEqual((manifest["style"], manifest["rendering"]), (style, "style-rendering"))
                for name, size in (("favicon-16.png", 16), ("icon-512.png", 512), ("apple-touch-icon.png", 180),
                                   ("maskable-512.png", 512), ("avatar-1024.png", 1024)):
                    app_icons.png_payload(out / "web" / name, size)
                result = self.invoke("--check", out, "--style", style)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                (out / "web" / "favicon.svg").write_text("<svg/>")
                result = self.invoke("--check", out, "--style", style)
                self.assertEqual(result.returncode, 1)
                self.assertIn("drift\tweb/favicon.svg", result.stdout)

    def test_lint_and_sheet_cover_every_style(self):
        result = self.invoke("--lint")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stdout.strip(), "clean")
        sheet = self.root / "sheet.svg"
        result = self.invoke("--sheet", sheet)
        self.assertEqual(result.returncode, 0, result.stderr)
        text = sheet.read_text()
        for style in ("flat", "mac-tile", "gloss"):
            self.assertIn(f">{style}<", text)
        self.assertEqual(self.invoke("--sheet", sheet).returncode, 1)


if __name__ == "__main__":
    unittest.main()
