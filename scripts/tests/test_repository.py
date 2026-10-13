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


if __name__ == "__main__":
    unittest.main()
