# Organization website integration

The organization's site is a separate repository, with its own implementation,
checks and deployment contract. `github-repo-steward` owns its GitHub standard;
website implementation and QA route to the Web skills. This reference owns
cross-repository meaning and catalog/documentation integration.

Use the same visitor promise, job grouping and umbrella identity as the profile.
Keep product claims in owning member sources. Catalog membership comes from
GitHub inventory reconciled with explicit grouping/order and install-kind
configuration; fail on missing intended members rather than hiding them.
Descriptions, releases and contributors should be derived, not duplicated into
hand-maintained tables.

For a release/plugin catalog, the website verifies source tags, digests and
release records itself. Notifications request a run only. Schedules recover
missed notifications. A change that writes catalog source uses a reviewed PR
and the organization's authorized automation design. Deployment permissions
stay scoped to the deployment job, with non-cancelling publication.

Documentation builds use accepted published source revisions. Current identity
may be applied separately from tagged API sources without moving release tags
or replacing those sources with the default branch. Ecosystem documentation
skills own directive/metadata handling; preserve existing directives and cover
synthesized combined landings when relevant. Cache keys identify source,
toolchain, selection and identity; transient checkouts come from worktrees or
archives and are retired after the producer finishes.

Verify real hosted landings, redirects, navigation and catalog links, member
icons and appearance, contributing anchors, and appropriate installation paths.
Review declared languages, responsive widths, light/dark, keyboard use and
fallbacks through the website QA owner. Read actual image/metadata bytes where
identity matters; HTTP 200 alone is insufficient. Set organization website
fields and member homepages only after their destinations work.
