---
hide:
  - toc

title: Key Modifier Flags
---

The Mac2 driver supports key modifiers for various click-related [execute methods](../reference/execute-methods.md),
as the `keyModifierFlags` parameter.

Supported modifier flag values are based on XCTest's [XCUIElement.KeyModifierFlags](https://developer.apple.com/documentation/xcuiautomation/xcuielement/keymodifierflags),
and should consist of one or more bitmasks, as defined in XCTest:

```objectivec
typedef NS_OPTIONS(NSUInteger, XCUIKeyModifierFlags) {
   XCUIKeyModifierNone       = 0,
   XCUIKeyModifierCapsLock   = (1UL << 0),
   XCUIKeyModifierShift      = (1UL << 1),
   XCUIKeyModifierControl    = (1UL << 2),
   XCUIKeyModifierOption     = (1UL << 3),
   XCUIKeyModifierCommand    = (1UL << 4),
   XCUIKeyModifierFunction   = (1UL << 5),
   // These values align with UIKeyModifierFlags and CGEventFlags.
   XCUIKeyModifierAlphaShift = XCUIKeyModifierCapsLock,
   XCUIKeyModifierAlternate  = XCUIKeyModifierOption,
};
```

The values you can use for `keyModifierFlags` are therefore as follows:

| Key | User value |
| --- |  --- |
| Caps Lock |  `1` |
| Shift |  `(1 << 1)` |
| Control |  `(1 << 2)` |
| Option |  `(1 << 3)` |
| Command |  `(1 << 4)` |
| Function |  `(1 << 5)` |

You can also combine multiple modifier keys using the bitwise OR (`|`) operator. For example, in
order to apply the Control and Shift modifiers, set `keyModifierFlags` to `(1 << 1) | (1 << 2)`.
