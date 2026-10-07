#!/usr/bin/env python3
"""Extract stable design facts from Sketch documents."""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
import os
import shutil
import subprocess
import sys
import urllib.request
import zipfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


DEFAULT_SKETCHTOOL = Path("/Applications/Sketch.app/Contents/MacOS/sketchtool")

CLASS_MAP = {
    "artboard": "Artboard",
    "bitmap": "Image",
    "group": "Group",
    "oval": "ShapePath",
    "page": "Page",
    "rectangle": "ShapePath",
    "shapeGroup": "Shape",
    "shapePath": "ShapePath",
    "slice": "Slice",
    "symbolInstance": "SymbolInstance",
    "symbolMaster": "SymbolMaster",
    "text": "Text",
}

EVIDENCE_KIND = {
    "source_named": "source-named",
    "api_mapped": "api-mapped",
    "inferred": "inferred",
}


@dataclass(frozen=True)
class CommandResult:
    command: list[str]
    returncode: int
    stdout: str
    stderr: str


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def run_command(command: list[str], *, required: bool = True) -> CommandResult:
    result = subprocess.run(command, text=True, capture_output=True)
    command_result = CommandResult(
        command=command,
        returncode=result.returncode,
        stdout=result.stdout,
        stderr=result.stderr,
    )
    if required and result.returncode != 0:
        rendered = " ".join(command)
        raise SystemExit(
            f"Command failed ({result.returncode}): {rendered}\n{result.stderr.strip()}"
        )
    return command_result


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def read_json_from_zip(archive: zipfile.ZipFile, name: str) -> dict[str, Any]:
    return json.loads(archive.read(name).decode("utf-8"))


def normalize_frame(frame: Any) -> dict[str, Any] | None:
    if not isinstance(frame, dict):
        return None
    keys = ["x", "y", "width", "height", "constrainProportions"]
    return {key: frame.get(key) for key in keys if key in frame}


def mapped_type(raw_class: str | None) -> str:
    if not raw_class:
        return "Unknown"
    if raw_class in CLASS_MAP:
        return CLASS_MAP[raw_class]
    return raw_class[:1].upper() + raw_class[1:]


def layer_id(node: dict[str, Any]) -> str | None:
    value = node.get("do_objectID") or node.get("id")
    return value if isinstance(value, str) else None


def export_format_count(node: dict[str, Any]) -> int:
    export_options = node.get("exportOptions")
    if not isinstance(export_options, dict):
        return 0
    formats = export_options.get("exportFormats")
    return len(formats) if isinstance(formats, list) else 0


def summarize_style(node: dict[str, Any]) -> dict[str, Any]:
    style = node.get("style") if isinstance(node.get("style"), dict) else {}
    context = style.get("contextSettings") if isinstance(style.get("contextSettings"), dict) else {}
    blur = style.get("blur") if isinstance(style.get("blur"), dict) else {}
    fills = style.get("fills") if isinstance(style.get("fills"), list) else []
    borders = style.get("borders") if isinstance(style.get("borders"), list) else []
    shadows = style.get("shadows") if isinstance(style.get("shadows"), list) else []
    inner_shadows = style.get("innerShadows") if isinstance(style.get("innerShadows"), list) else []
    shared_style_id = node.get("sharedStyleID") or style.get("sharedObjectID")
    text = node.get("attributedString") if isinstance(node.get("attributedString"), dict) else {}

    summary: dict[str, Any] = {}
    if context:
        summary["opacity"] = context.get("opacity")
        summary["blendMode"] = context.get("blendMode")
    summary["fills"] = len([item for item in fills if item.get("isEnabled", True)])
    summary["borders"] = len([item for item in borders if item.get("isEnabled", True)])
    summary["shadows"] = len([item for item in shadows if item.get("isEnabled", True)])
    summary["innerShadows"] = len([item for item in inner_shadows if item.get("isEnabled", True)])
    if blur:
        summary["blur"] = {
            "enabled": blur.get("isEnabled"),
            "type": blur.get("type"),
            "radius": blur.get("radius"),
        }
    if shared_style_id:
        summary["sharedStyleID"] = shared_style_id
    if isinstance(text.get("string"), str):
        summary["text"] = {
            "length": len(text["string"]),
            "sample": text["string"][:160],
        }
    return {key: value for key, value in summary.items() if value not in (None, {}, [])}


def normalize_color(value: dict[str, Any]) -> str | None:
    required = ["red", "green", "blue"]
    if not all(key in value for key in required):
        return None
    try:
        red = max(0, min(255, round(float(value["red"]) * 255)))
        green = max(0, min(255, round(float(value["green"]) * 255)))
        blue = max(0, min(255, round(float(value["blue"]) * 255)))
        alpha = float(value.get("alpha", 1))
    except (TypeError, ValueError):
        return None
    if alpha >= 0.999:
        return f"#{red:02X}{green:02X}{blue:02X}"
    return f"#{red:02X}{green:02X}{blue:02X}@{alpha:.3f}"


def normalize_source_value(value: Any) -> Any:
    if isinstance(value, dict):
        output = {key: normalize_source_value(child) for key, child in value.items()}
        if value.get("_class") == "color":
            output["hex"] = normalize_color(value)
        return output
    if isinstance(value, list):
        return [normalize_source_value(child) for child in value]
    return value


