# Maintainer guide

The skill owns template selection, inclusion, application and source bindings.
Original local templates are checked-in authored material with a repository
revision. Root `upstreams.yaml` remains authoritative for third-party template
review state and locked provenance. Do not fabricate upstream metadata for an
original template or relax tracking of imported material.

`templates/github-organization-family/DESIGN.md` owns a neutral organization
family presentation template. It supplies renderer defaults and source roles;
organization names, fonts, palettes, document routes and assets come from the
served organization's accepted inputs. Profile recipe mapping belongs to the
profile renderer contract. Template application does not implement renderers,
change GitHub settings or publish either profile.

Run the skill-creator package validator, collection publication checks and
`git diff --check`. Review `references/eval-fixtures.md` qualitatively or run
isolated paired evals through skill-creator; distinguish that evidence from
static package checks. For DESIGN format validation, use the current upstream
linter when available; preserve unknown Presentation sections as extensions.
