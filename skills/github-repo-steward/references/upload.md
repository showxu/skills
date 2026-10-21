# Social preview upload and verification

GitHub's supported upload route is the repository Settings page; there is no
supported repository social-preview upload API. Do not reverse engineer an
upload-token endpoint. Check the current
[GitHub upload instructions](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview)
when the UI changes. Prepare 1280×640 accepted PNGs within its current upload
limits. The accepted file must come from the merged source revision.

GitHub permits uploads to public repositories and to private repositories that
already have an uploaded preview image. Sharing the preview is supported only
for public repositories.

## Owner's browser

Use the owner's already signed-in browser and a task tab. Confirm the account,
repository URL and repository identity before upload. Let the owner perform
login, passkeys and permission changes. Never touch credentials, cookies,
authentication headers, tokens, browser profiles or session databases.

1. Open Settings → General → Social preview → Edit → Upload an image.
2. Select the accepted PNG using the normal chooser or supported browser file
   input API. Confirm the UI finishes saving. Do one repository at a time.
3. If chooser automation fails, use a page-context route only within the
   existing authorization and trusted settings page. On macOS, the owner
   temporarily enables the browser's Apple Events JavaScript setting. Do not
   enable it yourself or broaden automation permissions.
4. Address the task tab explicitly with Apple Events `do JavaScript`. Navigate
   in one operation, then inspect the loaded page in a separate operation;
   navigation invalidates page context. Inspect the current image input and
   repository ID instead of hardcoding a stale selector.
5. In page JavaScript create a `File` from the exact accepted PNG bytes. Supply
   bytes from the local accepted artifact or fetch a public raw file pinned to
   its merged SHA. Never send credentials with that fetch. Add the file to a
   `DataTransfer`, assign its `files` to the observed input and dispatch the
   input/change events expected by the page. Let GitHub's own normal handler
   save it. Do not read hidden authentication fields or call a private endpoint.
6. Verify the result below. If access or page scripting fails, preserve the
   prepared image and hand the specific UI step to the owner; do not bypass
   login, CSP or a permission boundary. Close only the task tab.
7. Hand back explicitly: the owner turns Apple Events JavaScript off again.
   Record whether restoration is confirmed or still pending; do not claim it
   is disabled merely because the upload finished.

## Independent receipt

After each upload, run `scripts/verify_upload.py` against the accepted local
image and keep its JSON receipt in the task's private evidence. Install the
steward's pinned `scripts/requirements.txt` in an ignored virtual environment.

```sh
python3 <skill>/scripts/verify_upload.py social-preview --repository <owner/repository> --image <accepted.png> --source-commit <merged-sha> --json <private-evidence/preview.json>
```

The script queries the exact repository with GraphQL through the existing
GitHub CLI login:

```graphql
query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    id nameWithOwner openGraphImageUrl usesCustomOpenGraphImage
  }
}
```

It checks the returned repository identity case-insensitively and requires the
custom-image flag, fetches the served image without credentials, and records
time, source revision, GraphQL ID, local/served SHA-256, byte lengths,
dimensions and decoded RGBA pixel comparison. Both images must be 1280×640.
Byte equality and pixel equality are separate observations: identical pixels
with different bytes pass with `re-encoded` in the receipt. A pixel mismatch
triggers up to three retries, five seconds apart, each with a fresh GraphQL
URL, before failing. Inspect a persistent mismatch with the owner.

The organization avatar check uses the same helper:

```sh
python3 <skill>/scripts/verify_upload.py avatar --organization <login> --image <accepted-avatar.png> --source-commit <merged-sha> --json <private-evidence/avatar.json>
```

It queries `organization { login avatarUrl(size: <local width>) }`. Since GitHub
can resize and re-encode avatars, the helper resizes the local image to the
served dimensions with bicubic resampling and compares both images composited
over white and over black. Both PSNR values must be at least 30 dB. The receipt
records both image sizes and digests and the two PSNR values; an exact match is
represented as `"infinity"` to keep the receipt valid JSON. `graphql_id` is null
for this query, which returns the organization login instead of an ID.

Both modes print a one-line summary: exit 0 is pass, 1 is mismatch, and 2 is
unknown evidence, including unavailable CLI login, API/network failure or an
undecodable image. `--source-commit` and `--json` are optional; supply both for
publication evidence. A receipt records the supplied source commit; the caller
is responsible for obtaining the image from that accepted revision.

HTTP 200, a settings screenshot or an uploaded filename alone does not prove
correct bytes. Served image URLs are omitted from all helper output. Private
repository visibility can limit unauthenticated image access; an unreadable
served image remains unknown with that scope stated. Use the authorized view
for follow-up without exposing private image URLs.
Keep receipts in the task's private evidence, out of public READMEs.
