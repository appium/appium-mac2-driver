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
} as const satisfies ExecuteMethodMap<any>;
