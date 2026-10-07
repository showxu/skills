#!/usr/bin/env python3
"""Inspect JSONL rollouts and prepare narrowly scoped image-history repairs."""

import argparse
import copy
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import sys
import tempfile
from collections import Counter


MARKER = "[Historical image omitted for session recovery; reopen the original image if needed.]"
SCOPES = ("latest-compaction", "tool-images", "user-images")


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("Duplicate JSON key.")
        result[key] = value
    return result


def reject_constant(value):
    raise ValueError("Nonstandard JSON constant.")


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=False, allow_nan=False,
                      separators=(",", ":"))


def digest(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def source_path(value):
    path = Path(value).expanduser()
    if path.is_symlink() or not path.is_file():
        raise ValueError("Select an existing regular rollout file, not a symlink.")
    return path.resolve()


def records(path):
    with path.open("rb") as stream:
        for number, raw in enumerate(stream, 1):
            try:
                item = json.loads(raw, object_pairs_hook=unique_object,
                                  parse_constant=reject_constant)
                if not isinstance(item, dict) or not isinstance(item.get("payload"), dict):
                    raise ValueError()
            except (ValueError, UnicodeDecodeError):
                raise ValueError(f"Invalid or unsupported JSONL record at line {number}.") from None
            yield number, raw, item


def images(node):
    count = chars = inline_count = inline_chars = 0
    pending = [node]
    while pending:
        value = pending.pop()
        if isinstance(value, dict):
            if value.get("type") == "input_image":
                count += 1
                url = value.get("image_url")
                if isinstance(url, str):
                    chars += len(url)
                    if url.startswith("data:image/") and ";base64," in url:
                        inline_count += 1
                        inline_chars += len(url)
            pending.extend(v for v in value.values() if isinstance(v, (dict, list)))
        elif isinstance(value, list):
            pending.extend(value)
    return {"input_images": count, "image_url_chars": chars,
            "inline_images": inline_count, "inline_image_chars": inline_chars}


def kind(item):
    payload = item["payload"]
    if item.get("type") == "compacted":
        return "compacted"
    if item.get("type") != "response_item":
        return None
    if payload.get("type") == "message" and payload.get("role") == "user":
        return "user-message"
    if payload.get("type") in ("function_call_output", "custom_tool_call_output"):
        return "tool-output"
    return "other-response"


def inspect(path):
    before = digest(path)
    counts = Counter()
    locations = []
    compactions = []
    session_id = None
    session_meta_count = 0
    version = None
    total = 0
    for number, raw, item in records(path):
        total += 1
        counts[item.get("type", "unknown")] += 1
        payload = item["payload"]
        if item.get("type") == "session_meta":
            session_meta_count += 1
            if session_meta_count > 1:
                raise ValueError("Multiple session_meta records are unsupported.")
            session_id = payload.get("id")
            version = payload.get("cli_version")
        location = kind(item)
        stats = images(payload)
        if location and stats["input_images"]:
            locations.append({"line": number, "kind": location, **stats})
        if location == "compacted":
            history = payload.get("replacement_history")
            compactions.append({"line": number, "record_bytes": len(raw),
                                "replacement_history_is_list": isinstance(history, list),
                                **images(history)})
    if not isinstance(session_id, str) or not session_id:
        raise ValueError("A session_meta record with a string id is required.")
    if digest(path) != before:
        raise ValueError("Rollout changed during inspection; retry after the target is idle.")
    return {"path": str(path), "sha256": before, "file_bytes": path.stat().st_size,
            "thread_id": session_id, "cli_version": version, "records": total,
            "record_types": dict(counts), "image_locations": locations,
            "compaction_records": len(compactions),
            "latest_compaction": compactions[-1] if compactions else None,
            "request_bytes": None, "cause_confirmed": False}


def replace_parts(parts):
    if not isinstance(parts, list):
        raise ValueError("Expected a typed content/output list; string outputs are unsupported.")
    changed = 0
    for index, part in enumerate(parts):
        if isinstance(part, dict) and part.get("type") == "input_image":
            if not isinstance(part.get("image_url"), str):
                raise ValueError("Unsupported input_image shape; inspect its owning schema.")
            if not part["image_url"].startswith("data:image/") or ";base64," not in part["image_url"]:
                continue
            parts[index] = {"type": "input_text", "text": MARKER}
            changed += 1
    return changed


def transform(item, scope):
    candidate = copy.deepcopy(item)
    payload = candidate["payload"]
    changed = 0
    if scope == "latest-compaction":
        if kind(candidate) != "compacted" or not isinstance(payload.get("replacement_history"), list):
            raise ValueError("Selected compaction lacks a supported replacement_history list.")
        for message in payload["replacement_history"]:
            if isinstance(message, dict) and message.get("type") == "message" and message.get("role") == "user":
                changed += replace_parts(message.get("content"))
    elif scope == "tool-images":
        if kind(candidate) != "tool-output":
            raise ValueError("Selected line is not a typed tool-output response_item.")
        changed = replace_parts(payload.get("output"))
    elif scope == "user-images":
        if kind(candidate) != "user-message":
            raise ValueError("Selected line is not a user-message response_item.")
        changed = replace_parts(payload.get("content"))
    else:
        raise ValueError("Unsupported repair scope.")
    if not changed:
        raise ValueError("Selected record has no supported images to replace.")
    return candidate, changed


def selected_lines(scan, scope, value):
    if scope == "latest-compaction":
        if value is not None:
            raise ValueError("latest-compaction chooses its own single record; omit --lines.")
        latest = scan["latest_compaction"]
        if not latest or not latest["replacement_history_is_list"]:
            raise ValueError("No supported completed compaction; do not invent a checkpoint.")
        return [latest["line"]]
    if value is None:
        raise ValueError("Raw-history repair requires explicit --lines from the inspected rollout.")
    try:
        result = sorted(set(int(v) for v in value.split(",")))
    except ValueError:
        raise ValueError("--lines must be comma-separated positive record numbers.") from None
    if not result or min(result) < 1 or max(result) > scan["records"]:
        raise ValueError("Selected record numbers are outside the rollout.")
    return result


def private_json(path, value):
    with path.open("x", encoding="utf-8") as stream:
        os.chmod(path, 0o600)
        json.dump(value, stream, indent=2)
        stream.write("\n")


def prepare(path, workspace, scope, value):
    scan = inspect(path)
    selected = selected_lines(scan, scope, value)
    workspace = Path(workspace).expanduser().resolve()
    if workspace.exists():
        raise ValueError("Use a new recovery workspace; existing recovery evidence is preserved.")
    workspace.mkdir(parents=True, mode=0o700)
    os.chmod(workspace, 0o700)
    backup = workspace / "original.jsonl"
    shutil.copyfile(path, backup)
    os.chmod(backup, 0o600)
    if digest(backup) != scan["sha256"] or digest(path) != scan["sha256"]:
        raise ValueError("Source changed while backing up; prepare again in a new workspace.")
    candidate = workspace / "candidate.jsonl"
    changes = []
    with candidate.open("xb") as out:
        os.chmod(candidate, 0o600)
        for number, raw, item in records(backup):
            if number in selected:
                item, count = transform(item, scope)
                encoded = (json.dumps(item, ensure_ascii=False, separators=(",", ":")) + "\n").encode()
                out.write(encoded)
                changes.append({"line": number, "replaced_images": count,
                                "before_bytes": len(raw), "after_bytes": len(encoded)})
            else:
                out.write(raw)
    manifest = {"format": 1, "source": str(path), "source_sha256": scan["sha256"],
                "candidate_sha256": digest(candidate), "thread_id": scan["thread_id"],
                "scope": scope, "selected_lines": selected, "changes": changes,
                "live_recovery_verified": False}
    private_json(workspace / "manifest.json", manifest)
    result = check(workspace)
    return {"workspace": str(workspace), "changes": changes, **result}


def check(workspace):
    workspace = Path(workspace).expanduser().resolve()
    manifest = json.loads((workspace / "manifest.json").read_text())
    if manifest.get("format") != 1 or manifest.get("scope") not in SCOPES:
        raise ValueError("Unsupported recovery manifest.")
    original, candidate = workspace / "original.jsonl", workspace / "candidate.jsonl"
    if digest(original) != manifest["source_sha256"] or digest(candidate) != manifest["candidate_sha256"]:
        raise ValueError("Backup/candidate hash mismatch; do not apply altered recovery files.")
    before, after = inspect(original), inspect(candidate)
    if before["thread_id"] != manifest["thread_id"] or after["thread_id"] != before["thread_id"]:
        raise ValueError("Thread identity changed.")
    if before["records"] != after["records"]:
        raise ValueError("Record count changed.")
    expected_selection = selected_lines(before, manifest["scope"], None if manifest["scope"] == "latest-compaction" else ",".join(map(str, manifest["selected_lines"])))
    if expected_selection != manifest["selected_lines"]:
        raise ValueError("Selected records do not match the repair scope.")
    changes = []
    for left, right in zip(records(original), records(candidate)):
        number, raw, item = left
        if number in expected_selection:
            expected, count = transform(item, manifest["scope"])
            if canonical(right[2]) != canonical(expected):
                raise ValueError(f"Unapproved semantic change at line {number}.")
            changes.append({"line": number, "replaced_images": count,
                            "before_bytes": len(raw), "after_bytes": len(right[1])})
        elif raw != right[1]:
            raise ValueError(f"Unselected record changed at line {number}.")
    if changes != manifest["changes"]:
        raise ValueError("Change receipt does not match candidate.")
    return {"structural_validation": "passed", "source_sha256": before["sha256"],
            "candidate_sha256": after["sha256"], "candidate_bytes": after["file_bytes"],
            "live_recovery_verified": False}


def install_file(source, replacement, expected_hash):
    if digest(source) != expected_hash:
        raise ValueError("Live source changed; preserve it and prepare a new repair.")
    mode = stat.S_IMODE(source.stat().st_mode)
    handle, name = tempfile.mkstemp(prefix=".rollout-recovery-", dir=source.parent)
    temporary = Path(name)
    try:
        with os.fdopen(handle, "wb") as out, replacement.open("rb") as incoming:
            shutil.copyfileobj(incoming, out)
            out.flush()
            os.fsync(out.fileno())
        os.chmod(temporary, mode)
        replacement_hash = digest(replacement)
        if digest(temporary) != replacement_hash or digest(source) != expected_hash:
            raise ValueError("Files changed during staging; live source preserved.")
        # Atomic replacement requires the session writer to be unloaded by the caller.
        os.replace(temporary, source)
        if digest(source) != replacement_hash:
            raise ValueError("Post-replacement hash mismatch; preserve recovery evidence.")
    finally:
        temporary.unlink(missing_ok=True)


def apply(workspace, unloaded, restore=False):
    if not unloaded:
        raise ValueError("Obtain runtime evidence that this thread is unloaded, then pass --thread-unloaded.")
    workspace = Path(workspace).expanduser().resolve()
    result = check(workspace)
    manifest = json.loads((workspace / "manifest.json").read_text())
    source = source_path(manifest["source"])
    replacement = workspace / ("original.jsonl" if restore else "candidate.jsonl")
    expected = manifest["candidate_sha256" if restore else "source_sha256"]
    install_file(source, replacement, expected)
    return {"source": str(source), "operation": "restored" if restore else "applied",
            "sha256": digest(source), "structural_validation": result["structural_validation"],
            "live_recovery_verified": False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest="command", required=True)
    scan = subs.add_parser("inspect", help="Read one rollout and emit content-free structural measurements.")
    scan.add_argument("--rollout", required=True)
    prep = subs.add_parser("prepare", help="Back up one rollout and generate a validated candidate; source stays intact.")
    prep.add_argument("--rollout", required=True)
    prep.add_argument("--workspace", required=True)
    prep.add_argument("--scope", choices=SCOPES, default="latest-compaction")
    prep.add_argument("--lines", help="Explicit raw-history record numbers, comma separated.")
    for command in ("check", "apply", "restore"):
        sub = subs.add_parser(command)
        sub.add_argument("--workspace", required=True)
        if command != "check":
            sub.add_argument("--thread-unloaded", action="store_true",
                             help="Attest runtime evidence of an unloaded target; this flag does not unload it.")
    args = parser.parse_args()
    try:
        if args.command == "inspect":
            result = inspect(source_path(args.rollout))
        elif args.command == "prepare":
            result = prepare(source_path(args.rollout), args.workspace, args.scope, args.lines)
        elif args.command == "check":
            result = check(args.workspace)
        else:
            result = apply(args.workspace, args.thread_unloaded, args.command == "restore")
        print(json.dumps(result, indent=2))
        return 0
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"Recovery stopped: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
