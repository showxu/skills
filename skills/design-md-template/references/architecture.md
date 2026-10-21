# Maintainer guide

The skill owns template selection, inclusion, application and source bindings.
Original local templates are checked-in authored material with a repository
revision. Root `upstreams.yaml` remains authoritative for third-party template
review state and locked provenance. Do not fabricate upstream metadata for an
original template or relax tracking of imported material.

`templates/github-organization-family/DESIGN.md` owns a neutral organization
family presentation template in Google's DESIGN.md format. Its front matter
carries every token `github-readme-design`'s terminal, social preview and
profile renderers read, with geometry and typography defaults and a stand-in
palette; its prose names source roles. Organization names, palettes, fonts,
marks and assets come from the served organization's accepted inputs.
Renderer behavior belongs to `github-readme-design`'s renderer contract.
Template application does not implement renderers, change GitHub settings or
publish either profile.

Included templates carry Google DESIGN.md front matter derived from their
own stated colors, typography, radii, spacing and component values. Preserve
the source body and record each adaptation in its root `upstreams.yaml`
segment. Native iOS points map to `px` with the same number, including letter
spacing (`17pt` becomes `17px`): both represent density-independent logical
units, following the convention used by design tools such as Figma.
Unitless line-height ratios are written in `em` (`1.2` becomes `1.2em`),
because the parser drops unitless line heights. Component values come only
from the source; lint warnings that only an invented value would remove stay.

Run the skill-creator package validator, collection publication checks and
`git diff --check`. Review `references/eval-fixtures.md` qualitatively or run
isolated paired evals through skill-creator; distinguish that evidence from
static package checks. For DESIGN format validation, use the current upstream
linter when available; preserve sections the format does not define, such as
Iconography, as extensions.
