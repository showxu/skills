"""Run contract, isolation, drift and optional native-rendering regressions."""

import base64
import copy
import importlib.util
import io
from contextlib import redirect_stdout
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

    def test_check_stages_outside_the_target_repository(self):
        self.generate()
        temporary_directory = tempfile.TemporaryDirectory
        with patch.object(app_icons.tempfile, 'TemporaryDirectory', wraps=temporary_directory) as temporary:
            with patch.object(sys, 'argv', [str(SCRIPT), str(self.design), '--name', 'example',
                                           '--document-only', '--check', str(self.out)]):
                with redirect_stdout(io.StringIO()):
                    self.assertEqual(app_icons.main(), 0)
            self.assertIsNone(temporary.call_args.kwargs['dir'])

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

class MaterialTests(unittest.TestCase):
    setUp = DocumentTests.setUp
    write_design = DocumentTests.write_design
    invoke = DocumentTests.invoke
    generate = DocumentTests.generate

    def prepared(self, group=None, layer=None):
        spec = copy.deepcopy(self.spec)
        if group is not None:
            spec['groups'][0].update(group)
        if layer is not None:
            spec['groups'][0]['layers'][0].update(layer)
        return app_icons.prepare(spec, self.root, 'liquid-glass')[0]['groups'][0]

    def test_group_material_values(self):
        for key, values in {
            'blend-mode': ('normal', 'plus-lighter', 'plus-darker', 'overlay', 'multiply',
                           'soft-light', 'hard-light', 'darken', 'lighten', 'screen'),
            'specular': (True, False), 'opacity': (0, 0.25, 1),
            'shadow': tuple({'kind': kind, 'opacity': 0.5} for kind in ('neutral', 'layer-color', 'none')),
        }.items():
            for value in values:
                with self.subTest(key=key, value=value):
                    self.assertEqual(self.prepared(group={key: value})[key], value)
        for key, values in {
            'blend-mode': ('Multiply', 'color', '', None, [], 1, True),
            'specular': (0, 1, 'false', None, [], {}),
            'opacity': (-0.1, 1.01, True, '0.5', None, [], float('nan'), float('inf')),
            'shadow': ({'kind': 'chromatic', 'opacity': 0.5}, {'kind': 'NONE', 'opacity': 0},
                       {'kind': [], 'opacity': 0}, {'kind': 'none'},
                       {'kind': 'neutral', 'opacity': True},
                       {'kind': 'none', 'opacity': 0, 'extra': 1}),
            'lighting': (True,), 'unknown': (0,),
        }.items():
            for value in values:
                with self.subTest(key=key, value=value), self.assertRaises(ValueError):
                    self.prepared(group={key: value})

    def test_layer_fill_and_opacity_values(self):
        for kind in ('solid', 'automatic-gradient'):
            for hex_color, expected in (
                ('#000000', 'srgb:0.00000,0.00000,0.00000,1.00000'),
                ('#ff800000', 'srgb:1.00000,0.50196,0.00000,0.00000'),
                ('#FF008080', 'srgb:1.00000,0.00000,0.50196,0.50196')):
                with self.subTest(kind=kind, color=hex_color):
                    native = self.prepared(layer={'fill': {kind: hex_color}})['layers'][0]
                    self.assertEqual(native['fill'], {kind: expected})
        for opacity in (0, 0.75, 1):
            self.assertEqual(self.prepared(layer={'opacity': opacity})['layers'][0]['opacity'], opacity)
        for value in (None, [], '#FFFFFF', {}, {'solid': '#fff'}, {'solid': '#1234567'},
                      {'solid': '#GG0000'}, {'solid': 'srgb:1,1,1,1'}, {'solid': 123},
                      {'gradient': '#ffffff'}, {'solid': '#ffffff', 'automatic-gradient': '#ffffff'}):
            with self.subTest(fill=value), self.assertRaises(ValueError):
                self.prepared(layer={'fill': value})
        for value in (-0.1, 1.01, True, '0.5', None, [], float('nan'), float('inf')):
            with self.subTest(opacity=value), self.assertRaises(ValueError):
                self.prepared(layer={'opacity': value})
        for key in ('blend-mode', 'lighting', 'specular', 'unknown'):
            with self.subTest(key=key), self.assertRaises(ValueError):
                self.prepared(layer={key: 'normal'})

    def test_fill_specializations_serialize_as_one_native_property(self):
        layer = {'fill': {'solid': '#00FF00'}, 'fill-specializations': {
            'tinted': {'solid': '#40404080'}, 'dark': {'automatic-gradient': '#FF0000'},
            'default': {'solid': '#0000FF'}}}
        native = self.prepared(layer=layer)['layers'][0]
        self.assertNotIn('fill', native)
        self.assertEqual(native['fill-specializations'], [
            {'value': {'solid': 'srgb:0.00000,1.00000,0.00000,1.00000'}},
            {'appearance': 'light', 'value': {'solid': 'srgb:0.00000,0.00000,1.00000,1.00000'}},
            {'appearance': 'dark', 'value': {'automatic-gradient': 'srgb:1.00000,0.00000,0.00000,1.00000'}},
            {'appearance': 'tinted', 'value': {'solid': 'srgb:0.25098,0.25098,0.25098,0.50196'}}])
        del layer['fill']
        self.assertEqual(len(self.prepared(layer=layer)['layers'][0]['fill-specializations']), 3)
        for value in (None, [], {}, [{'appearance': 'dark', 'value': {'solid': '#FFFFFF'}}],
                      {'light': {'solid': '#FFFFFF'}}, {'Dark': {'solid': '#FFFFFF'}},
                      {'clear': {'solid': '#FFFFFF'}}, {'dark': None}, {'dark': {'solid': '#xyz'}}):
            with self.subTest(overrides=value), self.assertRaises(ValueError):
                self.prepared(layer={'fill-specializations': value})

    def test_material_document_serialization_preserves_artwork(self):
        group = self.spec['groups'][0]
        group.update({'blend-mode': 'plus-lighter', 'specular': False, 'opacity': 0.8,
                      'shadow': {'kind': 'none', 'opacity': 0}})
        group['layers'][0].update({'fill': {'automatic-gradient': '#FF0080'}, 'opacity': 0.6})
        self.write_design()
        self.generate()
        native = json.loads((self.out / 'example.icon/icon.json').read_text())['groups'][0]
        self.assertEqual(native, self.prepared())
        self.assertEqual((self.out / 'example.icon/Assets/01-01.svg').read_text(), SVG)


