import { ExecuteMethodMap } from "@appium/types";

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
} as const satisfies ExecuteMethodMap<any>;
