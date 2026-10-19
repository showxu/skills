"""Shared presentation input validation; no project token schema is assumed."""

import hashlib
import json
from pathlib import Path
import unicodedata


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def load_spec(path):
    path = Path(path).resolve()
    spec = json.loads(path.read_text())
    if not isinstance(spec, dict):
        raise ValueError("Presentation recipe must be an object")
    if ("design_source" in spec) != ("design_sha256" in spec):
        raise ValueError("Supply both design_source and design_sha256")
    if "design_source" in spec:
        if sha256(path.parent / spec["design_source"]) != spec["design_sha256"]:
            raise ValueError("DESIGN binding is stale; resolve the reviewed tokens again")
    return spec, path.parent


def plain(value):
    if not isinstance(value, str):
        raise ValueError("Presentation text must be a string")
    if any(unicodedata.category(c) == "Cc" for c in value):
        raise ValueError("Presentation text must not contain terminal control characters")
    return value


def write_or_check(path, value, check):
    path = Path(path)
    if check:
        if not path.is_file() or path.read_text() != value:
            raise ValueError(f"{path.name} differs from its inputs")
    else:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value)
