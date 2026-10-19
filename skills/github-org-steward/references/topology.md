# Organization topology and placement

Choose the model before placing artifacts:

| Model | Meaning and product copy | Publication |
| --- | --- | --- |
| Product family | The product's owning repository; companions consume its accepted identity | Order follows actual dependency edges |
| Package collection | Each independently maintained member; the profile describes the collection's visitor promise | Each member follows its own cadence under shared version policy |

## Roles

| Repository role | Owns |
| --- | --- |
| `.github` | Shared maintenance/versioning/design standards, supported default community files, reusable workflows, organization checks and public profile |
| `.github-private` (private) | Member profile, maintenance navigation and live status; shared policy stays in `.github` |
| Product/package/tool | Its source, interface, requirements, checks, version source, release evidence and meaning |
| Template | Initial member layout and callers; stamping/first-publication validation owned by its ecosystem |
| Website | Public entry, documentation integration, generated catalog and release reconciliation |
| Tap or distribution integration | Its own domain-owned distribution metadata and checks |
| Skills | Authored reusable guidance for the organization, without duplicating the source owner's implementation |
| Fork | Maintained upstream patch line, source ownership and upstream-compatible conventions |

Keep shared invariants in `.github` and member-specific facts with their member.
MAINTENANCE owns declared organization settings and Apps; VERSIONING owns shared
version policy; DESIGN owns family identity. Documentation roles and layout
route to `repository-docs`. No fixed directory layout is imported from another
organization.

Default community-file inheritance and repository-local files are applied by
`github-repo-steward`. Reusable workflows also need explicit pinned callers;
placing a workflow in `.github` does not install it in every member. Update the
template and existing repositories separately through reviewed changes.

Brand exports have one owning generator and design input. Consumers receive
only the exports they use, with a reviewed source revision/digest record if
needed. Do not keep competing local renderers or manually maintained copies.
The organization inventory owns membership; grouping/order metadata owns
presentation, and a generator reconciles the two.

Fork adoption and legal/provenance review route to `fork-dog`. A shared license
policy does not relicense upstream code or third-party fixtures. Preserve
correct ownership records and ask for unresolved legal choices. Do not classify
historical facts as current drift solely because their names differ.

Check GitHub plan/visibility support before promising organization-level
ruleset enforcement or private defaults. Unsupported enforcement is an explicit
acceptance gap, not a successful setting.
