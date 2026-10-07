#!/usr/bin/env node

import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import process from "node:process";
import readline from "node:readline";
import { pathToFileURL } from "node:url";

process.umask(0o077);

const workerLifecycle = createWorkerLifecycle();

const inputLines = readline.createInterface({
  input: process.stdin,
  crlfDelay: Infinity,
})[Symbol.asyncIterator]();

class WorkerFailure extends Error {
  constructor(code, message, data = null) {
    super(message);
    this.code = code;
    this.data = data;
  }
}

function fail(code, message, data = null) {
  process.stdout.write(
    `${JSON.stringify({ ok: false, data, error: { code, message } })}\n`
  );
  process.exitCode = 1;
}

async function main() {
  const input = await readInput();
  const playwright = await loadPlaywright();
  if (input.command === "doctor") {
    process.stdout.write(
      `${JSON.stringify({ ok: true, data: { playwrightAvailable: true } })}\n`
    );
    return;
  }
  if (input.command === "auth.restore") {
    await restoreSession(playwright, input);
    return;
  }
  if (input.command === "auth.profile-session") {
    await runProfileSession(playwright, input);
    return;
  }
  if (
    input.command !== "capture"
    && input.command !== "auth.bootstrap"
    && input.command !== "auth.inspect"
  ) {
    throw new WorkerFailure(
      "worker.unsupported_command",
      `Unsupported worker command: ${input.command}`
    );
  }

  const outputDirectory = requireString(
    input.outputDirectory,
    "outputDirectory"
  );
  const entryURL = requireString(input.url, "url");
  const browserName = input.browser ?? "chromium";
  const browserType = browserName === "chrome"
    ? playwright.chromium
    : playwright[browserName];
  if (!browserType) {
    throw new WorkerFailure(
      "worker.invalid_browser",
      `Unsupported browser: ${browserName}`
    );
  }
  const device = resolveDevice(playwright, input.device);
  const authSessionRequirements = resolveAuthSessionRequirements(input);
  if (
    input.autoCompleteOnAuthRequirements === true
    && (
      input.command !== "auth.bootstrap"
      || !authSessionRequirements.hasRequirements
    )
  ) {
    throw new WorkerFailure(
      "worker.invalid_auth_auto_completion",
      "Automatic auth completion requires auth.bootstrap with declared session requirements."
    );
  }
  const authResponseRequirement = resolveAuthResponseRequirement(input);
  const authRevisitTriggerResponseRequirement =
    resolveAuthRevisitTriggerResponseRequirement(input);
  const authCompletion = resolveAuthCompletion(
    input,
    authSessionRequirements.hasRequirements
      || authResponseRequirement.hasRequirement
  );
  const revisitEntryOnSessionChange =
    input.authRevisitEntryOnSessionChange === true;
  if (
    revisitEntryOnSessionChange
    && (
      input.command !== "auth.bootstrap"
      || input.autoCompleteOnAuthRequirements !== true
      || !authSessionRequirements.hasRequirements
      || !authResponseRequirement.hasRequirement
    )
  ) {
    throw new WorkerFailure(
      "worker.invalid_auth_session_change_revisit",
      "Session-change entry revisit requires automatic auth bootstrap with declared session and authenticated-response requirements."
    );
  }
  if (
    authRevisitTriggerResponseRequirement.hasRequirement
    && (
      input.command !== "auth.bootstrap"
      || input.autoCompleteOnAuthRequirements !== true
      || !authSessionRequirements.hasRequirements
      || !authResponseRequirement.hasRequirement
      || revisitEntryOnSessionChange
    )
  ) {
    throw new WorkerFailure(
      "worker.invalid_auth_response_revisit",
      "Response-triggered entry revisit requires automatic auth bootstrap with declared session and final authenticated-response requirements, and cannot be combined with session-change revisit."
    );
  }
  const candidateOnly = input.candidateOnly === true;
  const rejectedURL = resolveRejectedURL(input);
  const responseBodyURLMatchers = resolveResponseBodyURLMatchers(input);
  if (candidateOnly) {
    if (input.command !== "auth.inspect") {
      throw new WorkerFailure(
        "worker.invalid_candidate_inspection",
        "Candidate-only extraction is limited to auth.inspect."
      );
    }
    if (!authSessionRequirements.hasRequirements) {
      throw new WorkerFailure(
        "worker.invalid_candidate_inspection",
        "Candidate-only extraction requires declared session material."
      );
    }
    if (rejectedURL || authResponseRequirement.hasRequirement) {
      throw new WorkerFailure(
        "worker.invalid_candidate_inspection",
        "Candidate-only extraction cannot use navigation or authenticated-response gates."
      );
    }
  }
  const headless = input.command === "auth.inspect"
    ? input.headless !== false
    : input.headless === true;
  const authSnapshotScope = (
    (input.command === "auth.bootstrap" || input.command === "auth.inspect")
    && authSessionRequirements.domains.length > 0
  ) ? authSessionRequirements : null;
  const authHARFilter = authSnapshotScope === null
    ? null
    : sessionDomainURLFilter(authSnapshotScope.domains);

  await fs.mkdir(outputDirectory, { recursive: true, mode: 0o700 });
  await fs.chmod(outputDirectory, 0o700);
  const harPath = `${outputDirectory}/capture.har`;
  const rawPath = `${outputDirectory}/capture.json`;
  const contextOptions = {
    ...device.options,
    recordHar: {
      path: harPath,
      content: "embed",
      mode: "full",
      ...(authHARFilter === null ? {} : { urlFilter: authHARFilter }),
    },
  };
  const replaySeed = resolveReplaySeed(input);
  if (replaySeed !== null) {
    if (input.profileDirectory && input.command !== "auth.bootstrap") {
      throw new WorkerFailure(
        "worker.invalid_session_replay",
        "Only auth bootstrap may combine session replay with a persistent browser profile."
      );
    }
    if (!input.profileDirectory) {
      contextOptions.storageState = {
        cookies: replaySeed.cookies,
        origins: replaySeed.origins.map((originState) => ({
          origin: originState.origin,
          localStorage: Object.entries(originState.localStorage ?? {}).map(
            ([name, value]) => ({ name, value: String(value) })
          ),
        })),
      };
    }
  }

  let browser;
  let context;
  const exchanges = [];
  const interceptedResponseBodies = [];
  const pendingResponseCaptures = new Set();
  let capturedResponseBodyBytes = 0;
  let browserVersion = "unknown";
  let lastStorageState = { cookies: [], origins: [] };
  let lastWebStorages = [];
  let latestQualifyingAuthSnapshot = null;
  let eagerStorageState = null;
  let eagerWebStorages = null;
  let checkpointStopped = false;
  let checkpointTask = null;
  let closeBrowserResourcesTask = null;
  const persistPrivateCapture = async (snapshot) => {
    lastStorageState = snapshot.storageState;
    lastWebStorages = snapshot.webStorages;
    await writePrivateJSONAtomically(rawPath, {
      capturedAt: new Date().toISOString(),
      exchanges,
      sessionSeed: {
        storageState: lastStorageState,
        webStorage: lastWebStorages[0] ?? {
          origin: new URL(entryURL).origin,
          localStorage: {},
          sessionStorage: {},
        },
        webStorages: lastWebStorages,
      },
    });
  };
  const snapshotPrivateCapture = async (preserveEager = false) => {
    if (!context) {
      return;
    }
    let snapshot = await collectSessionSnapshot(context, authSnapshotScope);
    if (
      preserveEager
      && eagerStorageState !== null
      && eagerWebStorages !== null
    ) {
      snapshot = mergeSessionSnapshots(
        {
          storageState: eagerStorageState,
          webStorages: eagerWebStorages,
        },
        snapshot
      );
    }
    if (
      input.command === "auth.bootstrap"
      && authSessionRequirements.hasRequirements
    ) {
      const missing = missingAuthSessionRequirements(
        snapshot.storageState,
        snapshot.webStorages,
        authSessionRequirements
      );
      if (missing.length === 0) {
        latestQualifyingAuthSnapshot = snapshot;
      } else if (latestQualifyingAuthSnapshot !== null) {
        snapshot = latestQualifyingAuthSnapshot;
      }
    }
    await persistPrivateCapture(snapshot);
  };
  const stopCheckpointing = async () => {
    checkpointStopped = true;
    if (checkpointTask) {
      await checkpointTask;
      checkpointTask = null;
    }
  };
  const closeBrowserResources = async () => {
    if (closeBrowserResourcesTask !== null) {
      return closeBrowserResourcesTask;
    }
    closeBrowserResourcesTask = (async () => {
      await stopCheckpointing();
      const activeContext = context;
      context = undefined;
      if (activeContext) {
        await activeContext.close();
      }
      const activeBrowser = browser;
      browser = undefined;
      if (activeBrowser) {
        await activeBrowser.close();
      }
    })();
    return closeBrowserResourcesTask;
  };
  workerLifecycle.setCleanup(closeBrowserResources);
  try {
    if (input.profileDirectory) {
      const persistentOptions = {
        ...contextOptions,
        headless,
        ignoreDefaultArgs: ["--use-mock-keychain"],
        ...(browserName === "chrome"
          ? { channel: "chrome" }
          : { executablePath: browserType.executablePath() }),
      };
      if (
        input.command === "auth.inspect"
        && (browserName === "chromium" || browserName === "chrome")
      ) {
        persistentOptions.args = [
          "--restore-last-session",
          "--disable-session-crashed-bubble",
        ];
      }
      context = await browserType.launchPersistentContext(
        input.profileDirectory,
        persistentOptions
      );
      if (replaySeed !== null) {
        await context.addCookies(replaySeed.cookies);
      }
    } else {
      browser = await browserType.launch({
        headless,
        ...(browserName === "chrome" ? { channel: "chrome" } : {}),
      });
      context = await browser.newContext(contextOptions);
    }

    if (replaySeed !== null) {
      await context.addInitScript((origins) => {
        const state = origins[globalThis.location.origin];
        if (!state) return;
        for (const [key, value] of Object.entries(
          state.localStorage ?? {}
        )) {
          globalThis.localStorage.setItem(key, String(value));
        }
        for (const [key, value] of Object.entries(
          state.sessionStorage ?? {}
        )) {
          globalThis.sessionStorage.setItem(key, String(value));
        }
      }, Object.fromEntries(replaySeed.origins.map((originState) => [
        originState.origin,
        {
          localStorage: originState.localStorage ?? {},
          sessionStorage: originState.sessionStorage ?? {},
        },
      ])));
    }

    if (input.command === "auth.inspect") {
      const eagerSnapshot = await collectSessionSnapshot(
        context,
        authSnapshotScope
      );
      eagerStorageState = eagerSnapshot.storageState;
      eagerWebStorages = eagerSnapshot.webStorages;
      lastStorageState = eagerStorageState;
      lastWebStorages = eagerWebStorages;
      await snapshotPrivateCapture(true);
    }

    if (responseBodyURLMatchers.length > 0) {
      await context.route("**/*", async (route) => {
        const request = route.request();
        const method = request.method().toUpperCase();
        const url = request.url();
        if (
          (method !== "GET" && method !== "HEAD")
          || !responseBodyURLMatchers.some((matcher) => matcher.test(url))
        ) {
          await route.continue();
          return;
        }
        let response;
        try {
          response = await route.fetch();
        } catch {
          await route.continue();
          return;
        }
        try {
          const headers = response.headers();
          const body = await readBoundedAPIResponseBody(response, headers);
          if (
            body !== null
            && capturedResponseBodyBytes + body.length
              <= maximumTotalCapturedResponseBodyBytes
          ) {
            capturedResponseBodyBytes += body.length;
            interceptedResponseBodies.push({
              method,
              url,
              responseBodyBase64: body.toString("base64"),
            });
            await route.fulfill({ response, body });
          } else {
            await route.fulfill({ response });
          }
        } catch {
          await route.fulfill({ response });
        }
      });
    }

    const preexistingPages = new Set(context.pages());
    const flowPages = () =>
      context.pages().filter((candidate) => !preexistingPages.has(candidate));
    const instrumentedPages = new WeakSet();
    const instrumentPage = (candidate) => {
      if (instrumentedPages.has(candidate)) {
        return;
      }
      instrumentedPages.add(candidate);
      candidate.on("response", (response) => {
        const task = (async () => {
          if (
            authSnapshotScope !== null
            && !urlMatchesSessionDomains(
              response.url(),
              authSnapshotScope.domains
            )
          ) {
            return;
          }
          const request = response.request();
          const responseHeaders = await response.allHeaders();
          const exchange = {
            method: request.method(),
            url: response.url(),
            requestHeaders: await request.allHeaders(),
            requestBody: request.postData(),
            responseStatus: response.status(),
            responseHeaders,
          };
          exchanges.push(exchange);
          const responseBody = await readBoundedResponseBody(
            response,
            responseHeaders
          );
          if (responseBody !== null) {
            if (
              capturedResponseBodyBytes + responseBody.length
                <= maximumTotalCapturedResponseBodyBytes
            ) {
              capturedResponseBodyBytes += responseBody.length;
              exchange.responseBodyBase64 = responseBody.toString("base64");
            }
          }
          await observeAuthResponseRequirement(
            response,
            authResponseRequirement
          );
          await observeAuthResponseRequirement(
            response,
            authRevisitTriggerResponseRequirement
          );
        })();
        pendingResponseCaptures.add(task);
        task.finally(() => pendingResponseCaptures.delete(task));
      });
    };
    for (const candidate of context.pages()) {
      instrumentPage(candidate);
    }
    context.on("page", instrumentPage);

    if (!candidateOnly) {
      const page = await context.newPage();
      instrumentPage(page);
      await page.goto(entryURL, {
        // Discovery needs the committed document plus an explicit settling
        // window. It must not fail just because a storefront keeps the DOM
        // lifecycle open with long-running resources.
        waitUntil: input.command === "capture" ? "commit" : "domcontentloaded",
      });
      const initialAuthSessionFingerprint = revisitEntryOnSessionChange
        ? authSessionRequirementFingerprint(
          await collectSessionSnapshot(context, authSessionRequirements),
          authSessionRequirements
        )
        : null;
      if (input.command === "auth.bootstrap") {
        checkpointTask = (async () => {
          while (!checkpointStopped) {
            try {
              await snapshotPrivateCapture();
            } catch {
              // The final synchronous checkpoint reports durable failures.
            }
            await new Promise((resolve) => setTimeout(resolve, 250));
          }
        })();
      }

      if (
        input.command === "auth.bootstrap"
        && input.autoCompleteOnAuthRequirements === true
      ) {
        process.stderr.write(
          "Complete the browser flow; capture will continue automatically once the declared session material is available.\n"
        );
        let shouldRevisitEntry = false;
        if (authRevisitTriggerResponseRequirement.hasRequirement) {
          shouldRevisitEntry = await waitForAuthRevisitTriggerResponse(
            authRevisitTriggerResponseRequirement,
            authResponseRequirement,
            authCompletion.timeoutMs ?? 120000,
            flowPages
          );
        } else if (revisitEntryOnSessionChange) {
          const changedSnapshot =
            await waitForChangedAuthSessionRequirements(
              context,
              authSessionRequirements,
              initialAuthSessionFingerprint,
              authCompletion.timeoutMs ?? 120000,
              authResponseRequirement,
              flowPages
            );
          if (changedSnapshot !== null) {
            latestQualifyingAuthSnapshot = changedSnapshot;
            shouldRevisitEntry = true;
          }
        }
        if (shouldRevisitEntry) {
          const revisitPage = typeof page.isClosed === "function"
            && page.isClosed()
            ? await context.newPage()
            : page;
          instrumentPage(revisitPage);
          await revisitPage.goto(entryURL, { waitUntil: "domcontentloaded" });
        }
        if (authCompletion.regex) {
          await waitForCompletionURL(
            flowPages,
            authCompletion.regex,
            authCompletion.timeoutMs
          );
        }
        if (authResponseRequirement.hasRequirement) {
          await waitForAuthResponseRequirement(
            authResponseRequirement,
            authCompletion.timeoutMs ?? 120000,
            flowPages
          );
        }
      } else if (
        input.command === "auth.bootstrap"
        || input.waitForUser === true
      ) {
        process.stderr.write(
          "Complete the browser flow, then press Return here.\n"
        );
        await readLine({ required: true });
        if (
          input.command === "auth.bootstrap"
          && authResponseRequirement.hasRequirement
          && !authResponseRequirement.satisfied
        ) {
          const revisitPage = typeof page.isClosed === "function"
            && page.isClosed()
            ? await context.newPage()
            : page;
          instrumentPage(revisitPage);
          await revisitPage.goto(entryURL, { waitUntil: "domcontentloaded" });
        }
        if (authCompletion.regex) {
          await waitForCompletionURL(
            flowPages,
            authCompletion.regex,
            authCompletion.timeoutMs
          );
        }
        if (authResponseRequirement.hasRequirement) {
          await waitForAuthResponseRequirement(
            authResponseRequirement,
            authCompletion.timeoutMs ?? 120000,
            flowPages
          );
        }
      } else {
        await page.waitForTimeout(input.durationMs ?? 5000);
      }
      if (
        input.command === "auth.bootstrap"
        && Number.isFinite(input.durationMs)
        && input.durationMs > 0
      ) {
        // A successful navigation or business response can precede the
        // browser's final Cookie/storage commit. Settle inside the same
        // lifecycle, then refresh the qualifying snapshot before closing.
        await new Promise((resolve) => setTimeout(resolve, input.durationMs));
        await snapshotPrivateCapture();
      }
      if (rejectedURL && pagesHaveMatchingURL(flowPages(), rejectedURL)) {
        throw new WorkerFailure(
          "worker.session_requires_login",
          "The persisted browser session was redirected to a login surface."
        );
      }
    }

    const sessionSnapshot = candidateOnly
      ? requireAuthSessionSnapshot(
        {
          storageState: eagerStorageState,
          webStorages: eagerWebStorages,
        },
        authSessionRequirements
      )
      : authSessionRequirements.hasRequirements
        ? input.command === "auth.inspect"
          ? await inspectAuthSessionRequirements(
            context,
            authSessionRequirements
          )
          : latestQualifyingAuthSnapshot
            ?? await waitForAuthSessionRequirements(
              context,
              authSessionRequirements,
              authCompletion.timeoutMs ?? 120000,
              flowPages
            )
        : {
          ...await collectSessionSnapshot(context, authSnapshotScope),
        };
    if (
      input.command === "auth.inspect"
      && authResponseRequirement.hasRequirement
      && !authResponseRequirement.satisfied
    ) {
      throw new WorkerFailure(
        "worker.session_requires_login",
        "The persisted browser session did not produce the required authenticated response."
      );
    }
    const { storageState, webStorages } = sessionSnapshot;
    browserVersion = context.browser()?.version() ?? "unknown";
    await stopCheckpointing();
    await Promise.allSettled(Array.from(pendingResponseCaptures));
    // Preserve the exact snapshot that satisfied the auth requirements. A
    // second read can lose session-scoped material before the browser closes.
    await persistPrivateCapture(sessionSnapshot);

    await closeBrowserResources();
    await backfillHARResponseBodies(
      harPath,
      exchanges.concat(interceptedResponseBodies)
    );
    await hardenPrivateFile(rawPath);
    await hardenPrivateFile(harPath);
    process.stdout.write(
      `${JSON.stringify({
        ok: true,
        data: {
          rawCapturePath: rawPath,
          rawHARPath: harPath,
          exchangeCount: exchanges.length,
          cookieCount: storageState.cookies.length,
          browser: browserName,
          browserVersion,
          device: device.name,
          storageOriginCount: webStorages.length,
        },
      })}\n`
    );
  } catch (error) {
    await stopCheckpointing();
    try {
      await snapshotPrivateCapture(input.command === "auth.inspect");
    } catch {
      // Keep the original browser/auth failure when checkpointing also fails.
    }
    if (
      error instanceof WorkerFailure
      && context
      && await fileExists(rawPath)
    ) {
      error.data = {
        rawCapturePath: rawPath,
        rawHARPath: harPath,
        exchangeCount: exchanges.length,
        cookieCount: lastStorageState.cookies.length,
        browser: browserName,
        browserVersion,
        device: device.name,
        storageOriginCount: lastWebStorages.length,
      };
    }
    throw error;
  } finally {
    await closeBrowserResources();
    workerLifecycle.clearCleanup(closeBrowserResources);
    await hardenPrivateFile(rawPath);
    await hardenPrivateFile(harPath);
  }
}

