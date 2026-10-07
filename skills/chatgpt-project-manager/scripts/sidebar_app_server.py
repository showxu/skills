#!/usr/bin/env python3
"""Inspect schemas and perform scoped sidebar requests through a running Codex proxy."""

from __future__ import annotations

import argparse
import contextlib
import fcntl
import hashlib
import json
import math
import os
from pathlib import Path
import re
import selectors
import shutil
import subprocess
import sys
import tempfile
import time
from typing import Any


READS = {"project/list", "project/read", "thread/list", "thread/read", "threadSection/list"}
LISTS = {"project/list", "thread/list", "threadSection/list"}
WRITES = {
    "project/create", "project/update", "project/delete", "project/move",
    "thread/start", "thread/name/set", "thread/metadata/update", "thread/settings/update",
    "thread/archive", "thread/unarchive", "thread/delete", "thread/section/move",
    "threadSection/create", "threadSection/update", "threadSection/delete",
}
OBJECT_FIELDS = {
    "threadId": "thread", "beforeThreadId": "thread",
    "projectId": "project", "beforeProjectId": "project", "sectionId": "threadSection",
}


class AdapterError(Exception):
    pass


class RpcError(AdapterError):
    pass


def encode(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, allow_nan=False)


def digest(value: Any) -> str:
    return hashlib.sha256(encode(value).encode()).hexdigest()


def read_json(path: str) -> Any:
    def reject_constant(value: str) -> None:
        raise AdapterError(f"Invalid JSON constant: {value}")
    return json.loads(Path(path).expanduser().read_text(), parse_constant=reject_constant)


def pointer(value: Any, path: str) -> Any:
    if path == "":
        return value
    if not path.startswith("/"):
        raise AdapterError(f"Expected a JSON pointer: {path}")
    try:
        for token in path[1:].split("/"):
            token = token.replace("~1", "/").replace("~0", "~")
            if isinstance(value, list):
                if not re.fullmatch(r"0|[1-9][0-9]*", token):
                    raise AdapterError(f"Invalid JSON pointer array index: {token}")
                value = value[int(token)]
            else:
                value = value[token]
        return value
    except (KeyError, IndexError, TypeError, ValueError) as error:
        raise AdapterError(f"Missing expected field: {path}") from error


