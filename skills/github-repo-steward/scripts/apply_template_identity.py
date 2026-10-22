#!/usr/bin/env python3
"""Replace declared template identities in tracked paths and UTF-8 contents."""

import argparse
from dataclasses import dataclass
import errno
import os
from pathlib import Path
import stat
import subprocess
import sys


@dataclass
class FileChange:
    source: Path
    target: Path
    original: bytes
    updated: bytes
    mode: int
    symlink: bool


def identity_map(value):
    old, separator, new = value.partition("=")
    if not separator or not old:
        raise argparse.ArgumentTypeError("--map requires a nonempty OLD in OLD=NEW")
    return old, new


def relative_path(value):
    path = Path(value)
    if path.is_absolute() or not path.parts or ".." in path.parts or ".git" in path.parts:
        raise ValueError(f"{value}: expected a path relative to the root")
    return path


def tracked_paths(root):
    def git(*args):
        try:
            return subprocess.check_output(["git", "-C", str(root), *args], stderr=subprocess.PIPE)
        except subprocess.CalledProcessError as error:
            raise ValueError(f"{root}: {error.stderr.decode(errors='replace').strip()}") from error

    if git("rev-parse", "--is-inside-work-tree").strip() != b"true":
        raise ValueError(f"{root}: --root must be a Git work tree")
    return [relative_path(os.fsdecode(path)) for path in git("ls-files", "-z").split(b"\0") if path]


def replace(value, mappings):
    for old, new in mappings:
        value = value.replace(old, new)
    return value


def read_file(path):
    return os.fsencode(os.readlink(path)) if path.is_symlink() else path.read_bytes()


def plan(root, tracked, mappings, removals):
    removed, directories = set(), set()
    for value in removals:
        relative = relative_path(value)
        path = root / relative
        if not path.parent.resolve().is_relative_to(root):
            raise ValueError(f"{relative}: removal leaves the root")
        if not path.exists() and not path.is_symlink():
            raise ValueError(f"{relative}: removal path is missing")
        matches = {name for name in tracked if name == relative or relative in name.parents}
        if not matches:
            raise ValueError(f"{relative}: removal path is not tracked by Git")
        if path.is_dir() and not path.is_symlink():
            directories.add(relative)
            for child in path.rglob("*"):
                name = child.relative_to(root)
                if child.is_symlink() or not child.is_dir():
                    if name not in matches:
                        raise ValueError(f"{name}: removal would affect an untracked file")
                else:
                    directories.add(name)
        removed.update(matches)

    changes = []
    targets = set()
    for source in tracked:
        if source in removed:
            continue
        path = root / source
        if not path.parent.resolve().is_relative_to(root):
            raise ValueError(f"{source}: tracked path leaves the root")
        original = read_file(path)
        try:
            updated = replace(original.decode("utf-8"), mappings).encode("utf-8")
        except UnicodeDecodeError:
            updated = original
        target = relative_path(str(Path(*(replace(part, mappings) for part in source.parts))))
        if target in targets:
            raise ValueError(f"{target}: identity maps produce a path collision")
        targets.add(target)
        changes.append(FileChange(source, target, original, updated,
                                  stat.S_IMODE(path.lstat().st_mode), path.is_symlink()))

    destinations = {}
    for change in changes:
        for destination in (change.target, *change.target.parents):
            if destination == Path("."):
                continue
            folded = str(destination).casefold()
            previous = destinations.get(folded)
            if previous is not None and previous != destination:
                raise ValueError(f"{previous} and {destination}: identity maps produce "
                                 "a case-insensitive path collision")
            destinations[folded] = destination

    for target in targets:
        if any(parent in targets for parent in target.parents):
            raise ValueError(f"{target}: identity maps put a file inside another file")

    vacated = removed | directories | {change.source for change in changes if change.source != change.target}

    def is_vacated(path):
        return path in vacated or any(parent in vacated for parent in path.parents)

    for change in changes:
        if change.source == change.target:
            continue
        destination = root / change.target
        if (destination.exists() or destination.is_symlink()) and not is_vacated(change.target):
            raise ValueError(f"{change.target}: rename destination already exists")
        for parent in change.target.parents:
            if parent == Path(".") or is_vacated(parent):
                continue
            path = root / parent
            if path.is_symlink() or (path.exists() and not path.is_dir()):
                raise ValueError(f"{parent}: rename destination is not a directory")
    return removed, directories, changes


def prune_directories(root, directories):
    for relative in sorted(directories, key=lambda path: len(path.parts), reverse=True):
        try:
            (root / relative).rmdir()
        except OSError as error:
            if error.errno not in (errno.ENOENT, errno.ENOTEMPTY, errno.EEXIST):
                raise


def apply(root, removed, directories, changes):
    for relative in sorted(removed):
        (root / relative).unlink()
    prune_directories(root, directories)
    renamed = [change for change in changes if change.source != change.target]
    for change in renamed:
        (root / change.source).unlink()
    parents = {parent for change in renamed for parent in change.source.parents if parent != Path(".")}
    prune_directories(root, parents)
    for change in changes:
        if change.source == change.target and change.original == change.updated:
            continue
        path = root / change.target
        path.parent.mkdir(parents=True, exist_ok=True)
        if change.symlink:
            if change.source == change.target:
                path.unlink()
            path.symlink_to(os.fsdecode(change.updated))
        else:
            path.write_bytes(change.updated)
            path.chmod(change.mode)


def residues(path, value, mappings, kind):
    count = 0
    for old, _ in mappings:
        start = 0
        while True:
            index = value.find(old, start)
            if index < 0:
                break
            line = value.count("\n", 0, index) + 1
            print(f"{path}:{line}: {kind} still contains {old!r}", file=sys.stderr)
            count += 1
            start = index + len(old)
    return count


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--map", required=True, action="append", type=identity_map, dest="mappings")
    parser.add_argument("--remove", action="extend", nargs="+", default=[])
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)
    try:
        root = args.root.resolve()
        mappings = sorted(args.mappings, key=lambda item: len(item[0]), reverse=True)
        removed, directories, changes = plan(root, tracked_paths(root), mappings, args.remove)
        for path in sorted(removed):
            print(f"remove {path}")
        for path in sorted(directories):
            print(f"remove directory {path}")
        for change in changes:
            if change.source != change.target:
                print(f"rename {change.source} -> {change.target}")
            if change.original != change.updated:
                print(f"change {change.target}")
        if not args.dry_run:
            apply(root, removed, directories, changes)
        remaining = 0
        # The index keeps the source names until the caller stages the renames.
        for change in changes:
            remaining += residues(change.target, str(change.target), mappings, "path")
            data = change.updated if args.dry_run else read_file(root / change.target)
            try:
                content = data.decode("utf-8")
            except UnicodeDecodeError:
                continue
            remaining += residues(change.target, content, mappings, "content")
        return 1 if remaining else 0
    except (OSError, ValueError) as error:
        print(f"template identity: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
