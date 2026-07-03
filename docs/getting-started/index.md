---
hide:
  - navigation

title: Getting Started
---

## System Requirements

There are three primary requirements to use the Mac2 driver:

* macOS host machine (version 11.3 Big Sur or later)
* Appium
* Xcode (version 13 or later)

### Appium Server

Make sure to install a version of Appium that supports your target driver version. The requirements
and prerequisites of Appium itself can be found in [the Appium documentation](https://appium.io/docs/en/latest/quickstart/requirements/).

| Mac2 driver version | Supported Appium server version |
| --- | --- |
| >= 3.0.0 | Appium 3 |
| 1.0.0 - 2.2.2 | Appium 2 |

## Installation

Provided you have set up the above prerequisites, you can install the driver using Appium's
[extension CLI](https://appium.io/docs/en/latest/cli/extensions/):

```bash
appium driver install mac2
```

You can also specify an exact driver version:

```bash
appium driver install mac2@2.2.0
```

Alternatively, if you are running a Node.js project, you can include `appium-mac2-driver` as
one of your project dependencies. [Refer to the Appium documentation](https://appium.io/docs/en/latest/guides/managing-exts/#do-it-yourself-with-npm)
for more information about this approach.

### Verify the Installation

In order to check that the driver was installed correctly, simply launch the Appium server:

```bash
appium
```

The server log output should include a line like the following:

```
[Appium] Mac2Driver has been successfully loaded in 0.789s
```

## Device Preparation

* Xcode must be configured to use its bundled Command Line Tools, in Xcode -> _Settings_ -> _Locations_ -> _Command Line Tools_
* The Xcode Helper app (bundled with Xcode) must be granted Accessibility permissions:
    * Open Finder in the directory containing the Xcode Helper app:
    
        ```
        open /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Xcode/Agents/
        ```

    * Without closing Finder, open System Settings -> _Privacy & Security_ -> _Accessibility_
    * Drag and drop Xcode Helper from Finder to the Accessibility list in System Settings

* Starting from macOS 12 Monterey, when starting a Mac2 driver session, macOS may occasionally [show a system prompt in order to enable automation](https://developer.apple.com/forums/thread/693850). The prompt can be disabled by running the following command:

    ```
    automationmodetool enable-automationmode-without-authentication
    ```

## Creating a Session

The Mac2 driver, like all Appium drivers, requires providing [specific capabilities](https://appium.io/docs/en/latest/guides/caps/)
in order to start a new session. The following example lists the minimum required capabilities for
a basic session:

```json
// This will start a macOS session and attach to the Finder application
{
  ...
  "platformName": "mac",
  "appium:automationName": "mac2",
  ...
}
```

See [the Capabilities reference page](../reference/capabilities.md) for more information on the
capabilities supported by the driver.
