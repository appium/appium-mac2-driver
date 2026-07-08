---
title: Endpoints
---

The Mac2 driver comes with a set of many available endpoints, which are primarily inherited from
the Appium base driver, and can be found in [their Appium docs reference pages](https://appium.io/docs/en/latest/reference/api/).
Refer to the documentation of your Appium client for how to call specific endpoints.

The driver also defines several additional endpoints listed below. Please note that most of the
driver-specific functionality is available using [Execute Methods](./execute-methods.md) instead.

### startRecordingScreen

```
POST /session/:sessionId/appium/start_recording_screen
```

Starts a screen recording. A wrapper for the [`macos: startRecordingScreen`](./execute-methods.md#macos-startrecordingscreen)
execute method.

#### Parameters

|Name|Description|<div style="width:11em">Type</div>|
|--|--|--|
|`options?`|Map of screen recording options. Refer to the corresponding execute method for more details.|`Record<string, any>`|

#### Response

`null`

### stopRecordingScreen

```
POST /session/:sessionId/appium/stop_recording_screen
```

Stops a running screen recording. A wrapper for the [`macos: stopRecordingScreen`](./execute-methods.md#macos-stoprecordingscreen)
execute method.

#### Parameters

|Name|Description|<div style="width:11em">Type</div>|
|--|--|--|
|`options?`|Map of screen recording options. Refer to the corresponding execute method for more details.|`Record<string, any>`|

#### Response

`string` - the recorded video file as a Base64-encoded content, or an empty string
