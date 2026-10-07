#!/usr/bin/env python3
"""Fetch and catalog official Apple Design Resources links."""

from __future__ import annotations

import argparse
import csv
import hashlib
import html
import json
import re
import shutil
import subprocess
import sys
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin, urlparse, urlsplit
from urllib.request import Request, urlopen


DEFAULT_SOURCE_URL = "https://developer.apple.com/design/resources/"
USER_AGENT = "Mozilla/5.0 (compatible; AppleDesignResourceSkill/1.0)"
DIRECT_EXTENSIONS = {
    ".ai",
    ".dmg",
    ".fig",
    ".icns",
    ".key",
    ".pdf",
    ".pkg",
    ".png",
    ".psd",
    ".sketch",
    ".svg",
    ".zip",
}


@dataclass
class LinkRecord:
    label: str
    url: str
    sections: list[str]
    source_line: int | None = None
    link_kind: str = ""
    resource_family: str = ""
    file_extension: str = ""
    direct_download: bool = False
    probe: dict[str, Any] = field(default_factory=dict)
    download: dict[str, Any] = field(default_factory=dict)


class DesignResourcesParser(HTMLParser):
    def __init__(self, base_url: str) -> None:
        super().__init__(convert_charrefs=False)
        self.base_url = base_url
        self.heading_stack: list[tuple[int, str]] = []
        self.current_heading: dict[str, Any] | None = None
        self.current_anchor: dict[str, Any] | None = None
        self.links: list[LinkRecord] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attrs_dict = dict(attrs)
        if tag in {"h1", "h2", "h3", "h4", "h5", "h6"}:
            self.current_heading = {"level": int(tag[1]), "parts": []}
        elif tag == "a" and attrs_dict.get("href"):
            self.current_anchor = {
                "href": attrs_dict["href"],
                "parts": [],
                "sections": [heading for _, heading in self.heading_stack],
                "line": self.getpos()[0],
            }

    def handle_endtag(self, tag: str) -> None:
        if tag in {"h1", "h2", "h3", "h4", "h5", "h6"} and self.current_heading:
            level = self.current_heading["level"]
            text = normalize_text(" ".join(self.current_heading["parts"]))
            if text:
                self.heading_stack = [(lv, title) for lv, title in self.heading_stack if lv < level]
                self.heading_stack.append((level, text))
            self.current_heading = None
        elif tag == "a" and self.current_anchor:
            label = normalize_text(" ".join(self.current_anchor["parts"])) or "(unlabeled)"
            href = html.unescape(str(self.current_anchor["href"]))
            url = urljoin(self.base_url, href)
            self.links.append(
                LinkRecord(
                    label=label,
                    url=url,
                    sections=list(self.current_anchor["sections"]),
                    source_line=self.current_anchor["line"],
                )
            )
            self.current_anchor = None

    def handle_data(self, data: str) -> None:
        if self.current_heading is not None:
            self.current_heading["parts"].append(data)
        if self.current_anchor is not None:
            self.current_anchor["parts"].append(data)

    def handle_entityref(self, name: str) -> None:
        self.handle_data(html.unescape(f"&{name};"))

    def handle_charref(self, name: str) -> None:
        self.handle_data(html.unescape(f"&#{name};"))


def normalize_text(value: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(value)).strip()


def fetch_text(url: str, timeout: int) -> str:
    request = Request(url, headers={"User-Agent": USER_AGENT})
    with urlopen(request, timeout=timeout) as response:
        charset = response.headers.get_content_charset() or "utf-8"
        return response.read().decode(charset, errors="replace")


def parse_links(page_html: str, source_url: str) -> list[LinkRecord]:
    parser = DesignResourcesParser(source_url)
    parser.feed(page_html)
    records = []
    seen: set[tuple[str, str, tuple[str, ...]]] = set()
    for link in parser.links:
        if not is_resource_link(link):
            continue
        classify(link)
        key = (link.url, link.label, tuple(link.sections))
        if key in seen:
            continue
        seen.add(key)
        records.append(link)
    return records


