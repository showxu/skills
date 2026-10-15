#!/usr/bin/env python3
"""Observe one repository's accepted source, workflows, tags and content; no mutations.

This is partial acceptance evidence, not a complete settings or semantic audit.
Historical observations are REVIEW items; published history remains unchanged.
"""

import argparse
import getpass
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
from collections import defaultdict
from urllib.parse import quote

TOOL_IDENTITY = re.compile(r"cursor|claude|anthropic|openai|codex|copilot|devin", re.I)
TOOL_TRAILER = re.compile(
    r"^(co-authored-by|made-with|generated-by|generated-with|assisted-by):(?!.*\[bot\])|generated[ ]with|"
    r"cursor\.com|anthropic\.com|claude\.ai|openai\.com",
    re.I | re.M,
)
SECRET = r"BEGIN [A-Z ]*PRIVATE KEY|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}"
BAD_RUNS = {"failure", "cancelled", "timed_out", "action_required", "startup_failure"}
SUBJECT = re.compile(r"(?P<type>[A-Za-z][A-Za-z0-9_-]*)(?:\([^()\r\n]+\))?!?: \S[^\r\n]*")
REMOTE_WORKFLOW = re.compile(r"([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)/(\.github/workflows/[^/@\s]+\.ya?ml)@([^\s]+)")
FULL_PIN = re.compile(r"[0-9a-fA-F]{40}")


def run(*cmd, cwd=None, check=True):
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if check and result.returncode:
        raise SystemExit(f"{' '.join(cmd)}: {result.stderr.strip()}")
    return result.stdout


def latest_workflow_runs(runs):
    """A later run supersedes the earlier observation of the same workflow."""
    latest = {}
    for item in runs:
        key = item["workflowDatabaseId"]
        if key not in latest or item["databaseId"] > latest[key]["databaseId"]:
            latest[key] = item
    return list(latest.values())


def license_digest(path):
    licenses = [file.read_bytes() for file in (path / "LICENSE", path / "LICENSE.txt")
                if file.is_file()]
    unique = sorted(set(licenses))
    if not unique:
        return "none"
    if len(unique) == 1:
        return hashlib.sha256(unique[0]).hexdigest()[:12]
    return "multiple:" + ",".join(hashlib.sha256(data).hexdigest()[:12] for data in unique)


def signature_result(verification, source):
    """Unavailable verification is different from a proven policy mismatch."""
    verification = verification if isinstance(verification, dict) else {}
    reason = verification.get("reason", "missing verification")
    if verification.get("verified") is True:
        status = "pass"
    elif verification.get("verified") is False and reason in {
        "unsigned", "invalid", "malformed_signature", "expired_key", "not_signing_key",
        "no_user", "unverified_email", "bad_email", "unknown_key",
    }:
        status = "drift"
    else:
        status = "unknown"
    return {"status": status, "reason": reason, "source": source,
            "verified_at": verification.get("verified_at")}


def api_json(endpoint, paginated=False):
    flags = ("--paginate", "--slurp") if paginated else ()
    return json.loads(run("gh", "api", endpoint, *flags))


