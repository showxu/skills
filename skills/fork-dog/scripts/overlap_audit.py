#!/usr/bin/env python3
"""Read-only overlap evidence for an independent pre-publication clean-room audit.

Compare one candidate commit with every reachable donor revision and optional
local copies. Exit 0 means the scan completed, never publication approval;
invalid or incomplete inputs exit 2. No source code is executed or checked out.
"""

import argparse
from collections import defaultdict
from fnmatch import fnmatchcase
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys

TOKEN = re.compile(r"[A-Za-z_][A-Za-z0-9_]*|\d+|==|!=|->|<=|>=|&&|\|\||[^\sA-Za-z0-9_]")
IMPORT = re.compile(r"^(?:@testable\s+)?import\b|^from\s+.+?\s+import\b|^#\s*include\b|^use\s+|^using\s+[\w.:]+\s*;")
HASH_SUFFIXES = {".py", ".sh", ".bash", ".zsh", ".rb", ".yaml", ".yml", ".toml", ".r", ".pl", ".ps1"}
C_SUFFIXES = {".swift", ".c", ".h", ".cc", ".cpp", ".hpp", ".m", ".mm", ".cs", ".java", ".js", ".jsx", ".ts", ".tsx", ".go", ".rs", ".kt", ".scala", ".jsonc"}


def git(repo, *args, data=None, check=True):
    environment = dict(os.environ, GIT_OPTIONAL_LOCKS="0", GIT_NO_REPLACE_OBJECTS="1", GIT_NO_LAZY_FETCH="1")
    for name in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR", "GIT_OBJECT_DIRECTORY", "GIT_ALTERNATE_OBJECT_DIRECTORIES", "GIT_SHALLOW_FILE"):
        environment.pop(name, None)
    result = subprocess.run(["git", "-C", str(repo), *args], input=data,
                            capture_output=True, env=environment)
    if check and result.returncode:
        raise ValueError(f"Git read failed ({args[0]}): {result.stderr.decode('utf-8', 'replace').strip()}")
    return result.stdout if check else result


def repository(repo):
    repo = Path(repo).resolve()
    git(repo, "rev-parse", "--git-dir")
    if git(repo, "rev-parse", "--is-shallow-repository").strip() == b"true":
        raise ValueError("Full history is required; a shallow repository cannot establish coverage")
    if git(repo, "for-each-ref", "refs/replace").strip():
        raise ValueError("Replacement refs make history coverage ambiguous")
    grafts = Path(os.fsdecode(git(repo, "rev-parse", "--git-path", "info/grafts").strip()))
    if not grafts.is_absolute():
        grafts = repo / grafts
    if grafts.is_file() and grafts.read_bytes().strip():
        raise ValueError("History grafts make coverage ambiguous")
    return repo


def tree_files(repo, ref):
    files = {}
    for record in git(repo, "ls-tree", "-rz", "--full-tree", ref).split(b"\0"):
        if not record:
            continue
        metadata, path = record.split(b"\t", 1)
        mode, kind, oid = metadata.split()
        if kind != b"blob":
            raise ValueError("Gitlinks require a separate audited source input")
        files[os.fsdecode(path)] = oid.decode()
    return files


def read_objects(repo, oids):
    oids = sorted(set(oids))
    if not oids:
        return {}
    result = git(repo, "cat-file", "--batch", data=("\n".join(oids) + "\n").encode())
    objects, offset = {}, 0
    for oid in oids:
        end = result.index(b"\n", offset)
        header = result[offset:end].split()
        if len(header) != 3 or header[0].decode() != oid:
            raise ValueError("Missing or malformed history object")
        size = int(header[2])
        offset = end + 1
        objects[oid] = result[offset:offset + size]
        offset += size + 1
    return objects


def history(repo, label):
    repo = repository(repo)
    commits = git(repo, "rev-list", "--all").decode().splitlines()
    if not commits:
        raise ValueError("A donor repository must have reachable history")
    trees = sorted(set(git(repo, "log", "--all", "--format=%T").decode().splitlines()))
    paths = defaultdict(set)
    for tree in trees:
        for path, oid in tree_files(repo, tree).items():
            paths[oid].add(path)
    objects = read_objects(repo, paths)
    records = [{"source": label, "object": oid, "paths": sorted(paths[oid]), "data": data}
               for oid, data in sorted(objects.items())]
    refs = git(repo, "for-each-ref", "--format=%(refname) %(objectname)").decode().splitlines()
    return records, {"source": label, "repository": str(repo), "scope": "all reachable refs",
                     "commits": commits, "refs": refs, "trees": len(trees), "blobs": len(records)}


