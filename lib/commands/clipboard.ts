import type { Mac2Driver } from '../driver';

/**
 * Sets the content of the clipboard.
 *
 * @param content - The content to be set as base64 encoded string.
 * @param contentType - The type of the content to set.
 * Only `plaintext`, 'image and 'url' are supported.
 */
export async function macosSetClipboard(
  this: Mac2Driver,
  content: string,
  contentType: string = 'plaintext'
): Promise<void> {
  await this.proxyCommand('/wda/setPasteboard', 'POST', {
    content,
    contentType,
  });
}

/**
 * Gets the content of the clipboard.
 *
 * @param contentType - The type of the content to get.
 * Only `plaintext`, 'image and 'url' are supported.
 * @returns {Promise<string>} The actual clipboard content encoded into base64 string.
 * An empty string is returned if the clipboard contains no data for the given content type.
 */
export async function macosGetClipboard(this: Mac2Driver, contentType: string = 'plaintext'): Promise<string> {
  return /** @type {string} */ (
    await this.proxyCommand('/wda/getPasteboard', 'POST', {
      contentType,
    })
  );
}
