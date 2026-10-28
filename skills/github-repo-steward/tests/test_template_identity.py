"""Template identity replacements using tracked-file evidence and local files."""

from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import apply_template_identity as identity

OUTPUT = Path(os.environ["REPO_STEWARD_TEST_OUTPUT"])
OUTPUT.mkdir(parents=True, exist_ok=True)


class TemplateIdentityTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=OUTPUT)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.tracked = []
        self.commands = []

    def file(self, name, data, mode=0o644, tracked=True):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        path.chmod(mode)
        if tracked:
            self.tracked.append(name)
        return path

    def git(self, command, **kwargs):
        self.commands.append(command)
        self.assertEqual(command[:3], ["git", "-C", str(self.root)])
        if command[3:] == ["rev-parse", "--is-inside-work-tree"]:
            return b"true\n"
        self.assertEqual(command[3:], ["ls-files", "-z"])
        return b"\0".join(os.fsencode(path) for path in self.tracked) + b"\0"

    def run_identity(self, *args):
        stdout, stderr = StringIO(), StringIO()
        with patch.object(identity.subprocess, "check_output", side_effect=self.git):
            with redirect_stdout(stdout), redirect_stderr(stderr):
                status = identity.main(["--root", str(self.root), *args])
        return status, stdout.getvalue(), stderr.getvalue()

    def test_content_and_path_replacement_longest_first_preserves_mode_and_bytes(self):
        name = "swift-package-template/scripts/swift-package-template.sh"
        original = self.file(name, b"#!/bin/sh\r\nexample-org/swift-package-template swift-package-template\r\n",
                             mode=0o755)
        untracked = self.file("untracked.txt", b"swift-package-template", tracked=False)
        status, stdout, stderr = self.run_identity(
            "--map", "swift-package-template=swift-color",
            "--map", "example-org/swift-package-template=example/swift-color")
        target = self.root / "swift-color/scripts/swift-color.sh"
        self.assertEqual(status, 0, stderr)
        self.assertFalse(original.exists())
        self.assertFalse((self.root / "swift-package-template").exists())
        self.assertEqual(target.read_bytes(), b"#!/bin/sh\r\nexample/swift-color swift-color\r\n")
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o755)
        self.assertEqual(untracked.read_bytes(), b"swift-package-template")
        self.assertIn("rename " + name, stdout)
        self.assertIn("change swift-color/scripts/swift-color.sh", stdout)
        self.assertEqual([command[3:] for command in self.commands],
                         [["rev-parse", "--is-inside-work-tree"], ["ls-files", "-z"]])

    def test_removes_files_and_directories_before_replacements(self):
        removed = self.file("Templates/logo.txt", b"old identity")
        removed_file = self.file("template-only.txt", b"old identity")
        self.file("README.md", b"old")
        status, stdout, stderr = self.run_identity(
            "--map", "old=new", "--remove", "Templates", "template-only.txt")
        self.assertEqual(status, 0, stderr)
        self.assertFalse(removed.exists())
        self.assertFalse(removed_file.exists())
        self.assertFalse((self.root / "Templates").exists())
        self.assertEqual((self.root / "README.md").read_bytes(), b"new")
        self.assertLess(stdout.index("remove "), stdout.index("change "))

    def test_missing_removal_is_an_error_without_changes(self):
        path = self.file("README.md", b"old")
        status, _, stderr = self.run_identity("--map", "old=new", "--remove", "missing")
        self.assertEqual(status, 1)
        self.assertIn("missing", stderr)
        self.assertEqual(path.read_bytes(), b"old")

    def test_removed_directory_is_vacated_before_a_rename(self):
        self.file("new.txt/logo.txt", b"template-only")
        self.file("old.txt", b"old")
        status, _, stderr = self.run_identity("--map", "old=new", "--remove", "new.txt")
        self.assertEqual(status, 0, stderr)
        self.assertEqual((self.root / "new.txt").read_bytes(), b"new")

    def test_residue_reports_every_path_and_content_occurrence_with_line(self):
        self.file("old.txt", b"heading\nold old\nold\n")
        status, _, stderr = self.run_identity("--map", "old=old-new")
        self.assertEqual(status, 1)
        self.assertIn("old-new.txt:1: path", stderr)
        self.assertEqual(stderr.count("old-new.txt:2: content"), 2)
        self.assertIn("old-new.txt:3: content", stderr)
        self.assertEqual((self.root / "old-new.txt").read_bytes(), b"heading\nold-new old-new\nold-new\n")

    def test_dry_run_prints_all_changes_and_writes_nothing(self):
        source = self.file("old/run.sh", b"old\n", mode=0o755)
        removed = self.file("Templates/logo.txt", b"old")
        status, stdout, stderr = self.run_identity(
            "--map", "old=new", "--remove", "Templates", "--dry-run")
        self.assertEqual(status, 0, stderr)
        self.assertIn("remove Templates/logo.txt", stdout)
        self.assertIn("rename old/run.sh -> new/run.sh", stdout)
        self.assertIn("change new/run.sh", stdout)
        self.assertEqual(source.read_bytes(), b"old\n")
        self.assertEqual(stat.S_IMODE(source.stat().st_mode), 0o755)
        self.assertEqual(removed.read_bytes(), b"old")
        self.assertFalse((self.root / "new").exists())

    def test_binary_contents_stay_intact_while_path_changes(self):
        data = b"\xff\x00old\x80\n"
        source = self.file("old.bin", data, mode=0o640)
        status, _, stderr = self.run_identity("--map", "old=new")
        self.assertEqual(status, 0, stderr)
        self.assertFalse(source.exists())
        target = self.root / "new.bin"
        self.assertEqual(target.read_bytes(), data)
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o640)

    def test_symlink_replacement_does_not_follow_untracked_contents(self):
        target = self.file("untouched.txt", b"old", tracked=False)
        source = self.root / "old-link"
        source.symlink_to("untouched.txt")
        self.tracked.append("old-link")
        status, _, stderr = self.run_identity("--map", "old=new")
        self.assertEqual(status, 0, stderr)
        self.assertEqual(os.readlink(self.root / "new-link"), "untouched.txt")
        self.assertEqual(target.read_bytes(), b"old")

    def test_untracked_files_cannot_be_removed(self):
        self.file("Templates/tracked.txt", b"old")
        untracked = self.file("Templates/untracked.txt", b"old", tracked=False)
        status, _, stderr = self.run_identity("--map", "old=new", "--remove", "Templates")
        self.assertEqual(status, 1)
        self.assertIn("untracked", stderr)
        self.assertEqual(untracked.read_bytes(), b"old")
        self.assertEqual((self.root / "Templates/tracked.txt").read_bytes(), b"old")

    def test_root_and_parent_removals_cannot_leave_root(self):
        for path in (".", "../outside", str(self.root)):
            with self.subTest(path=path):
                status, _, stderr = self.run_identity("--map", "old=new", "--remove", path)
                self.assertEqual(status, 1)
                self.assertIn("relative to the root", stderr)

    def test_rename_does_not_overwrite_untracked_files(self):
        original = self.file("old.txt", b"old")
        destination = self.file("new.txt", b"local", tracked=False)
        status, _, stderr = self.run_identity("--map", "old=new")
        self.assertEqual(status, 1)
        self.assertIn("new.txt", stderr)
        self.assertEqual(original.read_bytes(), b"old")
        self.assertEqual(destination.read_bytes(), b"local")

    def test_case_insensitive_collisions_fail_before_any_changes(self):
        root = self.root
        cases = (
            ("files", "old-one.txt", "old-two.txt", "Name", "name"),
            ("full-paths", "old-one/item.txt", "old-two/item.txt", "Name", "name"),
            ("directories", "old-one/first.txt", "old-two/second.txt", "Name", "name"),
            ("file-directory", "old-one", "old-two/item.txt", "Name", "name"),
            ("unicode", "old-one.txt", "old-two.txt", "Straße", "STRASSE"),
        )
        for case, first, second, new_first, new_second in cases:
            with self.subTest(case=case):
                self.root = root / case
                self.tracked = []
                self.file(first, b"old-one old-two\n", mode=0o755)
                self.file(second, b"old-two\n")
                self.file("Templates/logo.txt", b"template-only\n")
                before = {path.relative_to(self.root): (
                    path.read_bytes() if path.is_file() else None,
                    stat.S_IMODE(path.stat().st_mode),
                ) for path in self.root.rglob("*")}
                status, stdout, stderr = self.run_identity(
                    "--map", f"old-one={new_first}", "--map", f"old-two={new_second}",
                    "--remove", "Templates")
                self.assertEqual(status, 1)
                self.assertIn(new_first, stderr)
                self.assertIn(new_second, stderr)
                self.assertIn("case-insensitive path collision", stderr)
                self.assertEqual(stdout, "")
                after = {path.relative_to(self.root): (
                    path.read_bytes() if path.is_file() else None,
                    stat.S_IMODE(path.stat().st_mode),
                ) for path in self.root.rglob("*")}
                self.assertEqual(after, before)

    def test_git_worktree_is_required(self):
        error = subprocess.CalledProcessError(128, ["git"], stderr=b"not a git repository")
        stderr = StringIO()
        with patch.object(identity.subprocess, "check_output", side_effect=error):
            with redirect_stderr(stderr):
                status = identity.main(["--root", str(self.root), "--map", "old=new"])
        self.assertEqual(status, 1)
        self.assertIn(str(self.root), stderr.getvalue())
        self.assertIn("not a git repository", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
