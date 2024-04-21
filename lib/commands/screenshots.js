/**
 * Retrieves screenshots of each display available to macOS
 *
 * @this {Mac2Driver}
 * @param {import('../types').ScreenshotsOpts} [opts={}]
 * @returns {Promise<import('../types').ScreenshotsInfo>}
 */
export async function macosScreenshots (opts = {}) {
  const {displayId} = opts;
  return /** @type {import('../types').ScreenshotsInfo} */ (
    await this.wda.proxy.command('/wda/screenshots', 'POST', {displayId})
  );
};

/**
 * @typedef {import('../driver').Mac2Driver} Mac2Driver
 */
