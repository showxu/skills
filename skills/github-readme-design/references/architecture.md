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
| scripts/src/check.ts / cli.ts | Local byte comparison, recording-only CI checks, failure artifacts, commands and exit codes |
| scripts/action.yml / package.json / package-lock.json / .node-version | Composite Action, locked Node package and runtime |
| scripts/src/catalog.ts | Shared catalog/member schemas, safe links and revision-based URL resolution |
| scripts/src/social-preview/ | DESIGN-driven outlined card composition, icon validation and deterministic PNG rasterization |
| scripts/src/profile/render.ts | Public/member markup with parity goldens and required DESIGN sizes |
| scripts/test/ / references/eval-fixtures.md / evals/evals.json | Terminal, social and profile regressions, goldens and durable behavioral inputs; execution output is ignored |

All renderer DESIGN input uses Google's format and the locked official parser;
errors and warnings stop rendering. Components own colors and geometry;
typography owns font selection. Renderers have no fallback style. Platform
constants (canvas dimensions, title legibility floor and README width limit)
are documented in the renderer reference. The catalog owns repository content;
member input owns operational facts. The accepted `.github` commit supplies
the catalog revision for member relative links. Profiles and images are
rendered/checked locally and committed. The shared ecosystem validation workflow
in `github-workflows` uses its `demo` switch for recording-only checks against
the freshly built CLI.

The font fixture is Google Sans Code v7.001 under its accompanying SIL OFL.
Fixture DESIGN values and synthetic catalogs/icons are test inputs, not consumer
defaults. The JPEG/WebP fixtures are encoded variants of the synthetic PNG.
Pinned WebAssembly codecs fully decode still-image inputs; resvg WebAssembly
supplies PNG rendering. WebP inputs are normalized losslessly to an internal
PNG. Animated PNG/WebP inputs fail before embedding, with the file named.
Dependencies, including the development compiler, use JavaScript/WebAssembly;
installation disables lifecycle scripts.
The icon namespace, CSS URL/function and raster checks protect offline,
self-contained rendering without active content or system font lookup.

Validate with the skill-creator package validator and `npm ci --ignore-scripts && npm test` in
`skills/github-readme-design/scripts`. Tests use the collection's ignored
`.build/`; the CI matrix compares terminal SVGs and social-preview PNG bytes on
macOS and Linux. `npm run golden` deliberately updates those image goldens.
Profile Markdown goldens preserve the established public/member bytes and are
not rewritten by that command. Keep the organization observation tests passing
when changing the catalog/member contract.

Run the behavior fixtures as qualitative review or isolated paired evals and
label the evidence correctly. Static checks and local renders do not establish
served GitHub visual acceptance or host installation evidence.
