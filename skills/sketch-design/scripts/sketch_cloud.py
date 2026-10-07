"""Shared Sketch Cloud GraphQL helpers for sketch-design scripts."""

from __future__ import annotations

import hashlib
import json
import re
import time
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import Request, urlopen


DEFAULT_GRAPHQL_URL = "https://graphql.sketch.cloud/api"
USER_AGENT = "Mozilla/5.0 (compatible; SketchDesignSkill/1.0)"
SHARE_ID_RE = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
SHARE_PATH_RE = re.compile(r"/s/([0-9a-fA-F-]{36})(?:[/?#]|$)")

SHARE_DOWNLOAD_QUERY = """
query getShareDownload($id: UUID!) {
  share(id: $id) {
    identifier
    name
    publicUrl
    userCanInspect
    publicInspectEnabled
    version(preferredState: PROCESSED) {
      identifier
      shortId
      kind
      document {
        identifier
        name
        url
        downloadAvailable
        downloadUnavailableError
        userCanOpenInApp
        size
        sketchVersion
        pageCount
        frameCount
        documentVersion
        uuid
      }
    }
  }
}
"""

SCHEMA_QUERY = """
query SketchCloudSchema {
  __schema {
    queryType { name }
    mutationType { name }
    subscriptionType { name }
    types {
      kind
      name
      fields {
        name
        args {
          name
          type { kind name ofType { kind name ofType { kind name ofType { kind name } } } }
        }
        type { kind name ofType { kind name ofType { kind name ofType { kind name } } } }
      }
      inputFields {
        name
        type { kind name ofType { kind name ofType { kind name ofType { kind name } } } }
      }
      enumValues { name }
    }
  }
}
"""

DOCUMENT_INDEX_QUERY = """
query SketchCloudDocumentIndex($id: UUID!, $pageLimit: Int!, $frameLimit: Int!, $componentLimit: Int!) {
  share(id: $id) {
    identifier
    name
    publicUrl
    userCanInspect
    publicInspectEnabled
    version(preferredState: PROCESSED) {
      identifier
      shortId
      kind
      document {
        identifier
        name
        size
        sketchVersion
        documentVersion
        pageCount
        frameCount
        downloadAvailable
        downloadUnavailableError
        userCanOpenInApp
        componentCount {
          symbol
          textStyle
          layerStyle
          colorVar
        }
        pages(limit: $pageLimit) {
          entries {
            identifier
            uuid
            name
            order
            annotationCount
            hasUnreadComments
          }
          meta {
            before
            after
            limit
            totalCount
          }
        }
        frames(limit: $frameLimit, filter: ALL) {
          entries {
            identifier
            uuid
            name
            order
            documentOrder
            width
            height
            isFlowHome
            hasMissingFonts
            page {
              identifier
              uuid
              name
              order
            }
            files {
              identifier
              type
              width
              height
              scale
              size
            }
          }
          meta {
            before
            after
            limit
            totalCount
          }
        }
        symbols: components(limit: $componentLimit, type: SYMBOL) {
          entries {
            ... on Symbol {
              identifier
              uuid
              name
              path
              depth
              description
            }
          }
          meta { before after limit totalCount }
          status
        }
        textStyles: components(limit: $componentLimit, type: TEXT_STYLE) {
          entries {
            ... on TextStyle {
              identifier
              uuid
              name
              path
              depth
              description
              horizontalAlignment
              font {
                name
                size
                weight
              }
            }
          }
          meta { before after limit totalCount }
          status
        }
        layerStyles: components(limit: $componentLimit, type: LAYER_STYLE) {
          entries {
            ... on LayerStyle {
              identifier
              uuid
              name
              path
              depth
              description
              needsContrastingBackground
            }
          }
          meta { before after limit totalCount }
          status
        }
        colorVariables: components(limit: $componentLimit, type: COLOR_VARIABLE) {
          entries {
            ... on ColorVariable {
              identifier
              uuid
              name
              path
              depth
              description
              needsContrastingBackground
              rgbaValue {
                red
                green
                blue
                alpha
              }
            }
          }
          meta { before after limit totalCount }
          status
        }
        downloadableAssets {
          identifier
          fileName
          fileSizeInBytes
          formats
          scales
          layerUuids
          status
        }
      }
    }
  }
}
"""

