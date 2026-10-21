#!/usr/bin/env python3
"""Verify served GitHub images read-only; 0 pass, 1 mismatch, 2 unknown."""

import argparse
from datetime import datetime, timezone
import hashlib
from http.client import HTTPException
from io import BytesIO
import json
import math
from pathlib import Path
import re
import subprocess
import sys
import time
from urllib.parse import urlsplit
from urllib.request import Request, urlopen


SOCIAL_QUERY = """query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    id nameWithOwner openGraphImageUrl usesCustomOpenGraphImage
  }
}"""
AVATAR_QUERY = """query($login: String!, $size: Int!) {
  organization(login: $login) { login avatarUrl(size: $size) }
}"""


class Unreadable(Exception):
    """Unavailable evidence, with a message safe for private-image receipts."""


def graphql(query, variables):
    command = ["gh", "api", "graphql", "-f", "query=" + query]
    for key, value in variables.items():
        command += ["-F" if isinstance(value, int) else "-f", f"{key}={value}"]
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=30)
    except FileNotFoundError:
        raise Unreadable("GitHub CLI is missing; install gh and use its existing login") from None
    except (OSError, subprocess.SubprocessError):
        raise Unreadable("GitHub CLI request could not complete") from None
    if result.returncode:
        raise Unreadable("GitHub GraphQL request failed; check CLI login and target access")
    try:
        response = json.loads(result.stdout)
    except ValueError:
        raise Unreadable("GitHub GraphQL returned invalid JSON") from None
    return response


def fetch_image(url):
    try:
        parsed = urlsplit(url)
        if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password:
            raise ValueError("invalid served URL")
        request = Request(url, headers={"User-Agent": "github-repo-steward"})
        with urlopen(request, timeout=30) as response:
            return response.read()
    except (OSError, ValueError, HTTPException):
        # Transport errors can contain private image URLs and must not escape.
        raise Unreadable("Served image is unreadable without credentials; "
                         "verification is limited to unauthenticated image access, "
                         "which private repository visibility may restrict") from None


def decode(data, scope):
    try:
        from PIL import Image
    except ImportError:
        raise Unreadable("Install the pinned dependencies in "
                         "github-repo-steward/scripts/requirements.txt") from None
    try:
        with Image.open(BytesIO(data)) as image:
            return image.convert("RGBA")
    except (OSError, ValueError, SyntaxError, EOFError, Image.DecompressionBombError):
        access = "; only unauthenticated image access was checked" if scope == "Served" else ""
        raise Unreadable(f"{scope} image cannot be decoded{access}") from None


def image_record(data):
    return {"sha256": hashlib.sha256(data).hexdigest(), "byte_length": len(data),
            "dimensions": None}


def metadata(response, field):
    if not isinstance(response, dict) or response.get("errors"):
        raise Unreadable("GitHub GraphQL returned errors or invalid metadata")
    data = response.get("data")
    node = data.get(field) if isinstance(data, dict) else None
    if not isinstance(node, dict):
        raise Unreadable(f"GitHub {field} metadata is unavailable; check target access")
    return node


def required_text(node, key):
    value = node.get(key)
    if not isinstance(value, str) or not value:
        raise Unreadable(f"GitHub metadata is missing a valid {key}")
    return value


def avatar_psnr(local, served):
    from PIL import Image, ImageChops

    resized = local.resize(served.size, Image.Resampling.BICUBIC)
    values = {}
    for color in ("white", "black"):
        background = Image.new("RGBA", served.size, color)
        expected = Image.alpha_composite(background, resized).convert("RGB")
        observed = Image.alpha_composite(background, served).convert("RGB")
        histogram = ImageChops.difference(expected, observed).histogram()
        squared_error = sum(count * (index % 256) ** 2 for index, count in enumerate(histogram))
        mse = squared_error / (served.width * served.height * 3)
        values[color] = 10 * math.log10(255 ** 2 / mse) if mse else math.inf
    return values


def finish(receipt, status, observation):
    receipt.update(exit_status=status, state=("pass", "mismatch", "unknown")[status])
    receipt["observations"].append(observation)
    return receipt


