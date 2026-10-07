# Doctor And Diagnostics

## Purpose

`doctor` gives users and agents a non-destructive way to understand whether
the CLI is installed, configured, authenticated, and able to reach required
dependencies.

## Minimum Checks

Include checks that match the target CLI:

- binary version and runtime version
- config path existence and parseability
- auth source category: env, config, flag, platform default, browser profile,
  or missing
- endpoint reachability or offline-mode status
- required local tools such as browser runtime, SDKs, compilers, git, ffmpeg,
  or other dependencies
- writable cache/output directories if the CLI writes files
- generated contract/schema availability when packaged

## Output

`doctor --json` should be stable and non-secret:

```json
{
  "ok": false,
  "checks": [
    {
      "id": "auth",
      "status": "missing",
      "message": "No token or config profile found.",
      "hint": "Set the documented environment variable or run init."
    }
  ]
}
```

## Rules

- `doctor` must not mutate remote state.
- `doctor` should avoid live writes. If it uses a live read, say so in docs.
- Missing auth, verification, captcha, IP blocks, and expired sessions should
  be reported as environment/account conditions before implementation bugs.
- Do not print full tokens, cookies, browser profile secrets, or customer data.
- Keep diagnosis actionable: state what is missing and the next setup step.
