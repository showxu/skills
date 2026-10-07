"""Run document and failure-path regressions without a native renderer."""

import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

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


if __name__ == "__main__":
    unittest.main()
