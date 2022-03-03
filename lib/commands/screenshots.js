const commands = {};

/**
 * @typedef {Object} ScreenshotsInfo
 *
 * A dictionary where each key contains a unique display identifier
 * and values are dictionaries with following items:
 * - id: Display identifier
 * - isMain: Whether this display is the main one
 * - payload: The actual PNG screenshot data encoded to base64 string
 */

/**
 * @typedef {Object} ScreenshotsOpts
 * @property {number?} displayId macOS display identifier to take a screenshot for.
 * If not provided then screenshots of all displays are going to be returned.
 * If no matches were found then an error is thrown.
 */

/**
 * Retrieves screenshots of each display available to macOS
 *
 * @param {ScreenshotsOpts} opts
 * @returns {ScreenshotsInfo}
 */
commands.macosScreenshots = async function macosScreenshots (opts = {}) {
  const {displayId} = opts;
  return await this.wda.proxy.command('/wda/screenshots', 'POST', {displayId});
};

export { commands };
export default commands;