async function runProfileSession(playwright, input) {
  const profileDirectory = requireString(
    input.profileDirectory,
    "profileDirectory"
  );
  const urls = requireHTTPURLs(input.urls);
  const browserName = input.browser ?? "chromium";
  const browserType = browserName === "chrome"
    ? playwright.chromium
    : playwright[browserName];
  if (!browserType) {
    throw new WorkerFailure(
      "worker.invalid_browser",
      `Unsupported browser: ${browserName}`
    );
  }
  await fs.mkdir(profileDirectory, { recursive: true, mode: 0o700 });
  await fs.chmod(profileDirectory, 0o700);
  const persistentOptions = (headless) => ({
    headless,
    ignoreDefaultArgs: ["--use-mock-keychain"],
    args: ["--restore-last-session", "--disable-session-crashed-bubble"],
    ...(browserName === "chrome"
      ? { channel: "chrome" }
      : { executablePath: browserType.executablePath() }),
  });

  let context;
  try {
    context = await browserType.launchPersistentContext(
      profileDirectory,
      persistentOptions(true)
    );
    for (const url of urls) {
      const page = await context.newPage();
      await page.goto(url, { waitUntil: "domcontentloaded" });
    }
    await Promise.all(
      context.pages().map((page) => page.waitForTimeout(1000))
    );
    const preClose = await collectSessionSnapshot(context, null);
    const sessionScopedCookieCount = preClose.storageState.cookies.filter(
      (cookie) => !Number.isFinite(cookie.expires) || cookie.expires <= 0
    ).length;
    const sessionStorageOriginCount = preClose.webStorages.filter(
      (storage) => Object.keys(storage.sessionStorage ?? {}).length > 0
    ).length;
    await context.close();
    context = undefined;

    context = await browserType.launchPersistentContext(
      profileDirectory,
      persistentOptions(true)
    );
    const persisted = await context.storageState();
    const browserVersion = context.browser()?.version() ?? "unknown";
    const persistedCookieIdentities = new Set(
      persisted.cookies.map(cookieIdentity)
    );
    const lostCookieCount = preClose.storageState.cookies.filter(
      (cookie) => !persistedCookieIdentities.has(cookieIdentity(cookie))
    ).length;
    await context.close();
    context = undefined;
    process.stdout.write(
      `${JSON.stringify({
        ok: true,
        data: {
          browser: browserName,
          browserVersion,
          openedURLCount: urls.length,
          preCloseCookieCount: preClose.storageState.cookies.length,
          preCloseOriginCount: preClose.webStorages.length,
          sessionScopedCookieCount,
          sessionStorageOriginCount,
          persistedCookieCount: persisted.cookies.length,
          persistedOriginCount: persisted.origins.length,
          lostCookieCount,
          providerSessionValidated: false,
          requiresProviderHandoffBeforeClose:
            sessionScopedCookieCount > 0 || sessionStorageOriginCount > 0,
        },
      })}\n`
    );
  } finally {
    if (context) {
      await context.close();
    }
  }
}

