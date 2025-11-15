import type { Mac2Driver } from '../driver';

/**
 * Opens the given URL with the default or the given application.
 * Xcode must be at version 14.3+.
 *
 * @param url - The URL to be opened.
 * @param bundleId - The bundle identifier of an application to open
 *                 the given url with. If not provided then the default application
 *                 for the given url scheme is going to be used.
 */
export async function macosDeepLink(
  this: Mac2Driver,
  url: string,
  bundleId?: string
): Promise<unknown> {
  return await this.wda.proxy.command('/url', 'POST', { url, bundleId });
}