def validate_shape(value: Any, schema: Any, root: dict, path: str = "params") -> None:
    """Validate generated parameter shapes, rejecting unhandled validation keywords."""
    if schema is True:
        return
    if schema is False:
        raise AdapterError(f"{path}: forbidden value")
    known = {
        "$ref", "$schema", "$id", "$comment", "definitions", "$defs", "title",
        "description", "default", "deprecated", "examples", "format", "type",
        "enum", "const", "anyOf", "oneOf", "allOf", "properties", "required",
        "additionalProperties", "items", "minItems", "maxItems", "uniqueItems",
        "minLength", "maxLength", "pattern", "minimum", "maximum",
        "exclusiveMinimum", "exclusiveMaximum", "minProperties", "maxProperties",
    }
    if set(schema) - known:
        raise AdapterError(f"{path}: unsupported schema keywords: {sorted(set(schema) - known)}")
    if "$ref" in schema:
        ref = schema["$ref"]
        if not ref.startswith("#/"):
            raise AdapterError("Only local generated schema references are supported")
        validate_shape(value, pointer(root, ref[1:]), root, path)
    for key in ("anyOf", "oneOf", "allOf"):
        if key in schema:
            passes = 0
            for branch in schema[key]:
                try:
                    validate_shape(value, branch, root, path)
                    passes += 1
                except AdapterError:
                    pass
            valid = passes == len(schema[key]) if key == "allOf" else passes == 1 if key == "oneOf" else passes > 0
            if not valid:
                raise AdapterError(f"{path}: does not match {key}")
    types = schema.get("type", [])
    types = [types] if isinstance(types, str) else types
    matches = {
        "null": value is None, "boolean": type(value) is bool,
        "integer": type(value) is int,
        "number": type(value) in (int, float) and math.isfinite(value),
        "string": isinstance(value, str), "array": isinstance(value, list),
        "object": isinstance(value, dict),
    }
    if types and not any(matches.get(t, False) for t in types):
        raise AdapterError(f"{path}: expected {types}")
    if "enum" in schema and not any(encode(value) == encode(v) for v in schema["enum"]):
        raise AdapterError(f"{path}: value outside enum")
    if "const" in schema and encode(value) != encode(schema["const"]):
        raise AdapterError(f"{path}: incorrect constant")
    if isinstance(value, dict):
        missing = set(schema.get("required", [])) - set(value)
        if missing:
            raise AdapterError(f"{path}: missing {sorted(missing)}")
        props = schema.get("properties", {})
        # Rust-generated objects often omit additionalProperties. Fail on typos
        # in named parameter objects while retaining explicitly declared maps.
        extra = schema.get("additionalProperties", False if "properties" in schema else True)
        for key, item in value.items():
            validate_shape(item, props.get(key, extra), root, f"{path}.{key}")
        for key, op in (("minProperties", lambda n: len(value) >= n), ("maxProperties", lambda n: len(value) <= n)):
            if key in schema and not op(schema[key]):
                raise AdapterError(f"{path}: {key} violated")
    if isinstance(value, list):
        if "items" in schema:
            if isinstance(schema["items"], list):
                raise AdapterError("Tuple schemas are not supported")
            for i, item in enumerate(value):
                validate_shape(item, schema["items"], root, f"{path}[{i}]")
        if schema.get("uniqueItems") and len({encode(v) for v in value}) != len(value):
            raise AdapterError(f"{path}: duplicate items")
    if isinstance(value, (str, list)):
        low, high = ("minLength", "maxLength") if isinstance(value, str) else ("minItems", "maxItems")
        if low in schema and len(value) < schema[low] or high in schema and len(value) > schema[high]:
            raise AdapterError(f"{path}: length outside schema bounds")
    if isinstance(value, str) and "pattern" in schema and not re.search(schema["pattern"], value):
        raise AdapterError(f"{path}: pattern mismatch")
    if type(value) in (int, float):
        for key, valid in (("minimum", lambda n: value >= n), ("maximum", lambda n: value <= n),
                           ("exclusiveMinimum", lambda n: value > n), ("exclusiveMaximum", lambda n: value < n)):
            if key in schema and not valid(schema[key]):
                raise AdapterError(f"{path}: {key} violated")


class Protocol:
    def __init__(self, root: dict):
        self.root = root
        self.methods = {}
        for variant in root.get("oneOf", []):
            props = variant.get("properties", {})
            for method in props.get("method", {}).get("enum", []):
                self.methods[method] = props.get("params", {"type": "null"})
        if not self.methods:
            raise AdapterError("ClientRequest.json has an unrecognized method layout")

    def prepare(self, method: str, params: dict, internal: bool = False) -> dict:
        if not isinstance(params, dict):
            raise AdapterError("Parameters must be an object")
        if method not in READS | WRITES and not (internal and method in {"initialize", "account/read"}):
            raise AdapterError(f"Method outside sidebar adapter: {method}")
        if method not in self.methods:
            raise AdapterError(f"Method unavailable in selected CLI schema: {method}")
        params = dict(params)
        if method == "thread/list":
            if params.get("useStateDbOnly") is False:
                raise AdapterError("Sidebar inventory requires useStateDbOnly=true")
            params["useStateDbOnly"] = True
        if method == "thread/read":
            if params.get("includeTurns") is True:
                raise AdapterError("Sidebar adapter reads metadata; use the product history reader for turns")
            params["includeTurns"] = False
        if method == "thread/metadata/update" and "projectId" in params and params["projectId"] is None:
            raise AdapterError('Omit projectId to preserve it; use "" to clear it')
        if method == "thread/settings/update" and (set(params) - {"threadId", "cwd"} or "cwd" not in params):
            raise AdapterError("Sidebar settings adapter only owns explicit cwd updates")
        if method == "thread/start" and set(params) - {"projectId", "cwd", "runtimeWorkspaceRoots", "ephemeral"}:
            raise AdapterError("Use native create_thread for task prompts and execution configuration")
        if method == "thread/start" and params.get("ephemeral"):
            raise AdapterError("Sidebar creation requires a persistent thread")
        validate_shape(params, self.methods[method], self.root)
        return params