TOKEN_EXPORT_QUERY = """
query SketchCloudTokenExport($id: UUID!, $format: TokenExportFormat!, $colorFormat: TokenColorFormat!, $tokenTypes: [ExportableComponentType]!) {
  share(id: $id) {
    identifier
    name
    version(preferredState: PROCESSED) {
      identifier
      document {
        identifier
        name
        tokenExport(format: $format, colorFormat: $colorFormat, tokenTypes: $tokenTypes) {
          data
        }
      }
    }
  }
}
"""


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def parse_size(value: str) -> int:
    match = re.fullmatch(r"\s*(\d+(?:\.\d+)?)\s*([kmgt]?b?)?\s*", value, re.IGNORECASE)
    if not match:
        raise ValueError(f"invalid byte size: {value}")
    number = float(match.group(1))
    suffix = (match.group(2) or "").lower()
    multiplier = {
        "": 1,
        "b": 1,
        "k": 1024,
        "kb": 1024,
        "m": 1024**2,
        "mb": 1024**2,
        "g": 1024**3,
        "gb": 1024**3,
        "t": 1024**4,
        "tb": 1024**4,
    }[suffix]
    return int(number * multiplier)


def share_id_from_input(value: str) -> str:
    candidate = value.strip()
    if SHARE_ID_RE.fullmatch(candidate):
        return candidate.lower()
    parsed = urlparse(candidate)
    if parsed.scheme in {"http", "https"} and parsed.netloc.endswith("sketch.com"):
        match = SHARE_PATH_RE.search(parsed.path)
        if match and SHARE_ID_RE.fullmatch(match.group(1)):
            return match.group(1).lower()
    raise ValueError(f"not a Sketch Cloud share URL or UUID: {value}")


def canonical_share_url(share_id: str) -> str:
    return f"https://www.sketch.com/s/{share_id}"


def request_json(url: str, payload: dict[str, Any], timeout: int) -> dict[str, Any]:
    body = json.dumps(payload).encode("utf-8")
    request = Request(
        url,
        data=body,
        headers={
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Origin": "https://www.sketch.com",
            "Referer": "https://www.sketch.com/",
            "User-Agent": USER_AGENT,
        },
    )
    try:
        with urlopen(request, timeout=timeout) as response:
            raw = response.read()
    except HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")[:500]
        raise RuntimeError(f"GraphQL HTTP {exc.code}: {detail}") from exc
    except URLError as exc:
        raise RuntimeError(f"GraphQL request failed: {exc}") from exc
    try:
        data = json.loads(raw.decode("utf-8"))
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"GraphQL response was not JSON: {exc}") from exc
    if data.get("errors"):
        raise RuntimeError(f"GraphQL errors: {json.dumps(data['errors'], ensure_ascii=False)[:1200]}")
    return data


def graphql_query(
    query: str,
    *,
    variables: dict[str, Any] | None = None,
    operation_name: str | None = None,
    graphql_url: str = DEFAULT_GRAPHQL_URL,
    timeout: int = 30,
) -> dict[str, Any]:
    payload: dict[str, Any] = {"query": query, "variables": variables or {}}
    if operation_name:
        payload["operationName"] = operation_name
    return request_json(graphql_url, payload, timeout)


def pick(source: dict[str, Any], keys: list[str]) -> dict[str, Any]:
    return {key: source.get(key) for key in keys if key in source}


def resolve_share(share_id: str, graphql_url: str = DEFAULT_GRAPHQL_URL, timeout: int = 30) -> tuple[dict[str, Any], str | None]:
    response = graphql_query(
        SHARE_DOWNLOAD_QUERY,
        variables={"id": share_id},
        operation_name="getShareDownload",
        graphql_url=graphql_url,
        timeout=timeout,
    )
    share = ((response.get("data") or {}).get("share") or {})
    if not share:
        raise RuntimeError(f"share not found or not accessible: {share_id}")
    version = share.get("version") or {}
    document = version.get("document") or {}
    download_url = document.get("url")
    sanitized = {
        "share": pick(
            share,
            ["identifier", "name", "publicUrl", "userCanInspect", "publicInspectEnabled"],
        ),
        "version": pick(version, ["identifier", "shortId", "kind"]),
        "document": pick(
            document,
            [
                "identifier",
                "name",
                "downloadAvailable",
                "downloadUnavailableError",
                "userCanOpenInApp",
                "size",
                "sketchVersion",
                "pageCount",
                "frameCount",
                "documentVersion",
                "uuid",
            ],
        ),
        "download_url_omitted": bool(download_url),
    }
    return sanitized, download_url


