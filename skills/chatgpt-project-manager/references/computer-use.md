# Computer Use Workflow

Use the host's Computer Use tool for ChatGPT chat/project operations and desktop
sidebar gaps. Read its active documentation and associated skill first. Follow
its access/confirmation rules and the user's established authorization.

## Surface Selection

1. Locate the intended desktop app or ChatGPT browser tab and verify the account
   and workspace. An app display name is not its bundle identity.
2. Prefer Accessibility (AX) labels, roles, and observed controls. Use screenshots
   when AX is incomplete or visual context is needed. Reuse the host runtime.
3. Respect explicit target-access denials. CLI calls, another AX driver,
   injected code, or a changed app identifier must not bypass them. Another
   permitted surface is usable only for operations it independently owns.
4. ChatGPT web can provide chat/project operations; verify the current controls.
   Desktop mixed sections and ordering remain desktop-owned operations.

The inspected installation has a Computer Use CLI with a `mcp` subcommand.
Launcher/executable locations are runtime details. Prefer the session's tool
(for example, `cua_repl`). CLI entrypoints do not add target permissions.

## Procedures

| Task | Action | Verify |
| --- | --- | --- |
| Find | Sidebar/search/project/archive lists, paging or scrolling as needed | Account, backend, stable link/ID where exposed, title and parent |
| Create project | New project; enter authorized name and options | Identity, name, attributes and visibility |
| Create chat | Enter intended project, then New chat | Drafts may need a first message to persist; send only authorized text and verify saved identity |
| Rename | Item menu, rename dialog, save | Same identity with requested title |
| Update project | Read settings, change requested fields, save | Changed fields and preserved unedited fields |
| Move chat | Move to project / remove-from-project; resolve destination | Source/destination membership and same conversation identity |
| Archive/restore | Archive control or archived-chat management | Correct active/archive state |
| Delete | Read exact item's confirmation and cascade; follow required approval | Intended absence and preservation of other contents |
| Pin/section/order | Observed menu controls or drag handles | Placement and complete relevant manual order |

After actions, read fresh UI state before choosing another target. Element
indices expire after dialogs, list/account/tab/sort changes. Prefer AX actions
over coordinates. Derive drag endpoints from current state and verify the drop.

Titles can collide; virtualized sidebars expose partial lists. Use links/IDs
when available. Otherwise preserve account, project, title, and observed context
and resolve ambiguity before writing. AX indices are never backend IDs.

## Bulk and Failure Handling

Operate serially with per-object results. Create destinations, move members,
then reorder and remove containers. After uncertain outcomes, reread/search
before retrying. Keep completed results and pause dependent steps.

Product warnings are constraints, not permission. Surface memory-policy or
transfer restrictions without changing settings to circumvent them. Do not
extract auth cookies or invent private HTTP payloads as a UI substitute.

For required handoffs, prepare the exact operation first and explain the
requirement from the active tool/skill. Avoid redundant confirmation loops for
routine operations already authorized and permitted by the active rules.
