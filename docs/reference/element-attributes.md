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

## label

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
value.

## hittable

> Example: `true`

Corresponds to the element's XCTest [`isHittable`](https://developer.apple.com/documentation/xcuiautomation/xcuielement/ishittable)
value.

## frame

> Example: `{"x": 0,"y": 0,"width": 100,"height": 100}`

Corresponds to the element's XCTest [`frame`](https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes/frame)
value.
