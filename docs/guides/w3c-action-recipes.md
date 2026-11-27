---
title: W3C Action Recipes
---

While the Mac2 driver includes various [execute methods](../reference/execute-methods.md) to invoke
different click, tap and swipe-related gestures, [standard W3C WebDriver Actions](https://w3c.github.io/webdriver/#actions)
can provide much greater flexibility and allow gestures of virtually any complexity.

At the same time, different platforms (including macOS) have their own specifications for how a
gesture must be constructed in order to be actually recognized by the operating system.

!!! warning

    The Mac2 driver only has partial support for W3C Actions:

    * Only the `pointer` and `key` input sources are supported
    * Only the `mouse` pointing device type (`pointerType`) is supported

Here is a short list of examples for the most common macOS pointer gestures:

## Click

```json
[
  {"type": "pointerMove", "duration": 10, "x": 100, "y": 100},
  {"type": "pointerDown", "button": 0},
  {"type": "pause", "duration": 100},
  {"type": "pointerUp", "button": 0}
]
```

The click duration should be 0-125 ms.

## Right Click

```json
[
  {"type": "pointerMove", "duration": 10, "x": 100, "y": 100},
  {"type": "pointerDown", "button": 2},
  {"type": "pointerUp", "button": 2}
]
```

The click duration should be 0-125 ms.

## Double Click

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

The duration between the two clicks should be 600-1000 ms.

## Drag & Drop

```json
[
  {"type": "pointerMove", "duration": 10, "x": 100, "y": 100},
  {"type": "pointerDown", "button": 0},
  {"type": "pause", "duration": 600},
  {"type": "pointerMove", "duration": 10, "x": 200, "y": 200},
  {"type": "pointerUp", "button": 0}
]
```

The duration of the second `pointerMove` action determines the drag velocity (longer duration =
smaller velocity).

It is possible to add more `pointerMove` actions before releasing the mouse button to simulate
complex cursor paths. Note that the Mac2 driver limits action durations to 5 minutes.

## Hover

```json
[
  {"type": "pointerMove", "duration": 10, "x": 100, "y": 100},
  {"type": "pointerMove", "duration": 1000, "x": 200, "y": 200}
]
```

This snippet will result in the mouse pointer hovering over the `[100, 100, 200, 200]` area for 1
second.

In general, any `pointerMove` action while the cursor is not depressed (not preceded by a
`pointerDown` action) is treated as a hover gesture, given sufficiently high `duration`.

## Key Presses

Send the `key` input source as a standalone action. Combining it with a `pointer` source in the
same request is supported, but modifiers are not reliably kept pressed between the keys then.

```json
[
  {"type": "keyDown", "value": "\uE009"},
  {"type": "keyDown", "value": "d"},
  {"type": "keyUp", "value": "d"},
  {"type": "pause", "duration": 100},
  {"type": "keyDown", "value": "e"},
  {"type": "keyUp", "value": "e"},
  {"type": "keyUp", "value": "\uE009"}
]
```

This snippet presses the Control key (`\uE009`), types `d` and `e` while it is held, and then
releases it. The supported modifiers are Control (`\uE009`), Shift (`\uE008`), Option (`\uE00A`)
and Command (`\uE03D`). Every `keyDown` must have a matching `keyUp`.

Regular keys are typed when their `keyUp` is processed.
