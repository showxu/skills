"""Read-only profile observations; schema and rendering remain renderer-owned."""

import base64
import importlib.util
from http.client import HTTPException
import json
from pathlib import Path
import re
import subprocess
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlencode, urlsplit, urlunsplit
from urllib.request import Request, urlopen


class Unreadable(ValueError):
    pass


def api(endpoint):
    result = subprocess.run(["gh", "api", endpoint], capture_output=True)
    if result.returncode:
        raise Unreadable(f"GitHub API could not read {endpoint}")
    return json.loads(result.stdout)


def content(owner, repository, path, revision):
    endpoint = f"repos/{owner}/{repository}/contents/{quote(path, safe='/')}?" + urlencode({"ref": revision})
    value = api(endpoint)
    if not isinstance(value, dict) or value.get("encoding") != "base64":
        raise Unreadable(f"Expected a readable file at {repository}/{path}")
    return base64.b64decode(value["content"])


def load_renderer(path=None):
    root = path or Path(__file__).resolve().parents[2] / "github-readme-design"
    script = root / "scripts/render_profile.py"
    if not script.is_file():
        raise Unreadable("Install github-readme-design or pass --readme-design <skill-directory>")
    spec = importlib.util.spec_from_file_location("organization_profile_renderer", script)
    module = importlib.util.module_from_spec(spec)
    sys.path.insert(0, str(script.parent))
    try:
        spec.loader.exec_module(module)
    finally:
        sys.path.pop(0)
    return module


def image_resolves(url):
    try:
        # No account credentials are sent to image hosts. GET also checks hosts that reject HEAD.
        parsed = urlsplit(url)
        hostname = parsed.hostname.encode("idna").decode("ascii")
        authority = f"[{hostname}]" if ":" in hostname else hostname
        if parsed.port is not None:
            authority += f":{parsed.port}"
        encoded = urlunsplit((parsed.scheme, authority,
                              quote(parsed.path, safe="/%:@!$&'()*+,;=-._~"),
                              quote(parsed.query, safe="%=&?/:@!$'()*+,;~-._"), ""))
        with urlopen(Request(encoded, headers={"User-Agent": "profile-link-check"}), timeout=20) as response:
            if urlsplit(response.url).scheme != "https":
                return False
            return response.headers.get_content_type().startswith("image/") and bool(response.read(1))
    except HTTPError as error:
        if error.code in (404, 410):
            return False
        raise Unreadable(f"Icon request returned HTTP {error.code}: {url}") from error
    except (OSError, URLError, HTTPException, ValueError, UnicodeError) as error:
        raise Unreadable(f"Icon request unavailable: {url}") from error


def membership(expected, observed, report, repository, label):
    missing, extra = expected - observed, observed - expected
    if missing or extra:
        report("FAIL", repository, f"{label}: missing {sorted(missing)}, extra {sorted(extra)}")
    else:
        report("INFO", repository, f"{label}: {len(expected)} repositories match")