def maybe_section(value: dict[str, Any]) -> dict[str, Any] | None:
    return value if value else None


def normalize_export_options(node: dict[str, Any]) -> dict[str, Any] | None:
    export_options = node.get("exportOptions")
    if not isinstance(export_options, dict):
        return None
    return normalize_source_value(export_options)


def normalize_text_details(node: dict[str, Any]) -> dict[str, Any] | None:
    style = node.get("style") if isinstance(node.get("style"), dict) else {}
    text_style = style.get("textStyle") if isinstance(style.get("textStyle"), dict) else None
    attributed = node.get("attributedString") if isinstance(node.get("attributedString"), dict) else None
    details: dict[str, Any] = {}
    if attributed:
        details["attributedString"] = normalize_source_value(attributed)
        text = attributed.get("string")
        if isinstance(text, str):
            details["plainText"] = text
            details["length"] = len(text)
    if text_style:
        details["textStyle"] = normalize_source_value(text_style)
    for key in [
        "glyphBounds",
        "lineSpacingBehaviour",
        "textBehaviour",
        "automaticallyDrawOnUnderlyingPath",
        "dontSynchroniseWithSymbol",
    ]:
        if key in node:
            details[key] = normalize_source_value(node[key])
    return maybe_section(details)


def normalize_override_name(value: Any) -> str | None:
    if not isinstance(value, str) or "_" not in value:
        return None
    return value.rsplit("_", 1)[-1]


def normalize_override_rows(values: Any) -> list[dict[str, Any]]:
    if not isinstance(values, list):
        return []
    rows = []
    for item in values:
        if not isinstance(item, dict):
            continue
        row = normalize_source_value(item)
        override_type = normalize_override_name(item.get("overrideName"))
        if override_type:
            row["overrideType"] = override_type
        rows.append(row)
    return rows


def normalize_symbol_details(node: dict[str, Any]) -> dict[str, Any] | None:
    details: dict[str, Any] = {}
    for key in [
        "symbolID",
        "scale",
        "allowsOverrides",
        "includeBackgroundColorInInstance",
        "preservesSpaceWhenHidden",
    ]:
        if key in node:
            details[key] = normalize_source_value(node[key])
    override_values = normalize_override_rows(node.get("overrideValues"))
    if override_values:
        details["overrideValues"] = override_values
        details["overrideValueCount"] = len(override_values)
    override_properties = normalize_override_rows(node.get("overrideProperties"))
    if override_properties:
        details["overrideProperties"] = override_properties
        details["overridePropertyCount"] = len(override_properties)
    return maybe_section(details)


def normalize_layout_details(node: dict[str, Any]) -> dict[str, Any]:
    details: dict[str, Any] = {
        "frame": normalize_frame(node.get("frame")),
        "rotation": node.get("rotation"),
        "resizingConstraint": node.get("resizingConstraint"),
        "resizingType": node.get("resizingType"),
        "isFixedToViewport": node.get("isFixedToViewport"),
        "isFlippedHorizontal": node.get("isFlippedHorizontal"),
        "isFlippedVertical": node.get("isFlippedVertical"),
        "isLocked": node.get("isLocked"),
        "isVisible": node.get("isVisible"),
        "isTemplate": node.get("isTemplate"),
        "booleanOperation": node.get("booleanOperation"),
        "layerListExpandedType": node.get("layerListExpandedType"),
        "nameIsFixed": node.get("nameIsFixed"),
        "clippingMaskMode": node.get("clippingMaskMode"),
        "hasClippingMask": node.get("hasClippingMask"),
        "shouldBreakMaskChain": node.get("shouldBreakMaskChain"),
        "hasClickThrough": node.get("hasClickThrough"),
        "resizesContent": node.get("resizesContent"),
    }
    group_layout = node.get("groupLayout")
    if isinstance(group_layout, dict):
        details["groupLayout"] = normalize_source_value(group_layout)
    for key in ["horizontalRulerData", "verticalRulerData", "prototypeViewport"]:
        if isinstance(node.get(key), dict):
            details[key] = normalize_source_value(node[key])
    return {key: value for key, value in details.items() if value is not None}


def normalize_prototype_details(node: dict[str, Any]) -> dict[str, Any] | None:
    details = {
        key: normalize_source_value(node[key])
        for key in [
            "hasCustomPrototypeVisibility",
            "prototypeVisibility",
            "prototypeVisibilityTrigger",
            "prototypeScrolling",
            "isFlowHome",
            "overlayBackgroundInteraction",
            "presentationStyle",
        ]
        if key in node
    }
    return maybe_section(details)


def normalize_shape_details(node: dict[str, Any]) -> dict[str, Any] | None:
    details = {
        key: normalize_source_value(node[key])
        for key in [
            "edited",
            "isClosed",
            "pointRadiusBehaviour",
            "fixedRadius",
            "needsConvertionToNewRoundCorners",
            "hasConvertedToNewRoundCorners",
            "windingRule",
        ]
        if key in node
    }
    points = node.get("points")
    if isinstance(points, list):
        details["points"] = normalize_source_value(points)
        details["pointCount"] = len(points)
    return maybe_section(details)


