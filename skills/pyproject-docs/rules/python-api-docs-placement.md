# Python API Docs Placement

Use this rule when a Python project needs API documentation, generated docs
output, schema documentation, or generated client documentation.

## Principle

Python API documentation should be explicitly owned and reproducible. It may
be authored by hand, generated from docstrings/type hints, or generated from
contracts, but it should not blur with repository architecture truth.

## Source Versus Output

Documentation source inputs may include:

- Python docstrings and type hints
- `pyproject.toml` tool configuration
- MkDocs, Sphinx, pdoc, or similar source files
- OpenAPI, JSON Schema, GraphQL, or other contract files
- generated-client source annotations when checked into the repo by policy

Generated output may include:

- built documentation sites
- generated API reference pages
- generated OpenAPI client docs
- generated schema reference
- coverage or test report output

Treat generated output as build artifacts unless the repository explicitly
documents a checked-in publishing policy.

## Placement

Good repository-level placement:

```text
docs/architecture/runtime-contracts.md
docs/reference/source-bundles.md
docs/reference/cli-output.md
docs/api/README.md
```

Good source placement:

```text
src/<package>/
<package>/
contracts/
schemas/
```

Avoid by default:

```text
docs/generated-site/
docs/_build/
htmlcov/
Documentation/API/
```

## Ownership

- `docs/architecture/*` explains current architecture and generated-artifact
  ownership.
- `docs/reference/*` explains durable reference contracts and schemas.
- `docs/api/*` indexes authored or generated API reference when the repo
  intentionally publishes it.
- Generated output must identify its regeneration command or be excluded from
  source documentation.

## Audit Checks

- README-class files link to API reference without duplicating full API docs.
- Generated docs output is ignored, generated outside the source tree, or
  explicitly governed as a published artifact.
- Generated client or schema docs are not hand-edited.
- `docs/api/*` is present only when API documentation is intentionally
  authored or published.
