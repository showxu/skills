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
        cls.line = f'{EMAIL} namespaces="git" {cls.public}\n'
        release = " ".join((keys / "release-key.pub").read_text().split()[:2])
        cls.bot = f"release@example.test {release}\n"

    @classmethod
    def tearDownClass(cls):
        cls.signing.cleanup()

    def setUp(self):
        self.fixture = tempfile.TemporaryDirectory(dir=OUTPUT)
        self.addCleanup(self.fixture.cleanup)
        self.root = Path(self.fixture.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self.env = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1",
                        HOME=str(self.root))
        for name in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR"):
            self.env.pop(name, None)
        self.git("init", "-q", "-b", "main")
        self.shared = self.root / "shared" / "allowed_signers"
        self.shared.parent.mkdir()

    def git(self, *args, check=True):
        return subprocess.run(["git", *args], cwd=self.repo, env=self.env,
                              check=check, text=True, capture_output=True).stdout.strip()

    def configure(self, script="configure-signing.sh", **inputs):
        environment = dict(self.env, OWNER_NAME="Fixture Owner", OWNER_EMAIL=EMAIL,
                           SIGNING_KEY=str(self.key), **inputs)
        return subprocess.run(["sh", str(SKILL / "scripts" / script), str(self.repo)],
                              env=environment, text=True, capture_output=True)

    def signers(self):
        return self.git("config", "--get", "gpg.ssh.allowedSignersFile", check=False)

    def assert_verified_commit(self):
        self.git("commit", "-q", "--allow-empty", "-m", "feat: add payload")
        result = subprocess.run(["git", "verify-commit", "HEAD"], cwd=self.repo, env=self.env,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f'Good "git" signature for {EMAIL}', result.stderr)

    def assert_unconfigured(self):
        self.assertEqual(self.git("config", "--get", "user.email", check=False), "")
        self.assertEqual(self.git("config", "--get", "commit.gpgsign", check=False), "")

    def test_without_list_falls_back_to_git_directory(self):
        result = self.configure()
        self.assertEqual(result.returncode, 0, result.stderr)
        fallback = self.repo / ".git/allowed_signers"
        self.assertEqual(fallback.read_text(), self.line)
        self.assertEqual(self.signers(), str(fallback.resolve()))
        self.assert_verified_commit()

    def test_signing_alone_installs_no_push_gate(self):
        result = self.configure()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git("config", "--get", "tag.gpgsign"), "true")
        self.assertEqual(self.git("config", "--get-regexp", r"^steward\.", check=False), "")
        self.assertEqual(self.git("config", "--get", "credential.helper", check=False), "")
        self.assertFalse((self.repo / ".git/hooks/pre-push").exists())

    def test_configured_list_is_reused_and_extended_once(self):
        self.shared.write_text(self.bot)
        self.git("config", "gpg.ssh.allowedSignersFile", str(self.shared))
        for _ in range(2):
            result = self.configure()
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.shared.read_text(), self.bot + self.line)
        self.assertEqual(self.signers(), str(self.shared))
        self.assertFalse((self.repo / ".git/allowed_signers").exists())
        self.assert_verified_commit()

    def test_existing_owner_line_without_options_is_kept(self):
        content = f"{EMAIL} {self.public}\n" + self.bot
        self.shared.write_text(content)
        self.git("config", "gpg.ssh.allowedSignersFile", str(self.shared))
        result = self.configure()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.shared.read_text(), content)
        self.assert_verified_commit()

    def test_explicit_list_replaces_configured_choice(self):
        previous = self.repo / ".git/allowed_signers"
        previous.write_text(self.bot)
        self.git("config", "gpg.ssh.allowedSignersFile", str(previous))
        self.shared.write_text(self.bot.rstrip("\n"))
        result = self.configure(ALLOWED_SIGNERS=str(self.shared))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.shared.read_text(), self.bot + self.line)
        self.assertEqual(previous.read_text(), self.bot)
        self.assertEqual(self.signers(), str(self.shared))
        self.assert_verified_commit()

    def test_home_relative_list_is_stored_for_git_to_expand(self):
        result = self.configure(ALLOWED_SIGNERS="~/shared/allowed_signers")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.shared.read_text(), self.line)
        self.assertEqual(self.signers(), "~/shared/allowed_signers")
        self.assert_verified_commit()

    def test_tracked_list_with_owner_is_reused_unchanged(self):
        tracked = self.repo / ".github/signing-allowed-signers"
        tracked.parent.mkdir()
        tracked.write_text(f"{EMAIL} {self.public}\n" + self.bot)
        self.git("add", ".github")
        self.git("-c", "commit.gpgsign=false", "commit", "-qm", "ci: add signers")
        self.git("config", "gpg.ssh.allowedSignersFile", ".github/signing-allowed-signers")
        result = self.configure()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git("status", "--porcelain"), "")
        self.assertEqual(self.signers(), ".github/signing-allowed-signers")
        self.assert_verified_commit()

    def test_tracked_list_without_owner_is_refused_before_writes(self):
        tracked = self.repo / ".github/signing-allowed-signers"
        tracked.parent.mkdir()
        tracked.write_text(self.bot)
        self.git("add", ".github")
        self.git("-c", "commit.gpgsign=false", "commit", "-qm", "ci: add signers")
        self.git("config", "gpg.ssh.allowedSignersFile", ".github/signing-allowed-signers")
        result = self.configure()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("is repository content", result.stderr)
        self.assertIn(self.line.strip(), result.stderr)
        self.assertEqual(tracked.read_text(), self.bot)
        self.assert_unconfigured()

    def test_missing_list_in_working_tree_is_not_created(self):
        self.git("config", "gpg.ssh.allowedSignersFile", ".github/signing-allowed-signers")
        (self.repo / ".github").mkdir()
        result = self.configure()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("is repository content", result.stderr)
        self.assertFalse((self.repo / ".github/signing-allowed-signers").exists())
        self.assert_unconfigured()

    def test_full_setup_still_requires_checks_before_writes(self):
        result = self.configure("configure-clone.sh", CONTENT_CHECK="true")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("FAST_CHECK", result.stderr)
        self.assertFalse((self.repo / ".git/allowed_signers").exists())
        self.assert_unconfigured()

    def test_full_setup_uses_same_list_selection(self):
        self.git("config", "gpg.ssh.allowedSignersFile", str(self.shared))
        result = self.configure("configure-clone.sh", CONTENT_CHECK="true", FAST_CHECK="true")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.shared.read_text(), self.line)
        self.assertEqual(self.git("config", "--get", "steward.fastCheck"), "true")
        self.assertTrue((self.repo / ".git/hooks/pre-push").exists())
        self.assert_verified_commit()


if __name__ == "__main__":
    unittest.main()
