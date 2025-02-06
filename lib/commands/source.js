/**
 * Retrieves the string representation of the current application
 *
 * @this {Mac2Driver}
 * @param {string} [format='xml'] The format of the application source to retrieve.
 *                 Only two formats are supported:
 *                   - xml: Returns the source formatted as XML document (the default setting)
 *                   - description: Returns the source formatted as debugDescription output.
 *                 See https://developer.apple.com/documentation/xctest/xcuielement/1500909-debugdescription?language=objc
 *                 for more details.
 * @returns {Promise<string>} the page source in the requested format
 */
export async function macosSource (format = 'xml') {
  return /** @type {String} */ (
    await this.wda.proxy.command(`/source?format=${encodeURIComponent(format)}`, 'GET')
  );
};

/**
 * @typedef {import('../driver').Mac2Driver} Mac2Driver
 */
