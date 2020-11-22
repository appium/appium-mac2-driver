Appium Mac2 Driver
====

This is Appium driver for automating macOS applications using Apple's [XCTest](https://developer.apple.com/documentation/xctest) framework.
The driver operates in scope of [W3C WebDriver protocol](https://www.w3.org/TR/webdriver/) with several custom extensions to cover operating-system specific scenarios.
The original idea and parts of the source code are borrowed from the Facebook's [WebDriverAgent](https://github.com/facebookarchive/WebDriverAgent) project.


## Requirements

On top of standard Appium requirements Mac2 driver also expects the following prerequisites:

- Mac OS 10.15 or later
- Xcode 12 or later should be installed
- Xcode Helper app should be enabled for Accessibility access. The app itself could be usually found at `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Xcode/Agents/Xcode Helper.app`. In order to enable Accessibility access for it simply open the parent folder in Finder: `open /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Xcode/Agents/` and drag & drop the `Xcode Helper` app to `Security & Privacy -> Privacy -> Accessibility` list of your `System Preferences`. This action must only be done once.
- [Carthage](https://github.com/Carthage/Carthage) should be present. On macOS the utility could be installed via [Brew](https://brew.sh/): `brew install carthage`


## Capabilities

Capability Name | Description
--- | ---
platformName | Should be set to `mac`
automationName | Must always be set to `mac2`. Values of automationName are compared case-insensitively.
appium:systemPort | The number of the port for the driver to listen on. If not provided then Appium will use the default port `10100`.
appium:showServerLogs | Set it to `true` in order to include xcodebuild output to the Appium server log. `false` by default.
appium:bootstrapRoot | The full path to `WebDriverAgentMac` root folder where Xcode project of the server sources lives. By default this project is located in the same folder where the corresponding driver Node.js module lives.
appium:dependenciesLoadTimeout | The number of milliseconds to wait for Carthage dependencies load. These dependencies are loaded when the project is built for the first time. `120000` by default
appium:serverStartupTimeout | The number of milliseconds to wait util the WebDriverAgentMac project is built and started. `120000` by default
appium:bundleId | The bundle identifier of the application to automate, for example `com.apple.TextEdit`. This is an optional capability. If it is not provided then the session will be started without an application under test (actually, it will be Finder). If the application with the given identifier is not installed then an error will be thrown on session startup. If the application is already running then it will be moved to the foreground.
appium:arguments | Array of application command line arguments. This capability is only going to be applied if the application is not running on session startup.
appium:environment | A dictionary of environment variables (name->value) that are going to be passed to the application under test on top of environment variables inherited from the parent process. This capability is only going to be applied if the application is not running on session startup.
appium:skipAppKill | Whether to skip the termination of the application under test when the testing session quits. `false` by default. This capability is only going to be applied if `bundleId` is set.


## Element Attributes

Mac2 driver supports the following element attributes:

Name | Description | Example
--- | --- | ---
elementType | Integer-encoded element class. See https://developer.apple.com/documentation/xctest/xcuielementtype?language=objc for more details. | '2'
frame | Coordinates of bounding element rectangle | {x: 1, y: 2.5, width: 100, height: 200}
placeholderValue | It is usually only present for text fields. For other element types it's mostly empty | 'my placeholder'
enabled | Contains `true` if the element is enabled | 'false'
selected | Contains `true` if the element is selected | 'false'
label | Element's label value. Could be empty | 'my label'
title | Element's title value. Could be empty | 'my title'
identifier | Element's accessibility identifier. Could be empty | 'identifier'
value | The value could be different depending on the actual element type. For example, text fields might have their text context there and sliders would contain the float position value, while switches would have either `1` or `0` | '1.5'

These attribute values could be retrieved from the page source output and then used for elements location. See https://developer.apple.com/documentation/xctest/xcuielementattributes?language=objc for more details on each attribute.

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
element | string | if `x` or `y` are unset | Unique identifier of the element to perform the click on. Either this property or/and x and y must be set. If both are set then x and y are considered as relative element coordinates. If only x and y are set then these are parsed as absolute coordinates. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
x | number | if `y` is set or `element` is unset | click X coordinate | 100
y | number | if `y` is set or `element` is unset | click Y coordinate | 100
keyModifierFlags | number | no | if set then the given key modifiers will be applied while click is performed. See https://developer.apple.com/documentation/xctest/xcuikeymodifierflags for more details | 1 << 1 `logical or` 1 << 2

### macos: clickAndHold

Perform long click gesture on an element or by relative/absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
element | string | if `x` or `y` are unset | Unique identifier of the element to perform the long click on. Either this property or/and x and y must be set. If both are set then x and y are considered as relative element coordinates. If only x and y are set then these are parsed as absolute coordinates. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
x | number | if `y` is set or `element` is unset | long click X coordinate | 100
y | number | if `y` is set or `element` is unset | long click Y coordinate | 100
duration | number | yes | The number of float seconds to hold the mouse button | 2.5
keyModifierFlags | number | no | if set then the given key modifiers will be applied while long click is performed. See https://developer.apple.com/documentation/xctest/xcuikeymodifierflags for more details | 1 << 1 `logical or` 1 << 2

### macos: scroll

Perform scroll gesture on an element or by relative/absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
element | string | if `x` or `y` are unset | Unique identifier of the element to be scrolled. Either this property or/and x and y must be set. If both are set then x and y are considered as relative element coordinates. If only x and y are set then these are parsed as absolute coordinates. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
x | number | if `y` is set or `element` is unset | scroll X coordinate | 100
y | number | if `y` is set or `element` is unset | scroll Y coordinate | 100
deltaX | number | yes | Horizontal delta as float number. Could be negative | 100
deltaY | number | yes | vertical delta as float number. Could be negative | 100
keyModifierFlags | number | no | if set then the given key modifiers will be applied while scroll is performed. See https://developer.apple.com/documentation/xctest/xcuikeymodifierflags for more details | 1 << 1 `logical or` 1 << 2

### macos: rightClick

Perform right click gesture on an element or by relative/absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
element | string | if `x` or `y` are unset | Unique identifier of the element to perform the right click on. Either this property or/and x and y must be set. If both are set then x and y are considered as relative element coordinates. If only x and y are set then these are parsed as absolute coordinates. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
x | number | if `y` is set or `element` is unset | right click X coordinate | 100
y | number | if `y` is set or `element` is unset | right click Y coordinate | 100
keyModifierFlags | number | no | if set then the given key modifiers will be applied while right click is performed. See https://developer.apple.com/documentation/xctest/xcuikeymodifierflags for more details | 1 << 1 `logical or` 1 << 2

### macos: hover

Perform hover gesture on an element or by relative/absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
element | string | if `x` or `y` are unset | Unique identifier of the element to perform the hover on. Either this property or/and x and y must be set. If both are set then x and y are considered as relative element coordinates. If only x and y are set then these are parsed as absolute coordinates. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
x | number | if `y` is set or `element` is unset | long click X coordinate | 100
y | number | if `y` is set or `element` is unset | long click Y coordinate | 100
keyModifierFlags | number | no | if set then the given key modifiers will be applied while hover is performed. See https://developer.apple.com/documentation/xctest/xcuikeymodifierflags for more details | 1 << 1 `logical or` 1 << 2

### macos: doubleClick

Perform double click gesture on an element or by relative/absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
element | string | if `x` or `y` are unset | Unique identifier of the element to perform the double click on. Either this property or/and x and y must be set. If both are set then x and y are considered as relative element coordinates. If only x and y are set then these are parsed as absolute coordinates. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
x | number | if `y` is set or `element` is unset | double click X coordinate | 100
y | number | if `y` is set or `element` is unset | double click Y coordinate | 100
keyModifierFlags | number | no | if set then the given key modifiers will be applied while click is performed. See https://developer.apple.com/documentation/xctest/xcuikeymodifierflags for more details | 1 << 1 `logical or` 1 << 2

### macos: clickAndDrag

Perform long click and drag gesture on an element or by absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
sourceElement | string | if `startX`, `startY`, `endX` and `endY` are unset or if `destinationElement` is set | Uuid of the element to start the drag from. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
destinationElement | string | if `startX`, `startY`, `endX` and `endY` are unset or if `sourceElement` is set | Uuid of the element to end the drag on. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0745
startX | number | if `sourceElement` and `destinationElement` are unset | starting X coordinate | 100
startY | number | if `sourceElement` and `destinationElement` are unset | starting Y coordinate | 110
endX | number | if `sourceElement` and `destinationElement` are unset | end X coordinate | 200
endY | number | if `sourceElement` and `destinationElement` are unset | end Y coordinate | 220
duration | number | yes | The number of float seconds to hold the mouse button | 2.5
keyModifierFlags | number | no | if set then the given key modifiers will be applied while drag is performed. See https://developer.apple.com/documentation/xctest/xcuikeymodifierflags for more details | 1 << 1 `logical or` 1 << 2

### macos: clickDragAndDrag

Perform long click, drag and hold gesture on an element or by absolute coordinates

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
sourceElement | string | if `startX`, `startY`, `endX` and `endY` are unset or if `destinationElement` is set | Uuid of the element to start the drag from. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
destinationElement | string | if `startX`, `startY`, `endX` and `endY` are unset or if `sourceElement` is set | Uuid of the element to end the drag on. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0745
startX | number | if `sourceElement` and `destinationElement` are unset | starting X coordinate | 100
startY | number | if `sourceElement` and `destinationElement` are unset | starting Y coordinate | 110
endX | number | if `sourceElement` and `destinationElement` are unset | end X coordinate | 200
endY | number | if `sourceElement` and `destinationElement` are unset | end Y coordinate | 220
duration | number | yes | The number of float seconds to hold the mouse button | 2.5
velocity | number | no | Dragging velocity in pixels per second. If not provided then the default velocity is used. See https://developer.apple.com/documentation/xctest/xcuigesturevelocity for more details | 2500
keyModifierFlags | number | no | if set then the given key modifiers will be applied while drag is performed. See https://developer.apple.com/documentation/xctest/xcuikeymodifierflags for more details | 1 << 1 `logical or` 1 << 2

### macos: keys

Send keys to the given element or to the application under test

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
element | string | no | Unique identifier of the element to send the keys to. If unset then keys are sent to the current application under test. | 21045BC8-013C-43BD-9B1E-4C6DC7AB0744
keys | array | yes | Array of keys to type. Each item could either be a string, that represents a key itself (see https://developer.apple.com/documentation/xctest/xcuielement/1500604-typekey?language=objc and https://developer.apple.com/documentation/xctest/xcuikeyboardkey?language=objc) or a dictionary with `key` and `modifierFlags` entries, if the key should also be entered with modifiers. | ['h', 'i'] or [{key: 'h', modifierFlags: 1 << 1}, {key: 'i', modifierFlags: 1 << 2}] |

### macos: source

Retrieves the string representation of the current application

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
format | string | yes | The format of the application source to retrieve. Only two formats are supported: `xml` (returns the source formatted as XML document, the default value) and `description` (returns the source formatted as debugDescription output). See https://developer.apple.com/documentation/xctest/xcuielement/1500909-debugdescription?language=objc for more details. | description

#### Returns

The source of the current page in a string representation

### macos: launchApp

Start an app with the given bundle identifier or activates it if the app is already running. An exception is thrown if the app with the given identifier cannot be found.
This API influences the state of the [Application Under Test](#application-under-test-concept).

#### Arguments

Name | Type | Required | Description | Example
--- | --- | --- | --- | ---
bundleId | string | yes | bundle identifier of the app to be launched or activated | com.apple.TextEdit
arguments | array | no | the list of command line arguments for the app to be be launched with. This argument is ignored if the app is already running. | ['--help]
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

An integer value representing the application state. See https://developer.apple.com/documentation/xctest/xcuiapplicationstate?language=objc for more details.


## Application Under Test Concept

The Mac2 driver has the concept of `Application Under Test`. This is the app, whose bundle identifier has been passed as `bundleId` capability or as an argument to `macos: activateApp` or `macos: launchApp` extensions.
If this application is unexpectedly terminated during test session execution then an exception is going to be thrown upon any following session command invocation. In such case the driver assumes the application under test is crashed and it is impossible to proceed.
Also, the `Application Under Test` is going to be terminated when the testing session quits (unless canceled by `skipAppKill` capability).
It is possible to reset the `Application Under Test` value to none by executing `macos: terminateApp` helper and providing the bundle identifier of this app to it. Also, `macos: activateApp` or `macos: launchApp` calls can change `Application Under Test` value  if a bundle identifier different from the current one is provided to them.


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
```


## Parallel execution

Parallel execution of multiple Mac2 driver instances is highly discouraged. Only one UI test must be running at the same time, since the access to accessibility layer is single-threaded. Also HID devices, like the mouse or the keyboard, must be acquired exclusively.


## TBD

- W3C actions support (use `macos:` extension APIs for now)
