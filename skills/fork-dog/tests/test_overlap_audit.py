"""Synthetic full-history audits; no donor code, network or owner keys."""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SKILL = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("overlap_audit", SKILL / "scripts/overlap_audit.py")
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)
OUTPUT = Path(os.environ["OVERLAP_TEST_OUTPUT"])
OUTPUT.mkdir(parents=True, exist_ok=True)


class OverlapTests(unittest.TestCase):
    def setUp(self):
        self.workspace = tempfile.TemporaryDirectory(dir=OUTPUT)
        self.addCleanup(self.workspace.cleanup)
        self.root = Path(self.workspace.name)
        self.environment = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")
        for key in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR"):
            self.environment.pop(key, None)
        self.donor = self.repo("reference")
        self.candidate = self.repo("candidate")

    def git(self, repo, *args):
        return subprocess.check_output(["git", "-C", str(repo), *args], env=self.environment, stderr=subprocess.PIPE).decode().strip()

    def repo(self, name):
        path = self.root / name
        path.mkdir()
        self.git(path, "init", "-q", "-b", "fixture")
        self.git(path, "config", "user.name", "Fixture Owner")
        self.git(path, "config", "user.email", "fixture@example.test")
        self.git(path, "config", "commit.gpgsign", "false")
        return path

    def commit(self, repo, files, message):
        for name, content in files.items():
            path = repo / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content if isinstance(content, bytes) else content.encode())
        self.git(repo, "add", "-A")
        self.git(repo, "commit", "-qm", message)
        return self.git(repo, "rev-parse", "HEAD")

    def audit(self, **kwargs):
        return AUDIT.audit(self.candidate, "HEAD", [self.donor], terms=["DonorMark"], **kwargs)

    def test_deleted_history_renamed_paths_and_all_file_metrics(self):
        code = 'func renderResult(input: Int) -> String { return "value=\\(input * 17)" }\n'
        first = self.commit(self.donor, {"old.swift": code}, "reference start")
        self.git(self.donor, "mv", "old.swift", "new.swift")
        self.git(self.donor, "commit", "-qm", "reference rename")
        (self.donor / "new.swift").unlink()
        self.commit(self.donor, {"current.txt": "different behavior"}, "reference delete")
        self.commit(self.candidate, {"independent.swift": code, "unique.py": "value = independently_computed_result(variant=42)\n"}, "candidate start")
        result = self.audit()
        record = result["by_file"]["independent.swift"]
        self.assertTrue(record["identical_blobs"])
        self.assertEqual(record["identical_blobs"][0]["paths"], ["new.swift", "old.swift"])
        self.assertEqual(record["lines"]["40"]["shared"], 1)
        self.assertGreater(record["token_ngrams"]["8"]["shared"], 0)
        self.assertIn("unique.py", result["by_file"])
        self.assertEqual(result["references"][0]["commits"][-1], first)
        self.assertFalse(result["publication_approval"])

    def test_donor_nondefault_ref_is_in_scope(self):
        self.commit(self.donor, {"base.py": "base = 1\n"}, "base")
        self.git(self.donor, "switch", "-qc", "historical")
        self.commit(self.donor, {"retired.py": "retired = compute_legacy_payload(31, 47)\n"}, "historical content")
        self.git(self.donor, "switch", "-q", "fixture")
        self.commit(self.candidate, {"result.py": "retired = compute_legacy_payload(31, 47)\n"}, "candidate")
        self.assertTrue(self.audit()["by_file"]["result.py"]["identical_blobs"])

    def test_plain_renamed_copy_and_binary_exact_matches(self):
        self.commit(self.donor, {"old.py": "donor_only = False\n"}, "donor")
        copy = self.root / "renamed-copy"
        copy.mkdir()
        (copy / "local.py").write_text("renamed = transform_payload(19, 23, 29)\n")
        (copy / "asset.bin").write_bytes(b"\x00\xffCOPY")
        self.commit(self.candidate, {"new.py": (copy / "local.py").read_bytes(), "binary.dat": b"\x00\xffCOPY"}, "candidate")
        result = self.audit(copies=[copy])
        self.assertEqual(result["copies"][0]["files"], 2)
        for name in ("new.py", "binary.dat"):
            self.assertTrue(result["by_file"][name]["identical_blobs"])
        self.assertEqual(result["by_file"]["binary.dat"]["normalization"], "binary")
        self.assertEqual(result["by_file"]["binary.dat"]["lines"], {})

    def test_git_copy_includes_history_and_uncommitted_content(self):
        self.commit(self.donor, {"base.txt": "base"}, "donor")
        copy = self.repo("renamed-git-copy")
        self.commit(copy, {"past.py": "previous = collect_unique_values(71, 83)\n"}, "copy history")
        (copy / "past.py").unlink()
        self.commit(copy, {"current.py": "current = 1\n", ".gitignore": "output/\n"}, "copy renamed")
        (copy / "uncommitted.py").write_text("uncommitted = independent_probe(101, 103)\n")
        (copy / "output").mkdir()
        (copy / "output/skipped.py").write_text("ignored")
        self.commit(self.candidate, {"one.py": "previous = collect_unique_values(71, 83)\n", "two.py": (copy / "uncommitted.py").read_text()}, "candidate")
        result = self.audit(copies=[copy])
        self.assertEqual(len(result["copies"][0]["history"]["commits"]), 2)
        self.assertTrue(result["by_file"]["one.py"]["identical_blobs"])
        self.assertTrue(result["by_file"]["two.py"]["identical_blobs"])
        self.assertEqual(result["copies"][0]["files"], 3)

    def test_shared_commits_selected_ancestry_and_metadata_names(self):
        shared = self.commit(self.donor, {"base.py": "base = 1\n"}, "reference base")
        self.git(self.candidate, "fetch", "-q", str(self.donor), "fixture")
        self.git(self.candidate, "reset", "-q", "--hard", "FETCH_HEAD")
        self.git(self.candidate, "config", "user.name", "DonorMark Author")
        self.git(self.candidate, "config", "user.email", "committer@donormark.test")
        new = self.commit(self.candidate, {"DonorMark.txt": "retained DONORMARK attribution"}, "candidate names DonorMark")
        result = self.audit()
        self.assertEqual(result["common_commits"][0]["commits"], [shared])
        hit = next(item for item in result["commit_metadata_term_hits"] if item["commit"] == new)
        self.assertEqual(set(hit["fields"]), {"author", "committer", "message"})
        self.assertEqual(result["by_file"]["DonorMark.txt"]["term_hits"], [{"term": "DonorMark", "filename": True, "content": True}])

    def test_tab_newline_unicode_paths_are_not_quoted_or_lost(self):
        path = "odd\tpath\n源.py"
        content = "value = operation_with_unusual_path(5, 7)\n"
        self.commit(self.donor, {path: content}, "donor")
        self.commit(self.candidate, {path: content}, "candidate")
        result = self.audit()
        self.assertTrue(result["by_file"][path]["identical_blobs"])
        self.assertIn(path, result["by_file"][path]["identical_blobs"][0]["paths"])

    def test_comments_multiline_imports_braces_and_string_markers(self):
        code = '''/* comment with tokens that should vanish
           /* nested comment */ still ignored */
import { VeryLongImportedType,
         AnotherImportedType } from "module";
{
}
const endpoint = "https://example.test/#fragment"; // ignored trailing words
'''
        lines = AUDIT.meaningful_lines(code, "c")
        self.assertEqual(lines, ['const endpoint = "https://example.test/#fragment";'])
        python = '# hash comment\nfrom module import (\n LongImportedName,\n OtherImportedName\n)\nvalue = "#literal" # trailing comment\n'
        self.assertEqual(AUDIT.meaningful_lines(python, "hash"), ['value = "#literal"'])
        lines, _ = AUDIT.text_view(b'import: schema-value\n', "config.yaml", "auto")
        self.assertEqual(lines, ['import: schema-value'])

    def test_line_thresholds_and_non_swift_ngram_metrics(self):
        self.commit(self.donor, {"source.py": "result = compute(payload, options, strict=True)\n"}, "reference")
        self.commit(self.candidate, {"target.py": "result=compute(payload,options,strict=True)\nshort()\n"}, "candidate")
        result = self.audit(lengths=[10, 100], sizes=[4, 7])
        target = result["by_file"]["target.py"]
        self.assertEqual(target["lines"]["100"]["percent"], None)
        self.assertGreater(target["token_ngrams"]["7"]["shared"], 0)
        self.assertEqual(result["parameters"]["ngram_sizes"], [4, 7])

    def test_plain_copy_exclusions_and_symlinks_do_not_follow_targets(self):
        self.commit(self.donor, {"base.py": "value = 1\n"}, "donor")
        self.commit(self.candidate, {"link.txt": "outside"}, "candidate")
        copy = self.root / "copy"
        copy.mkdir()
        (copy / "cache").mkdir()
        (copy / "cache/payload.py").write_text("ignored")
        (copy / "link.txt").symlink_to("outside")
        result = self.audit(copies=[copy], excludes=["cache", "cache/**"])
        self.assertEqual(result["copies"][0]["files"], 1)
        self.assertTrue(result["by_file"]["link.txt"]["identical_blobs"])

    def test_shallow_donor_is_incomplete(self):
        self.commit(self.donor, {"one.py": "one = 1\n"}, "first")
        self.commit(self.donor, {"two.py": "two = 2\n"}, "second")
        self.commit(self.candidate, {"unique.py": "unique = 3\n"}, "candidate")
        shallow = self.root / "shallow"
        subprocess.run(["git", "clone", "-q", "--depth", "1", self.donor.as_uri(), str(shallow)], check=True, env=self.environment)
        with self.assertRaisesRegex(ValueError, "shallow"):
            AUDIT.audit(self.candidate, "HEAD", [shallow], terms=["DonorMark"])

    def test_replacement_refs_are_incomplete(self):
        first = self.commit(self.donor, {"one.py": "one = 1"}, "first")
        second = self.commit(self.donor, {"two.py": "two = 2"}, "second")
        self.commit(self.candidate, {"unique.py": "unique = 3"}, "candidate")
        self.git(self.donor, "replace", first, second)
        with self.assertRaisesRegex(ValueError, "Replacement refs"):
            self.audit()

    def test_exact_content_comparison_across_git_object_formats(self):
        self.commit(self.donor, {"source.txt": "same meaningful content despite different object formats"}, "donor")
        other = self.root / "sha256-candidate"
        other.mkdir()
        self.git(other, "init", "-q", "--object-format=sha256")
        self.git(other, "config", "user.name", "Fixture Owner")
        self.git(other, "config", "user.email", "fixture@example.test")
        self.git(other, "config", "commit.gpgsign", "false")
        self.commit(other, {"renamed.txt": "same meaningful content despite different object formats"}, "candidate")
        result = AUDIT.audit(other, "HEAD", [self.donor], terms=["DonorMark"])
        exact = result["by_file"]["renamed.txt"]["identical_blobs"]
        self.assertTrue(exact)
        self.assertNotEqual(result["by_file"]["renamed.txt"]["object"], exact[0]["object"])

    def test_missing_history_blob_cannot_yield_a_clean_report(self):
        self.commit(self.donor, {"old.py": "old = historical_computation(19, 37)"}, "first")
        blob = self.git(self.donor, "rev-parse", "HEAD:old.py")
        (self.donor / "old.py").unlink()
        self.commit(self.donor, {"current.py": "current = 1"}, "delete")
        self.commit(self.candidate, {"result.py": "result = 2"}, "candidate")
        (self.donor / ".git/objects" / blob[:2] / blob[2:]).unlink()
        with self.assertRaisesRegex(ValueError, "Missing or malformed"):
            self.audit()

    def test_cli_rejects_source_overwrite_and_missing_history(self):
        self.commit(self.donor, {"source.py": "result = source_value(1, 2)\n"}, "donor")
        self.commit(self.candidate, {"target.py": "result = candidate_value(3, 4)\n"}, "candidate")
        target = self.candidate / "target.py"
        original = target.read_bytes()
        command = ["python3", "-B", str(SKILL / "scripts/overlap_audit.py"), "--candidate", str(self.candidate), "--ref", "HEAD", "--reference", str(self.donor), "--term", "DonorMark"]
        result = subprocess.run(command + ["--output", str(target)], env=self.environment, capture_output=True)
        self.assertEqual(result.returncode, 2)
        self.assertEqual(target.read_bytes(), original)
        output = self.root / "receipt.json"
        result = subprocess.run(command + ["--output", str(output)], env=self.environment, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(output.read_text())["publication_approval"], False)
        self.assertEqual(self.git(self.candidate, "status", "--porcelain"), "")
        self.assertEqual(self.git(self.donor, "status", "--porcelain"), "")
        invalid = subprocess.run(command + ["--min-line-length", "0"], env=self.environment, capture_output=True)
        self.assertEqual(invalid.returncode, 2)
        missing = subprocess.run(command + ["--ref", "missing-commit"], env=self.environment, capture_output=True)
        self.assertEqual(missing.returncode, 2)


if __name__ == "__main__":
    unittest.main()
