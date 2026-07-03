---
title: BiDi Events
---

The Mac2 driver has partial support of the [WebDriver BiDi Protocol](https://w3c.github.io/webdriver-bidi/).
Only the events and commands mentioned below are supported. All other entities described in the
specification throw not implemented errors.

For other BiDi events recognized by the Appium server, see
[their Appium docs reference page](https://appium.io/docs/en/latest/reference/api/bidi/).

### appium:mac2.nativeVideoRecordingChunkAdded

Emitted when a new native video recording chunk is available for consumption.

This event is automatically and continuously emitted as soon as the `macos: startNativeScreenRecording`
execute method is invoked. Event emission stops as soon as the `macos: stopNativeScreenRecording`
execute method is called, or the test session is stopped.

#### Response

An object with the following properties:

| Parameter | Description | Type |
| -- | -- | |
| `uuid` | The UUID of the video being broadcast | string |
| `payload` | Base64-encoded chunk of the corresponding video file | string |
