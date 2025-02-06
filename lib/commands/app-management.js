/**
 * Start an app with given bundle identifier or activates it
 * if the app is already running. An exception is thrown if the
 * app with the given identifier cannot be found.
 *
 * @this {Mac2Driver}
 * @param {string} [bundleId] Bundle identifier of the app to be launched or activated.
 *                 Either this property or `path` must be provided
 * @param {string} [path] Full path to the app bundle. Either this property or
 *                 `bundleId` must be provided
 * @param {string[]} [args] The list of command line arguments for the app to be launched with.
 *                   This parameter is ignored if the app is already running.
 * @param {import('@appium/types').StringRecord} [environment] Environment variables mapping.
 *                   Custom variables are added to the default process environment.
 */
export async function macosLaunchApp (
  bundleId,
  path,
  args,
  environment,
) {
  return await this.wda.proxy.command('/wda/apps/launch', 'POST', {
    arguments: args,
    environment,
    bundleId,
    path,
  });
};

/**
 * Activate an app with given bundle identifier. An exception is thrown if the
 * app cannot be found or is not running.
 *
 * @this {Mac2Driver}
 * @param {string} [bundleId] Bundle identifier of the app to be activated.
 *                 Either this property or `path` must be provided
 * @param {string} [path] Full path to the app bundle. Either this property
 *                 or `bundleId` must be provided
 */
export async function macosActivateApp (bundleId, path) {
  return await this.wda.proxy.command('/wda/apps/activate', 'POST', { bundleId, path });
};

/**
 * Terminate an app with given bundle identifier. An exception is thrown if the
 * app cannot be found.
 *
 * @this {Mac2Driver}
 * @param {string} [bundleId] Bundle identifier of the app to be terminated.
 *                 Either this property or `path` must be provided
 * @param {string} [path] Full path to the app bundle. Either this property
 *                 or `bundleId` must be provided
 * @returns {Promise<boolean>} `true` if the app was running and has been successfully terminated.
 * `false` if the app was not running before.
 */
export async function macosTerminateApp (bundleId, path) {
  return /** @type {boolean} */ (
    await this.wda.proxy.command('/wda/apps/terminate', 'POST', { bundleId, path })
  );
};

/**
 * Query an app state with given bundle identifier. An exception is thrown if the
 * app cannot be found.
 *
 * @this {Mac2Driver}
 * @param {string} [bundleId] Bundle identifier of the app whose state should be queried.
 *                 Either this property or `path` must be provided
 * @param {string} [path] Full path to the app bundle. Either this property
 *                 or `bundleId` must be provided
 * @returns {Promise<number>} The application state code. See
 * https://developer.apple.com/documentation/xctest/xcuiapplicationstate?language=objc
 * for more details
 */
export async function macosQueryAppState (bundleId, path) {
  return /** @type {number} */ (
    await this.wda.proxy.command('/wda/apps/state', 'POST', { bundleId, path })
  );
};

/**
 * @typedef {import('../driver').Mac2Driver} Mac2Driver
 */