function cookieIdentity(cookie) {
  return `${cookie.domain}\u0000${cookie.path}\u0000${cookie.name}`;
}

function requireHTTPURLs(rawValues) {
  if (!Array.isArray(rawValues) || rawValues.length === 0) {
    throw new WorkerFailure(
      "worker.invalid_profile_session_urls",
      "Profile session requires at least one URL."
    );
  }
  return rawValues.map((rawValue) => {
    const value = requireString(rawValue, "url");
    let parsed;
    try {
      parsed = new URL(value);
    } catch {
      throw new WorkerFailure(
        "worker.invalid_profile_session_url",
        "Profile session URLs must be absolute HTTP(S) URLs."
      );
    }
    if (!["http:", "https:"].includes(parsed.protocol)) {
      throw new WorkerFailure(
        "worker.invalid_profile_session_url",
        "Profile session URLs must be absolute HTTP(S) URLs."
      );
    }
    return parsed.href;
  });
}

async function restoreSession(playwright, input) {
  const profileDirectory = requireString(
    input.profileDirectory,
    "profileDirectory"
  );
  const seed = input.restoreSeed;
  if (!seed || !Array.isArray(seed.cookies) || !Array.isArray(seed.origins)) {
    throw new WorkerFailure(
      "worker.invalid_session_seed",
      "restoreSeed must contain cookies and origins."
    );
  }
  const browserName = input.browser ?? "chromium";
  const browserType = browserName === "chrome"
    ? playwright.chromium
    : playwright[browserName];
  if (!browserType) {
    throw new WorkerFailure(
      "worker.invalid_browser",
      `Unsupported browser: ${browserName}`
    );
  }
  const launchOptions = {
    headless: true,
    ignoreDefaultArgs: ["--use-mock-keychain"],
    ...(browserName === "chrome"
      ? { channel: "chrome" }
      : { executablePath: browserType.executablePath() }),
  };

  let context;
  try {
    context = await browserType.launchPersistentContext(
      profileDirectory,
      launchOptions
    );
    await context.addCookies(seed.cookies);
    for (const originState of seed.origins) {
      const origin = requireHTTPOrigin(originState.origin);
      const page = await context.newPage();
      await page.goto(origin, { waitUntil: "domcontentloaded" });
      await page.evaluate((values) => {
        for (const [key, value] of Object.entries(values)) {
          localStorage.setItem(key, String(value));
        }
      }, originState.localStorage ?? {});
      await page.close();
    }
    await context.close();
    context = undefined;

    context = await browserType.launchPersistentContext(
      profileDirectory,
      launchOptions
    );
    const restoredCookies = await context.cookies();
    for (const expected of seed.cookies) {
      const restored = restoredCookies.find((candidate) =>
        candidate.name === expected.name
        && candidate.domain === expected.domain
        && candidate.path === expected.path
      );
      if (!restored || restored.value !== expected.value) {
        throw new WorkerFailure(
          "worker.session_restore_verification_failed",
          "A restored cookie did not survive browser restart."
        );
      }
    }
    for (const originState of seed.origins) {
      const origin = requireHTTPOrigin(originState.origin);
      const page = await context.newPage();
      await page.goto(origin, { waitUntil: "domcontentloaded" });
      const restored = await page.evaluate((keys) =>
        Object.fromEntries(keys.map((key) => [key, localStorage.getItem(key)])),
      Object.keys(originState.localStorage ?? {}));
      await page.close();
      for (const [key, value] of Object.entries(
        originState.localStorage ?? {}
      )) {
        if (restored[key] !== value) {
          throw new WorkerFailure(
            "worker.session_restore_verification_failed",
            "Restored local storage did not survive browser restart."
          );
        }
      }
    }
    await context.close();
    context = undefined;
    process.stdout.write(
      `${JSON.stringify({
        ok: true,
        data: {
          restoredCookieCount: seed.cookies.length,
          restoredOriginCount: seed.origins.length,
          browser: browserName,
        },
      })}\n`
    );
  } finally {
    if (context) {
      await context.close();
    }
  }
}

