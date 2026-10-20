"""Captured GitHub evidence for public/member profile acceptance."""

from copy import deepcopy
import builtins
from http.client import InvalidURL
from importlib.util import find_spec
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import profile_observations as profiles


class ProfileObservationsTests(unittest.TestCase):
    def setUp(self):
        self.catalog = {
            "organization": {"login": "example-team", "name": "Example Team"},
            "promise": "Useful tools", "secondary": "Build with care.", "mark": "../assets/mark.svg",
            "navigation": {}, "groups": [{"title": "Build", "repositories": [
                {"name": "library", "outcome": "Build reusable features.", "icon": "https://example.test/icon.svg"},
                {"name": "tool", "outcome": "Inspect your work.", "icon": "../assets/tool.svg"}]}],
        }
        self.catalog_bytes = json.dumps(self.catalog).encode()
        self.member = {
            "maintenance": {role: {"label": role, "url": "https://example.test/" + role}
                            for role in ("maintenance", "versioning", "settings", "design")},
            "repositories": {"library": {"default_branch": "development", "workflow": "verify.yml", "releases": "published"},
                             "tool": {"default_branch": "development", "workflow": None, "releases": "none"}},
        }
        self.repos = [self.repo(".github"), self.repo(".github-private", "private"),
                      self.repo("library"), self.repo("tool"), self.repo("old", archived=True),
                      self.repo("internal", "private")]
        self.rows = []
        self.workflow = "jobs:\n  profile:\n    uses: example-team/.github/.github/workflows/profile.yml@" + "a" * 40 + " # v0.1.0\n"
        self.workflow_tree = {"tree": [{"path": ".github/workflows/check.yml", "type": "blob"}], "truncated": False}

    def repo(self, name, visibility="public", archived=False):
        return dict(name=name, visibility=visibility, isArchived=archived,
                    defaultBranchRef={"name": "development"}, isFork=False)

    def content(self, owner, repository, path, revision):
        if repository == ".github" and path == "profile/catalog.json":
            self.assertIn(revision, ("development", "a" * 40))
            return self.catalog_bytes
        if repository == ".github-private":
            if path == ".github/workflows/check.yml":
                return self.workflow.encode()
            self.assertEqual(path, "profile/member.json")
            return json.dumps(self.member).encode()
        self.fail(f"unexpected file request: {repository}/{path}")

    def api(self, endpoint):
        if "/.github-private/git/trees/" in endpoint:
            return self.workflow_tree
        if "git/trees/development?recursive=1" in endpoint:
            return {"tree": [{"path": ".github/workflows/verify.yml", "type": "blob"}], "truncated": False}
        if "library/releases?" in endpoint:
            return [{"draft": False, "prerelease": False}]
        if "tool/releases?" in endpoint:
            return []
        self.fail(f"unexpected API request: {endpoint}")

    def scan(self, api=None, content=None, icons=True):
        with patch.object(profiles, "content", side_effect=content or self.content), \
             patch.object(profiles, "api", side_effect=lambda endpoint: self.api(endpoint) if "/.github-private/git/trees/" in endpoint else (api or self.api)(endpoint)), \
             patch.object(profiles, "image_resolves", return_value=icons) as images:
            profiles.inspect_profiles("example-team", self.repos, lambda *row: self.rows.append(row))
        return images

    def scan_workflows(self, workflows):
        self.workflow_tree["tree"] = [{"path": path, "type": "blob"} for path in workflows]
        def content(owner, repository, path, revision):
            if repository == ".github-private" and path in workflows:
                return workflows[path].encode()
            return self.content(owner, repository, path, revision)
        return self.scan(content=content)

    def test_icon_urls_encode_unicode_and_bound_transport_failures(self):
        response = MagicMock()
        response.__enter__.return_value = response
        response.url = "https://example.test/%E5%9B%BE.svg"
        response.headers.get_content_type.return_value = "image/svg+xml"
        response.read.return_value = b"<"
        cases = (("https://example.test/图.svg", "https://example.test/%E5%9B%BE.svg"),
                 ("https://例子.测试:443/图.svg", "https://xn--fsqu00a.xn--0zwm56d:443/%E5%9B%BE.svg"),
                 ("https://[2001:db8::1]:443/图.svg", "https://[2001:db8::1]:443/%E5%9B%BE.svg"))
        for url, expected in cases:
            with self.subTest(url=url), patch.object(profiles, "urlopen", return_value=response) as fetch:
                self.assertTrue(profiles.image_resolves(url))
                self.assertEqual(fetch.call_args.args[0].full_url, expected)
        for error in (InvalidURL("bad URL"), UnicodeEncodeError("ascii", "图", 0, 1, "non-ascii")):
            with self.subTest(error=type(error).__name__), patch.object(profiles, "urlopen", side_effect=error):
                with self.assertRaises(profiles.Unreadable):
                    profiles.image_resolves("https://example.test/icon.svg")
        with patch.object(profiles, "content", side_effect=self.content), \
             patch.object(profiles, "api", side_effect=self.api), \
             patch.object(profiles, "image_resolves", side_effect=profiles.Unreadable("unavailable icon")):
            profiles.inspect_profiles("example-team", self.repos, lambda *row: self.rows.append(row))
        self.assertTrue(any(row[0] == "REVIEW" and "unavailable icon" in row[2] for row in self.rows))
        self.assertTrue(any("release presence matches" in row[2] for row in self.rows))

    def test_complete_private_profile_has_verified_pin_membership_and_live_facts(self):
        images = self.scan()
        self.assertFalse([row for row in self.rows if row[0] in {"FAIL", "REVIEW"}], self.rows)
        self.assertTrue(any("workflow pin " in row[2] for row in self.rows))
        self.assertTrue(any("default branch development" in row[2] for row in self.rows))
        self.assertTrue(any('/.github/' + 'a' * 40 + '/assets/mark.svg' in call.args[0] for call in images.call_args_list))

    def test_missing_pyyaml_reports_owned_requirements(self):
        original_import = builtins.__import__
        def missing_pyyaml(name, *args, **kwargs):
            if name == "yaml":
                raise ImportError("No PyYAML installed")
            return original_import(name, *args, **kwargs)
        if find_spec("yaml") is None:
            self.scan()
        else:
            with patch("builtins.__import__", side_effect=missing_pyyaml):
                self.scan()
        reviews = [row[2] for row in self.rows if row[0] == "REVIEW"]
        self.assertEqual(len(reviews), 1, self.rows)
        self.assertIn("PyYAML", reviews[0])
        self.assertIn(str(Path(profiles.__file__).with_name("requirements.txt")), reviews[0])
        self.assertFalse(any(row[0] == "FAIL" or "workflow pin " + "a" * 40 in row[2] for row in self.rows))

    def test_workflow_pin_reads_yaml_callers(self):
        self.scan_workflows({".github/workflows/check.yaml": self.workflow})
        self.assertFalse([row for row in self.rows if row[0] in {"FAIL", "REVIEW"}], self.rows)
        self.assertTrue(any("workflow pin " + "a" * 40 in row[2] for row in self.rows))

    def test_workflow_pin_conflicts_name_all_files_and_shas(self):
        callers = {".github/workflows/check.yml": self.workflow,
                   ".github/workflows/check.yaml": self.workflow.replace("a" * 40, "b" * 40)}
        self.scan_workflows(callers)
        reviews = [row[2] for row in self.rows if row[0] == "REVIEW"]
        self.assertEqual(len(reviews), 1, self.rows)
        for value in [*callers, "a" * 40, "b" * 40, "conflicting"]:
            self.assertIn(value, reviews[0])

    def test_workflow_pin_shared_by_several_callers_is_one_observation(self):
        self.scan_workflows({".github/workflows/check.yml": self.workflow,
                             ".github/workflows/check.yaml": self.workflow})
        self.assertFalse([row for row in self.rows if row[0] in {"FAIL", "REVIEW"}], self.rows)
        self.assertEqual(sum("workflow pin " + "a" * 40 in row[2] for row in self.rows), 1)

    def test_workflow_pin_ignores_run_scalars_env_and_step_uses(self):
        target = "example-team/.github/.github/workflows/profile.yml@" + "a" * 40
        for workflow in (
            'jobs:\n  demo:\n    steps:\n      - run: \'echo "{uses: ' + target + '}"\'\n',
            'env:\n  uses: ' + target + '\njobs: {}\n',
            'jobs:\n  demo:\n    env:\n      uses: ' + target + '\n',
            'jobs:\n  demo:\n    steps:\n      - uses: ' + target + '\n',
        ):
            with self.subTest(workflow=workflow):
                for caller in (False, True):
                    with self.subTest(real_caller=caller):
                        self.rows = []
                        files = {".github/workflows/example.yml": workflow}
                        if caller:
                            files[".github/workflows/check.yml"] = self.workflow
                        self.scan_workflows(files)
                        if caller:
                            self.assertFalse([row for row in self.rows if row[0] in {"FAIL", "REVIEW"}], self.rows)
                        else:
                            self.assertTrue(any(row[0] == "REVIEW" and "no matching workflow caller" in row[2] for row in self.rows), self.rows)

    def test_invalid_workflow_yaml_is_review_naming_the_file(self):
        for workflow in ("jobs: [", "jobs: !!python/object:unexpected {}", "jobs: []"):
            with self.subTest(workflow=workflow):
                self.rows = []
                self.scan_workflows({".github/workflows/broken.yaml": workflow})
                self.assertTrue(any(row[0] == "REVIEW" and "broken.yaml" in row[2] for row in self.rows), self.rows)

    def test_workflow_pin_ignores_comments_and_block_scalar_examples(self):
        self.workflow = (
            '# uses: example-team/.github/.github/workflows/profile.yml@' + 'b' * 40 + '\n'
            'jobs:\n  example:\n    steps:\n      - run: |\n'
            '          uses: example-team/.github/.github/workflows/profile.yml@' + 'b' * 40 + '\n'
            '  profile:\n    uses: "example-team/.github/.github/workflows/profile.yml@' + 'a' * 40 + '"'
            ' # uses: example-team/.github/.github/workflows/profile.yml@' + 'b' * 40 + '\n')
        self.scan()
        self.assertFalse([row for row in self.rows if row[0] in {"FAIL", "REVIEW"}], self.rows)

    def test_absent_member_repository_is_optional_and_inaccessible_input_is_review(self):
        self.repos = [repo for repo in self.repos if repo["name"] != ".github-private"]
        self.scan()
        self.assertFalse(any(row[0] == "FAIL" for row in self.rows))
        self.assertTrue(any("optional" in row[2] for row in self.rows))
        self.setUp()
        def unreadable(*args):
            if args[1] == ".github-private":
                raise profiles.Unreadable("member input unreadable")
            return self.content(*args)
        self.scan(content=unreadable)
        self.assertIn(("REVIEW", ".github-private", "member input unreadable"), self.rows)

    def test_public_profile_requires_public_visibility(self):
        self.repos[0]["visibility"] = "private"
        self.scan()
        self.assertTrue(any(row[0] == "FAIL" and row[1] == ".github" and "visibility" in row[2] for row in self.rows))

    def test_internal_and_public_visibility_fail(self):
        for visibility in ("internal", "public"):
            with self.subTest(visibility=visibility):
                self.setUp()
                self.repos[1]["visibility"] = visibility
                self.scan()
                self.assertTrue(any(row[0] == "FAIL" and "visibility" in row[2] for row in self.rows))

    def test_inventory_excludes_archived_and_private_but_not_public_forks(self):
        self.repos.append(self.repo("fork"))
        self.repos[-1]["isFork"] = True
        self.scan()
        failures = [row for row in self.rows if row[0] == "FAIL"]
        self.assertEqual(len(failures), 1)
        self.assertIn("missing ['fork']", failures[0][2])

    def test_member_missing_and_extra_fail(self):
        for mutation in ("missing", "extra"):
            with self.subTest(mutation=mutation):
                self.setUp()
                if mutation == "missing":
                    del self.member["repositories"]["tool"]
                elif mutation == "extra":
                    self.member["repositories"]["other"] = {"default_branch": "development", "workflow": None, "releases": "none"}
                self.scan()
                self.assertTrue(any(row[0] == "FAIL" and "Invalid member input" in row[2] for row in self.rows))

    def test_valid_old_pin_still_fails_when_public_membership_has_changed(self):
        pinned_bytes = self.catalog_bytes
        new = deepcopy(self.catalog["groups"][0]["repositories"][0])
        new["name"] = "new"
        self.catalog["groups"][0]["repositories"].append(new)
        self.repos.append(self.repo("new"))
        self.catalog_bytes = json.dumps(self.catalog).encode()
        def content(*args):
            return pinned_bytes if args[3] == "a" * 40 else self.content(*args)
        self.scan(content=content)
        self.assertTrue(any(row[0] == "FAIL" and "pinned/current" in row[2] for row in self.rows))

    def test_missing_workflow_release_mismatch_and_broken_icon_fail(self):
        def api(endpoint):
            if "git/trees" in endpoint:
                return {"tree": [], "truncated": False}
            return []
        self.scan(api=api, icons=False)
        for message in ("is missing", "release presence differs", "icon resolution"):
            self.assertTrue(any(row[0] == "FAIL" and message in row[2] for row in self.rows), self.rows)

    def test_declared_branch_mismatch_is_reported_with_and_without_a_workflow(self):
        for name in ("library", "tool"):
            with self.subTest(repository=name):
                self.setUp()
                self.member["repositories"][name]["default_branch"] = "stable/next"
                self.scan()
                self.assertIn(("FAIL", name, "default branch: declared stable/next, GitHub reports development"), self.rows)
                self.assertTrue(any("release presence matches" in row[2] for row in self.rows))

    def test_unreadable_default_branch_is_review_without_a_workflow_request(self):
        self.repos[2]["defaultBranchRef"] = None
        self.scan()
        self.assertIn(("REVIEW", "library", "GitHub default branch is unreadable; branch/workflow facts not checked"), self.rows)
        self.assertFalse(any("declared workflow" in row[2] for row in self.rows))

    def test_verified_branch_with_slashes_is_encoded_for_workflow_lookup(self):
        self.repos[2]["defaultBranchRef"]["name"] = "stable/next"
        self.member["repositories"]["library"]["default_branch"] = "stable/next"
        def api(endpoint):
            if "git/trees/" in endpoint:
                self.assertIn("git/trees/stable%2Fnext?recursive=1", endpoint)
                return {"tree": [{"path": ".github/workflows/verify.yml", "type": "blob"}], "truncated": False}
            return self.api(endpoint)
        self.scan(api=api)
        self.assertFalse(any(row[0] in {"FAIL", "REVIEW"} for row in self.rows))

    def test_unreadable_or_truncated_online_evidence_is_review(self):
        def api(endpoint):
            if "git/trees" in endpoint:
                return {"tree": [], "truncated": True}
            raise profiles.Unreadable("rate limited")
        self.scan(api=api)
        self.assertFalse(any(row[0] == "FAIL" for row in self.rows))
        self.assertTrue(any("incomplete" in row[2] for row in self.rows))
        self.assertTrue(any("rate limited" in row[2] for row in self.rows))

    def test_published_prereleases_count_as_releases(self):
        def api(endpoint):
            if "library/releases" in endpoint:
                return [{"draft": False, "prerelease": True}]
            return self.api(endpoint)
        self.scan(api=api)
        self.assertFalse(any(row[0] in {"FAIL", "REVIEW"} for row in self.rows))

    def test_release_observation_paginates_and_ignores_drafts(self):
        def api(endpoint):
            if "library/releases" in endpoint:
                if "page=2" in endpoint:
                    return [{"draft": False, "prerelease": False}]
                return [{"draft": True, "prerelease": False}] * 100
            return self.api(endpoint)
        self.scan(api=api)
        self.assertFalse(any(row[0] in {"FAIL", "REVIEW"} for row in self.rows))


    def test_account_description_is_compared_only_when_declared(self):
        self.scan()
        self.assertFalse(any("account description" in row[2] for row in self.rows))
        for observed, status in (("Useful tools for careful work.", "INFO"), ("Something else", "FAIL")):
            with self.subTest(observed=observed):
                self.setUp()
                self.catalog["description"] = "Useful tools for careful work."
                self.catalog_bytes = json.dumps(self.catalog).encode()
                api = lambda endpoint: {"description": observed} if endpoint == "orgs/example-team" else self.api(endpoint)
                self.scan(api=api)
                rows = [row for row in self.rows if "account description" in row[2]]
                self.assertEqual([row[0] for row in rows], [status])
        self.setUp()
        self.catalog["description"] = "Useful tools for careful work."
        self.catalog_bytes = json.dumps(self.catalog).encode()
        def unreadable(endpoint):
            if endpoint == "orgs/example-team":
                raise profiles.Unreadable("organization unavailable")
            return self.api(endpoint)
        self.scan(api=unreadable)
        self.assertIn(("REVIEW", ".github", "Account description unavailable: organization unavailable"), self.rows)


    def test_workflow_pin_is_unknown_without_a_caller_or_with_conflicting_pins(self):
        for workflow in ("jobs: {}", "# uses: example-team/.github/.github/workflows/profile.yml@" + "a" * 40,
                         "jobs:\n  build:\n    steps:\n      - run: |\n          uses: example-team/.github/.github/workflows/profile.yml@" + "a" * 40,
                         self.workflow + "  other:\n    uses: example-team/.github/.github/workflows/profile.yml@" + "b" * 40):
            with self.subTest(workflow=workflow):
                self.workflow = workflow
                self.rows = []
                self.scan()
                self.assertTrue(any(row[0] == "REVIEW" and "pin unknown" in row[2] for row in self.rows), self.rows)

    def test_workflow_pin_accepts_quoted_yaml_but_rejects_branch_refs(self):
        self.workflow = 'jobs: {check: {uses: "example-team/.github/.github/workflows/profile.yml@' + 'a' * 40 + '"}}'
        self.scan()
        self.assertFalse(any(row[0] in {"FAIL", "REVIEW"} for row in self.rows), self.rows)
        self.workflow = self.workflow.replace('a' * 40, "master")
        self.rows = []
        self.scan()
        self.assertTrue(any(row[0] == "FAIL" and "full commit SHA" in row[2] for row in self.rows))

    def test_unreadable_workflow_tree_is_review(self):
        self.workflow_tree["truncated"] = True
        self.scan()
        self.assertTrue(any(row[0] == "REVIEW" and "workflow tree is incomplete" in row[2] for row in self.rows))

    def test_observation_uses_only_observed_fields_and_rejects_missing_structure(self):
        self.catalog["new_schema_field"] = "owned by the renderer"
        self.catalog["groups"][0]["repositories"][0]["kind"] = "library"
        self.catalog_bytes = json.dumps(self.catalog).encode()
        self.scan()
        self.assertFalse(any(row[0] in {"FAIL", "REVIEW"} for row in self.rows), self.rows)
        for target, field in ((self.catalog["organization"], "login"),
                              (self.catalog["groups"][0]["repositories"][0], "icon")):
            value = target.pop(field)
            self.catalog_bytes = json.dumps(self.catalog).encode()
            self.rows = []
            self.scan()
            self.assertTrue(any(row[0] == "FAIL" and "Invalid public catalog" in row[2] for row in self.rows))
            target[field] = value

    def test_unsafe_icon_urls_do_not_reach_the_network(self):
        for value in ("http://example.test/icon.svg", "//example.test/icon.svg", "../../../outside",
                      "https://user:password@example.test/icon.svg", "%2f%2fexample.test/icon.svg"):
            with self.subTest(value=value):
                self.catalog["mark"] = value
                self.catalog_bytes = json.dumps(self.catalog).encode()
                self.rows = []
                images = self.scan()
                self.assertFalse(images.called)
                self.assertTrue(any(row[0] == "FAIL" and "Invalid observed icon" in row[2] for row in self.rows))


if __name__ == "__main__":
    unittest.main()