@unittest.skipUnless(shutil.which('rsvg-convert'), 'rsvg-convert renders the SVG styles')
class MaterialIsolationTests(unittest.TestCase):
    setUp = StyleTests.setUp
    invoke = StyleTests.invoke

    def test_materials_do_not_change_legacy_outputs_sheets_or_checks(self):
        plain = copy.deepcopy(self.spec)
        plain['styles'] = {style: {} for style in ('flat', 'mac-tile', 'gloss')}
        enriched = copy.deepcopy(plain)
        for group in enriched['groups']:
            group.update({'blend-mode': 'multiply', 'specular': False, 'opacity': 0.1,
                          'shadow': {'kind': 'layer-color', 'opacity': 0.9},
                          'refractivity': {'enabled': True, 'strength': 0.8, 'depth': 0.2},
                          'blur-material': 0.7, 'translucency': {'enabled': True, 'value': 0.8}})
            group['layers'][0].update({'fill': {'automatic-gradient': '#FF000080'}, 'opacity': 0.2,
                                      'fill-specializations': {'dark': {'solid': '#00FF00'}}})
        for style in plain['styles']:
            with self.subTest(style=style):
                outputs = [self.root / (style + suffix) for suffix in ('-plain', '-materials')]
                for spec, out in zip((plain, enriched), outputs):
                    app_icons.build('example', spec, self.root, out, style)
                self.assertEqual(tree_bytes(outputs[0]), tree_bytes(outputs[1]))
                result = self.invoke(enriched, '--style', style, '--check', outputs[0])
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for spec, folder in ((plain, 'plain-sheet'), (enriched, 'material-sheet')):
            (self.root / folder).mkdir()
        self.assertEqual(app_icons.sheet({'example': plain}, ['example'], self.root, None, self.root / 'plain-sheet'),
                         app_icons.sheet({'example': enriched}, ['example'], self.root, None, self.root / 'material-sheet'))
        # Liquid Glass's SVG favicon and full-bleed web sources also use the artwork.
        for spec in (plain, enriched):
            spec['styles'] = {'liquid-glass': {}}
        for masked, scale in ((True, 1), (False, 1), (False, 0.56)):
            self.assertEqual(*(app_icons.compose('liquid-glass', spec,
                                                 app_icons.prepare(spec, self.root, 'liquid-glass')[2],
                                                 masked=masked, scale=scale) for spec in (plain, enriched)))

    def test_lint_fill_notice_is_informational_and_artwork_still_matters(self):
        self.spec['groups'] = [self.spec['groups'][0]]
        self.spec['groups'][0]['layers'][0]['fill'] = {'solid': '#123456'}
        result = self.invoke(self.spec, '--lint')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('info\tliquid-glass\tgroup 1: Liquid Glass appearance is determined by layer fill', result.stdout)
        self.assertTrue(result.stdout.endswith('clean\n'))
        (self.root / 'glyph.svg').write_text(SVG.replace('white', '#123456'))
        self.spec['groups'][0]['layers'][0]['fill'] = {'solid': '#FFFFFF'}
        result = self.invoke(self.spec, '--lint')
        self.assertEqual(result.returncode, 1)
        self.assertIn('lightness', result.stdout)
        self.assertIn('too close', result.stdout)


