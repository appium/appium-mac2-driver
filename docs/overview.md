---
hide:
  - navigation

title: Overview
---

The Mac2 driver is an Appium driver intended for black-box automated testing of macOS applications.

## Target Platforms

The driver supports the following Apple platforms as automation targets:

|Platform|Supported|
|--|--|
|macOS|:white_check_mark:|

## Technologies Used

The Mac2 driver uses the [W3C WebDriver protocol](https://www.w3.org/TR/webdriver/) for session
management.

Under the hood, the driver relies on Apple's [XCTest](https://developer.apple.com/documentation/xctest)
framework. Communication with XCTest is provided by the bundled WebDriverAgentMac component (a fork of
[the original implementation by Facebook](https://github.com/facebookarchive/WebDriverAgent)).
