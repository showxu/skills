#!/usr/bin/env python3
"""Build Icon Composer documents, native renditions, and web icons from DESIGN.md."""

from __future__ import annotations

import argparse
import base64
import html
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import zlib

PLATFORMS = ("iOS", "macOS", "watchOS")
RENDITIONS = ("Default", "Dark", "ClearLight", "ClearDark", "TintedLight", "TintedDark")
CORNER = (0.396305, 0.230261, 0.152117, 0.076058)
SAFE_NAME = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]*\Z")
GROUP_FIELDS = {"name", "layers", "shadow", "translucency", "blur-material", "refractivity"}


def fail(message):
    raise ValueError(message)


def read_entries(path):
    text = path.read_text()
    section = re.search(r"^## Iconography\s*\n(.*?)(?=^## |\Z)", text, re.M | re.S)
    block = re.search(r"^```json\s*\n(.*?)^```\s*$", section[1], re.M | re.S) if section else None
    if not block:
        fail("DESIGN.md needs an Iconography section with a JSON block")
    entries = json.loads(block[1]).get("app_icons")
    if not isinstance(entries, dict) or not entries:
        fail("Iconography needs a nonempty app_icons object")
    for name in entries:
        if not SAFE_NAME.fullmatch(name):
            fail(f"invalid icon name: {name}")
    return entries


def color(value):
    if not isinstance(value, str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", value):
        fail("background must be a six-digit hex color")
    return "srgb:" + ",".join(f"{int(value[i:i+2], 16)/255:.5f}" for i in (1, 3, 5)) + ",1.00000"


def validate_svg(data):
    root = ET.fromstring(data)
    viewbox = [float(v) for v in re.split(r"[\s,]+", root.get("viewBox", "").strip()) if v]
    if root.tag.split("}")[-1] != "svg" or viewbox != [0, 0, 1024, 1024]:
        fail("SVG layers need viewBox=\"0 0 1024 1024\"")
    for node in root.iter():
        if node.tag.split("}")[-1] in {"text", "script", "foreignObject"}:
            fail("SVG layers must use outlined artwork without text or executable content")
        for key, value in node.attrib.items():
            if key.split("}")[-1] == "href" and not value.startswith(("#", "data:image/")):
                fail("SVG layers must not depend on external files or URLs")
            if "url(" in value and not re.fullmatch(r"url\(#[^)]+\)", value):
                fail("SVG paint references must be local fragment IDs")
    return root


def unit(value, label):
    if isinstance(value, bool) or not isinstance(value, (float, int)) or not 0 <= value <= 1:
        fail(f"{label} must be a number from 0 to 1")


def material(group):
    if "name" in group and (not isinstance(group["name"], str) or not group["name"]):
        fail("group name must be nonempty text")
    if "blur-material" in group:
        unit(group["blur-material"], "blur-material")
    for key, fields in {"translucency": {"enabled", "value"},
                        "refractivity": {"enabled", "strength", "depth"},
                        "shadow": {"kind", "opacity"}}.items():
        if key not in group:
            continue
        obj = group[key]
        if not isinstance(obj, dict) or set(obj) != fields:
            fail(f"{key} needs exactly {', '.join(sorted(fields))}")
        if key == "shadow":
            if obj["kind"] not in {"neutral", "chromatic"}:
                fail("shadow kind must be neutral or chromatic")
        elif not isinstance(obj["enabled"], bool):
            fail(f"{key}.enabled must be true or false")
        for field in fields - {"enabled", "kind"}:
            unit(obj[field], f"{key}.{field}")


def prepare(spec, base):
    if not isinstance(spec, dict):
        fail("an app icon entry must be an object")
    unknown = set(spec) - {"background", "gradient", "groups", "maskable_scale"}
    if unknown:
        fail(f"unknown app icon fields: {sorted(unknown)}")
    fill = color(spec.get("background"))
    if not isinstance(spec.get("gradient", False), bool):
        fail("gradient must be true or false")
    groups = spec.get("groups")
    if not isinstance(groups, list) or not 1 <= len(groups) <= 4:
        fail("supply between one and four foreground groups")
    scale = spec.get("maskable_scale", 0.56)
    if not isinstance(scale, (float, int)) or not 0 < scale <= 0.56:
        fail("maskable_scale must be greater than zero and at most 0.56")
    document = {"fill": {"automatic-gradient" if spec.get("gradient") else "solid": fill},
                "groups": [], "supported-platforms": {"circles": ["watchOS"], "squares": "shared"}}
    assets = {}
    web_layers = []
    for gi, group in enumerate(groups):
        if not isinstance(group, dict) or set(group) - GROUP_FIELDS:
            fail(f"group {gi + 1} has unknown fields")
        material(group)
        layers = group.get("layers")
        if not isinstance(layers, list) or not layers:
            fail(f"group {gi + 1} needs layers")
        native = {k: v for k, v in group.items() if k != "layers"}
        native["layers"] = []
        for li, layer in enumerate(layers):
            if not isinstance(layer, dict) or set(layer) - {"source", "name"}:
                fail(f"group {gi + 1}, layer {li + 1}: expected source and optional name")
            source = layer.get("source")
            if "name" in layer and (not isinstance(layer["name"], str) or not layer["name"]):
                fail("layer name must be nonempty text")
            if not isinstance(source, str) or not source or Path(source).is_absolute():
                fail("layer sources must be paths relative to DESIGN.md")
            path = (base / source).resolve()
            if not path.is_file() or path.suffix.lower() not in {".svg", ".png"}:
                fail(f"missing or unsupported layer: {source}")
            data = path.read_bytes()
            suffix = path.suffix.lower()
            if suffix == ".svg":
                validate_svg(data)
            elif data[:8] != b"\x89PNG\r\n\x1a\n" or struct.unpack(">II", data[16:24]) != (1024, 1024):
                fail("PNG layers must be 1024 px square")
            filename = f"{gi + 1:02d}-{li + 1:02d}{suffix}"
            assets[filename] = data
            native["layers"].append({"image-name": filename, "name": layer.get("name", path.stem)})
            web_layers.append((suffix, data))
        if group.get("refractivity", {}).get("enabled"):
            document["features"] = ["refractivity"]
        # Icon Composer lists the foremost layer and group first; SVG paints last on top.
        native["layers"].reverse()
        document["groups"].insert(0, native)
    return document, assets, web_layers


def tile_path():
    side = 1024
    l, c1, c2, d = (v * side for v in CORNER)
    out = []
    for (cx, cy), e1, e2 in (((side, 0), (-1, 0), (0, 1)), ((side, side), (0, -1), (-1, 0)),
                            ((0, side), (1, 0), (0, -1)), ((0, 0), (0, 1), (1, 0))):
        def at(u, v):
            return f"{cx+u*e1[0]+v*e2[0]:.2f} {cy+u*e1[1]+v*e2[1]:.2f}"
        out.append(("M" if not out else "L") + at(l, 0))
        out.append(f"C{at(c1, 0)} {at(c2, 0)} {at(d, d)}C{at(0, c2)} {at(0, c1)} {at(0, l)}")
    return "".join(out) + "Z"


def web_svg(spec, layers, rounded=False, scale=1):
    images = []
    for suffix, data in layers:
        mime = "image/svg+xml" if suffix == ".svg" else "image/png"
        encoded = base64.b64encode(data).decode()
        images.append(f'<image width="1024" height="1024" href="data:{mime};base64,{encoded}"/>')
    inset = 512 * (1 - scale)
    clip = ' clip-path="url(#mask)"' if rounded else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">'
            f'<defs><clipPath id="mask"><path d="{tile_path()}"/></clipPath></defs><g{clip}>'
            f'<rect width="1024" height="1024" fill="{spec["background"]}"/>'
            f'<g transform="translate({inset} {inset}) scale({scale})">{"".join(images)}</g></g></svg>\n')


