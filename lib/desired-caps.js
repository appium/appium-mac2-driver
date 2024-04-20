const desiredCapConstraints = {
  systemPort: {
    isNumber: true
  },
  systemHost: {
    isString: true
  },
  showServerLogs: {
    isBoolean: true
  },
  bootstrapRoot: {
    isString: true
  },
  serverStartupTimeout: {
    isNumber: true
  },
  bundleId: {
    isString: true
  },
  arguments: {
    isArray: true
  },
  environment: {
    isObject: true
  },
  noReset: {
    isBoolean: true
  },
  skipAppKill: {
    isBoolean: true
  },
  prerun: {
    isObject: true
  },
  postrun: {
    isObject: true
  },
  webDriverAgentMacUrl: {
    isString: true
  },
  appPath: {
    isString: true
  },
  appLocale: {
    isObject: true
  },
  appTimeZone: {
    isString: true
  },
  initialDeeplinkUrl: {
    isString: true
  },
};

export { desiredCapConstraints };
