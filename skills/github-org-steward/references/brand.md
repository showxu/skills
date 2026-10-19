# Family identity and organization profile

## Identity ownership

The organization's `.github/DESIGN.md` owns family tokens, typography, icon
parameters, composition and supported appearances. Resolve values from that
file; never copy another family's hues or font choices. The visual identity
file shape routes to `design-md-template`. Original framework-style icons and
app icons route to their respective icon design owners.

The shared generator and accepted input produce source-controlled exports and
a manifest of digests. Commit inputs and outputs together. Consumers adopt
only needed files through independent reviewed PRs, recording their source and
expected bytes. A consumer check verifies its accepted input/export binding,
so a new shared design revision does not break every older consumer at once.
Remove an export only when its old delivery record proves ownership and its
consumer no longer needs it.

A product family takes claims from the owning product; independent packages
keep their own copy. Generated images consume those accepted words. Font
licenses and provenance stay with bundled resources. Per-repository README
information and preview uploads belong to `github-repo-steward`, and the
layout and rendering of headers, Quick looks, social cards and terminal demos
to `github-readme-design`. Invoke the repository steward for every consumer
with the accepted DESIGN revision. Do not maintain a second renderer here.

## Organization profile

Treat the profile as a visitor entry organized by the reader's job, not a list
of internal repository types. It states the organization promise and a
secondary line, uses the accepted umbrella icon, and links documentation,
contributing, security and support where available. The account description
expresses the same promise. `github-readme-design` lays out the profile from
these inputs and the catalog.

One catalog input owns the promise, navigation roles, job groups and ordering.
Authoritative GitHub inventory supplies intended public membership; each
repository supplies its outcome sentence. Generate the profile and check both
byte drift and complete membership. Navigation-only entries need not duplicate
catalog rows. Never assemble a membership-dependent banner, table or count by
hand or hide a missing member to make the check pass.

Keep the umbrella mark distinct from the account avatar when the identity
system defines both. Do not redraw either as part of a profile cleanup. Choose
pins as a curated subset supporting the visitor promise and review their order;
the pins are not a second complete inventory. The website landing consumes the
same promise, job groups and umbrella identity.

## Delivery and acceptance

Review the organization profile and representative consumer READMEs as actually
served in light and dark, including a library and a CLI when both exist.
Apply the shared standard's review gate before rollout. Keep screenshot and
render evidence outside public entry prose. Per-repository preview uploads use
the repository steward after source merges; organization avatar or pin changes
use the owner's signed-in browser within authorization. Never touch session
credentials, cookies or tokens.

Accept only when the generated profile matches its inputs, inventory coverage
is complete, links work, actual pin order matches the decision, and consumer
reports identify the accepted design/source revisions. An uploaded filename
or HTTP success alone cannot prove identity.