def audit_history(path, repository, head, signers=None, commit_types=()):
    """Audit accepted ancestry and every advertised tag, preserving legacy objects."""
    git = lambda *args: run("git", *args, cwd=path)  # noqa: E731
    if git("rev-parse", "--is-shallow-repository").strip() != "false":
        raise SystemExit("History audit needs complete ancestry, not a shallow clone")
    tags, roots = [], [head]
    for line in git("for-each-ref", "refs/tags", "--format=%(refname)%00%(objectname)%00%(objecttype)").splitlines():
        ref, oid, kind = line.split("\0")
        target = git("rev-parse", f"{ref}^{{}}").strip()
        target_type = git("cat-file", "-t", target).strip()
        if target_type == "commit":
            roots.append(target)
        item = {"name": ref.removeprefix("refs/tags/"), "object": oid, "type": kind,
                "target": target, "target_type": target_type}
        if kind != "tag":
            item["signature"] = {"status": "drift", "reason": "lightweight tag", "source": ref}
        elif signers and "-----BEGIN SSH SIGNATURE-----" in git("cat-file", "tag", oid):
            verified = subprocess.run(["git", "-c", f"gpg.ssh.allowedSignersFile={signers}",
                                       "verify-tag", oid], cwd=path, capture_output=True, text=True)
            item["signature"] = {"status": "pass" if verified.returncode == 0 else "drift",
                                 "reason": "trusted SSH verification" if verified.returncode == 0 else verified.stderr.strip(),
                                 "source": f"git verify-tag {oid}; supplied allowed signers"}
        else:
            endpoint = f"repos/{repository}/git/tags/{oid}"
            try:
                item["signature"] = signature_result(api_json(endpoint).get("verification"), endpoint)
            except (SystemExit, ValueError, AttributeError) as error:
                item["signature"] = {"status": "unknown", "reason": str(error), "source": endpoint}
        tags.append(item)

    roots = list(dict.fromkeys(roots))
    subjects = dict(line.split("\0", 1) for line in git("log", "--format=%H%x00%s", *roots, "--").splitlines())
    signatures, errors = {}, []
    for root in roots:
        if root in signatures:
            continue
        endpoint = f"repos/{repository}/commits?sha={root}&per_page=100"
        try:
            pages = api_json(endpoint, paginated=True)
            for page in pages:
                for item in page:
                    signatures[item["sha"]] = signature_result(item["commit"].get("verification"), endpoint)
        except (SystemExit, ValueError, KeyError, TypeError) as error:
            errors.append({"source": endpoint, "error": str(error)})
    missing, extra = sorted(subjects.keys() - signatures.keys()), sorted(signatures.keys() - subjects.keys())
    types = {value.casefold() for value in commit_types}
    commits = []
    for oid, subject in subjects.items():
        match = SUBJECT.fullmatch(subject)
        conventional = bool(match and (not types or match["type"].casefold() in types))
        commits.append({"sha": oid, "subject": subject, "conventional": conventional,
                        "signature": signatures.get(oid, {"status": "unknown", "reason": "missing API record",
                                                           "source": f"repos/{repository}/commits/{oid}"})})
    return {"roots": roots, "commit_types": sorted(types), "commits": commits, "tags": tags,
            "coverage": {"status": "unknown" if missing or extra or errors else "complete",
                         "missing": missing, "unexpected": extra, "errors": errors}}


def reusable_callers(text):
    """Parse job-level uses; shell text and action steps are not reusable callers."""
    import yaml

    class UniqueLoader(yaml.SafeLoader):
        pass

    def mapping(loader, node, deep=False):
        explicit = set()
        for key_node, _ in node.value:
            if key_node.tag == "tag:yaml.org,2002:merge":
                continue
            key = loader.construct_object(key_node, deep=deep)
            if key in explicit:
                raise ValueError(f"ambiguous duplicate YAML key: {key}")
            explicit.add(key)
        loader.flatten_mapping(node)
        return dict(loader.construct_pairs(node, deep=deep))

    UniqueLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, mapping)
    document = yaml.load(text, Loader=UniqueLoader)
    if not isinstance(document, dict) or not isinstance(document.get("jobs"), dict):
        raise ValueError("workflow must contain a jobs mapping")
    callers = []
    for job, config in document["jobs"].items():
        if not isinstance(config, dict):
            raise ValueError(f"invalid job mapping: {job}")
        if "uses" in config:
            callers.append({"job": str(job), "observed": config["uses"]})
    return callers


def shared_default(repository):
    metadata_endpoint = f"repos/{repository}"
    default = api_json(metadata_endpoint)["default_branch"]
    if not isinstance(default, str) or not default:
        raise ValueError("shared repository has no default branch")
    endpoint = f"repos/{repository}/commits/{quote(default, safe='')}"
    sha = api_json(endpoint)["sha"]
    if not isinstance(sha, str) or not FULL_PIN.fullmatch(sha):
        raise ValueError("shared default branch did not resolve to a full commit")
    return {"expected": sha, "default_branch": default, "source": [metadata_endpoint, endpoint]}


