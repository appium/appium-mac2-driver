import type {Mac2Driver} from '../driver.js';
import type {ScreenshotsInfo} from '../types.js';

/**
 * Retrieves screenshots of each display available to macOS
 *
 * @param displayId - macOS display identifier to take a screenshot for.
 *                 If not provided then screenshots of all displays are going to be returned.
 *                 If no matches were found then an error is thrown.
 * @returns Screenshots information for the requested display(s)
 */
export async function macosScreenshots(
  this: Mac2Driver,
  displayId?: number,
): Promise<ScreenshotsInfo> {
  return (await this.wda.proxy.command('/wda/screenshots', 'POST', {displayId})) as ScreenshotsInfo;
}
