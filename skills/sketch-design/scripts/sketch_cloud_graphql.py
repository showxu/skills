#!/usr/bin/env python3
"""Read-only Sketch Cloud GraphQL CLI for schema and document-side facts."""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Any

from sketch_cloud import (
    DEFAULT_GRAPHQL_URL,
    canonical_share_url,
    elapsed_since,
    fetch_document_index,
    fetch_token_export,
    introspect_schema,
    resolve_share,
    share_id_from_input,
    summarize_schema,
    utc_now,
    write_json,
    write_text,
)


DEFAULT_SHARE_URL = "https://www.sketch.com/s/f63aa308-1f82-498c-8019-530f3b846db9"


def share_id_arg(value: str) -> str:
    return share_id_from_input(value)


def ensure_output_dir(path: str | None, default_name: str) -> Path:
    output_dir = Path(path or f"/tmp/sketch-cloud-graphql-{default_name}").expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    return output_dir


def schema_markdown(summary: dict[str, Any]) -> str:
    counts = summary["counts"]
    roots = summary["root_types"]
    lines = [
        "# Sketch Cloud GraphQL Schema Summary",
        "",
        f"- Generated: `{summary['generated_at']}`",
        f"- Root query: `{roots.get('query')}`",
        f"- Root mutation: `{roots.get('mutation')}`",
        f"- Root subscription: `{roots.get('subscription')}`",
        f"- Types: `{counts['types']}`",
        f"- Object types: `{counts['object_types']}`",
        f"- Input types: `{counts['input_types']}`",
        f"- Enum types: `{counts['enum_types']}`",
        f"- Fields: `{counts['field_count']}`",
        "",
        "## Implemented Read-Only Segments",
        "",
    ]
    lines.extend(f"- {item}" for item in summary["implemented_read_only_segments"])
    lines.extend(["", "## Future Read-Only Segments", ""])
    lines.extend(f"- {item}" for item in summary["future_read_only_segments"])
    lines.extend(["", "## Excluded Segments", ""])
    lines.extend(f"- {item}" for item in summary["excluded_segments"])
    lines.extend(["", "## Top Object Types", ""])
    lines.extend(
        f"- `{item['name']}`: {item['field_count']} fields"
        for item in summary["top_object_types_by_fields"][:15]
    )
    lines.extend(["", "## Relevant Enums", ""])
    for name, values in summary["relevant_enums"].items():
        lines.append(f"- `{name}`: {', '.join(f'`{value}`' for value in values)}")
    lines.append("")
    return "\n".join(lines)


def command_schema(args: argparse.Namespace) -> int:
    started = time.time()
    output_dir = ensure_output_dir(args.output_dir, "schema")
    schema = introspect_schema(graphql_url=args.graphql_url, timeout=args.timeout)
    summary = summarize_schema(schema)
    summary["graphql_url"] = args.graphql_url
    summary["elapsed_seconds"] = elapsed_since(started)
    write_json(output_dir / "schema-summary.json", summary)
    write_text(output_dir / "schema-summary.md", schema_markdown(summary))
    if args.write_full_schema:
        write_json(output_dir / "schema.json", {"schema": "sketch-design.cloud-schema.v1", "created_at": utc_now(), "__schema": schema})
    print(json.dumps({"output_dir": str(output_dir), "counts": summary["counts"]}, indent=2, sort_keys=True))
    return 0


def command_share(args: argparse.Namespace) -> int:
    started = time.time()
    output_dir = ensure_output_dir(args.output_dir, "share")
    share_id = args.share_id
    resolved, _download_url = resolve_share(share_id, graphql_url=args.graphql_url, timeout=args.timeout)
    payload = {
        "schema": "sketch-design.cloud-share.v1",
        "created_at": utc_now(),
        "share_id": share_id,
        "share_url": canonical_share_url(share_id),
        "graphql_url": args.graphql_url,
        "share": resolved,
        "elapsed_seconds": elapsed_since(started),
    }
    write_json(output_dir / "share.json", payload)
    print(json.dumps({"output": str(output_dir / "share.json"), "document": resolved.get("document", {})}, indent=2, sort_keys=True))
    return 0


