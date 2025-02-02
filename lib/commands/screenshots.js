/**
 * Retrieves screenshots of each display available to macOS
 *
 * @this {Mac2Driver}
 * @param {number} [displayId] macOS display identifier to take a screenshot for.
 *                 If not provided then screenshots of all displays are going to be returned.
 *                 If no matches were found then an error is thrown.
 * @returns {Promise<import('../types').ScreenshotsInfo>}
 */
export async function macosScreenshots (displayId) {
  return /** @type {import('../types').ScreenshotsInfo} */ (
    await this.wda.proxy.command('/wda/screenshots', 'POST', {displayId})
  );
};

/**
 * @typedef {import('../driver').Mac2Driver} Mac2Driver
 */
