# Python Project Facts

Use this rule to translate Python repository facts into documentation shape.

## pyproject.toml

Read `pyproject.toml` before writing public docs. Check:

- project name, description, Python version, license, authors, and URLs
- build backend and package layout
- dependencies and optional dependency groups
- console script entry points
- ruff, pytest, mypy, pyright, coverage, MkDocs, Sphinx, pdoc, or other tool
  configuration

The README should not contradict the package name, command names, Python
version, or install path declared by `pyproject.toml`.

## Package Layout

Document the actual package shape:

- `src/<package>/` layout
- top-level `<package>/` layout
- namespace packages
- CLI entry points
- provider or adapter directories
- generated code directories
- contracts, schemas, or metadata directories

Do not invent a package layout that the repository does not use.

## Tooling

Use repository-native commands in docs and validation guidance. Derive command
examples from `pyproject.toml`, existing docs, scripts, or CI configuration
instead of forcing one toolchain. Template placeholders should be replaced with
actual commands such as:

```bash
<test-command>
<lint-command>
<typecheck-command>
<public-command> --help
```

When the repo does not use a tool, do not introduce that tool in the docs.

## Generated Artifacts

Generated Python clients, OpenAPI clients, schema metadata, MCP metadata,
command metadata, and generated docs must be identified as generated. The docs
should say which script or command regenerates them and where manual edits
belong instead.

## Public Manual Essentials

For a Python package, CLI, tool, service, MCP server, or library, the root
README should include:

- what it does
- requirements
- install or setup
- quick start
- common commands or examples
- expected output
- configuration and auth basics when relevant
- links to architecture, reference, and troubleshooting docs
