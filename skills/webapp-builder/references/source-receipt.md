# Webapp Builder Source Receipt

## Source Type

`webapp-builder` is a local integrated skill created for the generic Web layer.
It is not an Anthropic-compatible baseline mirror. It absorbs OpenAI/Codex Web
app implementation guidance after local boundary review.

## Sources Inspected

- OpenAI curated plugin `build-web-apps`, cache revision `6188456f`: skills
  `frontend-app-builder`, `react-best-practices` and `shadcn-best-practices`.
- OpenAI upstream repository `https://github.com/openai/skills` at commit
  `4c4058ebf44f6734e62c70ab4a81246d4d093fc8`.

The upstream checkout did not contain the Build Web Apps curated skills at the
same path. The local curated plugin cache is the inspected source for those
skills.

## Capability Disposition

| Source capability | Disposition | Local owner |
| --- | --- | --- |
| App shell, route structure, complex app UI component architecture | Absorbed | `webapp-builder` |
| Repo framework conventions, state/data helpers, reusable app modules | Absorbed | `webapp-builder` |
| React/Next server/client boundaries, request waterfalls, serialization, rendering and re-render hygiene | Absorbed as project-level engineering guidance | `webapp-builder` |
| shadcn CLI, registry, installed component discovery, dry-run/diff update workflows, preset caution | Absorbed as project-level shadcn guidance | `webapp-builder` |
| Design direction, image concept generation, visual fidelity bar, design system extraction | Kept with design owner | `frontend-design` |
| Browser evidence, screenshots, visual/functional QA, debugging workflow | Kept with QA owner | `webapp-testing` |
| Single-file HTML artifact scaffolding and bundling | Kept with artifact owner | `web-artifacts-builder` |
| Product requirements, interaction behavior, and acceptance criteria | Not absorbed | Product source skills own these facts |
| Figma operations | Not absorbed | Figma/design owner |

## Maintenance Rule

When refreshing this skill from OpenAI sources, route source changes through
`any-to-skill -> skill-distiller -> skill-creator`. Keep source-specific
ideas only when they strengthen repo-local Web app implementation without
turning this skill into visual design, artifact bundling, QA, product
management, or backend ownership.