def tree_bytes(root):
    return {str(p.relative_to(root)): p.read_bytes() for p in root.rglob('*') if p.is_file()}


class NativeMaterialTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        try:
            cls.tool = app_icons.find_ictool()
        except (ValueError, OSError) as exc:
            raise unittest.SkipTest(str(exc))

    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / 'panel.svg').write_text(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">'
            '<rect x="180" y="230" width="640" height="540" rx="100" fill="#a0c060"/></svg>')
        self.spec = {'background': '#334DA6', 'groups': [{'layers': [{'source': 'panel.svg'}]}]}
        self.serial = 0

    def render(self, spec, rendition='Default', generation=27):
        self.serial += 1
        out = self.root / str(self.serial)
        app_icons.build('probe', spec, self.root, out, document_only=True)
        png = out / 'render.png'
        app_icons.run([self.tool, out / 'probe.icon', '--export-image', '--output-file', png,
                       '--platform', 'iOS', '--rendition', rendition, '--width', 128, '--height', 128,
                       '--scale', 1, '--design-generation', generation])
        return app_icons.read_png(png)[2]

    def delta(self, a, b):
        return max(abs(x-y) for p, q in zip(a, b) for x, y in zip(p, q))

    def test_every_native_group_material_changes_pixels(self):
        control = self.render(self.spec)
        for key, values in {
            'blend-mode': app_icons.BLEND_MODES,
            'specular': (False, True), 'opacity': (0.3,),
            'shadow': tuple({'kind': kind, 'opacity': 0.8} for kind in app_icons.SHADOW_KINDS),
        }.items():
            for value in values:
                with self.subTest(key=key, value=value):
                    spec = copy.deepcopy(self.spec)
                    spec['groups'][0][key] = value
                    difference = self.delta(control, self.render(spec))
                    if (key, value) in (('blend-mode', 'normal'), ('specular', True)):
                        self.assertLessEqual(difference, app_icons.PNG_TOLERANCE)
                    else:
                        self.assertGreater(difference, app_icons.PNG_TOLERANCE)

    def test_layer_fills_alpha_and_opacity_change_pixels(self):
        control = self.render(self.spec)
        images = []
        for material in ({'fill': {'solid': '#FF0000'}}, {'fill': {'automatic-gradient': '#FF0000'}},
                         {'fill': {'solid': '#FF000080'}}, {'opacity': 0.3}):
            with self.subTest(material=material):
                spec = copy.deepcopy(self.spec)
                spec['groups'][0]['layers'][0].update(material)
                rendered = self.render(spec)
                self.assertGreater(self.delta(control, rendered), app_icons.PNG_TOLERANCE)
                images.append(rendered)
        self.assertGreater(self.delta(images[0], images[1]), app_icons.PNG_TOLERANCE)
        self.assertGreater(self.delta(images[0], images[2]), app_icons.PNG_TOLERANCE)

    def test_appearance_override_without_base_fill_inherits_artwork(self):
        spec = copy.deepcopy(self.spec)
        spec['groups'][0]['layers'][0]['fill-specializations'] = {'dark': {'solid': '#FF0000'}}
        for rendition in app_icons.RENDITIONS:
            with self.subTest(rendition=rendition):
                difference = self.delta(self.render(self.spec, rendition), self.render(spec, rendition))
                if rendition == 'Dark':
                    self.assertGreater(difference, app_icons.PNG_TOLERANCE)
                else:
                    self.assertLessEqual(difference, app_icons.PNG_TOLERANCE)

    def test_fill_overrides_affect_only_their_native_appearances(self):
        self.spec['groups'][0]['layers'][0]['fill'] = {'solid': '#00FF00'}
        for generation in app_icons.GENERATIONS:
            controls = {rend: self.render(self.spec, rend, generation) for rend in app_icons.RENDITIONS}
            for appearance, affected in {'default': {'Default'}, 'dark': {'Dark'},
                                         'tinted': {'TintedLight', 'TintedDark', 'ClearLight', 'ClearDark'}}.items():
                spec = copy.deepcopy(self.spec)
                spec['groups'][0]['layers'][0]['fill-specializations'] = {appearance: {'solid': '#FF0000'}}
                for rendition, control in controls.items():
                    with self.subTest(generation=generation, appearance=appearance, rendition=rendition):
                        difference = self.delta(control, self.render(spec, rendition, generation))
                        if rendition in affected:
                            self.assertGreater(difference, app_icons.PNG_TOLERANCE)
                        else:
                            self.assertLessEqual(difference, app_icons.PNG_TOLERANCE)


