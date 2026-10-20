# Family identity and organization profiles

## Identity ownership

The organization's `.github/DESIGN.md` owns family tokens, typography, icon
parameters, composition and supported appearances. Resolve values from that
file; never copy another family's hues or font choices. The visual identity
file shape routes to `design-md-template`. Original framework-style icons and
app icons route to their respective icon design owners.

The shared generator and accepted input produce source-controlled exports and
a manifest of digests. Commit inputs and outputs together. Consumers adopt
only needed files through independent reviewed PRs, recording their source and
expected bytes. A consumer check verifies its accepted input/export binding,
so a new shared design revision does not break every older consumer at once.
Remove an export only when its old delivery record proves ownership and its
consumer no longer needs it.

A product family takes claims from the owning product; independent packages
keep their own copy. Generated images consume those accepted words. Font
licenses and provenance stay with bundled resources. Per-repository README
information and preview uploads belong to `github-repo-steward`, and the
layout and rendering of headers, Quick looks, social cards and terminal demos
to `github-readme-design`. Invoke the repository steward for every consumer
with the accepted DESIGN revision. Do not maintain a second renderer here.

## Organization profile

Treat the profile as a visitor entry organized by the reader's job, not a list
of internal repository types. It states the organization promise and a
secondary line, uses the accepted umbrella icon, and links documentation,
contributing, security and support where available. The account description
expresses the same promise and is declared as the catalog's `description`. `github-readme-design` lays out the profile from
these inputs and the catalog.

The public `.github/profile/catalog.json` owns the promise, umbrella mark,
navigation roles, job groups, ordering, outcome sentences and repository icons.
Authoritative GitHub inventory supplies intended public membership; each
repository supplies its outcome sentence and the logo shown in its README
header; a repository without its own logo uses the product it distributes. Generate the profile and check both
byte drift and complete membership. Navigation-only entries need not duplicate
catalog rows. For both public and member profiles, never assemble a membership-dependent
banner, table or count by hand or hide a missing member to make the check pass.

Keep the umbrella mark distinct from the account avatar when the identity
system defines both. Do not redraw either as part of a profile cleanup. Choose
pins as a curated subset supporting the visitor promise and review their order;
the pins are not a second complete inventory. The website landing consumes the
same promise, job groups and umbrella identity.

## Member profile

The member profile is the maintainers' entry in the private
`.github-private/profile/README.md`. It links the shared standard and shows
live state. Policy stays in `.github`; do not restate it in the dashboard.
Treat the content as shareable with any organization member: never include
credentials, private paths or unpublished plans, and never record status by
hand. GitHub requires **private** visibility; internal visibility does not
serve this profile. See [GitHub's profile contract](https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/customizing-your-organizations-profile).

Render content in this order:

1. Header: umbrella mark smaller than the public profile, the title
   `<organization display name> maintainer dashboard`, and one line linking
   the public website or public profile.
2. Maintenance navigation: links to maintenance, versioning/release procedure,
   settings check and design documents in the shared standard. The organization
   declares paths and labels; no universal document layout is assumed.
3. Repositories: the public catalog's job groups in the same order, with one
   row per public member. Show its icon and linked name, a live CI badge for the
   declared workflow on the default branch (or an Actions link when none is
   declared), and a latest-release badge when it publishes releases, otherwise
   a Releases link for an unused channel or an em dash for no release channel.
4. Needs attention: organization-wide searches for open pull requests, open
   issues and Dependabot pull requests, derived from the organization login.

The member repository owns only maintenance navigation and operational facts
per repository: `default_branch`, CI workflow file or none, and release
publication/channel state. Its workflow calls the organization's reusable
`profile.yml` at a full commit SHA and consumes the public catalog and DESIGN
at that revision. Use the shared TypeScript presentation toolchain's
[profile contract](../../github-readme-design/references/renderers.md#organization-profiles);
the reusable workflow supplies `job.workflow_sha` as `catalog-revision` to
member rendering. Missing and extra member operational entries fail rendering.
Commit inputs, the workflow pin and generated output together.

Acceptance requires exact generated bytes, identical public/member membership,
working links and images, and live badges backed by declared facts. The online
organization check compares the catalog with all public, non-archived
repositories except `.github`, verifies each declared `default_branch` against
GitHub, each workflow on the observed default branch, release presence and icon
resolution, and verifies the catalog membership at the workflow's standard
pin. An absent or ambiguous caller leaves the pin unknown. Unreadable private
input is REVIEW, never proof of completeness.
Organizations with maintainers should have this entry; the scanner observes
absence without requiring a repository for organizations that have none.

## Delivery and acceptance

Review both public and member organization profiles and representative consumer READMEs as actually
served in light and dark, including a library and a CLI when both exist.
Apply the shared standard's review gate before rollout. Keep screenshot and
render evidence outside public entry prose. Per-repository preview uploads use
the repository steward after source merges; organization avatar or pin changes
use the owner's signed-in browser within authorization. Never touch session
credentials, cookies or tokens.

Accept only when both generated profiles match their inputs, inventory coverage
is complete, links work, actual pin order matches the decision, and consumer
reports identify the accepted design/source revisions. An uploaded filename
or HTTP success alone cannot prove identity.
