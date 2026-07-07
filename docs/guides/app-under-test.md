---
hide:
  - toc

title: Application Under Test
---

The Mac2 driver has the concept of the Application Under Test (AUT).

The AUT is usually the application whose identifier is specified as the [`appium:bundleId`](../reference/capabilities.md#bundleid)
capability, but it can be updated using the following execute methods:

* [`macos: activateApp`](../reference/execute-methods.md#macos-activateapp)
* [`macos: launchApp`](../reference/execute-methods.md#macos-launchapp)
* [`macos: terminateApp`](../reference/execute-methods.md#macos-terminateapp) - sets the AUT to none

The AUT is automatically terminated upon session deletion, unless the [`appium:skipAppKill`](../reference/capabilities.md#skipappkill)
capability is set.

If the AUT is unexpectedly terminated during the session, an exception will be thrown upon any
following session command invocation. In this case, the driver assumes the AUT has crashed, and it
is impossible to proceed.
