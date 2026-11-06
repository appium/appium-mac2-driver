---
hide:
  - navigation

title: Overview
---

The Mac2 driver is an Appium driver intended for black-box automated testing of macOS applications.
It is the successor to the deprecated [Appium Mac driver](https://github.com/appium/appium-mac-driver).

## Target Platforms

The driver supports the following Apple platforms as automation targets:

|Platform|Supported|
|--|--|
|macOS|:white_check_mark:|

## Contexts

The following application contexts are supported for automation:

* Native applications
* Webviews based on Chrome
* Hybrid applications

## Technologies Used

The Mac2 driver uses the [W3C WebDriver protocol](https://www.w3.org/TR/webdriver/) for session
management. Under the hood, the driver combines several different technologies to achieve its
functionality:

* Native testing
    * Based on Apple's [XCTest](https://developer.apple.com/documentation/xctest) framework
    * Provided by the bundled WebDriverAgentMac component (a fork of [the original implementation by Facebook](https://github.com/facebookarchive/WebDriverAgent))
* Webview testing
    * Based on [the ChromeDriver server](https://developer.chrome.com/docs/chromedriver)
    * Provided by the [`appium-chromedriver`](https://github.com/appium/appium-android/tree/main/packages/chromedriver)
    library
* Additional tools
    * Communication with Xcode is handled by the [`appium-xcode`](https://github.com/appium/appium-ios/tree/main/packages/xcode)
    library
