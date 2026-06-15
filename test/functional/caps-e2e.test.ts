import {describe, it, beforeEach, afterEach} from 'node:test';
import assert from 'node:assert/strict';
import {remote} from 'webdriverio';
import type {Browser} from 'webdriverio';
import os from 'node:os';
import path from 'node:path';
import {fs} from 'appium/support.js';
import {HOST, PORT, TEST_TIMEOUT, TEXT_EDIT_BUNDLE_ID} from '../utils.js';

const TEST_FILE = path.resolve(os.tmpdir(), 'test.test');

const CAPS = {
  platformName: 'mac',
  'appium:automationName': 'mac2',
  'appium:bundleId': TEXT_EDIT_BUNDLE_ID,
  'appium:prerun': {command: `do shell script "touch ${TEST_FILE}"`},
  'appium:postrun': {command: `do shell script "rm ${TEST_FILE}"`},
};

describe('Mac2Driver - caps', {timeout: TEST_TIMEOUT}, () => {
  let driver: Browser | null = null;

  beforeEach(async () => {
    driver = await remote({
      hostname: HOST,
      port: PORT,
      capabilities: CAPS,
    });
  });

  afterEach(async () => {
    if (driver) {
      try {
        await driver.deleteSession();
      } finally {
        driver = null;
      }
    }
  });

  it('should execute scripts from capabilities', async () => {
    assert.equal(await fs.exists(TEST_FILE), true);
    try {
      await driver!.deleteSession();
    } finally {
      driver = null;
    }
    assert.equal(await fs.exists(TEST_FILE), false);
  });
});
