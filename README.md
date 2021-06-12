Appium Mac2 Driver
====

This is Appium driver for automating macOS applications using Apple's [XCTest](https://developer.apple.com/documentation/xctest) framework.
The driver operates in scope of [W3C WebDriver protocol](https://www.w3.org/TR/webdriver/) with several custom extensions to cover operating-system specific scenarios.
The original idea and parts of the source code are borrowed from the Facebook's [WebDriverAgent](https://github.com/facebookarchive/WebDriverAgent) project.


## Requirements

On top of standard Appium requirements Mac2 driver also expects the following prerequisites:

- macOS 10.15 or later
- Xcode 12 or later should be installed
- Xcode Helper app should be enabled for Accessibility access. The app itself could be usually found at `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Xcode/Agents/Xcode Helper.app`. In order to enable Accessibility access for it simply open the parent folder in Finder: `open /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Xcode/Agents/` and drag & drop the `Xcode Helper` app to `Security & Privacy -> Privacy -> Accessibility` list of your `System Preferences`. This action must only be done once.


## Capabilities

Capability Name | Description
--- | ---
platformName | Should be set to `mac`
automationName | Must always be set to `mac2`. Values of automationName are compared case-insensitively.
appium:systemPort | The number of the port for the internal server to listen on. If not provided then Mac2Driver will use the default port `10100`.
appium:systemHost | The name of the host for the internal server to listen on. If not provided then Mac2Driver will use the default host address `127.0.0.1`. You could set it to `0.0.0.0` to make the server listening on all available network interfaces. It is also possible to set the particular interface name, for example `en1`.
appium:webDriverAgentMacUrl | Appium will connect to an existing WebDriverAgentMac instance at this URL instead of starting a new one. e.g. `http://192.168.10.1:10101`
appium:showServerLogs | Set it to `true` in order to include xcodebuild output to the Appium server log. `false` by default.
appium:bootstrapRoot | The full path to `WebDriverAgentMac` root folder where Xcode project of the server sources lives. By default this project is located in the same folder where the corresponding driver Node.js module lives.
appium:serverStartupTimeout | The number of milliseconds to wait util the WebDriverAgentMac project is built and started. `120000` by default
appium:bundleId | The bundle identifier of the application to automate, for example `com.apple.TextEdit`. This is an optional capability. If it is not provided then the session will be started without an application under test (actually, it will be Finder). If the application with the given identifier is not installed then an error will be thrown on session startup. If the application is already running then it will be moved to the foreground.
appium:arguments | Array of application command line arguments. This capability is only going to be applied if the application is not running on session startup.
appium:environment | A dictionary of environment variables (name->value) that are going to be passed to the application under test on top of environment variables inherited from the parent process. This capability is only going to be applied if the application is not running on session startup.
appium:skipAppKill | Whether to skip the termination of the application under test when the testing session quits. `false` by default. This capability is only going to be applied if `bundleId` is set.
appium:prerun | An object containing either `script` or `command` key. The value of each key must be a valid AppleScript script or command to be executed prior to the Mac2Driver session startup. See [AppleScript commands execution](#applescript-commands-execution) for more details. Example: `{command: 'do shell script "echo hello"'}`
appium:postrun | An object containing either `script` or `command` key. The value of each key must be a valid AppleScript script or command to be executed after Mac2Driver session is stopped. See [AppleScript commands execution](#applescript-commands-execution) for more details.
appium:noReset | Whether to restart the app whose bundle identifier was passed to capabilities as `bundleId` value if it was already running on the session startup (`false`, the default value) or just pick it up without changing the app state (`true`). Note that neither of `arguments` or `environment` capabilities will take effect if the app did not restart.


## Element Attributes

Mac2 driver supports the following element attributes:

Name | Description | Example
--- | --- | ---
elementType | Integer-encoded element class. See the official documentation on [XCUIElementType enumeration](https://developer.apple.com/documentation/xctest/xcuielementtype?language=objc) for more details. | '2'
frame | Coordinates of bounding element rectangle | {x: 1, y: 2.5, width: 100, height: 200}
placeholderValue | It is usually only present for text fields. For other element types it's mostly empty | 'my placeholder'
enabled | Contains `true` if the element is enabled | 'false'
selected | Contains `true` if the element is selected | 'false'
hittable | Contains `true` if the element is hittable | 'true'
label | Element's label value. Could be empty | 'my label'
title | Element's title value. Could be empty | 'my title'
identifier | Element's accessibility identifier. Could be empty | 'identifier'
value | The value could be different depending on the actual element type. For example, text fields might have their text context there and sliders would contain the float position value, while switches would have either `1` or `0` | '1.5'

These attribute values could be retrieved from the page source output and then used for elements location. See the official documentation on [XCUIElementAttributes protocol](https://developer.apple.com/documentation/xctest/xcuielementattributes?language=objc) for more details on each attribute.

## Element Location

Mac2 driver supports the following location strategies:

Name | Description | Example
--- | --- | ---
accessibilityId, id, name | These all strategies are mapped to the same Mac2 driver ByIdentifier lookup strategy. The locator matches the passed value with element's `identifer` attribute case-sensitively. | `MobileBy.accessibilityId("identifier")`, `By.id("identifier")`, `By.name("identifier")`
className | Class name uses stringified element types for lookup | `By.className("XCUIElementTypePopUpButton")`
predicate | Lookup by predicate is natively supported by XCTest and is as fast as previous lookup strategies. This lookup strategy could only use the supported [element attributes](#element-attributes). Unknown attribute names would throw an exception. Check [NSPredicate cheat sheet](https://academy.realm.io/posts/nspredicate-cheatsheet/) for more details on how to build effective and flexible locators. | `MobileBy.iOSNsPredicateString("elementType == 2 AND label BEGINSWITH 'Safari'")`
classChain | This strategy is a combination of Xpath flexibility and fast predicate lookup. Prefer it over Xpath unless there is no other way to build the desired locator. Visit [Class Chain Construction Rules tutorial](https://github.com/facebookarchive/WebDriverAgent/wiki/Class-Chain-Queries-Construction-Rules) to get more knowledge on how to build class chain locators. | `MobileBy.iOSClassChain("**/XCUIElementTypeRuler[$elementType == 72 AND value BEGINSWITH '10'$]"`)
xpath | For elements lookup Xpath strategy the driver uses the same XML tree that is generated by page source API. Only Xpath 1.0 is supported (based on xmllib2). | `By.xpath("//XCUIElementTypePopUpButton[@value="Regular" and @label="type face"]")`

Check the [integration tests](/test/functional/find-e2e-specs.js) for more examples on different location strategies usage.


## Platform-Specific Extensions

Beside of standard W3C APIs the driver provides the following custom command extensions to execute platform specific scenarios:

### macos: click

Perform click gesture on an element or by relative/absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
elementId ("element" prior to Appium v 1.22) | string | if `x` or `y` are unset | Unique identifier of the element to perform the click on. Either this property or/and x and y must be set. If both are set then x and y are considered as relative element coordinates. If only x and y are set then these are parsed as absolute coordinates. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
x | number | if `y` is set or `elementId` is unset | click X coordinate | 100
y | number | if `y` is set or `elementId` is unset | click Y coordinate | 100
keyModifierFlags | number | no | if set then the given key modifiers will be applied while click is performed. See the official documentation on [XCUIKeyModifierFlags enumeration](https://developer.apple.com/documentation/xctest/xcuikeymodifierflags) for more details | `1 << 1 | 1 << 2`

#### References

- [click (XCUIElement)](https://developer.apple.com/documentation/xctest/xcuielement/1500316-click?language=objc)
- [click (XCUICoordinate)](https://developer.apple.com/documentation/xctest/xcuicoordinate/1500677-click?language=objc)

### macos: scroll

Perform scroll gesture on an element or by relative/absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
elementId ("element" prior to Appium v 1.22) | string | if `x` or `y` are unset | Unique identifier of the element to be scrolled. Either this property or/and x and y must be set. If both are set then x and y are considered as relative element coordinates. If only x and y are set then these are parsed as absolute coordinates. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
x | number | if `y` is set or `elementId` is unset | scroll X coordinate | 100
y | number | if `y` is set or `elementId` is unset | scroll Y coordinate | 100
deltaX | number | yes | Horizontal delta as float number. Could be negative | 100
deltaY | number | yes | vertical delta as float number. Could be negative | 100
keyModifierFlags | number | no | if set then the given key modifiers will be applied while scroll is performed. See the official documentation on [XCUIKeyModifierFlags enumeration](https://developer.apple.com/documentation/xctest/xcuikeymodifierflags) for more details | `1 << 1 | 1 << 2`

#### References

- [scrollByDeltaX:deltaY: (XCUIElement)](https://developer.apple.com/documentation/xctest/xcuielement/1500758-scrollbydeltax?language=objc)
- [scrollByDeltaX:deltaY: (XCUICoordinate)](https://developer.apple.com/documentation/xctest/xcuicoordinate?language=objc)

### macos: rightClick

Perform right click gesture on an element or by relative/absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
elementId ("element" prior to Appium v 1.22) | string | if `x` or `y` are unset | Unique identifier of the element to perform the right click on. Either this property or/and x and y must be set. If both are set then x and y are considered as relative element coordinates. If only x and y are set then these are parsed as absolute coordinates. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
x | number | if `y` is set or `elementId` is unset | right click X coordinate | 100
y | number | if `y` is set or `elementId` is unset | right click Y coordinate | 100
keyModifierFlags | number | no | if set then the given key modifiers will be applied while right click is performed. See the official documentation on [XCUIKeyModifierFlags enumeration](https://developer.apple.com/documentation/xctest/xcuikeymodifierflags) for more details | `1 << 1 | 1 << 2`

#### References

- [rightClick (XCUIElement)](https://developer.apple.com/documentation/xctest/xcuielement/1500469-rightclick?language=objc)
- [rightClick (XCUICoordinate)](https://developer.apple.com/documentation/xctest/xcuicoordinate/1500503-rightclick?language=objc)

### macos: rightClick

### macos: hover

Perform hover gesture on an element or by relative/absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
elementId ("element" prior to Appium v 1.22) | string | if `x` or `y` are unset | Unique identifier of the element to perform the hover on. Either this property or/and x and y must be set. If both are set then x and y are considered as relative element coordinates. If only x and y are set then these are parsed as absolute coordinates. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
x | number | if `y` is set or `elementId` is unset | long click X coordinate | 100
y | number | if `y` is set or `elementId` is unset | long click Y coordinate | 100
keyModifierFlags | number | no | if set then the given key modifiers will be applied while hover is performed. See the official documentation on [XCUIKeyModifierFlags enumeration](https://developer.apple.com/documentation/xctest/xcuikeymodifierflags) for more details | `1 << 1 | 1 << 2`

#### References

- [hover (XCUIElement)](https://developer.apple.com/documentation/xctest/xcuielement/1500437-hover?language=objc)
- [hover (XCUICoordinate)](https://developer.apple.com/documentation/xctest/xcuicoordinate/1501021-hover?language=objc)

### macos: doubleClick

Perform double click gesture on an element or by relative/absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
elementId ("element" prior to Appium v 1.22) | string | if `x` or `y` are unset | Unique identifier of the element to perform the double click on. Either this property or/and x and y must be set. If both are set then x and y are considered as relative element coordinates. If only x and y are set then these are parsed as absolute coordinates. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
x | number | if `y` is set or `elementId` is unset | double click X coordinate | 100
y | number | if `y` is set or `elementId` is unset | double click Y coordinate | 100
keyModifierFlags | number | no | if set then the given key modifiers will be applied while click is performed. See the official documentation on [XCUIKeyModifierFlags enumeration](https://developer.apple.com/documentation/xctest/xcuikeymodifierflags) for more details | `1 << 1 | 1 << 2`

#### References

- [doubleClick (XCUIElement)](https://developer.apple.com/documentation/xctest/xcuielement/1500571-doubleclick?language=objc)
- [doubleClick (XCUICoordinate)](https://developer.apple.com/documentation/xctest/xcuicoordinate/1500302-doubleclick?language=objc)

### macos: clickAndDrag

Perform long click and drag gesture on an element or by absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
sourceElementId ("sourceElement" prior to Appium v 1.22) | string | if `startX`, `startY`, `endX` and `endY` are unset or if `destinationElementId` is set | Uuid of the element to start the drag from. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
destinationElementId ("destinationElement" prior to Appium v 1.22) | string | if `startX`, `startY`, `endX` and `endY` are unset or if `sourceElementId` is set | Uuid of the element to end the drag on. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0745
startX | number | if `sourceElementId` and `destinationElementId` are unset | starting X coordinate | 100
startY | number | if `sourceElementId` and `destinationElementId` are unset | starting Y coordinate | 110
endX | number | if `sourceElementId` and `destinationElementId` are unset | end X coordinate | 200
endY | number | if `sourceElementId` and `destinationElementId` are unset | end Y coordinate | 220
duration | number | yes | The number of float seconds to hold the mouse button | 2.5
keyModifierFlags | number | no | if set then the given key modifiers will be applied while drag is performed. See the official documentation on [XCUIKeyModifierFlags enumeration](https://developer.apple.com/documentation/xctest/xcuikeymodifierflags) for more details | `1 << 1 | 1 << 2`

#### References

- [clickForDuration:thenDragToElement (XCUIElement)](https://developer.apple.com/documentation/xctest/xcuielement/1500989-clickforduration?language=objc)
- [clickForDuration:thenDragToCoordinate: (XCUICoordinate)](https://developer.apple.com/documentation/xctest/xcuicoordinate/1500369-clickforduration?language=objc)

### macos: clickAndDragAndHold

Perform long click, drag and hold gesture on an element or by absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
sourceElementId ("sourceElement" prior to Appium v 1.22) | string | if `startX`, `startY`, `endX` and `endY` are unset or if `destinationElementId` is set | Uuid of the element to start the drag from. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
destinationElementId ("destinationElement" prior to Appium v 1.22) | string | if `startX`, `startY`, `endX` and `endY` are unset or if `sourceElementId` is set | Uuid of the element to end the drag on. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0745
startX | number | if `sourceElementId` and `destinationElementId` are unset | starting X coordinate | 100
startY | number | if `sourceElementId` and `destinationElementId` are unset | starting Y coordinate | 110
endX | number | if `sourceElementId` and `destinationElementId` are unset | end X coordinate | 200
endY | number | if `sourceElementId` and `destinationElementId` are unset | end Y coordinate | 220
duration | number | yes | The number of float seconds to hold the mouse button | 2.5
velocity | number | no | Dragging velocity in pixels per second. If not provided then the default velocity is used. See official documentation on [XCUIGestureVelocity structure](https://developer.apple.com/documentation/xctest/xcuigesturevelocity) for more details | 2500
keyModifierFlags | number | no | if set then the given key modifiers will be applied while drag is performed. See the official documentation on [XCUIKeyModifierFlags enumeration](https://developer.apple.com/documentation/xctest/xcuikeymodifierflags) for more details | `1 << 1 | 1 << 2`

#### References

- [clickForDuration:thenDragToElement:withVelocity:thenHoldForDuration: (XCUIElement)](https://developer.apple.com/documentation/xctest/xcuielement/3553192-clickforduration?language=objc)
- [clickForDuration:thenDragToCoordinate:withVelocity:thenHoldForDuration: (XCUICoordinate)](https://developer.apple.com/documentation/xctest/xcuicoordinate/3553191-clickforduration?language=objc)

### mobile: swipe

This extension performs a swipe gesture on the particular screen element or by given coordinates.
The API is only available on macOS since Xcode SDK 13.

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
elementId ("element" prior to Appium v 1.22) | string | if `x` or `y` are unset | The internal element identifier (as hexadecimal hash string) to swipe on. If both are set then x and y are considered as relative element coordinates. If only x and y are set then these are parsed as absolute coordinates. | fe50b60b-916d-420b-8728-ee2072ec53eb
x | number | if `y` is set or `elementId` is unset | long click X coordinate | 100
y | number | if `y` is set or `elementId` is unset | long click Y coordinate | 100
direction | Either 'up', 'down', 'left' or 'right' | yes | The direction in which to swipe | up
velocity | number | no | The value is measured in pixels per second and same values could behave differently on different devices depending on their display density. Higher values make swipe gesture faster (which usually scrolls larger areas if we apply it to a list) and lower values slow it down. Only values greater than zero have effect. | 250
keyModifierFlags | number | no | if set then the given key modifiers will be applied while swipe is performed. See the official documentation on [XCUIKeyModifierFlags enumeration](https://developer.apple.com/documentation/xctest/xcuikeymodifierflags) for more details | `1 << 1 | 1 << 2`

#### References

- [swipeDown (XCUIElement)](https://developer.apple.com/documentation/xctest/xcuielement/1618664-swipedown?language=objc)
- [swipeDown (XCUICoordinate)](https://developer.apple.com/documentation/xctest/xcuicoordinate/3752780-swipedown?language=objc)
- [swipeDownWithVelocity: (XCUIElement)](https://developer.apple.com/documentation/xctest/xcuielement/3551694-swipedownwithvelocity?language=objc)
- [swipeDownWithVelocity: (XCUICoordinate)](https://developer.apple.com/documentation/xctest/xcuicoordinate/3752781-swipedownwithvelocity?language=objc)
- ...

### macos: press

Perform press gesture on a Touch Bar element or by relative/absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
elementId | string | if `x` or `y` are unset | Unique identifier of a Touch Bar element to perform the press on. Either this property or/and x and y must be set. If both are set then x and y are considered as relative element coordinates. If only x and y are set then these are parsed as absolute Touch Bar coordinates. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
x | number | if `y` is set or `elementId` is unset | long click X coordinate | 100
y | number | if `y` is set or `elementId` is unset | long click Y coordinate | 100
duration | number | yes | The number of float seconds to hold the touch | 2.5
keyModifierFlags | number | no | if set then the given key modifiers will be applied while the gesture is performed. See the official documentation on [XCUIKeyModifierFlags enumeration](https://developer.apple.com/documentation/xctest/xcuikeymodifierflags) for more details | `1 << 1 | 1 << 2`

#### References

- [pressForDuration: (XCUIElement)](https://developer.apple.com/documentation/xctest/xcuielement/1618663-pressforduration?language=objc)
- [pressForDuration: (XCUICoordinate)](https://developer.apple.com/documentation/xctest/xcuicoordinate/1615002-pressforduration?language=objc)

### macos: tap

Perform tap gesture on a Touch Bar element or by relative/absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
elementId | string | if `x` or `y` are unset | Unique identifier of a Touch Bar element to perform the tap on. Either this property or/and x and y must be set. If both are set then x and y are considered as relative element coordinates. If only x and y are set then these are parsed as absolute Touch Bar coordinates. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
x | number | if `y` is set or `elementId` is unset | click X coordinate | 100
y | number | if `y` is set or `elementId` is unset | click Y coordinate | 100
keyModifierFlags | number | no | if set then the given key modifiers will be applied while the gesture is performed. See the official documentation on [XCUIKeyModifierFlags enumeration](https://developer.apple.com/documentation/xctest/xcuikeymodifierflags) for more details | `1 << 1 | 1 << 2`

#### References

- [tap (XCUIElement)](https://developer.apple.com/documentation/xctest/xcuielement/1618666-tap?language=objc)
- [tap (XCUICoordinate)](https://developer.apple.com/documentation/xctest/xcuicoordinate/1615004-tap?language=objc)

### macos: doubleTap

Perform double tap gesture on a Touch Bar element or by relative/absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
elementId | string | if `x` or `y` are unset | Unique identifier of a Touch Bar element to perform the double tap on. Either this property or/and x and y must be set. If both are set then x and y are considered as relative element coordinates. If only x and y are set then these are parsed as absolute Touch Bar coordinates. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
x | number | if `y` is set or `elementId` is unset | click X coordinate | 100
y | number | if `y` is set or `elementId` is unset | click Y coordinate | 100
keyModifierFlags | number | no | if set then the given key modifiers will be applied while the gesture is performed. See the official documentation on [XCUIKeyModifierFlags enumeration](https://developer.apple.com/documentation/xctest/xcuikeymodifierflags) for more details | `1 << 1 | 1 << 2`

#### References

- [doubleTap (XCUIElement)](https://developer.apple.com/documentation/xctest/xcuielement/1618673-doubletap?language=objc)
- [doubleTap (XCUICoordinate)](https://developer.apple.com/documentation/xctest/xcuicoordinate/1615005-doubletap?language=objc)

### macos: pressAndDrag

Perform long press and drag gesture on a Touch Bar element or by absolute Touch Bar coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
sourceElementId | string | if `startX`, `startY`, `endX` and `endY` are unset or if `destinationElementId` is set | Uuid of a Touch Bar element to start the drag from. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
destinationElementId | string | if `startX`, `startY`, `endX` and `endY` are unset or if `sourceElementId` is set | Uuid of a Touch Bar element to end the drag on. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0745
startX | number | if `sourceElementId` and `destinationElementId` are unset | starting X coordinate | 100
startY | number | if `sourceElementId` and `destinationElementId` are unset | starting Y coordinate | 110
endX | number | if `sourceElementId` and `destinationElementId` are unset | end X coordinate | 200
endY | number | if `sourceElementId` and `destinationElementId` are unset | end Y coordinate | 220
duration | number | yes | The number of float seconds to hold the touch | 2.5
keyModifierFlags | number | no | if set then the given key modifiers will be applied while the gesture is performed. See the official documentation on [XCUIKeyModifierFlags enumeration](https://developer.apple.com/documentation/xctest/xcuikeymodifierflags) for more details | `1 << 1 | 1 << 2`

#### References

- [pressForDuration:thenDragToElement: (XCUIElement)](https://developer.apple.com/documentation/xctest/xcuielement/1618670-pressforduration?language=objc)
- [pressForDuration:thenDragToCoordinate: (XCUICoordinate)](https://developer.apple.com/documentation/xctest/xcuicoordinate/1615003-pressforduration?language=objc)

### macos: pressAndDragAndHold

Perform long press, drag and hold gesture on a Touch Bar element or by absolute Touch Bar coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
sourceElementId | string | if `startX`, `startY`, `endX` and `endY` are unset or if `destinationElementId` is set | Uuid of a Touch Bar element to start the drag from. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
destinationElementId | string | if `startX`, `startY`, `endX` and `endY` are unset or if `sourceElementId` is set | Uuid of a Touch Bar element to end the drag on. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0745
startX | number | if `sourceElementId` and `destinationElementId` are unset | starting X coordinate | 100
startY | number | if `sourceElementId` and `destinationElementId` are unset | starting Y coordinate | 110
endX | number | if `sourceElementId` and `destinationElementId` are unset | end X coordinate | 200
endY | number | if `sourceElementId` and `destinationElementId` are unset | end Y coordinate | 220
duration | number | yes | The number of float seconds to hold the touch | 2.5
velocity | number | no | Dragging velocity in pixels per second. If not provided then the default velocity is used. See official documentation on [XCUIGestureVelocity structure](https://developer.apple.com/documentation/xctest/xcuigesturevelocity) for more details | 2500
keyModifierFlags | number | no | if set then the given key modifiers will be applied while the gesture is performed. See the official documentation on [XCUIKeyModifierFlags enumeration](https://developer.apple.com/documentation/xctest/xcuikeymodifierflags) for more details | `1 << 1 | 1 << 2`

#### References

- [pressForDuration:thenDragToElement:withVelocity:thenHoldForDuration: (XCUIElement)](https://developer.apple.com/documentation/xctest/xcuielement/3551693-pressforduration?language=objc)
- [pressForDuration:thenDragToCoordinate:withVelocity:thenHoldForDuration: (XCUICoordinate)](https://developer.apple.com/documentation/xctest/xcuicoordinate/3551692-pressforduration?language=objc)

### macos: keys

Send keys to the given element or to the application under test

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
elementId ("element" prior to Appium v 1.22) | string | no | Unique identifier of the element to send the keys to. If unset then keys are sent to the current application under test. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
keys | array | yes | Array of keys to type. Each item could either be a string, that represents a key itself (see the official documentation on XCUIElement's [typeKey:modifierFlags: method](https://developer.apple.com/documentation/xctest/xcuielement/1500604-typekey?language=objc) and on [XCUIKeyboardKey constants](https://developer.apple.com/documentation/xctest/xcuikeyboardkey?language=objc)) or a dictionary with `key` and `modifierFlags` entries, if the key should also be entered with modifiers. | ['h', 'i'] or [{key: 'h', modifierFlags: 1 << 1}, {key: 'i', modifierFlags: 1 << 2}] or ['XCUIKeyboardKeyEscape'] |

#### References

- [typeKey:modifierFlags:](https://developer.apple.com/documentation/xctest/xcuielement/1500604-typekey?language=objc)

### macos: source

Retrieves the string representation of the current application

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
format | string | yes | The format of the application source to retrieve. Only two formats are supported: `xml` (returns the source formatted as XML document, the default value) and `description` (returns the source formatted as debugDescription output). See the official documentation on XCUIElement's [debugDescription method](https://developer.apple.com/documentation/xctest/xcuielement/1500909-debugdescription?language=objc) for more details. | description

#### Returns

The source of the current page in a string representation

### macos: launchApp

Start an app with the given bundle identifier or activates it if the app is already running. An exception is thrown if the app with the given identifier cannot be found.
This API influences the state of the [Application Under Test](#application-under-test-concept).

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
bundleId | string | yes | bundle identifier of the app to be launched or activated | com.apple.TextEdit
arguments | array | no | the list of command line arguments for the app to be be launched with. This argument is ignored if the app is already running. | ['--help']
environment | dictionary | no | Environment variables mapping. Custom variables are added to the default process environment. This argument is ignored if the app is already running. | { myEnvVar: 'value' }

### macos: activateApp

Activates an app with the given bundle identifier. An exception is thrown if the app with the given identifier cannot be found or if the app is not running.
This API influences the state of the [Application Under Test](#application-under-test-concept).

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
bundleId | string | yes | bundle identifier of the app to be activated | com.apple.Finder

### macos: terminateApp

Terminate an app with the given bundle identifier. An exception is thrown if the app cannot be found.
This API influences the state of the [Application Under Test](#application-under-test-concept).

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
bundleId | string | yes | bundle identifier of the app to be terminated | com.apple.Finder

#### Returns

`true` if the app was running before being terminated

### macos: queryAppState

Query an app state with given bundle identifier. An exception is thrown if the pp cannot be found.

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
bundleId | string | yes | bundle identifier of the app to be queried | com.apple.TextEdit

#### Returns

An integer value representing the application state. See the official documentation on [XCUIApplicationState enumeration](https://developer.apple.com/documentation/xctest/xcuiapplicationstate?language=objc) for more details.

### macos: appleScript

Executes the given AppleScript command or a whole script based on the
given options. Either of these options must be provided. If both are provided
then the `command` one gets the priority.
Note that AppleScript command cannot contain line breaks. Consider making it
to a script in such case.
Note that by default AppleScript engine blocks commands/scripts execution if your script
is trying to access some private entities, like cameras or the desktop screen
and no permissions to do it are given to the parent (for example, Appium or Terminal)
process in System Preferences -> Privacy list.
See [AppleScript Commands Execution](#applescript-commands-execution) for more details.

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
command | string | yes if `script` is not provided | AppleScript command to execute | `do shell script "echo hello"`
script | string | yes if `command` is not provided | AppleScript script to execute | `do shell script "echo hello"\ndo shell script "echo hello2"`
language | string | no | Overrides the scripting language. Basically, sets the value of `-l` command line argument of `osascript` tool. If unset the AppleScript language is assumed. | JavaScript
timeout | number | no | The number of seconds to wait until a long-running blocking command is finished. An error is thrown if the command is still running after this timeout expires. | 60000
cwd | string | no | The path to an existing folder which is going to be set as the working directory for the command/script being executed. | `/tmp`

#### Returns

The actual stdout of the provided script if its execution was successful (e.g. got zero return code).

### macos: startRecordingScreen

Record the display in background while the automated test is running. This method requires [FFMPEG](https://www.ffmpeg.org/download.html) to be installed and present in PATH. Also, the Appium process must be allowed to access screen recording in System Preferences->Security & Privacy->Screen Recording. The resulting video uses H264 codec and is ready to be played by media players built-in into web browsers.

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
deviceId | number | yes | Screen device index to use for the recording. The list of available devices could be retrieved using `ffmpeg -f avfoundation -list_devices true -i` command. | 1
videoFilter | string | no | The video filter spec to apply for ffmpeg. See https://trac.ffmpeg.org/wiki/FilteringGuide for more details on the possible values. | Set it to `scale=ifnot(gte(iw\,1024)\,iw\,1024):-2` in order to limit the video width to 1024px. The height will be adjusted automatically to match the actual ratio.
fps | number | no | The count of frames per second in the resulting video. The greater fps it has the bigger file size is. The default vale is `15` | 10
preset | string | no | One of the supported encoding presets. Possible values are: `ultrafast`, `superfast`, `veryfast` (the default value), `faster`, `fast`, `medium`, `slow`, `slower`, `veryslow`. A preset is a collection of options that will provide a certain encoding speed to compression ratio. A slower preset will provide better compression (compression is quality per filesize). This means that, for example, if you target a certain file size or constant bit rate, you will achieve better quality with a slower preset. Read https://trac.ffmpeg.org/wiki/Encode/H.264 for more details. | fast
captureCursor | boolean | no | Whether to capture the mouse cursor while recording the screen. `false` by default | true
captureClicks | boolean | no | Whether to capture mouse clicks while recording the screen. `false` by default | true
timeLimit | number | no | The maximum recording time, in seconds. The default value is 600 seconds (10 minutes) | 300
forceRestart | boolean | no | Whether to ignore the call if a screen recording is currently running (`false`) or to start a new recording immediately and terminate the existing one if running (`true`, the default value). | true

### macos: stopRecordingScreen

Stop recording the screen. If no screen recording has been started before then the method returns an empty string.

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
remotePath | string | no | The path to the remote location, where the resulting video should be uploaded. The following protocols are supported: http/https, ftp. Null or empty string value (the default setting) means the content of resulting file should be encoded as Base64 and passed as the endpoint response value. An exception will be thrown if the generated media file is too big to fit into the available process memory. | https://myserver.com/upload/video.mp4
user | string | no | The name of the user for the remote authentication. | myname
pass | string | no | The password for the remote authentication. | mypassword
method | string | no | The http multipart upload method name. The 'PUT' one is used by default. | POST
headers | map | no | Additional headers mapping for multipart http(s) uploads | `{"header": "value"}`
fileFieldName | string | no | The name of the form field, where the file content BLOB should be stored for http(s) uploads. `file` by default | payload
formFields | Map or `Array<Pair>` | no | Additional form fields for multipart http(s) uploads | `{"field1": "value1", "field2": "value2"}` or `[["field1", "value1"], ["field2", "value2"]]`

#### Returns

Base64-encoded content of the recorded media file if `remotePath` parameter is falsy or an empty string.


## Application Under Test Concept

The Mac2 driver has the concept of `Application Under Test`. This is the app, whose bundle identifier has been passed as `bundleId` capability or as an argument to `macos: activateApp` or `macos: launchApp` extensions.
If this application is unexpectedly terminated during test session execution then an exception is going to be thrown upon any following session command invocation. In such case the driver assumes the application under test is crashed and it is impossible to proceed.
Also, the `Application Under Test` is going to be terminated when the testing session quits (unless canceled by `skipAppKill` capability).
It is possible to reset the `Application Under Test` value to none by executing `macos: terminateApp` helper and providing the bundle identifier of this app to it. Also, `macos: activateApp` or `macos: launchApp` calls can change `Application Under Test` value  if a bundle identifier different from the current one is provided to them.


## AppleScript Commands Execution

There is a possibility to run custom AppleScript
from your client code. This feature is potentially insecure and thus needs to be
explicitly enabled when executing the server by providing `apple_script` key to the list
of enabled insecure features. Check [Appium Security document](https://github.com/appium/appium/blob/master/docs/en/writing-running-appium/security.md) for more details.
It is possible to either execute a single AppleScript command (use the `command` argument)
or a whole script (use the `script` argument) and get its
stdout in response. If the script execution returns non-zero exit code then an exception
is going to be thrown. The exception message will contain the actual stderr.
If the script is a blocking one then it could only run up to 20 seconds long. After that the script
will be terminated and a timeout error will be thrown. This timeout could be customized by
providing the `timeout` option value.
You could also customize the script working directory by providing the `cwd` option.
Here's an example code of how to get a shell command output:

```java
// java
String appleScript = "do shell script \"echo hello\"";
System.println(driver.executeScript("macos: appleScript", ImmutableMap.of("command", appleScript)));
```


## W3C Action Recipes

In theory it is possible to emulate a mouse gesture of any complexity with W3C actions.
However, there is a set of "standard" gestures, where each operating system has its own
requirements, like clicks, double clicks, etc. All such action parameters
must comply with these requirements to be recognized properly. Here is a short list of
examples for the most common macOS pointer gestures:

### Click

```json
[
  {"type": "pointerMove", "duration": 10, "x": 100, "y": 100},
  {"type": "pointerDown", "button": 0},
  {"type": "pause", "duration": 100},
  {"type": "pointerUp", "button": 0}
]
```

The duration of mouse button suppression should be 0-125 ms.

### Right Click

```json
[
  {"type": "pointerMove", "duration": 10, "x": 100, "y": 100},
  {"type": "pointerDown", "button": 2},
  {"type": "pointerUp", "button": 2}
]
```

The duration of mouse button suppression should be 0-125 ms.

### Double Click

```json
[
  {"type": "pointerMove", "duration": 10, "x": 100, "y": 100},
  {"type": "pointerDown", "button": 0},
  {"type": "pointerUp", "button": 0},
  {"type": "pause", "duration": 1000},
  {"type": "pointerDown", "button": 0},
  {"type": "pointerUp", "button": 0}
]
```

The duration between two clicks should be 600-1000 ms.

### Drag & Drop

```json
[
  {"type": "pointerMove", "duration": 10, "x": 100, "y": 100},
  {"type": "pointerDown", "button": 0},
  {"type": "pause", "duration": 600},
  {"type": "pointerMove", "duration": 10, "x": 200, "y": 200},
  {"type": "pointerUp", "button": 0}
]
```

The longer is the duration of the second `pointerMove` action the lesser is the drag velocity
and vice versa. One could add more `pointerMove` actions before releasing the mouse button
to simulate complex cursor moving paths. Mac2Driver terminates action execution with a timeout
error if the duration of it exceeds 5 minutes.

### Hover

```json
[
  {"type": "pointerMove", "duration": 10, "x": 100, "y": 100},
  {"type": "pointerMove", "duration": 1000, "x": 200, "y": 200}
]
```

This snippet tells the mouse pointer to hover over [100, 100, 200, 200] area for 1 second.
In general, hover action will be performed every time if there is no preceding `pointerDown`
to the current `pointerMove` one or the preceding `pointerDown` action has been ended by
the `pointerUp` one.


## Settings API

Mac2Driver supports Appium [Settings API](https://appium.io/docs/en/advanced-concepts/settings/).
Along with the common settings the following driver-specific settings are currently available:

Name | Type | Description
--- | --- | ---
boundElementsByIndex | boolean | Whether to use elements binding by index (`true`) or by accessibility identifier (the default setting, `false`). It makes sense to switch the binding strategy to workaround stale element reference errors containing `Identity Binding` text in their descriptions. See the corresponding [Stack Overflow discussion](https://stackoverflow.com/questions/49307513/meaning-of-allelementsboundbyaccessibilityelement) to know more details on the difference between these two binding strategies.
useDefaultUiInterruptionsHandling | boolean | Whether to use the default XCTest UI interruptions handling (`true`, the default setting) or to disable it for the [Application Under Test](#application-under-test-concept) (`false`). It makes sense to disable the default handler if it is necessary to validate the interrupting element's presence in your test or do some other actions on it rather than just closing the view implicitly. Check [this WWDC presentation](https://developer.apple.com/videos/play/wwdc2020/10220/) from Apple to get more details on the UI interruptions handling.


## Examples

```python
# Python3 + PyTest
import pytest

from appium import webdriver


@pytest.fixture()
def driver():
    drv = webdriver.Remote('http://localhost:4723/wd/hub', {
        # automationName capability presence is mandatory for this Mac2 Driver to be selected
        'automationName': 'Mac2',
        'platformName': 'mac',
        'bundleId': 'com.apple.TextEdit',
    })
    yield drv
    drv.quit()


def test_edit_text(driver):
    edit_field = driver.find_element_by_class_name('XCUIElementTypeTextView')
    edit_field.send_keys('hello world')
    assert edit_field.text == 'hello world'
    edit_field.clear()
    assert edit_field.text == ''


def test_sending_custom_keys(driver):
    edit_field = driver.find_element_by_class_name('XCUIElementTypeTextView')
    flagsShift = 1 << 1
    driver.execute_script('macos: keys', {
        'keys': [{
            'key': 'h',
            'modifierFlags': flagsShift,
        }, {
            'key': 'i',
            'modifierFlags': flagsShift,
        }]
    })
    assert edit_field.text == 'HI'

```


## Parallel Execution

Parallel execution of multiple Mac2 driver instances is highly discouraged. Only one UI test must be running at the same time, since the access to accessibility layer is single-threaded. Also HID devices, like the mouse or the keyboard, must be acquired exclusively.


## Development & Testing

This module uses the same [development tools](https://github.com/appium/appium/tree/master/docs/cn/contributing-to-appium) as the other Appium drivers.

Check out the source. Then run:

```bash
npm install
gulp watch
```

Execute `npm run test` to run unit tests and `npm run e2e-test` to run integration tests.


## Notes

- W3C actions support is limited (only mouse actions are supported). You could also use `macos:` extension APIs to cover your test scenarios
