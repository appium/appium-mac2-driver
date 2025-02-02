/**
 * Opens the given URL with the default or the given application.
 * Xcode must be at version 14.3+.
 *
 * @this {Mac2Driver}
 * @param {string} url The URL to be opened.
 * @param {string} [bundleId] The bundle identifier of an application to open
 *                 the given url with. If not provided then the default application
 *                 for the given url scheme is going to be used.
 * @returns {Promise<unknown>}
 */
export async function macosDeepLink (url, bundleId) {
  return await this.wda.proxy.command('/url', 'POST', {url, bundleId});
};

/**
 * @typedef {import('../driver').Mac2Driver} Mac2Driver
 */
