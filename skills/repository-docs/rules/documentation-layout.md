# Documentation Layout

Repositories without an ecosystem documentation adapter use `docs/`. This
includes skill collections, taps, websites and organization `.github`
repositories. Use `docs/README.md` as the documentation index and create role
subdirectories only when they have content:

| Role | Directory |
| --- | --- |
| Current architecture | `docs/architecture/` |
| Proposals | `docs/proposals/` |
| Accepted decisions with lasting rationale | `docs/decisions/` |
| Migration records | `docs/migrations/` |
| Archived history | `docs/archive/` |
| Reference material | `docs/reference/` |
| Intentionally published API reference | `docs/api/` |

Use lowercase kebab-case file names, such as
`docs/reference/workflow-integration.md`. Keep conventional names such as
`README.md`, `AGENTS.md` and GitHub-defined files in their established form.
These directories separate current truth, proposals, history and reference;
they do not change the authority of the facts placed there. Open work stays
in the repository's issue tracker, and task state stays with its declared
owner.

Version rules live in the root `VERSIONING.md`, owned by `github-repo-steward`.
Release facts and mechanics beyond its release procedure go in
`docs/reference/release.md`. Other documents link them and do not restate
version rules.

An ecosystem documentation adapter owns its ecosystem's paths and naming.
For repositories without one, treat other documentation trees as input to
normalization into `docs/`, preserving unique content and updating links.
A documentation audit reports needed moves; it does not authorize them.
