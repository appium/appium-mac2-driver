/**
 * Opens the given URL with the default or the given application.
 * Xcode must be at version 14.3+.
 *
 * @this {Mac2Driver}
 * @param {import('../types').DeepLinkOptions} opts
 * @returns {Promise<unknown>}
 */
export async function macosDeepLink (opts) {
  const {url, bundleId} = opts;
  return await this.wda.proxy.command('/url', 'POST', {url, bundleId});
};

/**
 * @typedef {import('../driver').Mac2Driver} Mac2Driver
 */
