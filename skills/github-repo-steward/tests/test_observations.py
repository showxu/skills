"""Per-repository observation regressions; no network or owner credentials."""

import hashlib
import importlib.util
import os
from pathlib import Path
import tempfile
import unittest

SKILL = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("repo_observations", SKILL / "scripts/scan_repository.py")
OBS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(OBS)
OUTPUT = Path(os.environ["REPO_STEWARD_TEST_OUTPUT"])
OUTPUT.mkdir(parents=True, exist_ok=True)


class ObservationTests(unittest.TestCase):
    def test_latest_run_supersedes_failure_regardless_of_input_order(self):
        old = {"databaseId": 11, "workflowDatabaseId": 5, "conclusion": "failure"}
        new = {"databaseId": 12, "workflowDatabaseId": 5, "conclusion": "success"}
        self.assertEqual(OBS.latest_workflow_runs([new, old]), [new])
        self.assertEqual(OBS.latest_workflow_runs([old, new]), [new])


    def test_same_display_name_does_not_merge_different_workflows(self):
        first = {"databaseId": 11, "workflowDatabaseId": 5, "workflowName": "CI"}
        second = {"databaseId": 12, "workflowDatabaseId": 6, "workflowName": "CI"}
        self.assertEqual(OBS.latest_workflow_runs([first, second]), [first, second])


    def test_running_or_failed_new_run_does_not_inherit_old_success(self):
        old = {"databaseId": 11, "workflowDatabaseId": 5, "conclusion": "success"}
        for conclusion in ("", "failure", "cancelled"):
            current = {"databaseId": 12, "workflowDatabaseId": 5, "conclusion": conclusion}
            with self.subTest(conclusion=conclusion):
                self.assertEqual(OBS.latest_workflow_runs([old, current]), [current])


    def test_license_txt_and_identical_aliases_share_the_content_digest(self):
        with tempfile.TemporaryDirectory(dir=OUTPUT) as folder:
            root = Path(folder)
            self.assertEqual(OBS.license_digest(root), "none")
            data = b"Example license\n"
            expected = hashlib.sha256(data).hexdigest()[:12]
            (root / "LICENSE.txt").write_bytes(data)
            self.assertEqual(OBS.license_digest(root), expected)
            (root / "LICENSE").write_bytes(data)
            self.assertEqual(OBS.license_digest(root), expected)


    def test_conflicting_license_files_remain_visible(self):
        with tempfile.TemporaryDirectory(dir=OUTPUT) as folder:
            root = Path(folder)
            (root / "LICENSE.txt").write_text("one")
            (root / "LICENSE").write_text("two")
            result = OBS.license_digest(root)
            self.assertTrue(result.startswith("multiple:"))
            self.assertEqual(len(result.split(",")), 2)



if __name__ == "__main__":
    unittest.main()