def normalize_background_details(node: dict[str, Any]) -> dict[str, Any] | None:
    details = {
        key: normalize_source_value(node[key])
        for key in [
            "hasBackgroundColor",
            "includeBackgroundColorInExport",
            "includeBackgroundColorInInstance",
        ]
        if key in node
    }
    if isinstance(node.get("backgroundColor"), dict):
        details["backgroundColor"] = normalize_source_value(node["backgroundColor"])
    return maybe_section(details)


DETAIL_FIELD_KEYS = {
    "_class",
    "attributedString",
    "backgroundColor",
    "do_objectID",
    "exportOptions",
    "frame",
    "groupLayout",
    "horizontalRulerData",
    "id",
    "layers",
    "name",
    "overrideProperties",
    "overrideValues",
    "points",
    "prototypeViewport",
    "style",
    "verticalRulerData",
}


def normalize_source_properties(node: dict[str, Any]) -> dict[str, Any]:
    return {
        key: normalize_source_value(value)
        for key, value in node.items()
        if key not in DETAIL_FIELD_KEYS
    }


def build_layer_details(node: dict[str, Any]) -> dict[str, Any]:
    details: dict[str, Any] = {
        "schema": "sketch-design.layer-details.v1",
        "evidence": EVIDENCE_KIND["source_named"],
        "sourceFields": sorted(node.keys()),
        "layout": normalize_layout_details(node),
        "sourceProperties": normalize_source_properties(node),
    }
    style = node.get("style")
    if isinstance(style, dict):
        details["style"] = normalize_source_value(style)
    text = normalize_text_details(node)
    if text:
        details["text"] = text
    symbol = normalize_symbol_details(node)
    if symbol:
        details["symbol"] = symbol
    export = normalize_export_options(node)
    if export:
        details["export"] = export
    shape = normalize_shape_details(node)
    if shape:
        details["shape"] = shape
    prototype = normalize_prototype_details(node)
    if prototype:
        details["prototype"] = prototype
    background = normalize_background_details(node)
    if background:
        details["background"] = background
    return details


def collect_tokens(value: Any, colors: collections.Counter[str], fonts: collections.Counter[str]) -> None:
    if isinstance(value, dict):
        color = normalize_color(value)
        if color:
            colors[color] += 1
        if value.get("_class") == "fontDescriptor":
            attrs = value.get("attributes")
            if isinstance(attrs, dict):
                name = attrs.get("name")
                size = attrs.get("size")
                if name:
                    fonts[f"{name} {size}"] += 1
        for child in value.values():
            collect_tokens(child, colors, fonts)
    elif isinstance(value, list):
        for child in value:
            collect_tokens(child, colors, fonts)


def collect_named_objects(collection: Any) -> list[dict[str, Any]]:
    if not isinstance(collection, dict):
        return []
    objects = collection.get("objects")
    if not isinstance(objects, list):
        return []
    rows = []
    for item in objects:
        if not isinstance(item, dict):
            continue
        row = normalize_source_value(item)
        row["id"] = item.get("do_objectID") or item.get("id")
        row["name"] = item.get("name")
        row["raw_class"] = item.get("_class")
        row["evidence"] = EVIDENCE_KIND["source_named"]
        rows.append(row)
    return rows


def walk_layers(
    node: dict[str, Any],
    *,
    view: str,
    page_id: str | None,
    page_name: str | None,
    parent_id: str | None,
    depth: int,
    path_names: list[str],
    records: list[dict[str, Any]],
    raw_counts: collections.Counter[str],
    mapped_counts: collections.Counter[str],
) -> None:
    raw_class = node.get("_class")
    if isinstance(raw_class, str):
        raw_counts[raw_class] += 1
        mapped_counts[mapped_type(raw_class)] += 1
    current_id = layer_id(node)
    name = node.get("name") if isinstance(node.get("name"), str) else None
    current_path = path_names + ([name] if name else [])
    frame = normalize_frame(node.get("frame"))
    record = {
        "id": current_id,
        "name": name,
        "view": view,
        "page_id": page_id,
        "page_name": page_name,
        "parent_id": parent_id,
        "depth": depth,
        "path": " / ".join(current_path),
        "raw_class": raw_class,
        "mapped_type": mapped_type(raw_class if isinstance(raw_class, str) else None),
        "type_evidence": EVIDENCE_KIND["api_mapped"],
        "visible": node.get("isVisible"),
        "locked": node.get("isLocked"),
        "frame": frame,
        "resizingConstraint": node.get("resizingConstraint"),
        "resizingType": node.get("resizingType"),
        "exportFormatCount": export_format_count(node),
        "style": summarize_style(node),
        "details": build_layer_details(node),
    }
    records.append({key: value for key, value in record.items() if value not in (None, {}, [])})

    children = node.get("layers")
    if isinstance(children, list):
        for child in children:
            if isinstance(child, dict):
                walk_layers(
                    child,
                    view=view,
                    page_id=page_id,
                    page_name=page_name,
                    parent_id=current_id,
                    depth=depth + 1,
                    path_names=current_path,
                    records=records,
                    raw_counts=raw_counts,
                    mapped_counts=mapped_counts,
                )


