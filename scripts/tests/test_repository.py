import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_repository as repository


class PublicationTests(unittest.TestCase):
    def test_concrete_private_data_fails_without_printing_it(self):
        cases = [b"/Users/" + b"example/private/file", b"/home/" + b"example/project/file",
                 b"ghp_" + b"a" * 36, b"-----BEGIN PRIVATE KEY-----\n"]
        for content in cases:
            with self.subTest(content_type=content[:8]):
                findings = repository.content_findings({"README.md": content})
                self.assertTrue(findings)
                self.assertNotIn(content.decode().strip(), "\n".join(findings))

    def test_product_guidance_placeholders_and_license_notices_are_publishable(self):
        files = {"skills/example/references/tools.md":
                 b"Codex, Claude and Cursor use /Users/<user>/ for illustrative paths.\n",
                 "skills/example/NOTICE": b"Original source by a third-party contributor.\n"}
        self.assertEqual(repository.content_findings(files), [])

    def test_private_file_names_fail_even_with_empty_content(self):
        for name in (".codex/config.toml", ".agent/state.json", "plans/work.md",
                     "skills/example/.build/output", "skills/example/__pycache__/module.pyc"):
            with self.subTest(name=name):
                self.assertTrue(repository.content_findings({name: b""}))

    def test_agent_instruction_files_are_publishable_but_other_agent_state_is_not(self):
        for name in (".agent/agents.json", ".agent/agents.resolved", ".agent/instructions/guide.md",
                     ".agent/instructions/shared/route.md"):
            with self.subTest(name=name):
                self.assertEqual(repository.content_findings({name: b"{}\n"}), [])
        for name in (".agent/agents.json.bak", ".agent/agents.jsonl", ".agent/.agents.lock",
                     ".agent/instructions/units/.agent/cache/state", ".agent/instructions/.workspace/notes.md",
                     "skills/example/.agent/agents.json"):
            with self.subTest(name=name):
                self.assertTrue(repository.content_findings({name: b""}))

    def test_exact_commit_is_scanned_when_worktree_hides_the_leak(self):
        output = Path(os.environ.get("REPOSITORY_TEST_OUTPUT", ".build/repository-tests"))
        output.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=output) as folder:
            root = Path(folder)
            def git(*args):
                return subprocess.check_output(["git", "-C", folder, *args], stderr=subprocess.DEVNULL).decode().strip()
            git("init", "-q")
            (root / ".gitignore").write_text("private/\n")
            (root / "文档.md").write_text("/Users/" + "example/secret/\n")
            (root / "private").mkdir()
            (root / "private/config").write_text("local\n")
            git("add", ".gitignore", "文档.md")
            git("add", "-f", "private/config")
            tree = git("write-tree")
            (root / "文档.md").write_text("public\n")
            (root / "private/config").unlink()
            findings = repository.publication_findings(root, tree)
            self.assertIn("文档.md: workstation path", findings)
            self.assertIn("private/config: tracked despite publication exclusion", findings)


class PluginManifestTests(unittest.TestCase):
    def setUp(self):
        self.plugin = json.loads((Path(__file__).resolve().parents[2] / "plugin.json").read_text())

    def test_published_manifest_matches_the_schema(self):
        self.assertEqual(repository.plugin_manifest_findings(self.plugin), [])

    def test_schema_violations_are_reported(self):
        cases = {
            "schema": (lambda m: m.update({"$schema": "https://example.com/plugin.json"}),
                       "1.0.0 schema"),
            "name": (lambda m: m.update(name="Show--Skills"), "valid Agent Plugins name"),
            "skills field": (lambda m: m.update(skills="./skills/"), "outside the Agent Plugins"),
            "top-level interface": (lambda m: m.update(interface={}), "outside the Agent Plugins"),
            "version type": (lambda m: m.update(version=1), "must be strings"),
            "author field": (lambda m: m["author"].update(handle="showxu"), "author"),
            "keywords type": (lambda m: m.update(keywords="skills"), "keywords"),
            "namespace type": (lambda m: m["extensions"].update({"org.example": []}),
                               "each namespace"),
            "missing interface": (lambda m: m["extensions"]["com.openai"].pop("interface"),
                                  "Codex interface"),
        }
        for name, (change, message) in cases.items():
            with self.subTest(case=name):
                plugin = json.loads(json.dumps(self.plugin))
                change(plugin)
                self.assertIn(message, "\n".join(repository.plugin_manifest_findings(plugin)))

if __name__ == "__main__":
    unittest.main()
