const commands = {};

/**
 * @typedef {Object} DeepLinkOpts
 * @property {string} url The URL to be opened. This parameter is manadatory.
 * @property {string} [bundleId] The bundle identifier of an application to open the given url with.
 * If not provided then the default application for the given url scheme is going to be used.
 */

/**
 * Opens the given URL with the default or the given application.
 * Xcode must be at version 14.3+.
 *
 * @param {DeepLinkOpts} opts
 * @returns {Promise<void>}
 */
commands.macosDeepLink = async function macosDeepLink (opts) {
  const {url, bundleId} = opts;
  return await this.wda.proxy.command('/url', 'POST', {url, bundleId});
};

export { commands };
export default commands;