def find_ictool(explicit=None):
    override = explicit or os.environ.get("IC_TOOL")
    candidates = [override] if override else []
    if not override:
        selected = subprocess.run(["xcode-select", "-p"], capture_output=True, text=True)
        if selected.returncode == 0:
            candidates.append(str(Path(selected.stdout.strip()).parent /
                                  "Applications/Icon Composer.app/Contents/Executables/ictool"))
        candidates.append(shutil.which("ictool"))
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            help_result = subprocess.run([candidate, "--help"], capture_output=True, text=True)
            if "--export-image" in help_result.stdout + help_result.stderr:
                return candidate
    fail("Icon Composer's export-capable ictool was not found; supply --ictool or IC_TOOL")


def run(args):
    result = subprocess.run(list(map(str, args)), capture_output=True, text=True)
    if result.returncode:
        fail(f"{Path(str(args[0])).name} failed: {(result.stderr or result.stdout).strip()}")
    return result.stdout.strip()


def png_payload(path):
    """Ignore ancillary metadata while comparing the lossless encoded image data."""
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        fail(f"renderer did not produce PNG: {path.name}")
    pos, header, compressed = 8, b"", bytearray()
    while pos + 12 <= len(data):
        size, kind = struct.unpack(">I4s", data[pos:pos + 8])
        chunk = data[pos + 8:pos + 8 + size]
        if kind in {b"IHDR", b"PLTE", b"tRNS"}:
            header += kind + chunk
        elif kind == b"IDAT":
            compressed.extend(chunk)
        pos += size + 12
    return header + zlib.decompress(compressed)


def render_png(svg, target, size):
    run(["rsvg-convert", "-w", size, "-h", size, svg, "-o", target])


