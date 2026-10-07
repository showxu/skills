# Codex App-Server Adapter

Use `scripts/sidebar_app_server.py` for Codex sidebar operations missing from
callable native tools. Requirements: Python 3.10+, a compatible Codex executable,
and an explicitly identified running server's Unix control socket. The helper
uses only the standard library. Run `--help` for arguments.

## Establish the Owner

Locate the executable belonging to the intended application/host; a PATH CLI can
be a different version. Inspect process arguments or product diagnostics to find
the intended server and control socket. Do not guess a socket from its name or
start another server merely to get access to similar-looking local state.

```bash
python3 <skill-dir>/scripts/sidebar_app_server.py probe --codex <codex-bin>
python3 <skill-dir>/scripts/sidebar_app_server.py inspect \
  --codex <codex-bin> --socket <control-socket>
```

`probe` runs version/help/schema-generation commands in a temporary directory.
It reports schema availability, not live method availability. `inspect` connects
through `app-server proxy --sock`, initializes the session, and reads account
identity with token refresh disabled. It prints `binding` and probe evidence.

The binding contains socket, server-reported Codex home/user agent/platform,
an account fingerprint, and whether the account is distinguishable. It contains
no credentials. It detects endpoint/account drift but does not prove an
organization/workspace identity the protocol fails to expose. Match at least
one relevant object to the intended native/UI account, host, and workspace
before permitting writes. If that mapping is unknown, use native tools or UI.
Accounts without distinguishable email/account ID cannot use this write adapter.

## Read and Preview

Put exact parameters in a task-local JSON file. For example, a metadata read
uses `{"threadId":"<observed-thread-id>"}`:

```bash
python3 <skill-dir>/scripts/sidebar_app_server.py call \
  --codex <codex-bin> --socket <control-socket> \
  --method thread/read --params-file <params.json>
```

Use `--all-pages` with `thread/list`, `project/list`, or `threadSection/list`.
The result preserves order and rejects repeated cursors or duplicate IDs across
pages. Read active and archived threads separately. Explicitly select relevant
source kinds when a default interactive-only thread list is insufficient.
Inventory is not a transaction: rerun it if membership/order changes mid-read.

Thread inventory sets `useStateDbOnly: true` to avoid scan-and-repair behavior.
Thread reads set `includeTurns: false`; use the product history reader for
conversation content. The adapter rejects unsupported methods, unknown named
parameters, incompatible shapes, and unavailable schema fields. It validates
the generated schema subset it understands and fails on unhandled validation
keywords. The server remains responsible for full semantic validation.

Mutation calls without `--apply` print a parameter-checked preview without
connecting to the server. This does not check target existence or preconditions.

## Guarded Write

Save a task-local scope object:

```json
{
  "backend": "codex",
  "binding": {},
  "objects": [{"kind": "thread", "id": "thread-example"}],
  "checks": [{
    "method": "thread/read",
    "params": {"threadId": "thread-example"},
    "equals": {"/thread/id": "thread-example", "/thread/name": "Old title"}
  }]
}
```

Replace `binding` with the complete observed `inspect.binding`, and all example
IDs/titles with the resolved current values. The example renames one thread.
Its parameters file is `{"threadId":"thread-example","name":"New title"}`.
Use `kind: project` for projects and `kind: threadSection` for server sections.
Include every referenced object, including destinations and insertion anchors.
Each selected object must appear in a fresh read check.

`equals` maps JSON pointers into the raw read result to expected values. Include
the fields the operation relies on: membership for a transfer, roots/metadata
for a replacement update, and relevant full ordered lists for reorder/deletion.
Checks using list methods always fetch all pages and start without a cursor.
For creation into an empty inventory, an empty `objects` list is valid with a
check such as `project/list` and `equals: {"/data": []}`. Existing-container
creation must check that container. These are before-state checks, not desired
after-state assertions.

```bash
python3 <skill-dir>/scripts/sidebar_app_server.py call \
  --codex <codex-bin> --socket <control-socket> \
  --method thread/name/set --params-file <params.json> \
  --scope-file <scope.json> --apply \
  --journal <task-attempts.jsonl> --operation-id <unique-step-id>
```

The adapter validates scope and current reads, then records and syncs an
`attempting` entry before dispatch. A server response produces `accepted` or
`server_error`; timeout, disconnection, interruption, or another uncertain
failure produces `unknown` when the journal remains writable. A surviving
`attempting` entry also means unknown. Operation IDs cannot be reused in the
same journal. Keep one journal for the entire task, including resumed work.

`accepted` requires subsequent product readback before the agent marks the step
verified. This helper deliberately does not assume server success proves desktop
membership/order or that a created blank thread appears in the UI. It does not
automatically retry. After an error, inspect the current state and record the
reconciliation before issuing any separately identified attempt. Reuse the
original server idempotency key for an uncertain project creation if a retry is
needed and the current protocol guarantees that behavior.

## Supported Semantics

Use [operation routing](operations.md) for the supported method matrix. Common
payloads are:

| Operation | Parameters |
| --- | --- |
| Clear thread project | `thread/metadata/update`: `threadId`, `projectId: ""` |
| Assign project | Same method with an existing `projectId` |
| Reorder project | `project/move`: `projectId`, optional `beforeProjectId` |
| Remove thread section | `thread/section/move`: `threadId`, `sectionId: null` |
| Place/reorder server thread | Same method with section ID and optional `beforeThreadId` |
| Rename project | `project/update`: `projectId`, `name`; omit unedited fields |
| Update section appearance | `threadSection/update`: `sectionId`, current `name`, requested `appearance` |
| Create project | `project/create`: stable `idempotencyKey`, `name`, `roots` |

`thread/settings/update` is restricted to `threadId` and explicit `cwd` here.
`thread/start` accepts sidebar placement (`projectId`, `cwd`,
`runtimeWorkspaceRoots`, non-ephemeral intent); native `create_thread` owns task
prompts and execution configuration. Preserve product-specific creation and
deletion semantics from the current schema/UI.

## Failures and Limits

The write guard is optimistic: changes can occur between reads and dispatch.
Use server conditional operations if they become available; otherwise reread
after each step and never claim transaction isolation. User approval and cloud
deletion recovery are not implemented by `--apply` or the journal.

The proxy refuses server-initiated interactive requests; it does not approve
commands, grant permissions, authenticate, or generate attestation responses.
An interactive requirement must use the appropriate product client. Desktop
global sections, mixed ordering, pinning, and ChatGPT state remain with their
native/UI owners.