def summarize_detail_coverage(records: list[dict[str, Any]]) -> dict[str, int]:
    coverage: collections.Counter[str] = collections.Counter()
    for record in records:
        details = record.get("details") if isinstance(record.get("details"), dict) else {}
        raw_class = record.get("raw_class")
        if isinstance(details.get("style"), dict):
            coverage["layers_with_style_detail"] += 1
        if isinstance(details.get("text"), dict):
            coverage["layers_with_text_detail"] += 1
        if isinstance(details.get("symbol"), dict):
            coverage["layers_with_symbol_detail"] += 1
        if isinstance(details.get("export"), dict):
            coverage["layers_with_export_detail"] += 1
        if isinstance(details.get("shape"), dict):
            coverage["layers_with_shape_detail"] += 1
        if isinstance(details.get("prototype"), dict):
            coverage["layers_with_prototype_detail"] += 1
        if isinstance(details.get("background"), dict):
            coverage["layers_with_background_detail"] += 1
        layout = details.get("layout") if isinstance(details.get("layout"), dict) else {}
        if isinstance(layout.get("groupLayout"), dict):
            coverage["layers_with_group_layout_detail"] += 1
        symbol = details.get("symbol") if isinstance(details.get("symbol"), dict) else {}
        if symbol.get("overrideValueCount"):
            coverage["layers_with_override_values"] += 1
        if symbol.get("overridePropertyCount"):
            coverage["layers_with_override_properties"] += 1
        if raw_class == "symbolInstance":
            coverage["symbol_instances"] += 1
        if raw_class == "symbolMaster":
            coverage["symbol_masters"] += 1
        if raw_class == "text":
            coverage["text_layers"] += 1
    return dict(coverage.most_common())


def record_matches_target(record: dict[str, Any], target: str) -> bool:
    values = [record.get("id"), record.get("name"), record.get("path")]
    return any(value == target for value in values if isinstance(value, str))


