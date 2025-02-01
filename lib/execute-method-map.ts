import { ExecuteMethodMap } from '@appium/types';

export const executeMethodMap = {
  'macos: setValue': {
    command: 'macosSetValue',
    params: {
      required: [
          'elementId'
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
      required: [
          'elementId'
      ],
      optional: [
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
          'elementId'
      ],
      optional: [
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
      required: [
          'elementId'
      ],
      optional: [
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
      required: [
          'elementId'
      ],
      optional: [
        'x',
        'y',
        'keyModifierFlags',
      ],
    },
  },
  'macos: hover': {
    command: 'macosHover',
    params: {
      required: [
          'elementId'
      ],
      optional: [
        'x',
        'y',
        'keyModifierFlags',
      ],
    },
  },
  'macos: doubleClick': {
    command: 'macosDoubleClick',
    params: {
      required: [
          'elementId'
      ],
      optional: [
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
        'keyModifierFlags'
      ],
    },
  },
} as const satisfies ExecuteMethodMap<any>;
