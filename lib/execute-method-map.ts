import { ExecuteMethodMap } from '@appium/types';

export const executeMethodMap = {
  'macos: setValue': {
    command: 'macosSetValue',
    params: {
      required: [
          'elementId',
      ],
      optional: [
        'value',
        'text',
        'keyModifierFlags',
      ],
    },
  },
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
      optional: [
        'elementId',
        'x',
        'y',
        'deltaX',
        'deltaY',
        'keyModifierFlags',
      ],
    },
  },
  'macos: swipe': {
    command: 'macosSwipe',
    params: {
      optional: [
        'elementId',
        'x',
        'y',
        'direction',
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
      optional: [
        'sourceElementId',
        'destinationElementId',
        'startX',
        'startY',
        'endX',
        'endY',
        'duration',
        'keyModifierFlags',
      ],
    },
  },
  'macos: clickAndDragAndHold': {
    command: 'macosClickAndDragAndHold',
    params: {
      optional: [
        'sourceElementId',
        'destinationElementId',
        'startX',
        'startY',
        'endX',
        'endY',
        'duration',
        'holdDuration',
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
      optional: [
        'elementId',
        'x',
        'y',
        'duration',
        'keyModifierFlags',
      ],
    },
  },
} as const satisfies ExecuteMethodMap<any>;
