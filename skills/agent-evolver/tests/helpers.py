"""Isolated session stores for usage-count tests."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"

class HelperTestCase(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="agent-evolver-test-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.home = self.root / "home"
        self.codex_home = self.home / ".codex"
        self.claude_projects = self.home / ".claude" / "projects"
        for path in (self.codex_home, self.claude_projects):
            path.mkdir(parents=True)
        self.env = {
            "HOME": str(self.home),
            "CODEX_HOME": str(self.codex_home),
            "PATH": "",
            "PYTHONDONTWRITEBYTECODE": "1",
        }

    def run_helper(self, name, *arguments, expected=0, env=None):
        result = subprocess.run([sys.executable, "-B", str(SCRIPTS / name), *map(str, arguments)],
                                cwd=self.root, env=env or self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, expected, result.stderr + result.stdout)
        self.assertNotIn("Traceback", result.stderr)
        return result

    def jsonl(self, path, events):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("".join(json.dumps(event) + "\n" for event in events), encoding="utf-8")
        return path
