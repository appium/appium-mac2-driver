---
title: Hybrid Applications
---

The Mac2 driver supports automation of hybrid apps that use Chromium-based web views, such as
Electron, Chrome or CEF apps. This enables actions such as retrieving the web-specific page
source, as well as finding and interacting with elements located inside the web view.

!!! warning

    Webviews based on other engines, such as WebKit/Safari (`WKWebView`), are not supported. Their
    content is only available through the native accessibility tree (see the [`useDomIdAsAccessibilityId`](../reference/settings.md#usedomidasaccessibilityid)
    setting).

## Enabling Web Views

Access to webviews is not available by default, and must be explicitly enabled by setting the
[`appium:webviewEnabled`](../reference/capabilities.md#webviewenabled) capability to `true`.

If the app is already running and [`appium:noReset`](../reference/capabilities.md#noreset) is set,
it is also required to explicitly provide the debugging port using the
[`appium:webviewDevtoolsPort`](../reference/capabilities.md#webviewdevtoolsport) capability. The
underlying Chromium engine additionally needs a dedicated profile to start a new instance, e.g.
[`appium:arguments`](../reference/capabilities.md#arguments) may be set to `['--user-data-dir=/tmp/profile']`.

The availability of a particular web view could be easily verified by using the
[Chrome Remote Debugger](https://developer.chrome.com/docs/devtools/remote-debugging/).

## Contexts

Web-specific information is not directly integrated into the default page source. Instead, the
driver makes use of Appium's [Context Management API](https://appium.io/docs/en/latest/guides/context/),
where each available web view is separated into its own context. As such, in order to interact with
any web view, it is necessary to first switch to its specific context using the context API.

By default, a Mac2 driver session starts in the native context (named `NATIVE_APP`). This is
usually the only context available in native apps. Hybrid apps, however, can have one or more web
contexts in addition to the native context, and each web context can contain zero or more
pages/windows. To retrieve detailed information about these webviews, the driver also provides the
[`macos: getContexts`](../reference/execute-methods.md#macos-getcontexts) execute method.

In practice, when switching the application context from native to web view, the Mac2 driver
simply changes the underlying component to which it forwards most API commands:

* Native context: WebDriverAgentMac
* Web view context: an instance of [ChromeDriver](https://developer.chrome.com/docs/chromedriver)

Refer to [Technologies Used](../overview.md#technologies-used) for more details.

## Web Context Specifics

Switching from the native context to a ChromeDriver-backed web context brings a few benefits and
drawbacks alike:

* Web view-specific page source with web elements, similar to the one in Chrome DevTools
* Support for standard W3C WebDriver element locator strategies
* No support for driver-specific native locator strategies
* The `macos:` execute methods are still handled by the native layer, while any other script is
  executed in the webpage

Switching to the `NATIVE_APP` context, or to another webview, stops the current ChromeDriver
instance.

## Managing ChromeDriver

The most important property of the ChromeDriver instance is its version: Google requires it to
follow the version of Chromium used to build the web view under test, and in case of a mismatch,
ChromeDriver will simply fail to attach to the web view (exact matches are not required, but major
versions must almost always match).

There are several approaches to obtaining a matching Chromedriver version:

### Automatic Discovery

The Mac2 driver allows to automatically download the version of ChromeDriver compatible with the
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

If the target ChromeDriver executable already exists on the host machine, it is possible to simply
provide a path to it using the [`appium:chromedriverExecutable`](../reference/capabilities.md#chromedriverexecutable)
capability. Alternatively, the [`appium:chromedriverExecutableDir`](../reference/capabilities.md#chromedriverexecutabledir)
capability points to a folder containing several ChromeDriver executables, from which the one
matching the web view is selected.

In order to manually download the correct ChromeDriver executable, refer to the ChromeDriver
[Version Selection](https://developer.chrome.com/docs/chromedriver/downloads/version-selection)
guide.

## Troubleshooting

### Downloading

In case of issues when downloading Chromedriver, the underlying `appium-chromedriver` package
allows changing the download CDN. Refer to [its README](https://github.com/appium/appium-android/tree/main/packages/chromedriver#custom-binaries-url)
for details.

It may also be necessary to adjust network proxy and firewall settings for the above to work.
