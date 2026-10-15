"""Exercise local gates without network access or the operator's signing key."""

import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch


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



    def test_remote_delegates_each_active_repository_and_retires_its_clone(self):
        with tempfile.TemporaryDirectory(dir=OUTPUT) as folder:
            output = Path(folder)
            repositories = [
                {"name": "member", "isArchived": False},
                {"name": "archived", "isArchived": True},
                {"name": "second", "isArchived": False},
            ]
            def observe(owner, repository, workdir, identities, signers, report):
                (workdir / repository["name"]).mkdir()
                report("REVIEW", repository["name"], "captured observation")
                return {"license_digest": "license-digest", "source_commit": "accepted-sha", "default_branch": "trunk"}
            steward = SimpleNamespace(inspect_repository=Mock(side_effect=observe))
            args = SimpleNamespace(org="example-team", work_dir=output, identity=["owner@example.test"],
                                   allowed_signers=None, repo_steward=Path("selected-skill"))
            rows = [{"name": item["name"], "archived": item["isArchived"], "fork": False, "default_branch": "trunk"} for item in repositories]
            pages = [rows[:1], rows[1:]]
            with patch.object(SCAN, "load_repo_steward", return_value=steward) as loader, patch.object(SCAN, "run", return_value=json.dumps(pages)), patch("builtins.print") as printed:
                self.assertEqual(SCAN.remote(args), 0)
            loader.assert_called_once_with(Path("selected-skill"))
            self.assertEqual(steward.inspect_repository.call_count, 2)
            self.assertEqual(steward.inspect_repository.call_args.args[0], "example-team")
            self.assertEqual([call.args[1]["name"] for call in steward.inspect_repository.call_args_list], ["member", "second"])
            self.assertTrue(any("SOURCE member: accepted-sha" in call.args[0] for call in printed.call_args_list))
            self.assertEqual(list(output.iterdir()), [])

    def test_missing_repository_steward_has_an_actionable_failure(self):
        with tempfile.TemporaryDirectory(dir=OUTPUT) as folder:
            with self.assertRaisesRegex(SystemExit, "Install github-repo-steward"):
                SCAN.load_repo_steward(Path(folder))


if __name__ == "__main__":
    unittest.main()