def audit_workflow_pins(path, resolver=shared_default):
    findings, resolved = [], {}
    directory = path / ".github/workflows"
    if (path / ".github").is_symlink() or directory.is_symlink():
        return [{"workflow": ".github/workflows", "status": "unknown", "reason": "symlinked workflow directory"}]
    for file in sorted(directory.iterdir() if directory.is_dir() else []):
        if file.suffix not in (".yml", ".yaml"):
            continue
        try:
            if file.is_symlink():
                raise ValueError("symlinked workflow file")
            callers = reusable_callers(file.read_text())
        except Exception as error:
            findings.append({"workflow": file.relative_to(path).as_posix(), "status": "unknown", "reason": str(error)})
            continue
        for caller in callers:
            item = {"workflow": file.relative_to(path).as_posix(), **caller}
            observed = caller["observed"]
            if isinstance(observed, str) and re.fullmatch(r"[.$]/\.github/workflows/[^/@\s]+\.ya?ml", observed):
                item.update(status="local", reason="bound to the caller commit")
            elif isinstance(observed, str) and (match := REMOTE_WORKFLOW.fullmatch(observed)):
                repository, workflow, ref = match.groups()
                item.update(repository=repository, called_workflow=workflow, observed=ref,
                            pinned=bool(FULL_PIN.fullmatch(ref)),
                            pin_status="pass" if FULL_PIN.fullmatch(ref) else "drift")
                if repository not in resolved:
                    try:
                        resolved[repository] = resolver(repository)
                    except (SystemExit, Exception) as error:
                        resolved[repository] = {"error": str(error)}
                target = resolved[repository]
                if "error" in target:
                    item.update(status="unknown", reason=target["error"])
                else:
                    item.update(target, status="pass" if ref.lower() == target["expected"].lower() else "drift")
            else:
                item.update(status="unknown", reason="unsupported reusable-workflow reference")
            findings.append(item)
    return findings


def report_source_audit(audit, pins, head, fork, name, report):
    if audit["coverage"]["status"] != "complete":
        report("UNKNOWN", name, f"accepted history coverage: {json.dumps(audit['coverage'])}")
    for item in audit["commits"]:
        level = "REVIEW" if fork or item["sha"] != head else "FAIL"
        if item["signature"]["status"] != "pass":
            report("UNKNOWN" if item["signature"]["status"] == "unknown" else level, name,
                   f"commit {item['sha']} signature: {json.dumps(item['signature'])}")
        if not item["conventional"]:
            report(level, name, f"commit {item['sha']} subject is not Conventional: {item['subject']!r}")
    for item in audit["tags"]:
        if item["signature"]["status"] != "pass" or item["target_type"] != "commit":
            report("UNKNOWN" if item["signature"]["status"] == "unknown" else "REVIEW", name,
                   f"tag {item['name']} ({item['object']} -> {item['target']}): {json.dumps(item['signature'])}; target type {item['target_type']}")
    for item in pins:
        if item["status"] not in ("pass", "local"):
            report("UNKNOWN" if item["status"] == "unknown" else "REVIEW", name,
                   f"reusable-workflow pin: {json.dumps(item)}")


