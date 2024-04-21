import { util } from 'appium/support';

/**
 * This is needed to make lookup by image working
 *
 * @this {Mac2Driver}
 * @param {string} strategy
 * @param {string} selector
 * @param {boolean} mult
 * @param {string} [context]
 * @returns {Promise<any>}
 */
export async function findElOrEls (strategy, selector, mult, context) {
  const contextId = context ? util.unwrapElement(context) : context;
  const endpoint = `/element${contextId ? `/${contextId}/element` : ''}${mult ? 's' : ''}`;

  if (strategy === '-ios predicate string') {
    strategy = 'predicate string';
  } else if (strategy === '-ios class chain') {
    strategy = 'class chain';
  }

  return await this.wda.proxy.command(endpoint, 'POST', {
    using: strategy,
    value: selector,
  });
};

/**
 * @typedef {import('../driver').Mac2Driver} Mac2Driver
 */