def excluded(path, patterns):
    return any(fnmatchcase(path, pattern) for pattern in patterns)


def working_copy(folder, label, patterns):
    folder = Path(folder).resolve()
    if not folder.is_dir():
        raise ValueError("Local copy is not a directory")
    result = git(folder, "rev-parse", "--show-toplevel", check=False)
    is_repo = result.returncode == 0 and Path(os.fsdecode(result.stdout.strip())).resolve() == folder
    if result.returncode == 0 and not is_repo and git(folder, "ls-files", "--", ".").strip():
        raise ValueError("A tracked local copy needs its owning repository root so full history is included")
    extra, coverage = (history(folder, label + "-history") if is_repo else ([], None))
    if is_repo:
        names = [os.fsdecode(path) for path in git(folder, "ls-files", "--cached", "--others", "--exclude-standard", "-z").split(b"\0") if path]
    else:
        names = []
        def traversal_error(error):
            raise error
        for current, directories, files in os.walk(folder, followlinks=False, onerror=traversal_error):
            for name in list(directories):
                path = Path(current, name)
                relative = path.relative_to(folder).as_posix()
                if name == ".git" or excluded(relative, patterns):
                    directories.remove(name)
                elif path.is_symlink():
                    names.append(relative)
                    directories.remove(name)
            names.extend(Path(current, name).relative_to(folder).as_posix() for name in files if name != ".git")
    records = []
    for name in sorted(set(names)):
        if excluded(name, patterns):
            continue
        path = folder / name
        try:
            mode = path.lstat().st_mode
        except FileNotFoundError:
            if is_repo:
                continue  # A tracked deletion is still covered by the Git history.
            raise
        if stat.S_ISLNK(mode):
            data = os.fsencode(os.readlink(path))
        elif stat.S_ISREG(mode):
            data = path.read_bytes()
        else:
            raise ValueError("Local copy contains a non-regular input; scope it explicitly")
        records.append({"source": label, "object": None, "paths": [name], "data": data})
    digest = hashlib.sha256()
    for record in records:
        digest.update(os.fsencode(record["paths"][0]) + b"\0" + hashlib.sha256(record["data"]).digest())
    return extra + records, {"source": label, "directory": str(folder), "files": len(records),
                             "inventory_sha256": digest.hexdigest(), "history": coverage,
                             "excludes": patterns, "ignored_files": "Git ignore rules" if is_repo else "explicit excludes only"}


def comment_style(path, override):
    if override != "auto":
        return override
    suffix = Path(path).suffix.lower()
    if suffix in HASH_SUFFIXES or Path(path).name.lower() in {"makefile", "dockerfile"}:
        return "hash"
    if suffix in C_SUFFIXES:
        return "c"
    if suffix in {".md", ".html", ".xml", ".svg"}:
        return "markup"
    return "none"


def without_comments(text, style):
    # Preserve strings and newlines; nested C block comments occur in several languages.
    output, index, quote, depth = [], 0, "", 0
    while index < len(text):
        if depth:
            if style == "c" and text.startswith("/*", index):
                depth += 1
                index += 2
            elif text.startswith("*/" if style == "c" else "-->", index):
                depth -= 1
                index += 2 if style == "c" else 3
            else:
                if text[index] == "\n":
                    output.append("\n")
                index += 1
        elif quote:
            if text.startswith(quote, index):
                output.append(quote)
                index += len(quote)
                quote = ""
            elif text[index] == "\\" and index + 1 < len(text):
                output.append(text[index:index + 2])
                index += 2
            else:
                output.append(text[index])
                index += 1
        elif (style == "c" and text.startswith("/*", index)) or (style == "markup" and text.startswith("<!--", index)):
            output.append(" ")
            depth = 1
            index += 2 if style == "c" else 4
        elif (style == "c" and text.startswith("//", index)) or (style == "hash" and text[index] == "#"):
            end = text.find("\n", index)
            index = len(text) if end < 0 else end
        elif text[index] in ('"', "'", "`") and style != "markup":
            quote = text[index] * (3 if text.startswith(text[index] * 3, index) else 1)
            output.append(quote)
            index += len(quote)
        else:
            output.append(text[index])
            index += 1
    return "".join(output)


