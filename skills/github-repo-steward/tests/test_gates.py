"""Exercise task-clone signing and repository-owned gates without network."""

import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest

SKILL = Path(__file__).resolve().parents[1]
OUTPUT = Path(os.environ["REPO_STEWARD_TEST_OUTPUT"])
OUTPUT.mkdir(parents=True, exist_ok=True)


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
        # Identity comes only from config, as on runners where Git cannot infer one.
        self.env = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1",
                        GIT_CONFIG_COUNT="1", GIT_CONFIG_KEY_0="user.useConfigOnly",
                        GIT_CONFIG_VALUE_0="true")
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
        self.git("config", "steward.fastCheck", "exit 7")
        self.assert_rejected(self.gate(), "fast check failed")
        self.assertTrue((self.repo / ".git/content-checked").exists())

    def test_missing_content_command_fails_closed(self):
        self.commit()
        self.git("config", "--unset", "steward.contentCheck")
        self.assert_rejected(self.gate(), "configure steward.contentCheck")

    def test_missing_fast_command_fails_closed(self):
        self.commit()
        self.git("config", "--unset", "steward.fastCheck")
        self.assert_rejected(self.gate(), "configure steward.fastCheck")

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
        self.git("config", "--unset", "steward.fastCheck")
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
