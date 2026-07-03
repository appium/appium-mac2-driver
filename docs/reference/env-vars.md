---
hide:
  - toc

title: Environment Variables
---

The driver recognizes several environment variables, which can be set when launching the Appium server.

For other environment variables recognized by the Appium server, see
[their Appium docs reference page](https://appium.io/docs/en/latest/reference/cli/env-vars/).

|<div style="width:18em">Variable Name</div>|Description|
|------------|-----------|
|`ENABLE_AUTOMATIC_SCREENSHOTS`|Whether to enable automatic XCTest screenshots. Screenshots are stored in the same folder as WDA test logs. Be careful with this feature, as screenshots may quickly fill up the disk space.|
|`ENABLE_AUTOMATIC_SCREEN_RECORDINGS`|Whether to enable automatic XCTest screen recording. This feature only works on Xcode 15 or later. Recordings are stored in the same folder as WDA test logs. Be careful with this feature, as recordings may quickly fill up the disk space.|
|`VERBOSE_LOGGING`|Whether to enable verbose logging for the WDA server|
