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
version policy; DESIGN owns family identity. Documentation roles route to
`repository-docs`. The layout below is the standard, with GitHub-defined paths
first.

## Organization GitHub layout

| Place | Rule | Source |
| --- | --- | --- |
| Public `.github` repository | `profile/README.md` is the public organization profile. Supported default community health files and issue/PR templates apply to members without their own; licenses cannot be defaults. `workflow-templates/` holds organization workflow templates, pairing `<name>.yml` with `<name>.properties.json`. | [Organization profile](https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/customizing-your-organizations-profile), [default community health files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file), [workflow templates](https://docs.github.com/en/actions/how-tos/reuse-automations/create-workflow-templates) |
| Private `.github-private` repository | `profile/README.md` is the member-only profile. Members see it by default and switch with **View as**. Public and member views each pin up to six repositories; only organization owners pin. | [Organization profile](https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/customizing-your-organizations-profile) |

Use the [repository layout](../../github-repo-steward/references/layout.md)
for each repository's `.github/` directory and presentation assets. The local
organization layout keeps design inputs, catalog selections and generated
profile outputs with their shared owner:

```text
DESIGN.md                              tokens and rationale (Google format)
profile/catalog.json                   repositories, product kind, icon, outcome text
profile/README.md                      generated public profile
profile/assets/                        avatar and marks (consumed icon exports)
.github/design/fonts/                  font files, upstream names, OFL.txt
.github/design/icons/<name>/           layers/*.svg, provenance.json
.github/assets/social-preview/         the organization repository's own preview
```

Keep only GitHub presentation sources under `.github/design/`. Each icon's
`provenance.json` records its consumed copies, output paths, SHA-256 digests,
skill commit, renderer version and regeneration command. Consumed files live
with their owners. Icon Composer `.icon` documents are regenerated from DESIGN
and layers into ignored scratch for review. Product design, including shipped
product icons, stays with the product; README logos are recorded exports.

Each organization owns one DESIGN with its variants. The catalog owns
per-repository selections, including icon and outcome text; members consume
the shared design and supply their content. Keep generated catalog membership
reconciled with the authoritative inventory. The private repository links to
shared policy in `.github` rather than maintaining another copy.

## Shared defaults and consumers

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
