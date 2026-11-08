import {errors, isErrorType} from 'appium/driver.js';
import {util} from 'appium/support.js';
import {ConditionUnmetError} from 'asyncbox';

import type {Mac2Driver} from '../driver.js';

declare module '../driver.js' {
  interface Mac2Driver {
    findElOrEls(...args: Parameters<typeof findElOrEls>): ReturnType<typeof findElOrEls>;
  }
}

// Older asyncbox (possibly bundled with the base driver) throws a plain Error
function isConditionUnmet(e: unknown): boolean {
  return e instanceof ConditionUnmetError || /Condition unmet/.test((e as Error)?.message ?? '');
}

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
  context?: string,
): Promise<any> {
  const contextId = context ? util.unwrapElement(context) : context;
  const endpoint = `/element${contextId ? `/${contextId}/element` : ''}${mult ? 's' : ''}`;

  // Web view elements are located by Chromedriver using the standard W3C strategies
  if (this.chromedriver) {
    return await this.chromedriver.jwproxy.command(endpoint, 'POST', {using: strategy, value: selector});
  }

  let normalizedStrategy = strategy;
  if (strategy === '-ios predicate string') {
    normalizedStrategy = 'predicate string';
  } else if (strategy === '-ios class chain') {
    normalizedStrategy = 'class chain';
  }

  const doFind = async (): Promise<any> =>
    await this.wda.proxy.command(endpoint, 'POST', {
      using: normalizedStrategy,
      value: selector,
    });
  if (!this.implicitWaitMs) {
    return await doFind();
  }

  // The WDA server ignores the /timeouts API, so the implicit wait is applied here
  let result: any;
  let lastError: Error | undefined;
  // A lookup error other than NoSuchElementError stops the wait and must reach the caller as is
  let lookupError: unknown;
  try {
    await this.implicitWaitForCondition(async () => {
      try {
        result = await doFind();
      } catch (e) {
        if (!isErrorType(e, errors.NoSuchElementError)) {
          lookupError = e;
          throw e;
        }
        lastError = e as Error;
        return false;
      }
      return !mult || (Array.isArray(result) && result.length > 0);
    });
  } catch (e) {
    if (lookupError !== undefined) {
      throw lookupError;
    }
    if (!isConditionUnmet(e)) {
      throw e;
    }
    if (!mult && lastError) {
      throw lastError;
    }
  }
  return result;
}
