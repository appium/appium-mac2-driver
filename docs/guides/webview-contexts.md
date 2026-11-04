---
title: Web View Contexts
---

Chromium-based apps (Electron, Chrome, Edge, CEF) render their UI as web pages that are only partially
visible in the accessibility tree. The driver can automate such pages with [Chromedriver](https://github.com/appium/appium-chromedriver).

WKWebView (Safari engine) content is not supported. Use the native accessibility tree instead
(see the `useDomIdAsAccessibilityId` [setting](../reference/settings.md)).

## Usage

Set `appium:webviewEnabled` to `true`. The driver launches the app with `--remote-debugging-port`
and lists the app pages as contexts:

```js
const contexts = await driver.getContexts(); // ['NATIVE_APP', 'WEBVIEW_<id>']
await driver.switchContext(contexts[1]);
await driver.$('#submit').click(); // handled by Chromedriver
await driver.switchContext('NATIVE_APP');
```

In a web view context all commands go to Chromedriver, except `macos:` execute methods, which always
target the native layer. Other scripts are executed in the page. Switching to `NATIVE_APP`, or
another web view, stops the current Chromedriver.

## Caveats

- The debugging flag only applies to a fresh app launch. It is ignored if the app is already running
  or `appium:noReset` is set.
- Chrome needs a dedicated profile to start a new instance, e.g. `appium:arguments: ['--user-data-dir=/tmp/profile']`.
- Automatic Chromedriver download is opt-in. Start the server with
  `--driver-mac2-chromedriver-storage-dir=<folder>` to download Chromedrivers matching the app's
  Chromium version into that folder, or use `appium:chromedriverExecutablePath` for offline setups.
