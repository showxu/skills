# Resource Capture Mode

Use resource capture mode when interaction-design research needs local artifacts
from public design/prototyping resources. Captured files are research artifacts;
they are not source-of-truth product behavior, not active skill examples, and
not renderer inputs unless a later workflow explicitly uses them.

## Boundaries

- Capture only resources needed to inspect interaction/prototype object models.
- Preserve source URL, local path, byte size, hash, and validation signal.
- Keep confidence labels clear: official docs, public runtime artifact, local
  probe, inferred field, or speculative field.
- Do not implement importers, exporters, renderers, or production code from this
  mode.
- Do not let captured artifacts define product behavior. Product behavior still
  belongs in the canonical interaction model.

## Rive Runtime Files

Rive public Community and Marketplace pages expose runtime `.riv` files for the
browser player. These files are useful runtime/state-machine evidence.
Editable `.rev` files are editor-source backups and are not exposed by public
player pages.

Fetch public Rive runtime files with:

```bash
scripts/rive-cli \
  https://rive.app/community/files/8510-16308-state-machine-sample/
```

The script accepts:

- Rive Community / Marketplace page URLs.
- Direct public `.riv` URLs under `public.rive.app` or `cdn.rive.app`.
- `--url-file <path>` with one source URL per line.
- `--dry-run` to list discovered runtime files without downloading.

Default output:

```text
references/research/artifacts/rive/local-probe/
```

Each downloaded file is validated by the `RIVE` magic bytes and recorded in:

```text
references/research/artifacts/rive/local-probe/download-manifest.json
```

Treat `.riv` as runtime evidence for artboards, animations, state machines,
inputs, transitions, listeners, and events. Do not infer editable `.rev` fields
from `.riv` alone.
