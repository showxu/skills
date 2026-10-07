# Browser Extractors

## Purpose

Use browser extractors when the web UI is the honest source of evidence,
fallback behavior, or DOM-only data. Browser extractors are not OpenAPI. They
need their own contract, schemas, generated runner data, and provider checks
only when they overlap with another interchangeable execution path.

## Extractor Contract

Capture:

- extractor id
- capability id
- implementation or provider name, only when the project has that abstraction
- page URL template and declared query params
- supported input semantics
- wait selectors or readiness conditions
- extractor script symbol or module
- normalizer symbol and arguments
- output schema

## Runtime Shape

```text
extractor contract
  -> generated extractor data
  -> browser runner/adapter
  -> DOM extraction script
  -> normalizer
  -> schema-validated output
  -> use-case result
```

The generated part should own stable wiring: which page to open, which inputs
are supported, which selectors to wait for, which script to execute, which
normalizer to call, and which output schema applies.

The DOM JavaScript and normalizers may remain hand-written. They are page
semantics, not generic codegen trivia.

## Rules

- Do not make browser fallback implicit.
- If browser is the intended implementation path for a browser-only
  capability, keep it internal rather than exposing a provider option.
- If browser is an alternate provider for an existing capability, choose it
  explicitly through documented provider selection and prove it satisfies the
  same output contract.
- Do not claim a browser implementation/provider supports a capability unless an
  extractor contract covers that capability and input shape.
- Validate unsupported input semantics before launching the browser.
- Keep DOM output schemas separate from OpenAPI schemas.
- Treat browser network capture as a separate collector from DOM extraction.
- Screenshots can inform vocabulary and workflow, but they are not schema
  evidence without paired network, DOM, export, or fixture data.