def is_resource_link(link: LinkRecord) -> bool:
    parsed = urlparse(link.url)
    section_text = " > ".join(link.sections)
    if "Apple Design Resources" not in link.sections:
        return False
    if "Developer Footer" in section_text:
        return False
    if parsed.scheme in {"sketch"}:
        return True
    if parsed.scheme not in {"http", "https"}:
        return False
    text = f"{link.label} {' '.join(link.sections)} {link.url}".lower()
    host = parsed.netloc.lower()
    if "developer.apple.com/design/resources" in link.url:
        return False
    if "devimages-cdn.apple.com" in host:
        return True
    if any(domain in host for domain in ("figma.com", "sketch.com")):
        return True
    resource_terms = (
        "download",
        "design guideline",
        "human-interface-guidelines",
        "fonts",
        "sf symbols",
        "icon composer",
        "product bezel",
        "badge",
        "logo",
        "template",
        "ui kit",
    )
    return "apple design resources" in text or any(term in text for term in resource_terms)


def classify(link: LinkRecord) -> None:
    parsed = urlparse(link.url)
    host = parsed.netloc.lower()
    path = parsed.path
    ext = Path(urlsplit(link.url).path).suffix.lower()
    text = f"{link.label} {' '.join(link.sections)} {link.url}".lower()

    if parsed.scheme == "sketch":
        link.link_kind = "sketch-library"
    elif "devimages-cdn.apple.com" in host:
        link.link_kind = "apple-cdn-download"
    elif "figma.com" in host:
        link.link_kind = "figma"
    elif "sketch.com" in host and re.search(r"/s/[0-9a-fA-F-]{36}(?:[/?#]|$)", path):
        link.link_kind = "sketch-cloud-share"
    elif "sketch.com" in host:
        link.link_kind = "sketch"
    elif "developer.apple.com" in host:
        link.link_kind = "apple-developer-page"
    else:
        link.link_kind = "external"

    if "product bezel" in text or "bezel" in text:
        family = "product-bezel"
    elif "badge" in text or "logo" in text or "glyph" in text:
        family = "badge-logo-glyph"
    elif "font" in text or "sf pro" in text or "sf compact" in text or "sf mono" in text or "new york" in text:
        family = "font"
    elif "sf symbol" in text:
        family = "sf-symbols"
    elif "icon composer" in text:
        family = "icon-composer"
    elif "app icon" in text:
        family = "app-icon-template"
    elif "technology" in text or any(term in text for term in ("apple pay", "app clips", "wallet", "siri", "tipkit", "airplay", "homekit", "arkit", "live activities", "messages", "tap to pay")):
        family = "technology-template"
    elif "ui kit" in text:
        family = "ui-kit"
    elif "template" in text:
        family = "design-template"
    elif any(platform in text for platform in ("ios", "ipados", "macos", "tvos", "watchos", "visionos")):
        family = "platform-resource"
    else:
        family = "resource-link"

    link.resource_family = family
    link.file_extension = ext
    link.direct_download = link.link_kind == "apple-cdn-download" or ext in DIRECT_EXTENSIONS


def probe_link(link: LinkRecord, timeout: int) -> dict[str, Any]:
    parsed = urlparse(link.url)
    if parsed.scheme not in {"http", "https"}:
        return {"reachable": None, "scheme": parsed.scheme, "note": "non-http link not probed"}

    for method in ("HEAD", "GET"):
        headers = {"User-Agent": USER_AGENT}
        if method == "GET":
            headers["Range"] = "bytes=0-0"
        request = Request(link.url, method=method, headers=headers)
        try:
            with urlopen(request, timeout=timeout) as response:
                return {
                    "reachable": 200 <= response.status < 400,
                    "method": method,
                    "status": response.status,
                    "final_url": response.geturl(),
                    "content_type": response.headers.get("content-type"),
                    "content_length": response.headers.get("content-length"),
                    "accept_ranges": response.headers.get("accept-ranges"),
                }
        except HTTPError as exc:
            if method == "HEAD" and exc.code in {403, 405, 501}:
                continue
            return {
                "reachable": False,
                "method": method,
                "status": exc.code,
                "error": str(exc),
                "content_type": exc.headers.get("content-type") if exc.headers else None,
                "content_length": exc.headers.get("content-length") if exc.headers else None,
            }
        except (TimeoutError, URLError, OSError) as exc:
            if method == "HEAD":
                continue
            return {"reachable": False, "method": method, "error": repr(exc)}

    return {"reachable": False, "error": "probe failed"}


