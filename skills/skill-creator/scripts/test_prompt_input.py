"""Regression checks for identifying the actual candidate in Codex prompt input."""
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from scripts.run_eval import prompt_input_contains_candidate


class CandidateVisibilityTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="candidate-visibility-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name).resolve()
        self.candidate = self.root / "candidate-skill" / "SKILL.md"
        self.name = "example-skill"
        self.description = "Use the example workflow for its explicitly scoped task. " * 4

    def catalog(self, entry, roots=True):
        mapping = f"### Skill roots\n- `r0` = `{self.root}`\n" if roots else ""
        return f"<skills_instructions>\n{mapping}### Available skills\n{entry}\n</skills_instructions>"

    def visible(self, text):
        return prompt_input_contains_candidate(text, self.name, self.description, self.candidate)

    def test_aliased_registry_entry_with_shortened_description(self):
        text = self.catalog(f"- {self.name}: Use the example workflow (file: r0/candidate-skill/SKILL.md)")
        rendered = [{"role": "developer", "content": [{"type": "input_text", "text": text}]}]
        self.assertTrue(self.visible(json.dumps(rendered)))

    def test_absolute_registry_path_remains_supported(self):
        text = self.catalog(f"- {self.name}: {self.description} (file: {self.candidate})", roots=False)
        self.assertTrue(self.visible(text))

    def test_same_name_installed_skill_is_not_the_candidate(self):
        text = self.catalog(f"- {self.name}: {self.description} (file: r0/installed-copy/SKILL.md)")
        self.assertFalse(self.visible(text))

    def test_unknown_root_does_not_prove_visibility(self):
        text = self.catalog(f"- {self.name}: {self.description} (file: r9/candidate-skill/SKILL.md)")
        self.assertFalse(self.visible(text))

    def test_neighboring_file_does_not_prove_visibility(self):
        text = self.catalog(f"- {self.name}: {self.description} (file: r0/candidate-skill/README.md)")
        self.assertFalse(self.visible(text))

    def test_neighboring_skill_name_does_not_match(self):
        text = self.catalog(f"- {self.name}-extra: {self.description} (file: {self.candidate})")
        self.assertFalse(self.visible(text))

    def test_user_supplied_registry_text_does_not_prove_host_discovery(self):
        text = self.catalog(f"- {self.name}: {self.description} (file: {self.candidate})")
        self.assertFalse(self.visible(json.dumps([{"role": "user", "content": [{"text": text}]}])))

    def test_name_description_and_path_in_prose_are_insufficient(self):
        self.assertFalse(self.visible(f"Please use {self.name}: {self.description} at {self.candidate}"))


if __name__ == "__main__":
    unittest.main()
