"""Read-only drift and unknown handling using captured metadata."""

import json
from pathlib import Path
import sys
from types import SimpleNamespace
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from audit_repo import audit, collect


class AuditTests(unittest.TestCase):
    def standard(self):
        return {"authority": "organization shared standard at reviewed revision",
                "expected": {"repository": {"default_branch": "trunk", "allow_merge_commit": False}}}

    def test_organization_expectation_wins_over_member_state(self):
        report = audit(self.standard(), {"observed": {"repository": {"default_branch": "main", "allow_merge_commit": True}}})
        self.assertEqual(report["exit_status"], 1)
        self.assertEqual(len(report["findings"]), 2)
        self.assertEqual(report["findings"][0]["expected"], "trunk")

    def test_missing_access_is_unknown_and_keeps_proven_drift(self):
        report = audit(self.standard(), {"observed": {"repository": {"allow_merge_commit": True}}})
        self.assertEqual(report["exit_status"], 2)
        self.assertEqual({item["state"] for item in report["findings"]}, {"unknown", "drift"})

    def test_missing_observations_cannot_claim_conformance(self):
        report = audit(self.standard(), {"observed": {}, "unknowns": [{"endpoint": "unavailable"}]})
        self.assertEqual(report["exit_status"], 2)

    def test_personal_standard_and_extra_unselected_fields(self):
        standard = {"authority": "documented personal defaults", "expected": {"repository": {"allow_merge_commit": False}}}
        report = audit(standard, {"observed": {"repository": {"allow_merge_commit": False, "default_branch": "main"}}})
        self.assertEqual(report["exit_status"], 0)

    def test_empty_expected_contract_is_invalid(self):
        with self.assertRaisesRegex(ValueError, "nonempty"):
            audit({"authority": "defaults", "expected": {}}, {"observed": {}})

    def test_capture_reads_inherited_rulesets_and_only_gets(self):
        endpoints = []
        def request(command, **kwargs):
            self.assertEqual(command[:4], ["gh", "api", "--method", "GET"])
            endpoint = command[4]
            endpoints.append(endpoint)
            if "?includes_parents" in endpoint:
                value = [{"id": 7, "source_type": "Organization", "source": "example-team"}]
            elif endpoint == "orgs/example-team/rulesets/7":
                value = {"id": 7, "name": "shared rule", "rules": [{"type": "required_signatures"}]}
            else:
                value = {}
            return SimpleNamespace(returncode=0, stdout=json.dumps(value))
        with patch("audit_repo.subprocess.run", side_effect=request):
            result = collect("example-team/project")
        self.assertIn("orgs/example-team/rulesets/7", endpoints)
        self.assertEqual(result["observed"]["rulesets"][0]["rules"][0]["type"], "required_signatures")


if __name__ == "__main__":
    unittest.main()
