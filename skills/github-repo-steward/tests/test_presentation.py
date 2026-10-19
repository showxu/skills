"""Regression checks for layout bounds, recorded output and stale design inputs."""

import base64
import hashlib
from io import BytesIO
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
from xml.etree import ElementTree as ET

from PIL import Image, PngImagePlugin

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import render_social
from presentation import load_spec, sha256, write_or_check
from render_social import fit_title, icon_svg, wrap_about
from render_terminal import cells, render

OUTPUT = Path(os.environ["REPO_STEWARD_TEST_OUTPUT"])
OUTPUT.mkdir(parents=True, exist_ok=True)


class SocialIconTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=OUTPUT)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def image_data(self, format="PNG", dimensions=(384, 384), **options):
        buffer = BytesIO()
        mode = "RGBA" if format in {"PNG", "WEBP"} else "RGB"
        Image.new(mode, dimensions, "#2468ac80" if mode == "RGBA" else "#2468ac").save(
            buffer, format=format, **options)
        return buffer.getvalue()

    def svg_icon(self, content):
        path = self.root / "icon.svg"
        path.write_text('<svg xmlns="http://www.w3.org/2000/svg" '
                        'xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 100 100">'
                        + content + '</svg>')
        return path

    def test_raster_icons_embed_exact_bytes_at_the_svg_position_and_size(self):
        metadata = PngImagePlugin.PngInfo()
        metadata.add_text("identity", "fixture artwork")
        for format, mime in (("PNG", "image/png"), ("JPEG", "image/jpeg"), ("WEBP", "image/webp")):
            with self.subTest(format=format):
                path = self.root / ("icon." + format.lower())
                data = self.image_data(format, **({"pnginfo": metadata} if format == "PNG" else {}))
                path.write_bytes(data)
                image = ET.fromstring(icon_svg(path, 64, 128, 384))
                self.assertEqual(image.tag, "image")
                self.assertEqual([image.get(key) for key in ("x", "y", "width", "height")],
                                 ["64", "128", "384", "384"])
                prefix, payload = image.get("href").split(",", 1)
                self.assertEqual(prefix, f"data:{mime};base64")
                self.assertEqual(base64.b64decode(payload, validate=True), data)

    def test_svg_images_accept_supported_raster_data_with_either_href(self):
        for format, mime in (("PNG", "image/png"), ("JPEG", "image/jpeg"), ("WEBP", "image/webp")):
            for attribute in ("href", "xlink:href"):
                with self.subTest(format=format, attribute=attribute):
                    payload = base64.b64encode(self.image_data(format, (16, 8))).decode("ascii")
                    uri = f"data:{mime};base64,{payload}"
                    path = self.svg_icon(f'<image {attribute}="{uri}" width="100" height="100"/>')
                    svg = ET.fromstring(icon_svg(path, 64, 128, 384))
                    self.assertIn(uri, list(svg)[0].attrib.values())
                    self.assertEqual([svg.get(key) for key in ("x", "y", "width", "height")],
                                     ["64", "128", "384", "384"])

    def test_svg_fragment_references_remain_supported(self):
        path = self.svg_icon('<defs><path id="shape" d="M0 0h100v100z"/></defs><use href="#shape"/>')
        self.assertIn('href="#shape"', icon_svg(path, 0, 0, 384))

    def test_svg_rejects_other_nonfragment_references(self):
        references = ["https://example.test/icon.png", "file:///tmp/icon.png", "icon.png",
                      "//example.test/icon.png", "data:image/svg+xml;base64,PHN2Zy8+",
                      "data:image/gif;base64,R0lGODlh", "data:text/plain;base64,YQ==",
                      "data:image/png,%89PNG"]
        for attribute in ("href", "xlink:href"):
            for value in references:
                with self.subTest(attribute=attribute, reference=value):
                    path = self.svg_icon(f'<image {attribute}="{value}"/>')
                    with self.assertRaisesRegex(ValueError, "self-contained"):
                        icon_svg(path, 0, 0, 384)
        payload = base64.b64encode(self.image_data()).decode("ascii")
        path = self.svg_icon(f'<use href="data:image/png;base64,{payload}"/>')
        with self.assertRaisesRegex(ValueError, "self-contained"):
            icon_svg(path, 0, 0, 384)

    def test_svg_rejects_invalid_or_mislabeled_embedded_rasters(self):
        png = base64.b64encode(self.image_data()).decode("ascii")
        for uri, message in (("data:image/png;base64,not!base64", "valid base64"),
                             ("data:image/png;base64,PHN2Zy8+", "valid PNG, JPEG or WebP"),
                             (f"data:image/jpeg;base64,{png}", "match its data URI")):
            with self.subTest(uri=uri[:40]):
                path = self.svg_icon(f'<image href="{uri}"/>')
                with self.assertRaisesRegex(ValueError, message):
                    icon_svg(path, 0, 0, 384)

    def test_svg_active_content_and_live_text_remain_rejected(self):
        for content in ('<script/>', '<foreignObject/>', '<text>Logo</text>',
                        '<path onload="alert(1)"/>', '<image onerror="alert(1)"/>'):
            with self.subTest(content=content):
                with self.assertRaisesRegex(ValueError, "static SVG|self-contained"):
                    icon_svg(self.svg_icon(content), 0, 0, 384)

    def test_raster_icons_must_be_square(self):
        path = self.root / "icon.png"
        path.write_bytes(self.image_data(dimensions=(384, 512)))
        with self.assertRaisesRegex(ValueError, "square.*384x512"):
            icon_svg(path, 0, 0, 384)

    def test_raster_minimum_follows_the_rendered_icon_size(self):
        path = self.root / "icon.png"
        path.write_bytes(self.image_data(dimensions=(256, 256)))
        icon_svg(path, 0, 0, 256)
        for size in (256.5, 384):
            with self.subTest(size=size):
                with self.assertRaisesRegex(ValueError, f"at least {size:g}x{size:g}.*256x256"):
                    icon_svg(path, 0, 0, size)

    def test_raster_icons_reject_unsupported_or_invalid_formats(self):
        path = self.root / "icon.png"
        for data in (self.image_data("GIF"), b"not an image", self.image_data()[:50]):
            with self.subTest(data=data[:20]):
                path.write_bytes(data)
                with self.assertRaisesRegex(ValueError, "valid PNG, JPEG or WebP"):
                    icon_svg(path, 0, 0, 384)

    def test_recipe_check_preserves_outputs_and_detects_raster_byte_drift(self):
        icon = self.root / "icon.png"
        icon.write_bytes(self.image_data())
        for name in ("title.ttf", "body.ttf", "LICENSE.txt"):
            (self.root / name).write_text("synthetic font receipt")
        spec = self.root / "recipe.json"
        spec.write_text(json.dumps({"owner": "example-owner", "title": "example-app",
                                    "about": "Inspect your data before shipping it.", "icon": icon.name,
                                    "font_title": "title.ttf", "font_body": "body.ttf",
                                    "font_license": "LICENSE.txt"}))
        output = self.root / "card.svg"
        receipt = output.with_suffix(".layout.json")
        args = ["render_social.py", "--spec", str(spec), "--output", str(output)]
        with patch.object(render_social, "Face") as face:
            face.return_value.width.side_effect = lambda text, size: len(text) * size * .5
            face.return_value.outline.return_value = "<path/>"
            with patch.object(sys, "argv", args):
                render_social.main()
                original = [path.read_bytes() for path in (output, receipt)]
                render_social.main()
                self.assertEqual([path.read_bytes() for path in (output, receipt)], original)
            self.assertEqual(json.loads(receipt.read_text())["inputs"]["icon"],
                             hashlib.sha256(icon.read_bytes()).hexdigest())
            image = ET.fromstring(output.read_text()).find("{http://www.w3.org/2000/svg}image")
            self.assertEqual([image.get(key) for key in ("x", "y", "width", "height")],
                             ["64.0", "128.0", "384.0", "384.0"])
            modified = [path.stat().st_mtime_ns for path in (output, receipt)]
            with patch.object(sys, "argv", args + ["--check"]):
                render_social.main()
                render_social.main()
                metadata = PngImagePlugin.PngInfo()
                metadata.add_text("identity", "same pixels, changed bytes")
                icon.write_bytes(self.image_data(pnginfo=metadata))
                with self.assertRaisesRegex(ValueError, "card.svg differs"):
                    render_social.main()
                self.assertEqual([path.read_bytes() for path in (output, receipt)], original)
                self.assertEqual([path.stat().st_mtime_ns for path in (output, receipt)], modified)
                icon.write_bytes(self.image_data())
                receipt.write_text("{}")
                with self.assertRaisesRegex(ValueError, "card.layout.json differs"):
                    render_social.main()
                self.assertEqual(receipt.read_text(), "{}")
                icon.write_bytes(self.image_data(dimensions=(383, 383)))
                with self.assertRaisesRegex(ValueError, "at least 384x384.*383x383"):
                    render_social.main()


