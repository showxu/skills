#!/usr/bin/env python3
"""Render public and member organization profiles from a shared catalog."""

import argparse
import hashlib
from html import escape
import json
from pathlib import Path
import posixpath
import re
import sys
from urllib.parse import quote, unquote, urlencode, urlsplit, urlunsplit

from presentation import load_spec, plain


DEFAULTS = {
    "public_header_icon_size": 128,
    "member_header_icon_size": 64,
    "public_row_icon_size": 40,
    "member_row_icon_size": 24,
    "badge_style": "flat",
}
NAVIGATION = ("documentation", "contributing", "security", "support")
MAINTENANCE = ("maintenance", "versioning", "settings", "design")


def load_json(data):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f"Duplicate JSON field: {key}")
            result[key] = value
        return result
    return json.loads(data, object_pairs_hook=unique)


def fields(value, required, optional=(), context="input"):
    if not isinstance(value, dict):
        raise ValueError(f"{context} must be an object")
    missing, extra = set(required) - value.keys(), value.keys() - set(required) - set(optional)
    if missing or extra:
        raise ValueError(f"{context}: missing fields {sorted(missing)}, unknown fields {sorted(extra)}")


def text(value):
    value = plain(value)
    if not value.strip():
        raise ValueError("Profile text must not be empty")
    return value


def link(value):
    value = text(value)
    decoded = unquote(value)
    if any(c.isspace() for c in value) or any(ord(c) < 32 or ord(c) == 127 for c in decoded) or "\\" in decoded:
        raise ValueError("Links must not contain whitespace, controls or backslashes")
    parsed = urlsplit(decoded)
    if parsed.scheme:
        parsed.port  # Validate malformed or out-of-range URL ports.
        if parsed.scheme.lower() != "https" or not parsed.hostname or parsed.username or parsed.password:
            raise ValueError("Links must use https: or be repository-relative")
    elif parsed.netloc or decoded.startswith("/") or ":" in parsed.path.split("/")[0]:
        raise ValueError("Links must use https: or be repository-relative")
    if not parsed.scheme:
        path = posixpath.normpath(posixpath.join("profile", unquote(parsed.path) or "README.md"))
        if path == ".." or path.startswith("../"):
            raise ValueError("Relative link escapes the profile repository")
    return value


def identifier(value, kind):
    pattern = r"[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?" if kind == "organization" else r"[A-Za-z0-9_.-]+"
    if not isinstance(value, str) or not re.fullmatch(pattern, value) or value in {".", ".."}:
        raise ValueError(f"Invalid {kind} identifier")
    return value


def icon(value):
    if isinstance(value, str):
        link(value)
    else:
        fields(value, ("light", "dark"), context="icon")
        for url in value.values():
            link(url)


def navigation(value, roles, complete=False):
    fields(value, roles if complete else (), () if complete else roles, "navigation")
    for item in value.values():
        fields(item, ("label", "url"), context="navigation link")
        text(item["label"])
        link(item["url"])


def validate_catalog(catalog):
    fields(catalog, ("organization", "promise", "secondary", "mark", "navigation", "groups"),
           ("website", "maintainer"), "catalog")
    fields(catalog["organization"], ("login", "name"), context="organization")
    identifier(catalog["organization"]["login"], "organization")
    for value in (catalog["organization"]["name"], catalog["promise"], catalog["secondary"]):
        text(value)
    icon(catalog["mark"])
    navigation(catalog["navigation"], NAVIGATION)
    if "website" in catalog:
        link(catalog["website"])
    if "maintainer" in catalog:
        fields(catalog["maintainer"], ("label", "url"), context="maintainer")
        text(catalog["maintainer"]["label"])
        link(catalog["maintainer"]["url"])
    if not isinstance(catalog["groups"], list):
        raise ValueError("Catalog groups must be an ordered array")
    repositories = {}
    for group in catalog["groups"]:
        fields(group, ("title", "repositories"), context="group")
        text(group["title"])
        if not isinstance(group["repositories"], list) or not group["repositories"]:
            raise ValueError("Each group needs a nonempty repositories array")
        for repo in group["repositories"]:
            fields(repo, ("name", "outcome", "icon"), context="repository")
            name = identifier(repo["name"], "repository")
            if name.lower() in repositories:
                raise ValueError(f"Duplicate catalog repository: {name}")
            if name.lower() in {".github", ".github-private"}:
                raise ValueError(f"{name} is not a public catalog member")
            text(repo["outcome"])
            icon(repo["icon"])
            repositories[name.lower()] = repo
    return repositories


