import {Constraints} from '@appium/types';

const MAC2_CONSTRAINTS = {
  systemPort: {
    isNumber: true,
  },
  systemHost: {
    isString: true,
  },
  showServerLogs: {
    isBoolean: true,
  },
  bootstrapRoot: {
    isString: true,
  },
  serverStartupTimeout: {
    isNumber: true,
  },
  bundleId: {
    isString: true,
  },
  arguments: {
    isArray: true,
  },
  environment: {
    isObject: true,
  },
  noReset: {
    isBoolean: true,
  },
  skipAppKill: {
    isBoolean: true,
  },
  prerun: {
    isObject: true,
  },
  postrun: {
    isObject: true,
  },
  webDriverAgentMacUrl: {
    isString: true,
  },
  appPath: {
    isString: true,
  },
  appLocale: {
    isObject: true,
  },
  appTimeZone: {
    isString: true,
  },
  initialDeeplinkUrl: {
    isString: true,
  },
} as const satisfies Constraints;

export default MAC2_CONSTRAINTS;

export type Mac2Constraints = typeof MAC2_CONSTRAINTS;