def local_probe(binary: str) -> tuple[dict, Protocol]:
    resolved = shutil.which(binary)
    if not resolved:
        raise AdapterError(f"Codex executable not found: {binary}")
    resolved = str(Path(resolved).resolve())
    def command(args: list[str]) -> str:
        result = subprocess.run([resolved, *args], capture_output=True, text=True, timeout=60)
        if result.returncode:
            raise AdapterError(f"Codex probe command failed: {args[0]} (exit {result.returncode})")
        return result.stdout.strip()
    version = command(["--version"])
    proxy_help = command(["app-server", "proxy", "--help"])
    if "--sock" not in proxy_help:
        raise AdapterError("Selected CLI does not expose app-server proxy --sock")
    with tempfile.TemporaryDirectory(prefix="chatgpt-project-manager-schema-") as directory:
        command(["app-server", "generate-json-schema", "--experimental", "--out", directory])
        root = read_json(str(Path(directory) / "ClientRequest.json"))
    protocol = Protocol(root)
    return {
        "binary": resolved, "version": version, "schemaFingerprint": digest(root),
        "methods": sorted((READS | WRITES) & protocol.methods.keys()),
        "missingMethods": sorted((READS | WRITES) - protocol.methods.keys()),
        "evidence": "local schema only; running-server and desktop behavior require separate verification",
    }, protocol


class Proxy:
    def __init__(self, command: list[str], timeout: float):
        self.timeout = timeout
        self.stderr = tempfile.TemporaryFile()
        self.process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=self.stderr)
        self.selector = selectors.DefaultSelector()
        self.selector.register(self.process.stdout, selectors.EVENT_READ)
        self.buffer = b""
        self.sequence = 0

    def close(self) -> None:
        self.selector.close()
        if self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
        with contextlib.suppress(OSError):
            self.process.stdin.close()
        self.process.stdout.close()
        self.stderr.close()

    def send(self, value: dict) -> None:
        self.process.stdin.write((encode(value) + "\n").encode())
        self.process.stdin.flush()

    def request(self, method: str, params: dict) -> Any:
        self.sequence += 1
        request_id = self.sequence
        self.send({"id": request_id, "method": method, "params": params})
        deadline = time.monotonic() + self.timeout
        while True:
            if time.monotonic() >= deadline:
                raise AdapterError(f"Timed out waiting for {method}; inspect state before retrying")
            if b"\n" not in self.buffer:
                if not self.selector.select(max(0, deadline - time.monotonic())):
                    raise AdapterError(f"Timed out waiting for {method}; inspect state before retrying")
                chunk = os.read(self.process.stdout.fileno(), 65536)
                if not chunk:
                    raise AdapterError(f"Proxy disconnected during {method}; inspect state before retrying")
                self.buffer += chunk
                if len(self.buffer) > 32 * 1024 * 1024:
                    raise AdapterError("Proxy response exceeded metadata size limit")
                continue
            line, self.buffer = self.buffer.split(b"\n", 1)
            if not line.strip():
                continue
            message = json.loads(line)
            if not isinstance(message, dict):
                raise AdapterError("Malformed proxy message")
            if "method" in message:
                if "id" in message:
                    self.send({"id": message["id"], "error": {"code": -32601, "message": "Sidebar client cannot handle server-initiated requests"}})
                    raise AdapterError("Server requested an interactive action; use a supported interactive client")
                continue
            if message.get("id") != request_id:
                raise AdapterError("Unexpected proxy response ID")
            if "error" in message:
                raise RpcError(f"{method}: {encode(message['error'])}")
            if "result" not in message:
                raise AdapterError("Proxy response lacks result/error")
            return message["result"]


def bind(proxy: Proxy, protocol: Protocol, socket_path: str) -> dict:
    init = protocol.prepare("initialize", {
        "clientInfo": {"name": "chatgpt-project-manager", "version": "1.0.0"},
        "capabilities": {"experimentalApi": True},
    }, internal=True)
    response = proxy.request("initialize", init)
    proxy.send({"method": "initialized", "params": {}})
    if not isinstance(response, dict):
        raise AdapterError("Malformed initialization response")
    for key in ("codexHome", "userAgent", "platformOs"):
        if not isinstance(response.get(key), str) or not response[key]:
            raise AdapterError(f"Server cannot establish binding field {key}")
    account_response = proxy.request("account/read", protocol.prepare("account/read", {"refreshToken": False}, internal=True))
    if not isinstance(account_response, dict):
        raise AdapterError("Malformed account response")
    account = account_response.get("account")
    identity = {k: account[k] for k in ("type", "email", "accountId", "workspaceId") if k in account} if isinstance(account, dict) else {}
    return {
        "socket": str(Path(socket_path).expanduser().resolve()),
        "codexHome": response["codexHome"], "userAgent": response["userAgent"],
        "platformOs": response["platformOs"], "accountFingerprint": digest(identity),
        "accountIdentityKnown": bool(identity.get("email") or identity.get("accountId")),
    }


