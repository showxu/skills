"""Run contract, isolation, drift and optional native-rendering regressions."""

import base64
import copy
import importlib.util
import io
from contextlib import redirect_stdout
import hashlib
import json
import math
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


def naive_continuous_square(x, y, side, radius):
    """Continuous corners joined by straight lines even when they overrun the edge."""
    departure, segments = app_icons.CONTINUOUS
    return app_icons.rounded_path(x, y, side, departure * radius,
                                  tuple(tuple((u * radius, v * radius) for u, v in s) for s in segments))


def layer(*paths):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">' +
            "".join(f'<path d="{d}"/>' for d in paths) + "</svg>")


def path_cubics(d):
    """Cubics of absolute M/C/L/Z path data, with lines as degenerate cubics."""
    cubics, current, start = [], None, None
    for command, numbers in re.findall(r"([MCLZ])([^MCLZ]*)", d):
        values = [float(v) for v in re.findall(r"-?\d+(?:\.\d+)?", numbers)]
        points = list(zip(values[::2], values[1::2]))
        if command == "M":
            current = start = points[0]
        elif command == "C":
            cubics.append((current, *points))
            current = points[2]
        else:
            end = points[0] if command == "L" else start
            if end != current:
                cubics.append((current, current, end, end))
            current = end
    return cubics


