from __future__ import annotations

import contextlib
import io
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SCRIPTS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS))
import inspect_thread_cwd as inspect
import patch_thread_cwd as recovery
import verify_threads_cwd as verify


class CwdRecoveryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "codex"
        (self.home / "sqlite").mkdir(parents=True)
        self.old = str(self.root / "old")
        self.target = self.root / "new"
        self.target.mkdir()
        self.db = self.home / "sqlite/state_9.sqlite"
        self.rollout = self.root / "rollout.jsonl"
        self.records = [
            {"type": "session_meta", "payload": {"id": "parent", "cwd": "/parent"}},
            {"type": "session_meta", "payload": {"id": "t-1", "cwd": self.old}},
            {"type": "response_item", "payload": {"role": "user", "content": "keep this conversation"}},
            {"type": "turn_context", "payload": {"cwd": self.old, "workspace_roots": [self.old, "/unrelated"]}},
            {"type": "session_meta", "payload": {"id": "parent", "cwd": "/foreign-later"}},
        ]
        self.rollout.write_text("".join(json.dumps(row) + "\n" for row in self.records))
        self.make_db(self.db, "t-1", self.old, self.rollout)

    def make_db(self, path, thread_id, cwd, rollout):
        with sqlite3.connect(path) as conn:
            conn.execute("create table threads (id text primary key, cwd text, rollout_path text, git_branch text, git_origin_url text, title text)")
            conn.execute("insert into threads values (?, ?, ?, 'old-branch', 'old-origin', 'fixture')", (thread_id, cwd, str(rollout)))

    def run_script(self, name, *args):
        env = {**os.environ, "CODEX_HOME": str(self.home)}
        return subprocess.run([sys.executable, str(SCRIPTS / name), *map(str, args)], cwd=self.root, env=env, capture_output=True, text=True)

    def test_inspection_and_patch_preview_leave_files_unchanged(self):
        before = self.rollout.read_bytes(), self.db.read_bytes()
        result = self.run_script("patch_thread_cwd.py", "--thread-id", "t-1", "--target-cwd", self.target, "--sync-git-from-target-cwd")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Dry run", result.stdout)
        self.assertEqual(before, (self.rollout.read_bytes(), self.db.read_bytes()))
        self.assertFalse((self.home / "backups").exists())

    def test_append_recovery_preserves_history_backups_and_effective_cwd(self):
        original = self.rollout.read_bytes()
        inode = self.rollout.stat().st_ino
        backup = self.root / "backup"
        result = self.run_script("patch_thread_cwd.py", "--thread-id", "t-1", "--target-cwd", self.target, "--sync-git-from-target-cwd", "--backup-dir", backup, "--apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        rows = [json.loads(line) for line in self.rollout.read_text().splitlines()]
        self.assertEqual(rows[:-1], self.records)
        self.assertEqual(self.rollout.stat().st_ino, inode)
        self.assertEqual(rows[-1]["payload"]["cwd"], str(self.target))
        self.assertEqual((backup / self.rollout.name).read_bytes(), original)
        with sqlite3.connect(backup / self.db.name) as conn:
            self.assertEqual(conn.execute("pragma quick_check").fetchone()[0], "ok")
            self.assertEqual(conn.execute("select cwd from threads").fetchone()[0], self.old)
        row = inspect.fetch_thread(self.db, "t-1")
        self.assertEqual(row.cwd, str(self.target))
        self.assertIsNone(row.git_branch)
        self.assertIsNone(row.git_origin_url)
        report = verify.db_report("active", self.db, self.old, str(self.target))
        self.assertEqual(report["exact_old_count"], 0)
        self.assertEqual(report["target_rollout_mismatch_count"], 0)

    def test_explicit_remap_preserves_foreign_records_and_unrelated_roots(self):
        result = self.run_script("patch_thread_cwd.py", "--thread-id", "t-1", "--target-cwd", self.target, "--old-cwd", self.old, "--remap-turn-context", "--apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        rows = [json.loads(line) for line in self.rollout.read_text().splitlines()]
        self.assertEqual(rows[0], self.records[0])
        self.assertEqual(rows[2], self.records[2])
        self.assertEqual(rows[4], self.records[4])
        self.assertEqual(rows[3]["payload"]["workspace_roots"], [str(self.target), "/unrelated"])

    def test_batch_verifies_active_legacy_and_leaves_subpaths(self):
        legacy = self.home / "state_8.sqlite"
        legacy_rollout = self.root / "legacy.jsonl"
        legacy_rollout.write_text(json.dumps({"type": "session_meta", "payload": {"id": "t-2", "cwd": self.old}}) + "\n")
        self.make_db(legacy, "t-2", self.old, legacy_rollout)
        with sqlite3.connect(self.db) as conn:
            conn.execute("insert into threads values ('sub', ?, ?, null, null, 'sub')", (self.old + "/child", str(self.rollout)))
        manifest = self.root / "migration.json"
        result = self.run_script("migrate_threads_cwd.py", "--old-cwd", self.old, "--target-cwd", self.target, "--manifest", manifest, "--apply")
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        results = json.loads(manifest.read_text())["databases"]
        self.assertEqual({r["label"] for r in results}, {"active", "legacy"})
        for item in results:
            self.assertEqual(item["verification"]["exact_old_count"], 0)
            self.assertEqual(item["verification"]["target_rollout_mismatch_count"], 0)
        self.assertEqual(inspect.fetch_thread(self.db, "sub").cwd, self.old + "/child")
        result = self.run_script("verify_threads_cwd.py", "--old-cwd", self.old, "--target-cwd", self.target, "--json")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_rollout_failure_restores_db_fields(self):
        argv = ["patch_thread_cwd", "--thread-id", "t-1", "--db", str(self.db), "--codex-home", str(self.home), "--target-cwd", str(self.target), "--sync-git-from-target-cwd", "--apply"]
        with patch.object(sys, "argv", argv), patch.object(recovery, "patch_rollout_cwd", side_effect=RuntimeError("fixture failure")), contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaisesRegex(RuntimeError, "fixture failure"):
                recovery.main()
        row = inspect.fetch_thread(self.db, "t-1")
        self.assertEqual((row.cwd, row.git_branch, row.git_origin_url), (self.old, "old-branch", "old-origin"))

    def test_legacy_idless_fallback_and_late_parent_do_not_override_thread(self):
        summary = inspect.read_rollout_cwd_summary(str(self.rollout), "t-1")
        self.assertEqual(summary["effective_cwd"], self.old)
        self.rollout.write_text(json.dumps({"type": "session_meta", "payload": {"cwd": self.old}}) + "\n")
        self.assertEqual(inspect.read_rollout_cwd_summary(str(self.rollout), "t-1")["effective_cwd"], self.old)
        result = recovery.append_rollout_session_meta_cwd(self.rollout, "t-1", str(self.target))
        self.assertEqual(result["appended_session_meta"], 1)
        self.assertEqual(inspect.read_rollout_cwd_summary(str(self.rollout), "t-1")["effective_cwd"], str(self.target))

    def test_failed_validation_does_not_rollback_over_concurrent_append(self):
        new_record = {"type": "response_item", "payload": {"role": "user", "content": "arrived during verification"}}
        def append_then_fail(*args, **kwargs):
            with self.rollout.open("a") as file:
                file.write(json.dumps(new_record) + "\n")
            raise RuntimeError("verification interrupted")
        argv = ["patch_thread_cwd", "--thread-id", "t-1", "--db", str(self.db), "--codex-home", str(self.home), "--target-cwd", str(self.target), "--apply"]
        with patch.object(sys, "argv", argv), patch.object(recovery, "validate_post_patch", side_effect=append_then_fail), contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaisesRegex(SystemExit, "not auto-rolling back"):
                recovery.main()
        rows = [json.loads(line) for line in self.rollout.read_text().splitlines()]
        self.assertEqual(rows[:len(self.records)], self.records)
        self.assertEqual(rows[-1], new_record)
        self.assertEqual(inspect.fetch_thread(self.db, "t-1").cwd, str(self.target))


if __name__ == "__main__":
    unittest.main()