def inspect_profiles(owner, repos, report, renderer_path=None, member_path="profile/member.json"):
    inventory = {repo["name"].lower(): repo for repo in repos}
    private = inventory.get(".github-private")
    if private is None:
        report("REVIEW", ".github-private", "not visible in authenticated inventory (absent or unreadable); optional when none exists")
    else:
        visibility = private.get("visibility")
        report("REVIEW" if visibility is None else "INFO" if visibility == "private" else "FAIL", ".github-private",
               f"exists; visibility is {visibility or 'unknown'} (member profiles require private)")
    public = inventory.get(".github")
    if public is None:
        report("REVIEW", ".github", "public profile catalog is unreadable or absent")
        return
    visibility = public.get("visibility")
    report("REVIEW" if visibility is None else "INFO" if visibility == "public" else "FAIL",
           ".github", f"public profile repository visibility is {visibility or 'unknown'} (requires public)")
    try:
        renderer = load_renderer(renderer_path)
        branch = public["defaultBranchRef"]["name"]
        catalog_bytes = content(owner, ".github", "profile/catalog.json", branch)
        catalog = renderer.load_json(catalog_bytes)
        members = renderer.validate_catalog(catalog)
        if catalog["organization"]["login"].lower() != owner.lower():
            raise ValueError("Catalog organization differs from scanned organization")
    except Unreadable as error:
        report("REVIEW", ".github", str(error))
        return
    except (ValueError, KeyError, TypeError) as error:
        report("FAIL", ".github", f"Invalid public catalog: {error}")
        return
    if any(repo.get("visibility") is None for repo in repos):
        report("REVIEW", ".github", "inventory visibility incomplete; cannot verify public membership")
    else:
        expected = {name for name, repo in inventory.items()
                    if repo["visibility"] == "public" and not repo["isArchived"] and name != ".github"}
        membership(expected, set(members), report, ".github", "public catalog membership")
    inspect_icons(renderer, catalog, branch, report)
    if private is None:
        return
    try:
        member = renderer.load_json(content(owner, ".github-private", member_path, private["defaultBranchRef"]["name"]))
        revision = member["catalog"]["revision"]
        # Validate the pin before using it in an API request.
        if not isinstance(revision, str) or not re.fullmatch(r"[0-9a-f]{40}", revision):
            raise ValueError("Catalog revision must be a full commit SHA")
        pinned_bytes = content(owner, ".github", "profile/catalog.json", revision)
        pinned = renderer.load_json(pinned_bytes)
        pinned_members = renderer.validate_catalog(pinned)
        operations = renderer.validate_member(member, pinned_members, pinned_bytes)
        if pinned["organization"]["login"].lower() != owner.lower():
            raise ValueError("Pinned catalog organization differs from scanned organization")
        membership(set(members), set(pinned_members), report, ".github-private", "pinned/current catalog membership")
        report("INFO", ".github-private", f"member input covers all {len(pinned_members)} pinned catalog repositories; digest verified at {revision}")
    except Unreadable as error:
        report("REVIEW", ".github-private", str(error))
        return
    except (ValueError, KeyError, TypeError) as error:
        report("FAIL", ".github-private", f"Invalid member input or catalog binding: {error}")
        return
    inspect_icons(renderer, pinned, revision, report)
    for name, facts in operations.items():
        repo = inventory.get(name.lower())
        if repo is None:
            report("REVIEW", name, "repository is absent or unreadable; operational facts not checked")
            continue
        branch = (repo.get("defaultBranchRef") or {}).get("name")
        if not branch:
            report("REVIEW", name, "GitHub default branch is unreadable; branch/workflow facts not checked")
        else:
            report("INFO" if branch == facts["default_branch"] else "FAIL", name,
                   f"default branch: declared {facts['default_branch']}, GitHub reports {branch}")
        if branch and facts["workflow"] is not None:
            try:
                path = ".github/workflows/" + facts["workflow"]
                tree = api(f"repos/{owner}/{name}/git/trees/{quote(branch, safe='')}?recursive=1")
                if tree.get("truncated") or not isinstance(tree.get("tree"), list):
                    raise Unreadable("Default-branch tree is incomplete")
                exists = any(item["path"] == path and item["type"] == "blob" for item in tree["tree"])
                report("INFO" if exists else "FAIL", name,
                       f"declared workflow {'exists' if exists else 'is missing'} on default branch {branch}: {path}")
            except (Unreadable, KeyError, TypeError) as error:
                report("REVIEW", name, str(error))
        try:
            # Published releases include prereleases; drafts are not dashboard state.
            pages = api(f"repos/{owner}/{name}/releases?per_page=100")
            if not isinstance(pages, list):
                raise Unreadable("Release list is not readable")
            published = any(not item["draft"] for item in pages)
            page = 2
            while not published and len(pages) == 100:
                pages = api(f"repos/{owner}/{name}/releases?per_page=100&page={page}")
                published = any(not item["draft"] for item in pages)
                page += 1
            if published != (facts["releases"] == "published"):
                report("FAIL", name, f"release presence differs: declared {facts['releases']}, published release observed {published}")
            else:
                report("INFO", name, "release presence matches member input")
        except (Unreadable, KeyError, TypeError) as error:
            report("REVIEW", name, f"Release observation unavailable: {error}")


def inspect_icons(renderer, catalog, revision, report):
    images = [catalog["mark"]] + [repo["icon"] for group in catalog["groups"] for repo in group["repositories"]]
    urls = {renderer.catalog_url(url, catalog, revision, image=True)
            for value in images for url in ([value] if isinstance(value, str) else value.values())}
    for url in sorted(urls):
        try:
            report("INFO" if image_resolves(url) else "FAIL", ".github", f"icon resolution: {url}")
        except Unreadable as error:
            report("REVIEW", ".github", str(error))
