import assert from 'node:assert/strict';
import os from 'node:os';
import path from 'node:path';
import {describe, it, before, after} from 'node:test';

import {remote} from 'webdriverio';
import type {Browser} from 'webdriverio';

import {HOST, PORT, TEST_TIMEOUT} from '../utils.js';

const CHROME_BUNDLE_ID = 'com.google.Chrome';
const PAGE_URL = 'data:text/html,<title>mac2</title><button id="b" onclick="this.textContent=\'clicked\'">go</button>';

describe('Mac2Driver - web view contexts', {timeout: TEST_TIMEOUT}, () => {
  let driver: Browser;

  before(async () => {
    driver = await remote({
      hostname: HOST,
      port: PORT,
      capabilities: {
        platformName: 'mac',
        'appium:automationName': 'mac2',
        'appium:bundleId': CHROME_BUNDLE_ID,
        // @ts-expect-error not in webdriverio's capability typings
        'appium:webviewEnabled': true,
        'appium:arguments': [`--user-data-dir=${path.join(os.tmpdir(), 'mac2-webview-e2e')}`, PAGE_URL],
      },
    });
  });

  after(async () => {
    await driver?.deleteSession();
  });

  it('should list, switch and interact with a web view', async () => {
    let contexts: string[] = [];
    await driver.waitUntil(async () => (contexts = (await driver.getContexts()) as string[]).length > 1, {
      timeout: 30000,
    });
    assert.equal(contexts[0], 'NATIVE_APP');
    await driver.switchContext(contexts[1]);
    assert.equal(await driver.getContext(), contexts[1]);
    await driver.$('#b').click();
    assert.equal(await driver.$('#b').getText(), 'clicked');
    assert.equal(await driver.execute('return document.title'), 'mac2');
  });

  it('should switch back to the native context', async () => {
    await driver.switchContext('NATIVE_APP');
    assert.equal(await driver.getContext(), 'NATIVE_APP');
    assert.ok(await driver.$('//XCUIElementTypeWindow').isExisting());
  });
});