def filter_records_by_targets(
    records: list[dict[str, Any]],
    targets: list[str],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    if not targets:
        return records, []

    by_id = {
        record["id"]: record
        for record in records
        if isinstance(record.get("id"), str)
    }
    children_by_parent: dict[str, list[str]] = collections.defaultdict(list)
    for record in records:
        parent_id = record.get("parent_id")
        current_id = record.get("id")
        if isinstance(parent_id, str) and isinstance(current_id, str):
            children_by_parent[parent_id].append(current_id)

    matched_ids: set[str] = set()
    matches: list[dict[str, Any]] = []
    for target in targets:
        for record in records:
            current_id = record.get("id")
            if isinstance(current_id, str) and record_matches_target(record, target):
                matched_ids.add(current_id)
                matches.append(
                    {
                        "target": target,
                        "id": current_id,
                        "name": record.get("name"),
                        "path": record.get("path"),
                        "raw_class": record.get("raw_class"),
                        "mapped_type": record.get("mapped_type"),
                    }
                )

    if not matched_ids:
        return records, []

    include_ids: set[str] = set()
    stack = list(matched_ids)
    while stack:
        current_id = stack.pop()
        if current_id in include_ids:
            continue
        include_ids.add(current_id)
        stack.extend(children_by_parent.get(current_id, []))

    for current_id in list(include_ids):
        record = by_id.get(current_id)
        while record and isinstance(record.get("parent_id"), str):
            parent_id = record["parent_id"]
            if parent_id in include_ids:
                break
            include_ids.add(parent_id)
            record = by_id.get(parent_id)

    return [
        record
        for record in records
        if isinstance(record.get("id"), str) and record["id"] in include_ids
    ], matches


def parse_sketch_document(path: Path, view: str, targets: list[str] | None = None) -> dict[str, Any]:
    records: list[dict[str, Any]] = []
    raw_counts: collections.Counter[str] = collections.Counter()
    mapped_counts: collections.Counter[str] = collections.Counter()
    colors: collections.Counter[str] = collections.Counter()
    fonts: collections.Counter[str] = collections.Counter()
    embedded_assets: list[dict[str, Any]] = []

    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        meta = read_json_from_zip(archive, "meta.json") if "meta.json" in names else {}
        document = read_json_from_zip(archive, "document.json") if "document.json" in names else {}
        page_files = sorted(name for name in names if name.startswith("pages/") and name.endswith(".json"))

        collect_tokens(document, colors, fonts)
        for name in page_files:
            page = read_json_from_zip(archive, name)
            page_id = layer_id(page)
            page_name = page.get("name") if isinstance(page.get("name"), str) else None
            collect_tokens(page, colors, fonts)
            walk_layers(
                page,
                view=view,
                page_id=page_id,
                page_name=page_name,
                parent_id=None,
                depth=0,
                path_names=[],
                records=records,
                raw_counts=raw_counts,
                mapped_counts=mapped_counts,
            )

        for info in archive.infolist():
            if info.filename.startswith("images/") and not info.is_dir():
                embedded_assets.append({"path": info.filename, "bytes": info.file_size})

    unfiltered_record_count = len(records)
    records, target_matches = filter_records_by_targets(records, targets or [])
    raw_counts = collections.Counter(
        record.get("raw_class")
        for record in records
        if isinstance(record.get("raw_class"), str)
    )
    mapped_counts = collections.Counter(
        record.get("mapped_type")
        for record in records
        if isinstance(record.get("mapped_type"), str)
    )

    pages = [record for record in records if record.get("raw_class") == "page"]
    artboards = [record for record in records if record.get("raw_class") in ("artboard", "symbolMaster")]
    exportable = [record for record in records if record.get("exportFormatCount", 0)]
    detail_coverage = summarize_detail_coverage(records)

    shared_layer_styles = collect_named_objects(document.get("layerStyles"))
    shared_text_styles = collect_named_objects(document.get("layerTextStyles"))
    shared_swatches = collect_named_objects(document.get("sharedSwatches"))
    shared_symbols = collect_named_objects(document.get("layerSymbols"))

    return {
        "view": view,
        "path": str(path),
        "sha256": sha256_file(path),
        "meta": meta,
        "summary": {
            "pages": len(pages),
            "artboards_and_symbol_masters": len(artboards),
            "layers_including_pages": len(records),
            "layers_excluding_pages": len(records) - len(pages),
            "unfiltered_layers_including_pages": unfiltered_record_count,
            "embedded_images": len(embedded_assets),
            "exportable_layers": len(exportable),
            "raw_class_counts": dict(raw_counts.most_common()),
            "mapped_type_counts": dict(mapped_counts.most_common()),
            "mapped_type_counts_excluding_pages": {
                key: value
                for key, value in mapped_counts.items()
                if key != "Page"
            },
            "detail_coverage": detail_coverage,
        },
        "target_filter": {
            "targets": targets or [],
            "matched": target_matches,
            "applied": bool(targets and target_matches),
        },
        "layers": records,
        "page_files": page_files,
        "embedded_assets": embedded_assets[:500],
        "shared": {
            "layer_styles": shared_layer_styles,
            "text_styles": shared_text_styles,
            "swatches": shared_swatches,
            "symbols": shared_symbols,
            "foreign_layer_styles": document.get("foreignLayerStyles", []),
            "foreign_text_styles": document.get("foreignTextStyles", []),
            "foreign_swatches": document.get("foreignSwatches", []),
            "foreign_symbols": document.get("foreignSymbols", []),
        },
        "tokens": {
            "colors": [{"value": key, "count": value} for key, value in colors.most_common(200)],
            "fonts": [{"value": key, "count": value} for key, value in fonts.most_common(200)],
        },
        "artboards": [
            {
                "id": record.get("id"),
                "name": record.get("name"),
                "page_name": record.get("page_name"),
                "raw_class": record.get("raw_class"),
                "mapped_type": record.get("mapped_type"),
                "frame": record.get("frame"),
            }
            for record in artboards
        ],
    }


def export_preview(sketchtool: Path, source: Path, output_dir: Path) -> dict[str, Any]:
    output_dir.mkdir(parents=True, exist_ok=True)
    preview_path = output_dir / "preview.png"
    result = run_command(
        [
            str(sketchtool),
            "export",
            "preview",
            str(source),
            f"--output={output_dir}",
            "--filename=preview.png",
            "--overwriting=YES",
        ],
        required=False,
    )
    files = []
    if preview_path.exists():
        files.append(
            {
                "path": str(preview_path),
                "relative_path": preview_path.name,
                "bytes": preview_path.stat().st_size,
            }
        )
    return {
        "command": result.command,
        "returncode": result.returncode,
        "stdout": result.stdout.strip(),
        "stderr": result.stderr.strip(),
        "file_count": len(files),
        "files": files,
    }


def export_collection(
    sketchtool: Path,
    source: Path,
    kind: str,
    output_dir: Path,
    targets: list[str],
    include_symbols: bool = False,
) -> dict[str, Any]:
    output_dir.mkdir(parents=True, exist_ok=True)
    command = [
        str(sketchtool),
        "export",
        kind,
        str(source),
        f"--output={output_dir}",
        "--formats=png",
        "--use-id-for-name=YES",
        "--overwriting=YES",
    ]
    if kind == "artboards" and include_symbols:
        command.append("--include-symbols=YES")
    if targets:
        command.append(f"--items={','.join(targets)}")
    result = run_command(command, required=False)
    return export_result(result, output_dir)


def export_result(result: CommandResult, output_dir: Path) -> dict[str, Any]:
    files = []
    if output_dir.exists():
        for path in sorted(output_dir.rglob("*")):
            if path.is_file():
                files.append(
                    {
                        "path": str(path),
                        "relative_path": str(path.relative_to(output_dir)),
                        "bytes": path.stat().st_size,
                    }
                )
    return {
        "command": result.command,
        "returncode": result.returncode,
        "stdout": result.stdout.strip(),
        "stderr": result.stderr.strip(),
        "file_count": len(files),
        "files": files,
    }


def resolve_sketchtool(explicit: str | None) -> Path:
    if explicit:
        path = Path(explicit).expanduser().resolve()
        if not path.exists():
            raise SystemExit(f"sketchtool not found: {path}")
        return path
    env_path = os.environ.get("SKETCHTOOL")
    if env_path:
        path = Path(env_path).expanduser().resolve()
        if path.exists():
            return path
    if DEFAULT_SKETCHTOOL.exists():
        return DEFAULT_SKETCHTOOL
    found = shutil.which("sketchtool")
    if found:
        return Path(found).resolve()
    raise SystemExit("sketchtool not found. Pass --sketchtool or install Sketch from sketch.com.")


def call_mcp(url: str, payload: dict[str, Any], timeout: float = 15) -> dict[str, Any]:
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"content-type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        body = response.read().decode("utf-8").strip()
        if not body:
            return {}
        return json.loads(body)


def run_mcp_parity(url: str, source: Path, local_summary: dict[str, Any]) -> dict[str, Any]:
    try:
        call_mcp(
            url,
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "protocolVersion": "2025-03-26",
                    "capabilities": {},
                    "clientInfo": {"name": "sketch-design", "version": "0"},
                },
            },
        )
        call_mcp(url, {"jsonrpc": "2.0", "method": "notifications/initialized"})
        source_aliases = {str(source), str(source).replace("/private/tmp/", "/tmp/")}
        code = f"""
const sketch=require('sketch');
const targets={json.dumps(sorted(source_aliases))};
const docs=sketch.Document.getDocuments();
const doc=docs.find(d=>targets.includes(String(d.path)));
if(!doc) {{
  console.log(JSON.stringify({{status:'skipped', reason:'document-not-open', openDocuments:docs.map(d=>String(d.path))}}));
}} else {{
  const counts={{}};
  let total=0;
  function walk(layer) {{
    total++;
    counts[layer.type]=(counts[layer.type]||0)+1;
    if(layer.layers) layer.layers.forEach(walk);
  }}
  doc.pages.forEach(page=>page.layers.forEach(walk));
  console.log(JSON.stringify({{status:'ok', documentPath:doc.path, layers_total:total, type_counts:counts}}));
}}
"""
        response = call_mcp(
            url,
            {
                "jsonrpc": "2.0",
                "id": 2,
                "method": "tools/call",
                "params": {
                    "name": "run_code",
                    "arguments": {"title": "Sketch design parity", "script": code},
                },
            },
            timeout=30,
        )
    except Exception as error:  # noqa: BLE001
        return {"status": "error", "error": f"{type(error).__name__}: {error}"}

    text_blocks = []
    for item in response.get("result", {}).get("content", []):
        if isinstance(item, dict) and isinstance(item.get("text"), str):
            text_blocks.append(item["text"])
    parsed = None
    for text in reversed(text_blocks):
        candidate = text.strip()
        if candidate.startswith("'") and candidate.endswith("'"):
            candidate = candidate[1:-1]
        try:
            parsed = json.loads(candidate)
            break
        except json.JSONDecodeError:
            continue
    if parsed is None:
        return {"status": "error", "error": "MCP response did not contain JSON", "raw": response}
    if parsed.get("status") != "ok":
        return parsed

    local_counts = local_summary.get("mapped_type_counts_excluding_pages", {})
    mcp_counts = parsed.get("type_counts", {})
    keys = sorted(set(local_counts) | set(mcp_counts))
    return {
        "status": "ok",
        "mcp": parsed,
        "local": {
            "layers_excluding_pages": local_summary.get("layers_excluding_pages"),
            "mapped_type_counts_excluding_pages": local_counts,
        },
        "delta": {
            "layers": local_summary.get("layers_excluding_pages") - parsed.get("layers_total", 0),
            "type_counts": {key: local_counts.get(key, 0) - mcp_counts.get(key, 0) for key in keys},
        },
    }