def command_index(args: argparse.Namespace) -> int:
    started = time.time()
    output_dir = ensure_output_dir(args.output_dir, "index")
    share_id = args.share_id
    data = fetch_document_index(
        share_id,
        page_limit=args.page_limit,
        frame_limit=args.frame_limit,
        component_limit=args.component_limit,
        graphql_url=args.graphql_url,
        timeout=args.timeout,
    )
    payload = {
        "schema": "sketch-design.cloud-document-index.v1",
        "created_at": utc_now(),
        "share_id": share_id,
        "share_url": canonical_share_url(share_id),
        "graphql_url": args.graphql_url,
        "limits": {
            "page_limit": args.page_limit,
            "frame_limit": args.frame_limit,
            "component_limit": args.component_limit,
        },
        "data": data,
        "elapsed_seconds": elapsed_since(started),
    }
    write_json(output_dir / "document-index.json", payload)
    document = (((data.get("share") or {}).get("version") or {}).get("document") or {})
    print(
        json.dumps(
            {
                "output": str(output_dir / "document-index.json"),
                "document": {
                    "name": document.get("name"),
                    "pageCount": document.get("pageCount"),
                    "frameCount": document.get("frameCount"),
                    "componentCount": document.get("componentCount"),
                },
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


def command_tokens(args: argparse.Namespace) -> int:
    started = time.time()
    output_dir = ensure_output_dir(args.output_dir, "tokens")
    token_types = [item.strip().upper() for item in args.token_types.split(",") if item.strip()]
    data = fetch_token_export(
        args.share_id,
        token_format=args.format,
        color_format=args.color_format,
        token_types=token_types,
        graphql_url=args.graphql_url,
        timeout=args.timeout,
    )
    payload = {
        "schema": "sketch-design.cloud-token-export.v1",
        "created_at": utc_now(),
        "share_id": args.share_id,
        "share_url": canonical_share_url(args.share_id),
        "graphql_url": args.graphql_url,
        "format": args.format,
        "color_format": args.color_format,
        "token_types": token_types,
        "data": data,
        "elapsed_seconds": elapsed_since(started),
    }
    write_json(output_dir / "token-export.json", payload)
    token_data = (((data.get("share") or {}).get("version") or {}).get("document") or {}).get("tokenExport", {}).get("data")
    if isinstance(token_data, str) and token_data:
        write_text(output_dir / "token-export.data", token_data)
    print(json.dumps({"output": str(output_dir / "token-export.json"), "data_bytes": len(token_data or "")}, indent=2, sort_keys=True))
    return 0


def add_common_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--graphql-url", default=DEFAULT_GRAPHQL_URL, help="Sketch Cloud GraphQL endpoint.")
    parser.add_argument("--timeout", type=int, default=30, help="Network timeout in seconds.")
    parser.add_argument("--output-dir", help="Output directory. Defaults to /tmp/sketch-cloud-graphql-<command>.")


def add_share_arg(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--url",
        dest="share_id",
        type=share_id_arg,
        default=share_id_from_input(DEFAULT_SHARE_URL),
        help="Sketch Cloud share URL or UUID.",
    )


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    schema_parser = subparsers.add_parser("schema", help="Introspect the Sketch Cloud GraphQL schema.")
    add_common_args(schema_parser)
    schema_parser.add_argument("--write-full-schema", action="store_true", help="Also write the raw introspection JSON.")
    schema_parser.set_defaults(func=command_schema)

    share_parser = subparsers.add_parser("share", help="Resolve stable share/version/document metadata.")
    add_common_args(share_parser)
    add_share_arg(share_parser)
    share_parser.set_defaults(func=command_share)

    index_parser = subparsers.add_parser("index", help="Fetch Cloud-side pages, frames, components, and downloadable assets.")
    add_common_args(index_parser)
    add_share_arg(index_parser)
    index_parser.add_argument("--page-limit", type=int, default=50)
    index_parser.add_argument("--frame-limit", type=int, default=50)
    index_parser.add_argument("--component-limit", type=int, default=50)
    index_parser.set_defaults(func=command_index)

    tokens_parser = subparsers.add_parser("tokens", help="Fetch Sketch Cloud token export data.")
    add_common_args(tokens_parser)
    add_share_arg(tokens_parser)
    tokens_parser.add_argument("--format", choices=["W3C", "CSS", "AMAZON"], default="W3C")
    tokens_parser.add_argument("--color-format", choices=["HEX", "HSLA", "RGBA"], default="HEX")
    tokens_parser.add_argument("--token-types", default="COLOR_VARIABLE,LAYER_STYLE,TEXT_STYLE")
    tokens_parser.set_defaults(func=command_tokens)

    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