def meaningful_lines(text, style, strip_imports=True):
    lines, import_depth, continued = [], 0, False
    for raw in without_comments(text, style).splitlines():
        line = " ".join(raw.split())
        if strip_imports and (import_depth > 0 or continued or IMPORT.match(line)):
            import_depth += sum(line.count(c) for c in "([{") - sum(line.count(c) for c in ")]}")
            continued = line.endswith("\\")
            continue
        if line and not set(line) <= set("{}()[];, "):
            lines.append(line)
    return lines


def text_view(data, path, syntax):
    if b"\0" in data:
        return None, "binary"
    try:
        return meaningful_lines(data.decode("utf-8"), comment_style(path, syntax),
                                    syntax != "auto" or Path(path).suffix.lower() in (C_SUFFIXES - {".jsonc"}) | {".py"}), comment_style(path, syntax)
    except UnicodeDecodeError:
        return None, "non-utf8"


def ngrams(lines, size):
    tokens = TOKEN.findall("\n".join(lines))
    return {tuple(tokens[index:index + size]) for index in range(len(tokens) - size + 1)}


def location(record):
    return {key: record[key] for key in ("source", "object", "paths")}


def metadata_hits(repo, commits, terms):
    hits = []
    for oid, raw in read_objects(repo, commits).items():
        headers, _, body = raw.partition(b"\n\n")
        fields = {"message": body.decode("utf-8", "replace")}
        for field in ("author", "committer"):
            value = next((line[len(field) + 1:] for line in headers.splitlines() if line.startswith(field.encode() + b" ")), b"")
            fields[field] = value.decode("utf-8", "replace")
        for term in terms:
            matched = [field for field, value in fields.items() if term.casefold() in value.casefold()]
            if matched:
                hits.append({"commit": oid, "term": term, "fields": matched})
    return hits


