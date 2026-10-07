# Skills Monorepo Scripts

Root scripts are limited to shared repository helpers. Skill review,
trigger hardening, package validation, and production readiness belong to
`skills/skill-creator/`.

- `check_repository.py` checks the published tree, marketplace paths and
  versions, and delegates skill structure to the owning package validator.
- `check_policy.py` verifies the source range and publication content of a
  GitHub push or pull request.
- `upstream_manifest.py` manages the source-tracking manifest.