def validate_member(member, repositories, catalog_bytes):
    fields(member, ("catalog", "maintenance", "repositories"), context="member input")
    fields(member["catalog"], ("revision", "sha256"), context="catalog binding")
    binding = member["catalog"]
    if not isinstance(binding["revision"], str) or not re.fullmatch(r"[0-9a-f]{40}", binding["revision"]):
        raise ValueError("Catalog revision must be a full commit SHA")
    if binding["sha256"] != hashlib.sha256(catalog_bytes).hexdigest():
        raise ValueError("Catalog digest differs from the member binding")
    navigation(member["maintenance"], MAINTENANCE, complete=True)
    operations = member["repositories"]
    if not isinstance(operations, dict):
        raise ValueError("Member repositories must be an object keyed by catalog name")
    expected = {repo["name"] for repo in repositories.values()}
    missing, extra = expected - operations.keys(), operations.keys() - expected
    if missing or extra:
        raise ValueError(f"Member membership mismatch: missing {sorted(missing)}, extra {sorted(extra)}")
    for name, facts in operations.items():
        fields(facts, ("default_branch", "workflow", "releases"), context=f"operations for {name}")
        text(facts["default_branch"])
        workflow = facts["workflow"]
        if workflow is not None and (not isinstance(workflow, str) or not re.fullmatch(r"[A-Za-z0-9_.-]+\.ya?ml", workflow)):
            raise ValueError("Workflow must be a filename ending in .yml or .yaml, or null")
        if facts["releases"] not in ("published", "channel", "none"):
            raise ValueError("Releases must be published, channel or none")
    return operations


def tokens(spec):
    fields(spec, (), (*DEFAULTS, "design_source", "design_sha256"), "profile recipe")
    values = dict(DEFAULTS, **spec)
    for key in DEFAULTS.keys() - {"badge_style"}:
        if type(values[key]) is not int or values[key] <= 0:
            raise ValueError(f"{key} must be a positive integer in pixels")
    if values["badge_style"] not in ("flat", "flat-square", "plastic", "for-the-badge", "social"):
        raise ValueError("Unsupported badge_style")
    return values


def catalog_url(value, catalog, revision=None, image=False):
    value = link(value)
    if revision is None or urlsplit(value).scheme:
        return value
    parsed = urlsplit(value)
    path = posixpath.normpath(posixpath.join("profile", unquote(parsed.path) or "README.md"))
    if path == ".." or path.startswith("../"):
        raise ValueError("Catalog relative link escapes the .github repository")
    owner = catalog["organization"]["login"]
    base = f"https://raw.githubusercontent.com/{owner}/.github/{quote(revision, safe='')}" if image else f"https://github.com/{owner}/.github/blob/{quote(revision, safe='')}"
    return urlunsplit(("https", urlsplit(base).netloc, urlsplit(base).path + "/" + quote(path, safe="/"), parsed.query, parsed.fragment))


def anchor(url, label):
    return f'<a href="{escape(link(url), quote=True)}">{escape(text(label))}</a>'


def image_tag(value, label, size, resolve):
    def img(url):
        return f'<img src="{escape(resolve(url), quote=True)}" width="{size}" height="{size}" alt="{escape(label, quote=True)}">'
    if isinstance(value, str):
        return img(value)
    return ('<picture><source media="(prefers-color-scheme: dark)" '
            f'srcset="{escape(resolve(value["dark"]), quote=True)}">{img(value["light"])}</picture>')


def badge(url, image_url, label):
    return f'<a href="{escape(link(url), quote=True)}"><img src="{escape(link(image_url), quote=True)}" alt="{escape(label, quote=True)}"></a>'


