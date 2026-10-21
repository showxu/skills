"""Upload verification with generated images and injected GraphQL/HTTP evidence."""

from contextlib import redirect_stderr, redirect_stdout
import hashlib
from io import BytesIO, StringIO
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch
from urllib.error import URLError

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import verify_upload as upload

OUTPUT = Path(os.environ["REPO_STEWARD_TEST_OUTPUT"])
OUTPUT.mkdir(parents=True, exist_ok=True)
PRIVATE_URL = "https://example.test/private-image?signature=private-value"


def png(image, **options):
    stream = BytesIO()
    image.save(stream, format="PNG", **options)
    return stream.getvalue()


def repository(**fields):
    return {"data": {"repository": {"id": "R_fixture", "nameWithOwner": "example/project",
                                  "usesCustomOpenGraphImage": True,
                                  "openGraphImageUrl": PRIVATE_URL, **fields}}}


def organization(**fields):
    return {"data": {"organization": {"login": "example", "avatarUrl": PRIVATE_URL, **fields}}}


class UploadTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=OUTPUT)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.image = self.root / "accepted.png"
        self.output = self.root / "receipt.json"
        self.local = Image.new("RGBA", (1280, 640), (30, 80, 120, 255))
        self.data = png(self.local)
        self.query = Mock(return_value=repository())
        self.fetch = Mock(return_value=self.data)
        self.sleep = Mock()
        for name in ("urlopen", "subprocess.run"):
            blocker = patch("verify_upload." + name, side_effect=AssertionError("unexpected network or CLI access"))
            blocker.start()
            self.addCleanup(blocker.stop)

    def run_check(self, mode="social-preview", *, query=None, fetch=None, target=None):
        self.image.write_bytes(self.data)
        option = "--repository" if mode == "social-preview" else "--organization"
        target = target or ("example/project" if mode == "social-preview" else "example")
        stdout, stderr = StringIO(), StringIO()
        with redirect_stdout(stdout), redirect_stderr(stderr):
            status = upload.main([mode, option, target, "--image", str(self.image),
                                  "--source-commit", "a" * 40, "--json", str(self.output)],
                                 query=query or self.query, fetch=fetch or self.fetch, sleep=self.sleep)
        receipt = json.loads(self.output.read_text())
        self.assertEqual(status, receipt["exit_status"])
        self.assertEqual(len(stdout.getvalue().splitlines()), 1)
        self.assertEqual(stderr.getvalue(), "")
        for text in (stdout.getvalue(), stderr.getvalue(), self.output.read_text()):
            self.assertNotIn(PRIVATE_URL, text)
            self.assertNotIn("private-value", text)
        return receipt

    def test_exact_social_preview_receipt_and_case_insensitive_identity(self):
        result = self.run_check(target="EXAMPLE/Project")
        self.assertEqual(result["state"], "pass")
        self.assertTrue(result["pixel_equal"])
        self.assertEqual(result["local"], result["served"])
        self.assertEqual(result["local"], {"sha256": hashlib.sha256(self.data).hexdigest(),
                                          "byte_length": len(self.data), "dimensions": [1280, 640]})
        self.assertEqual(result["graphql_id"], "R_fixture")
        self.assertEqual(result["source_commit"], "a" * 40)
        self.assertIn("+00:00", result["observed_at"])
        self.query.assert_called_once_with(upload.SOCIAL_QUERY, {"owner": "EXAMPLE", "name": "Project"})
        self.sleep.assert_not_called()

    def test_reencoded_social_preview_passes_with_distinct_byte_evidence(self):
        self.fetch.return_value = png(self.local.convert("RGB"), compress_level=0)
        result = self.run_check()
        self.assertEqual(result["exit_status"], 0)
        self.assertTrue(result["pixel_equal"])
        self.assertNotEqual(result["local"]["sha256"], result["served"]["sha256"])
        self.assertNotEqual(result["local"]["byte_length"], result["served"]["byte_length"])
        self.assertIn("re-encoded", result["observations"])

    def test_pixel_mismatch_uses_three_delayed_retries_and_fresh_urls(self):
        self.fetch.return_value = png(Image.new("RGBA", self.local.size, "white"))
        urls = [f"https://example.test/image-{index}" for index in range(4)]
        self.query.side_effect = [repository(openGraphImageUrl=url) for url in urls]
        result = self.run_check()
        self.assertEqual(result["exit_status"], 1)
        self.assertFalse(result["pixel_equal"])
        self.assertEqual(result["attempts"], 4)
        self.assertEqual([call.args[0] for call in self.fetch.call_args_list], urls)
        self.assertEqual([call.args for call in self.sleep.call_args_list], [(5,), (5,), (5,)])

    def test_stale_pixels_can_pass_on_a_fresh_graphql_attempt(self):
        self.fetch.side_effect = [png(Image.new("RGBA", self.local.size, "white")), self.data]
        result = self.run_check()
        self.assertEqual(result["exit_status"], 0)
        self.assertEqual(result["attempts"], 2)
        self.assertEqual(self.query.call_count, 2)
        self.sleep.assert_called_once_with(5)

    def test_rgba_comparison_includes_hidden_rgb_and_alpha(self):
        self.data = png(Image.new("RGBA", self.local.size, (0, 0, 0, 0)))
        for color in ((1, 0, 0, 0), (0, 0, 0, 1)):
            with self.subTest(color=color):
                self.fetch.return_value = png(Image.new("RGBA", self.local.size, color))
                self.assertEqual(self.run_check()["exit_status"], 1)

    def test_wrong_repository_and_default_preview_fail_without_fetching(self):
        for fields in ({"nameWithOwner": "another/project"}, {"usesCustomOpenGraphImage": False}):
            with self.subTest(fields=fields):
                self.query.return_value = repository(**fields)
                self.assertEqual(self.run_check()["exit_status"], 1)
        self.fetch.assert_not_called()
        self.sleep.assert_not_called()

    def test_wrong_local_or_served_dimensions_fail_without_retries(self):
        small = png(Image.new("RGBA", (640, 320), "white"))
        self.fetch.return_value = small
        result = self.run_check()
        self.assertEqual(result["exit_status"], 1)
        self.assertEqual(result["served"]["dimensions"], [640, 320])
        self.data = small
        self.query.reset_mock()
        self.assertEqual(self.run_check()["exit_status"], 1)
        self.query.assert_not_called()
        self.sleep.assert_not_called()

    def test_avatar_resized_and_reencoded_at_observed_psnr_passes(self):
        local = Image.new("RGB", (1024, 1024), (60, 90, 120))
        ImageDraw.Draw(local).rectangle((100, 200, 800, 900), fill=(130, 160, 190))
        self.data = png(local)
        served = local.resize((460, 460), Image.Resampling.BICUBIC).point(lambda value: value + 5)
        self.fetch.return_value = png(served)
        self.query.return_value = organization(login="EXAMPLE")
        result = self.run_check("avatar")
        self.assertEqual(result["exit_status"], 0)
        self.assertEqual(result["local"]["dimensions"], [1024, 1024])
        self.assertEqual(result["served"]["dimensions"], [460, 460])
        self.assertNotEqual(result["local"]["sha256"], result["served"]["sha256"])
        for value in result["psnr_db"].values():
            self.assertAlmostEqual(value, 20 * math.log10(255 / 5), places=6)
            self.assertTrue(33 <= value <= 37)
        self.query.assert_called_once_with(upload.AVATAR_QUERY, {"login": "example", "size": 1024})
        self.sleep.assert_not_called()

    def test_avatar_threshold_accepts_above_30_and_rejects_below(self):
        self.data = png(Image.new("RGBA", (32, 32), (100, 100, 100, 255)))
        self.query.return_value = organization()
        for difference, status in ((8, 0), (9, 1), (100, 1)):
            with self.subTest(difference=difference):
                level = 100 + difference
                self.fetch.return_value = png(Image.new("RGB", (16, 16), (level, level, level)))
                result = self.run_check("avatar")
                self.assertEqual(result["exit_status"], status)
                self.assertAlmostEqual(result["psnr_db"]["white"], 20 * math.log10(255 / difference))
        self.sleep.assert_not_called()

    def test_avatar_requires_both_backgrounds_and_exact_match_is_strict_json(self):
        self.query.return_value = organization()
        self.data = png(Image.new("RGBA", (32, 32), (0, 0, 0, 0)))
        for color, matching in (("black", "black"), ("white", "white")):
            with self.subTest(color=color):
                self.fetch.return_value = png(Image.new("RGB", (16, 16), color))
                result = self.run_check("avatar")
                self.assertEqual(result["exit_status"], 1)
                self.assertEqual(result["psnr_db"][matching], "infinity")
                self.assertEqual(result["psnr_db"]["white" if matching == "black" else "black"], 0)
        self.fetch.return_value = self.data
        result = self.run_check("avatar")
        self.assertEqual(result["exit_status"], 0)
        self.assertEqual(result["psnr_db"], {"white": "infinity", "black": "infinity"})
        self.assertNotIn("Infinity", self.output.read_text())

    def test_wrong_organization_fails(self):
        self.query.return_value = organization(login="another")
        self.assertEqual(self.run_check("avatar")["exit_status"], 1)
        self.fetch.assert_not_called()

    def test_missing_metadata_and_graphql_errors_are_unknown(self):
        for response in ({"errors": [{"message": PRIVATE_URL}]}, {"data": {"repository": None}},
                         repository(usesCustomOpenGraphImage=None), repository(openGraphImageUrl=None), []):
            with self.subTest(response=response):
                self.query.return_value = response
                self.assertEqual(self.run_check()["exit_status"], 2)
        self.fetch.assert_not_called()

    def test_cli_api_failure_missing_login_missing_cli_and_timeout_are_unknown(self):
        failures = [SimpleNamespace(returncode=1, stdout="", stderr=PRIVATE_URL),
                    SimpleNamespace(returncode=0, stdout="invalid " + PRIVATE_URL),
                    FileNotFoundError(PRIVATE_URL), subprocess.TimeoutExpired("gh", 30)]
        for failure in failures:
            with self.subTest(failure=type(failure).__name__):
                options = {"side_effect": failure} if isinstance(failure, Exception) else {"return_value": failure}
                with patch.object(upload.subprocess, "run", **options):
                    self.assertEqual(self.run_check(query=upload.graphql)["exit_status"], 2)

    def test_graphql_uses_existing_cli_login_and_typed_size(self):
        with patch.object(upload.subprocess, "run", return_value=SimpleNamespace(
                returncode=0, stdout=json.dumps(organization()))) as run:
            upload.graphql(upload.AVATAR_QUERY, {"login": "example", "size": 1024})
        self.assertEqual(run.call_args.args[0], ["gh", "api", "graphql", "-f", "query=" + upload.AVATAR_QUERY,
                                               "-f", "login=example", "-F", "size=1024"])
        self.assertTrue(run.call_args.kwargs["capture_output"])

    def test_private_image_network_failure_is_unknown_and_never_prints_url(self):
        with patch.object(upload, "urlopen", side_effect=URLError(PRIVATE_URL)):
            result = self.run_check(fetch=upload.fetch_image)
        self.assertEqual(result["exit_status"], 2)
        self.assertIn("unauthenticated image access", result["observations"][-1])
        self.assertIn("private repository", result["observations"][-1])
        self.sleep.assert_not_called()

    def test_fetch_has_no_credentials_and_rejects_embedded_credentials(self):
        response = BytesIO(self.data)
        with patch.object(upload, "urlopen", return_value=response) as fetch:
            self.assertEqual(self.run_check(fetch=upload.fetch_image)["exit_status"], 0)
        request = fetch.call_args.args[0]
        self.assertEqual(request.full_url, PRIVATE_URL)
        self.assertEqual({name.lower() for name, _ in request.header_items()}, {"user-agent"})
        with self.assertRaises(upload.Unreadable):
            upload.fetch_image("https://user:password@example.test/image")

    def test_undecodable_download_keeps_digest_but_is_unknown(self):
        self.fetch.return_value = b"not an image"
        result = self.run_check()
        self.assertEqual(result["exit_status"], 2)
        self.assertEqual(result["served"]["byte_length"], len(self.fetch.return_value))
        self.assertIsNone(result["served"]["dimensions"])
        self.assertIn("unauthenticated image access", result["observations"][-1])
        self.sleep.assert_not_called()

    def test_undecodable_local_image_is_unknown_without_network(self):
        self.data = b"not an image"
        self.assertEqual(self.run_check()["exit_status"], 2)
        self.query.assert_not_called()

    def test_api_failure_after_mismatch_does_not_reuse_old_served_evidence(self):
        self.fetch.return_value = png(Image.new("RGBA", self.local.size, "white"))
        self.query.side_effect = [repository(), {"errors": [{"message": PRIVATE_URL}]}]
        result = self.run_check()
        self.assertEqual(result["exit_status"], 2)
        self.assertEqual(result["attempts"], 2)
        self.assertIsNone(result["served"])
        self.assertIsNone(result["pixel_equal"])
        self.assertIn("RGBA pixel mismatch on attempt 1", result["observations"])


if __name__ == "__main__":
    unittest.main()