def verify(mode, target, image, source_commit=None, *, query=graphql,
           fetch=fetch_image, sleep=time.sleep):
    receipt = {"observed_at": datetime.now(timezone.utc).isoformat(), "mode": mode,
               "target": target, "source_commit": source_commit, "graphql_id": None,
               "local": None, "served": None, "pixel_equal": None, "psnr_db": None,
               "attempts": 0, "observations": []}
    try:
        try:
            local_data = Path(image).read_bytes()
        except OSError:
            raise Unreadable("Local image cannot be read") from None
        receipt["local"] = image_record(local_data)
        local = decode(local_data, "Local")
        receipt["local"]["dimensions"] = list(local.size)
        if mode == "social-preview" and local.size != (1280, 640):
            return finish(receipt, 1, "Local social preview must be 1280x640")

        for attempt in range(4 if mode == "social-preview" else 1):
            receipt.update(attempts=attempt + 1, graphql_id=None, served=None, pixel_equal=None)
            if mode == "social-preview":
                owner, name = target.split("/")
                node = metadata(query(SOCIAL_QUERY, {"owner": owner, "name": name}), "repository")
                receipt["graphql_id"] = required_text(node, "id")
                if required_text(node, "nameWithOwner").casefold() != target.casefold():
                    return finish(receipt, 1, "Returned repository does not match the requested target")
                custom = node.get("usesCustomOpenGraphImage")
                if not isinstance(custom, bool):
                    raise Unreadable("GitHub metadata is missing a valid usesCustomOpenGraphImage")
                if not custom:
                    return finish(receipt, 1, "Repository does not use a custom social preview")
                url = required_text(node, "openGraphImageUrl")
            else:
                node = metadata(query(AVATAR_QUERY, {"login": target, "size": local.width}), "organization")
                if required_text(node, "login").casefold() != target.casefold():
                    return finish(receipt, 1, "Returned organization does not match the requested target")
                url = required_text(node, "avatarUrl")

            served_data = fetch(url)
            receipt["served"] = image_record(served_data)
            served = decode(served_data, "Served")
            receipt["served"]["dimensions"] = list(served.size)
            if mode == "avatar":
                values = avatar_psnr(local, served)
                # Strict JSON has no numeric infinity; exact matches retain its meaning.
                receipt["psnr_db"] = {key: value if math.isfinite(value) else "infinity"
                                      for key, value in values.items()}
                passed = all(value >= 30 for value in values.values())
                return finish(receipt, 0 if passed else 1,
                              "Avatar PSNR is at least 30 dB on white and black" if passed else
                              "Avatar PSNR is below 30 dB on white or black")

            if served.size != (1280, 640):
                return finish(receipt, 1, "Served social preview must be 1280x640")
            receipt["pixel_equal"] = local.tobytes() == served.tobytes()
            if receipt["pixel_equal"]:
                if local_data != served_data:
                    receipt["observations"].append("re-encoded")
                return finish(receipt, 0, "Social preview RGBA pixels match at 1280x640")
            receipt["observations"].append(f"RGBA pixel mismatch on attempt {attempt + 1}")
            if attempt < 3:
                sleep(5)
        return finish(receipt, 1, "Social preview pixels differ after three retries")
    except Unreadable as error:
        return finish(receipt, 2, str(error))


def main(argv=None, *, query=graphql, fetch=fetch_image, sleep=time.sleep):
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_subparsers(dest="mode", required=True)
    social = modes.add_parser("social-preview", help="compare exact 1280x640 RGBA pixels")
    social.add_argument("--repository", required=True)
    avatar = modes.add_parser("avatar", help="compare organization avatar PSNR on white and black")
    avatar.add_argument("--organization", required=True)
    for mode in (social, avatar):
        mode.add_argument("--image", required=True, type=Path)
        mode.add_argument("--source-commit")
        mode.add_argument("--json", type=Path)
    args = parser.parse_args(argv)
    target = args.repository if args.mode == "social-preview" else args.organization
    pattern = r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+" if args.mode == "social-preview" else r"[A-Za-z0-9-]+"
    if not re.fullmatch(pattern, target):
        parser.error("Use OWNER/NAME for a repository or LOGIN for an organization")
    receipt = verify(args.mode, target, args.image, args.source_commit,
                     query=query, fetch=fetch, sleep=sleep)
    if args.json:
        try:
            args.json.parent.mkdir(parents=True, exist_ok=True)
            args.json.write_text(json.dumps(receipt, indent=2, allow_nan=False) + "\n", encoding="utf-8")
        except OSError:
            finish(receipt, 2, "Cannot write JSON receipt")
    print(f"{receipt['state'].upper()} {args.mode} {target}: " + "; ".join(receipt["observations"]))
    return receipt["exit_status"]


if __name__ == "__main__":
    sys.exit(main())
