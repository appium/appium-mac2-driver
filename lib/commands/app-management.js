const commands = {};

/**
 * @typedef {Object} LaunchAppOptions
 * @property {string} [bundleId] Bundle identifier of the app to be launched
 * or activated. Either this property or `path` must be provided
 * @property {string} [path] Full path to the app bundle. Either this property
 * or `bundleId` must be provided
 * @property {string[]} arguments the list of command line arguments
 * for the app to be be launched with. This parameter is ignored if the app
 * is already running.
 * @property {Object} environment environment variables mapping. Custom
 * variables are added to the default process environment.
 */

/**
 * Start an app with given bundle identifier or activates it
 * if the app is already running. An exception is thrown if the
 * app with the given identifier cannot be found.
 *
 * @param {LaunchAppOptions} opts
 */
commands.macosLaunchApp = async function macosLaunchApp (opts) {
  const { bundleId, environment } = opts ?? {};
  return await this.wda.proxy.command('/wda/apps/launch', 'POST', {
    arguments: opts.arguments,
    environment,
    bundleId,
  });
};

/**
 * @typedef {Object} ActivateAppOptions
 * @property {string} [bundleId] Bundle identifier of the app to be activated.
 * Either this property or `path` must be provided
 * @property {string} [path] Full path to the app bundle. Either this property
 * or `bundleId` must be provided
 */

/**
 * Activate an app with given bundle identifier. An exception is thrown if the
 * app cannot be found or is not running.
 *
 * @param {ActivateAppOptions} opts
 */
commands.macosActivateApp = async function macosActivateApp (opts) {
  const { bundleId } = opts ?? {};
  return await this.wda.proxy.command('/wda/apps/activate', 'POST', { bundleId });
};

/**
 * @typedef {Object} TerminateAppOptions
 * @property {string} [bundleId] Bundle identifier of the app to be terminated.
 * Either this property or `path` must be provided
 * @property {string} [path] Full path to the app bundle. Either this property
 * or `bundleId` must be provided
 */

/**
 * Terminate an app with given bundle identifier. An exception is thrown if the
 * app cannot be found.
 *
 * @param {TerminateAppOptions} opts
 * @returns {Promise<boolean>} `true` if the app was running and has been successfully terminated.
 * `false` if the app was not running before.
 */
commands.macosTerminateApp = async function macosTerminateApp (opts) {
  const { bundleId } = opts ?? {};
  return await this.wda.proxy.command('/wda/apps/terminate', 'POST', { bundleId });
};

/**
 * @typedef {Object} QueryAppStateOptions
 * @property {string} [bundleId] Bundle identifier of the app whose state should be queried.
 * Either this property or `path` must be provided
 * @property {string} [path] Full path to the app bundle. Either this property
 * or `bundleId` must be provided
 */

/**
 * Query an app state with given bundle identifier. An exception is thrown if the
 * app cannot be found.
 *
 * @param {QueryAppStateOptions} opts
 * @returns {Promise<number>} The application state code. See
 * https://developer.apple.com/documentation/xctest/xcuiapplicationstate?language=objc
 * for more details
 */
commands.macosQueryAppState = async function macosQueryAppState (opts) {
  const { bundleId } = opts ?? {};
  return await this.wda.proxy.command('/wda/apps/state', 'POST', { bundleId });
};

export default commands;
