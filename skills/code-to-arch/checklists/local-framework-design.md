# Local Framework Design Checklist

Use this checklist after capability extraction and boundary filtering.

- What is the local semantic model?
- What is the minimal public surface?
- Which concepts are public API, internal runtime, adapter, renderer, host
  integration, docs truth, tests, or fixtures?
- What belongs in runtime, DSL, adapter, renderer, or host layers?
- Which donor terms should be renamed to local terms?
- Which donor terms should be kept because they clarify local concepts?
- What is intentionally deferred?
- What is explicitly out of scope?
- What is the smallest implementation slice?
- Which tests or fixtures prove the first slice?
- Which docs become architecture truth before implementation?
- Which donor evidence remains in reference docs?
- What future Codex prompt would let another session implement this without
  hidden context?