function resolveReplaySeed(input) {
  if (input.replaySeed === undefined || input.replaySeed === null) {
    return null;
  }
  if (input.command !== "capture" && input.command !== "auth.bootstrap") {
    throw new WorkerFailure(
      "worker.invalid_session_replay",
      "Session replay is supported by capture and auth bootstrap only."
    );
  }
  const seed = input.replaySeed;
  if (!Array.isArray(seed.cookies) || !Array.isArray(seed.origins)) {
    throw new WorkerFailure(
      "worker.invalid_session_seed",
      "replaySeed must contain cookies and origins."
    );
  }
  return seed;
}

function requireHTTPOrigin(value) {
  const raw = requireString(value, "origin");
  let parsed;
  try {
    parsed = new URL(raw);
  } catch {
    throw new WorkerFailure(
      "worker.invalid_session_origin",
      "Session origin must be an absolute HTTP(S) URL."
    );
  }
  if (
    !["http:", "https:"].includes(parsed.protocol)
    || parsed.origin !== raw.replace(/\/$/, "")
  ) {
    throw new WorkerFailure(
      "worker.invalid_session_origin",
      "Session origin must be an HTTP(S) origin without a path."
    );
  }
  return parsed.origin;
}

function resolveDevice(playwright, rawDevice) {
  if (rawDevice === undefined || rawDevice === null) {
    return { name: null, options: {} };
  }
  const name = requireString(rawDevice, "device");
  const descriptor = playwright.devices?.[name];
  if (!descriptor) {
    throw new WorkerFailure(
      "worker.invalid_device",
      `Unknown Playwright device: ${name}`
    );
  }
  const { defaultBrowserType: _ignored, ...options } = descriptor;
  return { name, options };
}

