from __future__ import annotations

import contextlib
import copy
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import sidebar_app_server as api


def protocol_fixture():
    """Small protocol shapes, independent of the adapter's dispatch allowlist."""
    string = {"type": "string"}
    nullable = {"type": ["string", "null"]}
    boolean = {"type": "boolean"}
    def obj(properties, required=()):
        return {"type": "object", "properties": properties, "required": list(required)}
    methods = {
        "initialize": obj({"clientInfo": obj({"name": string, "version": string}, ["name", "version"]), "capabilities": obj({"experimentalApi": boolean})}, ["clientInfo"]),
        "account/read": obj({"refreshToken": boolean}),
        "thread/read": obj({"threadId": string, "includeTurns": boolean}, ["threadId"]),
        "project/read": obj({"projectId": string}, ["projectId"]),
        "thread/list": obj({"cursor": nullable, "projectId": nullable, "sectionId": nullable, "archived": boolean, "useStateDbOnly": boolean}),
        "project/list": obj({"cursor": nullable}),
        "threadSection/list": obj({"cursor": nullable}),
        "thread/name/set": obj({"threadId": string, "name": string}, ["threadId", "name"]),
        "thread/delete": obj({"threadId": string}, ["threadId"]),
        "thread/archive": obj({"threadId": string}, ["threadId"]),
        "thread/unarchive": obj({"threadId": string}, ["threadId"]),
        "thread/metadata/update": obj({"threadId": string, "projectId": nullable}, ["threadId"]),
        "thread/settings/update": obj({"threadId": string, "cwd": string, "model": string}, ["threadId"]),
        "thread/start": obj({"projectId": nullable, "cwd": nullable, "ephemeral": boolean}),
        "project/create": obj({"idempotencyKey": string, "name": string, "roots": {"type": "array", "items": obj({"path": string}, ["path"])}, "metadata": {"type": "object", "additionalProperties": string}}, ["idempotencyKey", "name", "roots"]),
        "project/update": obj({"projectId": string, "name": nullable, "metadata": {"type": "object", "additionalProperties": string}}, ["projectId"]),
        "project/delete": obj({"projectId": string}, ["projectId"]),
        "project/move": obj({"projectId": string, "beforeProjectId": nullable}, ["projectId"]),
        "thread/section/move": obj({"threadId": string, "sectionId": nullable, "beforeThreadId": nullable}, ["threadId", "sectionId"]),
        "threadSection/create": obj({"name": string}, ["name"]),
        "threadSection/update": obj({"sectionId": string, "name": string, "appearance": {"type": ["object", "null"], "properties": {"color": nullable, "icon": nullable}}}, ["sectionId", "name"]),
        "threadSection/delete": obj({"sectionId": string}, ["sectionId"]),
    }
    return api.Protocol({"oneOf": [{"properties": {"method": {"enum": [method]}, "params": schema}} for method, schema in methods.items()]})


class AdapterTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.protocol = protocol_fixture()
        self.binding = {"socket": "/fixture/control.sock", "codexHome": "/fixture/codex", "userAgent": "fixture/1", "platformOs": "macos", "accountFingerprint": "fixture-account", "accountIdentityKnown": True}
        self.thread = {"id": "t-1", "name": "Same title", "projectId": "p-1", "cwd": "/fixture/worktree"}

    def proxy(self, scenario, timeout=1):
        scenario_file = self.root / "scenario.json"
        scenario_file.write_text(json.dumps(scenario))
        peer = api.Proxy([sys.executable, str(Path(__file__).with_name("fake_proxy.py")), str(scenario_file), str(self.root / "requests.jsonl")], timeout)
        self.addCleanup(peer.close)
        return peer

    def read_thread(self, value=None):
        return {"method": "thread/read", "params": {"threadId": "t-1", "includeTurns": False}, "result": {"thread": value or self.thread}}

    def scope(self):
        return {"backend": "codex", "binding": copy.deepcopy(self.binding), "objects": [{"kind": "thread", "id": "t-1"}], "checks": [{"method": "thread/read", "params": {"threadId": "t-1"}, "equals": {"/thread/id": "t-1", "/thread/name": "Same title", "/thread/projectId": "p-1"}}]}

    def journal(self, operation_id="step-1"):
        return api.Journal(str(self.root / "attempts.jsonl"), operation_id)

    def events(self):
        return [json.loads(line) for line in (self.root / "attempts.jsonl").read_text().splitlines()]

    def requests(self):
        path = self.root / "requests.jsonl"
        return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []

    def test_preview_is_offline_and_preserves_omitted_attributes(self):
        params = self.root / "params.json"
        params.write_text(json.dumps({"projectId": "p-1", "name": "New title"}))
        out = io.StringIO()
        with patch.object(sys, "argv", ["adapter", "call", "--method", "project/update", "--params-file", str(params)]), patch.object(api, "local_probe", return_value=({}, self.protocol)), patch.object(api, "Proxy") as connect, contextlib.redirect_stdout(out):
            self.assertEqual(api.main(), 0)
        connect.assert_not_called()
        preview = json.loads(out.getvalue())
        self.assertEqual(preview["params"], {"projectId": "p-1", "name": "New title"})
        self.assertFalse(preview["checksRun"])

    def test_schema_rejects_typo_missing_fields_wrong_type_and_unsupported_method(self):
        cases = [
            ("project/update", {"projectID": "p-1", "name": "x"}),
            ("thread/name/set", {"threadId": "t-1"}),
            ("thread/name/set", {"threadId": 17, "name": "x"}),
            ("account/login/start", {}),
            ("thread/settings/update", {"threadId": "t-1", "cwd": "/x", "model": "chosen"}),
            ("thread/start", {"ephemeral": True}),
        ]
        for method, params in cases:
            with self.subTest(method=method, params=params), self.assertRaises(api.AdapterError):
                self.protocol.prepare(method, params)
        del self.protocol.methods["thread/delete"]
        with self.assertRaisesRegex(api.AdapterError, "unavailable"):
            self.protocol.prepare("thread/delete", {"threadId": "t-1"})

    def test_generated_refs_maps_and_unknown_constraints(self):
        root = {"definitions": {"Name": {"type": "string", "minLength": 1}}}
        api.validate_shape({"a": "x"}, {"type": "object", "additionalProperties": {"$ref": "#/definitions/Name"}}, root)
        with self.assertRaises(api.AdapterError):
            api.validate_shape({"a": ""}, {"type": "object", "additionalProperties": {"$ref": "#/definitions/Name"}}, root)
        with self.assertRaisesRegex(api.AdapterError, "unsupported schema"):
            api.validate_shape("x", {"type": "string", "not": {"const": "x"}}, {})

    def test_malformed_scope_pointer_and_incomplete_journal_fail_before_dispatch(self):
        with self.assertRaisesRegex(api.AdapterError, "Scope must"):
            api.check_scope(None, self.protocol, [], self.binding, "thread/delete", {"threadId": "t-1"})
        for path in ("/-1", "/01"):
            with self.subTest(path=path), self.assertRaises(api.AdapterError):
                api.pointer(["a", "b"], path)
        (self.root / "attempts.jsonl").write_text('{"operationId":"earlier"}')
        with self.assertRaisesRegex(api.AdapterError, "incomplete record"):
            self.journal().append("attempting", {}, first=True)

    def test_membership_clear_differs_from_list_unassigned_and_omission(self):
        self.assertEqual(self.protocol.prepare("thread/metadata/update", {"threadId": "t-1", "projectId": ""})["projectId"], "")
        self.assertNotIn("projectId", self.protocol.prepare("thread/metadata/update", {"threadId": "t-1"}))
        self.assertIsNone(self.protocol.prepare("thread/list", {"projectId": None})["projectId"])
        with self.assertRaisesRegex(api.AdapterError, 'use ""'):
            self.protocol.prepare("thread/metadata/update", {"threadId": "t-1", "projectId": None})

    def test_complete_pagination_preserves_same_titles_and_page_order(self):
        peer = self.proxy([
            {"method": "thread/list", "params": {"useStateDbOnly": True}, "result": {"data": [{"id": "t-1", "name": "Same"}], "nextCursor": "page-2"}},
            {"method": "thread/list", "params": {"useStateDbOnly": True, "cursor": "page-2"}, "result": {"data": [{"id": "t-2", "name": "Same"}]}},
        ])
        result = api.read_request(peer, self.protocol, "thread/list", {}, True)
        self.assertEqual([v["id"] for v in result["data"]], ["t-1", "t-2"])
        self.assertIsNone(result["nextCursor"])

    def test_pagination_detects_duplicates_repeated_cursor_and_partial_start(self):
        for second in [{"data": [{"id": "t-1"}], "nextCursor": None}, {"data": [{"id": "t-2"}], "nextCursor": "again"}]:
            with self.subTest(second=second):
                peer = self.proxy([
                    {"method": "thread/list", "result": {"data": [{"id": "t-1"}], "nextCursor": "again"}},
                    {"method": "thread/list", "result": second},
                ])
                with self.assertRaises(api.AdapterError):
                    api.read_request(peer, self.protocol, "thread/list", {}, True)
        with self.assertRaisesRegex(api.AdapterError, "without a cursor"):
            api.read_request(None, self.protocol, "thread/list", {"cursor": "middle"}, True)

    def test_account_binding_reads_without_refresh_and_redacts_email(self):
        peer = self.proxy([
            {"method": "initialize", "result": {"codexHome": "/fixture/codex", "userAgent": "fixture/1", "platformOs": "macos"}},
            {"method": "account/read", "params": {"refreshToken": False}, "result": {"account": {"type": "chatgpt", "email": "fixture@example.test", "planType": "free"}}},
        ])
        result = api.bind(peer, self.protocol, "/fixture/control.sock")
        self.assertTrue(result["accountIdentityKnown"])
        self.assertNotIn("fixture@example.test", json.dumps(result))
        self.assertEqual(len(result["accountFingerprint"]), 64)
        self.assertEqual(self.requests()[1]["method"], "initialized")

    def test_chatgpt_wrong_binding_unknown_account_and_unscoped_id_block_writes(self):
        for change in ("backend", "binding", "unknown-account", "id"):
            scope, binding, params = self.scope(), copy.deepcopy(self.binding), {"threadId": "t-1", "name": "New"}
            if change == "backend": scope["backend"] = "chatgpt"
            if change == "binding": scope["binding"]["codexHome"] = "/another/host"
            if change == "unknown-account": binding["accountIdentityKnown"] = False
            if change == "id": params["threadId"] = "t-2"
            with self.subTest(change=change), self.assertRaises(api.AdapterError):
                api.mutate(None, self.protocol, "thread/name/set", params, scope, binding, self.journal())
        self.assertFalse((self.root / "attempts.jsonl").exists())

    def test_stale_state_prevents_dispatch(self):
        changed = {**self.thread, "name": "Changed by user"}
        peer = self.proxy([self.read_thread(changed)])
        with self.assertRaisesRegex(api.AdapterError, "State changed"):
            api.mutate(peer, self.protocol, "thread/name/set", {"threadId": "t-1", "name": "New"}, self.scope(), self.binding, self.journal())
        self.assertEqual([r["method"] for r in self.requests()], ["thread/read"])
        self.assertFalse((self.root / "attempts.jsonl").exists())

    def test_exact_id_rename_then_readback_preserves_membership_and_cwd(self):
        peer = self.proxy([self.read_thread(), {"method": "thread/name/set", "params": {"threadId": "t-1", "name": "New"}}, self.read_thread({**self.thread, "name": "New"})])
        result = api.mutate(peer, self.protocol, "thread/name/set", {"threadId": "t-1", "name": "New"}, self.scope(), self.binding, self.journal())
        self.assertEqual(result["status"], "accepted")
        after = api.read_request(peer, self.protocol, "thread/read", {"threadId": "t-1"})["thread"]
        self.assertEqual(after, {**self.thread, "name": "New"})
        self.assertEqual([e["status"] for e in self.events()], ["attempting", "accepted"])

    def test_reorder_requires_observed_insertion_anchor_and_fresh_order(self):
        projects = [{"id": "p-1", "name": "Same"}, {"id": "p-2", "name": "Same"}]
        scope = {"backend": "codex", "binding": self.binding, "objects": [{"kind": "project", "id": p["id"]} for p in projects], "checks": [{"method": "project/list", "params": {}, "equals": {"/data": projects}}]}
        peer = self.proxy([{"method": "project/list", "result": {"data": projects}}, {"method": "project/move", "params": {"projectId": "p-2", "beforeProjectId": "p-1"}}])
        api.mutate(peer, self.protocol, "project/move", {"projectId": "p-2", "beforeProjectId": "p-1"}, scope, self.binding, self.journal())
        with self.assertRaisesRegex(api.AdapterError, "Unscoped"):
            api.check_scope(None, self.protocol, scope, self.binding, "project/move", {"projectId": "p-2", "beforeProjectId": "p-3"})

    def test_section_update_requires_name_and_preserves_omitted_appearance(self):
        with self.assertRaises(api.AdapterError):
            self.protocol.prepare("threadSection/update", {"sectionId": "s-1", "appearance": None})
        params = self.protocol.prepare("threadSection/update", {"sectionId": "s-1", "name": "New"})
        self.assertNotIn("appearance", params)
        self.assertIsNone(self.protocol.prepare("thread/section/move", {"threadId": "t-1", "sectionId": None})["sectionId"])

    def test_unknown_delete_and_create_are_not_automatically_retried(self):
        for method, params in [("thread/delete", {"threadId": "t-1"}), ("project/create", {"idempotencyKey": "stable-key", "name": "New", "roots": []})]:
            with self.subTest(method=method):
                journal = self.journal(method)
                peer = self.proxy([self.read_thread(), {"method": method, "disconnect": True}])
                with self.assertRaisesRegex(api.AdapterError, "disconnected"):
                    api.mutate(peer, self.protocol, method, params, self.scope(), self.binding, journal)
                peer2 = self.proxy([self.read_thread()])
                with self.assertRaisesRegex(api.AdapterError, "already attempted"):
                    api.mutate(peer2, self.protocol, method, params, self.scope(), self.binding, journal)
                events = [e for e in self.events() if e["operationId"] == method]
                self.assertEqual([e["status"] for e in events], ["attempting", "unknown"])

    def test_batch_journal_retains_success_and_failure_separately(self):
        peer = self.proxy([self.read_thread(), {"method": "thread/archive"}, self.read_thread(), {"method": "thread/delete", "error": {"code": -32000, "message": "fixture conflict"}}])
        api.mutate(peer, self.protocol, "thread/archive", {"threadId": "t-1"}, self.scope(), self.binding, self.journal("archive"))
        with self.assertRaises(api.RpcError):
            api.mutate(peer, self.protocol, "thread/delete", {"threadId": "t-1"}, self.scope(), self.binding, self.journal("delete"))
        self.assertEqual([(e["operationId"], e["status"]) for e in self.events()], [("archive", "attempting"), ("archive", "accepted"), ("delete", "attempting"), ("delete", "server_error")])

    def test_timeout_records_unknown_and_server_requests_are_not_approved(self):
        peer = self.proxy([self.read_thread(), {"method": "thread/delete", "delay": 0.4}], timeout=0.15)
        with self.assertRaisesRegex(api.AdapterError, "Timed out"):
            api.mutate(peer, self.protocol, "thread/delete", {"threadId": "t-1"}, self.scope(), self.binding, self.journal())
        self.assertEqual(self.events()[-1]["status"], "unknown")
        peer2 = self.proxy([{"method": "project/list", "serverRequest": True}])
        with self.assertRaisesRegex(api.AdapterError, "interactive"):
            api.read_request(peer2, self.protocol, "project/list", {})
        peer2.process.wait(timeout=1)
        self.assertEqual(self.requests()[-1]["error"]["code"], -32601)


if __name__ == "__main__":
    unittest.main()
