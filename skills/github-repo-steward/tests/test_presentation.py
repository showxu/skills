"""Regression checks for layout bounds, recorded output and stale design inputs."""

import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from xml.etree import ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from presentation import load_spec, sha256, write_or_check
from render_social import fit_title, wrap_about
from render_terminal import cells, render

OUTPUT = Path(os.environ["REPO_STEWARD_TEST_OUTPUT"])
OUTPUT.mkdir(parents=True, exist_ok=True)


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