class PresentationTests(unittest.TestCase):
    def test_long_title_shrinks_before_wrapping(self):
        title = "sample-appstoreconnect"
        lines, size = fit_title(title, lambda text, size: len(text) * size * .55, 704)
        self.assertEqual(lines, [title])
        self.assertGreaterEqual(size, 40)
        self.assertLess(size, 72)

    def test_separator_runs_do_not_leave_a_dangling_hyphen(self):
        lines, size = fit_title("sample-/appstoreconnect", lambda text, size: len(text) * size, 90, 10, 5)
        self.assertEqual(lines, ["sample", "appstoreconnect"])
        self.assertGreaterEqual(size, 5)

    def test_wrapped_title_chooses_balanced_boundary(self):
        title = "alpha-beta-gamma-delta"
        lines, _ = fit_title(title, lambda text, size: len(text) * size, 60, 8, 5)
        self.assertEqual(lines, ["alpha-beta", "gamma-delta"])

    def test_unbreakable_overflow_fails_instead_of_clipping(self):
        with self.assertRaisesRegex(ValueError, "cannot fit"):
            fit_title("unbreakable", lambda text, size: len(text) * size, 20, 20, 10)

    def test_about_keeps_every_word_at_fixed_size(self):
        seen = []
        def measure(text, size):
            seen.append(size)
            return len(text) * 10
        value = "Read each complete result before publishing."
        lines = wrap_about(value, measure, 180)
        self.assertEqual(" ".join(lines), value)
        self.assertLessEqual(len(lines), 3)
        self.assertEqual(set(seen), {32})
        with self.assertRaisesRegex(ValueError, "at most three"):
            wrap_about(value * 4, measure, 180)

    def test_stale_design_binding_is_rejected(self):
        with tempfile.TemporaryDirectory(dir=OUTPUT) as folder:
            root = Path(folder)
            design = root / "DESIGN.md"
            design.write_text("accepted tokens")
            recipe = root / "recipe.json"
            recipe.write_text(json.dumps({"design_source": "DESIGN.md", "design_sha256": sha256(design)}))
            load_spec(recipe)
            design.write_text("new tokens")
            with self.assertRaisesRegex(ValueError, "stale"):
                load_spec(recipe)

    def test_icon_lettering_cannot_reintroduce_font_lookup(self):
        with tempfile.TemporaryDirectory(dir=OUTPUT) as folder:
            icon = Path(folder) / "icon.svg"
            icon.write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><text>Logo</text></svg>')
            with self.assertRaisesRegex(ValueError, "outlined lettering"):
                icon_svg(icon, 0, 0, 100)

    def test_check_reports_drift_without_overwriting(self):
        with tempfile.TemporaryDirectory(dir=OUTPUT) as folder:
            path = Path(folder) / "demo.svg"
            path.write_text("accepted")
            with self.assertRaisesRegex(ValueError, "differs"):
                write_or_check(path, "changed", True)
            self.assertEqual(path.read_text(), "accepted")

    def test_terminal_themes_preserve_real_command_and_output(self):
        record = {"title": "Inspect data", "commands": [{"command": "tool query '<item>'", "stdout": "ready & complete", "exit_code": 0}]}
        light = render(record, {}, "light")
        dark = render(record, {}, "dark")
        self.assertNotEqual(light, dark)
        text = "".join(ET.fromstring(light).itertext())
        self.assertIn(record["commands"][0]["command"], text)
        self.assertIn(record["commands"][0]["stdout"], text)
        self.assertEqual(cells("結果"), 4)

    def test_terminal_rejects_fabricated_success_and_control_sequences(self):
        record = {"title": "Inspect", "commands": [{"command": "tool", "stdout": "failure", "exit_code": 1}]}
        with self.assertRaisesRegex(ValueError, "successful"):
            render(record, {}, "dark")
        record["commands"][0].update(exit_code=0, stdout="\x1b[31mred")
        with self.assertRaisesRegex(ValueError, "control"):
            render(record, {}, "dark")


if __name__ == "__main__":
    unittest.main()
