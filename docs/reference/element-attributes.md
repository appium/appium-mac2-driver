---
title: Element Attributes
---

The Mac2 driver has a limited set of supported element attributes.

Refer to the [XCUIElementAttributes protocol documentation](https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes)
for more details on each attribute.

## elementType

> Example: `2`

Corresponds to the element's XCTest [`elementType`](https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes/elementtype)
integer-encoded value.

## identifier

> Example: `identifier`

Corresponds to the element's XCTest [`identifier`](https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes/identifier)
value. Can be `null`.

## label

> Examples: `my label`

Corresponds to the element's XCTest [`label`](https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes/label)
value. Can be `null`.

## title

> Examples: `my title`

Corresponds to the element's XCTest [`title`](https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes/title)
value. Can be `null`.

## value

> Example: `1.5`

Corresponds to the element's XCTest [`value`](https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes/value)
value.

The value of this attribute depend on the actual element type. For example, for text fields this
could be their text contents, for sliders this could be the float position value, while for
switches this could be either 1 or 0.

## placeholderValue

> Example: `my placeholder`

Corresponds to the element's XCTest [`placeholderValue`](https://developer.apple.com/documentation/xctest/xcuielementattributes/placeholdervalue)
value.

## enabled

> Example: `false`

Corresponds to the element's XCTest [`enabled`](https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes/isenabled)
value.

## selected

> Example: `false`

Corresponds to the element's XCTest [`selected`](https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes/isselected)
value.

## focused

> Example: `true`

Corresponds to the element's XCTest [`hasFocus`](https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes/hasfocus)
value. Available since driver version 1.3.0.

## hittable

> Example: `true`

Corresponds to the element's XCTest [`isHittable`](https://developer.apple.com/documentation/xcuiautomation/xcuielement/ishittable)
value.

## frame

> Example: `{"x": 0,"y": 0,"width": 100,"height": 100}`

Corresponds to the element's XCTest [`frame`](https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes/frame)
value.

## amIdentifier

> Example: `my-dom-id`

Non-standard, Mac2-driver-specific alias for [`identifier`](#identifier), with the exact same
value and the exact same [`useDomIdAsAccessibilityId`](./settings.md#usedomidasaccessibilityid)-gated
DOM id fallback behavior. Its only difference from `identifier` is that, unlike `identifier`,
it can also be used in [predicate string](./locator-strategies.md#predicate-string) and
[class chain](./locator-strategies.md#class-chain) locators (at any position in a class chain) to
reliably match against, including web elements by their DOM id when the setting above is enabled,
e.g. `amIdentifier == 'my-dom-id'`.

## amRect

> Example: `{"x": 0,"y": 0,"width": 100,"height": 100}`

Non-standard, Mac2-driver-specific alias for [`frame`](#frame), with the exact same value. `frame`
is a structured rectangle value that predicate/class chain expressions cannot compare against the
driver's `{x, y, width, height}` dictionary shape shown above. `amRect` resolves to that same
dictionary shape, so it can be used in
[predicate string](./locator-strategies.md#predicate-string) and
[class chain](./locator-strategies.md#class-chain) locators instead.

## amText

> Example: `my text`

Non-standard, Mac2-driver-specific attribute with no native XCTest equivalent: the first non-empty
value out of the element's `value`, `label`, `placeholderValue` and `title`, in that order, or an
empty string if all of them are empty. Because there is no such attribute on the XCTest side, it
can only be read through this alias, including from
[predicate string](./locator-strategies.md#predicate-string) and
[class chain](./locator-strategies.md#class-chain) locators.

## amType

> Example: `XCUIElementTypeButton`

Non-standard, Mac2-driver-specific alias for [`elementType`](#elementtype), except as its string
name (e.g. `XCUIElementTypeButton`) instead of the integer code. Unlike `elementType`, it can be
compared against type name strings directly in
[predicate string](./locator-strategies.md#predicate-string) and
[class chain](./locator-strategies.md#class-chain) locators.

## amHasKeyboardInputFocus

> Example: `true`

Non-standard, Mac2-driver-specific alias for [`focused`](#focused), with the exact same value.
XCTest does not expose any focus-related property through its public element attributes protocol
on macOS, so `focused` cannot be referenced directly from predicate/class chain expressions at
all. `amHasKeyboardInputFocus` makes that value available to
[predicate string](./locator-strategies.md#predicate-string) and
[class chain](./locator-strategies.md#class-chain) locators.
