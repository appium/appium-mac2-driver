# Supported BiDi Commands And Events

Only events and commands mentioned below are supported.
All other entities described in the spec throw not implemented errors.

# Supported Events

## appium:mac2.nativeVideoRecordingChunkAdded

This event is emitted upon new native video recording chunk is available
for consumption. These events are automatically being emitted as soon as
`macos: startNativeScreenRecording` execute method is invoked. The emission
stops as soon as `macos: stopNativeScreenRecording` is called, or the test
session is stopped.

### CDDL

```cddl
appium:mac2.nativeVideoRecordingChunkAdded = {
  method: "appium:mac2.nativeVideoRecordingChunkAdded",
  params: {
    uuid: text,
    payload: text,
  },
}
```

The event contains the following params:

### uuid

The UUID of the video being broadcast.

### payload

Base64-encoded chunk of the corresponding video file.
