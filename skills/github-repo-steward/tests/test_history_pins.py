"""Accepted-history and reusable-workflow audits with synthetic Git/API evidence."""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SKILL = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("history_pins", SKILL / "scripts/scan_repository.py")
SCAN = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SCAN)
OUTPUT = Path(os.environ["REPO_STEWARD_TEST_OUTPUT"])
OUTPUT.mkdir(parents=True, exist_ok=True)
OLD, NEW = "a" * 40, "b" * 40


def record(oid, verified=True, reason="valid"):
    return {"sha": oid, "commit": {"verification": {"verified": verified, "reason": reason}}}


class HistoryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=OUTPUT)
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name)
        self.env = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")
        for name in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR"):
            self.env.pop(name, None)
        self.git("init", "-q")
        self.git("config", "user.name", "Example Maintainer")
        self.git("config", "user.email", "maintainer@example.test")
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "tag.gpgsign", "false")

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.path, env=self.env,
                              capture_output=True, text=True, check=True).stdout.strip()

    def commit(self, subject):
        self.git("commit", "--allow-empty", "-qm", subject)
        return self.git("rev-parse", "HEAD")

    def test_verified_head_does_not_hide_unsigned_nonconventional_ancestor(self):
        old = self.commit("Initial import")
        head = self.commit("feat(parser)!: support another format")
        with patch.object(SCAN, "api_json", return_value=[[record(head)], [record(old, False, "unsigned")]]):
            result = SCAN.audit_history(self.path, "example/parcel", head)
        by_sha = {item["sha"]: item for item in result["commits"]}
        self.assertEqual(result["coverage"]["status"], "complete")
        self.assertEqual(by_sha[head]["signature"]["status"], "pass")
        self.assertTrue(by_sha[head]["conventional"])
        self.assertEqual(by_sha[old]["signature"]["status"], "drift")
        self.assertFalse(by_sha[old]["conventional"])
        calls = []
        SCAN.report_source_audit(result, [], head, False, "parcel", lambda *row: calls.append(row))
        self.assertEqual(len(calls), 2)
        self.assertTrue(all(row[0] == "REVIEW" and old in row[2] for row in calls))

    def test_tag_ancestry_lightweight_and_unsigned_tags_are_observed_without_signer_file(self):
        base = self.commit("chore: start")
        self.git("checkout", "-qb", "release-line")
        release = self.commit("fix: repair release")
        self.git("tag", "-a", "published", "-m", "release")
        tag_oid = self.git("rev-parse", "refs/tags/published")
        self.git("tag", "--no-sign", "legacy", base)
        self.git("checkout", "-q", "-B", "trunk", base)
        head = self.commit("feat: advance trunk")
        def api(endpoint, paginated=False):
            if endpoint.endswith(f"/git/tags/{tag_oid}"):
                return {"verification": {"verified": False, "reason": "unsigned"}}
            root = endpoint.split("sha=", 1)[1].split("&", 1)[0]
            return [[record(root), record(base)]]
        with patch.object(SCAN, "api_json", side_effect=api):
            result = SCAN.audit_history(self.path, "example/parcel", head)
        self.assertEqual({item["sha"] for item in result["commits"]}, {base, release, head})
        self.assertEqual(result["coverage"]["status"], "complete")
        tags = {item["name"]: item for item in result["tags"]}
        self.assertEqual(tags["published"]["target"], release)
        self.assertEqual(tags["published"]["signature"]["reason"], "unsigned")
        self.assertEqual(tags["legacy"]["signature"]["reason"], "lightweight tag")

    def test_local_ssh_tag_verification_uses_the_supplied_trust_file(self):
        head = self.commit("fix: validate")
        key = self.path / "ephemeral-key"
        subprocess.run(["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(key)], check=True,
                       capture_output=True)
        self.git("config", "gpg.format", "ssh")
        self.git("config", "user.signingkey", str(key))
        self.git("tag", "-s", "signed", "-m", "release")
        trust = self.path / "allowed-signers"
        trust.write_text("maintainer@example.test " + key.with_suffix(".pub").read_text())
        with patch.object(SCAN, "api_json", return_value=[[record(head)]]):
            result = SCAN.audit_history(self.path, "example/parcel", head, trust)
        self.assertEqual(result["tags"][0]["signature"]["status"], "pass")
        trust.write_text("")
        with patch.object(SCAN, "api_json", return_value=[[record(head)]]):
            result = SCAN.audit_history(self.path, "example/parcel", head, trust)
        self.assertEqual(result["tags"][0]["signature"]["status"], "drift")

    def test_missing_history_page_and_unavailable_tag_verification_remain_unknown(self):
        old = self.commit("chore: start")
        head = self.commit("fix: current")
        self.git("tag", "-a", "release", "-m", "release")
        def api(endpoint, paginated=False):
            if "/git/tags/" in endpoint:
                raise SystemExit("verification unavailable")
            return [[record(head)]]
        with patch.object(SCAN, "api_json", side_effect=api):
            result = SCAN.audit_history(self.path, "example/parcel", head)
        self.assertEqual(result["coverage"]["missing"], [old])
        self.assertEqual(result["coverage"]["status"], "unknown")
        self.assertEqual(result["tags"][0]["signature"]["status"], "unknown")
        calls = []
        SCAN.report_source_audit(result, [], head, True, "parcel", lambda *row: calls.append(row))
        self.assertTrue(all(row[0] == "UNKNOWN" for row in calls))

    def test_conventional_syntax_and_repository_type_set(self):
        first = self.commit("Feature(api)!: add endpoint")
        head = self.commit("fix: repair endpoint")
        with patch.object(SCAN, "api_json", return_value=[[record(head), record(first)]]):
            syntax = SCAN.audit_history(self.path, "example/parcel", head)
            policy = SCAN.audit_history(self.path, "example/parcel", head, commit_types=["feat", "fix"])
        self.assertTrue(all(item["conventional"] for item in syntax["commits"]))
        self.assertEqual([item["conventional"] for item in policy["commits"]], [True, False])
        for subject in ("fix:no space", "fix: ", "fix(): empty scope", "fix: a\nb"):
            self.assertIsNone(SCAN.SUBJECT.fullmatch(subject))

    def test_signature_service_errors_are_distinct_from_unsigned_or_invalid(self):
        for reason in ("gpgverify_unavailable", "gpgverify_error", "unknown_signature_type"):
            self.assertEqual(SCAN.signature_result({"verified": False, "reason": reason}, "captured")["status"], "unknown")
        for reason in ("unsigned", "invalid", "malformed_signature"):
            self.assertEqual(SCAN.signature_result({"verified": False, "reason": reason}, "captured")["status"], "drift")
        self.assertEqual(SCAN.signature_result({}, "captured")["status"], "unknown")

    def test_shallow_ancestry_cannot_claim_full_history_coverage(self):
        head = self.commit("fix: current")
        (self.path / ".git/shallow").write_text(head + "\n")
        with self.assertRaisesRegex(SystemExit, "complete ancestry"):
            SCAN.audit_history(self.path, "example/parcel", head)


class WorkflowPinTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=OUTPUT)
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name)
        self.workflows = self.path / ".github/workflows"
        self.workflows.mkdir(parents=True)

    def test_yaml_job_callers_include_flow_style_and_anchors_but_not_step_or_shell_decoys(self):
        text = f"""on: pull_request
jobs:
  direct: {{uses: example/shared/.github/workflows/policy.yml@{OLD}}}
  anchored: &shared
    uses: example/shared/.github/workflows/validate.yaml@{NEW}
  alias: *shared
  override:
    <<: *shared
    uses: example/shared/.github/workflows/another.yml@{OLD}
  build:
    steps:
      - uses: actions/checkout@{OLD}
      - run: |
          uses: fake/source/.github/workflows/decoy.yml@{OLD}
"""
        callers = SCAN.reusable_callers(text)
        self.assertEqual([item["job"] for item in callers], ["direct", "anchored", "alias", "override"])
        self.assertTrue(callers[-1]["observed"].endswith("another.yml@" + OLD))

    def test_pin_drift_reports_observed_expected_source_and_caches_each_shared_lookup(self):
        (self.workflows / "ci.yml").write_text(f"""jobs:
  old: {{uses: example/shared/.github/workflows/a.yml@{OLD}}}
  current: {{uses: example/shared/.github/workflows/b.yml@{NEW}}}
  floating: {{uses: example/shared/.github/workflows/c.yml@trunk}}
  local: {{uses: ./.github/workflows/local.yml}}
  local_cloud: {{uses: $/.github/workflows/local.yml}}
""")
        target = {"expected": NEW, "default_branch": "trunk", "source": ["captured metadata", "captured commit"]}
        with patch.object(SCAN, "shared_default", return_value=target) as resolver:
            result = SCAN.audit_workflow_pins(self.path, resolver)
        resolver.assert_called_once_with("example/shared")
        self.assertEqual([item["status"] for item in result], ["drift", "pass", "drift", "local", "local"])
        self.assertEqual(result[0]["observed"], OLD)
        self.assertEqual(result[0]["expected"], NEW)
        self.assertEqual(result[0]["workflow"], ".github/workflows/ci.yml")
        self.assertEqual(result[0]["source"], target["source"])
        self.assertFalse(result[2]["pinned"])

    def test_actual_default_branch_is_resolved_and_url_encoded(self):
        with patch.object(SCAN, "api_json", side_effect=[{"default_branch": "stable/next"}, {"sha": NEW}]) as api:
            target = SCAN.shared_default("example/shared")
        self.assertEqual(api.call_args_list[1].args[0], "repos/example/shared/commits/stable%2Fnext")
        self.assertEqual(target["expected"], NEW)

    def test_lookup_parse_and_unsupported_inputs_cannot_produce_a_clean_report(self):
        (self.workflows / "a.yml").write_text("jobs: {policy: {uses: example/shared/.github/workflows/a.yml@trunk}}")
        (self.workflows / "b.yml").write_text("jobs: {one: {uses: ./first.yml}, one: {uses: ./second.yml}}")
        (self.workflows / "c.yml").write_text("jobs: {policy: {uses: '${{ inputs.workflow }}'}}")
        (self.workflows / "d.yml").symlink_to("absent.yml")
        with patch.object(SCAN, "shared_default", side_effect=SystemExit("API unavailable")) as resolver:
            result = SCAN.audit_workflow_pins(self.path, resolver)
        self.assertEqual(len(result), 4)
        self.assertTrue(all(item["status"] == "unknown" for item in result))
        self.assertEqual(result[0]["pin_status"], "drift")
        self.assertIn("duplicate", result[1]["reason"])


if __name__ == "__main__":
    unittest.main()
