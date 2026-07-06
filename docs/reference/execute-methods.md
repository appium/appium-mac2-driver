---
title: Execute Methods
---

The Mac2 driver provides many [custom execute methods](https://appium.io/docs/en/latest/guides/execute-methods/)
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