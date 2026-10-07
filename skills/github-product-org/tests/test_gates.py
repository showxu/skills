"""Exercise local gates without network access or the operator's signing key."""

import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch


SKILL = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("scan_org", SKILL / "scripts/scan_org.py")
SCAN = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SCAN)
OUTPUT = Path(os.environ["ORG_TEST_OUTPUT"])
OUTPUT.mkdir(parents=True, exist_ok=True)


class ScannerTests(unittest.TestCase):
    def test_checkout_comparison_detects_unrelated_index_changes(self):
        with tempfile.TemporaryDirectory(dir=OUTPUT) as folder:
            root = Path(folder)
            repo = root / "repo"
            repo.mkdir()
            environment = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")
            for name in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR"):
                environment.pop(name, None)
            subprocess.run(["git", "init", "-q", str(repo)], check=True, env=environment)
            baseline = root / "baseline.json"
            baseline.write_text(json.dumps(SCAN.checkouts(root)))
            args = SimpleNamespace(root=root, baseline=baseline)
            with patch("builtins.print"):
                self.assertEqual(SCAN.compare(args), 0)
            (repo / "payload.txt").write_text("new work\n")
            subprocess.run(["git", "-C", str(repo), "add", "payload.txt"], check=True, env=environment)
            with patch("builtins.print") as output:
                self.assertEqual(SCAN.compare(args), 1)
            messages = [call.args[0] for call in output.call_args_list]
            self.assertTrue(any(line.startswith("FAIL repo: index ") for line in messages))

    def test_scan_preserves_nonempty_output_directory(self):
        with tempfile.TemporaryDirectory(dir=OUTPUT) as folder:
            root = Path(folder)
            owned = root / "keep.txt"
            owned.write_text("existing")
            args = SimpleNamespace(org="example", work_dir=root)
            with patch.object(SCAN, "run", return_value="[]"):
                with self.assertRaisesRegex(SystemExit, "must be empty"):
                    SCAN.remote(args)
            self.assertEqual(owned.read_text(), "existing")

    def test_scan_reuses_empty_output_directory(self):
        with tempfile.TemporaryDirectory(dir=OUTPUT) as folder:
            root = Path(folder)
            args = SimpleNamespace(org="example", work_dir=root)
            with patch.object(SCAN, "run", return_value="[]"), patch("builtins.print"):
                self.assertEqual(SCAN.remote(args), 0)
            self.assertTrue(root.is_dir())
            self.assertEqual(list(root.iterdir()), [])

    def test_latest_run_supersedes_failure_regardless_of_input_order(self):
        old = {"databaseId": 11, "workflowDatabaseId": 5, "conclusion": "failure"}
        new = {"databaseId": 12, "workflowDatabaseId": 5, "conclusion": "success"}
        self.assertEqual(SCAN.latest_workflow_runs([new, old]), [new])
        self.assertEqual(SCAN.latest_workflow_runs([old, new]), [new])

    def test_same_display_name_does_not_merge_different_workflows(self):
        first = {"databaseId": 11, "workflowDatabaseId": 5, "workflowName": "CI"}
        second = {"databaseId": 12, "workflowDatabaseId": 6, "workflowName": "CI"}
        self.assertEqual(SCAN.latest_workflow_runs([first, second]), [first, second])

    def test_running_or_failed_new_run_does_not_inherit_old_success(self):
        old = {"databaseId": 11, "workflowDatabaseId": 5, "conclusion": "success"}
        for conclusion in ("", "failure", "cancelled"):
            current = {"databaseId": 12, "workflowDatabaseId": 5, "conclusion": conclusion}
            with self.subTest(conclusion=conclusion):
                self.assertEqual(SCAN.latest_workflow_runs([old, current]), [current])

    def test_license_txt_and_identical_aliases_share_the_content_digest(self):
        with tempfile.TemporaryDirectory(dir=OUTPUT) as folder:
            root = Path(folder)
            self.assertEqual(SCAN.license_digest(root), "none")
            data = b"Example license\n"
            expected = hashlib.sha256(data).hexdigest()[:12]
            (root / "LICENSE.txt").write_bytes(data)
            self.assertEqual(SCAN.license_digest(root), expected)
            (root / "LICENSE").write_bytes(data)
            self.assertEqual(SCAN.license_digest(root), expected)

    def test_conflicting_license_files_remain_visible(self):
        with tempfile.TemporaryDirectory(dir=OUTPUT) as folder:
            root = Path(folder)
            (root / "LICENSE.txt").write_text("one")
            (root / "LICENSE").write_text("two")
            result = SCAN.license_digest(root)
            self.assertTrue(result.startswith("multiple:"))
            self.assertEqual(len(result.split(",")), 2)


class PushGateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.signing = tempfile.TemporaryDirectory(dir=OUTPUT)
        cls.key = Path(cls.signing.name) / "fixture-key"
        subprocess.run(["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(cls.key)],
                       check=True, capture_output=True)

    @classmethod
    def tearDownClass(cls):
        cls.signing.cleanup()

    def setUp(self):
        self.fixture = tempfile.TemporaryDirectory(dir=OUTPUT)
        self.addCleanup(self.fixture.cleanup)
        self.root = Path(self.fixture.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self.env = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")
        for name in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR"):
            self.env.pop(name, None)
        self.git("init", "-q", "-b", "main")
        content = self.root / "content check.py"
        content.write_text(
            "import pathlib, subprocess, sys\n"
            "commit = sys.argv[1]\n"
            "data = subprocess.check_output(['git', 'show', commit + ':payload.txt'])\n"
            "pathlib.Path('.git/content-checked').write_text(commit)\n"
            "raise SystemExit(2 if b'INTERNAL_VALUE' in data else 0)\n"
        )
        environment = dict(self.env, OWNER_NAME="Fixture Owner",
                           OWNER_EMAIL="owner@example.test", SIGNING_KEY=str(self.key),
                           CONTENT_CHECK=f'python3 {shlex.quote(str(content))} "$1"',
                           FAST_CHECK="printf done > .git/fast-ran")
        subprocess.run(["sh", str(SKILL / "scripts/configure-clone.sh"), str(self.repo)],
                       check=True, capture_output=True, env=environment)

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.repo, env=self.env,
                              check=True, text=True, capture_output=True).stdout.strip()

    def commit(self, content="public", signed=True, author=None, message="feat: add payload"):
        (self.repo / "payload.txt").write_text(content)
        self.git("add", "payload.txt")
        args = ["commit", "-qm", message]
        if not signed:
            args.append("--no-gpg-sign")
        if author:
            args += ["--author", author]
        self.git(*args)
        return self.git("rev-parse", "HEAD")

    def gate(self, ref="refs/heads/main", sha=None):
        target = sha or self.git("rev-parse", ref)
        line = f"{ref} {target} {ref} {'0' * 40}\n"
        return subprocess.run(["sh", ".git/hooks/pre-push"], cwd=self.repo, env=self.env,
                              input=line, text=True, capture_output=True)

    def assert_rejected(self, result, message):
        self.assertNotEqual(result.returncode, 0, result.stderr)
        self.assertIn(message, result.stderr)
        self.assertFalse((self.repo / ".git/fast-ran").exists())

    def test_signed_candidate_runs_content_at_exact_commit_then_fast_check(self):
        commit = self.commit()
        result = self.gate()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.repo / ".git/content-checked").read_text(), commit)
        self.assertEqual((self.repo / ".git/fast-ran").read_text(), "done")

    def test_unsigned_commit_is_rejected(self):
        self.commit(signed=False)
        self.assert_rejected(self.gate(), "not signed")

    def test_foreign_author_is_rejected(self):
        self.commit(author="Other Author <other@example.test>")
        self.assert_rejected(self.gate(), "foreign identity")

    def test_attribution_trailer_is_rejected(self):
        self.commit(message="feat: add payload\n\nCo-authored-by: Example Robot <robot@example.test>")
        self.assert_rejected(self.gate(), "attribution trailer")

    def test_content_failure_stops_fast_check(self):
        self.commit(content="INTERNAL_VALUE")
        self.assert_rejected(self.gate(), "content scan failed")

    def test_fast_failure_blocks_push(self):
        self.commit()
        self.git("config", "org.fastCheck", "exit 7")
        self.assert_rejected(self.gate(), "fast check failed")
        self.assertTrue((self.repo / ".git/content-checked").exists())

    def test_missing_content_command_fails_closed(self):
        self.commit()
        self.git("config", "--unset", "org.contentCheck")
        self.assert_rejected(self.gate(), "configure org.contentCheck")

    def test_missing_fast_command_fails_closed(self):
        self.commit()
        self.git("config", "--unset", "org.fastCheck")
        self.assert_rejected(self.gate(), "configure org.fastCheck")

    def test_modified_worktree_is_not_validation_of_committed_candidate(self):
        self.commit()
        (self.repo / "payload.txt").write_text("uncommitted")
        self.assert_rejected(self.gate(), "must be clean")

    def test_staged_worktree_is_not_validation_of_committed_candidate(self):
        self.commit()
        (self.repo / "payload.txt").write_text("staged")
        self.git("add", "payload.txt")
        self.assert_rejected(self.gate(), "must be clean")

    def test_other_candidate_cannot_reuse_checked_out_source(self):
        old = self.commit()
        self.commit(content="second")
        self.assert_rejected(self.gate(sha=old), "check out candidate")

    def test_already_remote_commit_needs_no_repeated_local_check(self):
        commit = self.commit()
        self.git("update-ref", "refs/remotes/origin/main", commit)
        self.git("config", "--unset", "org.fastCheck")
        result = self.gate()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.repo / ".git/fast-ran").exists())

    def test_lightweight_tag_is_rejected(self):
        self.commit()
        self.git("-c", "tag.gpgsign=false", "tag", "v1.0.0")
        self.assert_rejected(self.gate(ref="refs/tags/v1.0.0"), "not an annotated tag")

    def test_signed_tag_uses_exact_object_from_push_input(self):
        self.commit()
        self.git("tag", "-sm", "Release", "v1.0.0")
        result = self.gate(ref="refs/tags/v1.0.0")
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