def probe_links(records: list[LinkRecord], timeout: int, max_workers: int) -> None:
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_to_index = {executor.submit(probe_link, record, timeout): index for index, record in enumerate(records)}
        for future in as_completed(future_to_index):
            records[future_to_index[future]].probe = future.result()


def contains_all(value: str, needles: list[str] | None) -> bool:
    if not needles:
        return True
    lowered = value.lower()
    return all(needle.lower() in lowered for needle in needles)


def filter_records(records: list[LinkRecord], args: argparse.Namespace) -> list[LinkRecord]:
    resource_families = set(args.resource_family or [])
    link_kinds = set(args.link_kind or [])
    filtered: list[LinkRecord] = []
    for record in records:
        if resource_families and record.resource_family not in resource_families:
            continue
        if link_kinds and record.link_kind not in link_kinds:
            continue
        if not contains_all(" > ".join(record.sections), args.section_contains):
            continue
        if not contains_all(record.label, args.label_contains):
            continue
        filtered.append(record)
    return filtered


def safe_filename(link: LinkRecord, index: int) -> str:
    parsed = urlsplit(link.url)
    name = Path(parsed.path).name or f"resource-{index}"
    name = re.sub(r"[^A-Za-z0-9._-]+", "-", name).strip("-._")
    if not name:
        name = f"resource-{index}"
    if index:
        stem = Path(name).stem
        suffix = Path(name).suffix
        return f"{index:03d}-{stem}{suffix}"
    return name


def download_direct(records: list[LinkRecord], downloads_dir: Path, max_bytes: int, timeout: int) -> None:
    downloads_dir.mkdir(parents=True, exist_ok=True)
    for index, record in enumerate(records, start=1):
        if record.link_kind != "apple-cdn-download":
            continue
        status = record.probe or probe_link(record, timeout)
        length_value = status.get("content_length")
        if length_value and str(length_value).isdigit() and int(length_value) > max_bytes:
            record.download = {
                "downloaded": False,
                "reason": "content length exceeds max-download-bytes",
                "content_length": int(length_value),
                "max_download_bytes": max_bytes,
            }
            continue

        filename = safe_filename(record, index)
        output_path = downloads_dir / filename
        request = Request(record.url, headers={"User-Agent": USER_AGENT})
        digest = hashlib.sha256()
        total = 0
        try:
            with urlopen(request, timeout=timeout) as response, output_path.open("wb") as handle:
                while True:
                    chunk = response.read(1024 * 1024)
                    if not chunk:
                        break
                    total += len(chunk)
                    if total > max_bytes:
                        handle.close()
                        output_path.unlink(missing_ok=True)
                        record.download = {
                            "downloaded": False,
                            "reason": "download exceeded max-download-bytes",
                            "max_download_bytes": max_bytes,
                        }
                        break
                    digest.update(chunk)
                    handle.write(chunk)
                else:
                    pass
            if not record.download:
                record.download = {
                    "downloaded": True,
                    "path": str(output_path),
                    "bytes": total,
                    "sha256": digest.hexdigest(),
                }
        except (HTTPError, URLError, OSError, TimeoutError) as exc:
            output_path.unlink(missing_ok=True)
            record.download = {"downloaded": False, "error": repr(exc)}


def normalize_extensions(values: list[str] | None) -> set[str]:
    raw_values = values or [".png"]
    extensions = set()
    for value in raw_values:
        value = value.strip().lower()
        if not value:
            continue
        if not value.startswith("."):
            value = "." + value
        extensions.add(value)
    return extensions or {".png"}


