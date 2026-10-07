#!/usr/bin/env python3
"""Render Markdown through GitHub's Markdown API into a local preview page."""

from __future__ import annotations

import argparse
import html as html_lib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path


STYLESHEET = "https://cdn.jsdelivr.net/npm/github-markdown-css@5/github-markdown.css"
# GitHub wraps standalone images in a link to the same camo URL.
CAMO_ANCHOR_RE = re.compile(
    r'(<a\b[^>]*\shref=")https://camo\.githubusercontent\.com/[^"]*'
    r'("[^>]*>\s*<img\b[^>]*\sdata-canonical-src="([^"]*)")'
)
IMG_TAG_RE = re.compile(r"<img\b[^>]*>")
CANONICAL_RE = re.compile(r'\sdata-canonical-src="([^"]*)"')
SRC_RE = re.compile(r'\ssrc="[^"]*"')
REMOTE_URL_RE = re.compile(r'(?:src|srcset)="(https?://[^"\s]+)')

PAGE = """<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<link rel="stylesheet" href="{stylesheet}">
<style>
  body {{ margin: 0; background: #ffffff; }}
  @media (prefers-color-scheme: dark) {{ body {{ background: #0d1117; }} }}
  .markdown-body {{ box-sizing: content-box; min-width: 200px; max-width: {width}px; margin: 0 auto; padding: 45px; }}
  @media (max-width: 767px) {{ .markdown-body {{ padding: 15px; }} }}
</style>
</head>
<body>
<article class="markdown-body">
{body}
</article>
</body>
</html>
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Render Markdown with GitHub's sanitizer via `gh api markdown`, unwrap "
            "camo image proxies, apply URL mappings, and write <out>/index.html."
        )
    )
    parser.add_argument("markdown", type=Path, help="Markdown file to render.")
    parser.add_argument(
        "--context",
        required=True,
        help="Repository as OWNER/REPO, used to resolve issue, user, and relative links.",
    )
    parser.add_argument("--out", type=Path, required=True, help="Output directory.")
    parser.add_argument(
        "--map",
        action="append",
        default=[],
        metavar="FROM=TO",
        help=(
            "Replace a URL or URL prefix in rendered output, for example an unpublished "
            "remote image mapped to a local file in --out. Repeatable."
        ),
    )
    parser.add_argument(
        "--width",
        type=int,
        default=838,
        help=(
            "Max content width of the article in CSS pixels, excluding padding. Match "
            "the article.markdown-body width measured on the target github.com page. "
            "Default: 838."
        ),
    )
    return parser.parse_args()


def render_markdown(text: str, context: str) -> str:
    if shutil.which("gh") is None:
        raise SystemExit("gh is required: install GitHub CLI and run `gh auth login`.")
    payload = json.dumps({"text": text, "mode": "gfm", "context": context})
    result = subprocess.run(
        ["gh", "api", "markdown", "--input", "-"],
        input=payload,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise SystemExit(f"gh api markdown failed: {result.stderr.strip()}")
    return result.stdout


def unwrap_camo(html: str) -> str:
    def restore(match: re.Match[str]) -> str:
        tag = match.group(0)
        canonical = CANONICAL_RE.search(tag)
        if not canonical:
            return tag
        tag = SRC_RE.sub(f' src="{canonical.group(1)}"', tag, count=1)
        return CANONICAL_RE.sub("", tag)

    html = CAMO_ANCHOR_RE.sub(lambda match: match.group(1) + match.group(3) + match.group(2), html)
    return IMG_TAG_RE.sub(restore, html)


def apply_maps(html: str, mappings: list[str]) -> str:
    for mapping in mappings:
        source, separator, target = mapping.partition("=")
        if not separator or not source:
            raise SystemExit(f"--map must look like FROM=TO, got: {mapping}")
        html = html.replace(source, target)
    return html


def main() -> int:
    args = parse_args()
    if not args.markdown.is_file():
        raise SystemExit(f"Markdown file not found: {args.markdown}")
    text = args.markdown.read_text(encoding="utf-8")
    body = apply_maps(unwrap_camo(render_markdown(text, args.context)), args.map)

    args.out.mkdir(parents=True, exist_ok=True)
    page = PAGE.format(
        title=args.markdown.name,
        stylesheet=STYLESHEET,
        width=args.width,
        body=body,
    )
    output = args.out / "index.html"
    output.write_text(page, encoding="utf-8")

    print(f"Wrote {output}")
    remote = sorted({html_lib.unescape(url) for url in REMOTE_URL_RE.findall(body)})
    if remote:
        print("Remote images still loaded from the network:")
        for url in remote:
            print(f"  {url}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
