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

!!! note

    If you already have the driver installed, since version 1.9.0 you can also verify most of its
    requirements with the built-in Appium Doctor support:

    ```
    appium driver doctor mac2
    ```

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
* The Xcode Helper app (bundled with Xcode) [must be granted Accessibility permissions](https://apple.stackexchange.com/questions/334008/xcode-helper-does-not-have-the-accessibility-permissions-needed-to-run-tests):
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

To launch or attach to a specific macOS application (for example, `com.apple.TextEdit`), set the
`appium:bundleId` capability in your Appium client:

=== "Java"

    ```java
    import io.appium.java_client.mac.Mac2Driver;
    import io.appium.java_client.mac.options.Mac2Options;
    import java.net.URL;

    Mac2Options options = new Mac2Options()
        .setBundleId("com.apple.TextEdit")
        .setShowServerLogs(true);

    Mac2Driver driver = new Mac2Driver(new URL("http://127.0.0.1:4723"), options);
    try {
        // Perform automation actions
        System.out.println(driver.getPageSource());
    } finally {
        driver.quit();
    }
    ```

=== "JS (WebdriverIO)"

    ```js
    import {remote} from 'webdriverio';

    const driver = await remote({
      hostname: '127.0.0.1',
      port: 4723,
      capabilities: {
        platformName: 'mac',
        'appium:automationName': 'mac2',
        'appium:bundleId': 'com.apple.TextEdit',
        'appium:showServerLogs': true,
      },
    });

    try {
      console.log(await driver.getPageSource());
    } finally {
      await driver.deleteSession();
    }
    ```

=== "Python"

    ```python
    from appium import webdriver
    from appium.options.mac import Mac2Options

    options = Mac2Options()
    options.bundle_id = 'com.apple.TextEdit'
    options.show_server_logs = True

    driver = webdriver.Remote('http://127.0.0.1:4723', options=options)
    try:
        print(driver.page_source)
    finally:
        driver.quit()
    ```

=== "Ruby"

    ```ruby
    require 'appium_lib_core'

    opts = {
      caps: {
        platformName: :mac,
        automationName: :mac2,
        bundleId: 'com.apple.TextEdit',
        showServerLogs: true
      },
      appium_lib: {
        server_url: 'http://127.0.0.1:4723'
      }
    }

    driver = Appium::Core.for(opts).start_driver
    begin
      puts driver.page_source
    ensure
      driver.quit
    end
    ```

=== "C#"

    ```csharp
    using System;
    using OpenQA.Selenium.Appium;
    using OpenQA.Selenium.Appium.Mac;

    var options = new AppiumOptions
    {
        PlatformName = "Mac",
        AutomationName = "Mac2"
    };
    options.AddAdditionalAppiumOption("bundleId", "com.apple.TextEdit");
    options.AddAdditionalAppiumOption("showServerLogs", true);

    using var driver = new Mac2Driver(new Uri("http://127.0.0.1:4723"), options);
    Console.WriteLine(driver.PageSource);
    ```

See [the Capabilities reference page](../reference/capabilities.md) for more information on the
capabilities supported by the driver.