class ContinuousRectTests(unittest.TestCase):
    shapes = [(0, 0, 300, 100, 50), (0, 0, 100, 100, 40), (10, 20, 300, 100, (10, 50, 30, 0)),
              (0, 0, 300, 100, (45, 45, 20, 20)), (5, 5, 80, 300, (40, 10, 40, 10)), (0, 0, 120, 100, 49),
              (0, 0, 100, 100, 50), (0, 0, 100, 100, (50, 0, 50, 0)), (0, 0, 100, 100, (80, 10, 0, 20)),
              (25, 25, 231, 231, (189, 30 / app_icons.CONTINUOUS[0], 0, 30 / app_icons.CONTINUOUS[0])),
              (0, 0, 300, 100, (40, 60, 40, 60)), (0, 0, 950, 850, (70, 830, 4, 730))]

    def test_feasible_corners_meet_each_edge_at_their_departure(self):
        k = app_icons.CONTINUOUS[0]
        path = app_icons.continuous_rect(10, 20, 400, 200, (0, 60, 20, 40))
        for point in ((410 - k * 60, 20), (410, 20 + k * 60), (410, 220 - k * 20), (410 - k * 20, 220),
                      (10 + k * 40, 220), (10, 220 - k * 40), (10, 20)):
            self.assertIn(f"{point[0]:.2f} {point[1]:.2f}", path)
        self.assertEqual(path.count("C"), 9)
        self.assertEqual(app_icons.continuous_path(3, 7, 500, 100), app_icons.continuous_rect(3, 7, 500, 500, 100))
        for radius in (0.5, 1, 2, 30):
            with self.subTest(radius=radius):
                self.assertEqual(app_icons.continuous_rect(0, 0, 100, 100, radius),
                                 naive_continuous_square(0, 0, 100, radius))

    def test_overrunning_corners_blend_without_doubling_back(self):
        for x, y, width, height, radii in self.shapes:
            with self.subTest(shape=(width, height, radii)):
                path = app_icons.continuous_rect(x, y, width, height, radii)
                self.assertEqual(app_icons.doubled_back(layer(path)), [])
                cubics = path_cubics(path)
                for cubic in cubics:
                    for px, py in cubic:
                        self.assertTrue(x - 0.005 <= px <= x + width + 0.005 and y - 0.005 <= py <= y + height + 0.005)
                points = [app_icons.cubic_point(c, t / 40) for c in cubics for t in range(40)]
                turns = [(b[0] - a[0]) * (c[1] - b[1]) - (b[1] - a[1]) * (c[0] - b[0])
                         for a, b, c in zip(points, points[1:] + points[:1], points[2:] + points[:2])]
                self.assertGreaterEqual(min(turns), -1e-3, "outline must stay convex")
                vertices = {(x, y), (x + width, y), (x + width, y + height), (x, y + height)}
                segments = app_icons.path_segments(path)[0][0]
                for (_, _, joint, incoming), (_, outgoing, _, _) in zip(segments, segments[1:] + segments[:1]):
                    cosine = ((incoming[0] * outgoing[0] + incoming[1] * outgoing[1]) /
                              (math.hypot(*incoming) * math.hypot(*outgoing)))
                    if joint not in vertices:
                        self.assertGreater(cosine, 0.999, f"joint at {joint} must be tangent")

    def test_overrun_is_measured_per_edge(self):
        radii, scale, excess = app_icons.continuous_corners(300, 100, (10, 50, 30, 0))
        k = app_icons.CONTINUOUS[0]
        self.assertEqual((radii, scale), ((50, 30, 0, 10), 1))
        self.assertEqual(app_icons.continuous_corners(100, 100, (80, 80, 0, 0))[:2], ((50, 0, 0, 50), 0.625))
        self.assertAlmostEqual(excess[0], k * 80 - 100)
        self.assertTrue(all(e < 0 for e in excess[1:]))
        self.assertEqual(app_icons.continuous_rect(0, 0, 300, 100, 80), app_icons.continuous_rect(0, 0, 300, 100, 50))
        for origin, size, radii in (((0, 0), (0, 10), 1), ((0, 0), (10, -1), 1), ((0, 0), (10, 10), -1),
                                    ((0, 0), (10, 10), float("nan")), ((0, 0), (10, 10), float("inf")),
                                    ((0, 0), (10, 10), True), ((0, 0), (10, 10), (1, 2, 3)), ((0, 0), (10, 10), "1"),
                                    ((float("nan"), 0), (10, 10), 1), ((0, float("inf")), (10, 10), 1),
                                    ((True, 0), (10, 10), 1), ((1e308, 0), (1e308, 10), 1)):
            with self.subTest(origin=origin, size=size, radii=radii), self.assertRaises(ValueError):
                app_icons.continuous_rect(*origin, *size, radii)

    def test_large_corners_consume_small_neighbours(self):
        k = app_icons.CONTINUOUS[0]
        cell = app_icons.continuous_rect(25, 25, 231, 231, (189, 30 / k, 0, 30 / k))
        segments = app_icons.path_segments(cell)[0][0]
        ends = [segment[2] for segment in segments]
        # The small corners leave only the points where they meet the inner edges.
        self.assertIn((256.0, 55.0), ends)
        self.assertIn((55.0, 256.0), ends)
        self.assertIn((256.0, 256.0), ends)
        sharp = app_icons.continuous_rect(0, 0, 231, 231, (189, 0, 0, 0))
        top = [s for s in app_icons.path_segments(sharp)[0][0] if s[2][0] == 231.0 and s[0][0] < 231.0]
        self.assertEqual(len(top), 1, "the corner meets the sharp corner's other edge, then follows it")
        self.assertLess(top[0][2][1], 1.0)
        for size, radii in (((100, 5), (0, 5, 0, 0)), ((5, 100), (0, 0, 5, 0)), ((100, 5), (0, 0, 0, 5)),
                            ((5, 100), (5, 0, 0, 0))):
            with self.subTest(size=size, radii=radii):
                straight = [segment for segment in path_cubics(app_icons.continuous_rect(0, 0, *size, radii))
                            if segment[0] == segment[1] and segment[2] == segment[3]]
                self.assertTrue(all(abs(a[0] - b[0]) < 0.02 or abs(a[1] - b[1]) < 0.02 for a, _, _, b in straight))
        random = __import__("random").Random(11)
        for _ in range(200):
            width, height = random.uniform(1, 600), random.uniform(1, 600)
            radii = tuple(random.choice((0, random.uniform(0, 20), random.uniform(0, 700))) for _ in range(4))
            with self.subTest(size=(width, height), radii=radii):
                path = app_icons.continuous_rect(0, 0, width, height, radii)
                self.assertEqual(app_icons.doubled_back(layer(path)), [])
                points = [app_icons.cubic_point(c, t / 20) for c in path_cubics(path) for t in range(20)]
                # Overlaps below OVERRUN are left uncut, so the outline may pass its box by that much.
                tolerance = app_icons.OVERRUN + 0.005
                self.assertTrue(all(-tolerance <= px <= width + tolerance and -tolerance <= py <= height + tolerance
                                    for px, py in points))
                turns = [(b[0] - a[0]) * (c[1] - b[1]) - (b[1] - a[1]) * (c[0] - b[0])
                         for a, b, c in zip(points, points[1:] + points[:1], points[2:] + points[:2])]
                self.assertGreaterEqual(min(turns), -0.05, "outline must stay convex")
                cubics = path_cubics(path)
                for start, _, _, end in (c for c in cubics if c[0] == c[1] and c[2] == c[3]):
                    self.assertTrue(abs(start[0] - end[0]) < 0.05 or abs(start[1] - end[1]) < 0.05,
                                    f"line {start}-{end} must follow an edge")
                for before, after in zip(cubics, cubics[1:] + cubics[:1]):
                    joint = before[3]
                    # Creases belong only where a corner meets a sharp neighbour's edge.
                    if min(abs(joint[0]), abs(joint[0] - width), abs(joint[1]), abs(joint[1] - height)) < 0.05:
                        continue
                    arrive = (before[3][0] - before[2][0], before[3][1] - before[2][1])
                    leave = (after[1][0] - after[0][0], after[1][1] - after[0][1])
                    if math.hypot(*arrive) > 1 and math.hypot(*leave) > 1:
                        self.assertGreater((arrive[0] * leave[0] + arrive[1] * leave[1]) /
                                           (math.hypot(*arrive) * math.hypot(*leave)), 0.995, f"kink at {joint}")

    def test_barely_overrunning_corners_stay_well_formed_at_any_scale(self):
        k = app_icons.CONTINUOUS[0]
        for x, side, radius in ((0, 100, (100 + 0.011) / (2 * k)), (0, 1e6, 327082.78468467586),
                                (5e6, 1000, (1000 + 0.02) / (2 * k)), (0, 1e308, 5e307)):
            with self.subTest(side=side, radius=radius):
                path = app_icons.continuous_rect(x, x, side, side, radius)
                self.assertNotRegex(path, "nan|inf")
                self.assertEqual(app_icons.doubled_back(layer(path)), [])
                for cubic in path_cubics(path):
                    for point in cubic:
                        self.assertTrue(all(x - 0.005 <= v <= x + side + 0.005 for v in point), point)

    def test_command_prints_path_and_notes(self):
        run = subprocess.run([sys.executable, str(SCRIPT), "--continuous-rect", "0", "0", "300", "100", "60"],
                             capture_output=True, text=True, env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"))
        self.assertEqual(run.returncode, 0, run.stderr)
        self.assertEqual(run.stdout, app_icons.continuous_rect(0, 0, 300, 100, 50) + "\n")
        self.assertEqual([line.split(":")[0] for line in run.stderr.splitlines()],
                         ["info\tradii scaled by 0.8333 so that each edge holds its two radii", "info\tright edge",
                          "info\tleft edge"])
        for args, code in ((["--continuous-rect", "0", "0", "3", "3"], 1), (["--list"], 2),
                           (["--continuous-rect", "nan", "0", "100", "100", "20"], 1),
                           (["design.md", "--continuous-rect", "0", "0", "3", "3", "1"], 2)):
            with self.subTest(args=args):
                run = subprocess.run([sys.executable, str(SCRIPT), *args], capture_output=True, text=True,
                                     env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"))
                self.assertEqual(run.returncode, code, run.stderr)


class GridBackdropTests(unittest.TestCase):
    def test_default_backdrop(self):
        svg = app_icons.grid_backdrop()
        app_icons.validate_svg(svg.encode())
        self.assertEqual(app_icons.doubled_back(svg), [])
        paths = re.findall(r'<path( fill-rule="evenodd")? d="([^"]+)"/>', svg)
        self.assertEqual(sum(bool(rule) for rule, _ in paths), 4)
        lines = [d for rule, d in paths if not rule]
        self.assertIn("M507 0H517V1024H507Z", lines)
        self.assertIn("M251 55H261V969H251Z", lines)
        self.assertIn("M55 763H969V773H55Z", lines)
        self.assertEqual(len(lines), 6)
        self.assertNotIn("opacity", svg)
        self.assertIn('<g fill="#FFFFFF" opacity="0.2">', app_icons.grid_backdrop(opacity=0.2))

    def test_corner_edge_peels_out_of_the_glass_rim(self):
        k = app_icons.CONTINUOUS[0]
        edge = path_cubics(app_icons.continuous_rect(25, 25, 231, 231, (189, 30 / k, 0, 30 / k)))
        l, c1, c2, d = (v * 1024 for v in app_icons.CORNER)
        rim = [app_icons.cubic_point(c, t / 400) for c in (((0, l), (0, c1), (0, c2), (d, d)),
                                                            ((d, d), (c2, 0), (c1, 0), (l, 0))) for t in range(401)]
        points = [app_icons.cubic_point(c, t / 200) for c in edge for t in range(201)]

        def gap(point):
            return min(math.dist(point, r) for r in rim)
        turn = min((p for p in points if 225 <= p[0] <= 227 and p[1] < 100), key=lambda p: p[1])
        diagonal = min(points, key=lambda p: abs(p[0] - p[1]) + p[0])
        self.assertGreater(gap(turn), 18)
        self.assertLess(gap(diagonal), 4)

    def test_corner_edges_are_nested_bands_for_any_accepted_override(self):
        def inside(point, polygon):
            crossings = 0
            for (x0, y0), (x1, y1) in zip(polygon, polygon[1:] + polygon[:1]):
                if (y0 > point[1]) != (y1 > point[1]):
                    crossings += point[0] < x0 + (point[1] - y0) * (x1 - x0) / (y1 - y0)
            return crossings % 2 == 1

        accepted = 0
        for radius in (60, 150, 189, 220, 250):
            for turn in (0, 8, 30, 60):
                for width in (4, 10, 20):
                    try:
                        svg = app_icons.grid_backdrop(width=width, radius=radius, turn=turn)
                    except ValueError:
                        continue
                    accepted += 1
                    for d in re.findall(r'fill-rule="evenodd" d="([^"]+)"', svg):
                        outer, inner = (path_cubics(sub) for sub in re.findall(r"M[^M]+", d))
                        polygon = [app_icons.cubic_point(c, t / 12) for c in outer for t in range(12)]
                        for point in (app_icons.cubic_point(c, t / 12) for c in inner for t in range(12)):
                            with self.subTest(radius=radius, turn=turn, width=width, point=point):
                                self.assertTrue(inside(point, polygon) or
                                                min(math.dist(point, q) for q in polygon) < 0.05)
        self.assertGreater(accepted, 20)
        svg = app_icons.grid_backdrop(lines=(198, 512, 826), width=4.2, inset=10, radius=129, turn=71)
        for d in re.findall(r'fill-rule="evenodd" d="([^"]+)"', svg):
            outer, inner = (path_cubics(sub) for sub in re.findall(r"M[^M]+", d))
            polygon = [app_icons.cubic_point(c, t / 12) for c in outer for t in range(12)]
            for point in (app_icons.cubic_point(c, t / 12) for c in inner for t in range(12)):
                self.assertTrue(inside(point, polygon) or min(math.dist(point, q) for q in polygon) < 0.05, point)
        with self.assertRaisesRegex(ValueError, "do not fit"):
            app_icons.grid_backdrop(radius=250, turn=8)

    def test_command_prints_backdrop_with_overrides(self):
        def run(*args):
            return subprocess.run([sys.executable, str(SCRIPT), "--grid-backdrop", *args], capture_output=True,
                                  text=True, env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"))
        result = run("opacity=0.2", "lines=200,512,824", "radius=150")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, app_icons.grid_backdrop(lines=(200, 512, 824), radius=150, opacity=0.2))
        for args in (["color=red"], ["opacity=0.2", "opacity=0.3"], ["radius=big"], ["inset=300"], ["opacity=0"],
                     ["lines=512"], ["width=200"]):
            with self.subTest(args=args):
                self.assertEqual(run(*args).returncode, 1)


class PathReversalTests(unittest.TestCase):
    def test_path_data_is_parsed_like_svg(self):
        square = [((10.0, 10.0), (80.0, 0.0), (90.0, 10.0), (80.0, 0.0)),
                  ((90.0, 10.0), (0.0, 80.0), (90.0, 90.0), (0.0, 80.0)),
                  ((90.0, 90.0), (-80.0, 0.0), (10.0, 90.0), (-80.0, 0.0)),
                  ((10.0, 90.0), (0.0, -80.0), (10.0, 10.0), (0.0, -80.0))]
        for data in ("M10 10H90V90H10Z", "m10 10h80v80h-80z", "M10,10 90,10 90,90 10,90z", "M10 10L90 10 90 90 10 90 10 10Z"):
            with self.subTest(data=data):
                self.assertEqual(app_icons.path_segments(data), [(square, True)])
        smooth = app_icons.path_segments("M0 0C10 0 20 10 20 20S30 40 40 40Q50 40 50 30T60 20")[0][0]
        self.assertEqual([s[1] for s in smooth], [(10.0, 0.0), (0.0, 10.0), (10.0, 0.0), (0.0, -10.0)])
        self.assertEqual(app_icons.path_segments("M0 0H10H5H20e")[0][0][-1][2], (5.0, 0.0))
        for invalid in ("L10 0", "M0 0,,10 0", "M0 0L,10 0", "M0 0L1e 0", "M\u00a00 0L1 1"):
            with self.subTest(data=invalid):
                self.assertEqual(app_icons.path_segments(invalid), [])
        line = [((0.0, 0.0), (10.0, 0.0), (10.0, 0.0), (10.0, 0.0))]
        for data, expected in (("M0 0H10L L-10 0", [(line, False)]), ("M0 0ZL10 0", [(line, False)]),
                               ("M0 0H10ZH10", [(line + [((10.0, 0.0), (-10.0, 0.0), (0.0, 0.0), (-10.0, 0.0))], True),
                                                (line, False)])):
            with self.subTest(data=data):
                self.assertEqual(app_icons.path_segments(data), expected)
        compact = app_icons.path_segments("M1.5.5-2-3e1a5 5 0 0110 0l4 0zM0 0 1 1 x 9 9")
        self.assertEqual(compact[0][0][0][2], (-2.0, -30.0))
        self.assertEqual(compact[0][0][1][1:4:2], (None, None))
        self.assertEqual(compact[0][0][2][0], (8.0, -30.0))
        self.assertEqual(len(compact), 2)
        self.assertEqual(compact[1], ([((0.0, 0.0), (1.0, 1.0), (1.0, 1.0), (1.0, 1.0))], False))

    def test_overrunning_corners_are_found_in_any_path(self):
        excess = 2 * app_icons.CONTINUOUS[0] * 40 - 100
        found = app_icons.doubled_back(layer(naive_continuous_square(0, 0, 100, 40), "M0 0H10V10H0Z"))
        self.assertEqual(len(found), 1)
        x, y, length = found[0]
        self.assertEqual((x, y), (100.0, 61.15))
        self.assertAlmostEqual(length, excess, delta=0.02)
        transformed = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><g transform="scale(2)">'
                       f'<path d="{naive_continuous_square(0, 0, 100, 40)}"/></g></svg>')
        self.assertEqual(app_icons.doubled_back(transformed), found)
        self.assertEqual(app_icons.doubled_back(layer("M0 0H10H5H20")), [(10.0, 0.0, 5.0)])
        for line in ("L20 10", "L20 15L20 10", "C20 17 20 13 20 10"):
            with self.subTest(line=line):
                self.assertEqual(app_icons.doubled_back(layer(f"M0 0C10 0 20 10 20 20{line}C20 20 30 30 40 30")),
                                 [(20.0, 20.0, 10.0)])
        heart = "M512 320C512 128 192 128 192 384C192 576 512 800 512 800C512 800 832 576 832 384C832 128 512 128 512 320Z"
        for clean in (naive_continuous_square(0, 0, 100, 30), "M0 0H10H9.6H20", "M0 0L10 0L5 0",
                      "M0 0A5 5 0 0 1 10 0L0 0", "M0 0H100V100H0Z", "M0 0ZL10 0", heart, "M0 0H10H5H20e",
                      "M0 0H10\u00a0H5H20", "M0 0C10 0 20 10 20 20C20 17 20 13 20 10",
                      app_icons.continuous_rect(0, 0, 100, 100, 40)):
            with self.subTest(path=clean):
                self.assertEqual(app_icons.doubled_back(layer(clean)), [])


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

    def test_lint_reports_corners_that_overrun_their_edge(self):
        (self.root / "glyph.svg").write_text(layer(naive_continuous_square(312, 312, 400, 160)).replace(
            "<path ", '<path fill="white" '))
        result = self.invoke("--lint", "--style", "flat")
        self.assertEqual(result.returncode, 1)
        self.assertIn("flat\tgroup 1: layer 1 path doubles back 89.2 units at (712.0, 556.6)", result.stdout)
        (self.root / "glyph.svg").write_text(layer(app_icons.continuous_rect(312, 312, 400, 400, 160)).replace(
            "<path ", '<path fill="white" '))
        result = self.invoke("--lint", "--style", "flat")
        self.assertEqual((result.returncode, result.stdout), (0, "clean\n"), result.stderr)


    def test_lint_reports_backdrop_texture_without_stray_segments(self):
        (self.root / "grid.svg").write_text(app_icons.grid_backdrop())
        spec = {"background": "#0A84FF", "groups": [
            {"name": "Grid", "specular": False, "shadow": {"kind": "none", "opacity": 0},
             "layers": [{"source": "grid.svg", "opacity": 0.2}]},
            {"name": "Panel", "layers": [{"source": "glyph.svg"}]}]}
        self.design.write_text("# Design\n\n## Iconography\n\n```json\n" +
                               json.dumps({"app_icons": {"example": spec}}) + "\n```\n")
        result = self.invoke("--lint")
        self.assertEqual(result.returncode, 1)
        for expected in ("Grid: 0.8% of the artwork falls outside the shape", "Grid: 1 shape(s) narrower than 1 px",
                         "Panel: lightness 1.00 is too close to Grid 1.00"):
            self.assertIn(expected, result.stdout)
        self.assertNotIn("doubles back", result.stdout)


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
            'shadow': ({'kind': 'unknown', 'opacity': 0.5}, {'kind': 'NONE', 'opacity': 0},
                       {'kind': [], 'opacity': 0}, {'kind': 'none'},
                       {'kind': 'neutral', 'opacity': True},
                       {'kind': 'none', 'opacity': 0, 'extra': 1}),
            'lighting': (True,), 'unknown': (0,),
        }.items():
            for value in values:
                with self.subTest(key=key, value=value), self.assertRaises(ValueError):
                    self.prepared(group={key: value})

    def test_chromatic_shadow_normalizes_without_mutating_input(self):
        for specialized in (False, True):
            for kind in ('chromatic', 'layer-color'):
                with self.subTest(specialized=specialized, kind=kind):
                    group = self.spec['groups'][0]
                    group['shadow'] = {'kind': kind, 'opacity': 0.5}
                    if specialized:
                        group['shadow-specializations'] = {
                            appearance: {'kind': kind, 'opacity': 0.3} for appearance in app_icons.APPEARANCES}
                    before = copy.deepcopy(self.spec)
                    native = app_icons.prepare(self.spec, self.root, 'liquid-glass')[0]['groups'][0]
                    expected = {'kind': 'layer-color', 'opacity': 0.5}
                    if specialized:
                        self.assertNotIn('shadow', native)
                        self.assertEqual(native['shadow-specializations'], [{'value': expected}] + [
                            {'appearance': appearance, 'value': {'kind': 'layer-color', 'opacity': 0.3}}
                            for appearance in app_icons.APPEARANCES.values()])
                    else:
                        self.assertEqual(native['shadow'], expected)
                    self.assertEqual(self.spec, before)

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

    def test_material_specialization_validation_and_serialization(self):
        cases = {
            'opacity': (1, 0.25, [True, -1, 2, '0.3', None, float('nan'), float('inf')]),
            'blend-mode': ('normal', 'screen', ['invalid', True, [], None]),
            'specular': (True, False, [0, 1, 'false', None]),
            'shadow': ({'kind': 'neutral', 'opacity': 0.5}, {'kind': 'layer-color', 'opacity': 0.3},
                       [{'kind': 'unknown', 'opacity': 0.5}, {'kind': 'none'}, {'kind': 'none', 'opacity': 2}]),
            'translucency': ({'enabled': True, 'value': 0.3}, {'enabled': False, 'value': 0},
                            [{'enabled': 1, 'value': 0.3}, {'enabled': True, 'value': -1}]),
            'blur-material': (0.5, 0.8, [-1, 2, True, '0.3', None]),
            'refractivity': ({'enabled': False, 'strength': 0, 'depth': 0},
                             {'enabled': True, 'strength': 0.4, 'depth': 0.1},
                             [{'enabled': True, 'strength': 0.4}, {'enabled': True, 'strength': 0.4, 'depth': 2}]),
        }
        self.assertEqual(set(cases), set(app_icons.GROUP_MATERIALS))
        for key, (base, override, bad_values) in cases.items():
            field = key + '-specializations'
            for owner in (('group', 'layer') if key == 'opacity' else ('group',)):
                for appearance, native_appearance in [('default', 'light'), ('dark', 'dark'), ('tinted', 'tinted')]:
                    with self.subTest(key=key, owner=owner, appearance=appearance):
                        group = self.prepared(**{owner: {key: base, field: {appearance: override}}})
                        native = group if owner == 'group' else group['layers'][0]
                        self.assertNotIn(key, native)
                        self.assertEqual(native[field], [{'value': base},
                                                        {'appearance': native_appearance, 'value': override}])
                        group = self.prepared(**{owner: {field: {appearance: override}}})
                        native = group if owner == 'group' else group['layers'][0]
                        self.assertEqual(native[field], [{'appearance': native_appearance, 'value': override}])
                invalid_maps = [None, [], {}, {'light': override}, {'base': override}, {'Dark': override},
                                {'clear': override}, {'dark': override, 'unknown': override}]
                invalid_maps += [{'dark': bad} for bad in bad_values]
                for value in invalid_maps:
                    with self.subTest(key=key, owner=owner, invalid=value), self.assertRaises(ValueError):
                        self.prepared(**{owner: {field: value}})
        for owner, field in [('layer', 'shadow-specializations'), ('group', 'fill-specializations'),
                             ('group', 'lighting-specializations'), ('layer', 'blend-mode-specializations')]:
            with self.subTest(owner=owner, field=field), self.assertRaises(ValueError):
                self.prepared(**{owner: {field: {'dark': 0}}})

    def test_opacity_override_diagnostic_names_its_owner(self):
        for owner in ('group', 'layer'):
            for appearance in app_icons.APPEARANCES:
                with self.subTest(owner=owner, appearance=appearance):
                    with self.assertRaises(ValueError) as raised:
                        self.prepared(**{owner: {'opacity-specializations': {appearance: True}}})
                    self.assertEqual(str(raised.exception),
                                     f'opacity-specializations.{appearance}: {owner} opacity must be a number from 0 to 1')

    def test_specialized_refraction_enables_native_feature(self):
        self.spec['groups'][0]['refractivity-specializations'] = {
            'dark': {'enabled': True, 'strength': 0.4, 'depth': 0.1}}
        doc = app_icons.prepare(self.spec, self.root, 'liquid-glass')[0]
        self.assertEqual(doc['features'], ['refractivity'])

    def test_web_dark_is_an_explicit_entry_boolean(self):
        for value in (0, 1, 'true', None, [], {}):
            with self.subTest(value=value), self.assertRaisesRegex(ValueError, 'web_dark'):
                app_icons.prepare({**self.spec, 'web_dark': value}, self.root, 'liquid-glass')
        for value in (True, False):
            self.assertEqual(app_icons.prepare({**self.spec, 'web_dark': value}, self.root, 'liquid-glass'),
                             app_icons.prepare(self.spec, self.root, 'liquid-glass'))

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
        enriched['web_dark'] = True
        for group in enriched['groups']:
            group.update({'blend-mode': 'multiply', 'specular': False, 'opacity': 0.1,
                          'shadow': {'kind': 'layer-color', 'opacity': 0.9},
                          'refractivity': {'enabled': True, 'strength': 0.8, 'depth': 0.2},
                          'blur-material': 0.7, 'translucency': {'enabled': True, 'value': 0.8}})
            group['layers'][0].update({'fill': {'automatic-gradient': '#FF000080'}, 'opacity': 0.2,
                                      'fill-specializations': {'dark': {'solid': '#00FF00'}},
                                      'opacity-specializations': {'dark': 0.5}})
            for key in app_icons.GROUP_MATERIALS:
                group[key + '-specializations'] = {'dark': group[key]}
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

    def test_chromatic_shadow_renders_as_layer_color(self):
        alias = copy.deepcopy(self.spec)
        alias['groups'][0]['shadow'] = {'kind': 'chromatic', 'opacity': 0.5}
        native = copy.deepcopy(alias)
        native['groups'][0]['shadow']['kind'] = 'layer-color'
        for generation in app_icons.GENERATIONS:
            for rendition in app_icons.RENDITIONS:
                with self.subTest(generation=generation, rendition=rendition):
                    self.assertLessEqual(self.delta(self.render(alias, rendition, generation),
                                                    self.render(native, rendition, generation)), app_icons.PNG_TOLERANCE)

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

    def test_material_overrides_affect_only_their_appearance_family(self):
        (self.root / 'back.svg').write_text(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">'
            '<path fill="#FF5020" d="M280 100H480V900H280Z"/>'
            '<path fill="#1060FF" d="M500 100H700V900H500Z"/></svg>')
        self.spec['groups'].insert(0, {'layers': [{'source': 'back.svg'}]})
        cases = [
            ('group', 'opacity', 1, 0.2), ('layer', 'opacity', 1, 0.2),
            ('group', 'blend-mode', 'normal', 'multiply'), ('group', 'specular', True, False),
            ('group', 'shadow', {'kind': 'neutral', 'opacity': 0.8}, {'kind': 'none', 'opacity': 0}),
            ('group', 'translucency', {'enabled': True, 'value': 0.1}, {'enabled': True, 'value': 0.8}),
            ('group', 'blur-material', 0, 0.9),
            ('group', 'refractivity', {'enabled': True, 'strength': 0, 'depth': 0.1},
             {'enabled': True, 'strength': 0.8, 'depth': 0.6})]
        for generation in app_icons.GENERATIONS:
            for owner, key, initial, value in cases:
                base = copy.deepcopy(self.spec)
                group = base['groups'][1]
                target = group if owner == 'group' else group['layers'][0]
                target[key] = initial
                controls = {r: self.render(base, r, generation) for r in app_icons.RENDITIONS}
                for appearance, affected in {'default': {'Default'}, 'dark': {'Dark'},
                                             'tinted': {'ClearLight', 'ClearDark', 'TintedLight', 'TintedDark'}}.items():
                    # Generation 26 ignores this refraction model in both encodings.
                    if generation == 26 and key == 'refractivity':
                        affected = set()
                    spec = copy.deepcopy(base)
                    group = spec['groups'][1]
                    target = group if owner == 'group' else group['layers'][0]
                    target[key + '-specializations'] = {appearance: value}
                    deltas = {}
                    for rendition, control in controls.items():
                        with self.subTest(generation=generation, owner=owner, key=key,
                                          appearance=appearance, rendition=rendition):
                            difference = self.delta(control, self.render(spec, rendition, generation))
                            deltas[rendition] = difference
                            if generation == 26 and key == 'refractivity' and appearance == 'default':
                                scalar = copy.deepcopy(base)
                                scalar['groups'][1][key] = value
                                self.assertLessEqual(self.delta(control, self.render(scalar, rendition, generation)),
                                                     app_icons.PNG_TOLERANCE)
                            if rendition in affected:
                                self.assertGreater(difference, app_icons.PNG_TOLERANCE)
                            else:
                                self.assertLessEqual(difference, app_icons.PNG_TOLERANCE)
                    print(f'appearance\t{generation}\t{owner}.{key}\t{appearance}\t{deltas}', flush=True)

    def test_opacity_override_without_base_uses_native_default(self):
        for owner in ('group', 'layer'):
            spec = copy.deepcopy(self.spec)
            group = spec['groups'][0]
            target = group if owner == 'group' else group['layers'][0]
            target['opacity-specializations'] = {'dark': 0.25}
            for rendition in app_icons.RENDITIONS:
                with self.subTest(owner=owner, rendition=rendition):
                    difference = self.delta(self.render(self.spec, rendition), self.render(spec, rendition))
                    if rendition == 'Dark':
                        self.assertGreater(difference, app_icons.PNG_TOLERANCE)
                    else:
                        self.assertLessEqual(difference, app_icons.PNG_TOLERANCE)

    @unittest.skipUnless(shutil.which('rsvg-convert'), 'rsvg-convert scales native web exports')
    def test_dark_web_set_comes_from_native_dark_and_is_opt_in(self):
        self.spec['groups'][0]['layers'][0].update({
            'fill': {'solid': '#00FF00'}, 'fill-specializations': {'dark': {'solid': '#FF0000'}}})
        out = self.root / 'dark-output'
        app_icons.build('example', {**self.spec, 'web_dark': True}, self.root, out, ictool=self.tool)
        dark = out / 'web/dark'
        self.assertEqual({p.name for p in dark.iterdir()}, {name for name, _ in app_icons.MASKED_WEB_SIZES})
        manifest = json.loads((out / 'manifest.json').read_text())
        for name, size in app_icons.MASKED_WEB_SIZES:
            app_icons.png_payload(dark / name, size)
            expected = self.root / name
            app_icons.resize_png(out / 'renditions/iOS-Dark.png', expected, size)
            self.assertEqual(expected.read_bytes(), (dark / name).read_bytes())
            self.assertNotEqual(app_icons.png_payload(dark / name), app_icons.png_payload(out / 'web' / name))
            self.assertIn('web/dark/' + name, manifest['files'])
        # Reuse the actual native exports to isolate opt-in behavior from GPU rounding.
        original_run = app_icons.run
        def replay(args):
            if '--export-image' in args:
                output = Path(args[args.index('--output-file') + 1])
                output.write_bytes((out / 'renditions' / output.name).read_bytes())
                return ''
            return original_run(args)
        with patch.object(app_icons, 'run', side_effect=replay):
            for label, spec in [('off', {**self.spec, 'web_dark': False}), ('omitted', self.spec)]:
                app_icons.build('example', spec, self.root, self.root / label, ictool=self.tool)
        off = tree_bytes(self.root / 'off')
        self.assertEqual(off, tree_bytes(self.root / 'omitted'))
        self.assertFalse((self.root / 'off/web/dark').exists())
        for name, data in off.items():
            if name != 'manifest.json':
                self.assertEqual(data, (out / name).read_bytes(), name)
