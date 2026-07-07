---
title: Execute Methods
---

The Mac2 driver provides various [custom execute methods](https://appium.io/docs/en/latest/guides/execute-methods/)
based on the standard Execute Script endpoint. Use the following examples in order to invoke them
from your client code:

=== "Java"

    ```java
    var result = driver.executeScript("macos: <methodName>", Map.ofEntries(
        Map.entry("arg1", "value1"),
        Map.entry("arg2", "value2")
        // you may add more pairs if needed or skip providing the map completely
        // if all arguments are defined as optional
    ));
    ```

=== "JS (WebdriverIO)"

    ```js
    const result = await driver.executeScript('macos: <methodName>', [{
        arg1: "value1",
        arg2: "value2",
    }]);
    ```

=== "Python"

    ```python
    result = driver.execute_script('macos: <methodName>', {
        'arg1': 'value1',
        'arg2': 'value2',
    })
    ```

=== "Ruby"

    ```ruby
    result = @driver.execute_script 'macos: <methodName>', {
        arg1: 'value1',
        arg2: 'value2',
    }
    ```

=== "C#"

    ```csharp
    object result = driver.ExecuteScript("macos: <methodName>", new Dictionary<string, object>() {
        {"arg1", "value1"},
        {"arg2", "value2"}
    }));
    ```

### macos: click

Performs a click gesture on an element, or by relative/absolute coordinates. Based on XCTest's
[`click` (XCUIElement)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/click())
and [`click` (XCUICoordinate)](https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate/click())
methods.

#### Arguments

| <div style="width:10em">Name</div> | Type | Description |
| --- | --- | --- |
| `elementId?`| `string` | Identifier of the element to click on. Required if `x` and `y` are not set. |
| `x?` | `number` | Horizontal coordinate offset. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `y?` | `number` | Vertical coordinate offset. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `keyModifierFlags?` | `number` | Additional key modifiers to apply during the click. Refer to the [Key Modifier Flags guide](../guides/key-modifier-flags.md) for more details. |

#### Response

`null`

### macos: scroll

Performs a scroll gesture on an element, or by relative/absolute coordinates. Based on XCTest's
[`scrollByDeltaX:deltaY:` (XCUIElement)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/scroll(bydeltax:deltay:))
and [`scrollByDeltaX:deltaY:` (XCUICoordinate)](https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate/scroll(bydeltax:deltay:))
methods.

#### Arguments

| <div style="width:10em">Name</div> | Type | Description |
| --- | --- | --- |
| `elementId?`| `string` | Identifier of the element to be scrolled. Required if `x` and `y` are not set. |
| `x?` | `number` | Horizontal coordinate offset for the scroll startpoint. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `y?` | `number` | Vertical coordinate offset for the scroll startpoint. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `deltaX` | `number` | Horizontal coordinate offset for the scroll endpoint, with respect to the scroll startpoint. Can be negative. |
| `deltaY` | `number` | Vertical coordinate offset for the scroll endpoint, with respect to the scroll startpoint. Can be negative. |
| `keyModifierFlags?` | `number` | Additional key modifiers to apply during the scroll. Refer to the [Key Modifier Flags guide](../guides/key-modifier-flags.md) for more details. |

#### Response

`null`

### macos: rightClick

Performs a right click gesture on an element, or by relative/absolute coordinates. Based on XCTest's
[`rightClick` (XCUIElement)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/rightclick())
and [`rightClick` (XCUICoordinate)](https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate/rightclick())
methods.

#### Arguments

| <div style="width:10em">Name</div> | Type | Description |
| --- | --- | --- |
| `elementId?`| `string` | Identifier of the element to right click on. Required if `x` and `y` are not set. |
| `x?` | `number` | Horizontal coordinate offset. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `y?` | `number` | Vertical coordinate offset. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `keyModifierFlags?` | `number` | Additional key modifiers to apply during the click. Refer to the [Key Modifier Flags guide](../guides/key-modifier-flags.md) for more details. |

#### Response

`null`

### macos: hover

Performs a hover gesture on an element, or by relative/absolute coordinates. Based on XCTest's
[`hover` (XCUIElement)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/hover())
and [`hover` (XCUICoordinate)](https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate/hover())
methods.

#### Arguments

| <div style="width:10em">Name</div> | Type | Description |
| --- | --- | --- |
| `elementId?`| `string` | Identifier of the element to hover over. Required if `x` and `y` are not set. |
| `x?` | `number` | Horizontal coordinate offset. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `y?` | `number` | Vertical coordinate offset. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `keyModifierFlags?` | `number` | Additional key modifiers to apply during the hover. Refer to the [Key Modifier Flags guide](../guides/key-modifier-flags.md) for more details. |

#### Response

`null`

### macos: doubleClick

Performs a double click gesture on an element, or by relative/absolute coordinates. Based on
XCTest's [`doubleClick` (XCUIElement)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/doubleclick())
and [`doubleClick` (XCUICoordinate)](https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate/doubleclick())
methods.

#### Arguments

| <div style="width:10em">Name</div> | Type | Description |
| --- | --- | --- |
| `elementId?`| `string` | Identifier of the element to double click on. Required if `x` and `y` are not set. |
| `x?` | `number` | Horizontal coordinate offset. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `y?` | `number` | Vertical coordinate offset. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `keyModifierFlags?` | `number` | Additional key modifiers to apply during the click. Refer to the [Key Modifier Flags guide](../guides/key-modifier-flags.md) for more details. |

#### Response

`null`

### macos: clickAndDrag

Performs a long click and drag gesture on an element, or by absolute coordinates. Based on XCTest's
[`clickForDuration:thenDragToElement:` (XCUIElement)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/click(forduration:thendragto:))
and [`clickForDuration:thenDragToCoordinate:` (XCUICoordinate)](https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate/click(forduration:thendragto:))
methods.

#### Arguments

| <div style="width:12em">Name</div> | Type | Description |
| --- | --- | --- |
| `sourceElementId?`| `string` | Identifier of the element to start the drag from. Required if `startX`/`startY`/`endX`/`endY` are not set. |
| `destinationElementId?`| `string` | Identifier of the element to end the drag on. Required if `startX`/`startY`/`endX`/`endY` are not set. |
| `startX?` | `number` | Horizontal coordinate start point. Required if `sourceElementId`/`destinationElementId` are not set. |
| `startY?` | `number` | Vertical coordinate start point. Required if `sourceElementId`/`destinationElementId` are not set. |
| `endX?` | `number` | Horizontal coordinate end point. Required if `sourceElementId`/`destinationElementId` are not set. |
| `endY?` | `number` | Vertical coordinate end point. Required if `sourceElementId`/`destinationElementId` are not set. |
| `duration` | `number` | Duration in seconds to perform the click and hold. |
| `keyModifierFlags?` | `number` | Additional key modifiers to apply during the drag. Refer to the [Key Modifier Flags guide](../guides/key-modifier-flags.md) for more details. |

#### Response

`null`

### macos: clickAndDragAndHold

Performs a long click, drag and hold gesture on an element, or by absolute coordinates. Based on
XCTest's [`clickForDuration:thenDragToElement:withVelocity:thenHoldForDuration:` (XCUIElement)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/click(forduration:thendragto:withvelocity:thenholdforduration:))
and [`clickForDuration:thenDragToCoordinate:withVelocity:thenHoldForDuration:` (XCUICoordinate)](https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate/click(forduration:thendragto:withvelocity:thenholdforduration:))
methods.

#### Arguments

| <div style="width:12em">Name</div> | Type | Description |
| --- | --- | --- |
| `sourceElementId?`| `string` | Identifier of the element to start the drag from. Required if `startX`/`startY`/`endX`/`endY` are not set. |
| `destinationElementId?`| `string` | Identifier of the element to end the drag on. Required if `startX`/`startY`/`endX`/`endY` are not set. |
| `startX?` | `number` | Horizontal coordinate start point. Required if `sourceElementId`/`destinationElementId` are not set. |
| `startY?` | `number` | Vertical coordinate start point. Required if `sourceElementId`/`destinationElementId` are not set. |
| `endX?` | `number` | Horizontal coordinate end point. Required if `sourceElementId`/`destinationElementId` are not set. |
| `endY?` | `number` | Vertical coordinate end point. Required if `sourceElementId`/`destinationElementId` are not set. |
| `duration` | `number` | Duration in seconds to perform the initial click and hold. |
| `holdDuration` | `number` | Duration in seconds to perform the hold after drag. |
| `velocity?` | `number` | Drag velocity in pixels per second. Uses the `default` value by default; refer to [the XCTest documentation on XCUIGestureVelocity](https://developer.apple.com/documentation/xcuiautomation/xcuigesturevelocity) for more details. |
| `keyModifierFlags?` | `number` | Additional key modifiers to apply during the drag. Refer to the [Key Modifier Flags guide](../guides/key-modifier-flags.md) for more details. |

#### Response

`null`

### macos: swipe

Performs a swipe gesture on an element, or by relative/absolute coordinates. Based on various XCTest
methods: [`swipeDown` (XCUIElement)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/swipedown()),
[`swipeDown` (XCUICoordinate)](https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate/swipedown()),
[`swipeDownWithVelocity:` (XCUIElement)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/swipedown(velocity:)),
[`swipeDownWithVelocity:` (XCUICoordinate)](https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate/swipedown(velocity:)),
and equivalent methods for the `Up`, `Left` and `Right` directions.

#### Arguments

| <div style="width:10em">Name</div> | Type | Description |
| --- | --- | --- |
| `elementId?`| `string` | Identifier of the element to swipe on. Required if `x` and `y` are not set. |
| `x?` | `number` | Horizontal coordinate offset. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `y?` | `number` | Vertical coordinate offset. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `direction` | `string` | Direction in which to swipe. Supported values are `up`, `down`, `left` or `right`. |
| `velocity?` | `number` | Swipe velocity in pixels per second. Uses the `default` value by default; refer to [the XCTest documentation on XCUIGestureVelocity](https://developer.apple.com/documentation/xcuiautomation/xcuigesturevelocity) for more details. |
| `keyModifierFlags?` | `number` | Additional key modifiers to apply during the swipe. Refer to the [Key Modifier Flags guide](../guides/key-modifier-flags.md) for more details. |

#### Response

`null`

### macos: press

Performs a press gesture on a Touch Bar element, or by relative/absolute coordinates. Based on
XCTest's [`pressForDuration:` (XCUIElement)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/press(forduration:))
and [`pressForDuration:` (XCUICoordinate)](https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate/press(forduration:))
methods.

#### Arguments

| <div style="width:10em">Name</div> | Type | Description |
| --- | --- | --- |
| `elementId?`| `string` | Identifier of the Touch Bar element to press on. Required if `x` and `y` are not set. |
| `x?` | `number` | Horizontal coordinate offset. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `y?` | `number` | Vertical coordinate offset. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `duration` | `number` | Duration in float seconds to keep the element pressed |
| `keyModifierFlags?` | `number` | Additional key modifiers to apply during the press. Refer to the [Key Modifier Flags guide](../guides/key-modifier-flags.md) for more details. |

#### Response

`null`

### macos: tap

Performs a tap gesture on a Touch Bar element, or by relative/absolute coordinates. Based on
XCTest's [`tap` (XCUIElement)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/tap())
and [`tap` (XCUICoordinate)](https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate/tap())
methods.

#### Arguments

| <div style="width:10em">Name</div> | Type | Description |
| --- | --- | --- |
| `elementId?`| `string` | Identifier of the Touch Bar element to tap on. Required if `x` and `y` are not set. |
| `x?` | `number` | Horizontal coordinate offset. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `y?` | `number` | Vertical coordinate offset. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `keyModifierFlags?` | `number` | Additional key modifiers to apply during the press. Refer to the [Key Modifier Flags guide](../guides/key-modifier-flags.md) for more details. |

#### Response

`null`

### macos: doubleTap

Performs a double tap gesture on a Touch Bar element, or by relative/absolute coordinates. Based on
XCTest's [`doubleTap` (XCUIElement)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/doubletap())
and [`doubleTap` (XCUICoordinate)](https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate/doubletap())
methods.

#### Arguments

| <div style="width:10em">Name</div> | Type | Description |
| --- | --- | --- |
| `elementId?`| `string` | Identifier of the Touch Bar element to double tap on. Required if `x` and `y` are not set. |
| `x?` | `number` | Horizontal coordinate offset. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `y?` | `number` | Vertical coordinate offset. Required if `elementId` is not set. If `elementId` is also set, this value is used as a relative element coordinate offset. |
| `keyModifierFlags?` | `number` | Additional key modifiers to apply during the press. Refer to the [Key Modifier Flags guide](../guides/key-modifier-flags.md) for more details. |

#### Response

`null`

### macos: pressAndDrag

Performs a long press and drag gesture on a Touch Bar element, or by absolute coordinates. Based on
XCTest's [`pressForDuration:thenDragToElement:` (XCUIElement)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/press(forduration:thendragto:))
and [`pressForDuration:thenDragToCoordinate:` (XCUICoordinate)](https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate/press(forduration:thendragto:))
methods.

#### Arguments

| <div style="width:12em">Name</div> | Type | Description |
| --- | --- | --- |
| `sourceElementId?`| `string` | Identifier of the Touch Bar element to start the drag from. Required if `startX`/`startY`/`endX`/`endY` are not set. |
| `destinationElementId?`| `string` | Identifier of the Touch Bar element to end the drag on. Required if `startX`/`startY`/`endX`/`endY` are not set. |
| `startX?` | `number` | Horizontal coordinate start point. Required if `sourceElementId`/`destinationElementId` are not set. |
| `startY?` | `number` | Vertical coordinate start point. Required if `sourceElementId`/`destinationElementId` are not set. |
| `endX?` | `number` | Horizontal coordinate end point. Required if `sourceElementId`/`destinationElementId` are not set. |
| `endY?` | `number` | Vertical coordinate end point. Required if `sourceElementId`/`destinationElementId` are not set. |
| `duration` | `number` | Duration in seconds to perform the press and hold. |
| `keyModifierFlags?` | `number` | Additional key modifiers to apply during the drag. Refer to the [Key Modifier Flags guide](../guides/key-modifier-flags.md) for more details. |

#### Response

`null`

### macos: pressAndDragAndHold

Performs a long press, drag and hold gesture on a Touch Bar element, or by absolute coordinates.
Based on XCTest's [`pressForDuration:thenDragToElement:withVelocity:thenHoldForDuration:` (XCUIElement)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/press(forduration:thendragto:withvelocity:thenholdforduration:))
and [`pressForDuration:thenDragToCoordinate:withVelocity:thenHoldForDuration:` (XCUICoordinate)](https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate/press(forduration:thendragto:withvelocity:thenholdforduration:))
methods.

#### Arguments

| <div style="width:12em">Name</div> | Type | Description |
| --- | --- | --- |
| `sourceElementId?`| `string` | Identifier of the Touch Bar element to start the drag from. Required if `startX`/`startY`/`endX`/`endY` are not set. |
| `destinationElementId?`| `string` | Identifier of the Touch Bar element to end the drag on. Required if `startX`/`startY`/`endX`/`endY` are not set. |
| `startX?` | `number` | Horizontal coordinate start point. Required if `sourceElementId`/`destinationElementId` are not set. |
| `startY?` | `number` | Vertical coordinate start point. Required if `sourceElementId`/`destinationElementId` are not set. |
| `endX?` | `number` | Horizontal coordinate end point. Required if `sourceElementId`/`destinationElementId` are not set. |
| `endY?` | `number` | Vertical coordinate end point. Required if `sourceElementId`/`destinationElementId` are not set. |
| `duration` | `number` | Duration in seconds to perform the initial press and hold. |
| `holdDuration` | `number` | Duration in seconds to perform the hold after drag. |
| `velocity?` | `number` | Drag velocity in pixels per second. Uses the `default` value by default; refer to [the XCTest documentation on XCUIGestureVelocity](https://developer.apple.com/documentation/xcuiautomation/xcuigesturevelocity) for more details. |
| `keyModifierFlags?` | `number` | Additional key modifiers to apply during the drag. Refer to the [Key Modifier Flags guide](../guides/key-modifier-flags.md) for more details. |

#### Response

`null`

### macos: keys

Sends keys to an element, or the application under test.
Based on XCTest's [`typeKey:modifierFlags:`](https://developer.apple.com/documentation/xcuiautomation/xcuielement/typekey(_:modifierflags:)-9ubn)
method.

#### Arguments

| <div style="width:6em">Name</div> | <div style="width:11em">Type</div> | Description |
| --- | --- | --- |
| `elementId?`| `string` | Identifier of the element to send the keys to. If not set, keys are sent to the application under test. |
| `keys` | `Array<string|Record>` | Array of keys to type. A single key can be either a string (the key itself or an [XCUIKeyboardKey constant](https://developer.apple.com/documentation/xcuiautomation/xcuikeyboardkey)), or an object with the `key` and `modifierFlags` entries. Refer to the [Key Modifier Flags guide](../guides/key-modifier-flags.md) for more details. |

#### Key Examples

* `['h', 'i']`
* `[{key: 'h', modifierFlags: 1 << 1}, {key: 'i', modifierFlags: 1 << 2}]`
* `['XCUIKeyboardKeyEscape']`

#### Response

`null`

### macos: source

Retrieves a string representation of the current app source. Based on XCTest's
[`debugDescription`](https://developer.apple.com/documentation/xcuiautomation/xcuielement/debugdescription)
method.

#### Arguments

| Name | Type | Description |
| --- | --- | --- |
| `format?`| `string` | Format in which the app source should be retrieved. Supported values are `xml` (XML format, default) and `description` (the `debugDescription` output format) |

#### Response

`string` - the application source

### macos: launchApp

Launches the application with the given bundle identifier/path, or activates the application if it
is already running. An exception is thrown if the app cannot be found. Based on XCTest's
[`launch`](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/launch())
and [`activate`](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/activate())
methods.

This method influences the state of the [Application Under Test](../guides/app-under-test.md).

#### Arguments

| <div style="width:7em">Name</div> | <div style="width:11em">Type</div> | Description |
| --- | --- | --- |
| `bundleId?`| `string` | Bundle identifier of the app to be launched/activated. Required if `path` is not set. |
| `path?`| `string` | Full path to the application bundle. Required if `bundleId` is not set. Available since driver version 1.10.0. |
| `arguments?`| `Array<string>` | Command-line arguments passed to the app. Ignored if the app is already running. Similar to the [`appium:arguments`](./capabilities.md#arguments) capability. |
| `environment?`| `Record<string, any>` | Environment variables used when launching the app. Ignored if the app is already running. Similar to the [`appium:environment`](./capabilities.md#environment) capability. |

#### Response

`null`

### macos: activateApp

Activates the application with the given bundle identifier/path. An exception is thrown if the app
cannot be found, or the app is not running. Based on XCTest's
[`activate`](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/activate())
method.

This method influences the state of the [Application Under Test](../guides/app-under-test.md).

#### Arguments

| Name | Type | Description |
| --- | --- | --- |
| `bundleId?`| `string` | Bundle identifier of the app to be activated. Required if `path` is not set. |
| `path?`| `string` | Full path to the application bundle. Required if `bundleId` is not set. Available since driver version 1.10.0. |

#### Response

`null`

### macos: terminateApp

Terminates the application with the given bundle identifier/path. An exception is thrown if the app
cannot be found. Based on XCTest's
[`terminate`](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/terminate())
method.

This method influences the state of the [Application Under Test](../guides/app-under-test.md).

#### Arguments

| Name | Type | Description |
| --- | --- | --- |
| `bundleId?`| `string` | Bundle identifier of the app to be terminated. Required if `path` is not set. |
| `path?`| `string` | Full path to the application bundle. Required if `bundleId` is not set. Available since driver version 1.10.0. |

#### Response

`null`

### macos: queryAppState

Queries the state of the application with the given bundle identifier/path. An exception is thrown
if the app cannot be found.

#### Arguments

| Name | Type | Description |
| --- | --- | --- |
| `bundleId?`| `string` | Bundle identifier of the app to be queried. Required if `path` is not set. |
| `path?`| `string` | Full path to the application bundle. Required if `bundleId` is not set. Available since driver version 1.10.0. |

#### Response

`number` - an integer value representing the application state. See the [XCUITest documentation on XCUIApplicationState](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/state-swift.enum)
for more details.

### macos: appleScript

Executes the provided AppleScript command or script. The [`apple_script` insecure feature](./insecure-features.md)
must be enabled. Refer to the [AppleScript guide](../guides/applescript.md) for more details.

#### Arguments

| Name | Type | Description |
| --- | --- | --- |
| `command?`| `string` | AppleScript command to execute. Required if `script` is not set. If `script` is also set, only `command` is used. |
| `script?`| `string` | AppleScript script to execute. Required if `command` is not set. Ignored if `command` is also set. |
| `language?`| `string` | Overrides the scripting language (AppleScript by default). This translates to the `-l` argument of the `osascript` tool.  |
| `timeout?`| `number` | Number of seconds to wait until a long-running blocking command is finished. An error is thrown if the command is still running after this timeout expires. |
| `cwd?`| `string` | Path to an existing directory used as the working directory for the script execution. |

#### Response

`any` - the stdout of the provided script/command, if successful

### macos: startRecordingScreen

Starts a recording of the device display in the background using `ffmpeg`, while the automated test
is running. The video is recorded using the `libx264` codec in the `yuv420p` pixel format. The
recording can be stopped either using the [`macos: stopRecordingScreen`](#macos-stoprecordingscreen)
method, or by stopping the session itself. In both cases, the raw video file is deleted.

This method requires `ffmpeg` to be installed and present in PATH. Additionally, the Appium process
must be granted recording permissions in macOS System Settings -> _Privacy & Security_ ->
_Screen & System Audio Recording_.

#### Arguments

| <div style="width:8em">Name</div> | Type | Description |
| --- | --- | --- |
| `deviceId`| `number` | Identifier of the screen device to record. Available identifiers can be retrieved using the command `ffmpeg -f avfoundation -list_devices true -i`.|
| `videoFilter?`| `string` | Video filters to apply. Equivalent to the `-vf` argument for `ffmpeg`. Refer to [ffmpeg's Filtering Guide](https://trac.ffmpeg.org/wiki/FilteringGuide) for more details. |
| `fps?`| `number` | Framerate used to record the video. Set to `15` by default. |
| `preset?`| `string` | Encoding preset to use. Faster presets will result in a larger filesize - refer to [ffmpeg's H264 Presets Guide](https://trac.ffmpeg.org/wiki/Encode/H.264#Preset) for more details. Set to `veryfast` by default. |
| `captureCursor?`| `boolean` | Whether to capture the cursor during the recording. Set to `false` by default. |
| `captureClicks?`| `boolean` | Whether to capture clicks during the recording. Set to `false` by default. |
| `timeLimit?`| `number` | Time in seconds for the maximum recording length. Set to `600` (10 minutes) by default. |
| `forceRestart?`| `boolean` | If a screen recording process is already running, whether to terminate it and start a new one (`true`), or do nothing (`false`). Set to `true` by default. |

#### Response

`null`

### macos: stopRecordingScreen

Stops the active `ffmpeg` screen recording process started by [`macos: startRecordingScreen`](#macos-startrecordingscreen),
either returning its payload or uploading it to a remote location.

#### Arguments

| <div style="width:8em">Name</div> | <div style="width:8em">Type</div> | Description |
| --- | --- | --- |
| `remotePath?`| `string` | Path to a remote location where the resulting video file should be uploaded. Supported path protocols are HTTP(S) and FTP (deprecated). An exception is thrown if the file is too big to fit in the process memory. |
| `user?`| `string` | Username used for authentication to `remotePath` |
| `pass?`| `string` | Password used for authentication to `remotePath` |
| `method?`| `string` | Name of the HTTP(S) multipart upload method. Set to `PUT` by default. |
| `headers?`| `Record<string, any>` | Additional headers to use for the HTTP(S) multipart upload |
| `fileFieldName?`| `string` | Name of the form field for storing the file content blob for HTTP(S) uploads. Set to `file` by default. |
| `formFields?`| `Record<string, any>` or `Array<[string, any]>` | Additional form fields to use for the HTTP(S) multipart upload |

#### Response

`string` - base64-encoded string of the video file, or an empty string if `remotePath` is provided
or no active screen recording process is found.

### macos: screenshots

Retrieves a screenshot of one or more available displays. Available since driver version 1.1.0.

#### Arguments

| <div style="width:6em">Name</div> | Type | Description |
| --- | --- | --- |
| `displayId?`| `number` | Identifier of a specific display to take a screenshot for. By default, all available displays are used. Available displays can be found using the [`macos: listDisplays`](#macos-listdisplays) method, or the `system_profiler -json SPDisplaysDataType` terminal command. |

#### Response

`Array<Record<string, any>>` - a list of objects, where each object has the following structure:

| Key | Value Type | Description |
| --- | --- | --- |
| `id`| `number` | Display identifier |
| `isMain`| `boolean` | Whether this display is the main one |
| `payload`| `string` | The base64-encoded display screenshot data |

### macos: deepLink

Opens the specified URL within the default or specified application.

This feature requires Xcode 14.3 or later. Available since driver version 1.15.0.

#### Arguments

| Name | Type | Description |
| --- | --- | --- |
| `url`| `string` | URL to be opened |
| `bundleId?`| `string` | Bundle identifier of the application to use for opening the `url`. If not set, the default application for the URL scheme is used. |

#### Response

`null`

### macos: startNativeScreenRecording

Starts a recording of the device display in the background using XCTest, while the automated test
is running. Does nothing if a screen recording is already running. The recording can be stopped
using the [`macos: stopNativeScreenRecording`](#macos-stopnativescreenrecording) method, or by
stopping the session itself. In both cases, the raw video file is deleted.

This feature requires Xcode 15 or later. Available since driver version 2.1.0.

!!! tip

    This API also triggers broadcasting of the [`appium:mac2.nativeVideoRecordingChunkAdded` BiDi event](./bidi.md).
    Make sure to subscribe to these events _before_ calling this execute method, to ensure that
    all video chunks are properly consumed on the client side.

#### Arguments

| <div style="width:6em">Name</div> | Type | Description |
| --- | --- | --- |
| `fps?`| `number` | Framerate used to record the video. Set to `24` by default. |
| `codec?`| `number` | The video codec to use for recording. Supported values are `0` (H264) and `1` (HEVC). Set to `0` by default. |
| `displayId?`| `number` | Identifier of a specific display to record. By default, the main display is used. Available displays can be found using the [`macos: listDisplays`](#macos-listdisplays) method, or the `system_profiler -json SPDisplaysDataType` terminal command. |

#### Response

`Record<string, any>` - an object with the following structure:

| Key | Value Type | Description |
| --- | --- | --- |
| `fps`| `number` | Video framerate |
| `codec`| `number` | Video coded |
| `displayId`| `number` | Display identifier |
| `uuid`| `string` | Unique video identifier used by XCTest to store the video, located at `~/Library/Daemon Containers/<testmanager_id>/Data/Attachments/<uuid>.mp4`. |
| `startedAt`| `number` | Unix timestamp of the recording start time |

### macos: getNativeScreenRecordingInfo

Fetches the information of the currently running native video recording.

This feature requires Xcode 15 or later. Available since driver version 2.1.0.

#### Response

`Record<string, any> | null` - either the same object returned by [`macos: startNativeScreenRecording`](#macos-startnativescreenrecording), or `null` if no native video recording is active.

### macos: stopNativeScreenRecording

Stops the active XCTest screen recording process started by [`macos: startNativeScreenRecording`](#macos-startnativescreenrecording),
either returning its payload or uploading it to a remote location. An exception is thrown if no
active XCTest screen recording process is found.

This feature requires Xcode 15 or later, and the Appium process must be granted filesystem
permissions in macOS System Settings -> _Privacy & Security_ -> _Full Disk Access_. Available
since driver version 2.1.0.

#### Arguments

| <div style="width:8em">Name</div> | <div style="width:9em">Type</div> | Description |
| --- | --- | --- |
| `remotePath?`| `string` | Path to a remote location where the resulting video file should be uploaded. Supported path protocols are HTTP(S) and FTP (deprecated). An exception is thrown if the file is too big to fit in the process memory. |
| `user?`| `string` | Username used for authentication to `remotePath` |
| `pass?`| `string` | Password used for authentication to `remotePath` |
| `method?`| `string` | Name of the HTTP(S) multipart upload method. Set to `PUT` by default. |
| `headers?`| `Record<string, any>` | Additional headers to use for the HTTP(S) multipart upload |
| `fileFieldName?`| `string` | Name of the form field for storing the file content blob for HTTP(S) uploads. Set to `file` by default. |
| `formFields?`| `Record<string, any>` or `Array<[string, any]>` | Additional form fields to use for the HTTP(S) multipart upload |
| `ignorePayload?`| `boolean` | Whether to skip retrieval of the raw video from the filesystem, instead returning an empty string. Useful if you prefer to fetch video chunks via the [`appium:mac2.nativeVideoRecordingChunkAdded` BiDi event](./bidi.md). Set to `false` by default. Available since driver version 2.2.0. |

#### Response

`string` - base64-encoded string of the video file, or an empty string if `remotePath` is provided
or no active screen recording process is found.

### macos: listDisplays

Retrieves information about the available displays. Available since driver version 2.1.0.

#### Response

`Record<string, Record<string, any>>` - an object where each key is a display identifier, and the
value is an object with the following structure:

| Key | Value Type | Description |
| --- | --- | --- |
| `id`| `number` | Display identifier |
| `isMain`| `boolean` | Whether this display is the main one |

### macos: setClipboard

Sets the macOS clipboard content. The existing clipboard content (if present) will be cleared.

Available since driver version 3.1.0.

#### Arguments

| <div style="width:7em">Name</div> | Type | Description |
| --- | --- | --- |
| `content`| `string` | The base64-encoded data to set the clipboard value to. |
| `contentType?`| `string` | The type of `content`. Supported values are `plaintext` (default), `image`, and `url`. If set to `image`, `content` must decode to a valid PNG or TIFF image payload. If set to `url`, `content` must decode to a valid URL. |

#### Response

`null`

### macos: getClipboard

Retrieves the macOS clipboard content as a base64-encoded string.

Available since driver version 3.1.0.

#### Arguments

| <div style="width:7em">Name</div> | Type | Description |
| --- | --- | --- |
| `contentType?`| `string` | The type in which to parse the clipboard content. Supported values are `plaintext` (default), `image`, and `url`. |

#### Response

`string` - the base64-encoded clipboard contents, or an empty string if the clipboard contains no
data for the specified `contentType`.

### macos: performAccessibilityAudit

Performs an accessibility audit for the application under test.

This feature requires Xcode 15 or later. Available since driver version 3.3.0.

#### Arguments

| <div style="width:7em">Name</div> | <div style="width:8em">Type</div> | Description |
| --- | --- | --- |
| `auditTypes?`| `Array<string>` | List of audit type names to use. Supported values are defined in [XCUIAccessibilityAuditType](https://developer.apple.com/documentation/xcuiautomation/xcuiaccessibilityaudittype). Set to `['XCUIAccessibilityAuditTypeAll']` by default. |

#### Response

`Array<Record<string, any>>` - an array of audit issue objects, where each object has the following
structure:

| Key | Value Type | Description |
| --- | --- | --- |
| `detailedDescription`| `string` | Human-readable issue details |
| `compactDescription`| `string` | Short issue summary |
| `auditType`| `string` | The resolved audit type name |
| `element`| `string` | String representation of the affected element |
| `elementDescription`| `string` | Debug description of the affected element |
