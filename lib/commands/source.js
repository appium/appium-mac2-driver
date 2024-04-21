/**
 * Retrieves the string representation of the current application
 *
 * @this {Mac2Driver}
 * @param {import('../types').SourceOptions} [opts={}]
 * @returns {Promise<string>} the page source in the requested format
 */
export async function macosSource (opts = {}) {
  const {
    format = 'xml',
  } = opts;
  return /** @type {String} */ (
    await this.wda.proxy.command(`/source?format=${encodeURIComponent(format)}`, 'GET')
  );
};

/**
 * @typedef {import('../driver').Mac2Driver} Mac2Driver
 */
