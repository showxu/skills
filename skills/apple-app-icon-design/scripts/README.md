# Commands

`app_icons.py` uses the Python standard library. Complete exports need macOS,
Icon Composer's native renderer, and `rsvg-convert`. Supply output and temporary
locations that the producing repository ignores. Use `TMPDIR` for temporary
work owned by the caller.

```sh
python3 scripts/app_icons.py DESIGN.md --list
python3 scripts/app_icons.py DESIGN.md --name example-studio --out .build/icons
python3 scripts/app_icons.py DESIGN.md --name example-studio --check .build/icons
python3 scripts/app_icons.py DESIGN.md --name example-studio --out .build/document --document-only
```

`--out` requires a new directory and publishes it only after the entire
candidate succeeds. It never overwrites an existing output. `--check` is
read-only for its target, includes missing and extra files, and returns 1 on
any difference. Document-only output contains just the `.icon` document;
use the same flag when checking that output.

Optional `--ictool PATH` selects an export-capable Icon Composer renderer.
Optional `--design-generation NUMBER` pins the native generation when the
selected renderer supports it. The manifest records the renderer version and
selected generation. Unsupported native arguments fail visibly.

Exit 0 means the requested generation or comparison succeeded. Invalid input,
render failure, or drift exits 1. A successful document-only run does not
establish native rendition or visual readiness.

Run `python3 scripts/test_app_icons.py` for document, drift, preservation,
and failure-path regressions. The tests need only Python; use the native
example and contact sheet to validate renderer behavior and visual quality.
