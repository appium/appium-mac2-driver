import { VERBOSITY } from './constants';

const desiredCapConstraints = {
  browserName: {
    isString: true
  },
  browserVersion: {
    isString: true
  },
  acceptInsecureCerts: {
    isBoolean: true
  },
  pageLoadStrategy: {
    isString: true
  },
  proxy: {
    isObject: true
  },
  setWindowRect: {
    isBoolean: true
  },
  timeouts: {
    isObject: true
  },
  unhandledPromptBehavior: {
    isString: true
  },
  systemPort: {
    isNumber: true
  },
  verbosity: {
    isString: true,
    inclusionCaseInsensitive: Object.values(VERBOSITY)
  },
  androidStorage: {
    isString: true,
    inclusionCaseInsensitive: ['auto', 'app', 'internal', 'sdcard']
  },
  'moz:firefoxOptions': {
    isObject: true
  }
};

export { desiredCapConstraints };
