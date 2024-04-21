/**
 * Start an app with given bundle identifier or activates it
 * if the app is already running. An exception is thrown if the
 * app with the given identifier cannot be found.
 *
 * @this {Mac2Driver}
 * @param {import('../types').LaunchAppOptions} [opts={}]
 */
export async function macosLaunchApp (opts = {}) {
  const { bundleId, environment, path } = opts;
  return await this.wda.proxy.command('/wda/apps/launch', 'POST', {
    arguments: opts.arguments,
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
 * @param {import('../types').ActivateAppOptions} [opts={}]
 */
export async function macosActivateApp (opts = {}) {
  const { bundleId, path } = opts;
  return await this.wda.proxy.command('/wda/apps/activate', 'POST', { bundleId, path });
};

/**
 * Terminate an app with given bundle identifier. An exception is thrown if the
 * app cannot be found.
 *
 * @this {Mac2Driver}
 * @param {import('../types').TerminateAppOptions} opts
 * @returns {Promise<boolean>} `true` if the app was running and has been successfully terminated.
 * `false` if the app was not running before.
 */
export async function macosTerminateApp (opts) {
  const { bundleId, path } = opts ?? {};
  return /** @type {boolean} */ (
    await this.wda.proxy.command('/wda/apps/terminate', 'POST', { bundleId, path })
  );
};

/**
 * Query an app state with given bundle identifier. An exception is thrown if the
 * app cannot be found.
 *
 * @this {Mac2Driver}
 * @param {import('../types').QueryAppStateOptions} opts
 * @returns {Promise<number>} The application state code. See
 * https://developer.apple.com/documentation/xctest/xcuiapplicationstate?language=objc
 * for more details
 */
export async function macosQueryAppState (opts) {
  const { bundleId, path } = opts ?? {};
  return /** @type {number} */ (
    await this.wda.proxy.command('/wda/apps/state', 'POST', { bundleId, path })
  );
};

/**
 * @typedef {import('../driver').Mac2Driver} Mac2Driver
 */
