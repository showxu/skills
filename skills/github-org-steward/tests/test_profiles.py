"""Captured GitHub evidence for public/member profile acceptance."""

from copy import deepcopy
from http.client import InvalidURL
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

    def repo(self, name, visibility="public", archived=False, fork=False):
        return dict(name=name, visibility=visibility, isArchived=archived,
                    defaultBranchRef={"name": "development"}, isFork=fork)

    def content(self, owner, repository, path, revision):
        if repository == ".github" and path == "profile/catalog.json":
            self.assertEqual(revision, self.repos[0]["defaultBranchRef"]["name"])
            return self.catalog_bytes
        if repository == ".github-private":
            self.assertEqual(revision, self.repos[1]["defaultBranchRef"]["name"])
            self.assertEqual(path, "profile/member.json")
            return json.dumps(self.member).encode()
        self.fail(f"unexpected file request: {repository}/{path}")

    def api(self, endpoint):
        if "git/trees/development?recursive=1" in endpoint:
            return {"tree": [{"path": ".github/workflows/verify.yml", "type": "blob"}], "truncated": False}
        if "library/releases?" in endpoint:
            return [{"draft": False, "prerelease": False}]
        if "tool/releases?" in endpoint:
            return []
        self.fail(f"unexpected API request: {endpoint}")

    def scan(self, api=None, content=None, icons=True):
        with patch.object(profiles, "content", side_effect=content or self.content), \
             patch.object(profiles, "api", side_effect=api or self.api), \
             patch.object(profiles, "image_resolves", return_value=icons) as images:
            profiles.inspect_profiles("example-team", self.repos, lambda *row: self.rows.append(row))
        return images

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

    def test_current_member_dashboard_matches_default_branch_catalog_and_live_facts(self):
        self.repos[0]["defaultBranchRef"]["name"] = "standard/current"
        self.repos[1]["defaultBranchRef"]["name"] = "dashboard/current"
        images = self.scan()
        self.assertFalse([row for row in self.rows if row[0] in {"FAIL", "REVIEW"}], self.rows)
        self.assertIn(("INFO", ".github-private", "member dashboard membership matches current public catalog: 2 repositories"), self.rows)
        self.assertTrue(any("default branch development" in row[2] for row in self.rows))
        self.assertTrue(any('/.github/standard%2Fcurrent/assets/mark.svg' in call.args[0] for call in images.call_args_list))
        self.assertEqual(images.call_count, 3)

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

    def test_inventory_excludes_archived_private_and_fork_repositories(self):
        self.repos.append(self.repo("upstream", fork=True))
        self.scan()
        self.assertFalse([row for row in self.rows if row[0] in {"FAIL", "REVIEW"}], self.rows)
        self.assertIn(("INFO", ".github", "public catalog membership: 2 repositories match"), self.rows)

    def test_catalog_rejects_forks_even_when_dashboard_membership_matches(self):
        self.repos[3]["isFork"] = True
        self.scan()
        self.assertEqual([row for row in self.rows if row[0] == "FAIL"], [
            ("FAIL", ".github", "public catalog membership: missing [], extra ['tool']")])
        self.assertIn(("INFO", ".github-private", "member dashboard membership matches current public catalog: 2 repositories"), self.rows)

    def test_outdated_member_dashboard_needs_regeneration_against_current_catalog(self):
        for missing, extra in ((["new"], []), ([], ["tool"]), (["new"], ["tool"])):
            with self.subTest(missing=missing, extra=extra):
                self.setUp()
                catalog_repos = self.catalog["groups"][0]["repositories"]
                if missing:
                    new = deepcopy(catalog_repos[0])
                    new["name"] = "new"
                    catalog_repos.append(new)
                    self.repos.append(self.repo("new"))
                if extra:
                    catalog_repos[:] = [repo for repo in catalog_repos if repo["name"] != "tool"]
                    self.repos[3]["isArchived"] = True
                self.catalog_bytes = json.dumps(self.catalog).encode()
                self.scan()
                failures = [row for row in self.rows if row[0] == "FAIL"]
                self.assertEqual(failures, [("FAIL", ".github-private",
                    f"Member dashboard needs regeneration: membership differs from current public catalog; missing {missing}, extra {extra}")])
                self.assertTrue(any("release presence matches" in row[2] for row in self.rows))

    def test_invalid_member_structure_fails(self):
        for repositories in ([], {"library": {"workflow": None, "releases": "published"}}):
            with self.subTest(repositories=repositories):
                self.setUp()
                self.member["repositories"] = repositories
                self.scan()
                self.assertTrue(any(row[0] == "FAIL" and "Invalid member input" in row[2] for row in self.rows))

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
