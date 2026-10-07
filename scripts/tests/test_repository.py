import copy
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_policy as policy
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


class PolicyTests(unittest.TestCase):
    def record(self):
        return {"author": {"login": "showxu"}, "committer": {"login": "showxu"},
                "commit": {"author": {"email": policy.OWNER_EMAIL},
                           "committer": {"email": policy.OWNER_EMAIL},
                           "message": "feat: publish skills", "verification": {"verified": True}}}

    def test_verified_owner_and_github_squash_pass(self):
        record = self.record()
        self.assertEqual(policy.commit_findings("sha", record), [])
        record["commit"]["committer"]["email"] = "noreply@github.com"
        self.assertEqual(policy.commit_findings("sha", record), [])

    def test_signature_identity_and_attribution_fail_independently(self):
        base = self.record()
        cases = [("verification", "verified", False), ("author", "email", "other@example.com"),
                 ("committer", "email", "other@example.com")]
        for group, key, value in cases:
            record = copy.deepcopy(base)
            record["commit"][group][key] = value
            self.assertTrue(policy.commit_findings("sha", record))
        record = copy.deepcopy(base)
        record["commit"]["message"] += "\n\nCo-authored-by: Example <example@example.com>"
        self.assertTrue(policy.commit_findings("sha", record))

    def test_allowed_automation_still_requires_a_verified_commit(self):
        record = self.record()
        record["author"]["login"] = "dependabot[bot]"
        record["commit"]["author"]["email"] = "automation@example.com"
        self.assertEqual(policy.commit_findings("sha", record), [])
        record["commit"]["verification"]["verified"] = False
        self.assertTrue(policy.commit_findings("sha", record))

    def test_event_uses_pr_head_and_handles_initial_push(self):
        base, head = "a" * 40, "b" * 40
        self.assertEqual(policy.source_range({"pull_request": {"base": {"sha": base}, "head": {"sha": head}}}, "pull_request"), (base, head))
        self.assertEqual(policy.source_range({"before": policy.ZERO_SHA, "after": head}, "push"), (policy.ZERO_SHA, head))
        for event in ({"before": base, "after": head, "deleted": True},
                      {"before": base, "after": policy.ZERO_SHA}, {"before": base, "after": "--all"}):
            with self.assertRaises(ValueError):
                policy.source_range(event, "push")


if __name__ == "__main__":
    unittest.main()
