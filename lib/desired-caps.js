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
  depsLoadTimeout: {
    isNumber: true
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
    environment: true
  },
  skipAppKill: {
    isBoolean: true
  }
};

export { desiredCapConstraints };