def render(catalog, spec, member=None, catalog_bytes=None):
    repositories = validate_catalog(catalog)
    style = tokens(spec)
    operations = validate_member(member, repositories, catalog_bytes) if member is not None else None
    mode = "member" if member is not None else "public"
    revision = member["catalog"]["revision"] if member is not None else None
    resolve = lambda value: catalog_url(value, catalog, revision)
    resolve_image = lambda value: catalog_url(value, catalog, revision, image=True)
    owner = catalog["organization"]["login"]
    name = catalog["organization"]["name"]
    title = f"{name} maintainer dashboard" if member is not None else catalog["promise"]
    header = image_tag(catalog["mark"], f"{name} mark", style[f"{mode}_header_icon_size"], resolve_image)
    output = [f'<p align="center">{header}</p>', '', f'<h1 align="center">{escape(title)}</h1>', '']
    if member is None:
        output.extend([f'<p align="center">{escape(catalog["secondary"])}</p>', ''])
        links = [anchor(resolve(catalog["navigation"][role]["url"]), catalog["navigation"][role]["label"])
                 for role in NAVIGATION if role in catalog["navigation"]]
        if links:
            output.extend(['<p align="center">' + ' · '.join(links) + '</p>', ''])
    else:
        public = resolve(catalog["website"]) if "website" in catalog else f"https://github.com/{owner}"
        output.extend([f'<p align="center">{anchor(public, "Public website" if "website" in catalog else "Public profile")}</p>', '',
                       '<h2>Maintenance</h2>', '', '<p>' + ' · '.join(
                           anchor(member["maintenance"][role]["url"], member["maintenance"][role]["label"])
                           for role in MAINTENANCE) + '</p>', '', '<h2>Repositories</h2>', ''])
    for group in catalog["groups"]:
        heading = "h3" if member is not None else "h2"
        output.extend([f'<{heading}>{escape(group["title"])}</{heading}>', '', '<table>'])
        if member is not None:
            output.append('<tr><th>Repository</th><th>CI</th><th>Release</th></tr>')
        for repo in group["repositories"]:
            url = f'https://github.com/{owner}/{repo["name"]}'
            mark = image_tag(repo["icon"], f'{repo["name"]} icon', style[f"{mode}_row_icon_size"], resolve_image)
            cell = f'<td>{mark} {anchor(url, repo["name"])}</td>'
            if member is None:
                output.append(f'<tr>{cell}<td>{escape(repo["outcome"])}</td></tr>')
            else:
                facts = operations[repo["name"]]
                ci = anchor(url + "/actions", "Actions")
                if facts["workflow"] is not None:
                    workflow = quote(facts["workflow"], safe="")
                    ci = badge(url + "/actions/workflows/" + workflow + "?" + urlencode({"query": "branch:" + facts["default_branch"]}),
                               f'https://img.shields.io/github/actions/workflow/status/{owner}/{repo["name"]}/{workflow}?'
                               + urlencode({"branch": facts["default_branch"], "style": style["badge_style"], "label": "CI"}), f'{repo["name"]} CI')
                release = "—"
                if facts["releases"] == "published":
                    release = badge(url + "/releases", f'https://img.shields.io/github/v/release/{owner}/{repo["name"]}?'
                                    + urlencode({"style": style["badge_style"], "sort": "date", "include_prereleases": "true"}), f'{repo["name"]} latest release')
                elif facts["releases"] == "channel":
                    release = anchor(url + "/releases", "Releases")
                output.append(f'<tr>{cell}<td>{ci}</td><td>{release}</td></tr>')
        output.extend(['</table>', ''])
    if member is not None:
        output.extend(['<h2>Needs attention</h2>', '', '<ul>'])
        for label, query in (("Open pull requests", "is:pr is:open"), ("Open issues", "is:issue is:open"),
                             ("Dependabot pull requests", "is:pr is:open author:app/dependabot")):
            url = "https://github.com/search?" + urlencode({"q": f"org:{owner} {query}", "type": "issues"})
            output.append(f'<li>{anchor(url, label)}</li>')
        output.extend(['</ul>', ''])
    elif "maintainer" in catalog:
        output.extend(['<p>' + anchor(resolve(catalog["maintainer"]["url"]), catalog["maintainer"]["label"]) + '</p>', ''])
    return "\n".join(output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", type=Path, required=True)
    parser.add_argument("--member", type=Path, help="member input; omit for the public profile")
    parser.add_argument("--spec", type=Path, help="resolved DESIGN presentation recipe")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    catalog_bytes = args.catalog.read_bytes()
    catalog = load_json(catalog_bytes)
    member = load_json(args.member.read_bytes()) if args.member else None
    spec = load_spec(args.spec)[0] if args.spec else {}
    value = render(catalog, spec, member, catalog_bytes).encode("utf-8")
    if args.check:
        if not args.output.is_file() or args.output.read_bytes() != value:
            raise ValueError(f"{args.output.name} differs from its inputs")
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_bytes(value)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, TypeError, OSError) as error:
        sys.exit(str(error))
