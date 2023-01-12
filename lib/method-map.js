export const newMethodMap = /** @type {const} */ ({
  '/session/:sessionId/appium/start_recording_screen': {
    POST: {
      command: 'startRecordingScreen',
      payloadParams: { optional: ['options'] }
    }
  },
  '/session/:sessionId/appium/stop_recording_screen': {
    POST: {
      command: 'stopRecordingScreen',
      payloadParams: { optional: ['options'] }
    }
  },
});