def fetch_document_index(
    share_id: str,
    *,
    page_limit: int = 50,
    frame_limit: int = 50,
    component_limit: int = 50,
    graphql_url: str = DEFAULT_GRAPHQL_URL,
    timeout: int = 30,
) -> dict[str, Any]:
    response = graphql_query(
        DOCUMENT_INDEX_QUERY,
        variables={
            "id": share_id,
            "pageLimit": page_limit,
            "frameLimit": frame_limit,
            "componentLimit": component_limit,
        },
        operation_name="SketchCloudDocumentIndex",
        graphql_url=graphql_url,
        timeout=timeout,
    )
    return response.get("data") or {}


def fetch_token_export(
    share_id: str,
    *,
    token_format: str = "W3C",
    color_format: str = "HEX",
    token_types: list[str] | None = None,
    graphql_url: str = DEFAULT_GRAPHQL_URL,
    timeout: int = 30,
) -> dict[str, Any]:
    response = graphql_query(
        TOKEN_EXPORT_QUERY,
        variables={
            "id": share_id,
            "format": token_format,
            "colorFormat": color_format,
            "tokenTypes": token_types or ["COLOR_VARIABLE", "LAYER_STYLE", "TEXT_STYLE"],
        },
        operation_name="SketchCloudTokenExport",
        graphql_url=graphql_url,
        timeout=timeout,
    )
    return response.get("data") or {}


def introspect_schema(*, graphql_url: str = DEFAULT_GRAPHQL_URL, timeout: int = 30) -> dict[str, Any]:
    response = graphql_query(
        SCHEMA_QUERY,
        operation_name="SketchCloudSchema",
        graphql_url=graphql_url,
        timeout=timeout,
    )
    schema = (response.get("data") or {}).get("__schema")
    if not schema:
        raise RuntimeError("GraphQL introspection returned no schema")
    return schema


def type_name(type_ref: dict[str, Any] | None) -> str:
    if not type_ref:
        return ""
    if type_ref.get("name"):
        return str(type_ref["name"])
    inner = type_name(type_ref.get("ofType"))
    kind = type_ref.get("kind")
    if kind == "LIST":
        return f"[{inner}]"
    if kind == "NON_NULL":
        return f"{inner}!"
    return str(kind or inner)


def summarize_schema(schema: dict[str, Any]) -> dict[str, Any]:
    types = [item for item in schema.get("types", []) if item.get("name")]
    object_types = [item for item in types if item.get("kind") == "OBJECT"]
    input_types = [item for item in types if item.get("kind") == "INPUT_OBJECT"]
    enum_types = [item for item in types if item.get("kind") == "ENUM"]
    field_count = sum(len(item.get("fields") or []) for item in types)
    types_by_name = {item["name"]: item for item in types}

    def root_fields(root_name: str | None) -> list[dict[str, Any]]:
        if not root_name:
            return []
        root = types_by_name.get(root_name) or {}
        fields = []
        for field in root.get("fields") or []:
            fields.append(
                {
                    "name": field["name"],
                    "return_type": type_name(field.get("type")),
                    "args": [
                        {"name": arg["name"], "type": type_name(arg.get("type"))}
                        for arg in field.get("args") or []
                    ],
                }
            )
        return fields

    relevant_enum_names = [
        "ComponentFilterType",
        "TokenExportFormat",
        "TokenColorFormat",
        "ExportableComponentType",
        "PreferredVersionState",
        "FileType",
        "FrameFilterType",
        "DocumentDownloadUnavailableError",
    ]
    relevant_type_names = [
        "Share",
        "Version",
        "Document",
        "Page",
        "Frame",
        "Artboard",
        "Component",
        "Symbol",
        "TextStyle",
        "LayerStyle",
        "ColorVariable",
        "DownloadableAsset",
        "File",
        "TokenExport",
        "InspectorDataPayload",
    ]
    return {
        "schema": "sketch-design.cloud-schema-summary.v1",
        "generated_at": utc_now(),
        "root_types": {
            "query": (schema.get("queryType") or {}).get("name"),
            "mutation": (schema.get("mutationType") or {}).get("name"),
            "subscription": (schema.get("subscriptionType") or {}).get("name"),
        },
        "counts": {
            "types": len(types),
            "object_types": len(object_types),
            "input_types": len(input_types),
            "enum_types": len(enum_types),
            "field_count": field_count,
        },
        "top_object_types_by_fields": sorted(
            [
                {"name": item["name"], "field_count": len(item.get("fields") or [])}
                for item in object_types
            ],
            key=lambda item: item["field_count"],
            reverse=True,
        )[:30],
        "root_query_fields": root_fields((schema.get("queryType") or {}).get("name")),
        "root_mutation_field_count": len(root_fields((schema.get("mutationType") or {}).get("name"))),
        "root_subscription_field_count": len(root_fields((schema.get("subscriptionType") or {}).get("name"))),
        "relevant_enums": {
            name: [value["name"] for value in (types_by_name.get(name) or {}).get("enumValues") or []]
            for name in relevant_enum_names
            if name in types_by_name
        },
        "relevant_types": {
            name: [
                {
                    "name": field["name"],
                    "return_type": type_name(field.get("type")),
                    "args": [
                        {"name": arg["name"], "type": type_name(arg.get("type"))}
                        for arg in field.get("args") or []
                    ],
                }
                for field in (types_by_name.get(name) or {}).get("fields") or []
            ]
            for name in relevant_type_names
            if name in types_by_name
        },
        "implemented_read_only_segments": [
            "schema-summary",
            "share-document-download-metadata",
            "document-index-pages-frames-components-assets",
            "token-export-data",
        ],
        "future_read_only_segments": [
            "paginated full pages/frames/components traversal",
            "frame/artboard file render manifest and visual-reference download",
            "inspectorData snapshot for public inspectable frames/components/pages",
            "version history and revision index",
            "comments and annotations read-only export",
            "curated Sketch libraries/templates discovery",
            "authenticated workspace/project/share inventory when credentials are available",
            "schema drift diff against previous snapshots",
        ],
        "excluded_segments": [
            "mutations",
            "subscriptions as production dependency",
            "private workspace writes",
            "Cloud metadata as replacement for local .sketch ZIP/JSON parsing",
        ],
    }


