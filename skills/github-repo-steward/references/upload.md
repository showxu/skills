# Social preview upload and verification

GitHub's supported upload route is the repository Settings page; there is no
supported repository social-preview upload API. Do not reverse engineer an
upload-token endpoint. Check the current
[GitHub upload instructions](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview)
when the UI changes. Prepare 1280×640 accepted PNGs within its current upload
limits. The accepted file must come from the merged source revision.

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

Query the exact repository with GraphQL through the existing GitHub CLI login:

```graphql
query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    id nameWithOwner openGraphImageUrl usesCustomOpenGraphImage
  }
}
```

Check the returned repository and custom-image flag, fetch that served image
URL, and record time, source revision, local/served SHA-256, byte lengths,
dimensions and decoded RGBA pixel comparison. Both images must be 1280×640.
Use Pillow to decode and compare dimensions and pixel bytes. Byte equality and
pixel equality are separate observations; if GitHub re-encodes an image,
record it explicitly and inspect the served result instead of claiming a byte
match. A stale cached image is pending: fetch the current GraphQL URL and retry
boundedly before asking the owner to inspect the save.

HTTP 200, a settings screenshot or an uploaded filename alone does not prove
correct bytes. Private repository visibility can limit a public check; report
that scope and use the authorized view without exposing private image URLs.
Keep receipts in the task's private evidence, out of public READMEs.