def contact_sheet(files):
    cell, row, width = 180, 220, 6 * 180
    height = len(PLATFORMS) * row * 2
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}">']
    for bi, bg in enumerate(("#ffffff", "#0d1117")):
        top = bi * len(PLATFORMS) * row
        parts.append(f'<rect y="{top}" width="{width}" height="{len(PLATFORMS)*row}" fill="{bg}"/>')
        for pi, platform in enumerate(PLATFORMS):
            for ri, rendition in enumerate(RENDITIONS):
                y, x = top + pi * row, ri * cell
                source = "renditions/" + files[(platform, rendition)].name
                parts.append(f'<image x="{x+10}" y="{y+4}" width="160" height="160" href="{source}"/>')
                parts.append(f'<image x="{x+70}" y="{y+163}" width="32" height="32" href="{source}"/>')
                text_color = "#111111" if bi == 0 else "#eeeeee"
                label = html.escape(f"{platform} · {rendition}")
                parts.append(f'<text x="{x+90}" y="{y+212}" text-anchor="middle" font-family="sans-serif" font-size="11" fill="{text_color}">{label}</text>')
    return "".join(parts) + "</svg>\n"


def build(name, spec, base, out, ictool=None, document_only=False, generation=None):
    document, assets, web_layers = prepare(spec, base)
    doc = out / f"{name}.icon"
    (doc / "Assets").mkdir(parents=True)
    (doc / "icon.json").write_text(json.dumps(document, indent=2, ensure_ascii=False) + "\n")
    for filename, data in assets.items():
        (doc / "Assets" / filename).write_bytes(data)
    if document_only:
        return
    renditions = out / "renditions"
    renditions.mkdir()
    files = {}
    for platform in PLATFORMS:
        size = 1088 if platform == "watchOS" else 1024
        for rendition in RENDITIONS:
            path = renditions / f"{platform}-{rendition}.png"
            args = [ictool, doc, "--export-image", "--output-file", path, "--platform", platform,
                    "--rendition", rendition, "--width", size, "--height", size, "--scale", 1]
            if generation is not None:
                args.extend(["--design-generation", generation])
            run(args)
            png_payload(path)
            files[(platform, rendition)] = path
    web = out / "web"
    web.mkdir()
    shutil.copyfile(files[("iOS", "Default")], web / "avatar-1024.png")
    (web / "favicon.svg").write_text(web_svg(spec, web_layers, rounded=True))
    (web / "touch.svg").write_text(web_svg(spec, web_layers))
    (web / "maskable.svg").write_text(web_svg(spec, web_layers, scale=spec.get("maskable_scale", 0.56)))
    for name, source, size in [("favicon-16.png", "favicon.svg", 16), ("favicon-32.png", "favicon.svg", 32),
                               ("apple-touch-icon.png", "touch.svg", 180), ("maskable-512.png", "maskable.svg", 512)]:
        render_png(web / source, web / name, size)
    (out / "contact-sheet.svg").write_text(contact_sheet(files))
    run(["rsvg-convert", out / "contact-sheet.svg", "-o", out / "contact-sheet.png"])
    manifest = {"renderer": run([ictool, "--version"]), "design_generation": generation,
                "files": sorted(str(p.relative_to(out)) for p in out.rglob("*") if p.is_file())}
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def compare(candidate, target):
    expected = {str(p.relative_to(candidate)): p for p in candidate.rglob("*") if p.is_file()}
    actual = {str(p.relative_to(target)): p for p in target.rglob("*") if p.is_file()}
    differences = 0
    for name in sorted(expected.keys() | actual.keys()):
        if name not in actual:
            status = "missing"
        elif name not in expected:
            status = "extra"
        else:
            if name.endswith(".png"):
                same = png_payload(expected[name]) == png_payload(actual[name])
            else:
                same = expected[name].read_bytes() == actual[name].read_bytes()
            status = "same" if same else "drift"
        print(f"{status}\t{name}")
        differences += status != "same"
    return differences


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("design", type=Path)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--list", action="store_true")
    mode.add_argument("--out", type=Path, help="write a new, dedicated output directory")
    mode.add_argument("--check", type=Path, help="regenerate privately and compare without modifying this directory")
    parser.add_argument("--name")
    parser.add_argument("--document-only", action="store_true")
    parser.add_argument("--ictool", help="path to Icon Composer's export-capable ictool")
    parser.add_argument("--design-generation", type=int)
    args = parser.parse_args()
    try:
        entries = read_entries(args.design)
        if args.list:
            print("\n".join(entries))
            return 0
        if args.name not in entries:
            fail("--name must identify an app_icons entry")
        target = (args.out or args.check).resolve()
        if args.out and target.exists():
            fail("output directory exists; use a fresh directory or --check to inspect drift")
        if args.check and not target.is_dir():
            fail("check target is not a directory")
        tool = None if args.document_only else find_ictool(args.ictool)
        if not args.document_only and not shutil.which("rsvg-convert"):
            fail("rsvg-convert is required for web icons and contact sheets")
        target.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix=".app-icon-", dir=target.parent) as temp:
            candidate = Path(temp) / "output"
            build(args.name, entries[args.name], args.design.resolve().parent, candidate,
                  tool, args.document_only, args.design_generation)
            if args.check:
                return 1 if compare(candidate, target) else 0
            candidate.rename(target)
        print(target)
        return 0
    except (ValueError, OSError, ET.ParseError, zlib.error, struct.error) as exc:
        parser.exit(1, f"error: {exc}\n")


if __name__ == "__main__":
    raise SystemExit(main())
