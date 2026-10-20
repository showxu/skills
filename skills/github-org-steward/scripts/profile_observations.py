"""Read-only profile observations; schema and rendering remain renderer-owned."""

import base64
from http.client import HTTPException
import json
from pathlib import Path
import re
import posixpath
import subprocess
from urllib.error import HTTPError, URLError
from urllib.parse import quote, unquote, urlencode, urlsplit, urlunsplit
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


def observed_text(value, context):
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{context} must be a nonempty string")
    return value


def observed_icon(value):
    if isinstance(value, str):
        observed_text(value, "icon URL")
    elif isinstance(value, dict):
        for appearance in ("light", "dark"):
            observed_text(value[appearance], f"icon.{appearance}")
    else:
        raise ValueError("icon must be a URL or light/dark URLs")


def observed_catalog(catalog):
    if not isinstance(catalog, dict):
        raise ValueError("catalog must be an object")
    observed_text(catalog["organization"]["login"], "organization.login")
    observed_icon(catalog["mark"])
    if not isinstance(catalog["groups"], list):
        raise ValueError("catalog.groups must be an array")
    members = {}
    for group in catalog["groups"]:
        if not isinstance(group["repositories"], list):
            raise ValueError("group.repositories must be an array")
        for repo in group["repositories"]:
            name = observed_text(repo["name"], "repository.name")
            observed_icon(repo["icon"])
            if name.lower() in members:
                raise ValueError(f"Duplicate observed repository: {name}")
            members[name.lower()] = repo
    return members


def profile_revision(owner, branch):
    try:
        import yaml
    except ImportError as error:
        requirements = Path(__file__).with_name("requirements.txt")
        raise Unreadable(f"Profile standard pin unknown: PyYAML is missing; install requirements from {requirements}") from error
    tree = api(f"repos/{owner}/.github-private/git/trees/{quote(branch, safe='')}?recursive=1")
    if tree.get("truncated") or not isinstance(tree.get("tree"), list):
        raise Unreadable("Profile standard pin unknown: workflow tree is incomplete")
    target = f"{owner}/.github/.github/workflows/profile.yml@"
    revisions = {}
    for entry in tree["tree"]:
        path = entry["path"]
        if entry["type"] != "blob" or not re.fullmatch(r"\.github/workflows/[^/]+\.ya?ml", path):
            continue
        try:
            workflow = yaml.safe_load(content(owner, ".github-private", path, branch))
        except (yaml.YAMLError, UnicodeError) as error:
            raise Unreadable(f"Profile standard pin unknown: cannot parse {path}") from error
        jobs = workflow.get("jobs", {}) if isinstance(workflow, dict) else {}
        if not isinstance(jobs, dict):
            raise Unreadable(f"Profile standard pin unknown: invalid jobs in {path}")
        for job in jobs.values():
            use = job.get("uses") if isinstance(job, dict) else None
            if not isinstance(use, str) or not use.lower().startswith(target.lower()):
                continue
            revision = use[len(target):]
            if not re.fullmatch(r"[0-9a-fA-F]{40}", revision):
                raise ValueError(f"{path}: profile workflow must pin a full commit SHA")
            revisions.setdefault(revision.lower(), set()).add(path)
    if not revisions:
        raise Unreadable("Profile standard pin unknown: no matching workflow caller")
    if len(revisions) > 1:
        callers = "; ".join(f"{path}: {revision}" for revision, paths in sorted(revisions.items()) for path in sorted(paths))
        raise Unreadable(f"Profile standard pin unknown: conflicting workflow caller pins: {callers}")
    return next(iter(revisions))


