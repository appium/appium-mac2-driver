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

## Downloaded Applications

macOS asks for a confirmation the first time a quarantined application (for example, one downloaded
from the internet) is opened. Nobody can dismiss this dialog during a test, so the launch would
hang until the request times out. The driver detects such applications upfront and fails with an
error instead, both on session creation and in `macos: launchApp`/`macos: activateApp`.
Open the application manually once and approve it, or remove the quarantine flag on the machine
that runs the tests:

```bash
xattr -dr com.apple.quarantine /path/to/App.app
```

If this fails with `Operation not permitted`, the application is probably signed by another
developer. macOS may then require allowing the terminal app in System Settings > Privacy & Security >
App Management (or Full Disk Access) first.
