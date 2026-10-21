# CI baseline

Policy and validation are separate workflows. Title edits must rerun title and
added-line policy without producing a skipped validation result on the same
commit. Such a skip can replace a previous failing required result.

| Caller | Pull request activity | Other triggers | Concurrency |
| --- | --- | --- | --- |
| Policy | opened, synchronize, reopened, edited | default-branch push | Cancel superseded runs |
| Validation | opened, synchronize, reopened | default-branch push, manual dispatch | Cancel superseded runs |
| Release validation/publication | Repository-owned release event or manual accepted tag | As declared by release owner | Preserve running and queued releases |

For policy and validation, use distinct workflow names and this group shape:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true
```

The PR number handles fork contributions; the workflow name separates policy
from validation. Release workflows and their callers/callees never cancel
running or queued releases. Omit a shared concurrency group unless its queue is
proven to retain every intended run. `cancel-in-progress: false` alone still
allows a later pending run to replace an earlier one. If serialization is
required, use the platform's supported queue with an admitted wave below its
current queue limit and no cancelling option; otherwise coordinate dispatch
without a conflicting group. Separate workflow names/groups prevent unrelated
CI from cancelling releases. Keep release validation and publication outside
cancel-on-new-push callers, including job-level concurrency and cancellation
automation. Check [current concurrency semantics](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency)
before choosing a queue configuration. Release matrices disable fail-fast so
one failing member does not cancel the others; the aggregate still fails.

Release workflows never restore or save caches. This includes validation,
build, packaging and publication, setup-action caches, dependencies, compiler
outputs and reusable callees. Build from fresh paths and accepted immutable
inputs; transfer only artifacts produced and verified within that release run.
Ecosystem owners implement that contract in their toolchain. Development/PR
cache adoption needs the organization's controlled measurement gate, or an
equivalent repository-owned threshold and experiment when no organization
standard applies; a faster single run is insufficient.

Policy checks the PR title and added lines, using the repository's accepted
terms and publication constraints. External and bot contributions are welcome.
Default-branch policy can verify the accepted committer/signature contract
without requiring the original author to be the owner. Do not execute untrusted
PR code in a privileged `pull_request_target` workflow. Pass untrusted event
text through environment or structured arguments rather than interpolating it
into shell source.

Pin third-party actions and reusable workflows to full reviewed commits. A
pin to a release carries its `# vX.Y.Z` comment; a pin to an unreleased
commit of a change still in progress carries none.
Reusable callers derive input values from the consuming repository. A shared
change needs syntax validation and a real consumer run at the proposed pin.
Update callers through PRs after that evidence; a template only affects new
repositories. Keep all related callers consistent with the shared interface.

Add a pin-drift observation: resolve the shared repository's actual default
branch to a SHA, enumerate callers, and report workflow path, observed ref,
expected ref and unavailable lookups. Do not silently repin or turn each shared
commit into a consumer failure. The applicable standard decides whether drift
is advisory or blocking. API failure is unknown, not a clean pin report.

Stable result jobs use `always()` and inspect each dependency result explicitly;
a failed/cancelled dependency must fail the aggregate. Preserve exact required
contexts when splitting callers. Observe the resulting names before changing
rulesets, including reusable names such as `<caller> / <called>`.

Use read-only default permissions, minimal explicit write jobs and Dependabot
for actual ecosystems. Ecosystem-specific compilers, SDKs, deployment floors,
version validators and artifact formats route to their owners.
A timeout during observation is not cancellation: continue observing the same
run; acceptance uses the latest run per workflow ID at the accepted SHA.