def inspect_repository(owner, repo, workdir, identities, signers, report, commit_types=()):
    if signers:
        signers = Path(signers).resolve()
        if not signers.is_file():
            raise SystemExit("Allowed signers file is unavailable")
    name, fork = repo["name"], repo["isFork"]
    path = workdir / name
    run("gh", "repo", "clone", f"{owner}/{name}", str(path), "--", "-q", "--filter=blob:none", "--no-checkout")
    run("git", "fetch", "-q", "origin", "--tags", cwd=path)
    default = repo["defaultBranchRef"]["name"]
    run("git", "checkout", "-q", default, cwd=path)
    git = lambda *args, check=True: run("git", *args, cwd=path, check=check)  # noqa: E731

    head = git("rev-parse", "HEAD").strip()
    history = audit_history(path, f"{owner}/{name}", head, signers, commit_types)
    pins = audit_workflow_pins(path)
    report_source_audit(history, pins, head, fork, name, report)
    runs = json.loads(run("gh", "run", "list", "-R", f"{owner}/{name}", "--commit", head,
                          "--branch", default, "--limit", "50", "--json",
                          "databaseId,workflowDatabaseId,workflowName,status,conclusion"))
    if not runs:
        report("REVIEW", name, f"no workflow runs for {head[:7]}")
    for item in latest_workflow_runs(runs):
        if item["conclusion"] in BAD_RUNS:
            report("FAIL", name, f"{item['workflowName']} {item['conclusion']} at {head[:7]}")
        elif item["status"] != "completed":
            report("REVIEW", name, f"{item['workflowName']} still {item['status']}")

    branches = [b for b in git("for-each-ref", "refs/remotes/origin", "--format=%(refname:lstrip=3)").split()
                if b not in ("HEAD", default)]
    if branches and not fork:
        report("REVIEW", name, f"branches besides {default}: {', '.join(branches)}")

    names = defaultdict(set)
    for line in git("log", "--format=%an%x1f%ae%x1f%cn%x1f%ce").splitlines():
        author, author_email, committer, committer_email = line.split("\x1f")
        for who, address in ((author, author_email), (committer, committer_email)):
            if TOOL_IDENTITY.search(who + address) and "[bot]" not in who:
                report("REVIEW", name, f"tool identity in history: {who} <{address}>")
            names[address].add(who)
    for address in identities:
        if len(names.get(address, ())) > 1:
            report("REVIEW", name, f"{address} appears as {', '.join(sorted(map(ascii, names[address])))}")
    if identities:
        log = git("log", "--format=%x1e%ae%n%B")
        hits = [c for c in log.split("\x1e") if c.split("\n", 1)[0] in identities and TOOL_TRAILER.search(c)]
        if hits:
            report("REVIEW", name, f"{len(hits)} owner commits carry tool attribution trailers")

    if agent := [f for f in git("ls-files").splitlines() if re.search(r"(^|/)[.]agent/", f)]:
        report("FAIL", name, f"tracks agent state: {', '.join(agent[:3])}")
    local = "|".join(map(re.escape, {str(Path.home()), getpass.getuser()}))
    if found := git("grep", "-lIE", local, "HEAD", "--", ".", check=False).split():
        report("FAIL", name, f"operator-local paths or names: {', '.join(f[5:] for f in found[:4])}")
    if found := git("grep", "-lIE", SECRET, "HEAD", "--", ".", check=False).split():
        report("REVIEW", name, f"secret-like text (scanner patterns are expected): {', '.join(f[5:] for f in found[:4])}")
    return {"license_digest": license_digest(path), "source_commit": head, "default_branch": default,
            "history_audit": history, "reusable_workflow_pins": pins}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", required=True)
    parser.add_argument("--identity", action="append", default=[])
    parser.add_argument("--allowed-signers", type=Path)
    parser.add_argument("--commit-type", action="append", default=[],
                        help="accepted type from the applicable standard; repeat; otherwise check Conventional syntax")
    parser.add_argument("--work-dir", type=Path, required=True)
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", args.repo):
        raise SystemExit("Use owner/repository")
    args.work_dir.mkdir(parents=True, exist_ok=True)
    if any(args.work_dir.iterdir()):
        raise SystemExit("--work-dir must be empty; existing content is never removed")
    metadata = json.loads(run("gh", "repo", "view", args.repo, "--json", "name,isFork,defaultBranchRef"))
    findings = []
    def report(level, repository, message):
        findings.append({"level": level, "repository": repository, "message": message})
    try:
        observation = inspect_repository(args.repo.split("/")[0], metadata, args.work_dir,
                                           set(args.identity), args.allowed_signers, report, args.commit_type)
    finally:
        clone = args.work_dir / metadata["name"]
        if clone.exists():
            shutil.rmtree(clone)
    print(json.dumps({"repository": args.repo, **observation, "findings": findings}, indent=2))
    return 2 if any(item["level"] == "UNKNOWN" for item in findings) else 1 if any(item["level"] == "FAIL" for item in findings) else 0


if __name__ == "__main__":
    sys.exit(main())
