---
title: BiDi Commands and Events
---

The Mac2 driver has partial support of the [WebDriver BiDi Protocol](https://w3c.github.io/webdriver-bidi/).
It inherits [the BiDi commands and events supported by the Appium base driver](https://appium.io/docs/en/latest/reference/api/bidi/),
and additionally defines the events and commands listed below.

## Events

### appium:mac2.nativeVideoRecordingChunkAdded

Indicates that a new native video recording chunk is available for consumption.

This event is continuously emitted as soon as the [`macos: startNativeScreenRecording`](./execute-methods.md#macos-startnativescreenrecording) execute
method is invoked. Event emission stops as soon as the [`macos: stopNativeScreenRecording`](./execute-methods.md#macos-stopnativescreenrecording) execute
method is called, or the test session is stopped.

Available since driver version 2.2.0.

#### Event Type (CDDL)

```cddl
appium:mac2.nativeVideoRecordingChunkAdded = (
  method: "appium:mac2.nativeVideoRecordingChunkAdded",
  params: {
    uuid: text,
    payload: text,
  },
)
```

| Parameter | Description |
| -- | -- |
| `uuid` | The UUID of the video being broadcast |
| `payload` | Base64-encoded chunk of the corresponding video file |