@unittest.skipUnless(os.environ.get('APP_ICONS_BASELINE'), 'set APP_ICONS_BASELINE to the pre-change script')
@unittest.skipUnless(shutil.which('rsvg-convert'), 'rsvg-convert renders the examples')
class BaselineRenderingTests(unittest.TestCase):
    def test_all_example_styles_preserve_bytes_with_identical_native_exports(self):
        module = importlib.util.spec_from_file_location('baseline_icons', os.environ['APP_ICONS_BASELINE'])
        baseline = importlib.util.module_from_spec(module)
        module.loader.exec_module(baseline)
        tool = app_icons.find_ictool()
        examples = SCRIPT.parent.parent / 'examples'
        with tempfile.TemporaryDirectory() as temp:
            for design in sorted(examples.glob('DESIGN*.md')):
                for name, spec in app_icons.read_entries(design).items():
                    for style in app_icons.entry_styles(spec):
                        with self.subTest(design=design.name, name=name, style=style):
                            outputs = [Path(temp) / f'{design.stem}-{name}-{style}-{i}' for i in range(2)]
                            exports = {}
                            original_run = baseline.run

                            def command_key(args):
                                args = list(map(str, args))
                                args[1] = '<document>'
                                args[args.index('--output-file') + 1] = '<output>'
                                return tuple(args)

                            def record(args):
                                result = original_run(args)
                                if '--export-image' in args:
                                    png = Path(args[args.index('--output-file') + 1])
                                    exports[command_key(args)] = (tree_bytes(Path(args[1])), png.read_bytes())
                                return result

                            with patch.object(baseline, 'run', side_effect=record):
                                baseline.build(name, spec, design.parent, outputs[0], style, tool)
                            app_icons.build(name, spec, design.parent, outputs[1], style, tool)
                            before, after = map(tree_bytes, outputs)
                            self.assertEqual(before.keys(), after.keys())
                            different = [key for key in before if before[key] != after[key]]
                            for key in different:
                                self.assertEqual(style, 'liquid-glass', key)
                                self.assertTrue(key.endswith('.png'), key)
                                self.assertTrue(app_icons.same_pixels(outputs[0] / key, outputs[1] / key), key)
                            print(f'baseline-live\t{name}\t{style}\t{len(before)-len(different)}/{len(before)} '
                                  f'files byte-identical; rounding-only: {different}', flush=True)
                            if style == 'liquid-glass':
                                # Replay actual baseline exports after verifying identical renderer
                                # inputs. This isolates producer bytes from GPU rounding between runs.
                                replay = Path(temp) / f'{design.stem}-{name}-{style}-replay'
                                used = set()
                                current_run = app_icons.run

                                def replay_native(args):
                                    if '--export-image' not in args:
                                        return current_run(args)
                                    key = command_key(args)
                                    document, png = exports[key]
                                    self.assertEqual(tree_bytes(Path(args[1])), document)
                                    Path(args[args.index('--output-file') + 1]).write_bytes(png)
                                    used.add(key)
                                    return ''

                                with patch.object(app_icons, 'run', side_effect=replay_native):
                                    app_icons.build(name, spec, design.parent, replay, style, tool)
                                self.assertEqual(used, exports.keys())
                                after = tree_bytes(replay)
                            self.assertEqual([key for key in before if before[key] != after[key]], [])
                            print(f'baseline-producer\t{name}\t{style}\t{len(before)} files byte-identical', flush=True)


if __name__ == "__main__":
    unittest.main()
