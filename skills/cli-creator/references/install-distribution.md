# Install And Distribution

## Purpose

Make the CLI visible by command name from any working directory. The install
mechanism is a means to validate product usability, not the core product
architecture.

## Runtime Choice

Choose the least surprising runtime for the source, target repo, dependencies,
and distribution path.

| Runtime | Use when |
| --- | --- |
| Python | The project is Python-first, depends on Python SDKs, data tooling, Playwright, notebooks, or local automation. Prefer `pyproject.toml` console scripts and `uv tool install .` for durable local install. |
| Swift | The project belongs to SwiftPM, macOS/iOS tooling, Apple-platform workflows, or should ship as a native binary. Use SwiftPM, release binaries, or Homebrew when appropriate. |
| Shell | The CLI is a thin wrapper over stable existing commands and has minimal parsing/state. Keep it portable and test from another cwd. |
| Node/TypeScript | The official SDK, browser automation stack, npm distribution, or existing repo tooling is Node-first. |
| Rust | A single durable binary, strict parsing, speed, and easy local binary install matter more than source-language affinity. |

Do not choose a language only because another CLI template prefers it. The
target repo and source evidence own the runtime decision.

## Global Visibility Checks

Run the equivalent of:

```bash
command -v <tool-name>
<tool-name> --help
cd /tmp && <tool-name> --help
cd /tmp && <tool-name> --json doctor
```

If the project does not support `--json doctor`, run the closest installed
setup check and document the gap.

## Install Patterns

- Python: `uv tool install .`, `pipx install .`, or a project-approved console
  script. Verify generated entry points do not depend on the source cwd.
- Swift: `swift build -c release`, copied binary, Homebrew formula, or release
  artifact. Verify resource bundles and config paths work after install.
- Shell: install an executable wrapper into a PATH directory. Verify it locates
  repo assets through explicit config or installed resources, not cwd.
- Node: package `bin`, global link/install, or package-manager-approved global
  workflow. Verify built files are included.
- Rust: release build plus install/copy target or `cargo install --path .`.

## Review Checks

- Is the install command documented and tested?
- Does the CLI work outside the source tree?
- Are local fixtures, templates, schemas, or browser scripts packaged or
  located through explicit config?
- Does `doctor` report missing auth/config without leaking secrets?
- Is upgrade/removal path clear enough for a local tool?
