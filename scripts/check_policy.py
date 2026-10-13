#!/usr/bin/env python3
"""Check the skill collection's committed publication content."""

from pathlib import Path
import subprocess
import sys

from check_repository import publication_findings


def main():
    root = Path(__file__).resolve().parent.parent
    findings = publication_findings(root, "HEAD")
    if findings:
        print("\n".join(findings), file=sys.stderr)
        return 1
    print("Collection publication content passed")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"collection policy: {error}", file=sys.stderr)
        sys.exit(1)
