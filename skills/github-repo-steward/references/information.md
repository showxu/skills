# Public information

## Copy and metadata

Start with the visitor's outcome, supported by current source, tests or CI.
Use an active sentence without hype or unmeasured superiority. Process terms
such as signing, provenance or independent versioning belong in standards
unless those are the repository's product. About, the README tagline and the
social-card summary use one accepted sentence. The Overview explains the
mechanism or distinction; Quick look demonstrates it. Each adds information.

Keep release versions and drifting membership, feature or performance counts
out of short copy. Measurements need reproducible scope and an owning source.
Topics describe current domains, inputs, outputs and ecosystem; package topics
apply to packages only. Read back the complete topic set and About fields after
publication. Set a homepage only after its destination works.

Do not hand-maintain membership-dependent banners, tables or counts. Route a
catalog or organization profile to the organization owner; generate membership
from its owned data and GitHub inventory with drift checks.

## Information by product kind

Classify the product before deciding what its README states. A repository can
combine kinds, such as an app with a bundled CLI; state each piece of
information once.

| Kind | The README states | Values come from |
| --- | --- | --- |
| Library or package | Dependency line, the products a target uses, a working example of the core result, supported language and platform versions, license | The ecosystem's README skill |
| CLI | Install channels that exist, core commands with real output, requirements | `homebrew`, the release skill, `cli-creator`; the ecosystem's README skill for building from source |
| MCP server | The CLI information that applies, plus the server command and arguments, client configuration and the tools it exposes | `mcp-server-patterns` |
| Plugin for a host | The host it extends, how the host installs it, the capabilities it adds and its external dependencies | The host's plugin contract and the plugin's source |
| App | Download channels that exist, requirements of the released build, what the visitor can do, first-run steps to a first success, permissions and why, data handling, support and feedback channels, release notes | The release or app packaging skill, `homebrew`, the `app-store-*` skills, `macos-tcc-permissions-patterns` |

Each value comes from its owner in the skill's routing table. State only
channels and integrations that exist, and type no value from memory.

Open and closed source state the same information. Source visibility changes
only build-from-source and contribution information, and whether a license or
terms govern use. Verify an installed product's facts against the released
artifact that visitors install, not the source tree.

## Demonstration content

Quick look demonstrates the core result for the product kind with real input,
real output and the released version. Record successful commands and
representative output; build chatter and operator paths do not belong in it.
Keep recording provenance outside the README, with the recording or private
release evidence as appropriate. Explain how to reproduce in the owning
reference. The README demonstrates an outcome; it is not an execution ledger.
