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
LEGACY = "https://developer.apple.com/design/downloads/"


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
        self.assertEqual(adr.canonical_download("http://developer.apple.com:80/design/downloads/A.dmg"),
                         LEGACY + "A.dmg")
        for url in ("https://example.com/design/resources/download/A.dmg",
                    "https://devimages-cdn.apple.com/other/A.dmg", CDN, LEGACY + "sketch.rss"):
            self.assertIsNone(adr.canonical_download(url))

    def test_previous_releases_exclude_listed_and_unserved_files(self):
        listed = adr.LinkRecord(label="Sketch", url=CDN + "iOS-27-Design-Templates-Sketch.dmg", sections=[])
        index = "\n".join(CDN + name for name in (
            "iOS-27-Design-Templates-Sketch.dmg", "iOS-18-Production-Templates-Sketch.dmg",
            "SF-Symbols-7.dmg", "iOS-26-Icon-Templates-Photoshop-Illustrator.dmg", "Bezel-iPhone-15.dmg",
            "iOS-15-Production-Templates-Sketch.dmg"))
        gone = CDN + "iOS-15-Production-Templates-Sketch.dmg"
        with patch.object(adr, "fetch_text", side_effect=lambda url, timeout: index if "devimages" in url else ""), \
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

    def test_former_download_path_resolves_to_current_location_once(self):
        listed = adr.LinkRecord(label="Keynote", url=CDN + "iOS-13-Keynote.dmg", sections=[])
        indexes = {"devimages": CDN + "Glyph-ARKit.dmg",
                   "developer": "\n".join(LEGACY + n for n in ("iOS-13-Keynote.dmg", "Glyph-ARKit.dmg",
                                                               "Apple-iOS-14-Sketch-Library.dmg", "sketch.rss"))}
        redirects = {LEGACY + "iOS-13-Keynote.dmg": CDN + "iOS-13-Keynote.dmg",
                     LEGACY + "Glyph-ARKit.dmg": CDN + "Glyph-ARKit.dmg"}

        def probe(record, timeout):
            return {"reachable": True, "status": 200, "final_url": redirects.get(record.url, record.url)}
        with patch.object(adr, "fetch_text", side_effect=lambda url, t: next(v for k, v in indexes.items() if k in url)), \
                patch.object(adr, "probe_link", side_effect=probe):
            records, stats = adr.previous_records([listed], 10, 2)
        self.assertEqual(sorted(r.url for r in records),
                         sorted([CDN + "Glyph-ARKit.dmg", LEGACY + "Apple-iOS-14-Sketch-Library.dmg"]))
        self.assertEqual(stats["candidates"], 4)
        self.assertTrue(all(r.link_kind == "apple-cdn-download" for r in records))

    def test_sketch_library_feeds_add_their_disk_images(self):
        feed = ('<?xml version="1.0"?><rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">'
                '<channel><title>Apple tvOS UI</title><item><title>Apple tvOS UI</title>'
                f'<enclosure url="{CDN}Apple-Sketch-Library-tvOS-18.dmg" sparkle:version="12" length="8292110"/>'
                '</item></channel></rss>')
        library = adr.LinkRecord(
            label="Sketch", sections=["Apple Design Resources", "tvOS", "tvOS 18", "UI Kit"],
            url="sketch://add-library?url=https%3A%2F%2Fdeveloper.apple.com%2Fdesign%2Fdownloads%2Fsketch-tvOS.rss")
        adr.classify(library)
        listed = adr.LinkRecord(label="Sketch", url=CDN + "Other.dmg", sections=[])
        with patch.object(adr, "fetch_text", return_value=feed) as fetch:
            records = adr.library_records([library, listed], 10)
        fetch.assert_called_once_with(LEGACY + "sketch-tvOS.rss", 10)
        self.assertEqual([(r.url, r.label, r.sections[-1], r.link_kind, r.resource_family) for r in records],
                         [(CDN + "Apple-Sketch-Library-tvOS-18.dmg", "Apple tvOS UI Sketch Library 12", "UI Kit",
                           "apple-cdn-download", "ui-kit")])

    def test_previous_releases_follow_former_library_feeds(self):
        feed = ('<rss><channel><title>Apple iOS UI</title><item>'
                f'<enclosure url="{CDN}Apple-Sketch-Library-iOS-18.dmg"/></item></channel></rss>')
        pages = {"devimages": "", "developer": LEGACY + "sketch.rss", "sketch.rss": feed}

        def fetch(url, timeout):
            return next(v for k, v in sorted(pages.items(), key=lambda kv: -len(kv[0])) if k in url)
        with patch.object(adr, "fetch_text", side_effect=fetch), \
                patch.object(adr, "probe_link", side_effect=lambda r, t: {"reachable": True, "status": 200}):
            records, _ = adr.previous_records([], 10, 2)
        self.assertEqual([r.url for r in records], [CDN + "Apple-Sketch-Library-iOS-18.dmg"])

    def test_files_on_other_apple_hosts_are_direct_downloads(self):
        apple = adr.LinkRecord(label="Download version 2 for macOS", sections=["Apple Design Resources"],
                               url="https://itunespartner.apple.com/assets/downloads/Parallax%20Previewer.dmg")
        page = adr.LinkRecord(label="User Guide", sections=["Apple Design Resources"],
                              url="https://help.apple.com/itc/parallaxpreviewer/")
        other = adr.LinkRecord(label="Mirror", sections=["Apple Design Resources"], url="https://example.com/A.dmg")
        for record in (apple, page, other):
            adr.classify(record)
        self.assertEqual([apple.link_kind, page.link_kind, other.link_kind],
                         ["apple-cdn-download", "external", "external"])
        self.assertEqual(adr.archive_path(apple.url),
                         Path("itunespartner.apple.com/assets/downloads/Parallax-Previewer.dmg"))

    def test_archive_path_mirrors_apple_folders_without_traversal(self):
        self.assertEqual(adr.archive_path(CDN + "app-store/creative_assets-templates.fig"),
                         Path("app-store/creative_assets-templates.fig"))
        self.assertEqual(adr.archive_path(CDN + "../x/a b.dmg"), Path("x/a-b.dmg"))
        self.assertEqual(adr.archive_path(LEGACY + "Apple-iOS-14-Sketch-Library.dmg"),
                         Path("design-downloads/Apple-iOS-14-Sketch-Library.dmg"))


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

    def test_new_upstream_content_is_saved_beside_the_retained_version(self):
        self.download([self.record()])
        old = self.data
        self.data = b"updated disk image bytes"
        self.headers = {"etag": '"def"', "last-modified": "Wed, 01 Oct 2025 10:00:00 GMT"}
        update = self.record()
        update.probe.update({"content_length": str(len(self.data)), "etag": '"def"'})
        self.assertEqual(self.download([update]), 1)
        self.assertEqual((self.archive / "iOS-18-Production-Templates-Sketch.dmg").read_bytes(), old)
        self.assertEqual((self.archive / "iOS-18-Production-Templates-Sketch (2025-10-01).dmg").read_bytes(), self.data)
        entry = json.loads((self.archive / "manifest.json").read_text())["files"][0]
        self.assertEqual(entry["file"], "iOS-18-Production-Templates-Sketch (2025-10-01).dmg")
        self.assertEqual([v["sha256"] for v in entry["earlier_versions"]], [hashlib.sha256(old).hexdigest()])
        again = self.record()
        again.probe.update({"content_length": str(len(self.data)), "etag": '"def"'})
        self.assertEqual(self.download([again]), 0)
        self.assertTrue(again.download["reused"])
        self.assertEqual(len(json.loads((self.archive / "manifest.json").read_text())["files"][0]["earlier_versions"]), 1)

    def test_unknown_archive_files_are_never_replaced(self):
        (self.archive / "iOS-18-Production-Templates-Sketch.dmg").write_bytes(b"someone else's file")
        record = self.record()
        self.assertEqual(self.download([record]), 1)
        self.assertEqual((self.archive / "iOS-18-Production-Templates-Sketch.dmg").read_bytes(), b"someone else's file")
        self.assertEqual(record.download["file"], "iOS-18-Production-Templates-Sketch (2024-07-16).dmg")

    def test_manifest_keeps_fields_owned_by_other_tools(self):
        self.download([self.record()])
        path = self.archive / "manifest.json"
        data = json.loads(path.read_text())
        data["files"][0]["source"] = "archived elsewhere"
        path.write_text(json.dumps(data))
        self.download([self.record()])
        self.assertEqual(json.loads(path.read_text())["files"][0]["source"], "archived elsewhere")

    def test_oversized_files_are_skipped(self):
        record = self.record()
        record.probe["content_length"] = "4096"
        self.assertEqual(self.download([record]), 0)
        self.assertFalse(record.download["downloaded"])
        self.assertFalse((self.archive / "iOS-18-Production-Templates-Sketch.dmg").exists())


class ClassificationTests(unittest.TestCase):
    def test_technologies_section_rows_are_technology_templates(self):
        record = adr.LinkRecord(label="Sketch", sections=["Apple Design Resources", "Technologies", "Camera Control"],
                                url="https://sketch.com/s/a443d962-d989-4c5b-b1db-fb7fb3946995")
        adr.classify(record)
        self.assertEqual((record.link_kind, record.resource_family), ("sketch-cloud-share", "technology-template"))


class LicenseGateTests(unittest.TestCase):
    def test_extraction_requires_explicit_license_acceptance(self):
        with self.assertRaises(SystemExit), contextlib.redirect_stderr(io.StringIO()):
            adr.parse_args(["--download-direct", "--extract-dmg"])
        args = adr.parse_args(["--download-direct", "--extract-dmg", "--accept-license"])
        self.assertTrue(args.accept_license)


if __name__ == "__main__":
    unittest.main()
