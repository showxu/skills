#!/usr/bin/env python3
"""Exercise preservation, rejection and rollback invariants with synthetic history."""

import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import rollout_recovery as recovery


IMAGE = {"type": "input_image", "image_url": "data:image/png;base64,aW1hZ2U=", "detail": "high"}
REFERENCE = {"type": "input_image", "image_url": "https://example.invalid/image.png"}
TEXT = {"type": "input_text", "text": "Private checkpoint and original path wrapper"}


def record(kind, payload):
    return {"timestamp": "fixture-time", "type": kind, "payload": payload}


def user(parts):
    return {"type": "message", "role": "user", "id": "preserved-message", "content": copy.deepcopy(parts)}


def fixture():
    return [
        record("session_meta", {"id": "synthetic-thread", "cli_version": "fixture"}),
        record("response_item", user([TEXT, IMAGE, REFERENCE])),
        record("response_item", {"type": "function_call", "call_id": "paired-call", "name": "view_image", "arguments": "{}"}),
        record("response_item", {"type": "function_call_output", "call_id": "paired-call", "output": [TEXT, IMAGE]}),
        record("response_item", {"type": "reasoning", "encrypted_content": "opaque-preserve-exactly"}),
        record("event_msg", {"type": "tool_event", "content": [IMAGE]}),
        record("compacted", {"replacement_history": [user([TEXT, IMAGE])], "message": "old summary"}),
        record("compacted", {"replacement_history": [user([TEXT, IMAGE, REFERENCE]), {"type": "compaction", "encrypted_content": "opaque-compaction"}], "message": "latest summary"}),
        record("response_item", user([{"type": "input_text", "text": "Current image"}, IMAGE])),
    ]


class RecoveryTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.source = self.root / "rollout.jsonl"
        self.items = fixture()
        self.write(self.items)
        self.original = self.source.read_bytes()
        self.workspace = self.root / "recovery"

    def tearDown(self):
        self.temporary.cleanup()

    def write(self, items):
        # Noncompact formatting makes unselected-line byte preservation observable.
        self.source.write_text("".join(json.dumps(item) + "\n" for item in items))

    def prepare(self, scope="latest-compaction", lines=None):
        return recovery.prepare(self.source, self.workspace, scope, lines)

    def candidate(self):
        return [item for _, _, item in recovery.records(self.workspace / "candidate.jsonl")]

    def test_inspection_is_content_free_and_does_not_claim_causality(self):
        scan = recovery.inspect(self.source)
        serialized = json.dumps(scan)
        self.assertNotIn(TEXT["text"], serialized)
        self.assertNotIn(IMAGE["image_url"], serialized)
        self.assertEqual(scan["latest_compaction"]["line"], 8)
        self.assertEqual(scan["compaction_records"], 2)
        self.assertIsNone(scan["request_bytes"])
        self.assertFalse(scan["cause_confirmed"])
        self.assertEqual([row["line"] for row in scan["image_locations"]], [2, 4, 7, 8, 9])
        self.assertEqual(self.source.read_bytes(), self.original)

    def test_latest_checkpoint_preserves_all_other_records_and_opaque_data(self):
        result = self.prepare()
        self.assertEqual(result["structural_validation"], "passed")
        self.assertFalse(result["live_recovery_verified"])
        self.assertEqual(self.source.read_bytes(), self.original)
        self.assertEqual((self.workspace / "original.jsonl").read_bytes(), self.original)
        old_lines = self.original.splitlines(keepends=True)
        new_lines = (self.workspace / "candidate.jsonl").read_bytes().splitlines(keepends=True)
        self.assertEqual(len(old_lines), len(new_lines))
        for index in range(len(old_lines)):
            if index != 7:
                self.assertEqual(old_lines[index], new_lines[index])
        latest = self.candidate()[7]["payload"]
        content = latest["replacement_history"][0]["content"]
        self.assertEqual(content[0], TEXT)
        self.assertEqual(content[1], {"type": "input_text", "text": recovery.MARKER})
        self.assertEqual(content[2], REFERENCE)
        self.assertEqual(latest["replacement_history"][1]["encrypted_content"], "opaque-compaction")
        self.assertEqual(latest["message"], "latest summary")

    def test_explicit_tool_image_repair_preserves_pairing_and_current_image(self):
        self.prepare("tool-images", "4")
        candidate = self.candidate()
        self.assertEqual(candidate[2], self.items[2])
        self.assertEqual(candidate[3]["payload"]["call_id"], "paired-call")
        self.assertEqual(candidate[3]["payload"]["output"][0], TEXT)
        self.assertEqual(candidate[3]["payload"]["output"][1]["type"], "input_text")
        self.assertEqual(candidate[8], self.items[8])
        self.assertEqual(candidate[5], self.items[5])

    def test_user_scope_replaces_only_selected_inline_pixels(self):
        self.prepare("user-images", "2")
        candidate = self.candidate()
        self.assertEqual(candidate[1]["payload"]["content"][2], REFERENCE)
        self.assertEqual(candidate[3], self.items[3])
        self.assertEqual(candidate[8], self.items[8])

    def test_raw_history_requires_explicit_selection(self):
        with self.assertRaisesRegex(ValueError, "explicit --lines"):
            self.prepare("tool-images")
        self.assertFalse(self.workspace.exists())

    def test_missing_checkpoint_does_not_switch_scope(self):
        self.write(self.items[:6])
        before = self.source.read_bytes()
        with self.assertRaisesRegex(ValueError, "No supported completed compaction"):
            self.prepare()
        self.assertEqual(self.source.read_bytes(), before)

    def test_unknown_latest_checkpoint_does_not_fall_back_to_older_one(self):
        self.items[7]["payload"] = {"message": "opaque summary without replacement_history"}
        self.write(self.items)
        with self.assertRaisesRegex(ValueError, "No supported completed compaction"):
            self.prepare()

    def test_invalid_json_preserves_source_and_creates_no_candidate(self):
        self.source.write_bytes(self.original + b"{invalid\n")
        before = self.source.read_bytes()
        with self.assertRaisesRegex(ValueError, "Invalid or unsupported JSONL"):
            self.prepare()
        self.assertEqual(self.source.read_bytes(), before)
        self.assertFalse(self.workspace.exists())

    def test_missing_or_duplicate_identity_is_rejected(self):
        for items in (self.items[1:], [record("session_meta", {}), *self.items]):
            with self.subTest(items=len(items)):
                self.write(items)
                with self.assertRaises(ValueError):
                    recovery.inspect(self.source)

    def test_wrong_record_selection_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "not a typed tool-output"):
            self.prepare("tool-images", "2")
        self.assertEqual(self.source.read_bytes(), self.original)

    def test_string_encoded_output_is_not_recursively_rewritten(self):
        self.items[3]["payload"]["output"] = json.dumps([TEXT, IMAGE])
        self.write(self.items)
        with self.assertRaisesRegex(ValueError, "string outputs are unsupported"):
            self.prepare("tool-images", "4")

    def test_remote_references_alone_are_not_removed(self):
        self.items[1]["payload"]["content"] = [TEXT, REFERENCE]
        self.write(self.items)
        with self.assertRaisesRegex(ValueError, "no supported images"):
            self.prepare("user-images", "2")

    def test_recovery_directory_cannot_overwrite_existing_evidence(self):
        self.prepare()
        before = (self.workspace / "manifest.json").read_bytes()
        with self.assertRaisesRegex(ValueError, "new recovery workspace"):
            self.prepare()
        self.assertEqual((self.workspace / "manifest.json").read_bytes(), before)

    def test_backup_and_workspace_are_private(self):
        self.prepare()
        if os.name == "posix":
            self.assertEqual(self.workspace.stat().st_mode & 0o777, 0o700)
            for name in ("original.jsonl", "candidate.jsonl", "manifest.json"):
                self.assertEqual((self.workspace / name).stat().st_mode & 0o777, 0o600)

    def test_apply_requires_unload_attestation(self):
        self.prepare()
        with self.assertRaisesRegex(ValueError, "runtime evidence"):
            recovery.apply(self.workspace, False)
        self.assertEqual(self.source.read_bytes(), self.original)

    def test_stale_live_source_blocks_apply(self):
        self.prepare()
        self.source.write_bytes(self.original + json.dumps(record("event_msg", {"type": "new_work"})).encode() + b"\n")
        new_work = self.source.read_bytes()
        with self.assertRaisesRegex(ValueError, "Live source changed"):
            recovery.apply(self.workspace, True)
        self.assertEqual(self.source.read_bytes(), new_work)

    def test_tampered_candidate_blocks_apply(self):
        self.prepare()
        candidate = self.workspace / "candidate.jsonl"
        candidate.write_bytes(candidate.read_bytes() + b"\n")
        with self.assertRaisesRegex(ValueError, "hash mismatch"):
            recovery.apply(self.workspace, True)
        self.assertEqual(self.source.read_bytes(), self.original)

    def test_semantic_tampering_is_rejected_even_with_updated_receipt_hash(self):
        self.prepare()
        items = self.candidate()
        items[7]["payload"]["message"] = "Altered task summary"
        candidate = self.workspace / "candidate.jsonl"
        candidate.write_text("".join(json.dumps(item) + "\n" for item in items))
        manifest_path = self.workspace / "manifest.json"
        manifest = json.loads(manifest_path.read_text())
        manifest["candidate_sha256"] = recovery.digest(candidate)
        manifest_path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(ValueError, "Unselected record changed|Unapproved semantic change"):
            recovery.check(self.workspace)

    def test_selected_record_preserves_json_value_types(self):
        self.items[7]["payload"]["count"] = 1
        self.write(self.items)
        self.prepare()
        candidate = self.workspace / "candidate.jsonl"
        rows = candidate.read_bytes().splitlines(keepends=True)
        value = json.loads(rows[7])
        value["payload"]["count"] = True
        rows[7] = (json.dumps(value) + "\n").encode()
        candidate.write_bytes(b"".join(rows))
        manifest_path = self.workspace / "manifest.json"
        manifest = json.loads(manifest_path.read_text())
        manifest["candidate_sha256"] = recovery.digest(candidate)
        manifest_path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(ValueError, "Unapproved semantic change"):
            recovery.check(self.workspace)

    def test_ambiguous_and_nonstandard_json_records_are_rejected(self):
        for extra in (b'{"type":"event_msg","payload":{"value":NaN}}\n',
                      b'{"type":"event_msg","payload":{"value":1,"value":2}}\n'):
            with self.subTest(extra=extra):
                self.source.write_bytes(self.original + extra)
                with self.assertRaisesRegex(ValueError, "Invalid or unsupported JSONL"):
                    recovery.inspect(self.source)

    def test_apply_and_restore_are_byte_identical_and_preserve_permissions(self):
        self.source.chmod(0o640)
        self.prepare()
        result = recovery.apply(self.workspace, True)
        self.assertEqual(result["operation"], "applied")
        self.assertFalse(result["live_recovery_verified"])
        self.assertEqual(self.source.read_bytes(), (self.workspace / "candidate.jsonl").read_bytes())
        if os.name == "posix":
            self.assertEqual(self.source.stat().st_mode & 0o777, 0o640)
        recovery.apply(self.workspace, True, restore=True)
        self.assertEqual(self.source.read_bytes(), self.original)

    def test_restore_refuses_to_overwrite_appended_work(self):
        self.prepare()
        recovery.apply(self.workspace, True)
        with self.source.open("ab") as stream:
            stream.write(json.dumps(record("event_msg", {"type": "new_work"})).encode() + b"\n")
        before = self.source.read_bytes()
        with self.assertRaisesRegex(ValueError, "Live source changed"):
            recovery.apply(self.workspace, True, restore=True)
        self.assertEqual(self.source.read_bytes(), before)

    def test_staging_failure_keeps_source_and_cleans_temporary_file(self):
        self.prepare()
        with patch.object(recovery.os, "replace", side_effect=OSError("fixture failure")):
            with self.assertRaises(OSError):
                recovery.apply(self.workspace, True)
        self.assertEqual(self.source.read_bytes(), self.original)
        self.assertEqual(list(self.root.glob(".rollout-recovery-*")), [])

    def test_source_symlink_is_rejected(self):
        alias = self.root / "alias.jsonl"
        alias.symlink_to(self.source)
        with self.assertRaisesRegex(ValueError, "not a symlink"):
            recovery.source_path(alias)

    def test_cli_inspect_and_error_paths(self):
        helper = Path(recovery.__file__)
        good = subprocess.run([sys.executable, str(helper), "inspect", "--rollout", str(self.source)], capture_output=True, text=True)
        self.assertEqual(good.returncode, 0, good.stderr)
        self.assertEqual(json.loads(good.stdout)["thread_id"], "synthetic-thread")
        bad = subprocess.run([sys.executable, str(helper), "prepare", "--rollout", str(self.source), "--workspace", str(self.workspace), "--scope", "tool-images"], capture_output=True, text=True)
        self.assertEqual(bad.returncode, 2)
        self.assertIn("explicit --lines", bad.stderr)


if __name__ == "__main__":
    unittest.main()
