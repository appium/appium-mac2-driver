import { ExecuteMethodMap } from '@appium/types';

export const executeMethodMap = {
  'macos: click': {
    command: 'macosClick',
    params: {
      optional: [
        'elementId',
        'x',
        'y',
        'keyModifierFlags',
      ],
    },
  },
  'macos: scroll': {
    command: 'macosScroll',
    params: {
      required: [
        'deltaX',
        'deltaY',
      ],
      optional: [
        'elementId',
        'x',
        'y',
        'keyModifierFlags',
      ],
    },
  },
  'macos: swipe': {
    command: 'macosSwipe',
    params: {
      required: [
        'direction',
      ],
      optional: [
        'elementId',
        'x',
        'y',
        'velocity',
        'keyModifierFlags',
      ],
    },
  },
  'macos: rightClick': {
    command: 'macosRightClick',
    params: {
      optional: [
        'elementId',
        'x',
        'y',
        'keyModifierFlags',
      ],
    },
  },
  'macos: hover': {
    command: 'macosHover',
    params: {
      optional: [
        'elementId',
        'x',
        'y',
        'keyModifierFlags',
      ],
    },
  },
  'macos: doubleClick': {
    command: 'macosDoubleClick',
    params: {
      optional: [
        'elementId',
        'x',
        'y',
        'keyModifierFlags',
      ],
    },
  },
  'macos: clickAndDrag': {
    command: 'macosClickAndDrag',
    params: {
      required: [
        'duration',
      ],
      optional: [
        'sourceElementId',
        'destinationElementId',
        'startX',
        'startY',
        'endX',
        'endY',
        'keyModifierFlags',
      ],
    },
  },
  'macos: clickAndDragAndHold': {
    command: 'macosClickAndDragAndHold',
    params: {
      required: [
        'duration',
        'holdDuration',
      ],
      optional: [
        'sourceElementId',
        'destinationElementId',
        'startX',
        'startY',
        'endX',
        'endY',
        'velocity',
        'keyModifierFlags',
      ],
    },
  },
  'macos: keys': {
    command: 'macosKeys',
    params: {
      required: [
        'keys'
      ],
      optional: [
        'elementId'
      ],
    },
  },
  'macos: tap': {
    command: 'macosTap',
    params: {
      optional: [
        'elementId',
        'x',
        'y',
        'keyModifierFlags',
      ],
    },
  },
  'macos: doubleTap': {
    command: 'macosDoubleTap',
    params: {
      optional: [
        'elementId',
        'x',
        'y',
        'keyModifierFlags',
      ],
    },
  },
  'macos: press': {
    command: 'macosPressAndHold',
    params: {
      required: [
        'duration',
      ],
      optional: [
        'elementId',
        'x',
        'y',
        'keyModifierFlags',
      ],
    },
  },
  'macos: pressAndDrag': {
    command: 'macosPressAndDrag',
    params: {
      required: [
        'duration',
      ],
      optional: [
        'sourceElementId',
        'destinationElementId',
        'startX',
        'startY',
        'endX',
        'endY',
        'keyModifierFlags',
      ],
    },
  },
  'macos: pressAndDragAndHold': {
    command: 'macosPressAndDragAndHold',
    params: {
      required: [
        'duration',
        'holdDuration',
      ],
      optional: [
        'sourceElementId',
        'destinationElementId',
        'startX',
        'startY',
        'endX',
        'endY',
        'velocity',
        'keyModifierFlags',
      ],
    },
  },
  'macos: source': {
    command: 'macosSource',
    params: {
      optional: [
        'format',
      ],
    },
  },
  'macos: deepLink': {
    command: 'macosDeepLink',
    params: {
      required: [
        'url',
      ],
      optional: [
        'bundleId'
      ],
    },
  },
  'macos: screenshots': {
    command: 'macosScreenshots',
    params: {
      optional: [
        'displayId'
      ],
    },
  },
  'macos: appleScript': {
    command: 'macosExecAppleScript',
    params: {
      optional: [
        'script',
        'language',
        'command',
        'cwd',
        'timeout',
      ],
    },
  },
  'macos: launchApp': {
    command: 'macosLaunchApp',
    params: {
      optional: [
        'bundleId',
        'path',
        'arguments',
        'environment',
      ],
    },
  },
  'macos: activateApp': {
    command: 'macosActivateApp',
    params: {
      optional: [
        'bundleId',
        'path',
      ],
    },
  },
  'macos: terminateApp': {
    command: 'macosTerminateApp',
    params: {
      optional: [
        'bundleId',
        'path',
      ],
    },
  },
  'macos: queryAppState': {
    command: 'macosQueryAppState',
    params: {
      optional: [
        'bundleId',
        'path',
      ],
    },
  },
  'macos: startRecordingScreen': {
    command: 'startRecordingScreen',
    params: {
      required: [
        'deviceId'
      ],
      optional: [
        'timeLimit',
        'videoFilter',
        'fps',
        'preset',
        'captureCursor',
        'captureClicks',
        'forceRestart'
      ],
    },
  },
  'macos: stopRecordingScreen': {
    command: 'stopRecordingScreen',
    params: {
      optional: [
        'remotePath',
        'user',
        'pass',
        'method',
        'headers',
        'fileFieldName',
        'formFields'
      ],
    },
  },
  'macos: startNativeScreenRecording': {
    command: 'macosStartNativeScreenRecording',
    params: {
      optional: [
        'fps',
        'codec',
        'displayId',
      ],
    },
  },
  'macos: getNativeScreenRecordingInfo': {
    command: 'macosGetNativeScreenRecordingInfo',
  },
  'macos: stopNativeScreenRecording': {
    command: 'macosStopNativeScreenRecording',
    params: {
      optional: [
        'remotePath',
        'user',
        'pass',
        'method',
        'headers',
        'fileFieldName',
        'formFields',
        'ignorePayload',
      ],
    },
  },
  'macos: listDisplays': {
    command: 'macosListDisplays',
  },
} as const satisfies ExecuteMethodMap<any>;
