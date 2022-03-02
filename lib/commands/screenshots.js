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
 * Retrieves screenshots of each display available to macOS
 *
 * @returns {ScreenshotsInfo}
 */
commands.macosScreenshots = async function macosScreenshots () {
  return await this.wda.proxy.command('/wda/screenshots', 'GET');
};

export { commands };
export default commands;
