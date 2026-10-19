"""Regression checks for layout bounds, recorded output and stale design inputs."""

import base64
import hashlib
from html import escape
from io import BytesIO
import json
import os
from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest.mock import patch
from xml.etree import ElementTree as ET
import zlib

from PIL import Image, PngImagePlugin

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import render_social
from presentation import load_spec, sha256, write_or_check
from render_social import fit_title, icon_svg, wrap_about
from render_terminal import cells, render

OUTPUT = Path(os.environ["README_DESIGN_TEST_OUTPUT"])
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

    def test_nested_svg_rejects_style_elements_and_attributes(self):
        styles = ['@import url(https://example.test/theme.css);',
                  '@import "theme.css";', 'fill: url(https://example.test/paint.svg#paint)',
                  '.logo { fill: #2468ac; }', 'fill: #2468ac']
        for style in styles:
            for content in (f'<style><![CDATA[{style}]]></style>',
                            f'<path style="{escape(style, quote=True)}"/>'):
                with self.subTest(content=content):
                    path = self.svg_icon(f'<svg viewBox="0 0 100 100">{content}</svg>')
                    with self.assertRaisesRegex(ValueError, "self-contained"):
                        icon_svg(path, 0, 0, 384)

    def test_nested_svg_rejects_external_presentation_urls(self):
        for attribute in ("fill", "stroke", "filter", "clip-path", "mask", "marker",
                          "marker-start", "marker-mid", "marker-end", "cursor"):
            with self.subTest(attribute=attribute):
                path = self.svg_icon('<svg viewBox="0 0 100 100">'
                                     f'<path {attribute}="url(https://example.test/asset.svg#part)"/></svg>')
                with self.assertRaisesRegex(ValueError, "self-contained"):
                    icon_svg(path, 0, 0, 384)

    def test_nested_svg_rejects_animation_elements(self):
        for content in ('<set attributeName="href" to="https://example.test/icon.svg"/>',
                        '<animate attributeName="xlink:href" values="#one;#two"/>',
                        '<animate attributeName="opacity" from="0.5" to="1"/>'):
            with self.subTest(content=content):
                with self.assertRaisesRegex(ValueError, "element .* is not allowed"):
                    icon_svg(self.svg_icon(f'<svg>{content}</svg>'), 0, 0, 384)

    def test_nested_svg_rejects_external_base_and_source_attributes(self):
        for attribute in ("xml:base", "src"):
            with self.subTest(attribute=attribute):
                path = self.svg_icon(f'<svg {attribute}="https://example.test/asset.svg">'
                                     '<use href="#local"/></svg>')
                with self.assertRaisesRegex(ValueError, "self-contained"):
                    icon_svg(path, 0, 0, 384)

    def test_raster_data_uris_are_only_allowed_in_image_href(self):
        uri = 'data:image/png;base64,' + base64.b64encode(self.image_data()).decode("ascii")
        for content in (f'<style>.logo {{ fill: url({uri}); }}</style>',
                        f'<path style="fill: url({uri})"/>', f'<path fill="url({uri})"/>',
                        f'<image src="{uri}"/>'):
            with self.subTest(content=content[:60]):
                with self.assertRaisesRegex(ValueError, "self-contained"):
                    icon_svg(self.svg_icon(f'<svg>{content}</svg>'), 0, 0, 384)

    def test_nested_svg_preserves_fragment_presentation_references(self):
        content = ('<svg viewBox="0 0 100 100"><defs><linearGradient id="paint"/></defs>'
                   '<path class="logo" fill="url(#paint)" stroke="url(\'#paint\')" '
                   r'filter="u\72l(\23 filter)" transform="translate(10 20) scale(2)"/></svg>')
        svg = ET.fromstring(icon_svg(self.svg_icon(content), 0, 0, 384))
        path = svg.find('.//{http://www.w3.org/2000/svg}path')
        self.assertEqual(path.get("fill"), "url(#paint)")
        self.assertEqual(path.get("stroke"), "url('#paint')")
        self.assertEqual(path.get("class"), "logo")

    def test_nested_svg_rejects_foreign_namespaces(self):
        for content in ('<iframe xmlns="http://www.w3.org/1999/xhtml" '
                        'srcdoc="&lt;script&gt;alert(1)&lt;/script&gt;"/>',
                        '<img xmlns="http://www.w3.org/1999/xhtml" '
                        'srcset="https://example.invalid/icon.png 1x"/>',
                        '<math xmlns="http://www.w3.org/1998/Math/MathML"><mi>x</mi></math>',
                        '<path xmlns="urn:unknown" d="M0 0h100v100z"/>',
                        '<path xmlns="" d="M0 0h100v100z"/>'):
            for wrapper in ('{}', '<svg><defs><g>{}</g></defs></svg>'):
                with self.subTest(content=content, wrapper=wrapper):
                    with self.assertRaisesRegex(ValueError, "SVG namespace"):
                        icon_svg(self.svg_icon(wrapper.format(content)), 0, 0, 384)

    def test_svg_rejects_elements_outside_the_allowlist(self):
        for tag in ("unknown", "feImage", "feTurbulence", "a", "iframe", "img", "style", "text"):
            with self.subTest(tag=tag):
                with self.assertRaisesRegex(ValueError, "element .* is not allowed"):
                    icon_svg(self.svg_icon(f'<svg><g><{tag}/></g></svg>'), 0, 0, 384)

    def test_svg_drops_metadata_contents(self):
        path = self.svg_icon('<metadata id="receipt">private text'
                             '<iframe xmlns="http://www.w3.org/1999/xhtml" srcdoc="active"/>'
                             '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'
                             '<script xmlns="http://www.w3.org/2000/svg"/></rdf:RDF></metadata>'
                             '<path d="M0 0h100v100z" fill="red"/>')
        svg = ET.fromstring(icon_svg(path, 0, 0, 384))
        metadata = svg.find('{http://www.w3.org/2000/svg}metadata')
        self.assertEqual(metadata.get("id"), "receipt")
        self.assertEqual(list(metadata), [])
        self.assertIsNone(metadata.text)
        self.assertEqual(len(list(svg)), 2)
        self.assertNotIn("active", ET.tostring(svg, encoding="unicode"))

    def test_svg_accepts_composed_geometry_and_filter_inputs(self):
        path = self.svg_icon('''
          <title>Outlined logo</title><desc>A composed vector icon</desc>
          <defs>
            <linearGradient id="paint" gradientUnits="userSpaceOnUse" x1="0" x2="100">
              <stop offset="0" stop-color="rgb(30, 100, 200)"/><stop offset="1" stop-color="blue"/>
            </linearGradient>
            <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="1" stop-opacity="0"/></radialGradient>
            <clipPath id="clip" clipPathUnits="userSpaceOnUse"><circle cx="50" cy="50" r="45"/></clipPath>
            <mask id="mask" maskUnits="userSpaceOnUse"><rect width="100" height="100" fill="white"/></mask>
            <pattern id="pattern" width="10" height="10" patternUnits="userSpaceOnUse">
              <ellipse cx="5" cy="5" rx="2" ry="3"/>
            </pattern>
            <symbol id="shape" viewBox="0 0 100 100">
              <line x1="10" y1="10" x2="90" y2="90"/>
              <polyline points="10,10 50,90 90,10"/><polygon points="10,90 50,10 90,90"/>
            </symbol>
            <filter id="effect" filterUnits="userSpaceOnUse" primitiveUnits="userSpaceOnUse">
              <feGaussianBlur in="SourceGraphic" stdDeviation="1" result="blur"/>
              <feOffset in="blur" dx="1" dy="2" result="offset"/>
              <feBlend in="SourceGraphic" in2="offset" mode="normal"/>
              <feColorMatrix type="saturate" values="0.8"/>
              <feComposite in2="SourceAlpha" operator="in"/>
              <feFlood flood-color="blue" flood-opacity="0.1" result="flood"/>
              <feMerge><feMergeNode in="flood"/><feMergeNode in="SourceGraphic"/></feMerge>
              <feMorphology operator="dilate" radius="1"/>
              <feDropShadow dx="1" dy="1" stdDeviation="1"/>
              <feComponentTransfer>
                <feFuncR type="gamma" amplitude="1" exponent="1" offset="0"/>
                <feFuncG type="linear" slope="1" intercept="0"/>
                <feFuncB type="table" tableValues="0 1"/><feFuncA type="identity"/>
              </feComponentTransfer>
            </filter>
          </defs>
          <g id="logo" class="logo" fill="url(#paint)" clip-path="url(#clip)" mask="url(#mask)">
            <use href="#shape" width="100" height="100" filter="url(#effect)"/>
          </g>''')
        result = ET.fromstring(icon_svg(path, 0, 0, 384))
        self.assertIsNotNone(result.find('.//{http://www.w3.org/2000/svg}feComponentTransfer'))
        self.assertEqual(result.find('.//{http://www.w3.org/2000/svg}use').get("href"), "#shape")

    def test_svg_rejects_attributes_outside_the_allowlist(self):
        for attribute in ('unknown="value"', 'srcdoc="active"', 'srcset="image.png 1x"',
                          'style="fill:red"', 'onload="alert(1)"',
                          'xml:base="https://example.test/"',
                          'xmlns:custom="urn:custom" custom:fill="red"',
                          'xmlns:custom="urn:custom" custom:href="#local"'):
            with self.subTest(attribute=attribute):
                with self.assertRaisesRegex(ValueError, "attribute .* is not allowed"):
                    icon_svg(self.svg_icon(f'<svg><path {attribute}/></svg>'), 0, 0, 384)

    def test_svg_limits_href_by_element(self):
        for content in ('<image href="#local"/>', '<path href="#local"/>',
                        '<linearGradient xlink:href="#base"/>', '<use href="other.svg#local"/>'):
            with self.subTest(content=content):
                with self.assertRaisesRegex(ValueError, "self-contained"):
                    icon_svg(self.svg_icon(content), 0, 0, 384)

    def test_svg_rejects_escaped_external_urls_and_unlisted_value_functions(self):
        for value in (r'u\72l(\68ttps://example.test/icon.svg#paint)',
                      'URL("https://example.test/icon.svg#paint")', 'url(#local) url(../paint.svg)',
                      'url("https://example.test/icon.svg")', 'url(not a URL)',
                      '"url(https://example.test/icon.svg)"',
                      'image-set("https://example.test/icon.png" 1x)', 'unknown(#local)'):
            with self.subTest(value=value):
                with self.assertRaisesRegex(ValueError, "self-contained"):
                    icon_svg(self.svg_icon(f'<path fill="{escape(value, quote=True)}"/>'), 0, 0, 384)

    def test_svg_rejects_doctype_entities_and_processing_instructions(self):
        sources = ('<!DOCTYPE svg><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"/>',
                   '<!DOCTYPE svg [<!ENTITY payload "expanded">]>'
                   '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><title>&payload;</title></svg>',
                   '<!DOCTYPE svg SYSTEM "https://example.test/external.dtd">'
                   '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"/>',
                   '<?xml-stylesheet href="https://example.test/theme.css"?>'
                   '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"/>',
                   '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
                   '<metadata><?instruction ignored?></metadata></svg>')
        for encoding in ("utf-8", "utf-16"):
            for source in sources:
                with self.subTest(encoding=encoding, source=source[:50]):
                    path = self.root / "icon.svg"
                    path.write_bytes(source.encode(encoding))
                    with self.assertRaisesRegex(ValueError, "DOCTYPE|entity|processing instructions"):
                        icon_svg(path, 0, 0, 384)
        path = self.root / "icon.svg"
        path.write_text('<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" '
                        'viewBox="0 0 100 100"><title>Icon &amp; logo &#35;1</title></svg>')
        self.assertIn("Icon & logo #1", "".join(ET.fromstring(icon_svg(path, 0, 0, 384)).itertext()))

    def test_project_icon_assets_pass_validation(self):
        skills = Path(__file__).resolve().parents[2]
        for asset in (skills / "apple-app-icon-design/assets/icon-large.png",
                      skills / "apple-framework-icon-design/assets/icon-large.svg"):
            with self.subTest(asset=asset.name, skill=asset.parent.parent.name):
                image = ET.fromstring(icon_svg(asset, 64, 128, 384))
                self.assertEqual([image.get(key) for key in ("x", "y", "width", "height")],
                                 ["64", "128", "384", "384"])

    def test_rasters_with_valid_structure_but_corrupt_pixels_are_rejected(self):
        def chunk(kind, data):
            return (struct.pack(">I", len(data)) + kind + data
                    + struct.pack(">I", zlib.crc32(kind + data)))
        bad_png = (b"\x89PNG\r\n\x1a\n"
                   + chunk(b"IHDR", struct.pack(">IIBBBBB", 384, 384, 8, 6, 0, 0, 0))
                   + chunk(b"IDAT", b"invalid compressed pixels") + chunk(b"IEND", b""))
        bad_jpeg = self.image_data("JPEG")[:-2]
        animation = BytesIO()
        Image.new("RGBA", (384, 384), "red").save(
            animation, format="PNG", save_all=True,
            append_images=[Image.new("RGBA", (384, 384), "blue")], duration=100)
        original = animation.getvalue()
        offset, bad_animation = 8, original[:8]
        while offset < len(original):
            length = struct.unpack(">I", original[offset:offset + 4])[0]
            kind, pixels = original[offset + 4:offset + 8], original[offset + 8:offset + 8 + length]
            if kind == b"fdAT":
                pixels = pixels[:4] + b"invalid compressed pixels"
            bad_animation += chunk(kind, pixels)
            offset += length + 12
        for format, mime, data in (("PNG", "image/png", bad_png), ("JPEG", "image/jpeg", bad_jpeg),
                                  ("APNG", "image/png", bad_animation)):
            with self.subTest(format=format):
                with Image.open(BytesIO(data)) as image:
                    image.verify()
                if format == "APNG":
                    with Image.open(BytesIO(data)) as image:
                        self.assertEqual(image.n_frames, 2)
                        image.load()
                path = self.root / ("corrupt." + format.lower())
                path.write_bytes(data)
                with self.assertRaisesRegex(ValueError, "valid PNG, JPEG or WebP"):
                    icon_svg(path, 0, 0, 384)
                uri = f'data:{mime};base64,' + base64.b64encode(data).decode("ascii")
                for attribute in ("href", "xlink:href"):
                    path = self.svg_icon(f'<svg><image {attribute}="{uri}"/></svg>')
                    with self.assertRaisesRegex(ValueError, "valid PNG, JPEG or WebP"):
                        icon_svg(path, 0, 0, 384)

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
