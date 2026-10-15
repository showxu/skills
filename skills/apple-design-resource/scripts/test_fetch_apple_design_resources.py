"""Regressions for previous-release discovery, archive downloads and the license gate, without network."""

import contextlib
import hashlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import fetch_apple_design_resources as adr

CDN = "https://devimages-cdn.apple.com/design/resources/download/"


class FakeResponse(io.BytesIO):
    def __init__(self, data, headers):
        super().__init__(data)
        self.headers = headers

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()


class PreviousReleaseTests(unittest.TestCase):
    def test_canonical_download_keeps_only_cdn_files(self):
        self.assertEqual(adr.canonical_download("http://devimages-cdn.apple.com/design/resources/download/A.dmg?x=1"),
                         CDN + "A.dmg")
        for url in ("https://example.com/design/resources/download/A.dmg",
                    "https://devimages-cdn.apple.com/other/A.dmg", CDN):
            self.assertIsNone(adr.canonical_download(url))

    def test_previous_releases_exclude_listed_and_unserved_files(self):
        listed = adr.LinkRecord(label="Sketch", url=CDN + "iOS-27-Design-Templates-Sketch.dmg", sections=[])
        index = "\n".join(CDN + name for name in (
            "iOS-27-Design-Templates-Sketch.dmg", "iOS-18-Production-Templates-Sketch.dmg",
            "SF-Symbols-7.dmg", "iOS-26-Icon-Templates-Photoshop-Illustrator.dmg", "Bezel-iPhone-15.dmg",
            "iOS-15-Production-Templates-Sketch.dmg"))
        gone = CDN + "iOS-15-Production-Templates-Sketch.dmg"
        with patch.object(adr, "fetch_text", return_value=index), \
                patch.object(adr, "probe_link", side_effect=lambda r, t: {"reachable": r.url != gone, "status": 200}):
            records, stats = adr.previous_records([listed], 10, 2)
        self.assertEqual(stats["candidates"], 5)
        self.assertEqual(stats["reachable"], 4)
        families = {r.label: r.resource_family for r in records}
        self.assertEqual(families, {"iOS 18 Production Templates Sketch": "design-template",
                                    "SF Symbols 7": "sf-symbols",
                                    "iOS 26 Icon Templates Photoshop Illustrator": "app-icon-template",
                                    "Bezel iPhone 15": "product-bezel"})
        self.assertTrue(all(r.sections == adr.PREVIOUS_SECTIONS and r.link_kind == "apple-cdn-download"
                            for r in records))

    def test_archive_path_mirrors_apple_folders_without_traversal(self):
        self.assertEqual(adr.archive_path(CDN + "app-store/creative_assets-templates.fig"),
                         Path("app-store/creative_assets-templates.fig"))
        self.assertEqual(adr.archive_path(CDN + "../x/a b.dmg"), Path("x/a-b.dmg"))


class ArchiveDownloadTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.archive = Path(temporary.name)
        self.data = b"disk image bytes"
        self.headers = {"etag": '"abc"', "last-modified": "Tue, 16 Jul 2024 04:30:04 GMT"}

    def record(self, name="iOS-18-Production-Templates-Sketch.dmg"):
        return adr.LinkRecord(label=name, url=CDN + name, sections=adr.PREVIOUS_SECTIONS,
                              link_kind="apple-cdn-download",
                              probe={"reachable": True, "content_length": str(len(self.data)), "etag": '"abc"'})

    def download(self, records):
        with patch.object(adr, "urlopen", side_effect=lambda *a, **k: FakeResponse(self.data, self.headers)) as fetch:
            adr.download_direct(records, self.archive, 1024, 10)
            adr.write_manifest(self.archive, records)
        return fetch.call_count

    def test_download_records_identity_and_manifest(self):
        record = self.record()
        self.assertEqual(self.download([record]), 1)
        self.assertEqual(record.download["sha256"], hashlib.sha256(self.data).hexdigest())
        self.assertEqual((record.download["etag"], record.download["file"]),
                         ('"abc"', "iOS-18-Production-Templates-Sketch.dmg"))
        self.assertEqual((self.archive / record.download["file"]).read_bytes(), self.data)
        self.assertFalse(list(self.archive.rglob("*.part")))
        manifest = json.loads((self.archive / "manifest.json").read_text())["files"]
        self.assertEqual([entry["url"] for entry in manifest], [record.url])
        self.assertNotIn(str(self.archive), json.dumps(manifest))

    def test_matching_archive_files_are_reused_and_changed_files_refetched(self):
        self.download([self.record()])
        again = self.record()
        self.assertEqual(self.download([again]), 0)
        self.assertTrue(again.download["reused"])
        (self.archive / "iOS-18-Production-Templates-Sketch.dmg").write_bytes(b"damaged bytes!!!")
        repaired = self.record()
        self.assertEqual(self.download([repaired]), 1)
        self.assertEqual((self.archive / "iOS-18-Production-Templates-Sketch.dmg").read_bytes(), self.data)

    def test_manifest_keeps_entries_from_earlier_runs(self):
        self.download([self.record()])
        self.download([self.record("SF-Symbols-7.dmg")])
        manifest = json.loads((self.archive / "manifest.json").read_text())["files"]
        self.assertEqual([entry["file"] for entry in manifest],
                         ["SF-Symbols-7.dmg", "iOS-18-Production-Templates-Sketch.dmg"])

    def test_oversized_files_are_skipped(self):
        record = self.record()
        record.probe["content_length"] = "4096"
        self.assertEqual(self.download([record]), 0)
        self.assertFalse(record.download["downloaded"])
        self.assertFalse((self.archive / "iOS-18-Production-Templates-Sketch.dmg").exists())


class LicenseGateTests(unittest.TestCase):
    def test_extraction_requires_explicit_license_acceptance(self):
        with self.assertRaises(SystemExit), contextlib.redirect_stderr(io.StringIO()):
            adr.parse_args(["--download-direct", "--extract-dmg"])
        args = adr.parse_args(["--download-direct", "--extract-dmg", "--accept-license"])
        self.assertTrue(args.accept_license)


if __name__ == "__main__":
    unittest.main()
