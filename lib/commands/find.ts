import { util } from 'appium/support';
import type { Mac2Driver } from '../driver';

/**
 * This is needed to make lookup by image working
 *
 * @param strategy - The locator strategy to use
 * @param selector - The selector value
 * @param mult - Whether to find multiple elements
 * @param context - Optional context element ID
 */
export async function findElOrEls(
  this: Mac2Driver,
  strategy: string,
  selector: string,
  mult: boolean,
  context?: string
): Promise<any> {
  const contextId = context ? util.unwrapElement(context) : context;
  const endpoint = `/element${contextId ? `/${contextId}/element` : ''}${mult ? 's' : ''}`;

  let normalizedStrategy = strategy;
  if (strategy === '-ios predicate string') {
    normalizedStrategy = 'predicate string';
  } else if (strategy === '-ios class chain') {
    normalizedStrategy = 'class chain';
  }

  return await this.wda.proxy.command(endpoint, 'POST', {
    using: normalizedStrategy,
    value: selector,
  });
}

