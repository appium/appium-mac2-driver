---
hide:
  - toc
title: Key Modifier Flags
---

The Mac2 driver supports key modifiers for various click-related [execute methods](../reference/execute-methods.md)
(via the `keyModifierFlags` parameter) as well as for keyboard input in [`macos: keys`](../reference/execute-methods.md#macos-keys)
(via the `modifierFlags` property on each key descriptor).

Supported modifier flag values are based on XCTest's [XCUIElement.KeyModifierFlags](https://developer.apple.com/documentation/xcuiautomation/xcuielement/keymodifierflags),
and should consist of one or more bitmasks, as defined in XCTest:

```swift
public struct KeyModifierFlags : OptionSet {
    public init(rawValue: UInt)

    public static var capsLock: XCUIElement.KeyModifierFlags { get } // 1 << 0
    public static var shift: XCUIElement.KeyModifierFlags { get } // 1 << 1
    public static var control: XCUIElement.KeyModifierFlags { get } // 1 << 2
    public static var option: XCUIElement.KeyModifierFlags { get } // 1 << 3
    public static var command: XCUIElement.KeyModifierFlags { get } // 1 << 4
    public static var numericPad: XCUIElement.KeyModifierFlags { get } // 1 << 5
    public static var function: XCUIElement.KeyModifierFlags { get } // 1 << 6
}
```

The values you can use for `keyModifierFlags` are therefore as follows:

| Modifier | Value |
| --- | --- |
| Caps Lock | `(1 << 0)` |
| Shift | `(1 << 1)` |
| Control | `(1 << 2)` |
| Option / Alt | `(1 << 3)` |
| Command | `(1 << 4)` |
| Numeric Pad | `(1 << 5)` |
| Function |  `(1 << 5)` |

You can also combine multiple modifier keys using the bitwise OR (`|`) operator. For example, in
order to apply the Control and Shift modifiers during a click, set `keyModifierFlags` to `(1 << 1) | (1 << 2)`.