def safe_filename(value: str, fallback: str) -> str:
    cleaned = re.sub(r"[\\/:*?\"<>|\x00-\x1f]", " ", value).strip()
    cleaned = re.sub(r"\s+", " ", cleaned)
    cleaned = cleaned.strip(". ")
    if not cleaned:
        cleaned = fallback
    if not cleaned.lower().endswith(".sketch"):
        cleaned += ".sketch"
    return cleaned


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def file_record(path: Path, status: str) -> dict[str, Any]:
    return {
        "status": status,
        "path": str(path),
        "bytes": path.stat().st_size,
        "sha256": sha256_file(path),
        "is_zipfile": zipfile.is_zipfile(path),
    }


def download_file(
    download_url: str,
    target_path: Path,
    *,
    timeout: int,
    max_download_bytes: int,
    overwrite: bool,
) -> dict[str, Any]:
    if target_path.exists() and not overwrite:
        return file_record(target_path, "exists")

    request = Request(download_url, headers={"User-Agent": USER_AGENT})
    try:
        with urlopen(request, timeout=timeout) as response:
            content_length = response.headers.get("Content-Length")
            expected_bytes = int(content_length) if content_length and content_length.isdigit() else None
            if expected_bytes is not None and expected_bytes > max_download_bytes:
                return {
                    "status": "skipped",
                    "reason": "content-length-exceeds-limit",
                    "expected_bytes": expected_bytes,
                    "max_download_bytes": max_download_bytes,
                }

            target_path.parent.mkdir(parents=True, exist_ok=True)
            temp_path = target_path.with_suffix(target_path.suffix + ".download")
            digest = hashlib.sha256()
            total = 0
            with temp_path.open("wb") as handle:
                for chunk in iter(lambda: response.read(1024 * 1024), b""):
                    total += len(chunk)
                    if total > max_download_bytes:
                        handle.close()
                        temp_path.unlink(missing_ok=True)
                        return {
                            "status": "skipped",
                            "reason": "download-exceeds-limit",
                            "bytes_read": total,
                            "max_download_bytes": max_download_bytes,
                        }
                    digest.update(chunk)
                    handle.write(chunk)
            temp_path.replace(target_path)
    except HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")[:500]
        return {"status": "error", "error": f"HTTP {exc.code}: {detail}"}
    except URLError as exc:
        return {"status": "error", "error": str(exc)}

    return {
        "status": "downloaded",
        "path": str(target_path),
        "bytes": total,
        "sha256": digest.hexdigest(),
        "is_zipfile": zipfile.is_zipfile(target_path),
    }


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_text(path: Path, payload: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(payload, encoding="utf-8")


def elapsed_since(started: float) -> float:
    return round(time.time() - started, 3)