def catalog_image_url(value, catalog, revision):
    value = observed_text(value, "icon URL")
    decoded = unquote(value)
    if any(c.isspace() for c in value) or any(ord(c) < 32 or ord(c) == 127 for c in decoded) or "\\" in decoded:
        raise ValueError("Invalid icon URL")
    parsed = urlsplit(decoded)
    if parsed.scheme:
        parsed.port
        if parsed.scheme.lower() != "https" or not parsed.hostname or parsed.username or parsed.password:
            raise ValueError("Icon URLs must use HTTPS or be repository-relative")
        return value
    if decoded.startswith("/") or ":" in parsed.path.split("/")[0]:
        raise ValueError("Icon URLs must use HTTPS or be repository-relative")
    path = posixpath.normpath(posixpath.join("profile", unquote(parsed.path) or "README.md"))
    if path == ".." or path.startswith("../"):
        raise ValueError("Icon path escapes the profile repository")
    original = urlsplit(value)
    path = posixpath.normpath(posixpath.join("profile", unquote(original.path) or "README.md"))
    owner = catalog["organization"]["login"]
    return urlunsplit(("https", "raw.githubusercontent.com",
                       f"/{owner}/.github/{quote(revision, safe='')}/{quote(path, safe='/')}",
                       original.query, original.fragment))


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


def inspect_profiles(owner, repos, report, member_path="profile/member.json"):
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
        branch = public["defaultBranchRef"]["name"]
        catalog_bytes = content(owner, ".github", "profile/catalog.json", branch)
        catalog = json.loads(catalog_bytes)
        members = observed_catalog(catalog)
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
    inspect_icons(catalog, branch, report)
    if "description" in catalog:
        try:
            observed = api(f"orgs/{owner}").get("description")
            report("INFO" if observed == catalog["description"] else "FAIL", ".github",
                   "account description matches the catalog" if observed == catalog["description"]
                   else f"account description differs: catalog {catalog['description']!r}, GitHub {observed!r}")
        except (Unreadable, AttributeError) as error:
            report("REVIEW", ".github", f"Account description unavailable: {error}")
    if private is None:
        return
    try:
        member = json.loads(content(owner, ".github-private", member_path, private["defaultBranchRef"]["name"]))
        revision = profile_revision(owner, private["defaultBranchRef"]["name"])
        pinned_bytes = content(owner, ".github", "profile/catalog.json", revision)
        pinned = json.loads(pinned_bytes)
        pinned_members = observed_catalog(pinned)
        operations = member["repositories"]
        if not isinstance(operations, dict):
            raise ValueError("Member repositories must be an object")
        expected = {repo["name"] for repo in pinned_members.values()}
        missing, extra = expected - operations.keys(), operations.keys() - expected
        if missing or extra:
            raise ValueError(f"Member membership mismatch: missing {sorted(missing)}, extra {sorted(extra)}")
        for name, facts in operations.items():
            observed_text(facts["default_branch"], f"{name}.default_branch")
            if facts["workflow"] is not None:
                observed_text(facts["workflow"], f"{name}.workflow")
            observed_text(facts["releases"], f"{name}.releases")
        if pinned["organization"]["login"].lower() != owner.lower():
            raise ValueError("Pinned catalog organization differs from scanned organization")
        membership(set(members), set(pinned_members), report, ".github-private", "pinned/current catalog membership")
        report("INFO", ".github-private", f"member input covers all {len(pinned_members)} pinned catalog repositories; workflow pin {revision}")
    except Unreadable as error:
        report("REVIEW", ".github-private", str(error))
        return
    except (ValueError, KeyError, TypeError) as error:
        report("FAIL", ".github-private", f"Invalid member input or workflow pin: {error}")
        return
    inspect_icons(pinned, revision, report)
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


def inspect_icons(catalog, revision, report):
    images = [catalog["mark"]] + [repo["icon"] for group in catalog["groups"] for repo in group["repositories"]]
    try:
        urls = {catalog_image_url(url, catalog, revision)
                for value in images for url in ([value] if isinstance(value, str) else (value["light"], value["dark"]))}
    except (ValueError, TypeError, KeyError) as error:
        report("FAIL", ".github", f"Invalid observed icon: {error}")
        return
    for url in sorted(urls):
        try:
            report("INFO" if image_resolves(url) else "FAIL", ".github", f"icon resolution: {url}")
        except Unreadable as error:
            report("REVIEW", ".github", str(error))
