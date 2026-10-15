# Coordinated publication

One repository's versions, tags, changelog, release mechanics and immutable
assets belong to its repository steward and ecosystem release owner. The
organization owns shared version policy and the order/evidence across members.
Do not duplicate per-component release commands here.

## Plan by dependency

Record the accepted revisions and dependency graph. In a product family,
release prerequisites before dependents, then verify distribution/catalog
updates before publishing dependent integrations. An independent package
collection has no imposed global release train; coordinate only the edges
that actually depend on a changed release.

For every member, invoke `github-repo-steward` with the shared standard and
release scope. It hands build/package/store mechanics to the ecosystem release
skill. Shared workflow changes advance through a representative consumer first,
then reviewed pin updates in the template and other members. Neither a template
change nor a new shared revision proves adoption by existing repositories.

## Downstream distribution

Route taps and formula updates to `homebrew`. For a notice-only design, the
schedule observes verified releases and opens deduplicated issues; a normal
signed PR owns each distribution update. Use a scoped App only when authorized
unattended writing requires it. Do not treat a release notification as trusted
catalog data or let it bypass required checks.

The website fetches and validates release facts itself. Notifications request
reconciliation and carry no authoritative payload; a schedule supplies recovery.
Plugins/other integrations retain their host compatibility contracts and
publish through their own release owner.

## Acceptance

Bind each member row to accepted input, merged PR, immutable release identity,
current validation and downloaded artifact/consumer evidence from its owner.
Then verify dependent PRs, working public URLs and the organization catalog.
A prepared branch, an agent's completion message or an earlier green run on a
different SHA is incomplete. Existing published identities remain unchanged.
Do not rerun expensive accepted checks without a changed input or unresolved
concern; reuse evidence only within the scope the owner permits.
