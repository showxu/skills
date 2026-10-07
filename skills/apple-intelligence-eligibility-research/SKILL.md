---
name: apple-intelligence-eligibility-research
description: Use this skill for read-only technical research and risk assessment of macOS Apple Intelligence eligibility bypass repositories, especially China SKU or region-gated Mac scenarios, eligibilityd behavior, Darwin Eligibility override patterns, SIP/AMFI/boot-arg requirements, LaunchDaemon persistence, Xcode predictive code completion eligibility, and rollback risk. Do not use for installing bypasses, producing step-by-step bypass instructions, modifying the host Mac, general Apple Foundation Models app implementation, or Xcode IDEIntelligenceChat prompt extraction.
---

# Apple Intelligence Eligibility Research

## Purpose

Use this skill to turn Apple Intelligence eligibility bypass repositories into
an evidence-backed risk report. The output is an audit and decision aid, not an
installation guide or a tool that changes the current Mac.

## Hard Boundary

This skill is read-only.

- Do not execute repository install scripts or copied setup commands.
- Do not run commands that modify the host system, load services, change SIP,
  set boot arguments, attach debuggers, write privileged files, or install
  packages.
- Do not recommend "just run this" commands.
- Do not produce a procedural bypass guide. Explain architecture, evidence,
  risk, rollback, and compatibility.
- If the user asks for live installation, convert the request into a risk
  review, rollback planning checklist, or "do not proceed without manual audit"
  recommendation.

Allowed work:

- Read upstream repositories, local checkouts, README files, scripts, plist
  files, uninstall scripts, release notes, issues, and discussions.
- Clone or sync source into governed workspace upstream reference locations
  only through the owning workspace refs/upstream workflow when applicable.
- Run read-only commands such as `git log`, `git show`, `rg`, `find`, `sed`,
  and file parsers against repository contents.
- Quote short snippets only as evidence and prefer file paths plus line
  references.

## Source Set

Start from the user's provided repositories. If the user provides no list and
the task is the common China-SKU Apple Intelligence eligibility bypass audit,
use this default source set when available:

- `kanshurichard/enableAppleAI`
- `CatMe0w/zouxian`
- `Kyle-Ye/XcodeLLMEligible`
- `hyderay/AiOnMac`

Treat additional repositories as in-scope only when the user provides them or
one of the in-scope repositories explicitly references them as a dependency,
source-chain item, guide, issue, or discussion.

## Workflow

1. Confirm the target scenario: Mac purchase region, physical location, macOS
   version, Apple Silicon generation, Apple ID region, and whether the user
   wants a report, comparison, or go/no-go decision.
2. Resolve local upstream checkouts or read remote source. Prefer local
   `references/upstreams/...` checkouts when present.
3. Record commit hashes before interpreting evidence.
4. Inspect README claims, install/uninstall scripts, plists, LaunchDaemon
   definitions, shell scripts, release notes, issues, and discussions.
5. Verify claims against code. Mark every key claim as verified, contradicted,
   unsupported, or unresolved.
6. Identify the implementation model:
   - `eligibilityd` interaction
   - region/country answer override
   - Darwin Eligibility override file
   - LaunchDaemon or background service
   - SIP, CSR, AMFI, boot-arg, debugger, or private framework dependency
   - Xcode-only predictive completion eligibility versus system-wide Apple
     Intelligence eligibility
7. Separate claimed macOS support from evidenced support. Call out macOS 15.4+
   behavior changes when the inspected source depends on older override
   patterns.
8. Build a risk model covering security, OS integrity, Apple ID/services,
   Apple Pay or iOS-on-Mac side effects, updates, rollback, privacy, and
   reliability.
9. Finish with a decision recommendation and a read-only verification
   checklist.

## Output Contract

For a full assessment, include:

- **Phase / Stage Judgment**: whether the source set is sufficient and whether
  external dependency sources are necessary.
- **Executive Summary**: ranked current usefulness with brief rationale.
- **Repository Matrix**: goal, claimed support, maintenance signal, mechanism,
  SIP/AMFI/boot-arg needs, background service, persistence, rollback, risks,
  and recommendation.
- **Deep Dives**: one section per repository with files inspected, install
  flow as evidence, actual system changes, persistence, security posture,
  version gates, rollback, issues/discussions, and risk assessment.
- **Cross-Repo Implementation Model**: common macOS eligibility concepts and
  why modern macOS versions differ from older approaches.
- **Risk Model**: separated risk categories, not a blended safety statement.
- **Decision Recommendation**: main reference, fallback/comparison reference,
  historical-only reference, and direct-use warning.
- **Verification Checklist**: read-only facts the user should confirm before
  deciding anything.
- **Evidence Appendix**: commit hash inspected, key files, line references,
  verified/contradicted claims, and relevant issues or releases.
- **Code Diff**: say `No code changes were made.` unless the task explicitly
  created local notes, scripts, or repository changes.

## Judgment Rules

- A project is not "safe" merely because it has an uninstall script, says SIP
  can be re-enabled, or persists after reboot. Identify the concrete mechanism.
- A LaunchDaemon or long-running background process is an operational risk
  even when the README presents it as convenience.
- Any requirement for SIP reduction, AMFI changes, boot arguments, or debugger
  attachment must be surfaced as a security posture change.
- Xcode predictive completion eligibility is narrower than system-wide Apple
  Intelligence availability. Do not conflate them.
- README version claims are weak evidence until matched to code paths, release
  notes, or issue confirmations.
- Prefer "current reference", "historical reference", "script-only risk
  reference", and "do not use directly without manual audit" over binary
  safe/unsafe labels.

## Validation

Before closing, verify:

- No host-modifying commands were run.
- Every repository has a commit hash and inspected-file list.
- Matrix rows distinguish claimed support from code evidence.
- Recommendations do not include installation commands.
- Any local workspace refs changes used the governed refs/upstream workflow
  with dry-run before apply.
