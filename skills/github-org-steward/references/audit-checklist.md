# Organization audit checklist

Audit read-only first. Record shared standard revision, scope and observation
time. Each finding has expected/observed values, source evidence, owner,
severity and disposition. Do not claim completion for inaccessible areas.

| Area | Organization evidence | Follow-up owner |
| --- | --- | --- |
| Shared standards | .github maintenance, versioning, design, community defaults and workflow interfaces agree with declared organization decisions | Organization steward; repository-docs for document roles |
| Placement | Shared truth has one owner; members contain only delegated extensions; template adoption is distinct from existing members | Organization steward |
| Organization settings | Actions defaults and actual supported ruleset/plan/visibility scope match declaration | Organization owner and settings checker |
| Apps | Capability, permissions, events, installation selection and credential locations; no secret values | Organization owner; installation gaps need browser evidence |
| Member conformance | One repository-steward audit per in-scope repository, bound to its source and shared revision | github-repo-steward |
| Shared rollout | Consumer proof at proposed full pin, current required contexts, template/member PRs and capacity-bound wave receipts for each runner class and aggregate | Organization steward coordinating repository steward |
| Build-cache adoption | Predeclared material-saving threshold, controlled repeated cold/miss/warm comparisons, net cost and correctness evidence, accepted decision | Organization steward and ecosystem build owner |
| Family identity | DESIGN, generator revision, accepted exports/consumer bindings and icon owners | Design owner plus repository steward for delivery |
| Profile/catalog | Job groups, complete generated membership, outcome copy, umbrella identity, account description and working navigation | Organization steward |
| Member profile | `.github-private` exists and is private for organizations with maintainers; generated from the pinned public catalog with complete matching membership, working live links and no hand-recorded status; policy links back to `.github` | Organization steward |
| Pins | Curated set and actual order support the visitor promise | Organization steward; owner browser |
| Publication | Dependency-ordered accepted releases, release call graph free of cache operations and cancellation, downstream distribution/site PRs and real served artifacts | Repository steward, ecosystem release and distribution owners |
| Handoffs | Authorization, separate task files, disjoint writes, accepted revisions and one coordinated publisher | Organization steward |
| Local preservation | Snapshot/compare plus semantic review of local-only deltas; no owner work discarded | Report only unless separately authorized |

The acceptance scanner is partial evidence. Its per-repository observations do
not replace settings, content, presentation or semantic audits. Judge the latest
observation per workflow ID at the accepted SHA, explain historical/legacy
REVIEW items, and preserve published tags/history. Do not erase required notices
to make a name search empty. Keep an unclear artifact until its purpose is known.