def read_request(proxy: Proxy, protocol: Protocol, method: str, params: dict, all_pages: bool = False) -> Any:
    if method not in READS:
        raise AdapterError("State checks must use sidebar read methods")
    params = protocol.prepare(method, params)
    if not all_pages:
        return proxy.request(method, params)
    if method not in LISTS:
        raise AdapterError("--all-pages requires a supported list method")
    items, ids, cursors = [], set(), set()
    if params.get("cursor"):
        raise AdapterError("Complete inventory must start without a cursor")
    while True:
        result = proxy.request(method, params)
        if not isinstance(result, dict) or not isinstance(result.get("data"), list):
            raise AdapterError("Unrecognized paginated response; inventory is incomplete")
        for item in result["data"]:
            if not isinstance(item, dict) or not isinstance(item.get("id"), str) or not item["id"]:
                raise AdapterError("List item lacks stable identity")
            if item["id"] in ids:
                raise AdapterError("Duplicate ID across pages; inventory changed, reread it")
            ids.add(item["id"])
            items.append(item)
        cursor = result.get("nextCursor")
        if cursor is None:
            return {"data": items, "nextCursor": None}
        if not isinstance(cursor, str) or not cursor or cursor in cursors:
            raise AdapterError("Invalid/repeated cursor; inventory is incomplete")
        cursors.add(cursor)
        params["cursor"] = cursor


def check_scope(proxy: Proxy, protocol: Protocol, scope: dict, binding: dict, method: str, params: dict) -> None:
    if not isinstance(scope, dict):
        raise AdapterError("Scope must be an object")
    if scope.get("backend") != "codex":
        raise AdapterError("This adapter requires Codex scope; ChatGPT uses native tools or Computer Use")
    if not binding["accountIdentityKnown"]:
        raise AdapterError("Server lacks distinguishable account identity; use an established native product route")
    if scope.get("binding") != binding:
        raise AdapterError("Server/account binding changed; inspect and resolve scope again")
    objects = scope.get("objects")
    if not isinstance(objects, list) or any(not isinstance(o, dict) or o.get("kind") not in set(OBJECT_FIELDS.values()) or not isinstance(o.get("id"), str) or not o["id"] for o in objects):
        raise AdapterError("Scope objects must have kind and nonempty id")
    selected = {(o["kind"], o["id"]) for o in objects}
    if len(selected) != len(objects):
        raise AdapterError("Duplicate scope object")
    for field, kind in OBJECT_FIELDS.items():
        value = params.get(field)
        if value and (kind, value) not in selected:
            raise AdapterError(f"Unscoped {field}: {value}")
    checks = scope.get("checks")
    if not isinstance(checks, list) or not checks:
        raise AdapterError("Writes require fresh read checks")
    observed = set()
    for check in checks:
        if not isinstance(check, dict) or not isinstance(check.get("equals"), dict) or not check["equals"]:
            raise AdapterError("Each scope check requires nonempty JSON-pointer equals assertions")
        result = read_request(proxy, protocol, check["method"], check.get("params", {}), check["method"] in LISTS)
        for path, expected in check["equals"].items():
            if encode(pointer(result, path)) != encode(expected):
                raise AdapterError(f"State changed at {check['method']} {path}; recompute the operation")
        if check["method"] in LISTS:
            kind = {"project/list": "project", "thread/list": "thread", "threadSection/list": "threadSection"}[check["method"]]
            observed.update((kind, item["id"]) for item in result["data"])
        else:
            kind = "thread" if check["method"] == "thread/read" else "project"
            item = result.get(kind, {})
            if isinstance(item.get("id"), str):
                observed.add((kind, item["id"]))
    if not selected <= observed:
        raise AdapterError("Every scoped object must be present in fresh checks")


