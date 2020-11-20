const commands = {};

/**
 * @typedef {Object} SourceOptions
 * @property {?string} format [xml] The format of the application source to retrieve.
 * Only two formats are supported:
 * - xml: Returns the source formatted as XML document (the default setting)
 * - description: Returns the source formatted as debugDescription output.
 * See https://developer.apple.com/documentation/xctest/xcuielement/1500909-debugdescription?language=objc
 * for more details.
 */

/**
 * Retrieves the string representation of the current application
 *
 * @param {?SourceOptions} opts
 * @returns {string} the page source in the requested format
 */
commands.macosSource = async function macosSource (opts = {}) {
  const {
    format = 'xml',
  } = opts;
  return await this.wda.proxy.command(`/source?format=${encodeURIComponent(format)}`, 'GET');
};

export default commands;
