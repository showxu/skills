# Maintainer guide

The skill turns a supplied information set and the applicable DESIGN into a
README layout and its images. It decides placement, form and appearance only;
the information and its values arrive as inputs, and settings and uploads stay
with the caller.

| Surface | Responsibility |
| --- | --- |
| SKILL.md | Triggers, inputs, workflow, boundaries, validation, output |
| design.md | Developer-product README layout, badges, Quick look forms, social preview, public and member organization profile layouts and tokens |
| design-apps.md | App README layout, variants, consistency and images |
| renderers.md | Renderer input contracts, DESIGN binding, terminal recording and Action integration |
| scripts/src/design.ts / fonts.ts | Official DESIGN lint/parse, dark overrides, font selection and glyph outlines |
| scripts/src/terminal/ | Validated scripted recording in a fixed environment and deterministic light/dark SVG rendering |
| scripts/src/check.ts / cli.ts | Byte comparison, complete failure artifacts, commands and exit codes |
| scripts/action.yml / package.json / package-lock.json / .node-version | Composite Action, locked Node package and runtime |
| scripts/render_social.py | Outlined card layout |
| scripts/render_profile.py | Deterministic public/member profiles, catalog/member validation and pinned catalog binding |
| scripts/presentation.py | Shared design binding, digest and control-character validation |
| scripts/requirements.txt | Pinned Pillow for raster validation and tinycss2 for SVG attribute URL validation |
| scripts/test/ / tests / references/eval-fixtures.md / evals/evals.json | Node terminal and Python social/profile regressions, golden outputs and durable behavioral inputs; execution output is ignored |

Terminal DESIGN uses Google's format and the locked official parser; errors
and warnings stop rendering. Components own colors and geometry, typography
owns font selection, and the renderer reference owns the platform width
limit. Terminal rendering has no fallback style. Social and profile recipes
bind resolved values to a reviewed DESIGN digest. The terminal golden fixture
includes the specified agents-tools front matter and Google Sans Code v7.001
under its accompanying SIL OFL; these are test inputs, not consumer defaults.

Validate with the skill-creator package validator and
`npm ci && npm test` in `skills/github-readme-design/scripts`, and
`python3 -B -m unittest discover -s skills/github-readme-design/tests -v` from
the collection root, in an ignored virtual environment with
`scripts/requirements.txt` installed. Tests use `README_DESIGN_TEST_OUTPUT`
under the collection's ignored `.build/`. Node tests also use `.build/` and
compare both SVGs to committed goldens on macOS and Linux. `npm run golden`
updates those expected bytes deliberately. Social font rendering smoke checks
additionally need fonttools and a licensed input font. Run the behavior fixtures as qualitative
review or isolated paired evals and label the evidence correctly. Static
checks and local renders do not establish served GitHub visual acceptance or
host installation evidence.