function resolveAuthCompletion(input, hasOtherRequirement) {
  const rawPattern = input.authCompletionURLRegex;
  const rawTimeout = input.authTimeoutMs;
  if (rawPattern === undefined || rawPattern === null) {
    if (rawTimeout !== undefined && rawTimeout !== null) {
      if (!hasOtherRequirement) {
        throw new WorkerFailure(
          "worker.invalid_auth_timeout",
          "authTimeoutMs requires an auth completion URL, session requirement, or authenticated response requirement."
        );
      }
      if (!Number.isSafeInteger(rawTimeout) || rawTimeout <= 0) {
        throw new WorkerFailure(
          "worker.invalid_auth_timeout",
          "authTimeoutMs must be a positive integer."
        );
      }
      return { regex: null, timeoutMs: rawTimeout };
    }
    return { regex: null, timeoutMs: null };
  }
  if (input.command !== "auth.bootstrap") {
    throw new WorkerFailure(
      "worker.invalid_auth_completion",
      "Auth completion matching is limited to auth.bootstrap."
    );
  }
  const pattern = requireString(
    rawPattern,
    "authCompletionURLRegex"
  );
  let regex;
  try {
    regex = new RegExp(pattern);
  } catch {
    throw new WorkerFailure(
      "worker.invalid_auth_completion_regex",
      `Invalid auth completion URL regex: ${pattern}`
    );
  }
  const timeoutMs = rawTimeout ?? 120000;
  if (!Number.isSafeInteger(timeoutMs) || timeoutMs <= 0) {
    throw new WorkerFailure(
      "worker.invalid_auth_timeout",
      "authTimeoutMs must be a positive integer."
    );
  }
  return { regex, timeoutMs };
}

function resolveAuthSessionRequirements(input) {
  const cookieNames = normalizedRequirementNames(
    input.authRequiredCookieNames,
    "authRequiredCookieNames"
  );
  const localStorageKeys = normalizedRequirementNames(
    input.authRequiredLocalStorageKeys,
    "authRequiredLocalStorageKeys"
  );
  const sessionStorageKeys = normalizedRequirementNames(
    input.authRequiredSessionStorageKeys,
    "authRequiredSessionStorageKeys"
  );
  const hasRequirements = (
    cookieNames.length > 0
    || localStorageKeys.length > 0
    || sessionStorageKeys.length > 0
  );
  if (
    hasRequirements
    && input.command !== "auth.bootstrap"
    && input.command !== "auth.inspect"
  ) {
    throw new WorkerFailure(
      "worker.invalid_auth_session_requirements",
      "Auth session requirements are limited to auth.bootstrap and auth.inspect."
    );
  }
  const domains = normalizedSessionDomains(input.sessionDomains);
  if (hasRequirements && domains.length === 0) {
    throw new WorkerFailure(
      "worker.invalid_auth_session_requirements",
      "Auth session requirements need at least one session domain."
    );
  }
  return {
    cookieNames,
    localStorageKeys,
    sessionStorageKeys,
    domains,
    hasRequirements,
  };
}

function resolveAuthResponseRequirement(input) {
  const rawURLPattern = input.authRequiredResponseURLRegex;
  const rawBodyPattern = input.authRequiredResponseBodyRegex;
  const hasURLPattern = rawURLPattern !== undefined && rawURLPattern !== null;
  const hasBodyPattern = rawBodyPattern !== undefined && rawBodyPattern !== null;
  if (hasURLPattern !== hasBodyPattern) {
    throw new WorkerFailure(
      "worker.invalid_auth_response_requirement",
      "Auth response completion requires both URL and body regexes."
    );
  }
  if (!hasURLPattern) {
    return {
      hasRequirement: false,
      urlRegex: null,
      bodyRegex: null,
      satisfied: false,
    };
  }
  if (
    input.command !== "auth.bootstrap"
    && input.command !== "auth.inspect"
  ) {
    throw new WorkerFailure(
      "worker.invalid_auth_response_requirement",
      "Auth response completion is limited to auth.bootstrap and auth.inspect."
    );
  }
  return {
    hasRequirement: true,
    urlRegex: compileRegex(
      rawURLPattern,
      "authRequiredResponseURLRegex",
      "worker.invalid_auth_response_regex"
    ),
    bodyRegex: compileRegex(
      rawBodyPattern,
      "authRequiredResponseBodyRegex",
      "worker.invalid_auth_response_regex"
    ),
    satisfied: false,
  };
}

function resolveAuthRevisitTriggerResponseRequirement(input) {
  const rawURLPattern = input.authRevisitTriggerResponseURLRegex;
  const rawBodyPattern = input.authRevisitTriggerResponseBodyRegex;
  const hasURLPattern = rawURLPattern !== undefined && rawURLPattern !== null;
  const hasBodyPattern = rawBodyPattern !== undefined && rawBodyPattern !== null;
  if (hasURLPattern !== hasBodyPattern) {
    throw new WorkerFailure(
      "worker.invalid_auth_response_revisit",
      "Auth revisit trigger requires both URL and body regexes."
    );
  }
  if (!hasURLPattern) {
    return {
      hasRequirement: false,
      urlRegex: null,
      bodyRegex: null,
      satisfied: false,
    };
  }
  return {
    hasRequirement: true,
    urlRegex: compileRegex(
      rawURLPattern,
      "authRevisitTriggerResponseURLRegex",
      "worker.invalid_auth_response_revisit"
    ),
    bodyRegex: compileRegex(
      rawBodyPattern,
      "authRevisitTriggerResponseBodyRegex",
      "worker.invalid_auth_response_revisit"
    ),
    satisfied: false,
  };
}

function compileRegex(rawPattern, field, code) {
  const pattern = requireString(rawPattern, field);
  try {
    return new RegExp(pattern);
  } catch {
    throw new WorkerFailure(code, `Invalid ${field} regex.`);
  }
}

function normalizedRequirementNames(rawValues, field) {
  if (rawValues === undefined || rawValues === null) {
    return [];
  }
  if (!Array.isArray(rawValues)) {
    throw new WorkerFailure(
      "worker.invalid_auth_session_requirements",
      `${field} must be an array.`
    );
  }
  const values = rawValues.map((value) => requireString(value, field));
  return Array.from(new Set(values)).sort();
}

function normalizedSessionDomains(rawValues) {
  if (rawValues === undefined || rawValues === null) {
    return [];
  }
  if (!Array.isArray(rawValues)) {
    throw new WorkerFailure(
      "worker.invalid_session_domain",
      "sessionDomains must be an array."
    );
  }
  const domains = rawValues.map((value) => {
    const domain = requireString(value, "sessionDomains")
      .trim()
      .replace(/^\.+|\.+$/g, "")
      .toLowerCase();
    if (
      domain.length === 0
      || domain.includes("..")
      || !/^[a-z0-9.-]+$/.test(domain)
    ) {
      throw new WorkerFailure(
        "worker.invalid_session_domain",
        `Invalid session domain: ${value}`
      );
    }
    return domain;
  });
  return Array.from(new Set(domains)).sort();
}

function resolveRejectedURL(input) {
  const rawPattern = input.rejectURLRegex;
  if (rawPattern === undefined || rawPattern === null) {
    return null;
  }
  if (input.command !== "auth.inspect") {
    throw new WorkerFailure(
      "worker.invalid_reject_url",
      "rejectURLRegex is limited to auth.inspect."
    );
  }
  const pattern = requireString(rawPattern, "rejectURLRegex");
  try {
    return new RegExp(pattern);
  } catch {
    throw new WorkerFailure(
      "worker.invalid_reject_url_regex",
      `Invalid rejected URL regex: ${pattern}`
    );
  }
}

function pagesHaveMatchingURL(pages, regex) {
  for (const page of pages) {
    if (regex.test(page.url())) {
      return true;
    }
    for (const frame of page.frames()) {
      if (regex.test(frame.url())) {
        return true;
      }
    }
  }
  return false;
}

