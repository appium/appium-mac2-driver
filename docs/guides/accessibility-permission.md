---
title: Granting Accessibility Permission
---

Some Mac2 driver features read or change UI state through the macOS Accessibility API, which macOS
only allows for apps that you have explicitly trusted. Regular test automation (finding elements,
clicking, typing, and so on) does **not** need this permission. These features do:

| Feature | Without the permission |
| --- | --- |
| [`macos: adjustWindow`](../reference/execute-methods.md#macos-adjustwindow) | Fails with an error that mentions the Accessibility permission. |
| Window traits in [`macos: listWindows`](../reference/execute-methods.md#macos-listwindows) (`isMain`, `isMinimized`, `isFullscreen`, and so on) | The traits are `null`. |
| The [`useDomIdAsAccessibilityId`](../reference/settings.md#usedomidasaccessibilityid) setting | Web element DOM identifiers cannot be resolved. |

The permission must be granted to the **WebDriverAgent runner**, the helper app that the driver
builds and starts on your Mac. It is called `WebDriverAgentRunner-Runner.app`, and it is not the
application under test, Appium, or your terminal.

## Steps

1. **End your Mac2 sessions.** The next step stops the running WebDriverAgent runner, because macOS
   decides on the permission when a process starts. A session that is still active stops working.
2. **Run the helper script.** It stops the running runner, builds the runner if it does not exist
   yet (which can take a few minutes), shows it in Finder and opens the Accessibility settings:

    ```
    appium driver run mac2 setup-accessibility
    ```

   See [the scripts reference](../reference/scripts.md#setup-accessibility) for details.
3. **Add the runner.** In **System Settings → Privacy & Security → Accessibility**, add
   `WebDriverAgentRunner-Runner.app` with the **+** button (or drag it from the Finder window that
   the script opened), and turn its toggle on. macOS asks for your password or Touch ID.
4. **Start Appium and a new session**, and [verify](#verify-the-permission) that it works.

!!! note

    The name and the position of the Accessibility list differ between macOS versions. On some
    versions it can be grouped under another heading of the Privacy & Security page, for example
    "Device Control and Data Access". If you cannot find it, use the search field of System Settings.

## Verify the permission

Call [`macos: listWindows`](../reference/execute-methods.md#macos-listwindows) in a session. If the
runner is trusted, the window traits are booleans. If they are `null`, the runner is not trusted.

## Troubleshooting

### The permission is lost after some time

The runner is signed ad-hoc by default, and macOS ties the permission to the exact build. The
runner is rebuilt when the driver is updated, when WebDriverAgent sources change, or when the
derived data of Xcode is cleaned. Every new build needs the steps above again.

To keep the permission across rebuilds, sign WebDriverAgent with a stable identity, such as an Apple
Development certificate. Refer to the [Troubleshooting](../troubleshooting/index.md) page for more
details about the signing configuration. You can use the
[`open-wda` script](../reference/scripts.md#open-wda) to open the project in Xcode.

### The runner is in the list and enabled, but it is still not trusted

An entry that was created for an older build of the runner can stay in the list and keep the old
build's identity, so the new build does not match it. Reset the entry, and then add the runner
again:

```
tccutil reset Accessibility io.appium.WebDriverAgentRunner.xctrunner
```

Then follow the steps above. Do not rebuild the runner after you add it.

### The script cannot find the runner

The script builds the runner and looks for it in `~/Library/Developer/Xcode/DerivedData`. If you
moved the derived data of Xcode, set the `WDA_RUNNER_PATH` environment variable to the full path to
`WebDriverAgentRunner-Runner.app`:

```
WDA_RUNNER_PATH=/path/to/WebDriverAgentRunner-Runner.app appium driver run mac2 setup-accessibility
```
