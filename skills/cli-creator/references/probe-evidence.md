# Probe Evidence

## Purpose

Use probes when external behavior is non-official, reverse-engineered,
drift-prone, or insufficiently documented. Probes make maintenance
LLM-friendly by separating facts, schemas, diagnosis, and stable promotion.

## Workflow

```text
capability
  -> probe target
  -> probe or manual ingest
  -> raw evidence
  -> sanitized evidence
  -> observed schema
  -> proposal
  -> stable contract/runtime/docs/tests
```

Failure path:

```text
raw failure evidence
  -> sanitized failure evidence
  -> diagnosis report
  -> LLM diagnosis
  -> fix input/probe/runtime/extractor/contract
  -> reprobe
```

## Evidence Rules

- Raw evidence preserves what was observed.
- Sanitized evidence removes secrets, personal data, cookies, tokens, and
  context-bound values that should not enter the repo.
- Observed schema is generated only from successful capability-output evidence.
- Failed evidence supports diagnosis, not business output schemas.
- Stable contracts require review or an explicit promotion step; scripts should
  not silently decide semantic compatibility.

## LLM And Script Split

Scripts should:

- run probes or ingest evidence
- validate receipts, hashes, target ids, and outcomes
- sanitize payloads with deterministic rules
- infer observed schemas mechanically
- report diffs and validation failures

Agents should:

- decide whether the observed change is real drift, fixture noise, auth issue,
  implementation limitation, provider limitation when providers exist, or
  implementation bug
- propose contract/runtime/extractor updates
- update stable contracts after review
- add tests that protect the accepted behavior

## Probe Target Kinds

Use project-native names, but distinguish targets such as:

- API request
- API response
- API runtime policy
- browser DOM
- browser network
- use-case output
- adapter binding

This classification helps locate the owner when a drift check fails.
