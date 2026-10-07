#!/usr/bin/env python3
"""Resolve Sketch Cloud share links and optionally download local .sketch files."""

from __future__ import annotations

import argparse
import json
import sys
import time
from collections import Counter
from pathlib import Path
from typing import Any

from sketch_cloud import (
    DEFAULT_GRAPHQL_URL,
    canonical_share_url,
    download_file,
    elapsed_since,
    parse_size,
    resolve_share,
    safe_filename,
    share_id_from_input,
    utc_now,
    write_json,
)


def build_record(
    input_value: str,
    *,
    graphql_url: str,
    output_dir: Path,
    resolve_only: bool,
    timeout: int,
    max_download_bytes: int,
    overwrite: bool,
) -> dict[str, Any]:
    started = time.time()
    share_id = share_id_from_input(input_value)
    record: dict[str, Any] = {
        "input": input_value,
        "share_id": share_id,
        "share_url": canonical_share_url(share_id),
        "status": "started",
    }
    try:
        resolved, download_url = resolve_share(share_id, graphql_url=graphql_url, timeout=timeout)
        record.update(resolved)
        document = record.get("document") or {}
        record["status"] = "resolved"
        if resolve_only:
            record["download"] = {"status": "skipped", "reason": "resolve-only"}
        elif not document.get("downloadAvailable"):
            record["download"] = {
                "status": "skipped",
                "reason": "download-not-available",
                "downloadUnavailableError": document.get("downloadUnavailableError"),
            }
        elif not download_url:
            record["download"] = {"status": "skipped", "reason": "download-url-missing"}
        else:
            filename = safe_filename(str(document.get("name") or record["share_id"]), record["share_id"])
            target_path = output_dir / filename
            record["download"] = download_file(
                download_url,
                target_path,
                timeout=timeout,
                max_download_bytes=max_download_bytes,
                overwrite=overwrite,
            )
            if record["download"].get("status") in {"downloaded", "exists"}:
                record["status"] = record["download"]["status"]
    except Exception as exc:
        record["status"] = "error"
        record["error"] = str(exc)
    record["elapsed_seconds"] = elapsed_since(started)
    return record


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inputs", nargs="*", help="Sketch Cloud share URLs or UUIDs.")
    parser.add_argument("--url", action="append", default=[], help="Sketch Cloud share URL or UUID. Repeatable.")
    parser.add_argument("--output-dir", required=True, help="Directory for manifest and downloaded .sketch files.")
    parser.add_argument("--manifest-name", default="manifest.json", help="Manifest filename inside output-dir.")
    parser.add_argument("--graphql-url", default=DEFAULT_GRAPHQL_URL, help="Sketch Cloud GraphQL endpoint.")
    parser.add_argument("--resolve-only", action="store_true", help="Resolve metadata without downloading the .sketch file.")
    parser.add_argument("--max-download-bytes", type=parse_size, default=500 * 1024 * 1024, help="Per-file download cap, e.g. 500MB.")
    parser.add_argument("--timeout", type=int, default=30, help="Network timeout in seconds.")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing downloaded .sketch files.")
    args = parser.parse_args(argv)
    args.urls = [*args.url, *args.inputs]
    if not args.urls:
        parser.error("provide at least one Sketch Cloud share URL or UUID")
    return args


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    output_dir = Path(args.output_dir).expanduser().resolve()
    shares = [
        build_record(
            value,
            graphql_url=args.graphql_url,
            output_dir=output_dir,
            resolve_only=args.resolve_only,
            timeout=args.timeout,
            max_download_bytes=args.max_download_bytes,
            overwrite=args.overwrite,
        )
        for value in args.urls
    ]
    counts = Counter(record.get("status", "unknown") for record in shares)
    manifest = {
        "schema": "sketch-design.cloud-manifest.v1",
        "created_at": utc_now(),
        "graphql_url": args.graphql_url,
        "output_dir": str(output_dir),
        "resolve_only": args.resolve_only,
        "max_download_bytes": args.max_download_bytes,
        "shares": shares,
        "counts": dict(sorted(counts.items())),
    }
    manifest_path = output_dir / args.manifest_name
    write_json(manifest_path, manifest)
    print(
        json.dumps(
            {
                "manifest": str(manifest_path),
                "counts": manifest["counts"],
                "downloads": [record.get("download", {}) for record in shares],
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 1 if counts.get("error") else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
