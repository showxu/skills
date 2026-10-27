"""Exercise clone signing setup and allowed-signers list selection without network."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SKILL = Path(__file__).resolve().parents[1]
OUTPUT = Path(os.environ["REPO_STEWARD_TEST_OUTPUT"])
OUTPUT.mkdir(parents=True, exist_ok=True)
EMAIL = "owner@example.test"
TRACKED = ".github/signing-allowed-signers"


class SigningSetupTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.signing = tempfile.TemporaryDirectory(dir=OUTPUT)
        keys = Path(cls.signing.name)
        for name in ("fixture-key", "release-key"):
            subprocess.run(["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(keys / name)],
                           check=True, capture_output=True)
        cls.key = keys / "fixture-key"
        cls.public = " ".join((keys / "fixture-key.pub").read_text().split()[:2])
        cls.other = " ".join((keys / "release-key.pub").read_text().split()[:2])
        cls.line = f'{EMAIL} namespaces="git" {cls.public}\n'
        cls.bot = f"release@example.test {cls.other}\n"

    @classmethod
    def tearDownClass(cls):
        cls.signing.cleanup()

    def setUp(self):
        self.fixture = tempfile.TemporaryDirectory(dir=OUTPUT)
        self.addCleanup(self.fixture.cleanup)
        self.root = Path(self.fixture.name).resolve()
        self.repo = self.root / "repo"
        self.repo.mkdir()
        # Directories outside the fixture repository are in no working tree,
        # wherever the test output lives.
        self.env = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1",
                        GIT_CEILING_DIRECTORIES=str(self.root), HOME=str(self.root))
        for name in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR"):
            self.env.pop(name, None)
        self.git("init", "-q", "-b", "main")
        self.shared = self.root / "shared" / "allowed_signers"
        self.shared.parent.mkdir()

    def git(self, *args, check=True):
        return subprocess.run(["git", *args], cwd=self.repo, env=self.env,
                              check=check, text=True, capture_output=True).stdout.strip()

    def setup_commit(self, *args):
        self.git("-c", "user.name=Setup", "-c", "user.email=setup@example.test",
                 "-c", "commit.gpgsign=false", "commit", "-q", *args)

    def track(self, content):
        tracked = self.repo / TRACKED
        tracked.parent.mkdir()
        tracked.write_text(content)
        self.git("add", TRACKED)
        self.setup_commit("-m", "ci: add signers")
        self.git("config", "gpg.ssh.allowedSignersFile", TRACKED)
        return tracked

    def configure(self, script="configure-signing.sh", repo=None, **inputs):
        environment = dict(self.env, OWNER_NAME="Fixture Owner", OWNER_EMAIL=EMAIL,
                           SIGNING_KEY=str(self.key), **inputs)
        return subprocess.run(["sh", str(SKILL / "scripts" / script), str(repo or self.repo)],
                              env=environment, text=True, capture_output=True)

    def config(self):
        return (self.repo / ".git/config").read_text()

    def signers(self):
        return self.git("config", "--get-all", "gpg.ssh.allowedSignersFile", check=False)

    def assert_configured(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)

    def assert_refused(self, result, message, config):
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(message, result.stderr)
        self.assertIn(self.line.strip(), result.stderr)
        self.assertEqual(self.config(), config)

    def assert_verified_commit(self):
        self.git("commit", "-q", "--allow-empty", "-m", "feat: add payload")
        result = subprocess.run(["git", "verify-commit", "HEAD"], cwd=self.repo, env=self.env,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f'Good "git" signature for {EMAIL}', result.stderr)

    def test_without_list_falls_back_to_common_git_directory(self):
        self.assert_configured(self.configure())
        fallback = self.repo / ".git/allowed_signers"
        self.assertEqual(fallback.read_text(), self.line)
        self.assertEqual(self.signers(), str(fallback))
        self.assert_verified_commit()

    def test_linked_worktree_list_survives_worktree_removal(self):
        self.setup_commit("--allow-empty", "-m", "chore: start")
        worktree = self.root / "worktree"
        self.git("worktree", "add", "-q", "-b", "task", str(worktree))
        self.assert_configured(self.configure(repo=worktree))
        fallback = self.repo / ".git/allowed_signers"
        self.assertEqual(fallback.read_text(), self.line)
        self.git("worktree", "remove", str(worktree))
        self.assertEqual(self.signers(), str(fallback))
        self.assert_verified_commit()

    def test_signing_alone_installs_no_push_gate(self):
        self.assert_configured(self.configure())
        self.assertEqual(self.git("config", "--get", "tag.gpgsign"), "true")
        self.assertEqual(self.git("config", "--get-regexp", r"^steward\.", check=False), "")
        self.assertEqual(self.git("config", "--get", "credential.helper", check=False), "")
        self.assertFalse((self.repo / ".git/hooks/pre-push").exists())

    def test_configured_list_is_reused_and_extended_once(self):
        self.shared.write_text(self.bot)
        self.git("config", "gpg.ssh.allowedSignersFile", str(self.shared))
        for _ in range(2):
            self.assert_configured(self.configure())
        self.assertEqual(self.shared.read_text(), self.bot + self.line)
        self.assertEqual(self.signers(), str(self.shared))
        self.assertFalse((self.repo / ".git/allowed_signers").exists())
        self.assert_verified_commit()

    def test_owner_line_without_options_or_with_crlf_is_kept(self):
        for content in (f"{EMAIL} {self.public}\n", f"{EMAIL} {self.public}\r\n"):
            with self.subTest(content=content):
                self.shared.write_bytes((content + self.bot).encode())
                self.git("config", "gpg.ssh.allowedSignersFile", str(self.shared))
                self.assert_configured(self.configure())
                self.assertEqual(self.shared.read_bytes(), (content + self.bot).encode())
        self.assert_verified_commit()

    def test_lines_that_do_not_authorize_git_signing_are_not_the_owner_line(self):
        content = (f"{EMAIL} cert-authority {self.public}\n"
                   f'{EMAIL} namespaces="file" {self.public}\n'
                   f"{EMAIL} {self.other} replaced {self.public}\n")
        self.shared.write_text(content)
        self.git("config", "gpg.ssh.allowedSignersFile", str(self.shared))
        self.assert_configured(self.configure())
        self.assertEqual(self.shared.read_text(), content + self.line)
        self.assert_verified_commit()

    def test_rotated_key_is_appended_after_retired_key(self):
        retired = f'{EMAIL} namespaces="git" {self.other}\n'
        self.shared.write_text(retired)
        self.git("config", "gpg.ssh.allowedSignersFile", str(self.shared))
        self.assert_configured(self.configure())
        self.assertEqual(self.shared.read_text(), retired + self.line)
        self.assert_verified_commit()

    def test_missing_final_newline_is_repaired_before_appending(self):
        self.shared.write_text(self.bot.rstrip("\n"))
        self.git("config", "gpg.ssh.allowedSignersFile", str(self.shared))
        self.assert_configured(self.configure())
        self.assertEqual(self.shared.read_text(), self.bot + self.line)

    def test_explicit_list_replaces_configured_choice(self):
        previous = self.repo / ".git/allowed_signers"
        previous.write_text(self.bot)
        self.git("config", "gpg.ssh.allowedSignersFile", str(previous))
        self.assert_configured(self.configure(ALLOWED_SIGNERS=str(self.shared)))
        self.assertEqual(self.shared.read_text(), self.line)
        self.assertEqual(previous.read_text(), self.bot)
        self.assertEqual(self.signers(), str(self.shared))
        self.assert_verified_commit()

    def test_home_relative_list_is_stored_for_git_to_expand(self):
        self.assert_configured(self.configure(ALLOWED_SIGNERS="~/shared/allowed_signers"))
        self.assertEqual(self.shared.read_text(), self.line)
        self.assertEqual(self.signers(), "~/shared/allowed_signers")
        self.assert_verified_commit()

    def test_repeated_settings_are_replaced_by_one_value(self):
        self.git("config", "--add", "gpg.ssh.allowedSignersFile", str(self.root / "stale"))
        self.git("config", "--add", "gpg.ssh.allowedSignersFile", str(self.shared))
        self.git("config", "--add", "user.name", "Stale Owner")
        self.git("config", "--add", "user.name", "Other Owner")
        self.assert_configured(self.configure())
        self.assertEqual(self.signers(), str(self.shared))
        self.assertEqual(self.git("config", "--get-all", "user.name"), "Fixture Owner")
        self.assertEqual(self.shared.read_text(), self.line)
        self.assert_verified_commit()

    def test_tracked_list_with_owner_is_reused_unchanged(self):
        self.track(f"{EMAIL} {self.public}\n" + self.bot)
        self.assert_configured(self.configure())
        self.assertEqual(self.git("status", "--porcelain"), "")
        self.assertEqual(self.signers(), TRACKED)
        self.assert_verified_commit()

    def test_tracked_list_without_owner_is_refused_before_writes(self):
        tracked = self.track(self.bot)
        config = self.config()
        self.assert_refused(self.configure(), "is repository content", config)
        self.assertEqual(tracked.read_text(), self.bot)

    def test_untracked_list_in_working_tree_is_refused(self):
        listed = self.repo / "signers"
        listed.write_text(self.bot)
        config = self.config()
        self.assert_refused(self.configure(ALLOWED_SIGNERS="signers"), "is repository content", config)
        self.assertEqual(listed.read_text(), self.bot)

    def test_ignored_list_in_working_tree_is_written(self):
        (self.repo / ".gitignore").write_text("signers.local\n")
        self.assert_configured(self.configure(ALLOWED_SIGNERS="signers.local"))
        self.assertEqual((self.repo / "signers.local").read_text(), self.line)
        self.assertEqual(self.signers(), "signers.local")
        self.assert_verified_commit()

    def test_missing_list_in_working_tree_is_not_created(self):
        self.git("config", "gpg.ssh.allowedSignersFile", TRACKED)
        (self.repo / ".github").mkdir()
        config = self.config()
        self.assert_refused(self.configure(), "is missing from a working tree", config)
        self.assertFalse((self.repo / TRACKED).exists())

    def test_symbolic_link_list_is_not_written_through(self):
        tracked = self.track(self.bot)
        self.shared.symlink_to(tracked)
        config = self.config()
        self.assert_refused(self.configure(ALLOWED_SIGNERS=str(self.shared)),
                            "is a symbolic link", config)
        self.assertEqual(tracked.read_text(), self.bot)

    def test_full_setup_still_requires_checks_before_writes(self):
        config = self.config()
        result = self.configure("configure-clone.sh", CONTENT_CHECK="true")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("FAST_CHECK", result.stderr)
        self.assertEqual(self.config(), config)
        self.assertFalse((self.repo / ".git/allowed_signers").exists())

    def test_full_setup_uses_same_list_selection(self):
        self.git("config", "gpg.ssh.allowedSignersFile", str(self.shared))
        self.assert_configured(self.configure("configure-clone.sh", CONTENT_CHECK="true",
                                              FAST_CHECK="true"))
        self.assertEqual(self.shared.read_text(), self.line)
        self.assertEqual(self.git("config", "--get", "steward.fastCheck"), "true")
        self.assertTrue((self.repo / ".git/hooks/pre-push").exists())
        self.assert_verified_commit()


if __name__ == "__main__":
    unittest.main()