async function waitForCompletionURL(flowPages, regex, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() <= deadline) {
    const pages = requireOpenAuthFlow(flowPages);
    if (pages.some((page) => regex.test(page.url()))) {
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new WorkerFailure(
    "worker.auth_timeout",
    `Auth completion URL did not match within ${timeoutMs} ms.`
  );
}

async function waitForAuthSessionRequirements(
  context,
  requirements,
  timeoutMs,
  flowPages
) {
  const deadline = Date.now() + timeoutMs;
  let missing = [];
  while (Date.now() <= deadline) {
    const { storageState, webStorages } = await collectSessionSnapshot(
      context,
      requirements
    );
    missing = missingAuthSessionRequirements(
      storageState,
      webStorages,
      requirements
    );
    if (missing.length === 0) {
      return { storageState, webStorages };
    }
    requireOpenAuthFlow(flowPages);
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new WorkerFailure(
    "worker.auth_session_requirements_timeout",
    `Auth session material was incomplete after ${timeoutMs} ms: ${missing.join(", ")}.`
  );
}

async function waitForChangedAuthSessionRequirements(
  context,
  requirements,
  initialFingerprint,
  timeoutMs,
  responseRequirement = null,
  flowPages
) {
  const deadline = Date.now() + timeoutMs;
  let missing = [];
  while (Date.now() <= deadline) {
    if (responseRequirement?.satisfied === true) {
      return null;
    }
    const snapshot = await collectSessionSnapshot(context, requirements);
    missing = missingAuthSessionRequirements(
      snapshot.storageState,
      snapshot.webStorages,
      requirements
    );
    if (
      missing.length === 0
      && authSessionRequirementFingerprint(snapshot, requirements)
        !== initialFingerprint
    ) {
      return snapshot;
    }
    requireOpenAuthFlow(flowPages);
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new WorkerFailure(
    "worker.auth_session_change_timeout",
    "Required auth session material did not become complete and change "
      + `within ${timeoutMs} ms${missing.length > 0 ? `: ${missing.join(", ")}` : "."}`
  );
}

function authSessionRequirementFingerprint(snapshot, requirements) {
  const cookies = snapshot.storageState.cookies
    .filter((cookie) =>
      requirements.cookieNames.includes(cookie.name)
      && requirements.domains.some((domain) =>
        domainContains(cookie.domain, domain)
      )
      && usableSessionValue(cookie.value)
    )
    .map((cookie) => ({
      domain: String(cookie.domain ?? "").toLowerCase(),
      name: cookie.name,
      path: cookie.path ?? "/",
      value: cookie.value,
    }))
    .sort((lhs, rhs) => JSON.stringify(lhs).localeCompare(JSON.stringify(rhs)));
  const storage = snapshot.webStorages
    .flatMap((originState) => {
      let hostname;
      try {
        hostname = new URL(originState.origin).hostname;
      } catch {
        return [];
      }
      if (!requirements.domains.some((domain) =>
        domainContains(hostname, domain)
      )) {
        return [];
      }
      return [
        ...requirements.localStorageKeys
          .filter((key) => usableSessionValue(originState.localStorage?.[key]))
          .map((key) => ({
            key,
            origin: originState.origin,
            type: "localStorage",
            value: originState.localStorage[key],
          })),
        ...requirements.sessionStorageKeys
          .filter((key) =>
            usableSessionValue(originState.sessionStorage?.[key])
          )
          .map((key) => ({
            key,
            origin: originState.origin,
            type: "sessionStorage",
            value: originState.sessionStorage[key],
          })),
      ];
    })
    .sort((lhs, rhs) => JSON.stringify(lhs).localeCompare(JSON.stringify(rhs)));
  return JSON.stringify({ cookies, storage });
}

async function observeAuthResponseRequirement(response, requirement) {
  if (
    !requirement.hasRequirement
    || requirement.satisfied
    || !matches(requirement.urlRegex, response.url())
    || response.status() < 200
    || response.status() >= 300
  ) {
    return;
  }
  try {
    const body = await response.text();
    if (
      body.length <= 1024 * 1024
      && matches(requirement.bodyRegex, body)
    ) {
      requirement.satisfied = true;
    }
  } catch {
    // A response whose body cannot be read is not authentication evidence.
  }
}

async function waitForAuthResponseRequirement(
  requirement,
  timeoutMs,
  flowPages
) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() <= deadline) {
    if (requirement.satisfied) {
      return;
    }
    requireOpenAuthFlow(flowPages);
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new WorkerFailure(
    "worker.auth_response_requirement_timeout",
    `Required authenticated business response was not observed within ${timeoutMs} ms.`
  );
}

async function waitForAuthRevisitTriggerResponse(
  triggerRequirement,
  finalRequirement,
  timeoutMs,
  flowPages
) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() <= deadline) {
    if (finalRequirement.satisfied) {
      return false;
    }
    if (triggerRequirement.satisfied) {
      return true;
    }
    requireOpenAuthFlow(flowPages);
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new WorkerFailure(
    "worker.auth_revisit_trigger_timeout",
    `Neither the final authenticated response nor the entry-revisit trigger was observed within ${timeoutMs} ms.`
  );
}

function requireOpenAuthFlow(flowPages) {
  const pages = flowPages().filter((page) =>
    typeof page.isClosed !== "function" || !page.isClosed()
  );
  if (pages.length === 0) {
    throw new WorkerFailure(
      "worker.auth_flow_closed",
      "The interactive authentication window was closed before the declared auth requirements completed."
    );
  }
  return pages;
}

function matches(regex, value) {
  regex.lastIndex = 0;
  return regex.test(value);
}

async function inspectAuthSessionRequirements(context, requirements) {
  const { storageState, webStorages } = await collectSessionSnapshot(
    context,
    requirements
  );
  return requireAuthSessionSnapshot(
    { storageState, webStorages },
    requirements
  );
}

function requireAuthSessionSnapshot(snapshot, requirements) {
  const { storageState, webStorages } = snapshot;
  const missing = missingAuthSessionRequirements(
    storageState,
    webStorages,
    requirements
  );
  if (missing.length > 0) {
    throw new WorkerFailure(
      "worker.auth_session_requirements_missing",
      `The persisted browser session is missing required material: ${missing.join(", ")}.`
    );
  }
  return { storageState, webStorages };
}

function missingAuthSessionRequirements(
  storageState,
  webStorages,
  requirements
) {
  const scopedCookies = storageState.cookies.filter((cookie) =>
    requirements.domains.some((domain) =>
      domainContains(cookie.domain, domain)
    )
  );
  const scopedStorages = webStorages.filter((storage) => {
    try {
      return requirements.domains.some((domain) =>
        domainContains(new URL(storage.origin).hostname, domain)
      );
    } catch {
      return false;
    }
  });
  const missing = [];
  for (const name of requirements.cookieNames) {
    if (
      !scopedCookies.some((cookie) =>
        cookie.name === name && usableSessionValue(cookie.value)
      )
    ) {
      missing.push(`cookie:${name}`);
    }
  }
  for (const key of requirements.localStorageKeys) {
    if (
      !scopedStorages.some((storage) =>
        usableSessionValue(storage.localStorage?.[key])
      )
    ) {
      missing.push(`localStorage:${key}`);
    }
  }
  for (const key of requirements.sessionStorageKeys) {
    if (
      !scopedStorages.some((storage) =>
        usableSessionValue(storage.sessionStorage?.[key])
      )
    ) {
      missing.push(`sessionStorage:${key}`);
    }
  }
  return missing;
}

function domainContains(rawHost, domain) {
  const host = String(rawHost ?? "")
    .replace(/^\.+|\.+$/g, "")
    .toLowerCase();
  return host === domain || host.endsWith(`.${domain}`);
}

function urlMatchesSessionDomains(rawURL, domains) {
  try {
    const url = new URL(rawURL);
    return (
      (url.protocol === "http:" || url.protocol === "https:")
      && domains.some((domain) => domainContains(url.hostname, domain))
    );
  } catch {
    return false;
  }
}

function sessionDomainURLFilter(domains) {
  const escaped = domains.map((domain) =>
    domain.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
  );
  return new RegExp(
    `^https?://(?:[^/?#]+\\.)*(?:${escaped.join("|")})`
      + "(?::[0-9]+)?(?:[/?#]|$)",
    "i"
  );
}

function usableSessionValue(value) {
  if (typeof value !== "string") {
    return false;
  }
  const normalized = value.trim().toLowerCase();
  return (
    normalized.length > 0
    && !["false", "nil", "null", "undefined", "(null)"].includes(normalized)
  );
}

async function collectWebStorages(context) {
  return collectWebStoragesInScope(context, null);
}

async function collectSessionSnapshot(context, scope) {
  if (!scope) {
    return {
      storageState: await context.storageState(),
      webStorages: await collectWebStorages(context),
    };
  }
  const cookies = (await context.cookies()).filter((cookie) =>
    scope.domains.some((domain) => domainContains(cookie.domain, domain))
  );
  const webStorages = await collectWebStoragesInScope(context, scope);
  return {
    storageState: {
      cookies,
      origins: webStorages.map((storage) => ({
        origin: storage.origin,
        localStorage: Object.entries(storage.localStorage).map(
          ([name, value]) => ({ name, value })
        ),
      })),
    },
    webStorages,
  };
}

async function collectWebStoragesInScope(context, scope) {
  if (
    scope !== null
    && scope.localStorageKeys.length === 0
    && scope.sessionStorageKeys.length === 0
  ) {
    return [];
  }
  const snapshots = [];
  const pages = context.pages();
  for (let pageIndex = 0; pageIndex < pages.length; pageIndex += 1) {
    const page = pages[pageIndex];
    const frames = page.frames();
    for (let frameIndex = 0; frameIndex < frames.length; frameIndex += 1) {
      const frame = frames[frameIndex];
      const frameURL = frame.url();
      if (
        scope !== null
        && /^https?:\/\//i.test(frameURL)
        && !urlMatchesSessionDomains(frameURL, scope.domains)
      ) {
        continue;
      }
      try {
        const storage = await frame.evaluate((selection) => {
          const selectedEntries = (store, keys) => Object.fromEntries(
            keys === null
              ? Array.from({ length: store.length }, (_, index) => {
                  const key = store.key(index);
                  return key === null ? null : [key, store.getItem(key)];
                }).filter(Boolean)
              : keys.map((key) => [key, store.getItem(key)])
          );
          return {
            origin: location.origin,
            localStorage: selectedEntries(
              localStorage,
              selection?.localStorageKeys ?? null
            ),
            sessionStorage: selectedEntries(
              sessionStorage,
              selection?.sessionStorageKeys ?? null
            ),
          };
        }, scope === null ? null : {
          localStorageKeys: scope.localStorageKeys,
          sessionStorageKeys: scope.sessionStorageKeys,
        });
        if (
          scope !== null
          && !scope.domains.some((domain) => {
            try {
              return domainContains(new URL(storage.origin).hostname, domain);
            } catch {
              return false;
            }
          })
        ) {
          continue;
        }
        if (scope !== null) {
          storage.localStorage = selectStorageKeys(
            storage.localStorage,
            scope.localStorageKeys
          );
          storage.sessionStorage = selectStorageKeys(
            storage.sessionStorage,
            scope.sessionStorageKeys
          );
        }
        if (storage.origin && storage.origin !== "null") {
          snapshots.push({
            ...storage,
            pageURL: page.url(),
            frameURL: frame.url(),
            pageIndex,
            frameIndex,
          });
        }
      } catch {
        if (/^https?:\/\//i.test(frameURL)) {
          throw new WorkerFailure(
            "worker.storage_capture_failed",
            "Web storage could not be captured for an open HTTP(S) frame."
          );
        }
        // Detached or browser-internal frames have no stable web storage.
      }
    }
  }
  snapshots.sort((left, right) => {
    const leftKey = [
      left.origin,
      left.pageURL,
      left.frameURL,
      left.pageIndex,
      left.frameIndex,
    ];
    const rightKey = [
      right.origin,
      right.pageURL,
      right.frameURL,
      right.pageIndex,
      right.frameIndex,
    ];
    return JSON.stringify(leftKey).localeCompare(JSON.stringify(rightKey));
  });

  const byOrigin = new Map();
  for (const snapshot of snapshots) {
    const existing = byOrigin.get(snapshot.origin) ?? {
      origin: snapshot.origin,
      localStorage: {},
      sessionStorage: {},
    };
    existing.localStorage = mergeSorted(
      existing.localStorage,
      snapshot.localStorage
    );
    existing.sessionStorage = mergeSorted(
      existing.sessionStorage,
      snapshot.sessionStorage
    );
    byOrigin.set(snapshot.origin, existing);
  }
  return Array.from(byOrigin.values()).sort((left, right) =>
    left.origin.localeCompare(right.origin)
  );
}

function selectStorageKeys(storage, keys) {
  return Object.fromEntries(
    keys.map((key) => [key, storage?.[key] ?? null])
      .filter(([, value]) => value !== null)
  );
}

function mergeSorted(existing, incoming) {
  return Object.fromEntries(
    Object.entries({ ...existing, ...incoming }).sort(([left], [right]) =>
      left.localeCompare(right)
    )
  );
}

function mergeSessionSnapshots(eager, current) {
  const cookiesByIdentity = new Map();
  for (const cookie of [
    ...(eager.storageState.cookies ?? []),
    ...(current.storageState.cookies ?? []),
  ]) {
    const identity = JSON.stringify([
      cookie.domain,
      cookie.path,
      cookie.name,
    ]);
    const existing = cookiesByIdentity.get(identity);
    if (!existing || usableSessionValue(cookie.value)) {
      cookiesByIdentity.set(identity, cookie);
    }
  }
  const cookies = Array.from(cookiesByIdentity.values()).sort((left, right) =>
    JSON.stringify([left.domain, left.path, left.name]).localeCompare(
      JSON.stringify([right.domain, right.path, right.name])
    )
  );

  const webStoragesByOrigin = new Map();
  for (const storage of [
    ...(eager.webStorages ?? []),
    ...(current.webStorages ?? []),
  ]) {
    const existing = webStoragesByOrigin.get(storage.origin) ?? {
      origin: storage.origin,
      localStorage: {},
      sessionStorage: {},
    };
    existing.localStorage = mergeSorted(
      existing.localStorage,
      storage.localStorage ?? {}
    );
    existing.sessionStorage = mergeSorted(
      existing.sessionStorage,
      storage.sessionStorage ?? {}
    );
    webStoragesByOrigin.set(storage.origin, existing);
  }
  const webStorages = Array.from(webStoragesByOrigin.values()).sort(
    (left, right) => left.origin.localeCompare(right.origin)
  );
  return {
    storageState: {
      cookies,
      origins: webStorages.map((storage) => ({
        origin: storage.origin,
        localStorage: Object.entries(storage.localStorage).map(
          ([name, value]) => ({ name, value })
        ),
      })),
    },
    webStorages,
  };
}

async function hardenPrivateFile(filePath) {
  try {
    await fs.chmod(filePath, 0o600);
  } catch (error) {
    if (error?.code !== "ENOENT") {
      throw error;
    }
  }
}

const maximumCapturedResponseBodyBytes = 4 * 1024 * 1024;
const maximumTotalCapturedResponseBodyBytes = 32 * 1024 * 1024;
const responseBodyCaptureTimeoutMs = 5000;

async function readBoundedResponseBody(response, headers) {
  const contentType = String(headers["content-type"] ?? "").toLowerCase();
  if (!isTextualContentType(contentType)) {
    return null;
  }
  const contentLength = Number.parseInt(headers["content-length"] ?? "", 10);
  if (
    Number.isFinite(contentLength)
    && contentLength > maximumCapturedResponseBodyBytes
  ) {
    return null;
  }
  let timeout;
  try {
    const body = await Promise.race([
      response.body(),
      new Promise((_, reject) => {
        timeout = setTimeout(
          () => reject(new Error("response body capture timed out")),
          responseBodyCaptureTimeoutMs
        );
      }),
    ]);
    return body.length <= maximumCapturedResponseBodyBytes ? body : null;
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

async function readBoundedAPIResponseBody(response, headers) {
  const contentType = String(headers["content-type"] ?? "").toLowerCase();
  const contentLength = Number.parseInt(headers["content-length"] ?? "", 10);
  if (
    !isTextualContentType(contentType)
    || (
      Number.isFinite(contentLength)
      && contentLength > maximumCapturedResponseBodyBytes
    )
  ) {
    return null;
  }
  const body = await response.body();
  return body.length <= maximumCapturedResponseBodyBytes ? body : null;
}

function isTextualContentType(value) {
  return (
    value.startsWith("text/")
    || value.includes("json")
    || value.includes("javascript")
    || value.includes("graphql")
    || value.includes("xml")
    || value.includes("x-www-form-urlencoded")
  );
}

function resolveResponseBodyURLMatchers(input) {
  const values = input.responseBodyURLRegexes ?? [];
  if (!Array.isArray(values)) {
    throw new WorkerFailure(
      "worker.invalid_response_body_url_regex",
      "Response-body URL regexes must be an array."
    );
  }
  if (values.length > 0 && input.command !== "capture") {
    throw new WorkerFailure(
      "worker.invalid_response_body_url_regex",
      "Explicit response-body route capture is limited to capture."
    );
  }
  return values.map((value) => {
    if (typeof value !== "string" || value.length === 0) {
      throw new WorkerFailure(
        "worker.invalid_response_body_url_regex",
        "Response-body URL regexes must be nonempty strings."
      );
    }
    try {
      return new RegExp(value);
    } catch {
      throw new WorkerFailure(
        "worker.invalid_response_body_url_regex",
        `Invalid response-body URL regex: ${value}`
      );
    }
  });
}

async function backfillHARResponseBodies(harPath, exchanges) {
  const queues = new Map();
  for (const exchange of exchanges) {
    if (!exchange.responseBodyBase64) {
      continue;
    }
    const key = `${exchange.method.toUpperCase()}\n${exchange.url}`;
    const queue = queues.get(key) ?? [];
    queue.push(exchange.responseBodyBase64);
    queues.set(key, queue);
  }
  if (queues.size === 0 || !(await fileExists(harPath))) {
    return;
  }
  const document = JSON.parse(await fs.readFile(harPath, "utf8"));
  for (const entry of document?.log?.entries ?? []) {
    const key = `${String(entry?.request?.method ?? "").toUpperCase()}\n${entry?.request?.url ?? ""}`;
    const queue = queues.get(key);
    if (!queue?.length || entry?.response?.content?.text) {
      continue;
    }
    entry.response.content.text = queue.shift();
    entry.response.content.encoding = "base64";
  }
  await writePrivateJSONAtomically(harPath, document);
}

async function writePrivateJSONAtomically(filePath, value) {
  const temporaryPath = `${filePath}.checkpoint`;
  await fs.writeFile(
    temporaryPath,
    `${JSON.stringify(value, null, 2)}\n`,
    { mode: 0o600 }
  );
  await fs.chmod(temporaryPath, 0o600);
  await fs.rename(temporaryPath, filePath);
}

async function fileExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function loadPlaywright() {
  const dependencyRoot = process.env.WEB_API_REVERSE_PLAYWRIGHT_ROOT
    ?? path.join(
      os.homedir(),
      "Library",
      "Application Support",
      "web-api-reverse",
      "playwright"
    );
  try {
    const moduleURL = pathToFileURL(
      path.join(dependencyRoot, "node_modules", "playwright", "index.js")
    ).href;
    const module = await import(moduleURL);
    return module.default ?? module;
  } catch {
    try {
      const module = await import("playwright");
      return module.default ?? module;
    } catch {
      throw new WorkerFailure(
        "worker.playwright_unavailable",
        "Playwright is unavailable. Run scripts/install-playwright or set WEB_API_REVERSE_PLAYWRIGHT_ROOT."
      );
    }
  }
}

async function readInput() {
  const line = await readLine({ required: true });
  try {
    return JSON.parse(line);
  } catch {
    throw new WorkerFailure(
      "worker.invalid_input",
      "Worker input must be one JSON object."
    );
  }
}

async function readLine({ required = false } = {}) {
  const result = await inputLines.next();
  if (result.done) {
    if (required) {
      throw new WorkerFailure(
        "worker.user_confirmation_required",
        "Explicit user confirmation was not received."
      );
    }
    return "";
  }
  return result.value;
}

function requireString(value, name) {
  if (typeof value !== "string" || value.length === 0) {
    throw new WorkerFailure(
      "worker.invalid_input",
      `${name} is required`
    );
  }
  return value;
}

function createWorkerLifecycle() {
  const parentProcessID = process.ppid;
  const ownerProcessID = positiveProcessID(
    process.env.WEB_API_REVERSE_OWNER_PID
  );
  let cleanup = async () => {};
  let shutdownStarted = false;

  const shutdown = async () => {
    if (shutdownStarted) return;
    shutdownStarted = true;
    try {
      await cleanup();
    } finally {
      try {
        process.stdout.write(`${JSON.stringify({
          ok: false,
          data: null,
          error: {
            code: "worker.owner_terminated",
            message: "The owning command ended; the browser context was closed.",
          },
        })}\n`);
      } catch {
        // The owner may have closed the output pipe with the parent process.
      }
      process.exit(130);
    }
  };
  for (const signal of ["SIGINT", "SIGTERM", "SIGHUP"]) {
    process.once(signal, () => {
      void shutdown();
    });
  }
  const timer = setInterval(() => {
    const parentAlive = processIsAlive(parentProcessID);
    const ownerAlive = ownerProcessID === null
      || processIsAlive(ownerProcessID);
    if (!parentAlive || !ownerAlive) {
      void shutdown();
    }
  }, 100);
  timer.unref();

  return {
    setCleanup(value) {
      cleanup = value;
    },
    clearCleanup(value) {
      if (cleanup === value) cleanup = async () => {};
    },
    stop() {
      clearInterval(timer);
    },
  };
}

function positiveProcessID(value) {
  if (value === undefined) return null;
  const parsed = Number.parseInt(value, 10);
  return Number.isSafeInteger(parsed) && parsed > 0 ? parsed : null;
}

function processIsAlive(processID) {
  try {
    process.kill(processID, 0);
    return true;
  } catch (error) {
    return error?.code === "EPERM";
  }
}

main()
  .catch((error) => {
    fail(
      error instanceof WorkerFailure ? error.code : "worker.failure",
      error instanceof Error ? error.message : "Unexpected failure.",
      error instanceof WorkerFailure ? error.data : null
    );
  })
  .finally(() => workerLifecycle.stop());
