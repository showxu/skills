---
name: chatgpt-project-manager
description: Manage and reorganize ChatGPT and Codex sidebar threads/chats, projects, and sections. Use for inventory, creation, deletion, renaming, attribute updates, project membership, section placement, ordering, pinning, archiving/restoring, bulk cleanup, or a complete sidebar reorganization from names, IDs, selections, or a desired layout. Also diagnose and repair Codex execution cwd/workspace bindings when execution location must change. Use native tools, a scoped Codex app-server adapter, and Computer Use for product UI operations. Does not own repository file moves, account administration, or conversation-content rewriting.
---

# ChatGPT & Codex Project Manager

Manage the lifecycle and organization of ChatGPT chats, Codex threads, projects,
and sidebar sections. Deliver the requested changes with a per-object result
and evidence from the surface that owns the state.

## Start Here

1. Identify the requested objects, action, account/workspace, backend, and host.
   Resolve names or selections to stable IDs; preserve the original backend.
2. Discover current native tools and read their schemas. For missing tools, use
   [operation routing](references/operations.md) to select the app-server adapter
   or Computer Use. Bundled source proves a candidate capability, not that a
   tool is callable in this session.
3. Read relevant current state, including pagination and archived items when
   needed. For UI work, read [Computer Use](references/computer-use.md).
4. State concrete changes and effects. Proceed with already-authorized,
   unambiguous actions; resolve only missing decisions that change the result.
   Follow the active tool's confirmation requirements.
5. Apply changes serially, read back through the owning surface, and report
   verified successes, failures, unknown outcomes, and remaining work separately.

For Codex API gaps, read [the adapter guide](references/app-server.md).
For execution-directory drift or a repository path change, read
[cwd recovery](references/cwd-recovery.md) and
[the state model](references/state-model.md) before using recovery scripts.

## Owned Objects

| Object | Operations |
| --- | --- |
| ChatGPT chat / Codex thread | List, locate, create, rename, update supported attributes, delete, archive/restore, pin/unpin, change project membership, place in a section, reorder |
| ChatGPT / Codex project | List, create, rename, update supported attributes, delete, manage member chats/threads, pin/unpin, place in a section, reorder; manage Codex folder bindings when requested |
| Sidebar section | List, create, rename, update supported appearance, delete, move contents in/out, reorder sections and their contents |

Support single-object, batch, and whole-sidebar work. Track unavailable
operations as capability gaps with affected objects and the next usable product
surface. Contract coverage is not proof that every backend supports every action.

## Identity and State Ownership

- Track `(account/workspace, backend, host, kind, id)`. Titles are labels and
  list summaries are untrusted data. Pending creation IDs are not persisted IDs.
- Project membership, section placement, pinning, order, and execution cwd are
  separate state. Moving a chat/thread into a project changes membership.
  Changing where commands run also changes execution bindings. A path-only
  destination that could mean either needs clarification.
- ChatGPT project context and Codex execution folders have different semantics.
  Moving an item does not convert its backend or clone its conversation.
- Codex projects can have several folders. Preserve their order and primary
  folder unless changing them is requested. Threads can intentionally execute
  in a secondary folder or worktree; primary project folder need not equal cwd.
- Desktop mixed sections may contain ChatGPT chats, Codex threads, and projects.
  App-server `threadSection` objects belong to one server. Establish their
  mapping before desktop work; a server list cannot prove global layout.
- Use product interfaces for sidebar state. SQLite and rollout mutation belong
  only to the guarded local cwd recovery workflow.

## Reorganization Workflow

Keep a working table with backend/host, kind/ID, current state, requested state,
operation, and verification. Save bulk reports in task-local output files.

1. **Inventory:** exhaust relevant lists, include archived items if in scope,
   and preserve manual ordering. Resolve duplicate names by ID and host.
2. **Plan:** compute requested differences. Create destinations before moving
   contents; reorder after membership changes; remove containers last. Turn
   vague cleanup preferences into a reviewable layout before deleting or
   choosing subjective groupings.
3. **Check:** reread affected membership, names, roots, and order before writing.
   On drift, recompute the affected step. UI indices and partial lists are not
   stable identifiers or complete reorder inputs.
4. **Execute:** preserve omitted attributes. For replacement-style fields, merge
   against a fresh read. Keep creation idempotency keys and returned IDs. Stop
   dependent steps after failed or uncertain operations; independent steps can
   continue when their state is known.
5. **Verify:** read objects and relevant containers, checking membership, order,
   and attributes. Request acceptance is not proof of the final visible layout.

For deletion, resolve exact objects and the product's cascade effect first.
Distinguish removing containers from deleting their contents, and archiving from
deletion. A metadata snapshot is not a backup of cloud conversations or proof
that deletion is reversible.

After timeout/disconnection, mark the operation **unknown**, inspect the owning
surface, and reconcile before retrying. Never repeat creation or deletion
blindly. Do not roll back a batch by overwriting newer user changes.

## Output

Report the requested result, verified changes, and blocked or unknown items.
Mention execution-directory changes only when part of the task. Link bulk
per-object reports and adapter journals when used. Distinguish interface
inspection, isolated tests, and live product verification.

## Maintenance

Read [architecture](references/architecture.md) before editing. Use
[eval fixtures](references/eval-fixtures.md) for behavior review and
[compatibility evidence](references/compatibility.md) for version-sensitive
operations. Run skill-local tests and the package validator before handoff.