def audit(candidate, ref, references, copies=(), terms=(), lengths=(20, 40), sizes=(8, 12), excludes=(), syntax="auto", examples=5):
    if not references or not terms or any(not term.strip() for term in terms):
        raise ValueError("Supply donor repositories and explicit donor-name terms")
    if not lengths or not sizes or min(lengths) < 1 or min(sizes) < 1 or examples < 0:
        raise ValueError("Line lengths and n-gram sizes must be positive; examples must be nonnegative")
    candidate = repository(candidate)
    commit = git(candidate, "rev-parse", "--verify", "--end-of-options", ref + "^{commit}").decode().strip()
    files = tree_files(candidate, commit)
    if not files:
        raise ValueError("Candidate tree is empty")
    data = read_objects(candidate, files.values())
    commits = git(candidate, "rev-list", commit).decode().splitlines()
    records, sources, copy_sources = [], [], []
    for index, path in enumerate(references, 1):
        values, source = history(path, f"reference-{index}")
        records.extend(values)
        sources.append(source)
    for index, path in enumerate(copies, 1):
        values, source = working_copy(path, f"copy-{index}", excludes)
        records.extend(values)
        copy_sources.append(source)
    history_sources = sources + [item["history"] for item in copy_sources if item["history"]]
    common = [{"source": item["source"], "commits": sorted(set(commits) & set(item["commits"]))} for item in history_sources]
    exact, line_index, gram_index, ref_identifiers = defaultdict(list), {}, {}, set()
    for length in lengths:
        line_index[length] = defaultdict(set)
    for size in sizes:
        gram_index[size] = set()
    source_locations = []
    for index, record in enumerate(records):
        exact[hashlib.sha256(record["data"]).hexdigest()].append(location(record))
        source_locations.append(location(record))
        # A renamed extension can change comment syntax; evaluate each historical path.
        for path in record["paths"]:
            lines, _ = text_view(record["data"], path, syntax)
            if lines is None:
                continue
            for length in lengths:
                for line in set(lines):
                    if len(line) >= length:
                        line_index[length][line].add(index)
            for size in sizes:
                gram_index[size].update(ngrams(lines, size))
            ref_identifiers.update(token for token in TOKEN.findall("\n".join(lines)) if token.isidentifier() and len(token) >= 6)
    by_file, candidate_identifiers = {}, set()
    for path, oid in sorted(files.items()):
        raw = data[oid]
        lines, style = text_view(raw, path, syntax)
        entry = {"object": oid, "sha256": hashlib.sha256(raw).hexdigest(), "bytes": len(raw), "normalization": style,
                 "identical_blobs": exact.get(hashlib.sha256(raw).hexdigest(), []),
                 "term_hits": [{"term": term, "filename": term.casefold() in path.casefold(),
                                "content": term.casefold() in raw.decode("utf-8", "replace").casefold()} for term in terms
                               if term.casefold() in path.casefold() or term.casefold() in raw.decode("utf-8", "replace").casefold()],
                 "lines": {}, "token_ngrams": {}}
        if lines is not None:
            for length in lengths:
                selected = [line for line in lines if len(line) >= length]
                shared = [line for line in selected if line in line_index[length]]
                matches = sorted({index for line in shared for index in line_index[length][line]})
                entry["lines"][str(length)] = {"total": len(selected), "shared": len(shared),
                    "percent": round(100 * len(shared) / len(selected), 2) if selected else None,
                    "reference_blobs": [source_locations[index] for index in matches],
                    "examples": shared[:examples], "examples_omitted": max(0, len(shared) - examples)}
            for size in sizes:
                values = ngrams(lines, size)
                shared = values & gram_index[size]
                entry["token_ngrams"][str(size)] = {"total": len(values), "shared": len(shared),
                    "percent": round(100 * len(shared) / len(values), 2) if values else None}
            candidate_identifiers.update(token for token in TOKEN.findall("\n".join(lines)) if token.isidentifier() and len(token) >= 6)
        by_file[path] = entry
    totals = {}
    for kind, keys in (("lines", lengths), ("token_ngrams", sizes)):
        totals[kind] = {}
        for key in keys:
            values = [entry[kind][str(key)] for entry in by_file.values() if str(key) in entry[kind]]
            total, shared = sum(item["total"] for item in values), sum(item["shared"] for item in values)
            totals[kind][str(key)] = {"total": total, "shared": shared, "percent": round(100 * shared / total, 2) if total else None}
    return {"schema": 1, "status": "evidence-only", "publication_approval": False,
            "tool_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            "candidate": {"repository": str(candidate), "commit": commit,
                          "tree": git(candidate, "rev-parse", commit + "^{tree}").decode().strip(),
                          "history_scope": "selected commit ancestry", "commits": len(commits), "files": len(files)},
            "parameters": {"line_lengths": sorted(set(lengths)), "ngram_sizes": sorted(set(sizes)), "syntax": syntax, "max_examples_per_file": examples, "terms": sorted(set(terms))},
            "references": sources, "copies": copy_sources, "common_commits": common,
            "commit_metadata_term_hits": metadata_hits(candidate, commits, terms), "by_file": by_file, "totals": totals,
            "identifiers": {"candidate": len(candidate_identifiers), "shared": sorted(candidate_identifiers & ref_identifiers)},
            "limits": ["All available reachable donor refs are covered; unseen remote refs and unreachable objects require separate evidence.",
                       "Binary/non-UTF8 content has exact-blob and term checks only; lexical metrics are not semantic or legal proof.",
                       "Comment/import removal is lexical; inspect unsupported syntax and every unexplained overlap.",
                       "Only an independent auditor can accept the candidate before its first public push."]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--ref", required=True)
    parser.add_argument("--reference", type=Path, action="append", required=True)
    parser.add_argument("--tree", type=Path, action="append", default=[])
    parser.add_argument("--term", action="append", required=True)
    parser.add_argument("--min-line-length", type=int, action="append")
    parser.add_argument("--ngram-size", type=int, action="append")
    parser.add_argument("--exclude", action="append", default=[], help="local-copy glob; never limits donor Git history")
    parser.add_argument("--syntax", choices=["auto", "c", "hash", "markup", "none"], default="auto")
    parser.add_argument("--max-examples", type=int, default=5)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.output:
        output = args.output.resolve()
        for folder in [args.candidate, *args.reference, *args.tree]:
            folder = folder.resolve()
            if output.is_relative_to(folder):
                relative = output.relative_to(folder)
                ignored = git(folder, "check-ignore", "--no-index", "--quiet", "--", str(relative), check=False)
                if ".git" in relative.parts or ignored.returncode != 0:
                    raise ValueError("Output must be outside inputs or in a repository-owned ignored location")
    report = audit(args.candidate, args.ref, args.reference, args.tree, args.term,
                   args.min_line_length or (20, 40), args.ngram_size or (8, 12), args.exclude, args.syntax, args.max_examples)
    value = json.dumps(report, indent=2, ensure_ascii=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(value)
    else:
        print(value, end="")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"overlap audit incomplete: {error}", file=sys.stderr)
        sys.exit(2)