def extract_downloaded_dmgs(
    records: list[LinkRecord],
    extract_dir: Path,
    extensions: set[str],
) -> None:
    extract_dir.mkdir(parents=True, exist_ok=True)
    mount_root = extract_dir / ".mounts"
    mount_root.mkdir(parents=True, exist_ok=True)

    for index, record in enumerate(records, start=1):
        download = record.download
        if not download.get("downloaded"):
            continue
        dmg_path = Path(str(download.get("path", "")))
        if dmg_path.suffix.lower() != ".dmg" or not dmg_path.exists():
            continue

        mountpoint = mount_root / f"{index:03d}-{dmg_path.stem}"
        destination = extract_dir / f"{index:03d}-{dmg_path.stem}"
        mountpoint.mkdir(parents=True, exist_ok=True)
        destination.mkdir(parents=True, exist_ok=True)
        extract_status: dict[str, Any] = {
            "extracted": False,
            "extensions": sorted(extensions),
            "path": str(destination),
            "files": 0,
        }

        attach = subprocess.run(
            [
                "hdiutil",
                "attach",
                "-nobrowse",
                "-readonly",
                "-mountpoint",
                str(mountpoint),
                str(dmg_path),
            ],
            input="Y\n",
            text=True,
            capture_output=True,
        )
        if attach.returncode != 0:
            extract_status["error"] = attach.stderr.strip() or attach.stdout.strip()
            download["extract"] = extract_status
            continue

        try:
            count = 0
            for source in mountpoint.rglob("*"):
                if not source.is_file() or source.suffix.lower() not in extensions:
                    continue
                relative = source.relative_to(mountpoint)
                target = destination / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, target)
                count += 1
            extract_status["extracted"] = True
            extract_status["files"] = count
        finally:
            subprocess.run(["hdiutil", "detach", str(mountpoint), "-force"], text=True, capture_output=True)
            try:
                mountpoint.rmdir()
            except OSError:
                pass
        download["extract"] = extract_status


def record_to_dict(record: LinkRecord) -> dict[str, Any]:
    return {
        "label": record.label,
        "url": record.url,
        "sections": record.sections,
        "link_kind": record.link_kind,
        "resource_family": record.resource_family,
        "file_extension": record.file_extension,
        "direct_download": record.direct_download,
        "source_line": record.source_line,
        "probe": record.probe,
        "download": record.download,
    }


def build_counts(records: list[LinkRecord]) -> dict[str, Any]:
    reachable = Counter()
    for record in records:
        value = record.probe.get("reachable") if record.probe else "not_probed"
        reachable[str(value)] += 1
    return {
        "total": len(records),
        "by_link_kind": dict(Counter(record.link_kind for record in records)),
        "by_resource_family": dict(Counter(record.resource_family for record in records)),
        "by_reachability": dict(reachable),
        "direct_download_candidates": sum(1 for record in records if record.link_kind == "apple-cdn-download"),
    }


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_csv(path: Path, records: list[LinkRecord]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "label",
                "url",
                "sections",
                "link_kind",
                "resource_family",
                "file_extension",
                "direct_download",
                "reachable",
                "status",
                "content_type",
                "content_length",
                "downloaded",
                "download_path",
            ],
            lineterminator="\n",
        )
        writer.writeheader()
        for record in records:
            writer.writerow(
                {
                    "label": record.label,
                    "url": record.url,
                    "sections": " > ".join(record.sections),
                    "link_kind": record.link_kind,
                    "resource_family": record.resource_family,
                    "file_extension": record.file_extension,
                    "direct_download": record.direct_download,
                    "reachable": record.probe.get("reachable", ""),
                    "status": record.probe.get("status", ""),
                    "content_type": record.probe.get("content_type", ""),
                    "content_length": record.probe.get("content_length", ""),
                    "downloaded": record.download.get("downloaded", ""),
                    "download_path": record.download.get("path", ""),
                }
            )


def markdown_table(counter: dict[str, int]) -> str:
    if not counter:
        return "_No rows._\n"
    lines = ["| Value | Count |", "| --- | ---: |"]
    for key, value in sorted(counter.items(), key=lambda item: (-item[1], item[0])):
        lines.append(f"| `{key}` | {value} |")
    return "\n".join(lines) + "\n"


