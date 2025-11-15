import type { Mac2Driver } from '../driver';

/**
 * Retrieves the string representation of the current application
 *
 * @param format - The format of the application source to retrieve.
 *                 Only two formats are supported:
 *                   - xml: Returns the source formatted as XML document (the default setting)
 *                   - description: Returns the source formatted as debugDescription output.
 *                 See https://developer.apple.com/documentation/xctest/xcuielement/1500909-debugdescription?language=objc
 *                 for more details.
 * @returns the page source in the requested format
 */
export async function macosSource(
  this: Mac2Driver,
  format: string = 'xml'
): Promise<string> {
  return (await this.wda.proxy.command(`/source?format=${encodeURIComponent(format)}`, 'GET')) as string;
}

