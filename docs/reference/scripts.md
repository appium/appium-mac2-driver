---
title: Scripts
---

Appium drivers can include scripts for executing specific actions. The scripts included in the Mac2
driver can be run as follows:

```
appium driver run mac2 <script-name>
```

For more information about the `appium driver run` command, refer to [the Appium docs](https://appium.io/docs/en/latest/reference/cli/extensions/#run).

### `open-wda`

Opens the WebDriverAgent (WDA) project of the installed Mac2 driver in Xcode. Available since driver
version 1.19.0.

#### Usage

```
appium driver run mac2 open-wda
```

### `setup-accessibility`

Helps to grant the macOS Accessibility permission to the WebDriverAgent runner, which is required
by some features. The script stops the running WebDriverAgent runner, because macOS evaluates the
permission when a process starts, so an active Mac2 session stops working. It then finds the
`WebDriverAgentRunner-Runner.app` that the driver has built, or builds it first if it does not exist
yet, using the same build settings as the driver. Finally, it shows the runner in Finder and opens
the Accessibility settings. It cannot grant the permission itself, because macOS only allows it to
be granted by the user. Refer to the
[Granting Accessibility Permission](../guides/accessibility-permission.md) guide for the complete
steps. Available since driver version 4.5.0.

The Appium server keeps running. The script exits with a non-zero code if the runner cannot be
built or found. Use the `WDA_RUNNER_PATH` environment variable to point it to a runner in a
non-default location. Running the script directly with `node scripts/setup-accessibility.mjs` from
the driver folder also supports the `--keep-running` flag, which leaves the running processes alone,
and the `--no-open` flag, which only prints the runner location.

#### Usage

```
appium driver run mac2 setup-accessibility
```