@unittest.skipUnless(os.environ.get('APP_ICONS_BASELINE'), 'set APP_ICONS_BASELINE to the pre-change script')
@unittest.skipUnless(shutil.which('rsvg-convert'), 'rsvg-convert renders the examples')
class BaselineRenderingTests(unittest.TestCase):
    def test_chromatic_shadow_preserves_baseline_style_bytes(self):
        module = importlib.util.spec_from_file_location('baseline_icons', os.environ['APP_ICONS_BASELINE'])
        baseline = importlib.util.module_from_spec(module)
        module.loader.exec_module(baseline)
        spec = {'background': '#123456', 'groups': [{'layers': [{'source': 'glyph.svg'}],
                'shadow': {'kind': 'chromatic', 'opacity': 0.5}}],
                'styles': {style: {} for style in app_icons.STYLES}}
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / 'glyph.svg').write_text(SVG)
            for style in app_icons.STYLES:
                with self.subTest(style=style):
                    old_doc, old_assets, old_art, _ = baseline.prepare(spec, root, style)
                    new_doc, new_assets, new_art, _ = app_icons.prepare(spec, root, style)
                    old_doc = copy.deepcopy(old_doc)
                    self.assertEqual(old_doc['groups'][0]['shadow']['kind'], 'chromatic')
                    old_doc['groups'][0]['shadow']['kind'] = 'layer-color'
                    self.assertEqual(new_doc, old_doc)
                    self.assertEqual(new_assets, old_assets)
                    for masked, scale in ((True, 1), (False, 1), (False, 0.56)):
                        self.assertEqual(baseline.compose(style, spec, old_art, masked=masked, scale=scale),
                                         app_icons.compose(style, spec, new_art, masked=masked, scale=scale))
                    if style == 'liquid-glass':
                        print('baseline-chromatic\tliquid-glass\tartwork compositions and assets byte-identical; '
                              'native shadow normalized to layer-color', flush=True)
                        continue
                    outputs = [root / (style + suffix) for suffix in ('-baseline', '-current')]
                    baseline.build('example', spec, root, outputs[0], style)
                    app_icons.build('example', spec, root, outputs[1], style)
                    self.assertEqual(tree_bytes(outputs[0]), tree_bytes(outputs[1]))
                    print(f'baseline-chromatic\t{style}\t{len(tree_bytes(outputs[0]))} files byte-identical', flush=True)
            spec['styles'].pop('liquid-glass')
            sheets = []
            for name, producer in [('baseline', baseline), ('current', app_icons)]:
                work = root / name
                work.mkdir()
                sheets.append(producer.sheet({'example': spec}, ['example'], root, None, work))
            self.assertEqual(*sheets)

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
                                disabled = Path(temp) / f'{design.stem}-{name}-{style}-disabled'
                                with patch.object(app_icons, 'run', side_effect=replay_native):
                                    app_icons.build(name, {**spec, 'web_dark': False}, design.parent, disabled, style, tool)
                                self.assertEqual(after, tree_bytes(disabled))
                                print(f'baseline-option-off\t{name}\t{style}\t{len(after)} files byte-identical', flush=True)
                            self.assertEqual([key for key in before if before[key] != after[key]], [])
                            print(f'baseline-producer\t{name}\t{style}\t{len(before)} files byte-identical', flush=True)


if __name__ == "__main__":
    unittest.main()