def build_tokens(views: list[dict[str, Any]]) -> dict[str, Any]:
    color_counts: collections.Counter[str] = collections.Counter()
    font_counts: collections.Counter[str] = collections.Counter()
    shared = {
        "layer_styles": [],
        "text_styles": [],
        "swatches": [],
        "symbols": [],
    }
    for view in views:
        for color in view["tokens"]["colors"]:
            color_counts[color["value"]] += color["count"]
        for font in view["tokens"]["fonts"]:
            font_counts[font["value"]] += font["count"]
        for key in shared:
            for item in view["shared"].get(key, []):
                row = dict(item)
                row["view"] = view["view"]
                shared[key].append(row)
    return {
        "evidence": {
            "source_named": "Named styles, swatches, symbols, export settings, and text originate in the Sketch file.",
            "api_mapped": "Raw Sketch JSON classes are mapped to SketchAPI/MCP-style names.",
            "inferred": "Implementation hints are derived and must not be treated as source facts.",
        },
        "colors": [{"value": key, "count": value} for key, value in color_counts.most_common(300)],
        "fonts": [{"value": key, "count": value} for key, value in font_counts.most_common(300)],
        "shared": shared,
    }


def build_semantic_map(views: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "detail_schema": {
            "layer_details": [
                "layout",
                "style",
                "text",
                "symbol",
                "export",
                "shape",
                "prototype",
                "background",
                "sourceProperties",
                "sourceFields",
            ],
            "style": "Full Sketch style JSON with color objects augmented by hex values.",
            "text": "Full attributedString and textStyle records when present.",
            "symbol": "symbolID, scale, overrideValues, overrideProperties, and override type hints.",
            "shape": "Shape geometry fields, including full curve points when present.",
            "sourceProperties": "Top-level Sketch layer properties not otherwise promoted into named detail sections.",
        },
        "mapping": [
            {
                "raw_class": raw,
                "mapped_type": mapped,
                "evidence": EVIDENCE_KIND["api_mapped"],
            }
            for raw, mapped in sorted(CLASS_MAP.items())
        ],
        "views": [
            {
                "view": view["view"],
                "raw_class_counts": view["summary"]["raw_class_counts"],
                "mapped_type_counts": view["summary"]["mapped_type_counts"],
                "mapped_type_counts_excluding_pages": view["summary"]["mapped_type_counts_excluding_pages"],
            }
            for view in views
        ],
    }


