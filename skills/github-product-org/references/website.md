# Website

## Role

`<org>.github.io` is the product's official entry: product pages, setup guide,
documentation, the plugin catalog, and links to releases. Its README owns its
build and check commands; this reference owns how it fits the organization.

## Deployment

- GitHub Pages deploys from the default branch through a workflow. The same
  workflow runs on push, on a schedule, and on `workflow_dispatch`.
- The repository's check script covers format, HTML validity, build, links, and
  tests, and is the required check with the brand check.
- The deploy job alone holds Pages and identity-token permissions; every other
  job keeps a read-only token.

## Catalog Reconciliation

When the website lists plugins or releases:

- One central job verifies sources itself (tags, checksums, acceptance
  records) and renders the catalog. Notifications carry no data and cannot
  override policy; they only request a run.
- When the catalog changes, the job proposes the change as a pull request
  through the Updater App and enables auto-merge; checks run on that pull
  request and the ruleset decides.
- Plugins notify through a composite action owned by the website and pinned by
  full commit in each plugin's workflow. It mints a Release Notifier token
  scoped to the website and `actions: write`, and dispatches the deploy
  workflow with only `{"ref":"<default branch>"}`.
- Notify on release published, edited, released, unpublished, and deleted.
  The schedule is the fallback when notification fails.

## Visual Checks

- Screenshot every language at desktop, around 1000px, and mobile widths.
- Navigation must not wrap or break words; CJK headings must not orphan
  punctuation; the language toggle stays on one line.
- Confirm the declared font strategy, licenses, colors and tokens match
  `DESIGN.md`; inspect actual light/dark rendering and keyboard behavior.
- Implementation: `frontend-design` or `webapp-builder`. Browser QA:
  `webapp-testing`. Copy: `ux-writing`.

## Pitfalls

- Prettier with `proseWrap: always` rewraps edited Markdown; run the pinned
  formatter before pushing documentation edits.
- Changing the notifier action's descriptions or code creates a new commit;
  plugins keep their pinned commit until they choose to move.

## Package-Collection Website

Keep group order, install kinds and documentation selection in one catalog data
file. Derive public membership, descriptions, releases and contributors from
GitHub metadata. Check that the configured catalog equals the intended public
non-fork repositories; reconcile missing members rather than hiding them to
make a build pass.

Build DocC from the latest accepted published tags, resolved to full SHAs.
Use source archives or worktrees, remove transient source inputs afterward,
and cache by source, toolchain, selection and identity. The default branch can
supply current branding; it must not replace the tagged API source. Inject
missing landing identity during the build, preserve existing directives and
cover synthesized multi-module roots. Keep product claims in package sources.

Deploy through Pages Actions on default-branch pushes, manual dispatch and a
weekly rebuild. Only the deployment job receives Pages and OIDC permissions.
An optional narrowly scoped notifier requests a rebuild; the website remains
responsible for fetching and validating source facts.

Bootstrap an empty website with its accepted license before running the live
catalog/license check. Local bootstrap validation does not replace the live
check after publication. After deployment, verify every landing, redirects,
contributing anchor, catalog card, icon and color; test supported breakpoints,
light/dark appearance, keyboard use and clipboard/JavaScript fallbacks.

Apply the organization’s `blog` URL and repository About homepages only when
their destinations work. Record expected descriptions, full topic sets and
homepages in one delivery input, then read back the actual public metadata.
