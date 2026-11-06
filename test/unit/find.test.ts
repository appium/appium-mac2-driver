import assert from 'node:assert/strict';
import {describe, it} from 'node:test';

import {errors} from 'appium/driver.js';

import {Mac2Driver} from '../../lib/driver.js';

describe('findElOrEls', () => {
  function makeDriver(responses: (() => unknown)[], implicitWaitMs: number) {
    const driver = new Mac2Driver({} as any);
    const calls: string[] = [];
    (driver as any)._wda = {
      proxy: {
        command: async (url: string) => {
          calls.push(url);
          const respond = responses[Math.min(calls.length, responses.length) - 1];
          return respond();
        },
      },
    };
    driver.setImplicitWait(implicitWaitMs);
    return {driver, calls};
  }

  const notFound = () => {
    throw new errors.NoSuchElementError();
  };

  it('sends a single request if the implicit wait is not set', async () => {
    const {driver, calls} = makeDriver([notFound], 0);
    await assert.rejects(driver.findElOrEls('accessibility id', 'foo', false), errors.NoSuchElementError);
    assert.equal(calls.length, 1);
  });

  it('retries a single element lookup within the implicit wait', async () => {
    const element = {ELEMENT: '1'};
    const {driver, calls} = makeDriver([notFound, () => element], 2000);
    assert.deepEqual(await driver.findElOrEls('accessibility id', 'foo', false), element);
    assert.equal(calls.length, 2);
  });

  it('retries a multiple elements lookup within the implicit wait', async () => {
    const elements = [{ELEMENT: '1'}];
    const {driver, calls} = makeDriver([() => [], () => elements], 2000);
    assert.deepEqual(await driver.findElOrEls('accessibility id', 'foo', true), elements);
    assert.equal(calls.length, 2);
  });

  it('throws the lookup error once the implicit wait expires', async () => {
    const {driver, calls} = makeDriver([notFound], 600);
    await assert.rejects(driver.findElOrEls('accessibility id', 'foo', false), errors.NoSuchElementError);
    assert.ok(calls.length > 1);
  });

  it('returns an empty list once the implicit wait expires', async () => {
    const {driver, calls} = makeDriver([() => []], 600);
    assert.deepEqual(await driver.findElOrEls('accessibility id', 'foo', true), []);
    assert.ok(calls.length > 1);
  });

  it('does not retry on other errors', async () => {
    const {driver, calls} = makeDriver(
      [
        () => {
          throw new errors.InvalidSelectorError();
        },
      ],
      2000,
    );
    await assert.rejects(driver.findElOrEls('xpath', '//', false), errors.InvalidSelectorError);
    assert.equal(calls.length, 1);
  });

  it('throws a lookup error whose message looks like the wait timeout', async () => {
    const {driver, calls} = makeDriver(
      [
        () => {
          throw new errors.InvalidSelectorError('Invalid selector: Condition unmet');
        },
      ],
      2000,
    );
    await assert.rejects(driver.findElOrEls('xpath', '//', false), errors.InvalidSelectorError);
    await assert.rejects(driver.findElOrEls('xpath', '//', true), errors.InvalidSelectorError);
    assert.equal(calls.length, 2);
  });
});
