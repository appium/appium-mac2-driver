---
title: Hybrid Applications
---

The Mac2 driver supports automation of hybrid apps that use Chromium-based web views, such as
Electron, Chrome or CEF apps. This enables actions such as retrieving the web-specific page
source, as well as finding and interacting with elements located inside the web view.

Web views of other engines, such as `WKWebView`, are not supported. Their content is only available
through the native accessibility tree (see the `useDomIdAsAccessibilityId` [setting](../reference/settings.md)).

## Enabling Web Views

Set the [`appium:webviewEnabled`](../reference/capabilities.md#webviewenabled) capability to `true`.
The driver then launches the app with the `--remote-debugging-port` argument, so that the web views
are debuggable and accessible to the driver. The flag must not be set in `appium:arguments`, as such
a value is ignored. The port could be customized with the [`appium:webviewDevtoolsPort`](../reference/capabilities.md#webviewdevtoolsport)
capability.

!!! note

    The debugging argument only applies to a fresh app launch. It is ignored if the app is already
    running or if `appium:noReset` is set. Chrome additionally needs a dedicated profile to start
    a new instance, e.g. `appium:arguments: ['--user-data-dir=/tmp/profile']`.

The availability of a particular web view could be easily verified by using the
[Chrome Remote Debugger](https://developer.chrome.com/docs/devtools/remote-debugging/).

## Contexts

Web-specific information is not directly integrated into the default page source. Instead, the
driver makes use of Appium's [Context Management API](https://appium.io/docs/en/latest/guides/context/),
where each available web view is separated into its own context. As such, in order to interact with
any web view, it is necessary to first switch to its specific context using the context API.

```js
const contexts = await driver.getContexts(); // ['NATIVE_APP', 'WEBVIEW_<id>']
await driver.switchContext(contexts[1]);
await driver.$('#submit').click(); // handled by Chromedriver
await driver.switchContext('NATIVE_APP');
```

By default, a Mac2 driver session starts in the native context (named `NATIVE_APP`). To retrieve
detailed information about the web views, the driver also provides the
[`macos: getContexts`](../reference/execute-methods.md#macos-getcontexts) execute method.

In practice, when switching the application context from native to web view, the Mac2 driver
simply changes the underlying component to which it forwards most API commands:

* Native context: WebDriverAgentMac
* Web view context: an instance of [Chromedriver](https://developer.chrome.com/docs/chromedriver)

Refer to [Technologies Used](../overview.md#technologies-used) for more details.

## Web Context Specifics

Switching from the native context to a Chromedriver-backed web context brings a few benefits and
drawbacks alike:

* Web view-specific page source with web elements, similar to the one in Chrome DevTools
* Support for standard W3C WebDriver element locator strategies
* No support for driver-specific native locator strategies
* The `macos:` execute methods are still handled by the native layer, while any other script is
  executed in the page

Switching to `NATIVE_APP`, or to another web view, stops the current Chromedriver instance.

## Managing Chromedriver

The most important property of the Chromedriver instance is its version: Google requires it to
follow the version of Chromium used to build the web view under test, and in case of a mismatch,
Chromedriver will simply fail to attach to the web view (exact matches are not required, but major
versions must almost always match).

There are several approaches to obtaining a matching Chromedriver version:

### Automatic Discovery

The Mac2 driver allows to automatically download the version of Chromedriver compatible with the
web view under test. This download is initiated upon switching to the web view context.

However, since this approach allows clients to download files to the Appium server host machine, it
is considered an insecure feature, and requires explicit enablement on the server side via the
[`chromedriver_autodownload`](../reference/insecure-features.md) feature name:

```sh
appium server --allow-insecure mac2:chromedriver_autodownload
```

Once this feature is enabled, no additional configuration is required on the client side.

The downloaded executables are stored in the folder set by the
[`appium:chromedriverExecutableDir`](../reference/capabilities.md#chromedriverexecutabledir) capability.

### Using Capabilities

If the target Chromedriver executable already exists on the host machine, it is possible to simply
provide a path to it using the [`appium:chromedriverExecutable`](../reference/capabilities.md#chromedriverexecutable)
capability. Alternatively, the [`appium:chromedriverExecutableDir`](../reference/capabilities.md#chromedriverexecutabledir)
capability points to a folder containing several Chromedriver executables, from which the one
matching the web view is selected.

In order to manually download the correct Chromedriver executable, refer to the Chromedriver
[Version Selection](https://developer.chrome.com/docs/chromedriver/downloads/version-selection)
guide.

## Troubleshooting

### Downloading

In case of issues when downloading Chromedriver, the underlying `appium-chromedriver` package
allows changing the download CDN. Refer to [its README](https://github.com/appium/appium-chromedriver#custom-binaries-url)
for details.

It may also be necessary to adjust network proxy and firewall settings for the above to work.
