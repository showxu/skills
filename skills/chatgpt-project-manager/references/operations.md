# Operation Routing

Discover callable tools first and read their current schemas. The names below
are candidates verified in a desktop build, not promises of session availability.

| Intent | Native candidate | Codex adapter gap route | UI route / verification |
| --- | --- | --- | --- |
| Inventory | `list_threads`, `list_projects`, `list_archived_threads` | `thread/list`, `project/list`, `project/read`, `thread/read` | ChatGPT sidebar/project/search/archive UI; preserve backend/account |
| Create project | `create_project` | `project/create` | New project; verify identity and attributes |
| Rename/update project | Project tools if exposed | `project/update` | Project menu/settings; preserve unedited fields and folders |
| Delete project | Delete tool if exposed | `project/delete` | Establish actual cascade; verify project and affected members |
| Create thread/chat | `create_thread` | `thread/start` | New chat in intended project; verify saved identity and visibility |
| Rename thread | `set_thread_title` | `thread/name/set` | Chat menu; verify title by identity |
| Archive/restore | `set_thread_archived` | `thread/archive`, `thread/unarchive` | ChatGPT archive controls and archived-chat management |
| Delete thread/chat | Delete tool if exposed | `thread/delete` | Delete control; verify absence including archive/search |
| Pin/unpin | `set_thread_pinned`, project UI | No verified dedicated method | Product pin controls; verify placement separately from membership |
| Change project membership | Assignment tool/UI | `thread/metadata/update` | ChatGPT Move to project / remove-from-project |
| Change execution folder | Execution settings | `thread/settings/update` with `cwd` | Verify subsequent execution; recover remaining durable drift if needed |
| Create/update/delete section | `create_sidebar_section`, `rename_sidebar_section`, `delete_sidebar_section` | `threadSection/create`, `threadSection/update`, `threadSection/delete` for mapped server sections | Desktop section controls; verify contents and appearance |
| Place project in section | `move_project_to_sidebar_section` | No mixed-desktop equivalent | Desktop menu/drag; verify placement |
| Place thread in section | `move_thread_to_sidebar_section` | `thread/section/move` for server sections | Desktop controls for the supported backend |
| Reorder contents | `reorder_section` | `thread/section/move` with `beforeThreadId` for server thread order | Desktop manual order; verify full relevant order |
| Reorder projects | `reorder_sidebar_projects` | `project/move` for server project order | Manual order within the correct container |
| Reorder sections | `reorder_sidebar_sections` | No verified global equivalent | Desktop reorder; verify all custom sections |

## Native Semantics to Recheck

- `list_threads` can include a complete pinned list but only a limited recent
  non-pinned window. It is insufficient for global cleanup. Archived listing
  can be host-specific and Codex-only.
- Thread title/archive/pin tools and thread-section movement may be Codex-only.
  Do not pass ChatGPT IDs merely because the parameter is named `threadId`.
  A section reorder can instead require both backends' IDs.
- `create_thread` can submit a user-visible prompt and start work. Supply only
  authorized text. Resolve pending `clientThreadId` values to final thread/host
  IDs. `thread/start` alone does not prove that a blank thread persists in the
  sidebar; verify retention before reporting creation.
- Local projects can support several folders while remote projects have
  different constraints. Preserve root order and verify the primary folder.
  Creating a project does not authorize moving repository files.

## Ordering and Containers

- `reorder_section` requires the complete current set of thread/chat IDs once
  each. In the inspected build, project positions remain in place.
- `reorder_sidebar_sections` requires all current custom section IDs once each.
- `reorder_sidebar_projects` applies to default unpinned Projects; omitted
  projects retain their positions. Pinned/custom-section projects need the
  operation for their container.
- Special destinations such as `pinned`, `chats`, `threads`, and `null` have
  tool-specific meanings. Do not invent special IDs or assume built-in
  containers support the same editing operations as custom sections.
- `project/move` orders projects, not filesystem directories.
  `thread/section/move` combines server-section membership and order; omitted
  `beforeThreadId` appends.
- If the current view sorts by recency/priority, establish manual sorting when
  supported and required for the requested order, then verify in that view.

## Updates and Deletion

- `thread/metadata/update.projectId`: omitted preserves, `""` clears, an existing
  ID assigns. Do not use `null` as removal. List filters differ: omitted means
  every project, `null` unassigned, an ID that project.
- `threadSection/update` requires name even for appearance changes. Preserve
  the freshly read name. Appearance omitted preserves, null clears, an object
  replaces. Preserve unedited fields in replacement-style objects/maps/lists.
- Desktop section deletion in the inspected build leaves contents available
  outside the section. Establish server-section/project cascade behavior
  separately before deletion, then verify affected contents.
- ChatGPT memory rules can restrict moving chats. Respect current product
  restrictions; do not silently change memory policy or substitute cloning,
  exporting, or deleting/recreating a conversation.

## Capability Gaps

Record the operation/object, evidence, and next usable route when a method is
absent, disabled, denied, or cannot preserve the requested semantics. Keep the
skill's full responsibility visible; a route in this matrix is not a live test.
