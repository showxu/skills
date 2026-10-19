# Maintainer guide

The skill turns a supplied information set and the applicable DESIGN into a
README layout and its images. It decides placement, form and appearance only;
the information and its values arrive as inputs, and settings and uploads stay
with the caller.

| Surface | Responsibility |
| --- | --- |
| SKILL.md | Triggers, inputs, workflow, boundaries, validation, output |
| design.md | Developer-product README layout, badges, Quick look forms, social preview, organization profile layout |
| design-apps.md | App README layout, variants, consistency and images |
| renderers.md | Renderer input contracts, DESIGN binding and terminal recording format |
| scripts/render_social.py / render_terminal.py | Outlined card layout and light/dark recorded-session rendering |
| scripts/presentation.py | Shared design binding, digest and control-character validation |
| scripts/requirements.txt | Pinned Pillow for raster validation and tinycss2 for SVG attribute URL validation |
| tests / references/eval-fixtures.md / evals/evals.json | Helper regressions and durable behavioral inputs; execution output is ignored |

DESIGN shape is intentionally not guessed: a recipe binds resolved values to
its reviewed design digest. No project fonts, brand colors or assets are
bundled.

Validate with the skill-creator package validator and
`python3 -B -m unittest discover -s skills/github-readme-design/tests -v` from
the collection root, in an ignored virtual environment with
`scripts/requirements.txt` installed. Tests use `README_DESIGN_TEST_OUTPUT`
under the collection's ignored `.build/`. Font rendering smoke checks
additionally need fonttools and a licensed input font; do not bundle a
workstation font into the skill. Run the behavior fixtures as qualitative
review or isolated paired evals and label the evidence correctly.
