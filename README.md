Appium Mac2 Driver
====

[![NPM version](http://img.shields.io/npm/v/appium-mac2-driver.svg)](https://npmjs.org/package/appium-mac2-driver)
[![Downloads](http://img.shields.io/npm/dm/appium-mac2-driver.svg)](https://npmjs.org/package/appium-mac2-driver)

[![Release](https://github.com/appium/appium-mac2-driver/actions/workflows/publish.js.yml/badge.svg)](https://github.com/appium/appium-mac2-driver/actions/workflows/publish.js.yml)


This is Appium driver for automating macOS applications using Apple's [XCTest](https://developer.apple.com/documentation/xctest) framework.
The driver operates in scope of [W3C WebDriver protocol](https://www.w3.org/TR/webdriver/) with several custom extensions to cover operating-system specific scenarios.
The original idea and parts of the source code are borrowed from the Facebook's [WebDriverAgent](https://github.com/facebookarchive/WebDriverAgent) project.

> [!IMPORTANT]
> Since major version *2.0.0*, this driver is only compatible with Appium 3. Use the `appium driver install mac2`
> command to add it to your dist.


## Requirements

On top of standard Appium requirements Mac2 driver also expects the following prerequisites:

- macOS 11 or later
- Xcode 13 or later should be installed
    - `xcode-select` should be pointing to `<full_path_to_xcode_app>/Contents/Developer` developer directory instead of `/Library/Developer/CommandLineTools` to run `xcodebuild` commands
- Xcode Helper app should be enabled for Accessibility access. The app itself could be usually found at `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Xcode/Agents/Xcode Helper.app`. In order to enable Accessibility access for it simply open the parent folder in Finder: `open /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Xcode/Agents/` and drag & drop the `Xcode Helper` app to `Security & Privacy -> Privacy -> Accessibility` list of your `System Preferences`. This action must only be done once.
- `testmanagerd` process requires UIAutomation authentication since macOS 12. `automationmodetool enable-automationmode-without-authentication` command may help to disable it. This may be particularly useful in CI environments. [Apple forum thread](https://developer.apple.com/forums/thread/693850).

### Doctor

Since driver version 1.9.0 you can automate the validation for the most of the above
requirements as well as various optional ones needed by driver extensions by running the
`appium driver doctor mac2` server command.


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
appium:appPath | The path to the application to automate, for example `/Applications/MyAppName.app`. This is an optional capability, but it requires `bundleId` to be present until mac2 driver v1.13.0. In earlier versions if `bundleId` is empty, `appPath` would be ignored. If the path is invalid or application is damaged/incomplete then an error will be thrown on session startup. This capability could be useful when you have multiple builds of the same application with the same bundleId on your machine (for example one production build in /Applications/ and several dev builds). If you provide bundleId only, the operating system could open any of these builds. By providing `appPath` you have a guarantee that the specified .app will be launched, rather than a random one.
appium:appLocale | A dictionary with the following possible entries: `locale` (application locale name, for example `uk_UA`), `language` (application language name, for example `de`), `useMetricUnits` (whether to use metric units for the app, if `false` then imperial units are used), `measurementUnits` (the name of measurement units to use in the app, for example `Inches`). This capability only changes the locale for the app under test, it does not modify the system locale. You can achieve the same effect by providing custom values to reserved app command line arguments like `-AppleLanguages` or `-AppleLocale` using the `appium:arguments` capability. Example: use `appLocale = {locale: "de", language: "de_DE"}` to start the app in German language (if no German resources are defined in the destination app bundle then the app is started with the default locale, usually en_US).
appium:appTimeZone | Defines the custom time zone override for the application under test. You can use UTC, PST, EST, as well as place-based timezone names such as America/Los_Angeles. The application must be (re)launched for the capability to take effect. See the [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) for more details. The same behavior could be achieved by providing a custom value to the [TZ](https://developer.apple.com/forums/thread/86951#263395) environment variable via the `appium:environment` capability
appium:initialDeeplinkUrl | A deeplink URL used to run either the application assigned to `appium:bundleId`, or the default application assigned to handle the particular deeplink protocol if `appium:bundleId` is not set. An error is thrown on session init if either the value of the capability is not a valid URL, or XCTest was not able to associate it with any existing app, or the actual Xcode version is below *14.3*

## Element Attributes

Mac2 driver supports the following element attributes:

Name | Description | Example
--- | --- | ---
elementType | Integer-encoded element class. See the official documentation on [XCUIElementType enumeration](https://developer.apple.com/documentation/xctest/xcuielementtype?language=objc) for more details. | '2'
frame | Coordinates of bounding element rectangle | {x: 1, y: 2.5, width: 100, height: 200}
placeholderValue | It is usually only present for text fields. For other element types it's mostly empty | 'my placeholder'
enabled | Contains `true` if the element is enabled | 'false'
focused | Contains `true` if the element has the keyboard input focus | 'false'
selected | Contains `true` if the element is selected | 'false'
hittable | Contains `true` if the element is hittable | 'true'
label | Element's label value. Could be empty | 'my label'
title | Element's title value. Could be empty | 'my title'
identifier | Element's accessibility identifier. Could be empty | 'identifier'
value | The value could be different depending on the actual element type. For example, text fields might have their text context there and sliders would contain the float position value, while switches would have either `1` or `0` | '1.5'

These attribute values could be retrieved from the page source output and then used for elements location. See the official documentation on [XCUIElementAttributes protocol](https://developer.apple.com/documentation/xctest/xcuielementattributes?language=objc) for more details on each attribute.

## Element Location

Mac2 driver supports the following location strategies:

Name | Description | Speed Ranking | Pseudocode
--- | --- |  --- | ---
accessibilityId, id, name | These all strategies are mapped to the same Mac2 driver ByIdentifier lookup strategy. The locator matches the passed value with element's `identifier` attribute case-sensitively. | `⭐⭐⭐⭐⭐` | AppiumBy.accessibilityId("identifier"), By.id("identifier"), By.name("identifier")
className | Class name uses stringified element types for lookup | `⭐⭐⭐⭐⭐` | By.className("XCUIElementTypePopUpButton")
predicate | Lookup by predicate is natively supported by XCTest and is as fast as previous lookup strategies. This lookup strategy could only use the supported [element attributes](#element-attributes). Unknown attribute names would throw an exception. Check [NSPredicate cheat sheet](https://academy.realm.io/posts/nspredicate-cheatsheet/) for more details on how to build effective and flexible locators. | `⭐⭐⭐⭐⭐` | AppiumBy.iOSNsPredicateString("elementType == 2 AND label BEGINSWITH 'Safari'")
classChain | This strategy is a combination of Xpath flexibility and fast predicate lookup. Prefer it over Xpath unless there is no other way to build the desired locator. Visit [Class Chain Construction Rules tutorial](https://github.com/facebookarchive/WebDriverAgent/wiki/Class-Chain-Queries-Construction-Rules) to get more knowledge on how to build class chain locators. | `⭐⭐⭐⭐` | AppiumBy.iOSClassChain("**/XCUIElementTypeRuler[$elementType == 72 AND value BEGINSWITH '10'$]")
xpath | For elements lookup XPath strategy the driver uses the same XML tree that is generated by page source API. [XPath 2.0](https://www.w3.org/TR/xpath20/) is supported since driver version 1.20.0. All driver versions below 1.20.0 only support XPath 1.0 (based on xmllib2). | `⭐⭐⭐` | By.xpath("//XCUIElementTypePopUpButton[@value=\"Regular\" and @label=\"type face\"]")

Check the [integration tests](/test/functional/find-e2e-specs.js) for more examples on different location strategies usage.


## Platform-Specific Extensions

Beside of standard W3C APIs the driver provides the below custom command extensions to execute platform specific scenarios. Use the following source code examples in order to invoke them from your client code:

```java
// Java 11+
var result = driver.executeScript("macos: <methodName>", Map.of(
    "arg1", "value1",
    "arg2", "value2"
    // you may add more pairs if needed or skip providing the map completely
    // if all arguments are defined as optional
));
```

```js
// WebdriverIO
const result = await driver.executeScript('macos: <methodName>', [{
    arg1: "value1",
    arg2: "value2",
}]);
```

```python
# Python
result = driver.execute_script('macos: <methodName>', {
    'arg1': 'value1',
    'arg2': 'value2',
})
```

```ruby
# Ruby
result = @driver.execute_script 'macos: <methodName>', {
    arg1: 'value1',
    arg2: 'value2',
}
```

```csharp
// Dotnet
object result = driver.ExecuteScript("macos: <methodName>", new Dictionary<string, object>() {
    {"arg1", "value1"},
    {"arg2", "value2"}
});
```

### macos: click

Perform click gesture on an element or by relative/absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
elementId ("element" prior to Appium v 1.22) | string | if `x` or `y` are unset | Unique identifier of the element to perform the click on. Either this property or/and x and y must be set. If both are set then x and y are considered as relative element coordinates. If only x and y are set then these are parsed as absolute coordinates. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
x | number | if `y` is set or `elementId` is unset | click X coordinate | 100
y | number | if `x` is set or `elementId` is unset | click Y coordinate | 100
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
holdDuration | number | yes | Touch hold duration in float seconds | 2.5
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
holdDuration | number | yes | Touch hold duration in float seconds | 2.5
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

> [!NOTE]
> The `modifierFlags` argument is of `unsigned long` type and defines the bitmask with depressed modifier keys for the given key.
> XCTest defines the following possible bitmasks for modifier keys:
>
> <pre>
> typedef NS_OPTIONS(NSUInteger, XCUIKeyModifierFlags) {
>    XCUIKeyModifierNone       = 0,
>    XCUIKeyModifierCapsLock   = (1UL << 0),
>    XCUIKeyModifierShift      = (1UL << 1),
>    XCUIKeyModifierControl    = (1UL << 2),
>    XCUIKeyModifierOption     = (1UL << 3),
>    XCUIKeyModifierCommand    = (1UL << 4),
>    XCUIKeyModifierFunction   = (1UL << 5),
>    // These values align with UIKeyModifierFlags and CGEventFlags.
>    XCUIKeyModifierAlphaShift = XCUIKeyModifierCapsLock,
>    XCUIKeyModifierAlternate  = XCUIKeyModifierOption,
> };
> </pre>
>
> So, for example, if you want Ctrl and Shift to be depressed while entering your key then `modifierFlags` should be set to
> `(1 << 1) | (1 << 2)`, where the first constant defines `XCUIKeyModifierShift` and the seconds
> one - `XCUIKeyModifierControl`. We apply the [bitwise or](https://www.programiz.com/c-programming/bitwise-operators#or)
> (`|`) operator between them to raise both bitflags
> in the resulting value. The [left bitshift](https://www.programiz.com/c-programming/bitwise-operators#left-shift)
> (`<<`) operator defines the binary bitmask for the given modifier key.
> You may combine more keys using the same approach.

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
bundleId | string | no | Bundle identifier of the app to be launched or activated. Either this argument or the `path` one must be provided | com.apple.TextEdit
path | string | no | Full path to the app bundle. Either this argument or the `bundleId` one must be provided | /Applications/Xcode.app
arguments | array | no | the list of command line arguments for the app to be be launched with. This argument is ignored if the app is already running. | ['--help']
environment | dictionary | no | Environment variables mapping. Custom variables are added to the default process environment. This argument is ignored if the app is already running. | { myEnvVar: 'value' }

### macos: activateApp

Activates an app with the given bundle identifier. An exception is thrown if the app with the given identifier cannot be found or if the app is not running.
This API influences the state of the [Application Under Test](#application-under-test-concept).

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
bundleId | string | no | Bundle identifier of the app to be activated. Either this argument or the `path` one must be provided | com.apple.Finder
path | string | no | Full path to the app bundle. Either this argument or the `bundleId` one must be provided | /Applications/Xcode.app

### macos: terminateApp

Terminate an app with the given bundle identifier. An exception is thrown if the app cannot be found.
This API influences the state of the [Application Under Test](#application-under-test-concept).

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
bundleId | string | no | Bundle identifier of the app to be terminated. Either this argument or the `path` one must be provided | com.apple.Finder
path | string | no | Full path to the app bundle. Either this argument or the `bundleId` one must be provided | /Applications/Xcode.app

#### Returns

`true` if the app was running before being terminated

### macos: queryAppState

Query an app state with given bundle identifier. An exception is thrown if the pp cannot be found.

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
bundleId | string | no | Bundle identifier of the app to be queried. Either this argument or the `path` one must be provided | com.apple.TextEdit
path | string | no | Full path to the app bundle. Either this argument or the `bundleId` one must be provided | /Applications/Xcode.app

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

### macos: screenshots

Retrieves a screenshot of each display available to macOS.

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
displayId | number | no | Display identifier to take a screenshot for. If not provided then all display screenshots are going to be returned. If no matches were found then an error is thrown. Use the `system_profiler -json SPDisplaysDataType` Terminal command to list IDs of connected displays or the [macos: listDisplays](#macos-listdisplays) API. | 1

#### Returns

A list of dictionaries where each item has the following keys:
- `id`: Display identifier
- `isMain`: Whether this display is the main one
- `payload`: The actual PNG screenshot data encoded to base64 string

### macos: deepLink

Opens the given URL with the default or the given application.
Xcode must be at version 14.3+.

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
url | string | yes | The URL to be opened. This parameter is manadatory. | https://apple.com, myscheme:yolo
bundleId | string | no | The bundle identifier of an application to open the given url with. If not provided then the default application for the given url scheme is going to be used. | com.myapp.yolo

### macos: startNativeScreenRecording

Initiates a new native screen recording session via XCTest.
If the screen recording is already running then this call results in noop.
A screen recording is running until a testing session is finished.
If a recording has never been stopped explicitly during a test session
then it would be stopped automatically upon the test session termination,
and leftover videos would be deleted as well.
Xcode must be at version 15+.

> [!TIP]
> Invocation of this API also triggers broadcasting of
> [appium:mac2.nativeVideoRecordingChunkAdded](./docs/bidi.md#appiummac2nativevideorecordingchunkadded)
> BiDi events. Make sure to subscribe to such events **before** this API is invoked to ensure
> all video chunks are being properly consumed on the client side.

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
fps | number | no | Frame Per Second setting for the resulting screen recording. 24 by default. Higher FPS values may significantly increase the size of the resulting video. | 60
codec | number | no | Possible codec value, where `0` means H264 (the default setting), `1` means HEVC | 1
displayId | number | no | Valid display identifier to record the video from. Main display ID is assumed by default. Use the `system_profiler -json SPDisplaysDataType` Terminal command to list IDs of connected displays or the [macos: listDisplays](#macos-listdisplays) API. | 1

#### Returns

The information about the asynchronously running video recording, which includes the following items:

Name | Type | Description | Example
--- | --- | --- | ---
fps | number | Frame Per Second value | 24
codec | number | Codec value, where `0` means H264 (the default setting), `1` means HEVC | 1
displayId | number | Display identifier used to record this video for. | 1
uuid | string | Unique video identifier. It is also used by XCTest to store the video on the file system. Look for `$HOME/Library/Daemon Containers/<testmanager_id>/Data/Attachments/<uuid>` to find the appropriate video file. Add the `.mp4` extension to it to make it openable by video players.
startedAt | number | Unix timestamp of the video startup moment | 123456789

### macos: getNativeScreenRecordingInfo

Fetches the information of the currently running native video recording.
Xcode must be at version 15+.

#### Returns

Either `null` if no native video recording is currently active or the same map that [macos: startNativeScreenRecording](#macos-startnativescreenrecording) returns.

### macos: stopNativeScreenRecording

Stops native screen recording previously started by
[macos: startNativeScreenRecording](#macos-startnativescreenrecording)
and returns the video payload or uploads it to a remote location,
depending on the provided arguments.
The actual video file is removed from the local file system after the video payload is
successfully consumed.
If no screen recording has been started before then this API throws an exception.
Xcode must be at version 15+.

> [!IMPORTANT]
> In order to retrieve the recorded video from the local file system the Appium Server process itself
> or its parent process (e.g. Terminal) must have the "Full Disk Access" permission granted
> in 'System Preferences'→'Privacy & Security' tab.

> [!NOTE]
> Be careful while recording lengthy videos. They could be pretty large, and may easily exceed
> the free space on the home partition.

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
ignorePayload | boolean | no | Whether to ignore the resulting video payload and return an empty string. Useful if you prefer to fetch video chunks via the [appium:mac2.nativeVideoRecordingChunkAdded](./docs/bidi.md#appiummac2nativevideorecordingchunkadded) BiDi event. false by default. | true

#### Returns

Base64-encoded content of the recorded media file if `remotePath` parameter is falsy or an empty string.

### macos: listDisplays

Fetches information about available displays.

#### Returns

A map where keys are display identifiers represented as strings and values are display infos containing the following items:

Name | Type | Description | Example
--- | --- | --- | ---
id | number | Display identifier | 12345
isMain | boolean | Is `true` if the display is configured as a main system display | false

### macos: setClipboard

Set the macOS clipboard content as base64-encoded string. The existing clipboard content (if present) will be cleared.

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
content | string | yes | The content to be set as base64 encoded string | hello
contentType | string | no | The type of the content to set. Only `plaintext` (default), `image` and `url` are supported. If set to `url`, then `content` must be a valid URL. If set to `image`, then `content` must contain a valid PNG or TIFF image payload. | url

### macos: getClipboard

Get the macOS clipboard content as base64-encoded string.

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
contentType | string | no | The type of the content to get. Only `plaintext` (default), `image` and `url` are supported. | image

#### Returns

The actual clipboard content encoded into base64 string. An empty string is returned if the clipboard
contains no data for the given content type.


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
fetchFullText | boolean | Whether to use custom snapshotting mechanism to fetch full element's text payload instead of the first 512 chars. By default, this setting is set to false, which makes the driver to use the standard XCTest's snapshotting mechanism. It's fast, but may also cut long textual payloads of various UI element's in order to optimize internal UI hierarchy snapshotting performance. If the performance is less important for you that the ability to validate full element's text then consider enabling this setting while calling [Get Element Text](https://www.w3.org/TR/webdriver1/#dfn-get-element-text) API.


## Scripts

The Mac2 driver supports the following scripts:

### open-wda

Run `appium driver run mac2 open-wda` to open the bundled WebDriverAgentMac source in Xcode and to print the path to the main .xcodeproj file into the Terminal.


## Troubleshooting

### "WebDriverAgentRunner-Runner is from unidentified developer" system alert is shown on session startup

This is a macOS security feature and it cannot be disabled.
The only way to workaround this behavior is to configure digital signing for WDA.
Check [the Stackoverlow thread](https://stackoverflow.com/questions/41062607/osx-complains-that-app-is-from-unidentified-developer-although-it-passes-all-va)
for more details on how to do it. Use the [open-wda driver script](#open-wda) to quickly
open WebDriverAgent sources in Xcode.


## Examples

```python
# Python3 + PyTest
import pytest

from appium import webdriver
# Options are available in Python client since v2.6.0
from appium.options.mac import Mac2Options
from appium.webdriver.common.appiumby import AppiumBy


@pytest.fixture()
def driver():
    options = Mac2Options()
    options.bundle_id = 'com.apple.TextEdit'
    # The default URL is http://127.0.0.1:4723/wd/hub in Appium1
    drv = webdriver.Remote('http://127.0.0.1:4723', options=options)
    yield drv
    drv.quit()


def test_edit_text(driver):
    edit_field = driver.find_element(by=AppiumBy.CLASS_NAME, value='XCUIElementTypeTextView')
    edit_field.send_keys('hello world')
    assert edit_field.text == 'hello world'
    edit_field.clear()
    assert edit_field.text == ''


def test_sending_custom_keys(driver):
    edit_field = driver.find_element(by=AppiumBy.CLASS_NAME, value='XCUIElementTypeTextView')
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

## Environment Variables

The server part of the driver recognizes the following environment variables:

- `ENABLE_AUTOMATIC_SCREENSHOTS`: enables automatic XCTest screenshots.
  These screenshots are stored in the same folder where WDA test logs are located and are taken automatically.
  This feature is disabled by default. Only enable it if you know what you are doing otherwise these
  screenshots may quickly fill up the free disk space.
- `ENABLE_AUTOMATIC_SCREEN_RECORDINGS`: enables automatic XCTest screen recordings.
  These screen recordings are stored in the same folder where WDA test logs are located and are taken automatically. This feature is disabled by default.
  Only enable it if you know what you are doing otherwise these videos may quickly fill up the free disk space.
  The native screen recording feature only works on Xcode 15+.
- `USE_PORT`. If enabled then the server listens on the given port. Otherwise, a random free port from the
  10100..10200 range is selected. By default, the port is selected by the driver (see the `appium:systemPort`
  capability description).
- `VERBOSE_LOGGING`. If enabled then server logs should include various verbose details. Disabled by default.

## Development & Testing

This module uses the same [development tools](https://github.com/appium/appium/tree/master/docs/cn/contributing-to-appium) as the other Appium drivers.

Check out the source. Then run:

```bash
npm install
```

Execute `npm run test` to run unit tests and `npm run e2e-test` to run integration tests.


## Notes

- W3C actions support is limited (only mouse actions are supported). You could also use `macos:` extension APIs to cover your test scenarios
