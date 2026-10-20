# Coordinated publication

One repository's versions, tags, changelog, release mechanics and immutable
assets belong to its repository steward and ecosystem release owner. The
organization owns shared version policy and the order/evidence across members.
Do not duplicate per-component release commands here.

## Shared version policy

Write the organization `.github` root `VERSIONING.md` from the repository
steward's [VERSIONING template](../../github-repo-steward/templates/VERSIONING.md.tpl).
Fill its repository, version source, mirrors, release details and ecosystem
release owner from the organization's declared inputs. Append organization-only
sections for family release order and the members' release table. Keep the
common policy in the shared template rather than restating it in this skill.

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

## Size rollout waves to available runners

Before dispatching member PRs or publication, record the organization's current
Actions plan/limits and runner inventory, observation time, occupied and
reserved slots, and the peak simultaneous jobs each proposed member will need.
Account for matrix expansion, reusable workflows and jobs triggered by merges.
Budget each runner class separately, especially macOS, and also respect the
organization's aggregate concurrent-job limit and any runner-group restrictions.
Use observed capacity, not a remembered limit from another plan or organization.
See [current organization jobs](https://docs.github.com/en/actions/how-tos/manage-runners/github-hosted-runners/view-current-jobs).

For every class and the aggregate, admit a wave only when its summed peak
demand fits the available budget after existing work and a stated reserve.
Record member, dependency, runner demand, wave, accepted input, dispatch and
completion evidence. The smallest constrained class bounds the wave size;
different matrix sizes need different member counts. If limits or workload are
unknown, measure a representative consumer and resolve capacity before broad
dispatch. Do not treat a backlog as spare capacity.

Complete the wave's required checks and review, reconcile failures and accepted
revisions, then refresh usage before admitting the next wave. Preserve unrelated
jobs and queued releases. Capacity controls submission; it is not permission to
cancel accepted work. Publication dependency edges still apply within each wave.

## Measure before adopting a development build cache

The shared standard records the metric, material-saving threshold, sample plan,
representative consumers and acceptance rule **before** the controlled trial.
The threshold comes from the organization's cost/latency goals; do not import a
one-run number or lower it to accept the result. Until evidence meets that
threshold, retain the uncached baseline.

Compare cache-disabled builds with cache-enabled cold/miss and warm/hit builds
at the same accepted source, lockfiles, toolchain/SDK, runner class/image,
configuration, validation coverage and job layout. Use repeated comparable
pairs and record runner variability, median/spread and realistic hit/miss mix.
Include restore, upload/save and population costs in net savings. Record queue
time separately so quieter runner demand is not credited to the cache. Confirm
equivalent correctness checks and permitted artifact provenance; a hit or a
single faster run is not acceptance.

Keep the raw run receipts in the producer-owned evidence location; record the
threshold, comparison and adopt/defer/reject decision in the owning standard.
Adopt through reviewed shared changes and bounded consumer waves only after
the stated material saving is demonstrated. A proposed cache without controlled
evidence remains a proposal.

## Preserve release execution

Invoke the repository steward's [release workflow contract](../../github-repo-steward/references/ci.md)
for every release caller and transitive reusable job: no cache restores or saves
and no automatic cancellation of running or queued releases. That contract also
covers setup/dependency caches and pending-run replacement. The coordinator
checks the complete call graph and admits publication waves within both runner
and queue capacity; successful development cache measurements never exempt a
release. Ecosystem owners supply fresh build paths and same-run artifact proof.

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
Include the capacity snapshot and wave receipts, any cache experiment decision,
and the repository owner's release cache/concurrency audit.
Then verify dependent PRs, working public URLs and the organization catalog.
A prepared branch, an agent's completion message or an earlier green run on a
different SHA is incomplete. Existing published identities remain unchanged.
Do not rerun expensive accepted checks without a changed input or unresolved
concern; reuse evidence only within the scope the owner permits.