def build_summary_md(
    source: Path,
    sketchtool_version: str,
    views: list[dict[str, Any]],
    exports: dict[str, Any],
    targets: list[str],
) -> str:
    lines = [
        "# Sketch Design Summary",
        "",
        f"- Source: `{source}`",
        f"- Generated: `{now_iso()}`",
        f"- sketchtool: `{sketchtool_version}`",
    ]
    if targets:
        lines.append(f"- Targets: {', '.join(f'`{target}`' for target in targets)}")
    lines.extend(["", "## Views"])
    for view in views:
        summary = view["summary"]
        lines.extend(
            [
                "",
                f"### {view['view']}",
                "",
                f"- Pages: {summary['pages']}",
                f"- Artboards and symbol masters: {summary['artboards_and_symbol_masters']}",
                f"- Layers excluding pages: {summary['layers_excluding_pages']}",
                f"- Embedded images: {summary['embedded_images']}",
                f"- Exportable layers: {summary['exportable_layers']}",
                f"- Top mapped types: {', '.join(f'{k}={v}' for k, v in list(summary['mapped_type_counts_excluding_pages'].items())[:10])}",
            ]
        )
        coverage = summary.get("detail_coverage", {})
        if coverage:
            lines.append(
                "- Detail coverage: "
                + ", ".join(f"{key}={value}" for key, value in list(coverage.items())[:8])
            )
        shared = view["shared"]
        lines.extend(
            [
                f"- Shared layer styles: {len(shared.get('layer_styles', []))}",
                f"- Shared text styles: {len(shared.get('text_styles', []))}",
                f"- Shared swatches: {len(shared.get('swatches', []))}",
                f"- Shared symbols: {len(shared.get('symbols', []))}",
            ]
        )
    lines.extend(["", "## Exports"])
    if not exports:
        lines.append("- No visual exports requested.")
    for name, result in exports.items():
        lines.append(f"- {name}: {result.get('file_count', 0)} files, returncode {result.get('returncode')}")
    lines.extend(
        [
            "",
            "## Evidence Notes",
            "",
            "- `source-named` evidence comes from names, symbols, styles, swatches, text, and export settings stored in the Sketch file.",
            "- `api-mapped` evidence maps raw Sketch JSON classes to SketchAPI/MCP-style type names.",
            "- `inferred` guidance is useful for downstream implementation but is not a source fact.",
        ]
    )
    return "\n".join(lines) + "\n"