def write_readme(path: Path, catalog: dict[str, Any]) -> None:
    counts = catalog["counts"]
    records = catalog["resources"]
    lines = [
        "# Apple Design Resources Catalog",
        "",
        f"- Source: {catalog['source_url']}",
        f"- Source SHA-256: `{catalog['source_sha256']}`",
        f"- Fetched at: `{catalog['fetched_at']}`",
        f"- Snapshot: `{catalog['snapshot_dir']}`",
        f"- Filters: `{json.dumps(catalog.get('filters', {}), sort_keys=True)}`",
        f"- Resources: {counts['total']}",
        f"- Direct Apple CDN candidates: {counts['direct_download_candidates']}",
        "",
        "## Link Kinds",
        "",
        markdown_table(counts["by_link_kind"]),
        "## Resource Families",
        "",
        markdown_table(counts["by_resource_family"]),
        "## Reachability",
        "",
        markdown_table(counts["by_reachability"]),
        "## Resources",
        "",
    ]
    for record in records:
        section = " > ".join(record["sections"]) or "Unsectioned"
        status = record.get("probe", {}).get("status", "")
        reachable = record.get("probe", {}).get("reachable", "")
        suffix = f" status={status}" if status else ""
        if reachable != "":
            suffix = f" reachable={reachable}{suffix}"
        lines.append(
            f"- `{record['resource_family']}` / `{record['link_kind']}`: "
            f"{record['label']} ({section}){suffix}\n  {record['url']}"
        )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def default_output_dir() -> Path:
    return Path(__file__).resolve().parents[1] / "references" / "generated"


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-url", default=DEFAULT_SOURCE_URL)
    parser.add_argument("--output-dir", type=Path, default=default_output_dir())
    parser.add_argument("--snapshot-name")
    parser.add_argument("--probe", action="store_true")
    parser.add_argument("--timeout", type=int, default=20)
    parser.add_argument("--max-workers", type=int, default=8)
    parser.add_argument("--resource-family", action="append", help="Include only this resource family; repeat for more.")
    parser.add_argument("--link-kind", action="append", help="Include only this link kind; repeat for more.")
    parser.add_argument("--section-contains", action="append", help="Include only rows whose section path contains this text.")
    parser.add_argument("--label-contains", action="append", help="Include only rows whose label contains this text.")
    parser.add_argument("--download-direct", action="store_true")
    parser.add_argument("--max-download-bytes", type=int, default=500 * 1024 * 1024)
    parser.add_argument("--extract-dmg", action="store_true", help="Extract matching files from downloaded DMGs.")
    parser.add_argument(
        "--extract-extension",
        action="append",
        help="Extension to extract from DMGs; repeat for more. Defaults to .png.",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    fetched_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    snapshot_name = args.snapshot_name or f"Apple-Design-Resources-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    snapshot_dir = args.output_dir / snapshot_name
    snapshot_dir.mkdir(parents=True, exist_ok=True)

    page_html = fetch_text(args.source_url, args.timeout)
    source_sha256 = hashlib.sha256(page_html.encode("utf-8")).hexdigest()
    records = parse_links(page_html, args.source_url)
    records = filter_records(records, args)
    if not records:
        print("No resource links found after filters.", file=sys.stderr)
        return 2

    if args.probe:
        probe_links(records, args.timeout, max(1, args.max_workers))

    if args.download_direct:
        download_direct(records, snapshot_dir / "downloads", args.max_download_bytes, args.timeout)

    if args.extract_dmg:
        if not args.download_direct:
            raise SystemExit("--extract-dmg requires --download-direct")
        extract_downloaded_dmgs(
            records,
            snapshot_dir / "extracted",
            normalize_extensions(args.extract_extension),
        )

    # Catalog paths resolve against the output root when shared between machines.
    for record in records:
        for detail in (record.download, record.download.get("extract", {})):
            if detail.get("path"):
                detail["path"] = str(Path(detail["path"]).relative_to(args.output_dir))

    catalog = {
        "source_url": args.source_url,
        "source_sha256": source_sha256,
        "fetched_at": fetched_at,
        "snapshot_dir": str(snapshot_dir.relative_to(args.output_dir)),
        "filters": {
            "resource_family": args.resource_family or [],
            "link_kind": args.link_kind or [],
            "section_contains": args.section_contains or [],
            "label_contains": args.label_contains or [],
        },
        "resources": [record_to_dict(record) for record in records],
        "counts": build_counts(records),
    }

    catalog_path = snapshot_dir / "catalog.json"
    links_path = snapshot_dir / "links.csv"
    readme_path = snapshot_dir / "README.md"
    index_path = snapshot_dir / "INDEX.md"
    write_json(catalog_path, catalog)
    write_csv(links_path, records)
    write_readme(readme_path, catalog)
    shutil.copyfile(readme_path, index_path)

    args.output_dir.mkdir(parents=True, exist_ok=True)
    write_json(args.output_dir / "latest-catalog.json", catalog)
    write_csv(args.output_dir / "latest-links.csv", records)
    write_readme(args.output_dir / "latest-README.md", catalog)

    print(
        json.dumps(
            {
                "source_url": args.source_url,
                "snapshot_dir": str(snapshot_dir),
                "resources": len(records),
                "counts": catalog["counts"],
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
