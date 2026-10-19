"""Profiles preserve catalog ownership, safe markup and deterministic bytes."""

from copy import deepcopy
import hashlib
from html import unescape
from html.parser import HTMLParser
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from urllib.parse import parse_qs, urlsplit

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import render_profile as profile

FIXTURES = Path(__file__).parent / "fixtures/profile"
OUTPUT = Path(os.environ["README_DESIGN_TEST_OUTPUT"])
OUTPUT.mkdir(parents=True, exist_ok=True)


class ProfileTests(unittest.TestCase):
    def setUp(self):
        self.catalog_bytes = (FIXTURES / "catalog.json").read_bytes()
        self.catalog = json.loads(self.catalog_bytes)
        self.member = json.loads((FIXTURES / "member.json").read_bytes())

    def render(self, member=False, spec=None):
        self.member["catalog"]["sha256"] = hashlib.sha256(self.catalog_bytes).hexdigest()
        return profile.render(self.catalog, spec or {}, self.member if member else None, self.catalog_bytes)

    def test_public_and_member_goldens(self):
        for member, name in ((False, "public"), (True, "member")):
            with self.subTest(mode=name):
                self.assertEqual(self.render(member).encode(), (FIXTURES / f"{name}.md").read_bytes())

    def test_check_is_read_only_and_detects_missing_content_and_byte_drift(self):
        for member in (False, True):
            with self.subTest(member=member), tempfile.TemporaryDirectory(dir=OUTPUT) as folder:
                output = Path(folder) / "README.md"
                cmd = [sys.executable, "-B", profile.__file__, "--catalog", str(FIXTURES / "catalog.json"), "--output", str(output)]
                if member:
                    cmd.extend(["--member", str(FIXTURES / "member.json")])
                self.assertNotEqual(subprocess.run(cmd + ["--check"], capture_output=True).returncode, 0)
                self.assertFalse(output.exists())
                subprocess.run(cmd, check=True, capture_output=True)
                original = output.read_bytes()
                subprocess.run(cmd + ["--check"], check=True, capture_output=True)
                subprocess.run(cmd, check=True, capture_output=True)
                self.assertEqual(output.read_bytes(), original)
                for drift in (b"handwritten", original.replace(b"\n", b"\r\n")):
                    output.write_bytes(drift)
                    checked = subprocess.run(cmd + ["--check"], capture_output=True)
                    self.assertNotEqual(checked.returncode, 0)
                    self.assertIn(b"differs from its inputs", checked.stderr)
                    self.assertEqual(output.read_bytes(), drift)

    def test_missing_and_extra_members_fail(self):
        for change, expected in (("missing", "missing.*example-library"), ("extra", "extra.*other")):
            with self.subTest(change=change):
                member = deepcopy(self.member)
                if change == "missing":
                    del member["repositories"]["example-library"]
                else:
                    member["repositories"]["other"] = {"default_branch": "development", "workflow": None, "releases": "none"}
                with self.assertRaisesRegex(ValueError, expected):
                    profile.render(self.catalog, {}, member, self.catalog_bytes)

    def test_pin_and_digest_are_required(self):
        for key, value, message in (("revision", "trunk", "full commit SHA"), ("sha256", "0" * 64, "digest")):
            with self.subTest(key=key):
                self.member["catalog"][key] = value
                with self.assertRaisesRegex(ValueError, message):
                    profile.render(self.catalog, {}, self.member, self.catalog_bytes)
                self.setUp()

    def test_hostile_text_remains_text_in_both_profiles(self):
        hostile = '<script>alert("x")</script> & [link](javascript:evil) **strong**'
        self.catalog["promise"] = self.catalog["secondary"] = self.catalog["organization"]["name"] = hostile
        self.catalog["groups"][0]["title"] = self.catalog["groups"][0]["repositories"][0]["outcome"] = hostile
        self.catalog["navigation"]["support"]["label"] = hostile
        self.catalog["maintainer"]["label"] = hostile
        self.member["maintenance"]["maintenance"]["label"] = hostile
        self.catalog["mark"] = 'https://example.test/mark.svg?title="onerror=evil"&x=1'
        class Tags(HTMLParser):
            def __init__(self):
                super().__init__()
                self.tags = []
            def handle_starttag(self, tag, attrs):
                self.tags.append((tag, dict(attrs)))
        for member in (False, True):
            value = self.render(member)
            parsed = Tags()
            parsed.feed(value)
            self.assertNotIn("script", [tag for tag, attrs in parsed.tags])
            self.assertFalse(any("onerror" in attrs for tag, attrs in parsed.tags))
            self.assertIn("&lt;script&gt;", value)
            self.assertIn("&amp;", value)
            self.assertIn("&quot;onerror=evil&quot;", value)

    def test_rejects_link_schemes_and_disguised_absolute_links(self):
        unsafe = ("http://example.test", "javascript:alert(1)", "data:image/png;base64,a", "file:///etc/passwd",
                  "//example.test/a", "\\\\example.test/a", "https://user:password@example.test/a", "https:",
                  "https://example.test/\nx", "https://example.test:bad/icon.svg", "https://example.test:99999/icon.svg", "java%73cript:alert(1)", "%2f%2fexample.test/a", "/root/path", "../../../outside", "%2e%2e/%2e%2e/outside")
        for value in unsafe:
            for target in ("mark", "row", "nav", "maintenance", "website", "maintainer"):
                with self.subTest(value=value, target=target):
                    self.setUp()
                    if target == "mark":
                        self.catalog["mark"] = value
                    elif target == "row":
                        self.catalog["groups"][0]["repositories"][0]["icon"] = {"light": "logo.svg", "dark": value}
                    elif target == "nav":
                        self.catalog["navigation"]["support"]["url"] = value
                    elif target == "maintenance":
                        self.member["maintenance"]["design"]["url"] = value
                    elif target == "website":
                        self.catalog["website"] = value
                    else:
                        self.catalog["maintainer"]["url"] = value
                    with self.assertRaises(ValueError):
                        self.render(True)

    def test_order_and_icons_are_catalog_owned(self):
        first = self.render(True)
        self.member["repositories"] = dict(reversed(list(self.member["repositories"].items())))
        self.assertEqual(self.render(True), first)
        for mode in (False, True):
            value = self.render(mode)
            self.assertLess(value.index('Build your project'), value.index('Distribute your work'))
            self.assertLess(value.index('example-library icon'), value.index('example-cli icon'))
            self.assertEqual(value.count(' icon"'), 3)
        self.assertIn('width="24"', first)
        self.assertIn('/.github/1111111111111111111111111111111111111111/assets/cli-dark.svg', first)
        self.assertIn('prefers-color-scheme: dark', first)

    def test_operational_fallbacks_searches_and_public_fallback(self):
        del self.catalog["website"]
        value = self.render(True)
        self.assertIn('https://github.com/example-team">Public profile', value)
        self.assertIn('example-distribution/actions">Actions', value)
        self.assertIn('example-cli/releases">Releases', value)
        self.assertIn('<td>—</td>', value)
        self.assertIn('example-library/releases"', value)
        self.assertIn('org%3Aexample-team', value)
        self.assertIn('author%3Aapp%2Fdependabot', value)
        self.assertNotIn('Maintained by', value)

    def test_ci_badges_use_each_declared_member_branch(self):
        class Images(HTMLParser):
            def __init__(self):
                super().__init__()
                self.sources = []
            def handle_starttag(self, tag, attrs):
                if tag == "img":
                    self.sources.append(dict(attrs)["src"])
        for branch in ("trunk", "stable/next", "release/候选&channel=beta"):
            with self.subTest(branch=branch):
                self.member["repositories"]["example-library"]["default_branch"] = branch
                parsed = Images()
                parsed.feed(self.render(True))
                badges = [urlsplit(url) for url in parsed.sources if "/actions/workflow/status/" in url]
                self.assertEqual(len(badges), 2)
                query = parse_qs(badges[0].query)
                self.assertEqual(query, {"branch": [branch], "style": ["flat"], "label": ["CI"]})
                self.assertEqual(parse_qs(badges[1].query)["branch"], ["stable/next"])
        self.assertNotIn("branch=", unescape(self.render()))

    def test_member_branch_is_required_even_without_a_workflow(self):
        for value in (None, "", " ", "trunk\nother"):
            with self.subTest(value=value):
                self.member["repositories"]["example-distribution"]["default_branch"] = value
                with self.assertRaises(ValueError):
                    self.render(True)
        del self.member["repositories"]["example-distribution"]["default_branch"]
        with self.assertRaisesRegex(ValueError, "missing fields.*default_branch"):
            self.render(True)

    def test_design_tokens_override_documented_defaults(self):
        values = dict(public_header_icon_size=120, member_header_icon_size=60,
                      public_row_icon_size=36, member_row_icon_size=20, badge_style="flat-square")
        self.assertIn('width="120"', self.render(spec=values))
        self.assertIn('width="36"', self.render(spec=values))
        self.assertIn('width="60"', self.render(True, values))
        self.assertIn('width="20"', self.render(True, values))
        self.assertIn('style=flat-square', self.render(True, values))
        for invalid in ({"member_row_icon_size": 0}, {"public_header_icon_size": True}, {"badge_style": '"evil'}, {"unknown": 1}):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                self.render(True, invalid)

    def test_duplicate_json_keys_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "Duplicate JSON field"):
            profile.load_json('{"repositories": {"tool": {}, "tool": {}}}')

    def test_relative_paths_cannot_escape_and_encoded_spaces_resolve(self):
        self.catalog["mark"] = "../assets/family%20mark.svg"
        value = self.render(True)
        self.assertIn('/assets/family%20mark.svg', value)
        self.assertNotIn('/assets/family%2520mark.svg', value)
        self.assertEqual(profile.catalog_url("#section", self.catalog, "a" * 40),
                         'https://github.com/example-team/.github/blob/' + 'a' * 40 + '/profile/README.md#section')

    def test_duplicate_members_and_unowned_operational_fields_fail(self):
        self.catalog["groups"][0]["repositories"].append(deepcopy(self.catalog["groups"][0]["repositories"][0]))
        with self.assertRaisesRegex(ValueError, "Duplicate"):
            self.render()
        self.setUp()
        self.member["repositories"]["example-library"]["status"] = "green"
        with self.assertRaisesRegex(ValueError, "unknown fields.*status"):
            self.render(True)
        self.setUp()
        self.member["groups"] = []
        with self.assertRaisesRegex(ValueError, "unknown fields.*groups"):
            self.render(True)


if __name__ == "__main__":
    unittest.main()
