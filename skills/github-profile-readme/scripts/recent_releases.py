#!/usr/bin/env python3
"""Rewrite the recent releases block in a GitHub profile README."""

import argparse
import json
import os
import re
import sys
import urllib.request

START = "<!-- recent-releases:start -->"
END = "<!-- recent-releases:end -->"
QUERY = """
query($login: String!) {
  repositoryOwner(login: $login) {
    repositories(first: 100, privacy: PUBLIC, isFork: false, orderBy: {field: PUSHED_AT, direction: DESC}) {
      nodes {
        name
        isArchived
        latestRelease { tagName url publishedAt }
      }
    }
  }
}
"""


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("readme", nargs="?", default="README.md")
    parser.add_argument(
        "--owner",
        action="append",
        required=True,
        help="User or organization whose public repositories to scan. Repeat for several owners.",
    )
    parser.add_argument("--limit", type=int, default=6, help="Number of releases to list. Default: 6.")
    return parser.parse_args()


def fetch_repositories(owner, token):
    body = json.dumps({"query": QUERY, "variables": {"login": owner}}).encode()
    request = urllib.request.Request(
        "https://api.github.com/graphql",
        data=body,
        headers={"Authorization": f"bearer {token}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        payload = json.load(response)
    if payload.get("errors"):
        sys.exit(f"GraphQL error for {owner}: {payload['errors'][0]['message']}")
    owner_node = payload["data"]["repositoryOwner"]
    if owner_node is None:
        sys.exit(f"Owner not found: {owner}")
    return owner_node["repositories"]["nodes"]


def recent_releases(owners, limit, token):
    releases = []
    for owner in owners:
        for repo in fetch_repositories(owner, token):
            release = repo["latestRelease"]
            if release and not repo["isArchived"]:
                releases.append((release["publishedAt"], repo["name"], release))
    releases.sort(key=lambda item: item[0], reverse=True)
    return releases[:limit]


def render(releases):
    lines = []
    for published_at, name, release in releases:
        version = re.sub(rf"^(?:{re.escape(name)}[-_]?)?v?(?=\d)", "", release["tagName"])
        lines.append(f"- [{name} {version}]({release['url']}) - {published_at[:10]}")
    return "\n".join(lines)


def main():
    args = parse_args()
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if not token:
        sys.exit("Set GITHUB_TOKEN or GH_TOKEN.")

    try:
        with open(args.readme, encoding="utf-8") as handle:
            readme = handle.read()
    except FileNotFoundError:
        sys.exit(f"README not found: {args.readme}")
    pattern = re.compile(f"{re.escape(START)}\n.*?{re.escape(END)}", re.DOTALL)
    if not pattern.search(readme):
        sys.exit(f"Markers {START} and {END} not found in {args.readme}.")

    releases = recent_releases(args.owner, args.limit, token)
    if not releases:
        sys.exit("No releases found; leaving the README unchanged.")

    block = f"{START}\n{render(releases)}\n{END}"
    updated = pattern.sub(lambda _: block, readme, count=1)
    if updated == readme:
        print("Recent releases unchanged.")
        return
    with open(args.readme, "w", encoding="utf-8") as handle:
        handle.write(updated)
    print(f"Updated {len(releases)} recent releases.")


if __name__ == "__main__":
    main()
