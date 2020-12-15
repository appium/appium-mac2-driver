const desiredCapConstraints = {
  systemPort: {
    isNumber: true
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
  }
};

export { desiredCapConstraints };
