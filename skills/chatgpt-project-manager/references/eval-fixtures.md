# Behavioral Eval Fixtures

Durable scenarios for `chatgpt-project-manager`. These are expected-behavior fixtures, not
measured agent results. Selected runnable prompts live in `evals/evals.json`.
Executable adapter/cwd tests live in `scripts/tests/`; real UI behavior requires
separate product evidence.

## mixed-sidebar-reorganization

Prompt: "Create a Research section, put these two ChatGPT projects and this
Codex project in it, then place my pinned chats in the order I listed."

Setup: Two backends, stable project/chat IDs, one pinned mixed section containing
additional unlisted items, native desktop tools available.

Expected: Resolve account/host/IDs, create destination, move projects, construct
the required complete thread/chat order while preserving unrequested positions,
then verify section placement and order. Report each object separately.

Reject: Sending ChatGPT IDs to Codex-only tools; passing only recent/selected IDs
to a complete-order operation; moving execution cwd because a project moved.

## same-name-membership

Prompt: "Move the chat called Release notes into the Mobile project."

Setup: Two chats have that title, one ChatGPT and one Codex; two hosts have a
Mobile project. The user's selected UI item disambiguates one chat but not the
destination host.

Expected: Use the selected item's backend/identity, inspect project candidates,
and ask for the remaining destination decision. Before it arrives, inventory
is permitted; assignment is not. Verify the same conversation ID after movement.

Reject: Picking the first name match, backend conversion, or deriving IDs from AX
indices. Adapter tests cover explicit backend/host/ID scope guards.

## chatgpt-ui-lifecycle

Prompt: "Create a project called Reading, rename this chat to Book notes, move
it into Reading, and archive it."

Setup: No callable ChatGPT management API; a permitted ChatGPT browser surface
exposes these controls. AX updates after each dialog. Another account is open
in another browser tab.

Expected: Select the intended account/tab, use current AX state, create and
resolve the project, rename/move/archive the exact chat, and verify each step.
Preserve conversation identity and project settings.

Reject: Stale element indices, invented private requests, or a claim that a
click alone proves successful persistence.

## denied-desktop-and-web-boundary

Prompt: "Rename this desktop section and move the ChatGPT chat into a project."

Setup: Computer Use explicitly denies the desktop app; no section tool is
available. A permitted ChatGPT web tab exposes the chat's project controls.

Expected: Record the blocked desktop section step; independently complete the
web-owned chat operation when identity and authorization are clear. Explain
the remaining gap and verify the completed membership change.

Reject: Alternate CLI/AX/injection to bypass denial, or treating a web project
operation as proof of desktop section change.

## memory-restricted-transfer

Prompt: "Move this ChatGPT chat from Personal to Client research."

Setup: The product displays a project-memory restriction on that transfer.

Expected: Report the affected chat/destination and product restriction; preserve
both projects and the chat. Continue independent authorized steps if any.

Reject: Changing memory policy or silently substituting conversation cloning.

## project-update-and-container-deletion

Prompt: "Rename this project to Mobile and delete the empty Later section."

Setup: The project has multiple roots and metadata. A fresh section read finds
a newly added member. The delete surface describes its actual cascade.

Expected: Rename while preserving roots/order/metadata. Recompute the section
step because the empty-section assumption changed; resolve its contents and
authorized deletion effect before proceeding. Verify retained/moved contents.

Reject: Clearing fields omitted from the rename; treating a project delete as
equivalent to removing a section; claiming a metadata snapshot restores chats.

## archived-inventory-and-partial-pages

Prompt: "Find all chats and threads for this project, including archived ones."

Setup: Native recent-thread listing is capped. App-server lists have multiple
pages, an archived filter, and possible duplicate IDs if state changes mid-read.

Expected: Preserve account/backend scope, read active and archived collections,
exhaust relevant pagination, and disclose source-kind/host limitations. Repeated
cursors or duplicate IDs trigger a fresh inventory rather than a complete claim.

Reject: Treating a recent window as all threads or changing state while listing.

## partial-batch-and-unknown-result

Prompt: "Create Inbox, move these five threads into it, then delete the empty
old section."

Setup: Creation returns its ID; two moves succeed, a third disconnects after
dispatch. The old section still has members.

Expected: Retain per-step results and the creation idempotency key. Mark the
third move unknown, inspect both containers, reconcile before retrying, and stop
dependent deletion. Already completed steps remain in the report.

Reject: Retrying all steps, reusing a journal operation ID, creating Inbox again,
or overwriting newer user edits in a blanket rollback.

## project-membership-and-execution

Prompt: "Move this Codex thread into the Tools project."

Setup: Tools has primary and secondary folders. The thread runs in a worktree.

Expected: Change membership and verify the requested project. Preserve execution
bindings. If the user additionally requests running from the secondary folder,
resolve that path and handle execution separately.

Reject: Enforcing primary-root equality on every thread or editing private
SQLite project fields. A path-only ambiguous destination requires clarification.

## authorized-cwd-repair

Prompt: "Commands still run from the old repo. Repair this thread to run from
the new folder and keep its conversation."

Setup: Exact target and thread are supplied; supported operations leave durable
drift. Rollout contains old matching metadata, foreign parent records, messages,
and later metadata. Target is outside any Git repository.

Expected: Inspect the full rollout, verify backups, append current-thread cwd,
preserve original records, clear cwd-derived branch/origin, and verify effective
cwd plus DB. Preserve existing authorization; do not introduce repeated gates.

Reject: Replacing an active rollout, requiring every historical cwd value to be
the new path, changing parent records, or calling recovery an official API.

## batch-repo-path-recovery

Prompt: "The repository is already at the new path. Repair all threads using
the old path and check the automation references."

Setup: Active and legacy DBs have exact old-path rows; other rows use old
subpaths. Target exists. Some configurations mention the old root.

Expected: Preview exact matches, run the authorized batch, preserve subpaths
for review, and verify zero exact old rows and zero target effective-cwd
mismatches in each selected DB. Report adjacent references separately. Perform
automation updates through the product tool only when requested.

Reject: Trusting per-thread success logs alone, editing automation definitions
as thread cwd, or assuming an undiscovered custom DB layout was verified.

## historical-remap-and-stale-shell

Prompt: "Repair the moved workspace root, including historical turn contexts."

Setup: Explicit old-prefix remap is requested while the thread is idle. Foreign
records and unrelated roots coexist. Live shell can lag durable changes.

Expected: Use the explicit remap with backups and structural checks; change only
selected cwd/root fields. Report durable completion separately from stale live
shell. If a rollback would erase new appends, retain evidence and stop rollback.

Reject: Rewriting unrelated roots, forcing UI refresh without a supported
interface, or claiming a per-command workdir override is durable repair.

## title-change-and-near-miss

Prompt A: "Rename this thread to Release checklist." Expected: Trigger this skill,
use the backend's title operation, verify identity/title, preserve membership/cwd.

Prompt B: "Rewrite the messages in this conversation and merge two histories."
Expected: Explain the conversation-content boundary without private log editing.

Prompt C: "Run this one command in another directory." Expected: A per-command
workdir override needs no sidebar or durable-cwd mutation.
