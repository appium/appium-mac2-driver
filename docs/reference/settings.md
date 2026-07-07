---
title: Settings
---

The Mac2 driver exposes various settings through Appium's [Settings API](https://appium.io/docs/en/latest/guides/settings/).

## boundElementsByIndex

| Type | Default |
| -- | -- |
| `boolean` | `false` |

Whether to look up elements using [`allElementsBoundByIndex`](https://developer.apple.com/documentation/xcuiautomation/xcuielementquery/allelementsboundbyindex),
as opposed to the default approach using [`allElementsBoundByAccessibilityElement`](https://developer.apple.com/documentation/xcuiautomation/xcuielementquery/allelementsboundbyaccessibilityelement).
[This Stack Overflow topic](https://stackoverflow.com/questions/49307513/meaning-of-allelementsboundbyaccessibilityelement)
explains the difference.

This setting may help as a workaround for stale element reference errors containing
`Identity Binding` text in their descriptions.

## fetchFullText

| Type | Default |
| -- | -- |
| `boolean` | `false` |

Whether to fetch the full element text payload, as opposed to the default approach of fetching
only the first 512 characters.

The default approach is based on XCTest's standard snapshotting mechanism, which is known to cut
off long payloads for performance reasons. Enabling this setting switches to a custom snapshotting
mechanism, which is slower, but retrieves the full payload. The value can then be obtained using
APIs like [Get Element Attribute](https://www.w3.org/TR/webdriver1/#get-element-attribute) or
[Get Element Text](https://www.w3.org/TR/webdriver1/#dfn-get-element-text).

 Available since driver version 3.2.0.

## useDefaultUiInterruptionsHandling

| Type | Default |
| -- | -- |
| `boolean` | `true` |

Whether to use the standard XCTest UI interruption handler, as opposed to disabling it for the
[Application Under Test](../guides/app-under-test.md).

Turning this off may be useful for scenarios that interact with the interrupting element itself,
instead of having its view be implicitly closed. Refer to [this WWDC presentation](https://developer.apple.com/videos/play/wwdc2020/10220/)
to learn more about handling UI interruptions.