def build_handoff_md(source: Path, views: list[dict[str, Any]], exports: dict[str, Any]) -> str:
    original = views[0]
    top_types = ", ".join(
        f"{key}={value}"
        for key, value in list(original["summary"]["mapped_type_counts_excluding_pages"].items())[:10]
    )
    has_exports = any(result.get("file_count", 0) for result in exports.values())
    lines = [
        "# Sketch Implementation Handoff",
        "",
        f"- Source: `{source}`",
        f"- Primary design view: `{original['view']}`",
        f"- Layer count excluding pages: {original['summary']['layers_excluding_pages']}",
        f"- Top mapped types: {top_types}",
        "",
        "## Use This Context",
        "",
        "- Reuse existing project components before creating new components.",
        "- Map colors, typography, spacing, radius, and effects to project tokens before using literal values.",
        "- Let project architecture decide code structure; do not mechanically copy every Sketch group.",
        "- Use source-named symbols, shared styles, swatches, and export settings as design evidence.",
        "- Use per-layer `details` for exact typography, fills, borders, shadows, blur, radius, overrides, and shape geometry.",
        "- Treat inferred layout or component hints as hypotheses and verify them against project conventions.",
        "",
        "## Official Coding Guidance Parity",
        "",
        "- Translate Sketch output to project conventions before writing code.",
        "- Reuse existing UI components before creating new components.",
        "- Map Sketch values to project tokens: color, spacing, type scale, radius, and effects.",
        "- Match established architecture, state, and data-flow patterns in the target project.",
        "- Keep component boundaries consistent with the design hierarchy without mechanically copying every Sketch group.",
        "- Prefer incremental updates over broad rewrites.",
        "- Document intentional deviations caused by technical or accessibility constraints.",
        "",
        "## Visual Parity Targets",
        "",
        "- Match spacing, alignment, sizing, and hierarchy.",
        "- Match typography, color usage, effects, and asset rendering.",
        "- Preserve intended responsive or constraint-based layout behavior.",
        "- Use tokenized values when possible; avoid unnecessary hardcoded values.",
        "",
        "## Assets",
        "",
    ]
    if has_exports:
        lines.append("- Use exported Sketch assets from this output directory instead of placeholders or unrelated icon packs.")
    else:
        lines.append("- No assets were exported in this run; rerun with export flags before implementation needs bitmap, icon, or artboard references.")
    lines.extend(
        [
            "",
            "## Validation",
            "",
            "- Compare implemented UI against `summary.md`, `design-context.json`, and visual exports.",
            "- Check layout, spacing, typography, colors, effects, states, interactions, asset rendering, responsiveness, constraints, and accessibility basics.",
            "- If mismatch remains, re-extract the relevant artboard, layer, or subtree instead of patching from memory.",
            "",
            "## Boundary",
            "",
            "- This handoff intentionally contains no SwiftUI, UIKit, AppKit, React, HTML, or CSS implementation code.",
            "- Framework-specific implementation belongs to the downstream coding skill and the target project's conventions.",
        ]
    )
    return "\n".join(lines) + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, help="Path to a .sketch file.")
    parser.add_argument("--output-dir", required=True, help="Directory for generated artifacts.")
    parser.add_argument("--sketchtool", help="Path to sketchtool.")
    parser.add_argument("--target", action="append", default=[], help="Target page/artboard/layer id or name. Repeatable.")
    parser.add_argument("--detach", action="store_true", help="Create and parse detached.sketch.")
    parser.add_argument("--export-preview", action="store_true", help="Export document preview.png.")
    parser.add_argument("--export-artboards", action="store_true", help="Export artboards to artboards/.")
    parser.add_argument("--include-symbols", action="store_true", help="Include symbol masters when exporting artboards.")
    parser.add_argument("--export-layers", action="store_true", help="Export target/all layers to assets/layers/.")
    parser.add_argument("--export-slices", action="store_true", help="Export target/all slices to assets/slices/.")
    parser.add_argument("--summary-only", action="store_true", help="Skip export operations.")
    parser.add_argument("--mcp-parity-url", help="Optional Sketch MCP URL for small-sample parity.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    source = Path(args.input).expanduser().resolve()
    if not source.exists():
        raise SystemExit(f"Input not found: {source}")
    if source.suffix != ".sketch":
        raise SystemExit(f"Input must be a .sketch file: {source}")

    output_dir = Path(args.output_dir).expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    sketchtool = resolve_sketchtool(args.sketchtool)

    version_result = run_command([str(sketchtool), "--version"], required=False)
    sketchtool_version = (version_result.stdout or version_result.stderr).strip()

    metadata_result = run_command([str(sketchtool), "metadata", str(source)])
    metadata = json.loads(metadata_result.stdout)
    write_json(output_dir / "metadata.json", metadata)

    detached_path: Path | None = None
    detach_result: dict[str, Any] | None = None
    if args.detach:
        detached_path = output_dir / "detached.sketch"
        command = [str(sketchtool), "detach", str(source), f"--output={detached_path}"]
        result = run_command(command, required=True)
        detach_result = {
            "command": result.command,
            "returncode": result.returncode,
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip(),
            "path": str(detached_path),
            "bytes": detached_path.stat().st_size if detached_path.exists() else None,
        }

    views = [parse_sketch_document(source, "original", args.target)]
    if detached_path and detached_path.exists():
        views.append(parse_sketch_document(detached_path, "detached", args.target))

    exports: dict[str, Any] = {}
    if not args.summary_only:
        if args.export_preview:
            exports["preview"] = export_preview(sketchtool, source, output_dir)
        if args.export_artboards:
            exports["artboards"] = export_collection(
                sketchtool,
                source,
                "artboards",
                output_dir / "artboards",
                args.target,
                include_symbols=args.include_symbols,
            )
        if args.export_layers:
            exports["layers"] = export_collection(
                sketchtool, source, "layers", output_dir / "assets" / "layers", args.target
            )
        if args.export_slices:
            exports["slices"] = export_collection(
                sketchtool, source, "slices", output_dir / "assets" / "slices", args.target
            )

    context = {
        "schema": "sketch-design.context.v2",
        "generated_at": now_iso(),
        "source": {
            "path": str(source),
            "sha256": sha256_file(source),
            "bytes": source.stat().st_size,
        },
        "targets": args.target,
        "views": views,
    }
    tokens = build_tokens(views)
    semantic_map = build_semantic_map(views)

    manifest = {
        "schema": "sketch-design.manifest.v1",
        "generated_at": now_iso(),
        "source": context["source"],
        "sketchtool": {
            "path": str(sketchtool),
            "version": sketchtool_version,
        },
        "metadata": {
            "path": str(output_dir / "metadata.json"),
            "appVersion": metadata.get("appVersion"),
            "version": metadata.get("version"),
            "page_count": len(metadata.get("pagesAndArtboards", {}))
            if isinstance(metadata.get("pagesAndArtboards"), dict)
            else None,
        },
        "targets": args.target,
        "detach": detach_result,
        "exports": exports,
        "artifacts": {
            "manifest": str(output_dir / "manifest.json"),
            "design_context": str(output_dir / "design-context.json"),
            "semantic_map": str(output_dir / "semantic-map.json"),
            "tokens": str(output_dir / "tokens.json"),
            "summary": str(output_dir / "summary.md"),
            "implementation_handoff": str(output_dir / "implementation-handoff.md"),
        },
    }

    if args.mcp_parity_url:
        parity = run_mcp_parity(args.mcp_parity_url, source, views[0]["summary"])
        write_json(output_dir / "mcp-parity.json", parity)
        manifest["mcp_parity"] = {
            "url": args.mcp_parity_url,
            "path": str(output_dir / "mcp-parity.json"),
            "status": parity.get("status"),
        }

    write_json(output_dir / "design-context.json", context)
    write_json(output_dir / "semantic-map.json", semantic_map)
    write_json(output_dir / "tokens.json", tokens)
    (output_dir / "summary.md").write_text(
        build_summary_md(source, sketchtool_version, views, exports, args.target)
    )
    (output_dir / "implementation-handoff.md").write_text(
        build_handoff_md(source, views, exports)
    )
    write_json(output_dir / "manifest.json", manifest)

    print(json.dumps({"output_dir": str(output_dir), "views": [view["summary"] for view in views]}, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