class Journal:
    def __init__(self, path: str, operation_id: str):
        self.path = Path(path).expanduser()
        self.operation_id = operation_id

    @contextlib.contextmanager
    def locked(self):
        fd = os.open(self.path, os.O_RDWR | os.O_CREAT | os.O_APPEND, 0o600)
        with os.fdopen(fd, "a+", encoding="utf-8") as file:
            fcntl.flock(file, fcntl.LOCK_EX)
            yield file

    def append(self, status: str, payload: dict, first: bool = False) -> None:
        with self.locked() as file:
            if first:
                file.seek(0)
                for line in file:
                    if not line.endswith("\n"):
                        raise AdapterError("Journal has an incomplete record; inspect it before proceeding")
                    if json.loads(line).get("operationId") == self.operation_id:
                        raise AdapterError("Operation ID already attempted; inspect its journal and current product state")
            event = {"operationId": self.operation_id, "status": status, "time": time.time(), **payload}
            file.write(encode(event) + "\n")
            file.flush()
            os.fsync(file.fileno())


def mutate(proxy: Proxy, protocol: Protocol, method: str, params: dict, scope: dict, binding: dict, journal: Journal) -> dict:
    if method not in WRITES:
        raise AdapterError("Not a sidebar mutation")
    params = protocol.prepare(method, params)
    check_scope(proxy, protocol, scope, binding, method, params)
    journal.append("attempting", {"method": method, "params": params, "binding": binding, "scopeFingerprint": digest(scope)}, first=True)
    try:
        result = proxy.request(method, params)
    except BaseException as error:
        journal.append("server_error" if isinstance(error, RpcError) else "unknown", {"error": str(error)})
        raise
    journal.append("accepted", {"result": result})
    return {"status": "accepted", "result": result, "verification": "Read back through the owning product surface before marking this operation verified"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["probe", "inspect", "call"])
    parser.add_argument("--codex", default="codex", help="Prefer the executable belonging to the selected running app")
    parser.add_argument("--socket", help="Explicit existing app-server Unix control socket")
    parser.add_argument("--method")
    parser.add_argument("--params-file", help="JSON object; omitted means {}")
    parser.add_argument("--scope-file", help="Observed binding, scoped objects and before-state checks")
    parser.add_argument("--all-pages", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--journal", help="Task-local JSONL attempt log; parent directory must exist")
    parser.add_argument("--operation-id", help="Unique step ID within this task's journal")
    parser.add_argument("--timeout", type=float, default=20)
    args = parser.parse_args()
    if not math.isfinite(args.timeout) or args.timeout <= 0:
        raise AdapterError("Timeout must be finite and positive")
    evidence, protocol = local_probe(args.codex)
    if args.command == "probe":
        print(encode(evidence))
        return 0
    params = read_json(args.params_file) if args.params_file else {}
    if args.command == "call":
        params = protocol.prepare(args.method, params)
        if args.all_pages and args.method not in LISTS:
            raise AdapterError("--all-pages requires a supported list method")
        if args.method in WRITES and not args.apply:
            print(encode({"status": "preview", "method": args.method, "params": params, "probe": evidence, "checksRun": False}))
            return 0
        if args.method in WRITES and not all((args.scope_file, args.journal, args.operation_id)):
            raise AdapterError("--apply requires --scope-file, --journal and --operation-id")
    if not args.socket or not Path(args.socket).expanduser().is_socket():
        raise AdapterError("Select an existing app-server control socket with --socket")
    socket_path = str(Path(args.socket).expanduser().resolve())
    with contextlib.closing(Proxy([evidence["binary"], "app-server", "proxy", "--sock", socket_path], args.timeout)) as proxy:
        binding = bind(proxy, protocol, socket_path)
        if args.command == "inspect":
            print(encode({"binding": binding, "probe": evidence}))
        elif args.method in READS:
            result = read_request(proxy, protocol, args.method, params, args.all_pages)
            print(encode({"binding": binding, "result": result}))
        else:
            result = mutate(proxy, protocol, args.method, params, read_json(args.scope_file), binding, Journal(args.journal, args.operation_id))
            print(encode(result))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AdapterError, OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print(encode({"status": "error", "error": str(error)}), file=sys.stderr)
        raise SystemExit(1)
